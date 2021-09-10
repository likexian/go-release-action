# Go Release Action

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

Automate publishing Go build binary artifacts to GitHub releases through GitHub Actions.

## Example

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
          BUILD_DIR: cmd/example
          BUILD_FLAGS: "-v -ldflags '-w -s'"
```

## License

Copyright 2021 [Li Kexian](https://www.likexian.com/)

Licensed under the Apache License 2.0

## Donation

If this project is helpful, please share it with friends.

If you want to thank me, you can [give me a cup of coffee](https://www.likexian.com/donate/).
