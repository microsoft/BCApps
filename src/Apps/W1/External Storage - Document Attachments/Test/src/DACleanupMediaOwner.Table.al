// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExternalStorage.DocumentAttachments.Test;

table 136820 "DA Cleanup Media Owner"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; ID; Guid) { }
        field(2; Media; MediaSet) { DataClassification = CustomerContent; }
    }
    keys
    {
        key(PK; ID) { Clustered = true; }
    }
}
