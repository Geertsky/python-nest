---
name: rebuild-initramfs
description: Regenerate the rocky 8, 9 and 10 initramfs images so they contain the current python-nest.squashfs. Use after the python-nest environment was rebuilt and packed.
argument-hint: "[rocky8] [rocky9] [rocky10]"
---

# Rebuild the initramfs images

1. Run `sudo bash ~/work/tuxifier/generate-initrds.sh $ARGUMENTS`. With no arguments it builds rocky8, rocky9 and rocky10; pass a subset to limit it. If sudo cannot run non-interactively, ask the user to run it with `! sudo bash ~/work/tuxifier/generate-initrds.sh`.
2. Confirm each image `~/work/tuxifier/<rockyN>/ansible-tuxifier-initramfs-<VERSION>.img` was regenerated: fresh mtime and a plausible size in the script's final `ls -lh`.
