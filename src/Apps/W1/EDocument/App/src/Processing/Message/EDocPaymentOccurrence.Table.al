// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument;

/// <summary>
/// Stores an immutable payment application or reversal associated with an outgoing E-Document.
/// </summary>
table 6433 "E-Doc. Payment Occurrence"
{
    Access = Public;
    Caption = 'E-Document Payment Occurrence';
    DataClassification = CustomerContent;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "E-Document Entry No."; Integer)
        {
            Caption = 'E-Document Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "E-Document"."Entry No";
        }
        field(3; Type; Enum "E-Doc. Payment Occurrence Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(4; "Source Occurrence ID"; Guid)
        {
            Caption = 'Source Occurrence ID';
            DataClassification = SystemMetadata;
        }
        field(5; "Original Occurrence Entry No."; Integer)
        {
            Caption = 'Original Occurrence Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "E-Doc. Payment Occurrence"."Entry No.";
        }
        field(6; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = CustomerContent;
        }
        field(7; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
        }
        field(8; "Event Date"; Date)
        {
            Caption = 'Event Date';
            DataClassification = CustomerContent;
        }
        field(9; "Detailed Ledger Entry No."; Integer)
        {
            Caption = 'Detailed Ledger Entry No.';
            DataClassification = SystemMetadata;
        }
        field(10; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
        field(11; Status; Enum "E-Doc. Payment Occ. Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
        }
        field(12; "Last Attempt At"; DateTime)
        {
            Caption = 'Last Attempt At';
            DataClassification = SystemMetadata;
        }
        field(13; "Retry Count"; Integer)
        {
            Caption = 'Retry Count';
            DataClassification = SystemMetadata;
        }
        field(14; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
            DataClassification = CustomerContent;
        }
        field(15; "Next Attempt At"; DateTime)
        {
            Caption = 'Next Attempt At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Occurrence; "E-Document Entry No.", "Source Occurrence ID", Type)
        {
            Unique = true;
        }
        key(Source; "Source Occurrence ID", Type)
        {
        }
        key(Processing; Status, "Next Attempt At")
        {
        }
    }
}