<#
Should be Powershell v2 compatible, but tested mostly in PSv3.
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
	    $sha1 = New-Object System.Security.Cryptography.SHA1Managed
    }
	process
	{
	    $fs = $null
	    try
	    {
	        $fs = New-Object System.Io.FileStream $file, "Open", "Read"
            New-Object PSObject -Property @{
                sha1=[BitConverter]::ToString($sha1.ComputeHash($fs)).Replace("-", "");
                file=$file;
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
	    $md5 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
    }
	process
	{
	    $fs = $null
	    try
	    {
	        $fs = New-Object System.Io.FileStream $file, "Open", "Read"
            New-Object PSObject -Property @{
                md5=[BitConverter]::ToString($md5.ComputeHash($fs)).Replace("-", "");
                file=$file;
            }
	    }
	    finally { Disposer $fs }
	}
	end
    {
        Disposer $md5
    }
}
