function Format-DNSRecordOutput {
    <#
    .SYNOPSIS
        Internal helper function to format DNS record output consistently.

    .DESCRIPTION
        Formats DNS record data into a consistent structure for output.

    .PARAMETER Record
        The DNS record object from Microsoft Graph.

    .PARAMETER DomainName
        The domain name associated with the record.

    .OUTPUTS
        PSCustomObject - Formatted DNS record information.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Record,

        [Parameter(Mandatory = $true)]
        [string]$DomainName
    )

    try {
        $recordType = $Record.AdditionalProperties['recordType']

        $formattedRecord = [PSCustomObject]@{
            Domain = $DomainName
            RecordType = $recordType
            Label = $Record.Label
            TTL = $Record.Ttl
        }

        # Add type-specific properties
        switch ($recordType) {
            'MX' {
                $formattedRecord | Add-Member -MemberType NoteProperty -Name 'MailExchange' -Value $Record.AdditionalProperties['mailExchange']
                $formattedRecord | Add-Member -MemberType NoteProperty -Name 'Preference' -Value $Record.AdditionalProperties['preference']
            }
            'CName' {
                $formattedRecord | Add-Member -MemberType NoteProperty -Name 'CanonicalName' -Value $Record.AdditionalProperties['canonicalName']
            }
            'Txt' {
                $formattedRecord | Add-Member -MemberType NoteProperty -Name 'Text' -Value $Record.AdditionalProperties['text']
            }
            'Srv' {
                $formattedRecord | Add-Member -MemberType NoteProperty -Name 'NameTarget' -Value $Record.AdditionalProperties['nameTarget']
                $formattedRecord | Add-Member -MemberType NoteProperty -Name 'Port' -Value $Record.AdditionalProperties['port']
                $formattedRecord | Add-Member -MemberType NoteProperty -Name 'Priority' -Value $Record.AdditionalProperties['priority']
                $formattedRecord | Add-Member -MemberType NoteProperty -Name 'Protocol' -Value $Record.AdditionalProperties['protocol']
                $formattedRecord | Add-Member -MemberType NoteProperty -Name 'Service' -Value $Record.AdditionalProperties['service']
                $formattedRecord | Add-Member -MemberType NoteProperty -Name 'Weight' -Value $Record.AdditionalProperties['weight']
            }
        }

        return $formattedRecord
    }
    catch {
        Write-Warning "Failed to format DNS record: $_"
        return $null
    }
}
