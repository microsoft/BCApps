codeunit 101611 "Create Misc. Article"
{

    trigger OnRun()
    begin
        InsertData(XCREDITCARD, XCreditCardlc);
        InsertData(XKEY, XKeytoCompany);
        InsertData(XCOMPUTER, XComputerlc);
        InsertData(XCAR, XCompanyCar);
    end;

    var
        "Misc. Article": Record "Misc. Article";
        XCREDITCARD: Label 'CREDITCARD';
        XCreditCardlc: Label 'Credit Card';
        XKEY: Label 'KEY';
        XKeytoCompany: Label 'Key to Company';
        XCOMPUTER: Label 'COMPUTER';
        XComputerlc: Label 'Computer';
        XCAR: Label 'CAR';
        XCompanyCar: Label 'Company Car';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        "Misc. Article".Code := Code;
        "Misc. Article".Description := Description;
        "Misc. Article".Insert();
    end;
}

