# How to create a local development environment

## Prerequisites
- Install and run [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/). Make sure it is running Windows containers.
- Install [BcContainerHelper PS module](https://www.powershellgallery.com/packages/BcContainerHelper) (latest available version).
`Install-Module BCContainerHelper -AllowPrerelease` would do.

[Here](https://github.com/microsoft/navcontainerhelper) you can read more about *BcContainerHelper*.

## Create a development environment

The development environment is a docker container running Business Central locally.
In order to create it, simply run `build\scripts\DevEnv\NewDevEnv.ps1` with the desired parameters.

For instance, running the following will
1. Build all AL apps that match `.\src\System Application\`.
1. Create a docker container called _BC-SystemApp_ with an admin user with the provided credentials.
1. Publish the built apps and their dependencies to _BC-SystemApp_.

```
.\build\scripts\DevEnv\NewDevEnv.ps1 -containerName 'BC-SystemApp' -userName admin -password 'MyP@ss' -projectPaths '.\src\System Application\*'
```