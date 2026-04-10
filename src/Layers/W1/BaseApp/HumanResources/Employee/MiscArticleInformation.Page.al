// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.HumanResources.Comment;

page 5219 "Misc. Article Information"
{
    Caption = 'Misc. Article Information';
    DataCaptionFields = "Employee No.";
    PageType = List;
    SourceTable = "Misc. Article Information";

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
                    Visible = false;
                }
                field("Misc. Article Code"; Rec."Misc. Article Code")
                {
                    ApplicationArea = BasicHR;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicHR;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("From Date"; Rec."From Date")
                {
                    ApplicationArea = BasicHR;
                }
                field("To Date"; Rec."To Date")
                {
                    ApplicationArea = BasicHR;
                }
                field("In Use"; Rec."In Use")
                {
                    ApplicationArea = BasicHR;
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
            group("Mi&sc. Article")
            {
                Caption = 'Mi&sc. Article';
                Image = FiledOverview;
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Human Resource Comment Sheet";
                    RunPageLink = "Table Name" = const("Misc. Article Information"),
                                  "No." = field("Employee No."),
                                  "Alternative Address Code" = field("Misc. Article Code"),
                                  "Table Line No." = field("Line No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
    }
}

