// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

enum 5875 "Phys. Invt. Order Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Open") { Caption = 'Open'; }
    value(1; "Finished") { Caption = 'Finished'; }
}
