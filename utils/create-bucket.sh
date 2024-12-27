#!/bin/bash

set -o pipefail


check_bucket_exists() {
    local bucket_name=$1

    bucket_exists=$(aws s3api list-buckets --query "Buckets[?Name=='$bucket_name'].Name | [0]" --output text)

    if [[ "$bucket_exists" == "$bucket_name" ]]; then
        return 0
    else
        return 1
    fi
}


create_s3_bucket() {
    local bucket_name=$1
    local aws_region=$2

    if [[ $aws_region == "us-east-1" ]]; then
        aws s3api create-bucket --bucket "$bucket_name" --region $aws_region
    else
        aws s3api create-bucket --bucket "$bucket_name" --region $aws_region --create-bucket-configuration LocationConstraint=$aws_region
    fi

    if [[ $? -eq 0 ]]; then
        echo "Bucket '$bucket_name' created successfully."
        return 0
    else
        echo "Failed to create bucket '$bucket_name'."
        return 1
    fi
}



enable_versioning() {
    local bucket_name=$1

    aws s3api put-bucket-versioning --bucket "$bucket_name" --versioning-configuration Status=Enabled

    if [[ $? -eq 0 ]]; then
        echo "Versioning enabled on bucket '$bucket_name'."
        return 0
    else
        echo "Failed to enable versioning on bucket '$bucket_name'."
        return 1
    fi
}


main() {
    local bucket_name="devsecops-bucket-dev-es453s"
    local aws_region="us-east-1"
    local enable_versioning_flag=true

    if check_bucket_exists "$bucket_name"; then
        echo "Bucket $bucket_name already exists. No action needed."
    else
        echo "Attempting to create the bucket in $aws_region region..."
        if create_s3_bucket "$bucket_name" "$aws_region"; then
            if [[ "$enable_versioning_flag" == true ]]; then
                echo "Enabling versioning for bucket $bucket_name..."
                enable_versioning "$bucket_name"
            fi
        fi
    fi
}


main

