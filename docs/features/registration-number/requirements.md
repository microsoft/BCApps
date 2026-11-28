# Global Registration Number Capability

Status: Draft requirements

## 1. Purpose

Provide a global W1 capability for an organization's primary legal registration
number. Support international identifiers without treating them as VAT numbers
or reproducing country-specific functionality in the global application.

The capability must preserve legally significant letters, leading zeros, spaces,
and separators, support configurable format validation, and remain extensible
for local legal requirements.

## 2. Scope

The initial release includes:

- Company Information, Customer, Vendor, and Contact registration numbers.
- Optional country-specific format setup.
- Common duplicate discovery and appropriate user feedback.
- Extensible local validation and presentation.
- Registration-number snapshots on agreed legally relevant documents.
- API and E-Document integration.
- Compatibility and migration of applicable existing localized functionality.

The initial release does not include:

- A collection of multiple registrations per organization.
- A registry-authority catalog or a general registration-identifier framework.
- A global registry lookup service or mandatory external validation.
- Consolidation of VAT numbers, Italian Fiscal Codes, or other distinct tax IDs.
- Changes to the meaning of existing localized identifiers without an explicit
  migration decision.

## 3. Existing Implementation

The following baseline informs the design; it is not a request to create
duplicate fields.

| Area | Existing implementation | Required direction |
|---|---|---|
| Customer, Vendor, Contact | Field 25, `Registration Number`, Text[50], with a W1 validation limit of 20 characters | Reuse existing fields and remove the artificial global limit |
| Company Information | Field 20, `Registration No.`, Text[20] | Preserve the legacy field and add field 7407, `Registration Number`, Text[50] |
| Sales documents | Sales Header and posted sales invoice/credit-memo headers have Text[50] registration fields | Reuse existing snapshots and close agreed lifecycle gaps |
| DACH | Active purchase-document and vendor-template fields use ID 11000 and Text[20] | Preserve legacy fields locally; use separate W1 purchase-document fields |
| CZ | Uses W1 master fields but retains local Text[20] helpers, logs, document fields, and services | Separate reusable behavior from local services and remove unsafe truncation |
| Integration | Narrow E-Document contracts and a Code[20] payment-recipient field remain | Provide compatible, explicit boundaries |

## 4. Data Requirements

### DATA-01: Primary registration number

Each supported entity must expose one primary legal registration number as
Text[50]. Reuse existing Text[50] W1 fields. Existing Text[20] fields must retain
their IDs, AL names, lengths, and legacy behavior; add separate Text[50] fields
instead of widening or promoting localized fields.

Captions and tooltips must use consistent terminology and must not describe a
20-character restriction.

### DATA-02: Preserve the legal representation

The application must not globally uppercase identifiers, remove separators,
strip legally significant spaces, or silently truncate values.

Comparison keys and display formatting must not overwrite the stored value.
Values exceeding the supported length must produce an explicit validation error.

### DATA-03: Country context

V1 must use the entity's existing Country/Region Code as the available context.
A blank country must not automatically select the company's country or another
country's format rules.

Country/Region Code is not a guarantee of registration jurisdiction or registry
authority. This limitation must be documented and considered when interpreting
duplicates and implementing local rules.

### DATA-04: Separation from tax identifiers

Legal registration must remain distinct from VAT registration and other fiscal
identifiers. The application must not automatically copy, relabel, or migrate tax
identifiers into this field based only on similar captions.

## 5. Configurable Format Validation

### FMT-01: Separate setup

Provide a registration-number format table and maintenance page, following the
country-and-line setup pattern of table 381, `VAT Registration No. Format`.
Do not reuse VAT format records or VAT-specific validation contracts.

| Field | Type | Purpose |
|---|---|---|
| Country/Region Code | Code[10] | Country whose rules apply |
| Line No. | Integer | Multiple accepted patterns per country |
| Format | Text[50] | Pattern for the complete identifier |

The primary key must be Country/Region Code and Line No. Setup must not allow
blank countries or empty patterns.

### FMT-02: Pattern language

Support the familiar placeholders:

| Symbol | Meaning |
|---|---|
| `#` | One digit |
| `@` | One letter |
| `?` | Any one character |
| Other characters | Literal characters, including spaces and separators |

