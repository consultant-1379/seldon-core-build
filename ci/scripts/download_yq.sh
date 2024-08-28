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

set -ex;

YQ_DOWNLOAD_URL="$1"

# Absolute filepath to this script
case "$(uname -s)" in
Darwin*) SCRIPT=$(greadlink -f $0) ;;
*) SCRIPT=$(readlink -f $0) ;;
esac

# Location of parent dir
BASE_DIR=$(dirname $SCRIPT)
REPOROOT=$(dirname $(dirname $BASE_DIR))
BIN_LOCATION="$REPOROOT/.bob/bin"
YQ_BINARY="${BIN_LOCATION}/yq"

mkdir -p $BIN_LOCATION

# Download yq   
wget "${YQ_DOWNLOAD_URL}" -O ${YQ_BINARY} && chmod +x ${YQ_BINARY}
