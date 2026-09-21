# Storage and Volumes
In Kubernetes, storage management is decoupled from container lifecycles. Storage is categorized by its lifecycle relative to a Pod and is accessible via [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/): Ephemeral Volumes and Persistent Volumes.

---

## Ephemeral Volumes
[Ephemeral volumes](https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/) are tied directly to the lifetime of the Pod. If a Pod is evicted, deleted, or rescheduled to another node, all data stored within an ephemeral volume is **permanently destroyed**!

* **Primary Use Cases:** Application caching, temporary build workspaces, shared scratch space between containers within a Pod (Sidecar pattern), and configuration injection.
* **Key Ephemeral Types:**
  * `emptyDir`: A fresh, initially empty directory created on the host node when the Pod starts. Can run on physical host disk or directly out of RAM (`medium: Memory`).
  * `configMap` & `secret`: Inject cluster configurations, flags, or credentials as files into the container filesystem.
  * `projected`: Maps several existing volume sources (`secret`, `configMap`, `downwardAPI`, `serviceAccountToken`) into a single unified directory.
  * **Generic Ephemeral Volumes:** Allows third-party CSI drivers to create dynamic, short-lived volumes using standard PVC specs that follow the Pod lifecycle. Enforces hard capacity limits and custom performance profiles directly inside the Pod spec.

## Persistent Volumes
[Persistent volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) is compltely decoupled from the Pod lifecycle. Data survives Pod restarts, container crashes, rescheduling, and physical host failures. When a Pod dies, Kubernetes can recreate it on another node and reattach the existing network storage.

* **Primary Use Cases:** Stateful workloads including relational databases (PostgreSQL, MySQL), NoSQL stores (MongoDB), message brokers (Kafka), and shared file systems.
* **Management Model:** Handled via dedicated API objects that separate cluster administration from developer consumption: `StorageClass`, `PersistentVolume` (PV), and `PersistentVolumeClaim` (PVC).

---

## Direct Comparison

| Feature | Ephemeral Volumes | Persistent Volumes |
| :--- | :--- | :--- |
| **Lifecycle Binding** | Tied directly to the Pod lifetime | Completely independent of the Pod |
| **Pod Eviction / Deletion** | Data is permanently destroyed | Data safely remains on external storage |
| **Physical Location** | Local node storage (SSD or RAM) | Network-attached / Cloud storage (SAN, NAS, EBS, NFS) |
| **Primary Advantage** | Extremely high performance, no network overhead | High availability, data durability, and fault tolerance |
| **Typical Technologies** | `emptyDir`, `secret`, `configMap`, `projected` | `PersistentVolume`, `PersistentVolumeClaim` |
| **Resource Management** | Declared directly inside the Pod spec | Separated API objects (`PV`, `PVC`, `StorageClass`) |

---

## Core Storage Abstractions

### 1. [StorageClass (SC)](https://kubernetes.io/docs/concepts/storage/storage-classes/)
Defines a storage profile or policy (e.g., fast SSD vs. cheap HDD) and enables **Dynamic Provisioning** (automatically provisioning physical cloud disks when requested).
* `provisioner`: The Container Storage Interface (CSI) plugin handling volume creation (e.g., `://aws.com`, `://web.com`).
* `reclaimPolicy`: Dictates what happens to the underlying storage asset when its associated PVC is deleted:
  * `Delete` *(Default)*: Automatically deletes the physical cloud disk and the PV object.
  * `Retain`: Keeps the physical disk and data intact (`Released` state) for manual administrative recovery.
* `volumeBindingMode`:
  * `Immediate`: Provisions storage as soon as the PVC is created.
  * `WaitForFirstConsumer`: Delays volume creation until the Pod is scheduled. Ensures disk provisioning aligns with the Pod's node topology and Availability Zone (AZ).
* `allowVolumeExpansion`: When set to `true`, it allows resizing volumes on-the-fly by modifying the `storage` request in the PVC without deleting it.

