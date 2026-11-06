// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 148152 "FR Identifier Migration Tests"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        FRIdentifierMigration: Codeunit "FR Identifier Migration";
        IsInitialized: Boolean;
        ObservedCustomerNo: Code[20];
        CustomerModifyCount: Integer;

    [Test]
    procedure CustomerLegacySIRENIsCopiedWithoutClearingSource()
    var
        Customer: Record Customer;
        Issue: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Customer "C" migrates a valid legacy SIREN into its dedicated field
        Initialize();

        // [GIVEN] Customer "C" has only a nine-digit legacy registration
        CreateCustomer(Customer, '123456789');

        // [WHEN] Identifiers are migrated
        Issue := FRIdentifierMigration.MigrateCustomer(Customer);

        // [THEN] SIREN is populated and the source is preserved
        VerifyCustomerMigration(Customer, Issue, '123456789', '', '123456789');
    end;

    [Test]
    procedure CustomerLegacySIRETPopulatesBothDedicatedIdentifiers()
    var
        Customer: Record Customer;
        Issue: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Customer "C" migrates the complete fourteen-digit legacy establishment identifier
        Initialize();

        // [GIVEN] Customer "C" has only a legacy SIRET
        CreateCustomer(Customer, '12345678901234');

        // [WHEN] Identifiers are migrated
        Issue := FRIdentifierMigration.MigrateCustomer(Customer);

        // [THEN] Both dedicated identifiers are populated coherently
        VerifyCustomerMigration(Customer, Issue, '123456789', '12345678901234', '12345678901234');
    end;

    [Test]
    procedure VendorLegacySIRETPopulatesExistingSIREN()
    var
        Vendor: Record Vendor;
        Issue: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Vendor "V" fills only the existing SIREN field from a legacy SIRET
        Initialize();

        // [GIVEN] Vendor "V" has only a legacy SIRET
        CreateVendor(Vendor, '12345678901234');

        // [WHEN] Identifiers are migrated
        Issue := FRIdentifierMigration.MigrateVendor(Vendor);

        // [THEN] The existing SIREN is populated and the registration field is preserved
        VerifyVendorMigration(Vendor, Issue, '123456789', '12345678901234');
    end;

    [Test]
    procedure CanonicalSIRETBackfillsPrintedReportSIREN()
    var
        Customer: Record Customer;
        Issue: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Customer "C" exposes a canonical SIRET prefix in the existing SIREN field used by reports
        Initialize();

        // [GIVEN] Customer "C" has only a canonical SIRET
        CreateCustomer(Customer, '');
        Customer."FR SIRET No." := '12345678901234';
        Customer.Modify();

        // [WHEN] Identifiers are migrated
        Issue := FRIdentifierMigration.MigrateCustomer(Customer);

        // [THEN] The existing SIREN field is populated without a new report-specific identity
        VerifyCustomerMigration(Customer, Issue, '123456789', '12345678901234', '');
    end;

    [Test]
    procedure ExistingSIRENIsPreservedWhenLegacySIRETAgrees()
    var
        Customer: Record Customer;
        Issue: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An agreeing legacy SIRET fills only the missing establishment identifier
        Initialize();

        // [GIVEN] Customer "C" has a canonical SIREN and an agreeing legacy SIRET
        CreateCustomer(Customer, '12345678901234');
        Customer."SIREN No." := '123456789';
        Customer.Modify();

        // [WHEN] Identifiers are migrated
        Issue := FRIdentifierMigration.MigrateCustomer(Customer);

        // [THEN] The existing identity is retained
        VerifyCustomerMigration(Customer, Issue, '123456789', '12345678901234', '12345678901234');
    end;

    [Test]
    procedure ConflictingSourcesDoNotPartiallyMigrateCustomer()
    var
        Customer: Record Customer;
        Issue: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Conflicting legal units do not produce a partially populated customer
        Initialize();

        // [GIVEN] Customer "C" has contradictory legacy and qualified routing SIRETs
        CreateCustomer(Customer, '12345678901234');
        Customer."FR Electronic Address" := '98765432100011';
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::"0009";
        Customer.Modify();

        // [WHEN] Identifiers are migrated
        Issue := FRIdentifierMigration.MigrateCustomer(Customer);

        // [THEN] Neither target is populated and all sources remain unchanged
        VerifyCustomerConflict(Customer, Issue, '', '', '12345678901234', '98765432100011');
    end;

    [Test]
    procedure DifferentEstablishmentsWithSameSIRENAreNotMerged()
    var
        Customer: Record Customer;
        Issue: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Two SIRETs sharing SIREN still identify different establishments
        Initialize();

        // [GIVEN] Customer "C" has two different SIRETs with the same SIREN
        CreateCustomer(Customer, '12345678901234');
        Customer."FR Electronic Address" := '12345678900011';
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::"0009";
        Customer.Modify();

        // [WHEN] Identifiers are migrated
        Issue := FRIdentifierMigration.MigrateCustomer(Customer);

        // [THEN] No arbitrary establishment wins
        VerifyCustomerConflict(Customer, Issue, '', '', '12345678901234', '12345678900011');
    end;

    [Test]
    procedure MalformedCanonicalSIRENIsNeverOverwritten()
    var
        Customer: Record Customer;
        Issue: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A malformed populated canonical identifier requires correction rather than overwrite
        Initialize();

        // [GIVEN] Customer "C" has malformed SIREN and a valid legacy SIRET
        CreateCustomer(Customer, '12345678901234');
        Customer."SIREN No." := 'INVALID';
        Customer.Modify();

        // [WHEN] Identifiers are migrated
        Issue := FRIdentifierMigration.MigrateCustomer(Customer);

        // [THEN] The malformed canonical value and blank SIRET are preserved
        VerifyCustomerConflict(Customer, Issue, 'INVALID', '', '12345678901234', '');
    end;

    [Test]
    procedure SuffixWith0009IsNotMigratedAsSIRET()
    var
        Customer: Record Customer;
        Issue: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A SIREN suffix incorrectly qualified as SIRET cannot become a legal identifier
        Initialize();

        // [GIVEN] Customer "C" has a malformed 0009 route
        CreateCustomer(Customer, '123456789');
        Customer."FR Electronic Address" := '123456789_001';
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::"0009";
        Customer.Modify();

        // [WHEN] Identifiers are migrated
        Issue := FRIdentifierMigration.MigrateCustomer(Customer);

        // [THEN] The record is not partially migrated
        VerifyCustomerConflict(Customer, Issue, '', '', '123456789', '123456789_001');
    end;

    [Test]
    procedure QualifiedSIRETMigratesButInvalidReceivingRouteIsReported()
    var
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A retained 0009 route can supply legal identity without becoming a compliant B2B buyer endpoint
        Initialize();

        // [GIVEN] Customer "C" has only a qualified SIRET route
        CreateCustomer(Customer, '');
        Customer."FR Electronic Address" := '12345678901234';
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::"0009";
        Customer.Modify();

        // [WHEN] Migration and readiness are run
        FRIdentifierMigration.PrepareCustomer(Customer, TempErrorMessage, '');

        // [THEN] Legal fields are filled, the route is preserved, and remediation is reported
        VerifyCustomerMigration(Customer, '', '123456789', '12345678901234', '');
        VerifyRetainedRouting(Customer, '12345678901234', Customer."FR Elec. Address Scheme"::"0009");
        VerifyReadinessIssue(TempErrorMessage, Customer.RecordId, '0225');
    end;

    [Test]
    procedure TrulyBlankSchemeCanBeSetTo0225WithoutChangingAddress()
    var
        Customer: Record Customer;
        Address: Text[250];
        Issue: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An independently identified customer may qualify a complete valid blank-scheme route
        Initialize();

        // [GIVEN] Customer "C" has an independent legacy SIREN and a valid 125-character address
        CreateCustomer(Customer, '123456789');
        Address := PadStr('123456789_Ab-._', 125, 'x');
        Customer."FR Electronic Address" := Address;
        Customer.Modify();

        // [WHEN] Identifiers are migrated
        Issue := FRIdentifierMigration.MigrateCustomer(Customer);

        // [THEN] The address bytes are unchanged and the blank scheme becomes 0225
        VerifyCustomerMigration(Customer, Issue, '123456789', '', '123456789');
        VerifyRetainedRouting(Customer, Address, Customer."FR Elec. Address Scheme"::"0225");
    end;

    [Test]
    procedure BlankSchemeWithDifferentPrefixIsNotQualified()
    var
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A blank scheme is not filled when the address prefix disagrees with legal identity
        Initialize();

        // [GIVEN] Customer "C" has an independent SIREN and a different routing prefix
        CreateCustomer(Customer, '123456789');
        Customer."FR Electronic Address" := '987654321_OTHER';
        Customer.Modify();

        // [WHEN] Migration and readiness are run
        FRIdentifierMigration.PrepareCustomer(Customer, TempErrorMessage, '');

        // [THEN] The route remains unqualified and requires correction
        Customer.Get(Customer."No.");
        VerifyRetainedRouting(Customer, '987654321_OTHER', Customer."FR Elec. Address Scheme"::" ");
        VerifyReadinessIssue(TempErrorMessage, Customer.RecordId, 'scheme');
    end;

    [Test]
    procedure PopulatedEMAnd0002SchemesAreNotReinterpreted()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Numeric-looking explicit routes retain their existing schemes
        Initialize();

        // [GIVEN] Customers with legacy EM and 0002 routes
        // [WHEN] Legal identifiers are migrated
        // [THEN] Stored schemes are not reclassified as 0225
        VerifyExistingSchemePreserved(Enum::"Electronic Address Scheme"::EM);
        VerifyExistingSchemePreserved(Enum::"Electronic Address Scheme"::"0002");
    end;

    [Test]
    procedure RoutingOnlyCandidateRequiresConfirmation()
    var
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A routing prefix alone is shown for confirmation instead of becoming a canonical SIREN
        Initialize();

        // [GIVEN] Customer "C" has only a 0225 routing address
        CreateCustomer(Customer, '');
        Customer."FR Electronic Address" := '123456789_ROUTE';
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::"0225";
        Customer.Modify();

        // [WHEN] Migration and readiness are run
        FRIdentifierMigration.PrepareCustomer(Customer, TempErrorMessage, '');

        // [THEN] Identity stays blank and the unconfirmed candidate is visible in diagnostics
        VerifyCustomerMigration(Customer, '', '', '', '');
        VerifyUnconfirmedCandidate(TempErrorMessage, '123456789');
    end;

    [Test]
    procedure VATOnlyCandidateRequiresConfirmation()
    var
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A VAT suffix alone does not become canonical legal identity
        Initialize();

        // [GIVEN] Customer "C" has only a French VAT registration
        CreateCustomer(Customer, '');
        Customer."VAT Registration No." := 'FRAB123456789';
        Customer.Modify();

        // [WHEN] Migration and readiness are run
        FRIdentifierMigration.PrepareCustomer(Customer, TempErrorMessage, '');

        // [THEN] Identity stays blank and the possible SIREN requires confirmation
        VerifyCustomerMigration(Customer, '', '', '', '');
        VerifyUnconfirmedCandidate(TempErrorMessage, '123456789');
    end;

    [Test]
    procedure ForeignLegacyRegistrationIsPreservedWithoutMigration()
    var
        Customer: Record Customer;
        Issue: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Foreign registrations are not interpreted as SIREN or SIRET
        Initialize();

        // [GIVEN] Foreign customer "C" has a fourteen-digit registration
        CreateCustomer(Customer, '12345678901234');
        Customer."Country/Region Code" := CreateCountry('DE');
        Customer.Modify();

        // [WHEN] French migration is run
        Issue := FRIdentifierMigration.MigrateCustomer(Customer);

        // [THEN] No French fields are populated
        VerifyCustomerMigration(Customer, Issue, '', '', '12345678901234');
    end;

    [Test]
    procedure CompletedMigrationDoesNotWriteAgain()
    var
        Customer: Record Customer;
        MigrationObserver: Codeunit "FR Identifier Migration Tests";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Re-running migration is idempotent, including database writes
        Initialize();

        // [GIVEN] Customer "C" has a legacy SIRET and its writes are observed
        CreateCustomer(Customer, '12345678901234');
        MigrationObserver.ObserveCustomer(Customer."No.");
        BindSubscription(MigrationObserver);

        // [WHEN] Migration is run twice
        FRIdentifierMigration.MigrateCustomer(Customer);
        FRIdentifierMigration.MigrateCustomer(Customer);

        // [THEN] Only the first run writes the customer
        Assert.AreEqual(1, MigrationObserver.GetCustomerModifyCount(), 'Completed records must not be modified again.');
        UnbindSubscription(MigrationObserver);
    end;

    [Test]
    procedure CustomerMigrationDoesNotChangeLinkedContact()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        Issue: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Customer identity migration does not propagate changes to Contact fields
        Initialize();

        // [GIVEN] Customer "C" has a linked contact "K" with distinct existing identifiers
        CreateCustomer(Customer, '12345678901234');
        CreateLinkedContact(Contact, Customer."No.", Enum::"Contact Business Relation Link To Table"::Customer);

        // [WHEN] Customer identifiers are migrated
        Issue := FRIdentifierMigration.MigrateCustomer(Customer);

        // [THEN] Customer fields are populated but the contact remains unchanged
        VerifyCustomerMigration(Customer, Issue, '123456789', '12345678901234', '12345678901234');
        VerifyContactUnchanged(Contact);
    end;

    [Test]
    procedure VendorMigrationDoesNotChangeLinkedContact()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        Issue: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Vendor identity migration does not propagate changes to Contact fields
        Initialize();

        // [GIVEN] Vendor "V" has a linked contact "K" with distinct existing identifiers
        CreateVendor(Vendor, '12345678901234');
        CreateLinkedContact(Contact, Vendor."No.", Enum::"Contact Business Relation Link To Table"::Vendor);

        // [WHEN] Vendor identifiers are migrated
        Issue := FRIdentifierMigration.MigrateVendor(Vendor);

        // [THEN] Vendor SIREN is populated but the registration and contact remain unchanged
        VerifyVendorMigration(Vendor, Issue, '123456789', '12345678901234');
        VerifyContactUnchanged(Contact);
    end;

    [Test]
    procedure CompanyConflictsAreReportedWithoutRewritingValues()
    var
        CompanyInformation: Record "Company Information";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Company conflicts are readiness issues rather than destructive technical-upgrade failures
        Initialize();

        // [GIVEN] Company "C" has contradictory SIREN and SIRET
        CompanyInformation.Get();
        CompanyInformation."SIRET No." := '98765432100011';
        CompanyInformation.Modify();

        // [WHEN] Company readiness is prepared
        FRIdentifierMigration.PrepareCompany(TempErrorMessage, '');

        // [THEN] The conflict is navigable and both original values remain
        VerifyReadinessIssue(TempErrorMessage, CompanyInformation.RecordId, 'match SIREN');
        VerifyCompanyUnchanged(CompanyInformation);
    end;

    [Test]
    procedure RerunAfterCorrectionCompletesPreviouslyConflictingRecord()
    var
        Customer: Record Customer;
        Issue: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Readiness can be rerun after the user corrects conflicting source data
        Initialize();

        // [GIVEN] Customer "C" initially has conflicting SIREN and legacy SIRET
        CreateCustomer(Customer, '98765432100011');
        Customer."SIREN No." := '123456789';
        Customer.Modify();
        FRIdentifierMigration.MigrateCustomer(Customer);
        Customer."Registration Number" := '12345678901234';
        Customer.Modify();

        // [WHEN] Migration is rerun after correction
        Issue := FRIdentifierMigration.MigrateCustomer(Customer);

        // [THEN] The missing SIRET can now be filled
        VerifyCustomerMigration(Customer, Issue, '123456789', '12345678901234', '12345678901234');
    end;

    [Test]
    procedure EmptyLegacyEMSchemeRemainsStoredDuringPreparation()
    var
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Migration does not rewrite an old default EM when no explicit address exists
        Initialize();

        // [GIVEN] Customer "C" has legacy SIREN and an empty EM route
        CreateCustomer(Customer, '123456789');
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::EM;
        Customer.Modify();

        // [WHEN] Migration and readiness are run
        FRIdentifierMigration.PrepareCustomer(Customer, TempErrorMessage, '');

        // [THEN] The record is ready without a stored-scheme rewrite
        VerifyCustomerMigration(Customer, '', '123456789', '', '123456789');
        VerifyRetainedRouting(Customer, '', Customer."FR Elec. Address Scheme"::EM);
        Assert.IsTrue(TempErrorMessage.IsEmpty(), 'An empty legacy default is not an explicit invalid route.');
    end;

    [Test]
    [HandlerFunctions('ReadinessMessageHandler')]
    procedure CustomerCardCanRerunPreparation()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Customer "C" exposes the rerunnable migration action on its existing card
        Initialize();

        // [GIVEN] Customer "C" has a legacy SIREN
        CreateCustomer(Customer, '123456789');
        CustomerCard.OpenEdit();
        CustomerCard.GoToRecord(Customer);

        // [WHEN] Preparation is invoked on the card
        CustomerCard.PrepareFrenchIdentifiers.Invoke();
        CustomerCard.Close();

        // [THEN] The identifier is migrated and readiness is reported
        VerifyCustomerMigration(Customer, '', '123456789', '', '123456789');
        Assert.IsTrue(StrPos(LibraryVariableStorage.DequeueText(), 'Preparation completed') > 0, 'Readiness must be shown to the user.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ReadinessErrorPageHandler')]
    procedure VendorCardShowsConflictsWithoutOverwriting()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Vendor "V" exposes actionable conflict diagnostics on the existing card
        Initialize();

        // [GIVEN] Vendor "V" has contradictory canonical and legacy SIREN
        CreateVendor(Vendor, '987654321');
        Vendor."SIREN No." := '123456789';
        Vendor.Modify();
        VendorCard.OpenEdit();
        VendorCard.GoToRecord(Vendor);

        // [WHEN] Preparation is invoked on the card
        VendorCard.PrepareFrenchIdentifiers.Invoke();
        VendorCard.Close();

        // [THEN] A conflict is shown and the canonical field is preserved
        VerifyVendorMigration(Vendor, '', '123456789', '987654321');
        Assert.IsTrue(StrPos(LibraryVariableStorage.DequeueText(), 'disagree') > 0, 'The conflict must be shown to the user.');
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"FR Identifier Migration Tests");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if not IsInitialized then begin
            LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"FR Identifier Migration Tests");
            LibrarySetupStorage.SaveCompanyInformation();
            IsInitialized := true;
            LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"FR Identifier Migration Tests");
        end;
        CompanyInformation.Get();
        CompanyInformation."Registration No." := '123456789';
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

    local procedure CreateCustomer(var Customer: Record Customer; RegistrationNumber: Text[50])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibrarySales.CreateCustomer(Customer);
        Customer."Country/Region Code" := CompanyInformation."Country/Region Code";
        Customer."Registration Number" := RegistrationNumber;
        Customer."SIREN No." := '';
        Customer."FR SIRET No." := '';
        Customer."FR Electronic Address" := '';
        Customer."VAT Registration No." := '';
        Customer."FR Elec. Address Scheme" := Customer."FR Elec. Address Scheme"::" ";
        Customer."FR E-Reporting Trans. Type" := Customer."FR E-Reporting Trans. Type"::" ";
        Customer.Modify();
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; RegistrationNumber: Text[50])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor."Registration Number" := RegistrationNumber;
        Vendor."SIREN No." := '';
        Vendor."FR Electronic Address" := '';
        Vendor."FR Elec. Address Scheme" := Vendor."FR Elec. Address Scheme"::" ";
        Vendor.Modify();
    end;

    local procedure CreateLinkedContact(var Contact: Record Contact; PartnerNo: Code[20]; LinkToTable: Enum "Contact Business Relation Link To Table")
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        ContactBusinessRelation.SetRange("No.", PartnerNo);
        if ContactBusinessRelation.FindFirst() then
            Contact.Get(ContactBusinessRelation."Contact No.")
        else begin
            LibraryMarketing.CreateCompanyContact(Contact);
            ContactBusinessRelation.CreateRelation(Contact."No.", PartnerNo, LinkToTable);
        end;
        Contact."SIREN No." := '987654321';
        Contact."Registration Number" := 'CONTACT-UNCHANGED';
        Contact.Modify(false);
    end;

    local procedure VerifyCustomerMigration(var Customer: Record Customer; Issue: Text; SIREN: Text; SIRET: Text; RegistrationNumber: Text)
    begin
        Assert.AreEqual('', Issue, 'An agreeing record must not have a migration conflict.');
        Customer.Get(Customer."No.");
        Assert.AreEqual(SIREN, Customer."SIREN No.", 'Unexpected dedicated SIREN.');
        Assert.AreEqual(SIRET, Customer."FR SIRET No.", 'Unexpected dedicated SIRET.');
        Assert.AreEqual(RegistrationNumber, Customer."Registration Number", 'The legacy source must be preserved.');
    end;

    local procedure VerifyVendorMigration(var Vendor: Record Vendor; Issue: Text; SIREN: Text; RegistrationNumber: Text)
    begin
        Assert.AreEqual('', Issue, 'An agreeing record must not have a migration conflict.');
        Vendor.Get(Vendor."No.");
        Assert.AreEqual(SIREN, Vendor."SIREN No.", 'Unexpected dedicated SIREN.');
        Assert.AreEqual(RegistrationNumber, Vendor."Registration Number", 'The legacy source must be preserved.');
    end;

    local procedure VerifyCustomerConflict(var Customer: Record Customer; Issue: Text; SIREN: Text; SIRET: Text; RegistrationNumber: Text; Address: Text)
    begin
        Assert.AreNotEqual('', Issue, 'Conflicting or malformed candidates must be reported.');
        Customer.Get(Customer."No.");
        Assert.AreEqual(SIREN, Customer."SIREN No.", 'SIREN must not be partially migrated.');
        Assert.AreEqual(SIRET, Customer."FR SIRET No.", 'SIRET must not be partially migrated.');
        Assert.AreEqual(RegistrationNumber, Customer."Registration Number", 'The legacy source must be preserved.');
        Assert.AreEqual(Address, Customer."FR Electronic Address", 'Routing source values must be preserved.');
    end;

    local procedure VerifyRetainedRouting(Customer: Record Customer; Address: Text; Scheme: Enum "Electronic Address Scheme")
    begin
        Assert.AreEqual(Address, Customer."FR Electronic Address", 'The original address bytes must be preserved.');
        Assert.AreEqual(Scheme, Customer."FR Elec. Address Scheme", 'The stored scheme must not be reinterpreted.');
    end;

    local procedure VerifyReadinessIssue(var TempErrorMessage: Record "Error Message" temporary; OwnerId: RecordId; ExpectedText: Text)
    begin
        TempErrorMessage.SetRange("Record ID", OwnerId);
        TempErrorMessage.SetRange("Message Type", TempErrorMessage."Message Type"::Error);
        Assert.IsTrue(TempErrorMessage.FindFirst(), 'A navigable readiness error must be recorded.');
        Assert.IsTrue(StrPos(TempErrorMessage.Message, ExpectedText) > 0, 'The diagnostic must explain the required correction.');
        TempErrorMessage.Reset();
    end;

    local procedure VerifyUnconfirmedCandidate(var TempErrorMessage: Record "Error Message" temporary; SIREN: Text)
    begin
        TempErrorMessage.SetRange("Message Type", TempErrorMessage."Message Type"::Information);
        TempErrorMessage.SetFilter(Message, '*%1*', 'Possible SIREN ' + SIREN);
        Assert.IsFalse(TempErrorMessage.IsEmpty(), 'A possible SIREN must be shown for manual confirmation.');
        TempErrorMessage.Reset();
    end;

    local procedure VerifyExistingSchemePreserved(Scheme: Enum "Electronic Address Scheme")
    var
        Customer: Record Customer;
        Issue: Text;
    begin
        CreateCustomer(Customer, '123456789');
        Customer."FR Electronic Address" := '123456789_ROUTE';
        Customer."FR Elec. Address Scheme" := Scheme;
        Customer.Modify();
        Issue := FRIdentifierMigration.MigrateCustomer(Customer);
        VerifyCustomerMigration(Customer, Issue, '123456789', '', '123456789');
        VerifyRetainedRouting(Customer, '123456789_ROUTE', Scheme);
    end;

    local procedure VerifyContactUnchanged(var Contact: Record Contact)
    begin
        Contact.Get(Contact."No.");
        Assert.AreEqual('987654321', Contact."SIREN No.", 'Contact SIREN must not change during migration.');
        Assert.AreEqual('CONTACT-UNCHANGED', Contact."Registration Number", 'Contact generic registration must not change.');
    end;

    local procedure VerifyCompanyUnchanged(var CompanyInformation: Record "Company Information")
    begin
        CompanyInformation.Get();
        Assert.AreEqual('123456789', CompanyInformation."Registration No.", 'Company SIREN must not be rewritten.');
        Assert.AreEqual('98765432100011', CompanyInformation."SIRET No.", 'Company SIRET must not be rewritten.');
    end;

    procedure ObserveCustomer(CustomerNo: Code[20])
    begin
        ObservedCustomerNo := CustomerNo;
        CustomerModifyCount := 0;
    end;

    procedure GetCustomerModifyCount(): Integer
    begin
        exit(CustomerModifyCount);
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, OnAfterModifyEvent, '', false, false)]
    local procedure CountCustomerWrites(var Rec: Record Customer; var xRec: Record Customer; RunTrigger: Boolean)
    begin
        if Rec."No." = ObservedCustomerNo then
            CustomerModifyCount += 1;
    end;

    [MessageHandler]
    procedure ReadinessMessageHandler(MessageText: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(MessageText);
    end;

    [PageHandler]
    procedure ReadinessErrorPageHandler(var ErrorMessages: TestPage "Error Messages")
    begin
        LibraryVariableStorage.Enqueue(ErrorMessages.Description.Value());
        ErrorMessages.Close();
    end;
}
