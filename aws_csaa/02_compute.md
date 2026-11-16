# Design Resilient Architectures


---

## EC2 Instances

### IP Addressing & Elastic IP

| Type | Behavior |
|---|---|
| **Private IPv4** | Always assigned (VPC-internal). Fixed for the instance's lifetime. Survives Stop/Start and Reboot. |
| **Public IPv4** | Optional (depends on subnet setting). **Changes on Stop/Start**. Survives **Reboot**. |
| **Elastic IP (EIP)** | Static public IPv4 owned by your account. Survives Stop/Start, remappable between instances. |

- **Default limit: 5 EIPs per Region** (soft limit, can be increased).
- Since Feb 2024 **all public IPv4 are charged** (~$0.005/h), including EIP in use. Unused or attached to a stopped instance also costs.
- Avoid EIPs in modern architecture (**Single Point of Failure**, poor design).
- Use instead:
  - **Route 53 (DNS name)**
  - **Load Balancer (ALB/ELB)** in front of instances in **private subnets**

### ENI (Elastic Network Interface)

- **Virtual network card** in a VPC (backed by AWS Nitro / SDN).
- Contains:
  - **Primary private IPv4** + one or more secondary private IPv4
  - One **Elastic IP** per private IPv4
  - One **public IPv4**
  - **IPv6** addresses
  - One or more **Security Groups**
  - **MAC address**
- Can be created **independently** and **moved between instances on the fly** → fast **failover**.
- **Bound to one AZ** (cannot move to another AZ).

### Instance Families

| Family | Examples | Optimized for | Use cases |
|---|---|---|---|
| **General Purpose** | T, M | Balanced CPU/RAM/network | Web servers, microservices, small DBs. **T = burstable** |
| **Compute Optimized** | C | High CPU | Gaming, media transcoding, batch, HPC, ML inference |
| **Memory Optimized** | R, X, z1d | High RAM | In-memory DBs (Redis, Memcached, SAP HANA), real-time analytics |
| **Storage Optimized** | I, D, H | High IOPS, low latency (local NVMe) | OLTP, data warehousing, distributed FS, NoSQL, OpenSearch |
| **Accelerated Computing** | P, G, Inf, Trn | GPU / Inferentia / Trainium | ML training/inference, 3D graphics, game streaming |

- **Instance Store** = ephemeral. Data lost on **Stop / Terminate** (survives Reboot).

### Security Groups (SG)

- Virtual firewall at **instance (ENI) level**, outside the OS.
- **Allow rules only** (no Deny).
- Inbound **blocked** by default, outbound **allowed** by default.
- **Stateful:** response traffic is automatically allowed.
- Scoped to **Region + VPC**. Many instances ↔ many SGs.
- Source can be **another SG** (instead of IPs).
- Best practice: separate SG for SSH/RDP.

**Troubleshooting**
- **Timeout** → firewall issue (SG, NACL, or route table).
- **Connection refused** → SG is fine, the **application/service** is the problem.

**Key ports**

| Port | Protocol |
|---|---|
| 21 | FTP |
| 22 | SSH / SFTP |
| 80 | HTTP |
| 443 | HTTPS |
| 3389 | RDP (Windows) |

### Remote Access & IAM

| Method | Needs |
|---|---|
| **SSH** | Key pair (`.pem`, `chmod 400`), port 22 open. PuTTY (`.ppk`) for Windows < 10 |
| **EC2 Instance Connect** | Browser-based, no `.pem` (temp key for 60 s), **port 22 open** |
| **Session Manager (SSM)** | **No port 22, no keys**. Needs SSM agent + IAM role. Most secure |

- **Never** store access keys on EC2 → attach an **IAM role (instance profile)**.
- Credentials come from **Instance Metadata Service**: `169.254.169.254`.

### Placement Groups

Control **physical placement** of instances on AWS hardware.

