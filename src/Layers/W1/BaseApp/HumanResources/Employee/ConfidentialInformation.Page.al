// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

page 5221 "Confidential Information"
{
    AutoSplitKey = true;
    Caption = 'Confidential Information';
    DataCaptionFields = "Employee No.";
    PageType = List;
    SourceTable = "Confidential Information";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Confidential Code"; Rec."Confidential Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a code to define the type of confidential information.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a description of the confidential information.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies if a comment is associated with the entry.';
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
            group("&Confidential")
            {
                Caption = '&Confidential';
                Image = ConfidentialOverview;
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';

                    trigger OnAction()
                    var
                        HRConfidentialCommentLine: Record "HR Confidential Comment Line";
                    begin
                        HRConfidentialCommentLine.SetRange("Table Name", HRConfidentialCommentLine."Table Name"::"Confidential Information");
                        HRConfidentialCommentLine.SetRange("No.", Rec."Employee No.");
                        HRConfidentialCommentLine.SetRange(Code, Rec."Confidential Code");
                        HRConfidentialCommentLine.SetRange("Table Line No.", Rec."Line No.");
                        PAGE.RunModal(PAGE::"HR Confidential Comment Sheet", HRConfidentialCommentLine);
                    end;
                }
            }
        }
        area(Promoted)
        {
        }
    }
}

