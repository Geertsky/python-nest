---
name: build-recipe
description: Build one conda package recipe from this repo with rattler-build and publish it to the local conda-bld channel. Takes the package directory name as argument (e.g. /build-recipe blivet). Use when asked to build or rebuild a recipe/package.
argument-hint: <package-name>
---

# Build a recipe

Argument: `$ARGUMENTS` is the package directory in the repo root (e.g. `blivet`, `rpm-tools`). If it is empty or `<name>/recipe.yaml` does not exist, stop and ask.

`rattler-build` lives in the conda `base` environment. Run `conda deactivate` until `conda info` shows `active environment : base`. Shell state does not persist between Bash calls, so chain it in each command:

```bash
while [ -n "$CONDA_DEFAULT_ENV" ] && [ "$CONDA_DEFAULT_ENV" != "base" ]; do conda deactivate; done; <command>
```

Steps (stop at the first failure and show its output):

1. Build from the repo root:
   ```bash
   rattler-build build --recipe $ARGUMENTS/recipe.yaml --variant-config $ARGUMENTS/variants.yaml --output-dir output
   ```
2. Copy the new package(s) from `output/linux-64/` (or `output/noarch/` for noarch recipes) to the matching subdirectory of `~/miniforge3/conda-bld/`.
3. Re-index: `conda index ~/miniforge3/conda-bld`
4. Confirm availability: `conda search -c local $ARGUMENTS` lists the new version/build.

Do not upload. After a successful build, tell the user the package is ready for `/rebuild-env`; uploading only happens through `/upload-package` on their explicit request.
