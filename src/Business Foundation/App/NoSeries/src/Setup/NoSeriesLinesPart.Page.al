// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

page 421 "No. Series Lines Part"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'No. Series Lines';
    DataCaptionFields = "Series Code";
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "No. Series Line";
    SourceTableView = sorting("Series Code", "Starting Date", "Starting No.");

    layout
    {
        area(Content)
        {
            repeater(Repeater)
            {
                ShowCaption = false;
                field("Series Code"; Rec."Series Code")
                {
                    Caption = 'Series Code';
                    ToolTip = 'Specifies the code for the number series to which this line applies.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the date from which you would like this line to apply.';
                    Visible = false;
                }
                field("Starting No."; Rec."Starting No.")
                {
                    Caption = 'Starting No.';
                    ToolTip = 'Specifies the first number in the series.';
                }
                field("Ending No."; Rec."Ending No.")
                {
                    Caption = 'Ending No.';
                    ToolTip = 'Specifies the last number in the series.';
                }
                field("Last Date Used"; Rec."Last Date Used")
                {
                    Caption = 'Last Date Used';
                    ToolTip = 'Specifies the date when a number was most recently assigned from the number series.';
                    Visible = false;
                }
                field("Last No. Used"; Rec."Last No. Used")
                {
                    Caption = 'Last No. Used';
                    ToolTip = 'Specifies the last number that was used from the number series.';
                }
                field("Warning No."; Rec."Warning No.")
                {
                    Caption = 'Warning No.';
                    ToolTip = 'Specifies when you want to receive a warning that the number series is running out.';
                    Visible = false;
                }
                field("Increment-by No."; Rec."Increment-by No.")
                {
                    Caption = 'Increment-by No.';
                    ToolTip = 'Specifies the size of the interval by which you would like to space the numbers in the number series.';
                    Visible = false;
                }
                field("Allow Gaps in Nos."; AllowGaps)
                {
                    Caption = 'Allow Gaps in Nos.';
                    ToolTip = 'Specifies that a number assigned from the number series can later be deleted. This is practical for records, such as item cards and warehouse documents that, unlike financial transactions, can be deleted and cause gaps in the number sequence. NOTE: If an error occurs on a new record that will be assigned a number from such a number series when it is completed, the number in question may be lost, causing a gap in the sequence.';
                    Visible = false;
                }
                field(Implementation; Rec.Implementation)
                {
                    Caption = 'Implementation';
                    ToolTip = 'Specifies the implementation to use for getting numbers. Some may produce gaps in the number series. This is practical for records, such as item cards and warehouse documents that, unlike financial transactions, can be deleted and cause gaps in the number sequence.';
                    Visible = false;
                }
                field(Open; Rec.Open)
                {
                    Caption = 'Open';
                    ToolTip = 'Specifies whether the number series line is open. It is open until the last number in the series has been used.';
                    Visible = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        NoSeries: Codeunit "No. Series";
        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
    begin
        Rec."Last No. Used" := NoSeries.GetLastNoUsed(Rec);
        AllowGaps := NoSeriesSetupImpl.MayProduceGaps(Rec);
    end;

    var
        AllowGaps: Boolean;
}