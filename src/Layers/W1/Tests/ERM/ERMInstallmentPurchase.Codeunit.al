// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;

codeunit 134501 "ERM Installment Purchase"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibraryInstallments: Codeunit "Library - ERM Installments";
        LibraryPurchase: Codeunit "Library - Purchase";

    [Test]
    procedure PurchaseInvoicePostsOnePayablePerInstallment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Plan: Record "Purchase Installment Plan";
        PlanLine: Record "Purchase Installment Plan Line";
        TempPlanLine: Record "Purchase Installment Plan Line" temporary;
        PurchaseInstallmentMgt: Codeunit "Purchase Installment Mgt.";
        PostedInvoiceNo: Code[20];
        PlanID: Guid;
        AnchorEntryNo: Integer;
        InstallmentNo: Integer;
    begin
        LibraryInstallments.CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, '');
        PlanID := PurchaseHeader."Installment Plan ID";
        Assert.IsFalse(IsNullGuid(PlanID), 'A purchase invoice with installment terms must own a purchase plan.');
        PurchaseInstallmentMgt.CalculatePreview(PurchaseHeader, TempPlanLine);
        Assert.AreEqual(3, TempPlanLine.Count(), 'The purchase preview must contain one line per installment.');

        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.Get(PostedInvoiceNo);
        PurchInvHeader.TestField("Installment Plan ID", PlanID);
        Plan.Get(PlanID);
        Plan.TestField(Status, Plan.Status::Posted);
        Plan.TestField("Posted Invoice No.", PostedInvoiceNo);
        VendorLedgerEntry.SetRange("Installment Plan ID", PlanID);
        Assert.AreEqual(3, VendorLedgerEntry.Count(), 'Posting must create one vendor ledger entry per installment.');
        PlanLine.SetCurrentKey("Plan ID", "Installment No.");
        PlanLine.SetRange("Plan ID", PlanID);
        PlanLine.FindSet();
        repeat
            InstallmentNo += 1;
            PlanLine.TestField("Installment No.", InstallmentNo);
            VendorLedgerEntry.SetRange("Installment No.", InstallmentNo);
            VendorLedgerEntry.FindFirst();
            VendorLedgerEntry.TestField("Document No.", PostedInvoiceNo);
            VendorLedgerEntry.TestField("Installment Plan ID", PlanID);
            VendorLedgerEntry.TestField("No. of Installments", 3);
            PlanLine.TestField("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
            if AnchorEntryNo = 0 then
                AnchorEntryNo := VendorLedgerEntry."Invoice Entry No.";
            VendorLedgerEntry.TestField("Invoice Entry No.", AnchorEntryNo);
        until PlanLine.Next() = 0;
    end;
}
