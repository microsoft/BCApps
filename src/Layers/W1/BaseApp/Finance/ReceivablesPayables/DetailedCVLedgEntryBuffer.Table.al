// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Sales.Receivables;
using System.Security.AccessControl;

table 383 "Detailed CV Ledg. Entry Buffer"
{
    Caption = 'Detailed CV Ledg. Entry Buffer';
    DrillDownPageID = "Detailed Cust. Ledg. Entries";
    LookupPageID = "Detailed Cust. Ledg. Entries";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "CV Ledger Entry No."; Integer)
        {
            Caption = 'CV Ledger Entry No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Entry Type"; Enum "Detailed CV Ledger Entry Type")
        {
            Caption = 'Entry Type';
            DataClassification = SystemMetadata;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(7; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(8; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(9; "CV No."; Code[20])
        {
            Caption = 'CV No.';
            DataClassification = SystemMetadata;
        }
        field(10; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = SystemMetadata;
            TableRelation = User."User Name";
        }
        field(12; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            DataClassification = SystemMetadata;
            TableRelation = "Source Code";
        }
        field(13; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            DataClassification = SystemMetadata;
        }
        field(14; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = SystemMetadata;
        }
        field(15; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            DataClassification = SystemMetadata;
            TableRelation = "Reason Code";
        }
        field(16; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
            DataClassification = SystemMetadata;
        }
        field(17; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
            DataClassification = SystemMetadata;
        }
        field(18; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Debit Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(19; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Credit Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(20; "Initial Entry Due Date"; Date)
        {
            Caption = 'Initial Entry Due Date';
            DataClassification = SystemMetadata;
        }
        field(21; "Initial Entry Global Dim. 1"; Code[20])
        {
            Caption = 'Initial Entry Global Dim. 1';
            DataClassification = SystemMetadata;
        }
        field(22; "Initial Entry Global Dim. 2"; Code[20])
        {
            Caption = 'Initial Entry Global Dim. 2';
            DataClassification = SystemMetadata;
        }
        field(23; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
            DataClassification = SystemMetadata;
        }
        field(24; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Business Posting Group";
        }
        field(25; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Product Posting Group";
        }
        field(26; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Area";
        }
        field(27; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = SystemMetadata;
        }
        field(28; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Group";
        }
        field(29; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
            DataClassification = SystemMetadata;
        }
        field(30; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        field(31; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Product Posting Group";
        }
        field(32; "Additional-Currency Amount"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Additional-Currency Amount';
            DataClassification = SystemMetadata;
        }
        field(33; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(34; "Use Additional-Currency Amount"; Boolean)
        {
            Caption = 'Use Additional-Currency Amount';
            DataClassification = SystemMetadata;
        }
        field(35; "Initial Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Initial Document Type';
            DataClassification = SystemMetadata;
        }
        field(36; "Applied CV Ledger Entry No."; Integer)
        {
            Caption = 'Applied CV Ledger Entry No.';
            DataClassification = SystemMetadata;
        }
        field(39; "Remaining Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Pmt. Disc. Possible';
            DataClassification = SystemMetadata;
        }
        field(40; "Max. Payment Tolerance"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Max. Payment Tolerance';
            DataClassification = SystemMetadata;
        }
        field(41; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Tax Jurisdiction";
        }
        field(45; "Exch. Rate Adjmt. Reg. No."; Integer)
        {
            Caption = 'Exch. Rate Adjmt. Reg. No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Exch. Rate Adjmt. Reg.";
        }
        field(6200; "Non-Deductible VAT Amount LCY"; Decimal)
        {
            Caption = 'Non-Deductible VAT Amount LCY';
            Editable = false;
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(6201; "Non-Deductible VAT Amount ACY"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Amount ACY';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "CV Ledger Entry No.", "Entry Type")
        {
            SumIndexFields = Amount, "Amount (LCY)", "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)";
        }
        key(Key3; "CV No.", "Initial Entry Due Date", "Posting Date", "Currency Code")
        {
            SumIndexFields = Amount, "Amount (LCY)", "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)";
        }
        key(Key4; "CV No.", "Posting Date", "Entry Type", "Currency Code")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key5; "CV No.", "Initial Document Type", "Document Type")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key6; "Document Type", "Document No.", "Posting Date")
        {
        }
        key(Key7; "Initial Document Type", "CV No.", "Posting Date", "Currency Code", "Entry Type")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key8; "CV No.", "Initial Entry Due Date", "Posting Date", "Initial Entry Global Dim. 1", "Initial Entry Global Dim. 2", "Currency Code")
        {
            Enabled = false;
            SumIndexFields = Amount, "Amount (LCY)", "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)";
        }
        key(Key9; "CV No.", "Posting Date", "Entry Type", "Initial Entry Global Dim. 1", "Initial Entry Global Dim. 2", "Currency Code")
        {
            Enabled = false;
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key10; "CV No.", "Initial Document Type", "Document Type", "Initial Entry Global Dim. 1", "Initial Entry Global Dim. 2")
        {
            Enabled = false;
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key11; "Initial Document Type", "CV No.", "Posting Date", "Currency Code", "Entry Type", "Initial Entry Global Dim. 1", "Initial Entry Global Dim. 2")
        {
            Enabled = false;
            SumIndexFields = Amount, "Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

    protected var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerSetupRead: Boolean;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GeneralLedgerSetupRead then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetupRead := true;
        end;
        exit(GeneralLedgerSetup."Additional Reporting Currency")
    end;

    procedure InsertDtldCVLedgEntry(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; InsertZeroAmout: Boolean)
    var
        NewDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer";
        NextDtldBufferEntryNo: Integer;
        IsHandled: Boolean;
    begin
        if (DtldCVLedgEntryBuf.Amount = 0) and
           (DtldCVLedgEntryBuf."Amount (LCY)" = 0) and
           (DtldCVLedgEntryBuf."VAT Amount (LCY)" = 0) and
           (DtldCVLedgEntryBuf."Additional-Currency Amount" = 0) and
           (not InsertZeroAmout)
        then
            exit;

        DtldCVLedgEntryBuf.TestField("Entry Type");

        OnInsertDtldCVLedgEntryOnBeforeNewDtldCVLedgEntryBufInit(DtldCVLedgEntryBuf, CVLedgEntryBuf);
        NewDtldCVLedgEntryBuf.Init();
        NewDtldCVLedgEntryBuf := DtldCVLedgEntryBuf;

        if NextDtldBufferEntryNo = 0 then begin
            DtldCVLedgEntryBuf.Reset();
            if DtldCVLedgEntryBuf.FindLast() then
                NextDtldBufferEntryNo := DtldCVLedgEntryBuf."Entry No." + 1
            else
                NextDtldBufferEntryNo := 1;
        end;

        DtldCVLedgEntryBuf.Reset();
        DtldCVLedgEntryBuf.SetRange("CV Ledger Entry No.", CVLedgEntryBuf."Entry No.");
        DtldCVLedgEntryBuf.SetRange("Entry Type", NewDtldCVLedgEntryBuf."Entry Type");
        DtldCVLedgEntryBuf.SetRange("Posting Date", NewDtldCVLedgEntryBuf."Posting Date");
        DtldCVLedgEntryBuf.SetRange("Document Type", NewDtldCVLedgEntryBuf."Document Type");
        DtldCVLedgEntryBuf.SetRange("Document No.", NewDtldCVLedgEntryBuf."Document No.");
        DtldCVLedgEntryBuf.SetRange("CV No.", NewDtldCVLedgEntryBuf."CV No.");
        DtldCVLedgEntryBuf.SetRange("Gen. Posting Type", NewDtldCVLedgEntryBuf."Gen. Posting Type");
        DtldCVLedgEntryBuf.SetRange(
          "Gen. Bus. Posting Group", NewDtldCVLedgEntryBuf."Gen. Bus. Posting Group");
        DtldCVLedgEntryBuf.SetRange(
          "Gen. Prod. Posting Group", NewDtldCVLedgEntryBuf."Gen. Prod. Posting Group");
        DtldCVLedgEntryBuf.SetRange(
          "VAT Bus. Posting Group", NewDtldCVLedgEntryBuf."VAT Bus. Posting Group");
        DtldCVLedgEntryBuf.SetRange(
          "VAT Prod. Posting Group", NewDtldCVLedgEntryBuf."VAT Prod. Posting Group");
        DtldCVLedgEntryBuf.SetRange("Tax Area Code", NewDtldCVLedgEntryBuf."Tax Area Code");
        DtldCVLedgEntryBuf.SetRange("Tax Liable", NewDtldCVLedgEntryBuf."Tax Liable");
        DtldCVLedgEntryBuf.SetRange("Tax Group Code", NewDtldCVLedgEntryBuf."Tax Group Code");
        DtldCVLedgEntryBuf.SetRange("Use Tax", NewDtldCVLedgEntryBuf."Use Tax");
        DtldCVLedgEntryBuf.SetRange(
          "Tax Jurisdiction Code", NewDtldCVLedgEntryBuf."Tax Jurisdiction Code");

        IsHandled := false;
        OnBeforeCreateDtldCVLedgEntryBuf(DtldCVLedgEntryBuf, NewDtldCVLedgEntryBuf, NextDtldBufferEntryNo, IsHandled, CVLedgEntryBuf);
        if IsHandled then
            exit;

        if DtldCVLedgEntryBuf.FindFirst() then begin
            DtldCVLedgEntryBuf.Amount := DtldCVLedgEntryBuf.Amount + NewDtldCVLedgEntryBuf.Amount;
            DtldCVLedgEntryBuf."Amount (LCY)" :=
              DtldCVLedgEntryBuf."Amount (LCY)" + NewDtldCVLedgEntryBuf."Amount (LCY)";
            DtldCVLedgEntryBuf."VAT Amount (LCY)" :=
              DtldCVLedgEntryBuf."VAT Amount (LCY)" + NewDtldCVLedgEntryBuf."VAT Amount (LCY)";
            DtldCVLedgEntryBuf."Additional-Currency Amount" :=
              DtldCVLedgEntryBuf."Additional-Currency Amount" +
              NewDtldCVLedgEntryBuf."Additional-Currency Amount";
            OnInsertDtldCVLedgEntryOnBeforeModify(DtldCVLedgEntryBuf, NewDtldCVLedgEntryBuf);
            DtldCVLedgEntryBuf.Modify();
        end else begin
            NewDtldCVLedgEntryBuf."Entry No." := NextDtldBufferEntryNo;
            NextDtldBufferEntryNo := NextDtldBufferEntryNo + 1;
            DtldCVLedgEntryBuf := NewDtldCVLedgEntryBuf;
            OnInsertDtldCVLedgEntryOnBeforeInsert(DtldCVLedgEntryBuf);
            DtldCVLedgEntryBuf.Insert();
        end;

        CVLedgEntryBuf."Amount to Apply" := NewDtldCVLedgEntryBuf.Amount + CVLedgEntryBuf."Amount to Apply";
        CVLedgEntryBuf."Remaining Amount" := NewDtldCVLedgEntryBuf.Amount + CVLedgEntryBuf."Remaining Amount";
        CVLedgEntryBuf."Remaining Amt. (LCY)" :=
          NewDtldCVLedgEntryBuf."Amount (LCY)" + CVLedgEntryBuf."Remaining Amt. (LCY)";

        if DtldCVLedgEntryBuf."Entry Type" = DtldCVLedgEntryBuf."Entry Type"::"Initial Entry" then begin
            CVLedgEntryBuf."Original Amount" := NewDtldCVLedgEntryBuf.Amount;
            CVLedgEntryBuf."Original Amt. (LCY)" := NewDtldCVLedgEntryBuf."Amount (LCY)";
        end;
        DtldCVLedgEntryBuf.Reset();

        OnAfterInsertDtldCVLedgEntry(DtldCVLedgEntryBuf, CVLedgEntryBuf, NewDtldCVLedgEntryBuf, NextDtldBufferEntryNo);
    end;

    procedure CopyPostingGroupsFromVATEntry(VATEntry: Record "VAT Entry")
    begin
        "Gen. Posting Type" := VATEntry.Type;
        "Gen. Bus. Posting Group" := VATEntry."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := VATEntry."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := VATEntry."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := VATEntry."VAT Prod. Posting Group";
        "Tax Area Code" := VATEntry."Tax Area Code";
        "Tax Liable" := VATEntry."Tax Liable";
        "Tax Group Code" := VATEntry."Tax Group Code";
        "Use Tax" := VATEntry."Use Tax";
        OnAfterCopyPostingGroupsFromVATEntry(Rec, VATEntry);
    end;

    procedure CopyFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        "Entry Type" := "Entry Type"::"Initial Entry";
        "Posting Date" := GenJnlLine."Posting Date";
        "Document Type" := GenJnlLine."Document Type";
        "Document No." := GenJnlLine."Document No.";
        Amount := GenJnlLine.Amount;
        "Amount (LCY)" := GenJnlLine."Amount (LCY)";
        "Additional-Currency Amount" := GenJnlLine.Amount;
        "CV No." := GenJnlLine."Account No.";
        "Currency Code" := GenJnlLine."Currency Code";
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Initial Entry Due Date" := GenJnlLine."Due Date";
        "Initial Entry Global Dim. 1" := GenJnlLine."Shortcut Dimension 1 Code";
        "Initial Entry Global Dim. 2" := GenJnlLine."Shortcut Dimension 2 Code";
        "Initial Document Type" := GenJnlLine."Document Type";
        OnAfterCopyFromGenJnlLine(Rec, GenJnlLine);
    end;

    procedure InitFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        Init();
        "Posting Date" := GenJnlLine."Posting Date";
        "Document Type" := GenJnlLine."Document Type";
        "Document No." := GenJnlLine."Document No.";
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        OnAfterInitFromGenJnlLine(Rec, GenJnlLine);
    end;

    procedure CopyFromCVLedgEntryBuf(CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
        "CV Ledger Entry No." := CVLedgEntryBuf."Entry No.";
        "CV No." := CVLedgEntryBuf."CV No.";
        "Currency Code" := CVLedgEntryBuf."Currency Code";
        "Initial Entry Due Date" := CVLedgEntryBuf."Due Date";
        "Initial Entry Global Dim. 1" := CVLedgEntryBuf."Global Dimension 1 Code";
        "Initial Entry Global Dim. 2" := CVLedgEntryBuf."Global Dimension 2 Code";
        "Initial Document Type" := CVLedgEntryBuf."Document Type";
        OnAfterCopyFromCVLedgEntryBuf(Rec, CVLedgEntryBuf);
    end;

    procedure InitDetailedCVLedgEntryBuf(GenJnlLine: Record "Gen. Journal Line"; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; EntryType: Enum "Detailed CV Ledger Entry Type"; AmountFCY: Decimal; AmountLCY: Decimal; AmountAddCurr: Decimal; AppliedEntryNo: Integer; RemainingPmtDiscPossible: Decimal; MaxPaymentTolerance: Decimal)
    var
        IsHandled: Boolean;
    begin
        DtldCVLedgEntryBuf.InitFromGenJnlLine(GenJnlLine);
        DtldCVLedgEntryBuf.CopyFromCVLedgEntryBuf(CVLedgEntryBuf);
        DtldCVLedgEntryBuf."Entry Type" := EntryType;
        DtldCVLedgEntryBuf.Amount := AmountFCY;
        DtldCVLedgEntryBuf."Amount (LCY)" := AmountLCY;
        DtldCVLedgEntryBuf."Additional-Currency Amount" := AmountAddCurr;
        DtldCVLedgEntryBuf."Applied CV Ledger Entry No." := AppliedEntryNo;
        DtldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" := RemainingPmtDiscPossible;
        DtldCVLedgEntryBuf."Max. Payment Tolerance" := MaxPaymentTolerance;
        IsHandled := false;
        OnBeforeInsertDtldCVLedgEntry(DtldCVLedgEntryBuf, GenJnlLine, IsHandled, CVLedgEntryBuf);
        if not IsHandled then
            DtldCVLedgEntryBuf.InsertDtldCVLedgEntry(DtldCVLedgEntryBuf, CVLedgEntryBuf, false);
    end;

    procedure FindVATEntry(var VATEntry: Record "VAT Entry"; TransactionNo: Integer)
    begin
        VATEntry.Reset();
        VATEntry.SetCurrentKey("Transaction No.");
        VATEntry.SetRange("Transaction No.", TransactionNo);
        VATEntry.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
        VATEntry.FindFirst();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromGenJnlLine(var DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromCVLedgEntryBuf(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostingGroupsFromVATEntry(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromGenJnlLine(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertDtldCVLedgEntry(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NextDtldBufferEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDtldCVLedgEntry(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; GenJournalLine: Record "Gen. Journal Line"; var IsHanled: Boolean; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDtldCVLedgEntryBuf(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NewDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NextDtldBufferEntryNo: Integer; var IsHandled: Boolean; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDtldCVLedgEntryOnBeforeInsert(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDtldCVLedgEntryOnBeforeModify(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; NewDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDtldCVLedgEntryOnBeforeNewDtldCVLedgEntryBufInit(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;
}
