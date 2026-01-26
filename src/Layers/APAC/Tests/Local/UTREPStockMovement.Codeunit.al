codeunit 141072 "UT REP Stock Movement"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report] [Stock Movement]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        DocumentNoCap: Label 'Item_Ledger_Entry__Document_No__';
        EntryTypeCap: Label 'Item_Ledger_Entry__Entry_Type_';
        ItemNoCap: Label 'Item__No__';
        LocationCodeCap: Label 'Item_Ledger_Entry__Location_Code_';
        OpeningBalanceCap: Label 'OpeningBalance';
        OpeningBalance2Cap: Label 'OpeningBalance_Control1500033';
        TotalQuantityCap: Label 'TotalQuantity';
        TotalPositiveCap: Label 'TotalPos';
        TotalNegativeCap: Label 'TotalNeg';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";

    [HandlerFunctions('StockMovementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemStockMovement()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO] validate Item - OnAfterGetRecord Trigger of Report - 28022 Stock Movement with blank Date Filter.

        // Setup.
        Initialize();
        CreateItemLedgerEntry(ItemLedgerEntry, CreateItem(0D), ItemLedgerEntry."Entry Type"::Sale, 0, 0D);  // Using 0 for Quantity and blank for Posting Date.
        EnqueueValuesForStockMovementRequestPageHandler(ItemLedgerEntry."Item No.", 0D);  // Using blank for Date Filter.

        // Exercise & Verify.
        RunAndVerifyStockMovementReport(ItemLedgerEntry, 0, 0, 0, 0, 0);  // Using 0 for Quantity,PositiveValue,NegativeValue,OpeningBalance and OpeningBalance2.
    end;

    [HandlerFunctions('StockMovementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemWithDateFilterStockMovement()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntry2: Record "Item Ledger Entry";
        NetChange: Decimal;
    begin
        // [SCENARIO] validate Item - OnAfterGetRecord Trigger of Report - 28022 Stock Movement with Date Filter.

        // Setup.
        Initialize();
        CreateItemLedgerEntry(ItemLedgerEntry, CreateItem(WorkDate()), ItemLedgerEntry."Entry Type"::Output, 0, WorkDate());  // Using 0 for Quantity and WORKDATE for Posting Date.
        EnqueueValuesForStockMovementRequestPageHandler(ItemLedgerEntry."Item No.", WorkDate());  // Using WORKDATE for Date Filter.
        CreateItemLedgerEntry(
          ItemLedgerEntry2, ItemLedgerEntry."Item No.", ItemLedgerEntry."Entry Type"::Sale, LibraryRandom.RandDec(10, 2),
          CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'M>', WorkDate()));  // Using random for Quantity and as required by the test case using a date earlier than WORKDATE as Posting Date.
        NetChange := GetNetChangeFromItem(ItemLedgerEntry."Item No.");

        // Exercise & Verify.
        RunAndVerifyStockMovementReport(ItemLedgerEntry, 0, 0, 0, NetChange, NetChange);  // Using 0 for Quantity,PositiveValue and NegativeValue.
    end;

    [HandlerFunctions('StockMovementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecItemLedgEntryWithNegQtyStockMovement()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        NetChange: Decimal;
    begin
        // [SCENARIO] validate Item Ledger Entry - OnAfterGetRecord Trigger of Report - 28022 Stock Movement with Negative Quantity.

        // Setup.
        Initialize();
        CreateItemLedgerEntry(
          ItemLedgerEntry, CreateItem(WorkDate()), ItemLedgerEntry."Entry Type"::Consumption, -LibraryRandom.RandDec(10, 2), WorkDate());  // Using random for Quantity and WORKDATE for Posting Date.
        EnqueueValuesForStockMovementRequestPageHandler(ItemLedgerEntry."Item No.", WorkDate());  // Using WORKDATE for Date Filter.
        NetChange := GetNetChangeFromItem(ItemLedgerEntry."Item No.");

        // Exercise & Verify.
        RunAndVerifyStockMovementReport(ItemLedgerEntry, NetChange, 0, NetChange, 0, NetChange);  // Using 0 for Quantity and NegativeValue.
    end;

    [HandlerFunctions('StockMovementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecItemLedgEntryWithPosQtyStockMovement()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO] validate Item Ledger Entry - OnAfterGetRecord Trigger of Report - 28022 Stock Movement with Positive Quantity.
        PositiveQuantityOnStockMovementReport(ItemLedgerEntry."Entry Type"::Transfer);
    end;

    [HandlerFunctions('StockMovementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecItemLedgEntryTypePurchStockMovement()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO] validate Item Ledger Entry - OnAfterGetRecord Trigger of Report - 28022 Stock Movement with Entry Type as Purchase.
        PositiveQuantityOnStockMovementReport(ItemLedgerEntry."Entry Type"::Purchase);
    end;

    local procedure PositiveQuantityOnStockMovementReport(EntryType: Enum "Item Ledger Entry Type")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        NetChange: Decimal;
    begin
        // Setup.
        Initialize();
        CreateItemLedgerEntry(ItemLedgerEntry, CreateItem(WorkDate()), EntryType, LibraryRandom.RandDec(10, 2), WorkDate());  // Using random for Quantity and WORKDATE for Posting Date.
        EnqueueValuesForStockMovementRequestPageHandler(ItemLedgerEntry."Item No.", WorkDate());  // Using WORKDATE for Date Filter.
        NetChange := GetNetChangeFromItem(ItemLedgerEntry."Item No.");

        // Exercise & Verify.
        RunAndVerifyStockMovementReport(ItemLedgerEntry, NetChange, NetChange, 0, 0, NetChange);  // Using 0 for NegativeValue and OpeningBalance.
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateItem(DateFilter: Date): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item."Date Filter" := DateFilter;
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure CreateItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; Quantity: Decimal; PostingDate: Date)
    var
        ItemLedgerEntry2: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry2.FindLast();
        ItemLedgerEntry."Entry No." := ItemLedgerEntry2."Entry No." + 1;
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry."Posting Date" := PostingDate;
        ItemLedgerEntry."Entry Type" := EntryType;
        ItemLedgerEntry."Location Code" := LibraryUTUtility.GetNewCode10();
        ItemLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        ItemLedgerEntry.Quantity := Quantity;
        ItemLedgerEntry.Insert();
    end;

    local procedure EnqueueValuesForStockMovementRequestPageHandler(ItemNo: Code[20]; PostingDate: Date)
    begin
        // Enqueue values for StockMovementRequestPageHandler.
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(PostingDate);
    end;

    local procedure GetNetChangeFromItem(ItemNo: Code[20]): Decimal
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.CalcFields("Net Change");
        exit(Item."Net Change");
    end;

    local procedure RunAndVerifyStockMovementReport(ItemLedgerEntry: Record "Item Ledger Entry"; Quantity: Decimal; PositiveValue: Decimal; NegativeValue: Decimal; OpeningBalance: Decimal; OpeningBalance2: Decimal)
    begin
        // Exercise.
        REPORT.Run(REPORT::"Stock Movement");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemNoCap, ItemLedgerEntry."Item No.");
        LibraryReportDataset.AssertElementWithValueExists(DocumentNoCap, ItemLedgerEntry."Document No.");
        LibraryReportDataset.AssertElementWithValueExists(EntryTypeCap, Format(ItemLedgerEntry."Entry Type"));
        LibraryReportDataset.AssertElementWithValueExists(LocationCodeCap, ItemLedgerEntry."Location Code");
        LibraryReportDataset.AssertElementWithValueExists(TotalQuantityCap, Quantity);
        LibraryReportDataset.AssertElementWithValueExists(TotalPositiveCap, PositiveValue);
        LibraryReportDataset.AssertElementWithValueExists(TotalNegativeCap, NegativeValue);
        LibraryReportDataset.AssertElementWithValueExists(OpeningBalanceCap, OpeningBalance);
        LibraryReportDataset.AssertElementWithValueExists(OpeningBalance2Cap, OpeningBalance2);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StockMovementRequestPageHandler(var StockMovement: TestRequestPage "Stock Movement")
    var
        No: Variant;
        DateFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(DateFilter);
        StockMovement.Item.SetFilter("No.", No);
        StockMovement.Item.SetFilter("Date Filter", Format(DateFilter));
        StockMovement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

