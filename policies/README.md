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

## Read only policies

```bash
az policy definition create --name westeurope --description "Only permit resource creation in West Europe" --display-name "West Europe only" --rules policies/westEurope.json
az policy definition create --name uk --description "Only permit resource creation in UK regions" --display-name "UK only" --rules policies/uk.json
az policy definition list --output table --query "[?policyType == 'Custom']"
```