A pattern matches the complete value, including length. Multiple patterns for
one country are alternatives: matching any one is sufficient.

Example: `@@ ########` accepts `AB 00123456`.

The foundation uses Unicode letters for `@`, ASCII digits for `#`,
case-sensitive literals, and backslash escaping of the next character. A trailing
unescaped backslash is invalid. The matcher uses the platform's character
classification rather than table 381's ASCII-only letter definition.

### FMT-03: Validation behavior

- With no applicable patterns, accept any nonempty value within Text[50].
- With applicable patterns, reject nonempty values that match none of them and
  explain which formats are accepted.
- A blank identifier must not be rejected by format setup alone. Local legal
  requirements may separately make an identifier mandatory.
- Matching must not rewrite the stored value.
- Changing country must re-evaluate the identifier under the applicable rules.
- Changes to format setup must not rewrite or retroactively invalidate stored
  records without an explicit validation operation.

Setup must be empty by default. Localizations may supply appropriate patterns
through their established setup mechanisms.

### FMT-04: Limits of pattern validation

Format validation confirms structure only. It must not claim that a number
exists, belongs to an organization, or passes a national checksum.

Checksum validation, registry lookups, and exceptional legal rules remain local
extension responsibilities.

## 6. Common Management and Extensibility

Provide a lightweight W1 management entry point for format validation, duplicate
discovery, and local validation/presentation extension points.

New identifier parameters and identifier-returning contracts must support
Text[50]. Extension points must receive sufficient entity, country, and source
record context to apply local rules and exclude the current record.

Preserve existing validation events and their handled semantics. New events
must use a handled pattern only where there is default work to replace.

Local validation must not require a mandatory country implementation or a
hardcoded external service. Presentation formatting must be separate from
storage and duplicate comparison.

Do not introduce a public contract that assumes a bare registration number is
globally unique. Future typed registrations must remain possible without adding
a collection or authority framework in this release.

## 7. Duplicate Discovery

Duplicate discovery must:

- Consider country context and the complete, untruncated identifier.
- Ignore blank identifiers and exclude the current record.
- Account for linked Contact, Customer, and Vendor representations of the same
  organization instead of treating each link as a separate legal entity.
- Allow local comparison rules without modifying the stored identifier.
- Remain separate from format validation and external registry validation.

A possible duplicate must produce advisory feedback, not a global uniqueness
constraint. Equal values are not proof of the same registration authority or
legal entity, particularly when country context is missing.

Discovery must return usable results independently of UI messages. APIs and
background sessions must not depend on interactive dialogs.

The foundation checks records accessible to the caller, using database equality
on the full identifier and the same nonblank country. It does not automatically
warn when country context is missing. Local comparison rules can replace or
extend discovery through events. Interactive entry uses a nonblocking notification
with an action to review the matching organizations.

## 8. Document Snapshots

Agreed legally relevant documents must retain the registration identifiers and
associated country context used for the transaction.

Before implementation, define the legal issuer and recipient for each document
family. Do not silently reinterpret an existing sell-to field as bill-to or a
buy-from field as pay-to.

Snapshots must survive posting and archiving. Later changes to master data must
not change historical document identifiers, including when documents are
reprinted or exported.

Reuse existing snapshot fields where their meaning matches. Audit company
information, sales, purchase, archive, posted-document, report, and E-Document
paths for missing snapshots or narrow intermediate values.

### Registration-Number Accessors

Reports and other read-only consumers should use `GetRegistrationNumber()`
instead of reading master fields directly. Customer, Vendor, and Contact getters
return Text[50] and delegate to a shared resolver using the current record's
stored value, country, and record identity. Local extensions can redirect this
resolution without changing consumers or modifying stored values. Company
Information retains its existing Text return type and after-get event, which
runs after shared resolution.

Document getters return only the registration snapshot stored on that document,
including an empty snapshot. They must not resolve current master data or fill
missing historical values. Snapshot creation uses the relevant master getter
without changing the existing party-role selection.

Keep editable page bindings, validation, keys, filters, and storage-change
detection tied to actual fields. Formatting remains a separate operation.

### Confirmed Sales and Purchase Snapshot Policy

