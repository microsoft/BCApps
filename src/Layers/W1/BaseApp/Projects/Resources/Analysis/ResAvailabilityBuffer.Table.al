// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Analysis;

table 928 "Res. Availability Buffer"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(5; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
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
            ToolTip = 'Specifies a series of dates according to the selected time interval.';
            DataClassification = SystemMetadata;
        }
        field(8; "Period End"; Date)
        {
            Caption = 'Period End';
            DataClassification = SystemMetadata;
        }
        field(10; Capacity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Capacity';
            ToolTip = 'Specifies the total capacity for the corresponding time period.';
            DataClassification = SystemMetadata;
        }
        field(11; "Qty. on Order (Job)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. on Order (Project)';
            DataClassification = SystemMetadata;
        }
        field(12; "Availability After Orders"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Availability After Orders';
            ToolTip = 'Specifies capacity minus the quantity on order.';
            DataClassification = SystemMetadata;
        }
        field(13; "Job Quotes Allocation"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Project Quotes Allocation';
            DataClassification = SystemMetadata;
        }
        field(14; "Availability After Quotes"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Availability After Quotes';
            ToolTip = 'Specifies capacity, minus quantity on order (Project), minus quantity on service order, minus project quotes allocation.';
            DataClassification = SystemMetadata;
        }
        field(15; "Qty. on Service Order"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. on Service Order';
            DataClassification = SystemMetadata;
        }
        field(16; "Qty. on Assembly Order"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. on Assembly Order';
            ToolTip = 'Specifies how many units of the item are allocated to assembly orders, which is how many are listed on outstanding assembly order headers.';
            DataClassification = SystemMetadata;
        }
        field(17; "Net Availability"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Net Availability';
            ToolTip = 'Specifies capacity, minus the quantity on order, minus the projects quotes allocation.';
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
