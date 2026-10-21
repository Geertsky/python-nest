---
name: rebuild-env
description: Rebuild the python-nest conda environment from python-nest-environment.yml and pack it into python-nest.squashfs for the dracut module. Use after a recipe was rebuilt, or when asked to rebuild the python-nest environment.
---

# Rebuild the python-nest environment

Run `conda deactivate` until `conda info` shows `active environment : base`, chained in each Bash call:

```bash
while [ -n "$CONDA_DEFAULT_ENV" ] && [ "$CONDA_DEFAULT_ENV" != "base" ]; do conda deactivate; done; <command>
```

Steps (stop at the first failure and show its output):

1. Make sure the newly built package is listed in `python-nest-environment.yml` (repo root); add it alphabetically if missing.
2. Remove the old environment: `conda env remove -n python-nest -y`
3. Create the new one: `conda env create -f python-nest-environment.yml`. (`conda env build` does not exist.) If the freshly built local package is not picked up, add `-c local`.
4. Confirm the package is present: `conda list -n python-nest | grep -i <pkg>`
5. Pack the environment, from `~/git/geertsky/dracut-incubator/94incubator`:
   ```bash
   cd ~/git/geertsky/dracut-incubator/94incubator
   mv python-nest.squashfs{,.$(date +%s)}
   conda-pack --compress-level 9 -j 8 --dest-prefix /local/conda/envs/python-nest --format squashfs -n python-nest
   ```
   Confirm a fresh `python-nest.squashfs` exists there.

Afterwards tell the user the initramfs images can be regenerated with `/rebuild-initramfs`.
