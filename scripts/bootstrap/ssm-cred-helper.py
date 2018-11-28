#!/usr/bin/env python
# options <type> <version>
import sys
import os
import yaml
import boto3
import botocore
import fileinput
import argparse
from botocore.exceptions import ClientError


def get_secret(key):
    try:
        client = boto3.client('ssm')
        response = client.get_parameter(
            Name=key,
            WithDecryption=True
        )
        return response['Parameter']['Value']
    except ClientError as ex:
        print "boto client error: % s" % ex
        sys.exit(1)


def process_args():
    try:
        parser = argparse.ArgumentParser()
        parser.add_argument(
            '-key', '--key',
            help="SSM key name to fetch value for",
            default="/path/key"
        )
        parser.add_argument(
            '-template', '--template',
            help="filename to replace the secret value from ssm",
            default="ldap.groovy"
        )
        parser.add_argument(
            '-text', '--text',
            help="text keyword in the template file to replace the value from ssm",
            default="LDAP_PASSWORD"
        )
        return parser.parse_args()
    except:
        e = sys.exc_info()[0]
        print e


def replace_secret(key, template, text):
    value = get_secret(key)
    # Read in the file
    with open(template, 'r') as file:
        filedata = file.read()
    # add escaping chars for \
    if template.endswith('.groovy'):
        value.replace('\\','\\\\')
    # Replace the target string
    filedata = filedata.replace(text, value)

    # Write the file out again
    with open(template, 'w') as file:
        file.write(filedata)


def main():
    args = process_args()
    ssmkeyname = args.key
    templatefile = args.template
    valuereplacementtext = args.text
    replace_secret(ssmkeyname, templatefile, valuereplacementtext)


if __name__ == "__main__":
    main()
