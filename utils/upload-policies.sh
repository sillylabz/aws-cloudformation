#!/bin/bash

set -o pipefail


get_absolute_path() {
    local relative_path=$1
    echo "$(cd "$(dirname "$relative_path")" && pwd)/$(basename "$relative_path")"
}


check_bucket_exists() {
    local bucket_name=$1

    bucket_exists=$(aws s3api list-buckets --query "Buckets[?Name=='$bucket_name'].Name | [0]" --output text)

    if [[ "$bucket_exists" == "$bucket_name" ]]; then
        return 0
    else
        return 1
    fi
}


upload_policies() {
    local bucket_name=$1
    local source_directory=$2
    local destination_prefix="iam-policies"

    if [[ ! -d "$source_directory" ]]; then
        echo "Source directory $source_directory does not exist."
        return 1
    fi

    for file in "$source_directory"/*.json; do
        if [[ -f "$file" ]]; then
            aws s3 cp "$file" "s3://$bucket_name/$destination_prefix/" --only-show-errors
            if [[ $? -eq 0 ]]; then
                echo "Uploaded: $file to s3://$bucket_name/$destination_prefix/"
            else
                echo "Failed to upload: $file"
            fi
        fi
    done
}


main() {
    local bucket_name="devsecops-bucket-dev-es453s"
    local source_directory
    source_directory=$(get_absolute_path "./iam/policies")

    if check_bucket_exists "$bucket_name"; then
        echo "Bucket $bucket_name exists. Proceeding with upload..."
        upload_policies "$bucket_name" "$source_directory"
    else
        echo "Bucket '$bucket_name' does not exist. Please create the bucket before running this script."
    fi
}


main

