codeunit 101814 "Create FA Recl. Jnl. Template"
{

    trigger OnRun()
    begin
        InsertData(XRECLASSIFY, XFAReclassJournal);
    end;

    var
        XRECLASSIFY: Label 'RECLASSIFY';
        XFAReclassJournal: Label 'FA Reclass. Journal';

    procedure InsertData(Name: Code[10]; Description: Text[80])
    var
        "FA Reclass. Journal Template": Record "FA Reclass. Journal Template";
    begin
        "FA Reclass. Journal Template".Init();
        "FA Reclass. Journal Template".Validate(Name, Name);
        "FA Reclass. Journal Template".Validate(Description, Description);
        "FA Reclass. Journal Template".Insert(true);
    end;
}

