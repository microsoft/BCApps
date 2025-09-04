// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.History;

pageextension 30126 "Shpfy Posted Sales Cr. Memos" extends "Posted Sales Credit Memos"
{
    views
    {
        addlast
        {
            view(FromShopify)
            {
                Caption = 'From Shopify';
                Filters = where("Shpfy Refund Id" = filter(<> 0));
            }
        }
    }
}