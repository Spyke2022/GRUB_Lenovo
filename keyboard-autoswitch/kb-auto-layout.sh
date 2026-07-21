#!/bin/bash
# Alterna layout do Plasma conforme presenca do HyperX Alloy Elite 2 (03f0:058f)
# Layout 0 = Portugues (Brasil/ABNT2 interno) | Layout 1 = US Internacional (HyperX)

USER_NAME="silas"
USER_UID="1000"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${USER_UID}/bus"

sleep 1  # da tempo do udev assentar

if lsusb -d 03f0:058f >/dev/null 2>&1; then
    IDX=1   # HyperX conectado -> us intl
else
    IDX=0   # so teclado interno -> br abnt2
fi

QDBUS=$(command -v qdbus6 || command -v qdbus)

if [ "$(id -u)" -eq 0 ]; then
    runuser -u "$USER_NAME" -- env DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
        "$QDBUS" org.kde.keyboard /Layouts org.kde.KeyboardLayouts.setLayout "$IDX"
else
    "$QDBUS" org.kde.keyboard /Layouts org.kde.KeyboardLayouts.setLayout "$IDX"
fi
