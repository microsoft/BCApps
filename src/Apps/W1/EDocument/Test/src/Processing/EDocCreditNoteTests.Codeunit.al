// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;

codeunit 135649 "EDoc Credit Note Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    #region Document type

    [Test]
    procedure TypeCode381IsCreditNote()
    var
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        SourceJson: JsonObject;
    begin
        // [SCENARIO] The extraction type code 381 marks the document as a credit note
        SourceJson.Add('invoice_type_code', '381');
        Assert.IsTrue(EDocMLLMSchemaHelper.IsCreditNote(SourceJson), 'Type code 381 must be read as a credit note.');
    end;

    [Test]
    procedure TypeCode380OrMissingIsInvoice()
    var
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        InvoiceJson: JsonObject;
        EmptyJson: JsonObject;
    begin
        // [SCENARIO] Anything other than 381 is read as an invoice, so an invoice is never turned into a credit memo by default
        InvoiceJson.Add('invoice_type_code', '380');
        Assert.IsFalse(EDocMLLMSchemaHelper.IsCreditNote(InvoiceJson), 'Type code 380 must be read as an invoice.');
        Assert.IsFalse(EDocMLLMSchemaHelper.IsCreditNote(EmptyJson), 'A missing type code must be read as an invoice.');
    end;

    #endregion

    #region Invoice references

    [Test]
    procedure InvoiceReferencesExcludeOwnNumberAndDuplicates()
    var
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        SourceJson: JsonObject;
        InvoiceReferences: List of [Text];
    begin
        // [SCENARIO] Billing references are read, the credit note's own number and duplicates are dropped
        SourceJson.Add('billing_reference', BuildBillingReferences('INV-100', 'CN-7', 'INV-100'));

        InvoiceReferences := EDocMLLMSchemaHelper.GetInvoiceReferences(SourceJson, 'CN-7');

        Assert.AreEqual(1, InvoiceReferences.Count(), 'Only the referenced invoice must remain.');
        Assert.AreEqual('INV-100', InvoiceReferences.Get(1), 'The referenced invoice must be kept.');
    end;

    [Test]
    procedure SeveralInvoiceReferencesAreAllRead()
    var
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        SourceJson: JsonObject;
        InvoiceReferences: List of [Text];
    begin
        // [SCENARIO] A credit note for several invoices returns all of them, so the draft can use the first and warn about the others
        SourceJson.Add('billing_reference', BuildBillingReferences('INV-100', 'INV-101', ''));

        InvoiceReferences := EDocMLLMSchemaHelper.GetInvoiceReferences(SourceJson, 'CN-7');

        Assert.AreEqual(2, InvoiceReferences.Count(), 'Both referenced invoices must be read.');
        Assert.AreEqual('INV-100', InvoiceReferences.Get(1), 'The first referenced invoice is the one used.');
    end;

    #endregion

    #region Invoice resolver

    [Test]
    procedure ResolvesOpenInvoiceByPostedInvoiceNo()
    var
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        VendorNo: Code[20];
        PostedInvoiceNo: Code[20];
        FailureReason: Text;
    begin
        // [SCENARIO] The Business Central posted invoice number resolves to itself
        VendorNo := CreateVendor('');
        CreateInvoiceEntry(VendorNo, 'PI-1001', 'INV-100', '', true);

        Assert.IsTrue(EDocPurchDocHelper.TryResolveOpenInvoice(VendorNo, '', 'PI-1001', PostedInvoiceNo, FailureReason), FailureReason);
        Assert.AreEqual('PI-1001', PostedInvoiceNo, 'Posted invoice no.');
    end;

    [Test]
    procedure ResolvesOpenInvoiceByVendorInvoiceNo()
    var
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        VendorNo: Code[20];
        PostedInvoiceNo: Code[20];
        FailureReason: Text;
    begin
        // [SCENARIO] The vendor's own invoice number (as printed on the credit note) resolves to the posted invoice
        VendorNo := CreateVendor('');
        CreateInvoiceEntry(VendorNo, 'PI-1002', 'INV-200', '', true);

        Assert.IsTrue(EDocPurchDocHelper.TryResolveOpenInvoice(VendorNo, '', 'INV-200', PostedInvoiceNo, FailureReason), FailureReason);
        Assert.AreEqual('PI-1002', PostedInvoiceNo, 'Posted invoice no.');
    end;

    [Test]
    procedure ResolvesInvoiceOnPayToVendor()
    var
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        PayToVendorNo: Code[20];
        BuyFromVendorNo: Code[20];
        PostedInvoiceNo: Code[20];
        FailureReason: Text;
    begin
        // [SCENARIO] Ledger entries are posted on the pay-to vendor, so the lookup uses it
        PayToVendorNo := CreateVendor('');
        BuyFromVendorNo := CreateVendor(PayToVendorNo);
        CreateInvoiceEntry(PayToVendorNo, 'PI-1003', 'INV-300', '', true);

        Assert.AreEqual(PayToVendorNo, EDocPurchDocHelper.GetPayToVendorNo(BuyFromVendorNo), 'Pay-to vendor');
        Assert.IsTrue(EDocPurchDocHelper.TryResolveOpenInvoice(EDocPurchDocHelper.GetPayToVendorNo(BuyFromVendorNo), '', 'INV-300', PostedInvoiceNo, FailureReason), FailureReason);
        Assert.AreEqual('PI-1003', PostedInvoiceNo, 'Posted invoice no.');
    end;

    [Test]
    procedure ClosedInvoiceIsNotResolved()
    var
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        VendorNo: Code[20];
        PostedInvoiceNo: Code[20];
        FailureReason: Text;
    begin
        // [SCENARIO] A paid (closed) invoice is never applied to
        VendorNo := CreateVendor('');
        CreateInvoiceEntry(VendorNo, 'PI-1004', 'INV-400', '', false);

        Assert.IsFalse(EDocPurchDocHelper.TryResolveOpenInvoice(VendorNo, '', 'INV-400', PostedInvoiceNo, FailureReason), 'A closed invoice must not be resolved.');
        Assert.AreEqual('', PostedInvoiceNo, 'No invoice must be returned.');
        Assert.AreNotEqual('', FailureReason, 'The reason must be returned.');
    end;

    [Test]
    procedure InvoiceOfOtherVendorIsNotResolved()
    var
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        VendorNo: Code[20];
        PostedInvoiceNo: Code[20];
        FailureReason: Text;
    begin
        // [SCENARIO] An invoice with the same number at another vendor is never applied to
        VendorNo := CreateVendor('');
        CreateInvoiceEntry(CreateVendor(''), 'PI-1005', 'INV-500', '', true);

        Assert.IsFalse(EDocPurchDocHelper.TryResolveOpenInvoice(VendorNo, '', 'INV-500', PostedInvoiceNo, FailureReason), 'Another vendor''s invoice must not be resolved.');
    end;

    [Test]
    procedure AmbiguousInvoiceIsNotResolved()
    var
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        VendorNo: Code[20];
        PostedInvoiceNo: Code[20];
        FailureReason: Text;
    begin
        // [SCENARIO] When several open invoices match, nothing is guessed
        VendorNo := CreateVendor('');
        CreateInvoiceEntry(VendorNo, 'PI-1006', 'INV-600', '', true);
        CreateInvoiceEntry(VendorNo, 'PI-1007', 'INV-600', '', true);

        Assert.IsFalse(EDocPurchDocHelper.TryResolveOpenInvoice(VendorNo, '', 'INV-600', PostedInvoiceNo, FailureReason), 'An ambiguous reference must not be resolved.');
        Assert.AreEqual('', PostedInvoiceNo, 'No invoice must be returned.');
    end;

    [Test]
    procedure InvoiceInOtherCurrencyIsNotResolvedWhenNotAllowed()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        VendorNo: Code[20];
        PostedInvoiceNo: Code[20];
        FailureReason: Text;
    begin
        // [SCENARIO] Cross-currency application follows the "Appln. between Currencies" setup
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Appln. between Currencies" := PurchasesPayablesSetup."Appln. between Currencies"::None;
        PurchasesPayablesSetup.Modify();
        VendorNo := CreateVendor('');
        CreateInvoiceEntry(VendorNo, 'PI-1008', 'INV-800', 'XYZ', true);

        Assert.IsFalse(EDocPurchDocHelper.TryResolveOpenInvoice(VendorNo, '', 'INV-800', PostedInvoiceNo, FailureReason), 'A different currency must not be resolved when application between currencies is not allowed.');
        Assert.IsTrue(EDocPurchDocHelper.TryResolveOpenInvoice(VendorNo, 'XYZ', 'INV-800', PostedInvoiceNo, FailureReason), FailureReason);
    end;

    [Test]
    procedure LookupOffersOnlyInvoicesMatchingAmbiguousReference()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        VendorNo: Code[20];
    begin
        // [SCENARIO] When the invoice reference matches several open invoices, the lookup offers only those invoices
        VendorNo := CreateVendor('');
        CreateInvoiceEntry(VendorNo, 'PI-1009', 'INV-900', '', true);
        CreateInvoiceEntry(VendorNo, 'PI-1010', 'INV-900', '', true);
        CreateInvoiceEntry(VendorNo, 'PI-1011', 'INV-901', '', true);

        EDocPurchDocHelper.FilterOpenInvoicesToApplyTo(VendorNo, 'INV-900', VendorLedgerEntry);
        Assert.RecordCount(VendorLedgerEntry, 2);
    end;

    [Test]
    procedure LookupOffersAllOpenInvoicesWhenReferenceIsNotAmbiguous()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EDocPurchDocHelper: Codeunit "E-Doc. Purch. Doc. Helper";
        VendorNo: Code[20];
    begin
        // [SCENARIO] When the invoice reference matches at most one open invoice, the lookup offers all open invoices of the vendor
        VendorNo := CreateVendor('');
        CreateInvoiceEntry(VendorNo, 'PI-1012', 'INV-1200', '', true);
        CreateInvoiceEntry(VendorNo, 'PI-1013', 'INV-1300', '', true);
        CreateInvoiceEntry(VendorNo, 'PI-1014', 'INV-1400', '', false);

        EDocPurchDocHelper.FilterOpenInvoicesToApplyTo(VendorNo, 'INV-1200', VendorLedgerEntry);
        Assert.RecordCount(VendorLedgerEntry, 2);
    end;

    #endregion

    local procedure CreateVendor(PayToVendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        LibraryUtility: Codeunit "Library - Utility";
    begin
        // Synthetic on purpose, like CreateInvoiceEntry: these tests read only the vendor number and pay-to vendor, and nothing is posted.
        // Library - Purchase.CreateVendor needs number series and VAT setup that some localized test companies do not have.
        Vendor."No." := LibraryUtility.GenerateRandomCode20(Vendor.FieldNo("No."), Database::Vendor);
        Vendor."Pay-to Vendor No." := PayToVendorNo;
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateInvoiceEntry(VendorNo: Code[20]; DocumentNo: Code[20]; ExternalDocumentNo: Code[35]; CurrencyCode: Code[10]; IsOpen: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EntryNo: Integer;
    begin
        // Synthetic on purpose: the resolver reads only the fields set below, and some cases cannot be
        // produced by posting at all - two open invoices sharing an external document number is exactly
        // what posting prevents. The posted path is covered end to end by
        // PostedCreditMemoReducesRemainingAmountOfOriginalInvoice in codeunit 139883.
        if VendorLedgerEntry.FindLast() then
            EntryNo := VendorLedgerEntry."Entry No.";
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := EntryNo + 1;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Document No." := DocumentNo;
        VendorLedgerEntry."External Document No." := ExternalDocumentNo;
        VendorLedgerEntry."Currency Code" := CurrencyCode;
        VendorLedgerEntry.Open := IsOpen;
        VendorLedgerEntry.Insert();
    end;

    local procedure BuildBillingReferences(Reference1: Text; Reference2: Text; Reference3: Text) References: JsonArray
    begin
        AddBillingReference(References, Reference1);
        AddBillingReference(References, Reference2);
        AddBillingReference(References, Reference3);
    end;

    local procedure AddBillingReference(var References: JsonArray; Reference: Text)
    var
        DocumentReference: JsonObject;
        BillingReference: JsonObject;
    begin
        if Reference = '' then
            exit;
        DocumentReference.Add('id', Reference);
        BillingReference.Add('invoice_document_reference', DocumentReference);
        References.Add(BillingReference);
    end;
}
