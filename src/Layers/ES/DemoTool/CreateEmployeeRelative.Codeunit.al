codeunit 101604 "Create Employee Relative"
{

    trigger OnRun()
    begin
        // InsertData(XEH,XHUSBAND,XJames,CA.AdjustDate(04041902D),30);
        // InsertData(XEH,XCHILD1,XMary,CA.AdjustDate(25071902D),5);
        // InsertData(XEH,XCHILD2,XArthur,CA.AdjustDate(26091902D),3);
        // InsertData(XOF,XWIFE,XJulia,CA.AdjustDate(07061902D),50);
        // InsertData(XOF,XCHILD1,XElisabeth,CA.AdjustDate(18031902D),25);
        // InsertData(XOF,XCHILD2,XLiam,CA.AdjustDate(16041902D),21);
        // InsertData(XLT,XHUSBAND,XFranco,CA.AdjustDate(23041902D),33);
        // InsertData(XLT,XCHILD1,XCharles,CA.AdjustDate(29051902D),8);
        // InsertData(XJO,XWIFE,XDiana,CA.AdjustDate(12111902D),31);
        // InsertData(XJO,XCHILD1,'James',CA.AdjustDate(29091902D),6);
        // InsertData(XRB,XWIFE,XSofie,CA.AdjustDate(15081902D),33);
        // InsertData(XRB,XCHILD1,XMary,CA.AdjustDate(26101902D),9);
        InsertData(XEH, XHUSBAND, XJuan, CA.AdjustDate(19020404D), 30, XGarcia, XBalboa);
        InsertData(XEH, XCHILD1, XMaria, CA.AdjustDate(19020725D), 5, XGarcia, XHernandez);
        InsertData(XEH, XCHILD2, XArturo, CA.AdjustDate(19020926D), 3, XGarcia, XHernandez);
        InsertData(XOF, XWIFE, XJulia, CA.AdjustDate(19020926D), 50, XCobos, XPasante);
        InsertData(XOF, XCHILD1, XElisa, CA.AdjustDate(19020318D), 25, XRobles, XCobos);
        InsertData(XOF, XCHILD2, XLucas, CA.AdjustDate(19020416D), 21, XRobles, XCobos);
        InsertData(XLT, XHUSBAND, XFelipe, CA.AdjustDate(19020423D), 33, XPeral, XGomez);
        InsertData(XLT, XCHILD1, XCarlos, CA.AdjustDate(19020529D), 8, XFlores, XPeral);
        InsertData(XJO, XWIFE, XDiana, CA.AdjustDate(19021112D), 31, XGonzalo, XAyuso);
        InsertData(XJO, XCHILD1, XJuan, CA.AdjustDate(19020929D), 6, XSamplon, XAyuso);
        InsertData(XRB, XWIFE, XSofia, CA.AdjustDate(19020815D), 33, XAltares, XCasero);
        InsertData(XRB, XCHILD1, XMaria, CA.AdjustDate(19021026D), 9, XQuevedo, XAltares);
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
        XWIFE: Label 'WIFE';
        XJulia: Label 'Julia';
        XLT: Label 'LT';
        XJO: Label 'JO';
        XRB: Label 'RB';
        XDiana: Label 'Diana';
        CA: Codeunit "Make Adjustments";
        XJuan: Label 'Juan';
        XGarcia: Label 'García';
        XBalboa: Label 'Balboa';
        XMaria: Label 'María';
        XHernandez: Label 'Hernández';
        XArturo: Label 'Arturo';
        XCobos: Label 'Cobos';
        XPasante: Label 'Pasante';
        XElisa: Label 'Elisa';
        XRobles: Label 'Robles';
        XLucas: Label 'Lucas';
        XFelipe: Label 'Felipe';
        XPeral: Label 'Peral';
        XGomez: Label 'Gómez';
        XCarlos: Label 'Carlos';
        XFlores: Label 'Flores';
        XGonzalo: Label 'Gonzalo';
        XAyuso: Label 'Ayuso';
        XSamplon: Label 'Samplón';
        XSofia: Label 'Sofía';
        XAltares: Label 'Altares';
        XCasero: Label 'Casero';
        XQuevedo: Label 'Quevedo';

    procedure InsertData("Employee No.": Code[20]; "Relative Code": Code[10]; "First Name": Text[30]; "Birth Date": Date; Age: Integer; FFN: Text[30]; SFN: Text[30])
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
        // Relative."First Name" := "First Name";
        // Relative."Last Name" := Employee."Last Name";
        Relative.Name := "First Name";
        Relative."First Family Name" := FFN;
        Relative."Second Family Name" := SFN;
        "Birth Date" := DMY2Date(Date2DMY("Birth Date", 1), Date2DMY("Birth Date", 2),
            (Date2DMY("Birth Date", 3) - Age));
        Relative."Birth Date" := "Birth Date";
        Relative.Insert();
    end;
}

