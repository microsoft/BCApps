// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

pageextension 99000791 "Mfg. PostedReturnShipmentSubf" extends "Posted Return Shipment Subform"
{
    layout
    {
        addafter("Job No.")
        {
            field("Prod. Order No."; Rec."Prod. Order No.")
            {
                ApplicationArea = PurchReturnOrder;
                ToolTip = 'Specifies the number of the related production order.';
                Visible = false;
            }
        }
    }
}