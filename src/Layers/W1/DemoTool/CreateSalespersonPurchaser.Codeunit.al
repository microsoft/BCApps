codeunit 101013 "Create Salesperson/Purchaser"
{

    trigger OnRun()
    begin
        InsertData(XEH, XEsterHenderson, 0);
        InsertData(XOF, XOtisFalls, 5);
        InsertData(XLT, XLinaTownsend, 5);
        InsertData(XJO, XJimOlive, 5);
        InsertData(XRB, XRobinBettencourt, 0);
        InsertData(XBC, XBenjaminChiu, 0);
        InsertData(XHR, XHelenaRay, 0);
    end;

    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        XEH: Label 'EH';
        XEsterHenderson: Label 'Ester Henderson';
        XOF: Label 'OF';
        XOtisFalls: Label 'Otis Falls';
        XLT: Label 'LT';
        XLinaTownsend: Label 'Lina Townsend';
        XJO: Label 'JO';
        XJimOlive: Label 'Jim Olive';
        XRB: Label 'RB';
        XRobinBettencourt: Label 'Robin Bettencourt';
        XBC: Label 'BC';
        XBenjaminChiu: Label 'Benjamin Chiu';
        XHR: Label 'HR';
        XHelenaRay: Label 'Helena Ray';
        EmailDomainTok: Label '@contoso.com', Locked = true;

    procedure InsertData("Code": Code[20]; Name: Text[50]; "Commission %": Decimal)
    var
        ImagePath: Text;
    begin
        SalespersonPurchaser.Init();
        SalespersonPurchaser.Validate(Code, Code);
        SalespersonPurchaser.Validate(Name, Name);
        SalespersonPurchaser.Validate("Commission %", "Commission %");
        SalespersonPurchaser.Validate("E-Mail", Code + EmailDomainTok);
        ImagePath := StrSubstNo('Images\Person\OnPrem\%1.jpg', Name);
        if Exists(ImagePath) then
            SalespersonPurchaser.Image.ImportFile(ImagePath, Name);
        SalespersonPurchaser.Insert();
    end;

    procedure CreateEvaluationData()
    begin
        InsertEvaluationData(XEH, XEsterHenderson, 0);
        InsertEvaluationData(XOF, XOtisFalls, 5);
        InsertEvaluationData(XLT, XLinaTownsend, 5);
        InsertEvaluationData(XJO, XJimOlive, 5);
        InsertEvaluationData(XRB, XRobinBettencourt, 0);
        InsertEvaluationData(XBC, XBenjaminChiu, 0);
        InsertEvaluationData(XHR, XHelenaRay, 0);
    end;

    local procedure InsertEvaluationData("Code": Code[20]; Name: Text[50]; "Commission %": Decimal)
    var
        ImagePath: Text;
    begin
        SalespersonPurchaser.Init();
        SalespersonPurchaser.Validate(Code, Code);
        SalespersonPurchaser.Validate(Name, Name);
        SalespersonPurchaser.Validate("Commission %", "Commission %");
        SalespersonPurchaser.Validate("E-Mail", Code + EmailDomainTok);
        ImagePath := StrSubstNo('Images\Person\Saas\%1.jpg', Name);
        if Exists(ImagePath) then
            SalespersonPurchaser.Image.ImportFile(ImagePath, Name);
        SalespersonPurchaser.Insert();
    end;
}

