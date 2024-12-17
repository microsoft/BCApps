// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

table 9451 "Ext. File Storage Connector"
{
    TableType = Temporary;
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    fields
    {
        field(1; Connector; Enum "Ext. File Storage Connector") { }
        field(2; Logo; Media) { }
        field(3; Description; Text[250]) { }
    }

    keys
    {
        key(PK; Connector)
        {
            Clustered = true;
        }
    }
}