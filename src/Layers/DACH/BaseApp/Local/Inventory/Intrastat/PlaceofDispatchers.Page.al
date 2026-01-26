// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

page 11000 "Place of Dispatchers"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Place of Dispatchers';
    PageType = List;
    SourceTable = "Place of Dispatcher";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a location code for the dispatcher.';
                }
                field(Text; Rec.Text)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you must enter a name for the location of the dispatcher.';
                }
            }
        }
    }

    actions
    {
    }
}

