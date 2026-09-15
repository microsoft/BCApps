// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Foundation.Address;

table 27029 "SAT Suburb"
{
    DataPerCompany = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'Code';
        }
        field(2; "Suburb Code"; Code[10])
        {
        }
        field(3; "Postal Code"; Code[20])
        {
            Caption = 'Postal Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        SATSuburb: Record "SAT Suburb";
    begin
        if ID = 0 then begin
            ID := 1;
            if SATSuburb.FindLast() then
                ID += SATSuburb.ID;
        end;
    end;
}

