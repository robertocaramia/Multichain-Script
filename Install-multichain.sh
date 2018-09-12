#!/bin/bash
#### Description: Script to install or update Multichain following the Multichain instructions at https://www.multichain.com/download-install/.
#### Written by: Roberto Caramia - robertocaramia@hotmail.com on 08-2018.
#### Version: 0.2
#### License: GPL v3

# Setting up the name of the temporary folder for storing the downloaded files.
TempFolderName="temp-inst"

# Tell to the user that we are going to update Multichain if it is installed

echo "##############################################################################
# This script can automatically update the Multichain binary if present or   #
# install Multichain from scratch. If this is NOT your intent say S to skip  #
# the installation/upgrade process or N to exit                              #
##############################################################################"
read -p "Do you want to continue ? y/s/N: " answer

if [[ "$answer" = "Y" ]] || [[ "$answer" = "y" ]] ; then    

# Checking if there is a process running.
echo " - Check if Multichaind is running..."
CheckMultichaind=$(ps -x | grep multichaind | grep -v grep | wc -l)

# If we find a running process we stop it gently.
    if [ $CheckMultichaind == "1" ]; then
        ChainName=$(ps -x | grep multichaind | grep -v grep | awk '{print $6}')
        echo "- Stopping the running chain $ChainName..."
        multichain-cli $ChainName stop
    else
        echo " - No multichain process detected."
    fi

# We check if there is some temp folder from a previous launch and if yes we delete it.
    if [ -d $TempFolderName ] ; then
        rm -rf $TempFolderName
    fi

# We create the temp installation folder.
echo " - Creating a tmp installation folder..."
mkdir $TempFolderName
TempFolder=$(ls | grep $TempFolderName | wc -l)

# We check if the folder were created if not we exit.
    if [ $TempFolder == "1" ]; then
        echo "DONE"
    else
        echo "Could not create temp folder exiting..."
        exit
    fi

# Entering the installation folder.
cd $TempFolderName
# Make the user choose which version of Multichain to download.
echo "######################################################################################################################
# Choose which version of Multichain we are going to install from:                                                   #
# a. Stable Version can be selected here: https://www.multichain.com/download-install/ ;                             #
# b. Preview Version can be selected here: https://www.multichain.com/developers/multichain-2-0-preview-releases/ .  #
# If blank the latest stable version will be installed.                                                              #
######################################################################################################################"
read -p " - Insert the multichain download url: " url
    if [ -n $url ]; then
        echo " - Downloading multichain version $url"
        wget $url
    else
        wget https://www.multichain.com/download/multichain-latest.tar.gz
    fi
# We set up the downloaded filename to untar it.
file=$(ls | grep multichain)

echo " - Extracting multichain..."
tar -xvzf $file

# We set up the untar created folder and enter into that.
folder=$(find -type d | grep multichain)

echo " - Entering the multichain folder..."
cd $folder

# We move the multichain binary into the path to make easily accessible on the command line.
# N.B. for that operation we need sudo priviledge.

echo " - Move multichain binary into the path this operation need root privilege so insert sudo password."
sudo mv multichaind multichain-cli multichain-util /usr/local/bin

# We check if the binary copy was succesfull.
IsOk=$(ls /usr/local/bin/ | grep multichain | wc -l)

    if [ $IsOk == "3" ] ; then
        # We clean up the installation folder.
        echo " - Cleaning up..."
        cd ..
        cd ..
        rm -r $TempFolderName
        echo " - Installation complete"
    else
        echo " - Something goes wrong, try again."
        exit
    fi
fi

# If S or s is selected we skip the update/installation process

if [[ "$answer" = "S" ]] || [[ "$answer" = "s" ]] ; then
    echo " - Update skipped go direct to Chain management."

# In all the other case we exit to avoid nuclear disaster. 

else
exit
fi

# From here we are going to create a new chain or start an old one

read -p "Do you want to create a new chain or to start an old one?
 - Press N/n for new or O/o for old: " NorO
 
if [[ $NorO = "O" ]] || [[ $NorO = "o"  ]] ; then
    read -p " - Insert the name of the chain to start: " OldChainName
    # TODO Set param at chain start up.
    echo " - Starting chain $OldChainName ."
                        multichaind $OldChainName -daemon
                        echo " - Check if $OldChainName chain is running..."
                        CheckOldChain=$(ps -x | grep multichaind | grep $OldChainName | wc -l)
                        if [ $CheckOldChain == "1" ]; then
                            echo " - OK $OldChainName Started Enjoy!"
                            exit
                            else
                            echo " - Something goes wrong try starting the new chain manually:
                            - multichaind $OldChainName -daemon"
                            exit
                        fi
