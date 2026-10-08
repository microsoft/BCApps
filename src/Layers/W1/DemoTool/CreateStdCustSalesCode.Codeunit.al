codeunit 101045 "Create Std. Cust. Sales Code"
{

    trigger OnRun()
    begin
        InsertData('20000', XOFFICE);
        InsertData('44756404', XLAMPS);
    end;

    var
        StdCustSalesCode: Record "Standard Customer Sales Code";
        XOFFICE: Label 'OFFICE';
        XLAMPS: Label 'LAMPS';

    procedure InsertData(CustNo: Code[20]; "Code": Code[10])
    begin
        StdCustSalesCode.Init();
        StdCustSalesCode.Validate("Customer No.", CustNo);
        StdCustSalesCode.Validate(Code, Code);
        StdCustSalesCode.Insert();
    end;
}

