#Function to get secrets
function Get-Secrets
(
  [string]$accessToken,
  [string]$vaultName,
  [string]$secretName
)
{
  $headers = @{ 'Authorization' = "Bearer $accessToken" }
  $queryUrl = "https://$vaultName.vault.azure.net/secrets/$secretName" + '?api-version=2016-10-01'
  $keyResponse = Invoke-RestMethod -Method GET -Uri $queryUrl -Headers $headers

  return $keyResponse.value
}

$apiVersion = "2017-09-01"
$resourceURI = "https://vault.azure.net"
$tokenAuthURI = $env:MSI_ENDPOINT + "?resource=$resourceURI&api-version=$apiVersion"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $tokenAuthURI
$accessToken = $tokenResponse.access_token

$vaultName="YOURVAULT"
$getUserName="NameOfSecretThatContainsTheAADUsername"
$GetPassword="NameOfSecretThatContainsTheAADUsernamePassword"

$username=Get-Secrets -accessToken $accessToken -vaultName $vaultName -secretName $getUserName
$password=Get-Secrets -accessToken $accessToken -vaultName $vaultName -secretName $getPassWord

$cred = New-Object System.Management.Automation.PSCredential $userName,(ConvertTo-SecureString $Password -AsPlainText -Force)

Login-AzureRMAccount -Credential $cred

#Select-AzureRmSubscription -Tenant #GuidOfYourTenant. Not needed if only one tenant exists 

$group = (get-AzureRMResourceGroup -Name "Cloud217").resourceGroupName

Write-Output "Result: $group"

Write-Output "PowerShell Timer trigger function executed at:$(get-date)";