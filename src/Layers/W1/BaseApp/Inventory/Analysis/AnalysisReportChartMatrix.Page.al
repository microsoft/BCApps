// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

page 776 "Analysis Report Chart Matrix"
{
    Caption = 'Analysis Report Chart Matrix';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Analysis Report Chart Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("<Row No.>"; AnalysisLineRowNo)
                {
                    ApplicationArea = Suite;
                    Caption = 'Row No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of the row in the chart.';
                }
                field("<Description>"; AnalysisLineDescription)
                {
                    ApplicationArea = Suite;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies a description of the chart.';
                }
                field(Column1; ChartType[1])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[1];

                    trigger OnValidate()
                    begin
                        SetChartType(1);
                    end;
                }
                field(Column2; ChartType[2])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[2];

                    trigger OnValidate()
                    begin
                        SetChartType(2);
                    end;
                }
                field(Column3; ChartType[3])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[3];

                    trigger OnValidate()
                    begin
                        SetChartType(3);
                    end;
                }
                field(Column4; ChartType[4])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[4];

                    trigger OnValidate()
                    begin
                        SetChartType(4);
                    end;
                }
                field(Column5; ChartType[5])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[5];

                    trigger OnValidate()
                    begin
                        SetChartType(5);
                    end;
                }
                field(Column6; ChartType[6])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[6];

                    trigger OnValidate()
                    begin
                        SetChartType(6);
                    end;
                }
                field(Column7; ChartType[7])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[7];

                    trigger OnValidate()
                    begin
                        SetChartType(7);
                    end;
                }
                field(Column8; ChartType[8])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[8];

                    trigger OnValidate()
                    begin
                        SetChartType(8);
                    end;
                }
                field(Column9; ChartType[9])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[9];

                    trigger OnValidate()
                    begin
                        SetChartType(9);
                    end;
                }
                field(Column10; ChartType[10])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[10];

                    trigger OnValidate()
                    begin
                        SetChartType(10);
                    end;
                }
                field(Column11; ChartType[11])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[11];

                    trigger OnValidate()
                    begin
                        SetChartType(11);
                    end;
                }
                field(Column12; ChartType[12])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[12];

                    trigger OnValidate()
                    begin
                        SetChartType(12);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Select All';
                Image = AllLines;
                ToolTip = 'Select all lines.';

                trigger OnAction()
                var
                    AnalysisReportChartLine: Record "Analysis Report Chart Line";
                    AnalysisReportChartMgt: Codeunit "Analysis Report Chart Mgt.";
                begin
                    AnalysisReportChartLine.Copy(Rec);
                    AnalysisReportChartLine.SetRange("Analysis Column Line No.");
                    AnalysisReportChartMgt.SelectAll(AnalysisReportChartLine, true);
                end;
            }
            action(ShowNone)
            {
                ApplicationArea = Suite;
                Caption = 'Deselect All';
                Image = CancelAllLines;
                ToolTip = 'Unselect all lines.';

                trigger OnAction()
                var
                    AnalysisReportChartLine: Record "Analysis Report Chart Line";
                    AnalysisReportChartMgt: Codeunit "Analysis Report Chart Mgt.";
                begin
                    AnalysisReportChartLine.Copy(Rec);
                    AnalysisReportChartLine.SetRange("Analysis Column Line No.");
                    AnalysisReportChartMgt.DeselectAll(AnalysisReportChartLine, true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowAll_Promoted; ShowAll)
                {
                }
                actionref(ShowNone_Promoted; ShowNone)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        AnalysisLine: Record "Analysis Line";
    begin
        if AnalysisLine.Get(Rec."Analysis Area", Rec."Analysis Line Template Name", Rec."Analysis Line Line No.") then begin
            AnalysisLineRowNo := AnalysisLine."Row Ref. No.";
            AnalysisLineDescription := AnalysisLine.Description;
            GetChartTypes();
        end;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(Rec.FindSet());
    end;

    var
        AnalysisLineRowNo: Code[20];
        AnalysisLineDescription: Text[100];
        ChartType: array[12] of Option " ",Line,StepLine,Column,StackedColumn;
        ColumnCaptions: array[12] of Text[100];
        ColumnLineNos: array[12] of Integer;
        MaxColumns: Integer;
#pragma warning disable AA0074
        Text001: Label 'Invalid Column Layout.';
#pragma warning restore AA0074

    procedure SetFilters(AnalysisReportChartSetup: Record "Analysis Report Chart Setup")
    begin
        Rec.Reset();

        AnalysisReportChartSetup.SetLinkToLines(Rec);
        case AnalysisReportChartSetup."Base X-Axis on" of
            AnalysisReportChartSetup."Base X-Axis on"::Period:
                if Rec.FindFirst() then
                    Rec.SetRange("Analysis Column Line No.", Rec."Analysis Column Line No.");
            AnalysisReportChartSetup."Base X-Axis on"::Line,
          AnalysisReportChartSetup."Base X-Axis on"::Column:
                Rec.SetRange("Analysis Column Line No.", 0);
        end;
        UpdateColumnCaptions(AnalysisReportChartSetup);
    end;

    local procedure UpdateColumnCaptions(AnalysisReportChartSetup: Record "Analysis Report Chart Setup")
    var
        AnalysisColumn: Record "Analysis Column";
        ColumnNo: Integer;
        i: Integer;
    begin
        Clear(ColumnCaptions);
        AnalysisReportChartSetup.FilterAnalysisColumn(AnalysisColumn);

        if AnalysisColumn.FindSet() then
            repeat
                ColumnNo := ColumnNo + 1;
                ColumnCaptions[ColumnNo] := AnalysisColumn."Column Header";
                ColumnLineNos[ColumnNo] := AnalysisColumn."Line No.";
            until (AnalysisColumn.Next() = 0) or (ColumnNo = ArrayLen(ColumnCaptions));
        MaxColumns := ColumnNo;
        // Set unused columns to blank to prevent RTC to display control ID as caption
        for i := MaxColumns + 1 to ArrayLen(ColumnCaptions) do
            ColumnCaptions[i] := ' ';
    end;

    local procedure GetChartTypes()
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        AnalysisReportChartLine: Record "Analysis Report Chart Line";
        AnalysisReportChartLine2: Record "Analysis Report Chart Line";
        i: Integer;
    begin
        AnalysisReportChartSetup.Get(Rec."User ID", Rec."Analysis Area", Rec.Name);
        case AnalysisReportChartSetup."Base X-Axis on" of
            AnalysisReportChartSetup."Base X-Axis on"::Period:
                for i := 1 to MaxColumns do begin
                    AnalysisReportChartLine.Get(Rec."User ID", Rec."Analysis Area", Rec.Name, Rec."Analysis Line Line No.", ColumnLineNos[i]);
                    ChartType[i] := AnalysisReportChartLine."Chart Type";
                end;
            AnalysisReportChartSetup."Base X-Axis on"::Line:
                begin
                    AnalysisReportChartLine.Get(Rec."User ID", Rec."Analysis Area", Rec.Name, Rec."Analysis Line Line No.", 0);
                    if AnalysisReportChartLine."Chart Type" <> AnalysisReportChartLine."Chart Type"::" " then
                        for i := 1 to MaxColumns do begin
                            AnalysisReportChartLine2.Get(Rec."User ID", Rec."Analysis Area", Rec.Name, 0, ColumnLineNos[i]);
                            ChartType[i] := AnalysisReportChartLine2."Chart Type";
                        end
                    else
                        for i := 1 to MaxColumns do
                            ChartType[i] := AnalysisReportChartLine2."Chart Type"::" ";
                end;
            AnalysisReportChartSetup."Base X-Axis on"::Column:
                begin
                    AnalysisReportChartLine.Get(Rec."User ID", Rec."Analysis Area", Rec.Name, Rec."Analysis Line Line No.", 0);
                    for i := 1 to MaxColumns do begin
                        AnalysisReportChartLine2.Get(Rec."User ID", Rec."Analysis Area", Rec.Name, 0, ColumnLineNos[i]);
                        if AnalysisReportChartLine2."Chart Type" <> AnalysisReportChartLine2."Chart Type"::" " then
                            ChartType[i] := AnalysisReportChartLine."Chart Type"
                        else
                            ChartType[i] := AnalysisReportChartLine."Chart Type"::" ";
                    end;
                end;
        end;
        for i := MaxColumns + 1 to ArrayLen(ColumnCaptions) do
            ChartType[i] := AnalysisReportChartLine."Chart Type"::" ";
    end;

    local procedure SetChartType(ColumnNo: Integer)
    var
        AnalysisReportChartLine: Record "Analysis Report Chart Line";
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        if ColumnNo > MaxColumns then
            Error(Text001);

        AnalysisReportChartSetup.Get(Rec."User ID", Rec."Analysis Area", Rec.Name);
        case AnalysisReportChartSetup."Base X-Axis on" of
            AnalysisReportChartSetup."Base X-Axis on"::Period:
                AnalysisReportChartLine.Get(Rec."User ID", Rec."Analysis Area", Rec.Name, Rec."Analysis Line Line No.", ColumnLineNos[ColumnNo]);
            AnalysisReportChartSetup."Base X-Axis on"::Line:
                AnalysisReportChartLine.Get(Rec."User ID", Rec."Analysis Area", Rec.Name, 0, ColumnLineNos[ColumnNo]);
            AnalysisReportChartSetup."Base X-Axis on"::Column:
                AnalysisReportChartLine.Get(Rec."User ID", Rec."Analysis Area", Rec.Name, Rec."Analysis Line Line No.", 0);
        end;
        AnalysisReportChartLine.Validate("Chart Type", ChartType[ColumnNo]);
        AnalysisReportChartLine.Modify();
        CurrPage.Update();
    end;
}

