#! /usr/bin/env bash

set -x;

MODEL_LCM_PATH="$1"
SELDON_IMAGE_FULL_NAME_PREFIX="$2"
NON_SELDON_IMAGE_FULL_NAME_PREFIX="$3"

# Absolute filepath to this script
case "$(uname -s)" in
Darwin*) SCRIPT=$(greadlink -f $0) ;;
*) SCRIPT=$(readlink -f $0) ;;
esac

# Location of parent dir
BASE_DIR=$(dirname $SCRIPT)
REPOROOT=$(dirname $(dirname $BASE_DIR))
YQ_BINARY="${REPOROOT}/.bob/bin/yq"
PRODUCT_INFO_FILE="charts/eric-aiml-model-lcm/eric-product-info.yaml"
FOSSA_CONFIG_DIR="$REPOROOT/config/fossa"
MODEL_LCM_FOSSA_CONFIG_DIR="config/fossa"

# derive 
dockerRegistry=$(echo $SELDON_IMAGE_FULL_NAME_PREFIX | awk -F/ '{print $1}')  ## not used
seldonImageRepo=$(echo $SELDON_IMAGE_FULL_NAME_PREFIX | awk -F/ '{print $2}')
seldonImageNamePrefix=$(echo $SELDON_IMAGE_FULL_NAME_PREFIX | awk -F/ '{print $3}' | awk -F: '{print $1}')
seldonImageVersion=$(echo $SELDON_IMAGE_FULL_NAME_PREFIX | awk -F/ '{print $3}' | awk -F: '{print $2}')
nonSeldonImageNamePrefix=$(echo $NON_SELDON_IMAGE_FULL_NAME_PREFIX | awk -F/ '{print $3}' | awk -F: '{print $1}')

imageIds=( operator executor )

filesToSync=()

for imageId in "${imageIds[@]}"
do 
    echo "Updating seldon-${imageId} image to ${SELDON_IMAGE_FULL_NAME_PREFIX}"
    echo "Set seldon-${imageId} docker repo to ${seldonImageRepo}"
    image=$seldonImageNamePrefix-${imageId} repoPath=$seldonImageRepo $YQ_BINARY e -i '.images[env(image)].repoPath = env(repoPath)' "${MODEL_LCM_PATH}/$PRODUCT_INFO_FILE"
    echo "Set seldon-${imageId} docker image version to ${seldonImageVersion}"
    image=$seldonImageNamePrefix-${imageId} tag=$seldonImageVersion $YQ_BINARY e -i '.images[env(image)].tag = env(tag)' "${MODEL_LCM_PATH}/$PRODUCT_INFO_FILE"
    filesToSync+=("dependencies.seldon-${imageId}.yaml"  "foss.usage.seldon-${imageId}.yaml" "license-agreement-seldon-${imageId}.json")
done

nonSeldonImageIds=( python-base )
pythonBaseImageName="${nonSeldonImageNamePrefix}-python-base"

for imageId in "${nonSeldonImageIds[@]}"
do 
    echo "Updating ${imageId} image to ${NON_SELDON_IMAGE_FULL_NAME_PREFIX}"
    echo "Set ${imageId} docker repo to ${seldonImageRepo}"
    image=$nonSeldonImageNamePrefix-${imageId} repoPath=$seldonImageRepo $YQ_BINARY e -i '.images[env(image)].repoPath = env(repoPath)' "${MODEL_LCM_PATH}/$PRODUCT_INFO_FILE"
    echo "Set ${imageId} docker image version to ${seldonImageVersion}"
    image=$nonSeldonImageNamePrefix-${imageId} tag=$seldonImageVersion $YQ_BINARY e -i '.images[env(image)].tag = env(tag)' "${MODEL_LCM_PATH}/$PRODUCT_INFO_FILE"
    echo "Set ${imageId} docker image name to ${pythonBaseImageName}"
    image=$nonSeldonImageNamePrefix-${imageId} name=$pythonBaseImageName $YQ_BINARY e -i '.images[env(image)].name = env(name)' "${MODEL_LCM_PATH}/$PRODUCT_INFO_FILE"
    filesToSync+=("dependencies.seldon-${imageId}.yaml"  "foss.usage.seldon-${imageId}.yaml" "license-agreement-seldon-${imageId}.json")
done

changedFiles=($PRODUCT_INFO_FILE)

# Add new line after license header. It is lost due to yq manipulation
sed -i '/^productName:.*/i \ ' .bob/tmp/eric-product-info.yaml "${MODEL_LCM_PATH}/$PRODUCT_INFO_FILE"


for file in "${filesToSync[@]}"; do
    echo "Syncing ${file} from ${FOSSA_CONFIG_DIR} to ${MODEL_LCM_FOSSA_CONFIG_DIR}"
    echo "Check if there are changes in $file"
    if [ -f $MODEL_LCM_PATH/$MODEL_LCM_FOSSA_CONFIG_DIR/$file ]
    then 
        diff $FOSSA_CONFIG_DIR/$file $MODEL_LCM_PATH/$MODEL_LCM_FOSSA_CONFIG_DIR/$file
        diffStatus=$?
    else 
        diffStatus=1
    fi 
    if [ $diffStatus -eq 0 ]; then
        echo "No changes in $file"
    else
        echo "Detected changes in $file"
        changedFiles+=("$MODEL_LCM_FOSSA_CONFIG_DIR/$file")
        echo "Copy $file to $MODEL_LCM_PATH/$MODEL_LCM_FOSSA_CONFIG_DIR/$file"
        cp $FOSSA_CONFIG_DIR/$file $MODEL_LCM_PATH/$MODEL_LCM_FOSSA_CONFIG_DIR/$file
    fi
done

cd "${MODEL_LCM_PATH}"

gerrit create-patch --file ${changedFiles[*]} \
    --message "[NoJira] Update Seldon core images to $seldonImageVersion" \
    --git-repo-local . \
    --wait-label "Verified"="+1" \
    --debug \
    --email ${EMAIL} \
    --timeout 7200
    #--submit

changeStatus=$? 

if [ $changeStatus -eq 0 ]; then
        echo "Change verification is successful"
else
    echo "Change failed verification"
    exit 1
fi 