codeunit 134818 "ERM CA G/L Autotransfer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cost Accounting] [Auto Transfer from G/L]
        isInitialized := false;
    end;

    var
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestAutotransferFromGLOn()
    begin
        // Check "Autotransfer" option in Cost Accounting Setup and verify that GL entries are transfered to Cost Accounting.

        AutotransferFromGL(true);

        // Verify:
        LibraryCostAccounting.ValidateEntriesTransfered();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAutotransferFromGLOff()
    begin
        // Un-Check "Autotransfer" option in Cost Accounting Setup and verify that GL entries are not transfered to Cost Accounting.

        AutotransferFromGL(false);

        // Verify:
        asserterror LibraryCostAccounting.ValidateEntriesTransfered();
    end;

    [Normal]
    local procedure TurnOffAlignment()
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        CostAccountingSetup.Get();
        CostAccountingSetup.Validate("Align G/L Account", CostAccountingSetup."Align G/L Account"::"No Alignment");
        CostAccountingSetup.Validate("Align Cost Center Dimension", CostAccountingSetup."Align Cost Center Dimension"::"No Alignment");
        CostAccountingSetup.Validate("Align Cost Object Dimension", CostAccountingSetup."Align Cost Object Dimension"::"No Alignment");
        CostAccountingSetup.Modify(true);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM CA G/L Autotransfer");
        TurnOffAlignment();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM CA G/L Autotransfer");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM CA G/L Autotransfer");
    end;

    [Normal]
    local procedure AutotransferFromGL(Autotransfer: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        // Setup:
        Initialize();
        LibraryCostAccounting.SetAutotransferFromGL(Autotransfer);
        LibraryCostAccounting.SetupGLAccount(GLAccount);

        // Excercise:
        LibraryCostAccounting.PostGenJournalLine(GLAccount."No.");
    end;
}

