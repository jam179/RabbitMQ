Function Test-RabbitMQ
{
	# Test if the RabbitMQ is installed.
	Write-Verbose("Checking for RabbitMQ registry key.") 
	$RabbitRegCheck = Get-ItemProperty -path "HKLM:\Software\Ericsson\Erlang\ErlSrv\1.1\RabbitMQ" -ErrorAction SilentlyContinue
	$RegKeyPresent = ($RabbitRegCheck -ne $null)
	Write-Verbose("RabbitMQ Registry key present: $RegKeyPresent")

	Return $RegKeyPresent
}

Function New-DLFolder
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$true)]
		[string]$DownloadDIR
	)

	if (Test-Path $DownloadDIR)		# Test download directory needs to be created
	{
		Write-Verbose("$DownloadDIR directory exists.")
	}
		else
	{
		New-Item $DownloadDIR -ItemType directory
		Write-Verbose("$DownloadDIR directory was created.")
	}
} 

Function Get-Installer
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$true)]
		[string]$URL,
		[Parameter(Mandatory=$true)]
		[string]$Path
	)

	# Split out the filename from the URL 
	$Count = $URL.Split("/").Count - 1
	$Filename = $URL.Split("/")[$Count]

	$Out = $Path + "\" + $Filename 

	if (Test-Path $Out)		#Test if the file needs to be downloaded
	{
		Write-Verbose("$Out already exists. Skipping download.")
	}
	Else
	{
		Invoke-WebRequest $URL -OutFile $Out
		Write-Verbose("The File $Filename was downloaded to $Out")
	}

	Return $Out, $Filename
}

Function Install-Software
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$true)]
		[string]$PathToInstall,

		[Parameter(Mandatory=$true)]
		[string]$Arguments,

		[Parameter(Mandatory=$true)]
		[string]$Process
	)

	Write-Verbose("Path to install is $PathToInstall, Arguments are $Arguments, Process to check is $Process")

	Start-Process -FilePath $PathToInstall -ArgumentList $Arguments

	While (Get-Process -Name $Process -ErrorAction SilentlyContinue | Where-Object {-not $_.HasExited })
	{
		Write-Verbose ("The installer is running.")
		Sleep -Seconds 2
	}
	Write-Verbose("The file $PathToInstall was installed.")
}

Function Enable-RabbitMQManagement
{
	If ($env:Erlang_home -eq $null)    # Check for Environment variable
	{
		Write-Verbose("Setting Erlang_Home environment variable.")
		[environment]::GetEnvironmentVariable("Erlang_Home", "Machine")
		$env:Erlang_home = [environment]::GetEnvironmentVariable("Erlang_Home", "Machine")

		If($env:Erlang_home -eq "C:\Program Files\erl6.3") 
		{
			Write-Verbose ("Attempting to start Management plugin")
			& "C:\Program Files (x86)\RabbitMQ Server\rabbitmq_server-3.5.0\sbin\rabbitmq-plugins.bat" "enable" "rabbitmq_management"
		}
	}
	Else
	{
		Write-Verbose ("Attempting to start Management plugin")
		& "C:\Program Files (x86)\RabbitMQ Server\rabbitmq_server-3.5.0\sbin\rabbitmq-plugins.bat" "enable" "rabbitmq_management"
	}
}

Function New-RabbitMQBuild
{
	[CmdletBinding()]
	Param
	(
		# Directory to download the Erlang installer to.
		[Parameter(Mandatory=$False)]
		[String]$ErlangDlDIR = 'C:\DevOps\Erlang',

		# Directory to download the RabbitMQ installer to.  
		[Parameter(Mandatory=$False)]
		[String]$RabbitMQDlDIR = 'C:\DevOps\RabbitMQ',

		# URL to download Erlang from  
		[Parameter(Mandatory=$False)]
		[String]$ErlangURL = 'http://cc527d412bd9bc2637b1-054807a7b8a5f81313db845a72a4785e.r34.cf1.rackcdn.com/otp_win64_17.4.exe',

		# URL to download RabbitMQ from.  
		[Parameter(Mandatory=$False)]
		[String]$RabbitMQURL = 'http://cc527d412bd9bc2637b1-054807a7b8a5f81313db845a72a4785e.r34.cf1.rackcdn.com/rabbitmq-server-3.5.0.exe'

	)

	<# 1. Test to see if Rabbit is installed #>
	Write-Verbose("Test for Previous install.")
	$ContinueInstall = Test-RabbitMQ

	if ($ContinueInstall -eq $True)
	{
		Write-Verbose("RabbitMQ install failed due to previous installation.")
	}
	else
	{
        Write-Verbose("Continuing with RabbitMQ install.")

        <# 2. Create Erlang download directory #>
		Write-Verbose("Create Erlang download folder.")
		New-DLFolder $ErlangDlDIR

		<# 3. Create RabbitMQ download directory #>
		Write-Verbose("Create RabbitMQ download folder.")
		New-DLFolder $RabbitMQDlDIR

		<# 4. Download Erlang and place in Erlang directory #>
		Write-Verbose("Download Eralang.")
		$ErLangIN = Get-Installer -URL $ErlangURL -Path $ErlangDlDIR

		$ErlangPath = $ErLangIN[0]
		$ErlangFile = $ErLangIN[1]

		$ErlangFile1 = $ErlangFile.Substring(0,$ErlangFile.Length-4)

		<# 5. Download RabbitMQ and place in RabbitMQ directory #>
		Write-Verbose("Download RabbitMQ.")
		$RabbitMQIN = Get-Installer -URL $RabbitMQURL -Path $RabbitMQDlDIR

		$RabbitMQPath = $RabbitMQIN[0]
		$RabbitMQFile = $RabbitMQIN[1]

		$RabbitMQFile1 = $RabbitMQFile.Substring(0,$RabbitMQFile.Length-4)

		<# 6. Install Erlang #>
		Write-Verbose("Install Erlang")
		$ErlangArguments = "/S -Wait -Verbose"
		Install-Software $ErLangPath $ErlangArguments $ErlangFile1

		<# 7. Install RabbitMQ #>
		Write-Verbose("Install RabbitMQ.")
		$RabbitArguments = "/S -Verbose"
		Install-Software $RabbitMQPath $RabbitArguments $RabbitMQFile1

		<# 8. Enable RabbbitMQ Management Plugin #>
		Write-Verbose("Enable RabbbitMQ Management Plugin.")
		Enable-RabbitMQManagement
	}
}