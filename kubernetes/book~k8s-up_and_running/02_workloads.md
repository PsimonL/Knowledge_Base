# Workloads

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
```sh
kubectl get pod <pod-name> -o yaml
```

To view the live container logs (standard output and error streams) to see what the application is doing:
```sh
kubectl logs <pod-name>
```
> Tip: Add `-f` to stream logs in real-time, or `-p` to view logs from a previous, crashed instance of the container.

> Note: Kubernetes retains logs for only **1 previous execution** of the container; if the container restarts a second time, the logs from the first crash are overwritten.


To inspect detailed lifecycle status, configuration, and a chronological history of cluster **Events** (errors, image pulls, scheduling actions):
```sh
kubectl describe pod <pod-name>
```

#### Shared Boundaries
- *Storage&RAM:* They can be thought of as a single physical or virtual machine. While each container has its own isolated memory (RAM) and its own isolated file system, they can optionally share specific directories through Kubernetes volumes.
- *Networking:* Every Pod gets its own unique IP address. All containers inside that Pod share this IP address and port space. This means Container A and Container B can talk to each other instantly using localhost (e.g., localhost:8080).
- *Lifecycle:* If the Pod dies, all containers inside it die. If the Pod is scaled up, a completely new instance of the Pod (with all its containers) is created on a node.

#### Sample single container Pod definition
Command:
```sh
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
> Note: If a Pod has multiple init containers, Kubernetes executes them **one by one, strictly in the order they are defined in the YAML file** (from top to bottom).

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
> Note: Common examples include an Istio Envoy proxy for handling network traffic or a secret injector container that mounts credentials into the Pod.

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
> Note: If we use the `kubectl debug` command again on the same Pod, Kubernetes will append another item to the list under the ephemeralContainers section.


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

## 2. Labels and Annotations

## 3. Replicaset

## 4. Deployment

## 5. DaemonSet

## 6. Job and Cronjob

## 7. Singleton

## 8. StatefulSet