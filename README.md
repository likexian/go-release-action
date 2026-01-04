# Go Release Action

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

Automate publishing Go build binary artifacts to GitHub releases through GitHub Actions.

## Usage

Your secret token might not have permissions to upload assets. In that case do not forget to add `permissions` to your workflow file (see examples).

### Basic Example

Release single artifact for linux amd64 with default option when tag push.

```yaml
# .github/workflows/release.yaml
# Maintainer: https://www.likexian.com
# Licensed under the Apache License 2.0

name: Release

on:
  push:
    tags:
      - '*'

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v6
      - name: Release code
        uses: likexian/go-release-action@v0.9.0
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GOOS: linux
          GOARCH: amd64
```

### Release Arguments

We use `system environment` to set release arguments, as `env` setting in Github Action.

| Argument | Required | Description |
| -------- | -------- | ----------- |
| GITHUB_TOKEN | Required | `GITHUB_TOKEN` for uploading releases to Github assets. |
| GOOS | Optional | `GOOS` for go build, one of `darwin`, `linux`, `windows`, `freebsd` and so on. |
| GOARCH | Optional | `GOARCH` for go build, one of `amd64`, `386`, `arm64`, `arm` and so on. |
| BUILD_FLAGS | Optional | `flags` for running go build, `-v` for example. |
| BUILD_LDFLAGS | Optional | `ldflags` for running go build, `-w -s` for example. |
| BUILD_STATIC | Optional | Enable static build by setting `CGO_ENABLED=0`, adding `-a -tags netgo` flags and `-extldflags '-static'` ldflags. |
| BUILD_IN_DIR | Optional | Directory to run the go build. |
| BUILD_BIN_DIR | Optional | Binary target will include in this folder. |
| BUILD_BIN_FILE | Optional | Binary target file name for go build. |
| PACK_ASSET_FILE | Optional | Package name for uploading to Github assets. |
| PACK_INCLUDE_DIR | Optional | Files will be packed in this folder. |
| PACK_EXTRA_FILES | Optional | Extra files to pack, for example `LICENSE` and `README.md`. |

### Advanced Example

Release for multiple OS and ARCH parallelly by matrix strategy with more option when release created.

```yaml
# .github/workflows/release.yaml
# Maintainer: https://www.likexian.com
# Licensed under the Apache License 2.0

name: Release

on:
  release:
    types: [created]

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        goos: [linux, darwin, windows]
        goarch: ["386", "amd64"]
        exclude:
          - goos: darwin
            goarch: "386"
    steps:
      - name: Checkout code
        uses: actions/checkout@v6
      - name: Release code
        uses: likexian/go-release-action@v0.9.0
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GOOS: ${{ matrix.goos }}
          GOARCH: ${{ matrix.goarch }}
          BUILD_IN_DIR: cmd/example
          BUILD_BIN_DIR: bin
          BUILD_BIN_FILE: example
          BUILD_FLAGS: -v
          BUILD_LDFLAGS: -w -s
          BUILD_STATIC: true
          PACK_ASSET_FILE: example-${{ matrix.goos }}-${{ matrix.goarch }}
          PACK_INCLUDE_DIR: example
          PACK_EXTRA_FILES: LICENSE README.md
```

### More Example

Please refer to [go-release-action-example](https://github.com/likexian/go-release-action-example)

## License

Copyright 2021-2026 [Li Kexian](https://www.likexian.com/)

Licensed under the Apache License 2.0

## Donation

If this project is helpful, please share it with friends.

If you want to thank me, you can [give me a cup of coffee](https://www.likexian.com/donate/).
