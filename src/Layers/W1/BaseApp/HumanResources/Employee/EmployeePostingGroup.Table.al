// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.HumanResources.Payables;
using Microsoft.Finance.ReceivablesPayables;

table 5221 "Employee Posting Group"
{
    Caption = 'Employee Posting Group';
    LookupPageID = "Employee Posting Groups";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Payables Account"; Code[20])
        {
            Caption = 'Payables Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Payables Account");
            end;
        }
        field(10; "Debit Curr. Appln. Rndg. Acc."; Code[20])
        {
            Caption = 'Debit Curr. Appln. Rndg. Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Debit Curr. Appln. Rndg. Acc.");
            end;
        }
        field(11; "Credit Curr. Appln. Rndg. Acc."; Code[20])
        {
            Caption = 'Credit Curr. Appln. Rndg. Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Credit Curr. Appln. Rndg. Acc.");
            end;
        }
        field(12; "Debit Rounding Account"; Code[20])
        {
            Caption = 'Debit Rounding Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Debit Rounding Account");
            end;
        }
        field(13; "Credit Rounding Account"; Code[20])
        {
            Caption = 'Credit Rounding Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Credit Rounding Account");
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckGroupUsage();
    end;

    var
        PostingSetupMgt: Codeunit PostingSetupManagement;
        YouCannotDeleteErr: Label 'You cannot delete %1.', Comment = '%1 = Code';

    local procedure CheckGroupUsage()
    var
        Employee: Record Employee;
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        Employee.SetRange("Employee Posting Group", Code);
        if not Employee.IsEmpty() then
            Error(YouCannotDeleteErr, Code);

        EmployeeLedgerEntry.SetRange("Employee Posting Group", Code);
        if not EmployeeLedgerEntry.IsEmpty() then
            Error(YouCannotDeleteErr, Code);
    end;


    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
        end;
    end;

    procedure GetPayablesAccount(): Code[20]
    begin
        if "Payables Account" = '' then
            PostingSetupMgt.LogEmplPostingGroupFieldError(Rec, FieldNo("Payables Account"));

        exit("Payables Account");
    end;

    procedure GetRoundingAccount(Debit: Boolean): Code[20]
    begin
        if Debit then begin
            if "Debit Rounding Account" = '' then
                PostingSetupMgt.LogEmplPostingGroupFieldError(Rec, FieldNo("Debit Rounding Account"));

            exit("Debit Rounding Account");
        end;
        if "Credit Rounding Account" = '' then
            PostingSetupMgt.LogEmplPostingGroupFieldError(Rec, FieldNo("Credit Rounding Account"));

        exit("Credit Rounding Account");
    end;

    procedure GetApplRoundingAccount(Debit: Boolean): Code[20]
    begin
        if Debit then begin
            if "Debit Curr. Appln. Rndg. Acc." = '' then
                PostingSetupMgt.LogEmplPostingGroupFieldError(Rec, FieldNo("Debit Curr. Appln. Rndg. Acc."));

            exit("Debit Curr. Appln. Rndg. Acc.");
        end;
        if "Credit Curr. Appln. Rndg. Acc." = '' then
            PostingSetupMgt.LogEmplPostingGroupFieldError(Rec, FieldNo("Credit Curr. Appln. Rndg. Acc."));

        exit("Credit Curr. Appln. Rndg. Acc.");
    end;
}

