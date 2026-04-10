#pragma warning disable AA0247
codeunit 17201 "Tax Register Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        TaxRegSection: Record "Tax Register Section";
#pragma warning disable AA0074
        Text1000: Label 'DEFAULT';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1007: Label 'Existing data after %1 for table %2 will be deleted.\\Continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1008: Label 'Incorrect period start date.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1009: Label 'Data before %1 in table %2 not found.\\Continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1011: Label 'Incorrect period end date.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1012: Label 'End date must be defined.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1013: Label 'Start date must be define.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1014: Label 'Section code must be defined.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label 'january,february,march,april,may,june,july,august,september,october,november,december';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text006: Label 'first quarter,second quarter,third quarter,fourth quarter';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text000: Label '1,5,,Dimension 1 Value Code';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text001: Label '1,5,,Dimension 2 Value Code';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label '1,5,,Dimension 3 Value Code';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text003: Label '1,5,,Dimension 4 Value Code';
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
    procedure GetDimCaptionClass(SectionCode: Code[10]; DimType: Integer): Text[250]
    begin
        if not TaxRegSection.Get(SectionCode) then
            Clear(TaxRegSection);
        case DimType of
            1:
                begin
                    if TaxRegSection."Dimension 1 Code" <> '' then
                        exit('1,5,' + TaxRegSection."Dimension 1 Code");

                    exit(Text000);
                end;
            2:
                begin
                    if TaxRegSection."Dimension 2 Code" <> '' then
                        exit('1,5,' + TaxRegSection."Dimension 2 Code");

                    exit(Text001);
                end;
            3:
                begin
                    if TaxRegSection."Dimension 3 Code" <> '' then
                        exit('1,5,' + TaxRegSection."Dimension 3 Code");

                    exit(Text002);
                end;
            4:
                begin
                    if TaxRegSection."Dimension 4 Code" <> '' then
                        exit('1,5,' + TaxRegSection."Dimension 4 Code");

                    exit(Text003);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcDebitBalancePointDate(SectionCode: Code[10]; EndDate: Date; var FiterDueDate45Days: Text[30]; var FiterDueDate45Days90Days: Text[30]; var FilterDueDate90Days3Years: Text[30]; var FilterDueDate3YearsDebit: Text[30])
    var
        DueDate45Days: Date;
        DueDate90Days: Date;
        DueDate3YearsDebit: Date;
    begin
        TaxRegSection.Get(SectionCode);

        TaxRegSection.TestField("Debit Balance Point 1");
        TaxRegSection.TestField("Debit Balance Point 2");
        TaxRegSection.TestField("Debit Balance Point 3");

        DueDate45Days := CalcDate(TaxRegSection."Debit Balance Point 1", EndDate + 1);
        DueDate90Days := CalcDate(TaxRegSection."Debit Balance Point 2", EndDate + 1);
        DueDate3YearsDebit := CalcDate(TaxRegSection."Debit Balance Point 3", EndDate + 1);

        // great 45
        FiterDueDate45Days := StrSubstNo('%1..%2', DueDate45Days, EndDate);
        // great 45 and less/equal 90 days
        FiterDueDate45Days90Days := StrSubstNo('%1..%2', DueDate90Days, DueDate45Days - 1);
        // great 90 and less/equal 3 years
        FilterDueDate90Days3Years := StrSubstNo('%1..%2', DueDate3YearsDebit, DueDate90Days - 1);
        // great 3 years
        FilterDueDate3YearsDebit := StrSubstNo('..%1', DueDate3YearsDebit - 1);
    end;

    [Scope('OnPrem')]
    procedure CalcCreditBalancePointDate(SectionCode: Code[10]; EndDate: Date; var FilterDueDate3YearsCredit: Text[30])
    var
        DueDate3YearsCredit: Date;
    begin
        TaxRegSection.Get(SectionCode);

        TaxRegSection.TestField("Credit Balance Point 1");
        DueDate3YearsCredit := CalcDate(TaxRegSection."Credit Balance Point 1", EndDate + 1);

        // great 3 years
        FilterDueDate3YearsCredit := StrSubstNo('..%1', DueDate3YearsCredit - 1);
    end;

    [Scope('OnPrem')]
    procedure SectionSelection(FormTemplate: Option " "; var SectionCode: Code[10]) SectionSelected: Boolean
    var
        TaxRegSection: Record "Tax Register Section";
    begin
        SectionSelected := true;

        TaxRegSection.Reset();
        TaxRegSection.SetRange(Type, FormTemplate);

        case TaxRegSection.Count of
            0:
                begin
                    TaxRegSection.Init();
                    TaxRegSection.Type := FormTemplate;
                    TaxRegSection.Code := Text1000;
                    TaxRegSection.Validate(Type);
                    TaxRegSection.Insert();
                    Commit();
                end;
            1:
                TaxRegSection.FindFirst();
            else
                SectionSelected := PAGE.RunModal(0, TaxRegSection) = ACTION::LookupOK;
        end;
        if SectionSelected then
            SectionCode := TaxRegSection.Code;
    end;

    [Scope('OnPrem')]
    procedure OpenReg(CurrentSectionCode: Code[10]; var TaxReg: Record "Tax Register")
    begin
        TaxReg.FilterGroup := 2;
        TaxReg.SetRange("Section Code", CurrentSectionCode);
        TaxReg.FilterGroup := 0;
    end;

    [Scope('OnPrem')]
    procedure ValidateAbsenceGLEntriesDate(StartDate: Date; EndDate: Date; SectionCode: Code[10])
    var
        TaxReg: Record "Tax Register";
        TaxRegAccumulation: Record "Tax Register Accumulation";
        TaxRegGLEntry: Record "Tax Register G/L Entry";
        DeleteConfirmed: Boolean;
    begin
        ValidateStartDateEndDate(StartDate, EndDate, SectionCode);

        TaxRegAccumulation.Reset();
        TaxRegAccumulation.SetCurrentKey(
          "Section Code", "Tax Register No.", "Template Line No.", "Starting Date", "Ending Date");
        TaxRegAccumulation.SetRange("Section Code", SectionCode);
        TaxRegAccumulation.SetFilter("Starting Date", '%1..', StartDate);
        TaxReg.SetRange("Section Code", SectionCode);
        TaxReg.SetRange("Table ID", DATABASE::"Tax Register G/L Entry");
        if TaxReg.Find('-') then
            repeat
                TaxRegAccumulation.SetRange("Tax Register No.", TaxReg."No.");
                if not TaxRegAccumulation.IsEmpty() then
                    if not DeleteConfirmed then begin
                        if not Confirm(Text1007, false, StartDate, TaxRegGLEntry.TableCaption()) then
                            Error('');

                        DeleteConfirmed := true;
                    end;
                TaxRegAccumulation.DeleteAll();
            until TaxReg.Next() = 0;

        if StartDate = TaxRegSection."Starting Date" then
            TaxRegSection."Absence GL Entries Date" := 0D
        else
            if FindPrevPeriodRegisterData(StartDate, EndDate, SectionCode, DATABASE::"Tax Register G/L Entry") then begin
                if EndDate <= TaxRegSection."Absence GL Entries Date" then
                    TaxRegSection."Absence GL Entries Date" := 0D;
            end else begin
                if not Confirm(Text1009, false, StartDate - 1, TaxRegGLEntry.TableCaption()) then
                    Error('');
                if (TaxRegSection."Absence GL Entries Date" = 0D) or
                   ((StartDate - 1) < TaxRegSection."Absence GL Entries Date")
                then
                    TaxRegSection."Absence GL Entries Date" := StartDate - 1;
            end;

        TaxRegSection.Validate("Last GL Entries Date", EndDate);
        TaxRegSection.Modify();
    end;

    [Scope('OnPrem')]
    procedure FindPrevPeriodRegisterData(StartDate: Date; EndDate: Date; SectionCode: Code[10]; TableID: Integer): Boolean
    var
        TaxReg: Record "Tax Register";
        TaxRegAccumulation: Record "Tax Register Accumulation";
    begin
        TaxRegAccumulation.Reset();
        TaxRegAccumulation.SetCurrentKey(
          "Section Code", "Tax Register No.", "Template Line No.", "Starting Date", "Ending Date");
        TaxRegAccumulation.SetRange("Section Code", SectionCode);
        TaxRegAccumulation.SetRange("Ending Date", StartDate - 1);

        TaxReg.SetRange("Section Code", SectionCode);
        TaxReg.SetRange("Table ID", TableID);
        if TaxReg.FindSet() then
            repeat
                TaxRegAccumulation.SetRange("Tax Register No.", TaxReg."No.");
                if TaxRegAccumulation.IsEmpty() then
                    exit(false);
            until TaxReg.Next() = 0;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ValidateAbsenceCVEntriesDate(StartDate: Date; EndDate: Date; SectionCode: Code[10])
    var
        TaxReg: Record "Tax Register";
        TaxRegCVEntry: Record "Tax Register CV Entry";
        TaxRegAccumulation: Record "Tax Register Accumulation";
    begin
        ValidateStartDateEndDate(StartDate, EndDate, SectionCode);

        TaxRegCVEntry.Reset();
        TaxRegCVEntry.SetCurrentKey("Section Code", "Starting Date");
        TaxRegCVEntry.SetRange("Section Code", SectionCode);
        TaxRegCVEntry.SetFilter("Starting Date", '%1..', StartDate);
        if TaxRegCVEntry.FindFirst() then begin
            if not Confirm(Text1007, false, StartDate, TaxRegCVEntry.TableCaption()) then
                Error('');
            TaxRegCVEntry.DeleteAll();
        end;

        TaxReg.SetRange("Section Code", SectionCode);
        TaxReg.SetRange("Table ID", DATABASE::"Tax Register CV Entry");
        if TaxReg.FindSet() then begin
            SetAccumulationFilter(TaxRegAccumulation, SectionCode, StartDate);
            repeat
                TaxRegAccumulation.SetRange("Tax Register No.", TaxReg."No.");
                TaxRegAccumulation.DeleteAll();
            until TaxReg.Next() = 0;
        end;

        TaxRegCVEntry.Reset();
        TaxRegCVEntry.SetCurrentKey("Section Code", "Ending Date");
        TaxRegCVEntry.SetRange("Section Code", SectionCode);
        TaxRegCVEntry.SetFilter("Ending Date", '%1..', StartDate);
        if not TaxRegCVEntry.IsEmpty() then
            Error(Text1008);

        if StartDate = TaxRegSection."Starting Date" then
            TaxRegSection."Absence CV Entries Date" := 0D
        else begin
            TaxRegCVEntry.Reset();
            TaxRegCVEntry.SetCurrentKey("Section Code", "Ending Date");
            TaxRegCVEntry.SetRange("Section Code", SectionCode);
            TaxRegCVEntry.SetFilter("Ending Date", '%1', StartDate - 1);
            if TaxRegCVEntry.FindFirst() then begin
                if EndDate <= TaxRegSection."Absence CV Entries Date" then
                    TaxRegSection."Absence CV Entries Date" := 0D;
            end else begin
                if not Confirm(Text1009, false, StartDate - 1, TaxRegCVEntry.TableCaption()) then
                    Error('');
                if (TaxRegSection."Absence CV Entries Date" = 0D) or
                   ((StartDate - 1) < TaxRegSection."Absence CV Entries Date")
                then
                    TaxRegSection."Absence CV Entries Date" := StartDate - 1;
            end;
        end;

        TaxRegSection.Validate("Last CV Entries Date", EndDate);
        TaxRegSection.Modify();
    end;

    [Scope('OnPrem')]
    procedure ValidateAbsenceItemEntriesDate(StartDate: Date; EndDate: Date; SectionCode: Code[10])
    var
        TaxReg: Record "Tax Register";
        TaxRegItemEntry: Record "Tax Register Item Entry";
        TaxRegAccumulation: Record "Tax Register Accumulation";
    begin
        ValidateStartDateEndDate(StartDate, EndDate, SectionCode);

        TaxRegItemEntry.Reset();
        TaxRegItemEntry.SetCurrentKey("Section Code", "Starting Date");
        TaxRegItemEntry.SetRange("Section Code", SectionCode);
        TaxRegItemEntry.SetFilter("Starting Date", '%1..', StartDate);
        if TaxRegItemEntry.FindFirst() then begin
            if not Confirm(Text1007, false, StartDate, TaxRegItemEntry.TableCaption()) then
                Error('');
            TaxRegItemEntry.DeleteAll();
        end;

        TaxReg.SetRange("Section Code", SectionCode);
        TaxReg.SetRange("Table ID", DATABASE::"Tax Register Item Entry");
        if TaxReg.Find('-') then begin
            SetAccumulationFilter(TaxRegAccumulation, SectionCode, StartDate);
            repeat
                TaxRegAccumulation.SetRange("Tax Register No.", TaxReg."No.");
                TaxRegAccumulation.DeleteAll();
            until TaxReg.Next() = 0;
        end;

        TaxRegItemEntry.Reset();
        TaxRegItemEntry.SetCurrentKey("Section Code", "Ending Date");
        TaxRegItemEntry.SetRange("Section Code", SectionCode);
        TaxRegItemEntry.SetFilter("Ending Date", '%1..', StartDate);
        if not TaxRegItemEntry.IsEmpty() then
            Error(Text1008);

        if StartDate = TaxRegSection."Starting Date" then
            TaxRegSection."Absence Item Entries Date" := 0D
        else begin
            TaxRegItemEntry.Reset();
            TaxRegItemEntry.SetCurrentKey("Section Code", "Ending Date");
            TaxRegItemEntry.SetRange("Section Code", SectionCode);
            TaxRegItemEntry.SetFilter("Ending Date", '%1', StartDate - 1);
            if TaxRegItemEntry.FindFirst() then begin
                if EndDate <= TaxRegSection."Absence Item Entries Date" then
                    TaxRegSection."Absence Item Entries Date" := 0D;
            end else begin
                if not Confirm(Text1009, false, StartDate - 1, TaxRegItemEntry.TableCaption()) then
                    Error('');
                if (TaxRegSection."Absence Item Entries Date" = 0D) or
                   ((StartDate - 1) < TaxRegSection."Absence Item Entries Date")
                then
                    TaxRegSection."Absence Item Entries Date" := StartDate - 1;
            end;
        end;

        TaxRegSection.Validate("Last Item Entries Date", EndDate);
        TaxRegSection.Modify();
    end;

    [Scope('OnPrem')]
    procedure ValidateAbsenceFAEntriesDate(StartDate: Date; EndDate: Date; SectionCode: Code[10])
    var
        TaxReg: Record "Tax Register";
        TaxRegAccumulation: Record "Tax Register Accumulation";
        TaxRegFAEntry: Record "Tax Register FA Entry";
        DeleteConfirmed: Boolean;
    begin
        ValidateStartDateEndDate(StartDate, EndDate, SectionCode);

        TaxRegAccumulation.Reset();
        TaxRegAccumulation.SetCurrentKey(
          "Section Code", "Tax Register No.", "Template Line No.", "Starting Date", "Ending Date");
        TaxRegAccumulation.SetRange("Section Code", SectionCode);
        TaxRegAccumulation.SetFilter("Starting Date", '%1..', StartDate);

        TaxReg.SetRange("Section Code", SectionCode);
        TaxReg.SetRange("Table ID", DATABASE::"Tax Register FA Entry");
        if TaxReg.Find('-') then
            repeat
                TaxRegAccumulation.SetRange("Tax Register No.", TaxReg."No.");
                if not TaxRegAccumulation.IsEmpty() then
                    if not DeleteConfirmed then begin
                        if not Confirm(Text1007, false, StartDate, TaxRegFAEntry.TableCaption()) then
                            Error('');

                        DeleteConfirmed := true;
                    end;
                TaxRegAccumulation.DeleteAll();
            until TaxReg.Next() = 0;

        if StartDate = TaxRegSection."Starting Date" then
            TaxRegSection."Absence FA Entries Date" := 0D
        else
            if FindPrevPeriodRegisterData(StartDate, EndDate, SectionCode, DATABASE::"Tax Register FA Entry") then begin
                if EndDate <= TaxRegSection."Absence FA Entries Date" then
                    TaxRegSection."Absence FA Entries Date" := 0D;
            end else begin
                if not Confirm(Text1009, false, StartDate - 1, TaxRegFAEntry.TableCaption()) then
                    Error('');
                if (TaxRegSection."Absence FA Entries Date" = 0D) or
                   ((StartDate - 1) < TaxRegSection."Absence FA Entries Date")
                then
                    TaxRegSection."Absence FA Entries Date" := StartDate - 1;
            end;

        TaxRegSection.Validate("Last FA Entries Date", EndDate);
        TaxRegSection.Modify();
    end;

    [Scope('OnPrem')]
    procedure ValidateAbsenceFEEntriesDate(StartDate: Date; EndDate: Date; SectionCode: Code[10])
    var
        TaxReg: Record "Tax Register";
        TaxRegFEEntry: Record "Tax Register FE Entry";
        TaxRegAccumulation: Record "Tax Register Accumulation";
    begin
        ValidateStartDateEndDate(StartDate, EndDate, SectionCode);

        TaxRegFEEntry.Reset();
        TaxRegFEEntry.SetCurrentKey("Section Code", "Starting Date");
        TaxRegFEEntry.SetRange("Section Code", SectionCode);
        TaxRegFEEntry.SetFilter("Starting Date", '%1..', StartDate);
        if TaxRegFEEntry.FindFirst() then begin
            if not Confirm(Text1007, false, StartDate, TaxRegFEEntry.TableCaption()) then
                Error('');
            TaxRegFEEntry.DeleteAll();
        end;

        TaxReg.SetRange("Section Code", SectionCode);
        TaxReg.SetRange("Table ID", DATABASE::"Tax Register FE Entry");
        if TaxReg.Find('-') then begin
            SetAccumulationFilter(TaxRegAccumulation, SectionCode, StartDate);
            repeat
                TaxRegAccumulation.SetRange("Tax Register No.", TaxReg."No.");
                TaxRegAccumulation.DeleteAll();
            until TaxReg.Next() = 0;
        end;

        TaxRegFEEntry.Reset();
        TaxRegFEEntry.SetCurrentKey("Section Code", "Ending Date");
        TaxRegFEEntry.SetRange("Section Code", SectionCode);
        TaxRegFEEntry.SetFilter("Ending Date", '%1..', StartDate);
        if not TaxRegFEEntry.IsEmpty() then
            Error(Text1008);

        if StartDate = TaxRegSection."Starting Date" then
            TaxRegSection."Absence FE Entries Date" := 0D
        else begin
            TaxRegFEEntry.Reset();
            TaxRegFEEntry.SetCurrentKey("Section Code", "Ending Date");
            TaxRegFEEntry.SetRange("Section Code", SectionCode);
            TaxRegFEEntry.SetFilter("Ending Date", '%1', StartDate - 1);
            if TaxRegFEEntry.FindFirst() then begin
                if EndDate <= TaxRegSection."Absence FE Entries Date" then
                    TaxRegSection."Absence FE Entries Date" := 0D;
            end else begin
                if not Confirm(Text1009, false, StartDate - 1, TaxRegFEEntry.TableCaption()) then
                    Error('');
                if (TaxRegSection."Absence FE Entries Date" = 0D) or
                   ((StartDate - 1) < TaxRegSection."Absence FE Entries Date")
                then
                    TaxRegSection."Absence FE Entries Date" := StartDate - 1;
            end;
        end;

        TaxRegSection.Validate("Last FE Entries Date", EndDate);
        TaxRegSection.Modify();
    end;

    [Scope('OnPrem')]
    procedure ValidateStartDateEndDate(StartDate: Date; EndDate: Date; SectionCode: Code[10])
    begin
        if SectionCode = '' then
            Error(Text1014);
        if StartDate = 0D then
            Error(Text1013);
        if EndDate = 0D then
            Error(Text1012);

        TaxRegSection.Get(SectionCode);

        if StartDate < TaxRegSection."Starting Date" then
            Error(Text1008);

        if (TaxRegSection."Ending Date" <> 0D) and (TaxRegSection."Ending Date" < EndDate) then
            Error(Text1011);
    end;

    [Scope('OnPrem')]
    procedure SetAccumulationFilter(var TaxRegAccumulation: Record "Tax Register Accumulation"; SectionCode: Code[10]; StartDate: Date)
    begin
        TaxRegAccumulation.Reset();
        TaxRegAccumulation.SetCurrentKey("Section Code", "Tax Register No.", "Template Line No.", "Starting Date", "Ending Date");
        TaxRegAccumulation.SetRange("Section Code", SectionCode);
        TaxRegAccumulation.SetFilter("Starting Date", '%1..', StartDate);
    end;

    [Scope('OnPrem')]
    procedure GetNextAvailableBeginDate(SectionCode: Code[10]; TableID: Integer; Minimum: Boolean) StartDate: Date
    var
        DateMax: Date;
    begin
        TaxRegSection.Get(SectionCode);
        DateMax := TaxRegSection.LastDateEntries();
        StartDate := TaxRegSection."Starting Date";
        case TableID of
            DATABASE::"Tax Register Accumulation":
                if DateMax <> 0D then
                    if (TaxRegSection."Ending Date" = 0D) or (DateMax < TaxRegSection."Ending Date") then
                        StartDate := DateMax + 1;
            DATABASE::"Tax Register G/L Entry":
                if (TaxRegSection."Last GL Entries Date" = 0D) or
                   (Minimum and (TaxRegSection."Absence GL Entries Date" <> 0D))
                then
                    StartDate := TaxRegSection."Starting Date"
                else
                    if Minimum and (DateMax <> 0D) then
                        StartDate := DateMax + 1
                    else
                        if (TaxRegSection."Ending Date" = 0D) or
                           (TaxRegSection."Last GL Entries Date" < TaxRegSection."Ending Date")
                        then
                            StartDate := TaxRegSection."Last GL Entries Date" + 1;
            DATABASE::"Tax Register CV Entry":
                if (TaxRegSection."Last CV Entries Date" = 0D) or
                   (Minimum and (TaxRegSection."Absence CV Entries Date" <> 0D))
                then
                    StartDate := TaxRegSection."Starting Date"
                else
                    if Minimum and (DateMax <> 0D) then
                        StartDate := DateMax + 1
                    else
                        if (TaxRegSection."Ending Date" = 0D) or
                           (TaxRegSection."Last CV Entries Date" < TaxRegSection."Ending Date")
                        then
                            StartDate := TaxRegSection."Last CV Entries Date" + 1;
            DATABASE::"Tax Register FA Entry":
                if (TaxRegSection."Last FA Entries Date" = 0D) or
                   (Minimum and (TaxRegSection."Absence FA Entries Date" <> 0D))
                then
                    StartDate := TaxRegSection."Starting Date"
                else
                    if Minimum and (DateMax <> 0D) then
                        StartDate := DateMax + 1
                    else
                        if (TaxRegSection."Ending Date" = 0D) or
                           (TaxRegSection."Last FA Entries Date" < TaxRegSection."Ending Date")
                        then
                            StartDate := TaxRegSection."Last FA Entries Date" + 1;
            DATABASE::"Tax Register Item Entry":
                if (TaxRegSection."Last Item Entries Date" = 0D) or
                   (Minimum and (TaxRegSection."Absence Item Entries Date" <> 0D))
                then
                    StartDate := TaxRegSection."Starting Date"
                else
                    if Minimum and (DateMax <> 0D) then
                        StartDate := DateMax + 1
                    else
                        if (TaxRegSection."Ending Date" = 0D) or
                           (TaxRegSection."Last Item Entries Date" < TaxRegSection."Ending Date")
                        then
                            StartDate := TaxRegSection."Last Item Entries Date" + 1;
            DATABASE::"Tax Register FE Entry":
                if (TaxRegSection."Last FE Entries Date" = 0D) or
                   (Minimum and (TaxRegSection."Absence FE Entries Date" <> 0D))
                then
                    StartDate := TaxRegSection."Starting Date"
                else
                    if Minimum and (DateMax <> 0D) then
                        StartDate := DateMax + 1
                    else
                        if (TaxRegSection."Ending Date" = 0D) or
                           (TaxRegSection."Last FE Entries Date" < TaxRegSection."Ending Date")
                        then
                            StartDate := TaxRegSection."Last FE Entries Date" + 1;
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
    procedure TaxRegisterCreate(SectionCode: Code[10]; Calendar: Record Date; UseGLEntry: Boolean; UseCVEntry: Boolean; UseItemEntry: Boolean; UseFAEntry: Boolean; UseFEEntry: Boolean; UsePREntry: Boolean; UseTemplate: Boolean)
    var
        TaxReg: Record "Tax Register";
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegAccumulation: Record "Tax Register Accumulation";
        EntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        CreateTaxRegItemEntry: Codeunit "Create Tax Register Item Entry";
        CreateTaxRegFEEntry: Codeunit "Create Tax Register FE Entry";
        CreateTaxRegCVEntry: Codeunit "Create Tax Register CV Entry";
        CreateTaxRegGLEntry: Codeunit "Create Tax Register GL Entry";
        CreateTaxRegFAEntry: Codeunit "Create Tax Register FA Entry";
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        TemplateRecordRef: RecordRef;
        LinkAccumulateRecordRef: RecordRef;
        StartDate: Date;
        EndDate: Date;
        CycleLevel: Integer;
    begin
        TaxRegSection.Get(SectionCode);
        if not (TaxRegSection.Status in [TaxRegSection.Status::Open, TaxRegSection.Status::Reporting]) then
            TaxRegSection.FieldError(Status);

        TaxRegTermMgt.CheckTaxRegTerm(
          true, SectionCode, DATABASE::"Tax Register Term", DATABASE::"Tax Register Term Formula");

        TaxRegTermMgt.CheckTaxRegLink(
          true, SectionCode, DATABASE::"Tax Register Template");

        Calendar."Period Start" := NormalDate(Calendar."Period Start");
        Calendar."Period End" := NormalDate(Calendar."Period End");
        CreateTaxRegGLEntry.BuildTaxRegGLCorresp(
          TaxRegSection.Code, CalcDate('<-CM>', Calendar."Period Start"), CalcDate('<CM>', Calendar."Period End"));

        Calendar.Reset();
        Calendar.SetRange("Period Type", Calendar."Period Type"::Month);
        Calendar.SetRange("Period Start", Calendar."Period Start", Calendar."Period End");
        if Calendar.FindSet() then
            repeat
                StartDate := NormalDate(Calendar."Period Start");
                EndDate := NormalDate(Calendar."Period End");
                case true of
                    UseGLEntry:
                        CreateTaxRegGLEntry.CreateRegister(TaxRegSection.Code, StartDate, EndDate);
                    UseCVEntry:
                        CreateTaxRegCVEntry.CreateRegister(TaxRegSection.Code, StartDate, EndDate);
                    UseItemEntry:
                        CreateTaxRegItemEntry.CreateRegister(TaxRegSection.Code, StartDate, EndDate);
                    UseFAEntry:
                        CreateTaxRegFAEntry.CreateRegister(TaxRegSection.Code, StartDate, EndDate);
                    UseFEEntry:
                        CreateTaxRegFEEntry.CreateRegister(TaxRegSection.Code, StartDate, EndDate);
                    UseTemplate:
                        begin
                            TaxReg.Reset();
                            TaxReg.SetRange("Section Code", TaxRegSection.Code);
                            TaxReg.SetRange("Storing Method", TaxReg."Storing Method"::Calculation);
                            LinkAccumulateRecordRef.Close();
                            LinkAccumulateRecordRef.Open(DATABASE::"Tax Register Accumulation");
                            TaxRegAccumulation.SetCurrentKey("Section Code", "Tax Register No.", "Template Line No.");
                            TaxRegAccumulation.SetRange("Section Code", TaxRegSection.Code);
                            TaxRegAccumulation.SetRange("Ending Date", EndDate);
                            LinkAccumulateRecordRef.SetView(TaxRegAccumulation.GetView(false));
                            if TaxReg.FindSet() then
                                repeat
                                    TaxRegAccumulation.SetRange("Tax Register No.", TaxReg."No.");
                                    TaxRegAccumulation.DeleteAll();
                                until TaxReg.Next(1) = 0;
                            TaxReg.SetRange("Storing Method");
                            TaxRegTemplate.SetRange("Section Code", TaxRegSection.Code);
                            CycleLevel := 1;
                            while CycleLevel <> 0 do begin
                                TaxReg.SetRange(Level, CycleLevel);
                                if not TaxReg.FindSet() then
                                    CycleLevel := 0
                                else begin
                                    repeat
                                        if TaxReg."Storing Method" = TaxReg."Storing Method"::Calculation then begin
                                            TaxRegTemplate.SetRange(Code, TaxReg."No.");
                                            if TaxRegTemplate.FindFirst() then begin
                                                TaxRegTemplate.SetRange("Date Filter", StartDate, EndDate);
                                                TemplateRecordRef.GetTable(TaxRegTemplate);
                                                TemplateRecordRef.SetView(TaxRegTemplate.GetView(false));
                                                TaxRegTermMgt.AccumulateTaxRegTemplate(
                                                  TemplateRecordRef, EntryNoAmountBuffer, LinkAccumulateRecordRef);
                                                CreateAccumulate(TaxRegTemplate, EntryNoAmountBuffer);
                                                EntryNoAmountBuffer.DeleteAll();
                                            end;
                                        end;
                                    until TaxReg.Next(1) = 0;
                                    CycleLevel += 1;
                                end;
                            end;
                        end;
                end;
            until Calendar.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateAccumulate(var TaxRegTemplate: Record "Tax Register Template"; var EntryNoAmountBuffer: Record "Entry No. Amount Buffer")
    var
        TaxRegTemplate2: Record "Tax Register Template";
        TaxRegAccumulation: Record "Tax Register Accumulation";
        TaxRegAccumulation2: Record "Tax Register Accumulation";
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
    begin
        if EntryNoAmountBuffer.FindSet() then begin
            TaxRegAccumulation.Init();
            TaxRegAccumulation."Starting Date" := TaxRegTemplate.GetRangeMin("Date Filter");
            TaxRegAccumulation."Ending Date" := TaxRegTemplate.GetRangeMax("Date Filter");
            TaxRegAccumulation."Section Code" := TaxRegTemplate."Section Code";
            TaxRegAccumulation."Tax Register No." := TaxRegTemplate.Code;
            repeat
                TaxRegTemplate2.Get(
                  TaxRegAccumulation."Section Code", TaxRegAccumulation."Tax Register No.", EntryNoAmountBuffer."Entry No.");
                TaxRegAccumulation."Report Line Code" := TaxRegTemplate2."Report Line Code";
                TaxRegAccumulation."Template Line Code" := TaxRegTemplate2."Line Code";
                TaxRegAccumulation.Indentation := TaxRegTemplate2.Indentation;
                TaxRegAccumulation.Bold := TaxRegTemplate2.Bold;
                TaxRegAccumulation.Description := TaxRegTemplate2.Description;
                TaxRegAccumulation."Template Line No." := TaxRegTemplate2."Line No.";
                TaxRegAccumulation."Amount Date Filter" :=
                  TaxRegTermMgt.CalcIntervalDate(
                    TaxRegAccumulation."Starting Date",
                    TaxRegAccumulation."Ending Date",
                    TaxRegTemplate2.Period);
                TaxRegAccumulation.Amount := EntryNoAmountBuffer.Amount;
                if not TaxRegAccumulation2.FindLast() then
                    TaxRegAccumulation2."Entry No." := 0;
                TaxRegAccumulation."Entry No." := TaxRegAccumulation2."Entry No." + 1;
                TaxRegAccumulation.Insert();
            until EntryNoAmountBuffer.Next(1) = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure OpenJnl(CurrentSectionCode: Code[10]; var TaxReg: Record "Tax Register")
    begin
        TaxReg.FilterGroup := 2;
        TaxReg.SetRange("Section Code", CurrentSectionCode);
        TaxReg.FilterGroup := 0;
    end;

    [Scope('OnPrem')]
    procedure CheckName(CurrentSectionCode: Code[10])
    begin
        TaxRegSection.Get(CurrentSectionCode);
    end;

    [Scope('OnPrem')]
    procedure SetName(CurrentSectionCode: Code[10]; var TaxReg: Record "Tax Register")
    begin
        TaxReg.FilterGroup := 2;
        TaxReg.SetRange("Section Code", CurrentSectionCode);
        TaxReg.FilterGroup := 0;
        if TaxReg.Find('-') then;
    end;

    [Scope('OnPrem')]
    procedure LookupName(var CurrentSectionCode: Code[10]; var TaxReg: Record "Tax Register")
    begin
        Commit();
        TaxRegSection.Code := TaxReg.GetRangeMax("Section Code");
        if PAGE.RunModal(0, TaxRegSection) = ACTION::LookupOK then begin
            CurrentSectionCode := TaxRegSection.Code;
            SetName(CurrentSectionCode, TaxReg);
        end;
    end;
}

