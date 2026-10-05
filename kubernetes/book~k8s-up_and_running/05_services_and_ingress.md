# Services and Ingress

## Characteristics of the Kubernetes network model
- **IP-per-Pod Architecture:** Every Pod in a Kubernetes cluster automatically receives its own unique, fully routable internal IP address.
- **Flat Networking:** All Pods can communicate directly with any other Pod on any worker node without using Network Address Translation (NAT) or port mapping.
- **The Volatility Problem:** Pods are completely ephemeral (temporary). When a Pod dies or scales down, its IP is permanently lost. When a new one takes its place, it gets a completely different IP. 
- **The Solution:** Kubernetes requires a stable abstraction layer—Services—to act as a persistent gateway in front of these shifting Pod IPs.

---

## Service Types
- **ClusterIP:** This is the default Kubernetes service type that exposes the service on an internal IP within the cluster. 
    - **Work rule:** It provides a single stable IP address and DNS name accessible only by other resources inside the same Kubernetes cluster.
    - **Traffic Flow:** `Pod A → ClusterIP → Pod B (internal only)`.
    - **Best Used For:** Internal microservices communication, databases, or any backend component <u>that should never be exposed directly</u> to the outside world.
- **NodePort:** This service type exposes the service externally by opening a specific static port on every node in the cluster.
    - **Work rule:** It builds on top of ClusterIP and routes external traffic received on a designated port (usually 30000–32767) on any node directly to the internal service.
    - **Traffic Flow:** `External Client → Any Node IP:NodePort → ClusterIP → Pod`.
    - **Best Used For:** Non-production environments, quick demonstrations, or scenarios where you want to configure own external load balancers manually.
- **LoadBalancer:** This service type automates cloud infrastructure provisioning to expose application to the internet.
    - **Work rule:** It defines a direct integration with public cloud provider's API (such as AWS). When created, Kubernetes automatically requests the cloud provider to spin up a physical or virtual external Load Balancer (e.g., AWS ELB). The cloud provisions a stable, public-facing IP address that accepts all internet traffic and distributes it straight into cluster's nodes.
    - **Traffic Flow:** `External Client → Cloud Load Balancer → NodePort → ClusterIP → Pod`.
    - **Best Used For:** Production applications requiring a single, highly available public IP address that automatically scales and routes external internet traffic into the cluster.
- **ExternalName:** This service type acts purely as an internal DNS alias for resources located completely outside of the Kubernetes cluster.
    - **Work rule:** It allows internal cluster applications to look up and connect to an external resource (like an external database) using a simple, local cluster domain name. Hypothetically if that external database is later migrated inside the cluster, there is a need only to change this single Service definition to a ClusterIP.
    - **Traffic Flow:** `Internal Pod → Kubernetes DNS lookup → External CNAME target (outside the cluster)`.
    - **Best Used For:** Seamlessly connecting internal cluster microservices to legacy workloads, external cloud databases, or third-party APIs without hardcoding external endpoints into application code.

---

## Under the Hood Mechanics (How Services Find Pods)
- **Label Selectors:** Services completely ignore ephemeral Pod IPs during configuration. Instead, they use a declarative query system (e.g., *"Route traffic to Pods with the label `app: frontend`"*). When a Pod dies and a new one replaces it, the new Pod inherits the same label, and the Service automatically includes it in the traffic pool without manual intervention.
- **The Target Registry Evolution: Endpoints vs. EndpointSlices:** Once a selector matches Pods, their real-time IPs and ports are stored in a backend API object for network routing:
    - **Classic Endpoints (Legacy):** A single monolithic object that grouped **all** matching Pod IPs into one massive list. At scale (e.g., 1,000 Pods), a single Pod IP change forced the entire list to be updated and pushed to every node, creating heavy network overhead and `etcd` performance degradation.
    - **Modern EndpointSlices (Current Standard):** Replaced the legacy Endpoints object to solve this scalability bottleneck. It splits network targets into **multiple smaller, independent slices** (default max: 100 endpoints per slice). When a Pod changes, only its specific slice is modified and retransmitted, drastically reducing control plane and network stress in large environments.
