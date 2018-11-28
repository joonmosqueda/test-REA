#!/bin/bash -e

# USAGE
#
#   ./bootstrap-jenkins.sh
#
# DESCRIPTION
#
#   Automatically import jenkins jobs on boot.
#
#   Requires the following environment variables which are
#   sourced from cloud-environment:
#
#      - GIT_BOOTSTRAP_URL - URL to fetch list of jobs
#      - JENKINS_BOOTSTRAP_DIRECTORY - Repo checkout dir
#
# KNOWN USAGES
#
#   Included in `user-data.sh` executed by the Jenkins cloudformation stack.
#
# AUTHOR
#
#    Matt Fellows

# Source temporary admin user creds and env vars
. /etc/profile.d/cloud-environment.sh

# Temporary Jenkins admin user
JENKINS_USERNAME=$(openssl rand -base64 24 | tr -dc "a-zA-Z0-9_")
JENKINS_PASSWORD=$(openssl rand -base64 24 | tr -dc "a-zA-Z0-9_")
echo "export JENKINS_USERNAME=${JENKINS_USERNAME}" >>  /etc/profile.d/cloud-environment.sh
echo "export JENKINS_PASSWORD=${JENKINS_PASSWORD}" >> /etc/profile.d/cloud-environment.sh

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

# Import gradle
. /etc/profile.d/gradle.sh


# Create Jenkins bootstrap script.
# It is paramaterised with GIT_BOOTSTRAP_URL, GIT_BOOTSTRAP_BRANCH AND GIT_BOOTSTRAP_JENKINSFILE
cat <<EOF > /tmp/config/gradle/jobs/bootstrap.groovy
def gitUrl = '$GIT_BOOTSTRAP_URL'

folder('housekeeping-jobs')
pipelineJob('housekeeping-jobs/bootstrap') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            url(gitUrl)
            credentials('svc-account')
          }
          branches('$GIT_BOOTSTRAP_BRANCH')
        }
      }
      scriptPath('$GIT_BOOTSTRAP_JENKINSFILE')
    }
  }
}
EOF

cat <<EOF > /tmp/config/gradle/jobs/installjobplugins.groovy
def gitUrl = '$GIT_BOOTSTRAP_URL'
freeStyleJob('housekeeping-jobs/installjobplugins') {
    description('Install new plugins without having to re-bake Jenkins')
    scm {
        git {
           remote {
             url(gitUrl)
             credentials('svc-account')
           }
           branches('$GIT_BOOTSTRAP_BRANCH')
        }
    }
    logRotator {
      numToKeep(3)
      artifactNumToKeep(2)
    }
    wrappers {
      timestamps()
    }
    steps {
      shell('/usr/local/bin/install-user-plugins.sh plugins.txt')
    }
}
EOF

cat <<EOF > /tmp/config/gradle/jobs/update-users.groovy
def gitUrl = '$GIT_BOOTSTRAP_URL'
freeStyleJob('housekeeping-jobs/update-users') {
    description('Updates user access from bootstrap repo as defined in users.yaml')
    scm {
        git {
           remote {
             url(gitUrl)
             credentials('svc-account')
           }
           branches('$GIT_BOOTSTRAP_BRANCH')
        }
    }
    logRotator {
      numToKeep(3)
      artifactNumToKeep(2)
    }
    wrappers {
      timestamps()
    }
    steps {
      shell('/usr/local/bin/update-users.sh users.yaml')
    }
}
EOF

# Write out the location so the JENKINS_URL and other dependent environment variables are correctly set.
# Doing this here as it needs the host & domain name which is dynamic
cat <<EOF > /data/jenkins_home/jenkins.model.JenkinsLocationConfiguration.xml
<jenkins.model.JenkinsLocationConfiguration>
  <adminAddress>BCT.DevOps.Central.Mailbox@nab.com.au</adminAddress>
  <jenkinsUrl>https://${HOST}.${DOMAIN}/</jenkinsUrl>
</jenkins.model.JenkinsLocationConfiguration>
EOF
# For completeness
cp /data/jenkins_home/jenkins.model.JenkinsLocationConfiguration.xml /var/lib/jenkins


