codeunit 101044 "Create Std. Sales Line"
{

    trigger OnRun()
    begin
        LineNo := 0;
        InsertData(XLAMPS, 2, '1928-S', 10);
        InsertData(XLAMPS, 5, XSFREIGHT, 0);
        LineNo := 0;
        InsertData(XOFFICE, 2, '1896-S', 0);
        InsertData(XOFFICE, 2, '1908-S', 0);
        InsertData(XOFFICE, 2, '1924-W', 0);
    end;

    var
        StdSalesLine: Record "Standard Sales Line";
        LineNo: Integer;
        XLAMPS: Label 'LAMPS';
        XSFREIGHT: Label 'S-FREIGHT';
        XOFFICE: Label 'OFFICE';

    procedure InsertData(StdSalesCode: Code[10]; Type: Integer; No: Code[20]; Quantity: Decimal)
    begin
        StdSalesLine.Init();
        StdSalesLine.Validate("Standard Sales Code", StdSalesCode);
        StdSalesLine.Validate(Type, Type);
        StdSalesLine.Validate("No.", No);
        if Quantity <> 0 then
            StdSalesLine.Validate(Quantity, Quantity);
        LineNo := LineNo + 10000;
        StdSalesLine."Line No." := LineNo;
        StdSalesLine.Insert();
    end;
}

