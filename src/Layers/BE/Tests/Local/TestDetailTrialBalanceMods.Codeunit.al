codeunit 144026 "Test Detail Trial Balance Mods"
{
    // // [FEATURE] [Report] [Detail Trial Balance]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('DetailTrialBalanceReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DetailedTrialBalancePrintAccountDetailsTrue()
    var
        GLAccount1: Record "G/L Account";
        GLAccount2: Record "G/L Account";
    begin
        // [SCENARIO 256526] Report 'Detail Trial Balance' is printed with PrintDetailsOnAllAccounts = true for G/L Accounts with different Print Details value

        // [GIVEN] G/L Account "A" has 'Print Details' = yes, G/L Account "A" has 'Print Details' = no, both with detailed G/L Entries
        CreateGLAccount(GLAccount1, true);
        CreateGLAccount(GLAccount2, false);
        GLAccount1.SetFilter("No.", '%1|%2', GLAccount1."No.", GLAccount2."No.");

        // [WHEN] Run report 'Detail Trial Balance' with PrintDetailsOnAllAccounts = TRUE
        RunDetailedTrialBalanceReport(GLAccount1, true);

        // [THEN] G/L Entries shown for both Accounts "A" and "B"
        VerifyGLEntryValues(GLAccount1."No.", GLAccount2."No.", true, true);
    end;

    [Test]
    [HandlerFunctions('DetailTrialBalanceReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DetailedTrialBalancePrintAccountDetailsFalse()
    var
        GLAccount1: Record "G/L Account";
        GLAccount2: Record "G/L Account";
    begin
        // [SCENARIO 256526] Report 'Detail Trial Balance' is printed with PrintDetailsOnAllAccounts = false for G/L Accounts with different Print Details value

        // [GIVEN] G/L Account "A" has 'Print Details' = yes, G/L Account "A" has 'Print Details' = no, both with detailed G/L Entries
        CreateGLAccount(GLAccount1, true);
        CreateGLAccount(GLAccount2, false);
        GLAccount1.SetFilter("No.", '%1|%2', GLAccount1."No.", GLAccount2."No.");

        // [WHEN] Run report 'Detail Trial Balance' with PrintDetailsOnAllAccounts = FALSE
        RunDetailedTrialBalanceReport(GLAccount1, false);

        // [THEN] G/L Entry is shown for G/L Account "A" and not shown for "B"
        VerifyGLEntryValues(GLAccount1."No.", GLAccount2."No.", true, false);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; PrintDetails: Boolean)
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Print Details", PrintDetails);
        GLAccount.Modify(true);
        MockGLEntry(GLAccount."No.");
    end;

    local procedure MockGLEntry(GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry.Description := GLAccountNo;
        GLEntry."Posting Date" := WorkDate();
        GLEntry.Insert();
    end;

    local procedure RunDetailedTrialBalanceReport(var GLAccount: Record "G/L Account"; PrintDetailsOnAllAccounts: Boolean)
    begin
        LibraryVariableStorage.Enqueue(PrintDetailsOnAllAccounts);
        REPORT.Run(REPORT::"Detail Trial Balance", true, false, GLAccount);
    end;

    local procedure VerifyGLEntryValues(GLAcc1: Code[20]; GLAcc2: Code[20]; PrintAccDet1: Boolean; PrintAccDet2: Boolean)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Name_GLAcc', GLAcc1);
        LibraryReportDataset.AssertElementWithValueExists('PrintAccountDetails', PrintAccDet1);
        LibraryReportDataset.SetRange('Name_GLAcc', GLAcc2);
        LibraryReportDataset.AssertElementWithValueExists('PrintAccountDetails', PrintAccDet2);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DetailTrialBalanceReqPageHandler(var DetailTrialBalanceRequestPage: TestRequestPage "Detail Trial Balance")
    begin
        DetailTrialBalanceRequestPage.PrintDetailsOnAllAccounts.SetValue(LibraryVariableStorage.DequeueBoolean());
        DetailTrialBalanceRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

