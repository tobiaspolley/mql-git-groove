## finish-release.sh
# This file finishes a new release. It must be run upon a finished RC.
#
# (Part 1):
# Branches off of release beanch,
# ends old release by merging master w/ --strategy ours.
#
# (Part 2):
# It removes release specific files,
# updates project.info,
# updates version numbers in files,
# updates filenames to match version number,
# adds .ex4 files to git,
# generates release specific files,
# generates a tarball archive,
# commits,
# merges to master and
# creates a tag for this release.

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
  echo "Release must be finished from 'release/...' branch"
  echo "Abort..."
  exit 1
else
  clear
  echo "Finish release from '$tmp' branch"
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
last_version=$project_version
new_version=${project_version%-rc*}
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
  echo "Failed to branch release branch"
  echo "Abort..."
  exit 1
fi
echo ""
### end previous release
echo "Create new merge commit: ENDING OLD RELEASE"
git merge -s ours master -m "ENDING OLD RELEASE"
if [ $? -ne 0 ]; then
  echo "Failed to merge to 'master'"
  echo "Abort..."
  exit 1
fi
echo ""

#####################
### 2nd part
#####################

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

##################
### add release specific files usually ignored by git
AddIgnoredFiles

#####################
### generate release specific files
GenerateChangelog
GenerateReadme

#####################
### archive
GenerateArchive

#####################
### commit
echo "Create new commit: NEW RELEASE ${project_version}"
msg="NEW RELEASE ${project_version}

- remove release specific files
- update 'project.info' to $project_version
- update version numbers in all project files
- rename immediate source files to match version number
- rename src/*.ex4 files to match version number
- add src/*.ex4 to git
- generate CHANGELOG ($generate_changelog)
- generate README ($generate_readme)
- generate tarball ($generate_archive)
"
git add -A
git commit --allow-empty -m "$msg"
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
current_dir=$PWD
cd ..
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
cd "$current_dir"
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
