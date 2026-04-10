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
        IsInitialized: Boolean;
        TransactionNo: Integer;
        ConfirmAdjustQst: Label 'Do you want to fill the G/L Account No. field in VAT entries that are linked to G/L Entries?';


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

    [Test]
    procedure CallSetGLAccountNumberFromVATEntriesPage()
    var
        VATEntry: Record 254;
        VATEntriesPage: TestPage 315;
        GLAccountNo: array[4] of Code[20];
    begin
        // [SCENARIO] "Set G/L Account No." action is invoked from the "VAT Entries" page and the action is confirmed
        Initialize();

        // [GIVEN] 4 G/L Entry - VAT Entry Links, where two of them refer to VAT Entries whose G/L Account Number field is blank
        CreateVATEntriesGLEntriesWithLink(GLAccountNo, TransactionNo);

        // [GIVEN] The "VAT Entries" page is open
        VATEntriesPage.OpenView();

        // [WHEN] The "Set G/L Account No." action is run and confirmed in the confirm dialog
        LibraryVariableStorage.Enqueue(true); // Yes - for ConfirmHandlerSetGLAccountNo
        VATEntriesPage.SetGLAccountNo.Invoke();

        // [then] The G/L Account Number field is correctly set for all the test VAT Entries
        VATEntry.SetRange("Transaction No.", TransactionNo);
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

    [ConfirmHandler]
    procedure ConfirmHandlerSetGLAccountNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(FORMAT(ConfirmAdjustQst), Question, 'Wrong confirmation question');
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}