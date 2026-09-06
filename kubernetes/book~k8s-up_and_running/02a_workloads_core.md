# Workloads Core

In Kubernetes we can divide [Workloads](https://kubernetes.io/docs/concepts/workloads/) into 2 categories:
1. **Pods**, which are the essential building blocks of any workload and represent the actual running containers in the cluster.
2. **Workload Resources** (*Controllers* like Deployments, ReplicaSets, Job/CronJob or DaemonSets), which are high-level API mechanisms that automatically manage, scale, and orchestrate those Pods to maintain the desired state.

## 1. Pods

### What is a Pod?
[Pods](https://kubernetes.io/docs/concepts/workloads/pods/) are the smallest and ephemeral (stateless, temporary) deployable units that can be created in the K8S environment.
Pods can consist of **more than one container**. For example main container with it's Sidecars.
Pods follow a defined lifecycle, starting in the *Pending phase*, moving through *Running* if at least one of its primary containers starts OK, and then through either the *Succeeded or Failed* phases depending on whether any container in the Pod terminated in failure. 

To bridge the gap between these high-level phases, Kubernetes tracks specific Pod Conditions that mark technical milestones throughout this lifecycle, progressing in the following sequence:

```txt
[Pod Creation] 
       │
       ▼
 1. PodScheduled = True              (Scheduler has assigned the Pod to a node)
       │
       ▼
 2. PodReadyToStartContainers = True (Sandbox environment and networking are ready)
       │
       ▼
 3. Initialized = True               (All init containers have completed successfully)
       │
       ▼
 4. ContainersReady = True           (All main containers in the Pod are ready)
       │
       ▼
 5. Ready = True                     (Pod is healthy and ready to accept network traffic)
 ```

#### Useful comands for pod inspection
To inspect a Pod's conditions and general configuration using kubectl:
```bash
kubectl get pod <pod-name> -o yaml
```

To view the live container logs (standard output and error streams) to see what the application is doing:
```bash
kubectl logs <pod-name>
```
> Tip: Add `-f` to stream logs in real-time, or `-p` to view logs from a previous, crashed instance of the container.

> NOTE: Kubernetes retains logs for only **1 previous execution** of the container; if the container restarts a second time, the logs from the first crash are overwritten.


To inspect detailed lifecycle status, configuration, and a chronological history of cluster **Events** (errors, image pulls, scheduling actions):
```bash
kubectl describe pod <pod-name>
```

#### Shared Boundaries
- *Storage&RAM:* They can be thought of as a single physical or virtual machine. While each container has its own isolated memory (RAM) and its own isolated file system, they can optionally share specific directories through Kubernetes volumes.
- *Networking:* Every Pod gets its own unique IP address. All containers inside that Pod share this IP address and port space. This means Container A and Container B can talk to each other instantly using localhost (e.g., localhost:8080).
- *Lifecycle:* If the Pod dies, all containers inside it die. If the Pod is scaled up, a completely new instance of the Pod (with all its containers) is created on a node.

#### Sample single container Pod definition
Command:
```bash
kubectl run single-container-pod --image=nginx:1.25-alpine --port=80 --labels="app=my-app" --dry-run=client -o yaml > pod.yaml
```

Result:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: single-container-pod
  labels:
    app: my-app
spec:
  containers:
  - name: web-app
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
```

### Init containers
[Init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) are specialized containers that run **before the app containers in a Pod**. Kubernetes executes them sequentially (one after another). Each init container must run to completion and exit successfully (*with exit code 0*) before the next one starts. Only when all init containers have finished successfully does Kubernetes start the main application containers.
> NOTE: If a Pod has multiple init containers, Kubernetes executes them **one by one, strictly in the order they are defined in the YAML file** (from top to bottom).

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-init-pod
  labels:
    app: my-app
spec:
  # Init containers section - executed strictly from top to bottom
  initContainers:
  
  - name: 1st-init-wait-for-db       # <--- Starts FIRST
    image: busybox:1.36
    command: ['sh', '-c', 'until nc -z db-service 5432; do echo waiting for database; sleep 2; done']
  
  - name: 2nd-init-download-assets    # <--- Starts SECOND (only after the 1st exits with code 0)
    image: busybox:1.36
    command: ['sh', '-c', 'echo "Downloading static assets..."; sleep 5; echo "Done!"']
  
  # Main application containers section
  containers:
  - name: web-app                    # <--- Starts LAST (only after ALL init containers succeed)
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
```

### Sidecar containers
[Sidecar containers](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/) are secondary containers that run **alongside the main application container** within the same Pod. They start concurrently (technically slghtly before) with the main container and run for the entire lifecycle of the Pod. Their primary role is to extend, enhance, or support the main application by handling  / assistant tasks such as log shipping, proxying network traffic, or collecting metrics.
> NOTE: Common examples include an Istio Envoy proxy for handling network traffic or a secret injector container that mounts credentials into the Pod.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: single-container-pod
  labels:
    app: my-app
spec:
  # New native sidecar approach (Kubernetes 1.28 / 1.29+)
  initContainers:
  - name: istio-proxy
    image: docker.io/istio/proxyv2:1.24.0
    args:
    - proxy
    - sidecar
    # KEY FIELD: This makes the init container run for the entire Pod lifecycle
    restartPolicy: Always
    ports:
    - containerPort: 15001
      name: envoy-tunnel
  # Main app
  containers:
  - name: web-app
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
```

### Ephermal Containers
[An ephemeral container](https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/) is a temporary, diagnostic container injected into an already running Pod to troubleshoot issues without restarting the application or altering its original specification.
They are useful for interactive troubleshooting when `kubectl exec` is insufficient because a container has crashed or a container image doesn't include debugging utilities.

Practical example:
- Step 1. Let's assume that there is a following container:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: single-container-pod
  labels:
    app: my-app
spec:
  containers:
  - name: web-app
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
```

- Step 2. We notice of a potential issue and decide to attach a diagnostic container (busybox) into the running Pod on the fly.
```sh
kubectl debug -it single-container-pod --image=busybox --target=web-app
```

- Step 3. Once the terminal opens inside your new ephemeral container, you execute a local network test to see if Nginx responds on port 80.
```sh
# Inside the ephemeral container:
wget -qO- localhost:80
```
Expected output similar to this:
```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
</html>
```

- Step 4. While the ephemeral container was injected (or after it terminates), Kubernetes updates the cluster's internal state. If you fetch the live manifest from the API server, you see the injected result.
```sh
kubectl get pod single-container-pod -o yaml
```

Result:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: single-container-pod
  labels:
    app: my-app
spec:
  containers:
  - name: web-app
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
  # KUBERNETES AUTOMATICALLY INJECTED THIS SECTION:
  ephemeralContainers: 
  - image: busybox
    name: debugger-z6w2t
    targetContainerName: web-app
    stdin: true
    tty: true
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
```
> NOTE: If we use the `kubectl debug` command again on the same Pod, Kubernetes will append another item to the list under the ephemeralContainers section.


### Probes
Kubernetes lets you define [probes](https://kubernetes.io/docs/concepts/workloads/pods/probes/) to continuously monitor the health of containers in a Pod. A probe is a diagnostic performed periodically by the kubelet on a container. To perform a diagnostic, the kubelet either executes code within the container or makes a network request.

#### Types of probes:
| Probe Type | What it checks | Action on Failure | Typical Real-World Use Case |
| :--- | :--- | :--- | :--- |
| **Startup Probe** | Checks if the application inside the container has successfully started up. | **Restarts the container**. | Used for legacy or slow-starting apps that take a long time to load caches or initialize database connections. |
| **Liveness Probe** | Checks if the application is still running and hasn't frozen or deadlocked. | **Restarts the container**. | Catching a Java/Python app that is still running as a process but is stuck in a deadlock and cannot process threads. |
| **Readiness Probe** | Determines when a container is ready to accept traffic. | **Removes the Pod from Service endpoints** (stops sending traffic). | Temporarily stopping traffic to a backend app while it recalculates a heavy background task or reloads configuration. |

Example config:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: single-container-pod
  labels:
    app: my-app
spec:
  containers:
  - name: web-app
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
    # 1. STARTUP PROBE: Gives the application time to boot up
    startupProbe:
      httpGet:
        path: /index.html
        port: 80
      failureThreshold: 30    # Will try 30 times before giving up
      periodSeconds: 10       # Checks every 10 seconds (Total 300s / 5 mins maximum startup time)
    # 2. LIVENESS PROBE: Regularly checks if the app needs a restart
    livenessProbe:
      httpGet:
        path: /index.html
        port: 80
      initialDelaySeconds: 15 # Starts checking 15 seconds after Startup Probe succeeds
      periodSeconds: 20       # Performs the check every 20 seconds
    # 3. READINESS PROBE: Regularly checks if the app can handle incoming traffic
    readinessProbe:
      httpGet:
        path: /index.html
        port: 80
      initialDelaySeconds: 5  # Starts checking 5 seconds after Startup Probe succeeds
      periodSeconds: 10       # Performs the check every 10 seconds

```
#### Probe results
- **Success** -> The container passed the diagnostic.
- **Failure** -> The container failed the diagnostic. For *liveness and startup probes*, the kubelet kills the container, and the container is subjected to its restart policy. For *readiness probes*, the kubelet marks the container as not ready, and the Pod stops receiving traffic from matching Services.
- **Unknown** -> The diagnostic failed (no action should be taken, and the kubelet will make further checks).

## 2. Namespaces, Labels, Selectors and Annotations

### Namespaces
[Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) provide a mechanism for isolating groups of resources within a single cluster. Resource names must be **unique within a specific namespace**, but **not across different namespaces**. This namespace-based scoping applies exclusively to namespaced objects (e.g., Deployments, Services, etc.) that represent application-level workloads. Conversely, it does not apply to cluster-wide resources used for infrastructure administration (e.g., StorageClasses, Nodes, PersistentVolumes, etc.).

#### Essential Namespace commands
```bash
kubectl get namespace                     # List all namespaces
kubectl api-resources --namespaced=true   # Shows namespaced resources
kubectl api-resources --namespaced=false  # Shows cluster-wide resources (Nodes, PV, etc.)
```
> NOTE: Most Kubernetes resources (e.g. Pods, Services, Deployments, and others) are in some namespaces. However namespace resources are not themselves in a namespace. And low-level resources, such as Nodes and PersistentVolumes, are not in any namespace.

### Labels
[Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) are **key-value pairs** attached to Kubernetes objects (like Pods). They are intended to specify identifying attributes of objects that are meaningful and relevant to users.
> NOTE: Labels can be attached to objects at creation time and subsequently added and modified at any time. Each object can have a set of key/value labels defined. 

> Each Key must be unique for a given object.

#### Common use cases:
* Categorizing environments (`environment: dev`, `environment: prod`).
* Tracking application tiers (`tier: frontend`, `tier: backend`).
* Versioning (`release: stable`, `canary`).

#### Essential Label commands:
```bash
# View pods with their labels
kubectl get pods --show-labels

# Add or overwrite a label on a running pod
kubectl label pod my-pod app=nginx --overwrite

# Remove a label (suffix with a minus sign)
kubectl label pod my-pod app-
```

### Selectors
[Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors) are the core routing mechanism in Kubernetes. They define how resources link together (e.g., how a Service finds its Pods, or how a Deployment tracks its ReplicaSet).
Labels are simply **descriptive stickers** that you attach to your resources. Developer decides what to put and where to attach. Whereas Selectros are **filters** or queries that say: '*I'm only interested in resources that have a specific sticker*'.

Kubernetes supports two types of selectors:
1. **Equality-based (`matchLabels`):** Filters by exact key-value match.
2. **Set-based (`matchExpressions`):** Allows complex filtering using operators like `In`, `NotIn`, `Exists`, `DoesNotExist`.

#### Essential Selector commands:
```bash
kubectl get pods -l app=backend                              # matchLabels
kubectl get pods -l 'environment in (staging, production)'   # matchExpressions
```

### Annotations
[Annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) are also **key-value pairs**, but unlike Labels, they **cannot be used to select or group objects**. They are used to attach arbitrary non-identifying metadata to objects, which can be consumed by external tools, libraries, or system administrators.

#### Common use cases:
Once again, info intended for humans, automation scripts, CI/CD systems, or controllers inside Kubernetes. For instance:
- Storing deployment metadata (e.g., `kubernetes.io/change-cause: "Upgraded to v2"`) -> Shows history of app updates.
- Configuring cloud and network infrastructure (e.g., `service.beta.kubernetes.io/aws-load-balancer-type: "nlb"`) -> Triggers cloud load balancer creation.
- Enabling metrics collection and monitoring (e.g., `prometheus.io/scrape: "true"`) -> Tells Prometheus to scrape metrics.
- Tracking GitOps and CI/CD source information (e.g., `app.kubernetes.io/managed-by: "Helm"`) -> Verifies exact deployed code version.
- Adding team contact or ownership details (e.g., `owner: "team-alpha-backend@company.com"`) -> Routes alerts to responsible developers.
- Linking external documentation or playbooks (e.g., `confluence.link: "https://company.com"`) -> Opens troubleshooting instruction link quickly.

#### Essential Annotations commands:
```bash
# Annotate a resource
kubectl annotate pod my-pod description="This is a secure production backend"
# Delete Anotation
kubectl annotate pod my-pod description-
# Read one Anotation
kubectl get pod my-pod -o jsonpath='{.metadata.annotations.description}'
# Read all Anotations
kubectl get pod my-pod -o jsonpath='{.metadata.annotations}'
# At the top of the print
kubectl describe pod my-pod
```

### Example aggregating this subchapter
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-production-deployment
  namespace: production                  # Scopes this deployment to a specific environment
  labels:
    app.kubernetes.io/managed-by: Helm
spec:
  replicas: 3
  selector:
    matchLabels:                         # The Selector
      app: secure-backend                # Tells the deployment to look for Pods with this label
      tier: backend
  template:                              # Defines the blueprint for the Pods it will create
    metadata:
      labels:                            # The Labels
        app: secure-backend              # MUST match the selector above!
        tier: backend
        release: stable
      annotations:                       # Non-identifying metadata for tools/teams
        kubernetes.io/change-cause: "Upgraded to v2"
        prometheus.io/scrape: "true"
        owner: "team-alpha-backend@company.com"
        confluence.link: "https://company.com"
    spec:
      containers:
      - name: web-app
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80

```
Sample selector adressing to see if the mapping works:
```bash
# List all pods in the production namespace that match the selector
kubectl get pods -n production -l app=secure-backend,tier=backend
# View the pods alongside all their assigned stickers
kubectl get pods -n production --show-labels
```

## 3. Replicaset
[ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/) maintains a stable set of replica Pods running at any given time. Usually, you define a Deployment and let that Deployment manage ReplicaSets automatically.

### How does it work?
The mechanism relies on 3 main pillars:
1. **Declarative Approach:** You declare to the system *what* you want to achieve (e.g., *"I want 3 Pods with this specific label"*), rather than giving imperative commands on *how* to perform it.
2. **Autonomous System:** The cluster is managed by an ongoing **Reconciliation Loop**. It runs endlessly in the background following a strict three-step cycle: **Observe** (check the actual state) $\rightarrow$ **Compare** (match actual against desired state) $\rightarrow$ **Fix** (bring the cluster back to the desired state).
3. **Loose Coupling:** The controller does not track or "remember" specific Pods by their unique IDs which are stateless. Instead, it constantly queries the cluster using **Label Selectors** strictly within its assigned **Namespace**.

> **NOTE:** It is critical to understand that the **Controller** itself is a single, permanent background process running globally in the cluster (part of the `kube-controller-manager`). When you create a ReplicaSet, you are not spawning a new process; you are just creating a configuration *object*. 
> Furthermore, this architecture operates **per workload type**. Inside the `kube-controller-manager`, there is a dedicated, independent controller loop for each resource type (e.g., a *ReplicaSet Controller*, a *Deployment Controller*, a *DaemonSet Controller*, etc.). Each controller runs as an isolated thread, focusing exclusively on its own object type. This single global process uses its **Reconciliation Loop** to rapidly cycle through all your objects of that specific type—constantly checking, comparing, and fixing their states 24/7 without human intervention

### Practical Yaml example:
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: my-app-replicaset
  namespace: default
spec:
  # Define how many copies you want running continuously
  replicas: 3
  # The filter used by the controller to discover and track its Pods
  selector:
    matchLabels:
      app: my-app  
  # This is where the exact blueprint used to spin up new Pods starts
  template: 
    metadata:
      # CRITICAL: These labels MUST match the selector above perfectly!
      labels:
        app: my-app
    spec:
      containers:
      - name: web-app
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
``` 

### Why are `selector` and `template.labels` split into two sections?
At first glance, repeating the labels in both sections looks like redundant boilerplate code. However, this separation is a fundamental design pattern in Kubernetes called **Separation of Concerns**. They are kept apart for three critical reasons:
*   **Decoupling & Pod Autonomy:** The `template` block is a nested, fully independent `Pod` manifest definition. Keeping them separate allows Kubernetes to remain flexible, enabling advanced operations like "adopting" pre-existing standalone Pods or placing a malfunctioning Pod into "quarantine" simply by changing its labels on the fly without deleting it.
*   **Different Responsibilities (Search vs. Blueprint):** 
    *   `spec.selector.matchLabels` is a **query filter**. It tells the controller how to scan the namespace and find existing Pods.
    *   `spec.template.metadata.labels` is a **factory stamp**. It dictates what label to physically print onto a brand-new Pod when the controller needs to spin one up.
*   **Advanced Matching (`matchExpressions`):** While `matchLabels` is a simple 1:1 copy, Kubernetes selectors can use complex logical expressions (e.g., *find Pods where `tier` is either `frontend` OR `web`, but NOT `canary`*). If it were a single section, Kubernetes wouldn't know which exact label to assign to a newly created Pod.
> NOTE: In short; The selector defines *what to look for*, and the template defines *how to build it*.


## Next Step: Moving up the Abstraction Layer - follow to the [02b_workloads_controllers.md](02b_workloads_controllers.md)


**Pods, Labels, Namespaces, Selectors, and ReplicaSets** cover the foundational building blocks of the Kubernetes data plane. 

While a `ReplicaSet` technically runs a controller loop to keep Pods alive, it is a low-level primitive. In the latest Kubernetes version it is discouraged to use ReplicaSet. To quote the K8s docs:
> When to use a ReplicaSet?

> A ReplicaSet ensures that a specified number of pod replicas are running at any given time. However, a Deployment is a higher-level concept that manages ReplicaSets and provides declarative updates to Pods along with a lot of other useful features. Therefore, we recommend using Deployments instead of directly using ReplicaSets, unless you require custom update orchestration or don't require updates at all.

> This actually means that you **may never need to manipulate ReplicaSet objects: use a Deployment instead**, and define your application in the spec section.


The next section, [02b_workloads_controllers.md](02b_workloads_controllers.md), is a continuation of the current one.