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

set -x

BINDIR=$1
LICENSE_HEADER_CHECKER_VERSION=$2
LICENSE_HEADER_TEXT_FILE=$3
EXCLUDE_FOLDERS=$4

export BINDIR=$BINDIR

mkdir -p $BINDIR

curl -s https://raw.githubusercontent.com/lluissm/license-header-checker/master/install.sh | bash -s $LICENSE_HEADER_CHECKER_VERSION
result=$($BINDIR/license-header-checker -a -r -i $EXCLUDE_FOLDERS $LICENSE_HEADER_TEXT_FILE ./ yaml)

echo "$result"

replacedCount=$(echo "$result" | awk -F, '{print $2}' | sed 's/ licenses replaced//')
addedCount=$(echo "$result" | awk -F, '{print $3}' | sed 's/ licenses added//')

if [[ $replacedCount -ne 0 ]] || [[ $addedCount -ne 0 ]]
then 
    echo "$replacedCount files have licenses replaced"
    echo "$addedCount files have licenses added"
    exit 1
else 
    echo "license check is successful"
fi