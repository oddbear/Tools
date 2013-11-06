$path = Split-Path -Parent $MyInvocation.MyCommand.Definition #Path of this script.
Import-Module $path\HashTool.ps1

$title = "HashTool Runner";
$message = "Do you want to hash or verify file or folder?";

$hash =   New-Object System.Management.Automation.Host.ChoiceDescription "&Hash",   "Hash file or folder to hashfile.";
$verify = New-Object System.Management.Automation.Host.ChoiceDescription "&Verify", "Verifies files from hash file.";

$options = [System.Management.Automation.Host.ChoiceDescription[]]($hash, $verify);
$result = $Host.ui.PromptForChoice($title, $message, $options, 1);

$fileFolder = Read-Host 'File or folder to hash or verify?'

switch ($result) {
    0 {
        Hashtool-Hash $fileFolder -overwrite;
    }
    1 {
        $hashes = Hashtool-Verify $fileFolder;
        if($hashes) {
            Write-Error "Some files did not match.";
        }
        $hashes | ft -Wrap;
    }
}
