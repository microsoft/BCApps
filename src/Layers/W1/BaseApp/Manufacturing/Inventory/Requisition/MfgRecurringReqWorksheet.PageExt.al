// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

pageextension 99000837 "Mfg. Recurring Req. Worksheet" extends "Recurring Req. Worksheet"
{
    layout
    {
        addafter("Requester ID")
        {
            field("Prod. Order No."; Rec."Prod. Order No.")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies the number of the related production order.';
                Visible = false;
            }
        }
    }
}