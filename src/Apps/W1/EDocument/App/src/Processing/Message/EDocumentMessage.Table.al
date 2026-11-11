// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument;

/// <summary>
/// Stores a message (e.g. a PEPPOL Order Response) that relates to an existing E-Document.
/// A message does not produce a BC document; it updates the lifecycle state of the parent E-Document.
/// </summary>
table 6432 "E-Document Message"
{
    Access = Internal;
    Caption = 'E-Document Message';
    ReplicateData = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "E-Document Entry No."; Integer)
        {
            Caption = 'E-Document Entry No.';
            TableRelation = "E-Document"."Entry No";
            DataClassification = SystemMetadata;
        }
        field(3; "Message Type"; Enum "E-Document Message Type")
        {
            Caption = 'Message Type';
            DataClassification = SystemMetadata;
        }
        field(4; Direction; Enum "E-Document Direction")
        {
            Caption = 'Direction';
            DataClassification = SystemMetadata;
        }
        field(5; Status; Enum "E-Doc. Message Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
        }
        field(6; "Data Storage Entry No."; Integer)
        {
            Caption = 'Data Storage Entry No.';
            TableRelation = "E-Doc. Data Storage"."Entry No.";
            DataClassification = SystemMetadata;
        }
        field(7; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
        field(8; "Response Type"; Enum "E-Doc. Response Type")
        {
            Caption = 'Response Type';
            DataClassification = SystemMetadata;
        }
        field(9; Service; Code[20])
        {
            Caption = 'Service';
            TableRelation = "E-Document Service";
            DataClassification = SystemMetadata;
        }
        field(10; "Last Attempt At"; DateTime)
        {
            Caption = 'Last Attempt At';
            DataClassification = SystemMetadata;
        }
        field(11; "Retry Count"; Integer)
        {
            Caption = 'Retry Count';
            DataClassification = SystemMetadata;
        }
        field(12; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
            DataClassification = CustomerContent;
        }
        field(13; "External Message ID"; Text[250])
        {
            Caption = 'External Message ID';
            DataClassification = CustomerContent;
        }
        field(14; "External Document ID"; Text[250])
        {
            Caption = 'External Document ID';
            DataClassification = CustomerContent;
        }
        field(15; "Received At"; DateTime)
        {
            Caption = 'Received At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(EDocument; "E-Document Entry No.")
        {
        }
        key(ExternalMessage; Service, "External Message ID")
        {
        }
    }
}
