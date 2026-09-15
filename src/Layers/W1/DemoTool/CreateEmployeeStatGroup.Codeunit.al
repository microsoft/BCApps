codeunit 101610 "Create Employee Stat. Group"
{

    trigger OnRun()
    begin
        InsertData(XMONTH, XSalariedMonthly);
        InsertData(X14DAYS, XSalariedTwiceMonthly);
        InsertData(XHOUR, XHourlyWages);
    end;

    var
        EmployeeStatisticsGroup: Record "Employee Statistics Group";
        XMONTH: Label 'MONTH';
        XSalariedMonthly: Label 'Salaried (Monthly)';
        X14DAYS: Label '14DAYS';
        XSalariedTwiceMonthly: Label 'Salaried (Twice Monthly)';
        XHOUR: Label 'HOUR';
        XHourlyWages: Label 'Hourly Wages';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        EmployeeStatisticsGroup.Code := Code;
        EmployeeStatisticsGroup.Description := Description;
        EmployeeStatisticsGroup.Insert();
    end;
}

