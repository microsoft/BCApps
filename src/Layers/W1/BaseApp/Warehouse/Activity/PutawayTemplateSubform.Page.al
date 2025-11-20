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
                    ToolTip = 'Specifies that you must put items in a particular bin. You define the bin by choosing the item on a line on the Bin Contents page and selecting the Fixed checkbox. If you haven''t specified a fixed bin for items, choose the Find Floating Bin checkbox.';
                }
                field("Find Floating Bin"; Rec."Find Floating Bin")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that you must put items in a bin that is not specifically tied to any particular item. A bin is considered floating when there are no lines in the Bin Contents page where the Fixed, Default, or Dedicated checkbox is selected.';
                }
                field("Find Same Item"; Rec."Find Same Item")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that you must put items in bins that already contain the same item. You define the bin for an item by choosing the item on a line on the Bin Contents page. This setting doesn''t consider the quantity that''s currently in the bin.';
                }
                field("Find Unit of Measure Match"; Rec."Find Unit of Measure Match")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that you must put items in bins that have the same unit of measure as the item. You define the unit of measure for a bin on the Bin Contents page. To use this option, the bin must be assigned to a location where Directed Put-Away and Pick is enabled.';
                }
                field("Find Bin w. Less than Min. Qty"; Rec."Find Bin w. Less than Min. Qty")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that you must put items in bins that are currently below their minimum quantity of items. You define a minimum quantity for bins on the Bin Contents page.';
                }
                field("Find Empty Bin"; Rec."Find Empty Bin")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that an empty bin must be used in the put-away process.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the set of criteria that is on the put-away template line.';
                }
            }
        }
    }

    actions
    {
    }
}

