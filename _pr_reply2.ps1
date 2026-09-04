$ErrorActionPreference = 'Stop'
$repo = 'microsoft/BCApps'; $pr = 11016
$mut = 'mutation($threadId: ID!) { resolveReviewThread(input: {threadId: $threadId}) { thread { isResolved } } }'

$b1 = 'Changed the rejected-endpoint telemetry to ``TelemetryScope::All`` so the tenant-actionable SII setup misconfiguration surfaces in the customer''s own environment telemetry, consistent with the SecurityAudit call in the same branch.'
gh api --method POST "repos/$repo/pulls/$pr/comments/3932124608/replies" -f body="$b1" | Out-Null
$r1 = gh api graphql -f query="$mut" -f threadId='PRRT_kwDOJh2Tgs6fNsaF' | ConvertFrom-Json
Write-Host "3932124608 resolved=$($r1.data.resolveReviewThread.thread.isResolved)"

$b2 = 'Our tests run OnPrem (neither PROD nor PPE), so the previous environment gate skipped the real validation. Fixed by decoupling environment detection from the validation logic: the connector now exposes ``IsDestinationUrlAllowed(Url, ExpectedHostSuffix)`` and ``GetValidatedTokenEndpointForAuthority(Endpoint, AuthorityPrefix)`` internal seams. The six tests pass the trusted host suffix / authority prefix directly and exercise the validation deterministically OnPrem; the environment gate and PROD/PPE-only helpers are removed.'
gh api --method POST "repos/$repo/pulls/$pr/comments/3932124820/replies" -f body="$b2" | Out-Null
$r2 = gh api graphql -f query="$mut" -f threadId='PRRT_kwDOJh2Tgs6fNscD' | ConvertFrom-Json
Write-Host "3932124820 resolved=$($r2.data.resolveReviewThread.thread.isResolved)"
