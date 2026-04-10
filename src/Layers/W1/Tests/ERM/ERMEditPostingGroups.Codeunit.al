codeunit 134069 "ERM Edit Posting Groups"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Posting Group]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        TestFieldCodeErr: Label 'TestField';
        AccountCategory: Option ,Assets,Liabilities,Equity,Income,"Cost of Goods Sold",Expense;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCustomerPostingGroupListInvRounding()
    var
        CustomerPostingGroups: TestPage "Customer Posting Groups";
    begin
        Initialize();

        // Invoice rounding account
        LibrarySales.SetInvoiceRounding(false);
        CustomerPostingGroups.OpenView();
        Assert.AreEqual(CustomerPostingGroups."Invoice Rounding Account".Visible(), false, 'Invoice rounding off');
        CustomerPostingGroups.Close();

        LibrarySales.SetInvoiceRounding(true);
        CustomerPostingGroups.OpenView();
        Assert.AreEqual(CustomerPostingGroups."Invoice Rounding Account".Visible(), true, 'Invoice rounding on');
        CustomerPostingGroups.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCustomerPostingGroupListPmtDiscount()
    var
        PaymentTerms: Record "Payment Terms";
        CustomerPostingGroups: TestPage "Customer Posting Groups";
    begin
        Initialize();

        // Payment discount accounts
        PaymentTerms.SetFilter("Discount %", '<>%1', 0);
        PaymentTerms.DeleteAll();
        CustomerPostingGroups.OpenView();
        Assert.AreEqual(CustomerPostingGroups."Payment Disc. Debit Acc.".Visible(), false, 'Payment discount off');
        Assert.AreEqual(CustomerPostingGroups."Payment Disc. Credit Acc.".Visible(), false, 'Payment discount off');
        CustomerPostingGroups.Close();

        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        CustomerPostingGroups.OpenView();
        Assert.AreEqual(CustomerPostingGroups."Payment Disc. Debit Acc.".Visible(), true, 'Payment discount on');
        Assert.AreEqual(CustomerPostingGroups."Payment Disc. Credit Acc.".Visible(), true, 'Payment discount on');
        CustomerPostingGroups.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCustomerPostingGroupListPmtTolerance()
    var
        GLSetup: Record "General Ledger Setup";
        CustomerPostingGroups: TestPage "Customer Posting Groups";
    begin
        Initialize();

        // Payment tolerance accounts
        GLSetup.Get();
        CustomerPostingGroups.OpenView();
        Assert.AreEqual(
          CustomerPostingGroups."Payment Tolerance Debit Acc.".Visible(), GLSetup."Payment Tolerance %" <> 0,
          'Payment tolerance');
        Assert.AreEqual(
          CustomerPostingGroups."Payment Tolerance Credit Acc.".Visible(), GLSetup."Payment Tolerance %" <> 0,
          'Payment tolerance');
        CustomerPostingGroups.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCustomerPostingGroupListCurrAppln()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        CustomerPostingGroups: TestPage "Customer Posting Groups";
    begin
        Initialize();

        // Currency application accounts
        SalesSetup.Get();
        CustomerPostingGroups.OpenView();
        Assert.AreEqual(
          CustomerPostingGroups."Debit Curr. Appln. Rndg. Acc.".Visible(), SalesSetup."Appln. between Currencies" > 0,
          'Curr. application');
        Assert.AreEqual(
          CustomerPostingGroups."Credit Curr. Appln. Rndg. Acc.".Visible(), SalesSetup."Appln. between Currencies" > 0,
          'Curr. application');
        CustomerPostingGroups.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCustomerPostingGroupCardInvRounding()
    var
        CustomerPostingGroupCard: TestPage "Customer Posting Group Card";
    begin
        Initialize();

        // Invoice rounding account
        LibrarySales.SetInvoiceRounding(false);
        CustomerPostingGroupCard.OpenView();
        Assert.AreEqual(CustomerPostingGroupCard."Invoice Rounding Account".Visible(), false, 'Invoice rounding off');
        CustomerPostingGroupCard.Close();

        LibrarySales.SetInvoiceRounding(true);
        CustomerPostingGroupCard.OpenView();
        Assert.AreEqual(CustomerPostingGroupCard."Invoice Rounding Account".Visible(), true, 'Invoice rounding on');
        CustomerPostingGroupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCustomerPostingGroupCardPmtDiscount()
    var
        PaymentTerms: Record "Payment Terms";
        CustomerPostingGroupCard: TestPage "Customer Posting Group Card";
    begin
        Initialize();

        // Payment discount accounts
        PaymentTerms.SetFilter("Discount %", '<>%1', 0);
        PaymentTerms.DeleteAll();
        CustomerPostingGroupCard.OpenView();
        Assert.AreEqual(CustomerPostingGroupCard."Payment Disc. Debit Acc.".Visible(), false, 'Payment discount off');
        Assert.AreEqual(CustomerPostingGroupCard."Payment Disc. Credit Acc.".Visible(), false, 'Payment discount off');
        CustomerPostingGroupCard.Close();

        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        CustomerPostingGroupCard.OpenView();
        Assert.AreEqual(CustomerPostingGroupCard."Payment Disc. Debit Acc.".Visible(), true, 'Payment discount on');
        Assert.AreEqual(CustomerPostingGroupCard."Payment Disc. Credit Acc.".Visible(), true, 'Payment discount on');
        CustomerPostingGroupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCustomerPostingGroupCardPmtTolerance()
    var
        GLSetup: Record "General Ledger Setup";
        CustomerPostingGroupCard: TestPage "Customer Posting Group Card";
    begin
        Initialize();

        // Payment tolerance accounts
        GLSetup.Get();
        CustomerPostingGroupCard.OpenView();
        Assert.AreEqual(
          CustomerPostingGroupCard."Payment Tolerance Debit Acc.".Visible(), GLSetup."Payment Tolerance %" <> 0,
          'Payment tolerance');
        Assert.AreEqual(
          CustomerPostingGroupCard."Payment Tolerance Credit Acc.".Visible(), GLSetup."Payment Tolerance %" <> 0,
          'Payment tolerance');
        CustomerPostingGroupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCustomerPostingGroupCardCurrAppln()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        CustomerPostingGroupCard: TestPage "Customer Posting Group Card";
    begin
        Initialize();

        // Currency application accounts
        SalesSetup.Get();
        CustomerPostingGroupCard.OpenView();
        Assert.AreEqual(
          CustomerPostingGroupCard."Debit Curr. Appln. Rndg. Acc.".Visible(), SalesSetup."Appln. between Currencies" > 0,
          'Curr. application');
        Assert.AreEqual(
          CustomerPostingGroupCard."Credit Curr. Appln. Rndg. Acc.".Visible(), SalesSetup."Appln. between Currencies" > 0,
          'Curr. application');
        CustomerPostingGroupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVendorPostingGroupListInvRounding()
    var
        VendorPostingGroups: TestPage "Vendor Posting Groups";
    begin
        Initialize();

        // Invoice rounding account
        LibraryPurchase.SetInvoiceRounding(false);
        VendorPostingGroups.OpenView();
        Assert.AreEqual(VendorPostingGroups."Invoice Rounding Account".Visible(), false, 'Invoice rounding off');
        VendorPostingGroups.Close();

        LibraryPurchase.SetInvoiceRounding(true);
        VendorPostingGroups.OpenView();
        Assert.AreEqual(VendorPostingGroups."Invoice Rounding Account".Visible(), true, 'Invoice rounding on');
        VendorPostingGroups.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVendorPostingGroupListPmtDiscount()
    var
        PaymentTerms: Record "Payment Terms";
        VendorPostingGroups: TestPage "Vendor Posting Groups";
    begin
        Initialize();

        // Payment discount accounts
        PaymentTerms.SetFilter("Discount %", '<>%1', 0);
        PaymentTerms.DeleteAll();
        VendorPostingGroups.OpenView();
        Assert.AreEqual(VendorPostingGroups."Payment Disc. Debit Acc.".Visible(), false, 'Payment discount off');
        Assert.AreEqual(VendorPostingGroups."Payment Disc. Credit Acc.".Visible(), false, 'Payment discount off');
        VendorPostingGroups.Close();

        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        VendorPostingGroups.OpenView();
        Assert.AreEqual(VendorPostingGroups."Payment Disc. Debit Acc.".Visible(), true, 'Payment discount on');
        Assert.AreEqual(VendorPostingGroups."Payment Disc. Credit Acc.".Visible(), true, 'Payment discount on');
        VendorPostingGroups.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVendorPostingGroupListPmtTolerance()
    var
        GLSetup: Record "General Ledger Setup";
        VendorPostingGroups: TestPage "Vendor Posting Groups";
    begin
        Initialize();

        // Payment tolerance accounts
        GLSetup.Get();
        VendorPostingGroups.OpenView();
        Assert.AreEqual(
          VendorPostingGroups."Payment Tolerance Debit Acc.".Visible(), GLSetup."Payment Tolerance %" <> 0,
          'Payment tolerance');
        Assert.AreEqual(
          VendorPostingGroups."Payment Tolerance Credit Acc.".Visible(), GLSetup."Payment Tolerance %" <> 0,
          'Payment tolerance');
        VendorPostingGroups.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVendorPostingGroupListCurrAppln()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        VendorPostingGroups: TestPage "Vendor Posting Groups";
    begin
        Initialize();

        // Currency application accounts
        PurchSetup.Get();
        VendorPostingGroups.OpenView();
        Assert.AreEqual(
          VendorPostingGroups."Debit Curr. Appln. Rndg. Acc.".Visible(), PurchSetup."Appln. between Currencies" > 0,
          'Curr. application');
        Assert.AreEqual(
          VendorPostingGroups."Credit Curr. Appln. Rndg. Acc.".Visible(), PurchSetup."Appln. between Currencies" > 0,
          'Curr. application');
        VendorPostingGroups.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVendorPostingGroupCardInvRounding()
    var
        VendorPostingGroupCard: TestPage "Vendor Posting Group Card";
    begin
        Initialize();

        // Invoice rounding account
        LibraryPurchase.SetInvoiceRounding(false);
        VendorPostingGroupCard.OpenView();
        Assert.AreEqual(VendorPostingGroupCard."Invoice Rounding Account".Visible(), false, 'Invoice rounding off');
        VendorPostingGroupCard.Close();

        LibraryPurchase.SetInvoiceRounding(true);
        VendorPostingGroupCard.OpenView();
        Assert.AreEqual(VendorPostingGroupCard."Invoice Rounding Account".Visible(), true, 'Invoice rounding on');
        VendorPostingGroupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVendorPostingGroupCardPmtDiscount()
    var
        PaymentTerms: Record "Payment Terms";
        VendorPostingGroupCard: TestPage "Vendor Posting Group Card";
    begin
        Initialize();

        // Payment discount accounts
        PaymentTerms.SetFilter("Discount %", '<>%1', 0);
        PaymentTerms.DeleteAll();
        VendorPostingGroupCard.OpenView();
        Assert.AreEqual(VendorPostingGroupCard."Payment Disc. Debit Acc.".Visible(), false, 'Payment discount off');
        Assert.AreEqual(VendorPostingGroupCard."Payment Disc. Credit Acc.".Visible(), false, 'Payment discount off');
        VendorPostingGroupCard.Close();

        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        VendorPostingGroupCard.OpenView();
        Assert.AreEqual(VendorPostingGroupCard."Payment Disc. Debit Acc.".Visible(), true, 'Payment discount on');
        Assert.AreEqual(VendorPostingGroupCard."Payment Disc. Credit Acc.".Visible(), true, 'Payment discount on');
        VendorPostingGroupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVendorPostingGroupCardPmtTolerance()
    var
        GLSetup: Record "General Ledger Setup";
        VendorPostingGroupCard: TestPage "Vendor Posting Group Card";
    begin
        Initialize();

        // Payment tolerance accounts
        GLSetup.Get();
        VendorPostingGroupCard.OpenView();
        Assert.AreEqual(
          VendorPostingGroupCard."Payment Tolerance Debit Acc.".Visible(), GLSetup."Payment Tolerance %" <> 0,
          'Payment tolerance');
        Assert.AreEqual(
          VendorPostingGroupCard."Payment Tolerance Credit Acc.".Visible(), GLSetup."Payment Tolerance %" <> 0,
          'Payment tolerance');
        VendorPostingGroupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVendorPostingGroupCardCurrAppln()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        VendorPostingGroupCard: TestPage "Vendor Posting Group Card";
    begin
        Initialize();

        // Currency application accounts
        PurchSetup.Get();
        VendorPostingGroupCard.OpenView();
        Assert.AreEqual(
          VendorPostingGroupCard."Debit Curr. Appln. Rndg. Acc.".Visible(), PurchSetup."Appln. between Currencies" > 0,
          'Curr. application');
        Assert.AreEqual(
          VendorPostingGroupCard."Credit Curr. Appln. Rndg. Acc.".Visible(), PurchSetup."Appln. between Currencies" > 0,
          'Curr. application');
        VendorPostingGroupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupListSalesLineDiscAccountVisible()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetup: TestPage "General Posting Setup";
    begin
        Initialize();

        SetSalesDiscountPosting(SalesSetup."Discount Posting"::"Line Discounts");

        GeneralPostingSetup.OpenView();
        Assert.AreEqual(GeneralPostingSetup."Sales Line Disc. Account".Visible(), true, 'Sales line discount');
        GeneralPostingSetup.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupListSalesLineDiscAccountHidden()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetup: TestPage "General Posting Setup";
    begin
        Initialize();

        SetSalesDiscountPosting(SalesSetup."Discount Posting"::"No Discounts");

        GeneralPostingSetup.OpenView();
        Assert.AreEqual(GeneralPostingSetup."Sales Line Disc. Account".Visible(), false, 'Sales line discount');
        GeneralPostingSetup.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupListSalesInvDiscAccountVisible()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetup: TestPage "General Posting Setup";
    begin
        Initialize();

        SetSalesDiscountPosting(SalesSetup."Discount Posting"::"Invoice Discounts");

        GeneralPostingSetup.OpenView();
        Assert.AreEqual(GeneralPostingSetup."Sales Inv. Disc. Account".Visible(), true, 'Sales invoice discount');
        GeneralPostingSetup.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupListSalesInvDiscAccountHidden()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetup: TestPage "General Posting Setup";
    begin
        Initialize();

        SetSalesDiscountPosting(SalesSetup."Discount Posting"::"No Discounts");

        GeneralPostingSetup.OpenView();
        Assert.AreEqual(GeneralPostingSetup."Sales Inv. Disc. Account".Visible(), false, 'Sales invoice discount');
        GeneralPostingSetup.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupListSalesPmtDiscAccountVisible()
    var
        PaymentTerms: Record "Payment Terms";
        GeneralPostingSetup: TestPage "General Posting Setup";
    begin
        Initialize();

        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        GeneralPostingSetup.OpenView();
        Assert.AreEqual(GeneralPostingSetup."Sales Pmt. Disc. Debit Acc.".Visible(), true, 'Sales payment discount');
        Assert.AreEqual(GeneralPostingSetup."Sales Pmt. Disc. Credit Acc.".Visible(), true, 'Sales payment discount');
        GeneralPostingSetup.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupListSalesPmtDiscAccountHidden()
    var
        PaymentTerms: Record "Payment Terms";
        GeneralPostingSetup: TestPage "General Posting Setup";
    begin
        Initialize();

        PaymentTerms.SetFilter("Discount %", '<>%1', 0);
        PaymentTerms.DeleteAll();
        GeneralPostingSetup.OpenView();
        Assert.AreEqual(GeneralPostingSetup."Sales Pmt. Disc. Debit Acc.".Visible(), false, 'Sales payment discount');
        Assert.AreEqual(GeneralPostingSetup."Sales Pmt. Disc. Credit Acc.".Visible(), false, 'Sales payment discount');
        GeneralPostingSetup.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupListSalesPmtTolAccount()
    var
        GLSetup: Record "General Ledger Setup";
        GeneralPostingSetup: TestPage "General Posting Setup";
    begin
        Initialize();

        GLSetup.Get();
        GeneralPostingSetup.OpenView();
        Assert.AreEqual(
          GeneralPostingSetup."Sales Pmt. Tol. Debit Acc.".Visible(), GLSetup."Payment Tolerance %" <> 0, 'Payment tolerance');
        Assert.AreEqual(
          GeneralPostingSetup."Sales Pmt. Tol. Credit Acc.".Visible(), GLSetup."Payment Tolerance %" <> 0, 'Payment tolerance');
        GeneralPostingSetup.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupListPurchLineDiscAccountVisible()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetup: TestPage "General Posting Setup";
    begin
        Initialize();

        SetPurchDiscountPosting(PurchSetup."Discount Posting"::"Line Discounts");

        GeneralPostingSetup.OpenView();
        Assert.AreEqual(GeneralPostingSetup."Purch. Line Disc. Account".Visible(), true, 'Purch. line discount');
        GeneralPostingSetup.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupListPurchLineDiscAccountHidden()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetup: TestPage "General Posting Setup";
    begin
        Initialize();

        SetPurchDiscountPosting(PurchSetup."Discount Posting"::"No Discounts");

        GeneralPostingSetup.OpenView();
        Assert.AreEqual(GeneralPostingSetup."Purch. Line Disc. Account".Visible(), false, 'Purch. line discount');
        GeneralPostingSetup.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupListPurchInvDiscAccountVisible()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetup: TestPage "General Posting Setup";
    begin
        Initialize();

        SetPurchDiscountPosting(PurchSetup."Discount Posting"::"Invoice Discounts");

        GeneralPostingSetup.OpenView();
        Assert.AreEqual(GeneralPostingSetup."Purch. Inv. Disc. Account".Visible(), true, 'Purch. invoice discount');
        GeneralPostingSetup.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupListPurchInvDiscAccountHidden()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetup: TestPage "General Posting Setup";
    begin
        Initialize();

        SetPurchDiscountPosting(PurchSetup."Discount Posting"::"No Discounts");

        GeneralPostingSetup.OpenView();
        Assert.AreEqual(GeneralPostingSetup."Purch. Inv. Disc. Account".Visible(), false, 'Purch. invoice discount');
        GeneralPostingSetup.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupListPurchPmtDiscAccountVisible()
    var
        PaymentTerms: Record "Payment Terms";
        GeneralPostingSetup: TestPage "General Posting Setup";
    begin
        Initialize();

        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        GeneralPostingSetup.OpenView();
        Assert.AreEqual(GeneralPostingSetup."Purch. Pmt. Disc. Debit Acc.".Visible(), true, 'Purch. payment discount');
        Assert.AreEqual(GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc.".Visible(), true, 'Purch. payment discount');
        GeneralPostingSetup.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupListPurchPmtDiscAccountHidden()
    var
        PaymentTerms: Record "Payment Terms";
        GeneralPostingSetup: TestPage "General Posting Setup";
    begin
        Initialize();

        PaymentTerms.SetFilter("Discount %", '<>%1', 0);
        PaymentTerms.DeleteAll();
        GeneralPostingSetup.OpenView();
        Assert.AreEqual(GeneralPostingSetup."Purch. Pmt. Disc. Debit Acc.".Visible(), false, 'Purch. payment discount');
        Assert.AreEqual(GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc.".Visible(), false, 'Purch. payment discount');
        GeneralPostingSetup.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupListPurchPmtTolAccount()
    var
        GLSetup: Record "General Ledger Setup";
        GeneralPostingSetup: TestPage "General Posting Setup";
    begin
        Initialize();

        GLSetup.Get();
        GeneralPostingSetup.OpenView();
        Assert.AreEqual(
          GeneralPostingSetup."Purch. Pmt. Tol. Debit Acc.".Visible(), GLSetup."Payment Tolerance %" <> 0, 'Payment tolerance');
        Assert.AreEqual(
          GeneralPostingSetup."Purch. Pmt. Tol. Credit Acc.".Visible(), GLSetup."Payment Tolerance %" <> 0, 'Payment tolerance');
        GeneralPostingSetup.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupCardSalesLineDiscAccountVisible()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetupCard: TestPage "General Posting Setup Card";
    begin
        Initialize();

        SetSalesDiscountPosting(SalesSetup."Discount Posting"::"Line Discounts");

        GeneralPostingSetupCard.OpenView();
        Assert.AreEqual(GeneralPostingSetupCard."Sales Line Disc. Account".Visible(), true, 'Sales line discount');
        GeneralPostingSetupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupCardSalesLineDiscAccountHidden()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetupCard: TestPage "General Posting Setup Card";
    begin
        Initialize();

        SetSalesDiscountPosting(SalesSetup."Discount Posting"::"No Discounts");

        GeneralPostingSetupCard.OpenView();
        Assert.AreEqual(GeneralPostingSetupCard."Sales Line Disc. Account".Visible(), false, 'Sales line discount');
        GeneralPostingSetupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupCardSalesInvDiscAccountVisible()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetupCard: TestPage "General Posting Setup Card";
    begin
        Initialize();

        SetSalesDiscountPosting(SalesSetup."Discount Posting"::"Invoice Discounts");

        GeneralPostingSetupCard.OpenView();
        Assert.AreEqual(GeneralPostingSetupCard."Sales Inv. Disc. Account".Visible(), true, 'Sales invoice discount');
        GeneralPostingSetupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupCardSalesInvDiscAccountHidden()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetupCard: TestPage "General Posting Setup Card";
    begin
        Initialize();

        SetSalesDiscountPosting(SalesSetup."Discount Posting"::"No Discounts");

        GeneralPostingSetupCard.OpenView();
        Assert.AreEqual(GeneralPostingSetupCard."Sales Inv. Disc. Account".Visible(), false, 'Sales invoice discount');
        GeneralPostingSetupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupCardSalesPmtDiscAccountVisible()
    var
        PaymentTerms: Record "Payment Terms";
        GeneralPostingSetupCard: TestPage "General Posting Setup Card";
    begin
        Initialize();

        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        GeneralPostingSetupCard.OpenView();
        Assert.AreEqual(GeneralPostingSetupCard."Sales Pmt. Disc. Debit Acc.".Visible(), true, 'Sales payment discount');
        Assert.AreEqual(GeneralPostingSetupCard."Sales Pmt. Disc. Credit Acc.".Visible(), true, 'Sales payment discount');
        GeneralPostingSetupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupCardSalesPmtDiscAccountHidden()
    var
        PaymentTerms: Record "Payment Terms";
        GeneralPostingSetupCard: TestPage "General Posting Setup Card";
    begin
        Initialize();

        PaymentTerms.SetFilter("Discount %", '<>%1', 0);
        PaymentTerms.DeleteAll();
        GeneralPostingSetupCard.OpenView();
        Assert.AreEqual(GeneralPostingSetupCard."Sales Pmt. Disc. Debit Acc.".Visible(), false, 'Sales payment discount');
        Assert.AreEqual(GeneralPostingSetupCard."Sales Pmt. Disc. Credit Acc.".Visible(), false, 'Sales payment discount');
        GeneralPostingSetupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupCardSalesPmtTolAccount()
    var
        GLSetup: Record "General Ledger Setup";
        GeneralPostingSetupCard: TestPage "General Posting Setup Card";
    begin
        Initialize();

        GLSetup.Get();
        GeneralPostingSetupCard.OpenView();
        Assert.AreEqual(
          GeneralPostingSetupCard."Sales Pmt. Tol. Debit Acc.".Visible(), GLSetup."Payment Tolerance %" <> 0, 'Payment tolerance');
        Assert.AreEqual(
          GeneralPostingSetupCard."Sales Pmt. Tol. Credit Acc.".Visible(), GLSetup."Payment Tolerance %" <> 0, 'Payment tolerance');
        GeneralPostingSetupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupCardPurchLineDiscAccountVisible()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetupCard: TestPage "General Posting Setup Card";
    begin
        Initialize();

        SetPurchDiscountPosting(PurchSetup."Discount Posting"::"Line Discounts");

        GeneralPostingSetupCard.OpenView();
        Assert.AreEqual(GeneralPostingSetupCard."Purch. Line Disc. Account".Visible(), true, 'Purch. line discount');
        GeneralPostingSetupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupCardPurchLineDiscAccountHidden()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetupCard: TestPage "General Posting Setup Card";
    begin
        Initialize();

        SetPurchDiscountPosting(PurchSetup."Discount Posting"::"No Discounts");

        GeneralPostingSetupCard.OpenView();
        Assert.AreEqual(GeneralPostingSetupCard."Purch. Line Disc. Account".Visible(), false, 'Purch. line discount');
        GeneralPostingSetupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupCardPurchInvDiscAccountVisible()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetupCard: TestPage "General Posting Setup Card";
    begin
        Initialize();

        SetPurchDiscountPosting(PurchSetup."Discount Posting"::"Invoice Discounts");

        GeneralPostingSetupCard.OpenView();
        Assert.AreEqual(GeneralPostingSetupCard."Purch. Inv. Disc. Account".Visible(), true, 'Purch. invoice discount');
        GeneralPostingSetupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupCardPurchInvDiscAccountHidden()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetupCard: TestPage "General Posting Setup Card";
    begin
        Initialize();

        SetPurchDiscountPosting(PurchSetup."Discount Posting"::"No Discounts");

        GeneralPostingSetupCard.OpenView();
        Assert.AreEqual(GeneralPostingSetupCard."Purch. Inv. Disc. Account".Visible(), false, 'Purch. invoice discount');
        GeneralPostingSetupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupCardPurchPmtDiscAccountVisible()
    var
        PaymentTerms: Record "Payment Terms";
        GeneralPostingSetupCard: TestPage "General Posting Setup Card";
    begin
        Initialize();

        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        GeneralPostingSetupCard.OpenView();
        Assert.AreEqual(GeneralPostingSetupCard."Purch. Pmt. Disc. Debit Acc.".Visible(), true, 'Purch. payment discount');
        Assert.AreEqual(GeneralPostingSetupCard."Purch. Pmt. Disc. Credit Acc.".Visible(), true, 'Purch. payment discount');
        GeneralPostingSetupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupCardPurchPmtDiscAccountHidden()
    var
        PaymentTerms: Record "Payment Terms";
        GeneralPostingSetupCard: TestPage "General Posting Setup Card";
    begin
        Initialize();

        PaymentTerms.SetFilter("Discount %", '<>%1', 0);
        PaymentTerms.DeleteAll();
        GeneralPostingSetupCard.OpenView();
        Assert.AreEqual(GeneralPostingSetupCard."Purch. Pmt. Disc. Debit Acc.".Visible(), false, 'Purch. payment discount');
        Assert.AreEqual(GeneralPostingSetupCard."Purch. Pmt. Disc. Credit Acc.".Visible(), false, 'Purch. payment discount');
        GeneralPostingSetupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingSetupCardPurchPmtTolAccount()
    var
        GLSetup: Record "General Ledger Setup";
        GeneralPostingSetupCard: TestPage "General Posting Setup Card";
    begin
        Initialize();

        GLSetup.Get();
        GeneralPostingSetupCard.OpenView();
        Assert.AreEqual(
          GeneralPostingSetupCard."Purch. Pmt. Tol. Debit Acc.".Visible(), GLSetup."Payment Tolerance %" <> 0, 'Payment tolerance');
        Assert.AreEqual(
          GeneralPostingSetupCard."Purch. Pmt. Tol. Credit Acc.".Visible(), GLSetup."Payment Tolerance %" <> 0, 'Payment tolerance');
        GeneralPostingSetupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVATPostingSetupListAdjustForPmtDisc()
    var
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: TestPage "VAT Posting Setup";
    begin
        Initialize();

        GLSetup.Get();
        VATPostingSetup.OpenView();
        Assert.AreEqual(
          VATPostingSetup."Adjust for Payment Discount".Visible(), GLSetup."Adjust for Payment Disc.", 'Adjust for Payment Disc.');
        VATPostingSetup.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVATPostingSetupCardAdjustForPmtDisc()
    var
        GLSetup: Record "General Ledger Setup";
        VATPostingSetupCard: TestPage "VAT Posting Setup Card";
    begin
        Initialize();

        GLSetup.Get();
        VATPostingSetupCard.OpenView();
        Assert.AreEqual(
          VATPostingSetupCard."Adjust for Payment Discount".Visible(), GLSetup."Adjust for Payment Disc.", 'Adjust for Payment Disc.');
        VATPostingSetupCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroupInterestAccountVisibleFinChargeTerms()
    var
        CustomerPostingGroups: TestPage "Customer Posting Groups";
        PostInterest: Boolean;
    begin
        // [FEATURE] [UI] [Late Payment Fee] [Customer Posting Groups] [Visibility]
        // [SCENARIO 254979] Column "Interest Account" is visible on page Customer Posting Groups when "Post Interest" = TRUE in Finance Charge Terms
        Initialize();
        DeleteAllReminderTermsAndFinanceChargeTerms();
        PostInterest := true;

        // [GIVEN] Create Finance Charge Terms with "Post Interest" = TRUE
        CreateFinanceChargeTermsWithPostInterest(PostInterest);

        // [WHEN] Open page Customer Posting Groups
        CustomerPostingGroups.OpenView();

        // [THEN] Column "Interest Account" is visible
        Assert.AreEqual(PostInterest, CustomerPostingGroups."Interest Account".Visible(), 'Column invisible');
        CustomerPostingGroups.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroupInterestAccountInvisibleFinChargeTerms()
    var
        CustomerPostingGroups: TestPage "Customer Posting Groups";
        PostInterest: Boolean;
    begin
        // [FEATURE] [UI] [Late Payment Fee] [Customer Posting Groups] [Visibility]
        // [SCENARIO 254979] Column "Interest Account" is invisible on page Customer Posting Groups when "Post Interest" = FALSE in Finance Charge Terms and there are no Reminder Terms with "Post Interest" = TRUE
        Initialize();
        DeleteAllReminderTermsAndFinanceChargeTerms();
        PostInterest := false;

        // [GIVEN] Create Finance Charge Terms with "Post Interest" = FALSE
        CreateFinanceChargeTermsWithPostInterest(PostInterest);

        // [WHEN] Open page Customer Posting Groups
        CustomerPostingGroups.OpenView();

        // [THEN] Column "Interest Account" is invisible
        Assert.AreEqual(PostInterest, CustomerPostingGroups."Interest Account".Visible(), 'Column visible');
        CustomerPostingGroups.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroupAdditionalFeeAccountVisibleFinChargeTerms()
    var
        CustomerPostingGroups: TestPage "Customer Posting Groups";
        PostAdditionalFee: Boolean;
    begin
        // [FEATURE] [UI] [Late Payment Fee] [Customer Posting Groups] [Visibility]
        // [SCENARIO 254979] Column "Additional Fee Account" is visible on page Customer Posting Groups when "Post Additional Fee" = TRUE in Finance Charge Terms
        Initialize();
        DeleteAllReminderTermsAndFinanceChargeTerms();
        PostAdditionalFee := true;

        // [GIVEN] Create Finance Charge Terms with "Post Additional Fee" = TRUE
        CreateFinanceChargeTermsWithPostAdditionalFee(PostAdditionalFee);

        // [WHEN] Open page Customer Posting Groups
        CustomerPostingGroups.OpenView();

        // [THEN] Column "Additional Fee Account" is visible
        Assert.AreEqual(PostAdditionalFee, CustomerPostingGroups."Additional Fee Account".Visible(), 'Column invisible');
        CustomerPostingGroups.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroupAdditionalFeeAccountInvisibleFinChargeTerms()
    var
        CustomerPostingGroups: TestPage "Customer Posting Groups";
        PostAdditionalFee: Boolean;
    begin
        // [FEATURE] [UI] [Late Payment Fee] [Customer Posting Groups] [Visibility]
        // [SCENARIO 254979] Column "Additional Fee Account" is invisible on page Customer Posting Groups when "Post Additional Fee" = FALSE in Finance Charge Terms and there are no Reminder Terms with "Post Additional Fee" = TRUE
        Initialize();
        DeleteAllReminderTermsAndFinanceChargeTerms();
        PostAdditionalFee := false;

        // [GIVEN] Create Finance Charge Terms with "Post Additional Fee" = FALSE
        CreateFinanceChargeTermsWithPostAdditionalFee(PostAdditionalFee);

        // [WHEN] Open page Customer Posting Groups
        CustomerPostingGroups.OpenView();

        // [THEN] Column "Additional Fee Account" is invisible
        Assert.AreEqual(PostAdditionalFee, CustomerPostingGroups."Additional Fee Account".Visible(), 'Column visible');
        CustomerPostingGroups.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroupInterestAccountVisibleReminderTerms()
    var
        CustomerPostingGroups: TestPage "Customer Posting Groups";
        PostInterest: Boolean;
    begin
        // [FEATURE] [UI] [Late Payment Fee] [Customer Posting Groups] [Visibility]
        // [SCENARIO 254979] Column "Interest Account" is visible on page Customer Posting Groups when "Post Interest" = TRUE in Reminder Terms
        Initialize();
        DeleteAllReminderTermsAndFinanceChargeTerms();
        PostInterest := true;

        // [GIVEN] Create Reminder Terms with "Post Interest" = TRUE
        CreateReminderTermsWithPostInterest(PostInterest);

        // [WHEN] Open page Customer Posting Groups
        CustomerPostingGroups.OpenView();

        // [THEN] Column "Interest Account" is visible
        Assert.AreEqual(PostInterest, CustomerPostingGroups."Interest Account".Visible(), 'Column invisible');
        CustomerPostingGroups.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroupInterestAccountInvisibleReminderTerms()
    var
        CustomerPostingGroups: TestPage "Customer Posting Groups";
        PostInterest: Boolean;
    begin
        // [FEATURE] [UI] [Late Payment Fee] [Customer Posting Groups] [Visibility]
        // [SCENARIO 254979] Column "Interest Account" is invisible on page Customer Posting Groups when "Post Interest" = FALSE in Reminder Terms and there are no Finance Charge Terms with "Post Interest" = TRUE
        Initialize();
        DeleteAllReminderTermsAndFinanceChargeTerms();
        PostInterest := false;

        // [GIVEN] Create Reminder Terms with "Post Interest" = FALSE, and not exists Finance Charge Terms with "Post Interest" = TRUE
        CreateReminderTermsWithPostInterest(PostInterest);

        // [WHEN] Open page Customer Posting Groups
        CustomerPostingGroups.OpenView();

        // [THEN] Column "Interest Account" is invisible
        Assert.AreEqual(PostInterest, CustomerPostingGroups."Interest Account".Visible(), 'Column visible');
        CustomerPostingGroups.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroupAdditionalFeeAccountVisibleReminderTerms()
    var
        CustomerPostingGroups: TestPage "Customer Posting Groups";
        PostAdditionalFee: Boolean;
    begin
        // [FEATURE] [UI] [Late Payment Fee] [Customer Posting Groups] [Visibility]
        // [SCENARIO 254979] Column "Additional Fee Account" is visible on page Customer Posting Groups when "Post Additional Fee" = TRUE in Reminder Terms
        Initialize();
        DeleteAllReminderTermsAndFinanceChargeTerms();
        PostAdditionalFee := true;

        // [GIVEN] Create Reminder Terms with "Post Additional Fee" = TRUE
        CreateReminderTermsWithPostAdditionalFee(PostAdditionalFee);

        // [WHEN] Open page Customer Posting Groups
        CustomerPostingGroups.OpenView();

        // [THEN] Column "Additional Fee Account" is visible
        Assert.AreEqual(PostAdditionalFee, CustomerPostingGroups."Additional Fee Account".Visible(), 'Column invisible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroupAdditionalFeeAccountInvisibleReminderTerms()
    var
        CustomerPostingGroups: TestPage "Customer Posting Groups";
        PostAdditionalFee: Boolean;
    begin
        // [FEATURE] [UI] [Late Payment Fee] [Customer Posting Groups] [Visibility]
        // [SCENARIO 254979] Column "Additional Fee Account" is invisible on page Customer Posting Groups when "Post Additional Fee" = FALSE in Reminder Terms and there are no Finance Charge Terms with "Post Additional Fee" = TRUE
        Initialize();
        DeleteAllReminderTermsAndFinanceChargeTerms();
        PostAdditionalFee := false;

        // [GIVEN] Create Reminder Terms with "Post Additional Fee" = FALSE, and not exists Finance Charge Terms with "Post Additional Fee" = TRUE
        CreateReminderTermsWithPostAdditionalFee(PostAdditionalFee);

        // [WHEN] Open page Customer Posting Groups
        CustomerPostingGroups.OpenView();

        // [THEN] Column "Additional Fee Account" is invisible
        Assert.AreEqual(PostAdditionalFee, CustomerPostingGroups."Additional Fee Account".Visible(), 'Column visible');
        CustomerPostingGroups.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtTolFieldsVisibleOnGenPostingSetupPageWhenMaxPmtTolAmtSpecified()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: TestPage "General Posting Setup";
    begin
        // [SCENARIO 267197] Payment Tolerance fields are visible on General Posting Setup page when "Max. Payment Tolerance Amount" is specified in General Ledger Setup

        Initialize();

        // [GIVEN] "Max. Payment Tolerance Amount" = 1 in General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Payment Tolerance %" := 0;
        GeneralLedgerSetup."Max. Payment Tolerance Amount" := 1;
        GeneralLedgerSetup.Modify();

        // [WHEN] Open page "General Posting Setup"
        GeneralPostingSetup.OpenNew();

        // [THEN] Sales and Purchase payment tolerance fields are visible
        VerifyPmtTolFieldsVisibilityOnGeneralPostingSetup(GeneralPostingSetup, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtTolFieldsNotVisibleOnGenPostingSetupPageWhenMaxPmtTolAmtZero()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: TestPage "General Posting Setup";
    begin
        // [SCENARIO 267197] Payment Tolerance fields are not visible on General Posting Setup page when "Max. Payment Tolerance Amount" is not specified in General Ledger Setup

        Initialize();

        // [GIVEN] "Max. Payment Tolerance Amount" = 0 in General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Payment Tolerance %" := 0;
        GeneralLedgerSetup."Max. Payment Tolerance Amount" := 0;
        GeneralLedgerSetup.Modify();

        // [WHEN] Open page "General Posting Setup"
        GeneralPostingSetup.OpenNew();

        // [THEN] Sales and Purchase payment tolerance fields are not visible
        VerifyPmtTolFieldsVisibilityOnGeneralPostingSetup(GeneralPostingSetup, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBlockedPmtTolCreditAccCustPostingGrp()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Customer] [Payment Tolerance]
        // [SCENARIO 281606] Stan cannot validate "Payment Tolerance Credit Acc." = blocked G/L Account in Customer Posting Group
        Initialize();

        // [GIVEN] Blocked GL Account
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);

        // [WHEN] Validate "Payment Tolerance Credit Acc." = Blocked GL Account in Customer Posting Group
        CustomerPostingGroup.Init();
        asserterror CustomerPostingGroup.Validate("Payment Tolerance Credit Acc.", GLAccount."No.");

        // [THEN] Error "Blocked must be equal to 'No'"
        Assert.ExpectedTestFieldError(GLAccount.FieldCaption(Blocked), Format(false));
        Assert.ExpectedErrorCode(TestFieldCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBlockedPmtTolCreditAccVendPostingGrp()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Vendor] [Payment Tolerance]
        // [SCENARIO 281606] Stan cannot validate "Payment Tolerance Credit Acc." = blocked G/L Account in Vendor Posting Group
        Initialize();

        // [GIVEN] Blocked GL Account
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);

        // [WHEN] Validate "Payment Tolerance Credit Acc." = Blocked GL Account in Vendor Posting Group
        VendorPostingGroup.Init();
        asserterror VendorPostingGroup.Validate("Payment Tolerance Credit Acc.", GLAccount."No.");

        // [THEN] Error "Blocked must be equal to 'No'"
        Assert.ExpectedTestFieldError(GLAccount.FieldCaption(Blocked), Format(false));
        Assert.ExpectedErrorCode(TestFieldCodeErr);
    end;

    [Test]
    [HandlerFunctions('GlAccountListModalPageHandler')]
    [Scope('OnPrem')]
    procedure LookupPmtTolCreditAccCustPostingGrp()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        CustomerPostingGroups: TestPage "Customer Posting Groups";
        GLAccountNo1: Code[20];
        GLAccountNo2: Code[20];
    begin
        // [FEATURE] [UI] [Customer] [Payment Tolerance]
        // [SCENARIO 281606] When Stan Looks up "Payment Tolerance Credit Acc." in Customer Posting Group then "Payment Tolerance Debit Acc." is not changed
        Initialize();

        // [GIVEN] Set <non-zero> Payment Tolerance % in General Ledger Setup
        ModifyPaymentTolerancePercentInGLSetup();

        // [GIVEN] G/L Account "GL1"
        GLAccountNo1 := LibraryERM.CreateGLAccountNo();

        // [GIVEN] G/L Account "GL2" in Interest Expense Subcategory
        GLAccountNo2 := CreateGLAccountNoWithAccountSubcategory(
            CreateGLAccountCategoryWithDescription(AccountCategory::Expense, GLAccountCategoryMgt.GetInterestExpense()));

        // [GIVEN] Customer Posting Group with "Payment Tolerance Debit Acc." = "GL1"
        CreateCustomerPostingGroupWithPmtTolDebitAcc(CustomerPostingGroup, GLAccountNo1);

        // [GIVEN] Stan opened page Customer Posting Groups and looked up "Payment Tolerance Credit Acc."
        // [GIVEN] Stan selected G/L Account "GL2" on page G/L Account List
        CustomerPostingGroups.OpenEdit();
        CustomerPostingGroups.GotoRecord(CustomerPostingGroup);
        LibraryVariableStorage.Enqueue(GLAccountNo2);
        CustomerPostingGroups."Payment Tolerance Credit Acc.".Lookup();

        // [WHEN] Stan pushes OK on page G/L Account List
        // done in GlAccountListModalPageHandler

        // [THEN] "Payment Tolerance Debit Acc." = "GL1" on Customer Posting Groups page
        CustomerPostingGroups."Payment Tolerance Debit Acc.".AssertEquals(GLAccountNo1);

        // [THEN] "Payment Tolerance Credit Acc." = "GL2" on Customer Posting Groups page
        CustomerPostingGroups."Payment Tolerance Credit Acc.".AssertEquals(GLAccountNo2);

        CustomerPostingGroups.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GlAccountListModalPageHandler')]
    [Scope('OnPrem')]
    procedure LookupPmtTolCreditAccVendPostingGrp()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        VendorPostingGroups: TestPage "Vendor Posting Groups";
        GLAccountNo1: Code[20];
        GLAccountNo2: Code[20];
    begin
        // [FEATURE] [UI] [Vendor] [Payment Tolerance]
        // [SCENARIO 281606] When Stan Looks up "Payment Tolerance Credit Acc." in Vendor Posting Group then "Payment Tolerance Debit Acc." is not changed
        Initialize();

        // [GIVEN] Set <non-zero> Payment Tolerance % in General Ledger Setup
        ModifyPaymentTolerancePercentInGLSetup();

        // [GIVEN] G/L Account "GL1"
        GLAccountNo1 := LibraryERM.CreateGLAccountNo();

        // [GIVEN] G/L Account "GL2" in Income Interest Subcategory
        GLAccountNo2 := CreateGLAccountNoWithAccountSubcategory(
            CreateGLAccountCategoryWithDescription(AccountCategory::Income, GLAccountCategoryMgt.GetIncomeInterest()));

        // [GIVEN] Vendor Posting Group with "Payment Tolerance Debit Acc." = "GL1"
        CreateVendorPostingGroupWithPmtTolDebitAcc(VendorPostingGroup, GLAccountNo1);

        // [GIVEN] Stan opened page Vendor Posting Groups and looked up "Payment Tolerance Credit Acc."
        // [GIVEN] Stan selected G/L Account "GL2" on page G/L Account List
        VendorPostingGroups.OpenEdit();
        VendorPostingGroups.GotoRecord(VendorPostingGroup);
        LibraryVariableStorage.Enqueue(GLAccountNo2);
        VendorPostingGroups."Payment Tolerance Credit Acc.".Lookup();

        // [WHEN] Stan pushes OK on page G/L Account List
        // done in GlAccountListModalPageHandler

        // [THEN] "Payment Tolerance Debit Acc." = "GL1" on Vendor Posting Groups page
        VendorPostingGroups."Payment Tolerance Debit Acc.".AssertEquals(GLAccountNo1);

        // [THEN] "Payment Tolerance Credit Acc." = "GL2" on Vendor Posting Groups page
        VendorPostingGroups."Payment Tolerance Credit Acc.".AssertEquals(GLAccountNo2);

        VendorPostingGroups.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GlAccountListModalPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerPostingGroupInterestAccoutLookupValidates()
    var
        CustomerPostingGroupPage: TestPage "Customer Posting Groups";
        GlAcc: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Customer] [UI]
        // [SCENARIO 287860] User gets validation error after looking up an account with empty general posting group
        Initialize();

        // [GIVEN] G/L Account "1" with Category = Income and empty "Gen. Prod. Posting Group"
        GLAccountNo := CreateGLAccountNoWithAccountSubcategory(
            CreateGLAccountCategoryWithDescription(AccountCategory::Income, LibraryUtility.GenerateGUID()));

        // [GIVEN] Customer Posting Group Page was open
        CustomerPostingGroupPage.OpenEdit();

        // [WHEN] Lookup Interest Account and choose G/L Account "1"
        LibraryVariableStorage.Enqueue(GLAccountNo);
        asserterror CustomerPostingGroupPage."Interest Account".Lookup();
        // Lookup handled by GlAccountListModalPageHandler
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Error "Gen. Prod. Posting Group must have a value in G/L Account: No.=X.  It cannot be zero or empty." appears
        Assert.ExpectedTestFieldError(GlAcc.FieldCaption("Gen. Prod. Posting Group"), '');
        Assert.ExpectedErrorCode(TestFieldCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedOnGenPostingSetupList()
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        GeneralPostingSetupList: TestPage "General Posting Setup";
    begin
        // [FEATURE] [UI] [Gen. Posting Setup] [Blocked]
        // [SCENARIO 403129] New Gen. Posting Setup is not blocked on the page "Gen. Posting Setup".
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);

        GeneralPostingSetupList.OpenNew();
        GeneralPostingSetupList."Gen. Bus. Posting Group".SetValue(GenBusinessPostingGroup.Code);
        GeneralPostingSetupList."Gen. Prod. Posting Group".SetValue(GenProductPostingGroup.Code);

        GeneralPostingSetupList.Blocked.AssertEquals(false);
        GeneralPostingSetupList.Blocked.SetValue(true);
        GeneralPostingSetupList.Close();

        GeneralPostingSetup.Get(GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        GeneralPostingSetup.TestField(Blocked, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedOnGenPostingSetupCard()
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        GeneralPostingSetupCard: TestPage "General Posting Setup Card";
    begin
        // [FEATURE] [UI] [Gen. Posting Setup] [Blocked]
        // [SCENARIO 403129] New Gen. Posting Setup is not blocked on the page "Gen. Posting Setup Card".
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);

        GeneralPostingSetupCard.OpenNew();
        GeneralPostingSetupCard."Gen. Bus. Posting Group".SetValue(GenBusinessPostingGroup.Code);
        GeneralPostingSetupCard."Gen. Prod. Posting Group".SetValue(GenProductPostingGroup.Code);

        GeneralPostingSetupCard.Blocked.AssertEquals(false);
        GeneralPostingSetupCard.Blocked.SetValue(true);
        GeneralPostingSetupCard.Close();

        GeneralPostingSetup.Get(GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        GeneralPostingSetup.TestField(Blocked, true);
    end;

    [Test]
    procedure BlockedOnVATPostingSetupList()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetupList: TestPage "VAT Posting Setup";
    begin
        // [FEATURE] [UI] [VAT Posting Setup] [Blocked]
        // [SCENARIO 403129] New VAT Posting Setup is not blocked on the page "VAT Posting Setup".
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);

        VATPostingSetupList.OpenNew();
        VATPostingSetupList."VAT Bus. Posting Group".SetValue(VATBusinessPostingGroup.Code);
        VATPostingSetupList."VAT Prod. Posting Group".SetValue(VATProductPostingGroup.Code);

        VATPostingSetupList.Blocked.AssertEquals(false);
        VATPostingSetupList.Blocked.SetValue(true);
        VATPostingSetupList.Close();

        VATPostingSetup.Get(VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.TestField(Blocked, true);
    end;

    [Test]
    procedure BlockedOnVATPostingSetupCard()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetupCard: TestPage "VAT Posting Setup Card";
    begin
        // [FEATURE] [UI] [VAT Posting Setup] [Blocked]
        // [SCENARIO 403129] New VAT Posting Setup is not blocked on the page "VAT Posting Setup Card".
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);

        VATPostingSetupCard.OpenNew();
        VATPostingSetupCard."VAT Bus. Posting Group".SetValue(VATBusinessPostingGroup.Code);
        VATPostingSetupCard."VAT Prod. Posting Group".SetValue(VATProductPostingGroup.Code);

        VATPostingSetupCard.Blocked.AssertEquals(false);
        VATPostingSetupCard.Blocked.SetValue(true);
        VATPostingSetupCard.Close();

        VATPostingSetup.Get(VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.TestField(Blocked, true);
    end;

    local procedure Initialize()
    begin
        // Lazy Setup.
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        isInitialized := true;
        Commit();
    end;

    local procedure SetSalesDiscountPosting(DiscountPosting: Option)
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup."Discount Posting" := DiscountPosting;
        SalesSetup.Modify();
    end;

    local procedure SetPurchDiscountPosting(DiscountPosting: Option)
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup."Discount Posting" := DiscountPosting;
        PurchSetup.Modify();
    end;

    local procedure ModifyPaymentTolerancePercentInGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Tolerance %", LibraryRandom.RandDecInRange(10, 20, 2));
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CreateCustomerPostingGroupWithPmtTolDebitAcc(var CustomerPostingGroup: Record "Customer Posting Group"; GLAccountNo: Code[20])
    begin
        CustomerPostingGroup.Init();
        CustomerPostingGroup.Code := LibraryUtility.GenerateGUID();
        CustomerPostingGroup."Payment Tolerance Debit Acc." := GLAccountNo;
        CustomerPostingGroup.Insert();
    end;

    local procedure CreateVendorPostingGroupWithPmtTolDebitAcc(var VendorPostingGroup: Record "Vendor Posting Group"; GLAccountNo: Code[20])
    begin
        VendorPostingGroup.Init();
        VendorPostingGroup.Code := LibraryUtility.GenerateGUID();
        VendorPostingGroup."Payment Tolerance Debit Acc." := GLAccountNo;
        VendorPostingGroup.Insert();
    end;

    local procedure CreateGLAccountCategoryWithDescription(AccountCategory: Integer; Description: Text): Integer
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        GLAccountCategory.Init();
        GLAccountCategory."Entry No." := LibraryUtility.GetNewRecNo(GLAccountCategory, GLAccountCategory.FieldNo("Entry No."));
        GLAccountCategory."Account Category" := AccountCategory;
        GLAccountCategory.Description := CopyStr(Description, 1, MaxStrLen(GLAccountCategory.Description));
        GLAccountCategory.Insert();
        exit(GLAccountCategory."Entry No.");
    end;

    local procedure CreateGLAccountNoWithAccountSubcategory(AccountSubcategoryEntryNo: Integer): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        GLAccount.Validate("Account Subcategory Entry No.", AccountSubcategoryEntryNo);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateFinanceChargeTermsWithPostInterest(PostInterest: Boolean)
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Post Interest", PostInterest);
        FinanceChargeTerms.Modify(true);
    end;

    local procedure CreateFinanceChargeTermsWithPostAdditionalFee(PostAdditionalFee: Boolean)
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Post Additional Fee", PostAdditionalFee);
        FinanceChargeTerms.Modify(true);
    end;

    local procedure CreateReminderTermsWithPostInterest(PostInterest: Boolean)
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        ReminderTerms.Validate("Post Interest", PostInterest);
        ReminderTerms.Modify(true);
    end;

    local procedure CreateReminderTermsWithPostAdditionalFee(PostAdditionalFee: Boolean)
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        ReminderTerms.Validate("Post Additional Fee", PostAdditionalFee);
        ReminderTerms.Modify(true);
    end;

    local procedure DeleteAllReminderTermsAndFinanceChargeTerms()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        ReminderTerms: Record "Reminder Terms";
    begin
        FinanceChargeTerms.DeleteAll();
        ReminderTerms.DeleteAll();
    end;

    local procedure VerifyPmtTolFieldsVisibilityOnGeneralPostingSetup(var GeneralPostingSetup: TestPage "General Posting Setup"; ExpectedVisibility: Boolean)
    begin
        Assert.AreEqual(ExpectedVisibility, GeneralPostingSetup."Sales Pmt. Tol. Debit Acc.".Visible(), '');
        Assert.AreEqual(ExpectedVisibility, GeneralPostingSetup."Sales Pmt. Tol. Credit Acc.".Visible(), '');
        Assert.AreEqual(ExpectedVisibility, GeneralPostingSetup."Purch. Pmt. Tol. Debit Acc.".Visible(), '');
        Assert.AreEqual(ExpectedVisibility, GeneralPostingSetup."Purch. Pmt. Tol. Debit Acc.".Visible(), '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GlAccountListModalPageHandler(var GLAccountList: TestPage "G/L Account List")
    begin
        GLAccountList.GotoKey(LibraryVariableStorage.DequeueText());
        GLAccountList.OK().Invoke();
    end;
}
