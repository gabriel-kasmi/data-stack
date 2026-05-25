# Data Stack as a Service (Modular Infrastructure)

A infrastructure-as-code (IaC) project designed to deploy a complete data stack (Ingestion, Warehouse, Transformation, Orchestration, BI) to **AWS**, **GCP**, or **Kubernetes**.

The project is structured into three completely independent platforms, each utilizing cloud-native services for maximum scalability and maintainability.

---

## 🏗 Project Structure

```text
/aws
  ├── terraform/          # Redshift, ECS, Lambda, DMS, Step Functions
  └── src/
      ├── dbt/            # dbt project and Dockerfile (runs on ECS Task)
      ├── dlt/            # dlt project and Dockerfile (runs on ECS Task)
      └── ingestion/      # Custom ingestion code and Dockerfile (runs on Lambda/ECR)

/gcp
  ├── terraform/          # BigQuery, Cloud Run, Datastream, Workflows
  └── src/
      ├── dbt/            # dbt project and Dockerfile (runs on Cloud Run Job)
      ├── dlt/            # dlt project and Dockerfile (runs on Cloud Run Job)
      └── ingestion/      # Custom ingestion code and Dockerfile (runs on Cloud Run Job)

/k8s
  ├── helm/               # Datastack Umbrella Helm Chart
  │   └── datastack/      # Chart.yaml (Postgres, Clickhouse, Airbyte, Airflow, Metabase)
  └── src/
      ├── dbt/            # dbt project and Dockerfile (K8s Jobs)
      ├── dlt/            # dlt project and Dockerfile (K8s Jobs)
      └── ingestion/      # Custom ingestion code and Dockerfile (K8s Jobs)
```

---

## 🚀 Platforms Overview

### ☁️ AWS Platform
- **Warehouse**: Amazon Redshift (Serverless or Provisioned)
- **Compute**: ECS Fargate for dbt/dlt workloads
- **Ingestion**: AWS DMS and Lambda (for custom scripts)
- **Orchestration**: AWS Step Functions
- **BI**: QuickSight

### ☁️ GCP Platform
- **Warehouse**: BigQuery
- **Compute**: Cloud Run Jobs for dbt/dlt/ingestion
- **Ingestion**: Datastream (CDC) and Cloud Run
- **Orchestration**: Cloud Workflows
- **BI**: Data Studio (Looker Studio)

### ☸️ Kubernetes Platform
- **Deployment**: Managed via an **Umbrella Helm Chart** in `k8s/helm/datastack`.
- **Database**: PostgreSQL (via Bitnami Helm Chart)
- **Warehouse**: Clickhouse (via Bitnami Helm Chart)
- **Compute**: K8s Pods/Jobs for dbt/dlt
- **Ingestion**: Airbyte (via Helm Chart)
- **Orchestration**: Airflow (via Helm Charts)
- **BI**: Metabase (via Helm Chart)

---

## 🛠 Getting Started

### Prerequisites
- [Terraform](https://www.terraform.io/downloads.html) installed locally (for AWS/GCP).
- [Helm](https://helm.sh/docs/intro/install/) installed locally (for K8s).
- Cloud CLI configured (`aws` or `gcloud`).
- Docker for building images in the `src/` directories.

### Deployment (Example: K8s)
1. **Infrastructure**:
   ```bash
   cd k8s/helm/datastack
   helm dependency update
   helm install my-datastack .
   ```

### Deployment (Example: GCP)
1. **Infrastructure**:
   ```bash
   cd gcp/terraform
   terraform init
   terraform apply
   ```
2. **Compute (Source Code)**:
   Navigate to `gcp/src/[component]`, build the Docker image, and push it to GCP Artifact Registry (managed by Terraform).
3. **Orchestration**:
   Update the Cloud Workflows definition in `gcp/terraform/workflow.tf` to trigger your deployed jobs.

### Standardized `src/` Layout
Each platform's `src` folder is ready for containerization:
- **dbt**: Includes a `Dockerfile` based on `dbt-core` and its own `profiles.yml`.
- **dlt**: Includes a `Dockerfile` for running data load tool pipelines.
- **ingestion**: A flexible directory for custom Python scripts, always accompanied by a `Dockerfile`.

---

## 🔒 Security & Best Practices
- **Secrets Management**: Each platform uses native secret managers (AWS Secrets Manager, GCP Secret Manager, or K8s Secrets).
- **Isolation**: There is NO shared logic between platforms. Each directory is a standalone deployment unit.
- **Pure IaC**: No manual SSH or shell scripts are required for deployment. Everything is managed via Terraform and Cloud API native orchestration.
