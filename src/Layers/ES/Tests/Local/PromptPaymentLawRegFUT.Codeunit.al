codeunit 147301 "Prompt Payment Law RegF UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        IsInitialized: Boolean;
        ExpectedMaxDueDateError: Label 'The %1 exceeds the %2 defined on the %3.';
        PaymentTableNameOption: Option "Company Information",Customer,Vendor;
        IncorrectDueDateError: Label 'The adjusted due date is wrong.';

    [Test]
    [Scope('OnPrem')]
    procedure TestCustLedgerEntryManualDueDateModificationBoundaryValue()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        Initialize();

        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetFilter("Document Type", '<>%1', CustLedgerEntry."Document Type"::Bill);
        CustLedgerEntry.FindLast();
        PaymentTerms.Get(CustLedgerEntry."Payment Terms Code");

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date") + 'D>');
        CustLedgerEntry.Validate("Due Date", CalcDate(DateFormula, CustLedgerEntry."Document Date"));
        CustLedgerEntry.TestField("Due Date", CalcDate(DateFormula, CustLedgerEntry."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustLedgerEntryManualDueDateModificationBoundaryValuePlusOneError()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        Initialize();

        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetFilter("Document Type", '<>%1', CustLedgerEntry."Document Type"::Bill);
        CustLedgerEntry.FindLast();
        PaymentTerms.Get(CustLedgerEntry."Payment Terms Code");

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" + 1) + 'D>');
        asserterror CustLedgerEntry.Validate("Due Date", CalcDate(DateFormula, CustLedgerEntry."Document Date"));
        Assert.ExpectedError(
          StrSubstNo(
            ExpectedMaxDueDateError, CustLedgerEntry.FieldCaption("Due Date"),
            PaymentTerms.FieldCaption("Max. No. of Days till Due Date"), PaymentTerms.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustLedgerEntryManualDueDateModificationBoundaryValueMinusOne()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        Initialize();

        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetFilter("Document Type", '<>%1', CustLedgerEntry."Document Type"::Bill);
        CustLedgerEntry.FindLast();
        PaymentTerms.Get(CustLedgerEntry."Payment Terms Code");

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" - 1) + 'D>');
        CustLedgerEntry.Validate("Due Date", CalcDate(DateFormula, CustLedgerEntry."Document Date"));
        CustLedgerEntry.TestField("Due Date", CalcDate(DateFormula, CustLedgerEntry."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustLedgerEntryManualDueDateModificationDocumentTypeBill()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        Initialize();

        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetFilter("Document Type", '=%1', CustLedgerEntry."Document Type"::Bill);
        CustLedgerEntry.FindLast();
        PaymentTerms.Get(CustLedgerEntry."Payment Terms Code");

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" + 1) + 'D>');
        CustLedgerEntry.Validate("Due Date", CalcDate(DateFormula, CustLedgerEntry."Document Date"));
        CustLedgerEntry.TestField("Due Date", CalcDate(DateFormula, CustLedgerEntry."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorLedgerEntryManualDueDateModificationBoundaryValue()
    var
        VendorLedgerEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        Initialize();

        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetFilter("Document Type", '<>%1', VendorLedgerEntry."Document Type"::Bill);
        VendorLedgerEntry.FindLast();
        PaymentTerms.Get(VendorLedgerEntry."Payment Terms Code");

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date") + 'D>');
        VendorLedgerEntry.Validate("Due Date", CalcDate(DateFormula, VendorLedgerEntry."Document Date"));
        VendorLedgerEntry.TestField("Due Date", CalcDate(DateFormula, VendorLedgerEntry."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorLedgerEntryManualDueDateModificationBoundaryValuePlusOneError()
    var
        VendorLedgerEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        Initialize();

        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetFilter("Document Type", '<>%1', VendorLedgerEntry."Document Type"::Bill);
        VendorLedgerEntry.FindLast();
        PaymentTerms.Get(VendorLedgerEntry."Payment Terms Code");

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" + 1) + 'D>');
        asserterror VendorLedgerEntry.Validate("Due Date", CalcDate(DateFormula, VendorLedgerEntry."Document Date"));
        Assert.ExpectedError(
          StrSubstNo(
            ExpectedMaxDueDateError, VendorLedgerEntry.FieldCaption("Due Date"),
            PaymentTerms.FieldCaption("Max. No. of Days till Due Date"), PaymentTerms.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorLedgerEntryManualDueDateModificationBoundaryValueMinusOne()
    var
        VendorLedgerEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        Initialize();

        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetFilter("Document Type", '<>%1', VendorLedgerEntry."Document Type"::Bill);
        VendorLedgerEntry.FindLast();
        PaymentTerms.Get(VendorLedgerEntry."Payment Terms Code");

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" - 1) + 'D>');
        VendorLedgerEntry.Validate("Due Date", CalcDate(DateFormula, VendorLedgerEntry."Document Date"));
        VendorLedgerEntry.TestField("Due Date", CalcDate(DateFormula, VendorLedgerEntry."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorLedgerEntryManualDueDateModificationDocumentTypeBill()
    var
        VendorLedgerEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        Initialize();

        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetFilter("Document Type", '=%1', VendorLedgerEntry."Document Type"::Bill);
        VendorLedgerEntry.FindLast();
        PaymentTerms.Get(VendorLedgerEntry."Payment Terms Code");

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" + 1) + 'D>');
        VendorLedgerEntry.Validate("Due Date", CalcDate(DateFormula, VendorLedgerEntry."Document Date"));
        VendorLedgerEntry.TestField("Due Date", CalcDate(DateFormula, VendorLedgerEntry."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGeneralJournalManualDueDateModificationBoundaryValue()
    var
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        DateFormula: DateFormula;
    begin
        // This covers both Sales and Purchase Journal since they are actually General Journal
        Initialize();

        CreatePaymentTerms(PaymentTerms);
        CreateGeneralJournalLine(GenJnlLine);
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
        GenJnlLine."Payment Terms Code" := PaymentTerms.Code;
        GenJnlLine.Modify();

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date") + 'D>');
        GenJnlLine.Validate("Due Date", CalcDate(DateFormula, GenJnlLine."Document Date"));
        GenJnlLine.TestField("Due Date", CalcDate(DateFormula, GenJnlLine."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGeneralJournalManualDueDateModificationBoundaryValuePlusOneError()
    var
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        DateFormula: DateFormula;
    begin
        // This covers both Sales and Purchase Journal since they are actually General Journal
        Initialize();

        CreatePaymentTerms(PaymentTerms);
        CreateGeneralJournalLine(GenJnlLine);
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
        GenJnlLine."Payment Terms Code" := PaymentTerms.Code;
        GenJnlLine.Modify();

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" + 1) + 'D>');
        asserterror GenJnlLine.Validate("Due Date", CalcDate(DateFormula, GenJnlLine."Document Date"));
        Assert.ExpectedError(
          StrSubstNo(
            ExpectedMaxDueDateError, GenJnlLine.FieldCaption("Due Date"), PaymentTerms.FieldCaption("Max. No. of Days till Due Date"),
            PaymentTerms.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGeneralJournalManualDueDateModificationBoundaryValueMinusOne()
    var
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        DateFormula: DateFormula;
    begin
        // This covers both Sales and Purchase Journal since they are actually General Journal
        Initialize();

        CreatePaymentTerms(PaymentTerms);
        CreateGeneralJournalLine(GenJnlLine);
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
        GenJnlLine."Payment Terms Code" := PaymentTerms.Code;
        GenJnlLine.Modify();

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" - 1) + 'D>');
        GenJnlLine.Validate("Due Date", CalcDate(DateFormula, GenJnlLine."Document Date"));
        GenJnlLine.TestField("Due Date", CalcDate(DateFormula, GenJnlLine."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderManualDueDateModificationBoundaryValue()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        // This covers both Sales Order and Invoice since they are actually same sales header
        Initialize();
        SetupSales(SalesHeader, Customer, PaymentTerms);

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date") + 'D>');
        SalesHeader.Validate("Due Date", CalcDate(DateFormula, SalesHeader."Document Date"));
        SalesHeader.TestField("Due Date", CalcDate(DateFormula, SalesHeader."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderManualDueDateModificationBoundaryValuePlusOneError()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        // This covers both Sales Order and Invoice since they are actually same sales header
        Initialize();
        SetupSales(SalesHeader, Customer, PaymentTerms);

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" + 1) + 'D>');
        asserterror SalesHeader.Validate("Due Date", CalcDate(DateFormula, SalesHeader."Document Date"));
        Assert.ExpectedError(
          StrSubstNo(
            ExpectedMaxDueDateError, SalesHeader.FieldCaption("Due Date"), PaymentTerms.FieldCaption("Max. No. of Days till Due Date"),
            PaymentTerms.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderManualDueDateModificationBoundaryValueMinusOne()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        // This covers both Sales Order and Invoice since they are actually same sales header
        Initialize();
        SetupSales(SalesHeader, Customer, PaymentTerms);

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" - 1) + 'D>');
        SalesHeader.Validate("Due Date", CalcDate(DateFormula, SalesHeader."Document Date"));
        SalesHeader.TestField("Due Date", CalcDate(DateFormula, SalesHeader."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderManualDueDateModificationBoundaryValue()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        // This covers both Purchase Order and Invoice since they are actually same Purchase header
        Initialize();
        SetupPurchase(PurchaseHeader, Vendor, PaymentTerms);

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date") + 'D>');
        PurchaseHeader.Validate("Due Date", CalcDate(DateFormula, PurchaseHeader."Document Date"));
        PurchaseHeader.TestField("Due Date", CalcDate(DateFormula, PurchaseHeader."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderManualDueDateModificationBoundaryValuePlusOneError()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        // This covers both Purchase Order and Invoice since they are actually same Purchase header
        Initialize();
        SetupPurchase(PurchaseHeader, Vendor, PaymentTerms);

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" + 1) + 'D>');
        asserterror PurchaseHeader.Validate("Due Date", CalcDate(DateFormula, PurchaseHeader."Document Date"));
        Assert.ExpectedError(
          StrSubstNo(
            ExpectedMaxDueDateError, PurchaseHeader.FieldCaption("Due Date"),
            PaymentTerms.FieldCaption("Max. No. of Days till Due Date"), PaymentTerms.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderManualDueDateModificationBoundaryValueMinusOne()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        // This covers both Purchase Order and Invoice since they are actually same Purchase header
        Initialize();
        SetupPurchase(PurchaseHeader, Vendor, PaymentTerms);

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" - 1) + 'D>');
        PurchaseHeader.Validate("Due Date", CalcDate(DateFormula, PurchaseHeader."Document Date"));
        PurchaseHeader.TestField("Due Date", CalcDate(DateFormula, PurchaseHeader."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderManualPrePaymentDueDateModificationBoundaryValue()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        // This covers both Sales Order and Invoice since they are actually same sales header
        Initialize();
        SetupSales(SalesHeader, Customer, PaymentTerms);
        SalesHeader."Prepmt. Payment Terms Code" := PaymentTerms.Code;
        SalesHeader.Modify();

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date") + 'D>');
        SalesHeader.Validate("Prepayment Due Date", CalcDate(DateFormula, SalesHeader."Document Date"));
        SalesHeader.TestField("Prepayment Due Date", CalcDate(DateFormula, SalesHeader."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderManualPrePaymentDueDateModificationBoundaryValuePlusOneError()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        // This covers both Sales Order and Invoice since they are actually same sales header
        Initialize();
        SetupSales(SalesHeader, Customer, PaymentTerms);
        SalesHeader."Prepmt. Payment Terms Code" := PaymentTerms.Code;
        SalesHeader.Modify();

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" + 1) + 'D>');
        asserterror SalesHeader.Validate("Prepayment Due Date", CalcDate(DateFormula, SalesHeader."Document Date"));
        Assert.ExpectedError(
          StrSubstNo(
            ExpectedMaxDueDateError, SalesHeader.FieldCaption("Prepayment Due Date"),
            PaymentTerms.FieldCaption("Max. No. of Days till Due Date"), PaymentTerms.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderManualPrePaymentDueDateModificationBoundaryValueMinusOne()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        // This covers both Sales Order and Invoice since they are actually same sales header
        Initialize();
        SetupSales(SalesHeader, Customer, PaymentTerms);
        SalesHeader."Prepmt. Payment Terms Code" := PaymentTerms.Code;
        SalesHeader.Modify();

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" - 1) + 'D>');
        SalesHeader.Validate("Prepayment Due Date", CalcDate(DateFormula, SalesHeader."Document Date"));
        SalesHeader.TestField("Prepayment Due Date", CalcDate(DateFormula, SalesHeader."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderManualPrePaymentDueDateModificationBoundaryValue()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        // This covers both Purchase Order and Invoice since they are actually same Purchase header
        Initialize();
        SetupPurchase(PurchaseHeader, Vendor, PaymentTerms);
        PurchaseHeader."Prepmt. Payment Terms Code" := PaymentTerms.Code;
        PurchaseHeader.Modify();

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date") + 'D>');
        PurchaseHeader.Validate("Prepayment Due Date", CalcDate(DateFormula, PurchaseHeader."Document Date"));
        PurchaseHeader.TestField("Prepayment Due Date", CalcDate(DateFormula, PurchaseHeader."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderManualPrePaymentDueDateModificationBoundaryValuePlusOneError()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        // This covers both Purchase Order and Invoice since they are actually same Purchase header
        Initialize();
        SetupPurchase(PurchaseHeader, Vendor, PaymentTerms);
        PurchaseHeader."Prepmt. Payment Terms Code" := PaymentTerms.Code;
        PurchaseHeader.Modify();

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" + 1) + 'D>');
        asserterror PurchaseHeader.Validate("Prepayment Due Date", CalcDate(DateFormula, PurchaseHeader."Document Date"));
        Assert.ExpectedError(
          StrSubstNo(
            ExpectedMaxDueDateError, PurchaseHeader.FieldCaption("Prepayment Due Date"),
            PaymentTerms.FieldCaption("Max. No. of Days till Due Date"), PaymentTerms.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderManualPrePaymentDueDateModificationBoundaryValueMinusOne()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        // This covers both Purchase Order and Invoice since they are actually same Purchase header
        Initialize();
        SetupPurchase(PurchaseHeader, Vendor, PaymentTerms);
        PurchaseHeader."Prepmt. Payment Terms Code" := PaymentTerms.Code;
        PurchaseHeader.Modify();

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" - 1) + 'D>');
        PurchaseHeader.Validate("Prepayment Due Date", CalcDate(DateFormula, PurchaseHeader."Document Date"));
        PurchaseHeader.TestField("Prepayment Due Date", CalcDate(DateFormula, PurchaseHeader."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceHeaderManualDueDateModificationBoundaryValue()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        // This covers both Service Order and Invoice since they are actually same Service header
        Initialize();
        SetupService(ServiceHeader, Customer, PaymentTerms);

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date") + 'D>');
        ServiceHeader.Validate("Due Date", CalcDate(DateFormula, ServiceHeader."Document Date"));
        ServiceHeader.TestField("Due Date", CalcDate(DateFormula, ServiceHeader."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceHeaderManualDueDateModificationBoundaryValuePlusOneError()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        // This covers both Service Order and Invoice since they are actually same Service header
        Initialize();
        SetupService(ServiceHeader, Customer, PaymentTerms);

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" + 1) + 'D>');
        asserterror ServiceHeader.Validate("Due Date", CalcDate(DateFormula, ServiceHeader."Document Date"));
        Assert.ExpectedError(
          StrSubstNo(
            ExpectedMaxDueDateError, ServiceHeader.FieldCaption("Due Date"), PaymentTerms.FieldCaption("Max. No. of Days till Due Date"),
            PaymentTerms.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceHeaderManualDueDateModificationBoundaryValueMinusOne()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        DateFormula: DateFormula;
    begin
        // This covers both Service Order and Invoice since they are actually same Service header
        Initialize();
        SetupService(ServiceHeader, Customer, PaymentTerms);

        Evaluate(DateFormula, '<' + Format(PaymentTerms."Max. No. of Days till Due Date" - 1) + 'D>');
        ServiceHeader.Validate("Due Date", CalcDate(DateFormula, ServiceHeader."Document Date"));
        ServiceHeader.TestField("Due Date", CalcDate(DateFormula, ServiceHeader."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodForward1PeriodBefore()
    var
        CustomerNo: Code[20];
        FromDate: Date;
        ToDate: Date;
        DueDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate, ToDate, 'CM+1M');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate, ToDate);
        DueDate := PickDateBeforePeriod(FromDate, '1M');
        VerifySalesDueDateAdjust(CustomerNo, 0D, 99991231D, DueDate, DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodForward1PeriodDuring()
    var
        CustomerNo: Code[20];
        FromDate: Date;
        ToDate: Date;
        DueDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate, ToDate, 'CM+1M');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate, ToDate);
        DueDate := LibraryUtility.GenerateRandomDate(FromDate, ToDate);
        VerifySalesDueDateAdjust(CustomerNo, 0D, 99991231D, CalcDate('<1D>', ToDate), DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodForward1PeriodDuringWithMinDate()
    var
        CustomerNo: Code[20];
        FromDate: Date;
        ToDate: Date;
        DueDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate, ToDate, 'CM+1M');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate, ToDate);
        DueDate := LibraryUtility.GenerateRandomDate(FromDate, ToDate);
        VerifySalesDueDateAdjust(CustomerNo, CalcDate('<2D>', ToDate), 99991231D, 0D, DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodForward1PeriodAfter()
    var
        CustomerNo: Code[20];
        FromDate: Date;
        ToDate: Date;
        DueDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate, ToDate, 'CM+1M');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate, ToDate);
        DueDate := PickDateAfterPeriod(ToDate, '1M');
        VerifySalesDueDateAdjust(CustomerNo, 0D, 99991231D, DueDate, DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodForward2PeriodsSeparateP1()
    var
        CustomerNo: Code[20];
        FromDate: array[2] of Date;
        ToDate: array[2] of Date;
        DueDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate[1], ToDate[1], 'CM+1M');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate[1], ToDate[1]);
        AddPeriodSeparate(ToDate[1], FromDate[2], ToDate[2], '1M');
        CreateNonPaymentPeriod(CustomerNo, PaymentTableNameOption::Customer, FromDate[2], ToDate[2]);
        DueDate := LibraryUtility.GenerateRandomDate(FromDate[1], ToDate[1]);
        VerifySalesDueDateAdjust(CustomerNo, 0D, 99991231D, CalcDate('<1D>', ToDate[1]), DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodForward2PeriodsSeparateP2()
    var
        CustomerNo: Code[20];
        FromDate: array[2] of Date;
        ToDate: array[2] of Date;
        DueDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate[1], ToDate[1], 'CM+1M');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate[1], ToDate[1]);
        AddPeriodSeparate(ToDate[1], FromDate[2], ToDate[2], '1M');
        CreateNonPaymentPeriod(CustomerNo, PaymentTableNameOption::Customer, FromDate[2], ToDate[2]);
        DueDate := LibraryUtility.GenerateRandomDate(FromDate[2], ToDate[2]);
        VerifySalesDueDateAdjust(CustomerNo, 0D, 99991231D, CalcDate('<1D>', ToDate[2]), DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodForward2PeriodsOverlap()
    var
        CustomerNo: Code[20];
        FromDate: array[2] of Date;
        ToDate: array[2] of Date;
        DueDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate[1], ToDate[1], 'CM+1M');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate[1], ToDate[1]);
        AddPeriodOverlap(FromDate[1], ToDate[1], FromDate[2], ToDate[2], '1M');
        CreateNonPaymentPeriod(CustomerNo, PaymentTableNameOption::Customer, FromDate[2], ToDate[2]);
        DueDate := LibraryUtility.GenerateRandomDate(FromDate[1], FromDate[2]);
        VerifySalesDueDateAdjust(CustomerNo, 0D, 99991231D, CalcDate('<1D>', ToDate[2]), DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodForward2PeriodsAdjacent()
    var
        CustomerNo: Code[20];
        FromDate: array[2] of Date;
        ToDate: array[2] of Date;
        DueDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate[1], ToDate[1], 'CM+1M');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate[1], ToDate[1]);
        AddPeriodAdjacent(ToDate[1], FromDate[2], ToDate[2], '1M');
        CreateNonPaymentPeriod(CustomerNo, PaymentTableNameOption::Customer, FromDate[2], ToDate[2]);
        DueDate := LibraryUtility.GenerateRandomDate(FromDate[1], ToDate[1]);
        VerifySalesDueDateAdjust(CustomerNo, 0D, 99991231D, CalcDate('<1D>', ToDate[2]), DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodBackward1PeriodBefore()
    var
        CustomerNo: Code[20];
        FromDate: Date;
        ToDate: Date;
        DueDate: Date;
        MaxDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate, ToDate, 'CM+1M');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate, ToDate);
        DueDate := PickDateBeforePeriod(FromDate, '1M');
        MaxDate := ToDate;
        VerifySalesDueDateAdjust(CustomerNo, 0D, MaxDate, DueDate, DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodBackward1PeriodDuring()
    var
        CustomerNo: Code[20];
        FromDate: Date;
        ToDate: Date;
        DueDate: Date;
        MaxDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate, ToDate, 'CM+1M');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate, ToDate);
        DueDate := LibraryUtility.GenerateRandomDate(FromDate, ToDate);
        MaxDate := ToDate;
        VerifySalesDueDateAdjust(CustomerNo, 0D, MaxDate, CalcDate('<-1D>', FromDate), DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodBackward1PeriodDuringWithMinDate()
    var
        CustomerNo: Code[20];
        FromDate: Date;
        ToDate: Date;
        DueDate: Date;
        MaxDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate, ToDate, 'CM+1M');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate, ToDate);
        DueDate := LibraryUtility.GenerateRandomDate(FromDate, ToDate);
        MaxDate := ToDate;
        VerifySalesDueDateAdjust(CustomerNo, CalcDate('<1D>', FromDate), MaxDate, 0D, DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodBackward1PeriodAfter()
    var
        CustomerNo: Code[20];
        FromDate: Date;
        ToDate: Date;
        DueDate: Date;
        MaxDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate, ToDate, 'CM+1M');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate, ToDate);
        DueDate := PickDateAfterPeriod(ToDate, '1M');
        MaxDate := ToDate;
        VerifySalesDueDateAdjust(CustomerNo, 0D, MaxDate, CalcDate('<-1D>', FromDate), DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodBackward2PeriodsSeparateDueDateP1MaxP1()
    var
        CustomerNo: Code[20];
        FromDate: array[2] of Date;
        ToDate: array[2] of Date;
        DueDate: Date;
        MaxDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate[1], ToDate[1], '<CM+1M>');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate[1], ToDate[1]);
        AddPeriodSeparate(ToDate[1], FromDate[2], ToDate[2], '1M');
        CreateNonPaymentPeriod(CustomerNo, PaymentTableNameOption::Customer, FromDate[2], ToDate[2]);
        DueDate := LibraryUtility.GenerateRandomDate(FromDate[1], ToDate[1]);
        MaxDate := ToDate[1];
        VerifySalesDueDateAdjust(CustomerNo, 0D, MaxDate, CalcDate('<-1D>', FromDate[1]), DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodBackward2PeriodsSeparateDueDateP2MaxP1()
    var
        CustomerNo: Code[20];
        FromDate: array[2] of Date;
        ToDate: array[2] of Date;
        DueDate: Date;
        MaxDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate[1], ToDate[1], '<CM+1M>');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate[1], ToDate[1]);
        AddPeriodSeparate(ToDate[1], FromDate[2], ToDate[2], '1M');
        CreateNonPaymentPeriod(CustomerNo, PaymentTableNameOption::Customer, FromDate[2], ToDate[2]);
        DueDate := LibraryUtility.GenerateRandomDate(FromDate[2], ToDate[2]);
        MaxDate := ToDate[1];
        VerifySalesDueDateAdjust(CustomerNo, 0D, MaxDate, CalcDate('<-1D>', FromDate[1]), DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodBackward2PeriodsSeparateDueDateP2MaxP2()
    var
        CustomerNo: Code[20];
        FromDate: array[2] of Date;
        ToDate: array[2] of Date;
        DueDate: Date;
        MaxDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate[1], ToDate[1], '<CM+1M>');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate[1], ToDate[1]);
        AddPeriodSeparate(ToDate[1], FromDate[2], ToDate[2], '1M');
        CreateNonPaymentPeriod(CustomerNo, PaymentTableNameOption::Customer, FromDate[2], ToDate[2]);
        DueDate := LibraryUtility.GenerateRandomDate(FromDate[2], ToDate[2]);
        MaxDate := ToDate[2];
        VerifySalesDueDateAdjust(CustomerNo, 0D, MaxDate, CalcDate('<-1D>', FromDate[2]), DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodBackward2PeriodsOverlap()
    var
        CustomerNo: Code[20];
        FromDate: array[2] of Date;
        ToDate: array[2] of Date;
        DueDate: Date;
        MaxDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate[1], ToDate[1], '<CM+1M>');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate[1], ToDate[1]);
        AddPeriodOverlap(FromDate[1], ToDate[1], FromDate[2], ToDate[2], '1M');
        CreateNonPaymentPeriod(CustomerNo, PaymentTableNameOption::Customer, FromDate[2], ToDate[2]);
        DueDate := LibraryUtility.GenerateRandomDate(ToDate[1], ToDate[2]);
        MaxDate := ToDate[2];
        VerifySalesDueDateAdjust(CustomerNo, 0D, MaxDate, CalcDate('<-1D>', FromDate[1]), DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToNonPaymentPeriodBackward2PeriodsAdjacent()
    var
        CustomerNo: Code[20];
        FromDate: array[2] of Date;
        ToDate: array[2] of Date;
        DueDate: Date;
        MaxDate: Date;
    begin
        Initialize();

        Create1RandomPeriod(FromDate[1], ToDate[1], '<CM+1M>');
        CreateCustomerWithNonPaymentPeriod(CustomerNo, FromDate[1], ToDate[1]);
        AddPeriodAdjacent(ToDate[1], FromDate[2], ToDate[2], '1M');
        CreateNonPaymentPeriod(CustomerNo, PaymentTableNameOption::Customer, FromDate[2], ToDate[2]);
        DueDate := LibraryUtility.GenerateRandomDate(FromDate[2], ToDate[2]);
        MaxDate := ToDate[2];
        VerifySalesDueDateAdjust(CustomerNo, 0D, MaxDate, CalcDate('<-1D>', FromDate[1]), DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayForward1DayBefore()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay := LibraryRandom.RandIntInRange(2, 31);
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        DueDate :=
          LibraryUtility.GenerateRandomDate(CreateDateWithDayAndWorkDate(PayDay + 1, '-1M'), CreateDateWithDayAndWorkDate(PayDay - 1, ''));
        VerifySalesDueDateAdjust(CustomerNo, 0D, 99991231D, CreateDateWithDayAndWorkDate(PayDay, ''), DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayForward1DayEqual()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay := LibraryRandom.RandInt(Date2DMY(CalcDate('<CM>', WorkDate()), 1));
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        DueDate := CreateDateWithDayAndWorkDate(PayDay, '');
        VerifySalesDueDateAdjust(CustomerNo, 0D, 99991231D, DueDate, DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayForward1DayAfter()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay := LibraryRandom.RandIntInRange(1, Date2DMY(CalcDate('<CM>', WorkDate()), 1) - 1);
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        DueDate :=
          LibraryUtility.GenerateRandomDate(CreateDateWithDayAndWorkDate(PayDay + 1, ''), CreateDateWithDayAndWorkDate(PayDay - 1, '1M'));
        VerifySalesDueDateAdjust(CustomerNo, 0D, 99991231D, CreateDateWithDayAndWorkDate(PayDay, '1M'), DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayForward1DayAfterWithMinDate()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay := LibraryRandom.RandIntInRange(1, Date2DMY(CalcDate('<CM>', WorkDate()), 1) - 1);
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        DueDate :=
          LibraryUtility.GenerateRandomDate(CreateDateWithDayAndWorkDate(PayDay + 1, ''), CreateDateWithDayAndWorkDate(PayDay - 1, '1M'));
        VerifySalesDueDateAdjust(CustomerNo, CreateDateWithDayAndWorkDate(PayDay, '2M'), 99991231D, 0D, DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayForward2DaysBefore()
    var
        CustomerNo: Code[20];
        PayDay: array[2] of Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay[1] := LibraryRandom.RandIntInRange(2, 15);
        PayDay[2] := LibraryRandom.RandIntInRange(16, 31);
        CreateCustomerWithPaymentDay(CustomerNo, PayDay[1]);
        CreatePaymentDay(CustomerNo, PaymentTableNameOption::Customer, PayDay[2]);
        DueDate :=
          LibraryUtility.GenerateRandomDate(
            CreateDateWithDayAndWorkDate(PayDay[2] + 1, '-1M'), CreateDateWithDayAndWorkDate(PayDay[1] - 1, ''));
        VerifySalesDueDateAdjust(CustomerNo, 0D, 99991231D, CreateDateWithDayAndWorkDate(PayDay[1], ''), DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayForward2DaysBetween()
    var
        CustomerNo: Code[20];
        PayDay: array[2] of Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay[1] := LibraryRandom.RandInt(14);
        PayDay[2] := LibraryRandom.RandIntInRange(16, 31);
        CreateCustomerWithPaymentDay(CustomerNo, PayDay[1]);
        CreatePaymentDay(CustomerNo, PaymentTableNameOption::Customer, PayDay[2]);
        DueDate :=
          LibraryUtility.GenerateRandomDate(
            CreateDateWithDayAndWorkDate(PayDay[1] + 1, ''), CreateDateWithDayAndWorkDate(PayDay[2] - 1, ''));
        VerifySalesDueDateAdjust(CustomerNo, 0D, 99991231D, CreateDateWithDayAndWorkDate(PayDay[2], ''), DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayForward2DaysAfter()
    var
        CustomerNo: Code[20];
        PayDay: array[2] of Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay[1] := LibraryRandom.RandIntInRange(2, 15);
        PayDay[2] := LibraryRandom.RandIntInRange(16, Date2DMY(CalcDate('<CM>', WorkDate()), 1) - 1);
        CreateCustomerWithPaymentDay(CustomerNo, PayDay[1]);
        CreatePaymentDay(CustomerNo, PaymentTableNameOption::Customer, PayDay[2]);
        DueDate :=
          LibraryUtility.GenerateRandomDate(
            CreateDateWithDayAndWorkDate(PayDay[2] + 1, ''), CreateDateWithDayAndWorkDate(PayDay[1] - 1, '1M'));
        VerifySalesDueDateAdjust(CustomerNo, 0D, 99991231D, CreateDateWithDayAndWorkDate(PayDay[1], '1M'), DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayForward1DayEOM()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
        Years: array[11] of Integer;
        i: Integer;
        j: Integer;
    begin
        Initialize();

        PayDay := 31;
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        Years[1] := 1996; // EOM 29-02
        Years[2] := 2000; // EOM 29-02
        Years[3] := 2004; // EOM 29-02
        Years[4] := 2100; // EOM 28-02
        Years[5] := 2104; // EOM 29-02
        Years[6] := 2200; // EOM 28-02
        Years[7] := 2400; // EOM 29-02
        Years[8] := 2404; // EOM 29-02
        Years[9] := 2001; // EOM 28-02
        Years[10] := 2011; // EOM 28-02
        Years[11] := 2021; // EOM 28-02

        for i := 1 to ArrayLen(Years) do
            for j := 1 to 12 do begin
                DueDate := DMY2Date(15, j, Years[i]);
                VerifySalesDueDateAdjust(CustomerNo, 0D, 99991231D, CalcDate('<CM>', DMY2Date(1, j, Years[i])), DueDate)
            end
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayForward1DayEOMEOM()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
        Years: array[11] of Integer;
        i: Integer;
        j: Integer;
    begin
        Initialize();

        PayDay := 31;
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        Years[1] := 1996; // EOM 29-02
        Years[2] := 2000; // EOM 29-02
        Years[3] := 2004; // EOM 29-02
        Years[4] := 2100; // EOM 28-02
        Years[5] := 2104; // EOM 29-02
        Years[6] := 2200; // EOM 28-02
        Years[7] := 2400; // EOM 29-02
        Years[8] := 2404; // EOM 29-02
        Years[9] := 2001; // EOM 28-02
        Years[10] := 2011; // EOM 28-02
        Years[11] := 2021; // EOM 28-02

        for i := 1 to ArrayLen(Years) do
            for j := 1 to 12 do begin
                DueDate := CalcDate('<CM>', DMY2Date(1, j, Years[i]));
                VerifySalesDueDateAdjust(CustomerNo, 0D, 99991231D, CalcDate('<CM>', DMY2Date(1, j, Years[i])), DueDate)
            end
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayBackward1DayBeforeMaxBefore()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay := LibraryRandom.RandIntInRange(2, 31);
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        DueDate :=
          LibraryUtility.GenerateRandomDate(CreateDateWithDayAndWorkDate(PayDay + 1, '-1M'), CreateDateWithDayAndWorkDate(PayDay - 1, ''));
        VerifySalesDueDateAdjust(CustomerNo, 0D, CalcDate('<-1D>', DueDate), CreateDateWithDayAndWorkDate(PayDay, '-1M'), DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayBackward1DayBeforeMaxBetween()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay := LibraryRandom.RandIntInRange(2, 31);
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        DueDate :=
          LibraryUtility.GenerateRandomDate(CreateDateWithDayAndWorkDate(PayDay + 1, '-1M'), CreateDateWithDayAndWorkDate(PayDay - 1, ''));
        VerifySalesDueDateAdjust(
          CustomerNo, 0D, CalcDate('<-1D>', CreateDateWithDayAndWorkDate(PayDay, '')), CreateDateWithDayAndWorkDate(PayDay, '-1M'), DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayBackward1DayEqualMaxBefore()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay := LibraryRandom.RandInt(Date2DMY(CalcDate('<CM>', WorkDate()), 1));
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        DueDate := CreateDateWithDayAndWorkDate(PayDay, '');
        VerifySalesDueDateAdjust(CustomerNo, 0D, CalcDate('<-1D>', DueDate), CreateDateWithDayAndWorkDate(PayDay, '-1M'), DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayBackward1DayEqualMaxEqual()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay := LibraryRandom.RandInt(Date2DMY(CalcDate('<CM>', WorkDate()), 1));
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        DueDate := CreateDateWithDayAndWorkDate(PayDay, '');
        VerifySalesDueDateAdjust(CustomerNo, 0D, DueDate, DueDate, DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayBackward1DayAfterMaxBefore()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay := LibraryRandom.RandIntInRange(1, Date2DMY(CalcDate('<CM>', WorkDate()), 1) - 1);
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        DueDate :=
          LibraryUtility.GenerateRandomDate(CreateDateWithDayAndWorkDate(PayDay + 1, ''), CreateDateWithDayAndWorkDate(PayDay - 1, '1M'));
        VerifySalesDueDateAdjust(CustomerNo, 0D, CalcDate('<-1D>', DueDate), CreateDateWithDayAndWorkDate(PayDay, ''), DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayBackward1DayAfterMaxBetween()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay := LibraryRandom.RandIntInRange(1, Date2DMY(CalcDate('<CM>', WorkDate()), 1) - 1);
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        DueDate :=
          LibraryUtility.GenerateRandomDate(CreateDateWithDayAndWorkDate(PayDay + 2, ''), CreateDateWithDayAndWorkDate(PayDay - 1, '1M'));
        VerifySalesDueDateAdjust(
          CustomerNo, 0D, CalcDate('<1D>', CreateDateWithDayAndWorkDate(PayDay, '')), CreateDateWithDayAndWorkDate(PayDay, ''), DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayBackward1DayAfterMaxBetweenWithMinDate()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay := LibraryRandom.RandIntInRange(1, Date2DMY(CalcDate('<CM>', WorkDate()), 1) - 1);
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        DueDate :=
          LibraryUtility.GenerateRandomDate(CreateDateWithDayAndWorkDate(PayDay + 2, ''), CreateDateWithDayAndWorkDate(PayDay - 1, '1M'));
        VerifySalesDueDateAdjust(
          CustomerNo, CalcDate('<2D>', CreateDateWithDayAndWorkDate(PayDay, '')), CalcDate('<1D>', CreateDateWithDayAndWorkDate(PayDay, '')),
          0D, DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayForward1DayAfterWithMaxEqual()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay := LibraryRandom.RandIntInRange(1, Date2DMY(CalcDate('<CM>', WorkDate()), 1) - 1);
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        DueDate :=
          LibraryUtility.GenerateRandomDate(CreateDateWithDayAndWorkDate(PayDay + 1, ''), CreateDateWithDayAndWorkDate(PayDay - 1, '1M'));
        VerifySalesDueDateAdjust(
          CustomerNo, 0D, CreateDateWithDayAndWorkDate(PayDay, '1M'), CreateDateWithDayAndWorkDate(PayDay, '1M'), DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayForward1DayAfterWithMaxAfter()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay := LibraryRandom.RandIntInRange(1, Date2DMY(CalcDate('<CM>', WorkDate()), 1) - 1);
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        DueDate :=
          LibraryUtility.GenerateRandomDate(CreateDateWithDayAndWorkDate(PayDay + 1, ''), CreateDateWithDayAndWorkDate(PayDay - 1, '1M'));
        VerifySalesDueDateAdjust(
          CustomerNo, 0D, CalcDate('<1D>', CreateDateWithDayAndWorkDate(PayDay, '1M')), CreateDateWithDayAndWorkDate(PayDay, '1M'), DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayBackward2DaysBefore()
    var
        CustomerNo: Code[20];
        PayDay: array[2] of Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay[1] := LibraryRandom.RandIntInRange(2, 15);
        PayDay[2] := LibraryRandom.RandIntInRange(16, 31);
        CreateCustomerWithPaymentDay(CustomerNo, PayDay[1]);
        CreatePaymentDay(CustomerNo, PaymentTableNameOption::Customer, PayDay[2]);
        DueDate :=
          LibraryUtility.GenerateRandomDate(
            CreateDateWithDayAndWorkDate(PayDay[2] + 1, '-1M'), CreateDateWithDayAndWorkDate(PayDay[1] - 1, ''));
        VerifySalesDueDateAdjust(
          CustomerNo, 0D, CalcDate('<-1D>', CreateDateWithDayAndWorkDate(PayDay[1], '')), CreateDateWithDayAndWorkDate(PayDay[2], '-1M'),
          DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayBackward2DaysBeforeEdgeCase()
    var
        CustomerNo: Code[20];
    begin
        Initialize();

        CreateCustomerWithPaymentDay(CustomerNo, 2);
        CreatePaymentDay(CustomerNo, PaymentTableNameOption::Customer, 31);
        VerifySalesDueDateAdjust(CustomerNo, 0D, 20130101D, 20121231D, 20130101D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayBackward2DaysBetween()
    var
        CustomerNo: Code[20];
        PayDay: array[2] of Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay[1] := LibraryRandom.RandInt(14);
        PayDay[2] := LibraryRandom.RandIntInRange(16, 31);
        CreateCustomerWithPaymentDay(CustomerNo, PayDay[1]);
        CreatePaymentDay(CustomerNo, PaymentTableNameOption::Customer, PayDay[2]);
        DueDate :=
          LibraryUtility.GenerateRandomDate(
            CreateDateWithDayAndWorkDate(PayDay[1] + 1, ''), CreateDateWithDayAndWorkDate(PayDay[2] - 1, ''));
        VerifySalesDueDateAdjust(
          CustomerNo, 0D, CalcDate('<-1D>', CreateDateWithDayAndWorkDate(PayDay[1], '')), CreateDateWithDayAndWorkDate(PayDay[2], '-1M'),
          DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayBackward2DaysAfter()
    var
        CustomerNo: Code[20];
        PayDay: array[2] of Integer;
        DueDate: Date;
    begin
        Initialize();

        PayDay[1] := LibraryRandom.RandIntInRange(2, 15);
        PayDay[2] := LibraryRandom.RandIntInRange(16, Date2DMY(CalcDate('<CM>', WorkDate()), 1) - 1);
        CreateCustomerWithPaymentDay(CustomerNo, PayDay[1]);
        CreatePaymentDay(CustomerNo, PaymentTableNameOption::Customer, PayDay[2]);
        DueDate :=
          LibraryUtility.GenerateRandomDate(
            CreateDateWithDayAndWorkDate(PayDay[2] + 1, ''), CreateDateWithDayAndWorkDate(PayDay[1] - 1, '1M'));
        VerifySalesDueDateAdjust(
          CustomerNo, 0D, CalcDate('<-1D>', CreateDateWithDayAndWorkDate(PayDay[1], '')), CreateDateWithDayAndWorkDate(PayDay[2], '-1M'),
          DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayBackward1DayEOM()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
        Years: array[11] of Integer;
        i: Integer;
        j: Integer;
    begin
        Initialize();

        PayDay := 31;
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        Years[1] := 1996; // EOM 29-02
        Years[2] := 2000; // EOM 29-02
        Years[3] := 2004; // EOM 29-02
        Years[4] := 2100; // EOM 28-02
        Years[5] := 2104; // EOM 29-02
        Years[6] := 2200; // EOM 28-02
        Years[7] := 2400; // EOM 29-02
        Years[8] := 2404; // EOM 29-02
        Years[9] := 2001; // EOM 28-02
        Years[10] := 2011; // EOM 28-02
        Years[11] := 2021; // EOM 28-02

        for i := 1 to ArrayLen(Years) do
            for j := 1 to 12 do begin
                DueDate := DMY2Date(15, j, Years[i]);
                VerifySalesDueDateAdjust(
                  CustomerNo, 0D, CalcDate('<-1D>', DueDate), CalcDate('<CM>', CalcDate('<-1M>', DMY2Date(1, j, Years[i]))), DueDate)
            end
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayBackward1DayEOMEOM()
    var
        CustomerNo: Code[20];
        PayDay: Integer;
        DueDate: Date;
        Years: array[11] of Integer;
        i: Integer;
        j: Integer;
    begin
        Initialize();

        PayDay := 31;
        CreateCustomerWithPaymentDay(CustomerNo, PayDay);
        Years[1] := 1996; // EOM 29-02
        Years[2] := 2000; // EOM 29-02
        Years[3] := 2004; // EOM 29-02
        Years[4] := 2100; // EOM 28-02
        Years[5] := 2104; // EOM 29-02
        Years[6] := 2200; // EOM 28-02
        Years[7] := 2400; // EOM 29-02
        Years[8] := 2404; // EOM 29-02
        Years[9] := 2001; // EOM 28-02
        Years[10] := 2011; // EOM 28-02
        Years[11] := 2021; // EOM 28-02

        for i := 1 to ArrayLen(Years) do
            for j := 1 to 12 do begin
                DueDate := CalcDate('<CM>', DMY2Date(1, j, Years[i]));
                VerifySalesDueDateAdjust(
                  CustomerNo, 0D, CalcDate('<-1D>', DueDate), CalcDate('<CM>', CalcDate('<-1M>', DMY2Date(1, j, Years[i]))), DueDate)
            end
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayForward2PeriodsSeparateWith2PaymentDays()
    var
        CustomerNo: Code[20];
    begin
        Initialize();

        CreateCustomerWithNonPaymentPeriod(CustomerNo, CreateDateWithDayAndWorkDate(15, ''), CreateDateWithDayAndWorkDate(16, ''));
        CreateNonPaymentPeriod(
          CustomerNo, PaymentTableNameOption::Customer, CreateDateWithDayAndWorkDate(18, ''), CreateDateWithDayAndWorkDate(23, ''));
        CreateCustomerWithPaymentDay(CustomerNo, 20);
        VerifySalesDueDateAdjust(CustomerNo, 0D, 99991231D, CreateDateWithDayAndWorkDate(20, '1M'), CreateDateWithDayAndWorkDate(15, ''))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayWithoutPaymentDaysORNonPaymentPeriod()
    var
        Customer: Record Customer;
        DueDate: Date;
    begin
        Initialize();

        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer);
        Customer.Insert();
        DueDate := LibraryUtility.GenerateRandomDate(WorkDate(), CalcDate('<1Y>', WorkDate()));
        VerifySalesDueDateAdjust(Customer."No.", 0D, 99991231D, DueDate, DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayWithoutPaymentDaysORNonPaymentPeriodMinDate()
    var
        Customer: Record Customer;
        DueDate: Date;
    begin
        Initialize();

        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer);
        Customer.Insert();
        DueDate := LibraryUtility.GenerateRandomDate(WorkDate(), CalcDate('<1Y>', WorkDate()));
        VerifySalesDueDateAdjust(Customer."No.", CalcDate('<1D>', DueDate), 99991231D, 0D, DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustAdjustToPaymentDayWithoutPaymentDaysORNonPaymentPeriodMaxDate()
    var
        Customer: Record Customer;
        DueDate: Date;
    begin
        Initialize();

        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer);
        Customer.Insert();
        DueDate := LibraryUtility.GenerateRandomDate(WorkDate(), CalcDate('<1Y>', WorkDate()));
        VerifySalesDueDateAdjust(Customer."No.", 0D, CalcDate('<-1D>', DueDate), CalcDate('<-1D>', DueDate), DueDate)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustPurchVendor()
    var
        VendorNo: Code[20];
        DueDate: Date;
        VendorPayDay: Integer;
        CompanyPayDay: Integer;
    begin
        Initialize();

        VendorPayDay := LibraryRandom.RandIntInRange(2, 20);
        CompanyPayDay := LibraryRandom.RandIntInRange(VendorPayDay, 31);
        CreateVendorWithPaymentDay(VendorNo, VendorPayDay);
        UpdateCompanyInfoWithPaymentDay(CompanyPayDay);
        DueDate :=
          LibraryUtility.GenerateRandomDate(
            CreateDateWithDayAndWorkDate(CompanyPayDay + 1, '-1M'), CreateDateWithDayAndWorkDate(VendorPayDay - 1, ''));
        VerifyPurchDueDateAdjust(VendorNo, 0D, 99991231D, CreateDateWithDayAndWorkDate(VendorPayDay, ''), DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDueDateAdjustPurchCompanyInfo()
    var
        Vendor: Record Vendor;
        DueDate: Date;
        CompanyPayDay: Integer;
    begin
        Initialize();

        CompanyPayDay := LibraryRandom.RandIntInRange(2, 31);
        Vendor."No." := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor);
        Vendor.Insert();
        UpdateCompanyInfoWithPaymentDay(CompanyPayDay);
        DueDate :=
          LibraryUtility.GenerateRandomDate(
            CreateDateWithDayAndWorkDate(CompanyPayDay + 1, '-1M'), CreateDateWithDayAndWorkDate(CompanyPayDay - 1, ''));
        VerifyPurchDueDateAdjust(Vendor."No.", 0D, 99991231D, CreateDateWithDayAndWorkDate(CompanyPayDay, ''), DueDate);
    end;

    local procedure VerifySalesDueDateAdjust(CustomerNo: Code[20]; MinDate: Date; MaxDate: Date; ExpectedDueDate: Date; DueDate: Date)
    var
        DueDateAdjust: Codeunit "Due Date-Adjust";
    begin
        DueDateAdjust.SalesAdjustDueDate(DueDate, MinDate, MaxDate, CustomerNo);
        Assert.AreEqual(ExpectedDueDate, DueDate, IncorrectDueDateError)
    end;

    local procedure VerifyPurchDueDateAdjust(VendorNo: Code[20]; MinDate: Date; MaxDate: Date; ExpectedDueDate: Date; DueDate: Date)
    var
        DueDateAdjust: Codeunit "Due Date-Adjust";
    begin
        DueDateAdjust.PurchAdjustDueDate(DueDate, MinDate, MaxDate, VendorNo);
        Assert.AreEqual(ExpectedDueDate, DueDate, IncorrectDueDateError)
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        Commit();
    end;

    [Normal]
    local procedure CreateGeneralJournalLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        RecRef: RecordRef;
    begin
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        GenJnlLine.Init();
        GenJnlLine.Validate("Journal Template Name", GenJournalTemplate.Name);
        GenJnlLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        RecRef.GetTable(GenJnlLine);
        GenJnlLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, GenJnlLine.FieldNo("Line No.")));
        GenJnlLine."Document Date" := WorkDate();
        GenJnlLine.Insert();
    end;

    [Normal]
    local procedure CreatePaymentTerms(var PaymentTerms: Record "Payment Terms")
    begin
        PaymentTerms.Init();
        PaymentTerms.Code := LibraryUtility.GenerateRandomCode(PaymentTerms.FieldNo(Code), DATABASE::"Payment Terms");
        PaymentTerms."Max. No. of Days till Due Date" := LibraryRandom.RandInt(10);
        PaymentTerms.Insert();
    end;

    local procedure CreateNonPaymentPeriod(var NonPaymentPeriodCode: Code[20]; TableNameOption: Option; FromDate: Date; ToDate: Date)
    var
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        NonPaymentPeriod."Table Name" := TableNameOption;
        if NonPaymentPeriodCode = '' then
            NonPaymentPeriodCode := LibraryUtility.GenerateRandomCode(NonPaymentPeriod.FieldNo(Code), DATABASE::"Non-Payment Period");
        NonPaymentPeriod.Code := NonPaymentPeriodCode;
        NonPaymentPeriod."From Date" := FromDate;
        NonPaymentPeriod."To Date" := ToDate;
        NonPaymentPeriod.Insert();
    end;

    local procedure CreatePaymentDay(var PaymentDayCode: Code[20]; TableNameOption: Option; PayDay: Integer)
    var
        PaymentDay: Record "Payment Day";
    begin
        PaymentDay."Table Name" := TableNameOption;
        if PaymentDayCode = '' then
            PaymentDayCode := LibraryUtility.GenerateRandomCode(PaymentDay.FieldNo(Code), DATABASE::"Payment Day");
        PaymentDay.Code := PaymentDayCode;
        PaymentDay."Day of the month" := PayDay;
        PaymentDay.Insert();
    end;

    local procedure CreateCustomerWithNonPaymentPeriod(var CustomerNo: Code[20]; FromDate: Date; ToDate: Date)
    var
        Customer: Record Customer;
        ExistingCustomer: Boolean;
    begin
        CreateNonPaymentPeriod(CustomerNo, PaymentTableNameOption::Customer, FromDate, ToDate);
        ExistingCustomer := Customer.Get(CustomerNo);
        Customer."Non-Paymt. Periods Code" := CustomerNo;
        if not ExistingCustomer then begin
            Customer."No." := CustomerNo;
            Customer.Insert();
        end else
            Customer.Modify();
    end;

    local procedure CreateCustomerWithPaymentDay(var CustomerNo: Code[20]; PayDay: Integer)
    var
        Customer: Record Customer;
        ExistingCustomer: Boolean;
    begin
        CreatePaymentDay(CustomerNo, PaymentTableNameOption::Customer, PayDay);
        ExistingCustomer := Customer.Get(CustomerNo);
        Customer."Payment Days Code" := CustomerNo;
        if not ExistingCustomer then begin
            Customer."No." := CustomerNo;
            Customer.Insert();
        end else
            Customer.Modify();
    end;

    local procedure CreateVendorWithPaymentDay(var VendorNo: Code[20]; PayDay: Integer)
    var
        Vendor: Record Vendor;
        ExistingVendor: Boolean;
    begin
        CreatePaymentDay(VendorNo, PaymentTableNameOption::Vendor, PayDay);
        ExistingVendor := Vendor.Get(VendorNo);
        Vendor."Payment Days Code" := VendorNo;
        if not ExistingVendor then begin
            Vendor."No." := VendorNo;
            Vendor.Insert();
        end else
            Vendor.Modify();
    end;

    local procedure UpdateCompanyInfoWithPaymentDay(PayDay: Integer)
    var
        CompanyInfo: Record "Company Information";
        PaymentDayCode: Code[20];
    begin
        CreatePaymentDay(PaymentDayCode, PaymentTableNameOption::"Company Information", PayDay);
        CompanyInfo.Get();
        CompanyInfo."Payment Days Code" := PaymentDayCode;
        CompanyInfo.Modify();
    end;

    local procedure Create1RandomPeriod(var FromDate: Date; var ToDate: Date; RangeFormula: Code[10])
    begin
        FromDate := LibraryUtility.GenerateRandomDate(WorkDate(), CalcDate('<1Y>', WorkDate()));
        ToDate := LibraryUtility.GenerateRandomDate(FromDate, CalcDate(StrSubstNo('<%1>', RangeFormula), FromDate))
    end;

    local procedure AddPeriodSeparate(PrevToDate: Date; var FromDate: Date; var ToDate: Date; RangeFormula: Code[10])
    begin
        FromDate := PickDateAfterPeriod(CalcDate('<1D>', PrevToDate), '1M');
        ToDate := LibraryUtility.GenerateRandomDate(FromDate, CalcDate(StrSubstNo('<%1>', RangeFormula), FromDate))
    end;

    local procedure AddPeriodOverlap(PrevFromDate: Date; var PrevToDate: Date; var FromDate: Date; var ToDate: Date; RangeFormula: Code[10])
    begin
        FromDate := LibraryUtility.GenerateRandomDate(CalcDate('<1D>', PrevFromDate), PrevToDate);
        ToDate := LibraryUtility.GenerateRandomDate(PrevToDate, CalcDate(StrSubstNo('<%1>', RangeFormula), PrevToDate));
    end;

    local procedure AddPeriodAdjacent(PrevToDate: Date; var FromDate: Date; var ToDate: Date; RangeFormula: Code[10])
    begin
        FromDate := CalcDate('<1D>', PrevToDate);
        ToDate := LibraryUtility.GenerateRandomDate(PrevToDate, CalcDate(StrSubstNo('<%1>', RangeFormula), PrevToDate))
    end;

    local procedure PickDateBeforePeriod(FromDate: Date; RangeFormula: Code[10]): Date
    begin
        exit(LibraryUtility.GenerateRandomDate(CalcDate(StrSubstNo('<-1D-%1>', RangeFormula), FromDate), CalcDate('<-1D>', FromDate)))
    end;

    local procedure PickDateAfterPeriod(ToDate: Date; RangeFormula: Code[10]): Date
    begin
        exit(LibraryUtility.GenerateRandomDate(CalcDate('<1D>', ToDate), CalcDate(StrSubstNo('<1D+%1>', RangeFormula), ToDate)))
    end;

    local procedure CreateDateWithDayAndWorkDate(Day: Integer; OffsetFormula: Code[10]): Date
    var
        BaseDate: Date;
        EndOfBaseMonth: Integer;
    begin
        BaseDate := WorkDate();
        if OffsetFormula <> '' then
            BaseDate := CalcDate(StrSubstNo('<%1>', OffsetFormula), WorkDate());
        EndOfBaseMonth := Date2DMY(CalcDate('<CM>', BaseDate), 1);
        if Day > EndOfBaseMonth then
            Day := EndOfBaseMonth;
        if Day < 1 then
            Day := 1;
        exit(DMY2Date(Day, Date2DMY(BaseDate, 2), Date2DMY(BaseDate, 3)))
    end;

    [Normal]
    local procedure SetupSales(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var PaymentTerms: Record "Payment Terms")
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CreatePaymentTerms(PaymentTerms);
        SalesHeader."Payment Terms Code" := PaymentTerms.Code;
        SalesHeader."Document Date" := WorkDate();
        SalesHeader.Modify();
    end;

    [Normal]
    local procedure SetupPurchase(var PurchaseHeader: Record "Purchase Header"; var Vendor: Record Vendor; var PaymentTerms: Record "Payment Terms")
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        CreatePaymentTerms(PaymentTerms);
        PurchaseHeader."Payment Terms Code" := PaymentTerms.Code;
        PurchaseHeader."Document Date" := WorkDate();
        PurchaseHeader.Modify();
    end;

    [Normal]
    local procedure SetupService(var ServiceHeader: Record "Service Header"; var Customer: Record Customer; var PaymentTerms: Record "Payment Terms")
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        CreatePaymentTerms(PaymentTerms);
        ServiceHeader."Payment Terms Code" := PaymentTerms.Code;
        ServiceHeader."Document Date" := WorkDate();
        ServiceHeader.Modify();
    end;
}

