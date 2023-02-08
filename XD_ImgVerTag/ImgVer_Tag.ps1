## Jose Garcia / SERVER-RSRVPXT edit | Dec 25th, 2022                                                                   ##
## Error Codes:                                                                                                         ##
##  0  :            Successful Execution                                                                                ##
##  1  :            Invalid passed parameters                                                                           ##
##  2  :            Passed ComputerName parameter and actual ComputerName of the executing machine do NOT match         ##
##  3  :            .NET Framework Install utility setup fail                                                           ##
##  4  :            Citrix broker Snapin register fail                                                                  ##
##  5  :            citrix Broker Snapin load fail                                                                      ##
##  6  :            Failed to obtain machine data using the Get-BrokerMachine cmdlet                                    ##
##  7  :            Failed to associate the machine with a XD tag using Add-BrokerTag                                   ##
##  8  :            Failed to create a new XD Tag from scratch using New-BrokerTag                                      ##
##  9  :            Unregister Snapin failed                                                                            ##
##  9  :            Unregister Snapin failed                                                                            ##
## 10  :            Failed to remove the current ImgVer Tag using Remove-BrokerTag                                      ##
## Edit Oct 18th, removed error[0] redirects, replaced them with Checker variables for the if conditions
## Edit Dec 25th, Added APAC Dedicated XND Controllers and EU E2E XND Controllers (AZ-Ireland, Europe)

Param(
    [string]$XenDesktopController,
	[string]$ImageVersion,
	[string]$ComputerName
	)
	

function debug($message)
{
    write-host "$(Get-Date -Format yyyy-MM-dd--HH-mm-ss) $message"
    add-content -path "C:\Windows\AVC\Logging\XD_TAG_$env:COMPUTERNAME.log" -Value "$(Get-Date -Format yyyy-MM-dd--HH-mm-ss) $message" 
}

$ValidXDControllersList = @(
    'XD_DDC_Name1'
    'XD_DDC_Name2'
    'XD_DDC_Name3'
    'XD_DDC_Name4'
    'XD_DDC_Name5'
    'XD_DDC_Name6'
    )

