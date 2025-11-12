// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using Microsoft.Bank.BankAccount;

table 275 "Bank Account Statement"
{
    Caption = 'Bank Account Statement';
    DataCaptionFields = "Bank Account No.", "Statement No.";
    LookupPageID = "Bank Account Statement List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            NotBlank = true;
            TableRelation = "Bank Account";
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            NotBlank = true;
        }
        field(3; "Statement Ending Balance"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Statement Ending Balance';
        }
        field(4; "Statement Date"; Date)
        {
            Caption = 'Statement Date';
        }
        field(5; "Balance Last Statement"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Balance Last Statement';
            Editable = false;
        }
        field(50; "Bank Account Name"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Bank Account".Name where("No." = field("Bank Account No.")));
        }
        field(100; "G/L Balance at Posting Date"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'G/L Balance at Posting Date';
            Editable = false;
        }
        field(101; "Outstd. Payments at Posting"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Outstanding Payments at Posting Date';
            Editable = false;
        }
        field(102; "Outstd. Transact. at Posting"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Outstading Bank Transactions at Posting Date';
            Editable = false;
        }
        field(103; "Total Pos. Diff. at Posting"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Total Positive Difference at Posting Date';
            Editable = false;
        }
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

