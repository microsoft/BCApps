// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

page 99000751 "Shop Calendars"
{
    ApplicationArea = Manufacturing;
    Caption = 'Shop Calendars';
    PageType = List;
    SourceTable = "Shop Calendar";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a code to identify for this shop calendar.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the description of the shop calendar.';
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
            group("&Shop Cal.")
            {
                Caption = '&Shop Cal.';
                Image = Calendar;
                action("Working Days")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Working Days';
                    Image = Workdays;
                    RunObject = Page "Shop Calendar Working Days";
                    RunPageLink = "Shop Calendar Code" = field(Code);
                    ToolTip = 'View or edit the calendar days that are working days and at what time they start and end.';
                }
                action(Holidays)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Holidays';
                    Image = Holiday;
                    RunObject = Page "Shop Calendar Holidays";
                    RunPageLink = "Shop Calendar Code" = field(Code);
                    ToolTip = 'View or edit days that are registered as holidays. ';
                }
            }
        }
    }
}

