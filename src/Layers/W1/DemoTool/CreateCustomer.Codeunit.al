codeunit 101018 "Create Customer"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(
          '10000', XTheCannonGroupPLC, X192MarketSquare, CreatePostCode.Convert('GB-B27 4KT'), XMr, XAndyTeal, '',
          DemoDataSetup."Country/Region Code", XBLUE, '789456278', XMID1, '', '8712345000004');
        InsertData(
          '20000', XSelangorianLtd, X153ThomasDrive, CreatePostCode.Convert('GB-CV6 1GY'), XMr, XMarkMcArthur, '',
          DemoDataSetup."Country/Region Code", '', '254687456', XMID2, '', '8712345000011');
        InsertData(
          '30000', XJohnHaddockInsuranceCo, X10HighTowerGreen, CreatePostCode.Convert('GB-MO2 4RT'), XMiss, XPatriciaDoyle, '',
          DemoDataSetup."Country/Region Code", '', '533435789', XN, '', '');
        InsertData(
          '40000', XDeerfieldGraphicsCompany, X10DeerfieldRoad, CreatePostCode.Convert('GB-GL1 9HM'), XMr, XKevinWright, '',
          DemoDataSetup."Country/Region Code", XYELLOW, '733495789', XW, '', '');
        InsertData(
          '50000', XGuildfordWaterDepartment, X25WaterWay, CreatePostCode.Convert('GB-GU7 5GT'), XMr, XJimStewart, '',
          DemoDataSetup."Country/Region Code", '', '582048936', XS, '', '');
        InsertData(
          '01121212', 'Spotsmeyer''s Furnishings', '612 South Sunset Drive', 'US-FL 37125', 'Mr.', 'Mike Nash', 'USD', 'US',
          XYELLOW, '', '', '', '1234567890128');
        InsertData(
          '01445544', 'Progressive Home Furnishings', '3000 Roosevelt Blvd.', 'US-IL 61236', 'Mr.', 'Scott Mitchell', 'USD', 'US',
          XYELLOW, '', '', '', '');
        InsertData(
          '01454545', 'New Concepts Furniture', '705 West Peachtree Street', 'US-GA 31772', 'Ms.', 'Tammy L. McDonald', 'USD', 'US',
          XYELLOW, '', '', '', '');
        InsertData(
          '31505050', 'Woonboulevard Kuitenbrouwer', 'Industrieweg 11', 'NL-7202 BP', '', 'Maryann Barber', 'EUR', 'NL',
          XYELLOW, '159753258B46', '', '', '');
        InsertData(
          '31669966', 'Meersen Meubelen', 'Vijfpoortenweg 71', 'NL-6827 BP', '', 'Michael Vanderhyde', 'EUR', 'NL',
          XYELLOW, '852122584B75', '', '', '');
        InsertData(
          '31987987', 'Candoxy Nederland BV', 'Westzijdewal 123', 'NL-1009 AG', '', 'Rob Verhoff', 'EUR', 'NL',
          XYELLOW, '456124966B25', '', '', '');
        InsertData('32124578', 'Nieuwe Zandpoort NV', 'Nieuwstraat 28', 'BE-2200', '', 'Kevin Verboort', 'EUR', 'BE',
          XYELLOW, '456456456', '', '', '');
        InsertData('32656565', 'Antarcticopy', 'Katwilgweg 274', 'BE-2050', '', 'Michael Zeman', 'EUR', 'BE', XYELLOW, '778998789', '', '', '');
        InsertData('32789456', 'Lovaina Contractors', 'Vuurberg 137', 'BE-3000', '', 'Hans Visser', 'EUR', 'BE', XYELLOW, '456123456', '', '', '');
        InsertData('34010199', 'Corporación Beta', 'Avda. Europa 2', 'ES-46007', 'Srta.', 'Vanessa Garcia Garcia', 'EUR', 'ES',
          XBLUE, '46145456T', '', '', '');
        InsertData('34010100', 'Libros S.A.', 'Plaza Redonda 12', 'ES-08010', 'Sr.', 'Oscar Alfonso Caceres', 'EUR', 'ES',
          XBLUE, '08208612T', '', '', '');
        InsertData('34010602', 'Helguera industrial', 'c/ Paz 5', 'ES-28003', 'Sr.', 'Ramon Garcia Noblejas', 'EUR', 'ES',
          XRED, '28012001T', '', '', '');
        InsertData('35122112', 'Bilabankinn', 'Skemmuvegur 4', 'IS-200', '', 'Kristjan Thor Arnason', 'ISK', 'IS', XYELLOW, '', '', '', '');
        InsertData('35451236', 'Gagn & Gaman', 'Reykjavikurvegi 66', 'IS-220', '', 'Ragnheidur K. Gudmundsdottir', 'ISK', 'IS',
          XYELLOW, '', '', '', '');
        InsertData('35963852', 'Heimilisprydi', 'Hallarmula', 'IS-108', '', 'Gunnar Orn Thorsteinsson', 'ISK', 'IS', XYELLOW, '10753', '', '', '');
        InsertData('38128456', 'MEMA Ljubljana d.o.o.', 'Slovenska ccsta 127', 'SI-1000', 'g.', 'Bostjan Lukan', 'EUR', 'SI', XRED, '', '', '', '');
        InsertData('38546552', 'EXPORTLES d.o.o.', 'Zvornarska ulica 5', 'SI-1000', 'ga.', 'Katja Valjavec', 'EUR', 'SI', XRED, '', '', '', '');
        InsertData('38632147', 'Centromerkur d.o.o.', 'Tabor 23', 'SI-2000', 'ga.', 'Renata Lavtar', 'EUR', 'SI', XRED, '', '', '', '');
        InsertData('42147258', 'BYT-KOMPLET s.r.o.', 'V.Nezvala 5', 'CZ-687 71', '', 'Milos Silhan', 'CZK', 'CZ', XRED, '', '', '', '');
        InsertData('42258258', 'J & V v.o.s.', 'Fillova 128', 'CZ-696 42', '', 'Petr Karasek', 'CZK', 'CZ', XRED, '', '', '', '');
        InsertData('42369147', 'PLECHKONSTRUKT a.s.', 'Loosova 14', 'CZ-669 02', '', 'Michal Relich', 'CZK', 'CZ', XRED, '', '', '', '');
        InsertData(
          '43687129', 'Designstudio Gmunden', 'Seepromenade 1b', 'AT-4810', 'Fr.', 'Birgitte Vestphael', 'EUR', 'AT',
          XRED, 'ATU89759098', '', '', '');
        InsertData(
          '43852147', 'Michael Feit - Möbelhaus', 'Straße 33, Obj. 11', 'AT-2355', 'Hr.', 'Carl Langhorn', 'EUR', 'AT',
          XRED, 'ATU72660458', '', '', '');
        InsertData('43871144', 'Möbel Siegfried', 'Raxstraße 47', 'AT-1100', 'Hr.', 'Dr. Daniel Weisman', 'EUR', 'AT',
          XRED, 'ATU12456832', '', '', '');
        InsertData('45282828', 'Candoxy Kontor A/S', 'Carl Blochs Gade 7', 'DK-8000', 'Hr.', 'Jonathan Mollerup', 'DKK', 'DK',
          XYELLOW, '78945612', '', '', '');
        InsertData('45282829', 'Carl Anthony', 'De Mezas Plads 917B', 'DK-8000', 'Hr.', 'Carl Anthony', 'DKK', 'DK', XYELLOW,
          '44495666', '', '', '');
        InsertData('45779977', 'Ravel Møbler', 'Parkvej 44', 'DK-5800', 'Fr.', 'Karen Berg', 'DKK', 'DK', XYELLOW, '12345679', '', '', '');
        InsertData(
          '45979797', 'Lauritzen Kontormøbler A/S', 'Jomfru Ane Gade 56', 'DK-9000', 'Fr.', 'Jenny Gottfried', 'DKK', 'DK',
          XYELLOW, '63254178', '', '', '');
        InsertData('46251425', 'Marsholm Karmstol', 'Tylö Fackhandel', 'SE-302 50', '', '', 'SEK', 'SE', XYELLOW, '999999999901', '', '', '');
        InsertData('46525241', 'Konberg Tapet AB', 'Linnégatan 15', 'SE-550 05', '', '', 'SEK', 'SE', XYELLOW, '888888888801', '', '', '');
        InsertData('46897889', 'Englunds Kontorsmöbler AB', 'Kungsgatan 18', 'SE-600 03', '', '', 'SEK', 'SE', XYELLOW, '777777777701', '', '', '');
        InsertData('47523687', 'Slubrevik Senger AS', 'Storgt. 5', 'NO-1370', '', 'Jenny Lysaker', 'NOK', 'NO', XYELLOW, '', '', '', '');
        InsertData('47563218', 'Klubben', 'Skogveien 3', 'NO-1344', '', 'Thomas Andersen', 'NOK', 'NO', XYELLOW, '', '', '', '');
        InsertData('47586954', 'Sjøboden', 'Ytre Sandgt. 13', 'NO-1300', '', 'Flemming Pedersen', 'NOK', 'NO', XYELLOW, '', '', '', '');
        InsertData('49525252', 'Beef House', 'Südermarkt 6', 'DE-40593', 'Frau', 'Karin Fleischer', 'EUR', 'DE', XGREEN, '632541794', '', '', '');
        InsertData('49633663', 'Autohaus Mielberg KG', 'Porschestraße 911', 'DE-22417', '', '', 'EUR', 'DE', XGREEN, '525252141', '', '', '');
        InsertData('49858585', 'Hotel Pferdesee', 'Plett Straße 187', 'DE-60320', 'Herrn', 'Jonathan Haas', 'EUR', 'DE',
          XGREEN, '963963963', '', '', '');
        InsertData(
          '44180220', 'Afrifield Corporation', '100 Maidstone Ave.', 'GB-ME5 6RL', 'Mrs.', 'Ariane Peeters', 'GBP', 'GB',
          XBLUE, '609458790', XSE, '', '');
        InsertData(
          '44171511', 'Zuni Home Crafts Ltd.', '456 Main Street', 'GB-DY5 4DJ', 'Mr.', 'James R. Hamilton', 'GBP', 'GB',
          XBLUE, '879132357', 'MID', '', '');
        InsertData(
          '44756404', 'London Light Company', '235 Peachtree Street', 'GB-PE17 4RN', 'Mr.', 'Mathew Charles', 'GBP', 'GB',
          XBLUE, '748863386', 'EANG', '', '');
        InsertData(
          '41597832', 'Möbel Scherrer AG', 'Rheinstrasse 2', 'CH-8200', 'Herrn', 'Stefan Delmarco',
          'CHF', 'CH', XBLUE, 'CHE-145.456.123MWST', '', '', '');
        InsertData(
          '41497647', 'Pilatus AG', 'Bergstrasse 12', 'CH-6005', 'Fr.', 'Gabriele Dickmann', 'CHF', 'CH', XBLUE, 'CHE-123.456.789 TVA', '', '', '');
        InsertData(
          '41231215', 'Sonnmatt Design', 'Sonnmattstrasse 5', 'CH-8152', 'Fr.', 'Annelie Zuber', 'CHF', 'CH', XRED, 'CHE-145.456.457 IVA',
          '', '', '');
        InsertData(
          '01905893', 'Candoxy Canada Inc.', '18 Cumberland Street', 'CA-ON P7B 5E2', 'Mr.', 'Rob Young', 'CAD', 'CA', XYELLOW, '', '', '', '');
        InsertData('01905899', 'Elkhorn Airport', '105 Buffalo Dr.', 'CA-MB R0M 0N0', 'Mr.', 'Ryan Danner', 'CAD', 'CA', XYELLOW, '', '', '', '');
        InsertData(
          '01905902', 'London Candoxy Storage Campus', '120 Wellington Rd.', 'CA-ON N6B 1V7', 'Mr.', 'John Kane', 'CAD', 'CA',
          XYELLOW, '', '', '', '');
        InsertData(
          '20309920', 'Metatorad Malaysia Sdn Bhd', 'No 16M Jalan SS22', 'MY-47400', 'Mrs.', 'Azleen Samat', 'MYR', 'MY',
          XYELLOW, '', '', 'Damansara Utama', '');
        InsertData(
          '20312912', 'Highlights Electronics Sdn Bhd', '28 Ground Floor, 1 Jalan 3/26', 'MY-57000', 'Mr.', 'Mark Darrell Boland', 'MYR', 'MY',
          XGREEN, '', '', 'Bandar Baru Sri Petalang', '');
        InsertData('20339921', 'TraxTonic Sdn Bhd', 'Sama Jaya Free Industrial Zone', 'MY-93450', 'Mrs.', 'Rubina Usman', 'MYR', 'MY',
          XYELLOW, '', '', '', '');
        InsertData('21233572', 'Somadis', '37, Rue El Wahda', 'MA-10100', 'M.', 'Syed ABBAS', 'MAD', 'MA', XYELLOW, '', '', '', '');
        InsertData('21245278', 'Maronegoce', '21, Boulevard de la Nation', 'MA-20200', 'Mme.', 'Fadoua AIT MOUSSA', 'MAD', 'MA', XBLUE, '',
          '', '', '');
        InsertData('21252947', 'ElectroMAROC', '11, Avenue des FAR', 'MA-12000', '', '', 'MAD', 'MA', XYELLOW, '', '', '', '');
        InsertData('27090917', 'Zanlan Corp.', '2 Beta Street', 'ZA-2500', 'Mr.', 'Derik Stenerson', 'ZAR', 'ZA', XYELLOW, '', '', '', '');
        InsertData('27321782', 'Karoo Supermarkets', '38 Voortrekker Street', 'ZA-9300', 'Mr.', 'Pieter Wycoff', 'ZAR', 'ZA', XYELLOW,
          '', '', '', '');
        InsertData(
          '27489991', 'Durbandit Fruit Exporters', '100 St. George''s Mall', 'ZA-3600', 'Mr.', 'Eric Lang', 'ZAR', 'ZA',
          XYELLOW, '', '', 'Westmead', '');
        InsertData('33000019', 'Francematic', '19 Boulevard Commanderie', 'FR-78370', 'M.', 'Herve BOURAIMA', 'EUR', 'FR', XWHITE, '', '', '', '');
        InsertData('33002984', 'Parmentier Boutique', '34 Avenue Parmentier', 'FR-75000', 'M.', 'Jean E. TRENARY', 'EUR', 'FR', '', '', '', '', '');
        InsertData('33022842', 'Livre Importants', '46 Rue Orteaux', 'FR-77450', 'M.', 'Lionel PENUCHOT', 'EUR', 'FR', XYELLOW, '', '', '', '');

        Customer.Get('01121212');
        Customer.Validate("Bill-to Customer No.", '01454545');
        Customer.Modify();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Customer: Record Customer;
        TaxArea: Record "Tax Area";
        CreateCurrency: Codeunit "Create Currency";
        CreateTerritory: Codeunit "Create Territory";
        CreatePostCode: Codeunit "Create Post Code";
        CreateContact: Codeunit "Create Contact";
        Counter: Integer;
        PreviousCurrencyCode: Code[10];
        TaxLiable: Boolean;
        XTheCannonGroupPLC: Label 'The Cannon Group PLC';
        X192MarketSquare: Label '192 Market Square';
        XMr: Label 'Mr.';
        XAndyTeal: Label 'Andy Teal';
        XBLUE: Label 'BLUE';
        XMID1: Label 'MID';
        XMID2: Label 'MID';
        XSelangorianLtd: Label 'Selangorian Ltd.';
        X153ThomasDrive: Label '153 Thomas Drive';
        XMarkMcArthur: Label 'Mark McArthur';
        XJohnHaddockInsuranceCo: Label 'John Haddock Insurance Co.';
        X10HighTowerGreen: Label '10 High Tower Green';
        XMiss: Label 'Miss';
        XPatriciaDoyle: Label 'Patricia Doyle';
        XDeerfieldGraphicsCompany: Label 'Deerfield Graphics Company';
        X10DeerfieldRoad: Label '10 Deerfield Road';
        XKevinWright: Label 'Kevin Wright';
        XYELLOW: Label 'YELLOW';
        XGuildfordWaterDepartment: Label 'Guildford Water Department';
        X25WaterWay: Label '25 Water Way';
        XJimStewart: Label 'Jim Stewart';
        XRED: Label 'RED';
        XGREEN: Label 'GREEN';
        X14DAYS: Label '14 DAYS';
        XW: Label 'W';
        XSE: Label 'SE';
        XN: Label 'N';
        XS: Label 'S';
        XWHITE: Label 'WHITE';
        XLARGEACC: Label 'LARGE ACC';
        XCM: Label 'CM';
        X15DOM: Label '1.5 DOM.';
        X20FOR: Label '2.0 FOR.';
        XJO: Label 'JO';
        XOF: Label 'OF';
        XSALES: Label 'SALES';
        XEXW: Label 'EXW';
        X1M8D: Label '1M(8D)';
        XAdatumCorporation: Label 'Adatum Corporation';
        XTreyResearch: Label 'Trey Research';
        XSchoolOfFineArt: Label 'School of Fine Art';
        XAlpineSkiHouse: Label 'Alpine Ski House';
        XRelecloud: Label 'Relecloud';
        X21StationRoad: Label 'Station Road, 21';
        "X91-95SouthwarkBridgeRd": Label 'Southwark Bridge Rd, 91-95';
        X5WalterGropiusStrasse: Label 'Walter-Gropius-Strasse 5';
        X1OccamCourt: Label 'Occam Court, 1';
        XParkStadtSchwabing: Label 'Park Stadt Schwabing';
        XSurrey: Label 'Surrey';
        XRobertTownes: Label 'Robert Townes';
        XHelenRay: Label 'Helen Ray';
        XMeaganBond: Label 'Meagan Bond';
        XIanDeberry: Label 'Ian Deberry';
        XJesseHomer: Label 'Jesse Homer';

    procedure InsertData("No.": Code[20]; Name: Text[30]; Address: Text[30]; "Post Code": Text[30]; Title: Text[30]; "Contact Name": Text[30]; "Currency Code": Code[10]; "Country Code": Code[10]; "Location Code": Code[10]; "VAT Registration No.": Text[20]; "Territory Code": Code[10]; "Address 2": Text[30]; GLN: Text[13])
    var
        CreatePostCode: Codeunit "Create Post Code";
        CreateLanguage: Codeunit "Create Language";
        ImagePath: Text;
    begin
        DemoDataSetup.Get();
        if "Currency Code" = DemoDataSetup."Currency Code" then
            "Currency Code" := '';

        Customer.Init();
        Customer.Validate("No.", "No.");
        Customer.Validate(Name, Name);
        Customer.Validate(Address, Address);
        Customer.Validate("Country/Region Code", "Country Code");
        Customer."Post Code" := CreatePostCode.FindPostCode("Post Code");
        Customer.City := CreatePostCode.FindCity("Post Code");
        Customer.Validate("Currency Code", "Currency Code");
        Customer.Validate("Shipment Method Code", XEXW);
        Customer.Validate("Combine Shipments", true);
        Customer.Validate("Print Statements", true);
        Customer.Validate("Address 2", "Address 2");
        Customer.Validate(County, CreatePostCode.GetCounty(Customer."Post Code", Customer.City));

        case PreviousCurrencyCode of
            "Currency Code":
                Counter := Counter + 1;
            else begin
                PreviousCurrencyCode := "Currency Code";
                Counter := 1;
            end;
        end;

        case (Counter - 1) mod 3 of
            0:
                Customer.Validate("Payment Terms Code", X1M8D);
            1:
                begin
                    Customer.Validate("Customer Disc. Group", DemoDataSetup.RetailCode());
                    Customer.Validate("Payment Terms Code", X14DAYS);
                end;
            2:
                begin
                    Customer.Validate("Customer Disc. Group", XLARGEACC);
                    Customer.Validate("Payment Terms Code", XCM);
                end;
        end;

        case Customer."No." of
            '34010602', '49858585':
                Customer.Validate("Payment Terms Code", X1M8D);
        end;

        Customer.Validate("Location Code", "Location Code");
        Customer."VAT Registration No." := "VAT Registration No.";
        Customer.Validate(GLN, GLN);

        case Customer."No." of
            '32656565':
                Customer.Validate("Credit Limit (LCY)",
                  Round(
                    CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                      WorkDate(), 'EUR', 3871.17, CurrencyExchangeRate.ExchangeRate(WorkDate(), 'EUR')), 0.01));
            '35451236':
                Customer.Validate("Credit Limit (LCY)",
                  Round(
                    CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                      WorkDate(), 'ISK', 90000, CurrencyExchangeRate.ExchangeRate(WorkDate(), 'ISK')), 0.01));
            '20000':
                Customer.Validate("Application Method", 1);
            '49633663':
                Customer.Validate("Invoice Disc. Code", 'A');
        end;
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then
            if "Currency Code" = '' then begin
                Customer.Validate("Reminder Terms Code", DemoDataSetup.DomesticCode());
                Customer.Validate("Fin. Charge Terms Code", X15DOM);
            end else begin
                Customer.Validate("Reminder Terms Code", DemoDataSetup.ForeignCode());
                Customer.Validate("Fin. Charge Terms Code", X20FOR);
            end;

        if "Currency Code" = '' then
            Customer.Validate("Salesperson Code", XJO)
        else
            Customer.Validate("Salesperson Code", XOF);

        Customer.Validate("Customer Posting Group", CreateCurrency.GetPostingGroup("Country Code"));
        Customer.Validate("Gen. Bus. Posting Group", CreateCurrency.GetBusPostingGroup("Country Code"));
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then
            if "Currency Code" = '' then begin
                if TaxArea.Code = '' then begin
                    TaxArea.Find('-');
                    TaxLiable := true;
                end else
                    if TaxArea.Next() = 0 then begin
                        TaxArea.Find('-');
                        TaxLiable := not TaxLiable;
                    end;
                Customer.Validate("Tax Area Code", TaxArea.Code);
                Customer.Validate("Tax Liable", TaxLiable);
            end;

        Customer.Validate("Language Code", CreateLanguage.GetLanguageCode("Country Code"));
        Customer.Validate("Territory Code", CreateTerritory.GetTerritoryCode(Customer."Country/Region Code", "Territory Code"));

        if (DemoDataSetup."Country/Region Code" = "Country Code") then
            Customer.Validate("Reminder Terms Code", DemoDataSetup.DomesticCode())
        else
            Customer.Validate("Reminder Terms Code", DemoDataSetup.ForeignCode());

        Customer.Insert(true);

        Customer.Validate(Contact, CreateContact.FormatContact(Title, "Contact Name"));
        ImagePath := DemoDataSetup."Path to Picture Folder" + StrSubstNo('Images\Person\OnPrem\%1.jpg', "Contact Name");
        if Exists(ImagePath) then
            Customer.Image.ImportFile(ImagePath, "Contact Name");
        Customer.Modify(true);

        case DemoDataSetup."Data Type" of
            DemoDataSetup."Data Type"::Extended:
                begin
                    Customer.Validate("Global Dimension 1 Code", XSALES);
                    Customer.Modify();
                end;
        end;
    end;

    procedure CreateEvaluationData()
    begin
        DemoDataSetup.Get();
        InsertData(
          '10000', XAdatumCorporation, X21StationRoad, CreatePostCode.Convert('GB-CB1 2FB'), '', '', '',
          DemoDataSetup."Country/Region Code", '', '', '', '', '');
        UpdateContact('10000', XRobertTownes);
        InsertData(
          '20000', XTreyResearch, "X91-95SouthwarkBridgeRd", CreatePostCode.Convert('GB-SE1 0AX'), '', '', '',
          DemoDataSetup."Country/Region Code", '', '', '', '', '');
        UpdateContact('20000', XHelenRay);
        InsertData(
          '30000', XSchoolOfFineArt, X10HighTowerGreen, CreatePostCode.Convert('US-FL 37125'), '', '', '',
          'US', '', '', '', '', '');
        UpdateContact('30000', XMeaganBond);
        InsertData(
          '40000', XAlpineSkiHouse, X5WalterGropiusStrasse, CreatePostCode.Convert('DE-80807'), '', '', '',
          'DE', '', '', '', XParkStadtSchwabing, '');
        UpdateContact('40000', XIanDeberry);
        InsertData(
          '50000', XRelecloud, X1OccamCourt, CreatePostCode.Convert('GB-GU2 7YQ'), '', '', '',
          DemoDataSetup."Country/Region Code", '', '', '', XSurrey, '');
        UpdateContact('50000', XJesseHomer);

        if Customer.Get('10000') then begin
            Customer.Validate("Document Sending Profile", 'DIRECTFILE');
            Customer.Modify();
        end;
    end;

    procedure GetDefaultAreaDimensionValueEvaluation(CustomerNo: Code[20]): Code[20]
    begin
        case CustomerNo of
            '10000':
                exit('40');
            '20000':
                exit('40');
            '30000':
                exit('70');
            '40000':
                exit('30');
            '50000':
                exit('40');
        end;
    end;

    local procedure UpdateContact(CustomerNo: Code[20]; ContactName: Text[50])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate(Contact, ContactName);
        Customer.Modify(true);
    end;
}

