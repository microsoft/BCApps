// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

pageextension 99000792 "Mfg. Purch. Receipt Lines" extends "Purch. Receipt Lines"
{
    layout
    {
        addafter("Unit Cost")
        {
            field("Prod. Order No."; Rec."Prod. Order No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of the related production order.';
                Visible = false;
            }
        }
    }
}
