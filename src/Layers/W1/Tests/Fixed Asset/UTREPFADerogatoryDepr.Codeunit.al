// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 134153 "UT REP FA Derogatory Depr."
{
    // [FEATURE] [Fixed Asset] [Derogatory]

    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        DialogErr: Label 'Dialog';

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnPreReportCalculateDepreciationError()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Calculate Depreciation rejects a derogatory depreciation book
        Initialize();

        // [GIVEN] A depreciation book configured as derogatory
        CreateDepreciationBook();

        // [WHEN] Run Calculate Depreciation
        asserterror REPORT.Run(REPORT::"Calculate Depreciation");

        // [THEN] The report raises a dialog error
        Assert.ExpectedErrorCode(DialogErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CancelFALedgerEntriesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnPreReportCancelFALedgerEntriesError()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Cancel FA Ledger Entries rejects a derogatory depreciation book
        Initialize();

        // [GIVEN] A derogatory depreciation book and disposal disabled
        CreateDepreciationBook();
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run Cancel FA Ledger Entries
        asserterror REPORT.Run(REPORT::"Cancel FA Ledger Entries");

        // [THEN] The report raises a dialog error
        Assert.ExpectedErrorCode(DialogErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CancelFALedgerEntriesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnPreReportCancelDisposalFALedgerEntriesError()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Cancel FA Ledger Entries rejects disposal for a derogatory depreciation book
        Initialize();

        // [GIVEN] A derogatory depreciation book and disposal enabled
        CreateDepreciationBook();
        LibraryVariableStorage.Enqueue(true);

        // [WHEN] Run Cancel FA Ledger Entries
        asserterror REPORT.Run(REPORT::"Cancel FA Ledger Entries");

        // [THEN] The report raises a dialog error
        Assert.ExpectedErrorCode(DialogErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CopyFAEntriesToGLBudgetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnAfterGetRecordFixedAssetCopyFAEntriesToGLBudget()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLBudgetName: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Copy FA Entries to G/L Budget uses the derogatory account
        Initialize();

        // [GIVEN] FA "FA" with a derogatory ledger entry and G/L budget "B"
        GLBudgetName := CreateGLBudgetName();
        CreateFAPostingGroup(FAPostingGroup);
        CreateFADepreciationBook(FADepreciationBook, FAPostingGroup.Code);
        CreateFALedgerEntry(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code");

        // [GIVEN] Report parameters for budget "B" and "FA"
        LibraryVariableStorage.Enqueue(GLBudgetName);
        LibraryVariableStorage.Enqueue(FADepreciationBook."FA No.");

        // [WHEN] Run Copy FA Entries to G/L Budget
        REPORT.Run(REPORT::"Copy FA Entries to G/L Budget");

        // [THEN] The budget entry uses the FA posting group's derogatory account
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName);
        GLBudgetEntry.FindFirst();
        GLBudgetEntry.TestField("G/L Account No.", FAPostingGroup."Derogatory Acc.");
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"UT REP FA Derogatory Depr.");
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"UT REP FA Derogatory Depr.");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"UT REP FA Derogatory Depr.");
    end;

    local procedure CreateDepreciationBook(): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Code := LibraryUTUtility.GetNewCode10();
        DepreciationBook."Derogatory Calc." := LibraryUTUtility.GetNewCode10();
        DepreciationBook.Insert();
        LibraryVariableStorage.Enqueue(DepreciationBook.Code);
        exit(DepreciationBook.Code);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FAPostingGroup: Code[20])
    begin
        FADepreciationBook."FA No." := CreateFixedAsset();
        FADepreciationBook."Depreciation Book Code" := CreateDepreciationBook();
        FADepreciationBook."FA Posting Group" := FAPostingGroup;
        FADepreciationBook.Insert();
    end;

    local procedure CreateFALedgerEntry(FANo: Code[20]; DepreciationBookCode: Code[10])
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FALedgerEntry2: Record "FA Ledger Entry";
    begin
        FALedgerEntry."Entry No." := 1;
        if FALedgerEntry2.FindLast() then
            FALedgerEntry."Entry No." := FALedgerEntry2."Entry No." + 1;
        FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::Derogatory;
        FALedgerEntry."FA No." := FANo;
        FALedgerEntry."Depreciation Book Code" := DepreciationBookCode;
        FALedgerEntry."Posting Date" := WorkDate();
        FALedgerEntry.Insert();
    end;

    local procedure CreateFAPostingGroup(var FAPostingGroup: Record "FA Posting Group")
    begin
        FAPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        FAPostingGroup."Derogatory Acc." := LibraryUTUtility.GetNewCode();
        FAPostingGroup.Insert();
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset."No." := LibraryUTUtility.GetNewCode();
        FixedAsset.Insert();
        exit(FixedAsset."No.");
    end;

    local procedure CreateGLBudgetName(): Code[10]
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        GLBudgetName.Name := LibraryUTUtility.GetNewCode10();
        GLBudgetName.Insert();
        exit(GLBudgetName.Name);
    end;

    [RequestPageHandler]
    procedure CalculateDepreciationRequestPageHandler(var CalculateDepreciation: TestRequestPage "Calculate Depreciation")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        CalculateDepreciation.DepreciationBook.SetValue(DocumentNo);
        CalculateDepreciation.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CancelFALedgerEntriesRequestPageHandler(var CancelFALedgerEntries: TestRequestPage "Cancel FA Ledger Entries")
    var
        CancelBook: Variant;
        Disposal: Variant;
    begin
        LibraryVariableStorage.Dequeue(CancelBook);
        LibraryVariableStorage.Dequeue(Disposal);
        CancelFALedgerEntries.CancelBook.SetValue(CancelBook);
        CancelFALedgerEntries.Disposal.SetValue(Disposal);
        CancelFALedgerEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CopyFAEntriesToGLBudgetRequestPageHandler(var CopyFAEntriesToGLBudget: TestRequestPage "Copy FA Entries to G/L Budget")
    var
        CopyToGLBudgetName: Variant;
        CopyDeprBook: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(CopyDeprBook);
        LibraryVariableStorage.Dequeue(CopyToGLBudgetName);
        LibraryVariableStorage.Dequeue(No);
        CopyFAEntriesToGLBudget.CopyDeprBook.SetValue(CopyDeprBook);
        CopyFAEntriesToGLBudget.CopyToGLBudgetName.SetValue(CopyToGLBudgetName);
        CopyFAEntriesToGLBudget."Fixed Asset".SetFilter("No.", No);
        CopyFAEntriesToGLBudget."TransferType[7]".SetValue(true);
        CopyFAEntriesToGLBudget.OK().Invoke();
    end;
}
