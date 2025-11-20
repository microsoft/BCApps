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
                    ToolTip = 'Specifies a number for the employee.';
                    Visible = false;
                }
                field("Misc. Article Code"; Rec."Misc. Article Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a code to define the type of miscellaneous article.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a description of the miscellaneous article.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the miscellaneous article.';
                }
                field("From Date"; Rec."From Date")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the date when the employee first received the miscellaneous article.';
                }
                field("To Date"; Rec."To Date")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the date when the employee no longer possesses the miscellaneous article.';
                }
                field("In Use"; Rec."In Use")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies that the miscellaneous article is in use.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies if a comment is associated with this entry.';
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

