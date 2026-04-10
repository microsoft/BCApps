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
            ToolTip = 'Specifies the code that represents the function used on the handheld device.';
            NotBlank = true;
        }
        field(11; Description; Text[30])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a short description of what the function is or how it functions.';
        }
        field(20; KeyDef; Option)
        {
            Caption = 'KeyDef';
            ToolTip = 'Specifies the key that will trigger the function.';
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

