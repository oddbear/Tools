#testfile.ps1
cls

$psv2mode = $false;

if($psv2mode -and $PSVersionTable.PSVersion.Major -gt 2) #force testing to PSv2, no coloring or debugging in this mode.
{
    #Write-Host "script:" $PSCommandPath
    #$policy = Get-ExecutionPolicy
    powershell.exe -Version 2 -ExecutionPolicy RemoteSigned -File $PSCommandPath
    exit;
}

$path = Split-Path -Parent $MyInvocation.MyCommand.Definition #Path of this script.
$folder = ".\Folder1"
$file = ".\SingleFile1.txt"

Import-Module $path\HashTool.ps1 -Force #Force reload every time.

cls

#Folder:
HashTool -path $path -hashfile $path\$folder.hash -folder $folder -type sha1 -hash -overwrite -Verbose
Write-Host "------------- Next file --------------";

HashTool $path $path\$folder.hash -folder $folder -type sha1 -verify -overwrite -Verbose
Write-Host "------------- Next file --------------";

#File:
#HashTool -path $path -hashfile $path\$file.hash -file $file -type md5 -hash -overwrite -Verbose
#Write-Host "------------- Next file --------------";

HashTool -path $path -hashfile $path\$file.hash -file $file -type md5 -verify -overwrite -Verbose
Write-Host "------------- Next file --------------";

<#
If hash mismatch:

hash                                                            file                                                            SideIndicator
----                                                            ----                                                            -------------
E99A18C428CB38D5F260853678922E03                                .\SingleFile1.txt                                               =>           
00000000000000000000000000000000                                .\SingleFile1.txt                                               <=           
#>
