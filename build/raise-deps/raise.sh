#!/bin/bash
set -e

#
# Param 1: Version (required)
#   e.g.: 9.2.0-SNAPSHOT
# 
# Param 2: Source Branch (required)
#   e.g.: master or release/8.0
#
# Param 3: Token File for auth of gh cli (required)
#   e.g.: ~/.gh-token-file
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

uuid=$(date +%s%N)
newBranch=raise-version-${newVersion}-${uuid}

commitMessage="Raise dependencies version to ${newVersion}"

# switch to directory of this script
cd "$(dirname "$0")"

source "../raiseRepo.sh"

function raiseDepsOfOurRepos {
  repos=(
    "git@github.com:axonivy/core.git"
    "git@github.com:axonivy/rules.git"
    "git@github.com:axonivy/webeditor.git"
    "git@github.com:axonivy/process-editor-core.git"
    "git@github.com:axonivy/vscode-extensions.git"
    "git@github.com:axonivy/process-editor-client.git"
    "git@github.com:axonivy/form-editor-client.git"
    "git@github.com:axonivy/config-editor-client.git"
    "git@github.com:axonivy/neo.git"
    "git@github.com:axonivy/dataclass-editor-client.git"
  )
  runRepoUpdate 'updateSingleRepo' ${repos[@]}
}

function updateSingleRepo {
  .ivy/raise-deps.sh ${newVersion}
}

raiseDepsOfOurRepos
