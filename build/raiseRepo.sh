#!/bin/bash

if [ -z "$workDir" ]; then
  workDir=$(mktemp -d -t raiseRepoXXX)
fi
if [ "$DRY_RUN" = false ]; then
  echo ""; echo "This is NOT a DRY RUN! We will push to the origin Repos!"; echo "";
else
  echo ""; echo "This is a DRY RUN! Nothing is pushed!"
  echo "Change it by setting the variable 'DRY_RUN' to 'false' before executing this script. ('export DRY_RUN=false')"; echo ""
fi
if [ -z "$autoMerge" ]; then
  autoMerge=0
fi
if [ -z "$sourceBranch" ]; then
  sourceBranch="master"
fi
if [ -z "$newBranch" ]; then
  uuid=$(date +%s%N)
  newBranch="${sourceBranch}-${uuid}"
fi
if [[ ! "${PARALLEL_JOBS}" =~ ^[1-9][0-9]*$ ]]; then
  PARALLEL_JOBS=6
fi

function repoCloneDir {
  echo "${workDir}/$1" | sed 's|:|-|g'
}

function repoResultDir {
  echo "${workDir}/.raiseRepo-results/$1"
}

function printRepoLog {
  logFile="$1/log.txt"
  if [ -f "${logFile}" ]; then
    cat "${logFile}"
  fi
}

function recordRepoResult {
  resultDir="$1"
  status="$2"
  message="$3"

  echo "${status}" > "${resultDir}/status"
  printf '%s' "${message}" > "${resultDir}/message"
}

function readRepoResultMessage {
  resultDir="$1"

  if [ -f "${resultDir}/message" ]; then
    cat "${resultDir}/message"
  fi
}

function processRepoUpdate {
  updateAction=$1
  repo=$2
  resultDir=$3
  cloneDir=$(repoCloneDir "${repo}")
  logFile="${resultDir}/log.txt"

  mkdir -p "${resultDir}"

  (
    exec > "${logFile}" 2>&1
    set +e

    echo ""
    echo "==> start converting repo '${repo}'"
    echo ""

    branchExists=$(git ls-remote --heads ${repo} refs/heads/${sourceBranch})
    if [[ -z ${branchExists} ]]; then
      echo ""
      echo "--> skipping repo '${repo}' because it has no '${sourceBranch}' branch"
      recordRepoResult "${resultDir}" "skipped" "missing source branch"
      exit 0
    fi

    echo "git: clone branch '${sourceBranch}' of repo '${repo}' to '${cloneDir}'"
    git clone -b ${sourceBranch} -q "${repo}" "${cloneDir}"
    if [ $? -ne 0 ]; then
      echo "git: clone failed for repo '${repo}'"
      recordRepoResult "${resultDir}" "failed" "git clone failed"
      exit 1
    fi

    cd "${cloneDir}"
    if [ $? -ne 0 ]; then
      echo "git: failed to switch into clone dir '${cloneDir}'"
      recordRepoResult "${resultDir}" "failed" "failed to enter clone dir"
      exit 1
    fi

    echo "git: create new branch '${newBranch}'"
    git checkout -q -b "${newBranch}"
    if [ $? -ne 0 ]; then
      echo "git: failed to create new branch '${newBranch}'"
      recordRepoResult "${resultDir}" "failed" "git checkout failed"
      exit 1
    fi

    skipReason=""
    ${updateAction}
    updateExit=$?
    if [ ${updateExit} -ne 0 ]; then
      if [[ -z ${skipReason} ]]; then
        skipReason="${updateAction} failed"
      fi
      echo ""
      echo "--> failed converting repo '${repo}' because: ${skipReason}"
      recordRepoResult "${resultDir}" "failed" "${skipReason}"
      exit ${updateExit}
    fi
    if [[ -n ${skipReason} ]]; then
      echo ""
      echo "--> skipping repo '${repo}' because: ${skipReason}"
      recordRepoResult "${resultDir}" "skipped" "${skipReason}"
      exit 0
    fi

    if [[ -z $(git status --porcelain) ]]; then
      echo ""
      echo "--> skipping repo '${repo}' because: Nothing has changed"
      recordRepoResult "${resultDir}" "skipped" "Nothing has changed"
      exit 0
    fi

    if [ "$DRY_RUN" != false ]; then
      echo ""
      echo "DRY RUN: Changes were simulated however, in the following files:"
      showDiff
    fi

    echo "git: commit with message: ${commitMessage}"
    git commit -a -m "${commitMessage}"
    if [ $? -ne 0 ]; then
      echo "git: commit failed for repo '${repo}'"
      recordRepoResult "${resultDir}" "failed" "git commit failed"
      exit 1
    fi

    echo ""
    echo "--> finished converting repo '${repo}'"
    recordRepoResult "${resultDir}" "changed" "${cloneDir}"
  )
}

function waitForRepoSlot {
  maxJobs=$1

  while [ "$(jobs -rp | wc -l | tr -d ' ')" -ge "${maxJobs}" ]; do
    sleep 1
  done
}

function countFinishedRepoWorkers {
  finished=0

  for repoIndex in "${!repos[@]}"; do
    resultDir=$(repoResultDir "${repoIndex}")
    if [ -f "${resultDir}/status" ]; then
      finished=$((finished + 1))
    fi
  done

  echo "${finished}"
}

