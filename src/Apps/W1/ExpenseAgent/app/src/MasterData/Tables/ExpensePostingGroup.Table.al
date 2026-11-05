// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Account;

table 6928 "Expense Posting Group"
{
    Access = Internal;
    Caption = 'Expense Posting Group';
    LookupPageId = "Expense Posting Groups";
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Refundable Debit Account"; Code[20])
        {
            Caption = 'Refundable Debit Account';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false));

            trigger OnValidate()
            begin
                CheckGLAcc("Refundable Debit Account");
            end;
        }
        field(3; "Non-Refundable Debit Account"; Code[20])
        {
            Caption = 'Non-Refundable Debit Account';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false));

            trigger OnValidate()
            begin
                CheckGLAcc("Non-Refundable Debit Account");
            end;
        }
        field(4; "Prepayment Credit Account"; Code[20])
        {
            Caption = 'Prepayment Credit Account';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false));

            trigger OnValidate()
            begin
                CheckGLAcc("Prepayment Credit Account");
            end;
        }
        field(5; "Debit Rounding Account"; Code[20])
        {
            Caption = 'Debit Rounding Account';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false));

            trigger OnValidate()
            begin
                CheckGLAcc("Debit Rounding Account");
            end;
        }
        field(6; "Credit Rounding Account"; Code[20])
        {
            Caption = 'Credit Rounding Account';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false));

            trigger OnValidate()
            begin
                CheckGLAcc("Credit Rounding Account");
            end;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    begin
        CheckGroupUsage();
    end;

    var
        YouCannotDeleteErr: Label 'You cannot delete %1 as it is in use in Expense Category %2.', Comment = '%1 = Code, %2 = Expense Category Code';

    local procedure CheckGroupUsage()
    var
        ExpenseCategory: Record "Expense Category";
    begin
        ExpenseCategory.SetRange("Posting Group", Code);
        if not ExpenseCategory.IsEmpty() then
            Error(YouCannotDeleteErr, Code, ExpenseCategory.Code);
    end;

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo = '' then
            exit;

        GLAcc.Get(AccNo);
        GLAcc.CheckGLAcc();
    end;
}