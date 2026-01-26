codeunit 161006 "Create Payment Order"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        // Settle payable document
        SettlePayableDoc();
        Commit();
        // Create payment order
        InsertData(XNBL, CalcDate('<CY-2Y+2M+1D>'));
        // Insert documents in new payment order
        CarteraDoc.Reset();
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Payable);
        CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Bill);
        CarteraDoc.SetRange("Collection Agent", CarteraDoc."Collection Agent"::Bank);
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", '');
        CarteraDoc.Find('-');
        FinanceCoType := CarteraDoc."Collection Agent"::Bank;
        PmtOrdNo := PmtOrd."No.";
        for i := 1 to 2 do begin
            CarteraDoc.TestField("Collection Agent", FinanceCoType);
            CarteraDoc.TestField("Bill Gr./Pmt. Order No.", '');
            CarteraDoc.TestField("Currency Code", '');
            CarteraDoc.TestField(Type, CarteraDoc.Type::Payable);
            if CarteraDoc.Accepted = CarteraDoc.Accepted::No then
                CarteraDoc.FieldError(Accepted);
            OldCarteraDoc := CarteraDoc;
            CarteraDoc."Collection Agent" := FinanceCoType;
            CarteraDoc."Bill Gr./Pmt. Order No." := PmtOrdNo;
            CarteraDoc.Modify();
            CarteraDoc := OldCarteraDoc;
            CarteraDoc.Next();
        end;
        CarteraDoc.Reset();
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Payable);
        CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Invoice);
        CarteraDoc.SetRange("Collection Agent", CarteraDoc."Collection Agent"::Bank);
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", '');
        CarteraDoc.Find('-');
        FinanceCoType := CarteraDoc."Collection Agent"::Bank;
        PmtOrdNo := PmtOrd."No.";
        for i := 1 to 1 do begin
            CarteraDoc.TestField("Collection Agent", FinanceCoType);
            CarteraDoc.TestField("Bill Gr./Pmt. Order No.", '');
            CarteraDoc.TestField("Currency Code", '');
            CarteraDoc.TestField(Type, CarteraDoc.Type::Payable);
            if CarteraDoc.Accepted = CarteraDoc.Accepted::No then
                CarteraDoc.FieldError(Accepted);
            OldCarteraDoc := CarteraDoc;
            CarteraDoc."Collection Agent" := FinanceCoType;
            CarteraDoc."Bill Gr./Pmt. Order No." := PmtOrdNo;
            CarteraDoc.Modify();
            CarteraDoc := OldCarteraDoc;
            CarteraDoc.Next();
        end;

        // Modify Acc. 6260001 to post journal
        if CGCta.Get('6260001') then begin
            CGCta."Gen. Posting Type" := CGCta."Gen. Posting Type"::" ";
            CGCta."Gen. Bus. Posting Group" := '';
            CGCta."Gen. Prod. Posting Group" := '';
            CGCta.Modify();
        end;

        // Post group
        PmtOrd.SetRecFilter();
        PostPmtOrd.SetHidePrintDialog(true);
        PostPmtOrd.SetTableView(PmtOrd);
        PostPmtOrd.UseRequestPage(false);
        PostPmtOrd.InitReqForm(XCARTERA, XDEFAULT);
        PostPmtOrd.RunModal();

        Clear(PostPmtOrd);

        // Create one more group
        InsertData(XWWBEUR, CalcDate('<CY-2Y+2M+1D>'));
        // Insert Docs. in new payment order
        CarteraDoc.Reset();
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Payable);
        CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Bill);
        CarteraDoc.SetRange("Collection Agent", CarteraDoc."Collection Agent"::Bank);
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", '');
        CarteraDoc.Find('-');
        FinanceCoType := CarteraDoc."Collection Agent"::Bank;
        PmtOrdNo := PmtOrd."No.";
        for i := 1 to 2 do begin
            CarteraDoc.TestField("Collection Agent", FinanceCoType);
            CarteraDoc.TestField("Bill Gr./Pmt. Order No.", '');
            CarteraDoc.TestField("Currency Code", '');
            CarteraDoc.TestField(Type, CarteraDoc.Type::Payable);
            if CarteraDoc.Accepted = CarteraDoc.Accepted::No then
                CarteraDoc.FieldError(Accepted);
            OldCarteraDoc := CarteraDoc;
            CarteraDoc."Collection Agent" := FinanceCoType;
            CarteraDoc."Bill Gr./Pmt. Order No." := PmtOrdNo;
            CarteraDoc.Modify();
            CarteraDoc := OldCarteraDoc;
            CarteraDoc.Next();
        end;

        // Post group
        PmtOrd.SetRecFilter();
        PostPmtOrd.SetHidePrintDialog(true);
        PostPmtOrd.SetTableView(PmtOrd);
        PostPmtOrd.UseRequestPage(false);
        PostPmtOrd.InitReqForm(XCARTERA, XDEFAULT);
        PostPmtOrd.RunModal();

        // Create one more group
        InsertData(XNBL, CalcDate('<CY-2Y+2M+1D>'));
        // Insert Docs. in new payment order
        CarteraDoc.Reset();
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Payable);
        CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Bill);
        CarteraDoc.SetRange("Collection Agent", CarteraDoc."Collection Agent"::Bank);
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", '');
        CarteraDoc.Find('-');
        FinanceCoType := CarteraDoc."Collection Agent"::Bank;
        PmtOrdNo := PmtOrd."No.";
        for i := 1 to 2 do begin
            CarteraDoc.TestField("Collection Agent", FinanceCoType);
            CarteraDoc.TestField("Bill Gr./Pmt. Order No.", '');
            CarteraDoc.TestField("Currency Code", '');
            CarteraDoc.TestField(Type, CarteraDoc.Type::Payable);
            if CarteraDoc.Accepted = CarteraDoc.Accepted::No then
                CarteraDoc.FieldError(Accepted);
            OldCarteraDoc := CarteraDoc;
            CarteraDoc."Collection Agent" := FinanceCoType;
            CarteraDoc."Bill Gr./Pmt. Order No." := PmtOrdNo;
            CarteraDoc.Modify();
            CarteraDoc := OldCarteraDoc;
            CarteraDoc.Next();
        end;

        // Post settlement
        WorkDate(20080124D);
        PostedDoc.SetRange("Bill Gr./Pmt. Order No.", '109001');
        PostedDoc.Find('-');
        SettleDocsInPostedPO.SetHidePrintDialog(true);
        SettleDocsInPostedPO.SetTableView(PostedDoc);
        SettleDocsInPostedPO.UseRequestPage(false);
        SettleDocsInPostedPO.RunModal();

        GenJnlLine.SetRange("Journal Template Name", XCARTERA);
        GenJnlLine.SetRange("Journal Batch Name", XDEFAULT);
        if GenJnlLine.Find('-') then
            repeat
                GJPostLine.Run(GenJnlLine);
            until GenJnlLine.Next() = 0;
        GenJnlLine.DeleteAll();

        if CGCta.Get('6260001') then begin
            CGCta."Gen. Posting Type" := CGCta."Gen. Posting Type"::Purchase;
            CGCta."Gen. Bus. Posting Group" := DemoDataSetup.DomesticCode();
            CGCta."Gen. Prod. Posting Group" := DemoDataSetup.MiscCode();
            CGCta.Modify();
        end;
    end;

    var
        CarteraDoc: Record "Cartera Doc.";
        OldCarteraDoc: Record "Cartera Doc.";
        GJPostLine: Codeunit "Gen. Jnl.-Post Line";
        FinanceCoType: Integer;
        PmtOrdNo: Code[20];
        i: Integer;
        PmtOrd: Record "Payment Order";
        PostPmtOrd: Report "Post Payment Order";
        SettleDocsInPostedPO: Report "Settle Docs. in Posted PO";
        PostedDoc: Record "Posted Cartera Doc.";
        GenJnlLine: Record "Gen. Journal Line";
        CGCta: Record "G/L Account";
        DemoDataSetup: Record "Demo Data Setup";
        XNBL: Label 'NBL';
        XCARTERA: Label 'CARTERA';
        XDEFAULT: Label 'DEFAULT';
        XWWBEUR: Label 'WWB-EUR';
        XPAYMENT: Label 'PAYMENT';
        XLewisHomeFurniture: Label 'Lewis Home Furniture';
        XEH: Label 'EH';
        XBANK: Label 'BANK';
        XPAYMENTJNL: Label 'PAYMENTJNL';
        XBANKBILLGROUP: Label 'Bank Bill Group %1';

    procedure InsertData("Company No.": Code[20]; "Posting Date": Date)
    begin
        Clear(PmtOrd);
        PmtOrd.Validate("No.", '');
        PmtOrd."Posting Date" := "Posting Date";
        PmtOrd.Insert(true);
        // PmtOrd."Posting Description" := 'Bank Bill Group ' + PmtOrd."No.";
        PmtOrd."Posting Description" := StrSubstNo(XBANKBILLGROUP, PmtOrd."No.");
        PmtOrd."Bank Account No." := "Company No.";
        PmtOrd.Validate("Bank Account No.", "Company No.");
        PmtOrd.Validate("Posting Date", "Posting Date");
        PmtOrd.Modify();
    end;

    procedure SettlePayableDoc()
    var
        CarteraDoc2: Record "Cartera Doc.";
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        CarteraDoc2.Reset();
        CarteraDoc2.SetRange(Type, CarteraDoc2.Type::Payable);
        CarteraDoc2.SetRange("Document Type", CarteraDoc2."Document Type"::Bill);
        CarteraDoc2.SetRange("Collection Agent", CarteraDoc2."Collection Agent"::Bank);
        CarteraDoc2.SetRange("Bill Gr./Pmt. Order No.", '');
        CarteraDoc2.Find('-');
        GenJnlLine2.Init();
        GenJnlLine2.Validate("Journal Template Name", XPAYMENT);
        GenJnlLine2.Validate("Line No.", 10000);
        GenJnlLine2.Validate("Account Type", GenJnlLine2."Account Type"::Vendor);
        GenJnlLine2.Validate(GenJnlLine2."Account No.", CarteraDoc2."Account No.");
        GenJnlLine2.Validate(GenJnlLine2."Posting Date", CarteraDoc2."Posting Date");
        GenJnlLine2.Validate("Document Type", GenJnlLine2."Document Type"::Payment);
        GenJnlLine2.Validate("Document No.", 'G04001');
        GenJnlLine2.Validate(Description, XLewisHomeFurniture);
        GenJnlLine2.Validate(GenJnlLine2.Amount, CarteraDoc2."Remaining Amount");
        GenJnlLine2.Validate("Posting Group", DemoDataSetup.DomesticCode());
        GenJnlLine2.Validate("Salespers./Purch. Code", XEH);
        GenJnlLine2.Validate("Source Code", XPAYMENTJNL);
        GenJnlLine2.Validate("System-Created Entry", false);
        GenJnlLine2.Validate("Applies-to Doc. Type", GenJnlLine2."Applies-to Doc. Type"::Bill);
        GenJnlLine2.Validate(GenJnlLine2."Applies-to Doc. No.", CarteraDoc2."Document No.");
        GenJnlLine2.Validate(GenJnlLine2."Due Date", CarteraDoc2."Due Date");
        GenJnlLine2.Validate("Journal Batch Name", XBANK);
        GenJnlLine2.Validate("VAT Calculation Type", GenJnlLine2."VAT Calculation Type"::"Normal VAT");
        GenJnlLine2.Validate("Bal. Account Type", GenJnlLine2."Bal. Account Type"::"Bank Account");
        GenJnlLine2.Validate("Bal. Account No.", XNBL);
        GenJnlLine2.Validate("Applies-to Bill No.", '1');
        GenJnlLine2.Validate(GenJnlLine2."Recipient Bank Account", CarteraDoc2."Cust./Vendor Bank Acc. Code");
        GenJnlLine2.Validate(GenJnlLine2."Payment Method Code", CarteraDoc2."Payment Method Code");

        GJPostLine.SetFromSettlement(true);
        GJPostLine.Run(GenJnlLine2);

        // GJPostLine.RUN(GenJnlLine2);
        Clear(GJPostLine);
    end;
}

