# Pre-requistes

There are a number of manaual prerequisite steps needed prior to provisioning a Jenkins instance.

Required
1. A build or jump box in the account in which the Jenkins instance will be provisioned. Only required if there is a 
   need to SSH onto the Jenkins instance and to and to fullfil some prerequisite steps.
1. An EC2 KeyPair, used for SSH access to the Jenkins instance.
1. A KMS Key to use for encrypting data in SSM Parameter Store
1. A Certificate for the Jenkins instance, loaded into the ELB.
1. A service account to bind with LDAP for authentication.
1. Service account to connect to Github.
1. Service accounts to connect to Artifactory.
1. An S3 bucket for jenkins backups, if configured.
1. Bootstrap repository
1. VPC and subnet details for the jenkins master
1. The AMI ID to use for building this new Jenkins instance.
1. Credentials added to AWS Parameter Store


## Build box/EC2 Instance
An ec2 instance, build box or jump box that has the same role you wish to use when creating the Jenkins instance, or the ability to assume the required role..

If your account doesn't already have a build/jump box, you can create one using the AWS console, or running [this cloudformation template](https://github.aus.thenational.com/CENTRAL/jenkins/tree/master/templates/buildbox.yaml)

Once you've created your build box, create an ssh config and save your SSH keys for accessing GitHub repositories, so that you are able to clone the jenkins repository onto the buildbox.
1. Copy your SSH keys onto the build box so you can access GitHub.  This assumes you already have an SSH keypair configured in GitHub for your p number. 
   If you need to set this up, refer to: https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/
   ```
   scp -i <buildbox_ssh_key> <path_to_your_keyfile> ec2-user@<buildbox_ip>:~/.ssh
   eg:
       scp -i buildbox_id_rsa ~/.ssh/id_rsa ec2-user@1.2.3.4:~/.ssh
   ```
1. Setup SSH Configuration - save this configuration in `~/.ssh/config`.  Doing this as the `ec2-user` should be sufficient.
   ```
   Host  github.aus.thenational.com
   Hostname        github.aus.thenational.com
   IdentityFile    ~/.ssh/<your_private_key>
   StrictHostKeyChecking no
   ```
1. Clone the Jenkins repository
   ```
   git@github.aus.thenational.com:ATDRP/jenkins.git
   ```


## EC2 KeyPair
An AWS KeyPair is required to be able to SSH into the Jenkins instance created.  Once created, it should be stored securely in a known location.  
If this key is lost, re-assigning the instance with a new key is not a trivial exercise and sometimes not possible.

To create an AWS KeyPair, there are 2 options:
1. Use the AWS Console.
   Navigate to EC2 | Key Pairs | Create Key Pair.  Enter a name and press Create.  Download and save the key.
1. Create a local key pair.
   1. On a linux commandline, execute this command and enter values for the prompts as required.  Save the files to a known location.  `ssh-keygen -t rsa -b 4096`
   1. Navigate to EC2 | Key Pairs | Import Key Pair.  Enter the public key details and a name, then press Import.
   1. Ensure the ssh key files are somewhere secure and in a known location.


## KMS Encryption Key
A KMS Key is required to encrypt data that we'll be adding into the AWS SSM Parameter Store.  Sensitive data such as passwords, SSH keys and the like will be added.

To create a KMS Key:
1. Login to the AWS Console for the account in which you'll be creating the Jenkins instance.
1. Navigate to IAM | Encryption Keys
1. Choose the `Asia Pacific (Sydney)` region from the dropdown
1. Click the `Create Key` button, and enter details as required.
   - enter Alias and Description
   - add Tags
   - select the IAM role that will need access to manage the key (optional)
   - select the IAM role that will need to access the key in order to encrypt/decrypt data.  This will be the IAM role that is used to provision the Jenkins instance.
   - review the resulting policy and click `Finish` to create the key.


## Certificates
Create an SSL certificate for the Jenkins master. This will be setup against the load balancer that sits in front of Jenkins.  
There naming standards for Jenkins instances are: `jenkins.<asset>.<subdomain>.<domain>` e.g. `jenkins.nablabstest.nablabs.extnp.national.com.au`

Note: This format meets the HIP naming standards, and includes the asset subdomain.

