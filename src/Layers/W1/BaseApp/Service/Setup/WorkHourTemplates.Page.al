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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs, Service;
                }
                field(Monday; Rec.Monday)
                {
                    ApplicationArea = Jobs, Service;
                }
                field(Tuesday; Rec.Tuesday)
                {
                    ApplicationArea = Jobs, Service;
                }
                field(Wednesday; Rec.Wednesday)
                {
                    ApplicationArea = Jobs, Service;
                }
                field(Thursday; Rec.Thursday)
                {
                    ApplicationArea = Jobs, Service;
                }
                field(Friday; Rec.Friday)
                {
                    ApplicationArea = Jobs, Service;
                }
                field(Saturday; Rec.Saturday)
                {
                    ApplicationArea = Jobs, Service;
                }
                field(Sunday; Rec.Sunday)
                {
                    ApplicationArea = Jobs, Service;
                }
                field("Total per Week"; Rec."Total per Week")
                {
                    ApplicationArea = Jobs, Service;
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

