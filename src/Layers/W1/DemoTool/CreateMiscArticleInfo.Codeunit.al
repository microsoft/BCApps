codeunit 101612 "Create Misc. Article Info"
{

    trigger OnRun()
    begin
        InsertData(XEH, XCOMPUTER, XDesktopComputer, '123456');
        InsertData(XEH, XKEY, XKeytoMainOffice, '');

        InsertData(XOF, XCOMPUTER, XDesktopComputer, '789012');
        InsertData(XOF, XCREDITCARD, XVISA, '');
        InsertData(XOF, XCREDITCARD, XMasterCard, '');
        InsertData(XOF, XCAR, XCarlc, '45ACD 134');
        InsertData(XOF, XKEY, XKeytoMainOffice, '');

        InsertData(XLT, XCOMPUTER, XDesktopComputer, '123456');
        InsertData(XLT, XCAR, XCarlc, '45JKL 245');
        InsertData(XLT, XKEY, XKeytoMainOffice, '');

        InsertData(XJO, XCOMPUTER, XDesktopComputer, '146116');
        InsertData(XJO, XCOMPUTER, 'Notebook Computer', '987977');
        InsertData(XJO, XCREDITCARD, XVISA, '');
        InsertData(XJO, XCAR, XCarlc, '87NGI 123');
        InsertData(XJO, XKEY, XKeytoMainOffice, '');

        InsertData(XRB, XCOMPUTER, XDesktopComputer, '355468');
        InsertData(XRB, XCREDITCARD, 'VISA', '');
        InsertData(XRB, XCAR, XCarlc, '67APQ 123');
        InsertData(XRB, XKEY, XKeytoMainOffice, '');

        InsertData(XMH, XCOMPUTER, XDesktopComputer, '55467');
        InsertData(XMH, XCAR, XCarlc, '67APQ 124');
        InsertData(XMH, XKEY, XKeytoProductionDepartment, '');

        InsertData(XTD, XCOMPUTER, XDesktopComputer, '0454567');
        InsertData(XTD, XCAR, XCarlc, '67APQ 125');
        InsertData(XTD, XKEY, XKeytoProductionDepartment, '');
    end;

    var
        "Misc. Article Information": Record "Misc. Article Information";
        "Line No.": Integer;
        XEH: Label 'EH';
        XOF: Label 'OF';
        XLT: Label 'LT';
        XJO: Label 'JO';
        XRB: Label 'RB';
        XCOMPUTER: Label 'COMPUTER';
        XTD: Label 'TD';
        XMH: Label 'MH';
        XDesktopComputer: Label 'Desktop Computer';
        XKEY: Label 'KEY';
        XKeytoMainOffice: Label 'Key to Main Office';
        XCREDITCARD: Label 'CREDITCARD';
        XVISA: Label 'VISA';
        XMasterCard: Label 'MasterCard';
        XCAR: Label 'CAR';
        XCarlc: Label 'Car';
        XKeytoProductionDepartment: Label 'Key to Production Department';

    procedure InsertData("Employee No.": Code[20]; "Misc. Article Code": Code[10]; Description: Text[30]; "Serial No.": Text[30])
    begin
        "Misc. Article Information"."Employee No." := "Employee No.";
        "Misc. Article Information"."Misc. Article Code" := "Misc. Article Code";
        if "Line No." = 0 then
            "Line No." := 1
        else
            "Line No." := "Line No." + 1;
        "Misc. Article Information"."Line No." := "Line No.";
        "Misc. Article Information".Description := Description;
        "Misc. Article Information"."Serial No." := "Serial No.";
        "Misc. Article Information".Insert();
    end;
}

