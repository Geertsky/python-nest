---
name: rebuild-python-nest
description: Full python-nest rebuild pipeline - build a recipe, rebuild the python-nest environment, regenerate the initramfs images. Takes the package name as argument. Use when asked to rebuild python-nest end to end.
argument-hint: <package-name>
---

# Rebuild python-nest (orchestrator)

Run the step skills in order for package `$ARGUMENTS`, stopping at the first failure:

1. `build-recipe` with `$ARGUMENTS`
2. `rebuild-env`
3. `rebuild-initramfs`
4. `test-installers` - ask the user before running it: it creates missing installer{8,9,10}-{bios,uefi} VMs and run 1 wipes their disks.

`upload-package` is never part of this pipeline. Run it only when the user explicitly asks.

Finish with a summary per step: package version/build, python-nest confirmed, squashfs packed (and backup name), initramfs images regenerated, installer test result per run and host.
