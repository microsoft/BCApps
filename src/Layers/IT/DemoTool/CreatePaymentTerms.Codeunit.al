codeunit 101003 "Create Payment Terms"
{

    trigger OnRun()
    begin
        InsertData(XCM, XCurrentMonth, 1, 100);
        InsertData(XCOD, XCashOnDelivery, 1, 100);
        InsertData(X1M8D, X1Month2PERCENT8days, 1, 100);
        InsertData(X14DAYS, XNet14days, 1, 100);
        InsertData(X21DAYS, XNet21days, 1, 100);
        InsertData(X7DAYS, XNet7days, 1, 100);

        InsertData(Xx30X2, XNet3060Days, 2, 100);//IT
        InsertData(Xx30X3FM, XNet306090DaysEM, 3, 100);//IT
    end;

    var
        Xx30X2: Label '30X2';
        XNet3060Days: Label 'Net 30, 60 Days';
        Xx30X3FM: Label '30X3FM';
        XNet306090DaysEM: Label 'Net 30,60,90 Days E.M.';
        XCM: Label 'CM';
        XCurrentMonth: Label 'Current Month';
        XCOD: Label 'COD';
        XCashOnDelivery: Label 'Cash on delivery';
        X14DAYS: Label '14 DAYS';
        XNet14days: Label 'Net 14 days';
        X21DAYS: Label '21 DAYS';
        XNet21days: Label 'Net 21 days';
        X7DAYS: Label '7 DAYS';
        XNet7days: Label 'Net 7 days';
        X1Month2PERCENT8days: Label '1 Month/2% 8 days';
        X1M8D: Label '1M(8D)';

    procedure InsertData("Code": Code[10]; Description: Text[50]; "Payment Nos.": Integer; "Payment %": Decimal)
    var
        "Payment Terms": Record "Payment Terms";
    begin
        "Payment Terms".Init();
        "Payment Terms".Validate(Code, Code);
        "Payment Terms".Validate(Description, Description);
        // BEGIN IT
        "Payment Terms"."Payment Nos." := "Payment Nos.";
        "Payment Terms"."Payment %" := "Payment %";
        // END IT
        "Payment Terms".Insert();
    end;

    procedure CashOnDeliveryCode(): Code[10]
    begin
        exit(XCOD);
    end;

    procedure OneMonthEightDaysCode(): Code[10]
    begin
        exit(X1M8D);
    end;

    procedure FourteenDaysCode(): Code[10]
    begin
        exit(X14DAYS);
    end;
}

