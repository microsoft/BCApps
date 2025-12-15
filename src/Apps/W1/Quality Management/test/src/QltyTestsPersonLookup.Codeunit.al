// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Test;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Resources.Resource;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Test.QualityManagement.TestLibraries;
using System.Security.AccessControl;
using System.Security.User;
using System.TestLibraries.Utilities;

codeunit 139979 "Qlty. Tests - Person Lookup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        Any: Codeunit Any;
        IsInitialized: Boolean;

    [Test]
    procedure GetBasicPersonDetails_DoesNotExist()
    var
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
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
        LibraryAssert.AreEqual(false, QltyPersonLookup.GetBasicPersonDetails('Does not exist', FullName, OutJobTitle, Email, OutPhone, OutSourceRecord), 'there should be no match');
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
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
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
        LibraryAssert.AreEqual(true, QltyPersonLookup.GetBasicPersonDetails(Contact."No.", FullName, OutJobTitle, Email, OutPhone, OutSourceRecord), 'there should be a match');

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
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
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
        LibraryAssert.AreEqual(true, QltyPersonLookup.GetBasicPersonDetails(Employee."No.", FullName, JobTitle, Email, OutPhone, OutSourceRecord), 'there should be a match');

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
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
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
        LibraryAssert.AreEqual(true, QltyPersonLookup.GetBasicPersonDetails(Resource."No.", FullName, JobTitle, Email, OutPhone, OutSourceRecord), 'there should be a match');

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
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
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
        LibraryAssert.AreEqual(true, QltyPersonLookup.GetBasicPersonDetails(User."User Name", FullName, JobTitle, Email, OutPhone, OutSourceRecord), 'there should be a match');

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
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
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
        LibraryAssert.AreEqual(true, QltyPersonLookup.GetBasicPersonDetails(UserSetup."User ID", FullName, JobTitle, Email, OutPhone, OutSourceRecord), 'there should be a match');

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
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
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
        LibraryAssert.AreEqual(true, QltyPersonLookup.GetBasicPersonDetails(UserSetup."User ID", FullName, JobTitle, Email, OutPhone, OutSourceRecord), 'there should be a match');

        LibraryAssert.AreEqual(SalespersonPurchaser.Name, FullName, 'FullName should have been supplied');
        LibraryAssert.AreEqual(SalespersonPurchaser."Job Title", JobTitle, 'OutJobTitle should have been set');
        LibraryAssert.AreEqual(SalespersonPurchaser."E-Mail", Email, 'Email should have been set');
        LibraryAssert.AreEqual(SalespersonPurchaser."Phone No.", OutPhone, 'OutPhone should have been set');
        LibraryAssert.AreEqual(Database::"Salesperson/Purchaser", OutSourceRecord.TableNo(), 'OutSourceRecord should have been a Salesperson/Purchaser record');
        LibraryAssert.AreEqual(SalespersonPurchaser.RecordId(), OutSourceRecord, 'OutSourceRecord should have been a specific Salesperson/Purchaser record');
    end;

    [Test]
    procedure GetBasicPersonDetailsFromTestLine()
    var
        User: Record User;
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        LookupQualityMeasureQltyField: Record "Qlty. Field";
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
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibrarySales: Codeunit "Library - Sales";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        OutSourceRecord: RecordId;
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
        FullName: Text;
        JobTitle: Text;
        Email: Text;
        OutPhone: Text;
    begin
        // [SCENARIO] Get person details from a test line with table lookup field

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

        QltyTestsUtility.EnsureSetup();

        // [GIVEN] An inspection template with a table lookup field for Salesperson/Purchaser
        QltyTestsUtility.CreateTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, 2);
        QltyTestsUtility.CreateFieldAndAddToTemplate(ConfigurationToLoadQltyInspectionTemplateHdr, LookupQualityMeasureQltyField."Field Type"::"Field Type Table Lookup", LookupQualityMeasureQltyField, ConfigurationToLoadQltyInspectionTemplateLine);
        LookupQualityMeasureQltyField."Lookup Table No." := Database::"Salesperson/Purchaser";
        LookupQualityMeasureQltyField."Lookup Field No." := SalespersonPurchaser.FieldNo(Code);
        LookupQualityMeasureQltyField.Modify(false);

        // [GIVEN] A production order with routing line
        QltyTestsUtility.CreatePrioritizedRule(ConfigurationToLoadQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");
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

        // [GIVEN] A test line with a Salesperson/Purchaser code value
        QltyInspectionTestLine.SetRange("Test No.", QltyInspectionTestHeader."No.");
        QltyInspectionTestLine.SetRange("ReTest No.", QltyInspectionTestHeader."ReTest No.");
        QltyInspectionTestLine.SetRange("Field Code", LookupQualityMeasureQltyField.Code);

        LibraryAssert.AreEqual(1, QltyInspectionTestLine.Count(), 'there should  be exactly one test line that matches.');
        QltyInspectionTestLine.FindFirst();
        QltyInspectionTestLine.Validate("Test Value", SalespersonPurchaser.Code);
        QltyInspectionTestLine.Modify();

        // [WHEN] GetBasicPersonDetailsFromTestLine is called with the test line
        // [THEN] The function returns true and populates person details from the linked Salesperson/Purchaser
        LibraryAssert.AreEqual(true, QltyPersonLookup.GetBasicPersonDetailsFromTestLine(QltyInspectionTestLine, FullName, JobTitle, Email, OutPhone, OutSourceRecord), 'there should be a match');

        LibraryAssert.AreEqual(SalespersonPurchaser.Name, FullName, 'FullName should have been supplied');
        LibraryAssert.AreEqual(SalespersonPurchaser."Job Title", JobTitle, 'OutJobTitle should have been set');
        LibraryAssert.AreEqual(SalespersonPurchaser."E-Mail", Email, 'Email should have been set');
        LibraryAssert.AreEqual(SalespersonPurchaser."Phone No.", OutPhone, 'OutPhone should have been set');
        LibraryAssert.AreEqual(Database::"Salesperson/Purchaser", OutSourceRecord.TableNo(), 'OutSourceRecord should have been a Salesperson/Purchaser record');
        LibraryAssert.AreEqual(SalespersonPurchaser.RecordId(), OutSourceRecord, 'OutSourceRecord should have been a specific Salesperson/Purchaser record');
    end;

    [Test]
    procedure GetBasicPersonDetailsFromTestLine_EmptyRecord()
    var
        TempEmptyQltyInspectionTestLine: Record "Qlty. Inspection Test Line" temporary;
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
        OutSourceRecord: RecordId;
        FullName: Text;
        JobTitle: Text;
        Email: Text;
        OutPhone: Text;
    begin
        // [SCENARIO] Attempt to get person details from an empty test line

        Initialize();

        // [GIVEN] An empty test line record

        // [WHEN] GetBasicPersonDetailsFromTestLine is called with the empty record
        // [THEN] The function returns false and all output parameters remain empty
        Clear(TempEmptyQltyInspectionTestLine);
        LibraryAssert.AreEqual(false, QltyPersonLookup.GetBasicPersonDetailsFromTestLine(TempEmptyQltyInspectionTestLine, FullName, JobTitle, Email, OutPhone, OutSourceRecord), 'should be nothing.');

        LibraryAssert.AreEqual('', FullName, 'FullName should have been empty');
        LibraryAssert.AreEqual('', JobTitle, 'OutJobTitle should have been empty');
        LibraryAssert.AreEqual('', Email, 'Email should have been empty');
        LibraryAssert.AreEqual('', OutPhone, 'OutPhone should have been empty');
        LibraryAssert.AreEqual(0, OutSourceRecord.TableNo(), 'should have been empty');
    end;

    local procedure Initialize()
    var
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
    begin
        if IsInitialized then
            exit;

        QltyTestsUtility.EnsureSetup();
        IsInitialized := true;
    end;
}
