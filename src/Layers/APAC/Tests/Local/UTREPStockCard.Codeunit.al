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
        BalanceQtyLbl: Label 'BalanceQty';
        CostingMethodCap: Label 'CostingMethod';
        DialogErr: Label 'Dialog';
        OpeningStockAmountCap: Label 'OpeningStockAmount';
        OpeningStockCap: Label 'OpeningStock';
        ReceivedCostLbl: Label 'ReceivedCost';
        ReceivedQtyLbl: Label 'ReceivedQty';
        TotalBalanceAmountLbl: Label 'TotalBalanceAmount';

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

    [Test]
    [HandlerFunctions('StockCardRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReceivedQtySumsMultipleValueEntriesForSameILE()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        GroupTotals: Option Location,Item;
        FirstInvoiceQty: Decimal;
        SecondInvoiceQty: Decimal;
        UnitCost: Decimal;
        TotalInvoicedQty: Decimal;
        TotalCostAmount: Decimal;
    begin
        // [AI Test]
        // [SCENARIO] Stock Card report should sum ReceivedQty from all Value Entries for the same Item Ledger Entry
        // when multiple partial invoices are posted against a single purchase receipt.

        // [GIVEN] Random quantities for two partial invoices and a unit cost
        Initialize();
        FirstInvoiceQty := LibraryRandom.RandIntInRange(1, 10);
        SecondInvoiceQty := LibraryRandom.RandIntInRange(1, 10);
        UnitCost := LibraryRandom.RandDecInRange(10, 100, 2);
        TotalInvoicedQty := FirstInvoiceQty + SecondInvoiceQty;
        TotalCostAmount := TotalInvoicedQty * UnitCost;

        // [GIVEN] An Item Ledger Entry (purchase receipt) with FIFO costing for the total quantity
        CreatePurchaseReceiptItemLedgerEntry(ItemLedgerEntry, Item."Costing Method"::FIFO, TotalInvoicedQty);

        // [GIVEN] Two Value Entries for the same Item Ledger Entry simulating partial invoices
        CreateValueEntryWithInvoicedQty(ItemLedgerEntry."Entry No.", FirstInvoiceQty, FirstInvoiceQty * UnitCost);
        CreateValueEntryWithInvoicedQty(ItemLedgerEntry."Entry No.", SecondInvoiceQty, SecondInvoiceQty * UnitCost);

        EnqueueValuesForStockCardRequestPageHandler(ItemLedgerEntry."Item No.", GroupTotals::Location, WorkDate());

        // [WHEN] The Stock Card report is run
        REPORT.Run(REPORT::"Stock Card");

        // [THEN] ReceivedQty, ReceivedCost, Amount and the balances are derived from all Value Entries, not just the first one
        VerifyStockCardReceiptValues(TotalInvoicedQty, UnitCost, TotalCostAmount);
    end;

    [Test]
    [HandlerFunctions('StockCardRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReceivedQtySumsMultipleValueEntriesAverageCost()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        GroupTotals: Option Location,Item;
        FirstInvoiceQty: Decimal;
        SecondInvoiceQty: Decimal;
        UnitCost: Decimal;
        TotalInvoicedQty: Decimal;
        TotalCostAmount: Decimal;
    begin
        // [AI Test]
        // [SCENARIO] Stock Card report should sum ReceivedQty from all Value Entries for Average costing method.

        // [GIVEN] Random quantities for two partial invoices and a unit cost
        Initialize();
        FirstInvoiceQty := LibraryRandom.RandIntInRange(1, 10);
        SecondInvoiceQty := LibraryRandom.RandIntInRange(1, 10);
        UnitCost := LibraryRandom.RandDecInRange(10, 100, 2);
        TotalInvoicedQty := FirstInvoiceQty + SecondInvoiceQty;
        TotalCostAmount := TotalInvoicedQty * UnitCost;

        // [GIVEN] An Item Ledger Entry (purchase receipt) with Average costing for the total quantity
        CreatePurchaseReceiptItemLedgerEntry(ItemLedgerEntry, Item."Costing Method"::Average, TotalInvoicedQty);

        // [GIVEN] Two Value Entries for the same Item Ledger Entry simulating partial invoices
        CreateValueEntryWithInvoicedQty(ItemLedgerEntry."Entry No.", FirstInvoiceQty, FirstInvoiceQty * UnitCost);
        CreateValueEntryWithInvoicedQty(ItemLedgerEntry."Entry No.", SecondInvoiceQty, SecondInvoiceQty * UnitCost);

        EnqueueValuesForStockCardRequestPageHandler(ItemLedgerEntry."Item No.", GroupTotals::Location, WorkDate());

        // [WHEN] The Stock Card report is run
        REPORT.Run(REPORT::"Stock Card");

        // [THEN] ReceivedQty, ReceivedCost, Amount and the balances are derived from all Value Entries
        VerifyStockCardReceiptValues(TotalInvoicedQty, UnitCost, TotalCostAmount);
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

    local procedure CreatePurchaseReceiptItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; CostingMethod: Enum "Costing Method"; Quantity: Decimal)
    var
        LastItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if LastItemLedgerEntry.FindLast() then;
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := LastItemLedgerEntry."Entry No." + 1;
        ItemLedgerEntry."Item No." := CreateItem(CostingMethod);
        ItemLedgerEntry."Location Code" := CreateLocation();
        ItemLedgerEntry.Quantity := Quantity;
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Purchase;
        ItemLedgerEntry."Posting Date" := WorkDate();
        ItemLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        ItemLedgerEntry.Insert();
    end;

    local procedure CreateValueEntryWithInvoicedQty(ItemLedgerEntryNo: Integer; InvoicedQuantity: Decimal; CostAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
        LastValueEntry: Record "Value Entry";
    begin
        if LastValueEntry.FindLast() then;
        ValueEntry.Init();
        ValueEntry."Entry No." := LastValueEntry."Entry No." + 1;
        ValueEntry."Item Ledger Entry No." := ItemLedgerEntryNo;
        ValueEntry."Invoiced Quantity" := InvoicedQuantity;
        ValueEntry."Cost Amount (Actual)" := CostAmountActual;
        if InvoicedQuantity <> 0 then
            ValueEntry."Cost per Unit" := CostAmountActual / InvoicedQuantity;
        ValueEntry."Entry Type" := ValueEntry."Entry Type"::"Direct Cost";
        ValueEntry.Insert();
    end;

    local procedure VerifyStockCardReceiptValues(ExpectedReceivedQty: Decimal; ExpectedReceivedCost: Decimal; ExpectedAmount: Decimal)
    begin
        // The item and location are created by the test, so there is no opening stock and the balances equal the received values.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ReceivedQtyLbl, ExpectedReceivedQty);
        LibraryReportDataset.AssertElementWithValueExists(ReceivedCostLbl, ExpectedReceivedCost);
        LibraryReportDataset.AssertElementWithValueExists(AmountCap, ExpectedAmount);
        LibraryReportDataset.AssertElementWithValueExists(BalanceQtyLbl, ExpectedReceivedQty);
        LibraryReportDataset.AssertElementWithValueExists(TotalBalanceAmountLbl, ExpectedAmount);
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

