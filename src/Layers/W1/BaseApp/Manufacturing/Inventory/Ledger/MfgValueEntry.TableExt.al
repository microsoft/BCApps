// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;

tableextension 99000788 "Mfg. Value Entry" extends "Value Entry"
{
    fields
    {
        modify("No.")
        {
            TableRelation = if (Type = const("Machine Center")) "Machine Center"
            else
            if (Type = const("Work Center")) "Work Center";
        }
    }
}