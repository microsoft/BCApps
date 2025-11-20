// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Setup;

page 6017 "Work-Hour Templates"
{
    ApplicationArea = Jobs, Service;
    Caption = 'Work-Hour Templates';
    PageType = List;
    SourceTable = "Work-Hour Template";
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
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies a code for the work-hour template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies a description of the work-hour template.';
                }
                field(Monday; Rec.Monday)
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies the number of work-hours on Monday.';
                }
                field(Tuesday; Rec.Tuesday)
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies the number of work-hours on Tuesday.';
                }
                field(Wednesday; Rec.Wednesday)
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies the number of work-hours on Wednesday.';
                }
                field(Thursday; Rec.Thursday)
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies the number of work-hours on Thursday.';
                }
                field(Friday; Rec.Friday)
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies the number of work-hours on Friday.';
                }
                field(Saturday; Rec.Saturday)
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies the number of work-hours on Saturday.';
                }
                field(Sunday; Rec.Sunday)
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies the number of work-hours on Sunday.';
                }
                field("Total per Week"; Rec."Total per Week")
                {
                    ApplicationArea = Jobs, Service;
                    ToolTip = 'Specifies the total number of work-hours per week for the work-hour template.';
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

