codeunit 101003 "Create Payment Terms"
{

    trigger OnRun()
    begin
        InsertData(XCM, '<CM>', '', 0, XCurrentMonth, 31);
        InsertData(XCOD, '<0D>', '', 0, XCashOnDelivery, 31);
        InsertData(X1M8D, '<1M>', '<8D>', 2, X1Month2PERCENT8days, 31);
        InsertData(X14DAYS, '<14D>', '', 0, XNet14days, 31);
        InsertData(X21DAYS, '<21D>', '', 0, XNet21days, 21);
        InsertData(X7DAYS, '<7D>', '', 0, XNet7days, 7);
        InsertData(X1x30DAYS, '<30D>', '', 0, X1x30DaysSettlement, 30);
        InsertData(X3x30DAYS, '<30D>', '', 0, X3x306090DaysSettlements, 0);
        InsertData(X2x45DAYS, '<45D>', '', 0, X2x45And60DaysSettlements, 0);
        InsertData(X2DAYS, '<2D>', '', 0, XNet2days, 2);
        InsertData(X10DAYS, '<10D>', '', 0, XNet10days, 10);
        InsertData(X15DAYS, '<15D>', '', 0, XNet15days, 15);
        InsertData(X30DAYS, '<30D>', '', 0, XNet30days, 30);
        InsertData(X60DAYS, '<60D>', '', 0, XNet60days, 60);
        ID2(XCM, 1, 100, '');
        ID2(XCOD, 1, 100, '');
        ID2('1M(8D)', 1, 100, '');
        ID2(X14DAYS, 1, 100, '');
        ID2(X21DAYS, 1, 100, '');
        ID2(X7DAYS, 1, 100, '');
        ID2(X1x30DAYS, 1, 100, '');
        ID2(X3x30DAYS, 1, 55, '<30D>');
        ID2(X3x30DAYS, 2, 30, '<30D>');
        ID2(X3x30DAYS, 3, 15, '');
        ID2(X2x45DAYS, 1, 50, '<45D>');
        ID2(X2x45DAYS, 2, 50, '');
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
        X1x30DAYS: Label '1x30 DAYS';
        X1x30DaysSettlement: Label '1 - 30 days settlement';
        X3x30DAYS: Label '3x30 DAYS';
        X3x306090DaysSettlements: Label '3 - 30,60,90 days settlements';
        X2x45DAYS: Label '2x45 DAYS';
        X2x45And60DaysSettlements: Label '2 - 45 and 60 days settlements';
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

    procedure InsertData("Code": Code[10]; "Due Date Calculation": Text[30]; "Discount Date Calculation": Text[30]; "Discount %": Decimal; Description: Text[50]; MaxDayForDueDate: Integer)
    var
        "Payment Terms": Record "Payment Terms";
    begin
        "Payment Terms".Init();
        "Payment Terms".Validate(Code, Code);
        "Payment Terms".Insert(true);
        Evaluate("Payment Terms"."Due Date Calculation", "Due Date Calculation");
        "Payment Terms".Validate("Due Date Calculation");

        Evaluate("Payment Terms"."Discount Date Calculation", "Discount Date Calculation");
        "Payment Terms".Validate("Discount Date Calculation");
        "Payment Terms"."Calc. Pmt. Disc. on Cr. Memos" := true;
        "Payment Terms".Validate("Discount %", "Discount %");
        "Payment Terms".Validate(Description, Description);
        "Payment Terms".Validate("VAT distribution", 2);
        "Payment Terms".Validate("Max. No. of Days till Due Date", MaxDayForDueDate);
        "Payment Terms".Modify(true);
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

    procedure ID2("Payment terms code": Code[10]; No: Integer; "% of total": Decimal; GapBetInst: Code[20])
    var
        Installments: Record Installment;
    begin
        Installments.Init();
        Installments.SetRange("Payment Terms Code", "Payment terms code");
        Installments.Validate("Payment Terms Code", "Payment terms code");
        Installments.Validate("Line No.", No);
        Installments.Validate("% of Total", "% of total");
        Installments.Validate("Gap between Installments", GapBetInst);
        Installments.Insert(true);
    end;
}

