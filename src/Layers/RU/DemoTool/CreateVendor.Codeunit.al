codeunit 101023 "Create Vendor"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Skip creation of master data" then
            exit;

        InsertData(
          '10000', XLondonPostmaster, X10NorthLakeAvenue, CreatePostCode.Convert('GB-N12 5XY'), XMrs, XCarolPhilips, '',
          DemoDataSetup."Country/Region Code", '7700000104', XLND, '', '', XBUSINESS, XPURCHASE, '8712345000028');
        InsertData(
          '20000', XARDayPropertyManagement, X100DayDrive, CreatePostCode.Convert('GB-GU3 2SE'), XMr, XFrankLee, '',
          DemoDataSetup."Country/Region Code", '7700000200', XS, XYELLOW, '', XBUSINESS, XPURCHASE, '8712345000035');
        InsertData(
          '30000', XCoolWoodTechnologies, X33HitechDrive, CreatePostCode.Convert('GB-PO7 2HI'), XMr, XRichardBready, '',
          DemoDataSetup."Country/Region Code", '7700000305', XS, '', '', XBUSINESS, XPURCHASE, '');
        InsertData(
          '40000', XLewisHomeFurniture, X51RadcroftRoad, CreatePostCode.Convert('GB-IB7 7VN'), XMrs, XJuliaCollins, '',
          DemoDataSetup."Country/Region Code", '7700000400', XNE, XGREEN, '', XBUSINESS, XPURCHASE, '');
        InsertData(
          '50000', XServiceElectronicsLtd, X172FieldGreen, CreatePostCode.Convert('GB-WD2 4RG'), XMr, XMarcZimmerman, '',
          DemoDataSetup."Country/Region Code", '7700000506', XLND, '', '', XBUSINESS, XPURCHASE, '');
        InsertData(
          '01254796', 'Progressive Home Furnishings', '222 Reagan Drive', 'US-SC 27136', 'Mr.', 'Michael Sean Ray', 'USD', 'US', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '0123456789012');
        InsertData(
          '01587796', 'Custom Metals Incorporated', '640 Nixon Blvd.', 'US-AL 35242', 'Mr.', 'Peter Houston', 'USD', 'US', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '01863656', 'American Wood Exports', '723 North Hampton Drive', 'US-NY 11010', 'Mr.', 'Jeff D. Henshaw', 'USD',
          'US', '503912693', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '31147896', 'Houtindustrie Bruynsma', 'Havenweg 92', 'NL-1530 JM', '', 'Lieve Casteels', 'EUR', 'NL', '456789123B56', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '31568974', 'Koekamp Leerindustrie', 'Looiersdreef 19-27', 'NL-5132 EE', '', 'Anita Langers', 'EUR',
          'NL', '789455789B30', '', '', '', XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '31580305', 'Beekhuysen BV', 'Mergelland 4', 'NL-7321 HE', '', 'Alex Roland', 'EUR', 'NL', '453218925B23', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '32456123', 'Groene Kater BVBA', 'Stationstraat 12', 'BE-1851', '', 'Roger Van Houten', 'EUR', 'BE', '123123789', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '32554455', 'PURE-LOOK', 'Parklaan 3', 'BE-2800', '', 'Rob Caron', 'EUR', 'BE', '654654789', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '32665544', 'Overschrijd de Grens SA', 'Boomgaardstraat 55', 'BE-8500', '', 'Tom Vande Velde', 'EUR', 'BE', '321321654', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '34151086', 'Subacqua', 'c/ Neptuno 18', 'ES-37001', 'Srta.', 'Pilar Pinilla Gallego', 'EUR', 'ES', '37030758T', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '34280789', 'Transporte Roas', 'Pol. Ind. 4', 'ES-07001', 'Sr.', 'Fabricio Noriega', 'EUR', 'ES', '07472486T', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '34110257', 'Importaciones S.A.', 'Av. Palmeras 5', 'ES-03003', 'Sr.', 'Tomas Navarro', 'EUR', 'ES', '03121299T', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '35225588', 'Husplast HF', 'Dalvegi 24', 'IS-112', '', 'Vilhjalmur Arnason', 'ISK', 'IS', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '35336699', 'Hurdir HF', 'Skeifunni 13', 'IS-108', '', 'Anna Lisa Sigmundsdottir', 'ISK', 'IS', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '35741852', 'Huslagnir', 'Rangarseli 20', 'IS-101', '', 'Gudmundur Axel Hansen', 'ISK', 'IS', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '38458653', 'IVERKA POHISTVO d.o.o.', 'Industrijska c.15', 'SI-4502', 'g.', 'Lojze Dolenc', 'EUR', 'SI', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '38521479', 'Topol Slovenija d.o.o.', 'Ferkova ulica 4', 'SI-4502', 'ga.', 'Tina Gorenc', 'EUR', 'SI', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '38654478', 'POIIORLES d.d.', 'Cankarjeva 17', 'SI-6000', 'ga.', 'Borka Durovic', 'EUR', 'SI', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '42125678', 'UP Ostrov s.p.', 'Mayerova 12', 'CZ-779 00', '', 'Roman Miklus', 'CZK', 'CZ', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '42784512', 'TON s.r.o.', 'Krausova 125', 'CZ-697 01', '', 'Zuzana Janska', 'CZK', 'CZ', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '42895623', 'Mach & spol. v.o.s.', 'T.G. Masaryka 15', 'CZ-678 01', '', 'Milan Cvrkal', 'CZK', 'CZ', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '43258545', 'S´Š¢gewerk Mittersill', 'Ortstra´Š¢e 12', 'AT-5730', 'Hr.', 'Christian Kemp', 'EUR', 'AT', 'ATU32334456', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '43589632', 'Paul Brettschneider KG', 'Am Bahndamm 68', 'AT-8850', 'Hr.', 'Michael L. Rothkugel', 'EUR',
          'AT', 'ATU32336677', '', '', '', XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '43698547', 'Beschl´Š¢ge Schacherhuber', 'Fabrikstra´Š¢e 24', 'AT-1230', 'Hr.', 'Frank Pellow', 'EUR',
          'AT', 'ATU32337789', '', '', '', XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '45774477', 'Lyselette Lamper A/S', 'Nyborgvej 566', 'DK-5000', 'Hr.', 'Allan Vinther-Wahl', 'DKK', 'DK', '63524152', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '45858585', 'Busterby Stole og Borde A/S', 'Havnevej 6', 'DK-4600', 'Fr.', 'Karen Friske', 'DKK', 'DK', '52147896', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '45868686', 'Ahornby Hvidevare A/S', 'Ndr. Frihavnsgade 45', 'DK-2100', 'Hr.', 'Allan Benny Guinot', 'DKK', 'DK', '78963258', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '46558855', 'Kinnareds Tr´Š¢industri AB', 'Stordal Torslunda', 'SE-521 03', '', '', 'SEK', 'SE', '666666666601', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '46635241', 'Viksj´Š¢ Snickerifabrik AB', 'Sj´Š¢hagsgatan 7', 'SE-852 33', '', '', 'SEK', 'SE', '555555555501', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '46895623', 'Svensk M´Š¢beltextil AB', 'Ny´Š¢ngsv´Š¢gen 14', 'SE-415 06', '', '', 'SEK', 'SE', '444444444401', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '47521478', 'M´Š¢belhuset AS', 'Vivendelveien 17', 'NO-1400', '', 'Bjarke Rust Christensen', 'NOK', 'NO', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '47562214', 'Stilm´Š¢bler as', 'Thv. Meyersgt. 34', 'NO-0552', '', 'Sisser Wichmann', 'NOK', 'NO', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '47586622', 'Monabekken Barnesenger A/S', '´Š¢stensj´Š¢veien 27', 'NO-0661', '', 'Christina Philp', 'NOK', 'NO', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '49454647', 'VAG - J´Š¢rgensen', 'S´Š¢derweg 15', 'DE-20097', '', '', 'EUR', 'DE', '521478963', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '49494949', 'KKA B´Š¢romaschinen Gmbh', 'Immermannstra´Š¢e 92', 'DE-86899', '', '', 'EUR', 'DE', '456123985', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '49989898', 'JB-Spedition', 'Gr´Š¢nfahrtsweg 20', 'DE-80997', '', '', 'EUR', 'DE', '125874259', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '44756404', 'Furniture Industries', '23 Charington Cresent', 'GB-E12 5TG', 'Mr.', 'Stephen A. Mew', 'GBP',
          'GB', '796385274', 'SCOT', XBLUE, '', XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '44729910', 'Boybridge Tool Mart', '8 Grovenors Park', 'GB-N16 34Z', 'Mr.', 'David Campbell', 'GBP', 'GB', '279425763', 'LND', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '44127904', 'WoodMart Supply Co.', '12 Industrial Heights', 'GB-SA3 7HI', 'Mr.', 'Joseph Matthews', 'GBP',
          'GB', '741852963', 'MID', '', '', XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '41568934', 'Technische Betriebe Rotkreuz', 'Seedamm 18', 'CH-6343', 'Herrn', 'Michael Ruggiero',
          'CHF', 'CH', 'CHE-451.456.123MWST', '', '', '', XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '41483124', 'Matter Transporte', 'Industrie', 'CH-4133', 'Herrn', 'Michael Pfeiffer', 'CHF', 'CH', 'CHE-321.456.789 TVA', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '41124089', 'Kradolf Zimmerdecke AG', 'Erlenstrasse 5', 'CH-6405', 'Herrn', 'Dick Dievendorff',
          'CHF', 'CH', 'CHE-145.654.457 IVA', '', '', '', XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '44127914', 'Mortimor Car Company', '43 Industrial Heights', 'GB-SA3 7HI', 'Mr.', 'Andrew R. Hill', 'GBP',
          'GB', '741852979', 'MID', '', '', XBUSINESS, XPURCHNOVAT, '');
        InsertData('01905283', 'Mundersand Corporation', '21 W. Arthur St.', 'CA-ON P7A 4K8', 'Mr.', 'Mike Hines', 'CAD', 'CA', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData('01905382', 'NewCaSup', '12002 Simcoe St.', 'CA-ON M5E 1G5', 'Mr.', 'Toby Nixon', 'CAD', 'CA', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData('01905777', 'OakvilleWorld', '1 Sherwood Heights Dr.', 'CA-ON L6J 3J3', 'Mr.', 'Sean P. Alexander', 'CAD', 'CA', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '20300190', 'Malay-Dan Export Unit Sdn Bhd', '12, Jalan Ampang', 'MY-50450', 'Mr.', 'Fabrice Perez', 'MYR', 'MY', '', '', XYELLOW, '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData('20319939', 'KDHSL99 Sdn Bhd', '220, Jalan Limbongan', 'MY-42000', 'Mr.', 'Toh Chin Theng', 'MYR', 'MY', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData('20323323', 'Tengah Butong Sdn Bhd', '4KM Jalan Tuaran', 'MY-88100', 'Mrs.', 'Anisah Yoosoof', 'MYR', 'MY', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData('21201992', 'Texpro Maroc', '1, Rue la rennaissance', 'MA-20000', 'M.', 'Charaf HAMZAOUI', 'MAD', 'MA', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData('21218838', 'Top Bureau', '26, Rue Ahmed Faris', 'MA-90000', 'M.', 'Fadi FAKHOURI', 'MAD', 'MA', '', '', XBLUE, '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData('21248839', 'Comacycle', '38, Rue Ahmed Arabi', 'MA-20800', '', '', 'MAD', 'MA', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData('27299299', 'Big 5 Video', '32 Railway Street', 'ZA-3900', 'Mr.', 'Kevin Kennedy', 'ZAR', 'ZA', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData('27833998', 'Jewel Gold Mine', '24 Kempston Rd.', 'ZA-2000', 'Mr.', 'Craig Dewer', 'ZAR', 'ZA', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          '27889998', 'Mountain Fisheries', '12 Curcuit Road', 'ZA-8000', 'Mrs.', 'Corinna Bolender', 'ZAR', 'ZA', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData('33012999', 'Club Euroamis', '16 Rue de Berri', 'FR-44450', 'M.', 'Francois GERARD', 'EUR', 'FR', '', '', XYELLOW, '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData('33299199', 'Belle et Belle', '34 Rue du Dome', 'FR-50670', 'Mme.', 'Nicole CARON', 'EUR', 'FR', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');
        InsertData('33399927', 'Aranteaux Aliments', '3 Rue Grande', 'FR-83250', 'M.', 'Francois AJENSTAT', 'EUR', 'FR', '', '', '', '',
          XBUSINESS, XPURCHNOVAT, '');

        InsertData(XEH, 'Ester Henderson', XSpartakovskayaStreet1313, '', '', '', 'RUB',
          DemoDataSetup."Country/Region Code", '7700000001', XMSC, '', '71-1000', '', '', '');
        InsertData(XKH, 'Katherine Hull', XVoroshilovaStreet55, '', '', '', 'RUB',
          DemoDataSetup."Country/Region Code", '7700000002', XMSC, '', '71-1000', '', '', '');
        InsertData(XLT, 'Lina Townsend', XMarksistskayaStreet15112, '', '', '', 'RUB',
          DemoDataSetup."Country/Region Code", '7700000003', XMSC, '', '71-1000', '', '', '');
        InsertData(XMH, 'Marty Horst', XPervomayskayaStreet3112, '', '', '', 'RUB',
          DemoDataSetup."Country/Region Code", '7700000004', XMSC, '', '71-1000', '', '', '');

        InsertData(XVOB + '001', 'Alpine Ski House', 'address', '', '', '', 'RUB',
          DemoDataSetup."Country/Region Code", '7700000005', XMSC, '', '99-9999', XBUSINESS, XPURCHNOVAT, '');
        InsertData(XVOB + '002', 'Baldwin Museum of Science', 'address', '', '', '', 'RUB',
          DemoDataSetup."Country/Region Code", '7700000006', XMSC, '', '99-9999', XBUSINESS, XPURCHNOVAT, '');
        InsertData(XVOB + '003', 'Adatum Corporation Bank', 'address', '', '', '', 'RUB',
          DemoDataSetup."Country/Region Code", '7700000007', XMSC, '', '99-9999', XBUSINESS, XPURCHNOVAT, '');

        InsertData(XTAX + '001', XPIT, XVokzalnayaStreet26, '103054', '', '', '',
          DemoDataSetup."Country/Region Code", '7700000010', XMSC, '', '68-5100', '', '', '');
        InsertData(XTAX + '002', StrSubstNo(XSIF, '2,9%'), XVokzalnayaStreet26, '103054', '', '', '',
          DemoDataSetup."Country/Region Code", '7700000011', XMSC, '', '69-1100', '', '', '');
        InsertData(XTAX + '003', StrSubstNo(XSIF, '0,2%'), XVokzalnayaStreet26, '103054', '', '', '',
          DemoDataSetup."Country/Region Code", '7700000012', XMSC, '', '69-1200', '', '', '');
        InsertData(XTAX + '005', XPFInsurance, XVokzalnayaStreet26, '103054', '', '', '',
          DemoDataSetup."Country/Region Code", '7700000014', XMSC, '', '69-2200', '', '', '');
        InsertData(XTAX + '006', XPFAccumulated, XVokzalnayaStreet26, '103054', '', '', '',
          DemoDataSetup."Country/Region Code", '7700000015', XMSC, '', '69-2300', '', '', '');
        InsertData(XTAX + '007', XFederalFOMI, XVokzalnayaStreet26, '103054', '', '', '',
          DemoDataSetup."Country/Region Code", '7700000016', XMSC, '', '69-3100', '', '', '');
        InsertData(XTAX + '008', XLocalFOMI, XVokzalnayaStreet26, '103054', '', '', '',
          DemoDataSetup."Country/Region Code", '7700000017', XMSC, '', '69-3200', '', '', '');
        InsertData(XTAX + '009', XEstateTax, XVokzalnayaStreet26, '103054', '', '', '',
          DemoDataSetup."Country/Region Code", '7700000018', XMSC, '', '68-6000', '', '', '');
        InsertData(XTAX + '010', XTransportTax, XVokzalnayaStreet26, '103054', '', '', '',
          DemoDataSetup."Country/Region Code", '7700000019', XMSC, '', '68-2000', '', '', '');
        InsertData(XTAX + '011', XProfitTaxFederalBudget, XVokzalnayaStreet26, '103054', '', '', '',
          DemoDataSetup."Country/Region Code", '7700000020', XMSC, '', '68-3010', '', '', '');
        InsertData(XTAX + '012', XProfitTaxConstituentEntiryBudget, XVokzalnayaStreet26, '103054', '', '', '',
          DemoDataSetup."Country/Region Code", '7700000021', XMSC, '', '68-3020', '', '', '');
        InsertData(XTAX + '013', XVAT, XVokzalnayaStreet26, '103054', '', '', '',
          DemoDataSetup."Country/Region Code", '7700000022', XMSC, '', '68-4100', '', '', '');
        InsertData(XTAX + '014', XLandTax, XVokzalnayaStreet26, '103054', '', '', '',
          DemoDataSetup."Country/Region Code", '7700000023', XMSC, '', '68-1000', '', '', '');

        InsertData(XVLE + '001', XGraphicDesign, XRabochayaStreet51, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '60-1010', XBUSINESS, XPURCHASE, '');
        InsertData(XVLE + '002', XSchoolOfFineArt, XZeleniePolya172, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '60-1010', XBUSINESS, XPURCHASE, '');
        InsertData(XVLE + '003', XBaldwinMuseumofScience, X8MarchStreet12, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '60-1010', XBUSINESS, XPURCHASE, '');
        InsertData(XVLE + '004', XFabricamInc, XLeninskyAvenue16, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '60-1010', XBUSINESS, XPURCHNOVAT, '');
        InsertData(XVLE + '005', XCohoVineyard, XBotanisheskayaStreet44, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '60-1010', XBUSINESS, XPURCHNOVAT, '');
        InsertData(XVLE + '006', XThePhoneCompany, XZamorenovaStreet23, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '60-1010', XBUSINESS, XPURCHASE, '');
        InsertData(XVLE + '007', XConsolidatedMessenger, XDugovayaStreet54, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '76-1000', XBUSINESS, XPURCHASE, '');
        InsertData(XVLE + '008', XLucernePublishing, XEniseyskayaStreet8, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '60-1010', XBUSINESS, XPURCHASE, '');
        InsertData(XVLE + '009', XFourthCoffee, XEfremovaStreet76, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '60-1010', XBUSINESS, XPURCHNOVAT, '');
        InsertData(XVLE + '010', XHumongousInsurance, XBoghenkoStreet9, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '60-1010', XBUSINESS, XPURCHASE, '');
        InsertData(XVLE + '011', XWideWorldImporters, XBolotnayaStreet32, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '60-1010', XBUSINESS, XPURCHASE, '');
        InsertData(XVLE + '012', XTreyResearch, XVarvarkaStreet5, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '60-1010', XBUSINESS, XPURCHASE, '');
        InsertData(XVLE + '013', XMoscowSouthCustoms, XVeernayaStreet76, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '60-1010', XBUSINESS, XPURCHASE, '');
        InsertData(XVLE + '014', XMargieTravel, XBorovskyPassage13, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '60-1010', XBUSINESS, XPURCHASE, '');
        InsertData(XVLE + '015', XCityPowerandLight, XVokzalnayaStreet17, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '60-1010', XBUSINESS, XPURCHASE, '');
        InsertData(XVLE + '016', XContosoLtd, XVolovyaStreet34, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '60-1010', XBUSINESS, XPURCHASE, '');
        InsertData(XVLE + '017', XTimoshenkoVV, XGoncharnayaStreet54, '', '', '', '',
          DemoDataSetup."Country/Region Code", '', XMSC, '', '60-1010', XBUSINESS, XPURCHNOVAT, '');

        InsertData(
          XVFI + '004', XAlpineSkiHousePlus, XKonniyLane8, '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '76-5600', '', '', '');

        InsertData(
          XVEM + '001', XSkokovTI, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '73-1000', XBUSINESS, XPURCHASE, '');
        InsertData(XVEM + '002', XSabanzevAB, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '73-2000', '', '', '');

        InsertData(
          XVSH + '001', XIvanovII, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '75-1000', XBUSINESS, XPURCHASE, '');
        InsertData(
          XVSH + '002', XNordTraders, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '75-1000', XBUSINESS, XPURCHASE, '');
        InsertData(
          XVSH + '003', XContosoPharm, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '75-1000', XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          XVSH + '004', XGraphicDesign, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '75-1000', XBUSINESS, XPURCHNOVAT, '');
        InsertData(
          XVSH + '005', XTailspinToys, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '75-1000', XBUSINESS, XPURCHNOVAT, '');
        InsertData(XVSH + '006', XIvanovII, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '75-2000', '', '', '');
        InsertData(XVSH + '007', XNordTraders, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '75-2000', '', '', '');
        InsertData(XVSH + '008', XContosoPharm, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '75-2000', '', '', '');
        InsertData(XVSH + '009', XGraphicDesign, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '75-2000', '', '', '');
        InsertData(XVSH + '010', XTailspinToys, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '75-2000', '', '', '');
        InsertData(XVSH + '011', XKronusIP, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '75-2000', '', '', '');

        InsertData('71-001', XPetrovPP, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '71-1000', XBUSINESS, XPURCHNOVAT, '');

        InsertData(
          XVFI + '001', XAdatumCorporation, XDovghenkoStreet18, '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '76-5100',
          XBUSINESS, XPURCHASE, '');
        InsertData(
          XVFI + '001%', XAdatumCorporation, XDovghenkoStreet18, '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '76-5110',
          XBUSINESS, XPURCHASE, '');
        InsertData(
          XVFI + '002', XSouthridgeVideo, XSamotechnyAvenue27, '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '76-5600',
          XBUSINESS, XPURCHASE, '');
        InsertData(
          XVFI + '003', XWingtipToys, XZarevyLane12, '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '58-3100', XBUSINESS,
          XPURCHASE, '');
        InsertData(
          XVFI + '003%', XWingtipToys, XZarevyLane12, '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '76-5600',
          XBUSINESS, XPURCHASE, '');

        InsertData(XVBL + '001', XAdatumCorporationBank, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '66-1100', '', '', '');
        InsertData(XVBL + '001%', XAdatumCorporationBank, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '',
          '66-1110', '', '', '');
        InsertData(
          XVBL + '002', XAdventureWorks, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '55-3010', XBUSINESS, XPURCHASE, '');
        InsertData(
          XVBL + '002%', XAdventureWorks, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '76-5600', XBUSINESS, XPURCHASE, '');
        InsertData(
          XVBL + '003', XWoodgroveBank, '', '', '', '', 'EUR', DemoDataSetup."Country/Region Code", '', XMSC, '', '67-1200', XBUSINESS, XPURCHASE, '');
        InsertData(
          XVBL + '003%', XWoodgroveBank, '', '', '', '', 'EUR', DemoDataSetup."Country/Region Code", '', XMSC, '', '67-1210', XBUSINESS,
          XPURCHASE, '');
        InsertData(
          XVBL + '004', XNordTraders, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '66-2100', XBUSINESS, XPURCHASE, '');
        InsertData(
          XVBL + '004%', XNordTraders, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '66-2110', XBUSINESS, XPURCHASE, '');
        InsertData(
          XVBL + '005', XContosoPharm, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '67-2100', XBUSINESS, XPURCHASE, '');
        InsertData(
          XVBL + '005%', XContosoPharm, '', '', '', '', '', DemoDataSetup."Country/Region Code", '', XMSC, '', '67-2110', XBUSINESS, XPURCHASE, '');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Vendor: Record Vendor;
        TaxArea: Record "Tax Area";
        CreateCurrency: Codeunit "Create Currency";
        CreateTerritory: Codeunit "Create Territory";
        CreatePostCode: Codeunit "Create Post Code";
        CreateContact: Codeunit "Create Contact";
        Counter: Integer;
        PreviousCurrencyCode: Code[10];
        XLondonPostmaster: Label 'London Postmaster';
        X10NorthLakeAvenue: Label '10 North Lake Avenue';
        XMrs: Label 'Mrs.';
        XCarolPhilips: Label 'Carol Philips';
        XLND: Label 'LND';
        XARDayPropertyManagement: Label 'AR Day Property Management';
        X100DayDrive: Label '100 Day Drive';
        XMr: Label 'Mr.';
        XFrankLee: Label 'Frank Lee';
        XS: Label 'S';
        XYELLOW: Label 'YELLOW';
        XCoolWoodTechnologies: Label 'CoolWood Technologies';
        X33HitechDrive: Label '33 Hitech Drive';
        XRichardBready: Label 'Richard Bready';
        XLewisHomeFurniture: Label 'Lewis Home Furniture';
        X51RadcroftRoad: Label '51 Radcroft Road';
        XJuliaCollins: Label 'Julia Collins';
        XNE: Label 'NE';
        XGREEN: Label 'GREEN';
        XServiceElectronicsLtd: Label 'Service Electronics Ltd.';
        X172FieldGreen: Label '172 Field Green';
        XMarcZimmerman: Label 'Marc Zimmerman';
        XBLUE: Label 'BLUE';
        XRB: Label 'RB';
        XCM: Label 'CM';
        XCIF: Label 'CIF';
        X1M8D: Label '1M(8D)';
        XMSC: Label 'MSC';
        XEH: Label 'EH';
        XKH: Label 'KH';
        XLT: Label 'LT';
        XMH: Label 'MH';
        XVOB: Label 'VOB';
        XTAX: Label 'TAX';
        XVLE: Label 'VLE';
        XGraphicDesign: Label 'Graphic Design';
        XSchoolOfFineArt: Label 'Litware, Inc';
        XBaldwinMuseumofScience: Label 'Baldwin Museum of Science';
        XFabricamInc: Label 'Fabricam, Inc.';
        XCohoVineyard: Label 'Coho Vineyard';
        XThePhoneCompany: Label 'The Phone Company';
        XConsolidatedMessenger: Label 'Consolidated Messenger';
        XLucernePublishing: Label 'Lucerne Publishing';
        XFourthCoffee: Label 'Fourth Coffee';
        XWideWorldImporters: Label 'Wide World Importers';
        XTreyResearch: Label 'Trey Research';
        XMoscowSouthCustoms: Label 'Moscow South Customs';
        XMargieTravel: Label 'Margie Travel';
        XCityPowerandLight: Label 'City Power and Light';
        XContosoLtd: Label 'Contoso Ltd.';
        XHumongousInsurance: Label 'Humongous Insurance';
        XAlpineSkiHousePlus: Label 'Alpine Ski House Plus';
        XVFI: Label 'VFI';
        XVEM: Label 'VEM';
        XSkokovTI: Label 'Skokov T.I.';
        XSabanzevAB: Label 'Sabanzev A.B.';
        XVSH: Label 'VSH';
        XIvanovII: Label 'Ivanov I.I.';
        XNordTraders: Label 'Nord Traders';
        XContosoPharm: Label 'Contoso Pharm';
        XTailspinToys: Label 'Tailspin Toys';
        XKronusIP: Label 'Kronus I.P.';
        XPetrovPP: Label 'Petrov P.P.';
        XAdatumCorporation: Label 'Adatum Corporation';
        XSouthridgeVideo: Label 'Southridge Video';
        XWingtipToys: Label 'Wingtip Toys';
        XAdatumCorporationBank: Label 'Adatum Corporation Bank';
        XAdventureWorks: Label 'Adventure Works';
        XWoodgroveBank: Label 'Woodgrove Bank';
        XBUSINESS: Label 'BUSINESS';
        XPURCHASE: Label 'PURCHASE';
        XPURCHNOVAT: Label 'PURCHNOVAT';
        XTimoshenkoVV: Label 'Timoshenko V.V.';
        XVBL: Label 'VBL';
        XPIT: Label 'PIT';
        XSIF: Label 'SIF%1';
        XPFInsurance: Label 'PF Insurance';
        XPFAccumulated: Label 'PF Accumulated';
        XFederalFOMI: Label 'Federal FOMI';
        XLocalFOMI: Label 'Local FOMI';
        XEstateTax: Label 'Estate tax';
        XTransportTax: Label 'Transport tax';
        XProfitTaxFederalBudget: Label 'Profit tax fed. budget';
        XProfitTaxConstituentEntiryBudget: Label 'Profit tax const. ent. budg.';
        XVAT: Label 'VAT';
        XLandTax: Label 'Land tax';
        XVokzalnayaStreet26: Label 'Vokzalnaya street, 26';
        XRabochayaStreet51: Label 'Rabochaya street, 51';
        XZeleniePolya172: Label 'Zelenie Polya street, 172';
        X8MarchStreet12: Label '8 March street, 12';
        XLeninskyAvenue16: Label 'Leninsky avenue, 16';
        XBotanisheskayaStreet44: Label 'Botanisheskaya street, 44';
        XZamorenovaStreet23: Label 'Zamorenova street, 23';
        XDugovayaStreet54: Label 'Dugovaya street, 54';
        XEniseyskayaStreet8: Label 'Eniseyskaya street, 18';
        XEfremovaStreet76: Label 'Efremova street, 76';
        XBoghenkoStreet9: Label 'Boghenko street, 9';
        XBolotnayaStreet32: Label 'Bolotnaya street, 32';
        XVarvarkaStreet5: Label 'Varvarka street, 5';
        XVeernayaStreet76: Label 'Veernaya street, 76';
        XBorovskyPassage13: Label 'Borovsky passage, 13';
        XVokzalnayaStreet17: Label 'Vokzalnaya street, 17';
        XVolovyaStreet34: Label 'Volovya street, 34';
        XGoncharnayaStreet54: Label 'Goncharnaya street, 54';
        XKonniyLane8: Label 'Konniy lane, 8';
        XDovghenkoStreet18: Label 'Dovghenko street,18';
        XSamotechnyAvenue27: Label 'Samotechny avenue, 27';
        XZarevyLane12: Label 'Zareby lane, 12';
        XSpartakovskayaStreet1313: Label 'Spartakovskaya street, 13-13';
        XVoroshilovaStreet55: Label 'Voroshilova street, 55';
        XMarksistskayaStreet15112: Label 'Marksistskaya street 15-11-2';
        XPervomayskayaStreet3112: Label 'Pervomayskaya street, 3-112';

    procedure InsertData("No.": Code[20]; Name: Text[30]; Address: Text[30]; "Post Code": Text[30]; Title: Text[30]; "Contact Name": Text[30]; "Currency Code": Code[10]; "Country Code": Code[10]; "VAT Registration No.": Text[20]; "Territory Code": Code[10]; "Location Code": Code[10]; PostingGroup: Code[20]; GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]; GLN: Text[13])
    var
        DemoDataSetup: Record "Demo Data Setup";
        CreateLanguage: Codeunit "Create Language";
        ImagePath: Text;
    begin
        DemoDataSetup.Get();
        if "Currency Code" = DemoDataSetup."Currency Code" then
            "Currency Code" := '';

        Vendor.Init();
        Vendor.Validate("No.", "No.");
        Vendor.Validate(Name, Name);
        Vendor.Validate(Address, Address);
        Vendor.Validate("Country/Region Code", "Country Code");
        Vendor."Post Code" := CreatePostCode.FindPostCode("Post Code");
        Vendor.City := CreatePostCode.FindCity("Post Code");
        Vendor.Validate("Currency Code", "Currency Code");
        Vendor."VAT Registration No." := "VAT Registration No.";
        Vendor.Validate(GLN, GLN);
        if Vendor."Vendor Type" = Vendor."Vendor Type"::Vendor then
            Vendor.Validate("Purchaser Code", XRB);
        Vendor.Validate("Payment Terms Code", XCM);
        Vendor.Validate("Shipment Method Code", XCIF);
        Vendor.Validate("Location Code", "Location Code");
        Vendor.Validate(County, CreatePostCode.GetCounty(Vendor."Post Code", Vendor.City));
        if "No." = '71-1000' then
            Vendor.Validate("Vendor Type", 1);
        if CopyStr("No.", 1, 3) = CopyStr(XTAX, 1, 3) then
            Vendor.Validate("Vendor Type", 2);

        if PreviousCurrencyCode = "Currency Code" then
            Counter := Counter + 1
        else begin
            PreviousCurrencyCode := "Currency Code";
            Counter := 1;
        end;
        Vendor.Validate(Priority, Counter);

        case Vendor."No." of
            '35225588':
                Vendor.Validate("Payment Terms Code", X1M8D);
            '20000':
                Vendor.Validate("Application Method", 1);
            '10000':
                Vendor."Home Page" := 'www.royalmail.co.uk';
            '49454647':
                Vendor."Invoice Disc. Code" := 'K1';
        end;

        if PostingGroup = '' then
            Vendor.Validate("Vendor Posting Group", CreateCurrency.GetVendPostingGroup("Country Code"))
        else
            Vendor.Validate("Vendor Posting Group", PostingGroup);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then
            if "Currency Code" = '' then begin
                if TaxArea.Code = '' then
                    TaxArea.Find('-')
                else
                    if TaxArea.Next() = 0 then
                        TaxArea.Find('-');
                Vendor.Validate("Tax Area Code", TaxArea.Code);
            end;
        Vendor.Validate("Language Code", CreateLanguage.GetLanguageCode("Country Code"));
        Vendor.Validate("Territory Code", CreateTerritory.GetTerritoryCode(Vendor."Country/Region Code", "Territory Code"));
        if Vendor."Location Code" = XGREEN then begin
            Evaluate(Vendor."Lead Time Calculation", '<3D>');
            Vendor.Validate("Lead Time Calculation");
        end;
        Vendor.Insert(true);

        Vendor.Validate(Contact, CreateContact.FormatContact(Title, "Contact Name"));
        ImagePath := StrSubstNo('Images\Person\OnPrem\%1.jpg', "Contact Name");
        if Exists(ImagePath) then
            Vendor.Image.ImportFile(ImagePath, "Contact Name");
        Vendor.Modify(true);
    end;

    procedure UpdateData(BankCode: Code[20]; EmployeeNo: Code[20]; VendorType: Integer; KPPCode: Code[20]; AgreementPosting: Integer; AgreementNos: Code[20])
    begin
        Vendor.Validate("Default Bank Code", BankCode);
        Vendor.Validate("Employee No.", EmployeeNo);
        Vendor.Validate("Vendor Type", VendorType);
        Vendor.Validate("KPP Code", KPPCode);
        Vendor.Validate("Agreement Posting", AgreementPosting);
        Vendor.Validate("Agreement Nos.", AgreementNos);
        Vendor.Modify();
    end;

    procedure CreateEvaluationData()
    var
        DemoDataSetup: Record "Demo Data Setup";
    begin
        DemoDataSetup.Get();
        InsertData(
          '10000', XLondonPostmaster, X10NorthLakeAvenue, CreatePostCode.Convert('GB-N12 5XY'), '', '', '',
          DemoDataSetup."Country/Region Code", '', '', '', '', '', '', '');
        UpdateContact('10000', XCarolPhilips);
        InsertData(
          '20000', XARDayPropertyManagement, X100DayDrive, CreatePostCode.Convert('GB-GU3 2SE'), '', '', '',
          DemoDataSetup."Country/Region Code", '', '', '', '', '', '', '');
        UpdateContact('20000', XFrankLee);
        InsertData(
          '30000', XCoolWoodTechnologies, X33HitechDrive, CreatePostCode.Convert('GB-PO7 2HI'), '', '', '',
          DemoDataSetup."Country/Region Code", '', '', '', '', '', '', '');
        UpdateContact('30000', XRichardBready);
        InsertData(
          '40000', XLewisHomeFurniture, X51RadcroftRoad, CreatePostCode.Convert('GB-IB7 7VN'), '', '', '',
          DemoDataSetup."Country/Region Code", '', '', '', '', '', '', '');
        UpdateContact('40000', XJuliaCollins);
        InsertData(
          '50000', XServiceElectronicsLtd, X172FieldGreen, CreatePostCode.Convert('GB-WD2 4RG'), '', '', '',
          DemoDataSetup."Country/Region Code", '', '', '', '', '', '', '');
        UpdateContact('50000', XMarcZimmerman);
    end;

    procedure GetDefaultAreaDimensionValueEvaluation(VendorNo: Code[20]): Code[20]
    begin
        case VendorNo of
            '10000':
                exit('30');
            '20000':
                exit('30');
            '30000':
                exit('30');
            '40000':
                exit('30');
            '50000':
                exit('30');
        end;
    end;

    local procedure UpdateContact(VendorNo: Code[20]; ContactName: Text[50])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate(Contact, ContactName);
        Vendor.Modify(true);
    end;
}