| Strategy | Layout | Pros | Cons | Use cases |
|---|---|---|---|---|
| **Cluster** | Close together, **single AZ**, same rack/hardware | Lowest latency, highest throughput (**10 Gbps per flow**) | One rack fails → **all instances fail** | **HPC, Big Data, ML**, low-latency apps |
| **Spread** | Each instance on **separate hardware** (rack, power, network) | Max failure isolation, can span **multiple AZs** | **Max 7 instances per AZ** per group | **Critical apps**, primary nodes, small HA setups |
| **Partition** | Instances split into **partitions** (separate racks), **up to 7 partitions per AZ**, can span multiple AZs | Scales to **hundreds of instances**, failure isolated per partition | Failure affects a whole partition | **Kafka, Cassandra, HDFS, HBase** |

- Partition: instances can see which partition they are in (metadata), useful for **topology-aware** apps.

### Instance Lifecycle

| Action | RAM | EBS | IPs |
|---|---|---|---|
| **Stop / Start** | **Cleared**, OS boots from scratch | Data kept | Private kept, **Public changes** |
| **Terminate** | Gone | **Root EBS deleted** by default (`DeleteOnTermination`), **additional EBS kept** by default | Gone |
| **Hibernate** | **Saved to root EBS**, restored on start | Data kept | Private kept, **Public changes** (unless EIP) |

