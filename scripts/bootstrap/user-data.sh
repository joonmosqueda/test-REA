#!/bin/bash -ex

# USAGE
#
#   route53-setup.sh hostname iam-role (ip)?
#
# DESCRIPTION
#
#   Bootstrap the Jenkins instance with runtime information.
#
#   Requires the following environment variables:
#
#    - HOST   - Jenkins DNS prefix e.g. jenkins.nab-labs
#    - DOMAIN - Subdomain e.g extnp.national.com.au
#    - GIT_BOOTSTRAP_URL - URL to fetch list of jobs
#
# KNOWN USAGES
#
#   Kicked off by cloudformation user-data script.
#
# AUTHOR
#
#   Matt Fellows
#
# Log to userdata and ship to cloudwatch
exec >> /var/log/user-data.log
exec 2>&1

# Source temporary admin user creds and env vars
. /etc/profile.d/cloud-environment.sh

# Source proxy
. /etc/profile.d/proxy.sh

# Restart Jenkins and wait
function restart_and_wait_for_jenkins() {
    echo ">> Restarting Jenkins"
    systemctl restart jenkins
    echo ">> Waiting for Jenkins to be available"
    sleep 10
    while ! nc localhost 8080; do
        sleep 5
        systemctl start jenkins
    done
    echo ">> Jenkins is up!"
}


# Log user data and runtime Jenkins logs to CloudWatch
cat <<EOF > /var/awslogs/etc/config/jenkins_awslogs.conf
[${LOG_GROUP_NAME}]
file =  /var/log/jenkins/jenkins.log
log_group_name =  ${LOG_GROUP_NAME}
log_stream_name = {instance_id}_${LOG_GROUP_NAME}
datetime_format = %b %d %H:%M:%S

[${LOG_GROUP_NAME}_userdata]
file = /var/log/user-data.log
log_group_name = ${LOG_GROUP_NAME}_userdata
log_stream_name = {instance_id}_${LOG_GROUP_NAME}_userdata
datetime_format = %b %d %H:%M:%S
EOF
systemctl restart awslogs

# Use attached EBS Volume for Jenkins_Home
mkfs -t ext4 /dev/xvdf
mkdir /data
mount /dev/xvdf /data

# make and entry in fstab to automount on reboot
fsstr="/dev/xvdf    /data   ext4    defaults    1"
fname=/etc/fstab
echo $fsstr >> $fname
mkdir /data/jenkins_home


sed -i 's;JENKINS_HOME="/var/lib/jenkins";JENKINS_HOME="/data/jenkins_home";g' /etc/sysconfig/jenkins
cp -r /var/lib/jenkins/* /data/jenkins_home

chown -R jenkins:jenkins /data

# Run bootstrap - this will seed the initial job!

/usr/local/bin/bootstrap-jenkins.sh

# Don't want to manage backups and things for some instances.
if [[ "${ENABLE_BACKUPS}" == "true" ]] ; then
    /usr/local/bin/backup.py --bucket "${BACKUP_BUCKET}" --bucket-prefix "${HOST}.${DOMAIN}-jenkins-backup" --bucket-region ap-southeast-2 restore latest --jenkins-home /data/jenkins_home/
fi

chown -R jenkins:jenkins /data

restart_and_wait_for_jenkins

#echo "updating Route53 to elb"

#/usr/local/bin/Route53toELB.sh

echo 'Startup complete!'
