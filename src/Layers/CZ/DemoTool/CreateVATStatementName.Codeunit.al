codeunit 101257 "Create VAT Statement Name"
{

    trigger OnRun()
    begin
        InsertData(XVAT, XDEFAULT, XDefaultStatement);
        InsertData(XVAT, XVAT19, XVAT19Txt); // NAVCZ
    end;

    var
        XVAT: Label 'VAT';
        XDEFAULT: Label 'DEFAULT';
        XDefaultStatement: Label 'Default Statement';
        XVAT19: Label 'VAT-19';
        XVAT19Txt: Label 'VAT Statement valid from 1.1.2015 (type 19)';

    procedure InsertData("Statement Template Name": Code[10]; Name: Code[10]; Description: Text[50])
    var
        "VAT Statement Name": Record "VAT Statement Name";
    begin
        "VAT Statement Name".Init();
        "VAT Statement Name".Validate("Statement Template Name", "Statement Template Name");
        "VAT Statement Name".Validate(Name, Name);
        "VAT Statement Name".Validate(Description, Description);
        "VAT Statement Name".Insert();
    end;

    procedure GetVAT(VATCode: Text): Code[10]
    begin
        case UpperCase(VATCode) of
            'XVAT':
                exit(XVAT);
            'XVAT19':
                exit(XVAT19);
            else
                Error('Unknown VAT Statement Code %1.', VATCode);
        end;
    end;
}
