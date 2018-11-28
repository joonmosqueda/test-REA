#!/bin/bash -e
# Source temporary admin user creds and env vars
. /etc/profile.d/cloud-environment.sh

# Source proxy
. /etc/profile.d/proxy.sh
if [[ "${ENABLE_BACKUPS}" == "true" ]] ; then
    aws s3 ls
    /usr/local/bin/backup.py --bucket "${BACKUP_BUCKET}" --bucket-prefix "${HOST}.${DOMAIN}-jenkins-backup" --bucket-region ap-southeast-2 create --jenkins-home /data/jenkins_home/
fi
