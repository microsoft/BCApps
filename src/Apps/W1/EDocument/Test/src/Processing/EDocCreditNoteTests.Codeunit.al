// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;

codeunit 135649 "EDoc Credit Note Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";

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
        EDocPurchaseDraftUtility: Codeunit "E-Doc. Purchase Draft Utility";
        SourceJson: JsonObject;
        Joined: Text;
    begin
        // [SCENARIO] Billing references are read, the credit note's own number and duplicates are dropped
        SourceJson.Add('billing_reference', BuildBillingReferences('INV-100', 'CN-7', 'INV-100'));

        Joined := EDocPurchaseDraftUtility.JoinInvoiceReferences(EDocMLLMSchemaHelper.GetInvoiceReferences(SourceJson, 'CN-7'));

        Assert.AreEqual('INV-100', Joined, 'Only the referenced invoice must remain.');
        Assert.IsFalse(EDocPurchaseDraftUtility.ReferencesSeveralInvoices(Joined), 'A single reference is not several invoices.');
    end;

    [Test]
    procedure SeveralInvoiceReferencesAreKeptTogether()
    var
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        EDocPurchaseDraftUtility: Codeunit "E-Doc. Purchase Draft Utility";
        SourceJson: JsonObject;
        Joined: Text;
    begin
        // [SCENARIO] A credit note for several invoices keeps all of them, so it is never applied to only one
        SourceJson.Add('billing_reference', BuildBillingReferences('INV-100', 'INV-101', ''));

        Joined := EDocPurchaseDraftUtility.JoinInvoiceReferences(EDocMLLMSchemaHelper.GetInvoiceReferences(SourceJson, 'CN-7'));

        Assert.AreEqual('INV-100, INV-101', Joined, 'All referenced invoices must be kept.');
        Assert.IsTrue(EDocPurchaseDraftUtility.ReferencesSeveralInvoices(Joined), 'Several references must be detected.');
    end;

    #endregion

    #region Signs

    [Test]
    procedure NegativeCreditNoteBecomesPositive()
    var
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLine: Record "E-Document Purchase Line" temporary;
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
    begin
        // [SCENARIO] A credit note printed with negative amounts gets positive amounts; a fee with the opposite sign reduces the credit
        TempHeader."Sub Total" := -190;
        TempHeader."Total VAT" := -47.5;
        TempHeader.Total := -237.5;
        TempHeader."Amount Due" := -237.5;
        InsertLine(TempLine, 10000, -2, 100, -200);
        InsertLine(TempLine, 20000, 1, 10, 10);

        EDocMLLMSchemaHelper.NormalizeCreditNoteSigns(TempHeader, TempLine);

        Assert.AreEqual(190, TempHeader."Sub Total", 'Sub Total');
        Assert.AreEqual(47.5, TempHeader."Total VAT", 'Total VAT');
        Assert.AreEqual(237.5, TempHeader.Total, 'Total');
        TempLine.Get(0, 10000);
        Assert.AreEqual(2, TempLine.Quantity, 'Credited line quantity must be positive.');
        Assert.AreEqual(100, TempLine."Unit Price", 'Credited line unit price must be positive.');
        TempLine.Get(0, 20000);
        Assert.AreEqual(-1, TempLine.Quantity, 'A fee with the opposite sign must reduce the credit.');
        Assert.AreEqual(10, TempLine."Unit Price", 'Unit price stays positive.');
    end;

    [Test]
    procedure PositiveCreditNoteIsUnchanged()
    var
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLine: Record "E-Document Purchase Line" temporary;
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
    begin
        // [SCENARIO] A credit note printed with positive amounts keeps them
        TempHeader.Total := 125;
        InsertLine(TempLine, 10000, 1, 100, 100);

        EDocMLLMSchemaHelper.NormalizeCreditNoteSigns(TempHeader, TempLine);

        Assert.AreEqual(125, TempHeader.Total, 'Total');
        TempLine.Get(0, 10000);
        Assert.AreEqual(1, TempLine.Quantity, 'Quantity');
        Assert.AreEqual(100, TempLine."Unit Price", 'Unit Price');
    end;

    [Test]
    procedure NegativeQuantityIsKeptOnlyForCreditNotes()
    var
        TempLine: Record "E-Document Purchase Line" temporary;
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        LinesArray: JsonArray;
    begin
        // [SCENARIO] Invoices still clamp negative quantities to zero; credit notes keep them for sign normalization
        LinesArray.Add(BuildLine(-3, 50));

        EDocMLLMSchemaHelper.MapLinesFromJson(LinesArray, 1, TempLine, '');
        TempLine.FindFirst();
        Assert.AreEqual(0, TempLine.Quantity, 'Invoices clamp negative quantities.');

        EDocMLLMSchemaHelper.MapLinesFromJson(LinesArray, 1, TempLine, '', true);
        TempLine.FindFirst();
        Assert.AreEqual(-3, TempLine.Quantity, 'Credit notes keep negative quantities.');
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

    #endregion

    local procedure CreateVendor(PayToVendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Init();
        Vendor."No." := CopyStr('CN' + Format(LibraryRandom.RandIntInRange(10000000, 99999999)), 1, MaxStrLen(Vendor."No."));
        Vendor."Pay-to Vendor No." := PayToVendorNo;
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateInvoiceEntry(VendorNo: Code[20]; DocumentNo: Code[20]; ExternalDocumentNo: Code[35]; CurrencyCode: Code[10]; IsOpen: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EntryNo: Integer;
    begin
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

    local procedure InsertLine(var TempLine: Record "E-Document Purchase Line" temporary; LineNo: Integer; Quantity: Decimal; UnitPrice: Decimal; SubTotal: Decimal)
    begin
        TempLine.Init();
        TempLine."Line No." := LineNo;
        TempLine.Quantity := Quantity;
        TempLine."Unit Price" := UnitPrice;
        TempLine."Sub Total" := SubTotal;
        TempLine.Insert();
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

    local procedure BuildLine(Quantity: Decimal; UnitPrice: Decimal) Line: JsonObject
    var
        QuantityObj: JsonObject;
        PriceObj: JsonObject;
        ItemObj: JsonObject;
    begin
        QuantityObj.Add('value', Quantity);
        PriceObj.Add('price_amount', UnitPrice);
        ItemObj.Add('name', 'Returned goods');
        Line.Add('invoiced_quantity', QuantityObj);
        Line.Add('price', PriceObj);
        Line.Add('item', ItemObj);
    end;
}
