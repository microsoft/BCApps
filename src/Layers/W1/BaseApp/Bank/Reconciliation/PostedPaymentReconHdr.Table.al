// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;

table 1295 "Posted Payment Recon. Hdr"
{
    Caption = 'Posted Payment Recon. Hdr';
    DataCaptionFields = "Bank Account No.", "Statement No.";
    LookupPageID = "Bank Acc. Reconciliation List";
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
        field(6; "Bank Statement"; BLOB)
        {
            Caption = 'Bank Statement';
        }
        field(10; "Is Reconciled"; Boolean)
        {
            Caption = 'Is Reconciled';
            FieldClass = FlowField;
            CalcFormula = exist("Posted Payment Recon. Line" where("Bank Account No." = field("Bank Account No."),
                                                                    "Statement No." = field("Statement No."),
                                                                    Reconciled = const(true)));
        }
        field(11; "Is Reversed"; Boolean)
        {
            Caption = 'Is Reversed';
        }
        field(12; "G/L Register No."; Integer)
        {
            Caption = 'G/L Register No.';
        }
        field(13; "Entries found with G/L Reg."; Boolean)
        {
            Caption = 'Entries found with G/L Register';
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
    }

    var
        IgnoreConfirmOnDelete: Boolean;

    procedure SetIgnoreConfirmOnDelete(Value: Boolean)
    begin
        IgnoreConfirmOnDelete := Value;
    end;

    trigger OnDelete()
    begin
        if not IgnoreConfirmOnDelete then
            if not Confirm(HasBankEntriesQst, false, "Bank Account No.", "Statement No.") then
                Error('');
        CODEUNIT.Run(CODEUNIT::"BankPaymentApplLines-Delete", Rec);
    end;

    var
#pragma warning disable AA0470
        HasBankEntriesQst: Label 'One or more bank account ledger entries in bank account %1 have been reconciled for bank account statement %2, and contain information about the bank statement. These bank ledger entries will not be modified if you delete bank account statement %2.\\Do you want to continue?';
#pragma warning restore AA0470

    local procedure GetCurrencyCode(): Code[10]
    var
        BankAcc2: Record "Bank Account";
    begin
        if "Bank Account No." = BankAcc2."No." then
            exit(BankAcc2."Currency Code");

        if BankAcc2.Get("Bank Account No.") then
            exit(BankAcc2."Currency Code");

        exit('');
    end;
}

