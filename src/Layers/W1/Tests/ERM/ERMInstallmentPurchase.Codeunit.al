// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Upgrade;
using System.TestLibraries.Upgrade;
using System.TestLibraries.Utilities;
using System.Upgrade;

codeunit 134501 "ERM Installment Purchase"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Installments] [Purchase]
    end;

    var
        Assert: Codeunit Assert;
        LibraryInstallments: Codeunit "Library - ERM Installments";
        LibraryPurchase: Codeunit "Library - Purchase";

    [Test]
    procedure DisabledFeatureIgnoresGlobalRulesForPurchaseInvoiceAndJournal()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        OrdinaryTerms: Record "Payment Terms";
        LibraryERM: Codeunit "Library - ERM";
        PurchaseInstallmentPosting: Codeunit "Purchase Installment Posting";
        InstallmentTermsCode: Code[10];
    begin
        // [SCENARIO] Disabled global rules neither create a purchase schedule nor restrict ordinary journal use.
        // [GIVEN] An ordinary purchase invoice and disabled global installment rules.
        LibraryInstallments.CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, '');
        InstallmentTermsCode := PurchaseHeader."Payment Terms Code";
        LibraryERM.CreatePaymentTerms(OrdinaryTerms);
        PurchaseHeader.Validate("Payment Terms Code", OrdinaryTerms.Code);
        PurchaseHeader.Modify(true);
        LibraryInstallments.SetFeatureEnabled(false);

        // [WHEN] Installment payment terms are selected while the feature is disabled.
        PurchaseHeader.Validate("Payment Terms Code", InstallmentTermsCode);
        PurchaseHeader.Modify(true);
        // [THEN] No global plan is created and ordinary vendor journal validation accepts the terms.
        Assert.IsTrue(IsNullGuid(PurchaseHeader."Installment Plan ID"), 'Disabled global rules must not create a purchase installment plan.');
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Invoice;
        GenJournalLine."Payment Terms Code" := InstallmentTermsCode;
        PurchaseInstallmentPosting.CheckJournalLine(GenJournalLine);
    end;

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
        AnchorEntryNo: BigInteger;
        InstallmentNo: Integer;
    begin
        // [SCENARIO] Posting a purchase installment invoice creates one payable per previewed obligation.
        // [GIVEN] A purchase invoice with a three-installment draft schedule.
        LibraryInstallments.CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, '');
        PlanID := PurchaseHeader."Installment Plan ID";
        Assert.IsFalse(IsNullGuid(PlanID), 'A purchase invoice with installment terms must own a purchase plan.');
        PurchaseInstallmentMgt.CalculatePreview(PurchaseHeader, TempPlanLine);
        Assert.AreEqual(3, TempPlanLine.Count(), 'The purchase preview must contain one line per installment.');

        // [WHEN] The purchase invoice is posted.
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The posted plan owns three vendor entries sharing the invoice anchor and matching each schedule line.
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

    [Test]
    procedure VendorUpgradeInitializesOrdinaryEntriesAfterCustomerUpgrade()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        OrdinaryTerms: Record "Payment Terms";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        OriginalDetailedEntry: Record "Detailed Vendor Ledg. Entry";
        LibraryERM: Codeunit "Library - ERM";
        LibraryAssert: Codeunit "Library Assert";
        InstallmentLedgerUpgrade: Codeunit "Installment Ledger Upgrade";
        VendorModifiedAt: DateTime;
    begin
        // [SCENARIO] Vendor initialization runs independently of the completed customer upgrade and preserves financial and audit data.
        // [GIVEN] An ordinary posted invoice predates the vendor invoice-group fields.
        LibraryInstallments.CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, '');
        LibraryERM.CreatePaymentTerms(OrdinaryTerms);
        PurchaseHeader.Validate("Payment Terms Code", OrdinaryTerms.Code);
        PurchaseHeader.Modify(true);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        VendorLedgerEntry.Get(PurchInvHeader."Vendor Ledger Entry No.");
        VendorLedgerEntry."Invoice Entry No." := 0;
        VendorLedgerEntry.Modify();
        VendorModifiedAt := VendorLedgerEntry.SystemModifiedAt;
        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        DetailedVendorLedgEntry.ModifyAll("Invoice Entry No.", 0);
        DetailedVendorLedgEntry.FindFirst();
        OriginalDetailedEntry := DetailedVendorLedgEntry;
        PrepareVendorUpgradeAfterCustomerUpgrade();

        // [WHEN] The vendor upgrade runs after the customer upgrade has already completed.
        InstallmentLedgerUpgrade.UpgradeVendorInvoiceGroups();
        InstallmentLedgerUpgrade.UpgradeVendorInvoiceGroups();

        // [THEN] Ordinary entries use their own ledger anchor without changing amounts or audit timestamps.
        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.TestField("Invoice Entry No.", VendorLedgerEntry."Entry No.");
        LibraryAssert.AreEqualDateTime(VendorModifiedAt, VendorLedgerEntry.SystemModifiedAt, 'Initialization must preserve the vendor ledger audit timestamp.');
        DetailedVendorLedgEntry.Get(OriginalDetailedEntry."Entry No.");
        DetailedVendorLedgEntry.TestField("Invoice Entry No.", VendorLedgerEntry."Entry No.");
        Assert.AreEqual(OriginalDetailedEntry.Amount, DetailedVendorLedgEntry.Amount, 'Initialization must not change vendor amounts.');
        Assert.AreEqual(OriginalDetailedEntry."Amount (LCY)", DetailedVendorLedgEntry."Amount (LCY)", 'Initialization must not change vendor LCY amounts.');
        LibraryAssert.AreEqualDateTime(OriginalDetailedEntry.SystemModifiedAt, DetailedVendorLedgEntry.SystemModifiedAt, 'Initialization must preserve the detailed entry audit timestamp.');
    end;

    [Test]
    procedure VendorUpgradeRetriesIncompletePlansAndContinuesWithValidPlans()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        OtherPurchInvHeader: Record "Purch. Inv. Header";
        Plan: Record "Purchase Installment Plan";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InstallmentLedgerUpgrade: Codeunit "Installment Ledger Upgrade";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        // [SCENARIO] An inconsistent purchase plan does not block valid groups or permanently complete the vendor upgrade.
        // [GIVEN] A posted plan has inconsistent invoice identity, while another posted plan is valid.
        LibraryInstallments.CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, '');
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        Plan.Get(PurchInvHeader."Installment Plan ID");
        Plan."Posted Invoice SystemId" := CreateGuid();
        Plan.Modify();
        LibraryInstallments.CreatePurchaseInvoice(PurchaseHeader, PurchaseLine, '');
        OtherPurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        ClearVendorInvoiceGroups(Plan.ID);
        ClearVendorInvoiceGroups(OtherPurchInvHeader."Installment Plan ID");
        PrepareVendorUpgradeAfterCustomerUpgrade();

        // [WHEN] The vendor upgrade encounters the inconsistent plan.
        InstallmentLedgerUpgrade.UpgradeVendorInvoiceGroups();

        // [THEN] The valid plan is grouped, but the incomplete upgrade remains retryable.
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPurchaseInstallmentInvoiceGroupUpgradeTag()), 'An incomplete vendor backfill must not set its upgrade tag.');
        VerifyVendorInvoiceGroups(OtherPurchInvHeader);
        VendorLedgerEntry.SetRange("Installment Plan ID", Plan.ID);
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.TestField("Invoice Entry No.", VendorLedgerEntry."Entry No.");
        until VendorLedgerEntry.Next() = 0;

        // [WHEN] The invoice identity is repaired and the upgrade is repeated.
        Plan."Posted Invoice SystemId" := PurchInvHeader.SystemId;
        Plan.Modify();
        InstallmentLedgerUpgrade.UpgradeVendorInvoiceGroups();
        InstallmentLedgerUpgrade.UpgradeVendorInvoiceGroups();

        // [THEN] Both groups retain their correct anchors and the vendor upgrade completes independently.
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPurchaseInstallmentInvoiceGroupUpgradeTag()), 'A successful vendor backfill must set its own upgrade tag.');
        VerifyVendorInvoiceGroups(PurchInvHeader);
        VerifyVendorInvoiceGroups(OtherPurchInvHeader);
    end;

    [Test]
    procedure PurchaseInstallmentRetainsBigIntegerLedgerEntryNumbers()
    var
        PlanLine: Record "Purchase Installment Plan Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PurchaseInstallmentPosting: Codeunit "Purchase Installment Posting";
        PurchaseInstallmentHistory: Codeunit "Purchase Installment History";
        EntryNo: BigInteger;
        DetailedEntryNo: BigInteger;
    begin
        // [SCENARIO] Recording and grouping a purchase installment preserves an entry number beyond the Integer range.
        // [GIVEN] A vendor installment and its initial detailed entry have a large ledger entry number.
        if VendorLedgerEntry.FindLast() then
            EntryNo := VendorLedgerEntry."Entry No.";
        if EntryNo < 2147483647 then
            EntryNo := 2147483647;
        EntryNo += 1;
        if DetailedVendorLedgEntry.FindLast() then
            DetailedEntryNo := DetailedVendorLedgEntry."Entry No.";
        DetailedEntryNo += 1;
        PlanLine."Plan ID" := CreateGuid();
        PlanLine."Line No." := 10000;
        PlanLine."Installment No." := 1;
        PlanLine.Amount := 100;
        PlanLine."Amount (LCY)" := 100;
        PlanLine.Insert();
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := EntryNo;
        VendorLedgerEntry."Installment Plan ID" := PlanLine."Plan ID";
        VendorLedgerEntry."Installment No." := PlanLine."Installment No.";
        VendorLedgerEntry."No. of Installments" := 1;
        VendorLedgerEntry.Insert();
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := DetailedEntryNo;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := EntryNo;
        DetailedVendorLedgEntry."Entry Type" := DetailedVendorLedgEntry."Entry Type"::"Initial Entry";
        DetailedVendorLedgEntry.Amount := -PlanLine.Amount;
        DetailedVendorLedgEntry."Amount (LCY)" := -PlanLine."Amount (LCY)";
        DetailedVendorLedgEntry.Insert();

        // [WHEN] The posted installment is recorded and its invoice group is restored.
        PurchaseInstallmentPosting.RecordPostedLine(PlanLine, VendorLedgerEntry, 1);
        ClearVendorInvoiceGroups(PlanLine."Plan ID");
        PurchaseInstallmentHistory.SetInvoiceGroup(PlanLine."Plan ID", EntryNo);

        // [THEN] The plan relation and both ledger group anchors retain the full entry number.
        PlanLine.Get(PlanLine."Plan ID", PlanLine."Line No.");
        PlanLine.TestField("Vendor Ledger Entry No.", EntryNo);
        PlanLine.Validate("Vendor Ledger Entry No.", EntryNo);
        VendorLedgerEntry.Get(EntryNo);
        VendorLedgerEntry.TestField("Invoice Entry No.", EntryNo);
        DetailedVendorLedgEntry.Get(DetailedEntryNo);
        DetailedVendorLedgEntry.TestField("Invoice Entry No.", EntryNo);
    end;

    local procedure PrepareVendorUpgradeAfterCustomerUpgrade()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
    begin
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetInstallmentInvoiceGroupUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetInstallmentInvoiceGroupUpgradeTag());
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPurchaseInstallmentInvoiceGroupUpgradeTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(UpgradeTagDefinitions.GetPurchaseInstallmentInvoiceGroupUpgradeTag(), CompanyName());
    end;

    local procedure ClearVendorInvoiceGroups(PlanID: Guid)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        VendorLedgerEntry.SetRange("Installment Plan ID", PlanID);
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry."Invoice Entry No." := 0;
            VendorLedgerEntry.Modify();
            DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
            DetailedVendorLedgEntry.ModifyAll("Invoice Entry No.", 0);
        until VendorLedgerEntry.Next() = 0;
    end;

    local procedure VerifyVendorInvoiceGroups(PurchInvHeader: Record "Purch. Inv. Header")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        VendorLedgerEntry.SetRange("Installment Plan ID", PurchInvHeader."Installment Plan ID");
        Assert.AreEqual(3, VendorLedgerEntry.Count(), 'Backfill must preserve all vendor installments.');
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.TestField("Invoice Entry No.", PurchInvHeader."Vendor Ledger Entry No.");
            DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
            DetailedVendorLedgEntry.SetFilter("Invoice Entry No.", '<>%1', PurchInvHeader."Vendor Ledger Entry No.");
            Assert.IsTrue(DetailedVendorLedgEntry.IsEmpty(), 'All detailed entries must share the posted invoice anchor.');
            DetailedVendorLedgEntry.SetRange("Invoice Entry No.");
            DetailedVendorLedgEntry.CalcSums(Amount, "Amount (LCY)");
            VendorLedgerEntry.CalcFields("Original Amount", "Original Amt. (LCY)");
            Assert.AreEqual(VendorLedgerEntry."Original Amount", DetailedVendorLedgEntry.Amount, 'Backfill must not change vendor installment amounts.');
            Assert.AreEqual(VendorLedgerEntry."Original Amt. (LCY)", DetailedVendorLedgEntry."Amount (LCY)", 'Backfill must not change vendor installment LCY amounts.');
        until VendorLedgerEntry.Next() = 0;
    end;
}
