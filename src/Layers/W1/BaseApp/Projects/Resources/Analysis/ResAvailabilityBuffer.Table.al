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
            Caption = 'Qty. on Order (Project)';
            DataClassification = SystemMetadata;
        }
        field(12; "Availability After Orders"; Decimal)
        {
            Caption = 'Availability After Orders';
            DataClassification = SystemMetadata;
        }
        field(13; "Job Quotes Allocation"; Decimal)
        {
            Caption = 'Project Quotes Allocation';
            DataClassification = SystemMetadata;
        }
        field(14; "Availability After Quotes"; Decimal)
        {
            Caption = 'Availability After Quotes';
            DataClassification = SystemMetadata;
        }
        field(15; "Qty. on Service Order"; Decimal)
        {
            Caption = 'Qty. on Service Order';
            DataClassification = SystemMetadata;
        }
        field(16; "Qty. on Assembly Order"; Decimal)
        {
            Caption = 'Qty. on Assembly Order';
            DataClassification = SystemMetadata;
        }
        field(17; "Net Availability"; Decimal)
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
