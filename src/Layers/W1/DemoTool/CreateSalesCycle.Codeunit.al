codeunit 101590 "Create Sales Cycle"
{

    trigger OnRun()
    begin
        InsertData(XEXLARGE, XExistingcustomerLargeacc, 0, false);
        InsertData(XEXSMALL, XExistingcustomerSmallacc, 1, false);
        InsertData(XFIRSTLARGE, XFirsttimeLargeaccount, 0, false);
        InsertData(XFIRSTSMALL, XFirsttimeSmallaccount, 1, false);
    end;

    var
        SalesCycle: Record "Sales Cycle";
        XEXLARGE: Label 'EX-LARGE';
        XExistingcustomerLargeacc: Label 'Existing customer - Large acc.';
        XEXSMALL: Label 'EX-SMALL';
        XExistingcustomerSmallacc: Label 'Existing customer - Small acc.';
        XFIRSTLARGE: Label 'FIRSTLARGE';
        XFirsttimeLargeaccount: Label 'First time - Large account';
        XFIRSTSMALL: Label 'FIRSTSMALL';
        XFirsttimeSmallaccount: Label 'First time - Small account';
        XEXISTING: Label 'EXISTING';
        XExistingcustomer: Label 'Existing customer';
        XNEW: Label 'NEW';
        XNewcustomer: Label 'New customer';

    procedure InsertData("Code": Code[10]; Description: Text[30]; "Probability Calculation": Option; Blocked: Boolean)
    begin
        SalesCycle.Init();
        SalesCycle.Validate(Code, Code);
        SalesCycle.Validate(Description, Description);
        SalesCycle.Validate("Probability Calculation", "Probability Calculation");
        SalesCycle.Validate(Blocked, Blocked);
        SalesCycle.Insert();
    end;

    procedure InsertMiniAppData()
    begin
        InsertData(XEXISTING, XExistingcustomer, 3, false);
        InsertData(XNEW, XNewcustomer, 2, false);
    end;
}

