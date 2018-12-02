# TEST-REA

## Product Overview
The TEST-REA product offered via this repository will provide a Simple Sinatra Web App stack on Amazon, implementing features described in the next section.

![alt text](images/SinatraLogo.png "Simple Sinatra Web App")

### Features
Once built, Simple Sinatra Web App Stack will come with the following features:

- Web App deployed on EC2 instance(s) in a AutoScaling Group and an ELB. This will ensure that an instance is always available.
- Route53 DNS A Record, updating the domain with the alias of ELB created.
- Logs will be automatically published to CloudWatch, into a group created based on parameters entered.

**Limitations**
- Using Amazon Linux 2 AMI (ami-08589eca6dcc9b39c); golden AMI should be provisioned for more stable deployments
- Amazon Linux 2 AMI have version dependent packages: ansible2; cloudwatch agent
- DNS record for a more readable URL pointing to ELB; currently using only ELB DNS endpoint

## Launching TEST-REA
Launching TEST-REA requires a bit of setup work prior to actually creating the instance.  

### Pre-requistes 
At this stage, there are a number of manaual prerequisite steps needed prior to provisioning a TEST-REA stack.  These are things like certificate creation, IAM policy in a role, and collection of information required to launch the product.

Follow this [step-by-step guide for meeting prerequisites](docs/PREREQS.md) before launching a TEST-REA stack.  

### Configuration Options and Parameters
When launching a TEST-REA from the command line, there are a number of parameters required.  These will be populated
with values obtained, and items created whilst going through the prerequisite checklist.  

Further information on parameters and their values can be found [here](docs/PARAMS.md).


### How to launch a TEST-REA stack
1. Install Ansible and AWS CLI on your build box, if it isn't already installed.
2. Create a parameters file for Ansible, simillar to [this example](templates/template-conf.yaml).
3. From the root of the TEST-REA repo checkout, run the ansible playbook with parameters. 
   ```
   run_ansible.sh <path_to_config_file>

   eg: ./run_ansible.sh ./test_conf.yaml
   ```

## Upgrading TEST-REA
Upgrade should be performed if a new golden AMI is built.  Running `run_ansible.sh` with updated parameter file will then need to be performed.

## Backup
As there is no data on the TEST-REA stack that will require restoration if lost, hence backup is not being considered.

## Responsibilites and ownership
- You as the end user builds, owns and operates the service.  It will be your responsibility to ensure the service stays updated in line with your security requirements.  

