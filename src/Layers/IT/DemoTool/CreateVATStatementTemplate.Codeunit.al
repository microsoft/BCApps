codeunit 101255 "Create VAT Statement Template"
{

    trigger OnRun()
    begin
        InsertData(XVAT, XVATStatement, PAGE::"VAT Statement");
        InsertData(XVATCOMM, XVATCommunication, PAGE::"Annual VAT Communication");
    end;

    var
        XVAT: Label 'VAT';
        XVATStatement: Label 'VAT Statement';
        XVATCOMM: Label 'VAT COMM';
        XVATCommunication: Label 'Annual VAT Communication';

    procedure InsertData(Name: Code[10]; Description: Text[80]; PageID: Integer)
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        VATStatementTemplate.Init();
        VATStatementTemplate.Validate(Name, Name);
        VATStatementTemplate.Validate(Description, Description);
        VATStatementTemplate.Validate("Page ID", PageID);
        VATStatementTemplate.Insert(true);
    end;
}

