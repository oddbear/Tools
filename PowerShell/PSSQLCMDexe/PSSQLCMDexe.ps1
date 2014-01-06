<#
Should be Powershell v2 compatible, but tested mostly in PSv3.
Invoke-SQLCMDexe an alternative where you don't have Invoke-SQLCMD.
Do have some limitations because it's based on SQLCMD.

2014.01.03: A working example.
#>

<#
.SYNOPSIS
    Wrapper for SQLCMD.exe to make SQLCMD.exe more PowerShell friendly.
.DESCRIPTION
    Wrapper for SQLCMD.exe to make SQLCMD.exe more PowerShell friendly.
    Looks a lot like Invoke-SQLCMD. But also supports multiple resultsets as $t[0], $t[1], etc.
    Example:
        Invoke-SQLCMDexe -Q "SELECT name, dbid FROM master..sysdatabases;SELECT mode, status FROM master..sysdatabases;" -S ".";
.INPUTS
    [string] $ServerInstance    #Server and instance name.
    [string] $Database          #The initial database to use.
    [string] $Query             #Run the specified query and exit.
    [string] $UserName          #SQL Server Authentication login ID.
    [string] $Password          #SQL Server Authentication password.
    [int]    $QueryTimeout      #Query timeout interval.
    [string] $InputFile         #Input file containing a query
    [string] $NewPassword       #Change password and exit.
       [int] $ConnectionTimeout #Login timeout interval.
    [string] $HostName          #Hostname.
  [string[]] $Variable          #Variable definition.
.OUTPUTS
    [PSObject[]]
