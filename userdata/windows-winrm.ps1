<powershell>

# We add our administrative user, to run ansible role
$computer=$env:ComputerName
$user="Admin_ansible"
$password='1@345Qwert'
$objOu = [ADSI]"WinNT://$computer"
$objGroup = [ADSI]"WinNT://$computer/Administrators,group"
$objUser = $objOU.Create("User", $user)
$objUser.setpassword($password)
$objUser.SetInfo()
$objUser.description = "Local Admin User $user"
$objUser.SetInfo()
$objGroup.Add("WinNT://$user,user")
# Disable UAC
function setRegistryValue($key, $name, $value)
{  
    If ((Test-Path -Path $key) -Eq $false) { New-Item -ItemType Directory -Path $key | Out-Null }  
    Set-ItemProperty -Path $key -Name $name -Value $value -Type "Dword"  
}
function getRegistryValue($key, $name)
{
    (Get-ItemProperty $key $name).$name
}
$Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$ConsentPromptBehaviorAdmin_Name = "ConsentPromptBehaviorAdmin"
$PromptOnSecureDesktop_Name = "PromptOnSecureDesktop"
setRegistryValue $Key $ConsentPromptBehaviorAdmin_Name 0
setRegistryValue $Key $PromptOnSecureDesktop_Name 0
Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore
################################################################################
# Disable Windows Firewall
# ##############################################################################

Set-NetFirewallProfile -Profile Public,Private,Domain -Enabled False

###############################################################################
# Allow Remote Connetions
# #############################################################################

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -Value 0


Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore

# Don't set this before Set-ExecutionPolicy as it throws an error
$ErrorActionPreference = "stop"

# Remove HTTP listener
Remove-Item -Path WSMan:\Localhost\listener\listener* -Recurse

$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName "packer"
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force

# WinRM
write-output "Setting up WinRM"
write-host "(host) setting up WinRM"

cmd.exe /c winrm quickconfig -q
cmd.exe /c winrm set "winrm/config" '@{MaxTimeoutms="1800000"}'
cmd.exe /c winrm set "winrm/config/winrs" '@{MaxMemoryPerShellMB="1024"}'
cmd.exe /c winrm set "winrm/config/service" '@{AllowUnencrypted="true"}'
cmd.exe /c winrm set "winrm/config/client" '@{AllowUnencrypted="true"}'
cmd.exe /c winrm set "winrm/config/service/auth" '@{Basic="true"}'
cmd.exe /c winrm set "winrm/config/client/auth" '@{Basic="true"}'
cmd.exe /c winrm set "winrm/config/service/auth" '@{CredSSP="true"}'
cmd.exe /c winrm set "winrm/config/listener?Address=*+Transport=HTTPS" "@{Port=`"5986`";Hostname=`"packer`";CertificateThumbprint=`"$($Cert.Thumbprint)`"}"
cmd.exe /c netsh advfirewall firewall set rule group="remote administration" new enable=yes
cmd.exe /c netsh firewall add portopening TCP 5986 "Port 5986"
cmd.exe /c net stop winrm
cmd.exe /c sc config winrm start= auto
cmd.exe /c net start winrm
</powershell>
