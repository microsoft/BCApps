// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Journal;

pageextension 99001509 "Subc. Subcont. Worksheet" extends "Subcontracting Worksheet"
{
    layout
    {
        addlast(Control1)
        {
            field("Standard Task Code"; Rec."Standard Task Code")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
            }
            field("Pricelist Cost"; Rec."Pricelist Cost")
            {
                ApplicationArea = Manufacturing;
                Visible = false;
            }
            field("UoM for Pricelist"; Rec."UoM for Pricelist")
            {
                ApplicationArea = Manufacturing;
                Visible = false;
            }
            field("PL UM Qty/Base UM Qty"; Rec."PL UM Qty/Base UM Qty")
            {
                AutoFormatType = 0;
                ApplicationArea = Manufacturing;
                Visible = false;
            }
            field("Base UM Qty/PL UM Qty"; Rec."Base UM Qty/PL UM Qty")
            {
                AutoFormatType = 0;
                ApplicationArea = Manufacturing;
                Visible = false;
            }
        }
    }
}