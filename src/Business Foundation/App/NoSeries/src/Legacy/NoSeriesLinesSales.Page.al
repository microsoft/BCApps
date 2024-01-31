#if not CLEAN24
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

page 12145 "No. Series Lines Sales"
{
    AutoSplitKey = true;
    Caption = 'No. Series Lines Sales';
    DataCaptionFields = "Series Code";
    DelayedInsert = true;
    ObsoleteReason = 'Merged into No. Series Lines page.';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';
    PageType = List;
    SourceTable = "No. Series Line Sales";
    SourceTableView = sorting("Series Code", "Starting Date", "Starting No.");

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Series Code"; Rec."Series Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Series Code';
                    ToolTip = 'Specifies the number series code for the line.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the date from which you would like this line to apply.';
                }
                field("Starting No."; Rec."Starting No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting No.';
                    ToolTip = 'Specifies the first number in the series.';
                }
                field("Ending No."; Rec."Ending No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending No.';
                    ToolTip = 'Specifies the last number in the series.';
                }
                field("Last Date Used"; Rec."Last Date Used")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Date Used';
                    ToolTip = 'Specifies the date when a number was most recently assigned from the number series.';
                }
                field("Last No. Used"; Rec."Last No. Used")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last No. Used';
                    ToolTip = 'Specifies the last number that was used from the number series.';
                }
                field("Warning No."; Rec."Warning No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Warning No.';
                    ToolTip = 'Specifies if you want to receive a warning that the number series is running out.';
                }
                field("Increment-by No."; Rec."Increment-by No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Increment-by No.';
                    ToolTip = 'Specifies the size of the interval by which you would like to space the numbers in the number series.';
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open';
                    ToolTip = 'Specifies whether or not the number series line is open.';
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        NoSeriesLineSales: Record "No. Series Line Sales";
    begin
        if NoSeriesLineSales.Get(Rec."Series Code", Rec."Line No.") then begin
            NoSeriesLineSales.SetRange("Series Code", Rec."Series Code");
            if NoSeriesLineSales.FindLast() then;
            Rec."Line No." := NoSeriesLineSales."Line No." + 10000;
        end;
        exit(true);
    end;
}
#endif