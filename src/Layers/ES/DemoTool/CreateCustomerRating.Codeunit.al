codeunit 161008 "Create Customer Rating"
{

    trigger OnRun()
    begin
        InsertData(XWWBEUR, '', '10000', 80);
        InsertData(XWWBEUR, '', '20000', 70);
        InsertData(XWWBEUR, '', '30000', 65);
        InsertData(XWWBEUR, '', '40000', 90);
        InsertData(XWWBEUR, '', '50000', 75);

        InsertData(XNBL, '', '10000', 82);
        InsertData(XNBL, '', '20000', 75);
        InsertData(XNBL, '', '30000', 85);
        InsertData(XNBL, '', '40000', 91);
        InsertData(XNBL, '', '50000', 90);
    end;

    var
        "Customer Rating": Record "Customer Rating";
        XNBL: Label 'NBL';
        XWWBEUR: Label 'WWB-EUR';

    procedure InsertData("Code": Code[20]; "Currency Code": Code[10]; "Customer No.": Code[20]; "Risk Percentage": Decimal)
    begin
        "Customer Rating".Init();
        "Customer Rating".Validate(Code, Code);
        "Customer Rating".Validate("Currency Code", "Currency Code");
        "Customer Rating".Validate("Customer No.", "Customer No.");
        "Customer Rating".Validate("Risk Percentage", "Risk Percentage");
        "Customer Rating".Insert();
    end;
}

