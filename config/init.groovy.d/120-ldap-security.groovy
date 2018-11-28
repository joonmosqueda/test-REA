import jenkins.*
import hudson.*
import hudson.model.*
import hudson.util.Secret
import jenkins.model.*
import hudson.security.*
import hudson.scm.*
import jenkins.security.plugins.ldap.*
import com.cloudbees.plugins.credentials.*


def instance = Jenkins.getInstance()

/*
LDAP Setup
http://javadoc.jenkins-ci.org/ldap/hudson/security/LDAPSecurityRealm.html#LDAPSecurityRealm
*/
String server              = 'ldaps://ldap.aur.national.com.au'
String rootDN              = 'ou=Production,dc=aur,dc=national,dc=com,dc=au'
String userSearchBase      = 'ou=Accounts'
String userSearch          = 'sAMAccountName={0}'
String groupSearchBase     = 'ou=Support Groups'
String groupSearchFilter   = 'sAMAccountName={0}'
LDAPGroupMembershipStrategy groupMembershipStrategy = new FromGroupSearchLDAPGroupMembershipStrategy()
String managerDN           = 'AUR\\LDAPUSERNAME' 
Secret managerPasswordSecret = Secret.fromString('LDAPPASSWORD') // TODO: must encrypt this
boolean inhibitInferRootDN = true
boolean disableMailAddressResolver = false
LDAPSecurityRealm.CacheConfiguration cache = new LDAPSecurityRealm.CacheConfiguration(100, 3600)
LDAPSecurityRealm.EnvironmentProperty[] environmentProperties = []
String displayNameAttributeName = 'displayname'
String mailAddressAttributeName = 'mail'
IdStrategy userIdStrategy  = new IdStrategy.CaseInsensitive()
IdStrategy groupIdStrategy = new IdStrategy.CaseInsensitive()
SecurityRealm ldap_realm   = new LDAPSecurityRealm(server,
	                                               rootDN,
	                                               userSearchBase,
	                                               userSearch,
	                                               groupSearchBase,
	                                               groupSearchFilter,
	                                               groupMembershipStrategy,
	                                               managerDN,
	                                               managerPasswordSecret,
	                                               inhibitInferRootDN,
	                                               disableMailAddressResolver,
	                                               cache,
	                                               environmentProperties,
	                                               displayNameAttributeName,
	                                               mailAddressAttributeName,
	                                               userIdStrategy,
	                                               groupIdStrategy)
instance.setSecurityRealm(ldap_realm)

/*
Matrix Based Permissions
*/
def strategy = new GlobalMatrixAuthorizationStrategy()

// Anonymous
// WARNING: It is not ideal that Anonymous has READ access but it is required for
//          job artefacts to be read from dependant jobs
strategy.add(Jenkins.READ, "anonymous")
strategy.add(Item.READ,    "anonymous")


instance.setAuthorizationStrategy(strategy)


// Save
instance.save()
