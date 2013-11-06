#TestTool.ps1
cls

$psv2mode = $false; #Forces Powershell in V2 compatibility mode.

if($psv2mode -and $PSVersionTable.PSVersion.Major -gt 2) #force testing to PSv2, no coloring or debugging in this mode.
{
    #Write-Host "script:" $PSCommandPath
    #$policy = Get-ExecutionPolicy
    powershell.exe -Version 2 -ExecutionPolicy RemoteSigned -File $PSCommandPath
    exit;
}

$path = Split-Path -Parent $MyInvocation.MyCommand.Definition #Path of this script.

Import-Module $path\HashTool.ps1 -Force #Force reload every time.

cls

#Hashtool-Hash ".\Folder1" -overwrite -Verbose
Hashtool-Verify ".\Folder1" -Verbose | ft -Wrap

Write-Host "------------- Next file --------------";

Hashtool-Hash ".\SingleFile1.txt" -overwrite -Verbose
Hashtool-Verify ".\SingleFile1.txt" -Verbose | ft -Wrap

#Write-Host "------------- Next file --------------";

#Hashtool-Hash ".\SubFolder" -rootpath "C:\Temp\Folder2" -overwrite -Verbose | ft -Wrap
#Hashtool-Verify ".\SubFolder" -rootpath "C:\Temp\Folder2" -Verbose | ft -Wrap

<#
If hash mismatch:

hash                                                            file                                                            SideIndicator
----                                                            ----                                                            -------------
E99A18C428CB38D5F260853678922E03                                .\SingleFile1.txt                                               =>           
00000000000000000000000000000000                                .\SingleFile1.txt                                               <=           
#>