**EC2 Hibernate**
- RAM state dumped to the **root EBS volume** → on start, **OS doesn't reboot**, apps resume instantly, processes stay alive.
- Use cases: **long-running processes**, **save RAM state**, **services that take long to initialize**.
- Requirements:
  - Max hibernation time: **60 days**
  - RAM: **< 150 GB**
  - Root volume must be **EBS**, **encrypted**, with enough free space for RAM dump
  - Must be **enabled at launch** (can't add later)
  - Supported: **On-Demand, Reserved, Spot**
  - **Not supported with Auto Scaling Groups**
- Billing while hibernated: **no EC2 charge**, but you pay for **EBS** and **Elastic IP** (if any).

### Purchase Options

| Option | Discount | Commitment | Key point |
|---|---|---|---|
| **On-Demand** | None | None | Per second/hour, default, most expensive |
| **Standard RI** | Up to 72% | 1 or 3 yrs | Can't change instance family, can sell on **RI Marketplace** |
| **Convertible RI** | Up to 66% | 1 or 3 yrs | Can change family, OS, tenancy |
| **EC2 Instance Savings Plan** | Up to 72% | $/hour, 1 or 3 yrs | Fixed family + region, flexible size/OS |
| **Compute Savings Plan** | Up to 66% | $/hour, 1 or 3 yrs | Flexible family, region, OS (also Fargate, Lambda) |
| **Spot** | Up to 90% | None | Can be reclaimed, **2-min warning** |
| **Dedicated Host** | Varies | On-Demand or reserved | Whole physical server, visible sockets/cores, **BYOL** |
| **Dedicated Instance** | Varies | None | Hardware dedicated to you, no host-level visibility |
| **Capacity Reservation** | None | None (any duration) | Guaranteed capacity in a **specific AZ**, combine with RI/SP for discount |

- RI and Savings Plans are **billing models**, not launch types.

**Spot details**
- Stopping a Spot instance:
  - **One-time** request → terminate the instance.
  - **Persistent** request → **cancel the request first**, then terminate the instance (otherwise it relaunches).
- **Spot Fleet** = Spot (+ optional On-Demand) pool to hit target capacity at lowest cost.
  - Strategies: `lowestPrice`, `diversified`, `capacityOptimized`, `priceCapacityOptimized` (recommended).
- Good for: batch jobs, CI/CD, big data, fault-tolerant workloads. **Not** for databases or critical jobs.

### Amazon Time Sync Service

- Free, microsecond-level accuracy (atomic clocks / GPS).
- Endpoint: `169.254.169.123`.
- Available on all EC2 instances, no setup needed. Low exam priority.

---

## Scalability & High Availability

### Scalability vs Elasticity

| Concept | Meaning | Key points |
|---|---|---|
| **Vertical** (Scale Up / Down) | Bigger single machine (more vCPU / RAM), e.g. t3.micro → m5.2xlarge | **Downtime** (restart), **hardware limit**. Typical for **RDS** and monoliths |
| **Horizontal** (Scale Out / In) | More independent instances in parallel | **Zero downtime**, almost unlimited. Requires **stateless** app |
| **Elasticity** | Automatically add resources at peak and remove them when traffic drops | **Cost optimization** |

### High Availability (HA)

- Survive hardware / data center failure by **eliminating SPOFs** (Single Point of Failure).
- **Multi-AZ** = resources in **at least 2 AZs** in the same Region.
- **Passive HA:** standby waits and takes over after failure (e.g. **RDS Multi-AZ**).
- **Active HA:** all instances in different AZs serve traffic at once (e.g. **EC2 fleet behind ELB**).

### Stateless Architecture

- Needed for horizontal scaling without losing user data.
- Move state out of EC2:
  - **Session state** → **ElastiCache (Redis)** or **DynamoDB**
  - **Files** → **S3** or **EFS**

---

## Elastic Load Balancing (ELB)

### Basics

- **Managed service**: distributes traffic across **Target Groups** in **multiple AZs**. AWS handles its scaling and availability.
- Why use it:
  - **Single, fixed DNS hostname** as entry point
  - **Health Checks** → cuts traffic from unhealthy targets
  - **SSL/TLS termination**
  - **Sticky Sessions**
  - Separates **public** (ELB in public subnet) from **private** (EC2 in private subnet) traffic
- Integrations: **EC2, ASG, ECS / EKS, Lambda, WAF, ACM, Route 53**.

**Health Checks**
- Configured at **Target Group** level (port + path, e.g. `/health`).
- **HTTP 200** = Healthy (ALB lets you change success codes). Other code or timeout = **Unhealthy** → no traffic.
- **ALB** supports **HTTP, HTTPS** (and **gRPC**) health checks.
- **NLB** supports **TCP, HTTP, and HTTPS** health checks (even though it routes traffic at L4).

**Security Group chaining (ALB)**

| SG | Inbound rule |
|---|---|
| **ALB-SG** | **0.0.0.0/0** on **80** (HTTP) and **443** (HTTPS) |
| **EC2-SG** | App port **only from ALB-SG** (blocks direct internet access, still lets ALB health checks through) |

### Load Balancer Types

| Type | OSI layer | Protocols | Key points |
|---|---|---|---|
| **ALB** (Application) | **L7** | HTTP/1.1, HTTP/2, WebSocket, gRPC | **Smart routing**: path (`/users`), host (`api.domain.com`), query string, headers. Redirects (HTTP→HTTPS), fixed responses, **dynamic port mapping (ECS)**. Client IP in **`X-Forwarded-For`**. **No static IP** (fixed DNS name only). Targets: **EC2, ECS, Lambda, private IPs** |
| **NLB** (Network) | **L4** | TCP, TLS, UDP | **Millions of req/s**, ultra-low latency. **1 static IP per AZ**, supports **Elastic IP**. **No WAF** support. Targets: **EC2, private IPs, ALB** |
| **GWLB** (Gateway) | **L3** | IP (**GENEVE**, UDP **6081**) | Inspect traffic with **3rd-party virtual appliances** (firewall, IDS/IPS, DPI). Transparent, via **GWLB Endpoint (GWLBe)**. Targets: **EC2, private IPs** |
| **CLB** (Classic) | L4 + L7 | HTTP, HTTPS, TCP, SSL | **Legacy**. No modern routing, **no SNI** (1 SSL cert only) |

- **NLB + ALB** pattern: static IP (NLB) + L7 routing and WAF (ALB).
- **NLB and Security Groups:** NLB can now have its own SG (optional). Without it, EC2-SG must allow the **VPC CIDR** so health checks pass.

### Sticky Sessions (Session Affinity)

- Same client always goes to the **same EC2 instance**. Configured at **Target Group** level, has an **expiration**.
- Supported: **CLB, ALB** (HTTP cookies), **NLB** (by source IP).
- Downside: **uneven load** (imbalance).

| Cookie type | Details |
|---|---|
| **Custom cookie** (application-based) | Generated by the app on EC2, name set in the Target Group. Can't be named `AWSALB`, `AWSALBAPP`, `AWSALBTG` |
| **Application cookie** (application-based) | Generated by the LB, name **`AWSALBAPP`** |
| **Duration-based** | Generated by the LB: **`AWSALB`** (ALB), **`AWSELB`** (CLB). Lifetime **1 s – 7 days** |

### Cross-Zone Load Balancing

- **Enabled** → traffic split evenly across **all instances in all AZs**.
- **Disabled** → traffic split evenly **per AZ first**, then across instances in that AZ.

| LB | Default | Inter-AZ data cost |
|---|---|---|
| **ALB** | **Enabled** (always on at LB level, can be turned off per Target Group) | **Free** |
| **NLB** | **Disabled** | **Charged** when enabled |
| **GWLB** | **Disabled** | **Charged** when enabled |
| **CLB** | **Disabled** via API/CLI (enabled by default in console) | **Free** |

### SSL/TLS & SNI

- **X.509 certificate** (managed in **ACM** or uploaded) encrypts traffic **client ↔ ELB** (in-flight).
- ELB → EC2 inside the VPC is **not encrypted by default**.
- **Security Policies:** enforce SSL/TLS versions (e.g. support for legacy clients).
- **SNI (Server Name Indication):** client sends the domain name at the start of the TLS handshake → **one LB serves multiple certificates** (1 default + list of additional).
  - **ALB, NLB** → support SNI (multiple certs)
  - **CLB** → only **1 cert**

### Connection Draining / Deregistration Delay

- Gives an instance time to **finish in-flight requests** before it's removed (Scale In, failure). No new requests are sent to it meanwhile.
- Names: **Connection Draining** (CLB), **Deregistration Delay** (ALB, NLB).
- Range **1 – 3600 s**, default **300 s**. **0** = disabled (connections cut immediately).
- Short API requests → set low (**10 – 30 s**).

---

## Auto Scaling Groups (ASG)

### Basics

- **Free** (you pay only for EC2 / EBS).
- Scale **Out / In**, **auto-registers** instances in ELB, **self-healing** (replaces unhealthy instances).
- Capacity: **Minimum**, **Desired**, **Maximum**.
- **ELB Health Checks in ASG:**
  - Default: ASG checks only **EC2 status**.
  - With ELB health checks enabled: app Unhealthy in ELB → ASG **terminates and replaces** the instance.

### Launch Template (required)

- Defines a **single instance**: **AMI, instance type, User Data, EBS volumes, SGs, SSH key pair, IAM role, network**.
- Set directly on the **ASG** (not in the template): **VPC / subnets, ELB / Target Group, Min / Desired / Max, scaling policies**.

### Scaling Policies

| Policy | How it works | Example |
|---|---|---|
| **Target Tracking** | Keeps a metric at a target value, like a thermostat. **Simplest, most recommended** | Avg CPU = 40% |
| **Simple / Step** | Reacts to **CloudWatch alarms**, adds / removes a set number of instances | CPU > 70% → add 2 |
| **Scheduled** | Scales at a **set time** based on known patterns | Friday evening peak |
| **Predictive** | **ML** forecast from history, launches instances **in advance** | Recurring daily / weekly patterns |

- Common metrics: **CPUUtilization**, **RequestCountPerTarget** (ALB), **Average Network In/Out**.
- **Custom metrics** in CloudWatch (RAM usage, **SQS backlog per instance**). RAM is not available by default.

### Cooldown, Golden AMI & Termination

- **Scaling Cooldown:** after a scaling action ASG waits (default **300 s**) so metrics can stabilize.
- **Golden AMI:** app preinstalled in the AMI (instead of a long User Data script) → **faster start**, allows **shorter cooldown**.
- **Default Termination Policy (Scale In):**
  1. Pick the **AZ with the most instances** (keeps Multi-AZ balance)
  2. In it, terminate the instance with the **oldest Launch Template**
- **Troubleshooting:** instances keep launching and terminating (never Healthy) → check **Activity History**. Most common causes:
  - Bug in **User Data** script
  - **Security Group** on EC2 blocking ELB health checks

---