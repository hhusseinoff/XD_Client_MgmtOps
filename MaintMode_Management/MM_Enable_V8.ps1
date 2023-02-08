## Jose Garcia / SERVER-RSRVPXT edit | Dec 25th, 2022                                                                   ##
## Error Codes:                                                                                                         ##
##  0  :            Successful Execution                                                                                ##
##  1  :            Invalid passed parameters                                                                           ##
##  2  :            Passed ComputerName parameter and actual ComputerName of the executing machine do NOT match         ##
##  3  :            .NET Framework Install utility setup fail                                                           ##
##  4  :            Citrix broker Snapin register fail                                                                  ##
##  5  :            citrix Broker Snapin load fail                                                                      ##
##  6  :            Failed to obtain machine data using the Get-BrokerMachine cmdlet                                    ##
##  7  :            Failed to set MM off using the Set-BrokerPrivateDesktop cmdlet                                      ##
##  8  :            Unregister Snapin failed, after unloading the snapin failed first                                   ##
##  9  :            Unregister Snapin failed                                                                            ##
##
## Edit Oct 18th, removed error[0] redirects, replaced them with Checker variables for the if conditions
## Edit Dec 25th, Added APAC Dedicated XND Controllers and EU E2E XND Controllers (AZ-Ireland, Europe)


param(
[string]$XenDesktopController,
[string]$ComputerName
)

function debug($message)
{
    write-host "$(Get-Date -Format yyyy-MM-dd--HH-mm-ss) $message"
    add-content -path "C:\Windows\AVC\Logging\XD_MM_on_$env:COMPUTERNAME.log" -Value "$(Get-Date -Format yyyy-MM-dd--HH-mm-ss) $message" 
}

$ValidXDControllersList = @(
    'XD_DDC_Name1'
    'XD_DDC_Name2'
    'XD_DDC_Name3'
    'XD_DDC_Name4'
    'XD_DDC_Name5'
    'XD_DDC_Name6'
    )


debug "----------------------------Script initiated-----------------------------"

debug "Controller parameter used: $XenDesktopController"
debug "Computer name parameter used: $ComputerName"

