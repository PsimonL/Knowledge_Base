# Workloads Controllers
Kubernetes Workload Controllers are built-in control loops that manage the Pod lifecycle and automatically ensure the application's actual state matches your desired state. Running in a continuous Reconciliation Loop, they observe the cluster's current status and compare it against the YAML configuration. If a mismatch is detected—such as a Pod failure—the controller instantly intervenes to fix it by launching a replacement Pod

## 1. Deployment
[A Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) is the primary, declarative orchestrator used to manage the lifecycle of stateless applications. The main difference between ReplicaSets and Deployment is that Deployment sits as a higher-level abstraction that manages ReplicaSets to allow declarative application updates (rollouts and rollbacks) -> Kubernetes objects encapsulation. This is stateless workload.

### Capabilities
- **Automated Rollouts & Rollbacks** -> Transitions Pods to a new configuration without downtime using `RollingUpdate` or `Recreate` strategies. It maintains a historical log of revisions under the hood, allowing you to instantly revert to a previous working state via `kubectl rollout undo` if a new container image crashes or exhibits bugs.
- **Pause and Resume** -> Freezes an active rollout process mid-way, allowing operators to inspect application stability, review logs, or execute manual canary analysis before fully committing to the deployment. It also enables batching multiple container manifest modifications into a single rollout trigger.
- **Progress Deadlines** -> Monitors the health of an active deployment and automatically triggers a failure state (`DeadlineExceeded`) if new Pods fail to achieve a `Ready` status within a user-defined timeframe (e.g., due to a `CrashLoopBackOff` or `ImagePullBackOff`), allowing CI/CD pipelines to catch bad deploys.
- **Horizontal Auto-scaling** -> Integrates seamlessly with the HorizontalPodAutoscaler (HPA) to dynamically increase or decrease the number of running Pod replicas in real-time, responding automatically to traffic surges, spikes, or changes in resource metrics like CPU and Memory consumption.
- **Environment Consistency (Deployment vs. ReplicaSet)** -> Guarantees uniform multi-environment state definitions (Dev, Staging, Production) across the entire application lifecycle. While a raw `ReplicaSet` can define identical initial parameters (replicas, labels, images, and resource limits), it cannot enforce consistency during live updates. If a `ReplicaSet` template is modified, it ignores running Pods, requiring manual Pod deletion to apply updates. A `Deployment` solves this by wrapping around `ReplicaSets`, automatically orchestrating active, zero-downtime structural adjustments across all target environments.

### Common use cases
- **Any type of Web Servers & Stateless Microservices** -> Running application instances (e.g., Nginx, Node.js, Spring Boot API) that do not store persistent data on the local node's disk.


### Yaml example
```yaml
# ==============================================================================
# 1. DEPLOYMENT LAYER (Manages rollout strategies, revisions, and history logs)
# ==============================================================================
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app-deployment
  namespace: default
  labels:
    app: my-app
spec:
  # Rollout Protection & Safety Nets -> Deployment-exclusive properties
  progressDeadlineSeconds: 300    
  revisionHistoryLimit: 10         
  # Update Strategy Configuration -> Deployment-exclusive properties
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%        
      maxUnavailable: 0    
  # ============================================================================
  # 2. REPLICASET LAYER (Deployment injects these fields into the generated ReplicaSet)
  # ============================================================================
  # Scaling Configuration (Maintained dynamically by the ReplicaSet controller)
  replicas: 3
  # Target Selector (Tells the ReplicaSet exactly which Pods it must monitor)
  selector:
    matchLabels:
      app: my-app
  # ============================================================================
  # 3. POD LAYER (The blueprint template used by the ReplicaSet to spawn Pods)
  # ============================================================================
  # Pod Template (This acts identically to a standalone "kind: Pod" manifest)
  template:
    metadata:
      labels:
        app: my-app # CRITICAL: This must match the selector.matchLabels above!
    spec:
      containers:
      - name: web-app
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
          name: http
        # Environment Consistency (Container configurations inside the Pod)
        resources:
          limits:
            cpu: "500m"
            memory: "512Mi"
          requests:
            cpu: "250m"
            memory: "256Mi"
        # Health Monitoring (Probes verifying the runtime state inside the container)
        readinessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 15
          periodSeconds: 20
```

