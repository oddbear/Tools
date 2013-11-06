<#
Should be Powershell v2 compatible, but tested mostly in PSv4.
There is a new Get-FileHash cmdlet. This does not work with PSv2, so this tool is still relevant.

2013.11.03: A working edition.
2013.11.06: Updated with more features.
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

function Compute-Sha1
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
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$rootpath,
        [Parameter(ValueFromPipeline = $true)] $file
    )
    begin
    {
        $sha1 = New-Object System.Security.Cryptography.SHA1Managed;
        
        $tmp = Get-Location;
        Set-Location $rootpath;
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
                hash=$finalhash;
                file=$file | Resolve-Path -Relative;
            }
        }
        finally { Disposer $fs; }
    }
    end
    {
        Disposer $sha1;
        Set-Location $tmp;
    }
}

function Compute-MD5
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
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$rootpath,
        [Parameter(ValueFromPipeline = $true)] $file
    )
    begin
    {
        $md5 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider;
        
        $tmp = Get-Location;
        Set-Location $rootpath;
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
                hash=$finalhash;
                file=$file | Resolve-Path -Relative;
            }
        }
        finally { Disposer $fs; }
    }
    end
    {
        Disposer $md5;
        Set-Location $tmp;
    }
}

function Get-SciptDirectory
{
    <#
    .SYNOPSIS
        Finds the directory of invoker script.
    .DESCRIPTION
        Finds the directory of invoker script.
        Example:
            Get-SciptDirectory
    .INPUTS
    .OUTPUTS
        [System.String]
    #>
    Split-Path -Parent $myInvocation.ScriptName;
}

#function Get-SciptPath
#{
#    <#
#    .SYNOPSIS
#        Finds the full path of invoker script.
#    .DESCRIPTION
#        Finds the full path of invoker script.
#        Example:
#            Get-SciptPath
#    .INPUTS
#    .OUTPUTS
#        [System.String]
#    #>
#    $myInvocation.ScriptName;
#}

#function Get-SciptName
#{
#    <#
#    .SYNOPSIS
#        Finds the name of invoker script.
#    .DESCRIPTION
#        Finds the name of invoker script.
#        Example:
#            Get-SciptName
#    .INPUTS
#    .OUTPUTS
#        [System.String]
#    #>
#    Split-Path -Leaf $myInvocation.ScriptName;
#}

#function Get-RelativePath
#{
#    <#
#    .SYNOPSIS
#        Finds reltive path. Inputpath must exist.
#    .DESCRIPTION
#        Finds the relative path from rootpath.
#        Example:
#            Get-RelativePath "c:\temp\test.iso" "c:\temp\"
#    .INPUTS
#        [string]: Input path.
#        [string]: Root path.
#    .OUTPUTS
#        [System.String]
#    #>
#    param(
#        [Parameter(Mandatory = $true, Position = 0)]
#        [string]$path,
#        [Parameter(Mandatory = $true, Position = 1)]
#        [string]$rootpath
#    )
#    $tmp = Get-Location;
#    Set-Location $rootpath;
#    
#    Resolve-Path $path -Relative;
#
#    Set-Location $tmp;
#}

function Get-FullPath
{
    <#
    .SYNOPSIS
        Finds full path. Inputpath must exist.
    .DESCRIPTION
        Finds the full path from root of drive.
        Example:
            Get-FullPath "c:\temp\test.iso" "c:\temp\"
    .INPUTS
        [string]: Input path.
        [string]: Root path.
    .OUTPUTS
        [System.Management.Automation.PathInfo]
    #>
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$path,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$rootpath
    )
    $tmp = Get-Location;
    Set-Location $rootpath;

    Resolve-Path $path;

    Set-Location $tmp;

}

function Hashtool-Verify
{
    <#
    .SYNOPSIS
        Computes and verifies hashes of files or folders with pre-computed hashfile.
    .DESCRIPTION
        Used to find changed or corrupted files.
        Example:
            Hashtool-Hash "c:\test.iso"
    .INPUTS
        [string]: Path to file or folder to hash.
        [string]: Path to in-/output HashFile. Default "$path" + ".hash".
        [string]: RootPath. Default folder to folder or file selected to hash.
    .OUTPUTS
        [void]
    #>
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$path,
        [string]$hashfile, #path could be relative, full path is calculated before default value is set.
        [string]$rootpath = (Get-SciptDirectory)
    )

    $pathFull = $(Get-FullPath $path $rootpath);

    if(-not $hashfile) { #if no hashfile path is defined, hashfile will be "$fullpath" + ".hash"
        $hashfile = "$pathFull.hash"; #example: "c:\test.iso.hash"
    }

    $dir = dir $pathFull -Recurse | ?{ -Not $_.Mode.Contains("d") } | %{ $_.FullName }; #skip folders.

    $oldfile = Import-Clixml $hashfile;
    switch ($oldfile.type) {
        'sha1' {
            $hashes = $dir | Compute-Sha1 -rootpath $rootpath;
        }
        'md5' {
            $hashes = $dir | Compute-MD5 -rootpath $rootpath;
        }
    }

    Compare-Object $oldfile.hashes $hashes -Property hash, file -PassThru;
}

function Hashtool-Hash
{
    <#
    .SYNOPSIS
        Computes hashes of files or folders.
    .DESCRIPTION
        Used to find changed or corrupted files.
        Example:
            Hashtool-Hash "c:\test.iso"
    .INPUTS
        [string]: Path to file or folder to hash.
        [string]: Path to in-/output HashFile. Default "$path" + ".hash".
        [string]: Type of hash (md5, sha1).
        [string]: RootPath. Default folder to folder or file selected to hash.
        [switch]: Allow overwrite of output hashfile.
    .OUTPUTS
        [void]
    #>
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$path,
        [string]$hashfile, #path could be relative, full path is calculated before default value is set.
        [ValidateSet('md5','sha1')]
        [string]$type = 'sha1',
        [string]$rootpath = (Get-SciptDirectory),
        [switch]$overwrite
    )

    $pathFull = $(Get-FullPath $path $rootpath);

    if(-not $hashfile) { #if no hashfile path is defined, hashfile will be "$fullpath" + ".hash"
        $hashfile = "$pathFull.hash"; #example: "c:\test.iso.hash"
    }

    $dir = dir $pathFull -Recurse | ?{ -Not $_.Mode.Contains("d") } | %{ $_.FullName }; #skip folders.

    switch ($type) {
        'sha1' {
            $hashes = $dir | Compute-Sha1 -rootpath $rootpath;
        }
        'md5' {
            $hashes = $dir | Compute-MD5 -rootpath $rootpath;
        }
    }

    $outfile = New-Object PSObject -Property @{ type=$type; hashes=$hashes; }

    if($overwrite) {
        $outfile | Export-Clixml $hashfile; #Overwrite of hashfile is allowed.
    } else {
        $outfile | Export-Clixml $hashfile -NoClobber; #No overwrite of hashfile.
    }
}
