codeunit 101904 "Modify Currency"
{

    trigger OnRun()
    begin
        exit; // RU

    end;

    var
        Currency: Record Currency;
        CA: Codeunit "Make Adjustments";
}

