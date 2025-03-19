#!/bin/bash
set -e

CONFIG_FILE="config.yaml"
OUTPUT_FILE="aws_inventory"

# Check dependencies
if ! command -v aws &> /dev/null; then
    echo "AWS CLI not found. Install it first."
    exit 1
fi
if ! command -v yq &> /dev/null; then
    echo "yq (YAML parser) not found. Install it with: sudo apt install yq"
    exit 1
fi

# Read YAML config
echo "Reading configuration..."
EC2_ENABLED=$(yq e '.resources.ec2' "$CONFIG_FILE")
S3_ENABLED=$(yq e '.resources.s3' "$CONFIG_FILE")
RDS_ENABLED=$(yq e '.resources.rds' "$CONFIG_FILE")
LAMBDA_ENABLED=$(yq e '.resources.lambda' "$CONFIG_FILE")
EKS_ENABLED=$(yq e '.resources.eks' "$CONFIG_FILE")
IAM_ENABLED=$(yq e '.resources.iam' "$CONFIG_FILE")
DYNAMODB_ENABLED=$(yq e '.resources.dynamodb' "$CONFIG_FILE")
OUTPUT_FORMAT=$(yq e '.output_format' "$CONFIG_FILE")

# Read tag filters
FILTER_TAG_KEY=$(yq e '.filters.tags | keys | .[0]' "$CONFIG_FILE")
FILTER_TAG_VALUE=$(yq e '.filters.tags."'"$FILTER_TAG_KEY"'"' "$CONFIG_FILE")

# Set output file format
OUTPUT_FILE="${OUTPUT_FILE}.${OUTPUT_FORMAT}"

# Function to log and print
log_and_print() {
    echo -e "$1" | tee -a "$OUTPUT_FILE"
}

# Function to apply tag filtering
filter_by_tag() {
    RESOURCE_TYPE=$1
    QUERY=$2
    if [ -n "$FILTER_TAG_KEY" ] && [ -n "$FILTER_TAG_VALUE" ]; then
        aws $RESOURCE_TYPE describe-tags --filters "Name=tag:$FILTER_TAG_KEY,Values=$FILTER_TAG_VALUE" --query "$QUERY" --output $OUTPUT_FORMAT | tee -a "$OUTPUT_FILE"
    else
        aws $RESOURCE_TYPE describe-$RESOURCE_TYPE --query "$QUERY" --output $OUTPUT_FORMAT | tee -a "$OUTPUT_FILE"
    fi
}

# Start Logging
echo "Fetching AWS resources..." | tee "$OUTPUT_FILE"

# Fetch EC2 Instances
if [ "$EC2_ENABLED" == "true" ]; then
    log_and_print "\nEC2 Instances:"
    aws ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,Type:InstanceType,Tags:Tags}" --output $OUTPUT_FORMAT | tee -a "$OUTPUT_FILE"
fi

# Fetch S3 Buckets
if [ "$S3_ENABLED" == "true" ]; then
    log_and_print "\nS3 Buckets:"
    aws s3api list-buckets --query "Buckets[*].{Name:Name,CreationDate:CreationDate}" --output $OUTPUT_FORMAT | tee -a "$OUTPUT_FILE"
fi

# Fetch RDS Instances (Fixed)
if [ "$RDS_ENABLED" == "true" ]; then
    log_and_print "\nRDS Instances:"
    aws rds describe-db-instances --query "DBInstances[*].{ID:DBInstanceIdentifier,Engine:Engine,Status:DBInstanceStatus,Endpoint:Endpoint.Address}" --output $OUTPUT_FORMAT | tee -a "$OUTPUT_FILE"
fi

# Fetch Lambda Functions
if [ "$LAMBDA_ENABLED" == "true" ]; then
    log_and_print "\nLambda Functions:"
    aws lambda list-functions --query "Functions[*].{Name:FunctionName,Runtime:Runtime,Memory:MemorySize}" --output $OUTPUT_FORMAT | tee -a "$OUTPUT_FILE"
fi

# Fetch EKS Clusters
if [ "$EKS_ENABLED" == "true" ]; then
    log_and_print "\nEKS Clusters:"
    aws eks list-clusters --query "clusters" --output $OUTPUT_FORMAT | tee -a "$OUTPUT_FILE"
fi

# Fetch IAM Users
if [ "$IAM_ENABLED" == "true" ]; then
    log_and_print "\nIAM Users:"
    aws iam list-users --query "Users[*].{Username:UserName,Created:CreateDate}" --output $OUTPUT_FORMAT | tee -a "$OUTPUT_FILE"
fi

# Fetch DynamoDB Tables
if [ "$DYNAMODB_ENABLED" == "true" ]; then
    log_and_print "\nDynamoDB Tables:"
    aws dynamodb list-tables --query "TableNames" --output $OUTPUT_FORMAT | tee -a "$OUTPUT_FILE"
fi

log_and_print "\nAWS Inventory complete! Output saved to $OUTPUT_FILE"

