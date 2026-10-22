---
name: test-installers
description: Validate freshly built initramfs images (and so the python-nest change behind them) by creating/booting the six libvirt VMs installer{8,9,10}-{bios,uefi} and running the tuxifier-playbook on each twice - first with -e tuxifier_reinstall=true, then without. Use after /rebuild-initramfs, or when asked to test or validate the initramfs / the installer VMs. Optional argument - VM names to test instead of all six.
argument-hint: "[installer9-uefi ...]"
---

# Test the initramfs on the six installer VMs

The VMs direct-kernel-boot the images that `/rebuild-initramfs` writes to `~/work/tuxifier/<rockyN>/`, so a rebuilt initramfs needs no libvirt change, only a full stop + start of the VM (a guest reboot does not re-read the image). Use `virsh -c qemu:///system` for everything.

| VM | distro | firmware | MAC | IP (pinned) |
|---|---|---|---|---|
| installer8-bios  | rocky8  | bios | 52:54:00:eb:fe:63 | 192.168.122.101 |
| installer8-uefi  | rocky8  | uefi | 52:54:00:19:97:98 | 192.168.122.102 |
| installer9-bios  | rocky9  | bios | 52:54:00:ff:07:7e | 192.168.122.110 |
| installer9-uefi  | rocky9  | uefi | 52:54:00:d9:f3:bc | 192.168.122.104 |
| installer10-bios | rocky10 | bios | 52:54:00:7d:b4:c1 | 192.168.122.105 |
| installer10-uefi | rocky10 | uefi | 52:54:00:58:be:25 | 192.168.122.106 |

The IPs are pinned as `<host>` entries in the libvirt network `default` and listed in `/etc/hosts`. The playbook is `~/git/geertsky/tuxifier-playbook/playbook.yml` (`hosts: installer`; the group is in `inventory/inventory.ini`, host_vars `<vm>.yml`, soft-links to `rocky<N>-{bios,uefi}.yml`). Always pass `-l`. Run `ansible`/`ansible-playbook` from the default shell environment, not conda base.

`$ARGUMENTS` optionally names the VMs to test; without it test all six. The VMs run **in parallel**: each has 2 GiB RAM, so six fit on the host. Every ansible call below therefore takes all tested VMs at once (`-l` with a comma-separated list, e.g. `-l installer8-bios,installer8-uefi,...`, or `-l installer` for all six) and `-f 6` so none waits for another.

**Run 1 wipes the disk of every tested VM** (`tuxifier_reinstall=true`). They are test VMs, but if the user did not ask for the test, confirm first.

Success means: for every tested VM both playbook runs finish with `failed=0 unreachable=0`. Only then conclude that the initramfs is valid for that distro/firmware and the rebuilt package works end to end. Otherwise report the failing VM/task output and do not claim success. A missing module/command in the initramfs environment points to the python-nest change.

## Step 0: Open the tmux session (right after the command is issued, before anything else)

