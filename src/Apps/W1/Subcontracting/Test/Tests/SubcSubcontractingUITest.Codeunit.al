// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using System.Reflection;

codeunit 139990 "Subc. Subcontracting UI Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Subcontracting Management
        IsInitialized := false;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Subcontracting UI Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Subcontracting UI Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Subcontracting UI Test");
    end;

    [Test]
    procedure CheckCustCtrl_PagePurchaseOrderSubContractingLocationCode()
    var
        PageControl: Record "Page Control Field";
        PurchHeader: Record "Purchase Header";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Purchase Header"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Purchase Header");
        PageControl.SetRange(PageNo, Page::"Purchase Order");
        PageControl.SetRange(FieldNo, PurchHeader.FieldNo("Subc. Location Code"));
        ControlExist := not PageControl.IsEmpty();
        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, PurchHeader.FieldCaption("Subc. Location Code")));
    end;

    [Test]
    procedure CheckCustCtrl_PagePurchaseOrderSubContractingOrder()
    var
        PageControl: Record "Page Control Field";
        PurchHeader: Record "Purchase Header";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Purchase Header"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Purchase Header");
        PageControl.SetRange(PageNo, Page::"Purchase Order");
        PageControl.SetRange(FieldNo, PurchHeader.FieldNo("Subc. Order"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, PurchHeader.FieldCaption("Subc. Order")));
    end;

    [Test]
    procedure CheckCustCtrl_PageVendorCardSubContractingLocationCode()
    var
        PageControl: Record "Page Control Field";
        Vendor: Record Vendor;
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Vendor Card"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::Vendor);
        PageControl.SetRange(PageNo, Page::"Vendor Card");
        PageControl.SetRange(FieldNo, Vendor.FieldNo("Subc. Location Code"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, Vendor.FieldCaption("Subc. Location Code")));
    end;

    [Test]
    procedure CheckCustCtrl_PageVendorCardLinkedToWorkCenter()
    var
        PageControl: Record "Page Control Field";
        Vendor: Record Vendor;
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Vendor Card"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::Vendor);
        PageControl.SetRange(PageNo, Page::"Vendor Card");
        PageControl.SetRange(FieldNo, Vendor.FieldNo("Subc. Linked to Work Center"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, Vendor.FieldCaption("Subc. Linked to Work Center")));
    end;

    [Test]
    procedure CheckCustCtrl_PageSubcontractingWorksheetStandardTaskCode()
    var
        PageControl: Record "Page Control Field";
        ReqLine: Record "Requisition Line";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Subcontracting Worksheet"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Requisition Line");
        PageControl.SetRange(PageNo, Page::"Subc. Subcontracting Worksheet");
        PageControl.SetRange(FieldNo, ReqLine.FieldNo("Subc. Standard Task Code"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, ReqLine.FieldCaption("Subc. Standard Task Code")));
    end;

    [Test]
    procedure CheckCustCtrl_PageProductionBOMLinesComponentSupplyMethod()
    var
        PageControl: Record "Page Control Field";
        ProdBOMLine: Record "Production BOM Line";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Production BOM Lines"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Production BOM Line");
        PageControl.SetRange(PageNo, Page::"Production BOM Lines");
        PageControl.SetRange(FieldNo, ProdBOMLine.FieldNo("Component Supply Method"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, ProdBOMLine.FieldCaption("Component Supply Method")));
    end;

    [Test]
    procedure CheckCustCtrl_PageProductionBOMVersionLinesComponentSupplyMethod()
    var
        PageControl: Record "Page Control Field";
        ProdBOMLine: Record "Production BOM Line";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Production BOM Version Lines"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Production BOM Line");
        PageControl.SetRange(PageNo, Page::"Production BOM Version Lines");
        PageControl.SetRange(FieldNo, ProdBOMLine.FieldNo("Component Supply Method"));
        ControlExist := not PageControl.IsEmpty();
        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, ProdBOMLine.FieldCaption("Component Supply Method")));
    end;

    [Test]
    procedure CheckCustCtrl_PagePlanningComponentComponentSupplyMethod()
    var
        PageControl: Record "Page Control Field";
        PlanComp: Record "Planning Component";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Planning Components"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Planning Component");
        PageControl.SetRange(PageNo, Page::"Planning Components");
        PageControl.SetRange(FieldNo, PlanComp.FieldNo("Component Supply Method"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, PlanComp.FieldCaption("Component Supply Method")));
    end;

    [Test]
    procedure WorkCenterCardSubcontractingActionsHiddenWhenNotSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 633206] Subcontracting action group is not visible on Work Center Card when Work Center has no Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center without a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);

        // [WHEN] The Work Center Card page is opened for the Work Center
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GotoRecord(WorkCenter);

        // [THEN] Subcontractor Prices action is not enabled
        Assert.IsFalse(WorkCenterCard."Subcontractor Prices".Enabled(), SubcontractingActionsVisibleErr);
        WorkCenterCard.Close();
    end;

    [Test]
    procedure WorkCenterCardSubcontractingActionsVisibleWhenSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 633206] Subcontracting action group is visible on Work Center Card when Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [WHEN] The Work Center Card page is opened for the Work Center
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GotoRecord(WorkCenter);

        // [THEN] Subcontractor Prices action is enabled
        Assert.IsTrue(WorkCenterCard."Subcontractor Prices".Enabled(), SubcontractingActionsNotVisibleErr);
        WorkCenterCard.Close();
    end;

    [Test]
    procedure WorkCenterCardDispatchListDisabledWhenNotSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 633206] Subcontractor - Dispatch List action is disabled on Work Center Card when Work Center has no Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center without a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);

        // [WHEN] The Work Center Card page is opened for the Work Center
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GotoRecord(WorkCenter);

        // [THEN] Subcontractor - Dispatch List action is not enabled
        Assert.IsFalse(WorkCenterCard."Subcontractor - Dispatch List".Enabled(), SubcontractingActionsEnabledErr);
        WorkCenterCard.Close();
    end;

    [Test]
    procedure WorkCenterCardDispatchListEnabledWhenSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 633206] Subcontractor - Dispatch List action is enabled on Work Center Card when Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [WHEN] The Work Center Card page is opened for the Work Center
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GotoRecord(WorkCenter);

        // [THEN] Subcontractor - Dispatch List action is enabled
        Assert.IsTrue(WorkCenterCard."Subcontractor - Dispatch List".Enabled(), SubcontractingActionsNotEnabledErr);
        WorkCenterCard.Close();
    end;

    [Test]
    procedure WorkCenterListSubcontractingActionsDisabledWhenNotSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterList: TestPage "Work Center List";
    begin
        // [SCENARIO 633206] Subcontractor Prices action is disabled on Work Center List when Work Center has no Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center without a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);

        // [WHEN] The Work Center List page is opened and navigated to the Work Center
        WorkCenterList.OpenEdit();
        WorkCenterList.GotoRecord(WorkCenter);

        // [THEN] Subcontractor Prices action is not enabled
        Assert.IsFalse(WorkCenterList."Subcontractor Prices".Enabled(), SubcontractingActionsEnabledErr);
        WorkCenterList.Close();
    end;

    [Test]
    procedure WorkCenterListSubcontractingActionsEnabledWhenSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterList: TestPage "Work Center List";
    begin
        // [SCENARIO 633206] Subcontractor Prices action is enabled on Work Center List when Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [WHEN] The Work Center List page is opened and navigated to the Work Center
        WorkCenterList.OpenEdit();
        WorkCenterList.GotoRecord(WorkCenter);

        // [THEN] Subcontractor Prices action is enabled
        Assert.IsTrue(WorkCenterList."Subcontractor Prices".Enabled(), SubcontractingActionsNotEnabledErr);
        WorkCenterList.Close();
    end;

    [Test]
    [HandlerFunctions('HandlePostedPurchaseReceiptPage')]
    procedure CapLedgerEntriesShowDocumentOpensPostedReceipt()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 620656] Show Document action opens Posted Purchase Receipt when Document No. matches a receipt
        Initialize();

        // [GIVEN] A Posted Purchase Receipt
        PurchRcptHeader.Init();
        PurchRcptHeader."No." := 'TEST-RCPT-001';
        if not PurchRcptHeader.Insert() then
            PurchRcptHeader.Modify();

        // [GIVEN] A Capacity Ledger Entry with Document No. pointing to the receipt
        CapacityLedgerEntry.Init();
        CapacityLedgerEntry."Entry No." := GetNextCapLedgerEntryNo();
        CapacityLedgerEntry."Document No." := PurchRcptHeader."No.";
        CapacityLedgerEntry.Insert();

        // [WHEN] The Show Document action is invoked
        CapacityLedgerEntries.OpenView();
        CapacityLedgerEntries.GoToRecord(CapacityLedgerEntry);
        CapacityLedgerEntries.ShowDocument.Invoke();

        // [THEN] The Posted Purchase Receipt page is opened (verified by PageHandler)
        CapacityLedgerEntries.Close();
    end;

    [Test]
    [HandlerFunctions('HandlePostedPurchaseInvoicePage')]
    procedure CapLedgerEntriesShowDocumentOpensPostedInvoice()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 620656] Show Document action opens Posted Purchase Invoice when Document No. matches an invoice
        Initialize();

        // [GIVEN] A Posted Purchase Invoice (no matching receipt)
        PurchInvHeader.Init();
        PurchInvHeader."No." := 'TEST-INV-001';
        if not PurchInvHeader.Insert() then
            PurchInvHeader.Modify();

        // [GIVEN] A Capacity Ledger Entry with Document No. pointing to the invoice
        CapacityLedgerEntry.Init();
        CapacityLedgerEntry."Entry No." := GetNextCapLedgerEntryNo();
        CapacityLedgerEntry."Document No." := PurchInvHeader."No.";
        CapacityLedgerEntry.Insert();

        // [WHEN] The Show Document action is invoked
        CapacityLedgerEntries.OpenView();
        CapacityLedgerEntries.GoToRecord(CapacityLedgerEntry);
        CapacityLedgerEntries.ShowDocument.Invoke();

        // [THEN] The Posted Purchase Invoice page is opened (verified by PageHandler)
        CapacityLedgerEntries.Close();

        // Cleanup
        CapacityLedgerEntry.Delete();
        PurchInvHeader.Delete();
    end;

    [Test]
    [HandlerFunctions('HandlePurchaseOrderPage')]
    procedure CapLedgerEntriesShowDocumentOpensPurchaseOrder()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 620656] Show Document action opens Purchase Order when no posted document exists
        Initialize();

        // [GIVEN] A Purchase Order
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := 'TEST-PO-001';
        if not PurchaseHeader.Insert() then
            PurchaseHeader.Modify();

        // [GIVEN] A Capacity Ledger Entry with Subc. Purch. Order No. but no matching posted document
        CapacityLedgerEntry.Init();
        CapacityLedgerEntry."Entry No." := GetNextCapLedgerEntryNo();
        CapacityLedgerEntry."Document No." := '';
        CapacityLedgerEntry."Subc. Purch. Order No." := PurchaseHeader."No.";
        CapacityLedgerEntry.Insert();

        // [WHEN] The Show Document action is invoked
        CapacityLedgerEntries.OpenView();
        CapacityLedgerEntries.GoToRecord(CapacityLedgerEntry);
        CapacityLedgerEntries.ShowDocument.Invoke();

        // [THEN] The Purchase Order page is opened (verified by PageHandler)
        CapacityLedgerEntries.Close();

        // Cleanup
        CapacityLedgerEntry.Delete();
        PurchaseHeader.Delete();
    end;

    [Test]
    procedure CheckCustCtrl_PageRoutingVersionLinesTransferWIPItem()
    var
        PageControl: Record "Page Control Field";
        RoutingLine: Record "Routing Line";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO 638530] Check if Transfer WIP Item control exists on Page "Routing Version Lines"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Routing Line");
        PageControl.SetRange(PageNo, Page::"Routing Version Lines");
        PageControl.SetRange(FieldNo, RoutingLine.FieldNo("Transfer WIP Item"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, RoutingLine.FieldCaption("Transfer WIP Item")));
    end;

    [Test]
    procedure CheckCustCtrl_PageRoutingVersionLinesTransferDescription()
    var
        PageControl: Record "Page Control Field";
        RoutingLine: Record "Routing Line";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO 638530] Check if Transfer Description control exists on Page "Routing Version Lines"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Routing Line");
        PageControl.SetRange(PageNo, Page::"Routing Version Lines");
        PageControl.SetRange(FieldNo, RoutingLine.FieldNo("Transfer Description"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, RoutingLine.FieldCaption("Transfer Description")));
    end;

    local procedure GetNextCapLedgerEntryNo(): Integer
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        if CapacityLedgerEntry.FindLast() then
            exit(CapacityLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    [PageHandler]
    procedure HandlePostedPurchaseReceiptPage(var PostedPurchaseReceipt: TestPage "Posted Purchase Receipt")
    begin
        PostedPurchaseReceipt.Close();
    end;

    [PageHandler]
    procedure HandlePostedPurchaseInvoicePage(var PostedPurchaseInvoice: TestPage "Posted Purchase Invoice")
    begin
        PostedPurchaseInvoice.Close();
    end;

    [PageHandler]
    procedure HandlePurchaseOrderPage(var PurchaseOrder: TestPage "Purchase Order")
    begin
        PurchaseOrder.Close();
    end;

    [Test]
    procedure ItemLedgerEntriesSubcActionsDisabledWhenNotSubcontracting()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 638458] Subcontracting actions on Item Ledger Entries are disabled when the entry has no subcontracting production order or purchase order.
        Initialize();

        // [GIVEN] An Item Ledger Entry that is NOT related to subcontracting (no production order or Subc. Purch. Order No.)
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := GetNextItemLedgerEntryNo();
        ItemLedgerEntry."Item No." := 'TEST-ITEM';
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Purchase;
        ItemLedgerEntry."Order No." := '';
        ItemLedgerEntry."Subc. Purch. Order No." := '';
        ItemLedgerEntry.Insert();

        // [WHEN] The Item Ledger Entries page is opened for that entry
        ItemLedgerEntries.OpenView();
        ItemLedgerEntries.GoToRecord(ItemLedgerEntry);

        // [THEN] The Production Order action is disabled
        Assert.IsFalse(ItemLedgerEntries."Production Order".Enabled(), ILEProdActionsEnabledErr);
        // [THEN] The Production Order Routing action is disabled
        Assert.IsFalse(ItemLedgerEntries."Production Order Routing".Enabled(), ILEProdActionsEnabledErr);
        // [THEN] The Production Order Components action is disabled
        Assert.IsFalse(ItemLedgerEntries."Production Order Components".Enabled(), ILEProdActionsEnabledErr);
        // [THEN] The Purchase Order action is disabled
        Assert.IsFalse(ItemLedgerEntries."Purchase Order".Enabled(), ILEPurchActionsEnabledErr);

        ItemLedgerEntries.Close();

        // Cleanup
        ItemLedgerEntry.Delete();
    end;

    [Test]
    procedure ItemLedgerEntriesSubcActionsEnabledWhenSubcontracting()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 638458] Subcontracting actions on Item Ledger Entries are enabled when the entry is related to a subcontracting production order and purchase order.
        Initialize();

        // [GIVEN] An Item Ledger Entry that IS related to subcontracting
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := GetNextItemLedgerEntryNo();
        ItemLedgerEntry."Item No." := 'TEST-ITEM';
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Purchase;
        ItemLedgerEntry."Order Type" := ItemLedgerEntry."Order Type"::Production;
        ItemLedgerEntry."Order No." := 'PO-SUBC-001';
        ItemLedgerEntry."Order Line No." := 10000;
        ItemLedgerEntry."Subc. Purch. Order No." := 'PURCH-SUBC-001';
        ItemLedgerEntry."Subc. Purch. Order Line No." := 10000;
        ItemLedgerEntry.Insert();

        // [WHEN] The Item Ledger Entries page is opened for that entry
        ItemLedgerEntries.OpenView();
        ItemLedgerEntries.GoToRecord(ItemLedgerEntry);

        // [THEN] The Production Order action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order".Enabled(), ILEProdActionsNotEnabledErr);
        // [THEN] The Production Order Routing action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order Routing".Enabled(), ILEProdActionsNotEnabledErr);
        // [THEN] The Production Order Components action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order Components".Enabled(), ILEProdActionsNotEnabledErr);
        // [THEN] The Purchase Order action is enabled
        Assert.IsTrue(ItemLedgerEntries."Purchase Order".Enabled(), ILEPurchActionsNotEnabledErr);

        ItemLedgerEntries.Close();

        // Cleanup
        ItemLedgerEntry.Delete();
    end;

    [Test]
    procedure RoutingLinesTransferWIPItemDisabledForMachineCenterLine()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLines: TestPage "Routing Lines";
        MachineCenterNo: Code[20];
    begin
        // [SCENARIO] Transfer WIP Item field is disabled on Routing Lines page for a Machine Center routing line,
        // even when the parent Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [GIVEN] A Machine Center belonging to that Work Center
        LibraryMfgManagement.CreateMachineCenter(MachineCenterNo, WorkCenter."No.", 0);

        // [GIVEN] A Routing with a Machine Center routing line
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryMfgManagement.CreateRoutingLineForMachineCenter(RoutingLine, RoutingHeader, MachineCenterNo);

        // [WHEN] The Routing Lines page is opened for that line
        RoutingLines.OpenEdit();
        RoutingLines.GoToRecord(RoutingLine);

        // [THEN] Transfer WIP Item is not enabled (Machine Center type is not eligible for Transfer WIP Item)
        Assert.IsFalse(RoutingLines."Transfer WIP Item".Enabled(), RoutingLineTransferWIPEnabledErr);
        RoutingLines.Close();
    end;

    [Test]
    procedure RoutingLinesTransferWIPItemEnabledForSubcontractingWorkCenterLine()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLines: TestPage "Routing Lines";
    begin
        // [SCENARIO] Transfer WIP Item field is enabled on Routing Lines page for a Work Center routing line
        // when the Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [GIVEN] A Routing with a Work Center routing line
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryMfgManagement.CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");

        // [WHEN] The Routing Lines page is opened for that line
        RoutingLines.OpenEdit();
        RoutingLines.GoToRecord(RoutingLine);

        // [THEN] Transfer WIP Item is enabled (subcontracting Work Center type)
        Assert.IsTrue(RoutingLines."Transfer WIP Item".Enabled(), RoutingLineTransferWIPNotEnabledErr);
        RoutingLines.Close();
    end;

    [Test]
    procedure RoutingVersionLinesTransferWIPItemDisabledForMachineCenterLine()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersionLines: TestPage "Routing Version Lines";
        MachineCenterNo: Code[20];
        VersionCode: Code[20];
    begin
        // [SCENARIO] Transfer WIP Item field is disabled on Routing Version Lines page for a Machine Center
        // routing line, even when the parent Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [GIVEN] A Machine Center belonging to that Work Center
        LibraryMfgManagement.CreateMachineCenter(MachineCenterNo, WorkCenter."No.", 0);

        // [GIVEN] A Routing Version with a Machine Center routing line
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        VersionCode := '1';
        CreateRoutingVersionAndMachineCenterLine(RoutingHeader."No.", VersionCode, MachineCenterNo, RoutingLine);

        // [WHEN] The Routing Version Lines page is opened for that line
        RoutingVersionLines.OpenEdit();
        RoutingVersionLines.Filter.SetFilter("Routing No.", RoutingHeader."No.");
        RoutingVersionLines.Filter.SetFilter("Version Code", VersionCode);
        RoutingVersionLines.GoToRecord(RoutingLine);

        // [THEN] Transfer WIP Item is not enabled (Machine Center type is not eligible for Transfer WIP Item)
        Assert.IsFalse(RoutingVersionLines."Transfer WIP Item".Enabled(), RoutingLineTransferWIPEnabledErr);
        RoutingVersionLines.Close();
    end;

    [Test]
    procedure RoutingVersionLinesTransferWIPItemEnabledForSubcontractingWorkCenterLine()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersionLines: TestPage "Routing Version Lines";
        VersionCode: Code[20];
    begin
        // [SCENARIO] Transfer WIP Item field is enabled on Routing Version Lines page for a Work Center routing line
        // when the Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [GIVEN] A Routing Version with a Work Center routing line
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        VersionCode := '1';
        CreateRoutingVersionAndWorkCenterLine(RoutingHeader."No.", VersionCode, WorkCenter."No.", RoutingLine);

        // [WHEN] The Routing Version Lines page is opened for that line
        RoutingVersionLines.OpenEdit();
        RoutingVersionLines.Filter.SetFilter("Routing No.", RoutingHeader."No.");
        RoutingVersionLines.Filter.SetFilter("Version Code", VersionCode);
        RoutingVersionLines.GoToRecord(RoutingLine);

        // [THEN] Transfer WIP Item is enabled (subcontracting Work Center type)
        Assert.IsTrue(RoutingVersionLines."Transfer WIP Item".Enabled(), RoutingLineTransferWIPNotEnabledErr);
        RoutingVersionLines.Close();
    end;

    [Test]
    procedure RoutingLineTransferWIPItemValidationFailsForMachineCenterType()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        MachineCenterNo: Code[20];
    begin
        // [SCENARIO] Validating Transfer WIP Item = true on a Machine Center routing line fails
        // with an error because the Type must be Work Center.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [GIVEN] A Machine Center belonging to that Work Center
        LibraryMfgManagement.CreateMachineCenter(MachineCenterNo, WorkCenter."No.", 0);

        // [GIVEN] A Routing with a Machine Center routing line
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryMfgManagement.CreateRoutingLineForMachineCenter(RoutingLine, RoutingHeader, MachineCenterNo);

        // [WHEN] Transfer WIP Item is set to true on the Machine Center routing line
        // [THEN] An error is raised because the line type must be Work Center
        asserterror RoutingLine.Validate("Transfer WIP Item", true);
        Assert.ExpectedTestFieldError(RoutingLine.FieldCaption(Type), Format(RoutingLine.Type::"Work Center"));
    end;

    local procedure CreateRoutingVersionAndWorkCenterLine(RoutingNo: Code[20]; VersionCode: Code[20]; WorkCenterNo: Code[20]; var RoutingLine: Record "Routing Line")
    var
        RoutingVersion: Record "Routing Version";
        CapacityUoM: Record "Capacity Unit of Measure";
    begin
        RoutingVersion.Init();
        RoutingVersion.Validate("Routing No.", RoutingNo);
        RoutingVersion."Version Code" := VersionCode;
        RoutingVersion.Insert(true);

