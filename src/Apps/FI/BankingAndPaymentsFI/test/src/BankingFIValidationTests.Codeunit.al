// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Customer;

codeunit 148231 "Banking FI Validation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        LibraryBanking: Codeunit "Library - Banking FI";
        Assert: Codeunit Assert;

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
