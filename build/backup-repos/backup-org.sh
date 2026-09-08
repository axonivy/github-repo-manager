#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
org="${1:-${GITHUB_ORG:-axonivy}}"
backup_dir="${BACKUP_DIR:-${DIR}/target/backup/${org}}"

mkdir -p "${backup_dir}"
cd "${backup_dir}"

backupRepo() {
  local repo_name="$1"
  local repo_url="https://github.com/${org}/${repo_name}.git"
  local mirror_dir="${repo_name}.git"

  if [ -d "${mirror_dir}" ]; then
    echo "Updating mirror ${org}/${repo_name}"
    git -C "${mirror_dir}" remote update --prune
  else
    echo "Cloning mirror ${org}/${repo_name}"
    git clone --mirror "${repo_url}" "${mirror_dir}"
  fi
}

gh api --paginate "orgs/${org}/repos?per_page=100&type=all" \
  --jq '.[] | select(.archived == false and .fork == false) | .name' |
while IFS= read -r repo_name; do
  backupRepo "${repo_name}"
done
