codeunit 161370 "Create Payment Terms Lines"
{

    trigger OnRun()
    begin
        Evaluate(DueDateCalculation, '<CM>');
        Evaluate(DiscountDateCalculation, '<0D>');
        InsertData(PaymentLines.Type::"Payment Terms", XxCM, 10000, 100, DueDateCalculation,
                   DiscountDateCalculation, 0, (0D), (0D), PaymentLines."Sales/Purchase"::" ", '', 0);

        Evaluate(DueDateCalculation, '<0D>');
        InsertData(PaymentLines.Type::"Payment Terms", XxCOD, 10000, 100, DueDateCalculation,
                   DiscountDateCalculation, 0, (0D), (0D), PaymentLines."Sales/Purchase"::" ", '', 0);

        Evaluate(DueDateCalculation, '<1M>');
        Evaluate(DiscountDateCalculation, '<8D>');
        InsertData(PaymentLines.Type::"Payment Terms", Xx1MxI8DIx, 10000, 100, DueDateCalculation,
                   DiscountDateCalculation, 2, (0D), (0D), PaymentLines."Sales/Purchase"::" ", '', 0);

        Evaluate(DueDateCalculation, '<14D>');
        Evaluate(DiscountDateCalculation, '<0D>');
        InsertData(PaymentLines.Type::"Payment Terms", X14Days, 10000, 100, DueDateCalculation,
                   DiscountDateCalculation, 0, (0D), (0D), PaymentLines."Sales/Purchase"::" ", '', 0);

        Evaluate(DueDateCalculation, '<21D>');
        InsertData(PaymentLines.Type::"Payment Terms", X21Days, 10000, 100, DueDateCalculation,
                   DiscountDateCalculation, 0, (0D), (0D), PaymentLines."Sales/Purchase"::" ", '', 0);

        Evaluate(DueDateCalculation, '<30D>');
        InsertData(PaymentLines.Type::"Payment Terms", Xx30X2, 10000, 50, DueDateCalculation,
                   DiscountDateCalculation, 0, (0D), (0D), PaymentLines."Sales/Purchase"::" ", '', 0);
        Evaluate(DueDateCalculation, '<60D>');
        InsertData(PaymentLines.Type::"Payment Terms", Xx30X2, 20000, 50, DueDateCalculation,
                   DiscountDateCalculation, 0, (0D), (0D), PaymentLines."Sales/Purchase"::" ", '', 0);

        Evaluate(DueDateCalculation, '<30D+CM>');
        InsertData(PaymentLines.Type::"Payment Terms", Xx30X3FM, 10000, 33.33, DueDateCalculation,
                   DiscountDateCalculation, 0, (0D), (0D), PaymentLines."Sales/Purchase"::" ", '', 0);
        Evaluate(DueDateCalculation, '<60D+CM>');
        InsertData(PaymentLines.Type::"Payment Terms", Xx30X3FM, 20000, 33.33, DueDateCalculation,
                   DiscountDateCalculation, 0, (0D), (0D), PaymentLines."Sales/Purchase"::" ", '', 0);

        Evaluate(DueDateCalculation, '<90D+CM>');
        InsertData(PaymentLines.Type::"Payment Terms", Xx30X3FM, 30000, 33.34, DueDateCalculation,
                   DiscountDateCalculation, 0, (0D), (0D), PaymentLines."Sales/Purchase"::" ", '', 0);

        Evaluate(DueDateCalculation, '<7D>');
        InsertData(PaymentLines.Type::"Payment Terms", X7Days, 10000, 100, DueDateCalculation,
                   DiscountDateCalculation, 0, (0D), (0D), PaymentLines."Sales/Purchase"::" ", '', 0);
    end;

    var
        XxCM: Label 'CM';
        XxCOD: Label 'COD';
        Xx1MxI8DIx: Label '1M(8D)';
        X14Days: Label '14 DAYS';
        X21Days: Label '21 DAYS';
        Xx30X2: Label '30X2';
        Xx30X3FM: Label '30X3FM';
        X7Days: Label '7 DAYS';
        PaymentLines: Record "Payment Lines";
        DueDateCalculation: DateFormula;
        DiscountDateCalculation: DateFormula;

    procedure InsertData(Type: Enum "Payment Lines Document Type"; "Code": Code[10]; "Line No.": Integer; "Payment %": Decimal; "Due Date Calculation": DateFormula; "Discount Date Calculation": DateFormula; "Discount %": Decimal; "Due Date": Date; "Pmt. Discount Date": Date; "Sales/Purchase": Option; "Journal Template Name": Code[10]; "Journal Line No.": Integer)
    begin
        PaymentLines.Init();
        PaymentLines.Type := Type;
        PaymentLines.Code := Code;
        PaymentLines."Line No." := "Line No.";
        PaymentLines."Payment %" := "Payment %";
        PaymentLines."Due Date Calculation" := "Due Date Calculation";
        PaymentLines."Discount Date Calculation" := "Discount Date Calculation";
        PaymentLines."Discount %" := "Discount %";
        PaymentLines."Due Date" := "Due Date";
        PaymentLines."Pmt. Discount Date" := "Pmt. Discount Date";
        PaymentLines."Sales/Purchase" := "Sales/Purchase";
        PaymentLines."Journal Template Name" := "Journal Template Name";
        PaymentLines."Journal Line No." := "Journal Line No.";
        PaymentLines.Insert();
    end;
}

