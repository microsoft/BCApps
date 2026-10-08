codeunit 101225 "Create Post Code"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        ImportLocalPostCodes();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Standard then
            exit;

        InsertData('AT-1100', XWien, '');
        InsertData('AT-1230', XWien, '');
        InsertData('AT-2355', XWrNeudorf, '');
        InsertData('AT-4810', XGmunden, '');
        InsertData('AT-5730', XMittersill, '');
        InsertData('AT-8850', XMurau, '');
        InsertData('AU-2000', XSydneyNSW, '');
        InsertData('AU-2500', XWollongongNSW, '');
        InsertData('AU-3000', XMelbourneVIC, '');
        InsertData('AU-4000', XBrisbaneQLD, '');
        InsertData('AU-6800', XPerthWA, '');
        InsertData('AU-7178', XMurdunnaTAS, '');
        InsertData('BE-1851', XHumbeek, '');
        InsertData('BE-2050', XAntwerpen, '');
        InsertData('BE-2200', XHerentals, '');
        InsertData('BE-2800', XMechelen, '');
        InsertData('BE-3000', XLeuven, '');
        InsertData('BE-8500', XKortrijk, '');
        InsertData('BG-1000', XSofia, '');
        InsertData('BG-2500', XKustendil, '');
        InsertData('BG-2700', XBlagoevgrad, '');
        InsertData('BG-4000', XPlovdiv, '');
        InsertData('BG-8700', XElhovo, '');
        InsertData('BG-9000', XVarna, '');
        InsertData('CA-MB R0M 0N0', XElkhorn, '');
        InsertData('CA-ON L6J 3J3', XOakville, '');
        InsertData('CA-ON M5E 1G5', XToronto, '');
        InsertData('CA-ON N6B 1V7', XLondon, '');
        InsertData('CA-ON P7A 4K8', XThunderBay, '');
        InsertData('CA-ON P7B 5E2', XThunderBay, '');
        InsertData('CZ-696 42', XVracov, '');
        InsertData('CZ-697 01', XKyjov, '');
        InsertData('CZ-678 01', XBlansko, '');
        InsertData('CZ-669 02', XZnojmo, '');
        InsertData('CZ-687 71', XBojkovice, '');
        InsertData('CZ-779 00', XOlomouch, '');
        InsertData('CH-8200', XSchaffhausen, '');
        InsertData('CH-6005', XLuzern, '');
        InsertData('CH-8152', XGlattbrugg, '');
        InsertData('CH-6343', XRotkreuz, '');
        InsertData('CH-4133', XPratteln, '');
        InsertData('CH-6405', XImmensee, '');
        InsertData('DE-20097', XHamburg, '');
        InsertData('DE-22417', XHamburg36, '');
        InsertData('DE-40593', XDusseldorf, '');
        InsertData('DE-60320', XFrankfurtMain, '');
        InsertData('DE-72800', XEningen, '');
        InsertData('DE-80807', XMunchen, '');
        InsertData('DE-80997', XMunchen, '');
        InsertData('DE-86899', XLandsbergamLech, '');
        InsertData('DK-2100', XKobenhavn, '');
        InsertData('DK-2950', XVedbek, '');
        InsertData('DK-4600', XKoge, '');
        InsertData('DK-5000', XOdenseC, '');
        InsertData('DK-5800', XNyborg, '');
        InsertData('DK-8000', XArhusC, '');
        InsertData('DK-8200', XArhusN, '');
        InsertData('DK-9000', XAlborg, '');
        InsertData('DZ-05400', XBARIKA, '');
        InsertData('DZ-16000', XALGIERS, '');
        InsertData('DZ-16012', XALGIERS, '');
        InsertData('DZ-16027', XALGIERS, '');
        InsertData('DZ-21000', XMOSTAGANCU, '');
        InsertData('DZ-40000', XKHENCHE, '');
        InsertData('EE-10127', XTallinn, '');
        InsertData('EE-20607', XNarva, '');
        InsertData('EE-44313', XRakvere, '');
        InsertData('EE-45109', XTapa, '');
        InsertData('EE-49603', XMustvee, '');
        InsertData('EE-76806', XPaldiski, '');
        InsertData('ES-46007', XValencia, '');
        InsertData('ES-08010', XBarcelona, '');
        InsertData('ES-28003', XMadrid, '');
        InsertData('ES-37001', XSalamanca, '');
        InsertData('ES-07001', XPalmaMallorca, '');
        InsertData('ES-03003', XAlicante, '');
        InsertData('ES-36004', XPontevedra, '');
        InsertData('ES-50001', XZaragoza, '');
        InsertData('ES-41006', XSevilla, '');
        InsertData('ES-10003', XCaceres, '');
        InsertData('ES-47002', XValladolid, '');
        InsertData('FI-00100', XHelsinki, '');
        InsertData('FI-00101', XHelsinki, '');
        InsertData('FI-00260', XHelsinki, '');
        InsertData('FI-01800', XKlaukkala, '');
        InsertData('FI-05400', XJokela, '');
        InsertData('FI-88900', XKuhmo, '');
        InsertData('FR-44450', XLACHAPELLEBASSEMER, '');
        InsertData('FR-50670', XCASSEL, '');
        InsertData('FR-75000', XPARIS, '');
        InsertData('FR-77450', XESBLY, '');
        InsertData('FR-78370', XPLAISIR, '');
        InsertData('FR-83250', XLALONDELESMAURES, '');
        InsertData('EL-106 75', XAthens, '');
        InsertData('EL-106 82', XAthens, '');
        InsertData('EL-185 40', XPiraeus, '');
        InsertData('EL-546 35', XThessaloniki, '');
        InsertData('EL-731 33', XChania, '');
        InsertData('EL-851 03', XKolymbia, '');
        InsertData('HR-10000', XZagreb, '');
        InsertData('HR-20000', XDubrovnik, '');
        InsertData('HR-21000', XSplit, '');
        InsertData('HR-22000', XSibenik, '');
        InsertData('HR-43000', XBjelovar, '');
        InsertData('HR-52210', XRovinj, '');
        InsertData('HU-1107', XBudapest, '');
        InsertData('HU-1161', XBudapest, '');
        InsertData('HU-1204', XBudapest, '');
        InsertData('HU-2500', XEsztergom, '');
        InsertData('HU-3258', XTarnalelesz, '');
        InsertData('HU-3325', XNoszvaj, '');
        InsertData('ID-10310', XJakarta, '');
        InsertData('ID-10440', XJakarta, '');
        InsertData('ID-11470', XJakarta, '');
        InsertData('ID-15156', XTangerang, '');
        InsertData('ID-40135', XBandung, '');
        InsertData('ID-60172', XSurabaya, '');
        InsertData('IN-110002', XDelhi, '');
        InsertData('IN-400001', XMumbai, '');
        InsertData('IN-440001', XNagpur, '');
        InsertData('IN-560001', XBangalore, '');
        InsertData('IN-600001', XChennai, '');
        InsertData('IN-700001', XKolkata, '');
        InsertData('IT-00100', XROMARM, '');
        InsertData('IT-10100', XTORINOTO, '');
        InsertData('IT-20100', XMILANOMI, '');
        InsertData('IT-39100', XBOLZANOBZ, '');
        InsertData('IT-61100', XSANTAVENERANDAPS, '');
        InsertData('IT-67067', XPESCINAAQ, '');
        InsertData('IS-101', XReykjavik, '');
        InsertData('IS-108', XReykjavik, '');
        InsertData('IS-112', XReykjavik, '');
        InsertData('IS-200', XKopavogur, '');
        InsertData('IS-220', XHafnafjordur, '');
        InsertData('IS-300', XAkranes, '');
        InsertData('KE-0 0100', XNairobi, '');
        InsertData('KE-0 1007', XKairi, '');
        InsertData('KE-5 0413', XAdungosi, '');
        InsertData('KE-6 0500', XMarsabit, '');
        InsertData('KE-8 0100', XMombasa, '');
        InsertData('KE-8 0200', XMalindi, '');
        InsertData('LT-2600', XVilnius, '');
        InsertData('LT-2700', XVilnius, '');
        InsertData('LT-3000', XKaunas, '');
        InsertData('LT-3042', XKaunas, '');
        InsertData('LT-4600', XRudiskes, '');
        InsertData('LT-5800', XKlaipeda, '');
        InsertData('LV-1011', XRiga, '');
        InsertData('LV-1039', XRiga, '');
        InsertData('LV-3270', XDundaga, '');
        InsertData('LV-3900', XBauska, '');
        InsertData('LV-5002', XOgre, '');
        InsertData('LV-5113', XKoknese, '');
        InsertData('MA-10100', XAGDALRABAT, '');
        InsertData('MA-10101', XRIADRABAT, '');
        InsertData('MA-12000', XTEMARA, '');
        InsertData('MA-20000', XCASABLANCA, '');
        InsertData('MA-20200', XCASABLANCA, '');
        InsertData('MA-20800', XMOHAMMEDIA, '');
        InsertData('MA-90000', XKASBAHTANGER, '');
        InsertData('MY-42000', XPELABUHANKLANGSelangor, '');
        InsertData('MY-47400', XPETALINGJAYASelangor, '');
        InsertData('MY-50450', XAMPANGKualaLumpur, '');
        InsertData('MY-57000', XKUALALUMPUR, '');
        InsertData('MY-88100', XKOTAKINABALUSabah, '');
        InsertData('MY-93450', XKUCHINGSarawak, '');
        InsertData('MZ-00300', XMaputo, '');
        InsertData('NG-300001', XBENINEdostate, '');
        InsertData('NG-900001', XABUJA, '');
        InsertData('NG-930283', XJOSPlateaustate, '');
        InsertData('NG-931104', XGHOHPlateaustate, '');
        InsertData('NL-1009 AG', XAmsterdam, '');
        InsertData('NL-1530 JM', XZaandam, '');
        InsertData('NL-5132 EE', XWaalwijk, '');
        InsertData('NL-6827 BP', XArnhem, '');
        InsertData('NL-7202 BP', XZutphen, '');
        InsertData('NL-7321 HE', XApeldoorn, '');
        InsertData('NO-1300', XSandvika, '');
        InsertData('NO-1324', XLysaker, '');
        InsertData('NO-1344', XHaslum, '');
        InsertData('NO-1370', XAsker, '');
        InsertData('NO-1400', XSki, '');
        InsertData('NO-0552', XOslo, '');
        InsertData('NO-0661', XOslo, '');
        InsertData('NZ-1001', XAuckland, '');
        InsertData('NZ-5473', XWoodville, '');
        InsertData('NZ-5491', XDannevirke, '');
        InsertData('NZ-6001', XWellington, '');
        InsertData('NZ-7900', XHokitika, '');
        InsertData('NZ-8001', XChristchurch, '');
        InsertData('PH-1000', XManila, '');
        InsertData('PH-1003', XSantaCruzManila, '');
        InsertData('PH-1012', XTondoManila, '');
        InsertData('PH-1117', XCapriQuezonCity, '');
        InsertData('PH-1440', XValenzuela, '');
        InsertData('PH-7000', XZamboangaCity, '');
        InsertData('PL 02-515', XWarszawa, '');
        InsertData('PL 11-430', XKorsze, '');
        InsertData('PL 14-510', XOrneta, '');
        InsertData('PL 15-660', XBialystok, '');
        InsertData('PL 45-418', XOpole, '');
        InsertData('PL 59-300', XLubin, '');
        InsertData('PT 1050-042', XLISBOA, '');
        InsertData('PT 1100-150', XLISBOA, '');
        InsertData('PT 3000-337', XCOIMBRA, '');
        InsertData('PT 4000-322', XPORTO, '');
        InsertData('PT 9000-064', XFUNCHAL, '');
        InsertData('PT 9500-101', XPONTADELGADA, '');
        InsertData('RO-200331', XCraiova, '');
        InsertData('RO-500209', XBrasov, '');
        InsertData('RO-550264', XSibiu, '');
        InsertData('RO-050724', XBucuresti, '');
        InsertData('RO-050729', XBucuresti, '');
        InsertData('RO-051511', XBucuresti, '');
        InsertData('RU-103054', XMoskva, '');
        InsertData('RU-109456', XMoskva, '');
        InsertData('RU-197342', XSanktPetersburg, '');
        InsertData('RU-443008', XSamara, '');
        InsertData('RU-603061', XNizhnyNovgorod, '');
        InsertData('RU-690001', XVladivostok, '');
        InsertData('SE-114 32', XStockholm, '');
        InsertData('SE-302 50', XHalmstad, '');
        InsertData('SE-415 06', XGoteborg, '');
        InsertData('SE-521 03', XKinnared, '');
        InsertData('SE-550 05', XJonkobing, '');
        InsertData('SE-600 03', XNorrkobing, '');
        InsertData('SE-852 33', XSundsvall, '');
        InsertData('SG-038988', XSingapore, '');
        InsertData('SI-1000', XLjubljana, '');
        InsertData('SI-2000', XMaribor, '');
        InsertData('SI-3231', XGrobelno, '');
        InsertData('SI-4502', XKranj, '');
        InsertData('SI-6000', XKoper, '');
        InsertData('SI-8283', XBlanca, '');
        InsertData('SK-026 01', XDolnyKubin, '');
        InsertData('SK-049 21', XBetliar, '');
        InsertData('SK-813 38', XBratislava, '');
        InsertData('SK-821 04', XBratislava, '');
        InsertData('SK-905 01', XSenica, '');
        InsertData('SK-985 01', XKalinovo, '');
        InsertData('SZ-H100', XMbabane, '');
        InsertData('SZ-H101', XSwaziPlaza, '');
        InsertData('SZ-H108', XPiggsPeak, '');
        InsertData('SZ-L300', XSiteki, '');
        InsertData('SZ-H200', XManzini, '');
        InsertData('SZ-S400', XNhlangano, '');
        InsertData('TH-10260', XBangNaBangkok, '');
        InsertData('TH-10500', XBangRakBangkok, '');
        InsertData('TH-10510', XKhlongSamwaBangkok, '');
        InsertData('TH-17120', XWatSingChaiNat, '');
        InsertData('TH-31260', XNonDindaengBuriRam, '');
        InsertData('TH-50120', XSanPaTongChiangMai, '');
        InsertData('TN-1002', XTunisBelvedere, '');
        InsertData('TN-1030', XTunis, '');
        InsertData('TN-1111', XZaghouan, '');
        InsertData('TN-3100', XKairouan, '');
        InsertData('TN-8129', XAinDraham, '');
        InsertData('TN-8170', XBouSalem, '');
        InsertData('TR-06531', XAnkara, '');
        InsertData('TR-42020', XKonya, '');
        InsertData('TR-45030', XManisa, '');
        InsertData('TR-80080', XIstanbul, '');
        InsertData('TR-81420', XKartalIstanbul, '');
        InsertData('TR-81700', XTuzlaIstanbul, '');
        InsertData('TZ-DSM', XDarEsSalaam, '');
        InsertData('UG-KLA', XKampala, '');
        InsertData('UG-EBB', XEntebbe, '');
        InsertData('US-AL 35242', XBirmingham, '');
        InsertData('US-FL 37125', XMiami, 'FL');
        InsertData('US-GA 31772', XAtlanta, 'GA');
        InsertData('US-IL 61236', XChicago, '');
        InsertData('US-NY 11010', XNewYork, '');
        InsertData('US-SC 27136', XColombia, '');
        InsertData('ZA-0001', XPretoria, '');
        InsertData('ZA-0700', XPietersburg, '');
        InsertData('ZA-2000', XJohannesburg, '');
        InsertData('ZA-2500', XCarletonville, '');
        InsertData('ZA-2940', XNewcastle, '');
        InsertData('ZA-3600', XDurban, '');
        InsertData('ZA-3900', XRichardsBay, '');
        InsertData('ZA-6000', XPortElizabeth, '');
        InsertData('ZA-8000', XCapeTown, '');
        InsertData('ZA-9300', XBloemfontein, '');
        InsertData('GB-B27 4KT', XBirmingham, '');
        InsertData('GB-CB1 2FB', XCambridge, '');
        InsertData('GB-CV6 1GY', XCoventry, '');
        InsertData('GB-CV9 3QN', XAtherstone, '');
        InsertData('GB-EC2A 3JL', XLondon, '');
        InsertData('GB-EH1 3EG', XEdinburgh, '');
        InsertData('GB-M22 5TG', XManchester, '');
        InsertData('GB-MO2 4RT', XManchester, '');
        InsertData('GB-ME5 6RL', XMaidstone, '');
        InsertData('GB-DY5 4DJ', XDudley, '');
        InsertData('GB-PE17 4RN', XCambridge, '');
        InsertData('GB-RG6 1WG', XReading, '');
        InsertData('GB-N12 5XY', XLondon, '');
        InsertData('GB-GU2 7YQ', XGuildford, '');
        InsertData('GB-GU2 7XH', XGuildford, '');
        InsertData('GB-GU52 8DY', XFleet, '');
        InsertData('GB-GU7 5GT', XGuildford, '');
        InsertData('GB-GU3 2SE', XGuildford, '');
        InsertData('GB-PO7 2HI', XPortsmouth, '');
        InsertData('GB-E12 5TG', XEdinburgh, '');
        InsertData('GB-N16 34Z', XLondon, '');
        InsertData('GB-WD2 4RG', XWatford, '');
        InsertData('GB-GL1 9HM', XGloucester, '');
        InsertData('GB-W1 3AL', XLondon, '');
        InsertData('GB-WC1 3DG', XLondon, '');
        InsertData('GB-W2 6BD', XLondon, '');
        InsertData('GB-W2 8HG', XLondon, '');
        InsertData('GB-IB7 7VN', XGainsborough, '');
        InsertData('GB-SA3 7HI', XStratford, '');
        InsertData('GB-SE1 0AX', XLondon, '');
        InsertData('GB-PE21 3TG', XPeterborough, '');
        InsertData('GB-L18 6SA', XLiverpool, '');
        InsertData('GB-GL50 1TY', XCheltenham, '');
        InsertData('GB-GL78 5TT', XCheltenham, '');
        InsertData('GB-TA3 4FD', XNewquay, '');
        InsertData('GB-NE21 3YG', XNewcastle, '');
        InsertData('GB-PO21 6HG', XSouthseaPortsmouth, '');
        InsertData('GB-BR1 2ES', XBromley, '');
        InsertData('GB-WC1 2GS', XWestEndLane, '');
        InsertData('GB-MK41 5AE', XBedford, '');
        InsertData('GB-DA5 3EF', XSidcup, '');
        InsertData('GB-CT6 21ND', XHythe, '');
        InsertData('GB-PL14 5GB', XPlymouth, '');
        InsertData('GB-M61 2YG', XManchester, '');
        InsertData('GB-CB3 7GG', XCambridge, '');
        InsertData('GB-HG1 7YW', XRipon, '');
        InsertData('GB-CF22 1XU', XCardiff, '');
        InsertData('GB-OX16 0UA', XCheddington, '');
        InsertData('GB-B31 2AL', XBirmingham, '');
        InsertData('GB-BS3 6KL', XBristol, '');
        InsertData('GB-SK21 5DL', XMacclesfield, '');
        InsertData('GB-TQ17 8HB', XBrixham, '');
        InsertData('GB-WD6 9HY', XBorehamwood, '');
        InsertData('GB-EH16 8JS', XEdinburgh, '');
        InsertData('GB-HP43 2AY', XTring, '');
        InsertData('GB-WD1 6YG', XWatford, '');
        InsertData('GB-LL6 5GB', XRhyl, '');
        InsertData('GB-MK21 7GG', XBletchley, '');
        InsertData('GB-SA1 2HS', XSwansea, '');
        InsertData('GB-LU3 4FY', XLuton, '');
        InsertData('GB-BA24 6KS', XBath, '');
        InsertData('GB-LE16 7YH', XLeicester, '');
        InsertData('GB-PE23 5IK', XKingsLynn, '');
        InsertData('GB-B68 5TT', XBromsgrove, '');
        InsertData('GB-B32 4TF', XSparkhillBirmingham, '');
        InsertData('GB-NP5 6GH', XNewport, '');
        InsertData('GB-NP10 8BE', XNewport, '');
        InsertData('GB-WD6 8UY', XBorehamwood, '');
        InsertData('GB-TN27 6YD', XAshford, '');
        InsertData('GB-LN23 6GS', XLincoln, '');
        InsertData('MX-01030', XMexicoCityDF, '');
        InsertData('MX-06000', XMexicoCityDF, '');
        InsertData('MX-37500', XLeonGuanajuato, '');
        InsertData('MX-64640', XMonterreyNuevoLeon, '');
        InsertData('MX-78030', XSanLuisPotosiSanLuis, '');
        InsertData('MX-82100', XMazatlanSinaloa, '');
        InsertData('RS-11000', XBeograd, '');
        InsertData('RS-11001', XBeograd, '');
        InsertData('RS-19210', XBor, '');
        InsertData('RS-21000', XNoviSad, '');
        InsertData('RS-24000', XSubotica, '');
        InsertData('RS-34000', XKragujevac, '');
        InsertData('BR 05428-002', XSaoPauloSP, '');
        InsertData('BR 22291-040', XRiodeJaneiroRJ, '');
        InsertData('BR 51021-040', XRecifePE, '');
        InsertData('BR 70710-926', XBrasiliaDF, '');
        InsertData('BR 80020-290', XCuritibaPR, '');
        InsertData('BR 90040-130', XPortoAlegreRS, '');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        "Post Code": Record "Post Code";
        XKobenhavn: Label 'Copenhagen', Comment = 'Translate';
        XVedbek: Label 'Vedbaek', Comment = 'Translate';
        XKoge: Label 'Koge', Comment = 'Translate';
        XArhusC: Label 'Arhus C', Comment = 'Translate';
        XArhusN: Label 'Arhus N', Comment = 'Translate';
        XMoskva: Label 'Moskva';
        XSanktPetersburg: Label 'Sankt Petersburg';
        XSamara: Label 'Samara';
        XNizhnyNovgorod: Label 'Nizhny Novgorod';
        XVladivostok: Label 'Vladivostok';
        XWien: Label 'Wien';
        XWrNeudorf: Label 'Wr. Neudorf';
        XGmunden: Label 'Gmunden';
        XMittersill: Label 'Mittersill';
        XMurau: Label 'Murau';
        XSydneyNSW: Label 'Sydney, NSW';
        XWollongongNSW: Label 'Wollongong, NSW';
        XMelbourneVIC: Label 'Melbourne, VIC';
        XBrisbaneQLD: Label 'Brisbane, QLD';
        XPerthWA: Label 'Perth, WA';
        XMurdunnaTAS: Label 'Murdunna, TAS';
        XHumbeek: Label 'Humbeek';
        XAntwerpen: Label 'Antwerpen';
        XHerentals: Label 'Herentals';
        XMechelen: Label 'Mechelen';
        XLeuven: Label 'Leuven';
        XKortrijk: Label 'Kortrijk';
        XSofia: Label 'Sofia';
        XKustendil: Label 'Kustendil';
        XBlagoevgrad: Label 'Blagoevgrad';
        XPlovdiv: Label 'Plovdiv';
        XElhovo: Label 'Elhovo';
        XVarna: Label 'Varna';
        XElkhorn: Label 'Elkhorn';
        XOakville: Label 'Oakville';
        XToronto: Label 'Toronto';
        XLondon: Label 'London';
        XThunderBay: Label 'Thunder Bay';
        XVracov: Label 'Vracov';
        XKyjov: Label 'Kyjov';
        XBlansko: Label 'Blansko';
        XZnojmo: Label 'Znojmo';
        XBojkovice: Label 'Bojkovice';
        XOlomouch: Label 'Olomouch';
        XSchaffhausen: Label 'Schaffhausen';
        XLuzern: Label 'Luzern';
        XGlattbrugg: Label 'Glattbrugg';
        XRotkreuz: Label 'Rotkreuz';
        XPratteln: Label 'Pratteln';
        XImmensee: Label 'Immensee';
        XHamburg: Label 'Hamburg';
        XHamburg36: Label 'Hamburg 36';
        XDusseldorf: Label 'Dusseldorf', Comment = 'Translate';
        XFrankfurtMain: Label 'Frankfurt/Main';
        XMunchen: Label 'Munchen', Comment = 'Translate';
        XLandsbergamLech: Label 'Landsberg am Lech';
        XOdenseC: Label 'Odense C';
        XNyborg: Label 'Nyborg';
        XAlborg: Label 'Alborg', Comment = 'Translate';
        XBARIKA: Label 'BARIKA';
        XALGIERS: Label 'ALGIERS';
        XMOSTAGANCU: Label 'MOSTAGANCU';
        XKHENCHE: Label 'KHENCHE';
        XTallinn: Label 'Tallinn';
        XNarva: Label 'Narva';
        XRakvere: Label 'Rakvere';
        XTapa: Label 'Tapa';
        XMustvee: Label 'Mustvee';
        XPaldiski: Label 'Paldiski';
        XValencia: Label 'Valencia';
        XBarcelona: Label 'Barcelona';
        XMadrid: Label 'Madrid';
        XSalamanca: Label 'Salamanca';
        XPalmaMallorca: Label 'Palma Mallorca';
        XAlicante: Label 'Alicante';
        XPontevedra: Label 'Pontevedra';
        XZaragoza: Label 'Zaragoza';
        XSevilla: Label 'Sevilla';
        XCaceres: Label 'Caceres', Comment = 'Translate';
        XValladolid: Label 'Valladolid';
        XHelsinki: Label 'Helsinki';
        XKlaukkala: Label 'Klaukkala';
        XJokela: Label 'Jokela';
        XKuhmo: Label 'Kuhmo';
        XLACHAPELLEBASSEMER: Label 'LA CHAPELLE BASSE MER';
        XCASSEL: Label 'CASSEL';
        XPARIS: Label 'PARIS';
        XESBLY: Label 'ESBLY';
        XPLAISIR: Label 'PLAISIR';
        XLALONDELESMAURES: Label 'LA LONDE LES MAURES';
        XAthens: Label 'Athens';
        XPiraeus: Label 'Piraeus';
        XThessaloniki: Label 'Thessaloniki';
        XChania: Label 'Chania';
        XKolymbia: Label 'Kolymbia';
        XZagreb: Label 'Zagreb';
        XDubrovnik: Label 'Dubrovnik';
        XSplit: Label 'Split';
        XSibenik: Label 'Sibenik';
        XBjelovar: Label 'Bjelovar';
        XRovinj: Label 'Rovinj';
        XBudapest: Label 'Budapest';
        XEsztergom: Label 'Esztergom';
        XTarnalelesz: Label 'Tarnalelesz';
        XNoszvaj: Label 'Noszvaj';
        XJakarta: Label 'Jakarta';
        XTangerang: Label 'Tangerang';
        XBandung: Label 'Bandung';
        XSurabaya: Label 'Surabaya';
        XDelhi: Label 'Delhi';
        XMumbai: Label 'Mumbai';
        XNagpur: Label 'Nagpur';
        XBangalore: Label 'Bengaluru';
        XChennai: Label 'Chennai';
        XKolkata: Label 'Kolkata';
        XROMARM: Label 'ROMA RM';
        XTORINOTO: Label 'TORINO TO';
        XMILANOMI: Label 'MILANO MI';
        XBOLZANOBZ: Label 'BOLZANO BZ';
        XSANTAVENERANDAPS: Label 'SANTA VENERANDA PS';
        XPESCINAAQ: Label 'PESCINA AQ';
        XReykjavik: Label 'Reykjavik';
        XKopavogur: Label 'Kopavogur';
        XHafnafjordur: Label 'Hafnafjordur';
        XAkranes: Label 'Akranes';
        XNairobi: Label 'Nairobi';
        XKairi: Label 'Kairi';
        XAdungosi: Label 'Adungosi';
        XMarsabit: Label 'Marsabit';
        XMombasa: Label 'Mombasa';
        XMalindi: Label 'Malindi';
        XVilnius: Label 'Vilnius';
        XKaunas: Label 'Kaunas';
        XRudiskes: Label 'Rudiskes';
        XKlaipeda: Label 'Klaipeda';
        XRiga: Label 'Riga';
        XDundaga: Label 'Dundaga';
        XBauska: Label 'Bauska';
        XOgre: Label 'Ogre';
        XKoknese: Label 'Koknese';
        XAGDALRABAT: Label 'AGDAL-RABAT';
        XRIADRABAT: Label 'RIAD-RABAT';
        XTEMARA: Label 'TEMARA';
        XCASABLANCA: Label 'CASABLANCA';
        XMOHAMMEDIA: Label 'MOHAMMEDIA';
        XKASBAHTANGER: Label 'KASBAH TANGER';
        XPELABUHANKLANGSelangor: Label 'PELABUHAN KLANG, Selangor';
        XPETALINGJAYASelangor: Label 'PETALING JAYA, Selangor';
        XAMPANGKualaLumpur: Label 'AMPANG, Kuala Lumpur';
        XKUALALUMPUR: Label 'KUALA LUMPUR';
        XKOTAKINABALUSabah: Label 'KOTA KINABALU, Sabah';
        XKUCHINGSarawak: Label 'KUCHING, Sarawak';
        XMaputo: Label 'Maputo';
        XBENINEdostate: Label 'BENIN, Edo state';
        XABUJA: Label 'ABUJA';
        XJOSPlateaustate: Label 'JOS, Plateau state';
        XGHOHPlateaustate: Label 'GHOH, Plateau state';
        XAmsterdam: Label 'Amsterdam';
        XZaandam: Label 'Zaandam';
        XWaalwijk: Label 'Waalwijk';
        XArnhem: Label 'Arnhem';
        XZutphen: Label 'Zutphen';
        XApeldoorn: Label 'Apeldoorn';
        XSandvika: Label 'Sandvika';
        XLysaker: Label 'Lysaker';
        XHaslum: Label 'Haslum';
        XAsker: Label 'Asker';
        XSki: Label 'Ski';
        XOslo: Label 'Oslo';
        XAuckland: Label 'Auckland';
        XWoodville: Label 'Woodville';
        XDannevirke: Label 'Dannevirke';
        XWellington: Label 'Wellington';
        XHokitika: Label 'Hokitika';
        XChristchurch: Label 'Christchurch';
        XManila: Label 'Manila';
        XSantaCruzManila: Label 'Santa Cruz, Manila';
        XTondoManila: Label 'Tondo, Manila';
        XCapriQuezonCity: Label 'Capri, Quezon City';
        XValenzuela: Label 'Valenzuela';
        XZamboangaCity: Label 'Zamboanga City';
        XWarszawa: Label 'Warszawa';
        XKorsze: Label 'Korsze';
        XOrneta: Label 'Orneta';
        XBialystok: Label 'Bialystok';
        XOpole: Label 'Opole';
        XLubin: Label 'Lubin';
        XLISBOA: Label 'LISBOA';
        XCOIMBRA: Label 'COIMBRA';
        XPORTO: Label 'PORTO';
        XFUNCHAL: Label 'FUNCHAL';
        XPONTADELGADA: Label 'PONTA DELGADA';
        XCraiova: Label 'Craiova';
        XBrasov: Label 'Brasov';
        XSibiu: Label 'Sibiu';
        XBucuresti: Label 'Bucuresti';
        XStockholm: Label 'Stockholm';
        XHalmstad: Label 'Halmstad';
        XGoteborg: Label 'Goteborg', Comment = 'Translate';
        XKinnared: Label 'Kinnared';
        XJonkobing: Label 'Jonkobing', Comment = 'Translate';
        XNorrkobing: Label 'Norrkobing', Comment = 'Translate';
        XSundsvall: Label 'Sundsvall';
        XSingapore: Label 'Singapore';
        XLjubljana: Label 'Ljubljana';
        XMaribor: Label 'Maribor';
        XGrobelno: Label 'Grobelno';
        XKranj: Label 'Kranj';
        XKoper: Label 'Koper';
        XBlanca: Label 'Blanca';
        XDolnyKubin: Label 'Dolny Kubin';
        XBetliar: Label 'Betliar';
        XBratislava: Label 'Bratislava';
        XSenica: Label 'Senica';
        XKalinovo: Label 'Kalinovo';
        XMbabane: Label 'Mbabane';
        XSwaziPlaza: Label 'Swazi Plaza';
        XPiggsPeak: Label 'Piggs Peak';
        XSiteki: Label 'Siteki';
        XManzini: Label 'Manzini';
        XNhlangano: Label 'Nhlangano';
        XBangNaBangkok: Label 'Bang Na, Bangkok';
        XBangRakBangkok: Label 'Bang Rak, Bangkok';
        XKhlongSamwaBangkok: Label 'Khlong Samwa, Bangkok';
        XWatSingChaiNat: Label 'Wat Sing, Chai Nat';
        XNonDindaengBuriRam: Label 'Non Dindaeng, Buri Ram';
        XSanPaTongChiangMai: Label 'San Pa Tong, Chiang Mai';
        XTunisBelvedere: Label 'Tunis Belvedere';
        XTunis: Label 'Tunis';
        XZaghouan: Label 'Zaghouan';
        XKairouan: Label 'Kairouan';
        XAinDraham: Label 'Ain Draham';
        XBouSalem: Label 'Bou Salem';
        XAnkara: Label 'Ankara';
        XKonya: Label 'Konya';
        XManisa: Label 'Manisa';
        XIstanbul: Label 'Istanbul';
        XKartalIstanbul: Label 'Kartal-Istanbul';
        XTuzlaIstanbul: Label 'Tuzla-Istanbul';
        XDarEsSalaam: Label 'Dar Es Salaam';
        XKampala: Label 'Kampala';
        XEntebbe: Label 'Entebbe';
        XBirmingham: Label 'Birmingham';
        XMiami: Label 'Miami';
        XAtlanta: Label 'Atlanta';
        XChicago: Label 'Chicago';
        XNewYork: Label 'New York';
        XColombia: Label 'Colombia';
        XPretoria: Label 'Pretoria';
        XPietersburg: Label 'Pietersburg';
        XJohannesburg: Label 'Johannesburg';
        XCarletonville: Label 'Carletonville';
        XNewcastle: Label 'Newcastle';
        XDurban: Label 'Durban';
        XRichardsBay: Label 'Richards Bay';
        XPortElizabeth: Label 'Port Elizabeth';
        XCapeTown: Label 'Cape Town';
        XBloemfontein: Label 'Bloemfontein';
        XCoventry: Label 'Coventry';
        XManchester: Label 'Manchester';
        XMaidstone: Label 'Maidstone';
        XDudley: Label 'Dudley';
        XCambridge: Label 'Cambridge';
        XGuildford: Label 'Guildford';
        XPortsmouth: Label 'Portsmouth';
        XEdinburgh: Label 'Edinburgh';
        XWatford: Label 'Watford';
        XGloucester: Label 'Gloucester';
        XGainsborough: Label 'Gainsborough';
        XStratford: Label 'Stratford';
        XPeterborough: Label 'Peterborough';
        XLiverpool: Label 'Liverpool';
        XCheltenham: Label 'Cheltenham';
        XNewquay: Label 'Newquay';
        XSouthseaPortsmouth: Label 'Southsea, Portsmouth';
        XBromley: Label 'Bromley';
        XWestEndLane: Label 'West End Lane';
        XBedford: Label 'Bedford';
        XSidcup: Label 'Sidcup';
        XHythe: Label 'Hythe';
        XPlymouth: Label 'Plymouth';
        XRipon: Label 'Ripon';
        XCardiff: Label 'Cardiff';
        XCheddington: Label 'Cheddington';
        XBristol: Label 'Bristol';
        XMacclesfield: Label 'Macclesfield';
        XBrixham: Label 'Brixham';
        XBorehamwood: Label 'Borehamwood';
        XTring: Label 'Tring';
        XRhyl: Label 'Rhyl';
        XBletchley: Label 'Bletchley';
        XSwansea: Label 'Swansea';
        XLuton: Label 'Luton';
        XBath: Label 'Bath';
        XLeicester: Label 'Leicester';
        XKingsLynn: Label 'Kings Lynn';
        XBromsgrove: Label 'Bromsgrove';
        XSparkhillBirmingham: Label 'Sparkhill, Birmingham';
        XNewport: Label 'Newport';
        XAshford: Label 'Ashford';
        XLincoln: Label 'Lincoln';
        XMexicoCityDF: Label 'Mexico City, DF';
        XLeonGuanajuato: Label 'Leon, Guanajuato';
        XMonterreyNuevoLeon: Label 'Monterrey, Nuevo Leon';
        XSanLuisPotosiSanLuis: Label 'San Luis Potosi, San Luis';
        XMazatlanSinaloa: Label 'Mazatlan, Sinaloa';
        XBeograd: Label 'Beograd';
        XBor: Label 'Bor';
        XNoviSad: Label 'Novi Sad';
        XSubotica: Label 'Subotica';
        XKragujevac: Label 'Kragujevac';
        XSaoPauloSP: Label 'Sao Paulo SP';
        XRiodeJaneiroRJ: Label 'Rio de Janeiro RJ';
        XRecifePE: Label 'Recife PE';
        XBrasiliaDF: Label 'Brasilia DF';
        XCuritibaPR: Label 'Curitiba PR';
        XPortoAlegreRS: Label 'Porto Alegre RS';
        XWrongPostCode: Label 'Wrong Postcode %1';
        XEningen: Label 'Eningen';
        XAtherstone: Label 'Atherstone';
        XFleet: Label 'Fleet';
        XReading: Label 'Reading';

    local procedure ImportLocalPostCodes()
    var
        PostCodesDemoData: XMLport "Post Codes Demo Data";
        IStr: InStream;
        File: File;
        FileName: Text;
    begin
        FileName := DemoDataSetup."Path to Picture Folder" + 'LocalPostCodes.txt';

        if File.Open(FileName) then begin
            File.CreateInStream(IStr);
            PostCodesDemoData.SetSource(IStr);
            PostCodesDemoData.Import();
            File.Close();
        end;
    end;

    procedure InsertData("Code": Code[20]; City: Text[30]; County: Text[30])
    begin
        "Post Code".Init();
        "Post Code"."Country/Region Code" := CopyStr(Code, 1, 2);
        RemoveCountryPrefix(Code);
        "Post Code".Code := Code;
        "Post Code".City := City;
        "Post Code"."Search City" := City;
        "Post Code".County := County;
        "Post Code".Insert();
    end;

    procedure FindCity(PostCode: Code[20]) CityName: Text[30]
    var
        City: Text[30];
    begin
        if PostCode <> '' then begin
            RemoveCountryPrefix(PostCode);
            "Post Code".SetRange(Code, PostCode);
            "Post Code".FindFirst();
            City := "Post Code".City;
        end;
        CityName := City;
        "Post Code".Reset();
    end;

    procedure FindPostCode(PostCode: Code[20]) RetPostCode: Code[20]
    begin
        if PostCode <> '' then begin
            RemoveCountryPrefix(PostCode);
            "Post Code".SetRange(Code, PostCode);
            "Post Code".FindFirst();
        end;
        RetPostCode := PostCode;
        "Post Code".Reset();
    end;

    procedure RemoveCountryPrefix(var PostCode: Code[20])
    var
        DemoDataSetup: Record "Demo Data Setup";
        CountryCodeLength: Integer;
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Remove Country Prefix" then begin
            CountryCodeLength := StrLen(DemoDataSetup."Country/Region Code");
            if StrLen(PostCode) >= CountryCodeLength then
                if (CopyStr(PostCode, 1, CountryCodeLength) = DemoDataSetup."Country/Region Code") and
                   (CopyStr(PostCode, CountryCodeLength + 1, 1) in [' ', '-'])
                then
                    PostCode := DelStr(PostCode, 1, CountryCodeLength + 1);
        end;
    end;

    procedure Convert(PostCode: Code[20]) Return: Code[20]
    begin
        case PostCode of
            '':
                Return := '';
            // Location xBlue | Customer 10000 | Ship-toAdress 10000/xPARKROAD | C/VBankAccount ALL | RespCenter xBIRMINGHAM
            // Contact xCT100140|xCT100156|xCT100210
            'DE-72800':
                Return := 'DE-72800'; // Vendor 30000/xGraphicDesignInstitute
            'DE-80807':
                Return := 'DE-80807'; // Customer 40000/xAlpineSkiHouse
            'GB-B27 4KT':
                Return := 'GB-B27 4KT';
            'GB-B31 2AL':
                Return := 'GB-B31 2AL'; // Contact xCT200080
            'GB-B68 5TT':
                Return := 'GB-B68 5TT'; // Contact xCT200079
            'GB-BS3 6KL':
                Return := 'GB-BS3 6KL'; // Location xYellow
            'GB-CB1 2FB':
                Return := 'GB-CB1 2FB'; // Customer 10000/xAdatumCorporation
            'GB-SE1 0AX':
                Return := 'GB-SE1 0AX'; // Customer 20000/xTreyResearch
            'GB-CV6 1GY':
                Return := 'GB-CV6 1GY'; // Customer 20000
            'GB-CV9 3QN':
                Return := 'GB-CV9 3QN'; // Ship-To-Address 20000/xTWYCROSS
            'GB-DY5 4DJ':
                Return := 'GB-DY5 4DJ'; // Ship-toAdress 10000/xDudley
            'GB-EC2A 3JL':
                Return := 'GB-EC2A 3JL'; // East Warehouse
            'GB-EH1 3EG':
                Return := 'GB-EH1 3EG'; // Vendor 50000/xNodPublishers
            'GB-EH16 8JS':
                Return := 'GB-EH16 8JS'; // AltAddress xMH
            'GB-GL1 9HM':
                Return := 'GB-GL1 9HM'; // Customer 40000
            'GB-GL50 1TY':
                Return := 'GB-GL50 1TY'; // Ship-To-Address 10000/xCHELTENHAM
            'GB-GU2 7YQ':
                Return := 'GB-GU2 7YQ'; // Customer 50000/xRelecloud
            'GB-GU2 7XH':
                Return := 'GB-GU2 7XH'; // Vendor 20000/xFirstUpConsultatns
            'GB-GU3 2SE':
                Return := 'GB-GU3 2SE'; // Vendor 20000 | OrderAddress 20000/xJAMES
            'GB-GU52 8DY':
                Return := 'GB-GU52 8DY'; // Ship-To-Address 20000/xFLEET
            'GB-GU7 5GT':
                Return := 'GB-GU7 5GT'; // Customer 50000
            'GB-IB7 7VN':
                Return := 'GB-IB7 7VN'; // Vendor 40000
            'GB-L18 6SA':
                Return := 'GB-L18 6SA'; // Location xGreen
            'GB-M22 5TG':
                Return := 'GB-M22 5TG'; // Vendor 40000/xWideWorldImporters
            'GB-M61 2YG':
                Return := 'GB-M61 2YG'; // Contact xCT100239|xCT100125|xCT100187|xCT100188
            'GB-MO2 4RT':
                Return := 'GB-MO2 4RT'; // Customer 30000 | Ship-toAdress 20000/xMANCHESTER
                                        // Vendor 10000 | Resource xMark|xTIMOTHY | OrderAddress 10000/xHope | 10000/xTHEGROVE
                                        // Employee xMH|XTS | Union ALL | Resource | RespCenter xLondon
                                        // Contact xCT100128|xCT100229
            'GB-N12 5XY':
                Return := 'GB-N12 5XY';
            'GB-N16 34Z':
                Return := 'GB-N16 34Z'; // Resource xMary | Employee xMD/xLM
            'GB-NP5 6GH':
                Return := 'GB-NP5 6GH'; // Contact xCT100240|xCT100124|xCT100147|xCT100176
            'GB-NP10 8BE':
                Return := 'GB-NP10 8BE'; // West Warehouse
            'GB-OX16 0UA':
                Return := 'GB-OX16 0UA'; // Contact xCT100241|xCT100213|CT200035|xCT200130
            'GB-PE17 4RN':
                Return := 'GB-PE17 4RN'; // Employee xAH
            'GB-PO21 6HG':
                Return := 'GB-PO21 6HG'; // Contact xCT100242|xCT100134|xCT100142|CT200037
            'GB-PO7 2HI':
                Return := 'GB-PO7 2HI'; // Vendor 30000
            'GB-RG6 1WG':
                Return := 'GB-RG6 1WG'; // Main Warehouse
            'GB-TN27 6YD':
                Return := 'GB-TN27 6YD'; // Location xRed | Ship-toAdress 20000/xEASTACTON
            'GB-TQ17 8HB':
                Return := 'GB-TQ17 8HB'; // Contact xCT100243|xCT100126|xCT100127
            'GB-W1 3AL':
                Return := 'GB-W1 3AL'; // BankAccount xNBL|XGIRO | Employee xPS/xJR/xRL / Contact xCT100237
            'GB-W2 6BD':
                Return := 'GB-W2 6BD'; // Ship-To-Address 10000/xLODNON
            'GB-W2 8HG':
                Return := 'GB-W2 8HG'; // Company Information
            'GB-WC1 2GS':
                Return := 'GB-WC1 2GS'; // Location xWhite|xSilver
            'GB-WC1 3DG':
                Return := 'GB-WC1 3DG'; // BankAccount xWWBEUR|XWWBOPERATING|XWWBUSD | Contact xCT100159|xCT100170
            'GB-WD2 4RG':
                Return := 'GB-WD2 4RG'; // Vendor 50000 | OrderAddress 20000/xWATFORD | Contact xCT100162|xCT200046|xCT200068
            'US-FL 37125':
                Return := 'US-FL 37125'; // Customer 30000/xSchoolOfFineArt
            'US-GA 31772':
                Return := 'US-GA 31772'; // Vendor 10000/xFabrikamInc
            else
                Error(XWrongPostCode, PostCode);
        end;
    end;

    procedure GetCounty(PostCode: Code[20]; City: Text[30]): Code[30]
    var
        PostCodeRec: Record "Post Code";
    begin
        if PostCodeRec.Get(PostCode, City) then
            exit(PostCodeRec.County);
    end;
}

