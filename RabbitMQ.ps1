Function Test-RabbitMQMGMT
{
    $ServiceExist = Get-Service -Name RabbitMQ -ErrorAction SilentlyContinue
    $Exist = ($ServiceExist -ne $null)

    if ($Exist -eq $True)
    {
       Write-Verbose ("RabbitMQ service detected")
       If ($ServiceExist.Status -eq "Stopped")
       {
            Write-Verbose ("Service Status is " + $ServiceExist.Status)
            Start-RabbitMQService

            Write-Verbose ("Pausing for 5 Seconds to allow service to Start")
            Start-Sleep -Seconds 5
            # Test if RabbitMQ is installed With the Management plugin enabled.
	        Write-Verbose("Checking if the RabbitMQ management plugin is enabled.")
	        $ListenCHK = netstat -nao | findstr ":15672"
	        $Portlistening = ($ListenCHK -ne $null)
	        Write-Verbose("RabbitMQ management plugin enabled: $Portlistening")

	        Return $Portlistening
       }
       Else
       {
            # Test if RabbitMQ is installed With the Management plugin enabled.
	        Write-Verbose("Checking if the RabbitMQ management plugin is enabled.")
	        $ListenCHK = netstat -nao | findstr ":15672"
	        $Portlistening = ($ListenCHK -ne $null)
	        Write-Verbose("RabbitMQ management plugin enabled: $Portlistening")

	        Return $Portlistening
       }
    }
    Else
    {
        $Portlistening = $false
        Return $Portlistening
    }
}

Function New-DLFolder
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$true)]
		[string]$DownloadDIR
	)

	If (Test-Path $DownloadDIR)		# Test download directory needs to be created
	{
		Write-Verbose("$DownloadDIR directory exists.")
	}
    Else
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

	If (Test-Path $Out)		#Test if the file needs to be downloaded
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

Function Test-PreviousInstall
{
[CmdletBinding()]
	Param
	(
        [Parameter(Mandatory=$true)]
        [string]$AppToCheck
    )

    $Check = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select DisplayName | where { $_.DisplayName -match "$AppToCheck"}

    if ($Check -ne $Null )
    {
        Write-Verbose ("$AppToCheck is installed.")
        Return "Yes"
    }
    else
    {
        Write-Verbose ("$AppToCheck is NOT installed.")
        Return "No"
    }
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

Function Stop-RabbitMQService
{
    Write-Verbose ("Attempting stop.")
    Stop-Service -Name RabbitMQ -Force
    $RabbitMQSRV = Get-Service -Name RabbitMQ
    Write-Verbose ("Service is " + $RabbitMQSRV.Status)
}

Function Start-RabbitMQService
{
    Write-Verbose ("Attempting start.")
    Start-Service -Name RabbitMQ 
    $RabbitMQSRV = Get-Service -Name RabbitMQ
    Write-Verbose ("Service is " + $RabbitMQSRV.Status)
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
	$StartInstall = Test-RabbitMQMGMT

	If ($StartInstall -eq $True)
	{
		Write-Verbose("RabbitMQ install failed due to previous installation.")
	}
	Else
	{
        Write-Verbose("Continuing with RabbitMQ install.")

        <# 2. Create Erlang download directory #>
		Write-Verbose("Create Erlang download folder.")
		New-DLFolder $ErlangDlDIR

		<# 3. Create RabbitMQ download directory #>
		Write-Verbose("Create RabbitMQ download folder.")
		New-DLFolder $RabbitMQDlDIR

		<# 4. Download Erlang and place in Erlang directory #>
		Write-Verbose("Download Erlang.")
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
        #Test: If Erlang is installed
        $ErlangString = "Erlang"
        $ErlangInstalled = Test-PreviousInstall -AppToCheck $ErlangString

        If ($ErlangInstalled -eq "Yes")
        {
            Write-Verbose ("Erlang install aborted.")
        }
        Else
        {
            Write-Verbose("Installing Erlang")
		    $ErlangArguments = "/S -Wait -Verbose"
		    Install-Software $ErLangPath $ErlangArguments $ErlangFile1
        }
       
		<# 7. Install RabbitMQ #>
        #Test: If RabbitMQ is installed
        $RabbitMQString = "RabbitMQ Server"
        $RabbitMQInstalled = Test-PreviousInstall -AppToCheck $RabbitMQString

        If ($RabbitMQInstalled -eq "Yes")
        {
            Write-Verbose ("RabbitMQ install aborted.")
        }
        Else
        {
		    Write-Verbose("Installing RabbitMQ.")
		    $RabbitArguments = "/S -Verbose"
		    Install-Software $RabbitMQPath $RabbitArguments $RabbitMQFile1
        }
        
		<# 8. Enable RabbbitMQ Management Plugin #>
		Write-Verbose("Enabling RabbbitMQ Management Plugin.")
		Enable-RabbitMQManagement

        <# 9. Restart RabbitMQ service #>
        Write-Verbose ("Restarting RabbitMQ service")
        Stop-RabbitMQService
        Start-RabbitMQService
    }
}