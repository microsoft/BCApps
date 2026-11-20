# IRIS schema configuration deployment

## Schema implementations

`XML Schema Version IRIS` dispatches to `IRIS XML Schema`, whose three operations
are `GetVersionText`, `ValidateTransmission` and `CreateTransmissionXmlContent`.
The `2.0.3` and `5.0.7` codeunits own their validation and XML differences; common
writers and document bookkeeping remain in `Generate Xml File IRIS`.

To add a built-in schema, add its implementation codeunit, enum binding and exact
wire-string parser entry in `Helper IRIS`, with focused validation/XML tests.
Keep new mandatory-field rules inside validation and generation rather than
adding field-specific interface methods. New schemas do not change endpoint
selection or require changes to the released partner interfaces.
An enum value without an implementation fails explicitly.

Supplemental MISC/NEC lines are available for single-calendar-year periods from
2026 onward. Their mappings and occupation codes use the requested tax year's
resource, falling back to the latest earlier resource when necessary. Future-year
XML generation still requires the existing unverified-year confirmation; allowing
supplemental lines does not certify future IRS schemas or business rules.

## Product and private-testing boundary

The shipping app uses the extensible **XML Schema Version IRIS** enum (10045):
empty/no override, `2.0.3` and `5.0.7`. Empty is valid period setup, not an
effective XML version. Extending the enum alone does not implement a new
Standard contract. The released five-method configuration interface and partner
status/acknowledgment dispatch remain available; no local runtime-provider,
signing-provider, simulation or transport framework is part of this feature.
All three ordinary SaaS-only send guards remain unchanged.

The temporary OnPrem ATS route is a separately built private source copy plus
an independent settings/signing app. Installing settings cannot enable the
shipping app. Its preparation, dependency order, operator upload and restoration
runbook is local-only at `BuildOutput\US\IRSForms\LocalATS\README.md`; it is not
a shipping dependency or customer deployment procedure.

The temporary UI is **PRIVATE TEST ONLY - IRS ATS** (page 50210), separate
from **IRS Forms Setup**. Select **2025** or **2026** to apply the already supplied
public defaults; Software IDs, TCCs, client/key IDs and URLs are ordinary fields.
Only the full User ID (entered on **Setup IRIS User ID**), certificate/private key,
password and OAuth material stay protected. Use **Upload Certificate** after year
selection. Its ephemeral RSA key is reused only in the unchanged local session;
changing year/configuration requires another upload. This private UX does not
change automatic tax-year selection or guards in the shipping integration.
The local runbook records the current source/package identities and operator-owned
manual-test status; do not infer IRS acceptance from compilation/publication.

## Preparation

Before deploying the schema-selection update, provision both
`IRS1099IRIS-XmlSchemaVersionTest` and `IRS1099IRIS-XmlSchemaVersionLive`, even
when production remains on `2.0.3`. Values must be the exact XML version
`2.0.3` or `5.0.7`, not processing-year labels or XSD-package versions.
An unavailable, empty or unsupported selected setting must stop new generation;
it must not silently downgrade or read a retired setting.

Provision `IRS1099IRIS-AuthURLTest` for sandbox authentication and
`IRS1099IRIS-AuthURLLive` for production authentication. OAuth token requests,
JWT audiences, and refresh requests use the selected environment's URL.
There is no fallback to the other environment or the old shared
`IRS1099IRIS-AuthURL` setting.

Provision an IRS-approved `IRS1099IRIS-SoftwareID-<tax year>` for every year
offered for filing, including earlier years using `2.0.3`. The ID must begin
with the year's final two digits. IRS approval for the specific year and forms
is an operational prerequisite; prefix validation alone does not establish it.
Do not substitute a newer or shared ID when a Standard year-specific value is
missing. The released yearless configuration method remains available to
extensions, whose returned ID must match the requested year.

Use the NAV repository's
`Eng\Core\Scripts\Sync-IRS1099IRISKeyVaultSecrets.md` SAW procedure. Review
retired settings explicitly and retain them while older deployed readers need
them. Do not copy credentials into source or diagnostic evidence.

