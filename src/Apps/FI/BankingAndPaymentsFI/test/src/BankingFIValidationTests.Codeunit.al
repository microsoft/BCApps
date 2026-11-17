// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Customer;
using Microsoft.Purchases.Vendor;
using Microsoft.Foundation.Address;
using System.Environment.Configuration;

codeunit 148231 "Banking FI Validation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        LibraryBanking: Codeunit "Library - Banking FI";
        Assert: Codeunit Assert;
        BankValidationCount: Integer;

    [Test]
    procedure DueDateInitializesEmptyPlannedPaymentDate()
    var
        Journal: Record "Gen. Journal Line";
    begin
        EnableFeature();
        Journal.Validate("Due Date", WorkDate() + 10);
        Assert.AreEqual(Journal."Due Date", Journal."Planned Payment Date", 'An empty planned date must be initialized from the due date.');
        DisableFeature();
    end;

    [Test]
    procedure DueDatePreservesScheduledPaymentDate()
    var
        Journal: Record "Gen. Journal Line";
    begin
        EnableFeature();
        Journal."Planned Payment Date" := WorkDate() + 5;
        Journal.Validate("Due Date", WorkDate() + 10);
        Assert.AreEqual(WorkDate() + 5, Journal."Planned Payment Date", 'Changing the due date must not overwrite an intentional payment schedule.');
        DisableFeature();
    end;

    [Test]
    procedure BankCountryRevalidatesNumberOnce()
    var
        Bank: Record "Bank Account";
        Observer: Codeunit "Banking FI Validation Tests";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A country change validates a bank's domestic account exactly once after cutover.
        Initialize();

        // [GIVEN] Bank account "B" with a valid domestic account.
        BindSubscription(Observer);
        Bank."Bank Account No." := '159030-776';

        // [WHEN] The domestic country is validated.
        Bank.Validate("Country/Region Code", '');

        // [THEN] Only the replacement validation runs.
        Observer.AssertBankValidationCount(1);
        UnbindSubscription(Observer);
    end;

    [Test]
    procedure CustomerBankCountryRevalidatesNumberOnce()
    var
        Bank: Record "Customer Bank Account";
        Observer: Codeunit "Banking FI Validation Tests";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A customer bank country change validates its domestic account exactly once after cutover.
        Initialize();

        // [GIVEN] Customer bank account "B" with a valid domestic account.
        BindSubscription(Observer);
        Bank."Bank Account No." := '159030-776';

        // [WHEN] The domestic country is validated.
        Bank.Validate("Country/Region Code", '');

        // [THEN] Only the replacement validation runs.
        Observer.AssertBankValidationCount(1);
        UnbindSubscription(Observer);
    end;

    [Test]
    procedure VendorBankCountryRevalidatesNumberOnce()
    var
        Bank: Record "Vendor Bank Account";
        Observer: Codeunit "Banking FI Validation Tests";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A vendor bank country change validates its domestic account exactly once after cutover.
        Initialize();

        // [GIVEN] Vendor bank account "B" with a valid domestic account.
        BindSubscription(Observer);
        Bank."Bank Account No." := '159030-776';

        // [WHEN] The domestic country is validated.
        Bank.Validate("Country/Region Code", '');

        // [THEN] Only the replacement validation runs.
        Observer.AssertBankValidationCount(1);
        UnbindSubscription(Observer);
    end;

    [Test]
    procedure ExplicitFinnishCountryValidatesDomesticNumberOnce()
    var
        Bank: Record "Bank Account";
        Observer: Codeunit "Banking FI Validation Tests";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Explicit FI and a blank domestic country use the same single-validation path.
        Initialize();

        // [GIVEN] Bank account "B" with a valid domestic account.
        EnsureCountryExists('FI');
        Bank."Bank Account No." := '159030-776';
        BindSubscription(Observer);

        // [WHEN] The country is changed to FI.
        Bank.Validate("Country/Region Code", 'FI');

        // [THEN] The domestic validation executes once.
        Observer.AssertBankValidationCount(1);
        UnbindSubscription(Observer);
    end;

    [Test]
    procedure EmptyCustomerBankNumberRemainsValidAfterCountryChange()
    var
        Bank: Record "Customer Bank Account";
        Observer: Codeunit "Banking FI Validation Tests";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Changing the country must not require an account number that has not been entered.
        Initialize();

        // [GIVEN] Customer bank account "B" without a bank number.
        EnsureCountryExists('FI');
        BindSubscription(Observer);

        // [WHEN] The country is changed to FI.
        Bank.Validate("Country/Region Code", 'FI');

        // [THEN] The empty number remains valid and validation is not duplicated.
        Assert.AreEqual('', Bank."Bank Account No.", 'Country validation must not populate an empty bank number.');
        Observer.AssertBankValidationCount(1);
        UnbindSubscription(Observer);
    end;

    [Test]
    procedure FinnishVendorCountryRejectsInvalidAccountChecksum()
    var
        Bank: Record "Vendor Bank Account";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A formerly foreign vendor account must pass the Finnish checksum when its country changes.
        Initialize();

        // [GIVEN] Vendor bank account "B" with an invalid domestic checksum.
        EnsureCountryExists('FI');
        Bank."Country/Region Code" := 'SE';
        Bank."Bank Account No." := '159030-777';

        // [WHEN] The country is changed to FI.
        asserterror Bank.Validate("Country/Region Code", 'FI');

        // [THEN] The replacement validator rejects the checksum.
        Assert.ExpectedError('Error in Bank Account number');
        Assert.ExpectedErrorCode('Dialog');
    end;

