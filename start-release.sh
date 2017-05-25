#!/bin/bash

### start-release.sh
# This file starts a new release branch with the option to create
# several release-candidates prior to the main release.
#
# (Part 1):
# It updates project.info,
# updates version numbers in files and
# commits.
#
# (Part 2):
# Creates a new release branch,
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
### check branch (develop!)
tmp=$( git symbolic-ref --short -q HEAD )
CheckOnBranch develop
if [ $? -ne 0 ]; then
  echo "New release must be created from 'develop' branch"
  echo "Abort..."
  exit 1
else
  clear
  echo "Starting new release from '$tmp' branch"
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
### read version number for release
echo "Current version is $project_version"
read -p "Enter version number for next release base [x.y.z]: " new_version
read -p "Please confirm version ${new_version} [Y/n]" val
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
echo "Create temporary branch 'to-develop/${release_date}_${version_prefix}${project_version}'"
from_branch=$( git symbolic-ref --short -q HEAD )
git checkout -b to-develop/${release_date}_${version_prefix}${project_version}
if [ $? -ne 0 ]; then
  echo "Failed to create 'to-develop/${release_date}_${version_prefix}${project_version}'"
  echo "Abort..."
  exit 1
fi
echo ""

#####################
### update version in project.info
UpdateProjectInfo "${new_version}-dev"
if [ $? -ne 0 ]; then
  exit 1
fi
### reload func.source
source func.source
DEBUG $project_version

#####################
### update version number in src/ files
UpdateFileVersion

#####################
### commit
echo "Create new commit: MOVE TO NEW BASE ${project_version%-dev*}"
msg="MOVE TO NEW BASE ${project_version%-dev*}

- update 'project.info' to $project_version
- update version numbers in all project files
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
  echo""
  echo "Remove '$tmp'"
  git branch -d "$tmp"
fi
echo ""

#####################
### 2nd part
#####################

#####################
### branch
echo "Create new branch 'release/${release_date}_${version_prefix}${new_version}'"
git checkout -b release/${release_date}_${version_prefix}${new_version}
if [ $? -ne 0 ]; then
  echo "Failed to create new release branch"
  echo "Abort..."
  exit 1
fi
echo ""

#####################
### update version in project.info
UpdateProjectInfo "${new_version}-rc0"
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
