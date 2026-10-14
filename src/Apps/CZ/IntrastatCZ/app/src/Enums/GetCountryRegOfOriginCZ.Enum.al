// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

enum 31302 "Get Country/Reg. of Origin CZ"
{
    Extensible = true;

    value(0; "Item Card")
    {
        Caption = 'Item Card';
    }
    value(1; "Posted Entries")
    {
        Caption = 'Posted Entries';
    }
}
