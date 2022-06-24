# Define Terraform backend using a blob storage container on Microsoft Azure for storing the Terraform state
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstorageaccounteduenvs-rg"
    storage_account_name = "tfstorageaccounteduenvs"
    container_name       = "terraform-state-container"
    key                  = "terraform.tfstate"
  }
}