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

```
Which role would you like to activate?
  1 - Global Reader 
  2 - Usage Summary Reports Reader 
  3 - Message Center Privacy Reader 
  4 - Message Center Reader 
  5 - Reports Reader 
'R/r' to refresh without activating
Which would you like to activate? ('Q/q' to quit without activating):
```
Note 1: You will only see roles you have access to on the account you log in with.
Note 2:  You can pass in multiple values separated by commas (order does not matter). I.e. '1,2,3,4,5' or '4,1,3', etc.
