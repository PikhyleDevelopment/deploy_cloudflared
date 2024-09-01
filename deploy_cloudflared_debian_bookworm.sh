#!/bin/bash

# Color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'

# Usage string
usage="${YELLOW}$(basename "$0") -t CONNECTOR_TOKEN"

echo ' 
 ██████╗██╗      ██████╗ ██╗   ██╗██████╗ ██╗     ███████╗ █████╗ ██████╗ ███████╗██████╗     ██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗   ██╗███╗   ███╗███████╗███╗   ██╗████████╗
██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗██║     ██╔════╝██╔══██╗██╔══██╗██╔════╝██╔══██╗    ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝████╗ ████║██╔════╝████╗  ██║╚══██╔══╝
██║     ██║     ██║   ██║██║   ██║██║  ██║██║     █████╗  ███████║██████╔╝█████╗  ██║  ██║    ██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚████╔╝ ██╔████╔██║█████╗  ██╔██╗ ██║   ██║   
██║     ██║     ██║   ██║██║   ██║██║  ██║██║     ██╔══╝  ██╔══██║██╔══██╗██╔══╝  ██║  ██║    ██║  ██║██╔══╝  ██╔═══╝ ██║     ██║   ██║  ╚██╔╝  ██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║   
╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝███████╗██║     ██║  ██║██║  ██║███████╗██████╔╝    ██████╔╝███████╗██║     ███████╗╚██████╔╝   ██║   ██║ ╚═╝ ██║███████╗██║ ╚████║   ██║   
 ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═════╝     ╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝   
                                                            Written by Erik Mason                                                                                                                 
'

# Get switch flags 
# t for the connector token [required]
# h for help message
while getopts ':t:h' flag
do
	case "$flag" in
		t) token=${OPTARG};;
		h) echo -e "$usage"; exit 69;;
        # If -t is supplied without an argument
		:) echo -e "${RED}Missing token argument (-t)"; exit 69;;
		?) echo "use -t and supply the connector token provided by cloudflare"; exit 69;;
	esac
done

# If no switch flag is provided
if [ ! "$token" ]; then
	echo -e "${RED}a token must be provided with -t"
	exit 69
fi

echo -e "${GREEN}Checking for curl and installing if not found"
sudo apt install curl

# The below commands are from cloudflared documentation here:
# https://pkg.cloudflare.com/index.html
echo -e "${GREEN}Creating keyrings directory.."
sudo mkdir -p --mode=0755 /usr/share/keyrings

echo -e "${GREEN}Downloading Cloudflare gpg key.."

curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

echo -e "${GREEN}Setting up Cloudflared repository.."
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared bookworm main' | sudo tee /etc/apt/sources.list.d/cloudflared.list

echo -e "${GREEN}Installing cloudflared daemon.."
sudo apt update && sudo NEEDRESTART_MODE=a apt install cloudflared -y

echo -e "${GREEN}Installationg complete. Registering service.."

sudo cloudflared service install $token

echo -e "${GREEN}Successfully installed and registered cloudflared"
