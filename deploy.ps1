#az login

#az account set 

#Set default config for resource group where the project resides
az config set defaults.group=RG-DevCenter-Dennis

#Set variables
$resourcegroup_name = "RG-DevCenter-Dennis"
$devCenter_name = "DevCenter-Dennis"
$vaultname = "KeyVault-Dennis"
$location = "westeurope"
$project_name = "Project-Dennis"
$catalog_name = "Catalog-Dennis"
$subscriptionId = "b0a62e67-fe11-4a84-b57d-860652f00af3"
$scope = "/subscriptions/b0a62e67-fe11-4a84-b57d-860652f00af3"
$gitUri = "https://github.com/DennisvandeLaar/deployment-environments.git"
$secretUri = "https://keyvault-dennis.vault.azure.net/secrets/PAT-GH"

az group create -l $location -n $resourcegroup_name

az keyvault create --location $location --name $vaultname --resource-group $resourcegroup_name
$secret = az keyvault secret set --vault-name $vaultname --name "PAT-GH" --value "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" | ConvertFrom-Json
#Todo: extract secret identifier --> requird to create a catalog

$devcenter = az devcenter admin devcenter create --location $location --name $devCenter_name --resource-group $resourcegroup_name | ConvertFrom-Json

# Create access policy for DevCenter to read secrets
az keyvault set-policy -n $vaultname --object-id $devcenter.identity.principalId --secret-permissions get list -g $resourcegroup_name

# assign owner role to managed Identity of the DevCenter, this is required to create resource groups and Azure resources in the subscription
New-AzRoleAssignment -ObjectId $devcenter.identity.principalId -RoleDefinitionName "Owner" -Scope $scope

# Add catalog from GitHub
az devcenter admin catalog create --git-hub path="/Environments" branch="main" secret-identifier=$secretUri uri=$gitUri --name $catalog_name --dev-center-name $devCenter_name --resource-group $resourcegroup_name

#create environment types (Dev, Test, Prod)
az devcenter admin environment-type create -n Development -d $devcenter.name --resource-group $resourcegroup_name
az devcenter admin environment-type create -n Test -d $devcenter.name --resource-group $resourcegroup_name
az devcenter admin environment-type create -n Production -d $devcenter.name --resource-group $resourcegroup_name

#Create project, all catalog items are directly available to the project once created. 
$project = az devcenter admin project create -n $project_name --dev-center-id $devcenter.id --description "Test project" -l $location -g $resourcegroup_name | ConvertFrom-Json

####### TODO: Need to add an environment-types to project manually

#Create an environment (This is the scope of the development teams themselves). When this fails you probably don't have access right to create an environment
az devcenter dev environment create --dev-center-name $devCenter_name --name "LogicApp-Env" --project-name $project_name --environment-type "Development" --catalog-item-name "LogicApp" --catalog-name $catalog_name --verbose
