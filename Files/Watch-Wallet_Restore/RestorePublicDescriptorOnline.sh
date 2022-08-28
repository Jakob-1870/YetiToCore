#!/bin/bash
sudo clear
check_if_core_is_running() {	# If core is running displays an error message and ends script.
	if [[ $(ps -A | grep "bitcoin-qt" -wc) != 0 ]]; then  # checks the process status and searches for "bitcoin-qt". Recalls the function recursively until core is closed.
		zenity --info --text "Bitcoin core is already running. It will now shut down."
		sudo pkill bitcoin-qt
        zenity --info --text "Continue when Bitcoin core has fully closed"
		check_if_core_is_running
	fi
}
#check_if_core_is_running

notify-send "Be patient, it may take a moment..." &

sudo apt update -y
sudo apt upgrade -y
sudo apt install tor -y

tar -xzf bitcoin-0.21.2-x86_64-linux-gnu.tar.gz -C $HOME
mkdir $HOME/.bitcoin $HOME/.bitcoin/wallets

cp -r Public_Descriptor_Wallet $HOME/.bitcoin/wallets
$HOME/bitcoin-0.21.2/bin/bitcoin-qt -server --proxy=127.0.0.1:9050 & sleep 2


notify-send "Continue in the Script's popup window below" &
zenity --info --text "Wait until Bitcoin Core has finished loading\n\nThen click OK.\n\nBe patient after clicking, it may take a minute"

blocknumber=$(zenity --entry --title="Add new profile" --text="Enter the oldest block height of your wallet.\nIf you do not know, leave it 0" --entry-text "0")

$HOME/bitcoin-0.21.2/bin/bitcoin-cli loadwallet "Public_Descriptor_Wallet"
$HOME/bitcoin-0.21.2/bin/bitcoin-cli -rpcwallet="Public_Descriptor_Wallet" rescanblockchain $blocknumber & 

notify-send "Be patient, it can take up to a few hours for a full rescan..."