#pragma warning disable AA0210
        CapacityUoM.SetRange(Type, CapacityUoM.Type::Minutes);
#pragma warning restore AA0210
        CapacityUoM.FindFirst();

        RoutingLine.Init();
        RoutingLine.Validate("Routing No.", RoutingNo);
        RoutingLine.Validate("Version Code", VersionCode);
        RoutingLine.Validate("Operation No.", '10');
        RoutingLine.Validate(Type, RoutingLine.Type::"Work Center");
        RoutingLine.Validate("No.", WorkCenterNo);
        RoutingLine.Validate("Setup Time", 1);
        RoutingLine.Validate("Run Time", 1);
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUoM.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUoM.Code);
        RoutingLine.Insert(true);
    end;

    local procedure CreateRoutingVersionAndMachineCenterLine(RoutingNo: Code[20]; VersionCode: Code[20]; MachineCenterNo: Code[20]; var RoutingLine: Record "Routing Line")
    var
        RoutingVersion: Record "Routing Version";
        CapacityUoM: Record "Capacity Unit of Measure";
    begin
        RoutingVersion.Init();
        RoutingVersion.Validate("Routing No.", RoutingNo);
        RoutingVersion."Version Code" := VersionCode;
        RoutingVersion.Insert(true);

#pragma warning disable AA0210
        CapacityUoM.SetRange(Type, CapacityUoM.Type::Minutes);
