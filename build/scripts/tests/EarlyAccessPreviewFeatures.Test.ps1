Describe 'Early Access Preview feature catalog' {
    BeforeAll {
        $RepositoryRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path
        $script:CatalogPath = Join-Path $RepositoryRoot 'src\System Application\App\Resources\Files\EarlyAccessPreviewFeatures.json'
        $script:ConsumerPath = Join-Path $RepositoryRoot 'src\System Application\App\Guided Experience\src\Early Access Preview\EarlyAccessPreviewMgt.Codeunit.al'
        $script:LegacyEntry = '{"FeatureName":"Example","Description":"Try the feature.","Category":"Administration","HelpURL":"","VideoURL":""}'
        $TextLimits = @{
            FeatureName = 2048
            Description = 1024
            Category = 250
            HelpURL = 250
            VideoURL = 250
        }

        function Assert-FeatureCatalog {
            param([string] $Json)

            $Catalog = ConvertFrom-Json -InputObject $Json -NoEnumerate -ErrorAction Stop
            if ($Catalog -isnot [array]) {
                throw 'The feature catalog must be a JSON array.'
            }

            $Titles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            foreach ($Feature in $Catalog) {
                if ($Feature -isnot [pscustomobject]) {
                    throw 'Each feature must be a JSON object.'
                }

                $PropertyNames = @($Feature.PSObject.Properties.Name)
                foreach ($Name in $TextLimits.Keys) {
                    if ($PropertyNames -cnotcontains $Name -or $Feature.$Name -isnot [string]) {
                        throw "$Name must be a string with the exact property name."
                    }
                    if ($Feature.$Name.Length -gt $TextLimits[$Name]) {
                        throw "$Name exceeds the AL consumer limit of $($TextLimits[$Name])."
                    }
                }
                foreach ($Name in 'FeatureName', 'Description', 'Category') {
                    if ([string]::IsNullOrWhiteSpace($Feature.$Name)) {
                        throw "$Name must not be blank."
                    }
                }
                foreach ($Name in $PropertyNames) {
                    if (@($TextLimits.Keys) + @('ADOSliceIds') -cnotcontains $Name) {
                        throw "Unexpected feature property: $Name."
                    }
                }
                if (-not $Titles.Add($Feature.FeatureName)) {
                    throw "Duplicate feature name: $($Feature.FeatureName)."
                }

                if ($PropertyNames -ccontains 'ADOSliceIds') {
                    if ($Feature.ADOSliceIds -isnot [array] -or $Feature.ADOSliceIds.Count -eq 0) {
                        throw 'ADOSliceIds must be a nonempty array.'
                    }
                    $Ids = [System.Collections.Generic.HashSet[long]]::new()
                    foreach ($Id in $Feature.ADOSliceIds) {
                        if (($Id -isnot [int] -and $Id -isnot [long]) -or $Id -le 0) {
                            throw 'ADOSliceIds must contain positive integers.'
                        }
                        if (-not $Ids.Add($Id)) {
                            throw 'ADOSliceIds must be unique within an entry.'
                        }
                    }
                }
            }
        }
    }

    It 'validates the shipped catalog' {
        { Assert-FeatureCatalog (Get-Content $CatalogPath -Raw) } | Should -Not -Throw
    }

    It 'accepts an empty catalog' {
        { Assert-FeatureCatalog '[]' } | Should -Not -Throw
    }

    It 'accepts a legacy entry without slice metadata' {
        { Assert-FeatureCatalog "[$LegacyEntry]" } | Should -Not -Throw
    }

    It 'accepts <Ids> as slice metadata' -ForEach @(
        @{ Ids = '[1]' }
        @{ Ids = '[1,2]' }
    ) {
        $Entry = $LegacyEntry.TrimEnd('}') + ',"ADOSliceIds":' + $Ids + '}'
        { Assert-FeatureCatalog "[$Entry]" } | Should -Not -Throw
    }

    It 'rejects invalid slice metadata <Ids>' -ForEach @(
        @{ Ids = '[]' }
        @{ Ids = 'null' }
        @{ Ids = '1' }
        @{ Ids = '{}' }
        @{ Ids = '[0]' }
        @{ Ids = '[-1]' }
        @{ Ids = '[1,1]' }
        @{ Ids = '[1.5]' }
        @{ Ids = '[1.0]' }
        @{ Ids = '["1"]' }
        @{ Ids = '[true]' }
        @{ Ids = '[null]' }
        @{ Ids = '[[1]]' }
    ) {
        $Entry = $LegacyEntry.TrimEnd('}') + ',"ADOSliceIds":' + $Ids + '}'
        { Assert-FeatureCatalog "[$Entry]" } | Should -Throw '*ADOSliceIds*'
    }

    It 'rejects duplicate feature names' {
        { Assert-FeatureCatalog "[$LegacyEntry,$LegacyEntry]" } | Should -Throw '*Duplicate feature name*'
    }

    It 'enforces the text limits used by the AL consumer' {
        foreach ($Name in $TextLimits.Keys) {
            $Entry = $LegacyEntry | ConvertFrom-Json
            $Entry.$Name = 'x' * $TextLimits[$Name]
            { Assert-FeatureCatalog "[$($Entry | ConvertTo-Json -Compress)]" } | Should -Not -Throw
            $Entry.$Name += 'x'
            { Assert-FeatureCatalog "[$($Entry | ConvertTo-Json -Compress)]" } | Should -Throw "*$Name exceeds*"
        }
    }

    It 'requires exact case for property names' {
        $Entry = $LegacyEntry.Replace('"FeatureName"', '"featureName"')
        { Assert-FeatureCatalog "[$Entry]" } | Should -Throw '*FeatureName*'
        $Entry = $LegacyEntry.TrimEnd('}') + ',"adoSliceIds":[1]}'
        { Assert-FeatureCatalog "[$Entry]" } | Should -Throw '*Unexpected feature property*'
    }

    It 'keeps the AL loader limited to the five display properties' {
        $Consumer = Get-Content $ConsumerPath -Raw
        $ReadProperties = [regex]::Matches($Consumer, "FeatureObject\.Get\('([^']+)'") |
            ForEach-Object { $_.Groups[1].Value }
        @($ReadProperties).Count | Should -Be 5
        foreach ($Name in $TextLimits.Keys) {
            $ReadProperties -ccontains $Name | Should -BeTrue
        }
        $Consumer | Should -Not -Match 'ADOSliceIds'
    }
}
