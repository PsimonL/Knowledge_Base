# Security

Security in Kubernetes relies on the [**Defense in Depth**](https://www.paloaltonetworks.com/cyberpedia/what-is-defense-in-depth) principle and the [**4C Model**](https://www.cncf.io/blog/2022/02/14/kubernetes-security-best-practices-definitive-guide/) (*Cloud, Cluster, Container, Code*). A breach or vulnerability at one layer must not compromise the entire cluster.

---

## 1. Container Isolation - Security Context section

The [`securityContext`](https://kubernetes.io/docs/concepts/security/pod-security-standards/) section in a Pod or Container spec defines runtime privileges and pemissions inside the cluster and Linux kernel.

- **`runAsNonRoot: true` & `runAsUser`:** Strictly forbids running container processes as root (UID 0). Applications must run under a dedicated, non-root UID (e.g., `10001`).
- **`readOnlyRootFilesystem: true`:** Restricts write access to the container's root filesystem. If an attacker injects malicious code, they cannot persist it to disk. (Use `emptyDir` volumes for temporary file storage).
- **`allowPrivilegeEscalation: false`:** Prevents child processes from gaining higher privileges than their parent process (e.g., via setuid binaries).
- **Linux Capabilities (Kernel Privileges):** Linux breaks down root privileges into granular capabilities.
  - **Best Practice:** Apply the Principle of Least Privilege. Drop all capabilities first (`drop: ["ALL"]`), then selectively add only those strictly required (e.g., `add: ["NET_BIND_SERVICE"]` to bind to ports <1024).

---

## 2. Linux Kernel Primitives

At the Node level, low-level Linux security tools do the actual work to keep containers safe - classic Linux Hardening: 
- **Seccomp (Secure Computing Mode):** Restricts the set of system calls (*syscalls*) a container process can issue to the host kernel.
> NOTE: Setting `seccompProfile: { type: RuntimeDefault }` blocks dangerous syscalls (e.g., `reboot` or calls used in container escape exploits).
- **AppArmor / SELinux:** Mandatory Access Control (MAC) frameworks. They enforce security profiles that constrain container access to files, network sockets, and physical devices on the host, preventing actions outside designated boundaries.

---

## 3. Control Plane Security (API & etcd)

Hardening the entry point to the cluster (`kube-apiserver`) and its state store.

- **Network Access Control:** The API Server should not be publicly exposed to the internet (use private endpoints, VPNs, or bastion hosts).
- **Encryption at Rest:** By default, `etcd` stores data (including `Secret` objects) in plaintext. Configuring `EncryptionConfiguration` forces `etcd` database encryption using provider keys (e.g., external HSM / AWS KMS).
- **etcd Network Isolation:** Isolate the `etcd` peer and client communication endpoints (ports 2379/2380) using strict host-level firewalls and dedicated mTLS certificates, ensuring it *only* accepts traffic originating directly from the `kube-apiserver`.
- **API Server Audit Logging:** Enable comprehensive cluster auditing by configuring an `AuditPolicy` file. This records a cryptographic ledger of all API requests (who, what, when), which is critical for post-incident forensics.
- **Hardening ServiceAccounts:** The default mounted token in a Pod (`/var/run/secrets/kubernetes.io/serviceaccount`) allows applications to authenticate against the K8s API. If an application does not require API access, explicitly disable token mounting: `automountServiceAccountToken: false`.

---

## 4. Certificates & Certificate Signing Requests (PKI & CSR)

Kubernetes relies entirely on **X.509 certificates** for internal authentication (e.g., between cluster components like `kubelet`, `kube-apiserver`, `etcd`, and for external human users).

* **K8s PKI Infrastructure:**
  * An internal **Cluster CA** issues and validates certificates within the cluster. The CA private key (`ca.key`) must be strictly protected on the Control Plane nodes, as compromising it grants full cluster override.
  * X.509 client certificates encode user identity: the `CN` (Common Name) field specifies the username, and `O` (Organization) fields define K8s group memberships.
  * **The Revocation Limitation:** Native K8s PKI does not support Certificate Revocation Lists (CRL) or OCSP. Therefore, certificates issued to human users should have short lifetimes (low TTL) to mitigate risk.
* **CertificateSigningRequest (CSR) API:**
  * Allows entities (users, nodes) to request certificate signatures from the cluster CA without exposing the CA's private key.
  * Uses the `certificates.k8s.io/v1` API resource.
  * **CSR Workflow:**
    1. The requester generates a private key and a `.csr` file locally.
    2. A `CertificateSigningRequest` manifest is created with the base64-encoded CSR payload.
    3. An administrator or automated controller inspects the pending request:
       ```bash
       kubectl get csr
       ```
    4. Upon verification, the request is approved or denied:
       ```bash
       kubectl certificate approve <csr-name>
       kubectl certificate deny <csr-name>
       ```
    5. Once approved, the signed certificate is generated and populated into the `status.certificate` field of the CSR object.
* **Automated Certificate Rotation (Kubelet):**
  * Nodes (`kubelet`) automatically submit CSR requests to renew their client and server certificates prior to expiration.
* **Application Certificate Management (`cert-manager`):**
  * To manage TLS/HTTPS certificates for applications running inside the cluster (e.g., Ingress controllers or service mesh mTLS), dedicated operators like `cert-manager` are used (integrating with Let's Encrypt, HashiCorp Vault, or external PKIs).

---

## 5. Image & Supply Chain Security

Ensuring only verified, trusted code executes in production.

- **Vulnerability Scanning:** Integrate container registries and CI/CD pipelines with CVE scanners (e.g., Snyk, SonarQube) to automatically block images containing critical vulnerabilities.
- **Cryptographic Image Signing:** This process uses asymmetric cryptography to verify image integrity and origin. During CI/CD, a tool like Cosign generates a cryptographic hash of the container image and encrypts it with a private key to create a Digital Signature. Upon deployment, Kubernetes uses the corresponding public key to decrypt the signature. If the decrypted hash matches the live image, Kubernetes guarantees the container is authentic, untampered with, and safe to execute.
- **In-Cluster Verification:** Admission controllers (*Validating Webhooks*, e.g., OPA Gatekeeper) verify image signatures before Pod execution—if an image lacks a valid signature from your CI/CD pipeline, K8s rejects the deployment. This prevents supply chain attacks, such as man-in-the-middle image tampering, registry breaches, or accidental deployments of unapproved, untested, or malicious code into production.

---

## 6. Network Isolation & Pod Security Standards

- **NetworkPolicies:** Transition from the default *Allow-All* flat network to a strict **Zero Trust** posture. Operating at Layers 3 and 4, these policies are enforced directly by the CNI plugin (e.g., Cilium, Calico) to block all ingress and egress traffic by default at the Namespace level, preventing lateral movement. Communication paths between microservices must then be explicitly whitelisted using fine-grained pod and namespace label selectors.
- **Service Mesh Integration:** Extend network security to Layer 7 by injecting a Service Mesh (e.g., Istio) to enforce transparent **mutual TLS (mTLS)** encryption for all pod-to-pod communication. This secures data in transit and allows for cryptographic identity-based authorization policies (SPIFFE/SPIRE) and application-path filtering.
- **Pod Security Admission (PSA):** Enforce the strict **Restricted** Pod Security Standard profile at the Namespace level, which automatically rejects Pods violating security guidelines (e.g., attempting to run as root, using dangerous hostPath mounts, or missing a Seccomp profile).
- **RuntimeClass (Workload Sandboxing):** Defend against container escape exploits by using a custom `RuntimeClass` to delegate high-risk workloads to sandboxed runtimes like **gVisor** or **Kata Containers**. This isolates the workload with a dedicated guest kernel, ensuring host Node security even if the container layer is compromised.

---

## 7. Role-Based Access Control (RBAC)

Enforces the principle of least privilege by restricting user and service account permissions within the cluster; for a comprehensive deep dive into implementing secure roles and bindings, refer to the [08_rbac.md](08_rbac.md) file in this directory.
