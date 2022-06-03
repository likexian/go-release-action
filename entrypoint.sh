#!/bin/bash

# entrypoint.sh
# Maintainer: https://www.likexian.com
# Licensed under the Apache License 2.0

set -ex

git config --global --add safe.directory $GITHUB_WORKSPACE

tag_name=$(jq -r .release.tag_name $GITHUB_EVENT_PATH)
if [[ $tag_name != null ]]; then
    # event.type: release
    action=$(jq -r .action $GITHUB_EVENT_PATH)
    if [[ $action != "created" ]]; then
        echo "Skip: only CREATED event is supported"
        exit 0
    fi

    upload_url=$(jq -r .release.upload_url $GITHUB_EVENT_PATH)
else
    # event.type: push
    is_created=$(jq -r .created $GITHUB_EVENT_PATH)
    if [[ $is_created != true ]]; then
        echo "Skip: only CREATED event is supported"
        exit 0
    fi

    tag_name=$(jq -r .ref $GITHUB_EVENT_PATH | xargs basename)
    releases_url=$(jq -r .repository.releases_url $GITHUB_EVENT_PATH | sed -s 's/{\/id}//')

    curl --data "{\"tag_name\": \"${tag_name}\", \"name\": \"${tag_name}\"}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -o $GITHUB_EVENT_PATH \
        $releases_url

    upload_url=$(jq -r .upload_url $GITHUB_EVENT_PATH)
fi

tag_name=$(echo $tag_name | sed -s 's/v//')
if [[ $tag_name == null ]]; then
    echo "Error: tag_name is missing"
    exit 1
fi

upload_url=$(echo $upload_url | sed -s 's/{?name,label}//')
if [[ $upload_url == null ]]; then
    echo "Error: upload_url is missing"
    exit 1
fi

if [[ -z $GOOS ]]; then
    GOOS="linux"
fi

if [[ -z $GOARCH ]]; then
    GOARCH="amd64"
fi

project_name=$(basename $GITHUB_REPOSITORY)
if [[ -n $BUILD_IN_DIR ]]; then
    project_name=$(basename $BUILD_IN_DIR)
fi

if [[ -z $BUILD_BIN_FILE ]]; then
    BUILD_BIN_FILE=$project_name
fi

if [[ $GOOS == "windows" ]]; then
    content_type="zip"
    binary_ext=".exe"
    pack_ext=".zip"
else
    content_type="gzip"
    binary_ext=""
    pack_ext=".tar.gz"
fi

pack_dir="$GITHUB_WORKSPACE/$BUILD_IN_DIR/pack_$(date +%s)"
mkdir -p $pack_dir

if [[ -n $PACK_INCLUDE_DIR ]]; then
    mkdir -p $pack_dir/$PACK_INCLUDE_DIR
fi

if [[ -n $BUILD_BIN_DIR ]]; then
    mkdir -p $pack_dir/$PACK_INCLUDE_DIR/$BUILD_BIN_DIR
fi

if [[ -n $PACK_EXTRA_FILES ]]; then
    cp -rf $PACK_EXTRA_FILES $pack_dir/$PACK_INCLUDE_DIR
fi

if [[ -z $PACK_ASSET_FILE ]]; then
    PACK_ASSET_FILE="${BUILD_BIN_FILE}-${tag_name}-${GOOS}-${GOARCH}"
fi
PACK_ASSET_FILE="${PACK_ASSET_FILE}${pack_ext}"

if [[ -n $BUILD_IN_DIR ]]; then
    cd $BUILD_IN_DIR
fi

GOOS=${GOOS} GOARCH=${GOARCH} \
    go build ${BUILD_FLAGS} -ldflags "${BUILD_LDFLAGS}" \
    -o $pack_dir/$PACK_INCLUDE_DIR/$BUILD_BIN_DIR/${BUILD_BIN_FILE}${binary_ext}

cd $pack_dir

if [[ $content_type == "zip" ]]; then
    shopt -s dotglob; zip -v -r -9 ${PACK_ASSET_FILE} *
else
    shopt -s dotglob; tar zcvf ${PACK_ASSET_FILE} *
fi

checksum=$(sha256sum ${PACK_ASSET_FILE} | awk '{print $1}')

curl --data-binary "@${PACK_ASSET_FILE}" \
    -H "Content-Type: application/${content_type}" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "${upload_url}?name=${PACK_ASSET_FILE}"

curl --data "${checksum}" \
    -H "Content-Type: text/plain" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "${upload_url}?name=${PACK_ASSET_FILE}.sha256"
