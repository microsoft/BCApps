codeunit 142061 "ERM Misc. Report II"
{
    // Verify ERM Miscellaneous Reports:
    //  1. Verify Top Inventory Items Report using Smallest Quantity on Hand.
    //  2. Verify Top Inventory Items Report using Largest Quantity on Hand.
    //  3. Verify Top Inventory Items Report using Smallest Sales.
    //  4. Verify Top Inventory Items Report using Largest Sales.
    //  5. Verify Top Inventory Items Report using Smallest Inventory Value.
    //  6. Verify Top Inventory Items Report using Largest Inventory Value.
    //  7. Verify Item Status by Salesperson using Filters.
    //  8. Verify Ship to Address Listing Report.
    //  9. Verify Customer Account Detail Report With Print Amount In Customer Currency True.
    // 10. Verify Customer Account Detail Report With Print Amount In Customer Currency False.
    // 11. Verify Customer Account Detail Report With New Page Per Account True.
    // 12. Verify Customer Account Detail Report With New Page Per Account False.
    // 13. Verify Customer Account Detail Report With Account with Balance Only True.
    // 14. Verify Customer Account Detail Report With Account with Balance Only False.
    // 15. Verify error on Customer Statement Report when Print With All Entries set to FALSE.
    // 16. Verify Date Filter error on Customer Statement Report.
    // 17. Verify Range of dates error on Customer Statement Report when Statement Style is set to Balance.
    // 18. Verify Aging period error on Customer Statement Report when Aging method is set to Due Date.
    // 19. Verify Customer Statement Report after posting Sales Order.
    // 20. Verify Return Shipment Report with Print Company and without Log Interaction option.
    // 21. Verify Return Shipment Report without Print Company and with Log Interaction option.
    // 22. Verify Vendor Listing report with Print Amounts In Vendor's Currency option.
    // 23. Verify Vendor Listing report with Vend. With Balances Only option.
    // 24. Verify Cash Requirement By Due Date report with Print Detail option.
    // 25. Verify Cash Requirement By Due Date report with Print Detail and Use External Doc No option.
    // 26. Verify Sales Document Test Report with Document Type Order.
    // 27. Verify Sales Document Test Report with Document Type Return Order.
    // 28. Verify Sales Document Test Report with Document Type Invoice.
    // 29. Verify Sales Document Test Report with Document Type Credit Memo.
    // 30. Verify Sales Document Test Report with Document Type Blanket Order.
    // 33. Verify Customer Item Statistics Report after posting Sales Order.
    // 34. Verify Customer Item Statistics by Sales Person Report after posting Sales Order.
    // 35. Verify error on Daily Invoicing Report when Include Invoice and Include Credit Memo both are set to FALSE.
    // 36. Verify Daily Invoicing Report with Include Invoice and Include Credit Memo TRUE after posting Sales Order and Sales Credit Memo.
    // 37. Verify Outstanding Sales Order Aging Report With Print Amount in Customer Currency TRUE.
    // 38. Verify Outstanding Sales Order Aging Report With Print Amount in Customer Currency FALSE.
    // 39. Verify Outstanding Sales Order Status Report With Print Amount in Customer Currency TRUE.
    // 40. Verify Outstanding Sales Order Status Report With Print Amount in Customer Currency FALSE.
    // 41. Verify SalesPerson Statistics By Invoice Report after posting Sales Order.
    // 42. Verify Sales Commission Report after posting Sales Order.
    // 43. Verify Projected Cash Receipt Report with Print Total in Customer Currency True.
    // 44. Verify Projected Cash Receipt Report with Print Total in Customer Currency False.
    // 45. Verify Drop Shipment Report after Get Sales Order and Carryout Action Message on Requisition Line.
    // 46. Verify Open Sales Invoice By Job Report after posting Sales Invoice.
    // 
    // Covers Test Cases for WI - 327947
    // -----------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                          TFS ID
    // -----------------------------------------------------------------------------------------------------------------------------------
    // TopInventoryItemsReportUsingSmallestQtyonHand, TopInventoryItemsReportUsingLargestQtyonHand,
    // TopInventoryItemsReportUsingSmallestSales, TopInventoryItemsReportUsingLargestSales,
    // TopInventoryItemsReportUsingSmallestInvtVal, TopInventoryItemsReportUsingLargestInvtVal                                      171155
    // ItemStatusBySalespersonUsingFilters                                                                                          171200
    // 
    // Covers Test Cases for WI - 329593
    // -----------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                          TFS ID
    // -----------------------------------------------------------------------------------------------------------------------------------
    // ShipToAddressListingReport                                                                                                  171207
    // CustomerAccountDetailCurrencyTrue, CustomerAccountDetailReportFalse
    // CustomerAccountDetailReportNewPageTrue, CustomerAccountDetailReportNewPageFalse                                             284451
    // CustomerAccountDetailReportBalanceOnlyTrue, CustomerAccountDetailReportBalanceOnlyFalse
    // CustomerStatementEntiesBalanceError, CustomerStatementDateFilterError
    // CustomerStatementStatementStyleError, CustomerStatementAgingMethodError                                                     171209
    // CustomerStmtReportAfterPostingSalesOrder
    // 
    // Covers Test Cases for WI - 329573
    // -----------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                          TFS ID
    // -----------------------------------------------------------------------------------------------------------------------------------
    // ReturnShipmentWithPrintCompany, ReturnShipmentWithLogInteract                                                               171099
    // VendListingWithPrintAmtsInVendCurr, VendListingWithVendWithBalOnly                                                          171102
    // CashReqtByDueDateWithPrintDtl, CashReqtByDueDateWithPrintDtlAndUseExternalDocNo                                             171186
    // 
    // Covers Test Cases for WI - 331222
    // -----------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                          TFS ID
    // -----------------------------------------------------------------------------------------------------------------------------------
    // SalesDocumentTestReportWithSalesOrder, SalesDocumentTestreportWithSalesReturnOrder
    // SalesDocumentTestReportWithSalesInvoice, SalesDocumentTestReportWithSalesCreditMemo
    // SalesDocumentTestReportWithBlanketOrder                                                                                     171215
    // CustTop10ListReportWithTopTypeSales, CustTop10ListReportWithTopTypeBalance                                                  171208
    // 
    // Covers Test Cases for WI - 329591
    // -----------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                          TFS ID
    // -----------------------------------------------------------------------------------------------------------------------------------
    // CustomerItemStatisticsReport                                                                                                171196
    // CustItemStatBySalesPersonReportAssignedToCustomer                                                                           171197
    // DailyInvoicingReportError, DailyInvoicingReport                                                                             171198
    // OutStandingSalesOrderAgingReportWithCurrencyTrue, OutStandingSalesOrderAgingReportWithCurrencyFalse                         171202
    // OutStandingSalesOrderStatusReportWithCurrencyTrue, OutStandingSalesOrderStatusReportWithCurrencyFalse                       171203
    // SalespersonStatisticsByInvoiceReport                                                                                        171206
    // SalespersonCommissionReport                                                                                                 171205
    // ProjectedCashReceiptReportWithCurrencyTrue, ProjectedCashReceiptReportWithCurrencyFalse                                     171204
    // DropShipmentStatusReportByCustomer                                                                                          171199
    // OpenSalesInvoiceByJobReport                                                                                                 171201

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryResource: Codeunit "Library - Resource";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountToPrintCaption: Label 'AmountToPrint';
        CompanyNameCap: Label 'CompanyAddress1';
        CustTotalAmountDue2Caption: Label 'CustTotalAmountDue_2_';
        CustomerNoCaption: Label 'Customer__No__';
        CustomerFilter: Label '%1|%2';
        CustLedgerEntryAmountLCY: Label 'Cust__Ledger_Entry__Amount__LCY__';
        CustLedgerEntryAmountCaption: Label 'Cust__Ledger_Entry_Amount';
        CustLedgerEntryDocumentNoCaption: Label 'Cust__Ledger_Entry__Document_No__';
        CustLedgerEntrySalesLCYCaption: Label 'Cust__Ledger_Entry__Sales__LCY__';
        CustLedgerEntryRemainingAmtLCYCaption: Label 'Cust__Ledger_Entry__Remaining_Amt___LCY__';
        DocNoCap: Label 'DocNo';
        "Filter": Label '%1..%2';
        FilterString: Label '%1: %2';
        FilterStringCap: Label 'FilterString';
        FilterString2: Label '%1: %2, %3: %4';
        FilterStringCap2: Label 'FilterString2';
        InvoicedQuantityCaption: Label 'Invoiced_Quantity_';
        JobNoCaption: Label 'Job_No_';
        IntegerNumberCap: Label 'Integer_Number';
        ItemDescriptionCap: Label 'Item_Description';
        InvoicedQuantityCap: Label 'Invoiced_Quantity_';
        InvoiceCreditMemoError: Label 'You must Include either Invoices or Credit Memos.';
        ItemNumberToPrintCap: Label 'ItemNumberToPrint';
        LastDocNoCaption: Label 'LastDocNo';
        NewPagePerGroupNoCaption: Label 'NewPagePerGroupNo';
        OutstandingExclTax2Caption: Label 'OutstandingExclTax_2';
        PrintDetailCap: Label 'PrintDetail';
        PaymentDiscToPrintCap: Label 'PaymentDiscToPrint';
        PurchaseLineDocumentNoCaption: Label 'PurchaseLine__Document_No__';
        PurchaseLineBuyfromVendorNoCaption: Label 'PurchaseLine__Buy_from_Vendor_No__';
        ProfitCommissionCaption: Label 'ProfitCommission';
        QtyReturnShipmentLineCap: Label 'Qty_ReturnShipmentLine';
        RowMustNotExistErr: Label 'Row Must Not Exist';
        RoundingDirection: Label '<';
        SalesCommissionCaption: Label 'SalesCommission';
        SalesHeaderNoCap: Label 'SalesHeader__No__';
        SalesHeaderNoCaption: Label 'Sales_Header_No_';
        SalesHeaderSelltoCustomerNoCaption: Label 'Sales_Header___Sell_to_Customer_No__';
        SalesInvoiceLineDocumentNoCaption: Label 'Sales_Invoice_Line_Document_No_';
        SalespersonPurchaserCodeCaption: Label 'Salesperson_Purchaser_Code';
        SalespersonPurchaserCommissionCaption: Label 'Salesperson_Purchaser__Commission___';
        SalesInvoiceHeaderNoCaption: Label 'Sales_Invoice_Header__No__';
        SalesInvoiceHeaderBilltoCustomerNoCaption: Label 'Sales_Invoice_Header__Bill_to_Customer_No__';
        SalesInvoiceHeaderAmountCaption: Label 'Sales_Invoice_Header_Amount';
        SalesCrMemoHeaderNoCaption: Label 'Sales_Cr_Memo_Header__No__';
        SalesCrMemoHeaderBilltoCustomerNo: Label 'Sales_Cr_Memo_Header__Bill_to_Customer_No__';
        SalesCrMemoHeaderAmountCaption: Label 'Sales_Cr_Memo_Header_Amount';
        SalesLineNoCaption: Label 'Sales_Line___No__';
        SalesLineNoCap: Label 'Sales_Line__No__';
        SalesLineDocumentNoCaption: Label 'Sales_Line__Document_No__';
        SalesLineQuantityCaption: Label 'Sales_Line__Quantity';
        SalesLineQuantityCap: Label 'Sales_Line_Quantity';
        SalesLineLineAmountCaption: Label 'Sales_Line___Line_Amount_';
        ShiptoAddressCodeCaption: Label 'Ship_to_Address_Code';
        ShiptoAddressTaxAreaCodeCaption: Label 'Ship_to_Address__Tax_Area_Code_';
        TopNoCap: Label 'TopNo_Number_';
        TotalOutstandingCaption: Label 'TotalOutstanding';
        UseExternalDocNoCap: Label 'UseExternalDocNo';
        ValueMustMatch: Label 'Value must match.';
        VATAmountLineVATIdentifierCaption: Label 'VATAmountLine__VAT_Identifier_';
        VATAmountLineLineAmountCaption: Label 'VATAmountLine__Line_Amount__Control169';
        VATAmountLineVATAmountCaption: Label 'VATAmountLine__VAT_Amount__Control175';
        ValueEntryItemNoCaption: Label 'Value_Entry__Item_No__';
        ValueEntrySalesAmountActualCaption: Label 'Value_Entry__Sales_Amount__Actual__';
        VendorNoCap: Label 'Vendor__No__';
        VendBalanceCap: Label 'VendBalance';
        VendorLedgerEntryVendorNoCap: Label 'Vendor_Ledger_Entry__Vendor_No__';
        BalanceTotalLbl: Label 'BalanceTotal', Locked = true;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";

    [Test]
    [HandlerFunctions('TopInventoryItemsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TopInventoryItemsReportUsingSmallestQtyonHand()
    var
        TopSorting: Option Largest,Smallest;
    begin
        // Verify Top Inventory Items Report with Smallest Quantity on Hand.
        TopInventoryItemsReportUsingQtyonHandSetup(TopSorting::Smallest, 1); // Use value 1 for Smallest sorting.
    end;

    [Test]
    [HandlerFunctions('TopInventoryItemsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TopInventoryItemsReportUsingLargestQtyonHand()
    var
        TopSorting: Option Largest;
    begin
        // Verify Top Inventory Items Report with Largest Quantity on Hand.
        TopInventoryItemsReportUsingQtyonHandSetup(TopSorting::Largest, 2);  // Use value 2 for Largest sorting.
    end;

    local procedure TopInventoryItemsReportUsingQtyonHandSetup(TopSorting: Option; IntegerNumber: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLine2: Record "Item Journal Line";
        TopType: Option Sales,"Qty on Hand";
    begin
        // Setup: Create and Post two Item Journal.
        Initialize();
        SelectAndPostItemJournal(ItemJournalLine, LibraryRandom.RandDec(100, 2));  // Use Random value for Quantity.
        SelectAndPostItemJournal(ItemJournalLine2, ItemJournalLine.Quantity + 10);  // Use greater value than posted Item Journal.
        EnqueueValuesForTopInventoryItemsReport(
          ItemJournalLine."Item No.", ItemJournalLine2."Item No.", TopSorting, TopType::"Qty on Hand");

        // Exercise.
        REPORT.Run(REPORT::"Top __ Inventory Items");

        // Verify: Verify Inventory Item on Top Inventory Items Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(Format(IntegerNumber), IntegerNumberCap, TopNoCap, ItemJournalLine."Item No.");
    end;

    [Test]
    [HandlerFunctions('TopInventoryItemsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TopInventoryItemsReportUsingSmallestSales()
    var
        TopSorting: Option Largest,Smallest;
    begin
        // Verify Top Inventory Items Report with Smallest Sales.
        TopInventoryItemsReportUsingSalesSetup(TopSorting::Smallest, 1);  // Use value 1 for Smallest sorting.
    end;

    [Test]
    [HandlerFunctions('TopInventoryItemsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TopInventoryItemsReportUsingLargestSales()
    var
        TopSorting: Option Largest;
    begin
        // Verify Top Inventory Items Report with Largest Sales.
        TopInventoryItemsReportUsingSalesSetup(TopSorting::Largest, 2);  // Use value 2 for Largest sorting.
    end;

    local procedure TopInventoryItemsReportUsingSalesSetup(TopSorting: Option; IntegerNumber: Integer)
    var
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        TopType: Option Sales;
    begin
        // Setup: Create and Post two Sales Order.
        Initialize();
        CreateAndPostSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, CreateCustomer(''), LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity and Unit Price.
        CreateAndPostSalesDocument(
          SalesLine2, SalesLine."Document Type"::Order, CreateCustomer(''),
          SalesLine.Quantity + LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity and Unit Price.
        EnqueueValuesForTopInventoryItemsReport(SalesLine."No.", SalesLine2."No.", TopSorting, TopType::Sales);

        // Excercise.
        REPORT.Run(REPORT::"Top __ Inventory Items");

        // Verify: Verify Sales of Item on Top Inventory Items Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(Format(IntegerNumber), IntegerNumberCap, TopNoCap, SalesLine."No.");
    end;

    [Test]
    [HandlerFunctions('TopInventoryItemsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TopInventoryItemsReportUsingSmallestInvtVal()
    var
        TopSorting: Option Largest,Smallest;
    begin
        // Verify Top Inventory Items Report with Smallest Inventory Value.
        TopInventoryItemsReportUsingInvtValSetup(TopSorting::Smallest, 1); // Use value 1 for Smallest sorting.
    end;

    [Test]
    [HandlerFunctions('TopInventoryItemsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TopInventoryItemsReportUsingLargestInvtVal()
    var
        TopSorting: Option Largest;
    begin
        // Verify Top Inventory Items Report with Smallest Inventory Value.
        TopInventoryItemsReportUsingInvtValSetup(TopSorting::Largest, 2);  // Use value 2 for Largest sorting.
    end;

    local procedure TopInventoryItemsReportUsingInvtValSetup(TopSorting: Option; IntegerNumber: Integer)
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TopType: Option Sales,"Qty on Hand","Inventory Value";
    begin
        // Setup: Create and Post two Purchase Order.
        Initialize();
        CreateAndPostPurchaseDocumentForInventoryValue(
          LibraryInventory.CreateItem(Item), '', true, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDecInRange(0, 10, 2));  // Random value for Quantity.
        Item.CalcFields(Inventory);
        CreateAndPostPurchaseDocumentForInventoryValue(
          LibraryInventory.CreateItem(Item2),
          '', true, PurchaseHeader."Document Type"::Order, Item.Inventory + LibraryRandom.RandDec(10, 2), LibraryRandom.RandDecInDecimalRange(10, 100, 2));  // Random value for greater Quantity.
        EnqueueValuesForTopInventoryItemsReport(Item."No.", Item2."No.", TopSorting, TopType::"Inventory Value");

        // Excercise.
        REPORT.Run(REPORT::"Top __ Inventory Items");

        // Verify: Verify Inventory Value of Item on Top Inventory Items Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(Format(IntegerNumber), IntegerNumberCap, TopNoCap, Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemStatusBySalespersonRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemStatusBySalespersonUsingFilters()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        ValueEntry: Record "Value Entry";
        FilterStringValue: Text[50];
        FilterStringValue2: Text[50];
    begin
        // Verify Item Status by Salesperson with Filters.
        Initialize();
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibraryRandom.RandDec(100, 2), CreateCustomer(''),
          CreateItem(), LibraryRandom.RandDec(100, 2));  // Using Random Value for Quantity and Unit Price.
        ModifySalesHeader(SalesHeader, SalesLine, SalespersonPurchaser.Code);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryVariableStorage.Enqueue(SalespersonPurchaser.Code);
        LibraryVariableStorage.Enqueue(SalesLine."No.");
        LibraryVariableStorage.Enqueue(SalesHeader."Posting Date");
        FilterStringValue := StrSubstNo(FilterString, SalespersonPurchaser.FieldCaption(Code), SalespersonPurchaser.Code);
        FilterStringValue2 :=
          StrSubstNo(FilterString2, ValueEntry.FieldCaption("Item No."), SalesLine."No.", SalesHeader.FieldCaption("Posting Date"),
            SalesHeader."Posting Date");

        // Excercise.
        REPORT.Run(REPORT::"Item Status by Salesperson");

        // Verify: Verify Filters on Item Status by Salesperson Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(FilterStringValue, FilterStringCap, FilterStringCap2, FilterStringValue2);
        VerifyValuesOnReport(SalesLine."No.", ItemDescriptionCap, InvoicedQuantityCap, SalesLine."Qty. to Invoice");
    end;

    [Test]
    [HandlerFunctions('ShipToAddressListingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ShipToAddressListingReport()
    var
        ShiptoAddress: Record "Ship-to Address";
        TaxArea: Record "Tax Area";
    begin
        // Verify Ship to Address Listing Report.

        // Setup: Create Ship to Address, create Tax Area code.
        Initialize();
        LibrarySales.CreateShipToAddress(ShiptoAddress, CreateCustomer(''));
        LibraryERM.CreateTaxArea(TaxArea);
        ShiptoAddress.Validate("Tax Area Code", TaxArea.Code);
        ShiptoAddress.Modify(true);
        LibraryVariableStorage.Enqueue(ShiptoAddress."Customer No.");  // Enqueue for ShipToAddressListingRequestPageHandler.
        Commit();  // COMMIT required to run the report.

        // Exercise.
        REPORT.Run(REPORT::"Ship-To Address Listing");

        // Verify: Verify Ship to Address code and Tax Area code on Ship to Address Listing Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(
          ShiptoAddress."Customer No.", CustomerNoCaption, ShiptoAddressTaxAreaCodeCaption, ShiptoAddress."Tax Area Code");
        VerifyValuesOnReport(ShiptoAddress."Customer No.", CustomerNoCaption, ShiptoAddressCodeCaption, ShiptoAddress.Code);
    end;

    [Test]
    [HandlerFunctions('CustomerAccountDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerAccountDetailCurrencyTrue()
    var
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // Verify Customer Account Detail Report With Print Amount In Customer Currency True.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);  // Taken random Amount.
        CurrencyCode := CreateCurrency();
        CustomerAccountDetailReport(CurrencyCode, false, Amount, LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('CustomerAccountDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerAccountDetailReportFalse()
    var
        Amount: Decimal;
    begin
        // Verify Customer Account Detail Report With Print Amount In Customer Currency False.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);  // Taken random Amount.
        CustomerAccountDetailReport(CreateCurrency(), true, Amount, Amount);
    end;

    local procedure CustomerAccountDetailReport(CurrencyCode: Code[10]; PrintAmtInCustCurrency: Boolean; Amount: Decimal; AmountToPrint: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create and post General Journal Line.
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomer(CurrencyCode), -Amount);
        EnqueueValuesForCustAccountDetailReport(GenJournalLine."Account No.", PrintAmtInCustCurrency, false, false);  // Enqueue values for CustomerAccountDetailRequestPageHandler.
        Commit();  // COMMIT required to run the Report.

        // Exercise.
        REPORT.Run(REPORT::"Customer Account Detail");

        // Verify: Verify Amount and Amount to print on Customer Account Detail Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(GenJournalLine."Account No.", CustomerNoCaption, CustLedgerEntryAmountCaption, -Amount);
        VerifyValuesOnReport(GenJournalLine."Account No.", CustomerNoCaption, AmountToPrintCaption, -AmountToPrint);
    end;

    [Test]
    [HandlerFunctions('CustomerAccountDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerAccountDetailReportNewPageTrue()
    begin
        // Verify Customer Account Detail Report With New Page Per Account True.
        CustomerAccountDetailReportNewPage(true, 1, 2);  // Taken 1 and 2 for first and second page no.
    end;

    [Test]
    [HandlerFunctions('CustomerAccountDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerAccountDetailReportNewPageFalse()
    begin
        // Verify Customer Account Detail Report With New Page Per Account False.
        CustomerAccountDetailReportNewPage(false, 0, 0);  // Taken 0 for new page per group.
    end;

    local procedure CustomerAccountDetailReportNewPage(NewpagePerAccount: Boolean; NewPagePerGroupValue: Integer; NewPagePerGroupValue2: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        // Setup: Create and post two General Journal Lines.
        Initialize();
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomer(''), -LibraryRandom.RandDec(100, 2));  // Taken random Amount.
        CreateAndPostGenJournalLine(GenJournalLine2, CreateCustomer(''), -LibraryRandom.RandDec(100, 2));  // Taken random Amount.
        EnqueueValuesForCustAccountDetailReport(
          StrSubstNo(CustomerFilter, GenJournalLine."Account No.", GenJournalLine2."Account No."), true, NewpagePerAccount, false);
        Commit();  // COMMIT required to run the Report.

        // Exercise.
        REPORT.Run(REPORT::"Customer Account Detail");

        // Verify: Verify Customer No. on Customer Account Detail Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(GenJournalLine."Account No.", CustomerNoCaption, NewPagePerGroupNoCaption, NewPagePerGroupValue);
        VerifyValuesOnReport(GenJournalLine2."Account No.", CustomerNoCaption, NewPagePerGroupNoCaption, NewPagePerGroupValue2);
    end;

    [Test]
    [HandlerFunctions('CustomerAccountDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerAccountDetailReportBalanceOnlyTrue()
    var
        CustomerNo: Code[20];
    begin
        // Verify Customer Account Detail Report With Account with Balance Only True.

        // Setup and Exercise.
        Initialize();
        CustomerNo := CreateCustomer('');
        CustomerAccountDetailReportBalance(true, CustomerNo);

        // Verify: Verify Customer No. with no balance does not exist on Customer Account Detail Report.
        LibraryReportDataset.SetRange(CustomerNoCaption, CustomerNo);
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), RowMustNotExistErr);
    end;

    [Test]
    [HandlerFunctions('CustomerAccountDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerAccountDetailReportBalanceOnlyFalse()
    var
        CustomerNo: Code[20];
    begin
        // Verify Customer Account Detail Report With Account with Balance Only False.

        // Setup and Exercise.
        Initialize();
        CustomerNo := CreateCustomer('');
        CustomerAccountDetailReportBalance(false, CustomerNo);

        // Verify: Verify Customer No. with no balance exists on Customer Account Detail Report.
        LibraryReportDataset.AssertElementWithValueExists(CustomerNoCaption, CustomerNo);
    end;

    local procedure CustomerAccountDetailReportBalance(AccWithBalanceOnly: Boolean; CustomerNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create and post General Journal Line.
        CreateAndPostGenJournalLine(GenJournalLine, CreateCustomer(''), -LibraryRandom.RandDec(100, 2));  // Taken random Amount.
        EnqueueValuesForCustAccountDetailReport(
          StrSubstNo(CustomerFilter, GenJournalLine."Account No.", CustomerNo), true, false, AccWithBalanceOnly);
        Commit();  // COMMIT required to run the Report.

        // Exercise.
        REPORT.Run(REPORT::"Customer Account Detail");

        // Verify: Verify Customer No. exists on Customer Account Detail Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CustomerNoCaption, GenJournalLine."Account No.");
        LibraryReportDataset.AssertElementWithValueExists(BalanceTotalLbl, GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ReturnShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnShipmentWithPrintCompany()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify Return Shipment Report with Print Company and without Log Interaction option.
        Initialize();
        CompanyInformation.Get();
        ReturnShipmentReport(CompanyInformation.Name, true, false, true);
    end;

    [Test]
    [HandlerFunctions('ReturnShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnShipmentWithLogInteract()
    begin
        // Verify Return Shipment Report without Print Company and with Log Interaction option.
        Initialize();
        ReturnShipmentReport('', false, true, false);
    end;

    [Test]
    [HandlerFunctions('VendorListingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendListingWithPrintAmtsInVendCurr()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
    begin
        // Verify Vendor Listing report with Print Amounts In Vendor's Currency option.

        // Setup & Exercise.
        Initialize();
        VendorNo := CreateVendorWithCurrency(CreateCurrency());
        CreateAndPostInvoiceAndRunReportVendorListing(VendorLedgerEntry, VendorNo, true, false);

        // Verify: Verify Vendor Listing report.
        VendorLedgerEntry.CalcFields(Amount);
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(VendorLedgerEntry."Vendor No.", VendorNoCap, VendBalanceCap, Abs(VendorLedgerEntry.Amount));
        VerifyValuesOnReport(VendorNo, VendorNoCap, VendBalanceCap, 0);  // Use 0 for balance.
    end;

    [Test]
    [HandlerFunctions('VendorListingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendListingWithVendWithBalOnly()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
    begin
        // Verify Vendor Listing report with Vend. With Balances Only option.

        // Setup & Exercise.
        Initialize();
        VendorNo := CreateVendorWithCurrency(CreateCurrency());
        CreateAndPostInvoiceAndRunReportVendorListing(VendorLedgerEntry, VendorNo, false, true);

        // Verify: Verify Vendor Listing report.
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(VendorLedgerEntry."Vendor No.", VendorNoCap, VendBalanceCap, Abs(VendorLedgerEntry."Amount (LCY)"));
        LibraryReportDataset.SetRange(VendorNoCap, VendorNo);
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), RowMustNotExistErr);
    end;

    [Test]
    [HandlerFunctions('CashReqtByDueDateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CashReqtByDueDateWithPrintDtl()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Verify Cash Requirement By Due Date report with Print Detail option.

        // Setup & Exercise.
        Initialize();
        CreateAndPostInvoiceAndRunReportCashReqtByDueDate(VendorLedgerEntry, false);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyCashRequirementByDueDate(VendorLedgerEntry, VendorLedgerEntry."Document No.", false);
    end;

    [Test]
    [HandlerFunctions('CashReqtByDueDateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CashReqtByDueDateWithPrintDtlAndUseExternalDocNo()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 261601] "External Document No." printed in report "Cash Requirements by Due Date"
        // Verify Cash Requirement By Due Date report with Print Detail and Use External Doc option.

        // [GIVEN] Vendor Ledger Entry with "External Document No." (lenght of value is max)
        // [WHEN] Run report "Cash Requirements by Due Date"
        // Setup & Exercise.
        Initialize();
        CreateAndPostInvoiceAndRunReportCashReqtByDueDate(VendorLedgerEntry, true);

        // [THEN] Report contains value of "External Document No."
        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyCashRequirementByDueDate(VendorLedgerEntry, VendorLedgerEntry."External Document No.", true);
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestReportWithSalesOrder()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales Document Test Report with Document Type Order.
        SalesDocumentTestReport(SalesLine."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestreportWithSalesReturnOrder()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales Document Test Report with Document Type Return Order.
        SalesDocumentTestReport(SalesLine."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestReportWithSalesInvoice()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales Document Test Report with Document Type Invoice.
        SalesDocumentTestReport(SalesLine."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestReportWithSalesCreditMemo()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales Document Test Report with Document Type Credit Memo.
        SalesDocumentTestReport(SalesLine."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestReportWithBlanketOrder()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales Document Test Report with Document Type Blanket Order.
        SalesDocumentTestReport(SalesLine."Document Type"::"Blanket Order");
    end;

    local procedure SalesDocumentTestReport(DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Setup: Create Sales Document.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocument(
          SalesLine, DocumentType, LibraryRandom.RandDec(100, 2),
          CreateAndUpdateVATBusPostGrOnCustomer(VATPostingSetup."VAT Bus. Posting Group"),
          CreateAndUpdateVATProdPostGrOnItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(100, 2));  // Taken random Quantity and Unit Price.
        LibraryVariableStorage.Enqueue(DocumentType);
        LibraryVariableStorage.Enqueue(SalesLine."Document No.");  // Enqueue for SalesDocumentTestRequestPageHandler.
        Commit();  // COMMIT required to run the Report.

        // Exercise.
        REPORT.Run(REPORT::"Sales Document - Test");

        // Verify: Verify Sell To Customer No., Quantity, Line Amount and VAT Amount on Sales Document Test Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(
          SalesLine."Document No.", SalesHeaderNoCaption, SalesHeaderSelltoCustomerNoCaption, SalesLine."Sell-to Customer No.");
        VerifyValuesOnReport(SalesLine."No.", SalesLineNoCaption, SalesLineQuantityCaption, SalesLine.Quantity);
        VerifyValuesOnReport(SalesLine."No.", SalesLineNoCaption, SalesLineLineAmountCaption, SalesLine."Line Amount");
        VerifyValuesOnReport(
          VATPostingSetup."VAT Identifier", VATAmountLineVATIdentifierCaption, VATAmountLineLineAmountCaption, SalesLine."Line Amount");
        VerifyValuesOnReport(
          VATPostingSetup."VAT Identifier", VATAmountLineVATIdentifierCaption, VATAmountLineVATAmountCaption, Round(
            SalesLine."Line Amount" * VATPostingSetup."VAT %" / 100));
    end;

    [Test]
    [HandlerFunctions('CustomerItemStatisticsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemStatisticsReport()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Customer Item Statistics Report after posting Sales Order.

        // Setup: Create and post Sales Order.
        Initialize();
        CreateAndPostSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, CreateCustomer(''), LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity and Unit Price.
        LibraryVariableStorage.Enqueue(SalesLine."Sell-to Customer No.");  // Enqueue for CustomerItemStatisticsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Customer/Item Statistics");

        // Verify: Verify Invoiced Quantity and Line Amount on Customer Item Statistics Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(SalesLine."Sell-to Customer No.", CustomerNoCaption, InvoicedQuantityCaption, SalesLine.Quantity);
        VerifyValuesOnReport(
          SalesLine."Sell-to Customer No.", CustomerNoCaption, ValueEntrySalesAmountActualCaption, SalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('CustItemStatBySalespersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustItemStatBySalesPersonReportAssignedToCustomer()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        // Verify Customer Item Statistics by Sales Person Report after posting Sales Order.

        // Setup: Create Customer, create and post Sales Order.
        Initialize();
        PostSalesOrderWithSalesperson(SalesLine, LibraryRandom.RandDec(10, 2));  // Taken random value for Commission Pct.
        Customer.Get(SalesLine."Sell-to Customer No.");

        // Exercise.
        REPORT.Run(REPORT::"Cust./Item Stat. by Salespers.");

        // Verify: Verify Sales Person String, Amount, Item No. on Customer Item Statistics By Sales Person Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(
          Customer."Salesperson Code", SalespersonPurchaserCodeCaption, ValueEntrySalesAmountActualCaption, SalesLine."Line Amount");
        VerifyValuesOnReport(Customer."Salesperson Code", SalespersonPurchaserCodeCaption, ValueEntryItemNoCaption, SalesLine."No.");
    end;

    [Test]
    [HandlerFunctions('DailyInvoicingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DailyInvoicingReportError()
    begin
        // Verify error on Daily Invoicing Report when Include Invoice and Include Credit Memo both are set to FALSE.

        // Setup.
        Initialize();

        // Exercise.
        asserterror RunDailyInvoicingReport(false, false, '');

        // Verify: Verify error when Include Invoice and Include Credit Memo both are set to FALSE.
        Assert.ExpectedError(InvoiceCreditMemoError);
    end;

    [Test]
    [HandlerFunctions('DailyInvoicingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DailyInvoicingReport()
    var
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        PostedSalesInvoiceNo: Code[20];
        PostedCreditMemoNo: Code[20];
    begin
        // Verify Daily Invoicing Report with Include Invoice and Include Credit Memo TRUE after posting Sales Order and Sales Credit Memo.

        // Setup: Create and post Sales Invoice and Sales credit Memo.
        Initialize();
        PostedSalesInvoiceNo :=
          CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Order, CreateCustomer(''),
            LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity and Unit Price.
        PostedCreditMemoNo :=
          CreateAndPostSalesDocument(SalesLine2, SalesLine2."Document Type"::"Credit Memo", CreateCustomer(''),
            LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity and Unit Price.

        // Exercise.
        RunDailyInvoicingReport(true, true, StrSubstNo(CustomerFilter, SalesLine."Sell-to Customer No.", SalesLine2."Sell-to Customer No."));

        // Verify: Verify Bill To Customer No and Amount on Daily Invoicing Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(
          PostedSalesInvoiceNo, SalesInvoiceHeaderNoCaption, SalesInvoiceHeaderBilltoCustomerNoCaption, SalesLine."Sell-to Customer No.");
        VerifyValuesOnReport(PostedSalesInvoiceNo, SalesInvoiceHeaderNoCaption, SalesInvoiceHeaderAmountCaption, SalesLine."Line Amount");
        VerifyValuesOnReport(
          PostedCreditMemoNo, SalesCrMemoHeaderNoCaption, SalesCrMemoHeaderBilltoCustomerNo, SalesLine2."Sell-to Customer No.");
        VerifyValuesOnReport(PostedCreditMemoNo, SalesCrMemoHeaderNoCaption, SalesCrMemoHeaderAmountCaption, SalesLine2."Line Amount");
    end;

    [Test]
    [HandlerFunctions('OutstandingSalesOrderAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OutStandingSalesOrderAgingReportWithCurrencyTrue()
    var
        CurrencyCode: Code[10];
        UnitPrice: Decimal;
    begin
        // Verify Outstanding Sales Order Aging Report With Print Amount in Customer Currency TRUE.
        Initialize();
        CurrencyCode := CreateCurrency();
        UnitPrice := LibraryRandom.RandDec(10, 2);  // Taken random for Unit Price.
        OutStandingSalesOrderAgingReport(CurrencyCode, UnitPrice, false, LibraryERM.ConvertCurrency(UnitPrice, CurrencyCode, '', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('OutstandingSalesOrderAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OutStandingSalesOrderAgingReportWithCurrencyFalse()
    var
        UnitPrice: Decimal;
    begin
        // Verify Outstanding Sales Order Aging Report With Print Amount in Customer Currency FALSE.
        Initialize();
        UnitPrice := LibraryRandom.RandDec(10, 2);  // Taken random for Unit Price.
        OutStandingSalesOrderAgingReport(CreateCurrency(), UnitPrice, true, UnitPrice);
    end;

    local procedure OutStandingSalesOrderAgingReport(CurrencyCode: Code[10]; UnitPrice: Decimal; PrintAmountInCustCurrency: Boolean; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Sales Order.
        SetupForOutstandingSalesOrderReport(SalesLine, CurrencyCode, UnitPrice, PrintAmountInCustCurrency);

        // Exercise.
        REPORT.Run(REPORT::"Outstanding Sales Order Aging");

        // Verify: Verify Customer No., Item No., Amount on Outstanding Sales Order Aging Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(SalesLine."Document No.", LastDocNoCaption, CustomerNoCaption, SalesLine."Sell-to Customer No.");
        VerifyValuesOnReport(SalesLine."Document No.", LastDocNoCaption, SalesLineNoCap, SalesLine."No.");
        VerifyValuesOnReport(
          SalesLine."Document No.", LastDocNoCaption, TotalOutstandingCaption, Round(
            Amount * SalesLine.Quantity, LibraryERM.GetAmountRoundingPrecision(), RoundingDirection));
    end;

    [Test]
    [HandlerFunctions('OutStandingSalesOrderStatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OutStandingSalesOrderStatusReportWithCurrencyTrue()
    var
        CurrencyCode: Code[10];
        UnitPrice: Decimal;
    begin
        // Verify Outstanding Sales Order Status Report With Print Amount in Customer Currency TRUE.
        Initialize();
        CurrencyCode := CreateCurrency();
        UnitPrice := LibraryRandom.RandDec(10, 2);  // Taken random for Unit Price.
        OutStandingSalesOrderStatusReport(CurrencyCode, UnitPrice, false, LibraryERM.ConvertCurrency(UnitPrice, CurrencyCode, '', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('OutStandingSalesOrderStatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OutStandingSalesOrderStatusReportWithCurrencyFalse()
    var
        UnitPrice: Decimal;
    begin
        // Verify Outstanding Sales Order Status Report With Print Amount in Customer Currency FALSE.
        Initialize();
        UnitPrice := LibraryRandom.RandDec(10, 2);
        OutStandingSalesOrderStatusReport(CreateCurrency(), UnitPrice, true, UnitPrice);
    end;

    local procedure OutStandingSalesOrderStatusReport(CurrencyCode: Code[10]; UnitPrice: Decimal; PrintAmountInCustCurrency: Boolean; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Sales Order.
        SetupForOutstandingSalesOrderReport(SalesLine, CurrencyCode, UnitPrice, PrintAmountInCustCurrency);

        // Exercise.
        REPORT.Run(REPORT::"Outstanding Sales Order Status");

        // Verify: Verify Customer No., Item No., Amount on Outstanding Sales Order Status Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(SalesLine."Document No.", SalesHeaderNoCap, CustomerNoCaption, SalesLine."Sell-to Customer No.");
        VerifyValuesOnReport(SalesLine."Document No.", SalesHeaderNoCap, SalesLineNoCap, SalesLine."No.");
        VerifyValuesOnReport(
          SalesLine."Document No.", SalesHeaderNoCap, OutstandingExclTax2Caption, Round(
            Amount * SalesLine.Quantity, LibraryERM.GetAmountRoundingPrecision(), RoundingDirection));
    end;

    [Test]
    [HandlerFunctions('SalespersonStatisticsByInvRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalespersonStatisticsByInvoiceReport()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales person Statistics By Invoice Report after posting Sales Order.

        // Setup: Create Customer, create and post Sales Order.
        Initialize();
        PostSalesOrderWithSalesperson(SalesLine, LibraryRandom.RandDec(10, 2));  // Taken random value for Commission Pct.
        Customer.Get(SalesLine."Sell-to Customer No.");

        // Exercise.
        REPORT.Run(REPORT::"Salesperson Statistics by Inv.");

        // Verify: Verify Document No., Sales Amount and Remaining Amount on Sales person Statistics By Invoice Report.
        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(
          Customer."Salesperson Code", SalespersonPurchaserCodeCaption, CustLedgerEntryDocumentNoCaption, CustLedgerEntry."Document No.");
        VerifyValuesOnReport(
          Customer."Salesperson Code", SalespersonPurchaserCodeCaption, CustLedgerEntrySalesLCYCaption, CustLedgerEntry."Sales (LCY)");
        VerifyValuesOnReport(
          Customer."Salesperson Code", SalespersonPurchaserCodeCaption, CustLedgerEntryRemainingAmtLCYCaption, CustLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('SalespersonCommissionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalespersonCommissionReport()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        CommissionPct: Decimal;
    begin
        // Verify Sales Commission Report after posting Sales Order.

        // Setup: Create Customer with Salesperson Code, create and post Sales Order.
        Initialize();
        CommissionPct := LibraryRandom.RandDec(10, 2);  // Taken random value for Commission Pct.
        PostSalesOrderWithSalesperson(SalesLine, CommissionPct);
        Customer.Get(SalesLine."Sell-to Customer No.");

        // Exercise.
        REPORT.Run(REPORT::"Salesperson Commissions");

        // Verify: Verify Sales Amount, Sales Commission, Profit Commission on Sales Commission Report.
        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(
          Customer."Salesperson Code", SalespersonPurchaserCodeCaption, SalespersonPurchaserCommissionCaption, CommissionPct);
        VerifyValuesOnReport(
          Customer."Salesperson Code", SalespersonPurchaserCodeCaption, CustLedgerEntrySalesLCYCaption, CustLedgerEntry."Sales (LCY)");
        VerifyValuesOnReport(
          Customer."Salesperson Code", SalespersonPurchaserCodeCaption, SalesCommissionCaption, Round(
            CustLedgerEntry."Sales (LCY)" * CommissionPct / 100));
        VerifyValuesOnReport(
          Customer."Salesperson Code", SalespersonPurchaserCodeCaption, ProfitCommissionCaption, Round(
            CustLedgerEntry."Profit (LCY)" * CommissionPct / 100));
    end;

    [Test]
    [HandlerFunctions('ProjectedCashReceiptsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProjectedCashReceiptReportWithCurrencyTrue()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Verify Projected Cash Receipt Report with Print Total in Customer Currency True.

        // Setup and Exercise.
        Initialize();
        ProjectedCashReceiptReport(CustLedgerEntry, true);

        // Verify: Verify Amount on Projected Cash Receipt Report.
        VerifyValuesOnReport(CustLedgerEntry."Customer No.", CustomerNoCaption, CustTotalAmountDue2Caption, CustLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('ProjectedCashReceiptsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProjectedCashReceiptReportWithCurrencyFalse()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Verify Projected Cash Receipt Report with Print Total in Customer Currency False.

        // Setup and Exercise.
        Initialize();
        ProjectedCashReceiptReport(CustLedgerEntry, false);

        // Verify: Verify Amount on Projected Cash Receipt Report.
        VerifyValuesOnReport(CustLedgerEntry."Customer No.", CustomerNoCaption, CustTotalAmountDue2Caption, CustLedgerEntry."Amount (LCY)");
    end;

    local procedure ProjectedCashReceiptReport(var CustLedgerEntry: Record "Cust. Ledger Entry"; PrintTotalInCustomerCurrency: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create and post Sales Order.
        CreateAndPostSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, CreateCustomer(CreateCurrency()), LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity and Unit Price.
        LibraryVariableStorage.Enqueue(SalesLine."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(PrintTotalInCustomerCurrency);  // Enqueue for SalespersonCommissionRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Projected Cash Receipts");

        // Verify: Verify Document No. on Projected Cash Receipt Report
        FindCustLedgerEntry(CustLedgerEntry, SalesLine."Sell-to Customer No.");
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(
          SalesLine."Sell-to Customer No.", CustomerNoCaption, CustLedgerEntryDocumentNoCaption, CustLedgerEntry."Document No.");
    end;

    [Test]
    [HandlerFunctions('DropShipmentStatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DropShipmentStatusReportByCustomer()
    var
        SalesLine: Record "Sales Line";
        Vendor: Record Vendor;
        PurchaseOrderNo: Code[20];
    begin
        // Verify Drop Shipment Report after Get Sales Order and Carryout Action Message on Requisition Line.

        // Setup: Create and modify Sales Order, Get Sales Order and Carryout Action Message on Requisition Line.
        Initialize();
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibraryRandom.RandDec(10, 2), CreateCustomer(''),
          CreateItem(), LibraryRandom.RandDec(10, 2));  // Taken random for Unit Price and Quantity.
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseOrderNo := GetSalesOrderAndCarryoutActionMessage(SalesLine, Vendor."No.");
        LibraryVariableStorage.Enqueue(SalesLine."Document No.");  // Enqueue for DropShipmentStatusRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Drop Shipment Status");

        // Verify: Verify Quantity, Purchase Order No. and Vendor No. on Drop Shipment Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(SalesLine."Document No.", SalesLineDocumentNoCaption, SalesLineQuantityCap, SalesLine.Quantity);
        VerifyValuesOnReport(SalesLine."Document No.", SalesLineDocumentNoCaption, PurchaseLineDocumentNoCaption, PurchaseOrderNo);
        VerifyValuesOnReport(SalesLine."Document No.", SalesLineDocumentNoCaption, PurchaseLineBuyfromVendorNoCaption, Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('JobCreateSalesInvoiceHandler,MessageHandler,OpenSalesInvoicesByJobrequestPageHandler')]
    [Scope('OnPrem')]
    procedure OpenSalesInvoiceByJobReport()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Job: Record Job;
        DocumentNo: Code[20];
    begin
        // Verify Open Sales Invoice By Job Report after posting Sales Invoice.

        // Setup: Create Sales Invoice by Job and post it.
        Initialize();
        CreateSalesInvoiceByJob(Job);
        DocumentNo := FindAndPostSalesInvoice(Job."Bill-to Customer No.");
        LibraryVariableStorage.Enqueue(Job."No.");  // Enqueue for OpenSalesInvoicesByJobrequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Open Sales Invoices by Job");

        // Verify: Verify Job No., Document No., and Amount on Open Sales Invoice By Job Report.
        FindCustLedgerEntry(CustLedgerEntry, Job."Bill-to Customer No.");
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(Job."No.", JobNoCaption, SalesInvoiceLineDocumentNoCaption, DocumentNo);
        VerifyValuesOnReport(Job."No.", JobNoCaption, CustLedgerEntryAmountLCY, CustLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintCustCheckStub()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        InvoiceAmount: Decimal;
        CreditMemoAmount: Decimal;
        ApplyTo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 380266] Check report (1401) must print Credit Memo with amount in case of Invoice and Credit Memo documents

        Initialize();

        LibraryERM.SetAmountRoundingPrecision(0.01);
        ApplyTo := LibraryUTUtility.GetNewCode();
        InvoiceAmount := LibraryRandom.RandDecInDecimalRange(10, 50, 2) * 2;
        CreditMemoAmount := LibraryRandom.RandDecInRange(50, 100, 2) * 2; // credit memo amount should be more then invoice's

        // [GIVEN] Customer, Invoice with Amount = "X", Credit Memo with Amount = "Y"
        CreateBank(BankAccount);
        CreateCustomerWithCheckFormat(Customer, Customer."Check Date Format"::"YYYY MM DD");
        CreatePostCustInvoice(Customer, InvoiceAmount, ApplyTo);
        CreatePostCustCreditMemo(Customer, CreditMemoAmount, ApplyTo);

        // [GIVEN] Payment Journal Line with Amount = "X"-"Y"
        CreateComputerCheckPayment(GenJournalLine, BankAccount,
          GenJournalLine."Account Type"::Customer, Customer."No.",
          CreditMemoAmount - InvoiceAmount,
          ApplyTo);

        // [WHEN] Print Check with Stub
        Commit();
        REPORT.Run(REPORT::Check);

        // [THEN] Verify that Credit Memo amount = "Y" is shown on the Stub
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('LineAmt', CreditMemoAmount);
        LibraryReportDataset.AssertElementWithValueExists('LineAmt', -InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintVendCheckStub()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        InvoiceAmount: Decimal;
        CreditMemoAmount: Decimal;
        ApplyTo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 380266] Check report (1401) must print Credit Memo with amount in case of Invoice and Credit Memo documents
        Initialize();

        LibraryERM.SetAmountRoundingPrecision(0.01);
        ApplyTo := LibraryUTUtility.GetNewCode();
        InvoiceAmount := LibraryRandom.RandDecInDecimalRange(50, 100, 2) * 2;
        CreditMemoAmount := LibraryRandom.RandDecInDecimalRange(10, 50, 2) * 2; // credit memo amount should be less then invoice's

        // [GIVEN] Vendor, Invoice with Amount = "X", Credit Memo with Amount = "Y"
        CreateBank(BankAccount);
        CreateVendorWithCheckFormat(Vendor, Vendor."Check Date Format"::"YYYY MM DD");
        CreatePostVendorInvoice(Vendor, InvoiceAmount, ApplyTo);
        CreatePostVendorCreditMemo(Vendor, CreditMemoAmount, ApplyTo);

        // [GIVEN] Payment Journal Line with Amount = "X"-"Y"
        CreateComputerCheckPayment(GenJournalLine, BankAccount,
          GenJournalLine."Account Type"::Vendor, Vendor."No.",
          InvoiceAmount - CreditMemoAmount,
          ApplyTo);

        // [WHEN] Print Check with Stub
        Commit();
        REPORT.Run(REPORT::Check);

        // [THEN] Verify that Credit Memo amount = "Y" is shown on the Stub
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('LineAmt', -CreditMemoAmount);
        LibraryReportDataset.AssertElementWithValueExists('LineAmt', InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('DropShipmentStatusRequestPageHandler')]
    procedure DropShipmentStatusReportDescription();
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Drop Shipment] [Description]
        // [SCENARIO ] "Drop Shipment Status" Report accepts items with "Description" string of maximal length
        Initialize();

        // [GIVEN] Item with "Description" of maximal length
        LibraryInventory.CreateItem(Item);
        Item.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)));
        Item.Modify(true);

        // [GIVEN] Drop Shipment Sales Order for the Item
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibraryRandom.RandDec(10, 2), CreateCustomer(''),
          Item."No.", LibraryRandom.RandDec(10, 2));  // Taken random for Unit Price and Quantity.
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Modify(true);

        // [GIVEN] Drop Shipment Purchase Order created
        GetSalesOrderAndCarryoutActionMessage(SalesLine, LibraryPurchase.CreateVendorNo());
        LibraryVariableStorage.Enqueue(SalesLine."Document No.");  // Enqueue for DropShipmentStatusRequestPageHandler.

        // [WHEN] Run "Drop Shipment Status" Report
        REPORT.Run(REPORT::"Drop Shipment Status");

        // [THEN] Item Description is fully copied to the dataset
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnReport(SalesLine."Document No.", SalesLineDocumentNoCaption, 'ItemDescription', Item.Description);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryVariableStorage.Clear();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.CreateVATData();
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndModifyCustomerWithSalesPerson(var Customer: Record Customer; CommissionPct: Decimal)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser.Validate("Commission %", CommissionPct);
        SalespersonPurchaser.Modify(true);
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Modify(true);
    end;

    local procedure CreateAndUpdateVATBusPostGrOnCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateAndUpdateVATProdPostGrOnItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateCustomer(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        exit(LibraryInventory.CreateItem(Item));
    end;

    local procedure CreateJobAndJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJob(Job, CreateCustomer(''));
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobPlanningLine(JobTask: Record "Job Task")
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        LibraryJob: Codeunit "Library - Job";
    begin
        // Use Random values for Quantity and Unit Cost because values are not important.
        LibraryResource.CreateResourceNew(Resource);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeBoth(), LibraryJob.ResourceType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Resource."No.");
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity because value is not important.
        JobPlanningLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Cost because value is not important.
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateVendorWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Quantity: Decimal; CustomerNo: Code[20]; ItemNo: Code[20]; UnitPrice: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesLine, DocumentType, Quantity, CustomerNo, CreateItem(), UnitPrice);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseDocument(ItemNo: Code[20]; CurrencyCode: Code[10]; ToInvoice: Boolean; DocumentType: Enum "Purchase Document Type"; Quantity: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(PurchaseHeader, ItemNo, CurrencyCode, DocumentType, Quantity);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, ToInvoice));
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; CurrencyCode: Code[10]; DocumentType: Enum "Purchase Document Type"; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendorWithCurrency(CurrencyCode));
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryUtility.FillFieldMaxText(PurchaseHeader, PurchaseHeader.FieldNo("Vendor Invoice No."));
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Taken random for Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseDocumentForInventoryValue(ItemNo: Code[20]; CurrencyCode: Code[10]; ToInvoice: Boolean; DocumentType: Enum "Purchase Document Type"; Quantity: Decimal; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocumentForInventoryValue(PurchaseHeader, ItemNo, CurrencyCode, DocumentType, Quantity, DirectUnitCost);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, ToInvoice));
    end;

    local procedure CreatePurchaseDocumentForInventoryValue(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; CurrencyCode: Code[10]; DocumentType: Enum "Purchase Document Type"; Quantity: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendorWithCurrency(CurrencyCode));
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryUtility.FillFieldMaxText(PurchaseHeader, PurchaseHeader.FieldNo("Vendor Invoice No."));
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceByJob(var Job: Record Job)
    var
        JobTask: Record "Job Task";
    begin
        CreateJobAndJobTask(JobTask);
        CreateJobPlanningLine(JobTask);
        RunJobCreateSalesInvoice(JobTask);
        Job.Get(JobTask."Job No.");
    end;

    local procedure CreateAndPostInvoiceAndRunReportVendorListing(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; PrintAmountsInVendorCurrency: Boolean; VendWithBalancesOnly: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Invoice with Currency.
        DocumentNo := CreateAndPostPurchaseDocument(
            LibraryInventory.CreateItem(Item),
            CreateCurrency(), true, PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandDec(100, 2));  // Use random value for Quantity.
        FindVendorLedgerEntry(VendorLedgerEntry, DocumentNo);
        EnqueueValuesForVendorListingReport(
          StrSubstNo(Filter, VendorNo, VendorLedgerEntry."Vendor No."), PrintAmountsInVendorCurrency, VendWithBalancesOnly);

        // Exercise: Run report Vendor Listing.
        REPORT.Run(REPORT::"Vendor - Listing");
    end;

    local procedure CreateAndPostInvoiceAndRunReportCashReqtByDueDate(var VendorLedgerEntry: Record "Vendor Ledger Entry"; UseExternalDocNo: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Purchase Invoice.
        CreatePurchaseDocument(
          PurchaseHeader,
          LibraryInventory.CreateItem(Item), '', PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandDec(100, 2));  // Take random for Quantity.
        PurchaseHeader.Validate("Payment Discount %", LibraryRandom.RandIntInRange(0, 100));  // Take random for Payment Discount %.
        PurchaseHeader.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        FindVendorLedgerEntry(VendorLedgerEntry, DocumentNo);
        EnqueueValuesForCashReqtByDueDate(
          PurchaseHeader."Buy-from Vendor No.",
          PurchaseHeader."Purchaser Code", true, UseExternalDocNo, PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."Due Date");

        // Exercise: Run report Cash Requirement By Due Date.
        REPORT.Run(REPORT::"Cash Requirements by Due Date");
    end;

    local procedure CreateBank(var BankAccount: Record "Bank Account")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateBankAccountLastCheckNo(BankAccount);
        CreatePaymentGeneralBatch(GenJournalBatch);
        LibraryVariableStorage.Enqueue(BankAccount."No.");  // Enqueue value for Request Page handler
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account")
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Bank Acc. Posting Group", FindBankAccPostingGroup());
        BankAccount.Modify(true);
    end;

    local procedure CreateBankAccountLastCheckNo(var BankAccount: Record "Bank Account")
    begin
        CreateBankAccount(BankAccount);
        BankAccount.Validate(
          "Last Check No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Last Check No."), DATABASE::"Bank Account"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Bank Account", BankAccount.FieldNo("Last Check No."))));
        BankAccount.Modify(true);
    end;

    local procedure CreateCustomerWithCheckFormat(var Customer: Record Customer; CheckDateFormat: Option)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."Check Date Format" := CheckDateFormat;
        Customer.Modify(true);
    end;

    local procedure CreateVendorWithCheckFormat(var Vendor: Record Vendor; CheckDateFormat: Option)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Check Date Format" := CheckDateFormat;
        Vendor.Modify(true);
    end;

    local procedure CreateComputerCheckPayment(var GenJournalLine: Record "Gen. Journal Line"; BankAccount: Record "Bank Account"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PaymentAmount: Decimal; ApplyTo: Code[20])
    begin
        CreateGenJournal(GenJournalLine, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo,
          PaymentAmount);

        UpdateGenJournalLineWithBankAccount(GenJournalLine, BankAccount, GenJournalLine."Bank Payment Type"::"Computer Check");
        UpdateGeneralJournalLine(GenJournalLine, ApplyTo, false, '');

        // Enqueue value for Request Page handler
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
    end;

    local procedure CreateGenJournal(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreatePaymentGeneralBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreatePostVendorInvoice(Vendor: Record Vendor; InvoiceAmount: Decimal; ApplyTo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        CreatePaymentGeneralBatch(GenJournalBatch);
        LibraryERM.FindBankAccount(BankAccount);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, Vendor."No.",
          -InvoiceAmount);
        UpdateGenJournalLineWithBankAccount(GenJournalLine, BankAccount, GenJournalLine."Bank Payment Type"::" ");
        GenJournalLine."External Document No." :=
          CopyStr(
            LibraryRandom.RandText(MaxStrLen(GenJournalLine."External Document No.")), 1,
            MaxStrLen(GenJournalLine."External Document No."));
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        UpdateVendLedgerEntryWithApplyTo(Vendor."No.", ApplyTo);
    end;

    local procedure CreatePostCustInvoice(Customer: Record Customer; InvoiceAmount: Decimal; ApplyTo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        CreatePaymentGeneralBatch(GenJournalBatch);
        LibraryERM.FindBankAccount(BankAccount);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.",
          InvoiceAmount);
        UpdateGenJournalLineWithBankAccount(GenJournalLine, BankAccount, GenJournalLine."Bank Payment Type"::" ");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        UpdateCustLedgerEntryWithApplyTo(Customer."No.", ApplyTo);
    end;

    local procedure CreatePostVendorCreditMemo(Vendor: Record Vendor; CreditMemoAmount: Decimal; ApplyTo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        CreatePaymentGeneralBatch(GenJournalBatch);
        LibraryERM.FindBankAccount(BankAccount);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, Vendor."No.",
          CreditMemoAmount);
        UpdateGenJournalLineWithBankAccount(GenJournalLine, BankAccount, GenJournalLine."Bank Payment Type"::" ");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        UpdateVendLedgerEntryWithApplyTo(Vendor."No.", ApplyTo);
    end;

    local procedure CreatePostCustCreditMemo(Customer: Record Customer; CreditMemoAmount: Decimal; ApplyTo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        CreatePaymentGeneralBatch(GenJournalBatch);
        LibraryERM.FindBankAccount(BankAccount);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, Customer."No.",
          -CreditMemoAmount);
        UpdateGenJournalLineWithBankAccount(GenJournalLine, BankAccount, GenJournalLine."Bank Payment Type"::" ");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        UpdateCustLedgerEntryWithApplyTo(Customer."No.", ApplyTo);
    end;

    local procedure FindBankAccPostingGroup(): Code[20]
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        RecRef: RecordRef;
    begin
        BankAccountPostingGroup.Init();
        RecRef.GetTable(BankAccountPostingGroup);
        LibraryUtility.FindRecord(RecRef);
        RecRef.SetTable(BankAccountPostingGroup);
        exit(BankAccountPostingGroup.Code);
    end;

    local procedure FilterOnReportCheckRequestPage(var Check: TestRequestPage Check; ReprintChecks: Boolean; OneCheckPerVendorPerDocumentNo: Boolean)
    var
        BankAccount: Variant;
        JournalBatchName: Variant;
        JournalTemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccount);
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        Check.VoidGenJnlLine.SetFilter("Journal Template Name", JournalTemplateName);
        Check.VoidGenJnlLine.SetFilter("Journal Batch Name", JournalBatchName);
        Check.ReprintChecks.SetValue(ReprintChecks);
        Check.OneCheckPerVendorPerDocumentNo.SetValue(OneCheckPerVendorPerDocumentNo);
        Check.BankAccount.SetValue(BankAccount);
    end;

    local procedure UpdateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AppliesToID: Code[50]; CheckPrinted: Boolean; AppliesToDocNo: Code[20])
    begin
        GenJournalLine."Applies-to ID" := AppliesToID;
        GenJournalLine."Check Printed" := CheckPrinted;
        GenJournalLine."Applies-to Doc. No." := AppliesToDocNo;
        GenJournalLine.Modify();
    end;

    local procedure UpdateGenJournalLineWithBankAccount(var GenJournalLine: Record "Gen. Journal Line"; BankAccount: Record "Bank Account"; BankPaymentType: Enum "Bank Payment Type")
    begin
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Bank Payment Type", BankPaymentType);
        GenJournalLine.Modify(true);
    end;

    [Normal]
    local procedure UpdateCustLedgerEntryWithApplyTo(CustomerNo: Code[20]; ApplyTo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindLast();
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.Validate("Applies-to ID", ApplyTo);
        CustLedgerEntry.Validate("Amount to Apply", CustLedgerEntry."Remaining Amount");
        CustLedgerEntry.Modify(true);
    end;

    [Normal]
    local procedure UpdateVendLedgerEntryWithApplyTo(VendorNo: Code[20]; ApplyTo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindLast();
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.Validate("Applies-to ID", ApplyTo);
        VendorLedgerEntry.Validate("Amount to Apply", VendorLedgerEntry."Remaining Amount");
        VendorLedgerEntry.Modify(true);
    end;

    local procedure EnqueueValuesForCustAccountDetailReport(No: Text[50]; PrintAmtInCustCurrency: Boolean; NewPagePerAccount: Boolean; AccWithBalanceOnly: Boolean)
    begin
        LibraryVariableStorage.Enqueue(No);
        LibraryVariableStorage.Enqueue(PrintAmtInCustCurrency);
        LibraryVariableStorage.Enqueue(NewPagePerAccount);
        LibraryVariableStorage.Enqueue(AccWithBalanceOnly);
    end;

    local procedure EnqueueValuesForTopInventoryItemsReport(ItemNo: Code[20]; ItemNo2: Code[20]; TopSorting: Option; TopType: Option)
    var
        ItemFilter: Text[50];
    begin
        // Enqueue value for TopInventoryItemsReportHandler.
        ItemFilter := StrSubstNo(Filter, ItemNo, ItemNo2);
        LibraryVariableStorage.Enqueue(ItemFilter);
        LibraryVariableStorage.Enqueue(TopSorting);
        LibraryVariableStorage.Enqueue(TopType);
    end;

    local procedure EnqueueValuesForReturnShipmentReport(No: Code[20]; PrintCompanyAddress: Boolean; LogInteraction: Boolean)
    begin
        // Enqueue value for ReturnShipmentRequestPageHandler.
        LibraryVariableStorage.Enqueue(No);
        LibraryVariableStorage.Enqueue(PrintCompanyAddress);
        LibraryVariableStorage.Enqueue(LogInteraction);
    end;

    local procedure EnqueueValuesForVendorListingReport(VendorNo: Code[250]; PrintAmountsInVendorCurrency: Boolean; VendWithBalancesOnly: Boolean)
    begin
        // Enqueue value for VendorListingRequestPageHandler.
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(PrintAmountsInVendorCurrency);
        LibraryVariableStorage.Enqueue(VendWithBalancesOnly);
    end;

    local procedure EnqueueValuesForCashReqtByDueDate(VendorNo: Code[20]; PurchaserCode: Code[20]; PrintDetails: Boolean; UseExternalDocNo: Boolean; DocumentType: Option; DueDate: Date)
    begin
        // Enqueue value for CashReqtByDueDateRequestPageHandler.
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(PrintDetails);
        LibraryVariableStorage.Enqueue(UseExternalDocNo);
        LibraryVariableStorage.Enqueue(DocumentType);
        LibraryVariableStorage.Enqueue(PurchaserCode);
        LibraryVariableStorage.Enqueue(DueDate);
    end;

    local procedure FindAndPostSalesInvoice(BillToCustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Bill-to Customer No.", BillToCustomerNo);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.FindFirst();
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure FindCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindSet();
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure FindAndModifyRequisitionLine(var RequisitionLine: Record "Requisition Line"; JournalBatchName: Code[10]; VendorNo: Code[20])
    begin
        RequisitionLine.SetRange("Journal Batch Name", JournalBatchName);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Modify(true);
    end;

    local procedure GetSalesOrderAndCarryoutActionMessage(SalesLine: Record "Sales Line"; VendorNo: Code[20]) OrderNo: Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        NoSeries: Codeunit "No. Series";
        RetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, RetrieveDimensionsFrom::Item);
        FindAndModifyRequisitionLine(RequisitionLine, RequisitionWkshName.Name, VendorNo);
        PurchasesPayablesSetup.Get();
        OrderNo := NoSeries.PeekNextNo(PurchasesPayablesSetup."Order Nos.");
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure ModifySalesHeader(var SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalespersonCode: Code[20])
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.Validate("Salesperson Code", SalespersonCode);
        SalesHeader.Modify(true);
    end;

    local procedure PostSalesOrderWithSalesperson(var SalesLine: Record "Sales Line"; CommissionPct: Decimal)
    var
        Customer: Record Customer;
    begin
        CreateAndModifyCustomerWithSalesPerson(Customer, CommissionPct);
        CreateAndPostSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, Customer."No.", LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity and Unit Price.
        LibraryVariableStorage.Enqueue(Customer."Salesperson Code");  // Enqueue for various Request Page Handler.
    end;

    local procedure ReturnShipmentReport(NameOfCompany: Text[100]; PrintCompanyAddress: Boolean; LogInteraction: Boolean; ActualLogInteraction: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Purchase Return Order.
        DocumentNo := CreateAndPostPurchaseDocument(
            LibraryInventory.CreateItem(Item), '', false, PurchaseHeader."Document Type"::"Return Order", LibraryRandom.RandDec(10, 2));  // Use random value for Quantity.
        EnqueueValuesForReturnShipmentReport(DocumentNo, PrintCompanyAddress, LogInteraction);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindFirst();

        // Exercise.
        REPORT.Run(REPORT::"Return Shipment");

        // Verify: Verify Return Shipment report with Print Company and Log Interaction.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CompanyNameCap, NameOfCompany);
        LibraryReportDataset.AssertElementWithValueExists(ItemNumberToPrintCap, ItemLedgerEntry."Item No.");
        LibraryReportDataset.AssertElementWithValueExists(QtyReturnShipmentLineCap, Abs(ItemLedgerEntry.Quantity));
        VerifyLogInteraction(DocumentNo, ActualLogInteraction);
    end;

    local procedure RunDailyInvoicingReport(IncludeInvoice: Boolean; IncludeCreditMemo: Boolean; CustomerFilter: Text[50])
    begin
        LibraryVariableStorage.Enqueue(IncludeInvoice);
        LibraryVariableStorage.Enqueue(IncludeCreditMemo);
        LibraryVariableStorage.Enqueue(CustomerFilter);
        Commit();  // COMMIT required to run the Report.
        REPORT.Run(REPORT::"Daily Invoicing Report");
    end;

    local procedure RunJobCreateSalesInvoice(JobTask: Record "Job Task")
    var
        JobCreateSalesInvoice: Report "Job Create Sales Invoice";
    begin
        Commit();  // Commit required for batch report.
        JobTask.SetRange("Job No.", JobTask."Job No.");
        JobTask.SetRange("Job Task No.", JobTask."Job Task No.");
        Clear(JobCreateSalesInvoice);
        JobCreateSalesInvoice.SetTableView(JobTask);
        JobCreateSalesInvoice.Run();
    end;

    local procedure SelectAndPostItemJournal(var ItemJournalLine: Record "Item Journal Line"; Quantity: Decimal)
    var
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::"Phys. Inventory");
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", LibraryInventory.CreateItem(Item), Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure SetupForOutstandingSalesOrderReport(var SalesLine: Record "Sales Line"; CurrencyCode: Code[10]; UnitPrice: Decimal; PrintAmountInCustCurrency: Boolean)
    begin
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, LibraryRandom.RandDec(10, 2),
          CreateCustomer(CurrencyCode), CreateItem(), UnitPrice);
        LibraryVariableStorage.Enqueue(PrintAmountInCustCurrency);
        LibraryVariableStorage.Enqueue(SalesLine."Sell-to Customer No.");  // Enqueue for various Request Page Handler.
        Commit();  // COMMIT required to run the Report.
    end;

    local procedure VerifyValuesOnReport(RowValue: Variant; RowCaption: Text[50]; ValueCaption: Text[50]; Value: Variant)
    begin
        LibraryReportDataset.SetRange(RowCaption, RowValue);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(ValueCaption, Value);
    end;

    local procedure VerifyLogInteraction(DocumentNo: Code[20]; ActualLogInteraction: Boolean)
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        ExpLogInteraction: Boolean;
    begin
        InteractionLogEntry.SetRange("Document No.", DocumentNo);
        ExpLogInteraction := InteractionLogEntry.IsEmpty();
        Assert.AreEqual(ExpLogInteraction, ActualLogInteraction, ValueMustMatch)
    end;

    local procedure VerifyCashRequirementByDueDate(VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[35]; UseExternalDocNo: Boolean)
    begin
        LibraryReportDataset.AssertElementWithValueExists(PrintDetailCap, true);
        LibraryReportDataset.AssertElementWithValueExists(UseExternalDocNoCap, UseExternalDocNo);
        VerifyValuesOnReport(VendorLedgerEntry."Vendor No.", VendorLedgerEntryVendorNoCap, DocNoCap, DocumentNo);
        LibraryReportDataset.AssertCurrentRowValueEquals(PaymentDiscToPrintCap, Abs(VendorLedgerEntry."Original Pmt. Disc. Possible"));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerAccountDetailRequestPageHandler(var CustomerAccountDetail: TestRequestPage "Customer Account Detail")
    var
        No: Variant;
        PrintAmtInCustCurrency: Variant;
        NewPagePerAccount: Variant;
        AccWithBalanceOnly: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrintAmtInCustCurrency);
        LibraryVariableStorage.Dequeue(NewPagePerAccount);
        LibraryVariableStorage.Dequeue(AccWithBalanceOnly);
        CustomerAccountDetail.PrintAmountsInLocal.SetValue(PrintAmtInCustCurrency);  // Setting value for PrintAmtInCustCurrency.
        CustomerAccountDetail.OnlyOnePerPage.SetValue(NewPagePerAccount);  // Setting value for NewPagePerAccount.
        CustomerAccountDetail.AllHavingBalance.SetValue(AccWithBalanceOnly);  // Setting value for AccWithBalanceOnly.
        CustomerAccountDetail.Customer.SetFilter("No.", No);
        CustomerAccountDetail.Customer.SetFilter("Date Filter", Format(WorkDate()));
        CustomerAccountDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CashReqtByDueDateRequestPageHandler(var CashRequiremByDueDate: TestRequestPage "Cash Requirements by Due Date")
    var
        VendorNo: Variant;
        PrintDetails: Variant;
        UseExternalDocNo: Variant;
        DocumentType: Variant;
        PurchaserCode: Variant;
        DueDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(PrintDetails);
        LibraryVariableStorage.Dequeue(UseExternalDocNo);
        LibraryVariableStorage.Dequeue(DocumentType);
        LibraryVariableStorage.Dequeue(PurchaserCode);
        LibraryVariableStorage.Dequeue(DueDate);
        CashRequiremByDueDate.PrintDetail.SetValue(PrintDetails);
        CashRequiremByDueDate.UseExternalDocNo.SetValue(UseExternalDocNo);
        CashRequiremByDueDate."Vendor Ledger Entry".SetFilter("Vendor No.", VendorNo);
        CashRequiremByDueDate."Vendor Ledger Entry".SetFilter("Due Date", Format(DueDate));
        CashRequiremByDueDate."Vendor Ledger Entry".SetFilter("Document Type", Format(DocumentType));
        CashRequiremByDueDate."Vendor Ledger Entry".SetFilter("Purchaser Code", PurchaserCode);
        CashRequiremByDueDate.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerItemStatisticsRequestPageHandler(var CustomerItemStatistics: TestRequestPage "Customer/Item Statistics")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CustomerItemStatistics.Customer.SetFilter("No.", No);
        CustomerItemStatistics.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustItemStatBySalespersRequestPageHandler(var CustItemStatBySalespers: TestRequestPage "Cust./Item Stat. by Salespers.")
    var
        "Code": Variant;
        SalespersonToUse: Option "Assigned To Customer","Assigned To Sales Order";
    begin
        LibraryVariableStorage.Dequeue(Code);
        CustItemStatBySalespers.SalespersonToUse.SetValue(SalespersonToUse::"Assigned To Customer");
        CustItemStatBySalespers."Salesperson/Purchaser".SetFilter(Code, Code);
        CustItemStatBySalespers.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DailyInvoicingRequestPageHandler(var DailyInvoicingReport: TestRequestPage "Daily Invoicing Report")
    var
        IncludeInvoice: Variant;
        IncludeCreditMemo: Variant;
        SellToCustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(IncludeInvoice);
        LibraryVariableStorage.Dequeue(IncludeCreditMemo);
        LibraryVariableStorage.Dequeue(SellToCustomerNo);
        DailyInvoicingReport.IncludeInvoices.SetValue(IncludeInvoice);
        DailyInvoicingReport.IncludeCreditMemos.SetValue(IncludeCreditMemo);
        DailyInvoicingReport."Sales Invoice Header".SetFilter("Sell-to Customer No.", SellToCustomerNo);
        DailyInvoicingReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DropShipmentStatusRequestPageHandler(var DropShipmentStatus: TestRequestPage "Drop Shipment Status")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        DropShipmentStatus."Sales Line".SetFilter("Document No.", DocumentNo);
        DropShipmentStatus.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemStatusBySalespersonRequestPageHandler(var ItemStatusBySalesperson: TestRequestPage "Item Status by Salesperson")
    var
        "Code": Variant;
        ItemNo: Variant;
        PostingDate: Variant;
    begin
        ItemStatusBySalesperson.OnlyOnePerPage.SetValue(true);
        LibraryVariableStorage.Dequeue(Code);
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(PostingDate);
        ItemStatusBySalesperson."Value Entry".SetFilter("Item No.", ItemNo);
        ItemStatusBySalesperson."Value Entry".SetFilter("Posting Date", Format(PostingDate));
        ItemStatusBySalesperson."Salesperson/Purchaser".SetFilter(Code, Code);
        ItemStatusBySalesperson.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobCreateSalesInvoiceHandler(var JobCreateSalesInvoice: TestRequestPage "Job Create Sales Invoice")
    begin
        JobCreateSalesInvoice.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OutstandingSalesOrderAgingRequestPageHandler(var OutstandingSalesOrderAging: TestRequestPage "Outstanding Sales Order Aging")
    var
        No: Variant;
        PrintAmountInCustCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(PrintAmountInCustCurrency);
        LibraryVariableStorage.Dequeue(No);
        OutstandingSalesOrderAging.PrintAmountsInCustCurrency.SetValue(PrintAmountInCustCurrency);
        OutstandingSalesOrderAging.Customer.SetFilter("No.", No);
        OutstandingSalesOrderAging.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OutStandingSalesOrderStatusRequestPageHandler(var OutstandingSalesOrderStatus: TestRequestPage "Outstanding Sales Order Status")
    var
        No: Variant;
        PrintAmountInCustCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(PrintAmountInCustCurrency);
        LibraryVariableStorage.Dequeue(No);
        OutstandingSalesOrderStatus.PrintAmountsInCustCurrency.SetValue(PrintAmountInCustCurrency);
        OutstandingSalesOrderStatus.Customer.SetFilter("No.", No);
        OutstandingSalesOrderStatus.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OpenSalesInvoicesByJobrequestPageHandler(var OpenSalesInvoicesbyJob: TestRequestPage "Open Sales Invoices by Job")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        OpenSalesInvoicesbyJob.Job.SetFilter("No.", No);
        OpenSalesInvoicesbyJob.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProjectedCashReceiptsRequestPageHandler(var ProjectedCashReceipts: TestRequestPage "Projected Cash Receipts")
    var
        PrintTotalInCustomerCurrency: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrintTotalInCustomerCurrency);
        ProjectedCashReceipts.PrintTotalsInCustomersCurrency.SetValue(PrintTotalInCustomerCurrency);
        ProjectedCashReceipts.PrintDetail.SetValue(true);
        ProjectedCashReceipts.Customer.SetFilter("No.", No);
        ProjectedCashReceipts.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReturnShipmentRequestPageHandler(var ReturnShipment: TestRequestPage "Return Shipment")
    var
        No: Variant;
        PrintCompanyAddress: Variant;
        LogInteraction: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrintCompanyAddress);
        LibraryVariableStorage.Dequeue(LogInteraction);
        ReturnShipment.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        ReturnShipment.LogInteraction.SetValue(LogInteraction);
        ReturnShipment."Return Shipment Header".SetFilter("No.", No);
        ReturnShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalespersonCommissionRequestPageHandler(var SalespersonCommissions: TestRequestPage "Salesperson Commissions")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        SalespersonCommissions.NewPagePerSalesperson.SetValue(false);
        SalespersonCommissions."Salesperson/Purchaser".SetFilter(Code, Code);
        SalespersonCommissions.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalespersonStatisticsByInvRequestPageHandler(var SalespersonStatisticsByInv: TestRequestPage "Salesperson Statistics by Inv.")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        SalespersonStatisticsByInv.PrintDetail.SetValue(false);
        SalespersonStatisticsByInv."Salesperson/Purchaser".SetFilter(Code, Code);
        SalespersonStatisticsByInv.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesDocumentTestRequestPageHandler(var SalesDocumentTest: TestRequestPage "Sales Document - Test")
    var
        DocumentType: Variant;
        No: Variant;
        DocumentType2: Option;
    begin
        LibraryVariableStorage.Dequeue(DocumentType);
        LibraryVariableStorage.Dequeue(No);
        DocumentType2 := DocumentType;
        SalesDocumentTest."Sales Header".SetFilter("Document Type", Format(DocumentType2));
        SalesDocumentTest."Sales Header".SetFilter("No.", No);
        SalesDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ShipToAddressListingRequestPageHandler(var ShipToAddressListing: TestRequestPage "Ship-To Address Listing")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ShipToAddressListing.Customer.SetFilter("No.", No);
        ShipToAddressListing.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TopInventoryItemsRequestPageHandler(var TopInventoryItems: TestRequestPage "Top __ Inventory Items")
    var
        ItemFilter: Variant;
        TopSortingValue: Variant;
        TopTypeValue: Variant;
        TopSortingOption: Option;
        TopTypeOption: Option;
        TopSortingString: Option Largest,Smallest;
        TopTypeString: Option Sales,"Qty on Hand","Inventory Value";
    begin
        LibraryVariableStorage.Dequeue(ItemFilter);
        LibraryVariableStorage.Dequeue(TopSortingValue);
        TopSortingOption := TopSortingValue;
        LibraryVariableStorage.Dequeue(TopTypeValue);
        TopTypeOption := TopTypeValue;
        case TopSortingOption of
            TopSortingString::Smallest:
                TopInventoryItems.TopSorting.SetValue(TopSortingString::Smallest);
            TopSortingString::Largest:
                TopInventoryItems.TopSorting.SetValue(TopSortingString::Largest);
        end;
        case TopTypeOption of
            TopTypeString::"Qty on Hand":
                TopInventoryItems.TopType.SetValue(TopTypeString::"Qty on Hand");
            TopTypeString::Sales:
                TopInventoryItems.TopType.SetValue(TopTypeString::Sales);
            TopTypeString::"Inventory Value":
                TopInventoryItems.TopType.SetValue(TopTypeString::"Inventory Value");
        end;
        TopInventoryItems.Item.SetFilter("No.", ItemFilter);
        TopInventoryItems.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorListingRequestPageHandler(var VendorListing: TestRequestPage "Vendor - Listing")
    var
        VendorNo: Variant;
        PrintAmountsInVendorCurrency: Variant;
        VendWithBalancesOnly: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(PrintAmountsInVendorCurrency);
        LibraryVariableStorage.Dequeue(VendWithBalancesOnly);
        VendorListing.PrintAmountsinVendorsCurrency.SetValue(PrintAmountsInVendorCurrency);
        VendorListing.VendwithBalancesOnly.SetValue(VendWithBalancesOnly);
        VendorListing.Vendor.SetFilter("No.", VendorNo);
        VendorListing.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CheckRequestPageHandler(var Check: TestRequestPage Check)
    begin
        FilterOnReportCheckRequestPage(Check, false, false);  // Reprint Checks - FALSE, One Check Per Vendor Per Document No - FALSE.
        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

