FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2019 as iis
COPY ["ConfigTranformation.psm1", "C:/Program Files/WindowsPowerShell/Modules/ConfigTranformation/ConfigTranformation.psm1"]
ENTRYPOINT ["powershell", "Start-Web"]
ENV DOTNET_ENVIRONMENT Debug

FROM iis
COPY ./PublishOutput/ /inetpub/wwwroot
WORKDIR /inetpub/wwwroot
