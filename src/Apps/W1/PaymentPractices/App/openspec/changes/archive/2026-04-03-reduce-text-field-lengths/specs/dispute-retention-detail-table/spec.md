## MODIFIED Requirements

### Requirement: Detail table contains payment terms fields
The table SHALL have fields: `Shortest Standard Pmt. Period` (Integer), `Longest Standard Pmt. Period` (Integer), `Standard Payment Terms Desc.` (Text[2048]), `Payment Terms Have Changed` (Boolean), `Suppliers Notified of Changes` (Boolean), `Max Contractual Pmt. Period` (Integer), `Max Contr. Pmt. Period Info` (Text[1024]), `Other Pmt. Terms Information` (Text[1024]).

#### Scenario: Suppliers Notified conditional on Payment Terms Changed
- **WHEN** Payment Terms Have Changed = false
- **THEN** Suppliers Notified of Changes is reset to false

#### Scenario: Payment terms narrative saved
- **WHEN** a user enters Standard Payment Terms Desc. = "30 days from invoice date"
- **THEN** the value is persisted

### Requirement: Detail table contains construction retention fields
The table SHALL have a gate field `Has Constr. Contract Retention` (Boolean). When true, the following sub-fields SHALL be available: `Ret. Clause Used in Contracts` (Boolean), `Retention in Std Pmt. Terms` (Boolean), `Retention in Specific Circs.` (Boolean), `Retention Circs. Desc.` (Text[1024]), `Withholds Retent. from Subcon` (Boolean), `Contract Sum Threshold` (Decimal), `Std Retention Pct Used` (Boolean), `Standard Retention Pct` (Decimal), `Terms Fairness Practice` (Boolean), `Terms Fairness Desc.` (Text[1024]), `Release Mechanism Desc.` (Text[1024]), `Release Within Prescribed Days` (Boolean), `Prescribed Days Desc.` (Text[1024]).

#### Scenario: Retention Circs. Desc. cleared when gate is false
- **WHEN** Retention in Specific Circs. is set to false
- **THEN** Retention Circs. Desc. is cleared

#### Scenario: Standard Retention Pct cleared when not used
- **WHEN** Std Retention Pct Used is set to false
- **THEN** Standard Retention Pct is reset to 0
