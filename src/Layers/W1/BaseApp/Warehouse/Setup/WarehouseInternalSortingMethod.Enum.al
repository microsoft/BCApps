// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Setup;

#pragma warning disable AL0659
enum 7302 "Warehouse Internal Sorting Method"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { Caption = ' '; }
    value(1; "Item") { Caption = 'Item'; }
    value(2; "Shelf or Bin") { Caption = 'Shelf or Bin'; }
    value(3; "Due Date") { Caption = 'Due Date'; }
}
