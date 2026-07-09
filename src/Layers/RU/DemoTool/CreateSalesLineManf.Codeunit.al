codeunit 119061 "Create Sales Line Manf"
{

    trigger OnRun()
    begin
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOM + '-00001', 2, '1000', '', 25, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOM + '-00002', 2, '1000', '', 27, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOM + '-00003', 2, '1000', '', 16, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOM + '-00004', 2, '1000', '', 20, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOM + '-00004', 2, '1120', '', 10, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOM + '-00005', 2, '1000', '', 16, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOM + '-00005', 2, '1001', '', 3, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOM + '-00005', 2, '1100', '', 5, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOM + '-00005', 2, '1200', '', 5, '', '', '');
    end;

    var
        CreateSalesLine: Codeunit "Create Sales Line";
        XSOM: Label 'SOM';
}

