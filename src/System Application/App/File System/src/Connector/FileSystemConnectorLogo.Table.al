// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.FileSystem;

table 9452 "File System Connector Logo"
{
    DataClassification = SystemMetadata;
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    fields
    {
        field(1; Connector; Enum "File System Connector") { }
        field(2; Logo; Media) { }
    }

    keys
    {
        key(PK; Connector)
        {
            Clustered = true;
        }
    }
}