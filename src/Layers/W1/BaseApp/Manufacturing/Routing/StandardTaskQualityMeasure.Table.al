// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

using Microsoft.Manufacturing.Setup;

table 99000784 "Standard Task Quality Measure"
{
    Caption = 'Standard Task Quality Measure';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Standard Task Code"; Code[10])
        {
            Caption = 'Standard Task Code';
            NotBlank = true;
            TableRelation = "Standard Task";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(9; "Qlty Measure Code"; Code[10])
        {
            Caption = 'Qlty Measure Code';
            ToolTip = 'Specifies the code of the quality measure.';
            TableRelation = "Quality Measure";

            trigger OnValidate()
            begin
                if "Qlty Measure Code" = '' then
                    exit;

                QltyMeasure.Get("Qlty Measure Code");
                Description := QltyMeasure.Description;
            end;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the quality measure description.';
        }
        field(11; "Min. Value"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Min. Value';
            ToolTip = 'Specifies the minimum value that must be met.';
            DecimalPlaces = 0 : 5;
        }
        field(12; "Max. Value"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Max. Value';
            ToolTip = 'Specifies the maximum value that may be achieved.';
            DecimalPlaces = 0 : 5;
        }
        field(13; "Mean Tolerance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Mean Tolerance';
            ToolTip = 'Specifies the mean tolerance.';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Standard Task Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        QltyMeasure: Record "Quality Measure";
}

