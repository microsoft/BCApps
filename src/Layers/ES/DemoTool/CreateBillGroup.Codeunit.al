codeunit 161005 "Create Bill Group"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        // Settle receivable document ( a bill)
        SettleReceivableDoc();
        Commit();
        // Create bill group
        InsertData(XNBL, "Cartera Dealing Type"::Discount, CalcDate('<CY-2Y+2M+1D>'), 0);
        // Insert bills in new bill group
        CarteraDoc.Reset();
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Receivable);
        CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Bill);
        CarteraDoc.SetRange("Collection Agent", CarteraDoc."Collection Agent"::Bank);
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", '');
        CarteraDoc.Find('-');
        FinanceCoType := CarteraDoc."Collection Agent"::Bank;
        GroupNo := BillGr."No.";
        for i := 1 to 3 do begin
            CarteraDoc.TestField("Collection Agent", FinanceCoType);
            CarteraDoc.TestField("Bill Gr./Pmt. Order No.", '');
            CarteraDoc.TestField("Currency Code", '');
            CarteraDoc.TestField(Type, CarteraDoc.Type::Receivable);
            if CarteraDoc.Accepted = CarteraDoc.Accepted::No then
                CarteraDoc.FieldError(Accepted);
            OldCarteraDoc := CarteraDoc;
            CarteraDoc."Collection Agent" := FinanceCoType;
            CarteraDoc."Bill Gr./Pmt. Order No." := GroupNo;
            CarteraDoc.Modify();
            CarteraDoc := OldCarteraDoc;
            CarteraDoc.Next();
        end;

        // Create factoring bill group
        InsertData(XNBL, "Cartera Dealing Type"::Collection, CalcDate('<CY-2Y+2M+1D>'), 1);
        // Insert invoices in new bill group
        CarteraDoc.Reset();
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Receivable);
        CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Invoice);
        CarteraDoc.SetRange("Collection Agent", CarteraDoc."Collection Agent"::Bank);
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", '');
        CarteraDoc.Find('-');
        FinanceCoType := CarteraDoc."Collection Agent"::Bank;
        GroupNo := BillGr."No.";
        for i := 1 to 2 do begin
            CarteraDoc.TestField("Collection Agent", FinanceCoType);
            CarteraDoc.TestField("Bill Gr./Pmt. Order No.", '');
            CarteraDoc.TestField("Currency Code", '');
            CarteraDoc.TestField(Type, CarteraDoc.Type::Receivable);
            if CarteraDoc.Accepted = CarteraDoc.Accepted::No then
                CarteraDoc.FieldError(Accepted);
            OldCarteraDoc := CarteraDoc;
            CarteraDoc."Collection Agent" := FinanceCoType;
            CarteraDoc."Bill Gr./Pmt. Order No." := GroupNo;
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

        //Post group
        BillGr.SetRecFilter();
        PostBillGr.SetHidePrintDialog(true);
        PostBillGr.SetTableView(BillGr);
        PostBillGr.UseRequestPage(false);
        PostBillGr.InitReqForm(XCARTERA, XDEFAULT);
        PostBillGr.RunModal();

        Clear(PostBillGr);

        // Create one more group
        InsertData(XWWBEUR, "Cartera Dealing Type"::Collection, CalcDate('<CY-2Y+2M+1D>'), 0);
        // Insert Docs. in new bill group
        CarteraDoc.Reset();
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Receivable);
        CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Bill);
        CarteraDoc.SetRange("Collection Agent", CarteraDoc."Collection Agent"::Bank);
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", '');
        CarteraDoc.Find('-');
        FinanceCoType := CarteraDoc."Collection Agent"::Bank;
        GroupNo := BillGr."No.";
        for i := 1 to 3 do begin
            CarteraDoc.TestField("Collection Agent", FinanceCoType);
            CarteraDoc.TestField("Bill Gr./Pmt. Order No.", '');
            CarteraDoc.TestField("Currency Code", '');
            CarteraDoc.TestField(Type, CarteraDoc.Type::Receivable);
            if CarteraDoc.Accepted = CarteraDoc.Accepted::No then
                CarteraDoc.FieldError(Accepted);
            OldCarteraDoc := CarteraDoc;
            CarteraDoc."Collection Agent" := FinanceCoType;
            CarteraDoc."Bill Gr./Pmt. Order No." := GroupNo;
            CarteraDoc.Modify();
            CarteraDoc := OldCarteraDoc;
            CarteraDoc.Next();
        end;

        // Post group
        BillGr.SetRecFilter();
        PostBillGr.SetHidePrintDialog(true);
        PostBillGr.SetTableView(BillGr);
        PostBillGr.UseRequestPage(false);
        PostBillGr.InitReqForm(XCARTERA, XDEFAULT);
        PostBillGr.RunModal();

        // Post settlement
        WorkDate(20080124D);
        PostedDoc.SetRange("Bill Gr./Pmt. Order No.", '106003');
        SettleDocsInPostedBillGr.SetHidePrintDialog(true);
        SettleDocsInPostedBillGr.SetTableView(PostedDoc);
        SettleDocsInPostedBillGr.UseRequestPage(false);
        SettleDocsInPostedBillGr.RunModal();

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
        GroupNo: Code[20];
        i: Integer;
        BillGr: Record "Bill Group";
        PostBillGr: Report "Post Bill Group";
        SettleDocsInPostedBillGr: Report "Settle Docs. in Post. Bill Gr.";
        PostedDoc: Record "Posted Cartera Doc.";
        GenJnlLine: Record "Gen. Journal Line";
        CGCta: Record "G/L Account";
        DemoDataSetup: Record "Demo Data Setup";
        XNBL: Label 'NBL';
        XCARTERA: Label 'CARTERA';
        XDEFAULT: Label 'DEFAULT';
        XWWBEUR: Label 'WWB-EUR';
        XCASHRCPT: Label 'CASHRCPT';
        XDeerfieldGraphicsCompany: Label 'Deerfield Graphics Company';
        XJO: Label 'JO';
        XCASHRECJNL: Label 'CASHRECJNL';
        XBANK: Label 'BANK';
        XBANKBILLGROUP: Label 'Bank Bill Group %1';

    procedure InsertData("Company No.": Code[20]; "Dealing Type": Enum "Cartera Dealing Type"; "Posting Date": Date; Factoring: Option)
    begin
        Clear(BillGr);
        BillGr.Validate("No.", '');
        BillGr."Posting Date" := "Posting Date";
        BillGr.Insert(true);
        // BillGr."Posting Description" := 'Bank Bill Group ' + BillGr."No.";
        BillGr."Posting Description" := StrSubstNo(XBANKBILLGROUP, BillGr."No.");
        BillGr."Bank Account No." := "Company No.";
        BillGr."Dealing Type" := "Dealing Type";
        BillGr.Factoring := Factoring;
        BillGr.Validate("Bank Account No.", "Company No.");
        BillGr.Validate("Dealing Type", "Dealing Type");
        BillGr.Validate("Posting Date", "Posting Date");
        BillGr.Validate(Factoring, Factoring);
        BillGr.Modify();
    end;

    procedure SettleReceivableDoc()
    var
        CarteraDoc2: Record "Cartera Doc.";
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        CarteraDoc2.Reset();
        CarteraDoc2.SetRange(Type, CarteraDoc2.Type::Receivable);
        CarteraDoc2.SetRange("Document Type", CarteraDoc2."Document Type"::Bill);
        CarteraDoc2.SetRange("Collection Agent", CarteraDoc2."Collection Agent"::Bank);
        CarteraDoc2.SetRange("Bill Gr./Pmt. Order No.", '');
        CarteraDoc2.Find('-');
        GenJnlLine2.Validate("Journal Template Name", XCASHRCPT);
        GenJnlLine2.Validate("Line No.", 10000);
        GenJnlLine2.Validate("Account Type", GenJnlLine2."Account Type"::Customer);
        GenJnlLine2.Validate(GenJnlLine2."Account No.", CarteraDoc2."Account No.");
        GenJnlLine2.Validate(GenJnlLine2."Posting Date", CarteraDoc2."Posting Date");
        GenJnlLine2.Validate("Document Type", GenJnlLine2."Document Type"::Payment);
        GenJnlLine2.Validate("Document No.", 'G02001');
        GenJnlLine2.Validate(Description, XDeerfieldGraphicsCompany);
        GenJnlLine2.Validate(GenJnlLine2.Amount, -CarteraDoc2."Remaining Amount");
        GenJnlLine2.Validate("Posting Group", DemoDataSetup.DomesticCode());
        GenJnlLine2.Validate("Salespers./Purch. Code", XJO);
        GenJnlLine2.Validate("Source Code", XCASHRECJNL);
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
        GenJnlLine2.Insert();
        GJPostLine.SetFromSettlement(true);
        GJPostLine.Run(GenJnlLine2);

        // GJPostLine.RUN(GenJnlLine2);
        Clear(GJPostLine);
    end;
}

