#!/bin/bash
#==============================================================
# Script de Recuperacao do GRUB - Lenovo Yoga Slim 7 14IMH9
# Multi-boot: Garuda Mokka/Sway, Windows, Arch ML4W, CachyOS, NixOS
# Uso: rodar de dentro do Garuda Mokka como: sudo bash restaurar-grub.sh
#==============================================================
set -e
echo "=== Recuperacao do GRUB iniciada ==="

UUID_MOKKA="c3430b0b-797e-4687-b4d2-3ef0cc2c07b7"
UUID_SWAY="8bd3f167-6c5c-4577-ab47-9965d1964e7f"
UUID_ARCH="d5262ca6-bff8-463b-aac4-d9ec3a075bec"
UUID_CACHY="04a870a5-6127-4bdb-9bf0-53df5018c37e"
UUID_NIXOS="9e054757-5096-4e05-a471-26731c8043bd"
UUID_EFI="D8D9-D120"

echo ">> Reinstalando GRUB na EFI..."
mkdir -p /mnt/efi-main
mount /dev/nvme0n1p1 /mnt/efi-main 2>/dev/null || true
grub-install --target=x86_64-efi --efi-directory=/mnt/efi-main --bootloader-id=Garuda --recheck

echo ">> Detectando kernel do NixOS..."
NIXOS_KERNEL=$(ls /mnt/efi-main/EFI/nixos/ | grep "bzImage.efi" | head -1)
NIXOS_INITRD=$(ls /mnt/efi-main/EFI/nixos/ | grep "initrd.efi" | head -1)
mkdir -p /mnt/nixos-root
mount /dev/nvme0n1p7 /mnt/nixos-root 2>/dev/null || true
NIXOS_INIT=$(readlink /mnt/nixos-root/nix/var/nix/profiles/system-1-link)/init

echo ">> Desativando scripts que poluem o menu..."
chmod -x /etc/grub.d/10_linux 2>/dev/null || true
chmod -x /etc/grub.d/20_linux_xen 2>/dev/null || true
chmod -x /etc/grub.d/30_os-prober 2>/dev/null || true
chmod -x /etc/grub.d/30_uefi-firmware 2>/dev/null || true
chmod -x /etc/grub.d/41_snapshots-btrfs 2>/dev/null || true

echo ">> Recriando entradas do menu..."
cat > /etc/grub.d/40_custom << EOF
#!/bin/sh
exec tail -n +3 $0

menuentry "Garuda Mokka" --class garuda --class gnu-linux --class gnu --class os {
    insmod part_gpt
    insmod btrfs
    search --no-floppy --fs-uuid --set=root ${UUID_MOKKA}
    linux /@/boot/vmlinuz-linux-zen root=UUID=${UUID_MOKKA} rw rootflags=subvol=@ loglevel=3 quiet
    initrd /@/boot/initramfs-linux-zen.img
}

menuentry "Garuda Sway" --class garuda --class gnu-linux --class gnu --class os {
    insmod part_gpt
    insmod btrfs
    search --no-floppy --fs-uuid --set=root ${UUID_SWAY}
    linux /@/boot/vmlinuz-linux-zen root=UUID=${UUID_SWAY} rw rootflags=subvol=@ loglevel=3 quiet
    initrd /@/boot/initramfs-linux-zen.img
}

menuentry "Windows 11" --class windows --class os {
    insmod part_gpt
    insmod fat
    search --no-floppy --fs-uuid --set=root ${UUID_EFI}
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}

menuentry "Arch ML4W OS" --class arch --class gnu-linux --class gnu --class os {
    insmod part_gpt
    insmod ext2
    search --no-floppy --fs-uuid --set=root ${UUID_ARCH}
    linux /boot/vmlinuz-linux root=UUID=${UUID_ARCH} rw loglevel=3 quiet
    initrd /boot/initramfs-linux.img
}

menuentry "CachyOS" --class gnu-linux --class gnu --class os {
    insmod part_gpt
    insmod btrfs
    search --no-floppy --fs-uuid --set=root ${UUID_CACHY}
    linux /@/boot/vmlinuz-linux-cachyos root=UUID=${UUID_CACHY} rw rootflags=subvol=@ loglevel=3 quiet
    initrd /@/boot/initramfs-linux-cachyos.img
}

menuentry "NixOS 25.11" --class nixos --class gnu-linux --class gnu --class os {
    insmod part_gpt
    insmod fat
    insmod ext2
    search --no-floppy --fs-uuid --set=root ${UUID_EFI}
    linux /EFI/nixos/${NIXOS_KERNEL} init=${NIXOS_INIT} root=UUID=${UUID_NIXOS} loglevel=4
    initrd /EFI/nixos/${NIXOS_INITRD}
}
EOF

echo ">> Regenerando grub.cfg..."
chattr -i /boot/grub/grub.cfg 2>/dev/null || true
grub-mkconfig -o /boot/grub/grub.cfg
chattr +i /boot/grub/grub.cfg

echo ">> Ajustando ordem de boot..."
GARUDA_BOOT=$(efibootmgr | grep -i "Garuda" | head -1 | sed "s/Boot\([0-9A-F]*\).*/\1/")
if [ -n "\$GARUDA_BOOT" ]; then
    efibootmgr --bootorder \$GARUDA_BOOT
fi

echo ""
echo "=== GRUB restaurado com sucesso! Reinicie com: sudo reboot ==="