### 2. PersistentVolume (PV)
A cluster-scoped resource representing physical or network storage (AWS EBS, GCP PD, NFS) provisioned manually by an admin or dynamically by a `StorageClass`. It is **not** bound to a specific Namespace.

### 3. PersistentVolumeClaim (PVC)
A Namespace-scoped storage request submitted by a developer. It specifies requirements such as storage size (e.g., `50Gi`) and access modes. The Control Plane automatically matches and binds the PVC to a suitable PV.

---

## Advanced Storage Mechanisms

### Volume Mode Configuration
* **Filesystem (`volumeMode: Filesystem`):** The default mode. Kubernetes creates a filesystem on the device before mounting it into the Pod.
* **Raw Block (`volumeMode: Block`):** Bypasses the filesystem layer entirely. The volume is presented to the Pod as a raw block device. Ideal for ultra-high-performance databases (e.g., direct I/O operations).

### PV Lifecycle Phases
1. **Available:** A free storage resource ready to be bound to a claim.
2. **Bound:** The PV is successfully linked to a specific PVC.
3. **Released:** The PVC was deleted, but the physical resource is kept intact for manual administrative recovery (under `Retain` policy).
4. **Failed:** The automated reclamation or cleanup process encountered an error.

### Storage Object in Use Protection
Kubernetes uses finalizers to prevent data loss or accidental deletion of active storage resources:
* **PVC Protection:** Deleting a PVC currently mounted by a live Pod is postponed (`Terminating` state) until the Pod is safely removed.
* **PV Protection:** Deleting a PV that is still bound to a PVC is blocked until the underlying application release constraint is lifted.

### Backup & Recovery (Snapshots)
* **VolumeSnapshotClass:** Defines the backup cluster infrastructure profile (e.g., cloud provider snapshot integration).
* **VolumeSnapshot:** A request to create a point-in-time copy/backup of a `PersistentVolumeClaim`. This snapshot can later be targeted as the `dataSource` in a new PVC manifest to restore data.

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
provisioner: ://aws.com
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
parameters:
  type: gp3
```

### 2. Storage Request (`PersistentVolumeClaim`)
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

### 4. Projected Volume (Consolidating Sources)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: projected-pod
  namespace: data
spec:
  containers:
    - name: app
      image: nginx:alpine
      volumeMounts:
        - name: shared-data
          mountPath: /app/shared
  volumes:
    - name: shared-data
      projected:
        sources:
          - configMap:
              name: app-config
          - serviceAccountToken:
              path: token
              expirationSeconds: 3600
```
**Description:** This manifest merges multiple distinct volume sources into a single, unified directory inside the container. It allows applications to seamlessly access configurations, secrets, and system tokens from one shared location without creating multiple mount points.

---

### 5. Generic Ephemeral Volume (Inline Dynamic Provisioning)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ephemeral-compute-pod
  namespace: data
spec:
  containers:
    - name: data-cruncher
      image: ubuntu:24.04
      command: ["/bin/bash", "-c", "echo 'processing' > /scratch/data.log && sleep 3600"]
      volumeMounts:
        - name: high-perf-scratch
          mountPath: /scratch
  volumes:
    - name: high-perf-scratch
      ephemeral:
        volumeClaimTemplate:
          spec:
            accessModes: [ "ReadWriteOnce" ]
            storageClassName: "fast-ssd"
            resources:
              requests:
                storage: 20Gi
```
**Description:** This manifest triggers the dynamic provisioning of a high-performance cloud disk that exists solely for the lifetime of this specific Pod. Once the Pod is deleted or rescheduled, Kubernetes automatically triggers a cascading deletion to wipe and destroy the underlying physical storage.

---

### 6. Volume Snapshot (Point-in-Time Backup)
```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: db-snapshot
  namespace: data
spec:
  volumeSnapshotClassName: csi-aws-vsc
  source:
    persistentVolumeClaimName: db-pvc
```
**Description:** This manifest captures a point-in-time backup copy of the data currently stored within an active `PersistentVolumeClaim`. The resulting snapshot can be used later as a data source to provision a new, identical volume for disaster recovery or testing.
