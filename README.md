# One-Click Monitoring & Observability Infrastructure

A production-grade, automated observability and monitoring stack deployed on AWS. The infrastructure is provisioned dynamically via Terraform and configured using Ansible through a secured, two-stage Jenkins CI/CD pipeline.

---

## 🛠️ System Architecture

The deployment employs a highly secure, multi-tier network topology:
1. **Public Subnets**:
   - **NAT Gateway**: Handles outbound internet requests from private resources.
   - **Bastion Host (Jump Box)**: Restricts administrative SSH access to private instances.
   - **Application Load Balancer (ALB)**: Exposes the Grafana portal to the public internet while securing backend targets.
2. **Private Subnets**:
   - **Monitoring Instances**: Highly available hosts managed under an Autoscaling Group running **Prometheus**, **Alertmanager**, and **Grafana**.
   - **Node Exporters**: Automatically collect hardware and OS metrics from instances.
   - **Amazon EFS**: Dynamically mounts shared storage under `/var/lib/grafana` to ensure persistent storage for Grafana's sqlite/configuration databases across restarts and auto-scaling events.

---

## 🚀 Jenkins CI/CD Pipelines

The pipeline system utilizes a shared Groovy library (`my-shared-library`) and follows a secure, decoupled upstream/downstream model:

### 1. Upstream Pipeline: `Infrastructure-Provisioning`
* **File**: `jenkins/Jenkinsfile.infra`
* **Workflow**:
  - Checks input validation parameters (`ACTION`, `ENVIRONMENT`, `NOTIFICATION_EMAIL`).
  - Runs CI security checks (`terraform fmt`).
  - Bootstraps the AWS S3 state storage and DynamoDB state lock table.
  - Provisions the core AWS resources (`VPC`, `ALB`, `EFS`, `ASG`, `Bastion`, `IAM`).
  - Extracts output properties (`bastion_ip`, `efs_id`, `alb_dns_name`) and triggers the downstream pipeline automatically.

### 2. Downstream Pipeline: `Service-Configuration`
* **File**: `jenkins/Jenkinsfile.ansible`
* **Workflow**:
  - Dynamically builds dynamic EC2 inventories using AWS tags.
  - Performs Ansible playbook syntax checks.
  - Deploys the monitoring stack using secure credential bindings (`withCredentials`).
  - Installs and configures Node Exporter, Prometheus, Alertmanager, and Grafana.

---

## 🔔 Integrated Slack & Email Notifications

Both pipelines support structured, professional status alerts via SMTP and Slack incoming webhooks:

### Slack Notification Layout
Webhook notifications are sent directly to the `#jenkins-alerts` channel.
* **Success Layout**: Green border (`good`), subject detail, direct link to the running build, environment stats, and direct portal link to the ALB Grafana dashboard.
* **Failure Layout**: Red border (`danger`), failure logs quick-link, and environment variables context.

### Alertmanager Slack Integration
Alertmanager routes all active firing system alarms to the `#jenkins-alerts` channel using:
* Go-templated summary alerts showing status (`FIRING`/`RESOLVED`).
* Multi-line message blocks detailing target instances, warning severity, and description annotations.

---

## 📊 Grafana System Monitor Dashboard

The deployment automatically provisions a custom, dynamic **System Monitor** dashboard utilizing Prometheus metrics from Node Exporters:

| Visual Panel | Type | Description | Prometheus Query |
| :--- | :--- | :--- | :--- |
| **Time Series** | Timeseries | Trends CPU/Memory workloads per-host | `100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` |
| **Gauge** | Gauge | Spot usage status for CPU, Memory, Disk, and Network | `avg((node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / ...)` |
| **Pie Chart** | Piechart | Dynamic outbound/inbound network traffic distribution | `sum by (instance) (rate(node_network_receive_bytes_total[5m]))` |
| **Activity Heatmap** | Heatmap | Core-level CPU work density | `100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100)` |
| **Table** | Table | Multi-metric host health check status with green/red thresholds | Combined `CPU`, `Memory`, and `up` joined by `instance` |
| **Logs** | Logs | System event logs stream | Loki target syslog aggregator |

---

## 📦 Directory Structure

```directory
one-click-monitoring-infra/
├── ansible/
│   ├── group_vars/          # Environment configuration variables
│   ├── inventory/           # Dynamic EC2 inventory configurations
│   ├── roles/               # Ansible roles (Prometheus, Grafana, Node Exporter, Alertmanager)
│   └── site.yml             # Main playbook run
├── jenkins/
│   ├── Jenkinsfile.infra    # Upstream pipeline script
│   └── Jenkinsfile.ansible  # Downstream pipeline script
├── jenkins-shared-library/  # Custom Groovy pipelines shared library vars
└── terraform/               # Infrastructure resource code blocks
```

---

## ⚙️ Deployment & Setup Steps

### 1. Prerequisites
Ensure the following credentials are added to the **Jenkins Credentials Store**:
* **`aws-credentials-id`**: AWS Access Key ID (Secret text).
* **`aws-secret-credentials-id`**: AWS Secret Access Key (Secret text).
* **`aws-ssh-key-id`**: AWS SSH private key file used by Bastion and hosts.
* **`slack-webhook-url`**: Slack Incoming Webhook URL (Secret text).

### 2. Execution
1. Open Jenkins and trigger the **`Infrastructure-Provisioning`** job.
2. Select the `ACTION` (`apply` or `destroy`).
3. Enter your status tracking email under `NOTIFICATION_EMAIL`.
4. Run the build. The pipeline will automatically provision the infrastructure and configure all application services.
