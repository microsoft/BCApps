// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

table 160 "Res. Capacity Entry"
{
    Caption = 'Res. Capacity Entry';
    DrillDownPageID = "Res. Capacity Entries";
    LookupPageID = "Res. Capacity Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        field(2; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            ToolTip = 'Specifies the number of the corresponding resource.';
            TableRelation = Resource;

            trigger OnValidate()
            begin
                Res.Get("Resource No.");
                "Resource Group No." := Res."Resource Group No.";
            end;
        }
        field(3; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            ToolTip = 'Specifies the number of the corresponding resource group assigned to the resource.';
            TableRelation = "Resource Group";
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
            ToolTip = 'Specifies the date for which the capacity entry is valid.';
        }
        field(5; Capacity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Capacity';
            ToolTip = 'Specifies the capacity that is calculated and recorded. The capacity is in the unit of measure.';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Resource No.", Date)
        {
            SumIndexFields = Capacity;
        }
        key(Key3; "Resource Group No.", Date)
        {
            SumIndexFields = Capacity;
        }
    }

    fieldgroups
    {
    }

    var
        Res: Record Resource;
}

