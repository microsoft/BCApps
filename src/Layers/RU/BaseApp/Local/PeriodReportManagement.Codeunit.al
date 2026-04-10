#pragma warning disable AA0247
codeunit 12406 PeriodReportManagement
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text000: Label ' <Year4>', Locked = true;
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text001: Label '<Year4>', Locked = true;
#pragma warning restore AA0074
        PeriodsNames: Text[250];
#pragma warning disable AA0074
        Text002: Label 'one month,two  month,three  month,four  month,five  month,six  month,';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text003: Label 'seven  month,eight  month,nine  month,ten  month,eleven  month ';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label 'first quarter,first half year,nine month, ';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label 'january,february,march,april,may,june,july,august,september,october,november,december';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text006: Label 'first quarter,second quarter,third quarter,forth quarter';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure CreatePeriodsNames(TotalAdding: Boolean; CalendarPeriod: Record Date)
    begin
        if TotalAdding then
            case CalendarPeriod."Period Type" of
                CalendarPeriod."Period Type"::Month:
                    PeriodsNames := Text002 + Text003;
                CalendarPeriod."Period Type"::Quarter:
                    PeriodsNames := Text004;
                else
                    PeriodsNames := '';
            end
        else
            case CalendarPeriod."Period Type" of
                CalendarPeriod."Period Type"::Month:
                    PeriodsNames := Text005;
                CalendarPeriod."Period Type"::Quarter:
                    PeriodsNames := Text006;
                else
                    PeriodsNames := '';
            end;
    end;

    [Scope('OnPrem')]
    procedure ParseCaptionPeriodName(var TextPeriodYear: Text[30]; var CalendarPeriod: Record Date; TotalAdding: Boolean): Boolean
    var
        LengthPeriodName: Integer;
        PeriodSeqNo: Integer;
        YearNo: Integer;
        NumbPeriods: Integer;
    begin
        CreatePeriodsNames(TotalAdding, CalendarPeriod);
        TextPeriodYear := DelChr(TextPeriodYear, '<>', ' ');
        NumbPeriods := StrLen(PeriodsNames) - StrLen(DelChr(PeriodsNames, '=', ',')) + 1;
        if PeriodsNames = '' then
            PeriodSeqNo := NumbPeriods
        else
            PeriodSeqNo := 0;
        LengthPeriodName := 0;
        while (PeriodSeqNo < NumbPeriods) and (LengthPeriodName = 0) do begin
            PeriodSeqNo := PeriodSeqNo + 1;
            if StrPos(TextPeriodYear, SelectStr(PeriodSeqNo, PeriodsNames)) = 1 then
                LengthPeriodName := StrLen(SelectStr(PeriodSeqNo, PeriodsNames)) + 1;
        end;
        if LengthPeriodName = 0
        then begin
            LengthPeriodName := 1;
            PeriodSeqNo := NumbPeriods;
        end;
        if LengthPeriodName > StrLen(TextPeriodYear)
        then
            if CalendarPeriod."Period End" = 0D then
                YearNo := Date2DMY(WorkDate(), 3)
            else
                YearNo := Date2DMY(CalendarPeriod."Period End", 3)
        else
            if not Evaluate(YearNo, CopyStr(TextPeriodYear, LengthPeriodName, 5)) then
                exit(false);
        if YearNo < 50
        then
            YearNo := 2000 + YearNo
        else
            if YearNo < 100 then
                YearNo := 1900 + YearNo;
        case CalendarPeriod."Period Type" of
            CalendarPeriod."Period Type"::Month:
                begin
                    CalendarPeriod."Period Start" := DMY2Date(1, PeriodSeqNo, YearNo);
                    CalendarPeriod."Period Start" := CalcDate('<CM+1D-1M>', CalendarPeriod."Period Start");
                end;
            CalendarPeriod."Period Type"::Quarter:
                begin
                    CalendarPeriod."Period Start" := DMY2Date(1, PeriodSeqNo * 3, YearNo);
                    CalendarPeriod."Period Start" := CalcDate('<CQ+1D-1Q>', CalendarPeriod."Period Start");
                end;
            else begin
                CalendarPeriod."Period Start" := DMY2Date(1, 1, YearNo);
                CalendarPeriod."Period Type" := CalendarPeriod."Period Type"::Year;
                PeriodsNames := '';
            end
        end;
        CalendarPeriod.Get(CalendarPeriod."Period Type", CalendarPeriod."Period Start");
        CalendarPeriod."Period Start" := NormalDate(CalendarPeriod."Period Start");
        CalendarPeriod."Period End" := NormalDate(CalendarPeriod."Period End");
        if not (PeriodsNames = '')
        then begin
            TextPeriodYear := SelectStr(PeriodSeqNo, PeriodsNames) +
              Format(CalendarPeriod."Period End", 0, Text000);
            if not ((PeriodSeqNo = NumbPeriods) and TotalAdding) then
                TextPeriodYear := TextPeriodYear + 'á';
        end else
            TextPeriodYear := Format(CalendarPeriod."Period End", 0, Text001);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure SetCaptionPeriodYear(var FiscalPeriod: Text[30]; var CalendarPeriod: Record Date; TotalAdding: Boolean): Boolean
    var
        PeriodSeqNo: Integer;
    begin
        if not (FiscalPeriod = '')
        then
            case CalendarPeriod."Period Type" of
                CalendarPeriod."Period Type"::Month,
              CalendarPeriod."Period Type"::Quarter:
                    if not ParseCaptionPeriodName(FiscalPeriod, CalendarPeriod, TotalAdding) then
                        FiscalPeriod := '';
                else
                    FiscalPeriod := '';
            end;
        if FiscalPeriod = ''
        then begin
            CreatePeriodsNames(TotalAdding, CalendarPeriod);
            PeriodSeqNo := CalendarPeriod."Period No.";
            if PeriodSeqNo > (StrLen(PeriodsNames) - StrLen(DelChr(PeriodsNames, '=', ',')) + 1)
            then
                FiscalPeriod := Format(CalendarPeriod."Period End", 0, Text001)
            else begin
                FiscalPeriod := SelectStr(PeriodSeqNo, PeriodsNames) +
                  Format(CalendarPeriod."Period End", 0, Text000);
                if not (SelectStr(PeriodSeqNo, PeriodsNames) = ' ')
                then
                    FiscalPeriod := FiscalPeriod + 'á';
            end;
        end;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure SelectPeriod(var Text: Text[250]; var CalendarPeriod: Record Date; TotalAdding: Boolean): Boolean
    var
        SelectDate: Page "Select Reporting Period";
    begin
        Clear(SelectDate);
        SelectDate.SetRecord(CalendarPeriod);
        if SelectDate.RunModal() = ACTION::LookupOK then
            SelectDate.GetRecord(CalendarPeriod);
        Text := '';
        SetCaptionPeriodYear(Text, CalendarPeriod, TotalAdding);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure InitPeriod(var CalendarPeriod: Record Date; Perodical: Option Month,Quarter,Year)
    begin
        case Perodical of
            Perodical::Month:
                begin
                    CalendarPeriod."Period Type" := CalendarPeriod."Period Type"::Month;
                    CalendarPeriod."Period Start" := CalcDate('<CM+1D-1M>', WorkDate());
                    if Date2DMY(WorkDate(), 2) = 1 then
                        CalendarPeriod."Period Start" := CalcDate('<-1M>', CalendarPeriod."Period Start");
                end;
            Perodical::Year:
                begin
                    CalendarPeriod."Period Type" := CalendarPeriod."Period Type"::Year;
                    CalendarPeriod."Period Start" := CalcDate('<CY+1D-1Y>', WorkDate());
                    if Date2DMY(WorkDate(), 2) = 1 then
                        CalendarPeriod."Period Start" := CalcDate('<-1Y>', CalendarPeriod."Period Start");
                end;
            else begin
                CalendarPeriod."Period Type" := CalendarPeriod."Period Type"::Quarter;
                CalendarPeriod."Period Start" := CalcDate('<CQ+1D-1Q>', WorkDate());
                if Date2DMY(WorkDate(), 2) = 1 then
                    CalendarPeriod."Period Start" := CalcDate('<-1Q>', CalendarPeriod."Period Start");
            end;
        end;
        CalendarPeriod.Get(CalendarPeriod."Period Type", CalendarPeriod."Period Start");
        CalendarPeriod."Period Start" := NormalDate(CalendarPeriod."Period Start");
        CalendarPeriod."Period End" := NormalDate(CalendarPeriod."Period End");
    end;

    [Scope('OnPrem')]
    procedure PeriodSetup(var CalendarPeriod: Record Date; TotalsAdding: Boolean)
    begin
        CalendarPeriod."Period End" := NormalDate(CalendarPeriod."Period End");
        if TotalsAdding then
            CalendarPeriod."Period Start" := DMY2Date(1, 1, Date2DMY(CalendarPeriod."Period End", 3))
        else
            CalendarPeriod."Period Start" := NormalDate(CalendarPeriod."Period Start");
    end;
}

