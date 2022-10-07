#!/bin/bash

if [ ! -f /usr/bin/lipo ]; then
  echo "ERROR: This script requires the lipo tool from the XCode utilities; please install XCode."
  exit 1
fi

if which gon >/dev/null; then 
  echo "" >/dev/null
else
  echo "ERROR: This script requires gon, please see https://github.com/mitchellh/gon for installation"
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

echo "Packaging Release ${VERSION}"



###############################################################################################################
echo "Creating Universal Binary...."    
cd dist/macos/
/usr/bin/lipo -create -output mondoo mac_darwin_amd64/mondoo mac_darwin_arm64/mondoo
if [ ! -f mondoo ]; then
  echo "ERROR: Failure in creating universal binary, please investigate lipo create in $PWD"
  exit 2
else
  mkdir -p ${BLDDIR}/scripts/pkg/mac/packager/application/bin/
  cp mondoo ${BLDDIR}/scripts/pkg/mac/packager/application/bin/
fi


###############################################################################################################
echo "Signing Universal Binary...."    
codesign -s "Developer ID Application: Mondoo, Inc. (W2KUBWKG84)" -f -v --timestamp --options runtime ${BLDDIR}/scripts/pkg/mac/packager/application/bin/mondoo



###############################################################################################################
echo "Building Package...."            
cd ${BLDDIR}/scripts/pkg/mac/
bash packager/build-package.sh Mondoo ${VERSION} 

PKG=packager/target/pkg/Mondoo-macos-universal-${VERSION}.pkg
if [ -f $PKG ]; then
  mv $PKG .
  echo "SUCCESS! Your package is ready to rock, hot and fresh: Mondoo-macos-universal-${VERSION}.pkg"
else 
  echo "ERROR: Something went wrong building the package... time to debug. :(" 
  exit 2
fi


###############################################################################################################
echo "Signing Package..."               
productsign --sign "Developer ID Installer: Mondoo, Inc. (W2KUBWKG84)" Mondoo-macos-universal-${VERSION}.pkg mondoo_${VERSION}_darwin_universal.pkg
if [ ! -f mondoo_${VERSION}_darwin_universal.pkg ]; then
  echo "ERROR: Signing failed. :("
  exit 2
fi


###############################################################################################################
echo "Notorizing Package with user ${APPLE_ID_USERNAME}...."           
cat notorize.hcl.tmpl | sed s/PACKAGE_PATH/mondoo_${VERSION}_darwin_universal.pkg/ \
                      | sed s/APPLE_ID_USERNAME/${APPLE_ID_USERNAME}/ \
                      | sed s/APPLE_ID_PASSWORD/${APPLE_ID_PASSWORD}/  > notorize.hcl 
gon -log-level=info notorize.hcl


###############################################################################################################
echo "Copying package to dist...."      
shasum -a 256 mondoo_${VERSION}_darwin_universal.pkg >> ${BLDDIR}/dist/macos/checksums.macos.txt 
cp mondoo_${VERSION}_darwin_universal.pkg ${BLDDIR}/dist/macos/

ls -l ${BLDDIR}/dist/macos/${PKG_NAME}
echo "All done here. Good bye."         
