// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Archive;

pageextension 99000764 "Mfg. PurchReturnOrderArchSubf" extends "Purch Return Order Arc Subform"
{
    layout
    {
        addafter("Planning Flexibility")
        {
            field("Prod. Order Line No."; Rec."Prod. Order Line No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the related production order line.';
                Visible = false;
            }
            field("Prod. Order No."; Rec."Prod. Order No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the related production order.';
                Visible = false;
            }
            field("Operation No."; Rec."Operation No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the related production operation.';
                Visible = false;
            }
            field("Work Center No."; Rec."Work Center No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the work center number of the journal line.';
                Visible = false;
            }
            field(Finished; Rec.Finished)
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies that any related service or operation is finished.';
                Visible = false;
            }
        }
    }
}