NAB uses the Venafi platform to generate certificates.
1. Create the Certificate Request.  The steps below will generate a request for both prod and nonprod.
   Using this script [from the Jenkins repository,](https://github.aus.thenational.com/CENTRAL/jenkins/blob/master/scripts/prerequisites/generate-csr.sh), run as follow and enter required data at the prompts.
   ```
   ./generate-csr.sh <asset> <subdomain> <environment>

   eg: ./generate-csr.sh dfptest dfp nonprod
   ```

1. Using the Venafi Service to request a certificate
   1. Login to [Venafi](https://aupr2ap296nabwi.bas.aur.national.com.au/aperture/certificates/) with your AUR credentials.
   1. Naviate to Inventory | Certificates | Create New Certificate
   1. Enter the following parameters:
      - Certificate Folder: `Policy \ Banking Products \ Internal`
      - Nickname: `<certificate common name>`
      - Description: something to describe the certificate
      - Contacts: add your team's AD group name or your p number
      - Production Certificate: yes | no
      - Ownership validation: yes
      - NAB Requestor Email: enter your email
      - Business Application: choose the business application applicable to you.  This is tied to a Remedy group.
      - Remedy Group Email: check that this is correct.
      - Click `Next` to go to the CSR tab.  Paste the contents of the CSR you generated.
      - Click `Submit` to create the certificate.  You'll receive an email once the certificate is available.  At this point, you can login to Venafi and download the certificate.


### Uploading the Certificate to AWS
A certificate is required for the ELB, so that SSL is used encrypt communication to/from Jenkins.
With the certificate, the .pem file can't contain the same certificate that's in the .cer file. Generating from Venafi will provide the root and intermediate certificates.  
Generating from the command line will require you to find the root chain certificate for upload.

At this point in time, use of AWS Certificate Manager has not been CSAMed by HIP/Security, so the only option available is to upload to IAM.

There are 2 upload options available, both need to be run from the build box, assuming that the AWS ClI is available.
1. Command line
    ```bash
    aws iam upload-server-certificate --server-certificate-name <cert_name> --certificate-body <cert.cer> --private-key <cert.key> --certificate-chain <cert.pem>
    ```
1. Run a script from the command line.  This is [found in the Jenkins repository](https://github.aus.thenational.com/CENTRAL/jenkins/blob/master/scripts/prerequisites/upload-server-cert.sh).
    ```bash
    ./upload-server-cert.sh <cert file> <key file> <cert chain> <assumed role ARN> <cert name>
    ```

## Requesting a Service Account
Requesting a service account is at present, a painful, long process.  Expect this to take at least 5 working days.  
**Note**: If you find you have received a password with either a `/` or `#` in it, this can break the authentication.  
Solution is to call IBM to reset this password, however, they generally refuse to do this without an argument.

1. Go to the [IBM Self Service Portal](go/maximo), using IE.  Doesn't work with other browsers.
1. Select `Privileged Access Add Modify Delete`
1. Follow the inputs on this screenshot - https://confluence.dss.ext.national.com.au/display/DANT/How+to+request+a+Service+Account
   1. When selecting the environment, choose `PROD`.  Even though this might be created for a nonprod enviroment, `PROD` in this context means the `AUR` Active Directory Domain.
   1. [Use the guide here](https://confluence.dss.ext.national.com.au/display/SIO/How+to+Find+a+Technical+Service+Owner) when you're at the field requiring a Technical Service Owner.


## LDAP Service Account
Create a service account (as per above) that is able to be used for user/group searches in LDAP.  No special permissions are required.
The password for this service account will need to be stored in AWS SSM Parameter Store as a secure string.  Refer to the section below for details.


## GitHub Service Accounts
A service account is required for Jenkins to access GitHub repositories.  Initially, it will be to access the bootstrap repository and any other repository for which jobs have been configured.

1. Request a service account as described above.
1. Add your GitHub Service account to GitHub once created. This can be done by raising a Jira ticket in the `DOBAU` project, requesting that your service account be granted access to GitHub.
1. Login to github with the service account once access has been granted.
1. Add SSH public key for GitHubService account in GitHub. 
   - Generate a set of SSH keys (`ssh-keygen -t rsa -b 4096 -f <filename>`)
   - Securely store the private key
   - Login to GitHub using service account credentials and add public key for the GitHub service account user. https://github.aus.thenational.com/settings/ssh
1. Provide service account the required permissions to access the project and bootstrap repositories and the bootstrap repository.  This is done via the GitHub console, and is likely to be managed in a particular way for each team.
1. Store the GitHub SSH Private Key in AWS SSM Parameter Store.  Refer to the section below for details.

    
## Artifactory Service Accounts
Whilst setting up a new Jenkins, it's probably worth setting up Artifactory access from Jenkins, with service accounts.  This step is optional if you don't need Artifactory or already have this set up.

At present, NAB requires 2 repositories to be set up within Artifactory, one each for `BUILD` and `RELEASE`.  A service account corresponding to each of these repositories will also be required.

1. Create two Service Accounts for build/CI, verify and release activities e.g. `srv-asset-build` and `srv-asset-release`.  
   These map to the Artifactory repository roles.  Refer to the section above for details on service account creation.
1. Create a repository in Artifactory, using "generic" layout.  To create the repository, visit http://go/devopsportal | Repository Creation, entering parameters:
   - Asset ID: <your asset name>
   - Package Type: 'generic' (should suit most cases, but maven is generally accepted for development projects)
   - Email address: your email address.  Once the repo creation process runs, you'll receive an email to provide a status update.
   - Asset owner: Choose the relevant approver from the list.
   - Click `Submit for Approval`

   This will create three repositories named `<asset>-build`, `<asset>-verify` and `<asset>-release`.

1. Create the association between the Artifactory repositories and the service accounts.  **Note**: this can only be done once the service accounts and the Artifactory repository has been created.
   Execute the following steps once for each artifactory service account user, mapping them to the repository they'll provide access to.

   Create a new user in Artifactory, via http://go/devopsportal | Grant Service Account Access, enter parameters:
   - Username: name of the service account
   - Asset ID: name of the Asset ID provided when creating the repository
   - Access Role: Choose Build or Release
   - Email address: your email address.  Once the user creation process runs, you'll receive an email to provide a status update.
   - Asset owner: Choose the relevant approver from the list.


## S3 Bucket
To save backups, if configured, an S3 bucket should be created.  The backup process will write jobs, Jenkins configuration and build history to the backup bucket.

To create an S3 bucket:
1. Login to the AWS account, open S3.
1. Click `Create Bucket`
1. Enter a unique bucket name, and choose if you're copying settings from another bucket
1. Set required properties
1. Set required permissions
1. Review settings and click `Create bucket`.


## Create a Bootstrap Repository
A bootstrap repositiry is required, with configuration that will be used to create the Jenkins instance.
Refer to the [Jenkins Bootstrap Repository](BOOTSTRAP_REPO.md) for details.


## VPC and Subnets
To create a Jenkins instance in a particular account, the CloudFormation template needs to know in which VPC and subnets it will be creating the instance.

To find the networking details:
1. Login to the AWS Console for the account in which Jenkins will be created
1. Navigate to the `VPC` service, and list VPCs.  Note the ID of the VPC you need.
1. Navigate to `Subnets` and filter by the VPC ID you selected.  Take note of all the subnets listed for that VPC.


## Identify the latest Jenkins AMI ID
When creating the instance, we need to provide an AMI ID for Jenkins to be built upon.  
This can be found by running the [latestami.sh](https://github.aus.thenational.com/CENTRAL/jenkins/blob/master/scripts/bootstrap/latestami.sh) script
on the buildbox.
Run this script and take note of the AMI ID.
```
scripts/bootstrap/latestami.sh
```

Take note of the AMI ID returned.

## AWS SSM Parameter Store 
The AWS Parameter Store is used to store sensitive data and secrets. For the Jenkins build, we need to store the LDAP User's password and the GitHub SSH Private Key.
The next steps assume that the KMS Key has been created as described in the section above.

Encrypt and store passwords for the LDAP Service Account user and the private key for the GitHub Service Account.  
You may also want to encrypt API keys such as artifactory API tokens, Akamai keys etc.
Refer https://docs.aws.amazon.com/cli/latest/reference/ssm/put-parameter.html to add secrets to parameter store.  

The steps described to add parameters should be executed from the build box.  

1. Adding LDAP Password. This is the password for the LDAP User service account that was setup earlier.
```
aws ssm put-parameter --name /<asset>/<parameter_path> --value "Secret" --type SecureString --key-id alias/kmskey

eg:
    aws ssm put-parameter --name /dfp/ldap/password --value "Secret" --type SecureString --key-id alias/kmskey
```

1. Adding GitHub SSH Private Key.  **Note**: the key can't be uploaded via the console due to a bug where the newlines are not preserved, thus rendering the key useless.
```
aws ssm put-parameter --name /<asset>/<parameter_path> --value "$value" --type SecureString --key-id alias/kmskey

eg:
    value=$(cat ~/.ssh/id_rsa) 
    aws ssm put-parameter --name /dfp/git/sshkey --value "$value" --type SecureString --key-id alias/kmskey
```

