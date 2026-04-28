# EWU-CSCD396-2023-Fall

## Assignment 2

The purpose of this assignment is to solidify your learning of:

- Build and deploying containers
- Terraform IaC

## Prerequisites

- All CLI tools used in doc/containers.md such as dotnet, docker, etc.

## Instructions

- All cloud infrastructure should be built with Terraform. Terraform State should be maintained in a Storage Account
- All services should be deployed through a GitHub Action workflow

Complete the following Tutorials and do not clean up resources until assignment is graded.

1. Create and deploy a containerized Web App

   {https://learn.microsoft.com/en-us/azure/app-service/quickstart-dotnetcore?tabs=net70&pivots=development-environment-cli}
   Note: Deploy application code using az cli, not the VSCode extension

- Container App Created ❌✅
  (You can use the below steps to publish your app)

  - Create a new app using dotnet new command 
  - See docs/containers.md for how to create and deploy an image of your new app code to azure container registry

- Create a terraform main.tf and variables.tf files within a terraform folder. These files should contain relevant HCL for deploying a container app. ❌✅
- Use a variable for the container image name so that your workflow must pass this value into the terraform apply ❌✅
- Create a workflow that deploys your container app with Terraform using the init, plan, and apply commands adn passes your container image name into the apply ❌✅

- Url Accessible (and working) ❌✅
- Successful Workflow Run to Deploy Infrastructure ❌✅


4. Please add jcurry9@ewu.edu as a contributor to your subscription, otherwise grading will not be possible.


## Extra Credit


