codeunit 119011 "Create Shop Calendar"
{

    trigger OnRun()
    begin
        InsertData('1', XOneshiftMondayFriday);
        InsertData('2', XTwoshiftsMondayFriday);
    end;

    var
        XOneshiftMondayFriday: Label 'One shift Monday-Friday';
        XTwoshiftsMondayFriday: Label 'Two shifts Monday-Friday';

    procedure InsertData("Code": Code[10]; Name: Text[50])
    var
        ShopCalendar: Record "Shop Calendar";
    begin
        ShopCalendar.Validate(Code, Code);
        ShopCalendar.Validate(Description, Name);
        ShopCalendar.Insert();
    end;
}

