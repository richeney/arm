#!/bin/bash

source ~/.git-prompt.sh
export DEMO_PROMPT='\[\033[01;32m\]\w\[\033[01;33m\]$(__git_ps1 " (%s)") \[\033[01;37m\]\$ '
export TYPE_SPEED=20
export NO_WAIT=false
export PROMPT_TIMEOUT=5

source ~/demo-magic.sh

resize > /dev/null
clear

# Need Non-Prod with group 200 pre-created

pe 'az account management-group create --name 230 --display-name "Dev" --parent 200'
pe 'az account management-group list --output table'
pe 'az account show'
pe 'subscriptionId=$(az account show --output tsv --query id)'
pe 'echo $subscriptionId'
pe 'az account management-group subscription add --name 230 --subscription $subscriptionId'
pe 'az account management-group show --name 200 --recurse --expand --output jsonc'