fi
if [[ $NorO = "N" ]] || [[ $NorO = "n"  ]] ; then 
    read -p " - Select the chain name: " chainName
    read -p " - Do you want to set up a custom directory or use the default one?
     - Press C/c for custom or D/d for default: " CorD
    if [[ $CorD = "D" ]] || [[ $CorD = "d"  ]] ; then
        echo "Creating the new Chain $chainName"
                chainCreate=$(multichain-util create $chainName)
                echo " - $chainName Creation Complete."
                chainPath=$(echo $chainCreate | awk '{print $20}')
    fi
    if [[ $CorD = "C" ]] || [[ $CorD = "c"  ]] ; then
        read -p " - Do you want to create a new directory or set up an existing one?
        - Press N/n for new dir or E/e for existing one: " NorE
        if [[ $NorE = "N" ]] || [[ $NorE = "n"  ]] ; then
            read -p " - Insert the full directory path: " dirpath
            echo " - Creating $dirpath directory..."
            mkdir $dirpath
            if [ ! -d $dirpath ] ; then
                echo " - Could not create $dirpath directory exiting..."
                exit
            fi
        fi
        if [[ $NorE = "E" ]] || [[ $NorE = "e"  ]] ; then
            read -p " - Insert the full directory path: " dirpath
            echo " - Setting $dirpath as chain directory..."
            if [ ! -d $dirpath ] ; then
                echo " - $dirpath directory does not exist exiting..."
                exit
            fi
        fi
        echo "Creating new Chain in $dirpath..."
        chainCreate=$(multichain-util create $chainName -datadir=$dirpath)
        echo " - $chainName Creation Complete."
        chainPath=$(echo $chainCreate | awk '{print $20}')
    fi
    read -p " - Do you want to edit the chain parameters or use the default ones (it can't be done after the chain first start)? y/Y or n/N default N: " EditParam
    # TODO Manage the param.
    if [[ $EditParam = "Y" ]] || [[ $EditParam = "y" ]] ; then
        vi $chainPath
    fi
    if [[ $EditParam = "N" ]] || [[ $EditParam = "n"  ]] ; then
        echo "- Ready to start with the new Chain $chainName"
    fi
    read -p " - Do you want to edit multichain.conf parameters? y/Y or n/N default N: " McyN
        if [[ $McyN = "Y" ]] || [[ $McyN = "y"  ]] ; then
            
            ChainConfFolder="$(dirname $chainPath)"
            ChainConfFile="$ChainConfFolder/multichain.conf"
            
            read -p " - Set Username for the rpcuser: " rpcuser
            read -p " - Set Password for the rpcuser: " rpcpassword
            read -p " - Allow incoming JSON-RPC API connections from these IP addresses;
- Values can be a single IP (e.g. 1.2.3.4), a network/netmask (e.g. 1.2.3.4/255.255.255.0) or a network/CIDR (e.g. 1.2.3.4/24);
- Use multiple times to allow multiple IPs or ranges. : " rpcallowip
            read -p " - Do you want to anable SSL support for the JSON-RPC interface? Set 1 for Active 0 for Disabled:  " rpcssl
            
            if [[ $rpcssl == "1" ]] ; then
                read -p " - Set the Certificate (full path of the cert file): " rpcsslcertificatechainfile
                read -p " - Set the Certificate private key (full path of the key file): " rpcsslprivatekeyfile
                echo "rpcuser=$rpcuser" > $ChainConfFile
                echo "rpcpassword=$rpcpassword" >> $ChainConfFile
                echo "rpcallowip=$rpcallowip" >> $ChainConfFile
                echo "rpcssl=1" >> $ChainConfFile
                echo "rpcsslcertificatechainfile=$rpcsslcertificatechainfile" >> $ChainConfFile
                echo "rpcsslprivatekeyfile=$rpcsslprivatekeyfile" >> $ChainConfFile
                echo "rpcsslciphers=TLSv1.2+HIGH:TLSv1+HIGH:!SSLv2:!aNULL:!eNULL:!3DES:@STRENGTH" >> $ChainConfFile 
                echo " - Setting the selected params into $ChainConfFile...."
                echo " - Review the selected Configuration $(cat $ChainConfFile)"
            else
                echo "rpcuser=$rpcuser" > $ChainConfFile
                echo "rpcpassword=$rpcpassword" >> $ChainConfFile
                echo "rpcallowip=$rpcallowip" >> $ChainConfFile
                echo " - Setting the selected params into $ChainConfFile...."
                echo " - Review the selected Configuration in $ChainConfFile:"
                echo ""
                cat $ChainConfFile
            fi
        fi
        
        read -p "- Do you want to start the new chain? y/Y or n/N default N: " StartChain
            if [[ $StartChain = "N" ]] || [[ $StartChain = "n"  ]] ; then
               echo " - Exiting... Stay safe!!!"
               exit
            fi
            if [[ $StartChain = "Y" ]] || [[ $StartChain = "y"  ]] ; then    
                echo " - Starting new chain $chainName ."
                if [[ -n $dirpath ]] ; then
                    multichaind $chainName -daemon -datadir=$dirpath
                else
                    multichaind $chainName -daemon
                fi
                echo " - Check if $chainName chain is running..."
                CheckNewChain=$(ps -x | grep multichaind | grep $chainName | wc -l)
                if [ $CheckNewChain == "1" ]; then
                echo " - OK $chainName Started Enjoy!"
                else
                echo " - Something goes wrong try starting the new chain manually:
                - multichaind $chainName -daemon -datadir=$dirpath"
                exit
                fi
                if [[ $rpcssl == "1" ]] ; then
                    echo " - Check the JSON-RPC SSL interface insert the selected password when asked."
                    rpcport=$(cat $chainPath | grep rpc-port | awk '{print $3}')
                    curl --user $rpcuser --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getinfo", "params": [] }' -H 'content-type: application/json;' https://127.0.0.1:$rpcport/ -k
                fi
            else
            echo " - Exiting... Stay safe!!!"
            exit
            fi
fi

# 
# Generate self-signed certificate: 
# openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
