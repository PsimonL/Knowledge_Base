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
aws_csaa/
├── README.md                     # Main roadmap, study timeline, and global keyword cheat sheet
├── 01_secure_arch.md             # IAM, SCP, KMS, Secrets Manager, VPC (SG/NACL/Endpoints), Transit Gateway, WAF, Shield, GuardDuty, Macie, CloudTrail, RAM
├── 02_resilient_arch.md          # ELB, ASG, SQS, SNS, Route 53, Global Accelerator, RDS (Multi-AZ), Aurora, Kinesis, EventBridge, Storage Gateway, DR
├── 03_high_perform_arch.md       # EC2, EBS, EFS, FSx, CloudFront, ElastiCache, DAX, Lambda, DynamoDB, Redshift, Athena, DataSync, Transfer Family, AI/ML
└── 04_cost_optimized_arch.md     # S3 (Lifecycle/Glacier/Intelligent-Tiering), Spot/Reserved Inst., Savings Plans, Cost Explorer, Budgets, Organizations  
```

Below is the architectural breakdown of this repository. Each file targets a specific core pillar of the AWS ecosystem. Use these files to map real-world scenarios directly to the correct AWS services.

# AWS Certified Solutions Architect - Associate (SAA-C03) Study Roadmap

This folder contains my personal study notes, architectural patterns, and cheat sheets prepared for the **AWS Certified Solutions Architect - Associate** exam. The notes are structured according to the official AWS Exam Guide domains, focusing on scenario-based problem-solving and architectural best practices.

## Folder Structure & Scope
The study material is divided into 4 core architectural domains as defined by AWS:

*   **`01_secure_arch.md` — Design Secure Architectures (30% of exam)**
    *   Identity and Access Management (IAM) policies, roles, and security best practices.
    *   Data protection, encryption at rest/in transit using AWS KMS and Secrets Manager.
    *   Network isolation, VPC security (Security Groups, NACLs, VPC Endpoints).
    *   Advanced networking: **VPC Peering**, **AWS Transit Gateway** (centralized routing), and **AWS RAM** (resource sharing).
    *   Infrastructure protection using AWS WAF, Shield, GuardDuty, and AWS Config.
    *   Governance, multi-account strategy with AWS Organizations, **Service Control Policies (SCPs)**, and CloudTrail auditing.

*   **`02_resilient_arch.md` — Design Resilient Architectures (26% of exam)**
    *   High Availability (HA) and Scalability using Elastic Load Balancing (ELB) and Auto Scaling Groups (ASG).
    *   Decoupling application layers with messaging services (SQS, SNS, Amazon MQ).
    *   Event-driven architectures using Amazon Kinesis and AWS Lambda.
    *   Highly available data tiers (RDS Multi-AZ, Aurora Read Replicas, DynamoDB global tables).
    *   Hybrid integration & backup: **AWS Storage Gateway** (File/Volume/Tape) and **AWS Backup**.
    *   Global traffic routing, DNS strategies using Amazon Route 53, and **AWS Global Accelerator** (non-HTTP/Anycast IP).
    *   Disaster Recovery (DR) strategies: Backup & Restore, Pilot Light, Warm Standby, Multi-Site (+ **S3 CRR/SRR**).

*   **`03_high_perform_arch.md` — Design High-Performing Architectures (24% of exam)**
    *   Compute optimization (EC2 instance types, placement groups, AWS Fargate, ECS/EKS).
    *   High-performance storage solutions (EBS IOPS optimization, EFS, **Amazon FSx for Lustre/Windows**, Instance Store).
    *   Global content delivery and caching using Amazon CloudFront and ElastiCache.
    *   Database acceleration: **DynamoDB DAX** (microsecond caching).
    *   Data migration & analytics: **AWS DataSync**, **AWS Transfer Family**, Amazon Redshift, Athena, Glue, EMR.
    *   Artificial Intelligence and Machine Learning integration (Amazon SageMaker, Amazon Bedrock).

*   **`04_cost_optimized_arch.md` — Design Cost-Optimized Architectures (20% of exam)**
    *   Compute cost optimization (Spot Instances vs. Reserved Instances vs. Savings Plans).
    *   Storage tiering lifecycle policies (S3 Standard, Infrequent Access, **S3 Intelligent-Tiering**, Glacier Instant/Flexible/Deep Archive).
    *   Network data transfer charge mitigation and cost-effective routing.
    *   Serverless vs. Provisioned resource allocation strategies (e.g., Aurora Serverless).
    *   Cost management tools (AWS Budgets, Cost Explorer, AWS Compute Optimizer).


## 🚀 Exam Strategy & Technical Trap Log

Every module includes a dedicated **"Trap Log"** section. Instead of just listing what services do, the notes focus on technical trade-offs (**X vs. Y**) and common exam pitfalls:
*   Differentiating between similar services based on constraints (e.g., *Lowest Cost* vs. *Lowest Latency*).
*   Understanding service limits, minimum storage durations, and retrieval fees.
*   Identifying keyword triggers in exam scenarios (e.g., *"Highly available with immediate failover"* -> *Multi-AZ*, while *"Read heavy scaling"* -> *Read Replicas*).

---
