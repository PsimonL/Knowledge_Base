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

### Yaml example:
```yaml
```

## 5. StatefulSet

### Yaml example:
```yaml
```

## 6. Deployment Strategies
