// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TDS.TDSOnPayments;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.TaxBase;
using Microsoft.Finance.TDS.TDSBase;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.Payables;

codeunit 18771 "TDS Check Void Handler"
{
    Permissions = tabledata "Bank Account Ledger Entry" = rm,
                  tabledata "Check Ledger Entry" = rm,
                  tabledata "Vendor Ledger Entry" = rm;

    var
        BankAcc: Record "Bank Account";
        BankAccLedgEntry2: Record "Bank Account Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        AppliesIDCounter: Integer;
        VoidingCheckMsg: Label 'Voiding check %1.', Comment = '%1 = Check No.';
        TDSReversalDescTxt: Label 'TDS reversal for voided check %1.', Comment = '%1 = Check No.';
        VoidingCheckErr: Label 'You cannot Financially Void checks posted in a non-balancing transaction.';
        BalAccTypeNotSupportedErr: Label 'Financial void with TDS is supported only when the Bal. Account Type on the check is Vendor. Use the standard void process for this check.';
        NoAppliedEntryErr: Label 'Cannot find an applied entry within the specified filter.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::CheckManagement, 'OnBeforeFinancialVoidCheck', '', false, false)]
    local procedure OnBeforeFinancialVoidCheck(var CheckLedgerEntry: Record "Check Ledger Entry"; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        if not HasTDSEntries(CheckLedgerEntry."Document No.") then
            exit;

        FinancialVoidCheckWithTDS(CheckLedgerEntry);
        IsHandled := true;
    end;

    local procedure HasTDSEntries(DocumentNo: Code[20]): Boolean
    var
        TDSEntry: Record "TDS Entry";
    begin
        if DocumentNo = '' then
            exit(false);
        TDSEntry.SetRange("Document No.", DocumentNo);
        exit(not TDSEntry.IsEmpty());
    end;

    local procedure FinancialVoidCheckWithTDS(var CheckLedgEntry: Record "Check Ledger Entry")
    var
        ConfirmFinancialVoid: Page "Confirm Financial Void";
        VoidDate: Date;
    begin
        FinancialVoidCheckPreValidation(CheckLedgEntry);

        if CheckLedgEntry."Bal. Account Type" <> CheckLedgEntry."Bal. Account Type"::Vendor then
            Error(BalAccTypeNotSupportedErr);

        Clear(ConfirmFinancialVoid);
        ConfirmFinancialVoid.SetCheckLedgerEntry(CheckLedgEntry);
        if ConfirmFinancialVoid.RunModal() <> Action::Yes then
            exit;

        VoidDate := ConfirmFinancialVoid.GetVoidDate();

        PostBankReversal(CheckLedgEntry, VoidDate);
        PostTDSPayableReversal(CheckLedgEntry, VoidDate);
        PostVendorReversal(CheckLedgEntry, VoidDate, ConfirmFinancialVoid.GetVoidType());
        ReverseTDSEntries(CheckLedgEntry."Document No.");

        if VoidDate = CheckLedgEntry."Check Date" then begin
            BankAccLedgEntry2.Open := false;
            BankAccLedgEntry2."Remaining Amount" := 0;
            BankAccLedgEntry2."Statement Status" := BankAccLedgEntry2."Statement Status"::Closed;
            BankAccLedgEntry2.Modify();
        end;

        MarkCheckEntriesVoid(CheckLedgEntry, VoidDate);

        Commit();
        UpdateAnalysisView.UpdateAll(0, true);
    end;

    local procedure FinancialVoidCheckPreValidation(var CheckLedgEntry: Record "Check Ledger Entry")
    var
        GLEntry: Record "G/L Entry";
        TransactionBalance: Decimal;
    begin
        CheckLedgEntry.TestField("Entry Status", CheckLedgEntry."Entry Status"::Posted);
        CheckLedgEntry.TestField("Statement Status", CheckLedgEntry."Statement Status"::Open);
        CheckLedgEntry.TestField("Bal. Account No.");
        BankAcc.Get(CheckLedgEntry."Bank Account No.");
        BankAccLedgEntry2.Get(CheckLedgEntry."Bank Account Ledger Entry No.");
        SourceCodeSetup.Get();

        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
        GLEntry.SetRange("Document No.", BankAccLedgEntry2."Document No.");
        GLEntry.CalcSums(Amount);
        TransactionBalance := GLEntry.Amount;
        if TransactionBalance <> 0 then
            Error(VoidingCheckErr);
    end;

    local procedure PostBankReversal(CheckLedgEntry: Record "Check Ledger Entry"; VoidDate: Date)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.Init();
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Financial Void" := true;
        GenJnlLine."Document Type" := CheckLedgEntry."Document Type";
        GenJnlLine."Document No." := CheckLedgEntry."Document No.";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Bank Account";
        GenJnlLine."Posting Date" := VoidDate;
        GenJnlLine."VAT Reporting Date" := VoidDate;
        GenJnlLine.Validate("Account No.", CheckLedgEntry."Bank Account No.");
        GenJnlLine.Description := StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No.");
        GenJnlLine.Validate(Amount, -BankAccLedgEntry2.Amount);
        GenJnlLine."Shortcut Dimension 1 Code" := BankAccLedgEntry2."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := BankAccLedgEntry2."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := BankAccLedgEntry2."Dimension Set ID";
        GenJnlLine."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
        GenJnlLine."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
        GenJnlLine."Source Code" := SourceCodeSetup."Financially Voided Check";
        GenJnlLine."Allow Zero-Amount Posting" := true;
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    local procedure PostTDSPayableReversal(CheckLedgEntry: Record "Check Ledger Entry"; VoidDate: Date)
    var
        GLEntry: Record "G/L Entry";
        TDSAccountToSection: Dictionary of [Code[20], Code[10]];
        AccountAmounts: Dictionary of [Code[20], Decimal];
        AccountList: List of [Code[20]];
        TDSAccountNo: Code[20];
        AmountToReverse: Decimal;
        Running: Decimal;
    begin
        BuildTDSAccountSectionMap(CheckLedgEntry."Document No.", TDSAccountToSection);
        if TDSAccountToSection.Count() = 0 then
            exit;

        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
        GLEntry.SetRange("Document No.", BankAccLedgEntry2."Document No.");
        GLEntry.SetRange("Posting Date", BankAccLedgEntry2."Posting Date");
        if GLEntry.FindSet() then
            repeat
                if TDSAccountToSection.ContainsKey(GLEntry."G/L Account No.") then
                    if AccountAmounts.ContainsKey(GLEntry."G/L Account No.") then begin
                        Running := AccountAmounts.Get(GLEntry."G/L Account No.");
                        AccountAmounts.Set(GLEntry."G/L Account No.", Running + GLEntry.Amount);
                    end else
                        AccountAmounts.Add(GLEntry."G/L Account No.", GLEntry.Amount);
            until GLEntry.Next() = 0;

        AccountList := AccountAmounts.Keys();
        foreach TDSAccountNo in AccountList do begin
            AmountToReverse := -AccountAmounts.Get(TDSAccountNo);
            if AmountToReverse <> 0 then
                PostTDSReversalGLLine(CheckLedgEntry, VoidDate, TDSAccountNo, AmountToReverse);
        end;
    end;

    local procedure BuildTDSAccountSectionMap(DocumentNo: Code[20]; var TDSAccountToSection: Dictionary of [Code[20], Code[10]])
    var
        TDSEntry: Record "TDS Entry";
        TDSAccountNo: Code[20];
    begin
        Clear(TDSAccountToSection);
        TDSEntry.SetRange("Document No.", DocumentNo);
        if not TDSEntry.FindSet() then
            exit;
        repeat
            if TDSEntry.Section <> '' then begin
                TDSAccountNo := GetTDSPayableAccount(TDSEntry.Section, TDSEntry."Posting Date");
                if (TDSAccountNo <> '') and not TDSAccountToSection.ContainsKey(TDSAccountNo) then
                    TDSAccountToSection.Add(TDSAccountNo, TDSEntry.Section);
            end;
        until TDSEntry.Next() = 0;
    end;

    local procedure PostTDSReversalGLLine(CheckLedgEntry: Record "Check Ledger Entry"; VoidDate: Date; TDSAccountNo: Code[20]; Amount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.Init();
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Financial Void" := true;
        GenJnlLine."Document Type" := CheckLedgEntry."Document Type";
        GenJnlLine."Document No." := CheckLedgEntry."Document No.";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine."Posting Date" := VoidDate;
        GenJnlLine."VAT Reporting Date" := VoidDate;
        GenJnlLine.Validate("Account No.", TDSAccountNo);
        GenJnlLine.Description := StrSubstNo(TDSReversalDescTxt, CheckLedgEntry."Check No.");
        GenJnlLine.Validate(Amount, Amount);
        GenJnlLine."Shortcut Dimension 1 Code" := BankAccLedgEntry2."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := BankAccLedgEntry2."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := BankAccLedgEntry2."Dimension Set ID";
        GenJnlLine."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
        GenJnlLine."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
        GenJnlLine."Source Code" := SourceCodeSetup."Financially Voided Check";
        GenJnlLine."Allow Zero-Amount Posting" := true;
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    local procedure PostVendorReversal(CheckLedgEntry: Record "Check Ledger Entry"; VoidDate: Date; VoidType: Option)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        UnappliedAppliesToID: Code[50];
    begin
        if VoidType = 0 then
            if UnApplyVendorInvoices(CheckLedgEntry, VoidDate) then
                UnappliedAppliesToID := CheckLedgEntry."Document No.";

        VendorLedgerEntry.SetCurrentKey("Transaction No.");
        VendorLedgerEntry.SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
        VendorLedgerEntry.SetRange("Document No.", BankAccLedgEntry2."Document No.");
        VendorLedgerEntry.SetRange("Posting Date", BankAccLedgEntry2."Posting Date");
        if VendorLedgerEntry.FindSet() then
            repeat
                PostSingleVendorReversalLine(CheckLedgEntry, VoidDate, VendorLedgerEntry, UnappliedAppliesToID);
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure PostSingleVendorReversalLine(CheckLedgEntry: Record "Check Ledger Entry"; VoidDate: Date; VendorLedgerEntry: Record "Vendor Ledger Entry"; UnappliedAppliesToID: Code[50])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        VendorLedgerEntry.CalcFields("Original Amount");

        GenJnlLine.Init();
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Financial Void" := true;
        GenJnlLine."Document Type" := CheckLedgEntry."Document Type";
        GenJnlLine."Document No." := CheckLedgEntry."Document No.";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine."Posting Date" := VoidDate;
        GenJnlLine."VAT Reporting Date" := VoidDate;
        GenJnlLine.Validate("Account No.", CheckLedgEntry."Bal. Account No.");
        GenJnlLine.Description := StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No.");
        if UnappliedAppliesToID <> '' then
            GenJnlLine."Applies-to ID" := UnappliedAppliesToID;
        GenJnlLine.Validate(Amount, -VendorLedgerEntry."Original Amount");
        GenJnlLine.Validate("Currency Code", VendorLedgerEntry."Currency Code");
        MakeAppliesID(GenJnlLine."Applies-to ID", CheckLedgEntry."Document No.");
        GenJnlLine."Shortcut Dimension 1 Code" := VendorLedgerEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := VendorLedgerEntry."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := VendorLedgerEntry."Dimension Set ID";
        GenJnlLine."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
        GenJnlLine."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
        if GenJnlLine."Posting Group" <> VendorLedgerEntry."Vendor Posting Group" then
            GenJnlLine."Posting Group" := VendorLedgerEntry."Vendor Posting Group";
        GenJnlLine."Source Code" := SourceCodeSetup."Financially Voided Check";
        GenJnlLine."Source Currency Code" := VendorLedgerEntry."Currency Code";
        GenJnlLine."Allow Zero-Amount Posting" := true;
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    local procedure UnApplyVendorInvoices(CheckLedgEntry: Record "Check Ledger Entry"; VoidDate: Date): Boolean
    var
        OrigPaymentVendorLedgerEntry: Record "Vendor Ledger Entry";
        PayDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        UnapplyGenJnlLine: Record "Gen. Journal Line";
        AppliesID: Code[50];
    begin
        if CheckLedgEntry."Bal. Account Type" <> CheckLedgEntry."Bal. Account Type"::Vendor then
            exit(false);

        OrigPaymentVendorLedgerEntry.SetCurrentKey("Transaction No.");
        OrigPaymentVendorLedgerEntry.SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
        OrigPaymentVendorLedgerEntry.SetRange("Document No.", BankAccLedgEntry2."Document No.");
        OrigPaymentVendorLedgerEntry.SetRange("Posting Date", BankAccLedgEntry2."Posting Date");
        if not OrigPaymentVendorLedgerEntry.FindFirst() then
            exit(false);

        AppliesID := CheckLedgEntry."Document No.";
        PayDetailedVendorLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
        PayDetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", OrigPaymentVendorLedgerEntry."Entry No.");
        PayDetailedVendorLedgEntry.SetRange(Unapplied, false);
        PayDetailedVendorLedgEntry.SetFilter("Applied Vend. Ledger Entry No.", '<>%1', 0);
        PayDetailedVendorLedgEntry.SetRange("Entry Type", PayDetailedVendorLedgEntry."Entry Type"::Application);
        if not PayDetailedVendorLedgEntry.FindSet() then
            Error(NoAppliedEntryErr);

        UnapplyGenJnlLine."Document No." := OrigPaymentVendorLedgerEntry."Document No.";
        UnapplyGenJnlLine."Posting Date" := VoidDate;
        UnapplyGenJnlLine."Account Type" := UnapplyGenJnlLine."Account Type"::Vendor;
        UnapplyGenJnlLine."Account No." := OrigPaymentVendorLedgerEntry."Vendor No.";
        UnapplyGenJnlLine.Correction := true;
        UnapplyGenJnlLine.Description := StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No.");
        UnapplyGenJnlLine."Shortcut Dimension 1 Code" := OrigPaymentVendorLedgerEntry."Global Dimension 1 Code";
        UnapplyGenJnlLine."Shortcut Dimension 2 Code" := OrigPaymentVendorLedgerEntry."Global Dimension 2 Code";
        UnapplyGenJnlLine."Posting Group" := OrigPaymentVendorLedgerEntry."Vendor Posting Group";
        UnapplyGenJnlLine."Source Type" := UnapplyGenJnlLine."Source Type"::Vendor;
        UnapplyGenJnlLine."Source No." := OrigPaymentVendorLedgerEntry."Vendor No.";
        UnapplyGenJnlLine."Source Code" := SourceCodeSetup."Financially Voided Check";
        UnapplyGenJnlLine."Source Currency Code" := OrigPaymentVendorLedgerEntry."Currency Code";
        UnapplyGenJnlLine."System-Created Entry" := true;
        UnapplyGenJnlLine."Financial Void" := true;
        GenJnlPostLine.UnapplyVendLedgEntry(UnapplyGenJnlLine, PayDetailedVendorLedgEntry);

        if OrigPaymentVendorLedgerEntry.FindSet() then
            repeat
                MakeAppliesID(AppliesID, CheckLedgEntry."Document No.");
                OrigPaymentVendorLedgerEntry."Applies-to ID" := AppliesID;
                OrigPaymentVendorLedgerEntry.CalcFields("Remaining Amount");
                OrigPaymentVendorLedgerEntry."Amount to Apply" := OrigPaymentVendorLedgerEntry."Remaining Amount";
                OrigPaymentVendorLedgerEntry."Accepted Pmt. Disc. Tolerance" := false;
                OrigPaymentVendorLedgerEntry."Accepted Payment Tolerance" := 0;
                OrigPaymentVendorLedgerEntry.Modify();
            until OrigPaymentVendorLedgerEntry.Next() = 0;
        exit(true);
    end;

    local procedure ReverseTDSEntries(DocumentNo: Code[20])
    var
        TDSEntry: Record "TDS Entry";
        TaxBaseLibrary: Codeunit "Tax Base Library";
    begin
        TDSEntry.SetRange("Document No.", DocumentNo);
        TDSEntry.SetRange(Reversed, false);
        TDSEntry.SetFilter("Total TDS Including SHE CESS", '<>%1', 0);
        if not TDSEntry.FindSet() then
            exit;
        repeat
            TaxBaseLibrary.ReverseTDSEntry(TDSEntry."Entry No.", GenJnlPostLine.GetNextTransactionNo());
        until TDSEntry.Next() = 0;
    end;

    local procedure MarkCheckEntriesVoid(var OriginalCheckLedgerEntry: Record "Check Ledger Entry"; VoidDate: Date)
    var
        RelatedCheckLedgerEntry: Record "Check Ledger Entry";
        RelatedCheckLedgerEntry2: Record "Check Ledger Entry";
    begin
        RelatedCheckLedgerEntry.Reset();
        RelatedCheckLedgerEntry.SetCurrentKey("Bank Account No.", "Entry Status", "Check No.");
        RelatedCheckLedgerEntry.SetRange("Bank Account No.", OriginalCheckLedgerEntry."Bank Account No.");
        RelatedCheckLedgerEntry.SetRange("Entry Status", OriginalCheckLedgerEntry."Entry Status"::Posted);
        RelatedCheckLedgerEntry.SetRange("Statement Status", OriginalCheckLedgerEntry."Statement Status"::Open);
        RelatedCheckLedgerEntry.SetRange("Check No.", OriginalCheckLedgerEntry."Check No.");
        RelatedCheckLedgerEntry.SetRange("Check Date", OriginalCheckLedgerEntry."Check Date");
        RelatedCheckLedgerEntry.SetFilter("Entry No.", '<>%1', OriginalCheckLedgerEntry."Entry No.");
        if RelatedCheckLedgerEntry.FindSet() then
            repeat
                RelatedCheckLedgerEntry2 := RelatedCheckLedgerEntry;
                RelatedCheckLedgerEntry2."Original Entry Status" := RelatedCheckLedgerEntry."Entry Status";
                RelatedCheckLedgerEntry2."Entry Status" := RelatedCheckLedgerEntry."Entry Status"::"Financially Voided";
                RelatedCheckLedgerEntry2."Positive Pay Exported" := false;
                if VoidDate = OriginalCheckLedgerEntry."Check Date" then begin
                    RelatedCheckLedgerEntry2.Open := false;
                    RelatedCheckLedgerEntry2."Statement Status" := RelatedCheckLedgerEntry2."Statement Status"::Closed;
                end;
                RelatedCheckLedgerEntry2.Modify();
            until RelatedCheckLedgerEntry.Next() = 0;

        OriginalCheckLedgerEntry."Original Entry Status" := OriginalCheckLedgerEntry."Entry Status";
        OriginalCheckLedgerEntry."Entry Status" := OriginalCheckLedgerEntry."Entry Status"::"Financially Voided";
        OriginalCheckLedgerEntry."Positive Pay Exported" := false;
        if VoidDate = OriginalCheckLedgerEntry."Check Date" then begin
            OriginalCheckLedgerEntry.Open := false;
            OriginalCheckLedgerEntry."Statement Status" := OriginalCheckLedgerEntry."Statement Status"::Closed;
        end;
        OriginalCheckLedgerEntry.Modify();
    end;

    local procedure MakeAppliesID(var AppliesID: Code[50]; CheckDocNo: Code[20])
    begin
        if AppliesID = '' then
            exit;
        if AppliesID = CheckDocNo then
            AppliesIDCounter := 0;
        AppliesIDCounter := AppliesIDCounter + 1;
        AppliesID := CopyStr(Format(AppliesIDCounter) + CheckDocNo, 1, MaxStrLen(AppliesID));
    end;

    local procedure GetTDSPayableAccount(SectionCode: Code[10]; PostingDate: Date): Code[20]
    var
        TDSPostingSetup: Record "TDS Posting Setup";
    begin
        if SectionCode = '' then
            exit('');
        TDSPostingSetup.SetRange("TDS Section", SectionCode);
        TDSPostingSetup.SetRange("Effective Date", 0D, PostingDate);
        if TDSPostingSetup.FindLast() then
            exit(TDSPostingSetup."TDS Account");
        exit('');
    end;
}
