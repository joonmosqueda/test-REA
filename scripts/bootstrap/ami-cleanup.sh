#!/bin/bash -e

# USAGE
#
#   ./ami-cleanup <tag>
#
# DESCRIPTION
#
#   Cleanup old Jenkins AMI images for a given TAG.
#
# KNOWN USAGES
#
#   Run by housekeeping job on Jenkins instance.
#
# AUTHOR
#
#   Matt Fellows

export AWS_REGION=ap-southeast-2
export AWS_DEFAULT_REGION=ap-southeast-2

if [ -f "/etc/profile.d/proxy.sh" ]; then
    source /etc/profile.d/proxy.sh
fi

# Cleaning ami's of type build
currentamiid=$(curl http://169.254.169.254/latest/meta-data/ami-id)
amis=$(aws ec2 describe-images --image-ids --filter Name=name,Values="jenkins-dfp-build-*" | jq --raw-output '.Images | sort_by(.CreationDate) | .[] | .ImageId')
echo "$amis"
for ami in $(aws ec2 describe-images --image-ids --filter Name=name,Values="jenkins-dfp-build-*" --output=text --query Images[].ImageId )
do
    if [ "$ami" != "$currentamiid"  ]; then
        echo "$ami"
        echo aws ec2 deregister-image --image-id "$ami"
        aws ec2 deregister-image --image-id "$ami"
    fi
done
