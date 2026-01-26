// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.CODA;

using Microsoft.Bank.BankAccount;

table 2000040 "CODA Statement"
{
    Caption = 'CODA Statement';
    DataCaptionFields = "Bank Account No.", "Statement No.";
    LookupPageID = "CODA Statement List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            NotBlank = true;
            TableRelation = "Bank Account";

            trigger OnValidate()
            begin
                if "Statement No." = '' then begin
                    BankAcc.Get("Bank Account No.");
                    "Statement No." := IncStr(BankAcc."Last Statement No.");
                    "Balance Last Statement" := BankAcc."Balance Last Statement";
                end;
            end;
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            NotBlank = true;
        }
        field(3; "Statement Ending Balance"; Decimal)
        {
            Caption = 'Statement Ending Balance';
        }
        field(4; "Statement Date"; Date)
        {
            Caption = 'Statement Date';
        }
        field(5; "Balance Last Statement"; Decimal)
        {
            Caption = 'Balance Last Statement';
        }
        field(6; "CODA Statement No."; Integer)
        {
            Caption = 'CODA Statement No.';
        }
        field(7; Information; Integer)
        {
            BlankNumbers = BlankZero;
            BlankZero = true;
            CalcFormula = count("CODA Statement Line" where("Bank Account No." = field("Bank Account No."),
                                                             "Statement No." = field("Statement No."),
                                                             ID = const(Information)));
            Caption = 'Information';
            Editable = false;
            FieldClass = FlowField;
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

    trigger OnDelete()
    begin
        CODAStatementLine.Reset();
        CODAStatementLine.SetRange("Bank Account No.", "Bank Account No.");
        CODAStatementLine.SetRange("Statement No.", "Statement No.");
        CODAStatementLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        TestField("Bank Account No.");
        TestField("Statement No.");
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Text000: Label 'You cannot rename a %1.';
        BankAcc: Record "Bank Account";
        CODAStatementLine: Record "CODA Statement Line";
}

