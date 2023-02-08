## Jose Garcia / SERVER-RSRVPXT edit | Dec 31st, 2022                                                                           ##
##
## Purpose: Queries HKLM:\SOFTWARE\AVC for the value of ServicingXDController and returns it
##
## To be Used in conjunction with the XD_Identifier script
##
## To be run under an account that has the necessary write permisions to the ReportingLocation

param([string]$ReportingLocation)

$RegPath = "HKLM:\SOFTWARE\CompanyName"

$RegCheck = Get-ItemPropertyValue -Path $RegPath -Name "ServicingXDController" -ErrorAction SilentlyContinue

$Output = "Blank"

if($null -ne $RegCheck)
{
    $Output = $RegCheck
}
else
{
    $ReportingFileExists = Test-Path -Path "$ReportingLocation\GatherXDController_RegNotFound.txt" -PathType Leaf

    if($false -eq $ReportingFileExists)
    {
        Add-Content -Path "$ReportingLocation\GatherXDController_RegNotFound.txt" -Value "--Timestamp(UTC)--`tMachine Name" -Force -Confirm:$false
    }
    
    Add-Content -Path "$ReportingLocation\GatherXDController_RegNotFound.txt" -Value "$($(Get-Date).ToUniversalTime())`t$env:COMPUTERNAME" -Force -Confirm:$false

    $Output = "Error"
}

return $Output
