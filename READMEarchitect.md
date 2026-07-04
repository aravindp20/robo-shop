# AWS Deployment Architecture - Stan's Robot Shop

This document describes the AWS Cloud Architecture for deploying **Stan's Robot Shop** in a highly available, secure, and multi-AZ environment.

## Architecture Overview

The application is deployed on **Amazon EKS (Elastic Kubernetes Service)** across two Availability Zones (AZs) in the **Asia Pacific (Mumbai) `ap-south-1`** region. The network is isolated using a custom **VPC** with public and private subnets.

![AWS Architecture Diagram](aws-architecture.png) 
*(Note: Upload your architecture image to the repository root as `aws-architecture.png` to render it here.)*

---

## Component Architecture Diagram (Mermaid)

```mermaid
graph TD
    classDef external fill:#f5f5f5,stroke:#9e9e9e,stroke-width:2px;
    classDef public fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px;
    classDef privateApp fill:#e1f5fe,stroke:#0288d1,stroke-width:2px;
    classDef privateDb fill:#ffebee,stroke:#c62828,stroke-width:2px;

    %% External & Management
    ECR["📦 Amazon ECR<br>(Container Registry)"]:::external
    Secrets["🔑 AWS Secrets Manager"]:::external
    Client["🌐 Internet / Client"]:::external

    %% VPC
    subgraph VPC ["VPC (10.0.0.0/16)"]
        ALB["⚖️ Application Load Balancer / EKS Ingress"]:::public

        subgraph AZ_A ["Availability Zone A"]
            subgraph Public_A ["Public Subnet A (10.0.1.0/24)"]
                NAT_A["🔌 NAT Gateway A"]:::public
            end
            subgraph Private_App_A ["Private Subnet A (10.0.11.0/23)"]
                EKS_A["☸️ EKS Worker Nodes (AZ-A)"]:::privateApp
            end
            subgraph Private_Db_A ["Database Subnet A (10.0.21.0/24)"]
                RDS_A[("🐬 Amazon RDS<br>(MySQL)")]:::privateDb
                Cache_A[("🔴 ElastiCache<br>(Redis)")]:::privateDb
                MQ_A[("🐇 Amazon MQ<br>(RabbitMQ)")]:::privateDb
            end
        end

        subgraph AZ_B ["Availability Zone B"]
            subgraph Public_B ["Public Subnet B (10.0.2.0/24)"]
                NAT_B["🔌 NAT Gateway B"]:::public
            end
            subgraph Private_App_B ["Private Subnet B (10.0.14.0/23)"]
                EKS_B["☸️ EKS Worker Nodes (AZ-B)"]:::privateApp
            end
            subgraph Private_Db_B ["Database Subnet B (10.0.22.0/24)"]
                RDS_B[("🐬 Amazon RDS<br>(MySQL)")]:::privateDb
                Cache_B[("🔴 ElastiCache<br>(Redis)")]:::privateDb
                MQ_B[("🐇 Amazon MQ<br>(RabbitMQ)")]:::privateDb
            end
        end
    end

    %% Connections
    Client --> ALB
    ALB --> EKS_A
    ALB --> EKS_B

    %% Image Deployment
    ECR -->|Deploy Images| EKS_A
    ECR -->|Deploy Images| EKS_B

    %% Internet Outbound Access
    EKS_A --> NAT_A
    EKS_B --> NAT_B

    %% Secrets
    Secrets -.->|Inject Secrets| EKS_A
    Secrets -.->|Inject Secrets| EKS_B

    %% Database Connections
    EKS_A --> RDS_A
    EKS_A --> Cache_A
    EKS_A --> MQ_A

    EKS_B --> RDS_B
    EKS_B --> Cache_B
    EKS_B --> MQ_B

    %% Database Replication / High Availability
    RDS_A <--->|Replication| RDS_B
    Cache_A <--->|Replication| Cache_B
    MQ_A <--->|Replication| MQ_B
```

---

## Key Infrastructure Details

### 1. Network Subnetting (VPC: `10.0.0.0/16`)
* **Public Subnets (`10.0.1.0/24` and `10.0.2.0/24`)**: Host NAT Gateways to route outbound internet traffic from private subnets (e.g., pulling external dependencies or communicating with outside APIs).
* **Private App Subnets (`10.0.11.0/23` and `10.0.14.0/23`)**: Run EKS worker node groups in a secure zone. No direct public internet ingress is allowed; all external traffic must pass through the Load Balancer.
* **Private Database Subnets (`10.0.21.0/24` and `10.0.22.0/24`)**: Houses databases and queues. Only accessible from the Private App subnets.

### 2. Computing (Amazon EKS & Amazon ECR)
* **Amazon EKS**: The orchestration engine for running all application microservices (Web, Cart, Catalogue, User, Payment, Shipping, Ratings, and Dispatch).
* **Amazon ECR**: Serves as the private container registry, storing built Docker images for deployment on the EKS cluster.

### 3. Managed Services mapping for Stan's Robot Shop
* **Database (MySQL)** -> **Amazon RDS (Multi-AZ MySQL)**: Used by the *Shipping* and *Ratings* services.
* **Cache (Redis)** -> **Amazon ElastiCache (Redis)**: Used by the *Cart* and *User* services.
* **Message Broker (RabbitMQ)** -> **Amazon MQ (RabbitMQ)**: Used by *Payment* and *Dispatch* services.
* **Secrets Management** -> **AWS Secrets Manager**: Securely stores database passwords, API credentials, and Instana agent keys, injecting them dynamically into the EKS pods.
