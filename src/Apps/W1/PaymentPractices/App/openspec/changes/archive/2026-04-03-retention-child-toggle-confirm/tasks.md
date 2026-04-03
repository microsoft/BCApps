## 1. Table: Add shared confirmation label

- [x] 1.1 Add a shared Label variable in T689 for the child-toggle confirmation message (e.g., `ClearDependentFieldQst`)

## 2. Table: Update existing OnValidate triggers

- [x] 2.1 Update `Retention in Specific Circs.` OnValidate to show confirmation dialog before clearing `Retention Circs. Desc.`, skip dialog if desc is already empty, revert toggle on cancel
- [x] 2.2 Update `Terms Fairness Practice` OnValidate — add confirmation dialog before clearing `Terms Fairness Desc.`, skip dialog if desc is already empty, revert toggle on cancel

## 3. Table: Add new OnValidate trigger

- [x] 3.1 Add OnValidate on `Release Within Prescribed Days` with confirmation dialog before clearing `Prescribed Days Desc.`, skip dialog if desc is already empty, revert toggle on cancel

## 4. Validation

- [x] 4.1 Build the app and verify no compilation errors
- [x] 4.2 Test each toggle: confirm clears field, cancel reverts toggle
- [x] 4.3 Test no-dialog path: toggle off when dependent field is already empty
- [x] 4.4 Update any existing tests to handle new ConfirmHandler for these toggles
