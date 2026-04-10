// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Security.AccessControl;
using System.Security.User;

/// <summary>
/// Stores detailed sub-ledger entries for customer transactions, including payment applications, currency adjustments, payment tolerances, and discounts.
/// </summary>
table 379 "Detailed Cust. Ledg. Entry"
{
    Caption = 'Detailed Cust. Ledg. Entry';
    DataCaptionFields = "Customer No.";
    DrillDownPageID = "Detailed Cust. Ledg. Entries";
    LookupPageID = "Detailed Cust. Ledg. Entries";
    Permissions = TableData "Detailed Cust. Ledg. Entry" = m;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique sequential number assigned to this detailed customer ledger entry.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        /// <summary>
        /// Specifies the parent customer ledger entry that this detailed entry belongs to.
        /// </summary>
        field(2; "Cust. Ledger Entry No."; Integer)
        {
            Caption = 'Cust. Ledger Entry No.';
            TableRelation = "Cust. Ledger Entry";
            ToolTip = 'Specifies the entry number of the customer ledger entry that the detailed customer ledger entry line was created for.';
        }
        /// <summary>
        /// Specifies the type of transaction such as Initial Entry, Application, Payment Discount, or Currency Adjustment.
        /// </summary>
        field(3; "Entry Type"; Enum "Detailed CV Ledger Entry Type")
        {
            Caption = 'Entry Type';
            ToolTip = 'Specifies the entry type of the detailed customer ledger entry.';
        }
        /// <summary>
        /// Specifies the date when this detailed entry was posted to the ledger.
        /// </summary>
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date of the detailed customer ledger entry.';
        }
        /// <summary>
        /// Specifies the type of source document such as Invoice, Credit Memo, or Payment.
        /// </summary>
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the document type of the detailed customer ledger entry.';
        }
        /// <summary>
        /// Specifies the document number of the source transaction that created this entry.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number of the transaction that created the entry.';
        }
        /// <summary>
        /// Stores the transaction amount in the original currency for this detailed entry.
        /// </summary>
        field(7; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            ToolTip = 'Specifies the amount of the detailed customer ledger entry.';
        }
        /// <summary>
        /// Stores the transaction amount expressed in the local currency.
        /// </summary>
        field(8; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount (LCY)';
            ToolTip = 'Specifies the amount of the entry in LCY.';
        }
        /// <summary>
        /// Specifies the customer account associated with this detailed entry.
        /// </summary>
        field(9; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
            ToolTip = 'Specifies the customer account number to which the entry is posted.';
        }
        /// <summary>
        /// Specifies the currency in which the transaction amount is expressed.
        /// </summary>
        field(10; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
            ToolTip = 'Specifies the code for the currency if the amount is in a foreign currency.';
        }
        /// <summary>
        /// Specifies the user who created or posted this detailed entry.
        /// </summary>
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        /// <summary>
        /// Specifies the source code identifying where the transaction originated.
        /// </summary>
        field(12; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
            ToolTip = 'Specifies the source code that specifies where the entry was created.';
        }
        /// <summary>
        /// Specifies the transaction number that groups all entries from the same posting operation.
        /// </summary>
        field(13; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        /// <summary>
        /// Specifies the journal batch from which this entry was posted.
        /// </summary>
        field(14; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        /// <summary>
        /// Specifies a supplementary code providing additional context about the transaction purpose.
        /// </summary>
        field(15; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
            ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
        }
        /// <summary>
        /// Stores the debit portion of the amount in the original currency.
        /// </summary>
        field(16; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
            ToolTip = 'Specifies the total of the ledger entries that represent debits.';
        }
        /// <summary>
        /// Stores the credit portion of the amount in the original currency.
        /// </summary>
        field(17; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
            ToolTip = 'Specifies the total of the ledger entries that represent credits.';
        }
        /// <summary>
        /// Stores the debit portion of the amount in local currency.
        /// </summary>
        field(18; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Debit Amount (LCY)';
            ToolTip = 'Specifies the total of the ledger entries that represent debits, expressed in LCY.';
        }
        /// <summary>
        /// Stores the credit portion of the amount in local currency.
        /// </summary>
        field(19; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Credit Amount (LCY)';
            ToolTip = 'Specifies the total of the ledger entries that represent credits, expressed in LCY.';
        }
        /// <summary>
        /// Stores the due date from the original customer ledger entry for filtering and reporting.
        /// </summary>
        field(20; "Initial Entry Due Date"; Date)
        {
            Caption = 'Initial Entry Due Date';
            ToolTip = 'Specifies the date on which the initial entry is due for payment.';
        }
        /// <summary>
        /// Stores the first global dimension from the original customer ledger entry for analysis.
        /// </summary>
        field(21; "Initial Entry Global Dim. 1"; Code[20])
        {
            Caption = 'Initial Entry Global Dim. 1';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
            ToolTip = 'Specifies the Global Dimension 1 code of the initial customer ledger entry.';
        }
        /// <summary>
        /// Stores the second global dimension from the original customer ledger entry for analysis.
        /// </summary>
        field(22; "Initial Entry Global Dim. 2"; Code[20])
        {
            Caption = 'Initial Entry Global Dim. 2';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
            ToolTip = 'Specifies the Global Dimension 2 code of the initial customer ledger entry.';
        }
        /// <summary>
        /// Specifies the general business posting group used for determining accounts in the posting process.
        /// </summary>
        field(24; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// Specifies the general product posting group used for determining accounts in the posting process.
        /// </summary>
        field(25; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// Indicates whether use tax applies to this entry for US and Canadian tax jurisdictions.
        /// </summary>
        field(29; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        /// <summary>
        /// Specifies the VAT business posting group for VAT calculation purposes.
        /// </summary>
        field(30; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// Specifies the VAT product posting group for VAT calculation purposes.
        /// </summary>
        field(31; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Stores the document type from the original customer ledger entry for filtering and reporting.
        /// </summary>
        field(35; "Initial Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Initial Document Type';
            ToolTip = 'Specifies the document type that the initial customer ledger entry was created with.';
        }
        /// <summary>
        /// Specifies the customer ledger entry number to which this entry was applied during payment application.
        /// </summary>
        field(36; "Applied Cust. Ledger Entry No."; Integer)
        {
            Caption = 'Applied Cust. Ledger Entry No.';
        }
        /// <summary>
        /// Indicates whether this entry has been reversed through an unapplication process.
        /// </summary>
        field(37; Unapplied; Boolean)
        {
            Caption = 'Unapplied';
            ToolTip = 'Specifies whether the entry has been unapplied (undone) from the Unapply Customer Entries window by the entry no. shown in the Unapplied by Entry No. field.';
        }
        /// <summary>
        /// Specifies the entry number of the correcting entry that unapplied this original entry.
        /// </summary>
        field(38; "Unapplied by Entry No."; Integer)
        {
            Caption = 'Unapplied by Entry No.';
            TableRelation = "Detailed Cust. Ledg. Entry";
            ToolTip = 'Specifies the number of the correcting entry, if the original entry has been unapplied (undone) from the Unapply Customer Entries window.';
        }
        /// <summary>
        /// Stores the remaining payment discount that can still be granted for early payment.
        /// </summary>
        field(39; "Remaining Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Pmt. Disc. Possible';
        }
        /// <summary>
        /// Stores the maximum payment tolerance amount allowed when applying this entry.
        /// </summary>
        field(40; "Max. Payment Tolerance"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Max. Payment Tolerance';
        }
        /// <summary>
        /// Specifies the tax jurisdiction code for US and Canadian sales tax calculations.
        /// </summary>
        field(41; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            Editable = false;
            TableRelation = "Tax Jurisdiction";
        }
        /// <summary>
        /// Specifies the application number that groups all entries from the same application operation.
        /// </summary>
        field(42; "Application No."; Integer)
        {
            Caption = 'Application No.';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether this entry affects the ledger entry balance, excluding application entries.
        /// </summary>
        field(43; "Ledger Entry Amount"; Boolean)
        {
            Caption = 'Ledger Entry Amount';
            Editable = false;
        }
        /// <summary>
        /// Specifies the customer posting group that determines the receivables account used for posting.
        /// </summary>
        field(44; "Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            Editable = false;
            TableRelation = "Customer Posting Group";
            ToolTip = 'Specifies the customer''s market type to link business transactions to.';
        }
        /// <summary>
        /// Links this entry to the exchange rate adjustment register when created by currency adjustment.
        /// </summary>
        field(45; "Exch. Rate Adjmt. Reg. No."; Integer)
        {
            Caption = 'Exch. Rate Adjmt. Reg. No.';
            Editable = false;
            TableRelation = "Exch. Rate Adjmt. Reg.";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Customer No.", "Currency Code")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key3; "Cust. Ledger Entry No.", "Entry Type", "Posting Date")
        {
            IncludedFields = "Ledger Entry Amount", Amount, "Amount (LCY)", "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)";
        }
        key(Key5; "Initial Document Type", "Entry Type", "Customer No.", "Currency Code", "Initial Entry Global Dim. 1", "Initial Entry Global Dim. 2", "Posting Date")
        {
            IncludedFields = Amount, "Amount (LCY)";
        }
        key(Key6; "Customer No.", "Currency Code", "Initial Entry Global Dim. 1", "Initial Entry Global Dim. 2", "Initial Entry Due Date", "Posting Date")
        {
            IncludedFields = Amount, "Amount (LCY)";
        }
        key(Key7; "Document No.", "Document Type", "Posting Date")
        {
        }
        key(Key8; "Applied Cust. Ledger Entry No.", "Entry Type")
        {
        }
        key(Key9; "Transaction No.", "Customer No.", "Entry Type")
        {
        }
        key(Key10; "Application No.", "Customer No.", "Entry Type")
        {
        }
        key(Key11; "Customer No.", "Entry Type", "Posting Date", "Initial Document Type")
        {
            IncludedFields = Amount, "Amount (LCY)", "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)";
        }
        key(Key12; "Document Type")
        {
            SumIndexFields = "Amount (LCY)";
        }
        key(Key13; "Initial Document Type", "Initial Entry Due Date")
        {
            SumIndexFields = "Amount (LCY)";
        }
        key(Key14; "Customer No.", "Initial Entry Due Date")
        {
            IncludedFields = Amount, "Amount (LCY)";
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Cust. Ledger Entry No.", "Customer No.", "Posting Date", "Document Type", "Document No.")
        {
        }
    }

    trigger OnInsert()
    begin
        SetLedgerEntryAmount();
    end;

    /// <summary>
    /// Gets the entry number of the last detailed customer ledger entry in the table.
    /// </summary>
    /// <returns>The entry number of the last detailed customer ledger entry.</returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Detailed Cust. Ledg. Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    /// <summary>
    /// Updates the debit and credit amounts based on the sign of the amount and correction flag.
    /// </summary>
    /// <param name="Correction">Indicates whether this is a correction entry that reverses the normal debit/credit assignment.</param>
    procedure UpdateDebitCredit(Correction: Boolean)
    begin
        if ((Amount > 0) or ("Amount (LCY)" > 0)) and not Correction or
           ((Amount < 0) or ("Amount (LCY)" < 0)) and Correction
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
    /// Sets the transaction number to zero and assigns an application number for all entries with the specified transaction number.
    /// </summary>
    /// <param name="TransactionNo">The transaction number to reset to zero.</param>
    procedure SetZeroTransNo(TransactionNo: Integer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplicationNo: Integer;
    begin
        DetailedCustLedgEntry.SetCurrentKey("Transaction No.");
        DetailedCustLedgEntry.SetRange("Transaction No.", TransactionNo);
        if DetailedCustLedgEntry.FindSet(true) then begin
            ApplicationNo := DetailedCustLedgEntry."Entry No.";
            repeat
                DetailedCustLedgEntry."Transaction No." := 0;
                DetailedCustLedgEntry."Application No." := ApplicationNo;
                OnSetZeroTransNoOnBeforeDetailedCustLedgEntryModify(DetailedCustLedgEntry);
                DetailedCustLedgEntry.Modify();
            until DetailedCustLedgEntry.Next() = 0;
        end;
    end;

    local procedure SetLedgerEntryAmount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetLedgerEntryAmount(Rec, IsHandled);
        if IsHandled then
            exit;

        "Ledger Entry Amount" :=
            not (("Entry Type" = "Entry Type"::Application) or ("Entry Type" = "Entry Type"::"Appln. Rounding"));
    end;

    /// <summary>
    /// Calculates the sum of unrealized gain and loss amounts for a customer ledger entry.
    /// </summary>
    /// <param name="EntryNo">The customer ledger entry number to calculate unrealized gain/loss for.</param>
    /// <returns>The total unrealized gain/loss amount in local currency.</returns>
    procedure GetUnrealizedGainLossAmount(EntryNo: Integer): Decimal
    begin
        SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
        SetRange("Cust. Ledger Entry No.", EntryNo);
        SetRange("Entry Type", "Entry Type"::"Unrealized Loss", "Entry Type"::"Unrealized Gain");
        CalcSums("Amount (LCY)");
        exit("Amount (LCY)");
    end;

    /// <summary>
    /// Raised before setting the Ledger Entry Amount flag to allow custom logic.
    /// </summary>
    /// <param name="DetailedCustLedgEntry">The detailed customer ledger entry.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetLedgerEntryAmount(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after updating the debit and credit amounts on the entry.
    /// </summary>
    /// <param name="DetailedCustLedgEntry">The detailed customer ledger entry with updated debit/credit amounts.</param>
    /// <param name="Correction">Indicates whether this is a correction entry.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDebitCredit(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; Correction: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before modifying the detailed customer ledger entry when setting transaction number to zero.
    /// </summary>
    /// <param name="DetailedCustLedgEntry">The detailed customer ledger entry being modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnSetZeroTransNoOnBeforeDetailedCustLedgEntryModify(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;
}

