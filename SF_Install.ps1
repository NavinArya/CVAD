#RUn the Script in ISE as Administrator mode

# installation Variables
 $StoreFront_Installer_Path = "C:\temp\Naveen\Storefront\CitrixStoreFront-x64.exe"
 $WorkSpace_Installer_Path = "C:\temp\Naveen\Storefront\CitrixWorkspaceApp.exe"
# -------------------------------

 $ErrorActionPreference = "Stop"
# Disable open file security warnings
	$env:SEE_MASK_NOZONECHECKS = 1
# -------------------------------

# Installing the windows Feature
    Import-Module ServerManager
    $FeatureInstall = Install-WindowsFeature -Name Web-Default-Doc,Web-Http-Errors,Web-Static-Content,Web-Http-Redirect,Web-Http-Logging,Web-Filtering,Web-Basic-Auth,Web-Windows-Auth,Web-Net-Ext45,Web-AppInit,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Mgmt-Console,Web-Scripting-Tools,NET-Framework-45-ASPNET -Restart:$false
    if ($FeatureInstall.ExitCode -eq "NoChangeNeeded") {
        Write-Host "Required IIS Windows features already installed" -ForegroundColor Green
    }
    if ($FeatureInstall.ExitCode -eq "Success") {
        Write-Host "Reboot needed for IIS Windows features installation." -ForegroundColor Magenta
        Start-Sleep -Seconds 20
        #Restart-Computer -Force
    }
# -------------------------------


# Check if WOrkspace is already installed

# Check if WOrkspace is already installed
    if ((Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "Citrix Workspace Inside*"}).Name -contains "Citrix Workspace Inside") {
        Write-Host "Citrix Workspace already installed." -ForegroundColor Green
    } else {
# Installing Workspace application  
        Write-Host "Installing Citrix WorkSpace Application." -ForegroundColor Green
        cmd.exe /c $WorkSpace_Installer_Path /silent /noreboot

        if ((Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "Citrix Workspace Inside*"}).Name -contains "Citrix Workspace Inside") {
            Write-Host "Silent installation of Citrix WorkSpace completed. Please Reboot the server." -ForegroundColor Cyan
            Start-Sleep -Seconds 20
        } else {
            Write-Host "Citrix WorkSpace installation is failed." -ForegroundColor Red
        }
    }




# Check if StoreFront is already installed
    if ((Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "Citrix*"}).Name -contains "Citrix StoreFront") {
        Write-Host "Citrix StoreFront already installed." -ForegroundColor Green
    } else {
# Install StoreFront
        Write-Host "Installing Citrix StoreFront." -ForegroundColor Green
       Start-Process -FilePath $StoreFront_Installer_Path -ArgumentList "-silent" -Wait -PassThru
        if ((Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "Citrix*"}).Name -contains "Citrix StoreFront") {
            Write-Host "Citrix StoreFront installed. Rebooting the server." -ForegroundColor Cyan
            Start-Sleep -Seconds 20
            Restart-Computer -Force
        } else {
            Write-Host "Citrix StoreFront installation is failed." -ForegroundColor Red
        }
    }

