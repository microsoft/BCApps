// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;

table 10972 "FR E-Invoice Lifecycle Resp."
{
    Caption = 'FR E-Invoice Lifecycle Response';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = X;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Response ID"; Text[100])
        {
            Caption = 'Response ID';
            DataClassification = CustomerContent;
        }
        field(3; "Invoice ID"; Text[100])
        {
            Caption = 'Invoice ID';
            DataClassification = CustomerContent;
        }
        field(4; "E-Document Entry No."; Integer)
        {
            Caption = 'E-Document Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "E-Document"."Entry No";
        }
        field(5; "E-Document Message Entry No."; Integer)
        {
            Caption = 'E-Document Message Entry No.';
            DataClassification = SystemMetadata;
        }
        field(6; "Response Type"; Enum "E-Doc. Response Type")
        {
            Caption = 'Response Type';
            DataClassification = SystemMetadata;
        }
        field(7; "Reason Code"; Code[20])
        {
            Caption = 'Reason Code';
            DataClassification = CustomerContent;
        }
        field(8; "Reason Description"; Text[500])
        {
            Caption = 'Reason Description';
            DataClassification = CustomerContent;
        }
        field(9; "Received At"; DateTime)
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
        key(Response; "Response ID")
        {
            Unique = true;
        }
        key(EDocument; "E-Document Entry No.", "Received At")
        {
        }
    }
}