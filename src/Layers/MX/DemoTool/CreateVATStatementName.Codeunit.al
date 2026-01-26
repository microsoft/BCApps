codeunit 101257 "Create VAT Statement Name"
{

    trigger OnRun()
    begin
        InsertData(XVAT, XDEFAULT, XDefaultStatement);
        InsertData(XVAT, XUNREAL, XUNREALStatement);
    end;

    var
        XVAT: Label 'VAT';
        XDEFAULT: Label 'DEFAULT';
        XDefaultStatement: Label 'Default Statement';
        XUNREAL: Label 'UNREAL.';
        XUNREALStatement: Label 'Unrealized VAT';

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
}

