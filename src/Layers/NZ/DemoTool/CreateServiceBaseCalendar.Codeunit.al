codeunit 117507 "Create Service Base Calendar"
{

    trigger OnRun()
    begin
        BaseCalChange.DeleteAll();
        BaseCalendar.DeleteAll();

        DemoDataSetup.Get();

        InsertRec(XSERVICE, XServiceCalendar);
        InsertRec(XAustralia, XAustraliaBaseNatCalendar);
        InsertRec(XNZ, XNewZealandBaseNatCalendar);

        InsertBaseCalChange(
          XSERVICE, BaseCalChange."Recurring System"::"Weekly Recurring", BaseCalChange.Day::Saturday, true,
          DateToDMY(0D), '');
        InsertBaseCalChange(
          XSERVICE, BaseCalChange."Recurring System"::"Weekly Recurring", BaseCalChange.Day::Sunday, true,
          DateToDMY(0D), '');

        InsertBaseCalChange(
          DemoDataSetup."Country/Region Code", BaseCalChange."Recurring System"::"Weekly Recurring", BaseCalChange.Day::Saturday, true,
          DateToDMY(0D), XWeekend);
        InsertBaseCalChange(
          DemoDataSetup."Country/Region Code", BaseCalChange."Recurring System"::"Weekly Recurring", BaseCalChange.Day::Sunday, true,
          DateToDMY(0D), XWeekend);

        InsertBaseCalChange(
          DemoDataSetup."Country/Region Code", BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(19030101D), XNewYearsEve);
        CheckHolidayDate(DateToDMY(19030101D), XNewYearsEve);

        InsertBaseCalChange(
          DemoDataSetup."Country/Region Code", BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(19030102D), XBankHolidayScotlandOnly);
        CheckHolidayDate(DateToDMY(19030102D), XBankHolidayScotlandOnly);

        InsertBaseCalChange(
          DemoDataSetup."Country/Region Code", BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(19040317D), XStPatricksDay);
        CheckHolidayDate(DateToDMY(19040317D), XStPatricksDay);

        InsertBaseCalChange(
          DemoDataSetup."Country/Region Code", BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(19030712D), XBattleoftheBoyneDay);
        CheckHolidayDate(DateToDMY(19030712D), XBattleoftheBoyneDay);

        InsertBaseCalChange(
          DemoDataSetup."Country/Region Code", BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(19031225D), XChristmasDay);
        CheckHolidayDate(DateToDMY(19031225D), XChristmasDay);

        InsertBaseCalChange(
          DemoDataSetup."Country/Region Code", BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(19031226D), XBoxingDay);
        CheckHolidayDate(DateToDMY(19031226D), XBoxingDay);

        CreateSpecialHolidays();
        CreateAUHolidays();
        CreateNZHolidays();
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
        XAustralia: Label 'Australia';
        XNZ: Label 'NZ';
        XAustraliaBaseNatCalendar: Label 'Australia Base Nat. Calendar';
        XNewZealandBaseNatCalendar: Label 'New Zealand Base Nat. Calendar';
        XNewYearsDay: Label 'New Year''''s Day';
        XDayafterNewYearsDay: Label 'Day after New Year''''s Day';
        XWaitangiDay: Label 'Waitangi Day';
        XGoodFriday: Label 'Good Friday';
        XEasterMonday: Label 'Easter Monday';
        XAnzacDay: Label 'Anzac Day';
        XQueensBirthday: Label 'Queen''''s Birthday';
        XLarborDay: Label 'Larbor Day';

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
              DemoDataSetup."Country/Region Code", BaseCalChange."Recurring System"::" ", BaseCalChange.Day::Monday, true,
              GetPeriodNoOneDate('>'), XMayDayBankHoliday);
            StartDate := CalcDate('<1Y>', StartDate);
        until StartDate = MakeAdjustments.AdjustDate(19100501D);

        StartDate := CalcDate('<-1D>', MakeAdjustments.AdjustDate(19040601D));
        repeat
            InsertBaseCalChange(
              DemoDataSetup."Country/Region Code", BaseCalChange."Recurring System"::" ", BaseCalChange.Day::Monday, true,
              GetPeriodNoOneDate('<'), XBankHoliday);
            StartDate := CalcDate('<1Y>', StartDate);
        until StartDate = CalcDate('<-1D>', MakeAdjustments.AdjustDate(19100601D));

        // -------------------------------------------------------------------
        // My Bank Holiday, First and Last Monday of each Augest is a holiday
        // -------------------------------------------------------------------
        StartDate := MakeAdjustments.AdjustDate(19040801D);
        repeat
            InsertBaseCalChange(
              DemoDataSetup."Country/Region Code", BaseCalChange."Recurring System"::" ", BaseCalChange.Day::Monday, true,
              GetPeriodNoOneDate('>'), XSummerBankHolidayScotland);
            StartDate := CalcDate('<1Y>', StartDate);
        until StartDate = MakeAdjustments.AdjustDate(19100801D);

        StartDate := CalcDate('<-1D>', MakeAdjustments.AdjustDate(19040901D));
        repeat
            InsertBaseCalChange(
              DemoDataSetup."Country/Region Code", BaseCalChange."Recurring System"::" ", BaseCalChange.Day::Monday, true,
              GetPeriodNoOneDate('<'), XSummerBankHoliday);
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
              DemoDataSetup."Country/Region Code", BaseCalChange."Recurring System"::" ", BaseCalChange.Day::Monday, true,
              OriginalDate, OriginalDescription);
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

    procedure CreateAUHolidays()
    begin
        InsertBaseCalChange(
          XAustralia, BaseCalChange."Recurring System"::"Weekly Recurring", BaseCalChange.Day::Saturday, true, 0D, XWeekend);
        InsertBaseCalChange(
          XAustralia, BaseCalChange."Recurring System"::"Weekly Recurring", BaseCalChange.Day::Sunday, true, 0D, XWeekend);
        InsertBaseCalChange(
          XAustralia, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true, 20021225D, XChristmasDay);
        CheckHolidayDate(20021225D, XChristmasDay);
        InsertBaseCalChange(
          XAustralia, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true, 20021226D, XBoxingDay);
        CheckHolidayDate(20021226D, XBoxingDay);
        InsertBaseCalChange(
          XAustralia, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true, 20030101D, XNewYearsDay);
        CheckHolidayDate(20030101D, XNewYearsDay);
        InsertBaseCalChange(
          XAustralia, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true, 20030126D, 'Australia Day');
        CheckHolidayDate(20030126D, 'Australia Day');
        InsertBaseCalChange(
          XAustralia, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20030418D, XGoodFriday);
        CheckHolidayDate(20030418D, XGoodFriday);
        InsertBaseCalChange(
          XAustralia, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20040409D, XGoodFriday);
        CheckHolidayDate(20040409D, XGoodFriday);
        InsertBaseCalChange(
          XAustralia, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20030421D, XEasterMonday);
        CheckHolidayDate(20030421D, XEasterMonday);
        InsertBaseCalChange(
          XAustralia, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20040412D, XEasterMonday);
        CheckHolidayDate(20040412D, XEasterMonday);
        InsertBaseCalChange(
          XAustralia, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true, 20030425D, XAnzacDay);
        CheckHolidayDate(20030425D, XAnzacDay);
        InsertBaseCalChange(
          XAustralia, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20030609D, XQueensBirthday);
        CheckHolidayDate(20030609D, XQueensBirthday);
        InsertBaseCalChange(
          XAustralia, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20040614D, XQueensBirthday);
        CheckHolidayDate(20040614D, XQueensBirthday);
    end;

    procedure CreateNZHolidays()
    begin
        InsertBaseCalChange(
          XNZ, BaseCalChange."Recurring System"::"Weekly Recurring", BaseCalChange.Day::Saturday, true, 0D, XWeekend);
        InsertBaseCalChange(
          XNZ, BaseCalChange."Recurring System"::"Weekly Recurring", BaseCalChange.Day::Sunday, true, 0D, XWeekend);
        InsertBaseCalChange(
          XNZ, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true, 20021225D, XChristmasDay);
        CheckHolidayDate(20021225D, XChristmasDay);
        InsertBaseCalChange(
          XNZ, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true, 20021226D, XBoxingDay);
        CheckHolidayDate(20021226D, XBoxingDay);
        InsertBaseCalChange(
          XNZ, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true, 20030101D, XNewYearsDay);
        CheckHolidayDate(20030101D, XNewYearsDay);
        InsertBaseCalChange(
          XNZ, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true, 20030102D, XDayafterNewYearsDay);
        CheckHolidayDate(20030102D, XDayafterNewYearsDay);
        InsertBaseCalChange(
          XNZ, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true, 20030206D, XWaitangiDay);
        CheckHolidayDate(20030206D, XWaitangiDay);
        InsertBaseCalChange(
          XNZ, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20030418D, XGoodFriday);
        CheckHolidayDate(20030418D, XGoodFriday);
        InsertBaseCalChange(
          XNZ, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20040409D, XGoodFriday);
        CheckHolidayDate(20040409D, XGoodFriday);
        InsertBaseCalChange(
          XNZ, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20030421D, XEasterMonday);
        CheckHolidayDate(20030421D, XEasterMonday);
        InsertBaseCalChange(
          XNZ, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20040412D, XEasterMonday);
        CheckHolidayDate(20040412D, XEasterMonday);
        InsertBaseCalChange(
          XNZ, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true, 20030425D, XAnzacDay);
        CheckHolidayDate(20030425D, XAnzacDay);
        InsertBaseCalChange(
          XNZ, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20030602D, XQueensBirthday);
        CheckHolidayDate(20030602D, XQueensBirthday);
        InsertBaseCalChange(
          XNZ, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20040607D, XQueensBirthday);
        CheckHolidayDate(20040607D, XQueensBirthday);
        InsertBaseCalChange(
          XNZ, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20031027D, XLarborDay);
        CheckHolidayDate(20031027D, XLarborDay);
        InsertBaseCalChange(
          XNZ, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20041025D, XLarborDay);
        CheckHolidayDate(20041025D, XLarborDay);
    end;
}

