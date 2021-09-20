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

if [[ -z $BINARY_NAME ]]; then
    BINARY_NAME=$(basename $(pwd))
fi

BINARY_EXT=""
if [[ $GOOS == "windows" ]]; then
    BINARY_EXT=".exe"
fi

ZIP_NAME="${BINARY_NAME}-${GOOS}-${GOARCH}"
if [[ $FILE_TAG == "true" ]]; then
    ZIP_NAME="${BINARY_NAME}-${TAG_NAME}-${GOOS}-${GOARCH}"
fi

GOOS=${GOOS} GOARCH=${GOARCH} go build ${BUILD_FLAGS} -ldflags "${LDFLAGS}" -o ${BINARY_NAME}${BINARY_EXT}

if [[ $GOOS == "windows" ]]; then
    CONTENT_TYPE="zip"
    ZIP_NAME="${ZIP_NAME}.zip"
    zip -9 -r ${ZIP_NAME} "${BINARY_NAME}${BINARY_EXT}"
else
    CONTENT_TYPE="gzip"
    ZIP_NAME="${ZIP_NAME}.tar.gz"
    tar zcf ${ZIP_NAME} "${BINARY_NAME}${BINARY_EXT}"
fi

CHECKSUM=$(sha256sum ${ZIP_NAME} | awk '{print $1}')

set +x

curl --data-binary "@${ZIP_NAME}" \
    -H "Content-Type: application/${CONTENT_TYPE}" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "${UPLOAD_URL}?name=${ZIP_NAME}"

curl --data "${CHECKSUM}" \
    -H "Content-Type: text/plain" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "${UPLOAD_URL}?name=${ZIP_NAME}.sha256sum.txt"
