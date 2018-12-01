# Pre-requistes

There are a number of manual prerequisite steps needed prior to provisioning a TEST-REA stack.

Required
1.  A build or jump box in the account in which the TEST-REA stack will be provisioned. Only required if there is a need to SSH onto the EC2 instance(s) and to and to fullfil some prerequisite steps.
2.  An EC2 KeyPair, used for SSH access to the EC2 instance(s).
3.  A Certificate for the TEST-REA stack, loaded into the ELB.
4.  Service account to connect to Github.
5.  An S3 bucket for backups, if configured.
6.  VPC and subnet details for the TEST-REA stack
7.  The AMI ID to use for building new TEST-REA EC2 instance(s).


## Build box/EC2 Instance
An ec2 instance, build box or jump box that has the same role you wish to use when creating the TEST-REA stack, or the ability to assume the required role..

If your account doesn't already have a build/jump box, you can create one using the AWS console, or running [this cloudformation template](templates\template-buildbox.yaml)

Once you've created your build box, create an ssh config and save your SSH keys for accessing GitHub repositories, so that you are able to clone the TEST-REA repository onto the buildbox.
1. Copy your SSH keys onto the build box so you can access GitHub. 
   If you need to set this up, refer to: https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/
   ```
   scp -i <buildbox_ssh_key> <path_to_your_keyfile> ec2-user@<buildbox_ip>:~/.ssh
   eg:
       scp -i buildbox_id_rsa ~/.ssh/id_rsa ec2-user@1.2.3.4:~/.ssh
   ```
2. Setup SSH Configuration - save this configuration in `~/.ssh/config`.  Doing this as the `ec2-user` should be sufficient.
   ```
   Host  github.com
   Hostname        github.com
   IdentityFile    ~/.ssh/<your_private_key>
   StrictHostKeyChecking no
   ```
3. Clone the TEST-REA repository
   ```
   https://github.com/joonmosqueda/test-REA.git
   ```


## EC2 KeyPair
An AWS KeyPair is required to be able to SSH into the TEST-REA instance(s) created.  Once created, it should be stored securely in a known location.  
If this key is lost, re-assigning the instance with a new key is not a trivial exercise and sometimes not possible.

To create an AWS KeyPair, there are 2 options:
1. Use the AWS Console.
   Navigate to EC2 | Key Pairs | Create Key Pair.  Enter a name and press Create.  Download and save the key.
2. Create a local key pair.
   1. On a linux commandline, execute this command and enter values for the prompts as required.  Save the files to a known location.  `ssh-keygen -t rsa -b 4096`
   2. Navigate to EC2 | Key Pairs | Import Key Pair.  Enter the public key details and a name, then press Import.
   3. Ensure the ssh key files are somewhere secure and in a known location.


## Certificates
Create an SSL certificate for the TEST-REA stack. This will be setup against the load balancer that sits in front of the web app.  


### Uploading the Certificate to AWS
A certificate is required for the ELB, so that SSL is used encrypt communication to/from TEST-REA stack.
With the certificate, the .pem file can't contain the same certificate that's in the .cer file. Generating from Venafi will provide the root and intermediate certificates.  
Generating from the command line will require you to find the root chain certificate for upload.

Below is the command that need to be run from the build box, assuming that the AWS ClI is available.

    ```bash
    aws iam upload-server-certificate --server-certificate-name <cert_name> --certificate-body <cert.cer> --private-key <cert.key> --certificate-chain <cert.pem>
    ```


## GitHub Service Accounts
A service account is required to access GitHub repositories.  Initially, it will be used to access the TEST-REA repository and any other repository.

1. Login to github with the service account once access has been granted.
2. Add SSH public key for GitHubService account in GitHub. 
   - Generate a set of SSH keys (`ssh-keygen -t rsa -b 4096 -f <filename>`)
   - Securely store the private key
   - Login to GitHub using service account credentials and add public key for the GitHub service account user. https://github.com/settings/ssh
3. Provide service account the required permissions to access the project and bootstrap repositories and the bootstrap repository.  This is done via the GitHub console, and is likely to be managed in a particular way for each team.


## S3 Bucket
To save backups, if configured, an S3 bucket should be created. 

### To create an S3 bucket:
1. Login to the AWS account, open S3.
2. Click `Create Bucket`
3. Enter a unique bucket name, and choose if you're copying settings from another bucket
4. Set required properties
5. Set required permissions
6. Review settings and click `Create bucket`.


## VPC and Subnets
To create a TEST-REA stack in a particular account, the CloudFormation template needs to know in which VPC and subnets it will be creating the instance.

To find the networking details:
1. Login to the AWS Console for the account in which TEST-REA stack will be created
2. Navigate to the `VPC` service, and list VPCs.  Note the ID of the VPC you need.
3. Navigate to `Subnets` and filter by the VPC ID you selected.  Take note of all the subnets listed for that VPC.

