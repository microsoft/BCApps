codeunit 144718 "ERM Corr. Factura Test"
{
    // // [FEATURE] [Report] [Factura]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRandom: Codeunit "Library - Random";
        LibraryRUReports: Codeunit "Library RU Reports";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        ChangeCurrencyQst: Label 'If you change %1, the existing sales lines will be deleted and new sales lines based on the new information on the header will be created.';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrintCorrFacturaInvoice()
    var
        SalesHeader: Record "Sales Header";
        CorrSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NoSeries: Codeunit "No. Series";
        DocNo: Code[20];
        ExpectedPostingNo: Code[20];
        QtyBefore: Decimal;
        QtyAfter: Decimal;
        UoMCode: Code[10];
        UoMOKEICode: Code[3];
    begin
        // [SCENARIO] Export REP 14966 "Sales Corr. Factura-Invoice" for open corrective sales invoice
        Initialize();

        // [GIVEN] Company address with "Post Code" = "A", County = "B", City = "C", "Address" = "D", "Address 2" = "E"
        // [GIVEN] Corrective sales invoice for customer with "Post Code" = "F", County = "G", City = "H", "Address" = "I", "Address 2" = "J"
        DocNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);

        LibraryVariableStorage.Enqueue(ChangeCurrencyQst);
        LibraryVariableStorage.Enqueue(true);

        CreateReleaseCorrSalesInvoice(CorrSalesHeader, SalesHeader, DocNo);
        FindSalesLine(SalesLine, CorrSalesHeader);

        ExpectedPostingNo := NoSeries.PeekNextNo(CorrSalesHeader."Posting No. Series", CorrSalesHeader."Posting Date");

        // [WHEN] Print REP 14966 "Sales Corr. Factura-Invoice"
        RunCorrFacturaReport(CorrSalesHeader);

        GetSalesLineBeforeAfterInfo(CorrSalesHeader, QtyBefore, QtyAfter, UoMCode, UoMOKEICode);

        // [THEN] Exported factura field "2a" (seller address) = "A, B, C, D, E"
        // [THEN] Exported factura field "6a" (buyer address) = "F, G, H, I, J"
        VerifyCorrFacturaReportHeader(CorrSalesHeader."Sell-to Customer No.");
        VerifyCorrFacturaReportLine(
          SalesLine."No.", SalesLine."Unit Price (Before)", SalesLine."Amount (Before)", SalesLine."VAT %",
          SalesLine."Amount Including VAT (Before)" - SalesLine."Amount (Before)", SalesLine."Amount Including VAT (Before)");
        VerifyCorrFacturaReport(
          ExpectedPostingNo, DocNo,
          CorrSalesHeader."Posting Date", SalesHeader."Posting Date", QtyBefore, QtyAfter, UoMCode, UoMOKEICode);
        VerifyCorrFacturaReportCurrency(CorrSalesHeader."Currency Code");
        VerifyCorrFacturaReportDash(25);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrintPostedCorrFacturaInvoice()
    var
        SalesHeader: Record "Sales Header";
        CorrSalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocNo: Code[20];
        InvNo: Code[20];
        QtyBefore: Decimal;
        QtyAfter: Decimal;
        UoMCode: Code[10];
        UoMOKEICode: Code[3];
    begin
        // [SCENARIO] Export REP 14967 "Pstd. Sales Corr. Fact. Inv." for posted corrective sales invoice
        Initialize();

        // [GIVEN] Company address with "Post Code" = "A", County = "B", City = "C", "Address" = "D", "Address 2" = "E"
        // [GIVEN] Posted corrective sales invoice for customer with "Post Code" = "F", County = "G", City = "H", "Address" = "I", "Address 2" = "J"
        DocNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);

        LibraryVariableStorage.Enqueue(ChangeCurrencyQst);
        LibraryVariableStorage.Enqueue(true);

        InvNo := CreatePostCorrSalesInvoice(CorrSalesHeader, SalesHeader, DocNo);
        FindSalesInvoiceLine(SalesInvoiceLine, InvNo);

        // [WHEN] Print REP 14967 "Pstd. Sales Corr. Fact. Inv."
        RunPostedCorrInvoiceReport(InvNo);

        GetSalesInvoiceBeforeAfterInfo(InvNo, QtyBefore, QtyAfter, UoMCode, UoMOKEICode);

        // [THEN] Exported factura field "2a" (seller address) = "A, B, C, D, E"
        // [THEN] Exported factura field "6a" (buyer address) = "F, G, H, I, J"
        VerifyCorrFacturaReportHeader(CorrSalesHeader."Sell-to Customer No.");
        VerifyCorrFacturaReportLine(
          SalesInvoiceLine."No.", SalesInvoiceLine."Unit Price (Before)", SalesInvoiceLine."Amount (Before)", SalesInvoiceLine."VAT %",
          SalesInvoiceLine."Amount Including VAT (Before)" - SalesInvoiceLine."Amount (Before)",
          SalesInvoiceLine."Amount Including VAT (Before)");
        VerifyCorrFacturaReport(
          InvNo, DocNo,
          CorrSalesHeader."Posting Date", SalesHeader."Posting Date", QtyBefore, QtyAfter, UoMCode, UoMOKEICode);
        VerifyCorrFacturaReportCurrency(CorrSalesHeader."Currency Code");
        VerifyCorrFacturaReportDash(25);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrintPostedCorrFacturaCrMemo()
    var
        SalesHeader: Record "Sales Header";
        CorrSalesHeader: Record "Sales Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        DocNo: Code[20];
        CrMemoNo: Code[20];
        QtyBefore: Decimal;
        QtyAfter: Decimal;
        UoMCode: Code[10];
        UoMOKEICode: Code[3];
    begin
        // [SCENARIO] Export REP 14968 "Pstd. Sales Corr. Cr. M. Fact." for posted corrective sales credit memo
        Initialize();

        // [GIVEN] Company address with "Post Code" = "A", County = "B", City = "C", "Address" = "D", "Address 2" = "E"
        // [GIVEN] Posted corrective sales credit memo for customer with "Post Code" = "F", County = "G", City = "H", "Address" = "I", "Address 2" = "J"
        DocNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        LibraryVariableStorage.Enqueue(ChangeCurrencyQst);
        LibraryVariableStorage.Enqueue(true);

        CrMemoNo := CreatePostCorrSalesCrMemo(CorrSalesHeader, SalesHeader, DocNo);
        FindSalesCrMemoLine(SalesCrMemoLine, CrMemoNo);

        // [WHEN] Print REP 14968 "Pstd. Sales Corr. Cr. M. Fact."
        RunPostedCorrCrMemoReport(CrMemoNo);

        GetSalesCrMemoBeforeAfterInfo(CrMemoNo, QtyBefore, QtyAfter, UoMCode, UoMOKEICode);

        // [THEN] Exported factura field "2a" (seller address) = "A, B, C, D, E"
        // [THEN] Exported factura field "6a" (buyer address) = "F, G, H, I, J"
        VerifyCorrFacturaReportHeader(CorrSalesHeader."Sell-to Customer No.");
        VerifyCorrFacturaReportLine(
          SalesCrMemoLine."No.", SalesCrMemoLine."Unit Price (Before)", SalesCrMemoLine."Amount (Before)", SalesCrMemoLine."VAT %",
          SalesCrMemoLine."Amount Including VAT (Before)" - SalesCrMemoLine."Amount (Before)",
          SalesCrMemoLine."Amount Including VAT (Before)");
        VerifyCorrFacturaReport(
          CrMemoNo, DocNo,
          CorrSalesHeader."Posting Date", SalesHeader."Posting Date", QtyBefore, QtyAfter, UoMCode, UoMOKEICode);
        VerifyCorrFacturaReportCurrency(CorrSalesHeader."Currency Code");
        VerifyCorrFacturaReportDash(24);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintPostedFacturaCrMemoFacturaInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        DocumentNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Factura-Invoice] [Credit Memo]
        // [SCENARIO 201525] Verify REP 12484 "Posted Cr. M. Factura-Invoice" base values
        Initialize();

        // [GIVEN] Posted sales credit memo "CrMemoNo" with Item "X" (with description "Desc"), Quantity = 10, "Unit Price" = 80, "Line Amount" = 800, "VAT %" = 25, "Total Amount Incl. VAT" = 1000
        DocumentNo := CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        FindSalesCrMemoLine(SalesCrMemoLine, DocumentNo);

        // [WHEN] Print the posted credit memo (REP 12484 "Posted Cr. M. Factura-Invoice")
        RunPostedCrMemoFacturaInvoice(DocumentNo);

        // [THEN] Excel has been exported with following values:
        // [THEN] Header document no = "CrMemoNo"
        FileName := LibraryReportValidation.GetFileName();
        LibraryRUReports.VerifyFactura_DocNo(FileName, DocumentNo);

        // [THEN] Column "1" = "LineNo" // TFS 400627
        LibraryRUReports.VerifyFactura_LineNo(FileName, '1', 0);
        // [THEN] Column "1a" = "Desc" (Item Description)
        LibraryRUReports.VerifyFactura_ItemNo(FileName, SalesCrMemoLine.Description, 0);
        // [THEN] Column "3" = -10 (Quantity)
        LibraryRUReports.VerifyFactura_Qty(FileName, Format(-SalesCrMemoLine.Quantity), 0);
        // [THEN] Column "4" = 80 (Unit Price)
        LibraryRUReports.VerifyFactura_Price(FileName, Format(SalesCrMemoLine."Unit Price"), 0);
        // [THEN] Column "5" = -800 (Line Amount)
        LibraryRUReports.VerifyFactura_Amount(FileName, FormatAmount(-SalesCrMemoLine."Line Amount"), 0);
        // [THEN] Column "7" = 25 (VAT %)
        LibraryRUReports.VerifyFactura_VATPct(FileName, Format(SalesCrMemoLine."VAT %"), 0);
        // [THEN] Column "8" = -200 (VAT Amount)
        LibraryRUReports.VerifyFactura_VATAmount(
          LibraryReportValidation.GetFileName(), FormatAmount(-SalesCrMemoLine."Amount Including VAT" + SalesCrMemoLine.Amount), 0);
        // [THEN] Column "9" = -1000 (Amount Including VAT)
        LibraryRUReports.VerifyFactura_AmountInclVAT(
          LibraryReportValidation.GetFileName(), FormatAmount(-SalesCrMemoLine."Amount Including VAT"), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintPostedPrepmtFacturaCrMemoFacturaInvoice()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        DocumentNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Factura-Invoice] [Credit Memo] [Prepayment]
        // [SCENARIO 201525] Verify REP 12484 "Posted Cr. M. Factura-Invoice" base values in case of prepayment
        Initialize();

        // [GIVEN] Posted prepayment sales credit memo "CrM-No" with Item "X" (with description "Desc"), Quantity = 10, "Unit Price" = 80, "Line Amount" = 800, "VAT %" = 25, "Total Amount Incl. VAT" = 1000
        DocumentNo := CreatePostPrepmtSalesCrMemo();
        FindSalesCrMemoLine(SalesCrMemoLine, DocumentNo);

        // [WHEN] Print the posted credit memo (REP 12484 "Posted Cr. M. Factura-Invoice")
        RunPostedCrMemoFacturaInvoice(DocumentNo);

        // [THEN] Excel has been exported with following values:
        // [THEN] Header document no = "CrM-No"
        FileName := LibraryReportValidation.GetFileName();
        LibraryRUReports.VerifyFactura_DocNo(FileName, DocumentNo);

        // [THEN] Column "1" = "Desc" (Item Description)
        LibraryRUReports.VerifyFactura_ItemNo(FileName, SalesCrMemoLine.Description, 0);
        // [THEN] Column "7" = "25/125" (VAT %)
        LibraryRUReports.VerifyFactura_VATPct(
          LibraryReportValidation.GetFileName(), Format(SalesCrMemoLine."VAT %") + '/' + Format(100 + SalesCrMemoLine."VAT %"), 0);

        // TODO: known failure: "Amount (LCY)", "Amount Including VAT (LCY)" are empty for prepayment Invoice/CreditMemo for LCY. should be fixed. then below  should be uncommented.
        LibraryRUReports.VerifyFactura_Amount(FileName, '-', 0);
        LibraryRUReports.VerifyFactura_AmountInclVAT(FileName, FormatAmount(0), 0);

        // [THEN] Column "8" = -200 (VAT Amount)
        // LibraryRUReports.VerifyFactura_VATAmount(
        // LibraryReportValidation.GetFileName(),FormatAmount(-SalesCrMemoLine."Amount Including VAT" + SalesCrMemoLine.Amount),0);
        // [THEN] Column "9" = -1000 (Amount Including VAT)
        // LibraryRUReports.VerifyFactura_AmountInclVAT(
        // LibraryReportValidation.GetFileName(),FormatAmount(-SalesCrMemoLine."Amount Including VAT"),0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear();
        Clear(LibraryVariableStorage);
        LibraryERMCountryData.UpdatePrepaymentAccounts();

        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        UpdateSalesReceivablesSetup();
        LibraryRUReports.UpdateCompanyAddress();

        isInitialized := true;
        Commit();
    end;

    local procedure RunCorrFacturaReport(var CorrSalesHeader: Record "Sales Header")
    var
        SalesCorrFacturaInvoice: Report "Sales Corr. Factura-Invoice";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        CorrSalesHeader.SetRecFilter();
        SalesCorrFacturaInvoice.SetFileNameSilent(LibraryReportValidation.GetFileName());
        SalesCorrFacturaInvoice.SetTableView(CorrSalesHeader);
        SalesCorrFacturaInvoice.UseRequestPage(false);
        SalesCorrFacturaInvoice.Run();
    end;

    local procedure RunPostedCorrInvoiceReport(InvNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PstdSalesCorrFactInv: Report "Pstd. Sales Corr. Fact. Inv.";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        SalesInvoiceHeader.SetRange("No.", InvNo);
        PstdSalesCorrFactInv.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PstdSalesCorrFactInv.SetTableView(SalesInvoiceHeader);
        PstdSalesCorrFactInv.UseRequestPage(false);
        PstdSalesCorrFactInv.Run();
    end;

    local procedure RunPostedCorrCrMemoReport(InvNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PstdSalesCorrCrMFact: Report "Pstd. Sales Corr. Cr. M. Fact.";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        SalesCrMemoHeader.SetRange("No.", InvNo);
        PstdSalesCorrCrMFact.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PstdSalesCorrCrMFact.SetTableView(SalesCrMemoHeader);
        PstdSalesCorrCrMFact.UseRequestPage(false);
        PstdSalesCorrCrMFact.Run();
    end;

    local procedure RunPostedCrMemoFacturaInvoice(InvNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedCrMFacturaInvoice: Report "Posted Cr. M. Factura-Invoice";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        SalesCrMemoHeader.SetRange("No.", InvNo);
        PostedCrMFacturaInvoice.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PostedCrMFacturaInvoice.SetTableView(SalesCrMemoHeader);
        PostedCrMFacturaInvoice.UseRequestPage(false);
        PostedCrMFacturaInvoice.Run();
    end;

    local procedure CreatePostSalesDoc(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"): Code[20]
    begin
        CreateSalesDocument(SalesHeader, DocType, 0);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostPrepmtSalesCrMemo(): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, 100);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        SalesHeader.Find();
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        SalesCrMemoHeader.SetRange("Prepayment Order No.", SalesHeader."No.");
        SalesCrMemoHeader.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        SalesCrMemoHeader.FindFirst();
        exit(SalesCrMemoHeader."No.");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; PrepmtPct: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibraryRUReports.CreateCustomerNo());
        SalesHeader.Validate("Prepayment %", PrepmtPct);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemNoWithTariff(), LibraryRandom.RandIntInRange(15, 50));
    end;

    local procedure CreatePostCorrSalesInvoice(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCorrectiveSalesInvoice(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Correction, SalesHeader."Posting Date" + LibraryRandom.RandInt(5));
        UpdateCurrency(CorrSalesHeader);
        FindSalesLine(SalesLine, CorrSalesHeader);
        UpdateQuantityInSalesLine(SalesLine, LibraryRandom.RandIntInRange(3, 5));
        exit(LibrarySales.PostSalesDocument(CorrSalesHeader, true, true));
    end;

    local procedure CreatePostCorrSalesCrMemo(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCorrectiveSalesCrMemo(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Correction, SalesHeader."Posting Date" + LibraryRandom.RandInt(5));
        UpdateCurrency(CorrSalesHeader);
        FindSalesLine(SalesLine, CorrSalesHeader);
        UpdateQuantityInSalesLine(SalesLine, 1 / LibraryRandom.RandIntInRange(3, 5));
        exit(LibrarySales.PostSalesDocument(CorrSalesHeader, true, true));
    end;

    local procedure CreateReleaseCorrSalesInvoice(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    begin
        LibrarySales.CreateCorrectiveSalesInvoice(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Correction, SalesHeader."Posting Date" + LibraryRandom.RandInt(5));
        UpdateCurrency(CorrSalesHeader);
        ReleaseSalesDocWithNewQuantity(CorrSalesHeader, LibraryRandom.RandIntInRange(3, 5));
        exit(CorrSalesHeader."No.");
    end;

    local procedure CreateItemNoWithTariff(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Description, CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Item.Description), 0), 1, MaxStrLen(Item.Description)));
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        Item.Validate("Tariff No.", CreateTariffNo());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateTariffNo(): Code[20]
    var
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.Init();
        TariffNumber."No." := LibraryUtility.GenerateRandomCode(TariffNumber.FieldNo("No."), DATABASE::"Tariff Number");
        TariffNumber.Description := LibraryUtility.GenerateGUID();
        TariffNumber.Insert();
        exit(TariffNumber."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());
        Currency.Validate("RU Bank Digital Code", 'RUB');
        Currency.Validate(Description, LibraryUtility.GenerateGUID());
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure UpdateSalesReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"No Warning");
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure ReleaseSalesDocWithNewQuantity(SalesInvHeader: Record "Sales Header"; Multiplier: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesInvHeader);
        UpdateQuantityInSalesLine(SalesLine, Multiplier);
        LibrarySales.ReleaseSalesDocument(SalesInvHeader);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
    end;

    local procedure FindSalesCrMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; DocumentNo: Code[20])
    begin
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.FindFirst();
    end;

    local procedure FindSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; DocumentNo: Code[20])
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
    end;

    local procedure UpdateQuantityInSalesLine(var SalesLine: Record "Sales Line"; Multiplier: Decimal)
    begin
        SalesLine.Validate("Quantity (After)", Round(SalesLine."Quantity (After)" * Multiplier, 1));
        SalesLine.Modify(true);
    end;

    local procedure UpdateCurrency(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Currency Code", CreateCurrency());
        SalesHeader.Modify(true);
    end;

    local procedure GetSalesLineBeforeAfterInfo(SalesHeader: Record "Sales Header"; var QtyBefore: Decimal; var QtyAfter: Decimal; var UoMCode: Code[10]; var UoMOKEICode: Code[3])
    var
        SalesLine: Record "Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        QtyBefore := SalesLine."Quantity (Before)";
        QtyAfter := SalesLine."Quantity (After)";
        UnitOfMeasure.Get(SalesLine."Unit of Measure Code");
        UoMCode := UnitOfMeasure.Code;
        UoMOKEICode := UnitOfMeasure."OKEI Code";
    end;

    local procedure GetSalesInvoiceBeforeAfterInfo(InvNo: Code[20]; var QtyBefore: Decimal; var QtyAfter: Decimal; var UoMCode: Code[10]; var UoMOKEICode: Code[3])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        SalesInvoiceLine.SetRange("Document No.", InvNo);
        SalesInvoiceLine.FindFirst();
        QtyBefore := SalesInvoiceLine."Quantity (Before)";
        QtyAfter := SalesInvoiceLine."Quantity (After)";
        UnitOfMeasure.Get(SalesInvoiceLine."Unit of Measure Code");
        UoMCode := UnitOfMeasure.Code;
        UoMOKEICode := UnitOfMeasure."OKEI Code";
    end;

    local procedure GetSalesCrMemoBeforeAfterInfo(InvNo: Code[20]; var QtyBefore: Decimal; var QtyAfter: Decimal; var UoMCode: Code[10]; var UoMOKEICode: Code[3])
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        FindSalesCrMemoLine(SalesCrMemoLine, InvNo);
        QtyBefore := SalesCrMemoLine."Quantity (Before)";
        QtyAfter := SalesCrMemoLine."Quantity (After)";
        UnitOfMeasure.Get(SalesCrMemoLine."Unit of Measure Code");
        UoMCode := UnitOfMeasure.Code;
        UoMOKEICode := UnitOfMeasure."OKEI Code";
    end;

    local procedure GetCurrencyInfo(CurrencyCode: Code[10]; var CurrencyDescription: Text[30]; var CurrencyDigitalCode: Code[3])
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        CurrencyDigitalCode := '';
        CurrencyDescription := '';
        if CurrencyCode = '' then begin
            GLSetup.Get();
            CurrencyCode := GLSetup."LCY Code";
        end;

        if Currency.Get(CurrencyCode) then begin
            CurrencyDigitalCode := Currency."RU Bank Digital Code";
            CurrencyDescription := LowerCase(CopyStr(Currency.Description, 1, 1)) + CopyStr(Currency.Description, 2);
        end;
    end;

    local procedure FormatAmount(DecimalValue: Decimal): Text
    begin
        exit(Format(DecimalValue, 0, '<Sign><Integer Thousand><Decimal,3><Filler Character,0>'));
    end;

    local procedure VerifyCorrFacturaReport(CorrDocNo: Code[20]; DocNo: Code[20]; CorrDocDate: Date; DocDate: Date; QtyBefore: Decimal; QtyAfter: Decimal; UoMCode: Code[10]; UoMOKEICode: Code[3])
    var
        LocMgt: Codeunit "Localisation Management";
        FileName: Text;
    begin
        FileName := LibraryReportValidation.GetFileName();
        LibraryRUReports.VerifyCorrFactura_CorrDocNo(FileName, CorrDocNo);
        LibraryRUReports.VerifyCorrFactura_DocNo(FileName, DocNo);
        LibraryRUReports.VerifyCorrFactura_CorrDocDate(FileName, LocMgt.Date2Text(CorrDocDate));
        LibraryRUReports.VerifyCorrFactura_DocDate(FileName, LocMgt.Date2Text(DocDate));
        LibraryRUReports.VerifyCorrFactura_Qty(FileName, Format(QtyBefore), 0);
        LibraryRUReports.VerifyCorrFactura_Qty(FileName, Format(QtyAfter), 1);
        LibraryRUReports.VerifyCorrFactura_UOMCode(FileName, UoMOKEICode, 1);
        LibraryRUReports.VerifyCorrFactura_UOMName(FileName, UoMCode, 1);
    end;

    local procedure VerifyCorrFacturaReportCurrency(CurrencyCode: Code[10])
    var
        CurrencyDescription: Text[30];
        CurrencyDigitalCode: Code[3];
        FileName: Text;
    begin
        GetCurrencyInfo(CurrencyCode, CurrencyDescription, CurrencyDigitalCode);
        FileName := LibraryReportValidation.GetFileName();
        LibraryRUReports.VerifyCorrFactura_CurrencyName(FileName, CurrencyDescription);
        LibraryRUReports.VerifyCorrFactura_CurrencyCode(FileName, CurrencyDigitalCode);
    end;

    local procedure VerifyCorrFacturaReportDash(CheckingLine: Integer)
    var
        Offset: Integer;
        FileName: Text;
    begin
        Offset := CheckingLine - 22;
        FileName := LibraryReportValidation.GetFileName();
        LibraryRUReports.VerifyCorrFactura_Amount(FileName, '-', Offset);
        LibraryRUReports.VerifyCorrFactura_VATAmount(FileName, '-', Offset);
        LibraryRUReports.VerifyCorrFactura_AmountInclVAT(FileName, '-', Offset);
    end;

    local procedure VerifyCorrFacturaReportHeader(CustomerNo: Code[20])
    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        LocalReportMgt: Codeunit "Local Report Management";
        FileName: Text;
    begin
        FileName := LibraryReportValidation.GetFileName();
        LibraryRUReports.VerifyCorrFactura_CompanyName(FileName, LocalReportMgt.GetCompanyName());
        LibraryRUReports.VerifyCorrFactura_CompanyAddress(FileName, LocalReportMgt.GetLegalAddress());

        CompanyInformation.Get();
        LibraryRUReports.VerifyCorrFactura_CompanyINN(
          LibraryReportValidation.GetFileName(), CompanyInformation."VAT Registration No." + ' / ' + CompanyInformation."KPP Code");
        LibraryRUReports.VerifyCorrFactura_BuyerName(FileName, LocalReportMgt.GetCustName(CustomerNo));

        Customer.Get(CustomerNo);
        LibraryRUReports.VerifyCorrFactura_BuyerAddress(
          LibraryReportValidation.GetFileName(), LibraryRUReports.GetCustomerFullAddress(Customer."No."));
        LibraryRUReports.VerifyCorrFactura_BuyerINN(
          LibraryReportValidation.GetFileName(), Customer."VAT Registration No." + ' / ' + Customer."KPP Code");
    end;

    local procedure VerifyCorrFacturaReportLine(ItemNo: Code[20]; Price: Decimal; Amount: Decimal; VATPct: Decimal; VATAmount: Decimal; AmountInclVAT: Decimal)
    var
        Item: Record Item;
        FileName: Text;
    begin
        Item.Get(ItemNo);
        FileName := LibraryReportValidation.GetFileName();
        LibraryRUReports.VerifyCorrFactura_LineNo(FileName, '1', 0);
        LibraryRUReports.VerifyCorrFactura_ItemNo(FileName, Item.Description, 0);
        LibraryRUReports.VerifyCorrFactura_TariffNo(FileName, Item."Tariff No.", 0);
        LibraryRUReports.VerifyCorrFactura_Price(FileName, FormatAmount(Price), 0);
        LibraryRUReports.VerifyCorrFactura_Amount(FileName, FormatAmount(Amount), 0);
        LibraryRUReports.VerifyCorrFactura_VATPct(FileName, Format(VATPct), 0);
        LibraryRUReports.VerifyCorrFactura_VATAmount(FileName, FormatAmount(VATAmount), 0);
        LibraryRUReports.VerifyCorrFactura_AmountInclVAT(FileName, FormatAmount(AmountInclVAT), 0);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

