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
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                }
                field(Source; Rec.Source)
                {
                    ApplicationArea = Planning;
                    Style = Strong;
                    StyleExpr = Rec."Warning Level" > 0;
                }
                field("Source ID"; Rec."Source ID")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Parameter Value"; Rec."Parameter Value")
                {
                    ApplicationArea = Planning;
                }
                field("Track Quantity From"; Rec."Track Quantity From")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Untracked Quantity"; Rec."Untracked Quantity")
                {
                    ApplicationArea = Planning;
                }
                field("Track Quantity To"; Rec."Track Quantity To")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