# Create temporary admin user via templated groovy script
cd /tmp/config
sed "s/USERNAME/$JENKINS_USERNAME/g" .templates/basic-security.groovy.tmpl  | \
sed "s/PASSWORD/$JENKINS_PASSWORD/g"                                      > \
/data/jenkins_home/init.groovy.d/admin-user.groovy                          &&
chown jenkins:jenkins /data/jenkins_home/init.groovy.d/*.groovy

cat /data/jenkins_home/init.groovy.d/admin-user.groovy

# Disable LDAP authentication so we can bootstrap some jobs with local admin
# + enable CLI
echo "Listing current groovy scripts:"
ls -larth /data/jenkins_home/init.groovy.d/
rm /data/jenkins_home/init.groovy.d/*ldap-security.groovy
rm /data/jenkins_home/init.groovy.d/*security-configuration.groovy
ls -larth /data/jenkins_home/init.groovy.d/

# Restart Jenkins
restart_and_wait_for_jenkins

# Create bootstrap job created above
cd /tmp/config/gradle
gradle rest -DbaseUrl=http://localhost:8080 -Dpattern=jobs/bootstrap.groovy -Dusername=$JENKINS_USERNAME -Dpassword=$JENKINS_PASSWORD

# add install plugin job
gradle rest -DbaseUrl=http://localhost:8080 -Dpattern=jobs/installjobplugins.groovy -Dusername=$JENKINS_USERNAME -Dpassword=$JENKINS_PASSWORD

# add users update job
gradle rest -DbaseUrl=http://localhost:8080 -Dpattern=jobs/update-users.groovy -Dusername=$JENKINS_USERNAME -Dpassword=$JENKINS_PASSWORD

# Create maintenance jobs for test stack or housekeeping jobs for users stack
amiid=$(curl http://169.254.169.254/latest/meta-data/ami-id)
aminame=$(aws ec2 describe-images --image-ids "$amiid" --query 'Images[*].Name' --output text)

if [[ $aminame == *"build"* ]]; then
    gradle rest -DbaseUrl=http://localhost:8080 -Dpattern=jobs/maintenance.groovy -Dusername=$JENKINS_USERNAME -Dpassword=$JENKINS_PASSWORD
fi

gradle rest -DbaseUrl=http://localhost:8080 -Dpattern=jobs/housekeeping.groovy -Dusername=$JENKINS_USERNAME -Dpassword=$JENKINS_PASSWORD

# get jenkins-cli jar into temp dir and run housekeeping jobs
cd /tmp
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# asset team plugins installer
java -jar jenkins-cli.jar -s http://localhost:8080/ build -s --username $JENKINS_USERNAME --password $JENKINS_PASSWORD housekeeping-jobs/installjobplugins || true

# asset team access permissions udpater
java -jar jenkins-cli.jar -s http://localhost:8080/ build -s --username $JENKINS_USERNAME --password $JENKINS_PASSWORD housekeeping-jobs/update-users


# asset team jobs seeder
java -jar jenkins-cli.jar -s http://localhost:8080/ build -s --username $JENKINS_USERNAME --password $JENKINS_PASSWORD housekeeping-jobs/bootstrap || true

# asset team Route53 endpoint setup
java -jar jenkins-cli.jar -s http://localhost:8080/ build -s --username $JENKINS_USERNAME --password $JENKINS_PASSWORD housekeeping-jobs/route53-update || true


if [[ $aminame == *"build"* ]]; then
    #check if all above jobs are success before releasing ami
    /usr/local/bin/checkjobstatus.py -j 'housekeeping-jobs/job/update-users' -u "$JENKINS_USERNAME" -p "$JENKINS_PASSWORD"
    /usr/local/bin/checkjobstatus.py -j 'housekeeping-jobs/job/installjobplugins' -u "$JENKINS_USERNAME" -p "$JENKINS_PASSWORD"
    /usr/local/bin/checkjobstatus.py -j 'housekeeping-jobs/job/bootstrap' -u "$JENKINS_USERNAME" -p "$JENKINS_PASSWORD"
    /usr/local/bin/checkjobstatus.py -j 'housekeeping-jobs/job/route53-update' -u "$JENKINS_USERNAME" -p "$JENKINS_PASSWORD"
    cd /tmp
    # Release Current AMI to Tag Release
    java -jar jenkins-cli.jar -s http://localhost:8080/ build -f --username $JENKINS_USERNAME --password $JENKINS_PASSWORD maintenance-jobs/jenkins-release-ami
    # Cleanup Old AMI's with Tag Build
    java -jar jenkins-cli.jar -s http://localhost:8080/ build -f --username $JENKINS_USERNAME --password $JENKINS_PASSWORD maintenance-jobs/jenkins-ami-cleanup
fi

# Re-enable LDAP authentication, remove admin-user and disable CLI
rm /data/jenkins_home/init.groovy.d/admin-user.groovy
cp -r /tmp/config/init.groovy.d/* /data/jenkins_home/init.groovy.d
template=/data/jenkins_home/init.groovy.d/120-ldap-security.groovy
sed -i "s/LDAPUSERNAME/$LDAP_USERNAME/g" $template
/usr/local/bin/ssm-cred-helper.py -key $SSM_LDAP_PASSWORD -template $template -text LDAPPASSWORD

# Use Material Themes for differentiating nonprod and prod
cp /tmp/config/theme/$ENVIRONMENT/org.codefirst.SimpleThemeDecorator.xml /data/jenkins_home/

# Restart jenkins!
chown jenkins:jenkins /data/jenkins_home/init.groovy.d/*
restart_and_wait_for_jenkins

# Done!
echo 'Jenkins Bootstrap Complete!'
