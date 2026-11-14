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

## EC2 Instance Storage: EBS, EFS, AMIs

### EBS (Elastic Block Store)

#### Basics

- **Network block storage**, persistent: data survives Stop / Terminate of the instance (if volume is kept).
- Attached to **1 instance at a time** (exception: Multi-Attach), but 1 instance can have **many volumes**.
- Can be detached and attached to another instance **in the same AZ**.
- **Bound to one AZ.** To move to another AZ / Region → **Snapshot → restore** in target location.
- Billing: provisioned **GB + IOPS**. **Unattached volumes are still fully charged.**
- **Delete on Termination:**
  - **Root volume** → enabled by default (deleted with EC2)
  - **Additional volumes** → disabled by default (kept)

#### Volume Types

| Type | Category | Size | Max IOPS / Throughput | Key points |
|---|---|---|---|---|
| **gp3** | General SSD | 1 GiB – 64 TiB | 80k IOPS / 2000 MiB/s* | Baseline **3000 IOPS + 125 MiB/s**. IOPS and throughput scale **independently of size** |
| **gp2** | General SSD | 1 GiB – 16 TiB | 16k IOPS / 250 MiB/s | Size and IOPS **linked (3 IOPS/GB)**. Max 16k IOPS only at ~5334 GiB |
| **io1** | Provisioned IOPS SSD | 4 GiB – 16 TiB | 64k IOPS / 1000 MiB/s | Critical DBs. Independent PIOPS. Max ratio **50:1** IOPS:GiB |
| **io2 Block Express** | Provisioned IOPS SSD | 4 GiB – 64 TiB | 256k IOPS / 4000 MiB/s | DBs **> 64k IOPS**, sub-ms latency, ratio **1000:1**, supports **Multi-Attach** |
| **st1** | HDD | 125 GiB – 16 TiB | 500 IOPS / 500 MiB/s | **Not bootable**. Cheap, frequent access: big data, data warehouse, logs, Kafka |
| **sc1** | HDD | 125 GiB – 16 TiB | 250 IOPS / 250 MiB/s | **Not bootable**. Cheapest EBS, rarely accessed data (archives) |

*Older exam material often lists gp3 as 16 TiB / 16k IOPS / 1000 MiB/s.

- **Boot volumes:** only **SSD** (gp2, gp3, io1, io2). **HDD (st1, sc1) can never be boot.**
- **> 32,000 IOPS** on io1/io2 requires **Nitro** instances.

#### Multi-Attach

- Only **io1 / io2**.
- 1 volume attached (read + write) to **up to 16 instances**, **same AZ**.
- Requires a **cluster-aware file system** (regular XFS / EXT4 will corrupt data).
- Use case: clustered apps (e.g. Teradata), higher availability.

#### Encryption

- Uses **KMS (AES-256)**, minimal latency impact.
- Encrypts: **data at rest**, **data in transit** between EC2 and EBS, **snapshots**, and **volumes created from them**.
- **Encrypting an unencrypted volume:**
  1. Create **Snapshot**
  2. **Copy** snapshot with **Encrypt** (KMS) enabled
  3. Create new **volume** from the encrypted snapshot
  4. **Attach** it to EC2

#### Snapshots & Lifecycle

- **Incremental** backup stored in **S3** (managed by AWS).
- Can be taken while attached, but detaching is recommended for consistency.
- Snapshot uses I/O → **avoid peak hours**.

| Feature | What it does |
|---|---|
| **Snapshot Archive** | Up to **75% cheaper** tier, but restore takes **24–72 h** |
| **Fast Snapshot Restore (FSR)** | Blocks fully initialized immediately (full performance from second 1), **very expensive** |
| **Recycle Bin** | Protects snapshots and AMIs from accidental deletion, retention **1 day – 1 year** |
| **Data Lifecycle Manager (DLM)** | **Automates** creation, retention and deletion of snapshots and AMIs on a schedule |

