// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

page 457 "No. Series Lines"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'No. Series Lines';
    DataCaptionFields = "Series Code";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "No. Series Line";
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
                    Caption = 'Series Code';
                    ToolTip = 'Specifies the code for the number series to which this line applies.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the date from which you would like this line to apply.';
                }
                field("Starting No."; Rec."Starting No.")
                {
                    Caption = 'Starting No.';
                    ToolTip = 'Specifies the first number in the series.';
                    ShowMandatory = true;
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
                }
                field("Last No. Used"; Rec."Last No. Used")
                {
                    Caption = 'Last No. Used';
                    ToolTip = 'Specifies the last number that was used from the number series.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Warning No."; Rec."Warning No.")
                {
                    Caption = 'Warning No.';
                    ToolTip = 'Specifies when you want to receive a warning that the number series is running out.';
                }
                field("Increment-by No."; Rec."Increment-by No.")
                {
                    Caption = 'Increment-by No.';
                    ToolTip = 'Specifies the size of the interval by which you would like to space the numbers in the number series.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Allow Gaps in Nos."; AllowGaps)
                {
                    Caption = 'Allow Gaps in Nos.';
                    ToolTip = 'Specifies that a number assigned from the number series can later be deleted. This is practical for records, such as item cards and warehouse documents that, unlike financial transactions, can be deleted and cause gaps in the number sequence. NOTE: If an error occurs on a new record that will be assigned a number from such a number series when it is completed, the number in question may be lost, causing a gap in the sequence.';
#if CLEAN24
                    Editable = false;
#endif

#if not CLEAN24
#pragma warning disable AL0432
                    trigger OnValidate()
                    begin
                        Rec.Validate("Allow Gaps in Nos.", AllowGaps);
                        CurrPage.Update(true);
                    end;
#pragma warning restore AL0432
#endif
                }
                field(Implementation; Rec.Implementation)
                {
                    Caption = 'Implementation';
                    ToolTip = 'Specifies the implementation to use for getting numbers. Some may produce gaps in the number series. This is practical for records, such as item cards and warehouse documents that, unlike financial transactions, can be deleted and cause gaps in the number sequence.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Open; Rec.Open)
                {
                    Caption = 'Open';
                    ToolTip = 'Specifies whether the number series line is open. It is open until the last number in the series has been used.';
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        NoSeries: Codeunit "No. Series";
    begin
        Rec."Last No. Used" := NoSeries.GetLastNoUsed(Rec);
    end;

    trigger OnAfterGetRecord()
    var
        NoSeries: Codeunit "No. Series";
        NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
    begin
        Rec."Last No. Used" := NoSeries.GetLastNoUsed(Rec);
        AllowGaps := NoSeriesSetupImpl.MayProduceGaps(Rec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.Copy(Rec);
        if BelowxRec then
            if NoSeriesLine.FindLast() then begin
                Rec.Validate("Increment-by No.", NoSeriesLine."Increment-by No.");
                Rec.Validate(Implementation, NoSeriesLine.Implementation);
            end;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        if NoSeriesLine.Get(Rec."Series Code", Rec."Line No.") then begin
            NoSeriesLine.SetRange("Series Code", Rec."Series Code");
            if NoSeriesLine.FindLast() then;
            Rec."Line No." := NoSeriesLine."Line No." + 10000;
        end;
        exit(true);
    end;

    var
        AllowGaps: Boolean;
}