## Period overrides and routing

Reporting periods have separate TEST and production enum overrides. Both start
empty. The default-hidden **IRIS XML Schema Version** field can be revealed
through personalization; it edits only the current environment's slot. Clearing
it restores that environment's configured default. Copying setup must leave a
new target's overrides empty and retain an existing target's overrides.
An unverified year is not a reason to reject override entry; generation requires
the separate mapping-reuse confirmation.

To reveal the control, choose **Settings > Personalize**, expand **More**, and
choose **Field**. Drag **IRIS XML Schema Version** from **Add Field to Page**
into the period columns, then choose **Done**. Use **Edit List** to select a
version or the empty option. There is only one override control, not an
environment selector.

Schema selection does not select destinations. Standard sandbox requests use
IRS TEST; Standard production requests use production. This also applies to
status and acknowledgment requests for older receipts or copied history.
History is diagnostic evidence, never authority to switch environments or retry
against the other service. Normal on-premises sending remains unsupported.

Standard sending captures the schema, source, requested year and year-matched
Software ID before its selection warnings and
preflight. Preflight and transmission XML share that operation-local context.
Authentication, submission, token-validity probes and acknowledgments select
their endpoints from the current BC environment. The environment does not switch
between sandbox and production during a send. Each token request or refresh
uses the same auth URL for its JWT audience and destination.
Partner-owned status XML still uses the selected implementation.
Direct XML generation captures its own context before mapping
confirmation. A missing year ID can therefore fail before the warning; edits
during a warning do not change that transmission's selected contract or Software ID.
The snapshot is not stored for reuse: a failed, cancelled or subsequent send
starts a new operation. Independent status and acknowledgment requests continue
to resolve their current-environment configuration.
History captures the actual XML schema, source,
test code, nonsecret Software ID and the BC environment
alongside the payload. The BC environment is diagnostic, not a stored destination.
Status and acknowledgment
generation retain the selected implementation's existing facade dispatch and do
not require resolving a new-filing schema for an old receipt.

Transmission History downloads the selected attempt's stored transmission,
response and acknowledgment streams, not newly generated XML. Changing schema
configuration or source documents must not change those downloaded bytes.
An HTTP receipt is not final IRS acceptance; inspect the acknowledgment and
record/submission errors before deciding whether replacement or correction is
appropriate. Processing, pre-receipt failure and service errors do not complete
a zero correction.

## Production activation and rollback

### Implemented contract matrix

| Exact XML version | Verified tax years | Mapping and prior-year behavior |
|---|---|---|
| `2.0.3` | 2024, 2025 | Existing year resources and prior-year indicator `0` |
| `5.0.7` | 2025 | TY2025 resource, prior-year indicator `1`, no TY2026 disclosures |
| `5.0.7` | 2026 | TY2026 resource, prior-year indicator `0`, MISC/NEC disclosures |
| Either implemented version | Other requested years with a usable resource | Explicit operation-only confirmation; existing implemented prior-year behavior is not a verification claim |
| Unimplemented version or no usable resource | Any | Configuration/resource error; no confirmation can waive it |

For an unverified year, the warning identifies the **requested year**, the
**actual resource year** (the requested resource if present, otherwise the most
recent available earlier resource), and the **exact XML version**. **No** is the
default. No/closing cancels before generation writes or IRS requests. A
noninteractive caller receives an actionable confirmation-required error rather
than assumed consent. One Yes covers only that operation, including multiple
documents after preflight; a new operation must ask again. No persistent waiver
is saved.

Yes does not certify the mapping: IRS rejection is **not guaranteed** to detect
incorrect reporting. The payload retains the requested `TaxYr` and requires
that year's approved Software ID (for example `27...` for 2027 even when using
the 2026 resource). Schema/data/identity validation and known incompatibilities
still block generation. In particular, consenting to a TY2026 mapping under
`2.0.3` cannot permit populated supplemental disclosures.

Submission preflight retains the existing contact-name and phone validation.
For `5.0.7` with TY2026 it also requires contact email and reports missing values
through **Error Messages**; XML generation enforces the same centralized rule.
This additional email requirement does not apply to TY2025.

