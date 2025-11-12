// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

page 5234 "HR Confidential Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'Confidential Comment Sheet';
    DataCaptionExpression = Caption(Rec);
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "HR Confidential Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the date when the comment was created.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the comment itself.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a code for the comment.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine();
    end;

    var
        Employee: Record Employee;
        ConfidentialInfo: Record "Confidential Information";

#pragma warning disable AA0074
        Text000: Label 'untitled';
#pragma warning restore AA0074

    procedure Caption(HRCommentLine: Record "HR Confidential Comment Line"): Text
    begin
        if ConfidentialInfo.Get(HRCommentLine."No.", HRCommentLine.Code, HRCommentLine."Table Line No.") and
           Employee.Get(HRCommentLine."No.")
        then
            exit(HRCommentLine."No." + ' ' + Employee.FullName() + ' ' +
              ConfidentialInfo."Confidential Code");
        exit(Text000);
    end;
}

