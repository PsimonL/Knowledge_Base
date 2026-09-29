# Cheat Sheet: Kubernetes Policies & Governance
[Policies](https://kubernetes.io/docs/concepts/policy/) represent declarative mechanisms that enforce security boundaries, resource allocation limits, network isolation, and architectural compliance across the cluster.

---

## 1. Admission Control & Policy Engines
[Admission controller](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/) is the ultimate gatekeeper inside the `kube-apiserver` request path. It intercepts API requests right after identity verification (Authentication) and permission checks (RBAC), but before any object is saved to the `etcd` database. This specific phase is where Kubernetes enforces cluster policies:
```txt
[ HTTP Request ] ──> [ Authentication ] ──> [ Authorization (RBAC) ]
                     (Who are you?)          (Do you have permissions?)
                                                    │
                                                    ▼
                                        [ Mutating Webhooks ]
                                        (Modify/Auto-fill the YAML)
                                                    │
                                                    ▼
                                        [ Schema Validation ]
                                        (Check for typo/syntax errors)
                                                    │
                                                    ▼
                                       [ Validating Webhooks ]
                                       (Final check: Accept or Reject)
                                                    │
                                                    ▼
                                            [ Persist to etcd ]
                                            (Save to cluster database)

```

### Mutating Webhooks (Mutation)
Intercepts and modifies incoming resource specifications on the fly before admission.
- **Use Cases:** Automatically injecting sidecar containers (e.g., Istio, Linkerd), adding default labels, or enforcing `imagePullPolicy: Always`.

### Validating Webhooks (Validation)
Enforces a hard gate (Pass/Fail). Inspects resources against cluster compliance rules and rejects non-compliant API requests with an error message.

### External Policy Engines
Allow writing advanced governance rules without needing to build and maintain custom webhook code:
- **OPA Gatekeeper:** Built on Open Policy Agent. Uses a two-step declarative model written in **Rego**:
  - `ConstraintTemplate`: Defines the validation logic (Rego code).
  - `Constraint`: Binds the template to specific Kubernetes API resources and parameters.
- **Kyverno:** A Kubernetes-native engine configured using **100% standard YAML**. Supports:
  - **Validation:** Rejection of non-compliant manifests.
  - **Mutation:** Automatic modification of resource specs.
  - **Generation:** Automatic creation of secondary resources (e.g., generating a default `NetworkPolicy` whenever a new `Namespace` is created).
  - **Image Verification:** Verification of digital container signatures (Cosign/Notation).

### Enforcement Modes
- `enforce` *(Hard Gate)*: Immediately rejects API requests that violate policies.
- `audit` *(Dry-run)*: Allows object creation, but reports violations in audit logs and within the object's `.status` field.

> NOTE: By default, Kubernetes does not include a built-in customizable webhook engine, so there are 2 options: either write custom code or deploy an external tool like OPA Gatekeeper or Kyverno. However, modern K8S versions do offer native alternatives like `PodSecurity Admission` and `ValidatingAdmissionPolicy` for standard security and basic validations without external dependencies.

---

## 2. Pod Security Standards (PSS) & Pod Security Admission (PSA)

Pod Security standards govern runtime privileges and isolation levels for container workloads.

> **Historical Note:** `PodSecurityPolicy` (PSP) was deprecated in v1.21 and **completely removed in v1.25** due to complexity and RBAC integration issues. It was replaced by **Pod Security Admission (PSA)**.

### The 3 Security Profiles (PSS)
1. **`Privileged`:** Unrestricted access. Intended for cluster infrastructure workloads (e.g., CNI plugins, storage drivers, node monitoring agents).
2. **`Baseline`:** Default profile preventing known privilege escalation risks while ensuring minimal impact on standard applications.
3. **`Restricted`:** Highest security rigor (Best Practices):
   - Enforces `runAsNonRoot: true`.
   - Enforces `allowPrivilegeEscalation: false`.
   - Drops all default Linux capabilities (`capabilities: drop: ["ALL"]`).
   - Restricts `seccomp` profiles and allowed volume types.

### PSA Modes & Namespace Labeling
PSA is configured natively by applying labels to `Namespace` objects using three operational modes:
- `enforce`: Rejects Pods that do not comply with the specified profile.
- `audit`: Allows Pod creation, but records a violation entry in the API server audit logs.
- `warn`: Returns a user-facing warning message in the terminal when running `kubectl apply`.

---

## 3. Network Policies (L3/L4 Firewalling)

Network Policies define packet filtering rules for pod-to-pod and pod-to-external communication at Network Layers 3 (IP) and 4 (TCP/UDP).

- **Default Behavior:** Kubernetes operates on an **Allow-All** flat network model where any Pod can communicate with any other Pod in the cluster.
- **Targeting (`podSelector`):** Applies filtering rules to targeted Pods using label selectors within a namespace.
- **Traffic Direction:**
  - `Ingress`: Rules governing incoming traffic to target Pods.
  - `Egress`: Rules governing outgoing traffic from target Pods (e.g., blocking outbound public internet access).

> **PREREQUISITE:** The `NetworkPolicy` API resource is **completely ignored** unless the cluster utilizes a CNI plugin that supports network policy enforcement (e.g., **Calico**, **Cilium**, or **AWS VPC CNI** with policy support enabled).

---

## 4. Resource Policies (Resource Management)

Policies designed to prevent resource starvation and protect nodes from "Noisy Neighbor" workloads.

### LimitRange (Pod / Container Scope)
Defines resource constraints applied to individual Pods or Containers within a specific namespace:
- **Default Injector:** Automatically injects default CPU/Memory `requests` and `limits` if left unconfigured by developers.
- **Boundaries (Min/Max):** Enforces minimum and maximum allowable resource limits per Pod or volume sizes per PVC.

### ResourceQuota (Namespace Level Aggregation)
Limits total aggregate resource consumption across an entire Namespace:
- **Compute Quotas:** Total cumulative sum of CPU, RAM, and Ephemeral Storage allowed.
- **Object Count Quotas:** Restricts the maximum number of specific Kubernetes objects (e.g., max 10 `Pods`, 5 `Services`, 2 `PVCs`).

---

## 5. RBAC Policies (API Access Control)

Role-Based Access Control governs API server access by mapping **Subjects** (Users, Groups, ServiceAccounts) to **Permissions** (Verbs on API Resources).

### Core Components
1. **Rules:** Defines permitted actions (`verbs`: `get`, `list`, `watch`, `create`, `update`, `delete`) on specific API resources (`resources`: `pods`, `services`, `secrets`) within specific API groups (`apiGroups`).
2. **Role vs. ClusterRole:**
   - `Role`: Grants permissions confined strictly to a **single Namespace**.
   - `ClusterRole`: Grants global cluster-scoped permissions (or access to non-namespaced resources like `Nodes` or `PersistentVolumes`).
3. **Bindings:**
   - `RoleBinding`: Assigns permissions **only within a specific Namespace**.
   - `ClusterRoleBinding`: Assigns permissions **globally across the entire cluster**.

> NOTE: more about this topic will be covered [in the next section](/kubernetes/book~k8s-up_and_running/08_rbac.md).
---

## Direct Comparison

| Policy Domain | Scope / Target | Enforcement Mechanism | Core Resources / Tools |
| :--- | :--- | :--- | :--- |
| **Admission Policies** | API Server Requests | Pre-etcd Webhooks | `ValidatingWebhookConfiguration`, Gatekeeper, Kyverno |
| **Pod Security (PSA)** | Container Runtime | Admission Webhook | Namespace Labels (`pod-security.kubernetes.io/*`) |
| **Network Policies** | L3/L4 Traffic Filtering | CNI Data Plane | `NetworkPolicy` (`ingress`, `egress`, `podSelector`) |
| **Resource Policies** | Pods & Namespaces | Scheduler & Admission | `ResourceQuota`, `LimitRange` |
| **RBAC Policies** | API Authorization | `kube-apiserver` Auth | `Role`, `ClusterRole`, `RoleBinding`, `ClusterRoleBinding` |

---

## Manifest Examples (YAML)

### 1. Default Deny-All Network Policy (Zero-Trust Baseline)
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {} # Selects all Pods in the namespace
  policyTypes:
    - Ingress
    - Egress
```

### 2. Namespace Resource Isolation (`ResourceQuota` + `LimitRange`)
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ns-quota
  namespace: team-alpha
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "10"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: container-defaults
  namespace: team-alpha
spec:
  limits:
    - type: Container
      default: # Default Limit
        cpu: "500m"
        memory: "512Mi"
      defaultRequest: # Default Request
        cpu: "200m"
        memory: "256Mi"
```

### 3. Enabling Pod Security Admission via Namespace Labels
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-apps
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/warn: restricted
```

### 4. Namespace-Scoped RBAC (`Role` + `RoleBinding`)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: team-alpha
  name: pod-reader
rules:
- apiGroups: [""] # Core API group
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-binding
  namespace: team-alpha
subjects:
- kind: User
  name: john@example.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

---

## Best Practices
- **Zero-Trust Network Baseline:** Apply a "Default-Deny All" `NetworkPolicy` to every new namespace, then explicitly whitelist required `Ingress` and `Egress` traffic paths.
- **Reusing ClusterRoles via RoleBindings:** Binding a `ClusterRole` using a standard `RoleBinding` restricts the defined permissions strictly to the namespace of that `RoleBinding`. This allows you to define reusable role templates cluster-wide without granting global access.
- **Kyverno vs. OPA Gatekeeper Selection:** **OPA Gatekeeper** is the industry standard, with unified policy engine across heterogeneous cloud systems (e.g., K8s, Terraform, Envoy, AWS).