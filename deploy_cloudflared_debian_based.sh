#!/bin/bash

# Author: Erik Mason

####################################################################
# Description:                                                     #
#                                                                  #
#   This script is intended to provide a seemless deployment of    #
#   cloudflared. While installing, the script will check for the   #
#   presence of the GPG key, repository list, and cloudflared      #
#   binary. It will install whatever is not detected on the OS.    #
#                                                                  #
#   For removal, the same process occurs, removing whatever is     #
#   detected.                                                      #
#                                                                  #
#   Thanks for taking a look!                                      #
####################################################################

# Color variables
SUCCESS='\033[0;32m' # Green
WARN='\033[0;31m'    # Red
INFO='\033[1;33m'    # Yellow

# Usage string
usage_string="${INFO}$(basename "$0") [-h(elp)] [-r(emove)] -i(nstall) -t(oken) CONNECTOR_TOKEN"
service_name="cloudflared"
install_opt=0
remove_opt=0

echo -e '                                            
                                                                        
##  ### ##  #    #  # #      ## #    #  # # ##  ### #    #  ##  ### ##  
# # #   # # #   # # # #     #   #   # # # # # # #   #   # # # # #   # # 
# # ##  ##  #   # #  #      #   #   # # # # # # ##  #   ### ##  ##  # # 
# # #   #   #   # #  #      #   #   # # # # # # #   #   # # # # #   # # 
##  ### #   ###  #   #       ## ###  #  ### ##  #   ### # # # # ### ##                                             
                    
                    Written by Erik Mason                                                                                                                 
'

# Install the GPG key, apt source list, and cloudflared binary
# Then register the cloudflared service with the connector token.
install () {
    echo -e "${INFO}You're OS codename is: $(lsb_release -sc)"
    if [ ! -e /usr/bin/curl ]; then
        echo -e "${WARN}Curl is required to run this script. Please install and try again."
        exit 1
    else 
        echo -e "${SUCCESS}Curl is installed.. continuing"
    fi
    # The below commands are from cloudflared documentation here:
    # https://pkg.cloudflare.com/index.html
    echo -e "${INFO}Creating keyrings directory.."
    sudo mkdir -p --mode=0755 /usr/share/keyrings

    # Check if GPG key exists
    if [ ! -e /usr/share/keyrings/cloudflare-main.gpg ]; then
        echo -e "${INFO}Downloading Cloudflare gpg key.."
        curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
    else
        echo -e "${WARN}Cloudflare GPG key already exists."
    fi

    # Check if cloudflared.list exists
    if [ ! -e /etc/apt/sources.list.d/cloudflared.list ]; then
        echo -e "${INFO}Setting up Cloudflared repository.."
        echo deb "[signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
    else
        echo -e "${WARN}Cloudflared.list already setup."
    fi

    # Check if cloudflared is already installed
    if [ ! -x /usr/local/bin/cloudflared ]; then
        echo -e "${INFO}Installing cloudflared daemon.."
        sudo apt update && sudo NEEDRESTART_MODE=a apt install cloudflared -y
    else    
        echo -e "${WARN}Cloudflared already installed.. exiting. Please manually check service registered properly."
        exit 1
    fi

    # Check if cloudflared was installed correctly and register service
    if [ ! -x /usr/local/bin/cloudflared ]; then
        echo -e "${WARN}Cloudflared installation failed.. Exiting.";
        exit 1;
    else
        echo -e "${SUCCESS}Installation complete. Registering service.."
        sudo cloudflared service install $1
    fi

    # Confirm service is running
    if [ $(systemctl is-active --quiet "$service_name.service") ]; then
        echo -e "${WARN}Cloudflared failed to start"
    else
        echo -e "${SUCCESS}Cloudflared successfully running!"
    fi
}

remove () {
    if [[ $(systemctl list-units --full --all | grep cloudflared) ]]; then
        echo -e "${INFO}Uninstalling cloudflared service.."
        sudo cloudflared service uninstall
    else
        echo -e "${WARN}Cloudflared service not found.."
    fi

    # Check for GPG key
    if [ -e /usr/share/keyrings/cloudflare-main.gpg ]; then
        echo -e "${INFO}Removing GPG key.."
        sudo rm -rfv /usr/share/keyrings/cloudflare-main.gpg
    else
        echo -e "${WARN}GPG not found.. skipping."
    fi
    # Check for apt list
    if [ -e /etc/apt/sources.list.d/cloudflared.list ]; then
        echo -e "${INFO}Removing source list.."
        sudo rm -rfv /etc/apt/sources.list.d/cloudflared.list
    else
        echo -e "${WARN}Sources list not found.. skipping"
    fi
    # Check for existence of cloudflared binary
    if [ -x /usr/local/bin/cloudflared ]; then
        echo -e "${INFO}Removing cloudflared.."
        sudo apt remove --purge cloudflared -y

        if [ -x /usr/local/bin/cloudflared ]; then
            echo -e "${WARN}Removal of cloudflared binary NOT successful.."
            exit 1
        else
            echo -e "${SUCCESS}Successfully uninstalled cloudflared!"
            exit 0
        fi 
    else
        echo -e "${WARN}Cloudflared not currently installed"
        exit 1
    fi
}

usage () {
    echo -e $usage_string
}

# Get switch flags 
# t for the connector token [required]
# h for help message
# i for install
# r for remove
while getopts 'rt:hi' flag
do
	case "$flag" in
		t) token=${OPTARG};;
		h) usage; exit 69;;
        i) install_opt=1;;
        r) remove_opt=1;;
		?) usage; exit 69;;
	esac
done

if [ $remove_opt == 1 ]; then
    remove
fi

if [ ! "$token" ]; then
	usage
	exit 69
fi

if [[ $install_opt == 1 ]]; then
    install $token
else
    usage
    exit 69
fi 
