codeunit 161300 "Create Italian Data"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();

        Window.Open(XEnteringData + XTableXXX);

        Window.Update(1, GLSetup.TableCaption());

        GLSetup.Get();
        GLSetup."Use Document Date in Currency" := true;
        GLSetup."Minimum VAT Payable" := 25;
        GLSetup."Settlement Round. Factor" := 0.01;
        GLSetup.Modify();

        Window.Update(1, VATRegister.TableCaption());
        InsertVATRegister(XxEUPURCH, VATRegister.Type::Purchase, XEUPurchaseRegister);
        InsertVATRegister(XxEXTPURCH, VATRegister.Type::Purchase, XExtraEUPurchaseRegister);
        InsertVATRegister(XxNATPURCH, VATRegister.Type::Purchase, XNationalPurchaseRegister);
        InsertVATRegister(XxEUSALES, VATRegister.Type::Sale, XEUSalesRegister);
        InsertVATRegister(XxEXTSALES, VATRegister.Type::Sale, XExtraEUSalesRegister);
        InsertVATRegister(XxNATSALES, VATRegister.Type::Sale, XNationalSalesRegister);

        Window.Update(1, VATIdentifier.TableCaption());
        InsertVATIdentifier(XxE10, XTaxExemptArt10);
        InsertVATIdentifier(XxE13, XTaxExemptArt13);
        InsertVATIdentifier(XxFCI2, XxFCIArt2);
        InsertVATIdentifier(XxIND100, XVAT20PERC100PERCNondeductible);
        InsertVATIdentifier(XxIND50, XVAT20PERC50PERCNondeductible);
        InsertVATIdentifier(DemoDataSetup.ServicesVATCode(), XxVAT10PERC);
        InsertVATIdentifier(DemoDataSetup.GoodsVATCode(), XxVAT20PERC);
        InsertVATIdentifier(XxNI41, XNIArt41DL331slash93);
        InsertVATIdentifier(XxNI8, XNonTaxableArt8slash1);
        InsertVATIdentifier(XxNI9, XNonTaxableArt9);
        InsertVATIdentifier(DemoDataSetup.NoVATCode(), XNonTaxable);

        Window.Update(1, VATProductPostingGroup.TableCaption());
        InsertVATProductPostingGroup(XxE13, XTaxExemptArt13);
        InsertVATProductPostingGroup(XxIND100, XOrdVAT20PERC100PERCNondeduct);
        InsertVATProductPostingGroup(XxIND50, XOrdVAT20PERC50PERCNondeduct);
        InsertVATProductPostingGroup(XxVAT0, XZeroPERCTaxExemptNIFCIOthers);
        InsertVATProductPostingGroup(XxVAT04, XMinimumVAT4PERC);
        InsertVATProductPostingGroup(DemoDataSetup.ServicesVATCode(), XReducedVAT10PERC);
        InsertVATProductPostingGroup(DemoDataSetup.GoodsVATCode(), XOrdinaryVAT20PERC);
        InsertVATProductPostingGroup(XxNI8, XNonTaxableArt8slash1);

        Window.Update(1, NoSeries.TableCaption());
        InsertNoSeries(XxEXTVNSLS, XInvCrMemoVATNoForExtraEUCust, NoSeries."No. Series Type"::Sales, XxEXTSALES, '');
        InsertNoSeries(XxEXTVNPUR, XInvCrMemoVATNoForExtraEUVend, NoSeries."No. Series Type"::Purchase, XxEXTPURCH, '');
        InsertNoSeries(XxITVNSLS, XInvCrMemoVATNoForItalianCust, NoSeries."No. Series Type"::Sales, XxNATSALES, '');
        InsertNoSeries(XxITVNPUR, XInvCrMemoVATNoForItalianVend, NoSeries."No. Series Type"::Purchase, XxNATPURCH, '');
        InsertNoSeries(XxEUVNSLS, XInvCrMemoVATNoForEUCust, NoSeries."No. Series Type"::Sales, XxEUSALES, '');
        InsertNoSeries(XxEUVNPUR, XInvCrMemoVATNoForEUVend, NoSeries."No. Series Type"::Purchase, XxEUPURCH, XxEUVNSLS);

        Window.Update(1, NoSeriesLineSales.TableCaption());

        LineNo := 0;

        for i := 1 to 3 do begin
            LineNo += 10000;
            NoSeriesLineSales.Init();
            NoSeriesLineSales."Series Code" := XxEXTVNSLS;
            NoSeriesLineSales."Starting Date" := DMY2Date(1, 1, DemoDataSetup."Starting Year" + i - 1);
            NoSeriesLineSales."Line No." := LineNo;
            NoSeriesLineSales."Starting No." := StrSubstNo(XxCX0PERC10001, Format(i - 1));
            ;
            if NoSeriesLineSales.Insert() then;
        end;

        LineNo := 0;

        for i := 1 to 3 do begin
            LineNo += 10000;
            NoSeriesLineSales.Init();
            NoSeriesLineSales."Series Code" := XxEUVNSLS;
            NoSeriesLineSales."Starting Date" := DMY2Date(1, 1, DemoDataSetup."Starting Year" + i - 1);
            NoSeriesLineSales."Line No." := LineNo;
            NoSeriesLineSales."Starting No." := StrSubstNo(XxC0PERC10001, Format(i - 1));
            if NoSeriesLineSales.Insert() then;
        end;

        LineNo := 0;

        for i := 1 to 3 do begin
            LineNo += 10000;
            NoSeriesLineSales.Init();
            NoSeriesLineSales."Series Code" := XxEXTVNSLS;
            NoSeriesLineSales."Starting Date" := DMY2Date(1, 1, DemoDataSetup."Starting Year" + i - 1);
            NoSeriesLineSales."Line No." := LineNo;
            NoSeriesLineSales."Starting No." := StrSubstNo(XxCX0PERC10001, Format(i - 1));
            if NoSeriesLineSales.Insert() then;
        end;

        NoSeriesLineSales.Init();
        NoSeriesLineSales."Series Code" := XxITVNSLS;
        NoSeriesLineSales."Line No." := 10000;
        NoSeriesLineSales."Starting No." := '103001';
        if NoSeriesLineSales.Insert() then;

        Window.Update(1, NoSeriesLinePurchase.TableCaption());

        LineNo := 0;

        for i := 1 to 3 do begin
            LineNo += 10000;
            NoSeriesLinePurchase.Init();
            NoSeriesLinePurchase."Series Code" := XxEUVNPUR;
            NoSeriesLinePurchase."Starting Date" := DMY2Date(1, 1, DemoDataSetup."Starting Year" + i - 1);
            NoSeriesLinePurchase."Line No." := LineNo;
            NoSeriesLinePurchase."Starting No." := StrSubstNo(XxV0PERC10001, Format(i - 1));
            ;
            if NoSeriesLinePurchase.Insert() then;
        end;

        LineNo := 0;

        for i := 1 to 3 do begin
            LineNo += 10000;
            NoSeriesLinePurchase.Init();
            NoSeriesLinePurchase."Series Code" := XxEXTVNPUR;
            NoSeriesLinePurchase."Starting Date" := DMY2Date(1, 1, DemoDataSetup."Starting Year" + i - 1);
            NoSeriesLinePurchase."Line No." := LineNo;
            NoSeriesLinePurchase."Starting No." := StrSubstNo(XxFX0PERC10001, Format(i - 1));
            ;
            if NoSeriesLinePurchase.Insert() then;
        end;

        NoSeriesLinePurchase.Init();
        NoSeriesLinePurchase."Series Code" := XxITVNPUR;
        NoSeriesLinePurchase."Line No." := 10000;
        NoSeriesLinePurchase."Starting No." := '108001';
        if NoSeriesLinePurchase.Insert() then;

        Window.Update(1, VATPostingSetup.TableCaption());

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := '';
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.ServicesVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.ServicesVATCode());
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."Deductible %" := 100;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := '';
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.GoodsVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.GoodsVATCode());
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."Deductible %" := 100;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := '';
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.NoVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.NoVATCode());
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."Deductible %" := 100;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.ExportCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.ServicesVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.ServicesVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5611');
        VATPostingSetup.Validate("Purchase VAT Account", '5631');
        VATPostingSetup."VAT %" := 10;
        VATPostingSetup."Deductible %" := 100;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.ExportCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.GoodsVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.GoodsVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5610');
        VATPostingSetup.Validate("Purchase VAT Account", '5630');
        VATPostingSetup."VAT %" := 20;
        VATPostingSetup."Deductible %" := 100;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.ExportCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.NoVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.NoVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5610');
        VATPostingSetup.Validate("Purchase VAT Account", '5630');
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."Deductible %" := 100;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.DomesticCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.ServicesVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.ServicesVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5611');
        VATPostingSetup.Validate("Purchase VAT Account", '5631');
        VATPostingSetup."VAT %" := 10;
        VATPostingSetup."Deductible %" := 100;
        VATPostingSetup.Validate("Sales Prepayments Account", '5370');
        VATPostingSetup.Validate("Purch. Prepayments Account", '2420');
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.DomesticCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.GoodsVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.GoodsVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5610');
        VATPostingSetup.Validate("Purchase VAT Account", '5630');
        VATPostingSetup."VAT %" := 20;
        VATPostingSetup."Deductible %" := 100;
        VATPostingSetup.Validate("Sales Prepayments Account", '5380');
        VATPostingSetup.Validate("Purch. Prepayments Account", '2430');
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.DomesticCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.NoVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.NoVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5610');
        VATPostingSetup.Validate("Purchase VAT Account", '5630');
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."Deductible %" := 100;
        VATPostingSetup.Validate("Sales Prepayments Account", '5360');
        VATPostingSetup.Validate("Purch. Prepayments Account", '2410');
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.DomesticCode();
        VATPostingSetup."VAT Prod. Posting Group" := XxIND50;
        VATPostingSetup.Validate("VAT Identifier", XxIND50);
        VATPostingSetup.Validate("Purchase VAT Account", '5630');
        VATPostingSetup."VAT %" := 20;
        VATPostingSetup."Deductible %" := 50;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.DomesticCode();
        VATPostingSetup."VAT Prod. Posting Group" := XxE13;
        VATPostingSetup.Validate("VAT Identifier", XxE13);
        VATPostingSetup.Validate("Sales VAT Account", '5610');
        VATPostingSetup.Validate("Purchase VAT Account", '5630');
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."Deductible %" := 100;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.EUCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.ServicesVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.ServicesVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5611');
        VATPostingSetup.Validate("Purchase VAT Account", '5631');
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", '5621');
        VATPostingSetup."VAT %" := 10;
        VATPostingSetup."Deductible %" := 100;
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT";
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.EUCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.GoodsVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.GoodsVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5610');
        VATPostingSetup.Validate("Purchase VAT Account", '5630');
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", '5620');
        VATPostingSetup."VAT %" := 20;
        VATPostingSetup."Deductible %" := 100;
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT";
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.EUCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.NoVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.NoVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5610');
        VATPostingSetup.Validate("Purchase VAT Account", '5630');
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."Deductible %" := 100;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();
        CODEUNIT.Run(CODEUNIT::"Create VAT Assisted Setup");

        Window.Update(1, PaymentTerms.TableCaption());

        PaymentTerms.Init();
        PaymentTerms.Code := '306090';
        PaymentTerms.Description := X306090Days;
        if PaymentTerms.Insert() then;

        PaymentTerms.Init();
        PaymentTerms.Code := '3060';
        PaymentTerms.Description := X3060Days;
        if PaymentTerms.Insert() then;

        Window.Update(1, PaymentLines.TableCaption());

        LineNo := 0;
        for i := 1 to 3 do begin
            LineNo += 10000;
            PaymentLines.Init();
            PaymentLines.Type := PaymentLines.Type::"Payment Terms";
            PaymentLines.Code := '306090';
            PaymentLines."Line No." := LineNo;
            case i of
                1:
                    begin
                        PaymentLines."Payment %" := 33;
                        Evaluate(PaymentLines."Due Date Calculation", '<30D + CM>');
                    end;
                2:
                    begin
                        PaymentLines."Payment %" := 33;
                        Evaluate(PaymentLines."Due Date Calculation", '<60D + CM>');
                    end;
                3:
                    begin
                        PaymentLines."Payment %" := 34;
                        Evaluate(PaymentLines."Due Date Calculation", '<90D + CM>');
                    end;
            end;
            Evaluate(PaymentLines."Discount Date Calculation", '<0D>');
            if PaymentLines.Insert() then;
        end;

        LineNo := 0;

        for i := 1 to 2 do begin
            LineNo += 10000;
            PaymentLines.Init();
            PaymentLines.Type := PaymentLines.Type::"Payment Terms";
            PaymentLines.Code := '3060';
            PaymentLines."Line No." := LineNo;
            case i of
                1:
                    begin
                        PaymentLines."Payment %" := 50;
                        Evaluate(PaymentLines."Due Date Calculation", '<30D>');
                    end;
                2:
                    begin
                        PaymentLines."Payment %" := 50;
                        Evaluate(PaymentLines."Due Date Calculation", '<60D>');
                    end;
            end;
            Evaluate(PaymentLines."Discount Date Calculation", '<0D>');
            if PaymentLines.Insert() then;
        end;

        Window.Update(1, Customer.TableCaption());

        Customer.Init();
        Customer.Validate("No.", '');
        Customer.Validate(Name, XCust306090DaysPaymTerms);
        Customer.Address := XVialeMarelli72;
        Customer.City := XMilano;
        Customer."Post Code" := XIT20100;
        Customer."Gen. Bus. Posting Group" := DemoDataSetup.DomesticCode();
        Customer."VAT Bus. Posting Group" := DemoDataSetup.DomesticCode();
        Customer."Customer Posting Group" := DemoDataSetup.DomesticCode();
        Customer."Payment Terms Code" := '306090';
        Customer."Location Code" := XxBLUE;
        Customer.Insert(true);

        Window.Update(1, SalesHeader.TableCaption());

        // IT
        WorkDate := MakeAdjust.AdjustDate(DMY2Date(12, 12, 1902));
        // IT

        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := '';
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify();

        Window.Update(1, SalesLine.TableCaption());

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Validate("No.", '70000');
        SalesLine.Validate(Quantity, 10);
        SalesLine.Insert();

        SalesHeader.Invoice := true;
        SalesHeader.Ship := true;
        SalesPost.Run(SalesHeader);

        Window.Update(1, PaymentMethod.TableCaption());

        PaymentMethod.Init();
        PaymentMethod.Code := XxRIBA;
        PaymentMethod.Description := XBankReceipt;
        PaymentMethod."Bill Code" := XxRIBA;
        if PaymentMethod.Insert() then;

        Window.Update(1, SourceCode.TableCaption());

        SourceCode.Init();
        SourceCode.Code := XxRIBA;
        SourceCode.Description := XBankReceipts;
        if SourceCode.Insert() then;

        SourceCode.Init();
        SourceCode.Code := XxBANKTRANSF;
        SourceCode.Description := XBankTransfers;
        if SourceCode.Insert() then;

        Window.Update(1, NoSeries.TableCaption());

        NoSeries.Init();
        NoSeries.Code := XxTMCUSTBILL;
        NoSeries.Description := XTemporaryCustomerBillNo;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := true;
        if NoSeries.Insert() then;

        NoSeries.Init();
        NoSeries.Code := XxCUSTBILLS;
        NoSeries.Description := XFinalCustomerBillNo;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := true;
        if NoSeries.Insert() then;

        NoSeries.Init();
        NoSeries.Code := XxCUSBILLIST;
        NoSeries.Description := XCustomerBillList;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := true;
        if NoSeries.Insert() then;

        NoSeries.Init();
        NoSeries.Code := XxVNBILLIST;
        NoSeries.Description := XVendorBillsBRList;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := true;
        if NoSeries.Insert() then;

        NoSeries.Init();
        NoSeries.Code := XxVNBILLS;
        NoSeries.Description := XVendorBillsBRNo;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := true;
        if NoSeries.Insert() then;

        Window.Update(1, NoSeriesLine.TableCaption());

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := XxTMCUSTBILL;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := XxTEC00001;
        if NoSeriesLine.Insert() then;

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := XxCUSTBILLS;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := XxBILLC00001;
        if NoSeriesLine.Insert() then;

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := XxCUSBILLIST;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := XxDEC000001;
        if NoSeriesLine.Insert() then;

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := XxVNBILLIST;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := XxDEF00001;
        if NoSeriesLine.Insert() then;

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := XxVNBILLS;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := XxBILL000001;
        if NoSeriesLine.Insert() then;

        Window.Update(1, GLAccount.TableCaption());

        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgt.GetCurrentAssets());

        InsertGLAccount(GLAccount, '2450', XBills, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::"Begin-Total", GLAccountCategory);
        InsertGLAccount(GLAccount, '2460', XBillsForCollection, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);
        InsertGLAccount(GLAccount, '2470', XBillsForDiscount, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);
        InsertGLAccount(GLAccount, '2480', XBillsSubjToColl, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);
        InsertGLAccount(GLAccount, '2490', XExpenseBills, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);
        InsertGLAccount(GLAccount, '2499', XBillsTotal, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::"End-Total", GLAccountCategory);

        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Equity, GLAccountCategoryMgt.GetRetEarnings());

        InsertGLAccount(GLAccount, '3130', XGainForTheYear, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);
        InsertGLAccount(GLAccount, '3140', XLossForTheYear, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);

        GLAccount.Init();
        GLAccount."No." := '010000';
        GLAccount.Validate(Name, XSummaryAccount);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount."Account Type" := GLAccount."Account Type"::"Begin-Total";
        if GLAccount.Insert() then;

        GLAccount.Init();
        GLAccount."No." := '010010';
        GLAccount.Validate(Name, XBalance);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount."Account Type" := GLAccount."Account Type"::"Begin-Total";
        if GLAccount.Insert() then;

        GLAccountCategoryMgt.GetAccountCategory(GLAccountCategory, GLAccountCategory."Account Category"::Assets);
        InsertGLAccount(GLAccount, '010011', XOpeningBalance, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);

        InsertGLAccount(GLAccount, '010012', XClosingBalance, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);

        GLAccount.Init();
        GLAccount."No." := '010099';
        GLAccount.Validate(Name, XBalanceSheetTotal);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount."Account Type" := GLAccount."Account Type"::"End-Total";
        if GLAccount.Insert() then;

        GLAccount.Init();
        GLAccount."No." := '010100';
        GLAccount.Validate(Name, XIncomeStatement);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Income Statement";
        GLAccount."Account Type" := GLAccount."Account Type"::"Begin-Total";
        if GLAccount.Insert() then;

        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Income, GLAccountCategoryMgt.GetOtherIncomeExpense());

        InsertGLAccount(GLAccount, '010111', XGainLoss, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);

        GLAccount.Init();
        GLAccount."No." := '010199';
        GLAccount.Validate(Name, XIncomeStatementTotal);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Income Statement";
        GLAccount."Account Type" := GLAccount."Account Type"::"End-Total";
        if GLAccount.Insert() then;

        GLAccount.Init();
        GLAccount."No." := '010999';
        GLAccount.Validate(Name, XSummaryAccountTotal);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount."Account Type" := GLAccount."Account Type"::"End-Total";
        if GLAccount.Insert() then;

        GLAccountIndent.Indent();

        Window.Update(1, SalesReceivablesSetup.TableCaption());

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Temporary Bill List No." := XxTMDCUS;
        Evaluate(SalesReceivablesSetup."Bank Receipts Risk Period", '<20D>');
        SalesReceivablesSetup.Modify();

        Window.Update(1, PurchasesPayablesSetup.TableCaption());

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Temporary Bill List No." := XxTMDVEN;
        PurchasesPayablesSetup.Modify();

        Window.Update(1, BillPostingGroup.TableCaption());

        BillPostingGroup.Init();
        BillPostingGroup."No." := XxWWBUSD;
        BillPostingGroup."Payment Method" := XxRIBA;
        BillPostingGroup."Bills For Collection Acc. No." := '2460';
        BillPostingGroup."Bills For Discount Acc. No." := '2470';
        BillPostingGroup."Bills Subj. to Coll. Acc. No." := '2480';
        if BillPostingGroup.Insert() then;

        BillPostingGroup.Init();
        BillPostingGroup."No." := XxWWBUSD;
        BillPostingGroup."Payment Method" := XxBANKTRANSF;
        BillPostingGroup."Bills For Collection Acc. No." := '2460';
        BillPostingGroup."Bills For Discount Acc. No." := '2470';
        BillPostingGroup."Bills Subj. to Coll. Acc. No." := '2480';
        if BillPostingGroup.Insert() then;

        Window.Update(1, Customer.TableCaption());

        Customer.Init();
        Customer.Validate("No.", '');
        Customer.Validate(Name, XCustomerWithBankRecSrl);
        Customer.Address := XViaMagenta8;
        Customer.City := XMilano;
        Customer."Post Code" := XIT20100;
        Customer."Gen. Bus. Posting Group" := DemoDataSetup.DomesticCode();
        Customer."VAT Bus. Posting Group" := DemoDataSetup.DomesticCode();
        Customer."Customer Posting Group" := DemoDataSetup.DomesticCode();
        Customer."Payment Terms Code" := XxCM;
        Customer."Payment Method Code" := XxRIBA;
        Customer."Location Code" := XxBLUE;
        Customer.Insert(true);

        Window.Update(1, SalesHeader.TableCaption());

        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := '';
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify();

        Window.Update(1, SalesLine.TableCaption());

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Validate("No.", '70000');
        SalesLine.Validate(Quantity, 10);
        SalesLine.Insert();

        SalesHeader.Invoice := true;
        SalesHeader.Ship := true;
        Clear(SalesPost);
        SalesPost.Run(SalesHeader);

        Window.Update(1, CustomerBillHeader.TableCaption());

        IssuingCustomerBill.UseRequestPage := false;
        IssuingCustomerBill.SetPostingDescription(xPostingDescription);
        IssuingCustomerBill.SetMessageDisabled(true);
        IssuingCustomerBill.Run();

        CustomerBillHeader.Init();
        CustomerBillHeader."No." := '';
        CustomerBillHeader.Insert(true);
        // IT
        //CustomerBillHeader.VALIDATE("List Date",DMY2DATE(25,1,DATE2DMY(WORKDATE,3) + 1));
        CustomerBillHeader.Validate("List Date", DMY2Date(25, 1, Date2DMY(DemoDataSetup."Working Date", 3) + 1));
        // IT
        CustomerBillHeader.Validate("Bank Account No.", XxWWBUSD);
        CustomerBillHeader.Validate("Payment Method Code", XxRIBA);
        CustomerBillHeader.Type := CustomerBillHeader.Type::"Bills For Collection";
        CustomerBillHeader.Modify();

        Clear(SuggestCustomerBill);
        SuggestCustomerBill.InitValues(CustomerBillHeader, true);
        SuggestCustomerBill.UseRequestPage := false;
        SuggestCustomerBill.RunModal();

        DemoDataSetup.Get();
        CustomerBillPostPrint.SetHidePrintDialog(true);
        CustomerBillPostPrint.SetHTMLPath('CustBillReport.HTML');
        CustomerBillPostPrint.Code(CustomerBillHeader);

        Window.Update(1, Vendor.TableCaption());

        Vendor.Init();
        Vendor.Validate("No.", '');
        Vendor.Validate(Name, XVendorWithBankRecSrl);
        Vendor.Address := XPiazzaleGiulioCesare8;
        Vendor.City := XMilano;
        Vendor."Post Code" := XIT20100;
        Vendor."Gen. Bus. Posting Group" := DemoDataSetup.DomesticCode();
        Vendor."VAT Bus. Posting Group" := DemoDataSetup.DomesticCode();
        Vendor."Vendor Posting Group" := DemoDataSetup.DomesticCode();
        Vendor."Payment Terms Code" := XxCM;
        Vendor."Payment Method Code" := XxBANKTRANSF;
        Vendor."Location Code" := XxBLUE;
        Vendor.Insert(true);

        Window.Update(1, PurchaseHeader.TableCaption());

        // IT
        WorkDate := MakeAdjust.AdjustDate(DMY2Date(31, 12, 1902));
        // IT

        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := '';
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader."Vendor Invoice No." := XxINV001;
        PurchaseHeader."Check Total" := 1200;
        PurchaseHeader.Modify();

        Window.Update(1, PurchaseLine.TableCaption());

        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine.Validate("No.", '70000');
        PurchaseLine.Validate(Quantity, 1);
        PurchaseLine.Validate("Direct Unit Cost", 1000);
        PurchaseLine.Insert();

        PurchaseHeader.Invoice := true;
        PurchaseHeader.Receive := true;
        PurchPost.Run(PurchaseHeader);

        Window.Update(1, VendorBillHeader.TableCaption());

        VendorBillHeader.Init();
        VendorBillHeader."No." := '';
        VendorBillHeader.Insert(true);
        VendorBillHeader.Validate("Bank Account No.", XxWWBUSD);
        VendorBillHeader.Validate("Payment Method Code", XxBANKTRANSF);
        VendorBillHeader."Beneficiary Value Date" := WorkDate();
        VendorBillHeader.Modify();

        SuggestVendorBills.InitValues(VendorBillHeader);
        SuggestVendorBills.UseRequestPage := false;
        SuggestVendorBills.RunModal();

        VendBillListChangeStatus.FromOpenToSent(VendorBillHeader);
        VendorBillListPost.Code(VendorBillHeader);

        // Example of vendor with withh. tax

        Window.Update(1, Vendor.TableCaption());

        Vendor.Init();
        Vendor.Validate("No.", '');
        Vendor.Validate(Name, XVendorWithWithhTax);
        Vendor.Address := XCorsoColombo10;
        Vendor.City := XMilano;
        Vendor."Post Code" := XIT20100;
        Vendor.Validate("Gen. Bus. Posting Group", DemoDataSetup.DomesticCode());
        Vendor.Validate("VAT Bus. Posting Group", DemoDataSetup.DomesticCode());
        Vendor.Validate("Vendor Posting Group", DemoDataSetup.DomesticCode());
        Vendor.Validate("Withholding Tax Code", XxPROFESS);
        Vendor.Insert(true);

        Window.Update(1, PurchaseHeader.TableCaption());

        InsertPurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.", '1010', 600);
        InsertPurchaseLine(PurchaseHeader, Vendor, 10000, PurchaseLine.Type::"G/L Account", '8320', 1, XxDAY, 500, '');
        WithhSocSecTax.CalculateWithholdingTax(PurchaseHeader, false);

        InsertPurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.", '1011', 0);
        InsertPurchaseLine(PurchaseHeader, Vendor, 10000, PurchaseLine.Type::"G/L Account", '8320', 1, XxDAY, 1000, '');
        WithhSocSecTax.CalculateWithholdingTax(PurchaseHeader, false);

        InsertPurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.", '1012', 0);
        InsertPurchaseLine(PurchaseHeader, Vendor, 10000, PurchaseLine.Type::"G/L Account", '8310', 1, XxPCS, 2000, '');
        InsertPurchaseLine(PurchaseHeader, Vendor, 20000, PurchaseLine.Type::"G/L Account", '8320', 1, XxDAY, 630, '');
        InsertPurchaseLine(PurchaseHeader, Vendor, 30000, PurchaseLine.Type::Item, '70000', 11, '', 0, XxBLUE);
        WithhSocSecTax.CalculateWithholdingTax(PurchaseHeader, false);

        Window.Close();
    end;

    var
        XEnteringData: Label 'Entering data...\\';
        XTableXXX: Label 'Table #1###################\';
        XxEUPURCH: Label 'EUPURCH';
        XEUPurchaseRegister: Label 'EU Purchase Register';
        XxEXTPURCH: Label 'EXTPURCH';
        XExtraEUPurchaseRegister: Label 'ExtraEU Purchase Register';
        XxNATPURCH: Label 'NATPURCH';
        XNationalPurchaseRegister: Label 'National Purchase Register';
        XxEUSALES: Label 'EUSALES';
        XEUSalesRegister: Label 'EU Sales Register';
        XxEXTSALES: Label 'EXTSALES';
        XExtraEUSalesRegister: Label 'ExtraEU Sales Register';
        XxNATSALES: Label 'NATSALES';
        XNationalSalesRegister: Label 'National Sales Register';
        XxE10: Label 'E10';
        XTaxExemptArt10: Label 'Tax exempt - art. 10';
        XxE13: Label 'E13';
        XTaxExemptArt13: Label 'Tax exempt - art. 13';
        XxFCI2: Label 'FCI2';
        XxFCIArt2: Label 'F.C.I. Art.2';
        XxIND100: Label 'IND100';
        XVAT20PERC100PERCNondeductible: Label 'VAT 20% - 100% Nondeductible';
        XxIND50: Label 'IND50';
        XVAT20PERC50PERCNondeductible: Label 'VAT 20% - 50% Nondeductible';
        XxVAT10PERC: Label 'VAT 10%';
        XxVAT20PERC: Label 'VAT 20%';
        XxNI41: Label 'NI41';
        XNIArt41DL331slash93: Label 'N.I. Art. 41  DL 331/93';
        XxNI8: Label 'NI8';
        XNonTaxableArt8slash1: Label 'Non Taxable - Art. 8/1';
        XxNI9: Label 'NI9';
        XNonTaxableArt9: Label 'Non Taxable - Art. 9';
        XNonTaxable: Label 'Non taxable';
        XOrdVAT20PERC100PERCNondeduct: Label 'Ord. VAT % (20%) - 100% Nondeductible';
        XOrdVAT20PERC50PERCNondeduct: Label 'Ord. VAT % (20%) - 50% Nondeductible';
        XxVAT0: Label 'VAT0';
        XZeroPERCTaxExemptNIFCIOthers: Label 'Zero % (Tax exempt/N.I./FCI/Others)';
        XxVAT04: Label 'VAT04';
        XMinimumVAT4PERC: Label 'Minimum VAT % - 4%';
        XReducedVAT10PERC: Label 'Reduced VAT % - 10%';
        XOrdinaryVAT20PERC: Label 'Ordinary VAT % - 20%';
        XxEXTVNSLS: Label 'EXT-VN-SLS';
        XInvCrMemoVATNoForExtraEUCust: Label 'Inv./Cr. Memo VAT No. for ExtraEU Customers';
        XxEXTVNPUR: Label 'EXT-VN-PUR';
        XInvCrMemoVATNoForExtraEUVend: Label 'Inv./Cr. Memo VAT No. for ExtraEU Vendors';
        XxITVNSLS: Label 'IT-VN-SLS';
        XInvCrMemoVATNoForItalianCust: Label 'Inv./Cr. Memo VAT No. for Italian Cust.';
        XxITVNPUR: Label 'IT-VN-PUR';
        XInvCrMemoVATNoForItalianVend: Label 'Inv./Cr. Memo VAT No. for Italian Vend.';
        XxEUVNSLS: Label 'EU-VN-SLS';
        XInvCrMemoVATNoForEUCust: Label 'Inv./Cr. Memo VAT No. for EU Cust.';
        XxEUVNPUR: Label 'EU-VN-PUR';
        XInvCrMemoVATNoForEUVend: Label 'Inv./Cr. Memo VAT No. for EU Vend.';
        XxCX0PERC10001: Label 'CX0%10001';
        XxC0PERC10001: Label 'C0%10001';
        XxV0PERC10001: Label 'V0%10001';
        XxFX0PERC10001: Label 'FX0%10001';
        X306090Days: Label '30, 60, 90 Days';
        X3060Days: Label '30, 60 Days';
        XCust306090DaysPaymTerms: Label 'Cust. 30,60,90 days paym.terms';
        XVialeMarelli72: Label 'Viale Marelli, 72';
        XMilano: Label 'Milano';
        XIT20100: Label '20100';
        XxBLUE: Label 'BLUE';
        XxRIBA: Label 'RIBA';
        XBankReceipt: Label 'Bank Receipt';
        XBankReceipts: Label 'Bank Receipts';
        XxBANKTRANSF: Label 'BANKTRANSF';
        XBankTransfers: Label 'Bank Transfers';
        XxTMCUSTBILL: Label 'TMCUSTBILL';
        XTemporaryCustomerBillNo: Label 'Temporary Customer Bill No.';
        XxCUSTBILLS: Label 'CUSTBILLS';
        XFinalCustomerBillNo: Label 'Final Customer Bill No.';
        XxCUSBILLIST: Label 'CUSBILLIST';
        XCustomerBillList: Label 'Customer Bill List';
        XxVNBILLIST: Label 'VNBILLIST';
        XVendorBillsBRList: Label 'Vendor Bills/BR list';
        XxVNBILLS: Label 'VNBILLS';
        XVendorBillsBRNo: Label 'Vendor Bills/BR No.';
        XxTEC00001: Label 'TEC00001';
        XxBILLC00001: Label 'BILLC00001';
        XxDEC000001: Label 'DEC000001';
        XxDEF00001: Label 'DEF00001';
        XxBILL000001: Label 'BILL000001';
        XBills: Label 'Bills';
        XBillsForCollection: Label 'Bills for Collection';
        XBillsForDiscount: Label 'Bills for Discount';
        XExpenseBills: Label 'Expense Bills';
        XBillsSubjToColl: Label 'Bills Subj. to Coll.';
        XBillsTotal: Label 'Bills Total';
        XGainForTheYear: Label 'Gain for the Year';
        XLossForTheYear: Label 'Loss for the Year';
        XSummaryAccount: Label 'Summary Account';
        XBalance: Label 'Balance';
        XOpeningBalance: Label 'Opening Balance';
        XClosingBalance: Label 'Closing Balance';
        XBalanceSheetTotal: Label 'Balance Sheet Total';
        XIncomeStatement: Label 'Income Statement';
        XGainLoss: Label 'Gain/Loss';
        XIncomeStatementTotal: Label 'Income Statement Total';
        XSummaryAccountTotal: Label 'Summary Account Total';
        XxTMDCUS: Label 'TMDCUS';
        XxTMDVEN: Label 'TMDVEN';
        XxWWBUSD: Label 'WWB-USD';
        XCustomerWithBankRecSrl: Label 'Customer with Bank Rec. S.r.l.';
        XViaMagenta8: Label 'via Magenta, 8';
        XxCM: Label 'CM';
        XVendorWithBankRecSrl: Label 'Vendor with Bank Rec. S.r.l.';
        XPiazzaleGiulioCesare8: Label 'piazzale Giulio Cesare, 8';
        XxINV001: Label 'INV001';
        XVendorWithWithhTax: Label 'Vendor with Withh. Tax';
        XCorsoColombo10: Label 'corso Colombo, 10';
        XxPROFESS: Label 'PROFESS';
        XxDAY: Label 'DAY';
        XxPCS: Label 'PCS';
        PaymentTerms: Record "Payment Terms";
        PaymentLines: Record "Payment Lines";
        PaymentMethod: Record "Payment Method";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BillPostingGroup: Record "Bill Posting Group";
        SourceCode: Record "Source Code";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesLineSales: Record "No. Series Line";
        NoSeriesLinePurchase: Record "No. Series Line";
        GLAccount: Record "G/L Account";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GLSetup: Record "General Ledger Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorBillHeader: Record "Vendor Bill Header";
        VATRegister: Record "VAT Register";
        VATIdentifier: Record "VAT Identifier";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        DemoDataSetup: Record "Demo Data Setup";
        GLAccountCategory: Record "G/L Account Category";
        SuggestCustomerBill: Report "Suggest Customer Bills";
        SuggestVendorBills: Report "Suggest Vendor Bills";
        IssuingCustomerBill: Report "Issuing Customer Bill";
        GLAccountIndent: Codeunit "G/L Account-Indent";
        SalesPost: Codeunit "Sales-Post";
        PurchPost: Codeunit "Purch.-Post";
        CustomerBillPostPrint: Codeunit "Customer Bill - Post + Print";
        VendBillListChangeStatus: Codeunit "Vend. Bill List-Change Status";
        VendorBillListPost: Codeunit "Vendor Bill List - Post";
        WithhSocSecTax: Codeunit "Withholding - Contribution";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        Window: Dialog;
        i: Integer;
        LineNo: Integer;
        xPostingDescription: Label 'Posting Description';
        MakeAdjust: Codeunit "Make Adjustments";

    local procedure InsertVATRegister("Code": Code[10]; Type: Option; Description: Text[30])
    begin
        VATRegister.Init();
        VATRegister.Code := Code;
        VATRegister.Type := Type;
        VATRegister.Description := Description;
        if VATRegister.Insert() then;
    end;

    local procedure InsertVATIdentifier("Code": Code[10]; Description: Text[30])
    begin
        VATIdentifier.Init();
        VATIdentifier.Code := Code;
        VATIdentifier.Description := Description;
        if VATIdentifier.Insert() then;
    end;

    local procedure InsertVATProductPostingGroup("Code": Code[10]; Description: Text[50])
    begin
        VATProductPostingGroup.Init();
        VATProductPostingGroup.Code := Code;
        VATProductPostingGroup.Description := Description;
        if not VATProductPostingGroup.Insert() then
            VATProductPostingGroup.Modify();
    end;

    local procedure InsertNoSeries("Code": Code[20]; Description: Text[50]; NoSeriesType: Enum "No. Series Type"; VATRegister: Code[10]; ReverseSalesVATNoSeries: Code[20])
    begin
        NoSeries.Init();
        NoSeries.Code := Code;
        NoSeries.Description := Description;
        NoSeries."No. Series Type" := NoSeriesType;
        if VATRegister <> '' then
            NoSeries.Validate("VAT Register", VATRegister);
        if ReverseSalesVATNoSeries <> '' then
            NoSeries.Validate("Reverse Sales VAT No. Series", ReverseSalesVATNoSeries);
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := true;
        if NoSeries.Insert() then;
    end;

    local procedure InsertPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; VendorInvoiceNo: Code[35]; CheckTotal: Decimal)
    begin
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := '';
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchaseHeader."Vendor Invoice No." := VendorInvoiceNo;
        PurchaseHeader."Check Total" := CheckTotal;
        PurchaseHeader.Modify();
    end;

    local procedure InsertPurchaseLine(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor; LineNo: Integer; AccountType: Enum "Purchase Document Type"; AccountNo: Code[20]; Qty: Decimal; UoMCode: Code[10]; UnitCost: Decimal; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := LineNo;
        PurchaseLine."Buy-from Vendor No." := Vendor."No.";
        PurchaseLine.Type := AccountType;
        PurchaseLine.Validate("No.", AccountNo);
        PurchaseLine.Validate(Quantity, Qty);
        PurchaseLine.Validate("Unit of Measure Code", UoMCode);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Insert();
    end;

    local procedure InsertGLAccount(var GLAccount: Record "G/L Account"; No: Code[20]; Name: Text[50]; IncomeBalance: Enum "G/L Account Report Type"; Type: Enum "G/L Account Type"; GLAccountCategory: Record "G/L Account Category")
    begin
        GLAccount.Init();
        GLAccount."No." := No;
        GLAccount.Validate(Name, Name);
        GLAccount."Income/Balance" := IncomeBalance;
        GLAccount."Account Type" := Type;
        GLAccount."Account Category" := "G/L Account Category".FromInteger(GLAccountCategory."Account Category");
        GLAccount."Account Subcategory Entry No." := GLAccountCategory."Entry No.";
        if GLAccount.Insert() then;
    end;

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();

        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgt.GetCurrentAssets());

        InsertGLAccount(GLAccount, '2450', XBills, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::"Begin-Total", GLAccountCategory);
        InsertGLAccount(GLAccount, '2460', XBillsForCollection, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);
        InsertGLAccount(GLAccount, '2470', XBillsForDiscount, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);
        InsertGLAccount(GLAccount, '2480', XBillsSubjToColl, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);
        InsertGLAccount(GLAccount, '2490', XExpenseBills, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);
        InsertGLAccount(GLAccount, '2499', XBillsTotal, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::"End-Total", GLAccountCategory);

        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Equity, GLAccountCategoryMgt.GetRetEarnings());

        InsertGLAccount(GLAccount, '3130', XGainForTheYear, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);
        InsertGLAccount(GLAccount, '3140', XLossForTheYear, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);

        GLAccount.Init();
        GLAccount."No." := '010000';
        GLAccount.Validate(Name, XSummaryAccount);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount."Account Type" := GLAccount."Account Type"::"Begin-Total";
        if GLAccount.Insert() then;

        GLAccount.Init();
        GLAccount."No." := '010010';
        GLAccount.Validate(Name, XBalance);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount."Account Type" := GLAccount."Account Type"::"Begin-Total";
        if GLAccount.Insert() then;

        GLAccountCategoryMgt.GetAccountCategory(GLAccountCategory, GLAccountCategory."Account Category"::Assets);
        InsertGLAccount(GLAccount, '010011', XOpeningBalance, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);

        InsertGLAccount(GLAccount, '010012', XClosingBalance, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);

        GLAccount.Init();
        GLAccount."No." := '010099';
        GLAccount.Validate(Name, XBalanceSheetTotal);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount."Account Type" := GLAccount."Account Type"::"End-Total";
        if GLAccount.Insert() then;

        GLAccount.Init();
        GLAccount."No." := '010100';
        GLAccount.Validate(Name, XIncomeStatement);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Income Statement";
        GLAccount."Account Type" := GLAccount."Account Type"::"Begin-Total";
        if GLAccount.Insert() then;

        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Income, GLAccountCategoryMgt.GetOtherIncomeExpense());

        InsertGLAccount(GLAccount, '010111', XGainLoss, GLAccount."Income/Balance"::"Balance Sheet",
          GLAccount."Account Type"::Posting, GLAccountCategory);

        GLAccount.Init();
        GLAccount."No." := '010199';
        GLAccount.Validate(Name, XIncomeStatementTotal);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Income Statement";
        GLAccount."Account Type" := GLAccount."Account Type"::"End-Total";
        if GLAccount.Insert() then;

        GLAccount.Init();
        GLAccount."No." := '010999';
        GLAccount.Validate(Name, XSummaryAccountTotal);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount."Account Type" := GLAccount."Account Type"::"End-Total";
        if GLAccount.Insert() then;

        GLAccountIndent.Indent();

        InsertVATIdentifier(XxE10, XTaxExemptArt10);
        InsertVATIdentifier(XxE13, XTaxExemptArt13);
        InsertVATIdentifier(XxFCI2, XxFCIArt2);
        InsertVATIdentifier(XxIND100, XVAT20PERC100PERCNondeductible);
        InsertVATIdentifier(XxIND50, XVAT20PERC50PERCNondeductible);
        InsertVATIdentifier(DemoDataSetup.ServicesVATCode(), XxVAT10PERC);
        InsertVATIdentifier(DemoDataSetup.GoodsVATCode(), XxVAT20PERC);
        InsertVATIdentifier(XxNI41, XNIArt41DL331slash93);
        InsertVATIdentifier(XxNI8, XNonTaxableArt8slash1);
        InsertVATIdentifier(XxNI9, XNonTaxableArt9);
        InsertVATIdentifier(DemoDataSetup.NoVATCode(), XNonTaxable);

        InsertVATProductPostingGroup(XxE13, XTaxExemptArt13);
        InsertVATProductPostingGroup(XxIND100, XOrdVAT20PERC100PERCNondeduct);
        InsertVATProductPostingGroup(XxIND50, XOrdVAT20PERC50PERCNondeduct);
        InsertVATProductPostingGroup(XxVAT0, XZeroPERCTaxExemptNIFCIOthers);
        InsertVATProductPostingGroup(XxVAT04, XMinimumVAT4PERC);
        InsertVATProductPostingGroup(DemoDataSetup.ServicesVATCode(), XReducedVAT10PERC);
        InsertVATProductPostingGroup(DemoDataSetup.GoodsVATCode(), XOrdinaryVAT20PERC);
        InsertVATProductPostingGroup(XxNI8, XNonTaxableArt8slash1);

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := '';
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.ServicesVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.ServicesVATCode());
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."Deductible %" := 100;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := '';
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.GoodsVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.GoodsVATCode());
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."Deductible %" := 100;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := '';
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.NoVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.NoVATCode());
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."Deductible %" := 100;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.ExportCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.ServicesVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.ServicesVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5611');
        VATPostingSetup.Validate("Purchase VAT Account", '5631');
        VATPostingSetup."VAT %" := 10;
        VATPostingSetup."Deductible %" := 100;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.ExportCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.GoodsVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.GoodsVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5610');
        VATPostingSetup.Validate("Purchase VAT Account", '5630');
        VATPostingSetup."VAT %" := 20;
        VATPostingSetup."Deductible %" := 100;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.ExportCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.NoVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.NoVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5610');
        VATPostingSetup.Validate("Purchase VAT Account", '5630');
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."Deductible %" := 100;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.DomesticCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.ServicesVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.ServicesVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5611');
        VATPostingSetup.Validate("Purchase VAT Account", '5631');
        VATPostingSetup."VAT %" := 10;
        VATPostingSetup."Deductible %" := 100;
        VATPostingSetup.Validate("Sales Prepayments Account", '5370');
        VATPostingSetup.Validate("Purch. Prepayments Account", '2420');
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.DomesticCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.GoodsVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.GoodsVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5610');
        VATPostingSetup.Validate("Purchase VAT Account", '5630');
        VATPostingSetup."VAT %" := 20;
        VATPostingSetup."Deductible %" := 100;
        VATPostingSetup.Validate("Sales Prepayments Account", '5380');
        VATPostingSetup.Validate("Purch. Prepayments Account", '2430');
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.DomesticCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.NoVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.NoVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5610');
        VATPostingSetup.Validate("Purchase VAT Account", '5630');
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."Deductible %" := 100;
        VATPostingSetup.Validate("Sales Prepayments Account", '5360');
        VATPostingSetup.Validate("Purch. Prepayments Account", '2410');
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.DomesticCode();
        VATPostingSetup."VAT Prod. Posting Group" := XxIND50;
        VATPostingSetup.Validate("VAT Identifier", XxIND50);
        VATPostingSetup.Validate("Purchase VAT Account", '5630');
        VATPostingSetup."VAT %" := 20;
        VATPostingSetup."Deductible %" := 50;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.DomesticCode();
        VATPostingSetup."VAT Prod. Posting Group" := XxE13;
        VATPostingSetup.Validate("VAT Identifier", XxE13);
        VATPostingSetup.Validate("Sales VAT Account", '5610');
        VATPostingSetup.Validate("Purchase VAT Account", '5630');
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."Deductible %" := 100;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.EUCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.ServicesVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.ServicesVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5611');
        VATPostingSetup.Validate("Purchase VAT Account", '5631');
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", '5621');
        VATPostingSetup."VAT %" := 10;
        VATPostingSetup."Deductible %" := 100;
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT";
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.EUCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.GoodsVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.GoodsVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5610');
        VATPostingSetup.Validate("Purchase VAT Account", '5630');
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", '5620');
        VATPostingSetup."VAT %" := 20;
        VATPostingSetup."Deductible %" := 100;
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT";
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();

        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := DemoDataSetup.EUCode();
        VATPostingSetup."VAT Prod. Posting Group" := DemoDataSetup.NoVATCode();
        VATPostingSetup.Validate("VAT Identifier", DemoDataSetup.NoVATCode());
        VATPostingSetup.Validate("Sales VAT Account", '5610');
        VATPostingSetup.Validate("Purchase VAT Account", '5630');
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup."Deductible %" := 100;
        if not VATPostingSetup.Insert() then
            VATPostingSetup.Modify();
    end;
}

