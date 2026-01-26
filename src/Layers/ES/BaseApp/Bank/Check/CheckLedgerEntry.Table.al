// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Check;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.PositivePay;
using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;
using System.Security.AccessControl;

/// <summary>
/// Tracks the lifecycle and status of physical and electronic checks issued from bank accounts.
/// Maintains complete audit trail from creation through voiding with bank reconciliation support.
/// </summary>
/// <remarks>
/// Integrates with Bank Account Ledger Entry, Bank Account Reconciliation, and Positive Pay functionality.
/// Supports check printing, electronic payment transmission, and financial voiding processes.
/// Extensible through OnAfterCopyFromBankAccLedgEntry and OnAfterGetPayee events.
/// </remarks>
table 272 "Check Ledger Entry"
{
    Caption = 'Check Ledger Entry';
    DrillDownPageID = "Check Ledger Entries";
    LookupPageID = "Check Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique sequential identifier for the check ledger entry.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Bank account from which the check was issued or payment was made.
        /// </summary>
        field(2; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        /// <summary>
        /// Reference to the corresponding bank account ledger entry that created this check.
        /// </summary>
        field(3; "Bank Account Ledger Entry No."; Integer)
        {
            Caption = 'Bank Account Ledger Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        /// <summary>
        /// Date when the check transaction was posted to the general ledger.
        /// </summary>
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        /// <summary>
        /// Type of document that generated the check (typically Payment or Refund).
        /// </summary>
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        /// <summary>
        /// Document number associated with the check transaction.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        /// <summary>
        /// Descriptive text explaining the purpose or payee of the check.
        /// </summary>
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Amount of the check in the bank account's currency.
        /// </summary>
        field(8; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromBank();
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        /// <summary>
        /// Date printed or written on the physical check.
        /// </summary>
        field(9; "Check Date"; Date)
        {
            Caption = 'Check Date';
        }
        /// <summary>
        /// Check number as printed on the physical check or assigned for electronic payments.
        /// </summary>
        field(10; "Check No."; Code[20])
        {
            Caption = 'Check No.';
        }
        /// <summary>
        /// Indicates whether this represents a complete check or partial check payment.
        /// </summary>
        field(11; "Check Type"; Option)
        {
            Caption = 'Check Type';
            OptionCaption = 'Total Check,Partial Check';
            OptionMembers = "Total Check","Partial Check";
        }
        /// <summary>
        /// Method of payment transmission (Manual Check, Computer Check, Electronic Payment).
        /// </summary>
        field(12; "Bank Payment Type"; Enum "Bank Payment Type")
        {
            Caption = 'Bank Payment Type';
        }
        /// <summary>
        /// Current lifecycle status of the check from creation through final disposition.
        /// </summary>
        field(13; "Entry Status"; Option)
        {
            Caption = 'Entry Status';
            OptionCaption = ',Printed,Voided,Posted,Financially Voided,Test Print,Exported,Transmitted';
            OptionMembers = ,Printed,Voided,Posted,"Financially Voided","Test Print",Exported,Transmitted;
        }
        /// <summary>
        /// Original status before any voiding or status changes occurred.
        /// </summary>
        field(14; "Original Entry Status"; Option)
        {
            Caption = 'Original Entry Status';
            OptionCaption = ' ,Printed,Voided,Posted,Financially Voided,,,Exported';
            OptionMembers = " ",Printed,Voided,Posted,"Financially Voided",,,Exported;
        }
        /// <summary>
        /// Type of account being paid (Vendor, Customer, G/L Account, etc.).
        /// </summary>
        field(15; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        /// <summary>
        /// Account number of the payee receiving the check payment.
        /// </summary>
        field(16; "Bal. Account No."; Code[20])
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
            if ("Bal. Account Type" = const("Fixed Asset")) "Fixed Asset";
        }
        /// <summary>
        /// Indicates whether the check entry has outstanding amounts requiring reconciliation.
        /// </summary>
        field(17; Open; Boolean)
        {
            Caption = 'Open';
        }
        /// <summary>
        /// Status of check reconciliation with bank statements.
        /// </summary>
        field(18; "Statement Status"; Option)
        {
            Caption = 'Statement Status';
            OptionCaption = 'Open,Bank Acc. Entry Applied,Check Entry Applied,Closed';
            OptionMembers = Open,"Bank Acc. Entry Applied","Check Entry Applied",Closed;
        }
        /// <summary>
        /// Bank statement number where this check was reconciled.
        /// </summary>
        field(19; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Bank Acc. Reconciliation Line"."Statement No." where("Bank Account No." = field("Bank Account No."));
        }
        /// <summary>
        /// Line number within the bank statement where this check appears.
        /// </summary>
        field(20; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
            TableRelation = "Bank Acc. Reconciliation Line"."Statement Line No." where("Bank Account No." = field("Bank Account No."),
                                                                                        "Statement No." = field("Statement No."));
        }
        /// <summary>
        /// User who last modified the check ledger entry.
        /// </summary>
        field(21; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// External reference number from the original source document.
        /// </summary>
        field(22; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        /// <summary>
        /// Reference to data exchange entry for electronic payment processing.
        /// </summary>
        field(23; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        /// <summary>
        /// Reference to data exchange entry used when voiding electronic payments.
        /// </summary>
        field(24; "Data Exch. Voided Entry No."; Integer)
        {
            Caption = 'Data Exch. Voided Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        /// <summary>
        /// Indicates whether check information has been exported for positive pay file.
        /// </summary>
        field(25; "Positive Pay Exported"; Boolean)
        {
            Caption = 'Positive Pay Exported';
        }
#if not CLEANSCHEMA27
        field(26; "Record ID to Print"; RecordId)
        {
            Caption = 'Record ID to Print';
            DataClassification = SystemMetadata;
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Print Gen Jnl Line SystemId field';
            ObsoleteTag = '27.0';
        }
#endif
        /// <summary>
        /// SystemId reference to the General Journal Line used for check printing operations.
        /// </summary>
        field(27; "Print Gen Jnl Line SystemId"; Guid)
        {
            Caption = 'SystemId to Print';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.", "Check Date")
        {
        }
        key(Key3; "Bank Account No.", "Entry Status", "Check No.", "Statement Status")
        {
        }
        key(Key4; "Bank Account Ledger Entry No.")
        {
        }
        key(Key5; "Bank Account No.", Open)
        {
        }
        key(Key6; "Document No.", "Posting Date")
        {
        }
        key(Key7; "Print Gen Jnl Line SystemId")
        {
        }
    }

    fieldgroups
    {
    }

    var
        NothingToExportErr: Label 'There is nothing to export.';

    /// <summary>
    /// Retrieves the currency code from the associated bank account for formatting amounts.
    /// </summary>
    /// <returns>Currency code from the bank account, or empty string if not found</returns>
    procedure GetCurrencyCodeFromBank(): Code[10]
    var
        BankAcc: Record "Bank Account";
    begin
        if "Bank Account No." = BankAcc."No." then
            exit(BankAcc."Currency Code");

        if BankAcc.Get("Bank Account No.") then
            exit(BankAcc."Currency Code");

        exit('');
    end;

    /// <summary>
    /// Initializes check ledger entry fields from corresponding bank account ledger entry data.
    /// Sets default values for check-specific fields and status information.
    /// </summary>
    /// <param name="BankAccLedgEntry">Source bank account ledger entry to copy data from</param>
    procedure CopyFromBankAccLedgEntry(BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
        "Bank Account No." := BankAccLedgEntry."Bank Account No.";
        "Bank Account Ledger Entry No." := BankAccLedgEntry."Entry No.";
        "Posting Date" := BankAccLedgEntry."Posting Date";
        "Document Type" := BankAccLedgEntry."Document Type";
        "Document No." := BankAccLedgEntry."Document No.";
        "External Document No." := BankAccLedgEntry."External Document No.";
        Description := BankAccLedgEntry.Description;
        "Bal. Account Type" := BankAccLedgEntry."Bal. Account Type";
        "Bal. Account No." := BankAccLedgEntry."Bal. Account No.";
        "Entry Status" := "Entry Status"::Posted;
        Open := true;
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Check Date" := BankAccLedgEntry."Posting Date";
        "Check No." := BankAccLedgEntry."Document No.";

        OnAfterCopyFromBankAccLedgEntry(Rec, BankAccLedgEntry);
    end;

    /// <summary>
    /// Exports check entries to a positive pay file format for bank fraud prevention.
    /// Uses bank account configuration to determine export method and codeunit.
    /// </summary>
    procedure ExportCheckFile()
    var
        BankAcc: Record "Bank Account";
    begin
        if not FindSet() then
            Error(NothingToExportErr);

        if not BankAcc.Get("Bank Account No.") then
            Error(NothingToExportErr);

        if BankAcc.GetPosPayExportCodeunitID() > 0 then
            CODEUNIT.Run(BankAcc.GetPosPayExportCodeunitID(), Rec)
        else
            CODEUNIT.Run(CODEUNIT::"Exp. Launcher Pos. Pay", Rec);
    end;

    /// <summary>
    /// Determines the payee name based on the balancing account type and number.
    /// Returns the appropriate name from customer, vendor, G/L account, or other account types.
    /// </summary>
    /// <returns>Name of the payee for this check</returns>
    procedure GetPayee() Payee: Text[100]
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        Employee: Record Employee;
    begin
        case "Bal. Account Type" of
            "Bal. Account Type"::"G/L Account":
                if "Bal. Account No." <> '' then begin
                    GLAccount.Get("Bal. Account No.");
                    Payee := GLAccount.Name;
                end;
            "Bal. Account Type"::Customer:
                if "Bal. Account No." <> '' then begin
                    Customer.Get("Bal. Account No.");
                    Payee := Customer.Name;
                end;
            "Bal. Account Type"::Vendor:
                if "Bal. Account No." <> '' then begin
                    Vendor.Get("Bal. Account No.");
                    Payee := Vendor.Name;
                end;
            "Bal. Account Type"::"Bank Account":
                if "Bal. Account No." <> '' then begin
                    BankAccount.Get("Bal. Account No.");
                    Payee := BankAccount.Name;
                end;
            "Bal. Account Type"::"Fixed Asset":
                Payee := "Bal. Account No.";
            "Bal. Account Type"::Employee:
                if "Bal. Account No." <> '' then begin
                    Employee.Get("Bal. Account No.");
                    Payee := Employee.FullName();
                end;
        end;

        OnAfterGetPayee(Rec, Payee);
    end;

    /// <summary>
    /// Applies filter to show only open check entries for a specific bank account.
    /// Sets optimized key for efficient querying of open entries.
    /// </summary>
    /// <param name="BankAccNo">Bank account number to filter by</param>
    procedure SetFilterBankAccNoOpen(BankAccNo: Code[20])
    begin
        Reset();
        SetCurrentKey("Bank Account No.", Open);
        SetRange("Bank Account No.", BankAccNo);
        SetRange(Open, true);
    end;

    /// <summary>
    /// Integration event raised after copying data from bank account ledger entry to check ledger entry.
    /// Enables additional field initialization or custom processing during check entry creation.
    /// </summary>
    /// <param name="CheckLedgerEntry">Check ledger entry that was populated with bank account data</param>
    /// <param name="BankAccountLedgerEntry">Source bank account ledger entry used for copying data</param>
    /// <remarks>
    /// Raised from CopyFromBankAccLedgEntry procedure after copying standard fields from bank ledger entry.
    /// This is a public event publisher that can be raised and subscribed to from anywhere.
    /// </remarks>
    [IntegrationEvent(false, false)]
    procedure OnAfterCopyFromBankAccLedgEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after retrieving the payee name for a check.
    /// Enables custom logic for determining or modifying the payee name based on account type and number.
    /// </summary>
    /// <param name="CheckLedgerEntry">Check ledger entry containing balance account information</param>
    /// <param name="Payee">Payee name retrieved from the balance account (can be modified by subscribers)</param>
    /// <remarks>
    /// Raised from GetPayee procedure after determining payee name based on balance account type.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPayee(CheckLedgerEntry: Record "Check Ledger Entry"; var Payee: Text[100])
    begin
    end;
}
