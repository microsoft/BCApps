// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Utilities;

table 4150 "Temp Blob"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    TableType = Temporary;


    fields
    {
        field(1; "Primary Key"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; Blob; Blob)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

}

