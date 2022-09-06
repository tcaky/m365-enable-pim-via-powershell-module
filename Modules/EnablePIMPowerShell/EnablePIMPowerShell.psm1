# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Ensure you have AzureADPreview installed
#Use Install-Module AzureADPreview to install module
Import-Module AzureADPreview -ErrorAction Stop

Import-LocalizedData -BindingVariable MsgTable

#region Helper Functions
Function New-PimSchedule
{
<#
.DESCRIPTION
    This is a helper function.  It just helps make the code block where we
    are creating schedules a bit cleaner.

.NOTES
    Name: New-PimSchedule
    Author: keith.young@ec.gc.ca
    Version: 1.0
    DateCreated: 2022-May-05

.EXAMPLE 
    New-PimSchedule -HoursOffset 8
#>
    Param(
        [Parameter()]
        [Int]$HoursOffset
    )
    BEGIN
    {
        $UtcFormat = 'yyyy-MM-ddTHH:mm:ss.fffZ'
    }
    PROCESS
    {
        $DateObj = Get-Date
    
        $Schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
        $Schedule.Type = 'Once'
        $Schedule.StartDateTime = $DateObj.ToUniversalTime().ToString($UtcFormat)
        $Schedule.EndDateTime = $DateObj.AddHours($HoursOffset).ToUniversalTime().ToString($UtcFormat)

        $Schedule # Return
    }
    END
    {
    }
}

