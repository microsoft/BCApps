// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

enum 30180 "Shpfy Process Returns As"
{
    Extensible = true;

    value(0; "Credit Memo")
    {
        Caption = 'Credit Memo';
    }
    value(1; "Return Order")
    {
        Caption = 'Return Order';
    }
}
