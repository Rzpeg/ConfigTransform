# Description
Configuration Transformation helpers for containerization of .NET Framework applications.

Based on:

https://anthonychu.ca/post/overriding-web-config-settings-environment-variables-containerized-aspnet-apps/

https://stackoverflow.com/questions/8989737/web-config-transforms-outside-of-microsoft-msbuild

https://gist.github.com/sayedihashimi/f1fdc4bfba74d398ec5b


# Content
This repository contains 2 scripts to apply transformations to .config files, both using XDT and Environment Variables, a PowerShell module and an example Dockerfile.

## XDT-based transformation. 

transform-xml.ps1

Usage: .\transform-xml.ps1 "Web.config" "Web.Release.config"

## Environment Variables-based transformation. (Connection Strings and AppSettings only)

override-xml-from-env.ps1

Usage: 

Create the needed environment variables with correct prefix (APPSETTING_ or CONNSTR_) then run

.\override-xml-from-env.ps1 "Web.config"


## PowerShell Module.

Contains both functions from above, and a bootstrapper for web applications.


## Dockerfile

Example dockerfile
