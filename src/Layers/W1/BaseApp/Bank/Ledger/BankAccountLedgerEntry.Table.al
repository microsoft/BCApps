// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Ledger;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Reconciliation;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.AuditCodes;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Security.AccessControl;

/// <summary>
/// Stores posted bank account transactions with full audit trail and reconciliation support.
/// Each entry represents a single bank account transaction with complete financial, dimensional,
/// and reconciliation information for tracking bank movements and statement matching.
/// </summary>
table 271 "Bank Account Ledger Entry"
{
    Caption = 'Bank Account Ledger Entry';
    DrillDownPageID = "Bank Account Ledger Entries";
    LookupPageID = "Bank Account Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique sequential identifier for each bank account ledger entry.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Bank account number this transaction is posted to.
        /// </summary>
        field(3; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        /// <summary>
        /// Date when the transaction was posted to the bank account ledger.
        /// </summary>
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        /// <summary>
        /// Type of document that generated this bank transaction (Payment, Invoice, etc.).
        /// </summary>
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        /// <summary>
        /// Document number that generated this bank account transaction.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        /// <summary>
        /// Description text explaining the nature of the bank transaction.
        /// </summary>
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Currency code for transactions in foreign currencies, blank for local currency.
        /// </summary>
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        /// <summary>
        /// Transaction amount in the original currency (positive for receipts, negative for payments).
        /// </summary>
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        /// <summary>
        /// Remaining amount available for application in bank reconciliation processes.
        /// </summary>
        field(14; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Amount';
        }
        /// <summary>
        /// Transaction amount converted to local currency for consolidated reporting.
        /// </summary>
        field(17; "Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        /// <summary>
        /// Bank account posting group for general ledger integration and account determination.
        /// </summary>
        field(22; "Bank Acc. Posting Group"; Code[20])
        {
            Caption = 'Bank Acc. Posting Group';
            TableRelation = "Bank Account Posting Group";
        }
        /// <summary>
        /// First global dimension value for multi-dimensional analysis and reporting.
        /// </summary>
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Second global dimension value for multi-dimensional analysis and reporting.
        /// </summary>
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// Salesperson or purchaser code associated with this bank transaction.
        /// </summary>
        field(25; "Our Contact Code"; Code[20])
        {
            Caption = 'Our Contact Code';
            TableRelation = "Salesperson/Purchaser";
        }
        /// <summary>
        /// User ID of the person who posted this bank account ledger entry.
        /// </summary>
        field(27; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// Source code identifying the process that created this bank account entry.
        /// </summary>
        field(28; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        /// <summary>
        /// Indicates whether this bank account ledger entry is still open for application.
        /// </summary>
        field(36; Open; Boolean)
        {
            Caption = 'Open';
        }
        /// <summary>
        /// Indicates whether the transaction amount is positive (receipts) or negative (payments).
        /// </summary>
        field(43; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        /// <summary>
        /// Entry number of the bank account ledger entry that closed this entry.
        /// </summary>
        field(44; "Closed by Entry No."; Integer)
        {
            Caption = 'Closed by Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        /// <summary>
        /// Date when this bank account ledger entry was closed.
        /// </summary>
        field(45; "Closed at Date"; Date)
        {
            Caption = 'Closed at Date';
        }
        /// <summary>
        /// Journal template name used when posting this bank account transaction.
        /// </summary>
        field(48; "Journal Templ. Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        /// <summary>
        /// Journal batch name used when posting this bank account transaction.
        /// </summary>
        field(49; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        /// <summary>
        /// Reason code explaining why this bank account transaction was posted.
        /// </summary>
        field(50; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// Type of the balancing account used in the original transaction.
        /// </summary>
        field(51; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        /// <summary>
        /// Number of the balancing account used in the original transaction.
        /// </summary>
        field(52; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const(Customer)) Customer
            else
            if ("Bal. Account Type" = const(Vendor)) Vendor
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Bal. Account Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Bal. Account Type" = const(Employee)) Employee;
        }
        /// <summary>
        /// Transaction number linking this entry to other general ledger entries in the same posting transaction.
        /// </summary>
        field(53; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        /// <summary>
        /// Status indicating whether this entry has been applied to bank statement lines during reconciliation.
        /// </summary>
        field(55; "Statement Status"; Option)
        {
            Caption = 'Statement Status';
            OptionCaption = 'Open,Bank Acc. Entry Applied,Check Entry Applied,Closed';
            OptionMembers = Open,"Bank Acc. Entry Applied","Check Entry Applied",Closed;
        }
        /// <summary>
        /// Bank statement number this entry has been applied to during reconciliation.
        /// </summary>
        field(56; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Bank Acc. Reconciliation Line"."Statement No." where("Bank Account No." = field("Bank Account No."));
        }
        /// <summary>
        /// Line number on the bank statement this entry has been applied to during reconciliation.
        /// </summary>
        field(57; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
            TableRelation = "Bank Acc. Reconciliation Line"."Statement Line No." where("Bank Account No." = field("Bank Account No."),
                                                                                        "Statement No." = field("Statement No."));
        }
        /// <summary>
        /// Debit amount in the original currency for positive transactions.
        /// </summary>
        field(58; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
        }
        /// <summary>
        /// Credit amount in the original currency for negative transactions.
        /// </summary>
        field(59; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
        }
        /// <summary>
        /// Debit amount in local currency for positive transactions.
        /// </summary>
        field(60; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount (LCY)';
        }
        /// <summary>
        /// Credit amount in local currency for negative transactions.
        /// </summary>
        field(61; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount (LCY)';
        }
        /// <summary>
        /// Document date from the original source document that generated this bank transaction.
        /// </summary>
        field(62; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ClosingDates = true;
        }
        /// <summary>
        /// External document number from the source that generated this bank transaction.
        /// </summary>
        field(63; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        /// <summary>
        /// Indicates whether this bank account ledger entry has been reversed.
        /// </summary>
        field(64; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        /// <summary>
        /// Entry number of the bank account ledger entry that reversed this entry.
        /// </summary>
        field(65; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        /// <summary>
        /// Entry number of the original bank account ledger entry that this entry reverses.
        /// </summary>
        field(66; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        /// <summary>
        /// Count of check ledger entries associated with this bank account ledger entry.
        /// </summary>
        field(70; "Check Ledger Entries"; Integer)
        {
            CalcFormula = count("Check Ledger Entry" where("Bank Account Ledger Entry No." = field("Entry No.")));
            Caption = 'Check Ledger Entries';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Dimension set ID linking this entry to its dimension values for multi-dimensional analysis.
        /// </summary>
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        /// <summary>
        /// Third global dimension value retrieved from dimension set for reporting and analysis.
        /// </summary>
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        /// <summary>
        /// Fourth global dimension value retrieved from dimension set for reporting and analysis.
        /// </summary>
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        /// <summary>
        /// Fifth global dimension value retrieved from dimension set for reporting and analysis.
        /// </summary>
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        /// <summary>
        /// Sixth global dimension value retrieved from dimension set for reporting and analysis.
        /// </summary>
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        /// <summary>
        /// Seventh global dimension value retrieved from dimension set for reporting and analysis.
        /// </summary>
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        /// <summary>
        /// Eighth global dimension value retrieved from dimension set for reporting and analysis.
        /// </summary>
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.", "Posting Date")
        {
            SumIndexFields = Amount, "Amount (LCY)", "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)";
        }
        key(Key3; "Bank Account No.", Open, "Posting Date", "Statement No.", "Statement Status", "Statement Line No.")
        {
        }
        key(Key4; "Document Type", "Bank Account No.", "Posting Date")
        {
            MaintainSQLIndex = false;
            SumIndexFields = Amount;
        }
        key(Key5; "Document No.", "Posting Date")
        {
        }
        key(Key6; "Transaction No.")
        {
        }
        key(Key7; "Bank Account No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "Posting Date")
        {
            Enabled = false;
            SumIndexFields = Amount, "Amount (LCY)", "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)";
        }
        key(key8; "Statement No.", "Statement Line No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "Bank Account No.", "Posting Date", "Document Type", "Document No.")
        {
        }
    }
    trigger OnInsert()
    begin
        UpdateBankAccReconciliationLine();
    end;

    var
        DimMgt: Codeunit DimensionManagement;

    /// <summary>
    /// Opens the dimension management page to display dimensions associated with this entry.
    /// </summary>
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;

    /// <summary>
    /// Copies field values from a general journal line to populate this bank account ledger entry.
    /// Transfers standard fields and dimensions, then raises integration event for customization.
    /// </summary>
    /// <param name="GenJnlLine">Source general journal line to copy field values from.</param>
    procedure CopyFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        "Bank Account No." := GenJnlLine."Account No.";
        "Posting Date" := GenJnlLine."Posting Date";
        "Document Date" := GenJnlLine."Document Date";
        "Document Type" := GenJnlLine."Document Type";
        "Document No." := GenJnlLine."Document No.";
        "External Document No." := GenJnlLine."External Document No.";
        Description := GenJnlLine.Description;
        "Global Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := GenJnlLine."Dimension Set ID";
        "Our Contact Code" := GenJnlLine."Salespers./Purch. Code";
        "Source Code" := GenJnlLine."Source Code";
        "Journal Templ. Name" := GenJnlLine."Journal Template Name";
        "Journal Batch Name" := GenJnlLine."Journal Batch Name";
        "Reason Code" := GenJnlLine."Reason Code";
        "Currency Code" := GenJnlLine."Currency Code";
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Bal. Account Type" := GenJnlLine."Bal. Account Type";
        "Bal. Account No." := GenJnlLine."Bal. Account No.";
        if GenJnlLine."Linked Table ID" <> 0 then
            SetBankAccReconciliationLine(GenJnlLine);

        OnAfterCopyFromGenJnlLine(Rec, GenJnlLine);
    end;

    local procedure SetBankAccReconciliationLine(GenJnlLine: Record "Gen. Journal Line")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        if GenJnlLine."Linked Table ID" <> Database::"Bank Acc. Reconciliation Line" then
            exit;
        if IsNullGuid(GenJnlLine."Linked System ID") then
            exit;
        if not BankAccReconciliationLine.GetBySystemId(GenJnlLine."Linked System ID") then
            exit;
        if "Bank Account No." <> BankAccReconciliationLine."Bank Account No." then
            exit;
        "Statement Status" := "Statement Status"::"Bank Acc. Entry Applied";
        "Statement No." := BankAccReconciliationLine."Statement No.";
        "Statement Line No." := BankAccReconciliationLine."Statement Line No.";
    end;

    local procedure UpdateBankAccReconciliationLine()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        if "Statement No." = '' then
            exit;
        if not BankAccReconciliationLine.Get(BankAccReconciliationLine."Statement Type"::"Bank Reconciliation", "Bank Account No.", "Statement No.", "Statement Line No.") then
            exit;
        if (BankAccReconciliationLine."Statement Amount" = Amount) or (BankAccReconciliationLine.Difference = Amount) then begin
            BankAccReconciliationLine."Applied Amount" += Amount;
            BankAccReconciliationLine.Difference := BankAccReconciliationLine."Statement Amount" - BankAccReconciliationLine."Applied Amount";
            BankAccReconciliationLine."Applied Entries" += 1;
            BankAccReconciliationLine.Modify();
        end else begin
            "Statement Status" := "Statement Status"::Open;
            "Statement No." := '';
            "Statement Line No." := 0;
        end;
    end;

    /// <summary>
    /// Updates the debit and credit amount fields based on the transaction amount and correction flag.
    /// Positive amounts become debits, negative amounts become credits, with correction logic applied.
    /// </summary>
    /// <param name="Correction">Indicates whether this is a correction entry that reverses normal debit/credit logic.</param>
    procedure UpdateDebitCredit(Correction: Boolean)
    begin
        if (Amount > 0) and (not Correction) or
           (Amount < 0) and Correction
        then begin
            "Debit Amount" := Amount;
            "Credit Amount" := 0;
            "Debit Amount (LCY)" := "Amount (LCY)";
            "Credit Amount (LCY)" := 0;
        end else begin
            "Debit Amount" := 0;
            "Credit Amount" := -Amount;
            "Debit Amount (LCY)" := 0;
            "Credit Amount (LCY)" := -"Amount (LCY)";
        end;

        OnAfterUpdateDebitCredit(Rec, Correction);
    end;

    /// <summary>
    /// Retrieves the statement number associated with this entry if it has been applied to a bank statement.
    /// Checks for applied check entries or direct bank account entry application status.
    /// </summary>
    /// <returns>Statement number if the entry is applied, empty string otherwise.</returns>
    procedure GetAppliedStatementNo(): Code[20]
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        if ((Rec."Statement Status" = Rec."Statement Status"::"Bank Acc. Entry Applied") and
           (Rec."Statement No." <> '') and (Rec."Statement Line No." <> 0)) then
            exit(Rec."Statement No.");
        CheckLedgerEntry.SetLoadFields("Statement No.");
        CheckLedgerEntry.SetCurrentKey("Bank Account Ledger Entry No.");
        CheckLedgerEntry.SetRange("Bank Account Ledger Entry No.", Rec."Entry No.");
        CheckLedgerEntry.SetRange("Bank Account No.", Rec."Bank Account No.");
        CheckLedgerEntry.SetRange(Open, true);
        CheckLedgerEntry.SetRange("Statement Status", CheckLedgerEntry."Statement Status"::"Check Entry Applied");
        CheckLedgerEntry.SetFilter("Statement No.", '<>%1', '');
        CheckLedgerEntry.SetFilter("Statement Line No.", '<>%1', 0);
        if CheckLedgerEntry.FindFirst() then
            exit(CheckLedgerEntry."Statement No.");
        exit('');
    end;

    /// <summary>
    /// Determines whether this bank account ledger entry has been applied to a bank statement.
    /// </summary>
    /// <returns>True if the entry is applied to a statement, false otherwise.</returns>
    procedure IsApplied(): Boolean
    begin
        exit(GetAppliedStatementNo() <> '');
    end;

    /// <summary>
    /// Determines the visual style to apply to this entry in list displays.
    /// Applied entries receive favorable styling to indicate their reconciled status.
    /// </summary>
    /// <returns>Style name for applied entries ("Favorable"), empty string for unapplied entries.</returns>
    procedure SetStyle(): Text
    begin
        if IsApplied() then
            exit('Favorable');

        exit('');
    end;

    /// <summary>
    /// Applies filters to show only open entries for a specific bank account.
    /// Resets all existing filters and sets up optimized key and filtering for open entry retrieval.
    /// </summary>
    /// <param name="BankAccNo">Bank account number to filter by.</param>
    procedure SetFilterBankAccNoOpen(BankAccNo: Code[20])
    begin
        Reset();
        SetCurrentKey("Bank Account No.", Open);
        SetRange("Bank Account No.", BankAccNo);
        SetRange(Open, true);
    end;

    /// <summary>
    /// Creates a new bank account ledger entry by copying key fields from an existing entry.
    /// Used for creating related entries with specific statement association during reconciliation processes.
    /// </summary>
    /// <param name="BankAccountLedgerEntry">Source bank account ledger entry to copy from.</param>
    /// <param name="StatementNo">Statement number to assign to the new entry.</param>
    procedure CopyFromBankAccLedgerEntry(BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; StatementNo: Code[20])
    begin
        Init();
        "Entry No." := BankAccountLedgerEntry."Entry No.";
        "Posting Date" := BankAccountLedgerEntry."Posting Date";
        "Document Type" := BankAccountLedgerEntry."Document Type";
        "Document No." := BankAccountLedgerEntry."Document No.";
        "Bank Account No." := BankAccountLedgerEntry."Bank Account No.";
        Description := BankAccountLedgerEntry.Description;
        Amount := BankAccountLedgerEntry.Amount;
        "Statement No." := StatementNo;
        Insert();
    end;

    /// <summary>
    /// Sets filters on the record to find potential candidates for bank reconciliation matching.
    /// Filters for open, non-reversed entries with remaining amounts within the reconciliation date range.
    /// </summary>
    /// <param name="BankAccReconciliation">Bank reconciliation record providing filtering criteria.</param>
    procedure SetBankReconciliationCandidatesFilter(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        FilterDate: Date;
    begin
        Rec.Reset();
        Rec.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        Rec.SetRange("Statement Status", Rec."Statement Status"::Open);
        Rec.SetFilter("Remaining Amount", '<>%1', 0);
        Rec.SetRange("Reversed", false); // PR 30730

        FilterDate := BankAccReconciliation.MatchCandidateFilterDate();
        if FilterDate <> 0D then
            Rec.SetFilter("Posting Date", '<=%1', FilterDate);

        // Records sorted by posting date to optimize matching
        Rec.SetCurrentKey("Posting Date");
        Rec.SetAscending("Posting Date", true);

        OnAfterSetBankReconciliationCandidatesFilter(Rec);
    end;

    /// <summary>
    /// Integration event raised after copying field values from a general journal line.
    /// Allows subscribers to customize or extend the field transfer process.
    /// </summary>
    /// <param name="BankAccountLedgerEntry">Bank account ledger entry being populated with journal line data.</param>
    /// <param name="GenJournalLine">Source general journal line providing the data.</param>
    [IntegrationEvent(false, false)]
    procedure OnAfterCopyFromGenJnlLine(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after updating debit and credit amount fields.
    /// Allows subscribers to customize debit/credit calculation logic or add additional processing.
    /// </summary>
    /// <param name="BankAccountLedgerEntry">Bank account ledger entry with updated debit/credit amounts.</param>
    /// <param name="Correction">Indicates whether this is a correction entry affecting debit/credit logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDebitCredit(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; Correction: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after setting filters for bank reconciliation candidates.
    /// Allows subscribers to modify or extend the filtering criteria for reconciliation matching.
    /// </summary>
    /// <param name="BankAccountLedgerEntry">Bank account ledger entry with filters applied for reconciliation matching.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetBankReconciliationCandidatesFilter(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;
}