#if not CLEAN30
    [Test]
    procedure DisabledFeatureRetainsSingleLegacyValidationForAllBankTypes()
    var
        Bank: Record "Bank Account";
        CustomerBank: Record "Customer Bank Account";
        VendorBank: Record "Vendor Bank Account";
        Observer: Codeunit "Banking FI Validation Tests";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Before cutover, BaseApp remains responsible for bank-country validation.
        InitializeBeforeCutover();

        // [GIVEN] Bank accounts "B", "C" and "V" with valid domestic numbers.
        Bank."Bank Account No." := '159030-776';
        CustomerBank."Bank Account No." := Bank."Bank Account No.";
        VendorBank."Bank Account No." := Bank."Bank Account No.";
        BindSubscription(Observer);

        // [WHEN] Each domestic country is validated while the replacement is inactive.
        Bank.Validate("Country/Region Code", '');
        CustomerBank.Validate("Country/Region Code", '');
        VendorBank.Validate("Country/Region Code", '');

        // [THEN] Each legacy path validates once, without an additional extension validation.
        Observer.AssertBankValidationCount(3);
        UnbindSubscription(Observer);
        DisableFeature();
    end;
#endif

    [Test]
    procedure DomesticCountryRejectsPreviouslyForeignAccount()
    var
        Bank: Record "Bank Account";
    begin
        EnableFeature();
        Bank."Country/Region Code" := 'SE';
        Bank."Bank Account No." := '1234567890123456';
        asserterror Bank.Validate("Country/Region Code", '');
        Assert.ExpectedError('15');
        DisableFeature();
    end;

    [Test]
    procedure ForeignCountryAllowsForeignAccountLength()
    var
        Bank: Record "Bank Account";
        Country: Record "Country/Region";
    begin
        EnableFeature();
        if not Country.Get('SE') then begin
            Country.Code := 'SE';
            Country.Insert();
        end;
        Bank."Bank Account No." := '1234567890123456';
        Bank.Validate("Country/Region Code", Country.Code);
        DisableFeature();
    end;

    [Test]
    procedure ValidDomesticAccountAndReference()
    var
        Check: Codeunit "Bank Nos Check FI";
    begin
        EnableFeature();
        Assert.IsTrue(Check.CheckBankAccount('159030-776', ''), 'The legacy domestic account must remain valid.');
        Check.InvReferenceCheck('268745');
        DisableFeature();
    end;

    [Test]
    procedure InvalidChecksumRejected()
    var
        Check: Codeunit "Bank Nos Check FI";
    begin
        EnableFeature();
        asserterror Check.InvReferenceCheck('2687451');
        Assert.ExpectedError('Incorrect reference number.');
        DisableFeature();
    end;

    [Test]
    procedure ZeroReferenceRejected()
    var
        Check: Codeunit "Bank Nos Check FI";
    begin
        EnableFeature();
        asserterror Check.InvReferenceCheck('000000');
        Assert.ExpectedError('Reference number cannot contain only zeros.');
        DisableFeature();
    end;

    [Test]
    procedure CustomerAccountCannotBeTruncatedBeforeValidation()
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        EnableFeature();
        CustomerBankAccount."Country/Region Code" := 'FI';
        asserterror CustomerBankAccount.Validate("Bank Account No.", '159030-7761234567');
        Assert.ExpectedError('15');
        DisableFeature();
    end;

    [Test]
    procedure ReferenceLengthCheckedBeforeChecksum()
    var
        Journal: Record "Gen. Journal Line";
    begin
        EnableFeature();
        Journal."Bank Message Type" := Journal."Bank Message Type"::"Reference No";
        asserterror Journal.Validate("Payment Message", '123456789012345678901');
        Assert.ExpectedError('20');
        DisableFeature();
    end;

    procedure AssertBankValidationCount(Expected: Integer)
    begin
        Assert.AreEqual(Expected, BankValidationCount, 'A country change must revalidate the account number exactly once.');
    end;

    local procedure Initialize()
    begin
        LibraryBanking.SetCompletedFeatureFixture();
    end;

#if not CLEAN30
    local procedure InitializeBeforeCutover()
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
        Assert.IsFalse(FeatureManagementFacade.IsEnabled('BankingAndPaymentsFI'), 'Feature-off integration tests require an inactive installation, not a migrated company.');
        LibraryBanking.SetFeatureEnabled(false);
        BindSubscription(LibraryBanking);
    end;
#endif

    local procedure EnsureCountryExists(CountryCode: Code[10])
    var
        Country: Record "Country/Region";
    begin
        if Country.Get(CountryCode) then
            exit;
        Country.Code := CountryCode;
        Country.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnAfterValidateEvent', 'Bank Account No.', false, false)]
    local procedure CountBankValidation()
    begin
        BankValidationCount += 1;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer Bank Account", 'OnAfterValidateEvent', 'Bank Account No.', false, false)]
    local procedure CountCustomerBankValidation()
    begin
        BankValidationCount += 1;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", 'OnAfterValidateEvent', 'Bank Account No.', false, false)]
    local procedure CountVendorBankValidation()
    begin
        BankValidationCount += 1;
    end;

    local procedure EnableFeature()
    begin
#if not CLEAN30
        LibraryBanking.SetFeatureEnabled(true);
        BindSubscription(LibraryBanking);
#endif
    end;

    local procedure DisableFeature()
    begin
#if not CLEAN30
        UnbindSubscription(LibraryBanking);
#endif
    end;
}
