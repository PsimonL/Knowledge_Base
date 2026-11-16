# AWS Certified Solutions Architect – Associate (Exam Code: SAA-C03)

## Goal of this Folder
The purpose of this repository is to serve as a high-yield, structured knowledge base for **passing** the AWS SAA-C03 exam. It is organized to map core AWS architectural domains into concise, pattern-matching cheat sheets, enabling a fast and efficient path to certification.

## Noteworthy Courses & Resources
- **[Ultimate AWS Certified Solutions Architect Associate (SAA-C03)](https://www.udemy.com/course/aws-certified-solutions-architect-associate-saa-c03/), Stephane Maarek**  
  ➔ *Best for:* **Fast-paced theoretical overviews, concise slides, and exam-focused cramming.**
- **[Practice Exams | AWS Certified Solutions Architect Associate](https://www.udemy.com/course/practice-exams-aws-certified-solutions-architect-associate/?couponCode=MT261005G2A), Stephane Maarek, Abhishek Singh**  
  ➔ *Best for:* **Exposing knowledge gaps, learning keyword-matching patterns, and realistic exam simulation.**
- **[AWS Certified Solutions Architect - Associate (SAA-C03)](https://learn.cantrill.io/p/aws-certified-solutions-architect-associate-saa-c03), Adrian Cantrill**  
  ➔ *Best for:* **Deep engineering skills, visual architecture diagrams, and comprehensive real-world hands-on labs.**

> NOTE: Worth chekcing out - [Adrian Cantrill's SAA Exam Guide & Student Notes](https://cantrill.io/2020/05/24/Passing-the-AWS-certified-solutions-architect-associate-saa-c02-certification.html#:~:text=on%20the%20service.-,Student%20Notes,-One%20of%20my) => Exam strategies

## Notes Folder Structure

```text
aws_saa/
├── README.md                   # Repository overview, study resources, module breakdown
├── 01_security_identity.md     # IAM, KMS, Secrets Manager, WAF, Shield, GuardDuty, Macie, CloudTrail, Organizations/SCP
├── 02_compute.md               # EC2 (Instances, Placement Groups, Purchase Options), ELB, ASG, Lambda, ECS/EKS/Fargate
├── 03_storage.md               # EBS, EFS, FSx, Instance Store, AMI, S3 (Classes, Lifecycle, CRR), Storage Gateway, DataSync
├── 04_databases.md             # RDS (Multi-AZ, Proxy, Custom), Aurora (Quorum, Serverless, Global DB), DynamoDB, ElastiCache, DAX, Redshift
├── 05_networking_delivery.md   # VPC (SG/NACL/Endpoints), Peering, Transit Gateway, Route 53, CloudFront, Global Accelerator
├── 06_integration.md           # SQS, SNS, Kinesis, EventBridge, Amazon MQ, Step Functions
├── 07_analytics_ml.md          # Athena, Glue, EMR, OpenSearch, QuickSight, AI/ML (SageMaker/Bedrock)
└── 08_cheatsheet.md            # Exam Tips by scenario + "X vs. Y" tables + DR strategies & Cost Optimization
```

## Exam Domains → Files

The notes are organized by service, but the exam is organized by 4 domains. Use this map to see where each domain lives.

| Exam domain | Weight | Main files |
|---|---|---|
| **Design Secure Architectures** | 30% | `01` (IAM, KMS, WAF, Organizations), `05` (VPC security, endpoints), `03` (S3 / EBS encryption) |
| **Design Resilient Architectures** | 26% | `02` (ELB, ASG), `04` (Multi-AZ, replicas), `05` (Route 53, Global Accelerator), `06` (SQS, SNS, Kinesis), `08` (DR) |
| **Design High-Performing Architectures** | 24% | `02` (instance types, placement), `03` (EBS, EFS, FSx), `04` (ElastiCache, DAX), `05` (CloudFront), `07` (analytics, ML) |
| **Design Cost-Optimized Architectures** | 20% | `02` (Purchase Options), `03` (S3 tiering), `08` (cost playbook) |

## Folder Structure & Scope

*   **`01_security_identity.md`: Security, Identity & Governance**
    *   **IAM:** Users, Groups, Roles, Instance Profiles, policy evaluation logic, cross-account access, IAM Database Authentication.
    *   **Encryption & Secrets:** AWS KMS (CMKs, key rotation, envelope encryption), Secrets Manager (auto-rotation), Parameter Store.
    *   **Perimeter & Threat Detection:** AWS WAF, AWS Shield (Standard/Advanced), GuardDuty, Inspector, Macie, AWS Certificate Manager (ACM).
    *   **Multi-Account & Auditing:** AWS Organizations, **Service Control Policies (SCPs)**, AWS RAM, CloudTrail, AWS Config.

*   **`02_compute.md`: Compute, Containers & Serverless**
    *   **Amazon EC2:** instance families, Placement Groups (Cluster, Spread, Partition), User Data, Metadata (IMDSv2), ENIs, lifecycle (Stop / Terminate / Hibernate).
    *   **EC2 Purchase Options:** On-Demand, Spot, Reserved Instances (Standard/Convertible), Savings Plans, Dedicated Hosts/Instances, Capacity Reservations.
    *   **Scaling & Load Balancing:** Elastic Load Balancing (**ALB, NLB, GWLB**), Target Groups, SSL/SNI, Auto Scaling Groups (scaling policies).
    *   **Serverless & Containers:** AWS Lambda (concurrency, VPC networking, limits), Amazon ECS, EKS, **AWS Fargate**.

*   **`03_storage.md`: Block, File, Object & Hybrid Storage**
    *   **Instance-Level Storage:** EBS (gp3, io2, st1, sc1, snapshots, encryption), EC2 Instance Store (ephemeral), AMIs.
    *   **Shared File Systems:** Amazon EFS (POSIX, performance/throughput modes) and **Amazon FSx** (Windows File Server, Lustre, NetApp ONTAP, OpenZFS).
    *   **Amazon S3:** storage classes (Standard, IA, Intelligent-Tiering, Glacier tiers), Lifecycle rules, Versioning, MFA Delete, CRR/SRR, presigned URLs, encryption (SSE-S3/KMS/C).
    *   **Hybrid & Migration:** **AWS Storage Gateway** (File, Volume, Tape), DataSync, Snow Family, Transfer Family.

*   **`04_databases.md`: Relational, NoSQL & In-Memory Caching**
    *   **Amazon RDS:** Multi-AZ (HA) vs. Read Replicas (scaling), automated backups vs. manual snapshots, PITR, **RDS Proxy** (connection pooling, up to 66% faster failover), **RDS Custom**.
    *   **Amazon Aurora:** 6-copy storage quorum (4/6 write, 3/6 read), endpoints (Writer, Reader, Custom), **Serverless**, **Global Database** (< 1 min RTO), Backtrack, Cloning, Babelfish.
    *   **NoSQL & Data Warehouse:** DynamoDB (RCU/WCU, GSI/LSI, Streams, Global Tables) and **Redshift** (OLAP, Spectrum).
    *   **In-Memory Caching:** **ElastiCache (Redis vs. Memcached)**: Lazy Loading, Write Through, Session Store, Sorted Sets; **DynamoDB DAX**.

*   **`05_networking_delivery.md`: Networking & Content Delivery**
    *   **VPC Fundamentals:** CIDR, subnets, route tables, IGW, NAT Gateway vs. NAT Instance, Egress-Only IGW, DHCP option sets.
    *   **VPC Security:** Security Groups (stateful) vs. NACLs (stateless, ephemeral ports), **VPC Endpoints** (Gateway vs. Interface / PrivateLink).
    *   **Hybrid & Multi-VPC:** VPC Peering (non-transitive), **Transit Gateway**, Site-to-Site VPN, Direct Connect.
    *   **DNS & Edge:** Route 53 (routing policies, health checks), **CloudFront** (OAC, caching, Lambda@Edge), **Global Accelerator** (Anycast IPs).

*   **`06_integration.md`: Application Integration**
    *   **Decoupling & Messaging:** SQS (Standard, FIFO, DLQ, Visibility Timeout), SNS (fan-out), Amazon MQ.
    *   **Streaming & Events:** Kinesis (Data Streams, Data Firehose), EventBridge.
    *   **Orchestration:** Step Functions.

*   **`07_analytics_ml.md`: Analytics & AI/ML**
    *   **Data Analytics:** Athena (serverless SQL on S3), Glue (ETL & Data Catalog), EMR, OpenSearch, QuickSight.
    *   **AI / ML:** exam-level patterns for Rekognition, Comprehend, Textract, Polly, Transcribe, SageMaker, Bedrock.

*   **`08_cheatsheet.md`: Exam Strategy, Comparisons & Cost/DR**
    *   **Keyword-to-Service Mapping:** trigger-word associations for exam scenarios (the *Exam Tips* from every module, grouped by service category).
    *   **"X vs. Y" Trade-Off Tables:** SQS vs. Kinesis, ALB vs. NLB, Redis vs. Memcached, EFS vs. FSx, DataSync vs. Storage Gateway, Global Accelerator vs. CloudFront.
    *   **Disaster Recovery:** Backup & Restore, Pilot Light, Warm Standby, Multi-Site Active-Active (RTO vs. RPO).
    *   **Cost Optimization Playbook:** Budgets, Cost Explorer, Compute Optimizer, S3 tiering, compute/database cost-cutting traps.

## 🚀 Exam Strategy & Technical Trap Log

Modules `01`–`07` hold the technical specs per service. **`08_cheatsheet.md`** ties everything together against the 4 SAA-C03 pillars (*Secure, Resilient, High-Performing, Cost-Optimized*):

*   **Constraint-Based Elimination:** identify what the prompt optimizes for: *Lowest Cost*, *Lowest Latency*, *Zero Administration*, or *Minimal Code Changes*.
*   **Service Limits & Traps:** remember hard constraints (e.g. *ElastiCache requires code changes*, *an unencrypted RDS DB can't be encrypted in place*, *VPC Peering is non-transitive*).