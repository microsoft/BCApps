// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

page 5874 "BOM Warning Log"
{
    Caption = 'BOM Warning Log';
    Editable = false;
    PageType = List;
    SourceTable = "BOM Warning Log";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Warning Description"; Rec."Warning Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the warning associated with the entry.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table ID associated with the entry.';
                    Visible = false;
                }
                field("Table Position"; Rec."Table Position")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table position associated with the entry.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Show")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Show';
                Image = View;
                ToolTip = 'View the log details.';

                trigger OnAction()
                begin
                    Rec.ShowWarning();
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

