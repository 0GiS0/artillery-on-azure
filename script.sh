#Create a storage account to upload reports
RESOURCE_GROUP="artillery-load-tests"
LOCATION="northeurope"
STORAGE_NAME="artillerystuff" 

#Log in Azure
az login

#Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

#Create a storage account
az storage account create --name $STORAGE_NAME --resource-group $RESOURCE_GROUP --location $LOCATION --sku Standard_LRS
#Enable static website
az storage blob service-properties update --account-name $STORAGE_NAME --static-website --404-document 404.html --index-document index.html
#Get the connection string
CONNECTION_STRING=$(az storage account show-connection-string --name $STORAGE_NAME --resource-group $RESOURCE_GROUP | jq .connectionString)

# Build image
docker build -t 0gis0/artillery-on-aci artillery/

# Test locally
docker run \
    -v $(pwd)/tests:/tests \
    -e ARTILLERY_YAML_FILE=/tests/load.yaml \
    -e REPORT_NAME=returngis \
    -e AZURE_STORAGE_CONNECTION_STRING=$CONNECTION_STRING \
    0gis0/artillery-on-aci


### Using ACI ###
SHARE_NAME="load-tests"

#Get Azure storage access key
STORAGE_KEY=$(az storage account keys list -g $RESOURCE_GROUP -n $STORAGE_NAME --query '[0].value' -o tsv)

#Create a File Share
az storage share create --account-name $STORAGE_NAME --name $SHARE_NAME

#Upload test to the file share (se puede montar un repositorio git)
az storage file upload --account-name $STORAGE_NAME --share-name $SHARE_NAME --source tests/load.yaml

#Upload docker image to Docker Hub
docker push 0gis0/artillery-on-aci

#Create Azure Container Instances
CONTAINER_NAME="artillery-on-azure"

az container create --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME \
    --image 0gis0/artillery-on-aci \
    --dns-name-label artillery-on-azure \
    --ports 80 \
    --restart-policy Never \
    --azure-file-volume-account-name $STORAGE_NAME \
    --azure-file-volume-share-name $SHARE_NAME \
    --azure-file-volume-account-key $STORAGE_KEY \
    --azure-file-volume-mount-path /tests \
    --environment-variables ARTILLERY_YAML_FILE=/tests/load.yaml REPORT_NAME=returngis AZURE_STORAGE_CONNECTION_STRING=$CONNECTION_STRING

#See the logs
az container attach --name $CONTAINER_NAME --resource-group $RESOURCE_GROUP

#Delete container group & storage account
az group delete --name $RESOURCE_GROUP -y


#### Terraform ####

STORAGE_ACCESS_KEY="e8m3VVBbDoqg+g77KTwCDmQYxojUPby+PHn40b7GJfaz/sNTZ/30n8YZRFmMAeqzCRPAsFiElUmDvNkqOc7QTA=="

#1. Create Puppeteer Deployment
cd tf-puppeteer
terraform init \
    -backend-config="storage_account_name=statestf" \
    -backend-config="container_name=artillery" \
    -backend-config="key=puppeteer.tfstate" \
    -backend-config="access_key=$STORAGE_ACCESS_KEY"

terraform validate
terraform plan -out puppeteer.tfplan
terraform apply puppeteer.tfplan

#Deploy Puppeter
AZURE_FUNC_NAME=$(terraform output -raw azure_function_name)

#Install Azure Functions Tools if you don't have it
brew tap azure/functions
brew install azure-functions-core-tools@3

#Deploy code on Azure Functions
cd ..
cd puppeteer-func
func azure functionapp publish $AZURE_FUNC_NAME --javascript --build remote


# 2. Create Logic App

# API Connections first
cd tf-logic-app/api-connections
terraform init \
    -backend-config="storage_account_name=statestf" \
    -backend-config="container_name=artillery" \
    -backend-config="key=api-connections.tfstate" \
    -backend-config="access_key=$STORAGE_ACCESS_KEY"

terraform validate
terraform plan -out api-connections.tfplan
terraform apply api-connections.tfplan

# Now we can create the workflow
cd tf-logic-app/workflow
terraform init \
    -backend-config="storage_account_name=statestf" \
    -backend-config="container_name=artillery" \
    -backend-config="key=logicapp.tfstate" \
    -backend-config="access_key=$STORAGE_ACCESS_KEY"

terraform validate
terraform plan -var="access_key=$STORAGE_ACCESS_KEY" -out logicapp.tfplan 
terraform apply logicapp.tfplan


#Create the resource group and ACI container
cd tf-artillery
terraform init \
    -backend-config="storage_account_name=statestf" \
    -backend-config="container_name=artillery" \
    -backend-config="key=artillery-on-azure.tfstate" \
    -backend-config="access_key=$STORAGE_ACCESS_KEY"


terraform validate
terraform plan -out artillery.tfplan
terraform apply artillery.tfplan

#Get Azure Credentials for GitHub Actions
az ad sp create-for-rbac --name artillery-deployment --role contributor --sdk-auth