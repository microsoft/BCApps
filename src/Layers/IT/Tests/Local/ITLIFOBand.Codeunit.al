codeunit 144194 "IT - LIFO Band"
{
    // Test for Costing Inventory:
    //  1. Verify LIFO Band is correct after running Calculate Year Costs.
    //  2. Receive and partially invoice purchase order, run Calculate Year Costs and verify item cost history
    //  3. Receive and invoice purchase order, run Calculate Year Costs and verify item cost history
    //  4. Receive purchase order without invoice, run Calculate Year Costs and verify item cost history
    //  5. Receive and partially invoice purchase order, run Calculate Year Costs and verify costs in Ledger Entry Details report
    // 
    // TFS_TS_ID = N/A
    // Cover Test cases for Sicily SE Merge BUG:
    // ---------------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                                     TFS ID
    // ---------------------------------------------------------------------------------------------------------------------------------------------
    // VerifyLIFOBandAfterRunningCalculateYearCosts                                                                                            7067
    // 
    // VerifyLIFOCostOnPartiallyInvoicedOrder                                                                                                  357921
    // VerifyLIFOCostOnFullyInvoicedOrder                                                                                                      357921
    // VerifyLIFOCostOnReceivedNotInvoicedOrder                                                                                                357921
    // ExpectedCostIsCorrectInLedgEntryDetailsReport                                                                                           357921

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";

    [Test]
    [HandlerFunctions('CalculateEndYearCostsHandler')]
    [Scope('OnPrem')]
    procedure VerifyLIFOBandAfterRunningCalculateYearCosts()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LifoBand: Record "Lifo Band";
        ItemCostingSetup: Record "Item Costing Setup";
        Quantity: Decimal;
        BiggerQuantity: Decimal;
    begin
        // Setup: Create Item, post Item Journal
        LibraryInventory.CreateItem(Item);
        Item.Validate("Inventory Valuation", Item."Inventory Valuation"::"Discrete LIFO");
        Item.Modify(true);

        Quantity := LibraryRandom.RandDec(10, 2);
        BiggerQuantity := LibraryRandom.RandDec(10, 2) + Quantity;
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        if not ItemCostingSetup.Get() then begin
            ItemCostingSetup.Init();
            ItemCostingSetup."Components Valuation" := ItemCostingSetup."Components Valuation"::"Average Cost";
            ItemCostingSetup.Insert();
        end;

        // Make the three lines in different year.
        CreateItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Purchase, Item."No.", CalcDate('<-1Y>', WorkDate()), Quantity);
        CreateItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Purchase, Item."No.", WorkDate(), BiggerQuantity);
        CreateItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", CalcDate('<+1Y>', WorkDate()), Quantity);

        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Exercise: Run Calculate End Year Costs for WORKDATE-1Y, WORKDATE & WORKDATE+1Y.
        CalculateEndYearCosts(CalcDate('<CY-1Y>', WorkDate()));
        CalculateEndYearCosts(CalcDate('<CY>', WorkDate()));
        CalculateEndYearCosts(CalcDate('<CY+1Y>', WorkDate()));

        // Verify: Verify the negative adjustment quantity is in second line with Competence Year = WORKDATE based on LIFO.
        LifoBand.SetRange("Item No.", Item."No.");
        LifoBand.SetRange("Competence Year", CalcDate('<CY-1Y>', WorkDate()));
        LifoBand.FindFirst();
        LifoBand.TestField("Absorbed Quantity", 0);

        LifoBand.SetRange("Competence Year", CalcDate('<CY>', WorkDate()));
        LifoBand.FindFirst();
        LifoBand.TestField("Absorbed Quantity", Quantity);
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsHandler')]
    [Scope('OnPrem')]
    procedure VerifyLIFOCostOnPartiallyInvoicedOrder()
    var
        Item: Record Item;
    begin
        CreateAndPostPartiallyInvoicedPurchaseOrder(Item);
        VerifyItemCostHistoryEntry(Item);
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsHandler')]
    [Scope('OnPrem')]
    procedure VerifyLIFOCostOnFullyInvoicedOrder()
    begin
        TestItemCostHistoryCalculation(true);
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsHandler')]
    [Scope('OnPrem')]
    procedure VerifyLIFOCostOnReceivedNotInvoicedOrder()
    begin
        TestItemCostHistoryCalculation(false);
    end;

    [Test]
    [HandlerFunctions('CalculateEndYearCostsHandler,LedgerEntryDetailsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExpectedCostIsCorrectInLedgEntryDetailsReport()
    var
        Item: Record Item;
    begin
        CreateAndPostPartiallyInvoicedPurchaseOrder(Item);

        LibraryVariableStorage.Enqueue(Item."No.");
        REPORT.Run(REPORT::"Ledger Entry Details");

        VerifyLedgerEntryDetailsReport(Item."No.");
    end;

    local procedure Initialize()
    var
        ItemCostHistory: Record "Item Cost History";
    begin
        ItemCostHistory.DeleteAll();
    end;

    local procedure CalculateEndYearCosts(ReferenceDate: Date)
    begin
        LibraryVariableStorage.Enqueue(ReferenceDate);
        REPORT.Run(REPORT::"Calculate End Year Costs");
    end;

    local procedure ChangeQtyToInvoiceInPurchaseOrder(PurchaseOrderNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseOrderLine(PurchaseLine, PurchaseOrderNo);
        PurchaseLine.Validate("Qty. to Invoice", LibraryRandom.RandInt(PurchaseLine.Quantity div 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostPartiallyInvoicedPurchaseOrder(var Item: Record Item)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        CreatePurchaseOrder(PurchaseHeader, Item);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        ChangeQtyToInvoiceInPurchaseOrder(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        CalculateEndYearCosts(CalcDate('<CY>', WorkDate()));
    end;

    local procedure CreateItemJournalLine(ItemJournalTemplateName: Text[10]; ItemJournalBatchName: Text[10]; ItemJournalLineEntryType: Enum "Item Ledger Entry Type"; ItemNo: Text[20]; PostingDate: Date; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplateName, ItemJournalBatchName,
          ItemJournalLineEntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify();
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::LIFO, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item, '', '', LibraryRandom.RandIntInRange(100, 200), WorkDate(), Item."Unit Cost");
    end;

    local procedure FindPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; PurchaseOrderNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseOrderNo);
        PurchaseLine.FindFirst();
    end;

    local procedure TestItemCostHistoryCalculation(InvoiceOrder: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
    begin
        Initialize();

        CreatePurchaseOrder(PurchaseHeader, Item);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, InvoiceOrder);

        CalculateEndYearCosts(CalcDate('<CY>', WorkDate()));
        VerifyItemCostHistoryEntry(Item);
    end;

    local procedure VerifyItemCostHistoryEntry(Item: Record Item)
    var
        ItemCostHistory: Record "Item Cost History";
    begin
        ItemCostHistory.SetRange("Item No.", Item."No.");
        ItemCostHistory.FindLast();
        Assert.AreEqual(Item."Unit Cost", ItemCostHistory."Year Average Cost", '');
    end;

    local procedure VerifyLedgerEntryDetailsReport(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
        LibraryReportDataset.LoadDataSetFile();

        // LIFO Amount (Actual)
        LibraryReportDataset.AssertElementWithValueExists('Amount_Control1130117', ItemLedgerEntry."Cost Amount (Actual)");
        // LIFO Amount (Expected)
        LibraryReportDataset.AssertElementWithValueExists('ExpLIFOAmt', ItemLedgerEntry."Cost Amount (Expected)");
        // FIFO Amount (Actual)
        LibraryReportDataset.AssertElementWithValueExists('FIFOAmt_Control1130141', ItemLedgerEntry."Cost Amount (Actual)");
        // FIFO Amount (Expected)
        LibraryReportDataset.AssertElementWithValueExists('ExpFIFOAmt', ItemLedgerEntry."Cost Amount (Expected)");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateEndYearCostsHandler(var CalculateEndYearCosts: TestRequestPage "Calculate End Year Costs")
    var
        ReferenceDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(ReferenceDate);
        CalculateEndYearCosts.ReferenceDate.SetValue(ReferenceDate); // Set value for Control1130000 that is Reference Date.
        CalculateEndYearCosts.Definitive.SetValue(true); // Enable the field for Control1130005 that is Definitive.
        CalculateEndYearCosts.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LedgerEntryDetailsRequestPageHandler(var LedgerEntryDetails: TestRequestPage "Ledger Entry Details")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        LedgerEntryDetails."Item Cost History".SetFilter("Item No.", ItemNo);
        LedgerEntryDetails."Item Cost History".SetFilter("Competence Year", StrSubstNo('%1', CalcDate('<CY>', WorkDate())));
        LedgerEntryDetails.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

