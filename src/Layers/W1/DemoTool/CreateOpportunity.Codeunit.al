codeunit 101592 "Create Opportunity"
{

    trigger OnRun()
    begin
        InsertData(XOP100001, XNewTables, XBC, '', XCT200116,
          XCT100006, XEXLARGE, '', 19021105D, 1, 0, false, 0D, XOPP);
        InsertData(XOP100002, XNewTables, XBC, '', XCT200097,
          XCT100003, XEXLARGE, '', 19021205D, 0, 0, false, 0D, XOPP);
        InsertData(XOP100003, XNewTables, XBC, '', XCT200094,
          XCT100009, XEXLARGE, '', 19021205D, 0, 0, false, 0D, XOPP);
        InsertData(XOP100004, XNewTables, XBC, '', XCT200091,
          XCT100012, XEXLARGE, '', 19021205D, 0, 0, false, 0D, XOPP);
        InsertData(XOP100005, XNewTables, XBC, '', XCT100002,
          XCT100001, XEXLARGE, '', 19021205D, 0, 0, false, 0D, XOPP);
        InsertData(XOP100006, XNewTables, XBC, '', XCT200107,
          XCT100017, XEXLARGE, '', 19021205D, 0, 0, false, 0D, XOPP);
        InsertData(XOP100007, XNewTables, XBC, '', XCT200112,
          XCT100010, XEXLARGE, '', 19021205D, 0, 0, false, 0D, XOPP);
        InsertData(XOP100008, XNewTables, XBC, '', XCT200127,
          XCT100010, XEXLARGE, '', 19021205D, 0, 0, false, 0D, XOPP);
        InsertData(XOP100009, XNewTables, XBC, '', XCT200002,
          XCT100010, XEXLARGE, '', 19021205D, 0, 0, false, 0D, XOPP);
        InsertData(XOP100010, XNewTables, XBC, '', XCT200122,
          XCT100007, XEXLARGE, '', 19021205D, 0, 0, false, 0D, XOPP);
        InsertData(XOP100011, XNewTables, XBC, '', XCT200001,
          XCT100007, XEXLARGE, '', 19021205D, 0, 0, false, 0D, XOPP);
        InsertData(XOP100012, XNewTables, XBC, '', XCT200101,
          XCT100005, XEXLARGE, '', 19021205D, 0, 0, false, 0D, XOPP);
        InsertData(XOP100013, XNewTables, XBC, '', XCT200105,
          XCT100019, XEXLARGE, '', 19021205D, 0, 0, false, 0D, XOPP);
        InsertData(XOP100014, XNewTables, XBC, '', XCT200130,
          XCT100241, XEXLARGE, '', 19021205D, 0, 0, false, 0D, XOPP);
        InsertData(XOP100015, XAssemblingfurniture, XJO, '', XCT200136,
          ContactNo(DATABASE::Customer, '10000'), XEXLARGE, '', 19030104D, 2, 0, true, 19030126D, XOPP);
        InsertData(XOP100016, XAssemblingfurniture, XJO, '', ContactNo(DATABASE::Customer, '20000'),
          ContactNo(DATABASE::Customer, '20000'), XEXSMALL, '', 19030104D, 2, 1, true, 19030121D, XOPP);
        InsertData(XOP100017, XAssemblingfurniture, XJO, '', XCT200080,
          ContactNo(DATABASE::Customer, '30000'), XEXSMALL, '', 19030106D, 2, 1, true, 19030120D, XOPP);
        InsertData(XOP100018, XFurnituretosalesdepartment, XJO, '', ContactNo(DATABASE::Customer, '50000'),
          ContactNo(DATABASE::Customer, '50000'), XFIRSTSMALL, '', 19030106D, 2, 0, true, 19030120D, XOPP);
        InsertData(XOP100019, XFurniturefortheconference, XJO, '', XCT200136,
          ContactNo(DATABASE::Customer, '10000'), XEXLARGE, '', 19030101D, 2, 1, true, 19030111D, XOPP);
        InsertData(XOP100020, XChairsforthecanteen, XOF, '', ContactNo(DATABASE::Customer, '42147258'),
          ContactNo(DATABASE::Customer, '42147258'), XEXSMALL, '', 19030103D, 2, 2, true, 19030112D, XOPP);
        InsertData(XOP100021, XComplconferencearrangement, XOF, '', ContactNo(DATABASE::Customer, '43687129'),
          ContactNo(DATABASE::Customer, '43687129'), XFIRSTSMALL, '', 19030111D, 2, 1, true, 19030116D, XOPP);
        InsertData(XOP100022, XStoragefacilities, XBC, '', XCT100140,
          ContactNo(DATABASE::Customer, '10000'), XEXLARGE, '', 19030121D, 1, 1, false, 0D, XOPP);
        InsertData(XOP100023, XSwivelchair, XBC, '', ContactNo(DATABASE::Customer, '20000'),
          ContactNo(DATABASE::Customer, '20000'), XEXSMALL, '', 19021111D, 1, 1, false, 0D, XOPP);
        InsertData(XOP100024, XTablelightingTxt, XHR, '', XCT200079,
          ContactNo(DATABASE::Customer, '30000'), XEXSMALL, '', 19021214D, 1, 1, false, 0D, XOPP);
        InsertData(XOP100025, XGuestchairsforthereception, XHR, '', ContactNo(DATABASE::Customer, '40000'),
          ContactNo(DATABASE::Customer, '40000'), XEXLARGE, '', 19030124D, 1, 0, false, 0D, XOPP);
        InsertData(XOP100026, XStoragesystem, XHR, '', ContactNo(DATABASE::Customer, '50000'),
          ContactNo(DATABASE::Customer, '50000'), XEXLARGE, '', 19021126D, 1, 2, false, 0D, XOPP);
        InsertData(XOP100027, XDesksfortheservicedep, XJO, '', ContactNo(DATABASE::Customer, '50000'),
          ContactNo(DATABASE::Customer, '50000'), XEXSMALL, '', 19021101D, 0, 1, false, 0D, XOPP);
        InsertData(XOP100028, XChangingofficefurniture, XBC, '', XCT100148,
          ContactNo(DATABASE::Customer, '31669966'), XEXLARGE, '', 19021014D, 1, 2, false, 0D, XOPP);
        InsertData(XOP100029, XLookingforthreepiecesuite, XBC, '', ContactNo(DATABASE::Customer, '31987987'),
          ContactNo(DATABASE::Customer, '31987987'), XEXSMALL, '', 19020905D, 1, 1, false, 0D, XOPP);
        InsertData(XOP100030, X10to15Whiteboards, XHR, '', XCT100215,
          ContactNo(DATABASE::Customer, '32124578'), XEXSMALL, '', 19021112D, 1, 2, false, 0D, XOPP);
        InsertData(XOP100031, XNewconferencesystem, XOF, '', XCT100215,
          ContactNo(DATABASE::Customer, '32124578'), XEXSMALL, '', 19021116D, 1, 2, false, 0D, XOPP);
        InsertData(XOP100032, XDeskandchairforthemanager, XHR, '', ContactNo(DATABASE::Customer, '32656565'),
          ContactNo(DATABASE::Customer, '32656565'), XEXSMALL, '', 19030108D, 1, 1, false, 0D, XOPP);
        InsertData(XOP100033, X12greenswivelchairs, XBC, '', XCT100163,
          ContactNo(DATABASE::Customer, '32789456'), XFIRSTSMALL, '', 19021010D, 1, 1, false, 0D, XOPP);
        InsertData(XOP100034, XNeedaMobilePedestal, XHR, '', XCT100230,
          ContactNo(DATABASE::Customer, '34010100'), XFIRSTLARGE, '', 19021213D, 1, 1, false, 0D, XOPP);
        InsertData(XOP100035, X2Guestchairsblue, XHR, '', XCT100230,
          ContactNo(DATABASE::Customer, '34010100'), XFIRSTLARGE, '', 19021223D, 1, 1, false, 0D, XOPP);
        InsertData(XOP100036, XConferencetableblack, XOF, '', ContactNo(DATABASE::Customer, '34010199'),
          ContactNo(DATABASE::Customer, '34010199'), XEXSMALL, '', 19021128D, 1, 0, false, 0D, XOPP);
        InsertData(XOP100037, XConferencetable, XOF, '', ContactNo(DATABASE::Customer, '01445544'),
          ContactNo(DATABASE::Customer, '01445544'), XFIRSTSMALL, '', 19020926D, 3, 1, true, 19021016D, XOPP);
        InsertData(XOP100038, XNewofficesystem, XOF, '', XCT200009,
          ContactNo(DATABASE::Customer, '31505050'), XFIRSTLARGE, '', 19020922D, 3, 2, true, 19021003D, XOPP);
        InsertData(XOP100039, XCompletestoragesystem, XHR, '', ContactNo(DATABASE::Customer, '34010602'),
          ContactNo(DATABASE::Customer, '34010602'), XFIRSTLARGE, '', 19030105D, 3, 1, true, 19030116D, XOPP);
        InsertData(XOP100040, X30chairsblue, XBC, '', ContactNo(DATABASE::Customer, '34010602'),
          ContactNo(DATABASE::Customer, '34010602'), XEXSMALL, '', 19030109D, 3, 2, true, 19030124D, XOPP);
        InsertData(XOP100041, XInnsbruckStorageunits, XBC, '', XCT100189,
          ContactNo(DATABASE::Customer, '35122112'), XEXLARGE, '', 19021018D, 3, 1, true, 19021024D, XOPP);
        InsertData(XOP100042, X2guestchairs, XBC, '', XCT100189,
          ContactNo(DATABASE::Customer, '35122112'), XEXLARGE, '', 19030106D, 3, 1, true, 19030121D, XOPP);
        InsertData(XOP100043, XLampsforthemanageroffice, XHR, '', ContactNo(DATABASE::Customer, '35963852'),
          ContactNo(DATABASE::Customer, '35963852'), XEXSMALL, '', 19021117D, 3, 2, true, 19021120D, XOPP);
        InsertData(XOP100044, XLampsforthecanteen, XOF, '', ContactNo(DATABASE::Customer, '32656565'),
          ContactNo(DATABASE::Customer, '32656565'), XFIRSTSMALL, '', 19030110D, 3, 1, true, 19030121D, XOPP);
        InsertData(XOP100045, XNewInterior, XBC, '', XCT100132,
          ContactNo(DATABASE::Customer, '01121212'), XFIRSTLARGE, '', 19021011D, 1, 1, false, 0D, XOPP);
        InsertData(XOP100046, XNewlampsinthereception, XHR, '', ContactNo(DATABASE::Customer, '01445544'),
          ContactNo(DATABASE::Customer, '01445544'), XFIRSTSMALL, '', 19021107D, 1, 2, false, 0D, XOPP);
        InsertData(XOP100047, XGuestchairsforthereception, XOF, '', XCT100152,
          ContactNo(DATABASE::Customer, '01454545'), XFIRSTLARGE, '', 19021015D, 1, 1, false, 0D, XOPP);
        InsertData(XOP100048, XInterestedintheROMEchair, XBC, '', XCT100152,
          ContactNo(DATABASE::Customer, '01454545'), XFIRSTLARGE, '', 19021103D, 1, 2, false, 0D, XOPP);
        InsertData(XOP100049, XStorageunitsorshelves, XHR, '', XCT100226,
          ContactNo(DATABASE::Customer, '31505050'), XFIRSTSMALL, '', 19021203D, 1, 0, false, 0D, XOPP);
    end;

    var
        Opportunity: Record Opportunity;
        XOP100001: Label 'OP100001';
        XOP100002: Label 'OP100002';
        XOP100004: Label 'OP100004';
        XOP100005: Label 'OP100005';
        XOP100007: Label 'OP100007';
        XOP100006: Label 'OP100006';
        XOP100008: Label 'OP100008';
        XOP100009: Label 'OP100009';
        XOP100010: Label 'OP100010';
        XOP100011: Label 'OP100011';
        XOP100012: Label 'OP100012';
        XOP100013: Label 'OP100013';
        XOP100014: Label 'OP100014';
        XOP100015: Label 'OP100015';
        XOP100016: Label 'OP100016';
        XOP100017: Label 'OP100017';
        XOP100018: Label 'OP100018';
        XOP100019: Label 'OP100019';
        XOP100020: Label 'OP100020';
        XOP100022: Label 'OP100022';
        XOP100021: Label 'OP100021';
        XOP100023: Label 'OP100023';
        XOP100024: Label 'OP100024';
        XOP100025: Label 'OP100025';
        XOP100026: Label 'OP100026';
        XOP100027: Label 'OP100027';
        XOP100028: Label 'OP100028';
        XOP100029: Label 'OP100029';
        XOP100030: Label 'OP100030';
        XOP100031: Label 'OP100031';
        XOP100032: Label 'OP100032';
        XOP100033: Label 'OP100033';
        XOP100034: Label 'OP100034';
        XOP100035: Label 'OP100035';
        XOP100036: Label 'OP100036';
        XOP100037: Label 'OP100037';
        XOP100038: Label 'OP100038';
        XOP100039: Label 'OP100039';
        XOP100040: Label 'OP100040';
        XOP100041: Label 'OP100041';
        XOP100042: Label 'OP100042';
        XOP100043: Label 'OP100043';
        XOP100044: Label 'OP100044';
        XOP100045: Label 'OP100045';
        XOP100046: Label 'OP100046';
        XOP100047: Label 'OP100047';
        XOP100048: Label 'OP100048';
        XOP100049: Label 'OP100049';
        XNewTables: Label 'New tables';
        XBC: Label 'BC';
        XCT200116: Label 'CT200116';
        XCT100006: Label 'CT100006';
        XEXLARGE: Label 'EX-LARGE';
        XOPP: Label 'OPP';
        XCT200097: Label 'CT200097';
        XCT100012: Label 'CT100012';
        XCT100003: Label 'CT100003';
        XCT200091: Label 'CT200091';
        XCT100009: Label 'CT100009';
        XCT200094: Label 'CT200094';
        XOP100003: Label 'OP100003';
        XCT100002: Label 'CT100002';
        XCT100001: Label 'CT100001';
        XCT200107: Label 'CT200107';
        XCT100017: Label 'CT100017';
        XCT100010: Label 'CT100010';
        XCT200112: Label 'CT200112';
        XCT200002: Label 'CT200002';
        XCT200127: Label 'CT200127';
        XCT200122: Label 'CT200122';
        XCT100007: Label 'CT100007';
        XCT200001: Label 'CT200001';
        XCT100005: Label 'CT100005';
        XCT100019: Label 'CT100019';
        XCT100241: Label 'CT100241';
        XCT200101: Label 'CT200101';
        XCT200130: Label 'CT200130';
        XAssemblingfurniture: Label 'Assembling furniture';
        XJO: Label 'JO';
        XCT200136: Label 'CT200136';
        XEXSMALL: Label 'EX-SMALL';
        XCT200080: Label 'CT200080';
        XCT200105: Label 'CT200105';
        XFurnituretosalesdepartment: Label 'Furniture to sales department';
        XFIRSTSMALL: Label 'FIRSTSMALL';
        XFurniturefortheconference: Label 'Furniture for the conference';
        XChairsforthecanteen: Label 'Chairs for the canteen';
        XOF: Label 'OF';
        XComplconferencearrangement: Label 'Compl. conference arrangement';
        XStoragefacilities: Label 'Storage facilities';
        XCT100140: Label 'CT100140';
        XSwivelchair: Label 'Swivel chair';
        XTablelightingTxt: Label 'Table lighting';
        XHR: Label 'HR';
        XCT200079: Label 'CT200079';
        XStoragesystem: Label 'Storage system';
        XDesksfortheservicedep: Label 'Desks for the service dept.';
        XChangingofficefurniture: Label 'Changing office furniture';
        XCT100148: Label 'CT100148';
        XLookingforthreepiecesuite: Label 'Looking for three-piece suite';
        X10to15Whiteboards: Label '10 to 15 Whiteboards';
        XCT100215: Label 'CT100215';
        XNewconferencesystem: Label 'New conference system';
        XDeskandchairforthemanager: Label 'Desk and chair for the manager';
        X12greenswivelchairs: Label '12 green swivel chairs';
        XCT100163: Label 'CT100163';
        XNeedaMobilePedestal: Label 'Need a Mobile Pedestal';
        XCT100230: Label 'CT100230';
        X2Guestchairsblue: Label '2 Guest chairs, blue';
        XFIRSTLARGE: Label 'FIRSTLARGE';
        XConferencetableblack: Label 'Conference table, black';
        XConferencetable: Label 'Conference table';
        XCT200009: Label 'CT200009';
        XNewofficesystem: Label 'New office system';
        XCompletestoragesystem: Label 'Complete storage system';
        X30chairsblue: Label '30 chairs, blue';
        XCT100189: Label 'CT100189';
        XInnsbruckStorageunits: Label 'Innsbruck Storage units';
        X2guestchairs: Label '2 guest chairs';
        XLampsforthemanageroffice: Label 'Lamps for the manager office';
        XLampsforthecanteen: Label 'Lamps for the canteen';
        XNewInterior: Label 'New Interior';
        XCT100132: Label 'CT100132';
        XNewlampsinthereception: Label 'New lamps in the reception';
        XGuestchairsforthereception: Label 'Guest chairs for the reception';
        XCT100152: Label 'CT100152';
        XInterestedintheROMEchair: Label 'Interested in the ROME chair';
        XStorageunitsorshelves: Label 'Storage units or shelves';
        XCT100226: Label 'CT100226';
        MakeAdjustments: Codeunit "Make Adjustments";
        XEXISTING: Label 'EXISTING';
        XNEW: Label 'NEW';

    procedure InsertData("No.": Code[10]; Description: Text[30]; "Salesperson Code": Code[10]; "Campaign No.": Code[10]; "Contact No.": Code[20]; "Contact Company No.": Code[20]; "Sales Cycle Code": Code[10]; "Sales Document No.": Code[10]; Date: Date; Status: Option; Priority: Option; Closed: Boolean; "Date Closed": Date; "No. Series": Code[10])
    begin
        Opportunity.Init();
        Opportunity.Validate("No.", "No.");
        Opportunity.Validate(Description, Description);
        Opportunity.Validate("Salesperson Code", "Salesperson Code");
        Opportunity.Validate("Contact No.", "Contact No.");
        Opportunity.Validate("Contact Company No.", "Contact Company No.");
        Opportunity.Validate("Sales Cycle Code", "Sales Cycle Code");
        Opportunity.Validate("Sales Document Type", Opportunity."Sales Document Type"::Quote);
        Opportunity.Validate("Sales Document No.", "Sales Document No.");
        Opportunity.Validate("Creation Date", MakeAdjustments.AdjustDate(Date));
        Opportunity.Validate(Status, Status);
        Opportunity.Validate(Priority, Priority);
        Opportunity.Validate(Closed, Closed);
        Opportunity.Validate("Date Closed", MakeAdjustments.AdjustDate("Date Closed"));
        Opportunity.Validate("No. Series", "No. Series");
        Opportunity.Insert();

        Opportunity.Validate("Campaign No.", "Campaign No.");
        Opportunity.Modify();
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

    procedure PersonContactNo(TableID: Integer; No: Code[20]): Code[20]
    var
        Contact: Record Contact;
        PersonContact: Record Contact;
    begin
        Contact.Get(ContactNo(TableID, No));
        if Contact.Type = Contact.Type::Company then begin
            PersonContact.SetRange(Type, PersonContact.Type::Person);
            PersonContact.SetRange("Company No.", Contact."Company No.");
            if PersonContact.FindFirst() then
                exit(PersonContact."No.");
        end;

        exit(Contact."No.");
    end;

    procedure CreateEvaluationData()
    begin
        InsertData(
          XOP100015, XAssemblingfurniture, XJO, '', PersonContactNo(DATABASE::Customer, '10000'),
          ContactNo(DATABASE::Customer, '10000'), XEXISTING, '', 19030104D, 2, 0, true, 19030126D, XOPP);
        InsertData(
          XOP100016, XAssemblingfurniture, XJO, '', PersonContactNo(DATABASE::Customer, '20000'),
          ContactNo(DATABASE::Customer, '20000'), XEXISTING, '', 19030104D, 2, 1, true, 19030121D, XOPP);
        InsertData(
          XOP100017, XAssemblingfurniture, XOF, '', PersonContactNo(DATABASE::Customer, '30000'),
          ContactNo(DATABASE::Customer, '30000'), XEXISTING, '', 19030106D, 2, 1, true, 19030120D, XOPP);
        InsertData(
          XOP100018, XFurnituretosalesdepartment, XJO, '', PersonContactNo(DATABASE::Customer, '50000'),
          ContactNo(DATABASE::Customer, '50000'), XNEW, '', 19030106D, 2, 0, true, 19030120D, XOPP);
        InsertData(
          XOP100019, XFurniturefortheconference, XJO, '', PersonContactNo(DATABASE::Customer, '10000'),
          ContactNo(DATABASE::Customer, '10000'), XEXISTING, '', 19030101D, 2, 1, true, 19030111D, XOPP);
        InsertData(
          XOP100022, XStoragefacilities, XBC, '', PersonContactNo(DATABASE::Customer, '10000'),
          ContactNo(DATABASE::Customer, '10000'), XEXISTING, '', 19030121D, 1, 1, false, 0D, XOPP);
        InsertData(
          XOP100023, XSwivelchair, XBC, '', PersonContactNo(DATABASE::Customer, '20000'),
          ContactNo(DATABASE::Customer, '20000'), XEXISTING, '', 19021111D, 1, 1, false, 0D, XOPP);
        InsertData(
          XOP100024, XTablelightingTxt, XHR, '', PersonContactNo(DATABASE::Customer, '30000'),
          ContactNo(DATABASE::Customer, '30000'), XEXISTING, '', 19021214D, 1, 1, false, 0D, XOPP);
        InsertData(
          XOP100025, XGuestchairsforthereception, XHR, '', PersonContactNo(DATABASE::Customer, '40000'),
          ContactNo(DATABASE::Customer, '40000'), XEXISTING, '', 19030124D, 1, 0, false, 0D, XOPP);
        InsertData(
          XOP100026, XStoragesystem, XHR, '', PersonContactNo(DATABASE::Customer, '50000'),
          ContactNo(DATABASE::Customer, '50000'), XEXISTING, '', 19021126D, 1, 2, false, 0D, XOPP);
        InsertData(
          XOP100027, XDesksfortheservicedep, XJO, '', PersonContactNo(DATABASE::Customer, '50000'),
          ContactNo(DATABASE::Customer, '50000'), XEXISTING, '', 19021101D, 0, 1, false, 0D, XOPP);
        InsertData(
          XOP100037, XConferencetable, XOF, '', PersonContactNo(DATABASE::Customer, '40000'),
          ContactNo(DATABASE::Customer, '40000'), XNEW, '', 19020926D, 3, 1, true, 19021016D, XOPP);
        InsertData(
          XOP100038, XNewofficesystem, XOF, '', PersonContactNo(DATABASE::Customer, '20000'),
          ContactNo(DATABASE::Customer, '20000'), XNEW, '', 19020922D, 3, 2, true, 19021003D, XOPP);
        InsertData(
          XOP100039, XCompletestoragesystem, XHR, '', PersonContactNo(DATABASE::Customer, '30000'),
          ContactNo(DATABASE::Customer, '30000'), XNEW, '', 19030105D, 3, 1, true, 19030116D, XOPP);
        InsertData(
          XOP100040, X30chairsblue, XBC, '', PersonContactNo(DATABASE::Customer, '40000'),
          ContactNo(DATABASE::Customer, '40000'), XEXISTING, '', 19030109D, 3, 2, true, 19030124D, XOPP);
    end;
}

