codeunit 117556 "Add No. Series"
{

    trigger OnRun()
    begin
        InsertRec(XSMCNTTEMP, XTemplatesforServiceCont, '1');
        InsertRec(XSMCONTRAC, XServiceContracts, '1');
        InsertRec(XSMINVCON, XInvoiceNoforContracts, '1');
        InsertRec(XSMINV, XServiceInvoices, '1');
        InsertRec(XSMINVPLUS, XPostedServiceInvoices, '1');
        InsertRec(XSMITEM, XServiceItems, '1');
        InsertRec(XSMLOANER, XLoaners, '1');
        InsertRec(XSMORDER, XServiceOrders, '1');
        InsertRec(XSMQUOTE, XServiceQuotes, '1');
        InsertRec(XSMTROUBLE, XTroubleList, '1');
        InsertRec(XSMGENJNL, XGeneralJournalforContract, '1');
        InsertRec(XSMPREPAID, XPrepaidNoforContractBatch, '1');
        InsertRec(XSMCRCON, XCreditMemoNoforContracts, '1');
        InsertRec(XSMCR, XServiceCreditMemo, '1');
        InsertRec(XSMCRPLUS, XPostedServiceCreditMemo, '1');
        InsertRec(XSMSHIPPLUS, XPostedServiceShipment, '1');
        InsertRec(XCASHFLOW, XxCashFlow, '1');
        InsertRec(XBANKPYMTVSourceCodeLbl, XBANKPYMTV, '1');
        InsertRec(XBANKRCPTVSourceCodeLbl, XBANKRCPTV, '1');
        InsertRec(XCASHPYMTVSourceCodeLbl, XCASHPYMTV, '1');
        InsertRec(XCASHRCPTVSourceCodeLbl, XCASHRCPTV, '1');
        InsertRec(XCONTRAVSourceCodeLbl, XCONTRAV, '1');
        InsertRec(XJOURNALVSourceCodeLbl, XJOURNALV, '1');
        InsertRec(XINSALES, XPostedINSales, '1');
        InsertRec(XBNKPYVP, XPostedBankPaymentVoucher, '1');
        InsertRec(XBNKRCVP, XPostedBankReceiptVoucher, '1');
        InsertRec(XCSHPYVP, XPostedCashPaymentVoucher, '1');
        InsertRec(XCSHRCVP, XPostedCashReceiptVoucher, '1');
        InsertRec(XCNTRVP, XPostedContraVoucher, '1');
        InsertRec(XJRNLVP, XPostedJournalVoucher, '1');
    end;

    var
        XSMCNTTEMP: Label 'SM-CNTTEMP';
        XTemplatesforServiceCont: Label 'Templates for Service Contracts';
        XSMCONTRAC: Label 'SM-CONTRAC';
        XServiceContracts: Label 'Service Contracts';
        XSMINVCON: Label 'SM-INV-CON';
        XInvoiceNoforContracts: Label 'Invoice No. for Contracts';
        XSMINV: Label 'SM-INV';
        XServiceInvoices: Label 'Service Invoices';
        XSMITEM: Label 'SM-ITEM';
        XServiceItems: Label 'Service Items';
        XSMLOANER: Label 'SM-LOANER';
        XLoaners: Label 'Loaners';
        XSMORDER: Label 'SM-ORDER';
        XServiceOrders: Label 'Service Orders';
        XSMQUOTE: Label 'SM-QUOTE';
        XServiceQuotes: Label 'Service Quotes';
        XSMTROUBLE: Label 'SM-TROUBLE';
        XTroubleList: Label 'Trouble List';
        XSMGENJNL: Label 'SM-GENJNL';
        XGeneralJournalforContract: Label 'General Journal for Contract';
        XSMPREPAID: Label 'SM-PREPAID';
        XPrepaidNoforContractBatch: Label 'Prepaid No. for Contract Batchjobs';
        XSMCRCON: Label 'SM-CR-CON';
        XCreditMemoNoforContracts: Label 'Credit Memo No. for Contracts';
        XSMINVPLUS: Label 'SM-INV+';
        XPostedServiceInvoices: Label 'Posted Service Invoices';
        XSMCR: Label 'SM-CR';
        XServiceCreditMemo: Label 'Service Credit Memo';
        XSMCRPLUS: Label 'SM-CR+';
        XPostedServiceCreditMemo: Label 'Posted Service Credit Memo';
        XSMSHIPPLUS: Label 'SM-SHIP+';
        XPostedServiceShipment: Label 'Posted Service Shipment';
        XCASHFLOW: Label 'CASHFLOW', Comment = 'Cashflow is a name of No. Series.';
        XxCashFlow: Label 'Cash Flow';
        XBANKPYMTV: Label 'Bank Payment Voucher';
        XBANKRCPTV: Label 'Bank Receipt Voucher';
        XCASHPYMTV: Label 'Cash Payment Voucher';
        XCASHRCPTV: Label 'Cash Receipt Voucher';
        XCONTRAV: Label 'Contra Voucher';
        XJOURNALV: Label 'Journal Voucher';
        XPostedBankPaymentVoucher: Label 'Posted Bank Payment Voucher';
        XPostedBankReceiptVoucher: Label 'Posted Bank Receipt Voucher';
        XPostedCashPaymentVoucher: Label 'Posted Cash Payment Voucher';
        XPostedCashReceiptVoucher: Label 'Posted Cash Receipt Voucher';
        XPostedContraVoucher: Label 'Posted Contra Voucher';
        XPostedJournalVoucher: Label 'Posted Journal Voucher';
        XPostedINSales: Label 'Posted Sales IN Invoice';
        XINSALES: Label 'IN-SALES';
        XBNKPYVP: Label 'BNKPYV-P';
        XBNKRCVP: Label 'BNKRCV-P';
        XCSHPYVP: Label 'CSHPYV-P';
        XCSHRCVP: Label 'CSHRCV-P';
        XCNTRVP: Label 'CNTRV-P';
        XJRNLVP: Label 'JRNLV-P';
        XBANKPYMTVSourceCodeLbl: Label 'BANKPYMTV';
        XBANKRCPTVSourceCodeLbl: Label 'BANKRCPTV';
        XCASHPYMTVSourceCodeLbl: Label 'CASHPYMTV';
        XCASHRCPTVSourceCodeLbl: Label 'CASHRCPTV';
        XCONTRAVSourceCodeLbl: Label 'CONTRAV';
        XJOURNALVSourceCodeLbl: Label 'JOURNALV';

    procedure InsertRec(Fld1: Text[250]; Fld2: Text[250]; Fld3: Text[250])
    var
        NewRec: Record "No. Series";
    begin
        if NewRec.Get(Fld1) then
            exit;
        NewRec.Init();
        Evaluate(NewRec.Code, Fld1);
        Evaluate(NewRec.Description, Fld2);
        Evaluate(NewRec."Default Nos.", Fld3);
        NewRec."Manual Nos." := true;
        NewRec.Insert();
    end;
}

