#!/bin/bash

declare UNIQUER=""
declare LOCATION=""
declare RESOURCES_PREFIX=""
declare -r USAGE_HELP="Usage: ./deploy.sh -l <LOCATION> [-u <UNIQUER> -r <RESOURCES_PREFIX>]"

_error() {
    echo "##[error] $@" 2>&1
}

if [ $# -eq 0 ]; then
    _error "${USAGE_HELP}"
    exit 1
fi

# Initialize parameters specified from command line
while getopts ":l:u:r:s:" arg; do
    case "${arg}" in
    l) # Process -l (LOCATION)
        LOCATION="${OPTARG}"
        ;;
    u) # Process -u (UNIQUER)
        UNIQUER="${OPTARG}"
        ;;
    r) # Process -r (RESOURCES_PREFIX)
        RESOURCES_PREFIX="${OPTARG}"
        ;;
    s) # Process -s (SUBSCRIPTION_ID)
        ARM_SUBSCRIPTION_ID="${OPTARG}"
        ;;
    \?)
        _error "Invalid options found: -${OPTARG}."
        _error "${USAGE_HELP}" 2>&1
        exit 1
        ;;
    esac
done

# echo "${RESOURCES_PREFIX}-ServicePrincipalBash"

apt_update_and_install_jq() {
    sudo apt update
    sudo apt install -y jq
}

azure_create_sp() {
    az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${ARM_SUBSCRIPTION_ID}" --name="${RESOURCES_PREFIX}-ServicePrincipalBash" > azuresp.json 
}

azure_login() {
    _azuresp_json=$(cat azuresp.json)
    export ARM_CLIENT_ID=$(echo "${_azuresp_json}" | jq -r ".appId")
    export ARM_CLIENT_SECRET=$(echo "${_azuresp_json}" | jq -r ".password")
    # export ARM_SUBSCRIPTION_ID=$(echo "${_azuresp_json}" | jq -r ".subscriptionId")
    export ARM_TENANT_ID=$(echo "${_azuresp_json}" | jq -r ".tenant")
    az login --service-principal --username "${ARM_CLIENT_ID}" --password "${ARM_CLIENT_SECRET}" --tenant "${ARM_TENANT_ID}"
    az account set --subscription "${ARM_SUBSCRIPTION_ID}"
}

# lint_terraform() {
#     terraform fmt -check
#     if [ $? -ne 0 ]; then
#         _error "Terraform files are not properly formatted!"
#         exit 1
#     fi
# }

# init_terrafrom() {
#     terraform init -backend-config=storage_account_name="${TFSTATE_STORAGE_ACCOUNT_NAME}" -backend-config=container_name="${TFSTATE_STORAGE_CONTAINER_NAME}" -backend-config=key="${TFSTATE_KEY}" -backend-config=resource_group_name="${TFSTATE_RESOURCES_GROUP_NAME}"
# }