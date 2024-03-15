#!/bin/bash
set -e

shopt +s globstar
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

function searchReplaceOfOurRepos {
  repos=(
    "git@github.com:axonivy-market/demo-projects.git"
    "git@github.com:axonivy-market/basic-workflow-ui.git"

    "git@github.com:axonivy/admin-ui.git"
    "git@github.com:axonivy/birt-project-report.git"
    "git@github.com:axonivy/branding-images.git"
    "git@github.com:axonivy/build-container.git"
    "git@github.com:axonivy/bundled-elasticsearch.git"
    "git@github.com:axonivy/case-map-ui.git"
    "git@github.com:axonivy/cluster-tests.git"
    "git@github.com:axonivy/compare-uuid-vs-long.git"
    "git@github.com:axonivy/config-editor-client.git"
    "git@github.com:axonivy/core-7.git"
    "git@github.com:axonivy/core-icons.git"
    "git@github.com:axonivy/core.git"
    "git@github.com:axonivy/dev-workflow-ui.git"
    "git@github.com:axonivy/dev.axonivy.com.git"
    "git@github.com:axonivy/devcontainer-features.git"
    "git@github.com:axonivy/doc-images.git"
    "git@github.com:axonivy/docker-image.git"
    "git@github.com:axonivy/docker-integration-tests.git"
    "git@github.com:axonivy/docker-samples.git"
    "git@github.com:axonivy/dummy-keystores.git"
    "git@github.com:axonivy/engine-cockpit.git"
    "git@github.com:axonivy/engine-launchers.git"
    "git@github.com:axonivy/expressive-schema-module.git"
    "git@github.com:axonivy/extension-demos.git"
    "git@github.com:axonivy/extensions-sample.git"
    "git@github.com:axonivy/form-editor-client.git"
    "git@github.com:axonivy/github-repo-manager.git"
    "git@github.com:axonivy/hibernate-envers-sample.git"
    "git@github.com:axonivy/infra.git"
    "git@github.com:axonivy/inscription-client.git"
    "git@github.com:axonivy/issue-reproducer.git"
    "git@github.com:axonivy/ivymx.git"
    "git@github.com:axonivy/kubernetes-samples.git"
    "git@github.com:axonivy/license-order.git"
    "git@github.com:axonivy/maven-image-text-plugin.git"
    "git@github.com:axonivy/maven-jira-plugin.git"
    "git@github.com:axonivy/maven-plugins.git"
    "git@github.com:axonivy/maven-screenshot-html-plugin.git"
    "git@github.com:axonivy/maven-version-plugin.git"
    "git@github.com:axonivy/maven-windows-launcher-modifier-plugin.git"
    "git@github.com:axonivy/mavenizer.git"
    "git@github.com:axonivy/monaco-yaml-ivy.git"
    "git@github.com:axonivy/odata-converter.git"
    "git@github.com:axonivy/openvscode-server.git"
    "git@github.com:axonivy/p2-targetplatform.git"
    "git@github.com:axonivy/p2.axonivy.com.git"
    "git@github.com:axonivy/performance-tests.git"
    "git@github.com:axonivy/primefaces-example.git"
    "git@github.com:axonivy/primefaces-themes.git"
    "git@github.com:axonivy/process-editor-client.git"
    "git@github.com:axonivy/process-editor-core.git"
    "git@github.com:axonivy/product.ivyteam.io.git"
    "git@github.com:axonivy/project-build-examples.git"
    "git@github.com:axonivy/project-build-plugin.git"
    "git@github.com:axonivy/project-installer.git"
    "git@github.com:axonivy/rules.git"
    "git@github.com:axonivy/schema.git"
    "git@github.com:axonivy/security-scan.git"
    "git@github.com:axonivy/swagger-ui-ivy.git"
    "git@github.com:axonivy/test-webservices.git"
    "git@github.com:axonivy/thirdparty-libs.git"
    "git@github.com:axonivy/tls-connection-tester.git"
    "git@github.com:axonivy/ui-components.git"
    "git@github.com:axonivy/update.axonivy.com.git"
    "git@github.com:axonivy/vscode-extensions.git"
    "git@github.com:axonivy/web-tester.git"
    "git@github.com:axonivy/webeditor.git"
    "git@github.com:axonivy/ws-axis.git"
    "git@github.com:axonivy/ws-call-jax-ws.git"
  )
  runRepoUpdate 'updateSingleRepo' ${repos[@]}
}

function updateSingleRepo {
  echo "execute 'sed -i -E \"${sedRegexp}\" ${fileSelector}'"
  # Ignore exceptions here, because sed throw an error if no file matches
  set +e
  # likely not working on mac
  sed -i -E "${sedRegexp}" ${fileSelector} || { skipReason="sed failed"; return; }
  set -e
}

searchReplaceOfOurRepos
