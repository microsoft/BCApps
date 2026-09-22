---
description: "How to get a Business Central container you can drive from a browser, for UI and exploratory testing."
---

# Business Central test environment (browser-drivable)

> **Scope.** This file covers only what you need *beyond* the standard dev-environment setup:
> reaching and driving the product through a browser. For creating the container itself, use
> [`LOCAL_DEV_ENV.md`](../../../LOCAL_DEV_ENV.md) — do not invent a parallel recipe.

## 1. Create the container with the repo's own script

```powershell
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Test' -SkipVsCodeSetup
```

**Use this rather than calling `New-BcContainer` directly.** It resolves the artifact through
`Get-CurrentBCArtifactUrl`, which derives the version from `repoVersion` in
`.github/AL-Go-Settings.json`, so **the container matches your checkout**. That matters enormously
for testing: a container that doesn't match the source produces findings you cannot trace back to
code, and "is this a real bug?" becomes unanswerable.

It also handles artifact-account selection for you:

| Branch | Storage account order |
| --- | --- |
| `main` | `bcinsider` only |
| release branches | `bcartifacts`, falling back to `bcinsider` |

External contributors without insider access are therefore served from the public account
automatically. **Never hard-code `-storageAccount bcinsider`** — it fails for anyone outside the
insider program.

`-SkipVsCodeSetup` is appropriate when you only want a running product to test against, not an AL
authoring environment.

> **For a tours session, call `Create-BCContainer` from `NewDevEnv.psm1` instead of running
> `NewDevEnv.ps1`** — the script prompts for a password and cannot run unattended. See §3. Everything
> above still applies: it is the same wrapper, with the same artifact resolution.

## 2. Find the web client URL

`NewDevEnv.ps1` sets up VS Code, not a browser session, so it does not surface the URL prominently.
Recover it with:

```powershell
docker logs <ContainerName> | Select-String 'Web Client'
```

Two things decide the URL shape:

- **Tenancy.** A multitenant container needs `?tenant=default`; a single-tenant one does not.
  `NewDevEnv.ps1` does not pass `-multitenant`, so expect `http://<ContainerName>/BC/`.
  Check rather than assume — an unexpected or missing `?tenant=` is a common cause of a blank page.
- **Host resolution.** BcContainerHelper's `-updateHosts` writes the container name into the host
  `hosts` file — but **the repo's `Create-BCContainer` does not pass it**, so no entry is written.
  Resolution may still work by mDNS/LLMNR, which is fragile and machine-dependent. Verify it, and
  fall back to the container IP if it fails:

  ```powershell
  Resolve-DnsName <ContainerName> | Select-Object Name, IPAddress
  Get-BcContainerIpAddress -containerName <ContainerName>
  ```

  Whatever resolves, use that same base URL everywhere — the browser, Playwright's `BASE`, and any
  health check — so a resolution problem cannot masquerade as a product failure.

Verify the client is actually serving before automating against it:

```powershell
(Invoke-WebRequest "http://<ContainerName>/BC/" -UseBasicParsing -TimeoutSec 60).StatusCode  # expect 200
```

## 3. Credentials

Authentication is `UserPassword` (user `admin`). `NewDevEnv.ps1` calls `Get-Credential`, which
**prompts interactively** — unsuitable for a tours session, where setup should run unattended.

**Do not prompt the user for a password.** Generate a random one instead, and drive the repo's own
`Create-BCContainer` wrapper from `NewDevEnv.psm1` directly. That is the same code path
`NewDevEnv.ps1` uses — artifact resolution via `Get-CurrentBCArtifactUrl` still applies, so the
container still matches the checkout — just without the prompt:

```powershell
Import-Module "$baseFolder\build\scripts\EnlistmentHelperFunctions.psm1" -DisableNameChecking
Import-Module "$baseFolder\build\scripts\DevEnv\NewDevEnv.psm1" -DisableNameChecking
Import-Module BcContainerHelper

$alphabet = [char[]]((48..57) + (65..90) + (97..122))
$password = (-join (1..20 | ForEach-Object { $alphabet | Get-Random })) + 'Aa1!'   # ensure complexity
$credential = New-Object System.Management.Automation.PSCredential(
    'admin', (ConvertTo-SecureString $password -AsPlainText -Force))

Create-BCContainer -ContainerName $ContainerName -Authentication 'UserPassword' -Credential $credential
```

### The generated password must be persisted — do not discard it

A random password that only exists inside the script is a dead end. **The user will need it** to
sign in to the web client and inspect state after an automated run — which is exactly how a finding
gets confirmed or dismissed.

Write it somewhere durable and outside the repository, and tell the user the path and the container
name:

```powershell
@{ containerName = $ContainerName; user = 'admin'; password = $password } |
    ConvertTo-Json | Set-Content "$sessionArtifactsFolder\bc-credentials.json" -Encoding utf8
```

Rules:

- **Never commit a password, and never hard-code one in a test script.** The credentials file lives
  in the session artifacts folder, not in the repo, and is never staged.
- Record it in the session sheet's environment table **by reference** (path + container name), never
  the value itself.
- Scripts read it at run time from the environment:

  ```powershell
  $creds = Get-Content "$sessionArtifactsFolder\bc-credentials.json" | ConvertFrom-Json
  $env:BC_USER = $creds.user
  $env:BC_PASS = $creds.password
  ```

- The password belongs to a disposable container that is destroyed at the end of the session (§7),
  so its blast radius is one local container — but it is still a credential; treat it as one.

## 4. First run is slow — do not mistake this for a failure

The first sign-in against a freshly created container triggers server-side compilation and can take
**60 seconds or more** before the web client is usable. Automation with a 20–30 s timeout will fail
on the first run and pass on every run after.

Warm the container up with one manual sign-in before running any automated scenario, and give the
first navigation in a script a generous timeout. A cold-start timeout that looks like a product bug
is the most common false positive in this setup.

## 5. Record the exact build in every test artifact

```powershell
Get-BcContainerNavVersion -containerOrImageName <ContainerName>   # e.g. 30.0.54921.0-W1
```

`main` publishes **daily** insider builds. Without the exact build number recorded, a finding cannot
be distinguished from a transient broken daily. Pin it in every session sheet and bug report.

## 6. Optional: test toolkit

`NewDevEnv.ps1` does not install the AL test toolkit. Add `-includeTestToolkit` to `New-BcContainer`
only if you intend to run AL tests; it is unnecessary for browser-driven exploratory testing and
slows container creation.

## 7. Clean-up

```powershell
Remove-BcContainer -containerName <ContainerName>
```

Exploratory testing is destructive by nature — posting a document cannot be undone. Prefer a
disposable container per session over trying to restore demo data, and never point exploratory work
at a container someone else is developing against.
