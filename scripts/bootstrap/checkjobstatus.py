#!/usr/bin/python

import json
import sys
import urllib
import urllib2
import argparse
import base64

jenkinsUrl = "http://localhost:8080/job/"


def process_args():
    try:
        parser = argparse.ArgumentParser()
        parser.add_argument(
            '-j', '--jobname',
            help="Job Name to check build status",
            default="test-stack"
        )
        parser.add_argument(
            '-u', '--username',
            help="User Name to login to jenkins",
            default="test-lambda-stack"
        )
        parser.add_argument(
            '-p', '--password',
            help="Password to login to jenkins",
            default="test-lambda-stack"
        )
        return parser.parse_args()
    except:
        e = sys.exc_info()[0]
        print e


def main():
    args = process_args()
    jobname = args.jobname
    username = args.username
    password = args.password
    if len(jobname) > 1:
        joburl = urllib.quote(jobname)
    else:
        sys.exit(1)
    try:
        print jenkinsUrl + joburl + "/lastBuild/api/json"
        request = urllib2.Request(
            jenkinsUrl + joburl + "/lastBuild/api/json")
        base64string = base64.encodestring(
            '%s:%s' % (username, password)).replace('\n', '')
        request.add_header("Authorization", "Basic %s" % base64string)
        result = urllib2.urlopen(request)
    except urllib2.HTTPError, e:
        print "URL Error: " + str(e.code)
        print "      (job name [" + jobname + "] probably wrong)"
        sys.exit(2)
    try:
        buildout = json.load(result)
    except:
        print "Failed to parse json"
        sys.exit(3)
    if buildout.has_key("result"):
        print "[" + jobname + "] build status: " + buildout["result"]
    if buildout["result"] != "SUCCESS":
        sys.exit(4)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
