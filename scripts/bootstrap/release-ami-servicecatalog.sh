#!/bin/bash -e

# USAGE
#
#   ./release-ami-servicecatalog.sh SERVICE_CATALOG_ACCOUNT_NUMBER SERVICECATALOG_ACCOUNT_ROLE_ARN
#
# DESCRIPTION
#
#
#
# KNOWN USAGES
#
#   Run by maintenances job on Jenkins instance to create ami in service catalog account


export AWS_REGION=ap-southeast-2
export AWS_DEFAULT_REGION=ap-southeast-2

sc_account=$1
sc_role=$2

if [ -f "/etc/profile.d/proxy.sh" ]; then
    source /etc/profile.d/proxy.sh
fi


#Share ami with service catalog account
amiid=$(curl http://169.254.169.254/latest/meta-data/ami-id)
echo "$amiid"
aws ec2 modify-image-attribute --image-id "$amiid" --launch-permission "{\"Add\":[{\"UserId\":\"$sc_account\"}]}"
imagename=$(aws ec2 describe-images --image-ids "$amiid" --query 'Images[*].Name' --output text)
buildno=${imagename##*-}
newimagename="jenkins-dfp-release-$buildno"
snapshot_id=$(aws ec2 describe-images --image-ids "$amiid" --query 'Images[0].BlockDeviceMappings[0].Ebs.SnapshotId' --output text)
aws ec2 modify-snapshot-attribute --snapshot-id $snapshot_id --attribute createVolumePermission --operation-type add --user-ids $sc_account
#assume role into service catalog account
export AWS_REGION="ap-southeast-2"
aws sts assume-role --role-arn "$sc_role" --role-session-name "sc_session" > /tmp/sc_session.json
AWS_SECRET_ACCESS_KEY=$(exec grep SecretAccessKey /tmp/sc_session.json | awk -F: '{print $2}' | awk -F\" '{print $2}')
export AWS_SECRET_ACCESS_KEY
AWS_ACCESS_KEY_ID=$(grep AccessKeyId /tmp/sc_session.json | awk -F: '{print $2}' | awk -F\" '{print $2}')
export AWS_ACCESS_KEY_ID
AWS_SECURITY_TOKEN=$(grep SessionToken /tmp/sc_session.json | awk -F: '{print $2}' | awk -F\" '{print $2}')
export AWS_SECURITY_TOKEN

#copy ami in service catalog account
newamiid=$(aws ec2 copy-image --name $newimagename --source-image-id "$amiid" --region ap-southeast-2 --source-region ap-southeast-2 --output text)
sleep 10m
aws ec2 wait image-available --image-ids "$newamiid"

echo "$newamiid"
sed "s/{AMIID}/$newamiid/g" cloudformation.yaml