function printRepoProgress {
  finishedWorkers=$(countFinishedRepoWorkers)
  runningWorkers=$(jobs -rp | wc -l | tr -d ' ')

  if [ "${finishedWorkers}" != "${lastFinishedWorkers}" ] || [ "${runningWorkers}" != "${lastRunningWorkers}" ]; then
    echo "Progress: ${finishedWorkers}/${#repos[@]} repos finished, ${runningWorkers} running"
    lastFinishedWorkers="${finishedWorkers}"
    lastRunningWorkers="${runningWorkers}"
  fi
}

function runRepoUpdate {
  currentDir=$(pwd)
  updateAction=$1
  shift
  repos=("$@")
  resultsRoot="${workDir}/.raiseRepo-results"

  echo ""; echo "Convert the following "${#repos[@]}" repos:"
  for repo in "${repos[@]}"; do
    echo " - ${repo}"
  done

  rm -rf "${resultsRoot}"
  mkdir -p "${resultsRoot}"

  reposToPush=()
  workerPids=()
  raiseRepoErrors=""
  lastFinishedWorkers=-1
  lastRunningWorkers=-1

  echo ""
  echo "Processing repos with up to ${PARALLEL_JOBS} parallel workers..."
  printRepoProgress

  for repoIndex in "${!repos[@]}"; do
    repo="${repos[${repoIndex}]}"
    resultDir=$(repoResultDir "${repoIndex}")

    while [ "$(jobs -rp | wc -l | tr -d ' ')" -ge "${PARALLEL_JOBS}" ]; do
      printRepoProgress
      sleep 1
    done

    processRepoUpdate "${updateAction}" "${repo}" "${resultDir}" &
    workerPids+=("$!")
    printRepoProgress
  done

  while true; do
    printRepoProgress

    if [ "${lastFinishedWorkers}" -ge "${#repos[@]}" ]; then
      break
    fi

    sleep 1
  done

  for workerPid in "${workerPids[@]}"; do
    if ! wait "${workerPid}"; then
      true
    fi
  done

  for repoIndex in "${!repos[@]}"; do
    repo="${repos[${repoIndex}]}"
    resultDir=$(repoResultDir "${repoIndex}")
    status=$(cat "${resultDir}/status")

    printRepoLog "${resultDir}"

    if [ "${status}" = "changed" ]; then
      reposToPush+=("${repo}")
    fi

    if [ "${status}" = "failed" ]; then
      errorMessage=$(readRepoResultMessage "${resultDir}")
      raiseRepoErrors+="${repo}: ${errorMessage}\n"
    fi
  done

  if ! [ -z "${raiseRepoErrors}" ]; then
    printf '\nFailed to update some repos:\n%b' "${raiseRepoErrors}"
    cd "${currentDir}"
    return 127
  fi

  if [ "$DRY_RUN" != false ]; then
    echo ""; echo "Because this is a DRY RUN we are finished here and do NOT push!"
    cd "${currentDir}"
    return;
  fi

  if [ "${#reposToPush[@]}" -eq 0 ]; then
    echo ""; echo "Finished here because no repo has changed, nothing to push!"
    cd "${currentDir}"
    return;
  fi

  echo ""; echo "Push the following "${#reposToPush[@]}" repos:"
  for repo in "${reposToPush[@]}"; do
    echo " - ${repo}"
  done

  echo ""; ghAuth

  echo "Check github cli auth status with 'gh auth status':"
  gh auth status
  echo ""

  for repo in "${reposToPush[@]}"; do
    echo ""; echo "==> start pushing repo '${repo}'"; echo ""

    cloneDir=$(repoCloneDir "${repo}")
    cd "${cloneDir}"

    echo "Push branch ${newBranch} to repo ${repo}"
    git push -q -u origin "${newBranch}"

    prParams=(--fill --base ${sourceBranch})
    if ! [ -z "${BUILD_USER}" ]; then
      prParams+=(--assignee "${BUILD_USER}")
    fi
    gh pr create ${prParams[@]}

    if [ "$autoMerge" = "1" ]; then
      gh pr merge --merge
    fi

    echo ""; echo "--> finished pushing repo '${repo}'";
  done
  cd "${currentDir}"
}

function runAllRepoUpdate {
  ghAuth
  json=$(gh repo list axonivy --no-archived --source --json sshUrl --limit 400)
  gitUris=$(echo $json | grep -o "git[^\"]*\.git" | tr "\n" " ")
  repos=($gitUris)
  runRepoUpdate ${1} ${repos[@]}
}

function showDiff(){
  git --no-pager status -s | sed 's/.* //g' | while
  read file; do
    git --no-pager diff HEAD "$file"
    echo "..."
  done
}

function ghAuth(){
  if [ -f "${GITHUB_TOKEN_FILE}" ]; then
    echo "Login github cli with github token in file from variable 'GITHUB_TOKEN_FILE': ${GITHUB_TOKEN_FILE}"
    gh auth login --with-token < ${GITHUB_TOKEN_FILE}
  else
    echo "Do not login to github cli because variable 'GITHUB_TOKEN_FILE' does not contain a valid file path: ${GITHUB_TOKEN_FILE}"
  fi
}
