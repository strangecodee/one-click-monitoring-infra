# One-Click Monitoring and Observability Infrastructure

This repository contains the complete automation code to provision and configure a highly secure monitoring and observability stack on Amazon Web Services (AWS). It utilizes Terraform for infrastructure provisioning, Ansible for software configuration, and Jenkins to orchestrate the entire workflow.

---

## System Architecture

The architecture is built on AWS following security best practices. The resources are separated into public and private network areas within a Virtual Private Cloud (VPC):

### Public Network (Ingress Area)
* **Application Load Balancer (ALB)**: Acts as the public entry point for users accessing the Grafana portal. It forwards traffic securely to the private monitoring servers behind it.
* **Bastion Host (Jump Box)**: A single, secure access point exposed to SSH traffic. All administration and Ansible software installation commands are routed through this host to reach the private servers.
* **NAT Gateway**: Allows the private monitoring instances to securely connect to the internet to download updates and packages, while blocking direct inbound connections from the internet.

### Private Network (Secure Area)
* **Monitoring Instances**: Virtual machines running in an Autoscaling Group. These instances host the core observability applications (Prometheus, Alertmanager, and Grafana).
* **Amazon EFS (Elastic File System)**: Shared network storage mounted at `/var/lib/grafana` on the monitoring instances. This ensures that even if a server is replaced or scaled, all dashboard layouts, users, and configurations are preserved.

---

## Observability Software Stack

The following monitoring tools are automatically installed and configured:
* **Prometheus**: Collects and stores real-time system performance metrics.
* **Node Exporter**: An agent running on all servers that exposes machine-level metrics (CPU, Memory, Disk, and Network usage).
* **Alertmanager**: Handles alerts sent by Prometheus and routes them to notification channels like Slack.
* **Grafana**: A visualization dashboard tool that queries Prometheus to present system metrics on interactive graphs.

---

## Jenkins Automation Workflows

The automation is managed by two linked Jenkins pipelines utilizing a shared Groovy helper library:

### 1. Upstream Pipeline: Infrastructure Provisioning
* **Script Location**: `jenkins/Jenkinsfile.infra`
* **Purpose**: Performs formatting validations, boots up the remote AWS storage backend, and runs Terraform commands to create the AWS VPC network, servers, security rules, load balancers, and file storage.
* **Output**: Once the infrastructure is created, it outputs the public IP of the Bastion host and the EFS storage ID, and automatically triggers the downstream configuration pipeline.

### 2. Downstream Pipeline: Service Configuration
* **Script Location**: `jenkins/Jenkinsfile.ansible`
* **Purpose**: Performs a syntax check on Ansible configuration playbooks, logs into the newly created AWS instances via the Bastion Host, and runs playbooks to install Node Exporter, Prometheus, Alertmanager, and Grafana.

---

## Slack and Email Notifications

Notifications keep the engineering team informed about pipeline status and system health:

### Jenkins Pipeline Alerts
On build success or failure, Jenkins triggers an automated email and posts a formatted message to a designated Slack channel.
* **Success Alerts**: Contain environment summaries, build links, and a direct URL to access the Grafana console.
* **Failure Alerts**: Inform the team of build errors and provide quick links to execution logs for diagnostics.

### Alertmanager Slack Alerts
When a server experiences high utilization (e.g. CPU > 80% or Disk Space > 85%), Prometheus triggers an alert. Alertmanager aggregates these alerts and posts them to Slack with details about the severity, target host, and description of the issue.

---

## Grafana System Monitor Dashboard

The stack automatically provisions a pre-configured dashboard containing the following visual panels:
* **Time Series**: Historical graphs showing CPU and Memory usage patterns for each server.
* **Gauge**: Circular indicators showing current CPU, Memory, Disk, and Network usage.
* **Pie Chart**: Visualizes network traffic load distribution across instances.
* **Activity Heatmap**: Highlights peak resource utilization density zones over time.
* **Table**: A status board combining CPU, Memory, and online availability status for all monitored instances.
* **Logs**: Integration placeholder showing system syslog events.

---

## Directory Structure

* **`ansible/`**: Contains the inventory configurations and roles to install software on monitoring servers.
* **`jenkins/`**: Houses the pipeline definitions for both infrastructure provisioning and service configuration.
* **`jenkins-shared-library/`**: Contains reusable pipeline logic for notifications and execution blocks.
* **`terraform/`**: Holds the infrastructure configuration files for creating AWS resources.

---

## Setup and Deployment Guide

### Step 1: Add Jenkins Credentials
Before running the jobs, ensure that the following keys are registered in the Jenkins Credentials vault:
1. **`aws-credentials-id`**: AWS Access Key ID.
2. **`aws-secret-credentials-id`**: AWS Secret Access Key.
3. **`aws-ssh-key-id`**: SSH private key file for server access.
4. **`slack-webhook-url`**: Incoming Slack Webhook URL.

### Step 2: Trigger Deployment
1. Log into Jenkins and select the **`Infrastructure-Provisioning`** job.
2. Configure parameters:
   * **`ACTION`**: Set to `apply` to deploy or `destroy` to tear down.
   * **`NOTIFICATION_EMAIL`**: Enter the target email for SMTP notifications.
3. Click **Build with Parameters** to start the automatic deployment.