## 2. DaemonSet
A [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/) ensures that an exact copy of a designated Pod runs on all or a targeted subset of Nodes within the cluster. As nodes are removed from the cluster, those Pods are garbage collected. Also this is one of the stateless workloads.

### Kubernetes cluster Nodes limitations
1. `nodeSelector` -> Matches exact labels assigned to your nodes. This is *Equality-Based Selector*. The Pods will only run on nodes that have the specified key-value pair. For example:
```yaml
...
nodeSelector:
  disktype: "ssd"  # Runs only on nodes with this label
...
```
2. `affinity` / `nodeAffinity` -> Allows for complex logic using expressions (e.g., "run only in availability zones A or B", or "prefer these nodes but don't require them") and bases on *Set-Based Selectors*. For example:
```yaml
...
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: topology.kubernetes.io/zone
          operator: In
          values:
          - us-east-1a
          - us-east-1b
...
```
3. `tolerations` - `Taints` ->  Allows a node to repel a set of pods (Taints). A Taint allows a node to repel a set of pods. A pod will only run on a tainted node if it explicitly carries a matching Toleration. Unlike selectors which attract pods to nodes, taints are used to protect nodes from accidental scheduling. Unlike selectors which attract pods, taints drive back. These are used to protect nodes from accidental scheduling. For example:
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: gpu-monitoring-agent
spec:
  selector:
    matchLabels:
      app: gpu-monitor
  template:
    metadata:
      labels:
        app: gpu-monitor
    spec:
      containers:
      - name: monitor-container
        image: monitoring-image:latest
      # Assuming the Node was tainted via CLI: kubectl taint nodes node1 specialized=gpu:NoSchedule
      tolerations:
      - key: "specialized"    # Matches the key of the taint on the node
        operator: "Exists"     # Allows scheduling as long as the key exists
        effect: "NoSchedule"   # Matches the scheduling effect of the taint
```

### Typical use cases:
- Log Collection -> Running a log shipping daemon on every node to collect container logs and send them to a central storage. For example: Fluentd, Fluent Bit, Logstash, Vector.
- Monitoring & Metrics -> Deploying a metrics exporter on every node to monitor hardware metrics like CPU utilization, memory usage, disk space, and temperature. Examples: Prometheus Node Exporter, Datadog Agent.
- Cluster Networking -> Running a network plugin on every node which is a standard Container Network Interface practice, to enable communication between pods across different machines. Examples: Calico, Cilium, Flannel. 
- Security & Vulnerability Scanning -> Deploying security agents that monitor system calls, detect intrusions, or scan for vulnerabilities directly on the host operating system. Examples: Falco.
- Hardware-Specific Agents -> Using a nodeSelector combined with a DaemonSet to run device initialization plugins only on specialized machines. . For example, an NVIDIA GPU device plugin running only on nodes with dedicated GPU resources for AI/ML-related pods.

### Yaml example:
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: prometheus-node-exporter
  namespace: kube-system # Standard namespace for cluster-wide infrastructure agents
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      # Allows the pod to collect network metrics directly from the host machine
      hostNetwork: true
      hostPID: true
      # Tolerates all taints to ensure monitoring runs on EVERY node (including control-plane)
      tolerations:
      - operator: Exists
        effect: NoSchedule
      containers:
      - name: node-exporter
        image: quay.io/prometheus/node-exporter:v1.8.2
        args:
          - "--path.rootfs=/host"
        ports:
        - containerPort: 9100
          hostPort: 9100
          name: metrics
        volumeMounts:
        - name: host-sys-root
          mountPath: /host
          readOnly: true
      # Mounts the host's root filesystem so the agent can read actual disk/CPU/RAM metrics
      volumes:
      - name: host-sys-root
        hostPath:
          path: /
```
> NOTE: Think of a **Taint** as a lock placed on a Node to keep unwanted applications away, while a **Toleration** is the key carried by the Pod. Instead of updating the Node's configuration for every new application, Kubernetes puts the responsibility on the Pod's YAML to explicitly declare that it has permission to bypass that specific restriction.


