codeunit 144519 "ERM Tax Calc Mgt."
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTaxAcc: Codeunit "Library - Tax Accounting";
        TaxCalcMgt: Codeunit "Tax Calc. Mgt.";
        WrongFieldValueErr: Label 'Wrong value of field %1 in table %2.';
        WrongNextAvailBeginDateErr: Label 'Wrong next available begin date.';
        TaxRegAccumNotFoundErr: Label 'Tax register accumulation not found.';

    [Test]
    [Scope('OnPrem')]
    procedure FindTaxDate()
    var
        ExpectedCalendarPeriod: Record Date;
        ActualCalendarPeriod: Record Date;
        PeriodType: Option ,,Month,Quarter,Year;
        AmountType: Option "Current Period","Tax Period";
    begin
        Initialize();
        TaxCalcMgt.FindDate('=', ActualCalendarPeriod, PeriodType::Quarter, AmountType::"Tax Period");
        ExpectedCalendarPeriod."Period Type" := ExpectedCalendarPeriod."Period Type"::Quarter;
        ExpectedCalendarPeriod."Period Start" := CalcDate('<-CQ>', WorkDate());
        ExpectedCalendarPeriod.Find();
        ExpectedCalendarPeriod."Period Start" := CalcDate('<-CY>', ExpectedCalendarPeriod."Period Start");
        VerifyStartEndDates(ExpectedCalendarPeriod, ActualCalendarPeriod);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValidateAbsenceGLEntriesDate()
    var
        TaxCalcSection: Record "Tax Calc. Section";
        SectionCode: Code[10];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        InitTaxCalcAndDates(DATABASE::"Tax Register G/L Entry", SectionCode, StartDate, EndDate);
        TaxCalcMgt.ValidateAbsenceGLEntriesDate(StartDate, EndDate, SectionCode);
        TaxCalcSection.Get(SectionCode);
        Assert.AreEqual(
          CalcDate('<-1D>', StartDate),
          TaxCalcSection."No G/L Entries Date",
          StrSubstNo(WrongFieldValueErr, TaxCalcSection.FieldCaption("No G/L Entries Date"), TaxCalcSection.TableCaption()));
        Assert.AreEqual(
          EndDate,
          TaxCalcSection."Last G/L Entries Date",
          StrSubstNo(WrongFieldValueErr, TaxCalcSection.FieldCaption("Last G/L Entries Date"), TaxCalcSection.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValidateAbsenceItemEntriesDate()
    var
        TaxCalcSection: Record "Tax Calc. Section";
        SectionCode: Code[10];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        InitTaxCalcAndDates(DATABASE::"Tax Register Item Entry", SectionCode, StartDate, EndDate);
        TaxCalcMgt.ValidateAbsenceItemEntriesDate(StartDate, EndDate, SectionCode);
        TaxCalcSection.Get(SectionCode);
        Assert.AreEqual(
          CalcDate('<-1D>', StartDate),
          TaxCalcSection."No Item Entries Date",
          StrSubstNo(WrongFieldValueErr, TaxCalcSection.FieldCaption("No Item Entries Date"), TaxCalcSection.TableCaption()));
        Assert.AreEqual(
          EndDate,
          TaxCalcSection."Last Item Entries Date",
          StrSubstNo(WrongFieldValueErr, TaxCalcSection.FieldCaption("Last Item Entries Date"), TaxCalcSection.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValidateAbsenceFAEntriesDate()
    var
        TaxCalcSection: Record "Tax Calc. Section";
        SectionCode: Code[10];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        InitTaxCalcAndDates(DATABASE::"Tax Register FA Entry", SectionCode, StartDate, EndDate);
        TaxCalcMgt.ValidateAbsenceFAEntriesDate(StartDate, EndDate, SectionCode);
        TaxCalcSection.Get(SectionCode);
        Assert.AreEqual(
          CalcDate('<-1D>', StartDate),
          TaxCalcSection."No FA Entries Date",
          StrSubstNo(WrongFieldValueErr, TaxCalcSection.FieldCaption("No FA Entries Date"), TaxCalcSection.TableCaption()));
        Assert.AreEqual(
          EndDate,
          TaxCalcSection."Last FA Entries Date",
          StrSubstNo(WrongFieldValueErr, TaxCalcSection.FieldCaption("Last FA Entries Date"), TaxCalcSection.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure NextAvailableGLEntryBeginDate()
    var
        TaxCalcSection: Record "Tax Calc. Section";
        SectionCode: Code[10];
        StartDate: Date;
        EndDate: Date;
        TableID: Integer;
    begin
        Initialize();
        TableID := DATABASE::"Tax Calc. G/L Entry";
        InitTaxCalcAndDates(TableID, SectionCode, StartDate, EndDate);
        TaxCalcSection.Get(SectionCode);
        TaxCalcSection."Last G/L Entries Date" := StartDate;
        TaxCalcSection.Modify();
        Assert.AreEqual(
          CalcDate('<1D>', StartDate),
          TaxCalcMgt.GetNextAvailableBeginDate(SectionCode, TableID, false), WrongNextAvailBeginDateErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure NextAvailableItemEntryBeginDate()
    var
        TaxCalcSection: Record "Tax Calc. Section";
        SectionCode: Code[10];
        StartDate: Date;
        EndDate: Date;
        TableID: Integer;
    begin
        Initialize();
        TableID := DATABASE::"Tax Calc. Item Entry";
        InitTaxCalcAndDates(TableID, SectionCode, StartDate, EndDate);
        TaxCalcSection.Get(SectionCode);
        TaxCalcSection."Last Item Entries Date" := StartDate;
        TaxCalcSection.Modify();
        Assert.AreEqual(
          CalcDate('<1D>', StartDate),
          TaxCalcMgt.GetNextAvailableBeginDate(SectionCode, TableID, false), WrongNextAvailBeginDateErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure NextAvailableFAEntryBeginDate()
    var
        TaxCalcSection: Record "Tax Calc. Section";
        SectionCode: Code[10];
        StartDate: Date;
        EndDate: Date;
        TableID: Integer;
    begin
        Initialize();
        TableID := DATABASE::"Tax Calc. FA Entry";
        InitTaxCalcAndDates(TableID, SectionCode, StartDate, EndDate);
        TaxCalcSection.Get(SectionCode);
        TaxCalcSection."Last FA Entries Date" := StartDate;
        TaxCalcSection.Modify();
        Assert.AreEqual(
          CalcDate('<1D>', StartDate),
          TaxCalcMgt.GetNextAvailableBeginDate(SectionCode, TableID, false), WrongNextAvailBeginDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ParseCaptionPeriodAndName()
    var
        ExpectedCalendarPeriod: Record Date;
        ActualCalendarPeriod: Record Date;
        InputText: Text;
    begin
        Initialize();
        LibraryTaxAcc.FindCalendarPeriod(ExpectedCalendarPeriod, WorkDate());
        InputText := LowerCase(ExpectedCalendarPeriod."Period Name") + ' ' + Format(Date2DMY(ExpectedCalendarPeriod."Period Start", 3));
        ActualCalendarPeriod."Period Type" := ActualCalendarPeriod."Period Type"::Month;
        TaxCalcMgt.ParseCaptionPeriodAndName(InputText, ActualCalendarPeriod);
        VerifyStartEndDates(ExpectedCalendarPeriod, ActualCalendarPeriod);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitTaxPeriod()
    var
        ExpectedCalendarPeriod: Record Date;
        ActualCalendarPeriod: Record Date;
        Periodical: Option Month,Quarter,Year;
    begin
        Initialize();
        TaxCalcMgt.InitTaxPeriod(ActualCalendarPeriod, Periodical::Quarter, WorkDate());
        ExpectedCalendarPeriod.Get(ExpectedCalendarPeriod."Period Type"::Quarter, CalcDate('<-CQ>', WorkDate()));
        VerifyStartEndDates(ExpectedCalendarPeriod, ActualCalendarPeriod);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TaxRegisterCreate()
    var
        TaxCalcLine: Record "Tax Calc. Line";
        CalendarPeriod: Record Date;
        TaxCalcAccumulation: Record "Tax Calc. Accumulation";
    begin
        Initialize();
        InitTaxCalcWithLine(TaxCalcLine, CalendarPeriod, DATABASE::"Tax Register G/L Entry");
        TaxCalcMgt.CreateTaxCalcForPeriod(TaxCalcLine."Section Code", false, false, false, true, CalendarPeriod);
        FilterTaxCalcAccumulation(TaxCalcAccumulation, TaxCalcLine);
        Assert.IsFalse(TaxCalcAccumulation.IsEmpty, TaxRegAccumNotFoundErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TaxRegAccumulate()
    var
        TaxCalcLine: Record "Tax Calc. Line";
        TaxCalcAccumulation: Record "Tax Calc. Accumulation";
        CalendarPeriod: Record Date;
        EntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
    begin
        Initialize();
        InitTaxCalcWithLine(TaxCalcLine, CalendarPeriod, DATABASE::"Tax Register G/L Entry");
        TaxCalcLine.SetFilter("Date Filter", '%1..%2', WorkDate(), WorkDate());
        LibraryTaxAcc.CreateEntryNoAmountBuffer(EntryNoAmountBuffer, TaxCalcLine."Line No.");
        TaxCalcMgt.CreateAccumulate(TaxCalcLine, EntryNoAmountBuffer);
        Assert.AreEqual(
          EntryNoAmountBuffer.Amount, GetTaxCalcLineTotalAmount(TaxCalcLine),
          StrSubstNo(WrongFieldValueErr, TaxCalcAccumulation.FieldCaption(Amount), TaxCalcAccumulation.TableCaption()));
    end;

    local procedure Initialize()
    begin
        Clear(TaxCalcMgt);
    end;

    local procedure InitTaxCalcAndDates(TableID: Integer; var SectionCode: Code[10]; var StartDate: Date; var EndDate: Date)
    begin
        StartDate := WorkDate();
        EndDate := CalcDate('<1M>', StartDate);
        SectionCode :=
          CreateTaxCalcWithAccumulation(TableID, StartDate, EndDate);
    end;

    local procedure InitTaxCalcWithLine(var TaxCalcLine: Record "Tax Calc. Line"; var CalendarPeriod: Record Date; TableID: Integer)
    var
        TaxCalcHeader: Record "Tax Calc. Header";
    begin
        LibraryTaxAcc.CreateTaxCalcHeader(
          TaxCalcHeader, CreateTaxCalcSection(WorkDate(), WorkDate()), TableID);
        TaxCalcHeader.Validate("Storing Method", TaxCalcHeader."Storing Method"::Calculation);
        TaxCalcHeader.Validate(Level, 1);
        TaxCalcHeader.Modify(true);
        LibraryTaxAcc.CreateTaxCalcLine(TaxCalcLine, 0, TaxCalcHeader."Section Code", TaxCalcHeader."No.");
        LibraryTaxAcc.FindCalendarPeriod(CalendarPeriod, WorkDate());
    end;

    local procedure CreateTaxCalcWithAccumulation(TableID: Integer; StartingDate: Date; EndingDate: Date): Code[10]
    var
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcAccum: Record "Tax Calc. Accumulation";
        RecRef: RecordRef;
    begin
        LibraryTaxAcc.CreateTaxCalcHeader(
          TaxCalcHeader, CreateTaxCalcSection(StartingDate, EndingDate), TableID);

        TaxCalcAccum.Init();
        RecRef.GetTable(TaxCalcAccum);
        TaxCalcAccum."Entry No." := LibraryUtility.GetNewLineNo(RecRef, TaxCalcAccum.FieldNo("Entry No."));
        TaxCalcAccum."Section Code" := TaxCalcHeader."Section Code";
        TaxCalcAccum."Starting Date" := StartingDate;
        TaxCalcAccum.Insert();

        exit(TaxCalcHeader."Section Code");
    end;

    local procedure CreateTaxCalcSection(StartingDate: Date; EndingDate: Date): Code[10]
    var
        TaxCalcSection: Record "Tax Calc. Section";
    begin
        LibraryTaxAcc.CreateTaxCalcSection(TaxCalcSection, StartingDate, EndingDate);
        TaxCalcSection.Status := TaxCalcSection.Status::Open;
        TaxCalcSection.Modify();
        exit(TaxCalcSection.Code);
    end;

    local procedure FilterTaxCalcAccumulation(var TaxCalcAccumulation: Record "Tax Calc. Accumulation"; TaxCalcLine: Record "Tax Calc. Line")
    begin
        TaxCalcAccumulation.SetRange("Section Code", TaxCalcLine."Section Code");
        TaxCalcAccumulation.SetRange("Register No.", TaxCalcLine.Code);
    end;

    local procedure GetTaxCalcLineTotalAmount(TaxCalcLine: Record "Tax Calc. Line"): Decimal
    var
        TaxCalcAccumulation: Record "Tax Calc. Accumulation";
    begin
        FilterTaxCalcAccumulation(TaxCalcAccumulation, TaxCalcLine);
        TaxCalcAccumulation.CalcSums(Amount);
        exit(TaxCalcAccumulation.Amount)
    end;

    local procedure VerifyStartEndDates(ExpectedCalendarPeriod: Record Date; ActualCalendarPeriod: Record Date)
    begin
        Assert.AreEqual(
          ExpectedCalendarPeriod."Period Start",
          ActualCalendarPeriod."Period Start",
          StrSubstNo(WrongFieldValueErr, ActualCalendarPeriod.FieldCaption("Period Start"), ActualCalendarPeriod.TableCaption()));
        Assert.AreEqual(
          ExpectedCalendarPeriod."Period End",
          ClosingDate(ActualCalendarPeriod."Period End"),
          StrSubstNo(WrongFieldValueErr, ActualCalendarPeriod.FieldCaption("Period End"), ActualCalendarPeriod.TableCaption()));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

