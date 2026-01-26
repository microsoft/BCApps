codeunit 144180 "ERM NO Reports Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [NO Report]
        isInitialized := false;
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('RHSalesOrderPickingList')]
    [Scope('OnPrem')]
    procedure SalesQuotePickListLineCountMatchesSalesLines()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Sales Order Picking List]
        Initialize();

        UpdateSalesSetup(false);
        UpdateGeneralLedgerSetup(true);
        // Create sales order, but do not post
        CreateSalesDocumentWithOneItem(SalesHeader, SalesHeader."Document Type"::Order);

        // Exercise
        RunSalesOrderPickingList(SalesHeader."No.", false);

        Assert.AreEqual(1, CountSalesOrderPickingListSalesLines(), 'Expected one line in report with non-empty sales line type');
    end;

    [Test]
    [HandlerFunctions('RHSalesOrderPickingList')]
    [Scope('OnPrem')]
    procedure SalesQuotePickListDimensionLinesAreAdded()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Sales Order Picking List]
        Initialize();

        UpdateSalesSetup(false);
        UpdateGeneralLedgerSetup(true);
        CreateSalesDocumentWithTwoItems(SalesHeader, SalesHeader."Document Type"::Order);

        // Exercise with handler setting Show Internal Information to TRUE
        RunSalesOrderPickingList(SalesHeader."No.", true);

        // Expect 5 lines - 1 header line, 2 sales lines and 2 dimension lines
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(5, LibraryReportDataset.RowCount(), 'Expected 5 lines - 1 header line, 2 sales lines and 2 dimension lines');
        // There is a total of 4 line items - 2 from dimensions, 2 for the pick list
        Assert.AreEqual(4, CountLinesInLoadedDataSetFileHavingElement('SalesLine_Type'), 'Expected 4 sales lines in picking list');
        // Two of these lines should be dimension lines
        Assert.AreEqual(2, CountLinesInLoadedDataSetFileHavingElement('DimText_DimLoop2'), 'Expected 2 dimension lines in picking list');
    end;

    [Test]
    [HandlerFunctions('RHVendorBalance')]
    [Scope('OnPrem')]
    procedure VendorBalanceReturnsOneVendorRow()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Vendor - Balance]
        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateItem(), '');
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        Vendor.CalcFields("Balance (LCY)");

        // Exercise.
        RunVendorBalance(PurchaseHeader."Buy-from Vendor No.", false, false);

        // Verify: Verify Saved Report with Different Fields data.
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'Expected one row in the Vendor Balance Report');

        LibraryReportDataset.MoveToRow(1);

        LibraryReportDataset.AssertCurrentRowValueEquals('BalanceLCY', -Vendor."Balance (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('No_Vendor', Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('RHVendorBalance')]
    [Scope('OnPrem')]
    procedure VendorBalanceForNewVendorIsZero()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Vendor - Balance]
        // Setup.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise.
        RunVendorBalance(Vendor."No.", false, false);

        // Verify: Verify Saved Report with Different Fields data.
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'Expected one row in the Vendor Balance Report');

        LibraryReportDataset.MoveToRow(1);

        LibraryReportDataset.AssertCurrentRowValueEquals('BalanceLCY', 0);
    end;

    [Test]
    [HandlerFunctions('RHVendorBalance')]
    [Scope('OnPrem')]
    procedure VendorBalanceZeroNetChangeVendorsNotShown()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase] [Vendor - Balance]
        // Setup.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise.
        RunVendorBalance(Vendor."No.", true, false);

        // Verify: Verify Saved Report with Different Fields data.
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), 'Expected zero rows in the Vendor Balance Report');
    end;

    [Test]
    [HandlerFunctions('RHVendorAddressList')]
    [Scope('OnPrem')]
    procedure VendorAddressListIncludesNewVendor()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor - Address List]
        // Setup.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Address, 'SomeAddressText');
        Vendor.Modify(true);

        // Exercise.
        RunVendorAddressList('');

        // Verify: Verify Saved Report with Different Fields data.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Vendor', Vendor."No.");
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals('No_Vendor', Vendor."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Addr_Vendor', Vendor.Address);
    end;

    [Test]
    [HandlerFunctions('RHVendorAddressList')]
    [Scope('OnPrem')]
    procedure VendorAddressListAllowsBlankAddress()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor - Address List]
        // Setup.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise.
        RunVendorAddressList(Vendor."No.");

        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'Expected the Vendor Address List to include the vendor with blank address');

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('No_Vendor', Vendor."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Addr_Vendor', '');
    end;

    [Test]
    [HandlerFunctions('RHCustomerAddressList')]
    [Scope('OnPrem')]
    procedure CustomerAddressListIncludesNewCustomer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer - Address List]
        // Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Address, 'SomeAddressText');
        Customer.Modify(true);

        // Exercise.
        RunCustomerAddressList('');

        // Verify: Verify Saved Report with Different Fields data.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Customer', Customer."No.");
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals('No_Customer', Customer."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Address_Customer', Customer.Address);
    end;

    [Test]
    [HandlerFunctions('RHGLRegisterCustomerVendor')]
    [Scope('OnPrem')]
    procedure GLRegisterIncludesVATLines()
    var
        SalesHeader: Record "Sales Header";
        GLRegister: Record "G/L Register";
        Result: Variant;
        CustomerOrVendor: Text;
    begin
        // [FEATURE] [G/L Register Customer/Vendor]
        Initialize();

        // Create  customer with VAT posting group
        UpdateSalesSetup(false);
        UpdateGeneralLedgerSetup(true);

        // Create invoice and post it
        CreateSalesDocumentWithVAT(SalesHeader, SalesHeader."Document Type"::Invoice);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Find G/L Register number
        GLRegister.FindLast();

        // Run GLRegister for this entry number
        RunGLRegisterReport(GLRegister);

        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(3, LibraryReportDataset.RowCount(), 'Expected the report to contain 3 lines');
        Assert.AreEqual(0, LibraryReportDataset.Sum('Amount_GLEntry'), 'Expected sum to be zero');

        while LibraryReportDataset.GetNextRow() do begin
            LibraryReportDataset.AssertCurrentRowValueEquals('VendorDebit', 0);
            LibraryReportDataset.FindCurrentRowValue('CustomerOrVendor', Result);
            CustomerOrVendor := Result;
            if CustomerOrVendor <> '' then begin
                LibraryReportDataset.AssertCurrentRowValueEquals('CustomerOrVendor', 'Customer');
                LibraryReportDataset.AssertCurrentRowValueEquals('CustomerVendorNo', SalesHeader."Bill-to Customer No.");
            end
        end
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderPickingListOptionInSync()
    var
        SalesHeader: Record "Sales Header";
        DocumentPrint: Codeunit "Document-Print";
        Usage: Option "Order Confirmation","Work Order","Pick Instruction","Sales Order Picking List";
    begin
        // [FEATURE] [UT] [Sales] [Sales Order Picking List]
        // [SCENARIO 308897] Usage options for Report Selections and Custom Report Selection are in sync for Sales Order Picking List
        Initialize();

        CreateSalesDocumentWithOneItem(SalesHeader, SalesHeader."Document Type"::Order);
        asserterror DocumentPrint.PrintSalesOrder(SalesHeader, Usage::"Sales Order Picking List");
        Assert.ExpectedError('The Report Selections table is empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportSelectionSalesCanSelectSalesOrderPickingList()
    var
        ReportSelectionSales: TestPage "Report Selection - Sales";
        ReportUsage: Option Quote,"Blanket Order",Order,Invoice,"Work Order","Return Order","Credit Memo",Shipment,"Return Receipt","Sales Document - Test","Prepayment Document - Test","S.Arch. Quote","S.Arch. Order","S. Arch. Return Order","Pick Instruction","Customer Statement","Draft Invoice","Pro Forma Invoice","S. Arch. Blanket Order","S.Sales Order Picking List";
    begin
        // [FEATURE] [UT] [Sales] [Sales Order Picking List]
        // [SCENARIO 308897] Usage options for Page "Report Selection - Sales" allows to add for Sales Order Picking List report
        Initialize();

        ReportSelectionSales.OpenEdit();
        ReportSelectionSales.ReportUsage.SetValue(ReportUsage::"S.Sales Order Picking List");
        ReportSelectionSales."Report ID".SetValue(REPORT::"Sales Order Picking List");
        ReportSelectionSales.First();
        ReportSelectionSales."Report ID".AssertEquals(REPORT::"Sales Order Picking List");
        ReportSelectionSales.Close();
    end;

    [Test]
    [HandlerFunctions('TrialBalancePreviousPeriodRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TrialBalancePreviousPeriodIncomeAndBalance()
    var
        GLAccount: array[2] of Record "G/L Account";
    begin
        // [FEATURE] [UT] [Trial Balance/Previous Period]
        // [SCENARIO 313367] Running "Trial Balance/Previous Period" for G/L Acounts with both "Income Statement" and "Balance Sheet" leads to IncomeHidden and BalanceHidden being set to FALSE.
        Initialize();

        // [GIVEN] G/L Accounts with "Income/Balance" set to "Income Statement" / "Balance Sheet".
        CreateGLAccountWithIncomeOrBalanceAndNewPage(GLAccount[1], GLAccount[1]."Income/Balance"::"Income Statement", false);
        CreateGLAccountWithIncomeOrBalanceAndNewPage(GLAccount[2], GLAccount[2]."Income/Balance"::"Balance Sheet", false);

        // [WHEN] Report "Trial Balance/Previous Period" is run with filter set to G/L Accounts "No."'s.
        Commit();
        GLAccount[1].SetFilter("No.", StrSubstNo('%1|%2', GLAccount[1]."No.", GLAccount[2]."No."));
        GLAccount[1].SetRange("Date Filter", WorkDate());
        REPORT.Run(REPORT::"Trial Balance/Previous Period", true, false, GLAccount[1]);

        // [THEN] IncomeHidden and BalanceHidden are set to FALSE.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('IncomeHidden', false);
        LibraryReportDataset.AssertElementWithValueExists('BalanceHidden', false);
    end;

    [Test]
    [HandlerFunctions('TrialBalancePreviousPeriodRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TrialBalancePreviousPeriodIncome()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [UT] [Trial Balance/Previous Period]
        // [SCENARIO 313367] Running "Trial Balance/Previous Period" for G/L Acounts only with "Income Statement" leads to IncomeHidden and BalanceHidden being set to FALSE/TRUE.
        Initialize();

        // [GIVEN] G/L Accounts with "Income/Balance" set to "Income Statement".
        CreateGLAccountWithIncomeOrBalanceAndNewPage(GLAccount, GLAccount."Income/Balance"::"Income Statement", false);

        // [WHEN] Report "Trial Balance/Previous Period" is run with filter set to G/L Account "No.".
        Commit();
        GLAccount.SetRange("No.", GLAccount."No.");
        GLAccount.SetRange("Date Filter", WorkDate());
        REPORT.Run(REPORT::"Trial Balance/Previous Period", true, false, GLAccount);

        // [THEN] IncomeHidden and BalanceHidden are set to FALSE/TRUE.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('IncomeHidden', false);
        LibraryReportDataset.AssertElementWithValueExists('BalanceHidden', true);
    end;

    [Test]
    [HandlerFunctions('TrialBalancePreviousPeriodRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TrialBalancePreviousPeriodBalance()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [UT] [Trial Balance/Previous Period]
        // [SCENARIO 313367] Running "Trial Balance/Previous Period" for G/L Acounts only with "Balance Sheet" leads to IncomeHidden and BalanceHidden being set to TRUE/FALSE.
        Initialize();

        // [GIVEN] G/L Accounts with "Income/Balance" set to "Balance Sheet".
        CreateGLAccountWithIncomeOrBalanceAndNewPage(GLAccount, GLAccount."Income/Balance"::"Balance Sheet", false);

        // [WHEN] Report "Trial Balance/Previous Period" is run with filter set to G/L Account "No.".
        Commit();
        GLAccount.SetRange("No.", GLAccount."No.");
        GLAccount.SetRange("Date Filter", WorkDate());
        REPORT.Run(REPORT::"Trial Balance/Previous Period", true, false, GLAccount);

        // [THEN] IncomeHidden and BalanceHidden are set to TRUE/FALSE.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('IncomeHidden', true);
        LibraryReportDataset.AssertElementWithValueExists('BalanceHidden', false);
    end;

    [Test]
    [HandlerFunctions('TrialBalancePreviousPeriodRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TrialBalancePreviousPeriodNewPageSetToFalse()
    var
        GLAccount: array[4] of Record "G/L Account";
    begin
        // [FEATURE] [UT] [Trial Balance/Previous Period]
        // [SCENARIO 313367] Running "Trial Balance/Previous Period" for G/L Acounts with both "Income Statement" and "Balance Sheet" and "New Page" set to FALSE leads to IncomePageNo and BalancePageNo equal only to 0.
        Initialize();

        // [GIVEN] G/L Accounts with "Income/Balance" set to "Income Statement" / "Balance Sheet" and "New Page" set to FALSE.
        CreateGLAccountWithIncomeOrBalanceAndNewPage(GLAccount[1], GLAccount[1]."Income/Balance"::"Income Statement", false);
        CreateGLAccountWithIncomeOrBalanceAndNewPage(GLAccount[2], GLAccount[2]."Income/Balance"::"Income Statement", false);
        CreateGLAccountWithIncomeOrBalanceAndNewPage(GLAccount[3], GLAccount[3]."Income/Balance"::"Balance Sheet", false);
        CreateGLAccountWithIncomeOrBalanceAndNewPage(GLAccount[4], GLAccount[4]."Income/Balance"::"Balance Sheet", false);

        // [WHEN] Report "Trial Balance/Previous Period" is run with filter set to G/L Accounts "No."'s.
        Commit();
        GLAccount[1].SetFilter(
          "No.", StrSubstNo('%1|%2|%3|%4', GLAccount[1]."No.", GLAccount[2]."No.", GLAccount[3]."No.", GLAccount[4]."No."));
        GLAccount[1].SetRange("Date Filter", WorkDate());
        REPORT.Run(REPORT::"Trial Balance/Previous Period", true, false, GLAccount[1]);

        // [THEN] IncomePageNo and BalancePageNo equal to 0 exist, equal to 1 dont.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('IncomePageNo', 0);
        LibraryReportDataset.AssertElementWithValueNotExist('IncomePageNo', 1);
        LibraryReportDataset.AssertElementWithValueExists('BalancePageNo', 0);
        LibraryReportDataset.AssertElementWithValueNotExist('BalancePageNo', 1);
    end;

    [Test]
    [HandlerFunctions('TrialBalancePreviousPeriodRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TrialBalancePreviousPeriodNewPageSetToTrue()
    var
        GLAccount: array[4] of Record "G/L Account";
    begin
        // [FEATURE] [UT] [Trial Balance/Previous Period]
        // [SCENARIO 313367] Running "Trial Balance/Previous Period" for G/L Acounts with both "Income Statement" and "Balance Sheet" and "New Page" set to TRUE leads to IncomePageNo and BalancePageNo equal to 0 and 1.
        Initialize();

        // [GIVEN] G/L Accounts with "Income/Balance" set to "Income Statement" / "Balance Sheet" and "New Page" set to TRUE and FALSE.
        CreateGLAccountWithIncomeOrBalanceAndNewPage(GLAccount[1], GLAccount[1]."Income/Balance"::"Income Statement", true);
        CreateGLAccountWithIncomeOrBalanceAndNewPage(GLAccount[2], GLAccount[2]."Income/Balance"::"Income Statement", false);
        CreateGLAccountWithIncomeOrBalanceAndNewPage(GLAccount[3], GLAccount[3]."Income/Balance"::"Balance Sheet", true);
        CreateGLAccountWithIncomeOrBalanceAndNewPage(GLAccount[4], GLAccount[4]."Income/Balance"::"Balance Sheet", false);

        // [WHEN] Report "Trial Balance/Previous Period" is run with filter set to G/L Accounts "No."'s.
        Commit();
        GLAccount[1].SetFilter(
          "No.", StrSubstNo('%1|%2|%3|%4', GLAccount[1]."No.", GLAccount[2]."No.", GLAccount[3]."No.", GLAccount[4]."No."));
        GLAccount[1].SetRange("Date Filter", WorkDate());
        REPORT.Run(REPORT::"Trial Balance/Previous Period", true, false, GLAccount[1]);

        // [THEN] IncomePageNo and BalancePageNo equal to 0 and 1 exist.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('IncomePageNo', 0);
        LibraryReportDataset.AssertElementWithValueExists('IncomePageNo', 1);
        LibraryReportDataset.AssertElementWithValueExists('BalancePageNo', 0);
        LibraryReportDataset.AssertElementWithValueExists('BalancePageNo', 1);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
    end;

    local procedure UpdateGeneralLedgerSetup(VATSpecificationInLCY: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Print VAT specification in LCY" := VATSpecificationInLCY;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateSalesSetup(InvoiceRounding: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Invoice Rounding", InvoiceRounding);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateCustomerWithVATBusPostingGroup(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithDimensions(var Customer: Record Customer)
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        LibraryDim: Codeunit "Library - Dimension";
    begin
        // Create test dimensions
        LibraryDim.CreateDimension(Dimension);
        LibraryDim.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibrarySales.CreateCustomer(Customer);

        LibraryDim.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, DimensionValue.Code)
    end;

    local procedure CreateGLAccountWithIncomeOrBalanceAndNewPage(var GLAccount: Record "G/L Account"; IncomeOrBalance: Enum "G/L Account Report Type"; NewPage: Boolean)
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", IncomeOrBalance);
        GLAccount.Validate("New Page", NewPage);
        GLAccount.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));   // Using RANDOM value for Last Direct Cost.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; CurrencyCode: Code[10])
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseHeader, ItemNo);
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Use Random Value.
    end;

    local procedure CreateSalesDocumentWithOneItem(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(20));
    end;

    local procedure CreateSalesDocumentWithTwoItems(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        CreateCustomerWithDimensions(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(20));
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(20));
    end;

    local procedure CreateSalesDocumentWithVAT(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
    begin
        // Select a VAT Posting setup with VAT % different from 0
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);

        CustomerNo := CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);

        LibraryInventory.CreateItem(Item);
        Item."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        Item."Unit Price" := LibraryRandom.RandInt(20000);
        Item.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(20));
    end;

    local procedure RunSalesOrderPickingList(No: Code[20]; ShowInternalInformation: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesOrderPickingList: Report "Sales Order Picking List";
    begin
        Clear(SalesOrderPickingList);
        SalesHeader.SetRange("No.", No);
        SalesOrderPickingList.SetTableView(SalesHeader);
        Commit();
        LibraryVariableStorage.Enqueue(ShowInternalInformation);
        SalesOrderPickingList.Run();
    end;

    local procedure RunVendorBalance(No: Code[20]; ShowOnlyIfNetChange: Boolean; ShowOnlyGroups: Boolean)
    var
        Vendor: Record Vendor;
        VendorBalance: Report "Vendor - Balance";
    begin
        Clear(VendorBalance);
        Vendor.SetRange("No.", No);
        VendorBalance.SetTableView(Vendor);
        Commit();
        LibraryVariableStorage.Enqueue(ShowOnlyIfNetChange);
        LibraryVariableStorage.Enqueue(ShowOnlyGroups);
        VendorBalance.Run();
    end;

    local procedure RunVendorAddressList(No: Code[20])
    var
        Vendor: Record Vendor;
        VendorAddressList: Report "Vendor - Address List";
    begin
        Clear(VendorAddressList);
        if No <> '' then begin
            Vendor.SetRange("No.", No);
            VendorAddressList.SetTableView(Vendor);
        end;

        Commit();
        VendorAddressList.Run();
    end;

    local procedure RunCustomerAddressList(No: Code[20])
    var
        Customer: Record Customer;
        CustomerAddressList: Report "Customer - Address List";
    begin
        Clear(CustomerAddressList);
        if No <> '' then begin
            Customer.SetRange("No.", No);
            CustomerAddressList.SetTableView(Customer);
        end;

        Commit();
        CustomerAddressList.Run();
    end;

    local procedure RunGLRegisterReport(var GLRegister: Record "G/L Register")
    var
        GLRegisterCustomerVendor: Report "G/L Register Customer/Vendor";
    begin
        Clear(GLRegisterCustomerVendor);
        GLRegister.SetRange("No.", GLRegister."No.");
        GLRegisterCustomerVendor.SetTableView(GLRegister);

        Commit();
        GLRegisterCustomerVendor.Run();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHSalesOrderPickingList(var SalesOrderPickingList: TestRequestPage "Sales Order Picking List")
    var
        ShowInternalInformationVariant: Variant;
        ShowInternalInformation: Boolean;
    begin
        LibraryVariableStorage.Dequeue(ShowInternalInformationVariant);
        ShowInternalInformation := ShowInternalInformationVariant;

        // Set Show Internal Information Control1080094
        SalesOrderPickingList.ShowInternalInfo.SetValue(ShowInternalInformation);
        SalesOrderPickingList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorBalance(var VendorBalance: TestRequestPage "Vendor - Balance")
    var
        ShowOnlyIfNetChangeVariant: Variant;
        ShowOnlyIfNetChange: Boolean;
    begin
        LibraryVariableStorage.Dequeue(ShowOnlyIfNetChangeVariant);
        ShowOnlyIfNetChange := ShowOnlyIfNetChangeVariant;

        VendorBalance.ShowIfNetChange.SetValue(ShowOnlyIfNetChange);
        VendorBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorAddressList(var VendorAddressList: TestRequestPage "Vendor - Address List")
    begin
        VendorAddressList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCustomerAddressList(var CustomerAddressList: TestRequestPage "Customer - Address List")
    begin
        CustomerAddressList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHGLRegisterCustomerVendor(var GLRegisterCustomerVendor: TestRequestPage "G/L Register Customer/Vendor")
    begin
        GLRegisterCustomerVendor.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalancePreviousPeriodRequestPageHandler(var TrialBalancePreviousPeriod: TestRequestPage "Trial Balance/Previous Period")
    begin
        TrialBalancePreviousPeriod.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure CountSalesOrderPickingListSalesLines(): Integer
    begin
        LibraryReportDataset.LoadDataSetFile();
        exit(CountLinesInLoadedDataSetFileHavingElement('SalesLine_Type'));
    end;

    local procedure CountLinesInLoadedDataSetFileHavingElement(ElementName: Text): Integer
    var
        LineCount: Integer;
    begin
        LineCount := 0;

        LibraryReportDataset.Reset();

        while LibraryReportDataset.GetNextRow() do
            if LibraryReportDataset.CurrentRowHasElement(ElementName) then
                LineCount := LineCount + 1;

        exit(LineCount);
    end;
}

