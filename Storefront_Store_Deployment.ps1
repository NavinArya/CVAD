<#
 .SYNOPSIS
# Created on: 10.01.2023 Version: 1.4
# Created by: Naveen@Cloud9vin.com
# File name: StorefrontDeployment.ps1
# Description: This scripts do the standalone SF store Deployment in 1912LTSR citrix environment
  
# Prerequisite:1. Citrix PowerShell  module are available.
               2. SF installation is completed #use SF_Install.ps1
               3. Workspace Installation(optional) #use SF_Install.ps1
               4. Windows Feature(Web-Default-Doc,Web-Http-Errors,Web-Static-Content,Web-Http-Redirect,Web-Http-Logging,Web-Filtering,Web-Basic-Auth,Web-Windows-Auth,Web-Net-Ext45,Web-AppInit,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Mgmt-Console,Web-Scripting-Tools,NET-Framework-45-ASPNET(latest)) #use SF_Install.ps1

# Call by : Manually

Note:! Read it once before your run it 
Contact at Naveen@Cloud9vin.com  for any query.

 #>

Start-Transcript -Path C:\Temp\Naveen\storeconfig.txt

    $SFBaseURL = "https://ctxalabsf.Cloud9vin.com" # <-- EDIT - Define Base URL (e.g. https://storefront.local.lan)								  
    $XDDeliveryController1 = "ctxalabddc.Cloud9vin.com" # <-- EDIT - Define primary Citrix VADs Delivery Controller (e.g. xddc1.local.lan)
    $XDDeliveryController2 = "If any " # <-- EDIT - Define secondary Citrix VADs Delivery Controller (leave empty if there is only one Delivery Controller)
    $StoreFriendlyName = "Store" # <-- EDIT - Define StoreFront store name
    $XDFarmName = "Cloud9farm" # <-- EDIT - Define Citrix VADs farm name

# Pre-defined variables

    ##StoreVariable
    $SiteID = 1
    $StoreFriendlyNameWithoutSpaces = $StoreFriendlyName -replace '\s',''
    $StoreFriendlyNameWithoutSpacesWeb = $StoreFriendlyNameWithoutSpaces + "Web"
    $StoreVirtualPath = "/Citrix/" + $StoreFriendlyName -replace '\s',''
    $StoreVirtualPathWeb = $StoreVirtualPath + "Web"
    $StoreURL = $SFBaseURL + "/Citrix/" + $StoreFriendlyNameWithoutSpaces
    ##XD Controller infomation
    $FarmType = "XenDesktop"
    $TransportType ="HTTPS"
    $XMLPort = "80"
    $SslRelayPort = "443"

    ##NetScaler Infomation 
    $GatewayName="SF-COM" # <-- EDIT - Provide the Gateway Name)	
    $GatewayUrl="https://sf.Cloud9vin.com/" # <-- EDIT - Provide the Gateway url details)
    $GatewaySTAUrls="https://ctxalabsf.Cloud9vin.com" # <-- EDIT - Provide the STA url details)

    ##IIS Information 
    $RedirectFile = "Web.config"
    $RedirectPath = "C:\inetpub\wwwroot\"
    $RedirectPage = $RedirectPath + $Redirectfile

    $SFConfigFiles = "$env:ProgramFiles\Citrix\Receiver StoreFront\Services\SubscriptionsStoreService\Citrix.DeliveryServices.SubscriptionsStore.ServiceHost.exe.config",
                    "$env:ProgramFiles\Citrix\Receiver StoreFront\Services\CredentialWallet\Citrix.DeliveryServices.CredentialWallet.ServiceHost.exe.config"

# -------------------------------

# PREREQUISITES -----------------
# Set Stop on error
    $ErrorActionPreference = "Stop"
#importing the Citrix module for Storefront
    Import-Module 'C:\Program Files\Citrix\Receiver StoreFront\PowerShellSDK\Modules\Citrix.StoreFront'
	 & "C:\Program Files\Citrix\Receiver StoreFront\Scripts\ImportModules.ps1"
    Start-Sleep -Seconds 10
# -------------------------------

