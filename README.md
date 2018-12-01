# Jenkins

## Product Overview
The Jenkins product offered via this repository will provide a Jenkins master instance on Amazon EC2, implementing features described in the next section.

![alt text](images/SinatraLogo.png "Application and Cloud Platforms Jenkins Master Overview")
The supporting pattern is defined [here in Confluence](https://confluence.dss.ext.national.com.au/pages/viewpage.action?pageId=3891335)


### Features
Once built, Jenkins will come with the following features.

- Jenkins master created on EC2 instance in a AutoScaling Group and an ELB. This will ensure that an instance is always available.
- Route53 DNS A Record, updating the domain with the alias of ELB created.
- Authentication to NAB AD via a defined LDAP endpoint.
- Power management features built in.  Turned off after 7pm, restarted 7am and not run on the weekends.  This is configured via the AutoScaling LaunchConfiguration.
- [Built-in housekeeping jobs](docs/HOUSEKEEPING.md) to manage users, plugins and some system tasks.  [This file](https://github.aus.thenational.com/CENTRAL/jenkins/blob/master/config/plugins.txt) contains a list of pre-installed plugins.
- [Bootstrap configuration](docs/BOOTSTRAP_REPO.md) to automatically load end-user Jenkins jobs and configuration.
- SSL setup for all calls back to NAB with required certificates installed.
- Docker daemon installed so containerised builds can be run.
- Logs will be automatically published to CloudWatch, into a group created based on parameters entered.

**Limitations**
- No management of slaves; builds will run on the master.


## Launching Jenkins
Launching Jenkins requires a bit of setup work prior to actually creating the instance.  

### Pre-requistes 
At this stage, there are a number of manaual prerequisite steps needed prior to provisioning a Jenkins instance.  These are things like certificate creation,
creating the bootstrap respository, collection information required to launch the Jenkins product.

Follow this [step-by-step guide for meeting prerequisites](docs/PREREQS.md) before launching a Jenkins instance.  **Note**: Some of the steps will involved requests to IBM which can take days.


### Configuration Options and Parameters

When launching a Jenkins from the command line, there are a number of parameters required.  These will be populated
with values obtained, and items created whilst going through the prerequisite checklist.  

Further information on parameters and their values can be found [here](docs/CFN_PARAMS.md).


### How to launch a Jenkins instance
The repository provides two ways to launch a new Jenkins stack, one using `Ansible` and one using the `AWS CLI`.  Refer to [the prerequisites](docs/PREREQS.md) for details on how to obtain the AMI ID.

**Ansible**
1. Install Ansible on your build box, if it isn't already installed.
1. Create a parameters file for Ansible, simillar to [this example](https://github.aus.thenational.com/CENTRAL/jenkins-bootstrap-template/blob/master/template-ansible-params.yaml).
1. From the root of the Jenkins repo checkout, run the ansible playbook with parameters. 
   ```
   run_ansible.sh <path_to_config_file

   eg: run_ansible.sh ~/config/jenkins_ansible.yaml
   ```

**CloudFormation**
1. Create the Cloudformation parameters and tags files, using the data obtained from the prerequisite steps.  Template files are available, and all blank values must be provided.
   For additional information on passing parameters with CloudFormation, refer to [this AWS post](https://aws.amazon.com/blogs/devops/passing-parameters-to-cloudformation-stacks-with-the-aws-cli-and-powershell/)
   1. Parameters file: https://github.aus.thenational.com/CENTRAL/jenkins-bootstrap-template/blob/master/template-cloudformation-params.json
   1. Tags file: https://github.aus.thenational.com/CENTRAL/jenkins-bootstrap-template/blob/master/template-cloudformation-tags.json
1. From your build box, which must be configured with the correct instance profile, run the AWS CLI command from the root of the Jenkins rpeository you cloned earlier.
   ```
   aws cloudformation create-stack --stack-name my-jenkins --template-body file://cloudformation.yaml --parameters file:///some/local/path/params.json --tags file:///some/local/path/tags.json
   ```

## Upgrading Jenkins
New product versions will be published regularly when there is a new HIP AMI, a new Jenkins version or changes to the underlying Jenkins code.
This will result in a new AMI being built with the updates required.  

When applicable, you can run the `housekeeping/jenkins-rebase-latest` job to update the instance to the new AMI.  This will build a new instance from the latest AMI, add it to the ELB, and when it's
received a success signal, the old instance will be deleted.  If backups were taken, the latest backup will also be restored to the new instance from S3.



## Responsibilites and ownership
- ACP provides the ability to publish a pattern via the service catalog.  ACP will publish new product versions when a new HIP AMI is published, or when a new Jenkins version is available.
- You as the end user builds, owns and operates the service.  It will be your responsibility to ensure the service stays updated in line with NAB's security requirements.  

