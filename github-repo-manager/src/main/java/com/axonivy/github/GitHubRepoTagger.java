package com.axonivy.github;

import java.io.IOException;

import org.kohsuke.github.GHRepository;

public class GitHubRepoTagger {

  public static void main(String[] args) {
    var github = GitHubProvider.get();

    var dryRun = DryRun.is();
    var branch = args[0];
    var tag = args[1];

    System.out.println("Start GitHub repository tagging");
    System.out.println("dryRun: " + dryRun);
    System.out.println("branch: " + branch);
    System.out.println("tag: " + tag);
    try {
      for (var repo : GitHubRepos.REPOS_TO_TAG) {
        var r = github.getRepository("axonivy/" + repo);
        new Tagger(r, dryRun, branch, tag).run();
      }
    } catch (Exception ex) {
      throw new RuntimeException(ex);
    }
  }

  public static final class Tagger {

    private final GHRepository repo;
    private final boolean dryRun;
    private final String branch;
    private final String tag;
    private final String message;

    public Tagger(GHRepository repo, boolean dryRun, String branch, String tag) {
      this.repo = repo;
      this.dryRun = dryRun;
      this.branch = branch;
      this.tag = tag;
      this.message = tag;
    }

    public void run() {
      try {
        if (repo.isArchived()) {
          System.out.println("Skipping archived repo " + repo.getFullName());
          return;
        }
        if (!repo.getBranches().containsKey(branch)) {
          var defaultBranch = repo.getDefaultBranch();
          System.out.println("Repo " + repo.getFullName() + " has no " + branch + " branch, taking " + defaultBranch);
          return;
        }

        var ghBranch = repo.getBranch(branch);
        var sha1 = ghBranch.getSHA1();
        if (dryRun) {
          System.out.print("DRYRUN: ");
        }
        System.out.println("Create tag " + tag + " on " + repo.getFullName() + " ~ " + branch + " ~ " + sha1);
        if (!dryRun) {
          // we create a release and delete it again
          // but the annoated tag still exists
          // I don't know how I could create a annotated tag elseway
          repo.createRelease(tag)
            .name(message)
            .commitish(sha1)
            .create()
            .delete();
        }
      } catch (IOException ex) {
        throw new RuntimeException(ex);
      }
    }
  }
}
