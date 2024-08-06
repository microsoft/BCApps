# How to create a local development environment

## Prerequisites
- Install and run [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/). Make sure it is running Windows containers.
- Install [BcContainerHelper PS module](https://www.powershellgallery.com/packages/BcContainerHelper) (latest available version).
`Install-Module BCContainerHelper -AllowPrerelease` would do.

[Here](https://github.com/microsoft/navcontainerhelper) you can read more about *BcContainerHelper*.

## Create a development environment

The development environment is a docker container running Business Central locally.
In order to create it, simply run `.\build\scripts\DevEnv\NewDevEnv.ps1` with the desired parameters.


### Example - Set up a container and VSCode
```
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev'
```

Running the above will
* Create a new container (if one doesn't already exist)
* Set up launch.jsons and settings.jsons in your VSCode 


### Example - Set up a container, VSCode and publish a new system app
```
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev' -ProjectPaths '.\src\System Application\App'
```
Running the above will
* Create a new container (if one doesn't already exist)
* Set up launch.jsons and settings.jsons in your VSCode 
* Compile and publish a new system app using your local codebase

### Example - Set up a container, VSCode and publish a new system app and tests
```
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev' -ProjectPaths '.\src\System Application\*'
```
Running the above will
* Create a new container (if one doesn't already exist)
* Set up launch.jsons and settings.jsons in your VSCode 
* Compile and publish all AL apps that match `.\src\System Application\`