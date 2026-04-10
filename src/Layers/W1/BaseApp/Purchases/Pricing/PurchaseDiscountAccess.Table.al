// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Pricing;

/// <summary>
/// The purpose of the table is to setup access to UX and logic of the purchase discount calculation.
/// TableType is not set to Temporary only because the ReadPermission() method always returns true.
/// </summary>
table 7018 "Purchase Discount Access"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }
}
