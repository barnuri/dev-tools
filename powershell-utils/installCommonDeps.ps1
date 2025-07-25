Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"

Import-Module -Name Appx -UseWindowsPowerShell

Add-AppxPackage 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
Add-AppxPackage 'https://raw.githubusercontent.com/barnuri/dev-tools/master/powershell-utils/appx/Microsoft.UI.Xaml.2.7.appx'
Add-AppxPackage 'https://github.com/microsoft/winget-cli/releases/download/v1.4.2161-preview/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'

winget install --id Microsoft.WindowsTerminal -e
