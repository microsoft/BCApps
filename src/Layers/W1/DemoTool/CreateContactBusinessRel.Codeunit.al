codeunit 101554 "Create Contact Business Rel."
{

    trigger OnRun()
    begin
        InsertData(ContactNo(DATABASE::Customer, '40000'), XPRESS);
        InsertData(XCT100240, XPROS);
        InsertData(XCT100241, XJOB);
        InsertData(XCT100242, XJOB);
        InsertData(XCT100243, XACCOUNT);
        InsertData(XCT100244, XPROS);
        InsertData(XCT100245, XTRAVEL);
        InsertData(XCT100001, XLAW);
        InsertData(XCT100003, XPROS);
        InsertData(XCT100004, XPROS);
        InsertData(XCT100005, XPROS);
        InsertData(XCT100006, XLAW);
        InsertData(XCT100007, XPROS);
        InsertData(XCT100010, XPROS);
        InsertData(XCT100011, XJOB);
        InsertData(XCT100012, XPROS);
        InsertData(XCT100014, XLAW);
        InsertData(XCT100015, XPRESS);
        InsertData(XCT100016, XPROS);
        InsertData(XCT100017, XPROS);
        InsertData(XCT100019, XPROS);
    end;

    var
        "Contact Business Relation": Record "Contact Business Relation";
        XPRESS: Label 'PRESS';
        XCT100240: Label 'CT100240';
        XCT100241: Label 'CT100241';
        XCT100242: Label 'CT100242';
        XCT100243: Label 'CT100243';
        XCT100244: Label 'CT100244';
        XCT100245: Label 'CT100245';
        XCT100001: Label 'CT100001';
        XCT100003: Label 'CT100003';
        XCT100004: Label 'CT100004';
        XCT100005: Label 'CT100005';
        XCT100006: Label 'CT100006';
        XCT100007: Label 'CT100007';
        XCT100010: Label 'CT100010';
        XCT100011: Label 'CT100011';
        XCT100012: Label 'CT100012';
        XCT100014: Label 'CT100014';
        XCT100015: Label 'CT100015';
        XCT100016: Label 'CT100016';
        XCT100017: Label 'CT100017';
        XCT100019: Label 'CT100019';
        XPROS: Label 'PROS';
        XACCOUNT: Label 'ACCOUNT';
        XJOB: Label 'JOB';
        XTRAVEL: Label 'TRAVEL';
        XLAW: Label 'LAW';

    procedure InsertData("Contact No.": Code[20]; "Business Relation Code": Code[10])
    begin
        "Contact Business Relation".Init();
        "Contact Business Relation".Validate("Contact No.", "Contact No.");
        "Contact Business Relation".Validate("Business Relation Code", "Business Relation Code");
        "Contact Business Relation".Insert();
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

