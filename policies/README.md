# Policies

## Resource provider

Check that the resource provider is registered:

```bash
az provider show --namespace Microsoft.PolicyInsights --query registrationState --output tsv
```

If not then register:

```bash
az provider register --namespace Microsoft.PolicyInsights
```

## Management group

Policies can be created within a subscription or a management group.  We'll create a management group and move the current subscription underneath it.



## Read only policies

```bash
az policy definition create --name westeurope --description "Only permit resource creation in West Europe" --display-name "West Europe only" --rules policies/westEurope.json
az policy definition create --name uk --description "Only permit resource creation in UK regions" --display-name "UK only" --rules policies/uk.json
az policy definition list --output table --query "[?policyType == 'Custom']"
```

## Create resource groups and assignments



londonId=$(az group create --name london --location uksouth --query id --output tsv)

az disk create --resource-group london --name northeurope --location northeurope --sku Standard_LRS --size-gb 32 --output jsonc
az disk create --resource-group london --name ukwest --location ukwest --sku Standard_LRS --size-gb 32 --output jsonc

az policy assignment create --name uk --scope $londonId --policy uk --display-name "UK Only"
az policy assignment list --output jsonc --resource-group london

az disk create --resource-group london --name uksouth --location uksouth --sku Standard_LRS --size-gb 32 --output jsonc

az disk create --resource-group london --name westeurope --location westeurope --sku Standard_LRS --size-gb 32 --output jsonc

Operation failed with status: 'Forbidden'. Details: 403 Client Error: Forbidden for url: https://management.azure.com/subscriptions/2d31be49-d959-4415-bb65-8aec2c90ba62/resourceGroups/london/providers/Microsoft.Compute/disks/westeurope?api-version=2018-06-01

Takes up to 30 minutes for the policy compliance to start.  Be patient.

## OK, add parameters
