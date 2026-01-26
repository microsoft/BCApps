codeunit 141036 "UT VAT For SEA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [Report]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        AmountLangCap: Label 'AmountLangB1AmountLangB2';
        AmountLangTxt: Label '%1 ';
        LibraryRandom: Codeunit "Library - Random";
        AppliedToTextCap: Label 'AppliedToText';
        AppliesTxt: Label '(Applies to %1 %2)', Comment = '%1 for Applies to Doc. Type, %2 for Applies to Doc. No.';
        BuyfromVendNoCap: Label 'BuyfromVendNo_PurchTaxCrMemoHdr';
        NoPurchTaxCrMemoCap: Label 'No_PurchTaxCrMemoHdr';
        NoPurchTaxInvHdrCap: Label 'No_PurchTaxInvHdr';
        NoSalesCrMemoCap: Label 'No_SalesTaxCrMemoHeader';
        NoSalesTaxInvHdrCap: Label 'No_SalesTaxInvHdr';
        OrderNoCap: Label 'OrderNo_PurchTaxInvHdr';
        ReturnOrderNoCap: Label 'ReturnOrderNo_SalesTaxCrMemoHeader';
        VATRegNoPurchCrMemoCap: Label 'VATRegNo_PurchTaxCrMemoHdr';
        VATRegNoPurchInvHdrCap: Label 'VATRegNo_PurchTaxInvHdr';
        VATRegNoSalesCrMemoCap: Label 'VATRegNo_SalesTaxCrMemoHeader';
        VATRegNoSalesInvHdrCap: Label 'VATRegNo_SalesTaxInvHdr';
        YourRefPurchCrMemoCap: Label 'YourRef_PurchTaxCrMemoHdr';
        YourReferenceSalesInvCap: Label 'YourReference_SalesTaxInvHdr';

    [Test]
    [HandlerFunctions('PurchTaxInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchTaxInvHeaderPurchTaxInvoice()
    var
        PurchTaxInvHeader: Record "Purch. Tax Inv. Header";
    begin
        // [FEATURE] [Purchase] [Tax Invoice]
        // [SCENARIO] Purpose of the test is to validate Purch. Tax Inv. Header - OnAfterGetRecord Trigger of Report - 28071 (Purch. - Tax Invoice).

        // Setup.
        Initialize();
        PurchTaxInvHeader.Get(CreatePurchTaxInvHeader());

        // Exercise.
        RunMiscellaneousReport(PurchTaxInvHeader."No.", true, false, REPORT::"Purch. - Tax Invoice");  // Opens PurchTaxInvoiceRequestPageHandler. ShowInternalInformation as True and ShowTHAmountInWords as False.

        // Verify: Verify values of No_PurchTaxInvHdr, OrderNo_PurchTaxInvHdr and VATRegNo_PurchTaxInvHdr on Report - 28071 (Purch. - Tax Invoice).
        VerifyXMLValuesForMiscellaneousReport(NoPurchTaxInvHdrCap, OrderNoCap, VATRegNoPurchInvHdrCap, PurchTaxInvHeader."No.", '', '');  // VAT Registration No and Order No as blank.
    end;

    [Test]
    [HandlerFunctions('PurchTaxInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDimensionLoopPurchTaxInvoice()
    var
        PurchTaxInvHeader: Record "Purch. Tax Inv. Header";
    begin
        // [FEATURE] [Purchase] [Tax Invoice]
        // [SCENARIO] Purpose of the test is to validate DimensionLoop1 - OnAfterGetRecord Trigger of Report - 28071 (Purch. - Tax Invoice).

        // Setup: Create Purchase Tax Invoice.
        Initialize();
        CreatePurchaseTaxInvoice(PurchTaxInvHeader);

        // Exercise.
        RunMiscellaneousReport(PurchTaxInvHeader."No.", true, false, REPORT::"Purch. - Tax Invoice");  // Opens PurchTaxInvoiceRequestPageHandler. ShowInternalInformation as True and ShowTHAmountInWords as False.

        // Verify: Verify values of No_PurchTaxInvHdr, AmountLangB1AmountLangB2 and VATRegNo_PurchTaxInvHdr on Report - 28071 (Purch. - Tax Invoice).
        VerifyXMLValuesForMiscellaneousReport(
          NoPurchTaxInvHdrCap, VATRegNoPurchInvHdrCap, AmountLangCap, PurchTaxInvHeader."No.", PurchTaxInvHeader."VAT Registration No.", ' ');  // Amount Lang as blank.
    end;

    [Test]
    [HandlerFunctions('PurchTaxInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchTaxInvLinePurchTaxInvoice()
    var
        PurchTaxInvHeader: Record "Purch. Tax Inv. Header";
    begin
        // [FEATURE] [Purchase] [Tax Invoice]
        // [SCENARIO] Purpose of the test is to validate Purch. Tax Inv. Line - OnAfterGetRecord Trigger of Report - 28071 (Purch. - Tax Invoice).

        // Setup: Create Purchase Tax Invoice.
        Initialize();
        CreatePurchaseTaxInvoice(PurchTaxInvHeader);

        // Exercise.
        RunMiscellaneousReport(PurchTaxInvHeader."No.", false, true, REPORT::"Purch. - Tax Invoice");  // Opens PurchTaxInvoiceRequestPageHandler. ShowInternalInformation as False and ShowTHAmountInWords as True.

        // Verify: Verify values of No_PurchTaxInvHdr, VATRegNo_PurchTaxInvHdr and AmountLangB1AmountLangB2 on Report - 28071 (Purch. - Tax Invoice).
        VerifyXMLValuesForMiscellaneousReport(
          NoPurchTaxInvHdrCap, VATRegNoPurchInvHdrCap, AmountLangCap, PurchTaxInvHeader."No.",
          PurchTaxInvHeader."VAT Registration No.", StrSubstNo(
            AmountLangTxt, GetAmountLangFromPurchaseLine(PurchTaxInvHeader."Amount Including VAT", PurchTaxInvHeader."Currency Code")));
    end;

    [Test]
    [HandlerFunctions('SalesTaxInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesTaxInvHeaderSalesTaxInvoice()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesTaxInvoiceHeader: Record "Sales Tax Invoice Header";
    begin
        // [FEATURE] [Sales] [Tax Invoice]
        // [SCENARIO] Purpose of the test is to validate Sales Tax Inv. Header - OnAfterGetRecord Trigger of Report - 28072 (Sales - Tax Invoice).

        // Setup: Update Sales & Receivables Setup. Create Sales Tax Invoice Header.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Logo Position on Documents"::"No Logo");
        SalesTaxInvoiceHeader.Get(CreateSalesTaxInvHeader());

        // Exercise.
        RunMiscellaneousReport(SalesTaxInvoiceHeader."No.", false, false, REPORT::"Sales - Tax Invoice");  // Opens SalesTaxInvoiceRequestPageHandler. ShowInternalInformation and ShowTHAmountInWords as False.

        // Verify: Verify values of No_SalesTaxInvHdr, YourReference_SalesTaxInvHdr and VATRegNo_SalesTaxInvHdr on Report - 28072 (Sales - Tax Invoice).
        VerifyXMLValuesForMiscellaneousReport(
          NoSalesTaxInvHdrCap, YourReferenceSalesInvCap, VATRegNoSalesInvHdrCap, SalesTaxInvoiceHeader."No.", '', '');  // your Reference and VAT Registration No as blank.
    end;

    [Test]
    [HandlerFunctions('SalesTaxInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesTaxInvLineSalesTaxInvoice()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales] [Tax Invoice]
        // [SCENARIO] Purpose of the test is to validate DimensionLoop1 - OnAfterGetRecord Trigger of Report - 28072 (Sales - Tax Invoice).
        OnAfterGetRecordSalesTaxInvoice(SalesReceivablesSetup."Logo Position on Documents"::Right);
    end;

    [Test]
    [HandlerFunctions('SalesTaxInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATAmountLineSalesTaxInvoice()
    var
        SalesTaxInvoiceHeader: Record "Sales Tax Invoice Header";
        SalesTaxInvoiceLine: Record "Sales Tax Invoice Line";
    begin
        // [FEATURE] [Sales] [Tax Invoice]
        // [SCENARIO 380526] Print VAT Amount Specification part of Report - 28072 (Sales - Tax Invoice).
        Initialize();

        // [GIVEN] Create Sales Tax Invoice with Amount = 100, Amount Including VAT = 120 and VAT Identifier = "V".
        CreateSalesTaxInvoice(SalesTaxInvoiceHeader);
        SalesTaxInvoiceLine.Get(SalesTaxInvoiceHeader."No.", 0);
        SalesTaxInvoiceLine."Amount Including VAT" := LibraryRandom.RandDec(10, 2);
        SalesTaxInvoiceLine."VAT Identifier" := LibraryUTUtility.GetNewCode10();
        SalesTaxInvoiceLine.Modify();

        // [WHEN] Run report Sales - Tax Invoice
        RunMiscellaneousReport(SalesTaxInvoiceHeader."No.", true, true, REPORT::"Sales - Tax Invoice");
        // Opens SalesTaxInvoiceRequestPageHandler. ShowInternalInformation and ShowTHAmountInWords as True.

        // [THEN] Report printed VATAmountLineVATBase = 100, VATAmountLineVATAmount = 20, VAT Identifier = "V".
        VerifyXMLValuesForMiscellaneousReport(
          'VATAmountLineVATBase', 'VATAmountLineVATAmount', 'VATAmountLineVATIdentifier',
          SalesTaxInvoiceLine.Amount, SalesTaxInvoiceLine."Amount Including VAT" - SalesTaxInvoiceLine.Amount,
          SalesTaxInvoiceLine."VAT Identifier");
    end;

    [Test]
    [HandlerFunctions('SalesTaxInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDimLoopSalesTaxInvoice()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales] [Tax Invoice]
        // [SCENARIO] Purpose of the test is to validate DimensionLoop1 - OnAfterGetRecord Trigger of Report - 28072 (Sales - Tax Invoice).
        OnAfterGetRecordSalesTaxInvoice(SalesReceivablesSetup."Logo Position on Documents"::Left);
    end;

    [Test]
    [HandlerFunctions('SalesTaxInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDimLoopLogoCenterSalesTaxInvoice()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales] [Tax Invoice]
        // [SCENARIO] Purpose of the test is to validate DimensionLoop1 - OnAfterGetRecord Trigger of Report - 28072 (Sales - Tax Invoice) with Logo Position on Documents as Center.
        OnAfterGetRecordSalesTaxInvoice(SalesReceivablesSetup."Logo Position on Documents"::Center);
    end;

    local procedure OnAfterGetRecordSalesTaxInvoice(LogoPositionOnDocuments: Option)
    var
        SalesTaxInvoiceHeader: Record "Sales Tax Invoice Header";
    begin
        // Setup: Update Sales & Receivables Setup. Create Sales Tax Invoice.
        Initialize();
        UpdateSalesReceivablesSetup(LogoPositionOnDocuments);
        CreateSalesTaxInvoice(SalesTaxInvoiceHeader);

        // Exercise.
        RunMiscellaneousReport(SalesTaxInvoiceHeader."No.", true, true, REPORT::"Sales - Tax Invoice");  // Opens SalesTaxInvoiceRequestPageHandler. ShowInternalInformation and ShowTHAmountInWords as True.

        // Verify: Verify values of No_SalesTaxInvHdr, AmountLangB1AmountLangB2 and VATRegNo_SalesTaxInvHdr on Report - 28072 (Sales - Tax Invoice).
        VerifyXMLValuesForMiscellaneousReport(
          NoSalesTaxInvHdrCap, VATRegNoSalesInvHdrCap, AmountLangCap, SalesTaxInvoiceHeader."No.",
          SalesTaxInvoiceHeader."VAT Registration No.", StrSubstNo(AmountLangTxt,
            GetAmountLangFromPurchaseLine(SalesTaxInvoiceHeader."Amount Including VAT", SalesTaxInvoiceHeader."Currency Code")));
    end;

    [Test]
    [HandlerFunctions('PurchTaxCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchTaxCrMemoHeaderPurchTaxCrMemo()
    var
        PurchTaxCrMemoHdr: Record "Purch. Tax Cr. Memo Hdr.";
    begin
        // [FEATURE] [Purchase] [Tax Credit Memo]
        // [SCENARIO] Purpose of the test is to validate Purch. - Tax Cr. Memo Header - OnAfterGetRecord Trigger of Report - 28073 (Purch. - Tax Cr. Memo).

        // Setup: Create Purchase Credit Memo.
        Initialize();
        PurchTaxCrMemoHdr.Get(CreatePurchTaxCrMemoHeader());

        // Exercise.
        RunMiscellaneousReport(PurchTaxCrMemoHdr."No.", true, false, REPORT::"Purch. - Tax Cr. Memo");  // Opens PurchTaxCrMemoRequestPageHandler. ShowInternalInformation as True and ShowTHAmountInWords as False.

        // Verify: Verify values of No_PurchTaxCrMemoHdr, BuyfromVendNo_PurchTaxCrMemoHdr and YourRef_PurchTaxCrMemoHdr on Report - 28073 (Purch. - Tax Cr. Memo).
        VerifyXMLValuesForMiscellaneousReport(
          NoPurchTaxCrMemoCap, BuyfromVendNoCap, YourRefPurchCrMemoCap, PurchTaxCrMemoHdr."No.", PurchTaxCrMemoHdr."Buy-from Vendor No.", '');  // Your Reference as blank.
    end;

    [Test]
    [HandlerFunctions('PurchTaxCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDimLoopPurchTaxCrMemo()
    var
        PurchTaxCrMemoHdr: Record "Purch. Tax Cr. Memo Hdr.";
    begin
        // [FEATURE] [Purchase] [Tax Credit Memo]
        // [SCENARIO] Purpose of the test is to validate DimensionLoop1 - OnAfterGetRecord  Trigger of Report - 28073 (Purch. - Tax Cr. Memo).

        // Setup: Create Purchase Tax Credit Memo.
        Initialize();
        CreatePurchaseTaxCreditMemo(PurchTaxCrMemoHdr);

        // Exercise.
        RunMiscellaneousReport(PurchTaxCrMemoHdr."No.", true, false, REPORT::"Purch. - Tax Cr. Memo");  // Opens PurchTaxCrMemoRequestPageHandler. ShowInternalInformation as True and ShowTHAmountInWords as False.

        // Verify: Verify values of No_PurchTaxCrMemoHdr, AmountLangB1AmountLangB2 and VATRegNo_PurchTaxCrMemoHdr on Report - 28073 (Purch. - Tax Cr. Memo).
        VerifyXMLValuesForMiscellaneousReport(
          NoPurchTaxCrMemoCap, VATRegNoPurchCrMemoCap, AmountLangCap, PurchTaxCrMemoHdr."No.", PurchTaxCrMemoHdr."VAT Registration No.", ' ');  // Amount Lang as blank.
    end;

    [Test]
    [HandlerFunctions('PurchTaxCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchTaxCrMemoLinePurchTaxCrMemo()
    var
        PurchTaxCrMemoHdr: Record "Purch. Tax Cr. Memo Hdr.";
    begin
        // [FEATURE] [Purchase] [Tax Credit Memo]
        // [SCENARIO] Purpose of the test is to validate Purch. - Tax Cr. Memo Line - OnAfterGetRecord Trigger of Report - 28073 (Purch. - Tax Cr. Memo).

        // Setup: Create Purchase Tax Credit Memo.
        Initialize();
        CreatePurchaseTaxCreditMemo(PurchTaxCrMemoHdr);

        // Exercise.
        RunMiscellaneousReport(PurchTaxCrMemoHdr."No.", false, true, REPORT::"Purch. - Tax Cr. Memo");  // Opens PurchTaxCrMemoRequestPageHandler. ShowInternalInformation as False and ShowTHAmountInWords as True.

        // Verify: Verify values of No_PurchTaxCrMemoHdr, AmountLangB1AmountLangB2 and VATRegNo_PurchTaxCrMemoHdr on Report - 28073 (Purch. - Tax Cr. Memo).
        VerifyXMLValuesForMiscellaneousReport(
          NoPurchTaxCrMemoCap, VATRegNoPurchCrMemoCap, AmountLangCap, PurchTaxCrMemoHdr."No.",
          PurchTaxCrMemoHdr."VAT Registration No.", StrSubstNo(
            AmountLangTxt, GetAmountLangFromPurchaseLine(PurchTaxCrMemoHdr."Amount Including VAT", PurchTaxCrMemoHdr."Currency Code")));
    end;

    [Test]
    [HandlerFunctions('SalesTaxCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesTaxCrMemoHeaderSalesTaxCrMemo()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesTaxCrMemoHeader: Record "Sales Tax Cr.Memo Header";
    begin
        // [FEATURE] [Sales] [Tax Credit Memo]
        // [SCENARIO] Purpose of the test is to validate Sales - Tax Cr. Memo Header - OnAfterGetRecord Trigger of Report - 28074 (Sales - Tax Cr. Memo).

        // Setup: Update Sales & Receivables Setup. Create Sales Tax Cr. Memo Header.
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Logo Position on Documents"::"No Logo");
        SalesTaxCrMemoHeader.Get(CreateSalesTaxCrMemoHeader());

        // Exercise.
        RunMiscellaneousReport(SalesTaxCrMemoHeader."No.", false, false, REPORT::"Sales - Tax Cr. Memo");  // Opens SalesTaxCrMemoRequestPageHandler. ShowInternalInformation and ShowTHAmountInWords as False.

        // Verify: Verify values of No_SalesTaxCrMemoHeader, VATRegNo_SalesTaxCrMemoHeader and ReturnOrderNo_SalesTaxCrMemoHeader on Report - 28074 (Sales - Tax Cr. Memo).
        VerifyXMLValuesForMiscellaneousReport(
          NoSalesCrMemoCap, VATRegNoSalesCrMemoCap, ReturnOrderNoCap, SalesTaxCrMemoHeader."No.", '', '');  // VAT Registration No and Return Order No as blank.
    end;

    [Test]
    [HandlerFunctions('SalesTaxCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDimLoopSalesTaxCrMemo()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales] [Tax Credit Memo]
        // [SCENARIO] Purpose of the test is to validate DimensionLoop1 - OnAfterGetRecord Trigger of Report - 28074 (Sales - Tax Cr. Memo) with Logo Position on Documents as Right.
        OnAfterGetRecordSalesTaxCrMemoHeader(SalesReceivablesSetup."Logo Position on Documents"::Right);
    end;

    [Test]
    [HandlerFunctions('SalesTaxCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesTaxCrMemoLineSalesTaxCrMemo()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales] [Tax Credit Memo]
        // [SCENARIO] Purpose of the test is to validate Sales - Tax Cr. Memo Line - OnAfterGetRecord Trigger of Report - 28074 (Sales - Tax Cr. Memo) with Logo Position on Documents as Center.
        OnAfterGetRecordSalesTaxCrMemoHeader(SalesReceivablesSetup."Logo Position on Documents"::Center);
    end;

    [Test]
    [HandlerFunctions('SalesTaxCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemDimLoopSalesTaxCrMemo()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales] [Tax Credit Memo]
        // [SCENARIO] Purpose of the test is to validate Dimension Loop1 - OnPreDataItem Trigger of Report - 28074 (Sales - Tax Cr. Memo) with ShowTHAmountInWords as True and Logo Position on Documents as Left.
        OnAfterGetRecordSalesTaxCrMemoHeader(SalesReceivablesSetup."Logo Position on Documents"::Left);
    end;

    local procedure OnAfterGetRecordSalesTaxCrMemoHeader(LogoPositionOnDocuments: Option)
    var
        SalesTaxCrMemoHeader: Record "Sales Tax Cr.Memo Header";
    begin
        // Setup: Update Sales & Receivables Setup. Create Sales Tax Credit Memo.
        Initialize();
        UpdateSalesReceivablesSetup(LogoPositionOnDocuments);
        CreateSalesTaxCreditMemo(SalesTaxCrMemoHeader);

        // Exercise.
        RunMiscellaneousReport(SalesTaxCrMemoHeader."No.", true, true, REPORT::"Sales - Tax Cr. Memo");  // Opens SalesTaxCrMemoRequestPageHandler. ShowInternalInformation and ShowTHAmountInWords as True.

        // Verify: Verify values of No_SalesTaxCrMemoHeader, VATRegNo_SalesTaxCrMemoHeader and AmountLangB1AmountLangB2 on Report - 28074 (Sales - Tax Cr. Memo).
        VerifyXMLValuesForMiscellaneousReport(
          AppliedToTextCap, VATRegNoSalesCrMemoCap, AmountLangCap, StrSubstNo(AppliesTxt, SalesTaxCrMemoHeader."Applies-to Doc. Type",
            SalesTaxCrMemoHeader."Applies-to Doc. No."), SalesTaxCrMemoHeader."VAT Registration No.", StrSubstNo(AmountLangTxt,
            GetAmountLangFromSalesLine(SalesTaxCrMemoHeader."Amount Including VAT", SalesTaxCrMemoHeader."Currency Code")));
    end;

    [Test]
    procedure TransferFieldsFromSalesInvHeaderToSalesTaxInvHeader()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesTaxInvoiceHeader: Record "Sales Tax Invoice Header";
        SourceRecRef: RecordRef;
    begin
        // [FEATURE] [UT] [Sales]
        CreateRecWithFullTexts(SalesInvoiceHeader, SourceRecRef);
        SalesTaxInvoiceHeader.TransferFields(SalesInvoiceHeader);
        VerifyFullTexts(SalesTaxInvoiceHeader, SourceRecRef);
    end;

    [Test]
    procedure TransferFieldsFromSalesInvLineToSalesTaxInvLine()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesTaxInvoiceLine: Record "Sales Tax Invoice Line";
        SourceRecRef: RecordRef;
    begin
        // [FEATURE] [UT] [Sales]
        CreateRecWithFullTexts(SalesInvoiceLine, SourceRecRef);
        SalesTaxInvoiceLine.TransferFieldsFrom(SalesInvoiceLine);
        VerifyFullTexts(SalesTaxInvoiceLine, SourceRecRef);
    end;

    [Test]
    procedure TransferFieldsFromSalesCrMemoHeaderToSalesTaxInvHeader()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesTaxInvoiceHeader: Record "Sales Tax Invoice Header";
        SourceRecRef: RecordRef;
    begin
        // [FEATURE] [UT] [Sales]
        CreateRecWithFullTexts(SalesCrMemoHeader, SourceRecRef);
        SalesTaxInvoiceHeader.TransferFields(SalesCrMemoHeader);
        VerifyFullTexts(SalesTaxInvoiceHeader, SourceRecRef);
    end;

    [Test]
    procedure TransferFieldsFromSalesCrMemoLineToSalesTaxInvLine()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesTaxInvoiceLine: Record "Sales Tax Invoice Line";
        SourceRecRef: RecordRef;
    begin
        // [FEATURE] [UT] [Sales]
        CreateRecWithFullTexts(SalesCrMemoLine, SourceRecRef);
        SalesTaxInvoiceLine.TransferFieldsFrom(SalesCrMemoLine);
        VerifyFullTexts(SalesTaxInvoiceLine, SourceRecRef);
    end;

    [Test]
    procedure TransferFieldsFromSalesCrMemoHeaderToSalesTaxCrMemoHeader()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesTaxCrMemoHeader: Record "Sales Tax Cr.Memo Header";
        SourceRecRef: RecordRef;
    begin
        // [FEATURE] [UT] [Sales]
        CreateRecWithFullTexts(SalesCrMemoHeader, SourceRecRef);
        SalesTaxCrMemoHeader.TransferFieldsFrom(SalesCrMemoHeader);
        VerifyFullTexts(SalesTaxCrMemoHeader, SourceRecRef);
    end;

    [Test]
    procedure TransferFieldsFromSalesCrMemoLineToSalesTaxCrMemoLine()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesTaxCrMemoLine: Record "Sales Tax Cr.Memo Line";
        SourceRecRef: RecordRef;
    begin
        // [FEATURE] [UT] [Sales]
        CreateRecWithFullTexts(SalesCrMemoLine, SourceRecRef);
        SalesTaxCrMemoLine.TransferFieldsFrom(SalesCrMemoLine);
        VerifyFullTexts(SalesTaxCrMemoLine, SourceRecRef);
    end;

    [Test]
    procedure TransferFieldsFromPurchInvHeaderToPurchTaxInvHeader()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchTaxInvHeader: Record "Purch. Tax Inv. Header";
        SourceRecRef: RecordRef;
    begin
        // [FEATURE] [UT] [Purchase]
        CreateRecWithFullTexts(PurchInvHeader, SourceRecRef);
        PurchTaxInvHeader.TransferFieldsFrom(PurchInvHeader);
        VerifyFullTexts(PurchTaxInvHeader, SourceRecRef);
    end;

    [Test]
    procedure TransferFieldsFromPurchInvLineToPurchTaxInvLine()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchTaxInvLine: Record "Purch. Tax Inv. Line";
        SourceRecRef: RecordRef;
    begin
        // [FEATURE] [UT] [Purchase]
        CreateRecWithFullTexts(PurchInvLine, SourceRecRef);
        PurchTaxInvLine.TransferFieldsFrom(PurchInvLine);
        VerifyFullTexts(PurchTaxInvLine, SourceRecRef);
    end;

    [Test]
    procedure TransferFieldsFromPurchCrMemoHeaderToPurchTaxInvHeader()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchTaxInvHeader: Record "Purch. Tax Inv. Header";
        SourceRecRef: RecordRef;
    begin
        // [FEATURE] [UT] [Purchase]
        CreateRecWithFullTexts(PurchCrMemoHdr, SourceRecRef);
        PurchTaxInvHeader.TransferFields(PurchCrMemoHdr);
        VerifyFullTexts(PurchTaxInvHeader, SourceRecRef);
    end;

    [Test]
    procedure TransferFieldsFromPurchCrMemoLineToPurchTaxInvLine()
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchTaxInvLine: Record "Purch. Tax Inv. Line";
        SourceRecRef: RecordRef;
    begin
        // [FEATURE] [UT] [Purchase]
        CreateRecWithFullTexts(PurchCrMemoLine, SourceRecRef);
        PurchTaxInvLine.TransferFieldsFrom(PurchCrMemoLine);
        VerifyFullTexts(PurchTaxInvLine, SourceRecRef);
    end;

    [Test]
    procedure TransferFieldsFromPurchCrMemoHeaderToPurchTaxCrMemoHeader()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchTaxCrMemoHdr: Record "Purch. Tax Cr. Memo Hdr.";
        SourceRecRef: RecordRef;
    begin
        // [FEATURE] [UT] [Purchase]
        CreateRecWithFullTexts(PurchCrMemoHdr, SourceRecRef);
        PurchTaxCrMemoHdr.TransferFieldsFrom(PurchCrMemoHdr);
        VerifyFullTexts(PurchTaxCrMemoHdr, SourceRecRef);
    end;

    [Test]
    procedure TransferFieldsFromPurchCrMemoLineToPurchTaxCrMemoLine()
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchTaxCrMemoLine: Record "Purch. Tax Cr. Memo Line";
        SourceRecRef: RecordRef;
    begin
        // [FEATURE] [UT] [Purchase]
        CreateRecWithFullTexts(PurchCrMemoLine, SourceRecRef);
        PurchTaxCrMemoLine.TransferFieldsFrom(PurchCrMemoLine);
        VerifyFullTexts(PurchTaxCrMemoLine, SourceRecRef);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndUpdatePurchTaxCrMemoHeader(): Code[20]
    var
        PurchTaxCrMemoHdr: Record "Purch. Tax Cr. Memo Hdr.";
    begin
        PurchTaxCrMemoHdr.Get(CreatePurchTaxCrMemoHeader());
        PurchTaxCrMemoHdr."Responsibility Center" := CreateResponsibilityCenter();
        PurchTaxCrMemoHdr."Purchaser Code" := CreateSalesPersonPurchaser();
        PurchTaxCrMemoHdr."Your Reference" := LibraryUTUtility.GetNewCode();
        PurchTaxCrMemoHdr."Currency Code" := CreateCurrency();
        PurchTaxCrMemoHdr."Return Order No." := LibraryUTUtility.GetNewCode();
        PurchTaxCrMemoHdr."Dimension Set ID" := CreateDimensionSetEntry();
        PurchTaxCrMemoHdr."VAT Registration No." := LibraryUTUtility.GetNewCode();
        PurchTaxCrMemoHdr."Payment Terms Code" := CreatePaymentTerms();
        PurchTaxCrMemoHdr."Shipment Method Code" := CreateShipmentMethod();
        PurchTaxCrMemoHdr."Currency Factor" := LibraryRandom.RandDec(10, 2);
        PurchTaxCrMemoHdr.Modify();
        exit(PurchTaxCrMemoHdr."No.");
    end;

    local procedure CreateAndUpdatePurchTaxInvHeader(): Code[20]
    var
        PurchTaxInvHeader: Record "Purch. Tax Inv. Header";
    begin
        PurchTaxInvHeader.Get(CreatePurchTaxInvHeader());
        PurchTaxInvHeader."Order No." := LibraryUTUtility.GetNewCode();
        PurchTaxInvHeader."Responsibility Center" := CreateResponsibilityCenter();
        PurchTaxInvHeader."Purchaser Code" := CreateSalesPersonPurchaser();
        PurchTaxInvHeader."Your Reference" := LibraryUTUtility.GetNewCode();
        PurchTaxInvHeader."Currency Code" := CreateCurrency();
        PurchTaxInvHeader."Dimension Set ID" := CreateDimensionSetEntry();
        PurchTaxInvHeader."VAT Registration No." := LibraryUTUtility.GetNewCode();
        PurchTaxInvHeader."Payment Terms Code" := CreatePaymentTerms();
        PurchTaxInvHeader."Shipment Method Code" := CreateShipmentMethod();
        PurchTaxInvHeader."Currency Factor" := LibraryRandom.RandDec(10, 2);
        PurchTaxInvHeader.Modify();
        exit(PurchTaxInvHeader."No.");
    end;

    local procedure CreateAndUpdateSalesTaxCrMemoHeader(): Code[20]
    var
        SalesTaxCrMemoHeader: Record "Sales Tax Cr.Memo Header";
    begin
        SalesTaxCrMemoHeader.Get(CreateSalesTaxCrMemoHeader());
        SalesTaxCrMemoHeader."Return Order No." := LibraryUTUtility.GetNewCode();
        SalesTaxCrMemoHeader."Responsibility Center" := CreateResponsibilityCenter();
        SalesTaxCrMemoHeader."Your Reference" := LibraryUTUtility.GetNewCode();
        SalesTaxCrMemoHeader."Currency Code" := CreateCurrency();
        SalesTaxCrMemoHeader."Salesperson Code" := CreateSalesPersonPurchaser();
        SalesTaxCrMemoHeader."Applies-to Doc. Type" := SalesTaxCrMemoHeader."Applies-to Doc. Type"::Invoice;
        SalesTaxCrMemoHeader."Applies-to Doc. No." := LibraryUTUtility.GetNewCode();
        SalesTaxCrMemoHeader."Dimension Set ID" := CreateDimensionSetEntry();
        SalesTaxCrMemoHeader."VAT Registration No." := LibraryUTUtility.GetNewCode();
        SalesTaxCrMemoHeader."Payment Terms Code" := CreatePaymentTerms();
        SalesTaxCrMemoHeader."Shipment Method Code" := CreateShipmentMethod();
        SalesTaxCrMemoHeader."Currency Factor" := LibraryRandom.RandDec(10, 2);
        SalesTaxCrMemoHeader.Modify();
        exit(SalesTaxCrMemoHeader."No.");
    end;

    local procedure CreateAndUpdateSalesTaxInvHeader(): Code[20]
    var
        SalesTaxInvoiceHeader: Record "Sales Tax Invoice Header";
    begin
        SalesTaxInvoiceHeader.Get(CreateSalesTaxInvHeader());
        SalesTaxInvoiceHeader."Order No." := LibraryUTUtility.GetNewCode();
        SalesTaxInvoiceHeader."Responsibility Center" := CreateResponsibilityCenter();
        SalesTaxInvoiceHeader."Your Reference" := LibraryUTUtility.GetNewCode();
        SalesTaxInvoiceHeader."Currency Code" := CreateCurrency();
        SalesTaxInvoiceHeader."Salesperson Code" := CreateSalesPersonPurchaser();
        SalesTaxInvoiceHeader."Dimension Set ID" := CreateDimensionSetEntry();
        SalesTaxInvoiceHeader."VAT Registration No." := LibraryUTUtility.GetNewCode();
        SalesTaxInvoiceHeader."Payment Terms Code" := CreatePaymentTerms();
        SalesTaxInvoiceHeader."Shipment Method Code" := CreateShipmentMethod();
        SalesTaxInvoiceHeader."Currency Factor" := LibraryRandom.RandDec(10, 2);
        SalesTaxInvoiceHeader.Modify();
        exit(SalesTaxInvoiceHeader."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();
        CreateCurrencyExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate."Currency Code" := CurrencyCode;
        CurrencyExchangeRate."Relational Exch. Rate Amount" := LibraryRandom.RandDec(10, 2);
        CurrencyExchangeRate."Exchange Rate Amount" := LibraryRandom.RandDec(10, 2);
        CurrencyExchangeRate.Insert();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateDimensionSetEntry(): Integer
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry."Dimension Set ID" := LibraryRandom.RandInt(10);
        DimensionSetEntry."Dimension Code" := LibraryUTUtility.GetNewCode();
        DimensionSetEntry.Insert();
        exit(DimensionSetEntry."Dimension Set ID");
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Code := LibraryUTUtility.GetNewCode10();
        PaymentTerms.Insert();
        exit(PaymentTerms.Code);
    end;

    local procedure CreatePurchaseTaxCreditMemo(var PurchTaxCrMemoHdr: Record "Purch. Tax Cr. Memo Hdr.")
    var
        PurchTaxCrMemoLine: Record "Purch. Tax Cr. Memo Line";
    begin
        PurchTaxCrMemoHdr.Get(CreateAndUpdatePurchTaxCrMemoHeader());
        PurchTaxCrMemoLine."Document No." := PurchTaxCrMemoHdr."No.";
        PurchTaxCrMemoLine.Quantity := LibraryRandom.RandDec(10, 2);
        PurchTaxCrMemoLine.Type := PurchTaxCrMemoLine.Type::"G/L Account";
        PurchTaxCrMemoLine."Dimension Set ID" := PurchTaxCrMemoHdr."Dimension Set ID";
        PurchTaxCrMemoLine.Amount := LibraryRandom.RandDec(10, 2);
        PurchTaxCrMemoLine.Insert();
    end;

    local procedure CreatePurchTaxCrMemoHeader(): Code[20]
    var
        PurchTaxCrMemoHdr: Record "Purch. Tax Cr. Memo Hdr.";
    begin
        PurchTaxCrMemoHdr."No." := LibraryUTUtility.GetNewCode();
        PurchTaxCrMemoHdr."Buy-from Vendor No." := CreateVendor();
        PurchTaxCrMemoHdr."No. Printed" := LibraryRandom.RandInt(10);
        PurchTaxCrMemoHdr.Insert();
        exit(PurchTaxCrMemoHdr."No.");
    end;

    local procedure CreatePurchTaxInvHeader(): Code[20]
    var
        PurchTaxInvHeader: Record "Purch. Tax Inv. Header";
    begin
        PurchTaxInvHeader."No." := LibraryUTUtility.GetNewCode();
        PurchTaxInvHeader.Insert();
        exit(PurchTaxInvHeader."No.");
    end;

    local procedure CreatePurchaseTaxInvoice(var PurchTaxInvHeader: Record "Purch. Tax Inv. Header")
    var
        PurchTaxInvLine: Record "Purch. Tax Inv. Line";
    begin
        PurchTaxInvHeader.Get(CreateAndUpdatePurchTaxInvHeader());
        PurchTaxInvLine."Document No." := PurchTaxInvHeader."No.";
        PurchTaxInvLine.Quantity := LibraryRandom.RandDec(10, 2);
        PurchTaxInvLine.Type := PurchTaxInvLine.Type::"G/L Account";
        PurchTaxInvLine."Dimension Set ID" := PurchTaxInvHeader."Dimension Set ID";
        PurchTaxInvLine.Amount := LibraryRandom.RandDec(10, 2);
        PurchTaxInvLine.Insert();
    end;

    local procedure CreateSalesTaxCreditMemo(var SalesTaxCrMemoHeader: Record "Sales Tax Cr.Memo Header")
    var
        SalesTaxCrMemoLine: Record "Sales Tax Cr.Memo Line";
    begin
        SalesTaxCrMemoHeader.Get(CreateAndUpdateSalesTaxCrMemoHeader());
        SalesTaxCrMemoLine."Document No." := SalesTaxCrMemoHeader."No.";
        SalesTaxCrMemoLine.Quantity := LibraryRandom.RandDec(10, 2);
        SalesTaxCrMemoLine."Document No." := SalesTaxCrMemoHeader."No.";
        SalesTaxCrMemoLine."Dimension Set ID" := SalesTaxCrMemoHeader."Dimension Set ID";
        SalesTaxCrMemoLine.Amount := LibraryRandom.RandDec(10, 2);
        SalesTaxCrMemoLine.Insert();
    end;

    local procedure CreateSalesTaxCrMemoHeader(): Code[20]
    var
        SalesTaxCrMemoHeader: Record "Sales Tax Cr.Memo Header";
    begin
        SalesTaxCrMemoHeader."No." := LibraryUTUtility.GetNewCode();
        SalesTaxCrMemoHeader."Bill-to Customer No." := CreateCustomer();
        SalesTaxCrMemoHeader.Insert();
        exit(SalesTaxCrMemoHeader."No.");
    end;

    local procedure CreateSalesTaxInvoice(var SalesTaxInvoiceHeader: Record "Sales Tax Invoice Header")
    var
        SalesTaxInvoiceLine: Record "Sales Tax Invoice Line";
    begin
        SalesTaxInvoiceHeader.Get(CreateAndUpdateSalesTaxInvHeader());
        SalesTaxInvoiceLine."Document No." := SalesTaxInvoiceHeader."No.";
        SalesTaxInvoiceLine.Quantity := LibraryRandom.RandDec(10, 2);
        SalesTaxInvoiceLine."Document No." := SalesTaxInvoiceHeader."No.";
        SalesTaxInvoiceLine."Dimension Set ID" := SalesTaxInvoiceHeader."Dimension Set ID";
        SalesTaxInvoiceLine.Amount := LibraryRandom.RandDec(10, 2);
        SalesTaxInvoiceLine.Insert();
    end;

    local procedure CreateSalesTaxInvHeader(): Code[20]
    var
        SalesTaxInvoiceHeader: Record "Sales Tax Invoice Header";
    begin
        SalesTaxInvoiceHeader."No." := LibraryUTUtility.GetNewCode();
        SalesTaxInvoiceHeader."Bill-to Customer No." := CreateCustomer();
        SalesTaxInvoiceHeader.Insert();
        exit(SalesTaxInvoiceHeader."No.");
    end;

    local procedure CreateResponsibilityCenter(): Code[10]
    var
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        ResponsibilityCenter.Code := LibraryUTUtility.GetNewCode10();
        ResponsibilityCenter.Insert();
        exit(ResponsibilityCenter.Code);
    end;

    local procedure CreateSalesPersonPurchaser(): Code[10]
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        SalespersonPurchaser.Code := LibraryUTUtility.GetNewCode10();
        SalespersonPurchaser.Insert();
        exit(SalespersonPurchaser.Code);
    end;

    local procedure CreateShipmentMethod(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.Code := LibraryUTUtility.GetNewCode10();
        ShipmentMethod.Insert();
        exit(ShipmentMethod.Code);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateRecWithFullTexts(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var RecRef: RecordRef)
    begin
        RecRef.Open(Database::"Purch. Cr. Memo Hdr.");
        FillRecWithFullTexts(RecRef);
        RecRef.SetTable(PurchCrMemoHdr);
    end;

    local procedure CreateRecWithFullTexts(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var RecRef: RecordRef)
    begin
        RecRef.Open(Database::"Purch. Cr. Memo Line");
        FillRecWithFullTexts(RecRef);
        RecRef.SetTable(PurchCrMemoLine);
    end;

    local procedure CreateRecWithFullTexts(var PurchInvHeader: Record "Purch. Inv. Header"; var RecRef: RecordRef)
    begin
        RecRef.Open(Database::"Purch. Inv. Header");
        FillRecWithFullTexts(RecRef);
        RecRef.SetTable(PurchInvHeader);
    end;

    local procedure CreateRecWithFullTexts(var PurchInvLine: Record "Purch. Inv. Line"; var RecRef: RecordRef)
    begin
        RecRef.Open(Database::"Purch. Inv. Line");
        FillRecWithFullTexts(RecRef);
        RecRef.SetTable(PurchInvLine);
    end;

    local procedure CreateRecWithFullTexts(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var RecRef: RecordRef)
    begin
        RecRef.Open(Database::"Sales Cr.Memo Header");
        FillRecWithFullTexts(RecRef);
        RecRef.SetTable(SalesCrMemoHeader);
    end;

    local procedure CreateRecWithFullTexts(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var RecRef: RecordRef)
    begin
        RecRef.Open(Database::"Sales Cr.Memo Line");
        FillRecWithFullTexts(RecRef);
        RecRef.SetTable(SalesCrMemoLine);
    end;

    local procedure CreateRecWithFullTexts(var SalesInvoiceHeader: Record "Sales Invoice Header"; var RecRef: RecordRef)
    begin
        RecRef.Open(Database::"Sales Invoice Header");
        FillRecWithFullTexts(RecRef);
        RecRef.SetTable(SalesInvoiceHeader);
    end;

    local procedure CreateRecWithFullTexts(var SalesInvoiceLine: Record "Sales Invoice Line"; var RecRef: RecordRef)
    begin
        RecRef.Open(Database::"Sales Invoice Line");
        FillRecWithFullTexts(RecRef);
        RecRef.SetTable(SalesInvoiceLine);
    end;

    local procedure EnqueueValueForMiscellaneousHandler(No: Code[20]; ShowInternalInformation: Boolean; ShowTHAmountInWords: Boolean)
    begin
        LibraryVariableStorage.Enqueue(No);
        LibraryVariableStorage.Enqueue(ShowInternalInformation);
        LibraryVariableStorage.Enqueue(ShowTHAmountInWords);
    end;

    local procedure FillRecWithFullTexts(var RecRef: RecordRef)
    var
        FldRef: FieldRef;
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            if (FldRef.Class = FldRef.Class::Normal) and (FldRef.Type in [FieldType::Code, FieldType::Text]) then
                FldRef.Value := GetTextOfLength(FldRef.Length);
        end;
    end;

    local procedure GetTextOfLength(Len: Integer) Result: Text;
    begin
        Result := LibraryUTUtility.GetNewCode();
        while StrLen(Result) < Len do
            Result += Result;
        Result := CopyStr(Result, StrLen(Result) - Len + 1, Len);
    end;

    local procedure VerifyFullTexts(Rec: Variant; SourceRecRef: RecordRef)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        i: Integer;
    begin
        RecRef.GetTable(Rec);
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            if SourceRecRef.FieldExist(FldRef.Number) then
                if (FldRef.Class = FldRef.Class::Normal) and (FldRef.Type in [FieldType::Code, FieldType::Text]) then
                    Assert.AreEqual(FldRef.Length(), StrLen(FldRef.Value()), FldRef.Name());
        end;
        SourceRecRef.Close();
    end;

    local procedure GetAmountLangFromPurchaseLine(AmountIncludingVAT: Decimal; CurrencyCode: Code[10]): Text[80]
    var
        PurchaseLine: Record "Purchase Line";
        AmountLangB: array[2] of Text[80];
    begin
        PurchaseLine.InitTextVariableTH();
        PurchaseLine.FormatNoTextTH(AmountLangB, AmountIncludingVAT, CurrencyCode);
        exit(AmountLangB[1]);
    end;

    local procedure GetAmountLangFromSalesLine(AmountIncludingVAT: Decimal; CurrencyCode: Code[10]): Text[80]
    var
        SalesLine: Record "Sales Line";
        AmountLangB: array[2] of Text[80];
    begin
        SalesLine.InitTextVariableTH();
        SalesLine.FormatNoTextTH(AmountLangB, AmountIncludingVAT, CurrencyCode);
        exit(AmountLangB[1]);
    end;

    local procedure RunMiscellaneousReport(DocumentNo: Code[20]; ShowInternalInformation: Boolean; ShowTHAmountInWords: Boolean; ReportID: Integer)
    begin
        // Enqueue require for Miscellaneous Handler.
        EnqueueValueForMiscellaneousHandler(DocumentNo, ShowInternalInformation, ShowTHAmountInWords);  // ShowInternalInformation as True and ShowTHAmountInWords as False.
        Commit();  // Commit required as it is called explicitly from OnRun Trigger of Codeunit 28071, Codeunit 28072,Codeunit 28073 and Codeunit 28074.
        REPORT.Run(ReportID);
    end;

    local procedure UpdateSalesReceivablesSetup(LogoPositionOnDocuments: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Logo Position on Documents" := LogoPositionOnDocuments;
        SalesReceivablesSetup.Modify();
    end;

    local procedure VerifyXMLValuesForMiscellaneousReport(Caption: Text; Caption2: Text; Caption3: Text; Value: Variant; Value2: Variant; Value3: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption, Value);
        LibraryReportDataset.AssertElementWithValueExists(Caption2, Value2);
        LibraryReportDataset.AssertElementWithValueExists(Caption3, Value3);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchTaxCrMemoRequestPageHandler(var PurchTaxCrMemo: TestRequestPage "Purch. - Tax Cr. Memo")
    var
        No: Variant;
        ShowInternalInformation: Variant;
        ShowTHAmountInWords: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(ShowInternalInformation);
        LibraryVariableStorage.Dequeue(ShowTHAmountInWords);
        PurchTaxCrMemo."Purch. Tax Cr. Memo Hdr.".SetFilter("No.", No);
        PurchTaxCrMemo.ShowInternalInformation.SetValue(ShowInternalInformation);
        PurchTaxCrMemo.ShowTHAmountInWords.SetValue(ShowTHAmountInWords);
        PurchTaxCrMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchTaxInvoiceRequestPageHandler(var PurchTaxInvoice: TestRequestPage "Purch. - Tax Invoice")
    var
        No: Variant;
        ShowInternalInformation: Variant;
        ShowTHAmountInWords: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(ShowInternalInformation);
        LibraryVariableStorage.Dequeue(ShowTHAmountInWords);
        PurchTaxInvoice."Purch. Tax Inv. Header".SetFilter("No.", No);
        PurchTaxInvoice.ShowInternalInformation.SetValue(ShowInternalInformation);
        PurchTaxInvoice.ShowTHAmountInWords.SetValue(ShowTHAmountInWords);
        PurchTaxInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesTaxCrMemoRequestPageHandler(var SalesTaxCrMemo: TestRequestPage "Sales - Tax Cr. Memo")
    var
        No: Variant;
        ShowInternalInformation: Variant;
        ShowTHAmountInWords: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(ShowInternalInformation);
        LibraryVariableStorage.Dequeue(ShowTHAmountInWords);
        SalesTaxCrMemo."Sales Tax Cr.Memo Header".SetFilter("No.", No);
        SalesTaxCrMemo.ShowInternalInformation.SetValue(ShowInternalInformation);
        SalesTaxCrMemo.ShowTHAmountInWords.SetValue(ShowTHAmountInWords);
        SalesTaxCrMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesTaxInvoiceRequestPageHandler(var SalesTaxInvoice: TestRequestPage "Sales - Tax Invoice")
    var
        No: Variant;
        ShowInternalInformation: Variant;
        ShowTHAmountInWords: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(ShowInternalInformation);
        LibraryVariableStorage.Dequeue(ShowTHAmountInWords);
        SalesTaxInvoice."Sales Tax Invoice Header".SetFilter("No.", No);
        SalesTaxInvoice.ShowInternalInformation.SetValue(ShowInternalInformation);
        SalesTaxInvoice.ShowTHAmountInWords.SetValue(ShowTHAmountInWords);
        SalesTaxInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

