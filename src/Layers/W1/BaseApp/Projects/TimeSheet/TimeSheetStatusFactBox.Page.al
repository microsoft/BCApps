// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

page 957 "Time Sheet Status FactBox"
{
    Caption = 'Time Sheet Status';
    PageType = CardPart;

    layout
    {
        area(Content)
        {
            field(Comment; Comment)
            {
                ApplicationArea = Comments;
                Caption = 'Comment';
                ToolTip = 'Specifies a comment that applies to the time sheet status.';
            }
            field(OpenQty; OpenQty)
            {
                ApplicationArea = Jobs;
                Caption = 'Open';
                DecimalPlaces = 2 : 2;
                Editable = false;
                ToolTip = 'Specifies the sum of time sheet hours for open time sheets.';
            }
            field(SubmittedQty; SubmittedQty)
            {
                ApplicationArea = Jobs;
                Caption = 'Submitted';
                DecimalPlaces = 2 : 2;
                Editable = false;
                ToolTip = 'Specifies the sum of time sheet hours for submitted time sheets.';
            }
            field(RejectedQty; RejectedQty)
            {
                ApplicationArea = Jobs;
                Caption = 'Rejected';
                DecimalPlaces = 2 : 2;
                Editable = false;
                ToolTip = 'Specifies the sum of time sheet hours for rejected time sheets.';
            }
            field(ApprovedQty; ApprovedQty)
            {
                ApplicationArea = Jobs;
                Caption = 'Approved';
                DecimalPlaces = 2 : 2;
                Editable = false;
                ToolTip = 'Specifies the sum of time sheet hours for approved time sheets.';
            }
            field(TotalQuantity; TotalQuantity)
            {
                ApplicationArea = Jobs;
                Caption = 'Total';
                DecimalPlaces = 2 : 2;
                Editable = false;
                Style = Strong;
                StyleExpr = true;
                ToolTip = 'Specifies the sum of time sheet hours for time sheets of all statuses.';
            }
            field(PostedQty; PostedQty)
            {
                ApplicationArea = Jobs;
                Caption = 'Posted';
                DecimalPlaces = 2 : 2;
                Editable = false;
                ToolTip = 'Specifies the sum of time sheet hours for posted time sheets.';
            }
        }
    }

    actions
    {
    }

    var
        TimeSheetMgt: Codeunit "Time Sheet Management";
        Comment: Boolean;
        ApprovedQty: Decimal;
        OpenQty: Decimal;
        PostedQty: Decimal;
        RejectedQty: Decimal;
        SubmittedQty: Decimal;
        TotalQuantity: Decimal;

    procedure UpdateData(TimeSheetHeader: Record "Time Sheet Header")
    begin
        TimeSheetMgt.CalcStatusFactBoxData(
          TimeSheetHeader,
          OpenQty,
          SubmittedQty,
          RejectedQty,
          ApprovedQty,
          PostedQty,
          TotalQuantity);

        TimeSheetHeader.CalcFields(Comment);
        Comment := TimeSheetHeader.Comment;
        CurrPage.Update(false);
    end;

    procedure UpdateDataInclFilters(var TimeSheetHeader: Record "Time Sheet Header")
    begin
        TimeSheetMgt.CalcStatusFactBoxData(
          TimeSheetHeader,
          OpenQty,
          SubmittedQty,
          RejectedQty,
          ApprovedQty,
          PostedQty,
          TotalQuantity);

        TimeSheetHeader.CalcFields(Comment);
        Comment := TimeSheetHeader.Comment;
        CurrPage.Update(false);
    end;
}

