# vnet.json

## Description

Virtual network module.  Allows simplified and flexible calling from other templates.

## Parameters

### Simple strings

* vNetName
* vNetAddressPrefix
* subnetName
* subnetAddressPrefix

### Optional

* createVnet (boolean, default true)
* location (defaults to resource group)
* tags (defaults to resource group)
* vnetAddressPrefixes (array of multiple address spaces)
* dnsServers (array of DNS server IPs)
* nsgResourceGroup (used in combination with the subnet objects)
* defaultSubnetNSG (default NSG name to apply to subnets if not specified explicitly )

### Rich arrays and objects

* subnet (object)

```json
{
    "addressPrefix": "10.0.0.0/24",
    "name": "subnet",
    "nsg": "nsgName"
}
```

Note that nsg value should be either the name of an NSG in the current resource group (overridden by nsgResourceGroup), or a full resourceId.

* subnets (array of subnet objects

```json
[
    {
        "addressPrefix": "10.0.0.0/24",
        "name": "GatewaySubnet"
    },
    {
        "addressPrefix": "10.0.1.0/24",
        "name": "subnet1",
        "nsg": "nsgName"
    }
]
```

* vnet

```json
{
    "name": "vnetName",
    "addressPrefixes": [
      "10.0.0.0/16"
    ],
    "dnsServers": [
        "1.1.1.1",
        "1.0.0.1"
    ],
    "subnets": [
      {
        "name": "subnet1",
        "addressPrefix": "10.0.1.0/24",
        "nsg": "ResourceGroupDefault"
      }
      {
        "name": "subnet2",
        "addressPrefix": "10.0.2.0/24",
        "nsg": "ResourceGroupDefault"
      }
    ]
}
```