codeunit 144036 "UT PAG Telebank"
{
    // 1.     Purpose of the test is to validate Vendor Bank Account on Vendor Card Page.
    // 2-6.   Purpose of the test is to validate Error for Vendor Bank Account on Purchase Documents (Quote, Order, Return Order, Invoice, Credit Memo) without Vendor No.
    // 7-11.  Purpose of the test is to validate Vendor Bank Account on Purchase Documents (Quote, Order, Return Order, Invoice and Credit Memo).
    // 12.    Purpose of the test is to validate Customer Bank Account Customer Card Page.
    // 13-17. Purpose of the test is to validate Error for Customer Bank Account on Sales Documents (Quote, Order, Return Order, Invoice and Credit Memo) without Customer No.
    // 18-22. Purpose of the test is to validate Customer Bank Account on Sales Documents (Quote, Order, Return Order, Invoice and Credit Memo).
    // 23-31. Purpose of the test cases to validate Triggers & Actions on Telebank - Bank Overview page.
    // 32-37. Purpose of the test cases to validate Triggers & Actions on Proposal Detail Line page.
    // 38-43. Purpose of the test cases to validate Actions on Payment History List page.
    // 44-47. Purpose of the test cases to validate Actions on Payment History Line Subform page.
    // 48.    Purpose of the test cases to validate Actions on Import Protocol List page.
    // 49. Purpose of the test is to validate Bank Account Code on Page - 370 Bank Account Card.
    // 
    // Covers Test Cases for WI - 342309
    // -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                                                         TFS ID
    // -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // OnLookupBankAccountCodeVendor, OnInsertVendorBankAccountPurchaseQuoteError, OnInsertVendorBankAccountPurchaseOrderError                                    158444,158445,158446
    // OnInsertVendorBankAccountPurchaseReturnOrderError, OnInsertVendorBankAccountPurchaseInvoiceError, OnInsertVendorBankAccountPurchaseCreditMemoError         158447,158448,158449
    // OnLookupBankAccountCodePurchaseQuote,OnLookupBankAccountCodePurchaseOrder, OnLookupBankAccountCodePurchaseReturnOrder,
    // OnLookupBankAccountCodePurchaseInvoice, OnLookupBankAccountCodePurchaseCreditMemo
    // 
    // OnLookupBankAccountCodeCustomer, OnInsertCustomerBankAccountSalesQuoteError, OnInsertCustomerBankAccountSalesOrderError                                    158450,158451,158452
    // OnInsertCustomerBankAccountSalesReturnOrderError,OnInsertCustomerBankAccountSalesInvoiceError, OnInsertCustomerBankAccountSalesCreditMemoError             158453,158454,158455
    // OnLookupCustomerBankAccountCodeSalesQuote, OnLookupCustomerBankAccountCodeSalesOrder,OnLookupCustomerBankAccountCodeSalesReturnOrder
    // OnLookupCustomerBankAccountCodeSalesInvoice, OnLookupCustomerBankAccountCodeSalesCreditMemo
    // 
    // Covers Test Cases for WI - 343047
    // -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                                                         TFS ID
    // -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // OnDrillDownProposalTelebankBankOverview, OnDrillDownPaymentHistoryTelebankBankOverview, OnActionContactTelebankBankOverview
    // OnActionProposalTelebankBankOverview, OnActionGetProposalEntriesTelebankBankOverview, OnActionPaymentHistoryTelebankBankOverview
    // OnActionProposalOverviewTelebankBankOverview, OnActionPaymentHistoryOverviewTelebankBankOverview,
    // OnActionDefaultDimensionMultipleTelebankBankOverview
    // 
    // OnValidatePercentProposalDetailLine, OnActionCheckProposalDetailLine, OnActionProcessProposalDetailLine
    // OnActionToOtherBankProposalDetailLine, OnActionUpdateDescriptionsCustomerProposalDetailLine, OnActionUpdateDescriptionsVendorProposalDetailLine
    // OnValidateRemainingAmountPaymentHistory, OnActionCardPaymentHistory, OnActionPrintPaymentHistory, OnActionDimensionsPaymentHistory,
    // OnActionExportPaymentHistory                                                                                                                                171483
    // OnActionPrintDocketPaymentHistory, OnActionCardPaymentHistoryLine, OnActionDimensionsPaymentHistoryLine,
    // OnActionLedgerEntriesPaymentHistoryLine, OnActionDetailInformationPaymentHistoryLine, OnActionModifyImportProtocols
    // 
    // Covers Test Cases for WI - 343629
    // --------------------------------------------
    // Test Function Name
    // --------------------------------------------
    // OnOpenPageBankAccountCard

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UT] [UI] [Telebank]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        BankAccountCodeValidationErr: Label 'DB:RecordNotFound';
        LibraryRandom: Codeunit "Library - Random";
        ExportProtocolMsg: Label 'BTL91 data has been exported to disk.';
        ExportProtocol2Msg: Label 'File names can be found on payment history form';
        UnexpectedMsg: Label 'Unexpected Message.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [HandlerFunctions('ObjectListHandler')]
    [Scope('OnPrem')]
    procedure OnLookupReportExportIDOnExportProtocol()
    var
        ExportProtocol: Record "Export Protocol";
        AllObj: Record AllObj;
        ExportProtocols: TestPage "Export Protocols";
    begin
        ExportProtocols.OpenEdit();
        ExportProtocols.New();
        ExportProtocols.Code.SetValue(LibraryUTUtility.GetNewCode());
        ExportProtocols."Export Object Type".SetValue(ExportProtocol."Export Object Type"::Report);
        LibraryVariableStorage.Enqueue(AllObj."Object Type"::Report);
        ExportProtocols."Export ID".Lookup();
        // Verified by ObjectListHandler
        Assert.AreNotEqual('', ExportProtocols."Export Name".Value, ExportProtocol.FieldName("Export Name"));
    end;

    [Test]
    [HandlerFunctions('ObjectListHandler')]
    [Scope('OnPrem')]
    procedure OnLookupXMLPortExportIDOnExportProtocol()
    var
        ExportProtocol: Record "Export Protocol";
        AllObj: Record AllObj;
        ExportProtocols: TestPage "Export Protocols";
    begin
        ExportProtocols.OpenEdit();
        ExportProtocols.New();
        ExportProtocols.Code.SetValue(LibraryUTUtility.GetNewCode());
        ExportProtocols."Export Object Type".SetValue(ExportProtocol."Export Object Type"::XMLPort);
        LibraryVariableStorage.Enqueue(AllObj."Object Type"::XMLport);
        ExportProtocols."Export ID".Lookup();
        // Verified by ObjectListHandler
        Assert.AreNotEqual('', ExportProtocols."Export Name".Value, ExportProtocol.FieldName("Export Name"));
    end;

    [Test]
    [HandlerFunctions('VendorBankAccountListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnLookupBankAccountCodeVendor()
    var
        VendorCard: TestPage "Vendor Card";
        VendorBankAccountCode: Code[10];
    begin
        // Purpose of the test is to validate Bank Account Code on Page - 26 Vendor Card.
        // Setup: Create Vendor and Vendor Bank Account.
        VendorCard.OpenEdit();
        VendorCard.FILTER.SetFilter("No.", CreateVendor());
        VendorBankAccountCode := CreateVendorBankAccountByPage(VendorCard."No.".Value);

        // Exercise: Lookup through VendorBankAccountListPageHandler on Vendor Card Page.
        VendorCard."Preferred Bank Account Code".Lookup();

        // Verify: Verify Vendor Bank Account Code on Vendor Card.
        VendorCard."Preferred Bank Account Code".AssertEquals(VendorBankAccountCode);
        VendorCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertVendorBankAccountPurchaseQuoteError()
    var
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // Purpose of the test is to validate Error for Vendor Bank Account on Purchase Quote without Vendor No.
        // Setup: Create Purchase Quote without Vendor.
        OpenPurchaseQuote(PurchaseQuote);

        // Exercise and Verify: Create Vendor Bank Account without vendor and Verify error code.
        ErrorForVendorBankAccount(PurchaseQuote."Buy-from Vendor Name".Value);
        PurchaseQuote.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertVendorBankAccountPurchaseOrderError()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // Purpose of the test is to validate Error for Vendor Bank Account on Purchase Order without Vendor No.
        // Setup: Create Purchase Order without Vendor.
        OpenPurchaseOrder(PurchaseOrder);

        // Exercise and Verify: Create Vendor Bank Account without vendor and Verify error code.
        ErrorForVendorBankAccount(PurchaseOrder."Buy-from Vendor Name".Value);
        PurchaseOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertVendorBankAccountPurchaseReturnOrderError()
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // Purpose of the test is to validate Error for Vendor Bank Account on Purchase Return Order without Vendor No.
        // Setup: Create Purchase Return Order without Vendor.
        OpenPurchaseReturnOrder(PurchaseReturnOrder);

        // Exercise and Verify: Create Vendor Bank Account without vendor and Verify error code.
        ErrorForVendorBankAccount(PurchaseReturnOrder."Buy-from Vendor Name".Value);
        PurchaseReturnOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertVendorBankAccountPurchaseInvoiceError()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Purpose of the test is to validate Error for Vendor Bank Account on Purchase Invoice without Vendor No.
        // Setup: Create Purchase Invoice without Vendor.
        OpenPurchaseInvoice(PurchaseInvoice);

        // Exercise and Verify: Create Vendor Bank Account without vendor and Verify error code.
        ErrorForVendorBankAccount(PurchaseInvoice."Buy-from Vendor Name".Value);
        PurchaseInvoice.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertVendorBankAccountPurchaseCreditMemoError()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Purpose of the test is to validate Error for Vendor Bank Account on Purchase Credit Memo without Vendor No.
        // Setup: Create Purchase Credit Memo without Vendor.
        OpenPurchaseCreditMemo(PurchaseCreditMemo);

        // Exercise and Verify: Create Vendor Bank Account without vendor and Verify error code.
        ErrorForVendorBankAccount('');
        PurchaseCreditMemo.Close();
    end;

    local procedure ErrorForVendorBankAccount(BuyFromVendorNo: Code[20])
    begin
        // Exercise: Call OnInsert trigger of Vendor Bank Account.
        asserterror CreateVendorBankAccountInsertTrue(BuyFromVendorNo);

        // Verify: Verify error code, actual error is 'The Vendor does not exist.', on trigger OnInsert of Vendor Bank Account table.
        Assert.ExpectedErrorCode(BankAccountCodeValidationErr);
    end;

    [Test]
    [HandlerFunctions('VendorBankAccountListPageHandler')]
    [Scope('OnPrem')]
    procedure OnLookupBankAccountCodePurchaseQuote()
    var
        Vendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
        VendorBankAccountCode: Code[10];
    begin
        // Purpose of the test is to validate Bank Account Code on Purchase Quote with Vendor No.
        // Setup: Create Purchase Quote and Create Vendor Bank Account by Page.
        OpenPurchaseQuote(PurchaseQuote);
        Vendor.Get(CreateVendor());
        PurchaseQuote."Buy-from Vendor Name".SetValue(Vendor.Name);  // COMMIT have been used on OnValidate of field "Buy-from Vendor No." on Page 49 - Purchase Quote.
        VendorBankAccountCode := CreateVendorBankAccountByPage(Vendor."No.");

        // Exercise: Lookup through VendorBankAccountListPageHandler on Purchase Quote Page.
        PurchaseQuote."Bank Account Code".Lookup();

        // Verify: Verify Bank Account Code on Purchase Quote Page.
        PurchaseQuote."Bank Account Code".AssertEquals(VendorBankAccountCode);
        PurchaseQuote.Close();
    end;

    [Test]
    [HandlerFunctions('VendorBankAccountListPageHandler')]
    [Scope('OnPrem')]
    procedure OnLookupBankAccountCodePurchaseOrder()
    var
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        VendorBankAccountCode: Code[10];
    begin
        // Purpose of the test is to validate Bank Account Code on Purchase Order with Vendor No.
        // Setup: Create Purchase Order and Create Vendor Bank Account by Page.
        OpenPurchaseOrder(PurchaseOrder);
        Vendor.Get(CreateVendor());
        PurchaseOrder."Buy-from Vendor Name".SetValue(Vendor.Name);  // COMMIT have been used on OnValidate of field "Buy-from Vendor No." on Page 50 - Purchase Order.
        VendorBankAccountCode := CreateVendorBankAccountByPage(Vendor."No.");

        // Exercise: Lookup through VendorBankAccountListPageHandler on Purchase Order Page.
        PurchaseOrder."Bank Account Code".Lookup();

        // Verify: Verify Bank Account Code on Purchase Order Page.
        PurchaseOrder."Bank Account Code".AssertEquals(VendorBankAccountCode);
        PurchaseOrder.Close();
    end;

    [Test]
    [HandlerFunctions('VendorBankAccountListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnLookupBankAccountCodePurchaseReturnOrder()
    var
        Vendor: Record Vendor;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        VendorBankAccountCode: Code[10];
    begin
        // Purpose of the test is to validate Bank Account Code on Purchase Return Order with Vendor No.
        // Setup: Create Purchase Return Order and Create Vendor Bank Account by Page.
        OpenPurchaseReturnOrder(PurchaseReturnOrder);
        Vendor.Get(CreateVendor());
        PurchaseReturnOrder."Buy-from Vendor Name".SetValue(Vendor.Name);
        VendorBankAccountCode := CreateVendorBankAccountByPage(Vendor."No.");

        // Exercise: Lookup through VendorBankAccountListPageHandler on Purchase Return Order Page.
        PurchaseReturnOrder."Bank Account Code".Lookup();

        // Verify: Verify Bank Account Code on Purchase Return Order Page.
        PurchaseReturnOrder."Bank Account Code".AssertEquals(VendorBankAccountCode);
        PurchaseReturnOrder.Close();
    end;

    [Test]
    [HandlerFunctions('VendorBankAccountListPageHandler')]
    [Scope('OnPrem')]
    procedure OnLookupBankAccountCodePurchaseInvoice()
    var
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorBankAccountCode: Code[10];
    begin
        // Purpose of the test is to validate Bank Account Code on Purchase Invoice with Vendor No.
        // Setup: Create Purchase Invoice and Create Vendor Bank Account by Page.
        OpenPurchaseInvoice(PurchaseInvoice);
        Vendor.Get(CreateVendor());
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);  // COMMIT have been used on OnValidate of field "Buy-from Vendor No." on Page 51 - Purchase Invoice.
        VendorBankAccountCode := CreateVendorBankAccountByPage(Vendor."No.");

        // Exercise: Lookup through VendorBankAccountListPageHandler on Purchase Invoice Page.
        PurchaseInvoice."Bank Account Code".Lookup();

        // Verify: Verify Bank Account Code on Purchase Invoice Page.
        PurchaseInvoice."Bank Account Code".AssertEquals(VendorBankAccountCode);
        PurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('VendorBankAccountListPageHandler')]
    [Scope('OnPrem')]
    procedure OnLookupBankAccountCodePurchaseCreditMemo()
    var
        Vendor: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        VendorBankAccountCode: Code[10];
    begin
        // Purpose of the test is to validate Bank Account Code on Purchase Credit Memo with Vendor No.
        // Setup: Create Purchase Credit Memo and Create Vendor Bank Account by Page.
        OpenPurchaseCreditMemo(PurchaseCreditMemo);
        Vendor.Get(CreateVendor());
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vendor.Name);
        VendorBankAccountCode := CreateVendorBankAccountByPage(Vendor."No.");

        // Exercise: Lookup through VendorBankAccountListPageHandler on Purchase Credit Memo Page.
        PurchaseCreditMemo."Bank Account Code".Lookup();

        // Verify: Verify Bank Account Code on Purchase Credit Memo Page.
        PurchaseCreditMemo."Bank Account Code".AssertEquals(VendorBankAccountCode);
        PurchaseCreditMemo.Close();
    end;

    [Test]
    [HandlerFunctions('CustomerBankAccountListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnLookupBankAccountCodeCustomer()
    var
        CustomerCard: TestPage "Customer Card";
        CustomerBankAccountCode: Code[10];
    begin
        // Purpose of the test is to validate Bank Account Code On Customer Card.
        // Setup: Create Customer and Customer Bank Account.
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", CreateCustomer());
        CustomerBankAccountCode := CreateCustomerBankAccountByPage(CustomerCard."No.".Value);

        // Exercise: Lookup through CustomerBankAccountListPageHandler on Customer Card Page.
        CustomerCard."Preferred Bank Account Code".Lookup();

        // Verify: Verify Bank Account Code on Customer Card Page.
        CustomerCard."Preferred Bank Account Code".AssertEquals(CustomerBankAccountCode);
        CustomerCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertCustomerBankAccountSalesQuoteError()
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        // Purpose of the test is to validate Error for Customer Bank Account on Sales Quote without Customer No.
        // Setup: Create Sales Quote without Customer.
        OpenSalesQuote(SalesQuote);

        // Exercise and Verify: Create customer Bank Account without customer and Verify error.
        ErrorForCustomerBankAccount('');
        SalesQuote.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertCustomerBankAccountSalesOrderError()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // Purpose of the test is to validate Error for Customer Bank Account on Sales Order without Customer No.
        // Setup: Create Sales Order without Customer.
        OpenSalesOrder(SalesOrder);

        // Exercise and Verify: Create customer Bank Account without customer and Verify error.
        ErrorForCustomerBankAccount(SalesOrder."Sell-to Customer Name".Value);
        SalesOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertCustomerBankAccountSalesReturnOrderError()
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // Purpose of the test is to validate Error for Customer Bank Account on Sales Return Order without Customer No.
        // Setup: Create Sales Return Order without Customer.
        OpenSalesReturnOrder(SalesReturnOrder);

        // Exercise and Verify: Create customer Bank Account without customer and Verify error.
        ErrorForCustomerBankAccount(SalesReturnOrder."Sell-to Customer Name".Value);
        SalesReturnOrder.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertCustomerBankAccountSalesInvoiceError()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Purpose of the test is to validate Error for Customer Bank Account on Sales Invoice without Customer No.
        // Setup: Create Sales Invoice without Customer.
        OpenSalesInvoice(SalesInvoice);

        // Exercise and Verify: Create customer Bank Account without customer and Verify error.
        ErrorForCustomerBankAccount(SalesInvoice."Sell-to Customer Name".Value);
        SalesInvoice.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertCustomerBankAccountSalesCreditMemoError()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // Purpose of the test is to validate Error for Customer Bank Account on Sales Credit Memo without Customer No.
        // Setup: Create Sales Credit Memo without Customer.
        OpenSalesCreditMemo(SalesCreditMemo);

        // Exercise and Verify: Create customer Bank Account without customer and Verify error.
        ErrorForCustomerBankAccount(SalesCreditMemo."Sell-to Customer Name".Value);
        SalesCreditMemo.Close();
    end;

    local procedure ErrorForCustomerBankAccount(SellToCustomerNo: Code[20])
    begin
        // Exercise: Call OnInsert trigger of Customer Bank Account.
        asserterror CreateCustomerBankAccountInsertTrue(SellToCustomerNo);

        // Verify: Verify error code, actual error is 'The Customer does not exist.', on trigger OnInsert of Customer Bank Account table.
        Assert.ExpectedErrorCode(BankAccountCodeValidationErr);
    end;

    [Test]
    [HandlerFunctions('CustomerBankAccountListPageHandler')]
    [Scope('OnPrem')]
    procedure OnLookupCustomerBankAccountCodeSalesQuote()
    var
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
        CustomerBankAccountCode: Code[10];
    begin
        // Purpose of the test is to validate Bank Account Code on Sales Quote with Customer No.
        // Setup: Create Sales Quote and CreateCustomer Bank Account Card by Page.
        OpenSalesQuote(SalesQuote);
        Customer.Get(CreateCustomer());
        SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);
        CustomerBankAccountCode := CreateCustomerBankAccountByPage(Customer."No.");

        // Exercise: Lookup through CustomerBankAccountListPageHandler on Sales Quote Page.
        SalesQuote."Bank Account Code".Lookup();

        // Verify: Verify Bank Account Code on Sales Quote Page.
        SalesQuote."Bank Account Code".AssertEquals(CustomerBankAccountCode);
        SalesQuote.Close();
    end;

    [Test]
    [HandlerFunctions('CustomerBankAccountListPageHandler')]
    [Scope('OnPrem')]
    procedure OnLookupCustomerBankAccountCodeSalesOrder()
    var
        SalesOrder: TestPage "Sales Order";
        CustomerBankAccountCode: Code[10];
        CustomerNo: Code[20];
    begin
        // Purpose of the test is to validate Bank Account Code on Sales Order with Customer No.
        // Setup: Create Sales Order and CreateCustomer Bank Account Card by Page.
        OpenSalesOrder(SalesOrder);
        CustomerNo := CreateCustomer();
        SalesOrder."Sell-to Customer Name".SetValue(CustomerNo);  // COMMIT have been used on OnValidate of "Sell-to Customer No." field on  Page 42 - Sales Order.
        CustomerBankAccountCode := CreateCustomerBankAccountByPage(CustomerNo);

        // Exercise: Lookup through CustomerBankAccountListPageHandler on Sales Order Page.
        SalesOrder."Bank Account Code".Lookup();

        // Verify: Verify Bank Account Code on Sales Page.
        SalesOrder."Bank Account Code".AssertEquals(CustomerBankAccountCode);
        SalesOrder.Close();
    end;

    [Test]
    [HandlerFunctions('CustomerBankAccountListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnLookupCustomerBankAccountCodeSalesReturnOrder()
    var
        SalesReturnOrder: TestPage "Sales Return Order";
        CustomerBankAccountCode: Code[10];
        CustomerNo: Code[20];
    begin
        // Purpose of the test is to validate Bank Account Code on Sales Return Order with Customer No.
        // Setup: Create Sales Return Order and CreateCustomer Bank Account Card by Page.
        OpenSalesReturnOrder(SalesReturnOrder);
        CustomerNo := CreateCustomer();
        SalesReturnOrder."Sell-to Customer Name".SetValue(CustomerNo);
        CustomerBankAccountCode := CreateCustomerBankAccountByPage(CustomerNo);

        // Exercise: Lookup through CustomerBankAccountListPageHandler on Sales Return Order Page.
        SalesReturnOrder."Bank Account Code".Lookup();

        // Verify: Verify Bank Account Code on Sales Return Order Page.
        SalesReturnOrder."Bank Account Code".AssertEquals(CustomerBankAccountCode);
        SalesReturnOrder.Close();
    end;

    [Test]
    [HandlerFunctions('CustomerBankAccountListPageHandler')]
    [Scope('OnPrem')]
    procedure OnLookupCustomerBankAccountCodeSalesInvoice()
    var
        SalesInvoice: TestPage "Sales Invoice";
        CustomerBankAccountCode: Code[10];
        CustomerNo: Code[20];
    begin
        // Purpose of the test is to validate Bank Account Code on Sales Invoice with Customer No.
        // Setup: Create Sales Invoice and CreateCustomer Bank Account Card by Page.
        OpenSalesInvoice(SalesInvoice);
        CustomerNo := CreateCustomer();
        SalesInvoice."Sell-to Customer Name".SetValue(CustomerNo);  // COMMIT have been used on OnValidate of "Sell-to Customer No." field on  Page 43 - Sales Invoice.
        CustomerBankAccountCode := CreateCustomerBankAccountByPage(CustomerNo);

        // Exercise: Lookup through CustomerBankAccountListPageHandler on Sales invoice Page.
        SalesInvoice."Bank Account Code".Lookup();

        // Verify: Verify Bank Account Code on Sales Invoice Page.
        SalesInvoice."Bank Account Code".AssertEquals(CustomerBankAccountCode);
        SalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('CustomerBankAccountListPageHandler')]
    [Scope('OnPrem')]
    procedure OnLookupCustomerBankAccountCodeSalesCreditMemo()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CustomerBankAccountCode: Code[10];
        CustomerNo: Code[20];
    begin
        // Purpose of the test is to validate Bank Account Code on Sales Credit Memo with Customer No.
        // Setup: Create Sales Credit Memo and CreateCustomer Bank Account Card by Page.
        OpenSalesCreditMemo(SalesCreditMemo);
        CustomerNo := CreateCustomer();
        SalesCreditMemo."Sell-to Customer Name".SetValue(CustomerNo);  // COMMIT have been used on OnValidate of "Sell-to Customer No." field on Page 44 - Sales Cr. Memo.
        CustomerBankAccountCode := CreateCustomerBankAccountByPage(CustomerNo);

        // Exercise: Lookup through CustomerBankAccountListPageHandler on Sales Credit Memo Page.
        SalesCreditMemo."Bank Account Code".Lookup();

        // Verify: Verify Bank Account Code on Sales Credit Memo Page.
        SalesCreditMemo."Bank Account Code".AssertEquals(CustomerBankAccountCode);
        SalesCreditMemo.Close();
    end;

    [Test]
    [HandlerFunctions('TelebankProposalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDrillDownProposalTelebankBankOverview()
    var
        TelebankBankOverview: TestPage "Telebank - Bank Overview";
    begin
        // Purpose of the test is to validate Proposal field on Telebank - Bank Overview page ID - 11000000.
        // Setup: Open Telebank Bank Overview page.
        OpenTelebankOverview(TelebankBankOverview, CreateBankAccount());
        LibraryVariableStorage.Enqueue(TelebankBankOverview."No.".Value);

        // Exercise: Drilldown Proposal field.
        TelebankBankOverview.Proposal.DrillDown();  // Using TelebankProposalPageHandler.

        // Verify: Verification done by TelebankProposalPageHandler, Telebank Proposal page open successfully.
        TelebankBankOverview.Close();
    end;

    [Test]
    [HandlerFunctions('ContactListPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionContactTelebankBankOverview()
    var
        TelebankBankOverview: TestPage "Telebank - Bank Overview";
    begin
        // Purpose of the test is to validate page action Contact on Telebank - Bank Overview page ID - 11000000.
        // Setup: Open Telebank Bank Overview page.
        TelebankBankOverview.OpenEdit();

        // Exercise: Drilldown Proposal field, COMMIT have been used in this action, function ShowContact in Table ID 270 - Bank Account.
        TelebankBankOverview.Contact.Invoke();  // Using ContactListPageHandler.

        // Verify: Verification done by ContactListPageHandler, Contact List page open successfully.
        TelebankBankOverview.Close();
    end;

    [Test]
    [HandlerFunctions('TelebankProposalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionProposalTelebankBankOverview()
    var
        TelebankBankOverview: TestPage "Telebank - Bank Overview";
    begin
        // Purpose of the test is to validate page action Proposal on Telebank - Bank Overview page ID - 11000000.
        // Setup: Open Telebank Bank Overview page.
        OpenTelebankOverview(TelebankBankOverview, CreateBankAccount());
        LibraryVariableStorage.Enqueue(TelebankBankOverview."No.".Value);

        // Exercise: Call action Proposal on Telebank overview page.
        TelebankBankOverview.Proposal_Navigate.Invoke();  // Using TelebankProposalPageHandler.

        // Verify: Verification done by TelebankProposalPageHandler, Telebank Proposal page open successfully.
        TelebankBankOverview.Close();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionGetProposalEntriesTelebankBankOverview()
    var
        TelebankBankOverview: TestPage "Telebank - Bank Overview";
    begin
        // Purpose of the test is to validate page action Get Proposal Entries on Telebank - Bank Overview page ID - 11000000.
        // Setup: Open Telebank Bank Overview page.
        TelebankBankOverview.OpenEdit();

        // Exercise: Call action Get Proposal Entries on Telebank overview page.
        TelebankBankOverview.GetProposalEntries.Invoke();  // Using GetProposalEntriesRequestPageHandler.

        // Verify: Verification done by GetProposalEntriesRequestPageHandler, report Get Proposal Entries request Page open successfully.
        TelebankBankOverview.Close();
    end;

    [Test]
    [HandlerFunctions('ProposalOverviewRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionProposalOverviewTelebankBankOverview()
    var
        TelebankBankOverview: TestPage "Telebank - Bank Overview";
    begin
        // Purpose of the test is to validate page action Proposal Overview on Telebank - Bank Overview page ID - 11000000.
        // Setup: Open Telebank Bank Overview page.
        TelebankBankOverview.OpenEdit();

        // Exercise: Call action Proposal Overview on Telebank overview page.
        TelebankBankOverview.ProposalOverview.Invoke();  // Using ProposalOverviewRequestPageHandler.

        // Verify: Verification done by ProposalOverviewRequestPageHandler, report Proposal Overview request page open successfully.
        TelebankBankOverview.Close();
    end;

    [Test]
    [HandlerFunctions('PaymentHistoryOverviewRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionPaymentHistoryOverviewTelebankBankOverview()
    var
        TelebankBankOverview: TestPage "Telebank - Bank Overview";
    begin
        // Purpose of the test is to validate page action Payment History Overview on Telebank - Bank Overview page ID - 11000000.
        // Setup: Open Telebank Bank Overview page.
        TelebankBankOverview.OpenEdit();

        // Exercise: Call action Payment History Overview on Telebank overview page.
        TelebankBankOverview.PaymentHistoryOverview.Invoke();  // Using PaymentHistoryOverviewRequestPageHandler.

        // Verify: Verification done by PaymentHistoryOverviewRequestPageHandler, report Payment History Overview request page open successfully.
        TelebankBankOverview.Close();
    end;

    [Test]
    [HandlerFunctions('DefaultDimensionsMultiplePageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionDefaultDimensionMultipleTelebankBankOverview()
    var
        TelebankBankOverview: TestPage "Telebank - Bank Overview";
    begin
        // Purpose of the test is to validate page action Page DimensionsMultiple Overview on Telebank - Bank Overview page ID - 11000000.
        // Setup: Open Telebank Bank Overview page.
        OpenTelebankOverview(TelebankBankOverview, CreateBankAccount());
        LibraryVariableStorage.Enqueue(CreateDefaultDimension(DATABASE::"Bank Account", TelebankBankOverview."No.".Value));

        // Exercise: Call action Dimension on Telebank overview page.
        TelebankBankOverview.DimensionsMultiple.Invoke();  // Using DefaultDimensionsMultiplePageHandler.

        // Verify: Verification done by DefaultDimensionsMultiplePageHandler.
        TelebankBankOverview.Close();
    end;

    [Test]
    [HandlerFunctions('EditDimensionSetEntriesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionHeaderDimensionTelebankProposal()
    var
        Customer: Record Customer;
        ProposalLine: Record "Proposal Line";
        TelebankProposal: TestPage "Telebank Proposal";
        GlobalDimension1Value: Code[20];
        GlobalDimension2Value: Code[20];
    begin
        // [FEATURE] [Dimensions]
        // [SCENARIO 270714] Telebank Proposal does not change global dimensions in proposal line after Header Dimensions opened
        // [GIVEN] Proposal Line with global dimensions "Dim1" and "Dim2"
        Customer.Get(CreateCustomer());
        CreateProposalLineWithBank(
          ProposalLine."Account Type"::Customer, Customer."No.", Customer."Transaction Mode Code", CreateBankAccount());
        GlobalDimension1Value := LibraryUTUtility.GetNewCode();
        GlobalDimension2Value := LibraryUTUtility.GetNewCode();

        ProposalLine.SetRange("Account No.", Customer."No.");
        ProposalLine.FindFirst();
        ProposalLine."Shortcut Dimension 1 Code" := GlobalDimension1Value;
        ProposalLine."Shortcut Dimension 2 Code" := GlobalDimension2Value;
        ProposalLine.Modify();

        // [GIVEN] Telebank Proposal page with the proposal line
        TelebankProposal.OpenView();
        TelebankProposal.BankAccFilter.SetValue(ProposalLine."Our Bank No.");
        TelebankProposal.GotoRecord(ProposalLine);

        // [WHEN] Call action Proposal/Dimension on Telebank Proposal page
        TelebankProposal.HeaderDimensions.Invoke(); // EditDimensionSetEntriesPageHandler
        TelebankProposal.Close();

        // [THEN] Shortcut Dimensions 1 and 2 still equal to "Dim1" and "Dim2" respectively
        ProposalLine.Find();
        ProposalLine.TestField("Shortcut Dimension 1 Code", GlobalDimension1Value);
        ProposalLine.TestField("Shortcut Dimension 2 Code", GlobalDimension2Value);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePercentProposalDetailLine()
    var
        ProposalDetailLine: TestPage "Proposal Detail Line";
        Percentage: Decimal;
    begin
        // Purpose of the test is to validate Percentage Amount field on Proposal Detail Line page ID - 11000002.
        // Setup: Open Proposal Detail Line page.
        ProposalDetailLine.OpenEdit();
        Percentage := LibraryRandom.RandDec(100, 2);  // Using Random for Percentage.

        // Exercise: Validate Percentage Amount field on Proposal Detail Line page.
        ProposalDetailLine.Control2.PercentageAmount.SetValue(Percentage);

        // Verify: Verify Percent Amount field on Proposal Detail Line page.
        ProposalDetailLine.Control2.PercentageAmount.AssertEquals(Percentage);
        ProposalDetailLine.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionCheckProposalDetailLine()
    var
        ProposalDetailLine: TestPage "Proposal Detail Line";
    begin
        // Purpose of the test is to validate action Check on Proposal Detail Line page ID - 11000002.
        // Setup: Open Proposal Detail Line page.
        ProposalDetailLine.OpenEdit();

        // Exercise: Validate action Check on Proposal Detail Line page.
        ProposalDetailLine.Check.Invoke();  // Using MessageHandler.

        // Verify: Verification done by MessageHandler, Check action call successfully.
        ProposalDetailLine.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionProcessProposalDetailLine()
    var
        ProposalDetailLine: TestPage "Proposal Detail Line";
    begin
        // Purpose of the test is to validate action Process on Proposal Detail Line page ID - 11000002.
        // Setup: Open Proposal Detail Line page.
        ProposalDetailLine.OpenEdit();

        // Exercise: Validate action Process on Proposal Detail Line page.
        ProposalDetailLine.Process.Invoke();

        // Verify: Verification done by MessageHandler & ConfirmHandler, process action call successfully.
    end;

    [Test]
    [HandlerFunctions('BankAccountListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionToOtherBankProposalDetailLine()
    var
        ProposalDetailLine: TestPage "Proposal Detail Line";
    begin
        // Purpose of the test is to validate action To Other Bank on Proposal Detail Line page - ID 11000002.
        // Setup: Open Proposal Detail Line page.
        ProposalDetailLine.OpenEdit();
        ProposalDetailLine.FILTER.SetFilter("Our Bank No.", CreateBankAccount());

        // Exercise: Validate action To Other Bank on Proposal Detail Line page.
        ProposalDetailLine.ToOtherBank.Invoke();

        // Verify: Verification done by BankAccountListPageHandler, Bank Account List page open successfully.
        ProposalDetailLine.Close();
    end;

    [Test]
    [HandlerFunctions('CustomerLedgerEntriesModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionUpdateDescriptionsCustomerProposalDetailLine()
    var
        Customer: Record Customer;
        ProposalLine: Record "Proposal Line";
    begin
        // Purpose of the test is to validate action Update Descriptions for Customer on Proposal Detail Line page ID - 11000002.
        // Setup.
        Customer.Get(CreateCustomer());

        // Exercise and Verify.
        UpdateDescriptionsProposalDetailLine(
          ProposalLine."Account Type"::Customer, Customer."No.", Customer."Transaction Mode Code",
          CreateCustomerLedgerEntry(Customer."No."));
    end;

    [Test]
    [HandlerFunctions('VendorLedgerEntriesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionUpdateDescriptionsVendorProposalDetailLine()
    var
        ProposalLine: Record "Proposal Line";
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate action Update Descriptions for Vendor on Proposal Detail Line page ID - 11000002.
        // Setup.
        Vendor.Get(CreateVendor());

        // Exercise and Verify.
        UpdateDescriptionsProposalDetailLine(
          ProposalLine."Account Type"::Vendor, Vendor."No.", Vendor."Transaction Mode Code", CreateVendorLedgerEntry(Vendor."No."));
    end;

    [Test]
    [HandlerFunctions('EmployeeLedgerEntriesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionUpdateDescriptionsEmployeeProposalDetailLine()
    var
        ProposalLine: Record "Proposal Line";
        Employee: Record Employee;
    begin
        // Purpose of the test is to validate action Update Descriptions for Employee on Proposal Detail Line page ID - 11000002.
        // Setup.
        Employee.Get(CreateEmployee());

        // Exercise and Verify.
        UpdateDescriptionsProposalDetailLine(
          ProposalLine."Account Type"::Employee, Employee."No.", Employee."Transaction Mode Code",
          CreateEmployeeLedgerEntry(Employee."No."));
    end;

    [TransactionModel(TransactionModel::AutoRollback)]
    local procedure UpdateDescriptionsProposalDetailLine(AccountType: Option; AccountNo: Code[20]; TransactionModeCode: Code[20]; DocumentNo: Code[20])
    var
        ProposalDetailLine: TestPage "Proposal Detail Line";
    begin
        // Create Vendor and Vendor Ledger Entry, open Proposal Deatail Line.
        OpenProposalDetailLine(ProposalDetailLine, AccountType, AccountNo, TransactionModeCode);  // Using VendorLedgerEntriesPageHandler.

        // Exercise: Call action Update Description on Proposal Deatail Line page.
        ProposalDetailLine.UpdateDescriptions.Invoke();

        // Verify: Verify Description field value on Proposal Detail Line subform page.
        ProposalDetailLine."Description 1".AssertEquals('Invoice ' + DocumentNo);
        ProposalDetailLine.Close();
    end;

    [Test]
    [HandlerFunctions('DimensionSetEntriesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionDimensionsPaymentHistoryLine()
    var
        PaymentHistoryCard: TestPage "Payment History Card";
    begin
        // Purpose of the test is to validate action Dimensions on Payment History Line Subform page ID - 11000008.
        // Setup: Open Payment History Card page.
        PaymentHistoryCard.OpenEdit();

        // Exercise: Call action Dimensions on Payment History Card page.
        PaymentHistoryCard.Subform.Dimension.Invoke();  // Using DimensionSetEntriesPageHandler.

        // Verify: Verification done by DimensionSetEntriesPageHandler, Dimension Set Entries page open successfully.
        PaymentHistoryCard.Close();
    end;

    [Test]
    [HandlerFunctions('CustomerLedgerEntriesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionLedgerEntriesPaymentHistoryLine()
    var
        PaymentHistoryCard: TestPage "Payment History Card";
    begin
        // Purpose of the test is to validate action Ledger Entries on Payment History Line Subform page ID - 11000008.
        // Setup: Open Payment History Card page.
        PaymentHistoryCard.OpenEdit();

        // Exercise: Call action Ledger Entries on Payment History Card page.
        PaymentHistoryCard.Subform.LedgerEntries.Invoke(); // Using CustomerLedgerEntriesPageHandler.

        // Verify: Verification done by GeneralLedgerEntriesPageHandler, General Ledger Entries page open successfully.
        PaymentHistoryCard.Close();
    end;

    [Test]
    [HandlerFunctions('PaymentHistoryLineDetailPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionDetailInformationPaymentHistoryLine()
    var
        PaymentHistoryCard: TestPage "Payment History Card";
    begin
        // Purpose of the test is to validate action Detail Infromation on Payment History Line Subform page ID - 11000008.
        // Setup: Open Payment History Card page.
        PaymentHistoryCard.OpenEdit();

        // Exercise: Call action Detail Infromation on Payment History Card page.
        PaymentHistoryCard.Subform.DetailInformation.Invoke();  // Using PaymentHistoryLineDetailPageHandler.

        // Verify: Verification done by PaymentHistoryLineDetailPageHandler, Detail Information page open successfully.
        PaymentHistoryCard.Close();
    end;

    [Test]
    [HandlerFunctions('ImportProtocolsPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionModifyImportProtocols()
    var
        ImportProtocolList: TestPage "Import Protocol List";
    begin
        // Purpose of the test is to validate action Modify on ImportProtocol List page ID - 11000016.
        // Setup: Open Import Protocol List page.
        ImportProtocolList.OpenEdit();
        ImportProtocolList.FILTER.SetFilter(Code, CreateImportProtocol());
        LibraryVariableStorage.Enqueue(ImportProtocolList.Code.Value);

        // Exercise: Call action Modify on Import Protocol List page.
        ImportProtocolList.Modify.Invoke();  // Using ImportProtocolsPageHandler.

        // Verify: Verification done by ImportProtocolsPageHandler, Import Protocol List page open in edit mode successfully.
        ImportProtocolList.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnOpenPageBankAccountCard()
    var
        BankAccountCard: TestPage "Bank Account Card";
        No: Code[20];
    begin
        // Purpose of the test is to validate Bank Account Code On Open Page - 370 Bank Account Card.

        // Setup.
        No := CreateBankAccount();
        BankAccountCard.OpenEdit();

        // Exercise.
        BankAccountCard.FILTER.SetFilter("No.", No);

        // Verify.
        BankAccountCard."No.".AssertEquals(No);

        // Teardown.
        BankAccountCard.Close();
    end;

    [Test]
    [HandlerFunctions('ObjectsPageHandler')]
    [Scope('OnPrem')]
    procedure OnLookUpForImportIDFieldOfImportProtocols()
    var
        ImportProtocols: TestPage "Import Protocols";
    begin
        // [FEATURE] [Import Protocol]
        // [SCENARIO 202689] Look Up on "Import ID" field of Import Protocol should open Object page
        ImportProtocols.OpenNew();
        ImportProtocols."Import ID".Lookup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnDrillDownForImportIDFieldOfImportProtocols()
    var
        ImportProtocols: TestPage "Import Protocols";
        Objects: TestPage Objects;
    begin
        // [FEATURE] [Import Protocol]
        // [SCENARIO 202689] Drill Down on "Import ID" field of Import Protocol should open Object page
        Objects.Trap();
        ImportProtocols.OpenEdit();
        ImportProtocols."Import ID".DrillDown();
        Objects.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TelebankProposalRetrievesBankAccountOnceAfterPageIsOpened()
    var
        BankAccount: Record "Bank Account";
        ProposalLine: Record "Proposal Line";
        Vendor: Record Vendor;
        CodeCoverage: Record "Code Coverage";
        TelebankBankOverview: TestPage "Telebank - Bank Overview";
        TelebankProposal: TestPage "Telebank Proposal";
        i: Integer;
    begin
        // [FEATURE] [Proposal Line] [Performance]
        // [SCENARIO 281948] BankAccount is not updated for every record on the page
        CodeCoverageMgt.StopApplicationCoverage();

        Vendor.Get(CreateVendor());
        LibraryERM.CreateBankAccount(BankAccount);
        for i := 1 to LibraryRandom.RandIntInRange(10, 20) do
            CreateProposalLineWithBank(ProposalLine."Account Type"::Vendor, Vendor."No.", Vendor."Transaction Mode Code", BankAccount."No.");

        OpenTelebankOverview(TelebankBankOverview, BankAccount."No.");

        CodeCoverageMgt.StartApplicationCoverage();
        TelebankProposal.Trap();
        TelebankBankOverview.Proposal_Navigate.Invoke();
        CodeCoverageMgt.StopApplicationCoverage();

        TelebankProposal.Close();

        Assert.AreEqual(
          1, CodeCoverageMgt.GetNoOfHitsCoverageForObject(
              CodeCoverage."Object Type"::Page, PAGE::"Telebank Proposal", 'BankAccount.GET'), 'Unnecessary BankAccount.GET found');
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        TransactionMode: Record "Transaction Mode";
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Name := LibraryUTUtility.GetNewCode();
        Customer."Payment Terms Code" := CreatePaymentTerms();
        Customer."Gen. Bus. Posting Group" := LibraryUTUtility.GetNewCode10();
        Customer."Customer Posting Group" := LibraryUTUtility.GetNewCode10();
        Customer."Transaction Mode Code" := CreateTransactionMode(TransactionMode."Account Type"::Customer);
        Customer.Insert(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerBankAccount(CustomerNo: Code[20]): Code[10]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount."Customer No." := CustomerNo;
        CustomerBankAccount.Code := LibraryUTUtility.GetNewCode10();
        CustomerBankAccount.Insert();
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateCustomerBankAccountInsertTrue(CustomerNo: Code[20]): Code[10]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount."Customer No." := CustomerNo;
        CustomerBankAccount.Code := LibraryUTUtility.GetNewCode10();
        CustomerBankAccount.Insert(true);  // TRUE is required for test the code on OnInsert Trigger.
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateCustomerBankAccountByPage(CustomerNo: Code[20]): Code[10]
    var
        CustomerBankAccountCard: TestPage "Customer Bank Account Card";
    begin
        CustomerBankAccountCard.OpenEdit();
        CustomerBankAccountCard.FILTER.SetFilter(Code, CreateCustomerBankAccount(CustomerNo));
        exit(CustomerBankAccountCard.Code.Value);
    end;

    local procedure CreateCustomerLedgerEntry(CustomerNo: Code[20]): Code[20]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry."Entry No." := 1;
        if CustLedgerEntry2.FindLast() then
            CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        CustLedgerEntry.Amount := LibraryRandom.RandDec(100, 2);  // Using Random for Amount.
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();
        exit(CustLedgerEntry."Document No.");
    end;

    local procedure CreateDefaultDimension(TableID: Integer; No: Code[20]): Code[20]
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.FindFirst();
        DefaultDimension."Table ID" := TableID;
        DefaultDimension."No." := No;
        DefaultDimension."Dimension Code" := DimensionValue."Dimension Code";
        DefaultDimension."Dimension Value Code" := DimensionValue.Code;
        DefaultDimension.Insert();
        exit(DefaultDimension."Dimension Code");
    end;

    local procedure CreateImportProtocol(): Code[20]
    var
        ImportProtocol: Record "Import Protocol";
    begin
        ImportProtocol.Code := LibraryUTUtility.GetNewCode();
        ImportProtocol.Insert();
        exit(ImportProtocol.Code);
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Code := LibraryUTUtility.GetNewCode10();
        PaymentTerms.Insert();
        exit(PaymentTerms.Code);
    end;

    local procedure CreateProposalLine(AccountType: Option; AccountNo: Code[20]; TransactionMode: Code[20])
    begin
        CreateProposalLineWithBank(AccountType, AccountNo, TransactionMode, '');
    end;

    local procedure CreateProposalLineWithBank(AccountType: Option; AccountNo: Code[20]; TransactionMode: Code[20]; BankAccountNo: Code[20])
    var
        ProposalLine: Record "Proposal Line";
    begin
        ProposalLine."Our Bank No." := BankAccountNo;
        ProposalLine."Line No." := LibraryUtility.GetNewRecNo(ProposalLine, ProposalLine.FieldNo("Line No."));
        ProposalLine."Account Type" := AccountType;
        ProposalLine."Account No." := AccountNo;
        ProposalLine."Transaction Date" := WorkDate();
        ProposalLine."Transaction Mode" := TransactionMode;
        ProposalLine.Insert();
    end;

    local procedure CreatePurchaseDocument(DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader.Insert();
        exit(PurchaseHeader."No.")
    end;

    local procedure CreateSalesDocument(DocumentType: Enum "Sales Document Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader.Insert();
        exit(SalesHeader."No.")
    end;

    local procedure CreateTransactionMode(AccountType: Option): Code[20]
    var
        TransactionMode: Record "Transaction Mode";
    begin
        TransactionMode."Account Type" := AccountType;
        TransactionMode.Code := LibraryUTUtility.GetNewCode();
        TransactionMode.Insert();
        exit(TransactionMode.Code);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        TransactionMode: Record "Transaction Mode";
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Name := LibraryUTUtility.GetNewCode();
        Vendor."Gen. Bus. Posting Group" := LibraryUTUtility.GetNewCode10();
        Vendor."Vendor Posting Group" := LibraryUTUtility.GetNewCode10();
        Vendor."Transaction Mode Code" := CreateTransactionMode(TransactionMode."Account Type"::Vendor);
        Vendor.Insert(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBankAccount(VendorNo: Code[20]): Code[10]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount."Vendor No." := VendorNo;
        VendorBankAccount.Code := LibraryUTUtility.GetNewCode10();
        VendorBankAccount.Insert();
        exit(VendorBankAccount.Code);
    end;

    local procedure CreateVendorBankAccountInsertTrue(VendorNo: Code[20]): Code[10]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount."Vendor No." := VendorNo;
        VendorBankAccount.Code := LibraryUTUtility.GetNewCode10();
        VendorBankAccount.Insert(true);  // TRUE is required for test the code on OnInsert Trigger.
        exit(VendorBankAccount.Code);
    end;

    local procedure CreateVendorBankAccountByPage(VendorNo: Code[20]): Code[10]
    var
        VendorBankAccountCard: TestPage "Vendor Bank Account Card";
    begin
        VendorBankAccountCard.OpenEdit();
        VendorBankAccountCard.FILTER.SetFilter(Code, CreateVendorBankAccount(VendorNo));
        exit(VendorBankAccountCard.Code.Value);
    end;

    local procedure CreateVendorLedgerEntry(VendorNo: Code[20]): Code[20]
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry."Entry No." := 1;
        if VendorLedgerEntry2.FindLast() then
            VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        VendorLedgerEntry.Amount := -LibraryRandom.RandDec(100, 2);  // Using Random for Amount.
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry."External Document No." := VendorLedgerEntry."Document No.";
        VendorLedgerEntry.Description := VendorLedgerEntry."Document No.";
        VendorLedgerEntry.Insert();
        exit(VendorLedgerEntry."Document No.");
    end;

    local procedure CreateEmployee(): Code[20]
    var
        Employee: Record Employee;
        TransactionMode: Record "Transaction Mode";
    begin
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        Employee."Transaction Mode Code" := CreateTransactionMode(TransactionMode."Account Type"::Employee);
        Employee.Modify(true);
        exit(Employee."No.");
    end;

    local procedure CreateEmployeeLedgerEntry(EmployeeNo: Code[20]): Code[20]
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        EmployeeLedgerEntry2: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry."Entry No." := 1;
        if EmployeeLedgerEntry2.FindLast() then
            EmployeeLedgerEntry."Entry No." := EmployeeLedgerEntry2."Entry No." + 1;
        EmployeeLedgerEntry."Document Type" := EmployeeLedgerEntry."Document Type"::Invoice;
        EmployeeLedgerEntry."Employee No." := EmployeeNo;
        EmployeeLedgerEntry."Posting Date" := WorkDate();
        EmployeeLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        EmployeeLedgerEntry.Amount := -LibraryRandom.RandDec(100, 2);  // Using Random for Amount.
        EmployeeLedgerEntry.Open := true;
        EmployeeLedgerEntry.Description := EmployeeLedgerEntry."Document No.";
        EmployeeLedgerEntry.Insert();
        exit(EmployeeLedgerEntry."Document No.");
    end;

    local procedure OpenProposalDetailLine(var ProposalDetailLine: TestPage "Proposal Detail Line"; AccountType: Option; AccountNo: Code[20]; TransactionMode: Code[20])
    begin
        CreateProposalLine(AccountType, AccountNo, TransactionMode);
        ProposalDetailLine.OpenEdit();
        ProposalDetailLine.FILTER.SetFilter("Account No.", AccountNo);
        ProposalDetailLine.Control2."Serial No. (Entry)".Lookup();
    end;

    local procedure OpenPurchaseCreditMemo(var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", CreatePurchaseDocument(PurchaseHeader."Document Type"::"Credit Memo"));
    end;

    local procedure OpenPurchaseInvoice(var PurchaseInvoice: TestPage "Purchase Invoice")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", CreatePurchaseDocument(PurchaseHeader."Document Type"::Invoice));
    end;

    local procedure OpenPurchaseOrder(var PurchaseOrder: TestPage "Purchase Order")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", CreatePurchaseDocument(PurchaseHeader."Document Type"::Order));
    end;

    local procedure OpenPurchaseQuote(var PurchaseQuote: TestPage "Purchase Quote")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseQuote.OpenEdit();
        PurchaseQuote.FILTER.SetFilter("No.", CreatePurchaseDocument(PurchaseHeader."Document Type"::Quote));
    end;

    local procedure OpenPurchaseReturnOrder(var PurchaseReturnOrder: TestPage "Purchase Return Order")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", CreatePurchaseDocument(PurchaseHeader."Document Type"::"Return Order"));
    end;

    local procedure OpenSalesCreditMemo(var SalesCreditMemo: TestPage "Sales Credit Memo")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", CreateSalesDocument(SalesHeader."Document Type"::"Credit Memo"));
    end;

    local procedure OpenSalesInvoice(var SalesInvoice: TestPage "Sales Invoice")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", CreateSalesDocument(SalesHeader."Document Type"::Invoice));
    end;

    local procedure OpenSalesOrder(var SalesOrder: TestPage "Sales Order")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", CreateSalesDocument(SalesHeader."Document Type"::Order));
    end;

    local procedure OpenSalesQuote(var SalesQuote: TestPage "Sales Quote")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesQuote.OpenEdit();
        SalesQuote.FILTER.SetFilter("No.", CreateSalesDocument(SalesHeader."Document Type"::Quote));
    end;

    local procedure OpenSalesReturnOrder(var SalesReturnOrder: TestPage "Sales Return Order")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", CreateSalesDocument(SalesHeader."Document Type"::"Return Order"));
    end;

    local procedure OpenTelebankOverview(var TelebankBankOverview: TestPage "Telebank - Bank Overview"; No: Code[20])
    begin
        TelebankBankOverview.OpenEdit();
        TelebankBankOverview.FILTER.SetFilter("No.", No);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountListPageHandler(var BankAccountList: TestPage "Bank Account List")
    begin
        BankAccountList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ContactListPageHandler(var ContactList: TestPage "Contact List")
    begin
        ContactList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerBankAccountListPageHandler(var CustomerBankAccountList: TestPage "Customer Bank Account List")
    begin
        CustomerBankAccountList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntriesModalPageHandler(var CustomerLedgerEntries: TestPage "Customer Ledger Entries")
    begin
        CustomerLedgerEntries.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntriesPageHandler(var CustomerLedgerEntries: TestPage "Customer Ledger Entries")
    begin
        CustomerLedgerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DefaultDimensionsMultiplePageHandler(var DefaultDimensionsMultiple: TestPage "Default Dimensions-Multiple")
    var
        DimensionCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimensionCode);
        DefaultDimensionsMultiple."Dimension Code".AssertEquals(DimensionCode);
        DefaultDimensionsMultiple.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSetEntriesPageHandler(var DimensionSetEntries: TestPage "Dimension Set Entries")
    begin
        DimensionSetEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditDimensionSetEntriesPageHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    begin
        EditDimensionSetEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DocketRequestPageHandler(var Docket: TestRequestPage Docket)
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportBTL91ABNAMRORequestPageHandler(var ExportBTL91ABNAMRO: TestRequestPage "Export BTL91-ABN AMRO")
    begin
        ExportBTL91ABNAMRO.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ExportMessageHandler(Message: Text[1024])
    begin
        if (StrPos(Message, ExportProtocolMsg) = 0) and (StrPos(Message, ExportProtocol2Msg) = 0) then
            Error(UnexpectedMsg);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetProposalEntriesRequestPageHandler(var GetProposalEntries: TestRequestPage "Get Proposal Entries")
    begin
        GetProposalEntries.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerCardPageHandler(var CustomerCard: TestPage "Customer Card")
    begin
        CustomerCard.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ExportXMLPortMessageHandler(Message: Text[1024])
    var
        GenJnlLine: Record "Gen. Journal Line";
        BankNo: Variant;
        RunNo: Variant;
    begin
        // Verify: "Document No." and "Bal. Account No." must have filters.
        LibraryVariableStorage.Dequeue(BankNo);
        LibraryVariableStorage.Dequeue(RunNo);
        Assert.AreEqual(
          StrSubstNo(
            'XMLPort144055 [%1: %2, %3: %4, %5: %6, %7: %8]',
            GenJnlLine.FieldCaption("Journal Template Name"), '''''', GenJnlLine.FieldCaption("Journal Batch Name"), '''''',
            GenJnlLine.FieldCaption("Document No."), RunNo, GenJnlLine.FieldCaption("Bal. Account No."), BankNo),
          Message, '');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ImportProtocolsPageHandler(var ImportProtocols: TestPage "Import Protocols")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        ImportProtocols.Code.AssertEquals(Code);
        ImportProtocols.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ObjectListHandler(var ObjectsList: TestPage Objects)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ObjectType: Variant;
    begin
        LibraryVariableStorage.Dequeue(ObjectType);
        AllObjWithCaption.SetRange("Object Type", ObjectType);
        AllObjWithCaption.FindLast();
        ObjectsList.GotoRecord(AllObjWithCaption);
        ObjectsList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentHistoryCardModalPageHandler(var PaymentHistoryCard: TestPage "Payment History Card")
    begin
        PaymentHistoryCard.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PaymentHistoryCardPageHandler(var PaymentHistoryCard: TestPage "Payment History Card")
    var
        OurBank: Variant;
    begin
        LibraryVariableStorage.Dequeue(OurBank);
        PaymentHistoryCard."Our Bank".AssertEquals(OurBank);
        PaymentHistoryCard.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PaymentHistoryLineDetailPageHandler(var PaymentHistoryLineDetail: TestPage "Payment History Line Detail")
    begin
        PaymentHistoryLineDetail.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PaymentHistoryListPageHandler(var PaymentHistoryList: TestPage "Payment History List")
    var
        OurBank: Variant;
    begin
        LibraryVariableStorage.Dequeue(OurBank);
        PaymentHistoryList."Our Bank".AssertEquals(OurBank);
        PaymentHistoryList.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PaymentHistoryOverviewRequestPageHandler(var PaymentHistoryOverview: TestRequestPage "Payment History Overview")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProposalOverviewRequestPageHandler(var ProposalOverview: TestRequestPage "Proposal Overview")
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure TelebankProposalPageHandler(var TelebankProposal: TestPage "Telebank Proposal")
    var
        Bank: Variant;
    begin
        LibraryVariableStorage.Dequeue(Bank);
        TelebankProposal.BankAccFilter.AssertEquals(Bank);
        TelebankProposal.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorBankAccountListPageHandler(var VendorBankAccountList: TestPage "Vendor Bank Account List")
    begin
        VendorBankAccountList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorLedgerEntriesPageHandler(var VendorLedgerEntries: TestPage "Vendor Ledger Entries")
    begin
        VendorLedgerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmployeeLedgerEntriesPageHandler(var EmployeeLedgerEntries: TestPage "Employee Ledger Entries")
    begin
        EmployeeLedgerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ObjectsPageHandler(var Objects: TestPage Objects)
    begin
        Objects.OK().Invoke();
    end;
}

