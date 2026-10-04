# Kubernetes Extensions
[Extensions](https://kubernetes.io/docs/concepts/extend-kubernetes/#extensions) are software components that extend and deeply integrate with Kubernetes. They adapt it to support new types and new kinds of hardware.

## 1. API Server Request Lifecycle

All operations in the cluster pass through `kube-apiserver`. Any state change (e.g., `kubectl apply`) is processed through a multi-stage pipeline:

```text
  [ HTTP/REST Request ]
           │
           ▼
┌─────────────────────────┐
│ 1. Authentication       │ ──► (OIDC, X.509 Client Certs, Bearer Tokens)
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ 2. Authorization        │ ──► (RBAC, ABAC, Node Authorization)
└──────────┬──────────────┘
           │
           ▼
┌───────────────────────────────────────┐
│ 3. Mutating Admission Webhooks        │ ──► In-flight manifest modification 
└──────────┬────────────────────────────┘     (e.g., sidecar injection)
           │
           ▼
┌───────────────────────────────────────┐
│ 4. Schema Validation (OpenAPI v3)     │ ──► Structural & type checking
└──────────┬────────────────────────────┘
           │
           ▼
┌───────────────────────────────────────┐
│ 5. Validating Admission Webhooks      │ ──► Business logic & policy enforcement 
└──────────┬────────────────────────────┘     (accept / reject)
           │
           ▼
┌─────────────────────────┐
│ 6. etcd Persistence     │ ──► Persisting cluster state
└─────────────────────────┘
```

Stage Details:  
1. **Authentication (AuthN)**: Verifies the identity of the requester (*"Who are you?"*). Unauthenticated requests return `401 Unauthorized`. 
2. **Authorization (AuthZ)**: Verifies if the identity has permissions to perform the requested action on the target resource (*"Are you allowed to do this?"*). Commonly enforced via RBAC. Unauthorized requests return `403 Forbidden`.
3. **Mutating Admission Webhooks**: External HTTP services that can modify or inject default values into the resource payload before validation.
4. **Schema Validation**: Structural verification of the payload against built-in Go structs or the OpenAPI v3 schema defined in a CRD.
5. **Validating Admission Webhooks**: External HTTP services enforcing security and compliance policies (e.g., OPA Gatekeeper). They cannot modify objects; they can only approve (`allowed: true`) or reject (`allowed: false`) the request.
6. **`etcd` Persistence**: Upon passing all stages, the object is written to the etcd key-value store, and a 200 OK or 201 Created response is returned to the client.

---

## 2. Node Interfaces: CNI, CSI, CRI
Kubernetes relies on standardized interfaces to decouple core orchestration logic from specific infrastructure and runtime providers.
```text
                     +-------------------+
                     |      Kubelet      |
                     +---------+---------+
                               |
         ┌─────────────────────┼─────────────────────┐
         │ (gRPC)              │ (Exec/JSON)         │ (gRPC)
         ▼                     ▼                     ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│       CRI       │   │       CNI       │   │       CSI       │
│ (Container      │   │ (Container      │   │ (Container      │
│  Runtime        │   │  Network        │   │  Storage        │
│  Interface)     │   │  Interface)     │   │  Interface)     │
└────────┬────────┘   └────────┬────────┘   └────────┬────────┘
         │                     │                     │
         ▼                     ▼                     ▼
 containerd / CRI-O     Cilium / Calico       AWS EBS / Ceph
```
- **CRI** => Manages container lifecycle and image pulling on the Node.
- **CRO** => Allocates IP addresses (IPAM), attaches Pods to the network, and enforces NetworkPolicy rules.
- **CSI** => Handles dynamic volume provisioning, attaching (Attach), and mounting (Mount) physical storage to Pods.

---

## 3. Custom Resource Definition (CRD) & Validating Webhook Configuration

Mechanisms used to extend the native Kubernetes API with custom objects and validation logic.

### Custom Resource Definition (CRD)
Registers a new resource type in the cluster (`apiextensions.k8s.io/v1`). Once created, `kube-apiserver` automatically handles REST endpoints, `etcd` storage, and `kubectl` integration for the new resource.

Below manifest extends the Kubernetes API by introducing a custom resource named **Database** (short name: `db`). It allows users to define and manage database instances natively within the cluster.
```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: databases.example.com
spec:
  group: example.com
  versions:
    - name: v1alpha1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                engine:
                  type: string
                  enum: ["postgres", "mysql"]
                replicas:
                  type: integer
                  minimum: 1
  scope: Namespaced
  names:
    plural: databases
    singular: database
    kind: Database
    shortNames:
      - db
```

This is a sample instance of the custom **Database** resource defined by the CRD.
It provisions a PostgreSQL database cluster with 3 active replicas:
```yaml
apiVersion: ://example.com
kind: Database
metadata:
  name: my-database
  namespace: default
spec:
  engine: "postgres"
  replicas: 3
```

### Dynamic Admission Control
[Admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#what-are-admission-webhooks) are HTTP callbacks that receive admission requests and do something with them. You can define two types of admission webhooks, validating admission webhook and mutating admission webhook. Mutating admission webhooks are invoked first, and can modify objects sent to the API server to enforce custom defaults. After all object modifications are complete, and after the incoming object is validated by the API server, validating admission webhooks are invoked and can reject requests to enforce custom policies.

#### Validating Webhook Configuration
Defines rules for intercepting API requests (`admissionregistration.k8s.io/v1`) and forwarding them to an external HTTPS service for validation.
This configuration registers an external HTTP callback (`/validate`) with the Kubernetes API server. It acts as a safety gate to **intercept, inspect, and approve or reject** resource requests before they are saved to the cluster:
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: strict-policy-webhook
webhooks:
  - name: validate.example.com
    rules:
      - apiGroups: ["*"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["pods", "deployments"]
        scope: "Namespaced"
    clientConfig:
      service:
        name: policy-validator-svc
        namespace: security-system
        path: "/validate"
      caBundle: "<BASE64_ENCODED_CA_CERT>"
    admissionReviewVersions: ["v1"]
    sideEffects: None
    failurePolicy: Fail
```

#### Mutating Webhook Configuration
This configuration registers an external HTTP callback (`/mutate`) that intercepts resource requests **to modify them dynamically** before validation and persistence.
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: auto-injection-webhook
webhooks:
  - name: mutate.example.com
    rules:
      - apiGroups: ["*"]
        apiVersions: ["v1"]
        operations: ["CREATE"]
        resources: ["pods"]
        scope: "Namespaced"
    clientConfig:
      service:
        name: policy-mutator-svc
        namespace: security-system
        path: "/mutate"
      caBundle: "<BASE64_ENCODED_CA_CERT>"
    admissionReviewVersions: ["v1"]
    sideEffects: None
    failurePolicy: Ignore
```

---

## 4. Resource Creation Patterns
Three core approaches to defining and managing resources in Kubernetes environments. Below schema illustrates the architectural shift from manual, static configuration to intelligent, self-healing automation:
```text
 ┌─────────────────────────┐
 │ 1. Data-Only            │ ──► Static YAML/JSON manifests
 └─────────────────────────┘
           │
           ▼
 ┌─────────────────────────┐
 │ 2. Compilers            │ ──► Templating & Generation (e.g., Helm)
 └─────────────────────────┘
           │
           ▼
 ┌─────────────────────────┐
 │ 3. Operators            │ ──► CRD + Custom Controller (Reconciliation Loop)
 └─────────────────────────┘
```

### 1. Data-Only (Raw Declarative)
- **Description:** Writing static YAML/JSON manifests directly and applying them to the cluster (`kubectl apply -f manifest.yaml`).
- **Key Characteristics:**
    - No execution logic, variables, or conditional logic.
    - Fully declarative — the desired state is explicitly written in the file.
- **Use Cases:** Simple resources, local development, learning.

### 2. Compilers / Generators (Templating)
- **Description:** Tools that render clean YAML manifests client-side or within a CI/CD pipeline before sending them to the API Server.
- **Key Characteristics:**
    - Allows parameterization (variables, templates, environmental overlays).
    - The output is standard raw YAML consumed by kube-apiserver.
- **Examples:**
    - **Helm:** Package manager based on Go templating and values.yaml.
    - Kustomize: Template-free configuration management using overlays on top of base manifests.

### 3. Operators (Operator Pattern: CRD + Controller)
This is the most important and hot topic within extension category today.
[Operators](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) are software extensions to Kubernetes that make use of custom resources to manage applications and their components.
- **Description:** Extends cluster functionality with domain-specific operational logic by pairing a Custom Resource Definition (CRD) with a Custom Controller running inside the cluster.
- **Key Characteristics:** 
    - Encapsulates human operational knowledge into an automated reconciliation loop (`Observe => Analyze => Act`).
    - Manages the full lifecycle of complex/stateful workloads. For example: automated backups, failover, schema migrations.
- **Examples:** CloudNativePG (PostgreSQL), Strimzi (Apache Kafka), Argo CD (GitOps).
> NOTE: Unlike a custom HTTP server or webhook (e.g., a policy engine - OPA Gatekeeper), which acts synchronously during the API request phase before data is saved to etcd to validate or mutate incoming manifests, an Operator acts asynchronously in the background after data is persisted in etcd, continuously driving the actual cluster state toward the desired state through an active reconciliation loop.

---