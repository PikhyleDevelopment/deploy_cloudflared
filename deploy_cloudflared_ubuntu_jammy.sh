#!/bin/bash

# Author: Erik Mason

# Color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'

# Usage string
usage_string="${YELLOW}$(basename "$0") -t CONNECTOR_TOKEN"

echo ' 
 ██████╗██╗      ██████╗ ██╗   ██╗██████╗ ██╗     ███████╗ █████╗ ██████╗ ███████╗██████╗     ██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗   ██╗███╗   ███╗███████╗███╗   ██╗████████╗
██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗██║     ██╔════╝██╔══██╗██╔══██╗██╔════╝██╔══██╗    ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝████╗ ████║██╔════╝████╗  ██║╚══██╔══╝
██║     ██║     ██║   ██║██║   ██║██║  ██║██║     █████╗  ███████║██████╔╝█████╗  ██║  ██║    ██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚████╔╝ ██╔████╔██║█████╗  ██╔██╗ ██║   ██║   
██║     ██║     ██║   ██║██║   ██║██║  ██║██║     ██╔══╝  ██╔══██║██╔══██╗██╔══╝  ██║  ██║    ██║  ██║██╔══╝  ██╔═══╝ ██║     ██║   ██║  ╚██╔╝  ██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║   
╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝███████╗██║     ██║  ██║██║  ██║███████╗██████╔╝    ██████╔╝███████╗██║     ███████╗╚██████╔╝   ██║   ██║ ╚═╝ ██║███████╗██║ ╚████║   ██║   
 ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═════╝     ╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝   
                                                            Written by Erik Mason                                                                                                                 
'

install () {
    # The below commands are from cloudflared documentation here:
    # https://pkg.cloudflare.com/index.html
    echo -e "${YELLOW}Creating keyrings directory.."
    sudo mkdir -p --mode=0755 /usr/share/keyrings

    # Check if GPG key exists
    if [ ! $(test -f /usr/share/keyrings/cloudflare-main.gpg) ]; then
        echo -e "${YELLOW}Downloading Cloudflare gpg key.."
        curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
    else
        echo -e "${YELLOW}Cloudflare GPG key already exists."
    fi

    # Check if cloudflared.list exists
    if [ ! $(test -f /etc/apt/sources.list.d/cloudflared.list) ]; then
        echo -e "${YELLOW}Setting up Cloudflared repository.."
        echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared jammy main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
    else
        echo -e "${YELLOW}Cloudflared.list already setup."
    fi

    # Check if cloudflared is already installed
    if [ ! $(test -x /usr/local/bin/cloudflared) ]; then
        echo -e "${YELLOW}Installing cloudflared daemon.."
        sudo apt update && sudo NEEDRESTART_MODE=a apt install cloudflared -y
    else    
        echo -e "${RED}Cloudflared already installed.. exiting. Please manually check service registered properly."
        exit 1
    fi

    # Check if cloudflared was installed correctly and register service
    if [ $(test -x /usr/local/bin/cloudflared) ]; then
        echo -e "${RED}Cloudflared installation failed.. Exiting.";
        exit 1;
    else
        echo -e "${GREEN}Installation complete. Registering service.."
        sudo cloudflared service install $1
    fi

    service_name="cloudflared"

    # Confirm service is running
    if [ $(systemctl is-active --quiet "$service_name.service") ]; then
        echo -e "${RED}Cloudflared failed to start"
    else
        echo -e "${GREEN}Cloudflared successfully running!"
    fi
}

remove () {
    if [[ $(systemctl list-units --full --all | grep cloudflared) ]]; then
        echo -e "${YELLOW}Uninstalling cloudflared service.."
        sudo cloudflared service uninstall
    else
        echo -e "${RED}Cloudflared service not found.."
    fi

    # Check for GPG key
    if [ ! $(test -f /usr/share/keyrings/cloudflare-main.gpg) ]; then
        echo -e "${YELLOW}Removing GPG key.."
        sudo rm -rfv /usr/share/keyrings/cloudflare-main.gpg
    else
        echo -e "${RED}GPG not found.. skipping."
    fi

    if [ ! $(test -f /etc/apt/sources.list.d/cloudflared.list) ]; then
        echo -e "${YELLOW}Removing source list.."
        sudo rm -rfv /etc/apt/sources.list.d/cloudflared.list
    else
        echo -e "${RED}Sources list not found.. skipping"
    fi

    if [ ! $(test -x /usr/local/bin/cloudflared) ]; then
        echo -e "${YELLOW}Removing cloudflared.."
        sudo apt remove --purge cloudflared -y

        if [ $(test -x /usr/local/bin/cloudflared) ]; then
            echo -e "${RED}Removal of cloudflared binary NOT successful.."
            exit 1
        else
            echo -e "${GREEN}Successfully uninstalled cloudflared!"
            exit 0
        fi 
    else
        echo -e "${RED}Cloudflared not currently installed"
        exit 1
    fi
}

usage () {
    # TODO
    echo -e $usage_string
}

install_opt=0
remove_opt=0

# Get switch flags 
# t for the connector token [required]
# h for help message
while getopts 'rt:hi' flag
do
	case "$flag" in
		t) token=${OPTARG};;
		h) usage; exit 69;;
        i) install_opt=1;;
        r) remove_opt=1;;
		# :) echo -e "${RED}Missing token argument (-t)"; exit 69;;
		?) echo -e "${RED}use -t and supply the connector token provided by cloudflare"; exit 69;;
	esac
done

if [ $remove_opt == 1 ]; then
    remove
fi

if [ ! "$token" ]; then
	echo -e "${RED}a token must be provided with -t"
	exit 69
fi

if [[ $install_opt == 1 ]]; then
    install $token
else
    echo -e "${RED}Must supply -i and -t {token} together"
fi 

# If no switch flag is provided

