// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

table 15000301 "Recurring Post"
{
    Caption = 'Recurring Post';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Serial No."; Integer)
        {
            Caption = 'Serial No.';
        }
        field(2; "Blanket Order No."; Code[20])
        {
            Caption = 'Blanket Order No.';
        }
        field(3; Date; Date)
        {
            Caption = 'Date';
        }
        field(4; Time; Time)
        {
            Caption = 'Time';
        }
        field(5; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quotes,Ordres,Invoices,Credit Memos,Blanket Orders';
            OptionMembers = Quotes,Ordres,Invoices,"Credit Memos","Blanket Orders";
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "Serial No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if "Serial No." = 0 then
            if RecurringPost.FindLast() then
                "Serial No." := RecurringPost."Serial No." + 1
            else
                "Serial No." := 1;
    end;

    var
        RecurringPost: Record "Recurring Post";
}

