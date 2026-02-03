package com.axonivy.github;

import java.util.ArrayList;
import java.util.List;

public class GitHubRepos {

  public static List<String> repos(String version) {
    return REPOS;
  }


  public static final List<String> REPOS_TO_BRANCH = List.of(
          "rules",
          "engine-cockpit",
          "dev-workflow-ui",
          "core",
          "doc",
          "demo-projects",
          "primefaces-themes",
          "process-editor",
          "form-editor",
          "ui-components",
          "neo",
          "doc-images",
          "case-map-ui",
          "case-map-editor",
          "thirdparty-libs",
          "swagger-ui-ivy",
          "monaco-yaml-ivy",
          "project-build-examples",
          "vscode-designer",
          "runtimelog-view",
          "cms-editor",
          "dataclass-editor",
          "variable-editor",
          "database-editor",
          "role-editor",
          "user-editor",
          "restclient-editor"
          );

  public static final List<String> REPOS_TO_TAG = new ArrayList<>();

  private static final List<String> REPOS = new ArrayList<>();

  static {
    REPOS_TO_TAG.addAll(REPOS_TO_BRANCH);
    REPOS_TO_TAG.addAll(List.of(
        "p2-targetplatform",
        "engine-launchers",
        "core-icons"));
    REPOS.addAll(REPOS_TO_TAG);
    REPOS.add("project-build-plugin");
  }
}
