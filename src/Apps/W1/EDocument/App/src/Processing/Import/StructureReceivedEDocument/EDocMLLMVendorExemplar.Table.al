// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;

table 6167 "E-Doc. MLLM Vendor Exemplar"
{
    Access = Internal;
    DataClassification = CustomerContent;
    ReplicateData = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    Caption = 'E-Doc. MLLM Vendor Exemplar';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Vendor Company Name"; Text[250])
        {
            Caption = 'Vendor Company Name';
        }
        field(3; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
        }
        field(4; "Corrected UBL JSON"; Blob)
        {
            Caption = 'Corrected UBL JSON';
        }
        field(5; "E-Document Entry No."; Integer)
        {
            Caption = 'E-Document Entry No.';
            TableRelation = "E-Document"."Entry No";
            DataClassification = SystemMetadata;
        }
        field(6; "Unstructured Data Entry No."; Integer)
        {
            Caption = 'Unstructured Data Entry No.';
            DataClassification = SystemMetadata;
        }
        field(7; "Created At"; DateTime)
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
        key(VendorName; "Vendor Company Name")
        {
        }
    }
}
