codeunit 147593 "Due Date Modified Payment Days"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Days] [Due Date Modified] [Installments]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        DueDateModifiedErr: Label '%1 must be %2 in %3.', Comment = '%1 = Field Caption, %2 = Expected Value (true/false), %3 = Table Name';

    [Test]
    procedure DueDateModifiedIsFalseWhenPaymentDayAdjustsDueDateOnSalesInvoice()
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        PaymentDayValue: Integer;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Due Date Modified remains false when Payment Days adjusts Due Date on Sales Invoice
        Initialize();

        // [GIVEN] Payment Terms with Due Date Calculation of 1M
        CreatePaymentTermsWithDueDateCalc(PaymentTerms, '<1M>');

        // [GIVEN] Customer "C" with Payment Day set to day 25
        PaymentDayValue := 25;
        CreateCustomerWithPaymentDayAndTerms(Customer, PaymentDayValue, PaymentTerms.Code);

        // [WHEN] Sales Invoice is created for Customer "C"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [THEN] Due Date Modified must be False
        Assert.IsFalse(
            SalesHeader."Due Date Modified",
            StrSubstNo(DueDateModifiedErr, SalesHeader.FieldCaption("Due Date Modified"), false, SalesHeader.TableName()));
    end;

    [Test]
    procedure DueDateModifiedIsFalseWhenPaymentDayAdjustsDueDateOnPurchaseOrder()
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PaymentDayValue: Integer;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Due Date Modified remains false when Payment Days adjusts Due Date on Purchase Order
        Initialize();

        // [GIVEN] Payment Terms with Due Date Calculation of 1M
        CreatePaymentTermsWithDueDateCalc(PaymentTerms, '<1M>');

        // [GIVEN] Vendor "V" with Payment Day set to day 25
        PaymentDayValue := 25;
        CreateVendorWithPaymentDayAndTerms(Vendor, PaymentDayValue, PaymentTerms.Code);

        // [WHEN] Purchase Order is created for Vendor "V"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [THEN] Due Date Modified must be False
        Assert.IsFalse(
            PurchaseHeader."Due Date Modified",
            StrSubstNo(DueDateModifiedErr, PurchaseHeader.FieldCaption("Due Date Modified"), false, PurchaseHeader.TableName()));
    end;

    [Test]
    procedure PaymentDaysAppliedToAllInstallmentsWhenPostingSalesInvoice()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        DocumentNo: Code[20];
        PaymentDayValue: Integer;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Payment Days are applied to all installments when posting Sales Invoice with multiple installments
        Initialize();

        // [GIVEN] Payment Terms "PT" with Due Date Calculation of 1M and 3 installments with 1M gap
        CreatePaymentTermsWithDueDateCalc(PaymentTerms, '<1M>');
        LibraryCarteraReceivables.CreateMultipleInstallments(PaymentTerms.Code, 3);

        // [GIVEN] Bill-to-Cartera Payment Method "PM"
        LibraryCarteraReceivables.CreateBillToCarteraPaymentMethod(PaymentMethod);

        // [GIVEN] Customer "C" with Payment Day set to day 15 and Payment Terms "PT"
        PaymentDayValue := 15;
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Payment Days Code", CreatePaymentDayCode(PaymentDayValue));
        Customer.Modify(true);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);

        // [GIVEN] Sales Invoice "SI" for Customer "C"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.FindItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(1000, 2));

        // [WHEN] Sales Invoice "SI" is posted
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] All Customer Ledger Entries for bills have Due Date with day = 15 (Payment Day)
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Bill);
        CustLedgerEntry.FindSet();
        repeat
            Assert.AreEqual(
                PaymentDayValue,
                Date2DMY(CustLedgerEntry."Due Date", 1),
                StrSubstNo('Due Date day should be %1 for Bill %2', PaymentDayValue, CustLedgerEntry."Bill No."));
        until CustLedgerEntry.Next() = 0;
    end;

    [Test]
    procedure DueDateModifiedIsTrueWhenUserManuallyChangesDueDateOnSalesInvoice()
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        PaymentDayValue: Integer;
        ManualDueDate: Date;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Due Date Modified is True when user manually changes Due Date to a non-calculated value
        Initialize();

        // [GIVEN] Payment Terms with Due Date Calculation of 1M
        CreatePaymentTermsWithDueDateCalc(PaymentTerms, '<1M>');

        // [GIVEN] Customer "C" with Payment Day set to day 25
        PaymentDayValue := 25;
        CreateCustomerWithPaymentDayAndTerms(Customer, PaymentDayValue, PaymentTerms.Code);

        // [GIVEN] Sales Invoice for Customer "C"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] User manually changes Due Date to a different value
        ManualDueDate := CalcDate('<2M>', SalesHeader."Document Date");
        SalesHeader.Validate("Due Date", ManualDueDate);
        SalesHeader.Modify(true);

        // [THEN] Due Date Modified must be True
        Assert.IsTrue(
            SalesHeader."Due Date Modified",
            StrSubstNo(DueDateModifiedErr, SalesHeader.FieldCaption("Due Date Modified"), true, SalesHeader.TableName()));
    end;

    [Test]
    procedure DueDateModifiedIsFalseAfterRevalidatingDueDateToCalculatedValueOnSalesInvoice()
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        PaymentDayValue: Integer;
        OriginalDueDate: Date;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Due Date Modified returns to False when user sets Due Date back to the calculated value
        Initialize();

        // [GIVEN] Payment Terms with Due Date Calculation of 1M
        CreatePaymentTermsWithDueDateCalc(PaymentTerms, '<1M>');

        // [GIVEN] Customer "C" with Payment Day set to day 25
        PaymentDayValue := 25;
        CreateCustomerWithPaymentDayAndTerms(Customer, PaymentDayValue, PaymentTerms.Code);

        // [GIVEN] Sales Invoice for Customer "C" with original Due Date
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        OriginalDueDate := SalesHeader."Due Date";

        // [GIVEN] User changes Due Date to a different value
        SalesHeader.Validate("Due Date", CalcDate('<3M>', SalesHeader."Document Date"));
        SalesHeader.Modify(true);

        // [WHEN] User sets Due Date back to the originally calculated value
        SalesHeader.Validate("Due Date", OriginalDueDate);
        SalesHeader.Modify(true);

        // [THEN] Due Date Modified must be False
        Assert.IsFalse(
            SalesHeader."Due Date Modified",
            StrSubstNo(DueDateModifiedErr, SalesHeader.FieldCaption("Due Date Modified"), false, SalesHeader.TableName()));
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        Commit();
        IsInitialized := true;
    end;

    local procedure CreatePaymentTermsWithDueDateCalc(var PaymentTerms: Record "Payment Terms"; DueDateCalcFormula: Text)
    var
        DateFormula: DateFormula;
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(DateFormula, DueDateCalcFormula);
        PaymentTerms.Validate("Due Date Calculation", DateFormula);
        PaymentTerms.Modify(true);
    end;

    local procedure CreatePaymentDayCode(PaymentDayValue: Integer): Code[20]
    var
        PaymentDay: Record "Payment Day";
        PaymentDayCode: Code[20];
    begin
        PaymentDayCode := LibraryUtility.GenerateRandomCode(PaymentDay.FieldNo(Code), Database::"Payment Day");
        PaymentDay.Init();
        PaymentDay."Table Name" := PaymentDay."Table Name"::Customer;
        PaymentDay.Code := PaymentDayCode;
        PaymentDay."Day of the month" := PaymentDayValue;
        PaymentDay.Insert();
        exit(PaymentDayCode);
    end;

    local procedure CreateVendorPaymentDayCode(PaymentDayValue: Integer): Code[20]
    var
        PaymentDay: Record "Payment Day";
        PaymentDayCode: Code[20];
    begin
        PaymentDayCode := LibraryUtility.GenerateRandomCode(PaymentDay.FieldNo(Code), Database::"Payment Day");
        PaymentDay.Init();
        PaymentDay."Table Name" := PaymentDay."Table Name"::Vendor;
        PaymentDay.Code := PaymentDayCode;
        PaymentDay."Day of the month" := PaymentDayValue;
        PaymentDay.Insert();
        exit(PaymentDayCode);
    end;

    local procedure CreateCustomerWithPaymentDayAndTerms(var Customer: Record Customer; PaymentDayValue: Integer; PaymentTermsCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Validate("Payment Days Code", CreatePaymentDayCode(PaymentDayValue));
        Customer.Modify(true);
    end;

    local procedure CreateVendorWithPaymentDayAndTerms(var Vendor: Record Vendor; PaymentDayValue: Integer; PaymentTermsCode: Code[10])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Validate("Payment Days Code", CreateVendorPaymentDayCode(PaymentDayValue));
        Vendor.Modify(true);
    end;
}
