<#
Should be Powershell v2 compatible, but tested mostly in PSv4.

2013.03.11: A working edition.

Todo:
Whould it be bether to make a Make-Hash and Verify-Hash function instead of HashTool?
Could make a GUI mode/switch.
Set-Location might override predefined location?
Rise error if Compare-Object finds changed files.
Add faster non cryptographic hash functions.
#>
function Disposer
{
    <#
    .SYNOPSIS
        Helper method for Disposing objects.
    .DESCRIPTION
        Helper method for Disposing objects.
    .INPUTS
        [PSObject]
    .OUTPUTS
        [void]
    #>
        param($obj)
        if ($obj -and ($obj | Get-Member Dispose)) {
                $obj.Dispose()
        }
}

function ComputeSha1
{
    <#
    .SYNOPSIS
        Computes the sha1 hash of files.
    .DESCRIPTION
        Computes the sha1 hash of files.
        Works with piping.
        Example:
            $path = Split-Path -Parent $MyInvocation.MyCommand.Definition
            $file = "$path\file.bin"
            (ComputeSha1 $file).sha1 #or: ComputeSha1 $files | ...
    .INPUTS
        [string[]]: Pipe of files to be hashed.
        [string]: Output filepath.
    .OUTPUTS
        [PSObject]: { file, sha1 }, file is the filepath, sha1 is the sha1hash of the file.
    #>
    param([Parameter(ValueFromPipeline = $true)] $file)
    begin
    {
        $sha1 = New-Object System.Security.Cryptography.SHA1Managed;
    }
    process
    {
        Write-Verbose "Hashing using sha1: $file";
        $fs = $null;
        try
        {
            $fs = New-Object System.Io.FileStream $file, "Open", "Read";
            $finalhash = [BitConverter]::ToString($sha1.ComputeHash($fs)).Replace("-", "");
            Write-Verbose "Hash: $finalhash";
            New-Object PSObject -Property @{
                type="sha1";
                hash=$finalhash;
                file=$file | Resolve-Path -Relative;
            }
        }
        finally { Disposer $fs }
    }
    end
    {
        Disposer $sha1
    }
}

function ComputeMD5
{

    <#
    .SYNOPSIS
        Computes the md5 hash of files.
    .DESCRIPTION
        Computes the md5 hash of files.
        Works with piping.
        Example:
            $path = Split-Path -Parent $MyInvocation.MyCommand.Definition
            $file = "$path\file.bin"
            (ComputeMD5 $file).md5 #or: ComputeSha1 $files | ...
    .INPUTS
        [string[]]: Pipe of files to be hashed.
        [string]: Output filepath.
    .OUTPUTS
        [PSObject]: { file, md5 }, file is the filepath, sha1 is the md5hash of the file.
    #>
    param([Parameter(ValueFromPipeline = $true)] $file)
    begin
    {
        $md5 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider;
    }
    process
    {
        Write-Verbose "Hashing using md5: $file";
        $fs = $null;
        try
        {
            $fs = New-Object System.Io.FileStream $file, "Open", "Read";
            $finalhash = [BitConverter]::ToString($md5.ComputeHash($fs)).Replace("-", "");
            Write-Verbose "Hash: $finalhash";
            New-Object PSObject -Property @{
                type="md5";
                hash=$finalhash;
                file=$file | Resolve-Path -Relative;
            }
        }
        finally { Disposer $fs }
    }
    end
    {
        Disposer $md5
    }
}

function HashTool
{
    <#
    .SYNOPSIS
        Computes and compare hashes of files or folders.
    .DESCRIPTION
        Computes hashes of file and folder and either stores them in file, or verifies pre-stored hashvalues.
        Used to find changed or corrupted files.
        Example:
            $path = Split-Path -Parent $MyInvocation.MyCommand.Definition
            $folder = ".\Folder1"
            HashTool -path $path -hashfile $path\$folder.hash -folder $folder -type sha1 -hash -overwrite -Verbose
            HashTool       $path           $path\$folder.hash -folder $folder -type sha1 -verify -Verbose
    .INPUTS
        [string]: RootPath.
        [string]: Path to in-/output HashFile.
        [string]: Name of folder to Hash, if no file is provided.
        [string]: Name of file to Hash, if no folder is provided.
        [string]: Type of hash (md5, sha1).
        [switch]: Run in Hash mode.
        [switch]: Run in Verify mode.
        [switch]: Allow overwrite of output hashfile.
    .OUTPUTS
        [void]
    #>
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$path,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$hashfile,
        [string]$folder,
        [string]$file,
        [ValidateSet('md5','sha1')]
        [string]$type = 'sha1',
        [switch]$hash,
        [switch]$verify,
        [switch]$overwrite
    )
    Set-Location $path

    if(($hash -and $verify) -or (-not $hash -and -not $verify)) { throw "Choose either hash or verify switch."; }
    if(($folder -and $file) -or (-not $folder -and -not $file)) { throw "Choose either a folder or a file."; }
    if($hash) { Write-Verbose "Tash: Hash"; } elseif($verify) { Write-Verbose "Task: Verify"; }
    if($folder) { Write-Verbose "Folder: $folder"; } elseif($file) { Write-Verbose "File: $file"; }
    if($verify -and $overwrite) { Write-Warning "No overwrite in verify mode."; }
    Write-Verbose "RootPath: $path";
    Write-Verbose "HashFile: $hashfile";
        
    #get $dir
    if($file) {
        $dir = dir $path\$file | %{ $_.FullName };
    } elseif($folder) {
        $dir = dir $path\$folder -Recurse | ?{ -Not $_.Mode.Contains("d") } | %{ $_.FullName };
    }

    if(-not $dir) { throw "No files."; }

    #get hash:
    Write-Verbose "Type: $type";
    switch ($type) {
        'sha1' {
            $hashes = $dir | ComputeSha1;
        }
        'md5' {
            $hashes = $dir | ComputeMD5;
        }
    }
    #$hashes | ft -AutoSize;

    if($verify) {
        #ConvertTo-Xml $hashes
        $oldhashes = Import-Clixml $hashfile
        Compare-Object $oldhashes $hashes -Property hash, file | ft -Wrap # -PassThru
    } elseif($hash) {
        #ConvertTo-Xml $hashes
        if($overwrite) {
            $hashes | Export-Clixml $hashfile
        } else {
            $hashes | Export-Clixml $hashfile -NoClobber
        }
    }
}
