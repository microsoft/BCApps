Describe "BuildInitialize" {
    It "spreads load across a 10 minute window for test projects" {
        $script:delaySeconds = $null
        Mock Get-Random { 321 } -ParameterFilter { $Minimum -eq 0 -and $Maximum -eq 601 }
        Mock Start-Sleep { $script:delaySeconds = $Seconds } -ParameterFilter { $Seconds -eq 321 }

        . (Join-Path $PSScriptRoot "..\BuildInitialize.ps1")

        Should -Invoke Get-Random -Exactly 1
        Should -Invoke Start-Sleep -Exactly 1
        $script:delaySeconds | Should -Be 321
    }
}
