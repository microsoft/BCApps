// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using System.Globalization;

table 388 "Dimension Translation"
{
    Caption = 'Dimension Translation';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            TableRelation = Dimension;
        }
        field(2; "Language ID"; Integer)
        {
            Caption = 'Language ID';
            NotBlank = true;
            TableRelation = "Windows Language";

            trigger OnValidate()
            begin
                CalcFields("Language Name");
            end;
        }
        field(3; Name; Text[30])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                if "Code Caption" = '' then
                    "Code Caption" := CopyStr(StrSubstNo(Text001, Name), 1, MaxStrLen("Code Caption"));
                if "Filter Caption" = '' then
                    "Filter Caption" := CopyStr(StrSubstNo(Text002, Name), 1, MaxStrLen("Filter Caption"));
            end;
        }
        field(4; "Code Caption"; Text[80])
        {
            Caption = 'Code Caption';
        }
        field(5; "Filter Caption"; Text[80])
        {
            Caption = 'Filter Caption';
        }
        field(6; "Language Name"; Text[80])
        {
            CalcFormula = lookup("Windows Language".Name where("Language ID" = field("Language ID")));
            Caption = 'Language Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Code", "Language ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 Code';
        Text002: Label '%1 Filter';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

