// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Table Shpfy Product Collection (ID 30163).
/// </summary>
table 30163 "Shpfy Product Collection"
{
    Caption = 'Shopify Product Collection';
    DataClassification = CustomerContent;
    DrillDownPageId = "Shpfy Product Collections";
    LookupPageId = "Shpfy Product Collections";

    fields
    {
        field(1; Id; BigInteger)
        {
            Caption = 'Id';
            Editable = false;
            ToolTip = 'Specifies the unique identifier of the product collection.';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            Editable = false;
            ToolTip = 'Specifies the name of the product collection.';
        }
        field(3; "Shop Code"; Code[20])
        {
            Caption = 'Shop Code';
            Editable = false;
            ToolTip = 'Specifies the code of the shop.';
        }
        field(4; Default; Boolean)
        {
            Caption = 'Default';
            Editable = false;
            ToolTip = 'Specifies if the product collection is the default one. Used for new products publication if no other collection is selected';
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
