// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Archive;

using Microsoft.Foundation.Comment;
using System.Security.User;

page 5176 "Job Archive List"
{
    AdditionalSearchTerms = 'Projects, Projects List, Archive, Jobs Archives';
    ApplicationArea = Jobs;
    Caption = 'Project Archives';
    CardPageID = "Job Archive Card";
    Editable = false;
    PageType = List;
    QueryCategory = 'Project Archive List';
    SourceTable = "Job Archive";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Version No."; Rec."Version No.")
                {
                    ApplicationArea = Suite;
                }
                field("Date Archived"; Rec."Date Archived")
                {
                    ApplicationArea = Suite;
                }
                field("Time Archived"; Rec."Time Archived")
                {
                    ApplicationArea = Suite;
                }
                field("Archived By"; Rec."Archived By")
                {
                    ApplicationArea = Suite;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Archived By");
                    end;
                }
                field("Interaction Exist"; Rec."Interaction Exist")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Jobs;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Jobs;
                }
                field("Person Responsible"; Rec."Person Responsible")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the person responsible for the project. You can select a name from the list of resources available in the Resource List window. The name is copied from the No. field in the Resource table. You can choose the field to see a list of resources.';
                    Visible = false;
                }
                field("Next Invoice Date"; Rec."Next Invoice Date")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Job Posting Group"; Rec."Job Posting Group")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a project posting group code for a project. To see the available codes, choose the field.';
                    Visible = false;
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = Jobs;
                }
                field("Project Manager"; Rec."Project Manager")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the person assigned as the manager for this project.';
                    Visible = false;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Your Reference"; Rec."Your Reference")
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
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Job")
            {
                Caption = '&Project';
                Image = Job;
                action("Job Task &Lines")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Task Archive &Lines';
                    Image = TaskList;
                    RunObject = Page "Job Task Archive Lines";
                    RunPageLink = "Job No." = field("No."), "Version No." = field("Version No.");
                    ToolTip = 'Plan how you want to set up your planning information. In this window you can specify the tasks involved in a project. To start planning a project or to post usage for a project, you must set up at least one project task.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet Archive";
                    RunPageLink = "Table Name" = const(Job),
                                  "No." = field("No."),
                                  "Version No." = field("Version No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Category5)
            {
                Caption = 'Project', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("Job Task &Lines_Promoted"; "Job Task &Lines")
                {
                }
            }
        }
    }
}

