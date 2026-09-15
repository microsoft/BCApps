codeunit 101583 "Create Team"
{

    trigger OnRun()
    begin
        InsertData(XADM, XAdministration);
        InsertData(XCANVAS, XCanvasteam);
        InsertData(XMARKETING, XMarketingGroup);
        InsertData(XSALE, XSales);
        InsertData(XSERVICE, XFieldService);
        InsertData(XSUPPORT, XProductsupport);
    end;

    var
        Team: Record Team;
        XADM: Label 'ADM';
        XAdministration: Label 'Administration';
        XCANVAS: Label 'CANVAS';
        XCanvasteam: Label 'Canvas team';
        XMARKETING: Label 'MARKETING';
        XMarketingGroup: Label 'Marketing Group';
        XSALE: Label 'SALE';
        XSales: Label 'Sales';
        XSERVICE: Label 'SERVICE';
        XFieldService: Label 'Field Service';
        XSUPPORT: Label 'SUPPORT';
        XProductsupport: Label 'Product support';

    procedure InsertData("Code": Code[10]; Name: Text[30])
    begin
        Team.Init();
        Team.Validate(Code, Code);
        Team.Validate(Name, Name);
        Team.Insert();
    end;
}

