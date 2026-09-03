// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument;

table 6434 "E-Doc. External Reference"
{
    Access = Internal;
    Caption = 'E-Document External Reference';
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
        field(2; Service; Code[20])
        {
            Caption = 'Service';
            DataClassification = SystemMetadata;
            TableRelation = "E-Document Service";
        }
        field(3; "External Document ID"; Text[250])
        {
            Caption = 'External Document ID';
            DataClassification = CustomerContent;
        }
        field(4; "E-Document Entry No."; Integer)
        {
            Caption = 'E-Document Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "E-Document"."Entry No";
        }
        field(5; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ExternalDocument; Service, "External Document ID")
        {
            Unique = true;
        }
        key(EDocument; "E-Document Entry No.")
        {
        }
    }
}