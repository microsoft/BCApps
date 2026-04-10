// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.HumanResources.Analysis;
using Microsoft.HumanResources.Comment;

page 5207 "Qualified Employees"
{
    Caption = 'Qualified Employees';
    DataCaptionFields = "Qualification Code";
    Editable = false;
    PageType = List;
    SourceTable = "Employee Qualification";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = BasicHR;
                }
                field("From Date"; Rec."From Date")
                {
                    ApplicationArea = BasicHR;
                }
                field("To Date"; Rec."To Date")
                {
                    ApplicationArea = BasicHR;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = BasicHR;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicHR;
                }
                field("Institution/Company"; Rec."Institution/Company")
                {
                    ApplicationArea = BasicHR;
                }
                field(Cost; Rec.Cost)
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field("Course Grade"; Rec."Course Grade")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Q&ualification")
            {
                Caption = 'Q&ualification';
                Image = Certificate;
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Human Resource Comment Sheet";
                    RunPageLink = "Table Name" = const("Employee Qualification"),
                                  "No." = field("Employee No."),
                                  "Table Line No." = field("Line No.");
                    ToolTip = 'View or add comments for the record.';
                }
                separator(Action27)
                {
                }
                action("Q&ualification Overview")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Q&ualification Overview';
                    Image = QualificationOverview;
                    RunObject = Page "Qualification Overview";
                    ToolTip = 'View qualifications that are registered for the employee.';
                }
            }
        }
    }
}

