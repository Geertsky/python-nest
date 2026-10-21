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
   rattler-build build --recipe $ARGUMENTS/recipe.yaml --variant-config $ARGUMENTS/variants.yaml --output-dir output -c file:///home/geert/miniforge3/conda-bld -c conda-forge
   ```
   The local `conda-bld` channel is required: dependencies built earlier (cryptsetup, kmod, libbytesize, ...) live there, not in `./output` or conda-forge. Keep it before `conda-forge` (strict channel priority). Because of strict priority, any package name in `conda-bld` hides conda-forge's versions of that name, so `conda-bld` must only contain packages built from recipes in this repo (a recipe with several outputs, such as `libdevmapper` -> `libdevmapper` + `lvm2` or `e2fsprogs` -> `e2fsprogs` + `e2fsprogs-libs`, counts as one). Never copy other packages into it; stale/foreign ones go to `~/miniforge3/conda-bld/removed-non-python-nest/`. Do not add the geertsky channel: it still carries old shadow copies (libuuid, util-linux, e2fsprogs, ...).
2. Copy the new package(s) of this recipe (all outputs) from `output/linux-64/` (or `output/noarch/` for noarch recipes) to the matching subdirectory of `~/miniforge3/conda-bld/`. Only copy this recipe's packages; `output/` may hold others.
3. Re-index: `conda index ~/miniforge3/conda-bld`
4. Confirm availability: `conda search -c local $ARGUMENTS` lists the new version/build.

Do not upload. After a successful build, tell the user the package is ready for `/rebuild-env`; uploading only happens through `/upload-package` on their explicit request.
