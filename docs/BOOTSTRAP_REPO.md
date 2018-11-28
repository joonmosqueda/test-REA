# Jenkins Bootstrap Repository

## TL;DR;
- configuration is in a separate repository
  - Jenkinsfile to define jobs
  - users.yaml to manage users
  - plugins.txt to configure plugins
- all configuration as code
- you build it, own it


## Details

Part of the process of creating an instance involves configuration of the Jenkins instance using information provided by the end user.  This 
comes in the form of the `bootstrap repository` that contains:
- `Jenkinsfile`: that defines jobs
- `users.yaml`: to manage users
- `plugins.txt`: to manage plugins

It also assumes that all configuration for job definitions will be maintained as code, as this Jenkins setup will assume it is immutable.  Any
configuration not captured as code will need to be backed up (also a built-in function) so that the configuration and build history can
be restored onto the new instance.

**Note**: the `users.yaml` _must_ be updated with at least one user being given administrator privileges.  This is required 
so that the configured user can login to Jenkins once the instance is up and running.

### Setting up the Bootstrap Repository
A template repository has been created with the minimum setup requirements and an example Jenkinsfile that contains a single pipeline. 

Suggestion is to _fork_ [this](https://github.aus.thenational.com/CENTRAL/jenkins-bootstrap-template) repository into your 
organisation (don't clone it!) and add any required configuration.

### Updating Jobs
As the end users, you'll be responsible for creation and maintenance of all jobs in Jenkins, except for those default jobs provided..  
The example pipeline is written using the declarative Jenkins Syntax.  However, for more experienced maintainers, groovy is an option 
and you can script the pipeline code in `groovy`.
More information can be found here: https://jenkins.io/doc/book/pipeline/syntax/

Assuming the Jenkins instance has been set up, whenever jobs are created, updated or removed, by updating the code in the bootstrap repo,
you can apply those changes to the jenkins instance by navigating to `Jenkins|housekeeping-jobs|bootstrap`.  
This job will update it's copy of the repository, and process the Jenkinsfile to apply changes.


## Known Issues
- jobs won't be deleted once added to the Jenkins instance, even if removed from code.  Solution is to remove manually, or wait until the 
  Jenkins instance is rebuilt and refreshed from the bootstrap repo.
