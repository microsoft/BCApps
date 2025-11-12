// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.MarketingText;

table 5834 "Marketing Text Attributes"
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Selected; Boolean)
        {
            DataClassification = SystemMetadata;
        }

        field(2; Property; Text[2048])
        {
            DataClassification = CustomerContent;
        }

        field(3; Value; Text[2048])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; Property)
        {
            Clustered = true;
        }
    }
}
