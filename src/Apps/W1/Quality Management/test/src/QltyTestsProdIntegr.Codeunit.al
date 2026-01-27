// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.Test.QualityManagement.TestLibraries;
using System.TestLibraries.Utilities;

codeunit 139966 "Qlty. Tests - Prod. Integr."
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        ReUsedProdOrderLine: Record "Prod. Order Line";
        LibraryAssert: Codeunit "Library Assert";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        GenQltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;
        Msg: Label 'Copy to Quality Inspection now and I intend on removing Quality Measures later (copy the min/max values).,Copy to Quality Inspection and keep the conditions synchronized to Business Central Quality Measures (make a reference to these values)';
        CreateQltyInspectionTemplateMsg: Label 'Create or Update a Quality Inspection Template from these quality measures.';

    [Test]
    procedure CreateInspectionOnAfterPostOutput_AnyOutput_Output()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Inspection is created when output journal is posted with AnyOutput configuration
        Initialize();

        // [GIVEN] Setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template with 3 tests is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);

        // [GIVEN] All existing generation rules are deleted and an output prioritized rule is created
        QltyInspectionGenRule.DeleteAll();
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and released production order with routing are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnAnyOutput
        QltyManagementSetup.Get();
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost;
        QltyInspectionGenRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnAnyOutput;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with 5 units of output quantity
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        BeforeCount := QltyInspectionHeader.Count();
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One inspection is created
        AfterCount := QltyInspectionHeader.Count();
        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One inspection should have been created.');

        // [THEN] Inspection uses the correct template, item, and source quantity of 5
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Inspection should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionHeader."Source Item No.", 'Inspection should be for the correct item.');
        LibraryAssert.AreEqual(5, QltyInspectionHeader."Source Quantity (Base)", 'The inspection source quantity (base) should match the quantity of the output.');
    end;

    [Test]
    procedure CreateInspectionOnAfterPostOutput_AnyOutput_Scrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Inspection is created when scrap journal is posted with AnyOutput configuration using prod line quantity
        Initialize();

        // [GIVEN] Setup exists and a template with 3 tests is created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and released production order with quantity 10 are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnAnyOutput
        QltyManagementSetup.Get();
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost;
        QltyInspectionGenRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnAnyOutput;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with scrap quantity of 5 and no output quantity
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 0);
        ItemJournalLine.Validate("Scrap Quantity", 5);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One inspection is created
        AfterCount := QltyInspectionHeader.Count();
        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One inspection should have been created.');

        // [THEN] Inspection uses correct template, item, and source quantity matches prod line quantity (10)
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Inspection should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionHeader."Source Item No.", 'Inspection should be for the correct item.');
        LibraryAssert.AreEqual(10, QltyInspectionHeader."Source Quantity (Base)", 'The inspection source quantity (base) should match the quantity of the production line.');
    end;

    [Test]
    procedure CreateInspectionOnAfterPostOutput_AnyOutput_NoOutputOrScrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] No inspection is created when output journal with no quantities fails to post with AnyOutput configuration
        Initialize();

        // [GIVEN] Setup exists and a template with 3 tests is created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnAnyOutput
        QltyManagementSetup.Get();
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost;
        QltyInspectionGenRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnAnyOutput;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with no output quantity and no scrap quantity
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 0);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] Attempting to post the output journal with no quantities
        BeforeCount := QltyInspectionHeader.Count();
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] No inspection is created
        AfterCount := QltyInspectionHeader.Count();
        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'No inspection should be created.');
    end;

    [Test]
    procedure CreateInspectionOnAfterPostOutput_AnyOutput_OutputAndScrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Inspection is created with output quantity when both output and scrap are posted with AnyOutput configuration
        Initialize();

        // [GIVEN] Setup exists and a template with 3 tests is created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnAnyOutput
        QltyManagementSetup.Get();
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost;
        QltyInspectionGenRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnAnyOutput;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with output quantity 5 and scrap quantity 3
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine.Validate("Scrap Quantity", 3);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One inspection is created
        AfterCount := QltyInspectionHeader.Count();
        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One inspection should have been created.');

        // [THEN] Inspection uses correct template, item, and source quantity matches output quantity (5, not scrap 3)
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Inspection should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionHeader."Source Item No.", 'Inspection should be for the correct item.');
        LibraryAssert.AreEqual(5, QltyInspectionHeader."Source Quantity (Base)", 'The inspection source quantity (base) should match the quantity of the output.');
    end;

    [Test]
    procedure CreateInspectionOnAfterPostOutput_AnyQuantity_Output()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Inspection is created when output journal is posted with AnyQuantity configuration
        Initialize();

        // [GIVEN] Setup exists and a template with 3 tests is created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnAnyQuantity
        QltyManagementSetup.Get();
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost;
        QltyInspectionGenRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnAnyQuantity;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with 5 units of output quantity
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One inspection is created
        AfterCount := QltyInspectionHeader.Count();
        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One inspection should have been created.');

        // [THEN] Inspection uses correct template, item, and source quantity of 5
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Inspection should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionHeader."Source Item No.", 'Inspection should be for the correct item.');
        LibraryAssert.AreEqual(5, QltyInspectionHeader."Source Quantity (Base)", 'The inspection source quantity (base) should match the quantity of the output.');
    end;

    [Test]
    procedure CreateInspectionOnAfterPostOutput_AnyQuantity_Scrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Inspection is created when scrap journal is posted with AnyQuantity configuration using prod line quantity
        Initialize();

        // [GIVEN] Setup exists and a template with 3 tests is created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and released production order with quantity 10 are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnAnyQuantity
        QltyManagementSetup.Get();
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost;
        QltyInspectionGenRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnAnyQuantity;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with scrap quantity of 5 and no output quantity
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 0);
        ItemJournalLine.Validate("Scrap Quantity", 5);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One inspection is created
        AfterCount := QltyInspectionHeader.Count();
        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One inspection should have been created.');

        // [THEN] Inspection uses correct template, item, and source quantity matches prod line quantity (10)
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Inspection should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionHeader."Source Item No.", 'Inspection should be for the correct item.');
        LibraryAssert.AreEqual(10, QltyInspectionHeader."Source Quantity (Base)", 'The inspection source quantity (base) should match the quantity of the production line.');
    end;

    [Test]
    procedure CreateInspectionOnAfterPostOutput_AnyQuantity_OutputAndScrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Inspection is created with total quantity (output + scrap) when both are posted with AnyQuantity configuration
        Initialize();

        // [GIVEN] Setup exists and a template with 3 tests is created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnAnyQuantity
        QltyManagementSetup.Get();
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost;
        QltyInspectionGenRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnAnyQuantity;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with output quantity 5 and scrap quantity 3
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine.Validate("Scrap Quantity", 3);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One inspection is created
        AfterCount := QltyInspectionHeader.Count();
        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One inspection should have been created.');

        // [THEN] Inspection uses correct template and source quantity matches output quantity (5)
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Inspection should use provided template.');
        LibraryAssert.AreEqual(5, QltyInspectionHeader."Source Quantity (Base)", 'The inspection source quantity (base) should match the quantity of the output.');
    end;

    [Test]
    procedure CreateInspectionOnAfterPostOutput_AnyQuantity_NoOutputOrScrap_NoInspection()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] No inspection is created when output journal with no quantities (output/scrap) fails to post with AnyQuantity configuration
        Initialize();

        // [GIVEN] Setup exists and a template with 3 tests is created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnAnyQuantity
        QltyManagementSetup.Get();
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost;
        QltyInspectionGenRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnAnyQuantity;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with no output quantity and no scrap quantity
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 0);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] Attempting to post the output journal with no quantities
        BeforeCount := QltyInspectionHeader.Count();
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] No inspection is created
        AfterCount := QltyInspectionHeader.Count();
        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'No inspection should be created.');
    end;

    [Test]
    procedure CreateInspectionOnAfterPostOutput_OnlyWithQuantity_Scrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] No inspection is created when only scrap is posted with OnlyWithQuantity configuration
        Initialize();

        // [GIVEN] Setup exists and a template with 3 tests is created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnlyWithQuantity
        QltyManagementSetup.Get();
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost;
        QltyInspectionGenRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnlyWithQuantity;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with only scrap quantity of 5
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 0);
        ItemJournalLine.Validate("Scrap Quantity", 5);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] No inspection is created (OnlyWithQuantity ignores scrap-only)
        AfterCount := QltyInspectionHeader.Count();
        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'No inspection should be created.');
    end;

    [Test]
    procedure CreateInspectionOnAfterPostOutput_OnlyWithQuantity_Output()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Inspection is created when output journal is posted with OnlyWithQuantity configuration
        Initialize();

        // [GIVEN] Setup exists and a template with 3 tests is created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnlyWithQuantity
        QltyManagementSetup.Get();
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost;
        QltyInspectionGenRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnlyWithQuantity;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with output quantity of 5
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One inspection is created
        AfterCount := QltyInspectionHeader.Count();
        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One inspection should have been created.');

        // [THEN] Inspection uses correct template, item, and source quantity of 5
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Inspection should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionHeader."Source Item No.", 'Inspection should be for the correct item.');
        LibraryAssert.AreEqual(5, QltyInspectionHeader."Source Quantity (Base)", 'The inspection source quantity (base) should match the output.');
    end;

    [Test]
    procedure CreateInspectionOnAfterPostOutput_OnlyWithQuantity_OutputAndScrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Inspection is created with output quantity when both output and scrap are posted with OnlyWithQuantity configuration
        Initialize();

        // [GIVEN] Setup exists and a template with 3 tests is created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnlyWithQuantity
        QltyManagementSetup.Get();
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost;
        QltyInspectionGenRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnlyWithQuantity;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with output quantity 5 and scrap quantity 3
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine.Validate("Scrap Quantity", 3);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One inspection is created
        AfterCount := QltyInspectionHeader.Count();
        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One inspection should have been created.');

        // [THEN] Inspection uses correct template, item, and source quantity matches output (5, not scrap)
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Inspection should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionHeader."Source Item No.", 'Inspection should be for the correct item.');
        LibraryAssert.AreEqual(5, QltyInspectionHeader."Source Quantity (Base)", 'The inspection source quantity (base) should match the output.');
    end;

    [Test]
    procedure CreateInspectionOnAfterPostOutput_OnlyWithQuantity_NoOutputOrScrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] No inspection is created when output journal with no quantities fails to post with OnlyWithQuantity configuration
        Initialize();

        // [GIVEN] Setup exists and a template with 3 tests is created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnlyWithQuantity
        QltyManagementSetup.Get();
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost;
        QltyInspectionGenRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnlyWithQuantity;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with no output quantity and no scrap quantity
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 0);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] Attempting to post the output journal with no quantities
        BeforeCount := QltyInspectionHeader.Count();
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] No inspection is created
        AfterCount := QltyInspectionHeader.Count();
        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'No inspection should be created.');
    end;

    [Test]
    procedure CreateInspectionOnAfterPostOutput_OnlyWithScrap_Output()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] No inspection is created when only output is posted with OnlyWithScrap configuration
        Initialize();

        // [GIVEN] Setup exists and a template with 3 tests is created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnlyWithScrap
        QltyManagementSetup.Get();
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost;
        QltyInspectionGenRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnlyWithScrap;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with only output quantity of 5
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] No inspection is created (OnlyWithScrap ignores output-only)
        AfterCount := QltyInspectionHeader.Count();
        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'No inspection should be created.');
    end;

    [Test]
    procedure CreateInspectionOnAfterPostOutput_OnlyWithScrap_Scrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Inspection is created when scrap journal is posted with OnlyWithScrap configuration using prod line quantity
        Initialize();

        // [GIVEN] Setup exists and a template with 3 tests is created
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and released production order with quantity 10 are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnlyWithScrap
        QltyManagementSetup.Get();
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost;
        QltyInspectionGenRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnlyWithScrap;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with scrap quantity of 5 and no output quantity
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 0);
        ItemJournalLine.Validate("Scrap Quantity", 5);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One inspection is created
        AfterCount := QltyInspectionHeader.Count();
        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One inspection should have been created.');

        // [THEN] Inspection uses correct template, item, and source quantity matches prod line quantity (10)
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Inspection should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionHeader."Source Item No.", 'Inspection should be for the correct item.');
        LibraryAssert.AreEqual(10, QltyInspectionHeader."Source Quantity (Base)", 'The inspection source quantity (base) should match the quantity of the production line.');
    end;

    [Test]
    procedure CreateInspectionOnAfterPostOutput_OnlyWithScrap_OutputAndScrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Inspection is created when output journal with both output and scrap is posted with OnlyWithScrap configuration using output quantity
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] A production order is created with quantity 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Quality management setup has Auto Output Configuration set to OnlyWithScrap
        QltyManagementSetup.Get();
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost;
        QltyInspectionGenRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnlyWithScrap;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with output quantity 5 and scrap quantity 3
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine.Validate("Scrap Quantity", 3);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The output journal is posted
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        AfterCount := QltyInspectionHeader.Count();

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One inspection is created
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One inspection should have been created.');

        // [THEN] Inspection uses correct template, item, and source quantity matches output quantity (5)
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Inspection should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionHeader."Source Item No.", 'Inspection should be for the correct item.');
        LibraryAssert.AreEqual(5, QltyInspectionHeader."Source Quantity (Base)", 'The inspection source quantity (base) should match the quantity of the output.');
    end;

    [Test]
    procedure CreateInspectionOnAfterPostOutput_OnlyWithScrap_NoOutputOrScrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] No inspection is created when output journal with no output or scrap quantity fails to post with OnlyWithScrap configuration
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] A production order is created with quantity 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Quality management setup has Auto Output Configuration set to OnlyWithScrap
        QltyManagementSetup.Get();
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost;
        QltyInspectionGenRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnlyWithScrap;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with no output quantity and no scrap quantity
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 0);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();
        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The output journal posting is attempted (and fails due to no quantities)
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        AfterCount := QltyInspectionHeader.Count();

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] No inspection is created
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'No inspection should be created.');
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusReleasedFormModalPageHandler,MessageHandler')]
    procedure CreateInspectionOnAfterRelease_ProdOrderRoutingLine()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ManufacturingSetup: Record "Manufacturing Setup";
        ToUseNoSeries: Record "No. Series";
        ToUseNoSeriesLine: Record "No. Series Line";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        ProdOrderStatus: Enum "Production Order Status";
    begin
        // [SCENARIO] Inspection is created when production order is released with routing lines available
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Line", QltyInspectionGenRule);

        // [GIVEN] An item is created and a firm planned production order is created and refreshed with routing lines
        GenQltyProdOrderGenerator.Init(100);
        GenQltyProdOrderGenerator.CreateItem(Item);
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProdProductionOrder, ProdOrderStatus::"Firm Planned", "Prod. Order Source Type"::Item, Item."No.", 1);
        LibraryManufacturing.RefreshProdOrder(ProdProductionOrder, false, false, true, true, true);
        Item.Get(ProdProductionOrder."Source No.");

        // [GIVEN] Production order line quantity is set to 10
        ProdOrderLine.Get(ProdOrderLine.Status::"Firm Planned", ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Manufacturing setup has Released Order Nos. configured
        ManufacturingSetup.Get();
        if ManufacturingSetup."Released Order Nos." = '' then begin
            LibraryUtility.CreateNoSeries(ToUseNoSeries, true, true, false);
            LibraryUtility.CreateNoSeriesLine(ToUseNoSeriesLine, ToUseNoSeries.Code, '', '');
            ManufacturingSetup."Released Order Nos." := ToUseNoSeries.Code;
            ManufacturingSetup.Modify();
        end;

        // [GIVEN] Inspection generation rule has Production Trigger set to OnProductionOrderRelease
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOrderRelease;
        QltyInspectionGenRule.Modify();

        // [WHEN] The production order status is changed to Released
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] One inspection is created for the item
        CreatedQltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        LibraryAssert.IsTrue(not CreatedQltyInspectionHeader.IsEmpty(), 'One inspection should be created and should match item.');
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusReleasedFormModalPageHandler,MessageHandler')]
    procedure CreateInspectionOnAfterRelease_ProdOrderLine()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ManufacturingSetup: Record "Manufacturing Setup";
        ToUseNoSeries: Record "No. Series";
        ToUseNoSeriesLine: Record "No. Series Line";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        ProdOrderStatus: Enum "Production Order Status";
    begin
        // [SCENARIO] Inspection is created when production order is released without routing lines
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Line", QltyInspectionGenRule);

        // [GIVEN] An item is created and a firm planned production order is created and refreshed
        GenQltyProdOrderGenerator.CreateItem(Item);
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProdProductionOrder, ProdOrderStatus::"Firm Planned", "Prod. Order Source Type"::Item, Item."No.", 1);
        LibraryManufacturing.RefreshProdOrder(ProdProductionOrder, false, false, true, true, true);
        Item.Get(ProdProductionOrder."Source No.");

        // [GIVEN] Production order line quantity is set to 10
        ProdOrderLine.Get(ProdOrderLine.Status::"Firm Planned", ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] All production order routing lines are deleted
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::"Firm Planned");
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdProductionOrder."No.");
        if ProdOrderRoutingLine.FindSet() then
            ProdOrderRoutingLine.DeleteAll();

        // [GIVEN] Manufacturing setup has Released Order Nos. configured
        ManufacturingSetup.Get();
        if ManufacturingSetup."Released Order Nos." = '' then begin
            LibraryUtility.CreateNoSeries(ToUseNoSeries, true, true, false);
            LibraryUtility.CreateNoSeriesLine(ToUseNoSeriesLine, ToUseNoSeries.Code, '', '');
            ManufacturingSetup."Released Order Nos." := ToUseNoSeries.Code;
            ManufacturingSetup.Modify();
        end;

        // [GIVEN] Inspection generation rule has Production Trigger set to OnProductionOrderRelease
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOrderRelease;
        QltyInspectionGenRule.Modify();

        // [WHEN] The production order status is changed to Released
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] One inspection is created for the item
        CreatedQltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        LibraryAssert.AreEqual(1, CreatedQltyInspectionHeader.Count(), 'Inspection should match item.');
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusReleasedFormModalPageHandler,MessageHandler')]
    procedure CreateInspectionOnAfterRelease_ProdOrderRoutingLine_TrackedItem()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ManufacturingSetup: Record "Manufacturing Setup";
        ToUseNoSeries: Record "No. Series";
        ToUseNoSeriesLine: Record "No. Series Line";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        ProdOrderStatus: Enum "Production Order Status";
    begin
        // [SCENARIO] Inspection is created when production order with lot-tracked item is released with routing lines available
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Line", QltyInspectionGenRule);

        // [GIVEN] A lot-tracked item and firm planned production order are created with routing lines
        GenQltyProdOrderGenerator.CreateLotTrackedItemAndProductionOrder(ProdOrderStatus::"Firm Planned", Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] Production order line quantity is set to 10
        // [GIVEN] Item tracking with lot number and quantity 10 is created for the production order line
        ProdOrderLine.Get(ProdOrderLine.Status::"Firm Planned", ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, '', Item."Lot Nos.", 10);

        // [GIVEN] Manufacturing setup has Released Order Nos. configured
        ManufacturingSetup.Get();
        if ManufacturingSetup."Released Order Nos." = '' then begin
            LibraryUtility.CreateNoSeries(ToUseNoSeries, true, true, false);
            LibraryUtility.CreateNoSeriesLine(ToUseNoSeriesLine, ToUseNoSeries.Code, '', '');
            ManufacturingSetup."Released Order Nos." := ToUseNoSeries.Code;
            ManufacturingSetup.Modify();
        end;

        // [GIVEN] Inspection generation rule has Production Trigger set to OnProductionOrderRelease
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOrderRelease;
        QltyInspectionGenRule.Modify();

        // [WHEN] The production order status is changed to Released
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] One inspection is created for the lot-tracked item
        CreatedQltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        LibraryAssert.IsTrue(not CreatedQltyInspectionHeader.IsEmpty(), 'One inspection should be created and match item.');
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusReleasedFormModalPageHandler,MessageHandler')]
    procedure CreateInspectionOnAfterRelease_ProdOrderLine_TrackedItem()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ManufacturingSetup: Record "Manufacturing Setup";
        ToUseNoSeries: Record "No. Series";
        ToUseNoSeriesLine: Record "No. Series Line";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        ProdOrderStatus: Enum "Production Order Status";
    begin
        // [SCENARIO] Inspection is created when production order with lot-tracked item is released without routing lines
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Line", QltyInspectionGenRule);

        // [GIVEN] A lot-tracked item and firm planned production order are created
        GenQltyProdOrderGenerator.CreateLotTrackedItemAndProductionOrder(ProdOrderStatus::"Firm Planned", Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] Production order line quantity is set to 10
        // [GIVEN] Item tracking with lot number and quantity 10 is created for the production order line
        ProdOrderLine.Get(ProdOrderLine.Status::"Firm Planned", ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, '', Item."Lot Nos.", 10);

        // [GIVEN] All production order routing lines are deleted
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::"Firm Planned");
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdProductionOrder."No.");
        if ProdOrderRoutingLine.FindSet() then
            ProdOrderRoutingLine.DeleteAll();

        // [GIVEN] Manufacturing setup has Released Order Nos. configured
        ManufacturingSetup.Get();
        if ManufacturingSetup."Released Order Nos." = '' then begin
            LibraryUtility.CreateNoSeries(ToUseNoSeries, true, true, false);
            LibraryUtility.CreateNoSeriesLine(ToUseNoSeriesLine, ToUseNoSeries.Code, '', '');
            ManufacturingSetup."Released Order Nos." := ToUseNoSeries.Code;
            ManufacturingSetup.Modify();
        end;

        // [GIVEN] Inspection generation rule has Production Trigger set to OnProductionOrderRelease
        QltyInspectionGenRule."Production Trigger" := QltyInspectionGenRule."Production Trigger"::OnProductionOrderRelease;
        QltyInspectionGenRule.Modify();

        // [WHEN] The production order status is changed to Released
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] One inspection is created for the lot-tracked item
        CreatedQltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        LibraryAssert.AreEqual(1, CreatedQltyInspectionHeader.Count(), 'One inspection should be created and should match item.');
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences1()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RecordRef: RecordRef;
        UnusedVariant: Variant;
        RecordId: Text;
        RecordIdSecond: Text;
        RecordIdThird: Text;
    begin
        // [SCENARIO] Inspection source record IDs are updated when production order status changes from Released to Finished with source order: ProdOrderLine, ProdOrderRoutingLine, ProdProductionOrder
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Line", QltyInspectionGenRule);

        // [GIVEN] An item and production order are created with routing line
        // [GIVEN] Production order line quantity is set to 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] A quality inspection is created with variants in order: ProdOrderLine, ProdOrderRoutingLine, ProdProductionOrder
        // [GIVEN] All three source record IDs have "Released" status
        RecordRef.GetTable(ProdOrderLine);
        QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(ProdOrderLine, ProdOrderRoutingLine, ProdProductionOrder, UnusedVariant, false, '');
        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
        RecordId := Format(QltyInspectionHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Released') > 0, 'The source record ID should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Released') > 0, 'The source record ID 2 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Released') > 0, 'The source record ID 3 should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] Inspection source record IDs are updated to have "Finished" status
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        RecordId := Format(QltyInspectionHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Finished') > 0, 'The source record ID should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Finished') > 0, 'The source record ID 2 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Finished') > 0, 'The source record ID 3 should have the "finished" status.');

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences2()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RecordRef: RecordRef;
        UnusedVariant: Variant;
        RecordId: Text;
        RecordIdSecond: Text;
        RecordIdThird: Text;
    begin
        // [SCENARIO] Inspection source record IDs are updated when production order status changes from Released to Finished with source order: ProdProductionOrder, ProdOrderLine, ProdOrderRoutingLine
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Line", QltyInspectionGenRule);

        // [GIVEN] An item and production order are created with routing line
        // [GIVEN] Production order line quantity is set to 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] A quality inspection is created with variants in order: ProdProductionOrder, ProdOrderLine, ProdOrderRoutingLine
        // [GIVEN] All three source record IDs have "Released" status
        RecordRef.GetTable(ProdOrderLine);
        QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(ProdProductionOrder, ProdOrderLine, ProdOrderRoutingLine, UnusedVariant, false, '');
        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
        RecordId := Format(QltyInspectionHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Released') > 0, 'The source record ID should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Released') > 0, 'The source record ID 2 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Released') > 0, 'The source record ID 3 should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] Inspection source record IDs are updated to have "Finished" status
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        RecordId := Format(QltyInspectionHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Finished') > 0, 'The source record ID should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Finished') > 0, 'The source record ID 2 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Finished') > 0, 'The source record ID 3 should have the "finished" status.');

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences3()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RecordRef: RecordRef;
        UnusedVariant: Variant;
        RecordId: Text;
        RecordIdSecond: Text;
        RecordIdThird: Text;
    begin
        // [SCENARIO] Inspection source record IDs are updated when production order status changes from Released to Finished with source order: ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Line", QltyInspectionGenRule);

        // [GIVEN] An item and production order are created with routing line
        // [GIVEN] Production order line quantity is set to 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] A quality inspection is created with variants in order: ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine
        // [GIVEN] All source record IDs have "Released" status (note: third ID is not checked due to variant ordering)
        RecordRef.GetTable(ProdOrderLine);
        QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine, UnusedVariant, false, '');
        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
        RecordId := Format(QltyInspectionHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Released') > 0, 'The source record ID should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Released') > 0, 'The source record ID 2 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Released') > 0, 'The source record ID 3 should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] Inspection source record IDs are updated to have "Finished" status
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        RecordId := Format(QltyInspectionHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Finished') > 0, 'The source record ID should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Finished') > 0, 'The source record ID 2 should have the "finished" status.');

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences4()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RecordRef: RecordRef;
        UnusedVariant: Variant;
        RecordId: Text;
        RecordIdSecond: Text;
        RecordIdThird: Text;
    begin
        // [SCENARIO] Inspection source record IDs are updated when production order status changes from Released to Finished with routing line-based inspection and source order: ProdOrderRoutingLine, ProdOrderLine, ProdProductionOrder
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);

        // [GIVEN] An item and production order are created with routing line
        // [GIVEN] Production order line quantity is set to 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] A quality inspection is created with variants in order: ProdOrderRoutingLine, ProdOrderLine, ProdProductionOrder
        // [GIVEN] All three source record IDs have "Released" status
        RecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(ProdOrderRoutingLine, ProdOrderLine, ProdProductionOrder, UnusedVariant, false, '');
        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
        RecordId := Format(QltyInspectionHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Released') > 0, 'The source record ID should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Released') > 0, 'The source record ID 2 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Released') > 0, 'The source record ID 3 should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] Inspection source record IDs are updated to have "Finished" status
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        RecordId := Format(QltyInspectionHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Finished') > 0, 'The source record ID should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Finished') > 0, 'The source record ID 2 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Finished') > 0, 'The source record ID 3 should have the "finished" status.');

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences5()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RecordRef: RecordRef;
        UnusedVariant: Variant;
        RecordId: Text;
        RecordIdSecond: Text;
        RecordIdThird: Text;
    begin
        // [SCENARIO] Inspection source record IDs are updated when production order status changes from Released to Finished with routing line-based inspection and source order: ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);

        // [GIVEN] An item and production order are created with routing line
        // [GIVEN] Production order line quantity is set to 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] A quality inspection is created with variants in order: ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine
        // [GIVEN] All three source record IDs have "Released" status
        RecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine, UnusedVariant, false, '');
        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
        RecordId := Format(QltyInspectionHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Released') > 0, 'The source record ID should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Released') > 0, 'The source record ID 2 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Released') > 0, 'The source record ID 3 should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] Inspection source record IDs are updated to have "Finished" status
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        RecordId := Format(QltyInspectionHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Finished') > 0, 'The source record ID should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Finished') > 0, 'The source record ID 2 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Finished') > 0, 'The source record ID 3 should have the "finished" status.');

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences6()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RecordRef: RecordRef;
        RecordIdSecond: Text;
        RecordIdThird: Text;
        RecordIdFourth: Text;
    begin
        // [SCENARIO] Inspection source record IDs are updated when production order status changes from Released to Finished with journal line-based inspection and source order: ItemJournalLine, ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and production order are created with routing line
        // [GIVEN] Production order line quantity is set to 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] An output journal is created with output quantity 5 and scrap quantity 3
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);

        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine.Validate("Scrap Quantity", 3);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [GIVEN] A quality inspection is created with variants in order: ItemJournalLine, ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine
        // [GIVEN] Source record IDs 2, 3, and 4 have "Released" status
        RecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(ItemJournalLine, ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine, false, '');
        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
        RecordIdSecond := Format(QltyInspectionHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionHeader."Source RecordId 3");
        RecordIdFourth := Format(QltyInspectionHeader."Source RecordId 4");

        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Released') > 0, 'The source record ID 2 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Released') > 0, 'The source record ID 3 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdFourth.IndexOf('Released') > 0, 'The source record ID 4 should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] Inspection source record IDs are updated to have "Finished" status
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        RecordIdSecond := Format(QltyInspectionHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionHeader."Source RecordId 3");
        RecordIdFourth := Format(QltyInspectionHeader."Source RecordId 4");

        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Finished') > 0, 'The source record ID 2 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Finished') > 0, 'The source record ID 3 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdFourth.IndexOf('Finished') > 0, 'The source record ID 4 should have the "finished" status.');

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences7()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RecordRef: RecordRef;
        RecordIdSecond: Text;
        RecordIdThird: Text;
        RecordIdFourth: Text;
    begin
        // [SCENARIO] Inspection source record IDs are updated when production order status changes from Released to Finished with journal line-based inspection and source order: ItemJournalLine, ProdOrderRoutingLine, ProdOrderLine, ProdProductionOrder
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and production order are created with routing line
        // [GIVEN] Production order line quantity is set to 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] An output journal is created with output quantity 5 and scrap quantity 3
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);

        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine.Validate("Scrap Quantity", 3);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [GIVEN] A quality inspection is created with variants in order: ItemJournalLine, ProdOrderRoutingLine, ProdOrderLine, ProdProductionOrder
        // [GIVEN] Source record IDs 2, 3, and 4 have "Released" status
        RecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(ItemJournalLine, ProdOrderRoutingLine, ProdOrderLine, ProdProductionOrder, false, '');
        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
        RecordIdSecond := Format(QltyInspectionHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionHeader."Source RecordId 3");
        RecordIdFourth := Format(QltyInspectionHeader."Source RecordId 4");

        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Released') > 0, 'The source record ID 2 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Released') > 0, 'The source record ID 3 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdFourth.IndexOf('Released') > 0, 'The source record ID 4 should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] Inspection source record IDs are updated to have "Finished" status
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        RecordIdSecond := Format(QltyInspectionHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionHeader."Source RecordId 3");
        RecordIdFourth := Format(QltyInspectionHeader."Source RecordId 4");

        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Finished') > 0, 'The source record ID 2 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Finished') > 0, 'The source record ID 3 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdFourth.IndexOf('Finished') > 0, 'The source record ID 4 should have the "finished" status.');

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences8()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RecordRef: RecordRef;
        RecordIdSecond: Text;
        RecordIdThird: Text;
        RecordIdFourth: Text;
    begin
        // [SCENARIO] Inspection source record IDs are updated when production order status changes from Released to Finished with journal line-based inspection and source order: ItemJournalLine, ProdOrderLine, ProdProductionOrder, ProdOrderRoutingLine
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInspectionGenRule);

        // [GIVEN] An item and production order are created with routing line
        // [GIVEN] Production order line quantity is set to 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] An output journal is created with output quantity 5 and scrap quantity 3
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);

        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine.Validate("Scrap Quantity", 3);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [GIVEN] A quality inspection is created with variants in order: ItemJournalLine, ProdOrderLine, ProdProductionOrder, ProdOrderRoutingLine
        // [GIVEN] Source record IDs 2, 3, and 4 have "Released" status
        RecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(ItemJournalLine, ProdOrderLine, ProdProductionOrder, ProdOrderRoutingLine, false, '');
        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
        RecordIdSecond := Format(QltyInspectionHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionHeader."Source RecordId 3");
        RecordIdFourth := Format(QltyInspectionHeader."Source RecordId 4");

        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Released') > 0, 'The source record ID 2 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Released') > 0, 'The source record ID 3 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdFourth.IndexOf('Released') > 0, 'The source record ID 4 should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] Inspection source record IDs are updated to have "Finished" status
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        RecordIdSecond := Format(QltyInspectionHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionHeader."Source RecordId 3");
        RecordIdFourth := Format(QltyInspectionHeader."Source RecordId 4");

        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Finished') > 0, 'The source record ID 2 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Finished') > 0, 'The source record ID 3 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdFourth.IndexOf('Finished') > 0, 'The source record ID 4 should have the "finished" status.');

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CreateInspectionOnAfterPost_Assembly_TrackedItem()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        AssemblyHeader: Record "Assembly Header";
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        ToUseNoSeries: Record "No. Series";
        ToUseNoSeriesLine: Record "No. Series Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        NoSeries: Codeunit "No. Series";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LotNo1: Code[50];
        LotNo2: Code[50];
        BeforeCount: Integer;
    begin
        // [SCENARIO] Two inspections are created when assembly order with lot-tracked item is posted with two lot numbers
        Initialize();

        // [GIVEN] A no. series is created for test setup
        LibraryUtility.CreateNoSeries(ToUseNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(ToUseNoSeriesLine, ToUseNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A0SM-A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A0SM-A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] An item journal template and batch are created for assembly
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.SetFilter(Name, 'A0SM-A*');
        ItemJournalTemplate.DeleteAll(false);
        ItemJournalTemplate.Init();
        ItemJournalTemplate.Validate(Name, CopyStr(NoSeries.GetNextNo(ToUseNoSeries.Code), 1, MaxStrLen(ItemJournalTemplate.Name)));

        ItemJournalTemplate.Validate(Description, ItemJournalTemplate.Name);
        ItemJournalTemplate.Insert(true);
        LibraryAssembly.SetupItemJournal(ItemJournalTemplate, ItemJournalBatch);

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);

        // [GIVEN] An inspection generation rule is created for Posted Assembly Header table
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Posted Assembly Header", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A lot-tracked assembly item is created with components
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, false);
        LibraryAssembly.SetupAssemblyItem(Item, Enum::"Costing Method"::Standard, Enum::"Costing Method"::Standard, Enum::"Replenishment System"::Assembly, Location.Code, false, 2, 1, 1, 1);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify();

        // [GIVEN] An assembly order is created with quantity 10 and two lot tracking entries (5 each)
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", Location.Code, 10, '');
        LotNo1 := NoSeries.GetNextNo(ToUseNoSeries.Code);
        LibraryItemTracking.CreateAssemblyHeaderItemTracking(ReservationEntry, AssemblyHeader, '', LotNo1, 5);
        LotNo2 := NoSeries.GetNextNo(ToUseNoSeries.Code);
        LibraryItemTracking.CreateAssemblyHeaderItemTracking(ReservationEntry, AssemblyHeader, '', LotNo2, 5);

        // [GIVEN] Component inventory is added for the assembly order
        ItemJournalBatch."No. Series" := ToUseNoSeries.Code;
        ItemJournalBatch.Modify();
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate(), 0);

        // [GIVEN] Inspection generation rule has Assembly Trigger set to OnAssemblyOutputPost
        QltyInspectionGenRule."Assembly Trigger" := QltyInspectionGenRule."Assembly Trigger"::OnAssemblyOutputPost;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The assembly order is posted
        EnsureGenPostingSetupForAssemblyExists(AssemblyHeader);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [THEN] Two inspections are created (one for each lot number)
        LibraryAssert.AreEqual((BeforeCount + 2), QltyInspectionHeader.Count(), 'Should be two new inspections.');

        // [THEN] Each inspection uses correct template, location, quantity (5), and lot number
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        if QltyInspectionHeader.FindSet() then
            repeat
                LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Should be same template.');
                LibraryAssert.AreEqual(Location.Code, QltyInspectionHeader."Location Code", 'Should be same location.');
                LibraryAssert.AreEqual(5, QltyInspectionHeader."Source Quantity (Base)", 'Should be same quantity.');
                LibraryAssert.IsTrue((QltyInspectionHeader."Source Lot No." = LotNo1) or (QltyInspectionHeader."Source Lot No." = LotNo2), 'Should be same lot no.');
            until QltyInspectionHeader.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CreateInspectionOnAfterPost_Assembly_UntrackedItem()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        AssemblyHeader: Record "Assembly Header";
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ToUseNoSeries: Record "No. Series";
        ToUseNoSeriesLine: Record "No. Series Line";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryUtility: Codeunit "Library - Utility";
        NoSeries: Codeunit "No. Series";
        BeforeCount: Integer;
    begin
        // [SCENARIO] One inspection is created when assembly order with untracked item is posted
        Initialize();

        // [GIVEN] A no. series is created for test setup
        LibraryUtility.CreateNoSeries(ToUseNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(ToUseNoSeriesLine, ToUseNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A0SM-A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A0SM-A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] An item journal template and batch are created for assembly
        ItemJournalTemplate.Reset();
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.SetFilter(Name, 'A0SM-A*');
        ItemJournalTemplate.DeleteAll(false);
        ItemJournalTemplate.Init();
        ItemJournalTemplate.Validate(Name, CopyStr(NoSeries.GetNextNo(ToUseNoSeries.Code), 1, MaxStrLen(ItemJournalTemplate.Name)));

        ItemJournalTemplate.Validate(Description, ItemJournalTemplate.Name);
        ItemJournalTemplate.Insert(true);
        LibraryAssembly.SetupItemJournal(ItemJournalTemplate, ItemJournalBatch);

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);

        // [GIVEN] An inspection generation rule is created for Posted Assembly Header table
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Posted Assembly Header", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An assembly order is created with 2 components and component inventory is added
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate(), Location.Code, 2);
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate(), 0);

        // [GIVEN] Inspection generation rule has Assembly Trigger set to OnAssemblyOutputPost
        QltyInspectionGenRule."Assembly Trigger" := QltyInspectionGenRule."Assembly Trigger"::OnAssemblyOutputPost;
        QltyInspectionGenRule.Modify();

        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The assembly order is posted
        EnsureGenPostingSetupForAssemblyExists(AssemblyHeader);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [THEN] One inspection is created
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionHeader.Count(), 'Should be one new inspection.');

        // [THEN] Inspection uses correct template, location, and quantity matches assembly order quantity
        QltyInspectionHeader.SetRange("Source Item No.", AssemblyHeader."Item No.");
        QltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionHeader."Template Code", 'Should be same template.');
        LibraryAssert.AreEqual(Location.Code, QltyInspectionHeader."Location Code", 'Should be same location.');
        LibraryAssert.AreEqual(AssemblyHeader."Quantity (Base)", QltyInspectionHeader."Source Quantity (Base)", 'Should be same quantity.');
    end;

    [Test]
    procedure CreateInspectionOnAfterRefreshProdOrder()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        BeforeCount: Integer;
        CountOfRoutingLines: Integer;
    begin
        // [SCENARIO] Quality inspections are created for all routing lines when production order is refreshed with OnReleasedProductionOrderRefresh trigger
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] An inspection generation rule is created for Prod. Order Routing Line with OnReleasedProductionOrderRefresh trigger
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);
        QltyInspectionGenRule.Validate("Production Trigger", QltyInspectionGenRule."Production Trigger"::OnReleasedProductionOrderRefresh);
        QltyInspectionGenRule.Modify(true);

        // [GIVEN] An item and production order are created with routing lines
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderRoutingLine.Reset();
        ProdOrderRoutingLine.SetRange(Status, ProdProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdProductionOrder."No.");
        CountOfRoutingLines := ProdOrderRoutingLine.Count();

        // [GIVEN] The current count of inspection headers is recorded
        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] The production order is refreshed
        ProdProductionOrder.SetRecFilter();
        Report.Run(Report::"Refresh Production Order", false, false, ProdProductionOrder);

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] Inspections are created for each routing line
        LibraryAssert.AreEqual(BeforeCount + CountOfRoutingLines, QltyInspectionHeader.Count(), 'Inspection(s) was not created.');
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences_ProdOrder_NoSourceConfig()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        RecordRef: RecordRef;
        RecordId: Text;
    begin
        // [SCENARIO] Inspection source record ID is updated when production order status changes with no source configuration and "Update when source changes" setting
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Production Order", QltyInspectionGenRule);

        // [GIVEN] An item and production order are created with routing line
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] A quality inspection is created for the production order with Released status
        RecordRef.GetTable(ProdProductionOrder);
        QltyInspectionCreate.CreateInspection(RecordRef, false);
        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
        RecordId := Format(QltyInspectionHeader."Source RecordId");

        LibraryAssert.IsTrue(RecordId.IndexOf('Released') > 0, 'The source record ID should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [GIVEN] All source configurations are deleted
        QltyInspectSourceConfig.DeleteAll();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] The inspection source record ID is updated to have "Finished" status
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        RecordId := Format(QltyInspectionHeader."Source RecordId");

        LibraryAssert.IsTrue(RecordId.IndexOf('Finished') > 0, 'The source record ID should have the "finished" status.');

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences_ProdOrderLine_NoSourceConfig()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        RecordRef: RecordRef;
        RecordId: Text;
    begin
        // [SCENARIO] Inspection source record ID is updated when production order status changes with no source configuration and "Update when source changes" setting for Prod. Order Line
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Line", QltyInspectionGenRule);

        // [GIVEN] An item and production order are created with routing line
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] A quality inspection is created for the production order line with Released status
        RecordRef.GetTable(ProdOrderLine);
        QltyInspectionCreate.CreateInspection(RecordRef, false);
        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
        RecordId := Format(QltyInspectionHeader."Source RecordId");

        LibraryAssert.IsTrue(RecordId.IndexOf('Released') > 0, 'The source record ID should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [GIVEN] All source configurations are deleted
        QltyInspectSourceConfig.DeleteAll();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] The inspection source record ID is updated to have "Finished" status
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        RecordId := Format(QltyInspectionHeader."Source RecordId");

        LibraryAssert.IsTrue(RecordId.IndexOf('Finished') > 0, 'The source record ID should have the "finished" status.');

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences_ProdOrderRoutingLine_NoSourceConfig()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        RecordRef: RecordRef;
        RecordId: Text;
    begin
        // [SCENARIO] Inspection source record ID is updated when production order status changes with no source configuration and "UpdateOnChange" setting for Prod. Order Routing Line
        Initialize();

        // [GIVEN] Quality management setup exists
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);

        // [GIVEN] An item and production order are created with routing line
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] A quality inspection is created for the production order routing line with Released status
        RecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionCreate.CreateInspection(RecordRef, false);
        QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
        RecordId := Format(QltyInspectionHeader."Source RecordId");

        LibraryAssert.IsTrue(RecordId.IndexOf('Released') > 0, 'The source record ID should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [GIVEN] All source configurations are deleted
        QltyInspectSourceConfig.DeleteAll();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] The inspection source record ID is updated to have "Finished" status
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        RecordId := Format(QltyInspectionHeader."Source RecordId");

        LibraryAssert.IsTrue(RecordId.IndexOf('Finished') > 0, 'The source record ID should have the "finished" status.');

        QltyInspectionGenRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
    end;

    local procedure CreateOutputPrioritizedRule(QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; var QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule")
    var
        FindLowestQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        FindLowestQltyInspectionGenRule.Reset();
        FindLowestQltyInspectionGenRule.SetCurrentKey("Sort Order");

        QltyInspectionGenRule.Init();
        if FindLowestQltyInspectionGenRule.FindFirst() then
            QltyInspectionGenRule."Sort Order" := FindLowestQltyInspectionGenRule."Sort Order" - 1;

        QltyInspectionGenRule."Template Code" := QltyInspectionTemplateHdr.Code;
        QltyInspectionGenRule."Source Table No." := Database::"Item Journal Line";
        QltyInspectionGenRule.Insert(true);
    end;

    local procedure EnsureGenPostingSetupForAssemblyExists(AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        GeneralPostingSetup: Record "General Posting Setup";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // Ensure that the general posting setup exists for the assembly lines for the given assembly header
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");

        if AssemblyLine.FindSet() then
            repeat
                if not GeneralPostingSetup.Get(AssemblyLine."Gen. Bus. Posting Group", AssemblyLine."Gen. Prod. Posting Group") then begin
                    LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, AssemblyLine."Gen. Bus. Posting Group", AssemblyLine."Gen. Prod. Posting Group");
                    GeneralPostingSetup.SuggestSetupAccounts();
                end;
            until AssemblyLine.Next() = 0;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerTrue(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerFalse(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    procedure MessageHandler(MessageText: Text)
    begin
    end;

    [ModalPageHandler]
    procedure ProdOrderRoutingModalPageHandler(var ProdOrderRouting: TestPage "Prod. Order Routing")
    var
        FirstProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SecondProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FirstProdOrderRoutingLine.SetRange(Status, ReUsedProdOrderLine.Status);
        FirstProdOrderRoutingLine.SetRange("Prod. Order No.", ReUsedProdOrderLine."Prod. Order No.");
        FirstProdOrderRoutingLine.FindFirst();
        SecondProdOrderRoutingLine.CopyFilters(FirstProdOrderRoutingLine);
        SecondProdOrderRoutingLine.SetRange("Operation No.", FirstProdOrderRoutingLine."Next Operation No.");
        SecondProdOrderRoutingLine.FindFirst();
        ProdOrderRouting.GoToRecord(SecondProdOrderRoutingLine);
        ProdOrderRouting."Routing Status".Value(Format(SecondProdOrderRoutingLine."Routing Status"::"In Progress"));
        ProdOrderRouting.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ProdOrderStatusReleasedFormModalPageHandler(var ChangeStatusOnProdOrder: TestPage "Change Status on Prod. Order")
    var
        ProdProductionOrder: Record "Production Order";
    begin
        ChangeStatusOnProdOrder.FirmPlannedStatus.Value := (Format(ProdProductionOrder.Status::Released));
        ChangeStatusOnProdOrder.Yes().Invoke();
    end;

    [ModalPageHandler]
    procedure ProdOrderStatusFinishedFormModalPageHandler(var ChangeStatusOnProdOrder: TestPage "Change Status on Prod. Order")
    var
        ProdProductionOrder: Record "Production Order";
    begin
        ChangeStatusOnProdOrder.FirmPlannedStatus.Value := (Format(ProdProductionOrder.Status::Finished));
        ChangeStatusOnProdOrder.Yes().Invoke();
    end;

    [StrMenuHandler]
    procedure CreateTemplateStrMenuHandler_True(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        LibraryAssert.AreEqual(Msg, Options, 'The instructions should match.');
        LibraryAssert.AreEqual(CreateQltyInspectionTemplateMsg, Instruction, 'The instructions should match.');
        Choice := 1;
    end;

    [StrMenuHandler]
    procedure CreateTemplateStrMenuHandler_False(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        LibraryAssert.AreEqual(Msg, Options, 'The instructions should match.');
        LibraryAssert.AreEqual(CreateQltyInspectionTemplateMsg, Instruction, 'The instructions should match.');
        Choice := 2;
    end;

    [ModalPageHandler]
    procedure AutomatedInspectionTemplateModalPageHandler(var QltyInspectionTemplate: TestPage "Qlty. Inspection Template")
    begin
    end;
}