The user wants to watch the playbook output live, so every long run happens in a tmux session on a socket in their home directory (the default socket under `/tmp` is not reliably shared with the user's shell). Open it first and show the attach command in your reply before doing any other work:

```bash
SOCK=~/.tuxifier-tmux.sock
SCRATCH=<scratchpad directory>
tmux -S $SOCK kill-session -t tuxifier 2>/dev/null
tmux -S $SOCK new-session -d -s tuxifier -n shell
```

Then tell the user, as the first line of your answer:

> Watch the run with: `tmux -S ~/.tuxifier-tmux.sock attach -t tuxifier` (detach with Ctrl-b d; do not press Ctrl-c)

Each playbook run (Step 3.3 and 3.5) is started as its own window of this session, with its output also written to `$SCRATCH/<run>.log`; `$SCRATCH/current.log` is a symlink to the log of the run in progress, so `tail -f` works too. The window ends in `exec bash`, so the output stays readable after the run finished until the user types `exit`. If `tmux` is missing, ask the user to install it.

## Step 1: Preconditions

- The images `~/work/tuxifier/rocky*/ansible-tuxifier-initramfs-*.img` are newer than `~/git/geertsky/dracut-incubator/94incubator/python-nest.squashfs` (else run `/rebuild-initramfs` first).
- The install repos answer: `curl -sI -m 5 http://192.168.122.1/rocky/<N>/BaseOS/x86_64/os/repodata/repomd.xml | head -1` is `200` for N = 8, 9 and 10 (all host_vars use this local mirror).
- Network pins and `/etc/hosts` (set up once; add what is missing):
  ```bash
  virsh -c qemu:///system net-dumpxml default | grep "mac='<MAC>'"
  virsh -c qemu:///system net-update default add ip-dhcp-host "<host mac='<MAC>' name='<VM>' ip='<IP>'/>" --live --config
  grep -q "<IP> <VM>" /etc/hosts || echo "<IP> <VM>" | sudo tee -a /etc/hosts
  ```
  A pin only applies on the VM's next DHCP lease, so a VM started before the pin existed needs a destroy + start.

## Step 2: Make sure the VMs exist and use the current images

For each VM to test (idempotent):

1. Legacy names: if domain `installer-bios` / `installer-uefi` exists and `installer9-bios` / `installer9-uefi` does not, `virsh destroy` it if running and `virsh domrename installer-bios installer9-bios` (resp. uefi). The disk file keeps its old name.
2. Expected kernel and initramfs for the VM's distro (`<rockyN>` = rocky8, rocky9 or rocky10; `V=$(cat ~/work/tuxifier/<rockyN>/VERSION)`):
   - kernel `~/work/tuxifier/<rockyN>/boot/vmlinuz-$V`
   - initrd `~/work/tuxifier/<rockyN>/ansible-tuxifier-initramfs-$V.img`
3. If the domain does not exist, create the disk and define it (2 GiB RAM, 2 vCPUs, 30 GiB sparse disk, `vda`; for UEFI add the `uefi,firmware.feature0...` boot options as shown):
   ```bash
   qemu-img create -f qcow2 /var/lib/libvirt/images/<VM>.qcow2 30G
   virt-install --connect qemu:///system --name <VM> --memory 2048 --vcpus 2 --cpu host-passthrough \
     --import --osinfo detect=off,require=off \
     --disk path=/var/lib/libvirt/images/<VM>.qcow2,format=qcow2,bus=virtio,discard=unmap \
     --network network=default,mac=<MAC> --graphics spice --noautoconsole \
     --boot [uefi,firmware.feature0.name=secure-boot,firmware.feature0.enabled=yes,]kernel=<kernel>,initrd=<initrd>,cmdline='root=LABEL=root rd.neednet=1 enforcing=0 console=tty0 console=ttyS0 rd.retry=18000 rd.timeout=0' \
     --print-xml > <scratch>/<VM>.xml && virsh -c qemu:///system define <scratch>/<VM>.xml
   ```
4. If the domain exists, compare `<kernel>`/`<initrd>` in `virsh dumpxml <VM>` with the expected paths. If they differ (a newer kernel/initramfs was generated), destroy the VM if running and fix them via `virsh dumpxml --inactive`, `sed`, `virsh define`.
5. Memory must be 2 GiB (the renamed rocky9 pair was created with 8 GiB). If `virsh dominfo <VM>` shows otherwise, destroy the VM if running and run `virsh setmaxmem <VM> 2G --config && virsh setmem <VM> 2G --config`.

## Step 3: Run (all tested VMs in parallel; stop at the first failure and show its output)

`<VMS>` below is the comma-separated list of the tested VMs.

1. Boot all from the new images: for each VM `virsh destroy <VM>` if running, then `virsh start <VM>`.
2. Wait until every initramfs answers Ansible (each shows "Waiting for Ansible"):
   ```bash
   cd ~/git/geertsky/tuxifier-playbook
   ansible <VMS> -m ansible.builtin.wait_for_connection -a 'timeout=300' \
     -e ansible_python_interpreter=/local/conda/envs/python-nest/bin/python3
   ```
   The interpreter must be given explicitly: the initramfs has no `python3` on its default `PATH` (only the playbook's role sets `PATH` to the python-nest environment), so a plain `wait_for_connection` times out with "timed out waiting for ping module test". If the VM is still booting, ssh answers before the environment is usable; `ansible <VMS> -m ansible.builtin.raw -a true` is a Python-free reachability check.
3. Run 1, reinstall (long: it installs six OSes at once; run it in the background and wait for it to exit):
   ```bash
   rm -f $SCRATCH/run1.done; ln -sf $SCRATCH/run1.log $SCRATCH/current.log
   tmux -S $SOCK new-window -t tuxifier -n run1 "cd ~/git/geertsky/tuxifier-playbook && ansible-playbook -f 6 -l <VMS> playbook.yml -e tuxifier_reinstall=true 2>&1 | tee $SCRATCH/run1.log; touch $SCRATCH/run1.done; exec bash"
   until [ -e $SCRATCH/run1.done ]; do sleep 10; done
   ```
   Check the `PLAY RECAP` per VM in `$SCRATCH/run1.log`.
4. `continue_install` is false, so each VM powers off by itself. Wait until `virsh domstate <VM>` is `shut off` for all (up to ~5 min after its host finished), then repeat steps 1 and 2 to boot them from the initramfs again.
5. Run 2, no reinstall (the storage layout already exists and must match, nothing may break):
   ```bash
   rm -f $SCRATCH/run2.done; ln -sf $SCRATCH/run2.log $SCRATCH/current.log
   tmux -S $SOCK new-window -t tuxifier -n run2 "cd ~/git/geertsky/tuxifier-playbook && ansible-playbook -f 6 -l <VMS> playbook.yml 2>&1 | tee $SCRATCH/run2.log; touch $SCRATCH/run2.done; exec bash"
   until [ -e $SCRATCH/run2.done ]; do sleep 10; done
   ```
   Check the `PLAY RECAP` per VM in `$SCRATCH/run2.log`.

If run 1 fails on some VMs, still run steps 4-5 for the VMs that succeeded, so the report covers every VM.

## Report

A table, one row per VM: run 1 and run 2 with ok/changed/failed/unreachable from the recap. State plainly whether both runs succeeded on every tested VM (valid initramfs, workflow confirmed) or which VM/task failed. All tested VMs are left powered off.
