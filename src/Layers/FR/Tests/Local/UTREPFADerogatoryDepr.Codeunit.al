codeunit 144026 "UT REP FA Derogatory Depr."
{
    // Test for feature FADD - Fixed Asset Derogatory Depreciation.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DialogErr: Label 'Dialog';

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportCalculateDepreciationError()
    begin
        // Purpose of the test is to validate OnPreReport trigger of Report ID - 5692 Calculate Depreciation.
        // Setup.
        Initialize();
        CreateDepreciationBook();

        // Exercise.
        asserterror REPORT.Run(REPORT::"Calculate Depreciation");

        // Verify: Verify expected error code, actual error: Depreciation cannot be posted on depreciation book because it is set up as derogatory.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('CancelFALedgerEntriesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportCancelFALedgerEntriesError()
    begin
        // Purpose of the test is to validate OnPreReport trigger of Report ID - 5688 Cancel FA Ledger Entries.

        // Run Report Cancel FA Ledger Entries with Disposal - FALSE.
        OnPreReportCancelFALedgerEntries(false);
    end;

    [Test]
    [HandlerFunctions('CancelFALedgerEntriesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportCancelDisposalFALedgerEntriesError()
    begin
        // Purpose of the test is to validate OnPreReport trigger of Report ID - 5688 Cancel FA Ledger Entries.

        // Run Report Cancel FA Ledger Entries with Disposal - TRUE.
        OnPreReportCancelFALedgerEntries(true);
    end;

    local procedure OnPreReportCancelFALedgerEntries(Disposal: Boolean)
    begin
        // Setup.
        Initialize();
        CreateDepreciationBook();
        LibraryVariableStorage.Enqueue(Disposal);  // Required inside CancelFALedgerEntriesRequestPageHandler.

        // Exercise.
        asserterror REPORT.Run(REPORT::"Cancel FA Ledger Entries");

        // Verify: You cannot cancel FA entries that were posted to a derogatory depreciation book. Instead you must cancel the FA entries posted to the depreciation book integrated with G/L.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('CopyFAEntriesToGLBudgetRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordFixedAssetCopyFAEntriesToGLBudget()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLBudgetName: Code[10];
    begin
        // Purpose of the test is to validate Trigger Fixed Asset - OnAfterGetRecord of Report ID - 5684 Copy FA Entries to G/L Budget.

        // Setup: Create FA Depreciation Book with G/L Budget.
        Initialize();
        GLBudgetName := CreateGLBudgetName();
        CreateFAPostingGroup(FAPostingGroup);
        CreateFADepreciationBook(FADepreciationBook, FAPostingGroup.Code);
        CreateFALedgerEntry(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code");

        // Enqueue Required inside CopyFAEntriesToGLBudgetRequestPageHandler.
        LibraryVariableStorage.Enqueue(GLBudgetName);
        LibraryVariableStorage.Enqueue(FADepreciationBook."FA No.");

        // Exercise.
        REPORT.Run(REPORT::"Copy FA Entries to G/L Budget");

        // Verify: Verify G/L Budget Entry Created with G/L Account No. as Derogatory Account of FA Posting Group.
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName);
        GLBudgetEntry.FindFirst();
        GLBudgetEntry.TestField("G/L Account No.", FAPostingGroup."Derogatory Account");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateDepreciationBook(): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Code := LibraryUTUtility.GetNewCode10();
        DepreciationBook."Derogatory Calculation" := LibraryUTUtility.GetNewCode10();
        DepreciationBook.Insert();
        LibraryVariableStorage.Enqueue(DepreciationBook.Code);  // Required inside CalculateDepreciationRequestPageHandler or CancelFALedgerEntriesRequestPageHandler or CopyFAEntriesToGLBudgetRequestPageHandler.
        exit(DepreciationBook.Code);
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset."No." := LibraryUTUtility.GetNewCode();
        FixedAsset.Insert();
        exit(FixedAsset."No.");
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

    local procedure CreateGLBudgetName(): Code[10]
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        GLBudgetName.Name := LibraryUTUtility.GetNewCode10();
        GLBudgetName.Insert();
        exit(GLBudgetName.Name);
    end;

    local procedure CreateFAPostingGroup(var FAPostingGroup: Record "FA Posting Group")
    begin
        FAPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        FAPostingGroup."Derogatory Account" := LibraryUTUtility.GetNewCode();
        FAPostingGroup.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateDepreciationRequestPageHandler(var CalculateDepreciation: TestRequestPage "Calculate Depreciation")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        CalculateDepreciation.DepreciationBook.SetValue(DocumentNo);
        CalculateDepreciation.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
        CopyFAEntriesToGLBudget.Derogatory.SetValue(true);
        CopyFAEntriesToGLBudget.OK().Invoke();
    end;
}

