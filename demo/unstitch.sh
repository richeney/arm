#!/bin/bash

set -ex

# Move Visual Studio subscription back to Prod (100)
az account management-group subscription add --name 100 --subscription 2d31be49-d959-4415-bb65-8aec2c90ba62

# Delete the sub-management groups
az account management-group delete --name 230  # Dev
az account management-group delete --name 220  # Test