debug "Controller parameter used: $XenDesktopController"
debug "Image version string used: $ImageVersion"
debug "Computer name used: $ComputerName"

	
if (($ValidXDControllersList.Contains($XenDesktopController)) -and ($ComputerName -like "X*-D*") -and ($ImageVersion -like "*R*_*_*R*"))
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

        debug "Citrix Broker Snapin successfully unregistered."

        debug "Exiting with error code 5..."

        exit 5
    }

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
                debug "Unregistering the Snapin after a Failed unload attempt, FAILED."

                debug "Exiting with error code 9..."

                exit 9
             }
             else
             {
                debug "Unregistering the Snapin after a Failed unload attempt successful."

                debug "Exiting with error code 6..."

                exit 6
             }
        }

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


    ## Operations with Citrix Broker Cmdlets  ##

    debug "Machine Data retrieved. Proceeding to check current ImgVer tags..."

    $CurrentTag = Get-BrokerTag -MachineUid $MachineData.uid -AdminAddress $XenDesktopController | select Name -ErrorAction SilentlyContinue

    if($null -ne $CurrentTag.Name)
    {
        debug "Converting data obtained for the current ImgVer Tags to a comma-separated string..."

        $CurrentTagString = [System.String]::Join(",",$CurrentTag.Name)
    }
    else
    {
        $CurrentTagString = "Blank"
    }

    if( ($false -eq ($CurrentTagString.Contains("ImgVer"))) -or ($null -eq $CurrentTag) )
    {
        debug "Machine has no current ImgVer tags. Checking if the passed ImgVer parameter has ever been created as a XD Tag object..."

        $TagExists = Get-BrokerTag -Name "ImgVer $ImageVersion" -AdminAddress $XenDesktopController -ErrorAction SilentlyContinue

        if($null -ne $TagExists)
        {
            debug "The given ImgVer already exists in XD. Proceeding to associate the machine with it..."

            Add-BrokerTag -Name "ImgVer $ImageVersion" -Machine $MachineData -AdminAddress $XenDesktopController -ErrorAction SilentlyContinue

            debug "Proceeding to verify if the association was successful..."

            $OperationCheck = $null

            $OperationCheck = Get-BrokerTag -MachineUid $MachineData.uid -AdminAddress $XenDesktopController | select Name -ErrorAction SilentlyContinue

            if($true -eq (($OperationCheck.Name).Contains("ImgVer $ImageVersion")))
            {
                debug "Script job complete."

                debug "Proceeding to Unload the Snapin..."

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
                        debug "Unregistering the Snapin after a Failed unload attempt, FAILED."

                        debug "Exiting with error code 9..."

                        exit 9
                    }
                    else
                    {
                        debug "Unregistering the Snapin after a Failed unload attempt successful."

                        debug "Exiting with error code 0..."

                        exit 0
                    }

                }

                debug "Unloading the Snapin was successful, proceeding to unregister..."

                & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"

                $SnapinRegisterCheck = $null

                $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                if($null -ne $SnapinRegisterCheck)
                {
                    debug "Unregistering the Snapin after a successful unload, FAILED."

                    debug "Exiting with error code 9..."

                    exit 9
                }

                debug "Exiting with error code 0 (success)..."

                exit 0
            }
            else
            {
                debug "Error while trying to associate the existing ImgVer Tag with the machine."

                debug "Proceeding to Unload the Snapin..."

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
                        debug "Unregistering the Snapin after a Failed unload attempt, FAILED."

                        debug "Exiting with error code 9..."

                        exit 9
                    }
                    else
                    {
                        debug "Unregistering the Snapin after a Failed unload attempt successful."

                        debug "Exiting with error code 7..."

                        exit 7
                    }

                }

                debug "Unloading the Snapin was successful, proceeding to unregister..."

                & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"

                $SnapinRegisterCheck = $null

                $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                if($null -ne $SnapinRegisterCheck)
                {
                    debug "Unregistering the Snapin after a successful unload, FAILED."

                    debug "Exiting with error code 9..."

                    exit 9
                }

                debug "Exiting with error code 7..."

                exit 7
            }
        }
        else
        {
            debug "The given ImgVer has never been created as XD Tag before. Proceeding to create..."

            New-BrokerTag -Name "ImgVer $ImageVersion" -AdminAddress $XenDesktopController -ErrorAction SilentlyContinue

            debug "Verifying if the creation was successful..."

            $OperationCheck = $null

            $OperationCheck = Get-BrokerTag -Name "ImgVer $ImageVersion" -AdminAddress $XenDesktopController | select Name -ErrorAction SilentlyContinue

            if($true -eq (($OperationCheck.Name).Contains("ImgVer $ImageVersion")))
            {
                debug "XD ImgVer tag successfully created. Value:"
                
                debug "Proceeding to associate the machine with it..."
                
                Add-BrokerTag -Name "ImgVer $ImageVersion" -Machine $MachineData -AdminAddress $XenDesktopController -ErrorAction SilentlyContinue

                debug "Verifying if association was successful..."

                $OperationCheck = $null

                $OperationCheck = Get-BrokerTag -MachineUid $MachineData.uid -AdminAddress $XenDesktopController | select Name -ErrorAction SilentlyContinue

                if($true -eq (($OperationCheck.Name).Contains("ImgVer $ImageVersion")))
                {
                    debug "Script job complete."

                    debug "Proceeding to unload the snapin..."

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
                            debug "Unregistering the Snapin after a Failed unload attempt, FAILED."

                            debug "Exiting with error code 9..."

                            exit 9
                        }
                        else
                        {
                            debug "Unregistering the Snapin after a Failed unload attempt successful."

                            debug "Exiting with error code 0..."

                            exit 0
                        }
                    }


                    debug "Unloading the snapin successful. Proceeding to unregister it..."
                        
                    & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"
                        
                    $SnapinRegisterCheck = $null
                        
                    $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                    if($null -ne $SnapinRegisterCheck)
                    {
                        debug "Unregistering the Snapin, FAILED."

                        debug "Exiting with error code 9..."

                        exit 9
                    }
                    else
                    {
                        debug "Unregistering the Snapin, successful."
                        
                        debug "Exiting with error code 0..."
                        
                        exit 0       
                    }
                }
                else
                {
                    debug "Error while trying to associate the created ImgVer Tag with the machine."

                    debug "Proceeding to Unload the Snapin..."

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
                            debug "Unregistering the Snapin after a Failed unload attempt, FAILED."

                            debug "Exiting with error code 9..."

                            exit 9
                        }
                        else
                        {
                            debug "Unregistering the Snapin after a Failed unload attempt successful."

                            debug "Exiting with error code 7..."

                            exit 7
                        }

                    }

                    debug "Unloading the Snapin was successful, proceeding to unregister..."

                    & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"

                    $SnapinRegisterCheck = $null

                    $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                    if($null -ne $SnapinRegisterCheck)
                    {
                        debug "Unregistering the Snapin, FAILED."

                        debug "Exiting with error code 9..."

                        exit 9
                    }

                    debug "Unregistering the Snapin successful."

                    debug "Exiting with error code 7..."

                    exit 7
            }
            }
            else
            {
                debug "New tag creation FAILED."

                debug "Proceeding to unload the snapin..."

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
                        debug "Unregistering the Snapin after a Failed unload attempt, FAILED."

                        debug "Exiting with error code 9..."

                        exit 9
                    }
                    else
                    {
                        debug "Unregistering the Snapin after a Failed unload attempt successful."

                        debug "Exiting with error code 8..."

                        exit 8
                    }
                }


                debug "Unloading the snapin successful. Proceeding to unregister it..."
                        
                & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"
                        
                $SnapinRegisterCheck = $null
                        
                $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                if($null -ne $SnapinRegisterCheck)
                {
                    debug "Unregistering the Snapin, FAILED."

                    debug "Exiting with error code 9..."

                    exit 9
                }
                else
                {
                    debug "Unregistering the Snapin, successful."
                        
                    debug "Exiting with error code 8..."
                        
                    exit 8       
                }
            }
        }     
    }
    else
    {
        debug "The machine already has an old ImgVer tag(s) associated with it. Values:"

        debug "$CurrentTagString"
        
        debug "Proceeding to remove the current ImgVer tag(s)..."
        
        Remove-BrokerTag -Name "ImgVer *" -Machine $MachineData

        $RemovalChecker = $null

        $RemovalChecker = Get-BrokerTag -MachineUid $MachineData.uid -AdminAddress $XenDesktopController | select Name -ErrorAction SilentlyContinue

        if($null -ne $RemovalChecker.Name)
        {
            debug "Converting data obtained for the current ImgVer Tags to a comma-separated string..."

            $RemovalCheckerString = [System.String]::Join(",",$RemovalChecker.Name)
        }
        else
        {
            $RemovalCheckerString = "Blank"
        }

        if( ($false -eq ($RemovalCheckerString.Contains("ImgVer"))) -or ($null -eq $RemovalChecker)  )
        {
            debug "Removal successful. Proceeding to check if the new Tag has ever been created in XD before..."

            $TagExists = Get-BrokerTag -Name "ImgVer $ImageVersion" -AdminAddress $XenDesktopController -ErrorAction SilentlyContinue

            if($null -ne $TagExists)
            {
                
                debug "The given ImgVer already exists in XD. Proceeding to associate the machine with it..."

                Add-BrokerTag -Name "ImgVer $ImageVersion" -Machine $MachineData -AdminAddress $XenDesktopController -ErrorAction SilentlyContinue

                debug "Proceeding to verify if the association was successful..."

                $OperationCheck = $null

                $OperationCheck = Get-BrokerTag -MachineUid $MachineData.uid -AdminAddress $XenDesktopController | select Name -ErrorAction SilentlyContinue

                if($true -eq (($OperationCheck.Name).Contains("ImgVer $ImageVersion")))
                {
                    debug "Script job complete."

                    debug "Proceeding to unload the snapin..."

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
                            debug "Unregistering the Snapin after a Failed unload attempt, FAILED."

                            debug "Exiting with error code 9..."

                            exit 9
                        }
                        else
                        {
                            debug "Unregistering the Snapin after a Failed unload attempt successful."

                            debug "Exiting with error code 0..."

                            exit 0
                        }
                    }


                    debug "Unloading the snapin successful. Proceeding to unregister it..."
                        
                    & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"
                        
                    $SnapinRegisterCheck = $null
                        
                    $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                    if($null -ne $SnapinRegisterCheck)
                    {
                        debug "Unregistering the Snapin, FAILED."

                        debug "Exiting with error code 9..."

                        exit 9
                    }
                    else
                    {
                        debug "Unregistering the Snapin, successful."
                        
                        debug "Exiting with error code 0..."
                        
                        exit 0
                    }
                }
                else
                {
                    debug "Error while trying to associate the existing XD ImgVer Tag with the machine."

                    debug "Proceeding to Unload the Snapin..."

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
                            debug "Unregistering the Snapin after a Failed unload attempt, FAILED."

                            debug "Exiting with error code 9..."

                            exit 9
                        }
                        else
                        {
                            debug "Unregistering the Snapin after a Failed unload attempt successful."

                            debug "Exiting with error code 7..."

                            exit 7
                        }

                    }

                    debug "Unloading the Snapin was successful, proceeding to unregister..."

                    & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"

                    $SnapinRegisterCheck = $null

                    $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                    if($null -ne $SnapinRegisterCheck)
                    {
                        debug "Unregistering the Snapin, FAILED."

                        debug "Exiting with error code 9..."

                        exit 9
                    }

                    debug "Unregistering the Snapin successful."

                    debug "Exiting with error code 7..."

                    exit 7
                }

            }
            else
            {
                debug "The given ImgVer has never been created as XD Tag before. Proceeding to create..."

                New-BrokerTag -Name "ImgVer $ImageVersion" -AdminAddress $XenDesktopController -ErrorAction SilentlyContinue

                debug "Verifying if the creation was successful..."

                $OperationCheck = $null

                $OperationCheck = Get-BrokerTag -Name "ImgVer $ImageVersion" -AdminAddress $XenDesktopController | select Name -ErrorAction SilentlyContinue

                if($true -eq (($OperationCheck.Name).Contains("ImgVer $ImageVersion")))
                {
                    debug "XD ImgVer tag successfully created. Value:"

                    debug "$OperationCheck.Name"

                    debug "Proceeding to associate the machine with it..."

                    Add-BrokerTag -Name $OperationCheck.Name -Machine $MachineData -AdminAddress $XenDesktopController -ErrorAction SilentlyContinue

                    debug "Verifying if association was successful..."

                    $OperationCheck = $null

                    $OperationCheck = Get-BrokerTag -MachineUid $MachineData.uid -AdminAddress $XenDesktopController | select Name -ErrorAction SilentlyContinue

                    if($true -eq (($OperationCheck.Name).Contains("ImgVer $ImageVersion")))
                    {
                        debug "Script job complete."

                        debug "Proceeding to unload the snapin..."

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
                                debug "Unregistering the Snapin after a Failed unload attempt, FAILED."

                                debug "Exiting with error code 9..."

                                exit 9
                            }
                            else
                            {
                                debug "Unregistering the Snapin after a Failed unload attempt successful."

                                debug "Exiting with error code 0..."

                                exit 0
                            }
                        }


                        debug "Unloading the snapin successful. Proceeding to unregister it..."
                        
                        & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"
                        
                        $SnapinRegisterCheck = $null
                        
                        $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                        if($null -ne $SnapinRegisterCheck)
                        {
                            debug "Unregistering the Snapin, FAILED."

                            debug "Exiting with error code 9..."

                            exit 9
                        }
                        else
                        {
                            debug "Unregistering the Snapin, successful."
                        
                            debug "Exiting with error code 0..."
                        
                            exit 0
                        }
                    }
                    else
                    {
                        debug "Error while trying to associate the created ImgVer Tag with the machine."

                        debug "Proceeding to Unload the Snapin..."

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
                                debug "Unregistering the Snapin after a Failed unload attempt, FAILED."

                                debug "Exiting with error code 9..."

                                exit 9
                            }
                            else
                            {
                                debug "Unregistering the Snapin after a Failed unload attempt successful."

                                debug "Exiting with error code 7..."

                                exit 7
                            }

                        }

                        debug "Unloading the Snapin was successful, proceeding to unregister..."

                        & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"

                        $SnapinRegisterCheck = $null

                        $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                        if($null -ne $SnapinRegisterCheck)
                        {
                            debug "Unregistering the Snapin, FAILED."

                            debug "Exiting with error code 9..."

                            exit 9
                        }

                        debug "Unregistering the Snapin successful."

                        debug "Exiting with error code 7..."

                        exit 7
                        }
                }
                else
                {
                    debug "New tag creation FAILED."

                    debug "Proceeding to Unload the Snapin..."

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
                            debug "Unregistering the Snapin after a Failed unload attempt, FAILED."

                            debug "Exiting with error code 9..."

                            exit 9
                        }
                        else
                        {
                            debug "Unregistering the Snapin after a Failed unload attempt successful."

                            debug "Exiting with error code 8..."

                            exit 8
                        }

                    }

                    debug "Unloading the Snapin was successful, proceeding to unregister..."

                    & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"

                    $SnapinRegisterCheck = $null

                    $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

                    if($null -ne $SnapinRegisterCheck)
                    {
                        debug "Unregistering the Snapin, FAILED."

                        debug "Exiting with error code 9..."

                        exit 9
                    }

                    debug "Unregistering the Snapin successful."

                    debug "Exiting with error code 8..."

                    exit 8
                }
            }


        }
        else
        {
            debug "Removal FAILED. Exiting with error code 10..."

            debug "Proceeding to Unload the Snapin..."

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
                    debug "Unregistering the Snapin after a Failed unload attempt, FAILED."

                    debug "Exiting with error code 9..."

                    exit 9
                }
                else
                {
                    debug "Unregistering the Snapin after a Failed unload attempt successful."

                    debug "Exiting with error code 10..."

                    exit 10
                }

            }

            debug "Unloading the Snapin was successful, proceeding to unregister..."

            & $InstallUtil -u ".\SnapIn_V2\BrokerSnapin.dll"

            $SnapinRegisterCheck = $null

            $SnapinRegisterCheck = Get-PSSnapin -Name Citrix.Broker.Admin.V2 -Registered -ErrorAction SilentlyContinue

            if($null -ne $SnapinRegisterCheck)
            {
                 debug "Unregistering the Snapin, FAILED."

                 debug "Exiting with error code 9..."

                 exit 9
            }

            debug "Unregistering the Snapin successful."

            debug "Exiting with error code 10..."

            exit 10
        }
           
    }
}

else
{
    debug "Invalid Parameters passed."

    debug "Exiting with error code 1..."

    exit 1
}
