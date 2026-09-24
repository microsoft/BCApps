<#
.SYNOPSIS
    Gate 0, before a container exists: prove a source change is present in a BC
    artifact by reading the shipped Base Application.

.DESCRIPTION
    A charter that tours a named commit is worthless if the build under test does
    not contain that commit — a null result then cannot be told apart from "no side
    effect". This answers the question from the artifact cache, so it costs a few
    minutes instead of a whole container cycle.

    It found, on its first outing, that the repo-pinned artifact 30.0.54812.0 predates
    commit f125305261 AND the pre-fix state that commit's diff shows: the entire
    stored-value branch was absent, so a tour there would have measured a third,
    older behaviour and attributed it to the commit.

    ⚠️ THE REPO PIN IS NOT A GUARANTEE. .github/AL-Go-Settings.json pins
    "artifact": "bcinsider/Sandbox/<version>//latest". Get-CurrentBCArtifactUrl returns
    that pin verbatim when it contains a four-part version, so it never consults
    repoVersion. The pinned artifact can therefore predate commits that are ancestors
    of the very checkout it claims to match. Never infer "the build has this commit"
    from "the container matches the checkout".

.NOTES
    ARTIFACT LAYOUT — the part that costs an hour and is invisible afterwards:

      * the `base` artifact holds ONLY  Demo Database BC (<v>).bak, Cronus.bclicense,
        Master.bclicense, EULA.html, manifest.json.  There is no application code in it.
      * `Microsoft_Base Application.app` lives in the **platform** artifact, at
            <cache>\sandbox\<version>\platform\Applications\BaseApp\Source\
        so Download-Artifacts needs  -includePlatform.
      * `Download-Artifacts` has NO -accept_insiderEula parameter. Only
        `Get-BCArtifactUrl` does. Passing it throws a parameter-binding error that
        reads like an auth failure.
      * a .app is a zip behind a 40-byte NAVX header, so Expand-Archive refuses it
        until the header is stripped; and the outer app contains a NESTED
        <guid>_<version>_<build>.app which is the real package holding src\.
      * unpacking the outer app emits several
        "Can not process invalid archive entry 'publishedartifacts/file:///S:/...'"
        errors. They are HARMLESS - those are build-server path artefacts. The nested
        .app extracts fine. Do not chase them.

    ⚠️ @() IS LOAD-BEARING ON EVERY PIPELINE YOU INDEX.
    Three separate confident-but-wrong answers were produced in one session by
    omitting it, because indexing a single *string* returns its first CHARACTER:
        ($names | Sort-Object Length)[0]      -> 'C'   (read as a bad table name)
        (Download-Artifacts ...)[0]           -> 'c'   (read as a bad path)
    None of them errored. All three looked like data. Wrap it, always:
        @($pipeline)[0]

