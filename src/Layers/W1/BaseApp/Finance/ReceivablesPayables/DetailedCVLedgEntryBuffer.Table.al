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

/// <summary>
/// Buffer table for detailed customer and vendor ledger entry data including applications, payments, and adjustments.
/// Stores temporary copies of detailed entry information for analysis, reporting, and batch processing operations.
/// </summary>
/// <remarks>
/// Mirrors the structure of detailed customer and vendor ledger entries for processing scenarios requiring data manipulation.
/// Supports application tracking, currency amounts, VAT processing, and tax calculations.
/// Used by reports and processes analyzing payment applications, discounts, and detailed transaction history.
/// </remarks>
table 383 "Detailed CV Ledg. Entry Buffer"
{
    Caption = 'Detailed CV Ledg. Entry Buffer';
    DrillDownPageID = "Detailed Cust. Ledg. Entries";
    LookupPageID = "Detailed Cust. Ledg. Entries";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique entry number identifying the detailed ledger entry record.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Reference to the parent customer or vendor ledger entry.
        /// </summary>
        field(2; "CV Ledger Entry No."; Integer)
        {
            Caption = 'CV Ledger Entry No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Type of detailed entry indicating the specific transaction purpose.
        /// </summary>
        field(3; "Entry Type"; Enum "Detailed CV Ledger Entry Type")
        {
            Caption = 'Entry Type';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Date when the detailed entry was posted to the ledger.
        /// </summary>
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Document type associated with the detailed entry transaction.
        /// </summary>
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Document number for the detailed entry transaction.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Transaction amount in the original currency for the detailed entry.
        /// </summary>
        field(7; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Amount in local currency (LCY) for the detailed entry transaction.
        /// </summary>
        field(8; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Customer or vendor number associated with this detailed entry.
        /// </summary>
        field(9; "CV No."; Code[20])
        {
            Caption = 'CV No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Currency code for foreign currency amounts, blank for LCY.
        /// </summary>
        field(10; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        /// <summary>
        /// User ID who created or modified this detailed entry record.
        /// </summary>
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = SystemMetadata;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// Source code identifying the origin of this detailed entry transaction.
        /// </summary>
        field(12; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            DataClassification = SystemMetadata;
            TableRelation = "Source Code";
        }
        /// <summary>
        /// Transaction number linking related detailed entries and postings.
        /// </summary>
        field(13; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Journal batch name from which this detailed entry was created.
        /// </summary>
        /// <summary>
        /// Journal batch name from which this detailed entry was created.
        /// </summary>
        field(14; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Reason code explaining the business purpose of this detailed entry.
        /// </summary>
        field(15; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            DataClassification = SystemMetadata;
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// Debit amount for the detailed entry in original currency.
        /// </summary>
        field(16; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Credit amount for the detailed entry in original currency.
        /// </summary>
        field(17; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Debit amount for the detailed entry in local currency.
        /// </summary>
        field(18; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Debit Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Credit amount for the detailed entry in local currency.
        /// </summary>
        field(19; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Credit Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Due date from the initial entry before any applications or adjustments.
        /// </summary>
        field(20; "Initial Entry Due Date"; Date)
        {
            Caption = 'Initial Entry Due Date';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Global dimension 1 code from the initial entry for reporting and analysis.
        /// </summary>
        field(21; "Initial Entry Global Dim. 1"; Code[20])
        {
            Caption = 'Initial Entry Global Dim. 1';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Global dimension 2 code from the initial entry for cost center and project analysis.
        /// </summary>
        field(22; "Initial Entry Global Dim. 2"; Code[20])
        {
            Caption = 'Initial Entry Global Dim. 2';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// General posting type for G/L account determination and posting setup.
        /// </summary>
        field(23; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// General business posting group for G/L account determination and posting setup.
        /// </summary>
        field(24; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// General product posting group for G/L account determination and posting setup.
        /// </summary>
        field(25; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// Tax area code for sales tax calculation and reporting by geographical location.
        /// </summary>
        field(26; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether the entry is subject to sales tax calculation.
        /// </summary>
        field(27; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Tax group code defining the type of items subject to specific tax rates.
        /// </summary>
        field(28; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Indicates whether use tax applies instead of regular sales tax.
        /// </summary>
        field(29; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT business posting group for VAT calculation and posting setup.
        /// </summary>
        field(30; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// VAT product posting group for VAT calculation and posting setup.
        /// </summary>
        field(31; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Additional reporting currency amount for detailed entry.
        /// </summary>
        field(32; "Additional-Currency Amount"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Additional-Currency Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT amount in local currency for the detailed entry.
        /// </summary>
        field(33; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether to use additional reporting currency amount calculations.
        /// </summary>
        field(34; "Use Additional-Currency Amount"; Boolean)
        {
            Caption = 'Use Additional-Currency Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Document type from the initial entry before applications or adjustments.
        /// </summary>
        field(35; "Initial Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Initial Document Type';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Entry number of the CV ledger entry that this detailed entry was applied to.
        /// </summary>
        field(36; "Applied CV Ledger Entry No."; Integer)
        {
            Caption = 'Applied CV Ledger Entry No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Remaining payment discount amount that can still be taken.
        /// </summary>
        field(39; "Remaining Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Pmt. Disc. Possible';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Maximum payment tolerance amount allowed for this detailed entry.
        /// </summary>
        field(40; "Max. Payment Tolerance"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Max. Payment Tolerance';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Tax jurisdiction code for sales tax calculation and reporting requirements.
        /// </summary>
        field(41; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Tax Jurisdiction";
        }
        /// <summary>
        /// Exchange rate adjustment register number for currency revaluation tracking.
        /// </summary>
        field(45; "Exch. Rate Adjmt. Reg. No."; Integer)
        {
            Caption = 'Exch. Rate Adjmt. Reg. No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Exch. Rate Adjmt. Reg.";
        }
        /// <summary>
        /// Non-deductible VAT amount in local currency for partial VAT deduction scenarios.
        /// </summary>
        field(6200; "Non-Deductible VAT Amount LCY"; Decimal)
        {
            Caption = 'Non-Deductible VAT Amount LCY';
            Editable = false;
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        /// <summary>
        /// Non-deductible VAT amount in additional reporting currency for partial VAT deduction scenarios.
        /// </summary>
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

    /// <summary>
    /// Inserts or updates a detailed CV ledger entry buffer record with consolidation logic.
    /// Combines entries with matching key fields to avoid duplicate buffer records.
    /// </summary>
    /// <param name="DtldCVLedgEntryBuf">Detailed CV ledger entry buffer record to insert</param>
    /// <param name="CVLedgEntryBuf">Parent CV ledger entry buffer record</param>
    /// <param name="InsertZeroAmout">Whether to insert entries with zero amounts</param>
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

    /// <summary>
    /// Copies posting group fields from a VAT entry to the detailed CV ledger entry buffer.
    /// Used for VAT-related detailed entries to maintain proper posting setup references.
    /// </summary>
    /// <param name="VATEntry">VAT entry containing posting group information to copy</param>
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

    /// <summary>
    /// Copies relevant fields from a general journal line to create an initial detailed CV ledger entry.
    /// Sets up the buffer with transaction amounts, dimensions, and basic posting information.
    /// </summary>
    /// <param name="GenJnlLine">General journal line containing source transaction data</param>
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

    /// <summary>
    /// Initializes the detailed CV ledger entry buffer with basic posting information from a general journal line.
    /// Sets up document and user identification fields without amounts or detailed data.
    /// </summary>
    /// <param name="GenJnlLine">General journal line containing basic posting information</param>
    procedure InitFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        Init();
        "Posting Date" := GenJnlLine."Posting Date";
        "Document Type" := GenJnlLine."Document Type";
        "Document No." := GenJnlLine."Document No.";
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        OnAfterInitFromGenJnlLine(Rec, GenJnlLine);
    end;

    /// <summary>
    /// Copies key reference fields from a CV ledger entry buffer to establish parent-child relationship.
    /// Links the detailed entry to its parent ledger entry with currency and dimension information.
    /// </summary>
    /// <param name="CVLedgEntryBuf">Parent CV ledger entry buffer containing reference data</param>
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

    /// <summary>
    /// Initializes and inserts a complete detailed CV ledger entry buffer with specified amounts and application data.
    /// Creates fully populated detailed entry for payment applications, discounts, and tolerance scenarios.
    /// </summary>
    /// <param name="GenJnlLine">Source general journal line</param>
    /// <param name="CVLedgEntryBuf">Parent CV ledger entry buffer</param>
    /// <param name="DtldCVLedgEntryBuf">Detailed CV ledger entry buffer to initialize</param>
    /// <param name="EntryType">Type of detailed entry to create</param>
    /// <param name="AmountFCY">Amount in foreign currency</param>
    /// <param name="AmountLCY">Amount in local currency</param>
    /// <param name="AmountAddCurr">Amount in additional reporting currency</param>
    /// <param name="AppliedEntryNo">Entry number of applied ledger entry</param>
    /// <param name="RemainingPmtDiscPossible">Remaining payment discount available</param>
    /// <param name="MaxPaymentTolerance">Maximum payment tolerance amount</param>
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

    /// <summary>
    /// Finds the corresponding VAT entry for the detailed CV ledger entry using transaction number and posting groups.
    /// Used to link detailed entries with their related VAT transactions for reporting and analysis.
    /// </summary>
    /// <param name="VATEntry">VAT entry record to populate with found entry</param>
    /// <param name="TransactionNo">Transaction number to search for</param>
    procedure FindVATEntry(var VATEntry: Record "VAT Entry"; TransactionNo: Integer)
    begin
        VATEntry.Reset();
        VATEntry.SetCurrentKey("Transaction No.");
        VATEntry.SetRange("Transaction No.", TransactionNo);
        VATEntry.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
        VATEntry.FindFirst();
    end;

    /// <summary>
    /// Integration event raised after copying fields from a general journal line to the detailed CV ledger entry buffer.
    /// Enables customization of field mapping and additional data population from journal lines.
    /// </summary>
    /// <param name="DtldCVLedgEntryBuffer">Detailed CV ledger entry buffer being populated</param>
    /// <param name="GenJnlLine">Source general journal line</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromGenJnlLine(var DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after copying reference fields from a CV ledger entry buffer.
    /// Enables customization of field mapping and additional data population from parent ledger entries.
    /// </summary>
    /// <param name="DetailedCVLedgEntryBuffer">Detailed CV ledger entry buffer being populated</param>
    /// <param name="CVLedgerEntryBuffer">Source CV ledger entry buffer</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromCVLedgEntryBuf(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    /// <summary>
    /// Integration event raised after copying posting groups from a VAT entry.
    /// Enables customization of VAT-related posting group assignments and validation.
    /// </summary>
    /// <param name="DetailedCVLedgEntryBuffer">Detailed CV ledger entry buffer being updated</param>
    /// <param name="VATEntry">Source VAT entry with posting group information</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostingGroupsFromVATEntry(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; VATEntry: Record "VAT Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after initializing basic fields from a general journal line.
    /// Enables customization of initialization logic and additional field setup.
    /// </summary>
    /// <param name="DetailedCVLedgEntryBuffer">Detailed CV ledger entry buffer being initialized</param>
    /// <param name="GenJournalLine">Source general journal line</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromGenJnlLine(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after inserting a detailed CV ledger entry buffer record.
    /// Enables post-processing of inserted detailed entries and related buffer updates.
    /// </summary>
    /// <param name="DtldCVLedgEntryBuf">Current detailed CV ledger entry buffer</param>
    /// <param name="CVLedgEntryBuf">Parent CV ledger entry buffer</param>
    /// <param name="NewDtldCVLedgEntryBuf">Newly inserted detailed entry</param>
    /// <param name="NextDtldBufferEntryNo">Next available entry number for sequencing</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertDtldCVLedgEntry(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NextDtldBufferEntryNo: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a detailed CV ledger entry buffer in the initialization process.
    /// Enables custom validation and processing before detailed entry creation.
    /// </summary>
    /// <param name="DetailedCVLedgEntryBuffer">Detailed CV ledger entry buffer to be inserted</param>
    /// <param name="GenJournalLine">Source general journal line</param>
    /// <param name="IsHanled">Set to true to skip standard insertion logic</param>
    /// <param name="CVLedgerEntryBuffer">Parent CV ledger entry buffer</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDtldCVLedgEntry(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; GenJournalLine: Record "Gen. Journal Line"; var IsHanled: Boolean; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    /// <summary>
    /// Integration event raised before creating a detailed CV ledger entry buffer during consolidation.
    /// Enables custom logic for entry consolidation and duplicate detection.
    /// </summary>
    /// <param name="DtldCVLedgEntryBuf">Current detailed CV ledger entry buffer for comparison</param>
    /// <param name="NewDtldCVLedgEntryBuf">New detailed entry being processed</param>
    /// <param name="NextDtldBufferEntryNo">Next available entry number</param>
    /// <param name="IsHandled">Set to true to skip standard consolidation logic</param>
    /// <param name="CVLedgEntryBuf">Parent CV ledger entry buffer</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDtldCVLedgEntryBuf(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NewDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var NextDtldBufferEntryNo: Integer; var IsHandled: Boolean; var CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a new detailed CV ledger entry buffer record.
    /// Enables final validation and field modifications before database insertion.
    /// </summary>
    /// <param name="DetailedCVLedgEntryBuffer">Detailed CV ledger entry buffer about to be inserted</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertDtldCVLedgEntryOnBeforeInsert(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    /// <summary>
    /// Integration event raised before modifying an existing detailed CV ledger entry buffer during consolidation.
    /// Enables custom logic for amount aggregation and field updates in consolidated entries.
    /// </summary>
    /// <param name="DetailedCVLedgEntryBuffer">Existing detailed CV ledger entry buffer being modified</param>
    /// <param name="NewDtldCVLedgEntryBuf">New detailed entry being consolidated</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertDtldCVLedgEntryOnBeforeModify(var DetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; NewDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    /// <summary>
    /// Integration event raised before initializing a new detailed CV ledger entry buffer during the insertion process.
    /// Enables custom setup and field population before detailed entry processing begins.
    /// </summary>
    /// <param name="DtldCVLedgEntryBuf">Source detailed CV ledger entry buffer</param>
    /// <param name="CVLedgEntryBuf">Parent CV ledger entry buffer</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertDtldCVLedgEntryOnBeforeNewDtldCVLedgEntryBufInit(var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
    end;
}
