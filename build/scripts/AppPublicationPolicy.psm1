function Get-StandardAppPublicationExclusion {
    @('Library - No Transactions', 'Prevent Metadata Updates Library')
}

function Test-AppPublicationExcluded {
    param([string]$BaseName, [string[]]$ExclusionList)
    return (@($ExclusionList | Where-Object { $BaseName -like "Microsoft_$($_)_*" }).Count -gt 0)
}

Export-ModuleMember -Function Get-StandardAppPublicationExclusion, Test-AppPublicationExcluded
