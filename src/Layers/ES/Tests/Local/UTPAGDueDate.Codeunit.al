codeunit 144041 "UT PAG Due Date"
{
    // Test for feature - Due Date.
    //  1. Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Page - 43 Sales Invoice.
    //  2. Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Page - 42 Sales Order.
    //  3. Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Page - 41 Sales Quote.
    //  4. Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Page - 44 Sales Credit Memo.
    //  5. Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Page - 507 Blanket Sales Order.
    //  6. Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Page - 509 Blanket Purchase Order.
    //  7. Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Page - 52 Purchase Credit Memo.
    //  8. Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Page - 51 Purchase Invoice.
    //  9. Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Page - 49 Purchase Quote.
    // 10. Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Page - 50 Purchase Order.
    // 11. Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Page - 50 Purchase Order with Non zero value - Maximum Number of Days till Due Date.
    // 12. Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Page - 50 Purchase Order with Prepayment Percent.
    // 13. Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Page - 50 Purchase Order with Maximum Number of Days till Due Date and with Prepayment Percent.
    // 14. Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Page - 42 Sales Order with Non zero value - Maximum Number of Days till Due Date.
    // 15. Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Page - 42 Sales Order with Prepayment Percent.
    // 16. Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Page - 42 Sales Order with Maximum Number of Days till Due Date and with Prepayment Percent.
    // 
    // Covers Test Cases for WI - 351127.
    // -----------------------------------------------------------------------------
    // Test Function Name                                                   TFS ID
    // -----------------------------------------------------------------------------
    // OnValidateSellToCustomerNoForDueDateSalesInvoice                     152304
    // OnValidateSellToCustomerNoForDueDateSalesOrder                       152305
    // OnValidateSellToCustomerNoForDueDateSalesQuote                       152303
    // OnValidateSellToCustomerNoForDueDateSalesCreditMemo                  152301
    // OnValidateSellToCustomerNoForDueDateBlanketSalesOrder                152302
    // OnValidateBuyFromVendorNoForDueDateBlanketPurchaseOrder              152308
    // OnValidateBuyFromVendorNoForDueDatePurchaseCreditMemo                152306
    // OnValidateBuyFromVendorNoForDueDatePurchaseInvoice                   152310
    // OnValidateBuyFromVendorNoForDueDatePurchaseQuote                     152309
    // OnValidateBuyFromVendorNoForDueDatePurchaseOrder                     152311
    // 
    // Covers Test Cases for WI - 351129.
    // -----------------------------------------------------------------------------
    // Test Function Name                                                   TFS ID
    // -----------------------------------------------------------------------------
    // OnValidateBuyFromVendorNoMaxDayTillDueDatePurchaseOrder              152059
    // OnValidateBuyFromVendorNoDueDatePrepaymentPurchaseOrder              152057
    // OnValidateBuyFromVendorNoMaxDueDatePrepmtPurchaseOrder               152058
    // OnValidateSellToCustomerNoMaxDayTillDueDateSalesOrder                152031
    // OnValidateSellToCustomerNoDueDatePrepaymentSaleOrder                 151390
    // OnValidateSellToCustomerNoMaxDueDatePrepmtSaleOrder                  151296

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToCustomerNoForDueDateSalesInvoice()
    var
        SalesInvoice: TestPage "Sales Invoice";
        CustomerNo: Code[20];
        DueDate: Date;
    begin
        // Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Page - 43 Sales Invoice.

        // Setup: Create Customer, Payment Days And Non - Payment Period.
        DueDate := CreatePaymentDaysAndNonPaymentPeriodForCustomer(CustomerNo, '', '', 0, CalcDate('<CY>', WorkDate()));  // Blank - Country/Region Code, VAT Registration Number, Maximum Number of Days till Due Date required 0 and Last Day of the Current Year.
        SalesInvoice.OpenNew();

        // Exercise.
        SalesInvoice."Sell-to Customer Name".SetValue(CustomerNo);

        // Verify: Verify Due Date - Calculated on Basis the of Payment Days and Non - Payment Period on Page - Sales Invoice.
        SalesInvoice."Due Date".AssertEquals(DueDate);
        SalesInvoice.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToCustomerNoForDueDateSalesOrder()
    begin
        // Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Page - 42 Sales Order.

        // Setup.
        OnValidateSellToCustomerNoForSalesOrder(0, 0, CalcDate('<CY>', WorkDate()));  // Maximum Number of Days till Due Date required 0, 0 as Prepayment Percent and Last Day of the Current Year.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToCustomerNoForDueDateSalesQuote()
    var
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        CustomerNo: Code[20];
        DueDate: Date;
    begin
        // Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Page - 41 Sales Quote.

        // Setup: Create Customer, Payment Days And Non - Payment Period.
        DueDate := CreatePaymentDaysAndNonPaymentPeriodForCustomer(CustomerNo, '', '', 0, CalcDate('<CY>', WorkDate()));  // Blank - Country/Region Code, VAT Registration Number, Maximum Number of Days till Due Date required 0 and Last Day of the Current Year.
        SalesQuote.OpenNew();

        // Exercise.
        Customer.Get(CustomerNo);
        SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);

        // Verify: Verify Due Date - Calculated on the Basis of Payment Days and Non - Payment Period on Page - Sales Quote.
        SalesQuote."Due Date".AssertEquals(DueDate);
        SalesQuote.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToCustomerNoForDueDateSalesCreditMemo()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CustomerNo: Code[20];
        DueDate: Date;
    begin
        // Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Page - 44 Sales Credit Memo.

        // Setup: Create Customer, Payment Days And Non - Payment Period.
        DueDate :=
          CreatePaymentDaysAndNonPaymentPeriodForCustomer(CustomerNo, CreateCountryRegion(), LibraryUTUtility.GetNewCode(),
            0, CalcDate('<CY>', WorkDate()));  // Generate Code for VAT Registration Number, Maximum Number of Days till Due Date required 0 and Last Day of the Current Year.
        SalesCreditMemo.OpenNew();

        // Exercise.
        SalesCreditMemo."Sell-to Customer Name".SetValue(CustomerNo);

        // Verify: Verify Due Date - Calculated on the Basis of Payment Days and Non - Payment Period on Page - Sales Credit Memo.
        SalesCreditMemo."Due Date".AssertEquals(DueDate);
        SalesCreditMemo.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToCustomerNoForDueDateBlanketSalesOrder()
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        CustomerNo: Code[20];
        DueDate: Date;
    begin
        // Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Page - 507 Blanket Sales Order.

        // Setup: Create Customer, Payment Days And Non - Payment Period.
        DueDate :=
          CreatePaymentDaysAndNonPaymentPeriodForCustomer(CustomerNo, CreateCountryRegion(), LibraryUTUtility.GetNewCode(), 0,
            CalcDate('<CY>', WorkDate()));  // Generate Code for VAT Registration Number, Maximum Number of Days till Due Date required 0 and Last Day of the Current Year.
        BlanketSalesOrder.OpenNew();

        // Exercise.
        BlanketSalesOrder."Sell-to Customer Name".SetValue(CustomerNo);

        // Verify: Verify Due Date - Calculated on the Basis of Payment Days and Non - Payment Period on Page - Blanket Sales Order.
        BlanketSalesOrder."Due Date".AssertEquals(DueDate);
        BlanketSalesOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromVendorNoForDueDateBlanketPurchaseOrder()
    var
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        VendorNo: Code[20];
        DueDate: Date;
    begin
        // Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Page - 509 Blanket Purchase Order.

        // Setup: Create Vendor, Payment Days And Non - Payment Period.
        DueDate :=
          CreatePaymentDaysAndNonPaymentPeriodForVendor(VendorNo, CreateCountryRegion(), LibraryUTUtility.GetNewCode(), 0,
            CalcDate('<CY>', WorkDate()));  // Generate Code for VAT Registration Number, Maximum Number of Days till Due Date required 0 and Last Day of the Current Year.
        BlanketPurchaseOrder.OpenNew();

        // Exercise.
        BlanketPurchaseOrder."Buy-from Vendor Name".SetValue(VendorNo);

        // Verify: Verify Due Date - Calculated on the Basis of Payment Days and Non - Payment Period on Page - Blanket Purchase Order.
        BlanketPurchaseOrder."Due Date".AssertEquals(DueDate);
        BlanketPurchaseOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromVendorNoForDueDatePurchaseCreditMemo()
    var
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        VendorNo: Code[20];
        DueDate: Date;
    begin
        // Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Page - 52 Purchase Credit Memo.

        // Setup: Create Vendor, Payment Days And Non - Payment Period.
        DueDate :=
          CreatePaymentDaysAndNonPaymentPeriodForVendor(VendorNo, CreateCountryRegion(), LibraryUTUtility.GetNewCode(), 0,
            CalcDate('<CY>', WorkDate()));  // Generate Code for VAT Registration Number, Maximum Number of Days till Due Date required 0 and Last Day of the Current Year.
        PurchaseCreditMemo.OpenNew();

        // Exercise.
        Vendor.Get(VendorNo);
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vendor.Name);

        // Verify: Verify Due Date - Calculated on the Basis of Payment Days and Non - Payment Period on Page - Purchase Credit Memo.
        PurchaseCreditMemo."Due Date".AssertEquals(DueDate);
        PurchaseCreditMemo.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromVendorNoForDueDatePurchaseInvoice()
    var
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
        DueDate: Date;
    begin
        // Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Page - 51 Purchase Invoice.

        // Setup: Create Vendor, Payment Days And Non - Payment Period.
        DueDate := CreatePaymentDaysAndNonPaymentPeriodForVendor(VendorNo, '', '', 0, CalcDate('<CY>', WorkDate()));  // Blank - Country/Region Code, VAT Registration Number, Maximum Number of Days till Due Date required 0 and Last Day of the Current Year.
        PurchaseInvoice.OpenNew();

        // Exercise
        Vendor.Get(VendorNo);
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);

        // Verify: Verify Due Date - Calculated on the Basis of Payment Days and Non - Payment Period on Page - Purchase Invoice.
        PurchaseInvoice."Due Date".AssertEquals(DueDate);
        PurchaseInvoice.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromVendorNoForDueDatePurchaseQuote()
    var
        PurchaseQuote: TestPage "Purchase Quote";
        VendorNo: Code[20];
        DueDate: Date;
    begin
        // Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Page - 49 Purchase Quote.

        // Setup: Create Vendor, Payment Days And Non - Payment Period.
        DueDate := CreatePaymentDaysAndNonPaymentPeriodForVendor(VendorNo, '', '', 0, CalcDate('<CY>', WorkDate()));  // Blank - Country/Region Code, VAT Registration Number, Maximum Number of Days till Due Date required 0 and Last Day of the Current Year.
        PurchaseQuote.OpenNew();

        // Exercise.
        PurchaseQuote."Buy-from Vendor Name".SetValue(VendorNo);

        // Verify: Verify Due Date - Calculated on the Basis of Payment Days and Non - Payment Period on Page - Purchase Quote.
        PurchaseQuote."Due Date".AssertEquals(DueDate);
        PurchaseQuote.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromVendorNoForDueDatePurchaseOrder()
    begin
        // Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Page - 50 Purchase Order.

        // Setup.
        OnValidateBuyFromVendorNoPurchaseOrder(0, 0, CalcDate('<CY>', WorkDate()));  // Maximum Number of Days till Due Date required 0, 0 as Prepayment Percent and Last Day of the Current Year.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromVendorNoMaxDayTillDueDatePurchaseOrder()
    begin
        // Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Page - 50 Purchase Order with Non zero value - Maximum Number of Days till Due Date.

        // Setup.
        OnValidateBuyFromVendorNoPurchaseOrder(LibraryRandom.RandIntInRange(20, 30), 0, CalcDate('<CM>', WorkDate()));  // Random - Maximum Number of Days till Due Date, 0 as Prepayment Percent and Last Day of the Current Month.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromVendorNoDueDatePrepaymentPurchaseOrder()
    begin
        // Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Page - 50 Purchase Order with Prepayment Percent.

        // Setup.
        OnValidateBuyFromVendorNoPurchaseOrder(0, LibraryRandom.RandInt(10), CalcDate('<CY>', WorkDate()));  // Maximum Number of Days till Due Date required 0, Random as Prepayment Percent and Last Day of the Current Year.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromVendorNoMaxDueDatePrepmtPurchaseOrder()
    begin
        // Purpose of the test is to validate Buy-from Vendor No. - OnValidate Trigger of Page - 50 Purchase Order with Maximum Number of Days till Due Date and with Prepayment Percent.

        // Setup.
        OnValidateBuyFromVendorNoPurchaseOrder(
          LibraryRandom.RandIntInRange(20, 30), LibraryRandom.RandInt(10), CalcDate('<CM>', WorkDate()));  // Random - Maximum Number of Days till Due Date, Prepayment Percent and Last Day of the Current Month.
    end;

    local procedure OnValidateBuyFromVendorNoPurchaseOrder(MaxNoOfDaysTillDueDate: Integer; PrepaymentPct: Integer; ToDate: Date)
    var
        PurchaseOrder: TestPage "Purchase Order";
        VendorNo: Code[20];
        DueDate: Date;
    begin
        // Create Vendor, Payment Days And Non - Payment Period.
        DueDate := CreatePaymentDaysAndNonPaymentPeriodForVendor(VendorNo, '', '', MaxNoOfDaysTillDueDate, ToDate);  // Blank - Country/Region Code, VAT Registration Number.
        UpdatePrepaymentPctOnVendor(VendorNo, PrepaymentPct);
        PurchaseOrder.OpenNew();

        // Exercise.
        PurchaseOrder."Buy-from Vendor Name".SetValue(VendorNo);

        // Verify: Verify Due Date and Prepayment Due Date - Calculated on the Basis of Payment Days and Non - Payment Period on Page - Purchase Order.
        PurchaseOrder."Due Date".AssertEquals(DueDate);
        PurchaseOrder."Prepayment Due Date".AssertEquals(DueDate);
        PurchaseOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToCustomerNoMaxDayTillDueDateSalesOrder()
    begin
        // Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Page - 42 Sales Order with Non zero value - Maximum Number of Days till Due Date.

        // Setup.
        OnValidateSellToCustomerNoForSalesOrder(LibraryRandom.RandIntInRange(20, 30), 0, CalcDate('<CM>', WorkDate()));  // Random - Maximum Number of Days till Due Date, 0 as Prepayment Percent and Last Day of the Current Month.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToCustomerNoDueDatePrepaymentSaleOrder()
    begin
        // Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Page - 42 Sales Order with Prepayment Percent.

        // Setup.
        OnValidateSellToCustomerNoForSalesOrder(0, LibraryRandom.RandInt(10), CalcDate('<CY>', WorkDate()));  // Maximum Number of Days till Due Date required 0, Random as Prepayment Percent and Last Day of the Current Year.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToCustomerNoMaxDueDatePrepmtSaleOrder()
    begin
        // Purpose of the test is to validate Sell-to Customer No. - OnValidate Trigger of Page - 42 Sales Order with Maximum Number of Days till Due Date and with Prepayment Percent.

        // Setup.
        OnValidateSellToCustomerNoForSalesOrder(
          LibraryRandom.RandIntInRange(20, 30), LibraryRandom.RandInt(10), CalcDate('<CM>', WorkDate()));  // Random - Maximum Number of Days till Due Date, Prepayment Percent and Last Day of the Current Month.
    end;

    local procedure OnValidateSellToCustomerNoForSalesOrder(MaxNoOfDaysTillDueDate: Integer; PrepaymentPct: Integer; ToDate: Date)
    var
        SalesOrder: TestPage "Sales Order";
        CustomerNo: Code[20];
        DueDate: Date;
    begin
        // Create Customer, Payment Days And Non - Payment Period.
        DueDate :=
          CreatePaymentDaysAndNonPaymentPeriodForCustomer(CustomerNo, '', '', MaxNoOfDaysTillDueDate, ToDate);  // Blank - Country/Region Code, VAT Registration Number.
        UpdatePrepaymentPctOnCustomer(CustomerNo, PrepaymentPct);
        SalesOrder.OpenNew();

        // Exercise.
        SalesOrder."Sell-to Customer Name".SetValue(CustomerNo);

        // Verify: Verify Due Date and Prepayment Due Date - Calculated on the Basis of Payment Days and Non - Payment Period on Page - Sales Order.
        SalesOrder."Due Date".AssertEquals(DueDate);
        SalesOrder."Prepayment Due Date".AssertEquals(DueDate);
        SalesOrder.Close();
    end;

    local procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Code := LibraryUTUtility.GetNewCode10();
        CountryRegion.Insert();
        exit(CountryRegion.Code);
    end;

    local procedure CreateCustomer(CountryRegionCode: Code[10]; VATRegistrationNo: Code[20]; MaxNoOfDaysTillDueDate: Integer): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Name := LibraryUTUtility.GetNewCode();
        Customer."Customer Posting Group" := LibraryUTUtility.GetNewCode10();
        Customer."Gen. Bus. Posting Group" := LibraryUTUtility.GetNewCode10();
        Customer."Country/Region Code" := CountryRegionCode;
        Customer."Payment Terms Code" := CreatePaymentTerm(MaxNoOfDaysTillDueDate);
        Customer."Payment Days Code" := Customer."No.";
        Customer."Non-Paymt. Periods Code" := Customer."Payment Days Code";
        Customer."VAT Registration No." := VATRegistrationNo;
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateVendor(CountryRegionCode: Code[10]; VATRegistrationNo: Code[20]; MaxNoOfDaysTillDueDate: Integer): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Name := LibraryUTUtility.GetNewCode();
        Vendor."Vendor Posting Group" := LibraryUTUtility.GetNewCode10();
        Vendor."Gen. Bus. Posting Group" := LibraryUTUtility.GetNewCode10();
        Vendor."Country/Region Code" := CountryRegionCode;
        Vendor."Payment Terms Code" := CreatePaymentTerm(MaxNoOfDaysTillDueDate);
        Vendor."Payment Days Code" := Vendor."No.";
        Vendor."Non-Paymt. Periods Code" := Vendor."Payment Days Code";
        Vendor."VAT Registration No." := VATRegistrationNo;
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateNonPaymentPeriod(TableName: Option; "Code": Code[20]; ToDate: Date): Date
    var
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        NonPaymentPeriod."Table Name" := TableName;
        NonPaymentPeriod.Code := Code;
        NonPaymentPeriod."From Date" := CalcDate('<' + Format(LibraryRandom.RandIntInRange(1, 10)) + 'D>', WorkDate());
        NonPaymentPeriod."To Date" := ToDate;
        NonPaymentPeriod.Insert();
        exit(NonPaymentPeriod."From Date");
    end;

    local procedure CreatePaymentDays(TableName: Option; "Code": Code[20]): Integer
    var
        PaymentDay: Record "Payment Day";
    begin
        PaymentDay."Table Name" := TableName;
        PaymentDay.Code := Code;
        PaymentDay."Day of the month" := LibraryRandom.RandInt(10);
        PaymentDay.Insert();
        exit(PaymentDay."Day of the month");
    end;

    local procedure CreatePaymentDaysAndNonPaymentPeriod(TableName: Option; No: Code[20]; ToDate: Date): Date
    var
        PaymentsDay: Integer;
    begin
        PaymentsDay := CreatePaymentDays(TableName, No);
        CreateNonPaymentPeriod(TableName, No, ToDate);
        exit(CalcDate(Format(PaymentsDay) + 'D>', ToDate));
    end;

    local procedure CreatePaymentDaysAndNonPaymentPeriodForCustomer(var CustomerNo: Code[20]; CountryRegionCode: Code[10]; VATRegistrationNo: Code[20]; MaxNoOfDaysTillDueDate: Integer; ToDate: Date) DueDate: Date
    var
        PaymentDay: Record "Payment Day";
    begin
        CustomerNo := CreateCustomer(CountryRegionCode, VATRegistrationNo, MaxNoOfDaysTillDueDate);
        DueDate := CreatePaymentDaysAndNonPaymentPeriod(PaymentDay."Table Name"::Customer, CustomerNo, ToDate);
    end;

    local procedure CreatePaymentDaysAndNonPaymentPeriodForVendor(var VendorNo: Code[20]; CountryRegionCode: Code[10]; VATRegistrationNo: Code[20]; MaxNoOfDaysTillDueDate: Integer; ToDate: Date) DueDate: Date
    var
        PaymentDay: Record "Payment Day";
    begin
        VendorNo := CreateVendor(CountryRegionCode, VATRegistrationNo, MaxNoOfDaysTillDueDate);
        DueDate := CreatePaymentDaysAndNonPaymentPeriod(PaymentDay."Table Name"::Vendor, VendorNo, ToDate);
    end;

    local procedure CreatePaymentTerm(MaxNoOfDaysTillDueDate: Integer): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Code := LibraryUTUtility.GetNewCode10();
        Evaluate(PaymentTerms."Due Date Calculation", Format(LibraryRandom.RandIntInRange(10, 50)) + 'D>');  // Random - Due Date Calculation Period.
        PaymentTerms."VAT distribution" := PaymentTerms."VAT distribution"::Proportional;
        PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" := true;
        PaymentTerms."Max. No. of Days till Due Date" := MaxNoOfDaysTillDueDate;
        PaymentTerms.Insert();
        exit(PaymentTerms.Code);
    end;

    local procedure UpdatePrepaymentPctOnCustomer(CustomerNo: Code[20]; PrepaymentPct: Integer)
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer."Prepayment %" := PrepaymentPct;
        Customer.Modify();
    end;

    local procedure UpdatePrepaymentPctOnVendor(VendorNo: Code[20]; PrepaymentPct: Integer)
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor."Prepayment %" := PrepaymentPct;
        Vendor.Modify();
    end;
}

