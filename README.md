# chats-n-hack-azure-vwan

How to Deploy Bicep First Time
 
1. Install the Azure CLI from https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows (you may already have this installed)

2. Open a terminal or PowerShell window

3. Run az bicep install to install the Bicep CLI
 a. az bicep install

4. Run az login to sign in to your Azure account
 a. az login --tenant <your dev tenant ID>

5. Run az account show to confirm you're using the correct subscription
 a. az account show

6. If needed, switch subscriptions using az account set --subscription ""
 a. az account set --subscription <your subscription ID>

7. Create a resource group if it doesn't exist:
 a. az group create --name Demo --location <your deployment location>

8. Place the main.bicep file in a folder and navigate to that folder in your terminal window
 a. E.g. cd c:/scripts/bicep 

9. Preview the deployment
 a. az deployment group what-if --resource-group Demo --template-file main.bicep

10. Deploy the Bicep file
 a. az deployment group create --resource-group Demo --template-file main.bicep
