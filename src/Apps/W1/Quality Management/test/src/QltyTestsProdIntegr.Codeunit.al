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
using Microsoft.QualityManagement.Setup.Setup;
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
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        GenQltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        LibraryInventory: Codeunit "Library - Inventory";
        Msg: Label 'Copy to Quality Inspection now and I intend on removing Quality Measures later (copy the min/max values).,Copy to Quality Inspection and keep the conditions synchronized to Business Central Quality Measures (make a reference to these values)';
        CreateQltyInspectionTemplateMsg: Label 'Create or Update a Quality Inspection Template from these quality measures.';

    [Test]
    procedure CreateTestOnAfterPostOutput_AnyOutput_Output()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Test is created when output journal is posted with AnyOutput configuration

        // [GIVEN] Setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A template with 3 fields is created
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);

        // [GIVEN] All existing generation rules are deleted and an output prioritized rule is created
        QltyInTestGenerationRule.DeleteAll();
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and released production order with routing are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnAnyOutput
        QltyManagementSetup.Get();
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOutputPost;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnAnyOutput;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with 5 units of output quantity
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        BeforeCount := QltyInspectionTestHeader.Count();
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One test is created
        AfterCount := QltyInspectionTestHeader.Count();
        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionTestHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One test should have been created.');

        // [THEN] Test uses the correct template, item, and source quantity of 5
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Test should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionTestHeader."Source Item No.", 'Test should be for the correct item.');
        LibraryAssert.AreEqual(5, QltyInspectionTestHeader."Source Quantity (Base)", 'The test source quantity (base) should match the quantity of the output.');
    end;

    [Test]
    procedure CreateTestOnAfterPostOutput_AnyOutput_Scrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Test is created when scrap journal is posted with AnyOutput configuration using prod line quantity

        // [GIVEN] Setup exists and a template with 3 fields is created
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and released production order with quantity 10 are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnAnyOutput
        QltyManagementSetup.Get();
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOutputPost;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnAnyOutput;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with scrap quantity of 5 and no output quantity
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 0);
        ItemJournalLine.Validate("Scrap Quantity", 5);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionTestHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One test is created
        AfterCount := QltyInspectionTestHeader.Count();
        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionTestHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One test should have been created.');

        // [THEN] Test uses correct template, item, and source quantity matches prod line quantity (10)
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Test should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionTestHeader."Source Item No.", 'Test should be for the correct item.');
        LibraryAssert.AreEqual(10, QltyInspectionTestHeader."Source Quantity (Base)", 'The test source quantity (base) should match the quantity of the production line.');
    end;

    [Test]
    procedure CreateTestOnAfterPostOutput_AnyOutput_NoOutputOrScrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] No test is created when output journal with no quantities fails to post with AnyOutput configuration

        // [GIVEN] Setup exists and a template with 3 fields is created
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnAnyOutput
        QltyManagementSetup.Get();
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOutputPost;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnAnyOutput;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with no output quantity and no scrap quantity
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 0);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] Attempting to post the output journal with no quantities
        BeforeCount := QltyInspectionTestHeader.Count();
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] No test is created
        AfterCount := QltyInspectionTestHeader.Count();
        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'No test should be created.');
    end;

    [Test]
    procedure CreateTestOnAfterPostOutput_AnyOutput_OutputAndScrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Test is created with output quantity when both output and scrap are posted with AnyOutput configuration

        // [GIVEN] Setup exists and a template with 3 fields is created
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnAnyOutput
        QltyManagementSetup.Get();
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOutputPost;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnAnyOutput;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with output quantity 5 and scrap quantity 3
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine.Validate("Scrap Quantity", 3);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionTestHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One test is created
        AfterCount := QltyInspectionTestHeader.Count();
        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionTestHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One test should have been created.');

        // [THEN] Test uses correct template, item, and source quantity matches output quantity (5, not scrap 3)
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Test should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionTestHeader."Source Item No.", 'Test should be for the correct item.');
        LibraryAssert.AreEqual(5, QltyInspectionTestHeader."Source Quantity (Base)", 'The test source quantity (base) should match the quantity of the output.');
    end;

    [Test]
    procedure CreateTestOnAfterPostOutput_AnyQuantity_Output()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Test is created when output journal is posted with AnyQuantity configuration

        // [GIVEN] Setup exists and a template with 3 fields is created
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnAnyQuantity
        QltyManagementSetup.Get();
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOutputPost;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnAnyQuantity;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with 5 units of output quantity
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionTestHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One test is created
        AfterCount := QltyInspectionTestHeader.Count();
        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionTestHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One test should have been created.');

        // [THEN] Test uses correct template, item, and source quantity of 5
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Test should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionTestHeader."Source Item No.", 'Test should be for the correct item.');
        LibraryAssert.AreEqual(5, QltyInspectionTestHeader."Source Quantity (Base)", 'The test source quantity (base) should match the quantity of the output.');
    end;

    [Test]
    procedure CreateTestOnAfterPostOutput_AnyQuantity_Scrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Test is created when scrap journal is posted with AnyQuantity configuration using prod line quantity

        // [GIVEN] Setup exists and a template with 3 fields is created
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and released production order with quantity 10 are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnAnyQuantity
        QltyManagementSetup.Get();
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOutputPost;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnAnyQuantity;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with scrap quantity of 5 and no output quantity
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 0);
        ItemJournalLine.Validate("Scrap Quantity", 5);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionTestHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One test is created
        AfterCount := QltyInspectionTestHeader.Count();
        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionTestHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One test should have been created.');

        // [THEN] Test uses correct template, item, and source quantity matches prod line quantity (10)
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Test should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionTestHeader."Source Item No.", 'Test should be for the correct item.');
        LibraryAssert.AreEqual(10, QltyInspectionTestHeader."Source Quantity (Base)", 'The test source quantity (base) should match the quantity of the production line.');
    end;

    [Test]
    procedure CreateTestOnAfterPostOutput_AnyQuantity_OutputAndScrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Test is created with total quantity (output + scrap) when both are posted with AnyQuantity configuration

        // [GIVEN] Setup exists and a template with 3 fields is created
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnAnyQuantity
        QltyManagementSetup.Get();
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOutputPost;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnAnyQuantity;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with output quantity 5 and scrap quantity 3
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine.Validate("Scrap Quantity", 3);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionTestHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One test is created
        AfterCount := QltyInspectionTestHeader.Count();
        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionTestHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One test should have been created.');

        // [THEN] Test uses correct template and source quantity matches output quantity (5)
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Test should use provided template.');
        LibraryAssert.AreEqual(5, QltyInspectionTestHeader."Source Quantity (Base)", 'The test source quantity (base) should match the quantity of the output.');
    end;

    [Test]
    procedure CreateTestOnAfterPostOutput_AnyQuantity_NoOutputOrScrap_NoTest()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] No test is created when output journal with no quantities (output/scrap) fails to post with AnyQuantity configuration

        // [GIVEN] Setup exists and a template with 3 fields is created
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnAnyQuantity
        QltyManagementSetup.Get();
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOutputPost;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnAnyQuantity;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with no output quantity and no scrap quantity
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 0);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] Attempting to post the output journal with no quantities
        BeforeCount := QltyInspectionTestHeader.Count();
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] No test is created
        AfterCount := QltyInspectionTestHeader.Count();
        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'No test should be created.');
    end;

    [Test]
    procedure CreateTestOnAfterPostOutput_OnlyWithQuantity_Scrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] No test is created when only scrap is posted with OnlyWithQuantity configuration

        // [GIVEN] Setup exists and a template with 3 fields is created
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnlyWithQuantity
        QltyManagementSetup.Get();
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOutputPost;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnlyWithQuantity;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with only scrap quantity of 5
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 0);
        ItemJournalLine.Validate("Scrap Quantity", 5);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionTestHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] No test is created (OnlyWithQuantity ignores scrap-only)
        AfterCount := QltyInspectionTestHeader.Count();
        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'No test should be created.');
    end;

    [Test]
    procedure CreateTestOnAfterPostOutput_OnlyWithQuantity_Output()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Test is created when output journal is posted with OnlyWithQuantity configuration

        // [GIVEN] Setup exists and a template with 3 fields is created
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnlyWithQuantity
        QltyManagementSetup.Get();
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOutputPost;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnlyWithQuantity;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with output quantity of 5
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionTestHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One test is created
        AfterCount := QltyInspectionTestHeader.Count();
        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionTestHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One test should have been created.');

        // [THEN] Test uses correct template, item, and source quantity of 5
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Test should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionTestHeader."Source Item No.", 'Test should be for the correct item.');
        LibraryAssert.AreEqual(5, QltyInspectionTestHeader."Source Quantity (Base)", 'The test source quantity (base) should match the output.');
    end;

    [Test]
    procedure CreateTestOnAfterPostOutput_OnlyWithQuantity_OutputAndScrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Test is created with output quantity when both output and scrap are posted with OnlyWithQuantity configuration

        // [GIVEN] Setup exists and a template with 3 fields is created
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnlyWithQuantity
        QltyManagementSetup.Get();
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOutputPost;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnlyWithQuantity;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with output quantity 5 and scrap quantity 3
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine.Validate("Scrap Quantity", 3);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionTestHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One test is created
        AfterCount := QltyInspectionTestHeader.Count();
        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionTestHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One test should have been created.');

        // [THEN] Test uses correct template, item, and source quantity matches output (5, not scrap)
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Test should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionTestHeader."Source Item No.", 'Test should be for the correct item.');
        LibraryAssert.AreEqual(5, QltyInspectionTestHeader."Source Quantity (Base)", 'The test source quantity (base) should match the output.');
    end;

    [Test]
    procedure CreateTestOnAfterPostOutput_OnlyWithQuantity_NoOutputOrScrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] No test is created when output journal with no quantities fails to post with OnlyWithQuantity configuration

        // [GIVEN] Setup exists and a template with 3 fields is created
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnlyWithQuantity
        QltyManagementSetup.Get();
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOutputPost;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnlyWithQuantity;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with no output quantity and no scrap quantity
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 0);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] Attempting to post the output journal with no quantities
        BeforeCount := QltyInspectionTestHeader.Count();
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] No test is created
        AfterCount := QltyInspectionTestHeader.Count();
        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'No test should be created.');
    end;

    [Test]
    procedure CreateTestOnAfterPostOutput_OnlyWithScrap_Output()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] No test is created when only output is posted with OnlyWithScrap configuration

        // [GIVEN] Setup exists and a template with 3 fields is created
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and released production order are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnlyWithScrap
        QltyManagementSetup.Get();
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOutputPost;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnlyWithScrap;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with only output quantity of 5
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionTestHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] No test is created (OnlyWithScrap ignores output-only)
        AfterCount := QltyInspectionTestHeader.Count();
        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'No test should be created.');
    end;

    [Test]
    procedure CreateTestOnAfterPostOutput_OnlyWithScrap_Scrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Test is created when scrap journal is posted with OnlyWithScrap configuration using prod line quantity

        // [GIVEN] Setup exists and a template with 3 fields is created
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and released production order with quantity 10 are created
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Generation rule trigger is set to OnProductionOutputPost
        // [GIVEN] Setup Auto Output Configuration is set to OnlyWithScrap
        QltyManagementSetup.Get();
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOutputPost;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnlyWithScrap;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with scrap quantity of 5 and no output quantity
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 0);
        ItemJournalLine.Validate("Scrap Quantity", 5);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [WHEN] The output journal is posted
        BeforeCount := QltyInspectionTestHeader.Count();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] One test is created
        AfterCount := QltyInspectionTestHeader.Count();
        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionTestHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One test should have been created.');

        // [THEN] Test uses correct template, item, and source quantity matches prod line quantity (10)
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Test should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionTestHeader."Source Item No.", 'Test should be for the correct item.');
        LibraryAssert.AreEqual(10, QltyInspectionTestHeader."Source Quantity (Base)", 'The test source quantity (base) should match the quantity of the production line.');
    end;

    [Test]
    procedure CreateTestOnAfterPostOutput_OnlyWithScrap_OutputAndScrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Test is created when output journal with both output and scrap is posted with OnlyWithScrap configuration using output quantity

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] A production order is created with quantity 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Quality management setup has Auto Output Configuration set to OnlyWithScrap
        QltyManagementSetup.Get();
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOutputPost;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnlyWithScrap;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with output quantity 5 and scrap quantity 3
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine.Validate("Scrap Quantity", 3);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The output journal is posted
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        AfterCount := QltyInspectionTestHeader.Count();

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] One test is created
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Document Line No.", ProdOrderLine."Line No.");
        QltyInspectionTestHeader.FindLast();
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'One test should have been created.');

        // [THEN] Test uses correct template, item, and source quantity matches output quantity (5)
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Test should use provided template.');
        LibraryAssert.AreEqual(Item."No.", QltyInspectionTestHeader."Source Item No.", 'Test should be for the correct item.');
        LibraryAssert.AreEqual(5, QltyInspectionTestHeader."Source Quantity (Base)", 'The test source quantity (base) should match the quantity of the output.');
    end;

    [Test]
    procedure CreateTestOnAfterPostOutput_OnlyWithScrap_NoOutputOrScrap()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] No test is created when output journal with no output or scrap quantity fails to post with OnlyWithScrap configuration

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] A production order is created with quantity 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] Quality management setup has Auto Output Configuration set to OnlyWithScrap
        QltyManagementSetup.Get();
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOutputPost;
        QltyInTestGenerationRule.Modify();
        QltyManagementSetup."Auto Output Configuration" := QltyManagementSetup."Auto Output Configuration"::OnlyWithScrap;
        QltyManagementSetup.Modify();

        // [GIVEN] An output journal is created with no output quantity and no scrap quantity
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 0);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();
        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The output journal posting is attempted (and fails due to no quantities)
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        AfterCount := QltyInspectionTestHeader.Count();

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] No test is created
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'No test should be created.');
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusReleasedFormModalPageHandler,MessageHandler')]
    procedure CreateTestOnAfterRelease_ProdOrderRoutingLine()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ManufacturingSetup: Record "Manufacturing Setup";
        ToUseNoSeries: Record "No. Series";
        ToUseNoSeriesLine: Record "No. Series Line";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        ProdOrderStatus: Enum "Production Order Status";
    begin
        // [SCENARIO] Test is created when production order is released with routing lines available

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Line", QltyInTestGenerationRule);

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

        // [GIVEN] Test generation rule has Production Trigger set to OnProductionOrderRelease
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOrderRelease;
        QltyInTestGenerationRule.Modify();

        // [WHEN] The production order status is changed to Released
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] One test is created for the item
        CreatedQltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        LibraryAssert.IsTrue(not CreatedQltyInspectionTestHeader.IsEmpty(), 'One test should be created and should match item.');
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusReleasedFormModalPageHandler,MessageHandler')]
    procedure CreateTestOnAfterRelease_ProdOrderLine()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ManufacturingSetup: Record "Manufacturing Setup";
        ToUseNoSeries: Record "No. Series";
        ToUseNoSeriesLine: Record "No. Series Line";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        ProdOrderStatus: Enum "Production Order Status";
    begin
        // [SCENARIO] Test is created when production order is released without routing lines

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Line", QltyInTestGenerationRule);

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

        // [GIVEN] Test generation rule has Production Trigger set to OnProductionOrderRelease
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOrderRelease;
        QltyInTestGenerationRule.Modify();

        // [WHEN] The production order status is changed to Released
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] One test is created for the item
        CreatedQltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        LibraryAssert.AreEqual(1, CreatedQltyInspectionTestHeader.Count(), 'Test should match item.');
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusReleasedFormModalPageHandler,MessageHandler')]
    procedure CreateTestOnAfterRelease_ProdOrderRoutingLine_TrackedItem()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ManufacturingSetup: Record "Manufacturing Setup";
        ToUseNoSeries: Record "No. Series";
        ToUseNoSeriesLine: Record "No. Series Line";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        ProdOrderStatus: Enum "Production Order Status";
    begin
        // [SCENARIO] Test is created when production order with lot-tracked item is released with routing lines available

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Line", QltyInTestGenerationRule);

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

        // [GIVEN] Test generation rule has Production Trigger set to OnProductionOrderRelease
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOrderRelease;
        QltyInTestGenerationRule.Modify();

        // [WHEN] The production order status is changed to Released
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] One test is created for the lot-tracked item
        CreatedQltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        LibraryAssert.IsTrue(not CreatedQltyInspectionTestHeader.IsEmpty(), 'One test should be created and match item.');
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusReleasedFormModalPageHandler,MessageHandler')]
    procedure CreateTestOnAfterRelease_ProdOrderLine_TrackedItem()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ManufacturingSetup: Record "Manufacturing Setup";
        ToUseNoSeries: Record "No. Series";
        ToUseNoSeriesLine: Record "No. Series Line";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        ProdOrderStatus: Enum "Production Order Status";
    begin
        // [SCENARIO] Test is created when production order with lot-tracked item is released without routing lines

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Line", QltyInTestGenerationRule);

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

        // [GIVEN] Test generation rule has Production Trigger set to OnProductionOrderRelease
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::OnProductionOrderRelease;
        QltyInTestGenerationRule.Modify();

        // [WHEN] The production order status is changed to Released
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] One test is created for the lot-tracked item
        CreatedQltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        LibraryAssert.AreEqual(1, CreatedQltyInspectionTestHeader.Count(), 'One test should be created and should match item.');
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences1()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
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
        // [SCENARIO] Test source record IDs are updated when production order status changes from Released to Finished with source order: ProdOrderLine, ProdOrderRoutingLine, ProdProductionOrder

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Line", QltyInTestGenerationRule);

        // [GIVEN] An item and production order are created with routing line
        // [GIVEN] Production order line quantity is set to 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] A quality test is created with variants in order: ProdOrderLine, ProdOrderRoutingLine, ProdProductionOrder
        // [GIVEN] All three source record IDs have "Released" status
        RecordRef.GetTable(ProdOrderLine);
        QltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(ProdOrderLine, ProdOrderRoutingLine, ProdProductionOrder, UnusedVariant, false, '');
        QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
        RecordId := Format(QltyInspectionTestHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionTestHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionTestHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Released') > 0, 'The source record ID should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Released') > 0, 'The source record ID 2 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Released') > 0, 'The source record ID 3 should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] Test source record IDs are updated to have "Finished" status
        QltyInspectionTestHeader.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.");
        RecordId := Format(QltyInspectionTestHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionTestHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionTestHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Finished') > 0, 'The source record ID should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Finished') > 0, 'The source record ID 2 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Finished') > 0, 'The source record ID 3 should have the "finished" status.');

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences2()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
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
        // [SCENARIO] Test source record IDs are updated when production order status changes from Released to Finished with source order: ProdProductionOrder, ProdOrderLine, ProdOrderRoutingLine

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Line", QltyInTestGenerationRule);

        // [GIVEN] An item and production order are created with routing line
        // [GIVEN] Production order line quantity is set to 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] A quality test is created with variants in order: ProdProductionOrder, ProdOrderLine, ProdOrderRoutingLine
        // [GIVEN] All three source record IDs have "Released" status
        RecordRef.GetTable(ProdOrderLine);
        QltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(ProdProductionOrder, ProdOrderLine, ProdOrderRoutingLine, UnusedVariant, false, '');
        QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
        RecordId := Format(QltyInspectionTestHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionTestHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionTestHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Released') > 0, 'The source record ID should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Released') > 0, 'The source record ID 2 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Released') > 0, 'The source record ID 3 should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] Test source record IDs are updated to have "Finished" status
        QltyInspectionTestHeader.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.");
        RecordId := Format(QltyInspectionTestHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionTestHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionTestHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Finished') > 0, 'The source record ID should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Finished') > 0, 'The source record ID 2 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Finished') > 0, 'The source record ID 3 should have the "finished" status.');

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences3()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
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
        // [SCENARIO] Test source record IDs are updated when production order status changes from Released to Finished with source order: ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Line", QltyInTestGenerationRule);

        // [GIVEN] An item and production order are created with routing line
        // [GIVEN] Production order line quantity is set to 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] A quality test is created with variants in order: ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine
        // [GIVEN] All source record IDs have "Released" status (note: third ID is not checked due to variant ordering)
        RecordRef.GetTable(ProdOrderLine);
        QltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine, UnusedVariant, false, '');
        QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
        RecordId := Format(QltyInspectionTestHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionTestHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionTestHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Released') > 0, 'The source record ID should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Released') > 0, 'The source record ID 2 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Released') > 0, 'The source record ID 3 should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] Test source record IDs are updated to have "Finished" status
        QltyInspectionTestHeader.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.");
        RecordId := Format(QltyInspectionTestHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionTestHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionTestHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Finished') > 0, 'The source record ID should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Finished') > 0, 'The source record ID 2 should have the "finished" status.');

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences4()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
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
        // [SCENARIO] Test source record IDs are updated when production order status changes from Released to Finished with routing line-based test and source order: ProdOrderRoutingLine, ProdOrderLine, ProdProductionOrder

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInTestGenerationRule);

        // [GIVEN] An item and production order are created with routing line
        // [GIVEN] Production order line quantity is set to 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] A quality test is created with variants in order: ProdOrderRoutingLine, ProdOrderLine, ProdProductionOrder
        // [GIVEN] All three source record IDs have "Released" status
        RecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(ProdOrderRoutingLine, ProdOrderLine, ProdProductionOrder, UnusedVariant, false, '');
        QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
        RecordId := Format(QltyInspectionTestHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionTestHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionTestHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Released') > 0, 'The source record ID should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Released') > 0, 'The source record ID 2 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Released') > 0, 'The source record ID 3 should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] Test source record IDs are updated to have "Finished" status
        QltyInspectionTestHeader.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.");
        RecordId := Format(QltyInspectionTestHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionTestHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionTestHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Finished') > 0, 'The source record ID should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Finished') > 0, 'The source record ID 2 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Finished') > 0, 'The source record ID 3 should have the "finished" status.');

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences5()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
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
        // [SCENARIO] Test source record IDs are updated when production order status changes from Released to Finished with routing line-based test and source order: ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInTestGenerationRule);

        // [GIVEN] An item and production order are created with routing line
        // [GIVEN] Production order line quantity is set to 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] A quality test is created with variants in order: ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine
        // [GIVEN] All three source record IDs have "Released" status
        RecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine, UnusedVariant, false, '');
        QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
        RecordId := Format(QltyInspectionTestHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionTestHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionTestHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Released') > 0, 'The source record ID should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Released') > 0, 'The source record ID 2 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Released') > 0, 'The source record ID 3 should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] Test source record IDs are updated to have "Finished" status
        QltyInspectionTestHeader.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.");
        RecordId := Format(QltyInspectionTestHeader."Source RecordId");
        RecordIdSecond := Format(QltyInspectionTestHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionTestHeader."Source RecordId 3");

        LibraryAssert.IsTrue(RecordId.IndexOf('Finished') > 0, 'The source record ID should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Finished') > 0, 'The source record ID 2 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Finished') > 0, 'The source record ID 3 should have the "finished" status.');

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences6()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
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
        // [SCENARIO] Test source record IDs are updated when production order status changes from Released to Finished with journal line-based test and source order: ItemJournalLine, ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and production order are created with routing line
        // [GIVEN] Production order line quantity is set to 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] An output journal is created with output quantity 5 and scrap quantity 3
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);

        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine.Validate("Scrap Quantity", 3);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [GIVEN] A quality test is created with variants in order: ItemJournalLine, ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine
        // [GIVEN] Source record IDs 2, 3, and 4 have "Released" status
        RecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(ItemJournalLine, ProdOrderRoutingLine, ProdProductionOrder, ProdOrderLine, false, '');
        QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
        RecordIdSecond := Format(QltyInspectionTestHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionTestHeader."Source RecordId 3");
        RecordIdFourth := Format(QltyInspectionTestHeader."Source RecordId 4");

        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Released') > 0, 'The source record ID 2 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Released') > 0, 'The source record ID 3 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdFourth.IndexOf('Released') > 0, 'The source record ID 4 should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] Test source record IDs are updated to have "Finished" status
        QltyInspectionTestHeader.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.");
        RecordIdSecond := Format(QltyInspectionTestHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionTestHeader."Source RecordId 3");
        RecordIdFourth := Format(QltyInspectionTestHeader."Source RecordId 4");

        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Finished') > 0, 'The source record ID 2 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Finished') > 0, 'The source record ID 3 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdFourth.IndexOf('Finished') > 0, 'The source record ID 4 should have the "finished" status.');

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences7()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
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
        // [SCENARIO] Test source record IDs are updated when production order status changes from Released to Finished with journal line-based test and source order: ItemJournalLine, ProdOrderRoutingLine, ProdOrderLine, ProdProductionOrder

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and production order are created with routing line
        // [GIVEN] Production order line quantity is set to 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] An output journal is created with output quantity 5 and scrap quantity 3
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);

        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine.Validate("Scrap Quantity", 3);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [GIVEN] A quality test is created with variants in order: ItemJournalLine, ProdOrderRoutingLine, ProdOrderLine, ProdProductionOrder
        // [GIVEN] Source record IDs 2, 3, and 4 have "Released" status
        RecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(ItemJournalLine, ProdOrderRoutingLine, ProdOrderLine, ProdProductionOrder, false, '');
        QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
        RecordIdSecond := Format(QltyInspectionTestHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionTestHeader."Source RecordId 3");
        RecordIdFourth := Format(QltyInspectionTestHeader."Source RecordId 4");

        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Released') > 0, 'The source record ID 2 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Released') > 0, 'The source record ID 3 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdFourth.IndexOf('Released') > 0, 'The source record ID 4 should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] Test source record IDs are updated to have "Finished" status
        QltyInspectionTestHeader.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.");
        RecordIdSecond := Format(QltyInspectionTestHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionTestHeader."Source RecordId 3");
        RecordIdFourth := Format(QltyInspectionTestHeader."Source RecordId 4");

        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Finished') > 0, 'The source record ID 2 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Finished') > 0, 'The source record ID 3 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdFourth.IndexOf('Finished') > 0, 'The source record ID 4 should have the "finished" status.');

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences8()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
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
        // [SCENARIO] Test source record IDs are updated when production order status changes from Released to Finished with journal line-based test and source order: ItemJournalLine, ProdOrderLine, ProdProductionOrder, ProdOrderRoutingLine

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        CreateOutputPrioritizedRule(QltyInspectionTemplateHdr, QltyInTestGenerationRule);

        // [GIVEN] An item and production order are created with routing line
        // [GIVEN] Production order line quantity is set to 10
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] An output journal is created with output quantity 5 and scrap quantity 3
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);

        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, 5);
        ItemJournalLine.Validate("Scrap Quantity", 3);
        ItemJournalLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ItemJournalLine."No." := ProdOrderRoutingLine."No.";
        ItemJournalLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ItemJournalLine.Modify();

        // [GIVEN] A quality test is created with variants in order: ItemJournalLine, ProdOrderLine, ProdProductionOrder, ProdOrderRoutingLine
        // [GIVEN] Source record IDs 2, 3, and 4 have "Released" status
        RecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(ItemJournalLine, ProdOrderLine, ProdProductionOrder, ProdOrderRoutingLine, false, '');
        QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
        RecordIdSecond := Format(QltyInspectionTestHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionTestHeader."Source RecordId 3");
        RecordIdFourth := Format(QltyInspectionTestHeader."Source RecordId 4");

        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Released') > 0, 'The source record ID 2 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Released') > 0, 'The source record ID 3 should have the "released" status.');
        LibraryAssert.IsTrue(RecordIdFourth.IndexOf('Released') > 0, 'The source record ID 4 should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] Test source record IDs are updated to have "Finished" status
        QltyInspectionTestHeader.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.");
        RecordIdSecond := Format(QltyInspectionTestHeader."Source RecordId 2");
        RecordIdThird := Format(QltyInspectionTestHeader."Source RecordId 3");
        RecordIdFourth := Format(QltyInspectionTestHeader."Source RecordId 4");

        LibraryAssert.IsTrue(RecordIdSecond.IndexOf('Finished') > 0, 'The source record ID 2 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdThird.IndexOf('Finished') > 0, 'The source record ID 3 should have the "finished" status.');
        LibraryAssert.IsTrue(RecordIdFourth.IndexOf('Finished') > 0, 'The source record ID 4 should have the "finished" status.');

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CreateTestOnAfterPost_Assembly_TrackedItem()
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
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
        // [SCENARIO] Two tests are created when assembly order with lot-tracked item is posted with two lot numbers

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
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);

        // [GIVEN] A test generation rule is created for Posted Assembly Header table
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Posted Assembly Header", QltyInTestGenerationRule);

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

        // [GIVEN] Test generation rule has Assembly Trigger set to OnAssemblyOutputPost
        QltyInTestGenerationRule."Assembly Trigger" := QltyInTestGenerationRule."Assembly Trigger"::OnAssemblyOutputPost;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The assembly order is posted
        EnsureGenPostingSetupExistsForAssembly(AssemblyHeader);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [THEN] Two tests are created (one for each lot number)
        LibraryAssert.AreEqual((BeforeCount + 2), QltyInspectionTestHeader.Count(), 'Should be two new tests.');

        // [THEN] Each test uses correct template, location, quantity (5), and lot number
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        if QltyInspectionTestHeader.FindSet() then
            repeat
                LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Should be same template.');
                LibraryAssert.AreEqual(Location.Code, QltyInspectionTestHeader."Location Code", 'Should be same location.');
                LibraryAssert.AreEqual(5, QltyInspectionTestHeader."Source Quantity (Base)", 'Should be same quantity.');
                LibraryAssert.IsTrue((QltyInspectionTestHeader."Source Lot No." = LotNo1) or (QltyInspectionTestHeader."Source Lot No." = LotNo2), 'Should be same lot no.');
            until QltyInspectionTestHeader.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CreateTestOnAfterPost_Assembly_UntrackedItem()
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
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
        // [SCENARIO] One test is created when assembly order with untracked item is posted

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
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);

        // [GIVEN] A test generation rule is created for Posted Assembly Header table
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Posted Assembly Header", QltyInTestGenerationRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An assembly order is created with 2 components and component inventory is added
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate(), Location.Code, 2);
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate(), 0);

        // [GIVEN] Test generation rule has Assembly Trigger set to OnAssemblyOutputPost
        QltyInTestGenerationRule."Assembly Trigger" := QltyInTestGenerationRule."Assembly Trigger"::OnAssemblyOutputPost;
        QltyInTestGenerationRule.Modify();

        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The assembly order is posted
        EnsureGenPostingSetupExistsForAssembly(AssemblyHeader);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [THEN] One test is created
        LibraryAssert.AreEqual((BeforeCount + 1), QltyInspectionTestHeader.Count(), 'Should be one new test.');

        // [THEN] Test uses correct template, location, and quantity matches assembly order quantity
        QltyInspectionTestHeader.SetRange("Source Item No.", AssemblyHeader."Item No.");
        QltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, QltyInspectionTestHeader."Template Code", 'Should be same template.');
        LibraryAssert.AreEqual(Location.Code, QltyInspectionTestHeader."Location Code", 'Should be same location.');
        LibraryAssert.AreEqual(AssemblyHeader."Quantity (Base)", QltyInspectionTestHeader."Source Quantity (Base)", 'Should be same quantity.');
    end;

    [Test]
    procedure CreateTestOnAfterRefreshProdOrder()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        BeforeCount: Integer;
        CountOfRoutingLines: Integer;
    begin
        // [SCENARIO] Quality inspection tests are created for all routing lines when production order is refreshed with OnReleasedProductionOrderRefresh trigger

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInTestGenerationRule.DeleteAll();

        // [GIVEN] A test generation rule is created for Prod. Order Routing Line with OnReleasedProductionOrderRefresh trigger
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInTestGenerationRule);
        QltyInTestGenerationRule.Validate("Production Trigger", QltyInTestGenerationRule."Production Trigger"::OnReleasedProductionOrderRefresh);
        QltyInTestGenerationRule.Modify(true);

        // [GIVEN] An item and production order are created with routing lines
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderRoutingLine.Reset();
        ProdOrderRoutingLine.SetRange(Status, ProdProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdProductionOrder."No.");
        CountOfRoutingLines := ProdOrderRoutingLine.Count();

        // [GIVEN] The current count of inspection test headers is recorded
        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] The production order is refreshed
        ProdProductionOrder.SetRecFilter();
        Report.Run(Report::"Refresh Production Order", false, false, ProdProductionOrder);

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();

        // [THEN] Tests are created for each routing line
        LibraryAssert.AreEqual(BeforeCount + CountOfRoutingLines, QltyInspectionTestHeader.Count(), 'Test(s) was not created.');
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences_ProdOrder_NoSourceConfig()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        TestQualityOrder: Record "Qlty. Inspection Test Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        RecordRef: RecordRef;
        RecordId: Text;
    begin
        // [SCENARIO] Test source record ID is updated when production order status changes with no source configuration and "Update when source changes" setting

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Production Order", QltyInTestGenerationRule);

        // [GIVEN] An item and production order are created with routing line
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] A quality test is created for the production order with Released status
        RecordRef.GetTable(ProdProductionOrder);
        QltyInspectionTestCreate.CreateTest(RecordRef, false);
        QltyInspectionTestCreate.GetCreatedTest(TestQualityOrder);
        RecordId := Format(TestQualityOrder."Source RecordId");

        LibraryAssert.IsTrue(RecordId.IndexOf('Released') > 0, 'The source record ID should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [GIVEN] All source configurations are deleted
        QltyInspectSourceConfig.DeleteAll();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] The test source record ID is updated to have "Finished" status
        TestQualityOrder.Get(TestQualityOrder."No.", TestQualityOrder."Retest No.");
        RecordId := Format(TestQualityOrder."Source RecordId");

        LibraryAssert.IsTrue(RecordId.IndexOf('Finished') > 0, 'The source record ID should have the "finished" status.');

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences_ProdOrderLine_NoSourceConfig()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        TestQualityOrder: Record "Qlty. Inspection Test Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        RecordRef: RecordRef;
        RecordId: Text;
    begin
        // [SCENARIO] Test source record ID is updated when production order status changes with no source configuration and "Update when source changes" setting for Prod. Order Line

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Line", QltyInTestGenerationRule);

        // [GIVEN] An item and production order are created with routing line
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] A quality test is created for the production order line with Released status
        RecordRef.GetTable(ProdOrderLine);
        QltyInspectionTestCreate.CreateTest(RecordRef, false);
        QltyInspectionTestCreate.GetCreatedTest(TestQualityOrder);
        RecordId := Format(TestQualityOrder."Source RecordId");

        LibraryAssert.IsTrue(RecordId.IndexOf('Released') > 0, 'The source record ID should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [GIVEN] All source configurations are deleted
        QltyInspectSourceConfig.DeleteAll();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] The test source record ID is updated to have "Finished" status
        TestQualityOrder.Get(TestQualityOrder."No.", TestQualityOrder."Retest No.");
        RecordId := Format(TestQualityOrder."Source RecordId");

        LibraryAssert.IsTrue(RecordId.IndexOf('Finished') > 0, 'The source record ID should have the "finished" status.');

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatusFinishedFormModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UpdateReferences_ProdOrderRoutingLine_NoSourceConfig()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        TestQualityOrder: Record "Qlty. Inspection Test Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        RecordRef: RecordRef;
        RecordId: Text;
    begin
        // [SCENARIO] Test source record ID is updated when production order status changes with no source configuration and "UpdateOnChange" setting for Prod. Order Routing Line

        // [GIVEN] Quality management setup exists
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A quality inspection template is created with 3 lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInTestGenerationRule);

        // [GIVEN] An item and production order are created with routing line
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdProductionOrder."No.", 10000);
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify();

        // [GIVEN] A quality test is created for the production order routing line with Released status
        RecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionTestCreate.CreateTest(RecordRef, false);
        QltyInspectionTestCreate.GetCreatedTest(TestQualityOrder);
        RecordId := Format(TestQualityOrder."Source RecordId");

        LibraryAssert.IsTrue(RecordId.IndexOf('Released') > 0, 'The source record ID should have the "released" status.');

        // [GIVEN] Production Update Control is set to "Update when source changes"
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Update Control", QltyManagementSetup."Production Update Control"::"Update when source changes");
        QltyManagementSetup.Modify();

        // [GIVEN] All source configurations are deleted
        QltyInspectSourceConfig.DeleteAll();

        // [WHEN] The production order status is changed to Finished
        Codeunit.Run(Codeunit::"Prod. Order Status Management", ProdProductionOrder);

        // [THEN] The test source record ID is updated to have "Finished" status
        TestQualityOrder.Get(TestQualityOrder."No.", TestQualityOrder."Retest No.");
        RecordId := Format(TestQualityOrder."Source RecordId");

        LibraryAssert.IsTrue(RecordId.IndexOf('Finished') > 0, 'The source record ID should have the "finished" status.');

        QltyInTestGenerationRule.Delete();
        QltyInspectionTemplateHdr.Delete();
    end;

    local procedure CreateOutputPrioritizedRule(QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; var QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule")
    var
        FindLowestQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        FindLowestQltyInTestGenerationRule.Reset();
        FindLowestQltyInTestGenerationRule.SetCurrentKey("Sort Order");

        QltyInTestGenerationRule.Init();
        if FindLowestQltyInTestGenerationRule.FindFirst() then
            QltyInTestGenerationRule."Sort Order" := FindLowestQltyInTestGenerationRule."Sort Order" - 1;

        QltyInTestGenerationRule."Template Code" := QltyInspectionTemplateHdr.Code;
        QltyInTestGenerationRule."Source Table No." := Database::"Item Journal Line";
        QltyInTestGenerationRule.Insert(true);
    end;

    local procedure EnsureGenPostingSetupExistsForAssembly(AssemblyHeader: Record "Assembly Header")
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
    procedure AutomatedTestTemplateModalPageHandler(var QltyInspectionTemplate: TestPage "Qlty. Inspection Template")
    begin
    end;
}
