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

if [[ $FILE_TAG == "true" ]]; then
    FILE_TAG="-${TAG_NAME}"
elif [[ $FILE_TAG == "false" ]]; then
    FILE_TAG=""
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

GOOS=${GOOS} GOARCH=${GOARCH} go build ${BUILD_FLAGS} -ldflags "${LDFLAGS}" -o ${BINARY_NAME}${BINARY_EXT}

ZIP_NAME="${BINARY_NAME}${FILE_TAG}-${GOOS}-${GOARCH}${ZIP_EXT}"

if [[ $CONTENT_TYPE == "zip" ]]; then
    zip -v -r -9 ${ZIP_NAME} "${BINARY_NAME}${BINARY_EXT}"
else
    tar zcvf ${ZIP_NAME} "${BINARY_NAME}${BINARY_EXT}"
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
