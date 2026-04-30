// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
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
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Hide);
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
        PageControl.SetRange(FieldNo, PurchHeader.FieldNo("Subcontracting Order"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, PurchHeader.FieldCaption("Subcontracting Order")));
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
        PageControl.SetRange(FieldNo, Vendor.FieldNo("Subcontr. Location Code"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, Vendor.FieldCaption("Subcontr. Location Code")));
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
        PageControl.SetRange(FieldNo, Vendor.FieldNo("Linked to Work Center"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, Vendor.FieldCaption("Linked to Work Center")));
    end;

    [Test]
    procedure CheckCustCtrl_PageSubcontractingWorksheetBaseUMQtyPLUMQty()
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
        PageControl.SetRange(FieldNo, ReqLine.FieldNo("Base UM Qty/PL UM Qty"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, ReqLine.FieldCaption("Base UM Qty/PL UM Qty")));
    end;

    [Test]
    procedure CheckCustCtrl_PageSubcontractingWorksheetPLUMQtyBaseUMQty()
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
        PageControl.SetRange(FieldNo, ReqLine.FieldNo("PL UM Qty/Base UM Qty"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, ReqLine.FieldCaption("PL UM Qty/Base UM Qty")));
    end;

    [Test]
    procedure CheckCustCtrl_PageSubcontractingWorksheetPriceListCost()
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
        PageControl.SetRange(FieldNo, ReqLine.FieldNo("Pricelist Cost"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, ReqLine.FieldCaption("Pricelist Cost")));
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
        PageControl.SetRange(FieldNo, ReqLine.FieldNo("Standard Task Code"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, ReqLine.FieldCaption("Standard Task Code")));
    end;

    [Test]
    procedure CheckCustCtrl_PageSubcontractingWorksheetUoMForPriceList()
    var
        PageControl: Record "Page Control Field";
        ReqLine: Record "Requisition Line";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Subc. Subcontracting Worksheet"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Requisition Line");
        PageControl.SetRange(PageNo, Page::"Subc. Subcontracting Worksheet");
        PageControl.SetRange(FieldNo, ReqLine.FieldNo("UoM for Pricelist"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, ReqLine.FieldCaption("UoM for Pricelist")));
    end;

    [Test]
    procedure CheckCustCtrl_PageProductionBOMLinesSubcontractingType()
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
        PageControl.SetRange(FieldNo, ProdBOMLine.FieldNo("Subcontracting Type"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, ProdBOMLine.FieldCaption("Subcontracting Type")));
    end;

    [Test]
    procedure CheckCustCtrl_PageProductionBOMVersionLinesSubcontractingType()
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
        PageControl.SetRange(FieldNo, ProdBOMLine.FieldNo("Subcontracting Type"));
        ControlExist := not PageControl.IsEmpty();
        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, ProdBOMLine.FieldCaption("Subcontracting Type")));
    end;

    [Test]
    procedure CheckCustCtrl_PagePlanningComponentSubcontractingType()
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
        PageControl.SetRange(FieldNo, PlanComp.FieldNo("Subcontracting Type"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, PlanComp.FieldCaption("Subcontracting Type")));
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

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        ControlNotExistMsg: Label 'Control %1 does not exist.', Comment = '%1 = field caption';
        SubcontractingActionsVisibleErr: Label 'Subcontractor Prices action should not be visible for a non-subcontracting Work Center.';
        SubcontractingActionsEnabledErr: Label 'Subcontractor Prices action should not be enabled for a non-subcontracting Work Center.';
        SubcontractingActionsNotVisibleErr: Label 'Subcontractor Prices action should be visible for a subcontracting Work Center.';
        SubcontractingActionsNotEnabledErr: Label 'Subcontractor Prices action should be enabled for a subcontracting Work Center.';
}
