# French legal identifiers and electronic addressing

French electronic invoices distinguish the legal unit, its establishment, and
the electronic address used to route the invoice.

| Party | SIREN: legal unit, 9 digits | SIRET: establishment, 14 digits |
|---|---|---|
| Company | Company Information, Registration No. | Company Information, SIRET No. |
| Customer | Customer Card, SIREN No. | Customer Card, SIRET No. (`FR SIRET No.`) |
| Vendor | Vendor Card, SIREN No. | Existing Registration No., when it already contains a valid French SIRET (read-only evidence) |

Customer and Vendor Registration Number remains a generic registration field;
it is not the canonical French SIREN field. Existing Contact and French printed
report behavior continues to use the dedicated SIREN field.

No Vendor fields are added. A French Vendor's existing Registration Number is
read as SIRET evidence only when its complete value is fourteen digits. Foreign,
nonnumeric, or differently sized generic registrations are not SIRET evidence.
Matching does not populate, normalize, or overwrite Registration Number.

A valid SIRET can supply the first nine digits as SIREN when the canonical SIREN
is blank. A populated SIREN must be valid and agree with SIRET. SIRET is optional
for the supported invoice scenarios. Format validation does not establish
registration in the official directory or universally apply a checksum rule.

## Prepare existing data

Use **Prepare French Identifiers** on a Customer Card, Vendor Card, or French
E-Document Service Card. The service action prepares the company and French
customers and vendors, and checks service-specific routing.

Preparation fills empty Customer SIREN/SIRET fields and the existing Vendor
SIREN field from agreeing existing identifiers:
dedicated SIREN/SIRET, a recognized 9- or 14-digit generic Registration Number,
or a valid electronic address explicitly qualified with scheme `0009`.
Conflicting sources prevent migration of that record. Existing values are not
overwritten; generic registrations, address strings, and linked Contacts are
preserved. Repeating preparation does not rewrite already prepared records.
No Vendor SIRET field is introduced or populated.

A routing prefix or French VAT suffix alone is an unconfirmed candidate, not
permission to create a legal identifier. Readiness errors show the source
values and the owning record so they can be corrected and preparation repeated.
The versioned upgrade performs the same non-destructive preparation and records
unresolved issues without aborting the technical upgrade.

## Configure routing separately

For ordinary domestic French B2B invoices, the receiving buyer address uses
scheme `0225`: either the buyer's SIREN or `SIREN_suffix`. The suffix must be
nonempty and may contain ASCII letters, digits, hyphens, underscores, and
periods. The complete address is at most 125 characters and its prefix must
agree with the buyer's resolved legal SIREN.

Customer routing uses the selected Service Participant first, an explicitly
configured card address second, and a synthesized SIREN/`0225` route last.
Invalid higher-priority configuration is reported, not silently bypassed.
An empty legacy `EM` address is treated as unconfigured without changing its
stored scheme. Only a genuinely blank scheme can be migrated to `0225` after
its address has been checked against independently established SIREN.

For the ordinary sending company, a selected Service Participant takes
precedence; otherwise routing uses SIRET/`0009`, or SIREN/`0002` when SIRET is
absent. Other supported schemes are validated in contexts that permit them;
they do not replace the domestic buyer's `0225` requirement. Helper-level
self-billing role rules do not enable additional self-billing workflows.

## Export and import

| Identifier | UBL | CII |
|---|---|---|
| SIREN | `PartyLegalEntity/CompanyID`, scheme `0002` | `SpecifiedLegalOrganization/ID`, scheme `0002` |
| SIRET | `PartyIdentification/ID`, scheme `0009` | `GlobalID`, scheme `0009` |

These mappings apply independently to seller and buyer. CII GLN uses scheme
`0088` and is never read from an unqualified ID or a SIRET node. Factur-X carries
the selected service into the XML attachment produced by all supported report
rendering paths, including batch generation.

Both structured and legacy French imports use exact SIRET from an existing
fourteen-digit French Vendor Registration Number, resolved SIREN,
VAT, GLN, applicable Service Participant, and existing name/address matching,
in that order. Ambiguity at the highest matching tier requires manual
selection. Weaker identifiers cannot contradict the selected canonical
identity. Matching does not modify Vendor master data, and the shared W1
importer retains its default behavior outside the French wrapper.
The Vendor SIREN is resolved from its dedicated field, or from the existing
registration SIRET only when the dedicated SIREN is blank.

Incoming qualified XML terms must themselves be valid and coherent. Supplying
SIRET without its qualified legal SIREN is rejected rather than silently
repairing a missing legal term. Duplicate or empty qualified IDs are rejected.

## Document history

New or deliberately regenerated XML uses current master-data identity and
routing while preserving existing posted party details and party-selection
rules. No posting-time identifier snapshots are introduced. Already generated
payloads and frozen lifecycle/reversal identities are not rewritten when
master data changes.

Captions, tooltips, and diagnostics use the normal translatable AL properties
and labels. The build generates XLIFF resources for the repository's
localization process; generated translation files are not checked in.
