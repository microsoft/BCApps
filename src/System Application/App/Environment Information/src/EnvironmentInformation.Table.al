// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment;

table 3703 "Environment Information"
{
    Access = Internal;
    DataClassification = CustomerContent;
    DataPerCompany = false;
    InherentEntitlements = rimdX;
    InherentPermissions = rimdX;
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(2; Description; Blob)
        {
            Caption = 'Description';
            ToolTip = 'Specifies the environment''s nature and intended purpose to provide context for AI.';
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
