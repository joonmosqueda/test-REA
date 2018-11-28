#!/usr/bin/env python
# options <type> <version>
from StringIO import StringIO
import requests
import argparse
from bs4 import BeautifulSoup
import sys, os
import yaml

url = 'https://patching-server-hui.ext.national.com.au/images/aws/'
cwd = os.getcwd()

def get_tag_hip_ami():
  with open('/etc/facter/facts.d/hui_original_ami_id.yaml', 'r') as stream:
    try:
        data = yaml.load(stream)
        return data['hui_original_ami_id']
    except yaml.YAMLError as exc:
        print(str(exc))

def get_args():
  try:
      parser = argparse.ArgumentParser()
      parser.add_argument("ostype", help="rhel, centos, ol are the current options - see " + url, default='rhel-7')
      parser.add_argument("version", help="5,6,7 - see " + url, default='7')
      args = parser.parse_args()
      ostype =  args.ostype
      version = args.version
      return ostype, version
  except:
      e = sys.exc_info()[0]
      print e

def get_latest_ami(url, ostype, version):
  try:
    r = requests.get(url+'/'+ostype+'/'+version+'/latest', verify=cwd+'/config/certs/nab.pem')
    latest_ami = BeautifulSoup(r.text.strip(), 'html.parser')
    return latest_ami
  except Exception as e:
      print str(e)
      #e = sys.exc_info()[0]

def get_instance_id():
  try:
    response = requests.get('http://169.254.169.254/latest/meta-data/instance-id')
    instance_id = response.text
    return instance_id
  except:
      e = sys.exc_info()[0]

def main():
  ostype,version = get_args()
  latest_ami = get_latest_ami(url,ostype,version)
  hip_ami = get_tag_hip_ami()
  if latest_ami != hip_ami:
    print "REBUILD;"+str(latest_ami)

main()
