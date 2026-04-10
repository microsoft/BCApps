// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using System.Environment.Configuration;

codeunit 136133 "Service Stockout"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Availability] [Service]
        IsInitialized := false;
    end;

    var
        LibraryService: Codeunit "Library - Service";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ServiceLines: TestPage "Service Lines";
        IsInitialized: Boolean;
        ZeroQuantity: Integer;
        QuantityToSet: Integer;
        DescriptionText: Label 'NTF_TEST_NTF_TEST';
        NoDataForExecutionError: Label 'No service item has a non-blocked customer and non-blocked item. Execution stops.';
        ValidateQuantityDocumentError: Label 'DocNo %1 not found in following objects: Service Header.';
        ReceiptDateDocumentError: Label 'No Purchase Line found with sales order no %1.';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Stockout");
        // Clear the needed globals
        ClearGlobals();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Stockout");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Stockout");
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ServiceDemandHigherThanSupply()
    var
        TempNotificationContext: Record "Notification Context" temporary;
        ServiceLine: Record "Service Line";
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseOrderNo: Code[20];
        ServiceOrderNo: Code[20];
        PurchaseQuantity: Integer;
        ServiceQuantity: Integer;
        NbNotifs: Integer;
    begin
        // Test availability warning for Service Demand higher than Supply.

        // SETUP: Create Supply with Purchase Order for Item X, Quantity = Y.
        // SETUP: Create Service Demand for Item X,with zero quantity.
        Initialize();
        PurchaseQuantity := LibraryRandom.RandInt(10);
        ServiceQuantity := PurchaseQuantity + 1;
        LibraryInventory.CreateItem(Item);
        PurchaseOrderNo := CreatePurchaseSupply(Item."No.", PurchaseQuantity);
        ServiceOrderNo := CreateServiceDemandAfter(Item."No.", ZeroQuantity, GetReceiptDate(PurchaseOrderNo));

        // EXECUTE: Change Demand Quantity on Service Line Through UI to Quantity = Y + 1.
        // EXECUTE: (Quantity Change set in EditFirstServiceLinesQuantity).
        EditFirstServiceLinesQuantity(ServiceOrderNo, ServiceQuantity);

        // VERIFY: Verify Quantity on Service Order after warning is Y + 1.
        ValidateQuantity(ServiceOrderNo, QuantityToSet);

        // WHEN we decrease the quantity so the item is available (0 items ordered)
        NotificationLifecycleMgt.GetTmpNotificationContext(TempNotificationContext);
        NbNotifs := TempNotificationContext.Count();
        EditFirstServiceLinesQuantity(ServiceOrderNo, 0);

        // THEN the item availability notification is recalled
        Assert.AreEqual(NbNotifs - 1, TempNotificationContext.Count, 'Unexpected number of notifications after decreasing Quantity.');

        // WHEN we change the planning line type
        EditFirstServiceLinesQuantity(ServiceOrderNo, ServiceQuantity);
        Assert.AreEqual(NbNotifs, TempNotificationContext.Count, 'Unexpected number of notifications after increasing Quantity.');
        EditFirstServiceLinesType(ServiceOrderNo, Format(ServiceLine.Type::Resource));

        // THEN the item availability notification is recalled
        Assert.AreEqual(
          NbNotifs - 1, TempNotificationContext.Count, 'Unexpected number of notifications after changing Type to Resource.');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDemandLowerThanSupply()
    var
        Item: Record Item;
        PurchaseOrderNo: Code[20];
        ServiceOrderNo: Code[20];
        PurchaseQuantity: Integer;
        ServiceQuantity: Integer;
    begin
        // Test supply cover demand and therefore no warning.

        // SETUP: Create Supply for Item X.
        Initialize();
        PurchaseQuantity := LibraryRandom.RandInt(10);
        ServiceQuantity := PurchaseQuantity - 1;
        LibraryInventory.CreateItem(Item);
        PurchaseOrderNo := CreatePurchaseSupply(Item."No.", PurchaseQuantity);
        ServiceOrderNo := CreateServiceDemandAfter(Item."No.", ZeroQuantity, GetReceiptDate(PurchaseOrderNo));

        // EXECUTE: Create Service Demand for Item X at a date after Supply is arrived and quantity less than supply.
        // EXECUTE: (Quantity Change set in EditFirstServiceLinesQuantity).
        EditFirstServiceLinesQuantity(ServiceOrderNo, ServiceQuantity);

        // VERIFY: No availability warning is displayed.
        // VERIFY: Quantity remains same.
        ValidateQuantity(ServiceOrderNo, QuantityToSet);
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ServiceDemandBeforeSupply()
    var
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ServiceOrderNo: Code[20];
        PurchaseQuantity: Integer;
        ServiceQuantity: Integer;
    begin
        // Test availability warning if Service Demand is at a date before Supply arrives.

        // SETUP: Create Service Demand for Item X,with zero quantity
        // SETUP: Create Supply with Purchase Order for Item X, Qantity=Y, at a date after service Demand
        Initialize();
        PurchaseQuantity := LibraryRandom.RandInt(10) * 2;  // Taking Minimum Value as 2 as the Sale Quantity should not be zero.
        ServiceQuantity := PurchaseQuantity - 1;
        LibraryInventory.CreateItem(Item);
        ServiceOrderNo := CreateServiceDemand(Item."No.", ZeroQuantity);
        CreatePurchaseSupplyAfter(Item."No.", PurchaseQuantity, GetNeededByDate(ServiceOrderNo));

        // EXECUTE: Change Demand Quantity on Service Order Through UI to Quantity = Y - 1..
        // EXECUTE:  (Quantity Change set in EditFirstServiceLinesQuantity).
        EditFirstServiceLinesQuantity(ServiceOrderNo, ServiceQuantity);

        // VERIFY: Quantity on Service order after warning is Y - 1.
        ValidateQuantity(ServiceOrderNo, QuantityToSet);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ServiceSupplyLocationDifferent()
    var
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseQuantity: Integer;
        ServiceQuantity: Integer;
        LocationA: Code[10];
        LocationB: Code[10];
        PurchaseOrderNo: Code[20];
        ServiceOrderNo: Code[20];
    begin
        // Test availability warning if Service Demand is at a different Location than a supply from purchase.

        // SETUP: Create Supply with Purchase Order for Item X, Qantity=Y, Location = Z.
        // SETUP: Create Service Demand for Item X, Quantity=0, Location = M
        Initialize();
        PurchaseQuantity := LibraryRandom.RandInt(10) * 2;  // Taking Minimum Value as 2 as the Sale Quantity should not be zero.
        ServiceQuantity := PurchaseQuantity - 1;
        LibraryInventory.CreateItem(Item);
        LocationA := CreateLocation();
        LocationB := CreateLocation();
        PurchaseOrderNo := CreatePurchaseSupplyAtLocation(Item."No.", PurchaseQuantity, LocationA);
        ServiceOrderNo := CreateServiceDemandLocatnAfter(Item."No.", ZeroQuantity, LocationB, GetReceiptDate(PurchaseOrderNo));

        // EXECUTE: Change Demand Quantity on Service Order Through UI to Quantity = Y - 1.
        // EXECUTE: (Quantity Change set in EditFirstServiceLinesQuantity).
        EditFirstServiceLinesQuantity(ServiceOrderNo, ServiceQuantity);

        // VERIFY: Verify Quantity on Service order after warning is Y - 1.
        ValidateQuantity(ServiceOrderNo, QuantityToSet);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ServiceSupplyVariantDifferent()
    var
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseOrderNo: Code[20];
        ServiceOrderNo: Code[20];
        PurchaseQuantity: Integer;
        ServiceQuantity: Integer;
    begin
        // Test availability warning if Service Demand is for a different Variant than Supply from purchase.

        // SETUP: Create Supply with Purchase Order for Item X, Qantity=Y, Location = Z, Variant = V1.
        // SETUP: Create Service Demand for Item X, Quantity=0, Location = Z, Variant=V2
        Initialize();
        PurchaseQuantity := LibraryRandom.RandInt(10) * 2;  // Taking Minimum Value as 2 as the Sale Quantity should not be zero.
        ServiceQuantity := PurchaseQuantity - 1;
        CreateItemWithVariants(Item);
        PurchaseOrderNo := CreatePurchaseSupplyForVariant(Item."No.", PurchaseQuantity, 1);
        ServiceOrderNo :=
          CreateServiceDemandVarintAfter(Item."No.", ZeroQuantity, GetVariant(Item."No.", 2), GetReceiptDate(PurchaseOrderNo));

        // EXECUTE: Change Demand Quantity on Service Order Through UI to Quantity = Y - 1.
        // EXECUTE: (Quantity Change set in EditFirstServiceLinesQuantity).
        EditFirstServiceLinesQuantity(ServiceOrderNo, ServiceQuantity);

        // VERIFY: Quantity on Service order after warning is Y - 1.
        ValidateQuantity(ServiceOrderNo, QuantityToSet);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ServiceChangeLocation()
    var
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseQuantity: Integer;
        ServiceQuantity: Integer;
        LocationA: Code[10];
        LocationB: Code[10];
        PurchaseOrderNo: Code[20];
        ServiceOrderNo: Code[20];
    begin
        // Test availability warning if the location for Service Demand modified to a location where demand cannot be met

        // SETUP: Create Supply with Purchase Order for Item X, Qantity=Y, Location = Z.
        // SETUP: Create Service Demand for Item X, Quantity=Y, Location = Z
        Initialize();
        PurchaseQuantity := LibraryRandom.RandInt(10);
        ServiceQuantity := PurchaseQuantity;
        LibraryInventory.CreateItem(Item);
        LocationA := CreateLocation();
        LocationB := CreateLocation();
        PurchaseOrderNo := CreatePurchaseSupplyAtLocation(Item."No.", PurchaseQuantity, LocationA);
        ServiceOrderNo := CreateServiceDemandLocatnAfter(Item."No.", ServiceQuantity, LocationA, GetReceiptDate(PurchaseOrderNo));

        // EXECUTE: Change Location on Service Order Through UI to location M.
        // EXECUTE: (Location Change set in EditServiceLinesLocation).
        QuantityToSet := ServiceQuantity;
        EditFirstServiceLinesLocation(ServiceOrderNo, LocationB);

        // VERIFY: Verify Quantity on service order after warning is Y and location M.
        ValidateQuantity(ServiceOrderNo, QuantityToSet);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ServiceChangeDate()
    var
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseOrderNo: Code[20];
        ServiceOrderNo: Code[20];
        PurchaseQuantity: Integer;
        ServiceQuantity: Integer;
    begin
        // Test availability warning if the date of Service Demand is modified to a date where demand cannot be met

        // SETUP: Create Supply with Purchase Order for Item X, Qantity=Y, Date = Workdate.
        // SETUP: Create Service Demand for Item X, Quantity=Y, Date = WorkDate() + 1
        Initialize();
        PurchaseQuantity := LibraryRandom.RandInt(10);
        ServiceQuantity := PurchaseQuantity;
        LibraryInventory.CreateItem(Item);
        ServiceOrderNo := CreateServiceDemand(Item."No.", ServiceQuantity);
        PurchaseOrderNo := CreatePurchaseSupplyAfter(Item."No.", PurchaseQuantity, GetNeededByDate(ServiceOrderNo));
        ServiceOrderNo := CreateServiceDemandAfter(Item."No.", ServiceQuantity, GetReceiptDate(PurchaseOrderNo));

        // EXECUTE: Change Date on Service Order Through UI to Date = WorkDate() - 1.
        // EXECUTE: (Date Change set in EditServiceLinesNeededByDate).
        QuantityToSet := ServiceQuantity;
        EditFirstServiceLinesNeedDate(ServiceOrderNo);

        // VERIFY: Quantity on service order after warning is Y and Date is WorkDate() - 1.
        ValidateQuantity(ServiceOrderNo, QuantityToSet);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceMultipleSupplyForDemand()
    var
        Item: Record Item;
        PurchaseOrderNo: Code[20];
        ServiceOrderNo: Code[20];
        PurchaseQuantity: Integer;
        ServiceQuantity: Integer;
    begin
        // Test that multible supplies can cover Demand from Service.

        // SETUP: Create Supply with Purchase Order for Item X, Quantity = Y1
        // SETUP: Create Supply with Purchase Order for Item X, Quantity = Y2
        // SETUP: Create Service Order Demand for Item X, Quantity=0
        Initialize();
        PurchaseQuantity := LibraryRandom.RandInt(10);
        ServiceQuantity := PurchaseQuantity * 2;
        LibraryInventory.CreateItem(Item);
        PurchaseOrderNo := CreatePurchaseSupply(Item."No.", PurchaseQuantity);
        PurchaseOrderNo := CreatePurchaseSupplyAfter(Item."No.", PurchaseQuantity, GetReceiptDate(PurchaseOrderNo));
        ServiceOrderNo := CreateServiceDemandAfter(Item."No.", ZeroQuantity, GetReceiptDate(PurchaseOrderNo));

        // EXECUTE: Change Quantity on Service Order Through UI to Y1+Y2-1.
        EditFirstServiceLinesQuantity(ServiceOrderNo, ServiceQuantity);

        // VERIFY: No Availability Warning occur.
        // VERIFY: Quantity on Service Order after warning is Y1+Y2-1.
        ValidateQuantity(ServiceOrderNo, QuantityToSet);
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure MixedDemandForSupply()
    var
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        JobNo: Code[20];
        PurchaseOrderNo: Code[20];
        ServiceOrderNo: Code[20];
        PurchaseQuantity: Integer;
        ServiceQuantity: Integer;
        JobQuantity: Integer;
    begin
        // Test availability warning for multiple Demands from Service, Jobs, and service for one Supply.

        // SETUP: Create Demand From service for Item X, Qantity = Y1
        // SETUP: Create Job Planning Line Demand for Item X, Quantity=Y2
        // SETUP: Create Service Order Demand for Item X, Quantity=0
        // SETUP: Create Supply with Purchase Order for Item X, Quantity = Y1+Y2+Y3 - 1.
        Initialize();
        PurchaseQuantity := 10;
        JobQuantity := PurchaseQuantity / 2;
        ServiceQuantity := PurchaseQuantity - JobQuantity + 1;
        LibraryInventory.CreateItem(Item);
        PurchaseOrderNo := CreatePurchaseSupply(Item."No.", PurchaseQuantity);
        JobNo := CreateJobDemandAfter(Item."No.", JobQuantity, GetReceiptDate(PurchaseOrderNo));
        ServiceOrderNo := CreateServiceDemandAfter(Item."No.", ZeroQuantity, GetPlanningDate(JobNo));

        // EXECUTE: Change Quantity on Service Order Through UI to Y3.
        // EXECUTE: (Quantity Change set in EditFirstServiceLinesQuantity).
        EditFirstServiceLinesQuantity(ServiceOrderNo, ServiceQuantity);

        // VERIFY: Verify Quantity on Service Order after warning is Y3.
        ValidateQuantity(ServiceOrderNo, QuantityToSet);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Normal]
    local procedure ClearGlobals()
    begin
        // Clear all global variables
        ZeroQuantity := 0;
        Clear(ServiceLines);
        QuantityToSet := 0;
    end;

    [Normal]
    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        // Creates a new Location. Wrapper for the library method.
        LibraryWarehouse.CreateLocation(Location);
        exit(Location.Code);
    end;

    local procedure CreatePurchaseSupplyBasis(ItemNo: Code[20]; Quantity: Integer; LocationCode: Code[10]; VariantCode: Code[10]; ReceiptDate: Date): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Creates a Purchase order for the given item.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate(Quantity, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Validate("Expected Receipt Date", ReceiptDate);
        PurchaseLine.Modify();
        exit(PurchaseHeader."No.");
    end;

    local procedure CreatePurchaseSupply(ItemNo: Code[20]; ItemQuantity: Integer): Code[20]
    begin
        // Creates a Purchase order for the given item.
        exit(CreatePurchaseSupplyBasis(ItemNo, ItemQuantity, '', '', WorkDate()));
    end;

    local procedure CreatePurchaseSupplyAtLocation(ItemNo: Code[20]; ItemQuantity: Integer; LocationCode: Code[10]): Code[20]
    begin
        // Creates a Purchase order for the given item at the specified location.
        exit(CreatePurchaseSupplyBasis(ItemNo, ItemQuantity, LocationCode, '', WorkDate()));
    end;

    local procedure CreatePurchaseSupplyForVariant(ItemNo: Code[20]; ItemQuantity: Integer; VariantNo: Integer): Code[20]
    begin
        // Creates a Purchase order for the given item.
        exit(CreatePurchaseSupplyBasis(ItemNo, ItemQuantity, '', GetVariant(ItemNo, VariantNo), WorkDate()));
    end;

    local procedure CreatePurchaseSupplyAfter(ItemNo: Code[20]; Quantity: Integer; ReceiptDate: Date): Code[20]
    begin
        // Creates a Purchase order for the given item After a source document date.
        exit(CreatePurchaseSupplyBasis(ItemNo, Quantity, '', '', CalcDate('<+1D>', ReceiptDate)));
    end;

    local procedure CreateServiceDemandBasis(ItemNo: Code[20]; ItemQty: Integer; LocationCode: Code[10]; VariantCode: Code[10]; NeededBy: Date): Code[20]
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        FindServiceItem(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        ServiceHeader.Validate("Bill-to Name", DescriptionText);
        ServiceHeader.Modify();

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ServiceItemLine.Validate("Line No.", 10000);
        ServiceItemLine.Modify();

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.SetHideReplacementDialog(true);
        ServiceLine.Validate(Quantity, ItemQty);
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Validate("Variant Code", VariantCode);
        ServiceLine.Validate("Needed by Date", NeededBy);
        ServiceLine.Validate("Variant Code", VariantCode);
        ServiceLine.Modify();

        exit(ServiceHeader."No.");
    end;

    local procedure CreateServiceDemand(ItemNo: Code[20]; Quantity: Integer): Code[20]
    begin
        exit(CreateServiceDemandBasis(ItemNo, Quantity, '', '', WorkDate()));
    end;

    local procedure CreateServiceDemandAfter(ItemNo: Code[20]; Quantity: Integer; NeededByDate: Date): Code[20]
    begin
        exit(CreateServiceDemandBasis(ItemNo, Quantity, '', '', CalcDate('<+1D>', NeededByDate)));
    end;

    local procedure CreateServiceDemandVarintAfter(ItemNo: Code[20]; Quantity: Integer; VariantCode: Code[10]; NeededByDate: Date): Code[20]
    begin
        exit(CreateServiceDemandBasis(ItemNo, Quantity, '', VariantCode, CalcDate('<+1D>', NeededByDate)));
    end;

    local procedure CreateServiceDemandLocatnAfter(ItemNo: Code[20]; Quantity: Integer; LocationCode: Code[10]; NeededByDate: Date): Code[20]
    begin
        exit(CreateServiceDemandBasis(ItemNo, Quantity, LocationCode, '', CalcDate('<+1D>', NeededByDate)));
    end;

    local procedure CreateJobDemandAfter(ItemNo: Code[20]; ItemQuantity: Integer; PlanDate: Date): Code[20]
    var
        Job: Record Job;
        JobTaskLine: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        DocumentNo: Code[20];
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", true);
        Job.Validate("Description 2", DescriptionText);
        Job.Modify();

        // Job Task Line:
        LibraryJob.CreateJobTask(Job, JobTaskLine);
        JobTaskLine.Modify();

        // Job Planning Line:
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget,
          JobPlanningLine.Type::Item, JobTaskLine, JobPlanningLine);

        JobPlanningLine.Validate("Planning Date", PlanDate);
        JobPlanningLine.Validate("Usage Link", true);

        DocumentNo := DelChr(Format(Today), '=', '-/') + '_' + DelChr(Format(Time), '=', ':');
        JobPlanningLine.Validate("Document No.", DocumentNo);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate(Quantity, ItemQuantity);
        JobPlanningLine.Modify();

        exit(Job."No.");
    end;

    [Normal]
    local procedure CreateItemWithVariants(var Item: Record Item)
    var
        ItemVariantA: Record "Item Variant";
        ItemVariantB: Record "Item Variant";
    begin
        // Creates a new item with a variant.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariantA, Item."No.");
        ItemVariantA.Validate(Description, Item.Description);
        ItemVariantA.Modify();
        LibraryInventory.CreateItemVariant(ItemVariantB, Item."No.");
        ItemVariantB.Validate(Description, Item.Description);
        ItemVariantB.Modify();
    end;

    [Normal]
    local procedure EditFirstServiceLinesType(ServiceOrderNo: Code[20]; ServiceLineType: Text)
    var
        DummyServiceLinesToReturn: TestPage "Service Lines";
    begin
        OpenFirstServiceLines(DummyServiceLinesToReturn, ServiceOrderNo);
        ServiceLines := DummyServiceLinesToReturn;
        DummyServiceLinesToReturn.Type.Value(ServiceLineType);
    end;

    [Normal]
    local procedure EditFirstServiceLinesQuantity(ServiceOrderNo: Code[20]; ServiceLineQuantity: Integer)
    var
        ServiceLinesToReturn: TestPage "Service Lines";
    begin
        OpenFirstServiceLines(ServiceLinesToReturn, ServiceOrderNo);
        QuantityToSet := ServiceLineQuantity;
        ServiceLines := ServiceLinesToReturn;
        ServiceLinesToReturn.Quantity.Value(Format(QuantityToSet));
    end;

    [Normal]
    local procedure EditFirstServiceLinesLocation(ServiceOrderNo: Code[20]; LocationB: Code[10])
    var
        ServiceLinesToReturn: TestPage "Service Lines";
    begin
        OpenFirstServiceLines(ServiceLinesToReturn, ServiceOrderNo);
        ServiceLines := ServiceLinesToReturn;
        ServiceLinesToReturn."Location Code".Value(LocationB);
    end;

    [Normal]
    local procedure EditFirstServiceLinesNeedDate(ServiceOrderNo: Code[20])
    var
        ServiceLinesToReturn: TestPage "Service Lines";
    begin
        OpenFirstServiceLines(ServiceLinesToReturn, ServiceOrderNo);
        ServiceLines := ServiceLinesToReturn;
        ServiceLinesToReturn."Needed by Date".Value(Format(WorkDate()));
    end;

    local procedure FindServiceItem(var ServiceItem: Record "Service Item")
    var
        Item: Record Item;
        Customer: Record Customer;
    begin
        Clear(ServiceItem);
        if ServiceItem.FindFirst() then
            repeat
                Customer.Get(ServiceItem."Customer No.");
                Item.Get(ServiceItem."Item No.");
                if (Customer.Blocked = Customer.Blocked::" ") and not Item.Blocked then
                    exit;
            until ServiceItem.Next() = 0;
        Error(NoDataForExecutionError);
    end;

    local procedure GetReceiptDate(PurchaseHeaderNo: Code[20]): Date
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Method returns the expected receipt date from a purchase order.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeaderNo);
        PurchaseLine.FindFirst();
        if PurchaseLine.Count > 0 then
            exit(PurchaseLine."Expected Receipt Date");
        Error(ReceiptDateDocumentError, PurchaseHeaderNo);
    end;

    local procedure GetNeededByDate(ServiceHeaderNo: Code[20]): Date
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceHeaderNo);
        ServiceLine.FindFirst();
        exit(ServiceLine."Needed by Date");
    end;

    local procedure GetPlanningDate(JobNo: Code[20]): Date
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.FindFirst();
        exit(JobPlanningLine."Planning Date");
    end;

    local procedure GetVariant(ItemNo: Code[20]; VarNo: Integer): Code[10]
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.SetRange("Item No.", ItemNo);
        ItemVariant.Find('-');
        if VarNo > 1 then
            ItemVariant.Next(VarNo - 1);
        exit(ItemVariant.Code);
    end;

    [Normal]
    local procedure OpenFirstServiceLines(ServiceLinesToReturn: TestPage "Service Lines"; ServiceOrderNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceLineToSelect: Record "Service Line";
        LineNo: Text;
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, ServiceOrderNo);
        ServiceLinesToReturn.OpenEdit();

        ServiceLineToSelect.SetRange("Document No.", ServiceOrderNo);
        ServiceLineToSelect.SetRange("Document Type", ServiceLineToSelect."Document Type"::Order);
        ServiceLineToSelect.FindFirst();

        LineNo := Format(ServiceLineToSelect."Line No.");
        ServiceLinesToReturn.First();
        ServiceLinesToReturn.FILTER.SetFilter("Document No.", ServiceOrderNo);
        ServiceLinesToReturn.FILTER.SetFilter("Document Type", 'Order');
        ServiceLinesToReturn.FILTER.SetFilter("Line No.", LineNo);
        ServiceLinesToReturn.First();
    end;

    local procedure ValidateQuantity(DocumentNo: Code[20]; Quantity: Integer)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Method verifies the quantity on a service order.
        if ServiceHeader.Get(ServiceHeader."Document Type"::Order, DocumentNo) then begin
            ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
            ServiceLine.SetRange("Document No.", ServiceHeader."No.");
            ServiceLine.FindFirst();
            Assert.AreEqual(Quantity, ServiceLine.Quantity, 'Verify Sales Line Quantity matches expected');
            exit;
        end;

        Error(ValidateQuantityDocumentError, DocumentNo);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendAvailabilityNotificationHandler(var Notification: Notification): Boolean
    var
        Item: Record Item;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        Quantity: Integer;
        Inventory: Decimal;
        TotalQuantity: Decimal;
        ReservedQty: Decimal;
        SchedRcpt: Decimal;
        ReservedRcpt: Decimal;
        GrossReq: Decimal;
        ReservedReq: Decimal;
    begin
        Item.Get(ServiceLines."No.".Value);
        Assert.AreEqual(Notification.GetData('ItemNo'), Item."No.", 'Item No. was different than expected');
        Item.CalcFields(Inventory);
        Evaluate(Inventory, Notification.GetData('InventoryQty'));
        Assert.AreEqual(Inventory, Item.Inventory, 'Available Inventory was different than expected');
        Evaluate(Quantity, Notification.GetData('CurrentQuantity'));
        Evaluate(TotalQuantity, Notification.GetData('TotalQuantity'));
        Evaluate(ReservedQty, Notification.GetData('CurrentReservedQty'));
        Evaluate(ReservedReq, Notification.GetData('ReservedReq'));
        Evaluate(SchedRcpt, Notification.GetData('SchedRcpt'));
        Evaluate(GrossReq, Notification.GetData('GrossReq'));
        Evaluate(ReservedRcpt, Notification.GetData('ReservedRcpt'));
        Assert.AreEqual(TotalQuantity, Inventory - Quantity + (SchedRcpt - ReservedRcpt) - (GrossReq - ReservedReq),
          'Total quantity different than expected');
        Assert.AreEqual(Quantity, QuantityToSet, 'Quantity was different than expected');
        Assert.AreEqual(Notification.GetData('UnitOfMeasureCode'), ServiceLines."Unit of Measure Code".Value, '');
        ItemCheckAvail.ShowNotificationDetails(Notification);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NotificationDetailsHandler(var ItemAvailabilityCheck: TestPage "Item Availability Check")
    var
        Item: Record Item;
    begin
        Item.Get(ServiceLines."No.".Value);
        Item.CalcFields(Inventory);
        ItemAvailabilityCheck.AvailabilityCheckDetails."No.".AssertEquals(Item."No.");
        ItemAvailabilityCheck.AvailabilityCheckDetails.Description.AssertEquals(Item.Description);
        ItemAvailabilityCheck.AvailabilityCheckDetails.CurrentQuantity.AssertEquals(QuantityToSet);
        ItemAvailabilityCheck.InventoryQty.AssertEquals(Item.Inventory);
    end;
}