#pragma warning restore AA0210
        CapacityUoM.FindFirst();

        RoutingLine.Init();
        RoutingLine.Validate("Routing No.", RoutingNo);
        RoutingLine.Validate("Version Code", VersionCode);
        RoutingLine.Validate("Operation No.", '10');
        RoutingLine.Validate(Type, RoutingLine.Type::"Machine Center");
        RoutingLine.Validate("No.", MachineCenterNo);
        RoutingLine.Validate("Setup Time", 1);
        RoutingLine.Validate("Run Time", 1);
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUoM.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUoM.Code);
        RoutingLine.Insert(true);
    end;

    [Test]
    procedure ItemLedgerEntriesSubcProdActionsEnabledForTransferViaSubcProdOrder()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 641405] Subcontracting production actions on Item Ledger Entries are enabled for a Transfer-type entry
        // [SCENARIO 641405] whose production order is referenced only through the Subc. Prod. Order fields (the base Order No. holds the transfer order).
        Initialize();

        // [GIVEN] A Transfer-type Item Ledger Entry whose base Order fields point at a transfer order,
        //         while the production order is only referenced through the Subc. Prod. Order fields
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := GetNextItemLedgerEntryNo();
        ItemLedgerEntry."Item No." := 'TEST-ITEM';
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Transfer;
        ItemLedgerEntry."Order Type" := ItemLedgerEntry."Order Type"::Transfer;
        ItemLedgerEntry."Order No." := 'TRANSFER-001';
        ItemLedgerEntry."Order Line No." := 10000;
        ItemLedgerEntry."Subc. Prod. Order No." := 'PO-SUBC-001';
        ItemLedgerEntry."Subc. Prod. Order Line No." := 10000;
        ItemLedgerEntry.Insert();

        // [WHEN] The Item Ledger Entries page is opened for that entry
        ItemLedgerEntries.OpenView();
        ItemLedgerEntries.GoToRecord(ItemLedgerEntry);

        // [THEN] The Production Order action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order".Enabled(), ILEProdActionsNotEnabledErr);
        // [THEN] The Production Order Routing action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order Routing".Enabled(), ILEProdActionsNotEnabledErr);
        // [THEN] The Production Order Components action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order Components".Enabled(), ILEProdActionsNotEnabledErr);

        ItemLedgerEntries.Close();

        // Cleanup
        ItemLedgerEntry.Delete();
    end;

    local procedure GetNextItemLedgerEntryNo(): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if ItemLedgerEntry.FindLast() then
            exit(ItemLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        ControlNotExistMsg: Label 'Control %1 does not exist.', Comment = '%1 = field caption';
        SubcontractingActionsVisibleErr: Label 'Subcontractor Prices action should not be visible for a non-subcontracting Work Center.';
        SubcontractingActionsEnabledErr: Label 'Subcontractor Prices action should not be enabled for a non-subcontracting Work Center.';
        SubcontractingActionsNotVisibleErr: Label 'Subcontractor Prices action should be visible for a subcontracting Work Center.';
        SubcontractingActionsNotEnabledErr: Label 'Subcontractor Prices action should be enabled for a subcontracting Work Center.';
        ILEProdActionsEnabledErr: Label 'Production actions should not be enabled for a non-subcontracting Item Ledger Entry.';
        ILEProdActionsNotEnabledErr: Label 'Production actions should be enabled for a subcontracting Item Ledger Entry.';
        ILEPurchActionsEnabledErr: Label 'Purchase Order action should not be enabled for a non-subcontracting Item Ledger Entry.';
        ILEPurchActionsNotEnabledErr: Label 'Purchase Order action should be enabled for a subcontracting Item Ledger Entry.';
        RoutingLineTransferWIPEnabledErr: Label 'Transfer WIP Item should not be enabled for a Machine Center routing line.';
        RoutingLineTransferWIPNotEnabledErr: Label 'Transfer WIP Item should be enabled for a subcontracting Work Center routing line.';
}