codeunit 137602 "SCM CETAF Sales-Purchase"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [SCM]
    end;

    var
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPatterns: Codeunit "Library - Patterns";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        ItemJournalLine: Record "Item Journal Line";
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM CETAF Sales-Purchase");
        ItemJournalLine.DeleteAll();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM CETAF Sales-Purchase");

        LibraryPatterns.SetNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        InventorySetup.Get();
        InventorySetup."Automatic Cost Posting" := false;
        InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Never;
        InventorySetup."Average Cost Calc. Type" := InventorySetup."Average Cost Calc. Type"::Item;
        InventorySetup.Modify();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM CETAF Sales-Purchase");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SplitApplication_ValidateAll_Standard()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        TempItemJournalLine: Record "Item Journal Line" temporary;
    begin
        // From: Costing suite - CETAF 51
        // Costing: Standard; Inventory: Several splits; Modifications: None
        Initialize();

        StandardItem(Item);
        LibraryPatterns.GRPHSeveralSplitApplication(Item, SalesLine, TempItemJournalLine);

        // Execute: Run adjust cost batch job
        Adjust(Item);

        // Validate
        Commit();
        GetEntries(Item, ItemLedgerEntry, ValueEntry);

        ValidateValueEntry_StandardInbound(Item, ItemLedgerEntry, ValueEntry, TempItemJournalLine);
        ValidateValueEntry_StandardInbound(Item, ItemLedgerEntry, ValueEntry, TempItemJournalLine);
        ValidateValueEntry_StandardInbound(Item, ItemLedgerEntry, ValueEntry, TempItemJournalLine);

        ValidateValueEntry_StandardOutbound(Item, ItemLedgerEntry, ValueEntry);
        ValidateValueEntry_StandardOutbound(Item, ItemLedgerEntry, ValueEntry);
        ValidateValueEntry_StandardOutboundExpected(Item, ItemLedgerEntry, ValueEntry);

        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SplitApplication_ValidateAll_Average()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempItemJournalLine: Record "Item Journal Line" temporary;
        ValueEntry: Record "Value Entry";
        AverageCost: Decimal;
    begin
        // From: Costing suite - CETAF 52
        // Costing: Average; Inventory: Several splits; Modifications: None
        Initialize();

        AverageItem(Item);
        LibraryPatterns.GRPHSeveralSplitApplication(Item, SalesLine, TempItemJournalLine);

        // Execute
        Adjust(Item);

        // Validate
        GetEntries(Item, ItemLedgerEntry, ValueEntry);
        AverageCost := GetAverageCost(TempItemJournalLine);

        ValidateValueEntry_Inbound(TempItemJournalLine, ItemLedgerEntry, ValueEntry, ActualCost());
        ValidateValueEntry_Inbound(TempItemJournalLine, ItemLedgerEntry, ValueEntry, ActualCost());
        ValidateValueEntry_Inbound(TempItemJournalLine, ItemLedgerEntry, ValueEntry, ActualCost());

        TempItemJournalLine.FindFirst();
        ValidateValueEntry_Outbound(ItemLedgerEntry, ValueEntry, AverageCost, TempItemJournalLine."Unit Amount", ActualCost());
        ValidateValueEntry_Outbound(ItemLedgerEntry, ValueEntry, AverageCost, TempItemJournalLine."Unit Amount", ActualCost());

        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SplitApplication_ValidateAll_FIFO()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempItemJournalLine: Record "Item Journal Line" temporary;
        ValueEntry: Record "Value Entry";
        FIFOCost1: Decimal;
        FIFOCost2: Decimal;
        FIFOCost3: Decimal;
    begin
        // From: Costing suite - CETAF 53
        // Costing: FIFO; Inventory: Several splits; Modifications: None
        Initialize();

        FIFOItem(Item);

        LibraryPatterns.GRPHSeveralSplitApplicationWithCosts(Item, SalesLine, TempItemJournalLine, FIFOCost1, FIFOCost2, FIFOCost3);

        // Execute
        Adjust(Item);

        // Validate
        GetEntries(Item, ItemLedgerEntry, ValueEntry);

        ValidateValueEntry_Inbound(TempItemJournalLine, ItemLedgerEntry, ValueEntry, ActualCost());
        ValidateValueEntry_Inbound(TempItemJournalLine, ItemLedgerEntry, ValueEntry, ActualCost());
        ValidateValueEntry_Inbound(TempItemJournalLine, ItemLedgerEntry, ValueEntry, ActualCost());

        TempItemJournalLine.FindFirst();
        ValidateValueEntry_Outbound(ItemLedgerEntry, ValueEntry, FIFOCost1, TempItemJournalLine."Unit Amount", ActualCost());
        ValidateValueEntry_Outbound(ItemLedgerEntry, ValueEntry, FIFOCost2, TempItemJournalLine."Unit Amount", ActualCost());
        ValidateValueEntry_Outbound(ItemLedgerEntry, ValueEntry, FIFOCost3, TempItemJournalLine."Unit Amount", ExpectedCost());

        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SplitApplication_LIFO()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        TempItemJournalLine: Record "Item Journal Line" temporary;
    begin
        // From: Costing suite - CETAF 53
        // Costing: LIFO; Inventory: Several splits; Modifications: None
        Initialize();

        LIFOItem(Item);
        LibraryPatterns.GRPHSeveralSplitApplication(Item, SalesLine, TempItemJournalLine);

        // Execute
        Adjust(Item);

        // Validate
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SimpleApplication_Standard()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        TempItemJournalLine: Record "Item Journal Line" temporary;
    begin
        // From: Costing suite - CETAF 54
        // Costing: Standard; Inventory: Simple application; Modifications: None
        Initialize();
        StandardItem(Item);
        LibraryPatterns.GRPHSimpleApplication(Item, SalesLine, TempItemJournalLine);
        Invoice(SalesLine);

        // Execute
        Adjust(Item);

        // Validate
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SimpleApplication_Average()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        TempItemJournalLine: Record "Item Journal Line" temporary;
    begin
        // From: Costing suite - CETAF 54
        // Costing: Average; nventory: Simple application; Modifications: None
        Initialize();
        AverageItem(Item);
        LibraryPatterns.GRPHSimpleApplication(Item, SalesLine, TempItemJournalLine);
        Invoice(SalesLine);

        // Execute
        Adjust(Item);

        // Validate
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SimpleApplication_FIFO()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        TempItemJournalLine: Record "Item Journal Line" temporary;
    begin
        // From: Costing suite - CETAF 54
        // Costing: FIFO; Inventory: Simple application; Modifications: None
        Initialize();
        FIFOItem(Item);
        LibraryPatterns.GRPHSimpleApplication(Item, SalesLine, TempItemJournalLine);
        Invoice(SalesLine);

        // Execute
        Adjust(Item);

        // Validate
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SplitJoinApplication_Standard()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineReturn: Record "Sales Line";
        TempItemJournalLine: Record "Item Journal Line" temporary;
    begin
        // From: Costing suite - CETAF 55
        // Costing: Standard; Inventory: Sales Return Split/Join application; Modifications: Sales Item Charge
        Initialize();
        StandardItem(Item);
        LibraryPatterns.GRPHSplitJoinApplication(Item, SalesLine, SalesLineReturn, TempItemJournalLine);

        // Execute: Assign Sales Item Charge
        GetSalesHeader(SalesLine, SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        AssignItemChargeReturn(SalesHeader, SalesLineReturn);

        Invoice(SalesLineReturn);
        Invoice(SalesLine); // Also posts item charge
        Adjust(Item);

        // Validate
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SplitJoinApplication_Average()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineReturn: Record "Sales Line";
        TempItemJournalLine: Record "Item Journal Line" temporary;
    begin
        // From: Costing suite - CETAF 55
        // Costing: Standard; Inventory: Sales Return Split/Join application; Modifications: Sales Item Charge
        Initialize();
        AverageItem(Item);
        LibraryPatterns.GRPHSplitJoinApplication(Item, SalesLine, SalesLineReturn, TempItemJournalLine);

        // Execute: Assign Sales Item Charge
        GetSalesHeader(SalesLineReturn, SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        AssignItemCharge(SalesHeader, SalesLineReturn);
        Invoice(SalesLineReturn); // Also posts item charge
        Adjust(Item);

        // Validate
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CredeitMemo_SalesItemCharge_Average()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        TempItemJournalLine: Record "Item Journal Line" temporary;
        Customer: Record Customer;
    begin
        // From: Costing suite - CETAF 56
        // Costing: Average; Inventory: Simple Application; Modifications: Sales Shipment Item Charge
        Initialize();

        AverageItem(Item);
        LibraryPatterns.GRPHSimpleApplication(Item, SalesLine, TempItemJournalLine);

        Invoice(SalesLine);
        GetShipmentLine(SalesLine, SalesShptLine);
        Customer.Get(SalesLine."Sell-to Customer No.");

        // Execute: Assign Sales Item Charge
        CreateCreditMemo(SalesHeader, Customer, WorkDate());
        AssignItemChargeShipment(SalesHeader, SalesShptLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Adjust(Item);

        // Validate
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SimpleApplication_ByLocation_Average()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        TempItemJournalLine: Record "Item Journal Line" temporary;
        Location: Record Location;
        Location2: Record Location;
    begin
        // From: Costing suite - CETAF 57
        // Costing: Average; Inventory: Simple Application on two locations;
        Initialize();

        AverageItem(Item);

        LibraryWarehouse.CreateLocation(Location);
        LibraryWarehouse.CreateLocation(Location2);

        Item.SetFilter("Location Filter", Location.Code);
        LibraryPatterns.GRPHSimpleApplication(Item, SalesLine, TempItemJournalLine);
        Item.SetFilter("Location Filter", Location2.Code);
        LibraryPatterns.GRPHSimpleApplication(Item, SalesLine2, TempItemJournalLine);

        // Execute: Assign Sales Item Charge
        Invoice(SalesLine);
        Invoice(SalesLine2);
        Adjust(Item);

        // Validate
        LibraryCosting.CheckAdjustment(Item);
    end;

    local procedure FullyShipped_ItemCharge(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup
        Initialize();

        LibraryInventory.CreateItemSimple(Item, CostingMethod, LibraryPatterns.RandCost(Item));
        LibraryPatterns.GRPHApplyInboundToUnappliedOutbound(Item, SalesLine);

        GetSalesHeader(SalesLine, SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        AssignItemCharge(SalesHeader, SalesLine);
        Invoice(SalesLine);

        // Execute
        Adjust(Item);

        // Validate
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullyShipped_ItemCharge_Standard()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 59
        FullyShipped_ItemCharge(Item."Costing Method"::Standard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullyShipped_ItemCharge_Average()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 59
        FullyShipped_ItemCharge(Item."Costing Method"::Average);
    end;

    local procedure PartiallyShipped_ItemCharge(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        // Setup
        Initialize();

        LibraryInventory.CreateItemSimple(Item, CostingMethod, LibraryPatterns.RandCost(Item));
        LibraryPatterns.GRPHSalesOnly(Item, SalesLine);

        GetSalesHeader(SalesLine, SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        AssignItemCharge(SalesHeader, SalesLine);
        Invoice(SalesLine);

        // Execute
        Adjust(Item);

        // Validate
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(1, ItemLedgerEntry.Count,
          'Expected exactly one item ledger entry after posting sales order');

        ItemApplicationEntry.SetRange("Outbound Item Entry No.", ItemLedgerEntry."Entry No.");
        Assert.IsTrue(ItemApplicationEntry.IsEmpty,
          'Expected no application entries after posting sales order only.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartiallyShipped_ItemCharge_Standard()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 60
        PartiallyShipped_ItemCharge(Item."Costing Method"::Standard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartiallyShipped_ItemCharge_Average()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 60
        PartiallyShipped_ItemCharge(Item."Costing Method"::Average);
    end;

    local procedure ChangeSalesDate_AfterReval(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        TempItemJournalLine: Record "Item Journal Line" temporary;
        RevaluationDate: Date;
        Factor: Decimal;
        Amount: Decimal;
    begin
        // Setup
        Initialize();

        LibraryInventory.CreateItemSimple(Item, CostingMethod, LibraryPatterns.RandCost(Item));
        LibraryPatterns.GRPHSimpleApplication(Item, SalesLine, TempItemJournalLine);
        if Item."Costing Method" <> Item."Costing Method"::Standard then
            Amount := TempItemJournalLine.Amount
        else
            Amount := Item."Standard Cost" * TempItemJournalLine.Quantity;

        // Execute
        RevaluationDate := SalesLine."Shipment Date" + 1;
        RevaluateAndAdjust(Item, Factor, RevaluationDate);
        CheckRevaluation(Item, ValueEntry, Factor, SalesLine, TempItemJournalLine.Quantity, Amount);

        SetShipmentDate(SalesLine, RevaluationDate + 1);
        Adjust(Item);

        // Validate
        CheckRevaluation(Item, ValueEntry, Factor, SalesLine, TempItemJournalLine.Quantity, Amount);
        LibraryCosting.CheckAdjustment(Item);
    end;

    local procedure ChangeSalesDate_BeforeReval(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        TempItemJournalLine: Record "Item Journal Line" temporary;
        RevaluationDate: Date;
        Factor: Decimal;
        Amount: Decimal;
    begin
        // Setup
        Initialize();

        LibraryInventory.CreateItemSimple(Item, CostingMethod, LibraryPatterns.RandCost(Item));
        LibraryPatterns.GRPHSimpleApplication(Item, SalesLine, TempItemJournalLine);

        if CostingMethod <> Item."Costing Method"::Standard then
            Amount := TempItemJournalLine.Amount
        else
            Amount := Item."Standard Cost" * TempItemJournalLine.Quantity;

        // Execute
        RevaluationDate := SalesLine."Shipment Date" + 2;
        RevaluateAndAdjust(Item, Factor, RevaluationDate);
        CheckRevaluation(Item, ValueEntry, Factor, SalesLine, TempItemJournalLine.Quantity, Amount);

        SetShipmentDate(SalesLine, RevaluationDate - 1);
        Adjust(Item);

        // Validate
        CheckRevaluation(Item, ValueEntry, Factor, SalesLine, TempItemJournalLine.Quantity, Amount);
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSalesDate_AfterReval_FIFO()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 61
        ChangeSalesDate_AfterReval(Item."Costing Method"::FIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSalesDate_AfterReval_Average()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 61
        ChangeSalesDate_AfterReval(Item."Costing Method"::Average);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSalesDate_AfterReval_Standard()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 61
        ChangeSalesDate_AfterReval(Item."Costing Method"::Standard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSalesDate_BeforeReval_FIFO()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 61
        ChangeSalesDate_BeforeReval(Item."Costing Method"::FIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSalesDate_BeforeReval_Average()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 61
        ChangeSalesDate_BeforeReval(Item."Costing Method"::Average);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSalesDate_BeforeReval_Standard()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 61
        ChangeSalesDate_BeforeReval(Item."Costing Method"::Standard);
    end;

    local procedure ReturnOnly(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        Initialize();

        LibraryInventory.CreateItem(Item, CostingMethod, LibraryPatterns.RandCost(Item), 0, 0, '');
        LibraryPatterns.GRPHSalesReturnOnly(Item, ReturnReceiptLine);

        Adjust(Item);
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnOnly_FIFO()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 65
        ReturnOnly(Item."Costing Method"::FIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnOnly_LIFO()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 65
        ReturnOnly(Item."Costing Method"::LIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnOnly_Average()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 65
        ReturnOnly(Item."Costing Method"::Average);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnOnly_Standard()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 65
        ReturnOnly(Item."Costing Method"::Standard);
    end;

    local procedure PartiallyInvoiced(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        TempItemJournalLine: Record "Item Journal Line" temporary;
    begin
        Initialize();

        LibraryInventory.CreateItem(Item, CostingMethod, LibraryPatterns.RandCost(Item), 0, 0, '');
        LibraryPatterns.GRPHSimpleApplication(Item, SalesLine, TempItemJournalLine);

        InvoicePartially(SalesLine);

        Adjust(Item);
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartiallyInvoiced_FIFO()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 65
        PartiallyInvoiced(Item."Costing Method"::FIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartiallyInvoiced_LIFO()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 65
        PartiallyInvoiced(Item."Costing Method"::LIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartiallyInvoiced_Average()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 65
        PartiallyInvoiced(Item."Costing Method"::Average);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartiallyInvoiced_Standard()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 65
        PartiallyInvoiced(Item."Costing Method"::Standard);
    end;

    local procedure FullyInvoiced(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        TempItemJournalLine: Record "Item Journal Line" temporary;
    begin
        Initialize();

        LibraryInventory.CreateItem(Item, CostingMethod, LibraryPatterns.RandCost(Item), 0, 0, '');
        LibraryPatterns.GRPHSimpleApplication(Item, SalesLine, TempItemJournalLine);

        Invoice(SalesLine);

        Adjust(Item);
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullyInvoiced_FIFO()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 66
        FullyInvoiced(Item."Costing Method"::FIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullyInvoiced_LIFO()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 66
        FullyInvoiced(Item."Costing Method"::LIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullyInvoiced_Average()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 66
        FullyInvoiced(Item."Costing Method"::Average);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullyInvoiced_Standard()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 66
        FullyInvoiced(Item."Costing Method"::Standard);
    end;

    local procedure SalesFromReturns(CostingMethod: Enum "Costing Method")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        LibraryInventory.CreateItem(Item, CostingMethod, LibraryPatterns.RandCost(Item), 0, 0, '');
        LibraryPatterns.GRPHSalesFromReturnReceipts(Item, SalesLine);

        Invoice(SalesLine);

        Adjust(Item);
        LibraryCosting.CheckAdjustment(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesFromReturns_FIFO()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 68
        SalesFromReturns(Item."Costing Method"::FIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesFromReturns_LIFO()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 68
        SalesFromReturns(Item."Costing Method"::LIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesFromReturns_Average()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 68
        SalesFromReturns(Item."Costing Method"::Average);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesFromReturns_Standard()
    var
        Item: Record Item;
    begin
        // From: Costing suite - CETAF 68
        SalesFromReturns(Item."Costing Method"::Standard);
    end;

    local procedure AssignItemCharge(var SalesHeader: Record "Sales Header"; var SalesLineApplyTo: Record "Sales Line")
    begin
        LibrarySales.AssignSalesChargeToSalesLine(
          SalesHeader, SalesLineApplyTo, LibraryPatterns.RandDec(0, SalesLineApplyTo.Quantity, 5), LibraryPatterns.RandDec(0, 100, 5));
    end;

    local procedure AssignItemChargeReturn(var SalesHeader: Record "Sales Header"; var SalesLineApplyTo: Record "Sales Line")
    begin
        LibrarySales.AssignSalesChargeToSalesReturnLine(
          SalesHeader, SalesLineApplyTo, LibraryPatterns.RandDec(0, SalesLineApplyTo.Quantity, 5), LibraryPatterns.RandDec(0, 100, 5));
    end;

    local procedure AssignItemChargeShipment(var SalesHeader: Record "Sales Header"; var SalesShptLineApplyTo: Record "Sales Shipment Line")
    begin
        LibrarySales.AssignSalesChargeToSalesShptLine(
          SalesHeader, SalesShptLineApplyTo, LibraryPatterns.RandDec(0, SalesShptLineApplyTo.Quantity, 5), LibraryPatterns.RandDec(0, 100, 5));
    end;

    local procedure GetShipmentLine(SalesLine: Record "Sales Line"; var SalesShptLine: Record "Sales Shipment Line")
    begin
        SalesShptLine.SetRange("Order No.", SalesLine."Document No.");
        SalesShptLine.SetRange(Type, SalesLine.Type);
        Assert.AreEqual(1, SalesShptLine.Count, 'Couldn''t match Sales Line to Sales Shipment Line');
        SalesShptLine.FindFirst();
    end;

    local procedure CreateCreditMemo(var SalesHeader: Record "Sales Header"; Customer: Record Customer; PostingDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure Invoice(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        GetSalesHeader(SalesLine, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure Adjust(var Item: Record Item)
    begin
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        Commit();
    end;

    local procedure GetSalesHeader(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
    end;

    local procedure CostFor(var ItemLedgerEntry: Record "Item Ledger Entry"; var TempItemJournalLine: Record "Item Journal Line" temporary): Decimal
    begin
        exit(ItemLedgerEntry.Quantity * TempItemJournalLine."Unit Amount");
    end;

    local procedure StdCostFor(var ItemLedgerEntry: Record "Item Ledger Entry"; var Item: Record Item): Decimal
    begin
        exit(ItemLedgerEntry.Quantity * Item."Standard Cost");
    end;

    local procedure UnitCostFor(var ItemLedgerEntry: Record "Item Ledger Entry"; UnitCost: Decimal): Decimal
    begin
        exit(ItemLedgerEntry.Quantity * UnitCost);
    end;

    local procedure GetAverageCost(var TempItemJournalLine: Record "Item Journal Line" temporary): Decimal
    var
        TotalQuantity: Decimal;
        TotalCost: Decimal;
    begin
        TempItemJournalLine.SetRange("Entry Type", TempItemJournalLine."Entry Type"::Purchase);

        repeat
            TotalCost += TempItemJournalLine.Amount;
            TotalQuantity += TempItemJournalLine.Quantity;
        until TempItemJournalLine.Next() = 0;

        TempItemJournalLine.SetRange("Entry Type");
        TempItemJournalLine.FindSet();

        exit(TotalCost / TotalQuantity);
    end;

    local procedure GetEntries(var Item: Record Item; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry")
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.FindSet();

        ItemLedgerEntry.SetCurrentKey("Entry No.");
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindSet();
    end;

    local procedure ModifyPostRevaluation(ItemJnlBatch: Record "Item Journal Batch"; Factor: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlBatch.Name);
        if ItemJnlLine.FindSet() then
            repeat
                ItemJnlLine.Validate(
                  "Inventory Value (Revalued)", Round(ItemJnlLine."Inventory Value (Revalued)" * Factor, LibraryERM.GetAmountRoundingPrecision()));
                ItemJnlLine.Modify();
            until (ItemJnlLine.Next() = 0);
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);
    end;

    local procedure ValidateValueEntry_Inbound(var TempItemJournalLine: Record "Item Journal Line" temporary; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; Actual: Boolean)
    begin
        NearlyEqual(CostFor(ItemLedgerEntry, TempItemJournalLine), EntryCost(ValueEntry, Actual),
          'Unexpected cost amount actual on value entry.');
        NextValueEntry(ValueEntry);
        ItemLedgerEntry.Next();
        TempItemJournalLine.Next();
    end;

    local procedure ValidateValueEntry_Outbound(var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; AverageCost: Decimal; InitialUnitCost: Decimal; Actual: Boolean)
    begin
        NearlyEqual(UnitCostFor(ItemLedgerEntry, InitialUnitCost), EntryCost(ValueEntry, Actual),
          'Unexpected cost amount actual on value entry.');

        NextValueEntry(ValueEntry);

        NearlyEqual(ItemLedgerEntry.Quantity * (AverageCost - InitialUnitCost), EntryCost(ValueEntry, Actual),
          'Unexpected cost amount actual on value entry.');

        NextValueEntry(ValueEntry);
        ItemLedgerEntry.Next();
    end;

    local procedure ValidateValueEntry_StandardInbound(var Item: Record Item; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; var TempItemJournalLine: Record "Item Journal Line" temporary)
    begin
        NearlyEqual(CostFor(ItemLedgerEntry, TempItemJournalLine), ValueEntry."Cost Amount (Actual)",
          'Unexpected cost amount actual on inbound value entry.');
        NextValueEntry(ValueEntry);
        Assert.AreEqual(ValueEntry."Entry Type", ValueEntry."Entry Type"::Variance,
          'Expected variance entry after adjusting std. costed item.');
        NearlyEqual(CostFor(ItemLedgerEntry, TempItemJournalLine) - StdCostFor(ItemLedgerEntry, Item), -ValueEntry."Cost Amount (Actual)",
          'Unexpected cost amount actual on inbound variance value entry after adjusting.');

        ItemLedgerEntry.Next();
        NextValueEntry(ValueEntry);
        TempItemJournalLine.Next();
    end;

    local procedure ValidateValueEntry_StandardOutbound(var Item: Record Item; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry")
    begin
        NearlyEqual(StdCostFor(ItemLedgerEntry, Item), ValueEntry."Cost Amount (Actual)",
          'Unexpected cost amount actual on outbound value entry, standard cost.');
        ItemLedgerEntry.Next();
        NextValueEntry(ValueEntry);
    end;

    local procedure ValidateValueEntry_StandardOutboundExpected(var Item: Record Item; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry")
    begin
        NearlyEqual(StdCostFor(ItemLedgerEntry, Item), ValueEntry."Cost Amount (Expected)",
          'Unexpected cost amount expected on outbound value entry, standard cost.');
        ItemLedgerEntry.Next();
        NextValueEntry(ValueEntry);
    end;

    local procedure NearlyEqual(d1: Decimal; d2: Decimal; Message: Text)
    var
        Close: Boolean;
    begin
        // Check that _either_ the relative/absolute error is within an error margin of 10E2/10E3
        if Abs(d1 - d2) <= 0.02 then
            exit;

        if d1 <> 0 then
            Close := Abs((d2 - d1) / d1) <= 0.001
        else
            if d2 <> 0 then
                Close := Abs((d1 - d2) / d2) <= 0.001;

        Assert.IsTrue(Close, Message + StrSubstNo(': Expected %1. Was %2.', d1, d2));
    end;

    local procedure NextValueEntry(var ValueEntry: Record "Value Entry")
    begin
        if ValueEntry.Next() = 0 then
            exit;

        if (Abs(ValueEntry."Cost Amount (Actual)") <= 0.02) and (Abs(ValueEntry."Cost Amount (Expected)") <= 0.02) then
            NextValueEntry(ValueEntry);
    end;

    local procedure EntryCost(var ValueEntry: Record "Value Entry"; Actual: Boolean): Decimal
    begin
        if Actual then
            exit(ValueEntry."Cost Amount (Actual)");
        exit(ValueEntry."Cost Amount (Expected)");
    end;

    local procedure ActualCost(): Boolean
    begin
        exit(true);
    end;

    local procedure ExpectedCost(): Boolean
    begin
        exit(false);
    end;

    local procedure StandardItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Standard, LibraryPatterns.RandCost(Item), 0, 0, '');
    end;

    local procedure AverageItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item, Item."Costing Method"::Average, LibraryPatterns.RandCost(Item), 0, 0, '');
    end;

    local procedure FIFOItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item, Item."Costing Method"::FIFO, LibraryPatterns.RandCost(Item), 0, 0, '');
    end;

    local procedure LIFOItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item, Item."Costing Method"::LIFO, LibraryPatterns.RandCost(Item), 0, 0, '');
    end;

    local procedure RevaluateAndAdjust(var Item: Record Item; var Factor: Decimal; RevaluationDate: Date)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        Factor := 1 + LibraryPatterns.RandDec(0, 1, 5);

        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        LibraryPatterns.CalculateInventoryValueRun(ItemJournalBatch, Item, RevaluationDate, "Inventory Value Calc. Per"::Item,
          Item."Costing Method" <> Item."Costing Method"::Average, Item."Costing Method" <> Item."Costing Method"::Average,
          false, "Inventory Value Calc. Base"::" ", false, '', '');
        ModifyPostRevaluation(ItemJournalBatch, Factor);
        Adjust(Item);
    end;

    local procedure CheckRevaluation(Item: Record Item; var ValueEntry: Record "Value Entry"; Factor: Decimal; var SalesLine: Record "Sales Line"; Quantity: Decimal; Amount: Decimal)
    var
        ShippedQuantity: Decimal;
    begin
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
        Assert.AreEqual(1, ValueEntry.Count,
          'Expected exactly one revaluation entry');
        ValueEntry.FindFirst();

        ShippedQuantity := SalesLine.Quantity;
        NearlyEqual(Amount * (Factor - 1) * (Quantity - ShippedQuantity) / Quantity, ValueEntry."Cost Amount (Actual)",
          'Unexpected cost amount actual on revaluation entry');
    end;

    local procedure SetShipmentDate(var SalesLine: Record "Sales Line"; ShipmentDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        GetSalesHeader(SalesLine, SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);

        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure InvoicePartially(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Qty. to Invoice", LibraryPatterns.RandDec(0, SalesLine.Quantity / 2, 2));
        Invoice(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF310507FIFO()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        Day1: Date;
        Variant: Code[10];
        Loc: Code[10];
    begin
        Initialize();

        InventorySetup.Get();
        InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Always;
        InventorySetup.Modify();

        IsInitialized := false;

        LibraryInventory.CreateItem(Item, Item."Costing Method"::FIFO, 0, 0, 0, '');
        Day1 := WorkDate();
        Loc := '';
        Variant := '';

        LibraryPurchase.PostPurchaseOrder(PurchaseHeader, Item, Loc, Variant, 2, Day1, 10, true, true);
        LibraryPurchase.PostPurchaseOrder(PurchaseHeader, Item, Loc, Variant, 2, Day1, 20, true, true);

        LibrarySales.PostSalesOrderPartially(SalesHeader, Item, Loc, Variant, 2, Day1, 100, true, 1, true, 0.5);

        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Adjustment is done automatic

        // verify
        LibraryCosting.CheckAdjustment(Item);
    end;
}

