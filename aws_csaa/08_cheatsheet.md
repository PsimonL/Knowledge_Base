# Exam Cheatsheet

## 01. Security

### IAM
- Need temporary credentials → **STS / roles**, not IAM users.
- EC2 needs AWS access → **instance role**, never access keys on the instance.
- Third-party access to your account → **cross-account role + External ID**.
- Find unused permissions → **Access Advisor**. Audit credentials → **Credentials Report**.
- Restrict even root in member accounts → **SCP**.

---

## 02. Compute 

### EC2: Networking & Access
- Need fixed public endpoint → **ALB + Route 53**, not EIP.
- Fast failover with same private IP / MAC → **move the ENI** (same AZ only).
- Connection timeout → **Security Group**. Connection refused → **application**.
- Shell access without opening ports → **Session Manager**.

### EC2: Placement
- Lowest latency / HPC / big data → **Cluster PG**.
- Max HA, few critical instances → **Spread PG** (**7 per AZ** limit).
- Big distributed systems (Kafka, Cassandra, HDFS) → **Partition PG**.

### EC2: Lifecycle
- Fast app startup / keep RAM state → **Hibernate** (encrypted root EBS, enabled at launch).
- Terminate: **root EBS deleted**, **extra EBS kept** by default.

### EC2: Pricing
- Steady, predictable workload for 1 to 3 yrs → **Reserved / Savings Plan**.
- Short, uninterruptible workload → **On-Demand**.
- Fault-tolerant, cost-sensitive → **Spot**.
- Per-core/socket licensing (BYOL) → **Dedicated Host**.
- Guaranteed capacity in one AZ → **Capacity Reservation**.

### Load Balancers
- **GENEVE, port 6081, 3rd-party firewall / IDS / IPS / DPI** → **GWLB**.
- **Millions of req/s, ultra-low latency, UDP** → **NLB**.
- **Static IP / Elastic IP + WAF / path-based routing** → **NLB in front of ALB** (or **Global Accelerator + ALB**).
- **Path / host / header routing, Lambda targets, ECS dynamic ports** → **ALB**.
- **Multiple SSL certificates on one LB** → **ALB or NLB with SNI** (not CLB).
- **Client IP behind ALB** → **`X-Forwarded-For`** header.
- **Users logged out during scaling** (no code change) → **Sticky Sessions** on the Target Group.
- **Uneven traffic between AZs** → **Cross-Zone Load Balancing** (on by default only for ALB).
- **In-flight requests cut during Scale In** → **Deregistration Delay**.
- **EC2 reachable only via ALB** → EC2-SG allows **only ALB-SG** as source.

### ASG & HA
- **Replace instances when the app (not just EC2) fails** → enable **ELB Health Checks** in ASG.
- **Instances terminate immediately after launch** → bad **User Data** or **SG** blocking health checks (check **Activity History**).
- **Keep avg CPU at X%** → **Target Tracking**. **Known peak time** → **Scheduled**. **Recurring patterns, pre-scaling** → **Predictive**.
- **Scale on RAM / queue length** → **Custom CloudWatch metric** (e.g. SQS backlog per instance).
- **Faster instance start** → **Golden AMI**.
- **Scale web tier horizontally** → keep app **stateless** (sessions in **ElastiCache / DynamoDB**, files in **S3 / EFS**).
- **Database (RDS) can't scale horizontally for writes** → **scale vertically**, HA via **Multi-AZ**.

---

## 03. Storage

### EBS
- Cheap general-purpose volume with independent IOPS → **gp3**.
- DB needing high, consistent IOPS → **io1 / io2**. Sub-ms latency or > 64k IOPS → **io2 Block Express**.
- Cheap throughput for big data / logs → **st1**. Cheapest archive-like → **sc1**. Neither can be boot.
- Same volume on multiple instances → **Multi-Attach** (io1/io2, same AZ, cluster-aware FS).
- Move EBS to another AZ / Region → **Snapshot** → restore there.
- Encrypt an existing volume → **Snapshot → encrypted copy → new volume**.
- Cut snapshot costs for rarely used backups → **Snapshot Archive** (24–72 h restore).
- Need instant full performance after restore → **FSR**.
- Protect from accidental snapshot deletion → **Recycle Bin**. Automate backups → **DLM**.

### AMI / Instance Store / EFS
- Faster instance boot / consistent config → **custom AMI**. Use in another Region → **copy AMI**.
- Highest I/O, temporary data → **Instance Store** (never for critical data).
- Shared storage across AZs for Linux → **EFS**. Windows shared storage → **FSx for Windows**.
- Dev/test shared storage on a budget → **EFS One Zone**. Cold files in EFS → **EFS-IA** via Lifecycle Management.
- Big data / parallel workloads on EFS → **Max I/O** performance mode.

---

## 04. Databases

### Aurora & RDS
- **Lambda connection errors to RDS / Aurora** → **RDS Proxy** (Lambda in the VPC).
- **No DB passwords in Lambda code, with connection pooling** → **RDS Proxy + IAM Auth** (Secrets Manager behind the Proxy).
- **Passwordless DB login** → **IAM Database Authentication**.
- **Undo a mistake in Aurora without a new DB** → **Backtrack**.
- **Quick test DB from prod, no storage cost** → **Database Cloning**.
- **Unpredictable / intermittent traffic** → **Aurora Serverless**.
- **Cross-Region DR, RTO < 1 min, replication < 1 s** → **Global Database**.
- **Heavy analytics without hurting other readers** → **Custom Endpoint**.
- **Encrypt an existing unencrypted RDS DB** → **Snapshot + restore as encrypted**.
- **RDS unused for months** → **Manual Snapshot + delete DB**.
- **Legacy app needs OS access to DB** → **RDS Custom**.
- **T-SQL on PostgreSQL without code changes** → **Babelfish**.

### ElastiCache
- **Real-time gaming leaderboard** → **Redis (Sorted Sets)**.
- **Multi-AZ, persistence, backups** → **Redis**. **Simple, multi-threaded** → **Memcached**.
- **No stale data after DB write** → **Write Through**.
- **Cache with no app code changes** → **not ElastiCache** → use **RDS Read Replicas** or **DynamoDB DAX**.

---

## 05. Networking

### Route 53

- **Root domain (`example.com`) → AWS resource** → **Alias**, never CNAME (free, tracks IP, type A/AAAA).
- **Alias to a single EC2** → **not possible** → **A record (Elastic IP)**, or CNAME for a subdomain only.
- **Domain at GoDaddy, DNS in Route 53** → **Public Hosted Zone** + replace **NS** at the registrar. No transfer, never Private.
- **Lowest latency for users** → **Latency-based**. **Legal / country borders** → **Geolocation** (+ Default record). **Shift traffic with Bias** → **Geoproximity**.
- **Canary / A/B (e.g. 5%)** → **Weighted**. **Active-Passive DR** → **Failover**.
- **Simple DNS balancing with health checks** → **Multi-Value Answer** (max 8).
- **Health check on private VPC resource** → **CloudWatch Alarm**.
- **On-prem → AWS DNS** → **Inbound Endpoint**. **AWS → on-prem DNS** → **Outbound Endpoint**.
- **Migration with high TTL** → lower TTL (e.g. 60 s) → wait the old TTL → change record → raise TTL back.
- **100% SLA** → **Route 53**.

---

## 06. Integrations

---

## 07. Analytics
