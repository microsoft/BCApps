codeunit 101289 "Create Payment Method"
{

    trigger OnRun()
    begin
        InsertData(XxWWBUSD, XGirotransfer, "Payment Method"."Bal. Account Type"::"Bank Account", XxWWBUSD, '', '');
        InsertData(XBANK, XBanktransfer, "Payment Method"."Bal. Account Type"::"G/L Account", '', '', '');
        InsertData(XBANKDOMTxt, XBankDomTransferTxt, "Payment Method"."Bal. Account Type"::"G/L Account", '', '', XBankDataConvPmtLineDefnTxt);
        InsertData(XBANKINTTxt, XBankIntTransferTxt, "Payment Method"."Bal. Account Type"::"G/L Account", '', '', XBankDataConvPmtLineDefnTxt);
        InsertData(XCASH, XCashpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '992910', '', '');
        InsertData(XCHECK, XCheckpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', '', '');
        InsertData(XACCOUNT, XPaymentonaccount, "Payment Method"."Bal. Account Type"::"G/L Account", '', '', '');
        InsertData(XINTERCOM, XIntercompanypayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', '', '');
        //BEGIN IT
        InsertData(XxBANKTRANSF, XBanktransfer, "Payment Method"."Bal. Account Type"::"G/L Account", '', XxBB, '');
        InsertData(XxRIBA, XBankReceipt, "Payment Method"."Bal. Account Type"::"G/L Account", '', XxRB, '');
        //END IT
        InsertData(XCARD, XCardpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', '', '');
        InsertData(XMultiple, XMultiplepaymentmethods, "Payment Method"."Bal. Account Type"::"G/L Account", '', '', '');
    end;

    var
        XxWWBUSD: Label 'WWB-USD';
        XxBANKTRANSF: Label 'BANKTRANSF';
        XxBB: Label 'BB';
        XxRIBA: Label 'RIBA';
        XBankReceipt: Label 'Bank Receipt';
        XxRB: Label 'RB';
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
        XBankDataConvPmtLineDefnTxt: Label 'BANKDATACONVSERVCT', Locked = true;
        XCARD: Label 'CARD', Comment = 'Card';
        XCardpayment: Label 'Card payment';
        XMultiple: Label 'MULTIPLE', Comment = 'Multiple payment methods';
        XMultiplepaymentmethods: Label 'Multiple payment methods';

    procedure InsertMiniAppData()
    begin
        InsertData(XGIRO, XGirotransfer, "Payment Method"."Bal. Account Type"::"Bank Account", '', '', '');
        InsertData(XBANK, XBanktransfer, "Payment Method"."Bal. Account Type"::"G/L Account", '', '', '');
        InsertData(XBANKDOMTxt, XBankDomTransferTxt, "Payment Method"."Bal. Account Type"::"G/L Account", '', '', XBankDataConvPmtLineDefnTxt);
        InsertData(XBANKINTTxt, XBankIntTransferTxt, "Payment Method"."Bal. Account Type"::"G/L Account", '', '', XBankDataConvPmtLineDefnTxt);
        InsertData(XCASH, XCashpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '992910', '', '');
        InsertData(XCHECK, XCheckpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', '', '');
        InsertData(XACCOUNT, XPaymentonaccount, "Payment Method"."Bal. Account Type"::"G/L Account", '', '', '');
        InsertData(XINTERCOM, XIntercompanypayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', '', '');
        InsertData(XxBANKTRANSF, XBanktransfer, "Payment Method"."Bal. Account Type"::"G/L Account", '', XxBB, '');
        InsertData(XxRIBA, XBankReceipt, "Payment Method"."Bal. Account Type"::"G/L Account", '', XxRB, '');
        InsertData(XCARD, XCardpayment, "Payment Method"."Bal. Account Type"::"G/L Account", '', '', '');
        InsertData(XMultiple, XMultiplepaymentmethods, "Payment Method"."Bal. Account Type"::"G/L Account", '', '', '');
    end;

    procedure InsertData("Code": Code[10]; Description: Text[50]; "Bal. Account Type": Enum "Payment Balance Account Type"; "Bal. Account No.": Code[20]; "Bill Code": Code[20]; PmtExportLineDefn: Code[20])
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
        "Payment Method"."Bill Code" := "Bill Code";//IT
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

