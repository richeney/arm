#!/bin/bash

source ~/.git-prompt.sh
export DEMO_PROMPT='\[\033[01;32m\]\w\[\033[01;33m\]$(__git_ps1 " (%s)") \[\033[01;37m\]\$ '
export TYPE_SPEED=20
export NO_WAIT=false
export PROMPT_TIMEOUT=5

source ~/demo-magic.sh

resize > /dev/null
clear

# Need Dev with group 230 pre-created

_C=false _E=false pe 'cd /git/azure-blueprints'
_C=false _E=false pe 'jq . < policies/regions.parameters.json'
_C=true  _E=false pe ''
_C=false _E=false pe 'jq . < policies/regions.rule.json'
_C=true  _E=false pe ''
_C=false _E=true  pe 'az policy definition create --name regions --display-name "Permitted regions" --description "List of permitted regions for deployment" --mode Indexed --rules policies/regions.rule.json --params policies/regions.parameters.json --output jsonc'
_C=true  _E=false pe ''
_C=false _E=false pe 'az policy definition list --query "[?contains(displayName, '\''virtual machine SKU'\'')]" --output jsonc'
_C=true  _E=false pe ''
_C=false _E=false pe 'jq . < policies/deny.initiative.definition.json'
_C=true _E=false pe 'jq . < policies/deny.initiative.parameters.json'
_C=true  _E=true  pe 'az policy set-definition create --name deny --display-name "Standard set of deny policies" --description "Limit regions and VM SKUs" --definitions policies/deny.initiative.definition.json --params policies/deny.initiative.parameters.json --output jsonc'