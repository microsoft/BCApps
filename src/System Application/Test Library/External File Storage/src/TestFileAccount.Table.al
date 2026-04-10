// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.ExternalFileStorage;

table 135810 "Test File Account"
{
    DataClassification = SystemMetadata;
    ReplicateData = false;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Primary Key';
        }
        field(2; Name; Text[250])
        {
            Caption = 'Name';
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }
}