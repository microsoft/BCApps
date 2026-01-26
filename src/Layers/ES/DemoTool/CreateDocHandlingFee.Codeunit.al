codeunit 161007 "Create Doc.-Handling Fee"
{

    trigger OnRun()
    begin
        InsertData(XWWBEUR, '', 0, 1000);
        InsertData(XWWBEUR, '', 1, 0);
        InsertData(XWWBEUR, '', 2, 0);
        InsertData(XWWBEUR, '', 3, 0);
        InsertData(XWWBEUR, '', 4, 1300);
        InsertData(XWWBEUR, '', 5, 800);
        InsertData(XWWBEUR, '', 6, 900);

        InsertData(XNBL, '', 0, 1200);
        InsertData(XNBL, '', 1, 0);
        InsertData(XNBL, '', 2, 1000);
        InsertData(XNBL, '', 3, 0);
        InsertData(XNBL, '', 4, 500);
        InsertData(XNBL, '', 5, 600);
        InsertData(XNBL, '', 6, 700);


        ID2(XWWBEUR, '', 0, 0, 50, 0, 15);
        ID2(XWWBEUR, '', 1, 0, 0, 0.1, 0);
        ID2(XWWBEUR, '', 2, 30, 0, 8.25, 0);
        ID2(XWWBEUR, '', 2, 60, 0, 8.75, 0);
        ID2(XWWBEUR, '', 2, 90, 0, 9.25, 0);
        ID2(XWWBEUR, '', 3, 0, 0, 12.5, 0);
        ID2(XWWBEUR, '', 4, 0, 0, 10.25, 0);
        ID2(XWWBEUR, '', 5, 0, 0, 12.75, 0);
        ID2(XWWBEUR, '', 6, 0, 0, 8, 0);

        ID2(XNBL, '', 0, 0, 0, 0.5, 12);
        ID2(XNBL, '', 1, 0, 0, 0.2, 20);
        ID2(XNBL, '', 2, 30, 0, 5.25, 0);
        ID2(XNBL, '', 2, 60, 0, 6.75, 0);
        ID2(XNBL, '', 2, 90, 0, 7.25, 0);
        ID2(XNBL, '', 3, 0, 0, 17.25, 0);
        ID2(XNBL, '', 4, 0, 0, 10.25, 0);
        ID2(XNBL, '', 5, 0, 0, 8, 0);
        ID2(XNBL, '', 6, 0, 0, 12.75, 0);
    end;

    var
        "Operation Fee": Record "Operation Fee";
        "Fee Range": Record "Fee Range";
        XNBL: Label 'NBL';
        XWWBEUR: Label 'WWB-EUR';

    procedure InsertData("Code": Code[20]; "Currency Code": Code[10]; "Type of Fee": Option; ChargeAmtPerOperation: Decimal)
    begin
        "Operation Fee".Init();
        "Operation Fee".Validate(Code, Code);
        "Operation Fee".Validate("Currency Code", "Currency Code");
        "Operation Fee".Validate("Type of Fee", "Type of Fee");
        "Operation Fee".Validate("Charge Amt. per Operation", ChargeAmtPerOperation);
        "Operation Fee".Insert();
    end;

    procedure ID2("Code": Code[20]; "Currency Code": Code[10]; "Type of Fee": Option; "From No. of Days": Integer; "Charge Amount per Doc": Decimal; "Charge % per Doc": Decimal; MinAmount: Decimal)
    begin
        "Fee Range".Init();
        "Fee Range".Validate(Code, Code);
        "Fee Range".Validate("Currency Code", "Currency Code");
        "Fee Range".Validate("Type of Fee", "Type of Fee");
        "Fee Range".Validate("From No. of Days", "From No. of Days");
        "Fee Range".Validate("Charge Amount per Doc.", "Charge Amount per Doc");
        "Fee Range".Validate("Charge % per Doc.", "Charge % per Doc");
        "Fee Range".Validate("Minimum Amount", MinAmount);
        "Fee Range".Insert();
    end;
}

