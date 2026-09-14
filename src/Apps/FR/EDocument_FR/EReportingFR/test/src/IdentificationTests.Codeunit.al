// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument.Formats;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 148146 "Identification Tests"
{
    Subtype = Test;
    Permissions = tabledata "Company Information" = rimd,
                  tabledata Customer = rimd,
                  tabledata Vendor = rimd;

    trigger OnRun()
    begin
        // [FEATURE] [FR Identification]
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
    procedure SIRENValidationRequiresExactlyNineNumericDigits()
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] SIREN validation accepts only exactly nine numeric digits
        Initialize();

        // [WHEN] SIREN values are validated
        // [THEN] Only the nine-digit numeric value is valid
        Assert.IsTrue(EDocHelpers.IsValidSIREN('123456789'), 'A nine-digit numeric SIREN should be valid.');
        Assert.IsFalse(EDocHelpers.IsValidSIREN('12345678'), 'A short SIREN should be invalid.');
        Assert.IsFalse(EDocHelpers.IsValidSIREN('1234567890'), 'A long SIREN should be invalid.');
        Assert.IsFalse(EDocHelpers.IsValidSIREN('12345A789'), 'A nonnumeric SIREN should be invalid.');
    end;

    [Test]
    procedure SIRETValidationRequiresExactlyFourteenNumericDigits()
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] SIRET validation accepts only exactly fourteen numeric digits
        Initialize();

        // [WHEN] SIRET values are validated
        // [THEN] Only the fourteen-digit numeric value is valid
        Assert.IsTrue(EDocHelpers.IsValidSIRET('12345678901234'), 'A fourteen-digit numeric SIRET should be valid.');
        Assert.IsFalse(EDocHelpers.IsValidSIRET('1234567890123'), 'A short SIRET should be invalid.');
        Assert.IsFalse(EDocHelpers.IsValidSIRET('123456789012345'), 'A long SIRET should be invalid.');
        Assert.IsFalse(EDocHelpers.IsValidSIRET('123456789A1234'), 'A nonnumeric SIRET should be invalid.');
    end;

    [Test]
    procedure SIRENIsDerivedFromValidSIRET()
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] The first nine digits of a valid SIRET form its SIREN
        Initialize();

        // [WHEN] SIREN is derived from SIRET
        // [THEN] The first nine digits are returned
        Assert.AreEqual('123456789', EDocHelpers.GetSIRENFromSIRET('12345678901234'), 'Wrong SIREN derived from SIRET.');
        Assert.AreEqual('', EDocHelpers.GetSIRENFromSIRET('123456789_0123'), 'An invalid SIRET must not produce a SIREN.');
    end;

    [Test]
    procedure CompanyIdentifiersAcceptCoherentSIRENAndSIRET()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Company Information accepts a coherent SIREN and SIRET
        Initialize();

        // [GIVEN] Company Information with coherent legal identifiers
        CompanyInformation.Get();
        CompanyInformation."Registration No." := '123456789';
        CompanyInformation."SIRET No." := '12345678901234';

        // [WHEN] The identifiers are validated
        // [THEN] No error is raised
        EDocHelpers.ValidateCompanyIdentifiers(CompanyInformation);
    end;

    [Test]
    procedure CompanyIdentifiersRejectConflictingSIRENAndSIRET()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Company Information rejects legal identifiers for different entities
        Initialize();

        // [GIVEN] Company Information with conflicting legal identifiers
        CompanyInformation.Get();
        CompanyInformation."Registration No." := '123456789';
        CompanyInformation."SIRET No." := '98765432101234';

        // [WHEN] The identifiers are validated
        asserterror EDocHelpers.ValidateCompanyIdentifiers(CompanyInformation);

        // [THEN] A coherence error is raised
        Assert.ExpectedError('do not identify the same legal entity');
    end;

    [Test]
    procedure CustomerSIRETRejectsConflictWithValidSIREN()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Customer SIRET rejects a conflict with a valid Registration Number SIREN
        Initialize();

        // [GIVEN] Customer "C" with a valid SIREN
        Customer.Init();
        Customer."No." := 'SIREN-CUSTOMER';
        Customer."Registration Number" := '123456789';

        Customer."FR Electronic Address" := '98765432101234';
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::"0009";

        // [WHEN] The Customer identifiers are validated
        asserterror EDocHelpers.ValidateCustomerIdentifiers(Customer);

        // [THEN] A coherence error is raised
        Assert.ExpectedError('do not identify the same legal entity');
    end;

    [Test]
    procedure VendorSIRETUsesExistingElectronicAddressForScheme0009()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Vendor SIRET is read from the existing electronic address only for scheme 0009
        Initialize();

        // [GIVEN] Vendor "V" with a SIRET electronic address using scheme 0009
        Vendor.Init();
        Vendor."No." := 'SIRET-VENDOR';
        Vendor."FR Electronic Address" := '12345678901234';
        Vendor."FR Elec. Address Scheme" := Vendor."FR Elec. Address Scheme"::"0009";

        // [WHEN] The Vendor SIRET is resolved
        // [THEN] The electronic address is returned as SIRET
        Assert.AreEqual('12345678901234', EDocHelpers.GetVendorSIRET(Vendor), 'Wrong Vendor SIRET.');
    end;

    [Test]
    procedure ElectronicAddressValidationDependsOnScheme()
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Electronic addresses are validated according to their selected scheme
        Initialize();

        // [WHEN] Electronic addresses are validated
        // [THEN] Each supported scheme accepts its own format and rejects mismatched formats
        Assert.IsTrue(EDocHelpers.IsValidElectronicAddress('123456789', "Electronic Address Scheme"::"0002"), 'Scheme 0002 should accept SIREN.');
        Assert.IsTrue(EDocHelpers.IsValidElectronicAddress('12345678901234', "Electronic Address Scheme"::"0009"), 'Scheme 0009 should accept SIRET.');
        Assert.IsFalse(EDocHelpers.IsValidElectronicAddress('123456789_001', "Electronic Address Scheme"::"0009"), 'Scheme 0009 must reject SIREN suffix.');
        Assert.IsTrue(EDocHelpers.IsValidElectronicAddress('123456789_001', "Electronic Address Scheme"::"0225"), 'Scheme 0225 should accept SIREN suffix.');
        Assert.IsTrue(EDocHelpers.IsValidElectronicAddress('FR12123456789', "Electronic Address Scheme"::"9957"), 'Scheme 9957 should accept French VAT identifiers.');
        Assert.IsTrue(EDocHelpers.IsValidElectronicAddress('buyer@example.fr', "Electronic Address Scheme"::"EM"), 'Scheme EM should accept an email address.');
        Assert.IsFalse(EDocHelpers.IsValidElectronicAddress('123456789', "Electronic Address Scheme"::" "), 'A blank scheme must reject an explicit address.');
    end;

    [Test]
    procedure AmbiguousSIRETDoesNotSelectVendorOrUseWeakerFallback()
    var
        FirstVendor: Record Vendor;
        SecondVendor: Record Vendor;
        VendorNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Duplicate SIRET values prevent automatic Vendor selection
        Initialize();

        // [GIVEN] Vendors "V1" and "V2" with the same SIRET
        FirstVendor."No." := 'SIRET-V1';
        FirstVendor."FR Electronic Address" := '12345678901234';
        FirstVendor."FR Elec. Address Scheme" := FirstVendor."FR Elec. Address Scheme"::"0009";
        FirstVendor.Insert();
        SecondVendor."No." := 'SIRET-V2';
        SecondVendor."FR Electronic Address" := '12345678901234';
        SecondVendor."FR Elec. Address Scheme" := SecondVendor."FR Elec. Address Scheme"::"0009";
        SecondVendor.Insert();

        // [WHEN] Vendor matching is attempted with the duplicate SIRET
        Assert.IsTrue(EDocHelpers.FindVendorByLegalIdentifiers('12345678901234', '987654321', VendorNo), 'The legal identifier should be handled.');

        // [THEN] No Vendor is selected and SIREN fallback is not used
        Assert.AreEqual('', VendorNo, 'An ambiguous SIRET must not select a Vendor.');
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
