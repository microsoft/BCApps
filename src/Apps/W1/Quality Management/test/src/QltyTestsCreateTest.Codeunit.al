// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.Test.QualityManagement.TestLibraries;
using System.TestLibraries.Utilities;

codeunit 139959 "Qlty. Tests - Create Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        ReUsableQltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        CannotFindTemplateErr: Label 'Cannot find a Quality Inspection Template or Quality Inspection Test Generation Rule to match  %1. Ensure there is a Quality Inspection Test Generation Rule that will match this record.', Comment = '%1=The record identifier';
        ProgrammerErrNotARecordRefErr: Label 'Cannot find tests with %1. Please supply a "Record" or "RecordRef".', Comment = '%1=the variant being supplied that is not a recordref. Your system might have an extension or customization that needs to be re-configured.';
        UnableToCreateATestForRecordErr: Label 'Cannot find enough details to make a test for your record(s).  Try making sure that there is a source configuration for your record, and then also make sure there is sufficient information in your test generation rules.  The table involved is %1.', Comment = '%1=the table involved.';
        UnableToCreateATestForParentOrChildErr: Label 'Cannot find enough details to make a test for your record(s).  Try making sure that there is a source configuration for your record, and then also make sure there is sufficient information in your test generation rules.  Two tables involved are %1 and %2.', Comment = '%1=the parent table, %2=the child and original table.';
        IsInitialized: Boolean;

    [Test]
    procedure BasicCreate()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a basic quality inspection test from production order routing line

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();
        ClearLastError();

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] CreateTest is called with AlwaysCreate set to true
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        QltyInTestGenerationRule.Delete();

        // [THEN] The function claims a test was found or created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'Should claim a test has been found/created');

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] Overall test count increases by 1 and there is exactly one test for this operation
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests increase by 1.');
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test has the correct template code
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedQltyInspectionTestHeader);
        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            CreatedQltyInspectionTestHeader."Template Code",
            'Test generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        // [THEN] The created test has the correct document number, item, and template
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'Either wrong test gen. rule, or wrong item, or wrong document got applied.');
    end;

    [Test]
    procedure CreateTest_AlwaysCreate()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedTestFirstQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedTestSecondQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        CreateTestBehavior: Enum "Qlty. Create Test Behavior";
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create test with AlwaysCreate behavior creates a new test even when one exists

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A first test is created
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedTestFirstQltyInspectionTestHeader);

        // [GIVEN] The Create Test Behavior is set to "Always create new test"
        QltyManagementSetup.Get();
        CreateTestBehavior := QltyManagementSetup."Create Test Behavior";
        QltyManagementSetup."Create Test Behavior" := QltyManagementSetup."Create Test Behavior"::"Always create new test";
        QltyManagementSetup.Modify();

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();
        ClearLastError();

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] CreateTest is called again for the same routing line
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedTestSecondQltyInspectionTestHeader);

        QltyManagementSetup."Create Test Behavior" := CreateTestBehavior;
        QltyManagementSetup.Modify();
        QltyInTestGenerationRule.Delete();

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] A new test is created and the second test has a different number than the first
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'Should claim a test has been found/created.');
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests');
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreNotEqual(CreatedTestFirstQltyInspectionTestHeader."No.", CreatedTestSecondQltyInspectionTestHeader."No.", 'New test should not be a retest.');
    end;

    [Test]
    procedure CreateTest_CreateARetestAny()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedTestFirstQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedTestSecondQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        CreateTestBehavior: Enum "Qlty. Create Test Behavior";
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create test with CreateARetestAny behavior creates a retest when a test already exists

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A first test is created
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedTestFirstQltyInspectionTestHeader);

        // [GIVEN] The Create Test Behavior is set to "Always create retest"
        QltyManagementSetup.Get();
        CreateTestBehavior := QltyManagementSetup."Create Test Behavior";
        QltyManagementSetup."Create Test Behavior" := QltyManagementSetup."Create Test Behavior"::"Always create retest";
        QltyManagementSetup.Modify();

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();
        ClearLastError();

        // [WHEN] CreateTest is called again for the same routing line
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedTestSecondQltyInspectionTestHeader);

        QltyManagementSetup."Create Test Behavior" := CreateTestBehavior;
        QltyManagementSetup.Modify();
        QltyInTestGenerationRule.Delete();

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] A retest is created and the second test has the same number as the first with incremented Retest No.
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'Should claim a test has been found/created.');
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests increase by 1');
        LibraryAssert.AreEqual(CreatedTestFirstQltyInspectionTestHeader."No.", CreatedTestSecondQltyInspectionTestHeader."No.", 'New test should be a retest.');
        LibraryAssert.AreEqual((CreatedTestFirstQltyInspectionTestHeader."Retest No." + 1), CreatedTestSecondQltyInspectionTestHeader."Retest No.", 'New test "Retest No." should have incremented.');
    end;

    [Test]
    procedure CreateTest_CreateARetestFinished_NotFinished()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedTestFirstQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedTestSecondQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        CreateTestBehavior: Enum "Qlty. Create Test Behavior";
        BeforeCount: Integer;
        AfterCount: Integer;
        ClaimedATestWasFoundOrCreated: Boolean;
    begin
        // [SCENARIO] Create test with CreateARetestFinished behavior, using a production order routing line, retrieves existing test when it is not finished

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A first test is created
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedTestFirstQltyInspectionTestHeader);

        // [GIVEN] The Create Test Behavior is set to "Create retest if matching test is finished"
        QltyManagementSetup.Get();
        CreateTestBehavior := QltyManagementSetup."Create Test Behavior";
        QltyManagementSetup."Create Test Behavior" := QltyManagementSetup."Create Test Behavior"::"Create retest if matching test is finished";
        QltyManagementSetup.Modify();

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] CreateTest is called again for the same routing line when the first test is not finished
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedTestSecondQltyInspectionTestHeader);

        QltyManagementSetup."Create Test Behavior" := CreateTestBehavior;
        QltyManagementSetup.Modify();
        QltyInTestGenerationRule.Delete();

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] No new test is created and the same test is retrieved with the same number and Retest No.
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'Should claim a test has been found/created.');
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'Should not be any new tests counted.');
        LibraryAssert.AreEqual(CreatedTestFirstQltyInspectionTestHeader."No.", CreatedTestSecondQltyInspectionTestHeader."No.", 'Should retrieve same test.');
        LibraryAssert.AreEqual(CreatedTestFirstQltyInspectionTestHeader."Retest No.", CreatedTestSecondQltyInspectionTestHeader."Retest No.", 'Should retrieve same test.');
    end;

    [Test]
    procedure CreateTest_CreateARetestFinished_Finished()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedTestFirstQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedTestSecondQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        CreateTestBehavior: Enum "Qlty. Create Test Behavior";
        BeforeCount: Integer;
        AfterCount: Integer;
        ClaimedATestWasFoundOrCreated: Boolean;
    begin
        // [SCENARIO] Create test with CreateARetestFinished behavior, using a production order routing line, creates a retest when the existing test is finished

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A first test is created
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedTestFirstQltyInspectionTestHeader);

        // [GIVEN] The Create Test Behavior is set to "Create retest if matching test is finished"
        QltyManagementSetup.Get();
        CreateTestBehavior := QltyManagementSetup."Create Test Behavior";
        QltyManagementSetup."Create Test Behavior" := QltyManagementSetup."Create Test Behavior"::"Create retest if matching test is finished";
        QltyManagementSetup.Modify();

        // [GIVEN] The first test is marked as Finished
        CreatedTestFirstQltyInspectionTestHeader.Status := CreatedTestFirstQltyInspectionTestHeader.Status::Finished;
        CreatedTestFirstQltyInspectionTestHeader.Modify();

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] CreateTest is called again for the same routing line with the first test finished
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedTestSecondQltyInspectionTestHeader);

        QltyManagementSetup."Create Test Behavior" := CreateTestBehavior;
        QltyManagementSetup.Modify();
        QltyInTestGenerationRule.Delete();

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] A retest is created with incremented Retest No. and overall test count increases by 1
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'Should claim a test has been found/created.');
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests increase by 1.');
        LibraryAssert.AreEqual(CreatedTestFirstQltyInspectionTestHeader."No.", CreatedTestSecondQltyInspectionTestHeader."No.", 'New test should be a retest.');
        LibraryAssert.AreEqual((CreatedTestFirstQltyInspectionTestHeader."Retest No." + 1), CreatedTestSecondQltyInspectionTestHeader."Retest No.", 'New test "Retest No." should have incremented.');
    end;

    [Test]
    procedure CreateTest_CreateARetestFinished_UseExistingTestOpen_Finished()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedTestFirstQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedTestSecondQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        CreateTestBehavior: Enum "Qlty. Create Test Behavior";
        BeforeCount: Integer;
        AfterCount: Integer;
        ClaimedATestWasFoundOrCreated: Boolean;
    begin
        // [SCENARIO] Create test with UseExistingTestOpenElseNew behavior, using a production order routing line, creates a new test when existing test is finished

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A first test is created
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedTestFirstQltyInspectionTestHeader);

        // [GIVEN] The Create Test Behavior is set to "Use existing open test if available"
        QltyManagementSetup.Get();
        CreateTestBehavior := QltyManagementSetup."Create Test Behavior";
        QltyManagementSetup."Create Test Behavior" := QltyManagementSetup."Create Test Behavior"::"Use existing open test if available";
        QltyManagementSetup.Modify();

        // [GIVEN] The first test is marked as Finished
        CreatedTestFirstQltyInspectionTestHeader.Status := CreatedTestFirstQltyInspectionTestHeader.Status::Finished;
        CreatedTestFirstQltyInspectionTestHeader.Modify();

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] CreateTest is called again for the same routing line with the first test finished
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedTestSecondQltyInspectionTestHeader);

        QltyManagementSetup."Create Test Behavior" := CreateTestBehavior;
        QltyManagementSetup.Modify();
        QltyInTestGenerationRule.Delete();

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] A new test is created that is not a retest
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'Should claim a test has been found/created.');
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests');
        LibraryAssert.AreNotEqual(CreatedTestFirstQltyInspectionTestHeader."No.", CreatedTestSecondQltyInspectionTestHeader."No.", 'New test should not be a retest.');
    end;

    [Test]
    procedure CreateTest_CreateARetestFinished_UseExistingTestOpen_Open()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedTestFirstQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedTestSecondQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        CreateTestBehavior: Enum "Qlty. Create Test Behavior";
        BeforeCount: Integer;
        AfterCount: Integer;
        ClaimedATestWasFoundOrCreated: Boolean;
    begin
        // [SCENARIO] Create test with UseExistingTestOpenElseNew behavior, using a production order routing line, retrieves existing open test

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A first test is created and left open
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedTestFirstQltyInspectionTestHeader);

        // [GIVEN] The Create Test Behavior is set to "Use existing open test if available"
        QltyManagementSetup.Get();
        CreateTestBehavior := QltyManagementSetup."Create Test Behavior";
        QltyManagementSetup."Create Test Behavior" := QltyManagementSetup."Create Test Behavior"::"Use existing open test if available";
        QltyManagementSetup.Modify();

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] CreateTest is called again for the same routing line with the first test still open
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedTestSecondQltyInspectionTestHeader);

        QltyManagementSetup."Create Test Behavior" := CreateTestBehavior;
        QltyManagementSetup.Modify();
        QltyInTestGenerationRule.Delete();

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] No new test is created and the same test is retrieved
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'Should claim a test has been found/created.');
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'Should not be any new tests counted.');
        LibraryAssert.AreEqual(CreatedTestFirstQltyInspectionTestHeader."No.", CreatedTestSecondQltyInspectionTestHeader."No.", 'Should have retrieved same record.');
    end;

    [Test]
    procedure CreateTest_CreateARetestFinished_UseExistingTestAny_Existing()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedTestFirstQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedTestSecondQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        CreateTestBehavior: Enum "Qlty. Create Test Behavior";
        BeforeCount: Integer;
        AfterCount: Integer;
        ClaimedATestWasFoundOrCreated: Boolean;
    begin
        // [SCENARIO] Create test with UseExistingTestAnyElseNew behavior, using a production order routing line, retrieves existing test even if finished

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A first test is created
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedTestFirstQltyInspectionTestHeader);

        // [GIVEN] The Create Test Behavior is set to "Use any existing test if available"
        QltyManagementSetup.Get();
        CreateTestBehavior := QltyManagementSetup."Create Test Behavior";
        QltyManagementSetup."Create Test Behavior" := QltyManagementSetup."Create Test Behavior"::"Use any existing test if available";
        QltyManagementSetup.Modify();

        // [GIVEN] The first test is marked as Finished
        CreatedTestFirstQltyInspectionTestHeader.Status := CreatedTestFirstQltyInspectionTestHeader.Status::Finished;
        CreatedTestFirstQltyInspectionTestHeader.Modify();

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] CreateTest is called again for the same routing line
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedTestSecondQltyInspectionTestHeader);

        QltyManagementSetup."Create Test Behavior" := CreateTestBehavior;
        QltyManagementSetup.Modify();
        QltyInTestGenerationRule.Delete();

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] The existing test is found and no new test is created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been found.');
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'Expected overall tests count not to change.');
    end;

    [Test]
    procedure CreateTest_CreateARetestFinished_UseExistingTestAny_New()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        CreateTestBehavior: Enum "Qlty. Create Test Behavior";
        BeforeCount: Integer;
        AfterCount: Integer;
        ClaimedATestWasFoundOrCreated: Boolean;
    begin
        // [SCENARIO] Create test with UseExistingTestAnyElseNew behavior, using a production order routing line, creates a new test when no existing test

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] The Create Test Behavior is set to "Use any existing test if available"
        QltyManagementSetup.Get();
        CreateTestBehavior := QltyManagementSetup."Create Test Behavior";
        QltyManagementSetup."Create Test Behavior" := QltyManagementSetup."Create Test Behavior"::"Use any existing test if available";
        QltyManagementSetup.Modify();

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] CreateTest is called when no existing test exists
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);

        QltyManagementSetup."Create Test Behavior" := CreateTestBehavior;
        QltyManagementSetup.Modify();
        QltyInTestGenerationRule.Delete();

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] A new test is created and overall test count increases by 1
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created');
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests to increase by 1.');
    end;

    [Test]
    procedure CreateTestWithVariant()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from production order routing line with variant support

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();
        ClearLastError();

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] CreateTestWithVariant is called with AlwaysCreate set to true
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTestWithVariant(ProdOrderRoutingLineRecordRefRecordRef, true);

        // [THEN] A test is claimed to be created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created.');

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] Overall test count increases by 1 and there is exactly one test for this operation
        LibraryAssert.AreEqual(BeforeCount + 1, AfterCount, 'Expected overall tests count to increase by 1.');
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test has the correct template code
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedQltyInspectionTestHeader);

        QltyInTestGenerationRule.Delete();

        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            CreatedQltyInspectionTestHeader."Template Code",
            'Test generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        // [THEN] The test has the correct document number, item, and template
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'Either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateTestWithVariantAndTemplate()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test using a production order routing line with specified template and variant support

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();
        ClearLastError();

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] CreateTestWithVariantAndTemplate is called with specific template code
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTestWithVariantAndTemplate(ProdOrderRoutingLineRecordRefRecordRef, true, QltyInspectionTemplateHdr.Code);

        // [THEN] A test is claimed to be created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created');

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] Overall test count increases by 1 and there is exactly one test for this operation
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests count to increase by 1.');
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test uses the specified template code
        ReUsableQltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);

        QltyInTestGenerationRule.Delete();

        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            QltyInspectionTestHeader."Template Code",
            'Test generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        // [THEN] The test has the correct document number, item, and template
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'Either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateTestWithMultiVariants()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProductionTrigger: Integer;
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Creates a quality inspection test with multiple variants from production output

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] Production trigger is disabled temporarily
        QltyManagementSetup.Get();
        ProductionTrigger := QltyManagementSetup."Production Trigger";
        QltyManagementSetup."Production Trigger" := 0; // NoTrigger
        QltyManagementSetup.Modify();

        // [GIVEN] A production order line is created and output is posted
        CreateProdOrderLineAndPostOutput(Item, ProdProductionOrder, ProdOrderLine, 1, ItemJournalLine);

        OutputItemLedgerEntry.SetRange("Entry Type", OutputItemLedgerEntry."Entry Type"::Output);
        OutputItemLedgerEntry.SetRange("Order Type", OutputItemLedgerEntry."Order Type"::Production);
        OutputItemLedgerEntry.SetRange("Document No.", ProdProductionOrder."No.");
        OutputItemLedgerEntry.SetRange("Item No.", Item."No.");
        OutputItemLedgerEntry.FindFirst();

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();
        ClearLastError();

        // [WHEN] CreateTestWithMultiVariants is called with the production output
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(ProdOrderRoutingLine, OutputItemLedgerEntry, ItemJournalLine, ProdOrderLine, false, '');
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedQltyInspectionTestHeader);

        QltyManagementSetup."Production Trigger" := ProductionTrigger;
        QltyInTestGenerationRule.Delete();
        QltyManagementSetup.Modify();

        // [THEN] A test is claimed to be created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created.');

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] Overall test count increases by 1 and there is exactly one test for this operation
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests');
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test has the correct template code
        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            CreatedQltyInspectionTestHeader."Template Code",
            'Test generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        // [THEN] The test has the correct document number, item, and template
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'Either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateTestWithMultiVariants_2ndVariant()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        UnusedVariant1: Variant;
        ProductionTrigger: Enum "Qlty. Production Trigger";
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from production output using the 2nd variant parameter

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] Production trigger is disabled temporarily
        QltyManagementSetup.Get();
        ProductionTrigger := QltyManagementSetup."Production Trigger";
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
        QltyManagementSetup.Modify();

        // [GIVEN] A production order line is created and output is posted
        CreateProdOrderLineAndPostOutput(Item, ProdProductionOrder, ProdOrderLine, 1, ItemJournalLine);

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();
        ClearLastError();

        // [WHEN] CreateTestWithMultiVariants is called with 2nd variant (ProdOrderRoutingLine) provided
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(UnusedVariant1, ProdOrderRoutingLine, ItemJournalLine, ProdOrderLine, false, '');
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedQltyInspectionTestHeader);
        QltyManagementSetup."Production Trigger" := ProductionTrigger;
        QltyManagementSetup.Modify();
        QltyInTestGenerationRule.Delete();

        // [THEN] A test is claimed to be created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created.');

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] Overall test count increases by 1 and there is exactly one test for this operation
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests to increase by 1.');
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test has the correct template code and item
        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            CreatedQltyInspectionTestHeader."Template Code",
            'Test generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'Either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateTestWithMultiVariants_3rdVariant()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        ProductionTrigger: Enum "Qlty. Production Trigger";
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from production output using the 3rd variant parameter

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] Production trigger is disabled temporarily
        QltyManagementSetup.Get();
        ProductionTrigger := QltyManagementSetup."Production Trigger";
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
        QltyManagementSetup.Modify();

        // [GIVEN] A production order line is created and output is posted
        CreateProdOrderLineAndPostOutput(Item, ProdProductionOrder, ProdOrderLine, 1, ItemJournalLine);

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();
        ClearLastError();

        // [WHEN] CreateTestWithMultiVariants is called with 3rd variant (ProdOrderRoutingLine) provided
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(UnusedVariant1, UnusedVariant2, ProdOrderRoutingLine, ProdOrderLine, false, '');
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedQltyInspectionTestHeader);

        QltyManagementSetup."Production Trigger" := ProductionTrigger;
        QltyManagementSetup.Modify();
        QltyInTestGenerationRule.Delete();

        // [THEN] A test is claimed to be created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created.');

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] Overall test count increases by 1 if not triggered on output post
        if QltyManagementSetup."Production Trigger" <> QltyManagementSetup."Production Trigger"::OnProductionOutputPost then
            LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests to increase by 1.');
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");

        // [THEN] There is exactly one test for this operation with correct template
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'There should be exactly one test for this operation.');

        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            CreatedQltyInspectionTestHeader."Template Code",
            'Test generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'Either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateTestWithMultiVariants_4thVariant()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        UnusedVariant3: Variant;
        ProductionTrigger: Enum "Qlty. Production Trigger";
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from production output using the 4th variant parameter

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] Production trigger is disabled temporarily
        QltyManagementSetup.Get();
        ProductionTrigger := QltyManagementSetup."Production Trigger";
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
        QltyManagementSetup.Modify();

        // [GIVEN] A production order line is created and output is posted
        CreateProdOrderLineAndPostOutput(Item, ProdProductionOrder, ProdOrderLine, 1, ItemJournalLine);

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();
        ClearLastError();

        // [WHEN] CreateTestWithMultiVariants is called with 4th variant (ProdOrderRoutingLine) provided
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(UnusedVariant1, UnusedVariant2, UnusedVariant3, ProdOrderRoutingLine, false, '');
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedQltyInspectionTestHeader);

        QltyManagementSetup."Production Trigger" := ProductionTrigger;
        QltyManagementSetup.Modify();
        QltyInTestGenerationRule.Delete();

        // [THEN] A test is claimed to be created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been created');

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] Overall test count increases by 1 and there is exactly one test for this operation
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests');
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test has the correct template code and item
        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            CreatedQltyInspectionTestHeader."Template Code",
            'Test generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateTestWithMultiVariantsAndTemplate()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProductionTrigger: Enum "Qlty. Production Trigger";
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from production output with specified template using variant parameters

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] Production trigger is disabled temporarily
        QltyManagementSetup.Get();
        ProductionTrigger := QltyManagementSetup."Production Trigger";
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
        QltyManagementSetup.Modify();

        // [GIVEN] A production order line is created and output is posted
        CreateProdOrderLineAndPostOutput(Item, ProdProductionOrder, ProdOrderLine, 1, ItemJournalLine);

        // [GIVEN] An output item ledger entry is found for the production order
        OutputItemLedgerEntry.SetRange("Entry Type", OutputItemLedgerEntry."Entry Type"::Output);
        OutputItemLedgerEntry.SetRange("Order Type", OutputItemLedgerEntry."Order Type"::Production);
        OutputItemLedgerEntry.SetRange("Document No.", ProdProductionOrder."No.");
        OutputItemLedgerEntry.SetRange("Item No.", Item."No.");
        OutputItemLedgerEntry.FindFirst();

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();
        ClearLastError();

        // [WHEN] CreateTestWithMultiVariantsAndTemplate is called with specific template code
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(ProdOrderRoutingLine, OutputItemLedgerEntry, ItemJournalLine, ProdOrderLine, false, QltyInspectionTemplateHdr.Code);

        QltyManagementSetup."Production Trigger" := ProductionTrigger;
        QltyManagementSetup.Modify();
        QltyInTestGenerationRule.Delete();

        // [THEN] A test is claimed to be created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created');

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] Overall test count increases by 1 and there is exactly one test for this operation
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests');
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test uses the specified template code
        ReUsableQltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);

        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            QltyInspectionTestHeader."Template Code",
            'Test generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        // [THEN] The test has the correct document number, item, and template
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'Either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateTestWithMultiVariantsAndTemplate_NoGenRule()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        ProductionTrigger: Enum "Qlty. Production Trigger";
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test from production output with specified template when no generation rule exists

        Initialize();

        // [GIVEN] Quality inspection setup is initialized
        QltyTestsUtility.EnsureSetup();
        QltyManagementSetup.Get();
        // [GIVEN] Production trigger is disabled temporarily
        ProductionTrigger := QltyManagementSetup."Production Trigger";
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
        QltyManagementSetup.Modify();
        // [GIVEN] A quality inspection template is created
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        // [GIVEN] An item and production order with routing line are created
        QltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A production order line is created and output is posted
        CreateProdOrderLineAndPostOutput(Item, ProdProductionOrder, ProdOrderLine, 1, ItemJournalLine);

        // [GIVEN] The output item ledger entry is found for the production order
        OutputItemLedgerEntry.SetRange("Entry Type", OutputItemLedgerEntry."Entry Type"::Output);
        OutputItemLedgerEntry.SetRange("Order Type", OutputItemLedgerEntry."Order Type"::Production);
        OutputItemLedgerEntry.SetRange("Document No.", ProdProductionOrder."No.");
        OutputItemLedgerEntry.SetRange("Item No.", Item."No.");
        OutputItemLedgerEntry.FindFirst();

        // [GIVEN] The initial test count is recorded
        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();
        ClearLastError();

        // [WHEN] CreateTestWithMultiVariantsAndTemplate is called with specific template code (no generation rule scenario)
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(ProdOrderRoutingLine, OutputItemLedgerEntry, ItemJournalLine, ProdOrderLine, false, QltyInspectionTemplateHdr.Code);

        QltyManagementSetup."Production Trigger" := ProductionTrigger;
        QltyManagementSetup.Modify();

        // [THEN] A test is claimed to be created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created.');

        // [THEN] Overall test count increases by 1 and there is exactly one test for this operation
        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests');
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test uses the specified template code even without a generation rule
        ReUsableQltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            QltyInspectionTestHeader."Template Code",
            'Test generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        // [THEN] The test has the correct document number, item, and template
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'Either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateTestWithSpecificTemplate()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection test using a specified template code from production order routing line
        Initialize();

        // [GIVEN] A production order with routing line is set up with a test template and generation rule
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] The initial test count is captured
        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();
        ClearLastError();

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] CreateTestWithSpecificTemplate is called with the template code
        // [WHEN] CreateTestWithSpecificTemplate is called with the template code
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTestWithSpecificTemplate(ProdOrderRoutingLineRecordRefRecordRef, true, QltyInspectionTemplateHdr.Code);

        QltyInTestGenerationRule.Delete();

        // [THEN] The test creation is confirmed successful
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created.');

        QltyInspectionTestHeader.Reset();
        AfterCount := QltyInspectionTestHeader.Count();

        // [THEN] The overall test count increases by one
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests');

        // [THEN] Exactly one test exists for this production order operation
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test uses the specified template code
        ReUsableQltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            QltyInspectionTestHeader."Template Code",
            'Test generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        // [THEN] The test is correctly associated with the production order, item, and template
        QltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionTestHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionTestHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'Either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateTestWithSpecificTemplate_NoGenRuleOrTemplate_ShouldError()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        InspectionSecondQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
    begin
        // [SCENARIO] Verify error when creating test with specific template but generation rule and template do not exist

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] All generation rules are deleted
        QltyInTestGenerationRule.DeleteAll();
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] CreateTestWithSpecificTemplate is called with a non-existent template code
        asserterror ReUsableQltyInspectionTestCreate.CreateTestWithSpecificTemplate(ProdOrderRoutingLineRecordRefRecordRef, true, InspectionSecondQltyInspectionTemplateHdr.Code);

        // [THEN] An error is raised indicating the template cannot be found
        LibraryAssert.ExpectedError(StrSubstNo(CannotFindTemplateErr, Format(ProdOrderRoutingLineRecordRefRecordRef.RecordId())));
    end;

    [Test]
    procedure FindExistingTestWithVariant_FindAll_ShouldNotFind()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        Item: Record Item;
        TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        UnusedVariant3: Variant;
        FoundTest: Boolean;
    begin
        // [SCENARIO] Verify no tests are found when searching for nonexistent tests with FindAll option

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        QltyInspectionTestHeader.Reset();
        ClearLastError();

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] FindExistingTestWithVariant is called with FindAll=true when no tests exist
        FoundTest := ReUsableQltyInspectionTestCreate.FindExistingTestWithVariant(ProdOrderRoutingLineRecordRefRecordRef, UnusedVariant1, UnusedVariant2, UnusedVariant3, TempQltyInTestGenerationRule, FoundQltyInspectionTestHeader, true);

        QltyInTestGenerationRule.Delete();

        // [THEN] No test is found and the count is zero
        LibraryAssert.IsFalse(FoundTest, 'Should not find any tests.');
        LibraryAssert.AreEqual(0, FoundQltyInspectionTestHeader.Count(), 'There should not be any tests found.');
    end;

    [Test]
    procedure FindExistingTestWithVariant_FindAll()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ReQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        Item: Record Item;
        TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        UnusedVariant3: Variant;
        FoundTest: Boolean;
    begin
        // [SCENARIO] Retrieve all existing tests including retests when FindAll is true. Uses a production order routing line and a retest. Should find both tests.

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A test is created with a retest
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        ReUsableQltyInspectionTestCreate.CreateTestWithSpecificTemplate(ProdOrderRoutingLineRecordRefRecordRef, true, QltyInspectionTemplateHdr.Code);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);

        ReUsableQltyInspectionTestCreate.CreateRetest(QltyInspectionTestHeader, ReQltyInspectionTestHeader);

        Clear(FoundQltyInspectionTestHeader);

        // [WHEN] FindExistingTestWithVariant is called with FindAll=true
        FoundTest := ReUsableQltyInspectionTestCreate.FindExistingTestWithVariant(ProdOrderRoutingLineRecordRefRecordRef, UnusedVariant1, UnusedVariant2, UnusedVariant3, TempQltyInTestGenerationRule, FoundQltyInspectionTestHeader, true);
        QltyInTestGenerationRule.Delete();

        // [THEN] Both tests are found
        LibraryAssert.IsTrue(FoundTest, 'Should claim test found.');
        LibraryAssert.AreEqual(2, FoundQltyInspectionTestHeader.Count(), 'There should be exactly two tests found.');
    end;

    [Test]
    procedure FindExistingTestWithVariant_FindLast_ShouldNotFind()
    var
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        Item: Record Item;
        TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        UnusedVariant3: Variant;
        FoundTest: Boolean;
    begin
        // [SCENARIO] Verify no test is found when searching for nonexistent test with FindAll=false

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] FindExistingTestWithVariant is called with FindAll=false when no tests exist
        FoundTest := ReUsableQltyInspectionTestCreate.FindExistingTestWithVariant(ProdOrderRoutingLineRecordRefRecordRef, UnusedVariant1, UnusedVariant2, UnusedVariant3, TempQltyInTestGenerationRule, FoundQltyInspectionTestHeader, false);
        QltyInTestGenerationRule.Delete();

        // [THEN] No test is found and the count is zero
        LibraryAssert.IsFalse(FoundTest, 'Should not find any tests.');
        LibraryAssert.AreEqual(0, FoundQltyInspectionTestHeader.Count(), 'There should not be any tests found.');
    end;

    [Test]
    procedure FindExistingTestWithVariant_FindLast()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ReQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        Item: Record Item;
        TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        UnusedVariant3: Variant;
        FoundTest: Boolean;
    begin
        // [SCENARIO] Retrieve only the last test created when FindAll is false. Uses a production order routing line and a retest to ensure it only finds the last test created.

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A test is created with a retest
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        ReUsableQltyInspectionTestCreate.CreateTestWithSpecificTemplate(ProdOrderRoutingLineRecordRefRecordRef, true, QltyInspectionTemplateHdr.Code);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);

        ReUsableQltyInspectionTestCreate.CreateRetest(QltyInspectionTestHeader, ReQltyInspectionTestHeader);

        // [WHEN] FindExistingTestWithVariant is called with FindAll=false
        FoundTest := ReUsableQltyInspectionTestCreate.FindExistingTestWithVariant(ProdOrderRoutingLineRecordRefRecordRef, UnusedVariant1, UnusedVariant2, UnusedVariant3, TempQltyInTestGenerationRule, FoundQltyInspectionTestHeader, false);
        QltyInTestGenerationRule.Delete();

        // [THEN] Only the last created test (the retest) is found
        LibraryAssert.IsTrue(FoundTest, 'Should claim found test.');
        LibraryAssert.AreEqual(ReQltyInspectionTestHeader."Retest No.", FoundQltyInspectionTestHeader."Retest No.", 'The found test should match the last created test.');
    end;

    [Test]
    procedure FindExistingTestsWithVariant_ShouldNotFind()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        FoundTest: Boolean;
    begin
        // [SCENARIO] Verify no tests are found when searching for nonexistent tests

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [WHEN] FindExistingTestsWithVariant is called when no tests exist
        FoundTest := ReUsableQltyInspectionTestCreate.FindExistingTestsWithVariant(false, ProdOrderRoutingLine, FoundQltyInspectionTestHeader);
        QltyInTestGenerationRule.Delete();

        // [THEN] No test is found and the count matches the total test count
        LibraryAssert.IsFalse(FoundTest, 'Should not find any tests.');
        LibraryAssert.AreEqual(QltyInspectionTestHeader.Count(), FoundQltyInspectionTestHeader.Count(), 'There should not be any tests found.');
    end;

    [Test]
    procedure FindExistingTestsWithVariant()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
    begin
        // [SCENARIO] Retrieve an existing test when one exists for the production order routing line

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A test is created for the production order routing line
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        ReUsableQltyInspectionTestCreate.CreateTestWithSpecificTemplate(ProdOrderRoutingLineRecordRefRecordRef, true, QltyInspectionTemplateHdr.Code);
        ReUsableQltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);

        // [WHEN] FindExistingTestsWithVariant is called with the routing line
        ReUsableQltyInspectionTestCreate.FindExistingTestsWithVariant(false, ProdOrderRoutingLine, FoundQltyInspectionTestHeader);
        QltyInTestGenerationRule.Delete();

        // [THEN] Exactly one test is found with the correct test number
        LibraryAssert.AreEqual(1, FoundQltyInspectionTestHeader.Count(), 'There should be exactly one test found.');
        LibraryAssert.AreEqual(QltyInspectionTestHeader."No.", FoundQltyInspectionTestHeader."No.", 'Should find the correct test.');
    end;

    [Test]
    procedure FindExistingTestsWithVariant_ErrorNoGenRule()
    var
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
    begin
        // [SCENARIO] Verify error when no generation rule exists and ThrowError is true

        // [GIVEN] Quality Management setup is initialized and a template is created
        Initialize();
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);

        // [GIVEN] All generation rules are deleted
        QltyInTestGenerationRule.DeleteAll();

        // [WHEN] FindExistingTestsWithVariant is called with ThrowError=true
        asserterror ReUsableQltyInspectionTestCreate.FindExistingTestsWithVariant(true, ProdOrderRoutingLine, FoundQltyInspectionTestHeader);

        // [THEN] An error is raised indicating the template cannot be found
        LibraryAssert.ExpectedError(StrSubstNo(CannotFindTemplateErr, ProdOrderRoutingLine.RecordId()));
    end;

    [Test]
    procedure FindExistingTestsWithMultipleVariants_ErrorVariant()
    var
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
    begin
        // [SCENARIO] Verify error when an invalid variant is provided to search function

        // [GIVEN] Quality Management setup is initialized and a template is created
        Initialize();
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);

        // [WHEN] FindExistingTestsWithMultipleVariants is called with an empty string variant
        asserterror ReUsableQltyInspectionTestCreate.FindExistingTestsWithMultipleVariants(true, '', ProdOrderRoutingLine, OutputItemLedgerEntry, ItemJournalLine, FoundQltyInspectionTestHeader);

        // [THEN] An error is raised indicating the variant is not a valid RecordRef
        LibraryAssert.ExpectedError(StrSubstNo(ProgrammerErrNotARecordRefErr, ''));
    end;

    [Test]
    procedure FindExistingTestsWithMultipleVariants_ErrorNoGenRule()
    var
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdOrderLine: Record "Prod. Order Line";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
    begin
        // [SCENARIO] Verify error when no generation rule exists and ThrowError is true

        // [GIVEN] Quality Management setup is initialized and a template is created
        Initialize();
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);

        // [GIVEN] All generation rules are deleted
        QltyInTestGenerationRule.DeleteAll();

        // [WHEN] FindExistingTestsWithMultipleVariants is called with ThrowError=true
        asserterror ReUsableQltyInspectionTestCreate.FindExistingTestsWithMultipleVariants(true, ProdOrderRoutingLine, OutputItemLedgerEntry, ItemJournalLine, ProdOrderLine, FoundQltyInspectionTestHeader);

        // [THEN] An error is raised indicating the template cannot be found
        LibraryAssert.ExpectedError(StrSubstNo(CannotFindTemplateErr, ProdOrderRoutingLine.RecordId()));
    end;

    [Test]
    procedure FindExistingTestsWithMultipleVariants()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        ProductionTrigger: Enum "Qlty. Production Trigger";
        FoundTest: Boolean;
    begin
        // [SCENARIO] Retrieve an existing test created from production output with multiple variants

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] Production trigger is disabled temporarily
        QltyManagementSetup.Get();
        ProductionTrigger := QltyManagementSetup."Production Trigger";
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
        QltyManagementSetup.Modify();

        // [GIVEN] A production order line is created and output is posted
        QltyProdOrderGenerator.CreateProdOrderLine(ProdProductionOrder, Item, 1, ProdOrderLine);
        CreateProdOrderLineAndPostOutput(Item, ProdProductionOrder, ProdOrderLine, 1, ItemJournalLine);

        OutputItemLedgerEntry.SetRange("Entry Type", OutputItemLedgerEntry."Entry Type"::Output);
        OutputItemLedgerEntry.SetRange("Order Type", OutputItemLedgerEntry."Order Type"::Production);
        OutputItemLedgerEntry.SetRange("Document No.", ProdProductionOrder."No.");
        OutputItemLedgerEntry.SetRange("Item No.", Item."No.");
        OutputItemLedgerEntry.FindFirst();

        QltyInspectionTestHeader.Reset();
        ClearLastError();

        // [GIVEN] A test is created with multiple variants from the production output
        ReUsableQltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(ProdOrderRoutingLine, OutputItemLedgerEntry, ItemJournalLine, ProdOrderLine, false, '');
        ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedQltyInspectionTestHeader);

        // [WHEN] FindExistingTestsWithMultipleVariants is called with the same variants
        FoundTest := ReUsableQltyInspectionTestCreate.FindExistingTestsWithMultipleVariants(false, ProdOrderRoutingLine, OutputItemLedgerEntry, ItemJournalLine, ProdOrderLine, FoundQltyInspectionTestHeader);

        QltyManagementSetup."Production Trigger" := ProductionTrigger;
        QltyManagementSetup.Modify();
        QltyInTestGenerationRule.Delete();

        // [THEN] The test is found with the correct test number
        LibraryAssert.IsTrue(FoundTest, 'Should have found tests.');
        LibraryAssert.AreEqual(1, FoundQltyInspectionTestHeader.Count(), 'The search did not find the correct number of tests.');
        LibraryAssert.AreEqual(CreatedQltyInspectionTestHeader."No.", FoundQltyInspectionTestHeader."No.", 'The found test should match the created test.');
    end;

    [Test]
    procedure FindExistingTestsWithMultipleVariants_ShouldNotFind()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        BeforeCount: Integer;
        FoundTest: Boolean;
    begin
        // [SCENARIO] Verify no tests are found when searching for nonexistent tests with multiple variants

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A production order line is created and output is posted
        CreateProdOrderLineAndPostOutput(Item, ProdProductionOrder, ProdOrderLine, 1, ItemJournalLine);

        OutputItemLedgerEntry.SetRange("Entry Type", OutputItemLedgerEntry."Entry Type"::Output);
        OutputItemLedgerEntry.SetRange("Order Type", OutputItemLedgerEntry."Order Type"::Production);
        OutputItemLedgerEntry.SetRange("Document No.", ProdProductionOrder."No.");
        OutputItemLedgerEntry.SetRange("Item No.", Item."No.");
        OutputItemLedgerEntry.FindFirst();

        QltyInspectionTestHeader.Reset();
        BeforeCount := QltyInspectionTestHeader.Count();
        ClearLastError();

        // [WHEN] FindExistingTestsWithMultipleVariants is called when no tests have been created
        ReUsableQltyInspectionTestCreate.FindExistingTestsWithMultipleVariants(false, ProdOrderRoutingLine, OutputItemLedgerEntry, ItemJournalLine, ProdOrderLine, FoundQltyInspectionTestHeader);
        QltyInTestGenerationRule.Delete();

        // [THEN] No test is found and the count matches the initial count
        LibraryAssert.IsFalse(FoundTest, 'There should not be any tests found.');
        LibraryAssert.AreEqual(BeforeCount, FoundQltyInspectionTestHeader.Count(), 'There should not be any tests found.');
    end;

    [Test]
    procedure FindExistingTests_StandardSource()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyManagementSetup: Record "Qlty. Management Setup";
        PurOrdPurchaseLine: Record "Purchase Line";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        PurchaseLineRecordRef: RecordRef;
        TrackingSpecificationRecordRef: RecordRef;
        Optional3RecordRef: RecordRef;
        Optional4RecordRef: RecordRef;
        FindBehavior: Enum "Qlty. Find Existing Behavior";
        TestFound: Boolean;
    begin
        // [SCENARIO] Find an existing test from a purchase order for a lot-tracked item, by searching using standard source fields matching

        // [GIVEN] A purchase order with a lot-tracked item is set up
        Initialize();
        SetupCreateTestPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Standard Source Fields"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Standard Source Fields";
        QltyManagementSetup.Modify();

        // [GIVEN] A quality inspection test is created with tracking
        CreateTestWithTracking(PurOrdPurchaseLine, TempSpecTrackingSpecification, QltyInspectionTestHeader);

        // [WHEN] FindExistingTests is called with the purchase line and tracking specification
        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);
        TestFound := ReUsableQltyInspectionTestCreate.FindExistingTests(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionTestHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] The test is found successfully
        LibraryAssert.IsTrue(TestFound, 'Should find tests.');
        // [THEN] Exactly one test is found
        LibraryAssert.AreEqual(1, FoundQltyInspectionTestHeader.Count(), 'Should find exact number of tests.');
        // [THEN] The found test matches the created test
        LibraryAssert.AreEqual(FoundQltyInspectionTestHeader."No.", QltyInspectionTestHeader."No.", 'Should find the correct test.');
    end;

    [Test]
    procedure FindExistingTests_BySourceRecord()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyManagementSetup: Record "Qlty. Management Setup";
        PurOrdPurchaseLine: Record "Purchase Line";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        PurchaseLineRecordRef: RecordRef;
        TrackingSpecificationRecordRef: RecordRef;
        Optional3RecordRef: RecordRef;
        Optional4RecordRef: RecordRef;
        FindBehavior: Enum "Qlty. Find Existing Behavior";
        TestFound: Boolean;
    begin
        // [SCENARIO] Find an existing test from a purchase order for a lot-tracked item, by searching using source record matching

        // [GIVEN] A purchase order with a lot-tracked item is set up
        Initialize();
        SetupCreateTestPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Source Record"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Source Record";
        QltyManagementSetup.Modify();

        // [GIVEN] A quality inspection test is created with tracking
        CreateTestWithTracking(PurOrdPurchaseLine, TempSpecTrackingSpecification, QltyInspectionTestHeader);

        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);

        // [WHEN] FindExistingTests is called with the source record
        TestFound := ReUsableQltyInspectionTestCreate.FindExistingTests(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionTestHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] The test is found successfully
        LibraryAssert.IsTrue(TestFound, 'Should find tests.');

        // [THEN] Exactly one test is found
        LibraryAssert.AreEqual(1, FoundQltyInspectionTestHeader.Count(), 'Should find exact number of tests.');

        // [THEN] The found test matches the created test
        LibraryAssert.AreEqual(FoundQltyInspectionTestHeader."No.", QltyInspectionTestHeader."No.", 'Should find the correct test.');
    end;

    [Test]
    procedure FindExistingTests_BySourceRecord_NoGenRule()
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyManagementSetup: Record "Qlty. Management Setup";
        PurOrdPurchaseLine: Record "Purchase Line";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        PurchaseLineRecordRef: RecordRef;
        TrackingSpecificationRecordRef: RecordRef;
        Optional3RecordRef: RecordRef;
        Optional4RecordRef: RecordRef;
        FindBehavior: Enum "Qlty. Find Existing Behavior";
        TestFound: Boolean;
    begin
        // [SCENARIO] Find an existing test from a purchase order for a lot-tracked item, by source record matching even when no generation rule exists

        // [GIVEN] A purchase order with a lot-tracked item is set up
        Initialize();
        SetupCreateTestPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Source Record"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Source Record";
        QltyManagementSetup.Modify();

        // [GIVEN] A quality inspection test is created with tracking
        CreateTestWithTracking(PurOrdPurchaseLine, TempSpecTrackingSpecification, QltyInspectionTestHeader);

        // [GIVEN] All generation rules are deleted
        if not QltyInTestGenerationRule.IsEmpty() then
            QltyInTestGenerationRule.DeleteAll();

        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);

        // [WHEN] FindExistingTests is called with the source record
        // [WHEN] FindExistingTests is called with the source record
        TestFound := ReUsableQltyInspectionTestCreate.FindExistingTests(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionTestHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] The test is found successfully
        LibraryAssert.IsTrue(TestFound, 'Should find tests.');

        // [THEN] Exactly one test is found
        LibraryAssert.AreEqual(1, FoundQltyInspectionTestHeader.Count(), 'Should find exact number of tests.');

        // [THEN] The found test matches the created test
        LibraryAssert.AreEqual(FoundQltyInspectionTestHeader."No.", QltyInspectionTestHeader."No.", 'Should find the correct test.');
    end;

    [Test]
    procedure FindExistingTests_ByTracking()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyManagementSetup: Record "Qlty. Management Setup";
        PurOrdPurchaseLine: Record "Purchase Line";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        PurchaseLineRecordRef: RecordRef;
        TrackingSpecificationRecordRef: RecordRef;
        Optional3RecordRef: RecordRef;
        Optional4RecordRef: RecordRef;
        FindBehavior: Enum "Qlty. Find Existing Behavior";
        TestFound: Boolean;
    begin
        // [SCENARIO] Find an existing test from a purchase order for a lot-tracked item, by searching using item tracking information

        // [GIVEN] A purchase order with a lot-tracked item is set up
        Initialize();
        SetupCreateTestPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Item Tracking"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Item Tracking";
        QltyManagementSetup.Modify();

        // [GIVEN] A quality inspection test is created with tracking
        CreateTestWithTracking(PurOrdPurchaseLine, TempSpecTrackingSpecification, QltyInspectionTestHeader);

        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);

        // [WHEN] FindExistingTests is called with item tracking
        // [WHEN] FindExistingTests is called with item tracking
        TestFound := ReUsableQltyInspectionTestCreate.FindExistingTests(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionTestHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] The test is found successfully
        LibraryAssert.IsTrue(TestFound, 'Should find tests.');

        // [THEN] Exactly one test is found
        LibraryAssert.AreEqual(1, FoundQltyInspectionTestHeader.Count(), 'Should find exact number of tests.');

        // [THEN] The found test matches the created test
        LibraryAssert.AreEqual(FoundQltyInspectionTestHeader."No.", QltyInspectionTestHeader."No.", 'Should find the correct test.');
    end;

    [Test]
    procedure FindExistingTests_ByDocumentAndItemOnly()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyManagementSetup: Record "Qlty. Management Setup";
        PurOrdPurchaseLine: Record "Purchase Line";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        PurchaseLineRecordRef: RecordRef;
        TrackingSpecificationRecordRef: RecordRef;
        Optional3RecordRef: RecordRef;
        Optional4RecordRef: RecordRef;
        FindBehavior: Enum "Qlty. Find Existing Behavior";
        TestFound: Boolean;
    begin
        // [SCENARIO] Find an existing test from a purchase order for a lot-tracked item, by searching using document and item only

        // [GIVEN] A purchase order with a lot-tracked item is set up
        Initialize();
        SetupCreateTestPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Document and Item only"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Document and Item only";
        QltyManagementSetup.Modify();

        // [GIVEN] A quality inspection test is created with tracking
        CreateTestWithTracking(PurOrdPurchaseLine, TempSpecTrackingSpecification, QltyInspectionTestHeader);

        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);

        // [WHEN] FindExistingTests is called with document and item information
        TestFound := ReUsableQltyInspectionTestCreate.FindExistingTests(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionTestHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] The test is found successfully
        LibraryAssert.IsTrue(TestFound, 'Should find tests.');

        // [THEN] Exactly one test is found
        LibraryAssert.AreEqual(1, FoundQltyInspectionTestHeader.Count(), 'Should find exact number of tests.');

        // [THEN] The found test matches the created test
        LibraryAssert.AreEqual(FoundQltyInspectionTestHeader."No.", QltyInspectionTestHeader."No.", 'Should find the correct test.');
    end;

    [Test]
    procedure FindExistingTests_StandardSource_ShouldNotFind()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyManagementSetup: Record "Qlty. Management Setup";
        PurOrdPurchaseLine: Record "Purchase Line";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        PurchaseLineRecordRef: RecordRef;
        TrackingSpecificationRecordRef: RecordRef;
        Optional3RecordRef: RecordRef;
        Optional4RecordRef: RecordRef;
        FindBehavior: Enum "Qlty. Find Existing Behavior";
        TestFound: Boolean;
    begin
        // [SCENARIO] Verify no tests are found when searching for nonexistent tests using standard source fields search

        // [GIVEN] A purchase order with a lot-tracked item is set up
        Initialize();
        SetupCreateTestPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Standard Source Fields"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Standard Source Fields";
        QltyManagementSetup.Modify();

        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);

        // [WHEN] FindExistingTests is called before any test is created
        TestFound := ReUsableQltyInspectionTestCreate.FindExistingTests(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionTestHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        TestFound := ReUsableQltyInspectionTestCreate.FindExistingTests(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionTestHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] No test is found
        LibraryAssert.IsFalse(TestFound, 'Should not find any tests.');

        // [THEN] The count of found tests matches the initial count (zero)
        LibraryAssert.AreEqual(QltyInspectionTestHeader.Count(), FoundQltyInspectionTestHeader.Count(), 'Should not find any tests.');
    end;

    [Test]
    procedure FindExistingTests_BySourceRecord_ShouldNotFind()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyManagementSetup: Record "Qlty. Management Setup";
        PurOrdPurchaseLine: Record "Purchase Line";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        PurchaseLineRecordRef: RecordRef;
        TrackingSpecificationRecordRef: RecordRef;
        Optional3RecordRef: RecordRef;
        Optional4RecordRef: RecordRef;
        FindBehavior: Enum "Qlty. Find Existing Behavior";
        TestFound: Boolean;
    begin
        // [SCENARIO] Verify no tests are found when searching for nonexistent tests using source record search

        // [GIVEN] A purchase order with a lot-tracked item is set up
        Initialize();
        SetupCreateTestPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Source Record"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Source Record";
        QltyManagementSetup.Modify();

        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);

        // [WHEN] FindExistingTests is called before any test is created
        TestFound := ReUsableQltyInspectionTestCreate.FindExistingTests(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionTestHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] No test is found
        LibraryAssert.IsFalse(TestFound, 'Should not find any tests.');
        LibraryAssert.AreEqual(QltyInspectionTestHeader.Count(), FoundQltyInspectionTestHeader.Count(), 'Should not find any tests.');
    end;

    [Test]
    procedure FindExistingTests_ByTracking_ShouldNotFind()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyManagementSetup: Record "Qlty. Management Setup";
        PurOrdPurchaseLine: Record "Purchase Line";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        PurchaseLineRecordRef: RecordRef;
        TrackingSpecificationRecordRef: RecordRef;
        Optional3RecordRef: RecordRef;
        Optional4RecordRef: RecordRef;
        FindBehavior: Enum "Qlty. Find Existing Behavior";
        TestFound: Boolean;
    begin
        // [SCENARIO] Verify no tests are found when searching for nonexistent tests using item tracking search

        // [GIVEN] A purchase order with a lot-tracked item is set up
        Initialize();
        SetupCreateTestPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Item Tracking"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Item Tracking";
        QltyManagementSetup.Modify();

        // [WHEN] FindExistingTests is called before any test is created
        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);
        TestFound := ReUsableQltyInspectionTestCreate.FindExistingTests(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionTestHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] No test is found
        LibraryAssert.IsFalse(TestFound, 'Should not find any tests.');
        // [THEN] The count of found tests matches the initial count (zero)
        LibraryAssert.AreEqual(QltyInspectionTestHeader.Count(), FoundQltyInspectionTestHeader.Count(), 'Should not find any tests.');
    end;

    [Test]
    procedure FindExistingTests_ByDocAndItemOnly_ShouldNotFind()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FoundQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyManagementSetup: Record "Qlty. Management Setup";
        PurOrdPurchaseLine: Record "Purchase Line";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        PurchaseLineRecordRef: RecordRef;
        TrackingSpecificationRecordRef: RecordRef;
        Optional3RecordRef: RecordRef;
        Optional4RecordRef: RecordRef;
        FindBehavior: Enum "Qlty. Find Existing Behavior";
        TestFound: Boolean;
    begin
        // [SCENARIO] Verify no tests are found when searching for nonexistent tests using document and item only search

        // [GIVEN] A purchase order with a lot-tracked item is set up
        Initialize();
        SetupCreateTestPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Document and Item only"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Document and Item only";
        QltyManagementSetup.Modify();

        // [WHEN] FindExistingTests is called before any test is created
        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);
        TestFound := ReUsableQltyInspectionTestCreate.FindExistingTests(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionTestHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] No test is found
        LibraryAssert.IsFalse(TestFound, 'Should not find any tests.');
        // [THEN] The count of found tests matches the initial count (zero)
        LibraryAssert.AreEqual(QltyInspectionTestHeader.Count(), FoundQltyInspectionTestHeader.Count(), 'Should not find any tests.');
    end;

    [Test]
    procedure CreateRetest()
    var
        Item: Record Item;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ReQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        ClaimedATestWasFoundOrCreated: Boolean;
    begin
        // [SCENARIO] Create a retest for an existing quality inspection test

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        Initialize();
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A test is created from the production order routing line
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been created');

        // [GIVEN] The created test is retrieved
        ReUsableQltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);

        // [WHEN] CreateRetest is called with the existing test
        ReUsableQltyInspectionTestCreate.CreateRetest(QltyInspectionTestHeader, ReQltyInspectionTestHeader);

        QltyInTestGenerationRule.Delete();

        // [THEN] The retest has the same template code as the original test
        LibraryAssert.AreEqual(QltyInspectionTestHeader."Template Code", ReQltyInspectionTestHeader."Template Code", 'Template does not match.');
        // [THEN] The retest has the same test number as the original test
        LibraryAssert.AreEqual(QltyInspectionTestHeader."No.", ReQltyInspectionTestHeader."No.", 'Test No. does not match.');
        // [THEN] The retest number is incremented by 1
        LibraryAssert.AreEqual((QltyInspectionTestHeader."Retest No." + 1), ReQltyInspectionTestHeader."Retest No.", 'Retest No. did not increment.');
    end;

    [Test]
    procedure GetCreatedTest()
    var
        Item: Record Item;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        ClaimedATestWasFoundOrCreated: Boolean;
        TestStillExists: Boolean;
    begin
        // [SCENARIO] Retrieve the most recently created quality inspection test

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        Initialize();
        SetupCreateTestProductionOrder(QltyInspectionTemplateHdr, QltyInTestGenerationRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A test is created from the production order routing line
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        ClaimedATestWasFoundOrCreated := ReUsableQltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been created');

        // [GIVEN] The last created test is found in the database
        QltyInspectionTestHeader.FindLast();

        // [WHEN] GetCreatedTest is called to retrieve the most recently created test
        TestStillExists := ReUsableQltyInspectionTestCreate.GetCreatedTest(CreatedQltyInspectionTestHeader);

        QltyInTestGenerationRule.Delete();

        // [THEN] The test is confirmed to exist
        LibraryAssert.IsTrue(TestStillExists, 'Test should be said to exist.');
        // [THEN] The retrieved test has the same test number as the last created test
        LibraryAssert.AreEqual(QltyInspectionTestHeader."No.", CreatedQltyInspectionTestHeader."No.", 'Should get the last created test.');
        // [THEN] The retrieved test has the same retest number as the last created test
        LibraryAssert.AreEqual(QltyInspectionTestHeader."Retest No.", CreatedQltyInspectionTestHeader."Retest No.", 'Should get the last created test.');
    end;

    [Test]
    procedure CreateMultipleTestsForMarkedTrackingSpec()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Location: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrder1PurchaseHeader: Record "Purchase Header";
        PurOrderSecondPurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ResReservationEntry: Record "Reservation Entry";
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        asePurchLineReserve: Codeunit "Purch. Line-Reserve";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        CountBefore: Integer;
        CountAfter: Integer;
    begin
        // [SCENARIO] Create quality inspection tests for multiple marked tracking specifications from purchase lines

        // [GIVEN] Quality management setup is initialized
        Initialize();
        QltyTestsUtility.EnsureSetup();
        // [GIVEN] A quality inspection template is created
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        // [GIVEN] A generation rule is created for purchase lines
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);
        // [GIVEN] A location, lot tracking setup, and vendor are created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, '', '');
        LibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A first purchase order is created, released, and received with lot tracking
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, '', PurOrder1PurchaseHeader, PurchaseLine, ResReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrder1PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrder1PurchaseHeader, PurchaseLine);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        // [GIVEN] A tracking specification is created and marked for the first purchase order
        asePurchLineReserve.InitFromPurchLine(TempSpecTrackingSpecification, PurchaseLine);
        TempSpecTrackingSpecification."Entry No." := 1;
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(ResReservationEntry);
        TempSpecTrackingSpecification.Insert();
        TempSpecTrackingSpecification.Mark(true);

        // [GIVEN] A second purchase order is created, released, and received with lot tracking
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, '', PurOrderSecondPurchaseHeader, PurchaseLine, ResReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrder1PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderSecondPurchaseHeader, PurchaseLine);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        // [GIVEN] A tracking specification is created and marked for the second purchase order
        asePurchLineReserve.InitFromPurchLine(TempSpecTrackingSpecification, PurchaseLine);
        TempSpecTrackingSpecification."Entry No." := 2;
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(ResReservationEntry);
        TempSpecTrackingSpecification.Insert();
        TempSpecTrackingSpecification.Mark(true);
        // [GIVEN] The initial test count is recorded
        CountBefore := QltyInspectionTestHeader.Count();

        // [WHEN] CreateMultipleTestsForMarkedTrackingSpecification is called with the marked tracking specifications
        ReUsableQltyInspectionTestCreate.CreateMultipleTestsForMarkedTrackingSpecification(TempSpecTrackingSpecification);
        CountAfter := QltyInspectionTestHeader.Count();

        QltyInTestGenerationRule.Delete();

        // [THEN] Two tests are created (one for each marked tracking specification)
        LibraryAssert.AreEqual((CountBefore + 2), CountAfter, 'The tests should have been created.');
        // [THEN] One test is created for the first purchase order
        QltyInspectionTestHeader.SetRange("Source Document No.", PurOrder1PurchaseHeader."No.");
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'Should have created a test.');
        // [THEN] One test is created for the second purchase order
        QltyInspectionTestHeader.SetRange("Source Document No.", PurOrderSecondPurchaseHeader."No.");
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'Should have created a test.');
    end;

    [Test]
    procedure CreateMultipleTestsForMarkedTrackingSpec_ExistingReservationEntries_TrackingSpec()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Location: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        PreferredOrderPurchaseHeader: Record "Purchase Header";
        NoiseOrderPurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        AllReservationEntry: Record "Reservation Entry";
        LotAndSerialNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotAndSerialItemTrackingCode: Record "Item Tracking Code";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        asePurchLineReserve: Codeunit "Purch. Line-Reserve";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        CountBefore: Integer;
        CountAfter: Integer;
    begin
        // [SCENARIO] Create quality inspection tests for marked tracking specifications with existing reservation entries

        // [GIVEN] The quality management setup is initialized
        Initialize();
        QltyTestsUtility.EnsureSetup();
        // [GIVEN] A quality inspection template with 3 tests and a prioritized generation rule for Purchase Line are created
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);
        // [GIVEN] A WMS location, number series, item tracking code, and lot-tracked item are set up
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        LibraryUtility.CreateNoSeries(LotAndSerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotAndSerialNoSeries.Code, '', '');
        LibraryItemTracking.CreateItemTrackingCode(LotAndSerialItemTrackingCode, true, true, false);
        LibraryInventory.CreateTrackedItem(Item, LotAndSerialNoSeries.Code, LotAndSerialNoSeries.Code, LotAndSerialItemTrackingCode.Code);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order with 4 reservation entries is created
        QltyPurOrderGenerator.CreatePurchaseOrder(4, Location, Item, Vendor, '', PreferredOrderPurchaseHeader, PurchaseLine, ReservationEntry);
        AllReservationEntry.Reset();
        AllReservationEntry.SetRange("Source Type", ReservationEntry."Source Type");
        AllReservationEntry.SetRange("Source ID", ReservationEntry."Source ID");
        AllReservationEntry.SetRange("Item No.", Item."No.");
        LibraryAssert.AreEqual(4, AllReservationEntry.Count(), 'Testing the test, sanity check that we have exactly 4 reservation entries.');

        // [GIVEN] A tracking specification is created and marked from the second reservation entry
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        asePurchLineReserve.InitFromPurchLine(TempSpecTrackingSpecification, PurchaseLine);
        TempSpecTrackingSpecification."Entry No." := 1;
        AllReservationEntry.FindSet();
        AllReservationEntry.Next();
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(AllReservationEntry);
        TempSpecTrackingSpecification.Insert();
        TempSpecTrackingSpecification.Mark(true);

        // [GIVEN] Another purchase order is created (noise order)
        QltyPurOrderGenerator.CreatePurchaseOrder(4, Location, Item, Vendor, '', NoiseOrderPurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] The current count of quality inspection test headers is recorded
        CountBefore := QltyInspectionTestHeader.Count();
        // [WHEN] CreateMultipleTestsForMarkedTrackingSpecification is called with the marked tracking specification
        ReUsableQltyInspectionTestCreate.CreateMultipleTestsForMarkedTrackingSpecification(TempSpecTrackingSpecification);
        CountAfter := QltyInspectionTestHeader.Count();
        QltyInTestGenerationRule.Delete();

        // [THEN] Only 1 test is created
        LibraryAssert.AreEqual((CountBefore + 1), CountAfter, 'Only 1 test should have been created.');
        // [THEN] The created test is associated with the preferred order purchase header
        QltyInspectionTestHeader.SetRange("Source Document No.", PreferredOrderPurchaseHeader."No.");
        LibraryAssert.AreEqual(1, QltyInspectionTestHeader.Count(), 'Should have created 1 test for a purch order.');
    end;

    [Test]
    procedure CreateMultipleTestsForMultipleRecords()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        ProdOrderRoutingLineRecordRef: RecordRef;
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create quality inspection tests for multiple production order routing lines

        // [GIVEN] The quality management setup is initialized
        Initialize();
        QltyTestsUtility.EnsureSetup();
        // [GIVEN] A quality inspection template with 3 tests and a prioritized generation rule for Prod. Order Routing Line are created
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInTestGenerationRule);

        // [GIVEN] A production order generator is initialized with Item source type only
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        // [GIVEN] 3 production orders are generated
        QltyProdOrderGenerator.Generate(3, OrdersList);
        // [GIVEN] A RecordRef is populated with the last routing line from each production order
        ProdOrderRoutingLineRecordRef.Open(Database::"Prod. Order Routing Line", true);
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        foreach ProductionOrder in OrdersList do begin
            ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
            ProdOrderRoutingLine.FindLast();
            ProdOrderRoutingLineRecordRef.Copy(ProdOrderRoutingLine, false);
            ProdOrderRoutingLineRecordRef.Insert();
        end;

        // [GIVEN] The current count of quality inspection test headers is recorded
        BeforeCount := QltyInspectionTestHeader.Count();
        // [WHEN] CreateMultipleTestsForMultipleRecords is called with the RecordRef containing 3 routing lines
        ReUsableQltyInspectionTestCreate.CreateMultipleTestsForMultipleRecords(ProdOrderRoutingLineRecordRef, false);
        AfterCount := QltyInspectionTestHeader.Count();

        QltyInTestGenerationRule.Delete();

        // [THEN] 3 tests are created (one for each production order)
        LibraryAssert.AreEqual((BeforeCount + 3), AfterCount, 'Did not create the correct number of tests.');
        // [THEN] Each production order has exactly 1 test associated with it
        foreach ProductionOrder in OrdersList do begin
            CreatedQltyInspectionTestHeader.SetRange("Source Document No.", ProductionOrder);
            CreatedQltyInspectionTestHeader.FindFirst();
            LibraryAssert.AreEqual(1, CreatedQltyInspectionTestHeader.Count(), 'Did not create test for correct production order.');
        end;
    end;

    [Test]
    procedure CreateMultipleTestsForMultipleRecords_ShowTestsPage()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        ProdOrderRoutingLineRecordRef: RecordRef;
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create tests and display the test list page for multiple production order routing lines

        // [GIVEN] The quality management setup is initialized
        Initialize();
        QltyTestsUtility.EnsureSetup();
        // [GIVEN] The quality management setup is configured to show automatic and manually created tests
        QltyManagementSetup.Get();
        QltyManagementSetup."Show Test Behavior" := QltyManagementSetup."Show Test Behavior"::"Automatic and manually created tests";
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::OnProductionOutputPost;
        QltyManagementSetup.Modify();
        // [GIVEN] A quality inspection template with 3 tests and a prioritized generation rule for Prod. Order Routing Line are created
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInTestGenerationRule);

        // [GIVEN] A production order generator is initialized with Item source type only
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        // [GIVEN] 3 production orders are generated
        QltyProdOrderGenerator.Generate(3, OrdersList);
        // [GIVEN] A RecordRef is populated with the last routing line from each production order
        ProdOrderRoutingLineRecordRef.Open(Database::"Prod. Order Routing Line", true);
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        foreach ProductionOrder in OrdersList do begin
            ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
            ProdOrderRoutingLine.FindLast();
            ProdOrderRoutingLineRecordRef.Copy(ProdOrderRoutingLine, false);
            ProdOrderRoutingLineRecordRef.Insert();
        end;

        // [GIVEN] The current count of quality inspection test headers is recorded
        BeforeCount := QltyInspectionTestHeader.Count();
        // [WHEN] CreateMultipleTestsForMultipleRecords is called with the RecordRef containing 3 routing lines
        ReUsableQltyInspectionTestCreate.CreateMultipleTestsForMultipleRecords(ProdOrderRoutingLineRecordRef, false);
        AfterCount := QltyInspectionTestHeader.Count();

        QltyInTestGenerationRule.Delete();
        QltyManagementSetup."Show Test Behavior" := QltyManagementSetup."Show Test Behavior"::"Do not show created tests";
        QltyManagementSetup.Modify();

        // [THEN] 3 tests are created (one for each production order)
        LibraryAssert.AreEqual((BeforeCount + 3), AfterCount, 'Did not create the correct number of tests.');
        // [THEN] Each production order has exactly 1 test associated with it
        foreach ProductionOrder in OrdersList do begin
            CreatedQltyInspectionTestHeader.SetRange("Source Document No.", ProductionOrder);
            CreatedQltyInspectionTestHeader.FindFirst();
            LibraryAssert.AreEqual(1, CreatedQltyInspectionTestHeader.Count(), 'Did not create test for correct production order.');
        end;
    end;

    [Test]
    procedure CreateMultipleTestsForSingleRecords_ShowTestPage()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        ProdOrderRoutingLineRecordRef: RecordRef;
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a single test and display the test page for one production order routing line

        // [GIVEN] The quality management setup is initialized
        Initialize();
        QltyTestsUtility.EnsureSetup();
        // [GIVEN] The quality management setup is configured to show automatic and manually created tests
        QltyManagementSetup.Get();
        QltyManagementSetup."Show Test Behavior" := QltyManagementSetup."Show Test Behavior"::"Automatic and manually created tests";
        QltyManagementSetup.Modify();
        // [GIVEN] A quality inspection template with 3 tests and a prioritized generation rule for Prod. Order Routing Line are created
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInTestGenerationRule);

        // [GIVEN] A production order generator is initialized with Item source type only
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        // [GIVEN] 3 production orders are generated and the second one is selected
        QltyProdOrderGenerator.Generate(3, OrdersList);
        ProductionOrder := OrdersList.Get(2);
        // [GIVEN] A RecordRef is populated with the last routing line from the selected production order
        ProdOrderRoutingLineRecordRef.Open(Database::"Prod. Order Routing Line", true);
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();
        ProdOrderRoutingLineRecordRef.Copy(ProdOrderRoutingLine, false);
        ProdOrderRoutingLineRecordRef.Insert();

        // [GIVEN] The current count of quality inspection test headers is recorded
        BeforeCount := QltyInspectionTestHeader.Count();
        // [WHEN] CreateMultipleTestsForMultipleRecords is called with the RecordRef containing 1 routing line
        ReUsableQltyInspectionTestCreate.CreateMultipleTestsForMultipleRecords(ProdOrderRoutingLineRecordRef, false);
        AfterCount := QltyInspectionTestHeader.Count();

        QltyInTestGenerationRule.Delete();
        QltyManagementSetup."Show Test Behavior" := QltyManagementSetup."Show Test Behavior"::"Do not show created tests";
        QltyManagementSetup.Modify();

        // [THEN] 1 test is created
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Did not create the correct number of tests.');
        // [THEN] The created test is associated with the selected production order
        CreatedQltyInspectionTestHeader.SetRange("Source Document No.", ProductionOrder);
        CreatedQltyInspectionTestHeader.FindFirst();
        LibraryAssert.AreEqual(1, CreatedQltyInspectionTestHeader.Count(), 'Did not create test for correct production order.');
    end;

    [Test]
    procedure CreateMultipleTestsForMultipleRecords_NoCreate()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ProdOrderRoutingLineRecordRef: RecordRef;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Verify an error is returned when attempting to create tests with no valid records

        // [GIVEN] An empty RecordRef for Prod. Order Routing Line is opened
        Initialize();
        ProdOrderRoutingLineRecordRef.Open(Database::"Prod. Order Routing Line", true);
        // [GIVEN] The current count of quality inspection test headers is recorded
        BeforeCount := QltyInspectionTestHeader.Count();

        // [WHEN] CreateMultipleTestsForMultipleRecords is called with an empty RecordRef
        asserterror ReUsableQltyInspectionTestCreate.CreateMultipleTestsForMultipleRecords(ProdOrderRoutingLineRecordRef, false);
        // [THEN] An error is raised indicating unable to create a test for the record
        LibraryAssert.ExpectedError(StrSubstNo(UnableToCreateATestForRecordErr, ProdOrderRoutingLineRecordRef.Name));
        // [THEN] No tests are created
        AfterCount := QltyInspectionTestHeader.Count();
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'Should not have created tests.');
    end;

    [Test]
    procedure CreateMultipleTestsForMultipleRecords_NoGenRule_ShouldError()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        ProdOrderRoutingLineRecordRef: RecordRef;
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Verify an error is returned when no generation rule exists for production order routing lines

        // [GIVEN] The quality management setup is initialized
        Initialize();
        QltyTestsUtility.EnsureSetup();
        // [GIVEN] A quality inspection template with 3 tests is created
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        // [GIVEN] All generation rules are deleted to simulate missing rule scenario
        if not QltyInTestGenerationRule.IsEmpty() then
            QltyInTestGenerationRule.DeleteAll();

        // [GIVEN] A production order generator is initialized with Item source type only
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        // [GIVEN] 3 production orders are generated
        QltyProdOrderGenerator.Generate(3, OrdersList);
        // [GIVEN] A RecordRef is populated with the last routing line from each production order
        ProdOrderRoutingLineRecordRef.Open(Database::"Prod. Order Routing Line", true);
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        foreach ProductionOrder in OrdersList do begin
            ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
            ProdOrderRoutingLine.FindLast();
            ProdOrderRoutingLineRecordRef.Copy(ProdOrderRoutingLine, false);
            ProdOrderRoutingLineRecordRef.Insert();
        end;

        // [WHEN] CreateMultipleTestsForMultipleRecords is called without any generation rule configured
        asserterror ReUsableQltyInspectionTestCreate.CreateMultipleTestsForMultipleRecords(ProdOrderRoutingLineRecordRef, false);
        // [THEN] An error is raised indicating unable to create a test for the parent or child record
        LibraryAssert.ExpectedError(StrSubstNo(UnableToCreateATestForParentOrChildErr, ProdOrderLine.TableName, ProdOrderRoutingLineRecordRef.Name));
    end;

    local procedure CreateTestWithTracking(var PurOrdPurchaseLine: Record "Purchase Line"; var TempSpecTrackingSpecification: Record "Tracking Specification" temporary; var OutQltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        PurchaseLineRecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        QltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(PurchaseLineRecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, true, '');
        QltyInspectionTestCreate.GetCreatedTest(OutQltyInspectionTestHeader);
    end;

    local procedure SetupCreateTestPurchaseOrder(var OutPurchaseLine: Record "Purchase Line"; var TempOutSpecTrackingSpecification: Record "Tracking Specification" temporary)
    var
        Location: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        ResReservationEntry: Record "Reservation Entry";
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
    begin
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line");

        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, '', '');
        LibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);
        LibraryPurchase.CreateVendor(Vendor);
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, '', PurOrderPurchaseHeader, OutPurchaseLine, ResReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, OutPurchaseLine);
        OutPurchaseLine.Get(OutPurchaseLine."Document Type", OutPurchaseLine."Document No.", OutPurchaseLine."Line No.");
        TempOutSpecTrackingSpecification.CopyTrackingFromReservEntry(ResReservationEntry);
    end;

    local procedure SetupCreateTestProductionOrder(var QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; var QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule"; var Item: Record Item; var ProdProductionOrder: Record "Production Order"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        GenQltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
    begin
        QltyTestsUtility.EnsureSetup();
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInTestGenerationRule);
        GenQltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
    end;

    local procedure CreateProdOrderLineAndPostOutput(var Item: Record Item; var ProdProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; Qty: Decimal; var ItemJournalLine: Record "Item Journal Line")
    var
        GenQltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
    begin
        GenQltyProdOrderGenerator.CreateProdOrderLine(ProdProductionOrder, Item, Qty, ProdOrderLine);
        CreateAndPostOutput(Item, ProdOrderLine, Qty, ItemJournalLine);
    end;

    local procedure CreateAndPostOutput(var Item: Record Item; var ProdOrderLine: Record "Prod. Order Line"; Qty: Decimal; var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalBatch: Record "Item Journal Batch";
        GenQltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        QltyTestsUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
        GenQltyProdOrderGenerator.CreateOutputJournal(Item, ProdOrderLine, ItemJournalBatch, ItemJournalLine, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
    end;

    [PageHandler]
    procedure AutomatedTestListPageHandler(var QltyInspectionTestList: TestPage "Qlty. Inspection Test List")
    begin
    end;

    [PageHandler]
    procedure AutomatedSingleTestPageHandler(var QltyInspectionTest: TestPage "Qlty. Inspection Test")
    begin
    end;
}
