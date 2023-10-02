#if not CLEAN24
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

page 12146 "No. Series Lines Purchase"
{
    AutoSplitKey = true;
    Caption = 'No. Series Lines Purchase';
    DataCaptionFields = "Series Code";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "No. Series Line Purchase";
    SourceTableView = sorting("Series Code", "Starting Date", "Starting No.");
    ObsoleteReason = 'Merged into No. Series Lines page.';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Series Code"; Rec."Series Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series to which this line applies.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when you would like this line to apply.';
                }
                field("Starting No."; Rec."Starting No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first number in the series.';
                }
                field("Ending No."; Rec."Ending No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last number in the series.';
                }
                field("Last Date Used"; Rec."Last Date Used")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when a number was most recently assigned from the number series.';
                }
                field("Last No. Used"; Rec."Last No. Used")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last number that was used from the number series.';
                }
                field("Warning No."; Rec."Warning No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when you want to receive a warning that the number series is running out.';
                }
                field("Increment-by No."; Rec."Increment-by No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the size of the interval by which you would like to space the numbers in the number series.';
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether or not the number series line is open.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
    begin
        if NoSeriesLinePurchase.Get(Rec."Series Code", Rec."Line No.") then begin
            NoSeriesLinePurchase.SetRange("Series Code", Rec."Series Code");
            if NoSeriesLinePurchase.FindLast() then;
            Rec."Line No." := NoSeriesLinePurchase."Line No." + 10000;
        end;
        exit(true);
    end;
}
#endif