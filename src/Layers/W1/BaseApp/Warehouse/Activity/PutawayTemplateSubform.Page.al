// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

page 7313 "Put-away Template Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Put-away Template Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Find Fixed Bin"; Rec."Find Fixed Bin")
                {
                    ApplicationArea = Warehouse;
                }
                field("Find Floating Bin"; Rec."Find Floating Bin")
                {
                    ApplicationArea = Warehouse;
                }
                field("Find Same Item"; Rec."Find Same Item")
                {
                    ApplicationArea = Warehouse;
                }
                field("Find Unit of Measure Match"; Rec."Find Unit of Measure Match")
                {
                    ApplicationArea = Warehouse;
                }
                field("Find Bin w. Less than Min. Qty"; Rec."Find Bin w. Less than Min. Qty")
                {
                    ApplicationArea = Warehouse;
                }
                field("Find Empty Bin"; Rec."Find Empty Bin")
                {
                    ApplicationArea = Warehouse;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
            }
        }
    }

    actions
    {
    }
}

