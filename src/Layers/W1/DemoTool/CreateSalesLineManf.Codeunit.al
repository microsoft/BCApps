codeunit 119061 "Create Sales Line Manf"
{

    trigger OnRun()
    begin
        CreateSalesLine.InsertData(1, '109001', 2, '1000', '', 25);
        CreateSalesLine.InsertData(1, '109002', 2, '1000', '', 27);
        CreateSalesLine.InsertData(1, '109003', 2, '1000', '', 16);
        CreateSalesLine.InsertData(1, '109004', 2, '1000', '', 20);
        CreateSalesLine.InsertData(1, '109004', 2, '1120', '', 10);
        CreateSalesLine.InsertData(1, '109005', 2, '1000', '', 16);
        CreateSalesLine.InsertData(1, '109005', 2, '1001', '', 3);
        CreateSalesLine.InsertData(1, '109005', 2, '1100', '', 5);
        CreateSalesLine.InsertData(1, '109005', 2, '1200', '', 5);
    end;

    var
        CreateSalesLine: Codeunit "Create Sales Line";
}

