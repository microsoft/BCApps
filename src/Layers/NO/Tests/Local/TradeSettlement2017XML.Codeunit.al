codeunit 144004 "Trade Settlement 2017 - XML"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [Trade Settlement] [XML]
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        BoxNo: Option " ","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19";

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box3_DomesticVATHigh()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 168591] Domestic customer with high VAT
        UpdateCompanyInformation();

        // [GIVEN] Domestic customer with "VAT Settlement Rate" = Normal, "VAT %" = 25
        CustomerNo := CreateCustomer(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"3");

        // [GIVEN] Posted sales invoice with Total Amount Incl. VAT = 1250
        CreatePostSalesInvoice(VATBase, VATAmount, VATPostingSetup, CustomerNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(CustomerNo);

        // [THEN] XML has header data: 'dataFormatVersion' = 20160523, 'dataFormatProvider' = 'Skatteetaten', 'dataFormatId' = 212
        // [THEN] XML contains Company Information: Name, Iban, Swift
        // [THEN] XML contains Settlement Period Info: Year, PeriodType, PeriodNo
        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000
        // [THEN] Box 3 (Domestic turnover and withdrawal, VAT 25 %) = 1000 (base) + 250 (amount)
        // [THEN] Box 19 (Tax to pay) = 250
        VerifyXMLFileHeader();
        VerifyCompanyInformation();
        VerifyPeriodInfo();
        VerifyBoxVATBase(2, VATBase);
        VerifyBoxVATBaseAndAmount(3, VATBase, VATAmount);
        VerifyBoxVATAmount(19, VATAmount);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box4_DomesticVATMedium()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 168591] Domestic customer with medium VAT

        // [GIVEN] Domestic customer with "VAT Settlement Rate" = Medium, "VAT %" = 15
        CustomerNo := CreateCustomer(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Medium, BoxNo::"4");

        // [GIVEN] Posted sales invoice with Total Amount Incl. VAT = 1150
        CreatePostSalesInvoice(VATBase, VATAmount, VATPostingSetup, CustomerNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(CustomerNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000
        // [THEN] Box 4 (Domestic turnover and withdrawal, VAT 15 %) = 1000 (base) + 150 (amount)
        // [THEN] Box 19 (Tax to pay) = 150
        VerifyBoxVATBase(2, VATBase);
        VerifyBoxVATBaseAndAmount(4, VATBase, VATAmount);
        VerifyBoxVATAmount(19, VATAmount);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box5_DomesticVATLow()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 168591] Domestic customer with low VAT

        // [GIVEN] Domestic customer with "VAT Settlement Rate" = Low, "VAT %" = 10
        CustomerNo := CreateCustomer(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Low, BoxNo::"5");

        // [GIVEN] Posted sales invoice with Total Amount Incl. VAT = 1100
        CreatePostSalesInvoice(VATBase, VATAmount, VATPostingSetup, CustomerNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(CustomerNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000
        // [THEN] Box 5 (Domestic turnover and withdrawal, VAT 10 %) = 1000 (base) + 100 (amount)
        // [THEN] Box 19 (Tax to pay) = 100
        VerifyBoxVATBase(2, VATBase);
        VerifyBoxVATBaseAndAmount(5, VATBase, VATAmount);
        VerifyBoxVATAmount(19, VATAmount);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box6_DomesticNoVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 168591] Domestic customer with no VAT

        // [GIVEN] Domestic customer with "VAT Settlement Rate" = Normal, "VAT %" = 0
        CustomerNo := CreateCustomerWithNoVAT(VATPostingSetup, BoxNo::"6");

        // [GIVEN] Posted sales invoice with Total Amount Incl. VAT = 1000
        CreatePostSalesInvoice(VATBase, VATAmount, VATPostingSetup, CustomerNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(CustomerNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000
        // [THEN] Box 6 (Zero rated domestic turnover and withdrawal) = 1000
        // [THEN] Box 19 (Tax to pay) = 0
        VerifyBoxVATBase(2, VATBase);
        VerifyBoxVATBase(6, VATBase);
        VerifyBoxVATAmount(19, 0);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box7_DomesticRevChrg()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Reverse Charge VAT]
        // [SCENARIO 168591] Domestic vendor with Reverse Charge VAT

        // [GIVEN] Domestic vendor with "VAT Settlement Rate" = Medium, "VAT %" = 15, "VAT Calculation Type" = "Reverse Charge VAT"
        VendorNo :=
          CreateVendorWithRevChrgVAT(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Medium, BoxNo::"7", BoxNo::" ");

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 1150
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 0
        // [THEN] Box 7 (Domestic turnover subject to reverse charge (emission trading and gold)) = 1000 (base) + 150 (amount)
        // [THEN] Box 19 (Outstanding Tax) = -150
        VerifyBoxVATBase(2, VATBase);
        VerifyBoxVATBase(7, VATBase);
        VerifyBoxVATAmount(19, VATAmount);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box8_ExportNoVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 168591] Abroad customer with no VAT

        // [GIVEN] Abroad customer with "VAT Settlement Rate" = Normal, "VAT %" = 0
        CustomerNo := CreateCustomerWithNoVAT(VATPostingSetup, BoxNo::"8");

        // [GIVEN] Posted sales invoice with Total Amount Incl. VAT = 1000
        CreatePostSalesInvoice(VATBase, VATAmount, VATPostingSetup, CustomerNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(CustomerNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000
        // [THEN] Box 8 (Total zero rated turnover due to export of goods and services) = 1000
        // [THEN] Box 19 (Tax to pay) = 0
        VerifyBoxVATBase(2, VATBase);
        VerifyBoxVATBase(8, VATBase);
        VerifyBoxVATAmount(19, 0);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box9_ImportVATHigh()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168591] Abroad vendor with high VAT (import of goods)

        // [GIVEN] Abroad vendor with "VAT Settlement Rate" = Normal, "VAT %" = 25
        VendorNo := CreateVendor(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"9");

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 1250
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000
        // [THEN] Box 9 (Import of goods, VAT 25 %) = 1000 (base) + 250 (amount)
        // [THEN] Box 19 (Tax to pay) = 250
        VerifyBoxVATBase(2, VATBase);
        VerifyBoxVATBaseAndAmount(9, VATBase, VATAmount);
        VerifyBoxVATAmount(19, VATAmount);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box9_ImportVATHigh_ReverseCharge()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Reverse Charge VAT]
        // [SCENARIO 168591] Abroad vendor with high VAT (import of goods) and Reverse Charge VAT

        // [GIVEN] Abroad vendor with "VAT Settlement Rate" = Normal, "VAT %" = 25, "VAT Calculation Type" = "Reverse Charge VAT"
        VendorNo :=
          CreateVendorWithRevChrgVAT(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"9", BoxNo::"17");

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 1250
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000
        // [THEN] Box 9 (Import of goods, VAT 25 %) = 1000 (base) + 250 (amount)
        // [THEN] Box 17 (Deductible import VAT, 25 %) = 250
        // [THEN] Box 19 (Tax to pay) = 250 (box9) - 250 (box17) = 0
        VerifyBoxVATBase(2, VATBase);
        VerifyBoxVATBaseAndAmount(9, VATBase, VATAmount);
        VerifyBoxVATAmount(17, VATAmount);
        VerifyBoxVATAmount(19, 0);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box10_ImportVATMed()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168591] Abroad vendor with medium VAT (import of goods)

        // [GIVEN] Abroad vendor with "VAT Settlement Rate" = Medium, "VAT %" = 15
        VendorNo := CreateVendor(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Medium, BoxNo::"10");

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 1150
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000
        // [THEN] Box 10 (Import of goods, VAT 15 %) = 1000 (base) + 150 (amount)
        // [THEN] Box 19 (Tax to pay) = 150
        VerifyBoxVATBase(2, VATBase);
        VerifyBoxVATBaseAndAmount(10, VATBase, VATAmount);
        VerifyBoxVATAmount(19, VATAmount);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box10_ImportVATMed_ReverseCharge()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Reverse Charge VAT]
        // [SCENARIO 168591] Abroad vendor with medium VAT (import of goods) and Reverse Charge VAT

        // [GIVEN] Abroad vendor with "VAT Settlement Rate" = Medium, "VAT %" = 15, "VAT Calculation Type" = "Reverse Charge VAT"
        VendorNo :=
          CreateVendorWithRevChrgVAT(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"10", BoxNo::"18");

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 1150
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000
        // [THEN] Box 10 (Import of goods, VAT 15 %) = 1000 (base) + 150 (amount)
        // [THEN] Box 18 (Deductible import VAT, 15 %) = 150
        // [THEN] Box 19 (Tax to pay) = 150 (box10) - 150 (box18) = 0
        VerifyBoxVATBase(2, VATBase);
        VerifyBoxVATBaseAndAmount(10, VATBase, VATAmount);
        VerifyBoxVATAmount(18, VATAmount);
        VerifyBoxVATAmount(19, 0);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box11_ImportVATNo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168591] Abroad vendor with no VAT (import of goods)

        // [GIVEN] Abroad vendor with "VAT Settlement Rate" = Normal, "VAT %" = 0
        VendorNo := CreateVendorWithNoVAT(VATPostingSetup, BoxNo::"11");

        // [GIVEN] Posted purchase Invoice with Total Amount Incl. VAT = 1000
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000
        // [THEN] Box 11 (Import of goods not subject to VAT) = 1000
        // [THEN] Box 19 (Tax to pay) = 0
        VerifyBoxVATBase(2, VATBase);
        VerifyBoxVATBase(11, VATBase);
        VerifyBoxVATAmount(19, 0);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box12_PurchServFromAbroad()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168591] Abroad vendor with high VAT (services from abroad)

        // [GIVEN] Abroad vendor with "VAT Settlement Rate" = Normal, "VAT %" = 25, "VAT Calculation Type" = "Normal"
        VendorNo := CreateVendor(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"12");

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 1250
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000
        // [THEN] Box 12 (Purchase of intangible services from abroad, VAT 25 %) = 1000 (base) + 250 (amount)
        // [THEN] Box 19 (Tax to pay) = 250
        VerifyBoxVATBase(2, VATBase);
        VerifyBoxVATBaseAndAmount(12, VATBase, VATAmount);
        VerifyBoxVATAmount(19, VATAmount);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box12_PurchServFromAbroad_ReverseCharge()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Reverse Charge VAT]
        // [SCENARIO 168591] Abroad vendor with high VAT (services from abroad) and Reverse Charge VAT

        // [GIVEN] Abroad vendor with "VAT Settlement Rate" = Normal, "VAT %" = 25, "VAT Calculation Type" = "Reverse Charge VAT"
        VendorNo :=
          CreateVendorWithRevChrgVAT(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"12", BoxNo::"17");

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 1250
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000
        // [THEN] Box 12 (Purchase of intangible services from abroad, VAT 25 %) = 1000 (base) + 250 (amount)
        // [THEN] Box 17 (Deductible import VAT, 25 %) = 250
        // [THEN] Box 19 (Tax to pay) = 250 (box12) - 250 (box17) = 0
        VerifyBoxVATBase(2, VATBase);
        VerifyBoxVATBaseAndAmount(12, VATBase, VATAmount);
        VerifyBoxVATAmount(17, VATAmount);
        VerifyBoxVATAmount(19, 0);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box13_DomSubjectToReverse()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168591] Domestic vendor with high VAT (subject to reverse charge)

        // [GIVEN] Domestic vendor with "VAT Settlement Rate" = Normal, "VAT %" = 25, "VAT Calculation Type" = "Normal"
        VendorNo := CreateVendor(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"13");

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 1250
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 0
        // [THEN] Box 13 (Domestic purchases subject to reverse charge, VAT 25 %) = 1000 (base) + 250 (amount)
        // [THEN] Box 19 (Tax to pay) = 250
        VerifyBoxVATBase(2, 0);
        VerifyBoxVATBaseAndAmount(13, VATBase, VATAmount);
        VerifyBoxVATAmount(19, VATAmount);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box13_DomSubjectToReverse_ReverseCharge()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Reverse Charge VAT]
        // [SCENARIO 168591] Domestic vendor with high VAT (subject to reverse charge) and Reverse Charge VAT

        // [GIVEN] Domestic vendor with "VAT Settlement Rate" = Normal, "VAT %" = 25, "VAT Calculation Type" = "Reverse Charge VAT"
        VendorNo :=
          CreateVendorWithRevChrgVAT(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"13", BoxNo::"14");

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 1250
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 0
        // [THEN] Box 13 (Domestic purchases subject to reverse charge, VAT 25 %) = 1000 (base) + 250 (amount)
        // [THEN] Box 14 (Deductible domestic input VAT, 25 %) = 250
        // [THEN] Box 19 (Tax to pay) = 250 (box13) - 250 (box14) = 0
        VerifyBoxVATBase(2, 0);
        VerifyBoxVATBaseAndAmount(13, VATBase, VATAmount);
        VerifyBoxVATAmount(14, VATAmount);
        VerifyBoxVATAmount(19, 0);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box14_DeductibleDomesticVATHigh()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168591] Domestic vendor with high VAT

        // [GIVEN] Domestic vendor with "VAT Settlement Rate" = Normal, "VAT %" = 25
        VendorNo := CreateVendor(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"14");

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 1250
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 0
        // [THEN] Box 14 (Deductible domestic input VAT, 25 %) = 250
        // [THEN] Box 19 (Outstanding Tax) = -250
        VerifyBoxVATBase(2, 0);
        VerifyBoxVATAmount(14, VATAmount);
        VerifyBoxVATAmount(19, -VATAmount);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box15_DeductibleDomesticVATMed()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168591] Domestic vendor with medium VAT

        // [GIVEN] Domestic vendor with "VAT Settlement Rate" = Medium, "VAT %" = 15
        VendorNo := CreateVendor(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Medium, BoxNo::"15");

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 1150
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 0
        // [THEN] Box 15 (Deductible domestic input VAT, 15 %) = 150
        // [THEN] Box 19 (Outstanding Tax) = -150
        VerifyBoxVATBase(2, 0);
        VerifyBoxVATAmount(15, VATAmount);
        VerifyBoxVATAmount(19, -VATAmount);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box16_DeductibleDomesticVATLow()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168591] Domestic vendor with low VAT

        // [GIVEN] Domestic vendor with "VAT Settlement Rate" = Low, "VAT %" = 10
        VendorNo := CreateVendor(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Low, BoxNo::"16");

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 1100
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 0
        // [THEN] Box 16 (Deductible domestic input VAT, 10 %) = 100
        // [THEN] Box 19 (Outstanding Tax) = -150
        VerifyBoxVATBase(2, 0);
        VerifyBoxVATAmount(16, VATAmount);
        VerifyBoxVATAmount(19, -VATAmount);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box17_DeductibleImportVATHigh()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168591] Abroad vendor with high VAT (deduction of import)

        // [GIVEN] Abroad vendor with "VAT Settlement Rate" = Normal, "VAT %" = 25
        VendorNo := CreateVendor(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"17");

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 1250
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 0
        // [THEN] Box 17 (Deductible import VAT, 25 %) = 250
        // [THEN] Box 19 (Outstanding Tax) = -250
        VerifyBoxVATBase(2, 0);
        VerifyBoxVATAmount(17, VATAmount);
        VerifyBoxVATAmount(19, -VATAmount);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box18_DeductibleImportVATMed()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168591] Abroad vendor with med VAT (deduction of import)

        // [GIVEN] Abroad vendor with "VAT Settlement Rate" = Medium, "VAT %" = 15
        VendorNo := CreateVendor(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Medium, BoxNo::"18");

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 1150
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 0
        // [THEN] Box 18 (Deductible import VAT, 15 %) = 150
        // [THEN] Box 19 (Outstanding Tax) = -150
        VerifyBoxVATBase(2, 0);
        VerifyBoxVATAmount(18, VATAmount);
        VerifyBoxVATAmount(19, -VATAmount);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Section_BC_SalesCombine()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: array[5] of Record "VAT Posting Setup";
        CustomerNo: array[5] of Code[20];
        VATBase: array[5] of Decimal;
        VATAmount: array[5] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 168591] Domestic customers (with high/med/low/no vat), abroad customer with no vat
        VATEntry.FindLast();

        // [GIVEN] Five customers: four domestic customers with different VAT Rates (Normal, Medium, Low, NoVAT), one abroad customer
        CustomerNo[1] := CreateCustomer(VATPostingSetup[1], VATPostingSetup[1]."VAT Settlement Rate"::Normal, BoxNo::"3");
        CustomerNo[2] := CreateCustomer(VATPostingSetup[2], VATPostingSetup[2]."VAT Settlement Rate"::Medium, BoxNo::"4");
        CustomerNo[3] := CreateCustomer(VATPostingSetup[3], VATPostingSetup[3]."VAT Settlement Rate"::Low, BoxNo::"5");
        CustomerNo[4] := CreateCustomerWithNoVAT(VATPostingSetup[4], BoxNo::"6");
        CustomerNo[5] := CreateCustomerWithNoVAT(VATPostingSetup[5], BoxNo::"8");

        // [GIVEN] Posted sales invoices for all customers: 1000 + 250 (high 25%), 800 + 120 (med 15%), 600 + 60 (low 10%), 400 (no vat), 200 (abroad no vat)
        for i := 1 to ArrayLen(VATPostingSetup) do
            CreatePostSalesInvoice(VATBase[i], VATAmount[i], VATPostingSetup[i], CustomerNo[i]);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportCombine(VATEntry."Entry No.");

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000 + 800 + 600 + 400 + 200 = 3000
        // [THEN] Box 3 (Domestic turnover and withdrawal, VAT 25 %) = 1000 (base) + 250 (amount)
        // [THEN] Box 4 (Domestic turnover and withdrawal, VAT 15 %) = 800 (base) + 120 (amount)
        // [THEN] Box 5 (Domestic turnover and withdrawal, VAT 10 %) = 600 (base) + 60 (amount)
        // [THEN] Box 6 (Zero rated domestic turnover and withdrawal) = 400
        // [THEN] Box 8 (Total zero rated turnover due to export of goods and services) = 200
        // [THEN] Box 19 (Tax to pay) = 250 + 120 + 60 = 430
        VerifyBoxVATBase(2, VATBase[1] + VATBase[2] + VATBase[3] + VATBase[4] + VATBase[5]);
        VerifyBoxVATBaseAndAmount(3, VATBase[1], VATAmount[1]);
        VerifyBoxVATBaseAndAmount(4, VATBase[2], VATAmount[2]);
        VerifyBoxVATBaseAndAmount(5, VATBase[3], VATAmount[3]);
        VerifyBoxVATBase(6, VATBase[4]);
        VerifyBoxVATBase(8, VATBase[5]);
        VerifyBoxVATAmount(19, VATAmount[1] + VATAmount[2] + VATAmount[3]);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Section_D_ImportCombine()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VendorNo: array[3] of Code[20];
        VATBase: array[3] of Decimal;
        VATAmount: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168591] Abroad vendors with high/med/no VAT (import of goods)
        VATEntry.FindLast();

        // [GIVEN] Three abroad vendors with high/med/no VAT
        VendorNo[1] := CreateVendor(VATPostingSetup[1], VATPostingSetup[1]."VAT Settlement Rate"::Normal, BoxNo::"9");
        VendorNo[2] := CreateVendor(VATPostingSetup[2], VATPostingSetup[2]."VAT Settlement Rate"::Medium, BoxNo::"10");
        VendorNo[3] := CreateVendorWithNoVAT(VATPostingSetup[3], BoxNo::"11");

        // [GIVEN] Posted purchase invoices for all vendors: 1000 + 250 (high 25%), 800 + 120 (med 15%), 600 (no vat)
        for i := 1 to ArrayLen(VATPostingSetup) do
            CreatePostPurchaseInvoice(VATBase[i], VATAmount[i], VATPostingSetup[i], VendorNo[i]);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportCombine(VATEntry."Entry No.");

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000 + 800 + 600 = 2400
        // [THEN] Box 9 (Import of goods, VAT 25 %) = 1000 (base) + 250 (amount)
        // [THEN] Box 10 (Import of goods, VAT 15 %) = 800 (base) + 120 (amount)
        // [THEN] Box 11 (Import of goods not subject to VAT) = 600
        // [THEN] Box 19 (Tax to pay) = 250 (box9) + 150 (box10) = 400
        VerifyBoxVATBase(2, VATBase[1] + VATBase[2] + VATBase[3]);
        VerifyBoxVATBaseAndAmount(9, VATBase[1], VATAmount[1]);
        VerifyBoxVATBaseAndAmount(10, VATBase[2], VATAmount[2]);
        VerifyBoxVATBase(11, VATBase[3]);
        VerifyBoxVATAmount(19, VATAmount[1] + VATAmount[2]);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Section_E_PurchRevChrgCombine()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        VendorNo: array[2] of Code[20];
        VATBase: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Purchase] [Reverse Charge VAT]
        // [SCENARIO 168591] Abroad and domestic vendors with high VAT and Reverse Charge VAT
        VATEntry.FindLast();

        // [GIVEN] Two vendors: abroad and domestic with with "VAT Settlement Rate" = Normal, "VAT %" = 25, "VAT Calculation Type" = "Reverse Charge VAT"
        VendorNo[1] :=
          CreateVendorWithRevChrgVAT(VATPostingSetup[1], VATPostingSetup[1]."VAT Settlement Rate"::Normal, BoxNo::"12", BoxNo::" ");
        VendorNo[2] :=
          CreateVendorWithRevChrgVAT(VATPostingSetup[2], VATPostingSetup[2]."VAT Settlement Rate"::Normal, BoxNo::"13", BoxNo::" ");

        // [GIVEN] Posted purchase invoices for all vendors: 1000 + 250 (abroad high vat 25%), 800 + 200 (domestic high vat 25%)
        for i := 1 to ArrayLen(VATPostingSetup) do
            CreatePostPurchaseInvoice(VATBase[i], VATAmount[i], VATPostingSetup[i], VendorNo[i]);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportCombine(VATEntry."Entry No.");

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000
        // [THEN] Box 12 (Purchase of intangible services from abroad, VAT 25 %) = 1000 (base) + 250 (amount)
        // [THEN] Box 13 (Domestic purchases subject to reverse charge, VAT 25 %) = 800 (base) + 200 (amount)
        // [THEN] Box 19 (Tax to pay) = 250 (box12) + 200 (box13) = 450
        VerifyBoxVATBase(2, VATBase[1]);
        VerifyBoxVATBaseAndAmount(12, VATBase[1], VATAmount[1]);
        VerifyBoxVATBaseAndAmount(13, VATBase[2], VATAmount[2]);
        VerifyBoxVATAmount(19, VATAmount[1] + VATAmount[2]);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Section_F_DeductibleDomesticCombine()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VendorNo: array[3] of Code[20];
        VATBase: array[3] of Decimal;
        VATAmount: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168591] Domestic vendors with high/med/low vat
        VATEntry.FindLast();

        // [GIVEN] Three domestic vendors with high/med/low VAT
        VendorNo[1] := CreateVendor(VATPostingSetup[1], VATPostingSetup[1]."VAT Settlement Rate"::Normal, BoxNo::"14");
        VendorNo[2] := CreateVendor(VATPostingSetup[2], VATPostingSetup[2]."VAT Settlement Rate"::Medium, BoxNo::"15");
        VendorNo[3] := CreateVendor(VATPostingSetup[3], VATPostingSetup[3]."VAT Settlement Rate"::Low, BoxNo::"16");

        // [GIVEN] Posted purchase invoices for all vendors: 1000 + 250 (high 25%), 800 + 120 (med 15%), 600 + 60 (low 10%)
        for i := 1 to ArrayLen(VATPostingSetup) do
            CreatePostPurchaseInvoice(VATBase[i], VATAmount[i], VATPostingSetup[i], VendorNo[i]);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportCombine(VATEntry."Entry No.");

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 0
        // [THEN] Box 14 (Deductible domestic input VAT, 25 %) = 250
        // [THEN] Box 15 (Deductible domestic input VAT, 15 %) = 120
        // [THEN] Box 16 (Deductible domestic input VAT, 10 %) = 60
        // [THEN] Box 19 (Outstanding Tax) = -250 - 120 - 60 = -430
        VerifyBoxVATBase(2, 0);
        VerifyBoxVATAmount(14, VATAmount[1]);
        VerifyBoxVATAmount(15, VATAmount[2]);
        VerifyBoxVATAmount(16, VATAmount[3]);
        VerifyBoxVATAmount(19, -(VATAmount[1] + VATAmount[2] + VATAmount[3]));
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Section_G_DeductibleImportCombine()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        VendorNo: array[2] of Code[20];
        VATBase: array[2] of Decimal;
        VATAmount: array[2] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168591] Abroad vendors with high/med VAT (deduction of import)
        VATEntry.FindLast();

        // [GIVEN] Two abroad vendors with high/med VAT
        VendorNo[1] := CreateVendor(VATPostingSetup[1], VATPostingSetup[1]."VAT Settlement Rate"::Normal, BoxNo::"17");
        VendorNo[2] := CreateVendor(VATPostingSetup[2], VATPostingSetup[2]."VAT Settlement Rate"::Medium, BoxNo::"18");

        // [GIVEN] Posted purchase invoices for vendors: 1000 + 250 (high 25%), 800 + 120 (med 15%)
        for i := 1 to ArrayLen(VATPostingSetup) do
            CreatePostPurchaseInvoice(VATBase[i], VATAmount[i], VATPostingSetup[i], VendorNo[i]);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportCombine(VATEntry."Entry No.");

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 0
        // [THEN] Box 17 (Deductible import VAT, 25 %) = 250
        // [THEN] Box 18 (Deductible import VAT, 15 %) = 150
        // [THEN] Box 19 (Outstanding Tax) = - 250 (box17) - 150 (box18) = -400
        VerifyBoxVATBase(2, 0);
        VerifyBoxVATAmount(17, VATAmount[1]);
        VerifyBoxVATAmount(18, VATAmount[2]);
        VerifyBoxVATAmount(19, -(VATAmount[1] + VATAmount[2]));
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Section_DG_ImportCombine()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: array[5] of Record "VAT Posting Setup";
        VendorNo: array[5] of Code[20];
        VATBase: array[5] of Decimal;
        VATAmount: array[5] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168591] Abroad vendors with high/med/no VAT (import of goods, deduction of import)
        VATEntry.FindLast();

        // [GIVEN] Three abroad vendors with high/med/no VAT (import of goods)
        VendorNo[1] := CreateVendor(VATPostingSetup[1], VATPostingSetup[1]."VAT Settlement Rate"::Normal, BoxNo::"9");
        VendorNo[2] := CreateVendor(VATPostingSetup[2], VATPostingSetup[2]."VAT Settlement Rate"::Medium, BoxNo::"10");
        VendorNo[3] := CreateVendorWithNoVAT(VATPostingSetup[3], BoxNo::"11");

        // [GIVEN] Two abroad vendors with high/med VAT (deduction of import)
        VendorNo[4] := CreateVendor(VATPostingSetup[4], VATPostingSetup[4]."VAT Settlement Rate"::Normal, BoxNo::"17");
        VendorNo[5] := CreateVendor(VATPostingSetup[5], VATPostingSetup[5]."VAT Settlement Rate"::Medium, BoxNo::"18");

        // [GIVEN] Posted purchase invoices for three vendors (import of goods): 10000 + 2500 (high 25%), 8000 + 1200 (med 15%), 6000 (no vat)
        // [GIVEN] Posted purchase invoices for two vendors (deduction of import): 1000 + 250 (high 25%), 800 + 120 (med 15%)
        for i := 1 to ArrayLen(VATPostingSetup) do
            CreatePostPurchaseInvoice(VATBase[i], VATAmount[i], VATPostingSetup[i], VendorNo[i]);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportCombine(VATEntry."Entry No.");

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 10000 + 8000 + 6000 = 24000
        // [THEN] Box 9 (Import of goods, VAT 25 %) = 10000 (base) + 2500 (amount)
        // [THEN] Box 10 (Import of goods, VAT 15 %) = 8000 (base) + 1200 (amount)
        // [THEN] Box 11 (Import of goods not subject to VAT) = 6000
        // [THEN] Box 17 (Deductible import VAT, 25 %) = 250
        // [THEN] Box 18 (Deductible import VAT, 15 %) = 150
        // [THEN] Box 19 (Tax to pay) = 2500 (box9) + 1500 (box10) - 250 (box17) - 150 (box18) = 3600
        VerifyBoxVATBase(2, VATBase[1] + VATBase[2] + VATBase[3]);
        VerifyBoxVATBaseAndAmount(9, VATBase[1], VATAmount[1]);
        VerifyBoxVATBaseAndAmount(10, VATBase[2], VATAmount[2]);
        VerifyBoxVATBase(11, VATBase[3]);
        VerifyBoxVATAmount(17, VATAmount[4]);
        VerifyBoxVATAmount(18, VATAmount[5]);
        VerifyBoxVATAmount(19, VATAmount[1] + VATAmount[2] - (VATAmount[4] + VATAmount[5]));
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Section_DEFG_PurchaseCombine()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: array[10] of Record "VAT Posting Setup";
        VendorNo: array[10] of Code[20];
        VATBase: array[10] of Decimal;
        VATAmount: array[10] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 168591] Abroad/domestic vendors with high/med/low/no normal VAT, abroad/domestic vendors with high VAT and Reverse Charge VAT
        VATEntry.FindLast();

        // [GIVEN] Three abroad vendors with high/med/no VAT (import of goods)
        VendorNo[1] := CreateVendor(VATPostingSetup[1], VATPostingSetup[1]."VAT Settlement Rate"::Normal, BoxNo::"9");
        VendorNo[2] := CreateVendor(VATPostingSetup[2], VATPostingSetup[2]."VAT Settlement Rate"::Medium, BoxNo::"10");
        VendorNo[3] := CreateVendorWithNoVAT(VATPostingSetup[3], BoxNo::"11");
        // [GIVEN] Two vendors: abroad and domestic with with "VAT Settlement Rate" = Normal, "VAT %" = 25, "VAT Calculation Type" = "Reverse Charge VAT"
        VendorNo[4] :=
          CreateVendorWithRevChrgVAT(VATPostingSetup[4], VATPostingSetup[4]."VAT Settlement Rate"::Normal, BoxNo::"12", BoxNo::" ");
        VendorNo[5] :=
          CreateVendorWithRevChrgVAT(VATPostingSetup[5], VATPostingSetup[5]."VAT Settlement Rate"::Normal, BoxNo::"13", BoxNo::" ");
        // [GIVEN] Three domestic vendors with high/med/low VAT
        VendorNo[6] := CreateVendor(VATPostingSetup[6], VATPostingSetup[6]."VAT Settlement Rate"::Normal, BoxNo::"14");
        VendorNo[7] := CreateVendor(VATPostingSetup[7], VATPostingSetup[7]."VAT Settlement Rate"::Medium, BoxNo::"15");
        VendorNo[8] := CreateVendor(VATPostingSetup[8], VATPostingSetup[8]."VAT Settlement Rate"::Low, BoxNo::"16");
        // [GIVEN] Two abroad vendors with high/med VAT (deduction of import)
        VendorNo[9] := CreateVendor(VATPostingSetup[9], VATPostingSetup[9]."VAT Settlement Rate"::Normal, BoxNo::"17");
        VendorNo[10] := CreateVendor(VATPostingSetup[10], VATPostingSetup[10]."VAT Settlement Rate"::Medium, BoxNo::"18");

        // [GIVEN] Posted purchase invoices for abroad vendors (import of goods): 10000 + 2500 (high 25%), 8000 + 1200 (med 15%), 6000 (no vat)
        // [GIVEN] Posted purchase invoices for reverse charge vendors: 1000 + 250 (abroad high vat 25%), 800 + 200 (domestic high vat 25%)
        // [GIVEN] Posted purchase invoices for domestic vendors: 100 + 25 (high 25%), 80 + 12 (med 15%), 60 + 6 (low 10%)
        // [GIVEN] Posted purchase invoices for abroad vendors (deduction of import): 80 + 20 (high 25%), 20 + 3 (med 15%)
        for i := 1 to ArrayLen(VATPostingSetup) do
            CreatePostPurchaseInvoice(VATBase[i], VATAmount[i], VATPostingSetup[i], VendorNo[i]);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportCombine(VATEntry."Entry No.");

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 10000 + 8000 + 6000 + 1000 = 25000
        // [THEN] Box 9 (Import of goods, VAT 25 %) = 10000 (base) + 2500 (amount)
        // [THEN] Box 10 (Import of goods, VAT 15 %) = 8000 (base) + 1200 (amount)
        // [THEN] Box 11 (Import of goods not subject to VAT) = 6000
        // [THEN] Box 12 (Purchase of intangible services from abroad, VAT 25 %) = 1000 (base) + 250 (amount)
        // [THEN] Box 13 (Domestic purchases subject to reverse charge, VAT 25 %) = 800 (base) + 200 (amount)
        // [THEN] Box 14 (Deductible domestic input VAT, 25 %) = 25
        // [THEN] Box 15 (Deductible domestic input VAT, 15 %) = 12
        // [THEN] Box 16 (Deductible domestic input VAT, 10 %) = 6
        // [THEN] Box 17 (Deductible import VAT, 25 %) = 20
        // [THEN] Box 18 (Deductible import VAT, 15 %) = 3
        // [THEN] Box 19 (Tax to pay) = 2500 + 1200 + 250 + 200 - (25 + 12 + 6 + 20 + 3) = 4150 - 66 = 4084
        VerifyBoxVATBase(2, VATBase[1] + VATBase[2] + VATBase[3] + VATBase[4]);
        VerifyBoxVATBaseAndAmount(9, VATBase[1], VATAmount[1]);
        VerifyBoxVATBaseAndAmount(10, VATBase[2], VATAmount[2]);
        VerifyBoxVATBase(11, VATBase[3]);
        VerifyBoxVATBaseAndAmount(12, VATBase[4], VATAmount[4]);
        VerifyBoxVATBaseAndAmount(13, VATBase[5], VATAmount[5]);
        VerifyBoxVATAmount(14, VATAmount[6]);
        VerifyBoxVATAmount(15, VATAmount[7]);
        VerifyBoxVATAmount(16, VATAmount[8]);
        VerifyBoxVATAmount(17, VATAmount[9]);
        VerifyBoxVATAmount(18, VATAmount[10]);
        VerifyBoxVATAmount(19,
          VATAmount[1] + VATAmount[2] + VATAmount[4] + VATAmount[5] -
          (VATAmount[6] + VATAmount[7] + VATAmount[8] + VATAmount[9] + VATAmount[10]));
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Section_BF_SalesPurchaseDomestic()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: array[6] of Record "VAT Posting Setup";
        CustomerNo: array[3] of Code[20];
        VendorNo: array[3] of Code[20];
        SalesVATBase: array[3] of Decimal;
        SalesVATAmount: array[3] of Decimal;
        PurchVATBase: array[3] of Decimal;
        PurchVATAmount: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales] [Purchase]
        // [SCENARIO 168591] Domestic customers/vendors with high/med/low vat
        VATEntry.FindLast();

        // [GIVEN] Three domestic customers and vendors with high/med/low VAT
        CustomerNo[1] := CreateCustomer(VATPostingSetup[1], VATPostingSetup[1]."VAT Settlement Rate"::Normal, BoxNo::"3");
        CustomerNo[2] := CreateCustomer(VATPostingSetup[2], VATPostingSetup[2]."VAT Settlement Rate"::Medium, BoxNo::"4");
        CustomerNo[3] := CreateCustomer(VATPostingSetup[3], VATPostingSetup[3]."VAT Settlement Rate"::Low, BoxNo::"5");
        VendorNo[1] := CreateVendor(VATPostingSetup[4], VATPostingSetup[4]."VAT Settlement Rate"::Normal, BoxNo::"14");
        VendorNo[2] := CreateVendor(VATPostingSetup[5], VATPostingSetup[5]."VAT Settlement Rate"::Medium, BoxNo::"15");
        VendorNo[3] := CreateVendor(VATPostingSetup[6], VATPostingSetup[6]."VAT Settlement Rate"::Low, BoxNo::"16");

        // [GIVEN] Posted sales invoices for all customers: 10000 + 2500 (high 25%), 8000 + 1200 (med 15%), 6000 + 600 (low 10%)
        for i := 1 to ArrayLen(CustomerNo) do
            CreatePostSalesInvoice(SalesVATBase[i], SalesVATAmount[i], VATPostingSetup[i], CustomerNo[i]);

        // [GIVEN] Posted purchase invoices for all vendors: 1000 + 250 (high 25%), 800 + 120 (med 15%), 600 + 60 (low 10%)
        for i := 1 to ArrayLen(VendorNo) do
            CreatePostPurchaseInvoice(PurchVATBase[i], PurchVATAmount[i], VATPostingSetup[ArrayLen(CustomerNo) + i], VendorNo[i]);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportCombine(VATEntry."Entry No.");

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 10000 + 8000 + 6000 = 24000
        // [THEN] Box 3 (Domestic turnover and withdrawal, VAT 25 %) = 10000 (base) + 2500 (amount)
        // [THEN] Box 4 (Domestic turnover and withdrawal, VAT 15 %) = 8000 (base) + 1200 (amount)
        // [THEN] Box 5 (Domestic turnover and withdrawal, VAT 10 %) = 6000 (base) + 600 (amount)
        // [THEN] Box 14 (Deductible domestic input VAT, 25 %) = 250
        // [THEN] Box 15 (Deductible domestic input VAT, 15 %) = 120
        // [THEN] Box 16 (Deductible domestic input VAT, 10 %) = 60
        // [THEN] Box 19 (Tax to pay) = 2500 + 1200 + 600 = 4300
        VerifyBoxVATBase(2, SalesVATBase[1] + SalesVATBase[2] + SalesVATBase[3]);
        VerifyBoxVATBaseAndAmount(3, SalesVATBase[1], SalesVATAmount[1]);
        VerifyBoxVATBaseAndAmount(4, SalesVATBase[2], SalesVATAmount[2]);
        VerifyBoxVATBaseAndAmount(5, SalesVATBase[3], SalesVATAmount[3]);
        VerifyBoxVATAmount(14, PurchVATAmount[1]);
        VerifyBoxVATAmount(15, PurchVATAmount[2]);
        VerifyBoxVATAmount(16, PurchVATAmount[3]);
        VerifyBoxVATAmount(19,
          SalesVATAmount[1] + SalesVATAmount[2] + SalesVATAmount[3] -
          (PurchVATAmount[1] + PurchVATAmount[2] + PurchVATAmount[3]));
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box12_PurchServFromAbroad_ReverseChargeVATDeduction()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [Reverse Charge VAT]
        // [SCENARIO 267886] VAT Base and Amount when Reverse Charge VAT with Proportional Deduction

        // [GIVEN] Foreign Vendor with "VAT Settlement Rate" = Normal, "VAT %" = 25, "VAT Calculation Type" = "Reverse Charge VAT"
        VendorNo :=
          CreateVendorWithRevChrgVAT(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"12", BoxNo::"17");

        // [GIVEN] Deduction 20.0 % was set in VAT Posting Setup
        ModifyVATPostingSetupPropDeductionVATRate(VATPostingSetup, LibraryRandom.RandDecInRange(10, 20, 2));

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 1250
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000
        // [THEN] Box 12 (Purchase of intangible services from abroad, VAT 25 %) = 1000 (base) + 250 (amount)
        // [THEN] Box 17 (Deductible import VAT, 25 %) = 50
        // [THEN] Box 19 (Tax to pay) = 250 (box12) - 50 (box17) = 200
        VerifyBoxesForDeduction(VATBase, VATAmount, VATPostingSetup."Proportional Deduction VAT %", 12);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box12_PurchServFromAbroad_ReverseChargeVATPropDeduction0()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [Reverse Charge VAT]
        // [SCENARIO 293873] VAT Base and Amount when Reverse Charge VAT when Proportional Deduction VAT = 0%

        // [GIVEN] Foreign Vendor with "VAT Settlement Rate" = Normal, "VAT %" = 25, "VAT Calculation Type" = "Reverse Charge VAT"
        VendorNo :=
          CreateVendorWithRevChrgVAT(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"12", BoxNo::"17");

        // [GIVEN] Proportional Deduction VAT = 0 % in VAT Posting Setup
        ModifyVATPostingSetupPropDeductionVATRate(VATPostingSetup, 0);

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 800
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 800
        // [THEN] Box 12 (Purchase of intangible services from abroad, VAT 25 %) = 200
        // [THEN] Box 17 (Deductible import VAT, 25 %) = 0
        // [THEN] Box 19 (Tax to pay) = 200 (box12) - 0 (box17) = 200
        VerifyBoxesForPropDeduction(VATBase, VATAmount, 0, 12);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box12_PurchServFromAbroad_ReverseChargeVATPropDeduction100()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [Reverse Charge VAT]
        // [SCENARIO 293873] VAT Base and Amount when Reverse Charge VAT when Proportional Deduction VAT = 100%

        // [GIVEN] Foreign Vendor with "VAT Settlement Rate" = Normal, "VAT %" = 25, "VAT Calculation Type" = "Reverse Charge VAT"
        VendorNo :=
          CreateVendorWithRevChrgVAT(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"12", BoxNo::"17");

        // [GIVEN] Proportional Deduction VAT = 1000 % in VAT Posting Setup
        ModifyVATPostingSetupPropDeductionVATRate(VATPostingSetup, 100);

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 800
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 800
        // [THEN] Box 12 (Purchase of intangible services from abroad, VAT 25 %) = 200
        // [THEN] Box 17 (Deductible import VAT, 25 %) = 200
        // [THEN] Box 19 (Tax to pay) = 200 (box12) - 200 (box17) = 0
        VerifyBoxesForDeduction(VATBase, VATAmount, 100, 12);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyUnloopingBaseWithVATandBaseWithoutWATInfo()
    var
        VATPostingSetup: array[6] of Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        FileManagement: Codeunit "File Management";
        CustomerNo: array[3] of Code[20];
        VendorNo: array[3] of Code[20];
        FileName: Text;
        SalesVATBase: array[3] of Decimal;
        SalesVATAmount: array[3] of Decimal;
        PurchVATBase: array[3] of Decimal;
        PurchVATAmount: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales] [Purchase]
        // [SCENARIO 314390] BaseWithVAT and BaseWithoutVAT don't copy from previous section.

        // [GIVEN] Three domestic customers with high/no/high VAT.
        CustomerNo[1] := CreateCustomer(VATPostingSetup[1], VATPostingSetup[1]."VAT Settlement Rate"::Normal, BoxNo::"3");
        CustomerNo[2] := CreateCustomerWithNoVAT(VATPostingSetup[2], BoxNo::"8");
        CustomerNo[3] := CreateCustomer(VATPostingSetup[3], VATPostingSetup[3]."VAT Settlement Rate"::Normal, BoxNo::"3");

        // [GIVEN] Three domestic vendors with no/high/no VAT.
        VendorNo[1] := CreateVendorWithNoVAT(VATPostingSetup[4], BoxNo::"11");
        VendorNo[2] := CreateVendor(VATPostingSetup[5], VATPostingSetup[5]."VAT Settlement Rate"::Normal, BoxNo::"14");
        VendorNo[3] := CreateVendorWithNoVAT(VATPostingSetup[6], BoxNo::"11");

        // [GIVEN] Posted sales invoices for all customers:
        for i := 1 to ArrayLen(CustomerNo) do
            CreatePostSalesInvoice(SalesVATBase[i], SalesVATAmount[i], VATPostingSetup[i], CustomerNo[i]);

        // [GIVEN] Posted purchase invoices for all vendors:
        for i := 1 to ArrayLen(VendorNo) do
            CreatePostPurchaseInvoice(PurchVATBase[i], PurchVATAmount[i], VATPostingSetup[i + ArrayLen(CustomerNo)], VendorNo[i]);

        // [GIVEN] Took only useful VAT Bus. Posting Group for report:
        VATEntry.SetFilter("VAT Bus. Posting Group", '%1|%2|%3|%4|%5|%6', VATPostingSetup[1]."VAT Bus. Posting Group",
          VATPostingSetup[2]."VAT Bus. Posting Group", VATPostingSetup[3]."VAT Bus. Posting Group",
          VATPostingSetup[4]."VAT Bus. Posting Group", VATPostingSetup[5]."VAT Bus. Posting Group",
          VATPostingSetup[6]."VAT Bus. Posting Group");

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        FileName := FileManagement.ServerTempFileName('.xml');

        RunTradeSettlement2017Report(VATEntry, FileManagement.ServerTempFileName(''), FileName, FileManagement.ServerTempFileName(''));
        LibraryXMLRead.Initialize(FileName);

        // [THEN] Check BaseWithVat, BaseWithoutVat and BaseOutside for first purchase invoice
        VerifyBaseWithVATWithoutVATOutside(0, PurchVATBase[1], 0, 0);

        // [THEN] Check BaseWithVat, BaseWithoutVat and BaseOutside for second purchase invoice
        VerifyBaseWithVATWithoutVATOutside(PurchVATBase[2], 0, 0, 1);

        // [THEN] Check BaseWithVat, BaseWithoutVat and BaseOutside for third purchase invoice
        VerifyBaseWithVATWithoutVATOutside(0, PurchVATBase[3], 0, 2);

        // [THEN] Check BaseWithVat, BaseWithoutVat and BaseOutside for first sales invoice
        VerifyBaseWithVATWithoutVATOutside(SalesVATBase[1], 0, 0, 3);

        // [THEN] Check BaseWithVat, BaseWithoutVat and BaseOutside for second sales invoice
        VerifyBaseWithVATWithoutVATOutside(0, SalesVATBase[2], 0, 4);

        // [THEN] Check BaseWithVat, BaseWithoutVat and BaseOutside for third sales invoice
        VerifyBaseWithVATWithoutVATOutside(SalesVATBase[3], 0, 0, 5);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box9_PurchServFromAbroad_ReverseChargeVATDeduction()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [Reverse Charge VAT]
        // [SCENARIO 340079] VAT Base and Amount when Reverse Charge VAT with Proportional Deduction

        // [GIVEN] Foreign Vendor with "VAT Settlement Rate" = Normal, "VAT %" = 25, "VAT Calculation Type" = "Reverse Charge VAT"
        VendorNo :=
          CreateVendorWithRevChrgVAT(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"9", BoxNo::"17");

        // [GIVEN] Deduction 20.0 % was set in VAT Posting Setup
        ModifyVATPostingSetupPropDeductionVATRate(VATPostingSetup, LibraryRandom.RandDecInRange(10, 20, 2));

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 1250
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000
        // [THEN] Box 9 (Import of goods, VAT 25 %) = 1000 (base) + 250 (amount)
        // [THEN] Box 17 (Deductible import VAT, 25 %) = 50
        // [THEN] Box 19 (Tax to pay) = 250 (box12) - 50 (box17) = 200
        VerifyBoxesForDeduction(VATBase, VATAmount, VATPostingSetup."Proportional Deduction VAT %", 9);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box9_PurchServFromAbroad_ReverseChargeVATPropDeduction0()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [Reverse Charge VAT]
        // [SCENARIO 340079] VAT Base and Amount when Reverse Charge VAT when Proportional Deduction VAT = 0%

        // [GIVEN] Foreign Vendor with "VAT Settlement Rate" = Normal, "VAT %" = 25, "VAT Calculation Type" = "Reverse Charge VAT"
        VendorNo :=
          CreateVendorWithRevChrgVAT(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"9", BoxNo::"17");

        // [GIVEN] Proportional Deduction VAT = 0 % in VAT Posting Setup
        ModifyVATPostingSetupPropDeductionVATRate(VATPostingSetup, 0);

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 800
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 800
        // [THEN] Box 9 (Import of goods, VAT 25 %) = 200
        // [THEN] Box 17 (Deductible import VAT, 25 %) = 0
        // [THEN] Box 19 (Tax to pay) = 200 (box12) - 0 (box17) = 200
        VerifyBoxesForPropDeduction(VATBase, VATAmount, 0, 9);
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Box9_PurchServFromAbroad_ReverseChargeVATPropDeduction100()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [Reverse Charge VAT]
        // [SCENARIO 340079] VAT Base and Amount when Reverse Charge VAT when Proportional Deduction VAT = 100%

        // [GIVEN] Foreign Vendor with "VAT Settlement Rate" = Normal, "VAT %" = 25, "VAT Calculation Type" = "Reverse Charge VAT"
        VendorNo :=
          CreateVendorWithRevChrgVAT(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"9", BoxNo::"17");

        // [GIVEN] Proportional Deduction VAT = 1000 % in VAT Posting Setup
        ModifyVATPostingSetupPropDeductionVATRate(VATPostingSetup, 100);

        // [GIVEN] Posted purchase invoice with Total Amount Incl. VAT = 800
        CreatePostPurchaseInvoice(VATBase, VATAmount, VATPostingSetup, VendorNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(VendorNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 800
        // [THEN] Box 9 (Import of goods, VAT 25 %) = 200
        // [THEN] Box 17 (Deductible import VAT, 25 %) = 200
        // [THEN] Box 19 (Tax to pay) = 200 (box12) - 200 (box17) = 0
        VerifyBoxesForDeduction(VATBase, VATAmount, 100, 9);
    end;

    local procedure UpdateCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("SWIFT Code", LibraryUtility.GenerateRandomXMLText(MaxStrLen(CompanyInformation."SWIFT Code")));
        CompanyInformation.Modify(true);
    end;

    local procedure ModifyVATPostingSetupPropDeductionVATRate(var VATPostingSetup: Record "VAT Posting Setup"; PropDeductionVATRate: Decimal)
    begin
        VATPostingSetup.Validate("Proportional Deduction VAT %", PropDeductionVATRate);
        VATPostingSetup.Validate("Calc. Prop. Deduction VAT", true);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateCustomer(var VATPostingSetup: Record "VAT Posting Setup"; VATSettlementRate: Option; ReportBoxNo: Option): Code[20]
    begin
        CreateVATPostingSetup(
          VATPostingSetup, GenerateVATRate(VATSettlementRate), VATSettlementRate, CreateVATCode(ReportBoxNo, BoxNo::" "), '');
        exit(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
    end;

    local procedure CreateCustomerWithNoVAT(var VATPostingSetup: Record "VAT Posting Setup"; ReportBoxNo: Option): Code[20]
    begin
        CreateVATPostingSetup(
          VATPostingSetup, 0, VATPostingSetup."VAT Settlement Rate"::Normal, CreateVATCode(ReportBoxNo, BoxNo::" "), '');
        exit(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
    end;

    local procedure CreateVendor(var VATPostingSetup: Record "VAT Posting Setup"; VATSettlementRate: Option; ReportBoxNo: Option): Code[20]
    begin
        CreateVATPostingSetup(
          VATPostingSetup, GenerateVATRate(VATSettlementRate), VATSettlementRate, '', CreateVATCode(ReportBoxNo, BoxNo::" "));
        exit(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
    end;

    local procedure CreateVendorWithNoVAT(var VATPostingSetup: Record "VAT Posting Setup"; ReportBoxNo: Option): Code[20]
    begin
        CreateVATPostingSetup(
          VATPostingSetup, 0, VATPostingSetup."VAT Settlement Rate"::Normal, '', CreateVATCode(ReportBoxNo, BoxNo::" "));
        exit(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
    end;

    local procedure CreateVendorWithRevChrgVAT(var VATPostingSetup: Record "VAT Posting Setup"; VATSettlementRate: Option; ReportBoxNo: Option; ReverseChargeBoxNo: Option): Code[20]
    begin
        CreateVATPostingSetup(
          VATPostingSetup, GenerateVATRate(VATSettlementRate), VATSettlementRate, '', CreateVATCode(ReportBoxNo, ReverseChargeBoxNo));
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Modify(true);
        exit(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATPct: Decimal; VATSettlementRate: Option; SalesVATReportingCode: Code[10]; PurchaseVATReportingCode: Code[10])
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPct);
        VATPostingSetup.Validate("VAT Settlement Rate", VATSettlementRate);
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sale VAT Reporting Code", SalesVATReportingCode);
        VATPostingSetup.Validate("Purch. VAT Reporting Code", PurchaseVATReportingCode);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATCode(ReportBoxNo: Option; ReverseChargeBoxNo: Option): Code[10]
    var
        VATReportingCode: Record "VAT Reporting Code";
    begin
        VATReportingCode.Init();
        VATReportingCode.Code := LibraryUtility.GenerateRandomCode(VATReportingCode.FieldNo(Code), DATABASE::"VAT Reporting Code");
        VATReportingCode."Gen. Posting Type" := VATReportingCode."Gen. Posting Type"::Sale;
        VATReportingCode."Trade Settlement 2017 Box No." := ReportBoxNo;
        VATReportingCode."Reverse Charge Report Box No." := ReverseChargeBoxNo;
        VATReportingCode.Insert(true);
        exit(VATReportingCode.Code);
    end;

    local procedure CreatePostSalesInvoice(var VATBase: Decimal; var VATAmount: Decimal; VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);

        if not GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group") then
            LibraryERM.CreateGeneralPostingSetup(
              GeneralPostingSetup, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VATBase := SalesLine.Amount;
        VATAmount := SalesLine."Amount Including VAT" - SalesLine.Amount;

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreatePostPurchaseInvoice(var VATBase: Decimal; var VATAmount: Decimal; VATPostingSetup: Record "VAT Posting Setup"; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);

        if not GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group") then
            LibraryERM.CreateGeneralPostingSetup(
              GeneralPostingSetup, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VATBase := PurchaseLine.Amount;

        if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
            VATAmount := Round(VATBase * VATPostingSetup."VAT %" / 100)
        else
            VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure GenerateVATRate(VATSettlementRate: Option): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        case VATSettlementRate of
            VATPostingSetup."VAT Settlement Rate"::Low:
                exit(LibraryRandom.RandIntInRange(5, 10));
            VATPostingSetup."VAT Settlement Rate"::Medium:
                exit(LibraryRandom.RandIntInRange(11, 20));
            VATPostingSetup."VAT Settlement Rate"::Normal:
                exit(LibraryRandom.RandIntInRange(21, 30));
        end;
    end;

    local procedure RunTradeSettlement2017ReportForCVNo(CVNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
        FileManagement: Codeunit "File Management";
        FileName: Text;
        XmlFileName: Text;
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", CVNo);
        FileName := FileManagement.ServerTempFileName('.xml');
        XmlFileName := FileManagement.ServerTempFileName('');
        RunTradeSettlement2017Report(VATEntry, FileName, FileManagement.ServerTempFileName(''), XmlFileName);
        LibraryXMLRead.Initialize(XmlFileName + '.xml');
    end;

    local procedure RunTradeSettlement2017ReportCombine(LastVATEntryNo: Integer)
    var
        VATEntry: Record "VAT Entry";
        FileManagement: Codeunit "File Management";
        FileName: Text;
        XmlFileName: Text;
    begin
        VATEntry.SetFilter("Entry No.", '%1..', LastVATEntryNo + 1);
        FileName := FileManagement.ServerTempFileName('.xml');
        XmlFileName := FileManagement.ServerTempFileName('');
        RunTradeSettlement2017Report(VATEntry, FileName, FileManagement.ServerTempFileName(''), XmlFileName);
        LibraryXMLRead.Initialize(XmlFileName + '.xml');
    end;

    local procedure RunTradeSettlement2017Report(var VATEntry: Record "VAT Entry"; ParamertFileName: Text; DataSetFileName: Text; XmlFileName: Text)
    begin
        LibraryVariableStorage.Enqueue(ParamertFileName);
        LibraryVariableStorage.Enqueue(XmlFileName);
        LibraryVariableStorage.Enqueue(DataSetFileName);

        REPORT.Run(REPORT::"Trade Settlement 2017", true, true, VATEntry);
    end;

    local procedure GetXMLElementNameByBoxNo(BoxNo: Integer): Text
    begin
        case BoxNo of
            1:
                exit('sumOmsetningUtenforMva');
            2:
                exit('sumOmsetningInnenforMvaUttakOgInnfoersel');
            3:
                exit('innlandOmsetningUttakHoeySats');
            4:
                exit('innlandOmsetningUttakMiddelsSats');
            5:
                exit('innlandOmsetningUttakLavSats');
            6:
                exit('innlandOmsetningUttakFritattMva');
            7:
                exit('innlandOmsetningOmvendtAvgiftsplikt');
            8:
                exit('utfoerselVareTjenesteFritattMva');
            9:
                exit('innfoerselVareHoeySats');
            10:
                exit('innfoerselVareMiddelsSats');
            11:
                exit('innfoerselVareFritattMva');
            12:
                exit('kjoepUtlandTjenesteHoeySats');
            13:
                exit('kjoepInnlandVareTjenesteHoeySats');
            14:
                exit('fradragInnlandInngaaendeHoeySats');
            15:
                exit('fradragInnlandInngaaendeMiddelsSats');
            16:
                exit('fradragInnlandInngaaendeLavSats');
            17:
                exit('fradragInnfoerselMvaHoeySats');
            18:
                exit('fradragInnfoerselMvaMiddelsSats');
        end;
    end;

    local procedure VerifyBoxVATBase(BoxNo: Integer; ExpectedValue: Decimal)
    begin
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'mvaGrunnlag', GetXMLElementNameByBoxNo(BoxNo), ExpectedValue);
    end;

    local procedure VerifyBoxVATAmount(BoxNo: Integer; ExpectedValue: Decimal)
    var
        RootNode: Text;
        ElementName: Text;
    begin
        if BoxNo = 19 then begin
            RootNode := 'mvaSumAvgift';
            if ExpectedValue < 0 then begin
                ExpectedValue := -ExpectedValue;
                ElementName := 'tilGode'
            end else
                ElementName := 'aaBetale';
        end else begin
            RootNode := 'mvaAvgift';
            ElementName := GetXMLElementNameByBoxNo(BoxNo);
        end;
        LibraryXMLRead.VerifyNodeValueInSubtree(RootNode, ElementName, ExpectedValue);
    end;

    local procedure VerifyBoxVATBaseAndAmount(BoxNo: Integer; Base: Decimal; Amount: Decimal)
    begin
        VerifyBoxVATBase(BoxNo, Base);
        VerifyBoxVATAmount(BoxNo, Amount);
    end;

    local procedure VerifyXMLFileHeader()
    begin
        LibraryXMLRead.VerifyAttributeValue('melding', 'dataFormatVersion', '20160523');
        LibraryXMLRead.VerifyAttributeValue('melding', 'dataFormatProvider', 'Skatteetaten');
        LibraryXMLRead.VerifyAttributeValue('melding', 'dataFormatId', '212');
    end;

    local procedure VerifyCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibraryXMLRead.VerifyNodeValueInSubtree('skattepliktig', 'organisasjonsnavn', CompanyInformation.Name);
        LibraryXMLRead.VerifyNodeValueInSubtree('skattepliktig', 'iban', CompanyInformation.IBAN);
        LibraryXMLRead.VerifyNodeValueInSubtree('skattepliktig', 'swiftBic', CompanyInformation."SWIFT Code");
    end;

    local procedure VerifyPeriodInfo()
    var
        NorwegianVATTools: Codeunit "Norwegian VAT Tools";
    begin
        LibraryXMLRead.VerifyNodeValueInSubtree('meldingsopplysning', 'meldingstype', 1);
        LibraryXMLRead.VerifyNodeValueInSubtree('meldingsopplysning', 'termintype', 4);
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'meldingsopplysning', 'termin', '0' + Format(NorwegianVATTools.VATPeriodNo(WorkDate())) + '4');
        LibraryXMLRead.VerifyNodeValueInSubtree('meldingsopplysning', 'aar', Date2DMY(WorkDate(), 3));
    end;

    local procedure VerifyBoxesForDeduction(VATBase: Decimal; VATAmount: Decimal; DeductionRate: Decimal; VATBaseAndAmountBoxNo: Integer)
    var
        FullBase: Decimal;
        FullAmount: Decimal;
        DeductedAmount: Decimal;
    begin
        FullBase := Round(Round(VATBase * DeductionRate / 100) * 100 / DeductionRate);
        FullAmount := Round(Round(VATAmount * DeductionRate / 100) * 100 / DeductionRate);
        DeductedAmount := Round(VATAmount * DeductionRate / 100);
        VerifyBoxesForPropDeduction(FullBase, FullAmount, DeductedAmount, VATBaseAndAmountBoxNo);
    end;

    local procedure VerifyBoxesForPropDeduction(FullBase: Decimal; FullAmount: Decimal; DeductedAmount: Decimal; VATBaseAndAmountBoxNo: Integer)
    begin
        VerifyBoxVATBase(2, FullBase);
        VerifyBoxVATBaseAndAmount(VATBaseAndAmountBoxNo, FullBase, FullAmount);
        VerifyBoxVATAmount(17, DeductedAmount);
        VerifyBoxVATAmount(19, FullAmount - DeductedAmount);
    end;

    local procedure VerifyBaseWithVATWithoutVATOutside(BaseWithVAT: Decimal; BaseWithoutVAT: Decimal; BaseOutside: Decimal; index: Integer)
    var
        Assert: Codeunit Assert;
        SumWithVAT: Decimal;
        SumWithoutVAT: Decimal;
        SumOutside: Decimal;
    begin
        Evaluate(SumWithoutVAT, LibraryXMLRead.GetNodeValueAtIndex('BaseWithoutVAT', index));
        Evaluate(SumWithVAT, LibraryXMLRead.GetNodeValueAtIndex('BaseWithVAT', index));
        Evaluate(SumOutside, LibraryXMLRead.GetNodeValueAtIndex('BaseOutside', index));
        Assert.AreEqual(BaseWithVAT, Abs(SumWithVAT), '');
        Assert.AreEqual(BaseWithoutVAT, Abs(SumWithoutVAT), '');
        Assert.AreEqual(BaseOutside, Abs(SumOutside), '');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TradeSettlementRequestPageHandler(var TradeSettlement2017: TestRequestPage "Trade Settlement 2017")
    var
        NorwegianVATTools: Codeunit "Norwegian VAT Tools";
        FileName: Text;
    begin
        TradeSettlement2017.SettlementYear.SetValue(Date2DMY(WorkDate(), 3));
        TradeSettlement2017.SettlementPeriod.SetValue(NorwegianVATTools.VATPeriodNo(WorkDate()));
        TradeSettlement2017.ExportXML.SetValue(true);
        FileName := LibraryVariableStorage.DequeueText();
        TradeSettlement2017.ClientFileName.SetValue(LibraryVariableStorage.DequeueText());
        TradeSettlement2017.SaveAsXml(FileName, LibraryVariableStorage.DequeueText());
    end;
}

