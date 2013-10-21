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

function Split
{
    <#
    .SYNOPSIS
        Split one file to multiple smaller ones.
    .DESCRIPTION
        Split one file to multiple smaller ones.
        Does support -verbose switch.
        Example:
            $path = Split-Path -Parent $MyInvocation.MyCommand.Definition
            $file = "$path\file.iso"
            $partsSize = 1024 * 512
            Split $file -partsSize $partsSize -verbose
    .INPUTS
        [string]: Input filepath to the file that should be splittet into smaller once.
        [int]: Size of output files in bytes. Default 100MB
        [int]: Size of writebuffer in bytes. Default 256KB
        [int]: Max number of allowed files to output, will throw exception if number is exceeded. Default 100
        [switch]: Allow to overwrite output file true/false. Default false
    .OUTPUTS
        [void]
    #>
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        $innFile,
        $partsSize = 1024 * 1024 * 100, #100MB sizes
	    $bufferSize = 1024 * 256,
        $maxFiles = 100,
        [switch]$forceOverwriteFiles
    )
    #Setup:
    $partsCount = [Math]::Ceiling((Get-Item $innFile).Length / $partsSize);

    if ($partsCount -gt $maxFiles) {
        throw "To many output files"
    }
    
    $outFiles = New-Object String[] $partsCount
    $pad = ($maxFiles - 1).ToString().Length
    for ($i = 0; $i -lt $partsCount; $i++) {
        $outFiles[$i] = "{0}.o{1}" -f $innFile, $i.ToString().PadLeft($pad, '0')
    }
    
    if (!$forceOverwriteFiles) {
        foreach ($f in $outFiles) {
            if (Test-Path $f) {
                throw "File exists: {0}" -f $f
            }
        }
    }

    #Splitting:
    Write-Verbose "Start Splitting"
    try
    {
	    $fr = New-Object System.IO.FileStream($innFile, [System.IO.FileMode]::Open)
	    $buffer = New-Object byte[] $bufferSize
		for ($i = 0; $i -lt $outFiles.Length; $i++) {
            Write-Verbose ("Splitting file {0} of {1}" -f ($i+1), $partsCount)
            try
			{
                $fw = New-Object System.IO.FileStream($outFiles[$i], [System.IO.FileMode]::Create)
			    for ($bp = 0; $bp -lt $partsSize; $bp += $bufferSize)
			    {
				    $bytesRead = $fr.Read($buffer, 0, $bufferSize)
					$fw.Write($buffer, 0, $bytesRead)
			    }
			}
            finally { Disposer $fw }
		}
	}
    finally { Disposer $fr }
    Write-Verbose "Done Splitting"
}

function Merge
{
    <#
    .SYNOPSIS
        Merge smaller files together to one bigger file.
    .DESCRIPTION
        Merge smaller files together to one bigger file.
        Does support -verbose switch.
        Example:
            $path = Split-Path -Parent $MyInvocation.MyCommand.Definition
            $innFiles = dir $path *.o* | %{ $_.FullName }
            $outFile = "$path\file2.bin"
            Merge $innFiles $outFile -verbose
    .INPUTS
        [string[]]: List of files to be merged together, order does matter!
        [string]: Output filepath.
        [int]: Size of writebuffer in bytes. Default 256KB
        [switch]: Allow to overwrite output files true/false. Default false
    .OUTPUTS
        [void]
    #>
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [object[]]$innFiles,
        [Parameter(Mandatory = $true, Position = 1)]
        $outFile,
        $bufferSize = 1024 * 256,
        [switch]$forceOverwriteFiles
    )
    
    foreach ($f in $innFiles) {
        if (!(Test-Path $f)) {
            throw "File does not exists: {0}" -f $f
        }
    }
    
    if (!$forceOverwriteFiles) {
        if (Test-Path $outFile) {
            throw "File exists: {0}" -f $outFile
        }
    }

    #Merging:
    Write-Verbose "Start Merging"
    try
    {
		$fw = New-Object System.IO.FileStream($outFile, [System.IO.FileMode]::Create)
	    $buffer = New-Object byte[] $bufferSize
        $l = $innFiles.Length
	    for ($i = 0; $i -lt $l; $i++) {
            Write-Verbose ("Merging file {0} of {1}" -f ($i+1), $l)
            try
            {
		        $fr = New-Object System.IO.FileStream($innFiles[$i], [System.IO.FileMode]::Open)
				do {
					$bytesRead = $fr.Read($buffer, 0, $bufferSize)
					$fw.Write($buffer, 0, $bytesRead)
				} while($bytesRead -eq $bufferSize)
		    } finally { Disposer $fr }
	    }
	} finally { Disposer $fw }
    Write-Verbose "Done Merging"
}

function CreateMergeFile
{
    <#
    .SYNOPSIS
        Create a mergefile so this script is not needed for merging.
    .DESCRIPTION
        Create a mergefile so this script is not needed for merging.
        Example:
            $path = Split-Path -Parent $MyInvocation.MyCommand.Definition
            $innFiles = dir $path *.o* | %{ $_.FullName }
            CreateMergeFile $innFiles "$path\mergefile.bat" "file.iso"
    .INPUTS
        [string[]]: Files to be included in mergefile, order does matter!
        [string]: Output filepath, the .bat file.
    .OUTPUTS
        [void]
    #>
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [object[]]$innFiles,
        [Parameter(Mandatory = $true, Position = 1)]
        $outFile,
        $mergedFile = "merged.bin"
    )

    "copy /b {1} {0}" -f $mergedFile, (($innFiles | Get-Item | %{ $_.Name }) -join " + ") | Out-File -Encoding default $outFile
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

#------------------------------------------------------------------

<# Some test usage: #>

#$path = Split-Path -Parent $MyInvocation.MyCommand.Definition

#$file = "$path\sqlscript.htm" #file.bin

#$partsSize = 1024 * 512 #1024L * 1024 * 1024 * 2; #2GB L er kanskje ikke nødvendig i PS.

#(ComputeMD5 $file).md5 | Out-File "$file.md5" -Encoding default
#(ComputeSha1 $file).sha1 | Out-File "$file.sha1" -Encoding default

#Split $file -partsSize $partsSize -verbose

#$innFiles = dir $path *.o* | %{ $_.FullName }
#$outFile = "$path\file2.bin"

#Merge $innFiles $outFile -verbose

#CreateMergeFile $innFiles "$path\merge.bat"

#Remove-Item "$path\*.out*" #cleanUp