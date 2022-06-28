#!/bin/bash

declare UNIQUER=""
declare LOCATION=""
declare RESOURCES_PREFIX=""
declare -r USAGE_HELP="Usage: ./deploy.sh -l <LOCATION> [-u <UNIQUER> -r <RESOURCES_PREFIX>] -s <SUBSCRIPTION_ID>"

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

if [ ${#LOCATION} -eq 0 ]; then
    _error "Required LOCATION parameter is not set!"
    _error "${USAGE_HELP}" 2>&1
    exit 1
fi

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
    export ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID}
    export ARM_TENANT_ID=$(echo "${_azuresp_json}" | jq -r ".tenant")
    az login --service-principal --username "${ARM_CLIENT_ID}" --password "${ARM_CLIENT_SECRET}" --tenant "${ARM_TENANT_ID}"
    az account set --subscription "${ARM_SUBSCRIPTION_ID}"
}

lint_terraform() {
    cd terraform
    for i in $@;
    do
        cd $i
        SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
        terraform fmt -check
        if [ $? -ne 0 ]; then
            echo "##[in folder] $SCRIPT_DIR"
            _error "Terraform files are not properly formatted!"
            exit 1
        fi
        cd ..
    done
    cd ..
    # echo "End of loop"
    # exit 1
}

# iterate_terraform_folder() {
#     cd terraform/
#     for i in $@;
#     do
#         SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
#         echo $SCRIPT_DIR
#         cd $i
#         SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
#         echo $SCRIPT_DIR
#         cd ..
#     done
#     echo "End of loop"
# }

init_terrafrom_with_path_local() {
    cd terraform/$1
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    echo $SCRIPT_DIR
    terraform init -backend=false
}

init_terrafrom() {
    terraform init -backend-config=storage_account_name="${TFSTATE_STORAGE_ACCOUNT_NAME}" -backend-config=container_name="${TFSTATE_STORAGE_CONTAINER_NAME}" -backend-config=key="${TFSTATE_KEY}" -backend-config=resource_group_name="${TFSTATE_RESOURCES_GROUP_NAME}"
}

init_terrafrom_local() {
    terraform init -backend=false
}

validate_terraform() {
    terraform validate
}

preview_terraform() {
    terraform plan --detailed-exitcode -var="location=${LOCATION}" -var="resources_prefix=${RESOURCES_PREFIX}"
    return $?
}

deploy_terraform() {
    terraform apply --auto-approve -var="location=${LOCATION}" -var="resources_prefix=${RESOURCES_PREFIX}"
}

destroy_terraform() {
    terraform destroy --auto-approve -var="location=${LOCATION}" -var="resources_prefix=${RESOURCES_PREFIX}"
}

cd_back_to_iac() {
    cd ../..
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    echo $SCRIPT_DIR
}

azure_login

# iterate_terraform_folder 'create_storage_account/' 'backup/'
terraform_folder=$(ls -1 terraform)
lint_terraform ${terraform_folder}
init_terrafrom_with_path_local 'create_storage_account/'
preview_terraform
deploy_terraform $?
cd_back_to_iac


