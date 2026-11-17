# Databases

## RDS, Aurora & ElastiCache

### Amazon Aurora

#### Architecture

- **Storage:** **6 copies across 3 AZs**. Write needs **4/6**, read needs **3/6** → survives a whole AZ failure with no downtime.
- **Self-healing** storage, **auto-expands** from **10 GB up to 128 TiB** (256 TiB on newer versions).
- **Compute:** only **1 Master** takes writes. Reads: Master + up to **15 Read Replicas**. Automatic **failover < 30 s**.

| Endpoint | Behavior |
|---|---|
| **Writer** | Always points to the current **Master** |
| **Reader** | Load-balances across **all replicas**, follows Auto Scaling |
| **Custom** | Group of chosen replicas, e.g. **bigger replicas for heavy analytics queries** |

- In plain RDS every replica has its **own endpoint** (exception: **RDS Multi-AZ DB Cluster**).

#### Variants & Features

| Feature | Key points |
|---|---|
| **Aurora Serverless** (v2) | No server / capacity planning, scales in fractions of a second, **per-second billing**. For **intermittent / unpredictable** traffic |
| **Global Database** | **1 primary Region** (read/write) + up to **10 secondary Regions*** (read-only, up to **16 replicas** each). Replication **< 1 s**, Region failover **RTO < 1 min** |
| **Backtrack** | Rewinds the DB **in place**, **no backup, no new instance** (**Aurora MySQL** only) |
| **Database Cloning** | Fast test copy of prod, **Copy-on-Write**, no load on production, minimal extra storage |
| **Aurora ML** | Call **SageMaker** and **Comprehend** models via **SQL** |
| **Babelfish** | Run **T-SQL (MS SQL Server)** queries on **Aurora PostgreSQL** without rewriting code |

*Older exam material often says 5 secondary Regions.
- **Global Database, instance count:**
  - **Primary Region:** 1 Master (writer) + up to **15 Read Replicas**
  - **Each secondary Region:** up to **16 read-only instances** (all of them readers)

### Backups, Restore & Migration (RDS vs Aurora)

| Feature | RDS | Aurora |
|---|---|---|
| **Automated Backups** | **1–35 days** (**0 disables**). Daily snapshot + transaction logs every **5 min** | **1–35 days**, **cannot be disabled**. Continuous backup to S3 |
| **Point-in-Time Recovery** | Yes (up to ~5 min ago). Creates a **new DB** | Yes (any second in the window). Creates a **new cluster** |
| **Manual Snapshots** | Kept **after DB deletion** | Kept **after cluster deletion** |

- **Golden rule:** restoring from a backup or snapshot **always creates a new DB**.
- **Cost saving:** a **Stopped** RDS instance **still pays for storage** (and AWS restarts it after 7 days). For long shutdowns → **Manual Snapshot + delete DB**.
- **On-prem migration via S3:**
  - **RDS MySQL** → standard backup file in S3
  - **Aurora MySQL** → **Percona XtraBackup**

### Security (RDS & Aurora)

- **Encryption at rest (KMS):** enabled **only at creation**. An unencrypted master **cannot have an encrypted replica**.
  - Encrypt an existing DB → **Snapshot → restore as encrypted** (or enable encryption when **copying the snapshot** across Regions).
- **Encryption in flight (SSL/TLS):** install **AWS root certificates** in the app and enforce in the **DB Parameter Group**:
  - PostgreSQL: `rds.force_ssl=1`
  - MySQL: `require_secure_transport=ON`
- **IAM Database Authentication:** token instead of password (**MySQL, PostgreSQL, MariaDB**).
- **Network:** **Security Groups**, allow traffic **from the app's SG**, not from IPs.
- **No SSH / OS access** on managed services. Exception: **RDS Custom** (full OS access, for legacy apps).
- **Audit logs** → export to **CloudWatch Logs**.

### RDS Proxy

- **Serverless** connection pooler: merges thousands of sessions into a small pool → protects DB **CPU / RAM** during spikes (typical with **Lambda**).
- Cuts **failover time by up to 66%**. Deployment = just **change the endpoint** in the app.
- Supports **MySQL, PostgreSQL, MariaDB** (and Aurora variants).
- **Authentication (two separate hops):**
  - **Client → Proxy:** **IAM Authentication** (can be **enforced as the only method**) or classic **password**
  - **Proxy → DB:** credentials from **Secrets Manager** (works in the background)
  - Exam favorite: **enforce IAM Auth** on the Proxy, with **Secrets Manager** behind it
- **Never public**, only inside the VPC → **Lambda must be in the same VPC**.

### ElastiCache (Redis vs Memcached)

- **Managed in-memory cache**, **microsecond latency**. Used as **DB cache** or **user session store** (makes the app **stateless**).
- Requires **significant app code changes**.

| Feature | Redis | Memcached |
|---|---|---|
| **Multi-AZ + failover** | Yes | No |
| **Persistence & backups** | Yes (AOF + backup/restore) | No (backup only in Serverless) |
| **Architecture** | Mostly single-threaded (**Read Replicas + sharding**) | **Multi-threaded** (sharding only) |
| **Security** | IAM Auth, Redis AUTH, SSL/TLS, KMS | **SASL** auth |
| **Special features** | **Sorted Sets** (real-time leaderboards) | Simple key-value only |

**Caching patterns**
- **Lazy Loading:** load data on first read (**cache miss**). Data can become **stale**.
- **Write Through:** update cache on every DB write → **no stale data**, but **slower writes**.
- **Session Store:** use **TTL** to auto-expire sessions.

### Database Ports

| Port | Service |
|---|---|
| 1433 | MS SQL Server |
| 1521 | Oracle |
| 3306 | MySQL / MariaDB / Aurora MySQL |
| 5432 | PostgreSQL / Aurora PostgreSQL |
| 6379 | Redis |
| 11211 | Memcached |

---
