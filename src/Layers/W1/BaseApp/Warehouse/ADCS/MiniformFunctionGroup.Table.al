// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

table 7702 "Miniform Function Group"
{
    Caption = 'Miniform Function Group';
    LookupPageID = Functions;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(11; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(20; KeyDef; Option)
        {
            Caption = 'KeyDef';
            OptionCaption = 'Input,Esc,First,Last,Code,PgUp,PgDn,LnUp,LnDn,Reset,Register', Locked = true;
            OptionMembers = Input,Esc,First,Last,"Code",PgUp,PgDn,LnUp,LnDn,Reset,Register;
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
        MiniFunc.Reset();
        MiniFunc.SetRange("Function Code", Code);
        MiniFunc.DeleteAll();
    end;

    var
        MiniFunc: Record "Miniform Function";
}

