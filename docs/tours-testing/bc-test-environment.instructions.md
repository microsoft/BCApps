---
description: "How to get a Business Central container you can drive from a browser, for UI and exploratory testing."
---

# Business Central test environment

> **Scope.** Only what you need *beyond* the standard dev-environment setup. For creating a
> container generally, use [`LOCAL_DEV_ENV.md`](../../LOCAL_DEV_ENV.md) — do not invent a
> parallel recipe.

For a tours session, run [`harness/New-TourContainer.ps1`](./harness/README.md). This file explains
what it does and why.

## 1. Create the container from the repo's own script

```powershell
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Test' -SkipVsCodeSetup
```

**Use this rather than `New-BcContainer` directly.** It resolves the artifact through
`Get-CurrentBCArtifactUrl`, which derives the version from `repoVersion` in
`.github/AL-Go-Settings.json`, so **the container matches your checkout**. A container that does not
match the source produces findings you cannot trace back to code, and "is this a real bug?" becomes
unanswerable.

It also picks the storage account: `bcinsider` on `main`, `bcartifacts` falling back to `bcinsider`
on release branches. **Never hard-code `-storageAccount bcinsider`** — it fails for anyone outside
the insider program.

`-SkipVsCodeSetup` is right when you want a running product, not an AL authoring environment.

## 2. Run it unattended — never prompt for a password

`NewDevEnv.ps1` calls `Get-Credential`, which prompts. For a tours session, call the same
`Create-BCContainer` wrapper directly with a generated password. Artifact resolution still applies:

```powershell
Import-Module "$baseFolder\build\scripts\EnlistmentHelperFunctions.psm1" -DisableNameChecking
Import-Module "$baseFolder\build\scripts\DevEnv\NewDevEnv.psm1" -DisableNameChecking
Import-Module BcContainerHelper

$alphabet = [char[]]((48..57) + (65..90) + (97..122))
$password = (-join (1..20 | ForEach-Object { $alphabet | Get-Random })) + 'Aa1!'
$credential = New-Object System.Management.Automation.PSCredential(
    'admin', (ConvertTo-SecureString $password -AsPlainText -Force))

Create-BCContainer -ContainerName $ContainerName -Authentication 'UserPassword' -Credential $credential
```

### The generated password must be persisted

A password that only exists inside the script is a dead end — the user needs it to sign in and
inspect state after an automated run, which is exactly how a finding gets confirmed or dismissed.
Write it outside the repository, **named after the container**, and tell the user the path:

```powershell
$SecretPath = Join-Path $env:USERPROFILE ".bc-tours\$ContainerName-credentials.json"
@{ containerName = $ContainerName; user = 'admin'; password = $password } |
    ConvertTo-Json | Set-Content -Path $SecretPath -Encoding utf8
```

One file per container is what makes parallel tours safe: the harness takes `BC_CREDS`, and the
`containerName` inside the file determines which web client it signs in to and which container the
SQL oracle snapshots. See the harness README.

- **Never commit a password or hard-code one in a test script.**
- Record it in the session sheet **by reference** (path + container name), never the value.
- Scripts read it at run time; `bc.js` reads `$env:BC_CREDS` and refuses to start without it.
- The blast radius is one disposable local container — but it is still a credential.

## 3. Find the web client URL

```powershell
docker logs <ContainerName> | Select-String 'Web Client'
```

Two things decide its shape:

- **Tenancy.** `NewDevEnv.ps1` does not pass `-multitenant`, so expect `http://<ContainerName>/BC/`
  with no `?tenant=`. Check rather than assume — an unexpected or missing `?tenant=` is a common
  cause of a blank page.
- **Host resolution.** BcContainerHelper's `-updateHosts` writes the container name into the hosts
  file, but the repo's `Create-BCContainer` **does not pass it**. Resolution may still work by
  mDNS/LLMNR, which is fragile and machine-dependent:

  ```powershell
  Resolve-DnsName <ContainerName> | Select-Object Name, IPAddress
  Get-BcContainerIpAddress -containerName <ContainerName>
  ```

Use whatever resolves as the base URL **everywhere** — browser, Playwright `BASE`, health checks —
so a resolution problem cannot masquerade as a product failure. Verify before automating:

```powershell
(Invoke-WebRequest "http://<ContainerName>/BC/" -UseBasicParsing -TimeoutSec 60).StatusCode  # 200
```

## 4. The first run is slow — this is not a failure

The first sign-in triggers server-side compilation and can take **60 seconds or more**. Automation
with a 20–30 s timeout fails on the first run and passes on every run after. **Warm the container up
with one manual sign-in** before running anything automated, and give the first navigation a
generous timeout. A cold-start timeout mistaken for a product bug is the most common false positive
in this setup.

## 5. Record the exact build in every artifact

```powershell
Get-BcContainerNavVersion -containerOrImageName <ContainerName>   # e.g. 30.0.54921.0-W1
```

`main` publishes **daily** insider builds. Without the build number, a finding cannot be
distinguished from a transient broken daily.

## 6. Optional: test toolkit

`NewDevEnv.ps1` does not install the AL test toolkit. Add `-includeTestToolkit` only if you intend
to run AL tests; it is unnecessary for browser-driven exploratory testing and slows creation.

## 7. Clean-up

```powershell
Remove-BcContainer -containerName <ContainerName>
Remove-Item (Join-Path $env:USERPROFILE ".bc-tours\<ContainerName>-credentials.json")
```

Exploratory testing is destructive — posting cannot be undone. Prefer a disposable container per
session over restoring demo data, and never point exploratory work at a container someone else is
developing against.
