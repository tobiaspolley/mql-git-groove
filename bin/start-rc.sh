#!/bin/bash

### start-rc.sh
# This file starts a new release-candidate.
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
### check branch (release/...!)
tmp=$( git symbolic-ref --short -q HEAD )
CheckOnBranch release
if [ $? -ne 0 ]; then
  echo "New RC must be started from 'release/...' branch"
  echo "Abort..."
  exit 1
else
  clear
  echo "Start new RC from '$tmp' branch"
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
### read version number for rc
echo "Current version is $project_version"
tmp=${project_version##*-rc}
((tmp++))
new_version=${project_version%-rc*}-rc${tmp}
read -p "Version for next rc will be $new_version [Y/n]" val
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

#####################
### branch
echo "Create temporary branch 'to-release/${release_date}_${version_prefix}${project_version}'"
from_branch=$( git symbolic-ref --short -q HEAD )
git checkout -b to-release/${release_date}_${version_prefix}${project_version}
if [ $? -ne 0 ]; then
  echo "Failed to create 'to-release/${release_date}_${version_prefix}${project_version}'"
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
echo "Create new commit: START RC $project_version"
msg="START RC $project_version

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
### merge
tmp=$( git symbolic-ref --short -q HEAD )
DEBUG ${tmp[@]}
git checkout "$from_branch"
if [ $? -ne 0 ]; then
  echo "Failed to checkout '$from_branch'"
  echo "Abort..."
  exit 1
fi
echo "Merge back to '$from_branch'"
git merge --ff-only "$tmp"
if [ $? -ne 0 ]; then
  echo "Automerge failed"
  echo "Merge manually and delete branch by typing"
  echo "git branch -d '$tmp'"
  exit 1
else
  echo ""
  echo "Remove '$tmp'"
  git branch -d "$tmp"
fi
echo ""

#####################
### END
PrintDone
