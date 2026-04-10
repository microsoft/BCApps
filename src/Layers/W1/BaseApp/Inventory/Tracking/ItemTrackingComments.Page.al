// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

page 6506 "Item Tracking Comments"
{
    AutoSplitKey = true;
    Caption = 'Item Tracking Comments';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Item Tracking Comment";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = ItemTracking;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = ItemTracking;
                }
            }
        }
    }

    actions
    {
    }
}

