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

## Set default location

Not all of the following commands have `--location` specified. Set your location using `az configure --defaults location=westeurope`.

All of the commands assume that you are creating files within a folder called *policies*.

> Some of the commands that accept JSON, relative file path or URI seem to need a leading directory for the relative file path.

Note that it is assumed that you are testing this within your own dedicated test / dev subscription for training purposes. It is not recommended to use this lab to learn if you are using a production subscription or one that is shared!

## Tagging best practice

ADD IN LINK FOR GOVERNANCE, THEN DISCUSS

<https://www.cryingcloud.com/2016/07/18/azure-resource-tagging-best-practices/>

We will add a few of these:

**env** | Enforce value
**maintenance** | Assign default
**costcode** | Required from permitted list
**owner** | Require
**department** | Require
**application** | Require

We'll play nice and use audit as the policy effect for the required tags. Deployments will proceed even without the required tags, but they will be flagged as non-compliant.

The policies can always be switched from **audit** to **deny** at a later point once everything is compliant to ensure it stays that way.

We will need a few different types of policies:

Enforce a tag and its value | BuiltIn | 1e30110a-5ceb-460c-a204-c1c3969c6d62
Apply tag and its default value | BuiltIn | 2a0e14a6-b0a6-4fab-991a-187a4f81c498
Force a tag and value | Custom | -
Require tag | Custom | -
Require tag value from array | Custom -

The full definition ID for a BuiltIn policies is `/providers/Microsoft.Authorization/policyDefinitions/<policyGuid>`.

You can browse the BuiltIn policies and initiatives very easily in the portal. Example CLI command to list the BuiltIn policies that have *tag* somewhere in the description:

```bash
az policy definition list --query "[? policyType == 'BuiltIn' && contains(description, 'tag')].{id:id, displayName:displayName, description:description, name:name}" --output jsonc
```

## Policy Initiatives

Policy initiatives are collections of policies. They used to be named Policy Sets so you will see that in the CLI commands.  Using initiatives massively simplifies the ongoing management for policy assignments.

There are a number of BuiltIn initiatives. Browse the Azure Policy services Definitions screen in the portal to see how they look. Filter on Definition Type to Initiative. The preview Enable Azure Monitor for VMs is a good example.

It audits the various monitor agents for Linux and Windows VMs and will also deploys them if they are not present. As well as reducing down the number of initial assignments, it also allows for better lifecycle management. If the agents for Azure Monitor change then the policies used within the initiative definition will be updated, pushing through the required changes to the governed resources. They will then be flagged as non-compliant, and can be remediated through the Azure Policy screens.

Even if you are only looking to assign a single policy then I would always wrap that in an initiative. If you then add or modify policies then the next compliancy run will reflect the new requirements, allowing for easy remediation against existing resources as well as applying to the deployment of new resources.

The other recommendation is to create initiatives at the highest management group possible.  Usually that would be the default root Tenant Group, but you may have separate policy initiatives for production vs. non-production, in which case you can create management groups to help split those subscriptions and then apply the policy initiative at the appropriate scope level.

## Create a custom initiative

We'll make a simple custom initiative and add a policy in for the maintenance tag first. It is a simple tag default and there is a BuiltIn for that.

1. Check the BuiltIn policy definition:

    ```bash
    az policy definition show --name 2a0e14a6-b0a6-4fab-991a-187a4f81c498     --output jsonc
    ```

    Let's add that into a new initiative and use the parameters within the definition to set that tag name and value.

1. Create a tags.initiative.definition.json file in your policies folder:

    ```json
    [
        {
            "comment": "Assign default tag value for maintenance",
            "parameters": {
                "tagName": {
                    "value": "Maintenance"
                },
                "tagValue": {
                    "value": "Tue:04:00-Tue:04:30"
                }
            },
            "policyDefinitionId": "/providers/Microsoft.Authorization/policyDefinitions/2a0e14a6-b0a6-4fab-991a-187a4f81c498"
        }
    ]
    ```

    The comment will be ignored when the definition is read by the CLI command.

1. By default initiatives are created at the subscription scope, so we'll specify the root management group:

    ```bash
    rootId=$(az account show --output tsv --query tenantId)
    az policy set-definition create --name tags --display-name Tags --description "Tags: maintenance" --definitions policies/tags.initiative.definition.json --management-group $rootId --output jsonc
    ```

