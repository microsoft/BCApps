// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Assembly.Document;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Team;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
using Microsoft.Test.QualityManagement.TestLibraries;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Security.AccessControl;
using System.Security.User;
using System.TestLibraries.Utilities;

codeunit 139964 "Qlty. Tests - Misc."
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;
    EventSubscriberInstance = Manual;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        Any: Codeunit Any;
        DocumentNo: Text;
        FlagTestNavigateToSourceDocument: Text;
        NotificationDataInspectionRecordIdTok: Label 'InspectionRecordId', Locked = true;
        Bin1Tok: Label 'Bin1';
        Bin2Tok: Label 'Bin2';
        WarehouseEntryTypeBlockedErr: Label 'This warehouse transaction was blocked because the quality inspection %1 has the result of %2 for item %4 with tracking %5 %6 %7, which is configured to disallow the transaction "%3". You can change whether this transaction is allowed by navigating to Quality Inspection Results.', Comment = '%1=quality inspection, %2=result, %3=entry type being blocked, %4=item, %5=Lot No., %6=Serial No., %7=Package No.';
        EntryTypeBlockedErr: Label 'This transaction was blocked because the quality inspection %1 has the result of %2 for item %4 with tracking %5, which is configured to disallow the transaction "%3". You can change whether this transaction is allowed by navigating to Quality Inspection Results.', Comment = '%1=quality inspection, %2=result, %3=entry type being blocked, %4=item, %5=combined package tracking details of Lot No., Serial No. and Package No.';
        UnableToSetTableValueFieldNotFoundErr: Label 'Unable to set a value because the field [%1] in table [%2] was not found.', Comment = '%1=the field name, %2=the table name';
        NotificationDataRelatedRecordIdTok: Label 'RelatedRecordId', Locked = true;
        LotSerialTrackingDetailsTok: Label '%1 %2', Comment = '%1=lot no,%2=serial no', Locked = true;
        LockedYesLbl: Label 'Yes', Locked = true;
        LockedNoLbl: Label 'No', Locked = true;
        IsInitialized: Boolean;

    [Test]
    procedure AttemptSplitSimpleRangeIntoMinMax_IntegerSimple()
    var
        Min: Decimal;
        Max: Decimal;
    begin
        // [SCENARIO] Split a simple integer range string into minimum and maximum values

        // [GIVEN] A range string "1..2"

        // [WHEN] AttemptSplitSimpleRangeIntoMinMax is called with the range string
        // [THEN] The function returns true and sets Min to 1 and Max to 2
        Initialize();
        LibraryAssert.AreEqual(true, QltyInspectionUtility.AttemptSplitSimpleRangeIntoMinMax('1..2', Min, Max), 'simple conversion');
        LibraryAssert.AreEqual(1, Min, 'simple integer min');
        LibraryAssert.AreEqual(2, Max, 'simple integer max');
    end;

    [Test]
    procedure AttemptSplitSimpleRangeIntoMinMax_IntegerNegativeValues()
    var
        Min: Decimal;
        Max: Decimal;
    begin
        // [SCENARIO] Split a negative integer range string into minimum and maximum values

        // [GIVEN] A range string with negative values "-5..-1"

        // [WHEN] AttemptSplitSimpleRangeIntoMinMax is called with the negative range
        // [THEN] The function returns true and sets Min to -5 and Max to -1
        Initialize();
        LibraryAssert.AreEqual(true, QltyInspectionUtility.AttemptSplitSimpleRangeIntoMinMax('-5..-1', Min, Max), 'negative');
        LibraryAssert.AreEqual(-5, Min, 'simple integer min');
        LibraryAssert.AreEqual(-1, Max, 'simple integer max');
    end;

    [Test]
    procedure AttemptSplitSimpleRangeIntoMinMax_DecimalSimple()
    var
        Min: Decimal;
        Max: Decimal;
    begin
        // [SCENARIO] Split a decimal range string into minimum and maximum values

        // [GIVEN] A range string with decimal values "1.00000001..2.999999999999"

        // [WHEN] AttemptSplitSimpleRangeIntoMinMax is called with the decimal range
        // [THEN] The function returns true and sets Min to 1.00000001 and Max to 2.999999999999
        Initialize();
        LibraryAssert.AreEqual(true, QltyInspectionUtility.AttemptSplitSimpleRangeIntoMinMax('1.00000001..2.999999999999', Min, Max), 'simple conversion');
        LibraryAssert.AreEqual(1.00000001, Min, 'simple decimal min');
        LibraryAssert.AreEqual(2.999999999999, Max, 'simple decimal max');
    end;

    [Test]
    procedure AttemptSplitSimpleRangeIntoMinMax_DecimalThousands()
    var
        Min: Decimal;
        Max: Decimal;
    begin
        // [SCENARIO] Split a decimal range string with thousands separator into minimum and maximum values

        // [GIVEN] A range string with decimal values and thousands separators "1.00000001..1,234,567,890.99"

        // [WHEN] AttemptSplitSimpleRangeIntoMinMax is called with the formatted range
        // [THEN] The function returns true and correctly parses Min and Max values
        Initialize();
        LibraryAssert.AreEqual(true, QltyInspectionUtility.AttemptSplitSimpleRangeIntoMinMax('1.00000001..1,234,567,890.99', Min, Max), 'simple conversion');
        LibraryAssert.AreEqual(1.00000001, Min, 'thousands separator decimal min');
        LibraryAssert.AreEqual(1234567890.99, Max, 'thousands separator decimal max');
    end;

    [Test]
    procedure GetArbitraryMaximumRecursion()
    begin
        // [SCENARIO] Verify the maximum recursion depth limit

        // [GIVEN] A quality management system with recursion limits

        // [WHEN] GetArbitraryMaximumRecursion is called
        // [THEN] The function returns 20 as the maximum recursion depth
        Initialize();
        LibraryAssert.AreEqual(20, QltyInspectionUtility.GetArbitraryMaximumRecursion(), '20 levels of recursion maximum are expected');
    end;

    [Test]
    procedure GetBasicPersonDetails_DoesNotExist()
    var
        OutSourceRecord: RecordId;
        FullName: Text;
        OutJobTitle: Text;
        Email: Text;
        OutPhone: Text;
    begin
        // [SCENARIO] Attempt to get person details for a non-existent person

        Initialize();

        // [GIVEN] A person identifier that does not exist in any person table

        // [WHEN] GetBasicPersonDetails is called with the non-existent identifier
        // [THEN] The function returns false and all output parameters remain empty
        LibraryAssert.AreEqual(false, QltyInspectionUtility.GetBasicPersonDetails('Does not exist', FullName, OutJobTitle, Email, OutPhone, OutSourceRecord), 'there should be no match');
        LibraryAssert.AreEqual('', FullName, 'FullName should have been empty');
        LibraryAssert.AreEqual('', OutJobTitle, 'OutJobTitle should have been empty');
        LibraryAssert.AreEqual('', Email, 'Email should have been empty');
        LibraryAssert.AreEqual('', OutPhone, 'OutPhone should have been empty');
        LibraryAssert.AreEqual(0, OutSourceRecord.TableNo(), 'OutSourceRecord should have been empty');
    end;

    [Test]
    procedure GetBasicPersonDetails_Contact()
    var
        Contact: Record Contact;
        SalesPersonPurchaser: Record "Salesperson/Purchaser";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibrarySales: Codeunit "Library - Sales";
        OutSourceRecord: RecordId;
        FullName: Text;
        OutJobTitle: Text;
        Email: Text;
        OutPhone: Text;
    begin
        // [SCENARIO] Get person details from a Contact record

        Initialize();

        // [GIVEN] A Contact record with name, job title, email, and phone number
        LibrarySales.CreateSalesperson(SalesPersonPurchaser);
        LibraryMarketing.CreatePersonContact(Contact);
        Contact."First Name" := 'David';
        Contact.Validate(Surname, 'Tennant');
        Contact."Job Title" := 'a predictable job title';
        Contact."E-Mail" := CopyStr(Any.Email(), 1, MaxStrLen(Contact."E-mail"));
        Contact."Phone No." := '+1-866-440-7543';
        Contact.Modify(false);

        // [WHEN] GetBasicPersonDetails is called with the Contact number
        // [THEN] The function returns true and populates all contact details correctly
        LibraryAssert.AreEqual(true, QltyInspectionUtility.GetBasicPersonDetails(Contact."No.", FullName, OutJobTitle, Email, OutPhone, OutSourceRecord), 'there should be a match');

        LibraryAssert.AreEqual(Contact.Name, FullName, 'FullName should have been supplied');
        LibraryAssert.AreEqual(Contact."Job Title", OutJobTitle, 'OutJobTitle should have been supplied');
        LibraryAssert.AreEqual(Contact."E-Mail", Email, 'Email should have been supplied');
        LibraryAssert.AreEqual(Contact."Phone No.", OutPhone, 'OutPhone should have been supplied');
        LibraryAssert.AreEqual(Database::Contact, OutSourceRecord.TableNo(), 'OutSourceRecord should have been a contact record');
        LibraryAssert.AreEqual(Contact.RecordId(), OutSourceRecord, 'OutSourceRecord should have been a specific contact record');
    end;

    [Test]
    procedure GetBasicPersonDetails_Employee()
    var
        Employee: Record Employee;
        LibraryHumanResource: Codeunit "Library - Human Resource";
        OutSourceRecord: RecordId;
        FullName: Text;
        JobTitle: Text;
        Email: Text;
        OutPhone: Text;
    begin
        // [SCENARIO] Get person details from an Employee record

        // [GIVEN] An Employee record with name, job title, email, and phone number
        Initialize();
        LibraryHumanResource.CreateEmployee(Employee);
        Employee."First Name" := 'David';
        Employee.Validate("Last Name", 'Tennant');
        Employee."Job Title" := 'a predictable job title';
        Employee."E-Mail" := CopyStr(Any.Email(), 1, MaxStrLen(Employee."E-mail"));
        Employee."Phone No." := '+1-866-440-7543';
        Employee.Modify(false);

        // [WHEN] GetBasicPersonDetails is called with the Employee number
        // [THEN] The function returns true and populates all employee details correctly
        LibraryAssert.AreEqual(true, QltyInspectionUtility.GetBasicPersonDetails(Employee."No.", FullName, JobTitle, Email, OutPhone, OutSourceRecord), 'there should be a match');

        LibraryAssert.AreEqual(Employee.FullName(), FullName, 'FullName should have been supplied');
        LibraryAssert.AreEqual(Employee."Job Title", JobTitle, 'OutJobTitle should have been supplied');
        LibraryAssert.AreEqual(Employee."E-Mail", Email, 'Email should have been supplied');
        LibraryAssert.AreEqual(Employee."Phone No.", OutPhone, 'OutPhone should have been supplied');
        LibraryAssert.AreEqual(Database::Employee, OutSourceRecord.TableNo(), 'OutSourceRecord should have been a Employee record');
        LibraryAssert.AreEqual(Employee.RecordId(), OutSourceRecord, 'OutSourceRecord should have been a specific Employee record');
    end;

    [Test]
    procedure GetBasicPersonDetails_Resource()
    var
        Resource: Record Resource;
        LibraryResource: Codeunit "Library - Resource";
        OutSourceRecord: RecordId;
        FullName: Text;
        JobTitle: Text;
        Email: Text;
        OutPhone: Text;
    begin
        // [SCENARIO] Get person details from a Resource record

        // [GIVEN] A Resource record with name and job title
        Initialize();
        LibraryResource.CreateResourceNew(Resource);
        Resource.Name := CopyStr(Any.AlphanumericText(MaxStrLen(Resource.Name)), 1, MaxStrLen(Resource.Name));
        Resource."Job Title" := CopyStr(Any.AlphanumericText(MaxStrLen(Resource."Job Title")), 1, MaxStrLen(Resource."Job Title"));
        Resource.Modify(false);

        // [WHEN] GetBasicPersonDetails is called with the Resource number
        // [THEN] The function returns true with name and job title populated, but email and phone blank
        LibraryAssert.AreEqual(true, QltyInspectionUtility.GetBasicPersonDetails(Resource."No.", FullName, JobTitle, Email, OutPhone, OutSourceRecord), 'there should be a match');

        LibraryAssert.AreEqual(Resource.Name, FullName, 'FullName should have been supplied');
        LibraryAssert.AreEqual(Resource."Job Title", JobTitle, 'OutJobTitle should have been supplied');
        LibraryAssert.AreEqual('', Email, 'Email should have been blank');
        LibraryAssert.AreEqual('', OutPhone, 'OutPhone should have been blank');
        LibraryAssert.AreEqual(Database::Resource, OutSourceRecord.TableNo(), 'OutSourceRecord should have been a Resource record');
        LibraryAssert.AreEqual(Resource.RecordId(), OutSourceRecord, 'OutSourceRecord should have been a specific Resource record');
    end;

    [Test]
    procedure GetBasicPersonDetails_User()
    var
        User: Record User;
        LibraryPermissions: Codeunit "Library - Permissions";
        OutSourceRecord: RecordId;
        FullName: Text;
        JobTitle: Text;
        Email: Text;
        OutPhone: Text;
    begin
        // [SCENARIO] Get person details from a User record

        Initialize();

        // [GIVEN] A User record with full name and contact email
        LibraryPermissions.CreateUser(User, '', false);
        User."Full Name" := CopyStr(Any.AlphanumericText(MaxStrLen(User."Full Name")), 1, MaxStrLen(User."Full Name"));
        User."Contact Email" := CopyStr(Any.Email(), 1, MaxStrLen(User."Contact Email"));
        User.Modify(false);

        // [WHEN] GetBasicPersonDetails is called with the User name
        // [THEN] The function returns true with full name and email populated, but job title and phone blank
        LibraryAssert.AreEqual(true, QltyInspectionUtility.GetBasicPersonDetails(User."User Name", FullName, JobTitle, Email, OutPhone, OutSourceRecord), 'there should be a match');

        LibraryAssert.AreEqual(User."Full Name", FullName, 'FullName should have been supplied');
        LibraryAssert.AreEqual('', JobTitle, 'OutJobTitle should have been blank');
        LibraryAssert.AreEqual(User."Contact Email", Email, 'Email should have been set');
        LibraryAssert.AreEqual('', OutPhone, 'OutPhone should have been blank');
        LibraryAssert.AreEqual(Database::User, OutSourceRecord.TableNo(), 'OutSourceRecord should have been a User record');
        LibraryAssert.AreEqual(User.RecordId(), OutSourceRecord, 'OutSourceRecord should have been a specific User record');
    end;

    [Test]
    procedure GetBasicPersonDetails_UserSetup()
    var
        User: Record User;
        UserSetup: Record "User Setup";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        OutSourceRecord: RecordId;
        FullName: Text;
        JobTitle: Text;
        Email: Text;
        OutPhone: Text;
    begin
        // [SCENARIO] Get person details from User Setup record

        Initialize();

        // [GIVEN] A User record with full name
        LibraryPermissions.CreateUser(User, '', false);
        User."Full Name" := CopyStr(Any.AlphanumericText(MaxStrLen(User."Full Name")), 1, MaxStrLen(User."Full Name"));
        User."Contact Email" := CopyStr(Any.Email(), 1, MaxStrLen(User."Contact Email"));
        User.Modify(false);

        LibraryDocumentApprovals.CreateUserSetup(UserSetup, User."User Name", '');
        UserSetup."E-Mail" := CopyStr(Any.Email(), 1, MaxStrLen(UserSetup."E-mail"));
        UserSetup."Phone No." := '+1-866-440-7543';
        UserSetup."Salespers./Purch. Code" := '';
        UserSetup.Modify(false);

        // [GIVEN] A User Setup record with email and phone number

        // [WHEN] GetBasicPersonDetails is called with the User ID
        // [THEN] The function returns true with details from User Setup (email, phone) and User (full name)
        LibraryAssert.AreEqual(true, QltyInspectionUtility.GetBasicPersonDetails(UserSetup."User ID", FullName, JobTitle, Email, OutPhone, OutSourceRecord), 'there should be a match');

        LibraryAssert.AreEqual(User."Full Name", FullName, 'FullName should have been supplied');
        LibraryAssert.AreEqual('', JobTitle, 'OutJobTitle should have been blank');
        LibraryAssert.AreEqual(UserSetup."E-Mail", Email, 'Email should have been set');
        LibraryAssert.AreEqual(UserSetup."Phone No.", OutPhone, 'OutPhone should have been set');
        LibraryAssert.AreEqual(Database::"User Setup", OutSourceRecord.TableNo(), 'OutSourceRecord should have been a User record');
        LibraryAssert.AreEqual(UserSetup.RecordId(), OutSourceRecord, 'OutSourceRecord should have been a specific User record');
    end;

    [Test]
    procedure GetBasicPersonDetails_SalesPersonPurchaserSetup()
    var
        User: Record User;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibrarySales: Codeunit "Library - Sales";
        OutSourceRecord: RecordId;
        FullName: Text;
        JobTitle: Text;
        Email: Text;
        OutPhone: Text;
    begin
        // [SCENARIO] Get person details from Salesperson/Purchaser linked via User Setup

        Initialize();

        // [GIVEN] A User record
        LibraryPermissions.CreateUser(User, '', false);
        User."Full Name" := CopyStr(Any.AlphanumericText(MaxStrLen(User."Full Name")), 1, MaxStrLen(User."Full Name"));
        User."Contact Email" := CopyStr(Any.Email(), 1, MaxStrLen(User."Contact Email"));
        User.Modify(false);

        // [GIVEN] A Salesperson/Purchaser record with name, job title, email, and phone
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser.Name := CopyStr(Any.AlphanumericText(MaxStrLen(User."Full Name")), 1, MaxStrLen(SalespersonPurchaser.Name));
        SalespersonPurchaser."Job Title" := 'another predictable job title';
        SalespersonPurchaser."Phone No." := '+1-800-440-7543';
        SalespersonPurchaser."E-Mail" := CopyStr(Any.Email(), 1, MaxStrLen(SalespersonPurchaser."E-Mail"));
        SalespersonPurchaser.Modify();

        // [GIVEN] A User Setup linking the User to the Salesperson/Purchaser
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, User."User Name", '');
        UserSetup."Salespers./Purch. Code" := SalespersonPurchaser.Code;
        UserSetup."E-Mail" := CopyStr(Any.Email(), 1, MaxStrLen(UserSetup."E-mail"));
        UserSetup."Phone No." := '+1-866-440-7543';
        UserSetup.Modify(false);

        // [WHEN] GetBasicPersonDetails is called with the User ID
        // [THEN] The function returns true with details from the linked Salesperson/Purchaser record
        LibraryAssert.AreEqual(true, QltyInspectionUtility.GetBasicPersonDetails(UserSetup."User ID", FullName, JobTitle, Email, OutPhone, OutSourceRecord), 'there should be a match');

        LibraryAssert.AreEqual(SalespersonPurchaser.Name, FullName, 'FullName should have been supplied');
        LibraryAssert.AreEqual(SalespersonPurchaser."Job Title", JobTitle, 'OutJobTitle should have been set');
        LibraryAssert.AreEqual(SalespersonPurchaser."E-Mail", Email, 'Email should have been set');
        LibraryAssert.AreEqual(SalespersonPurchaser."Phone No.", OutPhone, 'OutPhone should have been set');
        LibraryAssert.AreEqual(Database::"Salesperson/Purchaser", OutSourceRecord.TableNo(), 'OutSourceRecord should have been a Salesperson/Purchaser record');
        LibraryAssert.AreEqual(SalespersonPurchaser.RecordId(), OutSourceRecord, 'OutSourceRecord should have been a specific Salesperson/Purchaser record');
    end;

    [Test]
    procedure GetBasicPersonDetailsFromInspectionLine()
    var
        User: Record User;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        LookupQualityMeasureQltyTest: Record "Qlty. Test";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Item: Record Item;
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibrarySales: Codeunit "Library - Sales";
        OutSourceRecord: RecordId;
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
        FullName: Text;
        JobTitle: Text;
        Email: Text;
        OutPhone: Text;
    begin
        // [SCENARIO] Get person details from an inspection line with table lookup field

        Initialize();

        // [GIVEN] User, Salesperson/Purchaser, and User Setup records configured
        LibraryPermissions.CreateUser(User, '', false);
        User."Full Name" := CopyStr(Any.AlphanumericText(MaxStrLen(User."Full Name")), 1, MaxStrLen(User."Full Name"));
        User."Contact Email" := CopyStr(Any.Email(), 1, MaxStrLen(User."Contact Email"));
        User.Modify(false);

        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser.Name := CopyStr(Any.AlphanumericText(MaxStrLen(User."Full Name")), 1, MaxStrLen(SalespersonPurchaser.Name));
        SalespersonPurchaser."Job Title" := 'another predictable job title';
        SalespersonPurchaser."Phone No." := '+1-800-440-7543';
        SalespersonPurchaser."E-Mail" := CopyStr(Any.Email(), 1, MaxStrLen(SalespersonPurchaser."E-Mail"));
        SalespersonPurchaser.Modify();

        LibraryDocumentApprovals.CreateUserSetup(UserSetup, User."User Name", '');
        UserSetup."Salespers./Purch. Code" := SalespersonPurchaser.Code;
        UserSetup."E-Mail" := CopyStr(Any.Email(), 1, MaxStrLen(UserSetup."E-mail"));
        UserSetup."Phone No." := '+1-866-440-7543';
        UserSetup.Modify(false);

        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] An inspection template with a table lookup field for Salesperson/Purchaser
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateTestAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, LookupQualityMeasureQltyTest."Test Value Type"::"Value Type Table Lookup", LookupQualityMeasureQltyTest, ConfigurationToLoadQltyInspectionTemplateLine);
        LookupQualityMeasureQltyTest."Lookup Table No." := Database::"Salesperson/Purchaser";
        LookupQualityMeasureQltyTest."Lookup Field No." := SalespersonPurchaser.FieldNo(Code);
        LookupQualityMeasureQltyTest.Modify(false);

        // [GIVEN] A production order with routing line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);
        Item.Get(ProdProductionOrder."Source No.");

        QltyInspectionHeader.Reset();

        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] An inspection line with a Salesperson/Purchaser code value
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionLine.SetRange("Test Code", LookupQualityMeasureQltyTest.Code);

        LibraryAssert.AreEqual(1, QltyInspectionLine.Count(), 'there should  be exactly one inspection line that matches.');
        QltyInspectionLine.FindFirst();
        QltyInspectionLine.Validate("Test Value", SalespersonPurchaser.Code);
        QltyInspectionLine.Modify();

        // [WHEN] GetBasicPersonDetailsFromInspectionLine is called with the inspection line
        // [THEN] The function returns true and populates person details from the linked Salesperson/Purchaser
        LibraryAssert.AreEqual(true, QltyInspectionUtility.GetBasicPersonDetailsFromInspectionLine(QltyInspectionLine, FullName, JobTitle, Email, OutPhone, OutSourceRecord), 'there should be a match');

        LibraryAssert.AreEqual(SalespersonPurchaser.Name, FullName, 'FullName should have been supplied');
        LibraryAssert.AreEqual(SalespersonPurchaser."Job Title", JobTitle, 'OutJobTitle should have been set');
        LibraryAssert.AreEqual(SalespersonPurchaser."E-Mail", Email, 'Email should have been set');
        LibraryAssert.AreEqual(SalespersonPurchaser."Phone No.", OutPhone, 'OutPhone should have been set');
        LibraryAssert.AreEqual(Database::"Salesperson/Purchaser", OutSourceRecord.TableNo(), 'OutSourceRecord should have been a Salesperson/Purchaser record');
        LibraryAssert.AreEqual(SalespersonPurchaser.RecordId(), OutSourceRecord, 'OutSourceRecord should have been a specific Salesperson/Purchaser record');
    end;

    [Test]
    procedure GetBasicPersonDetailsFromInspectionLine_EmptyRecord()
    var
        TempEmptyQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
        OutSourceRecord: RecordId;
        FullName: Text;
        JobTitle: Text;
        Email: Text;
        OutPhone: Text;
    begin
        // [SCENARIO] Attempt to get person details from an empty inspection line

        Initialize();

        // [GIVEN] An empty inspection line record

        // [WHEN] GetBasicPersonDetailsFromInspectionLine is called with the empty record
        // [THEN] The function returns false and all output parameters remain empty
        Clear(TempEmptyQltyInspectionLine);
        LibraryAssert.AreEqual(false, QltyInspectionUtility.GetBasicPersonDetailsFromInspectionLine(TempEmptyQltyInspectionLine, FullName, JobTitle, Email, OutPhone, OutSourceRecord), 'should be nothing.');

        LibraryAssert.AreEqual('', FullName, 'FullName should have been empty');
        LibraryAssert.AreEqual('', JobTitle, 'OutJobTitle should have been empty');
        LibraryAssert.AreEqual('', Email, 'Email should have been empty');
        LibraryAssert.AreEqual('', OutPhone, 'OutPhone should have been empty');
        LibraryAssert.AreEqual(0, OutSourceRecord.TableNo(), 'should have been empty');
    end;

    [Test]
    procedure GetBooleanFor()
    begin
        // [SCENARIO] Convert various text values to boolean

        Initialize();

        // [GIVEN] Various text values representing true or false

        // [WHEN] GetBooleanFor is called with positive values (true, 1, yes, ok, pass, etc.)
        // [THEN] The function returns true for all positive boolean representations
        LibraryAssert.IsTrue(QltyInspectionUtility.GetBooleanFor('true'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.GetBooleanFor('TRUE'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.GetBooleanFor('1'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.GetBooleanFor('Yes'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.GetBooleanFor('Y'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.GetBooleanFor('T'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.GetBooleanFor('OK'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.GetBooleanFor('GOOD'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.GetBooleanFor('PASS'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.GetBooleanFor('POSITIVE'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.GetBooleanFor(':SELECTED:'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsTrue(QltyInspectionUtility.GetBooleanFor('CHECK'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsTrue(QltyInspectionUtility.GetBooleanFor('CHECKED'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsTrue(QltyInspectionUtility.GetBooleanFor('V'), 'document intelligence/form recognizer selected check.');

        // [WHEN] GetBooleanFor is called with negative values (false, no, fail, etc.)
        // [THEN] The function returns false for all negative boolean representations
        LibraryAssert.IsFalse(QltyInspectionUtility.GetBooleanFor('false'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.GetBooleanFor('FALSE'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.GetBooleanFor('N'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.GetBooleanFor('No'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.GetBooleanFor('F'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.GetBooleanFor('Fail'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.GetBooleanFor('Failed'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.GetBooleanFor('BAD'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.GetBooleanFor('disabled'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.GetBooleanFor('unacceptable'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.GetBooleanFor(':UNSELECTED:'), 'document intelligence/form recognizer scenario');
    end;

    [Test]
    procedure GetCSVOfValuesFromRecord_NoFilter()
    var
        FirstSalespersonPurchaser: Record "Salesperson/Purchaser";
        SecondSalespersonPurchaser: Record "Salesperson/Purchaser";
        ThirdSalespersonPurchaser: Record "Salesperson/Purchaser";
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
        OutputOne := QltyInspectionUtility.GetCSVOfValuesFromRecord(Database::"Salesperson/Purchaser", FirstSalespersonPurchaser.FieldNo(Code), '', 0);
        OutputTwo := QltyInspectionUtility.GetCSVOfValuesFromRecord(Database::"Salesperson/Purchaser", FirstSalespersonPurchaser.FieldNo(Code), '');
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
        Output1 := QltyInspectionUtility.GetCSVOfValuesFromRecord(Database::"Salesperson/Purchaser", FirstSalespersonPurchaser.FieldNo(Code), FirstSalespersonPurchaser.GetView(true), 0);
        Output2 := QltyInspectionUtility.GetCSVOfValuesFromRecord(Database::"Salesperson/Purchaser", FirstSalespersonPurchaser.FieldNo(Code), FirstSalespersonPurchaser.GetView(false));
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
        Output1 := QltyInspectionUtility.GetCSVOfValuesFromRecord(Database::"Salesperson/Purchaser", FirstSalespersonPurchaser.FieldNo(Code), FilteredSalespersonPurchaser.GetView(true), 1);
        Output2 := QltyInspectionUtility.GetCSVOfValuesFromRecord(Database::"Salesperson/Purchaser", FirstSalespersonPurchaser.FieldNo(Code), FilteredSalespersonPurchaser.GetView(true), 2);

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
    procedure GetDefaultMaximumRowsFieldLookup_Defined()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
    begin
        // [SCENARIO] Get maximum rows for field lookup when configured

        Initialize();

        // [GIVEN] Quality Management Setup with Max Rows Field Lookups set to 2
        QltyInspectionUtility.EnsureSetupExists();

        QltyManagementSetup.Get();
        QltyManagementSetup."Max Rows Field Lookups" := 2;
        QltyManagementSetup.Modify();

        // [WHEN] GetDefaultMaximumRowsFieldLookup is called
        // [THEN] The function returns the configured value of 2
        LibraryAssert.AreEqual(2, QltyInspectionUtility.GetDefaultMaximumRowsFieldLookup(), 'simple maximum');
    end;

    [Test]
    procedure GetDefaultMaximumRowsFieldLookup_Undefined()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
    begin
        // [SCENARIO] Get maximum rows for field lookup when not configured

        Initialize();

        // [GIVEN] Quality Management Setup with Max Rows Field Lookups set to 0
        QltyInspectionUtility.EnsureSetupExists();

        QltyManagementSetup.Get();
        QltyManagementSetup."Max Rows Field Lookups" := 0;
        QltyManagementSetup.Modify();

        // [WHEN] GetDefaultMaximumRowsFieldLookup is called
        // [THEN] The function returns the default value of 100
        LibraryAssert.AreEqual(100, QltyInspectionUtility.GetDefaultMaximumRowsFieldLookup(), 'simple maximum');
    end;

    [Test]
    procedure GetLockedNo250()
    begin
        // [SCENARIO] Get locked "No" text value

        Initialize();

        // [WHEN] GetLockedNo250 is called
        // [THEN] The function returns the locked string "No"
        LibraryAssert.AreEqual('No', LockedNoLbl, 'locked no.');
    end;

    [Test]
    procedure GetLockedYes250()
    begin
        // [SCENARIO] Get locked "Yes" text value

        Initialize();

        // [WHEN] GetLockedYes250 is called
        // [THEN] The function returns the locked string "Yes"
        LibraryAssert.AreEqual('Yes', LockedYesLbl, 'locked yes.');
    end;

    [Test]
    procedure GetRecordsForTableField_One()
    var
        User: Record User;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        LookupQualityMeasureQltyTest: Record "Qlty. Test";
        TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary;
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Item: Record Item;
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibrarySales: Codeunit "Library - Sales";
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

        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] An inspection template with table lookup field for Salesperson/Purchaser filtered to one record
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateTestAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, LookupQualityMeasureQltyTest."Test Value Type"::"Value Type Table Lookup", LookupQualityMeasureQltyTest, ConfigurationToLoadQltyInspectionTemplateLine);
        LookupQualityMeasureQltyTest."Lookup Table No." := Database::"Salesperson/Purchaser";
        LookupQualityMeasureQltyTest."Lookup Field No." := SalespersonPurchaser.FieldNo(Code);
        LookupQualityMeasureQltyTest."Lookup Table Filter" := CopyStr(SalespersonPurchaser.GetView(), 1, maxstrlen(LookupQualityMeasureQltyTest."Lookup Table Filter"));
        LookupQualityMeasureQltyTest.Modify(false);

        // [GIVEN] A prioritized rule for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order with routing line and inspection created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);
        Item.Get(ProdProductionOrder."Source No.");

        QltyInspectionHeader.Reset();

        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] An inspection line with the lookup field and test value set to the Salesperson/Purchaser code
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionLine.SetRange("Test Code", LookupQualityMeasureQltyTest.Code);

        LibraryAssert.AreEqual(1, QltyInspectionLine.Count(), 'there should  be exactly one inspection line that matches.');
        QltyInspectionLine.FindFirst();
        QltyInspectionLine.Validate("Test Value", SalespersonPurchaser.Code);
        QltyInspectionLine.Modify();

        // [WHEN] GetRecordsForTableField is called
        QltyInspectionUtility.GetRecordsForTableField(QltyInspectionLine, TempBufferQltyTestLookupValue);

        // [THEN] The function returns exactly one matching record
        LibraryAssert.AreEqual(1, TempBufferQltyTestLookupValue.Count(), 'should have been 1 record.');

        TempBufferQltyTestLookupValue.FindFirst();
        LibraryAssert.AreEqual(SalespersonPurchaser.Code, TempBufferQltyTestLookupValue.Value, 'first key should have been set');
    end;

    [Test]
    procedure GetRecordsForTableField_Multiple()
    var
        User: Record User;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        LookupQualityMeasureQltyTest: Record "Qlty. Test";
        TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary;
        QltyInspectionLine: Record "Qlty. Inspection Line";
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
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibrarySales: Codeunit "Library - Sales";
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

        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] An inspection template with table lookup field for Salesperson/Purchaser filtered by email
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateTestAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, LookupQualityMeasureQltyTest."Test Value Type"::"Value Type Table Lookup", LookupQualityMeasureQltyTest, ConfigurationToLoadQltyInspectionTemplateLine);
        LookupQualityMeasureQltyTest."Lookup Table No." := Database::"Salesperson/Purchaser";
        LookupQualityMeasureQltyTest."Lookup Field No." := FilterSalespersonPurchaser.FieldNo(Code);
        LookupQualityMeasureQltyTest."Lookup Table Filter" := CopyStr(FilterSalespersonPurchaser.GetView(), 1, maxstrlen(LookupQualityMeasureQltyTest."Lookup Table Filter"));
        LookupQualityMeasureQltyTest.Modify(false);

        // [GIVEN] A prioritized rule for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order with routing line and inspection created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);
        Item.Get(ProdProductionOrder."Source No.");

        QltyInspectionHeader.Reset();

        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] An inspection line with the lookup field and test value set to the first Salesperson/Purchaser code
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionLine.SetRange("Test Code", LookupQualityMeasureQltyTest.Code);

        LibraryAssert.AreEqual(1, QltyInspectionLine.Count(), 'there should be exactly one inspection line that matches.');
        QltyInspectionLine.FindFirst();
        QltyInspectionLine.Validate("Test Value", FirstSalespersonPurchaser.Code);
        QltyInspectionLine.Modify();

        // [WHEN] GetRecordsForTableField is called
        QltyInspectionUtility.GetRecordsForTableField(QltyInspectionLine, TempBufferQltyTestLookupValue);

        // [THEN] The function returns all three matching records
        LibraryAssert.AreEqual(3, TempBufferQltyTestLookupValue.Count(), 'should have been 3 sales people with that email.');
    end;

    [Test]
    procedure GetRecordsForTableField_WithOverrides()
    var
        User: Record User;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyTest: Record "Qlty. Test";
        LookupQualityMeasureQltyTest: Record "Qlty. Test";
        TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary;
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ConfigurationToLoadQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Item: Record Item;
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibrarySales: Codeunit "Library - Sales";
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

        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] An inspection template with table lookup field for Salesperson/Purchaser
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateTestAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, LookupQualityMeasureQltyTest."Test Value Type"::"Value Type Table Lookup", LookupQualityMeasureQltyTest, ConfigurationToLoadQltyInspectionTemplateLine);
        LookupQualityMeasureQltyTest."Lookup Table No." := Database::"Salesperson/Purchaser";
        LookupQualityMeasureQltyTest."Lookup Field No." := SalespersonPurchaser.FieldNo(Code);
        LookupQualityMeasureQltyTest."Lookup Table Filter" := CopyStr(SalespersonPurchaser.GetView(), 1, maxstrlen(LookupQualityMeasureQltyTest."Lookup Table Filter"));
        LookupQualityMeasureQltyTest.Modify(false);

        // [GIVEN] A prioritized rule for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order with routing line and inspection created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);
        Item.Get(ProdProductionOrder."Source No.");

        QltyInspectionHeader.Reset();

        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] An inspection line with the lookup field and test value set to the Salesperson/Purchaser code
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionLine.SetRange("Test Code", LookupQualityMeasureQltyTest.Code);

        LibraryAssert.AreEqual(1, QltyInspectionLine.Count(), 'there should  be exactly one inspection line that matches.');
        QltyInspectionLine.FindFirst();
        QltyInspectionLine.Validate("Test Value", SalespersonPurchaser.Code);
        QltyInspectionLine.Modify();

        // [GIVEN] The quality test record retrieved
        QltyTest.Get(QltyInspectionLine."Test Code");

        // [WHEN] GetRecordsForTableField is called with different parameter combinations (field+header+line, field+header)
        QltyInspectionUtility.GetRecordsForTableField(QltyTest, QltyInspectionHeader, QltyInspectionLine, TempBufferQltyTestLookupValue);

        // [THEN] The function returns the correct record using all parameter overloads
        LibraryAssert.AreEqual(1, TempBufferQltyTestLookupValue.Count(), 'should have been 1 record.');

        TempBufferQltyTestLookupValue.FindFirst();
        LibraryAssert.AreEqual(SalespersonPurchaser.Code, TempBufferQltyTestLookupValue.Value, 'first key should have been set');

        QltyInspectionUtility.GetRecordsForTableField(QltyTest, QltyInspectionHeader, TempBufferQltyTestLookupValue);
        LibraryAssert.AreEqual(1, TempBufferQltyTestLookupValue.Count(), 'should have been 1 record.');

        TempBufferQltyTestLookupValue.FindFirst();
        LibraryAssert.AreEqual(SalespersonPurchaser.Code, TempBufferQltyTestLookupValue.Value, 'first key should have been set');
    end;

    [Test]
    procedure GetRecordsForTableFieldAsCSV()
    var
        User: Record User;
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        LookupQualityMeasureQltyTest: Record "Qlty. Test";
        QltyInspectionLine: Record "Qlty. Inspection Line";
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
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibrarySales: Codeunit "Library - Sales";
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

        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] Quality Management Setup with max rows field lookups set to 0 (unlimited)
        QltyManagementSetup.Get();
        QltyManagementSetup."Max Rows Field Lookups" := 0;
        QltyManagementSetup.Modify(false);

        // [GIVEN] An inspection template with table lookup field for Salesperson/Purchaser filtered by email
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 2);
        QltyInspectionUtility.CreateTestAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, LookupQualityMeasureQltyTest."Test Value Type"::"Value Type Table Lookup", LookupQualityMeasureQltyTest, ConfigurationToLoadQltyInspectionTemplateLine);
        LookupQualityMeasureQltyTest."Lookup Table No." := Database::"Salesperson/Purchaser";
        LookupQualityMeasureQltyTest."Lookup Field No." := FilterSalespersonPurchaser.FieldNo(Code);
        LookupQualityMeasureQltyTest."Lookup Table Filter" := CopyStr(FilterSalespersonPurchaser.GetView(), 1, maxstrlen(LookupQualityMeasureQltyTest."Lookup Table Filter"));
        LookupQualityMeasureQltyTest.Modify(false);

        // [GIVEN] A prioritized rule for production order routing line
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        // [GIVEN] A production order with routing line and inspection created
        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(1, OrdersList);
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        ProdProductionOrder.Get(ProdProductionOrder.Status::Released, ProductionOrder);
        Item.Get(ProdProductionOrder."Source No.");

        QltyInspectionHeader.Reset();

        ClearLastError();
        QltyInspectionUtility.CreateInspectionWithVariant(ProdOrderRoutingLine, false, QltyInspectionHeader);

        // [GIVEN] An inspection line with the lookup field and test value set to the first Salesperson/Purchaser code
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionLine.SetRange("Test Code", LookupQualityMeasureQltyTest.Code);

        LibraryAssert.AreEqual(1, QltyInspectionLine.Count(), 'there should  be exactly one inspection line that matches.');
        QltyInspectionLine.FindFirst();
        QltyInspectionLine.Validate("Test Value", FirstSalespersonPurchaser.Code);
        QltyInspectionLine.Modify();

        // [WHEN] GetRecordsForTableFieldAsCSV is called
        Output1 := QltyInspectionUtility.GetRecordsForTableFieldAsCSV(QltyInspectionLine);

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
    begin
        // [SCENARIO] Get translated "Yes" text value

        Initialize();

        // [WHEN] GetTranslatedYes250 is called
        // [THEN] The function returns the translated string "Yes"
        LibraryAssert.AreEqual('Yes', QltyInspectionUtility.GetTranslatedYes250(), 'locked yes.');
    end;

    [Test]
    procedure GetTranslatedNo250()
    begin
        // [SCENARIO] Get translated "No" text value

        Initialize();

        // [WHEN] GetTranslatedNo250 is called
        // [THEN] The function returns the translated string "No"
        LibraryAssert.AreEqual('No', QltyInspectionUtility.GetTranslatedNo250(), 'locked no.');
    end;

    [Test]
    procedure GuessDataTypeFromDescriptionAndValue_Description()
    var
        QltyTestValueType: Enum "Qlty. Test Value Type";
    begin
        // [SCENARIO] Guess data type from description text

        Initialize();

        // [GIVEN] Various field descriptions with question words, keywords, or phrases
        // [WHEN] GuessDataTypeFromDescriptionAndValue is called with description (empty value)
        // [THEN] The function infers the correct data type from description patterns
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Boolean", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('Does the monkey eat bananas', ''), 'bool test 3');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Boolean", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('Have you eaten bananas', ''), 'bool test 4');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Boolean", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('Do the monkeys eat bananas', ''), 'bool test 5');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Boolean", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('Is the monkey eating a banana', ''), 'bool test 6');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Text", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('lot #', ''), 'lot 1');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Text", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('lot number', ''), 'lot 2');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Text", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('serial #', ''), 'serial 1');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Text", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('serial number', ''), 'serial 2');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Date", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('posting date', ''), 'date 1');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Date", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('another date orso', ''), 'date 2');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Date", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('another dATE orso', ''), 'date 2b');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Date", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('date something was seen.', ''), 'date 3');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Date", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('Date something was seen.', ''), 'date 3b case');
    end;

    [Test]
    procedure GuessDataTypeFromDescriptionAndValue_Values()
    var
        QltyTestValueType: Enum "Qlty. Test Value Type";
    begin
        // [SCENARIO] Guess data type from actual values

        Initialize();

        // [GIVEN] Various sample values (boolean, numeric, date, text)
        // [WHEN] GuessDataTypeFromDescriptionAndValue is called with value (empty description)
        // [THEN] The function infers the correct data type from value patterns
        LibraryAssert.AreEqual('No', QltyInspectionUtility.GetTranslatedNo250(), 'locked no.');

        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Boolean", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('', 'true'), 'bool test 1');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Boolean", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('', 'false'), 'bool test 2');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Boolean", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('', 'TRUE'), 'bool test 1b');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Boolean", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('', 'FALSE'), 'bool test 2b');

        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Boolean", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('', ':selected:'), 'bool test document intelligence/form recognizer');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Boolean", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('', ':unselected:'), 'bool test document intelligence/form recognizer');

        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Decimal", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('', '1.0001'), 'decimal test 1');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Decimal", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('', '2'), 'decimal test 2');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Date", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('', Format(today())), 'date 1');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Date", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('', Format(DMY2Date(1, 1, 2000))), 'date 2 locale');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Date", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('', Format(DMY2Date(1, 1, 2000), 0, 9)), 'date 3 ISO 8601');
        LibraryAssert.AreEqual(QltyTestValueType::"Value Type Text", QltyInspectionUtility.GuessDataTypeFromDescriptionAndValue('', 'abc'), 'text 1');
    end;

    [Test]
    procedure IsNumericText()
    begin
        // [SCENARIO] Validate if text contains numeric values

        Initialize();

        // [GIVEN] Various text values (numbers, text, mixed content)
        // [WHEN] IsNumericText is called with each value
        // [THEN] The function returns true for numeric text, false for non-numeric text
        LibraryAssert.IsTrue(QltyInspectionUtility.IsNumericText('0'), 'zero');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsNumericText('-1'), 'simple negative');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsNumericText('1'), 'simple positive');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsNumericText(format(123456789.1234)), 'lcoale format');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsNumericText(format(123456789.1234, 0, 9)), 'ISO format');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsNumericText('not a hot dog'), 'simple text');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsNumericText('A1B2C3'), 'mixed');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsNumericText('1+2+3=4'), 'formula');
    end;

    [Test]
    procedure IsTextValueNegativeBoolean()
    begin
        // [SCENARIO] Identify negative boolean text values

        Initialize();

        // [GIVEN] Various text values representing positive and negative boolean states
        // [WHEN] IsTextValueNegativeBoolean is called with each value
        // [THEN] The function returns false for positive values, true for negative values
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValueNegativeBoolean('true'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValueNegativeBoolean('TRUE'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValueNegativeBoolean('1'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValueNegativeBoolean('Yes'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValueNegativeBoolean('Y'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValueNegativeBoolean('T'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValueNegativeBoolean('OK'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValueNegativeBoolean('GOOD'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValueNegativeBoolean('PASS'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValueNegativeBoolean('POSITIVE'), 'simple bool true.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValueNegativeBoolean(':SELECTED:'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValueNegativeBoolean('CHECK'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValueNegativeBoolean('CHECKED'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValueNegativeBoolean('V'), 'document intelligence/form recognizer selected check.');

        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValueNegativeBoolean('false'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValueNegativeBoolean('FALSE'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValueNegativeBoolean('N'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValueNegativeBoolean('No'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValueNegativeBoolean('F'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValueNegativeBoolean('Fail'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValueNegativeBoolean('Failed'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValueNegativeBoolean('BAD'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValueNegativeBoolean('disabled'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValueNegativeBoolean('unacceptable'), 'simple bool false.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValueNegativeBoolean(':UNSELECTED:'), 'document intelligence/form recognizer scenario');

        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValueNegativeBoolean('not a hot dog'), 'not a hot dog');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValuePositiveBoolean('Canada'), 'a sovereign country');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValueNegativeBoolean('1234'), 'a number');
    end;

    [Test]
    procedure IsTextValuePositiveBoolean()
    begin
        // [SCENARIO] Identify positive boolean text values

        Initialize();

        // [GIVEN] Various text values representing positive and negative boolean states
        // [WHEN] IsTextValuePositiveBoolean is called with each value
        // [THEN] The function returns true for positive values, false for negative values
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValuePositiveBoolean('true'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValuePositiveBoolean('TRUE'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValuePositiveBoolean('1'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValuePositiveBoolean('Yes'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValuePositiveBoolean('Y'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValuePositiveBoolean('T'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValuePositiveBoolean('OK'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValuePositiveBoolean('GOOD'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValuePositiveBoolean('PASS'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValuePositiveBoolean('POSITIVE'), 'simple bool true.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValuePositiveBoolean(':SELECTED:'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValuePositiveBoolean('CHECK'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValuePositiveBoolean('CHECKED'), 'document intelligence/form recognizer selected check.');
        LibraryAssert.IsTrue(QltyInspectionUtility.IsTextValuePositiveBoolean('V'), 'document intelligence/form recognizer selected check.');

        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValuePositiveBoolean('false'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValuePositiveBoolean('FALSE'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValuePositiveBoolean('N'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValuePositiveBoolean('No'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValuePositiveBoolean('F'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValuePositiveBoolean('Fail'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValuePositiveBoolean('Failed'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValuePositiveBoolean('BAD'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValuePositiveBoolean('disabled'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValuePositiveBoolean('unacceptable'), 'simple bool false.');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValuePositiveBoolean(':UNSELECTED:'), 'document intelligence/form recognizer scenario');

        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValuePositiveBoolean('not a hot dog'), 'not a hot dog');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValuePositiveBoolean('Canada'), 'a sovereign country');
        LibraryAssert.IsFalse(QltyInspectionUtility.IsTextValuePositiveBoolean('1234'), 'a number');
    end;

    [Test]
    procedure NavigateToFindEntries()
    var
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        Navigate: TestPage Navigate;
    begin
        // [SCENARIO] Navigate to find entries from inspection header

        Initialize();

        // [GIVEN] A temporary inspection header with source document, item, lot, and serial number
        TempQltyInspectionHeader."No." := 'INSPECTSOURCE';
        TempQltyInspectionHeader."Source Document No." := 'MYDOC123';
        TempQltyInspectionHeader."Source Item No." := 'ITEMABC';
        TempQltyInspectionHeader."Source Lot No." := 'LOTDEF';
        TempQltyInspectionHeader."Source Serial No." := 'SERIALGHI';

        // [WHEN] NavigateToFindEntries is called
        Navigate.Trap();
        QltyInspectionUtility.NavigateToFindEntries(TempQltyInspectionHeader);

        // [THEN] The Navigate page opens with lot and serial number filters applied
        LibraryAssert.AreEqual('SERIALGHI', Navigate.SerialNoFilter.Value, 'serial filter got set');
        LibraryAssert.AreEqual('LOTDEF', Navigate.LotNoFilter.Value, 'lot filter got set');
    end;

    [Test]
    procedure SetTableValue_Simple()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // [SCENARIO] Set table field values dynamically

        Initialize();

        // [GIVEN] A Salesperson/Purchaser record with initial values
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser."Commission %" := 1;
        SalespersonPurchaser."Job Title" := 'janitor';
        SalespersonPurchaser.Modify(false);
        SalespersonPurchaser.SetRecFilter();

        // [WHEN] SetTableValue is called for decimal and text fields
        QltyInspectionUtility.SetTableValue(SalespersonPurchaser.TableCaption(), SalespersonPurchaser.GetView(), SalespersonPurchaser.FieldName("Commission %"), format(1234.56), true);
        QltyInspectionUtility.SetTableValue(SalespersonPurchaser.TableCaption(), SalespersonPurchaser.GetView(), SalespersonPurchaser.FieldName("Job Title"), 'manager', true);

        // [THEN] The field values are updated correctly
        SalespersonPurchaser.SetRecFilter();
        SalespersonPurchaser.FindFirst();

        LibraryAssert.AreEqual(1234.56, SalespersonPurchaser."Commission %", 'decimal test');
        LibraryAssert.AreEqual('manager', SalespersonPurchaser."Job Title", 'text test');
    end;

    [Test]
    procedure SetTableValue_Error()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // [SCENARIO] Set table value error when field does not exist

        Initialize();

        // [GIVEN] A Salesperson/Purchaser record
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser."Commission %" := 1;
        SalespersonPurchaser."Job Title" := 'janitor';
        SalespersonPurchaser.Modify(false);
        SalespersonPurchaser.SetRecFilter();

        // [WHEN] SetTableValue is called with a non-existent field name
        asserterror QltyInspectionUtility.SetTableValue(SalespersonPurchaser.TableCaption(), SalespersonPurchaser.GetView(), 'This field does not exist.', format(1234.56), true);

        // [THEN] An error is raised indicating the field was not found
        LibraryAssert.ExpectedError(StrSubstNo(UnableToSetTableValueFieldNotFoundErr, 'This field does not exist.', SalespersonPurchaser.TableCaption()));
    end;

    [Test]
    procedure ReadFieldAsText()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        InteractionLogEntry: Record "Interaction Log Entry";
        LibrarySales: Codeunit "Library - Sales";
        Format0: Text;
        Format9: Text;
        Format9NoOfInteractions: Text;
    begin
        // [SCENARIO] Read field values as text with different formats

        Initialize();

        // [GIVEN] A Salesperson/Purchaser record with decimal field and calculated flowfield
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser."Commission %" := 12345.67;
        SalespersonPurchaser."Job Title" := 'janitor';
        SalespersonPurchaser.Modify(false);

        InteractionLogEntry.Reset();
        InteractionLogEntry."Salesperson Code" := SalespersonPurchaser.Code;
        InteractionLogEntry.Canceled := false;
        InteractionLogEntry.Postponed := false;
        InteractionLogEntry.InsertRecord();

        // [WHEN] ReadFieldAsText is called with format 0 (locale) and format 9 (ISO)
        Format0 := QltyInspectionUtility.ReadFieldAsText(SalespersonPurchaser, SalespersonPurchaser.FieldName("Commission %"), 0);
        Format9 := QltyInspectionUtility.ReadFieldAsText(SalespersonPurchaser, SalespersonPurchaser.FieldName("Commission %"), 9);

        Format9NoOfInteractions := QltyInspectionUtility.ReadFieldAsText(SalespersonPurchaser, SalespersonPurchaser.FieldName("No. of Interactions"), 9);

        // [THEN] The field values are formatted correctly including flowfields
        SalespersonPurchaser.CalcFields("No. of Interactions");
        LibraryAssert.AreEqual(format(SalespersonPurchaser."Commission %", 0, 0), Format0, 'format0 test');
        LibraryAssert.AreEqual(format(SalespersonPurchaser."Commission %", 0, 9), Format9, 'format9 test');
        LibraryAssert.AreEqual(format(SalespersonPurchaser."No. of Interactions", 0, 9), Format9NoOfInteractions, 'flowfield test');
    end;

    [Test]
    [HandlerFunctions('HandleModalPage_TestNavigateToSourceDocument')]
    procedure NavigateToSourceDocument()
    var
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        LibrarySales: Codeunit "Library - Sales";
        LocalQltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        SalespersonPurchaserCard: TestPage "Salesperson/Purchaser Card";
    begin
        // [SCENARIO] Navigate to source document from inspection header

        Initialize();

        // [GIVEN] A temporary inspection header with source RecordId pointing to a Salesperson/Purchaser
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        TempQltyInspectionHeader."Source RecordId" := SalespersonPurchaser.RecordId();

        // [WHEN] NavigateToSourceDocument is called
        SalespersonPurchaserCard.Trap();
        LocalQltyInspectionUtility.NavigateToSourceDocument(TempQltyInspectionHeader);

        // [THEN] The Salesperson/Purchaser card page opens and the handler validates the correct record
        LibraryAssert.AreEqual(FlagTestNavigateToSourceDocument, SalespersonPurchaser.Code, 'testing if a simple lookup page worked');
    end;

    [Test]
    procedure BlockTrackingTransaction_NoInspections_ShouldNotPreventPosting()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        NoSeries: Codeunit "No. Series";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LotNo: Code[20];
    begin
        // [SCENARIO] Block tracking transaction with no inspections should not prevent posting

        Initialize();

        // [GIVEN] Quality Management setup ensured
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Location created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Lot-tracked item with number series created
        QltyInspectionUtility.CreateLotTrackedItem(Item);

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

        // [GIVEN] Quality Management setup configured with 'Any' inspection selection criteria
        QltyManagementSetup."Inspection Selection Criteria" := QltyManagementSetup."Inspection Selection Criteria"::"Any inspection that matches";
        QltyManagementSetup.Modify();

        // [GIVEN] No inspections exist in the system
        if not QltyInspectionHeader.IsEmpty() then
            QltyInspectionHeader.DeleteAll();

        // [WHEN] Posting with 'Any' behavior and no inspections
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

        // [GIVEN] Quality Management setup configured with "Any finished inspection that matches" inspection selection criteria
        QltyManagementSetup."Inspection Selection Criteria" := QltyManagementSetup."Inspection Selection Criteria"::"Any finished inspection that matches";
        QltyManagementSetup.Modify();

        // [GIVEN] No inspections exist
        if not QltyInspectionHeader.IsEmpty() then
            QltyInspectionHeader.DeleteAll();

        // [WHEN] Posting with "Any finished inspection that matches" behavior and no inspections
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

        // [GIVEN] Quality Management setup configured with "Only the newest finished inspection/re-inspection" inspection selection criteria
        QltyManagementSetup."Inspection Selection Criteria" := QltyManagementSetup."Inspection Selection Criteria"::"Only the newest finished inspection/re-inspection";
        QltyManagementSetup.Modify();

        // [GIVEN] No inspections exist
        if not QltyInspectionHeader.IsEmpty() then
            QltyInspectionHeader.DeleteAll();

        // [WHEN] Posting with "Only the newest finished inspection/re-inspection" behavior and no inspections
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

        // [GIVEN] Quality Management setup configured with "Only the newest inspection/re-inspection" inspection selection criteria
        QltyManagementSetup."Inspection Selection Criteria" := QltyManagementSetup."Inspection Selection Criteria"::"Only the newest inspection/re-inspection";
        QltyManagementSetup.Modify();

        // [GIVEN] No inspections exist
        if not QltyInspectionHeader.IsEmpty() then
            QltyInspectionHeader.DeleteAll();

        // [WHEN] Posting with "Only the newest inspection/re-inspection" behavior and no inspections
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

        // [GIVEN] Quality Management setup configured with "Only the most recently modified finished inspection" inspection selection criteria
        QltyManagementSetup."Inspection Selection Criteria" := QltyManagementSetup."Inspection Selection Criteria"::"Only the most recently modified finished inspection";
        QltyManagementSetup.Modify();

        // [GIVEN] No inspections exist
        if not QltyInspectionHeader.IsEmpty() then
            QltyInspectionHeader.DeleteAll();

        // [WHEN] Posting with "Only the most recently modified finished inspection" behavior and no inspections
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

        // [GIVEN] Quality Management setup configured with "Only the most recently modified inspection" inspection selection criteria
        QltyManagementSetup."Inspection Selection Criteria" := QltyManagementSetup."Inspection Selection Criteria"::"Only the most recently modified inspection";
        QltyManagementSetup.Modify();

        // [GIVEN] No inspections exist
        if not QltyInspectionHeader.IsEmpty() then
            QltyInspectionHeader.DeleteAll();

        // [WHEN] Posting with "Only the most recently modified inspection" behavior and no inspections
        ItemJnlPostBatch.Run(ItemJournalLine);

        // [THEN] Posting succeeds without error - all 6 behaviors allow posting when no inspections exist
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
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
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
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LotNo: Code[20];
    begin
        // [SCENARIO] Block assembly consumption with "Any finished inspection that matches" behavior should error

        Initialize();

        // [GIVEN] Item journal template and batch prepared
        if ItemJournalTemplate.Count() > 1 then
            ItemJournalTemplate.DeleteAll();
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        if not ItemJournalTemplate.FindFirst() then
            LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] Quality Management setup ensured
        QltyInspectionUtility.EnsureSetupExists();
        QltyManagementSetup.Get();

        // [GIVEN] Location created
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Quality Management setup with "Any finished inspection that matches" inspection selection criteria
        QltyManagementSetup."Inspection Selection Criteria" := QltyManagementSetup."Inspection Selection Criteria"::"Any finished inspection that matches";
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

        // [GIVEN] Inspection result configured to block assembly consumption
        ToLoadQltyInspectionResult.FindFirst();
        QltyInspectionUtility.ClearResultLotSettings(ToLoadQltyInspectionResult);
        ToLoadQltyInspectionResult."Item Tracking Allow Asm. Cons." := ToLoadQltyInspectionResult."Item Tracking Allow Asm. Cons."::Block;
        ToLoadQltyInspectionResult.Modify();

        // [GIVEN] Finished inspection created for the component lot with blocking result
        QltyInspectionHeader.Init();
        QltyInspectionHeader."Source Item No." := ComponentItem."No.";
        QltyInspectionHeader."Source Lot No." := LotNo;
        QltyInspectionHeader."Source Quantity (Base)" := AssemblyLine."Quantity (Base)";
        QltyInspectionHeader.Insert(true);

        QltyInspectionHeader."Result Code" := ToLoadQltyInspectionResult.Code;
        QltyInspectionHeader.Status := QltyInspectionHeader.Status::Finished;
        QltyInspectionHeader.Modify();

        // [WHEN] Posting the assembly order
        // [THEN] An error is raised indicating assembly consumption is blocked by the result
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, StrSubstNo(
            EntryTypeBlockedErr,
            QltyInspectionHeader.GetFriendlyIdentifier(),
            ToLoadQltyInspectionResult.Code,
            ItemJournalLine."Entry Type"::"Assembly Consumption",
            ComponentItem."No.",
            LotNo));
    end;

    [Test]
    procedure BlockTrackingTransaction_Purchase_NewestReinspection_ShouldError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        ToUseNoSeries: Record "No. Series";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // [SCENARIO] Block purchase with "Only the newest inspection/re-inspection" behavior should error

        Initialize();

        // [GIVEN] Inspection results cleared
        if not ToLoadQltyInspectionResult.IsEmpty() then
            ToLoadQltyInspectionResult.DeleteAll();

        // [GIVEN] Quality Management setup ensured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] Prioritized inspection generation rule for Purchase Line created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] Package-tracked item with no series created
        QltyInspectionUtility.CreatePackageTrackedItemWithNoSeries(Item, ToUseNoSeries);

        // [GIVEN] Purchase order with package tracking created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] Inspection created for purchase line with tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Re-inspection created from original inspection
        QltyInspectionUtility.CreateReinspection(QltyInspectionHeader, ReQltyInspectionHeader);

        // [GIVEN] Inspection result configured to block purchase
        ToLoadQltyInspectionResult.FindFirst();
        QltyInspectionUtility.ClearResultLotSettings(ToLoadQltyInspectionResult);
        ToLoadQltyInspectionResult."Item Tracking Allow Purchase" := ToLoadQltyInspectionResult."Item Tracking Allow Purchase"::Block;
        ToLoadQltyInspectionResult.Modify();

        // [GIVEN] Re-inspection assigned the blocking result
        ReQltyInspectionHeader."Result Code" := ToLoadQltyInspectionResult.Code;
        ReQltyInspectionHeader.Modify();

        // [GIVEN] Quality Management setup with "Only the newest inspection/re-inspection" inspection selection criteria
        QltyManagementSetup.Get();
        QltyManagementSetup."Inspection Selection Criteria" := QltyManagementSetup."Inspection Selection Criteria"::"Only the newest inspection/re-inspection";
        QltyManagementSetup.Modify();

        // [GIVEN] Inspection generation rule deleted to prevent new inspection creation
        QltyInspectionGenRule.Delete();

        // [WHEN] Posting the purchase document
        // [THEN] An error is raised indicating purchase is blocked by the result on the highest re-inspection
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        LibraryAssert.ExpectedError(StrSubstNo(EntryTypeBlockedErr,
            ReQltyInspectionHeader.GetFriendlyIdentifier(),
            ToLoadQltyInspectionResult.Code,
            ItemJournalLine."Entry Type"::Purchase,
            PurchaseLine."No.",
            ReservationEntry."Package No."));
    end;

    [Test]
    procedure BlockTrackingTransaction_AssemblyOutput_MostRecentFinishedModified_ShouldError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReQltyInspectionHeader: Record "Qlty. Inspection Header";
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
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        RecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        LotNo: Code[50];
        SerialNo: Code[50];
    begin
        // [SCENARIO] Block assembly output with "Only the most recently modified finished inspection" behavior should error

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
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] Inspection template with 3 characteristics created
        QltyInspectionUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 3);

        // [GIVEN] Prioritized inspection generation rule for Assembly Header created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Assembly Header", QltyInspectionGenRule);

        // [GIVEN] Custom inspection source configuration for Assembly Header to Inspection created
        QltyInspectionUtility.CreateSourceConfig(SpecificQltyInspectSourceConfig, Database::"Assembly Header", Enum::"Qlty. Target Type"::Inspection, Database::"Qlty. Inspection Header");

        QltyInspectionUtility.CreateSourceFieldConfig(
            SpecificQltyInspectSourceConfig.Code,
            SpecificQltyInspectSourceConfig."From Table No.",
            AssemblyHeader.FieldNo("Item No."),
            Enum::"Qlty. Target Type"::Inspection,
            Database::"Qlty. Inspection Header",
            QltyInspectionHeader.FieldNo("Source Item No."));

        QltyInspectionUtility.CreateSourceFieldConfig(
            SpecificQltyInspectSourceConfig.Code,
            SpecificQltyInspectSourceConfig."From Table No.",
            AssemblyHeader.FieldNo("No."),
            Enum::"Qlty. Target Type"::Inspection,
            Database::"Qlty. Inspection Header",
            QltyInspectionHeader.FieldNo("Source Document No."));

        QltyInspectionUtility.CreateSourceFieldConfig(
            SpecificQltyInspectSourceConfig.Code,
            SpecificQltyInspectSourceConfig."From Table No.",
            AssemblyHeader.FieldNo("Document Type"),
            Enum::"Qlty. Target Type"::Inspection,
            Database::"Qlty. Inspection Header",
            QltyInspectionHeader.FieldNo("Source Type"));

        QltyInspectionUtility.CreateSourceFieldConfig(
            SpecificQltyInspectSourceConfig.Code,
            SpecificQltyInspectSourceConfig."From Table No.",
            AssemblyHeader.FieldNo("Quantity to Assemble (Base)"),
            Enum::"Qlty. Target Type"::Inspection,
            Database::"Qlty. Inspection Header",
            QltyInspectionHeader.FieldNo("Source Quantity (Base)"));

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

        // [GIVEN] Inspection created from assembly header with tracking
        RecordRef.GetTable(AssemblyHeader);
        TempSpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
        QltyInspectionUtility.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, TempSpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '', QltyInspectionHeader);

        // [GIVEN] Re-inspection created from original inspection
        QltyInspectionUtility.CreateReinspection(QltyInspectionHeader, ReQltyInspectionHeader);

        // [GIVEN] Inspection result configured to block assembly output
        ToLoadQltyInspectionResult.FindFirst();
        QltyInspectionUtility.ClearResultLotSettings(ToLoadQltyInspectionResult);
        ToLoadQltyInspectionResult."Item Tracking Allow Asm. Out." := ToLoadQltyInspectionResult."Item Tracking Allow Asm. Out."::Block;
        ToLoadQltyInspectionResult.Modify();

        // [GIVEN] Re-inspection marked as finished with blocking result
        ReQltyInspectionHeader."Result Code" := ToLoadQltyInspectionResult.Code;
        ReQltyInspectionHeader.Status := ReQltyInspectionHeader.Status::Finished;
        ReQltyInspectionHeader.Modify();
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        Commit();

        // [GIVEN] Sleep to ensure modified timestamp is different
        Sleep(1001);

        // [GIVEN] Quality Management setup with "Only the most recently modified finished inspection" inspection selection criteria
        QltyManagementSetup.Get();
        QltyManagementSetup."Inspection Selection Criteria" := QltyManagementSetup."Inspection Selection Criteria"::"Only the most recently modified finished inspection";
        QltyManagementSetup.Modify();

        // [GIVEN] Inspection generation rule deleted to prevent new inspection creation
        QltyInspectionGenRule.Delete();

        // [GIVEN] Original inspection also marked as finished with blocking result (most recent modified)
        QltyInspectionHeader."Result Code" := ToLoadQltyInspectionResult.Code;
        QltyInspectionHeader.Status := QltyInspectionHeader.Status::Finished;
        QltyInspectionHeader.Modify();

        // [WHEN] Posting the assembly header
        // [THEN] An error is raised indicating assembly output is blocked by the most recent finished modified inspection result
        EnsureGenPostingSetupForAssemblyExists(AssemblyHeader);
        asserterror LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        LibraryAssert.ExpectedError(StrSubstNo(
            EntryTypeBlockedErr,
            QltyInspectionHeader.GetFriendlyIdentifier(),
            ToLoadQltyInspectionResult.Code,
            ItemJournalLine."Entry Type"::"Assembly Output",
            AssemblyHeader."Item No.",
            StrSubstNo(LotSerialTrackingDetailsTok, ReservationEntry."Lot No.", ReservationEntry."Serial No.")));
    end;

    [Test]
    procedure BlockTrackingWarehouseTransaction_Putaway_HighestFinishedReinspection_ShouldError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReQltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        ToUseNoSeries: Record "No. Series";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // [SCENARIO] Block warehouse put-away with HighestFinishedReinspection behavior should error

        Initialize();

        // [GIVEN] Inspection generation rules cleared
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] Inspection results cleared
        if not ToLoadQltyInspectionResult.IsEmpty() then
            ToLoadQltyInspectionResult.DeleteAll();

        // [GIVEN] Quality Management setup ensured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] Prioritized inspection generation rule for Purchase Line created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] Full WMS location with 1 zone created
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);

        // [GIVEN] Lot-tracked item with no series created
        QltyInspectionUtility.CreateLotTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] Purchase order with lot tracking created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] Inspection created for purchase line with tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Re-inspection created from original inspection
        QltyInspectionUtility.CreateReinspection(QltyInspectionHeader, ReQltyInspectionHeader);

        // [GIVEN] Inspection result configured to block put-away
        ToLoadQltyInspectionResult.FindFirst();
        QltyInspectionUtility.ClearResultLotSettings(ToLoadQltyInspectionResult);
        ToLoadQltyInspectionResult."Item Tracking Allow Put-Away" := ToLoadQltyInspectionResult."Item Tracking Allow Put-Away"::Block;
        ToLoadQltyInspectionResult.Modify();

        // [GIVEN] Original inspection marked as finished with blocking result
        QltyInspectionHeader."Result Code" := ToLoadQltyInspectionResult.Code;
        QltyInspectionHeader.Status := QltyInspectionHeader.Status::Finished;
        QltyInspectionHeader.Modify();

        // [GIVEN] Re-inspection assigned the blocking result (highest finished re-inspection)
        ReQltyInspectionHeader."Result Code" := ToLoadQltyInspectionResult.Code;
        ReQltyInspectionHeader.Modify();

        // [GIVEN] Quality Management setup with "Only the newest finished inspection/re-inspection" inspection selection criteria
        QltyManagementSetup.Get();
        QltyManagementSetup."Inspection Selection Criteria" := QltyManagementSetup."Inspection Selection Criteria"::"Only the newest finished inspection/re-inspection";
        QltyManagementSetup.Modify();

        // [WHEN] Receiving the purchase order
        // [THEN] An error is raised indicating put-away is blocked by the highest finished re-inspection result
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        asserterror QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        LibraryAssert.ExpectedError(StrSubstNo(
            WarehouseEntryTypeBlockedErr,
            QltyInspectionHeader.GetFriendlyIdentifier(),
            ToLoadQltyInspectionResult.Code,
            WarehouseActivityLine."Activity Type"::"Put-away",
            Item."No.",
            ReservationEntry."Lot No.",
            '',
            ''));
    end;

    [Test]
    procedure BlockTrackingWarehouseTransaction_Putaway_AnyFinished_ShouldError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        ToUseNoSeries: Record "No. Series";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // [SCENARIO] Block warehouse put-away with "Any finished inspection that matches" behavior should error

        Initialize();

        // [GIVEN] Inspection generation rules cleared
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] Inspection results cleared
        if not ToLoadQltyInspectionResult.IsEmpty() then
            ToLoadQltyInspectionResult.DeleteAll();

        // [GIVEN] Quality Management setup ensured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] Prioritized inspection generation rule for Purchase Line created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] Full WMS location with 1 zone created
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);

        // [GIVEN] Lot-tracked item with no series created
        QltyInspectionUtility.CreateLotTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] Purchase order with lot tracking created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] Inspection created for purchase line with tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Inspection result configured to block put-away
        ToLoadQltyInspectionResult.FindFirst();
        QltyInspectionUtility.ClearResultLotSettings(ToLoadQltyInspectionResult);
        ToLoadQltyInspectionResult."Item Tracking Allow Put-Away" := ToLoadQltyInspectionResult."Item Tracking Allow Put-Away"::Block;
        ToLoadQltyInspectionResult.Modify();

        // [GIVEN] Inspection marked as finished with blocking result
        QltyInspectionHeader."Result Code" := ToLoadQltyInspectionResult.Code;
        QltyInspectionHeader.Status := QltyInspectionHeader.Status::Finished;
        QltyInspectionHeader.Modify();

        // [GIVEN] Quality Management setup with "Any finished inspection that matches" inspection selection criteria
        QltyManagementSetup.Get();
        QltyManagementSetup."Inspection Selection Criteria" := QltyManagementSetup."Inspection Selection Criteria"::"Any finished inspection that matches";
        QltyManagementSetup.Modify();

        // [WHEN] Receiving the purchase order
        // [THEN] An error is raised indicating put-away is blocked by any finished inspection result
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        asserterror QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        LibraryAssert.ExpectedError(StrSubstNo(
            WarehouseEntryTypeBlockedErr,
            QltyInspectionHeader.GetFriendlyIdentifier(),
            ToLoadQltyInspectionResult.Code,
            WarehouseActivityLine."Activity Type"::"Put-away",
            Item."No.",
            ReservationEntry."Lot No.",
            '',
            ''));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BlockTrackingWarehouseTransaction_InvPutaway_MostRecentFinishedModified_ShouldError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReQltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        ConfigurationToLoadQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        Bin: Record Bin;
        ReservationEntry: Record "Reservation Entry";
        ToUseNoSeries: Record "No. Series";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // [SCENARIO] Block warehouse inventory put-away with "Only the most recently modified finished inspection" behavior should error

        Initialize();

        // [GIVEN] Inspection generation rules cleared
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] Inspection results cleared
        if not ToLoadQltyInspectionResult.IsEmpty() then
            ToLoadQltyInspectionResult.DeleteAll();

        // [GIVEN] Quality Management setup ensured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] Prioritized inspection generation rule for Purchase Line created (then cleared)
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] WMS location with bins created
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, false, false);

        LibraryWarehouse.CreateBin(Bin, Location.Code, 'Bin', '', '');

        // [GIVEN] Lot-tracked item with no series created
        QltyInspectionUtility.CreateLotTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] Purchase order with lot tracking created
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] Inspection created for purchase line with tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Purchase line with bin code assigned
        PurchaseLine."Bin Code" := Bin.Code;
        PurchaseLine.Modify();

        // [GIVEN] Re-inspection created from original inspection
        QltyInspectionUtility.CreateReinspection(QltyInspectionHeader, ReQltyInspectionHeader);

        // [GIVEN] Inspection result configured to block inventory put-away
        ToLoadQltyInspectionResult.FindFirst();
        QltyInspectionUtility.ClearResultLotSettings(ToLoadQltyInspectionResult);
        ToLoadQltyInspectionResult."Item Tracking Allow Invt. PA" := ToLoadQltyInspectionResult."Item Tracking Allow Invt. PA"::Block;
        ToLoadQltyInspectionResult.Modify();

        // [GIVEN] Re-inspection marked as finished with blocking result
        ReQltyInspectionHeader."Result Code" := ToLoadQltyInspectionResult.Code;
        ReQltyInspectionHeader.Status := QltyInspectionHeader.Status::Finished;
        ReQltyInspectionHeader.Modify();
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        Commit();

        // [GIVEN] Quality Management setup with "Only the most recently modified finished inspection" inspection selection criteria
        QltyManagementSetup.Get();

        // [GIVEN] Setup trigger defaults cleared
        QltyInspectionUtility.ClearSetupTriggerDefaults(QltyManagementSetup);
        QltyManagementSetup."Inspection Selection Criteria" := QltyManagementSetup."Inspection Selection Criteria"::"Only the most recently modified finished inspection";
        QltyManagementSetup.Modify();

        // [GIVEN] Original inspection also marked as finished with blocking result (most recent modified)
        QltyInspectionHeader."Result Code" := ToLoadQltyInspectionResult.Code;
        QltyInspectionHeader.Status := QltyInspectionHeader.Status::Finished;
        QltyInspectionHeader.Modify();

        // [WHEN] Receiving the purchase order
        // [THEN] An error is raised indicating inventory put-away is blocked by the most recent finished modified inspection result
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        asserterror QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);
        LibraryAssert.ExpectedError(StrSubstNo(
            WarehouseEntryTypeBlockedErr,
            QltyInspectionHeader.GetFriendlyIdentifier(),
            ToLoadQltyInspectionResult.Code,
            WarehouseActivityLine."Activity Type"::"Invt. Put-away",
            Item."No.",
            ReservationEntry."Lot No.",
            '',
            ''));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BlockTrackingWarehouseTransaction_InvMovement_HighestReinspection_ShouldError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReQltyInspectionHeader: Record "Qlty. Inspection Header";
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
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // [SCENARIO] Block warehouse inventory movement with HighestReinspection behavior should error

        Initialize();

        // [GIVEN] Inspection generation rules cleared
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] Inspection results cleared
        if not ToLoadQltyInspectionResult.IsEmpty() then
            ToLoadQltyInspectionResult.DeleteAll();

        // [GIVEN] Quality Management setup ensured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] Prioritized inspection generation rule for Purchase Line created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] WMS location with bins created
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, false, false);

        // [GIVEN] Current warehouse employee set for the location
        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        // [GIVEN] Two bins created (Bin1 and Bin2)
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin1Tok, '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin2Tok, '', '');

        // [GIVEN] Lot-tracked item with no series created
        QltyInspectionUtility.CreateLotTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] Purchase order with lot tracking created and assigned to Bin1
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        PurchaseLine."Bin Code" := Bin1Tok;
        PurchaseLine.Modify();

        // [GIVEN] Purchase order released and received
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] Inspection created for purchase line with tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Re-inspection created from original inspection
        QltyInspectionUtility.CreateReinspection(QltyInspectionHeader, ReQltyInspectionHeader);

        // [GIVEN] Inspection result configured to block inventory movement
        ToLoadQltyInspectionResult.FindFirst();
        QltyInspectionUtility.ClearResultLotSettings(ToLoadQltyInspectionResult);
        ToLoadQltyInspectionResult."Item Tracking Allow Invt. Mov." := ToLoadQltyInspectionResult."Item Tracking Allow Invt. Mov."::Block;
        ToLoadQltyInspectionResult.Modify();

        // [GIVEN] Re-inspection marked as finished with blocking result
        ReQltyInspectionHeader."Result Code" := ToLoadQltyInspectionResult.Code;
        ReQltyInspectionHeader.Status := QltyInspectionHeader.Status::Finished;
        ReQltyInspectionHeader.Modify();
        Commit();
        Sleep(1001);

        // [GIVEN] Quality Management setup with "Only the newest inspection/re-inspection" inspection selection criteria
        QltyManagementSetup.Get();
        QltyManagementSetup."Inspection Selection Criteria" := QltyManagementSetup."Inspection Selection Criteria"::"Only the newest inspection/re-inspection";
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

        // [GIVEN] Original inspection also marked as finished with blocking result
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        QltyInspectionHeader."Result Code" := ToLoadQltyInspectionResult.Code;
        QltyInspectionHeader.Status := QltyInspectionHeader.Status::Finished;
        QltyInspectionHeader.Modify();

        // [WHEN] Registering the warehouse inventory movement
        // [THEN] An error is raised indicating inventory movement is blocked by the highest re-inspection result
        asserterror LibraryWarehouse.RegisterWhseActivity(InventoryMovementWarehouseActivityHeader);
        LibraryAssert.ExpectedError(StrSubstNo(
            WarehouseEntryTypeBlockedErr,
            ReQltyInspectionHeader.GetFriendlyIdentifier(),
            ToLoadQltyInspectionResult.Code,
            WarehouseActivityLine."Activity Type"::"Invt. Movement",
            Item."No.",
            ReservationEntry."Lot No.",
            '',
            ''));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BlockTrackingWarehouseTransaction_Movement_MostRecentModified_ShouldError()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ToLoadQltyInspectionResult: Record "Qlty. Inspection Result";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReQltyInspectionHeader: Record "Qlty. Inspection Header";
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
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        WhseWorksheetTemplateToUse: Text;
    begin
        // [SCENARIO] Block warehouse movement with "Only the most recently modified inspection" behavior should error

        Initialize();

        // [GIVEN] Inspection generation rules cleared
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] Inspection results cleared
        if not ToLoadQltyInspectionResult.IsEmpty() then
            ToLoadQltyInspectionResult.DeleteAll();

        // [GIVEN] Quality Management setup ensured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] Prioritized inspection generation rule for Purchase Line created
        QltyInspectionUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] Full WMS location with 2 zones created
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        // [GIVEN] Current warehouse employee set for the location
        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        // [GIVEN] Lot-tracked item with no series created
        QltyInspectionUtility.CreateLotTrackedItem(Item, ToUseNoSeries);

        // [GIVEN] Purchase order with lot tracking created, released and received
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        QltyPurOrderGenerator.ReceivePurchaseOrder(Location, PurchaseHeader, PurchaseLine);

        // [GIVEN] Inspection created for purchase line with tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Re-inspection created from original inspection
        QltyInspectionUtility.CreateReinspection(QltyInspectionHeader, ReQltyInspectionHeader);

        // [GIVEN] Inspection result configured to block movement
        ToLoadQltyInspectionResult.FindFirst();
        QltyInspectionUtility.ClearResultLotSettings(ToLoadQltyInspectionResult);
        ToLoadQltyInspectionResult."Item Tracking Allow Movement" := ToLoadQltyInspectionResult."Item Tracking Allow Movement"::Block;
        ToLoadQltyInspectionResult.Modify();

        // [GIVEN] Re-inspection marked as finished with blocking result
        ReQltyInspectionHeader."Result Code" := ToLoadQltyInspectionResult.Code;
        ReQltyInspectionHeader.Status := ReQltyInspectionHeader.Status::Finished;
        ReQltyInspectionHeader.Modify();
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
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

        // [GIVEN] Quality Management setup with "Only the most recently modified inspection" inspection selection criteria
        QltyManagementSetup.Get();
        QltyManagementSetup."Inspection Selection Criteria" := QltyManagementSetup."Inspection Selection Criteria"::"Only the most recently modified inspection";
        QltyManagementSetup.Modify();

        // [GIVEN] Original inspection assigned the blocking result (most recent modified)
        QltyInspectionHeader."Result Code" := ToLoadQltyInspectionResult.Code;
        QltyInspectionHeader.Modify();

        // [GIVEN] Warehouse worksheet template for Movement type ensured
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Movement);
        if WhseWorksheetTemplate.IsEmpty() then begin
            QltyInspectionUtility.GenerateRandomCharacters(10, WhseWorksheetTemplateToUse);
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
        // [THEN] An error is raised indicating movement is blocked by the most recent modified inspection result
        asserterror LibraryWarehouse.RegisterWhseActivity(WhseMovementWarehouseActivityHeader);
        LibraryAssert.ExpectedError(StrSubstNo(
            WarehouseEntryTypeBlockedErr,
            QltyInspectionHeader.GetFriendlyIdentifier(),
            ToLoadQltyInspectionResult.Code,
            WarehouseActivityLine."Activity Type"::Movement,
            Item."No.",
            ReservationEntry."Lot No.",
            '',
            ''));
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
        Notification: Notification;
        WhseWorksheetTemplateToUse: Text;
    begin
        // [SCENARIO] Notification management handles opening warehouse movement document
        Initialize();

        // [GIVEN] Quality Management setup ensured
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] Full WMS location with 3 zones created
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);

        // [GIVEN] Current warehouse employee set for the location
        QltyInspectionUtility.SetCurrLocationWhseEmployee(Location.Code);

        // [GIVEN] Cleared warehouse worksheet lines, names, and templates
        if not WhseWorksheetLine.IsEmpty() then
            WhseWorksheetLine.DeleteAll();
        if not WhseWorksheetName.IsEmpty() then
            WhseWorksheetName.DeleteAll();
        if not WhseWorksheetTemplate.IsEmpty() then
            WhseWorksheetTemplate.DeleteAll();

        // [GIVEN] Warehouse worksheet template for Movement with page ID assigned
        WhseWorksheetTemplate.Init();
        QltyInspectionUtility.GenerateRandomCharacters(10, WhseWorksheetTemplateToUse);
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
        QltyInspectionUtility.HandleOpenDocument(Notification);

        // [THEN] The warehouse movement document page opens and the handler validates the correct document number
        LibraryAssert.AreEqual(WhseMovementWarehouseActivityHeader."No.", DocumentNo, 'Should navigate to the movement document');
    end;


    [Test]
    procedure HandleNotificationActionAssignToSelf()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        MockNotification: Notification;
    begin
        // [SCENARIO] Notification action handler successfully assigns quality inspection to the current user

        // [GIVEN] Quality management setup with location, item, and inspection template are configured
        Initialize();

        QltyInspectionUtility.EnsureSetupExists();
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A quality inspection is created from a purchase line for an untracked item
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);
        QltyInspectionGenRule.Delete();

        // [GIVEN] A mock notification with the inspection record ID is prepared
        MockNotification.SetData(NotificationDataInspectionRecordIdTok, Format(QltyInspectionHeader.RecordId));

        // [WHEN] The assign to self notification action is handled
        QltyInspectionUtility.HandleNotificationActionAssignToSelf(MockNotification);

        // [THEN] The quality inspection is assigned to the current user
        QltyInspectionHeader.Get(QltyInspectionHeader."No.", QltyInspectionHeader."Re-inspection No.");
        LibraryAssert.AreEqual(QltyInspectionHeader."Assigned User Id", UserId(), 'Inspection should be assigned to the current user');
    end;

    [Test]
    procedure HandleNotificationActionIgnore()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        MockNotification: Notification;
    begin
        // [SCENARIO] Notification action handler successfully sets quality inspection to prevent auto assignment when ignored

        // [GIVEN] Quality management setup with location, item, and inspection template are configured
        Initialize();

        QltyInspectionUtility.EnsureSetupExists();
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A quality inspection is created from a purchase line for an untracked item
        QltyPurOrderGenerator.CreateInspectionFromPurchaseWithUntrackedItem(Location, 100, PurchaseHeader, PurchaseLine, QltyInspectionHeader);
        QltyInspectionGenRule.Delete();

        // [GIVEN] A mock notification with the inspection record ID is prepared
        MockNotification.SetData(NotificationDataInspectionRecordIdTok, Format(QltyInspectionHeader.RecordId()));

        // [WHEN] The ignore notification action is handled
        QltyInspectionUtility.HandleNotificationActionIgnore(MockNotification);

        // [THEN] The quality inspection is marked to prevent auto assignment
        LibraryAssert.IsTrue(QltyInspectionHeader.GetPreventAutoAssignment(), 'Inspection should be ignored');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
    end;

    local procedure EnsureGenPostingSetupForAssemblyExists(AssemblyHeader: Record "Assembly Header")
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
}