// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

table 3323 "PA BC IQ Demo Batch"
{
    Caption = 'Payables Agent BC IQ Demo Batch';
    DataClassification = CustomerContent;
    Access = Internal;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Primary Key"; Code[20])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Run ID"; Guid)
        {
            Caption = 'Run ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Submitted At"; DateTime)
        {
            Caption = 'Submitted At';
            DataClassification = SystemMetadata;
        }
        field(4; "BC IQ Enabled"; Boolean)
        {
            Caption = 'Business Central IQ Enabled';
            DataClassification = SystemMetadata;
        }
        field(5; "Expected Document Count"; Integer)
        {
            Caption = 'Expected Document Count';
            DataClassification = SystemMetadata;
        }
        field(6; "Submitted Document Count"; Integer)
        {
            Caption = 'Submitted Document Count';
            DataClassification = SystemMetadata;
        }
        field(7; Status; Enum "PA BC IQ Batch Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
        }
        field(8; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
        key(Run; "Run ID")
        {
        }
    }
}
