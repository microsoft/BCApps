// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.StandardCost;

enum 5841 "Standard Cost Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Item") { Caption = 'Item'; }
    value(3; "Resource") { Caption = 'Resource'; }
}
