# TEST-REA Catalog Parameters

When spinning up TEST-REA stack, a number of pieces of information are required so that the instance can be customised for the team spinning up the product.

## Parameter details

`Owner`: Tag parameter. Name of Owner.  e.g.: "Joon Mosqueda"

`Name`: Tag parameter. Name of Stack.  e.g.: testREA

`TechnicalService`: Tag parameter. Service provided by stack.  e.g.: SimpleSinatraApp

`Environment`: Tag parameter.  Environment Label for stack.  e.g.: prod, nonprod, dev, qa

`KeyName`: EC2 Key pair for TEST-REA instance(s).

`VPC`: VPC hosting TEST-REA instance(s).

`Subnets`: Provide list of minimum 3 subnets in the VPC, one per availability zone.

`InstanceProfile`: IAM instance profile role used to access CloudWatch and S3.  e.g: "mjoonjoel_InstanceRole"

`InstanceType`: EC2 instance type to launch TEST-REA.  e.g.: "t2.micro".

`InstanceMinSize`: Minimum number of instances launched by ASG.  e.g.: "0"

`InstanceMaxSize`: Maximum number of instances launched by ASG.  e.g.: "3"

`InstanceDesiredCapacity`: Desired number of instances launched by ASG.  e.g.: "2"

`InternalCertificateId`: ARN of the SSL certificate uploaded to AWS IAM. e.g.: "arn:aws:iam::99999999999:server-certificate/wildcard_devops"

`AMI`: AMI ID used to launch EC2 instance.  e.g.: ami-08589eca6dcc9b39c

`InternalNetwork`: Network CIDR for secured access to web app.  e.g.: "0.0.0.0/0"

`ExternalNetwork`: Network CIDR for end users of web app.  e.g.:"0.0.0.0/0"

`GitRepo`: The URL for the web app repository.  e.g.: "https://github.com/rea-cruitment/simple-sinatra-app.git"

`GitBranch`: Git branch should to be used for simple sinatra app.  e.g.: "master".