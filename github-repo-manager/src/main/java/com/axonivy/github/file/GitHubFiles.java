package com.axonivy.github.file;

public interface GitHubFiles {

  FileMeta LICENSE = new FileMeta("LICENSE", "Add license", "Add_License",
      "Add Apache 2.0 license");
  FileMeta SECURITY = new FileMeta("SECURITY.md", "Add security file", "Add_Security",
      "Add Security.md file to repo");
  FileMeta CODE_OF_CONDUCT = new FileMeta("CODE_OF_CONDUCT.md", "Add code of conduct file",
      "Add_Code_of_Conduct_v2", "Add CODE_OF_CONDUCT.md file to repo");
  FileMeta CODE_OWNERS = new FileMeta(".github/CODEOWNERS", "Add code owner file",
          "Add_CODEOWNERS", "Add CODEOWNERS file to repo");

  record FileMeta(String filePath, String pullRequestTitle, String branchName, String commitMessage) {

    public String filePath() {
      return filePath;
    }

    public String pullRequestTitle() {
      return pullRequestTitle;
    }

    public String branchName() {
      return branchName;
    }

    public String commitMessage() {
      return commitMessage;
    }
  }

}
