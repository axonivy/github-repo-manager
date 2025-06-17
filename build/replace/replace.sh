#!/bin/bash
set -e

shopt -s globstar
#
# Param 1: Sed Regexp param (required)
#   e.g.: s#search#replace#g
#
# Param 2: File Selector (required)
#   e.g.: bla/**/File.txt
# 
# Param 3: Source Branch (required)
#   e.g.: master or release/8.0
#
# Param 4: Target Branch (required)
#   e.g.: searchReplace
#
# Param 5: Commit Message (required)
#   e.g.: Replace search with Replace
#

if [ $# -eq 0 ]; then
  echo "Parameter 1 'regexp' required"
  exit
fi
if [ $# -eq 1 ]; then
  echo "Parameter 2 'file selector' required"
  exit
fi
if [ $# -eq 2 ]; then
  echo "Parameter 3 'source branch' required"
  exit
fi
if [ $# -eq 3 ]; then
  echo "Parameter 4 'target branch' required"
  exit
fi
if [ $# -eq 4 ]; then
  echo "Parameter 5 'commit message' required"
  exit
fi


sedRegexp=$1
fileSelector=$2
echo "will execute 'sed -i -E \"${sedRegexp}\" ${fileSelector}' on every repo"

sourceBranch=$3
echo "- source branch: ${sourceBranch}"
newBranch=$4
echo "- new branch: ${newBranch}"
commitMessage=$5
echo "- commit message: ${commitMessage}"

autoMerge=0
echo "- autoMerge: ${autoMerge}"

# switch to directory of this script
cd "$(dirname "$0")"

source "../raiseRepo.sh"


function updateSingleRepo {
  echo "execute 'sed -i -E \"${sedRegexp}\" ${fileSelector}'"
  # Ignore exceptions here, because sed throw an error if no file matches
  set +e
  # likely not working on mac
  sed -i -E "${sedRegexp}" ${fileSelector} || skipReason="sed failed"
  set -e
}

runAllRepoUpdate 'updateSingleRepo'
