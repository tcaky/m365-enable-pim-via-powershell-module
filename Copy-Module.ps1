#$ScriptName = $MyInvocation.MyCommand.Name
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent

$Destination = Get-Item $HOME\Documents\WindowsPowerShell\Modules

If($false -eq (Test-Path $Destination))
{
    Write-Error 'Could not find destination: "$Destination".  Exiting before copy done.'
    Return
}


Copy-Item $ScriptDir\Modules\* -Recurse -Destination $Destination -Force -Exclude .git*