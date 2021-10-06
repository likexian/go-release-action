# Go Release Action

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

Automate publishing Go build binary artifacts to GitHub releases through GitHub Actions.

## Example

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

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Release code
        uses: likexian/go-release-action@v0.1.0
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GOOS: linux
          GOARCH: amd64
```

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
        uses: actions/checkout@v2
      - name: Release code
        uses: likexian/go-release-action@v0.1.0
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GOOS: ${{ matrix.goos }}
          GOARCH: ${{ matrix.goarch }}
          BUILD_IN_DIR: cmd/example
          BUILD_BIN_DIR: bin
          BUILD_BIN_FILE: example
          BUILD_FLAGS: -v
          BUILD_LDFLAGS: -w -s
          PACK_ASSET_FILE: example-${{ matrix.goos }}-${{ matrix.goarch }}
          PACK_INCLUDE_DIR: example
          PACK_EXTRA_FILES: LICENSE README.md
```

## License

Copyright 2021 [Li Kexian](https://www.likexian.com/)

Licensed under the Apache License 2.0

## Donation

If this project is helpful, please share it with friends.

If you want to thank me, you can [give me a cup of coffee](https://www.likexian.com/donate/).
