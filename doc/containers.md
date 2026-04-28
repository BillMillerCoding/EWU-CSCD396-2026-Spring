
## Containerize with DotNet
[Containerize with DotNet](https://learn.microsoft.com/en-us/dotnet/core/containers/overview?tabs=windows)
1. use built in container tools in .NET 8+
1. set project properties to enable containerization
    ``` 
    <PropertyGroup>
    <IsPublishable>true</IsPublishable>
    <EnableSdkContainerSupport>true</EnableSdkContainerSupport>
    </PropertyGroup>
    ```
1. Be sure Docker is running
1. Run `dotnet publish -c Release` to build and publish the application, which will also create a Docker image.
1. Run `docker images` to see the created image.
1. Properties can be set in the project file or via command line arguments to `dotnet publish` to specify the base image, target OS, and other containerization options.
    ```
    dotnet publish --os linux --arch x64 /t:PublishContainer /p:ContainerImageTags=`"0.0.1`;latest`"
    ```

## Publish to Azure Container Registry
[Publish to Azure Container Registry](https://learn.microsoft.com/en-us/dotnet/core/containers/azure-container-registry?tabs=windows)
1. Create an Azure Container Registry (ACR) 
1. Install the Azure CLI and log in to your Azure account using `az login`
1. Use the Azure CLI to log in to your ACR using `az acr login --name <registry-name>`
1. Tag your Docker image with the ACR login server name using `docker tag <image-name> <registry-name>.azurecr.io/<image-name>:<tag>`
1. Push the Docker image to ACR using `docker push <registry-name>.azurecr


## Containerize with Docker
[Containerize with Docker](https://learn.microsoft.com/en-us/dotnet/core/docker/build-container?tabs=windows&pivots=dotnet-10-0)

https://learn.microsoft.com/en-us/dotnet/architecture/microservices/