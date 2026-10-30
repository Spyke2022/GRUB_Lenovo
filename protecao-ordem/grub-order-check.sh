#!/bin/bash
# Garante Windows 11 como 1a entrada do GRUB e Garuda (Boot0000) como 1o no UEFI
REF=/home/silas/GRUB_Lenovo/40_custom
CUSTOM=/etc/grub.d/40_custom
CFG=/boot/grub/grub.cfg
LOG=/var/log/grub-order-check.log

first=$(grep -m1 "^menuentry \"" "$CFG" | cut -d\" -f2)
if [ "$first" != "Windows 11" ]; then
    echo "$(date) primeira entrada era [$first] - restaurando" >> "$LOG"
    if [ -f "$REF" ] && grep -q "menuentry \"Windows 11\"" "$REF"; then
        cp "$REF" "$CUSTOM"
        chmod +x "$CUSTOM"
    fi
    grub-mkconfig -o "$CFG" >> "$LOG" 2>&1
fi

order=$(efibootmgr | grep ^BootOrder | cut -d" " -f2)
if [ -n "$order" ] && [ "${order%%,*}" != "0000" ]; then
    new="0000,$(echo "$order" | tr , "\n" | grep -vx 0000 | paste -sd, -)"
    efibootmgr -o "$new" > /dev/null
    echo "$(date) BootOrder $order corrigido para $new" >> "$LOG"
fi
