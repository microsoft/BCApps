## MODIFIED Requirements

### Requirement: Page organized in FastTab groups
The page SHALL have the following groups: `Qualifying Contracts` (fields 60-62), `Payment Terms` (fields 63-70), `Construction Contract Retention` (fields 40-58 with gate on Has Constr. Contract Retention), `Dispute Resolution` (field 71), `Payment Policies` (fields 30-34). Each field control on the page SHALL have a human-readable `Caption` property that expands ambiguous abbreviations from the underlying table field names. The following caption mappings SHALL apply:

| Table Field Name | Page Caption |
|---|---|
| Qual. Constr. Contr. in Period | Qual. Construction Contracts in Period |
| Standard Payment Terms Desc. | Standard Payment Terms Description |
| Max Contr. Pmt. Period Info | Max Contractual Pmt. Period Info |
| Has Constr. Contract Retention | Has Construction Contract Retention |
| Ret. Clause Used in Contracts | Retention Clause Used in Contracts |
| Retention in Std Pmt. Terms | Retention in Standard Pmt. Terms |
| Retention in Specific Circs. | Retention in Specific Circumstances |
| Retention Circs. Desc. | Retention Circumstances Description |
| Withholds Retent. from Subcon | Withholds Retention from Subcontractors |
| Std Retention Pct Used | Standard Retention Pct. Used |
| Standard Retention Pct | Standard Retention % |
| Terms Fairness Desc. | Terms Fairness Description |
| Release Mechanism Desc. | Release Mechanism Description |
| Prescribed Days Desc. | Prescribed Days Description |
| Retent. Withheld from Suppls. | Retention Withheld from Suppliers |
| Gross Payments Constr. Contr. | Gross Construction Contract Payments |
| Pct Retention vs Client Ret. | % Retention vs Client Retention |
| Pct Retent. vs Gross Payments | % Retention vs Gross Payments |
| Policy Covers Deduct. Charges | Policy Covers Deduction Charges |

Fields with already-clear names (e.g., Qualifying Contracts in Period, Payment Terms Have Changed, Contract Sum Threshold) SHALL NOT receive a Caption override and SHALL continue inheriting the table field name.

#### Scenario: Page displays expanded captions for abbreviated fields
- **WHEN** a user opens P693 for any D&R record
- **THEN** each of the 19 abbreviated fields displays its expanded caption as specified in the mapping table above

#### Scenario: Clear field names retain original captions
- **WHEN** a user opens P693 for any D&R record
- **THEN** fields with unambiguous names (e.g., "Qualifying Contracts in Period", "Payments Made in Period", "Contract Sum Threshold") display their table field name as the caption without override
