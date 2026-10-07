Describe "Logger" {
    BeforeAll {
        $moduleRoot = Join-Path $TestDrive "repo/build/scripts"
        New-Item -ItemType Directory -Path $moduleRoot -Force | Out-Null
        Copy-Item "$PSScriptRoot/../Logger.psm1" $moduleRoot
        Import-Module (Join-Path $moduleRoot "Logger.psm1") -Force
        $originalInetRoot = $env:INETROOT
    }

    AfterAll {
        $env:INETROOT = $originalInetRoot
        Remove-Module Logger
    }

    It "uses the repository Logs folder when INETROOT is unset" {
        $env:INETROOT = $null

        Write-Log "Repository log"

        Get-Content (Join-Path $TestDrive "repo/Logs/verbose.log") | Should -Match "Repository log"
    }

    It "preserves INETROOT when it is set" {
        $env:INETROOT = Join-Path $TestDrive "enlistment"

        Write-Log "Enlistment log"

        Get-Content (Join-Path $env:INETROOT "Logs/verbose.log") | Should -Match "Enlistment log"
    }

    It "honors an explicit log folder and writes every pipeline message" {
        $folder = Join-Path $TestDrive "explicit"

        "First message", "Second message" | Write-Log -LogFolder $folder

        $lines = @(Get-Content (Join-Path $folder "verbose.log"))
        $lines.Count | Should -Be 2
        $lines[0] | Should -Match "First message"
        $lines[1] | Should -Match "Second message"
    }
}
