#!/bin/bash -e

if [ -f "/etc/profile.d/proxy.sh" ]; then
    source /etc/profile.d/proxy.sh
fi

stacktype=${1:-release}

if [ ${stacktype} == 'test' ]; then
    AMI=$(aws ec2 describe-images --image-ids --filter Name=name,Values="jenkins-dfp-build-*"| jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId')
else
    AMI=$(aws ec2 describe-images --image-ids --filter Name=name,Values="jenkins-dfp-release-*"| jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId')
fi

echo $AMI