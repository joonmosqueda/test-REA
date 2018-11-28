def gitUrl = 'git@github.aus.thenational.com:ATDRP/jenkins.git'
def gitBranch = 'master'

folder('housekeeping-jobs')

freeStyleJob('housekeeping-jobs/docker-cleanup') {
    description('Cleanup old docker images/containers')
    logRotator {
        numToKeep(3)
        artifactNumToKeep(2)
    }
    wrappers {
        timestamps()
    }
    triggers {
        cron('@daily')
    }
    steps {
        shell('docker system prune -f')
    }
}

pipelineJob('housekeeping-jobs/safe-restart') {
    description('Restart jenkins when free')
    logRotator {
        numToKeep(3)
        artifactNumToKeep(2)
    }
    definition {
        cps {
            sandbox(false)
            script("""
            import hudson.model.*;
            Hudson.instance.doSafeRestart(null);
            """.stripIndent())
        }    
    }
}

pipelineJob('housekeeping-jobs/jenkins-rebase-latest') {
    description('Rebase jenkins from latest ami')
    parameters {
        stringParam('configFileName', '', 'Enter the name of configFile in Bootstrap Repo to build stack')
        stringParam('AMIID', 'latest', 'Enter the ami id to be used for creating the stack')
    }
    logRotator {
        numToKeep(3)
        artifactNumToKeep(2)
    }
    definition {
        cps {
            sandbox()
            script("""
                def bootstrapurl
                def amiid = ''     
                stage('Checkout') {
                    node {
                        git credentialsId: 'svc-account', url: 'git@github.aus.thenational.com:ATDRP/jenkins.git'
                    }
                }
                stage('Get AMI Id') {
                    if (AMIID == 'latest') {
                        node {
                            amiid = sh(script: './scripts/bootstrap/latestami.sh', returnStdout: true)
                        }
                    } else {
                        amiid = AMIID
                    } 
                }
                stage('Checkout Jobs Repo')
                {
                    node
                    {
                    dir('jobs') {
                        bootstrapurl = sh(script:'. /etc/profile.d/cloud-environment.sh; echo \$GIT_BOOTSTRAP_URL', returnStdout: true)
                        git credentialsId: 'svc-account', url: bootstrapurl
                    }
                    }
                }  
                stage('Create or Update Stack') {
                    node {
                        sh '(source /etc/profile.d/proxy.sh ; ansible-playbook deploy.yaml --extra-vars \\'{"ami":"'+amiid+'","config_file":"jobs/'+params.configFileName+'"}\\' -vvv)';
                    }
                }
            """.stripIndent())
        }
    }
}

freeStyleJob('housekeeping-jobs/route53-update') {
    description('Update jenkins elb dns name of this stack to route53 endpoint')
    scm {
        git {
            remote {
                url(gitUrl)
                credentials('svc-account')
            }
            branches(gitBranch)
        }
    }
    wrappers {
        timestamps()
    }
    steps {
        shell('./scripts/bootstrap/Route53toELB.sh')
    }
}
