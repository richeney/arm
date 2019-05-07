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

pe 'az policy definition show --name 1e30110a-5ceb-460c-a204-c1c3969c6d62 --output jsonc'
