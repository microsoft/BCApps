// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;

table 7000010 "Operation Fee"
{
    Caption = 'Operation Fee';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(3; "Type of Fee"; Option)
        {
            Caption = 'Type of Fee';
            OptionCaption = 'Collection Expenses,Discount Expenses,Discount Interests,Rejection Expenses,Payment Order Expenses,Unrisked Factoring Expenses,Risked Factoring Expenses ';
            OptionMembers = "Collection Expenses","Discount Expenses","Discount Interests","Rejection Expenses","Payment Order Expenses","Unrisked Factoring Expenses","Risked Factoring Expenses ";
        }
        field(7; "Charge Amt. per Operation"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Charge Amt. per Operation';
        }
    }

    keys
    {
        key(Key1; "Code", "Currency Code", "Type of Fee")
        {
            Clustered = true;
        }
        key(Key2; "Currency Code", "Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        FeeRange.SetRange(Code, Code);
        FeeRange.SetRange("Currency Code", "Currency Code");
        FeeRange.SetRange("Type of Fee", "Type of Fee");
        FeeRange.DeleteAll();
    end;

    var
        Text1100000: Label 'untitled';
        FeeRange: Record "Fee Range";

    procedure Caption(): Text
    var
        BankAcc: Record "Bank Account";
    begin
        if Code = '' then
            exit(Text1100000);
        BankAcc.Get(Code);
        exit(StrSubstNo('%1 %2 %3', BankAcc."No.", BankAcc.Name, "Currency Code"));
    end;
}

