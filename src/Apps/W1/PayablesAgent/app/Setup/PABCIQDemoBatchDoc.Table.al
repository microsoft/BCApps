// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

table 3324 "PA BC IQ Demo Batch Doc."
{
    Caption = 'Payables Agent BC IQ Demo Batch Document';
    DataClassification = CustomerContent;
    Access = Internal;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Run ID"; Guid)
        {
            Caption = 'Run ID';
            DataClassification = SystemMetadata;
        }
        field(2; Sequence; Integer)
        {
            Caption = 'Sequence';
            DataClassification = SystemMetadata;
        }
        field(3; "Resource Path"; Text[250])
        {
            Caption = 'Resource Path';
        }
        field(4; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(5; "E-Document Entry No."; Integer)
        {
            Caption = 'E-Document Entry No.';
            DataClassification = SystemMetadata;
        }
        field(6; "E-Document System ID"; Guid)
        {
            Caption = 'E-Document System ID';
            DataClassification = SystemMetadata;
        }
        field(7; "Agent Task ID"; BigInteger)
        {
            Caption = 'Agent Task ID';
            DataClassification = SystemMetadata;
        }
        field(8; "Unstructured Storage Entry No."; Integer)
        {
            Caption = 'Unstructured Storage Entry No.';
            DataClassification = SystemMetadata;
        }
        field(9; "Structured Storage Entry No."; Integer)
        {
            Caption = 'Structured Storage Entry No.';
            DataClassification = SystemMetadata;
        }
        field(10; "Purchase Header System ID"; Guid)
        {
            Caption = 'Purchase Header System ID';
            DataClassification = SystemMetadata;
        }
        field(11; "Purchase Document No."; Code[20])
        {
            Caption = 'Purchase Document No.';
            DataClassification = SystemMetadata;
        }
        field(12; Submitted; Boolean)
        {
            Caption = 'Submitted';
            DataClassification = SystemMetadata;
        }
        field(13; "Submission Error"; Text[2048])
        {
            Caption = 'Submission Error';
        }
    }

    keys
    {
        key(PK; "Run ID", Sequence)
        {
            Clustered = true;
        }
        key(EDocument; "E-Document Entry No.")
        {
        }
        key(AgentTask; "Agent Task ID")
        {
        }
    }
}
