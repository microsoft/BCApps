codeunit 134389 "ERM Customer Statistics"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Statistics] [Sales]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        OverDueBalanceErr: Label 'Customer OverDue Balance is not correct';
        WrongBillToCustErr: Label 'Incorrect Bill-to Customer value';
        CustomerNo: Code[20];
        FieldIsNotVisibleOnCustStatFactboxErr: Label 'The field %1 is not visible on page Customer Statistics Factbox.', Comment = '%1 = name of the field';
        IsNotFoundOnThePageErr: Label 'is not found on the page';
        InvoicePaymentDaysAverageErr: Label 'Invoice Payment Days Average was not calculated correct.';
        FieldIsNotHiddenErr: Label 'Field is hidden';
        EntryNoMustMatchErr: Label 'Entry No. must match.';
        PaymentsLCYAndAmountLCYMustMatchErr: Label 'Payemnts (LCY) and Amount (LCY) must match.';
        CustomerCardFactboxTotalErr: Label 'Customer card factbox total is not Correct';
        LotNoErr: Label 'Lot No. should have value.';

    [Test]
    [Scope('OnPrem')]
    procedure OverdueAmountForNewCustomer()
    var
        Customer: Record Customer;
    begin
        // Check that Overdue Amount is zero on Customer Statistics Page for Customer.

        // Setup.
        Initialize();

        // Exercise.
        LibrarySales.CreateCustomer(Customer);

        // Verify: Verify that Overdue Amount is 0 on Customer Statistics Page.
        VerifyOverdueBalanceForCustomer(Customer."No.", 0);

        // Tear Down: Delete earlier created Customer.
        Customer.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerStatisticsAmountOverdue()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        OverdueAmount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 384838] Overdue amount of Customer Statistics is correct after posting sales invoice

        // [GIVEN] Today is January 10
        // [GIVEN] Post sales invoice with "Posting Date" = January 8 and amount = "X"
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        OverdueAmount := CreateSalesInvoice(SalesHeader, Customer."No.", Today() - LibraryRandom.RandInt(10));

        // [WHEN] Post sales invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Overdue amount is "X" in Customer Statistics
        VerifyOverdueBalanceForCustomer(SalesHeader."Sell-to Customer No.", OverdueAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerStatisticsAmountNotOverdue()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
    begin
        // Check that Amount that is not overdue must not show on Customer Statistics Page.

        // Setup: Create Sales Invoice for Customer.
        Initialize();
        FindPaymentTerms(PaymentTerms);
        CreateSalesInvoice(SalesHeader, CreateCustomerWithPaymentTerms(PaymentTerms.Code), WorkDate());

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify that Amount Overdue is not updated as it is not due.
        VerifyOverdueBalanceForCustomer(SalesHeader."Sell-to Customer No.", 0);
    end;

    [Test]
    [HandlerFunctions('NoSeriesPageHandler,SendNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CustomerAmountOverdueWarning()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        OldCreditWarnings: Option;
        InvoiceNo: Code[20];
    begin
        // Check Overdue Amount appears on Credit Limit Warning page.

        // Setup: Update Sales and Receivables Setup.
        Initialize();
        UpdateGenLedgerSetupForDataCheck(false);
        UpdateSalesReceivableSetup(OldCreditWarnings, SalesReceivablesSetup."Credit Warnings"::"Overdue Balance");
        CreateAndPostSalesInvoice(SalesHeader);  // Assign Overdue Amount in global variable.

        CustomerNo := SalesHeader."Sell-to Customer No.";
        // Exercise: Open Sales Invoice Page to invoke Credit Limit Warning Page for overdue amount.
        InvoiceNo := OpenSalesInvoicePage(SalesHeader."Sell-to Customer No.");

        // Verify: Verify Overdue Amount on Credit Limit Warning Page. Verification done in SendNotification.

        // Tear Down: Delete the new Sales Invoice created and rollback Credit Warnings value in Sales & Receivables Setup.
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, InvoiceNo);
        SalesHeader.Delete(true);
        UpdateGenLedgerSetupForDataCheck(true);
        UpdateSalesReceivableSetup(OldCreditWarnings, OldCreditWarnings);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('NoSeriesPageHandler,SendNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure OverdueAmountForCustomerAfterWarning()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        OldCreditWarnings: Option;
        OverdueAmount: Decimal;
        InvoiceNo: Code[20];
    begin
        // Check Overdue Amount on Customer Statistics Page after posting two Sales Invoice on different Dates.

        // Setup: Update Sales and Receivables Setup.
        Initialize();
        UpdateGenLedgerSetupForDataCheck(false);
        UpdateSalesReceivableSetup(OldCreditWarnings, SalesReceivablesSetup."Credit Warnings"::"Overdue Balance");
        OverdueAmount := CreateAndPostSalesInvoice(SalesHeader);
        CustomerNo := SalesHeader."Sell-to Customer No.";

        // Create another Sales Invoice using Page and handle Credit Limit Warning page, take Random Quantity for new Invoice.
        InvoiceNo := OpenSalesInvoicePage(SalesHeader."Sell-to Customer No.");
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, InvoiceNo);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithUnitPrice(), LibraryRandom.RandDec(10, 2));

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify.
        VerifyOverdueBalanceForCustomer(SalesHeader."Sell-to Customer No.", OverdueAmount);

        // Tear Down: Rollback Credit Warnings value in Sales & Receivables Setup.
        UpdateGenLedgerSetupForDataCheck(true);
        UpdateSalesReceivableSetup(OldCreditWarnings, OldCreditWarnings);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FactBoxSalesLineForItem()
    var
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        // Verify program show values in Fact Box Sales Line Details of Sales Order when Type is Item in Sales Order Line.

        // Setup.
        Initialize();
        ItemNo := CreateItemWithUnitPrice();
        CreateSalesOrderAndVerifyFactBox(SalesLine.Type::Item, ItemNo, ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FactBoxSalesLineResource()
    var
        Resource: Record Resource;
        SalesLine: Record "Sales Line";
        LibraryResource: Codeunit "Library - Resource";
    begin
        // Verify program do not show any values in Fact Box Sales Line Details of Sales Order when Type is Resource in Sales Order Line.

        // Setup.
        Initialize();
        LibraryResource.FindResource(Resource);
        CreateSalesOrderAndVerifyFactBox(SalesLine.Type::Resource, Resource."No.", '');  // Using '' to verify Item No field on Fact Box.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FactBoxSalesLineGLAccount()
    var
        GLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
    begin
        // Verify program do not show any values in Fact Box Sales Line Details of Sales Order when Type is G/L Account in Sales Order Line.

        // Setup.
        Initialize();
        LibraryERM.FindGLAccount(GLAccount);
        CreateSalesOrderAndVerifyFactBox(SalesLine.Type::"G/L Account", GLAccount."No.", '');  // Using '' to verify Item No field on Fact Box.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFilterOnCustStatsByCurrLinesFromCustList()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        CustStatsByCurrLines: TestPage "Cust. Stats. by Curr. Lines";
        BalanceLCY: Decimal;
        BalanceFCY: Decimal;
    begin
        // Test that while opening the page CustStatsByCurrLines from the customer list, proper filter can be applied on that page.
        // Setup: Create Customer and Sales Document with or without currency and post it.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        BalanceLCY := CreateAndPostSalesDocument(Customer."No.", '');
        FindCurrency(Currency);
        BalanceFCY := CreateAndPostSalesDocument(Customer."No.", Currency.Code);

        // Exercise: Invoke page CustStatsByCurrLines from customer list page.
        InvokeCustStatsByCurrLinesFromCustomerList(CustStatsByCurrLines, Customer."No.");

        // Verify: Verfiy that proper filter can be applied on the page CustStatsByCurrLines and also verified the field Customer Balance.
        VerifyFiltersOnCustStatsByCurrLinesPage(CustStatsByCurrLines, '', BalanceLCY);
        VerifyFiltersOnCustStatsByCurrLinesPage(CustStatsByCurrLines, Currency.Code, BalanceFCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFilterOnCustStatsByCurrLinesFromCustCard()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        CustStatsByCurrLines: TestPage "Cust. Stats. by Curr. Lines";
        BalanceLCY: Decimal;
        BalanceFCY: Decimal;
    begin
        // Test that while opening the page CustStatsByCurrLines from the customer card, proper filter can be applied on that page.

        // Setup: Create Customer and Sales Document with or without currency and post it.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        BalanceLCY := CreateAndPostSalesDocument(Customer."No.", '');
        FindCurrency(Currency);
        BalanceFCY := CreateAndPostSalesDocument(Customer."No.", Currency.Code);

        // Exercise: Invoke page CustStatsByCurrLines from customer card page.
        InvokeCustStatsByCurrLinesFromCustomerCard(CustStatsByCurrLines, Customer."No.");

        // Verify: Verfiy that proper filter can be applied on the page CustStatsByCurrLines and also verified the field Customer Balance.
        VerifyFiltersOnCustStatsByCurrLinesPage(CustStatsByCurrLines, '', BalanceLCY);
        VerifyFiltersOnCustStatsByCurrLinesPage(CustStatsByCurrLines, Currency.Code, BalanceFCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckOverDueBalanceForCustomer()
    var
        Customer: Record Customer;
        InvoiceAmountLCY: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 384838] Overdue balance does not depend on the payment

        // [GIVEN] Today is January 10
        // [GIVEN] Post sales invoice with "Posting Date" = January 8 and Amount = "X"
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        InvoiceAmountLCY := CreateAndPostSalesDocument(Customer."No.", '');
        // [WHEN] Post partial payment to the invoice with Amount = "Y"
        PostPartialPaymentForCustomer(Customer."No.", InvoiceAmountLCY);

        // [THEN] CalcOverdueBalance function of the Customer table returns "X"
        Assert.AreEqual(Round(InvoiceAmountLCY), Customer.CalcOverdueBalance(), OverDueBalanceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTCheckEmptyBilltoCustomer()
    var
        Customer: Record Customer;
    begin
        // [SCENARIO 121705] Customer.GetBillToCustomerNo returns "No." if "Bill-to Customer No." is blank
        Customer."No." := 'A';
        Customer."Bill-to Customer No." := '';

        Assert.AreEqual(Customer."No.", Customer.GetBillToCustomerNo(), WrongBillToCustErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTCheckNotEmptyBilltoCustomer()
    var
        Customer: Record Customer;
    begin
        // [SCENARIO 121705] Customer.GetBillToCustomerNo returns "Bill-to Customer No." if "Bill-to Customer No." is not blank
        Customer."No." := 'A';
        Customer."Bill-to Customer No." := 'B';

        Assert.AreEqual(Customer."Bill-to Customer No.", Customer.GetBillToCustomerNo(), WrongBillToCustErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerSalesHistBilltoFactBox()
    var
        Customer: Record Customer;
        SalesHistBilltoFactBox: TestPage "Sales Hist. Bill-to FactBox";
    begin
        // [SCENARIO 121705] Sales Hist. Bill-to FactBox shows data for Bill-to Customer No.
        Initialize();

        // [GIVEN] Setup new Customer with Bill-to Customer No.
        CreateCustomerWithBilltoCust(Customer);
        SalesHistBilltoFactBox.Trap();

        // [WHEN] Open Sales Hist. Bill-to FactBox
        PAGE.Run(PAGE::"Sales Hist. Bill-to FactBox", Customer);

        // [THEN] FactBox is opened for Customer No.
        SalesHistBilltoFactBox."No.".AssertEquals(Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerServiceHistBilltoFactBox()
    var
        Customer: Record Customer;
        ServiceHistBilltoFactBox: TestPage "Service Hist. Bill-to FactBox";
    begin
        // [SCENARIO 121705] Service Hist. Bill-to FactBox is opened for Bill-to Customer No.
        Initialize();

        // [GIVEN] Setup new Customer with Bill-to Customer No.
        CreateCustomerWithBilltoCust(Customer);

        ServiceHistBilltoFactBox.Trap();

        // [WHEN] Open Service Hist. Bill-to FactBox
        PAGE.Run(PAGE::"Service Hist. Bill-to FactBox", Customer);

        // [THEN] FactBox is opened for Bill-to Customer No.
        ServiceHistBilltoFactBox."No.".AssertEquals(Customer."Bill-to Customer No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerServiceHistSelltoFactBox()
    var
        Customer: Record Customer;
        ServiceHistSelltoFactBox: TestPage "Service Hist. Sell-to FactBox";
    begin
        // [SCENARIO 121705] Service Hist. Sell-to FactBox is opened for Sell-to Customer No.
        Initialize();

        // [GIVEN] Setup new Customer
        LibrarySales.CreateCustomer(Customer);

        ServiceHistSelltoFactBox.Trap();

        // [WHEN] Open Service Hist. Sell-to FactBox
        Customer.SetRecFilter();
        PAGE.Run(PAGE::"Service Hist. Sell-to FactBox", Customer);

        // [THEN] FactBox is opened for Sell-to Customer No.
        ServiceHistSelltoFactBox."No.".AssertEquals(Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOnBalanceFromList()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerList: TestPage "Customer List";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        Initialize();

        // [GIVEN] Setup new Customer with a customer ledger entry
        LibrarySales.CreateCustomer(Customer);
        CreateBasicCustLedgerEntry(CustLedgerEntry, Customer."No.");

        // [WHEN] The user drills down on Balance (LCY) field from Customer List
        CustomerList.OpenView();
        CustomerList.GotoRecord(Customer);
        CustomerLedgerEntries.Trap();
        CustomerList."Balance (LCY)".DrillDown();

        // [THEN] Customer Ledger Entries window opens, showing the ledger entries for the selected customer
        CustomerLedgerEntries.First();
        Assert.AreEqual(CustLedgerEntry."Entry No.", CustomerLedgerEntries."Entry No.".AsInteger(), '');
        Assert.IsFalse(CustomerLedgerEntries.Next(), '');
        CustomerLedgerEntries.Close();
        CustomerList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOnBalanceFromCard()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerCard: TestPage "Customer Card";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        Initialize();

        // [GIVEN] Setup new Customer with a customer ledger entry
        LibrarySales.CreateCustomer(Customer);
        CreateBasicCustLedgerEntry(CustLedgerEntry, Customer."No.");

        // [WHEN] The user drills down on Balance (LCY) field from Customer Card
        CustomerCard.OpenView();
        CustomerCard.GotoRecord(Customer);
        CustomerLedgerEntries.Trap();
        CustomerCard."Balance (LCY)".DrillDown();

        // [THEN] Customer Ledger Entries window opens, showing the ledger entries for the selected customer
        CustomerLedgerEntries.First();
        Assert.AreEqual(CustLedgerEntry."Entry No.", CustomerLedgerEntries."Entry No.".AsInteger(), '');
        Assert.IsFalse(CustomerLedgerEntries.Next(), '');
        CustomerLedgerEntries.Close();
        CustomerCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOnBalanceDueFromList()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerList: TestPage "Customer List";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // [SCENARIO 258948] When Drill Down on Balance Due (LCY) is called from Customer List, Due Date filter on opened Customer Ledger Entries Page = Date Filter.
        Initialize();

        // [GIVEN] Setup new Customer with a customer ledger entry.
        LibrarySales.CreateCustomer(Customer);
        CreateBasicCustLedgerEntry(CustLedgerEntry, Customer."No.");
        CustLedgerEntry.Validate("Due Date", LibraryRandom.RandDate(100));
        CustLedgerEntry.Modify(true);

        // [WHEN] The user drills down on Balance Due (LCY) field from Customer List
        CustomerList.OpenView();
        CustomerLedgerEntries.Trap();
        CustomerList.FILTER.SetFilter("Date Filter", Format(CustLedgerEntry."Due Date"));
        CustomerList.GotoRecord(Customer);
        CustomerList."Balance Due (LCY)".DrillDown();

        // [THEN] Customer Ledger Entries window opens, Due Date filter = Date Filter from Customer List.
        Assert.AreEqual(CustomerList.FILTER.GetFilter("Date Filter"), CustomerLedgerEntries.FILTER.GetFilter("Due Date"), '');

        // [THEN] Customer Ledger Entries window opens, showing the ledger entries for the selected customer
        CustomerLedgerEntries.First();
        Assert.AreEqual(CustLedgerEntry."Entry No.", CustomerLedgerEntries."Entry No.".AsInteger(), '');
        Assert.IsFalse(CustomerLedgerEntries.Next(), '');
        CustomerLedgerEntries.Close();
        CustomerList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOnBalanceDueFromCard()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerCard: TestPage "Customer Card";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // [SCENARIO 258948] When Drill Down on Balance Due (LCY) is called from Customer Card, Due Date filter on opened Customer Ledger Entries Page = Date Filter.
        Initialize();

        // [GIVEN] Setup new Customer with a customer ledger entry
        LibrarySales.CreateCustomer(Customer);
        CreateBasicCustLedgerEntry(CustLedgerEntry, Customer."No.");
        CustLedgerEntry.Validate("Due Date", LibraryRandom.RandDate(100));
        CustLedgerEntry.Modify(true);

        // [WHEN] The user drills down on Balance Due (LCY) field from Customer Card
        CustomerCard.OpenView();
        CustomerLedgerEntries.Trap();
        CustomerCard.FILTER.SetFilter("Date Filter", Format(CustLedgerEntry."Due Date"));
        CustomerCard.GotoRecord(Customer);
        CustomerCard."Balance Due (LCY)".DrillDown();

        // [THEN] Customer Ledger Entries window opens, Due Date filter = Date Filter from Customer List.
        Assert.AreEqual(CustomerCard.FILTER.GetFilter("Date Filter"), CustomerLedgerEntries.FILTER.GetFilter("Due Date"), '');

        // [THEN] Customer Ledger Entries window opens, showing the ledger entries for the selected customer
        CustomerLedgerEntries.First();
        Assert.AreEqual(CustLedgerEntry."Entry No.", CustomerLedgerEntries."Entry No.".AsInteger(), '');
        Assert.IsFalse(CustomerLedgerEntries.Next(), '');
        CustomerLedgerEntries.Close();
        CustomerCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ServiceFieldsAreNotVisibleOnCustomerStatisticsFactboxUnderSaaSFoundation()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [FEATURE] [UI] [SaaS]
        // [SCENARIO 210531] Service statistics are not visible on "Customer Statistics Factbox" in Financials

        Initialize();

        // [GIVEN] Switch to Software as Service client and enable Foundation Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryApplicationArea.EnableFoundationSetup();

        // [WHEN] Open "Sales Order List" page
        SalesOrderList.OpenView();

        // [THEN] All fields related to Service Management are not visible
        asserterror SalesOrderList.Control1902018507."Outstanding Serv. Orders (LCY)".Activate();
        Assert.ExpectedError(IsNotFoundOnThePageErr);
        asserterror SalesOrderList.Control1902018507."Serv Shipped Not Invoiced(LCY)".Activate();
        Assert.ExpectedError(IsNotFoundOnThePageErr);
        asserterror SalesOrderList.Control1902018507."Outstanding Serv.Invoices(LCY)".Activate();
        Assert.ExpectedError(IsNotFoundOnThePageErr);

        // Tear down
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ServiceFieldsAreVisibleOnCustomerStatisticsFactboxUnderSaaSFull()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [FEATURE] [UI] [SaaS]
        // [SCENARIO 210531] Service statistics are not visible on "Customer Statistics Factbox" in Full

        Initialize();

        // [GIVEN] Switch to Software as Service client and enable Full Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [WHEN] Open "Sales Order List" page
        SalesOrderList.OpenView();

        // [THEN] All fields related to Service Management are visible
        Assert.IsTrue(
          SalesOrderList.Control1902018507."Outstanding Serv. Orders (LCY)".Visible(),
          StrSubstNo(FieldIsNotVisibleOnCustStatFactboxErr,
            SalesOrderList.Control1902018507."Outstanding Serv. Orders (LCY)".Caption));
        Assert.IsTrue(
          SalesOrderList.Control1902018507."Serv Shipped Not Invoiced(LCY)".Visible(),
          StrSubstNo(FieldIsNotVisibleOnCustStatFactboxErr,
            SalesOrderList.Control1902018507."Serv Shipped Not Invoiced(LCY)".Caption));
        Assert.IsTrue(
          SalesOrderList.Control1902018507."Outstanding Serv.Invoices(LCY)".Visible(),
          StrSubstNo(FieldIsNotVisibleOnCustStatFactboxErr,
            SalesOrderList.Control1902018507."Outstanding Serv.Invoices(LCY)".Caption));

        // Tear down
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerStatNotEditable()
    var
        CustomerStatistics: TestPage "Customer Statistics";
        CustomerList: TestPage "Customer List";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223267] Page Customer Statistic must be not editable
        Initialize();

        // [GIVEN] Customer
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [WHEN] Open "Customer Statistics"
        CustomerList.OpenView();
        CustomerList.FILTER.SetFilter("No.", CustomerNo);
        CustomerStatistics.Trap();
        CustomerList.Statistics.Invoke();

        // [THEN] Page "Customer Statistics" is not editable
        Assert.IsFalse(CustomerStatistics.Editable(), 'Page "Customer Statistics" must be not editable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoicePaymentDaysAverageCalculationForCustomerWhenEmptyDueDateExist()
    var
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        InvoicePaymentDaysAverage: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 254684] Invoice Payment Days Average calculation for Customer returns zero when only Invoice Customer Ledger Entries with blank Due Date exist with Payment.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Closed Customer Ledger Entry "CLE" with Type = Invoice and blank Due Date.
        CreateClosedInvoiceCustLedgerEntryWithEmptyDueDate(CustLedgEntry, Customer."No.");

        // [GIVEN] Detailed Customer Ledger Entry for "CLE" with Type = Payment.
        CreatePaymentDetailedCustLedgerEntryForCustLedgerEntry(DetailedCustLedgEntry, CustLedgEntry."Entry No.");

        // [WHEN] Calculate Invoice Payment Days Average.
        InvoicePaymentDaysAverage := AgedAccReceivable.InvoicePaymentDaysAverage(Customer."No.");

        // [THEN] Invoice Payment Days Average = 0.
        Assert.AreEqual(0, InvoicePaymentDaysAverage, InvoicePaymentDaysAverageErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FactboxStatFieldsNotAffectedByDateFilterShowTheirValues()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
        CustomerList: TestPage "Customer List";
        SalesOrderOutstandingAmtLCY: Decimal;
        SalesInvOutstandingAmtLCY: Decimal;
        SalesShippedNotInvoicedLCY: Decimal;
        ServOrderOutstandingAmtLCY: Decimal;
        ServInvOutstandingAmtLCY: Decimal;
        ServShippedNotInvoicedLCY: Decimal;
    begin
        // [SCENARIO 253431] The fields on page "Customer Statistics Factbox" which are not affected by "Date Filter" must show their values

        Initialize();

        // [GIVEN] Sales Order with "Outstanding Amount (LCY)" = 100, "Shipped Not Invoiced (LCY)" = 40
        LibrarySales.CreateCustomer(Customer);
        Commit();  // so background session can see the new customer

        SalesOrderOutstandingAmtLCY := LibraryRandom.RandDec(100, 2);
        SalesShippedNotInvoicedLCY := LibraryRandom.RandDec(100, 2);
        MockSalesLine(Customer."No.", SalesLine."Document Type"::Order, SalesOrderOutstandingAmtLCY, SalesShippedNotInvoicedLCY, 0);

        // [GIVEN] Sales Invoice with "Outstanding Amount (LCY)" = 60
        SalesInvOutstandingAmtLCY := LibraryRandom.RandDec(100, 2);
        MockSalesLine(Customer."No.", SalesLine."Document Type"::Invoice, SalesInvOutstandingAmtLCY, 0, 0);

        // [GIVEN] Service Order with "Outstanding Amount (LCY)" = 100, "Shipped Not Invoiced (LCY)" = 40
        ServOrderOutstandingAmtLCY := LibraryRandom.RandDec(100, 2);
        ServShippedNotInvoicedLCY := LibraryRandom.RandDec(100, 2);
        MockServLine(Customer."No.", ServiceLine."Document Type"::Order, ServOrderOutstandingAmtLCY, ServShippedNotInvoicedLCY);

        // [GIVEN] Service Invoice with "Outstanding Amount (LCY)" = 60
        ServInvOutstandingAmtLCY := LibraryRandom.RandDec(100, 2);
        MockServLine(Customer."No.", ServiceLine."Document Type"::Invoice, ServInvOutstandingAmtLCY, 0);

        // [WHEN] Open "Customer Statistics Factbox"
        CustomerList.OpenView();
        CustomerList.GotoRecord(Customer);

        // [THEN] Page "Customer Statistics Factbox" has "Outstanding Orders (LCY)" = 100, "Shipped Not Invoiced (LCY)" = 40, "Outstanding Invoices (LCY)" = 60,
        CustomerList.CustomerStatisticsFactBox."Outstanding Orders (LCY)".AssertEquals(SalesOrderOutstandingAmtLCY);
        Assert.IsFalse(CustomerList.CustomerStatisticsFactBox."Outstanding Orders (LCY)".HideValue(), FieldIsNotHiddenErr);
        CustomerList.CustomerStatisticsFactBox."Shipped Not Invoiced (LCY)".AssertEquals(SalesShippedNotInvoicedLCY);
        Assert.IsFalse(CustomerList.CustomerStatisticsFactBox."Shipped Not Invoiced (LCY)".HideValue(), FieldIsNotHiddenErr);
        CustomerList.CustomerStatisticsFactBox."Outstanding Invoices (LCY)".AssertEquals(SalesInvOutstandingAmtLCY);
        Assert.IsFalse(CustomerList.CustomerStatisticsFactBox."Outstanding Invoices (LCY)".HideValue(), FieldIsNotHiddenErr);
        CustomerList.CustomerStatisticsFactBox."Outstanding Serv. Orders (LCY)".AssertEquals(ServOrderOutstandingAmtLCY);
        Assert.IsFalse(CustomerList.CustomerStatisticsFactBox."Outstanding Serv. Orders (LCY)".HideValue(), FieldIsNotHiddenErr);
        CustomerList.CustomerStatisticsFactBox."Serv Shipped Not Invoiced(LCY)".AssertEquals(ServShippedNotInvoicedLCY);
        Assert.IsFalse(CustomerList.CustomerStatisticsFactBox."Serv Shipped Not Invoiced(LCY)".HideValue(), FieldIsNotHiddenErr);
        CustomerList.CustomerStatisticsFactBox."Outstanding Serv.Invoices(LCY)".AssertEquals(ServInvOutstandingAmtLCY);
        Assert.IsFalse(CustomerList.CustomerStatisticsFactBox."Outstanding Serv.Invoices(LCY)".HideValue(), FieldIsNotHiddenErr);
        CustomerList.CustomerStatisticsFactBox."Total (LCY)".AssertEquals(
          SalesOrderOutstandingAmtLCY + SalesShippedNotInvoicedLCY + SalesInvOutstandingAmtLCY +
          ServOrderOutstandingAmtLCY + ServShippedNotInvoicedLCY + ServInvOutstandingAmtLCY);
        Assert.IsFalse(CustomerList.CustomerStatisticsFactBox."Total (LCY)".HideValue(), FieldIsNotHiddenErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CutomerBalanceDueIsCalculatedConsideringDueDate()
    var
        Customer: Record Customer;
        CustLedgerEntry: array[2] of Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: array[2] of Record "Detailed Cust. Ledg. Entry";
    begin
        // [SCENARIO 258948] Cutomer "Balance Due" is calculated based on Detailed Customer Ledger Entries with Initial Entries Due Date < Date Filter.
        Initialize();

        // [GIVEN] Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Detailed Customer Ledger Entry "DCLE1" with Due Date > WORKDATE and Amount = 100.
        CreateCustLedgerEntryWithDueDate(CustLedgerEntry[1], Customer."No.", LibraryRandom.RandDate(100));
        MockDetailedCustLedgerEntryWithDueDate(DetailedCustLedgEntry[1], CustLedgerEntry[1]);

        // [GIVEN] Detailed Customer Ledger Entry "DCLE2" with Due Date < WORKDATE and Amount = 200.
        CreateCustLedgerEntryWithDueDate(CustLedgerEntry[2], Customer."No.", LibraryRandom.RandDate(-100));
        MockDetailedCustLedgerEntryWithDueDate(DetailedCustLedgEntry[2], CustLedgerEntry[2]);

        // [WHEN] Set "Date Filter" = WORKDATE.
        Customer.SetFilter("Date Filter", Format(WorkDate()));

        // [THEN] "Balance Due" = 200.
        Customer.CalcFields("Balance Due");
        Customer.TestField("Balance Due", DetailedCustLedgEntry[2].Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CutomerBalanceDueSumsDetailedLedgerEntriesAnyPostingDate()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: array[2] of Record "Detailed Cust. Ledg. Entry";
    begin
        // [SCENARIO 258948] Cutomer "Balance Due" is calculated based on Detailed Customer Ledger Entries with any posting date.
        Initialize();

        // [GIVEN] Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Detailed Customer Ledger Entry "DCLE1" with Posting Date > WORKDATE and Amount = 100.
        CreateBasicCustLedgerEntry(CustLedgerEntry, Customer."No.");
        MockDetailedCustLedgerEntryWithPostingDate(DetailedCustLedgEntry[1], CustLedgerEntry, LibraryRandom.RandDate(100));

        // [GIVEN] Detailed Customer Ledger Entry "DCLE2" with Posting Date < WORKDATE and Amount = 200.
        MockDetailedCustLedgerEntryWithPostingDate(DetailedCustLedgEntry[2], CustLedgerEntry, LibraryRandom.RandDate(-100));

        // [WHEN] Set "Date Filter" = WORKDATE.
        Customer.SetFilter("Date Filter", Format(WorkDate()));

        // [THEN] "Balance Due" = 300.
        Customer.CalcFields("Balance Due");
        Customer.TestField("Balance Due", DetailedCustLedgEntry[1].Amount + DetailedCustLedgEntry[2].Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTotalAmountReturnRcvdNotInv()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CreditLimitLCY: Integer;
        ReturnAmountLCY: Decimal;
    begin
        // [SCENARIO 280348] Customer "Total Amount"/"Available Credit" calculation includes Return Received Not Invoiced amount
        Initialize();

        // [GIVEN] Customer with Credit Limit = 100
        CreditLimitLCY := LibraryRandom.RandInt(100);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Credit Limit (LCY)", CreditLimitLCY);
        Customer.Modify(true);

        // [GIVEN] Sales Line for Customer with "Document Type" = "Return Order" and "Return Rcd. Not Invd. (LCY)" = 150
        ReturnAmountLCY := LibraryRandom.RandDecInRange(CreditLimitLCY, 2 * CreditLimitLCY, 2);
        MockSalesLine(Customer."No.", SalesHeader."Document Type"::"Return Order", 0, 0, ReturnAmountLCY);

        // [WHEN] Calculate Customer's Total Amount and Available Credit
        // [THEN] Customer's Total Amount = -150
        // [THEN] Customer's Available Credit = 250
        Assert.AreEqual(-ReturnAmountLCY, Customer.GetTotalAmountLCY(), '');
        Assert.AreEqual(CreditLimitLCY + ReturnAmountLCY, Customer.CalcAvailableCredit(), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatisticsFactboxLastPaymentDate()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        PaymentDate: array[3] of Date;
    begin
        // [SCENARIO 264555] Customer statistics factbox shows last payment date
        Initialize();

        // [GIVEN] Create new customer "CUST"
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Post payment "PAYM1" on 01.01
        PaymentDate[1] := CalcDate('<-CM>', WorkDate());
        PostPaymentForCustomer(Customer."No.", PaymentDate[1]);
        // [GIVEN] Post payment "PAYM2" on 15.01
        PaymentDate[2] := CalcDate('<-CM+14D>', WorkDate());
        PostPaymentForCustomer(Customer."No.", PaymentDate[2]);
        // [GIVEN] Post payment "PAYM3" on 31.01
        PaymentDate[3] := CalcDate('<CM>', WorkDate());
        PostPaymentForCustomer(Customer."No.", PaymentDate[3]);
        // [GIVEN] Reverse payment "PAYM3"
        ReversePayment(Customer."No.", PaymentDate[3]);

        // [WHEN] Customer card page is being opened for "CUST"
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");

        // [THEN] Customer statistics factbox shows Last Payment Received Date = 15.01
        CustomerCard.CustomerStatisticsFactBox.LastPaymentReceiptDate.AssertEquals(PaymentDate[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatisticsFactboxDrillDownLastPaymentDate()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        PaymentDate: array[3] of Date;
    begin
        // [SCENARIO 264555] DrillDown of Last Payment Received Date of customer statistics factbox opens customer payments with cursor on last payment
        Initialize();

        // [GIVEN] Create new customer "CUST"
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Post payment "PAYM1" on 01.01
        PaymentDate[1] := CalcDate('<-CM>', WorkDate());
        PostPaymentForCustomer(Customer."No.", PaymentDate[1]);
        // [GIVEN] Post payment "PAYM2" on 15.01
        PaymentDate[2] := CalcDate('<-CM+14D>', WorkDate());
        PostPaymentForCustomer(Customer."No.", PaymentDate[2]);
        // [GIVEN] Post payment "PAYM3" on 31.01
        PaymentDate[3] := CalcDate('<CM>', WorkDate());
        PostPaymentForCustomer(Customer."No.", PaymentDate[3]);
        // [GIVEN] Reverse payment "PAYM3"
        ReversePayment(Customer."No.", PaymentDate[3]);

        // [GIVEN] Open customer card page for "CUST"
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");

        // [WHEN] Last Payment Received Date drill down is being invoked
        CustomerLedgerEntries.Trap();
        CustomerCard.CustomerStatisticsFactBox.LastPaymentReceiptDate.DrillDown();

        // [THEN] Opened list of payments has cursor on payment "PAYM2"
        CustomerLedgerEntries."Posting Date".AssertEquals(PaymentDate[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintainSIFTIndexForCustomerPaymentLCYEnagled()
    var
        "Key": Record "Key";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 292660] MaintainSIFTIndex should be enabled for Detailed Cust. Ledg. Entry key responsible for calculation Customer.Payments (LCY)
        Key.SetRange(TableNo, DATABASE::"Detailed Cust. Ledg. Entry");
        Key.SetFilter(
          Key,
          'Customer No.,Currency Code,Initial Entry Global Dim. 1,Initial Entry Global Dim. 2,Initial Entry Due Date,*');
        Key.SetFilter(ObsoleteState, 'No');
        Key.FindFirst();
        Key.TestField(MaintainSIFTIndex, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerStatisticsServiceItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerList: TestPage "Customer List";
        CustomerStatistics: TestPage "Customer Statistics";
    begin
        // [FEATURE] [Service Item]
        // [SCENARIO 294617] Customer statistics shows proper value of Original Profit (LCY) for posted sales invoice with item of type Service
        Initialize();

        // [GIVEN] Item "I" with "Type" = "Service", Unit Cost = 60, Unit Price = 100
        LibraryInventory.CreateServiceTypeItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Unit Price", Item."Unit Cost" + LibraryRandom.RandDec(100, 2));
        Item.Modify();

        // [GIVEN] Create customer "CUST"
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Create and post sales order for customer "CUST" with item "I", Quantity = 1
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Open statistics for customer "CUST" is being opened
        CustomerList.OpenView();
        CustomerList.FILTER.SetFilter("No.", CustomerNo);
        CustomerStatistics.Trap();
        CustomerList.Statistics.Invoke();

        // [THEN] Original Cost (LCY) = 100
        // [THEN] Original Profit (LCY) = 40
        // [THEN] Adjusted Cost (LCY) = 100
        // [THEN] Adjusted Profit (LCY) = 40
        // [THEN] Cost Adjmt. Amounts (LCY) = 0
        VerifyCustomerStatisticsServiceItem(
          CustomerStatistics,
          SalesLine.Quantity * Item."Unit Cost",
          SalesLine.Quantity * (Item."Unit Price" - Item."Unit Cost"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOnPaymentsThisYearFromCustomerCard()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustomerCard: TestPage "Customer Card";
        DetailedCustLedgEntries: TestPage "Detailed Cust. Ledg. Entries";
    begin
        // [SCENARIO 480403] Payments this Year field under Statistics tab on the Customer Card is using the wrong Date Filter.
        Initialize();

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);
        Commit();  // so background session can see the new customer

        // [GIVEN] Create a Customer Ledger Entry.
        CreateBasicCustLedgerEntry(CustLedgerEntry, Customer."No.");

        // [GIVEN] Create a Detailed Customer Ledger Entry.
        CreatePaymentsThisYearDetailedCustLedgerEntry(DetailedCustLedgEntry, CustLedgerEntry);

        // [GIVEN] Open Customer Card page.
        CustomerCard.OpenView();
        CustomerCard.GotoRecord(Customer);

        // [GIVEN] Drill Down Payments This Year field & Find Detailed Customer Ledger Entry.
        DetailedCustLedgEntries.Trap();
        CustomerCard."Payments (LCY)".Drilldown();
        DetailedCustLedgEntries.First();

        // [VERIFY] Verify Detailed Customer Ledger Entry found is of Current Fiscal year.
        Assert.AreEqual(
            DetailedCustLedgEntry."Entry No.",
            DetailedCustLedgEntries."Entry No.".AsInteger(),
            EntryNoMustMatchErr);

        // [VERIFY] Verify Payments This Year value matches with Detailed Customer Ledger Entry Amount (LCY) value & Close the pages.
        Assert.AreEqual(
            CustomerCard."Payments (LCY)".AsDecimal(),
            -DetailedCustLedgEntries."Amount (LCY)".AsDecimal(),
            PaymentsLCYAndAmountLCYMustMatchErr);
        DetailedCustLedgEntries.Close();
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesPageHandler')]
    procedure CheckCustomerCardStatisticsTotalOnFactBox()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 574648] Check Customer Card Statistics Total On FactBox When Sales Order Only Shiped and Sales Invoice 
        // Created By GetShipmentLines without Posting.
        Initialize();

        // [GIVEN] Created New Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Created New Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Created Item Inventory By Posting Item Journal With Qty 10.
        CreateItemInventory(Item, 10);

        // [WHEN] Created New Sales Order With Qty 10.
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.", WorkDate());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 0));
        SalesLine.Modify(true);

        // [WHEN] "SO" Post invoked with "Shipped" selected.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Create New Sales Invoice And Get Shipment Line Through GetShipmentLines.
        CreateAndReleaseSalesInvoiceUsingGetShipmentLines(SalesHeader."Sell-to Customer No.");

        // [THEN] Check Customer Card Statistics Total is Equal To SalesLine."Amount Including VAT" and Not Multiply.
        Assert.AreEqual(SalesLine."Amount Including VAT", Customer.GetTotalAmountLCY(), CustomerCardFactboxTotalErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,GetShipmentLinesPageHandler')]
    procedure QuantityReducedInSalesInvoiceAfterGenShipmentLineReservesTrackingInformation()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Integer;
    begin
        // [SCENARIO 576049] When the quantity in a Sales Invoices was changed after using 'Get Shipment lines' and an item with item tracking lines and reserve always has the tracking information.
        Initialize();

        // [GIVEN] Created New Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Item Tracking Code and Validate Trackings.
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", false);
        ItemTrackingCode.Validate("SN Specific Tracking", false);
        ItemTrackingCode.Validate("SN Sales Inbound Tracking", true);
        ItemTrackingCode.Validate("SN Sales Outbound Tracking", true);
        ItemTrackingCode.Validate("Lot Sales Inbound Tracking", true);
        ItemTrackingCode.Validate("Lot Sales Outbound Tracking", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Created New Item and Validate Item Tracking Code, Serial Nos, Reserve.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Lot Nos.", LibraryERM.CreateNoSeriesCode());
        Item.Validate("Serial Nos.", LibraryERM.CreateNoSeriesCode());
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);

        // [GIVEN] Store quantity in Variable.
        Quantity := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Created Item Inventory By Posting Item Journal.
        CreateItemInventory(Item, Quantity);

        // [GIVEN] Create new Sales Header.
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.", WorkDate());

        // [GIVEN] Create Sales line and Validate Unit Price.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 0));
        SalesLine.Modify(true);

        // [GIVEN] Enqueue Quantity and assign Tracking Lines
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(Quantity);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Post Sales Order invoked with "Shipped" selected.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Create New Sales Invoice And Get Shipment Line Through GetShipmentLines.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        LibrarySales.GetShipmentLines(SalesLine);

        // [GIVEN] Find the Sales Line.
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();

        // [WHEN] Validate Quantity with random integer less than previous quanitity.
        SalesLine.Validate(Quantity, LibraryRandom.RandInt(5));
        SalesLine.Modify(true);

        // [THEN] Tracking Lines is not deleted.
        LibraryVariableStorage.Enqueue(false);
        SalesLine.OpenItemTrackingLines();
    end;

    [Test]
    procedure CheckCustomerCardStatisticsTotalLCYValueWhenThereIsMoreThanOneShipment()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerList: TestPage "Customer List";
        CustomerStatistics: TestPage "Customer Statistics";
        Index: Integer;
    begin
        // [SCENARIO 597753] Total (LCY) field on Customer Statistics is incorrectly calculated in case of more than one Shipment per Sales Order.
        Initialize();

        // [GIVEN] Created New Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Created New Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Created Item Inventory By Posting Item Journal With Qty 3.
        CreateItemInventory(Item, 3);

        // [WHEN] Created New Sales Order With Qty 3
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.", WorkDate());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 3);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 0));
        SalesLine.Modify(true);

        // [WHEN] "SO" Post invoked with "Shipped" selected 3 times for each qty 1.        
        for Index := 1 to 3 do begin
            SalesLine.Validate("Qty. to Ship", 1);
            SalesLine.Modify(true);
            LibrarySales.PostSalesDocument(SalesHeader, true, false);

            // [GIVEN] Find the Sales Line again after each Post.
            SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        end;

        // [GIVEN] When All 3 Shipments are done, Open "Customer Statistics"
        CustomerList.OpenView();
        CustomerList.FILTER.SetFilter("No.", Customer."No.");
        CustomerStatistics.Trap();
        CustomerList.Statistics.Invoke();

        // [THEN] Check Customer Card Statistics "Shipped Not Invoiced (LCY)" is Equal To SalesLine."Amount Including VAT" and Accordingly updated value of Total.
        Assert.AreEqual(SalesLine."Amount Including VAT", CustomerStatistics."Shipped Not Invoiced (LCY)".AsDecimal(), CustomerCardFactboxTotalErr);
        Assert.AreEqual(CustomerStatistics.GetTotalAmountLCY.AsDecimal(), Customer.GetTotalAmountLCY(), CustomerCardFactboxTotalErr);
    end;

    local procedure Initialize()
    var
        Currency: Record Currency;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Customer Statistics");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Customer Statistics");

        UpdateGenLedgerSetupForDataCheck(true);
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Link Doc. Date To Posting Date", true);
        PurchasesPayablesSetup.Modify();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify();

        FindCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, CalcDate('<-1Y>', WorkDate()), LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
        LibraryERM.CreateExchangeRate(Currency.Code, CalcDate('<-2Y>', WorkDate()), LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
        LibraryERM.CreateExchangeRate(Currency.Code, CalcDate('<-3Y>', WorkDate()), LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        UpdatePostedNoSeriesInSalesSetup(); // required for RU
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Customer Statistics");
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header") LineAmount: Decimal
    var
        PaymentTerms: Record "Payment Terms";
        PostingDate: Date;
    begin
        // Calculate Posting Date according to Customer's Payment Terms Due Date, create and post Sales Invoice on the calculated date.
        FindPaymentTerms(PaymentTerms);
        PostingDate :=
          CalcDate(
            '<-' + Format(LibraryRandom.RandInt(10)) + 'D>',
            CalcDate('<-' + Format(PaymentTerms."Due Date Calculation") + '>', Today()));
        LineAmount := CreateSalesInvoice(SalesHeader, CreateCustomerWithPaymentTerms(PaymentTerms.Code), PostingDate);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateSalesOrderAndVerifyFactBox(Type: Enum "Sales Line Type"; No: Code[20]; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInfoPaneMgt: Codeunit "Sales Info-Pane Management";
        SalesOrder: TestPage "Sales Order";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(), WorkDate());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Using Random for Quantity.

        // Exercise.
        OpenSalesOrderAndFindLine(SalesOrder, SalesHeader."No.", No, Type);

        // Verify: Verify Item No, Availability, Substitutions, Sales Prices, Sales Line Discounts on Sale Line Fact Box.
        VerifySalesLineFactBox(
          SalesOrder, ItemNo, SalesInfoPaneMgt.CalcAvailability(SalesLine), SalesInfoPaneMgt.CalcNoOfSubstitutions(SalesLine),
          SalesInfoPaneMgt.CalcNoOfSalesPrices(SalesLine), SalesInfoPaneMgt.CalcNoOfSalesLineDisc(SalesLine));
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithBilltoCust(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Bill-to Customer No.", CreateCustomer());
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithPaymentTerms(PaymentTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer());
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItemWithUnitPrice(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; SellToCustomerNo: Code[20]; PostingDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, SellToCustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; PostingDate: Date): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Invoice with Random Quantity.
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, PostingDate);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithUnitPrice(), LibraryRandom.RandDec(10, 2));
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields("Amount Including VAT");
        exit(SalesHeader."Amount Including VAT");
    end;

    local procedure CreateAndPostSalesDocument(CustomerNo: Code[20]; CurrencyCode: Code[10]): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, Today() - 1);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithUnitPrice(), LibraryRandom.RandDec(10, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesLine."Amount Including VAT");
    end;

    local procedure CreateBasicCustLedgerEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; CustNo: Code[20])
    begin
        CustLedgEntry.Init();
        CustLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgEntry, CustLedgEntry.FieldNo("Entry No."));
        CustLedgEntry."Posting Date" := WorkDate();
        CustLedgEntry."Customer No." := CustNo;
        CustLedgEntry.Open := true;
        CustLedgEntry.Insert();
    end;

    local procedure CreateCustLedgerEntryWithDueDate(var CustLedgEntry: Record "Cust. Ledger Entry"; CustNo: Code[20]; DueDate: Date)
    begin
        CreateBasicCustLedgerEntry(CustLedgEntry, CustNo);
        CustLedgEntry.Validate("Due Date", DueDate);
        CustLedgEntry.Modify(true);
    end;

    local procedure CreateClosedInvoiceCustLedgerEntryWithEmptyDueDate(var CustLedgEntry: Record "Cust. Ledger Entry"; CustNo: Code[20])
    begin
        CustLedgEntry.Init();
        CustLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgEntry, CustLedgEntry.FieldNo("Entry No."));
        CustLedgEntry."Posting Date" := WorkDate();
        CustLedgEntry."Customer No." := CustNo;
        CustLedgEntry."Document Type" := CustLedgEntry."Document Type"::Invoice;
        CustLedgEntry."Due Date" := 0D;
        CustLedgEntry.Open := false;
        CustLedgEntry.Insert();
    end;

    local procedure CreatePaymentDetailedCustLedgerEntryForCustLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgEntryNo: Integer)
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntryNo;
        DetailedCustLedgEntry."Document Type" := DetailedCustLedgEntry."Document Type"::Payment;
        DetailedCustLedgEntry.Insert();
    end;

    local procedure MockDetailedCustLedgerEntryWithDueDate(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CreatePaymentDetailedCustLedgerEntryForCustLedgerEntry(DetailedCustLedgEntry, CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.Validate("Initial Entry Due Date", CustLedgerEntry."Due Date");
        DetailedCustLedgEntry.Validate("Customer No.", CustLedgerEntry."Customer No.");
        DetailedCustLedgEntry.Validate(Amount, LibraryRandom.RandDec(1000, 2));
        DetailedCustLedgEntry.Modify(true);
    end;

    local procedure MockDetailedCustLedgerEntryWithPostingDate(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; PostingDate: Date)
    begin
        CreatePaymentDetailedCustLedgerEntryForCustLedgerEntry(DetailedCustLedgEntry, CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.Validate("Posting Date", PostingDate);
        DetailedCustLedgEntry.Validate("Customer No.", CustLedgerEntry."Customer No.");
        DetailedCustLedgEntry.Validate(Amount, LibraryRandom.RandDec(1000, 2));
        DetailedCustLedgEntry.Modify(true);
    end;

    local procedure MockSalesLine(CustNo: Code[20]; DocType: Enum "Sales Document Type"; OutstandingAmountLCY: Decimal; ShippedNotInvoicedLCY: Decimal; RetRcvdNotInvoicedLCY: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine."Document Type" := DocType;
        SalesLine."Document No." :=
          LibraryUtility.GenerateRandomCode(SalesLine.FieldNo("Document No."), DATABASE::"Sales Line");
        SalesLine."Bill-to Customer No." := CustNo;
        SalesLine."Outstanding Amount (LCY)" := OutstandingAmountLCY;
        SalesLine."Shipped Not Invoiced (LCY)" := ShippedNotInvoicedLCY;
        SalesLine."Return Rcd. Not Invd. (LCY)" := RetRcvdNotInvoicedLCY;
        SalesLine.Insert();
    end;

    local procedure MockServLine(CustNo: Code[20]; DocType: Enum "Service Document Type"; OutstandingAmountLCY: Decimal; ShippedNotInvoicedLCY: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.Init();
        ServiceLine."Document Type" := DocType;
        ServiceLine."Document No." :=
          LibraryUtility.GenerateRandomCode(ServiceLine.FieldNo("Document No."), DATABASE::"Service Line");
        ServiceLine."Bill-to Customer No." := CustNo;
        ServiceLine."Outstanding Amount (LCY)" := OutstandingAmountLCY;
        ServiceLine."Shipped Not Invoiced (LCY)" := ShippedNotInvoicedLCY;
        ServiceLine.Insert();
    end;

    local procedure FindCurrency(var Currency: Record Currency)
    begin
        Currency.SetRange("Invoice Rounding Precision", LibraryERM.GetAmountRoundingPrecision());
        LibraryERM.FindCurrency(Currency);
    end;

    local procedure FindPaymentTerms(var PaymentTerms: Record "Payment Terms")
    begin
        PaymentTerms.SetFilter("Due Date Calculation", '<>0D');  // Find Payment Terms having Due Date Calculation more than Zero Days.
        PaymentTerms.FindFirst();
    end;

    local procedure FindDocumentNo(CustomerNo: Code[20]): Code[20]
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        SalesInvHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesInvHeader.FindFirst();
        exit(SalesInvHeader."No.");
    end;

    local procedure InvokeCustStatsByCurrLinesFromCustomerList(var CustStatsByCurrLines: TestPage "Cust. Stats. by Curr. Lines"; CustomerNo: Code[20])
    var
        CustomerList: TestPage "Customer List";
    begin
        CustomerList.OpenView();
        CustomerList.FILTER.SetFilter("No.", CustomerNo);
        CustStatsByCurrLines.Trap();
        CustomerList."Statistics by C&urrencies".Invoke();
    end;

    local procedure InvokeCustStatsByCurrLinesFromCustomerCard(var CustStatsByCurrLines: TestPage "Cust. Stats. by Curr. Lines"; CustomerNo: Code[20])
    var
        CustomerCard: TestPage "Customer Card";
    begin
        CustomerCard.OpenView();
        CustomerCard.FILTER.SetFilter("No.", CustomerNo);
        CustStatsByCurrLines.Trap();
        CustomerCard."Statistics by C&urrencies".Invoke();
    end;

    local procedure OpenSalesOrderAndFindLine(var SalesOrder: TestPage "Sales Order"; DocumentNo: Code[20]; No: Code[20]; Type: Enum "Sales Line Type")
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", DocumentNo);
        SalesOrder.SalesLines.FILTER.SetFilter(Type, Format(Type));
        SalesOrder.SalesLines.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenSalesInvoicePage(SellToCustomerNo: Code[20]): Code[20]
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenNew();
        SalesInvoice."No.".AssistEdit();
        SalesInvoice."Sell-to Customer Name".SetValue(SellToCustomerNo);
        exit(SalesInvoice."No.".Value);
    end;

    local procedure PostPartialPaymentForCustomer(CustomerNo: Code[20]; InvoiceAmountLCY: Decimal): Decimal
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, -(InvoiceAmountLCY / LibraryRandom.RandIntInRange(2, 4)));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", FindDocumentNo(CustomerNo));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(-GenJournalLine.Amount);
    end;

    local procedure PostPaymentForCustomer(CustomerNo: Code[20]; PostingDate: Date): Decimal
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, -LibraryRandom.RandDec(1000, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(-GenJournalLine.Amount);
    end;

    local procedure ReversePayment(CustomerNo: Code[20]; PostingDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Posting Date", PostingDate);
        CustLedgerEntry.FindFirst();
        LibraryERM.ReverseTransaction(CustLedgerEntry."Transaction No.");
    end;

    local procedure UpdateSalesReceivableSetup(var OldCreditWarnings: Option; CreditWarnings: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldCreditWarnings := SalesReceivablesSetup."Credit Warnings";
        SalesReceivablesSetup.Validate("Credit Warnings", CreditWarnings);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateGenLedgerSetupForDataCheck(EnableDataCheck: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Enable Data Check", EnableDataCheck);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePostedNoSeriesInSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Invoice Nos.", LibraryERM.CreateNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Shipment Nos.", LibraryERM.CreateNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure VerifyFiltersOnCustStatsByCurrLinesPage(CustStatsByCurrLines: TestPage "Cust. Stats. by Curr. Lines"; CurrencyCode: Code[10]; CustomerBalance: Decimal)
    begin
        CustStatsByCurrLines.FILTER.SetFilter(Code, CurrencyCode);
        CustStatsByCurrLines."Customer Balance".AssertEquals(CustomerBalance);
    end;

    local procedure VerifyOverdueBalanceForCustomer(No: Code[20]; BalanceDueLCY: Decimal)
    var
        CustomerList: TestPage "Customer List";
        CustomerStatistics: TestPage "Customer Statistics";
    begin
        CustomerList.OpenView();
        CustomerList.FILTER.SetFilter("No.", No);
        CustomerStatistics.Trap();
        CustomerList.Statistics.Invoke();
        CustomerStatistics."Balance Due (LCY)".AssertEquals(BalanceDueLCY);
    end;

    local procedure VerifySalesLineFactBox(SalesOrder: TestPage "Sales Order"; ItemNo: Code[20]; Availability: Decimal; Substitutions: Integer; SalesPrices: Integer; SalesLineDiscounts: Integer)
    begin
        SalesOrder.Control1906127307.ItemNo.AssertEquals(ItemNo);
        SalesOrder.Control1906127307."Item Availability".AssertEquals(Availability);
        SalesOrder.Control1906127307.Substitutions.AssertEquals(Substitutions);
        SalesOrder.Control1906127307.SalesPrices.AssertEquals(SalesPrices);
        SalesOrder.Control1906127307.SalesLineDiscounts.AssertEquals(SalesLineDiscounts);
        SalesOrder.Close();
    end;

    local procedure VerifyCustomerStatisticsServiceItem(var CustomerStatistics: TestPage "Customer Statistics"; ExpectedCostAmount: Decimal; ExpectedProfitAmount: Decimal)
    begin
        Assert.AreNearlyEqual(
          ExpectedCostAmount,
          CustomerStatistics.ThisPeriodOriginalCostLCY.AsDecimal(),
          LibraryERM.GetAmountRoundingPrecision(),
          'Invalid This Period Original Cost (LCY) value');

        Assert.AreNearlyEqual(
          ExpectedProfitAmount,
          CustomerStatistics.ThisPeriodOriginalProfitLCY.AsDecimal(),
          LibraryERM.GetAmountRoundingPrecision(),
          'Invalid This Period Original Profit (LCY) value');

        Assert.AreNearlyEqual(
          ExpectedCostAmount,
          CustomerStatistics.ThisPeriodAdjustedCostLCY.AsDecimal(),
          LibraryERM.GetAmountRoundingPrecision(),
          'Invalid This Period Adjusted Cost (LCY) value');

        Assert.AreNearlyEqual(
          ExpectedProfitAmount,
          CustomerStatistics.ThisPeriodAdjustedProfitLCY.AsDecimal(),
          LibraryERM.GetAmountRoundingPrecision(),
          'Invalid This Period Adjusted Profit (LCY) value');

        CustomerStatistics.ThisPeriodCostAdjmtAmountsLCY.AssertEquals(0);
    end;

    local procedure CreatePaymentsThisYearDetailedCustLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry.Validate("Posting Date", WorkDate());
        DetailedCustLedgEntry.Validate("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.Validate("Entry Type", DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        DetailedCustLedgEntry.Validate("Customer No.", CustLedgerEntry."Customer No.");
        DetailedCustLedgEntry.Validate("Initial Document Type", DetailedCustLedgEntry."Initial Document Type"::Payment);
        DetailedCustLedgEntry.Validate("Amount (LCY)", -LibraryRandom.RandInt(1000));
        DetailedCustLedgEntry.Insert();
    end;

    local procedure CreateAndReleaseSalesInvoiceUsingGetShipmentLines(CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        LibrarySales.GetShipmentLines(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateItemInventory(var Item: Record Item; Qty: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name",
            ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Message: Text; var Response: Boolean)
    begin
        Response := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesPageHandler(var NoSeriesPage: TestPage "No. Series")
    begin
        NoSeriesPage.OK().Invoke();
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    var
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
    begin
        Assert.AreEqual(Notification.GetData('No.'), CustomerNo, 'Customer No. was different than expected');
        CustCheckCrLimit.ShowNotificationDetails(Notification);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NotificationDetailsHandler(var CreditLimitNotification: TestPage "Credit Limit Notification")
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.CalcFields("Balance (LCY)");
        Customer.CalcFields("Balance Due (LCY)");
        CreditLimitNotification.CreditLimitDetails."No.".AssertEquals(CustomerNo);
        CreditLimitNotification.CreditLimitDetails."Balance (LCY)".AssertEquals(Customer."Balance (LCY)");
        CreditLimitNotification.CreditLimitDetails.OverdueBalance.AssertEquals(Customer."Balance Due (LCY)");
        CreditLimitNotification.CreditLimitDetails."Credit Limit (LCY)".AssertEquals(Customer."Credit Limit (LCY)");
    end;

    [ModalPageHandler]
    procedure GetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        AssignSerial: Boolean;
    begin
        AssignSerial := LibraryVariableStorage.DequeueBoolean();
        if AssignSerial then
            ItemTrackingLines."Assign Serial No.".Invoke();

        if not AssignSerial then
            Assert.IsTrue(ItemTrackingLines."Lot No.".Value() <> '', LotNoErr);
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantitytoCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantitytoCreate.QtyToCreate.SetValue(LibraryVariableStorage.DequeueInteger());
        EnterQuantitytoCreate.CreateNewLotNo.SetValue(true);
        EnterQuantitytoCreate.OK().Invoke();
    end;
}
