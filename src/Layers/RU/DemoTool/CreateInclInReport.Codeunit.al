codeunit 163486 "Create Incl. In Report"
{

    trigger OnRun()
    begin
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", XPAYSICKHOMEDAY, 1);
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", XPAYSICKHOMEAMT, 1);
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", XPAYSICKDAY, 1);
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", XPAYSICKAMT, 1);
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", XPAYSICKCHILDDAY, 1);
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", XPAYSICKCHILDAMT, 1);
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", XPAYSICKPREGDAY, 2);
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", XPAYSICKPREGAMT, 2);
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", StrSubstNo(XVACCHILD, 1), 3);
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", XALLOWBIRTH, 4);
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", XALLOWBURIAL, 5);
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", XALLOWEARLYPREG, 7);
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", XALLOWADOP, 8);
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", XPAYSICKWORKDAY, 9);
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", XPAYSICKWORKAMT, 9);
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", StrSubstNo(XVACCHILD, 2), 11);
        InsertInclInRep(InclInReport."Report Code"::"FSI Rep", StrSubstNo(XVACCHILD, 3), 11);
    end;

    var
        InclInReport: Record "Including In Report";
        XPAYSICKHOMEDAY: Label 'PAY SICK HOME DAY';
        XPAYSICKHOMEAMT: Label 'PAY SICK HOME AMT';
        XPAYSICKDAY: Label 'PAY SICK DAY';
        XPAYSICKAMT: Label 'PAY SICK AMT';
        XPAYSICKCHILDDAY: Label 'PAY SICK CHILD DAY';
        XPAYSICKCHILDAMT: Label 'PAY SICK CHILD AMT';
        XPAYSICKPREGDAY: Label 'PAY SICK PREG DAY';
        XPAYSICKPREGAMT: Label 'PAY SICK PREG AMT';
        XVACCHILD: Label 'VAC CHILD%1  1,5';
        XALLOWBIRTH: Label 'ALLOWANCE BIRTH';
        XALLOWBURIAL: Label 'ALLOWANCE BURIAL';
        XALLOWEARLYPREG: Label 'ALLOWANCE EARLY PREG';
        XALLOWADOP: Label 'ALLOWANCE ADOPTION';
        XPAYSICKWORKDAY: Label 'PAY SICK WORK DAY';
        XPAYSICKWORKAMT: Label 'PAY SICK WORK AMT';

    procedure InsertInclInRep(ReportCode: Integer; ElementCode: Code[20]; ColumnNo: Integer)
    begin
        InclInReport.Init();
        InclInReport."Element Code" := ElementCode;
        InclInReport."Report Code" := ReportCode;
        case ColumnNo of
            1:
                InclInReport.Column1 := true;
            2:
                InclInReport.Column2 := true;
            3:
                InclInReport.Column3 := true;
            4:
                InclInReport.Column4 := true;
            5:
                InclInReport.Column5 := true;
            6:
                InclInReport.Column6 := true;
            7:
                InclInReport.Column7 := true;
            8:
                InclInReport.Column8 := true;
            9:
                InclInReport.Column9 := true;
            10:
                InclInReport.Column10 := true;
            11:
                InclInReport.Column11 := true;
            12:
                InclInReport.Column12 := true;
            13:
                InclInReport.Column13 := true;
            14:
                InclInReport.Column14 := true;
            15:
                InclInReport.Column15 := true;
            16:
                InclInReport.Column16 := true;
            17:
                InclInReport.Column17 := true;
            18:
                InclInReport.Column18 := true;
            19:
                InclInReport.Column19 := true;
            20:
                InclInReport.Column20 := true;
        end;
        if InclInReport.Insert() then;
    end;
}

