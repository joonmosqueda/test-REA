#!/bin/bash -ex

ENV_HOSTNAME="`echo $1 | awk '{print tolower($0)}'`"
HOST_DNS_SUFFIX=$2
ZONE_ID=$3
ROUTE53_PROFILE=$4

JSONFILE=/tmp/json

targetElbARN=`aws cloudformation describe-stacks --stack-name ${ENV_HOSTNAME} --query 'Stacks[].Outputs[?starts_with(OutputKey, \`ELBEndpointAddress\`) == \`true\`].OutputValue' --output text`

unset AWS_SESSION_TOKEN AWS_DELEGATION_TOKEN AWS_SECRET_ACCESS_KEY AWS_ACCESS_KEY_ID AWS_SECURITY_TOKEN AWS_ACCESS_KEY AWS_SECRET_KEY

# Assume a role and extract credentials
export AWS_REGION="ap-southeast-2"
aws sts assume-role --role-arn "$ROUTE53_PROFILE" --role-session-name "DNSManipulate" > /tmp/route53.json
AWS_SECRET_ACCESS_KEY=$(exec grep SecretAccessKey /tmp/route53.json | awk -F: '{print $2}' | awk -F\" '{print $2}')
export AWS_SECRET_ACCESS_KEY
AWS_ACCESS_KEY_ID=$(grep AccessKeyId /tmp/route53.json | awk -F: '{print $2}' | awk -F\" '{print $2}')
export AWS_ACCESS_KEY_ID
AWS_SECURITY_TOKEN=$(grep SessionToken /tmp/route53.json | awk -F: '{print $2}' | awk -F\" '{print $2}')
export AWS_SECURITY_TOKEN

cat <<EOF > "$JSONFILE"
{
    "Comment": "update elb dns to route53 endpoint",
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "$ENV_HOSTNAME.$HOST_DNS_SUFFIX",
                "Type": "CNAME",
                "TTL": 30,
                "ResourceRecords": [
                                    {
                                        "Value": "$targetElbARN"
                                    }
                                ]
            }
        }
    ]
}
EOF

cat $JSONFILE

aws route53 change-resource-record-sets --hosted-zone-id "${ZONE_ID}" --change-batch file://$JSONFILE

rm -f /tmp/route53.json "$JSONFILE"
