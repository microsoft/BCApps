// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

table 5763 "Whse. Post Parameters"
{
    Caption = 'Whse. Post Parameters';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Post Invoice"; Boolean)
        {
            Caption = 'Post Invoice';
            DataClassification = SystemMetadata;
        }
        field(3; "Print Documents"; Boolean)
        {
            Caption = 'Print Documents';
            DataClassification = SystemMetadata;
        }
        field(4; "Hide UI"; Boolean)
        {
            Caption = 'Hide UI';
            DataClassification = SystemMetadata;
        }
        field(5; "Preview Posting"; Boolean)
        {
            Caption = 'Preview Posting';
            DataClassification = SystemMetadata;
        }
        field(6; "Suppress Commit"; Boolean)
        {
            Caption = 'Suppress Commit';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(key1; "Primary Key")
        {
            Clustered = true;
        }
    }
}
