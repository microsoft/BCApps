// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.FinancialReports;
using System.Visualization;

codeunit 770 "Analysis Report Chart Mgt."
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        DefaultTXT: Label 'DEFAULT', Comment = 'The default name of the chart setup.';
#pragma warning disable AA0470
        DuplicateDescERR: Label 'Account Schedule %1 has duplicate Description values.';
        DuplicateColHdrERR: Label 'Column Layout %1 has duplicate Column Header values.';
#pragma warning restore AA0470
        Text001: Label '%1 | %2 (Updated %3)', Comment = '%1 Account Schedule Chart Setup Name, %2 Period, %3 Current time';
        Text002: Label '%1..%2', Comment = '%1 = Start Date, %2 = End Date', Locked = true;
        Text003: Label 'Analysis line or analysis column has been modified since the chart setup was created. Please reset your chart setup.';
#pragma warning restore AA0074

    local procedure GetSetup(var AnalysisReportChartSetup: Record "Analysis Report Chart Setup"; AnalysisArea: Option; ChartName: Text[30])
    var
        Found: Boolean;
    begin
        if AnalysisReportChartSetup.Get(UserId, AnalysisArea, ChartName) then begin
            AnalysisReportChartSetup.SetLastViewed();
            exit;
        end;

        AnalysisReportChartSetup.SetRange("User ID", UserId);
        AnalysisReportChartSetup.SetRange("Analysis Area", AnalysisArea);
        AnalysisReportChartSetup.SetRange("Last Viewed", true);
        Found := AnalysisReportChartSetup.FindFirst();
        AnalysisReportChartSetup.Reset();
        if Found then
            exit;

        ChartName := DefaultTXT;

        if not AnalysisReportChartSetup.Get(UserId, AnalysisArea, ChartName) then begin
            AnalysisReportChartSetup.Init();
            AnalysisReportChartSetup."User ID" := CopyStr(UserId(), 1, MaxStrLen(AnalysisReportChartSetup."User ID"));
            AnalysisReportChartSetup."Analysis Area" := "Analysis Area Type".FromInteger(AnalysisArea);
            AnalysisReportChartSetup.Name := ChartName;
            AnalysisReportChartSetup."Base X-Axis on" := AnalysisReportChartSetup."Base X-Axis on"::Period;
            AnalysisReportChartSetup."Start Date" := WorkDate();
            AnalysisReportChartSetup."Period Length" := AnalysisReportChartSetup."Period Length"::Day;
            AnalysisReportChartSetup.Insert();
        end;
        AnalysisReportChartSetup.SetLastViewed();
    end;

    [Scope('OnPrem')]
    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer"; AnalysisReportChartSetup: Record "Analysis Report Chart Setup")
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        AnalysisReportMgt: Codeunit "Analysis Report Management";
    begin
        GetAnalysisLineAndColumnForDrillDown(AnalysisLine, AnalysisColumn, BusChartBuf, AnalysisReportChartSetup);
        AnalysisReportMgt.CalcCell(AnalysisLine, AnalysisColumn, true);
    end;

    [Scope('OnPrem')]
    procedure UpdateData(var BusChartBuf: Record "Business Chart Buffer"; AnalysisReportChartSetup: Record "Analysis Report Chart Setup"; Period: Option " ",Next,Previous)
    var
        BusChartMapColumn: Record "Business Chart Map";
        AnalysisReportChartLine: Record "Analysis Report Chart Line";
        AnalysisReportChartLine2: Record "Analysis Report Chart Line";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        AnalysisReportMgt: Codeunit "Analysis Report Management";
        FromDate: Date;
        ToDate: Date;
        NoOfPeriods: Integer;
        PeriodCounter: Integer;
        XCounter: Integer;
    begin
        Commit();
        CheckDuplicateAnalysisLineDescription(
          AnalysisReportChartSetup."Analysis Area".AsInteger(), AnalysisReportChartSetup."Analysis Line Template Name");
        CheckDuplicateAnalysisColumnHeader(
          AnalysisReportChartSetup."Analysis Area".AsInteger(), AnalysisReportChartSetup."Analysis Column Template Name");

        BusChartBuf."Period Length" := AnalysisReportChartSetup."Period Length";

        case AnalysisReportChartSetup."Base X-Axis on" of
            AnalysisReportChartSetup."Base X-Axis on"::Period:
                if Period = Period::" " then begin
                    FromDate := 0D;
                    ToDate := 0D;
                end else
                    if BusChartBuf.FindMidColumn(BusChartMapColumn) then
                        BusChartBuf.GetPeriodFromMapColumn(BusChartMapColumn.Index, FromDate, ToDate);
            AnalysisReportChartSetup."Base X-Axis on"::Line,
            AnalysisReportChartSetup."Base X-Axis on"::Column:
                if (BusChartBuf."Period Filter Start Date" = 0D) and (AnalysisReportChartSetup."Start Date" <> 0D) then
                    BusChartBuf.InitializePeriodFilter(AnalysisReportChartSetup."Start Date", AnalysisReportChartSetup."End Date")
                else
                    BusChartBuf.RecalculatePeriodFilter(BusChartBuf."Period Filter Start Date", BusChartBuf."Period Filter End Date", Period);
        end;

        BusChartBuf.Initialize();
        case AnalysisReportChartSetup."Base X-Axis on" of
            AnalysisReportChartSetup."Base X-Axis on"::Period:
                begin
                    BusChartBuf.SetPeriodXAxis();
                    NoOfPeriods := AnalysisReportChartSetup."No. of Periods";
                    CalcAndInsertPeriodAxis(BusChartBuf, AnalysisReportChartSetup, Period, NoOfPeriods, FromDate, ToDate);
                end;
            AnalysisReportChartSetup."Base X-Axis on"::Line:
                BusChartBuf.SetXAxis(AnalysisLine.FieldCaption(Description), BusChartBuf."Data Type"::String);
            AnalysisReportChartSetup."Base X-Axis on"::Column:
                BusChartBuf.SetXAxis(AnalysisColumn.FieldCaption("Column Header"), BusChartBuf."Data Type"::String);
        end;

        AddMeasures(BusChartBuf, AnalysisReportChartSetup);

        case AnalysisReportChartSetup."Base X-Axis on" of
            AnalysisReportChartSetup."Base X-Axis on"::Period:
                begin
                    BusChartBuf.FindFirstColumn(BusChartMapColumn);
                    for PeriodCounter := 1 to NoOfPeriods do begin
                        AnalysisReportChartSetup.SetLinkToMeasureLines(AnalysisReportChartLine);
                        AnalysisReportChartLine.SetFilter("Chart Type", '<>%1', AnalysisReportChartLine."Chart Type"::" ");
                        if AnalysisReportChartLine.FindSet() then
                            repeat
                                BusChartBuf.GetPeriodFromMapColumn(PeriodCounter - 1, FromDate, ToDate);
                                AnalysisLine.SetRange("Date Filter", FromDate, ToDate);
                                if (not AnalysisLine.Get(
                                      AnalysisReportChartSetup."Analysis Area", AnalysisReportChartSetup."Analysis Line Template Name",
                                      AnalysisReportChartLine."Analysis Line Line No.")) or
                                   (not AnalysisColumn.Get(
                                      AnalysisReportChartSetup."Analysis Area", AnalysisReportChartSetup."Analysis Column Template Name",
                                      AnalysisReportChartLine."Analysis Column Line No."))
                                then
                                    Error(Text003);
                                BusChartBuf.SetValue(
                                  AnalysisReportChartLine."Measure Name", PeriodCounter - 1,
                                  AnalysisReportMgt.CalcCell(AnalysisLine, AnalysisColumn, false));
                            until AnalysisReportChartLine.Next() = 0;
                    end;
                end;
            AnalysisReportChartSetup."Base X-Axis on"::Line:
                begin
                    AnalysisReportChartSetup.SetLinkToDimensionLines(AnalysisReportChartLine);
                    AnalysisReportChartLine.SetFilter("Chart Type", '<>%1', AnalysisReportChartLine."Chart Type"::" ");
                    AnalysisReportChartSetup.SetLinkToMeasureLines(AnalysisReportChartLine2);
                    AnalysisReportChartLine2.SetFilter("Chart Type", '<>%1', AnalysisReportChartLine2."Chart Type"::" ");
                    XCounter := 0;
                    AnalysisLine.SetRange("Date Filter", BusChartBuf."Period Filter Start Date", BusChartBuf."Period Filter End Date");
                    if AnalysisReportChartLine.FindSet() then
                        repeat
                            BusChartBuf.AddColumn(AnalysisReportChartLine."Measure Name");
                            if not AnalysisLine.Get(
                                 AnalysisReportChartSetup."Analysis Area", AnalysisReportChartSetup."Analysis Line Template Name",
                                 AnalysisReportChartLine."Analysis Line Line No.")
                            then
                                Error(Text003);
                            if AnalysisReportChartLine2.FindSet() then
                                repeat
                                    if not AnalysisColumn.Get(
                                         AnalysisReportChartSetup."Analysis Area", AnalysisReportChartSetup."Analysis Column Template Name",
                                         AnalysisReportChartLine2."Analysis Column Line No.")
                                    then
                                        Error(Text003);
                                    BusChartBuf.SetValue(
                                      AnalysisReportChartLine2."Measure Name", XCounter, AnalysisReportMgt.CalcCell(AnalysisLine, AnalysisColumn, false));
                                until AnalysisReportChartLine2.Next() = 0;
                            XCounter += 1;
                        until AnalysisReportChartLine.Next() = 0;
                end;
            AnalysisReportChartSetup."Base X-Axis on"::Column:
                begin
                    AnalysisReportChartSetup.SetLinkToDimensionLines(AnalysisReportChartLine);
                    AnalysisReportChartLine.SetFilter("Chart Type", '<>%1', AnalysisReportChartLine."Chart Type"::" ");
                    AnalysisReportChartSetup.SetLinkToMeasureLines(AnalysisReportChartLine2);
                    AnalysisReportChartLine2.SetFilter("Chart Type", '<>%1', AnalysisReportChartLine2."Chart Type"::" ");
                    AnalysisLine.SetRange("Date Filter", BusChartBuf."Period Filter Start Date", BusChartBuf."Period Filter End Date");
                    XCounter := 0;
                    if AnalysisReportChartLine.FindSet() then
                        repeat
                            BusChartBuf.AddColumn(AnalysisReportChartLine."Measure Name");
                            if not AnalysisColumn.Get(
                                 AnalysisReportChartSetup."Analysis Area", AnalysisReportChartSetup."Analysis Column Template Name",
                                 AnalysisReportChartLine."Analysis Column Line No.")
                            then
                                Error(Text003);
                            if AnalysisReportChartLine2.FindSet() then
                                repeat
                                    if not AnalysisLine.Get(
                                         AnalysisReportChartSetup."Analysis Area", AnalysisReportChartSetup."Analysis Line Template Name",
                                         AnalysisReportChartLine2."Analysis Line Line No.")
                                    then
                                        Error(Text003);
                                    BusChartBuf.SetValue(
                                      AnalysisReportChartLine2."Measure Name", XCounter, AnalysisReportMgt.CalcCell(AnalysisLine, AnalysisColumn, false));
                                until AnalysisReportChartLine2.Next() = 0;
                            XCounter += 1;
                        until AnalysisReportChartLine.Next() = 0;
                end;
        end;
    end;

    local procedure AddMeasures(var BusChartBuf: Record "Business Chart Buffer"; AnalysisReportChartSetup: Record "Analysis Report Chart Setup")
    var
        AnalysisReportChartLine: Record "Analysis Report Chart Line";
        BusChartType: Enum "Business Chart Type";
    begin
        AnalysisReportChartSetup.SetLinkToMeasureLines(AnalysisReportChartLine);
        AnalysisReportChartLine.SetFilter(AnalysisReportChartLine."Chart Type", '<>%1', AnalysisReportChartLine."Chart Type"::" ");
        if AnalysisReportChartLine.FindSet() then
            repeat
                case AnalysisReportChartLine."Chart Type" of
                    AnalysisReportChartLine."Chart Type"::Line:
                        BusChartType := BusChartBuf."Chart Type"::Line;
                    AnalysisReportChartLine."Chart Type"::StepLine:
                        BusChartType := BusChartBuf."Chart Type"::StepLine;
                    AnalysisReportChartLine."Chart Type"::Column:
                        BusChartType := BusChartBuf."Chart Type"::Column;
                    AnalysisReportChartLine."Chart Type"::StackedColumn:
                        BusChartType := BusChartBuf."Chart Type"::StackedColumn;
                end;
                BusChartBuf.AddDecimalMeasure(AnalysisReportChartLine."Measure Name", AnalysisReportChartLine."Measure Value", BusChartType);
            until AnalysisReportChartLine.Next() = 0;
    end;

    local procedure CalcAndInsertPeriodAxis(var BusChartBuf: Record "Business Chart Buffer"; AnalysisReportChartSetup: Record "Analysis Report Chart Setup"; Period: Option ,Next,Previous; MaxPeriodNo: Integer; StartDate: Date; EndDate: Date)
    var
        AccSchedChartManagement: Codeunit "Acc. Sched. Chart Management";
        PeriodDate: Date;
    begin
        if (StartDate = 0D) and (AnalysisReportChartSetup."Start Date" <> 0D) then
            PeriodDate := CalcDate(StrSubstNo('<-1%1>', BusChartBuf.GetPeriodLength()), AnalysisReportChartSetup."Start Date")
        else begin
            BusChartBuf.RecalculatePeriodFilter(StartDate, EndDate, Period);
            PeriodDate := CalcDate(StrSubstNo('<-%1%2>', MaxPeriodNo - (MaxPeriodNo div 2), BusChartBuf.GetPeriodLength()), EndDate);
        end;

        BusChartBuf.AddPeriods(
          AccSchedChartManagement.GetCorrectedDate(BusChartBuf, PeriodDate, 1),
          AccSchedChartManagement.GetCorrectedDate(BusChartBuf, PeriodDate, MaxPeriodNo));
    end;

    local procedure GetAnalysisLineAndColumnForDrillDown(var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column"; var BusChartBuf: Record "Business Chart Buffer"; AnalysisReportChartSetup: Record "Analysis Report Chart Setup")
    var
        XName: Variant;
        FromDate: Date;
        ToDate: Date;
        MeasureValueString: Text;
        AnalysisLineLineNo: Integer;
        AnalysisColumnLineNo: Integer;
    begin
        case AnalysisReportChartSetup."Base X-Axis on" of
            AnalysisReportChartSetup."Base X-Axis on"::Period:
                begin
                    BusChartBuf."Period Length" := AnalysisReportChartSetup."Period Length";
                    ToDate := BusChartBuf.GetXValueAsDate(BusChartBuf."Drill-Down X Index");
                    FromDate := BusChartBuf.CalcFromDate(ToDate);
                    MeasureValueString := BusChartBuf.GetMeasureValueString(BusChartBuf."Drill-Down Measure Index");
                    Evaluate(AnalysisLineLineNo, CopyStr(MeasureValueString, 1, StrPos(MeasureValueString, ' ') - 1));
                    AnalysisLine.Get(
                      AnalysisReportChartSetup."Analysis Area", AnalysisReportChartSetup."Analysis Line Template Name", AnalysisLineLineNo);
                    Evaluate(AnalysisColumnLineNo, CopyStr(MeasureValueString, StrPos(MeasureValueString, ' ') + 1));
                    AnalysisColumn.Get(
                      AnalysisReportChartSetup."Analysis Area", AnalysisReportChartSetup."Analysis Column Template Name", AnalysisColumnLineNo);
                end;
            AnalysisReportChartSetup."Base X-Axis on"::Line:
                begin
                    FromDate := BusChartBuf."Period Filter Start Date";
                    ToDate := BusChartBuf."Period Filter End Date";
                    AnalysisReportChartSetup.FilterAnalysisLine(AnalysisLine);
                    BusChartBuf.GetXValue(BusChartBuf."Drill-Down X Index", XName);
                    AnalysisLine.SetRange(Description, Format(XName));
                    AnalysisLine.FindFirst();
                    MeasureValueString := BusChartBuf.GetMeasureValueString(BusChartBuf."Drill-Down Measure Index");
                    Evaluate(AnalysisColumnLineNo, MeasureValueString);
                    AnalysisColumn.Get(
                      AnalysisReportChartSetup."Analysis Area", AnalysisReportChartSetup."Analysis Column Template Name", AnalysisColumnLineNo);
                end;
            AnalysisReportChartSetup."Base X-Axis on"::Column:
                begin
                    FromDate := BusChartBuf."Period Filter Start Date";
                    ToDate := BusChartBuf."Period Filter End Date";
                    AnalysisReportChartSetup.FilterAnalysisColumn(AnalysisColumn);
                    BusChartBuf.GetXValue(BusChartBuf."Drill-Down X Index", XName);
                    AnalysisColumn.SetRange("Column Header", Format(XName));
                    AnalysisColumn.FindFirst();
                    MeasureValueString := BusChartBuf.GetMeasureValueString(BusChartBuf."Drill-Down Measure Index");
                    Evaluate(AnalysisLineLineNo, MeasureValueString);
                    AnalysisLine.Get(
                      AnalysisReportChartSetup."Analysis Area", AnalysisReportChartSetup."Analysis Line Template Name", AnalysisLineLineNo);
                end;
        end;

        AnalysisLine.SetRange("Date Filter", FromDate, ToDate);
    end;

    procedure CheckDuplicateAnalysisLineDescription(AnalysisArea: Option; AnalysisLineTemplate: Code[10])
    var
        AnalysisLineDescCountQuery: Query "Analysis Line Desc. Count";
    begin
        AnalysisLineDescCountQuery.SetRange(Analysis_Area, AnalysisArea);
        AnalysisLineDescCountQuery.SetRange(AnalysisLineDescCountQuery.Analysis_Line_Template_Name, AnalysisLineTemplate);
        AnalysisLineDescCountQuery.Open();
        if AnalysisLineDescCountQuery.Read() then
            Error(DuplicateDescERR, AnalysisLineTemplate);
    end;

    procedure CheckDuplicateAnalysisColumnHeader(AnalysisArea: Option; AnalysisColumnTemplate: Code[10])
    var
        AnalysisColHeaderCountQuery: Query "Analysis Column Header Count";
    begin
        AnalysisColHeaderCountQuery.SetRange(Analysis_Area, AnalysisArea);
        AnalysisColHeaderCountQuery.SetRange(Analysis_Column_Template, AnalysisColumnTemplate);
        AnalysisColHeaderCountQuery.Open();
        if AnalysisColHeaderCountQuery.Read() then
            Error(DuplicateColHdrERR, AnalysisColumnTemplate);
    end;

    procedure SelectAll(AnalysisReportChartLine: Record "Analysis Report Chart Line"; IsMeasure: Boolean)
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        AnalysisReportChartSetup.Get(
          AnalysisReportChartLine."User ID", AnalysisReportChartLine."Analysis Area", AnalysisReportChartLine.Name);
        if IsMeasure then
            AnalysisReportChartSetup.SetMeasureChartTypesToDefault(AnalysisReportChartLine)
        else
            AnalysisReportChartSetup.SetDimensionChartTypesToDefault(AnalysisReportChartLine);
    end;

    procedure DeselectAll(AnalysisReportChartLine: Record "Analysis Report Chart Line"; IsMeasure: Boolean)
    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
    begin
        AnalysisReportChartSetup.Get(
          AnalysisReportChartLine."User ID", AnalysisReportChartLine."Analysis Area", AnalysisReportChartLine.Name);
        if IsMeasure then
            AnalysisReportChartSetup.SetLinkToMeasureLines(AnalysisReportChartLine)
        else
            AnalysisReportChartSetup.SetLinkToDimensionLines(AnalysisReportChartLine);
        AnalysisReportChartLine.ModifyAll("Chart Type", AnalysisReportChartLine."Chart Type"::" ");
    end;

    local procedure GetCurrentSelectionText(AnalysisReportChartSetup: Record "Analysis Report Chart Setup"; FromDate: Date; ToDate: Date): Text[100]
    begin
        case AnalysisReportChartSetup."Base X-Axis on" of
            AnalysisReportChartSetup."Base X-Axis on"::Period:
                exit(StrSubstNo(Text001, AnalysisReportChartSetup.Name, AnalysisReportChartSetup."Period Length", Time));
            AnalysisReportChartSetup."Base X-Axis on"::Line,
              AnalysisReportChartSetup."Base X-Axis on"::Column:
                exit(StrSubstNo(Text001, AnalysisReportChartSetup.Name, StrSubstNo(Text002, FromDate, ToDate), Time));
        end;
    end;

    procedure UpdateChart(Period: Option ,Next,Previous; var AnalysisReportChartSetup: Record "Analysis Report Chart Setup"; AnalysisArea: Option; var BusChartBuffer: Record "Business Chart Buffer"; var StatusText: Text[250])
    begin
        GetSetup(AnalysisReportChartSetup, AnalysisArea, AnalysisReportChartSetup.Name);
        UpdateData(BusChartBuffer, AnalysisReportChartSetup, Period);
        StatusText :=
          GetCurrentSelectionText(
            AnalysisReportChartSetup, BusChartBuffer."Period Filter Start Date", BusChartBuffer."Period Filter End Date");
    end;

    procedure SelectChart(var AnalysisReportChartSetup: Record "Analysis Report Chart Setup"; var BusChartBuffer: Record "Business Chart Buffer") Selected: Boolean
    var
        AnalysisReportChartSetup2: Record "Analysis Report Chart Setup";
    begin
        AnalysisReportChartSetup2.SetRange("User ID", AnalysisReportChartSetup."User ID");
        AnalysisReportChartSetup2.SetRange("Analysis Area", AnalysisReportChartSetup."Analysis Area");
        AnalysisReportChartSetup2 := AnalysisReportChartSetup;
        if PAGE.RunModal(0, AnalysisReportChartSetup2) = ACTION::LookupOK then begin
            AnalysisReportChartSetup := AnalysisReportChartSetup2;
            BusChartBuffer.InitializePeriodFilter(0D, 0D);
            Selected := true;
        end;
    end;
}

