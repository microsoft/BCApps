codeunit 101043 "Create Std. Sales Code"
{

    trigger OnRun()
    begin
        InsertData(XLAMPS, XStandardlamporder);
        InsertData(XOFFICE, XBasicofficepackage);
    end;

    var
        StdSalesCode: Record "Standard Sales Code";
        XLAMPS: Label 'LAMPS';
        XStandardlamporder: Label 'Standard lamp order';
        XOFFICE: Label 'OFFICE';
        XBasicofficepackage: Label 'Basic office package';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    begin
        StdSalesCode.Init();
        StdSalesCode.Validate(Code, Code);
        StdSalesCode.Validate(Description, Description);
        StdSalesCode.Insert();
    end;
}

