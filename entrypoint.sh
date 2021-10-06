#!/bin/bash

# entrypoint.sh
# Maintainer: https://www.likexian.com
# Licensed under the Apache License 2.0

set -ex

TAG_NAME=$(jq -r .release.tag_name $GITHUB_EVENT_PATH)
if [[ $TAG_NAME != null ]]; then
    # event.type: release.created
    UPLOAD_URL=$(jq -r .release.upload_url $GITHUB_EVENT_PATH)
else
    # event.type: tags.push
    IS_CREATED=$(jq -r .created $GITHUB_EVENT_PATH)
    if [[ $IS_CREATED != true ]]; then
        echo "Skip: not tag created"
        exit 0
    fi

    TAG_NAME=$(jq -r .ref $GITHUB_EVENT_PATH | xargs basename)
    RELEASE_URL=$(jq -r .repository.releases_url $GITHUB_EVENT_PATH | sed -s 's/{\/id}//')

    curl --data "{\"tag_name\": \"${TAG_NAME}\", \"name\": \"${TAG_NAME}\"}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -o $GITHUB_EVENT_PATH \
        $RELEASE_URL

    UPLOAD_URL=$(jq -r .upload_url $GITHUB_EVENT_PATH)
fi

TAG_NAME=$(echo $TAG_NAME | sed -s 's/v//')
if [[ $TAG_NAME == null ]]; then
    echo "Error: TAG_NAME is missing"
    exit 1
fi

UPLOAD_URL=$(echo $UPLOAD_URL | sed -s 's/{?name,label}//')
if [[ $UPLOAD_URL == null ]]; then
    echo "Error: UPLOAD_URL is missing"
    exit 1
fi

if [[ -n $BUILD_DIR ]]; then
    cd $BUILD_DIR
fi

if [[ -z $GOOS ]]; then
    GOOS="linux"
fi

if [[ -z $GOARCH ]]; then
    GOARCH="amd64"
fi

if [[ -z $BUILD_FILE ]]; then
    if [[ $GITHUB_WORKSPACE == $(pwd) ]]; then
        BUILD_FILE=$(basename $GITHUB_REPOSITORY)
    else
        BUILD_FILE=$(basename $(pwd))
    fi
fi

if [[ $GOOS == "windows" ]]; then
    CONTENT_TYPE="zip"
    BINARY_EXT=".exe"
    ZIP_EXT=".zip"
else
    CONTENT_TYPE="gzip"
    BINARY_EXT=""
    ZIP_EXT=".tar.gz"
fi

PACK_DIR="$(pwd)/pack_$(date +%s)"
mkdir -p $PACK_DIR

GOOS=${GOOS} GOARCH=${GOARCH} go build ${BUILD_FLAGS} -ldflags "${BUILD_LDFLAGS}" -o $PACK_DIR/${BUILD_FILE}${BINARY_EXT}

if [[ -n $ZIP_EXTRA_FILES ]]; then
    cd $GITHUB_WORKSPACE
    cp -rf $ZIP_EXTRA_FILES $PACK_DIR
fi

if [[ -z $ZIP_FILE_NAME ]]; then
    ZIP_FILE_NAME="${BUILD_FILE}-${TAG_NAME}-${GOOS}-${GOARCH}"
fi
ZIP_FILE_NAME="${ZIP_FILE_NAME}${ZIP_EXT}"

cd $PACK_DIR
if [[ $CONTENT_TYPE == "zip" ]]; then
    shopt -s dotglob; zip -v -r -9 ${ZIP_FILE_NAME} *
else
    shopt -s dotglob; tar zcvf ${ZIP_FILE_NAME} *
fi

CHECKSUM=$(sha256sum ${ZIP_FILE_NAME} | awk '{print $1}')

curl --data-binary "@${ZIP_FILE_NAME}" \
    -H "Content-Type: application/${CONTENT_TYPE}" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "${UPLOAD_URL}?name=${ZIP_FILE_NAME}"

curl --data "${CHECKSUM}" \
    -H "Content-Type: text/plain" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "${UPLOAD_URL}?name=${ZIP_FILE_NAME}.sha256"
