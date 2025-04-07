package com.axonivy.github;

import java.util.ArrayList;
import java.util.List;

public class GitHubRepos {

  public static List<String> repos(String version) {
    if (version.startsWith("7")) {
      return REPOS7;
    } else if (version.startsWith("8")) {
      return REPOS8;
    }
    return REPOS;
  }

  public static final List<String> REPOS7 = List.of("core-7", "ulc-ria", "admin-ui", "rules", "maven-plugins", "webeditor");

  public static final  List<String> REPOS8 = List.of(
          "rules",
          "engine-cockpit",
          "maven-plugins",
          "webeditor",
          "core",
          "primefaces-themes",
          "ws-axis",
          "case-map-ui",
          "thirdparty-libs",
          "p2-targetplatform",
          "doc-images",
          "engine-launchers",
          "core-icons");

  public static final List<String> REPOS_TO_BRANCH = List.of(
          "rules",
          "engine-cockpit",
          "dev-workflow-ui",
          "webeditor",
          "core",
          "doc",
          "primefaces-themes",
          "process-editor-client",
          "process-editor-core",
          "config-editor-client",
          "form-editor-client",
          "ui-components",
          "dataclass-editor-client",
          "neo",
          "doc-images",
          "case-map-ui",
          "thirdparty-libs",
          "swagger-ui-ivy",
          "monaco-yaml-ivy",
          "project-build-examples",
          "vscode-extensions");

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
