// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.QualityManagement.Configuration;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Sales.Document;
using Microsoft.Test.QualityManagement.TestLibraries;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Worksheet;
using System.Apps;
using System.Device;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.TestLibraries.Device;
using System.TestLibraries.Utilities;

codeunit 139967 "Qlty. Tests - Test Table"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        NotFirstLoop: Boolean;
        AssistEditTemplateValue: Text;
        SourceCustomTok: Label 'Source Custom 1', Locked = true;
        StatusTok: Label 'Status';
        UserTok: Label 'OrigUser';
        TestValueTxt: Label 'test value.';
        ItemIsTrackingErr: Label 'The item [%1] is %2 tracked. Please define a %2 number before finishing the test. You can change whether this is required on the Quality Management Setup card.', Comment = '%1=the item number. %2=Lot or serial token';
        LotTok: Label 'lot', Locked = true;
        SerialTok: Label 'serial', Locked = true;
        PackageTok: Label 'package', Locked = true;
        ItemInsufficientPostedErr: Label 'The item [%1] is %2 tracked and requires posted inventory before it can be finished. The %2 %3 has inventory of %4. You can change whether this is required on the Quality Management Setup card.', Comment = '%1=the item number. %2=Lot or serial token, %3=the lot or serial, %4=';
        ItemInsufficientPostedOrUnpostedErr: Label 'The item [%1] is %2 tracked and requires either posted inventory or a reservation entry for it before it can be finished. The %2 %3 has inventory of %4. You can change whether this is required on the Quality Management Setup card.', Comment = '%1=the item number. %2=Lot or serial token, %3=the lot or serial, %4=';
        MeasurementNoteTxt: Label 'A measurement note for the associated line item.';
        UpdatedMeasurementNoteTxt: Label 'An updated measurement note for the associated line item.';
        OptionsTok: Label 'Option1,Option2,Option3';
        Option1Tok: Label 'Option1';
        NoTok: Label 'No';
        ExistingTestErr: Label 'The field %1 exists on %2 tests (such as %3 with template %4). The field can not be deleted if it is being used on a Quality Inspection.', Comment = '%1=the field, %2=count of tests, %3=one example test, %4=example template.';
        DescriptionTxt: Label 'Specific Gravity';
        SuggestedCodeTxtTestValueTxt: Label 'SPECIFICGRAVITY';
        Description2Txt: Label '><{}.@!`~''"|\/?&*()-_$#-=,%%:ELECTRICAL CONDUCTIVITY';
        SuggestedCodeTxtTestValue2Txt: Label 'LCTRCLCNDCTVT';
        AllowableValuesExpressionTok: Label '1..99';
        PassConditionExpressionTok: Label '1..5';
        PassConditionDescExpressionTok: Label '1 to 5';
        WarehouseFromTableFilterTok: Label '= %1|= %2', Comment = '%1=warehouse entry,%2=warehouse journal line';
        DefaultExpressionTok: Label '[No.][Source Item No.]', Locked = true;
        CalculatedExpressionTok: Label '%1%2%3', Comment = '%1=Test No.,%2=Item No.,%3=Table Name', Locked = true;
        ConditionFilterOutputTok: Label 'WHERE(Entry Type=FILTER(Output))';
        ConditionFilterProductionTok: Label 'WHERE(Order Type=FILTER(Production))';
        ConditionFilterPurchaseReceiptTok: Label 'WHERE(Document Type=FILTER(Purchase Receipt))';
        ConditionFilterSalesReturnReceiptTok: Label 'WHERE(Document Type=FILTER(Sales Return Receipt))';
        ConditionFilterTransferReceiptTok: Label 'WHERE(Document Type=FILTER(Transfer Receipt))';
        ConditionFilterDirectTransferTok: Label 'WHERE(Document Type=FILTER(Direct Transfer))';
        ConditionFilterPurchaseTok: Label 'WHERE(Entry Type=FILTER(Purchase))';
        ConditionFilterSaleTok: Label 'WHERE(Entry Type=FILTER(Sale))';
        ConditionFilterTransferTok: Label 'WHERE(Entry Type=FILTER(Transfer))';
        ConditionFilterAssemblyOutputTok: Label 'WHERE(Entry Type=FILTER(Assembly Output))';
        ConditionFilterWhseReceiptTok: Label 'WHERE(Whse. Document Type=FILTER(Receipt))';
        ConditionFilterPostedRcptTok: Label 'WHERE(Reference Document=FILTER(Posted Rcpt.))';
        ConditionFilterInternalPutAwayTok: Label 'WHERE(Whse. Document Type=FILTER(Internal Put-away))';
        ConditionFilterMovementTok: Label 'WHERE(Entry Type=FILTER(Movement))';
        GradeCode1Tok: Label '><{}.@!`~''';
        GradeCode2Tok: Label '"|\/?&*()';
        CannotBeRemovedExistingTestErr: Label 'This grade cannot be removed because it is being used actively on at least one existing Quality Inspection. If you no longer want to use this grade consider changing the description, or consider changing the visibility not to be promoted. You can also change the "Copy" setting on the grade.';
        IsInitialized: Boolean;

    [Test]
    procedure Table_GetControlCaptionClass()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
    begin
        // [SCENARIO] GetControlCaptionClass returns the correct caption for a custom control field
        Initialize();

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [GIVEN] Control information is determined for Source Custom field
        QltyInspectionHeader.DetermineControlInformation(SourceCustomTok);

        // [WHEN] GetControlCaptionClass is called for Source Custom field
        // [THEN] The method returns "Status" as the caption
        LibraryAssert.AreEqual(StatusTok, QltyInspectionHeader.GetControlCaptionClass(SourceCustomTok), 'Should have returned "Status".');

        QltyInspectionGenRule.DeleteAll();
    end;

    [Test]
    procedure Table_GetControlVisibleState()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
    begin
        // [SCENARIO] GetControlVisibleState returns true for a visible custom control field

        Initialize();

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [GIVEN] Control information is determined for Source Custom field
        QltyInspectionHeader.DetermineControlInformation(SourceCustomTok);

        // [WHEN] GetControlVisibleState is called for Source Custom field
        // [THEN] The method returns true indicating the control should be visible
        LibraryAssert.IsTrue(QltyInspectionHeader.GetControlVisibleState(SourceCustomTok), 'Should show Custom 1 (Status).');

        QltyInspectionGenRule.DeleteAll();
    end;

    [Test]
    procedure Table_GetRelatedItem()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Location: Record Location;
        Item: Record Item;
        FoundItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // [SCENARIO] GetRelatedItem successfully retrieves the item associated with an inspection

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order with the item is created
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, Item, PurchaseHeader, PurchaseLine);

        // [GIVEN] An inspection is created from the purchase line
        QltyInspectionUtility.CreateInspectionWithPurchaseLine(PurchaseLine, ConfigurationToLoadQltyInspectionTemplateHdr.Code, QltyInspectionHeader);

        // [WHEN] GetRelatedItem is called
        // [THEN] The method finds the item and returns the correct item number
        LibraryAssert.IsTrue(QltyInspectionHeader.GetRelatedItem(FoundItem), 'Should find item.');
        LibraryAssert.AreEqual(Item."No.", FoundItem."No.", 'Should be same item.');

        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure Table_ValidateAssignedUserID_AssignFromBlank()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] An inspection with no assigned user can be assigned to the current user

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase with untracked item
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        // [GIVEN] The inspection has no assigned user
        LibraryAssert.IsTrue(QltyInspectionHeader."Assigned User ID" = '', 'Should not have user assigned.');

        // [WHEN] The Assigned User ID is validated with the current user
        QltyInspectionHeader.Validate("Assigned User ID", UserId());

        // [THEN] The user is successfully assigned to the inspection
        LibraryAssert.IsTrue(QltyInspectionHeader."Assigned User ID" = UserId(), 'User should be assigned.');
    end;

    [Test]
    procedure Table_AssignToSelf()
    var
        User: Record User;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPermissions: Codeunit "Library - Permissions";
    begin
        // [SCENARIO] An inspection assigned to another user can be reassigned to the current user using AssignToSelf

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase with untracked item
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        // [GIVEN] An inspection user is created if it doesn't exist
        User.SetRange("User Name", UserTok);
        if not User.FindFirst() then
            LibraryPermissions.CreateUser(User, UserTok, false);

        // [GIVEN] The inspection is assigned to the test user
        QltyInspectionHeader."Assigned User ID" := User."User Name";
        QltyInspectionHeader.Modify();

        // [WHEN] AssignToSelf is called
        QltyInspectionHeader.AssignToSelf();

        // [THEN] The inspection is reassigned to the current user
        LibraryAssert.IsTrue(QltyInspectionHeader."Assigned User ID" = UserId(), 'User should be assigned.');
    end;

    [Test]
    procedure Table_ValidateAssignedUserID_CannotChangeTests()
    var
        User: Record User;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPermissions: Codeunit "Library - Permissions";
    begin
        // [SCENARIO] An inspection can be reassigned from one user to another without persisting the change

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase with untracked item
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        // [GIVEN] An inspection user is created if it doesn't exist
        User.SetRange("User Name", UserTok);
        if not User.FindFirst() then
            LibraryPermissions.CreateUser(User, UserTok, false);

        // [GIVEN] The inspection is assigned to the test user (not modified)
        QltyInspectionHeader."Assigned User ID" := User."User Name";

        // [WHEN] The Assigned User ID is validated with the current user
        QltyInspectionHeader.Validate("Assigned User ID", UserId());

        // [THEN] The user is successfully reassigned
        LibraryAssert.IsTrue(QltyInspectionHeader."Assigned User ID" = UserId(), 'User should be assigned.');
    end;

    [Test]
    procedure Table_ValidateAssignedUserID_CannotChangeTests_ShouldErr()
    var
        User: Record User;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPermissions: Codeunit "Library - Permissions";
    begin
        // [SCENARIO] An inspection assigned to another user can be reassigned to the current user after persisting

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase with untracked item
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        // [GIVEN] An inspection user is created if it doesn't exist
        User.SetRange("User Name", UserTok);
        if not User.FindFirst() then
            LibraryPermissions.CreateUser(User, UserTok, false);

        // [GIVEN] The inspection is assigned to the test user and modified
        QltyInspectionHeader."Assigned User ID" := User."User Name";
        QltyInspectionHeader.Modify();

        // [WHEN] The Assigned User ID is validated with the current user
        QltyInspectionHeader.Validate("Assigned User ID", UserId());

        // [THEN] The user is successfully reassigned to the current user
        LibraryAssert.AreEqual(UserId(), QltyInspectionHeader."Assigned User ID", 'smaller test for express.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure Table_ValidateSampleSize_SampleSizeLargerThanSourceQty()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] When sample size exceeds source quantity, it is automatically adjusted to match source quantity

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase with source quantity of 100
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [WHEN] Sample Size is validated with value 101 (larger than source)
        QltyInspectionHeader.Validate("Sample Size", 101);

        // [THEN] Sample size is adjusted to source quantity (100)
        LibraryAssert.IsTrue(QltyInspectionHeader."Sample Size" = 100, 'Sample size should be source quantity.');
    end;

    [Test]
    procedure Table_DefaultSampleSize_FromFixedQuantity()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] When template uses Fixed Quantity sample source, inspection defaults to the fixed amount

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] Template is configured with Fixed Quantity sample source of 5
        ConfigurationToLoadQltyInspectionTemplateHdr."Sample Source" := ConfigurationToLoadQltyInspectionTemplateHdr."Sample Source"::"Fixed Quantity";
        ConfigurationToLoadQltyInspectionTemplateHdr."Sample Fixed Amount" := 5;
        ConfigurationToLoadQltyInspectionTemplateHdr."Sample Percentage" := 99;
        ConfigurationToLoadQltyInspectionTemplateHdr.Modify(false);

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [WHEN] An inspection is created from purchase with source quantity of 200
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 200, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [THEN] Sample size equals the fixed quantity (5)
        LibraryAssert.AreEqual(ConfigurationToLoadQltyInspectionTemplateHdr."Sample Fixed Amount", QltyInspectionHeader."Sample Size", 'Sample size should be the fixed quantity defined ');
    end;

    [Test]
    procedure Table_DefaultSampleSize_FromFixedQuantity_MaxesOut()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] When fixed quantity exceeds source quantity, sample size is capped at source quantity

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] Template is configured with extremely large fixed quantity (999999)
        ConfigurationToLoadQltyInspectionTemplateHdr."Sample Source" := ConfigurationToLoadQltyInspectionTemplateHdr."Sample Source"::"Fixed Quantity";
        ConfigurationToLoadQltyInspectionTemplateHdr."Sample Fixed Amount" := 999999;
        ConfigurationToLoadQltyInspectionTemplateHdr."Sample Percentage" := 99;
        ConfigurationToLoadQltyInspectionTemplateHdr.Modify(false);

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [WHEN] An inspection is created from purchase with source quantity of 200
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 200, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [THEN] Sample size is capped at source quantity (200)
        LibraryAssert.AreEqual(200, QltyInspectionHeader."Sample Size", 'Sample size should have maxed out to the highest source quantity.');
    end;

    [Test]
    procedure Table_DefaultSampleSize_FromPercentage()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] When template uses Percent of Quantity sample source, inspection defaults to calculated percentage

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] Template is configured with Percent of Quantity sample source at 99%
        ConfigurationToLoadQltyInspectionTemplateHdr."Sample Source" := ConfigurationToLoadQltyInspectionTemplateHdr."Sample Source"::"Percent of Quantity";
        ConfigurationToLoadQltyInspectionTemplateHdr."Sample Fixed Amount" := 5;
        ConfigurationToLoadQltyInspectionTemplateHdr."Sample Percentage" := 99;
        ConfigurationToLoadQltyInspectionTemplateHdr.Modify(false);

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [WHEN] An inspection is created from purchase with source quantity of 200
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 200, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [THEN] Sample size equals 198 (99% of 200, rounded)
        LibraryAssert.AreEqual(198, QltyInspectionHeader."Sample Size", 'Sample size should be a rounded up discrete amount based on the input size against the percentage defined on the template. ');
    end;

    [Test]
    procedure Table_OnDelete_CanDeleteOpenTest()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        FoundQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] An open inspection can be successfully deleted

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase with untracked item
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        QltyInspectionGenRule.Delete();

        // [WHEN] The inspection is deleted
        QltyInspectionHeader.Delete(true);

        // [THEN] The inspection no longer exists in the database
        FoundQltyInspectionHeader.SetRange("No.", QltyInspectionHeader."No.");
        LibraryAssert.IsTrue(FoundQltyInspectionHeader.IsEmpty(), 'Should not find an inspection.');
    end;

    [Test]
    [HandlerFunctions('EditLargeTextModalPageHandler')]
    procedure Table_AssistEditTestField()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] AssistEditTestField allows editing an inspection field value through a modal page

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template with one field is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase with untracked item
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [GIVEN] The inspection line is retrieved
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.", 10000);

        // [WHEN] AssistEditTestField is called on the field code
        QltyInspectionHeader.AssistEditTestField(QltyInspectionLine."Field Code");

        // [THEN] The test value is updated through the modal page handler
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.", 10000);
        LibraryAssert.AreEqual(TestValueTxt, QltyInspectionLine."Test Value", 'Test value should match.');

        QltyInspectionGenRule.Delete();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSummaryModalPageHandler')]
    procedure Table_AssistEditLotNo()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        FirstPurchaseLine: Record "Purchase Line";
        FirstReservationEntry: Record "Reservation Entry";
        SecondPurchaseLine: Record "Purchase Line";
        SecondReservationEntry: Record "Reservation Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        QltyInspection: TestPage "Qlty. Inspection";
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        // [SCENARIO] AssistEditLotNo allows changing the lot number on an inspection through item tracking summary

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template with one field is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A lot-tracked item is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order is created with first lot number
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, '', PurchaseHeader, FirstPurchaseLine, FirstReservationEntry);

        // [GIVEN] A second purchase line is added with different lot number
        LibraryPurchase.CreatePurchaseLine(SecondPurchaseLine, PurchaseHeader, SecondPurchaseLine.Type::Item, Item."No.", 100);
        QltyPurOrderGenerator.AddTrackingForPurchaseLine(SecondPurchaseLine, Item, SecondReservationEntry);

        // [GIVEN] An inspection is created from the second purchase line with its lot number
        RecordRef.GetTable(SecondPurchaseLine);
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(SecondReservationEntry);
        if QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, true, '') then
            QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on the Lot No. field
        QltyInspection."Lot No.".AssistEdit();

        // [THEN] The lot number is changed to the first lot number through modal page handler
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.AreEqual(FirstReservationEntry."Lot No.", QltyInspectionHeader."Source Lot No.", 'Should be other source lot no.');

        QltyInspectionGenRule.Delete();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSummaryModalPageHandler')]
    procedure Table_AssistEditSerialNo()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Vendor: Record Vendor;
        ToUseNoSeries: Record "No. Series";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        QltyInspection: TestPage "Qlty. Inspection";
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        // [SCENARIO] AssistEditSerialNo allows changing the serial number on an inspection through item tracking summary

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template with one field is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A serial-tracked item is created
        QltyInspectionUtility.CreateSerialTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order is created with serial tracking
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, Vendor, '', PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] An inspection is created from the purchase line with its serial number
        RecordRef.GetTable(PurchaseLine);
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
        QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, true, '');
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on the Serial No. field
        QltyInspection."Serial No.".AssistEdit();

        // [THEN] The serial number is changed to a different serial number through modal page handler
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.AreNotEqual(ReservationEntry."Serial No.", QltyInspectionHeader."Source Serial No.", 'Should be new source serial no.');

        QltyInspectionGenRule.Delete();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSummaryModalPageHandler')]
    procedure Table_AssistEditPackageNo()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ToUseNoSeries: Record "No. Series";
        Location: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        FirstPurchaseLine: Record "Purchase Line";
        FirstReservationEntry: Record "Reservation Entry";
        SecondPurchaseLine: Record "Purchase Line";
        SecondReservationEntry: Record "Reservation Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        QltyInspection: TestPage "Qlty. Inspection";
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        // [SCENARIO] AssistEditPackageNo allows changing the package number on an inspection through item tracking summary

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template with one field is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A package-tracked item with no series is created
        QltyInspectionUtility.CreatePackageTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order is created with first package number
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, Vendor, '', PurchaseHeader, FirstPurchaseLine, FirstReservationEntry);

        // [GIVEN] A second purchase line is added with different package number
        LibraryPurchase.CreatePurchaseLine(SecondPurchaseLine, PurchaseHeader, SecondPurchaseLine.Type::Item, Item."No.", 10);
        QltyPurOrderGenerator.AddTrackingForPurchaseLine(SecondPurchaseLine, Item, SecondReservationEntry);

        // [GIVEN] An inspection is created from the second purchase line with its package number
        RecordRef.GetTable(SecondPurchaseLine);
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(SecondReservationEntry);
        QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, true, '');
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on the Source Package No. field
        QltyInspection."Source Package No.".AssistEdit();

        // [THEN] The package number is changed to the first package number through modal page handler
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.AreEqual(FirstReservationEntry."Package No.", QltyInspectionHeader."Source Package No.", 'Should be other source package no.');

        QltyInspectionGenRule.Delete();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSummaryModalPageHandler_ChooseSingleDocument')]
    procedure Table_AssistEditLotNo_ChooseSingleDocument()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        FirstPurchaseLine: Record "Purchase Line";
        FirstReservationEntry: Record "Reservation Entry";
        SecondPurchaseLine: Record "Purchase Line";
        SecondReservationEntry: Record "Reservation Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        QltyInspection: TestPage "Qlty. Inspection";
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        // [SCENARIO] AssistEditLotNo allows selecting lot number from single document tracking entries

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template with one field is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A lot-tracked item is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Two purchase lines on same document with different lot numbers are created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, Vendor, '', PurchaseHeader, FirstPurchaseLine, FirstReservationEntry);
        LibraryPurchase.CreatePurchaseLine(SecondPurchaseLine, PurchaseHeader, SecondPurchaseLine.Type::Item, Item."No.", 100);
        QltyPurOrderGenerator.AddTrackingForPurchaseLine(SecondPurchaseLine, Item, SecondReservationEntry);

        // [GIVEN] An inspection is created from the second purchase line
        RecordRef.GetTable(SecondPurchaseLine);
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(SecondReservationEntry);
        if QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, true, '') then
            QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on Lot No. field (handler chooses from single document)
        QltyInspection."Lot No.".AssistEdit();

        // [THEN] The lot number is changed to first lot number from same document
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.AreEqual(FirstReservationEntry."Lot No.", QltyInspectionHeader."Source Lot No.", 'Should be other source lot no.');

        QltyInspectionGenRule.Delete();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSummaryModalPageHandler_ChooseSingleDocument')]
    procedure Table_AssistEditSerialNo_ChooseSingleDocument()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Vendor: Record Vendor;
        ToUseNoSeries: Record "No. Series";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        QltyInspection: TestPage "Qlty. Inspection";
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        // [SCENARIO] AssistEditSerialNo allows selecting serial number from single document tracking entries

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A prioritized rule is created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A serial-tracked item is created
        QltyInspectionUtility.CreateSerialTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order with serial tracking is created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, Vendor, '', PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] An inspection is created from the purchase line
        RecordRef.GetTable(PurchaseLine);
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
        QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, true, '');
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on Serial No. field (handler chooses from single document)
        QltyInspection."Serial No.".AssistEdit();

        // [THEN] The serial number is changed to a different serial number
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.AreNotEqual(ReservationEntry."Serial No.", QltyInspectionHeader."Source Serial No.", 'Should be new source serial no.');

        QltyInspectionGenRule.Delete();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSummaryModalPageHandler_ChooseSingleDocument')]
    procedure Table_AssistEditPackageNo_ChooseSingleDocument()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ToUseNoSeries: Record "No. Series";
        Location: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        FirstPurchaseLine: Record "Purchase Line";
        FirstReservationEntry: Record "Reservation Entry";
        SecondPurchaseLine: Record "Purchase Line";
        SecondReservationEntry: Record "Reservation Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        QltyInspection: TestPage "Qlty. Inspection";
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        // [SCENARIO] AssistEditPackageNo allows selecting package number from single document tracking entries

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A prioritized rule is created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A package-tracked item is created
        QltyInspectionUtility.CreatePackageTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Two purchase lines on same document with different package numbers are created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, Vendor, '', PurchaseHeader, FirstPurchaseLine, FirstReservationEntry);
        LibraryPurchase.CreatePurchaseLine(SecondPurchaseLine, PurchaseHeader, SecondPurchaseLine.Type::Item, Item."No.", 10);
        QltyPurOrderGenerator.AddTrackingForPurchaseLine(SecondPurchaseLine, Item, SecondReservationEntry);

        // [GIVEN] An inspection is created from the second purchase line
        RecordRef.GetTable(SecondPurchaseLine);
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(SecondReservationEntry);
        QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, true, '');
        QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on Source Package No. field (handler chooses from single document)
        QltyInspection."Source Package No.".AssistEdit();

        // [THEN] The package number is changed to first package number from same document
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.AreEqual(FirstReservationEntry."Package No.", QltyInspectionHeader."Source Package No.", 'Should be other source package no.');

        QltyInspectionGenRule.Delete();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSummaryModalPageHandler_ChooseFromAnyDocument')]
    procedure Table_AssistEditLotNo_ChooseFromAnyDocument()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        Vendor: Record Vendor;
        FirstPurchaseHeader: Record "Purchase Header";
        SecondPurchaseHeader: Record "Purchase Header";
        FirstPurchaseLine: Record "Purchase Line";
        FirstReservationEntry: Record "Reservation Entry";
        SecondPurchaseLine: Record "Purchase Line";
        SecondReservationEntry: Record "Reservation Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        QltyInspection: TestPage "Qlty. Inspection";
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        // [SCENARIO] AssistEditLotNo allows selecting lot number from any document tracking entries

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A prioritized rule is created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A lot-tracked item is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Two separate purchase orders with different lot numbers are created
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, Item, Vendor, '', FirstPurchaseHeader, FirstPurchaseLine, FirstReservationEntry);
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, Item, Vendor, '', SecondPurchaseHeader, SecondPurchaseLine, SecondReservationEntry);

        // [GIVEN] An inspection is created from the second purchase order
        RecordRef.GetTable(SecondPurchaseLine);
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(SecondReservationEntry);
        if QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, true, '') then
            QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on Lot No. field (handler chooses from any document)
        QltyInspection."Lot No.".AssistEdit();

        // [THEN] The lot number is changed to lot number from different document
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.AreEqual(FirstReservationEntry."Lot No.", QltyInspectionHeader."Source Lot No.", 'Should be other source lot no.');

        QltyInspectionGenRule.Delete();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSummaryModalPageHandler_ChooseFromAnyDocument')]
    procedure Table_AssistEditSerialNo_ChooseFromAnyDocument()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        Vendor: Record Vendor;
        FirstPurchaseHeader: Record "Purchase Header";
        SecondPurchaseHeader: Record "Purchase Header";
        FirstPurchaseLine: Record "Purchase Line";
        FirstReservationEntry: Record "Reservation Entry";
        SecondPurchaseLine: Record "Purchase Line";
        SecondReservationEntry: Record "Reservation Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        QltyInspection: TestPage "Qlty. Inspection";
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        // [SCENARIO] AssistEditSerialNo allows selecting serial number from any document tracking entries

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A prioritized rule is created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A serial-tracked item is created
        QltyInspectionUtility.CreateSerialTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Two separate purchase orders with different serial numbers are created
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, Item, Vendor, '', FirstPurchaseHeader, FirstPurchaseLine, FirstReservationEntry);
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, Item, Vendor, '', SecondPurchaseHeader, SecondPurchaseLine, SecondReservationEntry);

        // [GIVEN] An inspection is created from the second purchase order
        RecordRef.GetTable(SecondPurchaseLine);
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(SecondReservationEntry);
        if QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, true, '') then
            QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on Serial No. field (handler chooses from any document)
        QltyInspection."Serial No.".AssistEdit();

        // [THEN] The serial number is changed to serial number from different document
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.AreEqual(FirstReservationEntry."Serial No.", QltyInspectionHeader."Source Serial No.", 'Should be other source serial no.');

        QltyInspectionGenRule.Delete();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSummaryModalPageHandler_ChooseFromAnyDocument')]
    procedure Table_AssistEditPackageNo_ChooseFromAnyDocument()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        Vendor: Record Vendor;
        FirstPurchaseHeader: Record "Purchase Header";
        SecondPurchaseHeader: Record "Purchase Header";
        FirstPurchaseLine: Record "Purchase Line";
        FirstReservationEntry: Record "Reservation Entry";
        SecondPurchaseLine: Record "Purchase Line";
        SecondReservationEntry: Record "Reservation Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        QltyInspection: TestPage "Qlty. Inspection";
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        // [SCENARIO] AssistEditPackageNo allows selecting package number from any document tracking entries

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template with one field is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A package-tracked item with no series is created
        QltyInspectionUtility.CreatePackageTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Two separate purchase orders with different package numbers are created
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, Item, Vendor, '', FirstPurchaseHeader, FirstPurchaseLine, FirstReservationEntry);
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, Item, Vendor, '', SecondPurchaseHeader, SecondPurchaseLine, SecondReservationEntry);

        // [GIVEN] An inspection is created from the second purchase order
        RecordRef.GetTable(SecondPurchaseLine);
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(SecondReservationEntry);
        if QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, true, '') then
            QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on Source Package No. field (handler chooses from any document)
        QltyInspection."Source Package No.".AssistEdit();

        // [THEN] The package number is changed to first package number from different document
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.AreEqual(FirstReservationEntry."Package No.", QltyInspectionHeader."Source Package No.", 'Should be other source package no.');

        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure Table_VerifyTrackingBeforeFinish_LotTrackedMissingErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Item: Record Item;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        // [SCENARIO] VerifyTrackingBeforeFinish throws error when lot-tracked item has no lot number

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A lot-tracked item is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] An inspection header is initialized with the item but no lot number
        QltyInspectionHeader.Init();
        QltyInspectionHeader."Source Item No." := Item."No.";

        // [GIVEN] Quality setup requires non-empty tracking value before finishing
        QltyManagementSetup.Get();
        QltyManagementSetup."Item Tracking Before Finishing" := QltyManagementSetup."Item Tracking Before Finishing"::"Allow any non-empty value";
        QltyManagementSetup.Modify();

        // [WHEN] VerifyTrackingBeforeFinish is called
        // [THEN] Error is thrown indicating lot number is required
        asserterror QltyInspectionHeader.VerifyTrackingBeforeFinish();
        LibraryAssert.ExpectedError(StrSubstNo(ItemIsTrackingErr, QltyInspectionHeader."Source Item No.", LotTok));
    end;

    [Test]
    procedure Table_VerifyTrackingBeforeFinish_SerialTrackedMissingErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        // [SCENARIO] Verify error when serial-tracked item has no serial number before finish

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A serial-tracked item is created
        QltyInspectionUtility.CreateSerialTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] An inspection header is initialized without serial number
        QltyInspectionHeader.Init();
        QltyInspectionHeader."Source Item No." := Item."No.";

        // [GIVEN] Quality setup requires non-empty tracking before finishing
        QltyManagementSetup.Get();
        QltyManagementSetup."Item Tracking Before Finishing" := QltyManagementSetup."Item Tracking Before Finishing"::"Allow any non-empty value";
        QltyManagementSetup.Modify();

        // [WHEN] VerifyTrackingBeforeFinish is called
        asserterror QltyInspectionHeader.VerifyTrackingBeforeFinish();

        // [THEN] Error is thrown indicating missing serial number
        LibraryAssert.ExpectedError(StrSubstNo(ItemIsTrackingErr, QltyInspectionHeader."Source Item No.", SerialTok));
    end;

    [Test]
    procedure Table_VerifyTrackingBeforeFinish_PackageTrackedMissingErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        // [SCENARIO] Verify error when package-tracked item has no package number before finish

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A package-tracked item with no series is created
        QltyInspectionUtility.CreatePackageTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [GIVEN] An inspection header is initialized without package number
        QltyInspectionHeader.Init();
        QltyInspectionHeader."Source Item No." := Item."No.";

        // [GIVEN] Quality setup requires non-empty tracking before finishing
        QltyManagementSetup.Get();
        QltyManagementSetup."Item Tracking Before Finishing" := QltyManagementSetup."Item Tracking Before Finishing"::"Allow any non-empty value";
        QltyManagementSetup.Modify();

        // [WHEN] VerifyTrackingBeforeFinish is called
        asserterror QltyInspectionHeader.VerifyTrackingBeforeFinish();

        // [THEN] Error is thrown indicating missing package number
        LibraryAssert.ExpectedError(StrSubstNo(ItemIsTrackingErr, QltyInspectionHeader."Source Item No.", PackageTok));
    end;

    [Test]
    procedure Table_VerifyTrackingBeforeFinish_LotNotPostedErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        // [SCENARIO] Verify error when lot-tracked item has unposted lot number before finish

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template and generation rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A lot-tracked item with no series is created
        QltyInspectionUtility.CreateLotTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order with lot tracking is created
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, Item, Vendor, '', PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] An inspection is created from the purchase line with tracking
        RecordRef.GetTable(PurchaseLine);
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
        if QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, true, '') then
            QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] Quality setup requires only posted item tracking
        QltyManagementSetup.Get();
        QltyManagementSetup."Item Tracking Before Finishing" := QltyManagementSetup."Item Tracking Before Finishing"::"Allow only posted Item Tracking";
        QltyManagementSetup.Modify();

        // [WHEN] VerifyTrackingBeforeFinish is called
        asserterror QltyInspectionHeader.VerifyTrackingBeforeFinish();

        // [THEN] Error is thrown indicating insufficient posted lot quantity
        LibraryAssert.ExpectedError(StrSubstNo(ItemInsufficientPostedErr, QltyInspectionHeader."Source Item No.", LotTok, ReservationEntry."Lot No.", 0));
    end;

    [Test]
    procedure Table_VerifyTrackingBeforeFinish_SerialNotPostedErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        // [SCENARIO] Verify error when serial-tracked item has unposted serial number before finish

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template and generation rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A serial-tracked item is created
        QltyInspectionUtility.CreateSerialTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order with serial tracking is created
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, Item, Vendor, '', PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] An inspection is created from the purchase line with tracking
        RecordRef.GetTable(PurchaseLine);
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
        if QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, true, '') then
            QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] Quality setup requires only posted item tracking
        QltyManagementSetup.Get();
        QltyManagementSetup."Item Tracking Before Finishing" := QltyManagementSetup."Item Tracking Before Finishing"::"Allow only posted Item Tracking";
        QltyManagementSetup.Modify();

        // [WHEN] VerifyTrackingBeforeFinish is called
        asserterror QltyInspectionHeader.VerifyTrackingBeforeFinish();

        // [THEN] Error is thrown indicating insufficient posted serial quantity
        LibraryAssert.ExpectedError(StrSubstNo(ItemInsufficientPostedErr, QltyInspectionHeader."Source Item No.", SerialTok, ReservationEntry."Serial No.", 0));
    end;

    [Test]
    procedure Table_VerifyTrackingBeforeFinish_PackageNotPostedErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        // [SCENARIO] Verify error when package-tracked item has unposted package number before finish

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template and generation rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A package-tracked item with no series is created
        QltyInspectionUtility.CreatePackageTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] A purchase order with package tracking is created
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, Item, Vendor, '', PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] An inspection is created from the purchase line with tracking
        RecordRef.GetTable(PurchaseLine);
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
        if QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, true, '') then
            QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);

        // [GIVEN] Quality setup requires only posted item tracking
        QltyManagementSetup.Get();
        QltyManagementSetup."Item Tracking Before Finishing" := QltyManagementSetup."Item Tracking Before Finishing"::"Allow only posted Item Tracking";
        QltyManagementSetup.Modify();

        // [WHEN] VerifyTrackingBeforeFinish is called
        asserterror QltyInspectionHeader.VerifyTrackingBeforeFinish();

        // [THEN] Error is thrown indicating insufficient posted package quantity
        LibraryAssert.ExpectedError(StrSubstNo(ItemInsufficientPostedErr, QltyInspectionHeader."Source Item No.", PackageTok, ReservationEntry."Package No.", 0));
    end;

    [Test]
    procedure Table_VerifyTrackingBeforeFinish_LotNotReservedErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        // [SCENARIO] Verify error when lot number is not reserved or posted before finish

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A lot-tracked item with no series is created
        QltyInspectionUtility.CreateLotTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] Quality setup requires reserved or posted item tracking
        QltyManagementSetup.Get();
        QltyManagementSetup."Item Tracking Before Finishing" := QltyManagementSetup."Item Tracking Before Finishing"::"Allow reserved or posted Item Tracking";
        QltyManagementSetup.Modify();

        // [GIVEN] An inspection header with lot number is initialized without reservation
        QltyInspectionHeader."Source Item No." := Item."No.";
        QltyInspectionHeader."Source Lot No." := LotTok;

        // [WHEN] VerifyTrackingBeforeFinish is called
        asserterror QltyInspectionHeader.VerifyTrackingBeforeFinish();

        // [THEN] Error is thrown indicating insufficient reserved or posted lot quantity
        LibraryAssert.ExpectedError(StrSubstNo(ItemInsufficientPostedOrUnpostedErr, QltyInspectionHeader."Source Item No.", LotTok, QltyInspectionHeader."Source Lot No.", 0));
    end;

    [Test]
    procedure Table_VerifyTrackingBeforeFinish_SerialNotReservedErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        // [SCENARIO] Verify error when serial number is not reserved or posted before finish

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A serial-tracked item is created
        QltyInspectionUtility.CreateSerialTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] Quality setup requires reserved or posted item tracking
        QltyManagementSetup.Get();
        QltyManagementSetup."Item Tracking Before Finishing" := QltyManagementSetup."Item Tracking Before Finishing"::"Allow reserved or posted Item Tracking";
        QltyManagementSetup.Modify();

        // [GIVEN] An inspection header with serial number is initialized without reservation
        QltyInspectionHeader."Source Item No." := Item."No.";
        QltyInspectionHeader."Source Serial No." := SerialTok;

        // [WHEN] VerifyTrackingBeforeFinish is called
        asserterror QltyInspectionHeader.VerifyTrackingBeforeFinish();

        // [THEN] Error is thrown indicating insufficient reserved or posted serial quantity
        LibraryAssert.ExpectedError(StrSubstNo(ItemInsufficientPostedOrUnpostedErr, QltyInspectionHeader."Source Item No.", SerialTok, QltyInspectionHeader."Source Serial No.", 0));
    end;

    [Test]
    procedure Table_VerifyTrackingBeforeFinish_PackageNotReservedErr()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        // [SCENARIO] Verify error when package number is not reserved or posted before finish

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A package-tracked item with no series is created
        QltyInspectionUtility.CreatePackageTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [GIVEN] Quality setup requires reserved or posted item tracking
        QltyManagementSetup.Get();
        QltyManagementSetup."Item Tracking Before Finishing" := QltyManagementSetup."Item Tracking Before Finishing"::"Allow reserved or posted Item Tracking";
        QltyManagementSetup.Modify();

        // [GIVEN] An inspection header with package number is initialized without reservation
        QltyInspectionHeader."Source Item No." := Item."No.";
        QltyInspectionHeader."Source Package No." := PackageTok;

        // [WHEN] VerifyTrackingBeforeFinish is called
        asserterror QltyInspectionHeader.VerifyTrackingBeforeFinish();

        // [THEN] Error is thrown indicating insufficient reserved or posted package quantity
        LibraryAssert.ExpectedError(StrSubstNo(ItemInsufficientPostedOrUnpostedErr, QltyInspectionHeader."Source Item No.", PackageTok, QltyInspectionHeader."Source Package No.", 0));
    end;

    [Test]
    procedure Table_TestAssignSelfOnModify()
    var
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] Test is automatically assigned to current user on modification

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A generation rule is created for purchase lines
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase with no assigned user
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [GIVEN] Test has no assigned user initially
        LibraryAssert.AreEqual('', QltyInspectionHeader."Assigned User ID", 'Should not have assigned user.');

        // [WHEN] Test is modified by changing source quantity
        QltyInspectionHeader."Source Quantity (Base)" := 99;
        QltyInspectionHeader.Modify(true);

        // [THEN] Test is automatically assigned to current user
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.AreEqual(UserId(), QltyInspectionHeader."Assigned User ID", 'Should be assigned to current user.');
    end;

    [Test]
    procedure Table_GetReferenceRecordId_TriggeringRecord()
    var
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] GetReferenceRecordId returns the triggering record's SystemId

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A generation rule is created for purchase lines
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from a purchase line
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [WHEN] GetReferenceRecordId is called
        // [THEN] The purchase line's SystemId is returned
        LibraryAssert.AreEqual(PurchaseLine.SystemId, QltyInspectionHeader.GetReferenceRecordId(), 'Should be the same record id.');
    end;

    [Test]
    procedure Table_GetReferenceRecordId_SourceRecordId()
    var
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] GetReferenceRecordId returns Source RecordId's SystemId when set

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A generation rule is created for purchase lines
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location and item are created
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);

        // [GIVEN] An inspection header is initialized with Source RecordId set to purchase line
        QltyInspectionHeader.Init();
        QltyInspectionHeader."Source RecordId" := PurchaseLine.RecordId();

        // [WHEN] GetReferenceRecordId is called
        // [THEN] The purchase line's SystemId is returned
        LibraryAssert.AreEqual(PurchaseLine.SystemId, QltyInspectionHeader.GetReferenceRecordId(), 'Should be the same record id.');
    end;

    [Test]
    procedure Table_GetReferenceRecordId_SourceRecordId2()
    var
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] GetReferenceRecordId returns Source RecordId 2's SystemId when set

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A generation rule is created for purchase lines
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location and item are created
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);

        // [GIVEN] An inspection header is initialized with Source RecordId 2 set to purchase line
        QltyInspectionHeader.Init();
        QltyInspectionHeader."Source RecordId 2" := PurchaseLine.RecordId();

        // [WHEN] GetReferenceRecordId is called
        // [THEN] The purchase line's SystemId is returned
        LibraryAssert.AreEqual(PurchaseLine.SystemId, QltyInspectionHeader.GetReferenceRecordId(), 'Should be the same record id.');
    end;

    [Test]
    procedure Table_GetReferenceRecordId_SourceRecordId3()
    var
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] GetReferenceRecordId returns Source RecordId 3's SystemId when set

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A generation rule is created for purchase lines
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location and item are created
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);

        // [GIVEN] An inspection header is initialized with Source RecordId 3 set to purchase line
        QltyInspectionHeader.Init();
        QltyInspectionHeader."Source RecordId 3" := PurchaseLine.RecordId();

        // [WHEN] GetReferenceRecordId is called
        // [THEN] The purchase line's SystemId is returned
        LibraryAssert.AreEqual(PurchaseLine.SystemId, QltyInspectionHeader.GetReferenceRecordId(), 'Should be the same record id.');
    end;

    [Test]
    procedure Table_GetReferenceRecordId_SourceRecordId4()
    var
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] GetReferenceRecordId returns Source RecordId 4's SystemId when set

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A generation rule is created for purchase lines
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location and item are created
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);

        // [GIVEN] An inspection header is initialized with Source RecordId 4 set to purchase line
        QltyInspectionHeader.Init();
        QltyInspectionHeader."Source RecordId 4" := PurchaseLine.RecordId();

        // [WHEN] GetReferenceRecordId is called
        // [THEN] The purchase line's SystemId is returned
        LibraryAssert.AreEqual(PurchaseLine.SystemId, QltyInspectionHeader.GetReferenceRecordId(), 'Should be the same record id.');
    end;

    [Test]
    [HandlerFunctions('CameraModalPageHandler')]
    procedure Table_TakeNewPicture_MockCamera()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        DocumentAttachment: Record "Document Attachment";
        CameraTestLibrary: Codeunit "Camera Test Library";
        QltyInspection: TestPage "Qlty. Inspection";
        BeforeCount: Integer;
    begin
        // [SCENARIO] Taking a picture with mock camera creates document attachment

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] Picture upload behavior is set to attach document
        QltyManagementSetup.Get();
        QltyManagementSetup."Picture Upload Behavior" := QltyManagementSetup."Picture Upload Behavior"::"Attach document";
        QltyManagementSetup.Modify();

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [GIVEN] Current document attachment count is recorded
        BeforeCount := DocumentAttachment.Count();

        // [GIVEN] Camera test library is subscribed
        BindSubscription(CameraTestLibrary);

        // [GIVEN] Test page is opened and positioned on the test
        QltyInspection.OpenView();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] TakePicture action is invoked
        QltyInspection.TakePicture.Invoke();

        // [GIVEN] Camera test library is unsubscribed
        UnbindSubscription(CameraTestLibrary);

        // [THEN] Inspection header now has a most recent picture
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.IsTrue(QltyInspectionHeader."Most Recent Picture".HasValue(), 'Should have added picture.');

        // [THEN] A new document attachment is created
        LibraryAssert.AreEqual(BeforeCount + 1, DocumentAttachment.Count(), 'Should have added document attachment.');

        // [THEN] Document attachment file name contains test number
        DocumentAttachment.SetRange("Table ID", Database::"Qlty. Inspection Header");
        DocumentAttachment.FindLast();
        LibraryAssert.IsTrue(DocumentAttachment."File Name".Contains(QltyInspectionHeader."No."), 'File name should have test no.');
    end;

    [Test]
    procedure Table_SetRecordFiltersToFindTestFor_ItemFilter()
    var
        Location: Record Location;
        Item: Record Item;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        RecordRef: RecordRef;
        Filter: Text;
    begin
        // [SCENARIO] SetRecordFiltersToFindTestFor applies item number filter

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template and generation rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location and item are created
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created with the item
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine);

        // [WHEN] SetRecordFiltersToFindTestFor is called with purchase line (useItem=true)
        QltyInspectionHeader.SetRecordFiltersToFindTestFor(true, PurchaseLine, true, false, false);

        // [THEN] Filter includes the item number
        RecordRef.GetTable(QltyInspectionHeader);
        Filter := RecordRef.GetFilters();
        LibraryAssert.IsTrue(Filter.Contains(Item."No."), 'Should have filter for item no.');
    end;

    [Test]
    procedure Table_SetRecordFiltersToFindTestFor_LotTrackingFilter()
    var
        Location: Record Location;
        Item: Record Item;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        Filter: Text;
    begin
        // [SCENARIO] SetRecordFiltersToFindTestFor applies lot number filter

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template and generation rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A lot-tracked item with no series is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order with lot tracking is created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] Tracking specification is created from reservation entry
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);

        // [WHEN] SetRecordFiltersToFindTestFor is called with tracking (useItemTracking=true)
        QltyInspectionHeader.SetRecordFiltersToFindTestFor(true, TempSpecTrackingSpecification, false, true, false);

        // [THEN] Filter includes the lot number
        RecordRef.GetTable(QltyInspectionHeader);
        Filter := RecordRef.GetFilters();
        LibraryAssert.IsTrue(Filter.Contains(ReservationEntry."Lot No."), 'Should have filter for lot no.');
    end;

    [Test]
    procedure Table_SetRecordFiltersToFindTestFor_SourceDocumentFilter()
    var
        Location: Record Location;
        Item: Record Item;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        Filter: Text;
    begin
        // [SCENARIO] SetRecordFiltersToFindTestFor applies source document number filter

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template and generation rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A lot-tracked item with no series is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order is created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);

        // [WHEN] SetRecordFiltersToFindTestFor is called with purchase line (useSourceDocument=true)
        QltyInspectionHeader.SetRecordFiltersToFindTestFor(true, PurchaseLine, false, false, true);

        // [THEN] Filter includes the source document number
        RecordRef.GetTable(QltyInspectionHeader);
        Filter := RecordRef.GetFilters();
        LibraryAssert.IsTrue(Filter.Contains(PurchaseHeader."No."), 'Should have filter for source document no.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure sPage_FinishTest()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        QltyInspectionList: TestPage "Qlty. Inspection List";
    begin
        // [SCENARIO] Finish action on inspection page changes inspection status to Finished

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template and generation rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase with Open status
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 10, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [GIVEN] Test list page is opened and positioned on the inspection
        QltyInspectionList.OpenView();
        QltyInspectionList.GoToRecord(QltyInspectionHeader);

        // [WHEN] ChangeStatusFinish action is invoked (ConfirmHandler confirms)
        QltyInspectionList.ChangeStatusFinish.Invoke();

        // [THEN] Test status is changed to Finished
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.IsTrue(QltyInspectionHeader.Status = QltyInspectionHeader.Status::Finished, 'Test should be finished.');

        // [GIVEN] Cleanup generation rule
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure sPage_ReopenTest()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        QltyInspectionList: TestPage "Qlty. Inspection List";
    begin
        // [SCENARIO] Reopen action on inspection page changes inspection status from Finished to Open

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template and generation rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 10, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [GIVEN] Test status is set to Finished
        QltyInspectionHeader.Status := QltyInspectionHeader.Status::Finished;
        QltyInspectionHeader.Modify();

        // [GIVEN] Inspection list page is opened and positioned on the inspection
        QltyInspectionList.OpenView();
        QltyInspectionList.GoToRecord(QltyInspectionHeader);

        // [WHEN] ChangeStatusReopen action is invoked (ConfirmHandler confirms)
        QltyInspectionList.ChangeStatusReopen.Invoke();

        // [THEN] Test status is changed to Open
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.IsTrue(QltyInspectionHeader.Status = QltyInspectionHeader.Status::Open, 'Test should be open.');

        // [GIVEN] Cleanup generation rule
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure sPage_PickupTest()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        QltyInspectionList: TestPage "Qlty. Inspection List";
    begin
        // [SCENARIO] AssignToSelf action on inspection page assigns inspection to current user

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template and generation rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase with no assigned user
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 10, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [GIVEN] Test list page is opened and positioned on the inspection
        QltyInspectionList.OpenView();
        QltyInspectionList.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssignToSelf action is invoked
        QltyInspectionList.AssignToSelf.Invoke();

        // [THEN] Test is assigned to current user
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.IsTrue(QltyInspectionHeader."Assigned User ID" = UserId(), 'Test should be assigned to user.');

        // [GIVEN] Cleanup generation rule
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure sPage_UnassignTest()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        QltyInspectionList: TestPage "Qlty. Inspection List";
    begin
        // [SCENARIO] Unassign action on inspection page clears assigned user

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template and generation rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 10, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [GIVEN] Test is assigned to current user
        QltyInspectionHeader."Assigned User ID" := CopyStr(UserId(), 1, MaxStrLen(QltyInspectionHeader."Assigned User ID"));
        QltyInspectionHeader.Modify();

        // [GIVEN] Inspection list page is opened and positioned on the inspection
        QltyInspectionList.OpenView();
        QltyInspectionList.GoToRecord(QltyInspectionHeader);

        // [WHEN] Unassign action is invoked
        QltyInspectionList.Unassign.Invoke();

        // [THEN] Test assigned user is cleared
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.IsTrue(QltyInspectionHeader."Assigned User ID" = '', 'Test should not be assigned to a user.');

        // [GIVEN] Cleanup generation rule
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure LineTable_SetAndGetMeasurementNote()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        RecordLink: Record "Record Link";
    begin
        // [SCENARIO] SetMeasurementNote creates and updates record link note for inspection line

        Initialize();

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [GIVEN] First inspection line is retrieved
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Reinspection No.", QltyInspectionHeader."Reinspection No.");
        QltyInspectionLine.FindFirst();

        // [WHEN] Measurement note is set
        QltyInspectionLine.SetMeasurementNote(MeasurementNoteTxt);

        // [THEN] A record link note is created
        RecordLink.Reset();
        RecordLink.SetRange(Type, RecordLink.Type::Note);
        RecordLink.SetRange("Record ID", QltyInspectionLine.RecordId());
        LibraryAssert.IsTrue(RecordLink.Count() = 1, 'There should be a link added.');

        // [THEN] GetMeasurementNote returns the correct message
        LibraryAssert.AreEqual(MeasurementNoteTxt, QltyInspectionLine.GetMeasurementNote(), 'Should be the correct message.');

        // [WHEN] Measurement note is updated
        QltyInspectionLine.SetMeasurementNote(UpdatedMeasurementNoteTxt);

        // [THEN] GetMeasurementNote returns the updated message
        LibraryAssert.AreEqual(UpdatedMeasurementNoteTxt, QltyInspectionLine.GetMeasurementNote(), 'Should be the correct message.');
    end;

    [Test]
    [HandlerFunctions('StrMenuPageHandler')]
    procedure FieldTable_AssistEditDefaultValue_Option()
    var
        ToLoadQltyField: Record "Qlty. Field";
    begin
        // [SCENARIO] AssistEditDefaultValue for Option field type opens option menu

        Initialize();

        // [GIVEN] A field record is initialized
        ToLoadQltyField.Init();

        // [GIVEN] Field type is set to Option
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Option");

        // [GIVEN] Allowable values are set
        ToLoadQltyField.Validate("Allowable Values", OptionsTok);

        // [WHEN] AssistEditDefaultValue is called (StrMenuPageHandler selects first option)
        ToLoadQltyField.AssistEditDefaultValue();

        // [THEN] Default value is set to selected option
        LibraryAssert.AreEqual(Option1Tok, ToLoadQltyField."Default Value", 'Should be selected option.');
    end;

    [Test]
    [HandlerFunctions('StrMenuPageHandler')]
    procedure FieldTable_AssistEditDefaultValue_Boolean()
    var
        ToLoadQltyField: Record "Qlty. Field";
    begin
        // [SCENARIO] AssistEditDefaultValue for Boolean field type opens Yes/No menu

        Initialize();

        // [GIVEN] A field record is initialized
        ToLoadQltyField.Init();

        // [GIVEN] Field type is set to Boolean
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Boolean");

        // [WHEN] AssistEditDefaultValue is called (StrMenuPageHandler selects first option: No)
        ToLoadQltyField.AssistEditDefaultValue();

        // [THEN] Default value is set to No
        LibraryAssert.AreEqual(NoTok, ToLoadQltyField."Default Value", 'Should be no.')
    end;

    [Test]
    [HandlerFunctions('EditLargeTextModalPageHandler')]
    procedure FieldTable_AssistEditDefaultValue_Text()
    var
        ToLoadQltyField: Record "Qlty. Field";
    begin
        // [SCENARIO] AssistEditDefaultValue for Text field type opens text editor modal

        Initialize();

        // [GIVEN] A field record is initialized
        ToLoadQltyField.Init();

        // [GIVEN] Field type is set to Text
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Text");

        // [WHEN] AssistEditDefaultValue is called (EditLargeTextModalPageHandler enters TestValueTxt)
        ToLoadQltyField.AssistEditDefaultValue();

        // [THEN] Default value is set to entered text
        LibraryAssert.AreEqual(TestValueTxt, ToLoadQltyField."Default Value", 'Should be same text.')
    end;

    [Test]
    procedure FieldTable_OnDelete_ShouldError()
    var
        ToLoadQltyField: Record "Qlty. Field";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        // [SCENARIO] Deleting field used in template lines should error

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template with 2 fields is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 2);

        // [GIVEN] First template line is retrieved
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.FindFirst();

        // [GIVEN] Field from template line is retrieved
        ToLoadQltyField.Get(ConfigurationToLoadQltyInspectionTemplateLine."Field Code");

        // [GIVEN] Sanity checks: field exists and template has two lines
        LibraryAssert.IsTrue(ToLoadQltyField.Get(ConfigurationToLoadQltyInspectionTemplateLine."Field Code"), 'Sanity check, the field should exist before deleting.');
        LibraryAssert.AreEqual(2, ConfigurationToLoadQltyInspectionTemplateLine.Count(), 'Sanity check, should be starting with two lines.');

        // [GIVEN] Changes are committed
        Commit();

        // [WHEN] Delete is attempted on field
        asserterror ToLoadQltyField.Delete(true);

        // [THEN] Field still exists after failed delete attempt
        LibraryAssert.IsTrue(ToLoadQltyField.Get(ConfigurationToLoadQltyInspectionTemplateLine."Field Code"), 'The field should still exist after a delete attempt, which should have failed.');

        // [THEN] Template lines are retained
        ConfigurationToLoadQltyInspectionTemplateLine.Reset();
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(2, ConfigurationToLoadQltyInspectionTemplateLine.Count(), 'Should have retained the template line.');

        // [THEN] Field record is retained
        ToLoadQltyField.SetRecFilter();
        LibraryAssert.AreEqual(1, ToLoadQltyField.Count(), 'Should have retained the field.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure FieldTable_EnsureCanBeDeleted_ShouldConfirmAndDelete()
    var
        ToLoadQltyField: Record "Qlty. Field";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        // [SCENARIO] EnsureCanBeDeleted with confirm removes template lines but not the field

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template with 2 fields is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 2);

        // [GIVEN] First template line is retrieved
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.FindFirst();

        // [GIVEN] Field from template line is retrieved
        ToLoadQltyField.Get(ConfigurationToLoadQltyInspectionTemplateLine."Field Code");

        // [WHEN] EnsureCanBeDeleted is called with confirm=true (ConfirmHandler confirms)
        ToLoadQltyField.EnsureCanBeDeleted(true);

        // [GIVEN] Field record filter is set
        ToLoadQltyField.SetRecFilter();

        // [THEN] Template line is deleted
        Clear(ConfigurationToLoadQltyInspectionTemplateLine);
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, ConfigurationToLoadQltyInspectionTemplateLine.Count(), 'Should have deleted template line.');

        // [THEN] Field still exists (EnsureCanBeDeleted only removes dependencies)
        LibraryAssert.AreEqual(1, ToLoadQltyField.Count(), 'Should have not deleted the field with just EnsureCanBeDeleted(true).');
    end;

    [Test]
    procedure FieldTable_OnDelete_HasExistingInspections_ShouldError()
    var
        ToLoadQltyField: Record "Qlty. Field";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
    begin
        // [SCENARIO] Deleting field with existing inspection lines should error with specific message

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template with 1 field is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] Template line is retrieved
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.FindFirst();

        // [GIVEN] An inspection header is created from the template
        QltyInspectionHeader.Init();
        QltyInspectionHeader.Validate("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        QltyInspectionHeader.Insert(true);

        // [GIVEN] Field from template line is retrieved
        ToLoadQltyField.Get(ConfigurationToLoadQltyInspectionTemplateLine."Field Code");

        // [GIVEN] An inspection line using the field is created
        QltyInspectionLine.Init();
        QltyInspectionLine.Validate("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.Validate("Reinspection No.", QltyInspectionHeader."Reinspection No.");
        QltyInspectionLine."Line No." := ConfigurationToLoadQltyInspectionTemplateLine."Line No.";
        QltyInspectionLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateLine."Template Code";
        QltyInspectionLine."Template Line No." := ConfigurationToLoadQltyInspectionTemplateLine."Line No.";
        QltyInspectionLine.Validate("Field Code", ToLoadQltyField.Code);
        QltyInspectionLine.Insert();

        // [WHEN] Delete is attempted on field
        asserterror ToLoadQltyField.Delete(true);

        // [THEN] Specific error message is shown with test details
        LibraryAssert.ExpectedError(StrSubstNo(
            ExistingTestErr,
            QltyInspectionLine."Field Code",
            1,
            QltyInspectionHeader."No.",
            QltyInspectionHeader."Template Code"));
    end;

    [Test]
    procedure FieldTable_SuggestFieldCodeFromDescription()
    var
        ToLoadQltyField: Record "Qlty. Field";
        FieldCode: Code[20];
    begin
        // [SCENARIO] SuggestUnusedFieldCodeFromDescription generates code from description

        Initialize();

        // [GIVEN] Existing fields with description are deleted
        ToLoadQltyField.SetRange(Description, DescriptionTxt);
        if not ToLoadQltyField.IsEmpty() then
            ToLoadQltyField.DeleteAll();

        // [WHEN] SuggestUnusedFieldCodeFromDescription is called with description
        ToLoadQltyField.SuggestUnusedFieldCodeFromDescription(DescriptionTxt, FieldCode);

        // [THEN] Suggested code matches expected value
        LibraryAssert.AreEqual(SuggestedCodeTxtTestValueTxt, FieldCode, 'Suggested code should match');
    end;

    [Test]
    procedure FieldTable_SuggestFieldCodeFromDescription_NoSpecialChar()
    var
        ToLoadQltyField: Record "Qlty. Field";
        FieldCode: Code[20];
    begin
        // [SCENARIO] SuggestUnusedFieldCodeFromDescription handles description with no special characters

        Initialize();

        // [GIVEN] Existing fields with description are deleted
        ToLoadQltyField.SetRange(Description, DescriptionTxt);
        if not ToLoadQltyField.IsEmpty() then
            ToLoadQltyField.DeleteAll();

        // [WHEN] SuggestUnusedFieldCodeFromDescription is called with description
        ToLoadQltyField.SuggestUnusedFieldCodeFromDescription(DescriptionTxt, FieldCode);

        // [THEN] Suggested code matches expected value
        LibraryAssert.AreEqual(SuggestedCodeTxtTestValueTxt, FieldCode, 'Suggested code should match');
    end;

    [Test]
    procedure FieldTable_SuggestFieldCodeFromDescription_LongWithSpecialChar()
    var
        ToLoadQltyField: Record "Qlty. Field";
        FieldCode: Code[20];
    begin
        // [SCENARIO] SuggestUnusedFieldCodeFromDescription handles long description with special characters

        Initialize();

        // [GIVEN] Existing fields with description are deleted
        ToLoadQltyField.SetRange(Description, Description2Txt);
        if not ToLoadQltyField.IsEmpty() then
            ToLoadQltyField.DeleteAll();

        // [WHEN] SuggestUnusedFieldCodeFromDescription is called with long description with special characters
        ToLoadQltyField.SuggestUnusedFieldCodeFromDescription(Description2Txt, FieldCode);

        // [THEN] Suggested code matches expected value (truncated and sanitized)
        LibraryAssert.AreEqual(SuggestedCodeTxtTestValue2Txt, FieldCode, 'Suggested code should match');
    end;

    [Test]
    procedure FieldTable_SuggestFieldCodeFromDescription_PreexistingField()
    var
        ToLoadQltyField: Record "Qlty. Field";
        FieldCode: Code[20];
    begin
        // [SCENARIO] SuggestUnusedFieldCodeFromDescription increments code when field already exists

        Initialize();

        // [GIVEN] Existing fields with description are cleaned up to have only one
        ToLoadQltyField.SetRange(Description, DescriptionTxt);
        if ToLoadQltyField.Count() > 1 then
            ToLoadQltyField.DeleteAll();

        // [GIVEN] A field with the suggested code already exists
        if ToLoadQltyField.IsEmpty() then begin
            ToLoadQltyField.Init();
            ToLoadQltyField.Validate(Code, SuggestedCodeTxtTestValueTxt);
            ToLoadQltyField.Validate(Description, DescriptionTxt);
            ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
            ToLoadQltyField.Insert();

            // [WHEN] SuggestUnusedFieldCodeFromDescription is called
            ToLoadQltyField.SuggestUnusedFieldCodeFromDescription(DescriptionTxt, FieldCode);

            // [THEN] Suggested code is incremented with suffix
            LibraryAssert.AreEqual(SuggestedCodeTxtTestValueTxt + '0002', FieldCode, 'Suggested code should match');
        end;
    end;

    [Test]
    [HandlerFunctions('AssistEditTemplatePageHandler')]
    procedure FieldTable_AssistEditAllowableValues()
    var
        ToLoadQltyField: Record "Qlty. Field";
        FieldCodeTxt: Text;
    begin
        // [SCENARIO] AssistEditAllowableValues opens modal to edit allowable values

        Initialize();

        // [GIVEN] A random field code is generated
        QltyInspectionUtility.GenerateRandomCharacters(20, FieldCodeTxt);

        // [GIVEN] A field is created
        ToLoadQltyField.Init();
        ToLoadQltyField.Validate(Code, CopyStr(FieldCodeTxt, 1, MaxStrLen(ToLoadQltyField.Code)));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();

        // [GIVEN] Handler will enter allowable values expression
        AssistEditTemplateValue := AllowableValuesExpressionTok;

        // [WHEN] AssistEditAllowableValues is called (handler enters value)
        ToLoadQltyField.AssistEditAllowableValues();

        // [THEN] Allowable values are updated
        LibraryAssert.AreEqual(AllowableValuesExpressionTok, ToLoadQltyField."Allowable Values", 'Allowable values should match');
    end;

    [Test]
    [HandlerFunctions('AssistEditTemplatePageHandler')]
    procedure FieldCardPage_UpdatePassConditionAndDescription()
    var
        ToLoadQltyField: Record "Qlty. Field";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        QltyFieldCard: TestPage "Qlty. Field Card";
        FieldCodeTxt: Text;
    begin
        // [SCENARIO] Field card page updates pass condition and description via AssistEdit

        Initialize();

        // [GIVEN] Existing grades are deleted
        if not ToLoadQltyInspectionGrade.IsEmpty() then
            ToLoadQltyInspectionGrade.DeleteAll();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A random field code is generated
        QltyInspectionUtility.GenerateRandomCharacters(20, FieldCodeTxt);

        // [GIVEN] A field is created
        ToLoadQltyField.Init();
        ToLoadQltyField.Validate(Code, CopyStr(FieldCodeTxt, 1, MaxStrLen(ToLoadQltyField.Code)));
        ToLoadQltyField.Validate("Field Type", ToLoadQltyField."Field Type"::"Field Type Decimal");
        ToLoadQltyField.Insert();

        // [GIVEN] Field card page is opened for the field
        QltyFieldCard.OpenEdit();
        QltyFieldCard.GoToRecord(ToLoadQltyField);

        // [GIVEN] Handler will enter pass condition expression
        AssistEditTemplateValue := PassConditionExpressionTok;

        // [WHEN] Pass condition AssistEdit is invoked
        QltyFieldCard.Field1.AssistEdit();

        // [GIVEN] Handler will enter pass condition description
        AssistEditTemplateValue := PassConditionDescExpressionTok;

        // [WHEN] Pass condition description AssistEdit is invoked
        QltyFieldCard.Field1_Desc.AssistEdit();

        // [GIVEN] Default pass grade is retrieved
        ToLoadQltyInspectionGrade.Get(QltyAutoConfigure.GetDefaultPassGrade());

        // [GIVEN] Grade condition configuration for field is retrieved
        ToLoadQltyIGradeConditionConf.SetRange("Field Code", ToLoadQltyField.Code);
        ToLoadQltyIGradeConditionConf.SetRange("Target Code", ToLoadQltyField.Code);
        ToLoadQltyIGradeConditionConf.SetRange("Grade Code", ToLoadQltyInspectionGrade.Code);
        ToLoadQltyIGradeConditionConf.SetRange("Condition Type", ToLoadQltyIGradeConditionConf."Condition Type"::Field);
        ToLoadQltyIGradeConditionConf.FindFirst();

        // [THEN] Condition is updated
        LibraryAssert.AreEqual(PassConditionExpressionTok, ToLoadQltyIGradeConditionConf.Condition, 'Should be same condition.');

        // [THEN] Condition description is updated
        LibraryAssert.AreEqual(PassConditionDescExpressionTok, ToLoadQltyIGradeConditionConf."Condition Description", 'Should be same description.')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure SetupTable_ValidateProductionTrigger()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] ValidateProductionTrigger updates existing production rules when setup trigger changes

        Initialize();

        // [GIVEN] All existing generation rules are deleted
        if not QltyInspectionGenRule.IsEmpty() then
            QltyInspectionGenRule.DeleteAll();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] Three production-related rules are created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Line");
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Production Order");

        // [GIVEN] Production rules with OnProductionOrderRelease trigger are filtered
        QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::Production);
        QltyInspectionGenRule.SetRange("Production Trigger", QltyInspectionGenRule."Production Trigger"::OnProductionOrderRelease);
        LibraryAssert.IsTrue(QltyInspectionGenRule.IsEmpty(), 'Should be no rules with trigger.');

        // [GIVEN] Setup is updated to OnProductionOrderRelease trigger
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Trigger", QltyManagementSetup."Production Trigger"::OnProductionOrderRelease);
        QltyManagementSetup.Modify();

        // [GIVEN] Rules with OnProductionOrderRelease trigger are verified as still empty
        QltyInspectionGenRule.SetRange("Production Trigger", QltyInspectionGenRule."Production Trigger"::OnProductionOrderRelease);
        LibraryAssert.IsTrue(QltyInspectionGenRule.IsEmpty(), 'Should be no rules with trigger.');

        // [GIVEN] A new production rule is created
        Clear(QltyInspectionGenRule);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);

        // [GIVEN] Source table is changed to Prod. Order Line
        QltyInspectionGenRule.Validate("Source Table No.", Database::"Prod. Order Line");
        QltyInspectionGenRule.Modify();
        LibraryAssert.IsTrue(QltyInspectionGenRule."Production Trigger" = QltyInspectionGenRule."Production Trigger"::OnProductionOrderRelease, 'Should have default trigger.');

        // [WHEN] Setup production trigger is changed to OnProductionOutputPost
        QltyManagementSetup.Validate("Production Trigger", QltyManagementSetup."Production Trigger"::OnProductionOutputPost);
        QltyManagementSetup.Modify();

        // [THEN] Existing production rule is updated to new trigger
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.SetRange("Production Trigger", QltyInspectionGenRule."Production Trigger"::OnProductionOutputPost);
        LibraryAssert.AreEqual(1, QltyInspectionGenRule.Count(), 'Production rule should have new production trigger.');
    end;

    [Test]
    procedure SetupTable_ValidateWarehouseTrigger_CreateSourceConfig()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
    begin
        // [SCENARIO] ValidateWarehouseTrigger creates source configurations for warehouse tables when trigger changes

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] Existing warehouse source configurations are deleted
        SpecificQltyInspectSourceConfig.SetFilter("From Table No.", StrSubstNo(WarehouseFromTableFilterTok, Database::"Warehouse Entry", Database::"Warehouse Journal Line"));
        if SpecificQltyInspectSourceConfig.FindSet() then
            SpecificQltyInspectSourceConfig.DeleteAll();

        // [GIVEN] Warehouse trigger is set to NoTrigger
        QltyManagementSetup.Validate("Warehouse Trigger", QltyManagementSetup."Warehouse Trigger"::NoTrigger);

        // [WHEN] Warehouse trigger is changed to OnWhseMovementRegister
        QltyManagementSetup.Validate("Warehouse Trigger", QltyManagementSetup."Warehouse Trigger"::OnWhseMovementRegister);
        QltyManagementSetup.Modify();

        // [THEN] Two source configurations are created for warehouse tables
        SpecificQltyInspectSourceConfig.SetFilter("From Table No.", StrSubstNo(WarehouseFromTableFilterTok, Database::"Warehouse Entry", Database::"Warehouse Journal Line"));
        LibraryAssert.IsTrue(SpecificQltyInspectSourceConfig.Count() = 2, 'Should have created source configurations.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure SetupTable_ValidateWarehouseTrigger_AddTrigger()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
    begin
        // [SCENARIO] ValidateWarehouseTrigger adds trigger to new warehouse rules when setup trigger is configured

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] Management setup warehouse trigger is set to OnWhseMovementRegister
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Warehouse Trigger", QltyManagementSetup."Warehouse Trigger"::OnWhseMovementRegister);
        QltyManagementSetup.Modify();

        // [GIVEN] A warehouse journal line rule is created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Journal Line", QltyInspectionGenRule);

        // [WHEN] Source table is changed to Warehouse Entry
        QltyInspectionGenRule.Validate("Source Table No.", Database::"Warehouse Entry");
        QltyInspectionGenRule.Modify();

        // [THEN] Warehouse Movement Trigger defaults to OnWhseMovementRegister
        LibraryAssert.IsTrue(QltyInspectionGenRule."Warehouse Movement Trigger" = QltyInspectionGenRule."Warehouse Movement Trigger"::OnWhseMovementRegister, 'Should have default trigger value.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure SetupTable_ValidateWarehouseTrigger_RemoveTrigger()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyManagementSetupPage: TestPage "Qlty. Management Setup";
    begin
        // [SCENARIO] ValidateWarehouseTrigger removes trigger from existing warehouse rules when trigger is set to NoTrigger

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] Management setup warehouse trigger is set to OnWhseMovementRegister
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Warehouse Trigger", QltyManagementSetup."Warehouse Trigger"::OnWhseMovementRegister);
        QltyManagementSetup.Modify();

        // [GIVEN] A warehouse rule is created with trigger
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Journal Line", QltyInspectionGenRule);
        QltyInspectionGenRule.Validate("Source Table No.", Database::"Warehouse Entry");
        QltyInspectionGenRule.Modify();

        // [GIVEN] Setup page is opened
        QltyManagementSetupPage.OpenEdit();

        // [WHEN] Warehouse trigger is set to NoTrigger via page
        QltyManagementSetupPage."Warehouse Trigger".SetValue(QltyManagementSetup."Warehouse Trigger"::NoTrigger);
        QltyManagementSetupPage.Close();

        // [THEN] Existing warehouse rule has trigger removed
        QltyInspectionGenRule.Get(QltyInspectionGenRule."Entry No.");
        LibraryAssert.IsTrue(QltyInspectionGenRule."Warehouse Movement Trigger" = QltyInspectionGenRule."Warehouse Movement Trigger"::NoTrigger, 'Should not have trigger.');
    end;

    [Test]
    [HandlerFunctions('ItemJournalBatchesModalPageHandler')]
    procedure SetupTable_LookupBinMoveBatchName()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyManagementSetupPage: TestPage "Qlty. Management Setup";
    begin
        // [SCENARIO] LookupBinMoveBatchName allows selecting item journal batch for bin movements

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] Existing item reclass journal templates are deleted
        ItemJournalTemplate.SetRange("Page ID", Page::"Item Reclass. Journal");
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Transfer);
        if ItemJournalTemplate.FindSet() then
            ItemJournalTemplate.DeleteAll();

        // [GIVEN] A new item journal template for transfers is created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);
        ItemJournalTemplate.Validate("Page ID", Page::"Item Reclass. Journal");
        ItemJournalTemplate.Validate(Recurring, false);
        ItemJournalTemplate.Modify();

        // [GIVEN] An item journal batch is created
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] The batch for the reclass template is found
        Clear(ItemJournalBatch);
        ItemJournalBatch.SetRange("Journal Template Name", QltyManagementSetup.GetItemReclassJournalTemplate());
        ItemJournalBatch.FindFirst();

        // [GIVEN] Setup page is opened
        QltyManagementSetupPage.OpenEdit();

        // [WHEN] Bin Move Batch Name lookup is invoked
        QltyManagementSetupPage."Bin Move Batch Name".Lookup();
        QltyManagementSetupPage.Close();

        // [THEN] Setup is updated with selected batch name
        QltyManagementSetup.Get();
        LibraryAssert.AreEqual(ItemJournalBatch.Name, QltyManagementSetup."Bin Move Batch Name", 'Should be same batch name.');

        // [GIVEN] Created records are cleaned up
        ItemJournalBatch.Delete();
        ItemJournalTemplate.Delete();
    end;

    [Test]
    [HandlerFunctions('WhseJournalBatchesModalPageHandler')]
    procedure SetupTable_LookupBinWhseMoveBatchName()
    var
        Location: Record Location;
        QltyManagementSetup: Record "Qlty. Management Setup";
        WhseWarehouseJournalTemplate: Record "Warehouse Journal Template";
        WhseWarehouseJournalBatch: Record "Warehouse Journal Batch";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        QltyManagementSetupPage: TestPage "Qlty. Management Setup";
    begin
        // [SCENARIO] LookupBinWhseMoveBatchName allows selecting warehouse journal batch for bin movements

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A full WMS location is created
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);

        // [GIVEN] Existing warehouse journal templates are deleted
        if not WhseWarehouseJournalTemplate.IsEmpty() then
            WhseWarehouseJournalTemplate.DeleteAll();

        // [GIVEN] A warehouse journal template for reclassification is created
        LibraryWarehouse.CreateWhseJournalTemplate(WhseWarehouseJournalTemplate, WhseWarehouseJournalTemplate.Type::Reclassification);
        WhseWarehouseJournalTemplate.Validate("Page ID", Page::"Whse. Reclassification Journal");
        WhseWarehouseJournalTemplate.Modify();

        // [GIVEN] Existing warehouse journal batches are deleted
        if not WhseWarehouseJournalBatch.IsEmpty() then
            WhseWarehouseJournalBatch.DeleteAll();

        // [GIVEN] A warehouse journal batch is created
        LibraryWarehouse.CreateWhseJournalBatch(WhseWarehouseJournalBatch, WhseWarehouseJournalTemplate.Name, Location.Code);

        // [GIVEN] The batch for the reclassification template is found
        Clear(WhseWarehouseJournalBatch);
        WhseWarehouseJournalBatch.SetRange("Journal Template Name", QltyManagementSetup.GetWarehouseReclassificationJournalTemplate());
        WhseWarehouseJournalBatch.FindFirst();

        // [GIVEN] Setup page is opened
        QltyManagementSetupPage.OpenEdit();

        // [WHEN] Bin Whse. Move Batch Name lookup is invoked
        QltyManagementSetupPage."Bin Whse. Move Batch Name".Lookup();
        QltyManagementSetupPage.Close();

        // [THEN] Setup is updated with selected batch name
        QltyManagementSetup.Get();
        LibraryAssert.AreEqual(WhseWarehouseJournalBatch.Name, QltyManagementSetup."Bin Whse. Move Batch Name", 'Should be same batch name.');

        // [GIVEN] Created records are cleaned up
        WhseWarehouseJournalBatch.Delete();
        WhseWarehouseJournalTemplate.Delete();
    end;

    [Test]
    [HandlerFunctions('WhseWorksheetNamesModalPageHandler')]
    procedure SetupTable_LookupWhseWkshName()
    var
        Location: Record Location;
        QltyManagementSetup: Record "Qlty. Management Setup";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        QltyManagementSetupPage: TestPage "Qlty. Management Setup";
        TemplateName: Text;
    begin
        // [SCENARIO] LookupWhseWkshName allows selecting warehouse worksheet name for movements

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A full WMS location is created
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);

        // [GIVEN] Existing warehouse worksheet templates are deleted
        if not WhseWorksheetTemplate.IsEmpty() then
            WhseWorksheetTemplate.DeleteAll();

        // [GIVEN] A new warehouse worksheet template is initialized
        WhseWorksheetTemplate.Init();

        // [GIVEN] A random template name is generated
        QltyInspectionUtility.GenerateRandomCharacters(10, TemplateName);
        WhseWorksheetTemplate.Name := CopyStr(TemplateName, 1, MaxStrLen(WhseWorksheetTemplate.Name));

        // [GIVEN] Template is configured for Movement type
        WhseWorksheetTemplate.Validate(Type, WhseWorksheetTemplate.Type::Movement);
        WhseWorksheetTemplate.Validate("Page ID", Page::"Movement Worksheet");
        WhseWorksheetTemplate.Insert();

        // [GIVEN] Existing warehouse worksheet names are deleted
        if not WhseWorksheetName.IsEmpty() then
            WhseWorksheetName.DeleteAll();

        // [GIVEN] A warehouse worksheet name is created
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);

        // [GIVEN] The worksheet name for the movement template is found
        Clear(WhseWorksheetName);
        WhseWorksheetName.SetRange("Worksheet Template Name", QltyManagementSetup.GetMovementWorksheetTemplateName());
        WhseWorksheetName.FindFirst();

        // [GIVEN] Setup page is opened
        QltyManagementSetupPage.OpenEdit();

        // [WHEN] Whse. Wksh. Name lookup is invoked
        QltyManagementSetupPage."Whse. Wksh. Name".Lookup();
        QltyManagementSetupPage.Close();

        // [THEN] Setup is updated with selected worksheet name
        QltyManagementSetup.Get();
        LibraryAssert.AreEqual(WhseWorksheetName.Name, QltyManagementSetup."Whse. Wksh. Name", 'Should be same name.');

        // [GIVEN] Created records are cleaned up
        WhseWorksheetName.Delete();
        WhseWorksheetTemplate.Delete();
    end;

    [Test]
    [HandlerFunctions('ItemJournalBatchesModalPageHandler')]
    procedure SetupTable_LookupAdjustmentBatchName()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyManagementSetupPage: TestPage "Qlty. Management Setup";
    begin
        // [SCENARIO] LookupAdjustmentBatchName allows selecting item journal batch for inventory adjustments

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] Existing item journal templates are deleted
        ItemJournalTemplate.SetRange("Page ID", Page::"Item Journal");
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        if ItemJournalTemplate.FindSet() then
            ItemJournalTemplate.DeleteAll();

        // [GIVEN] A new item journal template is created
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("Page ID", Page::"Item Journal");
        ItemJournalTemplate.Validate(Recurring, false);
        ItemJournalTemplate.Modify();

        // [GIVEN] An item journal batch is created
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] The batch for the adjustment template is found
        Clear(ItemJournalBatch);
        ItemJournalBatch.SetRange("Journal Template Name", QltyManagementSetup.GetInventoryAdjustmentJournalTemplate());
        ItemJournalBatch.FindFirst();

        // [GIVEN] Setup page is opened
        QltyManagementSetupPage.OpenEdit();

        // [WHEN] Item Adjustment Batch Name lookup is invoked
        QltyManagementSetupPage."Item Adjustment Batch Name".Lookup();
        QltyManagementSetupPage.Close();

        // [THEN] Setup is updated with selected batch name
        QltyManagementSetup.Get();
        LibraryAssert.AreEqual(ItemJournalBatch.Name, QltyManagementSetup."Adjustment Batch Name", 'Should be same batch name.');

        // [GIVEN] Created records are cleaned up
        ItemJournalBatch.Delete();
        ItemJournalTemplate.Delete();
    end;

    [Test]
    [HandlerFunctions('WhseJournalBatchesModalPageHandler')]
    procedure SetupTable_LookupWhseAdjustmentBatchName()
    var
        Location: Record Location;
        QltyManagementSetup: Record "Qlty. Management Setup";
        WhseWarehouseJournalTemplate: Record "Warehouse Journal Template";
        WhseWarehouseJournalBatch: Record "Warehouse Journal Batch";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        QltyManagementSetupPage: TestPage "Qlty. Management Setup";
    begin
        // [SCENARIO] LookupWhseAdjustmentBatchName allows selecting warehouse journal batch for inventory adjustments

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A full WMS location is created
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);

        // [GIVEN] Existing warehouse journal templates are deleted
        if not WhseWarehouseJournalTemplate.IsEmpty() then
            WhseWarehouseJournalTemplate.DeleteAll();

        // [GIVEN] A warehouse journal template for items is created
        LibraryWarehouse.CreateWhseJournalTemplate(WhseWarehouseJournalTemplate, WhseWarehouseJournalTemplate.Type::Item);
        WhseWarehouseJournalTemplate.Validate("Page ID", Page::"Whse. Item Journal");
        WhseWarehouseJournalTemplate.Modify();

        // [GIVEN] Existing warehouse journal batches are deleted
        if not WhseWarehouseJournalBatch.IsEmpty() then
            WhseWarehouseJournalBatch.DeleteAll();

        // [GIVEN] A warehouse journal batch is created
        LibraryWarehouse.CreateWhseJournalBatch(WhseWarehouseJournalBatch, WhseWarehouseJournalTemplate.Name, Location.Code);

        // [GIVEN] The batch for the adjustment template is found
        Clear(WhseWarehouseJournalBatch);
        WhseWarehouseJournalBatch.SetRange("Journal Template Name", QltyManagementSetup.GetWarehouseInventoryAdjustmentJournalTemplate());
        WhseWarehouseJournalBatch.FindFirst();

        // [GIVEN] Setup page is opened
        QltyManagementSetupPage.OpenEdit();

        // [WHEN] Whse. Adjustment Batch Name lookup is invoked
        QltyManagementSetupPage."Whse. Adjustment Batch Name".Lookup();
        QltyManagementSetupPage.Close();

        // [THEN] Setup is updated with selected batch name
        QltyManagementSetup.Get();
        LibraryAssert.AreEqual(WhseWarehouseJournalBatch.Name, QltyManagementSetup."Whse. Adjustment Batch Name", 'Should be same batch name.');

        // [GIVEN] Created records are cleaned up
        WhseWarehouseJournalBatch.Delete();
        WhseWarehouseJournalTemplate.Delete();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure SetupTable_ValidateWarehouseReceiveTrigger()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] ValidateWarehouseReceiveTrigger updates warehouse receive rules when setup trigger changes

        Initialize();

        // [GIVEN] All existing generation rules are deleted
        if not QltyInspectionGenRule.IsEmpty() then
            QltyInspectionGenRule.DeleteAll();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A warehouse receipt line rule is created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Receipt Line", QltyInspectionGenRule);
        LibraryAssert.IsTrue(QltyInspectionGenRule."Warehouse Receive Trigger" = QltyInspectionGenRule."Warehouse Receive Trigger"::NoTrigger, 'Should not have trigger.');

        // [GIVEN] Setup is updated to OnWarehouseReceiptCreate trigger
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Warehouse Receive Trigger", QltyManagementSetup."Warehouse Receive Trigger"::OnWarehouseReceiptCreate);
        QltyManagementSetup.Modify();

        // [GIVEN] Existing rule is retrieved and still has NoTrigger
        QltyInspectionGenRule.Get(QltyInspectionGenRule."Entry No.");
        LibraryAssert.IsTrue(QltyInspectionGenRule."Warehouse Receive Trigger" = QltyInspectionGenRule."Warehouse Receive Trigger"::NoTrigger, 'Should not have trigger.');

        // [GIVEN] A new rule is created for different source table
        Clear(QltyInspectionGenRule);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);

        // [GIVEN] Source table is changed to Warehouse Receipt Line
        QltyInspectionGenRule.Validate("Source Table No.", Database::"Warehouse Receipt Line");
        QltyInspectionGenRule.Modify();
        LibraryAssert.IsTrue(QltyInspectionGenRule."Warehouse Receive Trigger" = QltyInspectionGenRule."Warehouse Receive Trigger"::OnWarehouseReceiptCreate, 'Should have default trigger.');

        // [WHEN] Setup trigger is changed to OnWarehouseReceiptPost
        QltyManagementSetup.Validate("Warehouse Receive Trigger", QltyManagementSetup."Warehouse Receive Trigger"::OnWarehouseReceiptPost);
        QltyManagementSetup.Modify();

        // [THEN] Existing warehouse receipt rule is updated to new trigger
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.SetRange("Warehouse Receive Trigger", QltyInspectionGenRule."Warehouse Receive Trigger"::OnWarehouseReceiptPost);
        LibraryAssert.AreEqual(1, QltyInspectionGenRule.Count(), 'Production rule should have new production trigger value.');

        // [GIVEN] All generation rules are cleaned up
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure SetupTable_ValidatePurchaseTrigger()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] ValidatePurchaseTrigger updates purchase rules when setup trigger changes

        Initialize();

        // [GIVEN] All existing generation rules are deleted
        if not QltyInspectionGenRule.IsEmpty() then
            QltyInspectionGenRule.DeleteAll();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A purchase line rule is created with no trigger
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);
        LibraryAssert.IsTrue(QltyInspectionGenRule."Purchase Trigger" = QltyInspectionGenRule."Purchase Trigger"::NoTrigger, 'Should not have trigger.');

        // [GIVEN] Setup purchase trigger is set to OnPurchaseOrderPostReceive
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Purchase Trigger", QltyManagementSetup."Purchase Trigger"::OnPurchaseOrderPostReceive);
        QltyManagementSetup.Modify();

        // [GIVEN] Existing rule still has NoTrigger
        QltyInspectionGenRule.Get(QltyInspectionGenRule."Entry No.");
        LibraryAssert.IsTrue(QltyInspectionGenRule."Purchase Trigger" = QltyInspectionGenRule."Purchase Trigger"::NoTrigger, 'Should not have trigger.');

        // [GIVEN] A new rule is created for different source table
        Clear(QltyInspectionGenRule);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);

        // [GIVEN] Source table is changed to Purchase Line
        QltyInspectionGenRule.Validate("Source Table No.", Database::"Purchase Line");
        QltyInspectionGenRule.Modify();
        LibraryAssert.IsTrue(QltyInspectionGenRule."Purchase Trigger" = QltyInspectionGenRule."Purchase Trigger"::OnPurchaseOrderPostReceive, 'Should have default trigger.');

        // [WHEN] Setup trigger is changed to NoTrigger
        QltyManagementSetup.Validate("Purchase Trigger", QltyManagementSetup."Purchase Trigger"::NoTrigger);
        QltyManagementSetup.Modify();

        // [THEN] All purchase rules have trigger removed
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.SetRange("Purchase Trigger", QltyInspectionGenRule."Purchase Trigger"::NoTrigger);
        LibraryAssert.AreEqual(2, QltyInspectionGenRule.Count(), 'Purchase rule should have new purchase trigger value.');

        // [GIVEN] All generation rules are cleaned up
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure SetupTable_ValidateSalesReturnTrigger()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] ValidateSalesReturnTrigger updates sales return rules when setup trigger changes

        Initialize();

        // [GIVEN] All existing generation rules are deleted
        if not QltyInspectionGenRule.IsEmpty() then
            QltyInspectionGenRule.DeleteAll();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A sales line rule is created with no trigger
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Sales Line", QltyInspectionGenRule);
        LibraryAssert.IsTrue(QltyInspectionGenRule."Sales Return Trigger" = QltyInspectionGenRule."Sales Return Trigger"::NoTrigger, 'Should not have trigger.');

        // [GIVEN] Setup sales return trigger is set to OnSalesReturnOrderPostReceive
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Sales Return Trigger", QltyManagementSetup."Sales Return Trigger"::OnSalesReturnOrderPostReceive);
        QltyManagementSetup.Modify();

        // [GIVEN] Existing rule still has NoTrigger
        QltyInspectionGenRule.Get(QltyInspectionGenRule."Entry No.");
        LibraryAssert.IsTrue(QltyInspectionGenRule."Sales Return Trigger" = QltyInspectionGenRule."Sales Return Trigger"::NoTrigger, 'Should not have trigger.');

        // [GIVEN] A new rule is created for different source table
        Clear(QltyInspectionGenRule);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);

        // [GIVEN] Source table is changed to Sales Line
        QltyInspectionGenRule.Validate("Source Table No.", Database::"Sales Line");
        QltyInspectionGenRule.Modify();
        LibraryAssert.IsTrue(QltyInspectionGenRule."Sales Return Trigger" = QltyInspectionGenRule."Sales Return Trigger"::OnSalesReturnOrderPostReceive, 'Should have default trigger.');

        // [WHEN] Setup trigger is changed to NoTrigger
        QltyManagementSetup.Validate("Sales Return Trigger", QltyManagementSetup."Sales Return Trigger"::NoTrigger);
        QltyManagementSetup.Modify();

        // [THEN] All sales return rules have trigger removed
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.SetRange("Sales Return Trigger", QltyInspectionGenRule."Sales Return Trigger"::NoTrigger);
        LibraryAssert.AreEqual(2, QltyInspectionGenRule.Count(), 'Sales Return rule should have new sales return trigger value.');

        // [GIVEN] All generation rules are cleaned up
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure SetupTable_ValidateTransferTrigger()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] ValidateTransferTrigger updates transfer rules when setup trigger changes

        Initialize();

        // [GIVEN] All existing generation rules are deleted
        if not QltyInspectionGenRule.IsEmpty() then
            QltyInspectionGenRule.DeleteAll();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A transfer line rule is created with no trigger
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Transfer Line", QltyInspectionGenRule);
        LibraryAssert.IsTrue(QltyInspectionGenRule."Transfer Trigger" = QltyInspectionGenRule."Transfer Trigger"::NoTrigger, 'Should not have trigger.');

        // [GIVEN] Setup transfer trigger is set to OnTransferOrderPostReceive
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Transfer Trigger", QltyManagementSetup."Transfer Trigger"::OnTransferOrderPostReceive);
        QltyManagementSetup.Modify();

        // [GIVEN] Existing rule still has NoTrigger
        QltyInspectionGenRule.Get(QltyInspectionGenRule."Entry No.");
        LibraryAssert.IsTrue(QltyInspectionGenRule."Transfer Trigger" = QltyInspectionGenRule."Transfer Trigger"::NoTrigger, 'Should not have trigger.');

        // [GIVEN] A new rule is created for different source table
        Clear(QltyInspectionGenRule);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);

        // [GIVEN] Source table is changed to Transfer Line
        QltyInspectionGenRule.Validate("Source Table No.", Database::"Transfer Line");
        QltyInspectionGenRule.Modify();
        LibraryAssert.IsTrue(QltyInspectionGenRule."Transfer Trigger" = QltyInspectionGenRule."Transfer Trigger"::OnTransferOrderPostReceive, 'Should have default trigger.');

        // [WHEN] Setup trigger is changed to NoTrigger
        QltyManagementSetup.Validate("Transfer Trigger", QltyManagementSetup."Transfer Trigger"::NoTrigger);
        QltyManagementSetup.Modify();

        // [THEN] All transfer rules have trigger removed
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.SetRange("Transfer Trigger", QltyInspectionGenRule."Transfer Trigger"::NoTrigger);
        LibraryAssert.AreEqual(2, QltyInspectionGenRule.Count(), 'Transfer rule should have new transfer trigger value.');

        // [GIVEN] All generation rules are cleaned up
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure SetupTable_ValidateAssemblyTrigger()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] ValidateAssemblyTrigger updates assembly rules when setup trigger changes

        Initialize();

        // [GIVEN] All existing generation rules are deleted
        if not QltyInspectionGenRule.IsEmpty() then
            QltyInspectionGenRule.DeleteAll();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A posted assembly header rule is created with no trigger
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Posted Assembly Header", QltyInspectionGenRule);
        LibraryAssert.IsTrue(QltyInspectionGenRule."Assembly Trigger" = QltyInspectionGenRule."Assembly Trigger"::NoTrigger, 'Should not have trigger.');

        // [GIVEN] Setup assembly trigger is set to OnAssemblyOutputPost
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Assembly Trigger", QltyManagementSetup."Assembly Trigger"::OnAssemblyOutputPost);
        QltyManagementSetup.Modify();

        // [GIVEN] Existing rule still has NoTrigger
        QltyInspectionGenRule.Get(QltyInspectionGenRule."Entry No.");
        LibraryAssert.IsTrue(QltyInspectionGenRule."Assembly Trigger" = QltyInspectionGenRule."Assembly Trigger"::NoTrigger, 'Should not have trigger.');

        // [GIVEN] A new rule is created for different source table
        Clear(QltyInspectionGenRule);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);

        // [GIVEN] Source table is changed to Posted Assembly Header
        QltyInspectionGenRule.Validate("Source Table No.", Database::"Posted Assembly Header");
        QltyInspectionGenRule.Modify();
        LibraryAssert.IsTrue(QltyInspectionGenRule."Assembly Trigger" = QltyInspectionGenRule."Assembly Trigger"::OnAssemblyOutputPost, 'Should have default trigger.');

        // [WHEN] Setup trigger is changed to NoTrigger
        QltyManagementSetup.Validate("Assembly Trigger", QltyManagementSetup."Assembly Trigger"::NoTrigger);
        QltyManagementSetup.Modify();

        // [THEN] All assembly rules have trigger removed
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.SetRange("Assembly Trigger", QltyInspectionGenRule."Assembly Trigger"::NoTrigger);
        LibraryAssert.AreEqual(2, QltyInspectionGenRule.Count(), 'Assembly rule should have new assembly trigger value.');

        // [GIVEN] All generation rules are cleaned up
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('AssistEditTemplatePageHandler')]
    procedure SetupTable_AssistEditBrickFieldExpression()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        QltyManagementSetupPage: TestPage "Qlty. Management Setup";
    begin
        // [SCENARIO] AssistEditBrickFieldExpression allows configuring brick field expressions via AssistEdit

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A prioritized rule is created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] Handler will provide default expression
        AssistEditTemplateValue := DefaultExpressionTok;

        // [GIVEN] Setup page is opened
        QltyManagementSetupPage.OpenEdit();

        // [WHEN] Brick Top Left Expression AssistEdit is invoked
        QltyManagementSetupPage."Brick Top Left Expression".AssistEdit();
        QltyManagementSetupPage.Close();

        // [THEN] Setup is updated with brick expression
        QltyManagementSetup.Get();
        LibraryAssert.AreEqual(DefaultExpressionTok, QltyManagementSetup."Brick Top Left Expression", 'Brick expression should match.');

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [THEN] Test brick field is calculated using expression
        LibraryAssert.AreEqual(QltyInspectionHeader."Brick Top Left", StrSubstNo(CalculatedExpressionTok, QltyInspectionHeader."No.", QltyInspectionHeader."Source Item No.", QltyInspectionHeader."Table Name"), 'Expressions should match.');

        // [GIVEN] Generation rule is cleaned up
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    [HandlerFunctions('AssistEditTemplatePageHandler,MessageHandler')]
    procedure SetupTable_UpdateBrickFieldsOnAllExistingInspection()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        QltyManagementSetupPage: TestPage "Qlty. Management Setup";
    begin
        // [SCENARIO] UpdateBrickFieldsOnAllExistingInspections recalculates brick fields on all existing inspections

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A prioritized rule is created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase before expression is set
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [GIVEN] Handler will provide default expression
        AssistEditTemplateValue := DefaultExpressionTok;

        // [GIVEN] Setup page is opened
        QltyManagementSetupPage.OpenEdit();

        // [GIVEN] Brick Top Left Expression is configured via AssistEdit
        QltyManagementSetupPage."Brick Top Left Expression".AssistEdit();
        QltyManagementSetupPage.Close();

        // [GIVEN] Setup is verified to have brick expression
        QltyManagementSetup.Get();
        LibraryAssert.AreEqual(DefaultExpressionTok, QltyManagementSetup."Brick Top Left Expression", 'Brick expression should match.');

        // [GIVEN] Handler will use same expression for update
        AssistEditTemplateValue := DefaultExpressionTok;

        // [GIVEN] Setup page is reopened
        QltyManagementSetupPage.OpenEdit();

        // [WHEN] ChooseBrickUpdateExistingInspection drilldown is invoked
        QltyManagementSetupPage.ChooseBrickUpdateExistingInspection.Drilldown();
        QltyManagementSetupPage.Close();

        // [THEN] Existing inspection has brick field recalculated
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Reinspection No.");
        LibraryAssert.AreEqual(QltyInspectionHeader."Brick Top Left", StrSubstNo(CalculatedExpressionTok, QltyInspectionHeader."No.", QltyInspectionHeader."Source Item No.", QltyInspectionHeader."Table Name"), 'Expressions should match.');

        // [GIVEN] Generation rule is cleaned up
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure SetupTable_GetVersion()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        NAVAppInstalledApp: Record "NAV App Installed App";
        ReturnedVersion: Text;
    begin
        // [SCENARIO] GetVersion returns the installed app version information

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [WHEN] GetVersion is called and installed app record exists
        if NAVAppInstalledApp.Get(QltyManagementSetup.GetAppGuid()) then begin
            ReturnedVersion := QltyManagementSetup.GetVersion();

            // [THEN] Returned version contains major version number
            LibraryAssert.IsTrue(ReturnedVersion.Contains(Format(NAVAppInstalledApp."Version Major")), 'Returned version should have major version');

            // [THEN] Returned version contains minor version number
            LibraryAssert.IsTrue(ReturnedVersion.Contains(Format(NAVAppInstalledApp."Version Minor")), 'Returned version should have minor version');
        end;
    end;

    [Test]
    procedure GenerationRuleTable_ValidateTemplateCode()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] ValidateTemplateCode successfully validates and sets the template code

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template with one field is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A generation rule is initialized
        QltyInspectionGenRule.Init();

        // [WHEN] Template Code is validated with template code
        QltyInspectionGenRule.Validate("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);

        // [THEN] Template code is set correctly
        LibraryAssert.AreEqual(ConfigurationToLoadQltyInspectionTemplateHdr.Code, QltyInspectionGenRule."Template Code", 'Should be same template.');
    end;

    [Test]
    procedure GenerationRuleTable_UpdateSortOrder()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        LastQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] UpdateSortOrder automatically assigns incremental sort order values to new rules

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A first generation rule is initialized and inserted
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule.Validate("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        QltyInspectionGenRule."Source Table No." := Database::"Purchase Line";
        QltyInspectionGenRule.Insert(true);

        // [GIVEN] The last rule by sort order is found
        LastQltyInspectionGenRule.SetCurrentKey("Sort Order");
        LastQltyInspectionGenRule.Ascending(false);
        LastQltyInspectionGenRule.FindFirst();

        // [GIVEN] A second generation rule is initialized
        Clear(QltyInspectionGenRule);
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule.Validate("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        QltyInspectionGenRule."Source Table No." := Database::"Purchase Line";

        // [WHEN] The second rule is inserted with auto-numbering
        QltyInspectionGenRule.Insert(true);

        // [THEN] Sort order is 10 higher than previous rule
        LibraryAssert.AreEqual(LastQltyInspectionGenRule."Sort Order" + 10, QltyInspectionGenRule."Sort Order", 'Should have next available sort order.');
    end;

    [Test]
    procedure GenerationRuleTable_GetTemplateCodeFromRecordOrFilter_Record()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        TemplateCode: Code[20];
    begin
        // [SCENARIO] GetTemplateCodeFromRecordOrFilter returns template code from current record

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A prioritized rule is created for the template
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [WHEN] GetTemplateCodeFromRecordOrFilter is called with record mode (false)
        TemplateCode := QltyInspectionGenRule.GetTemplateCodeFromRecordOrFilter(false);

        // [THEN] Returned template code matches template
        LibraryAssert.AreEqual(ConfigurationToLoadQltyInspectionTemplateHdr.Code, TemplateCode, 'Should be same template code.');
    end;

    [Test]
    procedure GenerationRuleTable_GetTemplateCodeFromRecordOrFilter_Filter()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        FilterQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        TemplateCode: Code[20];
    begin
        // [SCENARIO] GetTemplateCodeFromRecordOrFilter returns template code from filter

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A prioritized rule is created for the template
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A filter is set for the template code
        FilterQltyInspectionGenRule.SetRange("Template Code", QltyInspectionGenRule."Template Code");

        // [WHEN] GetTemplateCodeFromRecordOrFilter is called with filter mode (true)
        TemplateCode := FilterQltyInspectionGenRule.GetTemplateCodeFromRecordOrFilter(true);

        // [THEN] Returned template code matches template
        LibraryAssert.AreEqual(ConfigurationToLoadQltyInspectionTemplateHdr.Code, TemplateCode, 'Should be same template code.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_Certain()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] InferGenerationRuleIntent correctly infers intent from source table number for known tables

        Initialize();

        // [WHEN] Source table is Warehouse Receipt Line
        QltyInspectionGenRule."Source Table No." := Database::"Warehouse Receipt Line";
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] Intent is inferred as Warehouse Receipt
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::"Warehouse Receipt", 'Should return Warehouse Receipt intent.');

        // [WHEN] Source table is Warehouse Entry
        QltyInspectionGenRule."Source Table No." := Database::"Warehouse Entry";
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] Intent is inferred as Warehouse Movement
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::"Warehouse Movement", 'Should return Warehouse Movement intent.');

        // [WHEN] Source table is Purchase Line
        QltyInspectionGenRule."Source Table No." := Database::"Purchase Line";
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] Intent is inferred as Purchase
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Purchase, 'Should return Purchase intent.');

        // [WHEN] Source table is Sales Line
        QltyInspectionGenRule."Source Table No." := Database::"Sales Line";
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] Intent is inferred as Sales Return
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::"Sales Return", 'Should return Sales Return intent.');

        // [WHEN] Source table is Transfer Line
        QltyInspectionGenRule."Source Table No." := Database::"Transfer Line";
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] Intent is inferred as Transfer
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Transfer, 'Should return Transfer intent.');

        // [WHEN] Source table is Transfer Receipt Line
        QltyInspectionGenRule."Source Table No." := Database::"Transfer Receipt Line";
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] Intent is inferred as Transfer
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Transfer, 'Should return Transfer intent.');

        // [WHEN] Source table is Prod. Order Routing Line
        QltyInspectionGenRule."Source Table No." := Database::"Prod. Order Routing Line";
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] Intent is inferred as Production
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Production, 'Should return Production intent.');

        // [WHEN] Source table is Prod. Order Line
        QltyInspectionGenRule."Source Table No." := Database::"Prod. Order Line";
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] Intent is inferred as Production
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Production, 'Should return Production intent.');

        // [WHEN] Source table is Production Order
        QltyInspectionGenRule."Source Table No." := Database::"Production Order";
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] Intent is inferred as Production
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Production, 'Should return "Production Order intent.');

        // [WHEN] Source table is Posted Assembly Header
        QltyInspectionGenRule."Source Table No." := Database::"Posted Assembly Header";
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] Intent is inferred as Assembly
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Assembly, 'Should return Assembly intent.');

        // [WHEN] Source table is Assembly Line
        QltyInspectionGenRule."Source Table No." := Database::"Assembly Line";
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] Intent is inferred as Assembly
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Assembly, 'Should return Assembly intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_ItemJournalLine_EntryTypeFilter_Production()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Item Journal Line with Entry Type filter for Production Output

        Initialize();

        // [GIVEN] A generation rule for Item Journal Line with Entry Type filter for Output
        QltyInspectionGenRule."Source Table No." := Database::"Item Journal Line";
        QltyInspectionGenRule."Condition Filter" := ConditionFilterOutputTok;

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Production
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Production, 'Should return Production intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_ItemJournalLine_OrderTypeFilter_Production()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Item Journal Line with Order Type filter for Production

        Initialize();

        // [GIVEN] A generation rule for Item Journal Line with Order Type filter for Production
        QltyInspectionGenRule."Source Table No." := Database::"Item Journal Line";
        QltyInspectionGenRule."Condition Filter" := ConditionFilterProductionTok;

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Production
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Production, 'Should return Production intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_ItemJournalLine_DocumentTypeFilter_Purchase()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Item Journal Line with Document Type filter for Purchase

        Initialize();

        // [GIVEN] A generation rule for Item Journal Line with Document Type filter for Purchase Receipt
        QltyInspectionGenRule."Source Table No." := Database::"Item Journal Line";
        QltyInspectionGenRule."Condition Filter" := ConditionFilterPurchaseReceiptTok;

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Purchase
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Purchase, 'Should return Purchase intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_ItemJournalLine_DocumentTypeFilter_SalesReturn()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Item Journal Line with Document Type filter for Sales Return

        Initialize();

        // [GIVEN] A generation rule for Item Journal Line with Document Type filter for Sales Return Receipt
        QltyInspectionGenRule."Source Table No." := Database::"Item Journal Line";
        QltyInspectionGenRule."Condition Filter" := ConditionFilterSalesReturnReceiptTok;

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Sales Return
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::"Sales Return", 'Should return Sales Return intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_ItemJournalLine_DocumentTypeFilter_TransferReceipt()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Item Journal Line with Document Type filter for Transfer Receipt

        Initialize();

        // [GIVEN] A generation rule for Item Journal Line with Document Type filter for Transfer Receipt
        QltyInspectionGenRule."Source Table No." := Database::"Item Journal Line";
        QltyInspectionGenRule."Condition Filter" := ConditionFilterTransferReceiptTok;

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Transfer
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Transfer, 'Should return Transfer intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_ItemJournalLine_DocumentTypeFilter_DirectTransfer()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Item Journal Line with Document Type filter for Direct Transfer

        Initialize();

        // [GIVEN] A generation rule for Item Journal Line with Document Type filter for Direct Transfer
        QltyInspectionGenRule."Source Table No." := Database::"Item Journal Line";
        QltyInspectionGenRule."Condition Filter" := ConditionFilterDirectTransferTok;

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Transfer
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Transfer, 'Should return Transfer intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_ItemLedgerEntry_EntryTypeFilter_Production()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Item Ledger Entry with Entry Type filter for Production Output
        Initialize();

        // [GIVEN] A generation rule for Item Ledger Entry with Entry Type filter for Output
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule."Condition Filter" := ConditionFilterOutputTok;

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Production
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Production, 'Should return Production intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_ItemLedgerEntry_OrderTypeFilter_Production()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Item Ledger Entry with Order Type filter for Production
        Initialize();

        // [GIVEN] A generation rule for Item Ledger Entry with Order Type filter for Production
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule."Condition Filter" := ConditionFilterProductionTok;

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Production
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Production, 'Should return Production intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_ItemLegerEntry_EntryTypeFilter_Purchase()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Item Ledger Entry with Entry Type filter for Purchase
        Initialize();

        // [GIVEN] A generation rule for Item Ledger Entry with Entry Type filter for Purchase
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule."Condition Filter" := ConditionFilterPurchaseTok;

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Purchase
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Purchase, 'Should return Purchase intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_ItemLegerEntry_DocumentTypeFilter_SalesReturn()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Item Ledger Entry with Document Type filter for Sales Return
        Initialize();

        // [GIVEN] A generation rule for Item Ledger Entry with Entry Type filter for Sale
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule."Condition Filter" := ConditionFilterSaleTok;

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Sales Return
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::"Sales Return", 'Should return Sales Return intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_ItemLegerEntry_EntryTypeFilter_TransferReceipt()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Item Ledger Entry with Entry Type filter for Transfer
        Initialize();

        // [GIVEN] A generation rule for Item Ledger Entry with Entry Type filter for Transfer
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule."Condition Filter" := ConditionFilterTransferTok;

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Transfer
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Transfer, 'Should return Transfer intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_ItemLegerEntry_DocumentTypeFilter_Assembly()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Item Ledger Entry with Document Type filter for Assembly Output
        Initialize();

        // [GIVEN] A generation rule for Item Ledger Entry with Entry Type filter for Assembly Output
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule."Condition Filter" := ConditionFilterAssemblyOutputTok;

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Assembly
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Assembly, 'Should return Assembly intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_WarehouseJournalLine_WhseDocumentFilter_Receive()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Warehouse Journal Line with Warehouse Document Type filter for Receipt
        Initialize();

        // [GIVEN] A generation rule for Warehouse Journal Line with Warehouse Document Type filter for Receipt
        QltyInspectionGenRule."Source Table No." := Database::"Warehouse Journal Line";
        QltyInspectionGenRule."Condition Filter" := ConditionFilterWhseReceiptTok;

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Warehouse Receipt
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::"Warehouse Receipt", 'Should return Warehouse Receive intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_WarehouseJournalLine_ReferenceDocumentFilter_Receive()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Warehouse Journal Line with Reference Document filter for Posted Receipt
        Initialize();

        // [GIVEN] A generation rule for Warehouse Journal Line with Reference Document filter for Posted Receipt
        QltyInspectionGenRule."Source Table No." := Database::"Warehouse Journal Line";
        QltyInspectionGenRule."Condition Filter" := ConditionFilterPostedRcptTok;

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Warehouse Receipt
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::"Warehouse Receipt", 'Should return Warehouse Receive intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_WarehouseJournalLine_WhseDocumentTypeFilter_Move()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Warehouse Journal Line with Warehouse Document Type filter for Internal Put-away
        Initialize();

        // [GIVEN] A generation rule for Warehouse Journal Line with Warehouse Document Type filter for Internal Put-away
        QltyInspectionGenRule."Source Table No." := Database::"Warehouse Journal Line";
        QltyInspectionGenRule."Condition Filter" := ConditionFilterInternalPutAwayTok;

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Warehouse Movement
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::"Warehouse Movement", 'Should return Warehouse Movement intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_WarehouseJournalLine_EntryTypeFilter_Move()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyGenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Warehouse Journal Line with Entry Type filter for Movement
        Initialize();

        // [GIVEN] A generation rule for Warehouse Journal Line with Entry Type filter for Movement
        QltyInspectionGenRule."Source Table No." := Database::"Warehouse Journal Line";
        QltyInspectionGenRule."Condition Filter" := ConditionFilterMovementTok;

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(QltyGenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Warehouse Movement
        LibraryAssert.IsTrue(QltyGenRuleIntent = QltyGenRuleIntent::"Warehouse Movement", 'Should return Warehouse Movement intent.');
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_ItemJournalLine_OnlyTriggerInSetup_Production()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Item Journal Line when only Production trigger is set in setup
        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A generation rule for Item Journal Line with no condition filter
        QltyInspectionGenRule."Source Table No." := Database::"Item Journal Line";

        // [GIVEN] Setup with only Production trigger enabled
        QltyManagementSetup.Get();
        QltyInspectionUtility.ClearSetupTriggerDefaults(QltyManagementSetup);
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::OnProductionOrderRelease;
        QltyManagementSetup.Modify();

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is Production with Maybe certainty
        LibraryAssert.AreEqual(GenRuleIntent::Production, GenRuleIntent, 'Should return Production intent.');
        LibraryAssert.AreEqual(Certainty::Maybe, Certainty, 'Should be  maybe on certainty.');

        // [THEN] Cleanup: Disable Production trigger
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
        QltyManagementSetup.Modify();
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_ItemLedgerEntry_OnlyTriggerInSetup_Production()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Item Ledger Entry when only Production trigger is set in setup
        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A generation rule for Item Ledger Entry with no condition filter
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";

        // [GIVEN] Setup with only Production trigger enabled
        QltyManagementSetup.Get();
        QltyInspectionUtility.ClearSetupTriggerDefaults(QltyManagementSetup);
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::OnProductionOrderRelease;
        QltyManagementSetup.Modify();

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Production
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Production, 'Should return Production intent.');

        // [THEN] Cleanup: Disable Production trigger
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
        QltyManagementSetup.Modify();
    end;

    [Test]
    procedure GenerationRuleTable_MultipleRangeValues()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Item Ledger Entry with multiple range values in filter
        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A generation rule for Item Ledger Entry
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule."Condition Filter" := 'WHERE(Entry Type=FILTER(Output|Positive Adjmt.))';

        // [GIVEN] Setup with Production trigger enabled
        QltyManagementSetup.Get();
        QltyInspectionUtility.ClearSetupTriggerDefaults(QltyManagementSetup);
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::OnProductionOrderRelease;
        QltyManagementSetup.Modify();

        // [WHEN] Inferring intent with Output first in filter
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] Production intent is returned (Output recognized)
        LibraryAssert.AreEqual(GenRuleIntent::Production, GenRuleIntent, 'Should return Production intent (first)');

        // [WHEN] Inferring intent with Output last in filter
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule."Condition Filter" := 'WHERE(Entry Type=FILTER(Positive Adjmt.|Output))';

        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] Production intent is returned (Output recognized at end)
        LibraryAssert.AreEqual(GenRuleIntent::Production, GenRuleIntent, 'Should return Production intent (last).');

        // [WHEN] Inferring intent without Output in filter
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule."Condition Filter" := 'WHERE(Entry Type=FILTER(Positive Adjmt.|Purchase|Sale))';

        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] Production intent is not returned
        LibraryAssert.AreNotEqual(GenRuleIntent::Production, GenRuleIntent, 'Should not be a Production intent.');

        // [WHEN] Inferring intent with Output in middle of filter
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule."Condition Filter" := 'WHERE(Entry Type=FILTER(Positive Adjmt.|Output|Purchase|Sale))';

        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] Production intent is returned (Output recognized in middle)
        LibraryAssert.AreEqual(GenRuleIntent::Production, GenRuleIntent, 'Should be a Production intent (output is in the middle.)');

        // [THEN] Cleanup: Disable Production trigger
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
        QltyManagementSetup.Modify();
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_ItemLedgerEntry_NotOnlyTriggerInSetup_Unknown()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent returns Unknown when multiple triggers are enabled in setup
        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A generation rule for Item Ledger Entry with no condition filter
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";

        // [GIVEN] Setup with all triggers enabled
        QltyManagementSetup.Get();
        QltyManagementSetup."Purchase Trigger" := QltyManagementSetup."Purchase Trigger"::OnPurchaseOrderPostReceive;
        QltyManagementSetup."Sales Return Trigger" := QltyManagementSetup."Sales Return Trigger"::OnSalesReturnOrderPostReceive;
        QltyManagementSetup."Transfer Trigger" := QltyManagementSetup."Transfer Trigger"::OnTransferOrderPostReceive;
        QltyManagementSetup."Assembly Trigger" := QltyManagementSetup."Assembly Trigger"::OnAssemblyOutputPost;
        QltyManagementSetup."Warehouse Receive Trigger" := QltyManagementSetup."Warehouse Receive Trigger"::OnWarehouseReceiptCreate;
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::OnWhseMovementRegister;
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::OnProductionOrderRelease;
        QltyManagementSetup.Modify();

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is Unknown (ambiguous due to multiple triggers)
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Unknown, 'Should return unknown intent.');

        // [THEN] Cleanup: Disable Production trigger
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
        QltyManagementSetup.Modify();
    end;

    [Test]
    procedure GenerationRuleTable_InferGenerationRuleIntent_WarehouseJournalLine_OnlyTriggerInSetup_WarehouseReceive()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        GenRuleIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // [SCENARIO] Infer generation rule intent from Warehouse Journal Line when only Warehouse Receive trigger is set in setup
        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetup();

        // [GIVEN] A generation rule for Warehouse Journal Line with no condition filter
        QltyInspectionGenRule."Source Table No." := Database::"Warehouse Journal Line";

        // [GIVEN] Setup with only Warehouse Receive trigger enabled
        QltyManagementSetup.Get();
        QltyInspectionUtility.ClearSetupTriggerDefaults(QltyManagementSetup);
        QltyManagementSetup."Warehouse Receive Trigger" := QltyManagementSetup."Warehouse Receive Trigger"::OnWarehouseReceiptCreate;
        QltyManagementSetup.Modify();

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Warehouse Receipt
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::"Warehouse Receipt", 'Should return Warehouse Receive intent.');

        // [THEN] Cleanup: Disable Warehouse Receive trigger
        QltyManagementSetup."Warehouse Receive Trigger" := QltyManagementSetup."Warehouse Receive Trigger"::NoTrigger;
        QltyManagementSetup.Modify();
    end;

    [Test]
    procedure GradeTable_TestValidateGradeCode()
    var
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
    begin
        // [SCENARIO] Validate grade code by removing special characters
        Initialize();

        // [WHEN] Validating grade code with special characters (GradeCode1Tok)
        ToLoadQltyInspectionGrade.Validate(Code, 'GRADE' + GradeCode1Tok);

        // [THEN] Special characters are removed from code
        LibraryAssert.AreEqual(ToLoadQltyInspectionGrade.Code, 'GRADE', 'Should remove special characters in grade code');

        // [WHEN] Validating grade code with different special characters (GradeCode2Tok)
        ToLoadQltyInspectionGrade.Validate(Code, 'GRADE' + GradeCode2Tok);

        // [THEN] Special characters are removed from code
        LibraryAssert.AreEqual(ToLoadQltyInspectionGrade.Code, 'GRADE', 'Should remove special characters in grade code');
    end;

    [Test]
    procedure GradeTable_TestOnDelete_ExistingTestLines_ShouldError()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        GradeCode: Text;
    begin
        // [SCENARIO] Cannot delete grade when it is referenced by existing inspection lines
        Initialize();

        // [GIVEN] All existing grades are deleted
        ToLoadQltyInspectionGrade.DeleteAll();

        // [GIVEN] A new grade is created
        QltyInspectionUtility.GenerateRandomCharacters(20, GradeCode);
        ToLoadQltyInspectionGrade.Code := CopyStr(GradeCode, 1, MaxStrLen(ToLoadQltyInspectionGrade.Code));
        ToLoadQltyInspectionGrade."Grade Category" := ToLoadQltyInspectionGrade."Grade Category"::Acceptable;
        ToLoadQltyInspectionGrade.Insert();

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] An inspection header is created
        QltyInspectionHeader."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        QltyInspectionHeader.Insert();

        // [GIVEN] An inspection line is created with the grade code
        QltyInspectionLine."Inspection No." := QltyInspectionHeader."No.";
        QltyInspectionLine."Reinspection No." := QltyInspectionHeader."Reinspection No.";
        QltyInspectionLine."Line No." := 10000;
        QltyInspectionLine."Grade Code" := ToLoadQltyInspectionGrade.Code;
        QltyInspectionLine.Insert();

        // [WHEN] Attempting to delete the grade
        asserterror ToLoadQltyInspectionGrade.Delete(true);

        // [THEN] An error is thrown preventing deletion
        LibraryAssert.ExpectedError(CannotBeRemovedExistingTestErr);
    end;

    [Test]
    procedure GradeTable_TestOnDelete_ExistingInspection_ShouldError()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        GradeCode: Text;
    begin
        // [SCENARIO] Cannot delete grade when it is referenced by existing inspection headers
        Initialize();

        // [GIVEN] All existing grades are deleted
        ToLoadQltyInspectionGrade.DeleteAll();

        // [GIVEN] A new grade is created
        QltyInspectionUtility.GenerateRandomCharacters(20, GradeCode);
        ToLoadQltyInspectionGrade.Code := CopyStr(GradeCode, 1, MaxStrLen(ToLoadQltyInspectionGrade.Code));
        ToLoadQltyInspectionGrade."Grade Category" := ToLoadQltyInspectionGrade."Grade Category"::Acceptable;
        ToLoadQltyInspectionGrade.Insert();

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] An inspection header is created with the grade code
        QltyInspectionHeader."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        QltyInspectionHeader."Grade Code" := ToLoadQltyInspectionGrade.Code;
        QltyInspectionHeader.Insert();

        // [WHEN] Attempting to delete the grade
        asserterror ToLoadQltyInspectionGrade.Delete(true);

        // [THEN] An error is thrown preventing deletion
        LibraryAssert.ExpectedError(CannotBeRemovedExistingTestErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GradeTable_TestOnDelete_ExistingTestGradeConditions()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        GradeCode: Text;
    begin
        // [SCENARIO] Delete grade with existing test grade conditions after confirmation
        Initialize();

        // [GIVEN] All existing grades are deleted
        ToLoadQltyInspectionGrade.DeleteAll();

        // [GIVEN] A new grade is created
        QltyInspectionUtility.GenerateRandomCharacters(20, GradeCode);
        ToLoadQltyInspectionGrade.Code := CopyStr(GradeCode, 1, MaxStrLen(ToLoadQltyInspectionGrade.Code));
        ToLoadQltyInspectionGrade."Grade Category" := ToLoadQltyInspectionGrade."Grade Category"::Acceptable;
        ToLoadQltyInspectionGrade.Insert();

        // [GIVEN] A template with one field is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionHeader."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        QltyInspectionHeader.Insert();

        // [GIVEN] Template line is retrieved
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.FindFirst();

        // [GIVEN] An inspection line is created
        QltyInspectionLine."Inspection No." := QltyInspectionHeader."No.";
        QltyInspectionLine."Reinspection No." := QltyInspectionHeader."Reinspection No.";
        QltyInspectionLine."Line No." := 10000;
        QltyInspectionLine."Field Code" := ConfigurationToLoadQltyInspectionTemplateLine."Field Code";
        QltyInspectionLine."Grade Code" := ToLoadQltyInspectionGrade.Code;
        QltyInspectionLine.Insert();

        // [GIVEN] A grade condition is created for the test
        ToLoadQltyIGradeConditionConf."Condition Type" := ToLoadQltyIGradeConditionConf."Condition Type"::Inspection;
        ToLoadQltyIGradeConditionConf."Target Code" := QltyInspectionHeader."No.";
        ToLoadQltyIGradeConditionConf."Target Reinspection No." := QltyInspectionHeader."Reinspection No.";
        ToLoadQltyIGradeConditionConf."Target Line No." := QltyInspectionLine."Line No.";
        ToLoadQltyIGradeConditionConf."Field Code" := QltyInspectionLine."Field Code";
        ToLoadQltyIGradeConditionConf."Grade Code" := ToLoadQltyInspectionGrade.Code;
        ToLoadQltyIGradeConditionConf.Insert();

        // [GIVEN] Inspection line and header are deleted
        QltyInspectionLine.Delete();
        QltyInspectionHeader.Delete();

        // [WHEN] Deleting the grade with confirmation
        ToLoadQltyInspectionGrade.Delete(true);

        // [THEN] Grade is successfully deleted
        ToLoadQltyInspectionGrade.SetRange(Code, ToLoadQltyInspectionGrade.Code);
        LibraryAssert.IsTrue(ToLoadQltyInspectionGrade.IsEmpty(), 'Should have deleted grade.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GradeTable_TestOnDelete_ExistingFieldGradeConditions()
    var
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        ToLoadQltyField: Record "Qlty. Field";
        GradeCode: Text;
    begin
        // [SCENARIO] Delete grade with existing field grade conditions after confirmation
        Initialize();

        // [GIVEN] All existing grades are deleted
        ToLoadQltyInspectionGrade.DeleteAll();

        // [GIVEN] A new grade is created
        QltyInspectionUtility.GenerateRandomCharacters(20, GradeCode);
        ToLoadQltyInspectionGrade.Code := CopyStr(GradeCode, 1, MaxStrLen(ToLoadQltyInspectionGrade.Code));
        ToLoadQltyInspectionGrade."Grade Category" := ToLoadQltyInspectionGrade."Grade Category"::Acceptable;
        ToLoadQltyInspectionGrade.Insert();

        // [GIVEN] A field is created
        ToLoadQltyField.Code := CopyStr(GradeCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField."Field Type" := ToLoadQltyField."Field Type"::"Field Type Integer";
        ToLoadQltyField.Insert();

        // [GIVEN] A grade condition is created for the field
        ToLoadQltyIGradeConditionConf."Condition Type" := ToLoadQltyIGradeConditionConf."Condition Type"::Field;
        ToLoadQltyIGradeConditionConf."Target Code" := ToLoadQltyField.Code;
        ToLoadQltyIGradeConditionConf."Field Code" := ToLoadQltyField.Code;
        ToLoadQltyIGradeConditionConf."Grade Code" := ToLoadQltyInspectionGrade.Code;
        ToLoadQltyIGradeConditionConf.Insert();

        // [WHEN] Deleting the grade with confirmation
        ToLoadQltyInspectionGrade.Delete(true);

        // [THEN] Grade is successfully deleted
        ToLoadQltyInspectionGrade.SetRange(Code, ToLoadQltyInspectionGrade.Code);
        LibraryAssert.IsTrue(ToLoadQltyInspectionGrade.IsEmpty(), 'Should have deleted grade.')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GradeTable_TestOnDelete_ExistingTemplateGradeConditions()
    var
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        ToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        GradeCode: Text;
    begin
        // [SCENARIO] Delete grade with existing template grade conditions after confirmation
        Initialize();

        // [GIVEN] All existing grades are deleted
        ToLoadQltyInspectionGrade.DeleteAll();

        // [GIVEN] A new grade is created
        QltyInspectionUtility.GenerateRandomCharacters(20, GradeCode);
        ToLoadQltyInspectionGrade.Code := CopyStr(GradeCode, 1, MaxStrLen(ToLoadQltyInspectionGrade.Code));
        ToLoadQltyInspectionGrade."Grade Category" := ToLoadQltyInspectionGrade."Grade Category"::Acceptable;
        ToLoadQltyInspectionGrade.Insert();

        // [GIVEN] A template with one field is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.FindFirst();

        // [GIVEN] A grade condition is created for the template
        ToLoadQltyIGradeConditionConf."Condition Type" := ToLoadQltyIGradeConditionConf."Condition Type"::Template;
        ToLoadQltyIGradeConditionConf."Target Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ToLoadQltyIGradeConditionConf."Target Line No." := ConfigurationToLoadQltyInspectionTemplateLine."Line No.";
        ToLoadQltyIGradeConditionConf."Field Code" := ConfigurationToLoadQltyInspectionTemplateLine."Field Code";
        ToLoadQltyIGradeConditionConf."Grade Code" := ToLoadQltyInspectionGrade.Code;
        ToLoadQltyIGradeConditionConf.Insert();

        // [WHEN] Deleting the grade with confirmation
        ToLoadQltyInspectionGrade.Delete(true);

        // [THEN] Grade is successfully deleted
        ToLoadQltyInspectionGrade.SetRange(Code, ToLoadQltyInspectionGrade.Code);
        LibraryAssert.IsTrue(ToLoadQltyInspectionGrade.IsEmpty(), 'Should have deleted grade.')
    end;

    [Test]
    [HandlerFunctions('StrMenuPageHandler')]
    procedure GradeTable_AssistEditGradeStyle()
    var
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        QltyInspectionGradeList: TestPage "Qlty. Inspection Grade List";
        GradeCode: Text;
    begin
        // [SCENARIO] Use AssistEdit to configure grade style on grade list page
        Initialize();

        // [GIVEN] All existing grades are deleted
        if not ToLoadQltyInspectionGrade.IsEmpty() then
            ToLoadQltyInspectionGrade.DeleteAll();
        ToLoadQltyInspectionGrade.DeleteAll();

        // [GIVEN] A new grade is created with StrongAccent style
        QltyInspectionUtility.GenerateRandomCharacters(20, GradeCode);
        ToLoadQltyInspectionGrade.Code := CopyStr(GradeCode, 1, MaxStrLen(ToLoadQltyInspectionGrade.Code));
        ToLoadQltyInspectionGrade."Grade Category" := ToLoadQltyInspectionGrade."Grade Category"::Acceptable;
        ToLoadQltyInspectionGrade."Override Style" := 'StrongAccent';
        ToLoadQltyInspectionGrade.Insert();

        // [GIVEN] Grade list page is opened and navigated to the grade
        QltyInspectionGradeList.OpenEdit();
        QltyInspectionGradeList.GoToRecord(ToLoadQltyInspectionGrade);

        // [WHEN] AssistEdit is invoked on Override Style field
        QltyInspectionGradeList."Override Style".AssistEdit();
        QltyInspectionGradeList.Close();

        // [THEN] Override style is updated to None
        ToLoadQltyInspectionGrade.Get(ToLoadQltyInspectionGrade.Code);
        LibraryAssert.AreEqual('None', ToLoadQltyInspectionGrade."Override Style", 'Override style should be updated.');
    end;

    [Test]
    procedure GradeTable_GetGradeStyle()
    var
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        GradeStyle: Text;
        GradeCode: Text;
    begin
        // [SCENARIO] Get appropriate grade style based on category and override style
        Initialize();

        // [GIVEN] All existing grades are deleted
        ToLoadQltyInspectionGrade.DeleteAll();

        // [GIVEN] A new grade with Acceptable category is created
        QltyInspectionUtility.GenerateRandomCharacters(20, GradeCode);
        ToLoadQltyInspectionGrade.Code := CopyStr(GradeCode, 1, MaxStrLen(ToLoadQltyInspectionGrade.Code));
        ToLoadQltyInspectionGrade."Grade Category" := ToLoadQltyInspectionGrade."Grade Category"::Acceptable;
        ToLoadQltyInspectionGrade.Insert();

        // [WHEN] Getting grade style for Acceptable category
        GradeStyle := ToLoadQltyInspectionGrade.GetGradeStyle();

        // [THEN] Style is Favorable
        LibraryAssert.AreEqual('Favorable', GradeStyle, 'Should have favorable style.');

        // [WHEN] Changing category to Not acceptable
        ToLoadQltyInspectionGrade."Grade Category" := ToLoadQltyInspectionGrade."Grade Category"::"Not acceptable";
        ToLoadQltyInspectionGrade.Modify();

        GradeStyle := ToLoadQltyInspectionGrade.GetGradeStyle();

        // [THEN] Style is Unfavorable
        LibraryAssert.AreEqual('Unfavorable', GradeStyle, 'Should have unfavorable style.');

        // [WHEN] Changing category to Uncategorized
        ToLoadQltyInspectionGrade."Grade Category" := ToLoadQltyInspectionGrade."Grade Category"::Uncategorized;
        ToLoadQltyInspectionGrade.Modify();

        GradeStyle := ToLoadQltyInspectionGrade.GetGradeStyle();

        // [THEN] Style is None
        LibraryAssert.AreEqual('None', GradeStyle, 'Should have no style.');

        // [WHEN] Setting override style to Attention
        ToLoadQltyInspectionGrade."Override Style" := 'Attention';
        ToLoadQltyInspectionGrade.Modify();

        GradeStyle := ToLoadQltyInspectionGrade.GetGradeStyle();

        // [THEN] Override style takes precedence
        LibraryAssert.AreEqual('Attention', GradeStyle, 'Should have override style.');
    end;

    [Test]
    procedure TemplateTable_OnDelete()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [SCENARIO] Template deletion cascades to template lines and generation rules
        Initialize();

        // [GIVEN] A template with one field is created
        QltyInspectionUtility.EnsureSetup();
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A prioritized rule is created for the template
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] Template line is verified to exist
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.FindFirst();

        // [WHEN] Deleting the template header
        ConfigurationToLoadQltyInspectionTemplateHdr.Delete(true);

        // [THEN] Template header is deleted
        ConfigurationToLoadQltyInspectionTemplateHdr.SetRange(Code, ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        LibraryAssert.IsTrue(ConfigurationToLoadQltyInspectionTemplateHdr.IsEmpty(), 'Template should have been deleted.');

        // [THEN] Associated template line is deleted
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        LibraryAssert.IsTrue(ConfigurationToLoadQltyInspectionTemplateLine.IsEmpty(), 'Template line should have been deleted.');

        // [THEN] Associated generation rule is deleted
        QltyInspectionGenRule.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        LibraryAssert.IsTrue(QltyInspectionGenRule.IsEmpty(), 'Generation rule should have been deleted.');
    end;

    [Test]
    procedure TemplateTable_AddFieldToTemplate()
    var
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        FieldToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        DurationTemplateToLoadQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        ToLoadQltyField: Record "Qlty. Field";
        GradeCode: Text;
    begin
        // [SCENARIO] Add field to template creates template line and copies grade conditions
        Initialize();

        // [GIVEN] A grade is created
        QltyInspectionUtility.GenerateRandomCharacters(20, GradeCode);
        ToLoadQltyInspectionGrade.Code := CopyStr(GradeCode, 1, MaxStrLen(ToLoadQltyInspectionGrade.Code));
        ToLoadQltyInspectionGrade."Grade Category" := ToLoadQltyInspectionGrade."Grade Category"::Acceptable;
        ToLoadQltyInspectionGrade.Insert();

        // [GIVEN] A field is created
        ToLoadQltyField.Code := CopyStr(GradeCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField."Field Type" := ToLoadQltyField."Field Type"::"Field Type Integer";
        ToLoadQltyField.Insert();

        // [GIVEN] A grade condition is created for the field
        FieldToLoadQltyIGradeConditionConf."Condition Type" := FieldToLoadQltyIGradeConditionConf."Condition Type"::Field;
        FieldToLoadQltyIGradeConditionConf."Target Code" := ToLoadQltyField.Code;
        FieldToLoadQltyIGradeConditionConf."Field Code" := ToLoadQltyField.Code;
        FieldToLoadQltyIGradeConditionConf."Grade Code" := ToLoadQltyInspectionGrade.Code;
        FieldToLoadQltyIGradeConditionConf.Insert();

        // [GIVEN] An empty template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [WHEN] Adding field to template
        LibraryAssert.IsTrue(ConfigurationToLoadQltyInspectionTemplateHdr.AddFieldToTemplate(ToLoadQltyField.Code), 'Should add template line for field');

        // [THEN] Template line is created with correct field code
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.FindFirst();
        LibraryAssert.AreEqual(ToLoadQltyField.Code, ConfigurationToLoadQltyInspectionTemplateLine."Field Code", 'Should be correct field code.');

        // [THEN] Grade condition is copied to template
        DurationTemplateToLoadQltyIGradeConditionConf.SetRange("Condition Type", DurationTemplateToLoadQltyIGradeConditionConf."Condition Type"::Template);
        DurationTemplateToLoadQltyIGradeConditionConf.SetRange("Target Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        DurationTemplateToLoadQltyIGradeConditionConf.FindFirst();

        // [THEN] Template grade condition has correct field and grade codes
        LibraryAssert.AreEqual(ToLoadQltyField.Code, DurationTemplateToLoadQltyIGradeConditionConf."Field Code", 'Should be correct field code.');
        LibraryAssert.AreEqual(ToLoadQltyInspectionGrade.Code, DurationTemplateToLoadQltyIGradeConditionConf."Grade Code", 'Should be correct grade code.');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(MessageText: Text)
    begin
    end;

    [ModalPageHandler]
    procedure ItemJournalBatchesModalPageHandler(var ItemJournalBatches: TestPage "Item Journal Batches")
    begin
        ItemJournalBatches.First();
        ItemJournalBatches.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure WhseJournalBatchesModalPageHandler(var WhseJournalBatches: TestPage "Whse. Journal Batches")
    begin
        WhseJournalBatches.First();
        WhseJournalBatches.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure WhseWorksheetNamesModalPageHandler(var WhseWorksheetNames: TestPage "Whse. Worksheet Names")
    begin
        WhseWorksheetNames.First();
        WhseWorksheetNames.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure AssistEditTemplatePageHandler(var QltyInspectionTemplateEdit: TestPage "Qlty. Inspection Template Edit")
    begin
        QltyInspectionTemplateEdit.htmlContent.SetValue(AssistEditTemplateValue);
        QltyInspectionTemplateEdit.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EditLargeTextModalPageHandler(var QltyEditLargeText: TestPage "Qlty. Edit Large Text")
    begin
        QltyEditLargeText.HtmlContent.SetValue(TestValueTxt);
        QltyEditLargeText.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingSummaryModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.First();
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingSummaryModalPageHandler_ChooseFromAnyDocument(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        if not NotFirstLoop then begin
            ItemTrackingSummary."Qlty_ChooseFromAnyDocument".Invoke();
            NotFirstLoop := true;
        end else begin
            NotFirstLoop := false;
            ItemTrackingSummary.First();
            ItemTrackingSummary.OK().Invoke();
        end;
    end;

    [ModalPageHandler]
    procedure ItemTrackingSummaryModalPageHandler_ChooseSingleDocument(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        if not NotFirstLoop then begin
            ItemTrackingSummary."Qlty_ChooseSingleDocument".Invoke();
            NotFirstLoop := true;
        end else begin
            NotFirstLoop := false;
            ItemTrackingSummary.First();
            ItemTrackingSummary.OK().Invoke();
        end;
    end;

    [StrMenuHandler]
    procedure StrMenuPageHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 1;
    end;

    [ModalPageHandler]
    procedure CameraModalPageHandler(var Camera: TestPage Camera)
    begin
    end;
}
