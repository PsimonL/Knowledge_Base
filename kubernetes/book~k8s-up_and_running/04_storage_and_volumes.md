# Storage and Volumes
In Kubernetes, storage management is decoupled from container lifecycles. Storage is categorized by its lifecycle relative to a Pod: Ephemeral Volumes and Persistent Storage.

---

## Ephemeral Volumes
Ephemeral volumes are tied directly to the lifetime of the Pod. If a Pod is evicted, deleted, or rescheduled to another node, all data stored within an ephemeral volume is **permanently destroyed**!

* **Primary Use Cases:** Application caching, temporary build workspaces, shared scratch space between containers within a Pod (Sidecar pattern), and configuration injection.
* **Key Ephemeral Types:**
  * `emptyDir`: A fresh, initially empty directory created on the host node when the Pod starts. Can run on physical host disk or directly out of RAM (`medium: Memory`).
  * `configMap` & `secret`: Inject cluster configurations, flags, or credentials as files into the container filesystem.
  * `projected`: Maps several existing volume sources (`secret`, `configMap`, `downwardAPI`, `serviceAccountToken`) into a single unified directory.
  * **Generic Ephemeral Volumes:** Allows third-party CSI drivers to create dynamic, short-lived volumes using standard PVC specs that follow the Pod lifecycle.

## Persistent Storage
Persistent storage is completely decoupled from the Pod lifecycle. Data survives Pod restarts, container crashes, rescheduling, and physical host failures. When a Pod dies, Kubernetes can recreate it on another node and reattach the existing network storage.

* **Primary Use Cases:** Stateful workloads including relational databases (PostgreSQL, MySQL), NoSQL stores (MongoDB), message brokers (Kafka), and shared file systems.
* **Management Model:** Handled via dedicated API objects that separate cluster administration from developer consumption: `StorageClass`, `PersistentVolume` (PV), and `PersistentVolumeClaim` (PVC).

---

## Direct Comparison

| Feature | Ephemeral Volumes ⏳ | Persistent Storage 🔒 |
| :--- | :--- | :--- |
| **Lifecycle Binding** | Tied directly to the Pod lifetime | Completely independent of the Pod |
| **Pod Eviction / Deletion** | Data is permanently destroyed | Data safely remains on external storage |
| **Physical Location** | Local node storage (SSD or RAM) | Network-attached / Cloud storage (SAN, NAS, EBS, NFS) |
| **Primary Advantage** | Extremely high performance, no network overhead | High availability, data durability, and fault tolerance |
| **Typical Technologies** | `emptyDir`, `secret`, `configMap`, `projected` | `PersistentVolume`, `PersistentVolumeClaim` |
| **Resource Management** | Declared directly inside the Pod spec | Separated API objects (`PV`, `PVC`, `StorageClass`) |

---

## Core Storage Abstractions

### 1. StorageClass (SC)
Defines a storage profile or policy (e.g., fast SSD vs. cheap HDD) and enables **Dynamic Provisioning** (automatically provisioning physical cloud disks when requested).
* `provisioner`: The Container Storage Interface (CSI) plugin handling volume creation (e.g., `ebs.csi.aws.com`, `pd.csi.storage.gcp.web.com`).
* `reclaimPolicy`: Dictates what happens to the underlying storage asset when its associated PVC is deleted:
  * `Delete` *(Default)*: Automatically deletes the physical cloud disk and the PV object.
  * `Retain`: Keeps the physical disk and data intact (`Released` state) for manual administrative recovery.
* `volumeBindingMode`:
  * `Immediate`: Provisions storage as soon as the PVC is created.
  * `WaitForFirstConsumer`: Delays volume creation until the Pod is scheduled. Ensures disk provisioning aligns with the Pod's node topology and Availability Zone (AZ).

### 2. PersistentVolume (PV)
A cluster-scoped resource representing physical or network storage (AWS EBS, GCP PD, NFS) provisioned manually by an admin or dynamically by a `StorageClass`. It is **not** bound to a specific Namespace.

### 3. PersistentVolumeClaim (PVC)
A Namespace-scoped storage request submitted by a developer. It specifies requirements such as storage size (e.g., `50Gi`) and access modes. The Control Plane automatically matches and binds the PVC to a suitable PV.

---

## Volume Access Modes

* **`ReadWriteOnce` (RWO):** Mounted as read-write by a **single Node** at a time. Multiple Pods running on the same node can share the volume. Standard for cloud block storage.
* **`ReadOnlyMany` (ROX):** Mounted as read-only by **many Nodes** simultaneously. Useful for shared static assets or reference databases across multi-replica Pods.
* **`ReadWriteMany` (RWX):** Mounted as read-write by **many Nodes** simultaneously. Requires network file systems like NFS, AWS EFS, or Ceph.
* **`ReadWriteOncePod` (RWOP):** Mounted as read-write by a **single Pod** across the entire cluster. Prevents concurrent write corruption across multiple Pods on the same node.

---

## Sample manifests
### 1. Storage Profile (`StorageClass`)
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
parameters:
  type: gp3
```

### 2.Storage Request (`PersistentVolumeClaim`)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-pvc
  namespace: data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 50Gi
```

### 3. Pod Mounting the PVC
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: db-pod
  namespace: data
spec:
  volumes:
    - name: storage-mount
      persistentVolumeClaim:
        claimName: db-pvc
  containers:
    - name: database
      image: postgres:15-alpine
      volumeMounts:
        - name: storage-mount
          mountPath: /var/lib/postgresql/data
```
