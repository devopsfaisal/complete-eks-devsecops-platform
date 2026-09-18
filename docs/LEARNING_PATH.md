# 🎓 Enterprise EKS DevSecOps & GitOps Platform: Complete Mastery Guide

> 🌐 **Language Selector / مبدّل اللغات / भाषा चुनें**:  
> **[🇬🇧 English (Current)]** • [🇮🇳 Hinglish](LEARNING_PATH.hi.md) • [🇸🇦 العربية](LEARNING_PATH.ar.md)

> **Author**: [Faisal Ansari](https://faisal.host) • [LinkedIn](https://www.linkedin.com/in/clumsyfaisal/)  
> **Target Cloud**: AWS (`ap-south-1` Mumbai)  
> **Orchestration**: Kubernetes on AWS EKS (`1.36+`)  
> **GitOps Engine**: ArgoCD with Automated Reconciliation & Self-Healing  
> **Infrastructure as Code**: Terraform "One-Go Apply" (VPC, EKS, ECR, Route 53, ACM SSL, Helm Addons)  
> **Public HTTPS Endpoint**: [https://eks.faisal.host](https://eks.faisal.host)

---

## 📑 Table of Contents
1. [Foundations: The Evolution of Cloud Delivery (ClickOps -> IaC -> GitOps)](#1-foundations-the-evolution-of-cloud-delivery)
2. [End-to-End Enterprise Architecture & Data Flow](#2-end-to-end-enterprise-architecture--data-flow)
3. [Terraform "One-Go Apply" Engine Deep Dive](#3-terraform-one-go-apply-engine-deep-dive)
4. [In-Cluster Day-1 Addons: Metrics Server, AWS Load Balancer Controller & ArgoCD](#4-in-cluster-day-1-addons)
5. [Microservice Engineering & DevSecOps Scanning (Dockerfile & Aqua Trivy)](#5-microservice-engineering--devsecops-scanning)
6. [Pure GitOps Delivery: How ArgoCD Manages State](#6-pure-gitops-delivery-how-argocd-manages-state)
7. [Kubernetes Manifests & Production Hardening (PDB, HPA, Non-Root UID 10001)](#7-kubernetes-manifests--production-hardening)
8. [Automated HTTPS: Route 53 & ACM SSL Architecture](#8-automated-https-route-53--acm-ssl-architecture)
9. [Hands-On Operational Runbook & Stress Testing Playbook](#9-hands-on-operational-runbook--stress-testing-playbook)
10. [Top 20 Platform Engineer & SRE Interview Questions & Answers](#10-top-20-platform-engineer--sre-interview-questions--answers)

---

## 1. Foundations: The Evolution of Cloud Delivery

### Phase 1: ClickOps (Manual Web Console)
Engineers manually created resources in the AWS Web Console.  
- **Disadvantages**: Human misconfiguration, zero reproducibility, configuration drift, and impossible disaster recovery.

### Phase 2: Infrastructure as Code (Terraform)
Infrastructure defined as declarative `.tf` files. Terraform maintains state and calculates exact dependency graphs.  
- **Advantage**: Version controlled, auditable, and automated.

### Phase 3: Pure GitOps (ArgoCD & Kubernetes)
Instead of an external pipeline having admin access into the cluster, a controller **inside** Kubernetes continuously watches Git as the **Single Source of Truth**. If someone manually edits a pod or service in production, ArgoCD detects the drift and automatically restores the desired state (**Self-Healing**).

---

## 2. End-to-End Enterprise Architecture & Data Flow

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Platform Engineer
    participant Git as GitHub (complete-eks-devsecops-platform)
    participant GHA_TF as GHA (Terraform Pipeline)
    participant AWS as AWS Cloud (ap-south-1)
    participant GHA_APP as GHA (App DevSecOps Pipeline)
    participant ECR as AWS ECR Registry
    participant Argo as ArgoCD Controller (Inside EKS)
    participant EKS as Kubernetes Pods & Services
    participant ALB as AWS Application Load Balancer

    Dev->>Git: Push Infrastructure Code (terraform/)
    Git->>GHA_TF: Trigger 01-terraform-infra.yml
    GHA_TF->>AWS: Provision VPC, EKS 1.36, ECR, Route 53, ACM SSL
    GHA_TF->>AWS: Deploy Helm: Metrics Server, AWS LBC, ArgoCD

    Dev->>Git: Push Application Code (app/)
    Git->>GHA_APP: Trigger 02-app-ci-cd.yml
    Note over GHA_APP: Lint, Unit Test, Buildx, Aqua Trivy Scan
    GHA_APP->>ECR: Push Scanned Image (Git SHA tag)
    GHA_APP->>Git: Update gitops/ kustomization.yaml image tag
    
    loop GitOps Reconciliation Loop (every 30s)
        Argo->>Git: Detect new Git Commit SHA
        Argo->>EKS: Zero-Downtime Rolling Update (maxUnavailable: 0)
    end

    ALB->>EKS: Route HTTPS Traffic (https://eks.faisal.host)
```

---

## 3. Terraform "One-Go Apply" Engine Deep Dive

Our modular Terraform codebase provisions the entire stack in one command without manual intervention:
1. **`modules/vpc`**: 3 Availability Zones, 3 Public Subnets (tagged `kubernetes.io/role/elb = 1`), 3 Private Subnets (tagged `kubernetes.io/role/internal-elb = 1`), NAT Gateway, Internet Gateway, and Route Tables.
2. **`modules/eks`**: EKS v1.36 Control Plane with KMS secret envelope encryption, managed node groups (`t3.medium`), and IAM OpenID Connect (OIDC) provider for IRSA.
3. **`modules/ecr`**: Private container registry with scan-on-push and lifecycle rules retaining only the last 10 images to minimize AWS storage costs.
4. **`modules/route53-acm`**: Fully codified SSL certificate request for `eks.faisal.host` with automatic DNS validation records in Route 53.
5. **`modules/cluster-addons`**: Uses Terraform's `helm_release` provider to install core controllers immediately after the cluster is created.

---

## 4. In-Cluster Day-1 Addons

### A. Kubernetes Metrics Server
Scrapes CPU/Memory from node `kubelet` cAdvisors. Without Metrics Server, Horizontal Pod Autoscaling (HPA) fails with `<unknown>` metrics.

### B. AWS Load Balancer Controller (LBC)
Instead of classic in-tree load balancers, AWS LBC natively creates AWS Application Load Balancers (ALBs) when Kubernetes `Ingress` resources are created, and registers Pod IPs directly (Target Type: `ip`).

### C. ArgoCD GitOps Engine
Deploys the declarative GitOps operator in the `argocd` namespace. ArgoCD monitors `gitops/apps/portal` and synchronizes Kubernetes workloads automatically.

---

## 5. Microservice Engineering & DevSecOps Scanning

### Multi-Stage Distroless Dockerfile
```dockerfile
# Stage 1: Build Dependencies
FROM python:3.11-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Minimal Runtime
FROM python:3.11-slim
WORKDIR /app
RUN groupadd -g 10001 appgroup && useradd -u 10001 -g appgroup appuser
COPY --from=builder /root/.local /home/appuser/.local
COPY . /app/
USER 10001:10001
```
- **Why UID 10001?**: Containers running as root (`UID 0`) expose the host node to kernel privilege escalation and container breakout exploits.
- **Aqua Trivy Scanning**: Scans OS packages and application dependencies for CVEs during CI.

---

## 6. Pure GitOps Delivery: How ArgoCD Manages State

In [gitops/argocd/application.yaml](file:///Users/deadpool/Documents/Project/complete-eks-devsecops-platform/gitops/argocd/application.yaml):
- `automated.selfHeal = true`: If an engineer runs `kubectl delete pod` or modifies replicas via CLI, ArgoCD restores the Git configuration within seconds.
- `automated.prune = true`: If a resource is deleted from Git, ArgoCD cleanly garbage-collects it from the cluster.

---

## 7. Kubernetes Manifests & Production Hardening

- **Zero-Downtime Rolling Update**: `maxSurge: 25%` and `maxUnavailable: 0` ensures capacity never drops below 100%.
- **PodDisruptionBudget (PDB)**: `minAvailable: 1` ensures node maintenance or EKS version upgrades never take down the service.
- **Horizontal Pod Autoscaler (HPA)**: Scales from 2 to 10 replicas when CPU exceeds 70% or Memory exceeds 80%.

---

## 8. Automated HTTPS: Route 53 & ACM SSL Architecture

- Ingress annotations:
  ```yaml
  alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
  alb.ingress.kubernetes.io/ssl-redirect: '443'
  ```
- AWS Application Load Balancer terminates TLS on port 443 using the ACM certificate for `eks.faisal.host` and automatically redirects all HTTP port 80 traffic to HTTPS.

---

## 9. Hands-On Operational Runbook & Stress Testing Playbook

### View In-Cluster Controllers & Metrics
```bash
# Verify Metrics Server and AWS Load Balancer Controller
kubectl get pods -n kube-system

# Verify ArgoCD Controller
kubectl get pods -n argocd

# Check live resource metrics
kubectl top nodes
kubectl top pods -n production
kubectl get hpa -n production
```

### Run Real-Time Autoscaling Stress Test
```bash
# Terminal 1: Watch HPA scale
kubectl get hpa -n production -w

# Terminal 2: Generate continuous load
kubectl run load-generator --rm -i --tty --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://complete-eks-portal-service.production.svc.cluster.local:80; done"
```

---

## 10. Top 20 Platform Engineer & SRE Interview Questions & Answers

1. **What is GitOps and how does it differ from traditional CI/CD push pipelines?**
   In traditional CI/CD, the runner pushes changes into Kubernetes using admin credentials. In GitOps, an agent inside the cluster (ArgoCD) pulls changes from Git. Credentials never leave the cluster, and automatic drift detection ensures self-healing.

2. **Why use AWS Load Balancer Controller instead of in-tree Service type LoadBalancer?**
   AWS LBC supports modern ALBs (Layer 7 routing, path routing, AWS WAF, ACM SSL termination) and targets Pod IPs directly, bypassing `kube-proxy` hops.

3. **What is the mathematical formula behind HPA?**
   $$\text{Desired Replicas} = \left\lceil \text{Current Replicas} \times \left( \frac{\text{Current Metric}}{\text{Target Metric}} \right) \right\rceil$$

4. **Why are non-root containers (`UID 10001`) mandatory in production?**
   If an RCE vulnerability is exploited, running as root gives the attacker root permissions on the host node kernel. Non-root users mitigate container breakout vulnerabilities.

5. **How does IAM Roles for Service Accounts (IRSA) work?**
   IRSA uses OIDC federated authentication to exchange Kubernetes service account tokens for temporary AWS STS credentials, adhering to least privilege.
