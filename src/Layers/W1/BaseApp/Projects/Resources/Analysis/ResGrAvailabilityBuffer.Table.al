// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Analysis;

table 920 "Res. Gr. Availability Buffer"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            DataClassification = SystemMetadata;

        }
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
            DataClassification = SystemMetadata;
        }
        field(7; "Period Start"; Date)
        {
            Caption = 'Period Start';
            DataClassification = SystemMetadata;
        }
        field(8; "Period End"; Date)
        {
            Caption = 'Period End';
            DataClassification = SystemMetadata;
        }
        field(10; Capacity; Decimal)
        {
            Caption = 'Capacity';
            DataClassification = SystemMetadata;
        }
        field(11; "Qty. on Order (Job)"; Decimal)
        {
            Caption = 'Qty. on Order';
            DataClassification = SystemMetadata;
        }
        field(12; "Qty. on Service Order"; Decimal)
        {
            Caption = 'Qty. Allocated on Service Order';
            DataClassification = SystemMetadata;
        }
        field(13; "Availability After Orders"; Decimal)
        {
            Caption = 'Availability After Orders';
            DataClassification = SystemMetadata;
        }
        field(14; "Qty. Quoted (Job)"; Decimal)
        {
            Caption = 'Project Quotes Allocation';
            DataClassification = SystemMetadata;
        }
        field(15; "Net Availability"; Decimal)
        {
            Caption = 'Net Availability';
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
