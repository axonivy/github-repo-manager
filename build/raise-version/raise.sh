#!/bin/bash
set -e

#
# Param 1: Version (required)
#   e.g.: 9.2.0-SNAPSHOT
# 
# Param 2: Source Branch (required)
#   e.g.: master or release/8.0
#

if [ $# -eq 0 ]; then
  echo "Parameter version required"
  exit
fi
if [ $# -eq 1 ]; then
  echo "Parameter source branch required"
  exit
fi

newVersion=$1
echo "raise version to ${newVersion}"

sourceBranch=$2
echo "source branch to checkout repos $2"

autoMerge=0
if [ "$DRY_RUN" = false ]; then
  autoMerge=1
fi
echo "autoMerge ${autoMerge}"

uuid=$(date +%s%N)
newBranch=raise-version-${newVersion}-${uuid}

commitMessage="Raise version to ${newVersion}"

# switch to directory of this script
cd "$(dirname "$0")"

source "../raiseRepo.sh"

function updateSingleRepo {
  if test -f .ivy/raise-version.sh; then
    .ivy/raise-version.sh ${newVersion}
  else
    skipReason="No raise-version.sh present"
  fi
}

runAllRepoUpdate 'updateSingleRepo'
