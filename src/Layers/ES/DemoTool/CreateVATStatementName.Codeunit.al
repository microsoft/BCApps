codeunit 101257 "Create VAT Statement Name"
{

    trigger OnRun()
    begin
        // InsertData(XVAT,XDEFAULT,XDefaultStatement);
        InsertData(XVAT, XDEFAULT, XDefaultStatement, 0);
        InsertData(XVAT, XSTMT320, X320TelematicStatement, 1);
        InsertData(XVAT, XSTMT392, X392XMLTelematicStatement, 1); // XMLVATDecl
    end;

    var
        XVAT: Label 'VAT';
        XDEFAULT: Label 'DEFAULT';
        XDefaultStatement: Label 'Default Statement';
        XSTMT320: Label 'Stmt. 320';
        X320TelematicStatement: Label '320 Telematic Statement';
        XSTMT392: Label 'Stmt. 392';
        X392XMLTelematicStatement: Label '392 XML Telematic Statement';

    procedure InsertData("Statement Template Name": Code[10]; Name: Code[10]; Description: Text[50]; "Template Type": Option)
    var
        "VAT Statement Name": Record "VAT Statement Name";
    begin
        "VAT Statement Name".Init();
        "VAT Statement Name".Validate("Statement Template Name", "Statement Template Name");
        "VAT Statement Name".Validate(Name, Name);
        "VAT Statement Name".Validate(Description, Description);
        "VAT Statement Name".Validate("Template Type", "Template Type");
        "VAT Statement Name".Insert();
    end;
}

