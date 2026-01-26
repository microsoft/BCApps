codeunit 141044 "APAC - Page & Controls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UI]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesTaxInvoices()
    var
        SalesTaxInvoiceHeader: Record "Sales Tax Invoice Header";
        PostedSalesTaxInvoices: TestPage "Posted Sales Tax Invoices";
        PostedSalesTaxInvoice: TestPage "Posted Sales Tax Invoice";
    begin
        // [FEATURE] [UT] [Tax] [Sales] [Invoice]
        // [SCENARIO 325922] Stan can view "Posted Sales Tax Invoices" list page and can open card page "Posted Sales Tax Invoice" from it
        SalesTaxInvoiceHeader.Init();
        SalesTaxInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesTaxInvoiceHeader.Insert();

        PostedSalesTaxInvoices.OpenView();
        PostedSalesTaxInvoices.FILTER.SetFilter("No.", SalesTaxInvoiceHeader."No.");

        PostedSalesTaxInvoice.Trap();
        PostedSalesTaxInvoices.Edit().Invoke();

        PostedSalesTaxInvoice."No.".AssertEquals(SalesTaxInvoiceHeader."No.");

        PostedSalesTaxInvoice.Close();
        PostedSalesTaxInvoices.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesTaxCreditMemos()
    var
        SalesTaxCrMemoHeader: Record "Sales Tax Cr.Memo Header";
        PostedSalesTaxCrMemos: TestPage "Posted Sales Tax Cr. Memos";
        PostedSalesTaxCreditMemo: TestPage "Posted Sales Tax Credit Memo";
    begin
        // [FEATURE] [UT] [Tax] [Sales] [Credit Memo]
        // [SCENARIO 325922] Stan can view "Posted Sales Tax Cr. Memos" list page and can open "Posted Sales Tax Credit Memo" card page from it
        SalesTaxCrMemoHeader.Init();
        SalesTaxCrMemoHeader."No." := LibraryUtility.GenerateGUID();
        SalesTaxCrMemoHeader.Insert();

        PostedSalesTaxCrMemos.OpenView();
        PostedSalesTaxCrMemos.FILTER.SetFilter("No.", SalesTaxCrMemoHeader."No.");

        PostedSalesTaxCreditMemo.Trap();
        PostedSalesTaxCrMemos.Edit().Invoke();

        PostedSalesTaxCreditMemo."No.".AssertEquals(SalesTaxCrMemoHeader."No.");

        PostedSalesTaxCreditMemo.Close();
        PostedSalesTaxCrMemos.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseTaxInvoices()
    var
        PurchTaxInvHeader: Record "Purch. Tax Inv. Header";
        PostedPurchTaxInvoices: TestPage "Posted Purch. Tax Invoices";
        PostedPurchaseTaxInvoice: TestPage "Posted Purchase Tax Invoice";
    begin
        // [FEATURE] [UT] [Tax] [Purchases] [Invoice]
        // [SCENARIO 325922] Stan can view "Posted Purch. Tax Invoices" list page and can open "Posted Purchase Tax Invoice" card page from it
        PurchTaxInvHeader.Init();
        PurchTaxInvHeader."No." := LibraryUtility.GenerateGUID();
        PurchTaxInvHeader.Insert();

        PostedPurchTaxInvoices.OpenView();
        PostedPurchTaxInvoices.FILTER.SetFilter("No.", PurchTaxInvHeader."No.");

        PostedPurchaseTaxInvoice.Trap();
        PostedPurchTaxInvoices.Edit().Invoke();

        PostedPurchaseTaxInvoice."No.".AssertEquals(PurchTaxInvHeader."No.");

        PostedPurchaseTaxInvoice.Close();
        PostedPurchTaxInvoices.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseTaxCreditMemos()
    var
        PurchTaxCrMemoHdr: Record "Purch. Tax Cr. Memo Hdr.";
        PostedPurchTaxCrMemos: TestPage "Posted Purch. Tax Cr. Memos";
        PostedPurchTaxCreditMemo: TestPage "Posted Purch. Tax  Credit Memo";
    begin
        // [FEATURE] [UT] [Tax] [Purchases] [Credit Memo]
        // [SCENARIO 325922] Stan can view "Posted Purch. Tax Cr. Memos" list page and can open "Posted Purch. Tax. Credit Memo" card page from it
        PurchTaxCrMemoHdr.Init();
        PurchTaxCrMemoHdr."No." := LibraryUtility.GenerateGUID();
        PurchTaxCrMemoHdr.Insert();

        PostedPurchTaxCrMemos.OpenView();
        PostedPurchTaxCrMemos.FILTER.SetFilter("No.", PurchTaxCrMemoHdr."No.");

        PostedPurchTaxCreditMemo.Trap();
        PostedPurchTaxCrMemos.Edit().Invoke();

        PostedPurchTaxCreditMemo."No.".AssertEquals(PurchTaxCrMemoHdr."No.");

        PostedPurchTaxCreditMemo.Close();
        PostedPurchTaxCrMemos.Close();
    end;
}

