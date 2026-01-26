codeunit 141070 "UT REP Stock Card"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report] [Stock Card] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountCap: Label 'Amount';
        CostingMethodCap: Label 'CostingMethod';
        DialogErr: Label 'Dialog';
        OpeningStockAmountCap: Label 'OpeningStockAmount';
        OpeningStockCap: Label 'OpeningStock';

    [Test]
    [HandlerFunctions('StockCardRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportStockCardError()
    var
        GroupTotals: Option Location,Item;
    begin
        // [SCENARIO] validate OnPreReport Trigger of Report - 14311 Stock Card for blank Date Filter.

        // Setup.
        Initialize();
        EnqueueValuesForStockCardRequestPageHandler('', GroupTotals::Location, 0D);  // Enqueue blank as Item No. and 0D as Date Filter for StockCardRequestPageHandler.

        // Exercise.
        asserterror REPORT.Run(REPORT::"Stock Card");

        // Verify: Verify expected error code,actual error: "Please enter the Date filter.".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('StockCardRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemLedgerEntryFIFOStockCard()
    var
        Item: Record Item;
        GroupTotals: Option Location,Item;
    begin
        // [SCENARIO] validate Item Ledger Entry - OnAfterGetRecord Trigger of Report - 14311 Stock Card with Costing Method as FIFO.
        OnAfterGetRecordItemLedgerEntryStockCard(Item."Costing Method"::FIFO, GroupTotals::Location);
    end;

    [Test]
    [HandlerFunctions('StockCardRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemLedgerEntryAverageStockCard()
    var
        Item: Record Item;
        GroupTotals: Option Location,Item;
    begin
        // [SCENARIO] validate Item Ledger Entry - OnAfterGetRecord Trigger of Report - 14311 Stock Card with Costing Method as Average.
        OnAfterGetRecordItemLedgerEntryStockCard(Item."Costing Method"::Average, GroupTotals::Location);
    end;

    [Test]
    [HandlerFunctions('StockCardRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemLedgerEntryStandardStockCard()
    var
        Item: Record Item;
        GroupTotals: Option Location,Item;
    begin
        // [SCENARIO] validate Item Ledger Entry - OnAfterGetRecord Trigger of Report - 14311 Stock Card with Costing Method as Standard.
        OnAfterGetRecordItemLedgerEntryStockCard(Item."Costing Method"::Standard, GroupTotals::Item);
    end;

    [Test]
    [HandlerFunctions('StockCardRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemLedgerEntryLIFOStockCard()
    var
        Item: Record Item;
        GroupTotals: Option Location,Item;
    begin
        // [SCENARIO] validate Item Ledger Entry - OnAfterGetRecord Trigger of Report - 14311 Stock Card with Costing Method as LIFO.
        OnAfterGetRecordItemLedgerEntryStockCard(Item."Costing Method"::LIFO, GroupTotals::Item);
    end;

    [Test]
    [HandlerFunctions('StockCardRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemLedgerEntrySpecificStockCard()
    var
        Item: Record Item;
        GroupTotals: Option Location,Item;
    begin
        // [SCENARIO] validate Item Ledger Entry - OnAfterGetRecord Trigger of Report - 14311 Stock Card with Costing Method as Specific.
        OnAfterGetRecordItemLedgerEntryStockCard(Item."Costing Method"::Specific, GroupTotals::Item);
    end;

    local procedure OnAfterGetRecordItemLedgerEntryStockCard(CostingMethod: Enum "Costing Method"; GroupTotals: Option)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Setup.
        Initialize();
        CreateItemLedgerEntries(ItemLedgerEntry, CostingMethod);
        CreateValueEntry(ItemLedgerEntry."Entry No.");
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        EnqueueValuesForStockCardRequestPageHandler(ItemLedgerEntry."Item No.", GroupTotals, WorkDate());  // Enqueue WORKDATE as Posting Date for StockCardRequestPageHandler.

        // Exercise & Verify.
        RunAndVerifyStockCardReport(
          CostingMethodCap, UpperCase(Format(CostingMethod)), ItemLedgerEntry.Quantity, ItemLedgerEntry."Cost Amount (Actual)");
    end;

    [Test]
    [HandlerFunctions('StockCardRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemApplicationEntryStockCard()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        GroupTotals: Option Location,Item;
        Quantity: Decimal;
        CostPerUnit: Decimal;
    begin
        // [SCENARIO] validate Item Application Entry - OnAfterGetRecord Trigger of Report - 14311 Stock Card.

        // Setup.
        Initialize();
        CreateItemLedgerEntries(ItemLedgerEntry, Item."Costing Method"::FIFO);
        Quantity := CreateItemApplicationEntry(ItemLedgerEntry."Entry No.");
        CostPerUnit := CreateValueEntry(ItemLedgerEntry."Entry No.");
        EnqueueValuesForStockCardRequestPageHandler(ItemLedgerEntry."Item No.", GroupTotals::Location, ItemLedgerEntry."Posting Date");  // Enqueue values for StockCardRequestPageHandler.

        // Exercise & Verify.
        RunAndVerifyStockCardReport(AmountCap, Quantity * CostPerUnit, -Quantity, -Quantity * CostPerUnit);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateItem(CostingMethod: Enum "Costing Method"): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item."Costing Method" := CostingMethod;
        Item.Insert();
        exit(Item."No.");
    end;

    [TransactionModel(TransactionModel::AutoRollback)]
    local procedure CreateItemApplicationEntry(ItemLedgerEntryNo: Integer): Decimal
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry."Item Ledger Entry No." := ItemLedgerEntryNo;
        ItemApplicationEntry."Inbound Item Entry No." := ItemLedgerEntryNo;
        ItemApplicationEntry."Posting Date" := WorkDate();
        ItemApplicationEntry.Quantity := LibraryRandom.RandDec(10, 2);
        ItemApplicationEntry.Insert();
        exit(ItemApplicationEntry.Quantity);
    end;

    local procedure CreateItemLedgerEntries(var ItemLedgerEntry2: Record "Item Ledger Entry"; CostingMethod: Enum "Costing Method")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.FindLast();
        CreateItemLedgerEntry(
          ItemLedgerEntry, CreateItem(CostingMethod), CreateLocation(), ItemLedgerEntry."Entry No." + 1, LibraryRandom.RandDec(10, 2),
          WorkDate());  // Using random for Quantity and WORKDATE for Posting Date.
        CreateItemLedgerEntry(
          ItemLedgerEntry2, ItemLedgerEntry."Item No.", ItemLedgerEntry."Location Code", ItemLedgerEntry."Entry No." + 1,
          -ItemLedgerEntry.Quantity, CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'M>', WorkDate()));  // As required by the test case using earlier date than WORKDATE as Posting Date.
    end;

    local procedure CreateItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; LocationCode: Code[10]; EntryNo: Integer; Quantity: Decimal; PostingDate: Date)
    begin
        ItemLedgerEntry."Entry No." := EntryNo;
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry.Quantity := Quantity;
        ItemLedgerEntry."Location Code" := LocationCode;
        ItemLedgerEntry."Posting Date" := PostingDate;
        ItemLedgerEntry.Insert();
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        Location.Code := LibraryUTUtility.GetNewCode10();
        Location.Insert();
        exit(Location.Code);
    end;

    local procedure CreateValueEntry(EntryNo: Integer): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry."Item Ledger Entry No." := EntryNo;
        ValueEntry."Cost Amount (Actual)" := LibraryRandom.RandDec(100, 2);
        ValueEntry."Cost per Unit" := LibraryRandom.RandDec(100, 2);
        ValueEntry.Insert();
        exit(ValueEntry."Cost per Unit");
    end;

    local procedure EnqueueValuesForStockCardRequestPageHandler(ItemNo: Code[20]; GroupTotals: Option; PostingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(GroupTotals);
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(PostingDate);
    end;

    local procedure RunAndVerifyStockCardReport(Caption: Text; ExpectedValue: Variant; ExpectedValue2: Decimal; ExpectedValue3: Decimal)
    begin
        // Exercise.
        REPORT.Run(REPORT::"Stock Card");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption, ExpectedValue);
        LibraryReportDataset.AssertElementWithValueExists(OpeningStockCap, ExpectedValue2);
        LibraryReportDataset.AssertElementWithValueExists(OpeningStockAmountCap, ExpectedValue3);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StockCardRequestPageHandler(var StockCard: TestRequestPage "Stock Card")
    var
        PostingDate: Variant;
        GroupTotals: Variant;
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(GroupTotals);
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(PostingDate);
        StockCard.GroupTotals.SetValue(GroupTotals);
        StockCard."Item Ledger Entry".SetFilter("Item No.", ItemNo);
        StockCard."Item Ledger Entry".SetFilter("Posting Date", Format(PostingDate));
        StockCard.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

