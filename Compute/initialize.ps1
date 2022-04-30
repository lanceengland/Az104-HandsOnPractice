# Install IIS (with Management Console)
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Install ASP.NET 4.6
Install-WindowsFeature Web-Asp-Net45

# Install Web Management Service
Install-WindowsFeature -Name Web-Mgmt-Service

$whb_installer_url = "https://download.visualstudio.microsoft.com/download/pr/fa3f472e-f47f-4ef5-8242-d3438dd59b42/9b2d9d4eecb33fe98060fd2a2cb01dcd/dotnet-hosting-3.1.0-win.exe"

# use the scratch drive
$whb_installer_file = "D:\dotnet-hosting.exe"

Invoke-WebRequest -Uri $whb_installer_url -OutFile $whb_installer_file

Invoke-Expression -Command "$whb_installer_file /install /quiet /norestart"

###########################################################

$wd_installer_url = "https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"

# use the scratch drive
$wd_installer_file = "D:\WebDeploy.msi"
Invoke-WebRequest -Uri $wd_installer_url -OutFile $wd_installer_file

Invoke-Expression -Command "wd_installer_file /quiet /norestart"

# next steps:
# install cli to pull git repo and deploy
