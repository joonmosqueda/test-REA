#!/bin/bash -ex

# USAGE
#
#   ./provision.sh
#
# DESCRIPTION
#
#    Main provisioning script for Jenkins server
#
# KNOWN USAGES
#
#    jenkins.*.extnp.national.com.au
#
# AUTHOR
#
#   Matt Fellows

export AWS_DEFAULT_REGION=ap-southeast-2

# Configure Proxy
echo 'export http_proxy=http://forwardproxy:3128' > /etc/profile.d/proxy.sh
echo 'export https_proxy=http://forwardproxy:3128' >> /etc/profile.d/proxy.sh
echo 'export no_proxy=.national.com.au,169.254.169.254,*.thenational.com,github.aus.thenational.com,artifactory.aus.thenational.com' >> /etc/profile.d/proxy.sh
source /etc/profile.d/proxy.sh

# Configure CloudWatch
cd /tmp
cat <<EOF > /var/awslogs/etc/config/jenkins_ami_awslogs.conf
[dfp_jenkins_ami_userdata]
file = /var/log/user-data.log
log_group_name =  dfp_jenkins_ami
log_stream_name = {instance_id}_jenkinsami_userdata
datetime_format = %b %d %H:%M:%S
EOF

# Yum Proxy
cat <<EOF >> /etc/yum.conf
http_proxy="http://forwardproxy:3128"
https_proxy="http://forwardproxy:3128"
EOF

# Install required packages
cat <<EOF > /etc/yum.repos.d/epel.repo
[epel]
name=Extra Packages for Enterprise Linux 7 - x86_64
enabled = 1
sslverify = 0
gpgcheck = 0
baseurl=https://dl.fedoraproject.org/pub/epel/7/x86_64
EOF
cat <<EOF > /etc/yum.repos.d/centos.repo
[centos]
name=centos core
enabled = 1
sslverify = 0
gpgcheck = 0
baseurl=http://mirror.centos.org/centos/7/os/x86_64
EOF
cat <<EOF > /etc/yum.repos.d/extras.repo
[extras]
name=Extra
enabled = 1
sslverify = 0
gpgcheck = 0
baseurl=http://mirror.centos.org/centos/7/extras/x86_64
EOF
cat <<EOF > /etc/yum.repos.d/updates.repo
[updates]
name=Update
enabled = 1
sslverify = 0
gpgcheck = 0
baseurl=http://mirror.centos.org/centos/7/updates/x86_64
EOF
yum install -y yum-utils
#yum update
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
yum install -y awscli
yum -y update
wget https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.amzn1.noarch.rpm && yum install -y aws-cfn-bootstrap-latest.amzn1.noarch.rpm
yum -y update openssl
yum -y install java-1.8.0-openjdk.x86_64
echo 'export JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk' | sudo tee -a /etc/profile
echo 'export JRE_HOME=/usr/lib/jvm/jre' | sudo tee -a /etc/profile
source /etc/profile
yum -y install nc jenkins git jq ShellCheck bind-utils

# Docker
yum install -y yum-utils device-mapper-persistent-data lvm2 vim
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --enable extras
yum makecache fast
yum -y install docker-ce zip

# Install pip for the jenkins master packer and curl scripts
pip install bs4 botocore boto3 jenkins-job-builder-addons jenkins-job-builder click ansible --upgrade
pip install awscli --upgrade

# Setup git access
cp /tmp/config/.ssh/known_hosts ~/.ssh/known_hosts
cp /tmp/config/.ssh/config ~/.ssh/config

# Run Docker in specific group
mkdir -p /etc/docker/
cat <<EOF > /etc/docker/daemon.json
{
  "group": "docker"
}
EOF
# TODO: Update Docker mounted volume as per below
# "graph": "/path/to/mounted/volume",
usermod -aG docker ec2-user
usermod -aG docker jenkins

# Docker - add proxy configuration
mkdir -p /etc/systemd/system/docker.service.d
cat <<EOF > /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=http://forwardproxy:3128/" "HTTPS_PROXY=http://forwardproxy:3128/" "NO_PROXY=localhost,169.254.169.254,patching-server-hui.ext.national.com.au,.national.com.au,.nab.com.au,.thenational.com,.nab.com.au,.ap-southeast-2.compute.internal"
EOF
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
systemctl daemon-reload

# Install NAB certificates
cd /tmp/config/certs/
./trust-me.sh $JAVA_HOME
systemctl stop jenkins

# Proxy, GH / Credentials etc. Config Files for Jenkins
cp /tmp/config/jenkins/*.* /var/lib/jenkins/
mkdir -p /var/lib/jenkins/init.groovy.d/
cp -r /tmp/config/init.groovy.d/* /var/lib/jenkins/init.groovy.d/
mkdir -p /var/lib/jenkins/.ssh/
cp /tmp/config/.ssh/* /var/lib/jenkins/.ssh/
chmod 600 /var/lib/jenkins/.ssh/*

# Hashed out as id_rsa no longer used in directory setupchmod 600 /tmp/config/.ssh/id_rsa*

touch /etc/profile.d/cloud-environment.sh
chmod +x /etc/profile.d/cloud-environment.sh

# Set Java settings for Jenkins
ln -sf /usr/share/zoneinfo/Australia/Melbourne /etc/localtime


# Copy helper scripts

cp /tmp/scripts/bootstrap/* /usr/local/bin/
chmod +x /usr/local/bin/*.sh
chmod +x /usr/local/bin/*.py

# Install plugins
chown -R jenkins:jenkins /var/lib/jenkins/
export JENKINS_UC=https://updates.jenkins.io
/usr/local/bin/install-plugins.sh $(sed -e :a -e '/$/N; s/\n/ /; ta' /tmp/config/plugins.txt)


# Allow gradle to pull gradlew from Internet and get dependancies from artifactory
# TODO: not sure this directory even is being used
mkdir -p /usr/share/jenkins/ref/.gradle/
cp /tmp/config/properties/gradle.properties /usr/share/jenkins/ref/.gradle/gradle.properties.override


# Jenkins owns all files!
chown -R jenkins:jenkins /var/lib/jenkins/

# add sudoers for Jenkins user to allow execution of user update script and restart jenkins
# TODO: SAI - generally good practice to explicitly list files here.  Using a wildcard allows any script in this directory to be executed.
cat <<EOF > /etc/sudoers.d/10_jenkins
jenkins ALL=(root) NOPASSWD: /usr/local/bin/backup.py, /usr/local/bin/update-users.sh, /usr/local/bin/jenkins-backup.sh, /usr/local/bin/install-user-plugins.sh, /usr/local/bin/install-plugins.sh
EOF
visudo -cf /etc/sudoers.d/10_jenkins


# Install Packer
rm /sbin/packer # just a symlink to the cracklib library
wget -O packer.zip https://releases.hashicorp.com/packer/1.0.2/packer_1.0.2_linux_amd64.zip?_ga=2.78225492.1701331671.1499045892-1821478300.1497919390
unzip packer.zip && mv packer /usr/local/bin/packer && rm packer.zip

# Setup gradle
cd /tmp/config/gradle
./gradle.sh

# Ensure all services start on boot
chkconfig docker on
chkconfig awslogs on
chkconfig jenkins on
