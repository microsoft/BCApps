// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

enum 99000915 "Planning Line Origin Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Action Message") { Caption = 'Action Message'; }
    value(2; "Planning") { Caption = 'Planning'; }
    value(3; "Order Planning") { Caption = 'Order Planning'; }
}
