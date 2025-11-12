// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

enumextension 99000783 "Mfg. Item Journal Templ. Type" extends "Item Journal Template Type"
{
    value(4; "Consumption") { Caption = 'Consumption'; }
    value(5;
    "Output") { Caption = 'Output'; }
    value(6; "Capacity") { Caption = 'Capacity'; }
    value(7; "Prod. Order") { Caption = 'Prod. Order'; }
}
