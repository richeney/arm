#!/bin/bash

guid=55378008-1976-1976-1976-123456789abc
rg=guidtest

correlationId=$(az group deployment show --name pid-$guid --resource-group $rg --query properties.correlationId --output tsv)

deployments=$(az group deployment list --resource-group $rg --output tsv --query "[?properties.correlationId == '$correlationId'].name")

for deployment in $deployments
do
  az group deployment show --resource-group $rg --name $deployment --query properties.outputResources[].id --output tsv
done