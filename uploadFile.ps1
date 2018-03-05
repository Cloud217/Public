Param(
    [parameter(Mandatory = $true)]
    [string]$files,
    [parameter(Mandatory = $true)]
    [string]$storageAccount,
    [parameter(Mandatory = $true)]
    [string]$resourceGroup
    [parameter(Mandatory = $true)]
    [string]$container
) 

$storageaccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount
$azureStorageAccountContext = $storageAccount.Context

$localFiles = get-childitem $files -Filter "*.json"

$localvmFiles = @()
foreach ($localFile in $localFiles) {
    #Set default import value to false
    $import = $false
    $localFilesName = $localFile.BaseName
    $localvmFiles += $localFilesName

    #get the filehash and change it to Base 64 string
    $crypto = [System.Security.Cryptography.MD5]::Create()
    $content = Get-Content -Path $localfile -Encoding byte
    $localHash = [System.Convert]::ToBase64String($crypto.ComputeHash($content))

    #get files on Azure Storage Account
    $blobFiles = Get-AzureStorageBlob -Blob $localfile -Container appcontainer -Context  $azureStorageAccountContext -ErrorAction 0   
    #put hash of Azure file into a variable
    $cloudHash = $blobFiles.ICloudBlob.Properties.ContentMD5

    if ($blobFiles -eq $null) {
        $import = $true
    }
    else {
        if ($LocalHash -ne $cloudHash) {
            Write-host ("The Hash of the local version of the file: $($localFile) differs from the Azure one. Re-importing...") -ForegroundColor Green
            Write-host "Remove the existing file"  -ForegroundColor Green
            Write-host $blobFiles.Name -ForegroundColor White
            Remove-AzureStorageBlob `
                -Blob $localFile `
                -Container $container `
                -Context  $azureStorageAccountContext
            #since we discovered that the local version differs we want to re-import. So we set $import to true
            $import = $true
        }
    }

    if ($import) {
        Write-host "Importing  $($localFile.FullName)" -ForegroundColor Green
        Set-AzureStorageBlobContent `
            -File $localFile `
            -Container appcontainer `
            -Blob $localFile `
            -Context  $azureStorageAccountContext `
            -Force
    }
}

# Check files on Azure Storage Account
$blobFiles = Get-AzureStorageBlob -Container $container -Context  $azureStorageAccountContext
foreach($blobFile in $blobFiles)
{
    if($localFiles.name -notcontains $blobFile.Name)
    {
        write-host "File $($blobFile.Name) Exists only on Azure Storage Account, removing" -ForegroundColor Yellow
        Remove-AzureStorageBlob `
                -Blob $blobFile.Name `
                -Container $container `
                -Context  $azureStorageAccountContext
    }
}
