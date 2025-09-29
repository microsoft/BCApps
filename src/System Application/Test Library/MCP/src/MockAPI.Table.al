// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.MCP;

table 130131 "Mock API"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            Caption = 'Primary key';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}