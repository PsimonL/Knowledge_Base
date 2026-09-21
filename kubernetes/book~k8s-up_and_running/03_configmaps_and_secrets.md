# ConfigMaps and Secrets

## ConfigMaps
A [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) stores non-confidential configuration data in key-value pairs (e.g., environment variables, application properties, feature flags). It decouples environment-specific configurations from container images, enabling the same image to be deployed across Dev, Staging, and Production environments.
It allows you to decouple environment-specific configuration from your container images, so that applications are easily portable.

> NOTE: ConfigMap does not provide secrecy or encryption.

There are two consumption methods; **environmental variables** and **volumes**.

---

### Environment Variables
Injects key-value pairs directly into the container's environment. This method is ideal for simple, **single-value configurations** like ports, flags, or profile names.
- **Individual Keys:** Maps specific keys from a ConfigMap to custom environment variable names using `valueFrom.configMapKeyRef`.
- **Bulk Loading (`envFrom`):** Automatically injects all keys from a ConfigMap as environment variables using their original names.
> NOTE: Environment variables are **static**. If you **update** the ConfigMap, the container **will not receive** the new values until it is **restarted**.

### ConfigMap Volumes
Mounts the ConfigMap data as files inside a directory within the container's filesystem. ConfigMap volumes write files directly to the host node's disk. This method is ideal for **large, multi-line configuration files** (such as `.yaml`, `.conf`, or `.properties` files), **application scripts**, or whenever there is a need to **update configurations dynamically** without restarting the container.
- **File Mapping:** Each key in the ConfigMap's `data` section becomes an individual file, and the key's value becomes the file's content.
- **Live Updates (Hot-reloading):** If the ConfigMap is updated via the API, the mounted files are **automatically updated** in the background without restarting the Pod (provided the application can detect file changes).

---

### Full example
- Sample ConfigMap body containing configuration data:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  labels:
    app: my-app
data:
  # Simple single-value keys (perfect for Environment Variables)
  APP_PORT: "8080"
  FEATURE_TOGGLE: "true"
  LOG_LEVEL: "DEBUG"
  # Key used for container startup control (perfect for Container Command and Args)
  STARTUP_MODE: "background-worker"
  # Multi-line key (perfect for ConfigMap Volumes)
  app.properties: |
    server.context-path=/api
    database.connection.timeout=5000
    cache.capacity=1000
```

- A Pod definition that consumes a ConfigMap using four different method (A-D):
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: single-container-pod
  labels:
    app: my-app
spec:
  # ============================================================================
  # METHOD D: KUBERNETES API (Pod Permissions)
  # ============================================================================
  # Assigning a ServiceAccount with RBAC privileges. Code inside the application 
  # can now use the Kubernetes SDK to fetch the 'app-config' ConfigMap via API.
  serviceAccountName: k8s-api-reader-account
  volumes:
    # Defining the volume and sourcing it from the app-config ConfigMap
    - name: config-volume-mount
      configMap:
        name: app-config 
  containers:
  - name: web-app
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
    # ============================================================================
    # METHOD A: ENVIRONMENT VARIABLES
    # ============================================================================
    env:
      # Individual Keys: Mapping a single key to a custom env variable name
      - name: CONTAINER_PORT
        valueFrom:
          configMapKeyRef:
            name: app-config
            key: APP_PORT
      # Helper Variable: Extracted for use inside METHOD C (Command and Args)
      - name: INTERNAL_STARTUP_MODE
        valueFrom:
          configMapKeyRef:
            name: app-config
            key: STARTUP_MODE
    envFrom:
      # Bulk Loading: Automatically injects FEATURE_TOGGLE and LOG_LEVEL
      - configMapRef:
          name: app-config
    # ============================================================================
    # METHOD C: CONTAINER COMMAND AND ARGS
    # ============================================================================
    # Overriding the default entrypoint behavior by evaluating the environment 
    # variable initialized via configMapKeyRef above using $(VARIABLE_NAME) syntax.
    command: ["/docker-entrypoint.sh"]
    args: ["--execute-as", "$(INTERNAL_STARTUP_MODE)"]
    # ============================================================================
    # METHOD B: CONFIGMAP VOLUMES
    # ============================================================================
    volumeMounts:
      # Mount path inside the container's filesystem. 
      # This generates a real file at: `/etc/config/app.properties`
      - name: config-volume-mount
        mountPath: /etc/config
        readOnly: true # Good practice: keep config volumes read-only

```

---

### Follow up notes:
- **Directory Overwriting vs `subPath`:** Mounting a ConfigMap via `mountPath` **wipes out** all existing files in that container directory. To inject a single file into an existing folder without overwriting it, use the `subPath` property in `volumeMounts`.
- **Hot-reload Delay:** Updated ConfigMap files do not sync instantly. Due to the Kubelet caching mechanism, it can take up to **60 seconds** for changes to reflect inside the container filesystem.
- **Immutable ConfigMaps:** Thre is a possibility of adding `immutable: true` to the ConfigMap metadata. This prevents accidental changes and heavily optimizes cluster performance by stopping Kubelet from constantly polling the API for updates.
- **Max Memory limit:** A ConfigMap is not designed to hold large chunks of data. **The data stored in a ConfigMap cannot exceed 1 MiB**. If you need to store settings that are larger than this limit, you may want to consider mounting a volume or use a separate database or file service.
- **Binary Data Support:** While the standard data field is designed for UTF-8 strings, you can store non-textual or binary files (like small icons, certificates, or .dat files) using the binaryData field. All values inside binaryData must be base64 encoded.
- **Key Overlapping Restriction:** The keys stored under the data field must not overlap with the keys defined in the binaryData field within the same ConfigMap.

