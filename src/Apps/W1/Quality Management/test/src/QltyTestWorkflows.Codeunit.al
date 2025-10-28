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
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Workflow;
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
using System.Reflection;
using System.Security.User;
using System.TestLibraries.Utilities;

codeunit 139969 "Qlty. Test Workflows"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = Uncategorized;

    var
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ReUsableQltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        ReUsableQltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryAssert: Codeunit "Library Assert";
        FilterTok: Label 'WHERE(No.=FILTER([Item:No.]))';
        ValueExprTok: Label 'Yes';
        NewLotTok: Label 'LOT123123';
        EventFilterTok: Label 'Where("Grade Code"=Filter(%1))', Comment = '%1=grade code.';
        DefaultGrade1FailCodeTok: Label 'FAIL', Locked = true;
        DefaultGrade2PassCodeTok: Label 'PASS', Locked = true;

    [Test]
    procedure PurchaseReturnWorkflow_OnTestFinished()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnReason: Record "Return Reason";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        ReturnPurchaseHeader: Record "Purchase Header";
        ReturnPurchaseLine: Record "Purchase Line";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
        MoveBehavior: Enum "Qlty. Quantity Behavior";
        CreditMemo: Text;
        Reason: Text;
    begin
        // [SCENARIO] Automatically create a purchase return order when a quality inspection test is finished

        // [GIVEN] A warehouse location and quality management setup with inspection template and generation rule
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A purchase order with inspection test created and received
        QltyItemTracking.ClearTrackingCache();
        ReUsableQltyPurOrderGenerator.CreateTestFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionTestHeader);
        PurchaseLine.Get(PurchaseLine."Document Type"::Order, QltyInspectionTestHeader."Source Document No.", QltyInspectionTestHeader."Source Document Line No.");
        ReUsableQltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] A return reason code and credit memo number are defined
        ReUsableQltyTestsUtility.GenerateRandomCharacters(35, CreditMemo);
        ReUsableQltyTestsUtility.GenerateRandomCharacters(10, Reason);
        ReturnReason.Init();
        ReturnReason.Code := CopyStr(Reason, 1, MaxStrLen(ReturnReason.Code));
        ReturnReason.Insert();

        // [GIVEN] A workflow is configured to create purchase return on test finished event
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponse(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestFinishedEvent(), QltyWorkflowSetup.GetWorkflowResponseCreatePurchaseReturn(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyWorkflowSetup.GetWorkflowResponseCreatePurchaseReturn(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyWorkflowResponse.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownMoveAll(), MoveBehavior::"Specific Quantity");
        QltyWorkflowResponse.SetStepConfigurationValueAsDecimal(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyQuantity(), PurchaseLine."Quantity (Base)");
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownExternalDocNo(), CreditMemo);
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownReasonCode(), Reason);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] The inspection test status is changed to finished
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Finished);
        QltyInspectionTestHeader.Modify();

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
        QltyInTestGenerationRule.Delete();
    end;

    [Test]
    procedure ClearTestStatusFilter_OnTestFinished()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        OriginalQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        ToLoadField: Record Field;
        Workflow: Record Workflow;
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        TestSourceConfigLineFieldNames: List of [Text];
        FieldName: Text;
        SourceConfig: Text;
        BeforeCount: Integer;
    begin
        // [SCENARIO] Test-to-test source configuration is applied from a create test workflow when source test was filtered by status

        // [GIVEN] A warehouse location and quality management setup with inspection template
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A purchase order with lot tracked item and inspection test created
        ReUsableQltyPurOrderGenerator.CreateTestFromPurchaseWithLotTrackedItem(Location, 100, PurchaseHeader, PurchaseLine, OriginalQltyInspectionTestHeader, ReservationEntry);

        // [GIVEN] A test-to-test source configuration with field mappings
        ReUsableQltyTestsUtility.GenerateRandomCharacters(20, SourceConfig);
        SpecificQltyInspectSourceConfig.Init();
        SpecificQltyInspectSourceConfig.Code := CopyStr(SourceConfig, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(SourceConfig, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::"Qlty. Inspection Test Header");
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Qlty. Inspection Test Header");
        SpecificQltyInspectSourceConfig.Insert();

        TestSourceConfigLineFieldNames.Add('Source Document No.');
        TestSourceConfigLineFieldNames.Add('Source Document Line No.');
        TestSourceConfigLineFieldNames.Add('Source Item No.');
        TestSourceConfigLineFieldNames.Add('Source Quantity (Base)');
        TestSourceConfigLineFieldNames.Add('Source Lot No.');

        foreach FieldName in TestSourceConfigLineFieldNames do begin
            Clear(SpecificQltyInspectSrcFldConf);
            SpecificQltyInspectSrcFldConf.Init();
            SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
            SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
            SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
            SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
            SpecificQltyInspectSrcFldConf."To Table No." := SpecificQltyInspectSourceConfig."To Table No.";
            Clear(ToLoadField);
            ToLoadField.SetRange(TableNo, Database::"Qlty. Inspection Test Header");
            ToLoadField.SetRange(FieldName, FieldName);
            ToLoadField.FindFirst();
            SpecificQltyInspectSrcFldConf."From Field No." := ToLoadField."No.";
            SpecificQltyInspectSrcFldConf."To Field No." := ToLoadField."No.";
            SpecificQltyInspectSrcFldConf.Insert();
        end;

        // [GIVEN] A workflow configured to create new test from existing test
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Qlty. Inspection Test Header");

        QltyManagementSetup.Get();
        QltyManagementSetup."Create Test Behavior" := QltyManagementSetup."Create Test Behavior"::"Always create new test";
        QltyManagementSetup.Modify();

        CreateWorkflowWithSingleResponse(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestFinishedEvent(), QltyWorkflowSetup.GetWorkflowResponseCreateTest(), true);
        BeforeCount := QltyInspectionTestHeader.Count();
        OriginalQltyInspectionTestHeader.SetRange(Status, OriginalQltyInspectionTestHeader.Status::Open);

        // [WHEN] The original test status is changed to finished
        OriginalQltyInspectionTestHeader.Validate(Status, OriginalQltyInspectionTestHeader.Status::Finished);
        OriginalQltyInspectionTestHeader.Modify();

        // [THEN] A new test is created with source configuration fields applied from the original test
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one new test created.');
        CreatedQltyInspectionTestHeader.SetRange("Source Document No.", OriginalQltyInspectionTestHeader."Source Document No.");
        CreatedQltyInspectionTestHeader.SetRange("Source Document Line No.", OriginalQltyInspectionTestHeader."Source Document Line No.");
        LibraryAssert.AreEqual(2, CreatedQltyInspectionTestHeader.Count(), 'Should be two tests for the source document.');
        CreatedQltyInspectionTestHeader.FindLast();
        LibraryAssert.AreNotEqual(OriginalQltyInspectionTestHeader."No.", CreatedQltyInspectionTestHeader."No.", 'Should be a new test created.');
        LibraryAssert.AreEqual(OriginalQltyInspectionTestHeader."Source Item No.", CreatedQltyInspectionTestHeader."Source Item No.", 'Should have applied source config fields. (Item No.)');
        LibraryAssert.AreEqual(OriginalQltyInspectionTestHeader."Source Quantity (Base)", CreatedQltyInspectionTestHeader."Source Quantity (Base)", 'Should have applied source config fields. (Source Quantity (Base))');
        LibraryAssert.AreEqual(OriginalQltyInspectionTestHeader."Source Lot No.", CreatedQltyInspectionTestHeader."Source Lot No.", 'Should have applied source config fields. (Source Lot No.)');

        DeleteWorkflows();
        QltyInTestGenerationRule.Delete();
    end;

    [Test]
    procedure CreateInternalPutaway_OnTestReopened()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        ToUseNoSeries: Record "No. Series";
        ToUseNoSeriesLine: Record "No. Series Line";
        WarehouseSetup: Record "Warehouse Setup";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
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
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
        MoveBehavior: Enum "Qlty. Quantity Behavior";
        PutawayCount: Integer;
    begin
        // [SCENARIO] Create an internal warehouse put-away when a quality inspection test is reopened

        // [GIVEN] A full warehouse management location with quality setup
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInTestGenerationRule);

        // [GIVEN] An item, warehouse employee, and number series for internal put-aways
        LibraryInventory.CreateItem(Item);

        ReUsableQltyTestsUtility.SetCurrLocationWhseEmployee(Location.Code);

        WarehouseSetup.Get();
        if WarehouseSetup."Whse. Internal Put-away Nos." = '' then begin
            LibraryUtility.CreateNoSeries(ToUseNoSeries, true, true, false);
            LibraryUtility.CreateNoSeriesLine(ToUseNoSeriesLine, ToUseNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
            WarehouseSetup."Whse. Internal Put-away Nos." := ToUseNoSeries.Code;
            WarehouseSetup.Modify();
        end;

        // [GIVEN] A purchase order received with quality inspection test created from warehouse entry
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        ReUsableQltyTestsUtility.CreateTestWithWarehouseEntry(WarehouseEntry, QltyInspectionTestHeader);

        // [GIVEN] A workflow configured to create internal put-away on test reopened event
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponse(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestReopensEvent(), QltyWorkflowSetup.GetWorkflowResponseInternalPutAway(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyWorkflowSetup.GetWorkflowResponseInternalPutAway(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyWorkflowResponse.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownMoveAll(), MoveBehavior::"Specific Quantity");
        QltyWorkflowResponse.SetStepConfigurationValueAsDecimal(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyQuantity(), PurchaseLine."Quantity (Base)");
        QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownCreatePutAway(), true);
        Workflow.Enabled := true;
        Workflow.Modify();

        PutawayWarehouseActivityHeader.SetRange(Type, PutawayWarehouseActivityHeader.Type::"Put-away");
        PutawayCount := PutawayWarehouseActivityHeader.Count();

        // [WHEN] The test is finished and then reopened
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Finished);
        QltyInspectionTestHeader.Modify();
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Open);
        QltyInspectionTestHeader.Modify();

        // [THEN] A warehouse put-away is created with correct item and quantity
        LibraryAssert.AreEqual(PutawayCount + 1, PutawayWarehouseActivityHeader.Count(), 'Should have created a warehouse put-away.');
        PutawayWarehouseActivityLine.SetRange("Activity Type", PutawayWarehouseActivityLine."Activity Type"::"Put-away");
        PutawayWarehouseActivityLine.SetRange("Location Code", Location.Code);
        PutawayWarehouseActivityLine.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTestHeader."Source Item No.", PutawayWarehouseActivityLine."Item No.", 'Should be correct item.');
        LibraryAssert.AreEqual(QltyInspectionTestHeader."Source Quantity (Base)", PutawayWarehouseActivityLine.Quantity, 'Should have specific quantity.');

        DeleteWorkflows();
        QltyInTestGenerationRule.Delete();
    end;

    [Test]
    procedure CreateNegativeAdjustment_OnTestFinished()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
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
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        MoveBehavior: Enum "Qlty. Quantity Behavior";
        AdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
        ReasonCodeToTest: Text;
    begin
        // [SCENARIO] Create and post a negative inventory adjustment when a quality inspection test is finished

        // [GIVEN] Quality management setup with inspection template and generation rule
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A warehouse location with bins and a lot tracked item
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        ReUsableQltyTestsUtility.CreateLotTrackedItemWithNoSeries(Item);

        // [GIVEN] A purchase order received with quality inspection test created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        ReUsableQltyTestsUtility.CreateTestWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionTestHeader);

        // [GIVEN] A reason code and item journal batch for adjustments
        ReUsableQltyTestsUtility.GenerateRandomCharacters(20, ReasonCodeToTest);
        ReasonCode.Init();
        ReasonCode.Validate(Code, CopyStr(ReasonCodeToTest, 1, MaxStrLen(ReasonCode.Code)));
        ReasonCode.Description := CopyStr(ReasonCodeToTest, 1, MaxStrLen(ReasonCode.Description));
        ReasonCode.Insert();

        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        QltyManagementSetup.Get();
        QltyManagementSetup."Adjustment Batch Name" := ItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A workflow configured to create and post inventory adjustment on test finished
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponse(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestFinishedEvent(), QltyWorkflowSetup.GetWorkflowResponseInventoryAdjustment(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyWorkflowSetup.GetWorkflowResponseInventoryAdjustment(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyWorkflowResponse.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownMoveAll(), MoveBehavior::"Specific Quantity");
        QltyWorkflowResponse.SetStepConfigurationValueAsDecimal(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyQuantity(), 50);
        QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownPostImmediately(), true);
        QltyWorkflowResponse.SetStepConfigurationValueAsAdjPostingEnum(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownAdjPostingBehavior(), AdjPostBehavior::Post);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] The inspection test status is changed to finished
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Finished);
        QltyInspectionTestHeader.Modify();

        // [THEN] A negative adjustment item ledger entry is posted with correct quantity
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
        ItemLedgerEntry.SetRange(Quantity, -50);
        LibraryAssert.AreEqual(1, ItemLedgerEntry.Count(), 'Should have posted one negative adjustment.');

        DeleteWorkflows();
        QltyInTestGenerationRule.Delete();
    end;

    [Test]
    procedure CreateTransfer_OnTestChange()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        DestinationLocation: Record Location;
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        Bin: Record Bin;
        Item: Record Item;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        MoveBehavior: Enum "Qlty. Quantity Behavior";
    begin
        // [SCENARIO] Create a transfer order for failed quantity when a quality inspection test grade changes

        // [GIVEN] Quality management setup with inspection template and locations
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A source location with bins and a destination location
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        LibraryWarehouse.CreateLocationWMS(DestinationLocation, false, false, false, false, false);

        // [GIVEN] A purchase order received with inspection test created
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        ReUsableQltyTestsUtility.CreateTestWithPurchaseLine(PurchaseLine, ConfigurationToLoadQltyInspectionTemplateHdr.Code, QltyInspectionTestHeader);

        // [GIVEN] A workflow configured to create transfer for failed quantity on test change
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponse(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestHasChangedEvent(), QltyWorkflowSetup.GetWorkflowResponseCreateTransfer(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyWorkflowSetup.GetWorkflowResponseCreateTransfer(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyWorkflowResponse.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownMoveAll(), MoveBehavior::"Failed Quantity");
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyLocation(), DestinationLocation.Code);
        QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownDirectTransfer(), true);
        Workflow.Enabled := true;
        Workflow.Modify();

        ToLoadQltyInspectionGrade.SetRange("Grade Category", ToLoadQltyInspectionGrade."Grade Category"::"Not acceptable");
        QltyInspectionTestHeader."Fail Quantity" := 2;
        QltyInspectionTestHeader.Modify();

        // [WHEN] The test grade is set to a failing grade
        QltyInspectionTestHeader.Validate("Grade Code", ToLoadQltyInspectionGrade.Code);
        QltyInspectionTestHeader.Modify(true);

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
        LibraryAssert.AreEqual(QltyInspectionTestHeader."Fail Quantity", TransferLine.Quantity, 'Should have requested quantity.');
        LibraryAssert.AreEqual(Bin.Code, TransferLine."Transfer-from Bin Code", 'Should have transfer-from bin code.');

        QltyInTestGenerationRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure ChangeDatabaseValue_OnTestFinish()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        WarehouseEntry: Record "Warehouse Entry";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
    begin
        // [SCENARIO] Update a database field value when a quality inspection test is finished

        // [GIVEN] A full warehouse management location with quality setup
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInTestGenerationRule);

        // [GIVEN] A purchase order received with inspection test created from warehouse entry
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        QltyTestsUtility.CreateTestWithWarehouseEntry(WarehouseEntry, QltyInspectionTestHeader);

        // [GIVEN] A workflow configured to set database value (blocking purchasing) on test finished
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponse(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestFinishedEvent(), QltyWorkflowSetup.GetWorkflowResponseSetDatabaseValue(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyWorkflowSetup.GetWorkflowResponseSetDatabaseValue(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyDatabaseTable(), Item.TableCaption());
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyDatabaseTableFilter(), FilterTok);
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyField(), Item.FieldCaption("Purchasing Blocked"));
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyValueExpression(), ValueExprTok);
        Workflow.Enabled := true;
        Workflow.Modify();

        LibraryAssert.IsFalse(Item."Purchasing Blocked", 'Item purchasing not be blocked.');

        // [WHEN] The inspection test status is changed to finished
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Finished);
        QltyInspectionTestHeader.Modify();

        // [THEN] The item purchasing blocked field is set to true
        Item.Get(Item."No.");
        LibraryAssert.IsTrue(Item."Purchasing Blocked", 'Item purchasing should be blocked.');

        DeleteWorkflows();
        QltyInTestGenerationRule.Delete();
    end;

    [Test]
    procedure Move_DPP_UseWorksheet_Pass_EntriesOnly_OnTestFinish()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
        WhseWorksheetTemplateToUseToUse: Text;
    begin
        // [SCENARIO] Move passed quantity using warehouse worksheet for directed put-away and pick location when test is finished

        // [GIVEN] Quality management setup with warehouse entry generation rule
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInTestGenerationRule);

        // [GIVEN] A full warehouse management location and warehouse worksheet setup
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        if not WhseWorksheetLine.IsEmpty() then
            WhseWorksheetLine.DeleteAll();
        if not WhseWorksheetName.IsEmpty() then
            WhseWorksheetName.DeleteAll();
        if not WhseWorksheetTemplate.IsEmpty() then
            WhseWorksheetTemplate.DeleteAll();

        WhseWorksheetTemplate.Init();
        ReUsableQltyTestsUtility.GenerateRandomCharacters(10, WhseWorksheetTemplateToUseToUse);
        WhseWorksheetTemplate.Name := CopyStr(WhseWorksheetTemplateToUseToUse, 1, MaxStrLen(WhseWorksheetTemplate.Name));
        WhseWorksheetTemplate.Type := WhseWorksheetTemplate.Type::Movement;
        WhseWorksheetTemplate."Page ID" := Page::"Movement Worksheet";
        WhseWorksheetTemplate.Insert();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);
        QltyManagementSetup.Get();
        QltyManagementSetup."Whse. Wksh. Name" := WhseWorksheetName.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A purchase order received with inspection test from warehouse entry
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        ReUsableQltyTestsUtility.CreateTestWithWarehouseEntry(WarehouseEntry, QltyInspectionTestHeader);

        QltyInspectionTestHeader."Pass Quantity" := 10;
        QltyInspectionTestHeader.Modify();

        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        // [GIVEN] A workflow configured to move passed quantity using worksheet on test finished
        CreateWorkflowWithSingleResponse(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestFinishedEvent(), QltyWorkflowSetup.GetWorkflowResponseMoveInventory(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyWorkflowSetup.GetWorkflowResponseMoveInventory(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownUseMoveSheet(), true);
        QltyWorkflowResponse.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownMoveAll(), QuantityBehavior::"Passed Quantity");
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyLocation(), Location.Code);
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyBin(), Bin.Code);
        QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownPostImmediately(), false);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] The inspection test status is changed to finished
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Finished);
        QltyInspectionTestHeader.Modify();

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
        LibraryAssert.AreEqual(QltyInspectionTestHeader."Pass Quantity", WhseWorksheetLine.Quantity, 'Should have correct requested quantity.');

        WhseWorksheetLine.Delete();
        WhseWorksheetName.Delete();
        WhseWorksheetTemplate.Delete();
        QltyInTestGenerationRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure Move_DPP_Reclass_Sample_OnTestFinish()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ReclassWhseItemWarehouseJournalTemplate: Record "Warehouse Journal Template";
        ReclassWarehouseJournalBatch: Record "Warehouse Journal Batch";
        ReclassWarehouseJournalLine: Record "Warehouse Journal Line";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
    begin
        // [SCENARIO] Move sample quantity using warehouse reclassification journal for directed put-away and pick location when test is finished

        // [GIVEN] Quality management setup with warehouse reclassification batch configured
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInTestGenerationRule);

        // [GIVEN] A full warehouse management location
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        QltyManagementSetup.Get();
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Bin Whse. Move Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A purchase order received with inspection test from warehouse entry
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        ReUsableQltyTestsUtility.CreateTestWithWarehouseEntry(WarehouseEntry, QltyInspectionTestHeader);

        QltyInspectionTestHeader."Sample Size" := 10;
        QltyInspectionTestHeader.Modify();

        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        Bin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        Bin.FindFirst();

        // [GIVEN] A workflow configured to move sample quantity using reclassification journal on test finished
        CreateWorkflowWithSingleResponse(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestFinishedEvent(), QltyWorkflowSetup.GetWorkflowResponseMoveInventory(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyWorkflowSetup.GetWorkflowResponseMoveInventory(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownUseMoveSheet(), false);
        QltyWorkflowResponse.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownMoveAll(), QuantityBehavior::"Sample Quantity");
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyLocation(), Location.Code);
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyBin(), Bin.Code);
        QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownPostImmediately(), false);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] The inspection test status is changed to finished
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Finished);
        QltyInspectionTestHeader.Modify();

        // [THEN] A warehouse reclassification journal line is created with correct bins and sample quantity
        ReclassWarehouseJournalLine.SetRange("Journal Template Name", ReclassWhseItemWarehouseJournalTemplate.Name);
        ReclassWarehouseJournalLine.SetRange("Journal Batch Name", ReclassWarehouseJournalBatch.Name);
        ReclassWarehouseJournalLine.SetRange("Item No.", Item."No.");
        ReclassWarehouseJournalLine.FindFirst();

        LibraryAssert.AreEqual(WarehouseEntry."Zone Code", ReclassWarehouseJournalLine."From Zone Code", 'Should have matching from zone code.');
        LibraryAssert.AreEqual(WarehouseEntry."Bin Code", ReclassWarehouseJournalLine."From Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin."Zone Code", ReclassWarehouseJournalLine."To Zone Code", 'Should have correct requested to zone code.');
        LibraryAssert.AreEqual(Bin.Code, ReclassWarehouseJournalLine."To Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(QltyInspectionTestHeader."Sample Size", ReclassWarehouseJournalLine.Quantity, 'Should have correct requested quantity.');

        ReclassWarehouseJournalLine.Delete();
        ReclassWarehouseJournalBatch.Delete();
        ReclassWhseItemWarehouseJournalTemplate.Delete();
        QltyInTestGenerationRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure Move_NonDPP_UseWorksheet_Fail_OnTestFinish()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        InventorySetup: Record "Inventory Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        Location: Record Location;
        ToUseNoSeries: Record "No. Series";
        ToUseNoSeriesLine: Record "No. Series Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        InternalMovementLine: Record "Internal Movement Line";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
    begin
        // [SCENARIO] Move failed quantity using internal movement worksheet for non-directed put-away location when test is finished

        // [GIVEN] Quality management setup with purchase line generation rule
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A location with bins and internal movement number series
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        ReUsableQltyTestsUtility.SetCurrLocationWhseEmployee(Location.Code);

        LibraryUtility.CreateNoSeries(ToUseNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(ToUseNoSeriesLine, ToUseNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        InventorySetup.Get();
        InventorySetup."Internal Movement Nos." := ToUseNoSeries.Code;
        InventorySetup.Modify();

        // [GIVEN] A purchase order received with inspection test created
        LibraryInventory.CreateItem(Item);

        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        ReUsableQltyTestsUtility.CreateTestWithPurchaseLine(PurchaseLine, ConfigurationToLoadQltyInspectionTemplateHdr.Code, QltyInspectionTestHeader);

        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1', PurchaseLine."Bin Code");
        Bin.FindFirst();

        QltyInspectionTestHeader."Fail Quantity" := 3;
        QltyInspectionTestHeader.Modify();

        // [GIVEN] A workflow configured to move failed quantity using internal movement on test finished
        CreateWorkflowWithSingleResponse(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestFinishedEvent(), QltyWorkflowSetup.GetWorkflowResponseMoveInventory(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyWorkflowSetup.GetWorkflowResponseMoveInventory(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownUseMoveSheet(), true);
        QltyWorkflowResponse.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownMoveAll(), QuantityBehavior::"Failed Quantity");
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyLocation(), Location.Code);
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyBin(), Bin.Code);
        QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownPostImmediately(), false);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] The inspection test status is changed to finished
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Finished);
        QltyInspectionTestHeader.Modify();

        // [THEN] An internal movement line is created with correct bins and failed quantity
        InternalMovementLine.SetRange("Location Code", Location.Code);
        InternalMovementLine.SetRange("Item No.", Item."No.");
        InternalMovementLine.FindFirst();

        LibraryAssert.AreEqual(PurchaseLine."Bin Code", InternalMovementLine."From Bin Code", 'Should have matching from bin code.');
        LibraryAssert.AreEqual(Bin.Code, InternalMovementLine."To Bin Code", 'Should have correct requested to bin code');
        LibraryAssert.AreEqual(QltyInspectionTestHeader."Fail Quantity", InternalMovementLine.Quantity, 'Should have correct requested quantity.');

        QltyInTestGenerationRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure Move_NonDPP_Reclass_Tracked_Filtered_OnTestFinish()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
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
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
        InitialChangeBin: Code[20];
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
    begin
        // [SCENARIO] Move item tracked quantity using reclassification journal with bin filters for non-directed put-away location when test is finished

        // [GIVEN] Quality management setup with item journal batch configured for bin moves
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);
        QltyManagementSetup.Get();
        LibraryInventory.CreateItemJournalTemplateByType(ReclassItemJournalTemplate, ReclassItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ReclassItemJournalBatch, ReclassItemJournalTemplate.Name);
        QltyManagementSetup."Bin Move Batch Name" := ReclassItemJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A location with bins and a lot tracked item
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);
        ReUsableQltyTestsUtility.CreateLotTrackedItemWithNoSeries(Item);

        // [GIVEN] A purchase order received with lot tracking and inspection test created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        PurchaseLine.Validate("Bin Code", Bin.Code);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        ReUsableQltyTestsUtility.CreateTestWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionTestHeader);

        // [GIVEN] A reclassification journal is posted to move 50 units to an intermediate bin
        ReUsableQltyTestsUtility.SetCurrLocationWhseEmployee(Location.Code);
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

        // [GIVEN] A workflow configured to move tracked quantity with source bin filter on test finished
        CreateWorkflowWithSingleResponse(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestFinishedEvent(), QltyWorkflowSetup.GetWorkflowResponseMoveInventory(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyWorkflowSetup.GetWorkflowResponseMoveInventory(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownUseMoveSheet(), false);
        QltyWorkflowResponse.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownMoveAll(), QuantityBehavior::"Item Tracked Quantity");
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyLocation(), Location.Code);
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyBin(), Bin.Code);
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownSourceLocationFilter(), Location.Code);
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownSourceBinFilter(), InitialChangeBin);
        QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownPostImmediately(), true);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] The inspection test status is changed to finished
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Finished);
        QltyInspectionTestHeader.Modify();

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
        QltyInTestGenerationRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure ChangeTracking_LotAndExp_OnTestFinished()
    var
        Location: Record Location;
        Item: Record Item;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        WarehouseEntry: Record "Warehouse Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
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
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
    begin
        // [SCENARIO] Change item tracking lot number and expiration date using warehouse reclassification journal when test is finished

        // [GIVEN] Quality management setup with lot tracked item using expiration dates
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInTestGenerationRule);
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);
        LotItemTrackingCode."Use Expiration Dates" := true;
        LotItemTrackingCode.Modify();
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);

        // [GIVEN] A full warehouse management location with warehouse reclassification batch
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        ReUsableQltyTestsUtility.SetCurrLocationWhseEmployee(Location.Code);
        QltyManagementSetup.Get();
        LibraryWarehouse.CreateWhseJournalTemplate(ReclassWhseItemWarehouseJournalTemplate, ReclassWhseItemWarehouseJournalTemplate.Type::Reclassification);
        LibraryWarehouse.CreateWhseJournalBatch(ReclassWarehouseJournalBatch, ReclassWhseItemWarehouseJournalTemplate.Name, Location.Code);
        QltyManagementSetup."Bin Whse. Move Batch Name" := ReclassWarehouseJournalBatch.Name;
        QltyManagementSetup.Modify();

        // [GIVEN] A purchase order received with inspection test created from warehouse entry
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        ReUsableQltyTestsUtility.CreateTestWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionTestHeader);

        // [GIVEN] A workflow configured to change item tracking (lot and expiration date) on test finished
        CreateWorkflowWithSingleResponse(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestFinishedEvent(), QltyWorkflowSetup.GetWorkflowResponseChangeItemTracking(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyWorkflowSetup.GetWorkflowResponseChangeItemTracking(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        QltyWorkflowResponse.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownMoveAll(), QuantityBehavior::"Item Tracked Quantity");
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownNewLotNo(), NewLotTok);
        QltyWorkflowResponse.SetStepConfigurationValueAsDate(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownNewExpDate(), WorkDate());
        QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownPostImmediately(), false);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] The inspection test status is changed to finished
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Finished);
        QltyInspectionTestHeader.Modify();

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
        QltyInTestGenerationRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CreateRetest()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Item: Record Item;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Workflow: Record Workflow;
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        CreatedTests: Integer;
    begin
        // [SCENARIO] Automatically create a retest when a quality inspection test is finished

        // [GIVEN] Quality management setup with warehouse entry generation rule
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInTestGenerationRule);

        // [GIVEN] A full warehouse management location and purchase order received with inspection test
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
        ReUsableQltyTestsUtility.CreateTestWithWarehouseEntry(WarehouseEntry, QltyInspectionTestHeader);

        // [GIVEN] A workflow configured to create retest on test finished event
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponse(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestFinishedEvent(), QltyWorkflowSetup.GetWorkflowResponseCreateRetest(), false);
        CreateWorkflowResponseArgument(Workflow, CopyStr(QltyWorkflowSetup.GetWorkflowResponseCreateRetest(), 1, 128), ResponseWorkflowStep, WorkflowStepArgument);
        Workflow.Enabled := true;
        Workflow.Modify();
        CreatedTests := CreatedQltyInspectionTestHeader.Count();

        // [WHEN] The inspection test status is changed to finished
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Finished);
        QltyInspectionTestHeader.Modify();

        // [THEN] A new retest is created with same test number but incremented retest number
        LibraryAssert.AreEqual(CreatedTests + 1, CreatedQltyInspectionTestHeader.Count(), 'Should be one more test created.');
        CreatedQltyInspectionTestHeader.SetRange("No.", QltyInspectionTestHeader."No.");
        LibraryAssert.AreEqual(2, CreatedQltyInspectionTestHeader.Count(), 'Should be 2 tests (one original and one retest)');

        QltyInTestGenerationRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure FinishTest()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Item: Record Item;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Workflow: Record Workflow;
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        LibraryInventory: Codeunit "Library - Inventory";
        ApprovalLibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Automatically finish a quality inspection test when a purchase approval workflow is completed

        // [GIVEN] Quality management setup with purchase header source configuration and generation rule
        ReUsableQltyTestsUtility.EnsureSetup();
        CreatePurHeaderToTestConfig();
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Header", QltyInTestGenerationRule);

        // [GIVEN] A purchase order with inspection test created
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        RecordRef.GetTable(PurchaseHeader);
        QltyInspectionTestCreate.CreateTest(RecordRef, true);
        QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);

        // [GIVEN] A purchase approval workflow configured to finish test after approval
        QltyManagementSetup.Get();
        CreatePurchaseApprovalRequestWorkflowWithResponse(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetWorkflowResponseFinishTest(), true);
        UserSetup.LockTable();
        if UserSetup.Get(UserId()) then
            UserSetup.Delete(false);
        ApprovalLibraryDocumentApprovals.SetupUserWithApprover(UserSetup);

        // [WHEN] The purchase order approval is sent and automatically approved
        if ApprovalsMgmt.CheckPurchaseApprovalPossible(PurchaseHeader) then
            ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // [THEN] The inspection test status is automatically set to finished
        QltyInspectionTestHeader.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.");
        LibraryAssert.IsTrue(QltyInspectionTestHeader.Status = QltyInspectionTestHeader.Status::Finished, 'Test status should be finished.');

        QltyInTestGenerationRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ReopenTest()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Item: Record Item;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Workflow: Record Workflow;
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        LibraryInventory: Codeunit "Library - Inventory";
        ApprovalLibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Automatically reopen a finished quality inspection test when a purchase approval workflow is completed

        // [GIVEN] Quality management setup with purchase header source configuration and generation rule
        ReUsableQltyTestsUtility.EnsureSetup();
        CreatePurHeaderToTestConfig();
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Header", QltyInTestGenerationRule);

        // [GIVEN] A purchase order with inspection test created and finished
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);
        RecordRef.GetTable(PurchaseHeader);
        QltyInspectionTestCreate.CreateTest(RecordRef, true);
        QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
        QltyInspectionTestHeader.FinishTest();

        // [GIVEN] A purchase approval workflow configured to reopen test after approval
        QltyManagementSetup.Get();
        CreatePurchaseApprovalRequestWorkflowWithResponse(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetWorkflowResponseReopenTest(), true);
        UserSetup.LockTable();
        if UserSetup.Get(UserId()) then
            UserSetup.Delete(false);
        ApprovalLibraryDocumentApprovals.SetupUserWithApprover(UserSetup);

        // [WHEN] The purchase order approval is sent and automatically approved
        if ApprovalsMgmt.CheckPurchaseApprovalPossible(PurchaseHeader) then
            ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // [THEN] The inspection test status is automatically set to open
        QltyInspectionTestHeader.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.");
        LibraryAssert.IsTrue(QltyInspectionTestHeader.Status = QltyInspectionTestHeader.Status::Open, 'Test status should be open.');

        QltyInTestGenerationRule.Delete();
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
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        LotNoInformation: Record "Lot No. Information";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Workflow: Record Workflow;
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] Block a lot number when a quality inspection test with failing grade is finished

        // [GIVEN] Quality management setup with lot tracked item and warehouse entry generation rule
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInTestGenerationRule);
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        ReUsableQltyTestsUtility.CreateLotTrackedItemWithNoSeries(Item);

        // [GIVEN] A purchase order received with lot tracking and inspection test created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        ReUsableQltyTestsUtility.CreateTestWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionTestHeader);

        // [GIVEN] A workflow configured to block lot on test finished with failing grade condition
        ToLoadQltyInspectionGrade.Get(DefaultGrade1FailCodeTok);
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponseAndEventCondition(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestFinishedEvent(), QltyWorkflowSetup.GetWorkflowResponseBlockLot(), StrSubstNo(EventFilterTok, ToLoadQltyInspectionGrade.Code), true);

        // [WHEN] The test grade is set to failing grade and test is finished
        QltyInspectionTestHeader.Validate("Grade Code", ToLoadQltyInspectionGrade.Code);
        QltyInspectionTestHeader.Modify();
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Finished);
        QltyInspectionTestHeader.Modify();

        // [THEN] The lot number information is marked as blocked
        LotNoInformation.Get(Item."No.", '', ReservationEntry."Lot No.");
        LibraryAssert.IsTrue(LotNoInformation.Blocked, 'Should be blocked.');

        QltyInTestGenerationRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure UnBlockLot()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        LotNoInformation: Record "Lot No. Information";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Workflow: Record Workflow;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] Unblock a lot number when a quality inspection test with passing grade is finished

        // [GIVEN] Quality management setup with lot tracked item and blocked lot number
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInTestGenerationRule);
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        ReUsableQltyTestsUtility.CreateLotTrackedItemWithNoSeries(Item);

        // [GIVEN] A purchase order received with lot tracking and inspection test created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        ReUsableQltyTestsUtility.CreateTestWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionTestHeader);
        ToLoadQltyInspectionGrade.Get(DefaultGrade2PassCodeTok);
        LibraryItemTracking.CreateLotNoInformation(LotNoInformation, Item."No.", '', ReservationEntry."Lot No.");
        LotNoInformation.Blocked := true;
        LotNoInformation.Modify();
        LibraryAssert.IsTrue(LotNoInformation.Blocked, 'Should be blocked.');

        // [GIVEN] A workflow configured to unblock lot on test finished with passing grade condition
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponseAndEventCondition(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestFinishedEvent(), QltyWorkflowSetup.GetWorkflowResponseUnBlockLot(), StrSubstNo(EventFilterTok, ToLoadQltyInspectionGrade.Code), true);

        // [WHEN] The test grade is set to passing grade and test is finished
        QltyInspectionTestHeader.Validate("Grade Code", ToLoadQltyInspectionGrade.Code);
        QltyInspectionTestHeader.Modify();
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Finished);
        QltyInspectionTestHeader.Modify();

        // [THEN] The lot number information is marked as unblocked
        LotNoInformation.Get(Item."No.", '', ReservationEntry."Lot No.");
        LibraryAssert.IsFalse(LotNoInformation.Blocked, 'Should not be blocked.');

        QltyInTestGenerationRule.Delete();
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
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        SerialNoInformation: Record "Serial No. Information";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Workflow: Record Workflow;
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] Block a serial number when a quality inspection test with failing grade is finished

        // [GIVEN] Quality management setup with serial tracked item and warehouse entry generation rule
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInTestGenerationRule);
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        ReUsableQltyTestsUtility.CreateSerialTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [GIVEN] A purchase order received with serial tracking and inspection test created
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        ReUsableQltyTestsUtility.CreateTestWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionTestHeader);
        ToLoadQltyInspectionGrade.Get(DefaultGrade1FailCodeTok);

        // [GIVEN] A workflow configured to block serial on test finished with failing grade condition
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponseAndEventCondition(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestFinishedEvent(), QltyWorkflowSetup.GetWorkflowResponseBlockSerial(), StrSubstNo(EventFilterTok, ToLoadQltyInspectionGrade.Code), true);

        // [WHEN] The test grade is set to failing grade and test is finished
        QltyInspectionTestHeader.Validate("Grade Code", ToLoadQltyInspectionGrade.Code);
        QltyInspectionTestHeader.Modify();
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Finished);
        QltyInspectionTestHeader.Modify();

        // [THEN] The serial number information is marked as blocked
        SerialNoInformation.Get(Item."No.", '', ReservationEntry."Serial No.");
        LibraryAssert.IsTrue(SerialNoInformation.Blocked, 'Should be blocked.');

        QltyInTestGenerationRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure UnBlockSerial()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        ReservationEntry: Record "Reservation Entry";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        SerialNoInformation: Record "Serial No. Information";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Workflow: Record Workflow;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] Unblock a serial number when a quality inspection test with passing grade is finished

        // [GIVEN] Quality management setup with serial tracked item and blocked serial number
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInTestGenerationRule);
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        ReUsableQltyTestsUtility.CreateSerialTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [GIVEN] A purchase order received with serial tracking and inspection test created
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        ReUsableQltyTestsUtility.CreateTestWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionTestHeader);
        ToLoadQltyInspectionGrade.Get(DefaultGrade2PassCodeTok);
        LibraryItemTracking.CreateSerialNoInformation(SerialNoInformation, Item."No.", '', ReservationEntry."Serial No.");
        SerialNoInformation.Blocked := true;
        SerialNoInformation.Modify();
        LibraryAssert.IsTrue(SerialNoInformation.Blocked, 'Should be blocked.');

        // [GIVEN] A workflow configured to unblock serial on test finished with passing grade condition
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponseAndEventCondition(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestFinishedEvent(), QltyWorkflowSetup.GetWorkflowResponseUnBlockSerial(), StrSubstNo(EventFilterTok, ToLoadQltyInspectionGrade.Code), true);

        // [WHEN] The test grade is set to passing grade and test is finished
        QltyInspectionTestHeader.Validate("Grade Code", ToLoadQltyInspectionGrade.Code);
        QltyInspectionTestHeader.Modify();
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Finished);
        QltyInspectionTestHeader.Modify();

        // [THEN] The serial number information is marked as unblocked
        SerialNoInformation.Get(Item."No.", '', ReservationEntry."Serial No.");
        LibraryAssert.IsFalse(SerialNoInformation.Blocked, 'Should not be blocked.');

        QltyInTestGenerationRule.Delete();
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
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        PackageNoInformation: Record "Package No. Information";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Workflow: Record Workflow;
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] Block a package number when a quality inspection test with failing grade is finished

        // [GIVEN] Quality management setup with package tracked item and warehouse entry generation rule
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInTestGenerationRule);
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        ReUsableQltyTestsUtility.CreatePackageTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [GIVEN] A purchase order received with package tracking and inspection test created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        ReUsableQltyTestsUtility.CreateTestWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionTestHeader);
        ToLoadQltyInspectionGrade.Get(DefaultGrade1FailCodeTok);

        // [GIVEN] A workflow configured to block package on test finished with failing grade condition
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponseAndEventCondition(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestFinishedEvent(), QltyWorkflowSetup.GetWorkflowResponseBlockPackage(), StrSubstNo(EventFilterTok, ToLoadQltyInspectionGrade.Code), true);

        // [WHEN] The test grade is set to failing grade and test is finished
        QltyInspectionTestHeader.Validate("Grade Code", ToLoadQltyInspectionGrade.Code);
        QltyInspectionTestHeader.Modify();
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Finished);
        QltyInspectionTestHeader.Modify();

        // [THEN] The package number information is marked as blocked
        PackageNoInformation.Get(Item."No.", '', ReservationEntry."Package No.");
        LibraryAssert.IsTrue(PackageNoInformation.Blocked, 'Should be blocked.');

        QltyInTestGenerationRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure UnBlockPackage()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        ReservationEntry: Record "Reservation Entry";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        PackageNoInformation: Record "Package No. Information";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        Workflow: Record Workflow;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        // [SCENARIO] Unblock a package number when a quality inspection test with passing grade is finished

        // [GIVEN] Quality management setup with package tracked item and blocked package number
        ReUsableQltyTestsUtility.EnsureSetup();
        ReUsableQltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Entry", QltyInTestGenerationRule);
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        ReUsableQltyTestsUtility.CreatePackageTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [GIVEN] A purchase order received with package tracking and inspection test created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();
        ReUsableQltyTestsUtility.CreateTestWithWarehouseEntryAndTracking(WarehouseEntry, ReservationEntry, QltyInspectionTestHeader);
        ToLoadQltyInspectionGrade.Get(DefaultGrade2PassCodeTok);
        if not PackageNoInformation.Get(Item."No.", '', ReservationEntry."Package No.") then
            LibraryItemTracking.CreatePackageNoInformation(PackageNoInformation, Item."No.", ReservationEntry."Package No.");
        PackageNoInformation.Blocked := true;
        PackageNoInformation.Modify();
        LibraryAssert.IsTrue(PackageNoInformation.Blocked, 'Should be blocked.');

        // [GIVEN] A workflow configured to unblock package on test finished with passing grade condition
        QltyManagementSetup.Get();
        CreateWorkflowWithSingleResponseAndEventCondition(QltyManagementSetup, Workflow, QltyWorkflowSetup.GetTestFinishedEvent(), QltyWorkflowSetup.GetWorkflowResponseUnBlockPackage(), StrSubstNo(EventFilterTok, ToLoadQltyInspectionGrade.Code), true);

        // [WHEN] The test grade is set to passing grade and test is finished
        QltyInspectionTestHeader.Validate("Grade Code", ToLoadQltyInspectionGrade.Code);
        QltyInspectionTestHeader.Modify();
        QltyInspectionTestHeader.Validate(Status, QltyInspectionTestHeader.Status::Finished);
        QltyInspectionTestHeader.Modify();

        // [THEN] The package number information is marked as unblocked
        PackageNoInformation.Get(Item."No.", '', ReservationEntry."Package No.");
        LibraryAssert.IsFalse(PackageNoInformation.Blocked, 'Should not be blocked.');

        QltyInTestGenerationRule.Delete();
        DeleteWorkflows();
    end;

    [Test]
    procedure GetStepConfigurationValueAsQuantityBehaviorEnum_True()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
    begin
        // [SCENARIO] Retrieve quantity behavior enum value from workflow step configuration when value is 'true'

        // [GIVEN] A workflow step argument with quantity configuration value set to 'true'
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyQuantity(), 'true');

        // [WHEN] The configuration value is retrieved as quantity behavior enum
        // [THEN] The value should be converted to Item Tracked Quantity enum
        LibraryAssert.AreEqual(QuantityBehavior::"Item Tracked Quantity", QltyWorkflowResponse.GetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyQuantity()),
            'True should evaluate to tracked quantity');
    end;

    [Test]
    procedure GetStepConfigurationValueAsQuantityBehaviorEnum_False()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
    begin
        // [SCENARIO] Retrieve quantity behavior enum value from workflow step configuration when value is 'false'

        // [GIVEN] A workflow step argument with quantity configuration value set to 'false'
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyQuantity(), 'false');

        // [WHEN] The configuration value is retrieved as quantity behavior enum
        // [THEN] The value should be converted to Specific Quantity enum
        LibraryAssert.AreEqual(QuantityBehavior::"Specific Quantity", QltyWorkflowResponse.GetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownKeyQuantity()),
            'False should evaluate to specific quantity');
    end;

    [Test]
    procedure GetSetStepConfigurationValueAsAdjPostingEnum_EntryOnly()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
        AdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
    begin
        // [SCENARIO] Set and retrieve adjustment posting behavior enum value as Prepare only

        // [GIVEN] A workflow step argument is prepared
        // [WHEN] Adjustment posting behavior is set to Prepare only and then retrieved
        QltyWorkflowResponse.SetStepConfigurationValueAsAdjPostingEnum(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownAdjPostingBehavior(), AdjPostBehavior::"Prepare only");

        // [THEN] The retrieved value should match the set value of Prepare only
        LibraryAssert.AreEqual(AdjPostBehavior::"Prepare only", QltyWorkflowResponse.GetStepConfigurationValueAsAdjPostingEnum(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownAdjPostingBehavior()),
        'Should return "entry only"');
    end;

    [Test]
    procedure GetSetStepConfigurationValueAsAdjPostingEnum_Post()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
        AdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
    begin
        // [SCENARIO] Set and retrieve adjustment posting behavior enum value as Post

        // [GIVEN] A workflow step argument is prepared
        // [WHEN] Adjustment posting behavior is set to Post and then retrieved
        QltyWorkflowResponse.SetStepConfigurationValueAsAdjPostingEnum(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownAdjPostingBehavior(), AdjPostBehavior::Post);

        // [THEN] The retrieved value should match the set value of Post
        LibraryAssert.AreEqual(AdjPostBehavior::Post, QltyWorkflowResponse.GetStepConfigurationValueAsAdjPostingEnum(WorkflowStepArgument, QltyWorkflowResponse.GetWellKnownAdjPostingBehavior()),
        'Should return "post"');
    end;

    local procedure CreateWorkflowWithSingleResponse(var QltyManagementSetup: Record "Qlty. Management Setup"; var Workflow: Record Workflow; WorkflowEvent: Code[128]; WorkflowResponseName: Text; Enable: Boolean)
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowEventStepID: Integer;
    begin
        QltyManagementSetup.Get();
        QltyManagementSetup."Workflow Integration Enabled" := true;
        QltyManagementSetup.Modify();

        WorkflowEventHandling.CreateEventsLibrary();
        WorkflowResponseHandling.CreateResponsesLibrary();
        LibraryWorkflow.CreateWorkflow(Workflow);
        WorkflowEventStepID := LibraryWorkflow.InsertEventStep(Workflow, WorkflowEvent, 0);
        LibraryWorkflow.SetEventStepAsEntryPoint(Workflow, WorkflowEventStepID);
        LibraryWorkflow.InsertResponseStep(Workflow, CopyStr(WorkflowResponseName, 1, 128), WorkflowEventStepID);
        if Enable then
            LibraryWorkflow.EnableWorkflow(Workflow);
    end;

    local procedure CreateWorkflowWithSingleResponseAndEventCondition(var QltyManagementSetup: Record "Qlty. Management Setup"; var Workflow: Record Workflow; WorkflowEvent: Code[128]; WorkflowResponseName: Text; EventCondition: Text; Enable: Boolean)
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowEventStepID: Integer;
    begin
        QltyManagementSetup.Get();
        QltyManagementSetup."Workflow Integration Enabled" := true;
        QltyManagementSetup.Modify();

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

    local procedure CreatePurchaseApprovalRequestWorkflowWithResponse(var QltyManagementSetup: Record "Qlty. Management Setup"; var Workflow: Record Workflow; WorkflowResponseName: Text; Enable: Boolean)
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowEventStepID: Integer;
    begin
        QltyManagementSetup.Get();
        QltyManagementSetup."Workflow Integration Enabled" := true;
        QltyManagementSetup.Modify();

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

    local procedure CreatePurHeaderToTestConfig()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        PurchaseHeader: Record "Purchase Header";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        ConfigCode: Text;
    begin
        SpecificQltyInspectSourceConfig.Init();
        ReUsableQltyTestsUtility.GenerateRandomCharacters(MaxStrLen(SpecificQltyInspectSourceConfig.Code), ConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::"Purchase Header");
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::Test;
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Qlty. Inspection Test Header");
        SpecificQltyInspectSourceConfig.Insert();

        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := PurchaseHeader.FieldNo("No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Document No.");
        SpecificQltyInspectSrcFldConf.Insert();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
