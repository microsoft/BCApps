// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
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
        FRLegalIdentifiers: Codeunit "FR Legal Identifiers";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
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
        AssertExpectedDialogError('Specify a SIREN or a valid SIRET');
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
    procedure IdentifierFormatsValidateTheEntireInput()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Legal identifiers accept exact digit lengths, without trimming or truncating malformed input
        Initialize();

        // [GIVEN] Exact-length, short, long, and nonnumeric identifier values
        // [WHEN] The full values are validated
        // [THEN] Only correctly formatted identifiers are accepted
        VerifyIdentifierFormats();
    end;

    [Test]
    procedure CompanySIRENIsDerivedFromSIRETWithoutWriting()
    var
        CompanyInformation: Record "Company Information";
        SIREN: Text[9];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Company "C" can use a SIRET without storing a second copy of SIREN
        Initialize();

        // [GIVEN] Company "C" has only a SIRET
        CompanyInformation.Get();
        CompanyInformation."SIRET No." := '12345678901234';
        CompanyInformation.Modify();

        // [WHEN] The legal SIREN is resolved
        SIREN := FRLegalIdentifiers.GetCompanySIREN(CompanyInformation);

        // [THEN] The prefix is returned without modifying Company Information
        VerifyCompanyResolution(CompanyInformation, SIREN);
    end;

    [Test]
    procedure ConflictingCompanyIdentifiersAreRejected()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Company "C" cannot publish identifiers belonging to different legal units
        Initialize();

        // [GIVEN] Company "C" has contradictory SIREN and SIRET
        CompanyInformation.Get();
        CompanyInformation."Registration No." := '123456789';
        CompanyInformation."SIRET No." := '98765432100011';

        // [WHEN] The legal SIREN is resolved
        asserterror FRLegalIdentifiers.GetCompanySIREN(CompanyInformation);

        // [THEN] The conflict is reported
        AssertExpectedDialogError('The first nine digits of SIRET must match SIREN');
    end;

    [Test]
    procedure MalformedPopulatedSIRENDoesNotFallBackToSIRET()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A malformed explicit SIREN is not silently replaced by a SIRET prefix
        Initialize();

        // [GIVEN] Company "C" has a malformed SIREN and a valid SIRET
        CompanyInformation.Get();
        CompanyInformation."Registration No." := '123 456 789';
        CompanyInformation."SIRET No." := '12345678901234';

        // [WHEN] The legal SIREN is resolved
        asserterror FRLegalIdentifiers.GetCompanySIREN(CompanyInformation);

        // [THEN] The complete populated value is rejected
        AssertExpectedDialogError('SIREN must contain exactly nine digits');
    end;

    [Test]
    procedure CustomerUsesDedicatedSIRENWithUnrelatedRegistrationNumber()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Dedicated SIREN does not repurpose a generic registration field
        Initialize();

        // [GIVEN] Customer "C" has dedicated SIREN and an unrelated private registration
        CreateCustomer(Customer);
        Customer.Validate("Registration Number", 'PRIVATE-REGISTRATION');

        // [WHEN] The customer identity is resolved
        // [THEN] The dedicated SIREN is used
        Assert.AreEqual('123456789', FRLegalIdentifiers.GetCustomerSIREN(Customer, true), 'The dedicated SIREN must be authoritative.');
    end;

    [Test]
    procedure CustomerSIRETDerivesIdentityAndReceivingRoute()
    var
        Customer: Record Customer;
        Address: Text[250];
        Scheme: Enum "Electronic Address Scheme";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Customer "C" with only SIRET gets a coherent legal identity and a 0225 receiving route
        Initialize();

        // [GIVEN] Customer "C" has SIRET but no SIREN or explicit route
        CreateCustomer(Customer);
        Customer."SIREN No." := '';
        Customer."FR SIRET No." := '12345678901234';
        Customer.Modify();

        // [WHEN] The receiving route is resolved
        FRLegalIdentifiers.GetCustomerEndpoint(Customer, '', false, Address, Scheme);

        // [THEN] The route uses the derived SIREN without changing the customer
        VerifyCustomerDerivedRoute(Customer, Address, Scheme);
    end;

    [Test]
    procedure VendorLegacySIRETDerivesIdentityWithoutWriting()
    var
        Vendor: Record Vendor;
        SIREN: Text[9];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] French vendor "V" resolves SIREN from an existing registration SIRET without writing
        Initialize();

        // [GIVEN] French vendor "V" has only a fourteen-digit legacy registration
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Country/Region Code" := CreateCountry('FR');
        Vendor."SIREN No." := '';
        Vendor."Registration Number" := '12345678901234';
        Vendor.Modify();

        // [WHEN] The vendor identity is resolved
        SIREN := FRLegalIdentifiers.GetVendorSIREN(Vendor);

        // [THEN] The prefix is returned and the dedicated SIREN remains blank
        VerifyVendorResolution(Vendor, SIREN);
    end;

    [Test]
    procedure RecognizedLegacyConflictBlocksFrenchProcessing()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A recognized legacy identifier cannot silently contradict the canonical identity
        Initialize();

        // [GIVEN] French customer "C" has conflicting dedicated and legacy SIREN
        CreateCustomer(Customer);
        Customer."Registration Number" := '987654321';

        // [WHEN] The customer identity is resolved
        asserterror FRLegalIdentifiers.GetCustomerSIREN(Customer, true);

        // [THEN] The user is directed to review the conflicting fields
        AssertExpectedDialogError('legacy Registration Number');
    end;

    [Test]
    procedure ForeignRegistrationIsNotInterpretedAsFrenchIdentity()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Foreign customer "C" keeps its generic numeric registration without French reinterpretation
        Initialize();

        // [GIVEN] Foreign customer "C" has a nine-digit generic registration
        CreateCustomer(Customer);
        Customer."Country/Region Code" := CreateCountry('DE');
        Customer."SIREN No." := '';
        Customer."Registration Number" := '987654321';

        // [WHEN] An optional French identity is resolved
        // [THEN] No French SIREN is synthesized
        Assert.AreEqual('', FRLegalIdentifiers.GetCustomerSIREN(Customer, false), 'Foreign registrations must not be reinterpreted.');
    end;

    [Test]
    procedure MissingRequiredCustomerIdentityIsRejected()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] French domestic B2B customer "C" must have a legal identity
        Initialize();

        // [GIVEN] Customer "C" has neither SIREN nor SIRET
        CreateCustomer(Customer);
        Customer."SIREN No." := '';

        // [WHEN] A required identity is resolved
        asserterror FRLegalIdentifiers.GetCustomerSIREN(Customer, true);

        // [THEN] Missing setup is reported
        AssertExpectedDialogError('Specify a SIREN or a valid SIRET');
    end;

    [Test]
    procedure CustomerSIRETValidationRejectsConflictingPrefix()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Editing customer SIRET validates its relationship to dedicated SIREN
        Initialize();

        // [GIVEN] Customer "C" has SIREN 123456789
        CreateCustomer(Customer);

        // [WHEN] A SIRET belonging to another legal unit is entered
        asserterror Customer.Validate("FR SIRET No.", '98765432100011');

        // [THEN] The mismatch is rejected
        AssertExpectedDialogError('The first nine digits of SIRET must match SIREN');
    end;

    [Test]
    procedure VendorSIRENValidationRejectsMalformedValue()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Editing the existing vendor SIREN rejects nonnumeric values
        Initialize();

        // [GIVEN] Vendor "V"
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] A nonnumeric SIREN is entered
        asserterror Vendor.Validate("SIREN No.", '12345678X');

        // [THEN] The value is not accepted as a legal identifier
        AssertExpectedDialogError('SIREN must contain exactly nine digits');
    end;

    [Test]
    procedure VendorSIRENValidationChecksLegacySIRET()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The existing vendor SIREN cannot contradict an existing French registration SIRET
        Initialize();

        // [GIVEN] French vendor "V" has an existing registration SIRET
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Country/Region Code" := CreateCountry('FR');
        Vendor."Registration Number" := '12345678901234';

        // [WHEN] A SIREN belonging to another legal unit is entered
        asserterror Vendor.Validate("SIREN No.", '987654321');

        // [THEN] The mismatch is reported without introducing a new vendor field
        AssertExpectedDialogError('The first nine digits of SIRET must match SIREN');
    end;

    [Test]
    procedure CustomerSIRENValidationChecksExistingSIRET()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Editing dedicated SIREN also checks the existing establishment identifier
        Initialize();

        // [GIVEN] Customer "C" has a coherent pair
        CreateCustomer(Customer);
        Customer."FR SIRET No." := '12345678901234';

        // [WHEN] Another valid SIREN is entered
        asserterror Customer.Validate("SIREN No.", '732829320');

        // [THEN] The new SIREN cannot contradict SIRET
        AssertExpectedDialogError('The first nine digits of SIRET must match SIREN');
    end;

    [Test]
    procedure NewCustomersAndVendorsHaveBlankEndpointSchemes()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] New records do not inherit the legacy EM ordinal as an explicit scheme
        Initialize();

        // [GIVEN] New customer "C" and vendor "V"
        LibrarySales.CreateCustomer(Customer);
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Their default routing fields are inspected
        // [THEN] Both schemes are explicitly blank
        VerifyBlankSchemes(Customer, Vendor);
    end;

    [Test]
    procedure EmptyLegacyEMRouteUsesSIRENWithoutRewritingScheme()
    var
        Customer: Record Customer;
        Address: Text[250];
        Scheme: Enum "Electronic Address Scheme";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An empty legacy EM field is unconfigured, not a numeric email address
        Initialize();

        // [GIVEN] Customer "C" has legal SIREN and the old default EM with no address
        CreateCustomer(Customer);
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::EM;
        Customer.Modify();

        // [WHEN] The receiving route is resolved
        FRLegalIdentifiers.GetCustomerEndpoint(Customer, '', false, Address, Scheme);

        // [THEN] The synthesized route is 0225 while the stored scheme remains EM
        VerifyEndpoint(Address, Scheme, '123456789', Enum::"Electronic Address Scheme"::"0225");
        Customer.Get(Customer."No.");
        Assert.AreEqual(Customer."FR Elec. Address Scheme"::EM, Customer."FR Elec. Address Scheme", 'Resolution must not rewrite stored schemes.');
    end;

    [Test]
    procedure ReceivingEndpointRequires0225AndMatchingSIREN()
    var
        Customer: Record Customer;
        Address: Text[250];
        Scheme: Enum "Electronic Address Scheme";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Ordinary domestic B2B does not accept a SIRET as its buyer endpoint
        Initialize();

        // [GIVEN] Customer "C" has a valid SIRET endpoint
        CreateCustomer(Customer);
        Customer."FR Electronic Address" := '12345678901234';
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::"0009";

        // [WHEN] The ordinary receiving route is resolved
        asserterror FRLegalIdentifiers.GetCustomerEndpoint(Customer, '', false, Address, Scheme);

        // [THEN] Role-specific 0225 policy is enforced
        AssertExpectedDialogError('must use scheme 0225');
    end;

    [Test]
    procedure ReceivingEndpointRejectsAnotherPartysSIREN()
    var
        Customer: Record Customer;
        Address: Text[250];
        Scheme: Enum "Electronic Address Scheme";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A syntactically valid 0225 endpoint cannot route to another legal unit
        Initialize();

        // [GIVEN] Customer "C" has a route with a different SIREN
        CreateCustomer(Customer);
        Customer."FR Electronic Address" := '987654321_ACCOUNTS';
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::"0225";

        // [WHEN] The receiving route is resolved
        asserterror FRLegalIdentifiers.GetCustomerEndpoint(Customer, '', false, Address, Scheme);

        // [THEN] Routing and legal identity must agree
        AssertExpectedDialogError('begin with the receiving party');
    end;

    [Test]
    procedure SelfBillingPolicyInvertsTheReceivingRole()
    var
        Customer: Record Customer;
        CompanyInformation: Record "Company Information";
        Address: Text[250];
        Scheme: Enum "Electronic Address Scheme";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Self-billing policy applies 0225 to the receiving seller, without enabling a new document flow
        Initialize();

        // [GIVEN] Customer "C" has a SIRET endpoint and company "O" has SIREN
        CreateCustomer(Customer);
        Customer."FR Electronic Address" := '12345678901234';
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::"0009";
        CompanyInformation.Get();
        CompanyInformation."Registration No." := '987654321';

        // [WHEN] The nonreceiving buyer and receiving company routes are resolved
        FRLegalIdentifiers.GetCustomerEndpoint(Customer, '', true, Address, Scheme);
        VerifyEndpoint(Address, Scheme, '12345678901234', Scheme::"0009");
        FRLegalIdentifiers.GetCompanyEndpoint(CompanyInformation, '', true, Address, Scheme);

        // [THEN] The receiving company's route uses 0225
        VerifyEndpoint(Address, Scheme, '987654321', Scheme::"0225");
    end;

    [Test]
    procedure French0225FormatChecksLengthSuffixAndCharacters()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] French 0225 validation uses full 125-character limits and the published character restrictions
        Initialize();

        // [GIVEN] Addresses around the format boundaries
        // [WHEN] The complete addresses are checked
        // [THEN] Valid forms pass and invalid suffixes, characters, or lengths fail
        Verify0225Formats();
    end;

    [Test]
    procedure OtherEndpointSchemesRemainAvailableOutsideReceivingRole()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A foreign buyer can use supported schemes without leaking the domestic receiving rule
        Initialize();

        // [GIVEN] Foreign customer "C"
        CreateCustomer(Customer);
        Customer."Country/Region Code" := CreateCountry('DE');

        // [WHEN] Supported scheme-specific routes are resolved
        // [THEN] Values and schemes remain paired
        VerifyPermittedEndpoint(Customer, '123456789', Enum::"Electronic Address Scheme"::"0002");
        VerifyPermittedEndpoint(Customer, '12345678901234', Enum::"Electronic Address Scheme"::"0002");
        VerifyPermittedEndpoint(Customer, '12345678901234', Enum::"Electronic Address Scheme"::"0009");
        VerifyPermittedEndpoint(Customer, 'FRAB123456789', Enum::"Electronic Address Scheme"::"9957");
        VerifyPermittedEndpoint(Customer, 'billing@example.test', Enum::"Electronic Address Scheme"::EM);
    end;

    [Test]
    procedure SchemeSpecificValidationRejectsInvalidLegacyRoutes()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Numeric email addresses and SIREN suffixes with 0002 or 0009 are not silently reclassified
        Initialize();

        // [GIVEN] Customer "C" and malformed scheme/value pairs
        CreateCustomer(Customer);

        // [WHEN] Each explicit route is validated outside the receiving-role restriction
        // [THEN] Its own scheme still requires a valid format
        VerifyInvalidEndpoint(Customer, '123456789_ABC', Enum::"Electronic Address Scheme"::"0009");
        VerifyInvalidEndpoint(Customer, '123456789_ABC', Enum::"Electronic Address Scheme"::"0002");
        VerifyInvalidEndpoint(Customer, '123456789', Enum::"Electronic Address Scheme"::EM);
        VerifyInvalidEndpoint(Customer, 'FR!A123456789', Enum::"Electronic Address Scheme"::"9957");
    end;

    [Test]
    procedure SelectedServiceParticipantOverridesCardRouting()
    var
        Customer: Record Customer;
        ServiceCode: Code[20];
        Address: Text[250];
        Scheme: Enum "Electronic Address Scheme";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The selected service's valid participant takes precedence over a lower-priority card route
        Initialize();

        // [GIVEN] Customer "C" has an invalid card route and a valid service participant
        CreateCustomer(Customer);
        Customer."FR Electronic Address" := 'INVALID';
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::EM;
        ServiceCode := CreateParticipant(Customer, '123456789_PLATFORM', Enum::"Electronic Address Scheme"::"0225");

        // [WHEN] The selected service route is resolved
        FRLegalIdentifiers.GetCustomerEndpoint(Customer, ServiceCode, false, Address, Scheme);

        // [THEN] The service participant is used
        VerifyEndpoint(Address, Scheme, '123456789_PLATFORM', Scheme::"0225");
    end;

    [Test]
    procedure InvalidSelectedParticipantDoesNotFallBackToCard()
    var
        Customer: Record Customer;
        ServiceCode: Code[20];
        Address: Text[250];
        Scheme: Enum "Electronic Address Scheme";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An invalid higher-priority route is reported instead of silently bypassed
        Initialize();

        // [GIVEN] Customer "C" has a valid card route but a different participant SIREN
        CreateCustomer(Customer);
        Customer."FR Electronic Address" := '123456789_CARD';
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::"0225";
        ServiceCode := CreateParticipant(Customer, '987654321_PLATFORM', Enum::"Electronic Address Scheme"::"0225");

        // [WHEN] The selected service route is resolved
        asserterror FRLegalIdentifiers.GetCustomerEndpoint(Customer, ServiceCode, false, Address, Scheme);

        // [THEN] The participant error is not hidden by fallback
        AssertExpectedDialogError('begin with the receiving party');
    end;

    [Test]
    procedure CustomerSIRETIsEditableOnTheCard()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Customer "C" exposes its establishment identifier next to dedicated SIREN
        Initialize();

        // [GIVEN] Customer "C" is open on its card
        CreateCustomer(Customer);
        CustomerCard.OpenEdit();
        CustomerCard.GoToRecord(Customer);

        // [WHEN] SIRET is entered through the page
        CustomerCard."FR SIRET No.".SetValue('12345678901234');
        CustomerCard.Close();

        // [THEN] The dedicated SIRET is stored
        Customer.Get(Customer."No.");
        Assert.AreEqual('12345678901234', Customer."FR SIRET No.", 'The customer card must expose the new field.');
    end;

    [Test]
    procedure VendorExistingSIRENIsEditableOnTheCard()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Vendor "V" retains the existing SIREN control without a new SIRET field
        Initialize();

        // [GIVEN] Vendor "V" is open on its card
        LibraryPurchase.CreateVendor(Vendor);
        VendorCard.OpenEdit();
        VendorCard.GoToRecord(Vendor);

        // [WHEN] SIREN is entered through the existing page control
        VendorCard."SIREN No.".SetValue('123456789');
        VendorCard.Close();

        // [THEN] The existing dedicated SIREN is stored
        Vendor.Get(Vendor."No.");
        Assert.AreEqual('123456789', Vendor."SIREN No.", 'The vendor card must retain the existing SIREN field.');
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Identification Tests");
        LibrarySetupStorage.Restore();
        if not IsInitialized then begin
            LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Identification Tests");
            LibrarySetupStorage.SaveCompanyInformation();
            IsInitialized := true;
            LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Identification Tests");
        end;
        CompanyInformation.Get();
        CompanyInformation."Registration No." := '';
        CompanyInformation."SIRET No." := '';
        CompanyInformation."Country/Region Code" := CreateCountry('FR');
        CompanyInformation.Modify();
    end;

    local procedure CreateCountry(ISOCode: Code[2]): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion."ISO Code" := ISOCode;
        CountryRegion.Modify();
        exit(CountryRegion.Code);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibrarySales.CreateCustomer(Customer);
        Customer."Country/Region Code" := CompanyInformation."Country/Region Code";
        Customer."SIREN No." := '123456789';
        Customer."FR SIRET No." := '';
        Customer."Registration Number" := '';
        Customer."FR Electronic Address" := '';
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::" ";
        Customer."FR E-Reporting Trans. Type" := Customer."FR E-Reporting Trans. Type"::" ";
        Customer.Modify();
    end;

    local procedure CreateParticipant(Customer: Record Customer; Address: Text[200]; Scheme: Enum "Electronic Address Scheme"): Code[20]
    var
        EDocumentService: Record "E-Document Service";
        ServiceParticipant: Record "Service Participant";
    begin
        EDocumentService.Code := CopyStr(Format(CreateGuid()), 1, MaxStrLen(EDocumentService.Code));
        EDocumentService."Document Format" := EDocumentService."Document Format"::"Peppol BIS 3.0 FR";
        EDocumentService.Insert();
        ServiceParticipant.Service := EDocumentService.Code;
        ServiceParticipant."Participant Type" := ServiceParticipant."Participant Type"::Customer;
        ServiceParticipant.Participant := Customer."No.";
        ServiceParticipant."Participant Identifier" := Address;
        ServiceParticipant."FR Identifier Scheme" := Scheme;
        ServiceParticipant.Insert();
        exit(EDocumentService.Code);
    end;

    local procedure VerifyIdentifierFormats()
    begin
        Assert.IsTrue(FRLegalIdentifiers.IsSIRENFormatValid('123456789'), 'Nine digits must be accepted.');
        Assert.IsFalse(FRLegalIdentifiers.IsSIRENFormatValid('12345678'), 'Short SIREN must be rejected.');
        Assert.IsFalse(FRLegalIdentifiers.IsSIRENFormatValid('1234567890'), 'Long SIREN must not be truncated.');
        Assert.IsFalse(FRLegalIdentifiers.IsSIRENFormatValid('12345678A'), 'Nonnumeric SIREN must be rejected.');
        Assert.IsFalse(FRLegalIdentifiers.IsSIRENFormatValid(' 123456789'), 'Whitespace must not be stripped.');
        Assert.IsTrue(FRLegalIdentifiers.IsSIRETFormatValid('12345678901234'), 'Fourteen digits must be accepted.');
        Assert.IsFalse(FRLegalIdentifiers.IsSIRETFormatValid('1234567890123'), 'Short SIRET must be rejected.');
        Assert.IsFalse(FRLegalIdentifiers.IsSIRETFormatValid('123456789012345'), 'Long SIRET must not be truncated.');
        Assert.IsFalse(FRLegalIdentifiers.IsSIRETFormatValid('1234567890123A'), 'Nonnumeric SIRET must be rejected.');
    end;

    local procedure Verify0225Formats()
    begin
        Assert.IsTrue(FRLegalIdentifiers.Is0225FormatValid('123456789'), 'A bare SIREN is permitted.');
        Assert.IsTrue(FRLegalIdentifiers.Is0225FormatValid('123456789_Az09-._'), 'Published suffix characters must be accepted.');
        Assert.IsTrue(FRLegalIdentifiers.Is0225FormatValid(PadStr('123456789_', 125, 'A')), '125 characters must be accepted.');
        Assert.IsFalse(FRLegalIdentifiers.Is0225FormatValid(PadStr('123456789_', 126, 'A')), '126 characters must be rejected.');
        Assert.IsFalse(FRLegalIdentifiers.Is0225FormatValid('123456789_'), 'The suffix must not be empty.');
        Assert.IsFalse(FRLegalIdentifiers.Is0225FormatValid('123456789_A B'), 'Spaces must be rejected.');
        Assert.IsFalse(FRLegalIdentifiers.Is0225FormatValid('123456789_A/B'), 'Slashes must be rejected.');
        Assert.IsFalse(FRLegalIdentifiers.Is0225FormatValid('123456789_A+B'), 'The published BR23 character set does not include plus.');
    end;

    local procedure VerifyCompanyResolution(var CompanyInformation: Record "Company Information"; SIREN: Text)
    begin
        Assert.AreEqual('123456789', SIREN, 'SIREN must be derived from the full valid SIRET.');
        CompanyInformation.Get();
        Assert.AreEqual('', CompanyInformation."Registration No.", 'Resolution must not write master data.');
    end;

    local procedure VerifyVendorResolution(var Vendor: Record Vendor; SIREN: Text)
    begin
        Assert.AreEqual('123456789', SIREN, 'SIREN must be derived from SIRET.');
        Vendor.Get(Vendor."No.");
        Assert.AreEqual('', Vendor."SIREN No.", 'Resolution must not write master data.');
        Assert.AreEqual('12345678901234', Vendor."Registration Number", 'The existing registration SIRET must remain unchanged.');
    end;

    local procedure VerifyCustomerDerivedRoute(var Customer: Record Customer; Address: Text; Scheme: Enum "Electronic Address Scheme")
    begin
        VerifyEndpoint(Address, Scheme, '123456789', Scheme::"0225");
        Customer.Get(Customer."No.");
        Assert.AreEqual('', Customer."SIREN No.", 'Resolution must not write master data.');
    end;

    local procedure VerifyBlankSchemes(Customer: Record Customer; Vendor: Record Vendor)
    begin
        Assert.AreEqual(Customer."FR Elec. Address Scheme"::" ", Customer."FR Elec. Address Scheme", 'New customer scheme must be blank.');
        Assert.AreEqual(Vendor."FR Elec. Address Scheme"::" ", Vendor."FR Elec. Address Scheme", 'New vendor scheme must be blank.');
    end;

    local procedure VerifyPermittedEndpoint(Customer: Record Customer; ExpectedAddress: Text[250]; ExpectedScheme: Enum "Electronic Address Scheme")
    var
        Address: Text[250];
        Scheme: Enum "Electronic Address Scheme";
    begin
        Customer."FR Electronic Address" := ExpectedAddress;
        Customer."FR Elec. Address Scheme" := ExpectedScheme;
        FRLegalIdentifiers.GetCustomerEndpoint(Customer, '', false, Address, Scheme);
        VerifyEndpoint(Address, Scheme, ExpectedAddress, ExpectedScheme);
    end;

    local procedure VerifyEndpoint(Address: Text; Scheme: Enum "Electronic Address Scheme"; ExpectedAddress: Text; ExpectedScheme: Enum "Electronic Address Scheme")
    begin
        Assert.AreEqual(ExpectedAddress, Address, 'The resolved endpoint value is incorrect.');
        Assert.AreEqual(ExpectedScheme, Scheme, 'The resolved endpoint scheme is incorrect.');
    end;

    local procedure VerifyInvalidEndpoint(Customer: Record Customer; Address: Text; Scheme: Enum "Electronic Address Scheme")
    begin
        asserterror FRLegalIdentifiers.ValidateEndpoint(Address, Scheme, false, Customer."SIREN No.", Customer);
        AssertExpectedDialogError('valid scheme-specific format');
    end;

    local procedure AssertExpectedDialogError(ExpectedErrorText: Text)
    begin
        Assert.ExpectedError(ExpectedErrorText);
        Assert.ExpectedErrorCode(DialogErrorCodeTok);
    end;
}
