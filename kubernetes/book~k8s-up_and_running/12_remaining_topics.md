Without Istio - Classical Ingress: `AWS:ELB ---> [ Service:LoadBalancer ---> Nginx-Pod (Engine) --(reads Ingress rules)--> Service:ClusterIP ---> SomePod ]`

With Istio: `AWS:ELB ---> [ Service:LoadBalancer ---> istio-ingressgateway-Pod (Engine) --(configured by Gateway & VirtualService)--> SomePod ]`


CNI (K8S docs: Topics > Extensions)

```mermaid
graph TD
    %% Definicja Stylów / Kolorów
    classDef aws color:#fff,fill:#FF9900,stroke:#333,stroke-width:1px;
    classDef k8s color:#fff,fill:#326CE5,stroke:#333,stroke-width:1px;
    classDef net color:#222,fill:#E6F2F7,stroke:#0073BB,stroke-width:2px;

    User([👤 Klient / Internet]) --> ALB["CloudFront / AWS ALB"]:::aws

    subgraph AWS_VPC ["Chmura AWS (VPC)"]
        ALB --> EKS_Cluster
        
        subgraph EKS_Cluster ["Klaster Amazon EKS"]
            direction LR
            
            subgraph K8s_Ingress ["Namespace: Production"]
                Ingress["K8s Ingress Controller"]:::k8s
                Service["K8s Service (ClusterIP)"]:::k8s
                Pod1["Pod: App Instance 1"]:::k8s
                Pod2["Pod: App Instance 2"]:::k8s
                
                Ingress --> Service
                Service --> Pod1
                Service --> Pod2
            end
        end
        
        %% Powiązanie komponentów z bazą poza klastrem
        Pod1 --> RDS["Amazon RDS (PostgreSQL)"]:::aws
        Pod2 --> RDS
    end

    %% Przypisanie klas stylów do kontenerów zewnętrznych
    style AWS_VPC fill:#f9f9f9,stroke:#FF9900,stroke-width:2px,stroke-dash
```