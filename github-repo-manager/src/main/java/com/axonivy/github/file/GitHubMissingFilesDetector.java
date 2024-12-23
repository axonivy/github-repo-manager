package com.axonivy.github.file;

import java.io.IOException;
import java.io.Reader;
import java.util.List;
import java.util.Objects;

import org.apache.commons.io.IOUtils;
import org.apache.commons.io.input.CharSequenceReader;
import org.kohsuke.github.*;

import com.axonivy.github.DryRun;
import com.axonivy.github.GitHubProvider;
import com.axonivy.github.file.GitHubFiles.FileMeta;

public class GitHubMissingFilesDetector {

  private static final String GITHUB_ORG = ".github";
  private static final String BRANCH_PREFIX = "refs/heads/";
  private static final Logger LOG = new Logger();
  private boolean isNotSync;
  private final FileReference reference;
  private final GitHub github;
  private final GHUser ghActor;

  public GitHubMissingFilesDetector(FileMeta fileMeta, String user) throws IOException {
    Objects.requireNonNull(fileMeta);
    this.reference = new FileReference(fileMeta);
    this.github = GitHubProvider.getGithubToken();
    this.ghActor = github.getUser(user);
  }

  public int requireFile(List<String> orgNames) throws IOException {
    Objects.requireNonNull(orgNames);
    LOG.info("Working on organizations: {0}.", orgNames);
    for (var orgName : orgNames) {
      var org = github.getOrganization(orgName);
      for (var repo : List.copyOf(org.getRepositories().values())) {
        missingFile(repo);
      }
    }
    if (isNotSync) {
      LOG.error("At least one repository has no {0}.", reference.meta().filePath());
      LOG.error("Add a {0} manually or run the build without DRYRUN to add {0} to the repository.",
          reference.meta().filePath());
      return 1;
    }
    return 0;
  }

  private void missingFile(GHRepository repo) throws IOException {
    if (GITHUB_ORG.equals(repo.getName())) {
      return;
    }
    if (repo.isFork()) {
      return;
    }
    if (repo.isPrivate() || repo.isArchived()) {
      LOG.info("Repo {0} is {1}.", repo.getFullName(), repo.isPrivate() ? "private" : "archived");
      return;
    }

    var foundFile = getFileContent(reference.meta().filePath(), repo);
    if (foundFile != null) {
      if (hasSimilarContent(foundFile)) {
        LOG.info("Repo {0} has {1}.", repo.getFullName(), foundFile.getName());
      } else {
        handleOtherContent(repo);
      }
    } else {
      handleMissingFile(repo);
    }
  }

  private GHContent getFileContent(String path, GHRepository repo) {
    try {
      return repo.getFileContent(path);
    } catch (Exception e) {
      LOG.error("File {0} in repo {1} is not found.", path, repo.getFullName());
      return null;
    }
  }

  private boolean hasSimilarContent(GHContent existingFile) throws IOException {
      Reader targetContent = new CharSequenceReader(new String(loadReferenceFileContent(existingFile.getGitUrl())));
    Reader actualContent;
    try (var inputStream = existingFile.read()) {
      actualContent = new CharSequenceReader(new String(inputStream.readAllBytes()));
    }
    return IOUtils.contentEqualsIgnoreEOL(targetContent, actualContent);
  }

  private void handleMissingFile(GHRepository repo) throws IOException {
    try {
      if (DryRun.is()) {
        isNotSync = true;
        LOG.info("DRYRUN: ");
      } else {
        addMissingFile(repo);
      }
      LOG.info("Repo {0} {1} synced.", repo.getFullName(), reference.meta().filePath());
    } catch (IOException ex) {
      LOG.error("Cannot add {0} to repo {1}.", repo.getFullName(), reference.meta().filePath());
      throw ex;
    }
  }

  private void addMissingFile(GHRepository repo) throws IOException {
    var defaultBranch = repo.getBranch(repo.getDefaultBranch());
    String refURL = createBranchIfMissing(repo, BRANCH_PREFIX + reference.meta().branchName(), defaultBranch.getSHA1());

    repo.createContent()
            .branch(refURL)
            .path(reference.meta().filePath())
            .content(loadReferenceFileContent(repo.getUrl().toString()))
            .message(reference.meta().commitMessage())
            .commit();
    var pr = repo.createPullRequest(reference.meta().pullRequestTitle(), reference.meta().branchName(), repo.getDefaultBranch(), "");
    if (ghActor != null) {
      pr.setAssignees(ghActor);
    }
    pr.merge(reference.meta().commitMessage());
  }

  private static String createBranchIfMissing(GHRepository repo, String branchName, String sha) throws IOException {
    try {
      var existedRef = repo.getRef(branchName);
      if (existedRef != null && existedRef.getRef().endsWith(branchName)) {
        return existedRef.getRef();
      } else {
        repo.createRef(branchName, sha);
      }
    } catch (IOException e) {
      LOG.info("Create new ref failed, try one more with {0}", branchName);
      return repo.createRef(branchName, sha).getRef();
    }
    return branchName;
  }

  private void handleOtherContent(GHRepository repo) throws IOException {
    try {
      if (DryRun.is()) {
        isNotSync = true;
        LOG.info("DRYRUN: ");
        LOG.info("Repo {0} has {1} but the content is different from required file {2}.",
          repo.getFullName(), reference.meta().filePath(), reference.meta().filePath());
      } else {
        updateFile(repo);
        LOG.info("Repo {0} {1} synced.", repo.getFullName(), reference.meta().filePath());
      }
    } catch (IOException ex) {
      LOG.error("Cannot update {1} in repo {0}.", repo.getFullName(), reference.meta().filePath());
      throw ex;
    }
  }

  private void updateFile(GHRepository repo) throws IOException {
    var headBranch = repo.getBranch(repo.getDefaultBranch());
    String refURL = createBranchIfMissing(repo, BRANCH_PREFIX + reference.meta().branchName(), headBranch.getSHA1());
    repo.getFileContent(reference.meta().filePath(), refURL)
            .update(loadReferenceFileContent(repo.getUrl().toString()),
                    reference.meta().commitMessage(),
                    refURL
            );
    var pr = repo.createPullRequest(
            reference.meta().pullRequestTitle(),
            refURL,
            repo.getDefaultBranch(),
            ""
    );
    if (ghActor != null) {
      pr.setAssignees(ghActor);
      // we open a PR; but auto-merging of it should be avoided
    }
  }

  protected byte[] loadReferenceFileContent(String repoURL) throws IOException {
    return reference.content();
  }
}
