// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument.Formats;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;

codeunit 148146 "Identification Tests"
{
    Subtype = Test;
    Permissions = tabledata "Company Information" = rimd;

    trigger OnRun()
    begin
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        EDocHelpers: Codeunit "EDoc. Helpers";
        DialogErrorCodeTok: Label 'Dialog', Locked = true;
        IsInitialized: Boolean;

    [Test]
    procedure CheckSIRENNotEmptyRaisesErrorWhenEmpty()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] CheckSIRENNotEmpty raises error when Registration No. is blank
        Initialize();

        // [GIVEN] Company Information with blank Registration No.
        CompanyInformation.Get();
        CompanyInformation."Registration No." := '';
        CompanyInformation.Modify();

        // [WHEN] CheckSIRENNotEmpty is called
        asserterror EDocHelpers.CheckSIRENNotEmpty();

        // [THEN] Error is raised
        AssertExpectedDialogError(EDocHelpers.GetSIRENRequiredError());
    end;

    [Test]
    procedure CheckSIRETNotEmptyRaisesErrorWhenEmpty()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] CheckSIRETNotEmpty raises error when SIRET is blank
        Initialize();

        // [GIVEN] Company Information with blank SIRET No.
        CompanyInformation.Get();
        CompanyInformation."SIRET No." := '';
        CompanyInformation.Modify();

        // [WHEN] CheckSIRETNotEmpty is called
        asserterror EDocHelpers.CheckSIRETNotEmpty();

        // [THEN] Error is raised
        AssertExpectedDialogError(EDocHelpers.GetSIRETRequiredError());
    end;

    [Test]
    procedure CheckSIRENNotEmptyDoesNotErrorWhenRegistrationNoPresent()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] CheckSIRENNotEmpty succeeds when Registration No. is set
        Initialize();

        // [GIVEN] Company Information with Registration No. set
        CompanyInformation.Get();
        CompanyInformation."Registration No." := '123456789';
        CompanyInformation.Modify();

        // [WHEN] CheckSIRENNotEmpty is called
        // [THEN] No error is raised
        EDocHelpers.CheckSIRENNotEmpty();
    end;

    [Test]
    procedure CheckSIRETNotEmptyDoesNotErrorWhenSIRETPresent()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] CheckSIRETNotEmpty succeeds when SIRET No. is set
        Initialize();

        // [GIVEN] Company Information with SIRET No. set
        CompanyInformation.Get();
        CompanyInformation."SIRET No." := '12345678901234';
        CompanyInformation.Modify();

        // [WHEN] CheckSIRETNotEmpty is called
        // [THEN] No error is raised
        EDocHelpers.CheckSIRETNotEmpty();
    end;

    [Test]
    procedure BuyerSIRENPrefersRegistrationNumber()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Legal registration takes precedence over routing and VAT identifiers.
        Initialize();

        // [GIVEN] Customer "C" with distinct registration, routing and VAT identifiers.
        Customer."Registration Number" := '012345678';
        Customer."FR Electronic Address" := '987654321_001';
        Customer."VAT Registration No." := 'FR12123456789';

        // [WHEN] Resolve the buyer SIREN.
        // [THEN] The registration number takes precedence and retains leading zeroes.
        Assert.AreEqual('012345678', EDocHelpers.GetBuyerSIREN(Customer),
            'The buyer SIREN must come from the registration number and retain leading zeroes.');
    end;

    [Test]
    procedure BuyerSIRENIsExtractedFromRegistrationSIRET()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A registration number containing a SIRET supplies its first nine digits.
        Initialize();

        // [GIVEN] Customer "C" with a registration SIRET and a different routing SIREN.
        Customer."Registration Number" := '01234567800012';
        Customer."FR Electronic Address" := '987654321_001';

        // [WHEN] Resolve the buyer SIREN.
        // [THEN] The first nine registration digits take precedence over routing.
        Assert.AreEqual('012345678', EDocHelpers.GetBuyerSIREN(Customer),
            'A registration SIRET must supply the legal SIREN before routing is considered.');
    end;

    [Test]
    procedure BuyerSIRENFallsBackToElectronicAddress()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An unusable registration falls back to the routing SIREN without its suffix.
        Initialize();

        // [GIVEN] Customer "C" with an invalid registration and usable routing and VAT identifiers.
        Customer."Registration Number" := '12345678A';
        Customer."FR Electronic Address" := '012345678_001';
        Customer."VAT Registration No." := 'FR12987654321';

        // [WHEN] Resolve the buyer SIREN.
        // [THEN] Routing supplies the SIREN without its suffix and retains leading zeroes.
        Assert.AreEqual('012345678', EDocHelpers.GetBuyerSIREN(Customer),
            'The routing suffix must not be included in the legal SIREN.');
    end;

    [Test]
    procedure BuyerSIRENFallsBackToFrenchVAT()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] French VAT supplies the SIREN when registration and routing cannot.
        Initialize();

        // [GIVEN] Customer "C" with invalid registration and routing and a lowercase, spaced French VAT.
        Customer."Registration Number" := '12345678';
        Customer."FR Electronic Address" := '12345678A_001';
        Customer."VAT Registration No." := 'fr 12 012345678';

        // [WHEN] Resolve the buyer SIREN.
        // [THEN] French VAT supplies the SIREN after normalization and retains leading zeroes.
        Assert.AreEqual('012345678', EDocHelpers.GetBuyerSIREN(Customer),
            'French VAT must supply the SIREN after removing spaces and accepting lowercase FR.');
    end;

    [Test]
    procedure BuyerSIRENIsEmptyWithoutUsableIdentifiers()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Missing or unusable identifiers do not raise an error or produce a legal SIREN.
        Initialize();

        // [GIVEN] Customer "C" with no identifiers.

        // [WHEN] Resolve the buyer SIREN.
        // [THEN] No legal SIREN is returned.
        Assert.AreEqual('', EDocHelpers.GetBuyerSIREN(Customer),
            'An empty customer must not supply a legal SIREN.');

        // [GIVEN] Customer "C" with invalid registration and routing and a non-French VAT.
        Customer."Registration Number" := '12345678A';
        Customer."FR Electronic Address" := '12345678A_001';
        Customer."VAT Registration No." := 'DE12012345678';

        // [WHEN] Resolve the buyer SIREN.
        // [THEN] No legal SIREN is returned.
        Assert.AreEqual('', EDocHelpers.GetBuyerSIREN(Customer),
            'Unusable identifiers and non-French VAT must not supply a legal SIREN.');
    end;

    local procedure AssertExpectedDialogError(ExpectedErrorText: Text)
    begin
        Assert.ExpectedError(ExpectedErrorText);
        Assert.ExpectedErrorCode(DialogErrorCodeTok);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Identification Tests");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Identification Tests");
        LibrarySetupStorage.SaveCompanyInformation();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Identification Tests");
    end;
}
