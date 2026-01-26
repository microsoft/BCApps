// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.NoSeries;

table 7000016 "Cartera Setup"
{
    Caption = 'Cartera Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(3; "Bill Group Nos."; Code[20])
        {
            Caption = 'Bill Group Nos.';
            TableRelation = "No. Series";
        }
        field(4; "Payment Order Nos."; Code[20])
        {
            Caption = 'Payment Order Nos.';
            TableRelation = "No. Series";
        }
        field(7; "Bills Discount Limit Warnings"; Boolean)
        {
            Caption = 'Bills Discount Limit Warnings';
        }
        field(8; "CCC Ctrl Digits Check String"; Text[30])
        {
            Caption = 'CCC Ctrl Digits Check String';
        }
        field(9; "Euro Currency Code"; Code[10])
        {
            Caption = 'Euro Currency Code';
            TableRelation = Currency;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

