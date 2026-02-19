// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.Test.QualityManagement.TestLibraries;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Automation;
using System.Security.User;
using System.TestLibraries.Utilities;

codeunit 139969 "Qlty. Tests - Workflows"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        ReUsableQltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryAssert: Codeunit "Library Assert";
        FilterTok: Label 'WHERE(No.=FILTER([Item:No.]))';
        ValueExprTok: Label 'Yes';
        NewLotTok: Label 'LOT123123';
        EventFilterTok: Label 'Where("Result Code"=Filter(%1))', Comment = '%1=result code.';
        DefaultResult1FailCodeTok: Label 'FAIL', Locked = true;
        DefaultResult2PassCodeTok: Label 'PASS', Locked = true;
        IsInitialized: Boolean;

    [Test]
    procedure PurchaseReturnWorkflow_OnInspectionFinished()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnReason: Record "Return Reason";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        ReturnPurchaseHeader: Record "Purchase Header";
        ReturnPurchaseLine: Record "Purchase Line";
        MoveBehavior: Enum "Qlty. Quantity Behavior";
        CreditMemo: Text;
        Reason: Text;
    begin
        // [SCENARIO] Automatically create a purchase return order when a quality inspection is finished
        Initialize();

        // [GIVEN] A warehouse location and quality management setup with inspection template and generation rule
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A purchase order with inspection created and received
        ReUsableQltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);
        PurchaseLine.Get(PurchaseLine."Document Type"::Order, QltyInspectionHeader."Source Document No.", QltyInspectionHeader."Source Document Line No.");
        ReUsableQltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A return reason code and credit memo number are defined
        QltyInspectionUtility.GenerateRandomCharacters(35, CreditMemo);
        QltyInspectionUtility.GenerateRandomCharacters(10, Reason);
        ReturnReason.Init();
        ReturnReason.Code := CopyStr(Reason, 1, MaxStrLen(ReturnReason.Code));
        ReturnReason.Insert();

        // [GIVEN] A workflow is configured to create purchase return on inspection finished event
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponse(Workflow, QltyInspectionUtility.GetInspectionFinishedEvent(), QltyInspectionUtility.GetWorkflowResponseCreatePurchaseReturn(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyInspectionUtility.GetWorkflowResponseCreatePurchaseReturn(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyInspectionUtility.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownMoveAll(), MoveBehavior::"Specific Quantity");
        QltyInspectionUtility.SetStepConfigurationValueAsDecimal(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyQuantity(), PurchaseLine."Quantity (Base)");
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownExternalDocNo(), CreditMemo);
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownReasonCode(), Reason);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] The inspection status is changed to finished
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();

        // [THEN] A purchase return order is created with correct details
        ReturnPurchaseHeader.SetRange("Document Type", ReturnPurchaseHeader."Document Type"::"Return Order");
        ReturnPurchaseHeader.SetRange("Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");
        LibraryAssert.AreEqual(1, ReturnPurchaseHeader.Count(), 'Should be one purchase return created.');
        ReturnPurchaseHeader.FindFirst();
        LibraryAssert.AreEqual(CreditMemo, ReturnPurchaseHeader."Vendor Cr. Memo No.", 'Credit Memo No. should match.');
        ReturnPurchaseLine.SetRange("Document No.", ReturnPurchaseHeader."No.");
        ReturnPurchaseLine.SetRange("Document Type", ReturnPurchaseHeader."Document Type");
        ReturnPurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        ReturnPurchaseLine.FindFirst();
        LibraryAssert.AreEqual(ReturnReason.Code, ReturnPurchaseLine."Return Reason Code", 'Return Reason Code should match.');
        LibraryAssert.AreEqual(PurchaseLine."Quantity (Base)", ReturnPurchaseLine."Quantity (Base)", 'Return Quantity should match.');

        DeleteWorkflows();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure ClearTestStatusFilter_OnInspectionFinished()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        OriginalQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        Workflow: Record Workflow;
        BeforeCount: Integer;
    begin
        // [SCENARIO] Test-to-test source configuration is applied from a create test workflow when source inspection was filtered by status

        Initialize();

        // [GIVEN] A warehouse location and quality management setup with inspection template
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A purchase order with lot tracked item and inspection created
        ReUsableQltyPurOrderGenerator.CreateInspectionFromPurchaseWithLotTrackedItem(Location, 100, PurchaseHeader, PurchaseLine, OriginalQltyInspectionHeader, ReservationEntry);

        // [GIVEN] An inspection-to-inspection source configuration with field mappings
        QltyInspectionUtility.CreateSourceConfig(
            SpecificQltyInspectSourceConfig,
            Database::"Qlty. Inspection Header",
            Enum::"Qlty. Target Type"::Inspection,
            Database::"Qlty. Inspection Header");

        QltyInspectionUtility.CreateSourceFieldConfigByName(SpecificQltyInspectSourceConfig.Code, Database::"Qlty. Inspection Header", Enum::"Qlty. Target Type"::Inspection, 'Source Document No.');
        QltyInspectionUtility.CreateSourceFieldConfigByName(SpecificQltyInspectSourceConfig.Code, Database::"Qlty. Inspection Header", Enum::"Qlty. Target Type"::Inspection, 'Source Document Line No.');
        QltyInspectionUtility.CreateSourceFieldConfigByName(SpecificQltyInspectSourceConfig.Code, Database::"Qlty. Inspection Header", Enum::"Qlty. Target Type"::Inspection, 'Source Item No.');
        QltyInspectionUtility.CreateSourceFieldConfigByName(SpecificQltyInspectSourceConfig.Code, Database::"Qlty. Inspection Header", Enum::"Qlty. Target Type"::Inspection, 'Source Quantity (Base)');
        QltyInspectionUtility.CreateSourceFieldConfigByName(SpecificQltyInspectSourceConfig.Code, Database::"Qlty. Inspection Header", Enum::"Qlty. Target Type"::Inspection, 'Source Lot No.');

        // [GIVEN] A workflow configured to create new inspection from existing inspection
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Qlty. Inspection Header");

        QltyManagementSetup.Get();
        QltyManagementSetup."Inspection Creation Option" := QltyManagementSetup."Inspection Creation Option"::"Always create new inspection";
        QltyManagementSetup.Modify();

        CreateWorkflowWithSingleResponse(Workflow, QltyInspectionUtility.GetInspectionFinishedEvent(), QltyInspectionUtility.GetWorkflowResponseCreateInspection(), true);
        BeforeCount := QltyInspectionHeader.Count();
        OriginalQltyInspectionHeader.SetRange(Status, OriginalQltyInspectionHeader.Status::Open);

        // [WHEN] The original inspection status is changed to finished
        OriginalQltyInspectionHeader.Validate(Status, OriginalQltyInspectionHeader.Status::Finished);
        OriginalQltyInspectionHeader.Modify();

        // [THEN] A new inspection is created with source configuration fields applied from the original inspection
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one new inspection created.');
        CreatedQltyInspectionHeader.SetRange("Source Document No.", OriginalQltyInspectionHeader."Source Document No.");
        CreatedQltyInspectionHeader.SetRange("Source Document Line No.", OriginalQltyInspectionHeader."Source Document Line No.");
        LibraryAssert.AreEqual(2, CreatedQltyInspectionHeader.Count(), 'Should be two inspections for the source document.');
        CreatedQltyInspectionHeader.FindLast();
        LibraryAssert.AreNotEqual(OriginalQltyInspectionHeader."No.", CreatedQltyInspectionHeader."No.", 'Should be a new inspection created.');
        LibraryAssert.AreEqual(OriginalQltyInspectionHeader."Source Item No.", CreatedQltyInspectionHeader."Source Item No.", 'Should have applied source config fields. (Item No.)');
        LibraryAssert.AreEqual(OriginalQltyInspectionHeader."Source Quantity (Base)", CreatedQltyInspectionHeader."Source Quantity (Base)", 'Should have applied source config fields. (Source Quantity (Base))');
        LibraryAssert.AreEqual(OriginalQltyInspectionHeader."Source Lot No.", CreatedQltyInspectionHeader."Source Lot No.", 'Should have applied source config fields. (Source Lot No.)');

        DeleteWorkflows();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure CreateInternalPutaway_OnInspectionReopened()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        ToUseNoSeries: Record "No. Series";
        ToUseNoSeriesLine: Record "No. Series Line";
        WarehouseSetup: Record "Warehouse Setup";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PutawayWarehouseActivityHeader: Record "Warehouse Activity Header";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        PutawayWarehouseActivityLine: Record "Warehouse Activity Line";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        MoveBehavior: Enum "Qlty. Quantity Behavior";
        PutawayCount: Integer;
    begin
        // [SCENARIO] Create an internal warehouse put-away when a quality inspection is reopened

        Initialize();

        // [GIVEN] A full warehouse management location with quality setup
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] An item, warehouse employee, and number series for internal put-aways
        LibraryInventory.CreateItem(Item);

        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        WarehouseSetup.Get();
        if WarehouseSetup."Whse. Internal Put-away Nos." = '' then begin
            LibraryUtility.CreateNoSeries(ToUseNoSeries, true, true, false);
            LibraryUtility.CreateNoSeriesLine(ToUseNoSeriesLine, ToUseNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
            WarehouseSetup."Whse. Internal Put-away Nos." := ToUseNoSeries.Code;
            WarehouseSetup.Modify();
        end;

        // [GIVEN] A purchase order received with quality inspection created from warehouse entry
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] A workflow configured to create internal put-away on inspection reopened event
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponse(Workflow, QltyInspectionUtility.GetInspectionReopenedEvent(), QltyInspectionUtility.GetWorkflowResponseInternalPutAway(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyInspectionUtility.GetWorkflowResponseInternalPutAway(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyInspectionUtility.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownMoveAll(), MoveBehavior::"Specific Quantity");
        QltyInspectionUtility.SetStepConfigurationValueAsDecimal(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyQuantity(), PurchaseLine."Quantity (Base)");
        QltyInspectionUtility.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownCreatePutAway(), true);
        Workflow.Enabled := true;
        Workflow.Modify();

        PutawayWarehouseActivityHeader.SetRange(Type, PutawayWarehouseActivityHeader.Type::"Put-away");
        PutawayCount := PutawayWarehouseActivityHeader.Count();

        // [WHEN] The inspection is finished and then reopened
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Open);
        QltyInspectionHeader.Modify();

        // [THEN] A warehouse put-away is created with correct item and quantity
        LibraryAssert.AreEqual(PutawayCount + 1, PutawayWarehouseActivityHeader.Count(), 'Should have created a warehouse put-away.');
        PutawayWarehouseActivityLine.SetRange("Activity Type", PutawayWarehouseActivityLine."Activity Type"::"Put-away");
        PutawayWarehouseActivityLine.SetRange("Location Code", Location.Code);
        PutawayWarehouseActivityLine.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionHeader."Source Item No.", PutawayWarehouseActivityLine."Item No.", 'Should be correct item.');
        LibraryAssert.AreEqual(QltyInspectionHeader."Source Quantity (Base)", PutawayWarehouseActivityLine.Quantity, 'Should have specific quantity.');

        DeleteWorkflows();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure CreateNegativeAdjustment_OnInspectionFinished()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        ReasonCode: Record "Reason Code";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        MoveBehavior: Enum "Qlty. Quantity Behavior";
        AdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
        ReasonCodeToTest: Text;
    begin
        // [SCENARIO] Create and post a negative inventory adjustment when a quality inspection is finished

        Initialize();

        // [GIVEN] Quality management setup with inspection template and generation rule
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A warehouse location with bins and a lot tracked item
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order received with quality inspection created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] A reason code and item journal batch for adjustments
        QltyInspectionUtility.GenerateRandomCharacters(20, ReasonCodeToTest);
        ReasonCode.Init();
        ReasonCode.Validate(Code, CopyStr(ReasonCodeToTest, 1, MaxStrLen(ReasonCode.Code)));
        ReasonCode.Description := CopyStr(ReasonCodeToTest, 1, MaxStrLen(ReasonCode.Description));
        ReasonCode.Insert();

        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        QltyManagementSetup.Get();
        QltyManagementSetup."Item Journal Batch Name" := ItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A workflow configured to create and post inventory adjustment on inspection finished
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponse(Workflow, QltyInspectionUtility.GetInspectionFinishedEvent(), QltyInspectionUtility.GetWorkflowResponseInventoryAdjustment(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyInspectionUtility.GetWorkflowResponseInventoryAdjustment(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyInspectionUtility.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownMoveAll(), MoveBehavior::"Specific Quantity");
        QltyInspectionUtility.SetStepConfigurationValueAsDecimal(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyQuantity(), 50);
        QltyInspectionUtility.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownPostImmediately(), true);
        QltyInspectionUtility.SetStepConfigurationValueAsAdjPostingEnum(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownAdjPostingBehavior(), AdjPostBehavior::Post);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] The inspection status is changed to finished
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();

        // [THEN] A negative adjustment item ledger entry is posted with correct quantity
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        ItemLedgerEntry.SetRange(Quantity, -50);
        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'Should have posted one negative adjustment.');

        DeleteWorkflows();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure CreateTransfer_OnInspectionChange()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        DestinationLocation: Record Location;
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        Bin: Record Bin;
        Item: Record Item;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        MoveBehavior: Enum "Qlty. Quantity Behavior";
    begin
        // [SCENARIO] Create a transfer order for failed quantity when a quality inspection result changes

        Initialize();

        // [GIVEN] Quality management setup with inspection template and locations
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A source location with bins and a destination location
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        LibraryWarehouse.CreateLocationWMS(DestinationLocation, false, false, false, false, false);

        // [GIVEN] A purchase order received with inspection created
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, ConfigurationToLoadQltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [GIVEN] A workflow configured to create transfer for failed quantity on inspection change
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponse(Workflow, QltyInspectionUtility.GetInspectionHasChangedEvent(), QltyInspectionUtility.GetWorkflowResponseCreateTransfer(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyInspectionUtility.GetWorkflowResponseCreateTransfer(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyInspectionUtility.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownMoveAll(), MoveBehavior::"Failed Quantity");
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyLocation(), DestinationLocation.Code);
        QltyInspectionUtility.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownDirectTransfer(), true);
        Workflow.Enabled := true;
        Workflow.Modify();

        ToLoadQltyInspectionResult.SetRange("Result Category", ToLoadQltyInspectionResult."Result Category"::"Not acceptable");
        QltyInspectionHeader."Fail Quantity" := 2;
        QltyInspectionHeader.Modify();

        // [WHEN] The inspection result is set to a failing result
        QltyInspectionHeader.Validate("Result Code", ToLoadQltyInspectionResult.Code);
        QltyInspectionHeader.Modify(true);

        // [THEN] A direct transfer order is created with the failed quantity
        TransferHeader.SetRange("Transfer-from Code", Location.Code);
        TransferHeader.SetRange("Transfer-to Code", DestinationLocation.Code);
        TransferHeader.SetRange("Direct Transfer", true);

        LibraryAssert.AreEqual(1, TransferHeader.Count(), 'Should be one transfer header created.');

        TransferLine.SetRange("Transfer-from Code", Location.Code);
        TransferLine.SetRange("Transfer-to Code", DestinationLocation.Code);
        TransferLine.SetRange("Item No.", Item."No.");

        LibraryAssert.AreEqual(1, TransferLine.Count(), 'Should be one transfer line created.');
        TransferLine.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionHeader."Fail Quantity", TransferLine.Quantity, 'Should have requested quantity.');
        LibraryAssert.AreEqual(Bin.Code, TransferLine."Transfer-from Bin Code", 'Should have transfer-from bin code.');

        QltyInspectionGenRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure ChangeDatabaseValue_OnInspectionFinish()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] Update a database field value when a quality inspection is finished

        Initialize();

        // [GIVEN] A full warehouse management location with quality setup
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] A purchase order received with inspection created from warehouse entry
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] A workflow configured to set database value (blocking purchasing) on inspection finished
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponse(Workflow, QltyInspectionUtility.GetInspectionFinishedEvent(), QltyInspectionUtility.GetWorkflowResponseSetDatabaseValue(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyInspectionUtility.GetWorkflowResponseSetDatabaseValue(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyDatabaseTable(), Item.TableCaption());
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyDatabaseTableFilter(), FilterTok);
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyField(), Item.FieldCaption("Purchasing Blocked"));
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyValueExpression(), ValueExprTok);
        Workflow.Enabled := true;
        Workflow.Modify();

        LibraryAssert.IsFalse(Item."Purchasing Blocked", 'Item purchasing not be blocked.');

        // [WHEN] The inspection status is changed to finished
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();

        // [THEN] The item purchasing blocked field is set to true
        Item.Get(Item."No.");
        LibraryAssert.IsTrue(Item."Purchasing Blocked", 'Item purchasing should be blocked.');

        DeleteWorkflows();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure Move_DPP_UseWorksheet_Pass_EntriesOnly_OnInspectionFinish()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
        WhseWorksheetTemplateToUseToUse: Text;
    begin
        // [SCENARIO] Move passed quantity using warehouse worksheet for directed put-away and pick location when inspection is finished

        Initialize();

        // [GIVEN] Quality management setup with warehouse entry generation rule
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] A full warehouse management location and warehouse worksheet setup
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        if not WhseWorksheetLine.IsEmpty() then
            WhseWorksheetLine.DeleteAll();
        if not WhseWorksheetName.IsEmpty() then
            WhseWorksheetName.DeleteAll();
        if not WhseWorksheetTemplate.IsEmpty() then
            WhseWorksheetTemplate.DeleteAll();

        WhseWorksheetTemplate.Init();
        QltyInspectionUtility.GenerateRandomCharacters(10, WhseWorksheetTemplateToUseToUse);
        WhseWorksheetTemplate.Name := CopyStr(WhseWorksheetTemplateToUseToUse, 1, MaxStrLen(WhseWorksheetTemplate.Name));
        WhseWorksheetTemplate.Type := WhseWorksheetTemplate.Type::Movement;
        WhseWorksheetTemplate."Page ID" := Page::"Movement Worksheet";
        WhseWorksheetTemplate.Insert();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);
        QltyManagementSetup.Get();
        QltyManagementSetup."Movement Worksheet Name" := WhseWorksheetName.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A purchase order received with inspection from warehouse entry
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        QltyInspectionHeader."Pass Quantity" := 10;
        QltyInspectionHeader.Modify();

        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        // [GIVEN] A workflow configured to move passed quantity using worksheet on inspection finished
        CreateWorkflowWithSingleResponse(Workflow, QltyInspectionUtility.GetInspectionFinishedEvent(), QltyInspectionUtility.GetWorkflowResponseMoveInventory(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyInspectionUtility.GetWorkflowResponseMoveInventory(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyInspectionUtility.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownUseMoveSheet(), true);
        QltyInspectionUtility.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownMoveAll(), QuantityBehavior::"Passed Quantity");
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyLocation(), Location.Code);
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyBin(), Bin.Code);
        QltyInspectionUtility.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownPostImmediately(), false);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] The inspection status is changed to finished
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();

        // [THEN] A warehouse worksheet line is created with correct bins and passed quantity
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetTemplate.Name);
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", Location.Code);
        WhseWorksheetLine.SetRange("Item No.", Item."No.");
        WhseWorksheetLine.FindFirst();

        LibraryAssert.AreEqual(WarehouseEntry."Zone Code", WhseWorksheetLine."From Zone Code", 'Should have matching from zone code.');
        LibraryAssert.AreEqual(WarehouseEntry."Bin Code", WhseWorksheetLine."From Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin."Zone Code", WhseWorksheetLine."To Zone Code", 'Should have correct requested to zone code.');
        LibraryAssert.AreEqual(Bin.Code, WhseWorksheetLine."To Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(QltyInspectionHeader."Pass Quantity", WhseWorksheetLine.Quantity, 'Should have correct requested quantity.');

        WhseWorksheetLine.Delete();
        WhseWorksheetName.Delete();
        WhseWorksheetTemplate.Delete();
        QltyInspectionGenRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure Move_DPP_Reclass_Sample_OnInspectionFinish()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
    begin
        // [SCENARIO] Move sample quantity using warehouse reclassification journal for directed put-away and pick location when inspection is finished

        Initialize();

        // [GIVEN] Quality management setup with warehouse reclassification batch configured
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] A full warehouse management location
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        QltyManagementSetup.Get();
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A purchase order received with inspection from warehouse entry
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        QltyInspectionHeader."Sample Size" := 10;
        QltyInspectionHeader.Modify();

        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        // [GIVEN] A workflow configured to move sample quantity using reclassification journal on inspection finished
        CreateWorkflowWithSingleResponse(Workflow, QltyInspectionUtility.GetInspectionFinishedEvent(), QltyInspectionUtility.GetWorkflowResponseMoveInventory(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyInspectionUtility.GetWorkflowResponseMoveInventory(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyInspectionUtility.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownUseMoveSheet(), false);
        QltyInspectionUtility.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownMoveAll(), QuantityBehavior::"Sample Quantity");
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyLocation(), Location.Code);
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyBin(), Bin.Code);
        QltyInspectionUtility.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownPostImmediately(), false);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] The inspection status is changed to finished
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();

        // [THEN] A warehouse reclassification journal line is created with correct bins and sample quantity
        ReclassWarehouseJournalLine.SetRange("Journal Template Name", ReclassWhseItemWarehouseJournalTemplate.Name);
        ReclassWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        ReclassWarehouseJournalLine.SetRange("Item No.", Item."No.");
        ReclassWarehouseJournalLine.FindFirst();

        LibraryAssert.AreEqual(WarehouseEntry."Zone Code", ReclassWarehouseJournalLine."From Zone Code", 'Should have matching from zone code.');
        LibraryAssert.AreEqual(WarehouseEntry."Bin Code", ReclassWarehouseJournalLine."From Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin."Zone Code", ReclassWarehouseJournalLine."To Zone Code", 'Should have correct requested to zone code.');
        LibraryAssert.AreEqual(Bin.Code, ReclassWarehouseJournalLine."To Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(QltyInspectionHeader."Sample Size", ReclassWarehouseJournalLine.Quantity, 'Should have correct requested quantity.');

        ReclassWarehouseJournalLine.Delete();
        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure Move_NonDPP_UseWorksheet_Fail_OnInspectionFinish()
    var
        InventorySetup: Record "Inventory Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        ToUseNoSeries: Record "No. Series";
        ToUseNoSeriesLine: Record "No. Series Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        InternalMovementLine: Record "Internal Movement Line";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
    begin
        // [SCENARIO] Move failed quantity using internal movement worksheet for non-directed put-away location when inspection is finished

        Initialize();

        // [GIVEN] Quality management setup with purchase line generation rule
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location with bins and internal movement number series
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        LibraryUtility.CreateNoSeries(ToUseNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(ToUseNoSeriesLine, ToUseNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        InventorySetup.Get();
        InventorySetup."Internal Movement Nos." := ToUseNoSeries.Code;
        InventorySetup.Modify();

        // [GIVEN] A purchase order received with inspection created
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, ConfigurationToLoadQltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1', PurchaseLine."Bin Code");
        Bin.FindFirst();

        QltyInspectionHeader."Fail Quantity" := 3;
        QltyInspectionHeader.Modify();

        // [GIVEN] A workflow configured to move failed quantity using internal movement on inspection finished
        CreateWorkflowWithSingleResponse(Workflow, QltyInspectionUtility.GetInspectionFinishedEvent(), QltyInspectionUtility.GetWorkflowResponseMoveInventory(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyInspectionUtility.GetWorkflowResponseMoveInventory(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyInspectionUtility.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownUseMoveSheet(), true);
        QltyInspectionUtility.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownMoveAll(), QuantityBehavior::"Failed Quantity");
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyLocation(), Location.Code);
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyBin(), Bin.Code);
        QltyInspectionUtility.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownPostImmediately(), false);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] The inspection status is changed to finished
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();

        // [THEN] An internal movement line is created with correct bins and failed quantity
        InternalMovementLine.SetRange("Location Code", Location.Code);
        InternalMovementLine.SetRange("Item No.", Item."No.");
        InternalMovementLine.FindFirst();

        LibraryAssert.AreEqual(PurchaseLine."Bin Code", InternalMovementLine."From Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin.Code, InternalMovementLine."To Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(QltyInspectionHeader."Fail Quantity", InternalMovementLine.Quantity, 'Should have correct requested quantity.');

        QltyInspectionGenRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure Move_NonDPP_Reclass_Tracked_Filtered_OnInspectionFinish()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        ReclassReservationEntry: Record "Reservation Entry";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        InitialChangeBin: Code[20];
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
    begin
        // [SCENARIO] Move item tracked quantity using reclassification journal with bin filters for non-directed put-away location when inspection is finished

        Initialize();

        // [GIVEN] Quality management setup with item journal batch configured for bin moves
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);
        QltyManagementSetup.Get();
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);
        QltyManagementSetup."Item Reclass. Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A location with bins and a lot tracked item
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order received with lot tracking and inspection created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] A reclassification journal is posted to move 50 units to an intermediate bin
        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);
        LibraryInventory.CreateItemJournalLine(ReclassItemJournalLine, ReclassItemJournalTemplate.Name, ReclassItemJournalBatch.Name, ReclassItemJournalLine."Entry Type"::Transfer, Item."No.", 50);
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1', PurchaseLine."Bin Code");
        Bin.FindFirst();
        InitialChangeBin := Bin.Code;
        ReclassItemJournalLine."Location Code" := Location.Code;
        ReclassItemJournalLine."Bin Code" := PurchaseLine."Bin Code";
        ReclassItemJournalLine."New Location Code" := Location.Code;
        ReclassItemJournalLine."New Bin Code" := InitialChangeBin;
        ReclassItemJournalLine.Modify();
        LibraryItemTracking.CreateItemReclassJnLineItemTracking(ReclassReservationEntry, ReclassItemJournalLine, '', ReservationEntry."Lot No.", 50);
        ReclassReservationEntry."New Lot No." := ReclassReservationEntry."Lot No.";
        ReclassReservationEntry.Modify();
        LibraryInventory.PostItemJournalBatch(ReclassItemJournalBatch);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        WarehouseEntry.SetRange("Bin Code", InitialChangeBin);
        WarehouseEntry.FindFirst();
        LibraryAssert.AreEqual(50, WarehouseEntry.Quantity, 'Test setup failed. Bin should have a quantity of 50 of the item.');

        // [GIVEN] A third bin is identified as the final destination
        Clear(Bin);
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1&<>%2', PurchaseLine."Bin Code", InitialChangeBin);
        Bin.FindFirst();

        // [GIVEN] A workflow configured to move tracked quantity with source bin filter on inspection finished
        CreateWorkflowWithSingleResponse(Workflow, QltyInspectionUtility.GetInspectionFinishedEvent(), QltyInspectionUtility.GetWorkflowResponseMoveInventory(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyInspectionUtility.GetWorkflowResponseMoveInventory(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyInspectionUtility.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownUseMoveSheet(), false);
        QltyInspectionUtility.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownMoveAll(), QuantityBehavior::"Item Tracked Quantity");
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyLocation(), Location.Code);
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyBin(), Bin.Code);
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownSourceLocationFilter(), Location.Code);
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownSourceBinFilter(), InitialChangeBin);
        QltyInspectionUtility.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownPostImmediately(), true);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] The inspection status is changed to finished
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();

        // [THEN] The lot tracked quantity is moved from the filtered bin to the target bin
        Clear(WarehouseEntry);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.FindSet();
        LibraryAssert.AreEqual(1, WarehouseEntry.Count(), 'Should be one movement into new bin.');
        LibraryAssert.AreEqual(50, WarehouseEntry.Quantity, 'Bin should have received 50 of the item.');

        ReclassItemJournalBatch.Delete();
        ReclassItemJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure ChangeTracking_LotAndExp_OnInspectionFinished()
    var
        Location: Record Location;
        Item: Record Item;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        WarehouseEntry: Record "Warehouse Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        WhseItemWarehouseJournalLine: Record "Warehouse Journal Line";
        CheckCreatedJnlWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        QltyManagementSetup: Record "Qlty. Management Setup";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
    begin
        // [SCENARIO] Change item tracking lot number and expiration date using warehouse reclassification journal when inspection is finished

        Initialize();

        // [GIVEN] Quality management setup with lot tracked item using expiration dates
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);
        LotItemTrackingCode."Use Expiration Dates" := true;
        LotItemTrackingCode.Modify();
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] A full warehouse management location with warehouse reclassification batch
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);
        QltyManagementSetup.Get();
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Whse. Reclass. Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A purchase order received with inspection created from warehouse entry
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] A workflow configured to change item tracking (lot and expiration date) on inspection finished
        CreateWorkflowWithSingleResponse(Workflow, QltyInspectionUtility.GetInspectionFinishedEvent(), QltyInspectionUtility.GetWorkflowResponseChangeItemTracking(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyInspectionUtility.GetWorkflowResponseChangeItemTracking(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyInspectionUtility.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownMoveAll(), QuantityBehavior::"Item Tracked Quantity");
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownNewLotNo(), NewLotTok);
        QltyInspectionUtility.SetStepConfigurationValueAsDate(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownNewExpDate(), WorkDate());
        QltyInspectionUtility.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownPostImmediately(), false);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] The inspection status is changed to finished
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();

        // [THEN] A warehouse reclassification journal line is created with new lot number and expiration date
        WhseItemWarehouseJournalLine.SetRange("Journal Template Name", ReclassWarehouseJournalBatch."Journal Template Name");
        WhseItemWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        LibraryAssert.AreEqual(1, WhseItemWarehouseJournalLine.Count(), 'warehouse journal line should have been created.');
        WhseItemWarehouseJournalLine.FindFirst();
        LibraryAssert.AreEqual(WhseItemWarehouseJournalLine."From Bin Code", WhseItemWarehouseJournalLine."To Bin Code", 'with item tracking changes, the bins must match.');
        LibraryAssert.AreEqual(PurchaseLine."Quantity (Base)", WhseItemWarehouseJournalLine."Qty. (Base)", 'base quantity should match');
        LibraryAssert.AreEqual(PurchaseLine.Quantity, WhseItemWarehouseJournalLine.Quantity, 'quantity should match');

        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source Type", Database::"Warehouse Journal Line");
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source ID", ReclassWarehouseJournalBatch.Name);
        CheckCreatedJnlWhseItemTrackingLine.SetRange("Source Batch Name", ReclassWarehouseJournalBatch."Journal Template Name");
        LibraryAssert.AreEqual(1, CheckCreatedJnlWhseItemTrackingLine.Count(), 'Tracking Line should have been created.');
        CheckCreatedJnlWhseItemTrackingLine.FindFirst();

        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Source Subtype" = 0, 'Tracking Line should have subtype 0');
        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Source Prod. Order Line" = 0, 'Tracking Line should have Source Prod. Order Line 0');
        LibraryAssert.IsTrue(CheckCreatedJnlWhseItemTrackingLine."Qty. per Unit of Measure" = 1, 'Should have Qty. per Unit of Measure = 1');
        LibraryAssert.AreEqual(ReservationEntry."Lot No.", CheckCreatedJnlWhseItemTrackingLine."Lot No.", 'Lot No. should match provided lot no.');
        LibraryAssert.AreEqual(NewLotTok, CheckCreatedJnlWhseItemTrackingLine."New Lot No.", 'Lot No. should match provided lot no.');
        LibraryAssert.AreEqual(WorkDate(), CheckCreatedJnlWhseItemTrackingLine."New Expiration Date", 'The new expiration date should match the request.');
        LibraryAssert.AreEqual(PurchaseLine."Quantity (Base)", CheckCreatedJnlWhseItemTrackingLine."Quantity (Base)", 'Quantity (Base) should match.');
        LibraryAssert.AreEqual(PurchaseLine."Quantity (Base)", CheckCreatedJnlWhseItemTrackingLine."Qty. to Handle (Base)", 'Quantity to Handle (Base) should match.');
        LibraryAssert.AreEqual(PurchaseLine.Quantity, CheckCreatedJnlWhseItemTrackingLine."Qty. to Handle", 'Quantity to Handle should match.');

        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();
        QltyInspectionGenRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CreateReinspection()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Item: Record Item;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        CreatedInspections: Integer;
    begin
        // [SCENARIO] Automatically create a re-inspection when a quality inspection is finished

        Initialize();

        // [GIVEN] Quality management setup with warehouse entry generation rule
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);

        // [GIVEN] A full warehouse management location and purchase order received with inspection
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        LibraryInventory.CreateItem(Item);
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntry(WarehouseEntry, QltyInspectionHeader);

        // [GIVEN] A workflow configured to create re-inspection on inspection finished event
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponse(Workflow, QltyInspectionUtility.GetInspectionFinishedEvent(), QltyInspectionUtility.GetWorkflowResponseCreateReinspection(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyInspectionUtility.GetWorkflowResponseCreateReinspection(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        Workflow.Enabled := true;
        Workflow.Modify();
        CreatedInspections := CreatedQltyInspectionHeader.Count();

        // [WHEN] The inspection status is changed to finished
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();

        // [THEN] A new re-inspection is created with same inspection number but incremented re-inspection number
        LibraryAssert.AreEqual(CreatedInspections + 1, CreatedQltyInspectionHeader.Count(), 'Should be one more inspection created.');
        CreatedQltyInspectionHeader.SetRange("No.", QltyInspectionHeader."No.");
        LibraryAssert.AreEqual(2, CreatedQltyInspectionHeader.Count(), 'Should be 2 inspections (one original and one re-inspection)');

        QltyInspectionGenRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure FinishInspection()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Item: Record Item;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Workflow: Record Workflow;
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        LibraryInventory: Codeunit "Library - Inventory";
        ApprovalLibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Automatically finish a quality inspection when a purchase approval workflow is completed

        Initialize();

        // [GIVEN] Quality management setup with purchase header source configuration and generation rule
        QltyInspectionUtility.EnsureSetupExists();
        CreatePurHeaderToInspectionConfig();
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Header", QltyInspectionGenRule);

        // [GIVEN] A purchase order with inspection created
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        RecordRef.GetTable(PurchaseHeader);
        QltyInspectionUtility.CreateInspection(RecordRef, false, QltyInspectionHeader);

        // [GIVEN] A purchase approval workflow configured to finish inspection after approval
        QltyManagementSetup.Get();
        CreatePurchaseApprovalRequestWorkflowWithResponse(Workflow, QltyInspectionUtility.GetWorkflowResponseFinishInspection(), true);
        UserSetup.LockTable();
        if UserSetup.Get(UserId()) then
            UserSetup.Delete(false);
        ApprovalLibraryDocumentApprovals.SetupUserWithApprover(UserSetup);

        // [WHEN] The purchase order approval is sent and automatically approved
        if ApprovalsMgmt.CheckPurchaseApprovalPossible(PurchaseHeader) then
            ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // [THEN] The inspection status is automatically set to finished
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        LibraryAssert.IsTrue(QltyInspectionHeader.Status = QltyInspectionHeader.Status::Finished, 'Inspection status should be finished.');

        QltyInspectionGenRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReopenInspection()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Item: Record Item;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Workflow: Record Workflow;
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        LibraryInventory: Codeunit "Library - Inventory";
        ApprovalLibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Automatically reopen a finished quality inspection when a purchase approval workflow is completed

        Initialize();

        // [GIVEN] Quality management setup with purchase header source configuration and generation rule
        QltyInspectionUtility.EnsureSetupExists();
        CreatePurHeaderToInspectionConfig();
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Header", QltyInspectionGenRule);

        // [GIVEN] A purchase order with inspection created and finished
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        RecordRef.GetTable(PurchaseHeader);
        QltyInspectionUtility.CreateInspection(RecordRef, false, QltyInspectionHeader);
        QltyInspectionHeader.FinishInspection();

        // [GIVEN] A purchase approval workflow configured to reopen inspection after approval
        QltyManagementSetup.Get();
        CreatePurchaseApprovalRequestWorkflowWithResponse(Workflow, QltyInspectionUtility.GetWorkflowResponseReopenInspection(), true);
        UserSetup.LockTable();
        if UserSetup.Get(UserId()) then
            UserSetup.Delete(false);
        ApprovalLibraryDocumentApprovals.SetupUserWithApprover(UserSetup);

        // [WHEN] The purchase order approval is sent and automatically approved
        if ApprovalsMgmt.CheckPurchaseApprovalPossible(PurchaseHeader) then
            ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // [THEN] The inspection status is automatically set to open
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        LibraryAssert.IsTrue(QltyInspectionHeader.Status = QltyInspectionHeader.Status::Open, 'Inspection status should be open.');

        QltyInspectionGenRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure BlockLot()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        LotNoInformation: Record "Lot No. Information";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Workflow: Record Workflow;
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] Block a lot number when a quality inspection with failing result is finished

        Initialize();

        // [GIVEN] Quality management setup with lot tracked item and warehouse entry generation rule
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order received with lot tracking and inspection created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] A workflow configured to block lot on inspection finished with failing result condition
        ToLoadQltyInspectionResult.Get(DefaultResult1FailCodeTok);
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponseAndEventCondition(Workflow, QltyInspectionUtility.GetInspectionFinishedEvent(), QltyInspectionUtility.GetWorkflowResponseBlockLot(), StrSubstNo(EventFilterTok, ToLoadQltyInspectionResult.Code), true);

        // [WHEN] The inspection result is set to failing result and inspection is finished
        QltyInspectionHeader.Validate("Result Code", ToLoadQltyInspectionResult.Code);
        QltyInspectionHeader.Modify();
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();

        // [THEN] The lot number information is marked as blocked
        LotNoInformation.Get(Item."No.", '', ReservationEntry."Lot No.");
        LibraryAssert.IsTrue(LotNoInformation.Blocked, 'Should be blocked.');

        QltyInspectionGenRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure UnblockLot()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        LotNoInformation: Record "Lot No. Information";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Workflow: Record Workflow;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] Unblock a lot number when a quality inspection with passing result is finished

        Initialize();

        // [GIVEN] Quality management setup with lot tracked item and blocked lot number
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order received with lot tracking and inspection created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionHeader);
        ToLoadQltyInspectionResult.Get(DefaultResult2PassCodeTok);
        LibraryItemTracking.CreateLotNoInformation(LotNoInformation, Item."No.", '', ReservationEntry."Lot No.");
        LotNoInformation.Blocked := true;
        LotNoInformation.Modify();
        LibraryAssert.IsTrue(LotNoInformation.Blocked, 'Should be blocked.');

        // [GIVEN] A workflow configured to unblock lot on inspection finished with passing result condition
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponseAndEventCondition(Workflow, QltyInspectionUtility.GetInspectionFinishedEvent(), QltyInspectionUtility.GetWorkflowResponseUnblockLot(), StrSubstNo(EventFilterTok, ToLoadQltyInspectionResult.Code), true);

        // [WHEN] The inspection result is set to passing result and inspection is finished
        QltyInspectionHeader.Validate("Result Code", ToLoadQltyInspectionResult.Code);
        QltyInspectionHeader.Modify();
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();

        // [THEN] The lot number information is marked as unblocked
        LotNoInformation.Get(Item."No.", '', ReservationEntry."Lot No.");
        LibraryAssert.IsFalse(LotNoInformation.Blocked, 'Should not be blocked.');

        QltyInspectionGenRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure BlockSerial()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ToUseNoSeries: Record "No. Series";
        Location: Record Location;
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        SerialNoInformation: Record "Serial No. Information";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Workflow: Record Workflow;
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] Block a serial number when a quality inspection with failing result is finished

        Initialize();

        // [GIVEN] Quality management setup with serial tracked item and warehouse entry generation rule
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        QltyInspectionUtility.CreateSerialTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] A purchase order received with serial tracking and inspection created
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionHeader);
        ToLoadQltyInspectionResult.Get(DefaultResult1FailCodeTok);

        // [GIVEN] A workflow configured to block serial on inspection finished with failing result condition
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponseAndEventCondition(Workflow, QltyInspectionUtility.GetInspectionFinishedEvent(), QltyInspectionUtility.GetWorkflowResponseBlockSerial(), StrSubstNo(EventFilterTok, ToLoadQltyInspectionResult.Code), true);

        // [WHEN] The inspection result is set to failing result and inspection is finished
        QltyInspectionHeader.Validate("Result Code", ToLoadQltyInspectionResult.Code);
        QltyInspectionHeader.Modify();
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();

        // [THEN] The serial number information is marked as blocked
        SerialNoInformation.Get(Item."No.", '', ReservationEntry."Serial No.");
        LibraryAssert.IsTrue(SerialNoInformation.Blocked, 'Should be blocked.');

        QltyInspectionGenRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure UnblockSerial()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        ReservationEntry: Record "Reservation Entry";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        SerialNoInformation: Record "Serial No. Information";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Workflow: Record Workflow;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] Unblock a serial number when a quality inspection with passing result is finished

        Initialize();

        // [GIVEN] Quality management setup with serial tracked item and blocked serial number
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        QltyInspectionUtility.CreateSerialTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] A purchase order received with serial tracking and inspection created
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionHeader);
        ToLoadQltyInspectionResult.Get(DefaultResult2PassCodeTok);
        LibraryItemTracking.CreateSerialNoInformation(SerialNoInformation, Item."No.", '', ReservationEntry."Serial No.");
        SerialNoInformation.Blocked := true;
        SerialNoInformation.Modify();
        LibraryAssert.IsTrue(SerialNoInformation.Blocked, 'Should be blocked.');

        // [GIVEN] A workflow configured to unblock serial on inspection finished with passing result condition
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponseAndEventCondition(Workflow, QltyInspectionUtility.GetInspectionFinishedEvent(), QltyInspectionUtility.GetWorkflowResponseUnblockSerial(), StrSubstNo(EventFilterTok, ToLoadQltyInspectionResult.Code), true);

        // [WHEN] The inspection result is set to passing result and inspection is finished
        QltyInspectionHeader.Validate("Result Code", ToLoadQltyInspectionResult.Code);
        QltyInspectionHeader.Modify();
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();

        // [THEN] The serial number information is marked as unblocked
        SerialNoInformation.Get(Item."No.", '', ReservationEntry."Serial No.");
        LibraryAssert.IsFalse(SerialNoInformation.Blocked, 'Should not be blocked.');

        QltyInspectionGenRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure BlockPackage()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ToUseNoSeries: Record "No. Series";
        Location: Record Location;
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        PackageNoInformation: Record "Package No. Information";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Workflow: Record Workflow;
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] Block a package number when a quality inspection with failing result is finished

        Initialize();

        // [GIVEN] Quality management setup with package tracked item and warehouse entry generation rule
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        QltyInspectionUtility.CreatePackageTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [GIVEN] A purchase order received with package tracking and inspection created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionHeader);
        ToLoadQltyInspectionResult.Get(DefaultResult1FailCodeTok);

        // [GIVEN] A workflow configured to block package on inspection finished with failing result condition
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponseAndEventCondition(Workflow, QltyInspectionUtility.GetInspectionFinishedEvent(), QltyInspectionUtility.GetWorkflowResponseBlockPackage(), StrSubstNo(EventFilterTok, ToLoadQltyInspectionResult.Code), true);

        // [WHEN] The inspection result is set to failing result and inspection is finished
        QltyInspectionHeader.Validate("Result Code", ToLoadQltyInspectionResult.Code);
        QltyInspectionHeader.Modify();
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();

        // [THEN] The package number information is marked as blocked
        PackageNoInformation.Get(Item."No.", '', ReservationEntry."Package No.");
        LibraryAssert.IsTrue(PackageNoInformation.Blocked, 'Should be blocked.');

        QltyInspectionGenRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure UnblockPackage()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        ReservationEntry: Record "Reservation Entry";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        PackageNoInformation: Record "Package No. Information";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Workflow: Record Workflow;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] Unblock a package number when a quality inspection with passing result is finished

        Initialize();

        // [GIVEN] Quality management setup with package tracked item and blocked package number
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInspectionGenRule);
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        QltyInspectionUtility.CreatePackageTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [GIVEN] A purchase order received with package tracking and inspection created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyInspectionUtility.CreateInspectionWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionHeader);
        ToLoadQltyInspectionResult.Get(DefaultResult2PassCodeTok);
        if not PackageNoInformation.Get(Item."No.", '', ReservationEntry."Package No.") then
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInformation, Item."No.", ReservationEntry."Package No.");
        PackageNoInformation.Blocked := true;
        PackageNoInformation.Modify();
        LibraryAssert.IsTrue(PackageNoInformation.Blocked, 'Should be blocked.');

        // [GIVEN] A workflow configured to unblock package on inspection finished with passing result condition
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponseAndEventCondition(Workflow, QltyInspectionUtility.GetInspectionFinishedEvent(), QltyInspectionUtility.GetWorkflowResponseUnblockPackage(), StrSubstNo(EventFilterTok, ToLoadQltyInspectionResult.Code), true);

        // [WHEN] The inspection result is set to passing result and inspection is finished
        QltyInspectionHeader.Validate("Result Code", ToLoadQltyInspectionResult.Code);
        QltyInspectionHeader.Modify();
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();

        // [THEN] The package number information is marked as unblocked
        PackageNoInformation.Get(Item."No.", '', ReservationEntry."Package No.");
        LibraryAssert.IsFalse(PackageNoInformation.Blocked, 'Should not be blocked.');

        QltyInspectionGenRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure GetStepConfigurationValueAsQuantityBehaviorEnum_True()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
    begin
        // [SCENARIO] Retrieve quantity behavior enum value from workflow step configuration when value is 'true'

        Initialize();

        // [GIVEN] A workflow step argument with quantity configuration value set to 'true'
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyQuantity(), 'true');

        // [WHEN] The configuration value is retrieved as quantity behavior enum
        // [THEN] The value should be converted to Item Tracked Quantity enum
        LibraryAssert.AreEqual(QuantityBehavior::"Item Tracked Quantity", QltyInspectionUtility.GetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyQuantity()),
            'True should evaluate to tracked quantity');
    end;

    [Test]
    procedure GetStepConfigurationValueAsQuantityBehaviorEnum_False()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
    begin
        // [SCENARIO] Retrieve quantity behavior enum value from workflow step configuration when value is 'false'

        Initialize();

        // [GIVEN] A workflow step argument with quantity configuration value set to 'false'
        QltyInspectionUtility.SetStepConfigurationValue(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyQuantity(), 'false');

        // [WHEN] The configuration value is retrieved as quantity behavior enum
        // [THEN] The value should be converted to Specific Quantity enum
        LibraryAssert.AreEqual(QuantityBehavior::"Specific Quantity", QltyInspectionUtility.GetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownKeyQuantity()),
            'False should evaluate to specific quantity');
    end;

    [Test]
    procedure GetSetStepConfigurationValueAsAdjPostingEnum_EntryOnly()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        AdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
    begin
        // [SCENARIO] Set and retrieve adjustment posting behavior enum value as Prepare only

        Initialize();

        // [GIVEN] A workflow step argument is prepared
        // [WHEN] Adjustment posting behavior is set to Prepare only and then retrieved
        QltyInspectionUtility.SetStepConfigurationValueAsAdjPostingEnum(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownAdjPostingBehavior(), AdjPostBehavior::"Prepare only");

        // [THEN] The retrieved value should match the set value of Prepare only
        LibraryAssert.AreEqual(AdjPostBehavior::"Prepare only", QltyInspectionUtility.GetStepConfigurationValueAsAdjPostingEnum(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownAdjPostingBehavior()),
        'Should return "entry only"');
    end;

    [Test]
    procedure GetSetStepConfigurationValueAsAdjPostingEnum_Post()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        AdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
    begin
        // [SCENARIO] Set and retrieve adjustment posting behavior enum value as Post

        Initialize();

        // [GIVEN] A workflow step argument is prepared
        // [WHEN] Adjustment posting behavior is set to Post and then retrieved
        QltyInspectionUtility.SetStepConfigurationValueAsAdjPostingEnum(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownAdjPostingBehavior(), AdjPostBehavior::Post);

        // [THEN] The retrieved value should match the set value of Post
        LibraryAssert.AreEqual(AdjPostBehavior::Post, QltyInspectionUtility.GetStepConfigurationValueAsAdjPostingEnum(WorkflowStepArgument, QltyInspectionUtility.GetWellKnownAdjPostingBehavior()),
        'Should return "post"');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
    end;

    local procedure CreateWorkflowWithSingleResponse(var Workflow: Record Workflow; WorkflowEvent: Code[128]; WorkflowResponseName: Text; Enable: Boolean)
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowEventStepID: Integer;
    begin
        WorkflowEventHandling.CreateEventsLibrary();
        WorkflowResponseHandling.CreateResponsesLibrary();
        LibraryWorkflow.CreateWorkflow(Workflow);
        WorkflowEventStepID := LibraryWorkflow.InsertEventStep(Workflow, WorkflowEvent, 0);
        LibraryWorkflow.SetEventStepAsEntryPoint(Workflow, WorkflowEventStepID);
        LibraryWorkflow.InsertResponseStep(Workflow, CopyStr(WorkflowResponseName, 1, 128), WorkflowEventStepID);
        if Enable then
            LibraryWorkflow.EnableWorkflow(Workflow);
    end;

    local procedure CreateWorkflowWithSingleResponseAndEventCondition(var Workflow: Record Workflow; WorkflowEvent: Code[128]; WorkflowResponseName: Text; EventCondition: Text; Enable: Boolean)
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowEventStepID: Integer;
    begin
        WorkflowEventHandling.CreateEventsLibrary();
        WorkflowResponseHandling.CreateResponsesLibrary();
        LibraryWorkflow.CreateWorkflow(Workflow);
        WorkflowEventStepID := LibraryWorkflow.InsertEventStep(Workflow, WorkflowEvent, 0);
        LibraryWorkflow.InsertEventArgument(WorkflowEventStepID, EventCondition);
        LibraryWorkflow.SetEventStepAsEntryPoint(Workflow, WorkflowEventStepID);
        LibraryWorkflow.InsertResponseStep(Workflow, CopyStr(WorkflowResponseName, 1, 128), WorkflowEventStepID);
        if Enable then
            LibraryWorkflow.EnableWorkflow(Workflow);
    end;

    local procedure CreatePurchaseApprovalRequestWorkflowWithResponse(var Workflow: Record Workflow; WorkflowResponseName: Text; Enable: Boolean)
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowEventStepID: Integer;
    begin
        WorkflowEventHandling.CreateEventsLibrary();
        WorkflowResponseHandling.CreateResponsesLibrary();
        LibraryWorkflow.CreateWorkflow(Workflow);
        WorkflowEventStepID := LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(), 0);
        LibraryWorkflow.SetEventStepAsEntryPoint(Workflow, WorkflowEventStepID);
        WorkflowEventStepID := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.ApproveAllApprovalRequestsCode(), WorkflowEventStepID);
        LibraryWorkflow.InsertResponseStep(Workflow, CopyStr(WorkflowResponseName, 1, 128), WorkflowEventStepID);
        if Enable then
            LibraryWorkflow.EnableWorkflow(Workflow);
    end;

    local procedure CreateWorkflowResponseArgument(var Workflow: Record Workflow; WorkflowResponseFunction: Code[128]; var OutResponseWorkflowStep: Record "Workflow Step"; var OutWorkflowStepArgument: Record "Workflow Step Argument")
    begin
        OutWorkflowStepArgument.Init();
        OutWorkflowStepArgument."Response Function Name" := WorkflowResponseFunction;
        OutWorkflowStepArgument.Insert(true);
        OutResponseWorkflowStep.SetRange(Type, OutResponseWorkflowStep.Type::Response);
        OutResponseWorkflowStep.SetRange("Workflow Code", Workflow.Code);
        OutResponseWorkflowStep.FindFirst();
        OutResponseWorkflowStep.Argument := OutWorkflowStepArgument.ID;
        OutResponseWorkflowStep.Modify();
    end;

    /// <summary>
    /// Ensures that there are no conflicting workflows using the same event
    /// </summary>
    local procedure DeleteWorkflows()
    var
        Workflow: Record Workflow;
    begin
        Workflow.FindSet();
        repeat
            Workflow.Enabled := false;
            Workflow.Modify();
        until Workflow.Next() = 0;
        Workflow.DeleteAll();
    end;

    local procedure CreatePurHeaderToInspectionConfig()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        ConfigCode: Text;
    begin
        SpecificQltyInspectSourceConfig.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(SpecificQltyInspectSourceConfig.Code), ConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::"Purchase Header");
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::Inspection;
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Qlty. Inspection Header");
        SpecificQltyInspectSourceConfig.Insert();

        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := PurchaseHeader.FieldNo("No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Inspection;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionHeader.FieldNo("Source Document No.");
        SpecificQltyInspectSrcFldConf.Insert();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
