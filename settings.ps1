[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)] [switch]$ws7e=$false,
    [Parameter(Mandatory=$false)] [switch]$proxydisable=$false,
    [Parameter(Mandatory=$false)] [switch]$enablequickeditmode=$false,
    [Parameter(Mandatory=$false)] [switch]$errorreportingdisable=$false,
    [Parameter(Mandatory=$false)] [switch]$priorityBackgroundServices=$true,
    [Parameter(Mandatory=$false)] [switch]$removeieshortcut=$false,
    [Parameter(Mandatory=$false)] [switch]$addtaylorsshortcuts=$false
)

. '.\include.ps1'

<#
https://goo.gl/AlWgg9

# this will prioritize background services
.\set-processorscheduling.ps1 -BackgroundServices

# this will prioritize programs
.\set-processorscheduling.ps1 -Programs 
#>

function set-processorscheduling()
{
	param
	(
		[switch]$Programs,
		[switch]$BackgroundServices
	)
	if($Programs)
	{
		Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl `
		  -Name Win32PrioritySeparation -Value 2
	}
	elseif($BackgroundServices)
	{
		Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl `
		  -Name Win32PrioritySeparation -Value 18
	}
	else
	{
		Write-Output "You must specify a flag!"
	}
}

function enable_quick_edit_mode()
{
	# (Get-ItemProperty -Path HKCU:\Console -Name QuickEdit).QuickEdit
	Set-ItemProperty -Path HKCU:\Console -Name QuickEdit -Type Dword -Value 1
}

function error_reporting_disable()
{
	# Disable error reporting for current user
	set-itemproperty -path 'HKCU:\Software\Microsoft\Windows\Windows Error Reporting' `
	  -Type DWord -name DontShowUI -value 1
}

function proxy_disable()
{
	# don't run twice for same user
	if((Test-RegistryKeyValue 'HKCU:\Software\Streambox\win_settings' 'disable_proxy_ran')){
		return 
	}

	New-Item -Type Directory -Path HKCU:\Software\Streambox
	New-Item -Type Directory -Path HKCU:\Software\Streambox\win_settings
	New-ItemProperty -Path HKCU:\Software\Streambox\win_settings -Name disable_proxy_ran -Value 1 `
	  -PropertyType DWORD -Force | Out-Null

	function Disable-AutomaticallyDetectProxySettings
	{
		# Read connection settings from Internet Explorer.
		$regKeyPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections\"
		$conSet = $(Get-ItemProperty $regKeyPath).DefaultConnectionSettings
		
		# Index into DefaultConnectionSettings where the relevant flag resides.
		$flagIndex = 8
		
		# Bit inside the relevant flag which indicates whether or not to enable automatically detect proxy settings.
		$autoProxyFlag = 8
		
		if ($($conSet[$flagIndex] -band $autoProxyFlag) -eq $autoProxyFlag)
		{
			# 'Automatically detect proxy settings' was enabled, adding one disables it.
			Write-Host "Disabling 'Automatically detect proxy settings'."
			$mask = -bnot $autoProxyFlag
			$conSet[$flagIndex] = $conSet[$flagIndex] -band $mask
			$conSet[4]++
			Set-ItemProperty -Path $regKeyPath -Name DefaultConnectionSettings -Value $conSet
		}
		
		$conSet = $(Get-ItemProperty $regKeyPath).DefaultConnectionSettings
		if ($($conSet[$flagIndex] -band $autoProxyFlag) -ne $autoProxyFlag)
		{
    		Write-Host "'Automatically detect proxy settings' is disabled."
		}
	}

	$job = Start-Job -ScriptBlock {
		$dir = (${env:ProgramFiles(x86)}, ${env:ProgramFiles} -ne $null)[0]
		$ie = "{0}\Internet Explorer\iexplore.exe" -f $dir
		Start-Process $ie -WindowStyle Minimized -Wait -PassThru
	}
	Start-Sleep -Seconds 5
	Stop-Job -Id $job.Id

	Disable-AutomaticallyDetectProxySettings

	Set-Itemproperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name ProxyEnable -Value 0

	taskkill /f /im iexplore.exe
}

if($ws7e)
{
	$proxydisable = $true
	$errorreportingdisable = $true
	$enablequickeditmode = $true
	$removeieshortcut = $true
	$priorityBackgroundServices = $true
}

function main()
{
	if($proxydisable)
	{
		proxy_disable
	}

	if($errorreportingdisable)
	{
		error_reporting_disable
	}

	if($enablequickeditmode)
	{
		enable_quick_edit_mode
	}

	if($priorityBackgroundServices)
	{
		set-processorscheduling -BackgroundServices
	}
}

main
