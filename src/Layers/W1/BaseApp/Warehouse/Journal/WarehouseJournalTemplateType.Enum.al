// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Journal;

#pragma warning disable AL0659
enum 7309 "Warehouse Journal Template Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Item") { Caption = 'Item'; }
    value(1; "Physical Inventory") { Caption = 'Physical Inventory'; }
    value(2; "Reclassification") { Caption = 'Reclassification'; }
}
