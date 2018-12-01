#!/bin/bash -ex

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
