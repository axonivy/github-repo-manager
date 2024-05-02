package com.axonivy.github.file;

import java.io.IOException;
import java.io.Reader;
import java.text.MessageFormat;
import java.util.List;
import java.util.Objects;

import org.apache.commons.io.IOUtils;
import org.apache.commons.io.input.CharSequenceReader;
import org.kohsuke.github.GHContent;
import org.kohsuke.github.GHRepository;

import com.axonivy.github.DryRun;
import com.axonivy.github.GitHubProvider;
import com.axonivy.github.file.GitHubFiles.FileMeta;

public class GitHubMissingFilesDetector {

  private static final String GITHUB_ORG = ".github";
  private final byte[] fileContent;
  private boolean isMissingRequiredFile;
  private List<String> workingOrgs;
  private FileMeta requestFileMeta;

  public GitHubMissingFilesDetector(FileMeta fileMeta, String... workingOrg) throws IOException {
    Objects.requireNonNull(fileMeta);
    Objects.requireNonNull(workingOrg);
    this.requestFileMeta = fileMeta;
    this.workingOrgs = List.of(workingOrg);
    try (var is = GitHubMissingFilesDetector.class.getResourceAsStream(requestFileMeta.filePath())) {
      if (is == null) {
        throw new IOException(requestFileMeta.filePath() + " file not found");
      }
      this.fileContent = IOUtils.toByteArray(is);
    }
  }

  public int checkMissingFile() throws IOException {
    var github = GitHubProvider.get();
    printInfoMessage("Working on organizations: {0}.", workingOrgs);
    for (var orgName : workingOrgs) {
      var org = github.getOrganization(orgName);
      for (var repo : List.copyOf(org.getRepositories().values())) {
        checkMissingFile(repo);
      }
    }
    if (isMissingRequiredFile) {
      printErrorMessage("At least one repository has no {0}.", requestFileMeta.filePath());
      printErrorMessage("Add a {0} manually or run the build without DRYRUN to add {0} to the repository.",
          requestFileMeta.filePath());
      return -1;
    }
    return 0;
  }

  private void checkMissingFile(GHRepository repo) throws IOException {
    if (repo.isPrivate() || repo.isArchived()) {
      printInfoMessage("Repo {0} is {1}.", repo.getFullName(), repo.isPrivate() ? "private" : "archived");
      return;
    }

    var foundFile = getFileContent(requestFileMeta.filePath(), repo);
    if (foundFile != null) {
      if (!hasSimilarContent(foundFile)) {
        printInfoMessage("Repo {0} has {1} but the content is different from required file {2}.", repo.getFullName(),
            foundFile.getName(), requestFileMeta.filePath());
        isMissingRequiredFile = true;
      } else {
        printInfoMessage("Repo {0} has {1}.", repo.getFullName(), foundFile.getName());
      }
    } else if (!GITHUB_ORG.equals(repo.getName())) {
      addMissingFile(repo);
    }
  }

  private GHContent getFileContent(String path, GHRepository repo) {
    try {
      return repo.getFileContent(path);
    } catch (Exception e) {
      printErrorMessage("File {0} in repo {1} is not found.", path, repo.getFullName());
      return null;
    }
  }

  private boolean hasSimilarContent(GHContent existingFile) throws IOException {
    Reader targetContent = new CharSequenceReader(new String(fileContent));
    Reader actualContent = new CharSequenceReader(new String(existingFile.read().readAllBytes()));
    return IOUtils.contentEqualsIgnoreEOL(targetContent, actualContent);
  }

  private void addMissingFile(GHRepository repo) throws IOException {
    try {
      if (DryRun.is()) {
        isMissingRequiredFile = true;
        printInfoMessage("DRYRUN: ");
      } else {
        var defaultBranch = repo.getBranch(repo.getDefaultBranch());
        var sha1 = defaultBranch.getSHA1();
        repo.createRef("refs/heads/" + requestFileMeta.branchName(), sha1);
        repo.createContent().branch(requestFileMeta.branchName()).path(requestFileMeta.filePath()).content(fileContent)
            .message(requestFileMeta.commitMessage()).commit();
        var pr = repo.createPullRequest(requestFileMeta.pullRequestTitle(), requestFileMeta.branchName(), repo.getDefaultBranch(), "");
        pr.merge(requestFileMeta.commitMessage());
      }
      printInfoMessage("Repo {0} {1} added.", repo.getFullName(), requestFileMeta.filePath());
    } catch (IOException ex) {
      printErrorMessage("Cannot add {0} to repo {1}.", repo.getFullName(), requestFileMeta.filePath());
      throw ex;
    }
  }

  private void printInfoMessage(String pattern, Object... arguments) {
    System.out.println(MessageFormat.format(pattern, arguments));
  }

  private void printErrorMessage(String pattern, Object... arguments) {
    System.err.println(MessageFormat.format(pattern, arguments));
  }
}
