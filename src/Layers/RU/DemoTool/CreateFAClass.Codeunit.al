codeunit 101804 "Create FA Class"
{

    trigger OnRun()
    begin
        InsertData(XTANGIBLE, XTangibleFixedAssets);
        InsertData(XINTANGIBLE, XIntangibleFixedAssets);
        InsertData(XFE, XFEs);
        InsertData(XLEASNIG, XLeasingproperty);
    end;

    var
        "FA Class": Record "FA Class";
        XTANGIBLE: Label 'TANGIBLE';
        XTangibleFixedAssets: Label 'Tangible Fixed Assets';
        XINTANGIBLE: Label 'INTANGIBLE';
        XIntangibleFixedAssets: Label 'Intangible Fixed Assets';
        XFE: Label 'FE';
        XFEs: Label 'Expenses of future period';
        XLEASNIG: Label 'LEASING';
        XLeasingproperty: Label 'Leasing Property';

    procedure InsertData("Code": Code[10]; Name: Text[50])
    begin
        "FA Class".Init();
        "FA Class".Validate(Code, Code);
        "FA Class".Validate(Name, Name);
        "FA Class".Insert();
    end;
}

