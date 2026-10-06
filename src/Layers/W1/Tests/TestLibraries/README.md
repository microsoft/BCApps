# Microsoft API test authentication: web service key prototype

**Draft experiment, not ready for production or merge.** The public enum,
interface, authentication context, Graph entry points and final request event
are unchanged. `None` remains the default. Windows and SaaS retain ambient
authentication. Other modes fail explicitly; only OnPrem `NavUserPassword`
uses a web service key as the Basic password, with the current `UserId()`.

The provider no longer reads `ApiTestPassword`, Key Vault, or the private mock
secret provider. Existing pipeline credential materialization and cleanup are
deliberately unchanged until real HTTP proofs succeed.

## Credential lifecycle

- Use public `Identity Management.GetWebServicesKey` and
  `GetWebServiceExpiryDate`, with no direct DotNet calls in the provider.
  Each getter substitutes a value on failure (error text or the current time).
  Clear AL's last-error state immediately before each call and reject nonempty
  `GetLastErrorText()` immediately afterwards, before returning credentials.
  Never match localized failure phrases or infer the key's format.
- Reuse a valid existing key, including an existing non-expiring key. Do not
  rotate it, extend its expiry, cache it globally, or clear it after a request.
- Reject retrieval failures and expired keys explicitly. A failure is never
  interpreted as absence and never falls back to a password file.
- For an actually missing key, lock the current user record and re-read before
  calling `Identity Management.CreateWebServicesKey`. New keys expire after
  24 hours of real time, independent of `WorkDate`.
- No explicit commit and no elevated permissions. Restricted callers must
  have the platform permissions required to read/provision their own key.
  Raw text exists only at the legacy API boundary, in non-debuggable code.

The first-use user-row lock is intended to serialize **this provider's**
provisioning in a tenant; it is not an inter-tenant lock or protection against
external administrators deliberately rotating a key. Its interaction with
platform credential storage/cache and authentication must still be verified.
Cloned tenants have separate credential state and are not a global cache.
The two public getters are not an atomic key/expiry snapshot. External key
rotation between these reads is not coordinated by the provider's user-row
lock; do not claim that the lock protects against administrative rotation.

## Disposable CI proofs

`Tests-Misc` codeunit **139497 Web Service Key Auth Tests** publishes a temporary
SOAP probe (139498), creates a unique user with a randomly generated bootstrap
password and test permissions, and invokes the probe as that user. The probe
exercises the provider exclusively through public Graph APIs. It never reads or
rotates the CI runner's or a human user's key. Each test deletes its owned user,
permission assignment and service before asserting the captured HTTP result,
including SOAP-fault/transport-failure paths. Container disposal is the final
cleanup boundary if setup or cleanup itself fails.

Run only in dedicated disposable OnPrem CI containers with SOAP/OData enabled.
Compile and publish **both Tests-TestLibraries and Tests-Misc** before running
the entire codeunit. Do not run on a shared NST. Use TLS outside an isolated
container/loopback environment: Basic credentials are otherwise exposed.

The seven HTTP tests assert:

1. Unauthenticated 401 becomes 200; a newly created key has a 24-hour expiry and
   is immediately usable by a different HTTP session.
2. Repeated requests on one Graph instance retain the key and return 200.
3. A second Graph instance does not rotate the key or invalidate the first.
4. An existing expiring key and its original expiry are preserved.
5. An expired key yields the explicit provider error.
6. A forced SOAP error rolls back a business-data marker inserted before key
   creation, detecting an implicit platform commit.
7. Selecting `None` restores 401 after a successful authenticated request.

Two additional behavioral tests call the public key and expiry getters with
separate nonexistent user IDs after `ClearLastError()`, then require a nonempty
`GetLastErrorText()`. They neither inspect failure text nor create credentials.
These tests must prove the platform failure signal before the public-wrapper
approach is accepted; a false result with empty last-error state blocks this
design rather than justifying format heuristics. They do not substitute for
restricted-current-user permission-failure tests.

Existing codeunit 139494 continues to cover the default provider, instance
lifetime, and final-event ordering. The 117 existing credential-pipeline and
parallel-execution Pester tests provide regression coverage for the unchanged
harness. They do not test this AL provider's authentication behavior. No
source-pattern tests are added; Windows/SaaS guards and restricted-user
retrieval failures still require behavioral validation.

**Outstanding acceptance gates:** compiled/published CI execution and artifacts;
fresh last-error signaling for both public getters; platform semantics for
absent/expired keys; immediate cross-session visibility;
rollback and lock behavior; simultaneous first use in separate sessions;
restricted-user retrieval/creation errors; Windows/SaaS runtime guards.
If creating a key requires committing the caller's transaction or cannot
serialize safely, do not add a hidden commit or silently rotate keys: block
this design and move provisioning to an explicit disposable-environment setup
step instead. This PR does not change SQL stabilization or API-test selection.

Reference: [Web services authentication](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/webservices/web-services-authentication).
Web service key Basic authentication is an OnPrem option, not a Business
Central Online authentication solution.
