codeunit 101081 "Create Gen. Journal Line"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        "Entry Balance" := 0;
        "Exactly Balanced" := false;
        InsertDailyEntry(
          XPURCH, 2, '49454647', 19030102D, 2, '2701', 'VAG - Jürgensen',
          0, '997120', -2300 / 0.8902428, '', '', 0, '', 19030202D);
        InsertDailyEntry(
          XPURCH, 2, '49454647', 19030103D, 2, '2702', 'VAG - Jürgensen',
          0, '997120', -1500 / 0.8902428, '', '', 0, '', 19030203D);
        InsertDailyEntry(
          XPURCH, 2, '49454647', 19030107D, 2, '2703', 'VAG - Jürgensen',
          0, '997120', -3500 / 0.8902428, '', '', 0, '', 19030207D);
        InsertDailyEntry(
          XPURCH, 2, '49454647', 19030115D, 2, '2704', 'VAG - Jürgensen',
          0, '997120', -2600 / 0.8902428, '', '', 0, '', 19030215D);
        InsertDailyEntry(
          XPURCH, 2, '49454647', 19030120D, 3, '2705', 'VAG - Jürgensen',
          0, '997120', 1100 / 0.8902428, '', '', 0, '', 19030220D);
        InsertDailyEntry(
          XPURCH, 2, '49494949', 19030104D, 2, '2706', 'KKA Büromaschinen Gmbh',
          0, '997120', -3300 / 0.8902428, '', '', 0, '', 19030204D);
        InsertDailyEntry(
          XPURCH, 2, '49494949', 19030107D, 2, '2707', 'KKA Büromaschinen Gmbh',
          0, '997120', -1400 / 0.8902428, '', '', 0, '', 19030204D);
        InsertDailyEntry(
          XPURCH, 2, '49494949', 19030115D, 2, '2708', 'KKA Büromaschinen Gmbh',
          0, '997120', -2700 / 0.8902428, '', '', 0, '', 19030215D);
        InsertDailyEntry(
          XPURCH, 2, '49494949', 19030116D, 2, '2709', 'KKA Büromaschinen Gmbh',
          0, '997120', -5600 / 0.8902428, '', '', 0, '', 19030216D);
        InsertDailyEntry(
          XPURCH, 2, '49494949', 19030120D, 3, '2710', 'KKA Büromaschinen Gmbh',
          0, '997120', 1900 / 0.8902428, '', '', 0, '', 19030220D);

        InsertDailyEntry(
          XSALES, 1, '49525252', 19030106D, 2, '2801', 'Beef House',
          0, '996120', 2500 / 0.8902428, XSALES, '', 0, '', 19030206D);
        InsertDailyEntry(
          XSALES, 1, '49525252', 19030107D, 2, '2802', 'Beef House',
          0, '996120', 2000 / 0.8902428, XSALES, '', 0, '', 19030206D);
        InsertDailyEntry(
          XSALES, 1, '49525252', 19030109D, 2, '2803', 'Beef House',
          0, '996120', 3500 / 0.8902428, XSALES, '', 0, '', 19030209D);
        InsertDailyEntry(
          XSALES, 1, '49525252', 19030120D, 2, '2804', 'Beef House',
          0, '996120', 2200 / 0.8902428, XSALES, '', 0, '', 19030220D);
        InsertDailyEntry(
          XSALES, 1, '49525252', 19030125D, 3, '2805', 'Beef House',
          0, '996120', -1000 / 0.8902428, XSALES, '', 0, '', 19030225D);
        InsertDailyEntry(
          XSALES, 1, '49633663', 19030121D, 1, '2806', 'Autohaus Mielberg KG',
          0, '996120', -1045.556 / 0.8902428, XSALES, '', 0, '', 19030221D);
        InsertDailyEntry(
          XSALES, 1, '49633663', 19030123D, 6, '2807', 'Autohaus Mielberg KG',
          3, XWWBEUR, 729.463 / 0.8902428, XSALES, '', 0, '', 19030223D);
        InsertDailyEntry(
          XSALES, 1, '49633663', 19030124D, 2, '2808', 'Autohaus Mielberg KG',
          0, '996120', 4000 / 0.8902428, XSALES, '', 0, '', 19030224D);
        InsertDailyEntry(
          XSALES, 1, '49633663', 19030125D, 2, '2809', 'Autohaus Mielberg KG',
          0, '996120', 2500 / 0.8902428, XSALES, '', 0, '', 19030225D);
        InsertDailyEntry(
          XSALES, 1, '49633663', 19030126D, 3, '2810', 'Autohaus Mielberg KG',
          0, '996120', -500 / 0.8902428, XSALES, '', 0, '', 19030226D);
        VATDocumentNo := StrSubstNo(VATDocNumber, XSET4Q, (DemoDataSetup."Starting Year" - 1));
        InsertDailyEntry(
          XGENERAL, 0, '995310', 19020201D, 0, VATDocumentNo, XVATSettlement,
          0, '995780', -104423.13, '', '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998120', 19030105D, 0, '2588', XCleaningExpensesDec,
          0, '992910', 172.86, '', '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998110', 19030105D, 0, '2589', XRent1stQuarter,
          3, XWWBOPERATING, 234.19, '', '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998130', 19030105D, 0, '2590', XWarehouseWindowReplacement,
          0, '992910', 234.19, '', '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998420', 19030105D, 0, '2591', XDinnerwithMarsholmFurniture,
          0, '992910', 234.19, XSALES, '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998530', 19030105D, 0, '2592', XNewTires,
          3, XWWBOPERATING, 49.96, XSALES, XTOYOTA, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 2, '10000', 19030111D, 1, '2593', XPayment,
          3, XWWBOPERATING, 0.0, '', '', 2, '5437', 19030111D);
        InsertDailyEntry(
          XGENERAL, 1, '20000', 19030112D, 1, '2594', XPayment,
          3, XWWBOPERATING, 0.0, '', '', 2, '00-2', 19030112D);
        InsertDailyEntry(
          XGENERAL, 1, '20000', 19030112D, 1, '2594', XPayment,
          3, XWWBOPERATING, 0.0, '', '', 2, '00-5', 19030112D);
        InsertDailyEntry(
          XGENERAL, 1, '20000', 19030112D, 1, '2594', XPayment,
          3, XWWBOPERATING, 0.0, '', '', 2, '00-12', 19030112D);
        InsertDailyEntry(
          XGENERAL, 0, '998710', 19030114D, 0, '2595', XSalariesWeek1AND2,
          0, '', 864.3, XSALES, '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998710', 19030114D, 0, '2595', XSalariesWeek1AND2,
          0, '', 259.29, XPROD, '', 0, '', 0D);
        "Exactly Balanced" := true;
        InsertDailyEntry(
          XGENERAL, 3, XWWBOPERATING, 19030114D, 0, '2595', XSalariesWeek1AND2,
          0, '', -1123.59, '', '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 1, '10000', 19030115D, 1, '2596', XPayment,
          3, XWWBOPERATING, 0.0, '', '', 2, '00-1', 19030115D);
        InsertDailyEntry(
          XGENERAL, 1, '10000', 19030115D, 1, '2596', XPayment,
          3, XWWBOPERATING, 0.0, '', '', 2, '00-3', 19030115D);
        InsertDailyEntry(
          XGENERAL, 1, '10000', 19030115D, 1, '2596', XPayment,
          3, XWWBOPERATING, 0.0, '', '', 2, '00-6', 19030115D);
        InsertDailyEntry(
          XGENERAL, 2, '20000', 19030115D, 1, '2597', XPayment,
          3, XWWBOPERATING, 0.0, '', '', 2, '4362', 19030115D);
        InsertDailyEntry(
          XGENERAL, 0, '995710', 19030118D, 0, '2598', XInvoiceno156683forGasoline,
          0, '', 13.94, XSALES, XTOYOTA, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '995750', 19030118D, 0, '2598', XInvoiceno156683forGasoline,
          0, '', 6.96, XSALES, XTOYOTA, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998510', 19030118D, 0, '2598', XInvoiceno156683forGasoline,
          0, '', 25.56, XSALES, XTOYOTA, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '995710', 19030118D, 0, '2598', XInvoiceno156683forGasoline,
          0, '', 6.51, XSALES, XVW, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '995750', 19030118D, 0, '2598', XInvoiceno156683forGasoline,
          0, '', 3.25, XSALES, XVW, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998510', 19030118D, 0, '2598', XInvoiceno156683forGasoline,
          0, '', 11.93, XSALES, XVW, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '995710', 19030118D, 0, '2598', XInvoiceno156683forGasoline,
          0, '', 17.76, XSALES, XMERCEDES, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '995750', 19030118D, 0, '2598', XInvoiceno156683forGasoline,
          0, '', 8.88, XSALES, XMERCEDES, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998510', 19030118D, 0, '2598', XInvoiceno156683forGasoline,
          0, '', 32.56, XSALES, XMERCEDES, 0, '', 0D);
        "Exactly Balanced" := true;
        InsertDailyEntry(
          XGENERAL, 3, XWWBOPERATING, 19030118D, 0, '2598', XInvoiceno156683forGasoline,
          0, '', -127.36, '', '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 3, XWWBEUR, 19030119D, 0, XBANK1, XBankTransfer,
          3, XWWBOPERATING, 5000.0, '', '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 3, XWWBUSD, 19030119D, 0, 'BANK2', XBankTransfer,
          3, XWWBOPERATING, 3000.0, '', '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998910', 19030120D, 0, '2599', XCoffeeandTea,
          0, '992910', 21.92, '', '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998910', 19030120D, 0, '2600', XBirthdayBreakfastMD,
          0, '992910', 4.43, '', '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998240', 19030125D, 0, '2601', XPostage,
          3, XWWBOPERATING, 217.46, XSALES, '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998210', 19030125D, 0, '2602', 'Office Supplies',
          0, '992910', 15.13, XADM, '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 2, '20000', 19030125D, 1, '2603', XPayment,
          3, XWWBOPERATING, 0.0, '', '', 2, '4511', 19030125D);
        InsertDailyEntry(
          XGENERAL, 2, '30000', 19030125D, 1, '2604', XPayment,
          3, XWWBOPERATING, 0.0, '', '', 2, '12345', 19030125D);
        InsertDailyEntry(
          XGENERAL, 0, '998320', 19030126D, 0, '2605', XPaymentAccSystemsHotline,
          3, XWWBOPERATING, 136.56, XADM, '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998910', 19030126D, 0, '2607', XPackingTape,
          0, '992910', 27.66, XPROD, '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '992910', 19030126D, 0, '2608', XRepairandUpgofSpraypaintRobot,
          0, '', -311.15, XPROD, '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '991120', 19030126D, 0, '2608', XRepairandUpgofSpraypaintRobot,
          0, '', 207.43, XPROD, '', 0, '', 0D);
        "Exactly Balanced" := true; // Before the last line without "Balancing Acc. No."
        InsertDailyEntry(
          XGENERAL, 0, '998910', 19030126D, 0, '2608', XRepairandUpgofSpraypaintRobot,
          0, '', 103.72, XPROD, '', 0, '', 0D);

        // Unposted entries in General Journal
        InsertDailyEntry(
          XGENERAL, 0, '991220', 19030127D, 0, '2609', XPackingMachine,
          0, '', 124.65, XPROD, '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998210', 19030127D, 0, '2609', XBoxesforPackingMachine,
          0, '', 27.66, XPROD, '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998210', 19030127D, 0, '2609', XGlueforPackingMachine,
          0, '', 31.17, XPROD, '', 0, '', 0D);
        "Exactly Balanced" := true; // Before the last line without "Balancing Acc. No."
        InsertDailyEntry(
          XGENERAL, 3, XWWBOPERATING, 19030127D, 0, '2609', XMaterialsforPackingMachine,
          0, '', -183.48, '', '', 0, '', 0D);

        InsertDailyEntry(
          XGENERAL, 0, '995710', 19030127D, 0, '2610', XInvoiceno156786forGasoline,
          0, '', 13.94, XSALES, XTOYOTA, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '995750', 19030127D, 0, '2610', XInvoiceno156786forGasoline,
          0, '', 6.96, XSALES, XTOYOTA, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998510', 19030127D, 0, '2610', XInvoiceno156786forGasoline,
          0, '', 25.56, XSALES, XTOYOTA, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '995710', 19030127D, 0, '2610', XInvoiceno156786forGasoline,
          0, '', 6.51, XSALES, XVW, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '995750', 19030127D, 0, '2610', XInvoiceno156786forGasoline,
          0, '', 3.25, XSALES, XVW, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998510', 19030127D, 0, '2610', XInvoiceno156786forGasoline,
          0, '', 11.93, XSALES, XVW, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '995710', 19030127D, 0, '2610', XInvoiceno156786forGasoline,
          0, '', 17.76, XSALES, XMERCEDES, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '995750', 19030127D, 0, '2610', XInvoiceno156786forGasoline,
          0, '', 8.88, XSALES, XMERCEDES, 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, 0, '998510', 19030127D, 0, '2610', XInvoiceno156786forGasoline,
          0, '', 32.56, XSALES, XMERCEDES, 0, '', 0D);
        "Exactly Balanced" := true;
        InsertDailyEntry(
          XGENERAL, 3, XWWBOPERATING, 19030127D, 0, '2610', XInvoiceno156786forGasoline,
          0, '', -127.36, '', '', 0, '', 0D);

        // Customer opening entries
        InsertCustLine('10000', '00-1', 19030101D, 3);
        InsertCustLine('20000', '00-2', 19030105D, 5);
        InsertCustLine('10000', '00-3', 19030105D, 6);
        InsertCustLine('30000', '00-4', 19030106D, 4);
        InsertCustLine('20000', '00-5', 19030106D, 3);
        InsertCustLine('10000', '00-6', 19030109D, 8);
        InsertCustLine('30000', '00-7', 19030109D, 9);
        InsertCustLine('20000', '00-8', 19030112D, 6);
        InsertCustLine('10000', '00-9', 19030131D, 6);
        InsertCustLine('30000', '00-10', 19030131D, 9);
        InsertCustLine('10000', '00-11', 19030131D, 7.5);
        InsertCustLine('20000', '00-12', 19030131D, 6.5);
        InsertCustLine('30000', '00-13', 19030131D, 9.5);
        InsertCustLine('20000', '00-14', 19030131D, 4.5);
        InsertCustLine('30000', '00-15', 19030131D, 9);
        InsertCustLine('10000', '00-16', 19030131D, -1);

        if Customer.Get('01454545') then
            InsertCustLine('01454545', '00-17', 19030131D, -1)
        else
            InsertCustLine('31505050', '00-17', 19030131D, -1);

        // Vendor opening entries
        InsertVendLine('10000', '5437', 19030115D, 15);
        InsertVendLine('20000', '4362', 19030115D, 16);
        InsertVendLine('30000', '12345', 19030118D, 14);
        InsertVendLine('10000', '5578', 19030120D, 5);
        InsertVendLine('10000', '5672', 19030121D, 12);
        InsertVendLine('20000', '4511', 19030125D, 16);
        InsertVendLine('30000', '12388', 19030131D, -1);

        if Vendor.Get('01254796') then
            InsertVendLine('01254796', '2344', 19030131D, -1)
        else
            InsertVendLine('31147896', '2344', 19030131D, -1);

        InsertBankAccEntry(XWWBOPERATING, XBANK1, -1);
        InsertBankAccEntry(XNBL, 'BANK2', -1);

        InsertOpeningEntry(0, '991110', 19011231D, 1488346.44);
        InsertOpeningEntry(0, '991140', 19011231D, -382542.6);
        InsertOpeningEntry(0, '991210', 19011231D, 654733.13);
        InsertOpeningEntry(0, '991240', 19011231D, -406926.51);
        InsertOpeningEntry(0, '991110', 19011231D, 173535.88);
        InsertOpeningEntry(0, '991140', 19011231D, -70682.82);
        InsertOpeningEntry(0, '991310', 19011231D, 55573.43);
        InsertOpeningEntry(0, '991340', 19011231D, -27861.76);
        InsertOpeningEntry(0, '992180', 19011231D, 303230.1);
        InsertOpeningEntry(0, '992180', 19011231D, 151913.72);
        InsertOpeningEntry(0, '992180', 19011231D, 40469.43);
        InsertOpeningEntry(0, '992180', 19011231D, 532384.54);
        InsertOpeningEntry(0, '992310', 19011231D, 895104.26);
        InsertOpeningEntry(0, '992320', 19011231D, 99456.03);
        InsertOpeningEntry(0, '992330', 19011231D, 4127.03);
        InsertOpeningEntry(0, '992810', 19011231D, 13322.97);
        InsertOpeningEntry(0, '992910', 19011231D, 169.12);
        InsertOpeningEntry(0, '992920', 19011231D, 2856.88);
        InsertOpeningEntry(0, '992940', 19011231D, 6033.63);
        InsertOpeningEntry(0, '993110', 19011231D, -328000.0);
        InsertOpeningEntry(0, '994010', 19011231D, -170560.0);
        InsertOpeningEntry(0, '995120', 19011231D, -405908.92);
        InsertOpeningEntry(0, '995110', 19011231D, -72207.63);
        InsertOpeningEntry(0, '995310', 19011231D, -517995.84);
        InsertOpeningEntry(0, '995310', 19011231D, -557534.01);
        InsertOpeningEntry(0, '995410', 19011231D, -567431.21);
        InsertOpeningEntry(0, '995420', 19011231D, -77816.95);
        InsertOpeningEntry(0, '995780', 19011231D, -104423.13);
        InsertOpeningEntry(0, '995810', 19011231D, -110071.95);
        InsertOpeningEntry(0, '995830', 19011231D, -16515.06);
        InsertOpeningEntry(0, '995840', 19011231D, -5075.46);
        InsertOpeningEntry(0, '995920', 19011231D, -51168.0);
        "Exactly Balanced" := true;
        InsertOpeningEntry(0, '993120', 19011231D, -547534.74);

        InsertPeriodicEntry(0, '996210', 19020101D, -424772.74, XSALES, XSMALL, '30', '', '');
        InsertPeriodicEntry(0, '992310', 19020101D, 424772.74, '', '', '', '', '');
        InsertPeriodicEntry(0, '996220', 19020101D, -178512.08, XSALES, XSMALL, '30', '', '');
        InsertPeriodicEntry(0, '992320', 19020101D, 178512.08, '', '', '', '', '');
        InsertPeriodicEntry(0, '996110', 19020101D, -93842.98, XSALES, XSMALL, '30', XOFFICE, '');
        InsertPeriodicEntry(0, '992310', 19020101D, 93842.98, '', '', '', '', '');
        InsertPeriodicEntry(0, '996120', 19020101D, -2380.3, XSALES, XSMALL, '30', XHOME, '');
        InsertPeriodicEntry(0, '992320', 19020101D, 2380.3, '', '', '', '', '');
        InsertPeriodicEntry(0, '996130', 19020101D, -7062.61, XSALES, XSMALL, '80', '', '');
        InsertPeriodicEntry(0, '992320', 19020101D, 7062.61, '', '', '', '', '');
        InsertPeriodicEntry(0, '997210', 19020101D, 246823.09, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '995410', 19020101D, -246823.09, '', '', '', '', '');
        InsertPeriodicEntry(0, '997220', 19020101D, 97717.13, XSALES, '', '30', '', '');
        InsertPeriodicEntry(0, '995420', 19020101D, -97717.13, '', '', '', '', '');
        InsertPeriodicEntry(0, '997110', 19020101D, 72702.0, XSALES, '', '30', XHOME, '');
        InsertPeriodicEntry(0, '995410', 19020101D, -72702.0, '', '', '', '', '');
        InsertPeriodicEntry(0, '997120', 19020101D, 16745.29, XSALES, '', '30', XINDUSTRIAL, '');
        InsertPeriodicEntry(0, '995420', 19020101D, -16745.29, '', '', '', '', '');
        InsertPeriodicEntry(0, '997130', 19020101D, 1850.53, XSALES, '', '80', XOFFICE, '');
        InsertPeriodicEntry(0, '995420', 19020101D, -1850.53, '', '', '', '', '');
        InsertPeriodicEntry(0, '996710', 19020101D, -20500.0, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996810', 19020101D, -45.92, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996910', 19020101D, 3737.89, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '997140', 19020101D, -658.62, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '997240', 19020101D, -1977.97, XSALES, '', '30', '', '');
        InsertPeriodicEntry(0, '998130', 19020101D, 2963.97, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020101D, 4445.96, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020101D, 7409.93, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020101D, 669.74, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020101D, 1004.62, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020101D, 1674.36, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020101D, 894.82, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020101D, 1342.22, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020101D, 2237.04, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020101D, 3137.81, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020101D, 4706.72, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020101D, 7844.53, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020101D, 1540.42, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020101D, 2310.63, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020101D, 3851.05, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020101D, 179.91, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020101D, 269.86, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020101D, 449.77, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020101D, 72.53, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020101D, 108.79, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020101D, 181.32, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020101D, 83.48, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020101D, 125.21, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020101D, 208.69, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020101D, 2722.2, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020101D, 4083.31, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020101D, 6805.51, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020101D, 88.99, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020101D, 133.48, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020101D, 222.47, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020101D, 604.23, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020101D, 906.34, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020101D, 1510.57, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020101D, 59.97, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020101D, 29.99, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020101D, 109.96, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020101D, 89.96, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020101D, 44.98, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020101D, 164.93, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020101D, 149.94, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020101D, 74.97, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020101D, 274.88, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020101D, 59.34, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020101D, 89.0, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020101D, 148.34, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020101D, 0.66, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020101D, 0.98, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020101D, 1.64, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020101D, 41.0, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020101D, 61.5, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020101D, 102.5, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020101D, 23648.8, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020101D, 35473.2, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020101D, 59122.0, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020101D, 7224.92, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020101D, 10837.38, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020101D, 18062.31, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020101D, 144.5, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020101D, 216.76, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020101D, 361.26, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998750', 19020101D, 1903.55, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998750', 19020101D, 2855.33, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998750', 19020101D, 4758.89, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '997150', 19020101D, 183.74, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '997250', 19020101D, 275.61, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998450', 19020101D, 459.35, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020101D, 1510.6, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020101D, 2265.9, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020101D, 3776.5, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020101D, 51.8, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020101D, 77.7, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020101D, 129.5, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020101D, 53.74, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020101D, 80.61, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020101D, 134.35, XSALES, '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020101D, -220458.7, '', '', '', '', '');

        InsertPeriodicEntry(0, '992310', 19020101D, -1024758.19, '', '', '', '', '');
        InsertPeriodicEntry(0, '992320', 19020101D, -146444.78, '', '', '', '', '');
        InsertPeriodicEntry(0, '995410', 19020101D, 647312.48, '', '', '', '', '');
        InsertPeriodicEntry(0, '995420', 19020101D, 106895.19, '', '', '', '', '');

        InsertPeriodicEntry(0, '995310', 19020101D, -500000.0, '', '', '', '', '');
        InsertPeriodicEntry(0, '992940', 19020101D, 500000.0, '', '', '', '', '');

        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020101D, 416995.3, '', '', '', '', '');

        InsertPeriodicEntry(0, '996210', 19020201D, -610665.1, XSALES, XMEDIUM, '30', '', '');
        InsertPeriodicEntry(0, '992310', 19020201D, 610665.1, '', '', '', '', '');
        InsertPeriodicEntry(0, '996220', 19020201D, -37168.74, XSALES, XSMALL, '30', XOFFICE, '');
        InsertPeriodicEntry(0, '992320', 19020201D, 37168.74, '', '', '', '', '');
        InsertPeriodicEntry(0, '996230', 19020201D, -104713.12, XSALES, XSMALL, '50', '', '');
        InsertPeriodicEntry(0, '992320', 19020201D, 104713.12, '', '', '', '', '');
        InsertPeriodicEntry(0, '996110', 19020201D, -97264.91, XSALES, XSMALL, '30', XHOME, '');
        InsertPeriodicEntry(0, '992310', 19020201D, 97264.91, '', '', '', '', '');
        InsertPeriodicEntry(0, '996130', 19020201D, -16780.69, XSALES, XMEDIUM, '50', XOFFICE, '');
        InsertPeriodicEntry(0, '992320', 19020201D, 16780.69, '', '', '', '', '');
        InsertPeriodicEntry(0, '997210', 19020201D, 330504.44, XSALES, '', '30', XHOME, '');
        InsertPeriodicEntry(0, '995410', 19020201D, -330504.44, '', '', '', '', '');
        InsertPeriodicEntry(0, '997220', 19020201D, 59569.56, XSALES, '', '30', '', '');
        InsertPeriodicEntry(0, '995420', 19020201D, -59569.56, '', '', '', '', '');
        InsertPeriodicEntry(0, '997110', 19020201D, 75955.87, XSALES, '', '30', XHOME, '');
        InsertPeriodicEntry(0, '995410', 19020201D, -75955.87, '', '', '', '', '');
        InsertPeriodicEntry(0, '997120', 19020201D, 27097.14, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '995420', 19020201D, -27097.14, '', '', '', '', '');
        InsertPeriodicEntry(0, '996710', 19020201D, -25625.0, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996810', 19020201D, -183.68, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996910', 19020201D, 3645.39, XSALES, XMEDIUM, '50', XOFFICE, '');
        InsertPeriodicEntry(0, '997140', 19020201D, -497.12, XSALES, '', '30', '', '');
        InsertPeriodicEntry(0, '997240', 19020201D, -2337.85, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020201D, 2776.26, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020201D, 4164.39, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020201D, 6940.65, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020201D, 627.33, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020201D, 941.0, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020201D, 1568.33, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020201D, 838.14, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020201D, 1257.21, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020201D, 2095.35, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020201D, 2939.08, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020201D, 4408.61, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020201D, 7347.69, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020201D, 1553.21, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020201D, 2329.82, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020201D, 3883.03, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020201D, 181.38, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020201D, 272.08, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020201D, 453.46, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020201D, 73.13, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020201D, 109.7, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020201D, 182.83, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020201D, 1502.24, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020201D, 2253.36, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020201D, 3755.6, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020201D, 44.28, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020201D, 66.42, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020201D, 110.7, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020201D, 2744.8, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020201D, 4117.2, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020201D, 6862.01, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020201D, 89.74, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020201D, 134.61, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020201D, 224.35, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020201D, 609.24, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020201D, 913.86, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020201D, 1523.1, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020201D, 60.47, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020201D, 30.23, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020201D, 110.86, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020201D, 90.7, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020201D, 45.35, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020201D, 166.28, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020201D, 151.17, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020201D, 75.58, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020201D, 277.14, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020201D, 59.83, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020201D, 89.74, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020201D, 149.57, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020201D, 2.76, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020201D, 4.13, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020201D, 6.89, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020201D, 132.84, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020201D, 199.26, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020201D, 332.1, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020201D, 23648.8, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020201D, 35473.2, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020201D, 59122.0, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020201D, 2440.98, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020201D, 3661.46, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020201D, 6102.44, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020201D, 7224.92, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020201D, 10837.38, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020201D, 18062.31, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020201D, 144.5, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020201D, 216.76, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020201D, 361.26, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '997150', 19020201D, 185.29, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998910', 19020201D, 277.93, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998450', 19020201D, 463.22, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020201D, 1810.68, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020201D, 2716.02, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020201D, 4526.7, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020201D, 52.22, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020201D, 78.33, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020201D, 130.55, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020201D, -9.92, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020201D, -14.88, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020201D, -24.8, XSALES, '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020201D, -224368.18, '', '', '', '', '');

        InsertPeriodicEntry(0, '992310', 19020201D, -565944.29, '', '', '', '', '');
        InsertPeriodicEntry(0, '992320', 19020201D, -180631.88, '', '', '', '', '');
        InsertPeriodicEntry(0, '995410', 19020201D, 341258.9, '', '', '', '', '');
        InsertPeriodicEntry(0, '995420', 19020201D, 108901.39, '', '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020201D, 296415.88, '', '', '', '', '');

        InsertPeriodicEntry(0, '995810', 19020301D, 110071.95, '', '', '', '', '');
        InsertPeriodicEntry(0, '995830', 19020301D, 16515.06, '', '', '', '', '');
        InsertPeriodicEntry(0, '995840', 19020301D, 5075.46, '', '', '', '', '');
        InsertPeriodicEntry(0, '995920', 19020301D, 51168.0, '', '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020301D, -182830.47, '', '', '', '', '');

        InsertPeriodicEntry(0, '996210', 19020301D, -366126.43, XSALES, XMEDIUM, '30', '', '');
        InsertPeriodicEntry(0, '992310', 19020301D, 366126.43, '', '', '', '', '');
        InsertPeriodicEntry(0, '996230', 19020301D, -126775.24, XSALES, XMEDIUM, '70', '', '');
        InsertPeriodicEntry(0, '992320', 19020301D, 126775.24, '', '', '', '', '');
        InsertPeriodicEntry(0, '996110', 19020301D, -103915.06, XSALES, XSMALL, '30', XOFFICE, '');
        InsertPeriodicEntry(0, '992310', 19020301D, 103915.06, '', '', '', '', '');
        InsertPeriodicEntry(0, '996130', 19020301D, -8492.34, XSALES, XMEDIUM, '40', XHOME, '');
        InsertPeriodicEntry(0, '992320', 19020301D, 8492.34, '', '', '', '', '');
        InsertPeriodicEntry(0, '997210', 19020301D, 252579.3, XSALES, '', '30', XINDUSTRIAL, '');
        InsertPeriodicEntry(0, '995410', 19020301D, -252579.3, '', '', '', '', '');
        InsertPeriodicEntry(0, '997220', 19020301D, 7704.26, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '995420', 19020301D, -7704.26, '', '', '', '', '');
        InsertPeriodicEntry(0, '997230', 19020301D, 77343.24, XSALES, '', '50', XOFFICE, '');
        InsertPeriodicEntry(0, '995420', 19020301D, -77343.24, '', '', '', '', '');
        InsertPeriodicEntry(0, '997240', 19020301D, -858.57, XSALES, '', '50', XOFFICE, '');
        InsertPeriodicEntry(0, '997110', 19020301D, 72657.14, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '995410', 19020301D, -72657.14, '', '', '', '', '');
        InsertPeriodicEntry(0, '997120', 19020301D, 5814.59, XSALES, '', '30', XINDUSTRIAL, '');
        InsertPeriodicEntry(0, '995420', 19020301D, -5814.59, '', '', '', '', '');
        InsertPeriodicEntry(0, '997130', 19020301D, 12930.39, XSALES, '', '80', XHOME, '');
        InsertPeriodicEntry(0, '995420', 19020301D, -12930.39, '', '', '', '', '');
        InsertPeriodicEntry(0, '997140', 19020301D, -262.4, XSALES, '', '30', XINDUSTRIAL, '');
        InsertPeriodicEntry(0, '996710', 19020301D, -25625.0, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996910', 19020301D, 3840.36, XSALES, XSMALL, '30', '', '');
        InsertPeriodicEntry(0, '998130', 19020301D, 2799.32, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020301D, 4198.97, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020301D, 6998.29, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020301D, 632.52, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020301D, 948.77, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020301D, 1581.29, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020301D, 845.12, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020301D, 1267.69, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020301D, 2112.81, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020301D, 2963.48, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020301D, 4445.22, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020301D, 7408.7, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020301D, 1723.15, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020301D, 2584.72, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020301D, 4307.87, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020301D, 201.23, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020301D, 301.84, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020301D, 503.07, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020301D, 81.13, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020301D, 121.7, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020301D, 202.84, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020301D, 98.4, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020301D, 147.6, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020301D, 246.0, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020301D, 3045.12, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020301D, 4567.68, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020301D, 7612.8, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020301D, 99.55, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020301D, 149.32, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020301D, 248.87, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020301D, 675.89, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020301D, 1013.84, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020301D, 1689.73, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020301D, 67.09, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020301D, 33.54, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020301D, 123.0, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020301D, 100.64, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020301D, 50.32, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020301D, 184.5, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020301D, 167.72, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020301D, 83.86, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020301D, 307.49, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020301D, 66.35, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020301D, 99.53, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020301D, 165.89, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020301D, 0.52, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020301D, 0.79, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020301D, 1.31, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020301D, 207.46, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020301D, 311.19, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020301D, 518.65, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020301D, 26300.35, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020301D, 39450.53, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020301D, 65750.88, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020301D, 7224.92, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020301D, 10837.38, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020301D, 18062.31, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020301D, 144.5, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020301D, 216.76, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020301D, 361.26, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020301D, 1475.58, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020301D, 2213.37, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020301D, 3688.95, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998910', 19020301D, 205.56, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '997250', 19020301D, 308.34, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998910', 19020301D, 513.9, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999210', 19020301D, 2436.25, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999210', 19020301D, 3654.38, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999210', 19020301D, 6090.63, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999230', 19020301D, 3538.76, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999230', 19020301D, 5308.14, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999230', 19020301D, 8846.9, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999220', 19020301D, 186.94, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999220', 19020301D, 280.41, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999220', 19020301D, 467.35, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020301D, 1511.86, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020301D, 2267.79, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020301D, 3779.65, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020301D, 57.94, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020301D, 86.91, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020301D, 144.85, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020301D, -118.38, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020301D, -177.57, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020301D, -295.95, XSALES, '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020301D, -260230.22, '', '', '', '', '');

        InsertPeriodicEntry(0, '992310', 19020301D, -648457.88, '', '', '', '', '');
        InsertPeriodicEntry(0, '992320', 19020301D, -152813.81, '', '', '', '', '');
        InsertPeriodicEntry(0, '995410', 19020301D, 386154.34, '', '', '', '', '');
        InsertPeriodicEntry(0, '995420', 19020301D, 90948.15, '', '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020301D, 324169.2, '', '', '', '', '');

        InsertPeriodicEntry(0, '996210', 19020401D, -447982.41, XSALES, XLARGE, '30', XHOME, '');
        InsertPeriodicEntry(0, '992310', 19020401D, 447982.41, '', '', '', '', '');
        InsertPeriodicEntry(0, '996230', 19020401D, -61335.66, XSALES, XSMALL, '70', '', '');
        InsertPeriodicEntry(0, '992320', 19020401D, 61335.66, '', '', '', '', '');
        InsertPeriodicEntry(0, '996110', 19020401D, -103325.45, XSALES, XMEDIUM, '30', XOFFICE, '');
        InsertPeriodicEntry(0, '992310', 19020401D, 103325.45, '', '', '', '', '');
        InsertPeriodicEntry(0, '996120', 19020401D, -768.51, XSALES, XSMALL, '30', XHOME, '');
        InsertPeriodicEntry(0, '992320', 19020401D, 768.51, '', '', '', '', '');
        InsertPeriodicEntry(0, '996130', 19020401D, -11666.26, XSALES, XSMALL, '80', XHOME, '');
        InsertPeriodicEntry(0, '992320', 19020401D, 11666.26, '', '', '', '', '');
        InsertPeriodicEntry(0, '997210', 19020401D, 236191.86, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '995410', 19020401D, -236191.86, '', '', '', '', '');
        InsertPeriodicEntry(0, '997220', 19020401D, 1914.47, XSALES, '', '30', XHOME, '');
        InsertPeriodicEntry(0, '995420', 19020401D, -1914.47, '', '', '', '', '');
        InsertPeriodicEntry(0, '997230', 19020401D, 87433.67, XSALES, '', '70', XHOME, '');
        InsertPeriodicEntry(0, '995420', 19020401D, -87433.67, '', '', '', '', '');
        InsertPeriodicEntry(0, '997110', 19020401D, 66088.16, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '995410', 19020401D, -66088.16, '', '', '', '', '');
        InsertPeriodicEntry(0, '997120', 19020401D, 6716.66, XSALES, '', '30', XHOME, '');
        InsertPeriodicEntry(0, '995420', 19020401D, -6716.66, '', '', '', '', '');
        InsertPeriodicEntry(0, '997130', 19020401D, 15912.13, XSALES, '', '70', XHOME, '');
        InsertPeriodicEntry(0, '995420', 19020401D, -15912.13, '', '', '', '', '');
        InsertPeriodicEntry(0, '996710', 19020401D, -23128.1, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996810', 19020401D, -219.76, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996910', 19020401D, 3318.44, XSALES, XSMALL, '40', XHOME, '');
        InsertPeriodicEntry(0, '997140', 19020401D, -203.1, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '997240', 19020401D, -893.08, XSALES, '', '30', XHOME, '');
        InsertPeriodicEntry(0, '998130', 19020401D, 2634.63, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020401D, 3951.94, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020401D, 6586.57, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020401D, 595.32, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020401D, 892.98, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020401D, 1488.3, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020401D, 795.4, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020401D, 1193.1, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020401D, 1988.5, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020401D, 2789.15, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020401D, 4183.72, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020401D, 6972.87, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020401D, 1324.79, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020401D, 1987.19, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020401D, 3311.98, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020401D, 154.72, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020401D, 232.08, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020401D, 386.8, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020401D, 62.37, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020401D, 93.56, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020401D, 155.93, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020401D, 2341.17, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020401D, 3511.75, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020401D, 5852.92, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020401D, 76.52, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020401D, 114.78, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020401D, 191.31, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020401D, 519.66, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020401D, 779.48, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020401D, 1299.14, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020401D, 51.57, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020401D, 25.79, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020401D, 94.55, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020401D, 77.36, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020401D, 38.68, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020401D, 141.82, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020401D, 128.93, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020401D, 64.46, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020401D, 236.37, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020401D, 51.04, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020401D, 76.55, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020401D, 127.59, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020401D, 48.22, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020401D, 72.32, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020401D, 120.54, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020401D, 25852.46, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020401D, 38778.69, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020401D, 64631.16, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020401D, 7224.92, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020401D, 10837.38, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020401D, 18062.31, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020401D, 144.5, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020401D, 216.76, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020401D, 361.26, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998750', 19020401D, 1727.69, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998750', 19020401D, 2591.54, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998750', 19020401D, 4319.24, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '997150', 19020401D, 158.03, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '997250', 19020401D, 237.05, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998910', 19020401D, 395.08, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020401D, 1209.11, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020401D, 1813.66, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020401D, 3022.77, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020401D, 44.53, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020401D, 66.8, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020401D, 111.33, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020401D, 28.16, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020401D, 42.23, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020401D, 70.39, XSALES, '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020401D, -218645.87, '', '', '', '', '');

        InsertPeriodicEntry(0, '992310', 19020401D, -490358.08, '', '', '', '', '');
        InsertPeriodicEntry(0, '992320', 19020401D, -119893.29, '', '', '', '', '');
        InsertPeriodicEntry(0, '995410', 19020401D, 319497.34, '', '', '', '', '');
        InsertPeriodicEntry(0, '995420', 19020401D, 105838.59, '', '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020401D, 184915.44, '', '', '', '', '');

        InsertPeriodicEntry(0, '996210', 19020501D, -656712.14, XSALES, XSMALL, '30', XOFFICE, '');
        InsertPeriodicEntry(0, '992310', 19020501D, 656712.14, '', '', '', '', '');
        InsertPeriodicEntry(0, '996230', 19020501D, -81392.82, XSALES, XSMALL, '70', XHOME, '');
        InsertPeriodicEntry(0, '992320', 19020501D, 81392.82, '', '', '', '', '');
        InsertPeriodicEntry(0, '996110', 19020501D, -87233.63, XSALES, XSMALL, '30', XOFFICE, '');
        InsertPeriodicEntry(0, '992310', 19020501D, 87233.63, '', '', '', '', '');
        InsertPeriodicEntry(0, '996120', 19020501D, -16781.06, XSALES, XMEDIUM, '30', XHOME, '');
        InsertPeriodicEntry(0, '992320', 19020501D, 16781.06, '', '', '', '', '');
        InsertPeriodicEntry(0, '996130', 19020501D, -17562.61, XSALES, XSMALL, '70', XHOME, '');
        InsertPeriodicEntry(0, '992320', 19020501D, 17562.61, '', '', '', '', '');
        InsertPeriodicEntry(0, '997210', 19020501D, 261028.66, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '995410', 19020501D, -261028.66, '', '', '', '', '');
        InsertPeriodicEntry(0, '997220', 19020501D, 10691.57, XSALES, '', '30', XHOME, '');
        InsertPeriodicEntry(0, '995420', 19020501D, -10691.57, '', '', '', '', '');
        InsertPeriodicEntry(0, '997230', 19020501D, 3564.59, XSALES, '', '70', XHOME, '');
        InsertPeriodicEntry(0, '995420', 19020501D, -3564.59, '', '', '', '', '');
        InsertPeriodicEntry(0, '997110', 19020501D, 59972.89, XSALES, '', '30', XHOME, '');
        InsertPeriodicEntry(0, '995410', 19020501D, -59972.89, '', '', '', '', '');
        InsertPeriodicEntry(0, '997130', 19020501D, 17580.25, XSALES, '', '70', XHOME, '');
        InsertPeriodicEntry(0, '995420', 19020501D, -17580.25, '', '', '', '', '');
        InsertPeriodicEntry(0, '996710', 19020501D, -30592.56, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996910', 19020501D, 3551.06, XSALES, XMEDIUM, '30', XHOME, '');
        InsertPeriodicEntry(0, '998130', 19020501D, 3877.85, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020501D, 6463.08, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020501D, 584.17, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020501D, 876.25, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020501D, 1460.42, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020501D, 780.48, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020501D, 1170.71, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020501D, 1951.19, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020501D, 2736.86, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020501D, 4105.3, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020501D, 6842.16, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020501D, 1644.56, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020501D, 2466.84, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020501D, 4111.4, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020501D, 192.08, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020501D, 288.11, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020501D, 480.19, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020501D, 77.43, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020501D, 116.15, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020501D, 193.59, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020501D, 443.39, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020501D, 665.09, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020501D, 1108.48, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020501D, 26.17, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020501D, 39.26, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020501D, 65.44, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020501D, 2906.28, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020501D, 4359.41, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020501D, 7265.69, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020501D, 95.02, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020501D, 142.53, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020501D, 237.56, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020501D, 645.08, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020501D, 967.63, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020501D, 1612.71, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020501D, 64.03, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020501D, 32.01, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020501D, 117.39, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020501D, 96.05, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020501D, 48.02, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020501D, 176.08, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020501D, 160.07, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020501D, 80.04, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020501D, 293.47, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020501D, 63.34, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020501D, 95.0, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020501D, 158.34, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020501D, 6.66, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020501D, 10.0, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020501D, 16.66, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998620', 19020501D, 1182.45, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998620', 19020501D, 1773.68, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998620', 19020501D, 2956.14, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998630', 19020501D, 611.72, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998630', 19020501D, 917.58, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998630', 19020501D, 1529.3, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020501D, 47.76, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020501D, 71.63, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020501D, 119.39, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020501D, 23597.63, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020501D, 35396.45, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020501D, 58994.08, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020501D, 2349.06, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020501D, 3523.59, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020501D, 5872.65, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020501D, 6338.4, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020501D, 9507.61, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020501D, 15846.01, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020501D, 126.77, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020501D, 190.15, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020501D, 316.92, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '997150', 19020501D, 196.18, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998910', 19020501D, 294.27, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998450', 19020501D, 490.45, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020501D, 1811.31, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020501D, 2716.97, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020501D, 4528.28, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020501D, 55.29, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020501D, 82.93, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020501D, 138.22, XSALES, '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020501D, -216957.09, '', '', '', '', '');

        InsertPeriodicEntry(0, '992310', 19020501D, -599467.34, '', '', '', '', '');
        InsertPeriodicEntry(0, '992320', 19020501D, -84261.95, '', '', '', '', '');
        InsertPeriodicEntry(0, '995410', 19020501D, 306960.4, '', '', '', '', '');
        InsertPeriodicEntry(0, '995420', 19020501D, 91941.8, '', '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020501D, 284827.09, '', '', '', '', '');

        InsertPeriodicEntry(0, '996210', 19020601D, -409404.38, XSALES, XSMALL, '30', XHOME, XSUMMER);
        InsertPeriodicEntry(0, '992310', 19020601D, 409404.38, '', '', '', '', '');
        InsertPeriodicEntry(0, '996220', 19020601D, -28436.57, XSALES, XSMALL, '30', XHOME, XSUMMER);
        InsertPeriodicEntry(0, '992320', 19020601D, 28436.57, '', '', '', '', '');
        InsertPeriodicEntry(0, '996230', 19020601D, -1508.49, XSALES, XSMALL, '80', XOFFICE, '');
        InsertPeriodicEntry(0, '992320', 19020601D, 1508.49, '', '', '', '', '');
        InsertPeriodicEntry(0, '996110', 19020601D, -60881.9, XSALES, XSMALL, '30', XHOME, XSUMMER);
        InsertPeriodicEntry(0, '992310', 19020601D, 60881.9, '', '', '', '', '');
        InsertPeriodicEntry(0, '996120', 19020601D, -8423.52, XSALES, XSMALL, '30', XHOME, XSUMMER);
        InsertPeriodicEntry(0, '992320', 19020601D, 8423.52, '', '', '', '', '');
        InsertPeriodicEntry(0, '997210', 19020601D, 305004.93, XSALES, '', '30', XHOME, XSUMMER);
        InsertPeriodicEntry(0, '995410', 19020601D, -305004.93, '', '', '', '', '');
        InsertPeriodicEntry(0, '997220', 19020601D, 21289.83, XSALES, '', '30', XHOME, XSUMMER);
        InsertPeriodicEntry(0, '995420', 19020601D, -21289.83, '', '', '', '', '');
        InsertPeriodicEntry(0, '997230', 19020601D, 1706.55, XSALES, '', '80', XOFFICE, '');
        InsertPeriodicEntry(0, '995420', 19020601D, -1706.55, '', '', '', '', '');
        InsertPeriodicEntry(0, '997110', 19020601D, 64926.8, XSALES, '', '30', XHOME, XSUMMER);
        InsertPeriodicEntry(0, '995410', 19020601D, -64926.8, '', '', '', '', '');
        InsertPeriodicEntry(0, '997120', 19020601D, 7639.08, XSALES, '', '30', XHOME, XSUMMER);
        InsertPeriodicEntry(0, '995420', 19020601D, -7639.08, '', '', '', '', '');
        InsertPeriodicEntry(0, '997130', 19020601D, 16697.84, XSALES, '', '80', XHOME, XSUMMER);
        InsertPeriodicEntry(0, '995420', 19020601D, -16697.84, '', '', '', '', '');
        InsertPeriodicEntry(0, '996710', 19020601D, -24796.8, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996910', 19020601D, 1460.26, XSALES, XSMALL, '30', XHOME, XSUMMER);
        InsertPeriodicEntry(0, '997240', 19020601D, -1645.77, XSALES, '', '30', XHOME, XSUMMER);
        InsertPeriodicEntry(0, '998130', 19020601D, 3046.3, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020601D, 4569.45, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020601D, 7615.75, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020601D, 688.34, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020601D, 1032.51, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020601D, 1720.85, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020601D, 919.68, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020601D, 1379.52, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020601D, 2299.2, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020601D, 3224.96, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020601D, 4837.44, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020601D, 8062.41, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020601D, 1653.71, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020601D, 2480.57, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020601D, 4134.28, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020601D, 193.13, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020601D, 289.69, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020601D, 482.82, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020601D, 77.85, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020601D, 116.78, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020601D, 194.64, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020601D, 1502.24, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020601D, 2253.36, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020601D, 3755.6, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020601D, 54.38, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020601D, 81.57, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020601D, 135.96, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020601D, 2922.41, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020601D, 4383.62, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020601D, 7306.04, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020601D, 95.55, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020601D, 143.32, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020601D, 238.87, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020601D, 648.65, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020601D, 972.98, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020601D, 1621.63, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020601D, 64.38, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020601D, 32.19, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020601D, 118.04, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020601D, 96.58, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020601D, 48.29, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020601D, 177.06, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020601D, 160.96, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020601D, 80.48, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020601D, 295.09, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998520', 19020601D, 140.78, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998520', 19020601D, 211.17, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998520', 19020601D, 351.95, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020601D, 63.7, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020601D, 95.55, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020601D, 159.25, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020601D, 2.34, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020601D, 3.5, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020601D, 5.84, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998620', 19020601D, 615.25, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998620', 19020601D, 922.88, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998620', 19020601D, 1538.13, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998630', 19020601D, 411.44, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998630', 19020601D, 617.17, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998630', 19020601D, 1028.61, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020601D, 246.0, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020601D, 369.0, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020601D, 615.0, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020601D, 23673.73, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020601D, 35510.59, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020601D, 59184.32, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020601D, 7175.33, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020601D, 10762.99, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020601D, 17938.32, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020601D, 143.51, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020601D, 215.26, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020601D, 358.77, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998740', 19020601D, 30920.19, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998740', 19020601D, 46380.29, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998740', 19020601D, 77300.48, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '997150', 19020601D, 197.26, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998910', 19020601D, 295.89, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998450', 19020601D, 493.15, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999110', 19020601D, -213.17, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999110', 19020601D, -319.76, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999110', 19020601D, -532.94, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999210', 19020601D, 2859.95, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999210', 19020601D, 4289.93, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999210', 19020601D, 7149.88, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999230', 19020601D, 4988.96, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999230', 19020601D, 7483.45, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999230', 19020601D, 12472.41, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020601D, 1811.36, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020601D, 2717.04, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020601D, 4528.41, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020601D, 55.6, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020601D, 83.4, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020601D, 139.01, XSALES, '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020601D, -416687.99, '', '', '', '', '');

        InsertPeriodicEntry(0, '992310', 19020601D, -675530.9, '', '', '', '', '');
        InsertPeriodicEntry(0, '992320', 19020601D, -96394.51, '', '', '', '', '');
        InsertPeriodicEntry(0, '995410', 19020601D, 333234.1, '', '', '', '', '');
        InsertPeriodicEntry(0, '995420', 19020601D, 35710.63, '', '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020601D, 402980.68, '', '', '', '', '');

        InsertPeriodicEntry(0, '996210', 19020701D, -309450.95, XSALES, XMEDIUM, '30', XINDUSTRIAL, XSUMMER);
        InsertPeriodicEntry(0, '992310', 19020701D, 309450.95, '', '', '', '', '');
        InsertPeriodicEntry(0, '996230', 19020701D, -107322.25, XSALES, XSMALL, '30', XOFFICE, XSUMMER);
        InsertPeriodicEntry(0, '992320', 19020701D, 107322.25, '', '', '', '', '');
        InsertPeriodicEntry(0, '996110', 19020701D, -57092.24, XSALES, XMEDIUM, '30', XOFFICE, XSUMMER);
        InsertPeriodicEntry(0, '992310', 19020701D, 57092.24, '', '', '', '', '');
        InsertPeriodicEntry(0, '996120', 19020701D, -3447.47, XSALES, XSMALL, '30', XOFFICE, XSUMMER);
        InsertPeriodicEntry(0, '992320', 19020701D, 3447.47, '', '', '', '', '');
        InsertPeriodicEntry(0, '996130', 19020701D, -1565.45, XSALES, XSMALL, '70', XINDUSTRIAL, XSUMMER);
        InsertPeriodicEntry(0, '992320', 19020701D, 1565.45, '', '', '', '', '');
        InsertPeriodicEntry(0, '997210', 19020701D, 200066.85, XSALES, '', '30', XINDUSTRIAL, XSUMMER);
        InsertPeriodicEntry(0, '995410', 19020701D, -200066.85, '', '', '', '', '');
        InsertPeriodicEntry(0, '997230', 19020701D, 74638.4, XSALES, '', '70', XOFFICE, XSUMMER);
        InsertPeriodicEntry(0, '995420', 19020701D, -74638.4, '', '', '', '', '');
        InsertPeriodicEntry(0, '997240', 19020701D, -1308.72, XSALES, '', '30', XOFFICE, XSUMMER);
        InsertPeriodicEntry(0, '997110', 19020701D, 52406.77, XSALES, '', '30', XOFFICE, XSUMMER);
        InsertPeriodicEntry(0, '995410', 19020701D, -52406.77, '', '', '', '', '');
        InsertPeriodicEntry(0, '997130', 19020701D, 16817.63, XSALES, '', '70', XINDUSTRIAL, XSUMMER);
        InsertPeriodicEntry(0, '995420', 19020701D, -16817.63, '', '', '', '', '');
        InsertPeriodicEntry(0, '997140', 19020701D, -525.06, XSALES, '', '30', XOFFICE, XSUMMER);
        InsertPeriodicEntry(0, '996710', 19020701D, -21580.43, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996910', 19020701D, 1172.27, XSALES, XSMALL, '70', XINDUSTRIAL, XSUMMER);
        InsertPeriodicEntry(0, '998130', 19020701D, 2614.88, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020701D, 3922.32, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020701D, 6537.21, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020701D, 590.86, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020701D, 886.29, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020701D, 1477.15, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020701D, 789.43, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020701D, 1184.15, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020701D, 1973.58, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020701D, 2768.22, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020701D, 4152.33, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020701D, 6920.56, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020701D, 1460.03, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020701D, 2190.04, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020701D, 3650.07, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020701D, 170.49, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020701D, 255.74, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020701D, 426.24, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020701D, 68.75, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020701D, 103.12, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020701D, 171.87, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020701D, 334.56, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020701D, 501.84, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020701D, 836.4, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19020701D, 941.36, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19020701D, 1412.04, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19020701D, 2353.4, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020701D, 82.98, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020701D, 124.48, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020701D, 207.46, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020701D, 2580.11, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020701D, 3870.17, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020701D, 6450.29, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020701D, 84.36, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020701D, 126.54, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020701D, 210.91, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020701D, 572.69, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020701D, 859.03, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020701D, 1431.72, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020701D, 56.84, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020701D, 28.42, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020701D, 104.2, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020701D, 85.25, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020701D, 42.63, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020701D, 156.3, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020701D, 142.09, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020701D, 71.04, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020701D, 260.5, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020701D, 56.22, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020701D, 84.33, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020701D, 140.55, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020701D, 3.23, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020701D, 4.84, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020701D, 8.07, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998630', 19020701D, 1863.04, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998630', 19020701D, 2794.56, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998630', 19020701D, 4657.6, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020701D, 55.37, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020701D, 83.05, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020701D, 138.42, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020701D, 23918.91, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020701D, 35878.37, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020701D, 59797.29, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020701D, 7175.33, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020701D, 10762.99, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020701D, 17938.32, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020701D, 143.51, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020701D, 215.26, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020701D, 358.77, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998750', 19020701D, 1967.95, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998750', 19020701D, 2951.92, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998750', 19020701D, 4919.87, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998910', 19020701D, 174.17, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '997250', 19020701D, 261.25, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998450', 19020701D, 435.42, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999220', 19020701D, 178.64, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999220', 19020701D, 267.96, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999220', 19020701D, 446.61, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020701D, 1350.05, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020701D, 2025.08, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020701D, 3375.13, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020701D, 49.1, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020701D, 73.64, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020701D, 122.74, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020701D, -46.42, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020701D, -69.63, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020701D, -116.05, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999320', 19020701D, 46.4, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999320', 19020701D, 69.6, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999320', 19020701D, 116.0, XSALES, '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020701D, -228676.46, '', '', '', '', '');

        InsertPeriodicEntry(0, '992310', 19020701D, -444350.51, '', '', '', '', '');
        InsertPeriodicEntry(0, '992320', 19020701D, -56860.23, '', '', '', '', '');
        InsertPeriodicEntry(0, '995410', 19020701D, 340567.2, '', '', '', '', '');
        InsertPeriodicEntry(0, '995420', 19020701D, 58363.98, '', '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020701D, 102279.56, '', '', '', '', '');

        InsertPeriodicEntry(0, '996210', 19020801D, -623044.91, XSALES, XLARGE, '30', XHOME, '');
        InsertPeriodicEntry(0, '992310', 19020801D, 623044.91, '', '', '', '', '');
        InsertPeriodicEntry(0, '996220', 19020801D, -43914.23, XSALES, XMEDIUM, '30', XHOME, '');
        InsertPeriodicEntry(0, '992320', 19020801D, 43914.23, '', '', '', '', '');
        InsertPeriodicEntry(0, '996230', 19020801D, -2085.42, XSALES, XSMALL, '70', XOFFICE, '');
        InsertPeriodicEntry(0, '992320', 19020801D, 2085.42, '', '', '', '', '');
        InsertPeriodicEntry(0, '996110', 19020801D, -60258.96, XSALES, XSMALL, '30', XINDUSTRIAL, '');
        InsertPeriodicEntry(0, '992310', 19020801D, 60258.96, '', '', '', '', '');
        InsertPeriodicEntry(0, '996120', 19020801D, -9181.69, XSALES, XSMALL, '30', XOFFICE, '');
        InsertPeriodicEntry(0, '992320', 19020801D, 9181.69, '', '', '', '', '');
        InsertPeriodicEntry(0, '996130', 19020801D, -5816.98, XSALES, XSMALL, '50', XHOME, '');
        InsertPeriodicEntry(0, '992320', 19020801D, 5816.98, '', '', '', '', '');
        InsertPeriodicEntry(0, '997210', 19020801D, 341542.81, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '995410', 19020801D, -341542.81, '', '', '', '', '');
        InsertPeriodicEntry(0, '997220', 19020801D, 1175.21, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '995420', 19020801D, -1175.21, '', '', '', '', '');
        InsertPeriodicEntry(0, '997110', 19020801D, 68270.44, XSALES, '', '30', XHOME, '');
        InsertPeriodicEntry(0, '995410', 19020801D, -68270.44, '', '', '', '', '');
        InsertPeriodicEntry(0, '997120', 19020801D, 14422.62, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '995420', 19020801D, -14422.62, '', '', '', '', '');
        InsertPeriodicEntry(0, '996710', 19020801D, -25387.2, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996810', 19020801D, -134.48, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996910', 19020801D, 2091.85, XSALES, XLARGE, '30', XHOME, '');
        InsertPeriodicEntry(0, '997140', 19020801D, -49.59, XSALES, '', '30', XHOME, '');
        InsertPeriodicEntry(0, '997240', 19020801D, -1525.07, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '998130', 19020801D, 2469.97, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020801D, 3704.96, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020801D, 6174.93, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020801D, 558.12, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020801D, 837.19, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020801D, 1395.31, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020801D, 745.68, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020801D, 1118.51, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020801D, 1864.19, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020801D, 2614.85, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020801D, 3922.27, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020801D, 6537.12, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020801D, 1516.67, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020801D, 2275.01, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020801D, 3791.68, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020801D, 177.12, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020801D, 265.68, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020801D, 442.8, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020801D, 71.4, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020801D, 107.1, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020801D, 178.5, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020801D, 1033.79, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020801D, 1550.69, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020801D, 2584.48, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19020801D, 1148.0, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19020801D, 1722.0, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19020801D, 2870.0, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020801D, 181.22, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020801D, 271.83, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020801D, 453.05, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020801D, 2680.22, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020801D, 4020.33, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020801D, 6700.55, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020801D, 87.61, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020801D, 131.41, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020801D, 219.02, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020801D, 594.91, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020801D, 892.37, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020801D, 1487.29, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020801D, 59.05, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020801D, 29.52, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020801D, 108.26, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020801D, 88.58, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020801D, 44.29, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020801D, 162.39, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020801D, 147.62, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020801D, 73.81, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020801D, 270.64, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020801D, 58.42, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020801D, 87.62, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020801D, 146.04, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020801D, 0.39, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020801D, 0.59, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020801D, 0.99, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020801D, 72.88, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020801D, 109.32, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020801D, 182.21, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020801D, 22181.25, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020801D, 33271.88, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020801D, 55453.13, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020801D, 667.31, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020801D, 1000.97, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020801D, 1668.28, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020801D, 7175.33, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020801D, 10762.99, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020801D, 17938.32, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020801D, 143.51, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020801D, 215.26, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020801D, 358.77, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '997150', 19020801D, 180.92, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '997250', 19020801D, 271.39, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998910', 19020801D, 452.31, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020801D, 1710.42, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020801D, 2565.63, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020801D, 4276.05, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020801D, 50.98, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020801D, 76.48, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020801D, 127.46, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020801D, 70.27, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020801D, 105.41, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020801D, 175.68, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999420', 19020801D, 171.61, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999420', 19020801D, 257.42, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999420', 19020801D, 429.03, XSALES, '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020801D, -207794.02, '', '', '', '', '');

        InsertPeriodicEntry(0, '992310', 19020801D, -445733.36, '', '', '', '', '');
        InsertPeriodicEntry(0, '992320', 19020801D, -99500.96, '', '', '', '', '');
        InsertPeriodicEntry(0, '995410', 19020801D, 291808.53, '', '', '', '', '');
        InsertPeriodicEntry(0, '995420', 19020801D, 72491.48, '', '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020801D, 180934.31, '', '', '', '', '');

        InsertPeriodicEntry(0, '996210', 19020901D, -430242.68, XSALES, XMEDIUM, '30', XOFFICE, '');
        InsertPeriodicEntry(0, '992310', 19020901D, 430242.68, '', '', '', '', '');
        InsertPeriodicEntry(0, '996220', 19020901D, -61229.61, XSALES, XSMALL, '30', XHOME, '');
        InsertPeriodicEntry(0, '992320', 19020901D, 61229.61, '', '', '', '', '');
        InsertPeriodicEntry(0, '996230', 19020901D, -82616.27, XSALES, XSMALL, '50', XINDUSTRIAL, '');
        InsertPeriodicEntry(0, '992320', 19020901D, 82616.27, '', '', '', '', '');
        InsertPeriodicEntry(0, '996110', 19020901D, -107470.15, XSALES, XLARGE, '30', XHOME, '');
        InsertPeriodicEntry(0, '992310', 19020901D, 107470.15, '', '', '', '', '');
        InsertPeriodicEntry(0, '996120', 19020901D, -1080.34, XSALES, XMEDIUM, '30', XOFFICE, '');
        InsertPeriodicEntry(0, '992320', 19020901D, 1080.34, '', '', '', '', '');
        InsertPeriodicEntry(0, '996130', 19020901D, -14743.4, XSALES, XSMALL, '70', XINDUSTRIAL, '');
        InsertPeriodicEntry(0, '992320', 19020901D, 14743.4, '', '', '', '', '');
        InsertPeriodicEntry(0, '997210', 19020901D, 245508.66, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '995410', 19020901D, -245508.66, '', '', '', '', '');
        InsertPeriodicEntry(0, '997220', 19020901D, 98683.84, XSALES, '', '30', XHOME, '');
        InsertPeriodicEntry(0, '995420', 19020901D, -98683.84, '', '', '', '', '');
        InsertPeriodicEntry(0, '997230', 19020901D, 1171.66, XSALES, '', '70', XOFFICE, '');
        InsertPeriodicEntry(0, '995420', 19020901D, -1171.66, '', '', '', '', '');
        InsertPeriodicEntry(0, '997110', 19020901D, 72871.71, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '995410', 19020901D, -72871.71, '', '', '', '', '');
        InsertPeriodicEntry(0, '997120', 19020901D, 20249.13, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '995420', 19020901D, -20249.13, '', '', '', '', '');
        InsertPeriodicEntry(0, '996710', 19020901D, -33037.8, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996810', 19020901D, -85.28, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996910', 19020901D, 3619.81, XSALES, XMEDIUM, '30', XOFFICE, '');
        InsertPeriodicEntry(0, '997140', 19020901D, -179.09, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '997240', 19020901D, -1283.66, XSALES, '', '30', XHOME, '');
        InsertPeriodicEntry(0, '998130', 19020901D, 2980.44, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020901D, 4470.66, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020901D, 7451.1, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020901D, 673.45, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020901D, 1010.18, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19020901D, 1683.63, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020901D, 899.8, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020901D, 1349.7, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19020901D, 2249.51, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020901D, 3155.23, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020901D, 4732.84, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19020901D, 7888.07, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020901D, 1566.0, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020901D, 2349.01, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19020901D, 3915.01, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020901D, 182.89, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020901D, 274.34, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19020901D, 457.23, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020901D, 73.73, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020901D, 110.6, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19020901D, 184.34, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020901D, 4305.98, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020901D, 6458.98, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19020901D, 10764.96, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19020901D, 1549.8, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19020901D, 2324.7, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19020901D, 3874.5, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020901D, 114.87, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020901D, 172.3, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19020901D, 287.17, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020901D, 2767.4, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020901D, 4151.1, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19020901D, 6918.51, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020901D, 90.46, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020901D, 135.69, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19020901D, 226.16, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020901D, 614.25, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020901D, 921.38, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19020901D, 1535.63, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020901D, 60.97, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020901D, 30.48, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020901D, 111.78, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020901D, 91.45, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020901D, 45.73, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020901D, 167.66, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19020901D, 152.42, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19020901D, 76.21, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19020901D, 279.44, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020901D, 60.32, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020901D, 90.48, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19020901D, 150.8, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020901D, 6.56, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020901D, 9.84, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19020901D, 16.4, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020901D, 146.62, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020901D, 219.92, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19020901D, 366.54, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020901D, 22181.25, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020901D, 33271.88, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19020901D, 55453.13, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020901D, 7175.33, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020901D, 10762.99, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19020901D, 17938.32, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020901D, 143.51, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020901D, 215.26, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19020901D, 358.77, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998740', 19020901D, 9282.48, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998740', 19020901D, 13923.72, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998740', 19020901D, 23206.2, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998910', 19020901D, 186.8, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '997250', 19020901D, 280.19, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998450', 19020901D, 466.99, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999210', 19020901D, 2542.18, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999210', 19020901D, 3813.28, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999210', 19020901D, 6355.46, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999230', 19020901D, 3901.32, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999230', 19020901D, 5851.97, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999230', 19020901D, 9753.29, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999220', 19020901D, 162.95, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999220', 19020901D, 244.43, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999220', 19020901D, 407.38, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020901D, 1770.76, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020901D, 2656.14, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19020901D, 4426.9, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020901D, 52.64, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020901D, 78.96, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19020901D, 131.6, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020901D, -15.17, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020901D, -22.75, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19020901D, -37.92, XSALES, '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020901D, -302909.44, '', '', '', '', '');

        InsertPeriodicEntry(0, '992310', 19020901D, -396906.11, '', '', '', '', '');
        InsertPeriodicEntry(0, '992320', 19020901D, -85666.15, '', '', '', '', '');
        InsertPeriodicEntry(0, '995410', 19020901D, 286955.03, '', '', '', '', '');
        InsertPeriodicEntry(0, '995420', 19020901D, 41724.53, '', '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19020901D, 153892.7, '', '', '', '', '');

        InsertPeriodicEntry(0, '996210', 19021001D, -623684.07, XSALES, XLARGE, '30', XOFFICE, '');
        InsertPeriodicEntry(0, '992310', 19021001D, 623684.07, '', '', '', '', '');
        InsertPeriodicEntry(0, '996230', 19021001D, -209360.49, XSALES, XSMALL, '80', XHOME, '');
        InsertPeriodicEntry(0, '992320', 19021001D, 209360.49, '', '', '', '', '');
        InsertPeriodicEntry(0, '996110', 19021001D, -96800.57, XSALES, XSMALL, '30', XINDUSTRIAL, '');
        InsertPeriodicEntry(0, '992310', 19021001D, 96800.57, '', '', '', '', '');
        InsertPeriodicEntry(0, '996120', 19021001D, -8068.83, XSALES, XSMALL, '30', XOFFICE, '');
        InsertPeriodicEntry(0, '992320', 19021001D, 8068.83, '', '', '', '', '');
        InsertPeriodicEntry(0, '996130', 19021001D, -11328.27, XSALES, XSMALL, '70', XOFFICE, '');
        InsertPeriodicEntry(0, '992320', 19021001D, 11328.27, '', '', '', '', '');
        InsertPeriodicEntry(0, '997210', 19021001D, 233115.8, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '995410', 19021001D, -233115.8, '', '', '', '', '');
        InsertPeriodicEntry(0, '997230', 19021001D, 79888.56, XSALES, '', '80', XHOME, '');
        InsertPeriodicEntry(0, '995420', 19021001D, -79888.56, '', '', '', '', '');
        InsertPeriodicEntry(0, '997110', 19021001D, 77623.66, XSALES, '', '30', XINDUSTRIAL, '');
        InsertPeriodicEntry(0, '995410', 19021001D, -77623.66, '', '', '', '', '');
        InsertPeriodicEntry(0, '997120', 19021001D, 4358.41, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '995420', 19021001D, -4358.41, '', '', '', '', '');
        InsertPeriodicEntry(0, '997130', 19021001D, 3950.13, XSALES, '', '70', XOFFICE, '');
        InsertPeriodicEntry(0, '995420', 19021001D, -3950.13, '', '', '', '', '');
        InsertPeriodicEntry(0, '996710', 19021001D, -22715.97, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996810', 19021001D, -209.92, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996910', 19021001D, 4333.93, XSALES, XLARGE, '30', XOFFICE, '');
        InsertPeriodicEntry(0, '997140', 19021001D, -766.08, XSALES, '', '70', XOFFICE, '');
        InsertPeriodicEntry(0, '997240', 19021001D, -2054.72, XSALES, '', '30', XOFFICE, '');
        InsertPeriodicEntry(0, '998130', 19021001D, 2160.39, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19021001D, 3240.59, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19021001D, 5400.98, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19021001D, 610.21, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19021001D, 915.32, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19021001D, 1525.53, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19021001D, 815.28, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19021001D, 1222.91, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19021001D, 2038.19, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19021001D, 2858.87, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19021001D, 4288.31, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19021001D, 7147.19, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19021001D, 1458.18, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19021001D, 2187.28, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19021001D, 3645.46, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19021001D, 170.3, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19021001D, 255.45, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19021001D, 425.75, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19021001D, 68.67, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19021001D, 103.01, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19021001D, 171.68, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19021001D, 1817.28, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19021001D, 2725.92, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19021001D, 4543.2, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19021001D, 511.68, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19021001D, 767.52, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19021001D, 1279.2, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19021001D, 40.04, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19021001D, 60.06, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19021001D, 100.11, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19021001D, 2576.9, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19021001D, 3865.35, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19021001D, 6442.25, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19021001D, 84.23, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19021001D, 126.35, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19021001D, 210.58, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19021001D, 571.98, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19021001D, 857.97, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19021001D, 1429.95, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19021001D, 56.77, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19021001D, 28.38, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19021001D, 104.07, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19021001D, 85.15, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19021001D, 42.57, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19021001D, 156.1, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19021001D, 141.91, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19021001D, 70.96, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19021001D, 260.17, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19021001D, 56.15, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19021001D, 84.23, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19021001D, 140.39, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19021001D, 15.27, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19021001D, 22.91, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19021001D, 38.18, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998620', 19021001D, 1403.05, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998620', 19021001D, 2104.58, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998620', 19021001D, 3507.63, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998630', 19021001D, 835.61, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998630', 19021001D, 1253.42, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998630', 19021001D, 2089.03, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19021001D, 213.44, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19021001D, 320.15, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19021001D, 533.59, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19021001D, 23312.74, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19021001D, 34969.12, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19021001D, 58281.86, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19021001D, 6333.16, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19021001D, 9499.73, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19021001D, 15832.89, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19021001D, 7175.33, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19021001D, 10762.99, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19021001D, 17938.32, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19021001D, 143.51, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19021001D, 215.26, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19021001D, 358.77, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998750', 19021001D, 2218.12, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998750', 19021001D, 3327.18, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998750', 19021001D, 5545.3, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '997150', 19021001D, 139.15, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998910', 19021001D, 208.73, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998450', 19021001D, 347.88, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19021001D, 1830.02, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19021001D, 2745.04, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19021001D, 4575.06, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19021001D, 49.02, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19021001D, 73.52, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19021001D, 122.54, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19021001D, 88.9, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19021001D, 133.35, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19021001D, 222.25, XSALES, '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19021001D, -267320.81, '', '', '', '', '');

        InsertPeriodicEntry(0, '992310', 19021001D, -483405.78, '', '', '', '', '');
        InsertPeriodicEntry(0, '992320', 19021001D, -126941.61, '', '', '', '', '');
        InsertPeriodicEntry(0, '995410', 19021001D, 266470.14, '', '', '', '', '');
        InsertPeriodicEntry(0, '995420', 19021001D, 52127.75, '', '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19021001D, 291749.5, '', '', '', '', '');

        InsertPeriodicEntry(0, '996210', 19021101D, -641629.34, XSALES, XSMALL, '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '992310', 19021101D, 641629.34, '', '', '', '', '');
        InsertPeriodicEntry(0, '996220', 19021101D, -233083.03, XSALES, XSMALL, '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '992320', 19021101D, 233083.03, '', '', '', '', '');
        InsertPeriodicEntry(0, '996110', 19021101D, -104857.78, XSALES, XMEDIUM, '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '992310', 19021101D, 104857.78, '', '', '', '', '');
        InsertPeriodicEntry(0, '996130', 19021101D, -19029.53, XSALES, XSMALL, '70', XHOME, XWINTER);
        InsertPeriodicEntry(0, '992320', 19021101D, 19029.53, '', '', '', '', '');
        InsertPeriodicEntry(0, '997210', 19021101D, 309681.81, XSALES, '', '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '995410', 19021101D, -309681.81, '', '', '', '', '');
        InsertPeriodicEntry(0, '997220', 19021101D, 6092.71, XSALES, '', '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '995420', 19021101D, -6092.71, '', '', '', '', '');
        InsertPeriodicEntry(0, '997110', 19021101D, 84654.03, XSALES, '', '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '995410', 19021101D, -84654.03, '', '', '', '', '');
        InsertPeriodicEntry(0, '997120', 19021101D, 1783.2, XSALES, '', '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '995420', 19021101D, -1783.2, '', '', '', '', '');
        InsertPeriodicEntry(0, '997130', 19021101D, 126.96, XSALES, '', '70', XHOME, XWINTER);
        InsertPeriodicEntry(0, '995420', 19021101D, -126.96, '', '', '', '', '');
        InsertPeriodicEntry(0, '996710', 19021101D, -17138.0, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996810', 19021101D, -236.16, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996910', 19021101D, 4840.36, XSALES, XSMALL, '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '998130', 19021101D, 2102.43, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '997240', 19021101D, -1952.12, XSALES, '', '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '998130', 19021101D, 3153.64, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19021101D, 5256.07, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19021101D, 593.84, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19021101D, 890.76, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19021101D, 1484.6, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19021101D, 793.39, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19021101D, 1190.09, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19021101D, 1983.48, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19021101D, 2782.2, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19021101D, 4173.3, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19021101D, 6955.5, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19021101D, 1498.41, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19021101D, 2247.61, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19021101D, 3746.02, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19021101D, 174.99, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19021101D, 262.49, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19021101D, 437.49, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19021101D, 70.56, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19021101D, 105.84, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19021101D, 176.4, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19021101D, 595.07, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19021101D, 892.61, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19021101D, 1487.68, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19021101D, 336.21, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19021101D, 504.32, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19021101D, 840.54, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19021101D, 102.36, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19021101D, 153.54, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19021101D, 255.91, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19021101D, 2647.96, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19021101D, 3971.94, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19021101D, 6619.9, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19021101D, 86.57, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19021101D, 129.85, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19021101D, 216.42, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19021101D, 587.75, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19021101D, 881.63, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19021101D, 1469.38, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19021101D, 58.33, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19021101D, 29.17, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19021101D, 106.94, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19021101D, 87.5, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19021101D, 43.75, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19021101D, 160.41, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19021101D, 145.83, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19021101D, 72.92, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19021101D, 267.36, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998520', 19021101D, 197.04, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998520', 19021101D, 295.55, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998520', 19021101D, 492.59, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19021101D, 57.7, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19021101D, 86.55, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19021101D, 144.26, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998630', 19021101D, 492.21, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998630', 19021101D, 738.32, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998630', 19021101D, 1230.53, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19021101D, 146.31, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19021101D, 219.47, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19021101D, 365.79, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19021101D, 22968.42, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19021101D, 34452.64, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19021101D, 57421.06, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19021101D, 4028.78, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19021101D, 6043.18, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19021101D, 10071.96, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19021101D, 7175.33, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19021101D, 10762.99, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19021101D, 17938.32, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19021101D, 143.51, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19021101D, 215.26, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19021101D, 358.77, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998740', 19021101D, 1964.51, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998740', 19021101D, 2946.77, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998740', 19021101D, 4911.28, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '997150', 19021101D, 142.98, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998910', 19021101D, 214.47, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998450', 19021101D, 357.46, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19021101D, 1690.31, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19021101D, 2535.47, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19021101D, 4225.78, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19021101D, 50.38, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19021101D, 75.57, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19021101D, 125.95, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19021101D, 119.92, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19021101D, 179.87, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19021101D, 299.79, XSALES, '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19021101D, -244232.09, '', '', '', '', '');

        InsertPeriodicEntry(0, '992310', 19021101D, -526985.26, '', '', '', '', '');
        InsertPeriodicEntry(0, '992320', 19021101D, -184596.33, '', '', '', '', '');
        InsertPeriodicEntry(0, '995410', 19021101D, 281638.56, '', '', '', '', '');
        InsertPeriodicEntry(0, '995420', 19021101D, 48148.54, '', '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19021101D, 381794.49, '', '', '', '', '');

        InsertPeriodicEntry(0, '996210', 19021201D, -703468.37, XSALES, XSMALL, '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '992310', 19021201D, 703468.37, '', '', '', '', '');
        InsertPeriodicEntry(0, '996230', 19021201D, -211576.19, XSALES, XSMALL, '50', XHOME, XWINTER);
        InsertPeriodicEntry(0, '992320', 19021201D, 211576.19, '', '', '', '', '');
        InsertPeriodicEntry(0, '996110', 19021201D, -79461.53, XSALES, XSMALL, '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '992310', 19021201D, 79461.53, '', '', '', '', '');
        InsertPeriodicEntry(0, '996120', 19021201D, -10821.24, XSALES, XSMALL, '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '992320', 19021201D, 10821.24, '', '', '', '', '');
        InsertPeriodicEntry(0, '996130', 19021201D, -12025.15, XSALES, XSMALL, '80', XHOME, XWINTER);
        InsertPeriodicEntry(0, '992320', 19021201D, 12025.15, '', '', '', '', '');
        InsertPeriodicEntry(0, '997210', 19021201D, 306509.81, XSALES, '', '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '995410', 19021201D, -306509.81, '', '', '', '', '');
        InsertPeriodicEntry(0, '997220', 19021201D, 131.26, XSALES, '', '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '995420', 19021201D, -131.26, '', '', '', '', '');
        InsertPeriodicEntry(0, '997230', 19021201D, 38505.98, XSALES, '', '50', XHOME, XWINTER);
        InsertPeriodicEntry(0, '995420', 19021201D, -38505.98, '', '', '', '', '');
        InsertPeriodicEntry(0, '997110', 19021201D, 77238.96, XSALES, '', '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '995410', 19021201D, -77238.96, '', '', '', '', '');
        InsertPeriodicEntry(0, '997120', 19021201D, 13649.84, XSALES, '', '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '995420', 19021201D, -13649.84, '', '', '', '', '');
        InsertPeriodicEntry(0, '996710', 19021201D, -20975.6, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996810', 19021201D, -234.19, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '996910', 19021201D, 3475.36, XSALES, XSMALL, '80', XHOME, XWINTER);
        InsertPeriodicEntry(0, '997140', 19021201D, -417.22, XSALES, '', '50', XHOME, XWINTER);
        InsertPeriodicEntry(0, '997240', 19021201D, -1707.57, XSALES, '', '30', XHOME, XWINTER);
        InsertPeriodicEntry(0, '998130', 19021201D, 2186.74, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19021201D, 3280.1, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19021201D, 5466.84, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19021201D, 617.58, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19021201D, 926.38, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998110', 19021201D, 1543.96, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19021201D, 825.27, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19021201D, 1237.91, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998120', 19021201D, 2063.19, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19021201D, 2893.72, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19021201D, 4340.58, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998130', 19021201D, 7234.3, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19021201D, 1333.88, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19021201D, 2000.83, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998210', 19021201D, 3334.71, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19021201D, 155.81, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19021201D, 233.72, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998230', 19021201D, 389.54, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19021201D, 62.82, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19021201D, 94.23, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998240', 19021201D, 157.05, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19021201D, 870.77, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19021201D, 1306.16, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998310', 19021201D, 2176.94, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19021201D, 498.56, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19021201D, 747.84, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998320', 19021201D, 1246.4, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19021201D, 400.24, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19021201D, 600.36, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998330', 19021201D, 1000.6, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19021201D, 2357.3, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19021201D, 3535.94, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998410', 19021201D, 5893.24, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19021201D, 77.09, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19021201D, 115.64, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998420', 19021201D, 192.74, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19021201D, 523.2, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19021201D, 784.8, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998430', 19021201D, 1308.0, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19021201D, 51.92, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19021201D, 25.96, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19021201D, 95.19, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19021201D, 77.89, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19021201D, 38.94, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19021201D, 142.79, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '995710', 19021201D, 129.81, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '995750', 19021201D, 64.91, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998510', 19021201D, 237.99, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19021201D, 51.38, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19021201D, 77.07, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998530', 19021201D, 128.45, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19021201D, 0.39, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19021201D, 0.59, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998610', 19021201D, 0.99, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998620', 19021201D, 90.53, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998620', 19021201D, 135.79, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998620', 19021201D, 226.32, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19021201D, 179.69, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19021201D, 269.54, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998640', 19021201D, 449.23, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19021201D, 21793.47, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19021201D, 32690.21, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998710', 19021201D, 54483.69, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19021201D, 7437.31, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19021201D, 11155.96, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998720', 19021201D, 18593.27, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19021201D, 150.28, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19021201D, 225.41, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998730', 19021201D, 375.69, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '998910', 19021201D, 127.29, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '997250', 19021201D, 190.94, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '998450', 19021201D, 318.23, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999110', 19021201D, -213.15, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999110', 19021201D, -319.72, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999110', 19021201D, -532.87, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999210', 19021201D, 2754.05, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999210', 19021201D, 4131.07, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999210', 19021201D, 6885.12, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999230', 19021201D, 4626.41, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999230', 19021201D, 6939.61, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999230', 19021201D, 11566.02, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999220', 19021201D, 150.49, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999220', 19021201D, 225.73, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999220', 19021201D, 376.22, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19021201D, 1309.18, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19021201D, 1963.78, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999240', 19021201D, 3272.96, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19021201D, 44.84, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19021201D, 67.27, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999250', 19021201D, 112.11, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19021201D, -171.08, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19021201D, -256.63, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999310', 19021201D, -427.71, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999320', 19021201D, 291.45, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999320', 19021201D, 437.17, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999320', 19021201D, 728.62, XSALES, '', '', '', '');
        InsertPeriodicEntry(0, '999510', 19021201D, 12568.96, XADM, '', '', '', '');
        InsertPeriodicEntry(0, '999510', 19021201D, 18853.44, XPROD, '', '', '', '');
        InsertPeriodicEntry(0, '999510', 19021201D, 31422.4, XSALES, '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19021201D, -300978.62, '', '', '', '', '');

        InsertPeriodicEntry(0, '992310', 19021201D, -942147.52, '', '', '', '', '');
        InsertPeriodicEntry(0, '992320', 19021201D, -273866.07, '', '', '', '', '');
        InsertPeriodicEntry(0, '995410', 19021201D, 338521.07, '', '', '', '', '');
        InsertPeriodicEntry(0, '995420', 19021201D, 19073.92, '', '', '', '', '');
        "Exactly Balanced" := true;
        InsertPeriodicEntry(0, '995310', 19021201D, 858418.6, '', '', '', '', '');

        InsertOtherEntry(0, '998810', 19021231D, '00-12A', XDepreciation, 14001.64, XADM);
        InsertOtherEntry(0, '998810', 19021231D, '00-12A', XDepreciation, 21002.46, XPROD);
        InsertOtherEntry(0, '998810', 19021231D, '00-12A', XDepreciation, 35004.1, XSALES);
        "Exactly Balanced" := true;
        InsertOtherEntry(0, '991140', 19021231D, '00-12A', XDepreciation, -70008.19, '');

        InsertOtherEntry(0, '998810', 19021231D, '00-12A', XDepreciation, 13662.51, XADM);
        InsertOtherEntry(0, '998810', 19021231D, '00-12A', XDepreciation, 20493.77, XPROD);
        InsertOtherEntry(0, '998810', 19021231D, '00-12A', XDepreciation, 34156.28, XSALES);
        "Exactly Balanced" := true;
        InsertOtherEntry(0, '991140', 19021231D, '00-12A', XDepreciation, -68312.56, '');

        InsertOtherEntry(0, '998820', 19021231D, '00-12A', XDepreciation, 32083.54, XADM);
        InsertOtherEntry(0, '998820', 19021231D, '00-12A', XDepreciation, 48125.32, XPROD);
        InsertOtherEntry(0, '998820', 19021231D, '00-12A', XDepreciation, 80208.86, XSALES);
        "Exactly Balanced" := true;
        InsertOtherEntry(0, '991240', 19021231D, '00-12A', XDepreciation, -160417.72, '');

        InsertOtherEntry(0, '998830', 19021231D, '00-12A', XDepreciation, 5043.56, XADM);
        InsertOtherEntry(0, '998830', 19021231D, '00-12A', XDepreciation, 7565.35, XPROD);
        InsertOtherEntry(0, '998830', 19021231D, '00-12A', XDepreciation, 12608.91, XSALES);
        "Exactly Balanced" := true;
        InsertOtherEntry(0, '991340', 19021231D, '00-12A', XDepreciation, -25217.82, '');

        InsertOtherEntry(0, '992330', 19021231D, '00-12B', XBalanceSheetChanges, 37665.42, '');
        InsertOtherEntry(0, '992340', 19021231D, '00-12B', XBalanceSheetChanges, 2280.91, '');
        InsertOtherEntry(0, '992910', 19021231D, '00-12B', XBalanceSheetChanges, 1103.92, '');
        InsertOtherEntry(0, '992920', 19021231D, '00-12B', XBalanceSheetChanges, 340.6, '');
        InsertOtherEntry(0, '992940', 19021231D, '00-12B', XBalanceSheetChanges, -5175.05, '');
        InsertOtherEntry(0, '994010', 19021231D, '00-12B', XBalanceSheetChanges, -24009.6, '');
        InsertOtherEntry(0, '995120', 19021231D, '00-12B', XBalanceSheetChanges, 49887.62, '');
        InsertOtherEntry(0, '995110', 19021231D, '00-12B', XBalanceSheetChanges, 9667.73, '');
        InsertOtherEntry(0, '995310', 19021231D, '00-12B', XBalanceSheetChanges, 141718.57, '');
        InsertOtherEntry(0, '995310', 19021231D, '00-12B', XBalanceSheetChanges, 178547.98, '');
        InsertOtherEntry(0, '995810', 19021231D, '00-12B', XBalanceSheetChanges, -95338.54, '');
        InsertOtherEntry(0, '995820', 19021231D, '00-12B', XBalanceSheetChanges, -35424.0, '');
        InsertOtherEntry(0, '995830', 19021231D, '00-12B', XBalanceSheetChanges, -17887.28, '');
        InsertOtherEntry(0, '995840', 19021231D, '00-12B', XBalanceSheetChanges, -6948.73, '');
        InsertOtherEntry(0, '995920', 19021231D, '00-12B', XBalanceSheetChanges, -38835.2, '');
        "Exactly Balanced" := true;
        InsertOtherEntry(0, '995310', 19021231D, '00-12B', XBalanceSheetChanges, -197594.35, '');

        CreatePeriodicDepr();

        InsertJobLine('998450', '992910', 19030126D, XW401, XParkingFee, 28, XGUILDFORD10CR, '1310', 0);
        InsertJobLine('998430', '992910', 19030127D, XW402, XRoadToll, 33.75, XGUILDFORD10CR, '1310', 35);
    end;

    procedure InsertEvaluationData()
    var
        CreateBankAccount: Codeunit "Create Bank Account";
        CreateGenJournalBatch: Codeunit "Create Gen. Journal Batch";
    begin
        DemoDataSetup.Get();
        "Entry Balance" := 0;
        "Exactly Balanced" := false;
        InsertDailyEntry(
          XGENERAL, CreateGenJournalBatch.GetDailyJournalBatchName(), 3, CreateBankAccount.GetSavingsBankAccountCode(), 19030119D, 1, 'BANK1', XPaymentDescription1,
          3, CreateBankAccount.GetCheckingBankAccountCode(), -2000.0, '', '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, CreateGenJournalBatch.GetDailyJournalBatchName(), 3, CreateBankAccount.GetSavingsBankAccountCode(), 19030119D, 1, 'BANK2', XPaymentDescription2,
          3, CreateBankAccount.GetCheckingBankAccountCode(), -3000.0, '', '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, CreateGenJournalBatch.GetDailyJournalBatchName(), 3, CreateBankAccount.GetSavingsBankAccountCode(), 19030119D, 1, 'DEPOSIT3', XPaymentDescription3,
          3, CreateBankAccount.GetCheckingBankAccountCode(), -4000.0, '', '', 0, '', 0D);
        InsertDailyEntry(
          XGENERAL, CreateGenJournalBatch.GetDailyJournalBatchName(), 3, CreateBankAccount.GetSavingsBankAccountCode(), 19030119D, 1, 'DEPOSIT4', XPaymentDescription4,
          3, CreateBankAccount.GetCheckingBankAccountCode(), -4000.0, '', '', 0, '', 0D);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        "Gen. Journal Batch": Record "Gen. Journal Batch";
        Customer: Record Customer;
        Vendor: Record Vendor;
        "FA Setup": Record "FA Setup";
        BlankGenJnlLine: Record "Gen. Journal Line";
        "General Ledger Setup": Record "General Ledger Setup";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimVal: Record "Dimension Value";
        CA: Codeunit "Make Adjustments";
        DimMgt: Codeunit DimensionManagement;
        "Entry Balance": Decimal;
        "Exactly Balanced": Boolean;
        "Line No.": Integer;
        XPURCH: Label 'PURCH';
        XSALES: Label 'SALES';
        XGENERAL: Label 'GENERAL';
        XVATSettlement: Label 'VAT Settlement';
        XCleaningExpensesDec: Label 'Cleaning Expenses, Dec.';
        XRent1stQuarter: Label 'Rent, 1st Quarter,';
        XWarehouseWindowReplacement: Label 'Warehouse Window Replacement';
        XDinnerwithMarsholmFurniture: Label 'Dinner with Marsholm Furniture';
        XNewTires: Label 'New Tires';
        XWWBOPERATING: Label 'WWB-OPERATING';
        XPayment: Label 'Payment';
        XSalariesWeek1AND2: Label 'Salaries, Week 1-2';
        XInvoiceno156683forGasoline: Label 'Invoice no. 156683 for Gasoline';
        XTOYOTA: Label 'TOYOTA';
        XVW: Label 'VW';
        XMERCEDES: Label 'MERCEDES';
        XWWBEUR: Label 'WWB-EUR';
        XBANK1: Label 'BANK1';
        XBankTransfer: Label 'Bank Transfer';
        XCoffeeandTea: Label 'Coffee and Tea';
        XPaymentAccSystemsHotline: Label 'Payment, Accounting Systems Hotline,';
        XADM: Label 'ADM';
        XBirthdayBreakfastMD: Label 'Birthday Breakfast, Managing Director';
        XPostage: Label 'Postage';
        XPackingTape: Label 'Packing Tape';
        XPROD: Label 'PROD';
        XRepairandUpgofSpraypaintRobot: Label 'Repair and Upgrade of Spray-paint Robot';
        XPackingMachine: Label 'Packing Machine';
        XBoxesforPackingMachine: Label 'Boxes for Packing Machine';
        XGlueforPackingMachine: Label 'Glue for Packing Machine';
        XMaterialsforPackingMachine: Label 'Materials for Packing Machine';
        XInvoiceno156786forGasoline: Label 'Invoice no. 156786 for Gasoline';
        XSMALL: Label 'SMALL';
        XOFFICE: Label 'OFFICE';
        XHOME: Label 'HOME';
        XINDUSTRIAL: Label 'INDUSTRIAL';
        XMEDIUM: Label 'MEDIUM';
        XLARGE: Label 'LARGE';
        XSUMMER: Label 'SUMMER';
        XWINTER: Label 'WINTER';
        XDepreciation: Label 'Depreciation';
        XBalanceSheetChanges: Label 'Balance Sheet Changes';
        XFA000010: Label 'FA000010';
        XFA000020: Label 'FA000020';
        XFA000030: Label 'FA000030';
        XFA000040: Label 'FA000040';
        XFA000050: Label 'FA000050';
        XFA000060: Label 'FA000060';
        XFA000070: Label 'FA000070';
        XFA000080: Label 'FA000080';
        XFA000090: Label 'FA000090';
        XSTART: Label 'START';
        XDEPR: Label 'DEPR';
        XDEFAULT: Label 'DEFAULT';
        XSALESCAMPAIGN: Label 'SALESCAMPAIGN';
        XBUSINESSGROUP: Label 'BUSINESSGROUP';
        XAREA: Label 'AREA';
        XCUSTOMERGROUP: Label 'CUSTOMERGROUP';
        XPERIODIC: Label 'PERIODIC';
        XGLOPEN: Label 'G/L OPEN';
        XBANKOPEN: Label 'BANK OPEN';
        XVENDOPEN: Label 'VEND OPEN';
        XCUSTOPEN: Label 'CUST OPEN';
        XNBL: Label 'NBL';
        XWWBUSD: Label 'WWB-USD';
        XOpeningEntriesCustomers: Label 'Opening Entries, Customers';
        XOpeningEntriesVendors: Label 'Opening Entries, Vendors';
        XOpeningEntriesBankAccounts: Label 'Opening Entries, Bank Accounts';
        XOpeningEntry: Label 'Opening Entry';
        XEntries12: Label 'Entries, %1 %2';
        GenJnlEntryDesc: Label '%1 %2';
        XSET4Q: Label 'SET-4Q';
        VATDocNumber: Label '%1%2';
        VATDocumentNo: Code[20];
        XJOBS: Label 'JOB';
        XW401: Label 'W4-01';
        XW402: Label 'W4-02';
        XParkingFee: Label 'Parking fee';
        XGUILDFORD10CR: Label 'GUILDFORD, 10 CR';
        XRoadToll: Label 'Road Toll';
        XPaymentDescription1: Label 'Transfer, January';
        XPaymentDescription2: Label 'Transfer of funds for Spring ';
        XPaymentDescription3: Label 'Deposit 3, ';
        XPaymentDescription4: Label 'Deposit 4, ';

    procedure InsertDailyEntry(JnlTemplateName: Code[10]; JnlBatchName: Code[10]; "Account Type": Option; "Account No.": Code[20]; Date: Date; "Document Type": Option; "Document No.": Code[20]; Description: Text[50]; "Bal. Account Type": Option; "Bal. Account No.": Code[20]; Amount: Decimal; "Shortcut Dimension 1 Code": Code[20]; "Shortcut Dimension 2 Code": Code[20]; "Applies-to Doc. Type": Option; "Applies-to Doc. No.": Code[20]; "Due Date": Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Amount := Amount * 100 / 13.12; // ECU -> DKK
        Date := CA.AdjustDate(Date);
        "Due Date" := CA.AdjustDate("Due Date");
        "General Ledger Setup".Get();
        if DemoDataSetup."Local Precision Factor" >= 1 then
            Amount := Round(
                Amount * DemoDataSetup."Local Currency Factor",
                "General Ledger Setup"."Amount Rounding Precision" * DemoDataSetup."Local Precision Factor")
        else // To avoid errors when posting the lines
            Amount := Round(Amount * DemoDataSetup."Local Currency Factor");

        InitGenJnlLine(GenJournalLine, JnlTemplateName, JnlBatchName);
        GenJournalLine.Validate("Posting Date", Date);
        GenJournalLine.Validate("Account Type", "Account Type");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then
            "Account No." := CA.Convert("Account No.");
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", "Document Type");
        GenJournalLine.Validate("Document No.", "Document No.");
        GenJournalLine.Validate(Description, StrSubstNo(GenJnlEntryDesc, Description, Date2DMY(Date, 3)));
        if "Document No." = '2588' then
            GenJournalLine.Validate(Description, StrSubstNo(GenJnlEntryDesc, Description, Date2DMY(Date, 3) - 1));
        GenJournalLine.Validate("Bal. Account Type", "Bal. Account Type");
        if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"G/L Account" then
            "Bal. Account No." := CA.Convert("Bal. Account No.");
        GenJournalLine.Validate("Bal. Account No.", "Bal. Account No.");

        if "Bal. Account No." = '' then
            if "Exactly Balanced" then begin
                if Abs(("Entry Balance" / Amount + 1) * 100) > 1 then
                    if not
                       Confirm(
                         StrSubstNo(
                           'Difference on Daily entries: %1 on %2\\' +
                           'Do you want to continue?', "Entry Balance" + Amount, Date),
                         true)
                    then
                        Error('Program terminated by the user');
                Amount := -"Entry Balance";
                "Entry Balance" := 0;
                "Exactly Balanced" := false;
            end else
                "Entry Balance" := "Entry Balance" + Amount;
        GenJournalLine.Validate(Amount, Amount);

        GenJournalLine.Validate("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
        GenJournalLine.Validate("Shortcut Dimension 2 Code", "Shortcut Dimension 2 Code");
        GenJournalLine.Validate("Applies-to Doc. Type", "Applies-to Doc. Type");
        GenJournalLine.Validate("Applies-to Doc. No.", "Applies-to Doc. No.");
        GenJournalLine.Validate("Due Date", "Due Date");

        case "Document No." of
            '2806':
                begin
                    GenJournalLine.Validate("Applies-to Doc. Type", 2);
                    GenJournalLine.Validate("Applies-to Doc. No.", '103021');
                end;
            '2807':
                begin
                    GenJournalLine.Validate("Applies-to Doc. Type", 3);
                    GenJournalLine.Validate("Applies-to Doc. No.", '104005');
                end;
        end;
        case "Document No." of
            '2701':
                GenJournalLine.Validate("External Document No.", '1');
            '2702':
                GenJournalLine.Validate("External Document No.", '2');
            '2703':
                GenJournalLine.Validate("External Document No.", '3');
            '2704':
                GenJournalLine.Validate("External Document No.", '4');
            '2705':
                GenJournalLine.Validate("External Document No.", '5');
            '2706':
                GenJournalLine.Validate("External Document No.", '6');
            '2707':
                GenJournalLine.Validate("External Document No.", '7');
            '2708':
                GenJournalLine.Validate("External Document No.", '8');
            '2709':
                GenJournalLine.Validate("External Document No.", '9');
            '2710':
                GenJournalLine.Validate("External Document No.", '10');
        end;
        case "Account No." of
            '49525252', '49633663', '49454647', '49494949':
                GenJournalLine.Validate("System-Created Entry", false);
        end;

        GenJournalLine.Insert();
    end;

    procedure InsertDailyEntry(CurrentJnlBatchName: Code[10]; "Account Type": Option; "Account No.": Code[20]; Date: Date; "Document Type": Option; "Document No.": Code[20]; Description: Text[50]; "Bal. Account Type": Option; "Bal. Account No.": Code[20]; Amount: Decimal; "Shortcut Dimension 1 Code": Code[20]; "Shortcut Dimension 2 Code": Code[20]; "Applies-to Doc. Type": Option; "Applies-to Doc. No.": Code[20]; "Due Date": Date)
    begin
        InsertDailyEntry(CurrentJnlBatchName, XDEFAULT, "Account Type", "Account No.", Date, "Document Type", "Document No.", Description, "Bal. Account Type", "Bal. Account No.", Amount, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Applies-to Doc. Type", "Applies-to Doc. No.", "Due Date");
    end;

    procedure InsertCustLine("Account No.": Code[20]; "Document No.": Code[20]; "Due Date": Date; Quantity: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        "Due Date" := CA.AdjustDate("Due Date");

        InitGenJnlLine(GenJournalLine, XSTART, XCUSTOPEN);
        GenJournalLine.Validate("Posting Date", CA.AdjustDate(19021231D));
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Document No.", "Document No.");
        GenJournalLine.Validate(Description, XOpeningEntriesCustomers);
        GenJournalLine.Validate("Due Date", "Due Date");
        GenJournalLine.Validate(Quantity, Quantity);
        GenJournalLine.Insert();
    end;

    procedure InsertVendLine("Account No.": Code[20]; "Document No.": Code[20]; "Due Date": Date; Quantity: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        "Due Date" := CA.AdjustDate("Due Date");
        InitGenJnlLine(GenJournalLine, XSTART, XVENDOPEN);
        GenJournalLine.Validate("Posting Date", CA.AdjustDate(19021231D));
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Document No.", "Document No.");
        GenJournalLine.Validate(Description, XOpeningEntriesVendors);
        GenJournalLine.Validate("Due Date", "Due Date");
        GenJournalLine.Validate(Quantity, Quantity);
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Insert();
    end;

    procedure InsertBankAccEntry("Account No.": Code[20]; "Document No.": Code[20]; Quantity: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        InitGenJnlLine(GenJournalLine, XSTART, XBANKOPEN);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Bank Account");
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Posting Date", CA.AdjustDate(19021231D));
        GenJournalLine.Validate("Document Type", 0);
        GenJournalLine.Validate("Document No.", "Document No.");
        GenJournalLine.Validate(Description, XOpeningEntriesBankAccounts);
        GenJournalLine.Validate(Quantity, Quantity);
        GenJournalLine.Insert();
    end;

    procedure InsertOpeningEntry("Account Type": Option; "Account No.": Code[20]; Date: Date; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Amount := Amount * 100 / 13.12;
        Date := CA.AdjustDate(Date);
        "General Ledger Setup".Get();
        if DemoDataSetup."Local Precision Factor" >= 1 then
            Amount := Round(
                Amount * DemoDataSetup."Local Currency Factor",
                "General Ledger Setup"."Amount Rounding Precision" * DemoDataSetup."Local Precision Factor")
        else // To avoid errors when posting the lines
            Amount := Round(Amount * DemoDataSetup."Local Currency Factor");

        InitGenJnlLine(GenJournalLine, XSTART, XGLOPEN);
        if Date = CA.AdjustDate(19011231D) then
            GenJournalLine.Validate("Posting Date", ClosingDate(Date))
        else
            GenJournalLine.Validate("Posting Date", Date);
        GenJournalLine.Validate("Account Type", "Account Type");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then
            "Account No." := CA.Convert("Account No.");
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", 0);
        GenJournalLine.Validate("Document No.", XSTART);
        GenJournalLine.Validate(Description, XOpeningEntry);

        if "Exactly Balanced" then begin
            if Abs(("Entry Balance" / Amount + 1) * 100) > 1 then
                if not
                   Confirm(
                     StrSubstNo(
                       'Difference on Opening entries: %1 on %2\\' +
                       'Do you want to continue?', "Entry Balance" + Amount, GenJournalLine."Posting Date"),
                     true)
                then
                    Error('Program terminated by the user');
            Amount := -"Entry Balance";
            "Entry Balance" := 0;
            "Exactly Balanced" := false;
        end else
            "Entry Balance" := "Entry Balance" + Amount;
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Insert();
    end;

    procedure InsertPeriodicEntry("Account Type": Option; "Account No.": Code[20]; Date: Date; Amount: Decimal; "Shortcut Dimension 1 Code": Code[20]; "Dimension 2 Value Code": Code[20]; "Dimension 3 Value Code": Code[20]; "Dimension 4 Value Code": Code[20]; "Dimension 5 Value Code": Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Amount := Amount * 100 / 13.12;
        Date := CA.AdjustDate(Date);
        "General Ledger Setup".Get();
        if DemoDataSetup."Local Precision Factor" >= 1 then
            Amount := Round(
                Amount * DemoDataSetup."Local Currency Factor",
                "General Ledger Setup"."Amount Rounding Precision" * DemoDataSetup."Local Precision Factor")
        else // To avoid errors when posting the lines
            Amount := Round(Amount * DemoDataSetup."Local Currency Factor");

        InitGenJnlLine(GenJournalLine, XSTART, XPERIODIC);
        GenJournalLine.Validate("Posting Date", Date);
        GenJournalLine.Validate("Account Type", "Account Type");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then
            "Account No." := CA.Convert("Account No.");
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", 0);
        GenJournalLine.Validate("Document No.", Format(Date2DMY(Date, 3)) + '-' + Format(Date2DMY(Date, 2)));
        GenJournalLine.Validate(Description, StrSubstNo(XEntries12, MonthName(Date), Date2DMY(Date, 3)));

        if "Exactly Balanced" then begin
            if Abs(("Entry Balance" / Amount + 1) * 100) > 1 then
                if not
                   Confirm(
                     StrSubstNo(
                       'Difference on Periodic entries: %1 on %2\\' +
                       'Do you want to continue?', "Entry Balance" + Amount, Date),
                     true)
                then
                    Error('Program terminated by the user');
            Amount := -"Entry Balance";
            "Entry Balance" := 0;
            "Exactly Balanced" := false;
        end else
            "Entry Balance" := "Entry Balance" + Amount;
        GenJournalLine.Validate(Amount, Amount);
        InsertTempDimSetEntry("General Ledger Setup"."Global Dimension 1 Code", "Shortcut Dimension 1 Code");
        InsertTempDimSetEntry(XCUSTOMERGROUP, "Dimension 2 Value Code");
        InsertTempDimSetEntry(XAREA, "Dimension 3 Value Code");
        InsertTempDimSetEntry(XBUSINESSGROUP, "Dimension 4 Value Code");
        InsertTempDimSetEntry(XSALESCAMPAIGN, "Dimension 5 Value Code");
        GenJournalLine."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        TempDimSetEntry.DeleteAll();
        DimMgt.UpdateGlobalDimFromDimSetID(
          GenJournalLine."Dimension Set ID",
          GenJournalLine."Shortcut Dimension 1 Code",
          GenJournalLine."Shortcut Dimension 2 Code");
        GenJournalLine.Insert();
    end;

    procedure InsertOtherEntry("Account Type": Option; "Account No.": Code[20]; Date: Date; "Document No.": Code[20]; Description: Text[50]; Amount: Decimal; "Shortcut Dimension 1 Code": Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Amount := Amount * 100 / 13.12;
        Date := CA.AdjustDate(Date);
        "General Ledger Setup".Get();
        if DemoDataSetup."Local Precision Factor" >= 1 then
            Amount := Round(
                Amount * DemoDataSetup."Local Currency Factor",
                "General Ledger Setup"."Amount Rounding Precision" * DemoDataSetup."Local Precision Factor")
        else // To avoid errors when posting the lines
            Amount := Round(Amount * DemoDataSetup."Local Currency Factor");

        InitGenJnlLine(GenJournalLine, XSTART, XDEFAULT);
        GenJournalLine.Validate("Posting Date", Date);
        GenJournalLine.Validate("Account Type", "Account Type");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then
            "Account No." := CA.Convert("Account No.");
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", 0);
        GenJournalLine.Validate("Document No.", "Document No.");
        GenJournalLine.Validate(Description, StrSubstNo(GenJnlEntryDesc, Description, Date2DMY(Date, 3)));

        if "Exactly Balanced" then begin
            if Abs(("Entry Balance" / Amount + 1) * 100) > 1 then
                if not
                   Confirm(
                     StrSubstNo(
                       'Difference on Other entries: %1 on %2\\' +
                       'Do you want to continue?', "Entry Balance" + Amount, Date),
                     true)
                then
                    Error('Program terminated by the user');
            Amount := -"Entry Balance";
            "Entry Balance" := 0;
            "Exactly Balanced" := false;
        end else
            "Entry Balance" := "Entry Balance" + Amount;
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Validate("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
        GenJournalLine.Insert();
    end;

    procedure SetExactlyBalanced()
    begin
        "Exactly Balanced" := true;
    end;

    procedure InsertEvaluationEntry("Account Type": Option; "Account No.": Code[20]; Date: Date; Amount: Decimal; DocumentNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        OpeningEntryDate: Date;
    begin
        DemoDataSetup.Get();
        Amount := Round(Amount * DemoDataSetup."Local Currency Factor", 0.01);

        OpeningEntryDate := CA.AdjustDate(19011231D);
        InitGenJnlLine(GenJournalLine, XGENERAL, XDEFAULT);
        if Date = OpeningEntryDate then
            GenJournalLine.Validate("Posting Date", ClosingDate(Date))
        else
            GenJournalLine.Validate("Posting Date", Date);
        GenJournalLine.Validate("Account Type", "Account Type");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"G/L Account" then
            "Account No." := CA.Convert("Account No.");
        GenJournalLine.Validate("Account No.", "Account No.");
        GenJournalLine.Validate("Document Type", 0);
        if DocumentNo <> '' then begin
            GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
            GenJournalLine.Validate("Document No.", DocumentNo);
            GenJournalLine.Validate(Description, DocumentNo);
        end else
            if Date = OpeningEntryDate then begin
                GenJournalLine.Validate("Document No.", XSTART);
                GenJournalLine.Validate(Description, XOpeningEntry);
            end else begin
                GenJournalLine.Validate("Document No.", Format(GenJournalLine."Posting Date", 0, '<Month,2>-<Year4>'));
                GenJournalLine.Validate(Description, Format(GenJournalLine."Posting Date", 0, '<Month Text> <Year4>'));
            end;

        if "Exactly Balanced" then begin
            Amount := -"Entry Balance";
            "Exactly Balanced" := false;
        end;
        "Entry Balance" := "Entry Balance" + Amount;

        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Insert();
    end;

    procedure InitGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; "Journal Template Name": Code[10]; "Journal Batch Name": Code[10])
    begin
        if ("Journal Template Name" <> "Gen. Journal Batch"."Journal Template Name") or
           ("Journal Batch Name" <> "Gen. Journal Batch".Name)
        then begin
            "Gen. Journal Batch".Get("Journal Template Name", "Journal Batch Name");
            if ("Gen. Journal Batch"."No. Series" <> '') or
               ("Gen. Journal Batch"."Posting No. Series" <> '')
            then begin
                "Gen. Journal Batch"."No. Series" := '';
                "Gen. Journal Batch"."Posting No. Series" := '';
                "Gen. Journal Batch".Modify();
            end;
            GenJournalLine.Reset();
            GenJournalLine.SetRange("Journal Template Name", "Journal Template Name");
            GenJournalLine.SetRange("Journal Batch Name", "Journal Batch Name");
            if GenJournalLine.Find('+') then
                "Line No." := GenJournalLine."Line No."
            else
                "Line No." := 0;
        end;
        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", "Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", "Journal Batch Name");
        "Line No." := "Line No." + 10000;
        GenJournalLine.Validate("Line No.", "Line No.");
        GenJournalLine."System-Created Entry" := true;
        GenJournalLine."Copy VAT Setup to Jnl. Lines" := "Gen. Journal Batch"."Copy VAT Setup to Jnl. Lines";
        GenJournalLine.SetUpNewLine(BlankGenJnlLine, 0, false);
    end;

    procedure MonthName(Date: Date) Name: Text[30]
    begin
        Name := Format(CA.AdjustDate(Date), 0, '<Month Text>');
    end;

    procedure CreatePeriodicDepr()
    var
        I: Integer;
        J: Integer;
        Description: Text[50];
    begin
        "FA Setup".Get();
        for I := 1 to 12 do
            for J := 1 to 9 do begin
                Description := CreateDescription(CalcDeprDate(I));
                InsertPeriodicDepr(GetFANo(J), CalcDeprDate(I), Description, I);
            end;
    end;

    procedure InsertPeriodicDepr("FA No.": Code[20]; "Posting Date": Date; Description: Text[50]; I: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempText: Text[10];
    begin
        InitGenJnlLine(GenJournalLine, XSTART, XDEPR);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Fixed Asset");
        GenJournalLine.Validate("FA Posting Type", GenJournalLine."FA Posting Type"::Depreciation);
        GenJournalLine.Validate("Account No.", "FA No.");
        GenJournalLine.Validate("Depreciation Book Code", "FA Setup"."Default Depr. Book");
        GenJournalLine.Validate("Posting Date", CA.AdjustDate("Posting Date"));
        if Date2DMY(GenJournalLine."Posting Date" + 1, 1) <> 1 then
            GenJournalLine.Validate("Posting Date", GenJournalLine."Posting Date" + 1);
        GenJournalLine."Depr. until FA Posting Date" := true;
        if I >= 10 then
            TempText := ''
        else
            TempText := '0';
        GenJournalLine.Validate(
          "Document No.",
          'D' + Format(Date2DMY(GenJournalLine."Posting Date", 3)) + TempText +
          Format(Date2DMY(GenJournalLine."Posting Date", 2)) + '0001');
        GenJournalLine.Description := Description;
        GenJournalLine.Insert();
    end;

    procedure GetFANo(J: Integer): Code[20]
    begin
        case J of
            1:
                exit(XFA000010);
            2:
                exit(XFA000020);
            3:
                exit(XFA000030);
            4:
                exit(XFA000040);
            5:
                exit(XFA000050);
            6:
                exit(XFA000060);
            7:
                exit(XFA000070);
            8:
                exit(XFA000080);
            9:
                exit(XFA000090);
        end;
    end;

    procedure CreateDescription(DeprDate: Date): Text[50]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine."FA Posting Type" := GenJnlLine."FA Posting Type"::Depreciation;
        exit(StrSubstNo(
            '%1 %2 %3',
            GenJnlLine."FA Posting Type",
            MonthName(DeprDate),
            Date2DMY(CA.AdjustDate(DeprDate), 3)));
    end;

    procedure CalcDeprDate(J: Integer): Date
    var
        DeprDate: Date;
    begin
        case J of
            1:
                DeprDate := 19020131D;
            2:
                DeprDate := 19020228D;
            3:
                DeprDate := 19020331D;
            4:
                DeprDate := 19020430D;
            5:
                DeprDate := 19020531D;
            6:
                DeprDate := 19020630D;
            7:
                DeprDate := 19020731D;
            8:
                DeprDate := 19020831D;
            9:
                DeprDate := 19020930D;
            10:
                DeprDate := 19021031D;
            11:
                DeprDate := 19021130D;
            12:
                DeprDate := 19021231D;
        end;
        exit(DeprDate);
    end;

    procedure InsertJobLine("Account No.": Code[20]; "Bal. Account No.": Code[20]; "Posting Date": Date; "Document No.": Code[20]; Description: Text[50]; Amount: Decimal; "Job No.": Code[20]; "Job Task No.": Code[20]; Amount2: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Amount := Amount * 100 / 13.12; // ECU -> DKK
        Amount2 := Amount2 * 100 / 13.12; // ECU -> DKK

        InitGenJnlLine(GenJournalLine, XJOBS, XDEFAULT);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", CA.Convert("Account No."));
        GenJournalLine.Validate("Posting Date", CA.AdjustDate("Posting Date"));
        GenJournalLine.Validate("Document Type", 0);
        GenJournalLine.Validate("Document No.", "Document No.");
        GenJournalLine.Validate(Description, Description);
        Amount := Round(
            Amount * DemoDataSetup."Local Currency Factor", DemoDataSetup."Local Precision Factor");
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Validate("Bal. Account No.", CA.Convert("Bal. Account No."));
        GenJournalLine.Validate("Job No.", "Job No.");
        GenJournalLine.Validate("Job Task No.", "Job Task No.");
        GenJournalLine.Validate("Job Line Type", GenJournalLine."Job Line Type"::"Both Budget and Billable");
        GenJournalLine.Validate("Job Quantity", 1);

        if Amount2 <> 0 then begin
            Amount2 := Round(
                Amount2 * DemoDataSetup."Local Currency Factor", DemoDataSetup."Local Precision Factor");
            GenJournalLine.Validate("Job Unit Price", Amount2);
        end;
        GenJournalLine.Validate("System-Created Entry", false);
        GenJournalLine.Insert();
    end;

    local procedure InsertTempDimSetEntry(DimCode: Code[20]; DimValCode: Code[20])
    begin
        if DimCode = '' then
            exit;
        if DimValCode = '' then
            exit;
        DimVal.Get(DimCode, DimValCode);
        TempDimSetEntry."Dimension Code" := DimVal."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimVal.Code;
        TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
        TempDimSetEntry.Insert();
    end;

    procedure CreateGenJnlLine(Description: Text[50]; PostingDate: Date; CustomerNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Init();
        InitGenJnlLine(GenJournalLine, XGENERAL, XDEFAULT);

        GenJournalLine.Validate("Posting Date", NormalDate(PostingDate));
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Account No.", CustomerNo);
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Validate(Description, Description);
        GenJournalLine.Validate("Document No.", CustomerNo);

        DemoDataSetup.Get();
        GenJournalLine.Insert();
    end;
}

