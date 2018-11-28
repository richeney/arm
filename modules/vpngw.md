# vnet.json

## Description

Adds a VPN Gateway uinto an existing vNet.  The GatewaySubnet must already exist. The public IP (PIP) will also be created.

## Parameters

### Required

* vNetName

### Optional

* vpnGwName (Default: vpnGateway)
* gatewaySku (Drop down of all SKUs, defaults to VpnGw1)
* pipSku (Basic or Standard, default is set dependant on SKU)
* asNumber (integer value used within the BGP configuration, defaults to 65515)