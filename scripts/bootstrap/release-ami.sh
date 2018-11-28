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

accounts=$WORKSPACE/accounts.txt

amiid=$(curl http://169.254.169.254/latest/meta-data/ami-id)
echo "$amiid"
imagename=$(aws ec2 describe-images --image-ids "$amiid" --query 'Images[*].Name' --output text)
buildno=${imagename##*-}
newimagename="jenkins-dfp-release-$buildno"
newamiid=$(aws ec2 copy-image --name $newimagename --source-image-id "$amiid" --region ap-southeast-2 --source-region ap-southeast-2 --output text)
sleep 10m
aws ec2 wait image-available --image-ids "$newamiid"
while IFS='' read -r line || [[ -n "$line" ]]; do
    aws ec2 modify-image-attribute --image-id "$newamiid" --launch-permission "{\"Add\":[{\"UserId\":\"$line\"}]}"
done < "$accounts"
