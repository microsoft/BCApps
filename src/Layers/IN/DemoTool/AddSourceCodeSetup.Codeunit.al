codeunit 117555 "Add Source Code Setup"
{

    trigger OnRun()
    begin
        SourceCodeSetup.Get();
        SourceCodeSetup."Service Management" := XSERVICE;
        SourceCodeSetup."Bank Payment Voucher" := XBANKPYMTVSourceCodeLbl;
        SourceCodeSetup."Bank Receipt Voucher" := XBANKRCPTVSourceCodeLbl;
        SourceCodeSetup."Cash Payment Voucher" := XCASHPYMTVSourceCodeLbl;
        SourceCodeSetup."Cash Receipt Voucher" := XCASHRCPTVSourceCodeLbl;
        SourceCodeSetup."Contra Voucher" := XCONTRAVSourceCodeLbl;
        SourceCodeSetup."Journal Voucher" := XJOURNALVSourceCodeLbl;
        SourceCodeSetup."GST Settlement" := XGSTSETSourceCodeLbl;
        SourceCodeSetup."GST Credit Adjustment Journal" := XGSTCRADJSourceCodeLbl;
        SourceCodeSetup.Modify();
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        XSERVICE: Label 'SERVICE';
        XBANKPYMTVSourceCodeLbl: Label 'BANKPYMTV';
        XBANKRCPTVSourceCodeLbl: Label 'BANKRCPTV';
        XCASHPYMTVSourceCodeLbl: Label 'CASHPYMTV';
        XCASHRCPTVSourceCodeLbl: Label 'CASHRCPTV';
        XCONTRAVSourceCodeLbl: Label 'CONTRAV';
        XJOURNALVSourceCodeLbl: Label 'JOURNALV';
        XGSTSETSourceCodeLbl: Label 'GSTSET';
        XGSTCRADJSourceCodeLbl: Label 'GSTCRADJ';
}