Function Get-PIMRoleAssignmentByUserPrincipalName
{
<#
.SYNOPSIS
    This will return all allowed PIM roles a user can activate.  It will also return any currently active
    PIM roles as part of the same result.
 
.NOTES
    Name: Get-PIMRoleAssignmentByUserPrincipalName
    Author: keith.young@ec.gc.ca
    Version: 1.0
    DateCreated: 2022-May-05

    See https://thesysadminchannel.com/get-pim-role-assignment-status-for-azure-ad-using-powershell/
    for original blog entry this function is based on.  I stripped it down to only what I needed.
 
.EXAMPLE
    Get-PIMRoleAssignmentByUserPrincipalName -UserPrincipalName reader.fname.lname@ec.gc.ca
#>
 
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position  = 0
        )]
        [string[]]  $UserPrincipalName,
        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [string]    $TenantId
    )
 
    BEGIN 
    {
        If(-not ($PSBoundParameters.ContainsKey('TenantId'))) 
        {
            $SessionInfo = Get-AzureADCurrentSessionInfo -ErrorAction Stop
            $TenantId = $SessionInfo.TenantId
        }
 
        $AdminRoles = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $TenantId -ErrorAction Stop | Select-Object Id, DisplayName
        $RoleId = @{}

        ForEach($AdminRole in $AdminRoles)
        {
            $RoleId.Add($AdminRole.DisplayName, $AdminRole.Id)
        }
    }
 
    PROCESS 
    {
        If($PSBoundParameters.ContainsKey('UserPrincipalName')) 
        {
            ForEach ($User in $UserPrincipalName) 
            {
                Try 
                {
                    $AzureUser = Get-AzureADUser -ObjectId $User -ErrorAction Stop | select DisplayName, UserPrincipalName, ObjectId
                    $UserRoles = Get-AzureADMSPrivilegedRoleAssignment -ProviderId aadRoles -ResourceId $TenantId -Filter "subjectId eq '$($AzureUser.ObjectId)'"
 
                    If($UserRoles)
                    {
                        ForEach($Role in $UserRoles)
                        {
                            $RoleObject = $AdminRoles | Where-Object {
                                $Role.RoleDefinitionId -eq $_.id
                            }
 
                            [PSCustomObject]@{
                                UserPrincipalName = $AzureUser.UserPrincipalName
                                AzureADRole       = $RoleObject.DisplayName
                                AzureADRoleGuid   = $RoleObject.Id
                                PIMAssignment     = $Role.AssignmentState
                                MemberType        = $Role.MemberType
                            }
                        }
                    }
                } 
                Catch 
                {
                    Write-Error $_.Exception.Message
                }
            }
        }
    }
 
    END 
    {
    
    }
}
#endregion
Function Enable-PIMPowerShell
{
    [CmdletBinding()]
    Param()


    $Connection = Connect-AzureAD

    Do
    {
        #region Gather current roles for account.  

        # We want this to run each time because we may activate one or more roles each time we loop.

        # This function will return all the PIM roles the "connected" Identity has access to.
        $AccountRoles = Get-PIMRoleAssignmentByUserPrincipalName -UserPrincipalName $Connection.Account


        $EligibleRoles = New-Object System.Collections.ArrayList
        $EligibleRoles.AddRange(($AccountRoles | Where-Object {$_.PIMAssignment -eq 'Eligible'}) -As [System.Management.Automation.PSObject[]])

        $ActiveRolesGuidArray = $AccountRoles | Where-Object {$_.PIMAssignment -eq 'Active'} | Select-Object -ExpandProperty AzureADRoleGuid
        #endregion


        Clear-Host
        Write-Host $MsgTable.WhichRole

        
        If(
            $MyInvocation.BoundParameters.ContainsKey("Debug") -or
            $DebugPreference -ne [System.Management.Automation.ActionPreference]::SilentlyContinue
        )
        {
            Write-Host ''
            Write-Host '******* START DEBUG *******' -BackgroundColor Red
            $EligibleRoles | Format-Table
            Write-Host '******* END DEBUG *******' -BackgroundColor Red
            Write-Host ''
        }
        For($i=0; $i -lt $EligibleRoles.Count; $i++)
        {
            $CurrentlyActive = [String]::Empty
            If($EligibleRoles[$i].AzureADRoleGuid -in $ActiveRolesGuidArray)
            {
                $CurrentlyActive = $MsgTable.CurrentlyActive
            }
            Write-Host (' {0,2} - {1} {2}' -f ($i + 1).ToString('D1'), $EligibleRoles[$i].AzureADRole, $CurrentlyActive)
            
        }

        Write-Host $MsgTable.Refresh
        $Choice = Read-Host -Prompt $MsgTable.Choice

        If($Choice -eq 'Q' -or $Choice -eq 'q')
        {
            Break
        }

        If($Choice -eq 'R' -or $Choice -eq 'r')
        {
            Continue
        }

        If($Choice -match '([\d],?)+')
        {
            ForEach($Option in $Choice.Split(','))
            {
                # This is to deal with an issue where the menu was expecting '09' instead of simply '9'.  I think it is likely due to
                # some weird issue with automatic string to number casting which caused the comparison. 
                # in the If statement below to incorrectly process the -gt and -le evaluations .
                # After adding this explicit conversion the issue has been fixed. 
                # (Note: All Read-Host data is returned as a string.).
                $OptionToInt = $Option.ToInt16([CultureInfo]::InvariantCulture)
                If(-not [String]::IsNullOrEmpty($Option) -and $OptionToInt -gt 0 -and $OptionToInt -le $EligibleRoles.Count)
                {
                    $Splat = @{
                        ProviderId = 'aadRoles'
                        ResourceId = $Connection.TenantId
                        RoleDefinitionId = $EligibleRoles[$OptionToInt - 1].AzureADRoleGuid
                        SubjectId = (Get-AzureADUser -ObjectId $Connection.Account.Id).ObjectId
                        Type = 'userAdd'
                        AssignmentState = 'Active'
                        Schedule = ''
                        Reason = 'Script Activated - Daily Tasks'
                    }

                    # Note: I haven't been able to figure out how to pull back the default time windows for
                    # the various roles.  We use four different allowed time windows for roles at ECCC.  So the
                    # code will iterate over the time windows from largest to smallest and when it has a success
                    # it ends the loop early.
                    ForEach($HoursOffset in @(8,4,2,1))
                    {
                        Try
                        {
                            $Splat['Schedule'] = New-PimSchedule -HoursOffset $HoursOffset
                            $Result = Open-AzureADMSPrivilegedRoleAssignmentRequest @Splat
                            If($Result -is [Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRoleAssignmentRequestRequest])
                            {
                                Write-Host ($MsgTable.HoursActivated -f $EligibleRoles[$OptionToInt - 1].AzureADRole, $HoursOffset) -BackgroundColor DarkGreen
                                Break
                            }
                        }
                        Catch
                        {
                            If($_.Exception.ErrorContent.Code -eq 'RoleAssignmentRequestPolicyValidationFailed' -and 
                            $_.Exception.ErrorContent.Message -match 'ExpirationRule')
                            {
                                # This specific error is because we requested too large of a time window for the given role.
                                # Get to the next iteration so we can try the next smaller window.
                                Continue
                            }
                        }
                    }

                    If($?)
                    {
                        Write-Host $MsgTable.ActivationSuccess -ForegroundColor Green
                    } 
                    Else 
                    {
                        Write-Host $MsgTable.ActivationFail -ForegroundColor Red
                    }
                }
                Else
                {
                    Write-Host ($MsgTable.OptionNotInChoices01 -f $OptionToInt) -BackgroundColor Red
                    #Continue
                    Read-Host -Prompt $MsgTable.OptionNotInChoices02
                }
            }
            Read-Host -Prompt $MsgTable.EnterToContinue
        }
    }
    While($true)

}

Export-ModuleMember -Function Enable-PIMPowerShell