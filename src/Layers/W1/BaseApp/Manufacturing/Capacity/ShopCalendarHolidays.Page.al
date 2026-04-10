// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

page 99000753 "Shop Calendar Holidays"
{
    Caption = 'Shop Calendar Holidays';
    DataCaptionFields = "Shop Calendar Code";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Shop Calendar Holiday";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
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
    }
}

