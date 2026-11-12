# Design High-Performing Architectures

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

### Exam Tips

**Networking & access**
- Need fixed public endpoint → **ALB + Route 53**, not EIP.
- Fast failover with same private IP / MAC → **move the ENI** (same AZ only).
- Connection timeout → **Security Group**. Connection refused → **application**.
- Shell access without opening ports → **Session Manager**.
- EC2 needs AWS access → **IAM role**, never access keys on the instance.

**Placement**
- Lowest latency / HPC / big data → **Cluster PG**.
- Max HA, few critical instances → **Spread PG** (**7 per AZ** limit).
- Big distributed systems (Kafka, Cassandra, HDFS) → **Partition PG**.

**Lifecycle**
- Fast app startup / keep RAM state → **Hibernate** (encrypted root EBS, enabled at launch).
- Terminate: **root EBS deleted**, **extra EBS kept** by default.

**Pricing**
- Steady, predictable workload for 1 to 3 yrs → **Reserved / Savings Plan**.
- Short, uninterruptible workload → **On-Demand**.
- Fault-tolerant, cost-sensitive → **Spot**.
- Per-core/socket licensing (BYOL) → **Dedicated Host**.
- Guaranteed capacity in one AZ → **Capacity Reservation**.

--- 

## EC2 Instance Storage: EBS 

