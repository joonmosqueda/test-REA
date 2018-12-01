# TEST-REA Catalog Parameters

When spinning up TEST-REA stack, a number of pieces of information are required so that the instance can be customised for the team spinning up the product.

## Parameter details

`Owner`: "Joon Mosqueda"

`Name`: testREA

`TechnicalService`: SimpleSinatraApp

`Environment`: Environment Label for TEST-REA.  eg: prod, nonprod, dev, qa

`KeyName`: EC2 Key pair for TEST-REA instance(s).

`VPC`: VPC hosting TEST-REA instance(s).

`Subnets`: Provide list of minimum 3 subnets in the VPC, one per availability zone.

`InstanceType`: EC2 instance type to launch TEST-REA.  Default value is "t2.micro".

`InstanceMinSize`: "0"

`InstanceMaxSize`: "3"

`InstanceDesiredCapacity`: "2"

`InternalCertificateId`: ARN of the SSL certificate uploaded to AWS IAM. eg: "arn:aws:iam::99999999999:server-certificate/wildcard_devops"

`AMI`: ami-08589eca6dcc9b39c

`InternalNetwork`: "0.0.0.0/0"

`ExternalNetwork`: "0.0.0.0/0"

`GitRepo`: The URL for the bootstrap repository.  eg: "https://github.com/rea-cruitment/simple-sinatra-app.git"

`GitBranch`: Which Git branch should be used for simple sinatra app?  eg: "master".