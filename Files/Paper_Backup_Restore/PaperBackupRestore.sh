#!/bin/bash

cd ..
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
sudo rm -r /lib/modules/$(uname -r)/kernel/drivers/net/ethernet # delete ethernet, wifi, and bluetooth drivers
sudo rm -r /lib/modules/$(uname -r)/kernel/drivers/net/wireless
sudo rm -r /lib/modules/$(uname -r)/kernel/drivers/bluetooth
nmcli networking off # disable internet
sudo systemctl disable bluetooth.service --force # disable bluetooth
sudo systemctl stop bluetooth
#-----
zenity --info --text "This computer is now airgapped."

NATOtoWIF()
{
    for (( j = 1 ; j <= 52 ; j++ )); do  
        word=$(echo -e $yetiseed | sed '13q' | sed s/'\S*$'// | tr --delete '\n' | cut --delimiter=' ' --fields=$j) # removes last word (checksum), new line, and loops through each word
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

#if you are getting errors with other projects it might be because yeti has misspelt words alfa, juliett
base58_NATO_words=('ONE' 'TWO' 'THREE' 'FOUR' 'FIVE' 'SIX' 'SEVEN' 'EIGHT' 'NINE' 'ALFA' 'BRAVO' 'CHARLIE' 'DELTA' 'ECHO' 'FOXTROT' 'GOLF' 'HOTEL' 'JULIETT' 'KILO' 'LIMA' 'MIKE' 'NOVEMBER' 'PAPA' 'QUEBEC' 'ROMEO' 'SIERRA' 'TANGO' 'UNIFORM' 'VICTOR' 'WHISKEY' 'X-RAY' 'YANKEE' 'ZULU' 'alfa' 'bravo' 'charlie' 'delta' 'echo' 'foxtrot' 'golf' 'hotel' 'india' 'juliett' 'kilo' 'mike' 'november' 'oscar' 'papa' 'quebec' 'romeo' 'sierra' 'tango' 'uniform' 'victor' 'whiskey' 'x-ray' 'yankee' 'zulu')
yetiseed=""
verify_checksum() {
    sum=0
    for (( j = 1; j <= 4; j++ )); do
        word=$(echo $line_of_words | cut -d " " -f$j )
        let sum+=$(echo ${base58_NATO_words[@]/$word//} | cut -d/ -f1 | wc -w | tr -d ' ') # gets index of each word
    done
    checksum=$(expr $sum % 58)
    if [[ "$(echo $line_of_words | cut -d " " -f5)" == "${base58_NATO_words[$checksum]}" ]]; then
        line_pass=true
    else
        line_pass=false
    fi
}

ask_line() {
    line_of_words=$(zenity --entry --width 600 --title "Line $i" --text "Enter line $i of yetiseed$seed_number")
    verify_checksum
    if [[ $line_pass == true ]]; then
        yetiseed+="$line_of_words""\n"
    else
        zenity --warning --text "Invalid line, try again"
        ask_line
    fi
}
seed_number=$(zenity --list --title "Select Seed Number" --text "Select the seed number you are recovering.\nIf you don't know just select an unused number." --column Selection --column Number --radiolist TRUE 1 FALSE 2 FALSE 3 FALSE 4 FALSE 5 FALSE 6 FALSE 7)

bitcoin_directory=$HOME/bitcoin-0.21.2
tar -xzf bitcoin-0.21.2-x86_64-linux-gnu.tar.gz -C $HOME
$bitcoin_directory/bin/bitcoin-qt -server &
sleep 2
notify-send "Continue in the Script's popup window below" &
zenity --info --text "Wait until Bitcoin Core has finished loading\n\nThen click OK."


for (( i = 1; i <= 13; i++ )); do
    ask_line
done

# test if seed is a valid key

NATOtoWIF

$bitcoin_directory/bin/bitcoin-cli createwallet "generator1" false true "" false false false
$bitcoin_directory/bin/bitcoin-cli -rpcwallet="generator1" sethdseed true "$hdseed"
check_seed=$($bitcoin_directory/bin/bitcoin-cli -rpcwallet="generator1" getnewaddress )
$bitcoin_directory/bin/bitcoin-cli unloadwallet "generator1"
rm -r $HOME/.bitcoin/wallets/generator1

if [[ "$check_seed" == "" ]]; then
        zenity --warning --text "Invalid seed, rerun script.\nYou probably duplicated a line or lost track of the order.\nTry again."
        exit
fi


yetiseed+="\n\n\n"

ask_descriptor() {
    Public_Descriptor=$(zenity --entry --width 600 --text "Enter the Public Descriptor")

    #check if descriptor is valid

    $HOME/bitcoin-0.21.2/bin/bitcoin-cli getdescriptorinfo "$Public_Descriptor"

    check=$($HOME/bitcoin-0.21.2/bin/bitcoin-cli getdescriptorinfo "$Public_Descriptor")

    if [[ check = "" ]]; then
        zenity --warning --text "Invalid line, try again.\nDo not include apostrophes at the end."
        ask_descriptor
    fi

}
ask_descriptor

yetiseed+="$Public_Descriptor\n"

for (( i = 1; i <= 18; i++ )); do
    yetiseed+="\nTwo other seed packets must be obtained to recover the bitcoin stored."
done

sudo echo -e $yetiseed >> $HOME/Pictures/yetiseed$seed_number.txt

zenity --info --text "Yetiwallet successfully restored. It has been saved to the Pictures folder\nYou can run this script again if you need more seeds recovered.\nRun YetiToCore.sh after to convert them to wallet.dats\n\nThis Computer needs to be wiped when finished."
