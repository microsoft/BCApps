## 1. Table: Retention toggle confirmation and clearing

- [x] 1.1 Add OnValidate trigger on `Has Constr. Contract Retention` in T689 that shows a confirmation dialog when toggled false, clears all retention child fields (41-58) on confirm, and reverts the toggle on cancel
- [x] 1.2 Verify existing child-toggle OnValidate triggers (Retention in Specific Circs., Std Retention Pct Used, Payment Terms Have Changed) still work correctly alongside the new parent trigger

## 2. Page: Grid layout on FastTab groups

- [x] 2.1 Wrap Qualifying Contracts fields in `grid(QualifyingContractsGrid) > group(QualifyingContractsInner) { ShowCaption = false }`
- [x] 2.2 Wrap Payment Terms fields in `grid(PaymentTermsGrid) > group(PaymentTermsInner) { ShowCaption = false }`
- [x] 2.3 Wrap Construction Contract Retention fields in `grid(RetentionGrid) > group(RetentionInner) { ShowCaption = false }`
- [x] 2.4 Wrap Payment Policies fields in `grid(PaymentPoliciesGrid) > group(PaymentPoliciesInner) { ShowCaption = false }`

## 3. Page: Flatten RetentionDetails and switch to Editable gating

- [x] 3.1 Remove the nested `RetentionDetails` group — move all its fields directly into the Construction Contract Retention group (inside the grid inner group)
- [x] 3.2 Add `Editable = Rec."Has Constr. Contract Retention"` on all retention child field controls (Ret. Clause Used in Contracts through Pct Retent. vs Gross Payments)
- [x] 3.3 Update compound Editable expressions for child-toggle fields: Retention Circs. Desc., Standard Retention Pct, Terms Fairness Desc., Prescribed Days Desc.

## 4. Page: MultiLine on text fields

- [x] 4.1 Add `MultiLine = true` on page field controls for: Standard Payment Terms Desc., Max Contr. Pmt. Period Info, Other Pmt. Terms Information, Dispute Resolution Process, Retention Circs. Desc., Terms Fairness Desc., Release Mechanism Desc., Prescribed Days Desc.

## 5. Validation

- [x] 5.1 Build the app and verify no compilation errors
- [x] 5.2 Publish to sandbox and verify single-column layout renders correctly on all groups
- [x] 5.3 Verify MultiLine text fields render acceptably inside grid controls
- [x] 5.4 Verify retention fields become non-editable when Has Constr. Contract Retention = false
- [x] 5.5 Verify confirmation dialog appears and fields clear when Has Constr. Contract Retention is toggled off
- [x] 5.6 Update any tests that assert retention fields are hidden (change to assert non-editable)
