codeunit 101289 "Create Payment Method"
{

    trigger OnRun()
    begin
        InsertData(XGIRO, XGirotransfer, "Payment Method"."Bal. Account Type"::"Bank Account", XGIRO, '');
        InsertData(XBANK, XBanktransfer, "Payment Method"."Bal. Account Type"::"G/L Account", '', '');
        InsertData(XBANKDOMTxt, XBankDomTransferTxt, "Payment Method"."Bal. Account Type"::"G/L Account", '', XBankDataConvPmtLineDefnTxt);
        InsertData(XBANKINTTxt, XBankIntTransferTxt, "Payment Method"."Bal. Account Type"::"G/L Account", '', XBankDataConvPmtLineDefnTxt);
        InsertData(XCASH, XCashpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', '');
        // NAVCZ
        InsertData(XCHECK, XCheckpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', '');
        InsertData(XACCOUNT, XPaymentonaccount, "Payment Method"."Bal. Account Type"::"G/L Account", '', '');
        InsertData(XINTERCOM, XIntercompanypayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', '');
        InsertData(XCARD, XCardpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', '');
        InsertData(XMultiple, XMultiplepaymentmethods, "Payment Method"."Bal. Account Type"::"G/L Account", '', '');
        InsertData(XCASHDESK01, XCashPayment01, "Payment Method"."Bal. Account Type"::"G/L Account", '', ''); // NAVCZ
    end;

    var
        "Payment Method": Record "Payment Method";
        "G/L Account": Record "G/L Account";
        CA: Codeunit "Make Adjustments";
        XGIRO: Label 'GIRO';
        XGirotransfer: Label 'Giro transfer';
        XBANK: Label 'BANK';
        XBanktransfer: Label 'Bank Transfer';
        XBANKDOMTxt: Label 'BNKCONVDOM', Locked = true;
        XBankDomTransferTxt: Label 'Bank Data Conversion for Domestic Banks';
        XBANKINTTxt: Label 'BNKCONVINT', Locked = true;
        XBankIntTransferTxt: Label 'Bank Data Conversion for International Banks';
        XCASH: Label 'CASH';
        XCashpayment: Label 'Cash payment';
        XCHECK: Label 'CHECK';
        XCheckpayment: Label 'Check payment';
        XACCOUNT: Label 'ACCOUNT';
        XPaymentonaccount: Label 'Payment on account';
        XINTERCOM: Label 'INTERCOM';
        XIntercompanypayment: Label 'Intercompany payment';
        XBankDataConvPmtLineDefnTxt: Label 'BANKDATACONVSERVCT', Locked = true;
        XCARD: Label 'CARD', Comment = 'Card';
        XCardpayment: Label 'Card payment';
        XMultiple: Label 'MULTIPLE', Comment = 'Multiple payment methods';
        XMultiplepaymentmethods: Label 'Multiple payment methods';
        XCASHDESK01: Label 'CASHDESK01';
        XCashPayment01: Label 'Cash payment on cash desk 01';
        XCOD: Label 'COD', Comment = 'Cash on delivery';
        XCashondeliverypayment: Label 'Cash on delivery payment';
        XCOMPENS: Label 'COMPENS';
        XPaidbycompensation: Label 'Paid by compensation';

    procedure InsertMiniAppData()
    begin
        InsertData(XBANK, XBanktransfer, "Payment Method"."Bal. Account Type"::"G/L Account", '', '');
        InsertData(XBANKDOMTxt, XBankDomTransferTxt, "Payment Method"."Bal. Account Type"::"G/L Account", '', XBankDataConvPmtLineDefnTxt);
        InsertData(XBANKINTTxt, XBankIntTransferTxt, "Payment Method"."Bal. Account Type"::"G/L Account", '', XBankDataConvPmtLineDefnTxt);
        InsertData(XCASH, XCashpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', '');
        // NAVCZ
        InsertData(XACCOUNT, XPaymentonaccount, "Payment Method"."Bal. Account Type"::"G/L Account", '', '');
        InsertData(XINTERCOM, XIntercompanypayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', '');
        InsertData(XCARD, XCardpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', '');
        InsertData(XMultiple, XMultiplepaymentmethods, "Payment Method"."Bal. Account Type"::"G/L Account", '', '');
        // NAVCZ
        InsertData(XCOD, XCashondeliverypayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', '');
        InsertData(XCOMPENS, XPaidbycompensation, "Payment Method"."Bal. Account Type"::"G/L Account", '', '');
        // NAVCZ
    end;

    procedure InsertData("Code": Code[10]; Description: Text[50]; "Bal. Account Type": Enum "Payment Balance Account Type"; "Bal. Account No.": Code[20]; PmtExportLineDefn: Code[20])
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
        // NAVCZ
        if "Payment Method".Code = XCASHDESK01 then begin
            "Payment Method"."Cash Desk Code CZP" := 'POK01';
            "Payment Method"."Cash Document Action CZP" := "Payment Method"."Cash Document Action CZP"::Post;
        end;
        // NAVCZ
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

