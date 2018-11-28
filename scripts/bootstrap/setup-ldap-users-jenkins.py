#!/usr/bin/env python

import yaml
import os
import sys
from os import path
import ConfigParser
import argparse


def process_args(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-f', '--file',
        help="file location",
        required="True"
    )
    return parser.parse_args()


args = process_args(sys.argv)

with open(args.file, 'r') as stream:
    try:
        data = yaml.load(stream)
    except yaml.YAMLError as exc:
        print(exc)

sys.stdout = open(
    "/data/jenkins_home/init.groovy.d/200-ldap-security-extras.groovy", "w")
print("import jenkins.*")
print("import hudson.model.*")
print("import hudson.util.Secret")
print("import jenkins.model.*")
print("import hudson.security.*")
print("def instance = Jenkins.getInstance()")
print("def strategy = new GlobalMatrixAuthorizationStrategy()")
for privilege in data.keys():
    for user in data[privilege]:
        print("strategy.add(Jenkins." + privilege +
              ", \"" + user['id'] + "\") //" + user['name'])
print("strategy.add(Jenkins.READ, \"anonymous\")")
print("strategy.add(Item.READ,    \"anonymous\")")
print("instance.setAuthorizationStrategy(strategy)")

print("instance.save()")
sys.stdout.close()
