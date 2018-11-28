#!/bin/bash

# USAGE
#
#   ./update-users.sh
#
# DESCRIPTION
#
#   Automatically updates users defined in the users.yaml file
#
#   Requires the following environment variables which are
#   sourced from cloud-environment:
#
#      - GIT_BOOTSTRAP_URL - URL to fetch list of jobs
#
# KNOWN USAGES
#
#   None
#
# AUTHOR
#
#    Josie Gioffre Dean

# Restart Jenkins and wait
USERS_FILE=$WORKSPACE/$1

echo "Adding users defined"
cat $USERS_FILE

# Create user-defined administrators.  Pulling data from the latest repo checkout, so it's updated whenever update-users job runs.
# This location will exist since we're doing this after invocation of the bootstrap job
/usr/local/bin/setup-ldap-users-jenkins.py --file $USERS_FILE

# Startup Jenkins with our new users!
chown jenkins:jenkins /data/jenkins_home/init.groovy.d/*
# Done!

echo "Users updated!"

