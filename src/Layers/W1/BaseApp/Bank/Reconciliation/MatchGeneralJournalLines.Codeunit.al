// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

codeunit 1250 "Match General Journal Lines"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.Copy(Rec);
        Code(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        Rec := GenJnlLine;

        OnAfterOnRun(Rec);
    end;

    var
#pragma warning disable AA0470
        MatchSummaryMsg: Label '%1 payment lines out of %2 are matched.\\';
        MissingMatchMsg: Label 'Text shorter than %1 characters cannot be matched.';
#pragma warning restore AA0470
        ProgressBarMsg: Label 'Please wait while the operation is being completed.';
        MatchLengthTreshold: Integer;
        NormalizingFactor: Integer;

    procedure "Code"(TemplateName: Code[10]; BatchName: Code[10])
    var
        TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary;
        GenJournalBatch: Record "Gen. Journal Batch";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        Window: Dialog;
    begin
        GenJournalBatch.Get(TemplateName, BatchName);
        Window.Open(ProgressBarMsg);
        SetMatchLengthThreshold(4);
        SetNormalizingFactor(10);
        FillTempGenJournalLine(GenJournalBatch, TempGenJournalLine);
        FindMatchingCustEntries(TempBankStatementMatchingBuffer, TempGenJournalLine);
        FindMatchingVendorEntries(TempBankStatementMatchingBuffer, TempGenJournalLine);
        SaveOneToOneMatching(TempBankStatementMatchingBuffer, GenJournalBatch);

        FillTempGenJournalLine(GenJournalBatch, TempGenJournalLine);
        FindAccountMappings(TempGenJournalLine);

        Window.Close();
        ShowMatchSummary(GenJournalBatch);
    end;

    local procedure FindMatchingCustEntries(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var TempGenJournalLine: Record "Gen. Journal Line" temporary)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        OnBeforeFindMatchingCustEntries(TempBankStatementMatchingBuffer, TempGenJournalLine);
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetFilter("Document Type", '<>%1&<>%2',
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Refund);
        CustLedgerEntry.SetRange("Applies-to ID", '');
        CustLedgerEntry.SetAutoCalcFields("Remaining Amt. (LCY)");
        OnFindMatchingCustEntriesOnAfterCustLedgerEntrySetFilters(CustLedgerEntry, TempBankStatementMatchingBuffer, TempGenJournalLine);
        if CustLedgerEntry.FindSet() then
            repeat
                FindMatchingCustEntry(TempBankStatementMatchingBuffer, CustLedgerEntry, TempGenJournalLine);
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure FindMatchingCustEntry(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    var
        Customer: Record Customer;
        Score: Integer;
    begin
        Customer.Get(CustLedgerEntry."Customer No.");
        if GenJournalLine.FindSet() then
            repeat
                Score := GetMatchScore(GenJournalLine, CustLedgerEntry."Document No.", Customer."No.", CustLedgerEntry."External Document No.",
                    Customer.Name, CustLedgerEntry."Remaining Amt. (LCY)", 1, CustLedgerEntry."Posting Date");
                OnFindMatchingCustEntryOnAfterGetMatchScore(GenJournalLine, CustLedgerEntry, Score);
                if Score > 5 then
                    TempBankStatementMatchingBuffer.AddMatchCandidate(GenJournalLine."Line No.", CustLedgerEntry."Entry No.", Score,
                      TempBankStatementMatchingBuffer."Account Type"::Customer, CustLedgerEntry."Customer No.");
                OnFindMatchingCustEntryOnAfterMatch(TempBankStatementMatchingBuffer, CustLedgerEntry, GenJournalLine, Score);
            until GenJournalLine.Next() = 0;
    end;

    local procedure FindMatchingVendorEntries(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var TempGenJournalLine: Record "Gen. Journal Line" temporary)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetFilter("Document Type", '<>%1&<>%2',
          VendorLedgerEntry."Document Type"::Payment, VendorLedgerEntry."Document Type"::Refund);
        VendorLedgerEntry.SetRange("Applies-to ID", '');
        VendorLedgerEntry.SetAutoCalcFields("Remaining Amt. (LCY)");
        OnFindMatchingVendorEntriesOnAfterSetVendorLedgerEntryFilters(VendorLedgerEntry, TempBankStatementMatchingBuffer, TempGenJournalLine);
        if VendorLedgerEntry.FindSet() then
            repeat
                FindMatchingVendorEntry(TempBankStatementMatchingBuffer, VendorLedgerEntry, TempGenJournalLine);
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure FindMatchingVendorEntry(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    var
        Vendor: Record Vendor;
        Score: Integer;
    begin
        Vendor.Get(VendorLedgerEntry."Vendor No.");
        if GenJournalLine.FindSet() then
            repeat
                Score := GetMatchScore(GenJournalLine, VendorLedgerEntry."Document No.", Vendor."No.",
                    VendorLedgerEntry."External Document No.", Vendor.Name, VendorLedgerEntry."Remaining Amt. (LCY)", -1,
                    VendorLedgerEntry."Posting Date");
                if Score > 5 then
                    TempBankStatementMatchingBuffer.AddMatchCandidate(GenJournalLine."Line No.", VendorLedgerEntry."Entry No.", Score,
                      TempBankStatementMatchingBuffer."Account Type"::Vendor, VendorLedgerEntry."Vendor No.");
                OnFindMatchingVendorEntryOnAfterMatch(TempBankStatementMatchingBuffer, VendorLedgerEntry, GenJournalLine, Score);
            until GenJournalLine.Next() = 0;
    end;

    local procedure FindAccountMappings(var TempGenJournalLine: Record "Gen. Journal Line" temporary)
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentDocType: Enum "Gen. Journal Document Type";
        InvoiceDocType: Enum "Gen. Journal Document Type";
        PaymentDocTypeOption: Option;
        InvoiceDocTypeOption: Option;
    begin
        if TempGenJournalLine.FindSet() then
            repeat
                if GetAccountMapping(TextToAccMapping, TempGenJournalLine.Description) then begin
                    GenJournalLine.Get(TempGenJournalLine."Journal Template Name", TempGenJournalLine."Journal Batch Name", TempGenJournalLine."Line No.");
                    case TextToAccMapping."Bal. Source Type" of
                        TextToAccMapping."Bal. Source Type"::"G/L Account":
                            UpdateGenJnlLine(
                              GenJournalLine, GenJournalLine."Document Type",
                              GenJournalLine."Account Type"::"G/L Account",
                              TextToAccMapping.GetAccountNo(GenJournalLine.Amount), '');
                        TextToAccMapping."Bal. Source Type"::Customer,
                        TextToAccMapping."Bal. Source Type"::Vendor:
                            if TextToAccMapping."Bal. Source No." <> '' then begin
                                TextToAccMapping.GetPaymentDocType(PaymentDocTypeOption, TextToAccMapping."Bal. Source Type", GenJournalLine.Amount);
                                PaymentDocType := Enum::"Gen. Journal Document Type".FromInteger(PaymentDocTypeOption);
                                TextToAccMapping.GetDocTypeForPmt(InvoiceDocTypeOption, PaymentDocType.AsInteger());
                                InvoiceDocType := Enum::"Gen. Journal Document Type".FromInteger(InvoiceDocTypeOption);
                                UpdateGenJnlLine(
                                  GenJournalLine, PaymentDocType,
                                  Enum::"Gen. Journal Account Type".FromInteger(TextToAccMapping."Bal. Source Type"), TextToAccMapping."Bal. Source No.", '');
                                CreateInvoiceLineFromPayment(
                                  GenJournalLine, InvoiceDocType,
                                  PaymentDocType, TextToAccMapping.GetAccountNo(GenJournalLine.Amount));
                            end;
                    end;
                end;
            until TempGenJournalLine.Next() = 0;
    end;

    local procedure GetAccountMapping(var TextToAccMapping: Record "Text-to-Account Mapping"; Description: Text): Boolean
    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        MaxNearness: Integer;
        Nearness: Integer;
        MatchLineNo: Integer;
        IsHandled: Boolean;
    begin
        Description := RecordMatchMgt.Trim(Description);
        TextToAccMapping.SetFilter("Mapping Text", '%1', '@' + Description);
        if TextToAccMapping.FindFirst() then
            exit(true);

        TextToAccMapping.Reset();
        MaxNearness := 0;
        if TextToAccMapping.FindSet() then
            repeat
                if Description = RecordMatchMgt.Trim(TextToAccMapping."Mapping Text") then
                    exit(true);

                IsHandled := false;
                OnGetAccountMappingOnBeforeCalculateStringNearness(TextToAccMapping, Description, IsHandled);
                if IsHandled then
                    exit(true);

                Nearness :=
                    RecordMatchMgt.CalculateStringNearness(
                        ' ' + RecordMatchMgt.Trim(TextToAccMapping."Mapping Text") + ' ',
                        ' ' + Description + ' ', StrLen(TextToAccMapping."Mapping Text") + 1, 10);
                if Nearness > MaxNearness then begin
                    MaxNearness := Nearness;
                    MatchLineNo := TextToAccMapping."Line No.";
                end;
            until TextToAccMapping.Next() = 0;

        if TextToAccMapping.Get(MatchLineNo) then
            exit(true);

        exit(false);
    end;

    local procedure GetNextAvailableLineNo(GenJournalLine: Record "Gen. Journal Line"): Integer
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine2.SetFilter("Line No.", '>%1', GenJournalLine."Line No.");
        if GenJournalLine2.FindFirst() then
            exit(GenJournalLine."Line No." + (GenJournalLine2."Line No." - GenJournalLine."Line No.") div 2);

        exit(GenJournalLine."Line No." + 10000);
    end;

    local procedure SaveOneToOneMatching(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        TempBankStatementMatchingBuffer.Reset();
        TempBankStatementMatchingBuffer.SetCurrentKey(Quality);
        TempBankStatementMatchingBuffer.Ascending(false);
        OnSaveOneToOneMatchingOnBeforeTempBankStatementMatchingBufferFindSet(TempBankStatementMatchingBuffer);
        if TempBankStatementMatchingBuffer.FindSet() then
            repeat
                GenJournalLine.Get(GenJournalBatch."Journal Template Name",
                  GenJournalBatch.Name, TempBankStatementMatchingBuffer."Line No.");
                ApplyRecords(GenJournalLine, TempBankStatementMatchingBuffer);
            until TempBankStatementMatchingBuffer.Next() = 0;
    end;

    local procedure ApplyRecords(var GenJournalLine: Record "Gen. Journal Line"; var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        case TempBankStatementMatchingBuffer."Account Type" of
            TempBankStatementMatchingBuffer."Account Type"::Customer:
                if CustLedgerEntry.Get(TempBankStatementMatchingBuffer."Entry No.") then
                    if (GenJournalLine."Applies-to ID" = '') and (CustLedgerEntry."Applies-to ID" = '') then begin
                        UpdateGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
                          GenJournalLine."Account Type"::Customer, CustLedgerEntry."Customer No.", GenJournalLine."Document No.");
                        PrepareCustLedgerEntryForApplication(CustLedgerEntry, GenJournalLine);
                    end;
            TempBankStatementMatchingBuffer."Account Type"::Vendor:
                if VendorLedgerEntry.Get(TempBankStatementMatchingBuffer."Entry No.") then
                    if (GenJournalLine."Applies-to ID" = '') and (VendorLedgerEntry."Applies-to ID" = '') then begin
                        UpdateGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
                          GenJournalLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.", GenJournalLine."Document No.");
                        PrepareVendorLedgerEntryForApplication(VendorLedgerEntry, GenJournalLine);
                    end;
        end;
    end;

    local procedure CreateInvoiceLineFromPayment(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AppliesToDocType: Enum "Gen. Journal Document Type"; BalAccountNo: Code[20])
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        GenJournalLine2.Copy(GenJournalLine);
        GenJournalLine2."Line No." := GetNextAvailableLineNo(GenJournalLine);
        if GenJournalLine2."Line No." = GenJournalLine."Line No." then
            exit;
        GenJournalLine2.Validate(Amount, -GenJournalLine2.Amount);
        GenJournalLine2.Validate("Document Type", DocType);
        GenJournalLine2.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine2.Validate("Applies-to Doc. No.", GenJournalLine."Document No.");
        GenJournalLine2.Validate("Bal. Account Type", GenJournalLine2."Bal. Account Type"::"G/L Account");
        GenJournalLine2.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine2.Validate(Description, GenJournalLine.Description);
        GenJournalLine2.Insert(true);
    end;

    local procedure UpdateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocID: Code[50])
    var
        OrigCurrencyCode: Code[10];
        OrigDescription: Text[100];
    begin
        OrigCurrencyCode := GenJournalLine."Currency Code";
        OrigDescription := GenJournalLine.Description;
        GenJournalLine.Validate("Document Type", DocType);
        GenJournalLine.Validate("Account Type", AccountType);
        GenJournalLine.Validate("Account No.", AccountNo);
        GenJournalLine.Validate("Applies-to ID", AppliesToDocID);
        if OrigCurrencyCode <> GenJournalLine."Currency Code" then
            GenJournalLine.Validate("Currency Code", OrigCurrencyCode);
        GenJournalLine.Validate("Applied Automatically", true);
        GenJournalLine.Validate(Description, OrigDescription);
        GenJournalLine.Modify(true);
    end;

    procedure PrepareCustLedgerEntryForApplication(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        CustLedgerEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        CustLedgerEntry."Applies-to ID" := GenJournalLine."Document No.";
        OnPrepareCustLedgerEntryForApplicationOnBeforeSetAmountToApply(CustLedgerEntry);
        if Abs(CustLedgerEntry."Remaining Amt. (LCY)") < Abs(GenJournalLine."Amount (LCY)") then
            CustLedgerEntry."Amount to Apply" := CustLedgerEntry."Remaining Amount"
        else
            CustLedgerEntry."Amount to Apply" := -GenJournalLine.Amount;

        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgerEntry);
    end;

    local procedure PrepareVendorLedgerEntryForApplication(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        VendorLedgerEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        VendorLedgerEntry."Applies-to ID" := GenJournalLine."Document No.";
        OnPrepareVendorLedgerEntryForApplicationOnBeforeSetAmountToApply(VendorLedgerEntry);
        if Abs(VendorLedgerEntry."Remaining Amt. (LCY)") < Abs(GenJournalLine."Amount (LCY)") then
            VendorLedgerEntry."Amount to Apply" := VendorLedgerEntry."Remaining Amount"
        else
            VendorLedgerEntry."Amount to Apply" := -GenJournalLine.Amount;

        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendorLedgerEntry);
    end;

    procedure FillTempGenJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var TempGenJournalLine: Record "Gen. Journal Line" temporary)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        TempGenJournalLine.DeleteAll();
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetRange("Applies-to ID", '');
        GenJournalLine.SetRange("Account No.", '');
        GenJournalLine.SetRange("Applied Automatically", false);
        GenJournalLine.SetFilter("Document Type", '%1|%2',
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Document Type"::Payment);
        if GenJournalLine.FindSet() then
            repeat
                TempGenJournalLine := GenJournalLine;
                TempGenJournalLine.Insert();
            until GenJournalLine.Next() = 0;
    end;

    local procedure ShowMatchSummary(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
        FinalText: Text;
        AdditionalText: Text;
        TotalCount: Integer;
        MatchedCount: Integer;
        IsHandled: Boolean;
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetFilter("Document Type", '%1|%2|%3',
          GenJournalLine."Document Type"::" ", GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Refund);
        TotalCount := GenJournalLine.Count();

        GenJournalLine.SetRange("Applied Automatically", true);
        MatchedCount := GenJournalLine.Count();

        if MatchedCount < TotalCount then
            AdditionalText := StrSubstNo(MissingMatchMsg, Format(GetMatchLengthTreshold()));
        FinalText := StrSubstNo(MatchSummaryMsg, MatchedCount, TotalCount) + AdditionalText;
        IsHandled := false;
        OnShowMatchSummaryOnAfterSetFinalText(GenJournalBatch, FinalText, IsHandled);
        if not IsHandled then
            Message(FinalText);
    end;

    local procedure GetMatchScore(GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; CustVendorNo: Code[20]; ExternalDocNo: Code[35]; CustVendorName: Text[100]; RemainingAmountLCY: Decimal; PreferredSign: Integer; EntryPostingDate: Date): Integer
    var
        Score: Integer;
    begin
        if GenJournalLine."Amount (LCY)" * RemainingAmountLCY > 0 then
            exit(0);

        if GenJournalLine."Posting Date" < EntryPostingDate then
            exit(0);

        Score += GetDescriptionMatchScore(GenJournalLine.Description, DocumentNo, CustVendorNo, ExternalDocNo, CustVendorName);

        Score += GetDescriptionMatchScore(GenJournalLine."Payer Information", DocumentNo, CustVendorNo, ExternalDocNo, CustVendorName);

        Score += GetDescriptionMatchScore(GenJournalLine."Transaction Information", DocumentNo, CustVendorNo, ExternalDocNo, CustVendorName);

        if GenJournalLine."Amount (LCY)" = -RemainingAmountLCY then
            Score += 4;

        if PreferredSign * GenJournalLine.Amount < 0 then
            Score += 2;

        exit(Score);
    end;

    local procedure GetDescriptionMatchScore(Description: Text; DocumentNo: Code[20]; CustVendorNo: Code[20]; ExternalDocNo: Code[35]; CustVendorName: Text[100]): Integer
    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        Score: Integer;
        Nearness: Integer;
        MatchLengthTreshold: Integer;
        NormalizingFactor: Integer;
    begin
        Description := RecordMatchMgt.Trim(Description);
        MatchLengthTreshold := GetMatchLengthTreshold();
        NormalizingFactor := GetNormalizingFactor();
        Score := 0;

        Nearness := RecordMatchMgt.CalculateStringNearness(DocumentNo, Description, MatchLengthTreshold, NormalizingFactor);
        if Nearness = NormalizingFactor then
            Score += 13;

        Nearness := RecordMatchMgt.CalculateStringNearness(CustVendorNo, Description, MatchLengthTreshold, NormalizingFactor);
        if Nearness = NormalizingFactor then
            Score += Nearness;

        Nearness := RecordMatchMgt.CalculateStringNearness(ExternalDocNo, Description, MatchLengthTreshold, NormalizingFactor);
        if Nearness = NormalizingFactor then
            Score += Nearness;

        Nearness := RecordMatchMgt.CalculateStringNearness(CustVendorName, Description, MatchLengthTreshold, NormalizingFactor);
        if Nearness >= 0.8 * NormalizingFactor then
            Score += Nearness;

        exit(Score)
    end;

    procedure SetMatchLengthThreshold(NewMatchLengthThreshold: Integer)
    begin
        MatchLengthTreshold := NewMatchLengthThreshold;
    end;

    procedure SetNormalizingFactor(NewNormalizingFactor: Integer)
    begin
        NormalizingFactor := NewNormalizingFactor;
    end;

    procedure GetMatchLengthTreshold(): Integer
    begin
        exit(MatchLengthTreshold);
    end;

    procedure GetNormalizingFactor(): Integer
    begin
        exit(NormalizingFactor);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindMatchingCustEntries(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var TempGenJournalLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindMatchingVendorEntriesOnAfterSetVendorLedgerEntryFilters(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var TempGenJournalLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindMatchingCustEntryOnAfterGetMatchScore(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var Score: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindMatchingCustEntriesOnAfterCustLedgerEntrySetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var TempGenJournalLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAccountMappingOnBeforeCalculateStringNearness(var TextToAccMapping: Record "Text-to-Account Mapping"; Description: Text; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowMatchSummaryOnAfterSetFinalText(var GenJournalBatch: Record "Gen. Journal Batch"; FinalText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindMatchingCustEntryOnAfterMatch(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; Score: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindMatchingVendorEntryOnAfterMatch(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; Score: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveOneToOneMatchingOnBeforeTempBankStatementMatchingBufferFindSet(var TempBankStatementMatchingBuffer: Record "Bank Statement Matching Buffer" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareCustLedgerEntryForApplicationOnBeforeSetAmountToApply(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareVendorLedgerEntryForApplicationOnBeforeSetAmountToApply(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;
}

