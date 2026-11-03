// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

table 30209 "Shpfy Recurring Sync Buffer"
{
    Access = Internal;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; Workload; Enum "Shpfy Sync Workload")
        {
            Caption = 'Workload';
            DataClassification = SystemMetadata;
        }
        field(3; Synchronization; Enum "Shpfy Sync Direction")
        {
            Caption = 'Synchronization';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the synchronization workload and direction.';
        }
        field(4; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what this synchronization does.';
        }
        field(5; Frequency; Integer)
        {
            Caption = 'Frequency (Minutes)';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies how often the synchronization runs, in minutes. The value must be greater than zero.';
        }
        field(6; Readiness; Enum "Shpfy Sync Readiness")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether this synchronization is ready to schedule.';
        }
        field(7; Selected; Boolean)
        {
            Caption = 'Schedule';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether to create a recurring schedule for this synchronization.';
        }
        field(8; Selectable; Boolean)
        {
            Caption = 'Selectable';
            DataClassification = SystemMetadata;
        }
        field(9; Details; Text[500])
        {
            Caption = 'Details';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the setup required before this synchronization can be scheduled.';
        }
        field(10; "Setup Target"; Enum "Shpfy Sync Setup Target")
        {
            Caption = 'Setup Target';
            DataClassification = SystemMetadata;
        }
        field(11; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';
            DataClassification = SystemMetadata;
        }
        field(12; "Shop Display"; Text[250])
        {
            Caption = 'Shop';
            DataClassification = CustomerContent;
        }
        field(13; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
            DataClassification = SystemMetadata;
        }
        field(14; "Next Run Date/Time"; DateTime)
        {
            Caption = 'Next Run Date/Time';
            DataClassification = SystemMetadata;
        }
        field(15; "Job Queue Status"; Text[40])
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
        }
        field(16; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
