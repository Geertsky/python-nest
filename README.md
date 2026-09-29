# The python-nest conda environment

The `python-nest` environment is a [conda python environment](https://conda-forge.org/docs/) with the minimum requirements for [ansible](https://docs.ansible.com/) to partition and install an OS.<br> It is build for the [tuxifier](https://github.com/Geertsky/tuxifier) ansible collection. An example playbook repository can be found here: [tuxifier-playbook](https://github.com/Geertsky/tuxifier-playbook).<br>
A prebuild `python-nest.squashfs` is available for download from here: [python-nest.squashfs](https://verweggistan.eu/python-nest.squashfs) <br>
It contains, not exclusively, the following:
* coreutils
* curl
* dosfstools
* e2fsprogs
* parted
* pip
* pyparted
* python
* rpm-tools
* util-linux

This is quite minimal, but it serves to show the intention.

For the people that would like to improve or extend the functionality of this python environment, below the steps to build it.
## Installing conda

On the following website is described how to install conda: https://conda-forge.org/download/

## Conda prerequisite - geertsky channel
There are three conda modules created for `python-nest` and some additional changes to existing conda modules.
Not all these changes have been merged yet to conda-forge.
The `geertsky` channel contains these changes as well as the `tuxifier` specific modules.
For building the `python-nest` environment the `geertsky` anaconda channel needs as addition to the `conda-forge` channel.
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

As an additional test we can issue a `conda search parted` which should return:

```
Loading channels: done
# Name                       Version           Build  Channel
parted                           3.7      h53a3f9b_0  geertsky
```

## Conda prerequisite - conda-pack
Additionally, the `conda-pack` conda package needs to be installed in the base environment to pack the `python-nest` conda environment in a squashfs.
This can be installed using the following command:

```bash
conda install -n base conda-pack
```

## Building the python-nest environment

In the dracut-incubator repository there is a conda environment file which can be use to build the python-nest environment.
Using the following command we can build the `python-nest` environment:

```bash
conda create -f python-nest/python-nest-environment.yml
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
_`--compression-level 9` is needed to use xz compression. The only one supported by RHEL8_<br>
_`--dest-prefix /local/conda/envs/python-nest` is needed as the environment gets mounted under `/local/conda/envs/python-nest` in the initramfs._<br>
_`--format squashfs` The environment needs to be packed in a squashfs._<br>

Once `conda-pack` is finished, we have a file `python-nest.squashfs` containing the python-nest environment.
This packed environment needs to be available in the dracut module directory of `dracut-incubator`. This is `/lib/dracut/modules.d/94tuxifier`

```bash
sudo mv python-nest.squashfs /lib/dracut/modules.d/94tuxifier
```

Now we're ready to build the initramfs. See: [dracut-incubator](https://github.com/Geertsky/dracut-incubator)
## python-nest devel branch

The intention of this `tuxifier` project is to be as closely as possible compatible to the redhat anaconda kickstart installer.
The idea is to replace the current LVM partitioning using parted by using the `Storage` role of the `RHEL System Roles` collection.
To realize this the `blivet` python module needs to be available in the `python-nest` conda environment. The `devel` branch contains<br>
the work to get `blivet` into `python-nest'.
