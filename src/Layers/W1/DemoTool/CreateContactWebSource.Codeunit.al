codeunit 101560 "Create Contact Web Source"
{

    trigger OnRun()
    begin
        InsertData(ContactNo(DATABASE::Customer, '30000'), XUSSTOCK, XJohnHaddockInsurance);
        InsertData(ContactNo(DATABASE::Customer, '30000'), 'CONTOSO', XJohnHaddockInsurance);
        InsertData(ContactNo(DATABASE::Customer, '40000'), XUSSTOCK, XDeerfieldGraphics);
        InsertData(ContactNo(DATABASE::Customer, '40000'), 'CONTOSO', XDeerfieldGraphics);
        InsertData(ContactNo(DATABASE::Customer, '50000'), 'LUCERNE', XGuildfordWaterDepartment);
        InsertData(ContactNo(DATABASE::Customer, '01445544'), 'FABRIKAM', 'Progressive Home Furnishings');
        InsertData(ContactNo(DATABASE::Customer, '01445544'), XUSSTOCK, 'Progressive Home Furnishings');
        InsertData(ContactNo(DATABASE::Customer, '01454545'), XUSSTOCK, 'New Concepts Furniture');
        InsertData(ContactNo(DATABASE::Customer, '01454545'), 'CONTOSO', 'New Concepts Furniture');
        InsertData(ContactNo(DATABASE::Customer, '31505050'), 'FABRIKAM', 'Woonboulevard Kuitenbrouwer');
        InsertData(ContactNo(DATABASE::Customer, '31505050'), XUSSTOCK, 'Woonboulevard Kuitenbrouwer');
        InsertData(ContactNo(DATABASE::Customer, '31669966'), 'ADATUM', 'Meersen Meubelen');
        InsertData(ContactNo(DATABASE::Customer, '31669966'), 'CONTOSO', 'Meersen Meubelen');
        InsertData(ContactNo(DATABASE::Customer, '32124578'), 'ADATUM', 'Nieuwe Zandpoort NV');
        InsertData(ContactNo(DATABASE::Customer, '32124578'), XUSSTOCK, 'Nieuwe Zandpoort NV');
        InsertData(ContactNo(DATABASE::Vendor, '01254796'), 'FABRIKAM', 'Progressive Home Furnishings');
        InsertData(ContactNo(DATABASE::Vendor, '01254796'), XUSSTOCK, 'Progressive Home Furnishings');
        InsertData(ContactNo(DATABASE::Vendor, '01587796'), 'ADATUM', 'Custom Metals Incorporated');
        InsertData(ContactNo(DATABASE::Vendor, '01587796'), XUSSTOCK, 'Custom Metals Incorporated');
        InsertData(ContactNo(DATABASE::Vendor, '01863656'), 'LUCERNE', 'American Wood Exports');
        InsertData(ContactNo(DATABASE::Vendor, '01863656'), XUSSTOCK, 'American Wood Exports');
        InsertData(ContactNo(DATABASE::Vendor, '31147896'), 'ADATUM', 'Houtindustrie Bruynsma');
        InsertData(ContactNo(DATABASE::Vendor, '31147896'), 'CONTOSO', 'Houtindustrie Bruynsma');
        InsertData(ContactNo(DATABASE::Vendor, '31568974'), 'LUCERNE', 'Koekamp Leerindustrie');
        InsertData(ContactNo(DATABASE::Vendor, '31568974'), XUSSTOCK, 'Koekamp Leerindustrie');
        InsertData(XCT100001, 'LUCERNE', 'Eco Office');
        InsertData(XCT100001, 'CONTOSO', 'Eco Office');
        InsertData(XCT100012, 'FABRIKAM', 'eAmericonda');
        InsertData(XCT100012, XUSSTOCK, 'eAmericonda');
        InsertData(XCT100014, 'ADATUM', 'Lynda McNeal');
        InsertData(XCT100014, 'CONTOSO', 'Lynda McNeal');
        InsertData(XCT100015, 'FABRIKAM', 'Triplelight Studio');
        InsertData(XCT100015, XUSSTOCK, 'Triplelight Studio');
        InsertData(XCT100015, 'CONTOSO', 'Triplelight Studio');
        InsertData(XCT100019, 'ADATUM', 'WoodImex');
        InsertData(XCT100019, XUSSTOCK, 'WoodImex');
    end;

    var
        "Contact Web Source": Record "Contact Web Source";
        XUSSTOCK: Label 'US-STOCK';
        XJohnHaddockInsurance: Label 'John Haddock Insurance';
        XDeerfieldGraphics: Label 'Deerfield Graphics';
        XGuildfordWaterDepartment: Label 'Guildford Water Department';
        XCT100001: Label 'CT100001';
        XCT100012: Label 'CT100012';
        XCT100014: Label 'CT100014';
        XCT100015: Label 'CT100015';
        XCT100019: Label 'CT100019';

    procedure InsertData("Contact  No.": Code[20]; "Web Source Code": Code[10]; "Search Word": Text[30])
    begin
        "Contact Web Source".Init();
        "Contact Web Source".Validate("Contact No.", "Contact  No.");
        "Contact Web Source".Validate("Web Source Code", "Web Source Code");
        "Contact Web Source".Validate("Search Word", "Search Word");
        "Contact Web Source".Insert();
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

