# Design High-Performing Architectures

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

---