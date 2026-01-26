codeunit 101230 "Create Source Code"
{

    trigger OnRun()
    begin
        "Source Code".Init();
        "Source Code".Code := XSTART;
        "Source Code".Description := XOpeningEntries;
        "Source Code".Insert(true);
        //BEGIN IT
        "Source Code".Code := XxRIBA;
        "Source Code".Description := XBankReceipts;
        "Source Code".Insert(true);

        "Source Code".Code := XxBANKTRANSF;
        "Source Code".Description := XBankTransfers;
        "Source Code".Insert(true);
        //END IT
    end;

    var
        XxRIBA: Label 'RIBA';
        XBankReceipts: Label 'Bank Receipts';
        XxBANKTRANSF: Label 'BANKTRANSF';
        XBankTransfers: Label 'Bank Transfers';
        "Source Code": Record "Source Code";
        XSTART: Label 'START';
        XOpeningEntries: Label 'Opening Entries';
}

