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
├── README.md               # Main roadmap, study timeline, and global keyword cheat sheet
├── 01_compute.md           # EC2, Lambda, Auto Scaling, ECS/EKS, App Integration (SQS/SNS)
├── 02_storage.md           # S3, EBS, EFS, Glacier, AWS Snow Family
├── 03_databases.md         # RDS, Aurora, DynamoDB, ElastiCache, Analytics (Redshift/Athena)
├── 04_networking.md        # VPC, Route 53, CloudFront, Direct Connect, Transit Gateway
└── 05_security_mgmt.md     # IAM, KMS, Secrets Manager, CloudWatch, CloudTrail
```
Below is the architectural breakdown of this repository. Each file targets a specific core pillar of the AWS ecosystem. Use these files to map real-world scenarios directly to the correct AWS services.
- **[01_compute.md](01_compute.md)**  
    ➔ *What it covers:* Core processing power (`EC2`, `Lambda`), automated elasticity (`Auto Scaling`), containerization (`ECS/EKS`), and application decoupling (`SQS/SNS/Kinesis`).  
    ➔ *Focus:* Deciding between traditional servers, serverless functions, or microservices based on traffic predictability.
- **[02_storage.md](02_storage.md)**  
    ➔ *What it covers:* Object storage (`S3`), block storage (`EBS`), shared file systems (`EFS`), long-term archiving (`Glacier`), and physical data migration (`Snow Family`).  
    ➔ *Focus:* Cost optimization lifecycles and choosing the correct storage type based on performance requirements (IOPS vs. throughput).
- **[03_databases.md](03_databases.md)**  
    ➔ *What it covers:* Relational data (`RDS`, `Aurora`), NoSQL data (`DynamoDB`), in-memory caching (`ElastiCache`), and Big Data analytics (`Redshift`, `Athena`, `Glue`).  
    ➔ *Focus:* High availability (Multi-AZ), read scaling (Read Replicas), and choosing the right database engine based on data structure and latency limits.
- **[04_networking.md](04_networking.md)**  
    ➔ *What it covers:* Custom virtual networks (`VPC`), global traffic routing (`Route 53`), content delivery networks (`CloudFront`), and hybrid cloud connectivity (`Direct Connect`, `Transit Gateway`).  
    ➔ *Focus:* Designing secure network isolation (subnets, NACLs, Security Groups) and connecting on-premises infrastructure to AWS.
- **[05_security_mgmt.md](05_security_mgmt.md)**  
    ➔ *What it covers:* Identity and access governance (`IAM`), data encryption (`KMS`), sensitive credential rotation (`Secrets Manager`), infrastructure monitoring (`CloudWatch`), and API auditing (`CloudTrail`).  
    ➔ *Focus:* The Principle of Least Privilege, compliance auditing, and centralizing security policies across multi-account organizations.