- **The Role of kube-proxy in Rule Mapping:** The `kube-proxy` daemon running on every worker node continuously watches `EndpointSlices` for changes. The microsecond a new Pod IP appears, `kube-proxy` programs the host kernel's packet filtering engine (**iptables** or **IPVS**). These low-level operating system rules physically intercept incoming network traffic and blindly forward it straight to the actual Pod IPs.
- **Service Discovery (CoreDNS):** The built-in CoreDNS server monitors the cluster and instantly registers a persistent, unique DNS record the moment a Service is created. This abstracts inter-pod communication completely—microservices never need to track shifting IPs; they simply send requests to a stable domain name like `service-name.namespace.svc.cluster.local`.
- **The Role of kube-proxy in Rule Mapping:** The `kube-proxy` daemon running on every single worker node continuously watches (listens for) updates to these `EndpointSlices`. The exact microsecond a new Pod IP appears in a slice, `kube-proxy` intercepts the change and translates it into low-level host operating system instructions. It instantly programs the host kernel's packet filtering engine (**iptables** or **IPVS**). It is these underlying host routing rules that physically capture incoming network traffic and blindly forward the packets straight to the actual, live Pod IPs.
- **Service Discovery (CoreDNS):** The cluster's built-in, centralized DNS server (CoreDNS) constantly monitors the Kubernetes API for the creation of new Services. The moment a Service is created, CoreDNS instantly registers a persistent, unique DNS record for it. Because of this, applications inside the cluster never have to know, cache, or poll for shifting IP addresses. Inter-pod communication becomes fully abstracted—microservices simply send requests to a stable, human-readable domain name formatted as: `service-name.namespace.svc.cluster.local`.

---

## Ingress nad Ingress Controller
- **The Layer 7 Router (Solving the L4 Problem):** While regular Services operate strictly at Layer 4 (routing packets blindly via TCP/UDP ports), Ingress operates at Layer 7. It understands HTTP/HTTPS headers, cookie data, hostnames, and specific URI paths. This solves the limitations of L4 Services, which cannot natively parse domains (`mywebsite.com`) or sub-paths (`/api/v1`).
- **The API Ingress Resource (The Manifest):** An Ingress manifest is a clean, static, and declarative YAML configuration file. It defines the mapping rules for incoming HTTP traffic, determining exactly how external requests should be routed to internal backend services (e.g., routing `/auth` requests to `auth-svc` and `/cart` to `cart-svc`).
- **The Controller Architecture (The Engine):** The Ingress manifest itself is just a static configuration file. To make it work, **Ingress Controller** must be deployed (e.g., NGINX, Traefik, HAProxy). The controller runs as a dedicated Pod acting as a reverse proxy on the edge of the cluster. It actively reads the Ingress rules and dynamically routes external requests directly to internal **ClusterIP** Services.
- **TLS Termination:** Managing SSL/TLS certificates directly at the Ingress Controller level is an industry **best practice**. The controller terminates and decrypts secure traffic at the cluster edge, forwarding lightweight, plain HTTP traffic to the internal Pods. This completely offloads the heavy cryptographic workload from your application containers.

---

## Example Manifests

### Internal Backend Service (`ClusterIP`)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: auth-svc
  namespace: default
spec:
  type: ClusterIP
  selector:
    app: auth-backend
  ports:
    - protocol: TCP
      port: 80         # The port exposed by the Service inside the cluster
      targetPort: 8080 # The actual container port the Pod is listening on
```
**Description:** A standard internal `Service` definition. It targets any Pods labeled with `app: auth-backend` and exposes them inside the cluster on port `80`.

### Ingress Resource (Layer 7 Routing with TLS)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
  namespace: default
  annotations:
    # Tells Kubernetes which Ingress Controller should process this manifest
    kubernetes.io/ingress.class: "nginx"
spec:
  tls:
    - hosts:
        - mywebsite.com
      secretName: mywebsite-tls-secret # Secret containing the SSL/TLS certificate
  rules:
    - host: mywebsite.com
      http:
        paths:
          - path: /auth
            pathType: Prefix
            backend:
              service:
                name: auth-svc # Routes to the ClusterIP service defined above
                port:
                  number: 80
          - path: /cart
            pathType: Prefix
            backend:
              service:
                name: cart-svc
                port:
                  number: 80
```
**Description:** The `Ingress` manifest which configures the **Ingress Controller** to route traffic based on hostnames and sub-paths, while also handling `TLS Termination` using a certificate stored in a Kubernetes `Secret`.