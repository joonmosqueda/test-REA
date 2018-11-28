# add the following to the environment on the user data
``` bash
export JENKINS_UC=https://updates.jenkins.io
```
# add the following under /usr/local/bin and make it executable
``` bash
jenkins-support
```
# add the following in the path and run it as follows; 
``` bash
./install-plugins.sh ldap
```
# where the ldap plugin will pull down the latest - if a version is needed - ldap:20.010.0

- note this is assumed that the jenkins war file is under - /usr/lib/jenkins/jenkins.war, if not, change the install-plugins.sh to solve this.

- push these over to your s3 buckets to be pulled from and used in the userdata

# Running the stack

```
cfndsl  -y cf/labs.yaml -p cf/jenkins.rb --disable-binding  > cf/jenkins.json
aws cloudformation create-stack --stack-name nab-labs-jenkins-scnonprod  --template-body file://cf/jenkins.json
```