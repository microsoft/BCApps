// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Reconciliation;

/// <summary>
/// Stores individual transaction lines from imported bank statements.
/// Contains detailed transaction data used for bank reconciliation and application to ledger entries.
/// </summary>
/// <remarks>
/// Links to Bank Account Statement for header information and provides detailed transaction data.
/// Supports application to Bank Account Ledger Entries and Check Ledger Entries through Type field.
/// Integrates with bank reconciliation matching algorithms for automated transaction processing.
/// </remarks>
table 276 "Bank Account Statement Line"
{
    Caption = 'Bank Account Statement Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the number of the bank account that this statement line belongs to.
        /// </summary>
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        /// <summary>
        /// Specifies the statement number that this line belongs to.
        /// </summary>
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Bank Account Statement"."Statement No." where("Bank Account No." = field("Bank Account No."));
        }
        /// <summary>
        /// Specifies the line number of this statement line within the bank statement.
        /// </summary>
        field(3; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
        }
        /// <summary>
        /// Specifies the document number for this statement line transaction.
        /// </summary>
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number of this line.';
        }
        /// <summary>
        /// Specifies the date when the transaction occurred.
        /// </summary>
        field(5; "Transaction Date"; Date)
        {
            Caption = 'Transaction Date';
            ToolTip = 'Specifies the posting date of the bank account or check ledger entry that the transaction on this line has been applied to.';
        }
        /// <summary>
        /// Specifies the description of the transaction as it appears on the bank statement.
        /// </summary>
        field(6; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description for the transaction on this line.';
        }
        /// <summary>
        /// Specifies the amount of the transaction as it appears on the bank statement.
        /// </summary>
        field(7; "Statement Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Statement Amount';
            ToolTip = 'Specifies the amount of the transaction on the bank''s statement on this line.';
        }
        /// <summary>
        /// Specifies the difference between the statement amount and the applied amount.
        /// </summary>
        field(8; Difference; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Difference';
            ToolTip = 'Specifies the difference between the amount in the Statement Amount field and Applied Amount field on this line.';
        }
        /// <summary>
        /// Specifies the total amount applied to this statement line from bank account ledger entries.
        /// </summary>
        field(9; "Applied Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Applied Amount';
            ToolTip = 'Specifies the amount on the bank account or check ledger entry that the transaction on this line has been applied to.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the type of entry that is applied to this statement line.
        /// </summary>
        field(10; Type; Enum "Bank Acc. Statement Line Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of ledger entry, or a difference that has been reconciled with the transaction on the bank''s statement on this line.';
        }
        /// <summary>
        /// Specifies the number of entries that have been applied to this statement line.
        /// </summary>
        field(11; "Applied Entries"; Integer)
        {
            Caption = 'Applied Entries';
            ToolTip = 'Specifies whether the transaction on this line has been applied to one or more ledger entries.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the value date of the transaction as it appears on the bank statement.
        /// </summary>
        field(12; "Value Date"; Date)
        {
            Caption = 'Value Date';
            ToolTip = 'Specifies the value date of the transaction on this line.';
        }
        /// <summary>
        /// Specifies the check number if the transaction is a check payment.
        /// </summary>
        field(14; "Check No."; Code[20])
        {
            AccessByPermission = TableData "Check Ledger Entry" = R;
            Caption = 'Check No.';
            ToolTip = 'Specifies the check number for the transaction on this line.';
        }
        /// <summary>
        /// Specifies the unique transaction identifier from the bank statement.
        /// </summary>
        field(70; "Transaction ID"; Text[50])
        {
            Caption = 'Transaction ID';
        }
    }

    keys
    {
        key(Key1; "Bank Account No.", "Statement No.", "Statement Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnRename()
    begin
        Error(CannotRenameErr, TableCaption);
    end;

    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        CheckLedgEntry: Record "Check Ledger Entry";

#pragma warning disable AA0470
        CannotRenameErr: Label 'You cannot rename a %1.';
#pragma warning restore AA0470

    /// <summary>
    /// Displays the entries that have been applied to this statement line.
    /// Shows either bank account ledger entries or check ledger entries based on the Type field.
    /// </summary>
    procedure DisplayApplication()
    var
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
    begin
        case Type of
            Type::"Bank Account Ledger Entry":
                begin
                    BankAccLedgEntry.Reset();
                    BankAccLedgEntry.SetCurrentKey("Bank Account No.", Open);
                    BankAccLedgEntry.SetRange("Bank Account No.", "Bank Account No.");
                    BankAccLedgEntry.SetRange(Open, false);
                    BankAccLedgEntry.SetRange("Statement Status", BankAccLedgEntry."Statement Status"::Closed);
                    BankAccLedgEntry.SetRange("Statement No.", "Statement No.");

                    BankAccRecMatchBuffer.SetRange("Bank Account No.", "Bank Account No.");
                    BankAccRecMatchBuffer.SetRange("Statement No.", "Statement No.");
                    BankAccRecMatchBuffer.SetRange("Statement Line No.", "Statement Line No.");

                    if BankAccRecMatchBuffer.FindFirst() then
                        BankAccLedgEntry.SetRange("Entry No.", BankAccRecMatchBuffer."Ledger Entry No.")
                    else
                        BankAccLedgEntry.SetRange("Statement Line No.", "Statement Line No.");
                    OnDisplayApplicationOnAfterBankAccLedgEntrySetFilters(Rec, BankAccLedgEntry);
                    PAGE.Run(0, BankAccLedgEntry);
                end;
            Type::"Check Ledger Entry":
                begin
                    CheckLedgEntry.Reset();
                    CheckLedgEntry.SetCurrentKey("Bank Account No.", Open);
                    CheckLedgEntry.SetRange("Bank Account No.", "Bank Account No.");
                    CheckLedgEntry.SetRange(Open, false);
                    CheckLedgEntry.SetRange("Statement Status", CheckLedgEntry."Statement Status"::Closed);
                    CheckLedgEntry.SetRange("Statement No.", "Statement No.");
                    CheckLedgEntry.SetRange("Statement Line No.", "Statement Line No.");
                    OnDisplayApplicationOnAfterCheckLedgEntrySetFilters(Rec, CheckLedgEntry);
                    PAGE.Run(0, CheckLedgEntry);
                end;
        end;

        OnAfterDisplayApplication(Rec);
    end;

    /// <summary>
    /// Gets the currency code for the bank account.
    /// </summary>
    /// <returns>The currency code of the bank account, or an empty string if not found.</returns>
    procedure GetCurrencyCode(): Code[10]
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
    /// Filters the match buffer to show many-to-one matches for this statement line.
    /// </summary>
    /// <param name="BankAccRecMatchBuffer">The bank account reconciliation match buffer to filter.</param>
    procedure FilterManyToOneMatches(var BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer")
    begin
        BankAccRecMatchBuffer.SetRange("Statement No.", Rec."Statement No.");
        BankAccRecMatchBuffer.SetRange("Bank Account No.", Rec."Bank Account No.");
        BankAccRecMatchBuffer.SetRange("Statement Line No.", Rec."Statement Line No.");
    end;

    /// <summary>
    /// Integration event raised after displaying applied entries for a bank account statement line.
    /// </summary>
    /// <param name="BankAccountStatementLine">The bank account statement line for which applications are displayed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterDisplayApplication(var BankAccountStatementLine: Record "Bank Account Statement Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after setting filters on bank account ledger entries during application display.
    /// </summary>
    /// <param name="BankAccountStatementLine">The bank account statement line being processed.</param>
    /// <param name="BankAccLedgEntry">The bank account ledger entry record with applied filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnDisplayApplicationOnAfterBankAccLedgEntrySetFilters(var BankAccountStatementLine: Record "Bank Account Statement Line"; var BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after setting filters on check ledger entries during application display.
    /// </summary>
    /// <param name="BankAccountStatementLine">The bank account statement line being processed.</param>
    /// <param name="CheckLedgEntry">The check ledger entry record with applied filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnDisplayApplicationOnAfterCheckLedgEntrySetFilters(var BankAccountStatementLine: Record "Bank Account Statement Line"; var CheckLedgEntry: Record "Check Ledger Entry")
    begin
    end;
}