# SCRIPT ------------------------
# Create initial store (will be deleted after creation of the definitive store)
   Set-DSInitialConfiguration -HostBaseUrl $SFBaseURL `
        -FarmName $XDFarmName `
        -Port 443 `
        -Transporttype HTTPS `
        -SslRelayPort 443 `
        -Servers @("tempddc.domain.lan") `
        -LoadBalance $false `
        -FarmType "XenDesktop" `
        -StoreVirtualPath /Citrix/TEMP `
        -WebReceiverVirtualPath /Citrix/TEMPWeb
       

# Create StoreFront store with one defined XenDesktop Delivery Controller

       if ($XDDeliveryController2 -eq "") {
        $AuthSummary = Get-DSAuthenticationServicesSummary -SiteID $SiteID 
        Install-DSStoreServiceAndConfigure  `
            -SiteID $SiteID `
            -FriendlyName $StoreFriendlyName `
            -VirtualPath $StoreVirtualPath `
            -AuthSummary $AuthSummary `
            -FarmName $XDFarmName `
            -FarmType $FarmType `
            -Servers @($XDDeliveryController1) `
            -TransportType $TransportType `
            -ServicePort $ServicePort `
            -SslRelayPort $SslRelayPort
            

        Install-DSWebReceiver -FriendlyName $StoreFriendlyName `
            -SiteID 1 `
            -StoreURL $StoreURL `
            -useHttps $true `
            -VirtualPath $StoreVirtualPathWeb
    }

# Create StoreFront store with two defined XenDesktop Delivery Controllers
    if ($XDDeliveryController2 -ne "") {
        $AuthSummary = Get-DSAuthenticationServicesSummary -SiteID $SiteID
        Install-DSStoreServiceAndConfigure -SiteID $SiteID `
            -FriendlyName $StoreFriendlyName `
            -VirtualPath $StoreVirtualPath `
            -AuthSummary $AuthSummary `
            -FarmName $XDFarmName `
            -FarmType $FarmType `
            -Servers @($XDDeliveryController1,$XDDeliveryController2) `
            -TransportType $TransportType `
            -ServicePort $XMLPOrt `
            -SslRelayPort $SslRelayPort

        Install-DSWebReceiver -FriendlyName $StoreFriendlyName `
            -SiteID 1 `
            -StoreURL $StoreURL `
            -useHttps $false `
            -VirtualPath $StoreVirtualPathWeb
        }

# Remove initial test store
    Remove-DSStore2 -SiteID 1 -VirtualPath "/Citrix/TEMP"
# -------------------------------​


##Adding the citrix Netscaler details and beacons  Information :
Write-Host "Adding NetScaler Gateway and Beacons detail" -ForegroundColor Cyan
Add-DSGlobalV10Gateway -Address $GatewayUrl -Id 1 -Logon Domain -Name $GatewayName   -IsDefault $True -SecureTicketAuthorityUrls $GatewaySTAUrls -SessionReliability $true -AreStaServersLoadBalanced $false
sleep  1

##Setting the Netscaler Gateway for Store 
$Gateway = Get-DSGlobalGateway -GatewayId 1
Set-DSStoreGateways -SiteId $SiteID -VirtualPath $StoreVirtualPath  -Gateways $Gateway


####Adding Authentication method

<# Below are authentication method can be used in SF authentication,Here in Acus we use option 1 & 6
1. User name and password = ExplicitForms
2. SAML Authentication = Forms-Saml
3. Domain pass-through = IntegratedWindows
4. Smart card = Certificate
5. HTTP Basic = HttpBasic
6. Pass-through from NetScaler Gateway = CitrixAGBasic
#>

$WebReceiver = Get-STFWebReceiverService -VirtualPath $StoreVirtualPathWeb #test the type of authentication method
Get-STFWebReceiverAuthenticationMethods $webReceiver
Set-STFWebReceiverAuthenticationMethods -WebReceiverService $WebReceiver -AuthenticationMethods ExplicitForms,CitrixAGBasic -TokenLifeTime 20:00:00


#ExplicitForms/UserName & Password configuration : Manage Password Options

$AuthService = Get-STFAuthenticationService -SiteID $SiteID -VirtualPath "/Citrix/Authentication"
Set-STFExplicitCommonOptions -AuthenticationService $AuthService -AllowUserPasswordChange Always -ShowPasswordExpiryWarning Never

#enabling the Pass through with netscaler

Enable-STFAuthenticationServiceProtocol -Name CitrixAGBasic  -AuthenticationService (Get-STFAuthenticationService)




###Setting the Store for Remote Access
Write-Host "Enabling & Configuring the host for Remote Access" -ForegroundColor Cyan

Set-DSStoreRemoteAccess -RemoteAccessType StoresOnly -SiteId $SiteID -VirtualPath $StoreVirtualPath
Sleep 1



#########Adding Http redirect in IIS under default website home
<#
$Http_Redirect = Get-STFWebReceiverService -SiteId $SiteID -VirtualPath $StoreVirtualPath
Set-STFWebReceiverService -WebReceiverService $Http_Redirect -DefaultIISSite:$True

#>
 #copy the webconfig from sharepath or from old sf server as this script is bascially created to decomission the old the SF servers.
 Copy-Item -Path '\\ctalabsfold1\c$\inetpub\wwwroot\web.config' -Destination C:\inetpub\wwwroot -Force ####coping the webconfig from old sf server(optional)

 ####Configuration of Manage receiver for websites
 #---------Start Script--------------#
