// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

enum 246 "Requisition Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "G/L Account") { Caption = 'G/L Account'; }
    value(2; "Item") { Caption = 'Item'; }
}
