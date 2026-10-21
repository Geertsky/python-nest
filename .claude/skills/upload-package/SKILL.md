---
name: upload-package
description: Upload a locally built conda package to the geertsky anaconda channel. Takes the package name as argument (e.g. /upload-package blivet). Only on the user's explicit request.
argument-hint: <package-name>
disable-model-invocation: true
---

# Upload a package to the geertsky channel

Argument: `$ARGUMENTS` is the package name. If empty, stop and ask.

Only run this when the user explicitly asked for the upload. Never as a side effect of a build.

1. Find the package file: the newest `$ARGUMENTS-*.conda` under `~/miniforge3/conda-bld/linux-64/` (or `noarch/`), by mtime. Show the user the full path, and confirm it before uploading since an upload publishes the package.
2. Activate conda base: run `conda deactivate` until `conda info` shows `active environment : base`, chained in the same Bash call:
   ```bash
   while [ -n "$CONDA_DEFAULT_ENV" ] && [ "$CONDA_DEFAULT_ENV" != "base" ]; do conda deactivate; done; anaconda upload <path to package>
   ```
3. Report the result. If `anaconda` reports it is not logged in, ask the user to run `! anaconda login`.
