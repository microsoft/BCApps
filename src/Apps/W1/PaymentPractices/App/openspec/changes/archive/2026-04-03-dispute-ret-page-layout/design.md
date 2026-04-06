## Context

P693 (`Paym. Prac. Dispute Ret. Card`) is a Card page sourced from T689. The BC web client responsive layout renders Card page groups in two columns when there are enough fields and viewport width allows it. This truncates the long captions common on this page. Additionally, the Construction Contract Retention group uses a nested sub-group (`RetentionDetails`) with `Visible = Rec."Has Constr. Contract Retention"` to hide/show 18 fields, causing page reflow when toggled.

The IRS Forms Setup page (P10030) in the US localization uses a `grid > group` pattern to force single-column layout on a Card page — this is the established pattern to follow.

## Goals / Non-Goals

**Goals:**
- Force single-column field layout on P693 so captions display fully without truncation.
- Flatten the RetentionDetails sub-group, replacing Visible gating with Editable gating for a stable layout.
- Confirm and clear retention fields when the parent toggle is switched off.
- Add MultiLine on text fields (Text[250]+) for paragraph-style content readability.

**Non-Goals:**
- Changing table field names or the database schema (aside from the new OnValidate trigger).
- Modifying the Dispute Resolution group layout (single field, no truncation issue).
- Shortening text field lengths (handled by a separate change: `reduce-text-field-lengths`).

## Decisions

**Grid pattern for single-column layout** — Each FastTab group (except Dispute Resolution) wraps its fields in `grid(<GroupName>Grid) { group(<GroupName>Inner) { ShowCaption = false; ... } }`. This forces all fields into one column regardless of viewport width. Alternative: splitting groups into smaller sub-groups of 2-3 fields was rejected because the platform's responsive behavior is not guaranteed even with small groups.

**Editable gating instead of Visible gating** — Retention detail fields use `Editable = Rec."Has Constr. Contract Retention"` (combined with existing child-toggle conditions where applicable). This keeps the page layout stable and lets users see the full form structure upfront. Alternative: per-field `Visible` was rejected because it requires repeating the expression 18 times and cannot use a sub-group inside the grid's inner group.

**Compound Editable expressions for child toggles** — Fields gated by both the parent and a child toggle use `Editable = Rec."Has Constr. Contract Retention" and Rec.<child-toggle>`. For example, `"Retention Circs. Desc."` becomes `Editable = Rec."Has Constr. Contract Retention" and Rec."Retention in Specific Circs."`.

**Confirm + clear on parent toggle-off** — A new `OnValidate` trigger on T689 field `"Has Constr. Contract Retention"` shows a confirmation dialog when toggled off, then clears all retention child fields. This extends the existing pattern where child toggles already clear their dependent fields. The confirmation uses `Confirm Management` codeunit consistent with the existing `CopyFromPrevious` action.

**MultiLine on text fields** — `MultiLine = true` is added on page field controls for Text[250]+ fields. There are no production examples of MultiLine inside grid controls in the BaseApp, so this is experimental. If rendering is poor, the fallback is to move text fields outside the grid into their own sub-group.

## Risks / Trade-offs

- **MultiLine inside grid is untested** → Fallback: extract text fields out of the grid into a separate group if rendering misbehaves. Low cost to revert.
- **Greyed-out fields show stale values before first save** → The OnValidate clear ensures values are wiped when the toggle is turned off, so stale data cannot persist after save.
- **Compound Editable expressions are verbose** → Acceptable — there are only 5 such fields and the pattern is already established on this page.
