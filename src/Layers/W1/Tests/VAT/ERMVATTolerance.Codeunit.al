codeunit 134042 "ERM VAT Tolerance"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [VAT Tolerance] [Payment Discount]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        AmountErr: Label '%1 must be %2 in %3.', Comment = '%1 is some Amount, %2 is another Amount, %3 is Table Caption';

    [Test]
    [Scope('OnPrem')]
    procedure HighVATTolBeforePostSalesDoc()
    var
        TempSalesLine: Record "Sales Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Sales Order Statistics when VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        SalesStatisticsWithVAT(TempSalesLine, VATTolerancePct, PaymentDiscountPct, false);

        // Verify VAT Amount and Rollback Payment Terms and General Ledger Setup.
        VerifySalesExclVAT(TempSalesLine, PaymentDiscountPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowVATTolBeforePostSalesDoc()
    var
        TempSalesLine: Record "Sales Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Sales Order Statistics when VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        SalesStatisticsWithVAT(TempSalesLine, VATTolerancePct, PaymentDiscountPct, false);

        // Verify VAT Amount and Rollback Payment Terms and General Ledger Setup.
        VerifySalesExclVAT(TempSalesLine, VATTolerancePct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HighInclVATBeforePostSalesDoc()
    var
        TempSalesLine: Record "Sales Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Sales Order Statistics when VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        SalesStatisticsWithVAT(TempSalesLine, VATTolerancePct, PaymentDiscountPct, true);

        // Verify VAT Amount Line and Rollback Payment Terms and General Ledger Setup.
        VerifyStatistics(TempSalesLine, PaymentDiscountPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowInclVATBeforePostSalesDoc()
    var
        TempSalesLine: Record "Sales Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Sales Order Statistics when VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        SalesStatisticsWithVAT(TempSalesLine, VATTolerancePct, PaymentDiscountPct, true);

        // Verify and Rollback Payment Terms and General Ledger Setup.
        VerifyStatistics(TempSalesLine, VATTolerancePct);
    end;

    local procedure SalesStatisticsWithVAT(var TempSalesLine: Record "Sales Line" temporary; VATTolerancePct: Decimal; PaymentDiscountPct: Decimal; PricesIncludingVAT: Boolean)
    var
        SalesHeader: Record "Sales Header";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Setup: Create Sales Order with Different VAT Posting Group Lines.
        SetupAndCreateSalesDocument(SalesHeader, TempSalesLine, VATTolerancePct, PaymentDiscountPct, PricesIncludingVAT);

        // Exercise: Calculate VAT Amount for all Sales Lines.
        TempSalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, TempSalesLine, VATAmountLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HighVATTolReleasedSalesDoc()
    var
        TempSalesLine: Record "Sales Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Released Sales Order Statistics when VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ReleasedSalesDocumentWithVAT(TempSalesLine, VATTolerancePct, PaymentDiscountPct, false);

        // Verify: Verify VAT Base Amount and Outstanding Amount on Sales Line and Rollback Payment Terms and General Ledger Setup.
        VerifySalesLineExcl(TempSalesLine, PaymentDiscountPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowVATTolReleasedSalesDoc()
    var
        TempSalesLine: Record "Sales Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Sales Order Statistics when VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ReleasedSalesDocumentWithVAT(TempSalesLine, VATTolerancePct, PaymentDiscountPct, false);

        // Verify: Verify VAT Base Amount and Outstanding Amount on Sales Line and Rollback Payment Terms and General Ledger Setup.
        VerifySalesLineExcl(TempSalesLine, VATTolerancePct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HighInclVATTolReleasedSalesDoc()
    var
        TempSalesLine: Record "Sales Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Released Sales Order Statistics when VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ReleasedSalesDocumentWithVAT(TempSalesLine, VATTolerancePct, PaymentDiscountPct, true);

        // Verify: Verify VAT Base Amount, Outstanding Amount on Sales Lines.
        VerifySalesLine(TempSalesLine, PaymentDiscountPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowInclVATTolReleasedSalesDoc()
    var
        TempSalesLine: Record "Sales Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Sales Order Statistics when VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ReleasedSalesDocumentWithVAT(TempSalesLine, VATTolerancePct, PaymentDiscountPct, true);

        // Verify: Verify VAT Base Amount, Outstanding Amount on Sales Lines.
        VerifySalesLine(TempSalesLine, VATTolerancePct);
    end;

    local procedure ReleasedSalesDocumentWithVAT(var TempSalesLine: Record "Sales Line" temporary; VATTolerancePct: Decimal; PaymentDiscountPct: Decimal; PricesIncludingVAT: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup: Create Sales Order with Different VAT Posting Group Lines.
        SetupAndCreateSalesDocument(SalesHeader, TempSalesLine, VATTolerancePct, PaymentDiscountPct, PricesIncludingVAT);

        // Exercise: Release Sales Document.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HighVATTolOnPostedSalesDoc()
    var
        TempSalesLine: Record "Sales Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Posted Sales Invoice Statistics when VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        PostedSalesStatisticsWithVAT(TempSalesLine, VATTolerancePct, PaymentDiscountPct, false);

        // Verify VAT Amount on Posted Sales Order Statistics
        VerifySalesExclVAT(TempSalesLine, PaymentDiscountPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowVATTolOnPostedSalesDoc()
    var
        TempSalesLine: Record "Sales Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Posted Sales Invoice Statistics when VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        PostedSalesStatisticsWithVAT(TempSalesLine, VATTolerancePct, PaymentDiscountPct, false);

        // Verify VAT Amount on Posted Sales Order Statistics
        VerifySalesExclVAT(TempSalesLine, VATTolerancePct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HighInclVATTolOnPostedSalesDoc()
    var
        TempSalesLine: Record "Sales Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Posted Sales Invoice Statistics when VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        PostedSalesStatisticsWithVAT(TempSalesLine, VATTolerancePct, PaymentDiscountPct, true);

        // Verify: Verify VAT Amount on Posted Sales Order Statistics.
        VerifyStatistics(TempSalesLine, PaymentDiscountPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowInclVATTolOnPostedSalesDoc()
    var
        TempSalesLine: Record "Sales Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Posted Sales Invoice Statistics when VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        PostedSalesStatisticsWithVAT(TempSalesLine, VATTolerancePct, PaymentDiscountPct, true);

        // Verify: Verify VAT Amount on Posted Sales Order Statistics.
        VerifyStatistics(TempSalesLine, VATTolerancePct);
    end;

    local procedure PostedSalesStatisticsWithVAT(var TempSalesLine: Record "Sales Line" temporary; VATTolerancePct: Decimal; PaymentDiscountPct: Decimal; PricesIncludingVAT: Boolean)
    var
        SalesHeader: Record "Sales Header";
        VATAmountLine: Record "VAT Amount Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        PostedDocumentNo: Code[20];
    begin
        // Setup: Create Sales Order with Different VAT Posting Group Lines.
        SetupAndCreateSalesDocument(SalesHeader, TempSalesLine, VATTolerancePct, PaymentDiscountPct, PricesIncludingVAT);

        // Exercise: Post Sales Order.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(PostedDocumentNo);
        SalesInvoiceLine.CalcVATAmountLines(SalesInvoiceHeader, VATAmountLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroVATAmtReleasedSalesDoc()
    var
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Base, Outstanding Amount on Sales Line after Releasing Sales Order. VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ZeroAmountVATSalesDocument(VATTolerancePct, PaymentDiscountPct, PaymentDiscountPct, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowVATTolZeroVATSalesDoc()
    var
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Base, Outstanding Amount on Sales Line after Releasing Sales Order. VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ZeroAmountVATSalesDocument(VATTolerancePct, PaymentDiscountPct, VATTolerancePct, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroInclVATReleasedSalesDoc()
    var
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Base, Outstanding Amount on Sales Line after Releasing Sales Order. VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ZeroAmountVATSalesDocument(VATTolerancePct, PaymentDiscountPct, PaymentDiscountPct, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowInclVATTolZeroVATSalesDoc()
    var
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Base, Outstanding Amount on Sales Line after Releasing Sales Order. VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ZeroAmountVATSalesDocument(VATTolerancePct, PaymentDiscountPct, VATTolerancePct, true);
    end;

    local procedure ZeroAmountVATSalesDocument(VATTolerancePct: Decimal; PaymentDiscountPct: Decimal; TolerancePctForCalculation: Decimal; PricesIncludingVAT: Boolean)
    var
        SalesHeader: Record "Sales Header";
        TempSalesLine: Record "Sales Line" temporary;
    begin
        // Setup: Create a Sales Order with Zero VAT Posting Setup Item.
        SetupAndCreateZeroVATSalesDoc(SalesHeader, TempSalesLine, VATTolerancePct, PaymentDiscountPct, PricesIncludingVAT);

        // Exercise: Release Sales Order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Verify: Verify VAT Base and Outstanding Amount on Sales Line and Tear Down.
        VerifySalesLine(TempSalesLine, TolerancePctForCalculation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroVATAmtOnPostedSalesDoc()
    var
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Base, Outstanding Amount on Posted Sales Line when VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ZeroVATPostedSalesDocument(VATTolerancePct, PaymentDiscountPct, PaymentDiscountPct, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowVATTolZeroVATOnPostSalesDoc()
    var
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Base, Outstanding Amount on Posted Sales Line when VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ZeroVATPostedSalesDocument(VATTolerancePct, PaymentDiscountPct, VATTolerancePct, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroInclVATOnPostedSalesDoc()
    var
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Base, Outstanding Amount on Posted Sales Line when VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ZeroVATPostedSalesDocument(VATTolerancePct, PaymentDiscountPct, PaymentDiscountPct, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowInclVATOnPostedSalesDoc()
    var
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Base, Outstanding Amount on Posted Sales Line when VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ZeroVATPostedSalesDocument(VATTolerancePct, PaymentDiscountPct, VATTolerancePct, true);
    end;

    local procedure ZeroVATPostedSalesDocument(VATTolerancePct: Decimal; PaymentDiscountPct: Decimal; TolerancePctForCalculation: Decimal; PricesIncludingVAT: Boolean)
    var
        SalesHeader: Record "Sales Header";
        TempSalesLine: Record "Sales Line" temporary;
        PostedDocumentNo: Code[20];
        VATBaseAmount: Decimal;
    begin
        // Setup: Create a Sales Order with Zero VAT Posting Setup Item.
        SetupAndCreateZeroVATSalesDoc(SalesHeader, TempSalesLine, VATTolerancePct, PaymentDiscountPct, PricesIncludingVAT);
        VATBaseAmount := TempSalesLine."Line Amount" - Round(TempSalesLine."Line Amount" * TolerancePctForCalculation / 100);

        // Exercise: Post the Sales Order.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify VAT Base Amount and Amount Including VAT on Posted Sales Document.
        VerifyPostedSalesLine(PostedDocumentNo, VATBaseAmount, TempSalesLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HighVATTolBeforePostPurchDoc()
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Purchase Order Statistics when VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        PurchStatisticsWithVAT(TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, false);

        // Verify VAT Amount for every VAT Amount Line and Rollback Payment Terms and General Ledger Setup.
        VerifyPurchExclVAT(TempPurchaseLine, PaymentDiscountPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowVATTolBeforePostPurchDoc()
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Purchase Order Statistics when VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        PurchStatisticsWithVAT(TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, false);

        // Verify VAT Amount for every VAT Amount Line and Rollback Payment Terms and General Ledger Setup.
        VerifyPurchExclVAT(TempPurchaseLine, VATTolerancePct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HighInclVATBeforePostPurchDoc()
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Purchase Order Statistics when VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        PurchStatisticsWithVAT(TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, true);

        // Verify: Verify VAT Amount for every VAT Amount Line.
        VerifyPurchVAT(TempPurchaseLine, PaymentDiscountPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowInclVATBeforePostPurchDoc()
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Purchase Order Statistics when VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        PurchStatisticsWithVAT(TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, true);

        // Verify: Verify VAT Amount for every VAT Amount Line.
        VerifyPurchVAT(TempPurchaseLine, VATTolerancePct);
    end;

    local procedure PurchStatisticsWithVAT(var TempPurchaseLine: Record "Purchase Line" temporary; VATTolerancePct: Decimal; PaymentDiscountPct: Decimal; PricesIncludingVAT: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Setup: Create Purchase Order with Different VAT Posting Group Lines.
        SetupAndCreatePurchaseDocument(PurchaseHeader, TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, PricesIncludingVAT);

        // Exercise: Calculate VAT Amount for all Purchase Lines.
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, TempPurchaseLine, VATAmountLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HighVATTolReleasedPurchDoc()
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Released Purchase Order Statistics when VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ReleasedPurchDocumentWithVAT(TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, false);

        // Verify: Verify VAT Base Amount, Outstanding Amount on Purchase Lines and Rollback Payment Terms and General Ledger Setup.
        VerifyPurchLineExcl(TempPurchaseLine, PaymentDiscountPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowVATTolReleasedPurchDoc()
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Purchase Order Statistics when VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ReleasedPurchDocumentWithVAT(TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, false);

        // Verify: Verify VAT Base Amount, Outstanding Amount on Purchase Lines and Rollback Payment Terms and General Ledger Setup.
        VerifyPurchLineExcl(TempPurchaseLine, VATTolerancePct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HighInclVATTolReleasedPurchDoc()
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Released Purchase Order Statistics when VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ReleasedPurchDocumentWithVAT(TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, true);

        // Verify: Verify VAT Base Amount, Outstanding Amount on Purchase Lines.
        VerifyPurchLine(TempPurchaseLine, PaymentDiscountPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowInclVATTolReleasedPurchDoc()
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Purchase Order Statistics when VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ReleasedPurchDocumentWithVAT(TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, true);

        // Verify: Verify VAT Base Amount, Outstanding Amount on Purchase Lines.
        VerifyPurchLine(TempPurchaseLine, VATTolerancePct);
    end;

    local procedure ReleasedPurchDocumentWithVAT(var TempPurchaseLine: Record "Purchase Line" temporary; VATTolerancePct: Decimal; PaymentDiscountPct: Decimal; PricesIncludingVAT: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup: Create Purchase Order with Different VAT Posting Group Lines.
        SetupAndCreatePurchaseDocument(PurchaseHeader, TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, PricesIncludingVAT);

        // Exercise: Release Purchase Document.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HighVATTolOnPostedPurchDoc()
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Posted Purchase Invoice Statistics when VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        PostedPurchStatisticsWithVAT(TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, false);

        // Verify VAT Amount on Posted Purchase Order Statistics and Rollback Payment Terms and General Ledger Setup.
        VerifyPurchExclVAT(TempPurchaseLine, PaymentDiscountPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowVATTolOnPostedPurchDoc()
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Posted Purchase Invoice Statistics when VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        PostedPurchStatisticsWithVAT(TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, false);

        // Verify VAT Amount on Posted Purchase Order Statistics and Rollback Payment Terms and General Ledger Setup.
        VerifyPurchExclVAT(TempPurchaseLine, VATTolerancePct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HighInclVATTolOnPostedPurchDoc()
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Posted Purchase Invoice Statistics when VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        PostedPurchStatisticsWithVAT(TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, true);

        // Verify: Verify VAT Amount on Posted Purchase Order Statistics.
        VerifyPurchVAT(TempPurchaseLine, PaymentDiscountPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowInclVATTolOnPostedPurchDoc()
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Amount on Posted Purchase Invoice Statistics when VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        PostedPurchStatisticsWithVAT(TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, true);

        // Verify: Verify VAT Amount on Posted Purchase Order Statistics.
        VerifyPurchVAT(TempPurchaseLine, VATTolerancePct);
    end;

    local procedure PostedPurchStatisticsWithVAT(var TempPurchaseLine: Record "Purchase Line" temporary; VATTolerancePct: Decimal; PaymentDiscountPct: Decimal; PricesIncludingVAT: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        VATAmountLine: Record "VAT Amount Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PostedDocumentNo: Code[20];
    begin
        // Setup: Create Purchase Order with Different VAT Posting Group Lines.
        SetupAndCreatePurchaseDocument(PurchaseHeader, TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, PricesIncludingVAT);

        // Exercise: Post Purchase Order.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvHeader.Get(PostedDocumentNo);
        PurchInvLine.CalcVATAmountLines(PurchInvHeader, VATAmountLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroVATAmtReleasedPurchDoc()
    var
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Base, Outstanding Amount on Line after Releasing Purchase Order. VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ZeroAmtVATPurchDocument(VATTolerancePct, PaymentDiscountPct, PaymentDiscountPct, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowVATTolZeroVATPurchDoc()
    var
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Base, Outstanding Amount on Line after Releasing Purchase Order. VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ZeroAmtVATPurchDocument(VATTolerancePct, PaymentDiscountPct, VATTolerancePct, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroInclVATAmtReleasedPurchDoc()
    var
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Base, Outstanding Amount on Line after Releasing Purchase Order. VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ZeroAmtVATPurchDocument(VATTolerancePct, PaymentDiscountPct, PaymentDiscountPct, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowInclVATTolZeroVATPurchDoc()
    var
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Base, Outstanding Amount on Line after Releasing Purchase Order. VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ZeroAmtVATPurchDocument(VATTolerancePct, PaymentDiscountPct, VATTolerancePct, true);
    end;

    local procedure ZeroAmtVATPurchDocument(VATTolerancePct: Decimal; PaymentDiscountPct: Decimal; TolerancePctForCalculation: Decimal; PricesIncludingVAT: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        // Setup: Create a Purchase Order with Zero VAT Posting Setup Item.
        SetupAndCreateZeroVATPurchDoc(PurchaseHeader, TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, PricesIncludingVAT);

        // Exercise: Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Verify: Verify VAT Base and Outstanding Amount on Purchase Line and Tear Down.
        VerifyPurchLine(TempPurchaseLine, TolerancePctForCalculation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroVATAmtPostedPurchDoc()
    var
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Base, Outstanding Amount on Posted Purchase Line when VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ZeroAmtVATPurchDocument(VATTolerancePct, PaymentDiscountPct, PaymentDiscountPct, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowVATTolZeroVATPostPurchDoc()
    var
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Base, Outstanding Amount on Posted Purchase Line when VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ZeroVATOnPostedPurchDocument(VATTolerancePct, PaymentDiscountPct, VATTolerancePct, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroInclVATAmtPostedPurchDoc()
    var
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Base, Outstanding Amount on Posted Purchase Line when VAT Tolerance % greater than Payment Discount %.
        Initialize();
        ComputeHighVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ZeroVATOnPostedPurchDocument(VATTolerancePct, PaymentDiscountPct, PaymentDiscountPct, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowInclVATZeroPostedPurchDoc()
    var
        VATTolerancePct: Decimal;
        PaymentDiscountPct: Decimal;
    begin
        // Check VAT Base, Outstanding Amount on Posted Purchase Line when VAT Tolerance % less than Payment Discount %.
        Initialize();
        ComputeLowVATTolerancePct(VATTolerancePct, PaymentDiscountPct);
        ZeroVATOnPostedPurchDocument(VATTolerancePct, PaymentDiscountPct, VATTolerancePct, true);
    end;

    local procedure ZeroVATOnPostedPurchDocument(VATTolerancePct: Decimal; PaymentDiscountPct: Decimal; TolerancePctForCalculation: Decimal; PricesIncludingVAT: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        PostedDocumentNo: Code[20];
        VATBaseAmount: Decimal;
    begin
        // Setup: Create a Purchase Order with Zero VAT Posting Setup Item.
        SetupAndCreateZeroVATPurchDoc(PurchaseHeader, TempPurchaseLine, VATTolerancePct, PaymentDiscountPct, PricesIncludingVAT);
        VATBaseAmount := TempPurchaseLine."Line Amount" - Round(TempPurchaseLine."Line Amount" * TolerancePctForCalculation / 100);

        // Exercise: Post the Purchase Order.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify VAT Base Amount and Amount Including VAT on Posted Purchase Document.
        VerifyPostedPurchaseLine(PostedDocumentNo, VATBaseAmount, TempPurchaseLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralLineWithApplyToOldest()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Customer Ledger Entry and Detailed Customer Ledger Entry while creating a General Journal Line of Invoice and posting
        // Credit Memo for same amount using Apply To Oldest method.

        // Setup: Create a General Journal Line with LibraryRandom used for Random Amount of Invoice type and post it.
        Initialize();
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CreateCustomer(), LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Create Credit Memo for the above Invoice using Apply To Oldest method.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, GenJournalLine."Account No.", -GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Check Customer Ledger Entry and Detailed Customer Ledger Entry.
        VerifyCustomerLedgerEntry(GenJournalLine."Account No.", -GenJournalLine.Amount, GenJournalLine."Document Date");
        VerifyDetailedCustLedgerEntry(GenJournalLine."Account No.", -GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseChargeVATAmountWithTolerance()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        DocNo: Code[20];
        DiscountPct: Decimal;
        VATTolerancePct: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT]
        // [SCENARIO 375142] VAT Base Amount for Reverse Charge VAT should be lowered with VAT Tolerance %

        Initialize();
        SetupReverseChargeVATPostingSetupWithVATTolerance(VATPostingSetup, DiscountPct, VATTolerancePct);

        // [GIVEN] Purchase Invoice with Amount = 100, Reverse Charge VAT % = 25, "VAT Tolerance %" = 3, "Pmt. Discount %" = 5
        Amount := CreatePurchaseInvWithReverseChargeVATAndPmtDisc(PurchHeader, VATPostingSetup, DiscountPct);

        // [WHEN] Post purchase invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] G/L Entry posted with "G/L Account No." = "Reverse Chrg. VAT Acc." and Amount = 100 * 0,3 * 0,25 = 7,5
        VerifyGLEntry(
          VATPostingSetup."Reverse Chrg. VAT Acc.", DocNo, -CalcVATAmountWithTolerance(Amount, VATTolerancePct, VATPostingSetup."VAT %"));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM VAT Tolerance");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM VAT Tolerance");
        // Need to use the following setups to prevent localization test failures.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(false);
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM VAT Tolerance");
    end;

    local procedure CreatePurchaseInvWithReverseChargeVATAndPmtDisc(var PurchHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; DiscountPct: Decimal): Decimal
    var
        GLAccount: Record "G/L Account";
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order, CreateVendWithPmtTerms(VATPostingSetup."VAT Bus. Posting Group", DiscountPct));
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase),
          LibraryRandom.RandInt(10));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
        exit(PurchLine.Amount);
    end;

    local procedure CreateVendWithPmtTerms(VATBusPostingGroupCode: Code[20]; DiscountPct: Decimal): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        PaymentTerms.Validate("Discount %", DiscountPct);
        PaymentTerms.Modify(true);
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusPostingGroupCode));
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure SetupReverseChargeVATPostingSetupWithVATTolerance(var VATPostingSetup: Record "VAT Posting Setup"; var DiscountPct: Decimal; var VATTolerancePct: Decimal)
    begin
        ComputeLowVATTolerancePct(VATTolerancePct, DiscountPct);
        UpdateGeneralLedgerSetup(VATTolerancePct);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo()); // different from Purch. VAT Acc. Required for BE
        VATPostingSetup.Modify(true);
    end;

    local procedure ComputeHighVATTolerancePct(var VATTolerancePct: Decimal; var PaymentDiscountPct: Decimal)
    begin
        // Taking VAT Tolerance Percent value greater than 2 to make VAT Tolerance %  Greater than Payment Discount %.
        VATTolerancePct := 2 + LibraryRandom.RandInt(5);
        PaymentDiscountPct := VATTolerancePct - 1;
    end;

    local procedure ComputeLowVATTolerancePct(var VATTolerancePct: Decimal; var PaymentDiscountPct: Decimal)
    begin
        // Taking Random Payment Discount value greater than VAT Tolerance %.
        VATTolerancePct := LibraryRandom.RandInt(5);
        PaymentDiscountPct := VATTolerancePct + LibraryRandom.RandInt(5);
    end;

    local procedure CopyPurchaseLine(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseLine: Record "Purchase Line")
    begin
        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();
    end;

    local procedure CopySalesLine(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line")
    begin
        TempSalesLine := SalesLine;
        TempSalesLine.Insert();
    end;

    local procedure CreateCustomerWithPmtTerms(): Code[20]
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibrarySales.CreateCustomer(Customer);
        // Customer.VALIDATE("VAT Bus. Posting Group",FindVATBusPostingGroup());
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; PricesIncludingVAT: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorWithPmtTerms());
        PurchaseHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; No: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithZeroVAT(var PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; PricesIncludingVAT: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        VATProdPostingGroup: Code[20];
    begin
        CreatePurchaseHeader(PurchaseHeader, PricesIncludingVAT);
        VATProdPostingGroup := UpdatePurchHeaderWithZeroVATPostSetup(PurchaseHeader);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, CreateItem(VATProdPostingGroup));
        CopyPurchaseLine(TempPurchaseLine, PurchaseLine);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; PricesIncludingVAT: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerWithPmtTerms());
        SalesHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; No: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithZeroVAT(var SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; PricesIncludingVAT: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, PricesIncludingVAT);
        CreateSalesLine(SalesLine, SalesHeader, CreateItem(FindVATPostingSetupZeroVAT()));
        CopySalesLine(TempSalesLine, SalesLine);
    end;

    local procedure CreateVATPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; PricesIncludingVAT: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Create Purchase Order with 3 Different VAT Posting Group Items.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseHeader(PurchaseHeader, PricesIncludingVAT);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        CopyPurchaseLine(TempPurchaseLine, PurchaseLine);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, FindItem(PurchaseLine."VAT %"));
        CopyPurchaseLine(TempPurchaseLine, PurchaseLine);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, CreateItem(FindVATPostingSetupZeroVAT()));
        CopyPurchaseLine(TempPurchaseLine, PurchaseLine);
    end;

    local procedure CreateVATSalesDocument(var SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; PricesIncludingVAT: Boolean)
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Create Sales Order with 3 Different VAT Posting Group Items.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesHeader(SalesHeader, PricesIncludingVAT);
        CreateSalesLine(SalesLine, SalesHeader, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        CopySalesLine(TempSalesLine, SalesLine);
        CreateSalesLine(SalesLine, SalesHeader, FindItem(SalesLine."VAT %"));
        CopySalesLine(TempSalesLine, SalesLine);
        CreateSalesLine(SalesLine, SalesHeader, CreateItem(FindVATPostingSetupZeroVAT()));
        CopySalesLine(TempSalesLine, SalesLine);
    end;

    local procedure CreateVendorWithPmtTerms(): Code[20]
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        // Vendor.VALIDATE("VAT Bus. Posting Group",FindVATBusPostingGroup());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure FindItem(VATPct: Decimal): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Not using Library Item Finder method to make this funtion World ready.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetFilter("VAT %", '>0&<>%1', VATPct);
        VATPostingSetup.FindFirst();
        Item.SetRange(Blocked, false);
        Item.FindFirst();
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2)); // Using Random for Random Decimal value.
        Item.Validate("Unit Price", Item."Last Direct Cost");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure FindVATPostingSetupZeroVAT(): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindZeroVATPostingSetup(VATPostingSetup);
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure FindZeroVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>''''');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT %", 0);
        VATPostingSetup.FindFirst();
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exits before creating
        // General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure CalcVATAmountWithTolerance(Amount: Decimal; VATTolerancePct: Decimal; VATPct: Decimal): Decimal
    begin
        exit(
          Round(Amount * (1 - VATTolerancePct / 100) * VATPct / 100, LibraryERM.GetAmountRoundingPrecision()));
    end;

    local procedure SetupAndCreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; VATTolerancePct: Decimal; PaymentDiscountPct: Decimal; PricesIncludingVAT: Boolean)
    begin
        UpdateGeneralLedgerSetup(VATTolerancePct);
        UpdatePaymentTerms(PaymentDiscountPct);
        CreateVATPurchaseDocument(PurchaseHeader, TempPurchaseLine, PricesIncludingVAT);
    end;

    local procedure SetupAndCreateSalesDocument(var SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; VATTolerancePct: Decimal; PaymentDiscountPct: Decimal; PricesIncludingVAT: Boolean)
    begin
        UpdateGeneralLedgerSetup(VATTolerancePct);
        UpdatePaymentTerms(PaymentDiscountPct);
        CreateVATSalesDocument(SalesHeader, TempSalesLine, PricesIncludingVAT);
    end;

    local procedure SetupAndCreateZeroVATPurchDoc(var PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; VATTolerancePct: Decimal; PaymentDiscountPct: Decimal; PricesIncludingVAT: Boolean)
    begin
        UpdateGeneralLedgerSetup(VATTolerancePct);
        UpdatePaymentTerms(PaymentDiscountPct);
        CreatePurchaseOrderWithZeroVAT(PurchaseHeader, TempPurchaseLine, PricesIncludingVAT);
    end;

    local procedure SetupAndCreateZeroVATSalesDoc(var SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; VATTolerancePct: Decimal; PaymentDiscountPct: Decimal; PricesIncludingVAT: Boolean)
    begin
        UpdateGeneralLedgerSetup(VATTolerancePct);
        UpdatePaymentTerms(PaymentDiscountPct);
        CreateSalesDocumentWithZeroVAT(SalesHeader, TempSalesLine, PricesIncludingVAT);
    end;

    local procedure UpdateGeneralLedgerSetup(VATTolerancePct: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Pmt. Disc. Excl. VAT", true);
        GeneralLedgerSetup.Validate("VAT Tolerance %", VATTolerancePct);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePaymentTerms(DiscountPct: Decimal)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        PaymentTerms.Validate("Discount %", DiscountPct);
        PaymentTerms.Modify(true);
    end;

    local procedure UpdatePurchHeaderWithZeroVATPostSetup(var PurchaseHeader: Record "Purchase Header"): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindZeroVATPostingSetup(VATPostingSetup);
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Modify(true);
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure VerifyCustomerLedgerEntry(CustomerNo: Code[20]; Amount: Decimal; PmtDiscountDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount);
        CustLedgerEntry.TestField(Amount, Amount);
        CustLedgerEntry.TestField("Pmt. Discount Date", PmtDiscountDate);
    end;

    local procedure VerifyPostedPurchaseLine(DocumentNo: Code[20]; VATBaseAmount: Decimal; AmountIncludingVAT: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();
        Assert.AreNearlyEqual(
          VATBaseAmount, PurchInvLine."VAT Base Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, PurchInvLine.FieldCaption("VAT Base Amount"), VATBaseAmount, PurchInvLine.TableCaption()));
        Assert.AreNearlyEqual(
          AmountIncludingVAT, PurchInvLine."Amount Including VAT", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, PurchInvLine.FieldCaption("Amount Including VAT"), AmountIncludingVAT, PurchInvLine.TableCaption()));
    end;

    [Normal]
    local procedure VerifyDetailedCustLedgerEntry(CustomerNo: Code[20]; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::Invoice);
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyGLEntry(GLAccNo: Code[20]; DocNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyPostedSalesLine(DocumentNo: Code[20]; VATBaseAmount: Decimal; AmountIncludingVAT: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        Assert.AreNearlyEqual(
          VATBaseAmount, SalesInvoiceLine."VAT Base Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, SalesInvoiceLine.FieldCaption("VAT Base Amount"), VATBaseAmount, SalesInvoiceLine.TableCaption()));
        Assert.AreNearlyEqual(
          AmountIncludingVAT, SalesInvoiceLine."Amount Including VAT", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, SalesInvoiceLine.FieldCaption("Amount Including VAT"), AmountIncludingVAT, SalesInvoiceLine.TableCaption()));
    end;

    local procedure VerifyPurchLine(var TempPurchaseLine: Record "Purchase Line" temporary; TolerancePctForCalculation: Decimal)
    var
        VATBaseAmount: Decimal;
        VATAmount: Decimal;
    begin
        // Verify: Verify VAT Base Amount on Purchase Line.
        TempPurchaseLine.FindSet();
        repeat
            VATAmount :=
              TempPurchaseLine."Line Amount" - Round(
                TempPurchaseLine."Line Amount" * TempPurchaseLine."VAT %" / (100 + TempPurchaseLine."VAT %"));
            VATBaseAmount := VATAmount - Round(VATAmount * TolerancePctForCalculation / 100);
            VerifyVATBaseAmountOnPurchLine(TempPurchaseLine, VATBaseAmount);
        until TempPurchaseLine.Next() = 0;
    end;

    local procedure VerifyPurchLineExcl(var TempPurchaseLine: Record "Purchase Line" temporary; TolerancePctForCalculation: Decimal)
    var
        OutstandingAmount: Decimal;
        VATBaseAmount: Decimal;
    begin
        // Verify: Verify VAT Base Amount on Purchase Line.
        TempPurchaseLine.FindSet();
        repeat
            VATBaseAmount := TempPurchaseLine."Line Amount" - Round(TempPurchaseLine."Line Amount" * TolerancePctForCalculation / 100);
            OutstandingAmount := TempPurchaseLine."Line Amount" + Round(VATBaseAmount * TempPurchaseLine."VAT %" / 100);
            VerifyVATEntryOnPurchLine(TempPurchaseLine, VATBaseAmount, OutstandingAmount);
        until TempPurchaseLine.Next() = 0;
    end;

    local procedure VerifyPurchVAT(var TempPurchaseLine: Record "Purchase Line" temporary; TolerancePctForCalculation: Decimal)
    var
        VATAmount: Decimal;
    begin
        TempPurchaseLine.FindSet();
        repeat
            VATAmount := Round(TempPurchaseLine."Line Amount" * TempPurchaseLine."VAT %" / (100 + TempPurchaseLine."VAT %"));
            VerifyVATOnStatistics(TempPurchaseLine."VAT %", VATAmount - Round(VATAmount * TolerancePctForCalculation / 100));
        until TempPurchaseLine.Next() = 0;
    end;

    local procedure VerifyPurchExclVAT(var TempPurchaseLine: Record "Purchase Line" temporary; TolerancePctForCalculation: Decimal)
    var
        VATAmount: Decimal;
    begin
        TempPurchaseLine.FindSet();
        repeat
            VATAmount := Round(TempPurchaseLine."Line Amount" * TempPurchaseLine."VAT %" / 100);
            VerifyVATOnStatistics(TempPurchaseLine."VAT %", VATAmount - Round(VATAmount * TolerancePctForCalculation / 100));
        until TempPurchaseLine.Next() = 0;
    end;

    local procedure VerifySalesExclVAT(var TempSalesLine: Record "Sales Line" temporary; TolerancePctForCalculation: Decimal)
    var
        VATAmount: Decimal;
    begin
        TempSalesLine.FindSet();
        repeat
            VATAmount := Round(TempSalesLine."Line Amount" * TempSalesLine."VAT %" / 100);
            VerifyVATOnStatistics(TempSalesLine."VAT %", VATAmount - Round(VATAmount * TolerancePctForCalculation / 100));
        until TempSalesLine.Next() = 0;
    end;

    local procedure VerifySalesLine(var TempSalesLine: Record "Sales Line" temporary; TolerancePctForCalculation: Decimal)
    var
        VATBaseAmount: Decimal;
        VATAmount: Decimal;
    begin
        // Verify: Verify VAT Base Amount on Sales Line.
        TempSalesLine.FindSet();
        repeat
            VATAmount :=
              TempSalesLine."Line Amount" - Round(TempSalesLine."Line Amount" * TempSalesLine."VAT %" / (100 + TempSalesLine."VAT %"));
            VATBaseAmount := Round(VATAmount - (VATAmount * TolerancePctForCalculation / 100));
            VerifyVATBaseAmountOnSalesLine(TempSalesLine, VATBaseAmount);
        until TempSalesLine.Next() = 0;
    end;

    local procedure VerifySalesLineExcl(var TempSalesLine: Record "Sales Line" temporary; TolerancePctForCalculation: Decimal)
    var
        VATBaseAmount: Decimal;
        OutstandingAmount: Decimal;
    begin
        // Verify: Verify VAT Base Amount and Outstanding Amount on Sales Line.
        TempSalesLine.FindSet();
        repeat
            VATBaseAmount := TempSalesLine."Line Amount" - Round(TempSalesLine."Line Amount" * TolerancePctForCalculation / 100);
            OutstandingAmount := TempSalesLine."Line Amount" + Round(VATBaseAmount * TempSalesLine."VAT %" / 100);
            VerifyVATEntriesOnSalesLine(TempSalesLine, VATBaseAmount, OutstandingAmount);
        until TempSalesLine.Next() = 0;
    end;

    local procedure VerifyStatistics(var TempSalesLine: Record "Sales Line" temporary; TolerancePctForCalculation: Decimal)
    var
        VATAmount: Decimal;
    begin
        TempSalesLine.FindSet();
        repeat
            VATAmount := Round(TempSalesLine."Line Amount" * TempSalesLine."VAT %" / (100 + TempSalesLine."VAT %"));
            VerifyVATOnStatistics(TempSalesLine."VAT %", VATAmount - Round(VATAmount * TolerancePctForCalculation / 100));
        until TempSalesLine.Next() = 0;
    end;

    local procedure VerifyVATBaseAmountOnPurchLine(TempPurchaseLine: Record "Purchase Line" temporary; VATBaseAmount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Get(TempPurchaseLine."Document Type", TempPurchaseLine."Document No.", TempPurchaseLine."Line No.");
        Assert.AreNearlyEqual(
          VATBaseAmount, PurchaseLine."VAT Base Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, PurchaseLine.FieldCaption("VAT Base Amount"), VATBaseAmount, PurchaseLine.TableCaption()));
    end;

    local procedure VerifyVATBaseAmountOnSalesLine(TempSalesLine: Record "Sales Line" temporary; VATBaseAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(TempSalesLine."Document Type", TempSalesLine."Document No.", TempSalesLine."Line No.");
        Assert.AreNearlyEqual(
          VATBaseAmount, SalesLine."VAT Base Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, SalesLine.FieldCaption("VAT Base Amount"), VATBaseAmount, SalesLine.TableCaption()));
    end;

    local procedure VerifyVATEntryOnPurchLine(TempPurchaseLine: Record "Purchase Line" temporary; VATBaseAmount: Decimal; OutstandingAmount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Get(TempPurchaseLine."Document Type", TempPurchaseLine."Document No.", TempPurchaseLine."Line No.");
        VerifyVATBaseAmountOnPurchLine(TempPurchaseLine, VATBaseAmount);
        Assert.AreNearlyEqual(
          OutstandingAmount, PurchaseLine."Outstanding Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, PurchaseLine.FieldCaption("Outstanding Amount"), OutstandingAmount, PurchaseLine.TableCaption()));
    end;

    local procedure VerifyVATEntriesOnSalesLine(TempSalesLine: Record "Sales Line" temporary; VATBaseAmount: Decimal; OutstandingAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(TempSalesLine."Document Type", TempSalesLine."Document No.", TempSalesLine."Line No.");
        VerifyVATBaseAmountOnSalesLine(TempSalesLine, VATBaseAmount);
        Assert.AreNearlyEqual(
          OutstandingAmount, SalesLine."Outstanding Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, SalesLine.FieldCaption("Outstanding Amount"), OutstandingAmount, SalesLine.TableCaption()));
    end;

    local procedure VerifyVATOnStatistics(VATPct: Decimal; VATAmount: Decimal)
    var
        VATAmountLine: Record "VAT Amount Line";
    begin
        VATAmountLine.SetRange("VAT %", VATPct);
        VATAmountLine.FindFirst();
        Assert.AreNearlyEqual(
          VATAmount, VATAmountLine."VAT Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATAmountLine.FieldCaption("VAT Amount"), VATAmount, VATAmountLine.TableCaption()));
    end;
}

