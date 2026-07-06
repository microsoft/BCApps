// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

pageextension 99000776 "Mfg. Movement Worksheet" extends "Movement Worksheet"
{
    actions
    {
        addbefore("Autofill Qty. to Handle")
        {
            action("Return Over-Picked Quantity")
            {
                ApplicationArea = Warehouse;
                Caption = 'Return Over-Picked Quantity';
                Image = AutofillQtyToHandle;
                ToolTip = 'Insert the Items in the Movement worksheet which are surplus in the "To Production Bin Code"';

                trigger OnAction()
                var
                    ReturnOverPickedQuantity: Page "Return Overpicked Quantity";
                begin
                    ReturnOverPickedQuantity.SetContext(Rec."Worksheet Template Name", Rec.Name, Rec."Location Code");
                    Commit();
                    ReturnOverPickedQuantity.RunModal();
                end;
            }
        }
    }
}