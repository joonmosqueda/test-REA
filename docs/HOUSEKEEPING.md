# Built-in Housekeeping Jobs 

These jobs are created by default as part of Jenkins build.  They'll be in the `housekeeping-jobs` folder.

## bootstrap
Job which will refresh the end user's bootstrap repository and reload the Jenkins configuration.  Note: this won't update anything except 
anything defined in the Jenkinsfile.  Needs to be triggered manually as required.

## docker-cleanup
Cleans up docker containers.  This is a scheduled daily task.

## installjobplugins 
Adds any new plugins as defined in the bootstrap repository `plugins.txt`. Can be triggered manually as required.


## jenkins-rebase-latest 
Recreates itself, by taking a newly published AMI and updating the cloudformation stack. Any changes to the configuration will be applied, 
and backups, if configured,  restored from S3.  Note: this will remove any manual job configuration applied to the old Jenkins instance.

## route53-update 
This re-updates the DNS entry for the domain with the current ELB details.  Should not be required.

## safe-restart 
This triggers a safe restart of Jenkins.  This is needed after running the `update-users` job, as a restart is required for changes to `users.yaml` to take effect.

## update-users 
This will re-read the `users.yaml` file and apply updated user configuration.  The `safe-restart` job should be triggere after this is run.
