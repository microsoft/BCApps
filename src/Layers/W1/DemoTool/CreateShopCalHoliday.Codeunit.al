codeunit 119013 "Create Shop Cal. Holiday"
{

    trigger OnRun()
    begin
    end;

    procedure InsertData(ShopCalendarCode: Code[10]; Date: Date; StartingTime: Time; EndingTime: Time; Description: Text[30])
    var
        ShopCalHoliday: Record "Shop Calendar Holiday";
    begin
        ShopCalHoliday.Validate("Shop Calendar Code", ShopCalendarCode);
        ShopCalHoliday.Validate(Date, Date);
        ShopCalHoliday.Validate("Starting Time", StartingTime);
        ShopCalHoliday.Validate("Ending Time", EndingTime);
        ShopCalHoliday.Validate(Description, Description);
        ShopCalHoliday.Insert();
    end;
}

