package com.axonivy.github;

import java.util.ArrayList;
import java.util.List;

public class GitHubRepos {

  public static List<String> repos(String version) {
    return REPOS;
  }

  public static final List<String> REPOS_TO_BRANCH = new ArrayList<>(List.of("core"));

  public static final List<String> REPOS_TO_TAG = new ArrayList<>(List.of(
      "p2-targetplatform",
      "engine-launchers",
      "core-icons"));

  public static final List<String> REPOS_TO_BRANCH_AND_TAG = List.of(
      "engine-cockpit",
      "dev-workflow-ui",
      "doc",
      "demo-projects",
      "primefaces-themes",
      "process-editor",
      "form-editor",
      "ui-components",
      "doc-images",
      "case-map-editor",
      "thirdparty-libs",
      "project-build-examples",
      "vscode-designer",
      "runtimelog-view",
      "cms-editor",
      "dataclass-editor",
      "variable-editor",
      "database-editor",
      "role-editor",
      "user-editor",
      "persistence-editor",
      "restclient-editor",
      "webservice-editor");

  private static final List<String> REPOS = new ArrayList<>(List.of("project-build-plugin"));

  static {
    REPOS.addAll(REPOS_TO_BRANCH_AND_TAG);
    REPOS.addAll(REPOS_TO_BRANCH);
    REPOS.addAll(REPOS_TO_TAG);

    REPOS_TO_BRANCH.addAll(REPOS_TO_BRANCH_AND_TAG);
    REPOS_TO_TAG.addAll(REPOS_TO_BRANCH_AND_TAG);
  }
}
