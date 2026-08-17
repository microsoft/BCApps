codeunit 119012 "Create Shop Cal. Working Day"
{

    trigger OnRun()
    begin
        InsertData('1', 0, 080000T, 160000T, '1');
        InsertData('1', 1, 080000T, 160000T, '1');
        InsertData('1', 2, 080000T, 160000T, '1');
        InsertData('1', 3, 080000T, 160000T, '1');
        InsertData('1', 4, 080000T, 160000T, '1');
        InsertData('2', 0, 080000T, 230000T, '2');
        InsertData('2', 1, 080000T, 230000T, '2');
        InsertData('2', 2, 080000T, 230000T, '2');
        InsertData('2', 3, 080000T, 230000T, '2');
        InsertData('2', 4, 080000T, 230000T, '2');
    end;

    procedure InsertData(ShopCalendarCode: Code[10]; Day: Option Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday; StartingTime: Time; EndingTime: Time; WorkShiftCode: Code[10])
    var
        ShopCalWorkingDay: Record "Shop Calendar Working Days";
    begin
        ShopCalWorkingDay.Validate("Shop Calendar Code", ShopCalendarCode);
        ShopCalWorkingDay.Validate(Day, Day);
        ShopCalWorkingDay.Validate("Starting Time", StartingTime);
        ShopCalWorkingDay.Validate("Ending Time", EndingTime);
        ShopCalWorkingDay.Validate("Work Shift Code", WorkShiftCode);
        ShopCalWorkingDay.Insert();
    end;
}

