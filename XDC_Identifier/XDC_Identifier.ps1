## Jose Garcia / SERVER-RSRVPXT edit | Dec 31st, 2022                                                                           ##
## Error Codes:                                                                                                                 ##
##  1  :            .NET Framework Install utility setup fail                                                                   ##
##  2  :            Citrix broker Snapin register fail                                                                          ##
##  3  :            citrix Broker Snapin load fail                                                                              ##
##  4  :            Unloading the Broker Snapin failed                                                                          ##
##  5  :            Unregistering the Broker Snapin Snapin failed                                                               ##
##
## Purpose: Uses Get-BrokerMachine to query a list of controllers, given as an input, then creates a registry value at
## HKLM:\SOFTWARE\AVC, named ServicingXDController (REG_SZ) for use in other scripts and/or in Task sequences (mainly MaintMode ON/Off and ImgVer Tagging in XD)
##
## Solves the problem of having to guess a machine's XND controller by the machine's name
##
## If the Registry fails to be created or no controllers servicing the machine are found, an appropriate TXT report file will be
## generated at the Reporting Location, given as the $ReportingLocation parameter for the script
##
## Local logs are also created on the machine at C:\Windows\AVC\Logging with the name XD_Identifier_<MachineName>.log
##
## Failure file names: FailedToCreateXDControllerRegValue.txt, NoXDControllersFound.txt | They contain a timestamp and the machine name
##
## The script must be run under a TU account (or an engineer's), otherwise Citrix Cmdlets won't be able to authorize and execute
##
## Intended to be used ONLY for UPGRADE Task Sequences - will fail in BFS sequences since running scripts under a specific account
## when not in Full OS mode is buggy

param(
[string]$ComputerName,
[String[]]$ControllersList,
[string]$ReportingLocation
)

function debug($message)
{
    write-host "$(Get-Date -Format yyyy-MM-dd--HH-mm-ss) $message"
    add-content -path "C:\Windows\AVC\Logging\XD_Identifier_$env:COMPUTERNAME.log" -Value "$(Get-Date -Format yyyy-MM-dd--HH-mm-ss) $message" 
}

##Main Body

debug "----------------------------Script initiated-----------------------------"

debug "Passed Computer Name: $ComputerName"
debug "Passed XND Controllers List: $ControllersList"
debug "Passed Reporting Location: $ReportingLocation"

$OutputMarker = "blank"

$RegPath = "HKLM:\SOFTWARE\AVC"

debug "Proceeding to set up the .NET Framework Install Utility..."

$InstallUtil = Join-Path $([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) "InstallUtil.exe"

$InstallUtilCheck = Test-Path -Path $InstallUtil

if($false -eq $InstallUtilCheck)
{
    debug "Failed to set up the .NET Framework Install Utility. Exiting with error code 1..."

    exit 1
}

debug ".NET Install Utility setup successful."

debug "Proceeding to register the Citrix Broker Snapin..."

$null = & $InstallUtil "$PSScriptRoot\SnapIn_V2\BrokerSnapin.dll"

$RegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

if($null -eq $RegisterCheck)
{
    debug "Failed to register the Citrix Broker Snapin. Exiting with error code 2..."

    exit 2
}

debug "Citrix Broker Snapin Registration Successful."

debug "Proceeding to load the Citrix Broker Snapin..."

Add-PSSnapin Citrix.Broker.Admin.V2

$LoadCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -ErrorAction SilentlyContinue

if($null -eq $LoadCheck)
{
    debug "Failed to load the Citrix Broker Snapin. Exiting with error code 3..."

    exit 3
}

debug "Starting checks for $ComputerName at each of the passed Controller Names..."

foreach($XD_Controller in $ControllersList)
{
    debug "Checking $XD_Controller"
    
    $XD_Check = Get-BrokerMachine -HostedMachineName $ComputerName -AdminAddress $XD_Controller -ErrorAction Ignore
    
    if($null -ne $XD_Check)
    {
        $OutputMarker = $XD_Controller

        debug "Servicing XND Controller for $ComputerName found: $XD_Controller"

        debug "Proceeding to create / overwrite ServicingXDController registry value at $RegPath ..."

        New-ItemProperty -Path $RegPath -Name "ServicingXDController" -PropertyType String -Value $XD_Controller -Force -Confirm:$false | Out-Null

        debug "Verifying that the registry value was created..."

        $RegCheck = Get-ItemPropertyValue -Path $RegPath -Name "ServicingXDController" -ErrorAction SilentlyContinue

        if($null -eq $RegCheck)
        {
            debug "Registry Value Creation / Overwrite FAILED."

            debug "Adding Entry for the machine at the Reporting Location of: $ReportingLocation\FailedToCreateXDControllerRegValue.txt..."

            $ReportFileExists = Test-Path -Path "$ReportingLocation\FailedToCreateXDControllerRegValue.txt"

            if($false -eq $ReportFileExists)
            {
                Add-Content -Path "$ReportingLocation\FailedToCreateXDControllerRegValue.txt" -Value "--Timestamp(UTC)--`tMachine Name" -Force -Confirm:$false
            }
            
            Add-Content -Path "$ReportingLocation\FailedToCreateXDControllerRegValue.txt" -Value "$($(Get-Date).ToUniversalTime())`t$ComputerName" -Force -Confirm:$false

            debug "Entry Added."
        }
        else
        {
            debug "Registry Value Creation / Overwrite Succeeded."
        }

        break
    }
    
    $XD_Check = $null   
}

if("blank" -eq $OutputMarker)
{
    debug "None of the Passed Controller names found servicing $ComputerName. No registry will be created."

    debug "Adding Entry for the machine at the Reporting Location of: $ReportingLocation\NoXDControllersFound.txt..."

    $ReportFileExists = Test-Path -Path "$ReportingLocation\NoXDControllersFound.txt"

    if($false -eq $ReportFileExists)
    {
         Add-Content -Path "$ReportingLocation\NoXDControllersFound.txt" -Value "--Timestamp(UTC)--`tMachine Name" -Force -Confirm:$false
    }

    Add-Content -Path "$ReportingLocation\NoXDControllersFound.txt" -Value "$($(Get-Date).ToUniversalTime())`t$ComputerName" -Force -Confirm:$false

    debug "Entry Added."
}

debug "Main script body finished executing."

debug "Proceeding to unload the Citrix Broker Snapin..."

Remove-PSSnapin Citrix.Broker.Admin.V2

$UnloadCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -ErrorAction SilentlyContinue

if($null -ne $UnloadCheck)
{
    debug "Failed to unload the Citrix Broker Snapin. Exiting with error code 4..."

    exit 4
}

debug "Unloading the Broker Snapin was successful."

debug "Proceeding to unregister the Citrix Broker Snapin..."

$null = & $InstallUtil -u "$PSScriptRoot\SnapIn_V2\BrokerSnapin.dll"

$UnregisterCheck = $null

$UnregisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

if($null -ne $UnregisterCheck)
{
    debug "Failed to unregister the Citrix Broker Snapin. Exiting with error code 5..."

    exit 5
}

debug "Script execution finished. Exiting..."

exit 0
