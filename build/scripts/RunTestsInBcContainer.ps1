Param(
    [Hashtable]$parameters
)

Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1

function Get-DisabledTests
{
    $baseFolder = Get-BaseFolder

    $disabledCodeunits = Get-ChildItem -Path $baseFolder -Filter "DisabledTests" -Recurse -Directory | ForEach-Object { Get-ChildItem -Path $_.FullName -Filter "*.json" }
    $disabledTests = @()
    foreach($disabledCodeunit in $disabledCodeunits)
    {
        $disabledTests += (Get-Content -Raw -Path $disabledCodeunit.FullName | ConvertFrom-Json)
    }

    return @($disabledTests)
}

$disabledTests = Get-DisabledTests

if ($disabledTests)
{
    $parameters["disabledTests"] = $disabledTests
}

if ($parameters["testRunnerCodeunitId"] -ne "138705")
{
    # The follwoing test codeunits need to run without test isolation
    $retentionPolicyTestCodeunits = @(
        @{
            "codeunitId" = "138700"
            "codeunitName" = "Retention Period Test"
        },
        @{
            "codeunitId" = "138701"
            "codeunitName" = "Reten. Policy Setup Test"
        },
        @{
            "codeunitId" = "138702"
            "codeunitName" = "Retention Policy Test"
        },
        @{
            "codeunitId" = "138703"
            "codeunitName" = "Reten. Pol. Allowed Tbl. Test"
        },
        @{
            "codeunitId" = "138705"
            "codeunitName" = "Retention Policy Log Test"
        }
    )

    $retentionPolicyTestCodeunits | ForEach-Object {
        # Manually disable the test codeunit
        $disabledTests += @{
            "codeunitId" = $_.codeunitId
            "codeunitName" = $_.codeunitName
            "method" = "*"
        }
    }
}

Write-Host "Disabled tests: $($disabledTests | ConvertTo-Json -Depth 100)"

Run-TestsInBcContainer @parameters
