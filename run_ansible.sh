#!/bin/bash -ex

#export http_proxy=http://forwardproxy:3128
#export https_proxy=http://forwardproxy:3128
#export no_proxy=localhost,169.254.169.254,patching-server-hui.ext.national.com.au
#export AWS_DEFAULT_REGION=ap-southeast-2

BASE_DIR=$(dirname $0)

CONFIG_FILENAME=$1

if [[ -z ${CONFIG_FILENAME} ]] ; then
    echo "Expected Ansible parameters file, but got nothing"
    exit 1
fi
if [[ ! -f ${CONFIG_FILENAME} ]] ; then
    echo "${CONFIG_FILENAME} does not exist"
    exit 1
fi

ansible-playbook deploy.yaml --extra-vars '{"config_file":"'${CONFIG_FILENAME}'"}' -vvv
