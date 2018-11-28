#!/bin/bash -e

# USAGE
#
#   ./build-packer-rebuild.sh
#
# DESCRIPTION
#
#   Rebuild packer AMI for Jenkins stack, CI job.
#
# KNOWN USAGES
#
#   Run by housekeeping job on Jenkins instance: jenkins.dfp.extnp.national.com.au/jobs/housekeeping/jenkins-packer-rebuild
#
# AUTHOR
#
#   Matt Fellows

. $(dirname $0)/lib/utils
source_proxy
OS=$1
VERSION=$2
RESULT=$(${WORKSPACE}/scripts/bootstrap/curl_ami.py ${OS} ${VERSION})
CONFIRM=$(echo $RESULT | awk -F";" '{print $1}')
LATEST_AMI=$(echo $RESULT | awk -F";" '{print $2}')

if [[ $CONFIRM == "REBUILD" ]]; then
    echo "Rebuilding "
    CHECKPOINT_DISABLE=1 PACKER_LOG=true PACKER_LOG_PATH=$(pwd)/packer.log /usr/local/bin/packer build -force -var base_ami=$LATEST_AMI -var build_version=${BUILD_NUMBER} ${WORKSPACE}/packer.json
fi