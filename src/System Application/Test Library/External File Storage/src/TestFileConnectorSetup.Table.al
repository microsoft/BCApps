// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.ExternalFileStorage;

table 135811 "Test File Connector Setup"
{
    DataClassification = SystemMetadata;
    ReplicateData = false;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Primary Key';
        }
        field(2; "Fail On Send"; Boolean)
        {
            Caption = 'Fail On Send';
        }
        field(3; "Fail On Register Account"; Boolean)
        {
            Caption = 'Fail On Register Account';
        }
        field(4; "Unsuccessful Register"; Boolean)
        {
            Caption = 'Unsuccessful Register';
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
