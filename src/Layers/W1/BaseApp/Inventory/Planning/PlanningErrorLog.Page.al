// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

page 5430 "Planning Error Log"
{
    Caption = 'Planning Error Log';
    DataCaptionExpression = Rec.Caption();
    Editable = false;
    PageType = List;
    SourceTable = "Planning Error Log";

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
                    ToolTip = 'Specifies the item number associated with this entry.';
                }
                field("Error Description"; Rec."Error Description")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the description to the error in this entry.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Show")
            {
                ApplicationArea = Planning;
                Caption = '&Show';
                Image = View;
                ToolTip = 'View the log details.';

                trigger OnAction()
                begin
                    Rec.ShowError();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Show_Promoted"; "&Show")
                {
                }
            }
        }
    }
}

