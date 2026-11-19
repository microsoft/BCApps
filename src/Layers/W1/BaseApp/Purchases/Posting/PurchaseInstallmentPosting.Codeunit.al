// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.Vendor;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;

codeunit 8847 "Purchase Installment Posting"
{
    Permissions = tabledata "Purchase Installment Plan" = RIMD,
                  tabledata "Purchase Installment Plan Line" = RIMD;

    var
        UnsupportedProducerErr: Label 'Global installments currently support full standalone purchase invoices only. Orders, receipt invoices, projects, subscription billing, service documents, and journals are not supported.';
        SourceErr: Label 'The installment posting source does not match the saved invoice and its owned draft plan.';
        ApplicationErr: Label 'Select individual installment entries using Applies-to ID. Applying an installment invoice by document number is not supported.';
        ReconciliationErr: Label 'The posted installment entries do not reconcile with the final invoice schedule.';
        TemporaryRecordErr: Label 'Installment posting calculation requires a temporary plan line record.';
        PostedPlanErr: Label 'Posted installment schedules cannot be changed or deleted.';
        CorrectionErr: Label 'Ledger reversal of installment invoices is not supported. Use a purchase credit memo or the invoice correction actions.';

    internal procedure CheckPurchasePosting(PurchaseHeader: Record "Purchase Header")
    var
        Plan: Record "Purchase Installment Plan";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if IsNullGuid(PurchaseHeader."Installment Plan ID") then
            exit;
        if PurchaseHeader.IsTemporary() or (PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Invoice) then
            Error(UnsupportedProducerErr);
        Plan.Get(PurchaseHeader."Installment Plan ID");
        Plan.TestField(Status, Plan.Status::Draft);
        if (Plan."Source SystemId" <> PurchaseHeader.SystemId) or
           (Plan."Source Record ID" <> PurchaseHeader.RecordId()) or
           (Plan."Payment Terms Code" <> PurchaseHeader."Payment Terms Code") or
           (Plan."Document Date" <> PurchaseHeader."Document Date") or
           (Plan."Currency Code" <> PurchaseHeader."Currency Code")
        then
            RaiseInternalError(SourceErr);
        PurchaseHeader.TestField("Applies-to Doc. No.", '');
        PurchaseHeader.TestField("Applies-to ID", '');
        PurchaseHeader.TestField("Bal. Account No.", '');
        PurchaseHeader.TestField("Prepayment %", 0);
        PurchaseHeader.TestField(Correction, false);
        PurchaseHeader.TestField("Tax Area Code", '');
        PurchaseHeader.TestField("Tax Liable", false);
        PurchaseHeader.TestField("VAT Base Discount %", 0);
        Vendor.Get(PurchaseHeader."Pay-to Vendor No.");
        Vendor.TestField("Application Method", Vendor."Application Method"::Manual);
        if PaymentMethod.Get(PurchaseHeader."Payment Method Code") then begin
            PaymentMethod.TestField("Bal. Account No.", '');
            PaymentMethod.TestField("Direct Debit", false);
        end;
        GLSetup.Get();
        GLSetup.TestField("Additional Reporting Currency", '');
        GLSetup.TestField("Pmt. Disc. Excl. VAT", false);
        GLSetup.TestField("Adjust for Payment Disc.", false);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                PurchaseLine.TestField("Receipt No.", '');
                PurchaseLine.TestField("Return Shipment No.", '');
                PurchaseLine.TestField("Job No.", '');
                PurchaseLine.TestField("Prepayment Line", false);
                PurchaseLine.TestField("Prepayment %", 0);
                PurchaseLine.TestField("Prepmt. Amt. Inv.", 0);
                PurchaseLine.TestField("Quantity Invoiced", 0);
                if PurchaseLine.Type <> PurchaseLine.Type::" " then begin
                    PurchaseLine.TestField("Qty. to Invoice", PurchaseLine.Quantity);
                    if not (PurchaseLine."VAT Calculation Type" in
                            [PurchaseLine."VAT Calculation Type"::"Normal VAT", PurchaseLine."VAT Calculation Type"::"No Taxable VAT"])
                    then
                        Error(UnsupportedProducerErr);
                    if VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group") then
                        VATPostingSetup.TestField("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
                end;
            until PurchaseLine.Next() = 0;
        OnAfterCheckPurchasePosting(PurchaseHeader);
    end;

    internal procedure PrepareJournalLine(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    var
        PurchInstallmentCorrection: Codeunit "Purch. Installment Correction";
    begin
        CheckPurchasePosting(PurchaseHeader);
        GenJournalLine."Installment Plan ID" := PurchaseHeader."Installment Plan ID";
        Clear(GenJournalLine."Purchase Invoice Source SystemId");
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice then
            GenJournalLine."Purchase Invoice Source SystemId" := PurchaseHeader.SystemId;
        PurchInstallmentCorrection.PrepareCreditApplication(PurchaseHeader, GenJournalLine);
    end;

    internal procedure CheckJournalLine(GenJournalLine: Record "Gen. Journal Line")
    var
        Rule: Record "Payment Term Installment";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmptyGuid: Guid;
        ApplyingVendorNo: Code[20];
    begin
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::Vendor then
            ApplyingVendorNo := GenJournalLine."Account No."
        else
            if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::Vendor then
                ApplyingVendorNo := GenJournalLine."Bal. Account No.";
        if (ApplyingVendorNo <> '') and (GenJournalLine."Applies-to Doc. No." <> '') then begin
            VendorLedgerEntry.SetRange("Vendor No.", ApplyingVendorNo);
            VendorLedgerEntry.SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
            VendorLedgerEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
            VendorLedgerEntry.SetFilter("Installment Plan ID", '<>%1', EmptyGuid);
            if not VendorLedgerEntry.IsEmpty() then
                Error(ApplicationErr);
        end;
        if ApplyingVendorNo = '' then
            exit;
        if not IsNullGuid(GenJournalLine."Installment Plan ID") then begin
            GenJournalLine.TestField("Account Type", GenJournalLine."Account Type"::Vendor);
            GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Invoice);
            GenJournalLine.TestField("System-Created Entry", true);
            GenJournalLine.TestField("Journal Template Name", '');
            GenJournalLine.TestField("Purchase Invoice Source SystemId");
            exit;
        end;
        if not ((GenJournalLine."Account Type" = GenJournalLine."Account Type"::Vendor) or
                (GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::Vendor)) or
           not (GenJournalLine."Document Type" in [GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo"])
        then
            exit;
        if GenJournalLine."Payment Terms Code" = '' then
            exit;
        Rule.SetRange("Payment Terms Code", GenJournalLine."Payment Terms Code");
        if Rule.IsEmpty() then
            exit;
        if IsPurchaseCreditMemoJournal(GenJournalLine) then
            exit;
        // Existing ordinary invoices do not acquire a plan when reusable setup is changed.
        if not IsNullGuid(GenJournalLine."Purchase Invoice Source SystemId") then
            if PurchaseHeader.GetBySystemId(GenJournalLine."Purchase Invoice Source SystemId") then
                if (GenJournalLine."Account Type" = GenJournalLine."Account Type"::Vendor) and
                   (GenJournalLine."Document Type" = GenJournalLine."Document Type"::Invoice) and
                   (PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice) and
                   IsNullGuid(PurchaseHeader."Installment Plan ID") and
                   (PurchaseHeader."Payment Terms Code" = GenJournalLine."Payment Terms Code") and
                   (PurchaseHeader."Pay-to Vendor No." = GenJournalLine."Account No.") and
                   GenJournalLine."System-Created Entry" and (GenJournalLine."Journal Template Name" = '')
                then
                    if PurchInvHeader.Get(GenJournalLine."Document No.") then
                        if IsNullGuid(PurchInvHeader."Installment Plan ID") and
                           (PurchInvHeader."Draft Invoice SystemId" = PurchaseHeader.SystemId)
                        then
                            exit;
        Error(UnsupportedProducerErr);
    end;

    local procedure IsPurchaseCreditMemoJournal(GenJournalLine: Record "Gen. Journal Line"): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        if (GenJournalLine."Account Type" <> GenJournalLine."Account Type"::Vendor) or
           (GenJournalLine."Document Type" <> GenJournalLine."Document Type"::"Credit Memo") or
           not GenJournalLine."System-Created Entry" or (GenJournalLine."Journal Template Name" <> '')
        then
            exit(false);
        if not PurchCrMemoHeader.Get(GenJournalLine."Document No.") then
            exit(false);
        if IsNullGuid(PurchCrMemoHeader."Draft Cr. Memo SystemId") then
            exit(false);
        if not PurchaseHeader.GetBySystemId(PurchCrMemoHeader."Draft Cr. Memo SystemId") then
            exit(false);
        exit((PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo") and
             IsNullGuid(PurchaseHeader."Installment Plan ID") and
             (PurchaseHeader."Payment Terms Code" = GenJournalLine."Payment Terms Code") and
             (PurchaseHeader."Pay-to Vendor No." = GenJournalLine."Account No.") and
             (PurchaseHeader."Currency Code" = GenJournalLine."Currency Code") and
             (PurchCrMemoHeader."Pay-to Vendor No." = GenJournalLine."Account No."));
    end;

    internal procedure PreparePosting(GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean; var TempPlanLine: Record "Purchase Installment Plan Line" temporary): Boolean
    var
        Plan: Record "Purchase Installment Plan";
        PlanLine: Record "Purchase Installment Plan Line";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        if IsNullGuid(GenJournalLine."Installment Plan ID") then
            exit(false);
        CheckTemporary(TempPlanLine);
        CheckJournalLine(GenJournalLine);
        if Balancing then
            Error(UnsupportedProducerErr);
        Plan.LockTable();
        Plan.Get(GenJournalLine."Installment Plan ID");
        Plan.TestField(Status, Plan.Status::Draft);
        if not PurchaseHeader.GetBySystemId(GenJournalLine."Purchase Invoice Source SystemId") then
            RaiseInternalError(SourceErr);
        if PurchaseHeader."Installment Plan ID" <> Plan.ID then
            RaiseInternalError(SourceErr);
        CheckPurchasePosting(PurchaseHeader);
        PurchInvHeader.Get(GenJournalLine."Document No.");
        PurchInvHeader.TestField("Installment Plan ID", Plan.ID);
        PurchInvHeader.TestField("Draft Invoice SystemId", PurchaseHeader.SystemId);
        GenJournalLine.TestField("Account No.", PurchaseHeader."Pay-to Vendor No.");
        GenJournalLine.TestField("Currency Code", PurchaseHeader."Currency Code");
        GenJournalLine.TestField("Document Date", PurchaseHeader."Document Date");
        GenJournalLine.TestField("Posting Date", PurchaseHeader."Posting Date");
        GenJournalLine.TestField("Payment Terms Code", PurchaseHeader."Payment Terms Code");
        GenJournalLine.TestField("Due Date", PurchaseHeader."Due Date");
        GenJournalLine.TestField("Additional-Currency Posting", GenJournalLine."Additional-Currency Posting"::None);
        GenJournalLine.TestField("Applies-to Doc. No.", '');
        GenJournalLine.TestField("Applies-to ID", '');
        GenJournalLine.TestField("Bal. Account No.", '');
        GenJournalLine.TestField(Prepayment, false);
        GenJournalLine.TestField(Correction, false);
        GenJournalLine.TestField("Deferral Code", '');
        GenJournalLine.TestField("VAT Amount", 0);
        GenJournalLine.TestField("VAT Amount (LCY)", 0);
        GenJournalLine.TestField("VAT Base Amount", 0);
        GenJournalLine.TestField("VAT Base Amount (LCY)", 0);
        GenJournalLine.TestField("Source Curr. VAT Amount", 0);
        GenJournalLine.TestField("Source Curr. VAT Base Amount", 0);
        GenJournalLine.TestField("Payment Discount %", 0);
        GenJournalLine.TestField("Pmt. Discount Date", 0D);
        GenJournalLine.TestField("Orig. Pmt. Disc. Possible", 0);
        GenJournalLine.TestField("Orig. Pmt. Disc. Possible(LCY)", 0);
        GenJournalLine.TestField("Source Currency Code", GenJournalLine."Currency Code");
        TempPlanLine.Reset();
        TempPlanLine.DeleteAll();
        PlanLine.SetRange("Plan ID", Plan.ID);
        if not PlanLine.FindSet() then
            RaiseInternalError(SourceErr);
        repeat
            TempPlanLine.Init();
            TempPlanLine."Plan ID" := Plan.ID;
            TempPlanLine.CopyRulesFromPlanLine(PlanLine);
            TempPlanLine.Insert();
        until PlanLine.Next() = 0;
        CalculatePostingLines(GenJournalLine, TempPlanLine);
        TempPlanLine.FindSet();
        exit(true);
    end;

    internal procedure CalculatePostingLines(GenJournalLine: Record "Gen. Journal Line"; var TempPlanLine: Record "Purchase Installment Plan Line" temporary)
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        TempCalculationLine: Record "Installment Calculation Line" temporary;
        InstallmentCalculation: Codeunit "Installment Calculation";
        RemainingSourceAmount: Decimal;
        RemainingPurchaseLCY: Decimal;
        RemainingInvDiscountLCY: Decimal;
        Amount: Decimal;
        AmountLCY: Decimal;
        LastLineNo: Integer;
        LastLine: Boolean;
    begin
        CheckTemporary(TempPlanLine);
        if TempPlanLine.IsEmpty() then
            RaiseInternalError(SourceErr);
        GLSetup.Get();
        Currency.Initialize(GenJournalLine."Currency Code", true);
        Amount := -GenJournalLine.Amount;
        AmountLCY := -GenJournalLine."Amount (LCY)";
        CopyToCalculationLines(TempPlanLine, TempCalculationLine);
        InstallmentCalculation.Calculate(
            TempCalculationLine, GenJournalLine."Document Date", GenJournalLine."Posting Date", Amount, AmountLCY,
            Currency."Amount Rounding Precision", GLSetup."Amount Rounding Precision", GLSetup."Payment Discount Grace Period");
        CopyFromCalculationLines(TempCalculationLine, TempPlanLine);
        TempPlanLine.FindLast();
        LastLineNo := TempPlanLine."Line No.";
        RemainingSourceAmount := GenJournalLine."Source Currency Amount";
        RemainingPurchaseLCY := GenJournalLine."Sales/Purch. (LCY)";
        RemainingInvDiscountLCY := GenJournalLine."Inv. Discount (LCY)";
        TempPlanLine.FindSet();
        repeat
            LastLine := TempPlanLine."Line No." = LastLineNo;
            TempPlanLine."Source Currency Amount" := Allocate(
                GenJournalLine."Source Currency Amount", RemainingSourceAmount, TempPlanLine."Payment %", LastLine, Currency."Amount Rounding Precision");
            TempPlanLine."Purchase (LCY)" := Allocate(
                GenJournalLine."Sales/Purch. (LCY)", RemainingPurchaseLCY, TempPlanLine."Payment %", LastLine, GLSetup."Amount Rounding Precision");
            TempPlanLine."Inv. Discount (LCY)" := Allocate(
                GenJournalLine."Inv. Discount (LCY)", RemainingInvDiscountLCY, TempPlanLine."Payment %", LastLine, GLSetup."Amount Rounding Precision");
            TempPlanLine.Modify();
        until TempPlanLine.Next() = 0;
    end;

    internal procedure SetJournalLine(TotalGenJournalLine: Record "Gen. Journal Line"; PlanLine: Record "Purchase Installment Plan Line"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine := TotalGenJournalLine;
        GenJournalLine.Amount := -PlanLine.Amount;
        GenJournalLine."Amount (LCY)" := -PlanLine."Amount (LCY)";
        GenJournalLine."Source Currency Amount" := PlanLine."Source Currency Amount";
        GenJournalLine."Sales/Purch. (LCY)" := PlanLine."Purchase (LCY)";
        GenJournalLine."Inv. Discount (LCY)" := PlanLine."Inv. Discount (LCY)";
        GenJournalLine."Due Date" := PlanLine."Due Date";
        GenJournalLine."Payment Discount %" := PlanLine."Discount %";
        GenJournalLine."Pmt. Discount Date" := PlanLine."Pmt. Discount Date";
        GenJournalLine."Debit Amount" := 0;
        GenJournalLine."Credit Amount" := PlanLine.Amount;
    end;

    internal procedure RecordPostedLine(PlanLine: Record "Purchase Installment Plan Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; InstallmentCount: Integer)
    var
        SavedPlanLine: Record "Purchase Installment Plan Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.TestField("Installment Plan ID", PlanLine."Plan ID");
        VendorLedgerEntry.TestField("Installment No.", PlanLine."Installment No.");
        VendorLedgerEntry.TestField("No. of Installments", InstallmentCount);
        VendorLedgerEntry.TestField("Due Date", PlanLine."Due Date");
        VendorLedgerEntry.TestField("Pmt. Discount Date", PlanLine."Pmt. Discount Date");
        VendorLedgerEntry.TestField("Original Pmt. Disc. Possible", PlanLine."Original Pmt. Disc. Possible");
        VendorLedgerEntry.TestField("Purchase (LCY)", PlanLine."Purchase (LCY)");
        VendorLedgerEntry.TestField("Inv. Discount (LCY)", PlanLine."Inv. Discount (LCY)");
        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        if DetailedVendorLedgEntry.Count() <> 1 then
            RaiseInternalError(ReconciliationErr);
        DetailedVendorLedgEntry.FindFirst();
        DetailedVendorLedgEntry.TestField("Entry Type", DetailedVendorLedgEntry."Entry Type"::"Initial Entry");
        DetailedVendorLedgEntry.TestField(Amount, -PlanLine.Amount);
        DetailedVendorLedgEntry.TestField("Amount (LCY)", -PlanLine."Amount (LCY)");
        DetailedVendorLedgEntry.TestField("Initial Entry Due Date", PlanLine."Due Date");
        SavedPlanLine.Get(PlanLine."Plan ID", PlanLine."Line No.");
        SavedPlanLine.TestField("Vendor Ledger Entry No.", 0);
        SavedPlanLine := PlanLine;
        SavedPlanLine."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        SavedPlanLine.Modify(true);
    end;

    internal procedure CompletePosting(GenJournalLine: Record "Gen. Journal Line"; InstallmentCount: Integer)
    var
        Plan: Record "Purchase Installment Plan";
        PlanLine: Record "Purchase Installment Plan Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInstallmentHistory: Codeunit "Purchase Installment History";
    begin
        Plan.Get(GenJournalLine."Installment Plan ID");
        Plan.TestField(Status, Plan.Status::Draft);
        PlanLine.SetRange("Plan ID", Plan.ID);
        if PlanLine.Count() <> InstallmentCount then
            RaiseInternalError(ReconciliationErr);
        PlanLine.SetRange("Vendor Ledger Entry No.", 0);
        if not PlanLine.IsEmpty() then
            RaiseInternalError(ReconciliationErr);
        PlanLine.SetRange("Vendor Ledger Entry No.");
        PlanLine.CalcSums(Amount, "Amount (LCY)", "Source Currency Amount", "Purchase (LCY)", "Inv. Discount (LCY)");
        if (PlanLine.Amount <> -GenJournalLine.Amount) or (PlanLine."Amount (LCY)" <> -GenJournalLine."Amount (LCY)") or
           (PlanLine."Source Currency Amount" <> GenJournalLine."Source Currency Amount") or
           (PlanLine."Purchase (LCY)" <> GenJournalLine."Sales/Purch. (LCY)") or
           (PlanLine."Inv. Discount (LCY)" <> GenJournalLine."Inv. Discount (LCY)")
        then
            RaiseInternalError(ReconciliationErr);
        PurchInvHeader.Get(GenJournalLine."Document No.");
        PurchInvHeader.TestField("Installment Plan ID", Plan.ID);
        PlanLine.SetCurrentKey("Plan ID", "Installment No.");
        PlanLine.FindLast();
        PurchaseInstallmentHistory.SetInvoiceGroup(Plan.ID, PlanLine."Vendor Ledger Entry No.");
        Plan.Status := Plan.Status::Posted;
        Plan."Posted Invoice No." := PurchInvHeader."No.";
        Plan."Posted Invoice SystemId" := PurchInvHeader.SystemId;
        Plan."Posting Date" := GenJournalLine."Posting Date";
        Plan.Amount := -GenJournalLine.Amount;
        Plan."Amount (LCY)" := -GenJournalLine."Amount (LCY)";
        // Source identity remains immutable provenance; posted ownership uses the posted invoice SystemId.
        Plan.Modify(true);
    end;

    internal procedure GetFinalVendorEntry(PurchInvHeader: Record "Purch. Inv. Header"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        Plan: Record "Purchase Installment Plan";
        PlanLine: Record "Purchase Installment Plan Line";
    begin
        Plan.Get(PurchInvHeader."Installment Plan ID");
        Plan.TestField(Status, Plan.Status::Posted);
        Plan.TestField("Posted Invoice SystemId", PurchInvHeader.SystemId);
        PlanLine.SetCurrentKey("Plan ID", "Installment No.");
        PlanLine.SetRange("Plan ID", Plan.ID);
        PlanLine.FindLast();
        VendorLedgerEntry.Get(PlanLine."Vendor Ledger Entry No.");
        VendorLedgerEntry.TestField("Installment Plan ID", Plan.ID);
        VendorLedgerEntry.TestField("Installment No.", PlanLine."Installment No.");
        VendorLedgerEntry.TestField("Document No.", PurchInvHeader."No.");
        VendorLedgerEntry.TestField("Vendor No.", PurchInvHeader."Pay-to Vendor No.");
    end;

    local procedure RaiseInternalError(ErrorMessage: Text)
    var
        InternalErrorInfo: ErrorInfo;
    begin
        InternalErrorInfo.DataClassification := DataClassification::SystemMetadata;
        InternalErrorInfo.ErrorType := ErrorType::Internal;
        InternalErrorInfo.Verbosity := Verbosity::Error;
        InternalErrorInfo.Message := ErrorMessage;
        Error(InternalErrorInfo);
    end;

    local procedure Allocate(Total: Decimal; var Remaining: Decimal; Percentage: Decimal; LastLine: Boolean; Precision: Decimal) Amount: Decimal
    begin
        if LastLine then
            Amount := Remaining
        else
            Amount := Round(Total * Percentage / 100, Precision);
        Remaining -= Amount;
    end;

    local procedure CheckTemporary(var TempPlanLine: Record "Purchase Installment Plan Line" temporary)
    begin
        if not TempPlanLine.IsTemporary() then
            Error(TemporaryRecordErr);
    end;

    local procedure CopyToCalculationLines(var TempPlanLine: Record "Purchase Installment Plan Line" temporary; var TempCalculationLine: Record "Installment Calculation Line" temporary)
    begin
        TempCalculationLine.Reset();
        TempCalculationLine.DeleteAll();
        TempPlanLine.Reset();
        if TempPlanLine.FindSet() then
            repeat
                TempCalculationLine.Init();
                TempPlanLine.CopyToCalculationLine(TempCalculationLine);
                TempCalculationLine.Insert();
            until TempPlanLine.Next() = 0;
    end;

    local procedure CopyFromCalculationLines(var TempCalculationLine: Record "Installment Calculation Line" temporary; var TempPlanLine: Record "Purchase Installment Plan Line" temporary)
    begin
        TempPlanLine.Reset();
        TempPlanLine.DeleteAll();
        TempCalculationLine.Reset();
        if TempCalculationLine.FindSet() then
            repeat
                TempPlanLine.Init();
                TempPlanLine.CopyFromCalculationLine(TempCalculationLine);
                TempPlanLine.Insert();
            until TempCalculationLine.Next() = 0;
    end;

    local procedure CheckPlanEditable(PlanID: Guid)
    var
        Plan: Record "Purchase Installment Plan";
    begin
        if Plan.Get(PlanID) then
            if Plan.Status = Plan.Status::Posted then
                Error(PostedPlanErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Installment Plan", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CheckPlanModification(var Rec: Record "Purchase Installment Plan")
    begin
        if not Rec.IsTemporary() then
            CheckPlanEditable(Rec.ID);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Installment Plan", 'OnBeforeRenameEvent', '', false, false)]
    local procedure CheckPlanRenaming(var Rec: Record "Purchase Installment Plan")
    var
        SavedPlan: Record "Purchase Installment Plan";
    begin
        if Rec.IsTemporary() then
            exit;
        if SavedPlan.GetBySystemId(Rec.SystemId) then
            CheckPlanEditable(SavedPlan.ID);
        CheckPlanEditable(Rec.ID);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Installment Plan", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure CheckPlanDeletion(var Rec: Record "Purchase Installment Plan")
    begin
        if not Rec.IsTemporary() then
            CheckPlanEditable(Rec.ID);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Installment Plan Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure CheckLineInsertion(var Rec: Record "Purchase Installment Plan Line")
    begin
        if not Rec.IsTemporary() then
            CheckPlanEditable(Rec."Plan ID");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Installment Plan Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CheckLineModification(var Rec: Record "Purchase Installment Plan Line")
    var
        SavedPlanLine: Record "Purchase Installment Plan Line";
    begin
        if Rec.IsTemporary() then
            exit;
        if SavedPlanLine.GetBySystemId(Rec.SystemId) then
            CheckPlanEditable(SavedPlanLine."Plan ID");
        CheckPlanEditable(Rec."Plan ID");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Installment Plan Line", 'OnBeforeRenameEvent', '', false, false)]
    local procedure CheckLineRenaming(var Rec: Record "Purchase Installment Plan Line")
    begin
        CheckLineModification(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Installment Plan Line", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure CheckLineDeletion(var Rec: Record "Purchase Installment Plan Line")
    begin
        if not Rec.IsTemporary() then
            CheckPlanEditable(Rec."Plan ID");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reversal Entry", 'OnBeforeCheckVend', '', false, false)]
    local procedure CheckVendorReversal(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        if not IsNullGuid(VendLedgEntry."Installment Plan ID") then
            Error(CorrectionErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPurchasePosting(PurchaseHeader: Record "Purchase Header")
    begin
    end;
}
