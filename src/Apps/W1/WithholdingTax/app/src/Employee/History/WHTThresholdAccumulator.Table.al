// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

using Microsoft.HumanResources.Employee;

table 6794 "WHT Threshold Accumulator"
{
    Caption = 'WHT Threshold Accumulator';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            ToolTip = 'Specifies the entry number of the withholding tax threshold accumulator.';
        }
        field(2; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
            ToolTip = 'Specifies the employee number for the withholding tax threshold accumulator.';
        }
        field(3; "Wthldg. Tax Bus. Post. Group"; Code[20])
        {
            Caption = 'Withholding Tax Bus. Post. Group';
            TableRelation = "Wthldg. Tax Bus. Post. Group";
            ToolTip = 'Specifies the withholding tax business posting group for the withholding tax threshold accumulator.';
        }
        field(4; "Wthldg. Tax Prod. Post. Group"; Code[20])
        {
            Caption = 'Withholding Tax Prod. Post. Group';
            TableRelation = "Wthldg. Tax Prod. Post. Group";
            ToolTip = 'Specifies the withholding tax product posting group for the withholding tax threshold accumulator.';
        }
        field(5; "Threshold Base"; Enum "Withholding Threshold Base")
        {
            Caption = 'Threshold Base';
            ToolTip = 'Specifies the threshold base for the withholding tax threshold accumulator.';
        }
        field(6; "Period Start Date"; Date)
        {
            Caption = 'Period Start Date';
            ToolTip = 'Specifies the start date of the period for the withholding tax threshold accumulator.';
        }
        field(7; "Period End Date"; Date)
        {
            Caption = 'Period End Date';
            ToolTip = 'Specifies the end date of the period for the withholding tax threshold accumulator.';
        }
        field(8; "Accumulated Base Amount"; Decimal)
        {
            Caption = 'Accumulated Base Amount';
            AutoFormatType = 1;
            ToolTip = 'Specifies the accumulated base amount for the withholding tax threshold accumulator.';
        }
        field(9; "Accumulated WHT Amount"; Decimal)
        {
            Caption = 'Accumulated Withholding Tax Amount';
            AutoFormatType = 1;
            ToolTip = 'Specifies the accumulated withholding tax amount for the withholding tax threshold accumulator.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Employee No.", "Threshold Base", "Period Start Date", "Period End Date")
        {
            SumIndexFields = "Accumulated Base Amount", "Accumulated WHT Amount";
        }
        key(Key3; "Employee No.", "Wthldg. Tax Bus. Post. Group", "Wthldg. Tax Prod. Post. Group", "Period Start Date", "Period End Date")
        {
            SumIndexFields = "Accumulated Base Amount", "Accumulated WHT Amount";
        }
    }
}
