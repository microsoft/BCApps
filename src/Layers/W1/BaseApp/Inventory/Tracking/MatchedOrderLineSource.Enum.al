// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

enum 5817 "Matched Order Line Source"
{
    Extensible = false;

    value(0; "Purchase Invoice")
    {
    }
    value(1; "Posted Purchase Invoice")
    {
    }
    value(2; "Purchase Credit Memo")
    {
    }
    value(3; "Posted Purchase Credit Memo")
    {
    }
    value(4; "Sales Invoice")
    {
    }
    value(5; "Posted Sales Invoice")
    {
    }
    value(6; "Sales Credit Memo")
    {
    }
    value(7; "Posted Sales Credit Memo")
    {
    }
}