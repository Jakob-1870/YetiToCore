#!/bin/bash
#   How to run the script:
#   Return to the file manager where you opened this file, right click the empty space, select Open in Terminal. Then paste this command in the terminal:
#   bash YetiToCore.sh

sudo clear
# check if brasero or xfburn is installed
if ! command -v brasero xfburn &> /dev/null; then
    zenity --question --text "Brasero or Xfburn is not installed. You must have either program to burn a disk.\nYou can install it now before airgapping.\nYou can also use a live OS like Xubuntu that already has Xfburn.\n\nContinue anyway?"
    if [[ $? = 1 ]]; then
        exit
    else
        zenity --question --text "Are you sure you want to continue?\nYou will not be able to get disk burning software easily once airgapped."
        if [[ $? = 1 ]]; then
        exit
        fi
    fi
fi

check_if_core_is_running() {	# If core is running displays an error message and ends script.
	if [[ $(ps -A | grep "bitcoin-qt" -wc) != 0 ]]; then  # checks the process status and searches for "bitcoin-qt". Recalls the function recursively until core is closed.
		zenity --info --text "Bitcoin core is already running. It will now shut down."
		sudo pkill bitcoin-qt
        zenity --info --text "Continue when Bitcoin core has fully closed"
		check_if_core_is_running
	fi
}
check_if_core_is_running

# airgapping
#sudo rm -r /lib/modules/$(uname -r)/kernel/drivers/net/ethernet # delete ethernet, wifi, and bluetooth drivers
#sudo rm -r /lib/modules/$(uname -r)/kernel/drivers/net/wireless
#sudo rm -r /lib/modules/$(uname -r)/kernel/drivers/bluetooth
#nmcli networking off # disable internet
#sudo systemctl disable bluetooth.service --force # disable bluetooth
#sudo systemctl stop bluetooth

zenity --info --text "This computer is now airgapped.\n\nInsert your yeti CD and Paste your yetiseed(s) into the Pictures directory now.\nAfter transferring, click OK."
yetiseeds_amount=$(sudo find $HOME/Pictures -maxdepth 1 -name "yetiseed[0-9]*.txt" 2>/dev/null | wc -l)
if [ $yetiseeds_amount -eq 0 ]; then # exit script with warning if no seeds found in Pictures
    zenity --warning --text="No Yetiseeds found\n\nCopy and paste the yetiseeds to your Pictures directory on the left sides of the \"Files\" application.\n\nRerun script."
    exit
fi

zenity --info --text "Creating additional wallet file(s) from this seed(s):\n\n\n$(echo "$(sudo find $HOME/Pictures -maxdepth 1 -name "yetiseed[0-9]*.txt" 2>/dev/null)" | tr ' ' '\n')"
zenity --question --text "Do you want to create a Public Descriptor wallet file as well?\n(Only needed once)"
make_pub=$?

time=$(date +'%I:%M:%S_%p_%F')
mkdir $HOME/Documents/oldFiles_$time
mv -t $HOME/Documents/oldFiles_$time $HOME/.bitcoin/wallets/yetiseed* $HOME/.bitcoin/wallets/generator $HOME/bitcoin-0.21.2 $HOME/Videos/YetiCD* # move any old files to backup
if [ $make_pub = "0" ]; then
    mv -t $HOME/Documents/oldFiles_$time $HOME/Videos/Public_DescriptorCD $HOME/.bitcoin/wallets/Public_Descriptor* # move any old files to backup
fi

