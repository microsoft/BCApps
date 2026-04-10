// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Posting;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Setup;

codeunit 136141 "Service Order Release validate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Order] [Status] [Service]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorPostWarehouseShipmenReopenedOrder()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
    begin
        Initialize();
        CreateAndReleaseServOrder(ServHeader, ServiceLine, ServiceItemLine);
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServHeader);
        LibraryService.ReopenServiceDocument(ServHeader);
        WhseShptHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Service Line", ServHeader."Document Type".AsInteger(), ServHeader."No."));
        // to be done later as part of next deliverable with 'pick'
        asserterror LibraryWarehouse.PostWhseShipment(WhseShptHeader, false);
    end;

    [Test]
    [HandlerFunctions('HandleStrMenu')]
    [Scope('OnPrem')]
    procedure AssertErrorPostAfterRelease()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        Initialize();
        CreateAndReleaseServOrder(ServHeader, ServiceLine, ServiceItemLine);
        asserterror ServPostYesNo.PostDocumentWithLines(ServHeader, ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineGeneralProductPostingGroup()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        Initialize();
        CreateAndReleaseServOrder(ServiceHeader, ServiceLine, ServiceItemLine);
        asserterror ServiceLine.Validate("Gen. Prod. Posting Group", CreateNewGenPPGroup());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineJobRemainQuantity()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        Initialize();
        CreateAndReleaseServOrder(ServHeader, ServiceLine, ServiceItemLine);
        asserterror ServiceLine.Validate("Job Remaining Qty.", (ServiceLine."Job Remaining Qty." - 1.0));
        asserterror ServiceLine.Validate("Job Remaining Qty.", (ServiceLine."Job Remaining Qty." + 1.0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineAllowInvoiceDiscount()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        Initialize();
        CreateAndReleaseServOrder(ServHeader, ServiceLine, ServiceItemLine);
        asserterror ServiceLine.Validate("Allow Invoice Disc.", (not ServiceLine."Allow Invoice Disc."));
    end;

    [Test]
    [HandlerFunctions('HandleServiceLinePageLineDiscountPct')]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineLineDiscountPercent()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceOrderTP: TestPage "Service Order";
    begin
        Initialize();
        CreateAndReleaseServOrder(ServHeader, ServiceLine, ServiceItemLine);
        ServiceOrderTP.OpenNew();
        ServiceOrderTP.GotoRecord(ServHeader);
        ServiceOrderTP.ServItemLines."Service Lines".Invoke();
        ServiceOrderTP.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineLineDiscountAmount()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        Initialize();
        CreateAndReleaseServOrder(ServHeader, ServiceLine, ServiceItemLine);
        asserterror ServiceLine.Validate("Line Discount Amount", (10 + ServiceLine."Line Discount Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineLocation()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        Location: Record Location;
    begin
        Initialize();
        CreateAndReleaseServOrder(ServiceHeader, ServiceLine, ServiceItemLine);
        Location.SetFilter(Code, '<>%1', ServiceLine."Location Code");
        Location.FindFirst();
        asserterror ServiceLine.Validate("Location Code", Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineLocationWarehouseShipment()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        Location: Record Location;
    begin
        Initialize();
        Location.SetFilter(Code, '<>%1', ServiceLine."Location Code");
        if Location.FindFirst() then
            asserterror ServiceLine.Validate("Location Code", Location.Code);
        CreateWhsShpReopenOrder(ServiceHeader, ServiceItemLine, ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineNeedByDate()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        NeedDate: Date;
    begin
        Initialize();
        CreateAndReleaseServOrder(ServHeader, ServiceLine, ServiceItemLine);
        NeedDate := ServiceLine."Needed by Date";
        if NeedDate <> 0D then
            asserterror
              ServiceLine.Validate("Needed by Date", CalcDate('<+6M>', NeedDate))
        else
            asserterror ServiceLine.Validate("Needed by Date", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineNo()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        Initialize();
        CreateAndReleaseServOrder(ServiceHeader, ServiceLine, ServiceItemLine);
        asserterror ServiceLine.Validate("No.", LibraryInventory.CreateItemNo());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLinenoWarehouseShipment()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        Initialize();
        CreateWhsShpReopenOrder(ServiceHeader, ServiceItemLine, ServiceLine);
        asserterror ServiceLine.Validate("No.", LibraryInventory.CreateItemNo());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLinePlanDeliveryDate()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        PlanDate: Date;
    begin
        Initialize();
        CreateAndReleaseServOrder(ServHeader, ServiceLine, ServiceItemLine);
        PlanDate := ServiceLine."Planned Delivery Date";
        if PlanDate <> 0D then
            asserterror
              ServiceLine.Validate("Planned Delivery Date", CalcDate('<+6M>', PlanDate))
        else
            asserterror ServiceLine.Validate("Planned Delivery Date", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineQuantity()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        Initialize();
        CreateAndReleaseServOrder(ServHeader, ServiceLine, ServiceItemLine);
        asserterror ServiceLine.Validate(Quantity, (ServiceLine.Quantity + 1.0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineQuantityWarehouseShipment()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        Initialize();
        CreateWhsShpReopenOrder(ServHeader, ServiceItemLine, ServiceLine);
        asserterror ServiceLine.Validate(Quantity, (ServiceLine.Quantity + 1.0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineQuantityInvoice()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        Initialize();
        CreateAndReleaseServOrder(ServHeader, ServiceLine, ServiceItemLine);
        asserterror ServiceLine.Validate("Qty. to Invoice", (ServiceLine."Qty. to Invoice" + 1.0));
    end;

    [Test]
    [HandlerFunctions('HandleServiceLinePageQtyToShip')]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineQuantityShip()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceOrderTP: TestPage "Service Order";
    begin
        Initialize();
        CreateAndReleaseServOrder(ServHeader, ServiceLine, ServiceItemLine);
        ServiceOrderTP.OpenNew();
        ServiceOrderTP.GotoRecord(ServHeader);
        ServiceOrderTP.ServItemLines."Service Lines".Invoke();
        ServiceOrderTP.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineType()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        Initialize();
        CreateAndReleaseServOrder(ServHeader, ServiceLine, ServiceItemLine);
        Commit();
        asserterror ServiceLine.Validate(Type, ServiceLine.Type::Resource);
        asserterror ServiceLine.Validate(Type, ServiceLine.Type::Cost);
        asserterror ServiceLine.Validate(Type, ServiceLine.Type::"G/L Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineTypeWarehouseShipment()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        Initialize();
        CreateWhsShpReopenOrder(ServHeader, ServiceItemLine, ServiceLine);
        Commit();
        asserterror ServiceLine.Validate(Type, ServiceLine.Type::Resource);
        asserterror ServiceLine.Validate(Type, ServiceLine.Type::Cost);
        asserterror ServiceLine.Validate(Type, ServiceLine.Type::"G/L Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineUOMCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
    begin
        Initialize();
        CreateAndReleaseServOrder(ServiceHeader, ServiceLine, ServiceItemLine);
        ItemUOM.SetRange("Item No.", ServiceLine."No.");
        ItemUOM.SetFilter(Code, '<>%1', ServiceLine."Unit of Measure Code");
        if ItemUOM.FindFirst() then
            asserterror ServiceLine.Validate("Unit of Measure Code", ItemUOM.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineCodeWarehouseShipment()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
    begin
        Initialize();
        CreateWhsShpReopenOrder(ServiceHeader, ServiceItemLine, ServiceLine);
        ItemUOM.SetRange("Item No.", ServiceLine."No.");
        ItemUOM.SetFilter(Code, '<>%1', ServiceLine."Unit of Measure Code");
        if ItemUOM.FindFirst() then
            asserterror ServiceLine.Validate("Unit of Measure Code", ItemUOM.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineVariantCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ItemVariant: Record "Item Variant";
    begin
        Initialize();
        CreateAndReleaseServOrder(ServiceHeader, ServiceLine, ServiceItemLine);
        ItemVariant.SetRange("Item No.", ServiceLine."No.");
        ItemVariant.SetFilter(Code, '<>%1', ServiceLine."Variant Code");
        if ItemVariant.FindFirst() then
            asserterror ServiceLine.Validate("Variant Code", ItemVariant.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertErrorServiceLineVariantCodeWarehouseShipment()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ItemVariant: Record "Item Variant";
    begin
        Initialize();
        CreateWhsShpReopenOrder(ServiceHeader, ServiceItemLine, ServiceLine);
        ItemVariant.SetRange("Item No.", ServiceLine."No.");
        ItemVariant.SetFilter(Code, '<>%1', ServiceLine."Variant Code");
        if ItemVariant.FindFirst() then
            asserterror ServiceLine.Validate("Variant Code", ItemVariant.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssertReopenServiceOrderWarehouseShipment()
    var
        ServHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceLine2: Record "Service Line";
    begin
        Initialize();
        CreateServiceOrder(ServHeader, ServiceLine, ServiceItemLine);
        ServiceLine2.Copy(ServiceLine);
        LibraryService.ReleaseServiceDocument(ServHeader);
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServHeader);
        LibraryService.ReopenServiceDocument(ServHeader);
        Assert.AreEqual(ServHeader."Release Status"::Open, ServHeader."Release Status", 'Verify Release Status');
        Assert.AreEqual(ServHeader.Status::Pending, ServHeader.Status, 'Verify Status of Service Header');
    end;

    [Normal]
    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServiceItemLine: Record "Service Item Line")
    var
        ServiceItem: Record "Service Item";
    begin
        CreateServiceItem(ServiceItem, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo());
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItem);
    end;

    local procedure CreateAndReleaseServOrder(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServiceItemLine: Record "Service Item Line")
    begin
        CreateServiceOrder(ServiceHeader, ServiceLine, ServiceItemLine);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
    end;

    [Normal]
    local procedure CreateWhsShpReopenOrder(var ServHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; var ServiceLine: Record "Service Line")
    begin
        CreateAndReleaseServOrder(ServHeader, ServiceLine, ServiceItemLine);
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServHeader);
        LibraryService.ReopenServiceDocument(ServHeader);
    end;

    [Normal]
    local procedure CreateNewGenPPGroup(): Code[10]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VatProductPostingGroup: Record "VAT Product Posting Group";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        VatProductPostingGroup.FindFirst();
        GenProductPostingGroup."Def. VAT Prod. Posting Group" := VatProductPostingGroup.Code;
        GenProductPostingGroup."Auto Insert Default" := true;
        GenProductPostingGroup.Modify(true);
        exit(GenProductPostingGroup.Code);
    end;

    local procedure CreateServiceItem(var ServiceItem: Record "Service Item"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Item No.", ItemNo);
        ServiceItem.Modify(true);
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItem: Record "Service Item")
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate("Service Item No.", ServiceItem."No.");
        // Use Random For Quantity and Quantity to Consume.
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Location Code", GetWhiteLocation());
        ServiceLine.Modify(true);
    end;

    [Normal]
    local procedure GetWhiteLocation(): Code[10]
    var
        LocationWhite: Record Location;
    begin
        LocationWhite.SetRange("Directed Put-away and Pick", true);
        LocationWhite.FindFirst();
        exit(LocationWhite.Code);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure HandleStrMenu(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        // Select the ship option
        Choice := 1;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleServiceLinePageLineDiscountPct(var ServiceLinesPage: TestPage "Service Lines")
    var
        Disc: Decimal;
    begin
        if ServiceLinesPage."Line Discount %".Value = '' then
            Disc := 0
        else
            Evaluate(Disc, ServiceLinesPage."Line Discount %".Value);
        asserterror ServiceLinesPage."Line Discount %".SetValue(99.55 - Disc);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandleServiceLinePageQtyToShip(var ServiceLinesPage: TestPage "Service Lines")
    var
        QtyToShip: Decimal;
    begin
        if ServiceLinesPage."Qty. to Ship".Value = '' then
            QtyToShip := 0
        else
            Evaluate(QtyToShip, ServiceLinesPage."Qty. to Ship".Value);
        asserterror ServiceLinesPage."Qty. to Ship".SetValue(1 + QtyToShip);
    end;

    local procedure Initialize()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Order Release validate");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Order Release validate");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, GetWhiteLocation(), false);
        Commit();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Order Release validate");
    end;
}

