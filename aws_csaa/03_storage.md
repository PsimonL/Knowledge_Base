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

### EBS vs EFS vs Instance Store

| Criteria | EBS | EFS | Instance Store |
|---|---|---|---|
| **Instances** | 1 (or up to 16 in 1 AZ via Multi-Attach io1/io2) | Hundreds / thousands at once | 1 (physically tied to host) |
| **AZ scope** | **1 AZ** (migrate via snapshot) | **Multi-AZ** (whole Region) | 1 physical server in 1 AZ |
| **OS** | Linux + Windows | **Linux only** (POSIX) | Linux + Windows |
| **Durability** | Persistent | Persistent | **Ephemeral** (lost on Stop/Terminate) |
| **Why choose** | Boot disks, databases, cost optimization (gp3, st1, sc1) | **Shared** file system for many Linux servers in different AZs | **Extreme I/O**, low latency for temp data |

---

## Amazon S3

### Basics & Use Cases

- **Infinitely scalable object storage**, integration point for many AWS services.
- Use cases: **backup / DR**, **long-term archive**, **hybrid cloud storage**, media / software distribution, **data lakes / big data**, **static website hosting**.

### Buckets & Naming

- Buckets are **regional**: data stays in the Region where the bucket was created (unless replication is set up).
- Console shows buckets from **all Regions** in one list (current account only).
- Other accounts' buckets: not in the list, but reachable via direct URL / CLI / SDK (if the Bucket Policy allows). Multi-account view → **S3 Storage Lens** or **AWS Resource Explorer**.
- **Name must be globally unique** (all accounts, all Regions), because buckets get public DNS names.
- Account Regional Namespace (newer): simple names unique only per account + Region (AWS appends `-{account-id}-{region}-an`). Low exam priority.
- **Naming rules:**
  - **3-63 characters**, lowercase letters, digits, **hyphens**, dots (**no uppercase, no `_`**)
  - Starts with a lowercase letter or digit
  - Not an IP address, no `xn--` prefix, no `-s3alias` suffix

### Objects

- **Key** = full path, e.g. `s3://my-bucket/my_folder1/another_folder/my_file.txt`.
- **No real folders**: key = **prefix** (`my_folder1/another_folder/`) + **object name**.
- **Max object size: 5 TB.**
- **Upload > 5 GB** → **Multi-part upload required** (recommended from ~100 MB).
- **Metadata:** key-value text pairs (system or user).
- **Tags:** up to **10** key-value pairs per object (used in permissions and Lifecycle rules).
- **Version ID** (if versioning is on).

### Security & Static Website

| Mechanism | Type | Use |
|---|---|---|
| **IAM Policy** | User-based | What API actions a user / role can do |
| **Bucket Policy** | Resource-based (JSON) | **Public access**, **force encryption**, **cross-account** access |
| **ACL** | Legacy | **Disabled by default** on new buckets, avoid |

- **Same account:** access granted if **IAM ALLOW *or* Bucket Policy ALLOW**, and **no explicit DENY**.
- **Cross-account:** **both** sides must allow (IAM in the caller's account + Bucket Policy).
- **Block Public Access:** protects against accidental leaks, **on by default**, can be enforced **account-wide**.
- **Static website hosting:**
  - URL: `http://<bucket>.s3-website-<region>.amazonaws.com` (or `s3-website.<region>` with a dot)
  - **403 Forbidden** → no public `s3:GetObject` in Bucket Policy, or **Block Public Access** is on

### Versioning

- Enabled **per bucket**. Protects against accidental deletion, easy rollback.
- Overwrite → **new version** (1, 2, 3...), previous = **noncurrent version**.
- Objects uploaded **before** enabling have `VersionId = null`.
- **Cannot be disabled, only Suspended** (existing versions stay, new objects get `null`).
- **You pay for all versions** (also noncurrent) → clean up with **Lifecycle rules**.

| Action (versioning on) | Result |
|---|---|
| **Delete without VersionId** | Adds a **Delete Marker** (object hidden, **not removed**). Remove the marker → object restored |
| **Delete with VersionId** | **Permanent delete**, data gone, stops billing |

- Permanent delete: console **Show versions**, `aws s3api delete-object --version-id ...`, or Lifecycle rule **"Permanently delete noncurrent versions"**.

### Replication (CRR & SRR)

- **Requirements:** **Versioning enabled on source and destination**, S3 needs an **IAM role**.
- **Asynchronous**, works **across accounts**.

| Type | Scope | Use cases |
|---|---|---|
| **CRR** | Cross-Region | **Compliance**, lower latency for users in another Region, cross-account copy |
| **SRR** | Same Region | **Log aggregation**, live sync prod ↔ test |

- Only **new objects** (after enabling the rule) are replicated. Existing / failed objects → **S3 Batch Replication**.
- **No chaining:** Bucket 1 → 2 → 3 does **not** copy from 1 to 3.
- **Deletes:**
  - **Delete Markers** → can be replicated (optional setting)
  - **Permanent deletes (with VersionId)** → **never replicated** (protects backup from ransomware / admin error)
  - To clean old versions in the destination → separate **Lifecycle rule** there

### Storage Classes

- **Durability: 99.999999999% (11 nines) in ALL classes.**
- **Availability** depends on the class.

| Class | Use case | Availability | AZs | Min duration | Min size | Retrieval |
|---|---|---|---|---|---|---|
| **Standard** | Frequent access, websites, big data | 99.99% | ≥ 3 | None | None | ms, no fee |
| **Intelligent-Tiering** | **Unknown / changing** access patterns | 99.9% | ≥ 3 | None | 128 KB (for tiering) | ms, no retrieval fee (small monitoring fee) |
| **Express One Zone** | **Extreme performance**, AI/ML, HPC | 99.95% | **1** (Directory Bucket) | 1 h | None | **single-digit ms** (10x faster), per-GB fee |
| **Standard-IA** | Infrequent access, DR, backups | 99.9% | ≥ 3 | 30 days | 128 KB | ms, per-GB fee |
| **One Zone-IA** | Secondary backups, **re-creatable** data | 99.5% | **1** (data lost if AZ is destroyed) | 30 days | 128 KB | ms, per-GB fee (20% cheaper than Std-IA) |
| **Glacier Instant Retrieval** | Archive accessed ~**once a quarter** | 99.9% | ≥ 3 | 90 days | 128 KB | ms, per-GB fee |
| **Glacier Flexible Retrieval** | Archive / backup, minutes to hours | 99.99% | ≥ 3 | 90 days | 40 KB overhead | **Expedited 1-5 min**, **Standard 3-5 h**, **Bulk 5-12 h (free)** |
| **Glacier Deep Archive** | **Cheapest**, 7-10 yr archive | 99.99% | ≥ 3 | 180 days | 40 KB overhead | **Standard 12 h**, **Bulk 48 h** |

**Intelligent-Tiering tiers (automatic)**
- **Frequent Access** (default) → **30 days** no access → **Infrequent Access** → **90 days** → **Archive Instant Access**
- Optional: **Archive Access** (90-700+ days), **Deep Archive Access** (180-700+ days)

---