codeunit 101023 "Create Vendor"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(
          '10000', XLondonPostmaster, X10NorthLakeAvenue, CreatePostCode.Convert('GB-N12 5XY'), XMrs, XCarolPhilips, '',
          DemoDataSetup."Country/Region Code", '895741963', XLND, '', '', '8712345000028');
        InsertData(
          '20000', XARDayPropertyManagement, X100DayDrive, CreatePostCode.Convert('GB-GU3 2SE'), XMr, XFrankLee, '',
          DemoDataSetup."Country/Region Code", '274863274', XS, XYELLOW, '', '8712345000035');
        InsertData(
          '30000', XCoolWoodTechnologies, X33HitechDrive, CreatePostCode.Convert('GB-PO7 2HI'), XMr, XRichardBready, '',
          DemoDataSetup."Country/Region Code", '697528465', XS, '', '', '');
        InsertData(
          '40000', XLewisHomeFurniture, X51RadcroftRoad, CreatePostCode.Convert('GB-IB7 7VN'), XMrs, XJuliaCollins, '',
          DemoDataSetup."Country/Region Code", '197548769', XNE, XGREEN, '', '');
        InsertData(
          '50000', XServiceElectronicsLtd, X172FieldGreen, CreatePostCode.Convert('GB-WD2 4RG'), XMr, XMarcZimmerman, '',
          DemoDataSetup."Country/Region Code", '295267495', XLND, '', '', '');
        InsertData(
          '01254796', 'Progressive Home Furnishings', '222 Reagan Drive', 'US-SC 27136', 'Mr.', 'Michael Sean Ray', 'USD', 'US', '', '', '',
          '', '0123456789012');
        InsertData(
          '01587796', 'Custom Metals Incorporated', '640 Nixon Blvd.', 'US-AL 35242', 'Mr.', 'Peter Houston', 'USD', 'US', '', '', '', '', '');
        InsertData(
          '01863656', 'American Wood Exports', '723 North Hampton Drive', 'US-NY 11010', 'Mr.', 'Jeff D. Henshaw', 'USD',
          'US', '503912693', '', '', '', '');
        InsertData(
          '31147896', 'Houtindustrie Bruynsma', 'Havenweg 92', 'NL-1530 JM', '', 'Lieve Casteels', 'EUR', 'NL', '456789123B56', '', '', '', '');
        InsertData(
          '31568974', 'Koekamp Leerindustrie', 'Looiersdreef 19-27', 'NL-5132 EE', '', 'Anita Langers', 'EUR',
          'NL', '789455789B30', '', '', '', '');
        InsertData(
          '31580305', 'Beekhuysen BV', 'Mergelland 4', 'NL-7321 HE', '', 'Alex Roland', 'EUR', 'NL', '453218925B23', '', '', '', '');
        InsertData(
          '32456123', 'Groene Kater BVBA', 'Stationstraat 12', 'BE-1851', '', 'Roger Van Houten', 'EUR', 'BE', '123123789', '', '', '', '');
        InsertData(
          '32554455', 'PURE-LOOK', 'Parklaan 3', 'BE-2800', '', 'Rob Caron', 'EUR', 'BE', '654654789', '', '', '', '');
        InsertData(
          '32665544', 'Overschrijd de Grens SA', 'Boomgaardstraat 55', 'BE-8500', '', 'Tom Vande Velde', 'EUR', 'BE', '321321654', '', '', '', '');
        InsertData(
          '34151086', 'Subacqua', 'c/ Neptuno 18', 'ES-37001', 'Srta.', 'Pilar Pinilla Gallego', 'EUR', 'ES', '37030758T', '', '', '', '');
        InsertData(
          '34280789', 'Transporte Roas', 'Pol. Ind. 4', 'ES-07001', 'Sr.', 'Fabricio Noriega', 'EUR', 'ES', '07472486T', '', '', '', '');
        InsertData(
          '34110257', 'Importaciones S.A.', 'Av. Palmeras 5', 'ES-03003', 'Sr.', 'Tomas Navarro', 'EUR', 'ES', '03121299T', '', '', '', '');
        InsertData(
          '35225588', 'Husplast HF', 'Dalvegi 24', 'IS-112', '', 'Vilhjalmur Arnason', 'ISK', 'IS', '', '', '', '', '');
        InsertData(
          '35336699', 'Hurdir HF', 'Skeifunni 13', 'IS-108', '', 'Anna Lisa Sigmundsdottir', 'ISK', 'IS', '', '', '', '', '');
        InsertData(
          '35741852', 'Huslagnir', 'Rangarseli 20', 'IS-101', '', 'Gudmundur Axel Hansen', 'ISK', 'IS', '', '', '', '', '');
        InsertData(
          '38458653', 'IVERKA POHISTVO d.o.o.', 'Industrijska c.15', 'SI-4502', 'g.', 'Lojze Dolenc', 'EUR', 'SI', '', '', '', '', '');
        InsertData(
          '38521479', 'Topol Slovenija d.o.o.', 'Ferkova ulica 4', 'SI-4502', 'ga.', 'Tina Gorenc', 'EUR', 'SI', '', '', '', '', '');
        InsertData(
          '38654478', 'POIIORLES d.d.', 'Cankarjeva 17', 'SI-6000', 'ga.', 'Borka Durovic', 'EUR', 'SI', '', '', '', '', '');
        InsertData(
          '42125678', 'UP Ostrov s.p.', 'Mayerova 12', 'CZ-779 00', '', 'Roman Miklus', 'CZK', 'CZ', '', '', '', '', '');
        InsertData(
          '42784512', 'TON s.r.o.', 'Krausova 125', 'CZ-697 01', '', 'Zuzana Janska', 'CZK', 'CZ', '', '', '', '', '');
        InsertData(
          '42895623', 'Mach & spol. v.o.s.', 'T.G. Masaryka 15', 'CZ-678 01', '', 'Milan Cvrkal', 'CZK', 'CZ', '', '', '', '', '');
        InsertData(
          '43258545', 'Sägewerk Mittersill', 'Ortstraße 12', 'AT-5730', 'Hr.', 'Christian Kemp', 'EUR', 'AT', 'ATU32334456', '', '', '', '');
        InsertData(
          '43589632', 'Paul Brettschneider KG', 'Am Bahndamm 68', 'AT-8850', 'Hr.', 'Michael L. Rothkugel', 'EUR',
          'AT', 'ATU32336677', '', '', '', '');
        InsertData(
          '43698547', 'Beschläge Schacherhuber', 'Fabrikstraße 24', 'AT-1230', 'Hr.', 'Frank Pellow', 'EUR',
          'AT', 'ATU32337789', '', '', '', '');
        InsertData(
          '45774477', 'Lyselette Lamper A/S', 'Nyborgvej 566', 'DK-5000', 'Hr.', 'Allan Vinther-Wahl', 'DKK', 'DK', '63524152', '', '', '', '');
        InsertData(
          '45858585', 'Busterby Stole og Borde A/S', 'Havnevej 6', 'DK-4600', 'Fr.', 'Karen Friske', 'DKK', 'DK', '52147896', '', '', '', '');
        InsertData(
          '45868686', 'Ahornby Hvidevare A/S', 'Ndr. Frihavnsgade 45', 'DK-2100', 'Hr.', 'Allan Benny Guinot', 'DKK', 'DK', '78963258',
          '', '', '', '');
        InsertData(
          '46558855', 'Kinnareds Träindustri AB', 'Stordal Torslunda', 'SE-521 03', '', '', 'SEK', 'SE', '666666666601', '', '', '', '');
        InsertData(
          '46635241', 'Viksjö Snickerifabrik AB', 'Sjöhagsgatan 7', 'SE-852 33', '', '', 'SEK', 'SE', '555555555501', '', '', '', '');
        InsertData(
          '46895623', 'Svensk Möbeltextil AB', 'Nyängsvägen 14', 'SE-415 06', '', '', 'SEK', 'SE', '444444444401', '', '', '', '');
        InsertData(
          '47521478', 'Møbelhuset AS', 'Vivendelveien 17', 'NO-1400', '', 'Bjarke Rust Christensen', 'NOK', 'NO', '', '', '', '', '');
        InsertData(
          '47562214', 'Stilmøbler as', 'Thv. Meyersgt. 34', 'NO-0552', '', 'Sisser Wichmann', 'NOK', 'NO', '', '', '', '', '');
        InsertData(
          '47586622', 'Monabekken Barnesenger A/S', 'Østensjøveien 27', 'NO-0661', '', 'Christina Philp', 'NOK', 'NO', '', '', '', '', '');
        InsertData(
          '49454647', 'VAG - Jürgensen', 'Süderweg 15', 'DE-20097', '', '', 'EUR', 'DE', '521478963', '', '', '', '');
        InsertData(
          '49494949', 'KKA Büromaschinen Gmbh', 'Immermannstraße 92', 'DE-86899', '', '', 'EUR', 'DE', '456123985', '', '', '', '');
        InsertData(
          '49989898', 'JB-Spedition', 'Grünfahrtsweg 20', 'DE-80997', '', '', 'EUR', 'DE', '125874259', '', '', '', '');
        InsertData(
          '44756404', 'Furniture Industries', '23 Charington Cresent', 'GB-E12 5TG', 'Mr.', 'Stephen A. Mew', 'GBP',
          'GB', '796385274', 'SCOT', XBLUE, '', '');
        InsertData(
          '44729910', 'Boybridge Tool Mart', '8 Grovenors Park', 'GB-N16 34Z', 'Mr.', 'David Campbell', 'GBP', 'GB', '279425763', 'LND', '', '', '');
        InsertData(
          '44127904', 'WoodMart Supply Co.', '12 Industrial Heights', 'GB-SA3 7HI', 'Mr.', 'Joseph Matthews', 'GBP',
          'GB', '741852963', 'MID', '', '', '');
        InsertData(
          '41568934', 'Technische Betriebe Rotkreuz', 'Seedamm 18', 'CH-6343', 'Herrn', 'Michael Ruggiero',
          'CHF', 'CH', 'CHE-451.456.123MWST', '', '', '', '');
        InsertData(
          '41483124', 'Matter Transporte', 'Industrie', 'CH-4133', 'Herrn', 'Michael Pfeiffer', 'CHF', 'CH', 'CHE-321.456.789 TVA', '', '', '', '');
        InsertData(
          '41124089', 'Kradolf Zimmerdecke AG', 'Erlenstrasse 5', 'CH-6405', 'Herrn', 'Dick Dievendorff',
          'CHF', 'CH', 'CHE-145.654.457 IVA', '', '', '', '');
        InsertData(
          '44127914', 'Mortimor Car Company', '43 Industrial Heights', 'GB-SA3 7HI', 'Mr.', 'Andrew R. Hill', 'GBP',
          'GB', '741852979', 'MID', '', '', '');
        InsertData('01905283', 'Mundersand Corporation', '21 W. Arthur St.', 'CA-ON P7A 4K8', 'Mr.', 'Mike Hines', 'CAD', 'CA', '',
          '', '', '', '');
        InsertData('01905382', 'NewCaSup', '12002 Simcoe St.', 'CA-ON M5E 1G5', 'Mr.', 'Toby Nixon', 'CAD', 'CA', '', '', '', '', '');
        InsertData('01905777', 'OakvilleWorld', '1 Sherwood Heights Dr.', 'CA-ON L6J 3J3', 'Mr.', 'Sean P. Alexander', 'CAD', 'CA', '',
          '', '', '', '');
        InsertData(
          '20300190', 'Malay-Dan Export Unit Sdn Bhd', '12, Jalan Ampang', 'MY-50450', 'Mr.', 'Fabrice Perez', 'MYR', 'MY', '', '', XYELLOW, '', '');
        InsertData('20319939', 'KDHSL99 Sdn Bhd', '220, Jalan Limbongan', 'MY-42000', 'Mr.', 'Toh Chin Theng', 'MYR', 'MY', '', '', '', '', '');
        InsertData('20323323', 'Tengah Butong Sdn Bhd', '4KM Jalan Tuaran', 'MY-88100', 'Mrs.', 'Anisah Yoosoof', 'MYR', 'MY', '', '', '', '', '');
        InsertData('21201992', 'Texpro Maroc', '1, Rue la rennaissance', 'MA-20000', 'M.', 'Charaf HAMZAOUI', 'MAD', 'MA', '', '', '', '', '');
        InsertData('21218838', 'Top Bureau', '26, Rue Ahmed Faris', 'MA-90000', 'M.', 'Fadi FAKHOURI', 'MAD', 'MA', '', '', XBLUE, '', '');
        InsertData('21248839', 'Comacycle', '38, Rue Ahmed Arabi', 'MA-20800', '', '', 'MAD', 'MA', '', '', '', '', '');
        InsertData('27299299', 'Big 5 Video', '32 Railway Street', 'ZA-3900', 'Mr.', 'Kevin Kennedy', 'ZAR', 'ZA', '', '', '', '', '');
        InsertData('27833998', 'Jewel Gold Mine', '24 Kempston Rd.', 'ZA-2000', 'Mr.', 'Craig Dewer', 'ZAR', 'ZA', '', '', '', '', '');
        InsertData(
          '27889998', 'Mountain Fisheries', '12 Curcuit Road', 'ZA-8000', 'Mrs.', 'Corinna Bolender', 'ZAR', 'ZA', '', '', '', 'Mountain House', '');
        InsertData('33012999', 'Club Euroamis', '16 Rue de Berri', 'FR-44450', 'M.', 'Francois GERARD', 'EUR', 'FR', '', '', XYELLOW, '', '');
        InsertData('33299199', 'Belle et Belle', '34 Rue du Dome', 'FR-50670', 'Mme.', 'Nicole CARON', 'EUR', 'FR', '', '', '', '', '');
        InsertData('33399927', 'Aranteaux Aliments', '3 Rue Grande', 'FR-83250', 'M.', 'Francois AJENSTAT', 'EUR', 'FR', '', '', '', '', '');
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
        XFabrikamInc: Label 'Fabrikam, Inc.';
        XFirstUpConsultants: Label 'First Up Consultants';
        XGraphicDesignInstitute: Label 'Graphic Design Institute';
        XWideWorldImporters: Label 'Wide World Importers';
        XNodPublishers: Label 'Nod Publishers';
        X20AllanTuringRd: Label 'Allan Turing Road, 20';
        XSurrey: Label 'Surrey';
        X6Arbachtalstrasse: Label 'Arbachtalstrasse 6';
        XUnterAchalm: Label 'Unter Achalm';
        X3000AviatorWay: Label 'Aviator Way, 3000';
        XManchesterBusinessPark: Label 'Manchester Business Park';
        "X2-4WaterlooPlace": Label 'Waterloo Place, 2-4';
        XWaverlyGate: Label 'Waverly Gate';
        XKrystalYork: Label 'Krystal York';
        XEvanMcIntosh: Label 'Evan McIntosh';
        XBryceJasso: Label 'Bryce Jasso';
        XTobyRhode: Label 'Toby Rhode';
        XRaymondHillard: Label 'Raymond Hillard';

    procedure InsertData("No.": Code[20]; Name: Text[30]; Address: Text[30]; "Post Code": Text[30]; Title: Text[30]; "Contact Name": Text[30]; "Currency Code": Code[10]; "Country Code": Code[10]; "VAT Registration No.": Text[20]; "Territory Code": Code[10]; "Location Code": Code[10]; "Address 2": Text[30]; GLN: Text[13])
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
        Vendor.Validate("Purchaser Code", XRB);
        Vendor.Validate("Payment Terms Code", XCM);
        Vendor.Validate("Shipment Method Code", XCIF);
        Vendor.Validate("Location Code", "Location Code");
        Vendor.Validate("Address 2", "Address 2");
        Vendor.Validate(County, CreatePostCode.GetCounty(Vendor."Post Code", Vendor.City));

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
            '49454647':
                Vendor."Invoice Disc. Code" := 'K1';
        end;

        Vendor.Validate("Vendor Posting Group", CreateCurrency.GetPostingGroup("Country Code"));
        Vendor.Validate("Gen. Bus. Posting Group", CreateCurrency.GetBusPostingGroup("Country Code"));
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

    procedure CreateEvaluationData()
    var
        DemoDataSetup: Record "Demo Data Setup";
    begin
        DemoDataSetup.Get();
        InsertData(
          '10000', XFabrikamInc, X10NorthLakeAvenue, CreatePostCode.Convert('US-GA 31772'), '', '', '',
          'US', '', '', '', '', '');
        UpdateContact('10000', XKrystalYork);
        InsertData(
          '20000', XFirstUpConsultants, X20AllanTuringRd, CreatePostCode.Convert('GB-GU2 7XH'), '', '', '',
          DemoDataSetup."Country/Region Code", '', '', '', XSurrey, '');
        UpdateContact('20000', XEvanMcIntosh);
        InsertData(
          '30000', XGraphicDesignInstitute, X6Arbachtalstrasse, CreatePostCode.Convert('DE-72800'), '', '', '',
          'DE', '', '', '', XUnterAchalm, '');
        UpdateContact('30000', XBryceJasso);
        InsertData(
          '40000', XWideWorldImporters, X3000AviatorWay, CreatePostCode.Convert('GB-M22 5TG'), '', '', '',
          DemoDataSetup."Country/Region Code", '', '', '', XManchesterBusinessPark, '');
        UpdateContact('40000', XTobyRhode);
        InsertData(
          '50000', XNodPublishers, "X2-4WaterlooPlace", CreatePostCode.Convert('GB-EH1 3EG'), '', '', '',
          DemoDataSetup."Country/Region Code", '', '', '', XWaverlyGate, '');
        UpdateContact('50000', XRaymondHillard);
    end;

    procedure GetDefaultAreaDimensionValueEvaluation(VendorNo: Code[20]): Code[20]
    begin
        case VendorNo of
            '10000':
                exit('70');
            '20000':
                exit('40');
            '30000':
                exit('30');
            '40000':
                exit('40');
            '50000':
                exit('40');
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

