def gitUrl = 'git@github.aus.thenational.com:ATDRP/jenkins.git'

folder('maintenance-jobs')

freeStyleJob('maintenance-jobs/jenkins-ami-cleanup') {
    description('Cleanup all the old ami builds based on tag details for the current account')
    scm {
        git {
            remote {
                url(gitUrl)
                credentials('svc-account')
            }
            branches('master')
        }
    }
    logRotator {
        numToKeep(3)
        artifactNumToKeep(2)
    }
    wrappers {
        timestamps()
    }
    steps {
        shell('./scripts/bootstrap/ami-cleanup.sh')
    }
}

pipelineJob('maintenance-jobs/packer-rebuild') {
    description('Rebake the jenkins master AMI based on any updates from the HIP url')
    parameters {
        choiceParam('OS', ['centos'], 'OS image for base ami')
        choiceParam('Version', ['5','6','7'], 'version of image')
    }
    logRotator {
        numToKeep(3)
        artifactNumToKeep(2)
    }
    definition {
        cps {
            sandbox()
            script("""
def amiid = ''
def bootstrapurl
stage('Checkout')
  {
    node
    {
      git credentialsId: 'svc-account', url: 'git@github.aus.thenational.com:ATDRP/jenkins.git'
    }
  }
  stage('Packer AMI Build')
  {
    node
    {
      sh './scripts/packer/build-packer-rebuild.sh \$OS \$Version'
      sleep 60
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
  stage('Get AMI Id')
  {
    node
    {
      amiid = sh(script: './scripts/bootstrap/latestami.sh test', returnStdout: true)
    }
  }
  
  stage('Create Test Stack')
  {
    node
    {
      sh '(source /etc/profile.d/proxy.sh ; ansible-playbook deploy.yaml --extra-vars \\'{"ami":"'+amiid+'","config_file":"jobs/spt-dfptest.yaml"}\\' -vvv)';
    }
  }
            """.stripIndent())
        }
    }
}

freeStyleJob('maintenance-jobs/jenkins-release-ami') {
    description('Rebake the jenkins master AMI based on any updates from the HIP url')
    scm {
        git {
           remote {
               url(gitUrl)
               credentials('svc-account')
           }
           branches('master')
        }
    }
    logRotator {
        numToKeep(3)
        artifactNumToKeep(2)
    }
    wrappers {
        timestamps()
    }
    steps {
        shell('./scripts/bootstrap/release-ami.sh')
    }
}

pipelineJob('maintenance-jobs/jenkins-publish-servicecatalog') {
    description('Add Jenkins to Service Catalog')
    parameters {
        stringParam('SCAccount', '', 'Service Catalog Account Number')
        stringParam('SCRole', '', 'Service Catalog Account Role')
    }
    logRotator {
        numToKeep(3)
        artifactNumToKeep(2)
    }
    definition {
        cps {
            sandbox()
            script("""
            stage('Checkout') {
                node {
                    deleteDir()  
                    git credentialsId: 'svc-account', url: 'git@github.aus.thenational.com:ATDRP/jenkins.git'
                }
            }
            stage('Service Catalog Product Publish') {
                node {
                    screlease = sh(script:'./scripts/bootstrap/release-ami-servicecatalog.sh \$SCAccount \$SCRole', returnStdout: true)
                }
            }
            """.stripIndent())
        }
    }
}
