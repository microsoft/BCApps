codeunit 144003 "Trade Settlement 2017 - Excel"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [Trade Settlement] [Excel]
    end;

    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        ReportBoxALbl: Label 'A. Total turnover and withdrawal based on import';
        StartingRowNo: Integer;
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

        // [GIVEN] Domestic customer with "VAT Settlement Rate" = Normal, "VAT %" = 25
        CustomerNo := CreateCustomer(VATPostingSetup, VATPostingSetup."VAT Settlement Rate"::Normal, BoxNo::"3");

        // [GIVEN] Posted sales invoice with Total Amount Incl. VAT = 1250
        CreatePostSalesInvoice(VATBase, VATAmount, VATPostingSetup, CustomerNo);

        // [WHEN] Run REP 10618 "Trade Settlement - 2017"
        RunTradeSettlement2017ReportForCVNo(CustomerNo);

        // [THEN] Box 2 (Total turnover and withdrawal covered by the VAT Act and import) = 1000
        // [THEN] Box 3 (Domestic turnover and withdrawal, VAT 25 %) = 1000 (base) + 250 (amount)
        // [THEN] Box 19 (Tax to pay) = 250
        OpenExcel();
        VerifyBoxVATBase(2, VATBase);
        VerifyBoxVATBaseAndAmount(3, VATBase, VATAmount);
        VerifyBoxVATAmount(19, VATAmount);
        // [THEN] Report has title "Trade settlement VAT" and all labels printed // TFS 263371
        VerifyTradeSettlementReportLabels();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
        VerifyBoxVATBase(2, VATBase);
        VerifyBoxVATBaseAndAmount(7, VATBase, VATAmount);
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
        OpenExcel();
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
    procedure StandardTradeSettlementPageForEmptyPeriod()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [SCENARIO 235227] Standard Trade Settlement part is printed when report is running in empty VAT period.

        // [GIVEN] Take period where no VAT Entries
        VATEntry.FindLast();

        // [WHEN] Run REP 10618 "Trade Settlement - 2017" in empty period
        RunTradeSettlement2017ReportCombine(VATEntry."Entry No." + 1);

        // [THEN] Standard Trade Settlement part is printed with zero values
        OpenExcel();
        VerifyBoxVATBase(2, 0); // Total turnover and withdrawal based on import
        VerifyBoxVATBaseAndAmount(3, 0, 0); // Base and Amount for Domestic turnover and withdrawal, VAT 25 %
        VerifyBoxVATBaseAndAmount(4, 0, 0); // Base and Amount for Domestic turnover and withdrawal, VAT 15 %
        VerifyBoxVATBaseAndAmount(5, 0, 0); // Base and Amount for Domestic turnover and withdrawal, VAT 10 %
        VerifyBoxVATAmount(14, 0); // Amount for Deductible domestic input VAT, 25 %
        VerifyBoxVATAmount(15, 0); // Amount for Deductible domestic input VAT, 15 %
        VerifyBoxVATAmount(16, 0); // Amount for Deductible domestic input VAT, 10 %
        VerifyBoxVATAmount(19, 0); // Tax to pay
    end;

    [Test]
    [HandlerFunctions('TradeSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TradeSettlementPrintsVATEntriesWithBlankVATBusPostingGroup()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
    begin
        // [SCENARIO 331869] Trade settlement report prints VAT entries with blank VAT Bus. Posting Group.

        // [GIVEN] VAT Posting Setup with blank "VAT Bus. Posting Group".
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, '', VATProductPostingGroup.Code);
        // [GIVEN] VAT Entry with this VAT Posting Setup. Amount = "X".
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Posting Date" := WorkDate();
        VATEntry.Amount := LibraryRandom.RandDecInRange(100, 200, 2);
        VATEntry.Insert();

        // [WHEN] Run Trade Settlement 2017 report.
        Commit();
        VATEntry.SetRecFilter();
        RunTradeSettlement2017Report(VATEntry);

        // [THEN] The report shows the VAT Entry with blank "VAT Bus. Posting Group", VAT Amount = "X".
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueOnWorksheet(
          LibraryReportValidation.FindRowNoFromColumnNoAndValue(1, 'Total Sale'), 12,
          LibraryReportValidation.FormatDecimalValue(VATEntry.Amount), '1');
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
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", CVNo);
        RunTradeSettlement2017Report(VATEntry);
    end;

    local procedure RunTradeSettlement2017ReportCombine(LastVATEntryNo: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetFilter("Entry No.", '%1..', LastVATEntryNo + 1);
        RunTradeSettlement2017Report(VATEntry);
    end;

    local procedure RunTradeSettlement2017Report(var VATEntry: Record "VAT Entry")
    begin
        REPORT.Run(REPORT::"Trade Settlement 2017", true, true, VATEntry);
    end;

    local procedure OpenExcel()
    begin
        LibraryReportValidation.OpenExcelFile();
        StartingRowNo := LibraryReportValidation.FindRowNoFromColumnNoAndValue(1, ReportBoxALbl);
    end;

    local procedure GetRowNoOffsetByBoxNo(BoxNo: Integer): Integer
    begin
        case BoxNo of
            1:
                exit(1);
            2:
                exit(2);
            3:
                exit(4);
            4:
                exit(5);
            5:
                exit(6);
            6:
                exit(7);
            7:
                exit(8);
            8:
                exit(10);
            9:
                exit(12);
            10:
                exit(13);
            11:
                exit(14);
            12:
                exit(16);
            13:
                exit(17);
            14:
                exit(19);
            15:
                exit(20);
            16:
                exit(21);
            17:
                exit(23);
            18:
                exit(24);
            19:
                exit(26);
        end;
    end;

    local procedure GetColumnNo(Base: Boolean): Integer
    begin
        if Base then
            exit(3);
        exit(7);
    end;

    local procedure VerifyBoxVATBase(BoxNo: Integer; ExpectedValue: Decimal)
    begin
        LibraryReportValidation.VerifyCellValueOnWorksheet(
          StartingRowNo + GetRowNoOffsetByBoxNo(BoxNo),
          GetColumnNo(true),
          LibraryReportValidation.FormatDecimalValue(ExpectedValue), '2');
    end;

    local procedure VerifyBoxVATAmount(BoxNo: Integer; ExpectedValue: Decimal)
    begin
        LibraryReportValidation.VerifyCellValueOnWorksheet(
          StartingRowNo + GetRowNoOffsetByBoxNo(BoxNo),
          GetColumnNo(false),
          LibraryReportValidation.FormatDecimalValue(ExpectedValue), '2');
    end;

    local procedure VerifyBoxVATBaseAndAmount(BoxNo: Integer; Base: Decimal; Amount: Decimal)
    begin
        VerifyBoxVATBase(BoxNo, Base);
        VerifyBoxVATAmount(BoxNo, Amount);
    end;

    local procedure VerifyTradeSettlementReportLabels()
    begin
        LibraryReportValidation.VerifyCellValueOnWorksheet(1, 1, 'Trade settlement VAT', '1');

        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(StartingRowNo + 3, 1, 'B. Domestic turnover and withdrawal', '2');
        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(
          StartingRowNo + 4, 1, '3. Domestic turnover and withdrawal, VAT High', '2');
        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(
          StartingRowNo + 5, 1, '4. Domestic turnover and withdrawal, VAT Medium', '2');
        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(
          StartingRowNo + 6, 1, '5. Domestic turnover and withdrawal, VAT Low', '2');

        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(StartingRowNo + 11, 1, 'D. Import of goods', '2');
        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(
          StartingRowNo + 12, 1, '9. Import of goods, VAT High', '2');
        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(
          StartingRowNo + 13, 1, '10. Import of goods, VAT Medium', '2');

        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(StartingRowNo + 15, 1, 'E. Purchase subject to reverse charge', '2');
        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(
          StartingRowNo + 16, 1, '12. Purchase of intangible services from abroad, VAT High', '2');
        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(
          StartingRowNo + 17, 1, '13. Domestic purchases subject to reverse charge, VAT High', '2');

        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(StartingRowNo + 18, 1, 'F. Deduction of domestic input VAT', '2');
        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(
          StartingRowNo + 19, 1, '14. Deductible domestic input VAT High', '2');
        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(
          StartingRowNo + 20, 1, '15. Deductible domestic input VAT Medium', '2');
        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(
          StartingRowNo + 21, 1, '16. Deductible domestic input VAT Low', '2');

        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(StartingRowNo + 22, 1, 'G. Deduction of import VAT', '2');
        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(
          StartingRowNo + 23, 1, '17. Deductible import VAT High', '2');
        LibraryReportValidation.VerifyCellContainsValueOnWorksheet(
          StartingRowNo + 24, 1, '18. Deductible import VAT Medium', '2');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TradeSettlementRequestPageHandler(var TradeSettlement2017: TestRequestPage "Trade Settlement 2017")
    var
        NorwegianVATTools: Codeunit "Norwegian VAT Tools";
    begin
        TradeSettlement2017.SettlementYear.SetValue(Date2DMY(WorkDate(), 3));
        TradeSettlement2017.SettlementPeriod.SetValue(NorwegianVATTools.VATPeriodNo(WorkDate()));
        TradeSettlement2017.ExportXML.SetValue(false);
        TradeSettlement2017.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;
}

