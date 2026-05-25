## Context

T689 has three boolean toggle fields in the Construction Contract Retention group that gate dependent text fields. Currently, two of them (`Retention in Specific Circs.`, `Terms Fairness Practice`) silently clear their dependent text fields on toggle-off. The third (`Release Within Prescribed Days`) has page-level Editable gating on `Prescribed Days Desc.` but no clearing trigger. The parent toggle `Has Constr. Contract Retention` already uses a confirmation dialog pattern via `Confirm Management` before clearing all child fields (added in `dispute-ret-page-layout`). `Std Retention Pct Used` (which clears a decimal field) is out of scope — clearing a numeric value is low-risk and doesn't warrant a confirmation.

## Goals / Non-Goals

**Goals:**
- Add confirmation dialogs on all 3 child boolean toggles that gate text fields, matching the parent toggle pattern.
- Add a clearing OnValidate trigger on `Release Within Prescribed Days` for `Prescribed Days Desc.`.

**Non-Goals:**
- Changing the parent toggle (`Has Constr. Contract Retention`) behavior — already handled.
- Adding confirms to boolean toggles outside the Construction Contract Retention group (e.g., `Payment Terms Have Changed`).

## Decisions

**One shared confirmation label vs per-field labels** — Use a single generic Label like `'The related field will be cleared. Do you want to continue?'` shared across all 3 toggles. Alternative: per-field messages naming the specific cleared field were rejected — the toggle/field pairing is obvious from the page layout and per-field labels add translation overhead for minimal UX benefit.

**Same Confirm Management pattern** — All 3 triggers use `ConfirmManagement.GetResponseOrDefault(...)` with revert-on-decline, consistent with the parent toggle. This keeps the table's OnValidate patterns uniform.

## Risks / Trade-offs

- **Confirmation fatigue** — Users toggling multiple fields off in one session will see multiple dialogs. Acceptable because these are infrequent policy-change actions, not high-frequency data entry.
- **Test handlers** — Any test that toggles these fields off will need a ConfirmHandler. Low risk since the test surface is small.
