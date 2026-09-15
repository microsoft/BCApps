// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

enum 5802 "Item Cost Source/Recipient"
{
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Source)
    {
        Caption = 'Source';
    }
    value(2; Recipient)
    {
        Caption = 'Recipient';
    }
}