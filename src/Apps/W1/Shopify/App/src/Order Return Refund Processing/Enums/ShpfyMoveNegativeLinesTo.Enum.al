// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

enum 30172 "Shpfy Move Negative Lines To"
{
    Access = Public;
    Extensible = false;

    value(0; "Do Not Move")
    {
        Caption = 'Do Not Move';
    }
    value(1; "Sales Order")
    {
        Caption = 'Sales Order';
    }
    value(2; "Sales Invoice")
    {
        Caption = 'Sales Invoice';
    }
}
