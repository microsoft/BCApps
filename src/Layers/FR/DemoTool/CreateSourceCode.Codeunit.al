codeunit 101230 "Create Source Code"
{

    trigger OnRun()
    begin
        "Source Code".Init();
        "Source Code".Code := XSTART;
        "Source Code".Description := XOpeningEntries;
        "Source Code".Insert(true);

        "Source Code".Init();
        "Source Code".Code := XEFFETS;
        "Source Code".Description := XBillsOfExchange;
        "Source Code".Insert(true);
    end;

    var
        "Source Code": Record "Source Code";
        XSTART: Label 'START';
        XOpeningEntries: Label 'Opening Entries';
        XEFFETS: Label 'EFFETS';
        XBillsOfExchange: Label 'Bills Of Exchange';
}

