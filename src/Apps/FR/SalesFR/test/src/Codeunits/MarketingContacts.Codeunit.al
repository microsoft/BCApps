// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Setup;
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
    begin
        // [SCENARIO 467032] Customer has SIREN No. when created from Contact
        Initialize();

        // [GIVEN] Contact created with SIREN No.
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("SIREN No. FR", LibraryUtility.GenerateRandomNumericText(9));
        Contact.Modify(true);

        // [GIVEN] Customer created from Contact
        Contact.SetHideValidationDialog(true);
        Contact.CreateCustomerFromTemplate('');

        // [THEN] Customer has SIREN No. from Contact
        Customer.SetRange(Name, Contact.Name);
        Customer.FindFirst();
        Customer.TestField("SIREN No. FR", Contact."SIREN No. FR");
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
