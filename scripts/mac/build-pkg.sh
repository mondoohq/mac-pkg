#!/bin/bash

if [ ! -f /usr/bin/lipo ]; then
  echo "ERROR: This script requires the lipo tool from the XCode utilities; please install XCode."
  exit 1
fi



if [[ $1 == "" ]]; then
  echo "USAGE: $0 <mondoo_version>"
  echo "   eg: $0 5.8.0"  
  exit 1
fi 

VERSION=$1
TIME=`/bin/date +%s`
BLDDIR=${PWD}

if [[ ! $PKGNAME ]]; then
  echo "ERROR: PKGNAME not set"
  exit 1
fi 

echo "Packaging Release ${VERSION}"

###############################################################################################################
# Pull Latest Binaries & Create Universal Binaries
for DIST in mondoo cnquery cnspec; do
  cd $BLDDIR
  mkdir -p dist/${DIST}
  for ARCH in amd64 arm64; do
    cd ${BLDDIR}/dist/${DIST}
    echo "Downloading ${DIST} for ${ARCH}"
    mkdir ${ARCH} && cd ${ARCH}
    curl -sL -o ${DIST}-${ARCH}.tgz https://install.mondoo.com/package/${DIST}/darwin/${ARCH}/tar.gz/latest/download
    tar -xzf ${DIST}-${ARCH}.tgz
    rm ${DIST}-${ARCH}.tgz
  done
  cd $BLDDIR/dist/${DIST}
  echo "Creating Universal Binary for ${DIST}..."
  /usr/bin/lipo -create -output ${DIST} amd64/${DIST} arm64/${DIST}
  if [ ! -f ${DIST} ]; then
    echo "ERROR: Failed to create universal ${DIST} binary"
    exit 1
  fi
  echo "Code Signing ${DIST}..."
  codesign -s "${APPLE_KEYS_CODESIGN_ID}" -f -v --timestamp --options runtime ${DIST}
  mkdir -p ${BLDDIR}/scripts/mac/packager/application/bin/
  cp ${DIST} ${BLDDIR}/scripts/mac/packager/application/bin/
done


###############################################################################################################
echo "Building Package...."            
cd ${BLDDIR}/scripts/mac/
bash packager/build-package.sh ${PKGNAME} ${VERSION} 

PKG=${BLDDIR}/scripts/mac/packager/target/pkg/${PKGNAME}-macos-universal-${VERSION}.pkg
if [ -f $PKG ]; then
  ls -lh $PKG
  shasum -a 256 $PKG
  cp ${PKG} ${BLDDIR}/dist/
  echo "SUCCESS! Your package is ready to rock, hot and fresh: dist/${PKGNAME}-macos-universal-${VERSION}.pkg"
else 
  echo "ERROR: Something went wrong building the package... time to debug. :(" 
  exit 2
fi

# Done!  Copy to dist for next step!  (Sign & Notarize)
