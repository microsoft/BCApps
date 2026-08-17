// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing.ActionMessage;

using Microsoft.Inventory.Setup;

pageextension 5840 "Cost Adjmt. Inventory Setup" extends "Inventory Setup"
{
    layout
    {
        addafter("Cost Adjustment Logging")
        {
            field(DisableCostAdjmtSignals; Rec."Disable Cost Adjmt. Signals")
            {
                ApplicationArea = Basic, Suite;
                Importance = Additional;
            }
        }
    }
}