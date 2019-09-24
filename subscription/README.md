# Subscription level deployments

<https://docs.microsoft.com/en-us/azure/azure-resource-manager/deploy-to-subscription>

Copy an example parameters file locally.  (ARM deployments do not support URI parameter files.)

```bash
curl -sSL https://raw.githubusercontent.com/richeney/azure-blueprints/master/deployments/example.parameters.json -o example.parameters.json
```

Deploy.

```bash
az deployment create --location westeurope --template-uri https://raw.githubusercontent.com/richeney/azure-blueprints/master/deployments/example.json --parameters example.parameters.json --verbose
```