---

## Secrets
A [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) is an API object used to store and manage sensitive data, such as passwords, OAuth tokens, and ssh keys. Using a Secret means that you don't need to include confidential data in your application code.

### Critical limitations and safety warnings:
- **No Real Encryption (by default):** Kubernetes Secrets are only **Base64 encoded** by default, not encrypted. Anyone with access to the YAML file or the API can easily decode them using `echo "encoded-string" | base64 --decode`.
- **Size Limit:** Just like ConfigMaps, the total data stored in a single Secret cannot exceed **1 MiB**.
- **Namespace Isolation:** A Secret can only be consumed by Pods residing within **the exact same namespace**.

### Secret Types (Built-in)
Kubernetes provides several built-in types for specific use cases:
- `Opaque`: The default type for arbitrary user-defined key-value pairs (passwords, tokens).
- `kubernetes.io/tls`: Used for storing TLS certificates and private keys (commonly used for Ingress controllers).
- `kubernetes.io/dockerconfigjson`: Used for storing credentials to a private Docker registry (used with `imagePullSecrets`).

---

### Private Registry Authentication (imagePullSecrets)
To pull container images from private registries (AWS ECR, GitLab Registry, Docker Hub Private), Kubelet uses a Secret of type `kubernetes.io/dockerconfigjson`.

- **Explicit Pod Definition:** Defined directly under spec.imagePullSecrets in the Pod manifest.
- **ServiceAccount Automation (Best Practice):** Attach the Secret directly to a `ServiceAccount` (`imagePullSecrets: [{name: registry-key}]`). Any Pod using this ServiceAccount automatically inherits registry access without repeating `imagePullSecrets` in every Deployment.

### Consumption Methods
#### 1. Environment Variables
Injects sensitive values directly into the container's environment.
- **Individual Keys:** Uses `valueFrom.secretKeyRef` to map specific keys to custom variable names.
- **Bulk Loading (`envFrom`):** Automatically injects all keys from a Secret as environment variables using `secretRef`.
- **Security Risk:** Environment variables can sometimes be leaked via application crash logs or debugging tools (`printenv`).

#### 2. Secret Volumes
Mounts the Secret keys as files inside a directory within the container's filesystem.
- **In-Memory Storage (`tmpfs`):** Kubernetes backs Secret volumes with temporary in-memory storage. The sensitive data is **never written to the node's physical disk**, making it much more secure than ConfigMap volumes.
- **Live Updates:** Mounted Secret files are automatically updated in the background if the Secret changes in the cluster.

---

### Full Example

#### - Sample Secret body containing sensitive data:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
  labels:
    app: my-app
type: Opaque # Default type
data:
  # All values MUST be base64 encoded strings
  DB_PASSWORD: "c3VwZXItc2VjcmV0LXBhc3N3b3Jk" # "super-secret-password" in base64
  API_TOKEN: "YmNhZDQ1Njc4OQ=="              # "bcad456789" in base64
```

#### - Pod definition that consumes the Secret:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-consumer-pod
  labels:
    app: my-app
spec:
  volumes:
    # Defining the volume and sourcing it from the app-secret Secret
    - name: secret-volume-mount
      secret:
        secretName: app-secret
  containers:
  - name: web-app
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
    # ============================================================================
    # METHOD A: ENVIRONMENT VARIABLES
    # ============================================================================
    env:
      # Individual Keys: Mapping a single key to a custom env variable name
      - name: DATABASE_PASSWORD
        valueFrom:
          secretKeyRef:
            name: app-secret
            key: DB_PASSWORD
    envFrom:
      # Bulk Loading: Automatically injects API_TOKEN and DB_PASSWORD
      - secretRef:
          name: app-secret
    # ============================================================================
    # METHOD B: SECRET VOLUMES
    # ============================================================================
    volumeMounts:
      # Mount path inside the container's filesystem.
      # This generates a real file at: `/etc/secrets/DB_PASSWORD`
      - name: secret-volume-mount
        mountPath: /etc/secrets
        readOnly: true # Always keep secrets read-only
```

---

### Follow-up Notes:
- **Base64 vs Encryption:** Remember that Base64 is **obfuscation**, not encryption. To secure secrets at rest in a real cluster, you must enable **Encryption at Rest** in the `kube-apiserver` configuration or use external tools like HashiCorp Vault.
- **Memory vs Disk:** Unlike ConfigMaps, Secret volumes use `tmpfs` (RAM). When the Pod is deleted, the secret data disappears from the node's memory instantly.
- **SubPath & Updates:** Just like ConfigMaps, if you mount a Secret using a `subPath`, it **will not** receive live updates when the Secret is modified.

## Secrets in GitOps (Production Patterns)
Storing raw Secret YAML files in Git repositories is prohibited because Base64 encoding is easily reversed. Two main patterns manage Secrets safely in GitOps workflows:

### 1. Encrypted Git Secrets (Sealed Secrets)
- **Mechanism:** Encrypt sensitive values locally using an asymmetric public key provided by the cluster.
- **Git Safety:** The resulting `SealedSecret` custom manifest can be safely committed to Git repositories.
- **Decryption:** A Sealed Secrets operator running inside the cluster holds the private key and decrypts the manifest into a native Kubernetes Secret.

### 2. External Secret Stores (External Secrets Operator - ESO)
- **Mechanism:** Store credentials in an external vault (HashiCorp Vault, AWS Secrets Manager, Azure Key Vault).
- **Git Safety:** Git contains only an `ExternalSecret` resource acting as a pointer to the vault path.
- **Synchronization:** The ESO controller fetches values from the external vault and dynamically generates/updates the native Kubernetes Secret inside the cluster.
