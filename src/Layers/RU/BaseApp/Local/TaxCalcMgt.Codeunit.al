#pragma warning disable AA0247
codeunit 17303 "Tax Calc. Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        TaxCalcSection: Record "Tax Calc. Section";
#pragma warning disable AA0074
        Text1000: Label 'STANDARD';
        Text1006: Label '\\Continue?';
        Text1007: Label 'Existing data will be deleted.';
        Text1008: Label 'Illegal begin date period.';
#pragma warning disable AA0470
        Text1009: Label 'There are no data in %2 for period ending at %1. Do you want to proceed anyway?';
#pragma warning restore AA0470
        Text1011: Label 'Illegal end date period.';
        Text1012: Label 'End date must be set.';
        Text1013: Label 'Begin date must be set.';
        Text1014: Label 'Section code must be defined.';
        Text000: Label '1,5,,Dimension 1 Value Code';
        Text001: Label '1,5,,Dimension 2 Value Code';
        Text002: Label '1,5,,Dimension 3 Value Code';
        Text003: Label '1,5,,Dimension 4 Value Code';
        Text005: Label 'january,february,march,april,may,june,july,august,september,october,november,december';
        Text006: Label 'first quarter,second quarter,third quarter,fourth quarter';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure FindDate(SearchString: Text[10]; var Calendar: Record Date; PeriodType: Option ,,Month,Quarter,Year; AmountType: Option "Current Period","Tax Period") Found: Boolean
    begin
        Calendar.SetRange("Period Type", PeriodType);
        Calendar."Period Type" := PeriodType;
        if Calendar."Period End" = 0D then
            Calendar."Period End" := WorkDate();
        case PeriodType of
            PeriodType::Year:
                Calendar."Period Start" := CalcDate('<-CY>', NormalDate(Calendar."Period End"));
            PeriodType::Quarter:
                Calendar."Period Start" := CalcDate('<-CQ>', NormalDate(Calendar."Period End"));
            else
                Calendar."Period Start" := CalcDate('<-CM>', NormalDate(Calendar."Period End"));
        end;
        if SearchString in ['', '=><'] then
            SearchString := '=<>';
        Found := Calendar.Find(SearchString);
        if Found then begin
            Calendar."Period Start" := NormalDate(Calendar."Period Start");
            Calendar."Period End" := NormalDate(Calendar."Period End");
        end;
        if AmountType = AmountType::"Tax Period" then
            Calendar."Period Start" := CalcDate('<-CY>', Calendar."Period Start");
        exit(Found);
    end;

    [Scope('OnPrem')]
    procedure SetPeriodAmountType(var Calendar: Record Date; var DateFilterText: Text; var PeriodType: Option ,,Month,Quarter,Year; var AmountType: Option "Current Period","Tax Period")
    begin
        DateFilterText := Calendar.GetFilter("Period End");
        PeriodType := PeriodType::Month;
        AmountType := AmountType::"Tax Period";
        case true of
            (DateFilterText = ''):
                begin
                    DateFilterText := '*';
                    AmountType := AmountType::"Current Period";
                end;
            (CopyStr(DateFilterText, 1, 2) = '..'),
          (StrPos(DateFilterText, '..') = StrLen(DateFilterText) - 1):
                DateFilterText := '*';
            CalcDate('<CM>', Calendar.GetRangeMin("Period End")) = Calendar.GetRangeMax("Period End"):
                AmountType := AmountType::"Current Period";
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDimCaptionClass(TaxCalcSectionCode: Code[10]; DimensionNo: Integer): Text[250]
    begin
        if not TaxCalcSection.Get(TaxCalcSectionCode) then
            Clear(TaxCalcSection);
        case DimensionNo of
            1:
                begin
                    if TaxCalcSection."Dimension 1 Code" <> '' then
                        exit('1,5,' + TaxCalcSection."Dimension 1 Code");

                    exit(Text000);
                end;
            2:
                begin
                    if TaxCalcSection."Dimension 2 Code" <> '' then
                        exit('1,5,' + TaxCalcSection."Dimension 2 Code");

                    exit(Text001);
                end;
            3:
                begin
                    if TaxCalcSection."Dimension 3 Code" <> '' then
                        exit('1,5,' + TaxCalcSection."Dimension 3 Code");

                    exit(Text002);
                end;
            4:
                begin
                    if TaxCalcSection."Dimension 4 Code" <> '' then
                        exit('1,5,' + TaxCalcSection."Dimension 4 Code");

                    exit(Text003);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SectionSelection(PageTemplate: Option " "; var TaxCalcSectionCode: Code[10]) SectionSelected: Boolean
    var
        TaxCalcSection: Record "Tax Calc. Section";
    begin
        SectionSelected := true;

        TaxCalcSection.Reset();
        TaxCalcSection.SetRange(Type, PageTemplate);

        case TaxCalcSection.Count of
            0:
                begin
                    TaxCalcSection.Init();
                    TaxCalcSection.Type := PageTemplate;
                    TaxCalcSection.Code := Text1000;
                    TaxCalcSection.Validate(Type);
                    TaxCalcSection.Insert();
                    Commit();
                end;
            1:
                TaxCalcSection.FindFirst();
            else
                SectionSelected := PAGE.RunModal(0, TaxCalcSection) = ACTION::LookupOK;
        end;
        if SectionSelected then
            TaxCalcSectionCode := TaxCalcSection.Code;
    end;

    [Scope('OnPrem')]
    procedure OpenReg(CurrentSectionCode: Code[10]; var TaxCalcHeader: Record "Tax Calc. Header")
    begin
        TaxCalcHeader.FilterGroup := 2;
        TaxCalcHeader.SetRange("Section Code", CurrentSectionCode);
        TaxCalcHeader.FilterGroup := 0;
    end;

    [Scope('OnPrem')]
    procedure ValidateAbsenceGLEntriesDate(DateBegin: Date; DateEnd: Date; TaxCalcSectionCode: Code[10])
    var
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcAccumulat: Record "Tax Calc. Accumulation";
        DeleteConfirmed: Boolean;
    begin
        ValidateDateBeginDateEnd(DateBegin, DateEnd, TaxCalcSectionCode);

        TaxCalcAccumulat.Reset();
        TaxCalcAccumulat.SetCurrentKey(
          "Section Code", "Register No.", "Template Line No.", "Starting Date", "Ending Date");
        TaxCalcAccumulat.SetRange("Section Code", TaxCalcSectionCode);
        TaxCalcAccumulat.SetFilter("Starting Date", '%1..', DateBegin);

        TaxCalcHeader.SetRange("Section Code", TaxCalcSectionCode);
        TaxCalcHeader.SetRange("Table ID", DATABASE::"Tax Calc. G/L Entry");
        if TaxCalcHeader.Find('-') then
            repeat
                TaxCalcAccumulat.SetRange("Register No.", TaxCalcHeader."No.");
                if not TaxCalcAccumulat.IsEmpty() then
                    if not DeleteConfirmed then begin
                        if not Confirm(Text1007 + Text1006) then
                            Error('');

                        DeleteConfirmed := true;
                    end;
                TaxCalcAccumulat.DeleteAll();
            until TaxCalcHeader.Next() = 0;

        if DateBegin = TaxCalcSection."Starting Date" then
            TaxCalcSection."No G/L Entries Date" := 0D
        else
            if FindPrevPeriodGLRegisterData(DateBegin, TaxCalcSectionCode) then begin
                if DateEnd <= TaxCalcSection."No G/L Entries Date" then
                    TaxCalcSection."No G/L Entries Date" := 0D;
            end else begin
                if not Confirm(Text1009) then
                    Error('');
                if (TaxCalcSection."No G/L Entries Date" = 0D) or
                   ((DateBegin - 1) < TaxCalcSection."No G/L Entries Date")
                then
                    TaxCalcSection."No G/L Entries Date" := DateBegin - 1;
            end;

        TaxCalcSection.Validate("Last G/L Entries Date", DateEnd);
        TaxCalcSection.Modify();
    end;

    [Scope('OnPrem')]
    procedure FindPrevPeriodGLRegisterData(FromDate: Date; SectionCode: Code[10]): Boolean
    var
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcAccum: Record "Tax Calc. Accumulation";
    begin
        TaxCalcAccum.Reset();
        TaxCalcAccum.SetCurrentKey(
          "Section Code", "Register No.", "Template Line No.", "Starting Date", "Ending Date");
        TaxCalcAccum.SetRange("Section Code", SectionCode);
        TaxCalcAccum.SetRange("Ending Date", FromDate - 1);

        TaxCalcHeader.SetRange("Section Code", SectionCode);
        TaxCalcHeader.SetRange("Table ID", DATABASE::"Tax Calc. G/L Entry");
        if TaxCalcHeader.FindSet() then
            repeat
                TaxCalcAccum.SetRange("Register No.", TaxCalcHeader."No.");
                if TaxCalcAccum.IsEmpty() then
                    exit(false);
            until TaxCalcHeader.Next() = 0;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ValidateAbsenceItemEntriesDate(DateBegin: Date; DateEnd: Date; TaxCalcSectionCode: Code[10])
    var
        TaxCalcLine: Record "Tax Calc. Item Entry";
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcAccumulat: Record "Tax Calc. Accumulation";
    begin
        ValidateDateBeginDateEnd(DateBegin, DateEnd, TaxCalcSectionCode);

        TaxCalcLine.Reset();
        TaxCalcLine.SetCurrentKey("Section Code", "Starting Date");
        TaxCalcLine.SetRange("Section Code", TaxCalcSectionCode);
        TaxCalcLine.SetFilter("Starting Date", '%1..', DateBegin);
        if TaxCalcLine.FindFirst() then begin
            if not Confirm(Text1007 + Text1006, false) then
                Error('');
            TaxCalcLine.DeleteAll();
        end;

        TaxCalcHeader.SetRange("Section Code", TaxCalcSectionCode);
        TaxCalcHeader.SetRange("Table ID", DATABASE::"Tax Calc. Item Entry");
        if TaxCalcHeader.Find('-') then begin
            TaxCalcAccumulat.Reset();
            TaxCalcAccumulat.SetCurrentKey(
              "Section Code", "Register No.", "Template Line No.", "Starting Date", "Ending Date");
            TaxCalcAccumulat.SetRange("Section Code", TaxCalcSectionCode);
            TaxCalcAccumulat.SetFilter("Starting Date", '%1..', DateBegin);
            repeat
                TaxCalcAccumulat.SetRange("Register No.", TaxCalcHeader."No.");
                TaxCalcAccumulat.DeleteAll();
            until TaxCalcHeader.Next() = 0;
        end;

        TaxCalcLine.Reset();
        TaxCalcLine.SetCurrentKey("Section Code", "Ending Date");
        TaxCalcLine.SetRange("Section Code", TaxCalcSectionCode);
        TaxCalcLine.SetFilter("Ending Date", '%1..', DateBegin);
        if TaxCalcLine.FindFirst() then
            Error(Text1008);

        if DateBegin = TaxCalcSection."Starting Date" then
            TaxCalcSection."No Item Entries Date" := 0D
        else begin
            TaxCalcLine.Reset();
            TaxCalcLine.SetCurrentKey("Section Code", "Ending Date");
            TaxCalcLine.SetRange("Section Code", TaxCalcSectionCode);
            TaxCalcLine.SetFilter("Ending Date", '%1', DateBegin - 1);
            if TaxCalcLine.FindFirst() then begin
                if DateEnd <= TaxCalcSection."No Item Entries Date" then
                    TaxCalcSection."No Item Entries Date" := 0D;
            end else begin
                if not Confirm(Text1009, false, DateBegin - 1, TaxCalcLine.TableCaption()) then
                    Error('');
                if (TaxCalcSection."No Item Entries Date" = 0D) or
                   ((DateBegin - 1) < TaxCalcSection."No Item Entries Date")
                then
                    TaxCalcSection."No Item Entries Date" := DateBegin - 1;
            end;
        end;

        TaxCalcSection.Validate("Last Item Entries Date", DateEnd);
        TaxCalcSection.Modify();
    end;

    [Scope('OnPrem')]
    procedure ValidateAbsenceFAEntriesDate(DateBegin: Date; DateEnd: Date; TaxCalcSectionCode: Code[10])
    var
        TaxCalcLine: Record "Tax Calc. FA Entry";
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcAccumulat: Record "Tax Calc. Accumulation";
    begin
        ValidateDateBeginDateEnd(DateBegin, DateEnd, TaxCalcSectionCode);

        TaxCalcLine.Reset();
        TaxCalcLine.SetCurrentKey("Section Code", "Starting Date");
        TaxCalcLine.SetRange("Section Code", TaxCalcSectionCode);
        TaxCalcLine.SetFilter("Starting Date", '%1..', DateBegin);
        if TaxCalcLine.FindFirst() then begin
            if not Confirm(Text1007 + Text1006, false) then
                Error('');
            TaxCalcLine.DeleteAll();
        end;

        TaxCalcHeader.SetRange("Section Code", TaxCalcSectionCode);
        TaxCalcHeader.SetRange("Table ID", DATABASE::"Tax Calc. FA Entry");
        if TaxCalcHeader.Find('-') then begin
            TaxCalcAccumulat.Reset();
            TaxCalcAccumulat.SetCurrentKey(
              "Section Code", "Register No.", "Template Line No.", "Starting Date", "Ending Date");
            TaxCalcAccumulat.SetRange("Section Code", TaxCalcSectionCode);
            TaxCalcAccumulat.SetFilter("Starting Date", '%1..', DateBegin);
            repeat
                TaxCalcAccumulat.SetRange("Register No.", TaxCalcHeader."No.");
                TaxCalcAccumulat.DeleteAll();
            until TaxCalcHeader.Next() = 0;
        end;

        TaxCalcLine.Reset();
        TaxCalcLine.SetCurrentKey("Section Code", "Ending Date");
        TaxCalcLine.SetRange("Section Code", TaxCalcSectionCode);
        TaxCalcLine.SetFilter("Ending Date", '%1..', DateBegin);
        if TaxCalcLine.FindFirst() then
            Error(Text1008);

        if DateBegin = TaxCalcSection."Starting Date" then
            TaxCalcSection."No FA Entries Date" := 0D
        else begin
            TaxCalcLine.Reset();
            TaxCalcLine.SetCurrentKey("Section Code", "Ending Date");
            TaxCalcLine.SetRange("Section Code", TaxCalcSectionCode);
            TaxCalcLine.SetFilter("Ending Date", '%1', DateBegin - 1);
            if TaxCalcLine.FindFirst() then begin
                if DateEnd <= TaxCalcSection."No FA Entries Date" then
                    TaxCalcSection."No FA Entries Date" := 0D;
            end else begin
                if not Confirm(Text1009, false, DateBegin - 1, TaxCalcLine.TableCaption()) then
                    Error('');
                if (TaxCalcSection."No FA Entries Date" = 0D) or
                   ((DateBegin - 1) < TaxCalcSection."No FA Entries Date")
                then
                    TaxCalcSection."No FA Entries Date" := DateBegin - 1;
            end;
        end;

        TaxCalcSection.Validate("Last FA Entries Date", DateEnd);
        TaxCalcSection.Modify();
    end;

    [Scope('OnPrem')]
    procedure ValidateDateBeginDateEnd(DateBegin: Date; DateEnd: Date; TaxCalcSectionCode: Code[10])
    begin
        if TaxCalcSectionCode = '' then
            Error(Text1014);
        if DateBegin = 0D then
            Error(Text1013);
        if DateEnd = 0D then
            Error(Text1012);

        TaxCalcSection.Get(TaxCalcSectionCode);

        if DateBegin < TaxCalcSection."Starting Date" then
            Error(Text1008);

        if (TaxCalcSection."Ending Date" <> 0D) and (TaxCalcSection."Ending Date" < DateEnd) then
            Error(Text1011);
    end;

    [Scope('OnPrem')]
    procedure GetNextAvailableBeginDate(TaxCalcSectionCode: Code[10]; TableID: Integer; Minimum: Boolean) DateBegin: Date
    var
        DateMax: Date;
    begin
        TaxCalcSection.Get(TaxCalcSectionCode);
        DateMax := TaxCalcSection.LastDateEntries();
        DateBegin := TaxCalcSection."Starting Date";
        case TableID of
            DATABASE::"Tax Calc. Accumulation":
                if DateMax <> 0D then
                    if (TaxCalcSection."Ending Date" = 0D) or
                       (DateMax < TaxCalcSection."Ending Date")
                    then
                        DateBegin := DateMax + 1;
            DATABASE::"Tax Calc. G/L Entry":
                if (TaxCalcSection."Last G/L Entries Date" = 0D) or
                   (Minimum and (TaxCalcSection."No G/L Entries Date" <> 0D))
                then
                    DateBegin := TaxCalcSection."Starting Date"
                else
                    if Minimum and (DateMax <> 0D) then
                        DateBegin := DateMax + 1
                    else
                        if (TaxCalcSection."Ending Date" = 0D) or
                           (TaxCalcSection."Last G/L Entries Date" < TaxCalcSection."Ending Date")
                        then
                            DateBegin := TaxCalcSection."Last G/L Entries Date" + 1;
            DATABASE::"Tax Calc. Item Entry":
                if (TaxCalcSection."Last Item Entries Date" = 0D) or
                   (Minimum and (TaxCalcSection."No Item Entries Date" <> 0D))
                then
                    DateBegin := TaxCalcSection."Starting Date"
                else
                    if Minimum and (DateMax <> 0D) then
                        DateBegin := DateMax + 1
                    else
                        if (TaxCalcSection."Ending Date" = 0D) or
                           (TaxCalcSection."Last Item Entries Date" < TaxCalcSection."Ending Date")
                        then
                            DateBegin := TaxCalcSection."Last Item Entries Date" + 1;
            DATABASE::"Tax Calc. FA Entry":
                if (TaxCalcSection."Last FA Entries Date" = 0D) or
                   (Minimum and (TaxCalcSection."No FA Entries Date" <> 0D))
                then
                    DateBegin := TaxCalcSection."Starting Date"
                else
                    if Minimum and (DateMax <> 0D) then
                        DateBegin := DateMax + 1
                    else
                        if (TaxCalcSection."Ending Date" = 0D) or
                           (TaxCalcSection."Last FA Entries Date" < TaxCalcSection."Ending Date")
                        then
                            DateBegin := TaxCalcSection."Last FA Entries Date" + 1;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreatePeriodsNames(CalendarPeriod: Record Date) PeriodsNames: Text[250]
    begin
        case CalendarPeriod."Period Type" of
            CalendarPeriod."Period Type"::Month:
                PeriodsNames := Text005;
            CalendarPeriod."Period Type"::Quarter:
                PeriodsNames := Text006;
        end;
    end;

    [Scope('OnPrem')]
    procedure ParseCaptionPeriodAndName(var TextPeriodYear: Text[30]; var CalendarPeriod: Record Date): Boolean
    var
        LengthPeriodName: Integer;
        PeriodSeqNo: Integer;
        YearNo: Integer;
        NumbPeriods: Integer;
        PeriodsNames: Text[250];
    begin
        PeriodsNames := CreatePeriodsNames(CalendarPeriod);
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
        if LengthPeriodName = 0 then begin
            LengthPeriodName := 1;
            PeriodSeqNo := NumbPeriods;
        end;
        if LengthPeriodName > StrLen(TextPeriodYear) then
            if CalendarPeriod."Period End" = 0D then
                YearNo := Date2DMY(WorkDate(), 3)
            else
                YearNo := Date2DMY(CalendarPeriod."Period End", 3)
        else
            if not Evaluate(YearNo, CopyStr(TextPeriodYear, LengthPeriodName, 5)) then
                exit(false);

        if YearNo < 50 then
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
        if PeriodsNames <> '' then
            TextPeriodYear := SelectStr(PeriodSeqNo, PeriodsNames) +
              Format(CalendarPeriod."Period End", 0, ' <Year4>')
        else
            TextPeriodYear := Format(CalendarPeriod."Period End", 0, '<Year4>');
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure SetCaptionPeriodAndYear(var FiscalPeriod: Text[30]; var CalendarPeriod: Record Date): Boolean
    var
        PeriodSeqNo: Integer;
        PeriodsNames: Text[250];
    begin
        if FiscalPeriod <> '' then
            case CalendarPeriod."Period Type" of
                CalendarPeriod."Period Type"::Month,
              CalendarPeriod."Period Type"::Quarter:
                    if not ParseCaptionPeriodAndName(FiscalPeriod, CalendarPeriod) then
                        FiscalPeriod := '';
                else
                    FiscalPeriod := '';
            end;
        if FiscalPeriod = '' then begin
            PeriodsNames := CreatePeriodsNames(CalendarPeriod);
            PeriodSeqNo := CalendarPeriod."Period No.";
            if PeriodSeqNo > (StrLen(PeriodsNames) - StrLen(DelChr(PeriodsNames, '=', ',')) + 1) then
                FiscalPeriod := Format(CalendarPeriod."Period End", 0, '<Year4>')
            else
                FiscalPeriod := SelectStr(PeriodSeqNo, PeriodsNames) +
                  Format(CalendarPeriod."Period End", 0, ' <Year4>');
        end;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure SelectPeriod(var Text: Text[250]; var CalendarPeriod: Record Date): Boolean
    var
        SelectDate: Page "Select Reporting Period";
    begin
        Clear(SelectDate);
        SelectDate.SetRecord(CalendarPeriod);
        if SelectDate.RunModal() = ACTION::LookupOK then
            SelectDate.GetRecord(CalendarPeriod);
        Text := '';
        SetCaptionPeriodAndYear(Text, CalendarPeriod);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure PeriodSetup(var CalendarPeriod: Record Date)
    begin
        CalendarPeriod."Period End" := NormalDate(CalendarPeriod."Period End");
        CalendarPeriod."Period Start" := NormalDate(CalendarPeriod."Period Start");
    end;

    [Scope('OnPrem')]
    procedure InitTaxPeriod(var CalendarPeriod: Record Date; Perodical: Option Month,Quarter,Year; BeginTaxPeriod: Date)
    begin
        case Perodical of
            Perodical::Month:
                begin
                    CalendarPeriod."Period Type" := CalendarPeriod."Period Type"::Month;
                    CalendarPeriod."Period Start" := CalcDate('<-CM>', BeginTaxPeriod);
                end;
            Perodical::Year:
                begin
                    CalendarPeriod."Period Type" := CalendarPeriod."Period Type"::Year;
                    CalendarPeriod."Period Start" := CalcDate('<-CY>', BeginTaxPeriod);
                end;
            else begin
                CalendarPeriod."Period Type" := CalendarPeriod."Period Type"::Quarter;
                CalendarPeriod."Period Start" := CalcDate('<-CQ>', BeginTaxPeriod);
            end;
        end;
        CalendarPeriod.Get(CalendarPeriod."Period Type", CalendarPeriod."Period Start");
        CalendarPeriod."Period Start" := NormalDate(CalendarPeriod."Period Start");
        CalendarPeriod."Period End" := NormalDate(CalendarPeriod."Period End");
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcForPeriod(TaxCalcSectionCode: Code[10]; UseGLEntry: Boolean; UseFAEntry: Boolean; UseItemEntry: Boolean; UseTemplate: Boolean; var CalendarPeriod: Record Date)
    var
        TaxCalcSection: Record "Tax Calc. Section";
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcLine: Record "Tax Calc. Line";
        TaxCalcAccumulat: Record "Tax Calc. Accumulation";
        TaxCalcTermName: Record "Tax Calc. Term";
        EntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        CreateTaxCalcEntries: Codeunit "Create Tax Calc. Entries";
        CreateTaxCalcItemEntries: Codeunit "Create Tax Calc. Item Entries";
        CreateTaxCalcFAEntries: Codeunit "Create Tax Calc. FA Entries";
        GeneralTermMgt: Codeunit "Tax Register Term Mgt.";
        TemplateRecordRef: RecordRef;
        LinkAccumulateRecordRef: RecordRef;
        DateBegin: Date;
        DateEnd: Date;
        CycleLevel: Integer;
    begin
        TaxCalcSection.Get(TaxCalcSectionCode);
        if not (TaxCalcSection.Status in [TaxCalcSection.Status::Open, TaxCalcSection.Status::Statement]) then
            TaxCalcSection.FieldError(Status);

        TaxCalcLine.GenerateProfile();
        TaxCalcTermName.GenerateProfile();
        Commit();

        GeneralTermMgt.CheckTaxRegTerm(true, TaxCalcSectionCode,
          DATABASE::"Tax Calc. Term", DATABASE::"Tax Calc. Term Formula");

        GeneralTermMgt.CheckTaxRegLink(true, TaxCalcSectionCode,
          DATABASE::"Tax Calc. Line");

        CalendarPeriod."Period Start" := NormalDate(CalendarPeriod."Period Start");
        CalendarPeriod."Period End" := NormalDate(CalendarPeriod."Period End");
        CreateTaxCalcEntries.BuildTaxCalcCorresp(
          CalcDate('<-CM>', CalendarPeriod."Period Start"), CalcDate('<CM>', CalendarPeriod."Period End"), TaxCalcSectionCode);

        CalendarPeriod.Reset();
        CalendarPeriod.SetRange("Period Type", CalendarPeriod."Period Type"::Month);
        CalendarPeriod.SetRange("Period Start", CalendarPeriod."Period Start", CalendarPeriod."Period End");
        if CalendarPeriod.FindSet() then
            repeat
                DateBegin := NormalDate(CalendarPeriod."Period Start");
                DateEnd := NormalDate(CalendarPeriod."Period End");

                if UseGLEntry then
                    CreateTaxCalcEntries.Code(DateBegin, DateEnd, TaxCalcSectionCode);

                if UseItemEntry then
                    CreateTaxCalcItemEntries.Code(DateBegin, DateEnd, TaxCalcSectionCode);

                if UseFAEntry then
                    CreateTaxCalcFAEntries.Code(DateBegin, DateEnd, TaxCalcSectionCode);

                if UseTemplate then begin
                    TaxCalcHeader.Reset();
                    TaxCalcHeader.SetRange("Section Code", TaxCalcSectionCode);
                    TaxCalcHeader.SetRange("Storing Method", TaxCalcHeader."Storing Method"::Calculation);
                    LinkAccumulateRecordRef.Close();
                    LinkAccumulateRecordRef.Open(DATABASE::"Tax Calc. Accumulation");
                    TaxCalcAccumulat.SetCurrentKey("Section Code", "Register No.", "Template Line No.");
                    TaxCalcAccumulat.SetRange("Section Code", TaxCalcSectionCode);
                    TaxCalcAccumulat.SetRange("Ending Date", DateEnd);
                    LinkAccumulateRecordRef.SetView(TaxCalcAccumulat.GetView(false));
                    if TaxCalcHeader.FindSet() then
                        repeat
                            TaxCalcAccumulat.SetRange("Register No.", TaxCalcHeader."No.");
                            TaxCalcAccumulat.DeleteAll();
                        until TaxCalcHeader.Next(1) = 0;
                    TaxCalcHeader.SetRange("Storing Method");
                    TaxCalcLine.SetRange("Section Code", TaxCalcSectionCode);
                    CycleLevel := 1;
                    while CycleLevel <> 0 do begin
                        TaxCalcHeader.SetRange(Level, CycleLevel);
                        if not TaxCalcHeader.FindSet() then
                            CycleLevel := 0
                        else begin
                            repeat
                                if TaxCalcHeader."Storing Method" = TaxCalcHeader."Storing Method"::Calculation then begin
                                    TaxCalcLine.SetRange(Code, TaxCalcHeader."No.");
                                    if TaxCalcLine.FindFirst() then begin
                                        TaxCalcLine.SetRange("Date Filter", DateBegin, DateEnd);
                                        TemplateRecordRef.GetTable(TaxCalcLine);
                                        TemplateRecordRef.SetView(TaxCalcLine.GetView(false));
                                        GeneralTermMgt.AccumulateTaxRegTemplate(
                                          TemplateRecordRef, EntryNoAmountBuffer, LinkAccumulateRecordRef);
                                        CreateAccumulate(TaxCalcLine, EntryNoAmountBuffer);
                                        EntryNoAmountBuffer.DeleteAll();
                                    end;
                                end;
                            until TaxCalcHeader.Next(1) = 0;
                            CycleLevel += 1;
                        end;
                    end;
                    CreateTaxCalcEntries.CalcFieldsTaxCalcEntry(DateBegin, DateEnd, TaxCalcSectionCode);
                end;
            until CalendarPeriod.Next(1) = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateAccumulate(var TaxCalcLine: Record "Tax Calc. Line"; var EntryNoAmountBuffer: Record "Entry No. Amount Buffer")
    var
        TaxCalcLine0: Record "Tax Calc. Line";
        TaxCalcAccumulation: Record "Tax Calc. Accumulation";
        TaxCalcAccumulation2: Record "Tax Calc. Accumulation";
        GeneralTermMgt: Codeunit "Tax Register Term Mgt.";
    begin
        if EntryNoAmountBuffer.FindSet() then begin
            TaxCalcAccumulation.Init();
            TaxCalcAccumulation."Starting Date" := TaxCalcLine.GetRangeMin("Date Filter");
            TaxCalcAccumulation."Ending Date" := TaxCalcLine.GetRangeMax("Date Filter");
            TaxCalcAccumulation."Section Code" := TaxCalcLine."Section Code";
            TaxCalcAccumulation."Register No." := TaxCalcLine.Code;
            repeat
                TaxCalcLine0.Get(
                  TaxCalcAccumulation."Section Code", TaxCalcAccumulation."Register No.", EntryNoAmountBuffer."Entry No.");
                TaxCalcAccumulation."Template Line Code" := TaxCalcLine0."Line Code";
                TaxCalcAccumulation.Indentation := TaxCalcLine0.Indentation;
                TaxCalcAccumulation.Bold := TaxCalcLine0.Bold;
                TaxCalcAccumulation.Description := TaxCalcLine0.Description;
                TaxCalcAccumulation."Template Line No." := TaxCalcLine0."Line No.";
                TaxCalcAccumulation."Amount Date Filter" :=
                  GeneralTermMgt.CalcIntervalDate(
                    TaxCalcAccumulation."Starting Date", TaxCalcAccumulation."Ending Date", TaxCalcLine0.Period);
                TaxCalcAccumulation.Amount := EntryNoAmountBuffer.Amount;
                TaxCalcAccumulation2.Reset();
                if not TaxCalcAccumulation2.FindLast() then
                    TaxCalcAccumulation2."Entry No." := 0;
                TaxCalcAccumulation."Entry No." := TaxCalcAccumulation2."Entry No." + 1;
                TaxCalcAccumulation.Insert();
            until EntryNoAmountBuffer.Next(1) = 0;
        end;
    end;
}
