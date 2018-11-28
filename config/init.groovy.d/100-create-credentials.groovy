import jenkins.*
import hudson.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*
import hudson.plugins.sshslaves.*;
import hudson.model.*
import jenkins.model.*
import hudson.security.*

  
String keyfile    = "/var/lib/jenkins/.ssh/id_rsa"
global_domain     = Domain.global()
credentials_store = Jenkins.instance.getExtensionList(
						'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
						)[0].getStore()
credentials       = new BasicSSHUserPrivateKey(
							CredentialsScope.GLOBAL,
							"svc-account",
							"svc-account",
 							new BasicSSHUserPrivateKey.FileOnMasterPrivateKeySource(keyfile),
							"",
							"Service Accounts private Github SSH key")

credentials_store.addCredentials(global_domain, credentials)