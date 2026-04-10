// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

page 275 "Job Journal Template List"
{
    Caption = 'Project Journal Template List';
    Editable = false;
    PageType = List;
    SourceTable = "Job Journal Template";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Jobs;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                }
                field("Test Report ID"; Rec."Test Report ID")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Posting Report ID"; Rec."Posting Report ID")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Force Posting Report"; Rec."Force Posting Report")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Test Report Caption"; Rec."Test Report Caption")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Posting Report Caption"; Rec."Posting Report Caption")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
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