.EXAMPLE
    # Is the change in the latest insider build?
    .\Test-FixInArtifact.ps1 -Pattern '"Source Currency Code" <> '''''

.EXAMPLE
    # Exact artifact, exact object, and also show what the UNFIXED twins look like.
    .\Test-FixInArtifact.ps1 `
        -ArtifactUrl 'https://bcinsider-xxxx.b02.azurefd.net/sandbox/30.0.55076.0/base' `
        -ObjectFile  'GenJnlPostLine.Codeunit.al' `
        -Pattern     '"System-Created Entry" and \(GenJnlLine\."Source Currency Code" <> ''''\)' `
        -AlsoShow    '"Source Currency VAT Amount" := GenJnlLine\."Source Curr\. VAT Amount"'

.EXAMPLE
    # Walk backwards to find the FIRST build that contains the change.
    .\Test-FixInArtifact.ps1 -Version scan -MaxScan 10 `
        -ObjectFile 'GenJnlPostLine.Codeunit.al' -Pattern '"Source Currency Code" <> '''''
#>
[CmdletBinding()]
param(
    # An explicit artifact url. Prefer this over -Version once you know the build:
    # "latest" can move underneath a session, breaking the link between the build you
    # validated and the build you measured.
    [string] $ArtifactUrl,

    # 'latest'  - newest insider for -MajorVersion
    # 'scan'    - walk backwards from newest until the pattern is found
    # '30.0.55076.0' - that exact build
    [string] $Version = 'latest',

    [string] $MajorVersion   = '30.',
    [string] $Country        = 'base',
    [string] $StorageAccount = 'bcinsider',

    # How many builds -Version scan will try before giving up.
    [int] $MaxScan = 10,

    # The shipped source file to read. Leave blank to search every .al in the package.
    [string] $ObjectFile = 'GenJnlPostLine.Codeunit.al',

    # A .NET regex. PRESENT => the change is in this build.
    [Parameter(Mandatory)][string] $Pattern,

    # Which shipped .app to unpack. The Base Application is the default, but plenty of
    # charters tour the System Application, which is a DIFFERENT package in the same
    # platform artifact. Grepping the Base App for a System App change returns
    # "SOURCE NOT SHIPPED", which reads exactly like "the build is too old".
    [string] $AppNamePattern = '*Base Application*.app',

    # Write the matched shipped file here, so it can be diffed against <fix> and <fix>^.
    # A grep that finds nothing is only ever a negative result; a diff is a positive one.
    [string] $ExtractTo,

    # Optional second regex, printed with context. Use it to show that the sibling
    # sites a fix did NOT touch really are still un-narrowed IN THE SHIPPED BUILD -
    # which is the only version of an asymmetry claim worth anything.
    [string] $AlsoShow,

    [string] $WorkDir = (Join-Path $env:TEMP 'test-fix-in-artifact')
)

$ErrorActionPreference = 'Stop'
Import-Module BcContainerHelper -DisableNameChecking -WarningAction SilentlyContinue | Out-Null

function Expand-BcApp {
    <# a .app is a zip behind a 40-byte NAVX header; find PK\x03\x04 and cut. #>
    param([string] $AppFile, [string] $Destination)

    $bytes = [System.IO.File]::ReadAllBytes($AppFile)
    $zipStart = -1
    for ($i = 0; $i -lt [Math]::Min($bytes.Length, 4096) - 3; $i++) {
        if ($bytes[$i]   -eq 0x50 -and $bytes[$i+1] -eq 0x4B -and
            $bytes[$i+2] -eq 0x03 -and $bytes[$i+3] -eq 0x04) { $zipStart = $i; break }
    }
    if ($zipStart -lt 0) { throw "No zip header found in '$AppFile' - not a .app?" }

    $zipFile = "$AppFile.zip"
    [System.IO.File]::WriteAllBytes($zipFile, $bytes[$zipStart..($bytes.Length - 1)])
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    # -ErrorAction SilentlyContinue: the 'publishedartifacts/file:///S:/...' entries
    # are build-server path artefacts and always fail. See .NOTES.
    Expand-Archive -Path $zipFile -DestinationPath $Destination -Force -ErrorAction SilentlyContinue
}

function Get-BaseAppSource {
    <# artifact url -> folder holding the unpacked shipped src\ #>
    param([string] $Url, [string] $Work)

    Write-Host "  downloading artifact (disk only, no container)..." -ForegroundColor DarkGray
    # @() load-bearing: a single returned path would index to one character.
    $paths = @(Download-Artifacts -artifactUrl $Url -includePlatform)
    $platform = $paths | Where-Object { $_ -like '*\platform' } | Select-Object -First 1
    if (-not $platform) { $platform = $paths[-1] }

    $app = @(Get-ChildItem (Join-Path $platform 'Applications') -Recurse `
                -Filter $AppNamePattern -ErrorAction SilentlyContinue |
             Sort-Object Length -Descending)[0]
    if (-not $app) { throw "No '$AppNamePattern' under '$platform\Applications'. Did -includePlatform work?" }
    Write-Host "  app: $($app.Name) ($([math]::Round($app.Length/1MB,1)) MB)" -ForegroundColor DarkGray

    $stem  = Join-Path $Work ([guid]::NewGuid().ToString('N').Substring(0,8))
    $outer = Join-Path $stem 'outer'
    $inner = Join-Path $stem 'inner'
    New-Item -ItemType Directory -Force -Path $stem | Out-Null
    $local = Join-Path $stem 'BaseApp.app'
    Copy-Item $app.FullName $local -Force

    Expand-BcApp -AppFile $local -Destination $outer
    $nested = @(Get-ChildItem $outer -Recurse -Filter '*.app' | Sort-Object Length -Descending)[0]
    if ($nested) {
        Write-Host "  nested:   $($nested.Name)" -ForegroundColor DarkGray
        Expand-BcApp -AppFile $nested.FullName -Destination $inner
        return $inner
    }
    return $outer
}

function Test-OneArtifact {
    param([string] $Url)

    Write-Host "`n=== $Url ===" -ForegroundColor Cyan
    $src = Get-BaseAppSource -Url $Url -Work $WorkDir

    $files = if ($ObjectFile) {
        @(Get-ChildItem $src -Recurse -Filter $ObjectFile -ErrorAction SilentlyContinue)
    } else {
        @(Get-ChildItem $src -Recurse -Filter '*.al' -ErrorAction SilentlyContinue)
    }

    if ($files.Count -eq 0) {
        Write-Host "  SOURCE NOT SHIPPED for '$ObjectFile' - cannot decide from this package." -ForegroundColor Yellow
        return [pscustomobject]@{ Url = $Url; Found = $null; File = $null }
    }

    $found = $false
    foreach ($f in $files) {
        if ($ExtractTo) {
            New-Item -ItemType Directory -Force -Path $ExtractTo | Out-Null
            Copy-Item $f.FullName (Join-Path $ExtractTo $f.Name) -Force
        }
        $hits = @(Select-String -Path $f.FullName -Pattern $Pattern)
        if ($hits.Count) {
            $found = $true
            Write-Host "  PRESENT in $($f.Name) ($([math]::Round($f.Length/1KB,0)) KB)" -ForegroundColor Green
            $hits | Select-Object -First 5 | ForEach-Object {
                Write-Host ("    {0}: {1}" -f $_.LineNumber, $_.Line.Trim())
            }
        }
    }

    if (-not $found) {
        Write-Host "  ABSENT - this build does not contain the change." -ForegroundColor Red
        Write-Host "  Before concluding: is the PATTERN right? A regex against unpacked AL has" -ForegroundColor DarkYellow
        Write-Host "  many quiet ways to fail. Suspect the instrument before the build." -ForegroundColor DarkYellow
    }

    if ($AlsoShow) {
        Write-Host "  --- -AlsoShow (sites the change did NOT touch, in THIS build) ---" -ForegroundColor DarkCyan
        foreach ($f in $files) {
            Select-String -Path $f.FullName -Pattern $AlsoShow -Context 1,0 | ForEach-Object {
                $pre = if ($_.Context.PreContext) { $_.Context.PreContext[0].Trim() } else { '' }
                Write-Host ("    {0}: {1}  ||  {2}" -f $_.LineNumber, $pre, $_.Line.Trim())
            }
        }
    }

    [pscustomobject]@{ Url = $Url; Found = $found; File = $files[0].FullName }
}

New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null

# ---- which artifacts to test ------------------------------------------------
$urls = @()
if ($ArtifactUrl) {
    $urls = @($ArtifactUrl)
} else {
    $all = @(Get-BCArtifactUrl -type sandbox -country $Country -version $MajorVersion `
                -select All -storageAccount $StorageAccount -accept_insiderEula)
    if ($all.Count -eq 0) { throw "No artifacts found for version '$MajorVersion' on $StorageAccount." }

    switch ($Version) {
        'latest' { $urls = @($all[-1]) }
        'scan'   {
            $take = [Math]::Min($MaxScan, $all.Count)
            $urls = @($all[($all.Count - $take)..($all.Count - 1)])
            [array]::Reverse($urls)     # newest first
        }
        default  {
            $urls = @($all | Where-Object { $_ -like "*/$Version/*" })
            if ($urls.Count -eq 0) { throw "Artifact for version '$Version' not found." }
        }
    }
}

$results = @()
foreach ($u in $urls) {
    $r = Test-OneArtifact -Url $u
    $results += $r
    if ($r.Found) { break }   # scan stops at the first build that has it
}

Write-Host "`n================ VERDICT ================" -ForegroundColor Cyan
$hit = @($results | Where-Object { $_.Found })[0]
if ($hit) {
    Write-Host "Change IS present in: $($hit.Url)" -ForegroundColor Green
    Write-Host "Build a container with exactly this artifact - pass the URL explicitly," -ForegroundColor Green
    Write-Host "not 'latest', so the build you validated is the build you measure:" -ForegroundColor Green
    Write-Host "  .\New-TourContainer.ps1 -ContainerName <name> -ArtifactUrl '$($hit.Url)'"
    exit 0
} else {
    Write-Host "Change NOT present in any artifact tested." -ForegroundColor Red
    Write-Host "That is a legitimate result: the charter is not tourable on a published build." -ForegroundColor Red
    Write-Host "Do NOT interpret probe results from these builds as effects of the change." -ForegroundColor Red
    exit 1
}
