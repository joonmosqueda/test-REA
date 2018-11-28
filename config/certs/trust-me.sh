#!/bin/bash

# USAGE
#
#   sudo ./trust-me.sh $JAVA_HOME
#
# DESCRIPTION
#
#   Automatically import NAB certificates into the java trust store.
#
# KNOWN USAGES
#
#   scripts/provision.sh
#
# AUTHOR
#
#    ?

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

TARGET=$JAVA_HOME
if [ "" != "$1" ]; then
    TARGET=$1
fi

SOURCE=${PWD}

if [ ! -d $TARGET/lib/security ]; then
    echo "Could not find directory $TARGET/lib/security"
    exit 1
fi

cd $TARGET/lib/security

echo "Installing certs in $(pwd)"
echo "Backing up cacerts"
cp -p cacerts cacerts.orig

for file in $SOURCE/*.pem; do
    BASE=$(basename $file)
    keytool -importcert -noprompt -file $file -alias "${BASE%.*}" -keystore cacerts -storepass changeit
done

#EOF
