#!/bin/sh
#
# This script is designed to simplify creating a developer-to-developer iphone-app-distribution.
# You can add this script to an iPhone project as a Run Script build Phase for easy automation.
#
# To do this put something like the following (prefixed with '##') in the 'script' area of the Run Script Phase:
#
## script_file="/Users/shane/projects/iphonedevtodev/devtodevdistribution.sh"
## dist_dirname="dist"
## resign_file="/Users/shane/projects/iphonedevtodev/re-sign.sh"
## echo "Running a custom build phase script: $script_file $dist_dirname $resign_file"
## ${script_file} "$resign_file" "$dist_dirname"
## scriptExitStatus=$?
## echo "DONE with script: ${script_file} (exitStatus=${scriptExitStatus})\n\n"
## exit "${scriptExitStatus}"
#
# If you chose not to add it as a build phase then you'll want to consider hard-coding the default
# values for RESIGN_PATH AND DIST_DIRNAME in the 'Setup' area below.
# 
# It is based off what needs to be done for 
# http://www.mobileorchard.com/developer-to-developer-iphone-app-distribution-without-ad-hoc-provisioning
# which was based on 
# http://www.tuaw.com/2009/06/24/dev-corner-signing-iphone-apps-for-informal-distribution/
#
# Xcode info I used: http://developer.apple.com/mac/library/DOCUMENTATION/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html
#

# BEGIN SETUP ---------------------------

# RESIGN_PATH is the path to the bare re-sign script which we will copy, and modify, to be included in the zip archive for the Xcode 
# Project's Application distribution.
# Default value is ~/bin/re-sign.sh
RESIGN_PATH=$1
if [ "$RESIGN_PATH" == "" ]; then
    echo "Assigning RE-SIGN script to DEFAULT"
    RESIGN_PATH="/Users/$USER/bin/re-sign.sh"
fi

# DIST_DIR_NAME is the name of the directory, within the project, that we'll place the codesigned
# application.app, the script to re-sign it. This directory will be zip'd up. Default value is 'dist'
DIST_DIRNAME=$2
if [ "$DIST_DIRNAME" == "" ]; then
  echo "Assigning Distribution Directory Name to DEFAULT"
  DIST_DIRNAME="dist"
fi

# CODESIGNIDENTITY is the name of the code Signing Identity to use. Generally obtained from 
# Xcode. If you have problems define it here.
CODESIGNIDENTITY="${CODE_SIGN_IDENTITY}"

# END SETUP -----------------------------

 
if [ "$BUILD_STYLE" == "Debug" ]; then
  echo "Skipping debug"
  exit 0;
fi

if [ "$EFFECTIVE_PLATFORM_NAME" == "-iphonesimulator" ]; then
  echo "Skipping simulator build"
  exit 0;
fi

if [ "$DIST_DIRNAME" == "" ]; then
  echo "DISTRIBUTION DIRECTORY NAME EMPTY ABORTING"
  exit 1;
fi

if [ "$RESIGN_PATH" == "" ]; then
  echo "PATH TO RAW RE-SIGN SCRIPT EMPTY ABORTING"
  exit 1;
fi

SRC_PATH=${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}
DIST_DIRPATH=${PROJECT_DIR}/${DIST_DIRNAME}
RELATIVE_DESTPATH=${DIST_DIRPATH}/${WRAPPER_NAME}
 
export CODESIGN_ALLOCATE=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/codesign_allocate
CODESIGN_CMD="codesign -f -s \"${CODESIGNIDENTITY}\" ${RELATIVE_DEST_PATH}"

if [ ! -e ${DIST_DIRPATH} ]; then
    mkdir "${DIST_DIRPATH}"
fi

#copy the source.app to the destination directory, recursively
cp -fr "${SRC_PATH}" "${RELATIVE_DESTPATH}"

#use the raw re-sign script, alter it with the correct app name and copy to destination directory
sed -e "s,APPNAME,${WRAPPER_NAME}," "${RESIGN_PATH}" > "${DIST_DIRPATH}/re-sign.sh"

#codesign the app in the destination directory
codesign -f -s "${CODESIGNIDENTITY}" "${RELATIVE_DESTPATH}"

#create a zip archive for easy distribution
zip -yr "${DIST_DIRPATH}.zip" "${DIST_DIRPATH}"

exit 0;