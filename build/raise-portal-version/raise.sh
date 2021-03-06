#!/bin/bash
set -e

#
# Param 1: Version (required)
#   e.g.: 9.2.0-SNAPSHOT
# 
# Param 2: Source Branch (required)
#   e.g.: master or release/8.0
#
# Param 3: dry run (optional)
#   e.g.: --dry-run
#

if [ $# -eq 0 ]; then
  echo "Parameter version required"
  exit
fi
if [ $# -eq 1 ]; then
  echo "Parameter source branch required"
  exit
fi
if [ $# -eq 2 ]; then
  echo "Parameter tokenFile required"
  exit
fi

newVersion=$1
echo "raise version to ${newVersion}"

sourceBranch=$2
echo "source branch to checkout repos ${sourceBranch}"

tokenFile=$3
echo "token file to auth for gh cli ${tokenFile}"

dryRun=0
if [ $# -eq 4 ]; then
  if [ $4 = "--dry-run" ]; then
    dryRun=1
  fi
fi
echo "dry run ${dryRun}"

uuid=$(date +%s%N)
newBranch=raise-portal-version-${newVersion}-${uuid}

# switch to directory of this script
cd "$(dirname "$0")"

source "../raiseRepo.sh"

function raiseVersionOfOurRepos {
  repos=(
    "git@github.com:axonivy/core.git"
  )
  message="Raise portal version to ${newVersion}"
  runRepoUpdate 'updateSingleRepo' ${repos[@]}
}

function updateSingleRepo {
  .ivy/raise-portal.sh ${newVersion}
  git commit -a -m "Raise portal version to ${newVersion}"
}

raiseVersionOfOurRepos
