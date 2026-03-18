codeunit 101558 "Create Contact Industry Group"
{

    trigger OnRun()
    begin
        InsertData(ContactNo(DATABASE::Customer, '01121212'), XWHOLE);
        InsertData(ContactNo(DATABASE::Customer, '01445544'), XWHOLE);
        InsertData(ContactNo(DATABASE::Customer, '01454545'), XRET);
        InsertData(ContactNo(DATABASE::Customer, '01454545'), XWHOLE);
        InsertData(ContactNo(DATABASE::Customer, '31505050'), XRET);
        InsertData(ContactNo(DATABASE::Customer, '31669966'), XRET);
        InsertData(ContactNo(DATABASE::Vendor, '01254796'), XMAN);
        InsertData(ContactNo(DATABASE::Vendor, '01587796'), XMAN);
        InsertData(ContactNo(DATABASE::Vendor, '01863656'), XMAN);
        InsertData(ContactNo(DATABASE::Vendor, '31147896'), XMAN);
        InsertData(ContactNo(DATABASE::Vendor, '31568974'), XMAN);
        InsertData(XCT100001, XLAWYER);
        InsertData(XCT100003, XRET);
        InsertData(XCT100004, XWHOLE);
        InsertData(XCT100005, XWHOLE);
        InsertData(XCT100006, XLAWYER);
        InsertData(XCT100007, XRET);
        InsertData(XCT100008, XPRESS);
        InsertData(XCT100010, XWHOLE);
        InsertData(XCT100011, XADVERT);
        InsertData(XCT100012, XWHOLE);
        InsertData(XCT100013, XRET);
        InsertData(XCT100014, XLAWYER);
        InsertData(XCT100016, XRET);
        InsertData(XCT100017, XWHOLE);
        InsertData(XCT100018, XPRESS);
        InsertData(XCT100019, XWHOLE);
    end;

    var
        "Contact Industry Group": Record "Contact Industry Group";
        XCT100001: Label 'CT100001';
        XCT100003: Label 'CT100003';
        XCT100004: Label 'CT100004';
        XCT100005: Label 'CT100005';
        XCT100006: Label 'CT100006';
        XCT100007: Label 'CT100007';
        XCT100008: Label 'CT100008';
        XCT100010: Label 'CT100010';
        XCT100011: Label 'CT100011';
        XCT100012: Label 'CT100012';
        XCT100013: Label 'CT100013';
        XCT100014: Label 'CT100014';
        XCT100016: Label 'CT100016';
        XCT100017: Label 'CT100017';
        XCT100018: Label 'CT100018';
        XCT100019: Label 'CT100019';
        XLAWYER: Label 'LAWYER';
        XWHOLE: Label 'WHOLE';
        XRET: Label 'RET';
        XPRESS: Label 'PRESS';
        XADVERT: Label 'ADVERT';
        XMAN: Label 'MAN';

    procedure InsertData("Contact No.": Code[20]; "Industry Group Code": Code[10])
    begin
        "Contact Industry Group".Init();
        "Contact Industry Group".Validate("Contact No.", "Contact No.");
        "Contact Industry Group".Validate("Industry Group Code", "Industry Group Code");
        "Contact Industry Group".Insert();
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

