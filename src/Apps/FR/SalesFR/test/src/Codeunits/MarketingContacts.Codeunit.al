// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using System.TestLibraries.Utilities;

codeunit 148005 "Marketing Contacts"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Contact] [Marketing]
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTemplates: Codeunit "Library - Templates";
        LibrarySales: Codeunit "Library - Sales";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;

    [Test]
    procedure CustomerHasSirenNoFromContact()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        // [SCENARIO 467032] Customer has SIREN No. when created from Contact
        Initialize();

        // [GIVEN] Contact created with SIREN No.
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("SIREN No. FR", CopyStr(LibraryUtility.GenerateRandomNumericText(9), 1, MaxStrLen(Contact."SIREN No. FR")));
        Contact.Modify(true);

        // [GIVEN] Customer created from Contact
        Contact.SetHideValidationDialog(true);
        Contact.CreateCustomerFromTemplate('');

        // [THEN] Customer has SIREN No. from Contact
        Customer.SetRange(Name, Contact.Name);
        Customer.FindFirst();
        Customer.TestField("SIREN No. FR", Contact."SIREN No. FR");
    end;

    [Test]
    procedure CustomerSIRENNoIsNotChangedWhenLinkedContactPhoneNoIsModified()
    begin
        // [SCENARIO 641872] Updating a contact without a SIREN No. does not clear the customer's SIREN No.
        Initialize();
        VerifyCustomerSIRENNoIsPreserved('123456789', '');
    end;

    [Test]
    procedure CustomerSIRENNoIsNotOverwrittenFromLinkedContact()
    begin
        // [SCENARIO] Updating a contact with a different SIREN No. preserves the customer's SIREN No.
        Initialize();
        VerifyCustomerSIRENNoIsPreserved('123456789', '987654321');
    end;

    [Test]
    procedure EmptyCustomerSIRENNoIsPreservedWhenLinkedContactChanges()
    begin
        // [SCENARIO] Updating a contact does not populate an intentionally blank customer SIREN No.
        Initialize();
        VerifyCustomerSIRENNoIsPreserved('', '987654321');
    end;

    local procedure VerifyCustomerSIRENNoIsPreserved(CustomerSIRENNo: Code[9]; ContactSIRENNo: Code[9])
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
    begin
        // [GIVEN] A customer and its linked contact have independently assigned SIREN numbers.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("SIREN No. FR", CustomerSIRENNo);
        Customer.Modify(true);
        ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, Customer."No.");
        Contact.Get(ContactBusinessRelation."Contact No.");
        Contact.Validate("SIREN No. FR", ContactSIRENNo);
        Contact.Modify();

        // [WHEN] The contact's phone number is modified.
        Contact.Validate("Phone No.", LibraryUtility.GenerateRandomPhoneNo());
        Contact.Modify(true);

        // [THEN] The phone number is synchronized without changing either SIREN number.
        Customer.Get(Customer."No.");
        Customer.TestField("Phone No.", Contact."Phone No.");
        Customer.TestField("SIREN No. FR", CustomerSIRENNo);
        Contact.Get(Contact."No.");
        Contact.TestField("SIREN No. FR", ContactSIRENNo);
    end;

    local procedure Initialize()
    var
        MarketingSetup: Record "Marketing Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Marketing Contacts");
        BindActiveDirectoryMockEvents();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Marketing Contacts");

        LibraryTemplates.EnableTemplatesFeature();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        MarketingSetup.Get();
        MarketingSetup.Validate("Maintain Dupl. Search Strings", false);
        MarketingSetup.Modify(true);

        LibrarySetupStorage.Save(Database::"Marketing Setup");
        LibrarySetupStorage.Save(Database::"Company Information");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Marketing Contacts");
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled() then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable();
    end;
}
