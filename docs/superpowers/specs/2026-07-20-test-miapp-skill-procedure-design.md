# Test MIAPP Skill Procedure Design

## Goal

Add a minimal public API change to the W1 VAT VIES declaration report for MIAPP skill testing.

## Design

Add a parameterless global procedure named `TestMiAppSkill` to report 19, `"VAT- VIES Declaration Tax Auth"`, in:

`src\Layers\W1\BaseApp\Finance\VAT\Reporting\VATVIESDeclarationTaxAuth.Report.al`

The procedure has an empty body. It does not read or modify report state, call dependencies, return a value, or raise errors.

## Placement

Place the procedure beside the existing global `InitializeRequest` procedure.

## Validation

Compile the W1 BaseApp to verify that the new public procedure is valid AL and introduces no diagnostics.
