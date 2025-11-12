codeunit 101599 "Create Interact. Templ. Setup"
{

    trigger OnRun()
    begin
        InteractionTmplSetup.Get();
        FillSalesTemplateCodes();
        FillPurchTemplateCodes();
        InteractionTmplSetup.Validate("Serv Ord Create", XSVORDC);
        InteractionTmplSetup.Validate("Serv Ord Post", XSVORDP);
        InteractionTmplSetup.Validate("E-Mails", XEMAIL);
        InteractionTmplSetup.Validate("Cover Sheets", XCOVERSH);
        InteractionTmplSetup.Validate("Outg. Calls", XOUTGOING);
        InteractionTmplSetup.Validate("Service Contract", XSVCONTR);
        InteractionTmplSetup.Validate("Service Contract Quote", XSVCONTRQ);
        InteractionTmplSetup.Validate("Service Quote", XSVQUOTE);
        InteractionTmplSetup.Validate("Meeting Invitation", XMEETINV);
        InteractionTmplSetup.Validate("E-Mail Draft", XEMAILDTxt);
        InteractionTmplSetup.Modify();
    end;

    var
        InteractionTmplSetup: Record "Interaction Template Setup";
        XSINVOICE: Label 'S_INVOICE';
        XSCMEMO: Label 'S_C_MEMO';
        XSORDERCF: Label 'S_ORDER_CF';
        XSDRAFTIN: Label 'S_DRAFT_IN';
        XSQUOTE: Label 'S_QUOTE';
        XSBORDER: Label 'S_B_ORDER';
        XSVORDC: Label 'SV_ORD_C';
        XSVORDP: Label 'SV_ORD_P';
        XSSHIP: Label 'S_SHIP';
        XSSTATM: Label 'S_STATM';
        XSREMIND: Label 'S_REMIND';
        XPINVOICE: Label 'P_INVOICE';
        XPCMEMO: Label 'P_C_MEMO';
        XPORDER: Label 'P_ORDER';
        XPQUOTE: Label 'P_QUOTE';
        XPBORDER: Label 'P_B_ORDER';
        XPRECEIPT: Label 'P_RECEIPT';
        XEMAIL: Label 'EMAIL';
        XCOVERSH: Label 'COVERSH';
        XOUTGOING: Label 'OUTGOING';
        XSRETORD: Label 'S_RET_ORD';
        XSFINCHG: Label 'S_FIN_CHG';
        XSRETRCP: Label 'S_RET_RCP';
        XPRTSHIP: Label 'P_RT_SHIP';
        XPRTORDC: Label 'P_RT_ORD_C';
        XSVCONTR: Label 'SV_CONTR';
        XSVCONTRQ: Label 'SV_CONTR_Q';
        XSVQUOTE: Label 'SV_QUOTE';
        XMEETINV: Label 'MEETINV';
        XEMAILDTxt: Label 'EMAIL_D', Comment = 'Short form of email draft';

    procedure InsertMiniAppData()
    begin
        InteractionTmplSetup.Get();
        InteractionTmplSetup.Validate("E-Mails", XEMAIL);
        InteractionTmplSetup.Validate("E-Mail Draft", XEMAILDTxt);
        InteractionTmplSetup.Validate("Cover Sheets", XCOVERSH);
        InteractionTmplSetup.Validate("Outg. Calls", XOUTGOING);
        InteractionTmplSetup.Validate("Meeting Invitation", XMEETINV);
        FillSalesTemplateCodes();
        FillPurchTemplateCodes();
        InteractionTmplSetup.Modify();
    end;

    local procedure FillSalesTemplateCodes()
    begin
        InteractionTmplSetup.Validate("Sales Invoices", XSINVOICE);
        InteractionTmplSetup.Validate("Sales Cr. Memo", XSCMEMO);
        InteractionTmplSetup.Validate("Sales Ord. Cnfrmn.", XSORDERCF);
        InteractionTmplSetup.Validate("Sales Draft Invoices", XSDRAFTIN);
        InteractionTmplSetup.Validate("Sales Quotes", XSQUOTE);
        InteractionTmplSetup.Validate("Sales Blnkt. Ord", XSBORDER);
        InteractionTmplSetup.Validate("Sales Shpt. Note", XSSHIP);
        InteractionTmplSetup.Validate("Sales Statement", XSSTATM);
        InteractionTmplSetup.Validate("Sales Rmdr.", XSREMIND);
        InteractionTmplSetup.Validate("Sales Return Order", XSRETORD);
        InteractionTmplSetup.Validate("Sales Finance Charge Memo", XSFINCHG);
        InteractionTmplSetup.Validate("Sales Return Receipt", XSRETRCP);
    end;

    local procedure FillPurchTemplateCodes()
    begin
        InteractionTmplSetup.Validate("Purch Invoices", XPINVOICE);
        InteractionTmplSetup.Validate("Purch Cr Memos", XPCMEMO);
        InteractionTmplSetup.Validate("Purch. Orders", XPORDER);
        InteractionTmplSetup.Validate("Purch. Quotes", XPQUOTE);
        InteractionTmplSetup.Validate("Purch Blnkt Ord", XPBORDER);
        InteractionTmplSetup.Validate("Purch. Rcpt.", XPRECEIPT);
        InteractionTmplSetup.Validate("Purch. Return Shipment", XPRTSHIP);
        InteractionTmplSetup.Validate("Purch. Return Ord. Cnfrmn.", XPRTORDC);
    end;
}