- Preserve existing sell-to/buy-from registration roles and existing local
  bill-to overrides; do not reinterpret existing values as bill-to/pay-to.
- Freeze the company's registration number and country when posting or
  archiving. Draft reports continue reading current company information.
- Cover sales and purchase invoices, credit memos, shipments/receipts, return
  shipments/receipts, prepayments, drop shipments, and order/quote archives.
  Service, reminder, finance-charge, inventory, and compensation documents are
  separate document families outside this slice.
- Reuse sales field 72, `Registration Number`, throughout the sales lifecycle.
  Add W1 purchase field 7407, `Registration Number`, Text[50], throughout the
  purchase lifecycle, including posted and archived headers. Leave DACH field
  11000, `Registration No.`, Text[20], local and unchanged.
  Do not consolidate the DACH Vendor registration field.
- Store counterparty country in field 7404, `Registration Country/Region`.
  Posted and archived headers also store company registration in field 7402,
  `Company Registration No.`, and company country in field 7403,
  `Company Reg. Country/Region`.
- Do not backfill missing historical numbers or countries from current master
  data. Existing stored sales and DACH purchase numbers remain unchanged.
- New company snapshots support Text[50]. A longer value returned by an
  existing company-getter subscriber must fail explicitly, not be truncated.

After feature activation, posted report readers use document company-snapshot
getters, without a live fallback for older or empty snapshots. Before activation,
report adapters preserve existing current-company and localized document reads.
Snapshot getters themselves always return stored values only.
CZ sales layouts use the per-document
`CompanyRegistrationNumber` dataset column, including when printing multiple
documents with different snapshots. Their old shared
`RegistrationNo_CompanyInformation` column retains its legacy value before
activation, becomes empty after activation, and is marked pending obsoletion
with CLEAN30 guards. Custom layouts using it must move to the new per-document
column before activation.

### Staged Activation and Local Migration

- Use the W1 feature key `GlobalRegistrationNumbers`, separate from the IT
  installment feature. Missing or disabled keys preserve legacy behavior.
- The platform feature definition must be registered with data update required,
  disabled by default, one-way activation, and no trial mode. Feature definitions
  are supplied by the platform, not declared by the Base App enum extension.
- The Base App implements `Feature Data Update` through `Feature To Update`.
  Each company must complete its update before the new readers, format
  validation, duplicate notifications, resolver hooks, and format-setup UI are
  enabled. Merely enabling the environment key is insufficient.
- New Text[50] fields are unconditional; existing field lengths do not change. Capture company
  snapshots during posting and archiving even before activation. Do not copy
  current master values into historical documents during migration.
- DACH purchase field 11000 retains its identity, Text[20] length, legacy behavior,
  and existing data. The separate W1 field 7407 stores new global snapshots;
  historical documents are not backfilled. The DACH Vendor field remains local
  and untouched.
- Company Information field 20 remains Text[20]. Its nonblank value is offered
  for explicit migration to field 7407, `Registration Number`, unless a local
  migration adapter already supplies a company candidate. The company accessor
  and UI switch to the new field only after activation.
- BE supplies migration candidates for Customer, Vendor, Contact, and Company
  Information where a nonblank `Enterprise No.` differs from the W1 registration
  field. No country-based or tax-derived mapping is inferred automatically.
- Review each candidate explicitly: **Use Local** copies the exact local value
  into W1, including overwriting a conflicting value only by that explicit
  choice. **W1 Value Is Intentional** preserves W1, including a deliberate blank.
  Until one is selected, activation is blocked.
- A changed local value, W1 value, country, or mapping invalidates the decision.
  Migration rechecks approved source data under update locks, runs atomically,
  validates copied registration values, and is safe to retry.
- Preserve BE enterprise fields, MOD97 checks, VAT interactions, and national
  consumers. Migration writes only the selected W1 master fields. The BE company
  accessor and caption switch from Enterprise No. to W1 only after activation.
  Migration is one-time; it does not introduce automatic synchronization between
  the W1 legal number and the locally maintained enterprise/tax fields.
- Assign `REGISTRATION MIGRATE` alongside the appropriate existing master-data
  permissions for review and update. This role includes Feature Management
  administration but does not grant extra master-data modification rights.
- Activation is not a storage rollback mechanism. Feature Management must not
  disable the feature after a company has completed migration.

