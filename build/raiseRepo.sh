#!/bin/bash

if [ -z "$workDir" ]; then
  workDir=$(mktemp -d -t raiseRepoXXX)
fi
if [ -z "$dryRun" ]; then
  dryRun=0
fi
if [ -z "$sourceBranch" ]; then
  sourceBranch="master"
fi
if [ -z "$newBranch" ]; then
  uuid=$(date +%s%N)
  newBranch="${sourceBranch}-${uuid}"
fi

function runRepoUpdate {
  currentDir=$(pwd)
  updateAction=$1
  shift
  repos=("$@")

  for repo in "${repos[@]}"; do
    cloneDir="${workDir}/${repo}"
    echo "clone repository ${repo} to ${cloneDir}"
    git clone -q "${repo}" "${cloneDir}"

    cd "${cloneDir}"
    git checkout -q -b "${newBranch}" "${sourceBranch}"

    ${updateAction}

    if [ "$dryRun" = "0" ]; then
      git push -u origin "${newBranch}"
    fi

  done
  cd "${currentDir}"
}
