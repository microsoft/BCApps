// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Calendar;

page 7601 "Base Calendar List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Base Calendars';
    CardPageID = "Base Calendar Card";
    Editable = false;
    PageType = List;
    SourceTable = "Base Calendar";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    Caption = 'Code';
                    ToolTip = 'Specifies the code for the base calendar you have set up.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the base calendar in the entry.';
                }
                field("Customized Changes Exist"; Rec."Customized Changes Exist")
                {
                    ApplicationArea = Suite;
                    Caption = 'Customized Changes Exist';
                    ToolTip = 'Specifies that the base calendar has been used to create customized calendars.';
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
        area(navigation)
        {
            group("&Base Calendar")
            {
                Caption = '&Base Calendar';
                Image = Calendar;
                action("&Where-Used List")
                {
                    ApplicationArea = Suite;
                    Caption = '&Where-Used List';
                    Image = Track;
                    ToolTip = 'View a list of the BOMs that the selected items are components of.';

                    trigger OnAction()
                    var
                        CalendarMgmt: Codeunit "Calendar Management";
                        WhereUsedList: Page "Where-Used Base Calendar";
                    begin
                        CalendarMgmt.CreateWhereUsedEntries(Rec.Code);
                        WhereUsedList.RunModal();
                        Clear(WhereUsedList);
                    end;
                }
                separator("-")
                {
                    Caption = '-';
                }
                action("&Base Calendar Changes")
                {
                    ApplicationArea = Suite;
                    Caption = '&Base Calendar Changes';
                    Image = Change;
                    RunObject = Page "Base Calendar Change List";
                    RunPageLink = "Base Calendar Code" = field(Code);
                    ToolTip = 'View changes to a base calendar entry. You would typically enter any nonworking days that you want to apply to a base calendar that you are setting up, to change their status from working to nonworking. You can also use this window to edit a base calendar that has already been set up.';
                }
            }
        }
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;
}

