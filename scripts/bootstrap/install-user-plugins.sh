#!/bin/bash -eux

# USAGE
#
#   ./install-user-plugins.sh <path-to-plugins.txt>
#
# DESCRIPTION
#
#   Install Jenkins plugins.
#
#   Resolves dependencies and download plugins given on the command line
#
# KNOWN USAGES
#
#   Used by jenkins housekeeping jobs to install addtional plugins from users jobs repo
#
# AUTHOR
#
#    Jenkins <https://github.com/jenkinsci/docker/blob/master/install-plugins.sh>

pluginsfile=$WORKSPACE/$1
export JENKINS_UC=https://updates.jenkins.io
/usr/local/bin/install-plugins.sh $(sed -e :a -e '/$/N; s/\n/ /; ta' "$pluginsfile")

# Done!
echo "Installed Plugins! Need to Restart Jenkins"