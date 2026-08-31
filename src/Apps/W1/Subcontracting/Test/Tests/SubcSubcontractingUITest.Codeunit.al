// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using System.Environment.Configuration;
using System.Reflection;
using System.TestLibraries.Environment.Configuration;
using System.TestLibraries.Utilities;

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
        LibraryVariableStorage.Clear();
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
    procedure SubcontractingAssistedSetupIsRegistered()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        // [SCENARIO 642233] The Subcontracting assisted setup is registered with Guided Experience.
        Initialize();

        // [GIVEN] The Subcontracting assisted setup registration does not exist
        AssistedSetupTestLibrary.Delete(Page::"Subcontracting Setup Wizard");

        // [WHEN] Assisted setups are registered
        AssistedSetupTestLibrary.CallOnRegister();

        // [THEN] The Subcontracting setup wizard is registered
        Assert.IsTrue(AssistedSetupTestLibrary.Exists(Page::"Subcontracting Setup Wizard"), 'The Subcontracting assisted setup should be registered.');
    end;

    [Test]
    [HandlerFunctions('SetupNotCompletedConfirmHandler')]
    procedure SubcontractingSetupWizardShowsCompanyDefaultsAndConfigurationLinks()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        SubcCompTransferLeadTime: DateFormula;
        SubcontractingSetupWizard: TestPage "Subcontracting Setup Wizard";
        ComponentDirectUnitCost: Option Standard,"Prod. Order Component";
        CreateProdOrderInfoLine: Boolean;
        SubcDefaultCompLocation: Enum "Components at Location";
        SubcontractingBatchName: Code[10];
        SubcontractingTemplateName: Code[10];
    begin
        // [SCENARIO 642233] The setup wizard displays the installed company defaults and the next configuration links.
        Initialize();

        // [GIVEN] The company has Subcontracting defaults
        ManufacturingSetup.Get();
        SubcontractingTemplateName := ManufacturingSetup."Subcontracting Template Name";
        SubcontractingBatchName := ManufacturingSetup."Subcontracting Batch Name";
        CreateProdOrderInfoLine := ManufacturingSetup."Create Prod. Order Info Line";
        ComponentDirectUnitCost := ManufacturingSetup."Component Direct Unit Cost";
        SubcCompTransferLeadTime := ManufacturingSetup."Subc. Comp. Transfer Lead Time";
        SubcDefaultCompLocation := ManufacturingSetup."Subc. Default Comp. Location";

        // [WHEN] The setup wizard is opened
        SubcontractingSetupWizard.OpenEdit();

        // [THEN] The welcome step is shown
        Assert.IsFalse(SubcontractingSetupWizard.ActionBack.Enabled(), 'Back should be disabled on the welcome step.');
        Assert.IsTrue(SubcontractingSetupWizard.ActionNext.Enabled(), 'Next should be enabled on the welcome step.');
        Assert.IsFalse(SubcontractingSetupWizard.ActionFinish.Enabled(), 'Finish should be disabled on the welcome step.');

        // [WHEN] The user continues to company defaults
        SubcontractingSetupWizard.ActionNext.Invoke();

        // [THEN] The defaults created during installation are displayed
        SubcontractingSetupWizard."Subcontracting Template Name".AssertEquals(SubcontractingTemplateName);
        SubcontractingSetupWizard."Subcontracting Batch Name".AssertEquals(SubcontractingBatchName);
        SubcontractingSetupWizard."Create Prod. Order Info Line".AssertEquals(CreateProdOrderInfoLine);
        SubcontractingSetupWizard."Component Direct Unit Cost".AssertEquals(ComponentDirectUnitCost);
        SubcontractingSetupWizard."Subc. Comp. Transfer Lead Time".AssertEquals(SubcCompTransferLeadTime);
        SubcontractingSetupWizard."Subc. Default Comp. Location".AssertEquals(SubcDefaultCompLocation);
        Assert.IsTrue(SubcontractingSetupWizard.ActionBack.Enabled(), 'Back should be enabled on the company defaults step.');
        Assert.IsTrue(SubcontractingSetupWizard.ActionNext.Enabled(), 'Next should be enabled on the company defaults step.');

        // [WHEN] The user continues to the final step
        SubcontractingSetupWizard.ActionNext.Invoke();

        // [THEN] Links to the remaining Subcontracting configuration are displayed
        Assert.IsTrue(SubcontractingSetupWizard.WorkCentersLink.Visible(), 'The work centers link should be visible.');
        Assert.IsTrue(SubcontractingSetupWizard.VendorsLink.Visible(), 'The vendors link should be visible.');
        Assert.IsTrue(SubcontractingSetupWizard.LocationsLink.Visible(), 'The locations link should be visible.');
        Assert.IsTrue(SubcontractingSetupWizard.SubcontractorPricesLink.Visible(), 'The subcontractor prices link should be visible.');
        Assert.IsTrue(SubcontractingSetupWizard.ComponentSupplyMethodsLink.Visible(), 'The component supply methods link should be visible.');
        Assert.IsTrue(SubcontractingSetupWizard.DocumentationLink.Visible(), 'The documentation link should be visible.');
        Assert.IsFalse(SubcontractingSetupWizard.ActionNext.Enabled(), 'Next should be disabled on the final step.');
        Assert.IsTrue(SubcontractingSetupWizard.ActionFinish.Enabled(), 'Finish should be enabled on the final step.');

        // [WHEN] The user closes the guide without finishing the setup
        LibraryVariableStorage.Enqueue(SetupNotCompletedQst);
        LibraryVariableStorage.Enqueue(true);
        SubcontractingSetupWizard.Close();

        // [THEN] The expected confirmation was handled
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Opening and navigating the guide did not replace the installed defaults
        ManufacturingSetup.Get();
        Assert.AreEqual(SubcontractingTemplateName, ManufacturingSetup."Subcontracting Template Name", 'The Subcontracting template default should be preserved.');
        Assert.AreEqual(SubcontractingBatchName, ManufacturingSetup."Subcontracting Batch Name", 'The Subcontracting batch default should be preserved.');
        Assert.AreEqual(CreateProdOrderInfoLine, ManufacturingSetup."Create Prod. Order Info Line", 'The production order information line default should be preserved.');
        Assert.AreEqual(ComponentDirectUnitCost, ManufacturingSetup."Component Direct Unit Cost", 'The component direct unit cost default should be preserved.');
        Assert.AreEqual(SubcCompTransferLeadTime, ManufacturingSetup."Subc. Comp. Transfer Lead Time", 'The component transfer lead time default should be preserved.');
        Assert.AreEqual(SubcDefaultCompLocation, ManufacturingSetup."Subc. Default Comp. Location", 'The default component location source should be preserved.');
    end;

    [Test]
    procedure FinishingSubcontractingSetupWizardSavesDefaultsAndCompletesAssistedSetup()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        GuidedExperience: Codeunit "Guided Experience";
        CreateProdOrderInfoLine: Boolean;
        OriginalCreateProdOrderInfoLine: Boolean;
        SubcontractingSetupWizard: TestPage "Subcontracting Setup Wizard";
    begin
        // [SCENARIO 642233] Finishing the setup guide saves changes and marks the assisted setup as completed.
        Initialize();

        // [GIVEN] The Subcontracting assisted setup is registered and incomplete
        AssistedSetupTestLibrary.Delete(Page::"Subcontracting Setup Wizard");
        AssistedSetupTestLibrary.CallOnRegister();
        AssistedSetupTestLibrary.SetStatusToNotCompleted(Page::"Subcontracting Setup Wizard");
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Subcontracting Setup Wizard"), 'The assisted setup should initially be incomplete.');

        // [GIVEN] A changed company default in the setup wizard
        ManufacturingSetup.Get();
        OriginalCreateProdOrderInfoLine := ManufacturingSetup."Create Prod. Order Info Line";
        CreateProdOrderInfoLine := not OriginalCreateProdOrderInfoLine;
        SubcontractingSetupWizard.OpenEdit();
        SubcontractingSetupWizard.ActionNext.Invoke();
        SubcontractingSetupWizard."Create Prod. Order Info Line".SetValue(CreateProdOrderInfoLine);
        SubcontractingSetupWizard.ActionNext.Invoke();

        // [WHEN] The user finishes the setup wizard
        SubcontractingSetupWizard.ActionFinish.Invoke();

        // [THEN] The company default is saved and the assisted setup is completed
        ManufacturingSetup.Get();
        Assert.AreEqual(CreateProdOrderInfoLine, ManufacturingSetup."Create Prod. Order Info Line", 'The changed company default should be saved.');
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Subcontracting Setup Wizard"), 'The assisted setup should be completed.');

        ManufacturingSetup."Create Prod. Order Info Line" := OriginalCreateProdOrderInfoLine;
        ManufacturingSetup.Modify();
    end;

    [Test]
    procedure ManufacturingSetupContainsDefaultComponentLocationSource()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        PageControl: Record "Page Control Field";
    begin
        // [SCENARIO 642233] Manufacturing Setup remains available for maintaining all Subcontracting company defaults.
        Initialize();

        // [WHEN] Controls on Manufacturing Setup are inspected
        PageControl.SetRange(TableNo, Database::"Manufacturing Setup");
        PageControl.SetRange(PageNo, Page::"Manufacturing Setup");
        PageControl.SetRange(FieldNo, ManufacturingSetup.FieldNo("Subc. Default Comp. Location"));

        // [THEN] Default Component Location Source is available for later maintenance
        Assert.IsFalse(PageControl.IsEmpty(), StrSubstNo(ControlNotExistMsg, ManufacturingSetup.FieldCaption("Subc. Default Comp. Location")));
    end;

    [Test]
    procedure CommentPagesExposeOperationKeysAndFields()
    var
        PageAction: Record "Page Action";
        PageControl: Record "Page Control Field";
        SubcProdOrderRoutingComment: Record "Subc. Prod. Rtng. Comment";
        SubcRoutingCommentLine: Record "Subc. Routing Comment Line";
        SubcStandardTaskComment: Record "Subc. Standard Task Comment";
    begin
        // [SCENARIO TP-001] Dedicated subcontracting comment pages expose their source operation keys and editable fields.
        Initialize();

        // [WHEN] Source pages expose navigation to dedicated subcontracting comments
        AssertPageActionRunsPage(PageAction, Page::"Standard Tasks", 'Subc. Subcontracting Comments', Page::"Subc. Standard Task Comments");
        AssertPageActionRunsPage(PageAction, Page::"Routing Lines", 'Subc. Subcontracting Comments', Page::"Subc. Routing Comments");
        AssertPageActionRunsPage(PageAction, Page::"Routing Version Lines", 'Subc. Subcontracting Comments', Page::"Subc. Routing Comments");
        AssertPageActionRunsPage(PageAction, Page::"Prod. Order Routing", 'Subc. Subcontracting Comments', Page::"Subc. Prod. Rtng. Comments");

        // [WHEN] Controls on each dedicated comment page are inspected
        AssertPageControlExists(
            Database::"Subc. Standard Task Comment", Page::"Subc. Standard Task Comments",
            SubcStandardTaskComment.FieldNo("Standard Task Code"), 'Standard Task Code');
        AssertPageControlExists(
            Database::"Subc. Standard Task Comment", Page::"Subc. Standard Task Comments",
            SubcStandardTaskComment.FieldNo("Line No."), 'Line No.');
        AssertPageControlExists(
            Database::"Subc. Standard Task Comment", Page::"Subc. Standard Task Comments",
            SubcStandardTaskComment.FieldNo(Description), 'Description');
        AssertPageControlExists(
            Database::"Subc. Standard Task Comment", Page::"Subc. Standard Task Comments",
            SubcStandardTaskComment.FieldNo("Description 2"), 'Description 2');

        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Routing No."), 'Routing No.');
        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Version Code"), 'Version Code');
        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Operation No."), 'Operation No.');
        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Line No."), 'Line No.');
        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo(Description), 'Description');
        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Description 2"), 'Description 2');

        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo(Status), 'Status');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Prod. Order No."), 'Prod. Order No.');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Routing Reference No."), 'Routing Reference No.');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Routing No."), 'Routing No.');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Operation No."), 'Operation No.');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Line No."), 'Line No.');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo(Description), 'Description');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Description 2"), 'Description 2');

        // [THEN] Ordinary routing comments are not a source for the dedicated page surface
        PageControl.SetRange(TableNo, Database::"Routing Comment Line");
        PageControl.SetRange(PageNo, Page::"Subc. Routing Comments");
        Assert.IsTrue(PageControl.IsEmpty(), 'The dedicated subcontracting routing comment page must not use ordinary routing comments.');
    end;

    [Test]
    procedure SubcontractingCommentDescription2IsHiddenInitially()
    var
        SubcProdOrderRoutingComment: Record "Subc. Prod. Rtng. Comment";
        SubcRoutingCommentLine: Record "Subc. Routing Comment Line";
        SubcStandardTaskComment: Record "Subc. Standard Task Comment";
        PageControl: Record "Page Control Field";
    begin
        // [SCENARIO TP-031] Description 2 is initially hidden on each dedicated subcontracting comment page.
        Initialize();

        // [WHEN] The Description 2 control metadata is inspected on each dedicated comment page
        AssertPageControlIsInitiallyHidden(
            PageControl, Database::"Subc. Standard Task Comment", Page::"Subc. Standard Task Comments",
            SubcStandardTaskComment.FieldNo("Description 2"), SubcStandardTaskComment.FieldCaption("Description 2"));
        AssertPageControlIsInitiallyHidden(
            PageControl, Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Description 2"), SubcRoutingCommentLine.FieldCaption("Description 2"));
        AssertPageControlIsInitiallyHidden(
            PageControl, Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Description 2"), SubcProdOrderRoutingComment.FieldCaption("Description 2"));
    end;

    [Test]
    procedure SubcontractingCommentsEnabledOnlyForSubcontractingLines()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        NonSubcontractingProdOrderRoutingLine: Record "Prod. Order Routing Line";
        NonSubcontractingRoutingLine: Record "Routing Line";
        NonSubcontractingRoutingVersionLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        SubcontractingProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SubcontractingRoutingLine: Record "Routing Line";
        SubcontractingRoutingVersionLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        RoutingPage: TestPage Routing;
        RoutingVersionPage: TestPage "Routing Version";
        ProdOrderRouting: TestPage "Prod. Order Routing";
    begin
        // [SCENARIO TP-029] Dedicated subcontracting comments are enabled only for subcontracting operations.
        Initialize();

        // [GIVEN] A regular work center and a subcontracting work center
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, false);
        WorkCenter[2].Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter[2].Modify(true);

        // [GIVEN] A routing and routing version containing both work center types
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, NonSubcontractingRoutingLine, '', '10', NonSubcontractingRoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, SubcontractingRoutingLine, '', '20', SubcontractingRoutingLine.Type::"Work Center", WorkCenter[2]."No.");
        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.", 'V1');
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, NonSubcontractingRoutingVersionLine, RoutingVersion."Version Code", '10', NonSubcontractingRoutingVersionLine.Type::"Work Center", WorkCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, SubcontractingRoutingVersionLine, RoutingVersion."Version Code", '20', SubcontractingRoutingVersionLine.Type::"Work Center", WorkCenter[2]."No.");
        RoutingVersion.Validate(Status, RoutingVersion.Status::Certified);
        RoutingVersion.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // [WHEN] Routing Lines is inspected for each operation type
        RoutingPage.OpenEdit();
        RoutingPage.GotoRecord(RoutingHeader);
        RoutingPage.RoutingLine.GotoRecord(NonSubcontractingRoutingLine);

        // [THEN] Subcontracting comments are disabled for a regular routing line
        Assert.IsFalse(RoutingPage.RoutingLine."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be disabled for a regular routing line.');

        RoutingPage.RoutingLine.GotoRecord(SubcontractingRoutingLine);

        // [THEN] Subcontracting comments are enabled for a subcontracting routing line
        Assert.IsTrue(RoutingPage.RoutingLine."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be enabled for a subcontracting routing line.');
        RoutingPage.Close();

        // [WHEN] Routing Version Lines is inspected for each operation type
        RoutingVersionPage.OpenEdit();
        RoutingVersionPage.GotoRecord(RoutingVersion);
        RoutingVersionPage.RoutingLine.GotoRecord(NonSubcontractingRoutingVersionLine);

        // [THEN] Subcontracting comments are disabled for a regular routing version line
        Assert.IsFalse(RoutingVersionPage.RoutingLine."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be disabled for a regular routing version line.');

        RoutingVersionPage.RoutingLine.GotoRecord(SubcontractingRoutingVersionLine);

        // [THEN] Subcontracting comments are enabled for a subcontracting routing version line
        Assert.IsTrue(RoutingVersionPage.RoutingLine."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be enabled for a subcontracting routing version line.');
        RoutingVersionPage.Close();

        // [GIVEN] A released production order with regular and subcontracting operations
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 1);
        NonSubcontractingProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        NonSubcontractingProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        NonSubcontractingProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[1]."No.");
        NonSubcontractingProdOrderRoutingLine.FindFirst();
        SubcontractingProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        SubcontractingProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        SubcontractingProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        SubcontractingProdOrderRoutingLine.FindFirst();

        // [WHEN] Prod. Order Routing is inspected for each operation type
        ProdOrderRouting.OpenView();
        ProdOrderRouting.GotoRecord(NonSubcontractingProdOrderRoutingLine);

        // [THEN] Subcontracting comments are disabled for a regular production operation
        Assert.IsFalse(ProdOrderRouting."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be disabled for a regular production operation.');

        ProdOrderRouting.GotoRecord(SubcontractingProdOrderRoutingLine);

        // [THEN] Subcontracting comments are enabled for a subcontracting production operation
        Assert.IsTrue(ProdOrderRouting."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be enabled for a subcontracting production operation.');
        ProdOrderRouting.Close();
    end;


    [Test]
    procedure V1DoesNotExposeUnsupportedCommentOrAttachmentSetup()
    var
        PageControl: Record "Page Control Field";
        TableField: Record Field;
    begin
        // [SCENARIO TP-025] V1 comment and attachment surfaces do not expose unsupported metadata.
        Initialize();

        // [WHEN] Dedicated comment tables are inspected for unsupported translation and date metadata
        AssertTableFieldMissing(TableField, Database::"Subc. Standard Task Comment", 'Vendor No.');
        AssertTableFieldMissing(TableField, Database::"Subc. Standard Task Comment", 'Language Code');
        AssertTableFieldMissing(TableField, Database::"Subc. Standard Task Comment", 'Starting Date');
        AssertTableFieldMissing(TableField, Database::"Subc. Standard Task Comment", 'Ending Date');
        AssertTableFieldMissing(TableField, Database::"Subc. Routing Comment Line", 'Vendor No.');
        AssertTableFieldMissing(TableField, Database::"Subc. Routing Comment Line", 'Language Code');
        AssertTableFieldMissing(TableField, Database::"Subc. Routing Comment Line", 'Starting Date');
        AssertTableFieldMissing(TableField, Database::"Subc. Routing Comment Line", 'Ending Date');
        AssertTableFieldMissing(TableField, Database::"Subc. Prod. Rtng. Comment", 'Vendor No.');
        AssertTableFieldMissing(TableField, Database::"Subc. Prod. Rtng. Comment", 'Language Code');
        AssertTableFieldMissing(TableField, Database::"Subc. Prod. Rtng. Comment", 'Starting Date');
        AssertTableFieldMissing(TableField, Database::"Subc. Prod. Rtng. Comment", 'Ending Date');

        // [THEN] Routing Lines do not expose operation-specific attachment selection
        AssertTableFieldMissing(TableField, Database::"Routing Line", 'Document Flow Production');
        AssertTableFieldMissing(TableField, Database::"Routing Line", 'Document Flow Purchase');
        AssertPageControlMissing(PageControl, Database::"Routing Line", Page::"Routing Lines", 'Document Flow Production');
        AssertPageControlMissing(PageControl, Database::"Routing Line", Page::"Routing Lines", 'Document Flow Purchase');
        AssertPageControlMissing(PageControl, Database::"Routing Line", Page::"Routing Version Lines", 'Document Flow Production');
        AssertPageControlMissing(PageControl, Database::"Routing Line", Page::"Routing Version Lines", 'Document Flow Purchase');
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
        Assert.IsFalse(WorkCenterCard."Subcontractor Dispatch List".Enabled(), SubcontractingActionsEnabledErr);
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
        Assert.IsTrue(WorkCenterCard."Subcontractor Dispatch List".Enabled(), SubcontractingActionsNotEnabledErr);
        WorkCenterCard.Close();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationNotificationHandler,SubcontractorLocationRecallHandler')]
    procedure WorkCenterCardNotifiesWhenSubcontractorHasNoLocation()
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 642229] A notification identifies a subcontractor vendor that has no subcontracting location.
        Initialize();

        // [GIVEN] A Work Center and a vendor without a Subcontracting Location Code
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        Vendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));

        // [WHEN] The vendor is selected as the subcontractor on the Work Center Card
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);
        WorkCenterCard."Subcontractor No.".SetValue(Vendor."No.");

        // [THEN] Any previous notification is recalled before one notification is sent for that vendor
        VerifySubcontractorLocationNotification(Vendor."No.");
        WorkCenterCard.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationNotificationHandler,SubcontractorLocationRecallHandler')]
    procedure WorkCenterCardDoesNotStackSubcontractorLocationNotifications()
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 642229] Revalidating an unconfigured subcontractor replaces the existing notification.
        Initialize();

        // [GIVEN] A Work Center Card showing a notification for a vendor without a subcontracting location
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        Vendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);
        WorkCenterCard."Subcontractor No.".SetValue(Vendor."No.");
        VerifySubcontractorLocationNotification(Vendor."No.");

        // [WHEN] The same vendor is validated again
        WorkCenterCard."Subcontractor No.".SetValue(Vendor."No.");

        // [THEN] The previous notification is recalled before its replacement is sent with the same notification ID
        VerifySubcontractorLocationNotification(Vendor."No.");
        WorkCenterCard.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationNotificationHandler,SubcontractorLocationRecallHandler')]
    procedure WorkCenterCardRecallsSubcontractorLocationNotificationWhenNoLongerNeeded()
    var
        Location: Record Location;
        ConfiguredVendor: Record Vendor;
        UnconfiguredVendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 642229] A previous notification is removed when the subcontractor is configured or cleared.
        Initialize();

        // [GIVEN] An unconfigured vendor, a configured vendor, and a Work Center Card showing the notification
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        UnconfiguredVendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        ConfiguredVendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ConfiguredVendor.Validate("Subc. Location Code", Location.Code);
        ConfiguredVendor.Modify(true);
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);
        WorkCenterCard."Subcontractor No.".SetValue(UnconfiguredVendor."No.");
        VerifySubcontractorLocationNotification(UnconfiguredVendor."No.");

        // [WHEN] The configured vendor is selected
        WorkCenterCard."Subcontractor No.".SetValue(ConfiguredVendor."No.");

        // [THEN] The previous notification is recalled and no notification is sent for the configured vendor
        VerifySubcontractorLocationNotification('');

        // [WHEN] The unconfigured vendor is selected again
        WorkCenterCard."Subcontractor No.".SetValue(UnconfiguredVendor."No.");

        // [THEN] The previous notification is recalled before a new notification is sent
        VerifySubcontractorLocationNotification(UnconfiguredVendor."No.");

        // [WHEN] The subcontractor is cleared
        WorkCenterCard."Subcontractor No.".SetValue('');

        // [THEN] The notification is recalled without sending another one
        VerifySubcontractorLocationNotification('');
        WorkCenterCard.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationNotificationActionHandler,SubcontractorLocationRecallHandler,VendorCardHandler')]
    procedure WorkCenterCardSubcontractorLocationNotificationActionOpensVendorCard()
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 642229] The notification action opens the selected subcontractor vendor.
        Initialize();

        // [GIVEN] A Work Center and a vendor without a Subcontracting Location Code
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        Vendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));

        // [WHEN] The vendor is selected as the subcontractor and the notification action is invoked
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);
        WorkCenterCard."Subcontractor No.".SetValue(Vendor."No.");

        // [THEN] The notification is sent for the vendor and the Vendor Card opens for that vendor
        VerifySubcontractorLocationNotification(Vendor."No.");
        Assert.AreEqual(Vendor."No.", LibraryVariableStorage.DequeueText(), VendorCardNoErr);
        WorkCenterCard.Close();
        LibraryVariableStorage.AssertEmpty();
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

    local procedure AssertPageControlExists(ControlTableNo: Integer; ControlPageNo: Integer; ControlFieldNo: Integer; ControlNameValue: Text)
    var
        PageControl: Record "Page Control Field";
    begin
        PageControl.SetRange(TableNo, ControlTableNo);
        PageControl.SetRange(PageNo, ControlPageNo);
        PageControl.SetRange(FieldNo, ControlFieldNo);
        PageControl.SetRange(ControlName, ControlNameValue);
        Assert.IsFalse(PageControl.IsEmpty(), StrSubstNo(ControlNotExistMsg, ControlNameValue));
    end;

    local procedure AssertPageControlIsInitiallyHidden(var PageControl: Record "Page Control Field"; ControlTableNo: Integer; ControlPageNo: Integer; ControlFieldNo: Integer; ControlFieldCaption: Text)
    begin
        PageControl.Reset();
        PageControl.SetRange(TableNo, ControlTableNo);
        PageControl.SetRange(PageNo, ControlPageNo);
        PageControl.SetRange(FieldNo, ControlFieldNo);
        Assert.IsFalse(PageControl.IsEmpty(), StrSubstNo(ControlNotExistMsg, ControlFieldCaption));
        PageControl.FindFirst();
        Assert.AreEqual('false', LowerCase(PageControl.Visible), StrSubstNo(ControlShouldBeHiddenErr, ControlFieldCaption, ControlPageNo));
    end;

    local procedure AssertPageActionRunsPage(var PageAction: Record "Page Action"; SourcePageNo: Integer; ActionName: Text; TargetPageNo: Integer)
    begin
        PageAction.Reset();
        PageAction.SetRange("Page ID", SourcePageNo);
        PageAction.SetRange(Name, ActionName);
        Assert.IsFalse(PageAction.IsEmpty(), StrSubstNo(ActionNotExistMsg, ActionName, SourcePageNo));
        PageAction.FindFirst();
        Assert.AreEqual(TargetPageNo, PageAction.RunObjectID, StrSubstNo(ActionTargetUnexpectedMsg, ActionName, TargetPageNo));
    end;

    local procedure AssertPageControlMissing(var PageControl: Record "Page Control Field"; ControlTableNo: Integer; ControlPageNo: Integer; ControlNameValue: Text)
    begin
        PageControl.Reset();
        PageControl.SetRange(TableNo, ControlTableNo);
        PageControl.SetRange(PageNo, ControlPageNo);
        PageControl.SetRange(ControlName, ControlNameValue);
        Assert.IsTrue(PageControl.IsEmpty(), StrSubstNo(UnsupportedControlExistsMsg, ControlNameValue, ControlPageNo));
    end;

    local procedure AssertTableFieldMissing(var TableField: Record Field; TableNumber: Integer; FieldNameValue: Text)
    begin
        TableField.Reset();
        TableField.SetRange(TableNo, TableNumber);
        TableField.SetRange(FieldName, FieldNameValue);
        Assert.IsTrue(TableField.IsEmpty(), StrSubstNo(UnsupportedFieldExistsMsg, FieldNameValue, TableNumber));
    end;

    local procedure GetNextCapLedgerEntryNo(): Integer
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        if CapacityLedgerEntry.FindLast() then
            exit(CapacityLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure VerifySubcontractorLocationNotification(VendorNo: Code[20])
    begin
        Assert.AreEqual(RecallNotificationTok, LibraryVariableStorage.DequeueText(), NotificationOrderErr);
        Assert.AreEqual(Format(GetMissingSubcontractingLocationNotificationId()), LibraryVariableStorage.DequeueText(), NotificationIdErr);
        if VendorNo <> '' then begin
            Assert.AreEqual(SendNotificationTok, LibraryVariableStorage.DequeueText(), NotificationOrderErr);
            Assert.AreEqual(Format(GetMissingSubcontractingLocationNotificationId()), LibraryVariableStorage.DequeueText(), NotificationIdErr);
            Assert.AreEqual(StrSubstNo(MissingSubcontractingLocationMsg, VendorNo), LibraryVariableStorage.DequeueText(), NotificationMessageErr);
            Assert.AreEqual(VendorNo, LibraryVariableStorage.DequeueText(), NotificationVendorErr);
        end;
    end;

    local procedure GetMissingSubcontractingLocationNotificationId(): Guid
    begin
        exit('{8A4B9A58-21EC-49DD-A3A5-C7E81F745B6D}');
    end;

    [SendNotificationHandler]
    procedure SubcontractorLocationNotificationHandler(var SubcontractorLocationNotification: Notification): Boolean
    begin
        if SubcontractorLocationNotification.Id <> GetMissingSubcontractingLocationNotificationId() then
            exit(false);

        CaptureSubcontractorLocationNotification(SubcontractorLocationNotification);
        exit(true);
    end;

    [SendNotificationHandler]
    procedure SubcontractorLocationNotificationActionHandler(var SubcontractorLocationNotification: Notification): Boolean
    var
        SubcNotificationMgmt: Codeunit "Subc. Notification Mgmt.";
    begin
        if SubcontractorLocationNotification.Id <> GetMissingSubcontractingLocationNotificationId() then
            exit(false);

        CaptureSubcontractorLocationNotification(SubcontractorLocationNotification);
        // Simulate choosing the Open Vendor Card notification action.
        SubcNotificationMgmt.OpenVendorCard(SubcontractorLocationNotification);
        exit(true);
    end;

    local procedure CaptureSubcontractorLocationNotification(SubcontractorLocationNotification: Notification)
    begin
        LibraryVariableStorage.Enqueue(SendNotificationTok);
        LibraryVariableStorage.Enqueue(Format(SubcontractorLocationNotification.Id));
        LibraryVariableStorage.Enqueue(SubcontractorLocationNotification.Message);
        LibraryVariableStorage.Enqueue(SubcontractorLocationNotification.GetData(VendorNoTok));
    end;

    [RecallNotificationHandler]
    procedure SubcontractorLocationRecallHandler(var SubcontractorLocationNotification: Notification): Boolean
    begin
        if SubcontractorLocationNotification.Id <> GetMissingSubcontractingLocationNotificationId() then
            exit(false);

        LibraryVariableStorage.Enqueue(RecallNotificationTok);
        LibraryVariableStorage.Enqueue(Format(SubcontractorLocationNotification.Id));
        exit(true);
    end;

    [PageHandler]
    procedure VendorCardHandler(var VendorCard: TestPage "Vendor Card")
    begin
        LibraryVariableStorage.Enqueue(VendorCard."No.".Value());
        VendorCard.Close();
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

    local procedure GetNextItemLedgerEntryNo(): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if ItemLedgerEntry.FindLast() then
            exit(ItemLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    [ConfirmHandler]
    procedure SetupNotCompletedConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedConfirm(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        IsInitialized: Boolean;
        ActionNotExistMsg: Label 'Action %1 does not exist on page %2.', Comment = '%1 = action name, %2 = page number';
        ActionTargetUnexpectedMsg: Label 'Action %1 does not run page %2.', Comment = '%1 = action name, %2 = target page number';
        ControlNotExistMsg: Label 'Control %1 does not exist.', Comment = '%1 = field caption';
        ControlShouldBeHiddenErr: Label 'The %1 control on page %2 should be initially hidden.', Comment = '%1 = field caption, %2 = page number';
        UnsupportedControlExistsMsg: Label 'Unsupported control %1 exists on page %2.', Comment = '%1 = control name, %2 = page number';
        UnsupportedFieldExistsMsg: Label 'Unsupported field %1 exists on table %2.', Comment = '%1 = field name, %2 = table number';
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
        SetupNotCompletedQst: Label 'The Subcontracting setup is not complete. Are you sure you want to exit?';
        MissingSubcontractingLocationMsg: Label 'Vendor %1 has no subcontracting location. This location is used to track components and work-in-process (WIP) items at the subcontractor. Choose a Subcontracting Location Code on the vendor before using this work center for subcontracting.', Comment = '%1 = Vendor No.';
        NotificationIdErr: Label 'The subcontractor location notification ID is unexpected.';
        NotificationMessageErr: Label 'The subcontractor location notification message is unexpected.';
        NotificationOrderErr: Label 'The subcontractor location notification interactions occurred in an unexpected order.';
        NotificationVendorErr: Label 'The vendor in the subcontractor location notification is unexpected.';
        RecallNotificationTok: Label 'Recall', Locked = true;
        SendNotificationTok: Label 'Send', Locked = true;
        VendorCardNoErr: Label 'The Vendor Card opened for an unexpected vendor.';
        VendorNoTok: Label 'VendorNo', Locked = true;
}