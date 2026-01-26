codeunit 101270 "Create Bank Account"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
            InsertData(
              XNBL, XNewBankofLondon, X4BakerStreet, CreatePostCode.Convert('GB-N12 5XY'),
              XHollyDickson, '', XLCY, '7866345', 'GB-W1 3AL', '', '36558', '22508');
            InsertData(
              XWWBEUR, XWorldWideBank, X1HighHolborn, CreatePostCode.Convert('GB-WC1 3DG'),
              XGrantCulbertson, '', XLCY, '9933456', '98765', XGB80RBOS16173241116737, '56200', '45007');
            SetSEPAExport();
            InsertData(
              XWWBOPERATING, XWorldWideBank, X1HighHolborn, CreatePostCode.Convert('GB-WC1 3DG'),
              XGrantCulbertson, '', XOPERATING, '9999888', '35678', '', '52714', '10180');
            InsertData(
              XxNBLOPERATING, XNewBankofLondon, X4BakerStreet, CreatePostCode.Convert('GB-N12 5XY'),
              XCharlesDickens, XUSD, XOPERATING, '9944567', '890-90', '', '85400', '45600');
            InsertData(
              XWWBUSD, XWorldWideBank, X1HighHolborn, 'GB-WC1 3DG',
              XGrantCulbertson, '', XLCY2, '1455678', '567-098', XGB80RBOS16173241116737, '52001', '56300');
            InsertData(
              XWWBTRANSFERSTxt, XWorldWideBank, X1HighHolborn, CreatePostCode.Convert('GB-WC1 3DG'),
              XGrantCulbertson, XGBPTok, XLCY, '9944567', '890-90', '', '85400', '45600');
            InsertData(
              XGIRO, XGiroBank, X2BridgeStreet, CreatePostCode.Convert('GB-W1 3AL'),
              XPaulaNartker, '', XLCY2, '1455678', XO284033, XGB80RBOS16173241116737, '52001', '56300');
        end else begin
            InsertData(
              XCHECKING, XWorldWideBank, X1HighHolborn, CreatePostCode.Convert('GB-WC1 3DG'),
              XGrantCulbertson, '', XCHECKING, '9999888', '35678', '', '52714', '10180');
            SetAsBalAccOnGenJnlBatch(XCHECKING);
            InsertData(
              XSAVINGS, XWorldWideBank, X1HighHolborn, CreatePostCode.Convert('GB-WC1 3DG'),
              XGrantCulbertson, '', XSAVINGS, '9999888', '35678', '', '52714', '10180');
        end;
    end;

    var
        XxNBLOPERATING: Label 'NBL-OPERATING';
        XCharlesDickens: Label 'Charles Dickens';
        XO284033: Label 'O284033';
        BankAcc: Record "Bank Account";
        DemoDataSetup: Record "Demo Data Setup";
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
        XLCY: Label 'LCY';
        XWWBEUR: Label 'WWB-EUR';
        XWorldWideBank: Label 'World Wide Bank';
        X1HighHolborn: Label '1 High Holborn';
        XGrantCulbertson: Label 'Grant Culbertson';
        XWWBOPERATING: Label 'WWB-OPERATING';
        XOPERATING: Label 'OPERATING';
        XWWBUSD: Label 'WWB-USD';
        XUSD: Label 'USD';
        XGBPTok: Label 'GBP', Locked = true;
        XGIRO: Label 'GIRO';
        XGiroBank: Label 'Giro Bank';
        X2BridgeStreet: Label '2 Bridge Street';
        XPaulaNartker: Label 'Paula Nartker';
        XLCY2: Label 'LCY2';
        XOF: Label 'OF';
        XGB80RBOS16173241116737: Label 'GB 80 RBOS 161732 41116737';
        XWWBTRANSFERSTxt: Label 'WWB-TRANSFERS', Locked = true;
        XSEPACAMTImpFmtTxt: Label 'SEPA CAMT', Locked = true;
        XCHECKING: Label 'CHECKING', Comment = 'To be translated.', MaxLength = 20;
        XSAVINGS: Label 'SAVINGS', Comment = 'To be translated.', MaxLength = 20;
        PmtRecNoSeriesTok: Label 'PREC', Locked = true;
        PmtRecNoSeriesDescriptionTxt: Label 'Payment Reconciliation Journals';
        PmtRecNoSeriesStartNoTok: Label 'PREC001', Locked = true;
        PmtRecNoSeriesEndNoTok: Label 'PREC999', Locked = true;

    procedure InsertData("No.": Code[20]; Name: Text[30]; Address: Text[30]; "Post Code": Text[30]; Contact: Text[30]; "Currency Code": Code[10]; "Posting Group": Code[20]; "Bank Account No.": Text[30]; "Bank Branch No.": Text[20]; IBAN: Code[50]; ABI: Code[5]; CAB: Code[5])
    var
        "No. Series": Record "No. Series";
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
        BankAcc.Validate(IBAN, IBAN);
        BankAcc.Validate("Statistics Group", 0);
        BankAcc.Validate("Last Date Modified", CA.AdjustDate(19030118D));

        case BankAcc."No." of
            XWWBOPERATING,
            XCHECKING:
                begin
                    BankAcc.Validate(
                      "Min. Balance",
                      Round(
                        -8000000 * DemoDataSetup."Local Currency Factor",
                        1000 * DemoDataSetup."Local Precision Factor"));
                    BankAcc.Validate("Bank Statement Import Format", XSEPACAMTImpFmtTxt);
                    "Create No. Series".InitBaseSeries(BankAcc."Pmt. Rec. No. Series", PmtRecNoSeriesTok, PmtRecNoSeriesDescriptionTxt, PmtRecNoSeriesStartNoTok, PmtRecNoSeriesEndNoTok, PmtRecNoSeriesStartNoTok, '', 1, "No. Series"."No. Series Type"::Normal, '', 0, '', false,  Enum::"No. Series Implementation"::Sequence);
                    BankAcc."Last Check No." := '199';
                    BankAcc."Last Statement No." := '23';
                end;
            'NBL':
                BankAcc."Last Statement No." := '4';
        end;

        BankAcc.Validate("Our Contact Code", XOF);

        //BEGIN IT
        BankAcc.Validate(ABI, ABI);
        BankAcc.Validate(CAB, CAB);
        //END IT

        BankAcc.Insert(true);
    end;

    internal procedure GetSavingsBankAccountCode(): Code[20]
    begin
        exit(XSAVINGS);
    end;

    internal procedure GetCheckingBankAccountCode(): Code[20]
    begin
        exit(XCHECKING);
    end;

    local procedure SetSEPAExport()
    var
        "No. Series": Record "No. Series";
        CreateNoSeries: Codeunit "Create No. Series";
        CompanyInitialize: Codeunit "Company-Initialize";
    begin
        BankAcc."Payment Export Format" := CompanyInitialize.GetSEPACT09Code();
        CreateNoSeries.InitTempSeries(BankAcc."Credit Transfer Msg. Nos.", XSEPACTMSGTxt, XSEPACTMessageIDTxt,
          "No. Series"."No. Series Type"::Normal, '', 0, '', false);
        BankAcc."SEPA Direct Debit Exp. Format" := CompanyInitialize.GetSEPADD08Code();
        CreateNoSeries.InitTempSeries(BankAcc."Direct Debit Msg. Nos.", XSEPADDMSGTxt, XSEPADDMessageIDTxt,
          "No. Series"."No. Series Type"::Normal, '', 0, '', false);
        BankAcc.Modify();
    end;

    local procedure SetAsBalAccOnGenJnlBatch(BankAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.SetRange("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.SetRange("Bal. Account No.", '');
        GenJournalBatch.ModifyAll("Bal. Account No.", BankAccountNo, true);
    end;
}