> The ids for management groups are integers or GUIDs.  The GUID for the tenantRootGroup is the tenantId.

## Create a custom policy

You can use policies multiple times using the parameters in the definition. We'll add in an audit that checks if Owner, Department and Application tags exist.

1. Take a look at the "Enforce a tag and its value" policy definition:

    ```bash
    az policy definition show --name 1e30110a-5ceb-460c-a204-c1c3969c6d62 --output jsonc
    ```

    The effect is deny.  So not quite what we want. Instead, lets duplicate the BuiltIn policy, and change it to audit instead.

1. Copy the parameter and policy sections into files:

    ```bash
    az policy definition show --name 2a0e14a6-b0a6-4fab-991a-187a4f81c498     --query parameters --output json > policies/audittag.parameters.json
    az policy definition show --name 2a0e14a6-b0a6-4fab-991a-187a4f81c498     --query policyRule --output json > policies/audittag.rule.json
    ```

1. Remove the tag value from the parameters files and save.

    ```json
    {
      "tagName": {
        "metadata": {
          "description": "Name of the tag, such as 'Owner'",
          "displayName": "Tag Name"
        },
        "type": "String"
      }
    }
    ```

1. Simplify the effect section in the rule so that it only has an effect of audit.

    ```json
    {
      "if": {
        "exists": "false",
        "field": "[concat('tags[', parameters('tagName'), ']    ')]"
      },
      "then": {
        "effect": "audit"
      }
    }
    ```

    This will allow non-tagged resources to be created, but they will be audited as non-compliant.

1. Create the custom policy definition:

    ```bash
    az policy definition create --name audittag --display-name "Audit that a tag exists" --description "Audit that the provided tag exists." --mode Indexed --rules policies/audittag.rule.json --params policies/audittag.parameters.json --management-group $rootId --output jsonc
    ```

    The id for the custom policy definition is required for the next step.

