#!/usr/bin/env bash
set -e
if jq --version 2>/dev/null; then
    :
else
    curl -sL -o /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
    chmod +x /usr/bin/jq
fi
export AWS_REGION="eu-west-1"
export AWS_DEFAULT_REGION="$AWS_REGION"

# Tests for init
awslocal s3 mb s3://test-bucket 1>/dev/null 2>/dev/null || true
awslocal s3 ls test-bucket 1>/dev/null 2>/dev/null

# Completed init :)
echo "Localstack is Ready!"