$WebReceiver = Get-STFWebReceiverService -VirtualPath $StoreVirtualPathWeb 
Get-STFWebReceiverSiteStyle -WebReceiverService $WebReceiver #this command will pull the default appearence setting for the storefront and we need to change the #HeaderBackgroundColor colour 
Set-STFWebReceiverSiteStyle -WebReceiverService $WebReceiver -HeaderLogoPath "C:\inetpub\wwwroot\Citrix\StoreWeb\receiver\images\2x\CitrixReceiverLogo_Home@2x_3FEDFD700D66DF42.png" -LogonLogoPath "C:\inetpub\wwwroot\Citrix\StoreWeb\receiver\images\2x\CitrixStoreFront_auth@2x_1B99A8ADCDDFD9AB.png" -HeaderForegroundColor "#FFFFFF" -HeaderBackgroundColor "#005EB8" -LinkColor "#02a1c1" 

#disabling the download HDX engine setting(optional)
Set-STFWebReceiverPluginAssistant -WebReceiverService $WebReceiver -Enabled $false

###Setting the session cotrol settings(optional)
set-STFWebReceiverCommunication  -WebReceiverService $WebReceiver -Attempts 1 -Timeout 00:03:00
Set-STFWebReceiverService -WebReceiverService $WebReceiver -SessionStateTimeout (60*20)
Set-STFWebReceiverAuthenticationManager -WebReceiverService $WebReceiver -LoginFormTimeout 60 
sleep 1

###WorkSpace Control setting(optional)
Set-STFWebReceiverUserInterface -WebReceiverService $WebReceiver -WorkspaceControlEnabled $false -WorkspaceControlAutoReconnectAtLogon $false -WorkspaceControlLogoffAction Terminate -WorkspaceControlShowReconnectButton $false -WorkspaceControlShowDisconnectButton $false
###client interface setting
Set-STFWebReceiverUserInterface -WebReceiverService $WebReceiver -AutoLaunchDesktop $false -MultiClickTimeout 30 -ShowDesktopsView $true -ReceiverConfigurationEnabled $false -ShowAppsView $true  -DefaultView Auto

###Advance Settig(optional)
Set-STFWebReceiverPluginAssistant -WebReceiverService $WebReceiver -ProtocolHandlerEnabled $False
 #---------End Script--------------#


####Adding the Certificate for https:


if ($SFBaseURL -like "*https*") {

$password=Get-Credential -UserName 'Enter password below' -Message "Enter the Exported Certificate Password"

$certificate=Import-PfxCertificate -FilePath C:\Users\Administrator\Desktop\SFCertificate.pfx -Password $password.Password -CertStoreLocation 'cert:\localmachine\my'

# Add certificate to Trusted Root Certification Authorities
        $CertificateRootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store -ArgumentList Root, LocalMachine
        $CertificateRootStore.Open("MaxAllowed")
        $CertificateRootStore.Add($Certificate)
        $CertificateRootStore.Close()
        Write-Host "Successfully imported the"$certificate.FriendlyName " to Trusted Root Certification Authorities" -ForegroundColor Cyan

# Get certificate thumbprint
        $Thumbprint = $Certificate.Thumbprint
# Create new IIS binding
        Write-Host "Binding the "$certificate.FriendlyName " Certificate for Https:" -ForegroundColor Cyan
        New-WebBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol https -Verbose

# Add certiticate to IIS binding
        Start-Sleep -Seconds 5
        $Binding = Get-WebBinding -IPAddress "*" -Port 443 -Protocol https
        $Binding.AddSslCertificate($Thumbprint, "my")
       Write-Host " successfullt Binded the "$certificate.FriendlyName " Certificate for Https:" -ForegroundColor Green

    }

    
##Citrix Storefront Customization(optional)
 
$Source_Path='\\acus\tsdata\Storefront Customization\Custom_PDT' ###I have alreday have the customized file hence using the same
$Files=Get-ChildItem -Path $Source_Path
$Custom='C:\inetpub\wwwroot\Citrix\StoreWeb\Custom'
$Change_Password_tfrm='C:\inetpub\wwwroot\Citrix\Authentication\App_Data\Templates'


if(Test-Path $Source_Path){

foreach($File in $Files){

if(($File.Name -like "amadeus*") -or ($File.Name -like "script.js*") -or($File.Name -like "style.css*")){

#Rename-Item -Path "$Custom\Custom" -NewName  "$Custom\Custom.old" -Force
Write-Host "Copying" $file.Name "to $Custom folder" -ForegroundColor Yellow

Copy-Item  -Path $Source_Path\$file  -Destination $Custom -Force

}

elseif($File.Name -like "ChangePassword*"){

Write-Host "Copying" $file.Name "to $Change_Password_tfrm folder" -ForegroundColor Cyan

Copy-Item  -Path $Source_Path\$file -Destination $Change_Password_tfrm -Force


}
elseif($File.Name -like "*Default.ica*"){
Write-Host "Copying" $file.Name "to $ICA_Default folder" -ForegroundColor Green

Copy-Item  -Path $Source_Path\$file -Destination $ICA_Default -Force


}

else{

Write-Host "Customized files are not avilable in" $Source_Path
}


}



}


Stop-Transcript

##############End of script#################################################################

  
 
