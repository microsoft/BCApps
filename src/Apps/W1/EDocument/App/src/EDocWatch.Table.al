// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.eServices.EDocument.IO;

#pragma warning disable AS0103
#pragma warning disable PTE0004
table 6150 "E-Doc Watch"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Export ID"; Integer)
        {
            Caption = 'Export ID';
            Editable = false;
        }
        field(3; "File Content"; Blob)
        {
            Caption = 'File Content';
        }
    }

    keys
    {
        key(PK; "Export ID")
        {
            Clustered = true;
        }
    }
}