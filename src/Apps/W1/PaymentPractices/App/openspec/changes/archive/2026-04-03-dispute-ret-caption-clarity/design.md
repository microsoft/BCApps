## Context

P693 (`Paym. Prac. Dispute Ret. Card`) is a card page sourced from table T689 (`Paym. Prac. Dispute Ret. Data`). Table field names are constrained to 30 characters by AL, forcing heavy abbreviation. Since page field controls inherit the table field name as caption by default, the page currently shows abbreviated labels. Card pages render one field per row, so there is no column-width constraint on caption length.

## Goals / Non-Goals

**Goals:**
- Make all 19 abbreviated field captions on P693 human-readable by adding explicit `Caption` properties on the page controls.
- Keep table field names unchanged (they are code identifiers, not user-facing).

**Non-Goals:**
- Renaming table fields or changing the database schema.
- Adding ToolTip overrides (existing ToolTips on the table are already clear).
- Changing captions on any other page that references T689 fields.
- Changing obviously clear abbreviations like "Pmt." (Payment).

## Decisions

**Caption-only override on page fields** — Captions are set via `Caption = '...'` on each `field()` control in the page. This avoids any schema change and the new captions appear in the `.g.xlf` for translation. Alternative: adding `CaptionML` on the table fields was rejected because it would affect all pages using those fields, not just P693.

**Abbreviation expansion rules:**
| Abbreviation | Expansion | Notes |
|---|---|---|
| Contr. | Contract(s) / Contractual | Context-dependent |
| Constr. | Construction | |
| Ret. / Retent. | Retention | |
| Circs. | Circumstances | |
| Suppls. | Suppliers | |
| Subcon | Subcontractors | |
| Std | Standard | |
| Pct | % | Universal symbol, saves space |
| Desc. | Description / Descr. | Full word when caption is short, Descr. when long |

## Risks / Trade-offs

- **Translation file churn** — 19 new Caption entries will appear in `.g.xlf`. This is expected and low-risk since the page is new.
- **Caption drift from ToolTip** — Table ToolTips still reference abbreviated field names in their text. No action needed since ToolTips are already descriptive sentences, not label echoes.
