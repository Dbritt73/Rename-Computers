<#
.Synopsis
    Rename computers to match the standardized naming convention decided upon

.DESCRIPTION
    Rename-Computers.ps1 is a script that ingests a pre filled CSV file template with one column containing the current
    names of the computers you would like to change and the other column containing the desired new name for the system. Old
    name and new name must be in the same row of the spreadsheet.

    Able to target single computer with -ComputerName and -NewName parameter calls

.EXAMPLE
    Rename-computers.ps1 -CSVPath C:\Computers.csv -Domaincreds (Get-Credential) -localadmincreds (Get-Credential)

    Example showing use with CSV file

.EXAMPLE
    Rename-computers.ps1 -ComputerName 'SERVER01' -NewName 'SERVER02' -Domaincreds (Get-Credential) -localadmincreds (Get-Credential)

    Example showing use when targeting single computer

.NOTES
    *Script written to change domained computer names en mass
    *DomainCreds to change AD object name and local admin creds not the same in original use case
        *would like to change the double prompt

#>

[cmdletbinding()]
param (

    [System.Management.Automation.Credential()][Pscredential]$DomainCreds = (Get-Credential -Message 'This prompt is for your DOMAIN\Username account, needed to rename the computer in the Managed OU of AD'),

    [System.Management.Automation.Credential()][Pscredential]$LocalAdminCreds = (Get-Credential -Message 'This prompt is for your LOCAL\Admin account, Can be domain or local user to target, just needs to be in admin group'),

    [String]$Log = "$ENV:WINDIR\Temp\Rename-Computers.log",

    [String]$CSVPath = "$env:HOMEDRIVE\Rename-Computer.csv",

    [String]$ComputerName,

    [String]$NewName

)

Begin {}

Process {
    
    if (! $PSBoundParameters.ContainsKey('ComputerName')) {

        Import-Csv -Path $CSVPath | Foreach-object {
            
            Try {
    
                $params = @{
    
                    'ComputerName' = $_.Oldname;
                    'NewName' = $_.Newname;
                    'DomainCredential' = $DomainCreds;
                    'LocalCredential' = $LocalAdminCreds;
                    'Restart' = $true;
                    'Force' = $true;
                    'ErrorAction' = 'Stop';
                    'Verbose' = $true;
                    'PassThru' = $true
    
                }
    
                Write-Verbose -Message "$(Get-Date) : Renaming $($_.Oldname) to $($_.Newname)" 4>> $Log
                $CurrentComp = $_.Oldname
    
                Rename-Computer @params | out-file -FilePath $Log -Append
    
            } Catch {

                # get error record
                [Management.Automation.ErrorRecord]$e = $_

                # retrieve information about runtime error
                $info = [PSCustomObject]@{

                    Date         = (Get-Date)
                    ComputerName = $CurrentComp
                    Exception    = $e.Exception.Message
                    Reason       = $e.CategoryInfo.Reason
                    Target       = $e.CategoryInfo.TargetName
                    Script       = $e.InvocationInfo.ScriptName
                    Line         = $e.InvocationInfo.ScriptLineNumber
                    Column       = $e.InvocationInfo.OffsetInLine

                }
                
                # output information. Post-process collected info, and log info (optional)
                $info | Out-file -Path $Log

            }
    
        }
    
    } Else {
    
        Try {
    
            $params = @{
    
                'ComputerName' = $ComputerName;
                'NewName' = $Newname;
                'DomainCredential' = $DomainCreds;
                'LocalCredential' = $LocalAdminCreds;
                'Restart' = $true;
                'Force' = $true;
                'ErrorAction' = 'Stop';
                'Verbose' = $true;
                'PassThru' = $true
    
            }
    
            Rename-Computer @params | Out-File -FilePath $Log -Append
    
        } Catch {
    
                #Write-Output "$(Get-Date) : Couldn't Rename $($currentcomp) : $($Error[0].Exception)" 1>> $Log
                # get error record
                [Management.Automation.ErrorRecord]$e = $_
    
                # retrieve information about runtime error
                $info = [PSCustomObject]@{
    
                Date         = (Get-Date)
                ComputerName = $ComputerName
                Exception    = $e.Exception.Message
                Reason       = $e.CategoryInfo.Reason
                Target       = $e.CategoryInfo.TargetName
                Script       = $e.InvocationInfo.ScriptName
                Line         = $e.InvocationInfo.ScriptLineNumber
                Column       = $e.InvocationInfo.OffsetInLine
    
            }
            
            # output information. Post-process collected info, and log info (optional)
            $info | out-file $Log
    
        }
    
    }

}

End {}