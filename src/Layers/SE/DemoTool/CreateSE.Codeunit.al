codeunit 160700 "Create SE"
{
    //  // Skapa SE demo-data fÔÇØr moms
    // Skapad ursprungligen manuellt i 3.70  av Ann Berzelius
    // 
    // 16. Komplettering med moms produktbokfÔÇØringsmallen ENBART att anvÔÇ×nda vid manuell
    // momskontering av inhemska leverantÔÇØrsfakturor samt tillhÔÇØrande
    // momsbokfÔÇØringsinstÔÇ×llningar. Lagt upp nytt konto, 2641, fÔÇØr att kunna sÔÇ×rskilja dessa
    // transaktioner.
    // 
    // 17. Ny momsrapport som mer ÔÇØverensstÔÇ×mmer med skattedeklarationen. Radnr
    // ÔÇØverensstÔÇ×mmer nÔÇágorlunda med radnr pÔÇá momsrapporten. Riktigt korrekt kan den inte gÔÇØras
    // eftersom demodatan innehÔÇáller momssats 10%, vilken sÔÇáklart inte finns med pÔÇá
    // skattedeklarationen.
    // -----------------------------------------------------------
    // Including the Swedish translations of the text-constants
    // -----------------------------------------------------------
    // C50998-Q1070001-P2818-L30:DomesticCode
    // C50998-Q1070001-P26171-A1033-L999:NATIONAL
    // C50998-Q1070001-P26171-A1053-L999:NATIONELL
    // C50998-Q1070002-P2818-L30:XONLY
    // C50998-Q1070002-P26171-A1033-L999:Only
    // C50998-Q1070002-P26171-A1053-L999:Enbart
    // 
    // C50998-U1070001-Q1070001-P2818-L30:KontoNr
    // C50998-U1070001-Q1070001-P26171-A1033-L999:Only VAT
    // C50998-U1070001-Q1070001-P26171-A1053-L999:IngÔÇáende moms enbart
    // C50998-U1070001-Q1070002-P2818-L30:GenProdPostGroup
    // C50998-U1070001-Q1070002-P26171-A1033-L999:MISC
    // C50998-U1070001-Q1070002-P26171-A1053-L999:DIV
    // 
    // C50998-U1070000-Q1070001-P2818-L30:XCode
    // C50998-U1070000-Q1070001-P26171-A1033-L999:Only
    // C50998-U1070000-Q1070001-P26171-A1053-L999:Enbart
    // C50998-U1070000-Q1070002-P2818-L30:XDesc
    // C50998-U1070000-Q1070002-P26171-A1033-L999:Only VAT
    // C50998-U1070000-Q1070002-P26171-A1053-L999:Enbart moms
    // 
    // C50998-U1070003-Q1070001-P2818-L30:VatStamentTemplateName
    // C50998-U1070003-Q1070001-P26171-A1033-L999:VAT
    // C50998-U1070003-Q1070001-P26171-A1053-L999:MOMS
    // C50998-U1070003-Q1070002-P2818-L30:VATStatementName
    // C50998-U1070003-Q1070002-P26171-A1033-L999:SE STD
    // C50998-U1070003-Q1070002-P26171-A1053-L999:SE STD
    // C50998-U1070003-Q1070003-P2818-L30:VATStatementDescription
    // C50998-U1070003-Q1070003-P26171-A1033-L999:SE Standard
    // C50998-U1070003-Q1070003-P26171-A1053-L999:SE Standard
    // 
    // C50998-U1070004-Q1070000-P2818-L30:DomesticCode
    // C50998-U1070004-Q1070000-P26171-A1033-L999:NATIONAL
    // C50998-U1070004-Q1070000-P26171-A1053-L999:NATIONELL
    // C50998-U1070004-Q1070001-P2818-L30:XVat10
    // C50998-U1070004-Q1070001-P26171-A1033-L999:VAT12
    // C50998-U1070004-Q1070001-P26171-A1053-L999:MOMS10
    // C50998-U1070004-Q1070002-P2818-L30:XVat25
    // C50998-U1070004-Q1070002-P26171-A1033-L999:VAT25
    // C50998-U1070004-Q1070002-P26171-A1053-L999:MOMS25
    // C50998-U1070004-Q1070003-P2818-L30:XExport
    // C50998-U1070004-Q1070003-P26171-A1033-L999:EXPORT
    // C50998-U1070004-Q1070003-P26171-A1053-L999:EXPORT
    // C50998-U1070004-Q1070004-P2818-L30:XEU
    // C50998-U1070004-Q1070004-P26171-A1033-L999:EU
    // C50998-U1070004-Q1070004-P26171-A1053-L999:EU
    // C50998-U1070004-Q1070005-P2818-L30:XNoVat
    // C50998-U1070004-Q1070005-P26171-A1033-L999:NO VAT
    // C50998-U1070004-Q1070005-P26171-A1053-L999:INGEN MOMS
    // C50998-U1070004-Q1070006-P2818-L30:XOnly
    // C50998-U1070004-Q1070006-P26171-A1033-L999:Only
    // C50998-U1070004-Q1070006-P26171-A1053-L999:Enbart
    // 
    // C50998-U1-Q1070000-P2818-L30:XVAT
    // C50998-U1-Q1070000-P26171-A1033-L999:VAT
    // C50998-U1-Q1070000-P26171-A1053-L999:MOMS
    // C50998-U1-Q1070001-P2818-L30:XSESTD
    // C50998-U1-Q1070001-P26171-A1033-L999:SE STD
    // C50998-U1-Q1070001-P26171-A1053-L999:SE STD


    trigger OnRun()
    begin
        InsertMiniAppData();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XONLY: Label 'ONLY';
        XGoteborgTxt: Label 'GÔÇØteborg';
        TransportMethod: Record "Transport Method";
        XTurnoverinSweden: Label 'A. Sales subject to VAT or withdrawals excl. VAT';
        XSalesinSweden25: Label 'National Sale 25%';
        XSalesinSweden12: Label 'National Sale 12 %';
        XSalesinSweden6: Label 'National Sale 6%';
        XSalesSubjectVATEU: Label 'Sales subject to VAT not included in boxes below';
        XSelfSupply: Label 'Self-supply subject to VAT';
        XTaxablebasis: Label 'Taxable basis for profit margin taxation';
        XRentalIncome: Label 'Rental income';
        XVoluntaryTax: Label '- voluntary tax liability';
        XOutputVAT: Label 'Output VAT on sales or self-supply in boxes 05-08';
        XOutputVAT25: Label 'Output VAT 25%';
        XOutputVAT12: Label 'Output VAT 12%';
        XOutputVAT6: Label 'Output VAT 6%';
        XPurchaseSubject: Label 'Purchases subj to VAT where purchaser subj to VAT';
        XPurchaseEU25: Label 'Purchase EU 25%';
        XPurchaseEU12: Label 'Purchase EU 12%';
        XPurchaseEU6: Label 'Purchase EU 6%';
        XPurchaseEU0: Label 'Purchase EU 0%';
        XPurchaseGoodEC: Label 'Purchase of goods from another EC country';
        XPurchaseServicesEC: Label 'Purchases of services from another EC country';
        XPurchaseServicesOutsideEC: Label 'Purchase of services from a country outside the EC';
        XPurchaseGoodSE: Label 'Purchases of goods in Sweden';
        XPurchaseServicesSE: Label 'Purchases of services in Sweden';
        XOutputVATpurchases: Label 'Output VAT on purchases in Boxes 20-24';
        XSalesexemptVAT: Label 'Sales etc. which are exempt from VAT';
        XEUSales25: Label 'EU Sales 25%';
        XEUSales12: Label 'EU Sales 12%';
        XEUSales6: Label 'EU Sales 6%';
        XEUSales0: Label 'EU Sales 0%';
        XSalesGoodAnotherEC: Label 'Sales of goods to another EC country';
        XExportSales25: Label 'Export Sales 25%';
        XExportSales12: Label 'Export Sales 12%';
        XExportSales6: Label 'Export Sales 6%';
        XSalesOutsideEC: Label 'Sales of goods outside the EC';
        XPurchasemiddleman: Label 'Purch. of goods by middleman in triang. trade';
        XSalesmiddleman: Label 'Sales of goods by middleman in triangular trading';
        XSalesServiceanotherEC: Label 'Service sale with purch. subj. to VAT in ECcountry';
        XOtherSales: Label 'Other sales of services turn-over outside SE';
        XSalesSE: Label 'Sales in which the purch. is subject to VAT in SE';
        XOtherSalesetc: Label 'Other Sales etc.';
        XFInputVAT: Label 'F. Input VAT';
        XPurchaseSE25: Label 'Purchase Sweden 25%';
        XPurchaseSE12: Label 'Purchase Sweden 12%';
        XPurchaseSE6: Label 'Purchase Sweden 6%';
        XPurchaseSE0: Label 'Purchase Sweden 0%';
        XPurchaseSEOnly: Label 'Purchase Sweden only';
        XInputVAT: Label 'Input VAT to deduct';
        XVATpayrefunded: Label 'VAT to pay or be refunded';
        NextLine: Integer;

    procedure CreateDeleteGLAccount()
    var
        GLAccount: Record "G/L Account";
        KontoNr: Label 'Only VAT';
        GenProdPostGroup: Label 'ONLY';
    begin
        if GLAccount.Get('2641') then begin
            GLAccount.Validate(Name, KontoNr);
            GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
            GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostGroup);
            GLAccount.Modify(true);
        end;

        if GLAccount.Get('5795') then GLAccount.Delete(true);
        if GLAccount.Get('5796') then GLAccount.Delete(true);
        if GLAccount.Get('5797') then GLAccount.Delete(true);
        if GLAccount.Get('5799') then GLAccount.Delete(true);
    end;

    procedure CreateVATProductPostingGroup()
    var
        "VAT Product Posting Group": Record "VAT Product Posting Group";
        XCode: Label 'Only';
        XDesc: Label 'Manually posted VAT';
    begin
        "VAT Product Posting Group".Init();
        "VAT Product Posting Group".Validate(Code, XCode);
        "VAT Product Posting Group".Validate(Description, XDesc);

        if "VAT Product Posting Group".Insert() then;
    end;

    procedure CreateVATPostingSetup()
    var
        "VAT Posting Setup": Record "VAT Posting Setup";
    begin
        "VAT Posting Setup".Init();

        "VAT Posting Setup".Validate("VAT Bus. Posting Group", DemoDataSetup.DomesticCode());
        "VAT Posting Setup".Validate("VAT Prod. Posting Group", XONLY);
        "VAT Posting Setup".Validate("VAT Identifier", XONLY);
        "VAT Posting Setup".Validate("VAT Calculation Type", "VAT Posting Setup"."VAT Calculation Type"::"Full VAT");
        "VAT Posting Setup".Validate("VAT %", 0);
        "VAT Posting Setup".Validate("Purchase VAT Account", '2641');

        if "VAT Posting Setup".Insert() then;
    end;

    procedure CreateVATName()
    var
        "VAT Statement Name": Record "VAT Statement Name";
        VatStamentTemplateName: Label 'VAT';
        VATStatementName: Label 'SE STD';
        VATStatementDescription: Label 'SE Standard';
    begin
        "VAT Statement Name".Init();
        "VAT Statement Name".Validate("Statement Template Name", VatStamentTemplateName);
        "VAT Statement Name".Validate(Name, VATStatementName);
        "VAT Statement Name".Validate(Description, VATStatementDescription);
        if "VAT Statement Name".Insert() then;
    end;

    procedure CreateVATLines()
    var
        XVat6: Label 'VAT6';
        XVat12: Label 'VAT12';
        XVat25: Label 'VAT25';
        XNoVat: Label 'NO VAT';
    begin
        NextLine := 0;
        InsertData('', XTurnoverinSweden, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('0501', XSalesinSweden25, 1, '', 2, DemoDataSetup.DomesticCode(), XVat25, '', 2, 0, false, 1, false);
        InsertData('0502', XSalesinSweden12, 1, '', 2, DemoDataSetup.DomesticCode(), XVat12, '', 2, 0, false, 1, false);
        InsertData('0503', XSalesinSweden6, 1, '', 2, DemoDataSetup.DomesticCode(), XVat6, '', 2, 0, false, 1, false);
        InsertData('05', XSalesSubjectVATEU, 2, '', 0, '', '', '0501..0599', 0, 0, true, 1, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('06', XSelfSupply, 1, '', 0, '', '', '', 0, 0, false, 1, false);
        InsertData('', '', 0, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('07', XTaxablebasis, 1, '', 0, '', '', '', 0, 0, false, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('08', XRentalIncome, 1, '', 0, '', '', '', 0, 0, true, 1, false);
        InsertData('', XVoluntaryTax, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', XOutputVAT, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('10', XOutputVAT25, 1, '', 2, DemoDataSetup.DomesticCode(), XVat25, '', 1, 0, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('11', XOutputVAT12, 1, '', 2, DemoDataSetup.DomesticCode(), XVat12, '', 1, 0, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('12', XOutputVAT6, 1, '', 2, DemoDataSetup.DomesticCode(), XVat6, '', 1, 0, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', XPurchaseSubject, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('2001', XPurchaseEU25, 1, '', 1, DemoDataSetup.EUCode(), XVat25, '', 2, 0, false, 0, false);
        InsertData('2002', XPurchaseEU12, 1, '', 1, DemoDataSetup.EUCode(), XVat12, '', 2, 0, false, 0, false);
        InsertData('2003', XPurchaseEU6, 1, '', 1, DemoDataSetup.EUCode(), XVat6, '', 2, 0, false, 0, false);
        InsertData('2004', XPurchaseEU0, 1, '', 1, DemoDataSetup.EUCode(), XNoVat, '', 2, 0, false, 0, false);
        InsertData('20', XPurchaseGoodEC, 2, '', 0, '', '', '2001..2099', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('21', XPurchaseServicesEC, 1, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('22', XPurchaseServicesOutsideEC, 1, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('23', XPurchaseGoodSE, 1, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('24', XPurchaseServicesSE, 1, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', XOutputVATpurchases, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('30', XOutputVAT25, 1, '', 1, DemoDataSetup.EUCode(), XVat25, '', 1, 1, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('31', XOutputVAT12, 1, '', 1, DemoDataSetup.EUCode(), XVat12, '', 1, 1, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('32', XOutputVAT6, 1, '', 1, DemoDataSetup.EUCode(), XVat6, '', 1, 1, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', XSalesexemptVAT, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('3501', XEUSales25, 1, '', 2, DemoDataSetup.EUCode(), XVat25, '', 2, 0, false, 1, false);
        InsertData('3502', XEUSales12, 1, '', 2, DemoDataSetup.EUCode(), XVat12, '', 2, 0, false, 1, false);
        InsertData('3503', XEUSales6, 1, '', 2, DemoDataSetup.EUCode(), XVat6, '', 2, 0, false, 1, false);
        InsertData('3504', XEUSales0, 1, '', 2, DemoDataSetup.EUCode(), XNoVat, '', 2, 0, false, 1, false);
        InsertData('35', XSalesGoodAnotherEC, 2, '', 0, '', '', '3501..3599', 0, 0, true, 1, false);
        InsertData('3601', XExportSales25, 1, '', 2, DemoDataSetup.ExportCode(), XVat25, '', 2, 0, false, 1, false);
        InsertData('3602', XExportSales12, 1, '', 2, DemoDataSetup.ExportCode(), XVat12, '', 2, 0, false, 1, false);
        InsertData('3603', XExportSales6, 1, '', 2, DemoDataSetup.ExportCode(), XVat6, '', 2, 0, false, 1, false);
        InsertData('3604', XEUSales0, 1, '', 2, DemoDataSetup.EUCode(), XNoVat, '', 2, 0, false, 1, false);
        InsertData('36', XSalesOutsideEC, 2, '', 0, '', '', '3601..3699', 0, 0, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('37', XPurchasemiddleman, 1, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('38', XSalesmiddleman, 1, '', 0, '', '', '', 0, 0, false, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('39', XSalesServiceanotherEC, 1, '', 0, '', '', '', 0, 0, false, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('40', XOtherSales, 1, '', 0, '', '', '', 0, 0, false, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('41', XSalesSE, 1, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, false, 0, false);
        InsertData('42', XOtherSalesetc, 1, '', 2, DemoDataSetup.DomesticCode(), XNoVat, '', 2, 0, true, 1, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', XFInputVAT, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('4801', XPurchaseSE25, 1, '', 1, DemoDataSetup.DomesticCode(), XVat25, '', 1, 0, false, 0, false);
        InsertData('4802', XPurchaseSE12, 1, '', 1, DemoDataSetup.DomesticCode(), XVat12, '', 1, 0, false, 0, false);
        InsertData('4803', XPurchaseSE6, 1, '', 1, DemoDataSetup.DomesticCode(), XVat6, '', 1, 0, false, 0, false);
        InsertData('4804', XPurchaseSE0, 1, '', 1, DemoDataSetup.DomesticCode(), XNoVat, '', 1, 0, false, 0, false);
        InsertData('4805', XPurchaseSEOnly, 1, '', 1, DemoDataSetup.DomesticCode(), XNoVat, '', 1, 0, false, 0, false);
        InsertData('4810', XPurchaseEU25, 1, '', 1, DemoDataSetup.EUCode(), XVat25, '', 2, 0, false, 0, false);
        InsertData('4811', XPurchaseEU12, 1, '', 1, DemoDataSetup.EUCode(), XVat12, '', 2, 0, false, 0, false);
        InsertData('4812', XPurchaseEU6, 1, '', 1, DemoDataSetup.EUCode(), XVat6, '', 2, 0, false, 0, false);
        InsertData('48', XInputVAT, 2, '', 1, DemoDataSetup.EUCode(), XNoVat, '4800..4899', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', '', 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('', XVATpayrefunded, 3, '', 0, '', '', '', 0, 0, true, 0, false);
        InsertData('49', XVATpayrefunded, 2, '', 0, '', '', '10|11|12|30|31|32|48', 0, 0, true, 1, false);
    end;

    procedure InsertData("Row No.": Code[10]; Description: Text[50]; Type: Option; "Account Totaling": Text[30]; "Gen. Posting Type": Option; "VAT Bus. Posting Group": Code[20]; "VAT Prod. Posting Group": Code[20]; "Row Totaling": Text[30]; "Amount Type": Option; "Calculate with": Option; Print: Boolean; "Print with": Option; "New Page": Boolean)
    var
        "VAT Statement Line": Record "VAT Statement Line";
        XVAT: Label 'VAT';
        XSESTD: Label 'SE STD';
    begin
        "VAT Statement Line".Init();
        "VAT Statement Line".Validate("Statement Template Name", XVAT);
        "VAT Statement Line".Validate("Statement Name", XSESTD);
        NextLine := NextLine + 10000;
        "VAT Statement Line".Validate("Line No.", NextLine);
        "VAT Statement Line".Validate("Row No.", "Row No.");
        "VAT Statement Line".Validate(Description, Description);
        "VAT Statement Line".Validate(Type, Type);
        "VAT Statement Line".Validate("Account Totaling", "Account Totaling");
        "VAT Statement Line".Validate("Gen. Posting Type", "Gen. Posting Type");
        "VAT Statement Line".Validate("VAT Bus. Posting Group", "VAT Bus. Posting Group");
        "VAT Statement Line".Validate("VAT Prod. Posting Group", "VAT Prod. Posting Group");
        "VAT Statement Line".Validate("Row Totaling", "Row Totaling");
        "VAT Statement Line".Validate("Amount Type", "Amount Type");
        "VAT Statement Line".Validate("Calculate with", "Calculate with");
        "VAT Statement Line".Validate(Print, Print);
        "VAT Statement Line".Validate("Print with", "Print with");
        "VAT Statement Line".Validate("New Page", "New Page");
        if "VAT Statement Line".Insert() then;
    end;

    procedure SetDirectPosting()
    var
        GLAccounts: Record "G/L Account";
    begin
        GLAccounts.Reset();
        GLAccounts.SetRange("Account Type", GLAccounts."Account Type"::Posting);
        GLAccounts.Find('-');
        GLAccounts.ModifyAll("Direct Posting", true);
    end;

    procedure SetCompanyInformation()
    var
        CompInfo: Record "Company Information";
    begin
        CompInfo.Get();
        CompInfo."Plus Giro Number" := '111111-1';
        CompInfo."Phone No." := '031-00000';
        CompInfo."VAT Registration No." := 'SE556233480401';
        CompInfo."Registration No." := '5562334804';
        CompInfo."Registered Office Info" := XGoteborgTxt;
        CompInfo.Modify();
    end;

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        CreateDeleteGLAccount();
        CreateVATProductPostingGroup();
        CreateVATPostingSetup();
        CreateVATName();
        CreateVATLines();
        SetDirectPosting();
        SetCompanyInformation();
        TransportMethod.DeleteAll();
    end;
}

