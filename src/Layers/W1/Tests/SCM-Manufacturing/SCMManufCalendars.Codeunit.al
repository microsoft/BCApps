// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Manufacturing.Capacity;
using System.TestLibraries.Utilities;
using Microsoft.Foundation.Enums;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.MachineCenter;
using System.Utilities;
using Microsoft.Finance.Analysis;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;

codeunit 137076 "SCM Manuf Calendars"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [SCM]
        Initialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CalendarMgt: Codeunit "Shop Calendar Management";
        Initialized: Boolean;
        CaptionError: Label 'Caption must be the same.';
        CalcTimeDeltaErr: Label 'Wrong CalcTimeDelta() result';
        CalcTimeSubtractErr: Label 'Wrong CalcTimeSubtract() result';
        MaxDateErr: Label 'Wrong Max Date value';
        WrongFieldValueErr: Label 'Wrong value of the field %1 in table %2';
        WrongNoOfLinesErr: Label 'Wrong number of lines in table %1';
        AbsenceEntryNotUpdatedErr: Label 'Absence entry must be updated.';
        WrongAbsenceEntryUpdatedErr: Label 'Absence entry must be skipped, as it has "Updated" flag set.';

    [Test]
    [HandlerFunctions('WorkCenterCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure WorkCenterCalendarWithPeriodTypeDay()
    begin
        // Setup.
        Initialize();
        WorkCenterCalendarWithPeriodType("Analysis Period Type"::Day, GetMonth(1, -1), GetMonth(1, 1));  // Calendar Month range required: -1M to 1M.
    end;

    [Test]
    [HandlerFunctions('WorkCenterCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure WorkCenterCalendarWithPeriodTypeWeek()
    begin
        // Setup.
        Initialize();
        WorkCenterCalendarWithPeriodType("Analysis Period Type"::Week, GetMonth(1, -1), GetMonth(1, 1));  // Calendar Month range required: -1M to 1M.
    end;

    [Test]
    [HandlerFunctions('WorkCenterCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure WorkCenterCalendarWithPeriodTypeMonth()
    begin
        // Setup.
        Initialize();
        WorkCenterCalendarWithPeriodType("Analysis Period Type"::Month, GetMonth(1, -1), GetMonth(1, 1));  // Calendar Month range required: -1M to 1M.
    end;

    [Test]
    [HandlerFunctions('WorkCenterCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure WorkCenterCalendarWithPeriodTypeQuarter()
    begin
        // Setup.
        Initialize();
        WorkCenterCalendarWithPeriodType("Analysis Period Type"::Quarter, GetMonth(3, -1), GetMonth(3, 1));  // Calendar Month range required: -3M to 3M.
    end;

    [Test]
    [HandlerFunctions('WorkCenterCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure WorkCenterCalendarWithPeriodTypeYear()
    begin
        // Setup.
        Initialize();
        WorkCenterCalendarWithPeriodType("Analysis Period Type"::Year, GetYear(1, -1), GetYear(1, 1));  // Calendar Year range required: -1Y to 1Y.
    end;

    [Test]
    [HandlerFunctions('WorkCenterCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure WorkCenterCalendarWithPeriodTypeAccountingPeriod()
    begin
        // Setup.
        Initialize();
        WorkCenterCalendarWithPeriodType("Analysis Period Type"::"Accounting Period", GetYear(2, -1), GetYear(2, 1));  // Calendar Year range required: -2Y to 2Y.
    end;

    local procedure WorkCenterCalendarWithPeriodType(PeriodType: Enum "Analysis Period Type"; StartingDate: Date; EndingDate: Date)
    var
        WorkCenter: Record "Work Center";
        MatrixRecords: array[32] of Record Date;
        MatrixManagement: Codeunit "Matrix Management";
        WorkCenterCalendar: TestPage "Work Center Calendar";
        CaptionSet: array[32] of Text[80];
        CaptionRange: Text;
        SetPosition: Option Initial,Previous,Same,Next,PreviousColumn,NextColumn;
        PrimaryKeyFirstRecordInCurrentSet: Text;
        CurrentSetLength: Integer;
    begin
        // Create Work Center.
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, StartingDate, EndingDate);

        // Open Work Center Calendar. Update Period Type.
        OpenWorkCenterCalendarPage(WorkCenterCalendar, WorkCenter."No.", PeriodType);

        // Using Matrix Management to Generate Period Matrix Data.
        MatrixManagement.GeneratePeriodMatrixData(
          SetPosition, ArrayLen(MatrixRecords), false, PeriodType, '', PrimaryKeyFirstRecordInCurrentSet, CaptionSet, CaptionRange,
          CurrentSetLength, MatrixRecords);

        // Enqueue Values for Page Handler - WorkCenterCalendarMatrixPageHandler.
        LibraryVariableStorage.Enqueue(WorkCenter."No.");
        LibraryVariableStorage.Enqueue(CaptionSet[1]);
        LibraryVariableStorage.Enqueue(CaptionSet[2]);
        DateFilterOnWorkCenter(WorkCenter, MatrixRecords[1]);
        LibraryVariableStorage.Enqueue(WorkCenter."Capacity (Effective)");
        DateFilterOnWorkCenter(WorkCenter, MatrixRecords[2]);
        LibraryVariableStorage.Enqueue(WorkCenter."Capacity (Effective)");

        // Exercise and Verify: Open Show Matrix and Verify Column Captions and Matrix value on Work Center Calendar Matrix Page on Page Handler WorkCenterCalendarMatrixPage.
        WorkCenterCalendar.ShowMatrix.Invoke();

        // Tear Down.
        CleanupCalendarEntry(WorkCenter."No.");
    end;

    [Test]
    [HandlerFunctions('WorkCenterGroupCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure WorkCenterGroupCalendarWithPeriodTypeDayAndCapacityUOMMinutes()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        // Setup.
        Initialize();
        WorkCenterGroupCalendarWithPeriodTypeAndCapacityUOM(
          "Analysis Period Type"::Day, CapacityUnitOfMeasure.Type::Minutes, GetMonth(1, -1), GetMonth(1, 1));  // Calendar Month range required: -1M to 1M.
    end;

    [Test]
    [HandlerFunctions('WorkCenterGroupCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure WorkCenterGroupCalendarWithPeriodTypeDayAndCapacityUOMHours()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        // Setup.
        Initialize();
        WorkCenterGroupCalendarWithPeriodTypeAndCapacityUOM(
          "Analysis Period Type"::Day, CapacityUnitOfMeasure.Type::Hours, GetMonth(1, -1), GetMonth(1, 1));  // Calendar Month range required: -1M to 1M.
    end;

    [Test]
    [HandlerFunctions('WorkCenterGroupCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure WorkCenterGroupCalendarWithPeriodTypeWeekAndCapacityUOMMinutes()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        // Setup.
        Initialize();
        WorkCenterGroupCalendarWithPeriodTypeAndCapacityUOM(
          "Analysis Period Type"::Week, CapacityUnitOfMeasure.Type::Minutes, GetMonth(1, -1), GetMonth(1, 1));  // Calendar Month range required: -1M to 1M.
    end;

    [Test]
    [HandlerFunctions('WorkCenterGroupCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure WorkCenterGroupCalendarWithPeriodTypeMonthAndCapacityUOMMinutes()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        // Setup.
        Initialize();
        WorkCenterGroupCalendarWithPeriodTypeAndCapacityUOM(
          "Analysis Period Type"::Month, CapacityUnitOfMeasure.Type::Minutes, GetMonth(1, -1), GetMonth(1, 1));  // Calendar Month range required: -1M to 1M.
    end;

    [Test]
    [HandlerFunctions('WorkCenterGroupCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure WorkCenterGroupCalendarWithPeriodTypeQuarterAndCapacityUOMMinutes()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        // Setup.
        Initialize();
        WorkCenterGroupCalendarWithPeriodTypeAndCapacityUOM(
          "Analysis Period Type"::Quarter, CapacityUnitOfMeasure.Type::Minutes, GetMonth(3, -1), GetMonth(3, 1)); // Calendar Month range required: -3M to 3M.
    end;

    [Test]
    [HandlerFunctions('WorkCenterGroupCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure WorkCenterGroupCalendarWithPeriodTypeYearAndCapacityUOMMinutes()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        // Setup.
        Initialize();
        WorkCenterGroupCalendarWithPeriodTypeAndCapacityUOM(
          "Analysis Period Type"::Year, CapacityUnitOfMeasure.Type::Minutes, GetYear(1, -1), GetYear(1, 1));  // Calendar Year range required: -1Y to 1Y.
    end;

    [Test]
    [HandlerFunctions('WorkCenterGroupCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure WorkCenterGroupCalendarWithPeriodTypeAccountingPeriodAndCapacityUOMMinutes()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        // Setup.
        Initialize();
        WorkCenterGroupCalendarWithPeriodTypeAndCapacityUOM(
          "Analysis Period Type"::"Accounting Period", CapacityUnitOfMeasure.Type::Minutes, GetYear(2, -1), GetYear(2, 1));  // Calendar Year range required: -2Y to 2Y.
    end;

    local procedure WorkCenterGroupCalendarWithPeriodTypeAndCapacityUOM(PeriodType: Enum "Analysis Period Type"; Type: Enum "Capacity Unit of Measure"; StartingDate: Date; EndingDate: Date)
    var
        WorkCenter: Record "Work Center";
        MatrixRecords: array[32] of Record Date;
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        MatrixManagement: Codeunit "Matrix Management";
        WorkCtrGroupCalendar: TestPage "Work Ctr. Group Calendar";
        MatrixColumnCaptions: array[32] of Text[80];
        ColumnSet: Text;
        SetPosition: Option Initial,Previous,Same,Next,PreviousColumn,NextColumn;
        PrimaryKeyFirstRecordInCurrentSet: Text;
        CurrentSetLength: Integer;
    begin
        // Create Work Center.
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, StartingDate, EndingDate);

        // Open Work Center Group Calendar. Update Period Type and Capacity Unit of Measure.
        FindCapacityUnitOfMeasure(CapacityUnitOfMeasure, Type);
        OpenWorkCenterGroupCalendarPage(WorkCtrGroupCalendar, WorkCenter."Work Center Group Code", PeriodType, CapacityUnitOfMeasure.Code);

        // Using Matrix Management to Generate Period Matrix Data.
        MatrixManagement.GeneratePeriodMatrixData(
          SetPosition, ArrayLen(MatrixRecords), false, PeriodType, '', PrimaryKeyFirstRecordInCurrentSet, MatrixColumnCaptions, ColumnSet,
          CurrentSetLength, MatrixRecords);

        // Enqueue Values for Page Handler - WorkCenterGroupCalendarMatrixPageHandler.
        LibraryVariableStorage.Enqueue(WorkCenter."Work Center Group Code");
        LibraryVariableStorage.Enqueue(MatrixColumnCaptions[1]);
        LibraryVariableStorage.Enqueue(MatrixColumnCaptions[2]);
        LibraryVariableStorage.Enqueue(
          CalculateCapacityEffective(WorkCenter."Work Center Group Code", MatrixRecords[1], CapacityUnitOfMeasure.Code));
        LibraryVariableStorage.Enqueue(
          CalculateCapacityEffective(WorkCenter."Work Center Group Code", MatrixRecords[2], CapacityUnitOfMeasure.Code));

        // Exercise and Verify: Open Show Matrix and Verify Column Captions and Matrix value on Work Center Group Calendar Matrix Page on Page Handler WorkCenterGroupCalendarMatrixPageHandler.
        WorkCtrGroupCalendar.ShowMatrix.Invoke();

        // Tear Down.
        CleanupCalendarEntry(WorkCenter."No.");
    end;

    [Test]
    [HandlerFunctions('MachineCenterCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure MachineCenterCalendarWithPeriodTypeDay()
    begin
        // Setup.
        Initialize();
        MachineCenterCalendarWithPeriodType("Analysis Period Type"::Day, GetMonth(1, -1), GetMonth(1, 1));  // Calendar Month range required: -1M to 1M.
    end;

    [Test]
    [HandlerFunctions('MachineCenterCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure MachineCenterCalendarWithPeriodTypeWeek()
    begin
        // Setup.
        Initialize();
        MachineCenterCalendarWithPeriodType("Analysis Period Type"::Week, GetMonth(1, -1), GetMonth(1, 1));  // Calendar Month range required: -1M to 1M.
    end;

    [Test]
    [HandlerFunctions('MachineCenterCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure MachineCenterCalendarWithPeriodTypeMonth()
    begin
        // Setup.
        Initialize();
        MachineCenterCalendarWithPeriodType("Analysis Period Type"::Month, GetMonth(1, -1), GetMonth(1, 1));  // Calendar Month range required: -1M to 1M.
    end;

    [Test]
    [HandlerFunctions('MachineCenterCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure MachineCenterCalendarWithPeriodTypeQuarter()
    begin
        // Setup.
        Initialize();
        MachineCenterCalendarWithPeriodType("Analysis Period Type"::Quarter, GetMonth(3, -1), GetMonth(3, 1));  // Calendar Month range required: -3M to 3M.
    end;

    [Test]
    [HandlerFunctions('MachineCenterCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure MachineCenterCalendarWithPeriodTypeYear()
    begin
        // Setup.
        Initialize();
        MachineCenterCalendarWithPeriodType("Analysis Period Type"::Year, GetYear(1, -1), GetYear(1, 1));  // Calendar Year range required: -1Y to 1Y.
    end;

    [Test]
    [HandlerFunctions('MachineCenterCalendarMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure MachineCenterCalendarWithPeriodTypeAccountingPeriod()
    begin
        // Setup.
        Initialize();
        MachineCenterCalendarWithPeriodType("Analysis Period Type"::"Accounting Period", GetYear(2, -1), GetYear(2, 1));  // Calendar Year range required: -2Y to 2Y.
    end;

    local procedure MachineCenterCalendarWithPeriodType(PeriodType: Enum "Analysis Period Type"; StartingDate: Date; EndingDate: Date)
    var
        MachineCenter: Record "Machine Center";
        MatrixRecords: array[32] of Record Date;
        MatrixManagement: Codeunit "Matrix Management";
        MachineCenterCalendar: TestPage "Machine Center Calendar";
        MatrixColumnCaptions: array[32] of Text[80];
        ColumnSet: Text;
        SetPosition: Option Initial,Previous,Same,Next,PreviousColumn,NextColumn;
        PrimaryKeyFirstRecordInCurrentSet: Text;
        CurrentSetLength: Integer;
    begin
        // Create Work Center and Machine Center.
        CreateMachineCenterWithHolidays(MachineCenter, LibraryRandom.RandDec(10, 1), 100, StartingDate, EndingDate);

        // Open Machine Center Calendar. Update Period Type.
        OpenMachineCenterCalendarPage(MachineCenterCalendar, MachineCenter."No.", PeriodType);

        // Using Matrix Management to Generate Period Matrix Data.
        MatrixManagement.GeneratePeriodMatrixData(
          SetPosition, ArrayLen(MatrixRecords), false, PeriodType, '', PrimaryKeyFirstRecordInCurrentSet, MatrixColumnCaptions, ColumnSet,
          CurrentSetLength, MatrixRecords);

        // Enqueue Values for Page Handler - MachineCenterCalendarMatrixPageHandler.
        LibraryVariableStorage.Enqueue(MachineCenter."No.");
        LibraryVariableStorage.Enqueue(MatrixColumnCaptions[1]);
        LibraryVariableStorage.Enqueue(MatrixColumnCaptions[2]);
        DateFilterOnMachineCenter(MachineCenter, MatrixRecords[1]);
        LibraryVariableStorage.Enqueue(MachineCenter."Capacity (Effective)");
        DateFilterOnMachineCenter(MachineCenter, MatrixRecords[2]);
        LibraryVariableStorage.Enqueue(MachineCenter."Capacity (Effective)");

        // Exercise and Verify: Open Show Matrix and Verify Column Captions and Matrix value on Machine Center Calendar Matrix Page on Page Handler MachineCenterCalendarMatrixPageHandler.
        MachineCenterCalendar.ShowMatrix.Invoke();

        // Tear Down.
        CleanupCalendarEntry(MachineCenter."Work Center No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcTimeDelta_UT1()
    var
        Time: Time;
        Hour: Integer;
        "Min": Integer;
        Sec: Integer;
    begin
        // Test Time Delta in case of the same Start, End time values
        Initialize();
        Hour := LibraryRandom.RandIntInRange(0, 23);
        Min := LibraryRandom.RandIntInRange(0, 59);
        Sec := LibraryRandom.RandIntInRange(0, 59);

        Time := CreateTime(Hour, Min, Sec);

        VerifyTimeDeltaAndSubtract(Time, Time, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcTimeDelta_UT2()
    var
        Time: array[2] of Time;
        Hour: array[2] of Integer;
        "Min": Integer;
        Sec: Integer;
        i: Integer;
    begin
        // Test Time Delta in case of integer number of Hours
        Initialize();
        Hour[1] := LibraryRandom.RandIntInRange(13, 22);
        Hour[2] := LibraryRandom.RandIntInRange(0, 12);
        Min := LibraryRandom.RandIntInRange(0, 59);
        Sec := LibraryRandom.RandIntInRange(0, 59);

        for i := 1 to 2 do
            Time[i] := CreateTime(Hour[i], Min, Sec);

        VerifyTimeDeltaAndSubtract(Time[1], Time[2], (Hour[1] - Hour[2]) * 60 * 60 * 1000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcTimeDelta_UT3()
    var
        Time: array[2] of Time;
        Hour: array[2] of Integer;
        "Min": Integer;
        Sec: Integer;
        i: Integer;
    begin
        // Test Time Delta in case of non 23:59:59 EndingTime
        Initialize();
        Hour[1] := LibraryRandom.RandIntInRange(13, 22);
        Hour[2] := LibraryRandom.RandIntInRange(0, 12);
        for i := 1 to 2 do begin
            Min := LibraryRandom.RandIntInRange(0, 59);
            Sec := LibraryRandom.RandIntInRange(0, 59);
            Time[i] := CreateTime(Hour[i], Min, Sec);
        end;

        VerifyTimeDeltaAndSubtract(Time[1], Time[2], Time[1] - Time[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcTimeDelta_UT4()
    var
        Time: array[2] of Time;
        Hour: Integer;
        "Min": Integer;
        Sec: Integer;
    begin
        // Test Time Delta in case of 23:59:59 EndingTime
        Initialize();
        Hour := LibraryRandom.RandIntInRange(0, 22);
        Min := LibraryRandom.RandIntInRange(0, 59);
        Sec := LibraryRandom.RandIntInRange(0, 59);

        Time[1] := CreateTime(23, 59, 59);
        Time[2] := CreateTime(Hour, Min, Sec);

        VerifyTimeDeltaAndSubtract(Time[1], Time[2], Time[1] - Time[2] + 1000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcTimeDelta_UT5()
    var
        Time: array[2] of Time;
        Hour: Integer;
        "Min": Integer;
        Sec: Integer;
    begin
        // Test Time Delta in case of 23:59:59:001 EndingTime
        Initialize();
        Hour := LibraryRandom.RandIntInRange(0, 22);
        Min := LibraryRandom.RandIntInRange(0, 59);
        Sec := LibraryRandom.RandIntInRange(0, 59);

        Time[1] := 235959.001T;
        Time[2] := CreateTime(Hour, Min, Sec);

        VerifyTimeDeltaAndSubtract(Time[1], Time[2], Time[1] - Time[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcTimeDelta_UT6()
    var
        Time: Time;
    begin
        // Test Time Delta in case of the same Start, End 23:59:59 Time value
        Initialize();
        Time := CreateTime(23, 59, 59);

        VerifyTimeDeltaAndSubtract(Time, Time, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckMaxDate_UT()
    begin
        // Verify MaxDate value
        Assert.AreEqual(99991230D, CalendarMgt.GetMaxDate(), MaxDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PS29218_CalculateCapacityLoadWithReducedEfficiency()
    var
        MachineCenter: Record "Machine Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderDueDate: Date;
    begin
        Initialize();

        ProdOrderDueDate := CalcDate('<CW>', WorkDate());
        CreateMachineCenterWithHolidays(MachineCenter, 1, 75, CalcDate('<-1W>', ProdOrderDueDate), ProdOrderDueDate);
        CreateRouting(RoutingHeader, RoutingLine, MachineCenter."No.", 1, 1, 24, 13);
        UpdateRoutingTimesUOM(RoutingLine);
        CertifyRouting(RoutingHeader);
        CreateItemWithRouting(Item, RoutingHeader."No.");

        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item, '', '', 10, ProdOrderDueDate);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        VerifyProductionOrder(ProductionOrder);
    end;

    [Test]
    [HandlerFunctions('AbsencePageHandler')]
    [Scope('OnPrem')]
    procedure TFS360551_UpdateActionUpdatesAbsenceEntry()
    var
        MachineCenter: Record "Machine Center";
        CalendarAbsenceEntry: Record "Calendar Absence Entry";
    begin
        // Verify that the selected absence entry is updated when "Update" action is run in the Absence page
        Initialize();
        CreateMachineCenterWithoutHolidays(MachineCenter, LibraryRandom.RandIntInRange(3, 10), 100, WorkDate(), WorkDate());
        CreateAndUpdateMachineCenterAbsence(CalendarAbsenceEntry, MachineCenter."No.", MachineCenter.Capacity - 1, 0, 1);
        CreateMachineCenterAbsence(CalendarAbsenceEntry, MachineCenter."No.", MachineCenter.Capacity, 0, 2);

        RunUpdateAbsenceAction(CalendarAbsenceEntry);

        CalendarAbsenceEntry.Find();
        Assert.IsTrue(CalendarAbsenceEntry.Updated, AbsenceEntryNotUpdatedErr);
    end;

    [Test]
    [HandlerFunctions('AbsencePageHandler')]
    [Scope('OnPrem')]
    procedure TFS360551_UpdateActionSkipsUpdatedAbsenceEntry()
    var
        MachineCenter: Record "Machine Center";
        CalendarAbsenceEntry: Record "Calendar Absence Entry";
        CalendarAbsenceEntryToUpdate: Record "Calendar Absence Entry";
        CalendarEntry: Record "Calendar Entry";
    begin
        // Verify that the selected entry having "Updated" status set, is not updated when the "Update" action is run
        Initialize();
        CreateMachineCenterWithoutHolidays(MachineCenter, LibraryRandom.RandIntInRange(3, 10), 100, WorkDate(), WorkDate());
        CreateAndUpdateMachineCenterAbsence(CalendarAbsenceEntryToUpdate, MachineCenter."No.", MachineCenter.Capacity - 1, 0, 1);
        CreateAndUpdateMachineCenterAbsence(CalendarAbsenceEntry, MachineCenter."No.", MachineCenter.Capacity, 0, 2);

        RunUpdateAbsenceAction(CalendarAbsenceEntryToUpdate);

        FindCalendarEntry(CalendarEntry, CalendarAbsenceEntry);
        Assert.AreEqual(CalendarEntry."Absence Capacity", CalendarAbsenceEntry.Capacity, WrongAbsenceEntryUpdatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShopCalendarWorkingDaysSecondInstanceValidating()
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        ShopCalendarWorkingDays2: Record "Shop Calendar Working Days";
        ShopCalendar: Record "Shop Calendar";
        WorkShift: Record "Work Shift";
    begin
        // [FEATURE] [UT] [Shop Calendar]
        // [SCENARIO 234987] No error occurs when new "Shop Calendar Working Days" fields are validated with old values.
        Initialize();

        LibraryManufacturing.CreateShopCalendarCode(ShopCalendar);
        LibraryManufacturing.CreateWorkShiftCode(WorkShift);

        // [GIVEN] The record of the "Shop Calendar Working Days" table
        LibraryManufacturing.CreateShopCalendarWorkingDays(ShopCalendarWorkingDays, ShopCalendar.Code, 0, WorkShift.Code, 080000T, 160000T);

        // [WHEN] Sequentially validate the fields of the new record one by one with values of the fields of the old record
        ShopCalendarWorkingDays2.Validate("Shop Calendar Code", ShopCalendarWorkingDays."Shop Calendar Code");
        ShopCalendarWorkingDays2.Validate("Work Shift Code", ShopCalendarWorkingDays."Work Shift Code");
        ShopCalendarWorkingDays2.Validate(Day, ShopCalendarWorkingDays.Day);
        ShopCalendarWorkingDays2.Validate("Starting Time", ShopCalendarWorkingDays."Starting Time");
        ShopCalendarWorkingDays2.Validate("Ending Time", ShopCalendarWorkingDays."Ending Time");

        // [THEN] No error occurs
    end;

    [Test]
    procedure ClearGlobalVarsInSingleInstanceShopCalendarMgtOnModifyRecord()
    var
        WorkCenter: Record "Work Center";
        CapUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        // [FEATURE] [Shop Calendar] [UT]
        // [SCENARIO 451879] Clear global record variables in the single instance Shop Calendar Mgt. when these records are modified.
        Initialize();

        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapUnitOfMeasure, CapUnitOfMeasure.Type::Seconds);
        WorkCenter.Validate("Unit of Measure Code", CapUnitOfMeasure.Code);
        WorkCenter.Modify(true);

        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapUnitOfMeasure, CapUnitOfMeasure.Type::Minutes);

        Assert.AreEqual(60, CalendarMgt.QtyperTimeUnitofMeasure(WorkCenter."No.", CapUnitOfMeasure.Code), '');

        CapUnitOfMeasure.Validate(Type, CapUnitOfMeasure.Type::Hours);
        CapUnitOfMeasure.Modify(true);

        Assert.AreEqual(3600, CalendarMgt.QtyperTimeUnitofMeasure(WorkCenter."No.", CapUnitOfMeasure.Code), '');

        WorkCenter.Validate("Unit of Measure Code", CapUnitOfMeasure.Code);
        WorkCenter.Modify(true);

        Assert.AreEqual(1, CalendarMgt.QtyperTimeUnitofMeasure(WorkCenter."No.", CapUnitOfMeasure.Code), '');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Manuf Calendars");
        LibraryVariableStorage.Clear();
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Manuf Calendars");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        CalendarMgt.ClearInternals(); // clear single instance codeunit vars to avoid influence of other test codeunits
        Commit();

        Initialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Manuf Calendars");
    end;

    local procedure CalcTimeShift(BaseTime: Time; ShiftHours: Decimal): Time
    begin
        exit(BaseTime + HoursToMilliseconds(ShiftHours));
    end;

    local procedure CertifyRouting(var RoutingHeader: Record "Routing Header")
    begin
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateAbsenceEntry(var CalendarAbsenceEntry: Record "Calendar Absence Entry"; MachineCenterNo: Code[20]; AbsentCapacity: Decimal; AbsenceDate: Date; StartingTime: Time; EndingTime: Time)
    begin
        CalendarAbsenceEntry.Init();
        CalendarAbsenceEntry.Validate("Capacity Type", CalendarAbsenceEntry."Capacity Type"::"Machine Center");
        CalendarAbsenceEntry.Validate("No.", MachineCenterNo);
        CalendarAbsenceEntry.Validate(Date, AbsenceDate);
        CalendarAbsenceEntry.Validate("Starting Time", StartingTime);
        CalendarAbsenceEntry.Validate("Ending Time", EndingTime);
        CalendarAbsenceEntry.Validate(Capacity, AbsentCapacity);
        CalendarAbsenceEntry.Insert(true);
    end;

    local procedure CreateAndUpdateMachineCenterAbsence(var CalendarAbsenceEntry: Record "Calendar Absence Entry"; MachineCenterNo: Code[20]; AbsenceCapacity: Decimal; AbsenceTimeStartShift: Decimal; AbsenceTimeEndShift: Decimal)
    var
        CalendarAbsenceMgt: Codeunit "Calendar Absence Management";
    begin
        CreateMachineCenterAbsence(CalendarAbsenceEntry, MachineCenterNo, AbsenceCapacity, AbsenceTimeStartShift, AbsenceTimeEndShift);
        CalendarAbsenceMgt.UpdateAbsence(CalendarAbsenceEntry);
    end;

    local procedure CreateItemWithRouting(var Item: Record Item; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Standard, LibraryPatterns.RandCost(Item));
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateMachineCenterAbsence(var CalAbsenceEntry: Record "Calendar Absence Entry"; MachineCenterNo: Code[20]; AbsentCapacity: Decimal; AbsenceTimeStartShift: Decimal; AbsenceTimeEndShift: Decimal)
    var
        WorkStartingTime: Time;
    begin
        WorkStartingTime := GetWorkStartingTime(MachineCenterNo);
        CreateAbsenceEntry(
          CalAbsenceEntry, MachineCenterNo, AbsentCapacity, WorkDate(), CalcTimeShift(WorkStartingTime, AbsenceTimeStartShift),
          CalcTimeShift(WorkStartingTime, AbsenceTimeEndShift));
    end;

    local procedure CreateMachineCenterCalculateCalendar(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20]; MachCenterCapacity: Decimal; MachCenterEfficiency: Decimal; StartingDate: Date; EndingDate: Date)
    begin
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenterNo, MachCenterCapacity);
        MachineCenter.Validate(Efficiency, MachCenterEfficiency);
        MachineCenter.Modify(true);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, StartingDate, EndingDate);
    end;

    local procedure CreateMachineCenterWithHolidays(var MachineCenter: Record "Machine Center"; MachCenterCapacity: Decimal; MachCenterEfficiency: Decimal; StartingDate: Date; EndingDate: Date)
    var
        WorkCenter: Record "Work Center";
    begin
        CreateWorkCenter(WorkCenter);
        CreateMachineCenterCalculateCalendar(
          MachineCenter, WorkCenter."No.", MachCenterCapacity, MachCenterEfficiency, StartingDate, EndingDate);
    end;

    local procedure CreateMachineCenterWithoutHolidays(var MachineCenter: Record "Machine Center"; MachCenterCapacity: Decimal; MachCenterEfficiency: Decimal; StartingDate: Date; EndingDate: Date)
    var
        WorkCenter: Record "Work Center";
    begin
        CreateWorkCenterWithoutHolidays(WorkCenter);
        CreateMachineCenterCalculateCalendar(
          MachineCenter, WorkCenter."No.", MachCenterCapacity, MachCenterEfficiency, StartingDate, EndingDate);
    end;

    local procedure CreateRouting(var RoutingHeader: Record "Routing Header"; var RoutingLine: Record "Routing Line"; MachineCenterNo: Code[20]; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal; MoveTime: Decimal)
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"),
          RoutingLine.Type::"Machine Center", MachineCenterNo);

        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Validate("Wait Time", WaitTime);
        RoutingLine.Validate("Move Time", MoveTime);
        RoutingLine.Modify(true);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
    end;

    local procedure CreateWorkCenterWithoutHolidays(var WorkCenter: Record "Work Center")
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
    begin
        CreateWorkCenter(WorkCenter);
        ShopCalendarWorkingDays.SetRange("Shop Calendar Code", WorkCenter."Shop Calendar Code");
        ShopCalendarWorkingDays.FindFirst();

        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarWorkingDays."Shop Calendar Code", ShopCalendarWorkingDays.Day::Saturday, ShopCalendarWorkingDays."Work Shift Code", ShopCalendarWorkingDays."Starting Time", ShopCalendarWorkingDays."Ending Time");
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarWorkingDays."Shop Calendar Code", ShopCalendarWorkingDays.Day::Sunday, ShopCalendarWorkingDays."Work Shift Code", ShopCalendarWorkingDays."Starting Time", ShopCalendarWorkingDays."Ending Time");
    end;

    local procedure CreateTime(Hour: Integer; "Min": Integer; Sec: Integer) Result: Time
    begin
        Evaluate(
          Result,
          Format(Hour, 0, '<Integer,2><Filler Character,0>') +
          Format(Min, 0, '<Integer,2><Filler Character,0>') +
          Format(Sec, 0, '<Integer,2><Filler Character,0>'));
    end;

    local procedure DateFilterOnWorkCenter(var WorkCenter: Record "Work Center"; MatrixRecords: Record Date)
    begin
        if MatrixRecords."Period Start" = MatrixRecords."Period End" then
            WorkCenter.SetRange("Date Filter", MatrixRecords."Period Start")
        else
            WorkCenter.SetRange("Date Filter", MatrixRecords."Period Start", MatrixRecords."Period End");
        WorkCenter.CalcFields("Capacity (Effective)");
    end;

    local procedure DateFilterOnMachineCenter(var MachineCenter: Record "Machine Center"; MatrixRecords: Record Date)
    begin
        if MatrixRecords."Period Start" = MatrixRecords."Period End" then
            MachineCenter.SetRange("Date Filter", MatrixRecords."Period Start")
        else
            MachineCenter.SetRange("Date Filter", MatrixRecords."Period Start", MatrixRecords."Period End");
        MachineCenter.CalcFields("Capacity (Effective)");
    end;

    local procedure CalculateCapacityEffective(WorkCenterGroupCode: Code[10]; MatrixRecords: Record Date; CapacityUnitOfMeasureCode: Code[10]) CapacityEffective: Decimal
    var
        WorkCenter: Record "Work Center";
        CalendarManagement: Codeunit "Shop Calendar Management";
    begin
        WorkCenter.SetRange("Work Center Group Code", WorkCenterGroupCode);
        WorkCenter.FindSet();
        repeat
            DateFilterOnWorkCenter(WorkCenter, MatrixRecords);
            CapacityEffective +=
              WorkCenter."Capacity (Effective)" *
              CalendarManagement.TimeFactor(WorkCenter."Unit of Measure Code") / CalendarManagement.TimeFactor(CapacityUnitOfMeasureCode);
        until WorkCenter.Next() = 0;
    end;

    local procedure EnqueueAbsenceEntry(CalendarAbsenceEntry: Record "Calendar Absence Entry")
    begin
        LibraryVariableStorage.Enqueue(CalendarAbsenceEntry."No.");
        LibraryVariableStorage.Enqueue(CalendarAbsenceEntry.Date);
        LibraryVariableStorage.Enqueue(CalendarAbsenceEntry."Starting Time");
        LibraryVariableStorage.Enqueue(CalendarAbsenceEntry."Ending Time");
    end;

    local procedure FindCalendarEntry(var CalendarEntry: Record "Calendar Entry"; CalendarAbsenceEntry: Record "Calendar Absence Entry")
    begin
        CalendarEntry.SetRange("Capacity Type", CalendarEntry."Capacity Type"::"Machine Center");
        CalendarEntry.SetRange("No.", CalendarAbsenceEntry."No.");
        CalendarEntry.SetRange(Date, CalendarAbsenceEntry.Date);
        CalendarEntry.SetRange("Starting Time", CalendarAbsenceEntry."Starting Time");
        CalendarEntry.FindFirst();
    end;

    local procedure FindCapacityUnitOfMeasure(var CapacityUnitOfMeasure: Record "Capacity Unit of Measure"; Type: Enum "Capacity Unit of Measure")
    begin
        CapacityUnitOfMeasure.SetRange(Type, Type);
        CapacityUnitOfMeasure.FindFirst();
    end;

    local procedure FindFirstWorkDay(var ShopCalendarWorkingDays: Record "Shop Calendar Working Days"; MachineCenterNo: Code[20])
    begin
        ShopCalendarWorkingDays.SetRange("Shop Calendar Code", GetMachineCenterShopCalendar(MachineCenterNo));
        ShopCalendarWorkingDays.FindFirst();
    end;

    local procedure GetMachineCenterShopCalendar(MachineCenterNo: Code[20]): Code[10]
    var
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
    begin
        MachineCenter.Get(MachineCenterNo);
        WorkCenter.Get(MachineCenter."Work Center No.");
        exit(WorkCenter."Shop Calendar Code");
    end;

    local procedure GetMonth(Month: Integer; SignFactor: Integer) NewDate: Date
    begin
        NewDate := CalcDate('<' + Format(SignFactor * Month) + 'M>', WorkDate());
    end;

    local procedure GetYear(Year: Integer; SignFactor: Integer) NewDate: Date
    begin
        NewDate := CalcDate('<' + Format(SignFactor * Year) + 'Y>', WorkDate());
    end;

    local procedure GetWorkStartingTime(MachineCenterNo: Code[20]): Time
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
    begin
        FindFirstWorkDay(ShopCalendarWorkingDays, MachineCenterNo);
        exit(ShopCalendarWorkingDays."Starting Time");
    end;

    local procedure HoursToMilliseconds(Hours: Decimal): Decimal
    begin
        exit(Hours * 60 * 60 * 1000);
    end;

    local procedure RunUpdateAbsenceAction(CalendarAbsenceEntry: Record "Calendar Absence Entry")
    var
        MachineCenterPage: TestPage "Machine Center Card";
    begin
        MachineCenterPage.OpenView();
        MachineCenterPage.GotoKey(CalendarAbsenceEntry."No.");

        EnqueueAbsenceEntry(CalendarAbsenceEntry);
        MachineCenterPage."A&bsence".Invoke();
    end;

    local procedure CleanupCalendarEntry(WorkCenterNo: Code[20])
    var
        CalendarEntry: Record "Calendar Entry";
    begin
        CalendarEntry.SetFilter("Work Center No.", WorkCenterNo);
        CalendarEntry.DeleteAll(true);
    end;

    local procedure VerifyProductionOrder(var ProductionOrder: Record "Production Order")
    begin
        VerifyProdOrderStartingTime(ProductionOrder);
        VerifyProdOrderLine(ProductionOrder);
        VerifyProdOrderRouting(ProductionOrder);
        VerifyProdOrderCapacityNeed(ProductionOrder);
    end;

    local procedure VerifyProdOrderStartingTime(ProductionOrder: Record "Production Order")
    begin
        Assert.AreEqual(090700T, ProductionOrder."Starting Time", StrSubstNo(WrongFieldValueErr, ProductionOrder.FieldName("Starting Time"), ProductionOrder.TableName));
    end;

    local procedure VerifyProdOrderLine(ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.AreEqual(1, ProdOrderLine.Count, StrSubstNo(WrongNoOfLinesErr, ProdOrderLine.TableName));

        ProdOrderLine.FindFirst();
        Assert.AreEqual(CalcDate('<-2D>', ProdOrderLine."Due Date"), ProdOrderLine."Ending Date", StrSubstNo(WrongFieldValueErr, ProdOrderLine.FieldName("Ending Date"), ProdOrderLine.TableName));
        Assert.AreEqual(160000T, ProdOrderLine."Ending Time", StrSubstNo(WrongFieldValueErr, ProdOrderLine.FieldName("Ending Time"), ProdOrderLine.TableName));
        Assert.AreEqual(
          CalcDate('<-4D>', ProdOrderLine."Due Date"), ProdOrderLine."Starting Date", StrSubstNo(WrongFieldValueErr, ProdOrderLine.FieldName("Starting Date"), ProdOrderLine.TableName));
        Assert.AreEqual(090700T, ProdOrderLine."Starting Time", StrSubstNo(WrongFieldValueErr, ProdOrderLine.FieldName("Starting Time"), ProdOrderLine.TableName));
    end;

    local procedure VerifyProdOrderRouting(ProductionOrder: Record "Production Order")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.AreEqual(
          CalcDate('<-2D>', ProductionOrder."Due Date"),
          ProdOrderRoutingLine."Ending Date", StrSubstNo(WrongFieldValueErr, ProdOrderRoutingLine.FieldName("Ending Date"), ProdOrderRoutingLine.TableName));
        Assert.AreEqual(160000T, ProdOrderRoutingLine."Ending Time", StrSubstNo(WrongFieldValueErr, ProdOrderRoutingLine.FieldName("Ending Time"), ProdOrderRoutingLine.TableName));
        Assert.AreEqual(
          CalcDate('<-4D>', ProductionOrder."Due Date"),
          ProdOrderRoutingLine."Starting Date", StrSubstNo(WrongFieldValueErr, ProdOrderRoutingLine.FieldName("Starting Date"), ProdOrderRoutingLine.TableName));
        Assert.AreEqual(090700T, ProdOrderRoutingLine."Starting Time", StrSubstNo(WrongFieldValueErr, ProdOrderRoutingLine.FieldName("Starting Time"), ProdOrderRoutingLine.TableName));
    end;

    local procedure VerifyProdOrderCapacityNeed(ProductionOrder: Record "Production Order")
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeed.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.", "Operation No.", Date, "Starting Time");
        ProdOrderCapacityNeed.SetRange(Status, ProductionOrder.Status);
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.AreEqual(3, ProdOrderCapacityNeed.Count, StrSubstNo(WrongNoOfLinesErr, ProdOrderCapacityNeed.TableName));

        ProdOrderCapacityNeed.FindSet();
        // Total time required for machine center setup is 60 minutes * 100 / 75 = 80 min. (as MC efficiency is 75%)
        VerifyCapacityLine(090700T, 102700T, ProdOrderCapacityNeed."Time Type"::"Setup Time", 60, ProdOrderCapacityNeed);
        ProdOrderCapacityNeed.Next();
        // Total run time is 60 min. * 10 pcs * 100 / 75 (75% efficiency) = 800 min.
        // Allocated time is 600 minutes, as it does not include efficiency multiplicator
        // Effective run time is 800 minutes
        VerifyCapacityLine(102700T, 160000T, ProdOrderCapacityNeed."Time Type"::"Run Time", 249.75, ProdOrderCapacityNeed);
        ProdOrderCapacityNeed.Next();
        // All times are backward calculated starting from the shift ending time
        // Move time - 13 minutes: 15:47 - 16:00 (efficiency multiplicator is not applied to move time and wait time)
        // Production takes 2 days:
        // Second day: 7 hours 47 minutes (whole work shift time) 08:00 - 15:47, actual allocated time is 467 * 75 / 100 = 350.25 min
        // First day: 5 hours 33 minutes 10:27 - 16:00 (till the end of the shift), allocated time is 333 * 75 / 100 = 249.75 min
        VerifyCapacityLine(080000T, 154700T, ProdOrderCapacityNeed."Time Type"::"Run Time", 350.25, ProdOrderCapacityNeed);
    end;

    local procedure VerifyCapacityLine(ExpStartingTime: Time; ExpEndingTime: Time; ExpTimeType: Enum "Routing Time Type"; ExpAllocatedTime: Decimal; ProdOrderCapacityNeed: Record "Prod. Order Capacity Need")
    begin
        Assert.AreEqual(ExpStartingTime, ProdOrderCapacityNeed."Starting Time", StrSubstNo(WrongFieldValueErr, ProdOrderCapacityNeed.FieldName("Starting Time"), ProdOrderCapacityNeed.TableName));
        Assert.AreEqual(ExpEndingTime, ProdOrderCapacityNeed."Ending Time", StrSubstNo(WrongFieldValueErr, ProdOrderCapacityNeed.FieldName("Ending Time"), ProdOrderCapacityNeed.TableName));
        Assert.AreEqual(ExpTimeType, ProdOrderCapacityNeed."Time Type", StrSubstNo(WrongFieldValueErr, ProdOrderCapacityNeed.FieldName("Time Type"), ProdOrderCapacityNeed.TableName));
        Assert.AreEqual(ExpAllocatedTime, ProdOrderCapacityNeed."Allocated Time", StrSubstNo(WrongFieldValueErr, ProdOrderCapacityNeed.FieldName("Allocated Time"), ProdOrderCapacityNeed.TableName));
    end;

    local procedure VerifyTimeDeltaAndSubtract(Time1: Time; Time2: Time; Expected: Integer)
    begin
        Assert.AreEqual(Expected, CalendarMgt.CalcTimeDelta(Time1, Time2), CalcTimeDeltaErr);
        Assert.AreEqual(Expected, CalendarMgt.CalcTimeSubtract(Time1, Time2 - 000000T) - 000000T, CalcTimeSubtractErr);
    end;

    local procedure OpenWorkCenterCalendarPage(var WorkCenterCalendar: TestPage "Work Center Calendar"; No: Code[20]; PeriodType: Enum "Analysis Period Type")
    var
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // Open Work Center Page and Open Work Center Calendar. Update Period Type.
        WorkCenterCard.OpenEdit();
        WorkCenterCard.FILTER.SetFilter("No.", No);
        WorkCenterCalendar.Trap();
        WorkCenterCard."&Calendar".Invoke();
        WorkCenterCalendar.PeriodType.SetValue(PeriodType);
    end;

    local procedure OpenWorkCenterGroupCalendarPage(var WorkCtrGroupCalendar: TestPage "Work Ctr. Group Calendar"; WorkCenterGroupCode: Code[20]; PeriodType: Enum "Analysis Period Type"; CapacityUOM: Code[10])
    var
        WorkCenterGroups: TestPage "Work Center Groups";
    begin
        // Open Work Center Group Page and Open Work Center Group Calendar. Update Period Type and Capacity Unit of Measure.
        WorkCenterGroups.OpenEdit();
        WorkCenterGroups.FILTER.SetFilter(Code, WorkCenterGroupCode);
        WorkCtrGroupCalendar.Trap();
        WorkCenterGroups.Calendar.Invoke();
        WorkCtrGroupCalendar.PeriodType.SetValue(PeriodType);
        WorkCtrGroupCalendar.CapacityUoM.SetValue(CapacityUOM);
    end;

    local procedure OpenMachineCenterCalendarPage(var MachineCenterCalendar: TestPage "Machine Center Calendar"; No: Code[20]; PeriodType: Enum "Analysis Period Type")
    var
        MachineCenterCard: TestPage "Machine Center Card";
    begin
        // Open Machine Center Page and Open Machine Center Calendar. Update Period Type.
        MachineCenterCard.OpenEdit();
        MachineCenterCard.FILTER.SetFilter("No.", No);
        MachineCenterCalendar.Trap();
        MachineCenterCard."&Calendar".Invoke();
        MachineCenterCalendar.PeriodType.SetValue(PeriodType);
    end;

    local procedure UpdateRoutingTimesUOM(var RoutingLine: Record "Routing Line")
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        FindCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::Hours);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Wait Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WorkCenterCalendarMatrixPageHandler(var WorkCenterCalendarMatrix: TestPage "Work Center Calendar Matrix")
    begin
        // Verify Work Center Calendar Matrix Page.
        WorkCenterCalendarMatrix.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), WorkCenterCalendarMatrix.Field1.Caption, CaptionError);
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), WorkCenterCalendarMatrix.Field2.Caption, CaptionError);
        WorkCenterCalendarMatrix.Field1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        WorkCenterCalendarMatrix.Field2.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WorkCenterGroupCalendarMatrixPageHandler(var WorkCtrGrpCalendarMatrix: TestPage "Work Ctr. Grp. Calendar Matrix")
    begin
        // Verify Work Center Group Calendar Matrix Page.
        WorkCtrGrpCalendarMatrix.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), WorkCtrGrpCalendarMatrix.Field1.Caption, CaptionError);
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), WorkCtrGrpCalendarMatrix.Field2.Caption, CaptionError);
        WorkCtrGrpCalendarMatrix.Field1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        WorkCtrGrpCalendarMatrix.Field2.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MachineCenterCalendarMatrixPageHandler(var MachineCenterCalendarMatrix: TestPage "Machine Center Calendar Matrix")
    begin
        // Verify Machine Center Calendar Matrix Page.
        MachineCenterCalendarMatrix.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), MachineCenterCalendarMatrix.Field1.Caption, CaptionError);
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), MachineCenterCalendarMatrix.Field2.Caption, CaptionError);
        MachineCenterCalendarMatrix.Field1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        MachineCenterCalendarMatrix.Field2.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AbsencePageHandler(var AbsencePage: TestPage "Capacity Absence")
    var
        QueuedVar: Variant;
        MachineCenterNo: Code[20];
        AbsenceDate: Date;
        AbsenceStartingTime: Time;
        AbsenceEndingTime: Time;
    begin
        LibraryVariableStorage.Dequeue(QueuedVar);
        MachineCenterNo := QueuedVar;
        AbsenceDate := LibraryVariableStorage.DequeueDate();
        AbsenceStartingTime := LibraryVariableStorage.DequeueTime();
        AbsenceEndingTime := LibraryVariableStorage.DequeueTime();

        AbsencePage.GotoKey(1, MachineCenterNo, AbsenceDate, AbsenceStartingTime, AbsenceEndingTime);
        AbsencePage.Update.Invoke();
    end;
}

