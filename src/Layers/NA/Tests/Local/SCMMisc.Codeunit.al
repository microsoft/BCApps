codeunit 144020 "SCM Misc."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LocationBlue: Record Location;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPlanning: Codeunit "Library - Planning";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        PurchHeaderNotFoundErr: Label 'Purchase Header not found for Vendor %1', Comment = '%1 = Vendor No.';
        WrongNoOfPurchOrdersErr: Label '%1 purchase orders must be created when carrying out action.';

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutPurchOrdersWithTwoVendorsUseTaxAreaCode()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PurchHeader: Record "Purchase Header";
        ItemFilter: Text;
        ProdOrderCount: Integer;
        Counter: Integer;
        PrevUseVendorTaxArea: Boolean;
    begin
        // [FEATURE] [Requisition Worksheet] [Carry Out Action Message] [Use Vendor's Tax Area Code]
        // [SCENARIO] Can create Purchase Orders at once for several Items with different Vendors, if "Use Vendor's Tax Area Code" set to TRUE.

        // [GIVEN] "Use Vendor's Tax Area Code" = TRUE, two Items with different Vendors and Order reordering policy, each is on Sales Line.
        Initialize();
        PrevUseVendorTaxArea := UpdateUseVendorTaxArea(true);
        ProdOrderCount := LibraryRandom.RandIntInRange(2, 4);
        for Counter := 1 to ProdOrderCount do begin
            CreateItemWithVendorNoAndReorderingPolicy(
              Item, CreateVendorWithTaxAreaCode(), Item."Reordering Policy"::Order);
            LibraryVariableStorage.Enqueue(Item."Vendor No.");
            ItemFilter += '|' + Item."No.";
            Clear(SalesHeader);
            CreateSalesOrder(
              SalesHeader, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandInt(100), LocationBlue.Code, false);
        end;

        // [GIVEN] Calculate Plan for Items.
        Item.SetFilter("No.", CopyStr(ItemFilter, 2));
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate(), WorkDate());

        // [WHEN] Carry Out Action Message.
        CarryOutRequisitionPlan(RequisitionWkshName);

        // [THEN] One Purchase order is created per Items Vendor
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        for Counter := 1 to ProdOrderCount do begin
            PurchHeader.SetRange("Buy-from Vendor No.", LibraryVariableStorage.DequeueText());
            Assert.IsFalse(PurchHeader.IsEmpty, StrSubstNo(PurchHeaderNotFoundErr, PurchHeader.GetRangeMin("Buy-from Vendor No.")));
        end;

        // Teardown.
        UpdateUseVendorTaxArea(PrevUseVendorTaxArea);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutActionOnDifferentLocationCodesNoSpecialOrder()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PurchaseHeader: Record "Purchase Header";
        NoOfSalesLines: Integer;
    begin
        // [FEATURE] [Requisition Worksheet] [Carry Out Action Message]
        // [SCENARIO 376917] "Carry Out Action Message" creates one purchase order for multiple location codes when planning purchases without special order.

        Initialize();

        // [GIVEN] Item "I" with purchase replenishment system and default vendor
        CreateItemPurchaseReplishment(Item);

        // [GIVEN] Create sales order with 2 lines: each line sales item "I" from different location
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        NoOfSalesLines := LibraryRandom.RandIntInRange(2, 5);
        CreateSalesLines(SalesHeader, Item."No.", '', NoOfSalesLines);

        // [GIVEN] Calculate requisition plan for item "I"
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate(), WorkDate());

        // [WHEN] Carry out requisition plan
        CarryOutRequisitionPlan(RequisitionWkshName);

        // [THEN] Two purchase orders have been created
        PurchaseHeader.SetRange("Buy-from Vendor No.", Item."Vendor No.");
        Assert.AreEqual(1, PurchaseHeader.Count, StrSubstNo(WrongNoOfPurchOrdersErr, NoOfSalesLines));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutActionOnDifferentLocationCodesSpecialOrder()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PurchaseHeader: Record "Purchase Header";
        NoOfSalesLines: Integer;
    begin
        // [FEATURE] [Requisition Worksheet] [Carry Out Action Message] [Special Order]
        // [SCENARIO 376917] "Carry Out Action Message" creates a separate purchase order per location code when planning purchases with special order

        Initialize();

        // [GIVEN] Item "I" with purchase replenishment system and default vendor
        CreateItemPurchaseReplishment(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [GIVEN] Create sales order with 2 lines: each line sales item "I" from different location. Purchasing Code = Special Order
        NoOfSalesLines := LibraryRandom.RandIntInRange(2, 5);
        CreateSalesLines(SalesHeader, Item."No.", CreatePurchasing(true, false), NoOfSalesLines);

        // [GIVEN] Retrieve sales orders into requisition workseet
        GetSpecialOrders(RequisitionWkshName, Item."No.");

        // [WHEN] Carry out requition plan
        CarryOutRequisitionPlan(RequisitionWkshName);

        // [THEN] Two purchase orders have been created
        PurchaseHeader.SetRange("Buy-from Vendor No.", Item."Vendor No.");
        Assert.AreEqual(NoOfSalesLines, PurchaseHeader.Count, StrSubstNo(WrongNoOfPurchOrdersErr, NoOfSalesLines));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecialOrderPurchLinePayToVendorValidated()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Special Order]
        // [SCENARIO 378319] "Pay-to Vendor No." can be changed in special purchase order

        // [GIVEN] Special sales order with linked purchase order for vendor "V1"
        Initialize();
        CreateSpecialSalesOrderWithLinkedPurchase(SalesHeader, SalesLine);

        // [GIVEN] Vendor "V2" with Name = "N"
        CreateVendor(Vendor);

        // [WHEN] Change "Pay-to" vendor no. in purchase order: set new vendor = "V2"
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, FindPurchaseHeaderNo(SalesLine."No."));
        UpdatePayToVendorOnPurchaseHeader(PurchaseHeader, Vendor."No.");

        // [THEN] "Pay-to Name" in purchase order is "N"
        PurchaseHeader.TestField("Pay-to Name", Vendor.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DropShipPurchLinePayToVendorNotValidated()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Drop Shipment]
        // [SCENARIO 378319] "Pay-to Vendor No." can be changed in purchase order with drop shipment

        // [GIVEN] Drop shipment sale with linked purchase order for vendor "V1"
        Initialize();
        CreateDropShipSalesOrderWithLinkedPurchase(SalesHeader, SalesLine);

        // [GIVEN] Vendor "V2" with Name = "N"
        CreateVendor(Vendor);

        // [WHEN] Change "Pay-to" vendor no. in purchase order: set new vendor = "V2"
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, FindPurchaseHeaderNo(SalesLine."No."));
        UpdatePayToVendorOnPurchaseHeader(PurchaseHeader, Vendor."No.");

        // [THEN] "Pay-to Name" in purchase order is "N"
        PurchaseHeader.TestField("Pay-to Name", Vendor.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCombiningPurchaseOrderForMultipleSalesLinesWithDefferentLocations()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // [FEATURE] [Drop Shipment] [Ship-to Code] [Location]
        // [SCENARIO 362455] Requisition Worksheet creates one Purchase Order if Sales Order Lines have different Location Code from Sales Header during Drop Shipment
        Initialize();

        // [GIVEN] "Ship-to Code" with Location "A" is assigned to a Sales Order
        CreateSalesHeaderWithShipToCodeAndItem(SalesHeader, Item);
        // [GIVEN] The Location Code on the Sales Order is then switched to Location "B"
        UpdateLocationOnSalesHeader(SalesHeader);
        // [GIVEN] Create two Sales Lines with Drop Shipment for Location "B"
        CreateTwoDropShipmentSalesLine(SalesHeader, SalesLine, Item."No.");
        // [GIVEN] Get Drop Shipment Sales Orders
        GetDropShipmentSalesOrders(SalesLine, RequisitionLine);

        // [WHEN] Carry Out Action Message
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        // [THEN] One Purchase Order is created for both Sales Lines
        PurchaseHeader.SetRange("Buy-from Vendor No.", Item."Vendor No.");
        Assert.RecordCount(PurchaseHeader, 1);
        PurchaseLine.SetRange("Buy-from Vendor No.", Item."Vendor No.");
        Assert.RecordCount(PurchaseLine, 2);
    end;

    local procedure Initialize()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Misc.");
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Misc.");

        LibraryERMCountryData.CreateVATData();
        NoSeriesSetup();
        ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LocationSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryInventory.UpdateGenProdPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Misc.");
    end;

    local procedure InitializeRequisitionLine(var RequisitionWkshName: Record "Requisition Wksh. Name"; var RequisitionLine: Record "Requisition Line")
    begin
        FindRequisitionWkshName(RequisitionWkshName);
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
    end;

    local procedure ItemJournalSetup(var ItemJournalTemplate2: Record "Item Journal Template"; var ItemJournalBatch2: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    begin
        ItemJournalTemplate.SetRange(Recurring, false);
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate2, ItemJournalTemplateType);
        ItemJournalTemplate2.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate2.Modify(true);

        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch2, ItemJournalTemplate2.Type, ItemJournalTemplate2.Name);
        ItemJournalBatch2.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch2.Modify(true);
    end;

    local procedure LocationSetup()
    begin
        CreateAndUpdateLocation(LocationBlue, true, true, false, false, false);  // Location Blue with Require Put-Away and Require Pick.
    end;

    local procedure NoSeriesSetup()
    var
        InventorySetup: Record "Inventory Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Item Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Modify(true);

        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure CalculatePlanForRequisitionWorksheet(var RequisitionWkshName: Record "Requisition Wksh. Name"; var Item: Record Item; StartDate: Date; EndDate: Date)
    begin
        FindRequisitionWkshName(RequisitionWkshName);
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, StartDate, EndDate);
    end;

    local procedure CarryOutRequisitionPlan(var RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.FindFirst();
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; BinMandatory: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Put-away", RequirePutAway);
        Location.Validate("Require Pick", RequirePick);
        Location.Validate("Require Receive", RequireReceive);
        Location.Validate("Require Shipment", RequireShipment);
        Location."Bin Mandatory" := BinMandatory;
        Location.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateItemPurchaseReplishment(var Item: Record Item)
    var
        Vendor: Record Vendor;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");

        LibraryPurchase.CreateVendor(Vendor);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);
    end;

    local procedure CreateItemWithVendorNoAndReorderingPolicy(var Item: Record Item; VendorNo: Code[20]; ReorderingPolicy: Enum "Reordering Policy")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", VendorNo);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
    end;

    local procedure CreatePurchasing(SpecialOrder: Boolean; DropShipment: Boolean): Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", SpecialOrder);
        Purchasing.Validate("Drop Shipment", DropShipment);
        Purchasing.Modify(true);

        exit(Purchasing.Code);
    end;

    local procedure CreateSalesHeaderWithShipToCode(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ShipToCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Ship-to Code", ShipToCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesHeaderWithShipToCodeAndItem(var SalesHeader: Record "Sales Header"; var Item: Record Item)
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        Location: Record Location;
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify();

        LibraryWarehouse.CreateLocation(Location);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Location Code", Location.Code);
        Customer.Modify(true);

        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        CreateSalesHeaderWithShipToCode(SalesHeader, Customer."No.", ShipToAddress.Code);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; Reserve: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        if Reserve then
            SalesLine.ShowReservation();
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(50));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLines(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; PurchasingCode: Code[10]; NoOfLines: Integer)
    var
        SalesLine: Record "Sales Line";
        I: Integer;
    begin
        for I := 1 to NoOfLines do
            CreateSalesLineOnNewLocation(SalesLine, SalesHeader, ItemNo, PurchasingCode);
    end;

    local procedure CreateSalesLineOnNewLocation(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; PurchasingCode: Code[10])
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, LibraryRandom.RandDec(100, 2), Location.Code);
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithPurchasingCode(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; PurchasingCode: Code[10])
    begin
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithPurchasing(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SpecialOrder: Boolean; DropShipment: Boolean)
    var
        Item: Record Item;
    begin
        CreateItemPurchaseReplishment(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLines(SalesHeader, Item."No.", CreatePurchasing(SpecialOrder, DropShipment), 1);

        FindSalesLine(SalesLine, SalesHeader);
    end;

    local procedure CreateSpecialSalesOrderWithLinkedPurchase(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        CreateSalesOrderWithPurchasing(SalesHeader, SalesLine, true, false);
        GetSpecialOrders(RequisitionWkshName, SalesLine."No.");
        CarryOutRequisitionPlan(RequisitionWkshName);
    end;

    local procedure CreateDropShipSalesOrderWithLinkedPurchase(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        CreateSalesOrderWithPurchasing(SalesHeader, SalesLine, false, true);
        GetSalesOrders(RequisitionWkshName, SalesLine);
        CarryOutRequisitionPlan(RequisitionWkshName);
    end;

    local procedure CreateTwoDropShipmentSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    var
        PurchasingCode: Code[10];
    begin
        PurchasingCode := CreatePurchasing(false, true);
        CreateSalesLineWithPurchasingCode(
          SalesHeader, SalesLine, ItemNo, LibraryRandom.RandDec(10, 2), '', PurchasingCode);
        CreateSalesLineWithPurchasingCode(
          SalesHeader, SalesLine, ItemNo, LibraryRandom.RandDec(10, 2), '', PurchasingCode);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, LibraryUtility.GenerateGUID());
        Vendor.Modify(true);
    end;

    local procedure CreateVendorWithTaxAreaCode(): Code[20]
    var
        Vendor: Record Vendor;
        TaxArea: Record "Tax Area";
    begin
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Tax Area Code", TaxArea.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure FindPurchaseHeaderNo(ItemNo: Code[20]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        exit(PurchaseLine."Document No.");
    end;

    local procedure FindRequisitionWkshName(var RequisitionWkshName: Record "Requisition Wksh. Name")
    begin
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::"Req.");
        RequisitionWkshName.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure GetDropShipmentSalesOrders(SalesLine: Record "Sales Line"; var RequisitionLine: Record "Requisition Line")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, RetrieveDimensionsFrom::"Sales Line");
    end;

    local procedure GetSalesOrders(var RequisitionWkshName: Record "Requisition Wksh. Name"; SalesLine: Record "Sales Line")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeRequisitionLine(RequisitionWkshName, RequisitionLine);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, 0);
    end;

    local procedure GetSpecialOrders(var RequisitionWkshName: Record "Requisition Wksh. Name"; ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        InitializeRequisitionLine(RequisitionWkshName, RequisitionLine);
        LibraryPlanning.GetSpecialOrder(RequisitionLine, ItemNo);
    end;

    local procedure UpdateLocationOnSalesHeader(var SalesHeader: Record "Sales Header")
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify();
    end;

    local procedure UpdatePayToVendorOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Pay-to Vendor No.", VendorNo);
    end;

    local procedure UpdateUseVendorTaxArea(NewValue: Boolean) PrevValue: Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PrevValue := PurchasesPayablesSetup."Use Vendor's Tax Area Code";
        PurchasesPayablesSetup.Validate("Use Vendor's Tax Area Code", NewValue);
        PurchasesPayablesSetup.Modify(true);
    end;
}

