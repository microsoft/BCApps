codeunit 101255 "Create VAT Statement Template"
{

    trigger OnRun()
    begin
        InsertData(XVAT, XVATStatement);
    end;

    var
        XVAT: Label 'VAT';
        XVATStatement: Label 'VAT Statement';

    procedure InsertData(Name: Code[10]; Description: Text[80])
    var
        "VAT Statement Template": Record "VAT Statement Template";
    begin
        "VAT Statement Template".Init();
        "VAT Statement Template".Validate(Name, Name);
        "VAT Statement Template".Validate(Description, Description);
        "VAT Statement Template".Insert(true);
    end;
}

