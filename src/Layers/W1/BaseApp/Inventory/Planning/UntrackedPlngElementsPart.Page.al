// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

page 9101 "Untracked Plng. Elements Part"
{
    Caption = 'Untracked Planning Elements';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Untracked Planning Element";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the item in the requisition line for which untracked planning surplus exists.';
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code in the requisition line associated with the untracked planning surplus.';
                    Visible = false;
                }
                field(Source; Rec.Source)
                {
                    ApplicationArea = Planning;
                    Style = Strong;
                    StyleExpr = Rec."Warning Level" > 0;
                    ToolTip = 'Specifies what the source of this untracked surplus quantity is.';
                }
                field("Source ID"; Rec."Source ID")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the identification code for the source of the untracked planning quantity.';
                    Visible = false;
                }
                field("Parameter Value"; Rec."Parameter Value")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the value of this planning parameter.';
                }
                field("Track Quantity From"; Rec."Track Quantity From")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how much the total surplus quantity is, including the quantity from this entry.';
                    Visible = false;
                }
                field("Untracked Quantity"; Rec."Untracked Quantity")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how much this planning parameter contributed to the total surplus quantity.';
                }
                field("Track Quantity To"; Rec."Track Quantity To")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies what the surplus quantity would be without the quantity from this entry.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

