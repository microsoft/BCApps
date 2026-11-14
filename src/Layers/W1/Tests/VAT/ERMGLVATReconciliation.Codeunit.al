codeunit 134991 "ERM  G/L - VAT Reconciliation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [Report] [Reconciliation]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        IsInitialized: Boolean;
        TransactionNo: Integer;
        ConfirmAdjustQst: Label 'Do you want to fill the G/L Account No. field in VAT entries that are linked to G/L Entries?';


    [TransactionModel(TransactionModel::AutoCommit)]
    [Test]
    procedure VATEntrySetGLAccountNumberWithoutUI()
    var
        VATEntry: Record 254;
        GLAccountNo: array[4] of Code[20];
    begin
        // [SCENARIO] The SetGLAccountNo function correctly sets the G/L Account Number field for VAT Entries when it is called with the WithUI parameter set to false
        Initialize();

        // [GIVEN] 4 G/L Entry - VAT Entry Links, where two of them refer to VAT Entries whose G/L Account Number field is blank
        CreateVATEntriesGLEntriesWithLink(GLAccountNo, TransactionNo);
        VATEntry.SetRange("Transaction No.", TransactionNo);

        // [WHEN] Calling the SetGLAccountNo function with the parameter WithUI set to false
        VATEntry.SetGLAccountNo(false);

        // [then] The G/L Account Number field is correctly set for all the test VAT Entries
        VerifyGLAccountNoInVATEntries(VATEntry, GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerSetGLAccountNo')]
    procedure VATEntrySetGLAccountNumberWithUIConfirmNo()
    var
        VATEntry: Record 254;
        GLAccountNo: array[4] of Code[20];
    begin
        // [SCENARIO] The SetGLAccountNo function is called with the parameter WithUI set to true, but the action is declined in the confirm dialog
        Initialize();

        // [GIVEN] 4 G/L Entry - VAT Entry Links, where two of them refer to VAT Entries whose G/L Account Number field is blank
        CreateVATEntriesGLEntriesWithLink(GLAccountNo, TransactionNo);
        VATEntry.SetRange("Transaction No.", TransactionNo);

        // [WHEN] The SetGLAccountNo function is called with the parameter WithUI set to true, but the action is declined in the confirm dialog
        LibraryVariableStorage.Enqueue(false); // No - for ConfirmHandlerSetGLAccountNo
        VATEntry.SetGLAccountNo(true);

        // [then] The G/L Account Number field remains unchanged for all the test VAT Entries
        GLAccountNo[3] := '';
        GLAccountNo[4] := '';
        VerifyGLAccountNoInVATEntries(VATEntry, GLAccountNo);
    end;

    [TransactionModel(TransactionModel::AutoCommit)]
    [Test]
    [HandlerFunctions('ConfirmHandlerSetGLAccountNo')]
    procedure VATEntrySetGLAccountNumberWithUIConfirmYes()
    var
        VATEntry: Record 254;
        GLAccountNo: array[4] of Code[20];
    begin
        // [SCENARIO] The SetGLAccountNo function is called with the parameter WithUI set to true and the action is confirmed in the confirm dialog
        Initialize();

        // [GIVEN] 4 G/L Entry - VAT Entry Links, where two of them refer to VAT Entries whose G/L Account Number field is blank
        CreateVATEntriesGLEntriesWithLink(GLAccountNo, TransactionNo);
        VATEntry.SetRange("Transaction No.", TransactionNo);

        // [WHEN] The SetGLAccountNo function is called with the parameter WithUI set to true and the action is confirmed in the confirm dialog
        LibraryVariableStorage.Enqueue(true); // Yes - for ConfirmHandlerSetGLAccountNo
        VATEntry.SetGLAccountNo(true);

        // [then] The G/L Account Number field is correctly set for all the test VAT Entries
        VerifyGLAccountNoInVATEntries(VATEntry, GLAccountNo);
    end;

    [TransactionModel(TransactionModel::AutoCommit)]
    [Test]
    procedure CallSetGLAccountNumberFromVATEntriesPageOnlyForSelection()
    var
        VATEntry: Record "VAT Entry";
        VATEntriesPage: TestPage "VAT Entries";
        GLAccountNo: array[4] of Code[20];
    begin
        // [SCENARIO 657911] "Set G/L Account No." action invoked from the "VAT Entries" page only processes the selected VAT entries
        Initialize();

        // [GIVEN] 4 G/L Entry - VAT Entry Links, where VAT Entries "3" and "4" have a blank G/L Account Number
        CreateVATEntriesGLEntriesWithLink(GLAccountNo, TransactionNo);

        // [GIVEN] The "VAT Entries" page is open and VAT Entry "3" is selected
        VATEntry.SetRange("Transaction No.", TransactionNo);
        VATEntry.FindSet();
        VATEntry.Next(2);
        VATEntriesPage.OpenView();
        VATEntriesPage.GoToRecord(VATEntry);

        // [WHEN] The "Set G/L Account No." action is run
        VATEntriesPage.SetGLAccountNo.Invoke();
        VATEntriesPage.Close();

        // [THEN] The G/L Account Number field is set for VAT Entry "3", VAT Entry "4" that was not selected keeps a blank G/L Account Number
        GLAccountNo[4] := '';
        VerifyGLAccountNoInVATEntries(VATEntry, GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('GLVATReconciliationRequestPageHandler')]
    procedure GLVATReconciliationAccountTotalingDoesNotAdjustVATEntries()
    var
        VATEntry: Record "VAT Entry";
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        GLAccountNo: array[4] of Code[20];
        RequestPageXML: Text;
    begin
        // [SCENARIO 657911] "G/L - VAT Reconciliation" report does not adjust VAT entries for VAT statement lines of type "Account Totaling"
        Initialize();

        // [GIVEN] 4 G/L Entry - VAT Entry Links, where VAT Entries "3" and "4" have a blank G/L Account Number
        CreateVATEntriesGLEntriesWithLink(GLAccountNo, TransactionNo);

        // [GIVEN] VAT Statement "V" with a single "Account Totaling" line
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementTemplate.Name, VATStatementName.Name);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"Account Totaling");
        VATStatementLine.Validate("Account Totaling", GLAccountNo[1]);
        VATStatementLine.Modify(true);

        // [WHEN] Run report "G/L - VAT Reconciliation" for VAT Statement "V"
        Commit();
        VATStatementName.SetRecFilter();
        RequestPageXML := Report.RunRequestPage(Report::"G/L - VAT Reconciliation", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"G/L - VAT Reconciliation", VATStatementName, RequestPageXML);

        // [THEN] No confirmation to adjust VAT entries is raised and VAT Entries "3" and "4" keep a blank G/L Account Number
        GLAccountNo[3] := '';
        GLAccountNo[4] := '';
        VATEntry.SetRange("Transaction No.", TransactionNo);
        VerifyGLAccountNoInVATEntries(VATEntry, GLAccountNo);
    end;

    [TransactionModel(TransactionModel::AutoCommit)]
    [Test]
    procedure SetGLAccountNoEventPreApprovalSkipsConfirm()
    var
        VATEntry: Record "VAT Entry";
        GLVATReconAdjustSubs: Codeunit "GL VAT Recon. Adjust Subs.";
        GLAccountNo: array[4] of Code[20];
    begin
        // [SCENARIO 640489] When a subscriber to OnBeforeSetGLAccountNo pre-approves the adjustment, the confirm is skipped and processing continues, so the report can run unattended
        Initialize();

        // [GIVEN] 4 G/L Entry - VAT Entry Links, where two of them refer to VAT Entries whose G/L Account Number field is blank
        CreateVATEntriesGLEntriesWithLink(GLAccountNo, TransactionNo);
        VATEntry.SetRange("Transaction No.", TransactionNo);

        // [GIVEN] A subscriber that pre-approves the adjustment via OnBeforeSetGLAccountNo (Response := true)
        BindSubscription(GLVATReconAdjustSubs);

        // [WHEN] The SetGLAccountNo function is called with WithUI set to true (which also requests a confirm) and no ConfirmHandler is registered
        VATEntry.SetGLAccountNo(true);
        UnbindSubscription(GLVATReconAdjustSubs);

        // [THEN] The G/L Account Number field is correctly set for all the test VAT Entries, without any confirm being raised
        VerifyGLAccountNoInVATEntries(VATEntry, GLAccountNo);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM  G/L - VAT Reconciliation");
        LibraryVariableStorage.Clear();
        TransactionNo -= 1;

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM  G/L - VAT Reconciliation");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM  G/L - VAT Reconciliation");
    end;

    local procedure CreateMockGLEntry(var GLEntry: Record 17; GLAccountNo: Code[20]; TransactionNo: Integer)
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FIELDNO("Entry No."));
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Transaction No." := TransactionNo;
        GLEntry.Insert();
    end;

    local procedure CreateMockVATEntry(var VATEntry: Record 254; GLAccountNo: Code[20]; TransactionNo: Integer)
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FIELDNO("Entry No."));
        VATEntry."G/L Acc. No." := GLAccountNo;
        VATEntry."Transaction No." := TransactionNo;
        VATEntry.Insert();
    end;

    local procedure CreateMockGLEntryVATEntryLink(GLEntryGLAccountNo: Code[20]; VATEntryGLAccountNo: Code[20]; TransactionNo: Integer)
    var
        GLEntry: Record 17;
        VATEntry: Record 254;
        GLEntryVATEntryLink: Record 253;
    begin
        CreateMockGLEntry(GLEntry, GLEntryGLAccountNo, TransactionNo);
        CreateMockVATEntry(VATEntry, VATEntryGLAccountNo, TransactionNo);
        GLEntryVATEntryLink.InsertLink(GLEntry."Entry No.", VATEntry."Entry No.");
    end;

    local procedure CreateVATEntriesGLEntriesWithLink(var GLAccountNo: array[4] of Code[20]; TransactionNo: Integer)
    var
        index: Integer;
    begin
        // create 4 G/L Accounts and store their IDs in an array
        for index := 1 to 4 do
            GLAccountNo[index] := LibraryERM.CreateGLAccountNo();

        // create G/L Entry - VAT Entry links, but for two of the links don't store the G/L Account No. in the VAT Entry objects
        for index := 1 to 2 do
            CreateMockGLEntryVATEntryLink(GLAccountNo[index], GLAccountNo[index], TransactionNo);
        for index := 3 to 4 do
            CreateMockGLEntryVATEntryLink(GLAccountNo[index], '', TransactionNo);
    end;

    local procedure VerifyGLAccountNoInVATEntries(var VATEntry: Record 254; GLAccountNo: array[4] of Code[20])
    var
        index: Integer;
        arrayLength: Integer;
    begin
        // remove all filters for the G/L Account Number field in the VAT Entry table
        VATEntry.SetRange("G/L Acc. No.");

        arrayLength := ArrayLen(GLAccountNo);
        Assert.RecordCount(VATEntry, arrayLength);

        VATEntry.FindSet();
        for index := 1 to arrayLength do begin
            VATEntry.TestField("G/L Acc. No.", GLAccountNo[index]);
            VATEntry.Next();
        end;
    end;

    [RequestPageHandler]
    procedure GLVATReconciliationRequestPageHandler(var GLVATReconciliation: TestRequestPage "G/L - VAT Reconciliation")
    begin
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerSetGLAccountNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(FORMAT(ConfirmAdjustQst), Question, 'Wrong confirmation question');
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}