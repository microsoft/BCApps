codeunit 144000 "ERM NZ - Pages UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure DisabledAUFunctionalityOnGenLedgSetup()
    var
        GeneralLedgerSetup: TestPage "General Ledger Setup";
    begin
        // [FEATURE] [GST] [UI]
        // [SCENARIO 218213] The field "Enable GST (Australia)" is enabled should be disabled on page "General Ledger Setup"

        // [WHEN] Open page "General Ledger Setup"
        GeneralLedgerSetup.OpenEdit();

        // [THEN] The field "Enable GST (Australia)" is disabled
        Assert.IsFalse(GeneralLedgerSetup."Enable GST (Australia)".Enabled(), 'The field "Enable GST (Australia)" is enabled');
    end;
}

