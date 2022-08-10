# M365 Enable-PIM-via-Powershell-module

A PowerShell module to allow a user to enable PIM roles quickly via PowerShell (as opposed to the longer process via a web browser, and multiple iterations for multiple roles).

To use this module, you need to put it in the modules directory. I.e :

`$env:USERPROFILE\Documents\WindowsPowerShell\Modules\EnablePIMPowerShell`

Once it is in the Modules directory you can import it manually:

`Import-Module EnablePIMPowerShell`

Alternatively, you can add the Import to your $profile.

```
If($null -ne (Get-Module -ListAvailable -Name EnablePIMPowerShell))
{
    Write-Host "Importing module EnablePIMPowerShell"
    Import-Module EnablePIMPowerShell
}
```


Finally, you can call the code to enable one or more PIM roles.  You must log in when prompted.  This allows for you to run the script as a normal user, but login as an admin account for example to enable PIM roles on the admin account.

`Enable-PIMPowerShell`