if (($ValidXDControllersList.Contains($XenDesktopController)) -and ($ComputerName -like "X*-D*"))
{
    debug "Checking if the passed computer name matches the name of the machine that executes the script..."

    $NameCheck = $false
    
    $NameCheck = ($ComputerName -eq $env:COMPUTERNAME)

    if($false -eq $NameCheck)
    {
        debug "Passed ComputerName parameter and the machine executing the script, DO NOT Have matching names."

        debug "Exiting with error code 2..."

        exit 2
    }
    else
    {
        debug "Setting up the .NET Framework Install Utility..."

        $InstallUtil = Join-Path $([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) "InstallUtil.exe"

        $PathCheck = $false
        
        $PathCheck = Test-Path -Path $InstallUtil

        if($false -eq $PathCheck)
        {
            debug ".NET Framework Install Utility failed to set up. Verify that .NET Framework is installed and functional."

            debug "Exiting with error code 3..."

            exit 3
        }
        else
        {
            debug ".NET Framework Install Utility setup successful."

            debug "Proceeding to Register the Citrix Broker Snapin..."

            & $InstallUtil ".\SnapIn_V2\BrokerSnapin.dll"

            $SnapinRegisterCheck = $null

            $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

            if($null -eq $SnapinRegisterCheck)
            {
                debug "Citrix Broker Snapin Register FAILED."

                debug "Exiting with error code 4..."

                exit 4

            }
            else
            {
                debug "Citrix Broker Snapin Register Successful."

                debug "Proceeding to load the Snapin..."

                Add-PSSnapin Citrix.Broker.Admin.V2

                $SnapinLoadCheck = $null

                $SnapinLoadCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -ErrorAction SilentlyContinue

                if($null -eq $SnapinLoadCheck)
                {
                    debug "Citrix Broker Snapin Load FAILED. Proceeding to Unregister the Snapin..."

                    & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"

                    $SnapinRegisterCheck = $null
                    
                    $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                    if($null -ne $SnapinRegisterCheck)
                    {
                        debug "Citrix Broker Snapin Unregister FAILED."

                        debug "Exiting with error code 9..."

                        exit 9
                    }
                    else
                    {
                        debug "Citrix Broker Snapin Unregister successful, after a failed attempt to load the snapin."

                        debug "Exiting with error code 5..."

                        exit 5
                    }
                }
                else
                {
                    debug "Citrix Broker Snapin Load successful."

                    debug "Proceeding to get machine data..."

                    $MachineData = Get-BrokerMachine -HostedMachineName $ComputerName -AdminAddress $XenDesktopController -ErrorAction SilentlyContinue

                    if($null -eq $MachineData)
                    {
                        debug "Obtaining machine data FAILED. Proceeding to Unload the Snapin..."

                        Remove-PSSnapin Citrix.Broker.Admin.V2

                        $SnapinLoadCheck = $null
                        
                        $SnapinLoadCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -ErrorAction SilentlyContinue

                        if($null -ne $SnapinLoadCheck)
                        {
                            debug "Unloading the Snapin FAILED. Attempting to Unregister the Snapin..."

                            & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"

                            $SnapinRegisterCheck = $null
                            
                            $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                            if($null -ne $SnapinRegisterCheck)
                            {
                                debug "Unregistering the Snapin after a Failed Load attempt, FAILED."

                                debug "Exiting with error code 8..."

                                exit 8

                            }
                            else
                            {
                                debug "Unregistering the Snapin after a Failed Load attempt successful."

                                debug "Exiting with error code 6..."

                                exit 6
                            }
                        }
                        else
                        {
                            debug "Unloading the Snapin Successful. Proceeding to Unregister the Snapin..."

                            & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"

                            $SnapinRegisterCheck = $null
                            
                            $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                            if($null -ne $SnapinRegisterCheck)
                            {
                                debug "Unregistering the Snapin after a successful unload, FAILED."

                                debug "Exiting with error code 9..."

                                exit 9
                            }
                            else
                            {
                                debug "Unregistering the Snapin after a successful unload, successful."

                                debug "Exiting with error code 6..."

                                exit 6
                            }
                        }
                    }
                    else
                    {
                        debug "Machine Data retrieved. Proceeding to set MM on..."

                        Set-BrokerPrivateDesktop -MachineName $MachineData.MachineName -InMaintenanceMode:$true -AdminAddress $XenDesktopController -ErrorAction SilentlyContinue

                        $OperationCheck = $false
                        
                        $OperationCheck = Get-BrokerMachine -HostedMachineName $ComputerName -AdminAddress $XenDesktopController | Select InMaintenanceMode -ErrorAction SilentlyContinue

                        if($false -eq $OperationCheck.InMaintenanceMode)
                        {
                            debug "Failed to set MM on. Proceeding to unload the Snapin..."

                            Remove-PSSnapin Citrix.Broker.Admin.V2

                            $SnapinLoadCheck = $null
                            
                            $SnapinLoadCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -ErrorAction SilentlyContinue

                            if($null -ne $SnapinLoadCheck)
                            {
                                debug "Failed to Unload the Snapin. Attempting to Unregister the snapin..."

                                & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"

                                $SnapinRegisterCheck = $null
                                
                                $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                                if($null -ne $SnapinRegisterCheck)
                                {
                                    debug "Failed to Unregister the snapin, after unloading the snapin failed first."

                                    debug "Exiting with error code 8..."

                                    exit 8
                                }
                                else
                                {
                                    debug "Unregistering the snapin after a failed load attemp successful."

                                    debug "Exiting with error code 7..."

                                    exit 7
                                }

                            }
                            else
                            {
                                debug "Unloading the Snapin successful. Proceeding to unregister the Snapin..."

                                & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"

                                $SnapinRegisterCheck = $null
                                
                                $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                                if($null -ne $SnapinRegisterCheck)
                                {
                                    debug "Failed to Unregister the Snapin."

                                    debug "Exiting with error code 9..."

                                    exit 9
                                }
                                else
                                {
                                    debug "Unregistering the Snapin successful."

                                    debug "Exiting with error code 7..."

                                    exit 7
                                }
                            }
                        }
                        else
                        {
                            debug "MM successfuly set on. Proceeding to unload the snapin..."

                            Remove-PSSnapin Citrix.Broker.Admin.V2

                            $SnapinLoadCheck = $null
                            
                            $SnapinLoadCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -ErrorAction SilentlyContinue

                            if($null -ne $SnapinLoadCheck)
                            {
                                debug "Unloading the snapin FAILED. Attempting to Unregister the Snapin..."

                                & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"

                                $SnapinRegisterCheck = $null
                                
                                $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                                if($null -ne $SnapinRegisterCheck)
                                {
                                    debug "Unregistering the Snapin after a failed unload attempt, FAILED."

                                    debug "Exiting with error code 8..."

                                    exit 8
                                }
                                else
                                {
                                    debug "Unregistering the Snapin after a failed unload attempt, successful."

                                    debug "Script job completed."

                                    debug "Exiting with error code 0 (success)..."

                                    exit 0
                                }
                            }
                            else
                            {
                                debug "Unloading the Snapin successful. Proceeding to Unregister the Snapin..."

                                & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"

                                $SnapinRegisterCheck = $null
                                
                                $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                                if($null -ne $SnapinRegisterCheck)
                                {
                                    debug "Unregistering the Snapin FAILED."

                                    debug "Exiting with error code 9..."

                                    exit 9
                                }
                                else
                                {
                                    debug "Unregistering the Snapin successful."

                                    debug "Script job completed."

                                    debug "Exiting with error code 0 (success)..."

                                    exit 0
                                }
                            }
                        }
                    }
                }
            }
        }

    }
} 

else
{
    debug "Invalid Parameters passed. Exiting with error code 1..."

    exit 1
}