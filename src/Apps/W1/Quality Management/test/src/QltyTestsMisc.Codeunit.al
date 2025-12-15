// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Assembly.Document;
using Microsoft.CRM.Team;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Test.QualityManagement.TestLibraries;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Security.AccessControl;
using System.Security.User;
using System.TestLibraries.Utilities;

codeunit 139964 "Qlty. Tests - Misc"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;
    EventSubscriberInstance = Manual;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        Any: Codeunit Any;
        TestNotification: Notification;
        NotificationMsg: Text;
        NotificationOptions: Dictionary of [Text, Text];
        DocumentNo: Text;
        FlagTestNavigateToSourceDocument: Text;
        NotificationDataTestRecordIdTok: Label 'TestRecordId', Locked = true;
        AssignToSelfExpectedMessageLbl: Label 'You have altered test %1, would you like to assign it to yourself?', Comment = '%1=the test number';
        AssignToSelfLbl: Label 'Assign to myself';
        IgnoreLbl: Label 'Ignore';
        Bin1Tok: Label 'Bin1';
        Bin2Tok: Label 'Bin2';
        EntryTypeBlockedErr: Label 'This warehouse transaction was blocked because the quality inspection %1 has the grade of %2 for item %4 with tracking %5 %6, which is configured to disallow the transaction "%3". You can change whether this transaction is allowed by navigating to Quality Inspection Grades.', Comment = '%1=quality test, %2=grade, %3=entry type being blocked, %4=item, %5=lot, %6=serial';
        EntryTypeBlocked2Err: Label 'This transaction was blocked because the quality inspection %1 has the grade of %2 for item %4 with tracking %5, which is configured to disallow the transaction "%3". You can change whether this transaction is allowed by navigating to Quality Inspection Grades.', Comment = '%1=quality test, %2=grade, %3=entry type being blocked, %4=item, %5=combined package tracking details of lot, serial, and package no.';
        NotificationDataRelatedRecordIdTok: Label 'RelatedRecordId', Locked = true;
        TrackingDetailsTok: Label '%1 %2', Comment = '%1=lot no,%2=serial no';
        IsInitialized: Boolean;

    [Test]
    procedure GetCSVOfValuesFromRecord_NoFilter()
    var
        FirstSalespersonPurchaser: Record "Salesperson/Purchaser";
        SecondSalespersonPurchaser: Record "Salesperson/Purchaser";
        ThirdSalespersonPurchaser: Record "Salesperson/Purchaser";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        LibrarySales: Codeunit "Library - Sales";
        OutputOne: Text;
        OutputTwo: Text;
        Count: Integer;
        CountOfCommas: Integer;
    begin
        // [SCENARIO] Get CSV of values from all records without filter

        Initialize();

        // [GIVEN] Multiple Salesperson/Purchaser records
        LibrarySales.CreateSalesperson(FirstSalespersonPurchaser);
        LibrarySales.CreateSalesperson(SecondSalespersonPurchaser);
        LibrarySales.CreateSalesperson(ThirdSalespersonPurchaser);

        // [WHEN] GetCSVOfValuesFromRecord is called without filter
        // [THEN] The function returns a comma-separated list of all codes
        OutputOne := QltyMiscHelpers.GetCSVOfValuesFromRecord(Database::"Salesperson/Purchaser", FirstSalespersonPurchaser.FieldNo(Code), '', 0);
        OutputTwo := QltyMiscHelpers.GetCSVOfValuesFromRecord(Database::"Salesperson/Purchaser", FirstSalespersonPurchaser.FieldNo(Code), '');
        LibraryAssert.AreEqual(OutputOne, OutputTwo, 'different approaches should be identical');

        Count := FirstSalespersonPurchaser.Count();
        CountOfCommas := StrLen(OutputOne) - strlen(DelChr(OutputOne, '=', ','));
        LibraryAssert.AreEqual(Count - 1, CountOfCommas, 'mismatch in expected records.');

        OutputOne := ',' + OutputOne;
        LibraryAssert.IsTrue(StrPos(OutputOne, ',' + FirstSalespersonPurchaser.Code) > 0, 'demo record 1');
        LibraryAssert.IsTrue(StrPos(OutputOne, ',' + SecondSalespersonPurchaser.Code) > 0, 'demo record 2');
        LibraryAssert.IsTrue(StrPos(OutputOne, ',' + ThirdSalespersonPurchaser.Code) > 0, 'demo record 3');
    end;

    [Test]
    procedure GetCSVOfValuesFromRecord_WithFilters()
    var
        FirstSalespersonPurchaser: Record "Salesperson/Purchaser";
        SecondSalespersonPurchaser: Record "Salesperson/Purchaser";
        ThirdSalespersonPurchaser: Record "Salesperson/Purchaser";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        LibrarySales: Codeunit "Library - Sales";
        Output1: Text;
        Output2: Text;
        CountOfCommas: Integer;
    begin
        // [SCENARIO] Get CSV of values from filtered records

        Initialize();

        // [GIVEN] Multiple Salesperson/Purchaser records with a filter applied to one record
        LibrarySales.CreateSalesperson(FirstSalespersonPurchaser);
        LibrarySales.CreateSalesperson(SecondSalespersonPurchaser);
        LibrarySales.CreateSalesperson(ThirdSalespersonPurchaser);

        FirstSalespersonPurchaser.SetRecFilter();

        // [WHEN] GetCSVOfValuesFromRecord is called with a filter view
        // [THEN] The function returns only the single filtered code value
        Output1 := QltyMiscHelpers.GetCSVOfValuesFromRecord(Database::"Salesperson/Purchaser", FirstSalespersonPurchaser.FieldNo(Code), FirstSalespersonPurchaser.GetView(true), 0);
        Output2 := QltyMiscHelpers.GetCSVOfValuesFromRecord(Database::"Salesperson/Purchaser", FirstSalespersonPurchaser.FieldNo(Code), FirstSalespersonPurchaser.GetView(false));
        LibraryAssert.AreEqual(Output1, Output2, 'different approaches should be identical');

        CountOfCommas := StrLen(Output1) - strlen(DelChr(Output1, '=', ','));
        LibraryAssert.AreEqual(0, CountOfCommas, 'should only be one record (no commas)');

        LibraryAssert.AreEqual(FirstSalespersonPurchaser.Code, Output1, 'should match exactly.');

        Output1 := ',' + Output1;
        LibraryAssert.IsTrue(StrPos(Output1, ',' + FirstSalespersonPurchaser.Code) > 0, 'demo record 1');
        LibraryAssert.IsTrue(StrPos(Output1, ',' + SecondSalespersonPurchaser.Code) = 0, 'demo record 2 should not be included');
        LibraryAssert.IsTrue(StrPos(Output1, ',' + ThirdSalespersonPurchaser.Code) = 0, 'demo record 3 should not be included.');
    end;

    [Test]
    procedure GetCSVOfValuesFromRecord_WithLimits()
    var
        FirstSalespersonPurchaser: Record "Salesperson/Purchaser";
        SecondSalespersonPurchaser: Record "Salesperson/Purchaser";
        ThirdSalespersonPurchaser: Record "Salesperson/Purchaser";
        FilteredSalespersonPurchaser: Record "Salesperson/Purchaser";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        LibrarySales: Codeunit "Library - Sales";
        Output1: Text;
        Output2: Text;
        CountOfCommas: Integer;
    begin
        // [SCENARIO] Get CSV of values from records with row limit

        Initialize();

        // [GIVEN] Multiple Salesperson/Purchaser records with the same email filtered
        LibrarySales.CreateSalesperson(FirstSalespersonPurchaser);
        FirstSalespersonPurchaser."E-Mail 2" := CopyStr(Any.Email(), 1, MaxStrLen(FirstSalespersonPurchaser."E-Mail 2"));
        FirstSalespersonPurchaser.Modify(false);

        LibrarySales.CreateSalesperson(SecondSalespersonPurchaser);
        SecondSalespersonPurchaser."E-Mail 2" := FirstSalespersonPurchaser."E-Mail 2";
        SecondSalespersonPurchaser.Modify(false);

        LibrarySales.CreateSalesperson(ThirdSalespersonPurchaser);
        ThirdSalespersonPurchaser."E-Mail 2" := FirstSalespersonPurchaser."E-Mail 2";
        ThirdSalespersonPurchaser.Modify(false);

        FilteredSalespersonPurchaser.Reset();
#pragma warning disable AA0210
        FilteredSalespersonPurchaser.SetRange("E-Mail 2", FirstSalespersonPurchaser."E-Mail 2");
