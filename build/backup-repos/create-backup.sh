#!/bin/bash
set -e

#
# Usage:
#    Linux:   Run this script ./create-escrow-backup.sh [<folder_to_copy_to>]
#    Windows: Open Git Bash shell and run this script ./create-escrow-backup.sh [<folder_to_copy_to>]
#
# Prerequisite:
#    Make sure you have your client ssh key(s) registered in bitbucket and GitHub.
#    Maybe also think about setting a key lifetime so you don't have to re-enter the password all the time.
#
# Param 1: existing target folder where the escrow file should be copied to - optional (no copy if not specified)
# 

if [ $# -eq 0 ]; then
  echo "No target folder specified, will not copy escrow file"
  targetFolder=''
elif [ "$1" == '-h' ] || [ "$1" == '--h' ] || [ "$1" == '--help' ]; then
  echo "Usage: ./create-escrow-backup.sh [<folder_to_copy_to>]"
  exit 0
elif [ -d "$1" ]; then
  targetFolder=$1
else
  echo "Specified target folder '$1' does not exist - exiting"
  exit 1
fi

DATE=`date '+%Y%m%d%H%M%S'`
thisFilePath="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
gitHubAxonIvyRepo='github.com:axonivy'

tmpDir=tmp
gitDir=git

function cloneRepository()
{
  repository="$1"
  project="$2"
  git clone -n git@$repository/$project.git $tmpDir/$gitDir/$project
}

function backup_escrow()
{
  cloneRepository $gitHubAxonIvyRepo 'core'
  cloneRepository $gitHubAxonIvyRepo 'core-7'
  cloneRepository $gitHubAxonIvyRepo 'addons'
  cloneRepository $gitHubAxonIvyRepo 'case-map-ui'
  cloneRepository $gitHubAxonIvyRepo 'core-icons'
  cloneRepository $gitHubAxonIvyRepo 'p2-targetplatform'
  cloneRepository $gitHubAxonIvyRepo 'core-primefaces-themes'
  cloneRepository $gitHubAxonIvyRepo 'thirdparty-libs'
  cloneRepository $gitHubAxonIvyRepo 'doc-images'
  cloneRepository $gitHubAxonIvyRepo 'engine-cockpit'
  cloneRepository $gitHubAxonIvyRepo 'engine-launchers'
  cloneRepository $gitHubAxonIvyRepo 'birt-project-report'
  cloneRepository $gitHubAxonIvyRepo 'rules'
  cloneRepository $gitHubAxonIvyRepo 'ulc-ria'
  cloneRepository $gitHubAxonIvyRepo 'webeditor'
  cloneRepository $gitHubAxonIvyRepo 'ws-axis'
  cloneRepository $gitHubAxonIvyRepo 'inscription-client'
  cloneRepository $gitHubAxonIvyRepo 'infra'
  cloneRepository $gitHubAxonIvyRepo 'license-order'
  cloneRepository $gitHubAxonIvyRepo 'maven-plugins'
  cloneRepository $gitHubAxonIvyRepo 'performance-tests'
  cloneRepository $gitHubAxonIvyRepo 'pipeline-shared-libs'
  cloneRepository $gitHubAxonIvyRepo 'security-scan'
  cloneRepository $gitHubAxonIvyRepo 'cluster-tests'
  cloneRepository $gitHubAxonIvyRepo 'test-webservices'
  cloneRepository $gitHubAxonIvyRepo 'dev-workflow-ui'
  cloneRepository $gitHubAxonIvyRepo 'market'
  cloneRepository $gitHubAxonIvyRepo 'process-editor-client'
  cloneRepository $gitHubAxonIvyRepo 'process-editor-core'
  cloneRepository $gitHubAxonIvyRepo 'project-build-plugin'
  cloneRepository $gitHubAxonIvyRepo 'project-build-examples'
  cloneRepository $gitHubAxonIvyRepo 'build-container'
  cloneRepository $gitHubAxonIvyRepo 'docker-image'
  cloneRepository $gitHubAxonIvyRepo 'ivymx'
  cloneRepository $gitHubAxonIvyRepo 'web-tester'
  cloneRepository $gitHubAxonIvyRepo 'bpm-beans'
  cloneRepository $gitHubAxonIvyRepo 'extensions-sample'
  cloneRepository $gitHubAxonIvyRepo 'webtest-sample'
  cloneRepository $gitHubAxonIvyRepo 'cxf-feature-sample'
  cloneRepository $gitHubAxonIvyRepo 'extension-demos'
  cloneRepository $gitHubAxonIvyRepo 'docker-samples'
  cloneRepository $gitHubAxonIvyRepo 'website-developer'
  cloneRepository $gitHubAxonIvyRepo 'website-p2'
  cloneRepository $gitHubAxonIvyRepo 'theia-ide'
  cloneRepository $gitHubAxonIvyRepo 'vscode-extensions'
}

function compressAllFiles()
{
  echo "compressing all cloned repositories"
  pushd .
  cd $tmpDir/$gitDir
  tar -cpzf ../ivy_escrow.$DATE.tar.gz *
  popd
}

function copyFiles()
{
  pushd .
  cd $tmpDir/$gitDir/ivy-core
  versionLTS80=`git tag -l --sort -version:refname | grep 8.0 | head -n 1`
  versionLE=`git tag -l --sort -version:refname | head -n 1`
  popd
  pushd .
  cd $tmpDir/$gitDir/ivy-core-branch-70
  versionLTS70=`git tag -l --sort -version:refname | grep 7.0 | head -n 1`
  popd

  echo "copying $tmpDir/ivy_escrow.$date.tar.gz to folder $1"
  cp -f $tmpDir/ivy_escrow.$DATE.tar.gz $1
  echo "copying $thisFilePath/README.txt to folder $1"
  cp -f $thisFilePath/README.txt $1
  sed -i -e "s/\__DATE__/${DATE}/" -e "s/\__versionLTS70__/${versionLTS70}/" -e "s/\__versionLTS80__/${versionLTS80}/" -e "s/\__versionLE__/${versionLE}/" $1/README.txt
}

rm -rf $tmpDir

backup_escrow
compressAllFiles

if [ $targetFolder != '' ]; then
  copyFiles $targetFolder
  rm -rf $tmpDir
else
  rm -rf $tmpDir/$gitDir
fi

