// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;

table 7000023 "Customer Rating"
{
    Caption = 'Customer Rating';
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
        field(3; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer."No.";
        }
        field(4; "Risk Percentage"; Decimal)
        {
            Caption = 'Risk Percentage';
            MaxValue = 100;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Code", "Currency Code", "Customer No.")
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

    var
        Text1100000: Label 'untitled';

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

