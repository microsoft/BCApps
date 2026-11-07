codeunit 101564 "Create Interaction Template"
{

    trigger OnRun()
    begin
        InsertData(XABSTRACT, XAbstractsofmeeting, XLETTER, 8, 90, 1, 0, XENU, 1, 1, true);
        InsertData(XBUS, XBusinessletter, XLETTER, 8, 30, 1, 1, XENU, 1, 1, true);
        InsertData(XCOVERSH, XCoversheet, XSYSTEM, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XGOLF, XGolfevent, XLETTER, 8, 1, 1, 1, XENU, 2, 3, true);
        InsertData(XINCOME, XIncomingphonecall, XPHONE, 0, 15, 2, 2, '', 0, 0, true);
        InsertData(XINHOUSE, XMeetingheldatCRONUS, XMEETING, 25, 120, 1, 1, '', 0, 0, false);
        InsertData(XINSDOC, XInsertadocument, XDOC, 0, 0, 0, 0, '', 0, 2, false);
        InsertData(XMEMO, XMem, XLETTER, 8, 15, 1, 1, XENU, 1, 1, true);
        InsertData(XONSITE, XMeetingatthecustomerssite, XMEETING, 45, 180, 1, 1, '', 0, 0, false);
        InsertData(XOUTGOING, XOutgoingphonecall, XPHONE, 1, 15, 1, 1, '', 0, 0, true);
        InsertData(XREMIN, XReminder, XSYSTEM, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSYSDOC, XOtherSystemDocuments, XSYSTEM, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XWORKSHOP, XWorkshopactivities, XMEETING, 120, 300, 1, 1, '', 0, 0, false);
        InsertData(XEMAIL, XEmails, XSYSTEM, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XEMAILDTxt, XEmailDraftTxt, XSYSTEM, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XMEETINV, XMeetingInvitation, XSYSTEM, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSVORDC, XServiceOrderCreate, XSERVICE, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSVORDP, XServiceOrderPost, XSERVICE, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSVCONTR, XServiceContract, XSERVICE, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSVCONTRQ, XServiceContractQuote, XSERVICE, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSVQUOTE, XServiceQuote, XSERVICE, 8, 1, 1, 1, '', 0, 0, false);
        InsertSalesTemplates();
        InsertPurhcaseTemplates();
    end;

    var
        "Interaction Template": Record "Interaction Template";
        XABSTRACT: Label 'ABSTRACT';
        XAbstractsofmeeting: Label 'Abstracts of meeting';
        XLETTER: Label 'LETTER';
        XBUS: Label 'BUS';
        XBusinessletter: Label 'Business letter';
        XCOVERSH: Label 'COVERSH';
        XCoversheet: Label 'Coversheet';
        XSYSTEM: Label 'SYSTEM';
        XGOLF: Label 'GOLF';
        XGolfevent: Label 'Golf event';
        XINCOME: Label 'INCOME';
        XIncomingphonecall: Label 'Incoming phone call';
        XPHONE: Label 'PHONE';
        XINHOUSE: Label 'INHOUSE';
        XMeetingheldatCRONUS: Label 'Meeting held at CRONUS';
        XMEETING: Label 'MEETING';
        XINSDOC: Label 'INSDOC';
        XInsertadocument: Label 'Insert a document';
        XDOC: Label 'DOC';
        XMEMO: Label 'MEMO';
        XMem: Label 'Memo';
        XONSITE: Label 'ONSITE';
        XMeetingatthecustomerssite: Label 'Meeting at the customers site';
        XOUTGOING: Label 'OUTGOING';
        XOutgoingphonecall: Label 'Outgoing phone call';
        XREMIN: Label 'REMIN';
        XReminder: Label 'Reminder';
        XSYSDOC: Label 'SYSDOC';
        XOtherSystemDocuments: Label 'Other System Documents';
        XWORKSHOP: Label 'WORKSHOP';
        XWorkshopactivities: Label 'Workshop activities';
        XEMAIL: Label 'EMAIL';
        XEmails: Label 'Emails';
        XMEETINV: Label 'MEETINV';
        XMeetingInvitation: Label 'Meeting Invitation';
        XSQUOTE: Label 'S_QUOTE';
        XSalesQuote: Label 'Sales Quote';
        XSALES: Label 'SALES';
        XSORDERCF: Label 'S_ORDER_CF';
        XSalesOrderConfirmation: Label 'Sales Order Confirmation';
        XSDRAFTIN: Label 'S_DRAFT_IN';
        XSalesDraftInvoice: Label 'Sales Draft Invoice';
        XSBORDER: Label 'S_B_ORDER';
        XSalesBlanketOrder: Label 'Sales Blanket Order';
        XSINVOICE: Label 'S_INVOICE';
        XSalesInvoice: Label 'Sales Invoice';
        XSCMEMO: Label 'S_C_MEMO';
        XSalesCreditMemo: Label 'Sales Credit Memo';
        XSSHIP: Label 'S_SHIP';
        XSalesShipment: Label 'Sales Shipment';
        XSREMIND: Label 'S_REMIND';
        XSalesReminder: Label 'Sales Reminder';
        XSSTATM: Label 'S_STATM';
        XSalesStatement: Label 'Sales Statement';
        XSRETORD: Label 'S_RET_ORD';
        XSalesReturnOrder: Label 'Sales Return Order';
        XSRETRCP: Label 'S_RET_RCP';
        XSalesReturnReceipt: Label 'Sales Return Receipt';
        XSFINCHG: Label 'S_FIN_CHG';
        XFinanceCharge: Label 'Finance Charge';
        XSVORDC: Label 'SV_ORD_C';
        XServiceOrderCreate: Label 'Service Order Create';
        XSERVICE: Label 'SERVICE';
        XSVORDP: Label 'SV_ORD_P';
        XServiceOrderPost: Label 'Service Order Post';
        XSVCONTR: Label 'SV_CONTR';
        XServiceContract: Label 'Service Contract';
        XSVCONTRQ: Label 'SV_CONTR_Q';
        XServiceContractQuote: Label 'Service Contract Quote';
        XSVQUOTE: Label 'SV_QUOTE';
        XServiceQuote: Label 'Service Quote';
        XPQUOTE: Label 'P_QUOTE';
        XPurchaseQuote: Label 'Purchase Quote';
        XPORDER: Label 'P_ORDER';
        XPurchaseOrder: Label 'Purchase Order';
        XPURCHASES: Label 'PURCHASES';
        XPBORDER: Label 'P_B_ORDER';
        XPurchaseBlanketOrder: Label 'Purchase Blanket Order';
        XPINVOICE: Label 'P_INVOICE';
        XPurchaseInvoice: Label 'Purchase Invoice';
        XPCMEMO: Label 'P_C_MEMO';
        XPurchaseCreditMemo: Label 'Purchase Credit Memo';
        XPRECEIPT: Label 'P_RECEIPT';
        XPurchaseReceipt: Label 'Purchase Receipt';
        XPRTSHIP: Label 'P_RT_SHIP';
        XPurchaseReturnShipment: Label 'Purchase Return Shipment';
        XPRTORDC: Label 'P_RT_ORD_C';
        XPurchRetOrderConfirmation: Label 'Purchase Return Order Confirmation';
        XENU: Label 'ENU';
        XEMAILDTxt: Label 'EMAIL_D', Comment = 'Short form of email draft';
        XEmailDraftTxt: Label 'Email Draft';

    procedure InsertData("Code": Code[10]; Description: Text[50]; "Interaction Group Code": Code[10]; "Unit Cost (LCY)": Decimal; "Unit Duration (Min.)": Decimal; "Information Flow": Option; "Initiated by": Option; "Language Code (Default)": Code[10]; "Correspondence Type (Default)": Option; "Wizard Trigger": Option; "Ignore Contact Corres. Type": Boolean)
    begin
        "Interaction Template".Init();
        "Interaction Template".Validate(Code, Code);
        "Interaction Template".Validate(Description, Description);
        "Interaction Template".Validate("Interaction Group Code", "Interaction Group Code");
        "Interaction Template".Validate("Unit Cost (LCY)", "Unit Cost (LCY)");
        "Interaction Template".Validate("Unit Duration (Min.)", "Unit Duration (Min.)");
        "Interaction Template".Validate("Information Flow", "Information Flow");
        "Interaction Template".Validate("Initiated By", "Initiated by");
        "Interaction Template"."Language Code (Default)" := "Language Code (Default)";
        "Interaction Template".Validate("Correspondence Type (Default)", "Correspondence Type (Default)");
        "Interaction Template".Validate("Wizard Action", "Wizard Trigger");
        "Interaction Template".Validate("Ignore Contact Corres. Type", "Ignore Contact Corres. Type");
        "Interaction Template".Insert();
    end;

    procedure InsertMiniAppData()
    begin
        InsertData(XCOVERSH, XCoversheet, XSYSTEM, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XEMAIL, XEmails, XSYSTEM, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XEMAILDTxt, XEmailDraftTxt, XSYSTEM, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XMEETINV, XMeetingInvitation, XSYSTEM, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XOUTGOING, XOutgoingphonecall, XPHONE, 1, 15, 1, 1, '', 0, 0, true);
        InsertData(XINCOME, XIncomingphonecall, XPHONE, 0, 15, 2, 2, '', 0, 0, true);
        InsertSalesTemplates();
        InsertPurhcaseTemplates();
    end;

    procedure CreateEvaluationData()
    begin
        InsertData(XABSTRACT, XAbstractsofmeeting, XLETTER, 8, 90, 1, 0, '', 1, 0, true);
        InsertData(XBUS, XBusinessletter, XLETTER, 8, 30, 1, 1, '', 1, 0, true);
        InsertData(XGOLF, XGolfevent, XLETTER, 8, 1, 1, 1, '', 2, 3, true);
        InsertData(XINHOUSE, XMeetingheldatCRONUS, XMEETING, 25, 120, 1, 1, '', 0, 0, false);
        InsertData(XONSITE, XMeetingatthecustomerssite, XMEETING, 45, 180, 1, 1, '', 0, 0, false);
    end;

    local procedure InsertSalesTemplates()
    begin
        InsertData(XSQUOTE, XSalesQuote, XSALES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSORDERCF, XSalesOrderConfirmation, XSALES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSDRAFTIN, XSalesDraftInvoice, XSALES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSBORDER, XSalesBlanketOrder, XSALES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSINVOICE, XSalesInvoice, XSALES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSCMEMO, XSalesCreditMemo, XSALES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSSHIP, XSalesShipment, XSALES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSREMIND, XSalesReminder, XSALES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSSTATM, XSalesStatement, XSALES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSRETORD, XSalesReturnOrder, XSALES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSRETRCP, XSalesReturnReceipt, XSALES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XSFINCHG, XFinanceCharge, XSALES, 8, 1, 1, 1, '', 0, 0, false);
    end;

    local procedure InsertPurhcaseTemplates()
    begin
        InsertData(XPQUOTE, XPurchaseQuote, XPURCHASES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XPORDER, XPurchaseOrder, XPURCHASES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XPBORDER, XPurchaseBlanketOrder, XPURCHASES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XPINVOICE, XPurchaseInvoice, XPURCHASES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XPCMEMO, XPurchaseCreditMemo, XPURCHASES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XPRECEIPT, XPurchaseReceipt, XPURCHASES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XPRTSHIP, XPurchaseReturnShipment, XPURCHASES, 8, 1, 1, 1, '', 0, 0, false);
        InsertData(XPRTORDC, XPurchRetOrderConfirmation, XPURCHASES, 8, 1, 1, 1, '', 0, 0, false);
    end;
}

