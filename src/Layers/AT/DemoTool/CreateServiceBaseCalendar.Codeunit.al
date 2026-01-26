codeunit 117507 "Create Service Base Calendar"
{

    trigger OnRun()
    begin
        BaseCalChange.DeleteAll();
        BaseCalendar.DeleteAll();

        DemoDataSetup.Get();

        InsertRec(XSERVICE, XServiceCalendar);
        InsertRec(XAT, XATBaseNationalCalendar);

        InsertBaseCalChange(
          XSERVICE, BaseCalChange."Recurring System"::"Weekly Recurring", BaseCalChange.Day::Saturday, true,
          DateToDMY(0D), '');
        InsertBaseCalChange(
          XSERVICE, BaseCalChange."Recurring System"::"Weekly Recurring", BaseCalChange.Day::Sunday, true,
          DateToDMY(0D), '');

        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::"Weekly Recurring", BaseCalChange.Day::Saturday, true,
          DateToDMY(0D), XWeekend);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::"Weekly Recurring", BaseCalChange.Day::Sunday, true,
          DateToDMY(0D), XWeekend);

        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(00031231D), XNewYearsEve);

        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(00030101D), XNewYearsDay);

        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(00030106D), XEpiphany);

        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(00030501D), XLaborDay);

        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(00030815D), XMarysAscension);

        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(00031026D), XNationalHoliday);

        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(00031101D), XAllSaintsDay);

        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(00031102D), XAllSoulsDay);

        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(00031208D), XImmaculateConception);

        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(00031224D), XChristmasEve);

        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(00031225D), XChristmasDay);

        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::"Annual Recurring", BaseCalChange.Day::" ", true,
          DateToDMY(00031226D), XBoxingDay);

        CreateSpecialHolidays();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        BaseCalChange: Record "Base Calendar Change";
        BaseCalendar: Record "Base Calendar";
        Date: Record Date;
        StartDate: Date;
        XSERVICE: Label 'SERVICE';
        XServiceCalendar: Label 'Service Calendar';
        XWeekend: Label 'Weekend';
        XNewYearsEve: Label 'New Years Eve';
        XChristmasDay: Label 'Christmas Day';
        XBoxingDay: Label 'Boxing Day';
        XAT: Label 'AT';
        XATBaseNationalCalendar: Label 'AT Base National Calendar';
        XNewYearsDay: Label 'New Year''s Day';
        XEpiphany: Label 'Epiphany';
        XLaborDay: Label 'Labor Day';
        XMarysAscension: Label 'Mary''s Ascension';
        XNationalHoliday: Label 'National Holiday';
        XAllSaintsDay: Label 'All Saints Day';
        XAllSoulsDay: Label 'All Souls Day';
        XImmaculateConception: Label 'Immaculate Conception';
        XChristmasEve: Label 'Christmas Eve';
        XEasterSunday: Label 'Easter Sunday';
        XEasterMonday: Label 'Easter Monday';
        XAscensionDay: Label 'Ascension Day';
        XPentecost: Label 'Pentecost';
        XWhitMonday: Label 'Whit Monday';
        XCorpusChristi: Label 'Corpus Christi';

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
        //----------------------------------------------------------------
        //My Bank Holiday, First and Last Monday of each May is a holiday
        //----------------------------------------------------------------


        //-------------------------------------------------------------------
        //My Bank Holiday, First and Last Monday of each Augest is a holiday
        //-------------------------------------------------------------------

        //-------------------------------------------------------------------
        //-------------------------------------------------------------------
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20010415D, XEasterSunday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20010416D, XEasterMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20020331D, XEasterSunday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20020401D, XEasterMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20030420D, XEasterSunday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20030421D, XEasterMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20040411D, XEasterSunday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20040412D, XEasterMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20050327D, XEasterSunday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20050328D, XEasterMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20060416D, XEasterSunday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20060417D, XEasterMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20070408D, XEasterSunday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20070409D, XEasterMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20080323D, XEasterSunday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20080324D, XEasterMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20090412D, XEasterSunday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20090413D, XEasterMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20100404D, XEasterSunday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20100405D, XEasterMonday);

        //-------------------------------------------------------------------
        // Ascension Day 2001..2006
        //-------------------------------------------------------------------
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20010524D, XAscensionDay);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20020509D, XAscensionDay);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20030529D, XAscensionDay);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20040520D, XAscensionDay);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20050505D, XAscensionDay);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20060525D, XAscensionDay);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20070517D, XAscensionDay);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20080501D, XAscensionDay);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20090521D, XAscensionDay);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20100513D, XAscensionDay);

        //-------------------------------------------------------------------
        // Pentecost/Whit Monday 2001..2006
        //-------------------------------------------------------------------
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20010603D, XPentecost);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20010604D, XWhitMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20020519D, XPentecost);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20020520D, XWhitMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20030608D, XPentecost);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20030609D, XWhitMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20040530D, XPentecost);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20040531D, XWhitMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20050515D, XPentecost);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20050516D, XWhitMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20060604D, XPentecost);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20060605D, XWhitMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20070527D, XPentecost);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20070528D, XWhitMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20080511D, XPentecost);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20080512D, XWhitMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20090531D, XPentecost);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20090601D, XWhitMonday);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20100523D, XPentecost);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20100524D, XWhitMonday);

        //-------------------------------------------------------------------
        // Corpus Christi 2001..2006
        //-------------------------------------------------------------------
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20010614D, XCorpusChristi);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20020530D, XCorpusChristi);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20030619D, XCorpusChristi);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20040610D, XCorpusChristi);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20050526D, XCorpusChristi);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20060615D, XCorpusChristi);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20070607D, XCorpusChristi);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20080522D, XCorpusChristi);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20090611D, XCorpusChristi);
        InsertBaseCalChange(
          XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::" ", true, 20100603D, XCorpusChristi);
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
              XAT, BaseCalChange."Recurring System"::" ", BaseCalChange.Day::Monday, true, OriginalDate, OriginalDescription);
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

