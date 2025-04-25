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

function raiseVersionOfOurRepos {
  repos=(
    "git@github.com:axonivy/demo-projects.git"
    "git@github.com:axonivy/doc-images.git"
    "git@github.com:axonivy/case-map-ui.git"
    "git@github.com:axonivy/config-editor-client.git"
    "git@github.com:axonivy/primefaces-themes.git"
    "git@github.com:axonivy/engine-cockpit.git"
    "git@github.com:axonivy/dev-workflow-ui.git"
    "git@github.com:axonivy/webeditor.git"
    "git@github.com:axonivy/rules.git"
    "git@github.com:axonivy/process-editor-client.git"
    "git@github.com:axonivy/process-editor-core.git"
    "git@github.com:axonivy/form-editor-client.git"
    "git@github.com:axonivy/ui-components.git"
    "git@github.com:axonivy/neo.git"
    "git@github.com:axonivy/dataclass-editor-client.git"
    "git@github.com:axonivy/monaco-yaml-ivy.git"
    "git@github.com:axonivy/swagger-ui-ivy.git"
    "git@github.com:axonivy/core.git"
    "git@github.com:axonivy/doc.git"
    "git@github.com:axonivy/vscode-designer.git"
  )
  runRepoUpdate 'updateSingleRepo' ${repos[@]}
}

function updateSingleRepo {
  .ivy/raise-version.sh ${newVersion}
}

raiseVersionOfOurRepos
