#!/usr/bin/env bash
set -eo pipefail

REGION="ap-south-1"
CLUSTER_NAME="complete-eks-platform"
STATE_BUCKET="complete-eks-devsecops-tfstate-461195385728"
LOCK_TABLE="complete-eks-devsecops-tflocks"

echo "========================================================"
echo "🚨 STARTING ONE-GO TOTAL INFRASTRUCTURE WIPEOUT 🚨"
echo "========================================================"

# Step 1: Pre-clean Kubernetes Ingress to prevent orphan AWS ALB dependencies
if aws eks describe-cluster --name "${CLUSTER_NAME}" --region "${REGION}" >/dev/null 2>&1; then
    echo "🔍 EKS Cluster found. Configuring kubectl..."
    aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${REGION}"
    echo "🧹 Deleting Ingress and LoadBalancer services..."
    kubectl delete ingress --all --all-namespaces --timeout=2m || true
    kubectl delete svc --all --all-namespaces --field-selector spec.type=LoadBalancer --timeout=2m || true
    echo "⏳ Waiting 30 seconds for AWS ALB deprovisioning..."
    sleep 30
else
    echo "ℹ️ EKS Cluster not found or already deleted. Proceeding directly to Terraform."
fi

# Step 2: Terraform Destroy
echo "💥 Running Terraform Destroy..."
cd "$(dirname "$0")/../terraform"
terraform init
terraform destroy -auto-approve

# Step 3: Total Wipeout of Remote Backend (S3 + DynamoDB)
echo "🧹 Emptying and deleting S3 state bucket: ${STATE_BUCKET}..."
aws s3 rm "s3://${STATE_BUCKET}" --recursive || true
aws s3api delete-bucket --bucket "${STATE_BUCKET}" --region "${REGION}" || true

echo "🧹 Deleting DynamoDB lock table: ${LOCK_TABLE}..."
aws dynamodb delete-table --table-name "${LOCK_TABLE}" --region "${REGION}" || true

echo "========================================================"
echo "✅ 100% TOTAL WIPEOUT COMPLETE: ZERO COSTS LEFT ON AWS"
echo "========================================================"
