function Invoke-ConfigTranformation-Template($sourceFile, $transformFile) 
{
    $toolsDir = ("$env:LOCALAPPDATA\LigerShark\tools\");
    $nugetDestPath = Join-Path -Path $toolsDir -ChildPath nuget.exe;
    
    if (!(Test-Path -path $sourceFile -PathType Leaf)) {
        throw "File not found. $sourceFile";
    }
    
    if (!(Test-Path -path $transformFile -PathType Leaf)) {
        throw "File not found. $transformFile";
    }
    
    if(!(Test-Path $toolsDir)){ 
        Write-Host "Creating tools directory";
        New-Item -Path $toolsDir -ItemType Directory | Out-Null;
    }
    
    if(!(Test-Path $nugetDestPath)){
        Write-Host "Downloading nuget.exe";
        $webclient = New-Object System.Net.WebClient;
        $webclient.DownloadFile('https://dist.nuget.org/win-x86-commandline/v5.6.0/nuget.exe', $nugetDestPath);
    }
    
    Write-Host "Installing Microsoft.Web.Xdt";
    $cmdArgs = @('install','Microsoft.Web.Xdt','-Version','3.1.0','-OutputDirectory',(Resolve-Path $toolsDir).ToString(),'-Source','https://api.nuget.org/v3/index.json');
    &$nugetDestPath $cmdArgs | Out-Null
    
    $dllPath = Join-Path -Path $toolsDir -ChildPath 'Microsoft.Web.Xdt.3.1.0\lib\net40\Microsoft.Web.XmlTransform.dll';
    Add-Type -LiteralPath $dllPath;
    
    $xmldoc = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument;
    $xmldoc.PreserveWhitespace = $true
    $xmldoc.Load($sourceFile);
    
    $transf = New-Object Microsoft.Web.XmlTransform.XmlTransformation($transformFile);
    
    if ($transf.Apply($xmldoc) -eq $false)
    {
        throw "Transformation failed."
    }
    
    $xmldoc.Save($sourceFile);
    
    Write-Host "File transformed";
}

function Invoke-ConfigTranformation-Environment($sourceFile) 
{
    $doc = (Get-Content $sourceFile) -as [Xml];
    $modified = $FALSE;
    $appSettingPrefix = "APPSETTING_";
    $connectionStringPrefix = "CONNSTR_";
    
    Get-ChildItem env:* | ForEach-Object {
        if ($_.Key.StartsWith($appSettingPrefix)) {
            $key = $_.Key.Substring($appSettingPrefix.Length);
            $appSetting = $doc.configuration.appSettings.add | Where-Object {$_.key -eq $key};
            if ($appSetting) {
                $appSetting.value = $_.Value;
                Write-Host "Replaced appSetting" $_.Key $_.Value;
                $modified = $TRUE;
            }
        }
        if ($_.Key.StartsWith($connectionStringPrefix)) {
            $key = $_.Key.Substring($connectionStringPrefix.Length);
            $connStr = $doc.configuration.connectionStrings.add | Where-Object {$_.name -eq $key};
            if ($connStr) {
                $connStr.connectionString = $_.Value;
                Write-Host "Replaced connectionString" $_.Key $_.Value;
                $modified = $TRUE;
            }
        }
    }
    
    if ($modified) {
        Write-Host "Document modified, overwriting the file.";
        $doc.Save($webConfig);
    } else {
        Write-Host "No changes to the document.";
    }
}

function Start-Web {
    Write-Host "Preparing Web application...";
    $environment = $env:DOTNET_ENVIRONMENT;
    $source = "Web.config";
    $target = "bin\Web.$environment.config";
    
    Write-Host "Transforming $source -> $target";
    Invoke-ConfigTranformation-Template $source $target;
    
    Write-Host "Transforming using environment variables..."
    Invoke-ConfigTranformation-Environment('Web.config');

    Write-Host "Starting...";
    C:\ServiceMonitor.exe w3svc
}