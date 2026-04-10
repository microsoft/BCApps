codeunit 101036 "Create Sales Header"
{

    trigger OnRun()
    begin
        DemoSetup.Get();
        LY := CopyStr(Format(DemoSetup."Starting Year"), 3, 2);
        CY := IncStr(LY);

        InsertData(1, '10000', 19030105D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1968-S', XRED, 5, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1996-S', XRED, 7, '1103000', '', '');

        InsertData(1, '01445544', 19030121D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1928-S', XGREEN, 14, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1988-W', XGREEN, 1, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1972-S', XGREEN, 1, '1103000', '', '');

        InsertData(1, '32656565', 19030109D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1968-S', XRED, 4, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1960-S', XRED, 7, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1976-W', XRED, 5, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '70011', XRED, 1, '1103000', '', '');

        InsertData(1, '20000', 19030111D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1896-S', XGREEN, 1, '1103000', '', '');

        InsertData(1, '30000', 19030112D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1920-S', XRED, 4, '1103000', '', '');

        InsertData(1, '49633663', 19030114D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1896-S', XRED, 1, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1906-S', XRED, 1, '1103000', '', '');

        InsertData(1, '20000', 19030116D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '766BC-C', XGREEN, 1, '1103000', '', '');

        InsertData(1, '35451236', 19030118D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1992-W', XRED, 1, '1103000', '', '');

        InsertData(1, '38128456', 19030120D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1976-W', XGREEN, 5, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1964-W', XGREEN, 2, '1103000', '', '');

        InsertData(1, '42147258', 19030113D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1972-S', XRED, 6, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1968-S', XRED, 4, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1980-S', XRED, 3, '1103000', '', '');

        InsertData(1, '43687129', 19030113D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1920-S', XGREEN, 5, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1900-S', XGREEN, 12, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1996-S', XGREEN, 1, '1103000', '', '');

        InsertData(1, '20000', 19030115D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1928-S', XGREEN, 5, '1103000', '', '');

        InsertData(1, '46897889', 19030119D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1952-W', XGREEN, 1, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1928-W', XGREEN, 2, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1964-W', XGREEN, 2, '1103000', '', '');

        InsertData(1, '47563218', 19030120D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '766BC-A', XGREEN, 2, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '766BC-C', XGREEN, 1, '1103000', '', '');

        InsertData(1, '49633663', 19030122D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1972-S', XRED, 6, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1968-S', XRED, 5, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1896-S', XRED, 12, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1906-S', XRED, 12, '1103000', '', '');

        InsertData(1, '10000', 19030126D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1920-S', XRED, 1, '1103000', '', '');

        InsertData(1, '20000', 19030127D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1928-W', XGREEN, 2, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1964-W', XGREEN, 1, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1976-W', XGREEN, 1, '1103000', '', '');

        InsertData(1, '01454545', 19030127D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1980-S', XGREEN, 6, '1103000', '', '');

        InsertData(1, '31987987', 19030127D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1952-W', XRED, 2, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1928-W', XRED, 2, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1976-W', XRED, 2, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1964-W', XRED, 2, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '70060', XRED, 2, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1896-S', XRED, 2, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1908-S', XRED, 2, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1928-S', XRED, 2, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '70102', XRED, 2, '1103000', '', '');

        InsertData(1, '32789456', 19030127D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1992-W', XRED, 4, '1103000', '', '');

        InsertData(1, '35963852', 19030127D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1968-W', XRED, 2, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1964-W', XRED, 1, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1960-S', XRED, 1, '1103000', '', '');

        InsertData(1, '38128456', 19030205D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1976-W', XYELLOW, 3, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1964-W', XGREEN, 4, '1103000', '', '');

        InsertData(1, '30000', 19030222D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1920-S', XGREEN, 4, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1936-S', XGREEN, 23, '1103000', '', '');

        InsertData(2, XCLE + '001', 19021101D, XItemSelling, '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-002', XBLUE, 3, '1103000', '', '');
        CreateSalesLine.UpdateData('', 1378.84, 965.19);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-003', XBLUE, 3, '1103000', '', '');
        CreateSalesLine.UpdateData('', 38.8, 27.16);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-004', XBLUE, 1, '1103000', '', '');
        CreateSalesLine.UpdateData('', 23.7, 16.59);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-005', XBLUE, 1, '1103000', '', '');
        CreateSalesLine.UpdateData('', 140.4, 98.28);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-006', XBLUE, 1, '1103000', '', '');
        CreateSalesLine.UpdateData('', 32251.8, 22576.26);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-007', XBLUE, 1, '1103000', '', '');
        CreateSalesLine.UpdateData('', 19149.51, 13404.66);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-008', XBLUE, 1, '1103000', '', '');
        CreateSalesLine.UpdateData('', 20157.39, 14110.17);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-009', XBLUE, 1, '1103000', '', '');
        CreateSalesLine.UpdateData('', 1080.54, 756.38);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-010', XBLUE, 1, '1103000', '', '');
        CreateSalesLine.UpdateData('', 2748.53, 1923.97);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-011', XBLUE, 1, '1103000', '', '');
        CreateSalesLine.UpdateData('', 3594.89, 2516.42);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-012', XBLUE, 1, '1103000', '', '');
        CreateSalesLine.UpdateData('', 7421.19, 5194.83);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-013', XBLUE, 1, '1103000', '', '');
        CreateSalesLine.UpdateData('', 5779.99, 4045.99);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-014', XBLUE, 95, '1103000', '', '');
        CreateSalesLine.UpdateData('', 12.94, 9.06);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-015', XBLUE, 1, '1103000', '', '');
        CreateSalesLine.UpdateData('', 27.2, 19.04);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-016', XBLUE, 1, '1103000', '', '');
        CreateSalesLine.UpdateData('', 27.21, 19.05);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-017', XBLUE, 1, '1103000', '', '');
        CreateSalesLine.UpdateData('', 25.6, 17.92);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-018', XBLUE, 1, '1103000', '', '');
        CreateSalesLine.UpdateData('', 23.69, 16.58);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-019', XBLUE, 1, '1103000', '', '');
        CreateSalesLine.UpdateData('', 23.7, 16.59);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-020', XBLUE, 10, '1103000', '', '');
        CreateSalesLine.UpdateData('', 272.4, 190.68);

        InsertData(2, XCLE + '004', 19021105D, XItemSelling2, '', '', '', 1, XB2JRUR + '-' + LY + '-004');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-022', XBLUE, 53600, '1103000', '', '');
        CreateSalesLine.UpdateData('', 12.12, 2.96657);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-023', XBLUE, 36400, '1103000', '', '');
        CreateSalesLine.UpdateData('', 17.8, 4.45064);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-024', XBLUE, 10000, '1103000', '', '');
        CreateSalesLine.UpdateData('', 27.8, 6.82313);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-025', XBLUE, 3000, '1103000', '', '');
        CreateSalesLine.UpdateData('', 35.04, 8.60298);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-026', XBLUE, 13676.9, '1103000', '', '');
        CreateSalesLine.UpdateData('', 72.28, 17.7994);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XITE + '-022', XBLUE, 1000, '1103000', '', '');
        CreateSalesLine.UpdateData('', 12.12, 2.98516);

        InsertData(2, XCLE + '002', 19021031D, XServRentPayOct, '1101000', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 1, '90-1210', '', 1, '1101000', '', '');
        CreateSalesLine.UpdateData(XServRentPayOct, 400000, 0);

        InsertData(2, XCLE + '002', 19021130D, XServRentPayNov, '1101000', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 1, '90-1210', '', 1, '1101000', '', '');
        CreateSalesLine.UpdateData(XServRentPayNov, 800000, 0);

        InsertData(2, XCLE + '002', 19021231D, XServRentPayDec, '1101000', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 1, '90-1210', '', 1, '1101000', '', '');
        CreateSalesLine.UpdateData(XServRentPayDec, 800000, 0);

        InsertData(2, XCLE + '002', 19021231D, XServStorDec, '1102000', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 1, '90-1210', '', 1, '1101000', '', '');
        CreateSalesLine.UpdateData(XServStorDec, 23000, 0);

        InsertData(2, XCLE + '003', 19021212D, XSpecClInv, '1201000', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, XMAT + '-002', XBLUE, 20, '1201000', '', '');
        CreateSalesLine.UpdateData('', 280, 250);

        InsertData(2, XCLE + '003', 19021228D, XSell4Comp, '1201000', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 4, XFA + '017', '', 1, '1201000', '', '');
        CreateSalesLine.UpdateData(XComputer, 26000, 0);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 4, XFA + '018', '', 1, '1201000', '', '');
        CreateSalesLine.UpdateData(XComputer, 26000, 0);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 4, XFA + '019', '', 1, '1201000', '', '');
        CreateSalesLine.UpdateData(XComputer, 26000, 0);
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 4, XFA + '020', '', 1, '1201000', '', '');
        CreateSalesLine.UpdateData(XComputer, 26000, 0);


        InsertData(2, XCLE + '005', 19030116D, XSellFA12, '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 4, XFA + '012', '', 1, '', '', '');
        CreateSalesLine.UpdateData(XComputer, 17000, 0);
        // Add new orders here
        InsertData(2, '10000', 19030123D, '', '', '', '', 0, '');
        CreateSalesLine.InsertResource("Sales Header"."Document Type", "Sales Header"."No.", 3, XTERRY, XAssemblingFurnitureJanuary, '', 25, '1109000', '', '');
        CreateSalesLine.InsertResource("Sales Header"."Document Type", "Sales Header"."No.", 3, XTERRY, XAssemblingFurnitureJanuary, XMILES, 120, '1109000', '', '');

        InsertData(2, '20000', 19030123D, '', '', '', '', 0, '');
        CreateSalesLine.InsertResource("Sales Header"."Document Type", "Sales Header"."No.", 3, XTERRY, XAssemblingFurnitureJanuary, '', 25, '1109000', '', '');
        CreateSalesLine.InsertResource("Sales Header"."Document Type", "Sales Header"."No.", 3, XTERRY, XAssemblingFurnitureJanuary, XMILES, 96, '1109000', '', '');

        InsertData(2, '30000', 19030123D, '', '', '', '', 0, '');
        CreateSalesLine.InsertResource("Sales Header"."Document Type", "Sales Header"."No.", 3, XTERRY, XAssemblingFurnitureJanuary, '', 25, '1109000', '', '');
        CreateSalesLine.InsertResource("Sales Header"."Document Type", "Sales Header"."No.", 3, XTERRY, XAssemblingFurnitureJanuary, XMILES, 76, '1109000', '', '');

        InsertData(2, '50000', 19030124D, '', '', '', '', 0, '');
        CreateSalesLine.InsertResource("Sales Header"."Document Type", "Sales Header"."No.", 3, XLINA, XLinaTownsend, '', 4, '1109000', '', '');
        CreateSalesLine.InsertResource("Sales Header"."Document Type", "Sales Header"."No.", 3, XLINA, XLinaTownsend, '', 10, '1109000', '', '');
        CreateSalesLine.InsertResource("Sales Header"."Document Type", "Sales Header"."No.", 3, XLINA, XLinaTownsend, '', 3, '1109000', '', '');
        CreateSalesLine.InsertResource("Sales Header"."Document Type", "Sales Header"."No.", 3, XLIFT, XLiftforfurniture, '', 8, '1109000', '', '');
        CreateSalesLine.InsertResource("Sales Header"."Document Type", "Sales Header"."No.", 3, XMARTY, XMartyHorst, '', 8, '1109000', '', '');
        CreateSalesLine.InsertResource("Sales Header"."Document Type", "Sales Header"."No.", 3, XMARTY, XMartyHorst, '', 8, '1109000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1920-S', XBLUE, 10, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1928-S', XBLUE, 10, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1964-S', XBLUE, 60, '1103000', '', '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1984-W', XBLUE, 10, '1103000', '', '');
        InsertData(2, '49525252', 19030105D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Document Type"::Invoice, "Sales Header"."No.", 2, '1976-W', XRED, 5, '1103000', '', '');
        InsertData(2, '49525252', 19030105D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Document Type"::Invoice, "Sales Header"."No.", 2, '1976-W', XRED, 25, '1103000', '', '');
        InsertData(2, '49858585', 19030105D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Document Type"::Invoice, "Sales Header"."No.", 2, '1976-W', XRED, 21, '1103000', '', '');
        InsertData(2, '49858585', 19030105D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Document Type"::Invoice, "Sales Header"."No.", 2, '1976-W', XRED, 21, '1103000', '', '');
        InsertData(2, '49858585', 19030105D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Document Type"::Invoice, "Sales Header"."No.", 2, '1976-W', XRED, 42, '1103000', '', '');
        InsertData(2, '49633663', 19030105D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Document Type"::Invoice, "Sales Header"."No.", 2, '1976-W', XRED, 22, '1103000', '', '');

        InsertData(2, '43687129', 19030105D, '', '', '', '', 0, '');
        CreateSalesLine.InsertDataAndUpdateUnitPrice("Sales Header"."Document Type", "Sales Header"."No.", 2, '70000', '', 3, 4349 / 3);
        InsertData(2, '43687129', 19030105D, '', '', '', '', 0, '');
        CreateSalesLine.InsertDataAndUpdateUnitPrice("Sales Header"."Document Type", "Sales Header"."No.", 2, '70000', '', 4, 5798.78 / 4);
        InsertData(2, '43687129', 19030105D, '', '', '', '', 0, '');
        CreateSalesLine.InsertDataAndUpdateUnitPrice("Sales Header"."Document Type", "Sales Header"."No.", 2, '70000', '', 5, 7248.48 / 5);
        InsertData(2, '49858585', 19030105D, '', '', '', '', 0, '');
        CreateSalesLine.InsertDataAndUpdateUnitPrice("Sales Header"."Document Type", "Sales Header"."No.", 2, '70000', '', 1, 1232.24);
        // Add new invoices here
        InsertData(3, '10000', 19030115D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1968-S', XRED, 2, '1103000', '', '');

        InsertData(3, '20000', 19030117D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1896-S', XGREEN, 1, '1103000', '', '');

        InsertData(3, '20000', 19030120D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '766BC-C', XGREEN, 1, '1103000', '', '');

        InsertData(3, '47563218', 19030127D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '766BC-C', XGREEN, 1, '1103000', '', '');

        InsertData(3, '49633663', 19030120D, '', '', '', '', 0, '');
        CreateSalesLine.InsertData("Sales Header"."Document Type", "Sales Header"."No.", 2, '1896-S', XRED, 1, '1103000', '', '');
        // Add new credit memos here
    end;

    var
        DemoSetup: Record "Demo Data Setup";
        CurrencyExchRate: Record "Currency Exchange Rate";
        "Sales Header": Record "Sales Header";
        CreateSalesLine: Codeunit "Create Sales Line";
        CA: Codeunit "Make Adjustments";
        i: Integer;
        "Date Displacement": Text[1];
        XRED: Label 'RED';
        XBLUE: Label 'BLUE';
        XGREEN: Label 'GREEN';
        XYELLOW: Label 'YELLOW';
        XTERRY: Label 'TERRY';
        XMILES: Label 'MILES';
        XAssemblingFurnitureJanuary: Label 'Assembling Furniture, January';
        XCLE: Label 'CLE';
        XITE: Label 'ITE';
        XMAT: Label 'MAT';
        XFA: Label 'FA';
        XLINA: Label 'LINA';
        XLIFT: Label 'LIFT';
        XMartyHorst: Label 'Marty Horst';
        XMARTY: Label 'MARTY';
        XLinaTownsend: Label 'Lina Townsend';
        XLiftforfurniture: Label 'Lift for furniture';
        XSALES: Label 'SALES';
        XB2JRUR: Label 'B2JRUR';
        LY: Code[2];
        CY: Code[2];
        XItemSelling: Label 'Item selling Inv. 07/001_%1';
        XItemSelling2: Label 'Item selling Inv. 3_%1';
        XServRentPayOct: Label 'Service selling rent payment for october';
        XServRentPayNov: Label 'Service selling rent payment for november';
        XServRentPayDec: Label 'Service selling rent payment for december';
        XServStorDec: Label 'Serv. selling storage for december';
        XSpecClInv: Label 'Spec.clothes selling Inv. 10_%1';
        XSell4Comp: Label 'Selling of 4 comp. "Cronus +"';
        XComputer: Label 'Computer';
        XSellFA12: Label 'Selling FA-12 sale contract from 11.01.08';

    procedure InsertData("Document Type": Integer; "Sell-to Customer No.": Code[20]; "Posting Date": Date; "Posting Description": Text[50]; Dim2Value: Code[20]; Dim7Value: Code[20]; Dim8Value: Code[20]; "Applies-to Doc. Type": Integer; "Applies-to Doc. No.": Code[20])
    var
        InterfaceBasisData: Codeunit "Interface Basis Data";
    begin
        Clear("Sales Header");
        "Sales Header".Validate("Document Type", "Document Type");
        "Sales Header".Validate("No.", '');
        "Sales Header"."Posting Date" := CA.AdjustDate("Posting Date");
        "Sales Header".Insert(true);
        "Sales Header".Validate("Sell-to Customer No.", "Sell-to Customer No.");
        "Sales Header".Validate("Posting Date");
        "Sales Header".Validate("Order Date", CA.AdjustDate("Posting Date"));
        "Sales Header".Validate("Shipment Date", CA.AdjustDate("Posting Date"));
        "Sales Header".Validate("Document Date", CA.AdjustDate("Posting Date"));
        "Sales Header"."Currency Factor" :=
          CurrencyExchRate.ExchangeRate(WorkDate(), "Sales Header"."Currency Code");

        if "Sales Header"."Shipping Agent Code" = '' then begin
            "Date Displacement" := CopyStr("Sales Header"."No.", StrLen("Sales Header"."No."), 1);
            if not ("Date Displacement" in ['1', '3', '5', '7', '9'])
            then begin // Not Partial Shipment (Set defined in CodeUnit 101901)
                i := i + 1;
                case i of
                    1:
                        SetPackage('DHL', '4561900081');
                    2:
                        SetPackage('UPS', '35505881957');
                    3:
                        SetPackage('DHL', '4515543524');
                    4:
                        SetPackage('UPS', '35531791111');
                    5:
                        SetPackage('DHL', '4561986030');
                    6:
                        SetPackage('UPS', '35531791102');
                    7:
                        SetPackage('DHL', '4363648774');
                    8:
                        SetPackage('DHL', '4457864736');
                    9:
                        SetPackage('DHL', '6040558366');
                    10:
                        SetPackage('DHL', '4430706862');
                    11:
                        SetPackage('DHL', '4327584111');
                    12:
                        SetPackage('DHL', '8321238321');
                    13:
                        SetPackage('DHL', '4490790441');
                end;
            end;
        end;

        "Sales Header".Validate("Applies-to Doc. Type", "Applies-to Doc. Type");
        "Sales Header".Validate("Applies-to Doc. No.", "Applies-to Doc. No.");

        if "Posting Description" <> '' then
            "Sales Header"."Posting Description" :=
              StrSubstNo(
                "Posting Description",
                CA.AdjustDate("Posting Date"));

        "Sales Header".Validate("Shortcut Dimension 1 Code", XSALES);
        "Sales Header".Validate("Shortcut Dimension 2 Code", Dim2Value);
        InterfaceBasisData.AddDocDimValue("Sales Header"."Dimension Set ID", 7, Dim7Value);
        InterfaceBasisData.AddDocDimValue("Sales Header"."Dimension Set ID", 8, Dim8Value);
        "Sales Header".Modify();
    end;

    procedure SetPackage("Shipping Agent Code": Code[10]; "Package Tracking No.": Text[50])
    begin
        "Sales Header"."Shipping Agent Code" := "Shipping Agent Code";
        "Sales Header"."Package Tracking No." := "Package Tracking No.";
    end;
}
