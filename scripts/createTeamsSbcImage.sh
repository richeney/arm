#!/bin/bash
# This script will create the SBC image

error()
{
  if [[ -n "$@" ]]
  then
    tput setaf 1
    echo "ERROR: $@" >&2
    tput sgr0
  fi

  exit 1
}

yellow() { tput setaf 3; cat - ; tput sgr0; return; }
cyan()   { tput setaf 6; cat - ; tput sgr0; return; }

# Set default values
sbcrg=teamsSbc
imagerg=teamsSbcImage
location=westeurope
source="/mnt/c/Users/richeney/Downloads/sbc-F7.20A.202.204-azure/sbc-F7.20A.202.204.vhd"

# Grab the Azure subscription ID
subId=$(az account show --output tsv --query id)
[[ -z "$subId" ]] && error "Not logged into Azure as expected."

# Create the resource group for the image

echo "az group create --name $imagerg --location $location" | yellow
az group create --name "$imagerg" --location $location --output jsonc
[[ $? -ne 0 ]] && error "Failed to create resource group $imagerg"

# Create the storage account

# saName=$(echo $image | tr '[:upper:]' '[:lower:]')$(tr -dc "[:lower:][:digit:]" < /dev/urandom | head -c 10)
saName=$(echo $imagerg | tr '[:upper:]' '[:lower:]')$(/usr/bin/md5sum <<< $subid | cut -c1-10)
echo "az storage account create --name $saName --kind BlobStorage --access-tier hot --sku Standard_LRS --resource-group $imagerg --location $location" | yellow
az storage account create --name $saName --kind StorageV2 --access-tier hot --sku Standard_LRS --resource-group $imagerg --location $location --output jsonc
[[ $? -ne 0 ]] && error "Failed to create storage account $saName"

# Grab the storage account key

saKey=$(az storage account keys list --account-name $saName --resource-group $imagerg --query "[1].value" --output tsv)
[[ $? -ne 0 ]] && error "Do not have sufficient privileges to read the storage account access key"

# Create the containers

for container in images disks
do
  echo "az storage container create --name $container --account-name $saName --account-key $saKey" | yellow
  az storage container create --name $container --account-name $saName --account-key $saKey --output jsonc
  [[ $? -ne 0 ]] && error "Failed to create the container $container"
done

[[ ! -f $source ]] && error "$source not found"

# Upload the image
vhdBlob="https://$saName.blob.core.windows.net/images/$(basename $source)"
echo "azcopy --source $source --destination $vhdBlob --dest-key $saKey --blob-type page" | yellow
azcopy --source $source --destination $vhdBlob --dest-key $saKey --blob-type page
sleep 10

# Create image from the VHD image
echo "az image create -g $image -n ${vhdBlob##*/} --source $vhdBlob --os-type linux" | yellow
az image create -g $image -n ${vhdBlob##*/} --source $vhdBlob --os-type linux
