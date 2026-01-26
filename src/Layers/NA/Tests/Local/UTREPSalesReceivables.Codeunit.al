codeunit 142070 "UT REP Sales Receivables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Reports]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CommentTxt: Label 'It is random value to generate text greater than 60 character.';
        ProfitsCap: Label 'Profits___1_';
        SalesCap: Label 'Sales___1_';
        TotalAmountCap: Label 'TotalAmountt';
        DescriptionCap: Label 'TempSalesLineDesc';
        CommentLineTxt: Label 'Sales Invoice and Sales Retrun document to be updated from Sales Comment Line.';
        CustomerBalanceCap: Label 'Customer__Balance__LCY__';
        FilterStringCap: Label 'FilterString';
        FilterStringCustomerNoCap: Label 'FilterString2';
        ItemDescriptionCap: Label 'Item_Description';

    [Test]
    [HandlerFunctions('CustomerSalesStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerSalesStatistics()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Customer of Report 10047 - Customer Sales Statistics without Sales and Profit.

        // Setup: Create Customer Ledger Entry without Sales and Profit.
        Initialize();
        CreateCustomerLedgerEntryWithDiscount(CustLedgerEntry, CreateCustomer());
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Customer No.");  // Enqueue used for CustomerSalesStatisticsTestReqPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Customer Sales Statistics");  // Open CustomerSalesStatisticsTestReqPageHandler.

        // Verify: Verify Sales and Profit on Report Customer Sales Statistics.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SalesCap, 0);
        LibraryReportDataset.AssertElementWithValueExists(ProfitsCap, 0);
    end;

    [Test]
    [HandlerFunctions('CustomerSalesStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordUsingSalesCustomerSalesStatistics()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Customer of Report 10047 - Customer Sales Statistics with Sales and Profit.

        // Setup: Create Customer Ledger Entry with Sales and Profit.
        Initialize();
        CreateCustomerLedgerEntryWithDiscount(CustLedgerEntry, CreateCustomer());
        UpdateSalesLCYAndProfitLCYOnCustomerLedgerEntry(CustLedgerEntry);
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Customer No.");  // Enqueue used for CustomerSalesStatisticsTestReqPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Customer Sales Statistics");  // Open CustomerSalesStatisticsTestReqPageHandler.

        // Verify: Verify Sales, Profit and Invoice Discounts on Report Customer Sales Statistics.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SalesCap, CustLedgerEntry."Sales (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(ProfitsCap, CustLedgerEntry."Profit (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('InvoiceDiscounts___1_', CustLedgerEntry."Inv. Discount (LCY)");
    end;

    [Test]
    [HandlerFunctions('CashAppliedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustLedgerEntryCashApplied()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Customer Ledger Entry of Report 10041 - Cash Applied.

        // Setup: Create Customer Ledger Entry and Detailed Customer Ledger Entry.
        Initialize();
        CreateCustomerLedgerEntryWithDiscount(CustLedgerEntry, CreateCustomer());
        CreateDetailedCustomerLedgerEntry(
          CustLedgerEntry."Entry No.", CustLedgerEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::"Payment Discount");
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Entry No.");  // Enqueue used for CashAppliedTestReqPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Cash Applied");  // Open CashAppliedTestReqPageHandler.

        // Verify: Verify Total Amount on Report Cash Applied.
        CustLedgerEntry.CalcFields("Amount (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalAmountCap, CustLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('CashAppliedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAppliedEntriesCashApplied()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        TotalAppliedAmount: Decimal;
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Applied Entries of Report 10041 - Cash Applied.

        // Setup: Create Customer Ledger Entry, Create Detailed Customer Ledger Entry for multiple Customer Ledger Entry.
        Initialize();
        CreateCustomerLedgerEntryWithDiscount(CustLedgerEntry, CreateCustomer());
        CreateDetailedCustomerLedgerEntry(
          CustLedgerEntry."Entry No.", CustLedgerEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::Application);
        CreateCustomerLedgerEntryWithDiscount(CustLedgerEntry2, CustLedgerEntry."Customer No.");
        CreateDetailedCustomerLedgerEntry(
          CustLedgerEntry."Entry No.", CustLedgerEntry2."Entry No.", DetailedCustLedgEntry."Entry Type"::"Payment Discount");
        CreateDetailedCustomerLedgerEntry(
          CustLedgerEntry2."Entry No.", CustLedgerEntry."Entry No.", DetailedCustLedgEntry."Entry Type"::Application);
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Entry No.");  // Enqueue used for CashAppliedTestReqPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Cash Applied");  // Open CashAppliedTestReqPageHandler.

        // Verify: Verify Total Amount, Total Applied, Get Total Applied and GetTotalDiscounts on Report Cash Applied.
        TotalAppliedAmount := GetAmountFromDetailCustLedgerEntry(CustLedgerEntry2."Entry No.");
        CustLedgerEntry.CalcFields("Amount (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalAmountCap, CustLedgerEntry."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('TotalApplied', -TotalAppliedAmount);
        LibraryReportDataset.AssertElementWithValueExists('GetTotalDiscounts', CustLedgerEntry2."Pmt. Disc. Given (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('GetTotalApplied', -TotalAppliedAmount);
    end;

    [Test]
    [HandlerFunctions('SalesBlanketOrderRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesLineCommentsSalesBlanketOrder()
    var
        SalesLine: Record "Sales Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Sales Line Comments of Report 10069 - Sales Blanket Order.

        // Setup: Create Sales Document with Description.
        Initialize();
        CreateSalesBlanketOrder(SalesLine);
        CreateCommentLineForBlanketSalesOrder(SalesLine."Document No.", LibraryUTUtility.GetNewCode());
        Commit();  // Commit required since explicit Commit used on OnRun Trigger of COD313: Sales-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Sales Blanket Order");  // Open SalesBlanketOrderRequestPageHandler.

        // Verify: Verify TempSalesLineDescCap on Report Sales Blanket Order.
        // Known issue
        // VerifyDataOnReport(DescriptionCap,SalesLine.Description + ' ');
    end;

    [Test]
    [HandlerFunctions('SalesBlanketOrderRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure OnPreDataItemSalesCommentLineSalesBlanketOrder()
    var
        SalesLine: Record "Sales Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Sales Comment Line of Report 10069 - Sales Blanket Order.

        // Setup: Create Sales Document and create Sales Comment Line.
        Initialize();
        CreateSalesBlanketOrder(SalesLine);
        CreateCommentLineForBlanketSalesOrder(SalesLine."Document No.", CommentTxt);  // Need a value containing more than 60 Characters.
        Commit();  // Commit required since explicit Commit used on OnRun Trigger of COD313: Sales-Printed.

        // Exercise.
        REPORT.Run(REPORT::"Sales Blanket Order");  // Open SalesBlanketOrderRequestPageHandler.

        // Verify: Verify TempSalesLineDescCap on Report Sales Blanket Order.
        VerifyDataOnReport(DescriptionCap, StrSubstNo(CommentTxt));
    end;

    [Test]
    [HandlerFunctions('VendorAccountDetailRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VendorAccountDetailReportWithMaxVendorNoLength()
    var
        VendorNo: Code[20];
    begin
        // Test and verify Vendor Account Detail report does not show any error while Vendor No. length is more than 10 Characters.

        // Setup: Create Vendor with Vendor No. length is more than 10 Characters.
        Initialize();
        VendorNo := CreateVendor();
        LibraryVariableStorage.Enqueue(VendorNo);  // Enqueue required for VendorAccountDetailRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Vendor Account Detail");  // Open VendorAccountDetailRequestPageHandler.

        // Verify: Verify Vendor No on Report Vendor Account Detail.
        VerifyDataOnReport('Vendor__No__', VendorNo);
    end;

    [Test]
    [HandlerFunctions('CustomerAccountDetailRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustLedgerEntryCustAccDetail()
    var
        CustomerNo: Code[20];
    begin
        // Purpose of the test is to validate Customer - OnAfterGetRecord trigger of Report ID - 10042.
        // Setup: Create Customer and Cust. Ledger Entry.
        Initialize();
        CustomerNo := CreateCustomerLedgerEntryWithDimension();

        // Exercise.
        REPORT.Run(REPORT::"Customer Account Detail");  // Opens CustomerAccountDetailRequestPageHandler.

        // Verify: Verify Customer after report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Customer__No__', CustomerNo);
    end;

    [Test]
    [HandlerFunctions('CustomerCommentListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCommentLineCustCommentList()
    var
        No: Code[20];
    begin
        // Purpose of the test is to validate Comment Line - OnAfterGetRecord trigger of Report ID - 10043.
        // Setup: Create Comment Line.
        Initialize();
        No := CreateCommentLine();

        // Exercise.
        REPORT.Run(REPORT::"Customer Comment List");  // Opens CustomerCommentListRequestPageHandler.

        // Verify: Verify Comment Line No. after report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Comment_Line__No__', No);
    end;

    [Test]
    [HandlerFunctions('CustomerLabelsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerCustomerLabels()
    var
        No: Code[20];
    begin
        // Purpose of the test is to validate Customer - OnAfterGetRecord trigger of Report ID - 10044.
        // Setup: Create Customer.
        Initialize();
        No := CreateCustomerWithDimension();
        LibraryVariableStorage.Enqueue(No);  // Enqueue required for CustomerLabelsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Customer Labels NA");  // Opens CustomerLabelsRequestPageHandler.

        // Verify: Verify Customer after report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Customer_No_', No);
    end;

    [Test]
    [HandlerFunctions('SalesInvoicePrePrintedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesCommentLineSalesInvPrePrinted()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCommentLine: Record "Sales Comment Line";
    begin
        // Purpose of the test is to validate Sales Invoice Line - OnAfterGetRecord trigger of Report ID - 10070.
        // Setup: Create Sales Invoice Document and Sales Comment Line.
        Initialize();
        CreatePostedSalesInvoice(SalesInvoiceLine);
        CreateSalesCommentLine(
          SalesCommentLine."Document Type"::"Posted Invoice",
          SalesInvoiceLine."Document No.", SalesInvoiceLine."Line No.", SalesInvoiceLine."Line No.");
        Commit();  // Codeunit 315 Sales Inv. Printed - On Run trigger Calls Commit();

        // Exercise.
        REPORT.Run(REPORT::"Sales Invoice (Pre-Printed)");  // Opens SalesInvoicePrePrintedRequestPageHandler.

        // Verify: Verify Sales Invoice Header No. After report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Sales_Invoice_Header___No__', SalesInvoiceLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ReturnAuthorizationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesLineCommentsReturnAuthorization()
    var
        SalesLine: Record "Sales Line";
        SalesCommentLine: Record "Sales Comment Line";
    begin
        // Purpose of the test is to validate Sales Comment Line - OnAfterGetRecord trigger of Report ID - 10081.
        // Setup: Create Sales Document and Sales Comment Line.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order");
        CreateSalesCommentLine(
          SalesCommentLine."Document Type"::"Return Order",
          SalesLine."Document No.", SalesLine."Line No.", SalesLine."Line No.");
        Commit();  // Codeunit 313 Sales Printed - On Run trigger Calls Commit();

        // Exercise.
        REPORT.Run(REPORT::"Return Authorization");  // Opens ReturnAuthorizationRequestPageHandler.

        // Verify: Verify Sales Header No. After report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Sales_Header_No_', SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ReturnReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordRetrunReceiptHeaderReturnReceipt()
    var
        No: Code[20];
    begin
        // Purpose of the test is to validate Return Receipt Header - OnAfterGetRecord trigger of Report ID - 10082.
        // Setup: Create Return Receipt.
        Initialize();
        No := CreateReturnReceipt();
        Commit();  // Codeunit 6661 Retrun Receipt Printed -  On Run trigger Calls Commit();

        // Exercise.
        REPORT.Run(REPORT::"Return Receipt");  // Opens ReturnReceiptRequestPageHandler.

        // Verify: Verify Retrun Receipt Header No. after report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_ReturnReceiptHeader', No);
    end;

    [Test]
    [HandlerFunctions('PickingListByOrderRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesHeaderPickingListByOrder()
    var
        SalesLine: Record "Sales Line";
    begin
        // Purpose of the test is to validate Sales Line - OnAfterGetRecord trigger of Report ID - 10153.
        // Setup: Create Sales Document and Sales Comment Line.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);

        // Exercise.
        REPORT.Run(REPORT::"Picking List by Order");  // Opens PickingListByOrderRequestPageHandler.

        // Verify: Verify Sales Header No. After report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Sales_Header_No_', SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('CustomerListingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemCustomerBalanceLCYCustomerListing()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Customer Trigger of Report ID - 10045 Customer Listing for Customer Balance and Customer Filter.
        // Setup.
        Initialize();
        CreateCustomerLedgerEntry(CustLedgerEntry);
        CreateDetailedCustomerLedgerEntryWithNegativeAmount(CustLedgerEntry."Entry No.", CustLedgerEntry."Customer No.");
        Customer.Get(CustLedgerEntry."Customer No.");

        // Exercise.
        REPORT.Run(REPORT::"Customer Listing");  // Open CustomerListingRequestPageHandler.

        // Verify: Verify Filters and Customer Balance is updated as Customer Balance (LCY) on Report Customer - Listing.
        Customer.CalcFields("Balance (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CustomerBalanceCap, Customer."Balance (LCY)");
    end;

    [Test]
    [HandlerFunctions('CustomerListingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemCustomerBalanceCustomerListing()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Customer Trigger of Report ID - 10045 Customer Listing for Customer Balance and Payment terms.
        // Setup.
        Initialize();
        CreatePaymentTerms(PaymentTerms);
        CreateCustomerLedgerEntry(CustLedgerEntry);
        Customer.Get(CustLedgerEntry."Customer No.");
        UpdatePaymentTermsAndSalesPersonCodeOnCustomer(Customer, PaymentTerms.Code, '');
        CreateDetailedCustomerLedgerEntryWithNegativeAmount(CustLedgerEntry."Entry No.", CustLedgerEntry."Customer No.");

        // Exercise.
        REPORT.Run(REPORT::"Customer Listing");  // Open CustomerListingPrintAmountsRequestPageHandler.

        // Verify: Verify Due Date Calculation of Payment Terms is updated on Report Customer - Listing.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'PaymentTerms__Due_Date_Calculation_', Format(PaymentTerms."Due Date Calculation"));
    end;

    [Test]
    [HandlerFunctions('CustomerItemStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportCustomerItemStatistics()
    var
        Customer: Record Customer;
        Item: Record Item;
        ValueEntry: Record "Value Entry";
    begin
        // Purpose of the test is to validate OnAfterGetrecord - ValueEntry Trigger of Report ID - 10048  Customer/Item Statistics for Filters and Item Description.
        // Setup.
        Initialize();
        CreateItem(Item);
        Customer.Get(CreateCustomer());
        CreateValueEntry(ValueEntry, Customer."No.", Item."No.");

        // Exercise.
        REPORT.Run(REPORT::"Customer/Item Statistics");  // Open CustomerItemStatisticsRequestPageHandler.

        // Verify: Verify Filters of Customer and Item Description is updated on report Customer/Item Statistics.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          FilterStringCap, StrSubstNo('%1: %2', Customer.FieldCaption("No."), Customer."No."));
        LibraryReportDataset.AssertElementWithValueExists(ItemDescriptionCap, Item.Description);
    end;

    [Test]
    [HandlerFunctions('CustomerItemStatisticsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemDescOthersCustomerItemStatistics()
    var
        ValueEntry: Record "Value Entry";
    begin
        // Purpose of the test is to validate OnAfterGetrecord - ValueEntry Trigger of Report ID - 10048  Customer/Item Statistics for Value Entry without Item.
        // Setup.
        Initialize();
        CreateValueEntry(ValueEntry, CreateCustomer(), LibraryUTUtility.GetNewCode10());

        // Exercise.
        REPORT.Run(REPORT::"Customer/Item Statistics");  // Open CustomerItemStatisticsRequestPageHandler.

        // Verify: Verify Item Description is updated on Report Customer/Item Statistics.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemDescriptionCap, 'Invalid Item');
    end;

    [Test]
    [HandlerFunctions('CustItemStatsBySalesPersRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordValueEntryCustItemStatsBySalespers()
    var
        Item: Record Item;
    begin
        // Purpose of the test is to validate OnAfterGetrecord - ValueEntry Trigger of Report ID - 10049 Customer/Item Statistics by SalesPerson for Value Entry with Item.
        // Setup.
        Initialize();
        CreateItem(Item);
        OnAfterGetRecordCustItemStatbySalespers(Item."No.", Item.Description);
    end;

    [Test]
    [HandlerFunctions('CustItemStatsBySalesPersRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDescOthersCustItemStatsBySalespers()
    begin
        // Purpose of the test is to validate OnAfterGetrecord - ValueEntry Trigger of Report ID - 10049 Customer/Item Statistics by SalesPerson for Value Entry without Item.
        // Setup.
        Initialize();
        OnAfterGetRecordCustItemStatbySalespers(LibraryUTUtility.GetNewCode10(), 'Others');  // Use random value for Item No.
    end;

    local procedure OnAfterGetRecordCustItemStatbySalespers(ItemNo: Code[20]; ItemDescription: Text[100])
    var
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        ValueEntry: Record "Value Entry";
    begin
        // Create Customer, Value Entry and Sales Invoice Header.
        Customer.Get(CreateCustomer());
        UpdatePaymentTermsAndSalesPersonCodeOnCustomer(Customer, '', CreateSalespersonPurchaser());
        CreateValueEntry(ValueEntry, Customer."No.", ItemNo);
        LibraryVariableStorage.Enqueue(Customer."Salesperson Code");  // Enqueue required for CustItemStatsBySalespersRequestPageHandler.

        // Exercise:
        REPORT.Run(REPORT::"Cust./Item Stat. by Salespers.");  // Open CustItemStatsBySalespersRequestPageHandler.

        // Verify: Verify Filters and Item Description on Report Customer/Item Stat. By Salespers.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          FilterStringCap, StrSubstNo('%1: %2', SalespersonPurchaser.FieldCaption(Code), Customer."Salesperson Code"));
        LibraryReportDataset.AssertElementWithValueExists(
          FilterStringCustomerNoCap, StrSubstNo('%1: %2', Customer.FieldCaption("No."), Customer."No."));
        LibraryReportDataset.AssertElementWithValueExists(
          'FilterString3', StrSubstNo('%1: %2', ValueEntry.FieldCaption("Source No."), ValueEntry."Source No."));
        LibraryReportDataset.AssertElementWithValueExists(ItemDescriptionCap, ItemDescription);
    end;

    [Test]
    [HandlerFunctions('CustomerRegisterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerLedgerEntryCustomerRegister()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord -  CustLedgerEntry Trigger of Report ID -10046 Customer Register.
        // Setup.
        Initialize();
        CreateCustomerLedgerEntry(CustLedgerEntry);
        CreateGLRegister(CustLedgerEntry."Entry No.");

        // Exercise.
        REPORT.Run(REPORT::"Customer Register");  // Open CustomerRegisterRequestPageHandler.

        // Verify: Verify Filters, Customer Name, Remaining Amount (LCY) and Amount (LCY) is updated on Report Customer Register.
        CustLedgerEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'FilterString2', StrSubstNo('%1: %2', CustLedgerEntry.FieldCaption("Customer No."), CustLedgerEntry."Customer No."));
        LibraryReportDataset.AssertElementWithValueExists('Cust__Ledger_Entry__Customer_No__', CustLedgerEntry."Customer No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'Cust__Ledger_Entry__Remaining_Amt___LCY__', CustLedgerEntry."Remaining Amt. (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('Cust__Ledger_Entry__Amount__LCY__', CustLedgerEntry."Amount (LCY)");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCommentLine(): Code[20]
    var
        CommentLine: Record "Comment Line";
    begin
        CommentLine."Table Name" := CommentLine."Table Name"::Customer;
        CommentLine."No." := LibraryUTUtility.GetNewCode();
        CommentLine."Line No." := LibraryRandom.RandInt(100);
        CommentLine.Comment := LibraryUTUtility.GetNewCode();
        CommentLine.Insert();
        LibraryVariableStorage.Enqueue(CommentLine."No.");  // Enqueue required for CustomerCommentListRequestPageHandler.
        exit(CommentLine."No.");
    end;

    local procedure CreateCommentLineForBlanketSalesOrder(No: Code[20]; Comment: Text[80]): Text[80]
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesCommentLine."Document Type" := SalesCommentLine."Document Type"::"Blanket Order";
        SalesCommentLine."No." := No;
        SalesCommentLine."Line No." := LibraryRandom.RandInt(10);
        SalesCommentLine.Comment := Comment;
        SalesCommentLine."Print On Order Confirmation" := true;
        SalesCommentLine.Insert();
        exit(SalesCommentLine.Comment);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CreateCustomerLedgerEntryOnDate(CustLedgerEntry, CreateCustomer(), WorkDate());
    end;

    local procedure CreateCustomerLedgerEntryOnDate(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; PostingDate: Date)
    begin
        CustLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        CustLedgerEntry."Posting Date" := PostingDate;
        CustLedgerEntry."Due Date" := PostingDate;
        CustLedgerEntry.Open := true;
        CustLedgerEntry."Sales (LCY)" := LibraryRandom.RandDec(10, 2);
        CustLedgerEntry.Insert();
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Customer No.");  // Enqueue required for OpenCustomerListingRequestPage.
    end;

    local procedure CreateCustomerLedgerEntryWithDimension(): Code[20]
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        Customer.Get(CreateCustomerWithDimension());
        CustLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Customer No." := Customer."No.";
        CustLedgerEntry."Global Dimension 1 Code" := Customer."Global Dimension 1 Code";
        CustLedgerEntry."Global Dimension 2 Code" := Customer."Global Dimension 2 Code";
        CustLedgerEntry.Insert();
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Customer No.");  // Enqueue required for CustomerLabelRequestPageHandler.
        exit(CustLedgerEntry."Customer No.");
    end;

    local procedure CreateCustomerLedgerEntryWithDiscount(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    begin
        CustLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Payment;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Inv. Discount (LCY)" := LibraryRandom.RandDec(10, 2);
        CustLedgerEntry."Pmt. Disc. Given (LCY)" := LibraryRandom.RandDec(10, 2);
        CustLedgerEntry.Insert();
    end;

    local procedure CreateCustomerWithDimension(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer."Global Dimension 1 Code" := LibraryUTUtility.GetNewCode();
        Customer."Global Dimension 2 Code" := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateDetailedCustomerLedgerEntry(CustLedgerEntryNo: Integer; AppliedCustLedgerEntryNo: Integer; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntryNo;
        DetailedCustLedgEntry."Entry Type" := EntryType;
        DetailedCustLedgEntry."Applied Cust. Ledger Entry No." := AppliedCustLedgerEntryNo;
        DetailedCustLedgEntry."Amount (LCY)" := LibraryRandom.RandDec(10, 2);
        DetailedCustLedgEntry.Insert(true);
    end;

    local procedure CreateDetailedCustomerLedgerEntryWithNegativeAmount(CustomerLedgerEntryNo: Integer; CustomerNo: Code[20])
    begin
        CreateDetailedCustomerLedgerEntryOnDate(
          CustomerLedgerEntryNo, CustomerNo, WorkDate(), -LibraryRandom.RandDec(10, 2)); // Amount less than 0 required.
    end;

    local procedure CreateDetailedCustomerLedgerEntryOnDate(CustomerLedgerEntryNo: Integer; CustomerNo: Code[20]; PostingDate: Date; EntryAmount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustomerLedgerEntryNo;
        DetailedCustLedgEntry.Amount := EntryAmount;
        DetailedCustLedgEntry."Amount (LCY)" := DetailedCustLedgEntry.Amount;
        DetailedCustLedgEntry."Posting Date" := PostingDate;
        DetailedCustLedgEntry."Customer No." := CustomerNo;
        DetailedCustLedgEntry.Insert(true);
    end;

    local procedure CreateGLRegister(FromEntryNo: Integer)
    var
        GLRegister: Record "G/L Register";
        GLRegister2: Record "G/L Register";
    begin
        GLRegister2.FindLast();
        GLRegister."No." := GLRegister2."No." + 1;
        GLRegister."From Entry No." := FromEntryNo;
        GLRegister."To Entry No." := GLRegister."From Entry No.";
        GLRegister.Insert();
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Description := Item."No.";
        Item.Insert();
    end;

    local procedure CreatePaymentTerms(var PaymentTerms: Record "Payment Terms")
    begin
        PaymentTerms.Code := LibraryUTUtility.GetNewCode10();
        Evaluate(PaymentTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        PaymentTerms."Due Date Calculation" := PaymentTerms."Due Date Calculation";
        PaymentTerms.Insert();
    end;

    local procedure CreatePostedSalesInvoice(var SalesInvoiceLine: Record "Sales Invoice Line")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader."No." := LibraryUTUtility.GetNewCode();
        SalesInvoiceHeader.Insert();
        SalesInvoiceLine."Document No." := SalesInvoiceHeader."No.";
        SalesInvoiceLine."Line No." := LibraryRandom.RandInt(100);
        SalesInvoiceLine.Description := LibraryUTUtility.GetNewCode();
        SalesInvoiceLine.Insert();
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."No.");  // Enqueue required for SalesInvoicePrePrintedRequestPageHandler.
    end;

    local procedure CreateReturnReceipt(): Code[20]
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        ReturnReceiptHeader."No." := LibraryUTUtility.GetNewCode();
        ReturnReceiptHeader.Insert();
        LibraryVariableStorage.Enqueue(ReturnReceiptHeader."No.");  // Enqueue required for ReturnReceiptRequestPageHandler.
        exit(ReturnReceiptHeader."No.");
    end;

    local procedure CreateSalesBlanketOrder(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Blanket Order";
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader.Insert();
        LibraryVariableStorage.Enqueue(SalesHeader."No.");  // Enqueue required for SalesOrderTestRequestPageHandler,SalesBlanketOrderRequestPageHandler,SalesDocumentTestRequestPageHandler and SalesQuoteTestRequestPageHandler.
        CreateSalesLine(SalesLine, SalesHeader."No.");
    end;

    local procedure CreateSalesCommentLine(DocumentType: Enum "Sales Comment Document Type"; DocumentNo: Code[20]; DocumentLineNo: Integer; LineNo: Integer)
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesCommentLine."Document Type" := DocumentType;
        SalesCommentLine."No." := DocumentNo;
        SalesCommentLine."Document Line No." := DocumentLineNo;
        SalesCommentLine."Line No." := LineNo;
        SalesCommentLine.Comment := CommentLineTxt;  // Required more than 50 character to hit the code.
        SalesCommentLine.Code := LibraryUTUtility.GetNewCode10();
        SalesCommentLine."Print On Invoice" := true;
        SalesCommentLine."Print On Return Receipt" := true;
        SalesCommentLine."Print On Return Authorization" := true;
        SalesCommentLine."Print On Pick Ticket" := true;
        SalesCommentLine.Insert();
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Location Code" := LibraryUTUtility.GetNewCode10();
        SalesHeader."Sell-to Customer No." := LibraryUTUtility.GetNewCode();
        SalesHeader.Status := SalesHeader.Status::Released;
        SalesHeader.Insert();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LibraryRandom.RandInt(100);
        SalesLine.Description := LibraryUTUtility.GetNewCode();
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesLine.Insert();
        LibraryVariableStorage.Enqueue(SalesHeader."No.");  // Enqueue required for ReturnAuthorizationRequestPageHandler.
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine."Document Type" := SalesLine."Document Type"::"Blanket Order";
        SalesLine."Document No." := DocumentNo;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := LibraryUTUtility.GetNewCode();
        SalesLine.Description := LibraryUTUtility.GetNewCode();
        SalesLine.Insert();
    end;

    local procedure CreateSalespersonPurchaser(): Code[10]
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        SalespersonPurchaser.Code := LibraryUTUtility.GetNewCode10();
        SalespersonPurchaser.Insert();
        exit(SalespersonPurchaser.Code);
    end;

    local procedure CreateValueEntry(var ValueEntry: Record "Value Entry"; CustomerNo: Code[20]; ItemNo: Code[20])
    var
        ValueEntry2: Record "Value Entry";
    begin
        ValueEntry2.FindLast();
        ValueEntry."Entry No." := ValueEntry2."Entry No." + 1;
        ValueEntry."Source Type" := ValueEntry."Source Type"::Customer;
        ValueEntry."Source No." := CustomerNo;
        ValueEntry."Item Ledger Entry Type" := ValueEntry."Item Ledger Entry Type"::Sale;
        ValueEntry."Item No." := ItemNo;
        ValueEntry."Posting Date" := WorkDate();
        ValueEntry.Insert();
        LibraryVariableStorage.Enqueue(ValueEntry."Source No.");  // Enqueue required for CustomerItemStatisticsRequestPageHandler and CustomerItemStatByPurchaserRequestPageHandler.
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure GetAmountFromDetailCustLedgerEntry(CustLedgerEntryNo: Integer): Decimal
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntryNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.FindFirst();
        exit(DetailedCustLedgEntry."Amount (LCY)");
    end;

    local procedure UpdatePaymentTermsAndSalesPersonCodeOnCustomer(var Customer: Record Customer; PaymentTermsCode: Code[10]; SalesPersonPurchaser: Code[10])
    begin
        Customer."Payment Terms Code" := PaymentTermsCode;
        Customer."Salesperson Code" := SalesPersonPurchaser;
        Customer.Modify();
    end;

    local procedure UpdateSalesLCYAndProfitLCYOnCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry."Sales (LCY)" := LibraryRandom.RandDec(10, 2);
        CustLedgerEntry."Profit (LCY)" := CustLedgerEntry."Sales (LCY)";
        CustLedgerEntry.Modify();
    end;

    local procedure VerifyDataOnReport(ElementName: Text; ExpectedValue: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ElementName, ExpectedValue);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CashAppliedRequestPageHandler(var CashApplied: TestRequestPage "Cash Applied")
    var
        EntryNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(EntryNo);
        CashApplied."Cust. Ledger Entry".SetFilter("Entry No.", Format(EntryNo));
        CashApplied.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustItemStatsBySalesPersRequestPageHandler(var CustItemStatbySalespers: TestRequestPage "Cust./Item Stat. by Salespers.")
    var
        "Code": Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(Code);
        CustItemStatbySalespers."Salesperson/Purchaser".SetFilter(Code, Code);
        CustItemStatbySalespers.Customer.SetFilter("No.", No);
        CustItemStatbySalespers."Value Entry".SetFilter("Source No.", No);
        CustItemStatbySalespers.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerAccountDetailRequestPageHandler(var CustomerAccountDetail: TestRequestPage "Customer Account Detail")
    var
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        CustomerAccountDetail."Cust. Ledger Entry".SetFilter("Customer No.", CustomerNo);
        CustomerAccountDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerCommentListRequestPageHandler(var CustomerCommentList: TestRequestPage "Customer Comment List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CustomerCommentList."Comment Line".SetFilter("No.", No);
        CustomerCommentList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerItemStatisticsRequestPageHandler(var CustomerItemStatistics: TestRequestPage "Customer/Item Statistics")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CustomerItemStatistics.Customer.SetFilter("No.", No);
        CustomerItemStatistics."Value Entry".SetFilter("Source No.", No);
        CustomerItemStatistics.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerLabelsRequestPageHandler(var CustomerLabels: TestRequestPage "Customer Labels NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CustomerLabels.Customer.SetFilter("No.", No);
        CustomerLabels.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerListingRequestPageHandler(var CustomerListing: TestRequestPage "Customer Listing")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CustomerListing.Customer.SetFilter("No.", No);
        CustomerListing.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerRegisterRequestPageHandler(var CustomerRegister: TestRequestPage "Customer Register")
    var
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        CustomerRegister."Cust. Ledger Entry".SetFilter("Customer No.", CustomerNo);
        CustomerRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerSalesStatisticsRequestPageHandler(var CustomerSalesStatistics: TestRequestPage "Customer Sales Statistics")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CustomerSalesStatistics.Customer.SetFilter("No.", No);
        CustomerSalesStatistics.LengthOfPeriods.SetValue('');
        CustomerSalesStatistics.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PickingListByOrderRequestPageHandler(var PickingListByOrder: TestRequestPage "Picking List by Order")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PickingListByOrder."Sales Header".SetFilter("No.", No);
        PickingListByOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReturnAuthorizationRequestPageHandler(var ReturnAuthorization: TestRequestPage "Return Authorization")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ReturnAuthorization."Sales Header".SetFilter("No.", No);
        ReturnAuthorization.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReturnReceiptRequestPageHandler(var ReturnReceipt: TestRequestPage "Return Receipt")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ReturnReceipt."Return Receipt Header".SetFilter("No.", No);
        ReturnReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderRequestPageHandler(var SalesBlanketOrder: TestRequestPage "Sales Blanket Order")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesBlanketOrder."Sales Header".SetFilter("No.", No);
        SalesBlanketOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoicePrePrintedRequestPageHandler(var SalesInvoicePrePrinted: TestRequestPage "Sales Invoice (Pre-Printed)")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesInvoicePrePrinted."Sales Invoice Header".SetFilter("No.", No);
        SalesInvoicePrePrinted.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorAccountDetailRequestPageHandler(var VendorAccountDetail: TestRequestPage "Vendor Account Detail")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        VendorAccountDetail.Vendor.SetFilter("No.", No);
        VendorAccountDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
