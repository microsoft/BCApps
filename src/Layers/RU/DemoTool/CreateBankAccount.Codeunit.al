codeunit 101270 "Create Bank Account"
{

    trigger OnRun()
    begin
        "Create No. Series".InsertSeriesOnly(BankAcc."Bank Payment Order No. Series",
          XB + '-01_1_RUR', XOutgoingPaymentOrders + ' RUR', true, false, true);
        "Create No. Series".InsertSeriesLine(BankAcc."Bank Payment Order No. Series", XOPO + 'RUR-1', 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(BankAcc."Bank Payment Order No. Series", XOPO + 'RUR-1', 20000, 19030101D, 1);
        InsertData(
          XNBL, XNewBankofLondon, X4BakerStreet, CreatePostCode.Convert('GB-W1 3AL'),
          XHollyDickson, '', '51-1001', '40702810700700700000', '', '', '30101810500000000000', '044525219');

        "Create No. Series".InsertSeriesOnly(BankAcc."Bank Payment Order No. Series",
          XB + '-01_1_EUR', XOutgoingPaymentOrders + ' EUR', true, false, true);
        "Create No. Series".InsertSeriesLine(BankAcc."Bank Payment Order No. Series", XOPO + 'EUR-1', 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(BankAcc."Bank Payment Order No. Series", XOPO + 'EUR-1', 20000, 19030101D, 1);
        InsertData(
          XWWBEUR, XWorldWideBank, X1HighHolborn, CreatePostCode.Convert('GB-WC1 3DG'),
          XGrantCulbertson, XEUR, '52-2002', '40702978100700700000', '', XGB80RBOS16173241116737, '30101810300000000000', '044525202');
        SetSEPAExport();

        "Create No. Series".InsertSeriesOnly(BankAcc."Bank Payment Order No. Series",
          XB + '-01_1_USD', XOutgoingPaymentOrders + ' USD', true, false, true);
        "Create No. Series".InsertSeriesLine(BankAcc."Bank Payment Order No. Series", XOPO + 'USD-1', 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(BankAcc."Bank Payment Order No. Series", XOPO + 'USD-1', 20000, 19030101D, 1);
        InsertData(
          XWWBUSD, XWorldWideBank, X1HighHolborn, CreatePostCode.Convert('GB-WC1 3DG'),
          XGrantCulbertson, XUSD, '52-1001', '40702840500700700000', '', '', '30101810300000000000', '044525202');

        "Create No. Series".InsertSeriesOnly(BankAcc."Bank Payment Order No. Series",
          XB + '-01_2_RUR', XOutgoingPaymentOrders + ' RUR', true, false, true);
        "Create No. Series".InsertSeriesLine(BankAcc."Bank Payment Order No. Series", XOPO + 'RUR-2', 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(BankAcc."Bank Payment Order No. Series", XOPO + 'RUR-2', 20000, 19030101D, 1);
        InsertData(
          XWWBRUR, XWorldWideBank, X1HighHolborn, CreatePostCode.Convert('GB-WC1 3DG'),
          XGrantCulbertson, '', '51-1002', '40702840500700700000', '', '', '30101810300000000000', '044525202');

        "Create No. Series".InsertSeriesOnly(BankAcc."Debit Cash Order No. Series",
          XC + '-02_1', XIngoingCashOrders, true, false, true);
        "Create No. Series".InsertSeriesLine(BankAcc."Debit Cash Order No. Series", XICO + '-1', 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(BankAcc."Debit Cash Order No. Series", XICO + '-1', 20000, 19030101D, 1);
        "Create No. Series".InsertSeriesOnly(BankAcc."Credit Cash Order No. Series",
          XC + '-03_1', XOutgoingCashOrders, true, false, true);
        "Create No. Series".InsertSeriesLine(BankAcc."Credit Cash Order No. Series", XOCO + '-1', 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(BankAcc."Credit Cash Order No. Series", XOCO + '-1', 20000, 19030101D, 1);
        InsertData(
          XCASH + '1', XCashDesk + ' 1', '', '',
          XPaulaNartker, '', '50-1000', '', '', '', '', '');

        "Create No. Series".InsertSeriesOnly(BankAcc."Debit Cash Order No. Series",
          XC + '-02_2', XIngoingCashOrders, true, false, true);
        "Create No. Series".InsertSeriesLine(BankAcc."Debit Cash Order No. Series", XICO + '-2', 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(BankAcc."Debit Cash Order No. Series", XICO + '-2', 20000, 19030101D, 1);
        "Create No. Series".InsertSeriesOnly(BankAcc."Credit Cash Order No. Series",
          XC + '-03_2', XOutgoingCashOrders, true, false, true);
        "Create No. Series".InsertSeriesLine(BankAcc."Credit Cash Order No. Series", XOCO + '-2', 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(BankAcc."Credit Cash Order No. Series", XOCO + '-2', 20000, 19030101D, 1);
        InsertData(
          XCASH + '2', XCashDesk + ' 2', '', '',
          XPaulaNartker, '', '50-1004', '', '', '', '', '');
        InsertData(
          XWWBTRANSFERSTxt, XWorldWideBank, X1HighHolborn, CreatePostCode.Convert('GB-WC1 3DG'),
          XGrantCulbertson, XGBPTok, '52-2002', '40702978100700700000', '', '', '30101810300000000000', '044525202');
    end;

    var
        BankAcc: Record "Bank Account";
        CA: Codeunit "Make Adjustments";
        CreatePostCode: Codeunit "Create Post Code";
        XSEPACTMSGTxt: Label 'SEPACT-MSG', Comment = 'SEPA Credit Transfer Message';
        XSEPACTMessageIDTxt: Label 'SEPA Credit Transfer Msg. ID', Comment = 'Msg. = Message';
        XSEPADDMSGTxt: Label 'SEPADD-MSG', Comment = 'SEPA Direct Debit Message';
        XSEPADDMessageIDTxt: Label 'SEPA Direct Debit Msg. ID', Comment = 'Msg. = Message';
        XNBL: Label 'NBL';
        XNewBankofLondon: Label 'New Bank of London';
        X4BakerStreet: Label '4 Baker Street';
        XHollyDickson: Label 'Holly Dickson';
        XWWBEUR: Label 'WWB-EUR';
        XWorldWideBank: Label 'World Wide Bank';
        X1HighHolborn: Label '1 High Holborn';
        XGrantCulbertson: Label 'Grant Culbertson';
        XEUR: Label 'EUR';
        XWWBOPERATING: Label 'WWB-OPERATING';
        XWWBUSD: Label 'WWB-USD';
        XUSD: Label 'USD';
        XGBPTok: Label 'GBP', Locked = true;
        XPaulaNartker: Label 'Paula Nartker';
        XOF: Label 'OF';
        XGB80RBOS16173241116737: Label 'GB 80 RBOS 161732 41116737';
        XCASH: Label 'CASH';
        XCashDesk: Label 'Cash Desk';
        "Create No. Series": Codeunit "Create No. Series";
        XWWBRUR: Label 'WWB-RUR';
        XIngoingCashOrders: Label 'Ingoing Cash Orders';
        XICO: Label 'ICO';
        XOutgoingCashOrders: Label 'Outgoing Cash Orders';
        XOCO: Label 'OCO';
        XOutgoingPaymentOrders: Label 'Outgoing Payment Orders';
        XOPO: Label 'OPO';
        XC: Label 'C';
        XB: Label 'B';
        XWWBTRANSFERSTxt: Label 'WWB-TRANSFERS', Locked = true;
        XSEPACAMTImpFmtTxt: Label 'SEPA CAMT', Locked = true;
        PmtRecNoSeriesTok: Label 'PREC', Locked = true;
        PmtRecNoSeriesDescriptionTxt: Label 'Payment Reconciliation Journals';
        PmtRecNoSeriesStartNoTok: Label 'PREC001', Locked = true;
        PmtRecNoSeriesEndNoTok: Label 'PREC999', Locked = true;

    procedure InsertData("No.": Code[20]; Name: Text[30]; Address: Text[30]; "Post Code": Text[30]; Contact: Text[30]; "Currency Code": Code[10]; "Posting Group": Code[20]; "Bank Account No.": Text[30]; "Bank Branch No.": Text[20]; IBAN: Code[50]; "Bank Corr. Account No.": Code[30]; "Bank BIC": Code[20])
    var
        DemoDataSetup: Record "Demo Data Setup";
        "Create No. Series": Codeunit "Create No. Series";
    begin
        BankAcc.Init();
        BankAcc.Validate("No.", "No.");
        BankAcc.Validate(Name, Name);
        BankAcc.Validate(Address, Address);
        BankAcc."Post Code" := CreatePostCode.FindPostCode("Post Code");
        BankAcc.City := CreatePostCode.FindCity("Post Code");
        BankAcc.Validate(Contact, Contact);
        DemoDataSetup.Get();
        if "Currency Code" = DemoDataSetup."Currency Code" then
            "Currency Code" := '';
        BankAcc.Validate("Currency Code", "Currency Code");
        BankAcc.Validate("Bank Acc. Posting Group", "Posting Group");
        BankAcc.Validate("Bank Branch No.", "Bank Branch No.");
        BankAcc.Validate("Bank Account No.", "Bank Account No.");
        BankAcc.Validate("Bank Corresp. Account No.", "Bank Corr. Account No.");
        BankAcc.Validate("Bank BIC", "Bank BIC");
        BankAcc.Validate(IBAN, IBAN);
        BankAcc.Validate("Statistics Group", 0);
        BankAcc.Validate("Last Date Modified", CA.AdjustDate(19030118D));
        case BankAcc."No." of
            XWWBOPERATING:
                begin
                    BankAcc.Validate(
                      "Min. Balance",
                      Round(
                        -8000000 * DemoDataSetup."Local Currency Factor",
                        1000 * DemoDataSetup."Local Precision Factor"));
                    BankAcc.Validate("Bank Statement Import Format", XSEPACAMTImpFmtTxt);
                    "Create No. Series".InitBaseSeries(BankAcc."Pmt. Rec. No. Series", PmtRecNoSeriesTok, PmtRecNoSeriesDescriptionTxt, PmtRecNoSeriesStartNoTok, PmtRecNoSeriesEndNoTok, PmtRecNoSeriesStartNoTok, '', 1, Enum::"No. Series Implementation"::Sequence);
                    BankAcc."Last Check No." := '199';
                    BankAcc."Last Statement No." := '23';
                end;
            XNBL:
                BankAcc."Last Statement No." := '4';
        end;

        BankAcc.Validate("Our Contact Code", XOF);
        case true of
            BankAcc."No." = XCASH + '1':
                begin
                    BankAcc.Validate("Account Type", BankAcc."Account Type"::"Cash Account");
                    BankAcc."VAT % for Document" := 20;
                    BankAcc."Last Cash Report Page No." := '001';
                    BankAcc.Validate("Debit Cash Order No. Series", XC + '-02_1');
                    BankAcc.Validate("Credit Cash Order No. Series", XC + '-03_1');
                end;
            BankAcc."No." = XCASH + '2':
                begin
                    BankAcc.Validate("Account Type", BankAcc."Account Type"::"Cash Account");
                    BankAcc."VAT % for Document" := 20;
                    BankAcc."Last Cash Report Page No." := '001';
                    BankAcc.Validate("Debit Cash Order No. Series", XC + '-02_2');
                    BankAcc.Validate("Credit Cash Order No. Series", XC + '-03_2');
                end;
            BankAcc."No." = XNBL:
                BankAcc.Validate("Bank Payment Order No. Series", XB + '-01_1_RUR');
            BankAcc."No." = XWWBRUR:
                BankAcc.Validate("Bank Payment Order No. Series", XB + '-01_2_RUR');
            BankAcc."No." = XWWBUSD:
                BankAcc.Validate("Bank Payment Order No. Series", XB + '-01_1_USD');
            BankAcc."No." = XWWBEUR:
                BankAcc.Validate("Bank Payment Order No. Series", XB + '-01_1_EUR');
        end;
        BankAcc.Insert(true);
    end;

    internal procedure GetSavingsBankAccountCode(): Code[20]
    begin
        exit(XNBL);
    end;

    internal procedure GetCheckingBankAccountCode(): Code[20]
    begin
        exit(XWWBEUR);
    end;

    local procedure SetSEPAExport()
    var
        CreateNoSeries: Codeunit "Create No. Series";
        CompanyInitialize: Codeunit "Company-Initialize";
    begin
        BankAcc."Payment Export Format" := CompanyInitialize.GetSEPACT09Code();
        CreateNoSeries.InitTempSeries(BankAcc."Credit Transfer Msg. Nos.", XSEPACTMSGTxt, XSEPACTMessageIDTxt);
        BankAcc."SEPA Direct Debit Exp. Format" := CompanyInitialize.GetSEPADD08Code();
        CreateNoSeries.InitTempSeries(BankAcc."Direct Debit Msg. Nos.", XSEPADDMSGTxt, XSEPADDMessageIDTxt);
        BankAcc.Modify();
    end;

}

