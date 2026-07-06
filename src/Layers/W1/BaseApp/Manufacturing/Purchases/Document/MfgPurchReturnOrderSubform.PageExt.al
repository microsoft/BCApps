// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

pageextension 99000785 "Mfg. PurchReturnOrderSubform" extends "Purchase Return Order Subform"
{
    layout
    {
        addafter("Qty. Assigned")
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