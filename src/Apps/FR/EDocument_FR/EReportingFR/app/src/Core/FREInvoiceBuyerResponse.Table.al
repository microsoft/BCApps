// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;

table 10973 "FR E-Invoice Buyer Response"
{
    Caption = 'FR E-Invoice Buyer Response';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = X;
    ReplicateData = false;

    fields
    {
        field(1; "E-Document Entry No."; Integer)
        {
            Caption = 'E-Document Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "E-Document"."Entry No";
        }
        field(2; "E-Document Message Entry No."; Integer)
        {
            Caption = 'E-Document Message Entry No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Reason Code"; Code[20])
        {
            Caption = 'Reason Code';
            DataClassification = CustomerContent;
        }
        field(4; "Reason Description"; Text[500])
        {
            Caption = 'Reason Description';
            DataClassification = CustomerContent;
        }
        field(5; Status; Enum "E-Doc. Message Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
        }
        field(6; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
        field(7; "Response Type"; Enum "E-Doc. Response Type")
        {
            Caption = 'Response Type';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "E-Document Entry No.")
        {
            Clustered = true;
        }
    }
}