// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Receivables;

codeunit 32000000 "Ref. Payment Management"
{
    Permissions = TableData "Gen. Journal Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        RefPmtImport: Record "Ref. Payment - Imported";
        RefPmtImportTemp: Record "Ref. Payment - Imported" temporary;
        BankAcc: Record "Bank Account";
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlTemplate: Record "Gen. Journal Template";
        VendLedgEntry: Record "Vendor Ledger Entry";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        ApplyVendLedgEntry: Page "Apply Vendor Entries";
        LineNro: Integer;
        LastDocNro: Code[20];
        AccCode: Code[20];
        Text1090001: Label 'Non-applied entries in the system!';
        Text1090005: Label 'When applying one payment to multiple invoices the system does not support disregarding of payment discount at full payment.';

    [Scope('OnPrem')]
    procedure SetLines(RefPaymentImported: Record "Ref. Payment - Imported"; JnlBatchName: Code[20]; JnlTemplateName: Code[20])
    var
        LineNoIncrement: Integer;
    begin
        LineNoIncrement := 10000;
        GLSetup.Get();
        GenJnlTemplate.Get(JnlTemplateName);

        GenJnlLine.Reset();
        GenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Line No.");
        GenJnlLine.SetFilter("Journal Template Name", JnlTemplateName);
        GenJnlLine.SetFilter("Journal Batch Name", JnlBatchName);
        if GenJnlLine.FindLast() then
            LastDocNro := IncStr(GenJnlLine."Document No.")
        else
            GetNroSeries(JnlBatchName, JnlTemplateName);
        OnBeforeSetLineNo(LineNoIncrement, GenJnlLine);
        LineNro := GenJnlLine."Line No." + LineNoIncrement;

        RefPaymentImported.Ascending(true);
        RefPaymentImported.SetRange("Posted to G/L", false);
        RefPaymentImported.SetRange(Matched, true);
        RefPaymentImported.SetFilter("Entry No.", '<>%1', 0);
        CustLedgEntry.Reset();
        if RefPaymentImported.FindSet() then
            repeat
                BankAcc.SetRange("No.", RefPaymentImported."Bank Account Code");
                if BankAcc.FindFirst() then
                    AccCode := BankAcc."No."
                else
                    AccCode := '';
                CustLedgEntry.SetRange("Entry No.", RefPaymentImported."Entry No.");
                GenJnlLine.Reset();
                GenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Applies-to Doc. No.", "Reference No.");
                GenJnlLine.SetRange("Journal Template Name", JnlTemplateName);
                GenJnlLine.SetRange("Journal Batch Name", JnlBatchName);
                GenJnlLine.SetRange("Applies-to Doc. No.", RefPaymentImported."Document No.");
                GenJnlLine.SetRange("Reference No.", RefPaymentImported."Reference No.");
                GenJnlLine.SetRange(Comment, RefPaymentImported."Filing Code");
                RefPmtImportTemp.SetRange("Account No.", RefPaymentImported."Account No.");
                RefPmtImportTemp.SetRange("Filing Code", RefPaymentImported."Filing Code");
                if (CustLedgEntry.FindFirst() or (not RefPmtImportTemp.FindFirst())) and (not GenJnlLine.FindFirst()) then begin
                    GenJnlLine.Init();
                    GenJnlLine."Journal Template Name" := JnlTemplateName;
                    GenJnlLine.Validate("Journal Batch Name", JnlBatchName);
                    GenJnlLine."Line No." := LineNro;
                    GenJnlLine.Validate("Posting Date", RefPaymentImported."Banks Posting Date");
                    GenJnlLine.Validate("Account Type", 1);
                    GenJnlLine.Validate("Account No.", CustLedgEntry."Customer No.");
                    GenJnlLine.Validate("Document Type", 1);
                    GenJnlLine.Validate("Applies-to Doc. Type", 2);
                    GenJnlLine."Applies-to Doc. No." := CustLedgEntry."Document No.";
                    GenJnlLine."Document No." := LastDocNro;
                    GenJnlLine.Validate("Bal. Account Type", 3);
                    GenJnlLine."Reference No." := RefPaymentImported."Reference No.";
                    GenJnlLine."Source Code" := GenJnlTemplate."Source Code";
                    GenJnlLine.Validate("Currency Code", CustLedgEntry."Currency Code");
                    GenJnlLine.Validate(Amount, RefPaymentImported.Amount * -1);
                    GenJnlLine.Comment := RefPaymentImported."Filing Code";
                    GenJnlLine.Validate("Bal. Account No.", GetBalAccountNo(GenJnlLine, AccCode, CustLedgEntry));
                    OnSetLinesOnBeforeGenJnlLineInsert(CustLedgEntry, GenJnlLine, RefPaymentImported);
                    GenJnlLine.Insert(true);
                    LineNro += LineNoIncrement;
                    LastDocNro := IncStr(LastDocNro);
                end;
            until RefPaymentImported.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetNroSeries(JnlBatchName: Code[20]; JnlTemplateName: Code[20])
    begin
        LineNro := 10000;
        GenJnlBatch.SetFilter("Journal Template Name", JnlTemplateName);
        GenJnlBatch.SetFilter(Name, JnlBatchName);
        if GenJnlBatch.FindFirst() then
            LastDocNro := NoSeriesBatch.GetNextNo(GenJnlBatch."No. Series");
    end;

    procedure MatchLines(JnlTemplateName: Code[20]; JnlBatchName: Code[20])
    var
        NoMatchLines: Boolean;
    begin
        RefPmtImport.Reset();
        RefPmtImport.SetRange("Record ID", 3, 5);
        RefPmtImport.SetRange("Posted to G/L", false);
        if RefPmtImport.FindSet() then
            repeat
                CustLedgEntry.Reset();
                CustLedgEntry.SetFilter("Reference No.", RefPmtImport."Reference No.");
                CustLedgEntry.SetFilter("Document Type", '%1', 2);
                CustLedgEntry.SetRange(Open, true);
                OnMatchLinesOnAfterCustLedgEntrySetFilters(RefPmtImport, CustLedgEntry);
                if CustLedgEntry.FindFirst() then begin
                    RefPmtImport."Entry No." := CustLedgEntry."Entry No.";
                    RefPmtImport.Validate("Customer No.", CustLedgEntry."Customer No.");
                    RefPmtImport."Document No." := CustLedgEntry."Document No.";
                    RefPmtImport."Posting Date" := CustLedgEntry."Posting Date";
                    RefPmtImport.Matched := true;
                    RefPmtImport."Matched Date" := Today;
                    RefPmtImport."Matched Time" := Time;
                    RefPmtImport.Modify();
                end else
                    NoMatchLines := true;
            until RefPmtImport.Next() = 0;

        if NoMatchLines then
            Message(Text1090001);

        RefPmtImport.Reset();
        SetLines(RefPmtImport, JnlBatchName, JnlTemplateName);
    end;

    [Scope('OnPrem')]
    procedure CombineVendPmt(PaymentType: Option Domestic,Foreign,SEPA)
    var
        RefPmtExported: Record "Ref. Payment - Exported";
        RefPmtExport1: Record "Ref. Payment - Exported";
        TempRefPmtBuffer: Record "Ref. Payment - Exported Buffer" temporary;
        Vendor: Record Vendor;
        LastLineNo: Integer;
    begin
        RefPmtExported.SetCurrentKey(Transferred, "Applied Payments");
        RefPmtExported.SetRange(Transferred, false);
        RefPmtExported.SetRange("Applied Payments", false);
        case PaymentType of
            PaymentType::Domestic:
                RefPmtExported.SetRange("Foreign Payment", false);
            PaymentType::Foreign:
                RefPmtExported.SetRange("Foreign Payment", true);
            PaymentType::SEPA:
                RefPmtExported.SetRange("SEPA Payment", true);
        end;
        OnCombineVendPmtOnBeforeFindRefPaymentExported(RefPmtExported);
        if RefPmtExported.FindSet() then
            repeat
                RefPmtExported.TestField("Vendor No.");
                RefPmtExported.TestField("Payment Account");
                RefPmtExported.TestField("Payment Date");
                CheckCombineAllowance(RefPmtExported."Payment Account", PaymentType);
            until RefPmtExported.Next() = 0;

        if RefPmtExported.FindSet(true) then
            repeat
                RefPmtExport1 := RefPmtExported;
                RefPmtExport1."Affiliated to Line" := TempRefPmtBuffer.AddLine(RefPmtExported);
                RefPmtExport1."Applied Payments" := true;
                RefPmtExport1.Modify();
            until RefPmtExported.Next() = 0;

        TempRefPmtBuffer.SetFilter("No.", '<>%1', 0);
        if TempRefPmtBuffer.FindSet() then
            repeat
                if RefPmtExported.Get(TempRefPmtBuffer."No.") then begin
                    RefPmtExported."Affiliated to Line" := 0;
                    RefPmtExported."Applied Payments" := false;
                    RefPmtExported.Modify();
                end;
            until TempRefPmtBuffer.Next() = 0;
        TempRefPmtBuffer.DeleteAll();

        RefPmtExported.LockTable();
        LastLineNo := RefPmtExported.GetLastLineNo() + 1;
        TempRefPmtBuffer.Reset();
        if TempRefPmtBuffer.FindSet() then
            repeat
                RefPmtExported.Init();
                RefPmtExported.TransferFields(TempRefPmtBuffer);
                if (PaymentType = PaymentType::SEPA) and RefPmtExport1.Get(TempRefPmtBuffer."Affiliated to Line") then
                    RefPmtExported."Document No." := RefPmtExport1."Document No.";
                RefPmtExported."No." := LastLineNo;
                Vendor.Get(RefPmtExported."Vendor No.");
                RefPmtExported."Description 2" := CopyStr(Vendor.Name, 1, MaxStrLen(RefPmtExported."Description 2"));
                RefPmtExported."Document Type" := RefPmtExported."Document Type"::Invoice;
                RefPmtExported.Validate("Message Type");
                RefPmtExported.Insert();
                LastLineNo := LastLineNo + 1;
            until TempRefPmtBuffer.Next() = 0;
        TempRefPmtBuffer.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure VendPaymApply(VendNo: Code[20])
    begin
        VendLedgEntry.SetFilter("Vendor No.", VendNo);
        VendLedgEntry.SetFilter("Document Type", '%1|%2', 2, 3);
        VendLedgEntry.SetRange(Open, true);
        ApplyVendLedgEntry.SetTableView(VendLedgEntry);
    end;

    procedure OEM2ANSI(OEMString: Text[250]): Text[250]
    var
        ToChars: Text[250];
        FromChars: Text[250];
    begin
        FromChars[1] := 192;
        FromChars[2] := 193;
        FromChars[3] := 196;
        FromChars[4] := 197;
        FromChars[5] := 198;
        FromChars[6] := 199;
        FromChars[7] := 200;
        FromChars[8] := 201;
        FromChars[9] := 202;
        FromChars[10] := 203;
        FromChars[11] := 204;
        FromChars[12] := 205;
        FromChars[13] := 206;
        FromChars[14] := 207;
        FromChars[15] := 209;
        FromChars[16] := 210;
        FromChars[17] := 211;
        FromChars[18] := 212;
        FromChars[19] := 214;
        FromChars[20] := 220;
        FromChars[21] := 223;
        FromChars[22] := 224;
        FromChars[23] := 225;
        FromChars[24] := 226;
        FromChars[25] := 228;
        FromChars[26] := 229;
        FromChars[27] := 230;
        FromChars[28] := 231;
        FromChars[29] := 232;
        FromChars[30] := 233;
        FromChars[31] := 234;
        FromChars[32] := 235;
        FromChars[33] := 236;
        FromChars[34] := 237;
        FromChars[35] := 238;
        FromChars[36] := 239;
        FromChars[37] := 241;
        FromChars[38] := 242;
        FromChars[39] := 243;
        FromChars[40] := 244;
        FromChars[41] := 245;
        FromChars[42] := 246;
        FromChars[43] := 249;
        FromChars[44] := 250;
        FromChars[45] := 251;
        FromChars[46] := 252;
        ToChars[1] := 183;
        ToChars[2] := 181;
        ToChars[3] := 142;
        ToChars[4] := 143;
        ToChars[5] := 146;
        ToChars[6] := 128;
        ToChars[7] := 212;
        ToChars[8] := 144;
        ToChars[9] := 210;
        ToChars[10] := 211;
        ToChars[11] := 222;
        ToChars[12] := 214;
        ToChars[13] := 215;
        ToChars[14] := 216;
        ToChars[15] := 165;
        ToChars[16] := 227;
        ToChars[17] := 224;
        ToChars[18] := 226;
        ToChars[19] := 153;
        ToChars[20] := 154;
        ToChars[21] := 225;
        ToChars[22] := 133;
        ToChars[23] := 160;
        ToChars[24] := 131;
        ToChars[25] := 132;
        ToChars[26] := 134;
        ToChars[27] := 145;
        ToChars[28] := 135;
        ToChars[29] := 138;
        ToChars[30] := 130;
        ToChars[31] := 136;
        ToChars[32] := 137;
        ToChars[33] := 141;
        ToChars[34] := 161;
        ToChars[35] := 140;
        ToChars[36] := 139;
        ToChars[37] := 164;
        ToChars[38] := 149;
        ToChars[39] := 162;
        ToChars[40] := 147;
        ToChars[41] := 228;
        ToChars[42] := 148;
        ToChars[43] := 151;
        ToChars[44] := 163;
        ToChars[45] := 150;
        ToChars[46] := 129;
        exit(ConvertStr(OEMString, ToChars, FromChars));
    end;

    [Scope('OnPrem')]
    procedure CheckIfPaidInFull(var GenJnlLine2: Record "Gen. Journal Line")
    var
        CustLedgerEntryPmt: Record "Cust. Ledger Entry";
        CountEntries: Integer;
    begin
        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Document No.");
        CustLedgEntry.SetRange("Document Type", GenJnlLine2."Applies-to Doc. Type");
        CustLedgEntry.SetRange("Document No.", GenJnlLine2."Applies-to Doc. No.");
        if CustLedgEntry.FindFirst() then
            UpdateDiscountPossible(GenJnlLine2, GenJnlLine2.Amount)
        else begin
            CustLedgEntry.Reset();
            CustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID", Open, Positive, "Due Date");
            CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
            CustLedgEntry.SetRange("Applies-to ID", GenJnlLine2."Applies-to ID");
            CountEntries := CustLedgEntry.Count;
            if CustLedgEntry.FindFirst() and (CustLedgEntry."Applies-to ID" <> '') then
                if CountEntries > 1 then begin
                    if CustLedgEntry."Disreg. Pmt. Disc. at Full Pmt" then
                        Error(Text1090005);
                end else begin
                    CustLedgerEntryPmt.Reset();
                    CustLedgerEntryPmt.SetCurrentKey("Customer No.", "Applies-to ID", Open, Positive, "Due Date");
                    CustLedgerEntryPmt.SetRange("Document Type", CustLedgEntry."Document Type"::Payment);
                    CustLedgerEntryPmt.SetRange("Applies-to ID", GenJnlLine2."Applies-to ID");
                    if CustLedgerEntryPmt.FindFirst() then begin
                        CustLedgerEntryPmt.CalcFields(Amount);
                        UpdateDiscountPossible(GenJnlLine2, CustLedgerEntryPmt.Amount);
                    end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateDiscountPossible(var GenJnlLine2: Record "Gen. Journal Line"; PaymentAmount: Decimal)
    begin
        if CustLedgEntry."Disreg. Pmt. Disc. at Full Pmt" and
            (GenJnlLine2."Posting Date" <= CustLedgEntry."Pmt. Disc. Tolerance Date") and
            (CustLedgEntry."Remaining Pmt. Disc. Possible" <> 0)
        then begin
            CustLedgEntry.CalcFields("Remaining Amount");
            if Abs(PaymentAmount) >= Abs(CustLedgEntry."Remaining Amount") then begin
                CustLedgEntry."Remaining Pmt. Disc. Possible" := 0;
                CustLedgEntry.Modify();
            end else
                if (Abs(PaymentAmount) > Abs(CustLedgEntry."Remaining Amount") - CustLedgEntry."Remaining Pmt. Disc. Possible") and
                   (CustLedgEntry."Accepted Payment Tolerance" = 0)
                then begin
                    CustLedgEntry."Remaining Pmt. Disc. Possible" := Abs(CustLedgEntry."Remaining Amount") - Abs(PaymentAmount);
                    CustLedgEntry.Modify();
                end;
        end;
    end;

    procedure GetRefPmtImportTemp(RefPmtImport: Record "Ref. Payment - Imported")
    begin
        if RefPmtImport.FindSet() then
            repeat
                RefPmtImportTemp := RefPmtImport;
                RefPmtImportTemp.Insert();
            until RefPmtImport.Next() = 0;
    end;

    local procedure CheckCombineAllowance(PaymentAccNo: Code[20]; PaymentType: Option Domestic,Foreign,SEPA)
    var
        RefFileSetup: Record "Reference File Setup";
    begin
        if RefFileSetup.Get(PaymentAccNo) then
            case PaymentType of
                PaymentType::Domestic:
                    RefFileSetup.TestField("Allow Comb. Domestic Pmts.");
                PaymentType::Foreign:
                    RefFileSetup.TestField("Allow Comb. Foreign Pmts.");
                PaymentType::SEPA:
                    RefFileSetup.TestField("Allow Comb. SEPA Pmts.");
            end;
    end;

    local procedure GetBalAccountNo(GenJournalLine: Record "Gen. Journal Line"; AccCode: Code[20]; CustLedgerEntry: Record "Cust. Ledger Entry"): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if AccCode <> '' then
            exit(AccCode);

        if (CustLedgerEntry."Bal. Account Type" = CustLedgerEntry."Bal. Account Type"::"Bank Account") and (CustLedgerEntry."Bal. Account No." <> '') then
            exit(CustLedgEntry."Bal. Account No.");

        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        if (GenJournalBatch."Bal. Account Type" = GenJournalBatch."Bal. Account Type"::"Bank Account") and (GenJournalBatch."Bal. Account No." <> '') then
            exit(GenJournalBatch."Bal. Account No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCombineVendPmtOnBeforeFindRefPaymentExported(var RefPmtExported: Record "Ref. Payment - Exported")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatchLinesOnAfterCustLedgEntrySetFilters(RefPmtImport: Record "Ref. Payment - Imported"; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetLinesOnBeforeGenJnlLineInsert(CustLedgEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; RefPaymentImported: Record "Ref. Payment - Imported")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetLineNo(var LineNoIncrement: Integer; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;
}