## 3. Job and Cronjob

### Job
A [Job](https://kubernetes.io/docs/concepts/workloads/controllers/job/) creates one or more Pods and ensures that a specified number of them successfully terminate. Unlike a Deployment (which runs continuously), a Job is meant for tasks that run until completion. When a specified number of successful completions is reached, the task is completed. Deleting a Job will clean up the Pods it created. Suspending a Job will delete its active Pods until the Job is resumed again.
> NOTE: You can also use a Job to run multiple Pods in parallel.

#### Key fields in the `spec` template:
- `completions`: The **total** number of Pods that must finish successfully for the Job to be marked as complete.
- `parallelism`: The maximum number of Pods allowed to run **simultaneously** at any given time.
- `backoffLimit`: Number of retries before marking the Job as failed (default: 6).
- `activeDeadlineSeconds`: A hard duration limit (in seconds). If exceeded, K8s terminates all active Pods and fails the Job.
> NOTE: The deafult `restartPolicy` is always set to `Always` value. For **Job** it's **strictly forbidden** and will cause a validation error. You must explicitly set it to: `OnFailure` or `Never`. 

#### Completion Modes (`.spec.completionMode`)
Jobs can operate in two different completion modes:
- **`NonIndexed` (Default):** All Pods are identical and interchangeable. The Job is complete as soon as any `.spec.completions` number of Pods succeed.
- **`Indexed`:** Each Pod gets a unique, static index from `0` to `.spec.completions-1` (available in the Pod via the `JOB_COMPLETION_INDEX` environment variable or hostname as `$(job-name)-$(index)`). The Job is only complete when there is **at least one successful Pod for every single index**.

#### Pod Replacement Policy (`.spec.podReplacementPolicy`)
By default, if a Pod fails or is in a *Terminating* state (e.g., node eviction), the Job controller instantly creates a replacement Pod. This can cause the number of concurrent running Pods to briefly exceed `.spec.parallelism` limit for a short moment of time.
- If you have strict resource constraints, you can set `podReplacementPolicy: Failed`. This tells K8s to wait until the old Pod is **completely dead** (`Failed` phase) before spawning a new one.

#### Automatic Cleanup / TTL (`.spec.ttlSecondsAfterFinished`)
Completed or failed Jobs stay in the cluster forever for log inspection. To prevent API server clutter and avoid orphaned pods, use the TTL mechanism:
- **`ttlSecondsAfterFinished: 100`**: Automatically and cascadingly deletes the Job and all its leftover Pods exactly 100 seconds after completion.
- Setting this to `0` triggers immediate deletion after the Job finishes.

### Job Yaml example:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pi-job
spec:
  template:
    spec:
      containers:
      - name: pi
        image: perl:5.34.0
        command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4
```

### CronJob
A [CronJob](https://kubernetes.io) manages time-based **Jobs**, running them periodically on a given schedule (written in standard Linux Cron format). One CronJob object acts like a single line of a `crontab` file. 

> NOTE: A CronJob does NOT create or manage Pods directly. It acts as a controller that triggers and monitors **Job** objects, which in turn manage the underlying Pods.


#### Key fields in the `spec` template:
- `schedule`: The cron schedule string (e.g., `"*/5 * * * *"` for every 5 minutes) that drives the execution.
- `concurrencyPolicy`: Specifies how to handle overlapping executions if a new Job is triggered while the previous Job is still running:
  - `Allow` (Default): Runs concurrent Jobs simultaneously.
  * `Forbid`: Skips the new execution entirely if the previous one hasn't finished yet.
  * `Replace`: Cancels/deletes the currently running Job and spawns a brand-new one.
- `startingDeadlineSeconds`: The maximum allowed delay (in seconds) for starting a missed Job (e.g., due to cluster resource limits or controller downtime). If the delay exceeds this value, the execution is skipped for that cycle.
- `successfulJobsHistoryLimit`: The number of successful completed Jobs to keep in the cluster history for debugging (default: 3).
- `failedJobsHistoryLimit`: The number of failed Jobs to keep in the cluster history for debugging (default: 1).

> NOTE: Unlike standalone Jobs which stay in the cluster forever, CronJobs automatically clean up their oldest execution history once the `successfulJobsHistoryLimit` or `failedJobsHistoryLimit` is breached.

#### CronJob schedule syntax
```
# ┌───────────── minute (0 - 59)
# │ ┌───────────── hour (0 - 23)
# │ │ ┌───────────── day of the month (1 - 31)
# │ │ │ ┌───────────── month (1 - 12)
# │ │ │ │ ┌───────────── day of the week (0 - 6) (Sunday to Saturday)
# │ │ │ │ │                                   OR sun, mon, tue, wed, thu, fri, sat
# │ │ │ │ │
# │ │ │ │ │
# * * * * *
```

### CronJob Yaml example:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: echo-cronjob
spec: 
  # ==========================================================================
  # LEVEL 1: CronJob Spec (.spec)
  # Controls: WHEN and HOW OFTEN the task triggers + how history is managed.
  # ==========================================================================
  schedule: "*/5 * * * *"
  concurrencyPolicy: Forbid
  startingDeadlineSeconds: 60
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      # ==========================================================================
      # LEVEL 2: Job Spec (.spec.jobTemplate.spec)
      # Controls: WHAT CONSTITUTES A SUCCESSFUL TASK (completions, retries).
      # ==========================================================================
      completions: 1
      parallelism: 1
      backoffLimit: 2
      activeDeadlineSeconds: 300
      template:
        spec:
          # ==========================================================================
          # LEVEL 3: Pod Spec (.spec.jobTemplate.spec.template.spec)
          # Controls: THE ACTUAL CONTAINER EXECUTION (images, commands, volumes).
          # ==========================================================================
          containers:
          - name: worker
            image: busybox
            command: ["sh", "-c", "echo 'Running scheduled task...'; sleep 5"]
          # MANDATORY: Must be set to Never or OnFailure (validation error if omitted/Always)
          restartPolicy: OnFailure
```

## 4. Singleton
The Singleton is not a native Kubernetes object, it's rather a type of  an architectural deployment design pattern. Typically implemented via a Deployment with replicas: 1 or a StatefulSet with 1 replica used for non-distributed legacy applications or single-instance stateful services.
A single Pod instance is bound to a cloud persistent block storage volume (a PersistentVolume using ReadWriteOnce access mode).

- High Availability without Replication: If the underlying Node crashes, the Kubernetes Control Plane reschedules the single Pod onto a healthy Node and re-attaches the exact same network persistent volume, maintaining data integrity.

- Trade-off: Lack of horizontal scaling and brief downtime during Pod migration between nodes.

### Yaml example:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: legacy-mysql-singleton
spec:
  replicas: 1
  strategy:
    type: Recreate      # Prevents multi-attach errors on RWO volume during updates
  selector:
    matchLabels:
      app: mysql-db
  template:
    metadata:
      labels:
        app: mysql-db
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-persistent-storage
        persistentVolumeClaim:
          claimName: mysql-pvc
```

### Architectural Limitations & Workaround Context

This pattern is a popular, simplified workaround suitable **only for specific, simple scenarios** (such as legacy monolithic applications). While using a Deployment with a `Recreate` strategy solves one critical infrastructure roadblock, **it is not a full replacement for a StatefulSet.**

#### What specific problem does this pattern solve?
It prevents **Multi-Attach errors** during application updates. 
Under the default `RollingUpdate` strategy, Kubernetes attempts to spin up a new Pod before killing the old one. If your volume uses `ReadWriteOnce` (RWO) access mode, the cloud provider will block the new Pod from starting because the old Pod is still holding the disk lock. By forcing `strategy: type: Recreate`, Kubernetes guarantees it will **completely terminate the old Pod and detach the volume first**, before creating the new Pod and mounting the storage.

#### What features of a StatefulSet does this pattern fail to replace?
- **No Horizontal Scaling (e.g., Read Replicas):** If you scale a standard Deployment beyond `replicas: 1`, every new Pod will attempt to mount the exact same `mysql-pvc` claim, causing immediate multi-attach failures. A StatefulSet bypasses this limitation entirely through `volumeClaimTemplates`, which automatically provision a unique, independent Persistent Volume (PV) for each individual Pod instance.
- **No Stable Network Identity or DNS:** In a Deployment, Pods are ephemeral and interchangeable. Every time the Pod restarts or migrates to a different node, its name changes completely (e.g., from `legacy-mysql-singleton-abc12` to `legacy-mysql-singleton-xyz98`). A StatefulSet guarantees strict, predictable naming (e.g., `mysql-0`) linked to a Headless Service, providing stable DNS records that remain unchanged across the Pod's lifecycle.
- **Random Startup and Shutdown Order:** Deployments manage Pods concurrently and randomly. They completely lack the ordered, deterministic execution found in a StatefulSet, which enforces sequential operations (e.g., launching `pod-0`, waiting for it to be `Ready`, then launching `pod-1`). This strict ordering is mathematically necessary for clustering, bootstrapping, and data synchronization in distributed stateful systems.

## 5. StatefulSet
[StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) is the specialized workload controller designed for distributed, clustered stateful applications (e.g., PostgreSQL, Kafka, MongoDB, Elasticsearch, Cassandra) where Pods require persistent network identities and individual storage. 

### Characteristics
- **Stable Network Identity**: Pods receive predictable, zero-indexed ordinal names (db-0, db-1, db-2) instead of random hashes.
- **Dedicated Storage (volumeClaimTemplates)**: Dynamically provisions an independent PersistentVolumeClaim (PVC) for each Pod replica. If db-1 fails, its replacement Pod automatically re-attaches to the exact volume dedicated to db-1.
- **Ordered Execution**: Operations (creation, updates, scaling, deletion) occur sequentially (0 to N-1). Kubernetes waits for db-0 to pass its Readiness Probe before spawning db-1, protecting leader election mechanisms and preventing split-brain scenarios.
- **Headless Service**: StatefulSets require a companion Headless Service (clusterIP: None) to create direct DNS A-records for individual Pods (e.g., db-0.db-service.default.svc.cluster.local) for peer discovery.

### **Update Strategies (`spec.updateStrategy.type`)**:
- `RollingUpdate`: The default behavior. Pods are deleted and recreated in reverse ordinal order (from `N-1` down to `0`). Kubernetes waits for each Pod to become `Ready` before moving to the next.
- `OnDelete`: The controller will not automatically update Pods when the `.spec.template` is modified. You must manually delete individual Pods to trigger the update on them.

### **Partitioning (`spec.updateStrategy.rollingUpdate.partition`)**:
- If a partition is specified, all Pods with an ordinal greater than or equal to the partition value will be updated when the template changes. All Pods with a smaller ordinal will remain untouched (useful for Canary deployments).

### **Pod Management Policy (`spec.podManagementPolicy`)**:
- `OrderedReady`: The default behavior. Pods are created sequentially (0 to N-1) and deleted in reverse order.
- `Parallel`: Pods are launched or terminated concurrently without waiting for previous ones, reducing scaling time while still maintaining unique identities and dedicated PVCs.

### **PVC Retention Policy (`spec.persistentVolumeClaimRetentionPolicy`)**:
- Controls whether PVCs are deleted or retained during the lifecycle of the StatefulSet.
- `whenDeleted`: Configures what happens to PVCs when the entire StatefulSet is deleted (`Retain` or `Delete`).
- `whenScaled`: Configures what happens to PVCs when the number of replicas is reduced (`Retain` or `Delete`).


### Yaml example:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: redis-headless
  labels:
    app: redis
spec:
  ports:
  - port: 6379
    name: redis
  clusterIP: None # Key setting that defines this as a Headless Service
  selector:
    app: redis
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis-cluster
spec:
  serviceName: "redis-headless"
  replicas: 3
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7.0-alpine
        ports:
        - containerPort: 6379
          name: redis
        # Health probes ensure the correctness of Ordered Execution guarantees
        readinessProbe:
          exec:
            command: ["redis-cli", "ping"]
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          exec:
            command: ["redis-cli", "ping"]
          initialDelaySeconds: 10
          periodSeconds: 10
        volumeMounts:
        - name: redis-data
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: redis-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "standard"
      resources:
        requests:
          storage: 10Gi
```

## 6. Deployment Strategies