## 9. APIs and Integration

Expose legal registration separately from existing tax-registration properties.
In particular, do not repurpose API `taxRegistrationNumber`.

New API and E-Document identifier contracts must support Text[50] and preserve
the stored representation. Existing published narrow methods and events require
compatible replacements, wrappers, and obsoletion where appropriate.

Audit E-Document receiving-company storage, vendor identification, report
variables, setup buffers, and payment-export paths. The current Code[20] payment
recipient identifier is a representation boundary, not just a text-length issue.

Where an external format has stricter limits, the adapter must validate them and
report a clear error or use an explicitly defined local conversion. It must not
silently truncate or normalize the global identifier.

Ambiguous inbound identification must not arbitrarily select the first matching
organization.

### Inbound E-Document Data Exchange upgrades

The incoming legal-identity upgrade adds optional columns and mappings to the
four shipped PEPPOL invoice/credit-note import definitions, including installed
copies. It preserves existing paths and mapping options, uses free column
numbers, and is safe to repeat. Do not reimport bundled XML over a customized
definition to obtain these additions.

Definitions under custom codes require a reviewed mapping update: map the
supplier/customer legal number, country and scheme to the new E-Document fields
for legacy imports, or the corresponding E-Document Purchase Header fields for
structured imports. Retain the full source value so the importer can reject
overflow rather than truncate it.

For PEPPOL definitions, add header source columns named `InboundSupplierVATID`
and `InboundCustomerVATID` for `PartyTaxScheme[TaxScheme/ID="VAT"]/CompanyID`,
plus `InboundSupplierEndpointID` and `InboundSupplierEndpointScheme` for
`EndpointID` and its `schemeID` attribute. Use the definition's actual namespace
prefixes and supplier/customer party paths. These source columns keep tax and
endpoint values separate from legal and payee identifiers; they require no
master-data target mapping. Review custom transformations rather than replacing
them automatically. Scheme values are retained as source metadata, not inferred
from a country or registration-number format.

### Outbound PEPPOL legal identities

The existing sales registration snapshot retains its sell-to meaning. Sales
headers, archives and posted headers additionally carry `Bill-to Registration
No.` (Text[50], field 7405) and `Bill-to Reg. Country/Region` (field 7406).
Bill-to selection captures both values; posting and archiving transfer them
without consulting today's customer.

| Export | Legal party | Snapshot | UBL business term |
|---|---|---|---|
| Sales invoice/credit note | Supplier | Document company | BT-30 |
| Sales invoice/credit note | Customer | Document bill-to | BT-47 |
| Self-billed purchase invoice/credit note | Supplier | Document buy-from vendor | BT-30 |
| Self-billed purchase invoice/credit note | Customer | Document company | BT-47 |

`Registration No. Export` applies these identities only to
`PartyLegalEntity/CompanyID`. Existing provider interfaces still run unchanged;
the adapter receives the original document RecordRef, not its temporary
Sales/Purchase Header projection. Modern and legacy XMLports, self-billing and
the PEPPOL Data Exchange export subscribers use this context. VAT, endpoints,
payees and the sell-to snapshot remain independent and unchanged.

With `GlobalRegistrationNumbers` inactive, exports preserve their previous
behavior. With it active, missing historical number/country snapshots are never
reconstructed from masters or other party roles. Optional legal identifiers are
omitted. Service documents currently have no equivalent legal snapshots and
follow the same omission policy.

The W1 default leaves optional legal `schemeID` attributes absent. No national
registry mapping is implied. Profile/registry extensions subscribe to
`OnResolveProfileRequirements`, using the customization identifier, role,
snapshot and country to specify a registry scheme, mandatory identifier/scheme
requirements and maximum supported length. Registration-format masks must not
be used as schemes. Missing mandatory data or unsupported lengths raise explicit
errors; export never truncates or normalizes a legal number.

Data Exchange exports omit optional blank legal nodes and schemes through
in-memory column options, without modifying installed/custom definitions.
Custom profiles must supply their applicable registry policy before activation.
There is no historical backfill or automatic master-data update.

### Payment format boundaries

