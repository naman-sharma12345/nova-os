# Tenka: build the live/installable ISO with live-build (Debian 13 trixie + backports).
#   make iso      build the ISO (needs root: run `sudo make iso`)
#   make themes   regenerate all theme files from the palettes
#   make run      boot the ISO in QEMU (UEFI)
#   make clean    remove the build tree
BUILD ?= $(CURDIR)/build
ISO = $(wildcard $(BUILD)/live/*.iso)

.PHONY: iso themes assemble run run-bios clean deps

deps:
	apt-get install -y live-build debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools dosfstools python3-pil rsync librsvg2-bin

themes:
	python3 scripts/gen-themes.py && python3 scripts/gen-lite.py && python3 scripts/gen-system.py

assemble:
	BUILD=$(BUILD) sh scripts/assemble.sh

iso: assemble
	cd $(BUILD)/live && lb clean && lb config && lb build 2>&1 | tee build.log
	@ls -lh $(BUILD)/live/*.iso

run:
	qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -cpu host -machine q35 \
	  -bios /usr/share/ovmf/OVMF.fd -device virtio-vga-gl -display gtk,gl=on \
	  -cdrom $(ISO)

run-bios:
	qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -cpu host -device virtio-vga -cdrom $(ISO)

clean:
	-cd $(BUILD)/live && lb clean --purge
	rm -rf $(BUILD)
