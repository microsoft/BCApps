// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

table 931 "Service Item Trend Buffer"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(5; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionMembers = Day,Week,Month,Quarter,Year,Period;
            DataClassification = SystemMetadata;
        }
        field(6; "Period Name"; Text[50])
        {
            Caption = 'Period Name';
            ToolTip = 'Specifies the name of the period shown in the line.';
            DataClassification = SystemMetadata;
        }
        field(7; "Period Start"; Date)
        {
            Caption = 'Period Start';
            ToolTip = 'Specifies the start date of the period defined on the line for the service trend.';
            DataClassification = SystemMetadata;
        }
        field(8; "Period End"; Date)
        {
            Caption = 'Period End';
            DataClassification = SystemMetadata;
        }
        field(10; "Prepaid Income"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Prepaid Income';
            DataClassification = SystemMetadata;
        }
        field(11; "Posted Income"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Posted Income';
            DataClassification = SystemMetadata;
        }
        field(12; "Parts Used"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Parts Used';
            DataClassification = SystemMetadata;
        }
        field(13; "Resources Used"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Resources Used';
            DataClassification = SystemMetadata;
        }
        field(14; "Cost Used"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Cost Used';
            DataClassification = SystemMetadata;
        }
        field(15; Profit; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Profit';
            ToolTip = 'Specifies the profit (posted income minus posted cost in LCY) for the service item in the period specified in the Period Start field.';
            DataClassification = SystemMetadata;
        }
        field(16; "Profit %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Profit %';
            ToolTip = 'Specifies the profit percentage for the service item in the specified period.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Period Type", "Period Start")
        {
            Clustered = true;
        }
    }
}
