// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using Microsoft.Bank.BankAccount;

/// <summary>
/// Stores bank statement headers containing summary information from imported bank statements.
/// Used as the master record for bank statement lines and reconciliation processing.
/// </summary>
/// <remarks>
/// Holds key financial data like statement ending balance, statement date, and previous balance.
/// Links to Bank Account Statement Line table for detailed transaction data.
/// Integrates with bank reconciliation workflow for statement processing and posting.
/// </remarks>
table 275 "Bank Account Statement"
{
    Caption = 'Bank Account Statement';
    DataCaptionFields = "Bank Account No.", "Statement No.";
    LookupPageID = "Bank Account Statement List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the number of the bank account that this statement belongs to.
        /// </summary>
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            ToolTip = 'Specifies the number of the bank account that has been reconciled with this Bank Account Statement.';
            NotBlank = true;
            TableRelation = "Bank Account";
        }
        /// <summary>
        /// Specifies the statement number for this bank account statement.
        /// </summary>
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            ToolTip = 'Specifies the number of the bank''s statement that has been reconciled with the bank account.';
            NotBlank = true;
        }
        /// <summary>
        /// Specifies the ending balance shown on the bank statement.
        /// </summary>
        field(3; "Statement Ending Balance"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Statement Ending Balance';
            ToolTip = 'Specifies the ending balance on the bank''s statement that has been reconciled with the bank account.';
        }
        /// <summary>
        /// Specifies the date of the bank statement.
        /// </summary>
        field(4; "Statement Date"; Date)
        {
            Caption = 'Statement Date';
            ToolTip = 'Specifies the date on the bank''s statement that has been reconciled with the bank account.';
        }
        /// <summary>
        /// Specifies the ending balance from the previous bank statement. This field is automatically filled when you create a new bank statement.
        /// </summary>
        field(5; "Balance Last Statement"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Balance Last Statement';
            ToolTip = 'Specifies the ending balance on the bank account statement from the last posted bank account reconciliation.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the name of the bank account. This is a FlowField that is calculated from the Bank Account table.
        /// </summary>
        field(50; "Bank Account Name"; Text[100])
        {
            ToolTip = 'Specifies the name of the bank account that has been reconciled.';
            FieldClass = FlowField;
            CalcFormula = lookup("Bank Account".Name where("No." = field("Bank Account No.")));
        }
        /// <summary>
        /// Specifies the G/L balance at the posting date when the bank statement was processed.
        /// </summary>
        field(100; "G/L Balance at Posting Date"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'G/L Balance at Posting Date';
            Editable = false;
        }
        /// <summary>
        /// Specifies the amount of outstanding payments at the posting date when the bank statement was processed.
        /// </summary>
        field(101; "Outstd. Payments at Posting"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Outstanding Payments at Posting Date';
            Editable = false;
        }
        /// <summary>
        /// Specifies the amount of outstanding bank transactions at the posting date when the bank statement was processed.
        /// </summary>
        field(102; "Outstd. Transact. at Posting"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Outstading Bank Transactions at Posting Date';
            Editable = false;
        }
        /// <summary>
        /// Specifies the total positive difference at the posting date when the bank statement was processed.
        /// </summary>
        field(103; "Total Pos. Diff. at Posting"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Total Positive Difference at Posting Date';
            Editable = false;
        }
        /// <summary>
        /// Specifies the total negative difference at the posting date when the bank statement was processed.
        /// </summary>
        field(104; "Total Neg. Diff. at Posting"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Total Negative Difference at Posting Date';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Bank Account No.", "Statement No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Bank Account No.", "Statement No.")
        {
        }
    }

    trigger OnDelete()
    begin
        if not Confirm(HasBankEntriesQst, false) then
            Error('');
        CODEUNIT.Run(CODEUNIT::"BankAccStmtLines-Delete", Rec);
    end;

    trigger OnRename()
    begin
        Error(CannotRenameErr, TableCaption);
    end;

    var
#pragma warning disable AA0470
        CannotRenameErr: Label 'You cannot rename a %1.';
#pragma warning restore AA0470
        HasBankEntriesQst: Label 'When you use action Delete the bank statement will be deleted, but the bank ledger entries will stay Closed. You will not be able to redo the bank reconciliation for these ledger entries.\\We suggest you use the Undo action instead.\\Do you want to continue with Delete?';

    /// <summary>
    /// Gets the currency code for the bank account.
    /// </summary>
    /// <returns>The currency code of the bank account, or an empty string if not found.</returns>
    local procedure GetCurrencyCode(): Code[10]
    var
        BankAcc: Record "Bank Account";
    begin
        if "Bank Account No." = BankAcc."No." then
            exit(BankAcc."Currency Code");

        if BankAcc.Get("Bank Account No.") then
            exit(BankAcc."Currency Code");

        exit('');
    end;
}

