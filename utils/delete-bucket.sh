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


bucket_has_objects() {
    local bucket_name=$1

    object_count=$(aws s3 ls s3://$bucket_name --recursive|wc -l)

    if [[ "$object_count" -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

is_versioning_enabled() {
    local bucket_name=$1

    version_status=$(aws s3api get-bucket-versioning --bucket "$bucket_name" --query "Status" --output text)

    if [[ "$version_status" == "Enabled" ]]; then
        return 0
    else
        return 1
    fi
}


empty_versioned_bucket() {
    local bucket_name=$1

    echo "Removing all versions and delete markers from bucket '$bucket_name'..."

    aws s3api list-object-versions --bucket "${bucket_name}" --output=json --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}' > delete-markers.json

    if [[ $? -ne 0 ]]; then
        echo "Failed to fetch object versions or delete markers."
        return 1
    fi

    aws s3api delete-objects --bucket "$bucket_name" --delete file://delete-markers.json

    if [[ $? -ne 0 ]]; then
        echo "Failed to delete objects and delete markers from the bucket."
        rm -f delete-markers.json
        return 1
    else
        echo "All versions and delete markers removed successfully."
        rm -f delete-markers.json
    fi
}


empty_non_versioned_bucket() {
    local bucket_name=$1

    echo "Removing all objects from bucket '$bucket_name'..."
    aws s3 rm "s3://$bucket_name" --recursive
}


delete_bucket() {
    local bucket_name=$1

    echo "Deleting bucket '$bucket_name'..."
    aws s3api delete-bucket --bucket "$bucket_name"
}


main() {
    local bucket_name="devsecops-bucket-dev-es453s"

    if check_bucket_exists "$bucket_name"; then
        echo "Bucket '$bucket_name' exists. Proceeding with deletion..."

        if bucket_has_objects "$bucket_name"; then
            echo "Bucket '$bucket_name' contains objects."

            if is_versioning_enabled "$bucket_name"; then
                echo "Bucket '$bucket_name' has versioning enabled."
                 if ! empty_versioned_bucket "$bucket_name"; then
                    echo "Failed to empty the versioned bucket. Exiting."
                    exit 1
                fi
            else
                echo "Bucket '$bucket_name' does not have versioning enabled."
                if ! empty_non_versioned_bucket "$bucket_name"; then
                    echo "Failed to empty the bucket. Exiting."
                    exit 1
                fi
            fi
        else
            echo "Bucket '$bucket_name' has no objects."
        fi

        if ! delete_bucket "$bucket_name"; then
            echo "Failed to delete bucket. Exiting."
            exit 1
        else
            echo "Bucket '$bucket_name' deleted successfully."
        fi
    else
        echo "Bucket '$bucket_name' does not exist."
    fi
}

main

