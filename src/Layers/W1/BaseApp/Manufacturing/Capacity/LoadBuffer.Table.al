// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

table 933 "Load Buffer"
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
            ToolTip = 'Specifies the starting date of the period that you want to view, for an overview of availability at the current work center group.';
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
            ToolTip = 'Specifies the amount of work that can be done in a specified time period at this work center group.';
            DataClassification = SystemMetadata;
        }
        field(11; "Allocated Qty."; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Allocated Qty.';
            ToolTip = 'Specifies the amount of capacity that is needed to produce a desired output in a given time period.';
            DataClassification = SystemMetadata;
        }
        field(12; "Availability After Orders"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Availability After Orders';
            ToolTip = 'Specifies the available capacity of this machine center that is not used in the planning of a given time period.';
            DataClassification = SystemMetadata;
        }
        field(13; Load; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Load';
            ToolTip = 'Specifies the sum of the required number of times that all the planned and actual orders are run on the work center in a specified period.';
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
