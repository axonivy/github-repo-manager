package com.axonivy.github.file;

import static com.axonivy.github.file.GitHubFiles.CODE_OF_CONDUCT;
import static com.axonivy.github.file.GitHubFiles.LICENSE;
import static com.axonivy.github.file.GitHubFiles.SECURITY;

import java.io.IOException;

public class GitHubMissingFiles {

  private static final String AXONIVY_ORG = "axonivy";
  private static final String MARKET_ORG = "axonivy-market";

  public static void main(String[] args) throws IOException {
    int missingStatus = 0;
    var githubMissingFiles = new GitHubMissingFilesDetector(LICENSE, AXONIVY_ORG);
    var returnedStatus = githubMissingFiles.checkMissingFile();
    missingStatus = returnedStatus != 0 ? returnedStatus : missingStatus;

    githubMissingFiles = new GitHubMissingFilesDetector(SECURITY, MARKET_ORG);
    returnedStatus = githubMissingFiles.checkMissingFile();
    missingStatus = returnedStatus != 0 ? returnedStatus : missingStatus;

    githubMissingFiles = new GitHubMissingFilesDetector(CODE_OF_CONDUCT, MARKET_ORG);
    returnedStatus = githubMissingFiles.checkMissingFile();
    missingStatus = returnedStatus != 0 ? returnedStatus : missingStatus;
    System.exit(missingStatus);
  }

}
