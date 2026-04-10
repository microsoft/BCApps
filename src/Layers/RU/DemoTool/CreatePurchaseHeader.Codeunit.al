codeunit 101038 "Create Purchase Header"
{

    trigger OnRun()
    begin
        DemoSetup.Get();
        LY := CopyStr(Format(DemoSetup."Starting Year"), 3, 2);
        CY := IncStr(LY);

        InsertData("Purchase Document Type"::Order, '20000', 19030102D, '5755', '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1964-S', '', XGREEN, 14, 0, 0, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '10000', 19030104D, '23047', '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1964-W', '', XGREEN, 15, 0, 0, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1964-W', '', XBLUE, 25, 0, 0, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '10000', 19030107D, '23587', '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70060', '', XRED, 250, 0, 0, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70060', '', XBLUE, 500, 0, 0, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70011', '', XBLUE, 52, 0, 0, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '38458653', 19030110D, '45885', '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70104', '', XBLUE, 800, 0, 0, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '30000', 19030115D, '563', '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1900-S', '', XYELLOW, 160, 0, 0, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '10000', 19030118D, '24521', '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1924-W', '', XGREEN, 5, 0, 0, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1924-W', '', XYELLOW, 15, 0, 0, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1928-W', '', XGREEN, 20, 0, 0, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1928-W', '', XYELLOW, 41, 0, 0, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '20000', 19030123D, '5966', '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1952-W', '', XBLUE, 7, 0, 0, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1952-W', '', XRED, 6, 0, 0, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '30000', 19030126D, '599', '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1964-W', '', XYELLOW, 8, 0, 0, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1964-W', '', XGREEN, 9, 0, 0, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '10000', 19030128D, '26874', '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1976-W', '', XBLUE, 2, 0, 0, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1976-W', '', XRED, 4, 0, 0, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '47586622', 19030129D, XBTZ009, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1952-W', '', '', 88, 0, 0, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '38654478', 19030129D, '43/3-66', '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1980-S', '', '', 100, 0, 0, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '01863656', 19030116D, XAWE1, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70000', '', '', 2000, 0, 0, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70001', '', '', 2000, 0, 0, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70003', '', '', 500, 0, 0, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '01863656', 19030121D, XAWE2, '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70010', '', '', 25, 0, 0, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '43698547', 19030128D, '2265423', '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70060', '', '', 1000, 0, 0, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '44127914', 19020101D, '18051', '', XAcqOfFAMercedes, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA000010, '', '', 1, 1, 35400, XINS000010, '', '', '');

        InsertData("Purchase Document Type"::Order, '44127914', 19020501D, '21152', '', XAcqOfFAToyoa, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA000020, '', '', 1, 1, 49560, XINS000020, '', '', '');

        InsertData("Purchase Document Type"::Order, '44127914', 19020601D, '24057', '', XAcqOfFAVolkswagen, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA000030, '', '', 1, 1, 17700, XINS000030, '', '', '');

        InsertData("Purchase Document Type"::Order, '44127904', 19020101D, '24365', '', XAcqOfFAConveyerDrive, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA000050, '', '', 1, 1, 7788, XINS000040, '', '', '');

        InsertData("Purchase Document Type"::Order, '44127904', 19020201D, '27116', '', XAcqOfFAConveyerLift, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA000060, '', '', 1, 1, 5324.16, XINS000040, '', '', '');

        InsertData("Purchase Document Type"::Order, '44127904', 19020301D, '35211', '', XAcqOfFAConveyerComputer, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA000070, '', '', 1, 1, 3568.32, XINS000040, '', '', '');

        InsertData("Purchase Document Type"::Order, '44127904', 19020401D, '36668', '', XAcqOfFAFurnitureLift, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA000080, '', '', 1, 1, 4531.2, XINS000040, '', '', '');

        InsertData("Purchase Document Type"::Order, '44127904', 19020201D, '27117', '', XAcqOfFAPanel, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA000090, '', '', 1, 1, 8425.2, XINS000040, '', '', '');

        InsertData("Purchase Document Type"::Order, '46558855', 19030126D, '712001', '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '80100', '', XGREEN, 6, 0, 0, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVSH + '005', 19021002D, '105', '', XContrCCGoodsBicycles, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-021', '', XBLUE, 100, 0, 4800, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVSH + '003', 19021002D, '/', '', XContrCCBuilding, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '001', '', '', 1, 1, 26694100, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVSH + '004', 19021002D, 'AKT', '', XContributionSWBilling, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XNA + '001', '', '', 1, 1, 825900, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '014', 19021003D, '105', '', XAcqItemSouv, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-002', '', XBLUE, 3, 0, 965.19, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-003', '', XBLUE, 3, 0, 27.16, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-004', '', XBLUE, 1, 0, 16.59, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-005', '', XBLUE, 1, 0, 98.28, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-006', '', XBLUE, 1, 0, 22576.26, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-007', '', XBLUE, 1, 0, 13404.66, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-008', '', XBLUE, 1, 0, 14110.17, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-009', '', XBLUE, 1, 0, 756.38, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-010', '', XBLUE, 1, 0, 1923.97, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-011', '', XBLUE, 1, 0, 2516.42, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-012', '', XBLUE, 1, 0, 5194.83, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-013', '', XBLUE, 1, 0, 4045.99, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-014', '', XBLUE, 95, 0, 9.06, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-015', '', XBLUE, 1, 0, 19.04, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-016', '', XBLUE, 1, 0, 19.05, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-017', '', XBLUE, 1, 0, 17.92, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-018', '', XBLUE, 1, 0, 16.58, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-019', '', XBLUE, 1, 0, 16.59, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-020', '', XBLUE, 10, 0, 190.68, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '001', 19021006D, '35', '', XAcqRBPSW, false, 1, XB1RUR + '-' + LY + '-001');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFE + '001', '', '', 1, 1, 65000, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '011', 19021007D, '119', '', XAcqHWMount, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XOM + '-07/001', '', XBLUE, 1, 0, 398400, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XOM + '-07/002', '', XBLUE, 1, 0, 141600, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XOM + '-07/003', '', XBLUE, 1, 0, 192000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XOM + '-07/004', '', XBLUE, 1, 0, 66000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XOM + '-07/005', '', XBLUE, 1, 0, 163404, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XOM + '-07/006', '', XBLUE, 1, 0, 127200, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '008', 19021015D, '461', '', XAcqAssTelDev, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XMAT + '-004', '', XBLUE, 2, 0, 7401.59, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '008', 19021015D, '462', '', XAcqFAATS, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '002', '', '', 1, 1, 373408.16, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '004', 19021018D, '55', '', XAcqMPZOverall, false, 1, XB1RUR + '-' + LY + '-004');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XMAT + '-002', '', XBLUE, 60, 0, 250, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XMAT + '-003', '', XBLUE, 30, 0, 15, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '005', 19021020D, '731', '', XMountWork, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '027', '', '', 1, 1, 60000, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '006', 19021025D, '20', '', XAcqFAComp, false, 1, XB1RUR + '-' + LY + '-007');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '003', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '004', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '005', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '006', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '007', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '008', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '009', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '010', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '011', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '012', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '017', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '018', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '019', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '020', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '021', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '022', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '023', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '024', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '025', '', '', 1, 1, 25000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '026', '', '', 1, 1, 25000, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '01863656', 19021027D, '157', '', XEnteredItem157, false, 1, XB1JUSD + '-' + LY + '-002');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-022', '', XBLUE, 54244, 0, 0.1, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-023', '', XBLUE, 36036, 0, 0.15, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-024', '', XBLUE, 10091, 0, 0.23, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-025', '', XBLUE, 3027, 0, 0.29, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-026', '', XBLUE, 13882, 0, 0.6, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '013', 19021027D, '157', '', XCustPaym, false, 1, XB2RUR + '-' + LY + '-003');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 5, XCUSTDUTY,
          XCustDuty2, '', 1, 0, 75296.96, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 5, XCUSTFEE,
          XCustFee2, '', 1, 0, 34110.68, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '68-4420',
          XTAXSCD, '', 1, 0, 192647.71, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '01863656', 19021030D, '1416', '', XEnteredItem1416, false, 1, XB1JUSD + '-' + LY + '-002');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-022', '', XBLUE, 60113, 0, 0.1, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-023', '', XBLUE, 44451, 0, 0.15, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-024', '', XBLUE, 10091, 0, 0.23, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-025', '', XBLUE, 3027, 0, 0.29, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '013', 19021030D, '1416', '', XCustPaym1416, false, 1, XB2RUR + '-' + LY + '-003');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 5, XCUSTDUTY,
          XCustDuty3, '', 1, 0, 87162.71, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '68-4420',
          XTAXSCD2, '', 1, 0, 170602.17, '', '', '', '');


        InsertData("Purchase Document Type"::Order, XVLE + '003', 19021031D, '211', '', XOfficeRent, false, 1, XB1RUR + '-' + LY + '-005');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9900',
          XOfficeRentOct, '', 1, 0, 54674.69, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '015', 19021031D, '835', '', XUtil, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-1000',
          XCommOct, '', 1, 0, 22702.97, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '002', 19021101D, '121', '', XAcqAssetKKM, false, 1, XB1RUR + '-' + LY + '-002');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XMAT + '-005', '', XBLUE, 1, 0, 10000, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '016', 19021109D, '238', '', XAcqFurn, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '013', '', '', 1, 1, 47810.34, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '014', '', '', 1, 1, 41352.85, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '015', '', '', 1, 1, 56627.31, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '016', 19021110D, '239', '', XAcqAssetFurn, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XMAT + '-006', '', XBLUE, 2, 0, 9810, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XMAT + '-007', '', XBLUE, 1, 0, 16367, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 5, XTRANSPORT,
          XTranspExp, '', 1, 0, 4267.28814, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '008', 19021116D, '588', '', XAcqAddHardATS, false, 0, '');
        CreatePurchLine.InsertData2("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '002', '', '', 1, 1, 897.21, '', '', XUPGRADING, '', '');
        CreatePurchLine.InsertData2("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '002', '', '', 1, 1, 657.12, '', '', XUPGRADING, '', '');
        CreatePurchLine.InsertData2("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA + '002', '', '', 1, 1, 53839.6, '', '', XUPGRADING, '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '017', 19021130D, '16', '', XAcqIAAuthority, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XNA + '002', '', '', 1, 1, 5000000, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '003', 19021130D, '311', '', XOfficeRentNovInv, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9900',
          XOfficeRentNov, '', 1, 0, 105932.2, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '015', 19021130D, '1020', '', XUtilNov, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-1000',
          XCommNov, '', 1, 0, 24973.27, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '010', 19021213D, '97', '', XServRevalBuildInv, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '91-2330',
          XServRevalBuild, '', 1, 0, 45000, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '009', 19021216D, '17', '', XServRegSpecSW, false, 1, XB1RUR + '-' + LY + '-033');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '08-3300',
          XServRegSpecSW, '', 1, 0, 10000, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '012', 19021220D, '56', '', XExpBuildRepInv, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '44-2910',
          XExpBuildRep, '', 1, 0, 320000, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '012', 19021225D, '50', '', XBuildConstInv, false, 1, XB2RUR + '-' + LY + '-001');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '08-3300',
          XBuildConst, '', 1, 0, 10000000, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '015', 19021231D, '1200', '', XUtilDec, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-1000',
          XCommDec, '', 1, 0, 32465.25, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '003', 19021231D, '511', '', XOfficeRentDecInv, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9900',
          XOfficeRentDec, '', 1, 0, 105932.2, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVOB + '001', 19021201D, '173', '', XFurnStorage, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XITE + '-027', '', XSTORAGE, 10, 0, 75000, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVOB + '002', 19021015D, '715', '', XBuildRentRec, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFAOB + '001', '', '', 1, 1, 750000, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '003', 19030115D, '11', '', XOfficeRentJanInv, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9900',
          XOfficeRentJan, '', 1, 0, 52966.1, '', '', '', '');

        InsertData("Purchase Document Type"::Order, XVLE + '015', 19030131D, '51', '', XUtilJan, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-1000',
          XCommJan, '', 1, 0, 30841.98, '', '', '', '');

        InsertData("Purchase Document Type"::Order, '20000', 19030102D, '5756', '', XAcquisitionOfGoods, false, 0, '');
        CreatePurchLine.InsertDataAndUpdateUnitOfMeasure("Purchase Document Type"::Order, "Purchase Header"."No.", 2, '1896-S', XGREEN, 2, CreateUnitOfMeasure.GetBoxUnitOfMeasureCode());
        // Add new orders here
        InsertData("Purchase Document Type"::Invoice, '44127904', 19020131D, '25760', '', XTunOfFAConveyerDrive, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA000050, '', '', 1, 1, 2360, '', '', '', '');

        InsertData("Purchase Document Type"::Invoice, '44127904', 19020228D, '35111', '', XRunOfFAConveyerLift, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA000060, '', '', 1, 1, 708, '', '', '', '');

        InsertData("Purchase Document Type"::Invoice, '44127904', 19020430D, '37552', '', XTunOfFAConveyerComputer, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA000070, '', '', 1, 1, 472, '', '', '', '');

        InsertData("Purchase Document Type"::Invoice, '44127904', 19020531D, '38661', '', XServOfFAFurnitureLift, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '20-2910', '', '', 1, 0, 1416, '', '', '', '');

        InsertData("Purchase Document Type"::Invoice, '44127904', 19020228D, '35112', '', XTunOfFAPanel, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 4, XFA000090, '', '', 1, 1, 2360, '', '', '', '');

        InsertData("Purchase Document Type"::Invoice, '44127914', 19020228D, '20053', '', XServOfFAMercedes, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9100', '', '', 1, 0, 2360, '', '', '', '');

        InsertData("Purchase Document Type"::Invoice, '44127914', 19020531D, '24054', '', XServOfFAToyota, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9100', '', '', 1, 0, 708, '', '', '', '');

        InsertData("Purchase Document Type"::Invoice, '44127914', 19020630D, '36455', '', XServOfFAVolkswagen, false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '20-2910', '', '', 1, 0, 472, '', '', '', '');

        InsertData("Purchase Document Type"::Invoice, '71-001', 19021003D, '', '', XAcqStationery, true, 0, '');
        ModifyData("Purchase Header"."Document Type", XAcqStationery, 1, 2, "Purchase Header"."No.");
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XMAT + '-008', '', XBLUE, 1, 0, 3969, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XMAT + '-009', '', XBLUE, 1, 0, 450, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, XMAT + '-010', '', XBLUE, 1, 0, 95, '', '', '', '');

        InsertData("Purchase Document Type"::Invoice, '71-001', 19021120D, '', '', XTravelExp, true, 0, '');
        ModifyData("Purchase Header"."Document Type", XTravelExp, 4, 7, "Purchase Header"."No.");

        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9200',
          XHotelNevskiy, '', 1, 0, 6000, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9200',
          XTicketMosPeter, '', 1, 0, 1933, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9200',
          XTicketPeterMoscow, '', 1, 0, 1145, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9200',
          XFee, '', 1, 0, 400, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9200',
          XDaily5, '', 5, 0, 700, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9995',
          XDailyExc, '', 5, 0, 300, '', '', '', '');


        InsertData("Purchase Document Type"::Invoice, '71-001', 19021122D, '', '', XBusTripOmsk, true, 0, '');
        ModifyData("Purchase Header"."Document Type", XBusTripOmsk, 6, 9, "Purchase Header"."No.");
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9200',
          XAirMoscowOmsk, '', 1, 0, 12758.13, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9200',
          XAirOmskNovo, '', 1, 0, 4486.6, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9200',
          XServiceCharge, '', 1, 0, 200, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9200',
          XPaymentLuggage, '', 1, 0, 405, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9200',
          XServiceCharge, '', 1, 0, 278.87, '', '', '', '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9200',
          XDaily11700, '', 1, 0, 7700, '', '', '', '');

        InsertData("Purchase Document Type"::Invoice, '71-001', 19021004D, '', '', XPaymGMSuppl71001, true, 0, '');
        ModifyData("Purchase Header"."Document Type", XPaymGMSupp, 3, 2, "Purchase Header"."No.");
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 1, '26-9900',
          XPaymRegeton, '', 1, 0, 83163.19, '', '', '', '');
        CreatePurchLine.AddEmplPurchase("Purchase Header"."Document Type", "Purchase Header"."No.", XVLE + '014');

        InsertDataSetVAT("Purchase Document Type"::Invoice, '33299199', 19030122D, '123401', XBANKTxt, true);
        CreatePurchLine.InsertDataAndUpdateUnitCost("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70000', '', 10, 1879.83 / 10);
        InsertDataSetVAT("Purchase Document Type"::Invoice, '33299199', 19030122D, '123402', XBANKTxt, true);
        CreatePurchLine.InsertDataAndUpdateUnitCost("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70000', '', 3, 563.95 / 3);
        InsertDataSetVAT("Purchase Document Type"::Invoice, '33299199', 19030122D, '123403', XBANKTxt, true);
        CreatePurchLine.InsertDataAndUpdateUnitCost("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70000', '', 2, 375.96 / 2);
        InsertDataSetVAT("Purchase Document Type"::Invoice, '31580305', 19030122D, 'INV4444', XBANKTxt, true);
        CreatePurchLine.InsertDataAndUpdateUnitCost("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70000', '', 6, 1127.89 / 6);
        InsertDataSetVAT("Purchase Document Type"::Invoice, '32554455', 19030122D, 'REF9999', XBANKTxt, true);
        CreatePurchLine.InsertDataAndUpdateUnitCost("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70000', '', 5, 939.91 / 5);
        InsertDataSetVAT("Purchase Document Type"::Invoice, '33012999', 19030126D, '88888', XBANKTxt, true);
        CreatePurchLine.InsertDataAndUpdateUnitCost("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70000', '', 12, 2255.78 / 12);
        InsertDataSetVAT("Purchase Document Type"::Invoice, '49454647', 19030126D, '0000004444', XBANKTxt, true);
        CreatePurchLine.InsertDataAndUpdateUnitCost("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70000', '', 30, 5639.46 / 30);
        InsertDataSetVAT("Purchase Document Type"::Invoice, '43589632', 19030126D, 'BBB-555', XBANKTxt, true);
        CreatePurchLine.InsertDataAndUpdateUnitCost("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70000', '', 25, 4699.55 / 25);
        // Add new invoices here
        InsertData("Purchase Document Type"::"Credit Memo", '30000', 19030112D, XKR950201, '', '', false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '1968-W', '', '', 40, 0, 30150, '', '', '', '');

        InsertData("Purchase Document Type"::"Credit Memo", '01863656', 19030125D, 'AWE-C3', '', '', false, 0, '');
        CreatePurchLine.InsertData("Purchase Header"."Document Type", "Purchase Header"."No.", 2, '70003', '', '', 200, 0, 25.98, '', '', '', '');

        InsertData("Purchase Document Type"::"Credit Memo", XVOB + '001', 19030115D, '87435', '', '%1 %2', false, 0, '');
        CreatePurchLine.InsertData("Purchase Document Type"::"Credit Memo", "Purchase Header"."No.", 4, XFAOB + '001', '', '', 1, 1, 750000, '', '', '', '');
        // Add new credit memos here
    end;

    var
        DemoSetup: Record "Demo Data Setup";
        "Purchase Header": Record "Purchase Header";
        CA: Codeunit "Make Adjustments";
        CreateUnitOfMeasure: Codeunit "Create Unit of Measure";
        XBTZ009: Label 'BTZ-009';
        XAWE1: Label 'AWE1';
        XAWE2: Label 'AWE2';
        XKR950201: Label 'KR95-02-01';
        XVSH: Label 'VSH';
        XVLE: Label 'VLE';
        XVOB: Label 'VOB';
        CreatePurchLine: Codeunit "Create Purchase Line";
        XGREEN: Label 'GREEN';
        XBLUE: Label 'BLUE';
        XRED: Label 'RED';
        XYELLOW: Label 'YELLOW';
        XFA000010: Label 'FA000010';
        XFA000020: Label 'FA000020';
        XFA000030: Label 'FA000030';
        XFA000050: Label 'FA000050';
        XFA000060: Label 'FA000060';
        XFA000070: Label 'FA000070';
        XFA000080: Label 'FA000080';
        XINS000010: Label 'INS000010';
        XINS000020: Label 'INS000020';
        XFA000090: Label 'FA000090';
        XINS000030: Label 'INS000030';
        XINS000040: Label 'INS000040';
        XITE: Label 'ITE';
        XMAT: Label 'MAT';
        XFA: Label 'FA';
        XNA: Label 'IA';
        XFE: Label 'FE';
        XOM: Label 'OM';
        XCUSTDUTY: Label 'CUSTDUTY';
        XCUSTFEE: Label 'CUSTCHARGE';
        XTRANSPORT: Label 'TRANCHARGE';
        XFAOB: Label 'FAOB';
        XSTORAGE: Label 'STORAGE';
        XB1RUR: Label 'B1RUR';
        XB2RUR: Label 'B2RUR';
        XB1JUSD: Label 'B1JUSD';
        XUPGRADING: Label 'UPGRADING';
        LY: Code[2];
        CY: Code[2];
        XAcquisitionOfGoods: Label 'Acquisition of goods';
        XAcqOfFAMercedes: Label 'Acquisition of FA - Mercedes 300';
        XAcqOfFAToyoa: Label 'Acquisition of FA - Toyota Supra 3.0';
        XAcqOfFAVolkswagen: Label 'Acquisition of FA - Volkswagen Transporter';
        XAcqOfFAConveyerDrive: Label 'Acquisition of FA - Conveyer Drive';
        XAcqOfFAConveyerLift: Label 'Acquisition of FA - Conveyer Lift';
        XAcqOfFAConveyerComputer: Label 'Acquisition of FA - Conveyer Computer';
        XAcqOfFAFurnitureLift: Label 'Acquisition of FA - Furniture Lift';
        XAcqOfFAPanel: Label 'Acquisition of FA - Panel';
        XTunOfFAConveyerDrive: Label 'Tuning of FA - Conveyer Drive';
        XRunOfFAConveyerLift: Label 'Tuning of FA - Conveyer Lift';
        XTunOfFAConveyerComputer: Label 'Tuning of FA - Conveyer Computer';
        XServOfFAFurnitureLift: Label 'Service of FA - Furniture Lift';
        XTunOfFAPanel: Label 'Tuning of FA - Panel';
        XServOfFAMercedes: Label 'Service of FA - Mercedes 300';
        XServOfFAToyota: Label 'Service of FA - Toyota Supra 3.0';
        XServOfFAVolkswagen: Label 'Service of FA - Volkswagen Transporter';
        XContrCCBuilding: Label 'Contribution to CC building - st. Koroleva, h.14';
        XContributionSWBilling: Label 'Contribution to the CC excl. law - Billing SW';
        XAcqItemSouv: Label 'Acquisition of item-souvenirs sale Inv. 105';
        XAcqRBPSW: Label 'Acq. of RBP-SW Domino Inv. 35';
        XAcqHWMount: Label 'Acq. of hardware to mount Inv. 119';
        XAcqAssTelDev: Label 'Acq. of assets<20000 tel. dev. Inv. 461';
        XAcqFAATS: Label 'Acq. of FA-ATS Inv. 462';
        XAcqMPZOverall: Label 'Acq. MPZ-overall ShipDoc 55';
        XMountWork: Label 'Mount work FA-conveyor, act';
        XAcqFAComp: Label 'Acq. FA-computers Inv. 731';
        XEnteredItem157: Label 'Entered items SCD0000157, tubes, cloth';
        XCustPaym: Label 'Custom payments SCD0000157';
        XEnteredItem1416: Label 'Entered items SCD0001416, tubes, cloth';
        XCustPaym1416: Label 'Custom payments SCD0001416';
        XOfficeRent: Label 'Office rent october Inv. 211';
        XUtil: Label 'Utilities october Inv. 835';
        XAcqAssetKKM: Label 'Acq. of assets up to 20000 rub. - KKM Inv. 121';
        XAcqFurn: Label 'Acq. of FA-furniture Inv. 238';
        XAcqAssetFurn: Label 'Acq. of assets up to 20000rub.-furnit. Inv. 239';
        XAcqAddHardATS: Label 'Acq. of add. hardware for ATS Inv. 588';
        XAcqIAAuthority: Label 'Acq. IA-authority act 17';
        XOfficeRentNovInv: Label 'Office rent november Inv. 311';
        XUtilNov: Label 'Utilities november Inv. 1020';
        XServRevalBuildInv: Label 'Service revaluation of buildings Inv. 97';
        XServRegSpecSW: Label 'Service registration spec. SW, act';
        XExpBuildRepInv: Label 'Expenses building repair Inv. 56';
        XBuildConstInv: Label 'Building and constr. work Inv. 50';
        XUtilDec: Label 'Utilities december Inv. 1200';
        XOfficeRentDecInv: Label 'Office rent december Inv. 511';
        XFurnStorage: Label 'Furniture storage receive';
        XBuildRentRec: Label 'Building rent receive';
        XOfficeRentJanInv: Label 'Office rent january Inv. 11';
        XUtilJan: Label 'Utilities january Inv. 51';
        XAcqStationery: Label 'Acq. of stationery';
        XTravelExp: Label 'Travel expenses';
        XBusTripOmsk: Label 'Bus. trip to Omsk-Novosibirsk';
        XPaymGMSuppl71001: Label 'Paym. GM supplier (71-001)';
        XPaymGMSupp: Label 'Paym. GM supplier';
        XCustDuty2: Label 'Cust. duty SCD 10124090/160107/0000157';
        XCustFee2: Label 'Cust. fee SCD 10124090/160107/0000157';
        XTAXSCD: Label 'TAX SCD 10124090/160107/0000157';
        XCustDuty3: Label 'Cust. duty SCD 10124090/140307/0001416';
        XTAXSCD2: Label 'TAX SCD 10124090/140307/0001416';
        XOfficeRentOct: Label 'Office rent october';
        XCommOct: Label 'Communal october';
        XTranspExp: Label 'Transport expenses';
        XOfficeRentNov: Label 'Office rent november';
        XCommNov: Label 'Communal november';
        XServRevalBuild: Label 'Serv. revaluate building';
        XExpBuildRep: Label 'Expenses building repair';
        XBuildConst: Label 'Building and constr. work';
        XCommDec: Label 'Communal december';
        XOfficeRentDec: Label 'Office rent december';
        XOfficeRentJan: Label 'Office rent january';
        XCommJan: Label 'Communal january';
        XHotelNevskiy: Label 'Hotel "Nevskiy club"-residence';
        XTicketMosPeter: Label 'Ticket Moscow-St.Petersburg';
        XTicketPeterMoscow: Label 'Ticket St.Petersburg-Moscow';
        XFee: Label 'Fee';
        XDaily5: Label 'Daily norm (5 days)';
        XDailyExc: Label 'Daily excess (5 days)';
        XAirMoscowOmsk: Label 'Air-icket Moscow-Omsk, Novosibirsk-Moscow';
        XAirOmskNovo: Label 'Air-ticket Omsk-Novosibirsk';
        XServiceCharge: Label 'Service charge';
        XPaymentLuggage: Label 'Payment luggage';
        XDaily11700: Label 'Daily norm (11d.*700rub.)';
        XPaymRegeton: Label 'Payment "Regeton" TMC Inv. 105';
        XContrCCGoodsBicycles: Label 'Contribution to the CC goods - Bicycles';
        XBANKTxt: Label 'BANK', Comment = 'Has to be translated exactly the same as global constant 1005 (XBANK) from COD101289 (Create Payment Method)';

    procedure InsertData("Document Type": Enum "Purchase Document Type"; "Buy-from Vendor No.": Code[20]; "Posting Date": Date; "Vendor Invoice No.": Code[20]; "Payment Method": Code[10]; "Posting Description": Text[50]; EmplPurchase: Boolean; "Applies-to Doc. Type": Integer; "Applies-to Doc. No.": Code[20]): Code[20]
    begin
        Clear("Purchase Header");
        "Purchase Header".Validate("Empl. Purchase", EmplPurchase);
        "Purchase Header".Validate("Document Type", "Document Type");
        "Purchase Header".Validate("No.", '');
        "Purchase Header"."Posting Date" := CA.AdjustDate("Posting Date");
        "Purchase Header".Insert(true);
        "Purchase Header".Validate("Buy-from Vendor No.", "Buy-from Vendor No.");
        "Purchase Header".Validate("Posting Date");
        "Purchase Header".Validate("Order Date", CA.AdjustDate("Posting Date"));
        "Purchase Header".Validate("Expected Receipt Date", CA.AdjustDate("Posting Date"));
        "Purchase Header".Validate("Document Date", CA.AdjustDate("Posting Date"));
        case "Document Type" of
            "Document Type"::Order:
                begin
                    "Purchase Header".Validate("Vendor Invoice No.", "Vendor Invoice No.");
                    "Purchase Header".Validate("Promised Receipt Date", "Purchase Header"."Expected Receipt Date");
                end;
            "Document Type"::Invoice:
                "Purchase Header".Validate("Vendor Invoice No.", "Vendor Invoice No.");
            "Document Type"::"Credit Memo":
                "Purchase Header".Validate("Vendor Cr. Memo No.", "Vendor Invoice No.");
        end;

        if "Payment Method" <> '' then
            "Purchase Header".Validate("Payment Method Code", "Payment Method");

        "Purchase Header".Validate("Applies-to Doc. Type", "Applies-to Doc. Type");
        "Purchase Header".Validate("Applies-to Doc. No.", "Applies-to Doc. No.");

        if "Posting Description" <> '' then
            "Purchase Header"."Posting Description" :=
              CopyStr(
                StrSubstNo(
                  "Posting Description",
                  "Purchase Header"."Document Type",
                  "Purchase Header"."No.",
                  CA.AdjustDate("Purchase Header"."Posting Date")),
                1,
                MaxStrLen("Purchase Header"."Posting Description"));

        "Purchase Header".Modify();

        exit("Purchase Header"."No.");
    end;

    procedure ModifyData(DocumentType: Enum "Purchase Document Type"; AdvancePurpose: Text[30]; NoOfDocuments: Integer; NoOfPages: Integer; VendorInvoiceNo: Code[20])
    begin
        "Purchase Header"."Advance Purpose" := AdvancePurpose;
        "Purchase Header"."No. of Documents" := NoOfDocuments;
        "Purchase Header"."No. of Pages" := NoOfPages;
        case DocumentType of
            DocumentType::Order, DocumentType::Invoice:
                "Purchase Header".Validate("Vendor Invoice No.", VendorInvoiceNo);
            DocumentType::"Credit Memo":
                "Purchase Header".Validate("Vendor Cr. Memo No.", VendorInvoiceNo);
        end;
        if "Purchase Header"."Empl. Purchase" then begin
            "Purchase Header"."Posting No. Series" := "Purchase Header"."No. Series";
            "Purchase Header"."Receiving No. Series" := "Purchase Header"."No. Series";
            "Purchase Header"."Posting No." := VendorInvoiceNo;
            "Purchase Header"."Receiving No." := VendorInvoiceNo;
        end;
        "Purchase Header".Modify();
    end;

    local procedure InsertDataSetVAT(DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20]; PostingDate: Date; VendorInvoiceNo: Code[20]; PaymentMethod: Code[10]; InclVAT: Boolean)
    begin
        InsertData(DocumentType, BuyFromVendorNo, PostingDate, VendorInvoiceNo, PaymentMethod, '', false, 0, '');
        "Purchase Header".Validate("Prices Including VAT", InclVAT);
        "Purchase Header".Modify(true);
    end;
}

