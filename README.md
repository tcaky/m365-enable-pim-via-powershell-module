>**Note:** A required module for this mudule to function as it was written is AzureADPreview.  This will no doubt change at some point to a full release, and the code will have to be updated.
>
>There is an issue with the time windows tied to PIM roles.  I have not found a way to pull back the time-boundaries associated to given PIM roles (these are something each organization can customize).  The organization I worked for when I wrote this used only four windows (8,4,2,1 - all hours), and therefore I hard-coded those in.  Unless your organization is using the same time bounds, this code may fail.  I will update this module if I ever figure out how to pull back the time window associated to a given PIM role.


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
