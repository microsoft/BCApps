// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

page 725 "Custom Address Format"
{
    Caption = 'Custom Address Format';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Custom Address Format";
    SourceTableView = sorting("Country/Region Code", "Line Position");

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Field ID"; Rec."Field ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies reference field ID.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupField();
                    end;
                }
                field("Line Format"; Rec."Line Format")
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    Editable = false;
                    ToolTip = 'Specifies address format fields.';

                    trigger OnAssistEdit()
                    begin
                        Rec.ShowCustomAddressFormatLines();
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Move Up")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Move Up';
                Image = MoveUp;
                ToolTip = 'Move current line up.';

                trigger OnAction()
                begin
                    Rec.MoveLine(-1);
                end;
            }
            action("Move Down")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Move Down';
                Image = MoveDown;
                ToolTip = 'Move current line down.';

                trigger OnAction()
                begin
                    Rec.MoveLine(1);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Move Up_Promoted"; "Move Up")
                {
                }
                actionref("Move Down_Promoted"; "Move Down")
                {
                }
            }
        }
    }
}

