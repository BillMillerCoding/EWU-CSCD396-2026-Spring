# EWU-CSCD396-2023-Fall

## Assignment 3 - DRAFT!!!

The purpose of this assignment is to solidify your learning of:

- Build and deploying containers
- Terraform IaC
- Fnctions and Logic Apps
- Messaging and Eventing

## Prerequisites

- Install VSCode Extension 'Azure App Service'

## Instructions

- All cloud infrastructure should be built with Terraform. Terraform State should be maintained in a Storage Account
- All services should be deployed through a GitHub Action workflow

Complete the following Tutorials and do not clean up resources until assignment is graded.

1. Create and deploy an Azure Function Bound to Service Bus. The function should write messages received to a storage account

   {https://learn.microsoft.com/en-us/azure/app-service/scenario-secure-app-access-storage?tabs=azure-cli}

- Enabled Managed Identity on the function app ❌✅
- Create Storage Account ❌✅
- Function App Identity Granted Access to Storage Account ❌✅

2. Add a feature to the container app to write a message to the Service Bus from step 2. Ideally this ia a text box for the message and a button to submit the message to the bus. You can use the Azure SDK for .NET to send messages to the bus from your container app.

- Add an identity to the container app (by updating your terraform configuration) ❌✅
- Assign the container app identity adequate permissions on your service bus to send messages. ❌✅
- Can I enter a message on your site and see the message appear in your storage account ❌✅



4. Please add jcurry9@ewu.edu as a contributor to your subscription, otherwise grading will not be possible.


## Extra Credit

- Have the web app write the message to an Azure SQL Table in addition to the message bus
- 