Payment fields named "registration" are not interchangeable legal identifiers.
W1 `Recipient Reg. No.` remains Code[20] bank-branch storage. RU journal exports
retain their balancing-account value in `Sender Reg. No.`; the generic journal
pre-mapping path likewise retains its sender bank-account value. Neither path
is reinterpreted as legal registration.

The W1 journal, vendor-ledger and customer-ledger adapters that explicitly read
the company legal getter validate their sender value before payment insertion
can apply EPC/ASCII conversion. IS's existing legal-recipient overrides use the
customer/vendor getters and validate before copying into Code[20], including
the journal pre-mapping override. Overflow, case/space normalization by Code,
control characters and lossy EPC conversion raise explicit errors rather than
truncating, transliterating or changing master data. EPC conversion can alter
ASCII punctuation as well as non-Latin letters.
Configured output-column lengths are checked before fixed-text formatting can
truncate a legal identifier.

These checks use the existing `GlobalRegistrationNumbers` company-completion
gate. Before activation, legacy narrowing and conversion remain unchanged.
After activation, a format configured to preserve non-Latin characters may
retain those characters, provided its destination field can also represent
the identifier unchanged. Name/address/remittance conversion remains unchanged.
Narrower format-specific character repertoires and custom transformations still
require review in custom bank definitions before activation.

No identified format requires new full-width recipient storage in this slice.
IS's existing narrow contract rejects unsupported values; it does not widen or
repurpose the W1 bank-branch field. AMC's existing unbounded XML legal-sender
element already reads the company getter independently of the generic payment
ASCII conversion, so no additional storage or guessed bank-specific limit is
introduced there.

## 10. Localization and Compatibility

| Localization | Required treatment |
|---|---|
| DACH | Preserve applicable active field IDs when consolidating matching functionality. Keep the removed Vendor registration field DACH-only. |
| CZ | Keep ARES integration, registration logging, and national legal behavior local. Reuse common duplicate discovery where appropriate. Replace truncating helpers through compatible contracts. |
| DK | Keep the local company-CVR posting requirement local. |
| IS | Preserve local UI arrangements and payment mappings; review export limits explicitly. |
| IT | Keep Fiscal Code separate from legal registration. |
| DE | Preserve existing fiscal and legal PEPPOL behavior until identifier semantics and migration are agreed. |

Do not obsolete local functionality merely because a W1 field exists. Obsolete
only functionality fully superseded by an available replacement, with the
required compatibility period and repository-standard cleanup guards.

Preserving field IDs avoids unnecessary migration only where table identity,
field identity, ownership, and semantics permit it. Different extension IDs or
different identifier meanings require an explicit migration plan.

Existing values must survive upgrade unchanged. New format setup must not block
upgrade or unrelated posting solely because historical records do not match a
newly configured pattern.

## 11. Acceptance Criteria

1. All four master entities accept and retain a valid 50-character value.
2. Leading zeros, letter case, and legally significant spaces and separators
   survive supported entry, synchronization, posting, API, and export paths.
3. Without country format setup, no format restriction is imposed.
4. With multiple formats, any matching pattern is accepted; a mismatch explains
   the applicable patterns without modifying the identifier.
5. Blank countries do not inherit another country's patterns.
6. Duplicate discovery excludes self and linked representations, considers
   country context, and never creates a global uniqueness constraint.
7. Local checksum and registry validation can extend the capability without
   adding global external-service dependencies.
8. Master-data edits do not change posted or archived registration snapshots.
9. API and background flows do not depend on interactive duplicate dialogs.
10. Existing localized records, integrations, and published extension contracts
    retain compatible behavior or have an explicit migration path.
11. Narrow output formats fail explicitly when they cannot represent a value;
    no supported path silently truncates the identifier.
12. VAT numbers, Fiscal Codes, and other tax identities remain semantically
    separate.

## 12. Decisions Required Before Implementation

- Legal party roles and snapshot coverage for additional document families,
  including service documents and related archives.
- DE fiscal/legal identifier mapping and any required data migration.
- API exposure/versioning and replacements for published narrow contracts.

## 13. Suggested Delivery Slices

1. W1 master fields, format setup, common management, and duplicate discovery.
2. Document snapshots, lifecycle gaps, and compatible DACH consolidation.
3. APIs, E-Documents, payment boundaries, and localized compatibility/migration.