#>
function Invoke-SQLCMDexe {
    param(
        [string]$ServerInstance,    #Server and instance name.
        [string]$Database,          #The initial database to use.
        [string]$Query,             #Run the specified query and exit.
        [string]$UserName,          #SQL Server Authentication login ID.
        [string]$Password,          #SQL Server Authentication password.
           [int]$QueryTimeout,      #Query timeout interval.
        [string]$InputFile,         #Input file containing a query
        [string]$NewPassword,       #Change password and exit.
           [int]$ConnectionTimeout, #Login timeout interval.
        [string]$HostName,          #Hostname.
        [string[]]$Variable         #Variable definition.
    )

    #Setup Expression:
    $exp = "& `"SQLCMD.exe`"";
    if($ServerInstance)    { $exp += " -S `"$ServerInstance`""; }
    if($Database)          { $exp += " -d `"$Database`""; }
    if($Query)             { $exp += " -Q `"$Query`"".Replace("$", '`$'); } #Needs special Care by .Net String method -replace does not work. Used for parameterized values.
    if($UserName)          { $exp += " -U `"$UserName`""; }
    if($Password)          { $exp += " -P `"$Password`""; }
    if($QueryTimeout)      { $exp += " -t `"$QueryTimeout`""; }
    if($InputFile)         { $exp += " -i `"$InputFile`""; }
    if($NewPassword)       { $exp += " -Z `"$NewPassword`""; }
    if($Variable)          { $exp += " -v"; $Variable | ForEach { $exp += " $_"; }; } #Used for parameterized values.
    #-b	-AbortOnError                     #Stop running on an error
    #-A	-DedicatedAdministratorConnection #Dedicated Administrator Connection.
    #-X	-DisableCommands                  #Disable interactive commands, startup script, and environment variables.
    #-x	-DisableVariables                 #Disable variable substitution.
    #-V	-SeverityLevel                    #Minimum severity level to report.
    #-m	-ErrorLevel                       #Minimum error level to report.
    if($ConnectionTimeout) { $exp += " -l `"$ConnectionTimeout`""; }
    if($HostName)          { $exp += " -H `"$HostName`""; }
    #-w	-MaxCharLength                    #Maximum length of character output.
    #-w	-MaxBinaryLength                  #Maximum length of binary output.
    
    $lines = [string[]]$(Invoke-Expression $exp);

    $tFA = @(); #tablesFormatedArray
    $tU = @(); #tablesUnformated

    #Extracts each resultset from output:
    foreach($line in $lines) {
        if($line.EndsWith(" rows affected)")) {
            $tFA += Format-SQLCMDexe $tU; #Alternative for splitting table inside array: , (Format-SQLCMDexe $tu)
            $tU = @();
        } else {
            $tU += $line;
        }
    }

    $tFA; return;
}

<#
.SYNOPSIS
    Returnes a formated table where each row is an PSObject.
.DESCRIPTION
    Returnes a formated table where each row is an PSObject.
    Example:
        Format-SQLCMDexe $SQLCMDexeResultSet;
.INPUTS
    [string]: -lines :: "Lines from output without empty rows and 'rows affected' text."
.OUTPUTS
    [PSObject[]]
#>
function Format-SQLCMDexe {
    param([string[]]$Lines)

    $Lines = $Lines | Where { $_ -and $_ -notlike "* rows affected)" }; #Filters out empty lines and last lines.

    #Extract Column information:
    $cols = @();
    $colWidthTot = 0;
    foreach($colWidth in $Lines[1] -split " " | %{ $_.Length; }) {
        $cols += New-Object PSObject -Property @{
            Name = $Lines[0].Substring($colWidthTot, $colWidth).Trim();
            StartIndex = $colWidthTot;
            Width = $colWidth;
        }
        $colWidthTot += $colWidth + 1;
    }

    #Extract rows and format them after column information:
    $table = @();
    for($i = 2; $i -lt $Lines.Length; $i++) {
        $row = New-Object PSObject;
        foreach($col in $cols) {
            #Every value is returned as strings, using CastFrom-String to make them valuetypes if posible.
            $row | Add-Member -type NoteProperty -name $col.Name -value (CastFrom-String $Lines[$i].SubString($col.StartIndex, $col.Width).Trim());
        }
        $table += $row;
    }

    $table; return;
}

<#
.SYNOPSIS
    Casts Strings to their primitive values.
.DESCRIPTION
    Helper method to cast a string value to a primitive value.
    Example:
        (CastFrom-String "123").GetType(); #[Byte]
.INPUTS
    [string]                            $String   #String value.
    [IFormatProvider]                   $Provider #Default: [System.Globalization.CultureInfo]::InvariantCulture.
    [System.Globalization.NumberStyles] $Styles   #Default: [System.Globalization.NumberStyles]::Number.
    [string]                            $Format   #DateTime format.
.OUTPUTS
    [ValueType] or [Object] / [String]
#>
function CastFrom-String {
    param(
        [string]$String,
        [IFormatProvider]$Provider = [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.NumberStyles]$Styles = [System.Globalization.NumberStyles]::Number,
        [string]$Format
    )

    #Primitives:
    $value = $null;
    if([byte]::TryParse($String, [ref]$value)) { $value; return; }
    if([int]::TryParse($String, [ref]$value)) { $value; return; }
    if([long]::TryParse($String, [ref]$value)) { $value; return; }
    if([decimal]::TryParse($String, $styles, $provider, [ref]$value)) { $value; return; }
    
    #DateTime:
    [datetime]$date = [DateTime]::MinValue; #Needs to be in correct format:
    if($Format -and [DateTime]::TryParseExact($String, $format, $provider, [System.Globalization.DateTimeStyles]::None, [ref]$date)) { $date; return; }
    elseif(         [DateTime]::TryParse($String, [ref]$date)) { $date; return; }

    #Nothing found:
    $String; return;
}

#Test:
$varArr = @(
    "tmp    = 10",
    "tmp2   =  2"
);

$query = @"
SELECT name, dbid FROM master..sysdatabases;
SELECT name, mode FROM master..sysdatabases WHERE dbid < `$(tmp) AND dbid > `$(tmp2);
"@;

$tables = Invoke-SQLCMDexe -Query $query -ServerInstance "." -Variable $varArr;
$tables[0] | ft -AutoSize; #First row only
$tables[1] | ft -AutoSize; #Second row only
$tables | ft -AutoSize; #Might not work with all PowerShell versions.
$tables | Select Name, @{Name="dbidType";Expression={ $_.dbid.GetType() }; }, Mode | ft -AutoSize;