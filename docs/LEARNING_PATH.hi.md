# 🎓 Enterprise EKS DevSecOps & GitOps Platform: Mastery Guide (Hinglish)

> 🌐 **Language Selector / مبدّل اللغات / भाषा चुनें**:  
> [🇬🇧 English](LEARNING_PATH.md) • **[🇮🇳 Hinglish (वर्तमान)]** • [🇸🇦 العربية](LEARNING_PATH.ar.md)

> **Author**: [Faisal Ansari](https://faisal.host) • [LinkedIn](https://www.linkedin.com/in/clumsyfaisal/)  
> **Target Cloud**: AWS (`ap-south-1` Mumbai)  
> **Orchestration**: Kubernetes on AWS EKS (`1.36+`)  
> **GitOps Engine**: ArgoCD with Automated Sync & Self-Healing  
> **Infrastructure as Code**: Terraform "One-Go Apply" (VPC, EKS, ECR, Route 53, ACM SSL, Helm Addons)  
> **Public HTTPS Endpoint**: [https://eks.faisal.host](https://eks.faisal.host)

---

## 📑 Table of Contents
1. [Scratch Se Samajhte Hain: ClickOps Se GitOps Tak Ka Safar](#1-scratch-se-samajhte-hain-clickops-se-gitops-tak-ka-safar)
2. [End-to-End Enterprise Architecture Blueprint](#2-end-to-end-enterprise-architecture-blueprint)
3. [Terraform "One-Go Apply" Engine Ka Deep Dive](#3-terraform-one-go-apply-engine-ka-deep-dive)
4. [In-Cluster Day-1 Addons: Metrics Server, AWS LBC aur ArgoCD](#4-in-cluster-day-1-addons-metrics-server-aws-lbc-aur-argocd)
5. [Microservice DevSecOps: Dockerfile aur Aqua Trivy Scanning](#5-microservice-devsecops-dockerfile-aur-aqua-trivy-scanning)
6. [Pure GitOps: ArgoCD State Kaise Manage Karta Hai?](#6-pure-gitops-argocd-state-kaise-manage-karta-hai)
7. [Production Hardening: PDB, HPA aur Non-Root UID 10001](#7-production-hardening-pdb-hpa-aur-non-root-uid-10001)
8. [Automated HTTPS: Route 53 aur ACM SSL Architecture](#8-automated-https-route-53-aur-acm-ssl-architecture)
9. [Hands-On Runbook aur Stress Testing Playbook](#9-hands-on-runbook-aur-stress-testing-playbook)
10. [Top 20 Platform Engineer & SRE Interview Q&A](#10-top-20-platform-engineer--sre-interview-qa)

---

## 1. Scratch Se Samajhte Hain: ClickOps Se GitOps Tak Ka Safar

Agar aap bilkul shuruat se sikh rahe hain, toh samajhte hain ki industry me deployment kaise evolve hui:

### 1. ClickOps (Purana Tareeka)
AWS Web Console me jakar buttons click karke EC2, VPC ya EKS banana.
- **Nuksan**: Human error, koi track record nahi, aur doosra environment banana bohot mushkil.

### 2. Infrastructure as Code (Terraform)
Code file (`.tf`) me likh kar ek command se poora AWS setup banana.
- **Fayda**: Automated, repeatable, aur audit trail.

### 3. Pure GitOps (ArgoCD)
Pehle CI/CD runner cluster ke andar push karta tha. Lekin **GitOps** me cluster ke andar baitha **ArgoCD agent** Git repo ko har 30 seconds me monitor karta hai. Agar kisi ne production me galti se pod delete kiya ya badla, toh ArgoCD use turant pakad kar Git wale version par wapas le aata hai (**Self-Healing**).

---

## 2. End-to-End Enterprise Architecture Blueprint

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Platform Engineer
    participant Git as GitHub (complete-eks-devsecops-platform)
    participant GHA_TF as Terraform Pipeline
    participant AWS as AWS Cloud (ap-south-1)
    participant GHA_APP as App DevSecOps Pipeline
    participant ECR as AWS ECR Registry
    participant Argo as ArgoCD (Inside EKS)
    participant EKS as Production Pods
    participant ALB as AWS Application Load Balancer

    Dev->>Git: Push Infrastructure Code (terraform/)
    Git->>GHA_TF: Trigger 01-terraform-infra.yml
    GHA_TF->>AWS: VPC, EKS 1.36, ECR, Route 53, ACM SSL
    GHA_TF->>AWS: Helm Deploy: Metrics Server, AWS LBC, ArgoCD

    Dev->>Git: Push Application Code (app/)
    Git->>GHA_APP: Trigger 02-app-ci-cd.yml
    Note over GHA_APP: Lint, Unit Test, Docker Buildx, Trivy Scan
    GHA_APP->>ECR: Scanned Image Push (Git SHA tag)
    GHA_APP->>Git: Update gitops/ kustomization.yaml image tag
    
    loop ArgoCD Reconciliation Loop (Every 30s)
        Argo->>Git: Naya Git SHA Detect Karta Hai
        Argo->>EKS: Zero-Downtime Rolling Update Shuru
    end

    ALB->>EKS: Secure HTTPS Traffic Route (https://eks.faisal.host)
```

---

## 3. Terraform "One-Go Apply" Engine Ka Deep Dive

Pehle hume bohot se kaam manual karne padte the. Is naye project me Terraform **ek single apply** me sab kuch setup kar deta hai:
1. **`modules/vpc`**: 3 Availability Zones, Public subnets (ALB ke liye), Private subnets (Worker nodes ke liye), NAT Gateway aur IGW.
2. **`modules/eks`**: EKS v1.36 Cluster, KMS Secret Encryption, Managed Node Groups (`t3.medium`), aur OIDC Provider (IRSA ke liye).
3. **`modules/ecr`**: Private registry with automatic vulnerability scan on push aur 10-image lifecycle policy (AWS cost control).
4. **`modules/route53-acm`**: Route 53 me `eks.faisal.host` ke liye ACM SSL certificate create aur auto-validate karta hai.
5. **`modules/cluster-addons`**: Terraform ke Helm provider se cluster bante hi Metrics Server, AWS Load Balancer Controller aur ArgoCD auto-install kar deta hai!

---

## 4. In-Cluster Day-1 Addons: Metrics Server, AWS LBC aur ArgoCD

### A. Metrics Server (HPA Fix)
Node kubelet se CPU aur Memory data collect karta hai taaki Autoscaling (HPA) real metrics dekh sake.

### B. AWS Load Balancer Controller (LBC)
Yeh controller Ingress resource dekhte hi AWS me real Application Load Balancer (ALB) banata hai aur pods ke IP direct target group me jodta hai.

### C. ArgoCD
GitOps engine jo continuous delivery aur zero-drift policy enforce karta hai.

---

## 5. Microservice DevSecOps: Dockerfile aur Aqua Trivy Scanning

### Multi-Stage Distroless Dockerfile
```dockerfile
# Stage 1: Build & Dependencies
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
- **Non-Root User (`UID 10001`)**: Hacker agar container hack bhi kar le, toh bhi woh AWS host server par root nahi ban sakta.
- **Aqua Trivy Scan**: CI stage me hi CRITICAL aur HIGH vulnerabilities ko block kar deta hai (Shift-Left Security).

---

## 6. Pure GitOps: ArgoCD State Kaise Manage Karta Hai?

In [gitops/argocd/application.yaml](file:///Users/deadpool/Documents/Project/complete-eks-devsecops-platform/gitops/argocd/application.yaml):
- `selfHeal: true`: Agar koi cluster me manual changes karega, toh ArgoCD turant use reject karke Git ke original state par restore kar dega.
- `prune: true`: Agar Git se koi file delete hui, toh cluster se bhi safely remove ho jayegi.

---

## 7. Production Hardening: PDB, HPA aur Non-Root UID 10001

- **Zero-Downtime Rolling Update**: `maxUnavailable: 0` ensure karta hai ki purane pods tab tak nahi band honge jab tak naye pods `/readyz` pass na kar lein.
- **PodDisruptionBudget (PDB)**: `minAvailable: 1` ensure karta hai ki node upgrade ya maintenance ke dauraan service kabhi down na ho.
- **Horizontal Pod Autoscaler (HPA)**: CPU 70% ya Memory 80% cross hote hi pods automatically 2 se 10 scale ho jate hain.

---

## 8. Automated HTTPS: Route 53 aur ACM SSL Architecture

- Ingress annotations se HTTP (Port 80) automatically HTTPS (Port 443) par redirect ho jata hai.
- AWS ALB trusted Amazon SSL certificate use karta hai jisse browser me green padlock 🔒 dikhta hai.

---

## 9. Hands-On Runbook aur Stress Testing Playbook

```bash
# Addons pods verify karein
kubectl get pods -n kube-system
kubectl get pods -n argocd

# Live resource consumption check karein
kubectl top nodes
kubectl top pods -n production
kubectl get hpa -n production

# High-traffic stress test run karein
kubectl run load-generator --rm -i --tty --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://complete-eks-portal-service.production.svc.cluster.local:80; done"
```

---

## 10. Top 20 Platform Engineer & SRE Interview Q&A

1. **GitOps Push vs Pull Model me kya farak hai?**
   Push model me CI runner ke paas cluster admin credentials hote hain. Pull model (ArgoCD) me agent cluster ke andar baith kar Git se pull karta hai, credentials kabhi bahar leak nahi hote.

2. **AWS Load Balancer Controller ka kya faayda hai?**
   Yeh Layer 7 Application Load Balancers (ALB) banata hai aur pods ke IP directly target groups me map karta hai, jisse latency kam hoti hai.

3. **HPA ka mathematical formula kya hai?**
   $$\text{Desired Replicas} = \left\lceil \text{Current Replicas} \times \left( \frac{\text{Current Metric}}{\text{Target Metric}} \right) \right\rceil$$
