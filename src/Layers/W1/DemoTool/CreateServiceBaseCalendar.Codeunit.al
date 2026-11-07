codeunit 117507 "Create Service Base Calendar"
{

    trigger OnRun()
    begin
        BaseCalChange.DeleteAll();
        BaseCalendar.DeleteAll();

        DemoDataSetup.Get();

        InsertRec(XSERVICE, XServiceCalendar);
        InsertRec(XGB, XGBBaseNationalCalendar);

        InsertBaseCalChange(
          XSERVICE, BaseCalChange."Recurring System"::"Weekly Recurring", BaseCalChange.Day::Saturday, true,
          DateToDMY(0D), '');
        InsertBaseCalChange(
          XSERVICE, BaseCalChange."Recurring System"::"Weekly Recurring", BaseCalChange.Day::Sunday, true,
          DateToDMY(0D), '');

        InsertBaseCalChange(
          XGB, BaseCalChange."Recurring System"::"Weekly Recurring", BaseCalChange.Day::Saturday, true,
          DateToDMY(0D), XWeekend);
        InsertBaseCalChange(
          XGB, BaseCalChange."Recurring System"::"Weekly Recurring", BaseCalChange.Day::Sunday, true,
          DateToDMY(0D), XWeekend);

        InsertBaseCalChange(
          XGB, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(19030101D), XNewYearsEve);
        CheckHolidayDate(DateToDMY(19030101D), XNewYearsEve);

        InsertBaseCalChange(
          XGB, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(19030102D), XBankHolidayScotlandOnly);
        CheckHolidayDate(DateToDMY(19030102D), XBankHolidayScotlandOnly);

        InsertBaseCalChange(
          XGB, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(19040317D), XStPatricksDay);
        CheckHolidayDate(DateToDMY(19040317D), XStPatricksDay);

        InsertBaseCalChange(
          XGB, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(19030712D), XBattleoftheBoyneDay);
        CheckHolidayDate(DateToDMY(19030712D), XBattleoftheBoyneDay);

        InsertBaseCalChange(
          XGB, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(19031225D), XChristmasDay);
        CheckHolidayDate(DateToDMY(19031225D), XChristmasDay);

        InsertBaseCalChange(
          XGB, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(19031226D), XBoxingDay);
        CheckHolidayDate(DateToDMY(19031226D), XBoxingDay);

        CreateSpecialHolidays();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        BaseCalChange: Record "Base Calendar Change";
        BaseCalendar: Record "Base Calendar";
        Date: Record Date;
        MakeAdjustments: Codeunit "Make Adjustments";
        StartDate: Date;
        XSERVICE: Label 'SERVICE';
        XServiceCalendar: Label 'Service Calendar';
        XGB: Label 'GB';
        XGBBaseNationalCalendar: Label 'GB Base National Calendar';
        XWeekend: Label 'Weekend';
        XNewYearsEve: Label 'New Years Eve';
        XBankHolidayScotlandOnly: Label 'Bank Holiday, Scotland Only';
        XStPatricksDay: Label 'St Patricks Day';
        XBattleoftheBoyneDay: Label 'Battle of the Boyne Day';
        XChristmasDay: Label 'Christmas Day';
        XBoxingDay: Label 'Boxing Day';
        XMayDayBankHoliday: Label 'May Day Bank Holiday';
        XBankHoliday: Label 'Bank Holiday';
        XSummerBankHolidayScotland: Label 'Summer Bank Holiday, Scotland';
        XSummerBankHoliday: Label 'Summer Bank Holiday';

    procedure InsertRec("Code": Code[10]; Name: Text[30])
    begin
        BaseCalendar.Init();
        BaseCalendar.Code := Code;
        BaseCalendar.Name := Name;
        BaseCalendar.Insert();
    end;

    procedure InsertBaseCalChange("Code": Code[10]; "Recurring System": Option; Day: Option; Nonworking: Boolean; Date: Date; Description: Text[30])
    begin
        BaseCalChange.Init();
        BaseCalChange."Base Calendar Code" := Code;
        BaseCalChange."Recurring System" := "Recurring System";
        BaseCalChange.Day := Day;
        BaseCalChange.Nonworking := Nonworking;
        BaseCalChange.Date := Date;
        BaseCalChange.Description := Description;
        if BaseCalChange.Insert() then;
    end;

    procedure CreateSpecialHolidays()
    begin
        // ----------------------------------------------------------------
        // My Bank Holiday, First and Last Monday of each May is a holiday
        // ----------------------------------------------------------------
        StartDate := MakeAdjustments.AdjustDate(19040501D);
        repeat
            InsertBaseCalChange(
              XGB, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::Monday, true, GetPeriodNoOneDate('>'), XMayDayBankHoliday);
            StartDate := CalcDate('<1Y>', StartDate);
        until StartDate = MakeAdjustments.AdjustDate(19100501D);

        StartDate := CalcDate('<-1D>', MakeAdjustments.AdjustDate(19040601D));
        repeat
            InsertBaseCalChange(
              XGB, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::Monday, true, GetPeriodNoOneDate('<'), XBankHoliday);
            StartDate := CalcDate('<1Y>', StartDate);
        until StartDate = CalcDate('<-1D>', MakeAdjustments.AdjustDate(19100601D));

        // -------------------------------------------------------------------
        // My Bank Holiday, First and Last Monday of each Augest is a holiday
        // -------------------------------------------------------------------
        StartDate := MakeAdjustments.AdjustDate(19040801D);
        repeat
            InsertBaseCalChange(
              XGB, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::Monday, true, GetPeriodNoOneDate('>'),
              XSummerBankHolidayScotland);
            StartDate := CalcDate('<1Y>', StartDate);
        until StartDate = MakeAdjustments.AdjustDate(19100801D);

        StartDate := CalcDate('<-1D>', MakeAdjustments.AdjustDate(19040901D));
        repeat
            InsertBaseCalChange(
              XGB, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::Monday, true, GetPeriodNoOneDate('<'), XSummerBankHoliday);
            StartDate := CalcDate('<1Y>', StartDate);
        until StartDate = CalcDate('<-1D>', MakeAdjustments.AdjustDate(19100901D))
    end;

    procedure GetPeriodNoOneDate(SkipDirection: Text[1]): Date
    begin
        Date.Get(Date."Period Type"::Date, StartDate);
        if Date."Period No." <> 1 then
            repeat
                Date.Find(SkipDirection);
            until Date."Period No." = 1;
        exit(Date."Period Start");
    end;

    procedure CheckHolidayDate(OriginalDate: Date; OriginalDescription: Text[30])
    begin
        Date.Get(Date."Period Type"::Date, OriginalDate);
        if (Date."Period No." = 6) or (Date."Period No." = 7) then begin
            OriginalDate := OriginalDate + 7 - Date."Period No." + 1;
            InsertBaseCalChange(
              XGB, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::Monday, true, OriginalDate, OriginalDescription);
        end;
    end;

    procedure DateToDMY(HolidayDate: Date): Date
    var
        MonthDay: Integer;
        Month: Integer;
    begin
        if HolidayDate = 0D then
            exit(0D);

        MonthDay := Date2DMY(HolidayDate, 1);
        Month := Date2DMY(HolidayDate, 2);
        exit(DMY2Date(MonthDay, Month, (Date2DMY(HolidayDate, 3) + DemoDataSetup."Starting Year" - 2)));
    end;
}

