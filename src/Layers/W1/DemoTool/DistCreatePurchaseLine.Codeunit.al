codeunit 118823 "Dist. Create Purchase Line"
{

    trigger OnRun()
    begin
        CreatePurchaseLine.InsertData(1, '6001', 2, '1908-S', XGREEN, 20, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '6001', 2, '1906-S', XGREEN, 20, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '6001', 2, '80100', XGREEN, 200, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '6002', 2, '1964-S', XGREEN, 100, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '6002', 2, '1996-S', XGREEN, 110, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '6002', 2, '80100', XGREEN, 140, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '6003', 2, '1964-S', XGREEN, 110, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '6003', 2, '1968-S', XGREEN, 110, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '6003', 2, '80100', XGREEN, 300, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '6003', 2, '80100', XGREEN, 60, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '6004', 2, '1906-S', XGREEN, 50, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '6004', 2, '1908-S', XGREEN, 50, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '6004', 2, '80100', XGREEN, 20, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '6004', 2, '1964-S', XGREEN, 30, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '6004', 2, '1968-S', XGREEN, 50, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '6004', 2, '1996-S', XGREEN, 50, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '6005', 2, '1896-S', XBLUE, 100, 0, 0, '', '');

        CreatePurchaseLine.InsertData(1, '104001', 2, 'LS-Man-10', XWHITE, 100, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104001', 2, 'LS-75', XWHITE, 10, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104002', 2, 'LS-120', XWHITE, 10, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104002', 2, 'LS-10PC', XWHITE, 22, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104003', 2, 'LS-150', XWHITE, 8, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104004', 2, 'LS-10PC', XWHITE, 40, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104004', 2, 'LS-150', XWHITE, 20, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104005', 2, 'LS-150', XWHITE, 12, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104006', 2, 'LS-Man-10', XWHITE, 50, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104006', 2, 'LS-2', XWHITE, 100, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104007', 2, 'LS-S15', XWHITE, 20, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104008', 2, 'LS-75', XWHITE, 20, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104008', 2, 'LS-120', XWHITE, 10, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104008', 2, 'LS-150', XWHITE, 12, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104009', 2, 'LS-Man-10', XWHITE, 100, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104009', 2, 'LS-10PC', XWHITE, 60, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104010', 2, 'LS-2', XWHITE, 40, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104010', 2, 'LS-10PC', XWHITE, 100, 0, 0, '', '');

        CreatePurchaseLine.InsertData(1, '104011', 2, 'LS-MAN-10', XWHITE, 100, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104011', 2, 'LS-75', XWHITE, 10, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104011', 2, 'LS-120', XWHITE, 10, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104011', 2, 'LS-10PC', XWHITE, 22, 0, 0, '', '');
        CreatePurchaseLine.InsertData(1, '104011', 2, 'LS-150', XWHITE, 8, 0, 0, '', '');

        CreatePurchaseLine.InsertData(1, '104012', 2, 'LS-81', XWHITE, 10, 0, 0, '', '');
    end;

    var
        CreatePurchaseLine: Codeunit "Create Purchase Line";
        XGREEN: Label 'GREEN';
        XBLUE: Label 'BLUE';
        XWHITE: Label 'WHITE';
}

