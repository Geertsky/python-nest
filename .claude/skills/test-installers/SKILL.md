---
name: test-installers
description: Validate freshly built initramfs images (and so the python-nest change behind them) by creating/booting the six libvirt VMs installer-rocky{8,9,10}-{bios,uefi} and running the tuxifier-playbook on each twice - first with -e tuxifier_reinstall=true, then without. Use after /rebuild-initramfs, or when asked to test or validate the initramfs / the installer VMs. Optional argument - VM names to test instead of all six.
argument-hint: "[installer-rocky9-uefi ...]"
---

# Test the initramfs on the six installer VMs

The VMs direct-kernel-boot the images that `/rebuild-initramfs` writes to `~/work/tuxifier/<rockyN>/`, so a rebuilt initramfs needs no libvirt change, only a full stop + start of the VM (a guest reboot does not re-read the image). Use `virsh -c qemu:///system` for everything.

| VM | distro | firmware | MAC | IP (pinned) |
|---|---|---|---|---|
| installer-rocky8-bios  | rocky8  | bios | 52:54:00:a8:00:01 | 192.168.122.101 |
| installer-rocky8-uefi  | rocky8  | uefi | 52:54:00:a8:00:02 | 192.168.122.102 |
| installer-rocky9-bios  | rocky9  | bios | 52:54:00:06:85:19 | 192.168.122.103 |
| installer-rocky9-uefi  | rocky9  | uefi | 52:54:00:3c:9e:fc | 192.168.122.104 |
| installer-rocky10-bios | rocky10 | bios | 52:54:00:aa:10:01 | 192.168.122.105 |
| installer-rocky10-uefi | rocky10 | uefi | 52:54:00:aa:10:02 | 192.168.122.106 |

The IPs are pinned as `<host>` entries in the libvirt network `default` and listed in `/etc/hosts`. The playbook is `~/git/geertsky/tuxifier-playbook/playbook.yml` (`hosts: installer`; the group is in `inventory/inventory.ini`, host_vars `installer-<vm>.yml`). Always pass `-l`. Run `ansible`/`ansible-playbook` from the default shell environment, not conda base.

`$ARGUMENTS` optionally names the VMs to test; without it test all six. The VMs run **in parallel**: each has 2 GiB RAM, so six fit on the host. Every ansible call below therefore takes all tested VMs at once (`-l` with a comma-separated list, e.g. `-l installer-rocky8-bios,installer-rocky8-uefi,...`, or `-l installer` for all six) and `-f 6` so none waits for another.

**Run 1 wipes the disk of every tested VM** (`tuxifier_reinstall=true`). They are test VMs, but if the user did not ask for the test, confirm first.

Success means: for every tested VM both playbook runs finish with `failed=0 unreachable=0`. Only then conclude that the initramfs is valid for that distro/firmware and the rebuilt package works end to end. Otherwise report the failing VM/task output and do not claim success. A missing module/command in the initramfs environment points to the python-nest change.

## Step 0: Preconditions

- The images `~/work/tuxifier/rocky*/ansible-tuxifier-initramfs-*.img` are newer than `~/git/geertsky/dracut-incubator/94incubator/python-nest.squashfs` (else run `/rebuild-initramfs` first).
- For rocky9 and rocky10 the install repo answers: `curl -sI -m 5 http://192.168.122.1/rhel/9.8/BaseOS/ | head -1` (and `.../rhel/10.2/BaseOS/`) is `200`. The rocky9 host_vars use it; rocky8 and rocky10 may use the public mirrors, which need internet access.
- Network pins and `/etc/hosts` (set up once; add what is missing):
  ```bash
  virsh -c qemu:///system net-dumpxml default | grep "mac='<MAC>'"
  virsh -c qemu:///system net-update default add ip-dhcp-host "<host mac='<MAC>' name='<VM>' ip='<IP>'/>" --live --config
  grep -q "<IP> <VM>" /etc/hosts || echo "<IP> <VM>" | sudo tee -a /etc/hosts
  ```
  A pin only applies on the VM's next DHCP lease, so a VM started before the pin existed needs a destroy + start.

## Step 1: Make sure the VMs exist and use the current images

For each VM to test (idempotent):

1. Legacy names: if domain `installer-bios` / `installer-uefi` exists and `installer-rocky9-bios` / `installer-rocky9-uefi` does not, `virsh destroy` it if running and `virsh domrename installer-bios installer-rocky9-bios` (resp. uefi). The disk file keeps its old name.
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

## Step 2: Run (all tested VMs in parallel; stop at the first failure and show its output)

`<VMS>` below is the comma-separated list of the tested VMs.

1. Boot all from the new images: for each VM `virsh destroy <VM>` if running, then `virsh start <VM>`.
2. Wait until every initramfs answers Ansible (each shows "Waiting for Ansible"):
   ```bash
   cd ~/git/geertsky/tuxifier-playbook
   ansible <VMS> -m ansible.builtin.wait_for_connection -a 'timeout=300'
   ```
3. Run 1, reinstall (long: it installs six OSes at once; run it in the background and wait for it to exit):
   ```bash
   ansible-playbook -f 6 -l <VMS> playbook.yml -e tuxifier_reinstall=true
   ```
   Check the `PLAY RECAP` per VM.
4. `continue_install` is false, so each VM powers off by itself. Wait until `virsh domstate <VM>` is `shut off` for all (up to ~5 min after its host finished), then repeat steps 1 and 2 to boot them from the initramfs again.
5. Run 2, no reinstall (the storage layout already exists and must match, nothing may break):
   ```bash
   ansible-playbook -f 6 -l <VMS> playbook.yml
   ```
   Check the `PLAY RECAP` per VM.

If run 1 fails on some VMs, still run steps 4-5 for the VMs that succeeded, so the report covers every VM.

## Report

A table, one row per VM: run 1 and run 2 with ok/changed/failed/unreachable from the recap. State plainly whether both runs succeeded on every tested VM (valid initramfs, workflow confirmed) or which VM/task failed. All tested VMs are left powered off.
