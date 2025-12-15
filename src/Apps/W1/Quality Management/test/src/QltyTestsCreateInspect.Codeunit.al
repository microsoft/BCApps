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
using Microsoft.QualityManagement.Integration.Manufacturing;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.Test.QualityManagement.TestLibraries;
using System.TestLibraries.Utilities;

codeunit 139959 "Qlty. Tests - Create Inspect."
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        CannotFindTemplateErr: Label 'Cannot find a Quality Inspection Template or Quality Inspection Generation Rule to match  %1. Ensure there is a Quality Inspection Generation Rule that will match this record.', Comment = '%1=The record identifier';
        ProgrammerErrNotARecordRefErr: Label 'Cannot find tests with %1. Please supply a "Record" or "RecordRef".', Comment = '%1=the variant being supplied that is not a RecordRef. Your system might have an extension or customization that needs to be re-configured.';
        UnableToCreateATestForRecordErr: Label 'Cannot find enough details to make an inspection for your record(s).  Try making sure that there is a source configuration for your record, and then also make sure there is sufficient information in your inspection generation rules.  The table involved is %1.', Comment = '%1=the table involved.';
        UnableToCreateATestForParentOrChildErr: Label 'Cannot find enough details to make an inspection for your record(s).  Try making sure that there is a source configuration for your record, and then also make sure there is sufficient information in your inspection generation rules.  Two tables involved are %1 and %2.', Comment = '%1=the parent table, %2=the child and original table.';
        IsInitialized: Boolean;

    [Test]
    procedure BasicCreate()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a basic quality inspection from production order routing line

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();
        ClearLastError();

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] CreateInspection is called with AlwaysCreate set to true
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        QltyInspectionGenRule.Delete();

        // [THEN] The function claims an inspection was found or created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'Should claim an inspection has been found/created');

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] Overall test count increases by 1 and there is exactly one test for this operation
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests increase by 1.');
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test has the correct template code
        QltyInspectionCreate.GetCreatedTest(CreatedQltyInspectionHeader);
        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            CreatedQltyInspectionHeader."Template Code",
            'Inspection generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        // [THEN] The created test has the correct document number, item, and template
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'Either wrong test gen. rule, or wrong item, or wrong document got applied.');
    end;

    [Test]
    procedure CreateInspection_AlwaysCreate()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedTestFirstQltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedTestSecondQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        QltyCreateInspectBehavior: Enum "Qlty. Create Inspect. Behavior";
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create test with AlwaysCreate behavior creates a new inspection even when one exists

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A first test is created
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        QltyInspectionCreate.GetCreatedTest(CreatedTestFirstQltyInspectionHeader);

        // [GIVEN] The Create Inspection Behavior is set to "Always create new inspection"
        QltyManagementSetup.Get();
        QltyCreateInspectBehavior := QltyManagementSetup."Create Inspection Behavior";
        QltyManagementSetup."Create Inspection Behavior" := QltyManagementSetup."Create Inspection Behavior"::"Always create new inspection";
        QltyManagementSetup.Modify();

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();
        ClearLastError();

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] CreateInspection is called again for the same routing line
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        QltyInspectionCreate.GetCreatedTest(CreatedTestSecondQltyInspectionHeader);

        QltyManagementSetup."Create Inspection Behavior" := QltyCreateInspectBehavior;
        QltyManagementSetup.Modify();
        QltyInspectionGenRule.Delete();

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] A new inspection is created and the second test has a different number than the first
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'Should claim an inspection has been found/created.');
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests');
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreNotEqual(CreatedTestFirstQltyInspectionHeader."No.", CreatedTestSecondQltyInspectionHeader."No.", 'New inspection should not be a reinspection.');
    end;

    [Test]
    procedure CreateInspection_CreateAReinspectionAny()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedTestFirstQltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedTestSecondQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        QltyCreateInspectBehavior: Enum "Qlty. Create Inspect. Behavior";
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create test with CreateAReinspectionAny behavior creates a reinspection when an inspection already exists

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A first test is created
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        QltyInspectionCreate.GetCreatedTest(CreatedTestFirstQltyInspectionHeader);

        // [GIVEN] The Create Inspection Behavior is set to "Always create reinspection"
        QltyManagementSetup.Get();
        QltyCreateInspectBehavior := QltyManagementSetup."Create Inspection Behavior";
        QltyManagementSetup."Create Inspection Behavior" := QltyManagementSetup."Create Inspection Behavior"::"Always create reinspection";
        QltyManagementSetup.Modify();

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();
        ClearLastError();

        // [WHEN] CreateInspection is called again for the same routing line
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        QltyInspectionCreate.GetCreatedTest(CreatedTestSecondQltyInspectionHeader);

        QltyManagementSetup."Create Inspection Behavior" := QltyCreateInspectBehavior;
        QltyManagementSetup.Modify();
        QltyInspectionGenRule.Delete();

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] A reinspection is created and the second test has the same number as the first with incremented Reinspection No.
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'Should claim an inspection has been found/created.');
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests increase by 1');
        LibraryAssert.AreEqual(CreatedTestFirstQltyInspectionHeader."No.", CreatedTestSecondQltyInspectionHeader."No.", 'New inspection should be a reinspection.');
        LibraryAssert.AreEqual((CreatedTestFirstQltyInspectionHeader."Reinspection No." + 1), CreatedTestSecondQltyInspectionHeader."Reinspection No.", 'New inspection "Reinspection No." should have incremented.');
    end;

    [Test]
    procedure CreateInspection_CreateAReinspectionFinished_NotFinished()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedTestFirstQltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedTestSecondQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        QltyCreateInspectBehavior: Enum "Qlty. Create Inspect. Behavior";
        BeforeCount: Integer;
        AfterCount: Integer;
        ClaimedATestWasFoundOrCreated: Boolean;
    begin
        // [SCENARIO] Create test with CreateAReinspectionFinished behavior, using a production order routing line, retrieves existing test when it is not finished

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A first test is created
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        QltyInspectionCreate.GetCreatedTest(CreatedTestFirstQltyInspectionHeader);

        // [GIVEN] The Create Inspection Behavior is set to "Create reinspection if matching test is finished"
        QltyManagementSetup.Get();
        QltyCreateInspectBehavior := QltyManagementSetup."Create Inspection Behavior";
        QltyManagementSetup."Create Inspection Behavior" := QltyManagementSetup."Create Inspection Behavior"::"Create reinspection if matching test is finished";
        QltyManagementSetup.Modify();

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] CreateInspection is called again for the same routing line when the first test is not finished
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        QltyInspectionCreate.GetCreatedTest(CreatedTestSecondQltyInspectionHeader);

        QltyManagementSetup."Create Inspection Behavior" := QltyCreateInspectBehavior;
        QltyManagementSetup.Modify();
        QltyInspectionGenRule.Delete();

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] No new inspection is created and the same test is retrieved with the same number and Reinspection No.
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'Should claim an inspection has been found/created.');
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'Should not be any new inspections counted.');
        LibraryAssert.AreEqual(CreatedTestFirstQltyInspectionHeader."No.", CreatedTestSecondQltyInspectionHeader."No.", 'Should retrieve same test.');
        LibraryAssert.AreEqual(CreatedTestFirstQltyInspectionHeader."Reinspection No.", CreatedTestSecondQltyInspectionHeader."Reinspection No.", 'Should retrieve same test.');
    end;

    [Test]
    procedure CreateInspection_CreateAReinspectionFinished_Finished()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedTestFirstQltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedTestSecondQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        QltyCreateInspectBehavior: Enum "Qlty. Create Inspect. Behavior";
        BeforeCount: Integer;
        AfterCount: Integer;
        ClaimedATestWasFoundOrCreated: Boolean;
    begin
        // [SCENARIO] Create test with CreateAReinspectionFinished behavior, using a production order routing line, creates a reinspection when the existing test is finished

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A first test is created
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        QltyInspectionCreate.GetCreatedTest(CreatedTestFirstQltyInspectionHeader);

        // [GIVEN] The Create Inspection Behavior is set to "Create reinspection if matching test is finished"
        QltyManagementSetup.Get();
        QltyCreateInspectBehavior := QltyManagementSetup."Create Inspection Behavior";
        QltyManagementSetup."Create Inspection Behavior" := QltyManagementSetup."Create Inspection Behavior"::"Create reinspection if matching test is finished";
        QltyManagementSetup.Modify();

        // [GIVEN] The first test is marked as Finished
        CreatedTestFirstQltyInspectionHeader.Status := CreatedTestFirstQltyInspectionHeader.Status::Finished;
        CreatedTestFirstQltyInspectionHeader.Modify();

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] CreateInspection is called again for the same routing line with the first test finished
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        QltyInspectionCreate.GetCreatedTest(CreatedTestSecondQltyInspectionHeader);

        QltyManagementSetup."Create Inspection Behavior" := QltyCreateInspectBehavior;
        QltyManagementSetup.Modify();
        QltyInspectionGenRule.Delete();

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] A reinspection is created with incremented Reinspection No. and overall test count increases by 1
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'Should claim an inspection has been found/created.');
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests increase by 1.');
        LibraryAssert.AreEqual(CreatedTestFirstQltyInspectionHeader."No.", CreatedTestSecondQltyInspectionHeader."No.", 'New inspection should be a reinspection.');
        LibraryAssert.AreEqual((CreatedTestFirstQltyInspectionHeader."Reinspection No." + 1), CreatedTestSecondQltyInspectionHeader."Reinspection No.", 'New inspection "Reinspection No." should have incremented.');
    end;

    [Test]
    procedure CreateInspection_CreateAReinspectionFinished_UseExistingTestOpen_Finished()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedTestFirstQltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedTestSecondQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        QltyCreateInspectBehavior: Enum "Qlty. Create Inspect. Behavior";
        BeforeCount: Integer;
        AfterCount: Integer;
        ClaimedATestWasFoundOrCreated: Boolean;
    begin
        // [SCENARIO] Create test with UseExistingTestOpenElseNew behavior, using a production order routing line, creates a new inspection when existing test is finished

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A first test is created
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        QltyInspectionCreate.GetCreatedTest(CreatedTestFirstQltyInspectionHeader);

        // [GIVEN] The Create Inspection Behavior is set to "Use existing open inspection if available"
        QltyManagementSetup.Get();
        QltyCreateInspectBehavior := QltyManagementSetup."Create Inspection Behavior";
        QltyManagementSetup."Create Inspection Behavior" := QltyManagementSetup."Create Inspection Behavior"::"Use existing open inspection if available";
        QltyManagementSetup.Modify();

        // [GIVEN] The first test is marked as Finished
        CreatedTestFirstQltyInspectionHeader.Status := CreatedTestFirstQltyInspectionHeader.Status::Finished;
        CreatedTestFirstQltyInspectionHeader.Modify();

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] CreateInspection is called again for the same routing line with the first test finished
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        QltyInspectionCreate.GetCreatedTest(CreatedTestSecondQltyInspectionHeader);

        QltyManagementSetup."Create Inspection Behavior" := QltyCreateInspectBehavior;
        QltyManagementSetup.Modify();
        QltyInspectionGenRule.Delete();

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] A new inspection is created that is not a reinspection
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'Should claim an inspection has been found/created.');
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests');
        LibraryAssert.AreNotEqual(CreatedTestFirstQltyInspectionHeader."No.", CreatedTestSecondQltyInspectionHeader."No.", 'New inspection should not be a reinspection.');
    end;

    [Test]
    procedure CreateInspection_CreateAReinspectionFinished_UseExistingTestOpen_Open()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedTestFirstQltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedTestSecondQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        QltyCreateInspectBehavior: Enum "Qlty. Create Inspect. Behavior";
        BeforeCount: Integer;
        AfterCount: Integer;
        ClaimedATestWasFoundOrCreated: Boolean;
    begin
        // [SCENARIO] Create test with UseExistingTestOpenElseNew behavior, using a production order routing line, retrieves existing open inspection

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A first test is created and left open
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        QltyInspectionCreate.GetCreatedTest(CreatedTestFirstQltyInspectionHeader);

        // [GIVEN] The Create Inspection Behavior is set to "Use existing open inspection if available"
        QltyManagementSetup.Get();
        QltyCreateInspectBehavior := QltyManagementSetup."Create Inspection Behavior";
        QltyManagementSetup."Create Inspection Behavior" := QltyManagementSetup."Create Inspection Behavior"::"Use existing open inspection if available";
        QltyManagementSetup.Modify();

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] CreateInspection is called again for the same routing line with the first test still open
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        QltyInspectionCreate.GetCreatedTest(CreatedTestSecondQltyInspectionHeader);

        QltyManagementSetup."Create Inspection Behavior" := QltyCreateInspectBehavior;
        QltyManagementSetup.Modify();
        QltyInspectionGenRule.Delete();

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] No new inspection is created and the same test is retrieved
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'Should claim an inspection has been found/created.');
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'Should not be any new inspections counted.');
        LibraryAssert.AreEqual(CreatedTestFirstQltyInspectionHeader."No.", CreatedTestSecondQltyInspectionHeader."No.", 'Should have retrieved same record.');
    end;

    [Test]
    procedure CreateInspection_CreateAReinspectionFinished_UseExistingTestAny_Existing()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedTestFirstQltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedTestSecondQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        PreviousQltyCreateInspectBehavior: Enum "Qlty. Create Inspect. Behavior";
        BeforeCount: Integer;
        AfterCount: Integer;
        ClaimedATestWasFoundOrCreated: Boolean;
    begin
        // [SCENARIO] Create test with UseExistingTestAnyElseNew behavior, using a production order routing line, retrieves existing test even if finished

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A first test is created
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        QltyInspectionCreate.GetCreatedTest(CreatedTestFirstQltyInspectionHeader);

        // [GIVEN] The Create Inspection Behavior is set to "Use any existing test if available"
        QltyManagementSetup.Get();
        PreviousQltyCreateInspectBehavior := QltyManagementSetup."Create Inspection Behavior";
        QltyManagementSetup."Create Inspection Behavior" := QltyManagementSetup."Create Inspection Behavior"::"Use any existing test if available";
        QltyManagementSetup.Modify();

        // [GIVEN] The first test is marked as Finished
        CreatedTestFirstQltyInspectionHeader.Status := CreatedTestFirstQltyInspectionHeader.Status::Finished;
        CreatedTestFirstQltyInspectionHeader.Modify();

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] CreateInspection is called again for the same routing line
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        QltyInspectionCreate.GetCreatedTest(CreatedTestSecondQltyInspectionHeader);

        QltyManagementSetup."Create Inspection Behavior" := PreviousQltyCreateInspectBehavior;
        QltyManagementSetup.Modify();
        QltyInspectionGenRule.Delete();

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] The existing test is found and no new inspection is created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been found.');
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'Expected overall tests count not to change.');
    end;

    [Test]
    procedure CreateInspection_CreateAReinspectionFinished_UseExistingTestAny_New()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        QltyCreateInspectBehavior: Enum "Qlty. Create Inspect. Behavior";
        BeforeCount: Integer;
        AfterCount: Integer;
        ClaimedATestWasFoundOrCreated: Boolean;
    begin
        // [SCENARIO] Create test with UseExistingTestAnyElseNew behavior, using a production order routing line, creates a new inspection when no existing test

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] The Create Inspection Behavior is set to "Use any existing test if available"
        QltyManagementSetup.Get();
        QltyCreateInspectBehavior := QltyManagementSetup."Create Inspection Behavior";
        QltyManagementSetup."Create Inspection Behavior" := QltyManagementSetup."Create Inspection Behavior"::"Use any existing test if available";
        QltyManagementSetup.Modify();

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] CreateInspection is called when no existing test exists
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);

        QltyManagementSetup."Create Inspection Behavior" := QltyCreateInspectBehavior;
        QltyManagementSetup.Modify();
        QltyInspectionGenRule.Delete();

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] A new inspection is created and overall test count increases by 1
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created');
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests to increase by 1.');
    end;

    [Test]
    procedure CreateInspectionWithVariant()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from production order routing line with variant support

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();
        ClearLastError();

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] CreateInspectionWithVariant is called with AlwaysCreate set to true
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspectionWithVariant(ProdOrderRoutingLineRecordRefRecordRef, true);

        // [THEN] An inspection is claimed to be created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created.');

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] Overall test count increases by 1 and there is exactly one test for this operation
        LibraryAssert.AreEqual(BeforeCount + 1, AfterCount, 'Expected overall tests count to increase by 1.');
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test has the correct template code
        QltyInspectionCreate.GetCreatedTest(CreatedQltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            CreatedQltyInspectionHeader."Template Code",
            'Inspection generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        // [THEN] The test has the correct document number, item, and template
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'Either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateInspectionWithVariantAndTemplate()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection using a production order routing line with specified template and variant support

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();
        ClearLastError();

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] CreateInspectionWithVariantAndTemplate is called with specific template code
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspectionWithVariantAndTemplate(ProdOrderRoutingLineRecordRefRecordRef, true, QltyInspectionTemplateHdr.Code);

        // [THEN] An inspection is claimed to be created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created');

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] Overall test count increases by 1 and there is exactly one test for this operation
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests count to increase by 1.');
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test uses the specified template code
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            QltyInspectionHeader."Template Code",
            'Inspection generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        // [THEN] The test has the correct document number, item, and template
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'Either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateInspectionWithMultiVariants()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProductionTrigger: Enum "Qlty. Production Trigger";
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Creates a quality inspection with multiple variants from production output

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] Production trigger is disabled temporarily
        QltyManagementSetup.Get();
        ProductionTrigger := QltyManagementSetup."Production Trigger";
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
        QltyManagementSetup.Modify();

        // [GIVEN] A production order line is created and output is posted
        CreateProdOrderLineAndPostOutput(Item, ProdProductionOrder, ProdOrderLine, 1, ItemJournalLine);

        OutputItemLedgerEntry.SetRange("Entry Type", OutputItemLedgerEntry."Entry Type"::Output);
        OutputItemLedgerEntry.SetRange("Order Type", OutputItemLedgerEntry."Order Type"::Production);
        OutputItemLedgerEntry.SetRange("Document No.", ProdProductionOrder."No.");
        OutputItemLedgerEntry.SetRange("Item No.", Item."No.");
        OutputItemLedgerEntry.FindFirst();

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();
        ClearLastError();

        // [WHEN] CreateInspectionWithMultiVariants is called with the production output
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(ProdOrderRoutingLine, OutputItemLedgerEntry, ItemJournalLine, ProdOrderLine, false, '');
        QltyInspectionCreate.GetCreatedTest(CreatedQltyInspectionHeader);

        QltyManagementSetup."Production Trigger" := ProductionTrigger;
        QltyInspectionGenRule.Delete();
        QltyManagementSetup.Modify();

        // [THEN] An inspection is claimed to be created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created.');

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] Overall test count increases by 1 and there is exactly one test for this operation
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests');
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test has the correct template code
        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            CreatedQltyInspectionHeader."Template Code",
            'Inspection generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        // [THEN] The test has the correct document number, item, and template
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'Either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateInspectionWithMultiVariants_2ndVariant()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        UnusedVariant1: Variant;
        ProductionTrigger: Enum "Qlty. Production Trigger";
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from production output using the 2nd variant parameter

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] Production trigger is disabled temporarily
        QltyManagementSetup.Get();
        ProductionTrigger := QltyManagementSetup."Production Trigger";
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
        QltyManagementSetup.Modify();

        // [GIVEN] A production order line is created and output is posted
        CreateProdOrderLineAndPostOutput(Item, ProdProductionOrder, ProdOrderLine, 1, ItemJournalLine);

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();
        ClearLastError();

        // [WHEN] CreateInspectionWithMultiVariants is called with 2nd variant (ProdOrderRoutingLine) provided
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(UnusedVariant1, ProdOrderRoutingLine, ItemJournalLine, ProdOrderLine, false, '');
        QltyInspectionCreate.GetCreatedTest(CreatedQltyInspectionHeader);
        QltyManagementSetup."Production Trigger" := ProductionTrigger;
        QltyManagementSetup.Modify();
        QltyInspectionGenRule.Delete();

        // [THEN] An inspection is claimed to be created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created.');

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] Overall test count increases by 1 and there is exactly one test for this operation
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests to increase by 1.');
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test has the correct template code and item
        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            CreatedQltyInspectionHeader."Template Code",
            'Inspection generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'Either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateInspectionWithMultiVariants_3rdVariant()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        ProductionTrigger: Enum "Qlty. Production Trigger";
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from production output using the 3rd variant parameter

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] Production trigger is disabled temporarily
        QltyManagementSetup.Get();
        ProductionTrigger := QltyManagementSetup."Production Trigger";
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
        QltyManagementSetup.Modify();

        // [GIVEN] A production order line is created and output is posted
        CreateProdOrderLineAndPostOutput(Item, ProdProductionOrder, ProdOrderLine, 1, ItemJournalLine);

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();
        ClearLastError();

        // [WHEN] CreateInspectionWithMultiVariants is called with 3rd variant (ProdOrderRoutingLine) provided
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(UnusedVariant1, UnusedVariant2, ProdOrderRoutingLine, ProdOrderLine, false, '');
        QltyInspectionCreate.GetCreatedTest(CreatedQltyInspectionHeader);

        QltyManagementSetup."Production Trigger" := ProductionTrigger;
        QltyManagementSetup.Modify();
        QltyInspectionGenRule.Delete();

        // [THEN] An inspection is claimed to be created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created.');

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] Overall test count increases by 1 if not triggered on output post
        if QltyManagementSetup."Production Trigger" <> QltyManagementSetup."Production Trigger"::OnProductionOutputPost then
            LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests to increase by 1.');
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");

        // [THEN] There is exactly one test for this operation with correct template
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'There should be exactly one test for this operation.');

        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            CreatedQltyInspectionHeader."Template Code",
            'Inspection generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'Either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateInspectionWithMultiVariants_4thVariant()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        UnusedVariant3: Variant;
        ProductionTrigger: Enum "Qlty. Production Trigger";
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from production output using the 4th variant parameter

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] Production trigger is disabled temporarily
        QltyManagementSetup.Get();
        ProductionTrigger := QltyManagementSetup."Production Trigger";
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
        QltyManagementSetup.Modify();

        // [GIVEN] A production order line is created and output is posted
        CreateProdOrderLineAndPostOutput(Item, ProdProductionOrder, ProdOrderLine, 1, ItemJournalLine);

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();
        ClearLastError();

        // [WHEN] CreateInspectionWithMultiVariants is called with 4th variant (ProdOrderRoutingLine) provided
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(UnusedVariant1, UnusedVariant2, UnusedVariant3, ProdOrderRoutingLine, false, '');
        QltyInspectionCreate.GetCreatedTest(CreatedQltyInspectionHeader);

        QltyManagementSetup."Production Trigger" := ProductionTrigger;
        QltyManagementSetup.Modify();
        QltyInspectionGenRule.Delete();

        // [THEN] An inspection is claimed to be created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been created');

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] Overall test count increases by 1 and there is exactly one test for this operation
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests');
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test has the correct template code and item
        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            CreatedQltyInspectionHeader."Template Code",
            'Inspection generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateInspectionWithMultiVariantsAndTemplate()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProductionTrigger: Enum "Qlty. Production Trigger";
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from production output with specified template using variant parameters

        Initialize();

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

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

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();
        ClearLastError();

        // [WHEN] CreateInspectionWithMultiVariantsAndTemplate is called with specific template code
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(ProdOrderRoutingLine, OutputItemLedgerEntry, ItemJournalLine, ProdOrderLine, false, QltyInspectionTemplateHdr.Code);

        QltyManagementSetup."Production Trigger" := ProductionTrigger;
        QltyManagementSetup.Modify();
        QltyInspectionGenRule.Delete();

        // [THEN] An inspection is claimed to be created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created');

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] Overall test count increases by 1 and there is exactly one test for this operation
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests');
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test uses the specified template code
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            QltyInspectionHeader."Template Code",
            'Inspection generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        // [THEN] The test has the correct document number, item, and template
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'Either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateInspectionWithMultiVariantsAndTemplate_NoGenRule()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        ProductionTrigger: Enum "Qlty. Production Trigger";
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from production output with specified template when no generation rule exists

        Initialize();

        // [GIVEN] Quality inspection setup is initialized
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();
        // [GIVEN] Production trigger is disabled temporarily
        ProductionTrigger := QltyManagementSetup."Production Trigger";
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
        QltyManagementSetup.Modify();
        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
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
        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();
        ClearLastError();

        // [WHEN] CreateInspectionWithMultiVariantsAndTemplate is called with specific template code (no generation rule scenario)
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(ProdOrderRoutingLine, OutputItemLedgerEntry, ItemJournalLine, ProdOrderLine, false, QltyInspectionTemplateHdr.Code);

        QltyManagementSetup."Production Trigger" := ProductionTrigger;
        QltyManagementSetup.Modify();

        // [THEN] An inspection is claimed to be created
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created.');

        // [THEN] Overall test count increases by 1 and there is exactly one test for this operation
        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests');
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test uses the specified template code even without a generation rule
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);
        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            QltyInspectionHeader."Template Code",
            'Inspection generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        // [THEN] The test has the correct document number, item, and template
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'Either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateInspectionWithSpecificTemplate()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        ClaimedATestWasFoundOrCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection using a specified template code from production order routing line
        Initialize();

        // [GIVEN] A production order with routing line is set up with an inspection template and generation rule
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] The initial test count is captured
        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();
        ClearLastError();

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] CreateInspectionWithSpecificTemplate is called with the template code
        // [WHEN] CreateInspectionWithSpecificTemplate is called with the template code
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspectionWithSpecificTemplate(ProdOrderRoutingLineRecordRefRecordRef, true, QltyInspectionTemplateHdr.Code);

        QltyInspectionGenRule.Delete();

        // [THEN] The test creation is confirmed successful
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been claimed to be created.');

        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();

        // [THEN] The overall test count increases by one
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests');

        // [THEN] Exactly one test exists for this production order operation
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'There should be exactly one test for this operation.');

        // [THEN] The created test uses the specified template code
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);
        LibraryAssert.AreEqual(
            QltyInspectionTemplateHdr.Code,
            QltyInspectionHeader."Template Code",
            'Inspection generation rules created an unexpected test. Remaining asserts are invalid. Either a problem in choosing the correct generation rule or a problem in the unit test itself.');

        // [THEN] The test is correctly associated with the production order, item, and template
        QltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        QltyInspectionHeader.SetRange("Source Item No.", Item."No.");
        QltyInspectionHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'Either wrong test gen rule, or wrong item, or wrong document got applied.');
        ClearLastError();
    end;

    [Test]
    procedure CreateInspectionWithSpecificTemplate_NoGenRuleOrTemplate_ShouldError()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        InspectionSecondQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
    begin
        // [SCENARIO] Verify error when creating test with specific template but generation rule and template do not exist

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] All generation rules are deleted
        QltyInspectionGenRule.DeleteAll();
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] CreateInspectionWithSpecificTemplate is called with a non-existent template code
        asserterror QltyInspectionCreate.CreateInspectionWithSpecificTemplate(ProdOrderRoutingLineRecordRefRecordRef, true, InspectionSecondQltyInspectionTemplateHdr.Code);

        // [THEN] An error is raised indicating the template cannot be found
        LibraryAssert.ExpectedError(StrSubstNo(CannotFindTemplateErr, Format(ProdOrderRoutingLineRecordRefRecordRef.RecordId())));
    end;

    [Test]
    procedure FindExistingTestWithVariant_FindAll_ShouldNotFind()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        UnusedVariant3: Variant;
        FoundTest: Boolean;
    begin
        // [SCENARIO] Verify no tests are found when searching for nonexistent tests with FindAll option

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        QltyInspectionHeader.Reset();
        ClearLastError();

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] FindExistingTestWithVariant is called with FindAll=true when no tests exist
        FoundTest := QltyInspectionCreate.FindExistingTestWithVariant(ProdOrderRoutingLineRecordRefRecordRef, UnusedVariant1, UnusedVariant2, UnusedVariant3, TempQltyInspectionGenRule, FoundQltyInspectionHeader, true);

        QltyInspectionGenRule.Delete();

        // [THEN] No test is found and the count is zero
        LibraryAssert.IsFalse(FoundTest, 'Should not find any tests.');
        LibraryAssert.AreEqual(0, FoundQltyInspectionHeader.Count(), 'There should not be any tests found.');
    end;

    [Test]
    procedure FindExistingTestWithVariant_FindAll()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReQltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        UnusedVariant3: Variant;
        FoundTest: Boolean;
    begin
        // [SCENARIO] Retrieve all existing tests including reinspections when FindAll is true. Uses a production order routing line and a reinspection. Should find both tests.

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] An inspection is created with a reinspection
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionCreate.CreateInspectionWithSpecificTemplate(ProdOrderRoutingLineRecordRefRecordRef, true, QltyInspectionTemplateHdr.Code);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        QltyInspectionCreate.CreateReinspection(QltyInspectionHeader, ReQltyInspectionHeader);

        Clear(FoundQltyInspectionHeader);

        // [WHEN] FindExistingTestWithVariant is called with FindAll=true
        FoundTest := QltyInspectionCreate.FindExistingTestWithVariant(ProdOrderRoutingLineRecordRefRecordRef, UnusedVariant1, UnusedVariant2, UnusedVariant3, TempQltyInspectionGenRule, FoundQltyInspectionHeader, true);
        QltyInspectionGenRule.Delete();

        // [THEN] Both tests are found
        LibraryAssert.IsTrue(FoundTest, 'Should claim test found.');
        LibraryAssert.AreEqual(2, FoundQltyInspectionHeader.Count(), 'There should be exactly two tests found.');
    end;

    [Test]
    procedure FindExistingTestWithVariant_FindLast_ShouldNotFind()
    var
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        UnusedVariant3: Variant;
        FoundTest: Boolean;
    begin
        // [SCENARIO] Verify no test is found when searching for nonexistent test with FindAll=false

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] FindExistingTestWithVariant is called with FindAll=false when no tests exist
        FoundTest := QltyInspectionCreate.FindExistingTestWithVariant(ProdOrderRoutingLineRecordRefRecordRef, UnusedVariant1, UnusedVariant2, UnusedVariant3, TempQltyInspectionGenRule, FoundQltyInspectionHeader, false);
        QltyInspectionGenRule.Delete();

        // [THEN] No test is found and the count is zero
        LibraryAssert.IsFalse(FoundTest, 'Should not find any tests.');
        LibraryAssert.AreEqual(0, FoundQltyInspectionHeader.Count(), 'There should not be any tests found.');
    end;

    [Test]
    procedure FindExistingTestWithVariant_FindLast()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReQltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        UnusedVariant3: Variant;
        FoundTest: Boolean;
    begin
        // [SCENARIO] Retrieve only the last test created when FindAll is false. Uses a production order routing line and a reinspection to ensure it only finds the last test created.

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] An inspection is created with a reinspection
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionCreate.CreateInspectionWithSpecificTemplate(ProdOrderRoutingLineRecordRefRecordRef, true, QltyInspectionTemplateHdr.Code);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        QltyInspectionCreate.CreateReinspection(QltyInspectionHeader, ReQltyInspectionHeader);

        // [WHEN] FindExistingTestWithVariant is called with FindAll=false
        FoundTest := QltyInspectionCreate.FindExistingTestWithVariant(ProdOrderRoutingLineRecordRefRecordRef, UnusedVariant1, UnusedVariant2, UnusedVariant3, TempQltyInspectionGenRule, FoundQltyInspectionHeader, false);
        QltyInspectionGenRule.Delete();

        // [THEN] Only the last created test (the reinspection) is found
        LibraryAssert.IsTrue(FoundTest, 'Should claim found test.');
        LibraryAssert.AreEqual(ReQltyInspectionHeader."Reinspection No.", FoundQltyInspectionHeader."Reinspection No.", 'The found test should match the last created test.');
    end;

    [Test]
    procedure FindExistingInspectionWithVariant_ShouldNotFind()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        FoundTest: Boolean;
    begin
        // [SCENARIO] Verify no tests are found when searching for nonexistent tests

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [WHEN] FindExistingInspectionWithVariant is called when no tests exist
        FoundTest := QltyInspectionCreate.FindExistingInspectionWithVariant(false, ProdOrderRoutingLine, FoundQltyInspectionHeader);
        QltyInspectionGenRule.Delete();

        // [THEN] No test is found and the count matches the total test count
        LibraryAssert.IsFalse(FoundTest, 'Should not find any tests.');
        LibraryAssert.AreEqual(QltyInspectionHeader.Count(), FoundQltyInspectionHeader.Count(), 'There should not be any tests found.');
    end;

    [Test]
    procedure FindExistingInspectionWithVariant()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
    begin
        // [SCENARIO] Retrieve an existing test when one exists for the production order routing line

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] An inspection is created for the production order routing line
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        QltyInspectionCreate.CreateInspectionWithSpecificTemplate(ProdOrderRoutingLineRecordRefRecordRef, true, QltyInspectionTemplateHdr.Code);
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [WHEN] FindExistingInspectionWithVariant is called with the routing line
        QltyInspectionCreate.FindExistingInspectionWithVariant(false, ProdOrderRoutingLine, FoundQltyInspectionHeader);
        QltyInspectionGenRule.Delete();

        // [THEN] Exactly one test is found with the correct test number
        LibraryAssert.AreEqual(1, FoundQltyInspectionHeader.Count(), 'There should be exactly one test found.');
        LibraryAssert.AreEqual(QltyInspectionHeader."No.", FoundQltyInspectionHeader."No.", 'Should find the correct test.');
    end;

    [Test]
    procedure FindExistingInspectionWithVariant_ErrorNoGenRule()
    var
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
    begin
        // [SCENARIO] Verify error when no generation rule exists and ThrowError is true

        // [GIVEN] Quality Management setup is initialized and a template is created
        Initialize();
        QltyInspectionUtility.EnsureSetup();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);

        // [GIVEN] All generation rules are deleted
        QltyInspectionGenRule.DeleteAll();

        // [WHEN] FindExistingInspectionWithVariant is called with ThrowError=true
        asserterror QltyInspectionCreate.FindExistingInspectionWithVariant(true, ProdOrderRoutingLine, FoundQltyInspectionHeader);

        // [THEN] An error is raised indicating the template cannot be found
        LibraryAssert.ExpectedError(StrSubstNo(CannotFindTemplateErr, ProdOrderRoutingLine.RecordId()));
    end;

    [Test]
    procedure FindExistingInspectionWithMultipleVariants_ErrorVariant()
    var
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
    begin
        // [SCENARIO] Verify error when an invalid variant is provided to search function

        // [GIVEN] Quality Management setup is initialized and a template is created
        Initialize();
        QltyInspectionUtility.EnsureSetup();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);

        // [WHEN] FindExistingInspectionWithMultipleVariants is called with an empty string variant
        asserterror QltyInspectionCreate.FindExistingInspectionWithMultipleVariants(true, '', ProdOrderRoutingLine, OutputItemLedgerEntry, ItemJournalLine, FoundQltyInspectionHeader);

        // [THEN] An error is raised indicating the variant is not a valid RecordRef
        LibraryAssert.ExpectedError(StrSubstNo(ProgrammerErrNotARecordRefErr, ''));
    end;

    [Test]
    procedure FindExistingInspectionWithMultipleVariants_ErrorNoGenRule()
    var
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdOrderLine: Record "Prod. Order Line";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalLine: Record "Item Journal Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
    begin
        // [SCENARIO] Verify error when no generation rule exists and ThrowError is true

        // [GIVEN] Quality Management setup is initialized and a template is created
        Initialize();
        QltyInspectionUtility.EnsureSetup();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);

        // [GIVEN] All generation rules are deleted
        QltyInspectionGenRule.DeleteAll();

        // [WHEN] FindExistingInspectionWithMultipleVariants is called with ThrowError=true
        asserterror QltyInspectionCreate.FindExistingInspectionWithMultipleVariants(true, ProdOrderRoutingLine, OutputItemLedgerEntry, ItemJournalLine, ProdOrderLine, FoundQltyInspectionHeader);

        // [THEN] An error is raised indicating the template cannot be found
        LibraryAssert.ExpectedError(StrSubstNo(CannotFindTemplateErr, ProdOrderRoutingLine.RecordId()));
    end;

    [Test]
    procedure FindExistingInspectionWithMultipleVariants()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        ProductionTrigger: Enum "Qlty. Production Trigger";
        FoundTest: Boolean;
    begin
        // [SCENARIO] Retrieve an existing test created from production output with multiple variants

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

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

        QltyInspectionHeader.Reset();
        ClearLastError();

        // [GIVEN] An inspection is created with multiple variants from the production output
        QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(ProdOrderRoutingLine, OutputItemLedgerEntry, ItemJournalLine, ProdOrderLine, false, '');
        QltyInspectionCreate.GetCreatedTest(CreatedQltyInspectionHeader);

        // [WHEN] FindExistingInspectionWithMultipleVariants is called with the same variants
        FoundTest := QltyInspectionCreate.FindExistingInspectionWithMultipleVariants(false, ProdOrderRoutingLine, OutputItemLedgerEntry, ItemJournalLine, ProdOrderLine, FoundQltyInspectionHeader);

        QltyManagementSetup."Production Trigger" := ProductionTrigger;
        QltyManagementSetup.Modify();
        QltyInspectionGenRule.Delete();

        // [THEN] The test is found with the correct test number
        LibraryAssert.IsTrue(FoundTest, 'Should have found tests.');
        LibraryAssert.AreEqual(1, FoundQltyInspectionHeader.Count(), 'The search did not find the correct number of tests.');
        LibraryAssert.AreEqual(CreatedQltyInspectionHeader."No.", FoundQltyInspectionHeader."No.", 'The found test should match the created test.');
    end;

    [Test]
    procedure FindExistingInspectionWithMultipleVariants_ShouldNotFind()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        OutputItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        BeforeCount: Integer;
        FoundTest: Boolean;
    begin
        // [SCENARIO] Verify no tests are found when searching for nonexistent tests with multiple variants

        // [GIVEN] A quality inspection template, generation rule, item, and production order are set up
        Initialize();
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] A production order line is created and output is posted
        CreateProdOrderLineAndPostOutput(Item, ProdProductionOrder, ProdOrderLine, 1, ItemJournalLine);

        OutputItemLedgerEntry.SetRange("Entry Type", OutputItemLedgerEntry."Entry Type"::Output);
        OutputItemLedgerEntry.SetRange("Order Type", OutputItemLedgerEntry."Order Type"::Production);
        OutputItemLedgerEntry.SetRange("Document No.", ProdProductionOrder."No.");
        OutputItemLedgerEntry.SetRange("Item No.", Item."No.");
        OutputItemLedgerEntry.FindFirst();

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();
        ClearLastError();

        // [WHEN] FindExistingInspectionWithMultipleVariants is called when no tests have been created
        QltyInspectionCreate.FindExistingInspectionWithMultipleVariants(false, ProdOrderRoutingLine, OutputItemLedgerEntry, ItemJournalLine, ProdOrderLine, FoundQltyInspectionHeader);
        QltyInspectionGenRule.Delete();

        // [THEN] No test is found and the count matches the initial count
        LibraryAssert.IsFalse(FoundTest, 'There should not be any tests found.');
        LibraryAssert.AreEqual(BeforeCount, FoundQltyInspectionHeader.Count(), 'There should not be any tests found.');
    end;

    [Test]
    procedure FindExistingInspection_StandardSource()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
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
        SetupCreateInspectionPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Standard Source Fields"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Standard Source Fields";
        QltyManagementSetup.Modify();

        // [GIVEN] A quality inspection is created with tracking
        CreateInspectionWithTracking(PurOrdPurchaseLine, TempSpecTrackingSpecification, QltyInspectionHeader);

        // [WHEN] FindExistingInspection is called with the purchase line and tracking specification
        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);
        TestFound := QltyInspectionCreate.FindExistingInspection(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] The test is found successfully
        LibraryAssert.IsTrue(TestFound, 'Should find tests.');
        // [THEN] Exactly one test is found
        LibraryAssert.AreEqual(1, FoundQltyInspectionHeader.Count(), 'Should find exact number of tests.');
        // [THEN] The found test matches the created test
        LibraryAssert.AreEqual(FoundQltyInspectionHeader."No.", QltyInspectionHeader."No.", 'Should find the correct test.');
    end;

    [Test]
    procedure FindExistingInspection_BySourceRecord()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
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
        SetupCreateInspectionPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Source Record"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Source Record";
        QltyManagementSetup.Modify();

        // [GIVEN] A quality inspection is created with tracking
        CreateInspectionWithTracking(PurOrdPurchaseLine, TempSpecTrackingSpecification, QltyInspectionHeader);

        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);

        // [WHEN] FindExistingInspection is called with the source record
        TestFound := QltyInspectionCreate.FindExistingInspection(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] The test is found successfully
        LibraryAssert.IsTrue(TestFound, 'Should find tests.');

        // [THEN] Exactly one test is found
        LibraryAssert.AreEqual(1, FoundQltyInspectionHeader.Count(), 'Should find exact number of tests.');

        // [THEN] The found test matches the created test
        LibraryAssert.AreEqual(FoundQltyInspectionHeader."No.", QltyInspectionHeader."No.", 'Should find the correct test.');
    end;

    [Test]
    procedure FindExistingInspection_BySourceRecord_NoGenRule()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
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
        SetupCreateInspectionPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Source Record"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Source Record";
        QltyManagementSetup.Modify();

        // [GIVEN] A quality inspection is created with tracking
        CreateInspectionWithTracking(PurOrdPurchaseLine, TempSpecTrackingSpecification, QltyInspectionHeader);

        // [GIVEN] All generation rules are deleted
        if not QltyInspectionGenRule.IsEmpty() then
            QltyInspectionGenRule.DeleteAll();

        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);

        // [WHEN] FindExistingInspection is called with the source record
        // [WHEN] FindExistingInspection is called with the source record
        TestFound := QltyInspectionCreate.FindExistingInspection(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] The test is found successfully
        LibraryAssert.IsTrue(TestFound, 'Should find tests.');

        // [THEN] Exactly one test is found
        LibraryAssert.AreEqual(1, FoundQltyInspectionHeader.Count(), 'Should find exact number of tests.');

        // [THEN] The found test matches the created test
        LibraryAssert.AreEqual(FoundQltyInspectionHeader."No.", QltyInspectionHeader."No.", 'Should find the correct test.');
    end;

    [Test]
    procedure FindExistingInspection_ByTracking()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
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
        SetupCreateInspectionPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Item Tracking"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Item Tracking";
        QltyManagementSetup.Modify();

        // [GIVEN] A quality inspection is created with tracking
        CreateInspectionWithTracking(PurOrdPurchaseLine, TempSpecTrackingSpecification, QltyInspectionHeader);

        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);

        // [WHEN] FindExistingInspection is called with item tracking
        // [WHEN] FindExistingInspection is called with item tracking
        TestFound := QltyInspectionCreate.FindExistingInspection(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] The test is found successfully
        LibraryAssert.IsTrue(TestFound, 'Should find tests.');

        // [THEN] Exactly one test is found
        LibraryAssert.AreEqual(1, FoundQltyInspectionHeader.Count(), 'Should find exact number of tests.');

        // [THEN] The found test matches the created test
        LibraryAssert.AreEqual(FoundQltyInspectionHeader."No.", QltyInspectionHeader."No.", 'Should find the correct test.');
    end;

    [Test]
    procedure FindExistingInspection_ByDocumentAndItemOnly()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
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
        SetupCreateInspectionPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Document and Item only"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Document and Item only";
        QltyManagementSetup.Modify();

        // [GIVEN] A quality inspection is created with tracking
        CreateInspectionWithTracking(PurOrdPurchaseLine, TempSpecTrackingSpecification, QltyInspectionHeader);

        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);

        // [WHEN] FindExistingInspection is called with document and item information
        TestFound := QltyInspectionCreate.FindExistingInspection(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] The test is found successfully
        LibraryAssert.IsTrue(TestFound, 'Should find tests.');

        // [THEN] Exactly one test is found
        LibraryAssert.AreEqual(1, FoundQltyInspectionHeader.Count(), 'Should find exact number of tests.');

        // [THEN] The found test matches the created test
        LibraryAssert.AreEqual(FoundQltyInspectionHeader."No.", QltyInspectionHeader."No.", 'Should find the correct test.');
    end;

    [Test]
    procedure FindExistingInspection_StandardSource_ShouldNotFind()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
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
        SetupCreateInspectionPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Standard Source Fields"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Standard Source Fields";
        QltyManagementSetup.Modify();

        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);

        // [WHEN] FindExistingInspection is called before any test is created
        TestFound := QltyInspectionCreate.FindExistingInspection(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        TestFound := QltyInspectionCreate.FindExistingInspection(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] No test is found
        LibraryAssert.IsFalse(TestFound, 'Should not find any tests.');

        // [THEN] The count of found tests matches the initial count (zero)
        LibraryAssert.AreEqual(QltyInspectionHeader.Count(), FoundQltyInspectionHeader.Count(), 'Should not find any tests.');
    end;

    [Test]
    procedure FindExistingInspection_BySourceRecord_ShouldNotFind()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
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
        SetupCreateInspectionPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Source Record"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Source Record";
        QltyManagementSetup.Modify();

        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);

        // [WHEN] FindExistingInspection is called before any test is created
        TestFound := QltyInspectionCreate.FindExistingInspection(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] No test is found
        LibraryAssert.IsFalse(TestFound, 'Should not find any tests.');
        LibraryAssert.AreEqual(QltyInspectionHeader.Count(), FoundQltyInspectionHeader.Count(), 'Should not find any tests.');
    end;

    [Test]
    procedure FindExistingInspection_ByTracking_ShouldNotFind()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
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
        SetupCreateInspectionPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Item Tracking"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Item Tracking";
        QltyManagementSetup.Modify();

        // [WHEN] FindExistingInspection is called before any test is created
        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);
        TestFound := QltyInspectionCreate.FindExistingInspection(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] No test is found
        LibraryAssert.IsFalse(TestFound, 'Should not find any tests.');
        // [THEN] The count of found tests matches the initial count (zero)
        LibraryAssert.AreEqual(QltyInspectionHeader.Count(), FoundQltyInspectionHeader.Count(), 'Should not find any tests.');
    end;

    [Test]
    procedure FindExistingInspection_ByDocAndItemOnly_ShouldNotFind()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
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
        SetupCreateInspectionPurchaseOrder(PurOrdPurchaseLine, TempSpecTrackingSpecification);

        // [GIVEN] The find existing behavior is set to "By Document and Item only"
        QltyManagementSetup.Get();
        FindBehavior := QltyManagementSetup."Find Existing Behavior";
        QltyManagementSetup."Find Existing Behavior" := QltyManagementSetup."Find Existing Behavior"::"By Document and Item only";
        QltyManagementSetup.Modify();

        // [WHEN] FindExistingInspection is called before any test is created
        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TrackingSpecificationRecordRef.GetTable(TempSpecTrackingSpecification);
        TestFound := QltyInspectionCreate.FindExistingInspection(false, PurchaseLineRecordRef, TrackingSpecificationRecordRef, Optional3RecordRef, Optional4RecordRef, FoundQltyInspectionHeader);

        QltyManagementSetup."Find Existing Behavior" := FindBehavior;
        QltyManagementSetup.Modify();

        // [THEN] No test is found
        LibraryAssert.IsFalse(TestFound, 'Should not find any tests.');
        // [THEN] The count of found tests matches the initial count (zero)
        LibraryAssert.AreEqual(QltyInspectionHeader.Count(), FoundQltyInspectionHeader.Count(), 'Should not find any tests.');
    end;

    [Test]
    procedure CreateReinspection()
    var
        Item: Record Item;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        ClaimedATestWasFoundOrCreated: Boolean;
    begin
        // [SCENARIO] Create a reinspection for an existing quality inspection

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        Initialize();
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] An inspection is created from the production order routing line
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been created');

        // [GIVEN] The created test is retrieved
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [WHEN] CreateReinspection is called with the existing test
        QltyInspectionCreate.CreateReinspection(QltyInspectionHeader, ReQltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        // [THEN] The reinspection has the same template code as the original test
        LibraryAssert.AreEqual(QltyInspectionHeader."Template Code", ReQltyInspectionHeader."Template Code", 'Template does not match.');
        // [THEN] The reinspection has the same test number as the original test
        LibraryAssert.AreEqual(QltyInspectionHeader."No.", ReQltyInspectionHeader."No.", 'Test No. does not match.');
        // [THEN] The reinspection number is incremented by 1
        LibraryAssert.AreEqual((QltyInspectionHeader."Reinspection No." + 1), ReQltyInspectionHeader."Reinspection No.", 'Reinspection No. did not increment.');
    end;

    [Test]
    procedure GetCreatedTest()
    var
        Item: Record Item;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        ClaimedATestWasFoundOrCreated: Boolean;
        TestStillExists: Boolean;
    begin
        // [SCENARIO] Retrieve the most recently created quality inspection

        // [GIVEN] A quality inspection template, generation rule, item, and production order with routing line are set up
        Initialize();
        SetupCreateInspectionProductionOrder(QltyInspectionTemplateHdr, QltyInspectionGenRule, Item, ProdProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] An inspection is created from the production order routing line
        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        ClaimedATestWasFoundOrCreated := QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, true);
        LibraryAssert.IsTrue(ClaimedATestWasFoundOrCreated, 'A test should have been created');

        // [GIVEN] The last created test is found in the database
        QltyInspectionHeader.FindLast();

        // [WHEN] GetCreatedTest is called to retrieve the most recently created test
        TestStillExists := QltyInspectionCreate.GetCreatedTest(CreatedQltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        // [THEN] The test is confirmed to exist
        LibraryAssert.IsTrue(TestStillExists, 'Test should be said to exist.');
        // [THEN] The retrieved test has the same test number as the last created test
        LibraryAssert.AreEqual(QltyInspectionHeader."No.", CreatedQltyInspectionHeader."No.", 'Should get the last created test.');
        // [THEN] The retrieved test has the same reinspection number as the last created test
        LibraryAssert.AreEqual(QltyInspectionHeader."Reinspection No.", CreatedQltyInspectionHeader."Reinspection No.", 'Should get the last created test.');
    end;

    [Test]
    procedure CreateMultipleTestsForMarkedTrackingSpec()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Location: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        CountBefore: Integer;
        CountAfter: Integer;
    begin
        // [SCENARIO] Create quality inspections for multiple marked tracking specifications from purchase lines

        // [GIVEN] Quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetup();
        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        // [GIVEN] A generation rule is created for purchase lines
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);
        // [GIVEN] A location, lot tracked item, and vendor are created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        QltyInspectionUtility.CreateLotTrackedItem(Item);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A first purchase order is created, released, and received with lot tracking
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, '', PurchaseHeader[1], PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader[1]);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader[1], PurchaseLine);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        // [GIVEN] A tracking specification is created and marked for the first purchase order
        PurchLineReserve.InitFromPurchLine(TempSpecTrackingSpecification, PurchaseLine);
        TempSpecTrackingSpecification."Entry No." := 1;
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
        TempSpecTrackingSpecification.Insert();
        TempSpecTrackingSpecification.Mark(true);

        // [GIVEN] A second purchase order is created, released, and received with lot tracking
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, '', PurchaseHeader[2], PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader[2]);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader[2], PurchaseLine);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        // [GIVEN] A tracking specification is created and marked for the second purchase order
        PurchLineReserve.InitFromPurchLine(TempSpecTrackingSpecification, PurchaseLine);
        TempSpecTrackingSpecification."Entry No." := 2;
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
        TempSpecTrackingSpecification.Insert();
        TempSpecTrackingSpecification.Mark(true);
        // [GIVEN] The initial test count is recorded
        CountBefore := QltyInspectionHeader.Count();

        // [WHEN] CreateMultipleTestsForMarkedTrackingSpecification is called with the marked tracking specifications
        QltyInspectionCreate.CreateMultipleTestsForMarkedTrackingSpecification(TempSpecTrackingSpecification);
        CountAfter := QltyInspectionHeader.Count();

        QltyInspectionGenRule.Delete();

        // [THEN] Two tests are created (one for each marked tracking specification)
        LibraryAssert.AreEqual((CountBefore + 2), CountAfter, 'The tests should have been created.');
        // [THEN] One test is created for the first purchase order
        QltyInspectionHeader.SetRange("Source Document No.", PurchaseHeader[1]."No.");
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'Should have created an inspection.');
        // [THEN] One test is created for the second purchase order
        QltyInspectionHeader.SetRange("Source Document No.", PurchaseHeader[2]."No.");
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'Should have created an inspection.');
    end;

    [Test]
    procedure CreateMultipleTestsForMarkedTrackingSpec_ExistingReservationEntries_TrackingSpec()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
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
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        CountBefore: Integer;
        CountAfter: Integer;
    begin
        // [SCENARIO] Create quality inspections for marked tracking specifications with existing reservation entries

        // [GIVEN] The quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetup();
        // [GIVEN] A quality inspection template with 3 tests and a prioritized generation rule for Purchase Line are created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);
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
        PurchLineReserve.InitFromPurchLine(TempSpecTrackingSpecification, PurchaseLine);
        TempSpecTrackingSpecification."Entry No." := 1;
        AllReservationEntry.FindSet();
        AllReservationEntry.Next();
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(AllReservationEntry);
        TempSpecTrackingSpecification.Insert();
        TempSpecTrackingSpecification.Mark(true);

        // [GIVEN] Another purchase order is created (noise order)
        QltyPurOrderGenerator.CreatePurchaseOrder(4, Location, Item, Vendor, '', NoiseOrderPurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] The current count of quality inspection headers is recorded
        CountBefore := QltyInspectionHeader.Count();
        // [WHEN] CreateMultipleTestsForMarkedTrackingSpecification is called with the marked tracking specification
        QltyInspectionCreate.CreateMultipleTestsForMarkedTrackingSpecification(TempSpecTrackingSpecification);
        CountAfter := QltyInspectionHeader.Count();
        QltyInspectionGenRule.Delete();

        // [THEN] Only 1 test is created
        LibraryAssert.AreEqual((CountBefore + 1), CountAfter, 'Only 1 test should have been created.');
        // [THEN] The created test is associated with the preferred order purchase header
        QltyInspectionHeader.SetRange("Source Document No.", PreferredOrderPurchaseHeader."No.");
        LibraryAssert.AreEqual(1, QltyInspectionHeader.Count(), 'Should have created 1 test for a purch order.');
    end;

    [Test]
    procedure CreateMultipleTestsForMultipleRecords()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        ProdOrderRoutingLineRecordRef: RecordRef;
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create quality inspections for multiple production order routing lines

        // [GIVEN] The quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetup();
        // [GIVEN] A quality inspection template with 3 tests and a prioritized generation rule for Prod. Order Routing Line are created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);

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

        // [GIVEN] The current count of quality inspection headers is recorded
        BeforeCount := QltyInspectionHeader.Count();
        // [WHEN] CreateMultipleTestsForMultipleRecords is called with the RecordRef containing 3 routing lines
        QltyInspectionCreate.CreateMultipleTestsForMultipleRecords(ProdOrderRoutingLineRecordRef, false);
        AfterCount := QltyInspectionHeader.Count();

        QltyInspectionGenRule.Delete();

        // [THEN] 3 tests are created (one for each production order)
        LibraryAssert.AreEqual((BeforeCount + 3), AfterCount, 'Did not create the correct number of tests.');
        // [THEN] Each production order has exactly 1 test associated with it
        foreach ProductionOrder in OrdersList do begin
            CreatedQltyInspectionHeader.SetRange("Source Document No.", ProductionOrder);
            CreatedQltyInspectionHeader.FindFirst();
            LibraryAssert.AreEqual(1, CreatedQltyInspectionHeader.Count(), 'Did not create test for correct production order.');
        end;
    end;

    [Test]
    procedure CreateMultipleTestsForMultipleRecords_ShowTestsPage()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        ProdOrderRoutingLineRecordRef: RecordRef;
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create inspections and display the test list page for multiple production order routing lines

        // [GIVEN] The quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetup();
        // [GIVEN] The quality management setup is configured to show Automatic and manually created inspections
        QltyManagementSetup.Get();
        QltyManagementSetup."Show Inspection Behavior" := QltyManagementSetup."Show Inspection Behavior"::"Automatic and manually created inspections";
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::OnProductionOutputPost;
        QltyManagementSetup.Modify();
        // [GIVEN] A quality inspection template with 3 tests and a prioritized generation rule for Prod. Order Routing Line are created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);

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

        // [GIVEN] The current count of quality inspection headers is recorded
        BeforeCount := QltyInspectionHeader.Count();
        // [WHEN] CreateMultipleTestsForMultipleRecords is called with the RecordRef containing 3 routing lines
        QltyInspectionCreate.CreateMultipleTestsForMultipleRecords(ProdOrderRoutingLineRecordRef, false);
        AfterCount := QltyInspectionHeader.Count();

        QltyInspectionGenRule.Delete();
        QltyManagementSetup."Show Inspection Behavior" := QltyManagementSetup."Show Inspection Behavior"::"Do not show created inspections";
        QltyManagementSetup.Modify();

        // [THEN] 3 tests are created (one for each production order)
        LibraryAssert.AreEqual((BeforeCount + 3), AfterCount, 'Did not create the correct number of tests.');
        // [THEN] Each production order has exactly 1 test associated with it
        foreach ProductionOrder in OrdersList do begin
            CreatedQltyInspectionHeader.SetRange("Source Document No.", ProductionOrder);
            CreatedQltyInspectionHeader.FindFirst();
            LibraryAssert.AreEqual(1, CreatedQltyInspectionHeader.Count(), 'Did not create test for correct production order.');
        end;
    end;

    [Test]
    procedure CreateMultipleTestsForSingleRecords_ShowTestPage()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        ProdOrderRoutingLineRecordRef: RecordRef;
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a single test and display the test page for one production order routing line

        // [GIVEN] The quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetup();
        // [GIVEN] The quality management setup is configured to show Automatic and manually created inspections
        QltyManagementSetup.Get();
        QltyManagementSetup."Show Inspection Behavior" := QltyManagementSetup."Show Inspection Behavior"::"Automatic and manually created inspections";
        QltyManagementSetup.Modify();
        // [GIVEN] A quality inspection template with 3 tests and a prioritized generation rule for Prod. Order Routing Line are created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);

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

        // [GIVEN] The current count of quality inspection headers is recorded
        BeforeCount := QltyInspectionHeader.Count();
        // [WHEN] CreateMultipleTestsForMultipleRecords is called with the RecordRef containing 1 routing line
        QltyInspectionCreate.CreateMultipleTestsForMultipleRecords(ProdOrderRoutingLineRecordRef, false);
        AfterCount := QltyInspectionHeader.Count();

        QltyInspectionGenRule.Delete();
        QltyManagementSetup."Show Inspection Behavior" := QltyManagementSetup."Show Inspection Behavior"::"Do not show created inspections";
        QltyManagementSetup.Modify();

        // [THEN] 1 test is created
        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Did not create the correct number of tests.');
        // [THEN] The created test is associated with the selected production order
        CreatedQltyInspectionHeader.SetRange("Source Document No.", ProductionOrder);
        CreatedQltyInspectionHeader.FindFirst();
        LibraryAssert.AreEqual(1, CreatedQltyInspectionHeader.Count(), 'Did not create test for correct production order.');
    end;

    [Test]
    procedure CreateMultipleTestsForMultipleRecords_NoCreate()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLineRecordRef: RecordRef;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Verify an error is returned when attempting to create inspections with no valid records

        // [GIVEN] An empty RecordRef for Prod. Order Routing Line is opened
        Initialize();
        ProdOrderRoutingLineRecordRef.Open(Database::"Prod. Order Routing Line", true);
        // [GIVEN] The current count of quality inspection headers is recorded
        BeforeCount := QltyInspectionHeader.Count();

        // [WHEN] CreateMultipleTestsForMultipleRecords is called with an empty RecordRef
        asserterror QltyInspectionCreate.CreateMultipleTestsForMultipleRecords(ProdOrderRoutingLineRecordRef, false);
        // [THEN] An error is raised indicating unable to create an inspection for the record
        LibraryAssert.ExpectedError(StrSubstNo(UnableToCreateATestForRecordErr, ProdOrderRoutingLineRecordRef.Name));
        // [THEN] No tests are created
        AfterCount := QltyInspectionHeader.Count();
        LibraryAssert.AreEqual(BeforeCount, AfterCount, 'Should not have created tests.');
    end;

    [Test]
    procedure CreateMultipleTestsForMultipleRecords_NoGenRule_ShouldError()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        ProdOrderRoutingLineRecordRef: RecordRef;
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Verify an error is returned when no generation rule exists for production order routing lines

        // [GIVEN] The quality management setup is initialized
        Initialize();
        QltyInspectionUtility.EnsureSetup();
        // [GIVEN] A quality inspection template with 3 tests is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        // [GIVEN] All generation rules are deleted to simulate missing rule scenario
        if not QltyInspectionGenRule.IsEmpty() then
            QltyInspectionGenRule.DeleteAll();

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
        asserterror QltyInspectionCreate.CreateMultipleTestsForMultipleRecords(ProdOrderRoutingLineRecordRef, false);
        // [THEN] An error is raised indicating unable to create an inspection for the parent or child record
        LibraryAssert.ExpectedError(StrSubstNo(UnableToCreateATestForParentOrChildErr, ProdOrderLine.TableName, ProdOrderRoutingLineRecordRef.Name));
    end;

    local procedure CreateInspectionWithTracking(var PurOrdPurchaseLine: Record "Purchase Line"; var TempSpecTrackingSpecification: Record "Tracking Specification" temporary; var OutQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        QltyInspectionCreate2: Codeunit "Qlty. Inspection - Create";
        PurchaseLineRecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        QltyInspectionCreate2.CreateInspectionWithMultiVariantsAndTemplate(PurchaseLineRecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, true, '');
        QltyInspectionCreate2.GetCreatedTest(OutQltyInspectionHeader);
    end;

    local procedure SetupCreateInspectionPurchaseOrder(var OutPurchaseLine: Record "Purchase Line"; var TempOutSpecTrackingSpecification: Record "Tracking Specification" temporary)
    var
        Location: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        PurOrderPurchaseHeader: Record "Purchase Header";
        ReservationEntry: Record "Reservation Entry";
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
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
    begin
        QltyInspectionUtility.EnsureSetup();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line");

        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code, '', '');
        LibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, LotNoSeries.Code, '', LotItemTrackingCode.Code);
        LibraryPurchase.CreateVendor(Vendor);
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, '', PurOrderPurchaseHeader, OutPurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurOrderPurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurOrderPurchaseHeader, OutPurchaseLine);
        OutPurchaseLine.Get(OutPurchaseLine."Document Type", OutPurchaseLine."Document No.", OutPurchaseLine."Line No.");
        TempOutSpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
    end;

    local procedure SetupCreateInspectionProductionOrder(var QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; var QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule"; var Item: Record Item; var ProdProductionOrder: Record "Production Order"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        GenQltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
    begin
        QltyInspectionUtility.EnsureSetup();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);
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
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        QltyInspectionUtility.CreateItemJournalTemplateAndBatch(Enum::"Item Journal Template Type"::Output, ItemJournalBatch);
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
    procedure AutomatedTestListPageHandler(var QltyInspectionList: TestPage "Qlty. Inspection List")
    begin
    end;

    [PageHandler]
    procedure AutomatedSingleTestPageHandler(var QltyInspection: TestPage "Qlty. Inspection")
    begin
    end;
}
