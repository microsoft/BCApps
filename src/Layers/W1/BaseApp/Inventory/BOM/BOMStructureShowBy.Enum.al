// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

enum 5874 "BOM Structure Show By"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Item") { Caption = 'Item'; }
    value(1; "Assembly") { Caption = 'Assembly'; }
    value(2; "Production") { Caption = 'Production'; }
}
