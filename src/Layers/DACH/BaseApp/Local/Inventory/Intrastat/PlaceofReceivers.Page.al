// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

page 11001 "Place of Receivers"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Place of Receivers';
    PageType = List;
    SourceTable = "Place of Receiver";
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
                    ToolTip = 'Specifies a location code for the receiver.';
                }
                field(Text; Rec.Text)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a name for the location of the receiver.';
                }
            }
        }
    }

    actions
    {
    }
}

