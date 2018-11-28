#!/bin/bash

ASSET=$1
SUBDOMAIN=$2
ENVIRONMENT=$3
NONPROD_DOMAIN=extnp.national.com.au
PROD_DOMAIN=ext.national.com.au

if [[ -z $ASSET ]] ; then
    echo "Expected Asset name to be provided"
    exit 1 
fi
if [[ -z $SUBDOMAIN ]] ; then
    echo "Expected subdomain name to be provided"
    exit 1 
fi
if [[ -z $ENVIRONMENT ]] ; then
    echo "Expected environment to be provided"
    exit 1 
fi
if [[ $ENVIRONMENT != "nonprod" ]] && [[ $ENVIRONMENT != "prod" ]] ; then
    echo "Expected an environment value of prod | nonprod"
    exit 1
fi

# Create non-prod CSR
if [[ $ENVIRONMENT == "nonprod" ]] ; then
    echo "Generating non-prod CSR"
    NONPROD_JENKINS=jenkins.$ASSET.$SUBDOMAIN.$NONPROD_DOMAIN
    openssl genrsa -out ${NONPROD_JENKINS}.key 2048 2048
    openssl req -new -sha256 -key ${NONPROD_JENKINS}.key -out ${NONPROD_JENKINS}.csr
fi

# Create production CSR
if [[ $ENVIRONMENT == "prod" ]] ; then
    echo "Generating production CSR"
    PROD_JENKINS=jenkins-prod.$ASSET.$SUBDOMAIN.$PROD_DOMAIN
    openssl genrsa -out ${PROD_JENKINS}.key 2048 2048
    openssl req -new -sha256 -key ${PROD_JENKINS}.key -out ${PROD_JENKINS}.csr
fi
