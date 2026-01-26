codeunit 145301 "BAS Managament"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [BAS Calculation Sheet]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        CannotEditFieldErr: Label 'You cannot edit this field. Use the import function.';

    [Test]
    [Scope('OnPrem')]
    procedure BanOnSettingValue()
    var
        BASCalculationSheet: TestPage "BAS Calculation Sheet";
    begin
        // [SCENARIO 379595] Check the ban on setting the value in the field A1

        Initialize();

        // [GIVEN] Open BAS Calculation Sheet
        BASCalculationSheet.OpenNew();

        // [WHEN] Setting value in field A1.
        asserterror BASCalculationSheet.A1.SetValue(LibraryUtility.GenerateRandomText(10));

        // [THEN] Verify error message appeared: 'You cannot edit this field. Use the import function'
        Assert.ExpectedError(CannotEditFieldErr);
    end;

    local procedure Initialize()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Enable GST (Australia)" := true;
        GLSetup."BAS to be Lodged as a Group" := true;
        GLSetup."BAS Group Company" := true;
        GLSetup.Modify();
    end;
}
