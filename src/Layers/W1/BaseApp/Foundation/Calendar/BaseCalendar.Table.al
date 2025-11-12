// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Calendar;

table 7600 "Base Calendar"
{
    Caption = 'Base Calendar';
    DataCaptionFields = "Code", Name;
    LookupPageID = "Base Calendar List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(3; "Customized Changes Exist"; Boolean)
        {
            CalcFormula = exist("Customized Calendar Change" where("Base Calendar Code" = field(Code)));
            Caption = 'Customized Changes Exist';
            Editable = false;
            FieldClass = FlowField;
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
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
    begin
        CustomizedCalendarChange.SetRange("Base Calendar Code", Code);
        if not CustomizedCalendarChange.IsEmpty() then
            Error(Text001, Code);

        BaseCalendarLine.Reset();
        BaseCalendarLine.SetRange("Base Calendar Code", Code);
        BaseCalendarLine.DeleteAll();
    end;

    var
        BaseCalendarLine: Record "Base Calendar Change";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You cannot delete this record. Customized calendar changes exist for calendar code=<%1>.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

