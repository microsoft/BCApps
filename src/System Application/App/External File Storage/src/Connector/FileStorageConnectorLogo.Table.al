// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

table 9452 "File Storage Connector Logo"
{
    DataClassification = SystemMetadata;
    Access = Internal;
    ReplicateData = false;
    InherentPermissions = X;
    InherentEntitlements = X;

    fields
    {
        field(1; Connector; Enum "Ext. File Storage Connector") { }
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