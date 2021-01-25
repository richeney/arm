#!/bin/bash
###################################################################################################
## Loop through stdin of ARM resource compliant policy files
## Example format is
##    https://github.com/richeney/azure-blueprints/blob/master/policies/auditemptytag.json
## Requires az and jq
## Can use unpathed URIs if you have exported URIBASE
###################################################################################################

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

# Check for zip and jq
_pkgs=""
[[ ! -x /usr/bin/zip ]] && _pkgs="$_pkgs zip"
[[ ! -x /usr/bin/jq ]]  && _pkgs="$_pkgs jq"

if [[ -n "$_pkgs"  ]]
then sudo apt-get update && sudo apt-get install --assume-yes -qq $_pkgs
fi

[[ ! -x /usr/bin/zip ]] && error "Install package \"zip\" and rerun"
[[ ! -x /usr/bin/jq ]] && error "Install package \"jq\" and rerun"

# Read in files from stdin

if [[ -z "$@" ]]
then
cat <<EOF
Usage:
	$0 uri [uri uri]
	$0 -

The uris should be raw JSON files in policy format. If using stdin then it expects a list of uris.

Example file format matching the ARM policy resource type:
<https://github.com/richeney/azure-blueprints/blob/master/policies/auditemptytag.json>

URIBASE environment variable provides a default URI location, e.g.:

export URIBASE=https://raw.githubusercontent.com/richeney/arm/master/policies

Otherwise use full URIs.
EOF
exit 0
fi

## Get list of uris
uris=$@
if [ $1 == '-' ]
then
  uris=$(cat -)
fi

## Find the tenantId GUID - this is the name for the Tenant Root Group management group

tenantId=$(az account show --output tsv --query tenantId)
[ $(echo "$tenantId" | wc -c) -ne 37 ] && error "Could not determine the GUID for the AAD tenant."

## Loop through the URIs and create the policy definition at the Tenant Root Group

uribase=${URIBASE:-https://raw.githubusercontent.com/richeney/arm/master/policies}

for uri in $uris
do
  [ "$(basename $uri)" == "$uri" ] && uri=$uribase/$(basename --suffix .json $uri).json
  json=$(curl -sSL $uri) || error "Failed to curl $uri"
  [[ "$json" == '404: Not Found' ]] && error "Could not find $uri"

  name=$(jq -r .name <<<$json)
  displayName=$(jq -r .properties.displayName <<<$json)
  description=$(jq -r .properties.description <<<$json)
  mode=$(jq -r .properties.mode <<<$json)
  params=$(jq -r .properties.parameters <<<$json)
  rule=$(jq -r .properties.policyRule <<<$json)

  az policy definition create \
	--name "$name" \
	--display-name "$displayName" \
	--description "$description" \
	--mode $mode \
        --management-group $tenantId \
	--params "$params" \
	--rules "$rule" \
	--output tsv --query id

  [ $? -ne 0 ] && error "Failed to run az policy definition create successfully"
done
