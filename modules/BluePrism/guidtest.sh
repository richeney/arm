#!/bin/bash

guid[0]='null'

for i in {1..5}
do
  guid[$i]=$(uuidgen -t)
  echo "$i: ${guid[$i]}"
done | tee guidtest.out

set +x

jsonUri=https://raw.githubusercontent.com/richeney/azure-blueprints/master/modules/BluePrism/disk.json


az configure --defaults group=guidtest location=westeurope

az group create --name guidtest
