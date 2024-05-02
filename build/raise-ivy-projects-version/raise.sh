#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE}" )" && pwd )"


engineUrl=https://dev.axonivy.com/permalink/dev/axonivy-engine.zip
if [ ! -z "$1" ]; then
  engineUrl=$1
fi

# do not convert these projects:
declare -A exclusions=( 
  ["core.git"]="doc/screenshots/designer/screenshots/additionalProjects/oldVersionProject" 
)

workDir=$(mktemp -d -t projectConvertXXX)

sourceBranch='master'
uuid=$(date +%s%N)
newBranch="raise-ivy-project-version-${uuid}"


commitMessage="Raise ivy projects to latest version"

source "${DIR}/../raiseRepo.sh"

downloadEngine(){
  if ! [ -d "${workDir}/engine" ]; then
    wget -P "${workDir}" "${engineUrl}"
    zipped=$(find "${workDir}" -maxdepth 1 -name "*.zip")
    unzip -qq "${zipped}" -d "${workDir}/engine"
    rm "${zipped}"
  fi
  jar="*thirdparty*.jar"
  if [ -z "$(ls ${workDir}/engine/dropins/${jar})" ]; then
    curl --output ${workDir}/engine/p2.zip https://drone.ivyteam.io/unzip/maven/prefixed/ivy-core/ch.ivyteam.ivy/ch.ivyteam.ivy.core.p2/${ivyVersion}-SNAPSHOT
    unzip -j ${workDir}/engine/p2.zip plugins/ch.ivyteam.ivy.bpm.exec.thirdparty* -d ${workDir}/engine/dropins 
  fi
}
clean(){
  rm -rf "${workDir}"
}

raiseProjects() {
  gitDir=$(pwd)
  gitName=$(basename ${gitDir})
  exclude="${exclusions[${gitName}]}"
  echo "Searching projects in ${gitDir}: excluding ${exclude}"
  projects=()
  for ivyPref in `find ${gitDir} -name "ch.ivyteam.ivy.designer.prefs"`; do
    project=$(dirname $(dirname $ivyPref))
    if ! [ -f "${project}/pom.xml" ]; then
      continue # prefs file not in natural project structure
    fi
    if [[ $project == *"/work/"* ]]; then
      continue # temporary workspace artifact
    fi
    if ! [ -z "${exclude}" ]; then
      if [[ $project == *"${exclude}"* ]]; then
        echo "Filtering: ${project} by exclusion pattern"
        continue # 
      fi
    fi

    projects+=("${project}")
  done
  echo "Collected projects: ${projects[@]}"

  downloadEngine
  ${workDir}/engine/bin/EngineConfigCli migrate-project ${projects[@]}
  git add . #include new+moved files!
}

updateProjectRepos() {
  projectRepos=(
    "git@github.com:axonivy/core.git"
    "git@github.com:axonivy-market/demo-projects.git"
    "git@github.com:axonivy/engine-cockpit.git"
    "git@github.com:axonivy/dev-workflow-ui.git"
    "git@github.com:axonivy/project-build-examples.git"
    "git@github.com:axonivy/cluster-tests.git"
    "git@github.com:axonivy/process-editor-client.git"
    "git@github.com:axonivy/inscription-client.git"
    "git@github.com:axonivy/vscode-extensions.git"
  )
  runRepoUpdate 'raiseProjects' "${projectRepos[@]}"
}

withLog() { # log to file and stdout (treasure logs in order to review/archive them)
  logFunction="$1"
  rm "${DIR}/conversion*.txt" # clean
  consoleLog="${DIR}/conversionConsole.txt"
  touch "$consoleLog"
  "${logFunction}" > "${consoleLog}" 2> "${DIR}/conversionError.txt" & echo "running conversion with pid $!"
  convertRun=$!
  sleep 2
  tail -f "--pid=${convertRun}" "$consoleLog" # print logs from file
}

downloadEngine
withLog updateProjectRepos
# because git writes on stderr
sed '/^remote/d' "${DIR}/conversionError.txt" > "${DIR}/conversionError.txt"
clean
