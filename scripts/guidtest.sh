#!/bin/bash

umask 022

# Source ~/.guidtest for consistent GUIDs

[ ! -d ~/.guidtest ]  && mkdir -m 755 ~/.guidtest
guids=~/.guidtest/guids

if [ ! -s $guids ]
then
  echo "Creating and then sourcing $guids"
  for i in {1..7}
  do
    guid[$i]=$(uuidgen -t)
    echo "export guid${i}=${guid[$i]}"
  done | tee $guids
else
  echo "Sourcing existing $guids.."
  cat $guids
fi

source $guids

# Base variables, including token for REST API calls

subscriptionId=$(az account show --output tsv --query id)
rg=guidtest
loc=westeurope

accessToken=$(az account get-access-token --output tsv --query accessToken)
curlSwitches="--silent --header \"Authorization: Bearer $accessToken\" --header \"Content-Type: application/json\""

jsonUri=https://raw.githubusercontent.com/terraform-azurerm-modules/terraform-azurerm-guidtest/master/guidtest.json


echo "Create the resource group"
az group create --name $rg --location $loc --output jsonc

echo "Test 1 - use the default ARM template GUID section"
az group deployment create --resource-group $rg --name test1-$guid1 --template-uri=$jsonUri --parameters test=1 guid=$guid1 templateGuid=true --output jsonc

echo "Test 2 - use env var for Azure CLI declarative template submission"
export AZURE_HTTP_USER_AGENT=pid-$guid2
az group deployment create --resource-group $rg --name test2-$guid2 --template-uri=$jsonUri --parameters test=2 guid=$guid2 templateGuid=false --output jsonc
unset AZURE_HTTP_USER_AGENT

echo "Test 3 - use env var for imperative CLI disk creation"
export AZURE_HTTP_USER_AGENT=pid-$guid3
az disk create --resource-group $rg --name test3-$guid3 --location $loc --sku StandardSSD_LRS --size-gb 128 --output jsonc
unset AZURE_HTTP_USER_AGENT

echo "Test 4 - set user agent for REST call - user agent only includes pid-GUID"

diskData='{
    "location": "westeurope",
    "properties": {
        "creationData": {
            "createOption": "Empty"
        },
        "diskSizeGB": 128,
        "osType": "Linux",
    },
    "sku": {
        "name": "StandardSSD_LRS"
    }
}'

uri="https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Compute/disks/test4-${guid4}?api-version=2018-06-01"
curl --silent -A "pid-$guid4" --header "Authorization: Bearer $accessToken" --header "Content-Type: application/json" --data "$diskData" --request PUT $uri | jq .

echo "Test 5 - repeat test 4, but with additional text before the pid-GUID"

uri="https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Compute/disks/test5-${guid5}?api-version=2018-06-01"
prepend='Go/go1.10.3 (amd64-windows) go-autorest/v10.15.4 Azure-SDK-For-Go/v21.3.0 sql/2015-05-01-preview Terraform/0.11.9 terraform-provider-azurerm/1.18.0'
curl --silent -A "$prepend pid-$guid5" --header "Authorization: Bearer $accessToken" --header "Content-Type: application/json" --data "$diskData" --request PUT $uri | jq .

echo "Test 6 - use REST API to submit template with UserAgent set"

deployData="{
    \"properties\": {
        \"templateLink\": {
            \"uri\": \"$jsonUri\",
            \"contentVersion\": \"1.0.0.0\"
        },
        \"mode\": \"Incremental\",
        \"parameters\": {
            \"test\": {
                \"value\": 6
            },
            \"guid\": {
                \"value\": \"$guid6\"
            },
            \"templateGuid\": {
                \"value\": false
            }
        }
    }
}"

uri="https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Resources/deployments/test6-${guid6}?api-version=2018-05-01"
curl --silent -A "pid-$guid6" --header "Authorization: Bearer $accessToken" --header "Content-Type: application/json" --data "$deployData" --request PUT $uri | jq .

echo "Test 7 - deploy hardcoded Terraform file with AZURE_HTTP_USER_AGENT set"

cd ~/.guidtest

tf="
module \"guidtest\" {
    source  = \"github.com/terraform-azurerm-modules/terraform-azurerm-guidtest\"
    guid    = \"$guid7\"
    test    = \"7\"
}
"

echo "$tf" > ~/.guidtest/guidtest.tf

export AZURE_HTTP_USER_AGENT=pid-$guid7
terraform get
terraform init
terraform apply -auto-approve

echo "Completed."

exit 0