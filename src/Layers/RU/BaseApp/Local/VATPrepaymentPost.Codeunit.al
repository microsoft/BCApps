#pragma warning disable AA0247
codeunit 12410 "VAT Prepayment-Post"
{
    Permissions = TableData "Sales Invoice Header" = rim,
                  TableData "Sales Invoice Line" = rim,
                  TableData "Purch. Inv. Header" = rim,
                  TableData "Purch. Inv. Line" = rim;
    TableNo = "Cust. Ledger Entry";

    trigger OnRun()
    begin
        Rec.TestField("Document Type", Rec."Document Type"::Payment);
        Rec.TestField(Open, true);
        Rec.TestField(Prepayment, PostingType = PostingType::Reset);
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        PostingType: Option Set,Reset;
        PostingDate: Date;
        UseDocNo: Code[20];
        PostDescription: Text[50];
        PostingDocNo: Code[20];
        EntryType: Option Sale,Purchase;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'There is already posted %1 %2 %3 related to %4 %5 %6.   ';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure InitGenJnlLines(CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    var
        CustAgr: Record "Customer Agreement";
        VendAgr: Record "Vendor Agreement";
    begin
        GenJnlLine.Init();
        if PostingDate = 0D then
            GenJnlLine."Posting Date" := CVLedgEntryBuf."Posting Date"
        else
            GenJnlLine."Posting Date" := PostingDate;
        if EntryType = EntryType::Sale then begin
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
            GenJnlLine."Source Code" := SourceCodeSetup."Customer Prepayments";
        end else begin
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
            GenJnlLine."Source Code" := SourceCodeSetup."Vendor Prepayments";
        end;
        GenJnlLine.Validate("Account No.", CVLedgEntryBuf."CV No.");
        GenJnlLine.Validate("Currency Code", CVLedgEntryBuf."Currency Code");
        GenJnlLine.Description := StrSubstNo(PostDescription, CVLedgEntryBuf."Document No.", CVLedgEntryBuf."Posting Date");
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Shortcut Dimension 1 Code" := CVLedgEntryBuf."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := CVLedgEntryBuf."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := CVLedgEntryBuf."Dimension Set ID";
        GenJnlLine."Prepayment Document No." := UseDocNo;
        if CVLedgEntryBuf."Agreement No." <> '' then begin
            GenJnlLine."Agreement No." := CVLedgEntryBuf."Agreement No.";
            if EntryType = EntryType::Sale then begin
                CustAgr.Get(GenJnlLine."Account No.", GenJnlLine."Agreement No.");
                if GenJnlLine."Posting Date" <= CustAgr."Expire Date" then
                    GenJnlLine."Posting Group" := CustAgr."Customer Posting Group";
            end else begin
                VendAgr.Get(GenJnlLine."Account No.", GenJnlLine."Agreement No.");
                if GenJnlLine."Posting Date" <= VendAgr."Expire Date" then
                    GenJnlLine."Posting Group" := VendAgr."Vendor Posting Group";
            end;
        end;
        GenJnlLine."External Document No." := CVLedgEntryBuf."External Document No.";
    end;

    [Scope('OnPrem')]
    procedure Initialize(NewPostingType: Option Set,Reset; NewPostingDate: Date; NewPostDescription: Text[50]; NewPostingDocNo: Code[20]; Type: Option)
    begin
        PostingType := NewPostingType;
        PostingDate := NewPostingDate;
        PostDescription := NewPostDescription;
        PostingDocNo := NewPostingDocNo;
        EntryType := Type;
    end;

    [Scope('OnPrem')]
    procedure PostPrepayment(CVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        CustPostingGr: Record "Customer Posting Group";
        VendPostingGr: Record "Vendor Posting Group";
        NoSeries: Codeunit "No. Series";
        Amount: Decimal;
        AmountLCY: Decimal;
    begin
        SourceCodeSetup.Get();
        if PostingDate = 0D then
            PostingDate := CVLedgEntryBuf."Posting Date";
        Amount := -CVLedgEntryBuf."Remaining Amount";
        AmountLCY := -CVLedgEntryBuf."Remaining Amt. (LCY)";
        if EntryType = EntryType::Sale then begin
            CustPostingGr.Get(CVLedgEntryBuf."CV Posting Group");
            CustPostingGr.TestField("Receivables Account");
            CustPostingGr.TestField("Prepayment Account");
            if PostingDocNo = '' then begin
                SalesSetup.Get();
                SalesSetup.TestField("Posted Prepayment Nos.");
                UseDocNo := NoSeries.GetNextNo(SalesSetup."Posted Prepayment Nos.", PostingDate);
            end;
        end else begin // Purchase
            VendPostingGr.Get(CVLedgEntryBuf."CV Posting Group");
            VendPostingGr.TestField("Payables Account");
            VendPostingGr.TestField("Prepayment Account");
            UseDocNo := CVLedgEntryBuf."Document No.";
        end;
        if PostingDocNo <> '' then
            UseDocNo := PostingDocNo;

        // Post refund
        InitGenJnlLines(CVLedgEntryBuf);
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
        GenJnlLine."Document No." := CVLedgEntryBuf."Document No.";
        GenJnlLine."Posting Group" := CVLedgEntryBuf."CV Posting Group";
        if PostingType = PostingType::Reset then begin
            GenJnlLine.Prepayment := true;
            GenJnlLine."Prepayment Status" := GenJnlLine."Prepayment Status"::Reset;
            if not CVLedgEntryBuf.Positive then begin
                GenJnlLine."Additional VAT Ledger Sheet" := true;
                GenJnlLine."Corrected Document Date" := CVLedgEntryBuf."Posting Date";
            end;
        end;
        GenJnlLine.Validate(Amount, Amount);
        GenJnlLine.Validate("Amount (LCY)", AmountLCY);
        GenJnlLine."Applies-to Doc. Type" := CVLedgEntryBuf."Document Type";
        GenJnlLine."Applies-to Doc. No." := CVLedgEntryBuf."Document No.";
        GenJnlLine."Unrealized VAT Entry No." := CVLedgEntryBuf."Entry No.";
        GenJnlPostLine.RunWithCheck(GenJnlLine);

        // Post New Payment
        InitGenJnlLines(CVLedgEntryBuf);
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := UseDocNo;
        if PostingType = PostingType::Set then begin
            GenJnlLine.Prepayment := true;
            GenJnlLine."Prepayment Status" := GenJnlLine."Prepayment Status"::Set;
        end;
        GenJnlLine.Validate(Amount, -Amount);
        GenJnlLine.Validate("Amount (LCY)", -AmountLCY);
        GenJnlPostLine.SpecialRunWithCheck(GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure InsertSalesInvoice(var GenJnlLine: Record "Gen. Journal Line"): Code[20]
    var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Currency: Record Currency;
        VATPostingSetup: Record "VAT Posting Setup";
        NoSeries: Codeunit "No. Series";
        TemplateDocumentNo: Code[20];
        TemplateDocumentType: Enum "Sales Document Type";
        PrepmtFactor: Decimal;
    begin
        if (GenJnlLine."Prepayment Document No." = '') or
           (GenJnlLine."Prepayment Status" = GenJnlLine."Prepayment Status"::" ")
        then begin
            TemplateDocumentNo := GenJnlLine."Prepayment Document No.";
            SalesSetup.Get();
            SalesSetup.TestField("Posted Prepayment Nos.");
            UseDocNo := NoSeries.GetNextNo(SalesSetup."Posted Prepayment Nos.", GenJnlLine."Posting Date");
        end else
            UseDocNo := GenJnlLine."Prepayment Document No.";

        if TemplateDocumentNo <> '' then begin
            if SalesHeader.Get(SalesHeader."Document Type"::Order, TemplateDocumentNo) then
                TemplateDocumentType := SalesHeader."Document Type"::Order
            else begin
                SalesHeader.Get(SalesHeader."Document Type"::Invoice, TemplateDocumentNo);
                TemplateDocumentType := SalesHeader."Document Type"::Invoice;
            end;
            SalesInvHeader.TransferFields(SalesHeader);
            SalesInvHeader."Currency Code" := '';
        end else begin
            SalesInvHeader.Init();
            FillSalesInvHeader(SalesInvHeader, GenJnlLine."Bill-to/Pay-to No.");
            SalesInvHeader."Tax Area Code" := GenJnlLine."Tax Area Code";
            SalesInvHeader."Tax Liable" := GenJnlLine."Tax Liable";
            SalesInvHeader."Posting Description" := GenJnlLine.Description;
        end;
        SalesInvHeader."No." := UseDocNo;
        SalesInvHeader."External Document No." := GenJnlLine."Document No.";
        SalesInvHeader."External Document Text" := GenJnlLine."External Document No.";
        SalesInvHeader."Order No." := TemplateDocumentNo;
        if PostingDate = 0D then begin
            SalesInvHeader."Posting Date" := GenJnlLine."Posting Date";
            SalesInvHeader."Order Date" := GenJnlLine."Posting Date";
            SalesInvHeader."Document Date" := GenJnlLine."Posting Date";
        end else begin
            SalesInvHeader."Posting Date" := PostingDate;
            SalesInvHeader."Order Date" := PostingDate;
            SalesInvHeader."Document Date" := PostingDate;
        end;
        SalesInvHeader."Prices Including VAT" := true;
        SalesInvHeader."Prepayment Invoice" := true;
        SalesInvHeader.Insert();

        GenJnlLine."Document No." := UseDocNo;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;

        // Create Lines
        if TemplateDocumentNo <> '' then begin
            VATPostingSetup.Get(GenJnlLine."VAT Bus. Posting Group", GenJnlLine."VAT Prod. Posting Group");
            SalesLine.SetRange("Document Type", TemplateDocumentType);
            SalesLine.SetRange("Document No.", TemplateDocumentNo);
            SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
            SalesLine.SetFilter("VAT %", '<>%1', GenJnlLine."VAT %");
            if SalesLine.FindFirst() then
                SalesLine.TestField("VAT %", GenJnlLine."VAT %");
            SalesLine.SetRange("VAT %");

            if SalesHeader."Currency Code" = '' then
                Currency.InitRoundingPrecision()
            else begin
                Currency.Get(SalesHeader."Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;

            SalesHeader.CalcFields("Amount Including VAT");
            PrepmtFactor := -GenJnlLine.Amount / SalesHeader."Amount Including VAT";
            SalesLine.SetRange(Type);
            CopySalesOrderLines(
              SalesLine, SalesInvHeader, GenJnlLine,
              Currency."Amount Rounding Precision", PrepmtFactor);
        end else
            InsertSalesLine(GenJnlLine, SalesInvHeader);

        exit(SalesInvHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure CopySalesOrderLines(var SalesLine: Record "Sales Line"; SalesInvHeader: Record "Sales Invoice Header"; GenJnlLine: Record "Gen. Journal Line"; AmountRoundingPrecision: Decimal; PrepmtFactor: Decimal)
    var
        SalesInvLine: Record "Sales Invoice Line";
        PrevAmount: Decimal;
        BaseDiffLCY: Decimal;
        AmountDiffLCY: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
    begin
        if PrepmtFactor <> 1 then begin
            TotalAmountInclVAT := -GenJnlLine.Amount;
            TotalAmount := -GenJnlLine.Amount + GenJnlLine."VAT Amount";
        end;

        if SalesLine.FindSet() then
            repeat
                SalesInvLine.TransferFields(SalesLine);
                SalesInvLine."Document No." := SalesInvHeader."No.";
                if PrepmtFactor <> 1 then begin
                    PrevAmount := SalesInvLine."Amount Including VAT";
                    SalesInvLine."Amount Including VAT" :=
                      Round(SalesInvLine."Amount Including VAT" * PrepmtFactor + BaseDiffLCY, AmountRoundingPrecision);
                    BaseDiffLCY := PrevAmount * PrepmtFactor - SalesInvLine."Amount Including VAT";
                    TotalAmountInclVAT := TotalAmountInclVAT - SalesInvLine."Amount Including VAT";

                    PrevAmount := SalesInvLine.Amount;
                    SalesInvLine.Amount :=
                      Round(SalesInvLine.Amount * PrepmtFactor + AmountDiffLCY, AmountRoundingPrecision);
                    AmountDiffLCY := PrevAmount * PrepmtFactor - SalesInvLine.Amount;
                    TotalAmount := TotalAmount - SalesInvLine.Amount;

                    SalesInvLine."Amount Including VAT (LCY)" := SalesInvLine."Amount Including VAT";
                    SalesInvLine."Amount (LCY)" := SalesInvLine.Amount;
                    SalesInvLine."Line Amount" := SalesInvLine."Amount Including VAT";
                    SalesInvLine."VAT Base Amount" := SalesInvLine.Amount;
                end;
                SalesInvLine.Insert();
            until SalesLine.Next() = 0;

        // Final line update
        if TotalAmountInclVAT <> 0 then begin
            SalesInvLine."Amount Including VAT (LCY)" := SalesInvLine."Amount Including VAT (LCY)" + TotalAmountInclVAT;
            SalesInvLine."Amount Including VAT" := SalesInvLine."Amount Including VAT (LCY)";
        end;
        if TotalAmount <> 0 then begin
            SalesInvLine."Amount (LCY)" := SalesInvLine."Amount (LCY)" + TotalAmount;
            SalesInvLine.Amount := SalesInvLine."Amount (LCY)";
            SalesInvLine."Line Amount" := SalesInvLine."Amount Including VAT";
            SalesInvLine."VAT Base Amount" := SalesInvLine.Amount;
        end;
        SalesInvLine.Modify();
    end;

    [Scope('OnPrem')]
    procedure InsertSalesLine(GenJnlLine: Record "Gen. Journal Line"; SalesInvHeader: Record "Sales Invoice Header")
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        SalesInvLine.Init();
        SalesInvLine."Document No." := SalesInvHeader."No.";
        SalesInvLine."Line No." := 10000;
        SalesInvLine."Sell-to Customer No." := SalesInvHeader."Sell-to Customer No.";
        SalesInvLine."Bill-to Customer No." := SalesInvHeader."Bill-to Customer No.";
        SalesInvLine.Type := SalesInvLine.Type::"G/L Account";
        SalesInvLine."No." := GenJnlLine."Account No.";
        SalesInvLine.Description := SalesInvHeader."Posting Description";
        SalesInvLine."VAT Bus. Posting Group" := GenJnlLine."VAT Bus. Posting Group";
        SalesInvLine."VAT Prod. Posting Group" := GenJnlLine."VAT Prod. Posting Group";
        SalesInvLine."Gen. Bus. Posting Group" := GenJnlLine."Gen. Bus. Posting Group";
        SalesInvLine."Gen. Prod. Posting Group" := GenJnlLine."Gen. Prod. Posting Group";
        SalesInvLine."Dimension Set ID" := GenJnlLine."Dimension Set ID";
        SalesInvLine."VAT Calculation Type" := GenJnlLine."VAT Calculation Type";
        SalesInvLine."Tax Area Code" := GenJnlLine."Tax Area Code";
        SalesInvLine."Tax Liable" := GenJnlLine."Tax Liable";
        SalesInvLine."Tax Group Code" := GenJnlLine."Tax Group Code";
        SalesInvLine.Quantity := 1;
        SalesInvLine."Qty. per Unit of Measure" := 1;
        SalesInvLine."Quantity (Base)" := 1;
        SalesInvLine.Amount := -GenJnlLine."VAT Base Amount";
        SalesInvLine."Line Amount" := -GenJnlLine.Amount;
        SalesInvLine."VAT %" := GenJnlLine."VAT %";
        SalesInvLine."Amount Including VAT" := -GenJnlLine.Amount;
        SalesInvLine."VAT Base Amount" := -GenJnlLine."VAT Base Amount";
        SalesInvLine."Unit Price" := -GenJnlLine.Amount;
        SalesInvLine.Insert();
    end;

    local procedure FillSalesInvHeader(var SalesInvHeader: Record "Sales Invoice Header"; CustNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustNo);
        SalesInvHeader."Sell-to Customer No." := Customer."No.";
        SalesInvHeader."Sell-to Customer Name" := Customer.Name;
        SalesInvHeader."Sell-to Customer Name 2" := Customer."Name 2";
        SalesInvHeader."Sell-to Address" := Customer.Address;
        SalesInvHeader."Sell-to Address 2" := Customer."Address 2";
        SalesInvHeader."Sell-to City" := Customer.City;
        SalesInvHeader."Bill-to Customer No." := Customer."No.";
        SalesInvHeader."Bill-to Name" := Customer.Name;
        SalesInvHeader."Bill-to Name 2" := Customer."Name 2";
        SalesInvHeader."Bill-to Address" := Customer.Address;
        SalesInvHeader."Bill-to Address 2" := Customer."Address 2";
        SalesInvHeader."Bill-to City" := Customer.City;
        SalesInvHeader."Bill-to Contact" := Customer.Contact;
        SalesInvHeader."Sell-to Post Code" := Customer."Post Code";
        SalesInvHeader."Sell-to Country/Region Code" := Customer."Country/Region Code";
        SalesInvHeader."Sell-to County" := Customer.County;
        SalesInvHeader."Sell-to Contact" := Customer.Contact;
        SalesInvHeader."Bill-to Post Code" := Customer."Post Code";
        SalesInvHeader."Bill-to Country/Region Code" := Customer."Country/Region Code";
        SalesInvHeader."Bill-to County" := Customer.County;
        SalesInvHeader."Bill-to Contact" := Customer.Contact;
        SalesInvHeader."Ship-to Name" := Customer.Name;
        SalesInvHeader."Ship-to Name 2" := Customer."Name 2";
        SalesInvHeader."Ship-to Address" := Customer.Address;
        SalesInvHeader."Ship-to Address 2" := Customer."Address 2";
        SalesInvHeader."Ship-to City" := Customer.City;
        SalesInvHeader."Ship-to Post Code" := Customer."Post Code";
        SalesInvHeader."Ship-to Country/Region Code" := Customer."Country/Region Code";
        SalesInvHeader."Ship-to County" := Customer.County;
        SalesInvHeader."Ship-to Contact" := Customer.Contact;
    end;

    [Scope('OnPrem')]
    procedure PostVendVAT(var VendLedgEntry: Record "Vendor Ledger Entry"; VATProdPostingGroup: Code[20]; VATBase: Decimal; VATAmount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendPostingGroup: Record "Vendor Posting Group";
        Vendor: Record Vendor;
        SourceCodeSetup: Record "Source Code Setup";
        PostingDate: Date;
    begin
        CheckForPostedVAT(VendLedgEntry."Entry No.");

        SourceCodeSetup.Get();
        VendPostingGroup.Get(VendLedgEntry."Vendor Posting Group");
        VendPostingGroup.TestField("Prepayment Account");
        Vendor.Get(VendLedgEntry."Vendor No.");
        VATPostingSetup.Get(Vendor."VAT Bus. Posting Group", VATProdPostingGroup);
        VATPostingSetup.TestField("Purchase VAT Account");

        PostingDate := VendLedgEntry."Vendor VAT Invoice Date";
        if VendLedgEntry."Vendor VAT Invoice Rcvd Date" > PostingDate then
            PostingDate := VendLedgEntry."Vendor VAT Invoice Rcvd Date";

        GenJnlLine.Init();
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Document Date" := VendLedgEntry."Vendor VAT Invoice Date";
        GenJnlLine."Vendor VAT Invoice No." := VendLedgEntry."Vendor VAT Invoice No.";
        GenJnlLine."Vendor VAT Invoice Date" := VendLedgEntry."Vendor VAT Invoice Date";
        GenJnlLine."Vendor VAT Invoice Rcvd Date" := VendLedgEntry."Vendor VAT Invoice Rcvd Date";
        GenJnlLine.Description := VendLedgEntry.Description;
        GenJnlLine.Prepayment := true;
        GenJnlLine."Initial Entry No." := VendLedgEntry."Entry No.";
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
        GenJnlLine."Document No." := VendLedgEntry."Vendor VAT Invoice No.";
        GenJnlLine."External Document No." := VendLedgEntry."Document No.";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine."Account No." := VATPostingSetup."Purchase VAT Account";
        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Purchase;
        GenJnlLine."Gen. Bus. Posting Group" := '';
        GenJnlLine."Gen. Prod. Posting Group" := '';
        GenJnlLine."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        GenJnlLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GenJnlLine.Validate("Currency Code", '');
        GenJnlLine.Validate(Amount, VATAmount);
        GenJnlLine."Advance VAT Base Amount" := VATBase;
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
        GenJnlLine."Bal. Account No." := VATPostingSetup."Purchase VAT Account";
        GenJnlLine."VAT Registration No." := Vendor."VAT Registration No.";
        GenJnlLine."Tax Area Code" := Vendor."Tax Area Code";
        GenJnlLine."Tax Liable" := Vendor."Tax Liable";
        GenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
        GenJnlLine."Bill-to/Pay-to No." := VendLedgEntry."Vendor No.";
        GenJnlLine."Reason Code" := VendLedgEntry."Reason Code";
        GenJnlLine."Source Code" := SourceCodeSetup."Vendor Prepayments";
        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Vendor;
        GenJnlLine."Source No." := VendLedgEntry."Vendor No.";
        GenJnlLine."IC Partner Code" := VendLedgEntry."IC Partner Code";
        GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Automatic VAT Entry";
        GenJnlLine."Agreement No." := VendLedgEntry."Agreement No.";
        GenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
        GenJnlLine."System-Created Entry" := true;
        InsertPurchInvoice(GenJnlLine);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    local procedure FillPurchInvHeader(var PurchInvHeader: Record "Purch. Inv. Header"; VendNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendNo);

        PurchInvHeader."Buy-from Vendor No." := Vendor."No.";
        PurchInvHeader."Buy-from Vendor Name" := Vendor.Name;
        PurchInvHeader."Buy-from Vendor Name 2" := Vendor."Name 2";
        PurchInvHeader."Buy-from Address" := Vendor.Address;
        PurchInvHeader."Buy-from Address 2" := Vendor."Address 2";
        PurchInvHeader."Buy-from City" := Vendor.City;
        PurchInvHeader."Pay-to Vendor No." := Vendor."No.";
        PurchInvHeader."Pay-to Name" := Vendor.Name;
        PurchInvHeader."Pay-to Name 2" := Vendor."Name 2";
        PurchInvHeader."Pay-to Address" := Vendor.Address;
        PurchInvHeader."Pay-to Address 2" := Vendor."Address 2";
        PurchInvHeader."Pay-to City" := Vendor.City;
        PurchInvHeader."Pay-to Contact" := Vendor.Contact;
        PurchInvHeader."Buy-from Post Code" := Vendor."Post Code";
        PurchInvHeader."Buy-from Country/Region Code" := Vendor."Country/Region Code";
        PurchInvHeader."Buy-from County" := Vendor.County;
        PurchInvHeader."Buy-from Contact" := Vendor.Contact;
        PurchInvHeader."Pay-to Post Code" := Vendor."Post Code";
        PurchInvHeader."Pay-to Country/Region Code" := Vendor."Country/Region Code";
        PurchInvHeader."Pay-to County" := Vendor.County;
        PurchInvHeader."Pay-to Contact" := Vendor.Contact;
        PurchInvHeader."Ship-to Name" := Vendor.Name;
        PurchInvHeader."Ship-to Name 2" := Vendor."Name 2";
        PurchInvHeader."Ship-to Address" := Vendor.Address;
        PurchInvHeader."Ship-to Address 2" := Vendor."Address 2";
        PurchInvHeader."Ship-to City" := Vendor.City;
        PurchInvHeader."Ship-to Post Code" := Vendor."Post Code";
        PurchInvHeader."Ship-to Country/Region Code" := Vendor."Country/Region Code";
        PurchInvHeader."Ship-to County" := Vendor.County;
        PurchInvHeader."Ship-to Contact" := Vendor.Contact;
    end;

    [Scope('OnPrem')]
    procedure InsertPurchInvoice(var GenJnlLine: Record "Gen. Journal Line"): Code[20]
    var
        PurchSetup: Record "Purchases & Payables Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        NoSeries: Codeunit "No. Series";
    begin
        PurchSetup.Get();
        PurchSetup.TestField("Posted Invoice Nos.");
        GenJnlLine."Document No." :=
          NoSeries.GetNextNo(PurchSetup."Posted Invoice Nos.", GenJnlLine."Posting Date");
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;

        PurchInvHeader.Init();
        FillPurchInvHeader(PurchInvHeader, GenJnlLine."Bill-to/Pay-to No.");
        PurchInvHeader."Prepayment Invoice" := true;
        PurchInvHeader."Vendor Invoice No." := GenJnlLine."Vendor VAT Invoice No.";
        PurchInvHeader."Posting Date" := GenJnlLine."Posting Date";
        PurchInvHeader."Document Date" := GenJnlLine."Vendor VAT Invoice Date";
        PurchInvHeader."Tax Area Code" := GenJnlLine."Tax Area Code";
        PurchInvHeader."Tax Liable" := GenJnlLine."Tax Liable";
        PurchInvHeader."Posting Description" := GenJnlLine.Description;
        PurchInvHeader."No." := GenJnlLine."Document No.";
        PurchInvHeader."Prices Including VAT" := true;
        PurchInvHeader."Currency Code" := '';
        PurchInvHeader."Dimension Set ID" := GenJnlLine."Dimension Set ID";
        PurchInvHeader.Insert();

        InsertPurchLine(GenJnlLine, PurchInvHeader);

        exit(PurchInvHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure InsertPurchLine(GenJnlLine: Record "Gen. Journal Line"; PurchInvHeader: Record "Purch. Inv. Header")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        PurchInvLine: Record "Purch. Inv. Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        PurchInvLine.Init();
        PurchInvLine."Document No." := PurchInvHeader."No.";
        PurchInvLine."Line No." := 10000;
        PurchInvLine."Buy-from Vendor No." := PurchInvHeader."Pay-to Vendor No.";
        PurchInvLine.Type := PurchInvLine.Type::"G/L Account";
        PurchInvLine."No." := GenJnlLine."Bal. Account No.";
        PurchInvLine.Description := PurchInvHeader."Posting Description";
        PurchInvLine."VAT Bus. Posting Group" := GenJnlLine."VAT Bus. Posting Group";
        PurchInvLine."VAT Prod. Posting Group" := GenJnlLine."VAT Prod. Posting Group";
        PurchInvLine."Gen. Bus. Posting Group" := GenJnlLine."Gen. Bus. Posting Group";
        PurchInvLine."Gen. Prod. Posting Group" := GenJnlLine."Gen. Prod. Posting Group";
        PurchInvLine."VAT Calculation Type" := GenJnlLine."VAT Calculation Type";
        PurchInvLine."Tax Area Code" := GenJnlLine."Tax Area Code";
        PurchInvLine."Tax Liable" := GenJnlLine."Tax Liable";
        PurchInvLine."Tax Group Code" := GenJnlLine."Tax Group Code";
        PurchInvLine.Quantity := 1;
        PurchInvLine."Qty. per Unit of Measure" := 1;
        PurchInvLine."Quantity (Base)" := 1;
        PurchInvLine."Direct Unit Cost" := GenJnlLine."Advance VAT Base Amount" + GenJnlLine.Amount;
        PurchInvLine.Amount := GenJnlLine."Advance VAT Base Amount";
        PurchInvLine."Line Amount" := PurchInvLine."Direct Unit Cost";
        if VATPostingSetup.Get(PurchInvLine."VAT Bus. Posting Group", PurchInvLine."VAT Prod. Posting Group") then
            PurchInvLine."VAT %" := VATPostingSetup."VAT %";
        PurchInvLine."Amount Including VAT" := PurchInvLine."Direct Unit Cost";
        PurchInvLine."VAT Base Amount" := GenJnlLine."Advance VAT Base Amount";
        if PurchInvHeader."Currency Code" = '' then begin
            PurchInvLine."Amount (LCY)" := PurchInvLine.Amount;
            PurchInvLine."Amount Including VAT (LCY)" := PurchInvLine."Amount Including VAT";
        end else begin
            PurchInvLine."Amount (LCY)" :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                PurchInvHeader."Posting Date", PurchInvHeader."Currency Code", PurchInvLine.Amount, PurchInvHeader."Currency Factor");
            PurchInvLine."Amount Including VAT (LCY)" :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                PurchInvHeader."Posting Date", PurchInvHeader."Currency Code",
                  PurchInvLine."Amount Including VAT", PurchInvHeader."Currency Factor");
        end;
        PurchInvLine."Dimension Set ID" := GenJnlLine."Dimension Set ID";
        PurchInvLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure CheckForPostedVAT(EntryNo: Integer)
    var
        VATEntry: Record "VAT Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VATEntry.SetCurrentKey("Transaction No.", "CV Ledg. Entry No.");
        VATEntry.SetRange("CV Ledg. Entry No.", EntryNo);
        VATEntry.SetRange("Unrealized VAT Entry No.", 0);
        VATEntry.SetRange(Reversed, false);
        if VATEntry.FindFirst() then
            Error(Text001,
              VATEntry.TableCaption(), VATEntry.FieldCaption("Entry No."), VATEntry."Entry No.",
              VendLedgEntry.TableCaption(), VendLedgEntry.FieldCaption("Entry No."), EntryNo);
    end;

    [Scope('OnPrem')]
    procedure InsertVATAgentPurchInvoice(var GenJnlLine: Record "Gen. Journal Line"; VATAmountLCY: Decimal; VATAmountFCY: Decimal)
    var
        PurchSetup: Record "Purchases & Payables Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        OrigPurchInvHeader: Record "Purch. Inv. Header";
        OrigPurchInvLine: Record "Purch. Inv. Line";
        TempOrigPurchInvHeader: Record "Purch. Inv. Header" temporary;
        TempOrigPurchInvLine: Record "Purch. Inv. Line" temporary;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        NoSeries: Codeunit "No. Series";
        PurchHeaderAmount: Decimal;
    begin
        if GenJnlLine.Prepayment then
            GenJnlLine.TestField("Prepayment Document No.")
        else
            GenJnlLine.TestField("Initial Document No.");

        PurchSetup.Get();
        PurchSetup.TestField("Posted VAT Agent Invoice Nos.");

        if GenJnlLine.Prepayment then begin
            if PurchHeader.Get(PurchHeader."Document Type"::Order, GenJnlLine."Prepayment Document No.") then begin
                PurchHeader.TestField(Status, PurchHeader.Status::Released);
                TempOrigPurchInvHeader.Init();
                TempOrigPurchInvHeader.TransferFields(PurchHeader);
                TempOrigPurchInvHeader.Insert();
                PurchLine.SetRange("Document Type", PurchHeader."Document Type"::Order);
            end else begin
                PurchHeader.Get(PurchHeader."Document Type"::Invoice, GenJnlLine."Prepayment Document No.");
                PurchHeader.TestField(Status, PurchHeader.Status::Released);
                TempOrigPurchInvHeader.Init();
                TempOrigPurchInvHeader.TransferFields(PurchHeader);
                TempOrigPurchInvHeader.Insert();
                PurchLine.SetRange("Document Type", PurchHeader."Document Type"::Invoice);
            end;
            PurchHeader.CalcFields(Amount);
            PurchHeaderAmount := PurchHeader.Amount;
            PurchLine.SetRange("Document No.", PurchHeader."No.");
            if PurchLine.FindSet() then
                repeat
                    TempOrigPurchInvLine.Init();
                    TempOrigPurchInvLine.TransferFields(PurchLine);
                    TempOrigPurchInvLine.Insert();
                until PurchLine.Next() = 0;
        end else begin
            OrigPurchInvHeader.Get(GenJnlLine."Initial Document No.");
            TempOrigPurchInvHeader.Init();
            TempOrigPurchInvHeader.TransferFields(OrigPurchInvHeader);
            TempOrigPurchInvHeader.Insert();
            OrigPurchInvLine.SetRange("Document No.", GenJnlLine."Initial Document No.");
            if OrigPurchInvLine.FindSet() then
                repeat
                    TempOrigPurchInvLine.Init();
                    TempOrigPurchInvLine.TransferFields(OrigPurchInvLine);
                    TempOrigPurchInvLine.Insert();
                until OrigPurchInvLine.Next() = 0;
        end;

        PurchInvHeader.Init();
        PurchInvHeader.TransferFields(TempOrigPurchInvHeader);
        PurchInvHeader."Posting Date" := GenJnlLine."Posting Date";
        PurchInvHeader."Document Date" := GenJnlLine."Document Date";
        PurchInvHeader."Posting Description" := GenJnlLine.Description;
        PurchInvHeader."Vendor Invoice No." := GenJnlLine."External Document No.";
        PurchInvHeader."No." := NoSeries.GetNextNo(PurchSetup."Posted VAT Agent Invoice Nos.", GenJnlLine."Posting Date");
        PurchInvHeader."Dimension Set ID" := GenJnlLine."Dimension Set ID";
        PurchInvHeader.Insert();

        CopyVATAgentPurchInvLine(
          TempOrigPurchInvHeader, TempOrigPurchInvLine,
          PurchInvHeader, GenJnlLine, VATAmountLCY, VATAmountFCY, PurchHeaderAmount);

        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
        GenJnlLine."Document No." := PurchInvHeader."No.";
    end;

    local procedure CopyVATAgentPurchInvLine(var InitialPurchInvHeader: Record "Purch. Inv. Header"; var InitialPurchInvLine: Record "Purch. Inv. Line"; var PurchInvHeader: Record "Purch. Inv. Header"; GenJnlLine: Record "Gen. Journal Line"; VATAmountLCY: Decimal; VATAmountFCY: Decimal; InitialPurchHeaderAmount: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        Currency: Record Currency;
        CurrencyLCY: Record Currency;
        VATPostingSetup: Record "VAT Posting Setup";
        PmtFactor: Decimal;
        PmtFactorInclVAT: Decimal;
        AmountRoundingPrecision: Decimal;
        AmountRoundingPrecisionLCY: Decimal;
        PrevAmount: Decimal;
        BaseDiff: Decimal;
        AmountDiff: Decimal;
        RemTotalAmount: Decimal;
        RemTotalAmountInclVAT: Decimal;
        BaseDiffLCY: Decimal;
        AmountDiffLCY: Decimal;
        RemTotalAmountLCY: Decimal;
        RemTotalAmountInclVATLCY: Decimal;
    begin
        if InitialPurchHeaderAmount = 0 then begin
            InitialPurchInvHeader.CalcFields(Amount);
            InitialPurchHeaderAmount := InitialPurchInvHeader.Amount;
        end;
        PmtFactor := (GenJnlLine.Amount - VATAmountFCY) / InitialPurchHeaderAmount;
        PmtFactorInclVAT := GenJnlLine.Amount / InitialPurchHeaderAmount;

        if PurchInvHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get(PurchInvHeader."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
        AmountRoundingPrecision := Currency."Amount Rounding Precision";
        CurrencyLCY.InitRoundingPrecision();
        AmountRoundingPrecisionLCY := CurrencyLCY."Amount Rounding Precision";

        RemTotalAmount := GenJnlLine.Amount - VATAmountFCY;
        RemTotalAmountInclVAT := GenJnlLine.Amount;
        RemTotalAmountLCY := GenJnlLine."Amount (LCY)" - VATAmountLCY;
        RemTotalAmountInclVATLCY := GenJnlLine."Amount (LCY)";

        VATPostingSetup.Get(GenJnlLine."VAT Bus. Posting Group", GenJnlLine."VAT Prod. Posting Group");
        if InitialPurchInvLine.FindSet() then
            repeat
                PurchInvLine.Init();
                PurchInvLine.TransferFields(InitialPurchInvLine);
                PurchInvLine."Document No." := PurchInvHeader."No.";
                PurchInvLine."VAT %" := VATPostingSetup."VAT %";

                PrevAmount := PurchInvLine."Amount Including VAT";
                PurchInvLine."Amount Including VAT" :=
                  Round(PurchInvLine."Amount Including VAT" * PmtFactorInclVAT + BaseDiff, AmountRoundingPrecision);
                BaseDiff := PrevAmount * PmtFactorInclVAT - PurchInvLine."Amount Including VAT";
                RemTotalAmountInclVAT -= PurchInvLine."Amount Including VAT";

                PrevAmount := PurchInvLine.Amount;
                PurchInvLine.Amount :=
                  Round(PurchInvLine.Amount * PmtFactor + AmountDiff, AmountRoundingPrecision);
                AmountDiff := PrevAmount * PmtFactor - PurchInvLine.Amount;
                RemTotalAmount -= PurchInvLine.Amount;

                PrevAmount := PurchInvLine."Amount Including VAT (LCY)";
                PurchInvLine."Amount Including VAT (LCY)" :=
                  Round(PurchInvLine."Amount Including VAT (LCY)" * PmtFactorInclVAT + BaseDiffLCY, AmountRoundingPrecisionLCY);
                BaseDiffLCY := PrevAmount * PmtFactorInclVAT - PurchInvLine."Amount Including VAT (LCY)";
                RemTotalAmountInclVATLCY -= PurchInvLine."Amount Including VAT (LCY)";

                PrevAmount := PurchInvLine."Amount (LCY)";
                PurchInvLine."Amount (LCY)" :=
                  Round(PurchInvLine."Amount (LCY)" * PmtFactor + AmountDiffLCY, AmountRoundingPrecisionLCY);
                AmountDiffLCY := PrevAmount * PmtFactor - PurchInvLine."Amount (LCY)";
                RemTotalAmountLCY -= PurchInvLine."Amount (LCY)";

                PurchInvLine."Line Amount" := PurchInvLine."Amount Including VAT";
                PurchInvLine."VAT Base Amount" := PurchInvLine.Amount;
                PurchInvLine."Dimension Set ID" := GenJnlLine."Dimension Set ID";
                PurchInvLine.Insert();
            until InitialPurchInvLine.Next() = 0;

        PurchInvLine."Amount Including VAT" += RemTotalAmountInclVAT;
        PurchInvLine.Amount += RemTotalAmount;
        PurchInvLine."Amount Including VAT (LCY)" += RemTotalAmountInclVATLCY;
        PurchInvLine."Amount (LCY)" += RemTotalAmountLCY;
        PurchInvLine."Line Amount" := PurchInvLine."Amount Including VAT";
        PurchInvLine."VAT Base Amount" := PurchInvLine.Amount;
        PurchInvLine.Modify();
    end;
}

