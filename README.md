[![Build MacOS Package](https://github.com/mondoohq/mac-pkg/actions/workflows/build_pkg.yaml/badge.svg)](https://github.com/mondoohq/mac-pkg/actions/workflows/build_pkg.yaml)
# Mondoo's MacOS Package Builder

This repo is responsible for building the Mondoo client package for OSX.  It:

- Downloads the latest mondoo, cnquery, and cnspec binaries produced by the mondoo repository, for both AMD64 and ARM64
- Signs all binaries
- Create a MacOS Package
- Signs the Package
- Notorizes the Package
- Uploads the package to releases.mondoo.com, overwritting the one produced by Gitlab, including fixing the checksum file
