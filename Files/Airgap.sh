#!/bin/bash

# airgapping
sudo rm -r /lib/modules/$(uname -r)/kernel/drivers/net/ethernet # delete ethernet, wifi, and bluetooth drivers
sudo rm -r /lib/modules/$(uname -r)/kernel/drivers/net/wireless
sudo rm -r /lib/modules/$(uname -r)/kernel/drivers/bluetooth
nmcli networking off # disable internet
sudo systemctl disable bluetooth.service --force # disable bluetooth
sudo systemctl stop bluetooth

zenity --info --text "Your computer is now software airgapped"
