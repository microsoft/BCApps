codeunit 101821 "Create FA Main Asset Comp."
{

    trigger OnRun()
    begin
        InsertData(XFA000040, XFA000050);
        InsertData(XFA000040, XFA000060);
        InsertData(XFA000040, XFA000070);
    end;

    var
        "Fixed Asset": Record "Fixed Asset";
        "Main Asset Component": Record "Main Asset Component";
        XFA000040: Label 'FA000040';
        XFA000050: Label 'FA000050';
        XFA000060: Label 'FA000060';
        XFA000070: Label 'FA000070';

    procedure InsertData("Main Asset No.": Code[20]; "FA No.": Code[20])
    begin
        "Main Asset Component"."Main Asset No." := "Main Asset No.";
        "Main Asset Component"."FA No." := "FA No.";
        "Fixed Asset".Get("FA No.");
        "Main Asset Component".Description := "Fixed Asset".Description;
        "Main Asset Component".Insert();
    end;
}

