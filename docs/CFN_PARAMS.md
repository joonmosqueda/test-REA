# Jenkins Service Catalog Parameters

When spinning up Jenkins, a number of pieces of information are required so that the instance can be customised for the asset team spinning up the product.

## Parameter details

`BackUpBucket`: Name of S3 bucket for storing backups.

`LogGroupName`: AWS Cloudwatch LogGroup to store log events.  AllowedValues are nonprod and prod.

`Environment`: Environment Label for Jenkins.  Default value is nonprod.

`Host`: Friendly Name for the Jenkins Server, eg: 'jenkins.assetteam.subdomain'

`Domain`: DNS domain for Jenkins URL.  Default value is "extnp.national.com.au".

`ZoneID`: Route53 Hostzone ID for DNS registration.  Default value is "Z3RQD0UV5PMRBG".

`GitBootstrapUrl`: The URL for the bootstrap repository.  eg: "git@github.aus.thenational.com:ORG/bootstrap-repo-name.git"

`GitBootstrapBranch`: Which Git branch should be used for Jenkins bootstrap?  Default value is "master".

`GitBootstrapJenkinsfile`: Name of the Jenkinfile within your bootstrap repository.  Default value is "Jenkinsfile".

`LDAPUsername`: AUR Service account for Jenkins LDAP integration/authentication.  eg: "srv_my_service_acc"

`GitHubUsername`: AUR Service account for to enable Jenkins to access the bootstrap and other GitHib repositories.  eg: "srv_github_acct"

`Route53Profile`: AWS IAM role for Route53 DNS record updates. The value for this will be provided by HIP in the handover document for the asset account.  eg: "arn:aws:iam::803264201466:role/HIPExtNpRoute53UpdateRole".

`KeyName`: EC2 Key pair for Jenkins instance.

`VPC`: VPC hosting Jenkins instance.

`Subnets`: Provide list of minimum 3 subnets in the VPC, one per availability zone.

`InstanceType`: EC2 instance type to launch Jenkins.  Default value is "t2.medium".

`InstanceProfile`: EC2 instance profile for Jenkins server.  eg: "TeamProvisioningInstanceProfile".

`SSMGITSSHKey`: AWS SSM Parameter Name with SSH key for the GitHub service account.

`SSMLDAPPassword`: AWS SSM Parameter Name with password for LDAP User service account

`InternalCertificateId`: ARN of the SSL certificate uploaded to AWS IAM. eg: "arn:aws:iam::364551985492:server-certificate/wildcard_didevops"

`EnableBackups`: Do you need backups of Jenkins configuration, and job history?  Default value is "true".  Allowed values are "true" or "false".
