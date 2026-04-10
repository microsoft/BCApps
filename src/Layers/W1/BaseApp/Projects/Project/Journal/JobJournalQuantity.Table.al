// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

using Microsoft.Foundation.UOM;
using Microsoft.Utilities;

table 278 "Job Journal Quantity"
{
    Caption = 'Project Journal Quantity';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Is Total"; Boolean)
        {
            Caption = 'Is Total';
        }
        field(2; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = "Unit of Measure";
        }
        field(3; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = ',Total';
            OptionMembers = ,Total;
        }
        field(4; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
            TableRelation = "Work Type";
        }
        field(5; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the project quantity to be reconciled.';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Is Total", "Unit of Measure Code", "Line Type", "Work Type Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

