codeunit 101551 "Create Contact Alt. Addr."
{

    trigger OnRun()
    begin
        InsertData(XCT100121, XTEMPSALES, 'WoodImex Ltd',
          '535 Willenhall Road', '', 'London', 'GB-WC1 3DG', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT100132, XHOLIDAY, '',
          '22, Manor Road', '', 'Cheltenham', 'GB-GL78 5TT', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT100148, XFAIR, 'G.W. Plantonic',
          'Unit 3b 113-115', 'Codicote Road', 'Borehamwood', 'GB-WD6 9HY', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT100152, XBUSINESS, '',
          'Omega Office Furniture', '17, Old Leeds Road', 'Leicester', 'GB-LE16 7YH', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT100156, XTEMPSALES, 'The Cannon Group PLC',
          'Tudor House 913a', 'Uppingham Road Bushby', 'Ashford', 'GB-TN27 6YD', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT100158, XBUSINESS, 'GDH Office Interiors Ltd',
          '11a, Orchard Road', '', 'London', 'GB-W2 8HG', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT100162, XRENOVATION, 'Service Electronics Ltd.',
          '16 Wainman Road', '', 'Swansea', 'GB-SA1 2HS', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT100191, XWORKSHOP, 'Harbenwood Ltd',
          '2, Mill Lane Felthorpe', '', 'Colombia', 'US-SC 27136', 'US', '', '', '', '',
          '', '', '');
        InsertData(XCT100194, XOFFICE, 'Eco Office Inc.',
          'Waughton Steading', '', 'New York', 'US-NY 11010', 'US', '', '', '', '',
          '', '', '');
        InsertData(XCT100204, XWORKSHOP, 'Harrijohn Associates',
          '30, Woolpack Lane', '', 'Macclesfield', 'GB-SK21 5DL', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT100210, XTEMPOFFICE, 'The Cannon Group PLC',
          'Whitwick Business Park', '', 'Brixham', 'GB-TQ17 8HB', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT100215, XFAIR, 'Galaxy Office Seating',
          'Hotchkiss Way', 'Binley Ind Est', 'West End Lane', 'GB-WC1 2GS', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT100218, XBUSINESS, 'Treawil Business Equipment Ltd',
          '106, Chapel Lane Sands', '', 'Ripon', 'GB-HG1 7YW', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT100229, XRENOVATION, 'London Postmaster',
          'Leofrick Business Park', '', 'London', 'GB-N12 5XY', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT200009, XHOME, '',
          '11a, Seedorf', '', 'Waalwijk', 'NL-5132 EE', 'NL', '', '', '', '',
          '', '', '');
        InsertData(XCT200011, XPRIVATE, 'Triplelight Studio',
          'Wroslyn Road', 'Freeland', 'West End Lane', 'GB-WC1 2GS', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT200016, XEXHIBITION, 'Sombercourt O.F.D',
          'The Galleries', 'Queen Street', 'Chicago', 'US-IL 61236', 'US', '', '', '', '',
          '', '', '');
        InsertData(XCT200016, XSUMMER, 'eAmericonda',
          '68 Grange Road', '', 'Chicago', 'US-IL 61236', 'US', '', '', '', '',
          '', '', '');
        InsertData(XCT200027, XBUSINESS, 'MGB Office Interiors',
          'Sevenoaks Kent', 'TN14 5EL', 'Kings Lynn', 'GB-PE23 5IK', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT200031, XFAIR, 'HGP Commercial Interiors',
          '9, Liston Court', '', 'London', 'GB-WC1 3DG', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT200036, XHOME, '',
          '7, Ravenstone Road', '', 'West End Lane', 'GB-WC1 2GS', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT200052, XCLOSED, 'Lynda McNeal, Inc',
          'Arbour Lane', '', 'Birmingham', 'US-AL 35242', 'US', '', '', '', '',
          '', '', '');
        InsertData(XCT200055, XEXHIBITION, 'Boybridge England Ltd',
          '10, Great Titchfield Street', '', 'Plymouth', 'GB-PL14 5GB', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT200067, XHOLIDAY, '',
          '', '', '', '', '', '', '', '', '',
          '', '', '');
        InsertData(XCT200074, XHOLIDAY, 'Eco Office Inc.',
          'Courteney Road', '', 'Edinburgh', 'GB-EH16 8JS', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT200079, XLONDON, 'John Haddock Insurance Co.',
          '30 Shepreth Road', 'Barrington', 'London', 'GB-N16 34Z', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT200080, XBRISTOL, 'John Haddock Insurance Co.',
          'Falkland Close Canley', '', XBRISTOL, 'GB-BS3 6KL', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT200080, XHOME, '',
          '715, North Circular Road', '', 'Dudley', 'GB-DY5 4DJ', 'GB', '', '', '', '',
          '', '', '');
        InsertData(XCT200092, XHOME, '',
          '1a Liverpool Grove', '', 'Chicago', 'US-IL 61236', 'US', '', '', '', '',
          '', '', '');
        InsertData(XCT200095, XHOLIDAY, '',
          '', '', '', '', 'FR', '', '', '', '',
          '', '', '');
        InsertData(XCT200121, XHOME, '',
          'Little Swailes', '', 'New York', 'US-NY 11010', 'US', '', '', '', '',
          '', '', '');
    end;

    var
        "Contact Alt. Address": Record "Contact Alt. Address";
        XCT100121: Label 'CT100121';
        XCT100132: Label 'CT100132';
        XCT100148: Label 'CT100148';
        XCT100152: Label 'CT100152';
        XCT100156: Label 'CT100156';
        XCT100158: Label 'CT100158';
        XCT100162: Label 'CT100162';
        XCT100191: Label 'CT100191';
        XCT100194: Label 'CT100194';
        XCT100204: Label 'CT100204';
        XCT100210: Label 'CT100210';
        XCT100215: Label 'CT100215';
        XCT100218: Label 'CT100218';
        XCT100229: Label 'CT100229';
        XCT200009: Label 'CT200009';
        XCT200011: Label 'CT200011';
        XCT200016: Label 'CT200016';
        XCT200027: Label 'CT200027';
        XCT200031: Label 'CT200031';
        XCT200036: Label 'CT200036';
        XCT200052: Label 'CT200052';
        XCT200055: Label 'CT200055';
        XCT200067: Label 'CT200067';
        XCT200074: Label 'CT200074';
        XCT200079: Label 'CT200079';
        XCT200080: Label 'CT200080';
        XCT200092: Label 'CT200092';
        XCT200095: Label 'CT200095';
        XCT200121: Label 'CT200121';
        XBRISTOL: Label 'BRISTOL';
        XBUSINESS: Label 'BUSINESS';
        XCLOSED: Label 'CLOSED';
        XEXHIBITION: Label 'EXHIBITION';
        XFAIR: Label 'FAIR';
        XHOLIDAY: Label 'HOLIDAY';
        XHOME: Label 'HOME';
        XLONDON: Label 'LONDON';
        XOFFICE: Label 'OFFICE';
        XPRIVATE: Label 'PRIVATE';
        XRENOVATION: Label 'RENOVATION';
        XSUMMER: Label 'SUMMER';
        XTEMPOFFICE: Label 'TEMPOFFICE';
        XTEMPSALES: Label 'TEMPSALES';
        XWORKSHOP: Label 'WORKSHOP';

    procedure InsertData("Contact  No.": Code[20]; "Code": Code[10]; Name: Text[30]; Address: Text[30]; "Address 2": Text[30]; City: Text[30]; "Post Code": Code[20]; "Country Code": Code[10]; "Phone No.": Text[30]; "Extension No.": Text[30]; "Mobile Phone No.": Text[30]; Email: Text[80]; "Home Page": Text[80]; "Fax No.": Text[30]; "Telex Answer Back": Text[20])
    var
        CreatePostCode: Codeunit "Create Post Code";
    begin
        "Contact Alt. Address".Init();
        "Contact Alt. Address".Validate("Contact No.", "Contact  No.");
        "Contact Alt. Address".Validate(Code, Code);
        "Contact Alt. Address".Validate("Company Name", Name);
        "Contact Alt. Address".Validate(Address, Address);
        "Contact Alt. Address".Validate("Address 2", "Address 2");
        "Contact Alt. Address".Validate("Country/Region Code", "Country Code");
        "Contact Alt. Address".City := City;
        "Contact Alt. Address"."Post Code" := CreatePostCode.FindPostCode("Post Code");
        "Contact Alt. Address".City := CreatePostCode.FindCity("Post Code");
        "Contact Alt. Address".Validate(
          County, CreatePostCode.GetCounty("Contact Alt. Address"."Post Code", "Contact Alt. Address".City));
        "Contact Alt. Address".Validate("Phone No.", "Phone No.");
        "Contact Alt. Address".Validate("Extension No.", "Extension No.");
        "Contact Alt. Address".Validate("Mobile Phone No.", "Mobile Phone No.");
        "Contact Alt. Address".Validate("E-Mail", Email);
        "Contact Alt. Address".Validate("Home Page", "Home Page");
        "Contact Alt. Address".Validate("Fax No.", "Fax No.");
        "Contact Alt. Address".Validate("Telex Answer Back", "Telex Answer Back");
        "Contact Alt. Address".Insert();
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
}