### AMI (Amazon Machine Image)

- Prebuilt image of **OS + apps + config** → **faster boot time**.
- **Region-specific**, but can be **copied across Regions**.
- Types: **Public** (AWS / community), **Own**, **Marketplace** (commercial).
- Build process:
  1. Launch EC2 and configure it
  2. **Stop** the instance (data integrity)
  3. Build **AMI** (creates EBS snapshots)
  4. Launch new instances from it in **any AZ** in the Region

### EC2 Instance Store

- **Physical disk** attached directly to the host server → **no network overhead**.
- Exam keyword: **"high performance hardware disk"** / maximum I/O.
- **Ephemeral:** data lost on **Stop**, **Terminate**, or hardware failure (survives **Reboot**).
- Use only for **temporary data**: cache, buffers, scratch files.

### EFS (Elastic File System)

- **Managed, shared network file system** (**NFS / POSIX**), **Linux only** (e.g. WordPress files).
- Mounted by **hundreds / thousands of instances** across **multiple AZs**.
- **Auto-scales**, pay per use (**~3x more expensive than gp2**).
- Access controlled by **Security Groups**.

| Setting | Options |
|---|---|
| **Performance mode** | **General Purpose** (low latency, default) / **Max I/O** (high parallelism: big data, media processing) |
| **Throughput mode** | **Bursting** (depends on data size) / **Provisioned** (fixed, independent of size) / **Elastic** (auto scales up and down) |
| **Storage classes** (Lifecycle Management after N days) | **Standard** → **EFS-IA** (Infrequent Access) → **EFS Archive** |
| **Availability** | **Standard (Regional)**: Multi-AZ, production / **One Zone**: 1 AZ, cheaper, dev/test |

---

### EBS vs EFS vs Instance Store

| Criteria | EBS | EFS | Instance Store |
|---|---|---|---|
| **Instances** | 1 (or up to 16 in 1 AZ via Multi-Attach io1/io2) | Hundreds / thousands at once | 1 (physically tied to host) |
| **AZ scope** | **1 AZ** (migrate via snapshot) | **Multi-AZ** (whole Region) | 1 physical server in 1 AZ |
| **OS** | Linux + Windows | **Linux only** (POSIX) | Linux + Windows |
| **Durability** | Persistent | Persistent | **Ephemeral** (lost on Stop/Terminate) |
| **Why choose** | Boot disks, databases, cost optimization (gp3, st1, sc1) | **Shared** file system for many Linux servers in different AZs | **Extreme I/O**, low latency for temp data |

### Exam Tips

**EBS**
- Cheap general-purpose volume with independent IOPS → **gp3**.
- DB needing high, consistent IOPS → **io1 / io2**. Sub-ms latency or > 64k IOPS → **io2 Block Express**.
- Cheap throughput for big data / logs → **st1**. Cheapest archive-like → **sc1**. Neither can be boot.
- Same volume on multiple instances → **Multi-Attach** (io1/io2, same AZ, cluster-aware FS).
- Move EBS to another AZ / Region → **Snapshot** → restore there.
- Encrypt an existing volume → **Snapshot → encrypted copy → new volume**.
- Cut snapshot costs for rarely used backups → **Snapshot Archive** (24–72 h restore).
- Need instant full performance after restore → **FSR**.
- Protect from accidental snapshot deletion → **Recycle Bin**. Automate backups → **DLM**.

**AMI / Instance Store / EFS**
- Faster instance boot / consistent config → **custom AMI**. Use in another Region → **copy AMI**.
- Highest I/O, temporary data → **Instance Store** (never for critical data).
- Shared storage across AZs for Linux → **EFS**. Windows shared storage → **FSx for Windows**.
- Dev/test shared storage on a budget → **EFS One Zone**. Cold files in EFS → **EFS-IA** via Lifecycle Management.
- Big data / parallel workloads on EFS → **Max I/O** performance mode.

---