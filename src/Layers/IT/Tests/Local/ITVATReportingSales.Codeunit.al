codeunit 144007 "IT - VAT Reporting - Sales"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVATUtils: Codeunit "Library - VAT Utils";
        LibraryItLocalization: Codeunit "Library - IT Localization";
        isInitialized: Boolean;
        YouMustSpecifyValueErr: Label 'You must specify a value for the %1 field';
        ConfirmChangeQst: Label 'Do you want to change %1?';

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvIncl()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Invoice, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifySalesDocIncl(SalesHeader."Document Type"::Invoice, false, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvExcl()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Invoice, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifySalesDocIncl(SalesHeader."Document Type"::Invoice, false, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvExcl2()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Invoice, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = No in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifySalesDocIncl(SalesHeader."Document Type"::Invoice, false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvInclWVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Invoice, [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifySalesDocIncl(SalesHeader."Document Type"::Invoice, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvExclWVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Invoice, [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifySalesDocIncl(SalesHeader."Document Type"::Invoice, true, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvExcl2WVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Invoice, [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = No in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifySalesDocIncl(SalesHeader."Document Type"::Invoice, true, false, true);
    end;

    local procedure VerifySalesDocIncl(DocumentType: Enum "Sales Document Type"; InclVAT: Boolean; InclInVATSetup: Boolean; InclInVATTransRep: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineAmount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(InclInVATSetup);

        // Create Sales Document.
        LineAmount := CalculateAmount(WorkDate(), InclVAT, InclInVATTransRep);
        CreateSalesDocument(
          SalesHeader, SalesLine, DocumentType, CreateCustomer(false, SalesHeader.Resident::Resident, true, InclVAT), LineAmount);

        // Verify Sales Line.
        SalesLine.TestField("Include in VAT Transac. Rep.", InclInVATSetup); // Amount is no longer compared to Threshold.

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrdLnkBlOrdSingleLine()
    begin
        // Sales Blanket Order with Single Line.
        // [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Order Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifySalesBlOrd(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrdLnkBlOrdMultipleLines()
    begin
        // Sales Blanket Order with Multiple Lines.
        // [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Order Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifySalesBlOrd(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrdLnkBlOrdSingleLineWVAT()
    begin
        // Sales Blanket Order with Single Line.
        // [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Order Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifySalesBlOrd(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrdLnkBlOrdMultiLinesWVAT()
    begin
        // Sales Blanket Order with Multiple Lines.
        // [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Order Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifySalesBlOrd(true, true);
    end;

    local procedure VerifySalesBlOrd(MultiLine: Boolean; InclVAT: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrderHeader: Record "Sales Header";
        LineAmount: Decimal;
        OrderAmount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Calculate Amounts.
        OrderAmount := CalculateAmount(WorkDate(), InclVAT, true); // Above threshold.
        LineAmount := CalculateAmount(WorkDate(), InclVAT, false); // Below threshold.

        // Create Sales Blanket Order.
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order",
          CreateCustomer(false, SalesHeader.Resident::Resident, true, InclVAT), OrderAmount);

        if MultiLine then begin
            // Set Quantity to Ship to 0 on line with Amount above Threshold.
            SalesLine.Validate("Qty. to Ship", 0);
            SalesLine.Modify(true);

            // Create Sales Line with Line Amount below Threshold.
            CreateSalesLine(SalesHeader, SalesLine, LineAmount);
        end else begin
            // Update Quantity to Ship so that Line Amount is below Threshold.
            SalesLine.Validate("Qty. to Ship", LineAmount / SalesLine."Unit Price");
            SalesLine.Modify(true);
        end;

        // Release and Make Order.
        CODEUNIT.Run(CODEUNIT::"Release Sales Document", SalesHeader);
        MakeOrderSales(SalesHeader, SalesOrderHeader);

        // Verify Line.
        FindSalesLine(SalesLine, SalesOrderHeader."Document Type", SalesOrderHeader."No.");
        SalesLine.TestField("Include in VAT Transac. Rep.", true);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EUCountrySalesInv()
    begin
        VerifyCountrySalesInv(CreateCountry()); // EU Country.
    end;

    local procedure VerifyCountrySalesInv(CountryRegionCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        LineAmount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Create Customer.
        Customer.Get(CreateCustomer(false, SalesHeader.Resident::"Non-Resident", true, false));
        Customer.Validate("Country/Region Code", CountryRegionCode);
        Customer.Modify(true);

        // Create Sales Document.
        LineAmount := CalculateAmount(WorkDate(), false, true);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.", LineAmount);

        // Verify Sales Line.
        SalesLine.TestField("Include in VAT Transac. Rep.", false);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocManualInclude()
    var
        SalesInvoiceTestPage: TestPage "Sales Invoice";
        SalesOrderTestPage: TestPage "Sales Order";
        SalesCreditMemoTestPage: TestPage "Sales Credit Memo";
        SalesReturnOrderTestPage: TestPage "Sales Return Order";
    begin
        // Verify EDITABLE is TRUE through pages because property is not available through record.
        // Sales Invoice.
        SalesInvoiceTestPage.OpenNew();
        SalesInvoiceTestPage."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());
        Assert.IsTrue(
          SalesInvoiceTestPage.SalesLines."Include in VAT Transac. Rep.".Editable(),
          'EDITABLE should be TRUE for the field ' + SalesInvoiceTestPage.SalesLines."Include in VAT Transac. Rep.".Caption);
        SalesInvoiceTestPage.Close();

        // Sales Order.
        SalesOrderTestPage.OpenNew();
        SalesOrderTestPage."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());
        Assert.IsTrue(
          SalesOrderTestPage.SalesLines."Include in VAT Transac. Rep.".Editable(),
          'EDITABLE should be TRUE for the field ' + SalesOrderTestPage.SalesLines."Include in VAT Transac. Rep.".Caption);
        SalesOrderTestPage.Close();

        // Sales Credit Memo.
        SalesCreditMemoTestPage.OpenNew();
        SalesCreditMemoTestPage."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());
        Assert.IsTrue(
          SalesCreditMemoTestPage.SalesLines."Include in VAT Transac. Rep.".Editable(),
          'EDITABLE should be TRUE for the field ' + SalesCreditMemoTestPage.SalesLines."Include in VAT Transac. Rep.".Caption);
        SalesCreditMemoTestPage.Close();

        // Sales Return Order.
        SalesReturnOrderTestPage.OpenNew();
        SalesReturnOrderTestPage."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());
        Assert.IsTrue(
          SalesReturnOrderTestPage.SalesLines."Include in VAT Transac. Rep.".Editable(),
          'EDITABLE should be TRUE for the field ' + SalesReturnOrderTestPage.SalesLines."Include in VAT Transac. Rep.".Caption);
        SalesReturnOrderTestPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvPostIncl()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Invoice, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifySalesDocPostIncl(SalesHeader."Document Type"::Invoice, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvPostExcl()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Invoice, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifySalesDocPostIncl(SalesHeader."Document Type"::Invoice, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvPostInclWVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Invoice, [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        VerifySalesDocPostIncl(SalesHeader."Document Type"::Invoice, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvPostExclWVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Invoice, [Prices Including VAT] = Yes.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifySalesDocPostIncl(SalesHeader."Document Type"::Invoice, true, false);
    end;

    local procedure VerifySalesDocPostIncl(DocumentType: Enum "Sales Document Type"; InclVAT: Boolean; InclInVATTransRep: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineAmount: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Create Sales Document.
        LineAmount := CalculateAmount(WorkDate(), InclVAT, InclInVATTransRep);
        CreateSalesDocument(
          SalesHeader, SalesLine, DocumentType, CreateCustomer(false, SalesHeader.Resident::Resident, true, InclVAT), LineAmount);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify Sales Line.
        VerifyIncludeVAT(GetDocumentTypeVATEntry(DATABASE::"Sales Header", DocumentType.AsInteger()), DocumentNo, true); // Amount is no longer compared to Threshold.

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrdWithContPostSingleLine()
    begin
        // Sales Order linked to Blanket Order.
        // Single Line with Contact No.
        // Expected result: Contract No. copied to VAT Entry.
        VerifySalesOrdwithContractPost(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrdWithContPostMultiLine()
    begin
        // Sales Order linked to Blanket Order.
        // Multiple Lines (only one has Contact No.).
        // Expected result: Contract No. copied to VAT Entry.
        VerifySalesOrdwithContractPost(true);
    end;

    local procedure VerifySalesOrdwithContractPost(Multi: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineAmount: Decimal;
        OrderAmount: Decimal;
        BlanketOrderNo: Code[20];
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Calculate Amounts.
        OrderAmount := CalculateAmount(WorkDate(), false, true); // Above threshold.
        LineAmount := CalculateAmount(WorkDate(), false, false); // Below threshold.

        // Create Sales Order Linked to Blanket Order.
        BlanketOrderNo :=
          CreateSalesOrderLinkedBlOrd(
            SalesHeader, CreateCustomer(false, SalesHeader.Resident::Resident, true, false), OrderAmount, LineAmount);

        // Create Sales Line w/o Contract.
        if Multi then
            CreateSalesLine(SalesHeader, SalesLine, OrderAmount);

        // Post Sales Order.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify VAT Entry.
        if Multi then
            VerifyContractNo(SalesHeader."Document Type"::Invoice, DocumentNo, -OrderAmount, '');
        VerifyContractNo(SalesHeader."Document Type"::Invoice, DocumentNo, -LineAmount, BlanketOrderNo);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCMRefToBlank()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: Error message that [Refers to Period] field is blank (part of the blacklist functionality).
        VerifySalesDocRefTo(SalesHeader."Document Type"::"Credit Memo", SalesHeader."Refers to Period"::" ", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCMRefToCurrent()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current.
        VerifySalesDocRefTo(SalesHeader."Document Type"::"Credit Memo", SalesHeader."Refers to Period"::Current, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCMRefToCrYear()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current Calendar Year.
        VerifySalesDocRefTo(SalesHeader."Document Type"::"Credit Memo", SalesHeader."Refers to Period"::"Current Calendar Year", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCMRefToPrevious()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Previous Calendar Year.
        VerifySalesDocRefTo(SalesHeader."Document Type"::"Credit Memo", SalesHeader."Refers to Period"::"Previous Calendar Year", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesRtnOrdRefToCurrent()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current.
        VerifySalesDocRefTo(SalesHeader."Document Type"::"Return Order", SalesHeader."Refers to Period"::Current, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesRtnOrdRefToCrYear()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current Calendar Year.
        VerifySalesDocRefTo(SalesHeader."Document Type"::"Return Order", SalesHeader."Refers to Period"::"Current Calendar Year", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesRtnOrdRefToPrevious()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Return Order, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Previous Calendar Year.
        VerifySalesDocRefTo(SalesHeader."Document Type"::"Return Order", SalesHeader."Refers to Period"::"Previous Calendar Year", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCMLineRefToCurrent()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current.
        VerifySalesDocRefTo(SalesHeader."Document Type"::"Credit Memo", SalesHeader."Refers to Period"::Current, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCMLineRefToCrYear()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Credit Memo, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Current Calendar Year.
        VerifySalesDocRefTo(SalesHeader."Document Type"::"Credit Memo", SalesHeader."Refers to Period"::"Current Calendar Year", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesRtnOrdLineRefToPrevious()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Return Order, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Excl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes.
        // Expected Result: [Refers to Period] = Previous Calendar Year.
        VerifySalesDocRefTo(SalesHeader."Document Type"::"Credit Memo", SalesHeader."Refers to Period"::"Previous Calendar Year", true);
    end;

    local procedure VerifySalesDocRefTo(DocumentType: Enum "Sales Document Type"; RefersToPeriod: Option; UpdateLine: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // [Prices Including VAT] = No.
        // Line Amount > [Threshold Amount Excl. VAT.].
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Create Sales Document.
        LineAmount := CalculateAmount(WorkDate(), false, true);

        // Create Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(false, SalesHeader.Resident::Resident, true, false));

        // Update Refers To Period.
        SalesHeader.Validate("Refers to Period", RefersToPeriod);
        SalesHeader.Modify(true);

        // Create Sales Line.
        CreateSalesLine(SalesHeader, SalesLine, LineAmount);

        // Update Refers To Period.
        if UpdateLine then begin
            SalesLine.Validate("Refers to Period", RefersToPeriod);
            SalesLine.Modify(true);
        end;

        // Post Sales Document.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify Posted Sales Cr. Memo.
        if UpdateLine then
            VerifyRefersToPeriod(DATABASE::"Sales Cr.Memo Line", DocumentNo, RefersToPeriod)
        else
            VerifyRefersToPeriod(DATABASE::"Sales Cr.Memo Header", DocumentNo, RefersToPeriod);

        // Verify VAT Entry.
        VerifyIncludeVAT(GetDocumentTypeVATEntry(DATABASE::"Sales Header", DocumentType.AsInteger()), DocumentNo, true);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrdPrep()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATEntry: Record "VAT Entry";
        LineAmount: Decimal;
        DocumentNo: Code[20];
        PrepDocumentNo: Code[20];
    begin
        // [Prices Including VAT] = No.
        // Line Amount > [Threshold Amount Excl. VAT.].
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);
        SetupPrepayments();

        // Create Sales Document.
        LineAmount := CalculateAmount(WorkDate(), false, true);

        // Create Sales Header.
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(false, SalesHeader.Resident::Resident, true, false));
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandInt(50)); // Prepayment below the threshold
        SalesHeader.Validate("Prepayment Due Date", SalesHeader."Posting Date");
        SalesHeader.Modify(true);

        // Create Sales Line.
        CreateSalesLine(SalesHeader, SalesLine, LineAmount);

        // Post Prepayment Invoice.
        PrepDocumentNo := PostSalesPrepInvoice(SalesHeader);

        // Post Sales Document.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify VAT Entry.
        FindVATEntry(VATEntry, VATEntry."Document Type"::Invoice, PrepDocumentNo);
        VATEntry.TestField("Include in VAT Transac. Rep.", false); // Prepayment Invoice VAT.

        VATEntry.SetFilter(Base, '<0');
        FindVATEntry(VATEntry, VATEntry."Document Type"::Invoice, DocumentNo);
        VATEntry.TestField("Include in VAT Transac. Rep.", true); // Invoice VAT.

        VATEntry.SetFilter(Base, '>0');
        FindVATEntry(VATEntry, VATEntry."Document Type"::Invoice, DocumentNo);
        VATEntry.TestField("Include in VAT Transac. Rep.", false); // Reverse of Prepayment Invoice VAT.

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustSalesTaxRepContact()
    var
        Customer: Record Customer;
    begin
        CustSalesTaxRep(Customer."Tax Representative Type"::Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustSalesTaxRepCust()
    var
        Customer: Record Customer;
    begin
        CustSalesTaxRep(Customer."Tax Representative Type"::Customer);
    end;

    local procedure CustSalesTaxRep(TaxRepType: Option)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATEntry: Record "VAT Entry";
        Amount: Decimal;
        DocumentNo: Code[20];
        TaxRepNo: Code[20];
        ExpectedTaxRepType: Option;
    begin
        Initialize();

        // Create Customer.
        Customer.Get(CreateCustomer(false, Customer.Resident::"Non-Resident", false, false));

        // Set Tax Representative Type & No.
        case TaxRepType of
            Customer."Tax Representative Type"::Contact:
                begin
                    TaxRepNo := CreateContact();
                    ExpectedTaxRepType := VATEntry."Tax Representative Type"::Contact;
                end;
            Customer."Tax Representative Type"::Customer:
                begin
                    TaxRepNo := CreateCustomer(false, Customer.Resident::Resident, true, true);
                    ExpectedTaxRepType := VATEntry."Tax Representative Type"::Customer;
                end;
        end;
        Customer.Validate("Tax Representative Type", TaxRepType);
        Customer.Validate("Tax Representative No.", TaxRepNo);
        Customer.Modify(true);

        // Create Sales Document.
        Amount := LibraryRandom.RandDec(10000, 2);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", Amount);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify VAT Entry.
        VerifyTaxRep(
          GetDocumentTypeVATEntry(DATABASE::"Sales Header", SalesHeader."Document Type".AsInteger()), DocumentNo, ExpectedTaxRepType, TaxRepNo);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InvIndCustResFiscalCode()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // Verify that error message is generated when posting Sales Invoice without [Fiscal Code].
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Resident.
        // Expected Result: posting is aborted with error message.
        VerifySalesDocReqFields(SalesHeader."Document Type"::Invoice, true, Customer.Resident::Resident, Customer.FieldNo("Fiscal Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvIndCustNonResCountryRegion()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // Verify that error message is generated when posting Sales Invoice without [Country/Region Code].
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifySalesDocReqFields(
          SalesHeader."Document Type"::Invoice, true, Customer.Resident::"Non-Resident", Customer.FieldNo("Country/Region Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvIndCustNonResFirstName()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // Verify that error message is generated when posting Sales Invoice without [First Name].
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifySalesDocReqFields(
          SalesHeader."Document Type"::Invoice, true, Customer.Resident::"Non-Resident", Customer.FieldNo("First Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvIndCustNonResLastName()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // Verify that error message is generated when posting Sales Invoice without [Last Name].
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifySalesDocReqFields(
          SalesHeader."Document Type"::Invoice, true, Customer.Resident::"Non-Resident", Customer.FieldNo("Last Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvIndCustNonResDateOfBirth()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // Verify that error message is generated when posting Sales Invoice without [Date of Birth].
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifySalesDocReqFields(
          SalesHeader."Document Type"::Invoice, true, Customer.Resident::"Non-Resident", Customer.FieldNo("Date of Birth"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvIndCustNonResPlaceOfBirth()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // Verify that error message is generated when posting Sales Invoice without [Place of Birth].
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifySalesDocReqFields(
          SalesHeader."Document Type"::Invoice, true, Customer.Resident::"Non-Resident", Customer.FieldNo("Place of Birth"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvKnCustResVATRegNo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // Verify that error message is generated when posting Sales Invoice without [VAT Registration No.].
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = No.
        // Resident = Resident.
        // Expected Result: posting is aborted with error message.
        VerifySalesDocReqFields(
          SalesHeader."Document Type"::Invoice, false, Customer.Resident::Resident, Customer.FieldNo("VAT Registration No."));
    end;

    local procedure VerifySalesDocReqFields(DocumentType: Enum "Sales Document Type"; IndividualPerson: Boolean; Resident: Option; FieldId: Integer)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FieldRef: FieldRef;
        RecordRef: RecordRef;
        LineAmount: Decimal;
        ExpectedError: Text;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Calculate Line Amount (Excl. VAT).
        LineAmount := CalculateAmount(WorkDate(), false, true);

        // Create Customer (Excl. VAT).
        Customer.Get(CreateCustomer(IndividualPerson, Resident, true, false));

        // Remove Value from Field under test.
        RecordRef.GetTable(Customer);
        FieldRef := RecordRef.Field(FieldId);
        ClearField(RecordRef, FieldRef);

        // Create Sales Document.
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, Customer."No.", LineAmount);

        // Try to Post Sales Document and verify Error Message.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        if FieldId = Customer.FieldNo("Country/Region Code") then
            ExpectedError := StrSubstNo(YouMustSpecifyValueErr, SalesHeader.FieldCaption("Sell-to Country/Region Code"))
        else
            ExpectedError := StrSubstNo(YouMustSpecifyValueErr, FindFieldCaption(DATABASE::"Sales Header", FieldRef.Name));
        Assert.ExpectedError(ExpectedError);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvIndCustResExclVATRep()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // Verify that no error message is generated when posting Sales Invoice without [Fiscal Code].
        // [Include in VAT Transac. Rep.] = No.
        // Individual Person = Yes.
        // Resident = Resident.
        // Expected Result: posting is completed successfully.
        VerifySalesDocReqFieldsExcl(SalesHeader."Document Type"::Invoice, true, Customer.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvIndCustNonResExclVATRep()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // Verify that no error message is generated when posting Sales Invoice without [Country/Region Code].
        // [Include in VAT Transac. Rep.] = No.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is completed successfully.
        VerifySalesDocReqFieldsExcl(SalesHeader."Document Type"::Invoice, true, Customer.Resident::"Non-Resident");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvKnCustResExclVATRep()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // Verify that no error message is generated when posting Sales Invoice without [VAT Registration No.].
        // [Include in VAT Transac. Rep.] = No.
        // Individual Person = No.
        // Resident = Resident.
        // Expected Result: posting is completed successfully.
        VerifySalesDocReqFieldsExcl(SalesHeader."Document Type"::Invoice, false, Customer.Resident::Resident);
    end;

    local procedure VerifySalesDocReqFieldsExcl(DocumentType: Enum "Sales Document Type"; IndividualPerson: Boolean; Resident: Option)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineAmount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(false);

        // Calculate Line Amount (Excl. VAT).
        LineAmount := CalculateAmount(WorkDate(), false, true);

        // Create Sales Document.
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, CreateCustomer(IndividualPerson, Resident, false, false), LineAmount);

        // Post Sales Document (no error message).
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrePayInvPost()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Sales Invoice, [Prices Including VAT] = No.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Expected Result: [Include in VAT Transac. Rep.] = No.
        VerifyPrePaySalesDocPostIncl(SalesHeader."Document Type"::Order, false, true);
    end;

    [Test]
    [HandlerFunctions('BillToCustomerNoChangeConfirmHandler')]
    [Scope('OnPrem')]
    procedure OperationTypeIsFilledWhenBillToCustomerIsChanged()
    var
        NoSeries1: Record "No. Series";
        NoSeries2: Record "No. Series";
        CustomerSellTo: Record "Customer";
        CustomerBillTo: Record "Customer";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Invoice] [UT]
        // [SCENARIO 307232] Operation type is updated when Bill-to Customer No. field is validated in Sales Header record.

        // [GIVEN] No. Series record "N1".
        // [GIVEN] Customer record "CustSellTo" with "VAT Bus. Posting Group" having "Default Sales Operation Type" = "N1".
        CreateCustomerWithNoSeries(CustomerSellTo, NoSeries1);
        // [GIVEN] No. Series record "N2".
        // [GIVEN] Customer record "CustBillTo" with "VAT Bus. Posting Group" having "Default Sales Operation Type" = "N2".
        CreateCustomerWithNoSeries(CustomerBillTo, NoSeries2);
        // [GIVEN] Sales Header record with "Sell-to Customer No." = "CustSellTo".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerSellTo."No.");
        LibraryVariableStorage.Enqueue(ConfirmChangeQst);

        // [WHEN] Validate "S1"."Bill-to Customer No." with "CustBillTo"."No." (confirm handler).
        SalesHeader.Validate("Bill-to Customer No.", CustomerBillTo."No.");

        // [THEN] Sales Header has "Operation Type" = "N2".
        SalesHeader.TestField("Operation Type", NoSeries2.Code);
    end;

    local procedure VerifyPrePaySalesDocPostIncl(DocumentType: Enum "Sales Document Type"; InclVAT: Boolean; InclInVATTransRep: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineAmount: Decimal;
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);
        SetupPrepayments();

        // Create Sales Document.
        LineAmount := CalculateAmount(WorkDate(), InclVAT, InclInVATTransRep);
        CreatePrePaymentSalesDocument(
          SalesHeader, SalesLine, DocumentType, CreateCustomer(false, SalesHeader.Resident::Resident, true, InclVAT), LineAmount);
        DocumentNo := PostSalesPrepInvoice(SalesHeader);

        // Verify Sales Line.
        VerifyIncludeVAT(GetDocumentTypeVATEntry(DATABASE::"Sales Header", DocumentType.AsInteger()), DocumentNo, false); // Amount is no longer compared to Threshold.

        // Tear Down.
        TearDown();
    end;

    local procedure Initialize()
    begin
        TearDown(); // Cleanup.
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;

        isInitialized := true;
        CreateVATReportSetup();
        Commit();

        TearDown(); // Cleanup for the first test.
    end;

    local procedure CalculateAmount(StartingDate: Date; InclVAT: Boolean; InclInVATTransRep: Boolean) Amount: Decimal
    var
        Delta: Decimal;
    begin
        // Random delta should be less than difference between Threshold Incl. VAT and Excl. VAT.
        Delta := LibraryRandom.RandDec(GetThresholdAmount(StartingDate, true) - GetThresholdAmount(StartingDate, false), 2);

        if not InclInVATTransRep then
            Delta := -Delta;

        Amount := GetThresholdAmount(StartingDate, InclVAT) + Delta;
    end;

    local procedure ClearField(RecordRef: RecordRef; FieldRef: FieldRef)
    var
        FieldRef2: FieldRef;
        RecordRef2: RecordRef;
    begin
        RecordRef2.Open(RecordRef.Number, true); // Open temp table.
        FieldRef2 := RecordRef2.Field(FieldRef.Number);

        FieldRef.Validate(FieldRef2.Value); // Clear field value.
        RecordRef.Modify(true);
    end;

    local procedure CreateContact(): Code[20]
    var
        Contact: Record Contact;
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate(
          "VAT Registration No.", LibraryUtility.GenerateRandomCode(Contact.FieldNo("VAT Registration No."), DATABASE::Contact));
        Contact.Modify(true);
        exit(Contact."No.");
    end;

    local procedure CreateCountry(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Intrastat Code", CountryRegion.Code); // Fill with Country Code as value is not important for test.
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateCustomer(IndividualPerson: Boolean; Resident: Option; ReqFlds: Boolean; PricesInclVAT: Boolean): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibrarySales.CreateCustomer(Customer);
        if not FindVATPostingSetup(VATPostingSetup, true) then
            FindVATPostingSetup(VATPostingSetup, false);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Individual Person", IndividualPerson);
        Customer.Validate(Resident, Resident);

        if ReqFlds then begin
            if Resident = Customer.Resident::"Non-Resident" then
                Customer.Validate("Country/Region Code", GetCountryCode());
            if not IndividualPerson then
                Customer.Validate(
                  "VAT Registration No.",
                  CopyStr(
                    LibraryUtility.GenerateRandomCode(Customer.FieldNo("VAT Registration No."), DATABASE::Customer), 1,
                    LibraryUtility.GetFieldLength(DATABASE::Customer, Customer.FieldNo("VAT Registration No."))))
            else
                case Resident of
                    Customer.Resident::Resident:
                        Customer.Validate(
                          "Fiscal Code",
                          CopyStr(
                            LibraryUtility.GenerateRandomCode(Customer.FieldNo("Fiscal Code"), DATABASE::Customer), 1,
                            LibraryUtility.GetFieldLength(DATABASE::Customer, Customer.FieldNo("Fiscal Code"))));
                    Customer.Resident::"Non-Resident":
                        begin
                            Customer.Validate("First Name", LibraryUtility.GenerateRandomCode(Customer.FieldNo("First Name"), DATABASE::Customer));
                            Customer.Validate("Last Name", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Last Name"), DATABASE::Customer));
                            Customer.Validate("Date of Birth", CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>'));
                            Customer.Validate(
                              "Place of Birth", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Place of Birth"), DATABASE::Customer));
                        end;
                end;
        end;

        Customer.Validate("Prices Including VAT", PricesInclVAT);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithNoSeries(var Customer: Record Customer; var NoSeries: Record "No. Series")
    var
        VATRegister: Record "VAT Register";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryItLocalization.CreateVATRegister(VATRegister, VATRegister.Type::Sale);
        VATRegister.Modify(true);
        CreateNoSeriesWithSalesType(NoSeries, VATRegister.Code);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VATBusinessPostingGroup.Validate("Default Sales Operation Type", NoSeries.Code);
        VATBusinessPostingGroup.Modify(true);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        Customer.Modify(true);
    end;

    local procedure CreateGLAccount(GenPostingType: Enum "General Posting Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT"); // Always use Normal for G/L Accounts.
        if not FindVATPostingSetup(VATPostingSetup, true) then
            FindVATPostingSetup(VATPostingSetup, false);

        // Gen. Posting Type, Gen. Bus. and VAT Bus. Posting Groups are required for General Journal.
        if GenPostingType <> GLAccount."Gen. Posting Type"::" " then begin
            GLAccount.Validate("Gen. Posting Type", GenPostingType);
            GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
            GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        end;
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateNoSeriesWithSalesType(var NoSeries: Record "No. Series"; VATRegisterCode: Code[10])
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, true);
        NoSeries.Validate("No. Series Type", NoSeries."No. Series Type"::Sales);
        NoSeries.Validate("VAT Register", VATRegisterCode);
        NoSeries.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; LineAmount: Decimal)
    begin
        // Create Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);

        // Create Sales Line.
        CreateSalesLine(SalesHeader, SalesLine, LineAmount);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LineAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        // Create Sales Line.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccount(GLAccount."Gen. Posting Type"::" "),
          LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LineAmount / SalesLine.Quantity);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineLinkedBlOrd(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesLine2: Record "Sales Line"; LineAmount: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", SalesLine2."No.", SalesLine2.Quantity / 2); // At least 2 documents can be linked to a Blanket Order.
        SalesLine.Validate("Blanket Order No.", SalesLine2."Document No.");
        SalesLine.Validate("Blanket Order Line No.", SalesLine2."Line No.");
        SalesLine.Validate("Unit Price", LineAmount / SalesLine.Quantity);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderLinkedBlOrd(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; OrderAmount: Decimal; LineAmount: Decimal): Code[20]
    var
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Create and Release Blanket Order.
        CreateSalesDocument(SalesHeader2, SalesLine2, SalesHeader2."Document Type"::"Blanket Order", CustomerNo, OrderAmount);
        CODEUNIT.Run(CODEUNIT::"Release Sales Document", SalesHeader2);

        // Create Sales Order Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesLine2."Sell-to Customer No.");

        // Create Sales Line and Assign Contract No.
        CreateSalesLineLinkedBlOrd(SalesHeader, SalesLine, SalesLine2, LineAmount);
        exit(SalesLine2."Document No.");
    end;

    local procedure CreatePrePaymentSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; LineAmount: Decimal)
    begin
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, CustomerNo, LineAmount);

        // Set pre payment percentage
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandInt(20));
        SalesHeader.Modify(true);
    end;

    local procedure CreateVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        // Create VAT Report Setup.
        if VATReportSetup.IsEmpty() then
            VATReportSetup.Insert(true);
        VATReportSetup.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        VATReportSetup.Modify(true);
    end;

    local procedure CreateVATTransReportAmount(var VATTransRepAmount: Record "VAT Transaction Report Amount"; StartingDate: Date)
    begin
        VATTransRepAmount.Init();
        VATTransRepAmount.Validate("Starting Date", StartingDate);
        VATTransRepAmount.Insert(true);
    end;

    local procedure EnableUnrealizedVAT(UnrealVAT: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Unrealized VAT", UnrealVAT);
        GLSetup.Modify(true);
    end;

    local procedure FindFieldCaption(TableNo: Integer; FieldName: Text[30]): Text
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, TableNo);
        Field.SetRange(FieldName, FieldName);
        Field.FindFirst();
        exit(Field."Field Caption");
    end;

    local procedure GetCountryCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CountryRegion.SetFilter(Code, '<>%1', CompanyInformation."Country/Region Code");
        CountryRegion.SetFilter("Intrastat Code", '');
        LibraryERM.FindCountryRegion(CountryRegion);
        exit(CountryRegion.Code);
    end;

    local procedure GetDocumentTypeVATEntry(TableNo: Option; DocumentType: Option) DocumentTypeVATEntry: Enum "Gen. Journal Document Type"
    var
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";
        VATEntry: Record "VAT Entry";
    begin
        case TableNo of
            DATABASE::"Gen. Journal Line":
                DocumentTypeVATEntry := "Gen. Journal Document Type".FromInteger(DocumentType);
            DATABASE::"Sales Header":
                case DocumentType of
                    SalesHeader."Document Type"::Invoice.AsInteger(),
                    SalesHeader."Document Type"::Order.AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::Invoice;
                    SalesHeader."Document Type"::"Credit Memo".AsInteger(),
                    SalesHeader."Document Type"::"Return Order".AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::"Credit Memo";
                end;
            DATABASE::"Service Header":
                case DocumentType of
                    ServiceHeader."Document Type"::Invoice.AsInteger(),
                    ServiceHeader."Document Type"::Order.AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::Invoice;
                    ServiceHeader."Document Type"::"Credit Memo".AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::"Credit Memo";
                end;
            DATABASE::"Purchase Header":
                case DocumentType of
                    PurchHeader."Document Type"::Invoice.AsInteger(),
                    PurchHeader."Document Type"::Order.AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::Invoice;
                    PurchHeader."Document Type"::"Credit Memo".AsInteger(),
                    PurchHeader."Document Type"::"Return Order".AsInteger():
                        DocumentTypeVATEntry := VATEntry."Document Type"::"Credit Memo";
                end;
        end;
    end;

    local procedure GetThresholdAmount(StartingDate: Date; InclVAT: Boolean) Amount: Decimal
    var
        VATTransactionReportAmount: Record "VAT Transaction Report Amount";
    begin
        VATTransactionReportAmount.SetFilter("Starting Date", '<=%1', StartingDate);
        VATTransactionReportAmount.FindLast();

        if InclVAT then
            Amount := VATTransactionReportAmount."Threshold Amount Incl. VAT"
        else
            Amount := VATTransactionReportAmount."Threshold Amount Excl. VAT";
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetFilter("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindSet();
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; IncludeInVATTransacRep: Boolean): Boolean
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '''''');
        VATPostingSetup.SetRange("VAT %", LibraryVATUtils.FindMaxVATRate(VATPostingSetup."VAT Calculation Type"::"Normal VAT"));
        VATPostingSetup.SetRange("Include in VAT Transac. Rep.", IncludeInVATTransacRep);
        VATPostingSetup.SetRange("Deductible %", 100);
        exit(VATPostingSetup.FindFirst())
    end;

    local procedure MakeOrderSales(var SalesHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header")
    var
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";
    begin
        BlanketSalesOrderToOrder.Run(SalesHeader);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesOrderHeader);
    end;

    local procedure PostSalesPrepInvoice(SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        SalesPostPrepayments.Invoice(SalesHeader);
        SalesInvHeader.SetRange("Prepayment Order No.", SalesHeader."No.");
        SalesInvHeader.FindFirst();
        exit(SalesInvHeader."No.");
    end;

    local procedure SetupThresholdAmount(StartingDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATTransRepAmount: Record "VAT Transaction Report Amount";
        ThresholdAmount: Decimal;
        VATRate: Decimal;
    begin
        // Law States Threshold Incl. VAT as 3600 and Threshold Excl. VAT as 3000.
        // For test purpose Threshold Excl. VAT is generated randomly in 1000..10000 range.
        CreateVATTransReportAmount(VATTransRepAmount, StartingDate);
        VATRate := LibraryVATUtils.FindMaxVATRate(VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        ThresholdAmount := 1000 * LibraryRandom.RandInt(10);
        VATTransRepAmount.Validate("Threshold Amount Incl. VAT", ThresholdAmount * (1 + VATRate / 100));
        VATTransRepAmount.Validate("Threshold Amount Excl. VAT", ThresholdAmount);

        VATTransRepAmount.Modify(true);
    end;

    local procedure SetupPrepayments()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Include in VAT Transac. Rep.", true);
        VATPostingSetup.FindFirst();
        VATPostingSetup.Validate("Sales Prepayments Account", CreateGLAccount("General Posting Type"::" "));
        VATPostingSetup.Validate("Purch. Prepayments Account", CreateGLAccount("General Posting Type"::" "));
        VATPostingSetup.Modify(true);
    end;

    local procedure VerifyContractNo(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Base: Decimal; ContractNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange(Base, Base);
        VATEntry.FindSet();
        repeat
            VATEntry.TestField("Contract No.", ContractNo);
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyIncludeVAT(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; InclInVATTransRep: Boolean)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, DocumentType, DocumentNo);
        repeat
            VATEntry.TestField("Include in VAT Transac. Rep.", InclInVATTransRep);
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyRefersToPeriod(TableID: Option; DocumentNo: Code[20]; RefersToPeriod: Option)
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        VATEntry: Record "VAT Entry";
    begin
        case TableID of
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader.Get(DocumentNo);
                    SalesCrMemoHeader.TestField("Refers to Period", RefersToPeriod);
                end;
            DATABASE::"Purch. Cr. Memo Hdr.":
                begin
                    PurchCrMemoHeader.Get(DocumentNo);
                    PurchCrMemoHeader.TestField("Refers to Period", RefersToPeriod);
                end;
            DATABASE::"Sales Cr.Memo Line":
                begin
                    SalesCrMemoLine.SetRange("Document No.", DocumentNo);
                    SalesCrMemoLine.FindFirst();
                    SalesCrMemoLine.TestField("Refers to Period", RefersToPeriod);
                end;
            DATABASE::"Purch. Cr. Memo Line":
                begin
                    PurchCrMemoLine.SetRange("Document No.", DocumentNo);
                    PurchCrMemoLine.FindFirst();
                    PurchCrMemoLine.TestField("Refers to Period", RefersToPeriod);
                end;
        end;

        FindVATEntry(VATEntry, VATEntry."Document Type"::"Credit Memo", DocumentNo);
        repeat
            VATEntry.TestField("Refers To Period", RefersToPeriod);
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyTaxRep(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; TaxRepType: Option; TaxRepNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, DocumentType, DocumentNo);
        repeat
            VATEntry.TestField("Tax Representative Type", TaxRepType);
            VATEntry.TestField("Tax Representative No.", TaxRepNo);
        until VATEntry.Next() = 0;
    end;

    local procedure TearDown()
    var
        VATTransRepAmount: Record "VAT Transaction Report Amount";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Include in VAT Transac. Rep.", true);
        VATPostingSetup.ModifyAll("Sales Prepayments Account", '', true);
        VATPostingSetup.ModifyAll("Purch. Prepayments Account", '', true);
        VATPostingSetup.ModifyAll("Include in VAT Transac. Rep.", false, true);

        VATPostingSetup.Reset();
        VATPostingSetup.SetFilter("Unrealized VAT Type", '<>%1', VATPostingSetup."Unrealized VAT Type"::" ");
        VATPostingSetup.ModifyAll("Sales VAT Unreal. Account", '', true);
        VATPostingSetup.ModifyAll("Purch. VAT Unreal. Account", '', true);
        VATPostingSetup.ModifyAll("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ", true);

        VATTransRepAmount.DeleteAll(true);
        EnableUnrealizedVAT(false);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Just for Handle the Message.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure BillToCustomerNoChangeConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := true;
        LibraryVariableStorage.AssertEmpty();
    end;
}

