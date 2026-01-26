codeunit 118813 "Dist. Create Sales Line"
{

    trigger OnRun()
    begin
        CreateSalesLine.InsertData(1, '6001', 2, '1908-S', XGREEN, 12, '', 0);
        CreateSalesLine.InsertData(1, '6001', 2, '1906-S', XGREEN, 22, '', 0);
        CreateSalesLine.InsertData(1, '6001', 2, '80100', XGREEN, 20, '', 0);
        CreateSalesLine.InsertData(1, '6002', 2, '1964-S', XGREEN, 34, '', 0);
        CreateSalesLine.InsertData(1, '6002', 2, '1996-S', XGREEN, 11, '', 0);
        CreateSalesLine.InsertData(1, '6002', 2, '80100', XGREEN, 14, '', 0);
        CreateSalesLine.InsertData(1, '6003', 2, '1964-S', XGREEN, 11, '', 0);
        CreateSalesLine.InsertData(1, '6003', 2, '1968-S', XGREEN, 11, '', 0);
        CreateSalesLine.InsertData(1, '6003', 2, '80100', XGREEN, 30, '', 0);
        CreateSalesLine.InsertData(1, '6003', 2, '80100', XGREEN, 6, '', 0);
        CreateSalesLine.InsertData(1, '6004', 2, '1906-S', XGREEN, 5, '', 0);
        CreateSalesLine.InsertData(1, '6004', 2, '1908-S', XGREEN, 5, '', 0);
        CreateSalesLine.InsertData(1, '6004', 2, '80100', XGREEN, 20, '', 0);
        CreateSalesLine.InsertData(1, '6004', 2, '1964-S', XGREEN, 3, '', 0);
        CreateSalesLine.InsertData(1, '6004', 2, '1968-S', XGREEN, 5, '', 0);
        CreateSalesLine.InsertData(1, '6004', 2, '1996-S', XGREEN, 5, '', 0);
        CreateSalesLine.InsertData(1, '6005', 2, '1964-W', XBLUE, 10, '', 0);
        CreateSalesLine.InsertData(1, '6005', 2, '70011', XBLUE, 5, '', 0);

        CreateSalesLine.InsertData(1, '104001', 2, 'LS-Man-10', XWHITE, 4, '', 0);
        CreateSalesLine.InsertData(1, '104002', 2, 'LS-75', XWHITE, 10, '', 0);
        CreateSalesLine.InsertData(1, '104002', 2, 'LS-120', XWHITE, 6, '', 0);
        CreateSalesLine.InsertData(1, '104002', 2, 'LS-10PC', XWHITE, 20, '', 0);
        CreateSalesLine.InsertData(1, '104003', 2, 'LS-150', XWHITE, 8, '', 0);
        CreateSalesLine.InsertData(1, '104004', 2, 'LS-10PC', XWHITE, 30, '', 0);
        CreateSalesLine.InsertData(1, '104005', 2, 'LS-150', XWHITE, 16, '', 0);
        CreateSalesLine.InsertData(1, '104005', 2, 'LS-150', XWHITE, 22, '', 0);
        CreateSalesLine.InsertData(1, '104006', 2, 'LS-Man-10', XWHITE, 10, '', 0);
        CreateSalesLine.InsertData(1, '104007', 2, 'LS-2', XWHITE, 20, '', 0);
        CreateSalesLine.InsertData(1, '104007', 2, 'LS-S15', XWHITE, 12, '', 0);
        CreateSalesLine.InsertData(1, '104007', 2, 'LS-Man-10', XWHITE, 30, '', 0);
        CreateSalesLine.InsertData(1, '104007', 2, 'LS-75', XWHITE, 16, '', 0);
        CreateSalesLine.InsertData(1, '104008', 2, 'LS-120', XWHITE, 10, '', 0);
        CreateSalesLine.InsertData(1, '104009', 2, 'LS-10PC', XWHITE, 12, '', 0);
        CreateSalesLine.InsertData(1, '104009', 2, 'LS-150', XWHITE, 8, '', 0);
        CreateSalesLine.InsertData(1, '104010', 2, 'LS-10PC', XWHITE, 20, '', 0);
        CreateSalesLine.InsertData(1, '104011', 2, 'LS-150', XWHITE, 10, '', 0);
        CreateSalesLine.InsertData(1, '104012', 2, 'LS-150', XWHITE, 8, '', 0);
        CreateSalesLine.InsertData(1, '104012', 2, 'LS-Man-10', XWHITE, 20, '', 0);
        CreateSalesLine.InsertData(1, '104012', 2, 'LS-2', XWHITE, 10, '', 0);
        CreateSalesLine.InsertData(1, '104013', 2, 'LS-S15', XWHITE, 12, '', 0);
        CreateSalesLine.InsertData(1, '104014', 2, 'LS-75', XWHITE, 8, '', 0);
        CreateSalesLine.InsertData(1, '104015', 2, 'LS-120', XWHITE, 4, '', 0);
        CreateSalesLine.InsertData(1, '104016', 2, 'LS-75', XWHITE, 4, '', 0);
        CreateSalesLine.InsertData(1, '104016', 2, 'LS-120', XWHITE, 2, '', 0);
        CreateSalesLine.InsertData(1, '104016', 2, 'LS-150', XWHITE, 2, '', 0);
        CreateSalesLine.InsertData(1, '104017', 2, 'LS-Man-10', XWHITE, 1, '', 0);
        CreateSalesLine.InsertData(1, '104018', 2, 'LS-10PC', XWHITE, 2, '', 0);
        CreateSalesLine.InsertData(1, '104018', 2, 'LS-2', XWHITE, 2, '', 0);
        CreateSalesLine.InsertData(1, '104019', 2, 'LS-MAN-10', XWHITE, 4, '', 0);
        CreateSalesLine.InsertData(1, '104019', 2, 'LS-75', XWHITE, 10, '', 0);
        CreateSalesLine.InsertData(1, '104019', 2, 'LS-120', XWHITE, 6, '', 0);
        CreateSalesLine.InsertData(1, '104020', 2, 'LS-10PC', XWHITE, 20, '', 0);
        CreateSalesLine.InsertData(1, '104020', 2, 'LS-120', XWHITE, 8, '', 0);
        CreateSalesLine.InsertData(1, '104020', 2, 'LS-10PC', XWHITE, 30, '', 0);
        CreateSalesLine.InsertData(1, '104021', 2, 'LS-81', XWHITE, 72, '', 0);
    end;

    var
        CreateSalesLine: Codeunit "Create Sales Line";
        XGREEN: Label 'GREEN';
        XBLUE: Label 'BLUE';
        XWHITE: Label 'WHITE';
}

