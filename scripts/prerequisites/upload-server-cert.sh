#!/bin/bash -ex

if [ -f "/etc/profile.d/proxy.sh" ]; then
    source /etc/profile.d/proxy.sh
fi

SCRIPT_DIR=$(dirname $0)

ELB_CERT_FILE=$1
ELB_CERT_KEY_FILE=$2
ELB_CERT_PEM_FILE=$3
IAM_ASSUMED_ROLE=$4
AWS_CERT_NAME=$5

if [[ -z ${ELB_CERT_FILE} ]] ; then
    echo "Path and filename for ELB certificate .cer is required"
    exit 1
fi
if [[ -z ${ELB_CERT_KEY_FILE} ]] ; then
    echo "Path and filename for ELB certificate .key is required"
    exit 1
fi
if [[ -z ${ELB_CERT_PEM_FILE} ]] ; then
    echo "Path and filename for ELB certificate .pem is required"
    exit 1
fi
if [[ -z ${IAM_ASSUMED_ROLE} ]] ; then
    echo "IAM Role to assume is required"
    exit 1
fi
if [[ -z ${AWS_CERT_NAME} ]] ; then
    echo "Certificate Name is required"
    exit 1
fi

if [[ ! -f ${ELB_CERT_FILE} ]] ; then
    echo "Can't find .cer file: ${ELB_CERT_FILE}"
    exit 1
fi
if [[ ! -f ${ELB_CERT_KEY_FILE} ]] ; then
    echo "Can't find .key file: ${ELB_CERT_KEY_FILE}"
    exit 1
fi
if [[ ! -f ${ELB_CERT_PEM_FILE} ]] ; then
    echo "Can't find .pem file: ${ELB_CERT_PEM_FILE}"
    exit 1
fi

# Assume a role (e.g. HIPExtNpRoute53UpdateRole) and extract credentials
export AWS_REGION="ap-southeast-2"
aws sts assume-role --role-arn "$IAM_ASSUMED_ROLE" --role-session-name "UploadServerCert" > /tmp/creds.json
export AWS_SECRET_ACCESS_KEY=$(exec grep SecretAccessKey /tmp/creds.json | awk -F: '{print $2}' | awk -F\" '{print $2}')
export AWS_ACCESS_KEY_ID=$(grep AccessKeyId /tmp/creds.json | awk -F: '{print $2}' | awk -F\" '{print $2}')
export AWS_SECURITY_TOKEN=$(grep SessionToken /tmp/creds.json | awk -F: '{print $2}' | awk -F\" '{print $2}')


# This is the cert needed for the ELB in the CFN for the instance. For this to work, the .pem can't contain the same cert that's in .cer
aws iam upload-server-certificate --server-certificate-name ${AWS_CERT_NAME} \
                                  --certificate-body file://${ELB_CERT_FILE} \
                                  --private-key file://${ELB_CERT_KEY_FILE} \
                                  --certificate-chain file://${ELB_CERT_PEM_FILE}

