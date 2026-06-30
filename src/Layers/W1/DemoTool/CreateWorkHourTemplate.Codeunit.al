codeunit 117055 "Create Work-Hour Template"
{

    trigger OnRun()
    begin
        InsertData(X30HWEEK, X30hoursweek, 6, 6, 6, 6, 6, 0, 0, 30);
        InsertData(X36HWEEK, X36hoursweek, 8, 8, 8, 8, 4, 0, 0, 36);
        InsertData(X40HWEEK, X40hoursweek, 8, 8, 8, 8, 8, 0, 0, 40);
    end;

    var
        X30HWEEK: Label '30HWEEK';
        X30hoursweek: Label '30 hours week';
        X36HWEEK: Label '36HWEEK';
        X36hoursweek: Label '36 hours week';
        X40HWEEK: Label '40HWEEK';
        X40hoursweek: Label '40 hours week';

    procedure InsertData("Code": Text[250]; Description: Text[250]; Monday: Decimal; Tuesday: Decimal; Wednesday: Decimal; Thursday: Decimal; Friday: Decimal; Saturday: Decimal; Sunday: Decimal; "Total per Week": Decimal)
    var
        WorkHourTemplate: Record "Work-Hour Template";
    begin
        WorkHourTemplate.Init();
        WorkHourTemplate.Validate(Code, Code);
        WorkHourTemplate.Validate(Description, Description);
        WorkHourTemplate.Validate(Monday, Monday);
        WorkHourTemplate.Validate(Tuesday, Tuesday);
        WorkHourTemplate.Validate(Wednesday, Wednesday);
        WorkHourTemplate.Validate(Thursday, Thursday);
        WorkHourTemplate.Validate(Friday, Friday);
        WorkHourTemplate.Validate(Saturday, Saturday);
        WorkHourTemplate.Validate(Sunday, Sunday);
        WorkHourTemplate.Validate("Total per Week", "Total per Week");
        WorkHourTemplate.Insert(true);
    end;
}

