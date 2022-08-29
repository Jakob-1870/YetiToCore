#!/bin/bash

# airgapping
sudo rm -r /lib/modules/$(uname -r)/kernel/drivers/net/ethernet # delete ethernet, wifi, and bluetooth drivers
sudo rm -r /lib/modules/$(uname -r)/kernel/drivers/net/wireless
sudo rm -r /lib/modules/$(uname -r)/kernel/drivers/bluetooth
nmcli networking off # disable internet
sudo systemctl disable bluetooth.service --force # disable bluetooth
sudo systemctl stop bluetooth
#------

tar -xzf Files/bitcoin-0.21.2-x86_64-linux-gnu.tar.gz -C $HOME
mkdir $HOME/.bitcoin $HOME/.bitcoin/wallets

wallet_number=$(pwd | tail -c 2)

cp -r YetiWallet* $HOME/.bitcoin/wallets
$HOME/bitcoin-0.21.2/bin/bitcoin-qt -server & sleep 2
$HOME/bitcoin-0.21.2/bin/bitcoin-cli loadwallet "YetiWallet$wallet_number"
