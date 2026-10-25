# The python-nest conda environment

The `python-nest` environment is a [conda python environment](https://conda-forge.org/docs/) with the minimum requirements for [ansible](https://docs.ansible.com/) to partition and install an OS.<br>
It is built for the [tuxifier](https://github.com/Geertsky/tuxifier) ansible collection. An example playbook repository can be found here: [tuxifier-playbook](https://github.com/Geertsky/tuxifier-playbook).<br>
A prebuilt `python-nest.squashfs` is available for download from here: [python-nest.squashfs](https://verweggistan.eu/python-nest.squashfs) <br>
It contains the packages listed in [python-nest-environment.yml](python-nest-environment.yml), among them python, blivet, parted, e2fsprogs, xfsprogs, mdadm, cryptsetup and rpm-tools.
The exact versions of the last build are in [python-nest-environment_versioned.yml](python-nest-environment_versioned.yml).

For the people that would like to improve or extend the functionality of this python environment, below the steps to build it.

## Where this fits

This repository is one of four that make up the tuxifier installer:

| Repository | Role |
|---|---|
| `python-nest` (this one) | The conda recipes and the environment that make up the python-nest environment |
| [dracut-incubator](https://github.com/Geertsky/dracut-incubator) | The dracut module that puts the packed environment in an initramfs |
| [tuxifier](https://github.com/Geertsky/tuxifier) | The ansible collection that runs inside that initramfs and installs the OS |
| [tuxifier-playbook](https://github.com/Geertsky/tuxifier-playbook) | An example playbook and inventory |

The packed environment is mounted at `/local/conda/envs/python-nest` in the initramfs, and the playbook puts its `bin` and `sbin` directories first in `PATH`. The tools in this environment therefore take precedence over the ones the initramfs got from the distribution.

## Target

The primary target of the tuxifier installer is Rocky Linux. The other targets are RHEL, AlmaLinux and Fedora. The initramfs images are built per distribution and release, and all of them use the same python-nest environment.

* linux-64 only.
* Python 3.13, with the exception of `rpm-tools` (see below).

## Installing conda

On the following website is described how to install conda: https://conda-forge.org/download/

## Conda channels

There are two situations, with different channel configuration.

### Using the environment: the geertsky channel

The directories in this repository are the recipes of the conda packages that are created for `python-nest`, or that are changed with respect to the `conda-forge` versions.
Not all these changes have been merged yet to conda-forge.
The `geertsky` channel contains the packages built from these recipes.
For building the `python-nest` environment from `python-nest-environment.yml` the `geertsky` anaconda channel is needed in addition to the `conda-forge` channel.
This can be done with the following command:

```bash
conda config --add channels geertsky
```

To see the configured channels we can issue a `conda config --show-sources` which should return:

```
channel_priority: strict
channels:
  - geertsky
  - conda-forge
report_errors: False
```

As an additional test we can issue a `conda search parted` which should list a build from the `geertsky` channel.

The channel only holds packages built from the recipes of this repository. Each of them is needed because `conda-forge` does not have the package at all (`blivet`, `cryptsetup`, `dosfstools`, `f2fs-tools`, `inih`, `iniparser`, `kmod`, `libblockdev`, `libbytesize`, `libnvme`, `lvm2`, `mdadm`, `ndctl`, `parted`, `pyparted`, `xfsprogs`), has only an older version (`btrfs-progs`, `e2fsprogs`, `e2fsprogs-libs`, `libdevmapper`, and `dasbus`, which is at 1.6 while `blivet` requires `>=1.7`), or lacks the changes made here (`rpm-tools`: the `PATH` patch and the read-only Berkeley DB backend).

### Building the recipes: a local channel

When building recipes, the dependencies that were built earlier from this repository are taken from a local channel, `~/miniforge3/conda-bld`, not from `geertsky`, so that a build never depends on a package that was published earlier but has since changed.

Because the channel priority is `strict`, a package name that is present in the local channel hides every version of that name in `conda-forge`. The local channel must therefore only contain packages built from the recipes in this repository. A recipe with several outputs counts as one: `libdevmapper` builds `libdevmapper` and `lvm2`, and `e2fsprogs` builds `e2fsprogs` and `e2fsprogs-libs`. These packages depend on each-other and should not be mixed with packages from other multi output packages.

## Conda prerequisite - conda-pack
Additionally, the `conda-pack` conda package needs to be installed in the base environment to pack the `python-nest` conda environment in a squashfs.
This can be installed using the following command:

```bash
conda install -n base conda-pack
```

## The recipes

Every directory with a `recipe.yaml` is a [rattler-build](https://rattler.build/) recipe. Next to it are a `variants.yaml` with the compiler and glibc sysroot, and, where needed, a `build.sh` and patches.

| Package | Version | Notes |
|---|---|---|
| `blivet` | 3.14.1 | Python storage library, the engine of the ansible storage role |
| `libblockdev` | 3.5.0 | Built from a pinned git commit instead of a release tarball. `activate.sh` and `deactivate.sh` set and restore `LIBBLOCKDEV_CONFIG_DIR` so the plugin configuration of the environment is found. `libudev` is pinned below 258, see below |
| `libbytesize` | 2.12 | |
| `libdevmapper` | 2.03.41 | Builds `libdevmapper` and `lvm2`. Installs the `lvm.conf` of this directory, see below |
| `cryptsetup` | 2.8.8 | LUKS |
| `e2fsprogs` | 1.47.4 | Builds `e2fsprogs` and `e2fsprogs-libs` |
| `xfsprogs` | 7.2.0 | |
| `btrfs-progs` | 7.1 | Built against Python 3.13 |
| `f2fs-tools` | 1.9.0 | |
| `dosfstools` | 4.2 | |
| `mdadm` | 4.4 | The Makefile enables `-Werror`, which `build.sh` drops. Builds with gcc 13. Only `mdadm` and `mdmon` are installed; the systemd units and udev rules are skipped |
| `parted` | 3.7 | Pins `libuuid` to 2.42.1 for compatibility with `util-linux` 2.42.1. |
| `pyparted` | 3.13.0 | |
| `dasbus` | 1.7 | |
| `kmod` | 34.2 | |
| `libnvme` | 1.16.2 | Built against Python 3.13 |
| `ndctl` | 85 | |
| `inih` | r62 | Needed by `xfsprogs` |
| `iniparser` | 4.2.6 | Needed by `ndctl` |
| `rpm-tools` | 6.1.0 | Derived from the conda-forge recipe. Three patches, see below. The Python bindings are a stable-ABI (abi3) extension built once against Python 3.10 (`python_min`), which serves every later Python |

### Patches of rpm-tools

1. `0001-Remove-fhardened-from-compiler-flags.patch`: drops `-fhardened` from the hardening flags the build tries to add. It is inherited from the conda-forge recipe, which does not record a reason either. Without the patch rpm-tools builds, passes its tests and works; the difference is stronger fortification (`-fhardened` implies `_FORTIFY_SOURCE=3`, where conda-forge's flags use `=2`; `librpm` imports 7 instead of 1 `*_chk` functions). It is kept to stay identical to conda-forge.
2. `0002-Only-require-the-Python-Development.Module-component.patch`: the bindings are a stable-ABI module, so the full `Development` component, which implies `libpython`, is not needed. Since CPython 3.15 conda-forge ships `libpython` separately, so without this the configure step fails. Not yet submitted upstream.
3. `0003-Run-scriptlets-with-the-PATH-rpm-was-started-with.patch`: rpm replaces `PATH` before it runs scriptlets and helpers such as `sysusers.sh`. With `--root` in the initramfs these cannot find `touch`, `basename` and `xargs` from this environment. The patch keeps the `PATH` rpm was started with.

The build is configured with `-DENABLE_BDB_RO=ON`: rpm 6 dropped the full Berkeley DB backend, and the read-only one is what lets this rpm read the rpmdb of EL8 systems.

### The lvm.conf

`libdevmapper/lvm.conf` is installed as `etc/lvm/lvm.conf` of the environment, which is the default system directory of the `lvm2` package. It is meant for an installer environment: it disables udev synchronisation and rules (the udev of an initramfs is not complete), lvmlockd, D-Bus notification and metadata backups, and does not restrict device discovery, because existing volume groups have to be found before the disks are wiped.

## Differences with conda-forge

Five recipes build packages that exist in both channels. The `geertsky` build differs from the `conda-forge` one as follows.

| Package | conda-forge | geertsky | Why |
|---|---|---|---|
| `btrfs-progs` | 5.16.2, which requires `util-linux <2.37` and `e2fsprogs-libs <1.47` | 7.1, built against `libudev <258` and Python 3.13 | The conda-forge build cannot be installed next to the `util-linux` and `e2fsprogs` of this environment. `libudev` is pinned for the EL8 kernel (see [Build constraints](#build-constraints)). Python is pinned because without it the build picked Python 3.15 |
| `e2fsprogs`, `e2fsprogs-libs` | 1.46.2, which requires `util-linux <2.37` | 1.47.4, built from source in one run and installed as the two packages. `fsck`, `uuidd`, `libuuid` and `libblkid` are disabled, those come from `util-linux` | The `util-linux` pin of the conda-forge build conflicts with the `util-linux` of this environment |
| `libdevmapper` | 2.02.187, the device-mapper library only | 2.03.41, built from the LVM2 sources as `libdevmapper` and `lvm2`, with the installer `lvm.conf` | conda-forge has no `lvm2` package. `libblockdev`, `blivet` and `parted` need `lvm2`, and `libdevmapper` comes from the same sources |
| `dasbus` | 1.6 | 1.7 | dasbus 1.6 has a `UnixFD` regression that breaks blivet's use of it. `blivet` requires `dasbus >=1.7` |
| `rpm-tools` | 6.1.0 | 6.1.0 with an extra patch and `-DENABLE_BDB_RO=ON`; the Python bindings are built against Python 3.10 where conda-forge requires `cpython >=3.11` | The patch keeps the `PATH` rpm was started with when running scriptlets, which `--root` installs in the initramfs need. `ENABLE_BDB_RO` lets rpm read the rpmdb of EL8, which uses Berkeley DB. See [Patches of rpm-tools](#patches-of-rpm-tools) |

The versions of conda-forge are those of 2026-10-25. When conda-forge catches up, as it already has for `rpm-tools`, check whether the `geertsky` package is still needed.

## Build constraints

Several recipes deviate from the others. Do not "fix" these without testing on EL8.

* **glibc sysroot.** Per default the recipes build against glibc 2.17. `btrfs-progs`, `e2fsprogs`, `libblockdev`, `libdevmapper`, `ndctl` and `rpm-tools` use 2.28, the glibc of EL8, and so the newest the environment may require. The sysroot is set in `variants.yaml`. The reason per recipe, found by building each of them against 2.17:

  | Recipe | With sysroot 2.17 |
  |---|---|
  | `btrfs-progs` | `configure` fails: `reallocarray` (glibc 2.26) is missing |
  | `libblockdev` | compile error: `explicit_bzero` (glibc 2.25) is not declared in `crypto.c` |
  | `rpm-tools` | compile error: `EM_BPF` is not declared in `rpmfc.cc`; the `elf.h` of glibc 2.17 is too old |
  | `ndctl` | compile error in `test/fwctl.c`: `__struct_group`, which the kernel headers of the 2.17 sysroot do not define |
  | `e2fsprogs` | builds, but `getrandom` (glibc 2.25) is not found, so it is built without it |
  | `libdevmapper` | builds. No functional difference was found; 2.28 is kept to build on the same baseline as `libblockdev`, which links against it |
* **libudev below 258.** The kernel of EL8 (4.18) lacks `statx` `STATX_MNT_ID`, which `libudev` 260 and later require, and 258 to 261.1 also need glibc 2.34. `libudev <258` is pinned in the `libblockdev` recipe, and `libudev1 <258` in `python-nest-environment.yml`.
* **libuuid** is pinned in `parted/variants.yaml`.
* **gcc.** The recipes use gcc 15, `mdadm` uses gcc 13.
* **Python.** `btrfs-progs` and `libnvme` are pinned to Python 3.13 in `variants.yaml`. The `libblockdev` tests check for `lib/python3.13/site-packages`, so they must be updated together with a Python upgrade.

## Building a recipe

`rattler-build` is installed in the conda `base` environment. Make sure that is the active environment (`conda info`), then, from the root of this repository:

```bash
rattler-build build --recipe <package>/recipe.yaml --variant-config <package>/variants.yaml \
  --output-dir output -c file://$HOME/miniforge3/conda-bld -c conda-forge
```

The local channel has to come before `conda-forge`. The result is in `output/linux-64/` (or `output/noarch/`). Copy the packages of this recipe, all outputs, to the matching directory of the local channel and index it:

```bash
cp output/linux-64/<package>-*.conda ~/miniforge3/conda-bld/linux-64/
conda index ~/miniforge3/conda-bld
conda search -c local <package>
```

The `output` directory also holds the rattler-build caches, including the extracted sources.

### Build order

A package has to be built after the packages it needs, taken from the `host` requirements of the recipes:

| Package | Needs |
|---|---|
| `libblockdev` | `cryptsetup`, `e2fsprogs`, `kmod`, `libbytesize`, `libdevmapper`, `libnvme`, `lvm2`, `ndctl`, `parted` |
| `blivet` | `libblockdev`, `libbytesize`, `lvm2`, `pyparted`, `dasbus` (at run time) |
| `pyparted` | `parted` |
| `parted` | `e2fsprogs`, `lvm2` |
| `cryptsetup` | `lvm2` |
| `btrfs-progs` | `lvm2`, `e2fsprogs` |
| `ndctl` | `kmod`, `iniparser` |
| `xfsprogs` | `inih` |

After rebuilding a package that others need, rebuild those too; `libblockdev` records its dependencies with `run_exports` and `blivet` runs on top of it.

## Building the python-nest environment

In this repository there is a conda environment file, `python-nest-environment.yml`, which can be used to build the python-nest environment.
Using the following command, from the root of this repository, we can build the `python-nest` environment:

```bash
conda env create -f python-nest-environment.yml
```

Per default, the `python-nest` conda environment will be placed in `~/miniforge3/envs/python-nest/`.

This environment can be activated for inspection using:
```sh
conda activate python-nest
```
## Packing the python-nest environment

To pack the `python-nest` conda environment we need to use the following command:

```bash
conda-pack --compress-level 9 -j 8  --dest-prefix /local/conda/envs/python-nest --format squashfs -n python-nest
```
_`--compress-level 9` is needed to use xz compression. The only one supported by RHEL8_<br>
_`--dest-prefix /local/conda/envs/python-nest` is needed as the environment gets mounted under `/local/conda/envs/python-nest` in the initramfs._<br>
_`--format squashfs` The environment needs to be packed in a squashfs._<br>

Once `conda-pack` is finished, we have a file `python-nest.squashfs` containing the python-nest environment.
This packed environment needs to be available in the dracut module directory of `dracut-incubator`. This is `/usr/lib/dracut/modules.d/94incubator`

```bash
sudo mv python-nest.squashfs /usr/lib/dracut/modules.d/94incubator
```

Now we're ready to build the initramfs. See: [dracut-incubator](https://github.com/Geertsky/dracut-incubator)

## License

The recipes and the other files of this repository are licensed under the [EUPL 1.2](LICENSE). The packages built from them keep the license of their upstream project, as stated in their recipes.
