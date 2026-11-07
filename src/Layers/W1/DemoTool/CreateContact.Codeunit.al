codeunit 101550 "Create Contact"
{

    trigger OnRun()
    begin
        if Contact.Find('-') then
            repeat
                Contact.Validate("E-Mail", CreateContactEMail(Contact.Name, Contact."No."));
                Contact.Modify();
            until Contact.Next() = 0;

        DemoDataSetup.Get();
        InsertData(XCT100239, XCaneShowroom, XRingwoodRoad, XS, '', XENG, XHR, XGB, 'GB-M61 2YG',
          0, XCT100239, '', '', '', 0);
        InsertData(XCT100240, XLordshipLaneFurnishers, X457LordshipLane, XSE, '', XENG, XLT, XGB, 'GB-NP5 6GH',
          0, XCT100240, '', '', '', 0);
        InsertData(XCT100241, XTimelessReproductions, X28TheTything, XSCOT, '', XENG, XHR, XGB, 'GB-OX16 0UA',
          0, XCT100241, '', '', '', 0);
        InsertData(XCT100242, XWyllieANDMar, XHighStreetRipley, XSW, '', XENG, XJO, XGB, 'GB-PO21 6HG',
          0, XCT100242, '', '', '', 0);
        InsertData(XCT100243, XCompohandlerLtd, XCarmunnockByPassBusby, XSE, '', XENG, XRB, XGB, 'GB-TQ17 8HB',
          0, XCT100243, '', '', '', 0);
        InsertData(XCT100244, 'OK Furnishers', '92-94 West St Bedminster', XNE, '', 'ENG', XHR, 'GB', 'GB-SA1 2HS',
          0, XCT100244, '', '', '', 0);
        InsertData(XCT100245, 'TenTails Direct Ltd', 'Tower Road', XN, '', 'ENG', XHR, 'GB', 'GB-TA3 4FD',
          0, XCT100245, '', '', '', 0);
        InsertData(XCT100001, 'Eco Office Inc.', 'Sgt. Millers Dirve', DemoDataSetup.ForeignCode(), 'USD', 'ENU', XEH, 'US', 'US-IL 61236',
          0, XCT100001, '', '', '', 0);
        InsertData(XCT100002, 'Christie Moon', 'Sgt. Millers Dirve', DemoDataSetup.ForeignCode(), 'USD', 'ENU', XEH, 'US', 'US-IL 61236',
          1, XCT100001, XFMAR, '', XJMANA, 0);
        InsertData(XCT100003, 'Capital Office Furnishings', '220 Richdale Ave', DemoDataSetup.ForeignCode(), 'USD', 'ENU', XRB, 'US', 'US-NY 11010',
          0, XCT100003, '', '', '', 0);
        InsertData(XCT100004, 'Ergonomic Office Systems', '25 Kingston St', DemoDataSetup.ForeignCode(), 'USD', 'ENU', XRB, 'US', 'US-IL 61236',
          0, XCT100004, '', '', '', 0);
        InsertData(XCT100005, 'Taylor"s Office Warehouse', '395 Westgate Drive', DemoDataSetup.ForeignCode(), 'USD', 'ENU', XOF, 'US', 'US-GA 31772',
          0, XCT100005, '', '', '', 0);
        InsertData(XCT100006, 'A. Gibson"s Law Firm', '2570 Swimthon Street', 'EANG', '', 'ENG', XEH, 'GB', 'GB-MO2 4RT',
          0, XCT100006, '', '', '', 0);
        InsertData(XCT100007, 'Officeland Of Manchester', '1120 Newport Ave', 'LND', '', 'ENG', XLT, 'GB', 'GB-M61 2YG',
          0, XCT100007, '', '', '', 0);
        InsertData(XCT100008, 'TelecomPetit', '1240 Yield mark Street', 'MID', '', 'ENG', XRB, 'GB', 'GB-N12 5XY',
          0, XCT100008, '', '', '', 0);
        InsertData(XCT100009, 'DHL Express', '810 South Newport Drive', 'MID', '', 'ENG', XJO, 'GB', 'GB-NP5 6GH',
          0, XCT100009, '', '', '', 0);
        InsertData(XCT100010, 'National Wholesale Corp', '620 Ingridson Av', DemoDataSetup.ForeignCode(), 'USD', 'ENU', XLT, 'US', 'US-SC 27136',
          0, XCT100010, '', '', '', 0);
        InsertData(XCT100011, 'Add-ON Marketing', '435 Kingston Street', DemoDataSetup.ForeignCode(), 'USD', 'ENU', XHR, 'US', 'US-NY 11010',
          0, XCT100011, '', '', '', 0);
        InsertData(XCT100012, 'eAmericonda', '1558 23rd Street', DemoDataSetup.ForeignCode(), 'USD', 'ENU', XHR, 'US', 'US-NY 11010',
          0, XCT100012, '', '', '', 0);
        InsertData(XCT100013, 'Rent a Truck', '210 Bimer Drive', XNW, '', 'ENG', XOF, 'GB', 'GB-PL14 5GB',
          0, XCT100013, '', '', '', 0);
        InsertData(XCT100014, 'Lynda McNeal, Inc', '340 Marlboro Drive', DemoDataSetup.ForeignCode(), 'USD', 'ENU', XEH, 'US', 'US-GA 31772',
          0, XCT100014, '', '', XJMANA, 0);
        InsertData(XCT100015, 'Triplelight Studio', '34 Johnson Street', 'SCOT', '', 'ENG', XEH, 'GB', 'GB-SA3 7HI',
          0, XCT100015, '', '', '', 0);
        InsertData(XCT100016, 'DanMøbler', 'Vindegade 72', DemoDataSetup.ForeignCode(), 'DKK', 'DAN', XRB, 'DK', 'DK-2100',
          0, XCT100016, '', '', '', 0);
        InsertData(XCT100017, 'Furnitures At Work', '854 Theater Road', XNE, '', 'ENG', XEH, 'GB', 'GB-WD1 6YG',
          0, XCT100017, '', '', '', 0);
        InsertData(XCT100018, 'UpTownSvea', 'Orkestergatan 24', DemoDataSetup.ForeignCode(), 'SEK', 'SVE', XRB, 'SE', 'SE-415 06',
          0, XCT100018, '', '', '', 0);
        InsertData(XCT100019, 'WoodImex Ltd', 'Strandvejen 334', DemoDataSetup.ForeignCode(), 'DKK', 'DAN', XBC, 'DK', 'DK-2950',
          0, XCT100019, '', '', '', 0);
        InsertData(XCT100120, 'Patrick Sands', '340 Marlboro Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-GA 31772',
          1, XCT100014, XM, '', '', 0);
        InsertData(XCT100121, 'Sussie Leth', 'Strandvejen 334', DemoDataSetup.ForeignCode(), '', 'DAN', XBC, 'DK', 'DK-2950',
          1, XCT100019, XFMAR, '', '', 0);
        InsertData(XCT100122, 'Michael Graff', 'Süderweg 15', DemoDataSetup.ForeignCode(), '', 'DEU', XRB, 'DE', 'DE-20097',
          1, ContactNo(DATABASE::Vendor, '49454647'), XM, '', '', 0);
        InsertData(XCT100123, 'Karolina Kacprzak', 'Krausova 125', DemoDataSetup.ForeignCode(), '', 'CSY', XRB, 'CZ', 'CZ-697 01',
          1, ContactNo(DATABASE::Vendor, '42784512'), XFMAR, '', '', 0);
        InsertData(XCT100124, XAdamBarr, X457LordshipLane, XSE, '', XENG, XLT, XGB, 'GB-NP5 6GH',
          1, XCT100240, XM, '', '', 0);
        InsertData(XCT100125, XAndrewLan, XRingwoodRoad, XS, '', XENG, XHR, XGB, 'GB-M61 2YG',
          1, XCT100239, XM, '', '', 0);
        InsertData(XCT100126, XTracyTallman, XCarmunnockByPassBusby, XSE, '', XENG, XRB, XGB, 'GB-TQ17 8HB',
          1, XCT100243, XFMAR, '', '', 0);
        InsertData(XCT100127, XBarbaraMoreland, XCarmunnockByPassBusby, XSE, '', XENG, XRB, XGB, 'GB-TQ17 8HB',
          1, XCT100243, XFMAR, '', '', 0);
        InsertData(XCT100128, XMarkHarrington, X10NorthLakeAvenue, XLND, '', XENG, XRB, XGB, 'GB-N12 5XY',
          1, ContactNo(DATABASE::Vendor, '10000'), XM, '', '', 0);
        InsertData(XCT100129, 'Stephanie Conroy', 'Tower Road', XN, '', 'ENG', XHR, 'GB', 'GB-TA3 4FD',
          1, XCT100245, XFMAR, '', '', 0);
        InsertData(XCT100130, 'Brannon Jones', '92-94 West St Bedminster', XNE, '', 'ENG', XHR, 'GB', 'GB-SA1 2HS',
          1, XCT100244, XM, '', '', 0);
        InsertData(XCT100131, 'Kevin F. Browne', '210 Bimer Drive', XNW, '', 'ENG', XOF, 'GB', 'GB-PL14 5GB',
          1, XCT100013, XM, '', '', 0);
        InsertData(XCT100132, 'Andrew Cencini', '612 South Sunset Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XOF, 'US', 'US-FL 37125',
          1, ContactNo(DATABASE::Customer, '01121212'), XM, '', '', 0);
        InsertData(XCT100133, 'Tony Madigan', 'Orkestergatan 24', DemoDataSetup.ForeignCode(), '', 'SVE', XRB, 'SE', 'SE-415 06',
          1, XCT100018, XM, '', '', 0);
        InsertData(XCT100134, XJuliaMoseley, XHighStreetRipley, XSW, '', XENG, XJO, XGB, 'GB-PO21 6HG',
          1, XCT100242, XFMAR, '', '', 0);
        InsertData(XCT100135, 'Andreas Berglund', 'Sjöhagsgatan 7', DemoDataSetup.ForeignCode(), '', 'SVE', XRB, 'SE', 'SE-852 33',
          1, ContactNo(DATABASE::Vendor, '46635241'), XM, '', '', 0);
        InsertData(XCT100136, 'Diane Tibbott', '395 Westgate Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XOF, 'US', 'US-GA 31772',
          1, XCT100005, XFMAR, '', '', 0);
        InsertData(XCT100137, 'Enrique Gil Gomez', 'c/ Neptuno 18', DemoDataSetup.ForeignCode(), '', 'ESP', XRB, 'ES', 'ES-37001',
          1, ContactNo(DATABASE::Vendor, '34151086'), XM, '', '', 0);
        InsertData(XCT100138, 'Matthias Berndt', 'Seedamm 18', DemoDataSetup.ForeignCode(), '', 'DES', XRB, 'CH', 'CH-6343',
          1, ContactNo(DATABASE::Vendor, '41568934'), XM, '', '', 0);
        InsertData(XCT100139, 'Katie Jordan', '395 Westgate Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XOF, 'US', 'US-GA 31772',
          1, XCT100005, XFMAR, '', '', 0);
        InsertData(XCT100140, XDavidHodgson, X192MarketSquare, XMID, '', XENG, XJO, XGB, 'GB-B27 4KT',
          1, ContactNo(DATABASE::Customer, '10000'), XM, '', '', 0);
        InsertData(XCT100141, 'John Tippett', '8 Grovenors Park', 'LND', '', 'ENG', XRB, 'GB', 'GB-N16 34Z',
          1, ContactNo(DATABASE::Vendor, '44729910'), XM, '', '', 0);
        InsertData(XCT100142, XSusanWEaton, XHighStreetRipley, XSW, '', XENG, XJO, XGB, 'GB-PO21 6HG',
          1, XCT100242, XFMAR, '', '', 0);
        InsertData(XCT100143, 'Michael Patten', 'Tower Road', XN, '', 'ENG', XHR, 'GB', 'GB-TA3 4FD',
          1, XCT100245, XM, '', '', 0);
        InsertData(XCT100144, 'Erik Ismert', 'Reykjavikurvegi 66', DemoDataSetup.ForeignCode(), '', 'ISL', XOF, 'IS', 'IS-220',
          1, ContactNo(DATABASE::Customer, '35451236'), XM, '', '', 0);
        InsertData(XCT100145, 'Michael Lund', 'Tylö Fackhandel', DemoDataSetup.ForeignCode(), '', 'SVE', XOF, 'SE', 'SE-302 50',
          1, ContactNo(DATABASE::Customer, '46251425'), XM, '', '', 0);
        InsertData(XCT100146, 'Brian Burke', '43 Industrial Heights', 'MID', '', 'ENG', XRB, 'GB', 'GB-SA3 7HI',
          1, ContactNo(DATABASE::Vendor, '44127914'), XM, '', '', 0);
        InsertData(XCT100147, XJohnEvans, X457LordshipLane, XSE, '', XENG, XLT, XGB, 'GB-NP5 6GH',
          1, XCT100240, XM, '', '', 0);
        InsertData(XCT100148, 'Monica Brink', 'Vijfpoortenweg 71', DemoDataSetup.ForeignCode(), '', 'NLD', XOF, 'NL', 'NL-6827 BP',
          1, ContactNo(DATABASE::Customer, '31669966'), XF, '', '', 0);
        InsertData(XCT100149, 'Christian Kleinerman', 'Straße 33, Obj. 11', DemoDataSetup.ForeignCode(), '', 'DEA', XOF, 'AT', 'AT-2355',
          1, ContactNo(DATABASE::Customer, '43852147'), XM, '', '', 0);
        InsertData(XCT100150, 'Heidi Steen', 'Vivendelveien 17', DemoDataSetup.ForeignCode(), '', 'NOR', XRB, 'NO', 'NO-1400',
          1, ContactNo(DATABASE::Vendor, '47521478'), XF, '', '', 0);
        InsertData(XCT100151, 'Benjamin Martin', 'Tylö Fackhandel', DemoDataSetup.ForeignCode(), '', 'SVE', XOF, 'SE', 'SE-302 50',
          1, ContactNo(DATABASE::Customer, '46251425'), XM, '', '', 0);
        InsertData(XCT100152, 'Belinda Newman', '705 West Peachtree Street', DemoDataSetup.ForeignCode(), '', 'ENU', XOF, 'US', 'US-GA 31772',
          1, ContactNo(DATABASE::Customer, '01454545'), XFMAR, '', '', 0);
        InsertData(XCT100153, 'Gregory Weber', '4 Baker Street', 'EANG', '', 'ENG', XOF, 'GB', 'GB-W1 3AL',
          1, ContactNo(DATABASE::"Bank Account", XNBL), XM, '', '', 0);
        InsertData(XCT100154, 'Linda Contreras', '210 Bimer Drive', XNW, '', 'ENG', XOF, 'GB', 'GB-PL14 5GB',
          1, XCT100013, XFMAR, '', '', 0);
        InsertData(XCT100155, 'Frank Zhang', '395 Westgate Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XOF, 'US', 'US-GA 31772',
          1, XCT100005, XM, '', '', 0);
        InsertData(XCT100156, XJohnEmory, X192MarketSquare, XMID, '', XENG, XJO, XGB, 'GB-B27 4KT',
          1, ContactNo(DATABASE::Customer, '10000'), XM, '', '', 0);
        InsertData(XCT100157, 'Jonas Hasselberg', 'Orkestergatan 24', DemoDataSetup.ForeignCode(), '', 'SVE', XRB, 'SE', 'SE-415 06',
          1, XCT100018, XM, '', '', 0);
        InsertData(XCT100158, 'Mia Sofie Hoffritz', 'Industrieweg 11', DemoDataSetup.ForeignCode(), '', 'NLD', XOF, 'NL', 'NL-7202 BP',
          1, ContactNo(DATABASE::Customer, '31505050'), XFMAR, '', '', 0);
        InsertData(XCT100159, XJackCreasey, X1HighHolborn, XLND, '', XENG, XOF, XGB, 'GB-WC1 3DG',
          1, ContactNo(DATABASE::"Bank Account", XWWBOPERATING), XM, '', '', 0);
        InsertData(XCT100160, 'Yvonne McKay', '456 Main Street', 'MID', '', 'ENG', XJO, 'GB', 'GB-DY5 4DJ',
          1, ContactNo(DATABASE::Customer, '44171511'), XFMAR, '', '', 0);
        InsertData(XCT100161, 'Jose Ignacio Peiro Alba', 'c/ Neptuno 18', DemoDataSetup.ForeignCode(), '', 'ESP', XRB, 'ES', 'ES-37001',
          1, ContactNo(DATABASE::Vendor, '34151086'), XM, '', '', 0);
        InsertData(XCT100162, XJulieTaftRider, X172FieldGreen, XLND, '', XENG, XRB, XGB, 'GB-WD2 4RG',
          1, ContactNo(DATABASE::Vendor, '50000'), XFMAR, '', '', 0);
        InsertData(XCT100163, 'Doris Hartwig', 'Vuurberg 137', DemoDataSetup.ForeignCode(), '', 'NLB', XOF, 'BE', 'BE-3000',
          1, ContactNo(DATABASE::Customer, '32789456'), XF, '', '', 0);
        InsertData(XCT100164, 'John Wood', '210 Bimer Drive', XNW, '', 'ENG', XOF, 'GB', 'GB-PL14 5GB',
          1, XCT100013, XM, '', '', 0);
        InsertData(XCT100165, 'Florian Voss', 'Ytre Sandgt. 13', DemoDataSetup.ForeignCode(), '', 'NOR', XOF, 'NO', 'NO-1300',
          1, ContactNo(DATABASE::Customer, '47586954'), XM, '', '', 0);
        InsertData(XCT100166, 'Yolanda Sanchez Sanchez', 'c/ Neptuno 18', DemoDataSetup.ForeignCode(), '', 'ESP', XRB, 'ES', 'ES-37001',
          1, ContactNo(DATABASE::Vendor, '34151086'), XFMAR, '', '', 0);
        InsertData(XCT100167, 'Amaya Hernandez', 'Pol. Ind. 4', DemoDataSetup.ForeignCode(), '', 'ESP', XRB, 'ES', 'ES-07001',
          1, ContactNo(DATABASE::Vendor, '34280789'), XFMAR, '', '', 0);
        InsertData(XCT100168, 'Robert Zare', 'Loosova 14', DemoDataSetup.ForeignCode(), '', 'CSY', XOF, 'CZ', 'CZ-669 02',
          1, ContactNo(DATABASE::Customer, '42369147'), XM, '', '', 0);
        InsertData(XCT100169, 'Birgit Seidl', 'Süderweg 15', DemoDataSetup.ForeignCode(), '', 'DEU', XRB, 'DE', 'DE-20097',
          1, ContactNo(DATABASE::Vendor, '49454647'), XFMAR, '', '', 0);
        InsertData(XCT100170, XDeborahPoe, X1HighHolborn, XMID, '', XENG, XOF, XGB, 'GB-WC1 3DG',
          1, ContactNo(DATABASE::"Bank Account", XWWBUSD), XFMAR, '', '', 0);
        InsertData(XCT100171, 'Candy Spoon', 'Sgt. Millers Dirve', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-IL 61236',
          1, XCT100001, XFMAR, '', '', 0);
        InsertData(XCT100172, 'Britta Simon', 'Kungsgatan 18', DemoDataSetup.ForeignCode(), '', 'SVE', XOF, 'SE', 'SE-600 03',
          1, ContactNo(DATABASE::Customer, '46897889'), XF, '', '', 0);
        InsertData(XCT100173, 'Charlotte Bender', 'Østensjøveien 27', DemoDataSetup.ForeignCode(), '', 'NOR', XRB, 'NO', 'NO-0661',
          1, ContactNo(DATABASE::Vendor, '47586622'), XF, '', '', 0);
        InsertData(XCT100174, 'Dadi Johannesson', 'Dalvegi 24', DemoDataSetup.ForeignCode(), '', 'ISL', XRB, 'IS', 'IS-112',
          1, ContactNo(DATABASE::Vendor, '35225588'), XM, '', '', 0);
        InsertData(XCT100175, 'Michael J. Zwilling', 'Stordal Torslunda', DemoDataSetup.ForeignCode(), '', 'SVE', XRB, 'SE', 'SE-521 03',
          1, ContactNo(DATABASE::Vendor, '46558855'), XM, '', '', 0);
        InsertData(XCT100176, XSamanthaSmith, X457LordshipLane, XSE, '', XENG, XLT, XGB, 'GB-NP5 6GH',
          1, XCT100240, XFMAR, '', '', 0);
        InsertData(XCT100177, 'Nigel Westbury', '92-94 West St Bedminster', XNE, '', 'ENG', XHR, 'GB', 'GB-SA1 2HS',
          1, XCT100244, XM, '', '', 0);
        InsertData(XCT100178, 'Lisa Jacobson', '395 Westgate Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XOF, 'US', 'US-GA 31772',
          1, XCT100005, XFMAR, '', '', 0);
        InsertData(XCT100179, 'Gustavo Camargo', 'Pol. Ind. 4', DemoDataSetup.ForeignCode(), '', 'ESP', XRB, 'ES', 'ES-07001',
          1, ContactNo(DATABASE::Vendor, '34280789'), XM, '', '', 0);
        InsertData(XCT100180, 'Marie Reinhart', 'Ytre Sandgt. 13', DemoDataSetup.ForeignCode(), '', 'NOR', XOF, 'NO', 'NO-1300',
          1, ContactNo(DATABASE::Customer, '47586954'), XFMAR, '', '', 0);
        InsertData(XCT100181, 'Antonio Bermejo', 'c/ Neptuno 18', DemoDataSetup.ForeignCode(), '', 'ESP', XRB, 'ES', 'ES-37001',
          1, ContactNo(DATABASE::Vendor, '34151086'), XM, '', '', 0);
        InsertData(XCT100182, 'Michael J. Hummer', 'Ortstraße 12', DemoDataSetup.ForeignCode(), '', 'DEA', XRB, 'AT', 'AT-5730',
          1, ContactNo(DATABASE::Vendor, '43258545'), XM, '', '', 0);
        InsertData(XCT100183, 'Jeremy Los', '395 Westgate Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XOF, 'US', 'US-GA 31772',
          1, XCT100005, XM, '', '', 0);
        InsertData(XCT100184, 'Robert Lyon', '1240 Yield mark Street', 'MID', '', 'ENG', XRB, 'GB', 'GB-N12 5XY',
          1, XCT100008, XM, '', '', 0);
        InsertData(XCT100185, 'Arlene Huff', '1240 Yield mark Street', 'MID', '', 'ENG', XRB, 'GB', 'GB-N12 5XY',
          1, XCT100008, XFMAR, '', '', 0);
        InsertData(XCT100186, 'Mary Baker', '210 Bimer Drive', XNW, '', 'ENG', XOF, 'GB', 'GB-PL14 5GB',
          1, XCT100013, XFMAR, '', '', 0);
        InsertData(XCT100187, XScottBishop, XRingwoodRoad, XS, '', XENG, XHR, XGB, 'GB-M61 2YG',
          1, XCT100239, XM, '', '', 0);
        InsertData(XCT100188, XJaneClayton, XRingwoodRoad, XS, '', XENG, XHR, XGB, 'GB-M61 2YG',
          1, XCT100239, XFMAR, '', '', 0);
        InsertData(XCT100189, 'Ragnar Eiriksson', 'Skemmuvegur 4', DemoDataSetup.ForeignCode(), '', 'ISL', XOF, 'IS', 'IS-200',
          1, ContactNo(DATABASE::Customer, '35122112'), XM, '', '', 0);
        InsertData(XCT100190, 'Chris McGurk', '435 Kingston Street', DemoDataSetup.ForeignCode(), '', 'ENU', XHR, 'US', 'US-NY 11010',
          1, XCT100011, XM, '', '', 0);
        InsertData(XCT100191, 'Megan Sherman', '723 North Hampton Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XRB, 'US', 'US-NY 11010',
          1, ContactNo(DATABASE::Vendor, '01863656'), XFMAR, '', '', 0);
        InsertData(XCT100192, 'Karina Agerby', 'Vindegade 72', DemoDataSetup.ForeignCode(), '', 'DAN', XRB, 'DK', 'DK-2100',
          1, XCT100016, XFMAR, '', '', 0);
        InsertData(XCT100193, 'Tina Slone O''Dell', '1558 23rd Street', DemoDataSetup.ForeignCode(), '', 'ENU', XHR, 'US', 'US-NY 11010',
          1, XCT100012, XF, '', '', 0);
        InsertData(XCT100194, 'Andrew Dixon', 'Sgt. Millers Dirve', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-IL 61236',
          1, XCT100001, XM, '', '', 0);
        InsertData(XCT100195, 'Elizabeth Keyser', 'Zvornarska ulica 5', DemoDataSetup.ForeignCode(), '', 'SLV', XOF, 'SI', 'SI-1000',
          1, ContactNo(DATABASE::Customer, '38546552'), XFMAR, '', '', 0);
        InsertData(XCT100196, 'Shelley Dick', '25 Kingston St', DemoDataSetup.ForeignCode(), '', 'ENU', XRB, 'US', 'US-IL 61236',
          1, XCT100004, XFMAR, '', '', 0);
        InsertData(XCT100197, 'Amy E. Alberts', '854 Theater Road', XNE, '', 'ENG', XEH, 'GB', 'GB-WD1 6YG',
          1, XCT100017, XF, '', '', 0);
        InsertData(XCT100198, 'Cornelia Weiler', 'Plett Straße 187', DemoDataSetup.ForeignCode(), '', 'DEU', XOF, 'DE', 'DE-60320',
          1, ContactNo(DATABASE::Customer, '49858585'), XFMAR, '', '', 0);
        InsertData(XCT100199, 'Alex Nayberg', 'Fillova 128', DemoDataSetup.ForeignCode(), '', 'CSY', XOF, 'CZ', 'CZ-696 42',
          1, ContactNo(DATABASE::Customer, '42258258'), XM, '', '', 0);
        InsertData(XCT100200, 'Jan Miksovsky', 'Immermannstraße 92', DemoDataSetup.ForeignCode(), '', 'DEU', XRB, 'DE', 'DE-86899',
          1, ContactNo(DATABASE::Vendor, '49494949'), XM, '', '', 0);
        InsertData(XCT100201, 'Charles Fitzgerald', '235 Peachtree Street', 'EANG', '', 'ENG', XJO, 'GB', 'GB-PE17 4RN',
          1, ContactNo(DATABASE::Customer, '44756404'), XM, '', '', 0);
        InsertData(XCT100202, 'Janice Galvin', '100 Maidstone Ave.', XSE, '', 'ENG', XJO, 'GB', 'GB-ME5 6RL',
          1, ContactNo(DATABASE::Customer, '44180220'), XFMAR, '', '', 0);
        InsertData(XCT100203, 'Spencer Low', '43 Industrial Heights', 'MID', '', 'ENG', XRB, 'GB', 'GB-SA3 7HI',
          1, ContactNo(DATABASE::Vendor, '44127914'), XM, '', '', 0);
        InsertData(XCT100204, 'Mary E. Gibson', '222 Reagan Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XRB, 'US', 'US-SC 27136',
          1, ContactNo(DATABASE::Vendor, '01254796'), XFMAR, '', '', 0);
        InsertData(XCT100205, 'Trinidad Lara', 'Pol. Ind. 4', DemoDataSetup.ForeignCode(), '', 'ESP', XRB, 'ES', 'ES-07001',
          1, ContactNo(DATABASE::Vendor, '34280789'), XFMAR, '', '', 0);
        InsertData(XCT100206, 'Rotislav Shabalin', 'Mayerova 12', DemoDataSetup.ForeignCode(), '', 'CSY', XRB, 'CZ', 'CZ-779 00',
          1, ContactNo(DATABASE::Vendor, '42125678'), XM, '', '', 0);
        InsertData(XCT100207, 'Mikael Sandberg', 'Orkestergatan 24', DemoDataSetup.ForeignCode(), '', 'SVE', XRB, 'SE', 'SE-415 06',
          1, XCT100018, XM, '', '', 0);
        InsertData(XCT100208, 'Garrett Young', 'High Street Ripley', XSW, '', 'ENG', XJO, 'GB', 'GB-PO21 6HG',
          1, XCT100242, XM, '', '', 0);
        InsertData(XCT100209, 'Ann Beebe', '456 Main Street', 'MID', '', 'ENG', XJO, 'GB', 'GB-DY5 4DJ',
          1, ContactNo(DATABASE::Customer, '44171511'), XFMAR, '', '', 0);
        InsertData(XCT100210, XStephanieBourne, X192MarketSquare, XMID, '', XENG, XJO, XGB, 'GB-B27 4KT',
          1, ContactNo(DATABASE::Customer, '10000'), XFMAR, '', '', 0);
        InsertData(XCT100211, 'Peter Conelly', '57 East Reach', XS, '', 'ENG', XHR, 'GB', 'GB-TA3 4FD',
          1, '', XM, '', '', 0);
        InsertData(XCT100212, 'Karen Archer', '14 The Broadway', 'SWAL', '', 'ENG', XLT, 'GB', 'GB-TN27 6YD',
          1, '', XF, '', '', 0);
        InsertData(XCT100213, XPatrickMCook, X28TheTything, XSCOT, '', XENG, XHR, XGB, 'GB-OX16 0UA',
          1, XCT100241, XM, '', '', 0);
        InsertData(XCT100214, 'Jose Edvaldo Saraiva', 'c/ Neptuno 18', DemoDataSetup.ForeignCode(), '', 'ESP', XRB, 'ES', 'ES-37001',
          1, ContactNo(DATABASE::Vendor, '34151086'), XM, '', '', 0);
        InsertData(XCT100215, 'Kenneth Cools', 'Nieuwstraat 28', DemoDataSetup.ForeignCode(), '', 'NLB', XOF, 'BE', 'BE-2200',
          1, ContactNo(DATABASE::Customer, '32124578'), XM, '', '', 0);
        InsertData(XCT100216, 'Bonnie Kearney', 'Tower Road', XN, '', 'ENG', XHR, 'GB', 'GB-TA3 4FD',
          1, XCT100245, XF, '', '', 0);
        InsertData(XCT100217, 'Peter Waxman', 'Bergstrasse 12', DemoDataSetup.ForeignCode(), '', 'DES', XOF, 'CH', 'CH-6005',
          1, ContactNo(DATABASE::Customer, '41497647'), XM, '', '', 0);
        InsertData(XCT100218, 'Gary W. Yukich', '3000 Roosevelt Blvd.', DemoDataSetup.ForeignCode(), '', 'ENU', XOF, 'US', 'US-IL 61236',
          1, ContactNo(DATABASE::Customer, '01445544'), XM, '', '', 0);
        InsertData(XCT100219, 'Patrick Dalle', 'Vuurberg 137', DemoDataSetup.ForeignCode(), '', 'NLB', XOF, 'BE', 'BE-3000',
          1, ContactNo(DATABASE::Customer, '32789456'), XM, '', '', 0);
        InsertData(XCT100220, 'Lene Rathkjen', 'Parkvej 44', DemoDataSetup.ForeignCode(), '', 'DAN', XOF, 'DK', 'DK-5800',
          1, ContactNo(DATABASE::Customer, '45779977'), XFMAR, '', '', 0);
        InsertData(XCT100221, 'Karin Zimprich', 'Seedamm 18', DemoDataSetup.ForeignCode(), '', 'DES', XRB, 'CH', 'CH-6343',
          1, ContactNo(DATABASE::Vendor, '41568934'), XFMAR, '', '', 0);
        InsertData(XCT100222, 'Martin Illum Lotz', 'Thv. Meyersgt. 34', DemoDataSetup.ForeignCode(), '', 'NOR', XRB, 'NO', 'NO-0552',
          1, ContactNo(DATABASE::Vendor, '47562214'), XM, '', '', 0);
        InsertData(XCT100223, 'Magnus Hedlund', 'Olavsgt. 589', DemoDataSetup.ForeignCode(), '', 'NOR', XJO, 'NO', 'NO-0661',
          1, '', XM, '', '', 0);
        InsertData(XCT100224, 'Laura Norman', 'Ortstraße 12', DemoDataSetup.ForeignCode(), '', 'DEA', XRB, 'AT', 'AT-5730',
          1, ContactNo(DATABASE::Vendor, '43258545'), XFMAR, '', '', 0);
        InsertData(XCT100225, 'Linda Meisner', 'Süderweg 15', DemoDataSetup.ForeignCode(), '', 'DEU', XRB, 'DE', 'DE-20097',
          1, ContactNo(DATABASE::Vendor, '49454647'), XFUMAR, '', '', 0);
        InsertData(XCT100226, 'Martin Skamris', 'Industrieweg 11', DemoDataSetup.ForeignCode(), '', 'NLD', XOF, 'NL', 'NL-7202 BP',
          1, ContactNo(DATABASE::Customer, '31505050'), XM, '', '', 0);
        InsertData(XCT100227, 'Susan Metters', '1120 Newport Ave', 'LND', '', 'ENG', XLT, 'GB', 'GB-M61 2YG',
          1, XCT100007, XFMAR, '', '', 0);
        InsertData(XCT100228, 'Wendy Wheeler', '457 Lordship Lane', XSE, '', 'ENG', XLT, 'GB', 'GB-NP5 6GH',
          1, XCT100240, XFUMAR, '', '', 0);
        InsertData(XCT100229, XJenniferRiegle, X10NorthLakeAvenue, XLND, '', XENG, XRB, XGB, 'GB-N12 5XY',
          1, ContactNo(DATABASE::Vendor, '10000'), XFMAR, '', '', 0);
        InsertData(XCT100230, 'Jaime Bastidas', 'Plaza Redonda 12', DemoDataSetup.ForeignCode(), '', 'ESP', XOF, 'ES', 'ES-08010',
          1, ContactNo(DATABASE::Customer, '34010100'), XM, '', '', 0);
        InsertData(XCT100231, 'Marianne Wier', 'Immermannstraße 92', DemoDataSetup.ForeignCode(), '', 'DEU', XRB, 'DE', 'DE-86899',
          1, ContactNo(DATABASE::Vendor, '49494949'), XFMAR, '', '', 0);
        InsertData(XCT100232, 'Ingelise Lang', 'Carl Blochs Gade 7', DemoDataSetup.ForeignCode(), '', 'DAN', XOF, 'DK', 'DK-8000',
          1, ContactNo(DATABASE::Customer, '45282828'), XFMAR, '', '', 0);
        InsertData(XCT100233, 'Sean Purcell', '340 Marlboro Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-GA 31772',
          1, XCT100014, XM, '', '', 0);
        InsertData(XCT100234, 'Bernard Duerr', 'Ferkova ulica 4', DemoDataSetup.ForeignCode(), '', 'SLV', XRB, 'SI', 'SI-4502',
          1, ContactNo(DATABASE::Vendor, '38521479'), XM, '', '', 0);
        InsertData(XCT100235, 'Eva Corets', 'Straße 33, Obj. 11', DemoDataSetup.ForeignCode(), '', 'DEA', XOF, 'AT', 'AT-2355',
          1, ContactNo(DATABASE::Customer, '43852147'), XFMAR, '', '', 0);
        InsertData(XCT100236, 'Charlotte Weiss', 'Sonnmattstrasse 5', DemoDataSetup.ForeignCode(), '', 'DES', XOF, 'CH', 'CH-8152',
          1, ContactNo(DATABASE::Customer, '41231215'), XFMAR, '', '', 0);
        InsertData(XCT100237, XMichaelSullivan, X4BakerStreet, XEANG, '', XENG, XOF, XGB, 'GB-W1 3AL',
          1, ContactNo(DATABASE::"Bank Account", XNBL), XM, '', '', 0);
        InsertData(XCT100238, 'Erlingur Orn Jonsson', 'Reykjavikurvegi 66', DemoDataSetup.ForeignCode(), '', 'ISL', XOF, 'IS', 'IS-220',
          1, ContactNo(DATABASE::Customer, '35451236'), XM, '', '', 0);
        InsertData(XCT200001, 'Andy Teal', '1120 Newport Ave', 'LND', '', 'ENG', XLT, 'GB', 'GB-M61 2YG',
          1, XCT100007, XM, '', '', 0);
        InsertData(XCT200002, 'David J. Liu', '620 Ingridson Av', DemoDataSetup.ForeignCode(), '', 'ENU', XLT, 'US', 'US-SC 27136',
          1, XCT100010, XM, '', XJMANA, 0);
        InsertData(XCT200003, 'Nicole Holliday', '340 Marlboro Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-GA 31772',
          1, XCT100014, XFUMAR, '', '', 0);
        InsertData(XCT200004, 'Jay Jamison', '340 Marlboro Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-GA 31772',
          1, XCT100014, XFMAR, '', '', 0);
        InsertData(XCT200005, 'Tom Getzinger', 'Süderweg 15', DemoDataSetup.ForeignCode(), '', 'DEU', XRB, 'DE', 'DE-20097',
          1, ContactNo(DATABASE::Vendor, '49454647'), XM, '', XJMANA, 0);
        InsertData(XCT200006, 'Mark McArthur', '65-73 Broadway West', 'SWAL', '', 'ENG', XOF, 'GB', 'GB-BR1 2ES',
          1, '', XM, '', '', 0);
        InsertData(XCT200007, 'David Hamilton', '34 Johnson Street', 'SCOT', '', 'ENG', XEH, 'GB', 'GB-SA3 7HI',
          1, XCT100015, XM, '', '', 0);
        InsertData(XCT200008, 'Gary E. Altman III', '435 Kingston Street', DemoDataSetup.ForeignCode(), '', 'ENU', XHR, 'US', 'US-NY 11010',
          1, XCT100011, XM, '', XJMANA, 0);
        InsertData(XCT200009, 'Michael DeVoe', 'Industrieweg 11', DemoDataSetup.ForeignCode(), '', 'NLD', XOF, 'NL', 'NL-7202 BP',
          1, ContactNo(DATABASE::Customer, '31505050'), XM, '', '', 0);
        InsertData(XCT200010, 'Patricia Doyle', '810 South Newport Drive', 'MID', '', 'ENG', XJO, 'GB', 'GB-NP5 6GH',
          1, XCT100009, XFMAR, '', '', 0);
        InsertData(XCT200011, 'Kevin Wright', '34 Johnson Street', 'SCOT', '', 'ENG', XEH, 'GB', 'GB-SA3 7HI',
          1, XCT100015, XM, '', XJMANA, 0);
        InsertData(XCT200012, 'Jim Stewart', '340 Marlboro Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-GA 31772',
          1, XCT100014, XM, '', '', 0);
        InsertData(XCT200013, 'Mike Nash', '210 Bimer Drive', XNW, '', 'ENG', XOF, 'GB', 'GB-PL14 5GB',
          1, XCT100013, XM, '', '', 0);
        InsertData(XCT200014, 'Scott Mitchell', '220 Richdale Ave', DemoDataSetup.ForeignCode(), '', 'ENU', XRB, 'US', 'US-NY 11010',
          1, XCT100003, XM, '', XJMANA, 0);
        InsertData(XCT200015, 'Tammy L. McDonald', '810 South Newport Drive', 'MID', '', 'ENG', XJO, 'GB', 'GB-NP5 6GH',
          1, XCT100009, XF, '', '', 0);
        InsertData(XCT200016, 'Maryann Barber', '1558 23rd Street', DemoDataSetup.ForeignCode(), '', 'ENU', XHR, 'US', 'US-NY 11010',
          1, XCT100012, XF, '', '', 0);
        InsertData(XCT200017, 'Michael Vanderhyde', 'Sgt. Millers Dirve', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-IL 61236',
          1, XCT100001, XM, '', XJMANA, 0);
        InsertData(XCT200018, 'Rob Verhoff', '395 Westgate Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XOF, 'US', 'US-GA 31772',
          1, XCT100005, XM, '', '', 0);
        InsertData(XCT200019, 'Kevin Verboort', '1240 Yield mark Street', 'MID', '', 'ENG', XRB, 'GB', 'GB-N12 5XY',
          1, XCT100008, XM, '', XJMANA, 0);
        InsertData(XCT200020, 'Michael Zeman', '34 Johnson Street', 'SCOT', '', 'ENG', XEH, 'GB', 'GB-SA3 7HI',
          1, XCT100015, XM, '', '', 0);
        InsertData(XCT200021, 'Hans Visser', '35 Brook Street', 'NWAL', '', 'ENG', XBC, 'GB', 'GB-B27 4KT',
          1, '', XM, '', '', 0);
        InsertData(XCT200022, 'Lone Kuhlmann', 'Vindegade 72', DemoDataSetup.ForeignCode(), '', 'DAN', XRB, 'DK', 'DK-2100',
          1, XCT100016, XFMAR, '', '', 0);
        InsertData(XCT200023, 'Christopher E. Hill', '34 Johnson Street', 'SCOT', '', 'ENG', XEH, 'GB', 'GB-SA3 7HI',
          1, XCT100015, XM, '', XJMANA, 0);
        InsertData(XCT200024, 'Debra E. Keiser', '220 Richdale Ave', DemoDataSetup.ForeignCode(), '', 'ENU', XRB, 'US', 'US-NY 11010',
          1, XCT100003, XF, '', '', 0);
        InsertData(XCT200025, 'Ole Gotfred', 'Vindegade 72', DemoDataSetup.ForeignCode(), '', 'DAN', XRB, 'DK', 'DK-2100',
          1, XCT100016, XM, '', '', 0);
        InsertData(XCT200026, 'Benjamin C. Willet', 'Orkestergatan 24', DemoDataSetup.ForeignCode(), '', 'SVE', XRB, 'SE', 'SE-415 06',
          1, XCT100018, XM, '', '', 0);
        InsertData(XCT200027, 'Tawana Nussbaum', '340 Marlboro Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-GA 31772',
          1, XCT100014, XFMAR, '', XJMANA, 0);
        InsertData(XCT200028, 'Nuria Gonzalez', 'Pol. Ind. 4', DemoDataSetup.ForeignCode(), '', 'ESP', XRB, 'ES', 'ES-07001',
          1, ContactNo(DATABASE::Vendor, '34280789'), XFUMAR, '', '', 0);
        InsertData(XCT200029, 'Gerda Jonsdottir', 'Strandvejen 334', DemoDataSetup.ForeignCode(), '', 'DAN', XBC, 'DK', 'DK-2950',
          1, XCT100019, XF, '', '', 0);
        InsertData(XCT200030, 'Anna Lidman', 'Orkestergatan 24', DemoDataSetup.ForeignCode(), '', 'SVE', XRB, 'SE', 'SE-415 06',
          1, XCT100018, XF, '', '', 0);
        InsertData(XCT200031, 'Charlotte Toft Madsen', 'Strandvejen 334', DemoDataSetup.ForeignCode(), '', 'DAN', XBC, 'DK', 'DK-2950',
          1, XCT100019, XFMAR, '', '', 0);
        InsertData(XCT200032, 'James D. Kramer', '1558 23rd Street', DemoDataSetup.ForeignCode(), '', 'ENU', XHR, 'US', 'US-NY 11010',
          1, XCT100012, XM, '', XJMANA, 0);
        InsertData(XCT200033, 'Linda Randall', '1240 Yield mark Street', 'MID', '', 'ENG', XRB, 'GB', 'GB-N12 5XY',
          1, XCT100008, XFMAR, '', '', 0);
        InsertData(XCT200034, 'Birgitte Vestphael', 'Orkestergatan 24', DemoDataSetup.ForeignCode(), '', 'SVE', XRB, 'SE', 'SE-415 06',
          1, XCT100018, XF, '', '', 0);
        InsertData(XCT200035, XCarlLanghorn, X28TheTything, XSCOT, '', XENG, XHR, XGB, 'GB-OX16 0UA',
          1, XCT100241, XM, '', '', 0);
        InsertData(XCT200036, 'Daniel Weisman', 'Strandvejen 334', DemoDataSetup.ForeignCode(), '', 'DAN', XBC, 'DK', 'DK-2950',
          1, XCT100019, XM, '', '', 0);
        InsertData(XCT200037, XJonathanMollerup, XHighStreetRipley, XSW, '', XENG, XJO, XGB, 'GB-PO21 6HG',
          1, XCT100242, XM, '', XJMANA, 0);
        InsertData(XCT200038, 'Karen Berg', 'Vindegade 72', DemoDataSetup.ForeignCode(), '', 'DAN', XRB, 'DK', 'DK-2100',
          1, XCT100016, XF, '', '', 0);
        InsertData(XCT200039, 'Jenny Gottfried', '620 Ingridson Av', DemoDataSetup.ForeignCode(), '', 'ENU', XLT, 'US', 'US-SC 27136',
          1, XCT100010, XF, '', '', 0);
        InsertData(XCT200040, 'Jenny Lysaker', 'Vindegade 72', DemoDataSetup.ForeignCode(), '', 'DAN', XRB, 'DK', 'DK-2100',
          1, XCT100016, XF, '', '', 0);
        InsertData(XCT200041, 'Peter J. Krebs', 'Krausova 125', DemoDataSetup.ForeignCode(), '', 'CSY', XRB, 'CZ', 'CZ-697 01',
          1, ContactNo(DATABASE::Vendor, '42784512'), XM, '', '', 0);
        InsertData(XCT200042, 'Soren Skov Klemmensen', 'Vindegade 72', DemoDataSetup.ForeignCode(), '', 'DAN', XRB, 'DK', 'DK-2100',
          1, XCT100016, XM, '', XJMANA, 0);
        InsertData(XCT200043, 'Jens Toft', 'Orkestergatan 24', DemoDataSetup.ForeignCode(), '', 'SVE', XRB, 'SE', 'SE-415 06',
          1, XCT100018, XM, '', '', 0);
        InsertData(XCT200044, 'Brian Clark', '210 Bimer Drive', XNW, '', 'ENG', XOF, 'GB', 'GB-PL14 5GB',
          1, XCT100013, XM, '', '', 0);
        InsertData(XCT200045, 'Ariane Peeters', 'Parklaan 3', DemoDataSetup.ForeignCode(), '', 'NLB', XRB, 'BE', 'BE-2800',
          1, ContactNo(DATABASE::Vendor, '32554455'), XFMAR, '', '', 0);
        InsertData(XCT200046, XJamesRHamilton, X172FieldGreen, XLND, '', XENG, XRB, XGB, 'GB-WD2 4RG',
          1, ContactNo(DATABASE::Vendor, '50000'), XM, '', '', 0);
        InsertData(XCT200047, 'Mathew Charles', '435 Kingston Street', DemoDataSetup.ForeignCode(), '', 'ENU', XHR, 'US', 'US-NY 11010',
          1, XCT100011, XM, '', XJMANA, 0);
        InsertData(XCT200048, 'Stefan Delmarco', 'Orkestergatan 24', DemoDataSetup.ForeignCode(), '', 'SVE', XRB, 'SE', 'SE-415 06',
          1, XCT100018, XM, '', '', 0);
        InsertData(XCT200049, 'Gabriele Dickmann', '34 Johnson Street', 'SCOT', '', 'ENG', XEH, 'GB', 'GB-SA3 7HI',
          1, XCT100015, XF, '', '', 0);
        InsertData(XCT200050, 'Annelie Zuber', 'Strandvejen 334', DemoDataSetup.ForeignCode(), '', 'DAN', XBC, 'DK', 'DK-2950',
          1, XCT100019, XF, '', '', 0);
        InsertData(XCT200051, 'Carol Philips', '395 Westgate Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XOF, 'US', 'US-GA 31772',
          1, XCT100005, XFMAR, '', '', 0);
        InsertData(XCT200052, 'Julie Bankert', '340 Marlboro Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-GA 31772',
          1, XCT100014, XFMAR, '', XJMANA, 0);
        InsertData(XCT200053, 'Shaun Beasley', '854 Theater Road', XNE, '', 'ENG', XEH, 'GB', 'GB-WD1 6YG',
          1, XCT100017, XM, '', '', 0);
        InsertData(XCT200054, 'Anja Schmidt', 'Strandvejen 334', DemoDataSetup.ForeignCode(), '', 'DAN', XBC, 'DK', 'DK-2950',
          1, XCT100019, XFUMAR, '', '', 0);
        InsertData(XCT200055, 'Kevin McDowell', '34 Johnson Street', 'SCOT', '', 'ENG', XEH, 'GB', 'GB-SA3 7HI',
          1, XCT100015, XM, '', '', 0);
        InsertData(XCT200056, 'Frank Lee', 'Strandvejen 334', DemoDataSetup.ForeignCode(), '', 'DAN', XBC, 'DK', 'DK-2950',
          1, XCT100019, XM, '', XJMANA, 0);
        InsertData(XCT200057, 'Alan Brewer', '2570 Swimthon Street', 'EANG', '', 'ENG', XEH, 'GB', 'GB-MO2 4RT',
          1, XCT100006, XM, '', '', 0);
        InsertData(XCT200058, 'Jan Christiansen', 'Vindegade 72', DemoDataSetup.ForeignCode(), '', 'DAN', XRB, 'DK', 'DK-2100',
          1, XCT100016, XM, '', '', 0);
        InsertData(XCT200059, 'Sten Bennetsen', 'Strandvejen 334', DemoDataSetup.ForeignCode(), '', 'DAN', XBC, 'DK', 'DK-2950',
          1, XCT100019, XM, '', '', 0);
        InsertData(XCT200060, 'Stephen A. Mew', '340 Marlboro Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-GA 31772',
          1, XCT100014, XM, '', '', 0);
        InsertData(XCT200061, 'Julia Collins', '620 Ingridson Av', DemoDataSetup.ForeignCode(), '', 'ENU', XLT, 'US', 'US-SC 27136',
          1, XCT100010, XFMAR, '', XJMANA, 0);
        InsertData(XCT200062, 'Marc Zimmerman', '854 Theater Road', XNE, '', 'ENG', XEH, 'GB', 'GB-WD1 6YG',
          1, XCT100017, XM, '', '', 0);
        InsertData(XCT200063, 'Michael Sean Ray', '1120 Newport Ave', 'LND', '', 'ENG', XLT, 'GB', 'GB-M61 2YG',
          1, XCT100007, XM, '', '', 0);
        InsertData(XCT200064, 'Peter Houston', '340 Marlboro Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-GA 31772',
          1, XCT100014, XM, '', '', 0);
        InsertData(XCT200065, 'Jeff D. Henshaw', '34 Johnson Street', 'SCOT', '', 'ENG', XEH, 'GB', 'GB-SA3 7HI',
          1, XCT100015, XM, '', '', 0);
        InsertData(XCT200066, 'Mandy Vance', '210 Bimer Drive', XNW, '', 'ENG', XOF, 'GB', 'GB-PL14 5GB',
          1, XCT100013, XF, '', '', 0);
        InsertData(XCT200067, 'Anita Langers', '34 Johnson Street', 'SCOT', '', 'ENG', XEH, 'GB', 'GB-SA3 7HI',
          1, XCT100015, XFMAR, '', XJMANA, 0);
        InsertData(XCT200068, XAlexRoland, X172FieldGreen, XLND, '', XENG, XRB, XGB, 'GB-WD2 4RG',
          1, ContactNo(DATABASE::Vendor, '50000'), XM, '', '', 0);
        InsertData(XCT200069, 'Roger Van Houten', 'Parklaan 3', DemoDataSetup.ForeignCode(), '', 'NLB', XRB, 'BE', 'BE-2800',
          1, ContactNo(DATABASE::Vendor, '32554455'), XM, '', '', 0);
        InsertData(XCT200070, 'Diane Margheim', 'Bergstrasse 12', DemoDataSetup.ForeignCode(), '', 'DES', XOF, 'CH', 'CH-6005',
          1, ContactNo(DATABASE::Customer, '41497647'), XFMAR, '', '', 0);
        InsertData(XCT200071, 'Tom Vande Velde', '1558 23rd Street', DemoDataSetup.ForeignCode(), '', 'ENU', XHR, 'US', 'US-NY 11010',
          1, XCT100012, XM, '', '', 0);
        InsertData(XCT200072, 'Amy S. Recker', '34 Johnson Street', 'SCOT', '', 'ENG', XEH, 'GB', 'GB-SA3 7HI',
          1, XCT100015, XFMAR, '', XJMANA, 0);
        InsertData(XCT200073, 'Fabricio Noriega', '220 Richdale Ave', DemoDataSetup.ForeignCode(), '', 'ENU', XRB, 'US', 'US-NY 11010',
          1, XCT100003, XM, '', '', 0);
        InsertData(XCT200074, 'Tomas Navarro', 'Sgt. Millers Dirve', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-IL 61236',
          1, XCT100001, XM, '', '', 0);
        InsertData(XCT200075, 'Brad Sutton', '854 Theater Road', XNE, '', 'ENG', XEH, 'GB', 'GB-WD1 6YG',
          1, XCT100017, XM, '', '', 0);
        InsertData(XCT200076, 'Mads Ebdrup', 'Vindegade 72', DemoDataSetup.ForeignCode(), '', 'DAN', XRB, 'DK', 'DK-2100',
          1, XCT100016, XM, '', '', 0);
        InsertData(XCT200077, 'Phil Spencer', '854 Theater Road', XNE, '', 'ENG', XEH, 'GB', 'GB-WD1 6YG',
          1, XCT100017, XM, '', '', 0);
        InsertData(XCT200078, 'Chris Okelberry', '34 Johnson Street', 'SCOT', '', 'ENG', XEH, 'GB', 'GB-SA3 7HI',
          1, XCT100015, XM, '', XJMANA, 0);
        InsertData(XCT200079, XTinaGorenc, X86StokeNewington, XSE, '', XENG, XOF, XGB, 'GB-B68 5TT',
          1, ContactNo(DATABASE::Customer, '30000'), XF, '', '', 0);
        InsertData(XCT200080, XPamelaAnsmanWolfe, X47HigherMarketStreet, XSW, '', XENG, XOF, XGB, 'GB-B31 2AL',
          1, ContactNo(DATABASE::Customer, '30000'), XFMAR, '', '', 0);
        InsertData(XCT200081, 'Greg Chapman', '2 Drury Way', XSW, '', 'ENG', XBC, 'GB', 'GB-EH16 8JS',
          1, '', XM, '', '', 0);
        InsertData(XCT200082, 'Zuzana Janska', '340 Marlboro Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-GA 31772',
          1, XCT100014, XF, '', XJMANA, 0);
        InsertData(XCT200083, 'Henning Troelsen', 'Strandvejen 334', DemoDataSetup.ForeignCode(), '', 'DAN', XBC, 'DK', 'DK-2950',
          1, XCT100019, XM, '', '', 0);
        InsertData(XCT200084, 'Christian Kemp', '1558 23rd Street', DemoDataSetup.ForeignCode(), '', 'ENU', XHR, 'US', 'US-NY 11010',
          1, XCT100012, XM, '', '', 0);
        InsertData(XCT200085, 'Michael L. Rothkugel', 'Orkestergatan 24', DemoDataSetup.ForeignCode(), '', 'SVE', XRB, 'SE', 'SE-415 06',
          1, XCT100018, XM, '', XJMANA, 0);
        InsertData(XCT200086, 'Frank Pellow', 'Strandvejen 334', DemoDataSetup.ForeignCode(), '', 'DAN', XBC, 'DK', 'DK-2950',
          1, XCT100019, XM, '', '', 0);
        InsertData(XCT200087, 'Allan Vinther-Wahl', '1240 Yield mark Street', 'MID', '', 'ENG', XRB, 'GB', 'GB-N12 5XY',
          1, XCT100008, XM, '', '', 0);
        InsertData(XCT200088, 'Karen Friske', 'Vindegade 72', DemoDataSetup.ForeignCode(), '', 'DAN', XRB, 'DK', 'DK-2100',
          1, XCT100016, XF, '', '', 0);
        InsertData(XCT200089, 'Allan Benny Guinot', 'Vindegade 72', DemoDataSetup.ForeignCode(), '', 'DAN', XRB, 'DK', 'DK-2100',
          1, XCT100016, XM, '', '', 0);
        InsertData(XCT200090, 'Bjarke Rust Christensen', 'Vindegade 72', DemoDataSetup.ForeignCode(), '', 'DAN', XRB, 'DK', 'DK-2100',
          1, XCT100016, XM, '', '', 0);
        InsertData(XCT200091, 'Sisser Wichmann', '1558 23rd Street', DemoDataSetup.ForeignCode(), '', 'ENU', XHR, 'US', 'US-NY 11010',
          1, XCT100012, XFMAR, '', '', 0);
        InsertData(XCT200092, 'Christina Philp', 'Sgt. Millers Dirve', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-IL 61236',
          1, XCT100001, XF, '', XJMANA, 0);
        InsertData(XCT200093, 'Richard Bready', '854 Theater Road', XNE, '', 'ENG', XEH, 'GB', 'GB-WD1 6YG',
          1, XCT100017, XM, '', '', 0);
        InsertData(XCT200094, 'David Campbell', '810 South Newport Drive', 'MID', '', 'ENG', XJO, 'GB', 'GB-NP5 6GH',
          1, XCT100009, XM, '', '', 0);
        InsertData(XCT200095, 'Joseph Matthews', '222 Reagan Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XRB, 'US', 'US-SC 27136',
          1, ContactNo(DATABASE::Vendor, '01254796'), XM, '', '', 0);
        InsertData(XCT200096, 'Michael Ruggiero', 'Strandvejen 334', DemoDataSetup.ForeignCode(), '', 'DAN', XBC, 'DK', 'DK-2950',
          1, XCT100019, XM, '', XJMANA, 0);
        InsertData(XCT200097, 'Michael Pfeiffer', '220 Richdale Ave', DemoDataSetup.ForeignCode(), '', 'ENU', XRB, 'US', 'US-NY 11010',
          1, XCT100003, XM, '', '', 0);
        InsertData(XCT200098, 'Dick Dievendorff', '854 Theater Road', XNE, '', 'ENG', XEH, 'GB', 'GB-WD1 6YG',
          1, XCT100017, XM, '', '', 0);
        InsertData(XCT200099, 'Andrew R. Hill', '620 Ingridson Av', DemoDataSetup.ForeignCode(), '', 'ENU', XLT, 'US', 'US-SC 27136',
          1, XCT100010, XM, '', '', 0);
        InsertData(XCT200100, 'Stuart Munson', '1120 Newport Ave', 'LND', '', 'ENG', XLT, 'GB', 'GB-M61 2YG',
          1, XCT100007, XM, '', '', 0);
        InsertData(XCT200101, 'Pat Coleman', '395 Westgate Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XOF, 'US', 'US-GA 31772',
          1, XCT100005, XFMAR, '', XJMANA, 0);
        InsertData(XCT200102, 'Tamara Johnston', '1240 Yield mark Street', 'MID', '', 'ENG', XRB, 'GB', 'GB-N12 5XY',
          1, XCT100008, XFUMAR, '', '', 0);
        InsertData(XCT200103, 'Dan K. Bacon Jr.', 'Sgt. Millers Dirve', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-IL 61236',
          1, XCT100001, XM, '', '', 0);
        InsertData(XCT200104, 'Paul Komosinski', '435 Kingston Street', DemoDataSetup.ForeignCode(), '', 'ENU', XHR, 'US', 'US-NY 11010',
          1, XCT100011, XM, '', '', 0);
        InsertData(XCT200105, 'Henning Serritslev', 'Strandvejen 334', DemoDataSetup.ForeignCode(), '', 'DAN', XBC, 'DK', 'DK-2950',
          1, XCT100019, XM, '', XJMANA, 0);
        InsertData(XCT200106, 'An Van Gysel', 'Parklaan 3', DemoDataSetup.ForeignCode(), '', 'NLB', XRB, 'BE', 'BE-2800',
          1, ContactNo(DATABASE::Vendor, '32554455'), XFMAR, '', '', 0);
        InsertData(XCT200107, 'Pete Male', '854 Theater Road', XNE, '', 'ENG', XEH, 'GB', 'GB-WD1 6YG',
          1, XCT100017, XM, '', '', 0);
        InsertData(XCT200108, 'Richard Carey', '1240 Yield mark Street', 'MID', '', 'ENG', XRB, 'GB', 'GB-N12 5XY',
          1, XCT100008, XM, '', XJMANA, 0);
        InsertData(XCT200109, 'Olinda Turner', '220 Richdale Ave', DemoDataSetup.ForeignCode(), '', 'ENU', XRB, 'US', 'US-NY 11010',
          1, XCT100003, XFMAR, '', '', 0);
        InsertData(XCT200110, 'Douglas Groncki', '620 Ingridson Av', DemoDataSetup.ForeignCode(), '', 'ENU', XLT, 'US', 'US-SC 27136',
          1, XCT100010, XM, '', '', 0);
        InsertData(XCT200111, 'Keith Harris', '1120 Newport Ave', 'LND', '', 'ENG', XLT, 'GB', 'GB-M61 2YG',
          1, XCT100007, XM, '', '', 0);
        InsertData(XCT200112, 'Dylan Miller', '620 Ingridson Av', DemoDataSetup.ForeignCode(), '', 'ENU', XLT, 'US', 'US-SC 27136',
          1, XCT100010, XM, '', XJMANA, 0);
        InsertData(XCT200113, 'Brian Lloyd', '340 Marlboro Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XEH, 'US', 'US-GA 31772',
          1, XCT100014, XM, '', '', 0);
        InsertData(XCT200114, 'Henrik Larsen', 'Parkvej 44', DemoDataSetup.ForeignCode(), '', 'DAN', XOF, 'DK', 'DK-5800',
          1, ContactNo(DATABASE::Customer, '45779977'), XM, '', '', 0);
        InsertData(XCT200115, 'Jeff Stammler', '395 Westgate Drive', DemoDataSetup.ForeignCode(), '', 'ENU', XOF, 'US', 'US-GA 31772',
          1, XCT100005, XM, '', '', 0);
        InsertData(XCT200116, 'David Oliver Lawrence', '2570 Swimthon Street', 'EANG', '', 'ENG', XEH, 'GB', 'GB-MO2 4RT',
          1, XCT100006, XM, '', XJMANA, 0);
        InsertData(XCT200117, 'Lone Strandbygaard', 'Strandvejen 334', DemoDataSetup.ForeignCode(), '', 'DAN', XBC, 'DK', 'DK-2950',
          1, XCT100019, XFMAR, '', '', 0);
        InsertData(XCT200118, 'Lori Kane', '2570 Swimthon Street', 'EANG', '', 'ENG', XEH, 'GB', 'GB-MO2 4RT',
          1, XCT100006, XFUMAR, '', '', 0);
        InsertData(XCT200119, 'Kimberly B. Zimmermann', '435 Kingston Street', DemoDataSetup.ForeignCode(), '', 'ENU', XHR, 'US', 'US-NY 11010',
          1, XCT100011, XFMAR, '', '', 0);
        InsertData(XCT200120, 'Simon Rapier', '210 Bimer Drive', XNW, '', 'ENG', XOF, 'GB', 'GB-PL14 5GB',
          1, XCT100013, XM, '', '', 0);
        InsertData(XCT200121, 'Sam Abolrous', '1558 23rd Street', DemoDataSetup.ForeignCode(), '', 'ENU', XHR, 'US', 'US-NY 11010',
          1, XCT100012, XM, '', XJMANA, 0);
        InsertData(XCT200122, 'David M. Bradley', '1120 Newport Ave', 'LND', '', 'ENG', XLT, 'GB', 'GB-M61 2YG',
          1, XCT100007, XM, '', '', 0);
        InsertData(XCT200123, 'Angela Barbariol', '854 Theater Road', XNE, '', 'ENG', XEH, 'GB', 'GB-WD1 6YG',
          1, XCT100017, XFMAR, '', '', 0);
        InsertData(XCT200124, 'Matthew Carroll', '854 Theater Road', XNE, '', 'ENG', XEH, 'GB', 'GB-WD1 6YG',
          1, XCT100017, XM, '', '', 0);
        InsertData(XCT200125, 'Brian Cox', '854 Theater Road', XNE, '', 'ENG', XEH, 'GB', 'GB-WD1 6YG',
          1, XCT100017, XM, '', '', 0);
        InsertData(XCT200126, 'Brandon D. Heidepriem', '220 Richdale Ave', DemoDataSetup.ForeignCode(), '', 'ENU', XRB, 'US', 'US-NY 11010',
          1, XCT100003, XM, '', XJMANA, 0);
        InsertData(XCT200127, 'Bob Gage', '620 Ingridson Av', DemoDataSetup.ForeignCode(), '', 'ENU', XLT, 'US', 'US-SC 27136',
          1, XCT100010, XM, '', '', 0);
        InsertData(XCT200128, 'Sharon Hoepf', '220 Richdale Ave', DemoDataSetup.ForeignCode(), '', 'ENU', XRB, 'US', 'US-NY 11010',
          1, XCT100003, XFMAR, '', '', 0);
        InsertData(XCT200129, 'Nancy Buchanan', '1240 Yield mark Street', 'MID', '', 'ENG', XRB, 'GB', 'GB-N12 5XY',
          1, XCT100008, XFMAR, '', '', 0);
        InsertData(XCT200130, XAlanSteiner, X28TheTything, XSCOT, '', XENG, XHR, XGB, 'GB-OX16 0UA',
          1, XCT100241, XM, '', '', 0);
        InsertData(XCT200131, 'Linda Moschell', '1240 Yield mark Street', 'MID', '', 'ENG', XRB, 'GB', 'GB-N12 5XY',
          1, XCT100008, XFMAR, '', XJMANA, 0);
        InsertData(XCT200132, 'Matthew Hink', '810 South Newport Drive', 'MID', '', 'ENG', XJO, 'GB', 'GB-NP5 6GH',
          1, XCT100009, XM, '', '', 0);
        InsertData(XCT200133, 'Shane S. Kim', '620 Ingridson Av', DemoDataSetup.ForeignCode(), '', 'ENU', XLT, 'US', 'US-SC 27136',
          1, XCT100010, XM, '', '', 0);
        InsertData(XCT200134, 'Steven B. Levy', '435 Kingston Street', DemoDataSetup.ForeignCode(), '', 'ENU', XHR, 'US', 'US-NY 11010',
          1, XCT100011, XM, '', '', 0);
        InsertData(XCT200135, 'Terry Adams', '810 South Newport Drive', 'MID', '', 'ENG', XJO, 'GB', 'GB-NP5 6GH',
          1, XCT100009, XM, '', '', 0);
        InsertData(XCT200136, 'Mindy Martin', '1558 23rd Street', DemoDataSetup.ForeignCode(), '', 'ENU', XJO, 'US', 'US-NY 11010',
          1, ContactNo(DATABASE::Customer, '10000'), XFMAR, '', XJMANA, 0);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Contact: Record Contact;
        RMSetup: Record "Marketing Setup";
        DuplMgt: Codeunit DuplicateManagement;
        CreatePostCode: Codeunit "Create Post Code";
        XCT100239: Label 'CT100239';
        XCT100240: Label 'CT100240';
        XCT100241: Label 'CT100241';
        XCT100242: Label 'CT100242';
        XCT100243: Label 'CT100243';
        XCT100244: Label 'CT100244';
        XCT100245: Label 'CT100245';
        XCT100001: Label 'CT100001';
        XCT100002: Label 'CT100002';
        XCT100003: Label 'CT100003';
        XCT100004: Label 'CT100004';
        XCT100005: Label 'CT100005';
        XCT100006: Label 'CT100006';
        XCT100007: Label 'CT100007';
        XCT100008: Label 'CT100008';
        XCT100009: Label 'CT100009';
        XCT100010: Label 'CT100010';
        XCT100011: Label 'CT100011';
        XCT100012: Label 'CT100012';
        XCT100013: Label 'CT100013';
        XCT100014: Label 'CT100014';
        XCT100015: Label 'CT100015';
        XCT100016: Label 'CT100016';
        XCT100017: Label 'CT100017';
        XCT100018: Label 'CT100018';
        XCT100019: Label 'CT100019';
        XCT100120: Label 'CT100120';
        XCT100121: Label 'CT100121';
        XCT100122: Label 'CT100122';
        XCT100123: Label 'CT100123';
        XCT100124: Label 'CT100124';
        XCT100125: Label 'CT100125';
        XCT100126: Label 'CT100126';
        XCT100127: Label 'CT100127';
        XCT100128: Label 'CT100128';
        XCT100129: Label 'CT100129';
        XCT100130: Label 'CT100130';
        XCT100131: Label 'CT100131';
        XCT100132: Label 'CT100132';
        XCT100133: Label 'CT100133';
        XCT100134: Label 'CT100134';
        XCT100135: Label 'CT100135';
        XCT100136: Label 'CT100136';
        XCT100137: Label 'CT100137';
        XCT100138: Label 'CT100138';
        XCT100139: Label 'CT100139';
        XCT100140: Label 'CT100140';
        XCT100141: Label 'CT100141';
        XCT100142: Label 'CT100142';
        XCT100143: Label 'CT100143';
        XCT100144: Label 'CT100144';
        XCT100145: Label 'CT100145';
        XCT100146: Label 'CT100146';
        XCT100147: Label 'CT100147';
        XCT100148: Label 'CT100148';
        XCT100149: Label 'CT100149';
        XCT100150: Label 'CT100150';
        XCT100151: Label 'CT100151';
        XCT100152: Label 'CT100152';
        XCT100153: Label 'CT100153';
        XCT100154: Label 'CT100154';
        XCT100155: Label 'CT100155';
        XCT100156: Label 'CT100156';
        XCT100157: Label 'CT100157';
        XCT100158: Label 'CT100158';
        XCT100159: Label 'CT100159';
        XCT100160: Label 'CT100160';
        XCT100161: Label 'CT100161';
        XCT100162: Label 'CT100162';
        XCT100163: Label 'CT100163';
        XCT100164: Label 'CT100164';
        XCT100165: Label 'CT100165';
        XCT100166: Label 'CT100166';
        XCT100167: Label 'CT100167';
        XCT100168: Label 'CT100168';
        XCT100169: Label 'CT100169';
        XCT100170: Label 'CT100170';
        XCT100171: Label 'CT100171';
        XCT100172: Label 'CT100172';
        XCT100173: Label 'CT100173';
        XCT100174: Label 'CT100174';
        XCT100175: Label 'CT100175';
        XCT100176: Label 'CT100176';
        XCT100177: Label 'CT100177';
        XCT100178: Label 'CT100178';
        XCT100179: Label 'CT100179';
        XCT100180: Label 'CT100180';
        XCT100181: Label 'CT100181';
        XCT100182: Label 'CT100182';
        XCT100183: Label 'CT100183';
        XCT100184: Label 'CT100184';
        XCT100185: Label 'CT100185';
        XCT100186: Label 'CT100186';
        XCT100187: Label 'CT100187';
        XCT100188: Label 'CT100188';
        XCT100189: Label 'CT100189';
        XCT100190: Label 'CT100190';
        XCT100191: Label 'CT100191';
        XCT100192: Label 'CT100192';
        XCT100193: Label 'CT100193';
        XCT100194: Label 'CT100194';
        XCT100195: Label 'CT100195';
        XCT100196: Label 'CT100196';
        XCT100197: Label 'CT100197';
        XCT100198: Label 'CT100198';
        XCT100199: Label 'CT100199';
        XCT100200: Label 'CT100200';
        XCT100201: Label 'CT100201';
        XCT100202: Label 'CT100202';
        XCT100203: Label 'CT100203';
        XCT100204: Label 'CT100204';
        XCT100205: Label 'CT100205';
        XCT100206: Label 'CT100206';
        XCT100207: Label 'CT100207';
        XCT100208: Label 'CT100208';
        XCT100209: Label 'CT100209';
        XCT100210: Label 'CT100210';
        XCT100211: Label 'CT100211';
        XCT100212: Label 'CT100212';
        XCT100213: Label 'CT100213';
        XCT100214: Label 'CT100214';
        XCT100215: Label 'CT100215';
        XCT100216: Label 'CT100216';
        XCT100217: Label 'CT100217';
        XCT100218: Label 'CT100218';
        XCT100219: Label 'CT100219';
        XCT100220: Label 'CT100220';
        XCT100221: Label 'CT100221';
        XCT100222: Label 'CT100222';
        XCT100223: Label 'CT100223';
        XCT100224: Label 'CT100224';
        XCT100225: Label 'CT100225';
        XCT100226: Label 'CT100226';
        XCT100227: Label 'CT100227';
        XCT100228: Label 'CT100228';
        XCT100229: Label 'CT100229';
        XCT100230: Label 'CT100230';
        XCT100231: Label 'CT100231';
        XCT100232: Label 'CT100232';
        XCT100233: Label 'CT100233';
        XCT100234: Label 'CT100234';
        XCT100235: Label 'CT100235';
        XCT100236: Label 'CT100236';
        XCT100237: Label 'CT100237';
        XCT100238: Label 'CT100238';
        XCT200001: Label 'CT200001';
        XCT200002: Label 'CT200002';
        XCT200003: Label 'CT200003';
        XCT200004: Label 'CT200004';
        XCT200005: Label 'CT200005';
        XCT200006: Label 'CT200006';
        XCT200007: Label 'CT200007';
        XCT200008: Label 'CT200008';
        XCT200009: Label 'CT200009';
        XCT200010: Label 'CT200010';
        XCT200011: Label 'CT200011';
        XCT200012: Label 'CT200012';
        XCT200013: Label 'CT200013';
        XCT200014: Label 'CT200014';
        XCT200015: Label 'CT200015';
        XCT200016: Label 'CT200016';
        XCT200017: Label 'CT200017';
        XCT200018: Label 'CT200018';
        XCT200019: Label 'CT200019';
        XCT200020: Label 'CT200020';
        XCT200021: Label 'CT200021';
        XCT200022: Label 'CT200022';
        XCT200023: Label 'CT200023';
        XCT200024: Label 'CT200024';
        XCT200026: Label 'CT200026';
        XCT200025: Label 'CT200025';
        XCT200027: Label 'CT200027';
        XCT200028: Label 'CT200028';
        XCT200029: Label 'CT200029';
        XCT200030: Label 'CT200030';
        XCT200031: Label 'CT200031';
        XCT200032: Label 'CT200032';
        XCT200033: Label 'CT200033';
        XCT200034: Label 'CT200034';
        XCT200035: Label 'CT200035';
        XCT200036: Label 'CT200036';
        XCT200037: Label 'CT200037';
        XCT200038: Label 'CT200038';
        XCT200039: Label 'CT200039';
        XCT200040: Label 'CT200040';
        XCT200041: Label 'CT200041';
        XCT200042: Label 'CT200042';
        XCT200043: Label 'CT200043';
        XCT200044: Label 'CT200044';
        XCT200045: Label 'CT200045';
        XCT200046: Label 'CT200046';
        XCT200047: Label 'CT200047';
        XCT200048: Label 'CT200048';
        XCT200049: Label 'CT200049';
        XCT200050: Label 'CT200050';
        XCT200051: Label 'CT200051';
        XCT200052: Label 'CT200052';
        XCT200053: Label 'CT200053';
        XCT200054: Label 'CT200054';
        XCT200055: Label 'CT200055';
        XCT200056: Label 'CT200056';
        XCT200057: Label 'CT200057';
        XCT200058: Label 'CT200058';
        XCT200059: Label 'CT200059';
        XCT200060: Label 'CT200060';
        XCT200061: Label 'CT200061';
        XCT200062: Label 'CT200062';
        XCT200063: Label 'CT200063';
        XCT200064: Label 'CT200064';
        XCT200065: Label 'CT200065';
        XCT200066: Label 'CT200066';
        XCT200067: Label 'CT200067';
        XCT200068: Label 'CT200068';
        XCT200069: Label 'CT200069';
        XCT200070: Label 'CT200070';
        XCT200071: Label 'CT200071';
        XCT200072: Label 'CT200072';
        XCT200073: Label 'CT200073';
        XCT200074: Label 'CT200074';
        XCT200075: Label 'CT200075';
        XCT200076: Label 'CT200076';
        XCT200077: Label 'CT200077';
        XCT200078: Label 'CT200078';
        XCT200079: Label 'CT200079';
        XCT200081: Label 'CT200081';
        XCT200080: Label 'CT200080';
        XCT200082: Label 'CT200082';
        XCT200083: Label 'CT200083';
        XCT200084: Label 'CT200084';
        XCT200085: Label 'CT200085';
        XCT200086: Label 'CT200086';
        XCT200087: Label 'CT200087';
        XCT200088: Label 'CT200088';
        XCT200089: Label 'CT200089';
        XCT200090: Label 'CT200090';
        XCT200091: Label 'CT200091';
        XCT200092: Label 'CT200092';
        XCT200093: Label 'CT200093';
        XCT200094: Label 'CT200094';
        XCT200095: Label 'CT200095';
        XCT200096: Label 'CT200096';
        XCT200097: Label 'CT200097';
        XCT200098: Label 'CT200098';
        XCT200099: Label 'CT200099';
        XCT200100: Label 'CT200100';
        XCT200101: Label 'CT200101';
        XCT200102: Label 'CT200102';
        XCT200103: Label 'CT200103';
        XCT200104: Label 'CT200104';
        XCT200105: Label 'CT200105';
        XCT200106: Label 'CT200106';
        XCT200107: Label 'CT200107';
        XCT200108: Label 'CT200108';
        XCT200109: Label 'CT200109';
        XCT200110: Label 'CT200110';
        XCT200111: Label 'CT200111';
        XCT200112: Label 'CT200112';
        XCT200113: Label 'CT200113';
        XCT200114: Label 'CT200114';
        XCT200115: Label 'CT200115';
        XCT200116: Label 'CT200116';
        XCT200117: Label 'CT200117';
        XCT200118: Label 'CT200118';
        XCT200119: Label 'CT200119';
        XCT200120: Label 'CT200120';
        XCT200121: Label 'CT200121';
        XCT200122: Label 'CT200122';
        XCT200123: Label 'CT200123';
        XCT200124: Label 'CT200124';
        XCT200125: Label 'CT200125';
        XCT200126: Label 'CT200126';
        XCT200127: Label 'CT200127';
        XCT200128: Label 'CT200128';
        XCT200129: Label 'CT200129';
        XCT200130: Label 'CT200130';
        XCT200131: Label 'CT200131';
        XCT200132: Label 'CT200132';
        XCT200133: Label 'CT200133';
        XCT200134: Label 'CT200134';
        XCT200135: Label 'CT200135';
        XCT200136: Label 'CT200136';
        XCaneShowroom: Label 'Cane Showroom';
        XRingwoodRoad: Label 'Ringwood Road';
        XS: Label 'S';
        XENG: Label 'ENG';
        XHR: Label 'HR';
        XGB: Label 'GB';
        XLordshipLaneFurnishers: Label 'Lordship Lane Furnishers';
        X457LordshipLane: Label '457 Lordship Lane';
        XSE: Label 'SE';
        XLT: Label 'LT';
        XTimelessReproductions: Label 'Timeless Reproductions';
        X28TheTything: Label '28 The Tything';
        XSCOT: Label 'SCOT';
        XWyllieANDMar: Label 'Wyllie & Mar';
        XHighStreetRipley: Label 'High Street Ripley';
        XSW: Label 'SW';
        XJO: Label 'JO';
        XCompohandlerLtd: Label 'Compohandler Ltd';
        XCarmunnockByPassBusby: Label 'Carmunnock By-Pass Busby';
        XRB: Label 'RB';
        X10NorthLakeAvenue: Label '10 North Lake Avenue';
        XEH: Label 'EH';
        XOF: Label 'OF';
        XBC: Label 'BC';
        XMarkHarrington: Label 'Mark Harrington';
        XLND: Label 'LND';
        XJulieTaftRider: Label 'Julie Taft-Rider';
        X172FieldGreen: Label '172 Field Green';
        XAndrewLan: Label 'Andrew Lan';
        XScottBishop: Label 'Scott Bishop';
        XJaneClayton: Label 'Jane Clayton';
        XAdamBarr: Label 'Adam Barr';
        XJohnEvans: Label 'John Evans';
        XSamanthaSmith: Label 'Samantha Smith';
        XPatrickMCook: Label 'Patrick M. Cook';
        XCarlLanghorn: Label 'Carl Langhorn';
        XAlanSteiner: Label 'Alan Steiner';
        XJuliaMoseley: Label 'Julia Moseley';
        XSusanWEaton: Label 'Susan W. Eaton';
        XJonathanMollerup: Label 'Jonathan Mollerup';
        XBarbaraMoreland: Label 'Barbara Moreland';
        XM: Label 'M';
        XFMAR: Label 'F-MAR';
        XJMANA: Label 'J-MANA';
        XNE: Label 'NE';
        XNW: Label 'NW';
        XN: Label 'N';
        XF: Label 'F';
        XFUMAR: Label 'F-UMAR';
        XEANG: Label 'EANG';
        XNBL: Label 'NBL';
        XWWBOPERATING: Label 'WWB-OPERATING';
        XWWBUSD: Label 'WWB-USD';
        XDavidHodgson: Label 'David Hodgson';
        X192MarketSquare: Label '192 Market Square';
        XMID: Label 'MID';
        X4BakerStreet: Label '4 Baker Street';
        XJohnEmory: Label 'John Emory';
        XJackCreasey: Label 'Jack Creasey';
        X1HighHolborn: Label '1 High Holborn';
        XDeborahPoe: Label 'Deborah Poe';
        XStephanieBourne: Label 'Stephanie Bourne';
        XJenniferRiegle: Label 'Jennifer Riegle';
        XMichaelSullivan: Label 'Michael Sullivan';
        XJamesRHamilton: Label 'James R. Hamilton';
        XAlexRoland: Label 'Alex Roland';
        XTinaGorenc: Label 'Tina Gorenc';
        X86StokeNewington: Label '86 Stoke Newington';
        XPamelaAnsmanWolfe: Label 'Pamela Ansman-Wolfe';
        X47HigherMarketStreet: Label '47 Higher Market Street';
        XTracyTallman: Label 'Tracy Tallman';
        EmailDomainTok: Label '@contoso.com', Locked = true;

    procedure InsertData("No.": Code[20]; Name: Text[30]; Address: Text[30]; "Territory Code": Code[10]; "Currency Code": Code[10]; "Language Code": Code[10]; "Salesperson Code": Code[10]; "Country Code": Code[10]; "Post Code": Code[20]; Type: Option Company,Person; "Company No.": Code[20]; "Salutation Code": Code[10]; "Job Title": Text[30]; "Organizational Level Code": Code[10]; "Correspondence Type": Option)
    var
        DemoDataSetup: Record "Demo Data Setup";
        ImagePath: Text;
    begin
        Contact.Init();
        Contact.Validate("No.", "No.");
        Contact.Type := "Contact Type".FromInteger(Type);
        Contact.Validate(Name, Name);
        Contact.TypeChange();
        if (Contact.Type = Contact.Type::Person) and ("Company No." <> '') then
            Contact.Validate("Company No.", "Company No.");
        RMSetup.Get();
        if Type = Type::Company then
            Contact.Validate("Salutation Code", RMSetup."Def. Company Salutation Code")
        else
            Contact.Validate("Salutation Code", "Salutation Code");
        Contact.Validate(Address, Address);
        Contact.Validate("Territory Code", "Territory Code");
        DemoDataSetup.Get();
        if "Currency Code" = DemoDataSetup."Currency Code" then
            "Currency Code" := '';
        Contact.Validate("Currency Code", "Currency Code");
        Contact.Validate("Language Code", "Language Code");
        Contact.Validate("Salesperson Code", "Salesperson Code");
        Contact.Validate("Country/Region Code", "Country Code");
        Contact."Post Code" := CreatePostCode.FindPostCode("Post Code");
        Contact.City := CreatePostCode.FindCity("Post Code");
        Contact.Validate(County, CreatePostCode.GetCounty(Contact."Post Code", Contact.City));
        Contact.Validate("Correspondence Type", "Correspondence Type");
        Contact.Validate("E-Mail", CreateContactEMail(Contact.Name, Contact."No."));
        Contact.Validate("Job Title", "Job Title");
        Contact.Validate("Organizational Level Code", "Organizational Level Code");
        ImagePath := DemoDataSetup."Path to Picture Folder" + StrSubstNo('Images\Person\OnPrem\%1.jpg', Name);
        if Exists(ImagePath) then
            Contact.Image.ImportFile(ImagePath, Name);
        Contact.Insert();
        if Contact.Type = Contact.Type::Company then
            DuplMgt.MakeContIndex(Contact);
    end;

    procedure ContactNo(TableID: Integer; No: Code[20]): Code[20]
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        ContBusRel.SetCurrentKey("Link to Table", "No.");
        case TableID of
            DATABASE::Customer:
                ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
            DATABASE::Vendor:
                ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
            DATABASE::"Bank Account":
                ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::"Bank Account");
        end;
        ContBusRel.SetRange("No.", No);
        ContBusRel.FindFirst();
        exit(ContBusRel."Contact No.");
    end;

    procedure CreateContactEMail(Name: Text[100]; "No.": Code[20]) EMail: Text[100]
    var
        FrCharacters: Text[260];
        ToCharacters: Text[260];
        EMailDomain: Text[15];
    begin
        EMailDomain := EmailDomainTok;
        if Name <> '' then
            Name := LowerCase(Name)
        else
            Name := LowerCase("No.");

        FrCharacters := ' "&(),./:;<=>?@[\]^_`~‘’àáâãäåæčďéêëěìíîïňðñòöõôóøřšťùúûüůýž';
        ToCharacters := '.                       aaaaaaacdeeeeiiiindnoooooorstuuuuuyz';
        EMail := CopyStr(ConvertStr(Name, FrCharacters, ToCharacters), 1, MaxStrLen(Contact."E-Mail") - StrLen(EMailDomain)) + EMailDomain;
        EMail := DelChr(EMail);
        while StrPos(EMail, '..') <> 0 do
            EMail := DelStr(EMail, StrPos(EMail, '..'), 1);

        while StrPos(EMail, '.-.') <> 0 do
            EMail := DelStr(EMail, StrPos(EMail, '-.'), 2);
    end;

    procedure FormatContact(Title: Text[30]; Contact: Text[100]): Text[100]
    begin
        if Title <> '' then
            exit(Title + ' ' + Contact);

        exit(Contact);
    end;

    procedure CreateEvaluationData()
    begin
        DemoDataSetup.Get();
        UpdateContactOnCustomer('10000', 'Robert Townes', XM);
        UpdateContactOnCustomer('20000', 'Helen Ray', XF);
        UpdateContactOnCustomer('30000', 'Meagan Bond', XF);
        UpdateContactOnCustomer('40000', 'Ian Deberry', XM);
        UpdateContactOnCustomer('50000', 'Jesse Homer', XM);
        UpdateContactOnVendor('10000', 'Krystal York', XF);
        UpdateContactOnVendor('20000', 'Evan McIntosh', XM);
        UpdateContactOnVendor('30000', 'Bryce Jasso', XM);
        UpdateContactOnVendor('40000', 'Toby Rhode', XM);
        UpdateContactOnVendor('50000', 'Raymond Hillard', XM);
    end;

    local procedure UpdateContactOnCustomer(CustomerNo: Code[20]; ContactName: Text[100]; SalutationCode: Code[10])
    var
        Customer: Record Customer;
        ImagePath: Text;
    begin
        Customer.Get(CustomerNo);
        ImagePath := StrSubstNo('Images\Person\Saas\%1.jpg', ContactName);
        if Exists(ImagePath) then
            Customer.Image.ImportFile(ImagePath, ContactName);
        Customer.Modify(true);

        Contact.Get(Customer."Primary Contact No.");
        Contact."Salutation Code" := SalutationCode;
        ImagePath := StrSubstNo('Images\Person\Saas\%1.jpg', ContactName);
        if Exists(ImagePath) then
            Contact.Image.ImportFile(ImagePath, ContactName);
        Contact.Modify();
    end;

    local procedure UpdateContactOnVendor(VendorNo: Code[20]; ContactName: Text[100]; SalutationCode: Code[10])
    var
        Vendor: Record Vendor;
        ImagePath: Text;
    begin
        Vendor.Get(VendorNo);
        ImagePath := StrSubstNo('Images\Person\Saas\%1.jpg', ContactName);
        if Exists(ImagePath) then
            Vendor.Image.ImportFile(ImagePath, ContactName);
        Vendor.Modify(true);

        Contact.Get(Vendor."Primary Contact No.");
        Contact."Salutation Code" := SalutationCode;
        ImagePath := StrSubstNo('Images\Person\Saas\%1.jpg', ContactName);
        if Exists(ImagePath) then
            Contact.Image.ImportFile(ImagePath, ContactName);
        Contact.Modify();
    end;
}

