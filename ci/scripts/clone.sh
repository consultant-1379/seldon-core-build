#!/usr/bin/env bash
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

set -eux -o pipefail

# Absolute filepath to this script
case "$(uname -s)" in
Darwin*) SCRIPT=$(greadlink -f $0) ;;
*) SCRIPT=$(readlink -f $0) ;;
esac

# Location of parent dir
BASE_DIR=$(dirname $SCRIPT)
REPOROOT=$(dirname $(dirname $BASE_DIR))

# Function usage() shows how to invoke this script
usage() {
  echo "usage: $0 -v RELEASE_TAG"
  exit 1
}

IS_SELDON=false

# parse input args
while [ $# -gt 0 ]; do
  case "$1" in
    --repoURL)
        REPO_URL="${2}"
        shift 2
      ;;
    --version|-v)
        RELEASE_TAG="${2}"
        shift 2
      ;;
    --clone-to)
        WORKSPACE="${2}"
        shift 2
      ;;
    --is-seldon)
        IS_SELDON="${2}"
        shift 2
      ;;
    *)
      usage
      ;;
  esac
done

# Function cleanup() cleans all temporary directories if they are available
cleanup() {
    TEMP_DIRS=(
        "${WORKSPACE}"
    )

    for temp_dir in "${TEMP_DIRS[@]}"
    do
      if [[ -d "${temp_dir}" ]]
      then
        rm -rf "${temp_dir}"
      fi
    done
}

copy_openapi(){
# Copy openapi spec to executor
mkdir -p ${WORKSPACE}/executor/api/rest/openapi/
cp  ${WORKSPACE}/openapi/swagger-ui/* ${WORKSPACE}/executor/api/rest/openapi/
cp  ${WORKSPACE}/openapi/engine.oas3.json ${WORKSPACE}/executor/api/rest/openapi/seldon.json
}

copy_operator_to_executor(){
# operator is required for building executor.  Following line is from makefile executor/Makefile target copy_operator
cp -r ${WORKSPACE}/operator ${WORKSPACE}/executor/_operator

}

# clean workspace if it already exists
cleanup

# clone Release tag version to workspace dir
git clone -b "${RELEASE_TAG}" --single-branch "${REPO_URL}" "${WORKSPACE}"

if [[ "${IS_SELDON}" == "true" ]]
then
  copy_openapi
  copy_operator_to_executor
fi