1. Grab the policy definition id:

    ```bash
    az policy definition show --name audittag --management-group $rootId --output tsv --query id

1. Add the new policy three times to the initiative, once for each of the required tags: owner, department and application.

    Example object for the definition array:

    ```json
        {
            "comment": "Audit application tag",
            "parameters": {
                "tagName": {
                    "value": "Application"
                }
            },
            "policyDefinitionId": "/providers/Microsoft.Management/managementgroups/f246eeb7-b820-4971-a083-9e100e084ed0/providers/Microsoft.Authorization/policyDefinitions/audittag"
        }
    ```

1. Update the initiative

    ```bash
    az policy set-definition update --name tags --description "Tags: owner, department, application, maintenance" --definitions policies/tags.initiative.definition.json --management-group $rootId --output jsonc
    ```

    Note that we did not need to update the displayName as that is unchanged.

1. View the definition

    Open the portal, go to the Definitions screen within Azure Policy, and filter on Initiatives and Custom.  (You may also need to select the scope.)

    ![Initiative Definition](/automation/policy/images/initiativeDefinition.png)

    It isn't great for seeing values of the parameters used within the policy definition, so the CLI is clearer for that. We'll output in YAML format for a change:

    ```bash
    az policy set-definition show --management-group $rootId --name tags --output yaml
    ```

    Your output should be similar to:

    ```yaml
    description: 'Tags: owner, department, application, maintenance'
    displayName: Tags
    id: /providers/Microsoft.Management/managementgroups/f246eeb7-b820-4971-a083-9e100e084ed0/providers/    Microsoft.Authorization/policySetDefinitions/tags
    metadata:
      createdBy: c3db7950-382d-40eb-931c-9b150e84b1dd
      createdOn: '2019-03-26T16:13:35.3581372Z'
      updatedBy: c3db7950-382d-40eb-931c-9b150e84b1dd
      updatedOn: '2019-03-27T11:08:37.4767698Z'
    name: tags
    parameters: null
    policyDefinitions:
    - parameters:
        tagName:
          value: Maintenance
        tagValue:
          value: Tue:04:00-Tue:04:30
      policyDefinitionId: /providers/Microsoft.Authorization/policyDefinitions/2a0e14a6-b0a6-4fab-991a-187a4f81c498
      policyDefinitionReferenceId: '11689655614511723004'
    - parameters:
        tagName:
          value: Owner
      policyDefinitionId: /providers/Microsoft.Management/managementgroups/f246eeb7-b820-4971-a083-9e100e084ed0/providers/    Microsoft.Authorization/policyDefinitions/audittag
      policyDefinitionReferenceId: '10436318141432591001'
    - parameters:
        tagName:
          value: Department
      policyDefinitionId: /providers/Microsoft.Management/managementgroups/f246eeb7-b820-4971-a083-9e100e084ed0/providers/    Microsoft.Authorization/policyDefinitions/audittag
      policyDefinitionReferenceId: '692846189219936038'
    - parameters:
        tagName:
          value: Application
      policyDefinitionId: /providers/Microsoft.Management/managementgroups/f246eeb7-b820-4971-a083-9e100e084ed0/providers/    Microsoft.Authorization/policyDefinitions/audittag
      policyDefinitionReferenceId: '17723888520643171314'
    policyType: Custom
    type: Microsoft.Authorization/policySetDefinitions
    ```

We'll leave the definition there for the moment and add the remaining tag policies to that initiative later. Let's get it assigned to a management group.

## Creating Management Groups via CLI

Policies can be created within a subscription or a management group. We'll create a management group and move the current subscription underneath it.

> The *name* for a management group should be an integer or GUID. The CLI will allow you to create manage groups with alpha names, but the portal will then show errors.

1. Create the management groups

    ```bash
    subscriptionId=$(az account show --output tsv --query id)
    az account management-group create --name 200 --display-name "Non-Prod"
    az account management-group create --name 230 --display-name "Dev" --parent 200
    az account management-group list --output table
    ```

1. Move the subscription underneath the Dev management group

    ```bash
    az account management-group subscription add --name 230 --subscription $subscriptionId
    ```

1. Recursively list out the Non-Prod management group structure and subscriptions

    ```bash
    az account management-group show --name 200 --recurse --expand --output jsonc
    ```

## Assign the policy initiative

We'll assign the new custom initiative to the Dev management group containing the subscription.

1. Derive the required parameters

    ```bash
    initiativeId=$(az policy set-definition show --name tags --management-group $rootId --output tsv --query id)
    devId=$(az account management-group list --query "[?displayName == 'Dev'].id" --output tsv)
    devName=$(basename $devId)
    ```

    You can echo out the value of any of these variables to check them, e.g. `echo $devName`.

1. Assign the initiative

    ```bash
    az policy assignment create --name tags --display-name "Tags" --location westeurope --policy-set-definition $initiativeId --scope $devId --output jsonc
    ```

## Check assignment and create disks

1. Check the assignment

    Go to Azure Policy in the portal. The Overview should show the initiative assigned as Tags against the Dev management group and therefore the policies will apply to your subscription.

    ![Initiative Assignment](/automation/policy/images/initiativeDefinition.png)

1. Create a new resource group and two disks, one without tags and one with:

    ```bash
    az group create --name initiativeTest --location westeurope
    az disk create --resource-group initiativeTest --name tagless --location westeurope --sku Standard_LRS --size-gb 32 --output jsonc
    az disk create --resource-group initiativeTest --name tagged --location westeurope --sku Standard_LRS --size-gb 32 --tags Owner="Richard Cheney" Department=OCP Application=tagtest --output jsonc
    ```

The policy may take up to 30 minutes so carry on with the lab and come back to it.

## Combining policies and initiative parameters

We want to force all resources within the Dev management group to have an Environment tag, and ensure that it is set to Dev.  We also want to be able to set the forced tag value differently if we assign this same initiative definition to other management groups, such as Prod, Pre-Prod, Test or UAT.

We will introduce initiative parameters so that we can set the environment upon assignment. Take a look at the parameters structure for [policy initiatives](https://docs.microsoft.com/en-gb/azure/governance/policy/concepts/definition-structure#initiatives).  They are the same format as the [parameters structure](https://docs.microsoft.com/en-gb/azure/governance/policy/concepts/definition-structure#parameters) for individual policy and will be familiar to anyone used to ARM templates.

Read about the [strongType](https://docs.microsoft.com/en-gb/azure/governance/policy/concepts/definition-structure#strongtype) property.  It is not relevant to this lab as we are solely looking at tags, but should be included for any policies or initiatives that may be assigned in the portal and relate to any of the following:

* location
* resourceTypes
* storageSkus
* vmSKUs
* existingResourceGroups
* omsWorkspace

> Note that OMS has been deprecated as a suite, but references still litter the commands and REST API. IF you need a workspace for the Logs within Azure Monitor then it is `omsWorkspace`.

We'll also use  multiple policies within the initiative. You cannot have multiple **if** and **then** blocks within a policy, but you can combine multiple policies to get the effect you want.  We can do this to force that tag value.

We will use both the assign default and deny BuiltIn policies.

1. Remind yourself of the two policies

    ```bash
    ## Create a tag with default value
     az policy definition show --name 2a0e14a6-b0a6-4fab-991a-187a4f81c498 --output jsonc

    ## Enforce a tag and specific value
    az policy definition show --name 1e30110a-5ceb-460c-a204-c1c3969c6d62 --output jsonc
    ```

    Combining the two will ensure that it is created correctly, and that it cannot be created incorrectly

1. Define a tags.initiative.parameters.json file in your policies folder:

    ```json
    {
        "environment": {
            "type": "string",
            "metadata": {
                "description": "Environment, from Prod, UAT, Test, Dev.",
                "displayName": "Environment"
            },
            "defaultValue": "Prod",
            "allowedValues": [
                "Prod",
                "UAT",
                "Test",
                "Dev"
            ]
        }
    }
    ```

    Note that you must have a defaultValue if you have an allowedValues list.

1. Add the following objects into the tags.initiative.definition.json array:

    ```json
    {
        "comment": "Assign parameterised tag value for environment",
        "parameters": {
            "tagName": {
                "value": "Environment"
            },
            "tagValue": {
                "value": "[parameters('environment')]"
            }
        },
        "policyDefinitionId": "/providers/Microsoft.Authorization/policyDefinitions/2a0e14a6-b0a6-4fab-991a-187a4f81c498"
    },
    {
        "comment": "Enforce parameterised tag value for environment",
        "parameters": {
            "tagName": {
                "value": "Environment"
            },
            "tagValue": {
                "value": "[parameters('environment')]"
            }
        },
        "policyDefinitionId": "/providers/Microsoft.Authorization/policyDefinitions/1e30110a-5ceb-460c-a204-c1c3969c6d62"
    }
    ```

1. Update the policy initiative's description

    Let's add in the full description now, including both environment and the planned costcode tag.

    ```bash
    az policy set-definition update --name tags --description "Tags: owner, department, application, environment, costcode, maintenance" --management-group $rootId --output jsonc
    ```

1. Update the policy initiative's definition

    ```bash
    az policy set-definition update --name tags --management-group $rootId --definitions policies/tags.initiative.definition.json --params policies/tags.initiative.parameters.json --output jsonc
    ```

    Note the additional switch for the parameters file.

1. Check the definition and assignment

    Feel free to check the portal for the initiative definition and assignment.  You'll see that it now has all six policies immediately in effect.

    Therefore, the value of the environment parameters for the Dev assignment will be incorrect, using the default value of Prod.

    So you may need to double check where an initiative has been assigned:

    ```bash
    rootId=$(az account show --output tsv --query tenantId)
    initiativeId=$(az policy set-definition show --name tags --management-group $rootId --output tsv --query id)
    az policy assignment list --disable-scope-strict-match --query "[? policyDefinitionId == '$initiativeId'].scope" --output tsv
    ```

    Our *tags* initiative should only be assigned to the Dev management group, which has a name value of 230.

    This command will create a CSV of all the assignments:

    ```bash
    az policy assignment list --disable-scope-strict-match --query "[].{name:name, policy:policyDefinitionId, scope:scope}" --output tsv | tr "\t" "," > assignments.csv
    ```

1. Create a JSON object for the parameter:

    ```bash
    devparams='{"environment": { "value": "Dev" }}'
    echo $devparams | jq .
    ```

    You could also have a file or URI containing the JSON.

1. Reassign the policy using the parameter

    ```bash
    initiativeId=$(az policy set-definition show --name tags --management-group $rootId --output tsv --query id)
    devId=$(az account management-group list --query "[?displayName == 'Dev'].id" --output tsv)
    devName=$(basename $devId)
    az policy assignment create --name tags --display-name "Tags" --location westeurope --policy-set-definition $initiativeId --params "$devparams" --scope $devId --output jsonc
    ```

    Notice that the parameters are now part of the assignment definition.  You could combine the two previous JMESPATH queries for a nice query:

    ```bash
    az policy assignment list --disable-scope-strict-match --query "[? policyDefinitionId == '$initiativeId'].{name:name, scope:scope, parameters:parameters}" --output jsonc
    ```

## Using defined lists of possible values

The last of the tags is costcode.  We'll take a similar approach, defining a list of costcodes in the definition itself, and we'll then parameterise a default costcode value from that list.

1. Extend the initiative parameters file

    ```json
        "costcodes": {
        "type": "array",
        "metadata": {
            "description": "List of permitted cost codes as a JSON array.",
            "displayName": "Cost Codes"
        },
        "defaultValue": [
            "3141592654",
            "2718281828",
            "1618033999"
        ]
    },
    "costcode": {
        "type": "string",
        "metadata": {
            "description": "Default cost code. Must be in the Cost Codes array. Will default to the first in the array.",
            "displayName": "Default Cost Code"
        },
        "defaultValue": "3141592654"
    }
    ```

1. Create a new policy that checks for existence in a list

    Create the two files

    ```bash
    az policy definition create --name audittagvalues --display-name "Audit tag value" --description "Audit that a tag exists and has an allowed value. Control the effect." --mode Indexed --rules policies/audittagvalues.rule.json --params policies/audittagvalues.parameters.json --management-group $rootId --output jsonc
    ```

1. Extend the initiative definition file

    ```json
        {
        "comment": "Assign parameterised default tag value for costcode",
        "parameters": {
            "tagName": {
                "value": "Costcode"
            },
            "tagValue": {
                "value": "[parameters('costcode')]"
            }
        },
        "policyDefinitionId": "/providers/Microsoft.Authorization/policyDefinitions/2a0e14a6-b0a6-4fab-991a-187a4f81c498"
    },
    {
        "comment": "Audit costcode is in permitted list",
        "parameters": {
            "tagName": {
                "value": "Costcode"
            },
            "tagValues": {
                "value": "[parameters('costcodes')]"
            },
            "effect": {
                "value": "audit"
            }
        },
        "policyDefinitionId": "/providers/Microsoft.Management/managementgroups/f246eeb7-b820-4971-a083-9e100e084ed0/providers/Microsoft.Authorization/policyDefinitions/audittagvalues"
    }
    ```

1. Update the initiative

    ```bash
    az policy set-definition update --name tags --management-group $rootId --definitions policies/tags.initiative.definition.json --params policies/tags.initiative.parameters.json --output jsonc
    ```

1. Update the assignment with additional parameters

    ```bash
    devparams='{"environment": { "value": "Dev" }, "costcode": { "value": "2718281828"}}'
    echo $devparms | jq .
    az policy assignment create --name tags --display-name "Tags" --location westeurope --policy-set-definition $initiativeId --params "$devparams" --scope $devId --output jsonc
    ```

1. Add in tests and audit....

## Subscription Level Templates

<https://docs.microsoft.com/en-us/azure/azure-resource-manager/deploy-to-subscription>

Links to ARM reference (2018-05-01 schema versions):

* [Policy Definitions](https://docs.microsoft.com/en-gb/azure/templates/microsoft.authorization/2018-05-01/policydefinitions)
* [Policy Set Definitions](https://docs.microsoft.com/en-gb/azure/templates/microsoft.authorization/2018-05-01/policysetdefinitions)
* [Policy Assignments](https://docs.microsoft.com/en-gb/azure/templates/microsoft.authorization/2018-05-01/policyassignments)

OK, create a file called tags.initiative.json:

```json

```

```bash
az deployment create --name tagInitiative --location westeurope --template-file policies/tags.initiative.json --output jsonc
```