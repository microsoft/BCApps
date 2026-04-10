// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Absence;

using Microsoft.HumanResources.Comment;

page 5211 "Employee Absences"
{
    Caption = 'Employee Absences';
    DataCaptionFields = "Employee No.";
    DelayedInsert = true;
    Editable = false;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Employee Absence";
    SourceTableView = sorting("Employee No.", "From Date");

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
                field("Cause of Absence Code"; Rec."Cause of Absence Code")
                {
                    ApplicationArea = BasicHR;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicHR;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = BasicHR;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the quantity associated with absences, in hours or days.';
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
            group("A&bsence")
            {
                Caption = 'A&bsence';
                Image = Absence;
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Human Resource Comment Sheet";
                    RunPageLink = "Table Name" = const("Employee Absence"),
                                  "Table Line No." = field("Entry No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
    }
}

