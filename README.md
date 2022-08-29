# Readme

This script will convert your yeti CD backups into standard bitcoin core wallet backups.

Benefits:
  1. The airgapped computer is permanently offline. It never requires new code or connecting to a website (like yeti currently does)
  2. You can sign independently of the other seeds, one at a time. You don't have to bring 3 seeds together. It's faster and easier.
  3. Only live OS needed. You don't have to install Ubuntu. Just boot from a live USB, sign, and turn off after.
  
It's as code-minimized as possible. It uses only uses simple bash scripts and bitcoin 0.21.2

You can run this script immediately after finishing yeti, before erasing, or later on with a Xubuntu USB.

## Improved Signing procedure:

* Create a live Xubuntu USB. 
* Take this USB and your airgapped laptop to a seed location.
* Boot into the OS.
* Run the restoration script (fast).
* sign the transaction.
* save the transaction to another USB (or the live USB if you know how to make another partition).
* Turn computer off.
* Return CD.
* Repeat for 2 more seeds.

Alternatively:
* You can leave the laptop and USB in a secure location.
* Retrieve 1 CD.
* Sign.
* Return the CD to its location.

# How to run the script:

You can run this script immediately after finishing yeti, before erasing, or later on with a Xubuntu USB.
* Download the release on github and transfer it to your offline laptop.
* Extract the folder anywhere.
* Open the extracted folder. Right click the empty space, select Open in Terminal. Then paste this command in the terminal: 

bash YetiToCore.sh

## Important Details

It's recommended to physically airgap the offline laptop as the script has no way of airgapping it before you enter the Backup CD.
If you don't physically airgap you must run the Airgap.sh script manually before you insert a backup CD.


Each backup CD includes the seed's bitcoin core wallet, a copy of bitcoin core, a restoration script, the original yetiseed*.txt, a Paper-backup script, and the seed info in plaintext (HDSeed,xprv,xpub, and the multisig wallet's xprv and xpub descriptor).
