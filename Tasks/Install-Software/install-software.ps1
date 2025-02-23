param (
    [string]$StorageAccountName,
    [string]$ContainerName,
    [string]$DownloadPath = "C:\Temp"
)

# Authenticate using Managed Identity
Connect-AzAccount -Identity

# Ensure Temp Directory Exists
if (!(Test-Path -Path $DownloadPath)) {
    New-Item -ItemType Directory -Path $DownloadPath -Force
}

# Define Software List
$softwareList = @(
    @{ Name = "Notepad++"; BlobName = "npp.8.7.7.Installer.x64.exe"; InstallArgs = "/S" },
    @{ Name = "SSMS"; BlobName = "SSMS-Setup-ENU.exe"; InstallArgs = "/S" },
    @{ Name = "Visual Studio Code"; BlobName = "VSCodeUserSetup-x64-1.97.2.exe"; InstallArgs = "/VERYSILENT /NORESTART /MERGETASKS=!runcode" }
)

# Get Storage Context using Provided Storage Account & Container Name
$storageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount

# Loop Through Software List
foreach ($software in $softwareList) {
    $blobName = $software.BlobName
    $installerPath = "$DownloadPath\$blobName"
    $installArgs = $software.InstallArgs

    Write-Host "⬇ Downloading $($software.Name)..."

    # Download the Installer
    try {
        Get-AzStorageBlobContent -Container $ContainerName -Blob $blobName -Destination $installerPath -Context $storageContext -ErrorAction Stop
    } catch {
        Write-Host " Failed to download $($software.Name). Skipping..."
        continue
    }

    # Verify Download & Install
    if (Test-Path -Path $installerPath) {
        Write-Host " Installing $($software.Name)..."
        try {
            Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -NoNewWindow -ErrorAction Stop
            Write-Host " Installed: $($software.Name)"

            # Delete installer
            Remove-Item -Path $installerPath -Force -ErrorAction Stop
            Write-Host " Deleted installer for $($software.Name)"
        } catch {
            Write-Host " Installation failed for $($software.Name)"
        }
    }
}

Write-Host " Software installation completed!"
