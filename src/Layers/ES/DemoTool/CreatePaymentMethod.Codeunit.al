codeunit 101289 "Create Payment Method"
{

    trigger OnRun()
    begin
        InsertData(XGIRO, XGirotransfer, "Payment Method"."Bal. Account Type"::"Bank Account", XGIRO, false, 0, false, 0, false, '');
        InsertData(XBANK, XBanktransfer, "Payment Method"."Bal. Account Type"::"G/L Account", '', false, 0, false, 0, false, '');
        InsertData(XBANKDOMTxt, XBankDomTransferTxt, "Payment Method"."Bal. Account Type"::"G/L Account", '', false, 0, false, 0, false, XBankDataConvPmtLineDefnTxt);
        InsertData(XBANKINTTxt, XBankIntTransferTxt, "Payment Method"."Bal. Account Type"::"G/L Account", '', false, 0, false, 0, false, XBankDataConvPmtLineDefnTxt);
        InsertData(XCASH, XCashpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '992910', false, 0, false, 0, false, '');
        InsertData(XCHECK, XCheckpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', false, 0, false, 0, false, '');
        InsertData(XACCOUNT, XPaymentonaccount, "Payment Method"."Bal. Account Type"::"G/L Account", '', false, 0, false, 0, false, '');
        InsertData(XINTERCOM, XIntercompanypayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', false, 0, false, 0, false, '');
        InsertData(XAGENTE, XCollectionAssistant, "Payment Method"."Bal. Account Type"::"G/L Account", '', true, 1, false, 0, false, '');
        InsertData(XEFECTO, XNegotiableBill, "Payment Method"."Bal. Account Type"::"Bank Account", '', true, 1, false, 1, false, '');
        InsertData(XLETRA, XAcceptanceBill, "Payment Method"."Bal. Account Type"::"Bank Account", '', true, 1, true, 1, false, '');
        InsertData(XPAGARE, XPromissoryNote, "Payment Method"."Bal. Account Type"::"Bank Account", '', true, 1, false, 3, false, '');
        InsertData(XReceipt, XReceipt, "Payment Method"."Bal. Account Type"::"Bank Account", '', true, 1, false, 2, false, '');
        InsertData(XORDENPAGO, XPaymentOrder, "Payment Method"."Bal. Account Type"::"Bank Account", '', false, 1, false, 5, true, '');
        InsertData(XFactoring, XFactoring, "Payment Method"."Bal. Account Type"::"Bank Account", '', false, 1, false, 0, true, '');
        InsertData(XCARD, XCardpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', false, 0, false, 0, false, '');
        InsertData(XMultiple, XMultiplepaymentmethods, "Payment Method"."Bal. Account Type"::"G/L Account", '', false, 0, false, 0, false, '');
    end;

    var
        "Payment Method": Record "Payment Method";
        "G/L Account": Record "G/L Account";
        CA: Codeunit "Make Adjustments";
        XGIRO: Label 'GIRO';
        XGirotransfer: Label 'Giro transfer';
        XBANK: Label 'BANK';
        XBanktransfer: Label 'Bank Transfer';
        XBANKDOMTxt: Label 'BNKDOMCONV', Locked = true;
        XBankDomTransferTxt: Label 'Domestic Bank Transfer with Data Conversion';
        XBANKINTTxt: Label 'BNKINTCONV', Locked = true;
        XBankIntTransferTxt: Label 'International Bank Transfer with Data Conversion';
        XCASH: Label 'CASH';
        XCashpayment: Label 'Cash payment';
        XCHECK: Label 'CHECK';
        XCheckpayment: Label 'Check payment';
        XACCOUNT: Label 'ACCOUNT';
        XPaymentonaccount: Label 'Payment on account';
        XINTERCOM: Label 'INTERCOM';
        XIntercompanypayment: Label 'Intercompany payment';
        XAGENTE: Label 'AGENTE';
        XCollectionAssistant: Label 'Collection Assistant';
        XEFECTO: Label 'EFECTO';
        XNegotiableBill: Label 'Negotiable Bill';
        XLETRA: Label 'LETRA';
        XAcceptanceBill: Label 'Acceptance Bill';
        XPAGARE: Label 'PAGARE';
        XPromissoryNote: Label 'Promissory Note';
        XReceipt: Label 'Receipt';
        XORDENPAGO: Label 'ORDENPAGO';
        XPaymentOrder: Label 'Payment Order';
        XFactoring: Label 'Factoring';
        XBankDataConvPmtLineDefnTxt: Label 'BANKDATACONVSERVCT', Locked = true;
        XCARD: Label 'CARD', Comment = 'Card';
        XCardpayment: Label 'Card payment';
        XMultiple: Label 'MULTIPLE', Comment = 'Multiple payment methods';
        XMultiplepaymentmethods: Label 'Multiple payment methods';

    procedure InsertMiniAppData()
    begin
        InsertData(XGIRO, XGirotransfer, "Payment Method"."Bal. Account Type"::"Bank Account", '', false, 0, false, 0, false, '');
        InsertData(XBANK, XBanktransfer, "Payment Method"."Bal. Account Type"::"G/L Account", '', false, 0, false, 0, false, '');
        InsertData(XBANKDOMTxt, XBankDomTransferTxt, "Payment Method"."Bal. Account Type"::"G/L Account", '', false, 0, false, 0, false, XBankDataConvPmtLineDefnTxt);
        InsertData(XBANKINTTxt, XBankIntTransferTxt, "Payment Method"."Bal. Account Type"::"G/L Account", '', false, 0, false, 0, false, XBankDataConvPmtLineDefnTxt);
        InsertData(XCASH, XCashpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '992910', false, 0, false, 0, false, '');
        InsertData(XCHECK, XCheckpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', false, 0, false, 0, false, '');
        InsertData(XACCOUNT, XPaymentonaccount, "Payment Method"."Bal. Account Type"::"G/L Account", '', false, 0, false, 0, false, '');
        InsertData(XINTERCOM, XIntercompanypayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', false, 0, false, 0, false, '');
        InsertData(XEFECTO, XNegotiableBill, "Payment Method"."Bal. Account Type"::"Bank Account", '', true, 1, false, 1, false, '');
        InsertData(XPAGARE, XPromissoryNote, "Payment Method"."Bal. Account Type"::"Bank Account", '', true, 1, false, 3, false, '');
        InsertData(XCARD, XCardpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', false, 0, false, 0, false, '');
        InsertData(XMultiple, XMultiplepaymentmethods, "Payment Method"."Bal. Account Type"::"G/L Account", '', false, 0, false, 0, false, '');
    end;

    procedure InsertData("Code": Code[10]; Description: Text[50]; "Bal. Account Type": Enum "Payment Balance Account Type"; "Bal. Account No.": Code[20]; "Create Bills": Boolean; "Company Type": Option; "Submit for Aceptance": Boolean; "Bill Type": Option; "Invoices to Cartera": Boolean; PmtExportLineDefn: Code[20])
    begin
        "Payment Method".Init();
        "Payment Method".Validate(Code, Code);
        "Payment Method".Validate(Description, Description);
        "Payment Method".Validate("Pmt. Export Line Definition", PmtExportLineDefn);
        if "Bal. Account No." <> '' then begin
            "Payment Method".Validate("Bal. Account Type", "Bal. Account Type");
            if "Payment Method"."Bal. Account Type" = "Payment Method"."Bal. Account Type"::"G/L Account" then
                "Bal. Account No." := CA.Convert("Bal. Account No.");
            "Payment Method".Validate("Bal. Account No.", "Bal. Account No.");

            if "Payment Method"."Bal. Account Type" = "Payment Method"."Bal. Account Type"::"G/L Account" then begin
                "G/L Account".Get("Payment Method"."Bal. Account No.");
                "G/L Account".TestField("Reconciliation Account");
            end;
        end;
        "Payment Method".Validate("Collection Agent", "Company Type");
        "Payment Method".Validate("Submit for Acceptance", "Submit for Aceptance");
        "Payment Method".Validate("Create Bills", "Create Bills");
        "Payment Method".Validate("Bill Type", "Bill Type");
        "Payment Method".Validate("Invoices to Cartera", "Invoices to Cartera");
        "Payment Method".Insert(true);
    end;

    procedure GetCashCode(): Code[10]
    begin
        exit(XCASH);
    end;

    procedure GetBankCode(): Code[10]
    begin
        exit(XBANK);
    end;
}

