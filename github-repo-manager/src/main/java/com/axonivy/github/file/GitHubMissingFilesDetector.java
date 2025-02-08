package com.axonivy.github.file;

import java.io.IOException;
import java.io.Reader;
import java.util.List;
import java.util.Objects;

import org.apache.commons.io.IOUtils;
import org.apache.commons.io.input.CharSequenceReader;
import org.kohsuke.github.GHContent;
import org.kohsuke.github.GHRepository;
import org.kohsuke.github.GHUser;
import org.kohsuke.github.GitHub;

import com.axonivy.github.DryRun;
import com.axonivy.github.GitHubProvider;
import com.axonivy.github.file.GitHubFiles.FileMeta;

public class GitHubMissingFilesDetector {

  private static final Logger LOG = new Logger();
  private boolean isNotSync;
  private final FileReference reference;
  private final GitHub github;
  private GHUser ghActor;

  public GitHubMissingFilesDetector(FileMeta fileMeta, String user) throws IOException {
    Objects.requireNonNull(fileMeta);
    this.reference = new FileReference(fileMeta);
    this.github = GitHubProvider.get();
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
      return -1;
    }
    return 0;
  }

  private void missingFile(GHRepository repo) throws IOException {
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
        handleOtherContent(repo, foundFile);
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
    Reader targetContent = new CharSequenceReader(new String(reference.content()));
    Reader actualContent = new CharSequenceReader(new String(existingFile.read().readAllBytes()));
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
    var sha1 = defaultBranch.getSHA1();
    repo.createRef("refs/heads/" + reference.meta().branchName(), sha1);
    repo.createContent()
      .branch(reference.meta().branchName())
      .path(reference.meta().filePath())
      .content(reference.content())
      .message(reference.meta().commitMessage())
      .commit();
    var pr = repo.createPullRequest(reference.meta().pullRequestTitle(), reference.meta().branchName(), repo.getDefaultBranch(), "");
    if (ghActor != null) {
      pr.setAssignees(ghActor);
    }
    pr.merge(reference.meta().commitMessage());
  }

  private void handleOtherContent(GHRepository repo, GHContent foundFile) throws IOException {
    try {
      if (DryRun.is()) {
        isNotSync = true;
        LOG.info("DRYRUN: ");
        LOG.info("Repo {0} has {1} but the content is different from required file {2}.",
          repo.getFullName(), foundFile.getName(), reference.meta().filePath());
      } else {
        updateFile(repo, foundFile);
        LOG.info("Repo {0} {1} synced.", repo.getFullName(), reference.meta().filePath());
      }
    } catch (IOException ex) {
      LOG.error("Cannot update {1} in repo {0}.", repo.getFullName(), reference.meta().filePath());
      throw ex;
    }
  }

  private void updateFile(GHRepository repo, GHContent foundFile) throws IOException {
    var headBranch = repo.getBranch(repo.getDefaultBranch());
    repo.createRef("refs/heads/" + reference.meta().branchName(), headBranch.getSHA1());
    foundFile.update(reference.content(),
      reference.meta().commitMessage(),
      reference.meta().branchName()
    );
    var pr = repo.createPullRequest(
      reference.meta().pullRequestTitle(),
      reference.meta().branchName(),
      repo.getDefaultBranch(),
      ""
    );
    if (ghActor != null) {
      pr.setAssignees(ghActor);
      // we open a PR; but auto-merging of it should be avoided
    }
  }

}
