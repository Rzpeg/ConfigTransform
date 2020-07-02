param (
    [Parameter(
        Mandatory=$true,
        Position=0)]
    $sourceFile,

    [Parameter(
        Mandatory=$true,
        Position=1)]
    $transformFile
)

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