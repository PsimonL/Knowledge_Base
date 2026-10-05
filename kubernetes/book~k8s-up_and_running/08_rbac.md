# Role Based Access Control (RBAC)

Role-Based Access Control (RBAC) is the foundational identity and authorization framework in Kubernetes. It operates strictly on the **Principle of Least Privilege** (by default), all access is denied unless explicitly permitted.

---

## 1. Subjects (WHO is requesting access?)

Kubernetes distinguishes between two types of identities:

* **User Accounts (Human Users):** Managed outside the cluster. There is **no `User` API object** in Kubernetes. Authentication relies on external Identity Providers (e.g., X.509 client certificates, OIDC/Keycloak, Google Workspace, AWS IAM).
* **Groups:** Formed automatically based on user certificates or OIDC tokens (e.g., `system:masters`, `system:authenticated`).
* **ServiceAccounts:** Managed inside the cluster as native Kubernetes API resources. They provide identity to Pods and automated processes that interact with the `kube-apiserver` (e.g., controllers, CI/CD agents, Ingress Controllers).

---

## 2. Rule Structure (WHAT can be done?)

A rule in RBAC is a declarative statement answering: *Which operations can be performed on which resources?*

* **`apiGroups`:** The target API group (e.g., `""` for core resources like `Pods`, `apps` for `Deployments`, `batch` for `Jobs`).
* **`resources`:** Object types (e.g., `pods`, `services`, `secrets`, `deployments`). Can be restricted to specific instance names via `resourceNames`.
* **`verbs`:** Allowed HTTP actions / methods:
  * **Read:** `get` (single object), `list` (collection), `watch` (stream changes).
  * **Write:** `create`, `update`, `patch`, `delete`, `deletecollection`.

---

## 3. Core RBAC Objects (Permissions & Bindings)

| Object | Scope | Description |
| :--- | :--- | :--- |
| **`Role`** | `Namespace` | A set of rules (permissions) confined strictly to a single namespace. Has no access to cluster-wide resources. |
| **`ClusterRole`** | `Cluster-wide` | A set of rules with global scope. Used for managing non-namespaced resources (e.g., `Nodes`, `PersistentVolumes`) or enforcing identical permissions across multiple namespaces at once. |
| **`RoleBinding`** | `Namespace` | The "glue" that binds a `Role` (or `ClusterRole`) to a subject (`User`, `Group`, or `ServiceAccount`) within a specific namespace. |
| **`ClusterRoleBinding`** | `Cluster-wide` | Binds a `ClusterRole` to a subject at the cluster level (grants permissions across all namespaces and to cluster-scoped resources). |

---

## 4. Architecture & Request Pipeline

Whenever `kubectl` or an in-cluster Pod sends an HTTP request to the `kube-apiserver`, it passes through a three-stage security pipeline:

1. **Authentication:** Verifies identity (*Who are you?*). Attaches subject metadata (`User`, `Group`, `ServiceAccount`).
2. **Authorization (RBAC):** Checks permission rules (*Are you allowed to perform this verb on this resource?*).
3. **Admission Control:** Validates or mutates object specifications before persisting state to `etcd`.

```
[ HTTP Request ] ──> [ 1. Authentication ] ──> [ 2. RBAC Authorization ] ──> [ 3. Admission Control ] ──> [ Persist to etcd ]
```

### Practical example  
Imagine a developer named **X** wants to fetch the logs of a Pod within the `team-X` namespace. He types the following command in his terminal:
```bash
kubectl logs moj-pod -n team-X
```

1. **Authentication:** The server verifies if X is who he claims to be. (Result: *Yes, this is X*).
2. **Authorization (RBAC):** The API Server searches the cluster's database to check if there is a `RoleBinding` object in the `team-X` namespace that connects the user `X` to a `Role` possessing the `get` verb on the `pods/log` resource.
3. **Decision:** If such a binding exists, X can see the logs. If it does not exist, Kubernetes returns the error: `Error from server (Forbidden)`.


---

## 5. Object Pairing Strategies

* **`Role` + `RoleBinding` (Local Isolation):** Enforces strict boundary isolation within a single namespace (e.g., developer access in `app-dev`).
* **`ClusterRole` + `RoleBinding` (Template Pattern – Best Practice):** Defines a single universal `ClusterRole` template centrally, but grants access locally inside specific namespaces via individual `RoleBinding` resources. Prevents duplicate YAML definitions.
* **`ClusterRole` + `ClusterRoleBinding` (Global Access):** Used for cluster administration or managing non-namespaced objects (`Nodes`, `PVs`, `CRDs`). Use with extreme caution.

---

## 6. Manifest Examples (YAML)

### Namespace-Scoped Access (`Role` + `RoleBinding`)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: team-alpha
  name: pod-reader
rules:
- apiGroups: [""]
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

### Reusing a ClusterRole Locally (`ClusterRole` + `RoleBinding`)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-secrets-alpha
  namespace: team-alpha
subjects:
- kind: ServiceAccount
  name: ci-runner
  namespace: team-alpha
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

---

## 7. Operational Best Practices

* **Disable Automatic Token Mounting:** Every Pod receives a `default` `ServiceAccount` by default. If your workload does not talk to the Kubernetes API, explicitly set `automountServiceAccountToken: false` in the Pod spec to prevent token theft.
* **Avoid `system:masters` & `cluster-admin`:** Never assign `system:masters` or `cluster-admin` for daily engineer access. Always create fine-grained, namespace-scoped roles.
* **Use Aggregated ClusterRoles:** Combine multiple `ClusterRoles` into a single aggregate role using `aggregationRule` label selectors to simplify permission management across large teams.
* **Quick Permission Auditing (`kubectl auth can-i`):**
  * Test your own permissions:
    ```bash
    kubectl auth can-i create deployments --namespace=default
    ```
  * Impersonate a ServiceAccount to test permissions:
    ```bash
    kubectl auth can-i get secrets --as=system:serviceaccount:default:my-app -n default
    ```