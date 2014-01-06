<#
Tries to force newer version of PowerShell ISE into PowerShell "v2 comaptibility mode".
You will however loose colors and debugging in this mode.
#>
cls
$psv2mode = $true;

if($psv2mode -and $PSVersionTable.PSVersion.Major -gt 2)
{
    Write-Host "CLR: " $PSVersionTable.CLRVersion.Major;
    Write-Host "PSv: " $PSVersionTable.PSVersion.Major;

    $policy = Get-ExecutionPolicy;
    powershell.exe -Version 2 -ExecutionPolicy $policy -File $PSCommandPath;
    exit;
}

Write-Host "CLR: " $PSVersionTable.CLRVersion.Major;
Write-Host "PSv: " $PSVersionTable.PSVersion.Major;