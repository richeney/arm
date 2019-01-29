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

az policy definition create --name costcode --description "Require costcode tag to be specified from approved list" --display-name "Cost Code required" --rules policies/costcode.rule.json --params policies/costcode.params.json --management-group Production

Needs a leading directory if relative e.g. `policies/name.rule.json`- cannot use files in current directory or dot notation.  Absolute pathing is fine as are uris.

mgmt=Production
policy=costcode
mgmtId=/providers/Microsoft.Management/managementGroups/$mgmt
policyId=$mgmtId/providers/Microsoft.Authorization/policyDefinitions/costcode


az policy definition show --name $policy --management-group $mgmt --query parameters
{
  "costcodes": {
    "metadata": {
      "description": "The list of permitted cost codes.",
      "displayName": "Cost Codes"
    },
    "type": "Array"
  }
}

costcodes='{"costcodes":{"value":[ "31415926536", "2718281828", "161803399887" ]}}'
echo $costcodes | jq .


/git/azure-blueprints (master) $ az policy assignment create --name costcode --display-name "Require costcode tag from list" --policy $policyId --scope $mgmtId --params "$costcodes"

```json
{
  "description": null,
  "displayName": "Require costcode tag from list",
  "id": "/providers/Microsoft.Management/managementGroups/Production/providers/Microsoft.Authorization/policyAssignments/costcode",
  "metadata": null,
  "name": "costcode",
  "notScopes": null,
  "parameters": {
    "costcodes": {
      "value": [
        "31415926536",
        "2718281828",
        "161803399887"
      ]
    }
  },
  "policyDefinitionId": "/providers/Microsoft.Management/managementgroups/Production/providers/Microsoft.Authorization/policyDefinitions/costcode",
  "scope": "/providers/Microsoft.Management/managementGroups/Production",
  "sku": {
    "name": "A0",
    "tier": "Free"
  },
  "type": "Microsoft.Authorization/policyAssignments"
}
```

## Prove Azure Policy compliancy

Should be 67% (check screenshots folder)

Remove the northeurope disk.  (Trust me to pick a resource type that doesn't migrate easily.)

Remove the standalone policy at the group level:

az policy assignment delete --name uk --resource-group london

## Create a disk with no tags and one with tags

az disk create --resource-group london --name tagless --location uksouth --sku Standard_LRS --size-gb 32 --output jsonc

OK policy definition and assigment is not showing up in the portal within the Management Group details. Aaargh!