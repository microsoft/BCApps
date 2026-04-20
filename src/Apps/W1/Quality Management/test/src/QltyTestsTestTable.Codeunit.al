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
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
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
        ItemIsTrackingErr: Label 'The item [%1] is %2 tracked. Please define a %2 number before finishing the inspection. You can change whether this is required on the Quality Management Setup card.', Comment = '%1=the item number. %2=Item tracking token';
        LotTok: Label 'lot', Locked = true;
        SerialTok: Label 'serial', Locked = true;
        PackageTok: Label 'package', Locked = true;
        ItemInsufficientPostedErr: Label 'The item [%1] is %2 tracked and requires posted inventory before it can be finished. The %2 %3 has inventory of %4. You can change whether this is required on the Quality Management Setup card.', Comment = '%1=the item number. %2=Item tracking token, %3=Item tracking, %4=';
        ItemInsufficientPostedOrUnpostedErr: Label 'The item [%1] is %2 tracked and requires either posted inventory or a reservation entry for it before it can be finished. The %2 %3 has inventory of %4. You can change whether this is required on the Quality Management Setup card.', Comment = '%1=the item number. %2=Item tracking token, %3=Item tracking, %4=';
        MeasurementNoteTxt: Label 'A measurement note for the associated line item.';
        UpdatedMeasurementNoteTxt: Label 'An updated measurement note for the associated line item.';
        OptionsTok: Label 'Option1,Option2,Option3';
        Option1Tok: Label 'Option1';
        NoTok: Label 'No';
        ExistingInspectiontErr: Label 'The test %1 exists on %2 inspections (such as %3 with template %4). The test can not be deleted if it is being used on a Quality Inspection.', Comment = '%1=the test, %2=count of inspections, %3=one example inspection, %4=example template.';
        DescriptionTxt: Label 'Specific Gravity';
        SuggestedCodeTxtTestValueTxt: Label 'SPECIFICGRAVITY';
        Description2Txt: Label '><{}.@!`~''"|\/?&*()-_$#-=,%%:ELECTRICAL CONDUCTIVITY';
        SuggestedCodeTxtTestValue2Txt: Label 'LCTRCLCNDCTVT';
        AllowableValuesExpressionTok: Label '1..99';
        PassConditionExpressionTok: Label '1..5';
        PassConditionDescExpressionTok: Label '1 to 5';
        WarehouseFromTableFilterTok: Label '= %1|= %2', Comment = '%1=warehouse entry,%2=warehouse journal line';
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
        ResultCode1Tok: Label '><{}.@!`~''';
        ResultCode2Tok: Label '"|\/?&*()';
        CannotBeRemovedExistingInspectionErr: Label 'This result cannot be removed because it is being used actively on at least one existing Quality Inspection. If you no longer want to use this result consider changing the description, or consider changing the visibility not to be promoted. You can also change the "Copy" setting on the result.';
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
        QltyInspectionUtility.DetermineControlInformation(QltyInspectionHeader, SourceCustomTok);

        // [WHEN] GetControlCaptionClass is called for Source Custom field
        // [THEN] The method returns "Status" as the caption
        LibraryAssert.AreEqual(StatusTok, QltyInspectionUtility.GetControlCaptionClass(QltyInspectionHeader, SourceCustomTok), 'Should have returned "Status".');

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
        QltyInspectionUtility.DetermineControlInformation(QltyInspectionHeader, SourceCustomTok);

        // [WHEN] GetControlVisibleState is called for Source Custom field
        // [THEN] The method returns true indicating the control should be visible
        LibraryAssert.IsTrue(QltyInspectionUtility.GetControlVisibleState(QltyInspectionHeader, SourceCustomTok), 'Should show Custom 1 (Status).');

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
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.EnsureSetupExists();

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
    procedure Table_ValidateAssignedUserID_CannotChangeInspections()
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
        QltyInspectionUtility.EnsureSetupExists();

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
    procedure Table_ValidateAssignedUserID_CannotChangeInspections_ShouldErr()
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
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.EnsureSetupExists();

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
        LibraryAssert.AreEqual(198, QltyInspectionHeader."Sample Size", 'Sample size should be a rounded up discrete amount based on the input size against the percentage defined on the template.');
    end;

    [Test]
    procedure Table_OnDelete_CanDeleteOpenInspection()
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
        QltyInspectionUtility.EnsureSetupExists();

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
        // [SCENARIO] AssistEditTestField allows editing an inspection test value through a modal page

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template with one test is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] A prioritized rule is created for Purchase Line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase with untracked item
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [GIVEN] The inspection line is retrieved
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.", 10000);

        // [WHEN] AssistEditTest is called on the test code
        QltyInspectionHeader.AssistEditTest(QltyInspectionLine."Test Code");

        // [THEN] The test value is updated through the modal page handler
        QltyInspectionLine.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.", 10000);
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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template with one test is created
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
        QltyInspectionUtility.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '', QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on the Source Lot No. field
        QltyInspection."Source Lot No.".AssistEdit();

        // [THEN] The lot number is changed to the first lot number through modal page handler
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template with one test is created
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
        QltyInspectionUtility.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '', QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on the Source Serial No. field
        QltyInspection."Source Serial No.".AssistEdit();

        // [THEN] The serial number is changed to a different serial number through modal page handler
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template with one test is created
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
        QltyInspectionUtility.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '', QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on the Source Package No. field
        QltyInspection."Source Package No.".AssistEdit();

        // [THEN] The package number is changed to the first package number through modal page handler
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template with one test is created
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
        QltyInspectionUtility.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '', QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on Source Lot No. field (handler chooses from single document)
        QltyInspection."Source Lot No.".AssistEdit();

        // [THEN] The lot number is changed to first lot number from same document
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
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
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '', QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on Source Serial No. field (handler chooses from single document)
        QltyInspection."Source Serial No.".AssistEdit();

        // [THEN] The serial number is changed to a different serial number
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
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
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '', QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on Source Package No. field (handler chooses from single document)
        QltyInspection."Source Package No.".AssistEdit();

        // [THEN] The package number is changed to first package number from same document
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
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
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '', QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on Source Lot No. field (handler chooses from any document)
        QltyInspection."Source Lot No.".AssistEdit();

        // [THEN] The lot number is changed to lot number from different document
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
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
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '', QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on Source Serial No. field (handler chooses from any document)
        QltyInspection."Source Serial No.".AssistEdit();

        // [THEN] The serial number is changed to serial number from different document
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template with one test is created
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
        QltyInspectionUtility.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '', QltyInspectionHeader);

        // [GIVEN] The inspection page is opened
        QltyInspection.OpenEdit();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssistEdit is invoked on Source Package No. field (handler chooses from any document)
        QltyInspection."Source Package No.".AssistEdit();

        // [THEN] The package number is changed to first package number from different document
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
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
        QltyInspectionUtility.EnsureSetupExists();

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
        asserterror QltyInspectionUtility.VerifyTrackingBeforeFinish(QltyInspectionHeader);
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
        QltyInspectionUtility.EnsureSetupExists();

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
        asserterror QltyInspectionUtility.VerifyTrackingBeforeFinish(QltyInspectionHeader);

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
        QltyInspectionUtility.EnsureSetupExists();

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
        asserterror QltyInspectionUtility.VerifyTrackingBeforeFinish(QltyInspectionHeader);

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
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        // [SCENARIO] Verify error when lot-tracked item has unposted lot number before finish

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '', QltyInspectionHeader);

        // [GIVEN] Quality setup requires only posted item tracking
        QltyManagementSetup.Get();
        QltyManagementSetup."Item Tracking Before Finishing" := QltyManagementSetup."Item Tracking Before Finishing"::"Allow only posted Item Tracking";
        QltyManagementSetup.Modify();

        // [WHEN] VerifyTrackingBeforeFinish is called
        asserterror QltyInspectionUtility.VerifyTrackingBeforeFinish(QltyInspectionHeader);

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
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        // [SCENARIO] Verify error when serial-tracked item has unposted serial number before finish

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '', QltyInspectionHeader);

        // [GIVEN] Quality setup requires only posted item tracking
        QltyManagementSetup.Get();
        QltyManagementSetup."Item Tracking Before Finishing" := QltyManagementSetup."Item Tracking Before Finishing"::"Allow only posted Item Tracking";
        QltyManagementSetup.Modify();

        // [WHEN] VerifyTrackingBeforeFinish is called
        asserterror QltyInspectionUtility.VerifyTrackingBeforeFinish(QltyInspectionHeader);

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
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        RecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
    begin
        // [SCENARIO] Verify error when package-tracked item has unposted package number before finish

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '', QltyInspectionHeader);

        // [GIVEN] Quality setup requires only posted item tracking
        QltyManagementSetup.Get();
        QltyManagementSetup."Item Tracking Before Finishing" := QltyManagementSetup."Item Tracking Before Finishing"::"Allow only posted Item Tracking";
        QltyManagementSetup.Modify();

        // [WHEN] VerifyTrackingBeforeFinish is called
        asserterror QltyInspectionUtility.VerifyTrackingBeforeFinish(QltyInspectionHeader);

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
        QltyInspectionUtility.EnsureSetupExists();

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
        asserterror QltyInspectionUtility.VerifyTrackingBeforeFinish(QltyInspectionHeader);

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
        QltyInspectionUtility.EnsureSetupExists();

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
        asserterror QltyInspectionUtility.VerifyTrackingBeforeFinish(QltyInspectionHeader);

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
        QltyInspectionUtility.EnsureSetupExists();

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
        asserterror QltyInspectionUtility.VerifyTrackingBeforeFinish(QltyInspectionHeader);

        // [THEN] Error is thrown indicating insufficient reserved or posted package quantity
        LibraryAssert.ExpectedError(StrSubstNo(ItemInsufficientPostedOrUnpostedErr, QltyInspectionHeader."Source Item No.", PackageTok, QltyInspectionHeader."Source Package No.", 0));
    end;

    [Test]
    procedure Table_InspectionAssignSelfOnModify()
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
        // [SCENARIO] Inspection is automatically assigned to current user on modification

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A generation rule is created for purchase lines
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase with no assigned user
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [GIVEN] Inspection has no assigned user initially
        LibraryAssert.AreEqual('', QltyInspectionHeader."Assigned User ID", 'Should not have assigned user.');

        // [WHEN] Inspection is modified by changing source quantity
        QltyInspectionHeader."Source Quantity (Base)" := 99;
        QltyInspectionHeader.Modify(true);

        // [THEN] Inspection is automatically assigned to current user
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A generation rule is created for purchase lines
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from a purchase line
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [WHEN] GetReferenceRecordId is called
        // [THEN] The purchase line's SystemId is returned
        LibraryAssert.AreEqual(PurchaseLine.SystemId, QltyInspectionUtility.GetReferenceRecordId(QltyInspectionHeader), 'Should be the same record id.');
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
        QltyInspectionUtility.EnsureSetupExists();

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
        LibraryAssert.AreEqual(PurchaseLine.SystemId, QltyInspectionUtility.GetReferenceRecordId(QltyInspectionHeader), 'Should be the same record id.');
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
        QltyInspectionUtility.EnsureSetupExists();

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
        LibraryAssert.AreEqual(PurchaseLine.SystemId, QltyInspectionUtility.GetReferenceRecordId(QltyInspectionHeader), 'Should be the same record id.');
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
        QltyInspectionUtility.EnsureSetupExists();

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
        LibraryAssert.AreEqual(PurchaseLine.SystemId, QltyInspectionUtility.GetReferenceRecordId(QltyInspectionHeader), 'Should be the same record id.');
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
        QltyInspectionUtility.EnsureSetupExists();

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
        LibraryAssert.AreEqual(PurchaseLine.SystemId, QltyInspectionUtility.GetReferenceRecordId(QltyInspectionHeader), 'Should be the same record id.');
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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] Additional picture handling is set to save as attachment
        QltyManagementSetup.Get();
        QltyManagementSetup."Additional Picture Handling" := QltyManagementSetup."Additional Picture Handling"::"Save as attachment";
        QltyManagementSetup.Modify();

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, ConfigurationToLoadQltyInspectionTemplateHdr);

        // [GIVEN] Current document attachment count is recorded
        BeforeCount := DocumentAttachment.Count();

        // [GIVEN] Camera test library is subscribed
        BindSubscription(CameraTestLibrary);

        // [GIVEN] Inspection page is opened and positioned on the inspection
        QltyInspection.OpenView();
        QltyInspection.GoToRecord(QltyInspectionHeader);

        // [WHEN] TakePicture action is invoked
        QltyInspection.TakePicture.Invoke();

        // [GIVEN] Camera test library is unsubscribed
        UnbindSubscription(CameraTestLibrary);

        // [THEN] Inspection header now has a most recent picture
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        LibraryAssert.IsTrue(QltyInspectionHeader."Most Recent Picture".HasValue(), 'Should have added picture.');

        // [THEN] A new document attachment is created
        LibraryAssert.AreEqual(BeforeCount + 1, DocumentAttachment.Count(), 'Should have added document attachment.');

        // [THEN] Document attachment file name contains inspection number
        DocumentAttachment.SetRange("Table ID", Database::"Qlty. Inspection Header");
        DocumentAttachment.FindLast();
        LibraryAssert.IsTrue(DocumentAttachment."File Name".Contains(QltyInspectionHeader."No."), 'File name should have inspection no.');
    end;

    [Test]
    procedure Table_SetRecordFiltersToFindInspectionFor_ItemFilter()
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
        // [SCENARIO] SetRecordFiltersToFindInspectionFor applies item number filter

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template and generation rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location and item are created
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A purchase order is created with the item
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine);

        // [WHEN] SetRecordFiltersToFindInspectionFor is called with purchase line (useItem=true)
        QltyInspectionHeader.SetRecordFiltersToFindInspectionFor(true, PurchaseLine, true, false, false);

        // [THEN] Filter includes the item number
        RecordRef.GetTable(QltyInspectionHeader);
        Filter := RecordRef.GetFilters();
        LibraryAssert.IsTrue(Filter.Contains(Item."No."), 'Should have filter for item no.');
    end;

    [Test]
    procedure Table_SetRecordFiltersToFindInspectionFor_LotTrackingFilter()
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
        // [SCENARIO] SetRecordFiltersToFindInspectionFor applies lot number filter

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

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

        // [WHEN] SetRecordFiltersToFindInspectionFor is called with tracking (useItemTracking=true)
        QltyInspectionHeader.SetRecordFiltersToFindInspectionFor(true, TempSpecTrackingSpecification, false, true, false);

        // [THEN] Filter includes the lot number
        RecordRef.GetTable(QltyInspectionHeader);
        Filter := RecordRef.GetFilters();
        LibraryAssert.IsTrue(Filter.Contains(ReservationEntry."Lot No."), 'Should have filter for lot no.');
    end;

    [Test]
    procedure Table_SetRecordFiltersToFindInspectionFor_SourceDocumentFilter()
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
        // [SCENARIO] SetRecordFiltersToFindInspectionFor applies source document number filter

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template and generation rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] A lot-tracked item with no series is created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

        // [GIVEN] A purchase order is created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);

        // [WHEN] SetRecordFiltersToFindInspectionFor is called with purchase line (useSourceDocument=true)
        QltyInspectionHeader.SetRecordFiltersToFindInspectionFor(true, PurchaseLine, false, false, true);

        // [THEN] Filter includes the source document number
        RecordRef.GetTable(QltyInspectionHeader);
        Filter := RecordRef.GetFilters();
        LibraryAssert.IsTrue(Filter.Contains(PurchaseHeader."No."), 'Should have filter for source document no.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure InspectionPage_FinishInspection()
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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template and generation rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase with Open status
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 10, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [GIVEN] Inspection list page is opened and positioned on the inspection
        QltyInspectionList.OpenView();
        QltyInspectionList.GoToRecord(QltyInspectionHeader);

        // [WHEN] ChangeStatusFinish action is invoked (ConfirmHandler confirms)
        QltyInspectionList.ChangeStatusFinish.Invoke();

        // [THEN] Inspection status is changed to Finished
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        LibraryAssert.IsTrue(QltyInspectionHeader.Status = QltyInspectionHeader.Status::Finished, 'Inspection should be finished.');

        // [GIVEN] Cleanup generation rule
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure InspectionPage_ReopenInspection()
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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template and generation rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 10, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [GIVEN] Inspection status is set to Finished
        QltyInspectionHeader.Status := QltyInspectionHeader.Status::Finished;
        QltyInspectionHeader.Modify();

        // [GIVEN] Inspection list page is opened and positioned on the inspection
        QltyInspectionList.OpenView();
        QltyInspectionList.GoToRecord(QltyInspectionHeader);

        // [WHEN] ChangeStatusReopen action is invoked (ConfirmHandler confirms)
        QltyInspectionList.ChangeStatusReopen.Invoke();

        // [THEN] Inspection status is changed to Open
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        LibraryAssert.IsTrue(QltyInspectionHeader.Status = QltyInspectionHeader.Status::Open, 'Inspection should be open.');

        // [GIVEN] Cleanup generation rule
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure InspectionPage_PickupInspection()
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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template and generation rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase with no assigned user
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 10, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [GIVEN] Inspection list page is opened and positioned on the inspection
        QltyInspectionList.OpenView();
        QltyInspectionList.GoToRecord(QltyInspectionHeader);

        // [WHEN] AssignToSelf action is invoked
        QltyInspectionList.AssignToSelf.Invoke();

        // [THEN] Inspection is assigned to current user
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        LibraryAssert.IsTrue(QltyInspectionHeader."Assigned User ID" = UserId(), 'Inspection should be assigned to user.');

        // [GIVEN] Cleanup generation rule
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure InspectionPage_UnassignInspection()
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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template and generation rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A location is created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] An inspection is created from purchase
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 10, PurchaseHeader, PurchaseLine, QltyInspectionHeader);

        // [GIVEN] Inspection is assigned to current user
        QltyInspectionHeader."Assigned User ID" := CopyStr(UserId(), 1, MaxStrLen(QltyInspectionHeader."Assigned User ID"));
        QltyInspectionHeader.Modify();

        // [GIVEN] Inspection list page is opened and positioned on the inspection
        QltyInspectionList.OpenView();
        QltyInspectionList.GoToRecord(QltyInspectionHeader);

        // [WHEN] Unassign action is invoked
        QltyInspectionList.Unassign.Invoke();

        // [THEN] Inspection assigned user is cleared
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        LibraryAssert.IsTrue(QltyInspectionHeader."Assigned User ID" = '', 'Inspection should not be assigned to a user.');

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
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
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
    procedure TestTable_AssistEditDefaultValue_Option()
    var
        ToLoadQltyTest: Record "Qlty. Test";
    begin
        // [SCENARIO] AssistEditDefaultValue for Option test value type opens option menu

        Initialize();

        // [GIVEN] A test record is initialized
        ToLoadQltyTest.Init();

        // [GIVEN] Test value type is set to Option
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Option");

        // [GIVEN] Allowable values are set
        ToLoadQltyTest.Validate("Allowable Values", OptionsTok);

        // [WHEN] AssistEditDefaultValue is called (StrMenuPageHandler selects first option)
        ToLoadQltyTest.AssistEditDefaultValue();

        // [THEN] Default value is set to selected option
        LibraryAssert.AreEqual(Option1Tok, ToLoadQltyTest."Default Value", 'Should be selected option.');
    end;

    [Test]
    [HandlerFunctions('StrMenuPageHandler')]
    procedure TestTable_AssistEditDefaultValue_Boolean()
    var
        ToLoadQltyTest: Record "Qlty. Test";
    begin
        // [SCENARIO] AssistEditDefaultValue for Boolean test value type opens Yes/No menu

        Initialize();

        // [GIVEN] A test record is initialized
        ToLoadQltyTest.Init();

        // [GIVEN] Test value type is set to Boolean
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Boolean");

        // [WHEN] AssistEditDefaultValue is called (StrMenuPageHandler selects first option: No)
        ToLoadQltyTest.AssistEditDefaultValue();

        // [THEN] Default value is set to No
        LibraryAssert.AreEqual(NoTok, ToLoadQltyTest."Default Value", 'Should be no.')
    end;

    [Test]
    [HandlerFunctions('EditLargeTextModalPageHandler')]
    procedure TestTable_AssistEditDefaultValue_Text()
    var
        ToLoadQltyTest: Record "Qlty. Test";
    begin
        // [SCENARIO] AssistEditDefaultValue for Text test value type opens text editor modal

        Initialize();

        // [GIVEN] A test record is initialized
        ToLoadQltyTest.Init();

        // [GIVEN] Test value type is set to Text
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Text");

        // [WHEN] AssistEditDefaultValue is called (EditLargeTextModalPageHandler enters TestValueTxt)
        ToLoadQltyTest.AssistEditDefaultValue();

        // [THEN] Default value is set to entered text
        LibraryAssert.AreEqual(TestValueTxt, ToLoadQltyTest."Default Value", 'Should be same text.')
    end;

    [Test]
    procedure TestTable_OnDelete_ShouldError()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        // [SCENARIO] Deleting test used in template lines should error

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template with 2 tests is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 2);

        // [GIVEN] First template line is retrieved
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.FindFirst();

        // [GIVEN] Test from template line is retrieved
        ToLoadQltyTest.Get(ConfigurationToLoadQltyInspectionTemplateLine."Test Code");

        // [GIVEN] Sanity checks: test exists and template has two lines
        LibraryAssert.IsTrue(ToLoadQltyTest.Get(ConfigurationToLoadQltyInspectionTemplateLine."Test Code"), 'Sanity check, the test should exist before deleting.');
        LibraryAssert.AreEqual(2, ConfigurationToLoadQltyInspectionTemplateLine.Count(), 'Sanity check, should be starting with two lines.');

        // [GIVEN] Changes are committed
        Commit();

        // [WHEN] Delete is attempted on test
        asserterror ToLoadQltyTest.Delete(true);

        // [THEN] Test still exists after failed delete attempt
        LibraryAssert.IsTrue(ToLoadQltyTest.Get(ConfigurationToLoadQltyInspectionTemplateLine."Test Code"), 'The test should still exist after a delete attempt, which should have failed.');
        // [THEN] Template lines are retained
        ConfigurationToLoadQltyInspectionTemplateLine.Reset();
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(2, ConfigurationToLoadQltyInspectionTemplateLine.Count(), 'Should have retained the template line.');

        // [THEN] Test record is retained
        ToLoadQltyTest.SetRecFilter();
        LibraryAssert.AreEqual(1, ToLoadQltyTest.Count(), 'Should have retained the test.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestTable_CheckDeleteConstraints_ShouldConfirmAndDelete()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        // [SCENARIO] CheckDeleteConstraints with confirm removes template lines but not the test

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template with 2 tests is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 2);

        // [GIVEN] First template line is retrieved
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.FindFirst();

        // [GIVEN] Test from template line is retrieved
        ToLoadQltyTest.Get(ConfigurationToLoadQltyInspectionTemplateLine."Test Code");

        // [WHEN] CheckDeleteConstraints is called with confirm=true (ConfirmHandler confirms)
        ToLoadQltyTest.CheckDeleteConstraints(true);

        // [GIVEN] Test record filter is set
        ToLoadQltyTest.SetRecFilter();

        // [THEN] Template line is deleted
        Clear(ConfigurationToLoadQltyInspectionTemplateLine);
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        LibraryAssert.AreEqual(1, ConfigurationToLoadQltyInspectionTemplateLine.Count(), 'Should have deleted template line.');

        // [THEN] Test still exists (CheckDeleteConstraints only removes dependencies)
        LibraryAssert.AreEqual(1, ToLoadQltyTest.Count(), 'Should have not deleted the test with just CheckDeleteConstraints(true).');
    end;

    [Test]
    procedure TestTable_OnDelete_HasExistingInspections_ShouldError()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
    begin
        // [SCENARIO] Deleting test with existing inspection lines should error with specific message

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template with 1 test is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] Template line is retrieved
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.FindFirst();

        // [GIVEN] An inspection header is created from the template
        QltyInspectionHeader.Init();
        QltyInspectionHeader.Validate("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        QltyInspectionHeader.Insert(true);

        // [GIVEN] Test from template line is retrieved
        ToLoadQltyTest.Get(ConfigurationToLoadQltyInspectionTemplateLine."Test Code");

        // [GIVEN] An inspection line using the test is created
        QltyInspectionLine.Init();
        QltyInspectionLine.Validate("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.Validate("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionLine."Line No." := ConfigurationToLoadQltyInspectionTemplateLine."Line No.";
        QltyInspectionLine."Template Code" := ConfigurationToLoadQltyInspectionTemplateLine."Template Code";
        QltyInspectionLine."Template Line No." := ConfigurationToLoadQltyInspectionTemplateLine."Line No.";
        QltyInspectionLine.Validate("Test Code", ToLoadQltyTest.Code);
        QltyInspectionLine.Insert();

        // [WHEN] Delete is attempted on test
        asserterror ToLoadQltyTest.Delete(true);

        // [THEN] Specific error message is shown with inspection details
        LibraryAssert.ExpectedError(StrSubstNo(
            ExistingInspectiontErr,
            QltyInspectionLine."Test Code",
            1,
            QltyInspectionHeader."No.",
            QltyInspectionHeader."Template Code"));
    end;

    [Test]
    procedure TestTable_SuggestTestCodeFromDescription()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        TestCode: Code[20];
    begin
        // [SCENARIO] SuggestUnusedTestCodeFromDescription generates code from description

        Initialize();

        // [GIVEN] Existing tests with description are deleted
        ToLoadQltyTest.SetRange(Description, DescriptionTxt);
        if not ToLoadQltyTest.IsEmpty() then
            ToLoadQltyTest.DeleteAll();

        // [WHEN] SuggestUnusedTestCodeFromDescription is called with description
        QltyInspectionUtility.SuggestUnusedTestCodeFromDescription(ToLoadQltyTest, DescriptionTxt, TestCode);

        // [THEN] Suggested code matches expected value
        LibraryAssert.AreEqual(SuggestedCodeTxtTestValueTxt, TestCode, 'Suggested code should match');
    end;

    [Test]
    procedure TestTable_SuggestTestCodeFromDescription_NoSpecialChar()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        TestCode: Code[20];
    begin
        // [SCENARIO] SuggestUnusedTestCodeFromDescription handles description with no special characters

        Initialize();

        // [GIVEN] Existing tests with description are deleted
        ToLoadQltyTest.SetRange(Description, DescriptionTxt);
        if not ToLoadQltyTest.IsEmpty() then
            ToLoadQltyTest.DeleteAll();

        // [WHEN] SuggestUnusedTestCodeFromDescription is called with description
        QltyInspectionUtility.SuggestUnusedTestCodeFromDescription(ToLoadQltyTest, DescriptionTxt, TestCode);

        // [THEN] Suggested code matches expected value
        LibraryAssert.AreEqual(SuggestedCodeTxtTestValueTxt, TestCode, 'Suggested code should match');
    end;

    [Test]
    procedure TestTable_SuggestTestCodeFromDescription_LongWithSpecialChar()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        TestCode: Code[20];
    begin
        // [SCENARIO] SuggestUnusedTestCodeFromDescription handles long description with special characters

        Initialize();

        // [GIVEN] Existing tests with description are deleted
        ToLoadQltyTest.SetRange(Description, Description2Txt);
        if not ToLoadQltyTest.IsEmpty() then
            ToLoadQltyTest.DeleteAll();

        // [WHEN] SuggestUnusedTestCodeFromDescription is called with long description with special characters
        QltyInspectionUtility.SuggestUnusedTestCodeFromDescription(ToLoadQltyTest, Description2Txt, TestCode);

        // [THEN] Suggested code matches expected value (truncated and sanitized)
        LibraryAssert.AreEqual(SuggestedCodeTxtTestValue2Txt, TestCode, 'Suggested code should match');
    end;

    [Test]
    procedure TestTable_SuggestTestCodeFromDescription_PreexistingTest()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        TestCode: Code[20];
    begin
        // [SCENARIO] SuggestUnusedTestCodeFromDescription increments code when test already exists

        Initialize();

        // [GIVEN] Existing tests with description are cleaned up to have only one
        ToLoadQltyTest.SetRange(Description, DescriptionTxt);
        if ToLoadQltyTest.Count() > 1 then
            ToLoadQltyTest.DeleteAll();

        // [GIVEN] A test with the suggested code already exists
        if ToLoadQltyTest.IsEmpty() then begin
            ToLoadQltyTest.Init();
            ToLoadQltyTest.Validate(Code, SuggestedCodeTxtTestValueTxt);
            ToLoadQltyTest.Validate(Description, DescriptionTxt);
            ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Decimal");
            ToLoadQltyTest.Insert();

            // [WHEN] SuggestUnusedTestCodeFromDescription is called
            QltyInspectionUtility.SuggestUnusedTestCodeFromDescription(ToLoadQltyTest, DescriptionTxt, TestCode);

            // [THEN] Suggested code is incremented with suffix
            LibraryAssert.AreEqual(SuggestedCodeTxtTestValueTxt + '0002', TestCode, 'Suggested code should match');
        end;
    end;

    [Test]
    [HandlerFunctions('AssistEditTemplatePageHandler')]
    procedure TestTable_AssistEditAllowableValues()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        TestCodeTxt: Text;
    begin
        // [SCENARIO] AssistEditAllowableValues opens modal to edit allowable values

        Initialize();

        // [GIVEN] A random test code is generated
        QltyInspectionUtility.GenerateRandomCharacters(20, TestCodeTxt);

        // [GIVEN] A test is created
        ToLoadQltyTest.Init();
        ToLoadQltyTest.Validate(Code, CopyStr(TestCodeTxt, 1, MaxStrLen(ToLoadQltyTest.Code)));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Decimal");
        ToLoadQltyTest.Insert();

        // [GIVEN] Handler will enter allowable values expression
        AssistEditTemplateValue := AllowableValuesExpressionTok;

        // [WHEN] AssistEditAllowableValues is called (handler enters value)
        ToLoadQltyTest.AssistEditAllowableValues();

        // [THEN] Allowable values are updated
        LibraryAssert.AreEqual(AllowableValuesExpressionTok, ToLoadQltyTest."Allowable Values", 'Allowable values should match');
    end;

    [Test]
    [HandlerFunctions('AssistEditTemplatePageHandler')]
    procedure TestCardPage_UpdatePassConditionAndDescription()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyTestCard: TestPage "Qlty. Test Card";
        TestCodeTxt: Text;
    begin
        // [SCENARIO] Test card page updates pass condition and description via AssistEdit

        Initialize();

        // [GIVEN] Existing results are deleted
        if not ToLoadQltyInspectionResult.IsEmpty() then
            ToLoadQltyInspectionResult.DeleteAll();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A random test code is generated
        QltyInspectionUtility.GenerateRandomCharacters(20, TestCodeTxt);

        // [GIVEN] A test is created
        ToLoadQltyTest.Init();
        ToLoadQltyTest.Validate(Code, CopyStr(TestCodeTxt, 1, MaxStrLen(ToLoadQltyTest.Code)));
        ToLoadQltyTest.Validate("Test Value Type", ToLoadQltyTest."Test Value Type"::"Value Type Decimal");
        ToLoadQltyTest.Insert();

        // [GIVEN] Test card page is opened for the test
        QltyTestCard.OpenEdit();
        QltyTestCard.GoToRecord(ToLoadQltyTest);

        // [GIVEN] Handler will enter pass condition expression
        AssistEditTemplateValue := PassConditionExpressionTok;

        // [WHEN] Pass condition AssistEdit is invoked
        QltyTestCard.Field1.AssistEdit();

        // [GIVEN] Handler will enter pass condition description
        AssistEditTemplateValue := PassConditionDescExpressionTok;

        // [WHEN] Pass condition description AssistEdit is invoked
        QltyTestCard.Field1_Desc.AssistEdit();

        // [GIVEN] Default pass result is retrieved
        ToLoadQltyInspectionResult.Get(QltyInspectionUtility.GetDefaultPassResult());

        // [GIVEN] Result condition configuration for test is retrieved
        ToLoadQltyIResultConditConf.SetRange("Test Code", ToLoadQltyTest.Code);
        ToLoadQltyIResultConditConf.SetRange("Target Code", ToLoadQltyTest.Code);
        ToLoadQltyIResultConditConf.SetRange("Result Code", ToLoadQltyInspectionResult.Code);
        ToLoadQltyIResultConditConf.SetRange("Condition Type", ToLoadQltyIResultConditConf."Condition Type"::Test);
        ToLoadQltyIResultConditConf.FindFirst();

        // [THEN] Condition is updated
        LibraryAssert.AreEqual(PassConditionExpressionTok, ToLoadQltyIResultConditConf.Condition, 'Should be same condition.');

        // [THEN] Condition description is updated
        LibraryAssert.AreEqual(PassConditionDescExpressionTok, ToLoadQltyIResultConditConf."Condition Description", 'Should be same description.')
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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] Three production-related rules are created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Line");
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Production Order");

        // [GIVEN] Production rules with OnProductionOrderRelease trigger are filtered
        QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::Production);
        QltyInspectionGenRule.SetRange("Production Order Trigger", QltyInspectionGenRule."Production Order Trigger"::OnProductionOrderRelease);
        LibraryAssert.IsTrue(QltyInspectionGenRule.IsEmpty(), 'Should be no rules with trigger.');

        // [GIVEN] Setup is updated to OnProductionOrderRelease trigger
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Production Order Trigger", QltyManagementSetup."Production Order Trigger"::OnProductionOrderRelease);
        QltyManagementSetup.Modify();

        // [GIVEN] Rules with OnProductionOrderRelease trigger are verified as still empty
        QltyInspectionGenRule.SetRange("Production Order Trigger", QltyInspectionGenRule."Production Order Trigger"::OnProductionOrderRelease);
        LibraryAssert.IsTrue(QltyInspectionGenRule.IsEmpty(), 'Should be no rules with trigger.');

        // [GIVEN] A new production rule is created
        Clear(QltyInspectionGenRule);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);

        // [GIVEN] Source table is changed to Prod. Order Line
        QltyInspectionGenRule.Validate("Source Table No.", Database::"Prod. Order Line");
        QltyInspectionGenRule.Modify();
        LibraryAssert.IsTrue(QltyInspectionGenRule."Production Order Trigger" = QltyInspectionGenRule."Production Order Trigger"::OnProductionOrderRelease, 'Should have default trigger.');

        // [WHEN] Setup production order trigger is changed to OnProductionOutputPost
        QltyManagementSetup.Validate("Production Order Trigger", QltyManagementSetup."Production Order Trigger"::OnProductionOutputPost);
        QltyManagementSetup.Modify();

        // [THEN] Existing production rule is updated to new trigger
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.SetRange("Production Order Trigger", QltyInspectionGenRule."Production Order Trigger"::OnProductionOutputPost);
        LibraryAssert.AreEqual(1, QltyInspectionGenRule.Count(), 'Production rule should have new production order trigger.');
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
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.EnsureSetupExists();

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

        // [WHEN] Item Reclass. Batch Name lookup is invoked
        QltyManagementSetupPage."Item Reclass. Batch Name".Lookup();
        QltyManagementSetupPage.Close();

        // [THEN] Setup is updated with selected batch name
        QltyManagementSetup.Get();
        LibraryAssert.AreEqual(ItemJournalBatch.Name, QltyManagementSetup."Item Reclass. Batch Name", 'Should be same batch name.');

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
        QltyInspectionUtility.EnsureSetupExists();

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

        // [WHEN] Whse. Reclass. Batch Name lookup is invoked
        QltyManagementSetupPage."Whse. Reclass. Batch Name".Lookup();
        QltyManagementSetupPage.Close();

        // [THEN] Setup is updated with selected batch name
        QltyManagementSetup.Get();
        LibraryAssert.AreEqual(WhseWarehouseJournalBatch.Name, QltyManagementSetup."Whse. Reclass. Batch Name", 'Should be same batch name.');

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
        QltyInspectionUtility.EnsureSetupExists();

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

        // [WHEN] Movement Worksheet Name lookup is invoked
        QltyManagementSetupPage."Movement Worksheet Name".Lookup();
        QltyManagementSetupPage.Close();

        // [THEN] Setup is updated with selected worksheet name
        QltyManagementSetup.Get();
        LibraryAssert.AreEqual(WhseWorksheetName.Name, QltyManagementSetup."Movement Worksheet Name", 'Should be same name.');

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
        QltyInspectionUtility.EnsureSetupExists();

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

        // [WHEN] Item Item Journal Batch Name lookup is invoked
        QltyManagementSetupPage."Item Item Journal Batch Name".Lookup();
        QltyManagementSetupPage.Close();

        // [THEN] Setup is updated with selected batch name
        QltyManagementSetup.Get();
        LibraryAssert.AreEqual(ItemJournalBatch.Name, QltyManagementSetup."Item Journal Batch Name", 'Should be same batch name.');

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
        QltyInspectionUtility.EnsureSetupExists();

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

        // [WHEN] Whse. Item Journal Batch Name lookup is invoked
        QltyManagementSetupPage."Whse. Item Journal Batch Name".Lookup();
        QltyManagementSetupPage.Close();

        // [THEN] Setup is updated with selected batch name
        QltyManagementSetup.Get();
        LibraryAssert.AreEqual(WhseWarehouseJournalBatch.Name, QltyManagementSetup."Whse. Item Journal Batch Name", 'Should be same batch name.');

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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A warehouse receipt line rule is created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Warehouse Receipt Line", QltyInspectionGenRule);
        LibraryAssert.IsTrue(QltyInspectionGenRule."Warehouse Receipt Trigger" = QltyInspectionGenRule."Warehouse Receipt Trigger"::NoTrigger, 'Should not have trigger.');

        // [GIVEN] Setup is updated to OnWarehouseReceiptCreate trigger
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Warehouse Receipt Trigger", QltyManagementSetup."Warehouse Receipt Trigger"::OnWarehouseReceiptCreate);
        QltyManagementSetup.Modify();

        // [GIVEN] Existing rule is retrieved and still has NoTrigger
        QltyInspectionGenRule.Get(QltyInspectionGenRule."Entry No.");
        LibraryAssert.IsTrue(QltyInspectionGenRule."Warehouse Receipt Trigger" = QltyInspectionGenRule."Warehouse Receipt Trigger"::NoTrigger, 'Should not have trigger.');

        // [GIVEN] A new rule is created for different source table
        Clear(QltyInspectionGenRule);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);

        // [GIVEN] Source table is changed to Warehouse Receipt Line
        QltyInspectionGenRule.Validate("Source Table No.", Database::"Warehouse Receipt Line");
        QltyInspectionGenRule.Modify();
        LibraryAssert.IsTrue(QltyInspectionGenRule."Warehouse Receipt Trigger" = QltyInspectionGenRule."Warehouse Receipt Trigger"::OnWarehouseReceiptCreate, 'Should have default trigger.');

        // [WHEN] Setup trigger is changed to OnWarehouseReceiptPost
        QltyManagementSetup.Validate("Warehouse Receipt Trigger", QltyManagementSetup."Warehouse Receipt Trigger"::OnWarehouseReceiptPost);
        QltyManagementSetup.Modify();

        // [THEN] Existing warehouse receipt rule is updated to new trigger
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.SetRange("Warehouse Receipt Trigger", QltyInspectionGenRule."Warehouse Receipt Trigger"::OnWarehouseReceiptPost);
        LibraryAssert.AreEqual(1, QltyInspectionGenRule.Count(), 'Production rule should have new production order trigger value.');

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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A purchase line rule is created with no trigger
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);
        LibraryAssert.IsTrue(QltyInspectionGenRule."Purchase Order Trigger" = QltyInspectionGenRule."Purchase Order Trigger"::NoTrigger, 'Should not have trigger.');

        // [GIVEN] Setup Purchase Order Trigger is set to OnPurchaseOrderPostReceive
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Purchase Order Trigger", QltyManagementSetup."Purchase Order Trigger"::OnPurchaseOrderPostReceive);
        QltyManagementSetup.Modify();

        // [GIVEN] Existing rule still has NoTrigger
        QltyInspectionGenRule.Get(QltyInspectionGenRule."Entry No.");
        LibraryAssert.IsTrue(QltyInspectionGenRule."Purchase Order Trigger" = QltyInspectionGenRule."Purchase Order Trigger"::NoTrigger, 'Should not have trigger.');

        // [GIVEN] A new rule is created for different source table
        Clear(QltyInspectionGenRule);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);

        // [GIVEN] Source table is changed to Purchase Line
        QltyInspectionGenRule.Validate("Source Table No.", Database::"Purchase Line");
        QltyInspectionGenRule.Modify();
        LibraryAssert.IsTrue(QltyInspectionGenRule."Purchase Order Trigger" = QltyInspectionGenRule."Purchase Order Trigger"::OnPurchaseOrderPostReceive, 'Should have default trigger.');

        // [WHEN] Setup trigger is changed to NoTrigger
        QltyManagementSetup.Validate("Purchase Order Trigger", QltyManagementSetup."Purchase Order Trigger"::NoTrigger);
        QltyManagementSetup.Modify();

        // [THEN] All purchase rules have trigger removed
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.SetRange("Purchase Order Trigger", QltyInspectionGenRule."Purchase Order Trigger"::NoTrigger);
        LibraryAssert.AreEqual(2, QltyInspectionGenRule.Count(), 'Purchase rule should have new Purchase Order Trigger value.');

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
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A transfer line rule is created with no trigger
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Transfer Line", QltyInspectionGenRule);
        LibraryAssert.IsTrue(QltyInspectionGenRule."Transfer Order Trigger" = QltyInspectionGenRule."Transfer Order Trigger"::NoTrigger, 'Should not have trigger.');

        // [GIVEN] Setup transfer order trigger is set to OnTransferOrderPostReceive
        QltyManagementSetup.Get();
        QltyManagementSetup.Validate("Transfer Order Trigger", QltyManagementSetup."Transfer Order Trigger"::OnTransferOrderPostReceive);
        QltyManagementSetup.Modify();

        // [GIVEN] Existing rule still has NoTrigger
        QltyInspectionGenRule.Get(QltyInspectionGenRule."Entry No.");
        LibraryAssert.IsTrue(QltyInspectionGenRule."Transfer Order Trigger" = QltyInspectionGenRule."Transfer Order Trigger"::NoTrigger, 'Should not have trigger.');

        // [GIVEN] A new rule is created for different source table
        Clear(QltyInspectionGenRule);
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);

        // [GIVEN] Source table is changed to Transfer Line
        QltyInspectionGenRule.Validate("Source Table No.", Database::"Transfer Line");
        QltyInspectionGenRule.Modify();
        LibraryAssert.IsTrue(QltyInspectionGenRule."Transfer Order Trigger" = QltyInspectionGenRule."Transfer Order Trigger"::OnTransferOrderPostReceive, 'Should have default trigger.');

        // [WHEN] Setup trigger is changed to NoTrigger
        QltyManagementSetup.Validate("Transfer Order Trigger", QltyManagementSetup."Transfer Order Trigger"::NoTrigger);
        QltyManagementSetup.Modify();

        // [THEN] All transfer rules have trigger removed
        QltyInspectionGenRule.Reset();
        QltyInspectionGenRule.SetRange("Transfer Order Trigger", QltyInspectionGenRule."Transfer Order Trigger"::NoTrigger);
        LibraryAssert.AreEqual(2, QltyInspectionGenRule.Count(), 'Transfer rule should have new transfer order trigger value.');

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
        QltyInspectionUtility.EnsureSetupExists();

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
    procedure SetupTable_GetVersion()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        NAVAppInstalledApp: Record "NAV App Installed App";
        ReturnedVersion: Text;
    begin
        // [SCENARIO] GetVersion returns the installed app version information

        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [WHEN] GetVersion is called and installed app record exists
        if NAVAppInstalledApp.Get(QltyInspectionUtility.GetAppGuid(QltyManagementSetup)) then begin
            ReturnedVersion := QltyInspectionUtility.GetVersion(QltyManagementSetup);

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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A template with one test is created
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
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.EnsureSetupExists();

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
        QltyInspectionUtility.EnsureSetupExists();

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
        // [SCENARIO] Infer generation rule intent from Item Journal Line when only production order trigger is set in setup
        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A generation rule for Item Journal Line with no condition filter
        QltyInspectionGenRule."Source Table No." := Database::"Item Journal Line";

        // [GIVEN] Setup with only production order trigger enabled
        QltyManagementSetup.Get();
        QltyInspectionUtility.ClearSetupTriggerDefaults(QltyManagementSetup);
        QltyManagementSetup."Production Order Trigger" := QltyManagementSetup."Production Order Trigger"::OnProductionOrderRelease;
        QltyManagementSetup.Modify();

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is Production with Maybe certainty
        LibraryAssert.AreEqual(GenRuleIntent::Production, GenRuleIntent, 'Should return Production intent.');
        LibraryAssert.AreEqual(Certainty::Maybe, Certainty, 'Should be  maybe on certainty.');

        // [THEN] Cleanup: Disable production order trigger
        QltyManagementSetup."Production Order Trigger" := QltyManagementSetup."Production Order Trigger"::NoTrigger;
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
        // [SCENARIO] Infer generation rule intent from Item Ledger Entry when only production order trigger is set in setup
        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A generation rule for Item Ledger Entry with no condition filter
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";

        // [GIVEN] Setup with only production order trigger enabled
        QltyManagementSetup.Get();
        QltyInspectionUtility.ClearSetupTriggerDefaults(QltyManagementSetup);
        QltyManagementSetup."Production Order Trigger" := QltyManagementSetup."Production Order Trigger"::OnProductionOrderRelease;
        QltyManagementSetup.Modify();

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Production
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Production, 'Should return Production intent.');

        // [THEN] Cleanup: Disable production order trigger
        QltyManagementSetup."Production Order Trigger" := QltyManagementSetup."Production Order Trigger"::NoTrigger;
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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A generation rule for Item Ledger Entry
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";
        QltyInspectionGenRule."Condition Filter" := 'WHERE(Entry Type=FILTER(Output|Positive Adjmt.))';

        // [GIVEN] Setup with production order trigger enabled
        QltyManagementSetup.Get();
        QltyInspectionUtility.ClearSetupTriggerDefaults(QltyManagementSetup);
        QltyManagementSetup."Production Order Trigger" := QltyManagementSetup."Production Order Trigger"::OnProductionOrderRelease;
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

        // [THEN] Cleanup: Disable production order trigger
        QltyManagementSetup."Production Order Trigger" := QltyManagementSetup."Production Order Trigger"::NoTrigger;
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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A generation rule for Item Ledger Entry with no condition filter
        QltyInspectionGenRule."Source Table No." := Database::"Item Ledger Entry";

        // [GIVEN] Setup with all triggers enabled
        QltyManagementSetup.Get();
        QltyManagementSetup."Purchase Order Trigger" := QltyManagementSetup."Purchase Order Trigger"::OnPurchaseOrderPostReceive;
        QltyManagementSetup."Sales Return Trigger" := QltyManagementSetup."Sales Return Trigger"::OnSalesReturnOrderPostReceive;
        QltyManagementSetup."Transfer Order Trigger" := QltyManagementSetup."Transfer Order Trigger"::OnTransferOrderPostReceive;
        QltyManagementSetup."Assembly Trigger" := QltyManagementSetup."Assembly Trigger"::OnAssemblyOutputPost;
        QltyManagementSetup."Warehouse Receipt Trigger" := QltyManagementSetup."Warehouse Receipt Trigger"::OnWarehouseReceiptCreate;
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::OnWhseMovementRegister;
        QltyManagementSetup."Production Order Trigger" := QltyManagementSetup."Production Order Trigger"::OnProductionOrderRelease;
        QltyManagementSetup.Modify();

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is Unknown (ambiguous due to multiple triggers)
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::Unknown, 'Should return unknown intent.');

        // [THEN] Cleanup: Disable production order trigger
        QltyManagementSetup."Production Order Trigger" := QltyManagementSetup."Production Order Trigger"::NoTrigger;
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
        // [SCENARIO] Infer generation rule intent from Warehouse Journal Line when only Warehouse Receipt Trigger is set in setup
        Initialize();

        // [GIVEN] Quality management setup is configured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A generation rule for Warehouse Journal Line with no condition filter
        QltyInspectionGenRule."Source Table No." := Database::"Warehouse Journal Line";

        // [GIVEN] Setup with only Warehouse Receipt Trigger enabled
        QltyManagementSetup.Get();
        QltyInspectionUtility.ClearSetupTriggerDefaults(QltyManagementSetup);
        QltyManagementSetup."Warehouse Receipt Trigger" := QltyManagementSetup."Warehouse Receipt Trigger"::OnWarehouseReceiptCreate;
        QltyManagementSetup.Modify();

        // [WHEN] Inferring the generation rule intent
        QltyInspectionGenRule.InferGenerationRuleIntent(GenRuleIntent, Certainty);

        // [THEN] The intent is correctly identified as Warehouse Receipt
        LibraryAssert.IsTrue(GenRuleIntent = GenRuleIntent::"Warehouse Receipt", 'Should return Warehouse Receive intent.');

        // [THEN] Cleanup: Disable Warehouse Receipt Trigger
        QltyManagementSetup."Warehouse Receipt Trigger" := QltyManagementSetup."Warehouse Receipt Trigger"::NoTrigger;
        QltyManagementSetup.Modify();
    end;

    [Test]
    procedure ResultTable_TestValidateResultCode()
    var
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
    begin
        // [SCENARIO] Validate result code by removing special characters
        Initialize();

        // [WHEN] Validating result code with special characters (ResultCode1Tok)
        ToLoadQltyInspectionResult.Validate(Code, 'RESULT' + ResultCode1Tok);

        // [THEN] Special characters are removed from code
        LibraryAssert.AreEqual(ToLoadQltyInspectionResult.Code, 'RESULT', 'Should remove special characters in result code');

        // [WHEN] Validating result code with different special characters (ResultCode2Tok)
        ToLoadQltyInspectionResult.Validate(Code, 'RESULT' + ResultCode2Tok);

        // [THEN] Special characters are removed from code
        LibraryAssert.AreEqual(ToLoadQltyInspectionResult.Code, 'RESULT', 'Should remove special characters in result code');
    end;

    [Test]
    procedure ResultTable_TestOnDelete_ExistingTestLines_ShouldError()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ResultCode: Text;
    begin
        // [SCENARIO] Cannot delete result when it is referenced by existing inspection lines
        Initialize();

        // [GIVEN] All existing results are deleted
        ToLoadQltyInspectionResult.DeleteAll();

        // [GIVEN] A new result is created
        QltyInspectionUtility.GenerateRandomCharacters(20, ResultCode);
        ToLoadQltyInspectionResult.Code := CopyStr(ResultCode, 1, MaxStrLen(ToLoadQltyInspectionResult.Code));
        ToLoadQltyInspectionResult."Result Category" := ToLoadQltyInspectionResult."Result Category"::Acceptable;
        ToLoadQltyInspectionResult.Insert();

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] An inspection header is created
        QltyInspectionHeader."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        QltyInspectionHeader.Insert();

        // [GIVEN] An inspection line is created with the result code
        QltyInspectionLine."Inspection No." := QltyInspectionHeader."No.";
        QltyInspectionLine."Re-inspection No." := QltyInspectionHeader."Re-inspection No.";
        QltyInspectionLine."Line No." := 10000;
        QltyInspectionLine."Result Code" := ToLoadQltyInspectionResult.Code;
        QltyInspectionLine.Insert();

        // [WHEN] Attempting to delete the result
        asserterror ToLoadQltyInspectionResult.Delete(true);

        // [THEN] An error is thrown preventing deletion
        LibraryAssert.ExpectedError(CannotBeRemovedExistingInspectionErr);
    end;

    [Test]
    procedure ResultTable_TestOnDelete_ExistingInspection_ShouldError()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ResultCode: Text;
    begin
        // [SCENARIO] Cannot delete result when it is referenced by existing inspection headers
        Initialize();

        // [GIVEN] All existing results are deleted
        ToLoadQltyInspectionResult.DeleteAll();

        // [GIVEN] A new result is created
        QltyInspectionUtility.GenerateRandomCharacters(20, ResultCode);
        ToLoadQltyInspectionResult.Code := CopyStr(ResultCode, 1, MaxStrLen(ToLoadQltyInspectionResult.Code));
        ToLoadQltyInspectionResult."Result Category" := ToLoadQltyInspectionResult."Result Category"::Acceptable;
        ToLoadQltyInspectionResult.Insert();

        // [GIVEN] A template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);

        // [GIVEN] An inspection header is created with the result code
        QltyInspectionHeader."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        QltyInspectionHeader."Result Code" := ToLoadQltyInspectionResult.Code;
        QltyInspectionHeader.Insert();

        // [WHEN] Attempting to delete the result
        asserterror ToLoadQltyInspectionResult.Delete(true);

        // [THEN] An error is thrown preventing deletion
        LibraryAssert.ExpectedError(CannotBeRemovedExistingInspectionErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ResultTable_TestOnDelete_ExistingInspectionResultConditions()
    var
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ResultCode: Text;
    begin
        // [SCENARIO] Delete result with existing inspection result conditions after confirmation
        Initialize();

        // [GIVEN] All existing results are deleted
        ToLoadQltyInspectionResult.DeleteAll();

        // [GIVEN] A new result is created
        QltyInspectionUtility.GenerateRandomCharacters(20, ResultCode);
        ToLoadQltyInspectionResult.Code := CopyStr(ResultCode, 1, MaxStrLen(ToLoadQltyInspectionResult.Code));
        ToLoadQltyInspectionResult."Result Category" := ToLoadQltyInspectionResult."Result Category"::Acceptable;
        ToLoadQltyInspectionResult.Insert();

        // [GIVEN] A template with one test is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        QltyInspectionHeader."Template Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        QltyInspectionHeader.Insert();

        // [GIVEN] Template line is retrieved
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.FindFirst();

        // [GIVEN] An inspection line is created
        QltyInspectionLine."Inspection No." := QltyInspectionHeader."No.";
        QltyInspectionLine."Re-inspection No." := QltyInspectionHeader."Re-inspection No.";
        QltyInspectionLine."Line No." := 10000;
        QltyInspectionLine."Test Code" := ConfigurationToLoadQltyInspectionTemplateLine."Test Code";
        QltyInspectionLine."Result Code" := ToLoadQltyInspectionResult.Code;
        QltyInspectionLine.Insert();

        // [GIVEN] A result condition is created for the inspection
        ToLoadQltyIResultConditConf."Condition Type" := ToLoadQltyIResultConditConf."Condition Type"::Inspection;
        ToLoadQltyIResultConditConf."Target Code" := QltyInspectionHeader."No.";
        ToLoadQltyIResultConditConf."Target Re-inspection No." := QltyInspectionHeader."Re-inspection No.";
        ToLoadQltyIResultConditConf."Target Line No." := QltyInspectionLine."Line No.";
        ToLoadQltyIResultConditConf."Test Code" := QltyInspectionLine."Test Code";
        ToLoadQltyIResultConditConf."Result Code" := ToLoadQltyInspectionResult.Code;
        ToLoadQltyIResultConditConf.Insert();

        // [GIVEN] Inspection line and header are deleted
        QltyInspectionLine.Delete();
        QltyInspectionHeader.Delete();

        // [WHEN] Deleting the result with confirmation
        ToLoadQltyInspectionResult.Delete(true);

        // [THEN] Result is successfully deleted
        ToLoadQltyInspectionResult.SetRange(Code, ToLoadQltyInspectionResult.Code);
        LibraryAssert.IsTrue(ToLoadQltyInspectionResult.IsEmpty(), 'Should have deleted result.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ResultTable_TestOnDelete_ExistingTestResultConditions()
    var
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ToLoadQltyTest: Record "Qlty. Test";
        ResultCode: Text;
    begin
        // [SCENARIO] Delete result with existing test result conditions after confirmation
        Initialize();

        // [GIVEN] All existing results are deleted
        ToLoadQltyInspectionResult.DeleteAll();

        // [GIVEN] A new result is created
        QltyInspectionUtility.GenerateRandomCharacters(20, ResultCode);
        ToLoadQltyInspectionResult.Code := CopyStr(ResultCode, 1, MaxStrLen(ToLoadQltyInspectionResult.Code));
        ToLoadQltyInspectionResult."Result Category" := ToLoadQltyInspectionResult."Result Category"::Acceptable;
        ToLoadQltyInspectionResult.Insert();

        // [GIVEN] A test is created
        ToLoadQltyTest.Code := CopyStr(ResultCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest."Test Value Type" := ToLoadQltyTest."Test Value Type"::"Value Type Integer";
        ToLoadQltyTest.Insert();

        // [GIVEN] A result condition is created for the test
        ToLoadQltyIResultConditConf."Condition Type" := ToLoadQltyIResultConditConf."Condition Type"::Test;
        ToLoadQltyIResultConditConf."Target Code" := ToLoadQltyTest.Code;
        ToLoadQltyIResultConditConf."Test Code" := ToLoadQltyTest.Code;
        ToLoadQltyIResultConditConf."Result Code" := ToLoadQltyInspectionResult.Code;
        ToLoadQltyIResultConditConf.Insert();

        // [WHEN] Deleting the result with confirmation
        ToLoadQltyInspectionResult.Delete(true);

        // [THEN] Result is successfully deleted
        ToLoadQltyInspectionResult.SetRange(Code, ToLoadQltyInspectionResult.Code);
        LibraryAssert.IsTrue(ToLoadQltyInspectionResult.IsEmpty(), 'Should have deleted result.')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ResultTable_TestOnDelete_ExistingTemplateResultConditions()
    var
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        ResultCode: Text;
    begin
        // [SCENARIO] Delete result with existing template result conditions after confirmation
        Initialize();

        // [GIVEN] All existing results are deleted
        ToLoadQltyInspectionResult.DeleteAll();

        // [GIVEN] A new result is created
        QltyInspectionUtility.GenerateRandomCharacters(20, ResultCode);
        ToLoadQltyInspectionResult.Code := CopyStr(ResultCode, 1, MaxStrLen(ToLoadQltyInspectionResult.Code));
        ToLoadQltyInspectionResult."Result Category" := ToLoadQltyInspectionResult."Result Category"::Acceptable;
        ToLoadQltyInspectionResult.Insert();

        // [GIVEN] A template with one test is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 1);
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.FindFirst();

        // [GIVEN] A result condition is created for the template
        ToLoadQltyIResultConditConf."Condition Type" := ToLoadQltyIResultConditConf."Condition Type"::Template;
        ToLoadQltyIResultConditConf."Target Code" := ConfigurationToLoadQltyInspectionTemplateHdr.Code;
        ToLoadQltyIResultConditConf."Target Line No." := ConfigurationToLoadQltyInspectionTemplateLine."Line No.";
        ToLoadQltyIResultConditConf."Test Code" := ConfigurationToLoadQltyInspectionTemplateLine."Test Code";
        ToLoadQltyIResultConditConf."Result Code" := ToLoadQltyInspectionResult.Code;
        ToLoadQltyIResultConditConf.Insert();

        // [WHEN] Deleting the result with confirmation
        ToLoadQltyInspectionResult.Delete(true);

        // [THEN] Result is successfully deleted
        ToLoadQltyInspectionResult.SetRange(Code, ToLoadQltyInspectionResult.Code);
        LibraryAssert.IsTrue(ToLoadQltyInspectionResult.IsEmpty(), 'Should have deleted result.')
    end;

    [Test]
    [HandlerFunctions('StrMenuPageHandler')]
    procedure ResultTable_AssistEditResultStyle()
    var
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        QltyInspectionResultList: TestPage "Qlty. Inspection Result List";
        ResultCode: Text;
    begin
        // [SCENARIO] Use AssistEdit to configure result style on result list page
        Initialize();

        // [GIVEN] All existing results are deleted
        if not ToLoadQltyInspectionResult.IsEmpty() then
            ToLoadQltyInspectionResult.DeleteAll();
        ToLoadQltyInspectionResult.DeleteAll();

        // [GIVEN] A new result is created with StrongAccent style
        QltyInspectionUtility.GenerateRandomCharacters(20, ResultCode);
        ToLoadQltyInspectionResult.Code := CopyStr(ResultCode, 1, MaxStrLen(ToLoadQltyInspectionResult.Code));
        ToLoadQltyInspectionResult."Result Category" := ToLoadQltyInspectionResult."Result Category"::Acceptable;
        ToLoadQltyInspectionResult."Override Style" := 'StrongAccent';
        ToLoadQltyInspectionResult.Insert();

        // [GIVEN] Result list page is opened and navigated to the result
        QltyInspectionResultList.OpenEdit();
        QltyInspectionResultList.GoToRecord(ToLoadQltyInspectionResult);

        // [WHEN] AssistEdit is invoked on Override Style field
        QltyInspectionResultList."Override Style".AssistEdit();
        QltyInspectionResultList.Close();

        // [THEN] Override style is updated to None
        ToLoadQltyInspectionResult.Get(ToLoadQltyInspectionResult.Code);
        LibraryAssert.AreEqual('None', ToLoadQltyInspectionResult."Override Style", 'Override style should be updated.');
    end;

    [Test]
    procedure ResultTable_GetResultStyle()
    var
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ResultStyle: Text;
        ResultCode: Text;
    begin
        // [SCENARIO] Get appropriate result style based on category and override style
        Initialize();

        // [GIVEN] All existing results are deleted
        ToLoadQltyInspectionResult.DeleteAll();

        // [GIVEN] A new result with Acceptable category is created
        QltyInspectionUtility.GenerateRandomCharacters(20, ResultCode);
        ToLoadQltyInspectionResult.Code := CopyStr(ResultCode, 1, MaxStrLen(ToLoadQltyInspectionResult.Code));
        ToLoadQltyInspectionResult."Result Category" := ToLoadQltyInspectionResult."Result Category"::Acceptable;
        ToLoadQltyInspectionResult.Insert();

        // [WHEN] Getting result style for Acceptable category
        ResultStyle := ToLoadQltyInspectionResult.GetResultStyle();

        // [THEN] Style is Favorable
        LibraryAssert.AreEqual('Favorable', ResultStyle, 'Should have favorable style.');

        // [WHEN] Changing category to Not acceptable
        ToLoadQltyInspectionResult."Result Category" := ToLoadQltyInspectionResult."Result Category"::"Not acceptable";
        ToLoadQltyInspectionResult.Modify();

        ResultStyle := ToLoadQltyInspectionResult.GetResultStyle();

        // [THEN] Style is Unfavorable
        LibraryAssert.AreEqual('Unfavorable', ResultStyle, 'Should have unfavorable style.');

        // [WHEN] Changing category to Uncategorized
        ToLoadQltyInspectionResult."Result Category" := ToLoadQltyInspectionResult."Result Category"::Uncategorized;
        ToLoadQltyInspectionResult.Modify();

        ResultStyle := ToLoadQltyInspectionResult.GetResultStyle();

        // [THEN] Style is None
        LibraryAssert.AreEqual('None', ResultStyle, 'Should have no style.');

        // [WHEN] Setting override style to Attention
        ToLoadQltyInspectionResult."Override Style" := 'Attention';
        ToLoadQltyInspectionResult.Modify();

        ResultStyle := ToLoadQltyInspectionResult.GetResultStyle();

        // [THEN] Override style takes precedence
        LibraryAssert.AreEqual('Attention', ResultStyle, 'Should have override style.');
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

        // [GIVEN] A template with one test is created
        QltyInspectionUtility.EnsureSetupExists();
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
    procedure TemplateTable_AddTestToTemplate()
    var
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        TestToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        DurationTemplateToLoadQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        ToLoadQltyTest: Record "Qlty. Test";
        ResultCode: Text;
    begin
        // [SCENARIO] Add test to template creates template line and copies result conditions
        Initialize();

        // [GIVEN] A result is created
        QltyInspectionUtility.GenerateRandomCharacters(20, ResultCode);
        ToLoadQltyInspectionResult.Code := CopyStr(ResultCode, 1, MaxStrLen(ToLoadQltyInspectionResult.Code));
        ToLoadQltyInspectionResult."Result Category" := ToLoadQltyInspectionResult."Result Category"::Acceptable;
        ToLoadQltyInspectionResult.Insert();

        // [GIVEN] A test is created
        ToLoadQltyTest.Code := CopyStr(ResultCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest."Test Value Type" := ToLoadQltyTest."Test Value Type"::"Value Type Integer";
        ToLoadQltyTest.Insert();

        // [GIVEN] A result condition is created for the test
        TestToLoadQltyIResultConditConf."Condition Type" := TestToLoadQltyIResultConditConf."Condition Type"::Test;
        TestToLoadQltyIResultConditConf."Target Code" := ToLoadQltyTest.Code;
        TestToLoadQltyIResultConditConf."Test Code" := ToLoadQltyTest.Code;
        TestToLoadQltyIResultConditConf."Result Code" := ToLoadQltyInspectionResult.Code;
        TestToLoadQltyIResultConditConf.Insert();

        // [GIVEN] An empty template is created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 0);

        // [WHEN] Adding test to template
        LibraryAssert.IsTrue(ConfigurationToLoadQltyInspectionTemplateHdr.AddTestToTemplate(ToLoadQltyTest.Code), 'Should add template line for test');

        // [THEN] Template line is created with correct test code
        ConfigurationToLoadQltyInspectionTemplateLine.SetRange("Template Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        ConfigurationToLoadQltyInspectionTemplateLine.FindFirst();
        LibraryAssert.AreEqual(ToLoadQltyTest.Code, ConfigurationToLoadQltyInspectionTemplateLine."Test Code", 'Should be correct test code.');

        // [THEN] Result condition is copied to template
        DurationTemplateToLoadQltyIResultConditConf.SetRange("Condition Type", DurationTemplateToLoadQltyIResultConditConf."Condition Type"::Template);
        DurationTemplateToLoadQltyIResultConditConf.SetRange("Target Code", ConfigurationToLoadQltyInspectionTemplateHdr.Code);
        DurationTemplateToLoadQltyIResultConditConf.FindFirst();

        // [THEN] Template result condition has correct test and result codes
        LibraryAssert.AreEqual(ToLoadQltyTest.Code, DurationTemplateToLoadQltyIResultConditConf."Test Code", 'Should be correct test code.');
        LibraryAssert.AreEqual(ToLoadQltyInspectionResult.Code, DurationTemplateToLoadQltyIResultConditConf."Result Code", 'Should be correct result code.');
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
