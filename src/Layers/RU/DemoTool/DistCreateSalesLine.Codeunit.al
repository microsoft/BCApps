codeunit 118813 "Dist. Create Sales Line"
{

    trigger OnRun()
    begin
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00001', 2, '1908-S', XGREEN, 12, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00001', 2, '1906-S', XGREEN, 22, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00001', 2, '80100', XGREEN, 20, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00002', 2, '1964-S', XGREEN, 34, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00002', 2, '1996-S', XGREEN, 11, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00002', 2, '80100', XGREEN, 14, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00003', 2, '1964-S', XGREEN, 11, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00003', 2, '1968-S', XGREEN, 11, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00003', 2, '80100', XGREEN, 30, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00003', 2, '80100', XGREEN, 6, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00004', 2, '1906-S', XGREEN, 5, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00004', 2, '1908-S', XGREEN, 5, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00004', 2, '80100', XGREEN, 20, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00004', 2, '1964-S', XGREEN, 3, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00004', 2, '1968-S', XGREEN, 5, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00004', 2, '1996-S', XGREEN, 5, '', '', '');

        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00005', 2, '1964-W', XBLUE, 10, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '-00005', 2, '70011', XBLUE, 5, '', '', '');

        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00001', 2, 'LS-Man-10', XWHITE, 4, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00002', 2, 'LS-75', XWHITE, 10, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00002', 2, 'LS-120', XWHITE, 6, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00002', 2, 'LS-10PC', XWHITE, 20, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00003', 2, 'LS-150', XWHITE, 8, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00004', 2, 'LS-10PC', XWHITE, 30, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00005', 2, 'LS-150', XWHITE, 16, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00005', 2, 'LS-150', XWHITE, 22, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00006', 2, 'LS-Man-10', XWHITE, 10, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00007', 2, 'LS-2', XWHITE, 20, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00007', 2, 'LS-S15', XWHITE, 12, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00007', 2, 'LS-Man-10', XWHITE, 30, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00007', 2, 'LS-75', XWHITE, 16, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00008', 2, 'LS-120', XWHITE, 10, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00009', 2, 'LS-10PC', XWHITE, 12, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00009', 2, 'LS-150', XWHITE, 8, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00010', 2, 'LS-10PC', XWHITE, 20, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00011', 2, 'LS-150', XWHITE, 10, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00012', 2, 'LS-150', XWHITE, 8, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00012', 2, 'LS-Man-10', XWHITE, 20, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00012', 2, 'LS-2', XWHITE, 10, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00013', 2, 'LS-S15', XWHITE, 12, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00014', 2, 'LS-75', XWHITE, 8, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00015', 2, 'LS-120', XWHITE, 4, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00016', 2, 'LS-75', XWHITE, 4, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00016', 2, 'LS-120', XWHITE, 2, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00016', 2, 'LS-150', XWHITE, 2, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00017', 2, 'LS-Man-10', XWHITE, 1, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00018', 2, 'LS-10PC', XWHITE, 2, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00018', 2, 'LS-2', XWHITE, 2, '', '', '');

        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00019', 2, 'LS-MAN-10', XWHITE, 4, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00019', 2, 'LS-75', XWHITE, 10, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00019', 2, 'LS-120', XWHITE, 6, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00020', 2, 'LS-10PC', XWHITE, 20, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00020', 2, 'LS-120', XWHITE, 8, '', '', '');
        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00020', 2, 'LS-10PC', XWHITE, 30, '', '', '');

        CreateSalesLine.InsertData("Sales Document Type"::Order, XSOD + '1-00021', 2, 'LS-81', XWHITE, 72, '', '', '');
    end;

    var
        CreateSalesLine: Codeunit "Create Sales Line";
        XGREEN: Label 'GREEN';
        XBLUE: Label 'BLUE';
        XWHITE: Label 'WHITE';
        XSOD: Label 'SOD';
}

