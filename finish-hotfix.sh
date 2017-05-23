#!/bin/bash

### towards-hotfix.sh
# This file starts a new hotfix branch.
#
# (Part 1):
# It updates project.info,
# updates version numbers in files,
# updates filenames to match version number,
# adds .ex4 files to git,
# generates release specific files,
# generates a tarball archive,
# commits,
# merges back into 'master' and
# creates a tag for this release.
#
# (Part 2):
# Removes release specific files,
# updates project.info,
# updates version numbers in files,
# updates filenames to match version number,
# commits and merges back into 'develop'.

####################
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
### check branch (hotfix/...!)
tmp=$( git symbolic-ref --short -q HEAD )
CheckOnBranch hotfix
if [ $? -ne 0 ]; then
  echo "Hotfix must be finished from 'hotfix/...' branch"
  echo "Abort..."
  exit 1
else
  clear
  echo "Finish hotfix from '$tmp' branch"
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
new_version=${project_version%-hotfix}
read -p "Version for next release will be $new_version [Y/n]" val
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
echo "Create temporary branch 'to-master/${release_date}_${version_prefix}${project_version}'"
git checkout -b "to-master/${release_date}_${version_prefix}${project_version}"
if [ $? -ne 0 ]; then
  echo "Failed to branch hotfix branch"
  echo "Abort..."
  exit 1
fi
echo ""

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

##################
### add release specific files usually ignored by git
AddIgnoredFiles

#####################
### generate release specific files
GenerateReleaseFiles
if [ -f ../CHANGELOG ]; then
  git add ../CHANGELOG
fi
if [ -f ../LICENCE ]; then
  git add ../LICENCE
fi
if [ -f ../README ]; then
  git add ../README
fi

#####################
### archive
GenerateArchive

#####################
### commit
echo "Create new commit: FINISH HOTFIX ${project_version}-hotfix"
msg="FINISH HOTFIX ${project_version}-hotfix

- update 'project.info' to $project_version
- update version numbers in all project files
- rename immediate source files to match version number
- rename src/*.ex4 files to match version number
- add src/*.ex4 to git
- generate release specific files
- generate tarball archive
"
git add -A
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
git checkout master
if [ $? -ne 0 ]; then
  echo "Failed to checkout 'master'"
  echo "Abort..."
  exit 1
fi
echo ""
echo "Merge to master"
git merge --ff-only "$tmp"
if [ $? -ne 0 ]; then
  echo "Automerge failed"
  echo "Merge manually and delete branch by typing"
  echo "git branch -d '$tmp'"
  echo "Tag manually by typing"
  if [[ $date_in_tagnames == "true" ]]; then
    echo "git tag -s -m 'Version ${project_version}' ${release_date}_${version_prefix}${project_version}"
  else
    echo "git tag -s -m 'Version ${project_version}' ${version_prefix}${project_version}"
  fi
  exit 1
else
  echo ""
  echo "Remove '$tmp'"
  git branch -d "$tmp"
fi
echo ""

#####################
### tag
echo "Create tag for Version ${project_version}"
if [[ $date_in_tagnames == "true" ]]; then
  git tag -s -m "Version ${project_version}" ${release_date}_${version_prefix}${project_version}
else
  git tag -s -m "Version ${project_version}" ${version_prefix}${project_version}
fi
if [ $? -ne 0 ]; then
  echo "Failed to create new tag"
  echo "Abort..."
  exit 1
fi

#####################
### END
PrintDone

#####################
### 2nd part
#####################

#####################
### merge ?
read -p "Do you want to merge back to 'develop'? [Y/n]" val
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
echo "Create temporary branch 'to-develop/${release_date}_${version_prefix}${project_version}'"
git checkout -b to-develop/${release_date}_${version_prefix}${project_version}
if [ $? -ne 0 ]; then
  echo "Failed to create 'to-develop/${release_date}_${version_prefix}${project_version}'"
  echo "Abort..."
  exit 1
fi
echo ""

#####################
### read version number for dev
echo "Current version is $project_version"
last_version=$project_version
new_version=${project_version}-dev
read -p "New version will be ${new_version} [Y/n]" val
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
### delete release specific files
DeleteReleaseFiles

#####################
### update version in project.info
UpdateProjectInfo "${new_version}"
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
UpdateFilenames --plain

#####################
### commit
echo "Create new commit: TOWARDS $project_version"
msg="TOWARDS $project_version

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
git checkout develop
if [ $? -ne 0 ]; then
  echo "Failed to checkout 'develop'"
  echo "Abort..."
  exit 1
fi
echo ""
echo "Create new merge commit: MERGE BACK FROM $last_version"
git merge --no-ff -X theirs -m "MERGE BACK FROM $last_version" "$tmp"
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
