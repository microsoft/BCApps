// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Vendor;
using System.Agents;

table 3332 "PA Detailed Task"
{
    Caption = 'Payables Agent Task';
    Access = Internal;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    TableType = Temporary;
    DataClassification = CustomerContent;
    Extensible = false;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Task Id"; Guid)
        {
            Caption = 'Task Id';
            DataClassification = SystemMetadata;
        }
        field(4; "Agent Task ID"; BigInteger)
        {
            Caption = 'Agent Task ID';
            DataClassification = SystemMetadata;
            TableRelation = "Agent Task".ID;
        }
        field(5; Outcome; RecordId)
        {
            Caption = 'Outcome';
            DataClassification = CustomerContent;
        }
        field(6; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
        field(7; "Updated At"; DateTime)
        {
            Caption = 'Updated At';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// The vendor of the Purchase Invoice registered as the outcome.
        /// </summary>
        field(10; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            DataClassification = CustomerContent;
            TableRelation = Vendor."No.";
        }
        field(11; "Agent Task Status"; Enum "Agent Task Status")
        {
            Caption = 'Task Status';
            DataClassification = SystemMetadata;
        }
        field(20; "Source Type"; Enum "PA Source Type")
        {
            Caption = 'Source Type';
            DataClassification = SystemMetadata;
        }
        field(21; "Email From"; Text[250])
        {
            Caption = 'Email From';
            DataClassification = CustomerContent;
        }
        field(22; "Email Subject"; Text[250])
        {
            Caption = 'Email Subject';
            DataClassification = CustomerContent;
        }
        field(23; "File Name"; Text[250])
        {
            Caption = 'File Name';
            DataClassification = CustomerContent;
        }
        field(24; "Has Pdf"; Boolean)
        {
            Caption = 'Has PDF';
            DataClassification = SystemMetadata;
        }
        field(27; "Sender Name"; Text[250])
        {
            Caption = 'Sender Name';
            DataClassification = CustomerContent;
        }
        field(28; "Email Received At"; DateTime)
        {
            Caption = 'Received At';
            DataClassification = SystemMetadata;
        }
        field(29; "Email External Id"; Text[2048])
        {
            Caption = 'Email External Id';
            DataClassification = CustomerContent;
        }
        field(30; Name; Text[250])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
        }
        field(31; "Source Description"; Text[1024])
        {
            Caption = 'Source';
            DataClassification = CustomerContent;
        }
        field(32; "Result Description"; Text[1024])
        {
            Caption = 'Result';
            DataClassification = CustomerContent;
        }
        field(33; "Has Agent Task"; Boolean)
        {
            Caption = 'Has Agent Task';
            DataClassification = SystemMetadata;
        }
        field(34; State; Enum "PA Task State")
        {
            Caption = 'State';
            DataClassification = SystemMetadata;
        }
        field(35; "Can Extract Text"; Boolean)
        {
            Caption = 'Can Extract Text';
            DataClassification = SystemMetadata;
        }
        field(36; "Can Register Outcome"; Boolean)
        {
            Caption = 'Can Register Outcome';
            DataClassification = SystemMetadata;
        }
        field(37; Version; Enum "PA Version")
        {
            Caption = 'Version';
            DataClassification = SystemMetadata;
        }
        field(38; "Intake Status"; Enum "PA Task Intake Status")
        {
            Caption = 'Intake Status';
            DataClassification = SystemMetadata;
        }
        field(39; "Rejection Reason"; Text[250])
        {
            Caption = 'Rejection Reason';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ByName; Name, "Entry No.")
        {
        }
        key(BySource; "Source Description", "Entry No.")
        {
        }
        key(ByResult; "Result Description", "Entry No.")
        {
        }
        key(ByVendor; "Vendor No.", "Entry No.")
        {
        }
        key(ByStatus; "Agent Task Status", "Entry No.")
        {
        }
    }
}
