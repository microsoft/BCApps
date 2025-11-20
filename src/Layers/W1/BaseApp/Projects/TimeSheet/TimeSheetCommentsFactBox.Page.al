// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

page 947 "Time Sheet Comments FactBox"
{
    Caption = 'Comments';
    DataCaptionFields = "No.";
    LinksAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Editable = false;
    PageType = ListPart;
    SourceTable = "Time Sheet Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the comment that relates to a time sheet or time sheet line.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the date when you created a comment.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies a code for a comment.';
                    Visible = false;
                }
            }
        }
    }

    procedure UpdateData(TimeSheetNo: Code[20]; TimeSheetLineNo: Integer; IncludeTimeSheetHeaderComments: Boolean)
    begin
        Rec.Reset();
        Rec.FilterGroup(2);
        Rec.SetRange("No.", TimeSheetNo);
        if IncludeTimeSheetHeaderComments then
            Rec.SetFilter("Time Sheet Line No.", '%1|%2', 0, TimeSheetLineNo)
        else
            Rec.SetRange("Time Sheet Line No.", TimeSheetLineNo);
        Rec.FilterGroup(0);

        CurrPage.Update(false);
    end;
}