// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

table 6792 "Withholding Tax Group"
{
    Caption = 'Withholding Tax Group';
    LookupPageID = "Withholding Tax Groups";
    DrillDownPageID = "Withholding Tax Groups";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies the code for the withholding tax group.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description for the withholding tax group.';
        }
        field(3; "Party Applicability"; Enum "Withholding Party Type")
        {
            Caption = 'Party Applicability';
            InitValue = Employee;
            ToolTip = 'Specifies which party type this withholding tax group applies to.';
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
        fieldgroup(DropDown; "Code", Description, "Party Applicability")
        {
        }
    }

    trigger OnDelete()
    var
        WHTGroupLine: Record "Withholding Tax Group Line";
    begin
        WHTGroupLine.SetRange("Group Code", Code);
        WHTGroupLine.DeleteAll(true);
    end;
}
