// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

// NB: This table is only used during posting preview to ensure we use correct numbersequence during posting preview and actual posting, respectively.

namespace Microsoft.Foundation.NoSeries;

table 9501 "Sequence No. Preview State"
{
    DataClassification = SystemMetadata;
    InherentEntitlements = RIMDX;
    InherentPermissions = rimdx;
    ReplicateData = false;
    Access = Internal;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }
}