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

prereqs()
{
  # Check for zip and jq
  _pkgs=""
  [[ ! -x /usr/bin/zip ]] && _pkgs="$_pkgs zip"
  [[ ! -x /usr/bin/jq ]]  && _pkgs="$_pkgs jq"

  if [[ -n "$_pkgs"  ]]
  then sudo apt-get update && sudo apt-get install --assume-yes -qq $_pkgs
  fi

  [[ ! -x /usr/bin/zip ]] && error "Install package \"zip\" and rerun"
  [[ ! -x /usr/bin/jq ]] && error "Install package \"jq\" and rerun"
}

usage()
{
  script=$(basename $0)
  cat <<EOF
Usage:

  Create custom policy at subscription scope for current context:
  $script uri

  Create custom policies at specified management scope:
  $script -m <management group> uri1 uri2 uri3

  Display help:
  $script -h

Management scope can be either the name or full ID. Display name will not be accepted.

The uris should be raw JSON files. Format is the full ARM Azure Policy resource format. Example file:
https://github.com/richeney/arm/blob/master/policies/auditemptytag.json

Either specify fully pathed URIs or the files will be prefixed with \$URIBASE variable.
Default \$URIBASE is https://raw.githubusercontent.com/richeney/arm/master/policies.
EOF

  [[ -n "$@" ]] && error "$@"
  exit 0
}
# Read in the switches

while getopts ":m:h" opt; do
  case ${opt} in
    m ) mg=$OPTARG
        [[ "$(basename $mg)" != "$mg" && "$(dirname $mg)" != "/providers/Microsoft.Management/managementGroups" ]] && usage "Unexpected value for -m switch"
        mg=$(basename $mg)
        ;;
    h ) usage ;;
    * ) usage ;;
  esac
done

shift $((OPTIND -1))

## Get list of uris
uris=$@
[[ -z "$uris" ]] && usage "uri(s) not specified"

## Check prereqs
prereqs

## Find the subscription GUID - this will also test we are logged in

subId=$(az account show --output tsv --query id)
[ $(echo "$subId" | wc -c) -ne 37 ] && error "Could not determine the subscription GUID. Are you logged into Azure?"


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

  if [[ -n "$mg" ]]
  then
    az policy definition create \
  	--name "$name" \
  	--display-name "$displayName" \
  	--description "$description" \
  	--mode $mode \
    --management-group $mg \
  	--params "$params" \
  	--rules "$rule" \
  	--output tsv --query id
  else
    az policy definition create \
  	--name "$name" \
  	--display-name "$displayName" \
  	--description "$description" \
  	--mode $mode \
    --subscription $subId \
  	--params "$params" \
  	--rules "$rule" \
  	--output tsv --query id
  fi

  [ $? -ne 0 ] && error "Failed to run az policy definition create successfully"
done
