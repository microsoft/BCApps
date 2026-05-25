## Why

The Dispute & Retention Details card page (P693) renders fields in two columns on wide viewports, causing long captions to be truncated. The Construction Contract Retention group also uses a nested sub-group with dynamic `Visible` to gate 18 child fields, which causes the page to jump when toggled. These layout issues make the page harder to read and use.

## What Changes

- Wrap fields in each FastTab group (except Dispute Resolution) inside a `grid > group` control to force single-column layout, ensuring full caption visibility.
- Flatten the `RetentionDetails` nested sub-group into the `Construction Contract Retention` parent group, removing the dynamic `Visible` gate.
- Switch retention detail fields from `Visible` gating to `Editable` gating on `"Has Constr. Contract Retention"`, keeping the page layout stable when the toggle is off.
- Add a confirmation dialog when `"Has Constr. Contract Retention"` is toggled off, warning the user that retention fields will be cleared.
- Add `MultiLine = true` on long text fields (Text[250]+) to improve readability of paragraph-style content inside the grid layout.

## Capabilities

### New Capabilities

### Modified Capabilities
- `dispute-retention-detail-page`: Change field layout to single-column via grid controls. Replace Visible gating on retention sub-group with per-field Editable gating. Add confirmation dialog and field clearing on parent toggle-off. Add MultiLine on text fields.

## Impact

- **Page**: `Paym. Prac. Dispute Ret. Card` (P693) — layout restructured with grid controls, field editability logic changed, MultiLine added.
- **Table**: `Paym. Prac. Dispute Ret. Data` (T689) — new `OnValidate` trigger on `"Has Constr. Contract Retention"` to confirm and clear child fields.
- **Translation**: No new captions; existing captions are unaffected. The confirmation dialog Label will generate a `.g.xlf` entry.
- **Tests**: Existing tests that assert retention fields are hidden when gate is false will need updating to assert non-editable instead.
