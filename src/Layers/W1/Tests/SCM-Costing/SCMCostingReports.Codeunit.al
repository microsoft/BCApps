codeunit 137306 "SCM Costing Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [SCM]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AutoCostPostFalseAndAdjustCost()
    begin
        Initialize();
        AdjustCostItemEntries(false, false);  // Automatic Cost Posting, Expected Cost Posting To GL.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AutoCostPostTrueAndAdjustCost()
    begin
        Initialize();
        AdjustCostItemEntries(true, true);    // Automatic Cost Posting - TRUE, Expected Cost Posting To GL will be TRUE later.
    end;

    [Test]
    [HandlerFunctions('ItemAgeCompositionValueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAgeCompositionAverageDifferentPeriods()
    var
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        UnitCost: array[2] of Decimal;
    begin
        // [FEATURE] [Item Age Composition - Value]
        // [SCENARIO 381639] For an item with "Average" costing method, report "Item Age Composition - Value" should calculate average cost amount in each period separately

        Initialize();

        // [GIVEN] Item with "Average" costing method
        CreateItem(Item, Item."Costing Method"::Average);

        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);

        // [GIVEN] Post item inventory on workdate with cost amount = "C1", another entry on WorkDate() + 1 month, cost amount = "C2"
        UnitCost[1] := LibraryRandom.RandDecInRange(100, 500, 2);
        UnitCost[2] := LibraryRandom.RandDecInRange(100, 500, 2);
        PostItemJournalLine(
          ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
          Item."No.", 1, UnitCost[1], WorkDate());
        PostItemJournalLine(
          ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
          Item."No.", 1, UnitCost[2], CalcDate('<1M>', WorkDate()));

        // [WHEN] Run report "Item Age Composition - Value" with ending date = workdate and period length = "1M"
        RunItemAgeCompositionReport(WorkDate(), '1M', Item."No.");

        // [THEN] Inventory value on workdate is "C1", inventory value in the period after workdate is "C2"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', Item."No.");
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals('InvtValue4_Item', UnitCost[1]);
        LibraryReportDataset.AssertCurrentRowValueEquals('InvtValue5_Item', (UnitCost[1] + UnitCost[2]) / 2);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalInvtValue_Item', UnitCost[1] * 1 + UnitCost[2] * 1);

    end;

    [Test]
    [HandlerFunctions('ItemAgeCompositionValueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAgeCompositionAverageOnePeriod()
    var
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        UnitCost: array[2] of Decimal;
        I: Integer;
    begin
        // [FEATURE] [Item Age Composition - Value]
        // [SCENARIO 381639] For an item with "Average" costing method, report "Item Age Composition - Value" should valuate inventory by average cost amount

        Initialize();

        // [GIVEN] Item with "Average" costing method
        CreateItem(Item, Item."Costing Method"::Average);

        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);

        // [GIVEN] Post two item ledger entries on workdate with cost amount = "C1"and "C2"
        for I := 1 to 2 do begin
            UnitCost[I] := LibraryRandom.RandDecInRange(100, 500, 2);
            PostItemJournalLine(
              ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
              Item."No.", 1, UnitCost[I], WorkDate());
        end;

        // [GIVEN] Post negative adjustment, quantity = 1. Remaining quantity on inventory is 1.
        PostItemJournalLine(
          ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", 1, 0, WorkDate());

        // [GIVEN] Run "Adjust Cost - Item Entries"
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [WHEN] Run report "Item Age Composition - Value" with ending date = workdate and period length = "1M"
        Commit();
        RunItemAgeCompositionReport(WorkDate(), '1M', Item."No.");

        // [THEN] Inventory value on workdate is ("C1" + "C2") / 2
        LibraryReportDataset.LoadDataSetFile();
        VerifyItemAgeComposition(Item."No.", UnitCost[1] + UnitCost[2] - Round((UnitCost[1] + UnitCost[2]) / 2), 0);
    end;

    [Test]
    [HandlerFunctions('ItemAgeCompositionValueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAgeCompositionValueTotalInvtValueCalculation()
    var
        Item: array[2] of Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        UnitCost: array[2, 2] of Decimal;
        ItemInvtValue: array[2] of Decimal;
        i: Integer;
        j: Integer;
    begin
        // [FEATURE] [Item Age Composition - Value]
        // [SCENARIO 231532]
        Initialize();

        // [GIVEN] Item "A" with average costing method, item "F" with FIFO costing method.
        CreateItem(Item[1], Item[1]."Costing Method"::Average);
        CreateItem(Item[2], Item[2]."Costing Method"::FIFO);

        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);

        // [GIVEN] Post 2 positive adjustments and 1 negative adjustment for 1 pc per each item.
        // [GIVEN] The resulting inventory of each item = 1.
        for i := 1 to 2 do begin
            for j := 1 to 2 do begin
                UnitCost[i] [j] := LibraryRandom.RandDecInRange(100, 500, 2);
                PostItemJournalLine(
                  ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
                  Item[i]."No.", 1, UnitCost[i] [j], WorkDate());
            end;
            PostItemJournalLine(
              ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Negative Adjmt.",
              Item[i]."No.", 1, 0, WorkDate());
        end;

        // [GIVEN] Run "Adjust Cost - Item Entries".
        // [GIVEN] The negative adjustment of item "A" is valued by average cost. The resulting inventory value of item "A" = "ResA".
        // [GIVEN] The negative adjustment of item "F" is valued by the cost of the first inbound entry. The resulting inventory value of item "F" = "ResF".
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', Item[1]."No.", Item[2]."No."), '');

        // [WHEN] Run report "Item Age Composition - Value" for both items.
        Commit();
        RunItemAgeCompositionReport(WorkDate(), '1M', StrSubstNo('%1|%2', Item[1]."No.", Item[2]."No."));

        // [THEN] The report shows that the invt. value of "A" = "ResA", invt. value of "F" = "ResF".
        LibraryReportDataset.LoadDataSetFile();
        ItemInvtValue[1] := UnitCost[1] [1] + UnitCost[1] [2] - Round((UnitCost[1] [1] + UnitCost[1] [2]) / 2);
        ItemInvtValue[2] := UnitCost[2] [2];
        VerifyItemAgeComposition(Item[1]."No.", ItemInvtValue[1], 0);
        VerifyItemAgeComposition(Item[2]."No.", ItemInvtValue[2], 0);

        // [THEN] The total inventory value in the report is equal to "ResA" + "ResF".
        VerifyItemAgeCompositionTotals(Item[2]."No.", ItemInvtValue[1] + ItemInvtValue[2], 0);
    end;

    [Test]
    procedure InventoryGLReconciliationRecognizesInterimRevaluation()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        TempInventoryReportHeader: Record "Inventory Report Header" temporary;
        TempInventoryReportEntry: Record "Inventory Report Entry" temporary;
        GetInventoryReport: Codeunit "Get Inventory Report";
        NoSeries: Codeunit "No. Series";
        NewDate: Date;
        Qty: Decimal;
        UnitCost: Decimal;
    begin
        // [FEATURE] [Inventory - G/L Reconciliation] [Revaluation] [Expected Cost]
        // [SCENARIO 411429] "Inventory G/L Reconciliation" report recognizes interim revaluation of purchase receipt.
        Initialize();
        NewDate := CalcDate('<2Y>', WorkDate());
        Qty := LibraryRandom.RandIntInRange(10, 20);
        UnitCost := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Enable "Automatic Cost Posting" and "Expected Cost Posting".
        LibraryInventory.SetAutomaticCostPosting(true);
        LibraryInventory.SetExpectedCostPosting(true);

        // [GIVEN] Item with "Costing Method" = Standard, unit cost = 10.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        Item.SetRecFilter();

        // [GIVEN] Purchase order for 10 pcs of the item.
        // [GIVEN] Post the order as "Receive".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Posting Date", NewDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Open revaluation journal, invoke "Calculate Inventory Value" and set a new Unit Cost = 2000.
        // [GIVEN] Post the revaluation journal.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryCosting.CalculateInventoryValue(
          ItemJournalLine, Item, NewDate, NoSeries.PeekNextNo(ItemJournalBatch."No. Series"),
          "Inventory Value Calc. Per"::Item, false, false, true, "Inventory Value Calc. Base"::" ", false);
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Unit Cost (Revalued)", UnitCost);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Calculate "Inventory - G/L Reconciliation" report.
        TempInventoryReportHeader.SetFilter("Posting Date Filter", Format(NewDate));
        GetInventoryReport.SetReportHeader(TempInventoryReportHeader);
        GetInventoryReport.Run(TempInventoryReportEntry);

        // [THEN] "Inventory (Interim)" and "Invt. Accrual (Interim)" include the revaluation of the receipt and are equal to 20000 (10 pcs * 2000 LCY).
        TempInventoryReportEntry.SetRange(Type, TempInventoryReportEntry.Type::Item);
        TempInventoryReportEntry.SetRange("No.", Item."No.");
        TempInventoryReportEntry.CalcSums("Inventory (Interim)", "Invt. Accrual (Interim)");
        TempInventoryReportEntry.TestField("Inventory (Interim)", Qty * UnitCost);
        TempInventoryReportEntry.TestField("Invt. Accrual (Interim)", -Qty * UnitCost);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Costing Reports");
        // Lazy Setup.

        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Costing Reports");

        NoSeriesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Costing Reports");
    end;

    local procedure AdjustCostItemEntries(AutomaticCostPosting: Boolean; ExpectedCostPostingToGLLater: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseHeader3: Record "Purchase Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        NewPostingDate: Date;
        UnitCost: Decimal;
        Quantity: Decimal;
        DirectUnitCost: Decimal;
        QuantityToReceive: Decimal;
        SalesQuantity: Decimal;
        ItemChargeUnitCost: Decimal;
        TotalInventoryCost: Decimal;
        PostedPurchInvoiceNo: Code[20];
        PostedPurchInvoiceNo2: Code[20];
        PostedPurchInvoiceNo3: Code[20];
        ServiceInvoiceNo: Code[20];
    begin
        // Setup : Update Sales Setup and Inventory Setup, Create Item, Post Two Purchase Orders.
        SalesReceivablesSetup.Get();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Credit Warnings"::"No Warning", false);

        InventorySetup.Get();
        LibraryInventory.SetAverageCostSetup(InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period");
        LibraryInventory.SetAutomaticCostPosting(AutomaticCostPosting);
        LibraryInventory.SetExpectedCostPosting(false);

        DirectUnitCost := LibraryRandom.RandDec(100, 2);
        QuantityToReceive := LibraryRandom.RandIntInRange(10, 20);
        Quantity := QuantityToReceive + LibraryRandom.RandInt(10);
        ItemChargeUnitCost := LibraryRandom.RandDec(10, 2);
        NewPostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(2) + 2) + 'D>', WorkDate());  // Random date required for later postings.

        CreateItem(Item, Item."Costing Method"::Average);
        PostedPurchInvoiceNo := CreatePurchaseOrderAndPost(PurchaseHeader, Item."No.", WorkDate(), Quantity, QuantityToReceive, DirectUnitCost);
        PostedPurchInvoiceNo2 :=
          CreatePurchaseOrderAndPost(PurchaseHeader2, Item."No.", NewPostingDate, Quantity, QuantityToReceive, DirectUnitCost);  // Random date required.

        // Calculating Inventory Quantity.
        Item.Get(Item."No.");
        Item.CalcFields(Inventory);

        // Post Service Order.
        SalesQuantity := LibraryRandom.RandInt(QuantityToReceive);
        ServiceInvoiceNo := CreateServiceOrderAndPost(Item."No.", NewPostingDate, SalesQuantity, true, true);

        // Post Charge Item.
        PostedPurchInvoiceNo3 :=
          CreateAndPostChargeItemPO(PurchaseHeader3, PurchaseHeader2."No.", Item."No.", NewPostingDate, ItemChargeUnitCost);

        UnitCost := (2 * QuantityToReceive * DirectUnitCost + ItemChargeUnitCost) / Item.Inventory;
        Item.CalcFields(Inventory);
        TotalInventoryCost := Item.Inventory * UnitCost;

        // Exercise : Run Adjust Cost - Item Entries Batch Report
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        if ExpectedCostPostingToGLLater then
            UpdateExpectedCostOnInvSetup(true);

        // Verify : Check That Unit Cost is equal to Unit Cost on Item.
        VerifyUnitCost(Item."No.", UnitCost);

        // Exercise : Run Post Inventory Cost to G/L for the different dates.
        PostInventoryCostGL(Item."No.", WorkDate());
        PostInventoryCostGL(Item."No.", NewPostingDate);

        // Verify : Check G/L Entry Created After Run Post Inventory To G/L Report.
        VerifyInventoryCostOnGL(
          TotalInventoryCost, Item, PostedPurchInvoiceNo, PostedPurchInvoiceNo2, PostedPurchInvoiceNo3, ServiceInvoiceNo);
    end;

    local procedure NoSeriesSetup()
    begin
        LibrarySales.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();
        LibraryService.SetupServiceMgtNoSeries();
    end;

    local procedure UpdateExpectedCostOnInvSetup(ExpectedCostPostingToGL: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Expected Cost Posting to G/L", ExpectedCostPostingToGL);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(CreditWarnings: Option; StockoutWarning: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", CreditWarnings);
        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Modify(true);
    end;

    local procedure CreateServiceOrderAndPost(ItemNo: Code[20]; PostingDate: Date; Quantity: Decimal; Ship: Boolean; Invoice: Boolean) ServiceInvoiceNo: Code[20]
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        NoSeries: Codeunit "No. Series";
    begin
        CreateServiceOrder(ServiceHeader, ServiceItemLine, ServiceItem);
        ServiceHeader.Validate("Posting Date", PostingDate);
        ServiceHeader.Modify(true);
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItem."No.", ItemNo, Quantity);

        ServiceMgtSetup.Get();
        ServiceInvoiceNo := NoSeries.PeekNextNo(ServiceMgtSetup."Posted Service Invoice Nos.");
        LibraryService.PostServiceOrder(ServiceHeader, Ship, false, Invoice);
    end;

    local procedure CreatePurchaseOrderAndPost(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; DocumentDate: Date; Quantity: Decimal; QuantityToReceive: Decimal; DirectUnitCost: Decimal) PostedPurchInvoiceNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentDate);

        // Receive Quantity is less than Purchase Order Quantity.
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, Quantity, QuantityToReceive, DirectUnitCost);
        PostedPurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostInventoryCostGL(ItemNo: Code[20]; PostingDate: Date)
    begin
        LibraryPostInventoryToGL.PostInvtCostToGL(false, PostingDate, ItemNo);
    end;

    local procedure CreateAndPostChargeItemPO(var PurchaseHeader: Record "Purchase Header"; PurchaseOdrerNo: Code[20]; ItemNo: Code[20]; DocumentDate: Date; ItemChargeUnitCost: Decimal) PostedPurchInvoiceNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentDate);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);  // creating a single item charge.
        PurchaseLine.Validate("Direct Unit Cost", ItemChargeUnitCost);
        PurchaseLine.Modify(true);
        CreateItemChargeAssignment(PurchaseLine, PurchaseOdrerNo, ItemNo);
        PostedPurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentDate: Date)
    begin
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate(
          "Vendor Invoice No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Validate("Document Date", DocumentDate);
        PurchaseHeader.Validate("Posting Date", DocumentDate);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; QuantityToReceiveAndInvoice: Decimal; DirectUnitCost: Decimal)
    begin
        Clear(PurchaseLine);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Qty. to Invoice", QuantityToReceiveAndInvoice);
        PurchaseLine.Validate("Qty. to Receive", QuantityToReceiveAndInvoice);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        Clear(ServiceLine);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Qty. to Invoice", Quantity);
        ServiceLine.Validate("Qty. to Ship", Quantity);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2) + 10);  // Value required.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; var ServiceItem: Record "Service Item")
    begin
        // Create Service Order - Service Item, Service Header, Service Line with Type as Item.
        LibraryService.CreateServiceItem(ServiceItem, '');
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure CreateItemChargeAssignment(var PurchaseLine: Record "Purchase Line"; PurchaseOrderNo: Code[20]; ItemNo: Code[20])
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        FindPurchaseReceiptLine(PurchRcptLine, PurchaseOrderNo, ItemNo);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt, PurchRcptLine."Document No.",
          PurchRcptLine."Line No.", PurchRcptLine."No.");
    end;

    local procedure FindInventoryPostingSetup(var InventoryPostingSetup: Record "Inventory Posting Setup"; InventoryPostingGroup: Code[20])
    begin
        InventoryPostingSetup.SetRange("Location Code", '');
        InventoryPostingSetup.SetRange("Invt. Posting Group Code", InventoryPostingGroup);
        InventoryPostingSetup.FindFirst();
    end;

    local procedure FindPurchaseReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseOrderNo: Code[20]; ItemNo: Code[20])
    begin
        PurchRcptLine.SetRange("Order No.", PurchaseOrderNo);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure PostItemJournalLine(ItemJnlTemplateName: Code[10]; ItemJnlBatchName: Code[10]; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Qty: Decimal; UnitAmount: Decimal; PostingDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJnlTemplateName, ItemJnlBatchName, EntryType, ItemNo, Qty);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJnlTemplateName, ItemJnlBatchName);
    end;

    local procedure RunItemAgeCompositionReport(EndingDate: Date; PeriodLength: Text; ItemFilter: Text)
    var
        Item: Record Item;
    begin
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(PeriodLength);
        Item.SetFilter("No.", ItemFilter);
        REPORT.Run(REPORT::"Item Age Composition - Value", true, false, Item);
    end;

    local procedure VerifyInventoryCostOnGL(ExpectedAmount: Decimal; Item: Record Item; DocumentNo: Code[20]; DocumentNo2: Code[20]; DocumentNo3: Code[20]; DocumentNo4: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLEntry: Record "G/L Entry";
        ActualAmount: Decimal;
    begin
        FindInventoryPostingSetup(InventoryPostingSetup, Item."Inventory Posting Group");
        GLEntry.SetFilter(
          "Document No.", '%1|%2|%3|%4|%5', Item."No.", DocumentNo, DocumentNo2, DocumentNo3, DocumentNo4);
        GLEntry.SetRange("G/L Account No.", InventoryPostingSetup."Inventory Account");
        GLEntry.FindSet();
        repeat
            ActualAmount := ActualAmount + GLEntry.Amount;
        until GLEntry.Next() = 0;

        GeneralLedgerSetup.Get();

        Assert.AreNearlyEqual(ExpectedAmount, ActualAmount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
          'Wrong Inventory value. Item:' + Item."No.");
    end;

    local procedure VerifyItemAgeComposition(ItemNo: Code[20]; CurrPeriodPerItem: Decimal; NextPeriodPerItem: Decimal)
    begin
        LibraryReportDataset.SetRange('No_Item', ItemNo);
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals('InvtValue4_Item', CurrPeriodPerItem);
        LibraryReportDataset.AssertCurrentRowValueEquals('InvtValue5_Item', NextPeriodPerItem);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalInvtValue_Item', CurrPeriodPerItem + NextPeriodPerItem);
    end;

    local procedure VerifyItemAgeCompositionTotals(ItemNo: Code[20]; CurrPeriodTotal: Decimal; NextPeriodTotal: Decimal)
    begin
        LibraryReportDataset.SetRange('No_Item', ItemNo);
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals('InvtValueRTC4', CurrPeriodTotal);
        LibraryReportDataset.AssertCurrentRowValueEquals('InvtValueRTC5', NextPeriodTotal);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalInvtValueRTC', CurrPeriodTotal + NextPeriodTotal);
    end;

    local procedure VerifyUnitCost(ItemNo: Code[20]; UnitCost: Decimal)
    var
        Item: Record Item;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        Item.Get(ItemNo);
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(UnitCost, Item."Unit Cost", GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
          'Wrong Unit cost. Item:' + ItemNo);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(
          StrPos(ConfirmMessage, 'If you enable the Expected Cost Posting to G/L') > 0, 'Unexpected confirm dialog: ' + ConfirmMessage);

        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemAgeCompositionValueRequestPageHandler(var ItemAgeCompositionValue: TestRequestPage "Item Age Composition - Value")
    begin
        ItemAgeCompositionValue.EndingDate.SetValue(LibraryVariableStorage.DequeueDate());
        ItemAgeCompositionValue.PeriodLength.SetValue(LibraryVariableStorage.DequeueText());
        ItemAgeCompositionValue.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

