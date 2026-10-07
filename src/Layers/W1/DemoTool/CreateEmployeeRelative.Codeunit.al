codeunit 101604 "Create Employee Relative"
{

    trigger OnRun()
    begin
        InsertData(XEH, XHUSBAND, XJames, CA.AdjustDate(19020404D), 30);
        InsertData(XEH, XCHILD1, XMary, CA.AdjustDate(19020725D), 5);
        InsertData(XEH, XCHILD2, XArthur, CA.AdjustDate(19020926D), 3);
        InsertData(XOF, XWIFE, XJulia, CA.AdjustDate(19020607D), 50);
        InsertData(XOF, XCHILD1, XElisabeth, CA.AdjustDate(19020318D), 25);
        InsertData(XOF, XCHILD2, XLiam, CA.AdjustDate(19020416D), 21);
        InsertData(XLT, XHUSBAND, XFranco, CA.AdjustDate(19020423D), 33);
        InsertData(XLT, XCHILD1, XCharles, CA.AdjustDate(19020529D), 8);
        InsertData(XJO, XWIFE, XDiana, CA.AdjustDate(19021112D), 31);
        InsertData(XJO, XCHILD1, 'James', CA.AdjustDate(19020929D), 6);
        InsertData(XRB, XWIFE, XSofie, CA.AdjustDate(19020815D), 33);
        InsertData(XRB, XCHILD1, XMary, CA.AdjustDate(19021026D), 9);
    end;

    var
        Relative: Record "Employee Relative";
        Employee: Record Employee;
        "Line No.": Integer;
        "Old Employee No.": Code[20];
        XEH: Label 'EH';
        XOF: Label 'OF';
        XHUSBAND: Label 'HUSBAND';
        XCHILD1: Label 'CHILD1';
        XCHILD2: Label 'CHILD2';
        XJames: Label 'James';
        XMary: Label 'Mary';
        XArthur: Label 'Arthur';
        XWIFE: Label 'WIFE';
        XJulia: Label 'Julia';
        XElisabeth: Label 'Elisabeth';
        XLiam: Label 'Liam';
        XFranco: Label 'Franco';
        XLT: Label 'LT';
        XJO: Label 'JO';
        XRB: Label 'RB';
        XSofie: Label 'Sofie';
        XDiana: Label 'Diana';
        XCharles: Label 'Charles';
        CA: Codeunit "Make Adjustments";

    procedure InsertData("Employee No.": Code[20]; "Relative Code": Code[10]; "First Name": Text[30]; "Birth Date": Date; Age: Integer)
    begin
        Employee.Get("Employee No.");
        Relative."Employee No." := "Employee No.";
        if "Old Employee No." = "Employee No." then
            "Line No." := "Line No." + 10000
        else
            "Line No." := 10000;
        Relative."Line No." := "Line No.";
        "Old Employee No." := "Employee No.";
        Relative."Relative Code" := "Relative Code";
        Relative."First Name" := "First Name";
        Relative."Last Name" := Employee."Last Name";
        "Birth Date" := DMY2Date(Date2DMY("Birth Date", 1), Date2DMY("Birth Date", 2),
            (Date2DMY("Birth Date", 3) - Age));
        Relative."Birth Date" := "Birth Date";
        Relative.Insert();
    end;
}

