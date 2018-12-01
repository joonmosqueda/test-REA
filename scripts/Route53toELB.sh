#!/bin/bash -ex

source /etc/profile.d/proxy.sh
source /etc/profile.d/cloud-environment.sh

HOSTNAME="${HOST}.${DOMAIN}"

JSONFILE=/tmp/json


# Assume a role (e.g. HIPExtNpRoute53UpdateRole) and extract credentials
export AWS_REGION="ap-southeast-2"
aws sts assume-role --role-arn "$ROUTE53_PROFILE" --role-session-name "DNSManipulate" > /tmp/route53.json
AWS_SECRET_ACCESS_KEY=$(exec grep SecretAccessKey /tmp/route53.json | awk -F: '{print $2}' | awk -F\" '{print $2}')
export AWS_SECRET_ACCESS_KEY
AWS_ACCESS_KEY_ID=$(grep AccessKeyId /tmp/route53.json | awk -F: '{print $2}' | awk -F\" '{print $2}')
export AWS_ACCESS_KEY_ID
AWS_SECURITY_TOKEN=$(grep SessionToken /tmp/route53.json | awk -F: '{print $2}' | awk -F\" '{print $2}')
export AWS_SECURITY_TOKEN

# This zone now has 5000+ records in it and downloading the zone takes ages
# Also, it scares the sh*t out of me of what could happen if someone messes up.
existingRecords=$(dig +short "${HOSTNAME}"); if [ -z "$existingRecords" ]; then echo FAILURE; else echo SUCCESS; fi

cat <<EOF > "$JSONFILE"
{
    "Comment": "update elb dns to route53 endpoint for jenkins ",
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "$HOSTNAME.",
                "Type": "A",
                "AliasTarget":
                    {
                        "HostedZoneId": "$ELB_ZONEID",
                        "DNSName": "$ELB_DNS",
                        "EvaluateTargetHealth": false
                    }
            }
        }
    ]
}
EOF

cat $JSONFILE

aws route53 change-resource-record-sets --hosted-zone-id "${ZONE_ID}" --change-batch file://$JSONFILE
# aws route53 get-change --id C2FNW58L41NYKM

rm -f /tmp/route53.json "$JSONFILE"
