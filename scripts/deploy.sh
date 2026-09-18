#!/usr/bin/env bash
set -eo pipefail

REGION="ap-south-1"
CLUSTER_NAME="complete-eks-cluster"
STATE_BUCKET="complete-eks-devsecops-tfstate-461195385728"
LOCK_TABLE="complete-eks-devsecops-tflocks"

echo "========================================================"
echo "🚀 STARTING ONE-GO ENTERPRISE PLATFORM DEPLOYMENT 🚀"
echo "========================================================"

# Step 1: Pre-flight Backend Bootstrap
echo "📦 Step 1: Verifying S3 State Bucket & Lock Table..."
if ! aws s3api head-bucket --bucket "${STATE_BUCKET}" 2>/dev/null; then
    echo "Creating S3 state bucket: ${STATE_BUCKET}"
    aws s3api create-bucket \
      --bucket "${STATE_BUCKET}" \
      --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
    aws s3api put-bucket-versioning \
      --bucket "${STATE_BUCKET}" \
      --versioning-configuration Status=Enabled
else
    echo "✅ S3 state bucket is ready."
fi

if ! aws dynamodb describe-table --table-name "${LOCK_TABLE}" --region "${REGION}" 2>/dev/null; then
    echo "Creating DynamoDB lock table: ${LOCK_TABLE}"
    aws dynamodb create-table \
      --table-name "${LOCK_TABLE}" \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --region "${REGION}"
    aws dynamodb wait table-exists --table-name "${LOCK_TABLE}" --region "${REGION}"
else
    echo "✅ DynamoDB lock table is ready."
fi

# Step 2: Terraform Init & Apply
echo "🏗️ Step 2: Applying Terraform Infrastructure..."
cd "$(dirname "$0")/../terraform"
terraform init
terraform apply -auto-approve

# Step 3: Configure Kubectl
echo "⚙️ Step 3: Configuring Kubectl context..."
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${REGION}"

echo "========================================================"
echo "🎉 DEPLOYMENT COMPLETE! Cluster and Addons are Live."
echo "========================================================"
