## Why

Three boolean toggle fields in the Construction Contract Retention group silently clear their dependent text fields when toggled off (`Retention in Specific Circs.` clears `Retention Circs. Desc.`, `Terms Fairness Practice` clears `Terms Fairness Desc.`). A third toggle (`Release Within Prescribed Days`) gates `Prescribed Days Desc.` via page Editable but has no clearing trigger at all. Users can lose entered text with no warning. The parent toggle `Has Constr. Contract Retention` already has a confirmation dialog (added in `dispute-ret-page-layout`), so the child toggles should follow the same pattern for consistency.

## What Changes

- Add confirmation dialogs on the `OnValidate` triggers for `Retention in Specific Circs.` and `Terms Fairness Practice` in T689. When toggled false, the user is asked to confirm before the dependent text field is cleared. If declined, the toggle reverts to true.
- Apply the same pattern to `Release Within Prescribed Days` which gates `Prescribed Days Desc.` via page `Editable` but currently has no clearing trigger — add both the clearing logic and the confirmation dialog.

## Capabilities

### New Capabilities

### Modified Capabilities
- `dispute-retention-detail-table`: Add confirmation dialog before clearing dependent fields on child boolean toggles in the Construction Contract Retention group.

## Impact

- **Table**: `Paym. Prac. Dispute Ret. Data` (T689) — modify OnValidate on 2 existing fields; add OnValidate on 1 field (`Release Within Prescribed Days`).
- **Translation**: New confirmation Label string will generate a `.g.xlf` entry (1 shared label across all 3 toggles).
- **Tests**: Tests that toggle these fields off will need to handle the confirmation dialog.
