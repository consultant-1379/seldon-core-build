#
# COPYRIGHT Ericsson 2022
#
#
#
# The copyright to the computer program(s) herein is the property of
#
# Ericsson Inc. The programs may be used and/or copied only with written
#
# permission from Ericsson Inc. or in accordance with the terms and
#
# conditions stipulated in the agreement/contract under which the
#
# program(s) have been supplied.
#

#! /usr/bin/env bash

REPOSITORY_URL=""
PACKAGE=""
VERSION=""
TARGET_DIR=""
FILE_NAME=""

while [ "$#" -gt 0 ]
do
    case $1 in
        -r|--repository) REPOSITORY_URL="$2"; shift;;
        -p|--package) PACKAGE="$2"; shift;;
        -v|--version) VERSION="$2"; shift;;
        -d|--target-dir) TARGET_DIR="$2"; shift;;
        -f|--file-name) FILE_NAME="$2"; shift;;
    esac
    shift
done

cd "$TARGET_DIR" && \
curl -O -H "X-JFrog-Art-Api: ${ARM_API_TOKEN}" "$REPOSITORY_URL/$PACKAGE/$VERSION/$FILE_NAME" && \
tar xvf "$FILE_NAME" && \
rm "$FILE_NAME"