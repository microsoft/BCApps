codeunit 144011 "Prepayment Sales"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Prepayment]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        ValueNotExistMsg: Label 'Value must not exist';

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceWithPrepaymentIncludeTax()
    var
        SalesHeader: Record "Sales Header";
        TaxGroup: Record "Tax Group";
        LineGLAccount: Record "G/L Account";
        DocumentNo: Code[20];
        ItemNo: Code[20];
        PrepaymentAmount: Decimal;
        TaxAreaCode: Code[20];
        SalesPrepaymentsAccNo: Code[20];
    begin
        // Setup: Create Tax Area with Detail, Create Item with Tax Group Code. Create and Update Sales Order with Prepmt. Include Tax.
        TaxAreaCode := CreateTaxAreaWithDetail(TaxGroup);
        SalesPrepaymentsAccNo := CreatePrepaymentVATSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount, TaxGroup.Code);
        CreateSalesOrder(SalesHeader, ItemNo, LineGLAccount, true, true, TaxAreaCode, TaxGroup.Code);  // Tax Liable and Prepmt. Include Tax - TRUE.
        DocumentNo := GetPostedDocumentNo(SalesHeader."Posting No. Series");

        // Exercise: Post Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Verify: Verify that correct G/L Entry and Customer Ledger Entry is created when posting Prepayment Invoice with Prepmt. Include Tax. Verify Tax Liable and Prepayment as TRUE.
        SalesHeader.CalcFields("Amount Including VAT");
        PrepaymentAmount := Round(SalesHeader."Amount Including VAT" * SalesHeader."Prepayment %" / 100);
        VerifyGLEntry(
          DocumentNo, SalesHeader."Document Type"::Invoice, SalesPrepaymentsAccNo, -PrepaymentAmount,
          SalesHeader."Tax Area Code", TaxGroup.Code, true);
        VerifyCustomerLedgerEntry(
          SalesHeader."Sell-to Customer No.", SalesHeader."Document Type"::Invoice, DocumentNo, PrepaymentAmount, PrepaymentAmount, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderPostPrepmtInvoicePrepmtIncludeTax()
    var
        SalesHeader: Record "Sales Header";
        TaxGroup: Record "Tax Group";
        LineGLAccount: Record "G/L Account";
        DocumentNo: Code[20];
        ItemNo: Code[20];
        PrepaymentAmount: Decimal;
        TaxAreaCode: Code[20];
        AmountIncludingVAT: Decimal;
        SalesPrepaymentsAccNo: Code[20];
    begin
        // Setup: Create Tax Area with Detail, Create Item with Tax Group Code. Create and Update Sales Order with Prepmt. Include Tax.
        TaxAreaCode := CreateTaxAreaWithDetail(TaxGroup);
        SalesPrepaymentsAccNo := CreatePrepaymentVATSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount, TaxGroup.Code);
        CreateSalesOrder(SalesHeader, ItemNo, LineGLAccount, true, true, TaxAreaCode, TaxGroup.Code);  // Tax Liable and Prepmt. Include Tax - TRUE.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);  // Post Prepayment Invoice.
        SalesHeader.CalcFields("Amount Including VAT");

        // Taking values from Sales Header for verification after posting.
        AmountIncludingVAT := SalesHeader."Amount Including VAT";
        PrepaymentAmount := Round(AmountIncludingVAT * SalesHeader."Prepayment %" / 100);

        // Exercise: Post Sales Order as Ship and Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify that correct G/L Entry and Customer Ledger Entry is created when posting full Prepayment Invoice with Prepmt. Include Tax after posting Sales Document.
        VerifyGLEntry(DocumentNo, SalesHeader."Document Type"::Invoice, SalesPrepaymentsAccNo, PrepaymentAmount, '', '', false);  // Tax Liable - FALSE.
        VerifyCustomerLedgerEntry(
          SalesHeader."Sell-to Customer No.", SalesHeader."Document Type"::Invoice, DocumentNo,
          AmountIncludingVAT - PrepaymentAmount, AmountIncludingVAT - PrepaymentAmount, false);  // Prepayment - FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderPostPartialPrepmtInvoicePrepmtIncludeTax()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        LineGLAccount: Record "G/L Account";
        DocumentNo: Code[20];
        ItemNo: Code[20];
        TaxAreaCode: Code[20];
        SalesPrepaymentsAccNo: Code[20];
    begin
        // [SCENARIO] Partial posting of Sales Invoice with Prepmt. Include Tax
        // [GIVEN] Create Tax Area with Detail, Create Item with Tax Group Code.
        // [GIVEN] Create and Update Sales Order with Prepmt. Include Tax.
        // [GIVEN] Update Qty to Ship on Sales Line with a half of Quantity
        TaxAreaCode := CreateTaxAreaWithDetail(TaxGroup);
        SalesPrepaymentsAccNo := CreatePrepaymentVATSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount, TaxGroup.Code);
        CreateSalesOrder(SalesHeader, ItemNo, LineGLAccount, true, true, TaxAreaCode, TaxGroup.Code);  // Tax Liable and Prepmt. Include Tax - TRUE.
        UpdateQuantityToShipOnSalesLine(SalesLine, SalesHeader."No.");  // Partial Quantity to Ship.

        // [GIVEN] Post partial Prepayment Invoice and Release Sales Order.
        PostPrepaymentInvoiceAndReleaseSalesOrder(SalesHeader);

        // [WHEN] Post Sales Order as Ship and Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Correct G/L Entry is created when posting Sales Order after posting partial Prepayment Invoice with Prepmt. Include Tax.
        // [THEN] G/L Entry for Sales Prepayment Account has a half of prepayment amount
        SalesHeader.CalcFields("Amount Including VAT");
        VerifyGLEntry(
          DocumentNo, SalesHeader."Document Type"::Invoice, SalesPrepaymentsAccNo,
          Round(SalesHeader."Amount Including VAT" * SalesHeader."Prepayment %" / 100 / 2), '', '', false);  // Tax Liable - FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderPartialPrepmtInvoiceWithoutPrepmtIncludeTax()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        LineGLAccount: Record "G/L Account";
        DocumentNo: Code[20];
        ItemNo: Code[20];
        TaxAreaCode: Code[20];
        SalesPrepaymentsAccNo: Code[20];
    begin
        // Setup: Create Tax Area with Detail, Create Item with Tax Group Code. Create and Update Sales Order without Prepmt. Include Tax. Update Qty to Ship on Sales Line.
        TaxAreaCode := CreateTaxAreaWithDetail(TaxGroup);
        SalesPrepaymentsAccNo := CreatePrepaymentVATSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount, TaxGroup.Code);
        CreateSalesOrder(SalesHeader, ItemNo, LineGLAccount, false, false, TaxAreaCode, TaxGroup.Code);  // Tax Liable and Prepmt. Include Tax - FALSE.
        UpdateQuantityToShipOnSalesLine(SalesLine, SalesHeader."No.");  // Partial Quantity to Ship.

        // Post partial Prepayment Invoice and Release Sales Order.
        PostPrepaymentInvoiceAndReleaseSalesOrder(SalesHeader);

        // Exercise: Post Sales Order as Ship and Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify that correct G/L Entry is created when posting Sales Order after posting partial Prepayment Invoice without Prepmt. Include Tax.
        SalesHeader.CalcFields(Amount);
        VerifyGLEntry(
          DocumentNo, SalesHeader."Document Type"::Invoice, SalesPrepaymentsAccNo,
          Round(SalesHeader.Amount * SalesHeader."Prepayment %" / 100) / 2, '', '', false);  // Tax Liable - FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPrepmtCreditMemoWithoutPrepmtIncludeTax()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        LineGLAccount: Record "G/L Account";
        ItemNo: Code[20];
        TaxAreaCode: Code[20];
        PostedCreditMemoNo: Code[20];
        SalesPrepaymentsAccNo: Code[20];
    begin
        // Setup: Create Tax Area with Detail, Create Item with Tax Group Code. Create and Update Sales Order without Prepmt. Include Tax. Update Qty to Ship on Sales Line.
        TaxAreaCode := CreateTaxAreaWithDetail(TaxGroup);
        SalesPrepaymentsAccNo := CreatePrepaymentVATSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount, TaxGroup.Code);
        CreateSalesOrder(SalesHeader, ItemNo, LineGLAccount, false, false, TaxAreaCode, TaxGroup.Code);  // Tax Liable and Prepmt. Include Tax - FALSE.
        UpdateQuantityToShipOnSalesLine(SalesLine, SalesHeader."No.");  // Partial Quantity to Ship.
        PostedCreditMemoNo := GetPostedDocumentNo(SalesHeader."Prepmt. Cr. Memo No. Series");

        // Post partial Prepayment Invoice and Release Sales Order.
        PostPrepaymentInvoiceAndReleaseSalesOrder(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Exercise: Post Prepayment Credit Memo.
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);

        // Verify: Verify that correct G/L Entry is created when posting partial Prepayment Credit Memo without Prepmt. Include Tax.
        SalesHeader.CalcFields(Amount);
        VerifyGLEntry(
          PostedCreditMemoNo, SalesHeader."Document Type"::"Credit Memo", SalesPrepaymentsAccNo,
          Round(SalesHeader.Amount * SalesHeader."Prepayment %" / 100) / 2, SalesHeader."Tax Area Code", TaxGroup.Code, false);  // Tax Liable - FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesOrderPrepmtInvoiceWithoutPrepmtIncludeTax()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesTaxAmountDifference: Record "Sales Tax Amount Difference";
        TaxGroup: Record "Tax Group";
        LineGLAccount: Record "G/L Account";
        ItemNo: Code[20];
        TaxAreaCode: Code[20];
    begin
        // Setup: Create Tax Area with Detail, Create Item with Tax Group Code. Create and Update Sales Order with Prepmt. Include Tax. Update Qty to Ship on Sales Line.
        TaxAreaCode := CreateTaxAreaWithDetail(TaxGroup);
        CreatePrepaymentVATSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount, TaxGroup.Code);
        CreateSalesOrder(SalesHeader, ItemNo, LineGLAccount, false, false, TaxAreaCode, TaxGroup.Code);  // Tax Liable and Prepmt. Include Tax - FALSE.
        UpdateQuantityToShipOnSalesLine(SalesLine, SalesHeader."No.");  // Partial Quantity to Ship.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        UpdatePrepaymentLineAmountOnSalesLine(SalesLine, 0);  // Update Prepayment Line Amount to Zero for Pending Prepayment.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Exercise: Delete Sales Order.
        SalesHeader.Delete(true);

        // Verify: Verify that Sales Order and Sales Tax Amount Difference does not exist after deleting Sales Order.
        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No."), ValueNotExistMsg);
        Assert.IsFalse(
          SalesTaxAmountDifference.Get(
            SalesTaxAmountDifference."Document Product Area"::Sales, SalesHeader."Document Type", SalesHeader."No."), ValueNotExistMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentCreditMemoWithPrepaymentIncludeTax()
    var
        SalesHeader: Record "Sales Header";
        TaxGroup: Record "Tax Group";
        LineGLAccount: Record "G/L Account";
        DocumentNo: Code[20];
        PostedCreditMemoNo: Code[20];
        ItemNo: Code[20];
        PrepaymentAmount: Decimal;
        TaxAreaCode: Code[20];
        SalesPrepaymentsAccNo: Code[20];
    begin
        // Setup: Create Tax Area with Detail, Create Item with Tax Group Code. Create and Update Sales Order with Prepmt. Include Tax.
        TaxAreaCode := CreateTaxAreaWithDetail(TaxGroup);
        SalesPrepaymentsAccNo := CreatePrepaymentVATSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount, TaxGroup.Code);
        CreateSalesOrder(SalesHeader, ItemNo, LineGLAccount, true, true, TaxAreaCode, TaxGroup.Code);  // Tax Liable and Prepmt. Include Tax - TRUE.
        DocumentNo := GetPostedDocumentNo(SalesHeader."Posting No. Series");
        PostedCreditMemoNo := GetPostedDocumentNo(SalesHeader."Prepmt. Cr. Memo No. Series");

        // Exercise: Post Prepayment Invoice and Prepayment Credit Memo.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);

        // Verify: Verify that correct G/L Entries are created when posting Prepayment Invoice and Prepayment Credit Memo with Prepmt. Include Tax. Verify Tax Liable as TRUE.
        SalesHeader.CalcFields("Amount Including VAT");
        PrepaymentAmount := Round(SalesHeader."Amount Including VAT" * SalesHeader."Prepayment %" / 100);
        VerifyGLEntry(
          DocumentNo, SalesHeader."Document Type"::Invoice, SalesPrepaymentsAccNo, -PrepaymentAmount,
          SalesHeader."Tax Area Code", TaxGroup.Code, true);
        VerifyGLEntry(
          PostedCreditMemoNo, SalesHeader."Document Type"::"Credit Memo", SalesPrepaymentsAccNo, PrepaymentAmount,
          SalesHeader."Tax Area Code", TaxGroup.Code, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentCreditMemoWithoutPrepaymentIncludeTax()
    var
        SalesHeader: Record "Sales Header";
        TaxGroup: Record "Tax Group";
        LineGLAccount: Record "G/L Account";
        DocumentNo: Code[20];
        PostedCreditMemoNo: Code[20];
        ItemNo: Code[20];
        PrepaymentAmount: Decimal;
        TaxAreaCode: Code[20];
        SalesPrepaymentsAccNo: Code[20];
    begin
        // Setup: Create Tax Area with Detail, Create Item with Tax Group Code. Create and Update Sales Order with Prepmt. Include Tax.
        TaxAreaCode := CreateTaxAreaWithDetail(TaxGroup);
        SalesPrepaymentsAccNo := CreatePrepaymentVATSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount, TaxGroup.Code);
        CreateSalesOrder(SalesHeader, ItemNo, LineGLAccount, false, false, TaxAreaCode, TaxGroup.Code);  // Tax Liable and Prepmt. Include Tax - FALSE.
        DocumentNo := GetPostedDocumentNo(SalesHeader."Posting No. Series");
        PostedCreditMemoNo := GetPostedDocumentNo(SalesHeader."Prepmt. Cr. Memo No. Series");

        // Exercise: Post Prepayment Invoice and Prepayment Credit Memo.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);

        // Verify: Verify that correct G/L Entries are created when posting Prepayment Invoice and Prepayment Credit Memo without Prepmt. Include Tax. Verify Tax Liable as FALSE.
        SalesHeader.CalcFields(Amount);
        PrepaymentAmount := Round(SalesHeader.Amount * SalesHeader."Prepayment %" / 100);
        VerifyGLEntry(
          DocumentNo, SalesHeader."Document Type"::Invoice, SalesPrepaymentsAccNo, -PrepaymentAmount,
          SalesHeader."Tax Area Code", TaxGroup.Code, false);
        VerifyGLEntry(
          PostedCreditMemoNo, SalesHeader."Document Type"::"Credit Memo", SalesPrepaymentsAccNo, PrepaymentAmount,
          SalesHeader."Tax Area Code", TaxGroup.Code, false);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20]; PrepmtIncludeTax: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomerNo);
        SalesHeader.Validate("Prepmt. Include Tax", PrepmtIncludeTax);
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; No: Code[20]; TaxGroupCode: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Tax Area Code", SalesHeader."Tax Area Code");
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LineGLAccount: Record "G/L Account"; TaxLiable: Boolean; PrepmtIncludeTax: Boolean; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, CreateCustomer(LineGLAccount, TaxLiable, TaxAreaCode), PrepmtIncludeTax);
        CreateSalesLine(SalesLine, SalesHeader, ItemNo, TaxGroupCode);
    end;

    local procedure CreateCustomer(LineGLAccount: Record "G/L Account"; TaxLiable: Boolean; TaxAreaCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Customer.Validate("Tax Liable", TaxLiable);
        Customer.Validate("Tax Area Code", TaxAreaCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(var Item: Record Item; TaxGroupCode: Code[20]; LineGLAccount: Record "G/L Account")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Validate("Gen. Prod. Posting Group", LineGLAccount."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Modify(true);
    end;

    local procedure CreateItemWithPostingSetup(LineGLAccount: Record "G/L Account"; TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        CreateItem(Item, TaxGroupCode, LineGLAccount);
        exit(Item."No.");
    end;

    local procedure CreatePrepaymentVATSetup(var LineGLAccount: Record "G/L Account"): Code[20]
    var
        PrepmtGLAccount: Record "G/L Account";
    begin
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount, PrepmtGLAccount, LineGLAccount."Gen. Posting Type"::Sale,
          "Tax Calculation Type"::"Sales Tax", "Tax Calculation Type"::"Sales Tax");
        exit(PrepmtGLAccount."No.");
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure GetPostedDocumentNo(NoSeries: Code[20]): Code[20]
    var
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        exit(NoSeriesCodeunit.PeekNextNo(NoSeries));  // Required for Prepayment Invoice and Prepayment Credit Memo.
    end;

    local procedure PostPrepaymentInvoiceAndReleaseSalesOrder(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure UpdateQuantityToShipOnSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.FindFirst();
        SalesLine.Validate("Qty. to Ship", SalesLine."Qty. to Ship" / 2);  // Partial Qty To Ship.
        SalesLine.Modify(true);
    end;

    local procedure UpdatePrepaymentLineAmountOnSalesLine(var SalesLine: Record "Sales Line"; PrepmtLineAmount: Decimal)
    begin
        SalesLine.Validate("Prepmt. Line Amount", PrepmtLineAmount);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesTaxJurisdiction(var TaxJurisdiction: Record "Tax Jurisdiction")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateGLAccount(GLAccount);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxJurisdiction.Modify(true);
    end;

    local procedure CreateTaxGroupWithDetail(var TaxGroup: Record "Tax Group"; var TaxDetail: Record "Tax Detail"; TaxJurisdictionCode: Code[10])
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroup.Code, TaxDetail."Tax Type"::"Sales Tax Only", WorkDate());
    end;

    local procedure CreateTaxAreaWithDetail(var TaxGroup: Record "Tax Group"): Code[20]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
        TaxAreaLine: Record "Tax Area Line";
        TaxArea: Record "Tax Area";
    begin
        LibraryERM.CreateTaxArea(TaxArea);
        CreateSalesTaxJurisdiction(TaxJurisdiction);
        CreateTaxGroupWithDetail(TaxGroup, TaxDetail, TaxJurisdiction.Code);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxJurisdiction.Code);
        exit(TaxAreaLine."Tax Area");
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type"; GLAccountNo: Code[20]; Amount: Decimal; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, GLAccountNo);
        GLEntry.TestField(Amount, Amount);
        GLEntry.TestField("Document Type", DocumentType);
        GLEntry.TestField("Tax Area Code", TaxAreaCode);
        GLEntry.TestField("Tax Group Code", TaxGroupCode);
        GLEntry.TestField("Tax Liable", TaxLiable);
    end;

    local procedure VerifyCustomerLedgerEntry(CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; Amount: Decimal; RemainingAmount: Decimal; Prepayment: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount, "Remaining Amount");
        CustLedgerEntry.TestField(Amount, Amount);
        CustLedgerEntry.TestField("Remaining Amount", RemainingAmount);
        CustLedgerEntry.TestField(Prepayment, Prepayment);
    end;
}