This update supports the existing DIV, INT, MISC and NEC form families. It does
not add state filing, FIRE-origin/cross-channel corrections, Form 8027 or other
new form families. Schema selection is not evidence that every form described
by an IRS release package has been implemented.

1. Verify IRS production availability and the required year/form software
   approvals before authorizing `5.0.7`. Recheck the IRS
   [release schedule](https://www.irs.gov/e-file-providers/iris-schemas-and-business-rules)
   and [deployment notice](https://www.irs.gov/filing/e-file-information-returns-with-iris)
   at cutover. A scheduled release, machine date, successful TEST send or XSD
   pass is not production authorization.
2. Audit production period overrides before changing the Live default: a
   nonempty override continues to win.
3. Change the Live default through separately authorized operations, account
   for Key Vault caching using the supported refresh procedure, and inspect
   actual newly generated XML. TEST activation does not activate production.
4. For rollback, select the explicitly supported prior version through the
   applicable override/default and verify new XML. Preserve sent payloads,
   receipts, released data and history. Do not regenerate or resend old
   attempts, delete configuration, or reset the database.
   `2.0.3` is not a lossless rollback for populated TY2026 supplements: that
   incompatible combination stops explicitly. Pause affected filing and resolve
   the supported contract; do not clear disclosures to force a downgrade.
5. Before either deployment or package restoration, retain the approved
   Standard package/build identity and a supported normal recovery path. Use
   normal Synchronize only; `forceUpgrade` is not ForceSync. A failed
   publication/synchronization is a stop condition, not permission to retype
   fields, add shims, uninstall dependent apps or discard data.

The unshipped prototype header additions require no production data conversion,
conversion marker or prototype rollback adapter. This does not authorize
discarding released documents, stored XML or unrelated local ATS inputs.
Annual setup reconciliation remains an explicit, conservative operation.

Start local live smoke with TY2026 and its approved 2026 ID. TY2025 live cases
remain blocked without an approved 2025 ID; the 2026 ID is not a substitute.
Local ATS signing/configuration and OnPrem substitutions belong only in an
isolated private testing copy, not the shipping app.

## Build boundaries

Resolve `IRS Forms`, `IRS Forms Test Library` and `IRS Forms Tests` through
`Get-ProjectFolder -CountryCode <US|CA> -ApplicationName "<name>"`. The normal
manifest loader rebases canonical catalog paths to the BCApps source; do not
rewrite `projects.json` for a materialized checkout or add local harness entries.
Keep ordinary packages in `BuildOutput\<CC>\IRSForms\Standard` and private
kit packages in ignored `BuildOutput\US\IRSForms\LocalATS\Packages`, with frozen
source under `LocalATS\Generated`. `Development` contains retained earlier
packages used for provenance/recovery, not the current private kit or a
deployment instruction. A standard build must not depend on the local settings
app. Compile and publish the intended product,
test library and test app before claiming runtime test results.

Codeunit 148018 performs real self-HTTP API calls and requires disabled test
isolation so its committed fixtures are visible to the HTTP session. Honor its
`RequiredTestIsolation` setting without disabling isolation for other tests.
Run it only in a disposable test company and remove that owned company after
the test session; committed fixtures are not rolled back automatically. Each
successful method deletes only its owned documents, periods and vendors and
restores its work date, preserving other codeunits' reporting setup.
Require all four methods to execute and pass without skips.
The full suite also needs a test user with global `SUPER` in the selected
disposable test database: the existing permissions mock and cross-company
reconciliation tests require it. Remove any temporary user and all its
assignments after testing.

IRIS identity/XML fixtures post to monetary boxes MISC-03 and NEC-01 so both
forms qualify even at the purchase factory's lower amount boundary. Do not select
random direct-sales indicator boxes: their $5,000 minimum can suppress every
form document before the identity assertion is reached.

Offline lifecycle tests use the existing platform HTTP handler and File
Management download-stream test facility with synthetic data. They do not
contact IRS or certify ATS acceptance. The external schema gate validates
actual published-AL output against the authorized TY2025 v3.1 and TY2026 v1.2
`MSG\IRS-IRIntakeTransmissionMessage.xsd` entry points; do not copy those
packages into source control. Retain the generated XML, package/payload hashes
and validation results separately. XSD validation alone does not enforce every
product contract or IRS business rule: for example, the IRIS-origin intake
indicator and year-specific prior-year indicator need explicit assertions.

### Acceptance evidence is gate-specific

Source/package isolation, native compilation, published offline AL execution,
external XSD validation, actual-client behavior and real IRS acceptance are
different gates. Existing focused results and actual synthetic PDF/XML artifacts
do not establish a full-suite or final US/CA build pass, real mailbox delivery,
private installation/cleanup, signed ATS authentication or IRS acceptance.
The redacted local ledger is
`BuildOutput\US\IRSForms\Standard\Evidence\M00-M18-Redacted-Acceptance-20261030.md`.
It retains each historical build's provenance instead of attributing older
exports to the latest package. Detailed evidence belongs in access-restricted
local storage; never include protected inputs, PFX/passwords, OAuth material or
taxpayer data in a summary. Operator-only upload and live gates remain pending
until separately recorded.

## Supplemental document storage

### Annual setup

Fresh TY2026 setup, copying TY2025 setup into TY2026, and the existing
consecutive-year update use the same seven $2,000 defaults: MISC-01, -03,
-06, -09, -12, -15 and NEC-01 (physical box 1a). Earlier years retain their
existing defaults, including TY2025's $600 compensation threshold and its
distinct MISC-09/$1 and MISC-15/$0 defaults. Royalty/substitute-payment $10,
fish $600, direct-sales $5,000 and DIV/INT categories are unchanged.

Annual reconciliation inserts missing target setup and replaces only each
box's recognized prior standard minimum. Custom minimums, descriptions and
incompatible supplemental mappings are preserved and identified in the update
summary for explicit resolution in form-box/supplemental setup. Repeating an
update does not duplicate definitions. New target periods do not inherit
TEST/live schema overrides, and copying again retains existing target choices.

The six standard TY2026 supplemental definitions are seeded separately from
form boxes; no empty document disclosure rows are created. A historical
financial MISC-14 is not renamed, repurposed as overtime or silently removed:
its identifier conflict is reported. The old parachute-payment migration
remains limited to 2024-to-2025.

Recipient instructions are reconciled for the target document year, not the
work date. TY2025 NEC box 3 describes excess golden parachute payments and
MISC box 14 is reserved. TY2026 identifies NEC 1a/1b/1c/1d, MISC 13a/13b/14
and an unnumbered FATCA filing requirement. Fresh setup, copied setup and the
consecutive-year update insert missing instructions and replace only recognized
earlier standard text. Custom headers, descriptions and ordering are preserved
and reported with company, period, form and instruction line for explicit review
in **Form Instructions**. Earlier periods are not rewritten. Repeating the
update does not duplicate moved instructions.

The summary identifies the company, period and exact Open document IDs whose
stored thresholds differ from the target setup. Review these documents and use
the existing **Create Form Documents** or **Update Transmission** workflow to
select the intended recalculations. Setup itself changes no document amounts,
inclusion/threshold snapshots, saved supplemental parents, submitted documents,
posted payments or transmission payloads.

Financial parents referenced by supplemental definitions cannot be deleted or
renamed. Allowed whole-form/period deletion checks document use first and
removes statement rows before supplemental definitions and form boxes.
An active supplemental statement selector also protects its definition from
deletion, rename or structural edits. Compatible description changes remain
allowed. Change or remove the referencing statement selector before changing
otherwise unused supplemental setup.

### Configurable recipient statement rows

The existing **Form Statement** setup now has **Value Source** and
**Supplemental Box No.**. Existing rows default to **Financial Line** and retain
their financial filters, amount/Yes-No type, sign handling and ordering.
For a disclosure, choose **Supplemental Line**, then select a definition from
the same reporting period and form. Its definition determines amount versus
text-code output; financial filter expressions and the financial print type
are inactive for that source, not erased.

Fresh/copy/update TY2026 setup supplies NEC boxes 1b/1c/1d after compensation
(labelled physical box 1a, with internal identifier NEC-01 unchanged), and MISC
13a/13b/14 between section 409A deferrals and nonqualified deferred compensation.
All rows remain configurable. A nonempty row description overrides the definition
description; **Print with** applies to amounts, never to text codes such as `000`.
Move rows by their line ordering without changing XML element order.

TY2026 MISC/NEC XML uses schema `5.0.7` and the separate saved supplemental
lines, with the same parent eligibility as statements. Only selected documents
contribute to details and totals; tips and overtime never increase financial
income. When several documents form one recipient, reportable occupation codes
are deduplicated across those documents. More than two distinct codes stops
generation and identifies the contributing documents. Supplemental totals must
remain within the XSD amount limit. Populated unsupported mappings, or populated
disclosures with the incompatible `2.0.3` contract, fail explicitly instead of
being silently dropped. TY2025 XML retains its existing financial mappings and
contains no TY2026 disclosure fields.

Zero corrections zero only outgoing financial and supplemental amounts and omit
occupation elements. Saved amounts, codes and parent relationships are retained.
An IRIS-origin `5.0.7` correction still requires the accepted original reference
and emits `OtherIntakeSystemInd=0` before it; originals and replacements do not
emit that correction group.

Only documents included in the outgoing attempt become In Progress. An HTTP
receipt, a failed request or a Processing acknowledgment does not complete a
correction. The accepted acknowledgment, including one obtained later through
Request Status, completes the selected correction; an accepted zero correction
abandons its source without erasing its disclosures. **Step 2: Send Corrected**
sends a new original, not another correction.

A wholly rejected transmission is replaced using its original receipt in the
manifest. Otherwise replacement includes only rejected submissions, using each
submission's last receipt and submission ID. Accepted submissions stay excluded
even when another correction has changed the transmission's overall status.

For copied or existing 2026 periods, review the annual-update summary and open
**Form Statement** for each affected form. Reconciliation inserts absent defaults
and updates the recognized old NEC compensation label. Custom sources, selectors,
descriptions, signs, ordering and occupied default positions are retained and
reported for explicit resolution; moved rows are not duplicated at their old
positions. Repeating reconciliation makes no new rows or document changes.
Printing validates the entire document through the shared supplemental reporting
boundary and includes only disclosures with their own reportable saved parent.
Zero-tip codes remain stored but are not printed.

Saved PDFs are cached copies, not live views of this dataset. Source/setup edits
do not automatically replace issued PDFs or resend email. Deliberately regenerate
the required report copy before a controlled resend:

1. Select the intended document and verify its reporting period, form, financial
   parent and **Supplemental Lines**. Reopen it before correcting stored values;
   review/release it again through the normal workflow. Setup changes alone do
   not recalculate its financial snapshots.
2. Open **Reports** on the document. Download and retain any previously issued
   Copy B and Copy 2 before replacing a saved copy. Record which document/copy
   was issued; do not overwrite that external archive.
3. Explicitly replace only the intended cached copy. An authorized extension or
   administrative routine can call the existing public
   `IRS Forms Facade.SaveContentForDocument(Document, PrintParams, true)`, with
   `PrintParams."Report Type"` set to **Copy B** or **Copy 2**. The final `true`
   is deliberate replacement; `false` retains an existing PDF. Replacing Copy B
   does not replace Copy 2. This is an extension/administrative operation; this
   page does not provide a dedicated regeneration action.
4. Download the regenerated saved copy from **Reports** and inspect its year,
   instructions, amounts, occupation codes and pagination. The **Print** action
   can render current source, but does not refresh the separate email cache.
5. Use **Send Email**, explicitly select the inspected report type and authorize
   any intended resend. Sending by itself uses an existing cached PDF; it does
   not refresh changed disclosures. Verify the received attachment independently.

For fresh setup, confirm the year-specific defaults before entering documents.
For **Copy Setup** or an existing-period annual update, first resolve the
preserved conflicts described above in **Form Statement**, **Form Instructions**
and **Supplemental Boxes**. Review any affected Open document separately, then
follow the same archive/regenerate/inspect steps. Neither path authorizes
regenerating already issued copies or resending them automatically.

Offline regression uses the existing test email connector, not a real mailbox.
Attachment-byte checks and saved-PDF inspection do not establish real email
delivery or IRS acceptance.

The read-only `irs1099documentsupplementallines` API collection is available
directly and through each `irs1099documents` document's navigation property
(including `$expand`). Its key is `id` (SystemId); fields expose the stored
`documentId`, `supplementalBoxNo`, saved `parentFormBoxNo`, `valueType`,
`amount`, `occupationCode1` and `occupationCode2`. Codes remain text, including
`000`. Excluded amounts and codes retained when tips are zero are returned:
this is stored document data, **not** a projection of transmitted or printed
values. Reporting eligibility and zero-tip suppression apply separately to
XML/statements. POST, PATCH and DELETE are not allowed. The existing financial
collection and header fields are unchanged; supplements are not extra income.

TY2026 MISC and NEC disclosures use separate supplemental definitions and
document lines, never ordinary financial form boxes or posting destinations.
From the form setup, use **Supplemental Boxes** to configure compatible
definitions. Known identifiers must retain their exact XML mapping, financial
parent and value type. Descriptions remain editable; a definition already used
by document lines or active statement selectors cannot be deleted, renamed or structurally changed. A custom
definition with an empty XML mapping does not acquire Standard XML support.

On an Open document, explicitly select needed rows in **Supplemental Lines**.
The descriptive lookup offers only definitions for that period/form with an
existing financial parent and excludes boxes already added. The saved parent
box and value type are read-only; parent lookup uses the document ID and saved
box, not the financial line number. No empty supplemental rows are generated.

Amount rows cannot contain occupation codes, and code rows cannot contain
money. Codes are three-character text, including `000`, from the exact Treasury
enumeration. Each amount must be nonnegative, within the XSD range
`999999999999999.99`, and no greater than its stored parent income even when
that income is excluded by a threshold. The individual parent ceiling follows
the IRS instructions' included-income semantics; there is no combined
tips-plus-overtime ceiling and no new storage/input rounding policy.

Positive cash tips require one or two valid occupation codes before release.
The exact code enumeration and nonnegative monetary range come from the XSD;
the individual parent ceilings and positive-tip completeness check follow the
IRS instructions' included-income semantics, not an asserted workbook rejection
rule. Populated custom disclosures without a supported mapping fail at the
shared reporting boundary rather than disappearing silently.

Disclosures follow their **specific saved financial parent's** inclusion. Other
eligible income does not qualify an excluded parent. Positive backup withholding
preserves relevant nonzero MISC/NEC payment lines below their ordinary thresholds.
Valid excluded amounts remain stored against the actual parent amount, not the
zero that might be emitted for excluded income. Saved occupation codes remain
available when tips are zero or excluded; the reporting-status explanation
describes their exclusion. Shared consumers omit them until positive reportable
tips are restored, without requiring code re-entry.

Update Transmission stages recalculation and proposed attachments before user
selection. Accepted financial changes, supplemental validation, document statuses
and associations form one transaction; cancellation or invalid retained values
must leave every document and association unchanged. Threshold/inclusion changes
are offered even when payment amounts have not changed. Selection and manual
amount edits remain explicit. Posted payments are not part of this operation.

Same-year/vendor/form recreation snapshots disclosures before header cleanup
and transfers them to the actual new ID. A retained Abandoned header instead
keeps its disclosures and supplies a separate copy to its replacement. Saved
parent boxes and financial ledger details survive financial renumbering.
Replacement candidates with an exact source ID must match its period, vendor
and form; an unspecified source is rejected if multiple active matches exist.
Selected removed form boxes are not copied back into a replacement, and
removing a saved supplemental parent blocks the whole update.
Valid non-filing documents remain
Open with their parent and disclosures, without attachment solely to retain data.
Deliberately deleting a financial parent explicitly confirms deletion of its
linked supplemental rows; declining changes neither. Parent reassignment is
not consent to retarget or clear disclosures.
