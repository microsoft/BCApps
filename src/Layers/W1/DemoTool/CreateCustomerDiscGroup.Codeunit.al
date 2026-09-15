codeunit 101340 "Create Customer Disc. Group"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(DemoDataSetup.RetailCode(), XRetail2);
        InsertData(XLARGEACC, XLargeaccount);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CustDiscGr: Record "Customer Discount Group";
        XRetail2: Label 'Retail';
        XLARGEACC: Label 'LARGE ACC';
        XLargeaccount: Label 'Large account';

    procedure InsertData("Customer Disc. Group": Code[10]; Description: Text[30])
    begin
        CustDiscGr.Init();
        CustDiscGr.Validate(Code, "Customer Disc. Group");
        CustDiscGr.Validate(Description, Description);
        CustDiscGr.Insert();
    end;
}

