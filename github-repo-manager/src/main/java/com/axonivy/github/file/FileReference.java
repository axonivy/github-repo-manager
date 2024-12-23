package com.axonivy.github.file;

import com.axonivy.github.file.GitHubFiles.FileMeta;
import org.apache.commons.io.IOUtils;

import java.io.IOException;

public class FileReference {
  FileMeta meta;

  public FileReference(FileMeta meta) throws IOException {
    this.meta = meta;
  }

  private static byte[] load(FileMeta meta) throws IOException {
    try (var is = GitHubMissingFilesDetector.class.getResourceAsStream(meta.filePath())) {
      if (is == null) {
        throw new IOException(meta.filePath() + " file not found");
      }
      return IOUtils.toByteArray(is);
    }
  }

  public FileMeta meta() {
    return meta;
  }

  public byte[] content() throws IOException {
    return load(meta);
  }
}