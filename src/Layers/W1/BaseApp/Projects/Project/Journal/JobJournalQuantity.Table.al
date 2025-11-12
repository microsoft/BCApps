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
            TableRelation = "Work Type";
        }
        field(5; Quantity; Decimal)
        {
            Caption = 'Quantity';
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

