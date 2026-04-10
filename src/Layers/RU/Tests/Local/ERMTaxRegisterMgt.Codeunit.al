codeunit 144517 "ERM Tax Register Mgt."
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
        TaxRegMgt: Codeunit "Tax Register Mgt.";
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
        TaxRegMgt.FindDate('=', ActualCalendarPeriod, PeriodType::Quarter, AmountType::"Tax Period");
        // Find period start and period end.
        ExpectedCalendarPeriod."Period Type" := ExpectedCalendarPeriod."Period Type"::Quarter;
        ExpectedCalendarPeriod."Period Start" := CalcDate('<-CQ>', WorkDate());
        ExpectedCalendarPeriod.Find();
        // Calculate difference for period start.
        ExpectedCalendarPeriod."Period Start" := CalcDate('<-CY>', ExpectedCalendarPeriod."Period Start");
        VerifyStartEndDates(ExpectedCalendarPeriod, ActualCalendarPeriod);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValidateAbsenceGLEntriesDate()
    var
        TaxRegSection: Record "Tax Register Section";
        SectionCode: Code[10];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        InitTaxRegisterAndDates(DATABASE::"Tax Register G/L Entry", SectionCode, StartDate, EndDate);
        TaxRegMgt.ValidateAbsenceGLEntriesDate(StartDate, EndDate, SectionCode);
        TaxRegSection.Get(SectionCode);
        Assert.AreEqual(
          CalcDate('<-1D>', StartDate),
          TaxRegSection."Absence GL Entries Date",
          StrSubstNo(WrongFieldValueErr, TaxRegSection.FieldCaption("Absence GL Entries Date"), TaxRegSection.TableCaption()));
        Assert.AreEqual(
          EndDate,
          TaxRegSection."Last GL Entries Date",
          StrSubstNo(WrongFieldValueErr, TaxRegSection.FieldCaption("Last GL Entries Date"), TaxRegSection.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValidateAbsenceCVEntriesDate()
    var
        TaxRegSection: Record "Tax Register Section";
        SectionCode: Code[10];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        InitTaxRegisterAndDates(DATABASE::"Tax Register G/L Entry", SectionCode, StartDate, EndDate);
        TaxRegMgt.ValidateAbsenceCVEntriesDate(StartDate, EndDate, SectionCode);
        TaxRegSection.Get(SectionCode);
        Assert.AreEqual(
          CalcDate('<-1D>', StartDate),
          TaxRegSection."Absence CV Entries Date",
          StrSubstNo(WrongFieldValueErr, TaxRegSection.FieldCaption("Absence CV Entries Date"), TaxRegSection.TableCaption()));
        Assert.AreEqual(
          EndDate,
          TaxRegSection."Last CV Entries Date",
          StrSubstNo(WrongFieldValueErr, TaxRegSection.FieldCaption("Last CV Entries Date"), TaxRegSection.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValidateAbsenceItemEntriesDate()
    var
        TaxRegSection: Record "Tax Register Section";
        SectionCode: Code[10];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        InitTaxRegisterAndDates(DATABASE::"Tax Register Item Entry", SectionCode, StartDate, EndDate);
        TaxRegMgt.ValidateAbsenceItemEntriesDate(StartDate, EndDate, SectionCode);
        TaxRegSection.Get(SectionCode);
        Assert.AreEqual(
          CalcDate('<-1D>', StartDate),
          TaxRegSection."Absence Item Entries Date",
          StrSubstNo(WrongFieldValueErr, TaxRegSection.FieldCaption("Absence Item Entries Date"), TaxRegSection.TableCaption()));
        Assert.AreEqual(
          EndDate,
          TaxRegSection."Last Item Entries Date",
          StrSubstNo(WrongFieldValueErr, TaxRegSection.FieldCaption("Last Item Entries Date"), TaxRegSection.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValidateAbsenceFAEntriesDate()
    var
        TaxRegSection: Record "Tax Register Section";
        SectionCode: Code[10];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        InitTaxRegisterAndDates(DATABASE::"Tax Register FA Entry", SectionCode, StartDate, EndDate);
        TaxRegMgt.ValidateAbsenceFAEntriesDate(StartDate, EndDate, SectionCode);
        TaxRegSection.Get(SectionCode);
        Assert.AreEqual(
          CalcDate('<-1D>', StartDate),
          TaxRegSection."Absence FA Entries Date",
          StrSubstNo(WrongFieldValueErr, TaxRegSection.FieldCaption("Absence FA Entries Date"), TaxRegSection.TableCaption()));
        Assert.AreEqual(
          EndDate,
          TaxRegSection."Last FA Entries Date",
          StrSubstNo(WrongFieldValueErr, TaxRegSection.FieldCaption("Last FA Entries Date"), TaxRegSection.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValidateAbsenceFEEntriesDate()
    var
        TaxRegSection: Record "Tax Register Section";
        SectionCode: Code[10];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        InitTaxRegisterAndDates(DATABASE::"Tax Register FE Entry", SectionCode, StartDate, EndDate);
        TaxRegMgt.ValidateAbsenceFEEntriesDate(StartDate, EndDate, SectionCode);
        TaxRegSection.Get(SectionCode);
        Assert.AreEqual(
          CalcDate('<-1D>', StartDate),
          TaxRegSection."Absence FE Entries Date",
          StrSubstNo(WrongFieldValueErr, TaxRegSection.FieldCaption("Absence FE Entries Date"), TaxRegSection.TableCaption()));
        Assert.AreEqual(
          EndDate,
          TaxRegSection."Last FE Entries Date",
          StrSubstNo(WrongFieldValueErr, TaxRegSection.FieldCaption("Last FE Entries Date"), TaxRegSection.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NextAvailableGLEntryBeginDate()
    var
        TaxRegSecton: Record "Tax Register Section";
        SectionCode: Code[10];
        StartDate: Date;
        EndDate: Date;
        TableID: Integer;
    begin
        Initialize();
        TableID := DATABASE::"Tax Register G/L Entry";
        InitTaxRegisterAndDates(TableID, SectionCode, StartDate, EndDate);
        TaxRegSecton.Get(SectionCode);
        TaxRegSecton."Last GL Entries Date" := StartDate;
        TaxRegSecton.Modify();
        Assert.AreEqual(
          CalcDate('<1D>', StartDate),
          TaxRegMgt.GetNextAvailableBeginDate(SectionCode, TableID, false), WrongNextAvailBeginDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NextAvailableCVEntryBeginDate()
    var
        TaxRegSecton: Record "Tax Register Section";
        SectionCode: Code[10];
        StartDate: Date;
        EndDate: Date;
        TableID: Integer;
    begin
        Initialize();
        TableID := DATABASE::"Tax Register CV Entry";
        InitTaxRegisterAndDates(TableID, SectionCode, StartDate, EndDate);
        TaxRegSecton.Get(SectionCode);
        TaxRegSecton."Last CV Entries Date" := StartDate;
        TaxRegSecton.Modify();
        Assert.AreEqual(
          CalcDate('<1D>', StartDate),
          TaxRegMgt.GetNextAvailableBeginDate(SectionCode, TableID, false), WrongNextAvailBeginDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NextAvailableItemEntryBeginDate()
    var
        TaxRegSecton: Record "Tax Register Section";
        SectionCode: Code[10];
        StartDate: Date;
        EndDate: Date;
        TableID: Integer;
    begin
        Initialize();
        TableID := DATABASE::"Tax Register Item Entry";
        InitTaxRegisterAndDates(TableID, SectionCode, StartDate, EndDate);
        TaxRegSecton.Get(SectionCode);
        TaxRegSecton."Last Item Entries Date" := StartDate;
        TaxRegSecton.Modify();
        Assert.AreEqual(
          CalcDate('<1D>', StartDate),
          TaxRegMgt.GetNextAvailableBeginDate(SectionCode, TableID, false), WrongNextAvailBeginDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NextAvailableFAEntryBeginDate()
    var
        TaxRegSecton: Record "Tax Register Section";
        SectionCode: Code[10];
        StartDate: Date;
        EndDate: Date;
        TableID: Integer;
    begin
        Initialize();
        TableID := DATABASE::"Tax Register FA Entry";
        InitTaxRegisterAndDates(TableID, SectionCode, StartDate, EndDate);
        TaxRegSecton.Get(SectionCode);
        TaxRegSecton."Last FA Entries Date" := StartDate;
        TaxRegSecton.Modify();
        Assert.AreEqual(
          CalcDate('<1D>', StartDate),
          TaxRegMgt.GetNextAvailableBeginDate(SectionCode, TableID, false), WrongNextAvailBeginDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NextAvailableFEEntryBeginDate()
    var
        TaxRegSecton: Record "Tax Register Section";
        SectionCode: Code[10];
        StartDate: Date;
        EndDate: Date;
        TableID: Integer;
    begin
        Initialize();
        TableID := DATABASE::"Tax Register FE Entry";
        InitTaxRegisterAndDates(TableID, SectionCode, StartDate, EndDate);
        TaxRegSecton.Get(SectionCode);
        TaxRegSecton."Last FE Entries Date" := StartDate;
        TaxRegSecton.Modify();
        Assert.AreEqual(
          CalcDate('<1D>', StartDate),
          TaxRegMgt.GetNextAvailableBeginDate(SectionCode, TableID, false), WrongNextAvailBeginDateErr);
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
        TaxRegMgt.ParseCaptionPeriodAndName(InputText, ActualCalendarPeriod);
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
        TaxRegMgt.InitTaxPeriod(ActualCalendarPeriod, Periodical::Quarter, WorkDate());
        ExpectedCalendarPeriod.Get(ExpectedCalendarPeriod."Period Type"::Quarter, CalcDate('<-CQ>', WorkDate()));
        VerifyStartEndDates(ExpectedCalendarPeriod, ActualCalendarPeriod);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxRegisterCreate()
    var
        TaxRegTemplate: Record "Tax Register Template";
        CalendarPeriod: Record Date;
        TaxRegAccum: Record "Tax Register Accumulation";
    begin
        Initialize();
        InitTaxRegisterWithTemplate(TaxRegTemplate, CalendarPeriod, DATABASE::"Tax Register G/L Entry");
        TaxRegMgt.TaxRegisterCreate(TaxRegTemplate."Section Code", CalendarPeriod, false, false, false, false, false, false, true);
        TaxRegAccum.SetRange("Section Code", TaxRegTemplate."Section Code");
        TaxRegAccum.SetRange("Tax Register No.", TaxRegTemplate.Code);
        Assert.IsFalse(TaxRegAccum.IsEmpty, TaxRegAccumNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxRegAccumulate()
    var
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegAccum: Record "Tax Register Accumulation";
        CalendarPeriod: Record Date;
        EntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
    begin
        Initialize();
        InitTaxRegisterWithTemplate(TaxRegTemplate, CalendarPeriod, DATABASE::"Tax Register G/L Entry");
        TaxRegTemplate.SetFilter("Date Filter", '%1..%2', WorkDate(), WorkDate());
        LibraryTaxAcc.CreateEntryNoAmountBuffer(EntryNoAmountBuffer, TaxRegTemplate."Line No.");
        TaxRegMgt.CreateAccumulate(TaxRegTemplate, EntryNoAmountBuffer);
        TaxRegAccum.SetRange("Section Code", TaxRegTemplate."Section Code");
        TaxRegAccum.SetRange("Tax Register No.", TaxRegTemplate.Code);
        TaxRegAccum.CalcSums(Amount);
        Assert.AreEqual(
          EntryNoAmountBuffer.Amount, TaxRegAccum.Amount,
          StrSubstNo(WrongFieldValueErr, TaxRegAccum.FieldCaption(Amount), TaxRegAccum.TableCaption()));
    end;

    local procedure Initialize()
    begin
        Clear(TaxRegMgt);
    end;

    local procedure InitTaxRegisterAndDates(TableID: Integer; var SectionCode: Code[10]; var StartDate: Date; var EndDate: Date)
    begin
        SectionCode :=
          CreateTaxRegisterWithAccumulation(TableID, WorkDate());
        StartDate := WorkDate();
        EndDate := CalcDate('<1M>', StartDate);
    end;

    local procedure InitTaxRegisterWithTemplate(var TaxRegTemplate: Record "Tax Register Template"; var CalendarPeriod: Record Date; TableID: Integer)
    var
        TaxRegister: Record "Tax Register";
    begin
        LibraryTaxAcc.CreateTaxReg(TaxRegister, CreateTaxRegSection(WorkDate()), TableID, TaxRegister."Storing Method"::Calculation);
        LibraryTaxAcc.CreateTaxRegTemplate(TaxRegTemplate, TaxRegister."Section Code", TaxRegister."No.");
        LibraryTaxAcc.FindCalendarPeriod(CalendarPeriod, WorkDate());
    end;

    local procedure CreateTaxRegisterWithAccumulation(TableID: Integer; AccumDate: Date): Code[10]
    var
        TaxRegister: Record "Tax Register";
        TaxRegAccum: Record "Tax Register Accumulation";
        RecRef: RecordRef;
    begin
        LibraryTaxAcc.CreateTaxReg(
          TaxRegister, CreateTaxRegSection(AccumDate), TableID, TaxRegister."Storing Method"::Calculation);

        TaxRegAccum.Init();
        RecRef.GetTable(TaxRegAccum);
        TaxRegAccum."Entry No." := LibraryUtility.GetNewLineNo(RecRef, TaxRegAccum.FieldNo("Entry No."));
        TaxRegAccum."Section Code" := TaxRegister."Section Code";
        TaxRegAccum."Starting Date" := AccumDate;
        TaxRegAccum.Insert();

        exit(TaxRegister."Section Code");
    end;

    local procedure CreateTaxRegSection(StartingDate: Date): Code[10]
    var
        TaxRegSection: Record "Tax Register Section";
    begin
        TaxRegSection.Init();
        TaxRegSection.Code := LibraryUtility.GenerateGUID();
        TaxRegSection."Starting Date" := CalcDate('<-1M>', StartingDate);
        TaxRegSection.Insert();
        exit(TaxRegSection.Code);
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

