// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Sales.Setup;

codeunit 148233 "Banking FI Reference Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        LibraryBanking: Codeunit "Library - Banking FI";
        ExpectedImportedPayment: Record "Ref. Payment - Imported FI";

    [Test]
    procedure InvoiceDigitsGenerateReference()
    var
        Check: Codeunit "Bank Nos Check FI";
        Reference: Code[20];
    begin
        EnableFeature();
        LibraryBanking.SetInvoiceReferenceSetup();
        Reference := Check.CreateSalesInvReference('INV26874', '');
        Assert.AreEqual('268745', Reference, 'Invoice digits and the 7-3-1 check digit must be preserved.');
        Check.InvReferenceCheck(Reference);
        DisableFeature();
    end;

    [Test]
    procedure CustomerDigitsPrependInvoiceDigits()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        Check: Codeunit "Bank Nos Check FI";
        Reference: Code[20];
    begin
        EnableFeature();
        LibraryBanking.SetInvoiceReferenceSetup();
        SalesSetup.Get();
        SalesSetup."Use Customer No. in Reference" := true;
        SalesSetup.Modify();
        Reference := Check.CreateSalesInvReference('INV26874', 'CUST12');
        Assert.AreEqual('1226874', CopyStr(Reference, 1, 7), 'Customer and invoice digits must retain their order.');
        Check.InvReferenceCheck(Reference);
        DisableFeature();
    end;

    [Test]
    procedure CombinedReferenceCannotExceedTwentyCharacters()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        Check: Codeunit "Bank Nos Check FI";
    begin
        EnableFeature();
        LibraryBanking.SetInvoiceReferenceSetup();
        SalesSetup.Get();
        SalesSetup."Use Customer No. in Reference" := true;
        SalesSetup.Modify();
        asserterror Check.CreateSalesInvReference('1234567890', '1234567890');
        Assert.ExpectedError('Reference number cannot be over 20 character long');
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('ImportedPaymentLookupHandler')]
    procedure DefaultLookupShowsUnpostedImportedPayment()
    begin
        VerifyDefaultImportedPaymentLookup(false);
    end;

    [Test]
    [HandlerFunctions('ImportedPaymentLookupHandler')]
    procedure DefaultLookupShowsPostedImportedHistory()
    begin
        VerifyDefaultImportedPaymentLookup(true);
    end;

    local procedure VerifyDefaultImportedPaymentLookup(Posted: Boolean)
    var
        ImportedPayment: Record "Ref. Payment - Imported FI";
    begin
        EnableFeature();
        Clear(ExpectedImportedPayment);
        ImportedPayment.LockTable();
        if ImportedPayment.FindLast() then
            ExpectedImportedPayment."No." := ImportedPayment."No." + 1
        else
            ExpectedImportedPayment."No." := 1;
        ExpectedImportedPayment."Record ID" := 3;
        ExpectedImportedPayment."Filing Code" := 'FI-LOOKUP';
        ExpectedImportedPayment."Reference No." := '268745';
        ExpectedImportedPayment."Banks Posting Date" := WorkDate();
        ExpectedImportedPayment.Amount := 123.45;
        ExpectedImportedPayment.Matched := true;
        ExpectedImportedPayment."Posted to G/L" := Posted;
        ExpectedImportedPayment.Insert();

        ImportedPayment := ExpectedImportedPayment;
        ImportedPayment.SetRecFilter();
        Page.RunModal(0, ImportedPayment);
        DisableFeature();
    end;

    [ModalPageHandler]
    procedure ImportedPaymentLookupHandler(var ImportedPayments: TestPage "Ref. Payment - Import FI")
    begin
        ImportedPayments."Filing Code".AssertEquals(ExpectedImportedPayment."Filing Code");
        ImportedPayments."Reference No.".AssertEquals(ExpectedImportedPayment."Reference No.");
        ImportedPayments."Banks Posting Date".AssertEquals(ExpectedImportedPayment."Banks Posting Date");
        ImportedPayments.Amount.AssertEquals(ExpectedImportedPayment.Amount);
        ImportedPayments.Close();
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
