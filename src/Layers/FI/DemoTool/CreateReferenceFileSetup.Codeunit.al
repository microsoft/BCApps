codeunit 160900 "Create Reference File Setup"
{

    trigger OnRun()
    begin
        InsertData(XNBL);
    end;

    var
        XNBL: Label 'NBL';

    procedure InsertData("No.": Code[20])
    var
        "Reference File Setup": Record "Reference File Setup";
    begin
        "Reference File Setup".Init();
        "Reference File Setup".Validate("No.", "No.");
        "Reference File Setup".Insert();
    end;
}

