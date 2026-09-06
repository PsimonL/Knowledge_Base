# 📚 "Kubernetes: Up & Running — Study Guide" (Based on Polish Edition)

This directory serves as my personal compendium, structured notes, and hands-on lab configurations based on the Polish edition of the book *Kubernetes: Up & Running* (*Kubernetes. Przewodnik*).

> 💡 **Study Strategy:** The book's content has been reorganized and consolidated into **10 core topic files** arranged in a natural, engineering-focused lifecycle order. Each file builds upon the knowledge of the previous one, mapping perfectly to both real-world deployment workflows and CKA/CKAD exam domains.

---

## 🗺️ Reorganized Table of Contents

### 1. ⚙️ [Fundamentals](01_fundamentals.md)
* **C01** -> Introduction -> Core concepts of containerization and the evolution of the cloud-native ecosystem.
* **C02** -> Creating and Running Containers -> Building, optimizing, and basic execution of container images.
* **C03** -> Deploying a Kubernetes Cluster -> Overview of Control Plane components and Worker Node architecture.
* **C04** -> Common kubectl Commands -> Essential CLI tool usage, basic commands, and imperative operations.

### 2. 🧩 [Workloads Core](02a_workloads_core.md) and [Workloads Controllers](02b_workloads_controllers.md)
* **C05** -> Pods -> Deep dive into Pod anatomy, lifecycle, and configuring liveness/readiness probes.
* **C06** -> Labels and Annotations -> Utilizing metadata for resource selection, filtering, and organizing workloads.
* **C09** -> ReplicaSet -> Low-level replication mechanism running beneath Deployments to ensure pod count.
* **C10** -> Deployment -> Declarative orchestration for rolling updates, rollbacks, and application scaling.
* **C11** -> DaemonSet -> Deploying background system pods (logging, monitoring) on every single cluster node.
* **C12** -> Job -> Executing short-lived batch tasks and scheduling periodic automated tasks (CronJobs).
* **C16** -> Integrating Storage Solutions -> Deploying stateful workloads via StatefulSets and Singleton architectures.

### 🗄️ 3. [Config Maps and Secrets](03_configmaps_and_secrets.md)
* **C13** -> ConfigMaps and Secrets -> Decoupling non-sensitive configuration parameters and sensitive credentials from application code.

### 🚦 4. [Services and Ingress](04_services_and_ingress.md)
* **C07** -> Services -> Internal and external communication blueprints via ClusterIP, NodePort, and LoadBalancer.
* **C08** -> Ingress Load Balancing -> HTTP/HTTPS reverse proxy routing rules and managing external traffic ingress controllers.

### 🌐 5. [Service Mesh](05_service_mesh.md)
* **C15** -> Service Mesh -> Advanced traffic management, service-to-service security, mutual TLS, and observability.

### 🛡️ 6. [Policies](06_policies.md)
* **C20** -> Policy and Governance -> Network isolation using NetworkPolicies and managing cluster ResourceQuotas.

### 🔑 7. [RBAC](07_rbac.md)
* **C14** -> RBAC -> Cluster authorization framework using Role-Based Access Control (Roles, ClusterRoles, and Bindings).

### 🔒 8. [Security](08_security.md)
* **C19** -> Application Security in Kubernetes -> Linux host security isolation using Pod SecurityContext and capability restrictions.

### 🔌 9. [Kubernetes Extensions](09_extensions.md)
* **C17** -> Extending Kubernetes -> Introduction to Custom Resource Definitions (CRDs) and the automated Operator pattern.

### 10. 🗺️ [Multi-Cluster Deployments](10_multi_cluster_deploy.md)
* **C21** -> Deploying Applications in Multiple Clusters -> Theoretical architectures and policies for deploying services across multiple distinct clusters.

### 11. 📦 [Remaining Topics](11_remaining_topics.md)
* **C18** -> Accessing Kubernetes from Popular Programming Languages -> Interacting with the K8s API using official client libraries (Python, Go, etc.).
* **C22** -> Organizing Your A

---

## 🧪 Hands-On Labs (YAML Manifests)
All production-ready YAML manifests written and tested while studying these categories are located in the [`/manifests`](./manifests/) directory. Each file features proper resource limits and security hardening.
