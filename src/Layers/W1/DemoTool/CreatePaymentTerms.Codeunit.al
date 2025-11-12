codeunit 101003 "Create Payment Terms"
{

    trigger OnRun()
    begin
        InsertData(XCM, '<CM>', '', 0, XCurrentMonth);
        InsertData(XCOD, '<0D>', '', 0, XCashOnDelivery);
        InsertData(X1M8D, '<1M>', '<8D>', 2, X1Month2PERCENT8days);
        InsertData(X14DAYS, '<14D>', '', 0, XNet14days);
        InsertData(X21DAYS, '<21D>', '', 0, XNet21days);
        InsertData(X7DAYS, '<7D>', '', 0, XNet7days);
        InsertData(X2DAYS, '<2D>', '', 0, XNet2days);
        InsertData(X10DAYS, '<10D>', '', 0, XNet10days);
        InsertData(X15DAYS, '<15D>', '', 0, XNet15days);
        InsertData(X30DAYS, '<30D>', '', 0, XNet30days);
        InsertData(X60DAYS, '<60D>', '', 0, XNet60days);
    end;

    var
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
        X60DAYS: Label '60 DAYS';
        XNet60days: Label 'Net 60 days';
        X30DAYS: Label '30 DAYS';
        XNet30days: Label 'Net 30 days';
        X15DAYS: Label '15 DAYS';
        XNet15days: Label 'Net 15 days';
        X10DAYS: Label '10 DAYS';
        XNet10days: Label 'Net 10 days';
        X2DAYS: Label '2 DAYS';
        XNet2days: Label 'Net 2 days';

    procedure InsertData("Code": Code[10]; "Due Date Calculation": Text[30]; "Discount Date Calculation": Text[30]; "Discount %": Decimal; Description: Text[50])
    var
        "Payment Terms": Record "Payment Terms";
    begin
        "Payment Terms".Init();
        "Payment Terms".Validate(Code, Code);

        Evaluate("Payment Terms"."Due Date Calculation", "Due Date Calculation");
        "Payment Terms".Validate("Due Date Calculation");

        Evaluate("Payment Terms"."Discount Date Calculation", "Discount Date Calculation");
        "Payment Terms".Validate("Discount Date Calculation");

        "Payment Terms".Validate("Discount %", "Discount %");
        "Payment Terms".Validate(Description, Description);
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

