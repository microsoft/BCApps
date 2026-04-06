## Why

The Dispute & Retention Card page (P693) uses heavily abbreviated field captions inherited from 30-character table field names (e.g., "Qual. Constr. Contr. in Period", "Retent. Withheld from Suppls."). Since P693 is a card page displayed one field per row, there is no column-width pressure and captions can be longer. Several abbreviations are ambiguous — "Contr." is used for both "Contract(s)" and "Contractual", making the page hard to read.

## What Changes

- Add explicit `Caption` properties on 19 page fields in P693 to expand abbreviated captions into clear, readable text.
- Table field names remain unchanged (code-only identifiers, 30-char AL limit).
- No functional or schema changes — purely a UI readability improvement.

## Capabilities

### New Capabilities

### Modified Capabilities
- `dispute-retention-detail-page`: Add requirement that page field captions SHALL be human-readable, expanding abbreviations like Contr., Constr., Ret., Retent., Circs., Suppls., Subcon, Std, Pct, and Desc. where the field name is ambiguous or unclear.

## Impact

- **Page**: `Paym. Prac. Dispute Ret. Card` (P693) — 19 fields gain Caption overrides.
- **Translation**: New Caption values will generate entries in the `.g.xlf` translation file.
- **Table**: No changes to `Paym. Prac. Dispute Ret. Data` (T689).
- **Tests**: No functional behavior change; existing tests unaffected.
