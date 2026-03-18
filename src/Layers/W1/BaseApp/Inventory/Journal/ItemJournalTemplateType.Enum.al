// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

enum 83 "Item Journal Template Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Item") { Caption = 'Item'; }
    value(1; "Transfer") { Caption = 'Transfer'; }
    value(2; "Phys. Inventory") { Caption = 'Phys. Inventory'; }
    value(3; "Revaluation") { Caption = 'Revaluation'; }
}
