// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

table 15000007 "Return Error"
{
    Caption = 'Return Error';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Waiting Journal Reference"; Integer)
        {
            Caption = 'Waiting Journal Reference';
        }
        field(2; "Serial Number"; Integer)
        {
            Caption = 'Serial Number';
        }
        field(10; "Message Text"; Text[250])
        {
            Caption = 'Message Text';
        }
        field(11; "Payment Order ID"; Integer)
        {
            Caption = 'Payment Order ID';
            TableRelation = "Remittance Payment Order".ID;
        }
        field(12; Date; Date)
        {
            Caption = 'Date';
        }
        field(13; Time; Time)
        {
            Caption = 'Time';
        }
        field(14; "Transaction Name"; Text[8])
        {
            Caption = 'Transaction Name';
        }
    }

    keys
    {
        key(Key1; "Waiting Journal Reference", "Serial Number")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if "Serial Number" = 0 then begin
            ReturnError.SetRange("Waiting Journal Reference", "Waiting Journal Reference");
            if ReturnError.FindLast() then
                "Serial Number" := ReturnError."Serial Number" + 1
            else
                "Serial Number" := 1;
        end;
    end;

    var
        ReturnError: Record "Return Error";
}

