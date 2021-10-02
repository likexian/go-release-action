#!/bin/bash

# entrypoint.sh
# Maintainer: https://www.likexian.com
# Licensed under the Apache License 2.0

set -ex

TAG_NAME=$(jq -r .release.tag_name $GITHUB_EVENT_PATH | sed -s 's/v//')
UPLOAD_URL=$(jq -r .release.upload_url $GITHUB_EVENT_PATH | sed -s 's/{?name,label}//')

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

set +x

curl --data-binary "@${ZIP_FILE_NAME}" \
    -H "Content-Type: application/${CONTENT_TYPE}" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "${UPLOAD_URL}?name=${ZIP_FILE_NAME}"

curl --data "${CHECKSUM}" \
    -H "Content-Type: text/plain" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "${UPLOAD_URL}?name=${ZIP_FILE_NAME}.sha256"
