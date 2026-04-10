// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Globalization;

table 378 "Report List Translation"
{
    Caption = 'Report List Translation';
    DataPerCompany = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Menu ID"; Integer)
        {
            Caption = 'Menu ID';
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            NotBlank = true;
        }
        field(3; "Language ID"; Integer)
        {
            BlankZero = true;
            Caption = 'Language ID';
            NotBlank = true;
            TableRelation = "Windows Language";

            trigger OnValidate()
            begin
                CalcFields("Language Name");
            end;
        }
        field(4; "Language Name"; Text[80])
        {
            CalcFormula = lookup("Windows Language".Name where("Language ID" = field("Language ID")));
            Caption = 'Language Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Menu ID", "Line No.", "Language ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

