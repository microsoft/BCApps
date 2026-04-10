codeunit 117556 "Add No. Series"
{

    trigger OnRun()
    begin
        InsertRec(XSRV + '-20', XTemplatesforServiceCont, '1');
        InsertRec(XSRV + '-02', XServiceContracts, '1');
        InsertRec(XSRV + '-11', XInvoiceNoforContracts, '1');
        InsertRec(XSRV + '-13', XServiceInvoices, '1');
        InsertRec(XSRV + '-14', XPostedServiceInvoices, '1');
        InsertRec(XSRV + '-04', XServiceItems, '1');
        InsertRec(XSRV + '-01', XLoaners, '1');
        InsertRec(XSRV + '-12', XServiceOrders, '1');
        InsertRec(XSRV + '-10', XServiceQuotes, '1');
        InsertRec(XSRV + '-03', XTroubleList, '1');
        InsertRec(XSRV + '-30', XGeneralJournalforContract, '1');
        InsertRec(XSRV + '-05', XPrepaidNoforContractBatch, '1');
        InsertRec(XSRV + '-19', XCreditMemoNoforContracts, '1');
        InsertRec(XSRV + '-15', XServiceCreditMemo, '1');
        InsertRec(XSRV + '-16', XPostedServiceCreditMemo, '1');
        InsertRec(XSRV + '-17', XPostedServiceShipment, '1');
        // TODO: to be localized
        InsertRec(XCASHFLOW, XxCashFlow, '1');
    end;

    var
        XTemplatesforServiceCont: Label 'Templates for Service Contracts';
        XServiceContracts: Label 'Service Contracts';
        XInvoiceNoforContracts: Label 'Invoice No. for Contracts';
        XServiceInvoices: Label 'Service Invoices';
        XServiceItems: Label 'Service Items';
        XLoaners: Label 'Loaners';
        XServiceOrders: Label 'Service Orders';
        XServiceQuotes: Label 'Service Quotes';
        XTroubleList: Label 'Trouble List';
        XGeneralJournalforContract: Label 'General Journal for Contract';
        XPrepaidNoforContractBatch: Label 'Prepaid No. for Contract Batchjobs';
        XCreditMemoNoforContracts: Label 'Credit Memo No. for Contracts';
        XPostedServiceInvoices: Label 'Posted Service Invoices';
        XServiceCreditMemo: Label 'Service Credit Memo';
        XPostedServiceCreditMemo: Label 'Posted Service Credit Memo';
        XPostedServiceShipment: Label 'Posted Service Shipment';
        XSRV: Label 'SRV';
        XCASHFLOW: Label 'CASHFLOW', Comment = 'Cashflow is a name of No. Series.';
        XxCashFlow: Label 'Cash Flow';

    procedure InsertRec(Fld1: Text[250]; Fld2: Text[250]; Fld3: Text[250])
    var
        NewRec: Record "No. Series";
    begin
        NewRec.Init();
        Evaluate(NewRec.Code, Fld1);
        Evaluate(NewRec.Description, Fld2);
        Evaluate(NewRec."Default Nos.", Fld3);
        NewRec."Manual Nos." := true;
        NewRec.Insert();
    end;
}

