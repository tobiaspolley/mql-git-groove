#!/bin/bash

### start-hotfix.sh
# This file starts a new hotfix branch.
#
# It removes release specific files,
# updates project.info,
# updates version numbers in files,
# updates filenames to match version number and
# commits.

#####################
### check start directory (bin!)
me=`basename "$0"`
if [ ${PWD##*/} != "bin" ]; then
  echo "$me must be run from bin/ directory"
  echo "Abort..."
  exit 1
fi

####################
### include func.source
debug="false"
source func.source

#####################
### check branch (master!)
tmp=$( git symbolic-ref --short -q HEAD )
CheckOnBranch master
if [ $? -ne 0 ]; then
  echo "New hotfix must be started from 'master' branch"
  echo "Abort..."
  exit 1
else
  clear
  echo "Start new hotfix from '$tmp' branch"
fi

#####################
### check git status
CheckGitStatus
if [ $? -ne 0 ]; then
  exit 1
fi

#####################
### check upstream
CheckUpstream
if [ $? -ne 0 ]; then
  exit 1
fi

#####################
### ShowProjectInfo
ShowProjectInfo

#####################
### 1st part
#####################

#####################
### read version number for hotfix
echo "Current version is $project_version"
tmp=${project_version##*.}
((tmp++))
DEBUG ${tmp[@]}
new_version=${project_version%.*}.${tmp}-hotfix
read -p "Version for new hotfix will be $new_version [Y/n]" val
case "$val" in
  Yes|yes|Y|y|"") DEBUG "YES"
  ;;
  No|no|N|n) echo "Abort..."
    exit 1
  ;;
  *) echo "Unknown option"
    echo "Abort..."
    exit 1
  ;;
esac
echo ""

#####################
### branch
echo "Create new branch 'hotfix/${release_date}_${version_prefix}${new_version%-hotfix}'"
git checkout -b hotfix/${release_date}_${version_prefix}${new_version%-hotfix}
if [ $? -ne 0 ]; then
  echo "Failed to create new hotfix branch"
  echo "Abort..."
  exit 1
fi
echo ""

#####################
### delete release specific files
DeleteReleaseFiles

#####################
### update version in project.info
UpdateProjectInfo "$new_version"
if [ $? -ne 0 ]; then
  exit 1
fi
### reload func.source
source func.source
DEBUG $project_version

#####################
### update version number in src/ files
UpdateFileVersion

##################
### update filenames of binaries and immediate binary source files
UpdateFilenames

#####################
### commit
echo "Create new commit: START HOTFIX $project_version"
msg="START HOTFIX $project_version

- remove release specific files
- update 'project.info' to $project_version
- update version numbers in all project files
- rename immediate source files to match version number
- rename src/*.ex4 files to match version number
"
git add -u
git commit -m "$msg"
if [ $? -ne 0 ]; then
  echo "Failed to create new commit"
  echo "Abort..."
  exit 1
fi
echo ""

#####################
### END
PrintDone
