// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.StandardCost;

enumextension 99000802 "Mfg. Standard Cost Source Type" extends "Standard Cost Source Type"
{
    value(1; "Work Center") { Caption = 'Work Center'; }
    value(2; "Machine Center") { Caption = 'Machine Center'; }
}
