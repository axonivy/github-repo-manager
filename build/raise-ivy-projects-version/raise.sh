#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE}" )" && pwd )"


engineUrl=https://dev.axonivy.com/permalink/dev/axonivy-engine.zip
if [ ! -z "$1" ]; then
  engineUrl=$1
fi
if [ $# -eq 1 ]; then
  echo "Parameter source branch required"
  exit
fi

# do not convert these projects:
declare -A exclusions=(   
  ["migration-test-projects.git"]="migrate-me"
)

workDir=$(mktemp -d -t projectConvertXXX)

sourceBranch=$2
echo "source branch to checkout repos $2"

uuid=$(date +%s%N)
newBranch="raise-ivy-project-version-${uuid}"


commitMessage="Raise ivy projects to latest version"

source "${DIR}/../raiseRepo.sh"

downloadEngine(){
  if ! [ -d "${workDir}/engine" ]; then
    wget -P "${workDir}" --progress=bar:force:noscroll "${engineUrl}"
    zipped=$(find "${workDir}" -maxdepth 1 -name "*.zip")
    unzip -qq "${zipped}" -d "${workDir}/engine"
    rm "${zipped}"
  fi
  jar="*thirdparty*.jar"
  if [ -z "$(ls ${workDir}/engine/dropins/${jar})" ]; then
    curl --output ${workDir}/engine/dropins/bpm.exec.thirdparty_le11.jar\
     https://p2.ivyteam.io/thirdparty-bpm/ch.ivyteam.ivy.bpm.exec.thirdparty_le11.jar
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
  for ivyPref in `find ${gitDir} -name ".ivyproject"`; do
    project=$(dirname $ivyPref)
    if ! [ -f "${project}/pom.xml" ]; then
      continue # project file not in natural project structure
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
  runAllRepoUpdate 'raiseProjects'
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
