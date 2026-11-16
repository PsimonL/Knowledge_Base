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
├── README.md                   # Repository overview, study resources, and module breakdown
├── 01_security_identity.md     # IAM, KMS, Secrets Manager, WAF, Shield, GuardDuty, Macie, CloudTrail, Organizations/SCP
├── 02_compute.md               # EC2 (Instances, Placement Groups, Purchase Options), ELB, ASG, Lambda, ECS/EKS/Fargate
├── 03_storage.md               # EBS, EFS, FSx, Instance Store, AMI, S3 (Classes, Lifecycle, CRR), Storage Gateway, DataSync
├── 04_databases.md             # RDS (Multi-AZ, Proxy, Custom), Aurora (Quorum, Serverless, Global DB), DynamoDB, ElastiCache, DAX, Redshift
├── 05_networking_delivery.md   # VPC (SG/NACL/Endpoints), Peering, Transit Gateway, Route 53, CloudFront, Global Accelerator
├── 06_integration_analytics.md # SQS, SNS, Kinesis, EventBridge, Amazon MQ, Athena, Glue, EMR, AI/ML (SageMaker/Bedrock)
└── 07_cheatsheet.md            # Exam Tips by scenario + "X vs. Y" comparison tables + DR strategies & Cost Optimization
```

---

Below is the architectural breakdown of this repository. Each file targets a specific core pillar of the AWS ecosystem. Use these files to map real-world scenarios directly to the correct AWS services.

# AWS Certified Solutions Architect - Associate (SAA-C03) Study Roadmap

This folder contains my personal study notes, architectural patterns, and cheat sheets prepared for the **AWS Certified Solutions Architect - Associate** exam. The notes are structured according to the official AWS Exam Guide domains, focusing on scenario-based problem-solving and architectural best practices.

## Folder Structure & Scope

*   **`01_security_identity.md` — Security, Identity & Governance**
    *   **IAM:** Users, Groups, Roles, Instance Profiles, Policy evaluation logic, Cross-Account access, and IAM Database Authentication.
    *   **Encryption & Secrets:** AWS KMS (CMKs, key rotation, envelope encryption), AWS Secrets Manager (auto-rotation), and Parameter Store.
    *   **Perimeter & Threat Detection:** AWS WAF, AWS Shield (Standard/Advanced), GuardDuty, Inspector, Macie, and AWS Certificate Manager (ACM).
    *   **Multi-Account & Auditing:** AWS Organizations, **Service Control Policies (SCPs)**, AWS RAM, CloudTrail, and AWS Config.

*   **`02_compute.md` — Compute, Containers & Serverless**
    *   **Amazon EC2:** Instance families, Placement Groups (Cluster, Spread, Partition), User Data, Metadata (IMDSv2), and ENIs.
    *   **EC2 Purchase Options:** On-Demand, Spot Instances, Reserved Instances (Standard/Convertible), Savings Plans, and Dedicated Hosts/Instances.
    *   **Scaling & Load Balancing:** Elastic Load Balancing (**ALB, NLB, GWLB**), Target Groups, SSL offloading, and Auto Scaling Groups (ASG policies).
    *   **Serverless & Containers:** AWS Lambda (concurrency, VPC networking, execution limits), Amazon ECS, EKS, and **AWS Fargate**.

*   **`03_storage.md` — Block, File, Object & Hybrid Storage**
    *   **Instance-Level Storage:** EBS (gp3, io2, st1, sc1, snapshots, encryption), EC2 Instance Store (ephemeral), and AMIs.
    *   **Shared File Systems:** Amazon EFS (POSIX, performance/throughput modes) and **Amazon FSx** (Windows File Server, Lustre, NetApp ONTAP, OpenZFS).
    *   **Amazon S3:** Storage Classes (Standard, IA, Intelligent-Tiering, Glacier tiers), Lifecycle rules, Versioning, MFA Delete, CRR/SRR, Presigned URLs, and Encryption (SSE-S3/KMS/C).
    *   **Hybrid & Migration:** **AWS Storage Gateway** (File, Volume, Tape), AWS DataSync, Snow Family, and AWS Transfer Family.

*   **`04_databases.md` — Relational, NoSQL & In-Memory Caching**
    *   **Amazon RDS:** Multi-AZ (HA) vs. Read Replicas (scaling), Automated Backups vs. Manual Snapshots, PITR, **RDS Proxy** (connection pooling & 66% faster failover), and **RDS Custom**.
    *   **Amazon Aurora:** 6-copy Storage Quorum (4/6 write, 3/6 read), Endpoints (Writer, Reader, Custom), **Aurora Serverless**, **Global Database** (<1 min RTO), Backtrack, Database Cloning, and Babelfish.
    *   **NoSQL & Analytics DB:** Amazon DynamoDB (RCU/WCU, GSI/LSI, Streams, Global Tables) and **Amazon Redshift** (OLAP, Redshift Spectrum).
    *   **In-Memory Caching:** **Amazon ElastiCache (Redis vs. Memcached)** — *Lazy Loading*, *Write Through*, *Session Store*, Sorted Sets — and **DynamoDB DAX**.

*   **`05_networking_delivery.md` — Networking & Content Delivery**
    *   **VPC Fundamentals:** CIDR, Subnets, Route Tables, IGW, NAT Gateway vs. NAT Instance, Egress-Only IGW, DHCP Option Sets.
    *   **VPC Security:** Security Groups (stateful) vs. NACLs (stateless, ephemeral ports), and **VPC Endpoints** (Gateway vs. Interface / PrivateLink).
    *   **Hybrid & Multi-VPC:** VPC Peering (non-transitive), **AWS Transit Gateway**, Site-to-Site VPN, and AWS Direct Connect (DX).
    *   **DNS & Edge Networking:** Amazon Route 53 (routing policies, health checks), **Amazon CloudFront** (OAC, caching, Lambda@Edge), and **AWS Global Accelerator** (Anycast IPs).

*   **`06_integration_analytics.md` — App Integration, Analytics & AI/ML**
    *   **Decoupling & Messaging:** Amazon SQS (Standard, FIFO, DLQ, Visibility Timeout), SNS (fan-out pattern), Amazon MQ, and Step Functions.
    *   **Streaming & Events:** Amazon Kinesis (Data Streams, Data Firehose) and Amazon EventBridge.
    *   **Data Analytics:** Amazon Athena (serverless S3 SQL), AWS Glue (ETL & Data Catalog), Amazon EMR, and OpenSearch.
    *   **AI / ML Services:** High-level exam patterns for Amazon Rekognition, Comprehend, Textract, Polly, Transcribe, SageMaker, and Bedrock.

*   **`07_cheatsheet.md` — SAA-C03 Exam Strategy, Comparisons & Cost/DR**
    *   **Keyword-to-Service Mapping:** Fast trigger-word associations for exam scenarios.
    *   **"X vs. Y" Trade-Off Tables:** SQS vs. Kinesis, ALB vs. NLB, Redis vs. Memcached, EFS vs. FSx, DataSync vs. Storage Gateway, Global Accelerator vs. CloudFront.
    *   **Disaster Recovery (DR):** Backup & Restore, Pilot Light, Warm Standby, and Multi-Site Active-Active (RTO vs. RPO).
    *   **Cost Optimization Playbook:** AWS Budgets, Cost Explorer, Compute Optimizer, S3 Tiering, and compute/database cost-cutting traps.

---

## 🚀 Exam Strategy & Technical Trap Log

While modules `01` through `06` provide deep technical specifications per service, **`07_cheatsheet.md`** ties everything together against the 4 official SAA-C03 exam pillars (*Secure, Resilient, High-Performing, Cost-Optimized*):
*   **Constraint-Based Elimination:** Identifying whether the prompt optimizes for *Lowest Cost*, *Lowest Latency*, *Zero Administration*, or *Minimal Code Changes*.
*   **Service Limits & Traps:** Remembering hard constraints (e.g., *ElastiCache requires code changes*, *unencrypted RDS cannot be encrypted in place*, *VPC Peering is non-transitive*).
