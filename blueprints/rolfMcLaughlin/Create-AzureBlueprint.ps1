cls
# https://docs.microsoft.com/en-us/azure/governance/blueprints/create-blueprint-rest-api

$azContext = Get-AzureRmContext
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.AccessToken
}

# Invoke the REST API
# 42ad42c7-7e9b-464a-a612-607f9515b1cb
$restUri = 'https://management.azure.com/subscriptions/42ad42c7-7e9b-464a-a612-607f9515b1cb?api-version=2016-06-01'
$response = Invoke-RestMethod -Uri $restUri -Method Get -Headers $authHeader

$MgName = "AutoMGtk"
$BPName = "MytkBlueprint"
$ResourceGroupName = "Governance"
$StorageAccountName = "govstorage"
$container = "artefacts"
$Folder = "blueprintJSON/"
$StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName


$body1 = '{
    "properties": {
        "description": "Custom tk Azure Blueprint. This blueprint sets tag policy and role assignment on the subscription, creates a ResourceGroup, and deploys a resource template and role assignment to that ResourceGroup.",
        "targetScope": "subscription",
        "parameters": {
            "storageAccountType": {
                "type": "string",
                "metadata": {
                    "displayName": "storage account type.",
                    "description": null
                }
            },
            "tagName": {
                "type": "string",
                "metadata": {
                    "displayName": "The name of the tag to provide the policy assignment.",
                    "description": null
                }
            },
            "tagValue": {
                "type": "string",
                "metadata": {
                    "displayName": "The value of the tag to provide the policy assignment.",
                    "description": null
                }
            },
            "contributors": {
                "type": "array",
                "metadata": {
                    "description": "List of AAD object IDs that is assigned Contributor role at the subscription"
                }
            },
            "owners": {
                "type": "array",
                "metadata": {
                    "description": "List of AAD object IDs that is assigned Owner role at the resource group"
                }
            }
        },
        "resourceGroups": {
            "storageRG": {
                "description": "Contains the resource template deployment and a role assignment."
            }
        }
    }
}'

$body2 = Get-Content -Path "C:\Users\rolfma\OneDrive - Microsoft\Consulting\Thyssen Krupp\Scripting\contributor.json"
# or this way
$file2 = "contributor.json"
Get-AzureStorageFileContent -ShareName "artefacts" -Path ($Folder+$file2) -Context $StorageAccount.Context -Destination C:\tmp -Force
$body2 = Get-Content "C:\tmp\$file2"
Remove-Item "C:\tmp\$file2"

$body3 = Get-Content -Path "C:\Users\rolfma\OneDrive - Microsoft\Consulting\Thyssen Krupp\Scripting\policy.json"

$body4 = Get-Content -Path "C:\Users\rolfma\OneDrive - Microsoft\Consulting\Thyssen Krupp\Scripting\storagetag.json"

$body5 = Get-Content -Path "C:\Users\rolfma\OneDrive - Microsoft\Consulting\Thyssen Krupp\Scripting\storageAccountTypeFromBP.json"

$body6 = Get-Content -Path "C:\Users\rolfma\OneDrive - Microsoft\Consulting\Thyssen Krupp\Scripting\owner.json"


#Create the blueprint
$uri1 = "https://management.azure.com/providers/Microsoft.Management/managementGroups/$MgName/providers/Microsoft.Blueprint/blueprints/$($BPName)?api-version=2017-11-11-preview"
$response1 = Invoke-RestMethod -Uri $uri1 -Method Put -Headers $authHeader -Body $body1

$uri2 = "https://management.azure.com/providers/Microsoft.Management/managementGroups/$MgName/providers/Microsoft.Blueprint/blueprints/$BPName/artifacts/roleContributor?api-version=2017-11-11-preview"
$response2 = Invoke-RestMethod -Uri $uri2 -Method Put -Headers $authHeader -Body $body2

$uri3 = "https://management.azure.com/providers/Microsoft.Management/managementGroups/$MgName/providers/Microsoft.Blueprint/blueprints/$BPName/artifacts/policyTags?api-version=2017-11-11-preview"
$response3 = Invoke-RestMethod -Uri $uri3 -Method Put -Headers $authHeader -Body $body3

$uri4 = "https://management.azure.com/providers/Microsoft.Management/managementGroups/$MgName/providers/Microsoft.Blueprint/blueprints/$BPName/artifacts/policyStorageTags?api-version=2017-11-11-preview"
$response4 = Invoke-RestMethod -Uri $uri4 -Method Put -Headers $authHeader -Body $body4

$uri5 = "https://management.azure.com/providers/Microsoft.Management/managementGroups/$MgName/providers/Microsoft.Blueprint/blueprints/$BPName/artifacts/templateStorage?api-version=2017-11-11-preview"
$response5 = Invoke-RestMethod -Uri $uri5 -Method Put -Headers $authHeader -Body $body5

$uri6 = "https://management.azure.com/providers/Microsoft.Management/managementGroups/$MgName/providers/Microsoft.Blueprint/blueprints/$BPName/artifacts/roleOwner?api-version=2017-11-11-preview"
$response6 = Invoke-RestMethod -Uri $uri6 -Method Put -Headers $authHeader -Body $body6

# Publish Blueprint
$BPVersion = "v20181003-Demo"
$uriPublish = "https://management.azure.com/providers/Microsoft.Management/managementGroups/$MgName/providers/Microsoft.Blueprint/blueprints/$BPName/versions/$($BPVersion)?api-version=2017-11-11-preview"
$responsePublish = Invoke-RestMethod -Uri $uriPublish -Method Put -Headers $authHeader