#pragma warning restore AA0210
        FilteredSalespersonPurchaser.SetCurrentKey(SystemModifiedAt);
        FilteredSalespersonPurchaser.Ascending(false);
        FilteredSalespersonPurchaser.FindSet();
        FilteredSalespersonPurchaser.Next(1);

        // [WHEN] GetCSVOfValuesFromRecord is called with row limits
        // [THEN] The function returns only the specified number of records
        Output1 := QltyMiscHelpers.GetCSVOfValuesFromRecord(Database::"Salesperson/Purchaser", FirstSalespersonPurchaser.FieldNo(Code), FilteredSalespersonPurchaser.GetView(true), 1);
        Output2 := QltyMiscHelpers.GetCSVOfValuesFromRecord(Database::"Salesperson/Purchaser", FirstSalespersonPurchaser.FieldNo(Code), FilteredSalespersonPurchaser.GetView(true), 2);

        CountOfCommas := StrLen(Output1) - strlen(DelChr(Output1, '=', ','));
        LibraryAssert.AreEqual(0, CountOfCommas, 'should only be one record (no commas)');

        CountOfCommas := StrLen(Output2) - strlen(DelChr(Output2, '=', ','));
        LibraryAssert.AreEqual(1, CountOfCommas, 'should only be two records, 1 comma');

        Output2 := ',' + Output2;
        LibraryAssert.IsTrue(StrPos(Output2, ',' + FirstSalespersonPurchaser.Code) = 0, 'demo record 1 should  be EXCLUDED');
        LibraryAssert.IsTrue(StrPos(Output2, ',' + SecondSalespersonPurchaser.Code) > 0, 'demo record 2 should  be included');
        LibraryAssert.IsTrue(StrPos(Output2, ',' + ThirdSalespersonPurchaser.Code) > 0, 'demo record 3 should  be included');
    end;

    [Test]
    procedure GetRecordsForTableField_One()
    var
        User: Record User;
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        LookupQualityMeasureQltyField: Record "Qlty. Field";
        TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary;
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Item: Record Item;
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibrarySales: Codeunit "Library - Sales";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Get records for table field with single matching record

        Initialize();

        // [GIVEN] A User with full name and contact email
        LibraryPermissions.CreateUser(User, '', false);
        User."Full Name" := CopyStr(Any.AlphanumericText(MaxStrLen(User."Full Name")), 1, MaxStrLen(User."Full Name"));
        User."Contact Email" := CopyStr(Any.Email(), 1, MaxStrLen(User."Contact Email"));
        User.Modify(false);

        // [GIVEN] A Salesperson/Purchaser with name, job title, phone, and email
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser.Name := CopyStr(Any.AlphanumericText(MaxStrLen(User."Full Name")), 1, MaxStrLen(SalespersonPurchaser.Name));
        SalespersonPurchaser."Job Title" := 'another predictable job title';
        SalespersonPurchaser."Phone No." := '+1-800-440-7543';
        SalespersonPurchaser."E-Mail" := CopyStr(Any.Email(), 1, MaxStrLen(SalespersonPurchaser."E-Mail"));
        SalespersonPurchaser.Modify();
        SalespersonPurchaser.SetRecFilter();

        // [GIVEN] A User Setup linked to the Salesperson/Purchaser
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, User."User Name", '');
        UserSetup."Salespers./Purch. Code" := SalespersonPurchaser.Code;
        UserSetup."E-Mail" := CopyStr(Any.Email(), 1, MaxStrLen(UserSetup."E-mail"));
        UserSetup."Phone No." := '+1-866-440-7543';
        UserSetup.Modify(false);

        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A test template with table lookup field for Salesperson/Purchaser filtered to one record
        QltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 2);
        QltyTestsUtility.CreateFieldAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, LookupQualityMeasureQltyField."Field Type"::"Field Type Table Lookup", LookupQualityMeasureQltyField, ConfigurationToLoadQltyInspectionTemplateLine);
        LookupQualityMeasureQltyField."Lookup Table No." := Database::"Salesperson/Purchaser";
        LookupQualityMeasureQltyField."Lookup Field No." := SalespersonPurchaser.FieldNo(Code);
        LookupQualityMeasureQltyField."Lookup Table Filter" := CopyStr(SalespersonPurchaser.GetView(), 1, maxstrlen(LookupQualityMeasureQltyField."Lookup Table Filter"));
        LookupQualityMeasureQltyField.Modify(false);

        // [GIVEN] A prioritized rule for production order routing line
        QltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order with routing line and inspection test created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);
        Item.Get(ProdProductionOrder."Source No.");

        QltyInspectionTestHeader.Reset();

        ClearLastError();
        QltyInspectionTestCreate.CreateTestWithVariant(ProdOrderRoutingLine, true);
        QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);

        // [GIVEN] A test line with the lookup field and test value set to the Salesperson/Purchaser code
        QltyInspectionTestLine.SetRange("Test No.", QltyInspectionTestHeader."No.");
        QltyInspectionTestLine.SetRange("ReTest No.", QltyInspectionTestHeader."ReTest No.");
        QltyInspectionTestLine.SetRange("Field Code", LookupQualityMeasureQltyField.Code);

        LibraryAssert.AreEqual(1, QltyInspectionTestLine.Count(), 'there should  be exactly one test line that matches.');
        QltyInspectionTestLine.FindFirst();
        QltyInspectionTestLine.Validate("Test Value", SalespersonPurchaser.Code);
        QltyInspectionTestLine.Modify();

        // [WHEN] GetRecordsForTableField is called
        QltyMiscHelpers.GetRecordsForTableField(QltyInspectionTestLine, TempBufferQltyLookupCode);

        // [THEN] The function returns exactly one matching record
        LibraryAssert.AreEqual(1, TempBufferQltyLookupCode.Count(), 'should have been 1 record.');

        TempBufferQltyLookupCode.FindFirst();
        LibraryAssert.AreEqual(SalespersonPurchaser.Code, TempBufferQltyLookupCode.Code, 'first key should have been set');
    end;

    [Test]
    procedure GetRecordsForTableField_Multiple()
    var
        User: Record User;
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        LookupQualityMeasureQltyField: Record "Qlty. Field";
        TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary;
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        FirstSalespersonPurchaser: Record "Salesperson/Purchaser";
        SecondSalespersonPurchaser: Record "Salesperson/Purchaser";
        ThirdSalespersonPurchaser: Record "Salesperson/Purchaser";
        FilterSalespersonPurchaser: Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Item: Record Item;
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibrarySales: Codeunit "Library - Sales";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Get records for table field with multiple matching records

        Initialize();

        // [GIVEN] A User with full name and contact email
        LibraryPermissions.CreateUser(User, '', false);
        User."Full Name" := CopyStr(Any.AlphanumericText(MaxStrLen(User."Full Name")), 1, MaxStrLen(User."Full Name"));
        User."Contact Email" := CopyStr(Any.Email(), 1, MaxStrLen(User."Contact Email"));
        User.Modify(false);

        // [GIVEN] Three Salesperson/Purchasers sharing the same email address
        LibrarySales.CreateSalesperson(FirstSalespersonPurchaser);
        FirstSalespersonPurchaser.Name := CopyStr(Any.AlphanumericText(MaxStrLen(User."Full Name")), 1, MaxStrLen(FirstSalespersonPurchaser.Name));
        FirstSalespersonPurchaser."Job Title" := 'TestGetRecordsForTableField';
        FirstSalespersonPurchaser."Phone No." := '+1-800-440-7543';
        FirstSalespersonPurchaser."E-Mail" := CopyStr(Any.Email(), 1, MaxStrLen(FirstSalespersonPurchaser."E-Mail"));
        FirstSalespersonPurchaser.Modify();
        FirstSalespersonPurchaser.SetRecFilter();

        LibrarySales.CreateSalesperson(SecondSalespersonPurchaser);
        SecondSalespersonPurchaser."E-Mail" := FirstSalespersonPurchaser."E-Mail";
        SecondSalespersonPurchaser.Modify(false);

        LibrarySales.CreateSalesperson(ThirdSalespersonPurchaser);
        ThirdSalespersonPurchaser."E-Mail" := FirstSalespersonPurchaser."E-Mail";
        ThirdSalespersonPurchaser.Modify(false);

        // [GIVEN] A filter on Salesperson/Purchaser for the shared email
        FilterSalespersonPurchaser.Reset();
        FilterSalespersonPurchaser.SetRange("E-Mail", FirstSalespersonPurchaser."E-Mail");

        // [GIVEN] A User Setup linked to the first Salesperson/Purchaser
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, User."User Name", '');
        UserSetup."Salespers./Purch. Code" := FirstSalespersonPurchaser.Code;
        UserSetup."E-Mail" := CopyStr(Any.Email(), 1, MaxStrLen(UserSetup."E-mail"));
        UserSetup."Phone No." := '+1-866-440-7543';
        UserSetup.Modify(false);

        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A test template with table lookup field for Salesperson/Purchaser filtered by email
        QltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 2);
        QltyTestsUtility.CreateFieldAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, LookupQualityMeasureQltyField."Field Type"::"Field Type Table Lookup", LookupQualityMeasureQltyField, ConfigurationToLoadQltyInspectionTemplateLine);
        LookupQualityMeasureQltyField."Lookup Table No." := Database::"Salesperson/Purchaser";
        LookupQualityMeasureQltyField."Lookup Field No." := FilterSalespersonPurchaser.FieldNo(Code);
        LookupQualityMeasureQltyField."Lookup Table Filter" := CopyStr(FilterSalespersonPurchaser.GetView(), 1, maxstrlen(LookupQualityMeasureQltyField."Lookup Table Filter"));
        LookupQualityMeasureQltyField.Modify(false);

        // [GIVEN] A prioritized rule for production order routing line
        QltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order with routing line and inspection test created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);
        Item.Get(ProdProductionOrder."Source No.");

        QltyInspectionTestHeader.Reset();

        ClearLastError();
        QltyInspectionTestCreate.CreateTestWithVariant(ProdOrderRoutingLine, true);
        QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);

        // [GIVEN] A test line with the lookup field and test value set to the first Salesperson/Purchaser code
        QltyInspectionTestLine.SetRange("Test No.", QltyInspectionTestHeader."No.");
        QltyInspectionTestLine.SetRange("ReTest No.", QltyInspectionTestHeader."ReTest No.");
        QltyInspectionTestLine.SetRange("Field Code", LookupQualityMeasureQltyField.Code);

        LibraryAssert.AreEqual(1, QltyInspectionTestLine.Count(), 'there should  be exactly one test line that matches.');
        QltyInspectionTestLine.FindFirst();
        QltyInspectionTestLine.Validate("Test Value", FirstSalespersonPurchaser.Code);
        QltyInspectionTestLine.Modify();

        // [WHEN] GetRecordsForTableField is called
        QltyMiscHelpers.GetRecordsForTableField(QltyInspectionTestLine, TempBufferQltyLookupCode);

        // [THEN] The function returns all three matching records
        LibraryAssert.AreEqual(3, TempBufferQltyLookupCode.Count(), 'should have been 3 sales people with that email.');
    end;

    [Test]
    procedure GetRecordsForTableField_WithOverrides()
    var
        User: Record User;
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyField: Record "Qlty. Field";
        LookupQualityMeasureQltyField: Record "Qlty. Field";
        TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary;
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Item: Record Item;
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibrarySales: Codeunit "Library - Sales";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
    begin
        // [SCENARIO] Get records for table field using overloaded function with field and header parameters

        Initialize();

        // [GIVEN] A User with full name and contact email
        LibraryPermissions.CreateUser(User, '', false);
        User."Full Name" := CopyStr(Any.AlphanumericText(MaxStrLen(User."Full Name")), 1, MaxStrLen(User."Full Name"));
        User."Contact Email" := CopyStr(Any.Email(), 1, MaxStrLen(User."Contact Email"));
        User.Modify(false);

        // [GIVEN] A Salesperson/Purchaser with name, job title, phone, and email
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser.Name := CopyStr(Any.AlphanumericText(MaxStrLen(User."Full Name")), 1, MaxStrLen(SalespersonPurchaser.Name));
        SalespersonPurchaser."Job Title" := 'another predictable job title';
        SalespersonPurchaser."Phone No." := '+1-800-440-7543';
        SalespersonPurchaser."E-Mail" := CopyStr(Any.Email(), 1, MaxStrLen(SalespersonPurchaser."E-Mail"));
        SalespersonPurchaser.Modify();
        SalespersonPurchaser.SetRecFilter();

        // [GIVEN] A User Setup linked to the Salesperson/Purchaser
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, User."User Name", '');
        UserSetup."Salespers./Purch. Code" := SalespersonPurchaser.Code;
        UserSetup."E-Mail" := CopyStr(Any.Email(), 1, MaxStrLen(UserSetup."E-mail"));
        UserSetup."Phone No." := '+1-866-440-7543';
        UserSetup.Modify(false);

        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A test template with table lookup field for Salesperson/Purchaser
        QltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 2);
        QltyTestsUtility.CreateFieldAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, LookupQualityMeasureQltyField."Field Type"::"Field Type Table Lookup", LookupQualityMeasureQltyField, ConfigurationToLoadQltyInspectionTemplateLine);
        LookupQualityMeasureQltyField."Lookup Table No." := Database::"Salesperson/Purchaser";
        LookupQualityMeasureQltyField."Lookup Field No." := SalespersonPurchaser.FieldNo(Code);
        LookupQualityMeasureQltyField."Lookup Table Filter" := CopyStr(SalespersonPurchaser.GetView(), 1, maxstrlen(LookupQualityMeasureQltyField."Lookup Table Filter"));
        LookupQualityMeasureQltyField.Modify(false);

        // [GIVEN] A prioritized rule for production order routing line
        QltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order with routing line and inspection test created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);
        Item.Get(ProdProductionOrder."Source No.");

        QltyInspectionTestHeader.Reset();

        ClearLastError();
        QltyInspectionTestCreate.CreateTestWithVariant(ProdOrderRoutingLine, true);
        QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);

        // [GIVEN] A test line with the lookup field and test value set to the Salesperson/Purchaser code
        QltyInspectionTestLine.SetRange("Test No.", QltyInspectionTestHeader."No.");
        QltyInspectionTestLine.SetRange("ReTest No.", QltyInspectionTestHeader."ReTest No.");
        QltyInspectionTestLine.SetRange("Field Code", LookupQualityMeasureQltyField.Code);

        LibraryAssert.AreEqual(1, QltyInspectionTestLine.Count(), 'there should  be exactly one test line that matches.');
        QltyInspectionTestLine.FindFirst();
        QltyInspectionTestLine.Validate("Test Value", SalespersonPurchaser.Code);
        QltyInspectionTestLine.Modify();

        // [GIVEN] The quality field record retrieved
        QltyField.Get(QltyInspectionTestLine."Field Code");

        // [WHEN] GetRecordsForTableField is called with different parameter combinations (field+header+line, field+header)
        QltyMiscHelpers.GetRecordsForTableField(QltyField, QltyInspectionTestHeader, QltyInspectionTestLine, TempBufferQltyLookupCode);

        // [THEN] The function returns the correct record using all parameter overloads
        LibraryAssert.AreEqual(1, TempBufferQltyLookupCode.Count(), 'should have been 1 record.');

        TempBufferQltyLookupCode.FindFirst();
        LibraryAssert.AreEqual(SalespersonPurchaser.Code, TempBufferQltyLookupCode.Code, 'first key should have been set');

        QltyMiscHelpers.GetRecordsForTableField(QltyField, QltyInspectionTestHeader, TempBufferQltyLookupCode);
        LibraryAssert.AreEqual(1, TempBufferQltyLookupCode.Count(), 'should have been 1 record.');

        TempBufferQltyLookupCode.FindFirst();
        LibraryAssert.AreEqual(SalespersonPurchaser.Code, TempBufferQltyLookupCode.Code, 'first key should have been set');
    end;

    [Test]
    procedure GetRecordsForTableFieldAsCSV()
    var
        User: Record User;
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        LookupQualityMeasureQltyField: Record "Qlty. Field";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        FirstSalespersonPurchaser: Record "Salesperson/Purchaser";
        SecondSalespersonPurchaser: Record "Salesperson/Purchaser";
        ThirdSalespersonPurchaser: Record "Salesperson/Purchaser";
        FilterSalespersonPurchaser: Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Item: Record Item;
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibrarySales: Codeunit "Library - Sales";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
        Output1: Text;
        Count: Integer;
        CountOfCommas: Integer;
    begin
        // [SCENARIO] Get records for table field as CSV string

        Initialize();

        // [GIVEN] A User with full name and contact email
        LibraryPermissions.CreateUser(User, '', false);
        User."Full Name" := CopyStr(Any.AlphanumericText(MaxStrLen(User."Full Name")), 1, MaxStrLen(User."Full Name"));
        User."Contact Email" := CopyStr(Any.Email(), 1, MaxStrLen(User."Contact Email"));
        User.Modify(false);

        // [GIVEN] Three Salesperson/Purchasers sharing the same email address
        LibrarySales.CreateSalesperson(FirstSalespersonPurchaser);
        FirstSalespersonPurchaser.Name := CopyStr(Any.AlphanumericText(MaxStrLen(User."Full Name")), 1, MaxStrLen(FirstSalespersonPurchaser.Name));
        FirstSalespersonPurchaser."Job Title" := 'TestGetRecordsForTableField';
        FirstSalespersonPurchaser."Phone No." := '+1-800-440-7543';
        FirstSalespersonPurchaser."E-Mail" := CopyStr(Any.Email(), 1, MaxStrLen(FirstSalespersonPurchaser."E-Mail"));
        FirstSalespersonPurchaser.Modify();
        FirstSalespersonPurchaser.SetRecFilter();

        LibrarySales.CreateSalesperson(SecondSalespersonPurchaser);
        SecondSalespersonPurchaser."E-Mail" := FirstSalespersonPurchaser."E-Mail";
        SecondSalespersonPurchaser.Modify(false);

        LibrarySales.CreateSalesperson(ThirdSalespersonPurchaser);
        ThirdSalespersonPurchaser."E-Mail" := FirstSalespersonPurchaser."E-Mail";
        ThirdSalespersonPurchaser.Modify(false);

        // [GIVEN] A filter on Salesperson/Purchaser for the shared email
        FilterSalespersonPurchaser.Reset();
        FilterSalespersonPurchaser.SetRange("E-Mail", FirstSalespersonPurchaser."E-Mail");

        // [GIVEN] A User Setup linked to the first Salesperson/Purchaser
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, User."User Name", '');
        UserSetup."Salespers./Purch. Code" := FirstSalespersonPurchaser.Code;
        UserSetup."E-Mail" := CopyStr(Any.Email(), 1, MaxStrLen(UserSetup."E-mail"));
        UserSetup."Phone No." := '+1-866-440-7543';
        UserSetup.Modify(false);

        QltyTestsUtility.EnsureSetup();

        // [GIVEN] Quality Management Setup with max rows field lookups set to 0 (unlimited)
        QltyManagementSetup.Get();
        QltyManagementSetup."Max Rows Field Lookups" := 0;
        QltyManagementSetup.Modify(false);

        // [GIVEN] A test template with table lookup field for Salesperson/Purchaser filtered by email
        QltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 2);
        QltyTestsUtility.CreateFieldAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, LookupQualityMeasureQltyField."Field Type"::"Field Type Table Lookup", LookupQualityMeasureQltyField, ConfigurationToLoadQltyInspectionTemplateLine);
        LookupQualityMeasureQltyField."Lookup Table No." := Database::"Salesperson/Purchaser";
        LookupQualityMeasureQltyField."Lookup Field No." := FilterSalespersonPurchaser.FieldNo(Code);
        LookupQualityMeasureQltyField."Lookup Table Filter" := CopyStr(FilterSalespersonPurchaser.GetView(), 1, maxstrlen(LookupQualityMeasureQltyField."Lookup Table Filter"));
        LookupQualityMeasureQltyField.Modify(false);

        // [GIVEN] A prioritized rule for production order routing line
        QltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order with routing line and inspection test created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);
        Item.Get(ProdProductionOrder."Source No.");

        QltyInspectionTestHeader.Reset();

        ClearLastError();
        QltyInspectionTestCreate.CreateTestWithVariant(ProdOrderRoutingLine, true);
        QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);

        // [GIVEN] A test line with the lookup field and test value set to the first Salesperson/Purchaser code
        QltyInspectionTestLine.SetRange("Test No.", QltyInspectionTestHeader."No.");
        QltyInspectionTestLine.SetRange("ReTest No.", QltyInspectionTestHeader."ReTest No.");
        QltyInspectionTestLine.SetRange("Field Code", LookupQualityMeasureQltyField.Code);

        LibraryAssert.AreEqual(1, QltyInspectionTestLine.Count(), 'there should  be exactly one test line that matches.');
        QltyInspectionTestLine.FindFirst();
        QltyInspectionTestLine.Validate("Test Value", FirstSalespersonPurchaser.Code);
        QltyInspectionTestLine.Modify();

        // [WHEN] GetRecordsForTableFieldAsCSV is called
        Output1 := QltyMiscHelpers.GetRecordsForTableFieldAsCSV(QltyInspectionTestLine);

        // [THEN] The function returns a comma-separated list of all matching codes with correct count
        Count := FilterSalespersonPurchaser.Count();
        CountOfCommas := StrLen(Output1) - strlen(DelChr(Output1, '=', ','));
        LibraryAssert.AreEqual(Count - 1, CountOfCommas, 'mismatch in expected records.');

        Output1 := ',' + Output1;
        LibraryAssert.IsTrue(StrPos(Output1, ',' + FirstSalespersonPurchaser.Code) > 0, 'demo record 1');
        LibraryAssert.IsTrue(StrPos(Output1, ',' + SecondSalespersonPurchaser.Code) > 0, 'demo record 2');
        LibraryAssert.IsTrue(StrPos(Output1, ',' + ThirdSalespersonPurchaser.Code) > 0, 'demo record 3');
    end;

    [Test]
    procedure GetTranslatedYes250()
    var
        QltyLocalization: Codeunit "Qlty. Localization";
    begin
        // [SCENARIO] Get translated "Yes" text value

        Initialize();

        // [WHEN] GetTranslatedYes250 is called
        // [THEN] The function returns the translated string "Yes"
        LibraryAssert.AreEqual('Yes', QltyLocalization.GetTranslatedYes250(), 'locked yes.');
    end;

    [Test]
    procedure GetTranslatedNo250()
    var
        QltyLocalization: Codeunit "Qlty. Localization";
    begin
        // [SCENARIO] Get translated "No" text value

        Initialize();

        // [WHEN] GetTranslatedNo250 is called
        // [THEN] The function returns the translated string "No"
        LibraryAssert.AreEqual('No', QltyLocalization.GetTranslatedNo250(), 'locked no.');
    end;

    [Test]
    procedure GuessDataTypeFromDescriptionAndValue_Description()
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        QltyFieldType: Enum "Qlty. Field Type";
    begin
        // [SCENARIO] Guess data type from description text

        Initialize();

        // [GIVEN] Various field descriptions with question words, keywords, or phrases
        // [WHEN] GuessDataTypeFromDescriptionAndValue is called with description (empty value)
        // [THEN] The function infers the correct data type from description patterns
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Boolean", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('Does the monkey eat bananas', ''), 'bool test 3');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Boolean", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('Have you eaten bananas', ''), 'bool test 4');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Boolean", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('Do the monkeys eat bananas', ''), 'bool test 5');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Boolean", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('Is the monkey eating a banana', ''), 'bool test 6');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Text", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('lot #', ''), 'lot 1');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Text", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('lot number', ''), 'lot 2');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Text", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('serial #', ''), 'serial 1');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Text", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('serial number', ''), 'serial 2');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Date", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('posting date', ''), 'date 1');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Date", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('another date orso', ''), 'date 2');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Date", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('another dATE orso', ''), 'date 2b');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Date", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('date something was seen.', ''), 'date 3');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Date", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('Date something was seen.', ''), 'date 3b case');
    end;

    [Test]
    procedure GuessDataTypeFromDescriptionAndValue_Values()
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        QltyLocalization: Codeunit "Qlty. Localization";
        QltyFieldType: Enum "Qlty. Field Type";
    begin
        // [SCENARIO] Guess data type from actual values

        Initialize();

        // [GIVEN] Various sample values (boolean, numeric, date, text)
        // [WHEN] GuessDataTypeFromDescriptionAndValue is called with value (empty description)
        // [THEN] The function infers the correct data type from value patterns
        LibraryAssert.AreEqual('No', QltyLocalization.GetTranslatedNo250(), 'locked no.');

        LibraryAssert.AreEqual(QltyFieldType::"Field Type Boolean", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('', 'true'), 'bool test 1');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Boolean", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('', 'false'), 'bool test 2');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Boolean", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('', 'TRUE'), 'bool test 1b');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Boolean", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('', 'FALSE'), 'bool test 2b');

        LibraryAssert.AreEqual(QltyFieldType::"Field Type Boolean", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('', ':selected:'), 'bool test document intelligence/form recognizer');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Boolean", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('', ':unselected:'), 'bool test document intelligence/form recognizer');

        LibraryAssert.AreEqual(QltyFieldType::"Field Type Decimal", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('', '1.0001'), 'decimal test 1');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Decimal", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('', '2'), 'decimal test 2');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Date", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('', Format(today())), 'date 1');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Date", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('', Format(DMY2Date(1, 1, 2000))), 'date 2 locale');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Date", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('', Format(DMY2Date(1, 1, 2000), 0, 9)), 'date 3 ISO 8601');
        LibraryAssert.AreEqual(QltyFieldType::"Field Type Text", QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue('', 'abc'), 'text 1');
    end;

    [Test]
    procedure IsNumericText()
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
    begin
        // [SCENARIO] Validate if text contains numeric values

        Initialize();

        // [GIVEN] Various text values (numbers, text, mixed content)
        // [WHEN] IsNumericText is called with each value
        // [THEN] The function returns true for numeric text, false for non-numeric text
        LibraryAssert.IsTrue(QltyMiscHelpers.IsNumericText('0'), 'zero');
        LibraryAssert.IsTrue(QltyMiscHelpers.IsNumericText('-1'), 'simple negative');
        LibraryAssert.IsTrue(QltyMiscHelpers.IsNumericText('1'), 'simple positive');
        LibraryAssert.IsTrue(QltyMiscHelpers.IsNumericText(format(123456789.1234)), 'lcoale format');
        LibraryAssert.IsTrue(QltyMiscHelpers.IsNumericText(format(123456789.1234, 0, 9)), 'ISO format');
        LibraryAssert.IsFalse(QltyMiscHelpers.IsNumericText('not a hot dog'), 'simple text');
        LibraryAssert.IsFalse(QltyMiscHelpers.IsNumericText('A1B2C3'), 'mixed');
        LibraryAssert.IsFalse(QltyMiscHelpers.IsNumericText('1+2+3=4'), 'formula');
    end;

    [Test]
    procedure NavigateToFindEntries()
    var
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        Navigate: TestPage Navigate;
    begin
        // [SCENARIO] Navigate to find entries from test header

        Initialize();

        // [GIVEN] A temporary test header with source document, item, lot, and serial number
        TempQltyInspectionTestHeader."No." := 'TESTSOURCE';
        TempQltyInspectionTestHeader."Source Document No." := 'MYDOC123';
        TempQltyInspectionTestHeader."Source Item No." := 'ITEMABC';
        TempQltyInspectionTestHeader."Source Lot No." := 'LOTDEF';
        TempQltyInspectionTestHeader."Source Serial No." := 'SERIALGHI';

        // [WHEN] NavigateToFindEntries is called
        Navigate.Trap();
        QltyMiscHelpers.NavigateToFindEntries(TempQltyInspectionTestHeader);

        // [THEN] The Navigate page opens with lot and serial number filters applied
        LibraryAssert.AreEqual('SERIALGHI', Navigate.SerialNoFilter.Value, 'serial filter got set');
        LibraryAssert.AreEqual('LOTDEF', Navigate.LotNoFilter.Value, 'lot filter got set');
    end;

    [Test]
    [HandlerFunctions('HandleModalPage_TestNavigateToSourceDocument')]
    procedure NavigateToSourceDocument()
    var
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        LibrarySales: Codeunit "Library - Sales";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        SalespersonPurchaserCard: TestPage "Salesperson/Purchaser Card";
    begin
        // [SCENARIO] Navigate to source document from test header

        Initialize();

        // [GIVEN] A temporary test header with source RecordId pointing to a Salesperson/Purchaser
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        TempQltyInspectionTestHeader."Source RecordId" := SalespersonPurchaser.RecordId();

        // [WHEN] NavigateToSourceDocument is called
        SalespersonPurchaserCard.Trap();
        QltyMiscHelpers.NavigateToSourceDocument(TempQltyInspectionTestHeader);

        // [THEN] The Salesperson/Purchaser card page opens and the handler validates the correct record
        LibraryAssert.AreEqual(FlagTestNavigateToSourceDocument, SalespersonPurchaser.Code, 'testing if a simple lookup page worked');
    end;

    [Test]
    procedure BlockTrackingTransaction_NoTests_ShouldNotPreventPosting()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LotNo: Code[20];
    begin
        // [SCENARIO] Block tracking transaction with no tests should not prevent posting

        Initialize();

        // [GIVEN] Quality Management setup ensured
        QltyTestsUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Location created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Lot-tracked item with number series created
        QltyTestsUtility.CreateLotTrackedItem(Item);

        // [GIVEN] Item journal template and batch configured
        if ItemJournalTemplate.Count() > 1 then
            ItemJournalTemplate.DeleteAll();
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        if not ItemJournalTemplate.FindFirst() then
            LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] First journal line with lot tracking created
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);

        LotNo := NoSeries.GetNextNo(Item."Lot Nos.");
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Modify();

        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine.Quantity);

        // [GIVEN] Quality Management setup configured with 'Any' conditional lot find behavior
        QltyManagementSetup."Conditional Lot Find Behavior" := QltyManagementSetup."Conditional Lot Find Behavior"::Any;
        QltyManagementSetup.Modify();

        // [GIVEN] No inspection tests exist in the system
        if not QltyInspectionTestHeader.IsEmpty() then
            QltyInspectionTestHeader.DeleteAll();

        // [WHEN] Posting with 'Any' behavior and no tests
        ItemJnlPostBatch.Run(ItemJournalLine);

        // [THEN] Posting succeeds without error
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        LibraryAssert.IsTrue(ItemLedgerEntry.Count() = 1, 'Should be one ledger entry.');

        // [GIVEN] Second journal line with new lot tracking created
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);

        LotNo := NoSeries.GetNextNo(Item."Lot Nos.");
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Modify();

        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine.Quantity);

        // [GIVEN] Quality Management setup configured with 'AnyFinished' conditional lot find behavior
        QltyManagementSetup."Conditional Lot Find Behavior" := QltyManagementSetup."Conditional Lot Find Behavior"::AnyFinished;
        QltyManagementSetup.Modify();

        // [GIVEN] No inspection tests exist
        if not QltyInspectionTestHeader.IsEmpty() then
            QltyInspectionTestHeader.DeleteAll();

        // [WHEN] Posting with 'AnyFinished' behavior and no tests
        ItemJnlPostBatch.Run(ItemJournalLine);

        // [THEN] Posting succeeds without error
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        LibraryAssert.IsTrue(ItemLedgerEntry.Count() = 1, 'Should be one ledger entry.');

        // [GIVEN] Third journal line with new lot tracking created
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);

        LotNo := NoSeries.GetNextNo(Item."Lot Nos.");
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Modify();

        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine.Quantity);

        // [GIVEN] Quality Management setup configured with 'HighestFinishedRetestNumber' conditional lot find behavior
        QltyManagementSetup."Conditional Lot Find Behavior" := QltyManagementSetup."Conditional Lot Find Behavior"::HighestFinishedRetestNumber;
        QltyManagementSetup.Modify();

        // [GIVEN] No inspection tests exist
        if not QltyInspectionTestHeader.IsEmpty() then
            QltyInspectionTestHeader.DeleteAll();

        // [WHEN] Posting with 'HighestFinishedRetestNumber' behavior and no tests
        ItemJnlPostBatch.Run(ItemJournalLine);

        // [THEN] Posting succeeds without error
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        LibraryAssert.IsTrue(ItemLedgerEntry.Count() = 1, 'Should be one ledger entry.');

        // [GIVEN] Fourth journal line with new lot tracking created
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);

        LotNo := NoSeries.GetNextNo(Item."Lot Nos.");
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Modify();

        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine.Quantity);

        // [GIVEN] Quality Management setup configured with 'HighestRetestNumber' conditional lot find behavior
        QltyManagementSetup."Conditional Lot Find Behavior" := QltyManagementSetup."Conditional Lot Find Behavior"::HighestRetestNumber;
        QltyManagementSetup.Modify();

        // [GIVEN] No inspection tests exist
        if not QltyInspectionTestHeader.IsEmpty() then
            QltyInspectionTestHeader.DeleteAll();

        // [WHEN] Posting with 'HighestRetestNumber' behavior and no tests
        ItemJnlPostBatch.Run(ItemJournalLine);

        // [THEN] Posting succeeds without error
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        LibraryAssert.IsTrue(ItemLedgerEntry.Count() = 1, 'Should be one ledger entry.');

        // [GIVEN] Fifth journal line with new lot tracking created
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);

        LotNo := NoSeries.GetNextNo(Item."Lot Nos.");
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Modify();

        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine.Quantity);

        // [GIVEN] Quality Management setup configured with 'MostRecentFinishedModified' conditional lot find behavior
        QltyManagementSetup."Conditional Lot Find Behavior" := QltyManagementSetup."Conditional Lot Find Behavior"::MostRecentFinishedModified;
        QltyManagementSetup.Modify();

        // [GIVEN] No inspection tests exist
        if not QltyInspectionTestHeader.IsEmpty() then
            QltyInspectionTestHeader.DeleteAll();

        // [WHEN] Posting with 'MostRecentFinishedModified' behavior and no tests
        ItemJnlPostBatch.Run(ItemJournalLine);

        // [THEN] Posting succeeds without error
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        LibraryAssert.IsTrue(ItemLedgerEntry.Count() = 1, 'Should be one ledger entry.');

        // [GIVEN] Sixth journal line with new lot tracking created
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);

        LotNo := NoSeries.GetNextNo(Item."Lot Nos.");
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Modify();

        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine.Quantity);

        // [GIVEN] Quality Management setup configured with 'MostRecentModified' conditional lot find behavior
        QltyManagementSetup."Conditional Lot Find Behavior" := QltyManagementSetup."Conditional Lot Find Behavior"::MostRecentModified;
        QltyManagementSetup.Modify();

        // [GIVEN] No inspection tests exist
        if not QltyInspectionTestHeader.IsEmpty() then
            QltyInspectionTestHeader.DeleteAll();

        // [WHEN] Posting with 'MostRecentModified' behavior and no tests
        ItemJnlPostBatch.Run(ItemJournalLine);

        // [THEN] Posting succeeds without error - all 6 behaviors allow posting when no tests exist
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        LibraryAssert.IsTrue(ItemLedgerEntry.Count() = 1, 'Should be one ledger entry.');
    end;

    [Test]
    procedure BlockTrackingTransaction_AssemblyConsumption_AnyFinished_ShouldError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        AssemblyItem: Record Item;
        ComponentItem: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ReservationEntry: Record "Reservation Entry";
        ToUseNoSeries: Record "No. Series";
        ToUseNoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LotNo: Code[20];
    begin
        // [SCENARIO] Block assembly consumption with AnyFinished behavior should error

        Initialize();

        // [GIVEN] Item journal template and batch prepared
        if ItemJournalTemplate.Count() > 1 then
            ItemJournalTemplate.DeleteAll();
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        if not ItemJournalTemplate.FindFirst() then
            LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] Quality Management setup ensured
        QltyTestsUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Location created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Quality Management setup with AnyFinished conditional lot find behavior
        QltyManagementSetup."Conditional Lot Find Behavior" := QltyManagementSetup."Conditional Lot Find Behavior"::AnyFinished;
        QltyManagementSetup.Modify();

        // [GIVEN] Assembly item with one lot-tracked component created
        LibraryAssembly.SetupAssemblyItem(AssemblyItem, Enum::"Costing Method"::Standard, Enum::"Costing Method"::Standard, Enum::"Replenishment System"::Assembly, Location.Code, false, 1, 0, 0, 1);

        // [GIVEN] Assembly order created for 10 units
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalcDate('<+10D>', WorkDate()), AssemblyItem."No.", Location.Code, 10, '');

        AssemblyLine.Get(AssemblyHeader."Document Type", AssemblyHeader."No.", 10000);

        // [GIVEN] Lot tracking code assigned to the component item
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, false);
        ComponentItem.Get(AssemblyLine."No.");
        ComponentItem.Validate("Item Tracking Code", ItemTrackingCode.Code);
        ComponentItem.Modify();

        // [GIVEN] Item journal line created for positive adjustment of component
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", AssemblyLine."No.", AssemblyLine."Quantity (Base)");
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Modify(true);

        // [GIVEN] No series for lot number generation
        LibraryUtility.CreateNoSeries(ToUseNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(ToUseNoSeriesLine, ToUseNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LotNo := NoSeries.GetNextNo(ToUseNoSeries.Code);

        // [GIVEN] Lot number generated and tracking created for journal line
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine.Quantity);

        // [GIVEN] Item journal posted to create inventory
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);

        // [GIVEN] Assembly line linked to the lot via item tracking
        LibraryItemTracking.CreateAssemblyLineItemTracking(ReservationEntry, AssemblyLine, '', LotNo, AssemblyLine."Quantity (Base)");

        // [GIVEN] Inspection grade configured to block assembly consumption
        ToLoadQltyInspectionGrade.FindFirst();
        QltyTestsUtility.ClearGradeLotSettings(ToLoadQltyInspectionGrade);
        ToLoadQltyInspectionGrade."Lot Allow Assembly Consumption" := ToLoadQltyInspectionGrade."Lot Allow Assembly Consumption"::Block;
        ToLoadQltyInspectionGrade.Modify();

        // [GIVEN] Finished inspection test created for the component lot with blocking grade
        QltyInspectionTestHeader.Init();
        QltyInspectionTestHeader."Source Item No." := ComponentItem."No.";
        QltyInspectionTestHeader."Source Lot No." := LotNo;
        QltyInspectionTestHeader."Source Quantity (Base)" := AssemblyLine."Quantity (Base)";
        QltyInspectionTestHeader.Insert(true);

        QltyInspectionTestHeader."Grade Code" := ToLoadQltyInspectionGrade.Code;
        QltyInspectionTestHeader.Status := QltyInspectionTestHeader.Status::Finished;
        QltyInspectionTestHeader.Modify();

        // [WHEN] Posting the assembly order
        // [THEN] An error is raised indicating assembly consumption is blocked by the grade
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, StrSubstNo(
            EntryTypeBlocked2Err,
            QltyInspectionTestHeader.GetFriendlyIdentifier(),
            ToLoadQltyInspectionGrade.Code,
            ItemJournalLine."Entry Type"::"Assembly Consumption",
            ComponentItem."No.",
            LotNo));
    end;

    [Test]
    procedure BlockTrackingTransaction_Purchase_HighestRetestNumber_ShouldError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ReQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // [SCENARIO] Block purchase with HighestRetestNumber behavior should error

        Initialize();

        // [GIVEN] Inspection grades cleared
        if not ToLoadQltyInspectionGrade.IsEmpty() then
            ToLoadQltyInspectionGrade.DeleteAll();

        // [GIVEN] Quality Management setup ensured
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] Prioritized test generation rule for Purchase Line created
        QltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] Package-tracked item with no series created
        QltyTestsUtility.CreatePackageTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [GIVEN] Purchase order with package tracking created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] Inspection test created for purchase line with tracking
        QltyTestsUtility.CreateTestWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionTestHeader);

        // [GIVEN] Retest created from original inspection test
        QltyInspectionTestCreate.CreateRetest(QltyInspectionTestHeader, ReQltyInspectionTestHeader);

        // [GIVEN] Inspection grade configured to block purchase
        ToLoadQltyInspectionGrade.FindFirst();
        QltyTestsUtility.ClearGradeLotSettings(ToLoadQltyInspectionGrade);
        ToLoadQltyInspectionGrade."Lot Allow Purchase" := ToLoadQltyInspectionGrade."Lot Allow Purchase"::Block;
        ToLoadQltyInspectionGrade.Modify();

        // [GIVEN] Retest assigned the blocking grade
        ReQltyInspectionTestHeader."Grade Code" := ToLoadQltyInspectionGrade.Code;
        ReQltyInspectionTestHeader.Modify();

        // [GIVEN] Quality Management setup with HighestRetestNumber conditional lot find behavior
        QltyManagementSetup.Get();
        QltyManagementSetup."Conditional Lot Find Behavior" := QltyManagementSetup."Conditional Lot Find Behavior"::HighestRetestNumber;
        QltyManagementSetup.Modify();

        // [GIVEN] Test generation rule deleted to prevent new test creation
        QltyInTestGenerationRule.Delete();

        // [WHEN] Posting the purchase document
        // [THEN] An error is raised indicating purchase is blocked by the grade on the highest retest
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        LibraryAssert.ExpectedError(StrSubstNo(EntryTypeBlocked2Err,
            ReQltyInspectionTestHeader.GetFriendlyIdentifier(),
            ToLoadQltyInspectionGrade.Code,
            ItemJournalLine."Entry Type"::Purchase,
            PurchaseLine."No.",
            ReservationEntry."Package No."));
    end;

    [Test]
    procedure BlockTrackingTransaction_AssemblyOutput_MostRecentFinishedModified_ShouldError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ReQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        AssemblyHeader: Record "Assembly Header";
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        ToUseNoSeries: Record "No. Series";
        ToUseNoSeriesLine: Record "No. Series Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        NoSeries: Codeunit "No. Series";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        RecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        LotNo: Code[50];
        SerialNo: Code[50];
        ConfigCode: Text;
    begin
        // [SCENARIO] Block assembly output with MostRecentFinishedModified behavior should error

        Initialize();

        // [GIVEN] No series for generating unique template names created
        LibraryUtility.CreateNoSeries(ToUseNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(ToUseNoSeriesLine, ToUseNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'A0SM-A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'A0SM-A<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));

        // [GIVEN] Custom item journal template cleared and created
        ItemJournalTemplate.Reset();
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.SetFilter(Name, 'A0SM-A*');
        ItemJournalTemplate.DeleteAll(false);
        ItemJournalTemplate.Init();
        ItemJournalTemplate.Validate(Name, CopyStr(NoSeries.GetNextNo(ToUseNoSeries.Code), 1, MaxStrLen(ItemJournalTemplate.Name)));

        ItemJournalTemplate.Validate(Description, ItemJournalTemplate.Name);
        ItemJournalTemplate.Insert(true);
        LibraryAssembly.SetupItemJournal(ItemJournalTemplate, ItemJournalBatch);

        // [GIVEN] Quality Management setup ensured
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] Inspection template with 3 characteristics created
        QltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 3);

        // [GIVEN] Prioritized test generation rule for Assembly Header created
        QltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Assembly Header", QltyInTestGenerationRule);

        // [GIVEN] Custom inspection source configuration for Assembly Header to Test created
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(SpecificQltyInspectSourceConfig.Code), ConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::"Assembly Header");
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::Test;
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Qlty. Inspection Test Header");
        SpecificQltyInspectSourceConfig.Insert();

        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := AssemblyHeader.FieldNo("Item No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Item No.");
        SpecificQltyInspectSrcFldConf.Insert();

        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := AssemblyHeader.FieldNo("No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Document No.");
        SpecificQltyInspectSrcFldConf.Insert();

        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := AssemblyHeader.FieldNo("Document Type");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Type");
        SpecificQltyInspectSrcFldConf.Insert();

        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := AssemblyHeader.FieldNo("Quantity to Assemble (Base)");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Quantity (Base)");
        SpecificQltyInspectSrcFldConf.Insert();

        // [GIVEN] Location created
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Lot and serial tracked assembly item created
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, true, false);
        LibraryAssembly.SetupAssemblyItem(Item, Enum::"Costing Method"::Standard, Enum::"Costing Method"::Standard, Enum::"Replenishment System"::Assembly, Location.Code, false, 2, 1, 1, 1);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify();

        // [GIVEN] Assembly order for 1 unit created with lot and serial tracking
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, CalcDate('<+10D>', WorkDate()), Item."No.", Location.Code, 1, '');
        LotNo := NoSeries.GetNextNo(ToUseNoSeries.Code);
        SerialNo := NoSeries.GetNextNo(ToUseNoSeries.Code);
        LibraryItemTracking.CreateAssemblyHeaderItemTracking(ReservationEntry, AssemblyHeader, SerialNo, LotNo, AssemblyHeader."Quantity (Base)");

        ItemJournalBatch."No. Series" := ToUseNoSeries.Code;
        ItemJournalBatch.Modify();
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate(), 0);

        // [GIVEN] Inspection test created from assembly header with tracking
        RecordRef.GetTable(AssemblyHeader);
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
        QltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '');
        QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);

        // [GIVEN] Retest created from original test
        QltyInspectionTestCreate.CreateRetest(QltyInspectionTestHeader, ReQltyInspectionTestHeader);

        // [GIVEN] Inspection grade configured to block assembly output
        ToLoadQltyInspectionGrade.FindFirst();
        QltyTestsUtility.ClearGradeLotSettings(ToLoadQltyInspectionGrade);
        ToLoadQltyInspectionGrade."Lot Allow Assembly Output" := ToLoadQltyInspectionGrade."Lot Allow Assembly Output"::Block;
        ToLoadQltyInspectionGrade.Modify();

        // [GIVEN] Retest marked as finished with blocking grade
        ReQltyInspectionTestHeader."Grade Code" := ToLoadQltyInspectionGrade.Code;
        ReQltyInspectionTestHeader.Status := ReQltyInspectionTestHeader.Status::Finished;
        ReQltyInspectionTestHeader.Modify();
        QltyInspectionTestHeader.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.");
        Commit();

        // [GIVEN] Sleep to ensure modified timestamp is different
        Sleep(1001);

        // [GIVEN] Quality Management setup with MostRecentFinishedModified conditional lot find behavior
        QltyManagementSetup.Get();
        QltyManagementSetup."Conditional Lot Find Behavior" := QltyManagementSetup."Conditional Lot Find Behavior"::MostRecentFinishedModified;
        QltyManagementSetup.Modify();

        // [GIVEN] Test generation rule deleted to prevent new test creation
        QltyInTestGenerationRule.Delete();

        // [GIVEN] Original test also marked as finished with blocking grade (most recent modified)
        QltyInspectionTestHeader."Grade Code" := ToLoadQltyInspectionGrade.Code;
        QltyInspectionTestHeader.Status := QltyInspectionTestHeader.Status::Finished;
        QltyInspectionTestHeader.Modify();

        // [WHEN] Posting the assembly header
        // [THEN] An error is raised indicating assembly output is blocked by the most recent finished modified test grade
        EnsureGenPostingSetupExistsForAssembly(AssemblyHeader);
        asserterror LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        LibraryAssert.ExpectedError(StrSubstNo(
            EntryTypeBlocked2Err,
            QltyInspectionTestHeader.GetFriendlyIdentifier(),
            ToLoadQltyInspectionGrade.Code,
            ItemJournalLine."Entry Type"::"Assembly Output",
            AssemblyHeader."Item No.",
            StrSubstNo(TrackingDetailsTok, ReservationEntry."Lot No.", ReservationEntry."Serial No.")));
    end;

    [Test]
    procedure BlockTrackingWarehouseTransaction_Putaway_HighestFinishedRetest_ShouldError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ReQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        ToUseNoSeries: Record "No. Series";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // [SCENARIO] Block warehouse put-away with HighestFinishedRetest behavior should error

        Initialize();

        // [GIVEN] Test generation rules cleared
        QltyInTestGenerationRule.DeleteAll();

        // [GIVEN] Inspection grades cleared
        if not ToLoadQltyInspectionGrade.IsEmpty() then
            ToLoadQltyInspectionGrade.DeleteAll();

        // [GIVEN] Quality Management setup ensured
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] Prioritized test generation rule for Purchase Line created
        QltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] Full WMS location with 1 zone created
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);

        // [GIVEN] Lot-tracked item with no series created
        QltyTestsUtility.CreateLotTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] Purchase order with lot tracking created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] Inspection test created for purchase line with tracking
        QltyTestsUtility.CreateTestWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionTestHeader);

        // [GIVEN] Retest created from original inspection test
        QltyInspectionTestCreate.CreateRetest(QltyInspectionTestHeader, ReQltyInspectionTestHeader);

        // [GIVEN] Inspection grade configured to block put-away
        ToLoadQltyInspectionGrade.FindFirst();
        QltyTestsUtility.ClearGradeLotSettings(ToLoadQltyInspectionGrade);
        ToLoadQltyInspectionGrade."Lot Allow Put-Away" := ToLoadQltyInspectionGrade."Lot Allow Put-Away"::Block;
        ToLoadQltyInspectionGrade.Modify();

        // [GIVEN] Original test marked as finished with blocking grade
        QltyInspectionTestHeader."Grade Code" := ToLoadQltyInspectionGrade.Code;
        QltyInspectionTestHeader.Status := QltyInspectionTestHeader.Status::Finished;
        QltyInspectionTestHeader.Modify();

        // [GIVEN] Retest assigned the blocking grade (highest finished retest)
        ReQltyInspectionTestHeader."Grade Code" := ToLoadQltyInspectionGrade.Code;
        ReQltyInspectionTestHeader.Modify();

        // [GIVEN] Quality Management setup with HighestFinishedRetestNumber conditional lot find behavior
        QltyManagementSetup.Get();
        QltyManagementSetup."Conditional Lot Find Behavior" := QltyManagementSetup."Conditional Lot Find Behavior"::HighestFinishedRetestNumber;
        QltyManagementSetup.Modify();

        // [WHEN] Receiving the purchase order
        // [THEN] An error is raised indicating put-away is blocked by the highest finished retest grade
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        asserterror QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        LibraryAssert.ExpectedError(StrSubstNo(
            EntryTypeBlockedErr,
            QltyInspectionTestHeader.GetFriendlyIdentifier(),
            ToLoadQltyInspectionGrade.Code,
            WarehouseActivityLine."Activity Type"::"Put-away",
            Item."No.",
            ReservationEntry."Lot No.",
            ''))
    end;

    [Test]
    procedure BlockTrackingWarehouseTransaction_Putaway_AnyFinished_ShouldError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        ToUseNoSeries: Record "No. Series";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // [SCENARIO] Block warehouse put-away with AnyFinished behavior should error

        Initialize();

        // [GIVEN] Test generation rules cleared
        QltyInTestGenerationRule.DeleteAll();

        // [GIVEN] Inspection grades cleared
        if not ToLoadQltyInspectionGrade.IsEmpty() then
            ToLoadQltyInspectionGrade.DeleteAll();

        // [GIVEN] Quality Management setup ensured
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] Prioritized test generation rule for Purchase Line created
        QltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] Full WMS location with 1 zone created
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);

        // [GIVEN] Lot-tracked item with no series created
        QltyTestsUtility.CreateLotTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] Purchase order with lot tracking created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] Inspection test created for purchase line with tracking
        QltyTestsUtility.CreateTestWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionTestHeader);

        // [GIVEN] Inspection grade configured to block put-away
        ToLoadQltyInspectionGrade.FindFirst();
        QltyTestsUtility.ClearGradeLotSettings(ToLoadQltyInspectionGrade);
        ToLoadQltyInspectionGrade."Lot Allow Put-Away" := ToLoadQltyInspectionGrade."Lot Allow Put-Away"::Block;
        ToLoadQltyInspectionGrade.Modify();

        // [GIVEN] Inspection test marked as finished with blocking grade
        QltyInspectionTestHeader."Grade Code" := ToLoadQltyInspectionGrade.Code;
        QltyInspectionTestHeader.Status := QltyInspectionTestHeader.Status::Finished;
        QltyInspectionTestHeader.Modify();

        // [GIVEN] Quality Management setup with AnyFinished conditional lot find behavior
        QltyManagementSetup.Get();
        QltyManagementSetup."Conditional Lot Find Behavior" := QltyManagementSetup."Conditional Lot Find Behavior"::AnyFinished;
        QltyManagementSetup.Modify();

        // [WHEN] Receiving the purchase order
        // [THEN] An error is raised indicating put-away is blocked by any finished test grade
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        asserterror QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        LibraryAssert.ExpectedError(StrSubstNo(
            EntryTypeBlockedErr,
            QltyInspectionTestHeader.GetFriendlyIdentifier(),
            ToLoadQltyInspectionGrade.Code,
            WarehouseActivityLine."Activity Type"::"Put-away",
            Item."No.",
            ReservationEntry."Lot No.",
            ''))
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BlockTrackingWarehouseTransaction_InvPutaway_MostRecentFinishedModified_ShouldError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ReQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        Bin: Record Bin;
        ReservationEntry: Record "Reservation Entry";
        ToUseNoSeries: Record "No. Series";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // [SCENARIO] Block warehouse inventory put-away with MostRecentFinishedModified behavior should error

        Initialize();

        // [GIVEN] Test generation rules cleared
        QltyInTestGenerationRule.DeleteAll();

        // [GIVEN] Inspection grades cleared
        if not ToLoadQltyInspectionGrade.IsEmpty() then
            ToLoadQltyInspectionGrade.DeleteAll();

        // [GIVEN] Quality Management setup ensured
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] Prioritized test generation rule for Purchase Line created (then cleared)
        QltyInTestGenerationRule.DeleteAll();
        QltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] WMS location with bins created
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, false, false);

        LibraryWarehouse.CreateBin(Bin, Location.Code, 'Bin', '', '');

        // [GIVEN] Lot-tracked item with no series created
        QltyTestsUtility.CreateLotTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] Purchase order with lot tracking created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] Inspection test created for purchase line with tracking
        QltyTestsUtility.CreateTestWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionTestHeader);

        // [GIVEN] Purchase line with bin code assigned
        PurchaseLine."Bin Code" := Bin.Code;
        PurchaseLine.Modify();

        // [GIVEN] Retest created from original inspection test
        QltyInspectionTestCreate.CreateRetest(QltyInspectionTestHeader, ReQltyInspectionTestHeader);

        // [GIVEN] Inspection grade configured to block inventory put-away
        ToLoadQltyInspectionGrade.FindFirst();
        QltyTestsUtility.ClearGradeLotSettings(ToLoadQltyInspectionGrade);
        ToLoadQltyInspectionGrade."Lot Allow Invt. Put-Away" := ToLoadQltyInspectionGrade."Lot Allow Invt. Put-Away"::Block;
        ToLoadQltyInspectionGrade.Modify();

        // [GIVEN] Retest marked as finished with blocking grade
        ReQltyInspectionTestHeader."Grade Code" := ToLoadQltyInspectionGrade.Code;
        ReQltyInspectionTestHeader.Status := QltyInspectionTestHeader.Status::Finished;
        ReQltyInspectionTestHeader.Modify();
        QltyInspectionTestHeader.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.");
        Commit();

        // [GIVEN] Quality Management setup with MostRecentFinishedModified conditional lot find behavior
        QltyManagementSetup.Get();

        // [GIVEN] Setup trigger defaults cleared
        QltyTestsUtility.ClearSetupTriggerDefaults(QltyManagementSetup);
        QltyManagementSetup."Conditional Lot Find Behavior" := QltyManagementSetup."Conditional Lot Find Behavior"::MostRecentFinishedModified;
        QltyManagementSetup.Modify();

        // [GIVEN] Original test also marked as finished with blocking grade (most recent modified)
        QltyInspectionTestHeader."Grade Code" := ToLoadQltyInspectionGrade.Code;
        QltyInspectionTestHeader.Status := QltyInspectionTestHeader.Status::Finished;
        QltyInspectionTestHeader.Modify();

        // [WHEN] Receiving the purchase order
        // [THEN] An error is raised indicating inventory put-away is blocked by the most recent finished modified test grade
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        asserterror QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        LibraryAssert.ExpectedError(StrSubstNo(
            EntryTypeBlockedErr,
            QltyInspectionTestHeader.GetFriendlyIdentifier(),
            ToLoadQltyInspectionGrade.Code,
            WarehouseActivityLine."Activity Type"::"Invt. Put-away",
            Item."No.",
            ReservationEntry."Lot No.",
            ''))
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BlockTrackingWarehouseTransaction_InvMovement_HighestRetest_ShouldError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ReQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        Bin: Record Bin;
        ReservationEntry: Record "Reservation Entry";
        ToUseNoSeries: Record "No. Series";
        InventorySetup: Record "Inventory Setup";
        InventoryMovementWarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // [SCENARIO] Block warehouse inventory movement with HighestRetest behavior should error

        Initialize();

        // [GIVEN] Test generation rules cleared
        QltyInTestGenerationRule.DeleteAll();

        // [GIVEN] Inspection grades cleared
        if not ToLoadQltyInspectionGrade.IsEmpty() then
            ToLoadQltyInspectionGrade.DeleteAll();

        // [GIVEN] Quality Management setup ensured
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] Prioritized test generation rule for Purchase Line created
        QltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] WMS location with bins created
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, false, false);

        // [GIVEN] Current warehouse employee set for the location
        QltyTestsUtility.SetCurrLocationWhseEmployee(Location.Code);

        // [GIVEN] Two bins created (Bin1 and Bin2)
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin1Tok, '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin2Tok, '', '');

        // [GIVEN] Lot-tracked item with no series created
        QltyTestsUtility.CreateLotTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] Purchase order with lot tracking created and assigned to Bin1
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        PurchaseLine."Bin Code" := Bin1Tok;
        PurchaseLine.Modify();

        // [GIVEN] Purchase order released and received
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] Inspection test created for purchase line with tracking
        QltyTestsUtility.CreateTestWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionTestHeader);

        // [GIVEN] Retest created from original inspection test
        QltyInspectionTestCreate.CreateRetest(QltyInspectionTestHeader, ReQltyInspectionTestHeader);

        // [GIVEN] Inspection grade configured to block inventory movement
        ToLoadQltyInspectionGrade.FindFirst();
        QltyTestsUtility.ClearGradeLotSettings(ToLoadQltyInspectionGrade);
        ToLoadQltyInspectionGrade."Lot Allow Invt. Movement" := ToLoadQltyInspectionGrade."Lot Allow Invt. Movement"::Block;
        ToLoadQltyInspectionGrade.Modify();

        // [GIVEN] Retest marked as finished with blocking grade
        ReQltyInspectionTestHeader."Grade Code" := ToLoadQltyInspectionGrade.Code;
        ReQltyInspectionTestHeader.Status := QltyInspectionTestHeader.Status::Finished;
        ReQltyInspectionTestHeader.Modify();
        Commit();
        Sleep(1001);

        // [GIVEN] Quality Management setup with HighestRetestNumber conditional lot find behavior
        QltyManagementSetup.Get();
        QltyManagementSetup."Conditional Lot Find Behavior" := QltyManagementSetup."Conditional Lot Find Behavior"::HighestRetestNumber;
        QltyManagementSetup.Modify();

        // [GIVEN] Inventory setup with no series configured
        LibraryInventory.NoSeriesSetup(InventorySetup);

        // [GIVEN] Inventory movement header created for the location
        LibraryWarehouse.CreateInventoryMovementHeader(InventoryMovementWarehouseActivityHeader, Location.Code);

        // [GIVEN] Inventory movement line with Take action from Bin1
        WarehouseActivityLine.Init();
        WarehouseActivityLine.Validate("Activity Type", InventoryMovementWarehouseActivityHeader.Type);
        WarehouseActivityLine.Validate("No.", InventoryMovementWarehouseActivityHeader."No.");
        WarehouseActivityLine."Line No." := 10000;
        WarehouseActivityLine.Validate("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.Validate("Item No.", Item."No.");
        WarehouseActivityLine.Validate("Lot No.", ReservationEntry."Lot No.");
        WarehouseActivityLine.Validate("Location Code", InventoryMovementWarehouseActivityHeader."Location Code");
        WarehouseActivityLine.Validate("Bin Code", Bin1Tok);
        WarehouseActivityLine.Validate(Quantity, PurchaseLine.Quantity);
        WarehouseActivityLine.Insert();

        // [GIVEN] Inventory movement line with Place action to Bin2
        Clear(WarehouseActivityLine);
        WarehouseActivityLine.Init();
        WarehouseActivityLine.Validate("Activity Type", InventoryMovementWarehouseActivityHeader.Type);
        WarehouseActivityLine.Validate("No.", InventoryMovementWarehouseActivityHeader."No.");
        WarehouseActivityLine."Line No." := 20000;
        WarehouseActivityLine.Validate("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.Validate("Item No.", Item."No.");
        WarehouseActivityLine.Validate("Lot No.", ReservationEntry."Lot No.");
        WarehouseActivityLine.Validate("Location Code", InventoryMovementWarehouseActivityHeader."Location Code");
        WarehouseActivityLine.Validate("Bin Code", Bin2Tok);
        WarehouseActivityLine.Validate(Quantity, PurchaseLine.Quantity);
        WarehouseActivityLine.Insert();

        // [GIVEN] Original test also marked as finished with blocking grade
        QltyInspectionTestHeader.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.");
        QltyInspectionTestHeader."Grade Code" := ToLoadQltyInspectionGrade.Code;
        QltyInspectionTestHeader.Status := QltyInspectionTestHeader.Status::Finished;
        QltyInspectionTestHeader.Modify();

        // [WHEN] Registering the warehouse inventory movement
        // [THEN] An error is raised indicating inventory movement is blocked by the highest retest grade
        asserterror LibraryWarehouse.RegisterWhseActivity(InventoryMovementWarehouseActivityHeader);
        LibraryAssert.ExpectedError(StrSubstNo(
            EntryTypeBlockedErr,
            ReQltyInspectionTestHeader.GetFriendlyIdentifier(),
            ToLoadQltyInspectionGrade.Code,
            WarehouseActivityLine."Activity Type"::"Invt. Movement",
            Item."No.",
            ReservationEntry."Lot No.",
            ''))
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BlockTrackingWarehouseTransaction_Movement_MostRecentModified_ShouldError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        ToLoadQltyInspectionGrade: Record "Qlty. Inspection Grade";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ReQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        WarehouseEntry: Record "Warehouse Entry";
        InitialBin: Record Bin;
        DestinationBin: Record Bin;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        ReservationEntry: Record "Reservation Entry";
        ToUseNoSeries: Record "No. Series";
        WhseMovementWarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        WhseWorksheetTemplateToUse: Text;
    begin
        // [SCENARIO] Block warehouse movement with MostRecentModified behavior should error

        Initialize();

        // [GIVEN] Test generation rules cleared
        QltyInTestGenerationRule.DeleteAll();

        // [GIVEN] Inspection grades cleared
        if not ToLoadQltyInspectionGrade.IsEmpty() then
            ToLoadQltyInspectionGrade.DeleteAll();

        // [GIVEN] Quality Management setup ensured
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] Prioritized test generation rule for Purchase Line created
        QltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] Full WMS location with 2 zones created
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        // [GIVEN] Current warehouse employee set for the location
        QltyTestsUtility.SetCurrLocationWhseEmployee(Location.Code);

        // [GIVEN] Lot-tracked item with no series created
        QltyTestsUtility.CreateLotTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] Purchase order with lot tracking created, released and received
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] Inspection test created for purchase line with tracking
        QltyTestsUtility.CreateTestWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionTestHeader);

        // [GIVEN] Retest created from original inspection test
        QltyInspectionTestCreate.CreateRetest(QltyInspectionTestHeader, ReQltyInspectionTestHeader);

        // [GIVEN] Inspection grade configured to block movement
        ToLoadQltyInspectionGrade.FindFirst();
        QltyTestsUtility.ClearGradeLotSettings(ToLoadQltyInspectionGrade);
        ToLoadQltyInspectionGrade."Lot Allow Movement" := ToLoadQltyInspectionGrade."Lot Allow Movement"::Block;
        ToLoadQltyInspectionGrade.Modify();

        // [GIVEN] Retest marked as finished with blocking grade
        ReQltyInspectionTestHeader."Grade Code" := ToLoadQltyInspectionGrade.Code;
        ReQltyInspectionTestHeader.Status := ReQltyInspectionTestHeader.Status::Finished;
        ReQltyInspectionTestHeader.Modify();
        QltyInspectionTestHeader.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.");
        Commit();

        // [GIVEN] Warehouse entry identified (Movement type, not in RECEIVE zone)
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();

        // [GIVEN] Initial bin determined from warehouse entry
        InitialBin.Get(Location.Code, WarehouseEntry."Bin Code");

        // [GIVEN] Destination bin determined (PICK zone, different from initial bin)
        DestinationBin.SetRange("Location Code", Location.Code);
        DestinationBin.SetRange("Zone Code", 'PICK');
        DestinationBin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        DestinationBin.FindFirst();

        // [GIVEN] Quality Management setup with MostRecentModified conditional lot find behavior
        QltyManagementSetup.Get();
        QltyManagementSetup."Conditional Lot Find Behavior" := QltyManagementSetup."Conditional Lot Find Behavior"::MostRecentModified;
        QltyManagementSetup.Modify();

        // [GIVEN] Original test assigned the blocking grade (most recent modified)
        QltyInspectionTestHeader."Grade Code" := ToLoadQltyInspectionGrade.Code;
        QltyInspectionTestHeader.Modify();

        // [GIVEN] Warehouse worksheet template for Movement type ensured
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Movement);
        if WhseWorksheetTemplate.IsEmpty() then begin
            QltyTestsUtility.GenerateRandomCharacters(10, WhseWorksheetTemplateToUse);
            WhseWorksheetTemplate.Name := CopyStr(WhseWorksheetTemplateToUse, 1, MaxStrLen(WhseWorksheetTemplate.Name));
            WhseWorksheetTemplate.Type := WhseWorksheetTemplate.Type::Movement;
            WhseWorksheetTemplate."Page ID" := Page::"Movement Worksheet";
            WhseWorksheetTemplate.Insert();
        end;

        // [GIVEN] Movement worksheet line created from initial bin to destination bin
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, InitialBin, DestinationBin, Item."No.", '', WarehouseEntry.Quantity);

        // [GIVEN] Lot tracking assigned to worksheet line
        LibraryItemTracking.CreateWhseWkshItemTracking(WhseItemTrackingLine, WhseWorksheetLine, '', ReservationEntry."Lot No.", 10);

        // [GIVEN] Warehouse Movement document created from worksheet
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, Location.Code, Enum::"Whse. Activity Sorting Method"::None, false, false);
        WhseMovementWarehouseActivityHeader.SetRange(Type, WhseMovementWarehouseActivityHeader.Type::Movement);
        WhseMovementWarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WhseMovementWarehouseActivityHeader.FindFirst();

        // [WHEN] Registering the warehouse movement
        // [THEN] An error is raised indicating movement is blocked by the most recent modified test grade
        asserterror LibraryWarehouse.RegisterWhseActivity(WhseMovementWarehouseActivityHeader);
        LibraryAssert.ExpectedError(StrSubstNo(
            EntryTypeBlockedErr,
            QltyInspectionTestHeader.GetFriendlyIdentifier(),
            ToLoadQltyInspectionGrade.Code,
            WarehouseActivityLine."Activity Type"::Movement,
            Item."No.",
            ReservationEntry."Lot No.",
            ''))
    end;

    [Test]
    [HandlerFunctions('MessageHandler,HandleModalPage_NavigateToMovementDocument')]
    procedure NotificationMgmt_HandleOpenDocument_WarehouseMovement()
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseMovementWarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEntry: Record "Warehouse Entry";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        Location: Record Location;
        Item: Record Item;
        FromBin: Record Bin;
        ToBin: Record Bin;
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        Notification: Notification;
        WhseWorksheetTemplateToUse: Text;
    begin
        // [SCENARIO] Notification management handles opening warehouse movement document

        Initialize();

        // [GIVEN] Quality Management setup ensured
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] Full WMS location with 3 zones created
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] Current warehouse employee set for the location
        QltyTestsUtility.SetCurrLocationWhseEmployee(Location.Code);

        // [GIVEN] Cleared warehouse worksheet lines, names, and templates
        if not WhseWorksheetLine.IsEmpty() then
            WhseWorksheetLine.DeleteAll();
        if not WhseWorksheetName.IsEmpty() then
            WhseWorksheetName.DeleteAll();
        if not WhseWorksheetTemplate.IsEmpty() then
            WhseWorksheetTemplate.DeleteAll();

        // [GIVEN] Warehouse worksheet template for Movement with page ID assigned
        WhseWorksheetTemplate.Init();
        QltyTestsUtility.GenerateRandomCharacters(10, WhseWorksheetTemplateToUse);
        WhseWorksheetTemplate.Name := CopyStr(WhseWorksheetTemplateToUse, 1, MaxStrLen(WhseWorksheetTemplate.Name));
        WhseWorksheetTemplate.Type := WhseWorksheetTemplate.Type::Movement;
        WhseWorksheetTemplate."Page ID" := Page::"Movement Worksheet";
        WhseWorksheetTemplate.Insert();

        // [GIVEN] Warehouse worksheet name created for the template and location
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);

        // [GIVEN] Item created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Purchase order for 100 units at the WMS location
        QltyPurOrderGenerator.CreatePurchaseOrder(100, Location, Item, PurchaseHeader, PurchaseLine);

        // [GIVEN] Purchase order released and received
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] Warehouse entry identified (Movement type, not in RECEIVE zone)
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetFilter("Zone Code", '<>%1', 'RECEIVE');
        WarehouseEntry.FindFirst();

        // [GIVEN] From bin determined from warehouse entry
        FromBin.Get(Location.Code, WarehouseEntry."Bin Code");

        // [GIVEN] To bin determined (same zone, different bin code)
        ToBin.SetRange("Location Code", Location.Code);
        ToBin.SetRange("Zone Code", WarehouseEntry."Zone Code");
        ToBin.SetFilter(Code, '<>%1', WarehouseEntry."Bin Code");
        ToBin.FindFirst();

        // [GIVEN] Movement worksheet line created from FromBin to ToBin for 50 units
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, FromBin, ToBin, Item."No.", '', 50);
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, Location.Code, Enum::"Whse. Activity Sorting Method"::None, false, false);

        // [GIVEN] Warehouse Movement document created from the worksheet line
        WhseMovementWarehouseActivityHeader.SetRange(Type, WhseMovementWarehouseActivityHeader.Type::Movement);
        WhseMovementWarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WhseMovementWarehouseActivityHeader.FindLast();

        DocumentNo := WhseMovementWarehouseActivityHeader."No.";

        // [GIVEN] Disposition buffer configured for movement with specific quantity to ToBin
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Movement Worksheet";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := 50;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Specific Quantity";
        TempInstructionQltyDispositionBuffer."New Location Code" := Location.Code;
        TempInstructionQltyDispositionBuffer."New Bin Code" := ToBin.Code;
        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;

        // [GIVEN] Notification with related RecordId pointing to the warehouse movement header
        Notification.SetData(NotificationDataRelatedRecordIdTok, Format(WhseMovementWarehouseActivityHeader.RecordId()));

        // [WHEN] HandleOpenDocument is called on the notification
        QltyNotificationMgmt.HandleOpenDocument(Notification);

        // [THEN] The warehouse movement document page opens and the handler validates the correct document number
        LibraryAssert.AreEqual(WhseMovementWarehouseActivityHeader."No.", DocumentNo, 'Should navigate to the movement document');
    end;

    [Test]
    procedure NotifyDoYouWantToAssignToYourself()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        // [SCENARIO] Notification system prompts user to assign quality inspection test to themselves with correct message and action options

        // [GIVEN] Quality management setup with location, item, and inspection template are configured
        Initialize();

        QltyTestsUtility.EnsureSetup();
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A quality inspection test is created from a purchase line for an untracked item
        QltyPurOrderGenerator.CreateTestFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionTestHeader);
        QltyInTestGenerationRule.Delete();

        // [GIVEN] Notification capture variables are cleared and subscription is set up
        NotificationMsg := '';
        Clear(NotificationOptions);
        Clear(TestNotification);

        BindSubscription(this);

        // [WHEN] The notification to assign test to yourself is triggered
        QltyNotificationMgmt.NotifyDoYouWantToAssignToYourself(QltyInspectionTestHeader);
        UnbindSubscription(this);

        // [THEN] The notification contains the correct message with test number, action options, and test record ID data
        LibraryAssert.AreEqual(StrSubstNo(AssignToSelfExpectedMessageLbl, QltyInspectionTestHeader."No."), NotificationMsg, 'Notification message should match expected pattern with test number');

        LibraryAssert.IsTrue(NotificationOptions.ContainsKey(AssignToSelfLbl), 'Notification should contain "Assign to myself" action');
        LibraryAssert.IsTrue(NotificationOptions.ContainsKey(IgnoreLbl), 'Notification should contain "Ignore" action');

        LibraryAssert.AreEqual(Format(QltyInspectionTestHeader.RecordId), TestNotification.GetData(NotificationDataTestRecordIdTok), 'Notification should contain the correct test record ID in data');

        LibraryAssert.IsTrue(StrPos(NotificationMsg, QltyInspectionTestHeader."No.") > 0, 'Notification message should contain the test number');
    end;

    [Test]
    procedure HandleNotificationActionAssignToSelf()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        IWXQltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        MockNotification: Notification;
    begin
        // [SCENARIO] Notification action handler successfully assigns quality inspection test to the current user

        // [GIVEN] Quality management setup with location, item, and inspection template are configured
        Initialize();

        QltyTestsUtility.EnsureSetup();
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A quality inspection test is created from a purchase line for an untracked item
        QltyPurOrderGenerator.CreateTestFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionTestHeader);
        QltyInTestGenerationRule.Delete();

        // [GIVEN] A mock notification with the test record ID is prepared
        MockNotification.SetData(NotificationDataTestRecordIdTok, Format(QltyInspectionTestHeader.RecordId));

        // [WHEN] The assign to self notification action is handled
        IWXQltyNotificationMgmt.HandleNotificationActionAssignToSelf(MockNotification);

        // [THEN] The quality inspection test is assigned to the current user
        QltyInspectionTestHeader.Get(QltyInspectionTestHeader."No.", QltyInspectionTestHeader."Retest No.");
        LibraryAssert.AreEqual(QltyInspectionTestHeader."Assigned User Id", UserId(), 'Test should be assigned to the current user');
    end;

    [Test]
    procedure HandleNotificationActionIgnore()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        MockNotification: Notification;
    begin
        // [SCENARIO] Notification action handler successfully sets quality inspection test to prevent auto assignment when ignored

        // [GIVEN] Quality management setup with location, item, and inspection template are configured
        Initialize();

        QltyTestsUtility.EnsureSetup();
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A quality inspection test is created from a purchase line for an untracked item
        QltyPurOrderGenerator.CreateTestFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionTestHeader);
        QltyInTestGenerationRule.Delete();

        // [GIVEN] A mock notification with the test record ID is prepared
        MockNotification.SetData(NotificationDataTestRecordIdTok, Format(QltyInspectionTestHeader.RecordId()));

        // [WHEN] The ignore notification action is handled
        QltyNotificationMgmt.HandleNotificationActionIgnore(MockNotification);

        // [THEN] The quality inspection test is marked to prevent auto assignment
        LibraryAssert.IsTrue(QltyInspectionTestHeader.GetPreventAutoAssignment(), 'Test should be ignored');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
    end;

    local procedure EnsureGenPostingSetupExistsForAssembly(AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        GeneralPostingSetup: Record "General Posting Setup";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // Ensure that the general posting setup exists for the assembly lines of the given assembly header
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

    [MessageHandler]
    procedure MessageHandler(MessageText: Text)
    begin
    end;

    [ModalPageHandler]
    procedure HandleModalPage_TestNavigateToSourceDocument(var SalespersonPurchaserCard: TestPage "Salesperson/Purchaser Card")
    begin
        FlagTestNavigateToSourceDocument := SalespersonPurchaserCard.Code.Value();
    end;

    [ModalPageHandler]
    procedure HandleModalPage_NavigateToMovementDocument(var WarehouseMovement: TestPage "Warehouse Movement")
    begin
        DocumentNo := WarehouseMovement."No.".Value();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Qlty. Notification Mgmt.", 'OnBeforeCreateActionNotification', '', true, true)]
    local procedure OnBeforeCreateActionNotification(var NotificationToShow: Notification; var CurrentMessage: Text; var AvailableOptions: Dictionary of [Text, Text]; var Handled: Boolean)
    begin
        NotificationMsg := CurrentMessage;
        NotificationOptions := AvailableOptions;
        TestNotification := NotificationToShow;
        Handled := true;
    end;
}
