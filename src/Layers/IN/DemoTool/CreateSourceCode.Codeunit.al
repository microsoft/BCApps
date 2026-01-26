codeunit 101230 "Create Source Code"
{

    trigger OnRun()
    begin
        "Source Code".Init();
        "Source Code".Code := XSTART;
        "Source Code".Description := XOpeningEntries;
        "Source Code".Insert(true);
        InsertData(XBANKPYMTVSourceCodeLbl, XBANKPYMTV);
        InsertData(XBANKRCPTVSourceCodeLbl, XBANKRCPTV);
        InsertData(XCASHPYMTVSourceCodeLbl, XCASHPYMTV);
        InsertData(XCASHRCPTVSourceCodeLbl, XCASHRCPTV);
        InsertData(XCONTRAVSourceCodeLbl, XCONTRAV);
        InsertData(XJOURNALVSourceCodeLbl, XJOURNALV);
        InsertData(XTCSADJNLSourceCodeLbl, XTCSADJNLLbl);
        InsertData(XTDSADJNLSourceCodeLbl, XTDSADJNLLbl);
        InsertData(XGSTSETSourceCodeLbl, XGSTSETLbl);
        InsertData(XGSTCRADJSourceCodeLbl, XGSTCRADJLbl);
    end;

    local procedure InsertData(Code: Code[20]; Description: Text[100])
    begin
        "Source Code".Init();
        "Source Code".Validate(Code, Code);
        "Source Code".Validate(Description, Description);
        "Source Code".Insert();
    end;

    var
        "Source Code": Record "Source Code";
        XSTART: Label 'START';
        XOpeningEntries: Label 'Opening Entries';
        XBANKPYMTV: Label 'Bank Payment Voucher';
        XBANKRCPTV: Label 'Bank Receipt Voucher';
        XCASHPYMTV: Label 'Cash Payment Voucher';
        XCASHRCPTV: Label 'Cash Receipt Voucher';
        XCONTRAV: Label 'Contra Voucher';
        XJOURNALV: Label 'Journal Voucher';
        XBANKPYMTVSourceCodeLbl: Label 'BANKPYMTV';
        XBANKRCPTVSourceCodeLbl: Label 'BANKRCPTV';
        XCASHPYMTVSourceCodeLbl: Label 'CASHPYMTV';
        XCASHRCPTVSourceCodeLbl: Label 'CASHRCPTV';
        XCONTRAVSourceCodeLbl: Label 'CONTRAV';
        XJOURNALVSourceCodeLbl: Label 'JOURNALV';
        XTCSADJNLSourceCodeLbl: Label 'TCSADJNL';
        XTCSADJNLLbl: Label 'TCS Adjustment Journal';
        XTDSADJNLSourceCodeLbl: Label 'TDSADJNL';
        XTDSADJNLLbl: Label 'TDS Adjustment Journal';
        XGSTSETSourceCodeLbl: Label 'GSTSET';
        XGSTSETLbl: Label 'GST Settlement';
        XGSTCRADJSourceCodeLbl: Label 'GSTCRADJ';
        XGSTCRADJLbl: Label 'GST Credit Adjustment Journal';
}