bitcoin_directory=$HOME/bitcoin-0.21.2
tar -xzf Files/bitcoin-0.21.2-x86_64-linux-gnu.tar.gz -C $HOME
$bitcoin_directory/bin/bitcoin-qt -server &
sleep 2
notify-send "Continue in the Script's popup window below" &
zenity --info --text "Wait until Bitcoin Core has finished loading\n\nThen click OK.\n\nBe patient after clicking, it may take a minute"
NATOtoWIF()
{
    for (( j = 1 ; j <= 52 ; j++ )); do  
        word=$(cat /$HOME/Pictures/yetiseed$i.txt | sed '13q' | sed s/'\S*$'// | tr --delete '\n' | cut --delimiter=' ' --fields=$j) # removes last word (checksum), new line, and loops through each word
                if [ $word = "ONE" ]; then
                    character="1"
                elif [ $word = "TWO" ]; then
                    character="2"
                elif [ $word = "THREE" ]; then
                    character="3"
                elif [ $word = "FOUR" ]; then
                    character="4"
                elif [ $word = "FIVE" ]; then
                    character="5"
                elif [ $word = "SIX" ]; then
                    character="6"
                elif [ $word = "SEVEN" ]; then
                    character="7"
                elif [ $word = "EIGHT" ]; then
                    character="8"
                elif [ $word = "NINE" ]; then
                    character="9"
                else
                    character="${word:0:1}"
                fi
        hdseed+="$character"
    done
}
descriptor=$(sed -n '17p' $HOME/Pictures/yetiseed*.txt)
$bitcoin_directory/bin/bitcoin-cli createwallet "generator" false true "" false false # create generator wallet to get the xprv from seed
for (( i = 1 ; i <= 7 ; i++ )); do  
    if [ ! -f $HOME/Pictures/yetiseed$i.txt ]; then
        echo "Skipping yetiseed$i"
    else
        hdseed=""  
        NATOtoWIF
        $bitcoin_directory/bin/bitcoin-cli -rpcwallet=generator sethdseed true "$hdseed"
        $bitcoin_directory/bin/bitcoin-cli -rpcwallet=generator dumpwallet "$bitcoin_directory/bin/yetiseed$i-dumpwallet"
        xprv=$(grep "# extended private masterkey: " $bitcoin_directory/bin/yetiseed$i-dumpwallet | tail -c112)
        # construct descriptor with replaced xprv
        xpub_to_replace=$($bitcoin_directory/bin/bitcoin-cli getdescriptorinfo "wpkh($xprv/*)" | sed '2q;d' | grep -Eio 'xpub[0-9|A-Z|a-z]*')
        # replace xpub with xprv, get descriptor
        descriptor_cut_checksum=$(echo "${descriptor::-9}")
        xprv_descriptor=$(echo "${descriptor_cut_checksum/"$xpub_to_replace"/"$xprv"}")
        xprv_checksum=$($bitcoin_directory/bin/bitcoin-cli getdescriptorinfo "$xprv_descriptor" | sed '3q;d' | cut -d '"' -f4)
        xprv_complete_desc="$xprv_descriptor#$xprv_checksum"

        $bitcoin_directory/bin/bitcoin-cli createwallet "yetiseed$i" false true "" false true true # create blank, descriptor wallet.dat
        $bitcoin_directory/bin/bitcoin-cli -rpcwallet="yetiseed$i" importdescriptors '[{"desc": "'$xprv_complete_desc'", "timestamp": "now", "active": true}]' # import complete xprv descriptor to the wallet
        mkdir $HOME/Videos/YetiCD$i $HOME/Videos/YetiCD$i/YetiWallet$i $HOME/Videos/YetiCD$i/Files
        $bitcoin_directory/bin/bitcoin-cli -rpcwallet="yetiseed$i" backupwallet ~/Videos/YetiCD$i/YetiWallet$i/wallet.dat

        printf "This HDSeed is:\n$hdseed\n\nThis xprv is:\n$xprv\n\nThis xpub is:\n$xpub_to_replace\n\nYour xprv-descriptor is:\n$xprv_complete_desc\n\nYour Public descriptor is:\n$descriptor" > $HOME/Videos/YetiCD$i/Files/Seed"$i"Info.txt
        mv -t $HOME/Documents/oldFiles_$time $bitcoin_directory/bin/yetiseed$i-dumpwallet 

        cp -t $HOME/Videos/YetiCD$i Files/Offline_Restore/RestoreOfflineWallet.sh Files/Offline_Restore/Instructions_For_Offline_Wallet 
        cp -r -t $HOME/Videos/YetiCD$i/Files Files/bitcoin-0.21.2-x86_64-linux-gnu.tar.gz $HOME/Pictures/yetiseed$i.txt Files/Paper_Backup_Restore

        if [ ! -f $HOME/Videos/YetiCD$i/YetiWallet$i/wallet.dat ]; then
            mv -t $HOME/Documents/oldFiles_$time $HOME/Videos/YetiCD*
            zenity --info --text  "Error detected, could not create a wallet.dat.\nFollow instructions carefully.\nMake sure that core is running properly before clicking OK. Rerun script.\n\nAny old files were moved to "$(echo $HOME/Documents/oldFiles_$time)""
            exit
        fi
        brasero -d $HOME/Videos/YetiCD$i &
        xfburn -d $HOME/Videos/YetiCD$i &
    fi
done
if [ $make_pub = "0" ]; then
    mkdir $HOME/Videos/Public_DescriptorCD $HOME/Videos/Public_DescriptorCD/Public_Descriptor_Wallet $HOME/Videos/Public_DescriptorCD/Files
    cp -t $HOME/Videos/Public_DescriptorCD/Files Files/bitcoin-0.21.2-x86_64-linux-gnu.tar.gz
    printf "Your Public Descriptor is:\n$descriptor" > $HOME/Videos/Public_DescriptorCD/Files/Public_Descriptor_Info.txt
    cp -t $HOME/Videos/Public_DescriptorCD/ Files/Watch-Wallet_Restore/RestorePublicDescriptorOnline.sh Files/Watch-Wallet_Restore/Instructions_For_Online_Watch-Wallet

    $bitcoin_directory/bin/bitcoin-cli createwallet "Public_Descriptor" true true "" false true true # create blank, private keys disabled, descriptor wallet.dat
    $bitcoin_directory/bin/bitcoin-cli -rpcwallet="Public_Descriptor" importdescriptors '[{"desc": "'$descriptor'", "timestamp": "now", "active": true}]'
    $bitcoin_directory/bin/bitcoin-cli -rpcwallet="Public_Descriptor" backupwallet ~/Videos/Public_DescriptorCD/Public_Descriptor_Wallet/wallet.dat
    brasero -d $HOME/Videos/Public_DescriptorCD &
    xfburn -d $HOME/Videos/Public_DescriptorCD &
    
fi

# delete generator wallet
$bitcoin_directory/bin/bitcoin-cli unloadwallet "generator"
rm -r $HOME/.bitcoin/wallets/generator

notify-send "Continue in the Script's popup window below" &
if [ $make_pub = "0" ]; then
    zenity --info --text "Script Complete.\n\nBurn the $yetiseeds_amount YetiCD folder(s) to $yetiseeds_amount disk(s) in your disk burning software that popped up.\n\nBurn the Public_DescriptorCD folder by itself to 7 disks\n\nWhen finished, wipe the computer:\nIf using a live CD, turn the computer off\nIf using yeti then complete the secure erase procedure in the instructions.\n\nYour wallet file have been saved to Videos.\n\nAny old files were moved to "$(echo $HOME/Documents/oldFiles_$time)""
else
    zenity --info --text "Script Complete.\n\nBurn the $yetiseeds_amount YetiCD folder(s) to $yetiseeds_amount disk(s) in your disk burning software that popped up.\n\nWhen finished, wipe the computer:\nIf using a live CD, turn the computer off\nIf using yeti then complete the secure erase procedure in the instructions.\n\nYour wallet file have been saved to Videos.\n\nAny old files were moved to "$(echo $HOME/Documents/oldFiles_$time)""
fi