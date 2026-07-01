codeunit 101556 "Create Contact Mailing Group"
{

    trigger OnRun()
    begin
        InsertData(XCT100002, XXCARD);
        InsertData(XCT200001, XXCARD);
        InsertData(XCT200002, XXCARD);
        InsertData(XCT200091, XXCARD);
        InsertData(XCT200094, XXCARD);
        InsertData(XCT200097, XXCARD);
        InsertData(XCT200101, XXCARD);
        InsertData(XCT200105, XXCARD);
        InsertData(XCT200107, XXCARD);
        InsertData(XCT200112, XXCARD);
        InsertData(XCT200116, XXCARD);
        InsertData(XCT200122, XXCARD);
        InsertData(XCT200127, XXCARD);
        InsertData(XCT200130, XXGIFT);
    end;

    var
        "Contact Mailing Group": Record "Contact Mailing Group";
        XCT100002: Label 'CT100002';
        XCT200001: Label 'CT200001';
        XCT200002: Label 'CT200002';
        XCT200091: Label 'CT200091';
        XCT200094: Label 'CT200094';
        XCT200097: Label 'CT200097';
        XCT200101: Label 'CT200101';
        XCT200105: Label 'CT200105';
        XCT200107: Label 'CT200107';
        XCT200112: Label 'CT200112';
        XCT200116: Label 'CT200116';
        XCT200122: Label 'CT200122';
        XCT200127: Label 'CT200127';
        XCT200130: Label 'CT200130';
        XXCARD: Label 'X-CARD';
        XXGIFT: Label 'X-GIFT';

    procedure InsertData("Contact No.": Code[20]; "Mailing Group Code": Code[10])
    begin
        "Contact Mailing Group".Init();
        "Contact Mailing Group".Validate("Contact No.", "Contact No.");
        "Contact Mailing Group".Validate("Mailing Group Code", "Mailing Group Code");
        "Contact Mailing Group".Insert();
    end;
}

