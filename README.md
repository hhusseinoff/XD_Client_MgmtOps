# XD_Client_MgmtOps

Series of scripts to perform various Citrix-related tasks on client devices (private dekstops)

Inteded to be used as SCCM Packages in SCCM Task sequences


## Commonalities

All of them, except for the XD Gatherer follow the algorithm:

+ Start verbose logging at the location specified in the **debug** function

+ Take the Citrix Broker Snapin Powershell Snapin and register it on the executing machine using the .NET InstallUtil.exe

+ Load the snapin in the current PS Session

+ Perform tasks

+ Unload the Snapin 

+ Unregister the snapin to prevent end users from accessing the Citrix backend on their own


>**Warning**
>The Citrix Broker Snapin Powershell Snapin is not uploade here and must be supplied at the root of the script source, when making the SCCM Package

## XDC Identifier and XD Gatherer

[XDC_Identifier.ps1](https://github.com/hhusseinoff/XD_Client_MgmtOps/blob/main/XDC_Identifier/XDC_Identifier.ps1)

[XD_GatherControll.ps1](https://github.com/hhusseinoff/XD_Client_MgmtOps/blob/main/XD_GatherController/XD_GatherControll.ps1)

+ The XDC Identifier checks the array of XD Controller names, passed as the input param **$ControllersList**

+ Tries to retrieve XD Data at each of them using the name of the executing machine via the Get-BrokerMachine cmdlet

+ If Get-BrokerMachine returns XD Data, creates a string type reg entry under **HKLM:\SOFTWARE\CompanyName**, called ServicingXDController, whose value is equal to the first XD Controller from the input array that returned results

+ If no passed controller is found or other irregular activiy takes place, a simple txt report is generated at the location of **$ReportingLocation**


+ The XD Gatherer searches for the reg entry created by the Identifier Script and returns it back to the task sequence for additional if-else logic ops and use with the MaintMode scripts / XD Tagging scripts


## Maintenance Mode Management

[MM_Enable_V8.ps1](https://github.com/hhusseinoff/XD_Client_MgmtOps/blob/main/MaintMode_Management/MM_Enable_V8.ps1)

[MM_Disable.ps1](https://github.com/hhusseinoff/XD_Client_MgmtOps/blob/main/MaintMode_Management/MM_Disable.ps1)

+ Turn Maintenance Mode on or off respectively.

## XD Tagging

[ImgVer_Tag.ps1](https://github.com/hhusseinoff/XD_Client_MgmtOps/blob/main/XD_ImgVerTag/ImgVer_Tag.ps1)

+ Tags a machine with the passed ***$ImageVersion** input param, Tag name format: "ImgVer $ImageVersion", ImageVersion string can be PR0xx_yy_PR0xx for example

+ Creates the tag automatically at the specified **$XenDesktopController**, if it doesn't already exist as an object there

+ All previous **lower** Image Version tags associated with the machine are cleared
