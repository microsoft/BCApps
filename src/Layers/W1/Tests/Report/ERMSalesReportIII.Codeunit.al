codeunit 134984 "ERM Sales Report III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report][Sales]
    end;

    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        FileManagement: Codeunit "File Management";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        RecordErr: Label '%1 must exist.', Comment = '%1 = Table Name';
        HeaderDimensionTxt: Label '%1%2%3', Locked = true;
        TotalLCYTxt: Label 'Total (LCY)';
        TotalCapTxt: Label 'Total';
        PrepaymentPostErr: Label '%1 must be completely preinvoiced before you can ship or invoice the line.', Comment = '%1=Field Caption';
        CustBalanceCustLedgEntryTxt: Label 'CustBalance_CustLedgEntryHdrFooter';
        DocEntryTableNameTxt: Label 'DocEntryTableName';
        DocEntryNoofRecordsTxt: Label 'DocEntryNoofRecords';
        CrMemoPostingDtTxt: Label 'PostDt_SalesCrMemoHeader';
        CrMemoAmtTxt: Label 'Amt_SalesCrMemoHeader';
        InvPostingDtTxt: Label 'PostDate_SalesInvHeader';
        InvAmtTxt: Label 'Amt_SalesInvHeader';
        WarningTxt: Label 'Warning!';
        EntriesExistTxt: Label 'true';
        TotalTxt: Label 'total';
        AgingBy: Option "Due Date","Posting Date","Document Date";
        HeadingType: Option "Date Interval","Number of Days";
        isInitialized: Boolean;
        ReportStandardSalesCreditMemoErr: Label 'File of report Standard Sales - Credit Memo not found.';
        WrongExchRateErr: Label 'Wrong exchange rate.';
        VALExchRateTok: Label 'VALExchRate';
        VATIdentifierTok: Label 'VATAmountLine__VAT_Identifier__Control241';
        EnterDateFormulaErr: Label 'Enter a date formula in the Period Length field.';
        RowPrintedMultiplyErr: Label 'Analysis row must be printed only once.';
        RunReportNotSupportedErr: Label 'The method RunReport is not supported for TestPages';
        Rep1302DatasetErr: Label 'Wrong REP1302 "Standard Sales - Pro Forma Inv" dataset.';
        PurchaseOrderNoLbl: Label 'Purchase Order No.';
        OurDocumentNoLbl: Label 'Our Document No.';
        ExpectedCellValueErr: Label 'Cell value expected.';

    [Test]
    [HandlerFunctions('RHBlanketSalesOrder')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrder()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        // Check Blanket Sales Order Report without any Option.

        // Setup: Create Blanket Sales Order.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order", Customer."No.", '');

        // Exercise: Save Blanket Sales Order Report.
        SaveBlanketSalesOrder(SalesLine."Document No.", false);
        LibraryReportDataset.LoadDataSetFile();

        // Verify: Verify Saved Report.
        LibraryReportDataset.SetRange('No_SalesLine', SalesLine."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalSalesLineAmount', SalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('RHBlanketSalesOrder')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderInternalInfo()
    var
        DimensionValue: Record "Dimension Value";
        SalesLine: Record "Sales Line";
    begin
        // Check Blanket Sales Order Report with Dimension.

        // Setup: Create Sales Blanket Order with Dimension.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order", CreateCustomerWithDimension(DimensionValue), '');

        // Exercise.
        SaveBlanketSalesOrder(SalesLine."Document No.", true);

        // Verify: Verify Report Data with Dimension.
        LibraryReportDataset.LoadDataSetFile();
        VerifyInternalInformation(DimensionValue, ' ');
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestWithReceive()
    var
        SalesLine: Record "Sales Line";
    begin
        // Check Sales Document Test Report with Ship Option.
        Initialize();
        SetupSalesDocumentTest(SalesLine, true, false);
        VerifySalesDocumentTestSalesLine(SalesLine);
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestWithInvoice()
    var
        SalesLine: Record "Sales Line";
    begin
        // Check Sales Document Test Report with Ship and Invoice Option.
        Initialize();
        SetupSalesDocumentTest(SalesLine, true, true);
        VerifySalesDocumentTestSalesLine(SalesLine);

        // Verify: Verify Report Data.
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___Qty__to_Invoice_', SalesLine."Qty. to Invoice");
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestWithDimension()
    var
        DimensionValue: Record "Dimension Value";
        SalesLine: Record "Sales Line";
    begin
        // Check Sales Document Test Report with Show Dimension Option.

        // Setup: Crate Sales Order with Dimension.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, CreateCustomerWithDimension(DimensionValue), '');

        // Exercise.
        SaveSalesDocumentTest(SalesLine."Document No.", false, false, true, false);

        // Verify: Verify Report Data with Dimension.
        LibraryReportDataset.LoadDataSetFile();
        VerifyInternalInformation(DimensionValue, ' - ');
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestItemCharge()
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ItemCharge: Record "Item Charge";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // Check Sales Document Test Report with Item Charge Option.

        // Setup: Crate Sales Order and Item Charge Sales Line.
        Initialize();
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order, Customer."No.", '');

        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandDec(10, 2));
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.", SalesLine."No.");

        // Exercise.
        SaveSalesDocumentTest(SalesLine."Document No.", false, false, false, true);

        // Verify: Verify Report Data.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Item_Charge_Assignment__Sales___Item_No__', ItemCharge."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Item_Charge_Assignment__Sales___Qty__to_Assign_', SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestForCreditMemo()
    var
        SalesLine: Record "Sales Line";
    begin
        // Check Sales Document Test Report for Invoice Discount on Credit Memo.

        // Setup: Update New No. Series in Sales and Receivables Setup.
        Initialize();
        SetupSalesAndReceivablesSetup(LibraryUtility.GetGlobalNoSeriesCode());
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", SetupInvoiceDiscount(), '');
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
        SalesLine.Get(SalesLine."Document Type"::"Credit Memo", SalesLine."Document No.", SalesLine."Line No.");

        // Exercise.
        SaveSalesDocumentTest(SalesLine."Document No.", false, false, false, false);

        // Verify: Verify Report Data for Invoice Discount and other column values.
        LibraryReportDataset.LoadDataSetFile();
        VerifyInvoiceDiscountInReport(SalesLine);
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocTestForCreditMemoInvDiscAmt()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales Document - Test]
        // [SCENARIO 363729] When printing the Sales Document - Test Report the invoice discount is displayed
        Initialize();

        // [GIVEN] Sales & Receivables Setup option "Calc. Inv. Discount" is set to YES
        UpdateSalesReceivablesSetupCalcInvDisc(true);

        // [GIVEN] Sales Credit Memo with Invoice Discount Amount = "X"
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", CreateCustomer(), '');

        // [WHEN] Run Sales Document - Test Report
        RunSalesCreditMemoTestReport(SalesLine."Document No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Invoice Discount Amount "X" is shown on the report
        VerifyInvoiceDiscountInReport(SalesLine);
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestWithVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Check Sales Document Test Report with VAT on Credit Memo.

        // Setup: Update Sales Receivables Setup and Create Sales Credit Memo. Calculate VAT Amount Lines.
        Initialize();
        SetupSalesAndReceivablesSetup(LibraryUtility.GetGlobalNoSeriesCode());
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", CreateCustomer(), '');
        SalesHeader.Get(SalesLine."Document Type"::"Credit Memo", SalesLine."Document No.");
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);

        // Exercise.
        SaveSalesDocumentTest(SalesLine."Document No.", false, false, false, false);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyVATEntries('VATAmountLine__VAT_Identifier_', 'VATAmountLine__VAT___', 'VATAmountLine__VAT_Base_',
          'VATAmountLine__Line_Amount_', 'VATAmountLine__Inv__Disc__Base_Amount_');
    end;

    [Test]
    [HandlerFunctions('RHCustomerPaymentReceipt')]
    [Scope('OnPrem')]
    procedure CustomerPaymentReceipt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerPaymentReceipt: Report "Customer - Payment Receipt";
        PmtDiscAmount: Decimal;
        InvoiceAmount: Decimal;
    begin
        // [FEATURE] [Customer - Payment Receipt]
        // Check Customer Payment Receipt Report.

        // Setup: Post Invoice and Payment Entries for a Customer. Take Random Values for Invoice and Payment Amount.
        Initialize();
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        PmtDiscAmount := CreateAndPostGenJournalLines(GenJournalLine, InvoiceAmount, -InvoiceAmount, CreateCustomer(), '');

        // Exercise: Save Customer Payment Receipt Report.
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        Clear(CustomerPaymentReceipt);
        CustomerPaymentReceipt.SetTableView(CustLedgerEntry);
        CustomerPaymentReceipt.Run();

        // Verify: Verify values on Customer Payment Receipt Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyCustomerPaymentReceipt(GenJournalLine."Document No.", -PmtDiscAmount, InvoiceAmount, Round(GenJournalLine.Amount));
    end;

    [Test]
    [HandlerFunctions('RHSalesShipment')]
    [Scope('OnPrem')]
    procedure SalesShipment()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Check Sales Shipment Report without any option.

        // Setup.
        Initialize();
        Quantity := CreateAndPostSalesShipment(DocumentNo, CreateCustomer());

        // Exercise: Save Sales Shipment Report with no options checked.
        SaveSalesShipmentReport(DocumentNo, false, false, false);

        // Verify: Verify Shipped Quantity in Report.
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.FindFirst();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_SalesShptLine', SalesShipmentLine."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_SalesShptLine', Quantity);
    end;

    [Test]
    [HandlerFunctions('RHSalesShipment')]
    [Scope('OnPrem')]
    procedure SalesShipmentInternalInfo()
    var
        DimensionValue: Record "Dimension Value";
        DocumentNo: Code[20];
    begin
        // Check Internal Information on Sales Shipment Report.

        // Setup: Create and Post Sales Shipment with Customer having Dimensions attached.
        Initialize();
        CreateAndPostSalesShipment(DocumentNo, CreateCustomerWithDimension(DimensionValue));

        // Exercise: Save Sales Shipment Report with Show Internal Information option checked.
        SaveSalesShipmentReport(DocumentNo, true, false, false);

        // Verify: Verify Internal Information in saved Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyInternalInformation(DimensionValue, ' - ');
    end;

    [Test]
    [HandlerFunctions('RHSalesShipment')]
    [Scope('OnPrem')]
    procedure SalesShipmentLogInteraction()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        DocumentNo: Code[20];
    begin
        // Check Interaction Log Entries created after running Sales Shipment Report.

        // Setup.
        Initialize();
        CreateAndPostSalesShipment(DocumentNo, CreateCustomer());

        // Exercise: Save Sales Shipment Report with Log Interaction option checked.
        SaveSalesShipmentReport(DocumentNo, false, true, false);

        // Verify: Verify Interaction Log Entry Record.
        VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Sales Shpt. Note", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('RHSalesShipment,UndoShipmentConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesShipmentCorrectionLines()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        DocumentNo: Code[20];
    begin
        // Check Correction Entry on Sales Shipment Report.

        // Setup: Create and Post Sales Shipment and then undo the Shipment.
        Initialize();
        CreateAndPostSalesShipment(DocumentNo, CreateCustomer());

        // Undo the Shipment.
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.FindFirst();
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // Exercise: Save Sales Shipment Report.
        SaveSalesShipmentReport(DocumentNo, false, false, true);

        // Verify: Verify Undone entry in Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyUndoneQuantityInReport(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('RHSalesShipment')]
    [Scope('OnPrem')]
    procedure SalesShipmentOrderNoAndExternalDocumentNoArePrinted()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // [FEATURE] [UI] [Shipment]
        // [SCENARIO 225799] "Order No." and "External Document No." are shown with their captions when report "Sales - Shipment" is printed for Shipment
        Initialize();

        // [GIVEN] Shipment Header with "External Document No." = "XXX" and "Order No." = "YYY"
        SalesShipmentHeader."No." := LibraryUtility.GenerateGUID();
        SalesShipmentHeader."External Document No." := LibraryUtility.GenerateGUID();
        SalesShipmentHeader."Order No." := LibraryUtility.GenerateGUID();
        SalesShipmentHeader.Insert();

        // [WHEN] Export report "Sales - Shipment" to XML file
        SaveSalesShipmentReport(SalesShipmentHeader."No.", false, false, false);
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "Purchase Order No." is displayed under Tag <ExternalDocumentNoCaption_SalesShptHeader> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('ExternalDocumentNoCaption_SalesShptHeader', 'Purchase Order No.');

        // [THEN] Value "XXX" is displayed under Tag <ExternalDocumentNo_SalesShptHeader> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists(
          'ExternalDocumentNo_SalesShptHeader', SalesShipmentHeader."External Document No.");

        // [THEN] Value "Our Document No." is displayed under Tag <OrderNoCaption_SalesShptHeader> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('OrderNoCaption_SalesShptHeader', 'Our Document No.');

        // [THEN] Value "YYY" is displayed under tag <OrderNo_SalesShptHeader> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('OrderNo_SalesShptHeader', SalesShipmentHeader."Order No.");
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecDueDate()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        VATAmount: Decimal;
        PeriodLength: DateFormula;
        NoOfDays: Text[30];
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Check Aged Account Receivable Report with Aging By Due Date.

        // Setup: Create and Post Sales Order with Modify Due Date on Sales Header and Calculate VAT Amount with Random Values.
        Initialize();
        NoOfDays := Format(LibraryRandom.RandInt(5));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, CreateCustomer(), '');
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.Validate("Due Date", CalcDate('<' + NoOfDays + 'D>', SalesHeader."Posting Date"));
        SalesHeader.Modify(true);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VATAmount := Round(SalesLine."Line Amount" + (SalesLine."Line Amount" * SalesLine."VAT %" / 100));
        Evaluate(PeriodLength, '<' + NoOfDays + 'M>');

        // Exercise: Save Aged Account Receivable Report with Aging By Due Date.
        Customer.SetRange("No.", SalesLine."Sell-to Customer No.");
        SaveAgedAccountsReceivable(
          Customer, AgingBy::"Due Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // Verify: Verify Saved Report Data.
        VerifyAgedAccountsRecReport(PostedDocNo, SalesLine."Sell-to Customer No.", VATAmount, VATAmount
          , VATAmount, VATAmount);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecPostingDate()
    var
        SalesLine: Record "Sales Line";
        PeriodLength: DateFormula;
        VATAmount: Decimal;
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Check Aged Account Receivable Report with Aging By Posting Date.

        // Create and Post Sales Order and Save Aged Account Receivable Report with Posting Date.
        Initialize();
        VATAmount := SetupAgedAccountsReceivable(SalesLine, PostedDocNo, PeriodLength, AgingBy::"Posting Date",
            HeadingType::"Date Interval", false, false, '');

        // Verify: Verify Saved Report Data with Aging by Posting Date. 1D is Required by Increasing Date with 1 Day.
        VerifyAgedAccountsRecReport(PostedDocNo, SalesLine."Sell-to Customer No.", VATAmount, VATAmount,
          VATAmount, VATAmount);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecDocumentDate()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        PeriodLength: DateFormula;
        NoOfDays: Text[30];
        VATAmount: Decimal;
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Check Aged Account Receivable Report with Aging By Document Date.

        // Setup: Create and Post Sales Order with Modify Document Date on Sales Header and Calculate VAT Amount with Random Values.
        Initialize();
        NoOfDays := Format(LibraryRandom.RandInt(5));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, CreateCustomer(), '');
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.Validate("Document Date", CalcDate('<' + NoOfDays + 'D>', SalesHeader."Posting Date"));
        SalesHeader.Modify(true);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VATAmount := Round(SalesLine."Line Amount" + (SalesLine."Line Amount" * SalesLine."VAT %" / 100));
        Evaluate(PeriodLength, '<' + NoOfDays + 'M>');

        // Exercise: Save Aged Account Receivable Report with Aging By Document Date.
        Customer.SetRange("No.", SalesLine."Sell-to Customer No.");
        SaveAgedAccountsReceivable(
          Customer, AgingBy::"Document Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // Verify: Verify Saved Report Data with Balance Amount and Heading Type with Date Interval.
        VerifyAgedAccountsRecReport(PostedDocNo, SalesLine."Sell-to Customer No.", VATAmount, 0,
          VATAmount, 0);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecFalsePrintAmtLCY()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        PeriodLength: DateFormula;
        VATAmount: Decimal;
        VATAmount2: Decimal;
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Check Aged Account Receivable Report with Print Amount LCY False.

        // Create and Post Sales Order and Save Aged Account Receivable Report with Print Amount LCY.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateAndPostSalesDocument(SalesLine, CreateCustomer(), SalesLine."Document Type"::Order, '', true);
        VATAmount := Round(SalesLine."Line Amount" + (SalesLine."Line Amount" * SalesLine."VAT %" / 100));

        CreateAndPostSalesDocument(SalesLine2, CreateCustomer(), SalesLine."Document Type"::Order, '', true);
        VATAmount2 := Round(SalesLine2."Line Amount" + (SalesLine2."Line Amount" * SalesLine2."VAT %" / 100));

        // Exercise: Take Period Length with Random Values.
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        Customer.SetFilter("No.", '%1|%2', SalesLine."Sell-to Customer No.", SalesLine2."Sell-to Customer No.");
        SaveAgedAccountsReceivable(
          Customer, AgingBy::"Due Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // Verify: Verify Saved Report Data with Print Amount LCY FALSE.
        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.SetRange('No_Cust', SalesLine."Sell-to Customer No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('CurrrencyCode', GeneralLedgerSetup."LCY Code");

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('CurrSpecificationCptn', 'Currency Specification');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('AgedCLE6RemAmt', VATAmount + VATAmount2);

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('TotalLCYCptn', TotalLCYTxt);
        LibraryReportDataset.SetRange('No_Cust', SalesLine2."Sell-to Customer No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('GrandTotalCLEAmtLCY', VATAmount + VATAmount2);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecTruePrintAmtLCY()
    var
        Currency: Record Currency;
        SalesLine: Record "Sales Line";
        PeriodLength: DateFormula;
        VATAmount: Decimal;
        VATAmountLCY: Decimal;
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Check Aged Account Receivable Report with Print Amount LCY TRUE.

        // Create and Post Sales Order and Save Aged Account Receivable Report with Print Amount LCY.
        Initialize();
        VATAmount := SetupAgedAccountsReceivable(SalesLine, PostedDocNo, PeriodLength, AgingBy::"Due Date", HeadingType::"Date Interval",
            true, false, CreateCurrencyAndExchangeRate());
        Currency.Get(SalesLine."Currency Code");
        VATAmount := Round(VATAmount, Currency."Invoice Rounding Precision");
        VATAmountLCY := LibraryERM.ConvertCurrency(Round(VATAmount, Currency."Invoice Rounding Precision"), Currency.Code, '', WorkDate());

        // Verify: Verify Saved Report Data with Print Amount LCY FALSE.
        VerifyAgedAccountsRecReport(PostedDocNo, SalesLine."Sell-to Customer No.", VATAmount, VATAmount,
          VATAmountLCY, VATAmountLCY);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecNoOfDays()
    var
        SalesLine: Record "Sales Line";
        PeriodLength: DateFormula;
        PostedDocNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Check Aged Account Receivable Report with Heading Type No. of Days.

        // Create and Post Sales Order, Save Aged Account Receivable Report with Heading Type No. of Days.
        Initialize();

        VATAmount := SetupAgedAccountsReceivable(SalesLine, PostedDocNo, PeriodLength, AgingBy::"Due Date",
            HeadingType::"Number of Days", false, false, '');

        // Verify: Verify Saved Report Data with Heading Type No. of Days.
        VerifyAgedAccountsRecReport(PostedDocNo, SalesLine."Sell-to Customer No.", VATAmount, VATAmount,
          VATAmount, VATAmount);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecPrintDetails()
    var
        SalesLine: Record "Sales Line";
        PeriodLength: DateFormula;
        VATAmount: Decimal;
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Check Aged Account Receivable Report with Print Details.

        // Create and Post Sales Order, Save Aged Account Receivable Report with Print Details.
        Initialize();

        VATAmount := SetupAgedAccountsReceivable(SalesLine, PostedDocNo, PeriodLength, AgingBy::"Due Date",
            HeadingType::"Date Interval", false, true, '');

        // Verify: Verify Saved Report Data with Print Details TRUE.
        VerifyAgedAccountsRecReport(PostedDocNo, SalesLine."Sell-to Customer No.", VATAmount, VATAmount,
          VATAmount, VATAmount);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateAllFalse()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PmtDiscAmount: Decimal;
        InvoiceAmount: Decimal;
    begin
        // Check Customer Balance To Date Report without any Option Selected.

        // Setup: Create and Post Invoice and Payment Entries for Customer. Take Random Values for Invoice and Payment Amount.
        Initialize();
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        PmtDiscAmount := CreateAndPostGenJournalLines(GenJournalLine, InvoiceAmount, -InvoiceAmount, CreateCustomer(), '');

        // Exercise: Save Customer Balance To Date Report without any Option Checked.
        SaveCustomerBalanceToDate(GenJournalLine."Account No.", false, false);
        LibraryReportDataset.LoadDataSetFile();

        // Verify: Verify Values on Report.
        VerifyCustomerBalanceToDate(GenJournalLine, InvoiceAmount, PmtDiscAmount);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateAmountLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceAmount: Decimal;
        InvAmountLCY: Decimal;
        PmtAmountLCY: Decimal;
    begin
        // Check Customer Balance To Date Report with Show Amount in LCY Option Selected.

        // Setup: Create and Post Invoice and Payment Entries for Customer with Currency Code. Take Random Invoice Amount and Make sure that
        // Payment Amount is Lesser than Invoice Amount to Post Partial Payment.
        Initialize();
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        CreateAndPostGenJournalLines(GenJournalLine, InvoiceAmount, -InvoiceAmount / 2, CreateCustomerWithCurrency(), '');
        InvAmountLCY := LibraryERM.ConvertCurrency(InvoiceAmount, GenJournalLine."Currency Code", '', WorkDate());
        PmtAmountLCY := LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', WorkDate());
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document No.");

        // Exercise: Save Customer Balance To Date Report with Show Amount in LCY Option Checked.
        SaveCustomerBalanceToDate(GenJournalLine."Account No.", true, false);

        // Verify: Verify Values on Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyCustBalanceToDateWithLCY(CustLedgerEntry, InvAmountLCY, PmtAmountLCY);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateUnapplied()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        LibraryERMUnapply: Codeunit "Library - ERM Unapply";
        InvoiceAmount: Decimal;
    begin
        // Check Customer Balance To Date Report with Include Unapplied Entries Option Selected.

        // Setup: Create and Post Invoice and Payment Entry for Customer. Unapply Payment Entry. Take Random Invoice Amount.
        // Divide Invoice Amount by Two to make Payment Amount partial.
        Initialize();
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        CreateAndPostGenJournalLines(GenJournalLine, InvoiceAmount, -InvoiceAmount / 2, CreateCustomer(), '');
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");
        LibraryERMUnapply.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        // Exercise: Save Customer Balance To Date Report with Include Unapplied Entries Option Checked.
        SaveCustomerBalanceToDate(GenJournalLine."Account No.", false, true);

        // Verify: Verify Unapplied Values on Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyUnappliedEntries(GenJournalLine, InvoiceAmount, CustLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('RHReturnOrderConfirmation')]
    [Scope('OnPrem')]
    procedure ReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Check Return Order Confirmation Report for VAT Amount.

        // Setup: Create Sales Return Order and Calculate VAT Amount.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", CreateCustomer(), '');
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);

        // Exercise: Save Report with default value.
        SaveReturnOrderReport(SalesLine."Document No.", false, false);

        // Verify: Verify Report Data for VAT.
        LibraryReportDataset.LoadDataSetFile();
        VerifyVATEntries('VATAmtLineVATIdentifier', 'VATAmtLineVATPercentage',
          'VATAmtLineVATBase', 'VATAmtLineLineAmt', 'VATAmtLineInvDiscBaseAmt');
    end;

    [Test]
    [HandlerFunctions('RHReturnOrderConfirmation')]
    [Scope('OnPrem')]
    procedure ReturnOrderWithInternalInfo()
    var
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
    begin
        // Check Return Order Confirmation Report with Dimension.

        // Setup: Create Sales Return Order with Dimension.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", CreateCustomerWithDimension(DimensionValue), '');

        // Exercise: Save Report using TRUE to show Internal Info.
        SaveReturnOrderReport(SalesLine."Document No.", true, false);

        // Verify: Verify Report Data for Dimension.
        LibraryReportDataset.LoadDataSetFile();
        VerifyInternalInformation(DimensionValue, ' ');
    end;

    [Test]
    [HandlerFunctions('RHReturnOrderConfirmation')]
    [Scope('OnPrem')]
    procedure ReturnOrderWithLogInfo()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        SalesLine: Record "Sales Line";
    begin
        // Check Return Order Confirmation Report for Log Interaction Entry.

        // Setup: Create Sales Return Order and Calculate VAT Amount.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", CreateCustomer(), '');

        // Exercise: Save Report using TRUE to make Log Interaction Enry.
        SaveReturnOrderReport(SalesLine."Document No.", false, true);

        // Verify: Verify Interaction Log Entry Record.
        LibraryReportDataset.LoadDataSetFile();
        VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Sales Return Order", SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PostAndApplyCustPageHandler,PostApplicationPageHandler,MessageHandler,RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccReceivableReport()
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        AgingBy: Option "Due Date","Posting Date","Document Date";
        HeadingType: Option "Date Interval","Number of Days";
        PeriodLength: DateFormula;
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Verify that program filter data correctly by date in Aged Accounts Receivable report.

        // Setup: Create Customer,Post Invoice and Payment and apply it.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(100, 2)); // Take Random Amount.

        // In Bug 215283,Invoice should be made before the Payment is posted.Hence, taking Random Date before the workdate.
        GenJournalLine.Validate("Posting Date", CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Make Payment by dividing Invoice amount from Random no.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, Customer."No.", -(GenJournalLine.Amount / LibraryRandom.RandIntInRange(2, 5)));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        ApplyCustLedgerEntry(GenJournalLine."Document Type", GenJournalLine."Account No.");
        Customer.Get(Customer."No.");
        Customer.CalcFields(Balance);

        // Exercise: Save Aged Accounts Receivables Report.
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>'); // Take Random value for Period length.
        Customer.SetRecFilter();
        Commit();
        SaveAgedAccountsReceivable(
          Customer, AgingBy::"Due Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // Verify: Verify the Balance in the report.
        VerifyXMLReport('No_Cust', Customer."No.", 'TotalCLE1Amt', Customer.Balance);
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestWithoutPrepaymentInvoicePost()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify Warnings on Sales Document Test Report of Sales Order before posting Prepayment Invoice.

        // Setup: Create Sales Order with Prepayment % and enter different values for 'Type' in Sales Line.
        Initialize();
        CreateSalesOrderWithDifferentLineType(SalesHeader);

        // Exercise: Run and Save Sales Document Test Report.
        SaveSalesDocumentTest(SalesHeader."No.", true, true, false, false);

        // Verify: Verify Warning message on Sales Document Test Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifySalesDocumentTestReport();
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestWithPrepaymentInvoicePost()
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        VATAmount: Decimal;
        VATPercent: Decimal;
        PrepaymentTotalAmount: Decimal;
    begin
        // Verify data on Sales Document Test Report of Sales Order after posting Prepayment Invoice.

        // Setup: Create Sales Order with Prepayment % and enter different values for 'Type' in Sales Line.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        CreateGLAccount(GLAccount, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATPercent := CreateSalesOrderWithDifferentLineType(SalesHeader);

        // Perform summation of Prepayment Line Amount for further validation and post Prepayment Invoice.
        FindSalesLine(SalesLine, SalesHeader);
        repeat
            UpdateSalesPrepmtAccount(GLAccount."No.", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
            PrepaymentTotalAmount += SalesLine."Prepmt. Line Amount";
        until SalesLine.Next() = 0;

        VATAmount := PrepaymentTotalAmount * VATPercent / 100;
        SalesPostPrepayments.Invoice(SalesHeader);

        // Exercise: Run and Save Sales Document Test Report.
        SaveSalesDocumentTest(SalesHeader."No.", true, true, false, false);

        // Verify: Verify data on Sales Document Test Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyDataOnSalesDocumentTestReport(VATAmount, VATPercent, PrepaymentTotalAmount);
    end;

    [Test]
    [HandlerFunctions('StatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatementReportWithGenLines()
    var
        Customer: Record Customer;
        Statement: Report Statement;
        DateChoice: Option "Due Date","Posting Date";
        InvoiceAmount: Decimal;
    begin
        // Check Customer Statement Report with Posted General Line.

        // Setup: Create Invoice and Payment General Line for Customer and Random Values.
        Initialize();
        CreateCustomerAndPostGenJnlLines(Customer, InvoiceAmount);

        // Exercise: Save Statement Report with Random Period Length.
        Clear(Statement);

        Customer.SetRange("No.", Customer."No.");
        Statement.SetTableView(Customer);
        Statement.InitializeRequest(
          false, false, true, false, false, false, '<' + Format(LibraryRandom.RandInt(5)) + 'M>',
          DateChoice::"Due Date", true, WorkDate(), WorkDate());
        Commit();
        Statement.Run();

        // Verify: Verify Saved Data in Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Amt_DtldCustLedgEntries', -InvoiceAmount * 2);
        LibraryReportDataset.AssertElementWithValueExists('RemainAmt_DtldCustLedgEntries', -InvoiceAmount * 2);
        LibraryReportDataset.AssertElementWithValueExists('CustBalance', -InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('StatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyCustomerStatementReportTotalLine()
    var
        Customer: Record Customer;
        InvoiceAmount: Decimal;
    begin
        // Check Customer Statement Report Total value
        Initialize();

        // Setup: Create Invoice and Payment General Line for Customer and Random Values.
        CreateCustomerAndPostGenJnlLines(Customer, InvoiceAmount);

        // Exercise: Save Customer Statement Report as XML
        RunStatementReport(Customer."No.");

        VerifyStatementEntriesTotal(-InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesReqPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForSalesShipment()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
        PostedSalesShipmentPage: Page "Posted Sales Shipment";
        DocumentNo: Code[20];
    begin
        // Verify Document Entries for Sales Shipment with Tables and No of Records as per Navigate.

        // Setup: Create and Post Sales Shipment.
        Initialize();
        CreateAndPostSalesShipment(DocumentNo, CreateCustomer());
        LibraryVariableStorage.Enqueue(false);  // Enqueue for DocumentEntriesReqPageHandler.
        PostedSalesShipment.OpenView();
        PostedSalesShipment.FILTER.SetFilter("No.", DocumentNo);

        // Exercise.
        PostedSalesShipment."&Navigate".Invoke();  // Navigate.

        // Verify: Verify Tables and No of Records as per Navigate.
        LibraryReportDataset.LoadDataSetFile();
        SalesShipmentHeader.SetRange("No.", DocumentNo);
        VerifyDocumentEntries(PostedSalesShipmentPage.Caption, SalesShipmentHeader.Count);
        VerifyItemLedgerWithValueEntry(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesReqPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForSalesInvoiceWithLCY()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Verify Document Entries report for Sales Invoice with Tables and No of Records as per Navigate and option 'Show Amount in LCY'.

        // Setup and Excercise.
        DocumentEntriesForSalesInvoice(SalesInvoiceHeader, true);

        // Verify: Verify Amount in LCY on Document Entries Report.
        VerifyAmtOnDocumentEntriesReport(
          InvPostingDtTxt, Format(
            SalesInvoiceHeader."Posting Date"), InvAmtTxt, SalesInvoiceHeader.Amount / SalesInvoiceHeader."Currency Factor");
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesReqPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForSalesInvoiceWithFCY()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Verify Document Entries report for Sales Invoice Tables and No of Records as per Navigate and without option 'Show Amount in LCY'.

        // Setup and Excercise.
        DocumentEntriesForSalesInvoice(SalesInvoiceHeader, false);

        // Verify: Verify Amount in FCY on Document Entries Report.
        VerifyAmtOnDocumentEntriesReport(
          InvPostingDtTxt, Format(SalesInvoiceHeader."Posting Date"), InvAmtTxt, SalesInvoiceHeader.Amount);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesReqPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForSalesRetReceipt()
    var
        SalesLine: Record "Sales Line";
        ReturnReceiptHeader: Record "Return Receipt Header";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
        PostedReturnReceiptPage: Page "Posted Return Receipt";
        DocumentNo: Code[20];
    begin
        // Verify Document Entries for Sales Return Order with Tables and No of Records as per Navigate.

        // Setup: Create and Post Sales Return Order.
        Initialize();
        DocumentNo := CreateAndPostSalesDocument(SalesLine, CreateCustomer(), SalesLine."Document Type"::"Return Order", '', false);  // Blank is used for Currency Code.
        LibraryVariableStorage.Enqueue(false);  // Enqueue for DocumentEntriesReqPageHandler.
        PostedReturnReceipt.OpenView();
        PostedReturnReceipt.FILTER.SetFilter("No.", DocumentNo);

        // Exercise.
        PostedReturnReceipt."&Navigate".Invoke();  // Navigate.

        // Verify: Verify Tables and No of Records as per Navigate.
        LibraryReportDataset.LoadDataSetFile();
        ReturnReceiptHeader.SetRange("No.", DocumentNo);
        VerifyDocumentEntries(PostedReturnReceiptPage.Caption, ReturnReceiptHeader.Count);
        VerifyItemLedgerWithValueEntry(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesReqPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForSalesCrMemoWithLCY()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Verify Document Entries report for Sales Cr. Memo with Tables and No of Records as per Navigate and option 'Show Amount in LCY'.

        // Setup and Excercise.
        DocumentEntriesForSalesCrMemo(SalesCrMemoHeader, true);

        // Verify: Verify Amount in LCY on Document Entries Report.
        VerifyAmtOnDocumentEntriesReport(CrMemoPostingDtTxt, Format(SalesCrMemoHeader."Posting Date"),
          CrMemoAmtTxt, SalesCrMemoHeader.Amount / SalesCrMemoHeader."Currency Factor");
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesReqPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForSalesCrMemoWithFCY()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Verify Document Entries report for Sales Cr. Memo Tables and No of Records as per Navigate and without option 'Show Amount in LCY'.

        // Setup and Excercise.
        DocumentEntriesForSalesCrMemo(SalesCrMemoHeader, false);

        // Verify: Verify Amount in FCY on Document Entries Report.
        VerifyAmtOnDocumentEntriesReport(
          CrMemoPostingDtTxt, Format(SalesCrMemoHeader."Posting Date"), CrMemoAmtTxt, SalesCrMemoHeader.Amount);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecWithCurrencyCodeMatchesBlankAndLCY()
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Verify Aged Accounts Receivable report should consider the Amount when Currency Code is Blank and LCY with Print Amount LCY False.
        AgedAccountRecFalsePrintAmtLCYAndCurrencyCodeMatchesLCY(true); // 1st currency code is blank, 2nd currency is LCY.
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecWithCurrencyCodeMatchesLCYAndBlank()
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Verify Aged Accounts Receivable report should consider the Amount when Currency Code is LCY and Blank with Print Amount LCY False.
        AgedAccountRecFalsePrintAmtLCYAndCurrencyCodeMatchesLCY(false); // 1st currency code is LCY, 2nd currency is blank.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardSalesCreditMemoWithEmptyShiptoInformation()
    var
        PostedCreditMemoDocNo: Code[20];
        FileName: Text[1024];
    begin
        // [SCENARIO 371670] "Standard Sales - Credit Memo" report prints document without ship-to informantion

        Initialize();
        // [GIVEN] Posted Credit Memo without ship-to information
        PostedCreditMemoDocNo := CreatePostCreditMemoWithoutShiptoInfo();

        // [WHEN] Run "Standard Sales - Credit Memo" report
        FileName := RunStandardSalesCreditMemo(PostedCreditMemoDocNo);

        // [THEN] File of report exists
        Assert.IsTrue(FileManagement.ServerFileExists(FileName), ReportStandardSalesCreditMemoErr);
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestReportExchangeRate()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ActualResult: Variant;
        SalesHeaderNo: Code[20];
        ExpectedResult: Decimal;
        VATIdentifier: Code[20];
    begin
        // [FEATURE] [Sales Document - Test]
        // [SCENARIO 378473] Sales Document - Test report should show Exchange Rate from Sales header in section "VAT Amount Specification ..."
        Initialize();

        // [GIVEN] "General Ledger Setup"."Print VAT specification in LCY" = TRUE
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Print VAT specification in LCY" := true;
        GeneralLedgerSetup.Modify();

        // [GIVEN] Currency "C" with Exchange Rate = "X"
        CreateCurrencyWithExchRate(CurrencyExchangeRate);

        // [GIVEN] Sales Invoice with "Currency Code" = "C" and Exchange Rate = "Y"
        CreateSalesInvoiceWithCurrFactor(SalesHeaderNo, ExpectedResult, VATIdentifier, CurrencyExchangeRate);

        // [WHEN] Run "Sales Document - Test"
        SaveSalesDocumentTest(SalesHeaderNo, true, true, false, false);

        // [THEN] Exchange Rate = "Y"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(VATIdentifierTok, VATIdentifier);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.GetElementValueInCurrentRow(VALExchRateTok, ActualResult);
        Assert.AreNotEqual(0, StrPos(ActualResult, Format(ExpectedResult)), WrongExchRateErr);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CheckCustomerBalanceToDateWithGLobalDimension1Filter()
    var
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
        CustomerNo: Code[20];
        DimensionNo: array[2] of Code[20];
    begin
        // [SCENARIO 163061] Check Customer Balance To Date report with filter on Customer."Global Dimension 1 Filter"
        Initialize();

        // [GIVEN] Posted Sales Invoice with Global Dimension 1 = "D1" where Amount = "A1"
        // [GIVEN] Posted Sales Invoice with Global Dimension 1 = "D2" where Amount = "A2"
        GLSetup.Get();
        CustomerNo := CreateCustomer();
        Customer.Get(CustomerNo);
        LibraryDimension.FindDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");
        DimensionNo[1] := DimensionValue.Code;
        DimensionNo[2] := LibraryDimension.FindDifferentDimensionValue(GLSetup."Global Dimension 1 Code", DimensionNo[1]);
        Customer.Validate("Global Dimension 1 Code", DimensionNo[1]);
        Customer.Modify();
        CreateCustomerAndPostGenJnlLinesWithFilters(CustomerNo, DimensionNo[1], '', '');
        CreateCustomerAndPostGenJnlLinesWithFilters(CustomerNo, DimensionNo[2], '', '');

        // [WHEN] Save Customer - Balance To Date report with Limit Totals on Global Dimension 1 = "D2"
        RunCustomerBalanceToDateWithLimitTotal(CustomerNo, DimensionNo[2], '', '');

        // [THEN] 'Original Amount' value is equal to "A2".
        VerifyCustomerBalanceToDateWithLimitTotal(CustomerNo, DimensionNo[2], '', '');
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CheckCustomerBalanceToDateWithGLobalDimension2Filter()
    var
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
        CustomerNo: Code[20];
        DimensionNo: array[2] of Code[20];
    begin
        // [SCENARIO 163061] Check Customer Balance To Date report with filter on Customer."Global Dimension 2 Filter"
        Initialize();

        // [GIVEN] Posted Sales Invoice with Global Dimension 2 = "D1" where Amount = "A1"
        // [GIVEN] Posted Sales Invoice with Global Dimension 2 = "D2" where Amount = "A2"
        GLSetup.Get();
        CustomerNo := CreateCustomer();
        Customer.Get(CustomerNo);
        LibraryDimension.FindDimensionValue(DimensionValue, GLSetup."Global Dimension 2 Code");
        DimensionNo[1] := DimensionValue.Code;
        DimensionNo[2] := LibraryDimension.FindDifferentDimensionValue(GLSetup."Global Dimension 2 Code", DimensionNo[1]);
        Customer.Validate("Global Dimension 2 Code", DimensionNo[1]);
        Customer.Modify();
        CreateCustomerAndPostGenJnlLinesWithFilters(CustomerNo, '', DimensionNo[1], '');
        CreateCustomerAndPostGenJnlLinesWithFilters(CustomerNo, '', DimensionNo[2], '');

        // [WHEN] Save Customer - Balance To Date report with Limit Totals on Global Dimension 2 = "D2"
        RunCustomerBalanceToDateWithLimitTotal(CustomerNo, '', DimensionNo[2], '');

        // [THEN] 'Original Amount' value is equal to "A2".
        VerifyCustomerBalanceToDateWithLimitTotal(CustomerNo, '', DimensionNo[2], '');
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CheckCustomerBalanceToDateWithCurrencyFilter()
    var
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 163061] Check Customer Balance To Date report with filter on Customer."Currency Filter"

        // [GIVEN] Posted Sales Invoice with Currency Code = "C1" where Amount = "A1"
        // [GIVEN] Posted Sales Invoice with Currency Code = "C2" where Amount = "A2"
        Initialize();
        CustomerNo := CreateCustomerWithCurrency();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        CreateCustomerAndPostGenJnlLinesWithFilters(CustomerNo, '', '', '');
        CreateCustomerAndPostGenJnlLinesWithFilters(CustomerNo, '', '', CurrencyCode);

        // [WHEN] Save Customer - Balance To Date report with Limit Totals on Currency Code = "C2"
        RunCustomerBalanceToDateWithLimitTotal(CustomerNo, '', '', CurrencyCode);

        // [THEN] 'Original Amount' value is equal to "A2".
        VerifyCustomerBalanceToDateWithLimitTotal(CustomerNo, '', '', CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateClosedEntryAppliedUnappliedAppliedOutOfPeriod()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
    begin
        // [SCENARIO 378237] Customer Balance To Date for Entry where unapplication and then application are out of Ending Date
        Initialize();

        // [GIVEN] Customer with payment of Amount = -150
        MockCustLedgerEntry(CustLedgerEntry, LibrarySales.CreateCustomerNo(), -LibraryRandom.RandDec(100, 2), WorkDate());

        // [GIVEN] Closed Customer Ledger Entry on 31.12.15 with Amount = 100
        // [GIVEN] Application dtld. cust. ledger entries of Amount = -100 applied on 31.12.15 and unapplied on 01.01.16
        // [GIVEN] Application dtld. cust. ledger entry with Amount = -100 on 01.01.16
        Amount := MockApplyUnapplyScenario(CustLedgerEntry."Customer No.", WorkDate(), WorkDate() + 1, WorkDate() + 1);

        // [WHEN] Save Customer Balance To Data report on 31.12.15 with Include Unapplied Entries = No
        RunCustomerBalanceToDateWithCustomer(CustLedgerEntry."Customer No.", false, WorkDate());

        // [THEN] Payment Entry of -150 is printed, 100 is not printed, Total Amount = -150
        // [THEN] Applied Entry (01.01.16) of 100 is not printed. Initial TFSID 231621
        VerifyCustomerBalanceToDateDoesNotExist(CustLedgerEntry."Customer No.", CustLedgerEntry.Amount, Amount);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateClosedEntryAppliedUnappliedAppliedOutOfPeriodIncludeUnapplied()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
    begin
        // [SCENARIO 378237] Customer Balance To Date for closed Entry with zero balance inside period and application after Ending Date
        Initialize();

        // [GIVEN] Customer with payment of Amount = -150
        MockCustLedgerEntry(CustLedgerEntry, LibrarySales.CreateCustomerNo(), -LibraryRandom.RandDec(100, 2), WorkDate());

        // [GIVEN] Closed Customer Ledger Entry on 31.12.15 with Amount = 100
        // [GIVEN] Application dtld. cust. ledger entries of Amount = -100 applied on 31.12.15 and unapplied on 01.01.16
        // [GIVEN] Application dtld. cust. ledger entry with Amount = -100 on 01.01.16
        Amount := MockApplyUnapplyScenario(CustLedgerEntry."Customer No.", WorkDate(), WorkDate() + 1, WorkDate() + 1);

        // [WHEN] Save Customer Balance To Data report on 31.12.15 with Include Unapplied Entries = Yes
        RunCustomerBalanceToDateWithCustomer(CustLedgerEntry."Customer No.", true, WorkDate());

        // [THEN] Payment Entry of -150 is printed, 100 is printed with 0 balance, Total Amount = -150
        // [THEN] Applied Entry (01.01.16) of 100 is not printed. Initial TFSID 231621
        VerifyCustomerBalanceToDateTwoEntriesExist(
          CustLedgerEntry."Customer No.", CustLedgerEntry.Amount, Amount, CustLedgerEntry.Amount);
        // [THEN] Applied Entry (31.12.15) is printed. Initial TFSID 231621
        LibraryReportDataset.AssertElementWithValueExists('postDt_DtldCustLedgEntry', Format(WorkDate()));
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateClosedEntryAppliedInPeriodUnappliedAppliedOutOfPeriod()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
    begin
        // [SCENARIO 378848] Customer Balance To Date for unapplied entry inside period and application after Ending Date
        Initialize();

        // [GIVEN] Customer with payment of Amount = -150
        MockCustLedgerEntry(CustLedgerEntry, LibrarySales.CreateCustomerNo(), -LibraryRandom.RandDec(100, 2), WorkDate());

        // [GIVEN] Closed Customer Ledger Entry on 31.12.15 with Amount = 100
        // [GIVEN] Application dtld. cust. ledger entries of Amount = -100 applied on 31.12.15 and unapplied on 31.12.15
        // [GIVEN] Application dtld. cust. ledger entry with Amount = -100 on 01.01.16
        Amount := MockApplyUnapplyScenario(CustLedgerEntry."Customer No.", WorkDate(), WorkDate(), WorkDate() + 1);

        // [WHEN] Save Customer Balance To Data report on 31.12.15 with Include Unapplied Entries = No
        RunCustomerBalanceToDateWithCustomer(CustLedgerEntry."Customer No.", false, WorkDate());

        // [THEN] Payment Entry of -150 is printed, 100 is printed, Total Amount = -50
        // [THEN] Applied Entry (01.01.16) of 100 is not printed. Initial TFSID 231621
        VerifyCustomerBalanceToDateTwoEntriesExist(
          CustLedgerEntry."Customer No.", CustLedgerEntry.Amount, Amount, CustLedgerEntry.Amount + Amount);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateClosedEntryWithinPeriod()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PmtAmount: Decimal;
    begin
        // [SCENARIO 211599] Customer Balance To Date for closed Entry inside period
        Initialize();

        // [GIVEN] Customer with payment of Amount = -150
        PmtAmount := -LibraryRandom.RandDec(100, 2);
        MockCustLedgerEntry(CustLedgerEntry, LibrarySales.CreateCustomerNo(), PmtAmount, WorkDate());

        // [GIVEN] Closed Customer Ledger Entry on 30.12.15 with Amount = 100
        MockCustLedgerEntry(CustLedgerEntry, CustLedgerEntry."Customer No.", LibraryRandom.RandDec(100, 2), WorkDate() - 1);

        // [GIVEN] Application dtld. cust. ledger entry with Amount = -100 on 31.12.15
        MockDtldCustLedgEntry(CustLedgerEntry."Customer No.", CustLedgerEntry."Entry No.", -CustLedgerEntry.Amount, false, WorkDate());
        UpdateOpenOnCustLedgerEntry(CustLedgerEntry."Entry No.");

        // [WHEN] Save Customer Balance To Data report on 31.12.15 with Include Unapplied Entries = No
        RunCustomerBalanceToDateWithCustomer(CustLedgerEntry."Customer No.", false, WorkDate());

        // [THEN] Payment Entry of -150 is printed, 100 is not printed, Total Amount = -150
        VerifyCustomerBalanceToDateDoesNotExist(CustLedgerEntry."Customer No.", PmtAmount, CustLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('StatementCancelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportSelectionForCustomerStatementInReminder()
    var
        Reminder: TestPage Reminder;
    begin
        // [FEATURE] [UT] [Report Selection]
        // [SCENARIO 381714] When running the report "Customer Statement", the report specified in Report Selection should be opened
        Initialize();
        Commit();
        REPORT.Run(REPORT::"Customer Statement"); // Calls StatementCancelRequestPageHandler
        Reminder.OpenEdit();
        asserterror Reminder."Report Statement".Invoke(); // Calls StatementCancelRequestPageHandler
        Assert.ExpectedError(RunReportNotSupportedErr);
    end;

    [Test]
    [HandlerFunctions('StatementCancelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportSelectionForCustomerStatementInSalesInvoiceList()
    var
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [FEATURE] [UT] [Report Selection]
        // [SCENARIO 381714] When using "Statement" action on Sales Invoice List, the report specified in Report Selection should be opened
        Initialize();
        Commit();
        REPORT.Run(REPORT::"Customer Statement");
        SalesInvoiceList.OpenEdit();
        asserterror SalesInvoiceList."Report Statement".Invoke(); // Calls StatementCancelRequestPageHandler
        Assert.ExpectedError(RunReportNotSupportedErr);
    end;

    [Test]
    [HandlerFunctions('StatementCancelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportSelectionForCustomerStatementInSalesCreditMemos()
    var
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        // [FEATURE] [UT] [Report Selection]
        // [SCENARIO 381714] When using "Statement" action on Sales Credit Memos, the report specified in Report Selection should be opened
        Initialize();
        Commit();
        REPORT.Run(REPORT::"Customer Statement");
        SalesCreditMemos.OpenEdit();
        asserterror SalesCreditMemos."Report Statement".Invoke(); // Calls StatementCancelRequestPageHandler
        Assert.ExpectedError(RunReportNotSupportedErr);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivableEmptyPeriodLength')]
    [Scope('OnPrem')]
    procedure AgedAccountsReceivablePeriodLengthError()
    var
        Customer: Record Customer;
        PeriodLength: DateFormula;
    begin
        // [FEATURE] [UT] [Aged Accounts Receivable]
        // [SCENARIO 202767] Aged Accounts Receivable report gives 'Enter a date formula in the Period Length field.' error when "Period Length" is empty
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        Commit();
        asserterror SaveAgedAccountsReceivable(
            Customer, AgingBy::"Due Date", HeadingType::"Date Interval", PeriodLength, false, false);
        Assert.ExpectedError(EnterDateFormulaErr);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivableDefaultPeriodLength')]
    [Scope('OnPrem')]
    procedure AgedAccountsReceivableDefaultPeriodLength()
    var
        Customer: Record Customer;
        PeriodLength: DateFormula;
        ExpectedPeriodLength: DateFormula;
    begin
        // [FEATURE] [UT] [Aged Accounts Receivable]
        // [SCENARIO 232335] Aged Accounts Receivable report has '<1M>' as default Period Length
        Initialize();

        Clear(PeriodLength);
        LibrarySales.CreateCustomer(Customer);
        Commit();
        SaveAgedAccountsReceivable(
          Customer, AgingBy::"Due Date", HeadingType::"Date Interval", PeriodLength, false, false);
        Evaluate(PeriodLength, LibraryVariableStorage.DequeueText());
        Evaluate(ExpectedPeriodLength, '<1M>');
        Assert.AreEqual(ExpectedPeriodLength, PeriodLength, 'Incorrect Period Length');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ECSalesListReportWithFilteredPostingDateWithNoData()
    var
        DummyVATEntry: Record "VAT Entry";
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [EC Sales List]
        Initialize();
        CompanyInformation.Get();

        // [GIVEN] Report 130 "EC Sales List" request page
        // [GIVEN] Type filter for VAT Entry "Posting Date"  = "01-01-2120" (on a date with no data)
        // [WHEN] Run the report
        DummyVATEntry.SetRange("Posting Date", DMY2Date(1, 1, Date2DMY(WorkDate(), 3) + 10), DMY2Date(31, 1, Date2DMY(WorkDate(), 3) + 10));
        REPORT.SaveAsExcel(REPORT::"EC Sales List", LibraryReportValidation.GetFileName(), DummyVATEntry);

        // [THEN] The report has been printed
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueOnWorksheet(5, 5, CompanyInformation.Name, '1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPmtReceiptReportWithExternalDocNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        ExternalDocNo: Code[35];
        Amount: Decimal;
    begin
        // [FEATURE] [Customer - Payment Receipt] [External Document No.]
        // [SCENARIO 210727] REP 211 "Customer - Payment Receipt" prints "External Document No." payment line with positive amount
        Initialize();

        // [GIVEN] Posted customer payment with "External Document No." = "X", Amount = "A"
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        ExternalDocNo := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(ExternalDocNo)), 1, MaxStrLen(ExternalDocNo));
        CreateAndPostGenJournalLines(GenJournalLine, Amount, -Amount, LibrarySales.CreateCustomerNo(), ExternalDocNo);

        // [WHEN] Run REP 211 "Customer - Payment Receipt"
        DummyCustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        REPORT.SaveAsExcel(REPORT::"Customer - Payment Receipt", LibraryReportValidation.GetFileName(), DummyCustLedgerEntry);

        // [THEN] Payment line has been printed with Description = "X", Amount = "A"
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.VerifyCellValueByRef('K', 65, 1, ExternalDocNo);
        LibraryReportValidation.VerifyCellValueByRef('O', 65, 1, LibraryReportValidation.FormatDecimalValue(Amount));
    end;

    [Test]
    [HandlerFunctions('StatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StatementBlanked()
    begin
        // [FEATURE] [Statement]
        // [SCENARIO 218263] REP 116 "Statement" doesn't show any error in case of empty output
        Initialize();

        // [GIVEN] Customer without any business data
        // [THEN] Run "Statement" report for the customer
        RunStatementReport(LibrarySales.CreateCustomerNo());

        // [WHEN] Report has been printed blanked
        // StatementRequestPageHandler
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), '');
    end;

    [Test]
    [HandlerFunctions('StandardStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardStatementBlanked()
    begin
        // [FEATURE] [Standard Statement]
        // [SCENARIO 218263] REP 1316 "Standard Statement" doesn't show any error in case of empty output
        Initialize();

        // [GIVEN] Customer without any business data
        // [THEN] Run "Standard Statement" report for the customer
        RunStandardStatementReport(LibrarySales.CreateCustomerNo());

        // [WHEN] Report has been printed blanked
        // StatementRequestPageHandler
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), '');
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountsReceivableTimestampAndCompanyDisplayNameCalledOnce()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        PeriodLength: DateFormula;
        I: Integer;
    begin
        // [FEATURE] [Performance] [Aged Accounts Receivable] [Date-Time] [Time Zone]
        // [SCENARIO 235531] TypeHelper.GetFormattedCurrentDateTimeInUserTimeZone and COMPANYPROPERTY.DisplayName() are called once for Aged Accounts Receivable report when multiple entries are processed
        Initialize();

        // [GIVEN] Post 2 Sales Invoices
        LibrarySales.CreateCustomer(Customer);
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        for I := 1 to 2 do
            LibraryJournals.CreateGenJournalLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
              GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Bal. Account Type"::"G/L Account",
              LibraryERM.CreateGLAccountNo(), LibraryRandom.RandIntInRange(1000, 2000));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run Aged Accounts Receivable
        Customer.SetRecFilter();
        Evaluate(PeriodLength, '<1M>');
        CodeCoverageMgt.StartApplicationCoverage();
        SaveAgedAccountsReceivable(Customer, AgingBy::"Posting Date", HeadingType::"Date Interval", PeriodLength, false, false);
        CodeCoverageMgt.StopApplicationCoverage();

        // [THEN] COMPANYPROPERTY.DisplayName() is called once
        VerifyAgedAccountsReceivableNoOfHitsCodeCoverage('COMPANYPROPERTY.DISPLAYNAME', 1);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDateEnableShowEntriesWithZeroBalance')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateShowEntriesWithZeroBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Customer - Balance to Date]
        // [SCENARIO 275908] Report Customer - Balance to Date shows entries with zero balance when "Show Entries with Zero Balance" was enabled on request page
        Initialize();

        // [GIVEN] Posted Invoice Gen. Journal Line with Customer Account and Amount = -1000
        CreateGenJnlLineWithBalAccount(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          LibrarySales.CreateCustomerNo(), GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Credit Memo Gen. Journal Line with Customer Account and Amount = 1000
        CreateGenJnlLineWithBalAccount(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer,
          GenJournalLine."Account No.", GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          -GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Stan ran report "Customer - Balance to Date" and enabled "Show Entries with Zero Balance" on request page
        RunCustomerBalanceToDateWithLimitTotal(GenJournalLine."Account No.", '', '', '');

        // [WHEN] Stan pushes OK on request page
        // Done in RHVendorBalanceToDateEnableShowEntriesWithZeroBalance

        // [THEN] Report shows formatted Invoice and Credit Memo entries for Customer
        // [THEN] Report shows formatted balance value = 0 for Customer
        VerifyCustomerEntriesAndBalanceInCustomerBalanceToDate(GenJournalLine, 0);
    end;

    [Test]
    [HandlerFunctions('AnalysisReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisReportPrintoutFormattingCheck()
    var
        AnalysisReportName: Record "Analysis Report Name";
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisLine: array[5] of Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        AnalysisReport: Report "Analysis Report";
    begin
        // [FEATURE] [Analysis Report]
        // [SCENARIO 280460] Analysis report printout should respect analysis line format settings.
        Initialize();

        // [GIVEN] Sales analysis report with one column.
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, AnalysisReportName."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisLineTemplate."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisColumnTemplate."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisColumn(AnalysisColumn, AnalysisColumn."Analysis Area"::Sales, AnalysisColumnTemplate.Name);

        // [GIVEN] The report has five analysis lines with various formatting.
        // [GIVEN] Line 1 - normal font style, Line 2 - bold, Line 3 - italic, Line 4 - bold italic, Line 5 - bold and underlined.
        CreateAnalysisLine(AnalysisLine[1], AnalysisLineTemplate.Name, LibrarySales.CreateCustomerNo(), false, false, false);
        CreateAnalysisLine(AnalysisLine[2], AnalysisLineTemplate.Name, LibrarySales.CreateCustomerNo(), true, false, false);
        CreateAnalysisLine(AnalysisLine[3], AnalysisLineTemplate.Name, LibrarySales.CreateCustomerNo(), false, true, false);
        CreateAnalysisLine(AnalysisLine[4], AnalysisLineTemplate.Name, LibrarySales.CreateCustomerNo(), true, true, false);
        CreateAnalysisLine(AnalysisLine[5], AnalysisLineTemplate.Name, LibrarySales.CreateCustomerNo(), true, false, true);

        // [WHEN] Run "Analysis Report".
        Commit();
        AnalysisReport.SetParameters(
          AnalysisLine[1]."Analysis Area"::Sales, AnalysisReportName.Name, AnalysisLineTemplate.Name, AnalysisColumnTemplate.Name);
        AnalysisReport.SetFilters(Format(WorkDate()), '', '', '', '', '', 0, '');
        AnalysisReport.Run();

        // [THEN] Each line is printed only once and has its own format.
        LibraryReportDataset.LoadDataSetFile();
        VerifyRowFormatInAnalysisReport(AnalysisLine[1], true, false, false, false, false); // normal
        VerifyRowFormatInAnalysisReport(AnalysisLine[2], false, true, false, false, false); // bold
        VerifyRowFormatInAnalysisReport(AnalysisLine[3], false, false, true, false, false); // italic
        VerifyRowFormatInAnalysisReport(AnalysisLine[4], false, false, false, true, false); // bold italic
        VerifyRowFormatInAnalysisReport(AnalysisLine[5], false, true, false, false, true); // bold + underlined
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateFilterAsTextInAnalysisReportToExcel()
    var
        AnalysisReportName: Record "Analysis Report Name";
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ExportAnalysisRepToExcel: Report "Export Analysis Rep. to Excel";
        DateFilter: Text;
    begin
        // [FEATURE] [Analysis Report]
        // [SCENARIO 280460] When "Date Filter" set on analysis line is not a single date, but a date period, it should be printed as text on the filter section in "Analysis Report to Excel" worksheet.
        Initialize();

        // [GIVEN] Sales analysis report with one line and one column.
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, AnalysisReportName."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisLineTemplate."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisColumnTemplate."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisColumn(AnalysisColumn, AnalysisColumn."Analysis Area"::Sales, AnalysisColumnTemplate.Name);
        LibraryInventory.CreateAnalysisLine(AnalysisLine, AnalysisLine."Analysis Area"::Sales, AnalysisLineTemplate.Name);

        // [GIVEN] Set "Date Filter" = '01/01/20..31/12/20' on the analysis line.
        DateFilter := StrSubstNo('%1..%2', CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        AnalysisLine.SetFilter("Date Filter", DateFilter);

        // [WHEN] Export the analysis report to Excel.
        ExportAnalysisRepToExcel.SetOptions(AnalysisLine, AnalysisColumnTemplate.Name, AnalysisLineTemplate.Name);
        ExportAnalysisRepToExcel.SetFileNameSilent(LibraryReportValidation.GetFileName());
        ExportAnalysisRepToExcel.SetTestMode(true);
        ExportAnalysisRepToExcel.Run();

        // [THEN] Date Filter = '01/01/20..31/12/20' is printed on the filter section on Excel worksheet.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueOnWorksheet(2, 2, DateFilter, '1');
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccReceivableReportConsidersGlobalDimensionFiltersWhenReportOpenLedgEntries()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        AgingBy: Option "Due Date","Posting Date","Document Date";
        HeadingType: Option "Date Interval","Number of Days";
        PeriodLength: DateFormula;
        i: Integer;
    begin
        // [FEATURE] [Aged Accounts Receivable] [Dimension]
        // [SCENARIO 284398] Aged Account Receivable Report considers global dimension filters

        Initialize();

        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Two posted invoices
        // [GIVEN] Invoice "A" with Amount = 100, "Global Dimension 1 Code" = "X1", "Global Dimension 2 Code" = "X2"
        // [GIVEN] Invoice "B" with Amount = 200, "Global Dimension 1 Code" = "X2", "Global Dimension 2 Code" = "Y2"
        for i := 1 to 2 do
            PostInvoiceWithDimensions(GenJournalLine, Customer."No.");
        PrepareAgedAccReceivableReportForDimRun(
          Customer, PeriodLength, GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code");

        // [WHEN] Run Aged Account Receivable Report with "Global Dimension 1 Filter" = "X2" and "Global Dimension 2 Filter" = "Y2"
        SaveAgedAccountsReceivable(
          Customer, AgingBy::"Posting Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // [THEN] Total amount in exported XML file of report is 200
        VerifyXMLReport('No_Cust', Customer."No.", 'TotalCLE1Amt', GenJournalLine."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('PostAndApplyCustPageHandler,PostApplicationPageHandler,MessageHandler,RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccReceivableReportConsidersGlobalDimensionFiltersWhenReportClosedLedgEntries()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        AgingBy: Option "Due Date","Posting Date","Document Date";
        PeriodLength: DateFormula;
        i: Integer;
    begin
        // [FEATURE] [Aged Accounts Receivable] [Dimension]
        // [SCENARIO 284398] Aged Account Receivable Report considers global dimension filters

        Initialize();

        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Two posted invoices fully applied by payments
        // [GIVEN] Invoice "A" with Amount = 100, "Global Dimension 1 Code" = "X1", "Global Dimension 2 Code" = "X2"
        // [GIVEN] Invoice "B" with Amount = 200, "Global Dimension 1 Code" = "X2", "Global Dimension 2 Code" = "Y2"
        for i := 1 to 2 do begin
            PostInvoiceWithDimensions(GenJournalLine, Customer."No.");
            PostApplyPaymentWithDimensions(
              GenJournalLine, Customer."No.", GenJournalLine."Posting Date" + 1, -GenJournalLine.Amount,
              GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code");
        end;
        PrepareAgedAccReceivableReportForDimRun(
          Customer, PeriodLength, GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code");
        Commit();

        // [WHEN] Run Aged Account Receivable Report with "Global Dimension 1 Filter" = "X2" and "Global Dimension 2 Filter" = "Y2"
        SaveAgedAccountsReceivable(
          Customer, AgingBy::"Posting Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // [THEN] Total amount in exported XML file of report is 200
        VerifyXMLReport('No_Cust', Customer."No.", 'TotalCLE1Amt', -GenJournalLine."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateRemainingAmount()
    var
        GenJournalLine: array[3] of Record "Gen. Journal Line";
        Customer: Record Customer;
        AutoFormat: Codeunit "Auto Format";
        CustomerBalanceToDate: Report "Customer - Balance to Date";
    begin
        // [FEATURE] [Customer - Balance to Date]
        // [SCENARIO 288122] Remaining Amount in "Customer - Balance to Date" report shows sum of invoice that is closed at a later date.
        Initialize();

        // [GIVEN] Invoice Gen. Jnl. Line with Amount 'X', Payment Gen. Jnl. Line with Amount 'Y', Payment Gen. Jnl. Line with Amount -'X'-'Y'
        LibrarySales.CreateCustomer(Customer);
        CreateGenJournalLine(
          GenJournalLine[1], WorkDate(), Customer."No.",
          GenJournalLine[1]."Document Type"::Invoice, GenJournalLine[1]."Document Type"::" ", '', LibraryRandom.RandIntInRange(500, 1000));
        LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);

        CreateGenJournalLine(
          GenJournalLine[2], WorkDate() + 1, Customer."No.",
          GenJournalLine[1]."Document Type"::Payment, GenJournalLine[1]."Document Type"::Invoice, GenJournalLine[1]."Document No.", LibraryRandom.RandIntInRange(-499, -1));
        LibraryERM.PostGeneralJnlLine(GenJournalLine[2]);

        CreateGenJournalLine(
          GenJournalLine[3], WorkDate() + 2, Customer."No.",
          GenJournalLine[1]."Document Type"::Payment, GenJournalLine[1]."Document Type"::Invoice, GenJournalLine[1]."Document No.", -GenJournalLine[1].Amount - GenJournalLine[2].Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine[3]);

        // [WHEN] "Customer - Balance to Date" report is run
        Customer.SetRecFilter();
        CustomerBalanceToDate.SetTableView(Customer);
        CustomerBalanceToDate.InitializeRequest(false, false, false, WorkDate() + 1);
        Commit();
        CustomerBalanceToDate.Run();

        // [THEN] RemainingAmt is equal to 'X' + 'Y'
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('RemainingAmt',
            Format(GenJournalLine[1].Amount + GenJournalLine[2].Amount, 0,
                AutoFormat.ResolveAutoFormat("Auto Format"::AmountFormat, GenJournalLine[1]."Currency Code")));
    end;

    [Test]
    [HandlerFunctions('ProFormaInvoiceXML_RPH')]
    [Scope('OnPrem')]
    procedure PrintProFormaInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Pro Forma Invoive] [UI] [Order]
        // [SCENARIO 201636] Print REP 1302 "Standard Sales - Pro Forma Inv" from Sales Order page
        Initialize();
        UpdateGLSetupDefaultUnitAmountRounding();
        UpdateCompanyInfo();
        LibraryERM.SetLCYCode(LibraryUtility.GenerateGUID());
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Sales Order card
        CreateSalesOrderWithSevItemsForProForma(SalesHeader);

        // [WHEN] Invoke "Proforma Invoice" action
        RunStandardSalesProformaInvFromOrderPage(SalesHeader);

        // [THEN] REP 1302 "Standard Sales - Pro Forma Inv" has been printed
        // [THEN] Document line with zero Quantity has been printed (TFS 225721)
        VerifyProformaInvoiceBaseValues(SalesHeader);

        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('ProFormaInvoiceXML_RPH')]
    [Scope('OnPrem')]
    procedure ProFormaCurrencyAmountDecimals2Digits()
    var
        SalesLine: Record "Sales Line";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Pro Forma Invoive]
        // [SCENARIO 290824] REP 1302 "Standard Sales - Pro Forma Inv" in case of currency
        // [SCENARIO 290824] with "Unit-Amount Rounding Precision" = 0.00001,  Unit-Amount Decimal Places = 2:5,
        // [SCENARIO 290824] "Amount Rounding Precision" = 0.01, "Amount Decimal Places" = 2:2

        // [GIVEN] Currency with "Unit-Amount Rounding Precision" = 0.00001,  Unit-Amount Decimal Places = 2:5, "Amount Rounding Precision" = 0.01, "Amount Decimal Places" = 2:2
        CurrencyCode := CreateCurrencyWithDecimalPlaces(0.01, '2:5', 0.00001, '5:5');

        // [GIVEN] FCY Sales Invoice with "Unit Price" = 1000.11111, "Quantity" = 5, "VAT %" = 12 (vat amount = 600.06667)
        PrepareCustomFCYSalesInvoiceForProForma(SalesLine, CurrencyCode);

        // [WHEN] Print "Pro Forma Invoice" report
        RunStandardSalesProFormaInv(SalesLine."Document No.");

        // [THEN] Printed line values: "Quantity" = 5, "Unit Price" = 1000.112, "VAT Amount" = 600.07, "Amount" = 5000.56
        // [THEN] Printed total values: "TotalValue" = 5000.56, "TotalVATAmount" = 600.07, "TotalAmountInclVAT" = 5600.63
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), Rep1302DatasetErr);
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo', SalesLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity', 5);
        LibraryReportDataset.AssertCurrentRowValueEquals('Price', FormatDecimal(1000.112, 5));
        LibraryReportDataset.AssertCurrentRowValueEquals('LineAmount', FormatDecimal(5000.56, 2));
        LibraryReportDataset.AssertCurrentRowValueEquals('VATAmount', FormatDecimal(600.07, 2));
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), Rep1302DatasetErr);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalValue', FormatDecimal(5000.56, 2));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalVATAmount', FormatDecimal(600.07, 2));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmountInclVAT', FormatDecimal(5600.63, 2));
    end;

    [Test]
    [HandlerFunctions('ProFormaInvoiceXML_RPH')]
    [Scope('OnPrem')]
    procedure ProFormaCurrencyAmountDecimals5Digits()
    var
        SalesLine: Record "Sales Line";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Pro Forma Invoive]
        // [SCENARIO 290824] REP 1302 "Standard Sales - Pro Forma Inv" in case of currency
        // [SCENARIO 290824] with "Unit-Amount Rounding Precision" = 0.00001,  Unit-Amount Decimal Places = 5:5,
        // [SCENARIO 290824] "Amount Rounding Precision" = 0.00001, "Amount Decimal Places" = 5:5

        // [GIVEN] Currency with "Unit-Amount Rounding Precision" = 0.00001,  Unit-Amount Decimal Places = 5:5, "Amount Rounding Precision" = 0.00001, "Amount Decimal Places" = 5:5
        CurrencyCode := CreateCurrencyWithDecimalPlaces(0.00001, '5:5', 0.00001, '5:5');

        // [GIVEN] FCY Sales Invoice with "Unit Price" = 1000.11111, "Quantity" = 5, "VAT %" = 12 (vat amount = 600.06667)
        PrepareCustomFCYSalesInvoiceForProForma(SalesLine, CurrencyCode);

        // [WHEN] Print "Pro Forma Invoice" report
        RunStandardSalesProFormaInv(SalesLine."Document No.");

        // [THEN] Printed line values: "Quantity" = 5, "Unit Price" = 1000.11111, "VAT Amount" = 600.06667, "Amount" = 5000.55555
        // [THEN] Printed total values: "TotalValue" = 5000.55555, "TotalVATAmount" = 600.06667, "TotalAmountInclVAT" = 5600.62222
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), Rep1302DatasetErr);
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo', SalesLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity', 5);
        LibraryReportDataset.AssertCurrentRowValueEquals('Price', FormatDecimal(1000.11111, 5));
        LibraryReportDataset.AssertCurrentRowValueEquals('LineAmount', FormatDecimal(5000.55555, 5));
        LibraryReportDataset.AssertCurrentRowValueEquals('VATAmount', FormatDecimal(600.06667, 5));
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), Rep1302DatasetErr);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalValue', FormatDecimal(5000.55555, 5));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalVATAmount', FormatDecimal(600.06667, 5));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmountInclVAT', FormatDecimal(5600.62222, 5));
    end;

    [Test]
    [HandlerFunctions('SalesShipmentSaveAsExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesShipmentReportHasExternalDocNoAndOrderNo()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ExternalDocNo: array[2] of Code[10];
        Index: Integer;
    begin
        // [FEATURE] [Sales Shipment] [UT]
        // [SCENARIO 331988] Report 208 "Sales - Shipment" exposes "External Document No." and "Order No." fields as "Purchase Order No." and "Our Document No." respectively
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Two posted Sales Shipments with different "External Document No."
        CustomerNo := LibrarySales.CreateCustomerNo();
        ItemNo := LibraryInventory.CreateItemNo();
        for Index := 1 to 2 do begin
            ExternalDocNo[Index] := LibraryUtility.GenerateGUID();
            LibrarySales.CreateSalesDocumentWithItem(
              SalesHeader[Index], SalesLine[Index], SalesHeader[Index]."Document Type"::Order,
              CustomerNo, ItemNo, LibraryRandom.RandIntInRange(2, 5), '', 0D);
            SalesHeader[Index].Validate("External Document No.", ExternalDocNo[Index]);
            SalesHeader[Index].Modify(true);
            LibrarySales.PostSalesDocument(SalesHeader[Index], true, false);
        end;

        // [WHEN] Run Report 208 "Sales - Shipment" and save as Excel, handled by SalesShipmentSaveAsExcelRequestPageHandler
        Commit();
        SalesShipmentHeader.SetRange("Sell-to Customer No.", CustomerNo);
        REPORT.Run(REPORT::"Sales - Shipment", true, false, SalesShipmentHeader);

        // [THEN] Verify that "Our Document No." and "Purchase Order No." report fields are populated accordingly.
        VerifySalesShipmentDocFieldsExcel(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('AgedAccountsReceivableReportRequestPageHandler')]
    procedure AgedAccReceivableCustomerPhoneNoAndContact()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // [SCENARIO 290824] Aged Accounts Receivable report prints customer phone number and contact when Print Details = "Yes"
        Initialize();

        // [GIVEN] Customer "CUST" with Phone No. = "12345", Contact = "CONT"
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Phone No.",
          CopyStr(
            LibraryUtility.GenerateRandomNumericText(MaxStrLen(Customer."Phone No.")),
            1,
            MaxStrLen(Customer."Phone No.")));
        Customer.Validate(Contact,
          CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Customer.Contact), 0),
            1,
            MaxStrLen(Customer.Contact)));
        Customer.Modify();

        // [GIVEN] Create and post invoice for Customer "CUST", "Posting Date" = "01.01.2019" and "Due Date" = "01.02.2019"
        CreatePostSalesInvoiceWithDueDateCalc(Customer."No.", CalcDate('<1M>', WorkDate()));

        // [WHEN] Run report Aged Accounts Receivable with "Print Details" = "Yes"
        RunAgedAccountsReceivableWithParameters(Customer, CalcDate('<2M>', WorkDate()));

        // [THEN] Customer "CUST" is printed with Phone No. = "12345", Contact = "CONT"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Name1_Cust', Customer."No.");
        LibraryReportDataset.AssertElementWithValueExists('CustomerPhoneNo', Customer."Phone No.");
        LibraryReportDataset.AssertElementWithValueExists('CustomerContactName', Customer.Contact);
    end;

    [Test]
    [HandlerFunctions('ProFormaInvoiceXML_RPH')]
    [Scope('OnPrem')]
    procedure SalesProFormaInvoiceCorrectlyCalculateVATAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        Quantity: Decimal;
        UnitPrice: Decimal;
        AmountInclVAT: Decimal;
        VATAmount: Decimal;
        ItemNo: Code[20];
    begin
        // [SCENARIO 360280] The "VAT Amount" is calculated correctly for 2 equal lines,
        // [SCENARIO 360280] when the Sum of not rounding "Line Amount Incl. VAT" will be round in different side
        Initialize();

        // [GIVEN] Create Sales Header
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        Quantity := LibraryRandom.RandInt(10);
        ItemNo := LibraryInventory.CreateItemNo();

        // [WHEN] Create first Sales Line
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::Item, ItemNo, Quantity);

        // [GIVEN] Create "Amount Inc. VAT" with prescision = 0.001, which will be round down. The 2*"Amount Inc. VAT" will be rounded up.
        AmountInclVAT := LibraryRandom.RandDecInDecimalRange(50, 100, 2) + LibraryRandom.RandDecInDecimalRange(0.003, 0.004, 3);
        UnitPrice := AmountInclVAT / (1 + SalesLine[1]."VAT %" / 100) / Quantity;
        SalesLine[1].Validate("Unit Price", UnitPrice);
        SalesLine[1].Modify(true);

        // [GIVEN] Create second Sales Line with the same Quantity and Unit Price
        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::Item, ItemNo, Quantity);
        SalesLine[2].Validate("Unit Price", UnitPrice);
        SalesLine[2].Modify(true);
        Commit();

        // [WHEN] Print "Pro Forma Invoice" report
        RunStandardSalesProFormaInv(SalesLine[1]."Document No.");

        // [THEN] The fields VATAmount evaluates correctly
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), Rep1302DatasetErr);
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo', SalesLine[1]."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity', Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('LineAmount', Format(SalesLine[1]."Line Amount"));
        VATAmount := SalesLine[1]."Amount Including VAT" - SalesLine[1].Amount;
        LibraryReportDataset.AssertCurrentRowValueEquals('VATAmount', Format(VATAmount));

        Assert.IsTrue(LibraryReportDataset.GetNextRow(), Rep1302DatasetErr);
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity', Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('LineAmount', Format(SalesLine[2]."Line Amount"));
        VATAmount := SalesLine[2]."Amount Including VAT" - SalesLine[2].Amount;
        LibraryReportDataset.AssertCurrentRowValueEquals('VATAmount', Format(VATAmount));
    end;

    [Test]
    [HandlerFunctions('RHStandardSalesShipment')]
    [Scope('OnPrem')]
    procedure SalesStandardShipment()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        PostedShipmentNo: Code[20];
    begin
        // [FEATURE] [Standard Sales - Shipment]
        // [SCENARIO 306111] "Sales Standard Shipment" report prints basic header and line data
        Initialize();

        // [GIVEN] Set report "Sales Standard Shipment" as default for printing sales shipments
        SetReportSelection("Report Selection Usage"::"S.Shipment", Report::"Standard Sales - Shipment");

        // [GIVEN] Set report selection for sales shipme
        // [GIVEN] Create and post shipment for customer "C", item "I" with quantity "5"
        CreateAndPostSalesShipment(PostedShipmentNo, CreateCustomer());
        SalesShipmentHeader.Get(PostedShipmentNo);
        SalesShipmentLine.SetRange("Document No.", PostedShipmentNo);
        SalesShipmentLine.FindFirst();

        // [WHEN] Report "Sales Standard Shipment" is being printed
        SaveStandardSalesShipmentReport(PostedShipmentNo);

        // [THEN] Dataset contains data about customer "C", line with item "I" and Quantity "5"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo', PostedShipmentNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('SelltoCustomerNo', SalesShipmentHeader."Sell-to Customer No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemNo_Line', SalesShipmentLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_Line', Format(SalesShipmentLine.Quantity));
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ItemTrackingSummaryPageHandler,RHStandardSalesShipment')]
    [Scope('OnPrem')]
    procedure SalesStandardShipmentWithItemTracking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemTrackingCode: Record "Item Tracking Code";
        PostedShipmentNo: Code[20];
        Quantity: Decimal;
        ItemTrackingMode: Option " ","Assign Lot No.","Select Entries","Verify Entries";
    begin
        // [FEATURE] [Standard Sales - Shipment] [Item Tracking]
        // [SCENARIO 306111] "Sales Standard Shipment" report prints item tracking data
        Initialize();

        // [GIVEN] Set report "Sales Standard Shipment" as default for printing sales shipments
        SetReportSelection("Report Selection Usage"::"S.Shipment", Report::"Standard Sales - Shipment");

        // [GIVEN] Create Item "I" with lot item tracking
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateTrackedItem(
            Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Fixed Reorder Qty.", false, Quantity,
            ItemTrackingCode.Code);

        // [GIVEN] Post positive adjustment for item "I" with assigned "Lot No." = "L1" and Quantity = 5
        CreateAndPostItemJournalLineWithTracking(Item."No.", Quantity);

        // [GIVEN] Create and post sales order with item "I" and selected "Lot No." = "L1" and Quantity = 5
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue for Page Handler - LotItemTrackingPageHandler.
        SalesLine.OpenItemTrackingLines();  // Select Item Tracking on Page handler - LotItemTrackingPageHandler.
        PostedShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Report "Sales Standard Shipment" is being printed with option "Show Serial/Lot Number Appendix" = Yes
        SaveStandardSalesShipmentReport(PostedShipmentNo);

        // [THEN] Dataset contains data about lot number "L1" for item "I" and Quantity "5"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('TrackingSpecBufferEntryNo', 1);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TrackingSpecBufferNo', Item."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('TrackingSpecBufferLotNo', FindAssignedLotNo(Item."No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('TrackingSpecBufferQty', Quantity);
    end;

    [Test]
    [HandlerFunctions('RHStandardSalesShipment')]
    [Scope('OnPrem')]
    procedure SalesStandardShipmentShipToBillToCustomer()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        Customer: Record Customer;
        PostedShipmentNo: Code[20];
    begin
        // [FEATURE] [Standard Sales - Shipment]
        // [SCENARIO 306111] "Sales Standard Shipment" report dataset has ship-to and bill-to customer data
        Initialize();

        // [GIVEN] Set report "Sales Standard Shipment" as default for printing sales shipments
        SetReportSelection("Report Selection Usage"::"S.Shipment", Report::"Standard Sales - Shipment");

        // [GIVEN] Customer "C1" with Bill-to customer "C2"
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        Customer.Modify();

        // [GIVEN] Create and post shipment for customer "C1"
        CreateAndPostSalesShipment(PostedShipmentNo, Customer."No.");
        SalesShipmentHeader.Get(PostedShipmentNo);
        SalesShipmentLine.SetRange("Document No.", PostedShipmentNo);
        SalesShipmentLine.FindFirst();

        // [WHEN] Report "Sales Standard Shipment" is being printed
        SaveStandardSalesShipmentReport(PostedShipmentNo);

        // [THEN] Dataset contains data for ship-to customer "C1"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo', PostedShipmentNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ShipToAddress1', SalesShipmentHeader."Ship-to Name");
        // [THEN] Dataset contains data for bill-to customer "C2"
        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress1', SalesShipmentHeader."Bill-to Name");
    end;

    [Test]
    [HandlerFunctions('RHStandardSalesReturnReceipt')]
    [Scope('OnPrem')]
    procedure SalesStandardReturnReceipt()
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        ReturnReceiptLine: Record "Return Receipt Line";
        PostedReturnReceiptNo: Code[20];
    begin
        // [FEATURE] [Standard Sales - Return Receipt]
        // [SCENARIO 306111] "Standard Sales - Return Rcpt." report prints basic header and line data
        Initialize();

        // [GIVEN] Set report "Standard Sales - Return Rcpt.." as default for printing return receipts
        SetReportSelection("Report Selection Usage"::"S.Ret.Rcpt.", Report::"Standard Sales - Return Rcpt.");

        // [GIVEN] Create and post return order for customer "C", item "I" with quantity "5"
        CreateAndPostSalesReturnReceipt(PostedReturnReceiptNo, CreateCustomer());
        ReturnReceiptHeader.Get(PostedReturnReceiptNo);
        ReturnReceiptLine.SetRange("Document No.", PostedReturnReceiptNo);
        ReturnReceiptLine.FindFirst();

        // [WHEN] Report "Standard Sales - Return Rcpt.." is being printed
        SaveStandardSalesReturnReceiptReport(PostedReturnReceiptNo);

        // [THEN] Dataset contains data about customer "C", line with item "I" and Quantity "5"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo', PostedReturnReceiptNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('SelltoCustomerNo', ReturnReceiptHeader."Sell-to Customer No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemNo_Line', ReturnReceiptLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_Line', Format(ReturnReceiptLine.Quantity));
    end;

    [Test]
    [HandlerFunctions('RHStandardSalesReturnReceipt')]
    [Scope('OnPrem')]
    procedure SalesStandardReturnReceiptShipToBillToCustomer()
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        ReturnReceiptLine: Record "Return Receipt Line";
        Customer: Record Customer;
        PostedReturnReceiptNo: Code[20];
    begin
        // [FEATURE] [Standard Sales - Return Receipt]
        // [SCENARIO 306111] "Standard Sales - Return Rcpt." report dataset has ship-to and bill-to customer data
        Initialize();

        // [GIVEN] Set report "Standard Sales - Return Rcpt.." as default for printing return receipts
        SetReportSelection("Report Selection Usage"::"S.Ret.Rcpt.", Report::"Standard Sales - Return Rcpt.");

        // [GIVEN] Customer "C1" with Bill-to customer "C2"
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        Customer.Modify();

        // [GIVEN] Create and post return order for customer "C1"
        CreateAndPostSalesReturnReceipt(PostedReturnReceiptNo, Customer."No.");
        ReturnReceiptHeader.Get(PostedReturnReceiptNo);
        ReturnReceiptLine.SetRange("Document No.", PostedReturnReceiptNo);
        ReturnReceiptLine.FindFirst();

        // [WHEN] Report "Standard Sales - Return Rcpt.." is being printed
        SaveStandardSalesReturnReceiptReport(PostedReturnReceiptNo);

        // [THEN] Dataset contains data for ship-to customer "C1"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo', PostedReturnReceiptNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ShipToAddress1', ReturnReceiptHeader."Ship-to Name");
        // [THEN] Dataset contains data for bill-to customer "C2"
        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress1', ReturnReceiptHeader."Bill-to Name");
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivableFileName')]
    procedure AgedAccountsReceivableCurrencyFilterNotSet()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        CurrencyCode: array[2] of Code[10];
        DocumentNo: Code[20];
        PeriodLength: DateFormula;
        Filters: Text;
        AmountFCY: array[2] of Decimal;
        AmountLCY: array[2] of Decimal;
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // [SCENARIO 397446] Run Aged Accounts Receivable report for Sales Documents with different currencies when Currency Filter is not set.
        Initialize();

        // [GIVEN] Posted Sales Invoice with Currency "C1". Posted Sales Invoice with Currency "C2".
        LibrarySales.CreateCustomer(Customer);
        CurrencyCode[1] := LibraryERM.CreateCurrencyWithRandomExchRates();
        CurrencyCode[2] := LibraryERM.CreateCurrencyWithRandomExchRates();
        DocumentNo := CreateAndPostSalesDocument(SalesLine, Customer."No.", SalesLine."Document Type"::Invoice, CurrencyCode[1], true);
        GetSalesDocAmounts(SalesLine."Document Type"::Invoice, DocumentNo, AmountFCY[1], AmountLCY[1]);
        DocumentNo := CreateAndPostSalesDocument(SalesLine, Customer."No.", SalesLine."Document Type"::Invoice, CurrencyCode[2], true);
        GetSalesDocAmounts(SalesLine."Document Type"::Invoice, DocumentNo, AmountFCY[2], AmountLCY[2]);

        // [WHEN] Run report Aged Accounts Receivable. "Currency Filter" is not set in "Filter Totals by" section in Customer block.
        Evaluate(PeriodLength, StrSubstNo('<%1M>', LibraryRandom.RandInt(5)));
        Customer.SetRecFilter();
        SaveAgedAccountsReceivable(Customer, AgingBy::"Due Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // [THEN] Lines for currencies "C1" and "C2" are shown. Totals are equal to sum of Amount(LCY) of Invoices.
        LibraryXPathXMLReader.Initialize(LibraryVariableStorage.DequeueText(), '');
        VerifyCurrencyAgedAccountsReceivable(CurrencyCode[1], AmountFCY[1], AmountLCY[1], 0);
        VerifyCurrencyAgedAccountsReceivable(CurrencyCode[2], AmountFCY[2], AmountLCY[2], 1);
        VerifyTotalLCYAgedAccountsReceivable(AmountLCY[1] + AmountLCY[2]);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Result/CurrrencyCode', 2);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Result/TempCurrCode', 2);

        // [THEN] Filter on the report page does not contain "Currency Filter".
        Filters := LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//Result/CustFilter', 0);
        asserterror Assert.ExpectedMessage('Currency Filter', Filters);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivableFileName')]
    procedure AgedAccountsReceivableCurrencyFilterSetOneCurrency()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        CurrencyCode: array[2] of Code[10];
        DocumentNo: Code[20];
        PeriodLength: DateFormula;
        Filters: Text;
        AmountFCY: Decimal;
        AmountLCY: Decimal;
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // [SCENARIO 397446] Run Aged Accounts Receivable report for Sales Documents with different currencies when Currency Filter is set to one currency.
        Initialize();

        // [GIVEN] Posted Sales Invoice with Currency "C1". Posted Sales Invoice with Currency "C2".
        LibrarySales.CreateCustomer(Customer);
        CurrencyCode[1] := LibraryERM.CreateCurrencyWithRandomExchRates();
        CurrencyCode[2] := LibraryERM.CreateCurrencyWithRandomExchRates();
        CreateAndPostSalesDocument(SalesLine, Customer."No.", SalesLine."Document Type"::Invoice, CurrencyCode[1], true);
        DocumentNo := CreateAndPostSalesDocument(SalesLine, Customer."No.", SalesLine."Document Type"::Invoice, CurrencyCode[2], true);
        GetSalesDocAmounts(SalesLine."Document Type"::Invoice, DocumentNo, AmountFCY, AmountLCY);

        // [WHEN] Run report Aged Accounts Receivable. Set "Currency Filter" = "C2" in "Filter Totals by" section in Customer block.
        Evaluate(PeriodLength, StrSubstNo('<%1M>', LibraryRandom.RandInt(5)));
        Customer.SetRecFilter();
        Customer.SetRange("Currency Filter", CurrencyCode[2]);
        SaveAgedAccountsReceivable(Customer, AgingBy::"Due Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // [THEN] Only line for currency "C2" is shown. Totals are equal to corresponding values of the posted Invoice with Currency "C2".
        LibraryXPathXMLReader.Initialize(LibraryVariableStorage.DequeueText(), '');
        VerifyCurrencyAgedAccountsReceivable(CurrencyCode[2], AmountFCY, AmountLCY, 0);
        VerifyTotalLCYAgedAccountsReceivable(AmountLCY);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Result/CurrrencyCode', 1);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Result/TempCurrCode', 1);

        // [THEN] Filter on the report page contains "Currency Filter: C2".
        Filters := LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//Result/CustFilter', 0);
        Assert.ExpectedMessage(StrSubstNo('Currency Filter: %1', CurrencyCode[2]), Filters);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivableFileName')]
    procedure AgedAccountsReceivableCurrencyFilterSetTwoCurrencies()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        CurrencyCode: array[2] of Code[10];
        DocumentNo: Code[20];
        PeriodLength: DateFormula;
        Filters: Text;
        AmountFCY: array[2] of Decimal;
        AmountLCY: array[2] of Decimal;
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // [SCENARIO 397446] Run Aged Accounts Receivable report for Sales Documents with different currencies when Currency Filter is set for two currencies.
        Initialize();

        // [GIVEN] Posted Sales Invoice with Currency "C1". Posted Sales Invoice with Currency "C2".
        LibrarySales.CreateCustomer(Customer);
        CurrencyCode[1] := LibraryERM.CreateCurrencyWithRandomExchRates();
        CurrencyCode[2] := LibraryERM.CreateCurrencyWithRandomExchRates();
        DocumentNo := CreateAndPostSalesDocument(SalesLine, Customer."No.", SalesLine."Document Type"::Invoice, CurrencyCode[1], true);
        GetSalesDocAmounts(SalesLine."Document Type"::Invoice, DocumentNo, AmountFCY[1], AmountLCY[1]);
        DocumentNo := CreateAndPostSalesDocument(SalesLine, Customer."No.", SalesLine."Document Type"::Invoice, CurrencyCode[2], true);
        GetSalesDocAmounts(SalesLine."Document Type"::Invoice, DocumentNo, AmountFCY[2], AmountLCY[2]);

        // [WHEN] Run report Aged Accounts Receivable. Set "Currency Filter" = "C1|C2" in "Filter Totals by" section in Customer block.
        Evaluate(PeriodLength, StrSubstNo('<%1M>', LibraryRandom.RandInt(5)));
        Customer.SetRecFilter();
        Customer.SetFilter("Currency Filter", '%1|%2', CurrencyCode[1], CurrencyCode[2]);
        SaveAgedAccountsReceivable(Customer, AgingBy::"Due Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // [THEN] Lines for currencies "C1" and "C2" are shown. Totals are equal to sum of Amount(LCY) of Invoices.
        LibraryXPathXMLReader.Initialize(LibraryVariableStorage.DequeueText(), '');
        VerifyCurrencyAgedAccountsReceivable(CurrencyCode[1], AmountFCY[1], AmountLCY[1], 0);
        VerifyCurrencyAgedAccountsReceivable(CurrencyCode[2], AmountFCY[2], AmountLCY[2], 1);
        VerifyTotalLCYAgedAccountsReceivable(AmountLCY[1] + AmountLCY[2]);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Result/CurrrencyCode', 2);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Result/TempCurrCode', 2);

        // [THEN] Filter on the report page contains "Currency Filter: C1|C2".
        Filters := LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//Result/CustFilter', 0);
        Assert.ExpectedMessage(StrSubstNo('Currency Filter: %1|%2', CurrencyCode[1], CurrencyCode[2]), Filters);
    end;

    [Test]
    [HandlerFunctions('ProFormaInvoiceXML_RPH')]
    procedure ProFormaInvoiceForUnshippedOrderAtLocationRequireShipment()
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Pro Forma Invoive] [Warehouse]
        // [SCENARIO 402887] Quantity in Pro forma invoice for unshipped sales at WMS location is equal to the sales line's Quantity.
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Location with required shipment.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);

        // [GIVEN] Sales order at the WMS location, quantity = 10.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', LibraryInventory.CreateItemNo(),
          LibraryRandom.RandInt(10), Location.Code, WorkDate());

        // [WHEN] Print Pro forma invoice.
        RunStandardSalesProformaInvFromOrderPage(SalesHeader);

        // [THEN] Quantity in the report = 10 (nothing is shipped yet and the customer cannot set what will be invoiced).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemDescription', SalesLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity', SalesLine.Quantity);

        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('ProFormaInvoiceXML_RPH')]
    procedure ProFormaInvoiceForShippedOrderAtLocationRequireShipment()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // [FEATURE] [Pro Forma Invoive] [Warehouse]
        // [SCENARIO 402887] Quantity in Pro Forma Invoice for shipped sales at WMS location is equal to sales line's "Qty. to Invoice"
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Location with required shipment.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Sales order at the WMS location, quantity = 10.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', LibraryInventory.CreateItemNo(),
          LibraryRandom.RandInt(10), Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create and post warehouse shipment.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
            DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No."));
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [GIVEN] Set "Qty. to Invoice" = 0 on the sales line.
        SalesHeader.Find();
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.Find();
        SalesLine.Validate("Qty. to Invoice", 0);
        SalesLine.Modify(true);

        // [WHEN] Print Pro forma invoice.
        RunStandardSalesProformaInvFromOrderPage(SalesHeader);

        // [THEN] Quantity in the report = 0 (as defined by customer within shipped quantity).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemDescription', SalesLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity', 0);

        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ItemTrackingSummaryPageHandler,RHStandardSalesShipmentSetShowItemTracking')]
    procedure SalesStandardShipmentReportForMultipleShipmentsWithItemTracking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PostedShipmentNo: array[2] of Code[20];
        RequestPageXML: Text;
        ItemTrackingMode: Option " ","Assign Lot No.","Select Entries","Verify Entries";
        i: Integer;
    begin
        // [FEATURE] [Standard Sales - Shipment] [Item Tracking]
        // [SCENARIO 414343] Printing "Standard Sales - Shipment" for multiple shipments with item tracking.
        Initialize();

        // [GIVEN] Lot-tracked item.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Post positive adjustment with assigned "Lot No." = "L" and Quantity = 10.
        CreateAndPostItemJournalLineWithTracking(Item."No.", LibraryRandom.RandIntInRange(20, 40));

        // [GIVEN] Create and ship two sales orders, select "Lot No." = "L" and Quantity = 5 for each.
        for i := 1 to 2 do begin
            CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandInt(10));
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");
            SalesLine.OpenItemTrackingLines();
            PostedShipmentNo[i] := LibrarySales.PostSalesDocument(SalesHeader, true, false);
        end;

        // [WHEN] Run "Standard Sales - Shipment" report for both sales shipments with "Show Serial/Lot Number Appendix" = Yes.
        SalesShipmentHeader.SetFilter("No.", '%1|%2', PostedShipmentNo[1], PostedShipmentNo[2]);
        RequestPageXML := Report.RunRequestPage(Report::"Standard Sales - Shipment");
        LibraryReportDataset.RunReportAndLoad(Report::"Standard Sales - Shipment", SalesShipmentHeader, RequestPageXML);

        // [THEN] The report shows both shipments and lot no. "L" for each.
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo', PostedShipmentNo[1]);
        LibraryReportDataset.AssertCurrentRowValueEquals('TrackingSpecBufferLotNo', FindAssignedLotNo(Item."No."));

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo', PostedShipmentNo[2]);
        LibraryReportDataset.AssertCurrentRowValueEquals('TrackingSpecBufferLotNo', FindAssignedLotNo(Item."No."));
    end;

    [Test]
    [HandlerFunctions('StandardStatementNoLogInteractionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardStatementNoILEWhenILEDisabled()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        RequestPageXML: Text;
        InteractionLogEntryCount: Integer;
    begin
        // [FEATURE] [Standard Statement]
        // [SCENARIO 426814] REP 1316 "Standard Statement" should not log interaction log entry if user disabled it
        Initialize();

        // [GIVEN] Interaction Log Entry count = "X"
        InteractionLogEntry.Reset();
        InteractionLogEntryCount := InteractionLogEntry.Count();

        // [GIVEN] Customer "C" with Customer Ledger Entry
        LibrarySales.CreateCustomer(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");
        MockCustLedgerEntry(CustLedgerEntry, Customer."No.", -LibraryRandom.RandInt(100), WorkDate());
        Customer.SetRecFilter();
        Commit();

        // [WHEN] When run "Standard Statement" report for the customer "C" and Log Interaction = false
        LibraryVariableStorage.Enqueue(false);
        RequestPageXML := REPORT.RunRequestPage(REPORT::"Standard Statement");
        LibraryReportDataset.RunReportAndLoad(REPORT::"Standard Statement", Customer, RequestPageXML);

        // [THEN] No Interaction Log Entries created, record count = "X"
        InteractionLogEntry.Reset();
        Assert.RecordCount(InteractionLogEntry, InteractionLogEntryCount);
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Log Interaction control is not visible');
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDateEnableShowEntriesWithZeroBalance')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateDoesNotShowExtraEntriesWithZeroBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        InvoiceAmount: array[2] of Decimal;
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Customer - Balance to Date]
        // [SCENARIO 431846] Report "Customer - Balance to Date" does not print extra lines for applied entries
        Initialize();

        // [GIVEN] Customer C
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Posted invoice 1 with Customer C and Amount = 1000
        InvoiceAmount[1] := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateGenJnlLineWithBalAccount(
            GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
            Customer."No.", GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            InvoiceAmount[1]);
        InvoiceNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted invoice 1 with Customer C and Amount = 2000
        InvoiceAmount[2] := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateGenJnlLineWithBalAccount(
            GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
            Customer."No.", GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            InvoiceAmount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted payment with Customer C and Amount = -1000 applied to invoice 1
        CreateGenJnlLineWithBalAccount(
            GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer,
            Customer."No.", GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            -InvoiceAmount[1]);
        GenJournalLine.Validate("Applies-to Doc. Type", "Gen. Journal Document Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Stan ran report "Customer - Balance to Date" and enabled "Show Entries with Zero Balance" on request page
        RunCustomerBalanceToDateWithLimitTotal(GenJournalLine."Account No.", '', '', '');

        // [WHEN] Stan pushes OK on request page
        // Done in RHVendorBalanceToDateEnableShowEntriesWithZeroBalance

        // [THEN] Dataset does not contain record related to original payment (only as applied entry)
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Payment));
    end;

    [Test]
    [HandlerFunctions('RHStandardSalesShipment,UndoShipmentConfirmHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesShipmentCorrectionLines()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 443284] Check Correction Lines not showing on Standard Sales Shipment Report.

        // [GIVEN] Create and Post Sales Shipment and then undo the Shipment.
        Initialize();
        CreateAndPostSalesShipment(DocumentNo, CreateCustomer());

        // [GIVEN] Undo the Shipment.
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.FindFirst();
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // [WHEN] Save Standard Sales Shipment Report.
        SaveStandardSalesShipmentReportWithCorrectionLines(DocumentNo);

        // [THEN] Verify Correction Lines.
        LibraryReportDataset.LoadDataSetFile();
        VerifyUndoneQuantityInStandardSalesShipmentReport(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('RHStandardSalesShipment,UndoShipmentConfirmHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesShipmentWithOutCorrectionLines()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 443284] Check Correction Lines not showing on Standard Sales Shipment Report.

        // [GIVEN] Create and Post Sales Shipment and then undo the Shipment.
        Initialize();
        CreateAndPostSalesShipment(DocumentNo, CreateCustomer());

        // [GIVEN] Undo the Shipment.
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.FindFirst();
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // [WHEN] Save Standard Sales Shipment Report.
        SaveStandardSalesShipmentReportWithOutCorrectionLines(DocumentNo);

        // [THEN] Verify Correction Lines expecting as error.
        LibraryReportDataset.LoadDataSetFile();
        asserterror VerifyUndoneQuantityInStandardSalesShipmentReport(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDateEnableShowEntriesWithZeroBalance')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateShowEntriesWithBalanceDateFilter()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        GLAccountNo: array[2] of Code[20];
        Amount: array[2] of Decimal;
        AppliestoDocNo: Code[20];
    begin
        // [SCENARIO 461061] Report Customer - Balance to Date - Option show entries with zero balance
        Initialize();

        // [GIVEN] Create Customer, 2 G/L Accounts and 2 amounts variables
        CustomerNo := LibrarySales.CreateCustomerNo();
        GLAccountNo[1] := LibraryERM.CreateGLAccountNo();
        GLAccountNo[2] := LibraryERM.CreateGLAccountNo();
        Amount[1] := LibraryRandom.RandDecInRange(1000, 2000, 2);
        Amount[2] := LibraryRandom.RandDecInRange(1000, 1500, 2);

        // [GIVEN] Post invoice and save posted invoice document No.
        CreateGenJnlLineWithBalAccount(
        GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
        CustomerNo, GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo[1], Amount[1]);
        AppliestoDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Post payment and apply with invoice posted in last step.
        CreateGenJnlLineWithBalAccount(
         GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer,
         CustomerNo, GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo[2], -Amount[1]);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliestoDocNo);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create and post Invoice
        CreateGenJnlLineWithBalAccount(
        GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
        CustomerNo, GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo[1], Amount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create and post payment and not apply with last invoice
        CreateGenJnlLineWithBalAccount(
        GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer,
        CustomerNo, GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo[2], -Amount[2]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Run report "Customer - Balance to Date" and enabled "Show Entries with Zero Balance" on request page
        RunCustomerBalanceToDateWithLimitTotal(GenJournalLine."Account No.", '', '', '');

        // [WHEN] pushes OK on request page
        // Done in RHVendorBalanceToDateEnableShowEntriesWithZeroBalance
        // [THEN] Report shows formatted invoice and payment entries for customer
        VerifyAppliesCustomerEntriesAndBalanceInCustomerBalanceToDate(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ItemTrackingSummaryPageHandler,RHStandardSalesShipmentSetShowItemTracking')]
    procedure SalesStandardShipmentReportWithMultipleItemTracking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PostedShipmentNo: Code[20];
        RequestPageXML: Text;
        ItemTrackingMode: Option " ","Assign Lot No.","Select Entries","Verify Entries";
    begin
        // [SCENARIO 466086] Report 1308 printed with RDLC layout shows only first Serial No.
        Initialize();

        // [GIVEN] Lot-tracked item.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Post positive adjustment with assigned "Lot No."
        CreateAndPostItemJournalLineWithTracking(Item."No.", 1);
        CreateAndPostItemJournalLineWithTracking(Item."No.", 1);

        // [GIVEN] Create and ship sales orders, select "Lot No."and Quantity = 2
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 2);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Post Sales Shipment
        PostedShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Run "Standard Sales - Shipment" report with "Show Serial/Lot Number Appendix" = Yes.
        SalesShipmentHeader.SetFilter("No.", PostedShipmentNo);
        RequestPageXML := Report.RunRequestPage(Report::"Standard Sales - Shipment");
        LibraryReportDataset.RunReportAndLoad(Report::"Standard Sales - Shipment", SalesShipmentHeader, RequestPageXML);

        // [VERIFY] Verify Second Serial No. exist in the report.
        LibraryReportDataset.SearchForElementByValue('TrackingSpecBufferLotNo', FindAssignedLotNo(Item."No."));
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDateEnableShowEntriesWithZeroBalance')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateShowsIncorrectBalanceWhenRunningForAllCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        InvoiceAmount: array[2] of Decimal;
        InvoiceNo: array[2] of Code[20];
    begin
        // [SCENARIO 467715] Customer-Balance to Date shows incorrect Balance when running this report for all Customers.
        Initialize();

        // [GIVEN] Create new Customer C
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create random invoice amount and 1st invoice journal line with Bal Account for Customer C
        InvoiceAmount[1] := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateGenJnlLineWithBalAccount(
            GenJournalLine,
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Customer,
            Customer."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(),
            InvoiceAmount[1]);

        // [Then] Post 1st invoice
        InvoiceNo[1] := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create random invoice amount and 2nd invoice journal line with Bal Account for Customer C
        InvoiceAmount[2] := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateGenJnlLineWithBalAccount(
            GenJournalLine,
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Customer,
            Customer."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(),
            InvoiceAmount[2]);

        // [Then] Post 2nd invoice
        InvoiceNo[2] := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create a journal line for payment with Customer C with invoice amount 1
        CreateGenJnlLineWithBalAccount(
            GenJournalLine,
            GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer,
            Customer."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(),
            -InvoiceAmount[1]);

        // [GIVEN] Applied 1st posted invoice to payment
        GenJournalLine.Validate("Posting Date", CalcDate('<CM>', GenJournalLine."Posting Date"));
        GenJournalLine.Validate("Applies-to Doc. Type", "Gen. Journal Document Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo[1]);
        GenJournalLine.Modify();

        // [THEN] Post the payment
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run Customer Balance to Date report for specific customer with Unapplied Entries = No
        RunCustomerBalanceToDateWithCustomer(GenJournalLine."Account No.", false, GenJournalLine."Posting Date" - 1);

        // [VERIFY] Verify: Data on Customer Balance to Date report resultset
        VerifyCustomerEntriesAmountInCustomerBalanceToDate(InvoiceAmount, InvoiceNo);

        // [WHEN] Run Customer Balance to Date report for all customer with Unapplied Entries = No
        RunCustomerBalanceToDateForAllCustomer(false, GenJournalLine."Posting Date" - 1);

        // [VERIFY] Verify: Data on Customer Balance to Date report resultset for specific customer when running report for all customer
        VerifyCustomerEntriesAmountInCustomerBalanceToDateForSpecificCustomer(Customer."No.", InvoiceAmount, InvoiceNo);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDateEnableShowEntriesWithZeroBalance')]
    [Scope('OnPrem')]
    procedure VerifyCustomerBalanceToDateShowsAllCustomerLedgerEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        InvoiceAmount: array[2] of Decimal;
        InvoiceNo: array[2] of Code[20];
    begin
        // [SCENARIO] Customer Balance to Date shows only Customer Ledger Entries
        Initialize();

        // [GIVEN] Create new Customer C
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create random invoice amount and 1st invoice journal line with Bal Account for Customer C
        InvoiceAmount[1] := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateGenJnlLineWithBalAccount(
            GenJournalLine,
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Customer,
            Customer."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(),
            InvoiceAmount[1]);

        // [Then] Post 1st invoice
        InvoiceNo[1] := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create random invoice amount and 2nd invoice journal line with Bal Account for Customer C
        InvoiceAmount[2] := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateGenJnlLineWithBalAccount(
            GenJournalLine,
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Customer,
            Customer."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(),
            InvoiceAmount[2]);

        // [Then] Post 2nd invoice
        InvoiceNo[2] := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create a journal line for payment with Customer C with invoice amount 1
        CreateGenJnlLineWithBalAccount(
            GenJournalLine,
            GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer,
            Customer."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(),
            -InvoiceAmount[1]);

        // [GIVEN] Applied 1st posted invoice to payment
        GenJournalLine.Validate("Posting Date", CalcDate('<CM>', GenJournalLine."Posting Date"));
        GenJournalLine.Validate("Applies-to Doc. Type", "Gen. Journal Document Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceNo[1]);
        GenJournalLine.Modify();

        // [THEN] Post the payment
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run Customer Balance to Date report for specific customer with Unapplied Entries = No
        RunCustomerBalanceToDateWithCustomer(GenJournalLine."Account No.", false, GenJournalLine."Posting Date" - 1);

        // [VERIFY] Verify: Data on Customer Balance to Date report resultset
        VerifyTotalOnCustBalanceToDateWithLCY(DetailedCustLedgEntryAmount(Customer."No.", GenJournalLine."Posting Date" - 1));

        // [WHEN] Run Customer Balance to Date report for specific customer with Unapplied Entries = Yes
        RunCustomerBalanceToDateWithCustomer(GenJournalLine."Account No.", true, GenJournalLine."Posting Date");

        // [VERIFY] Verify: Data on Customer Balance to Date report resultset
        VerifyTotalOnCustBalanceToDateWithLCY(DetailedCustLedgEntryAmount(Customer."No.", GenJournalLine."Posting Date"));
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivableFileName')]
    [Scope('OnPrem')]
    procedure AgedAccountReceivablesReportsPrioritizeMostRecentPostingCausingFaultyReports()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        DocumentNo: Code[20];
        Amount: Decimal;
        AsofDate: Date;
        PeriodLength: DateFormula;
    begin
        //[SCENARIO 574822] Aged Account Receivables and Aged Account Payable Reports Prioritize Most Recent Posting Date Rather than Posting Date on Latest Entry Causing Faulty Reports

        Initialize();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        //[GIVEN] Create and Post Sales Invoice
        Amount := 12000;
        DocumentNo :=
        CreateAndPostSalesInvoiceWithOneLine(Customer."No.", '123', Amount, 0D);

        // [GIVEN] Create Payment Journal and post for Sales Invoice
        CreateGeneralJournalLine(GenJournalLine, 1, Customer."No.", GenJournalLine."Document Type"::Payment, -Amount);
        GenJournalLine.Validate("Posting Date", WorkDate());
        UpdateGenJournalLine(GenJournalLine, '', DocumentNo, -Amount);
        LibraryLowerPermissions.SetAccountReceivables();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Unapply The Payment for Sales Invoice
        LibraryERM.FindCustomerLedgerEntry(CustomerLedgerEntry, CustomerLedgerEntry."Document Type"::Payment, DocumentNo);
        UnapplyCustomerLedgerEntry(CustomerLedgerEntry, 20280201D);

        // [GIVEN] apply the payment again for the Sales Invoice
        CreateGeneralJournalLine(GenJournalLine, 1, Customer."No.", GenJournalLine."Document Type"::Payment, -Amount);
        GenJournalLine.Validate("Posting Date", WorkDate());
        UpdateGenJournalLine(GenJournalLine, '', DocumentNo, -Amount);
        LibraryLowerPermissions.SetAccountReceivables();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        //[WHEN] Run Aged Account Receivable Report
        AsofDate := 20271231D;
        SaveAgedAccReceivable(Customer, AgingBy::"Posting Date", HeadingType::"Date Interval", PeriodLength, false, true, AsofDate);

        //[THEN] Check These  Entries should not be there.
        LibraryReportDataset.AssertElementWithValueNotExist('CLEPostingDate', WorkDate());
    end;

    [Test]
    [HandlerFunctions('PostAndApplyCustPageHandler,PostApplicationPageHandler,MessageHandler,RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountsReceivableReportShouldShowCreditMemoWhenUsingOptionAgingByPostingDate()
    var
        Customer: Record Customer;
        Item: Record Item;
        CustledEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesCrMemo: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        PeriodLength: DateFormula;
    begin

        //[SCENARIO 599304] Aged Accounts Receivable/Payable reports do not show credit memo when using option Aging By = Posting Date
        Initialize();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Post Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesHeader."Posting Date" := WorkDate();
        SalesHeader.Modify();
        SalesLine.Validate("Unit Price", 1000); //Use a value that is easy to verify in the report
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Create and Post Sales Credit Memo
        LibrarySales.CreateSalesHeader(SalesCrMemo, SalesCrMemo."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesCrMemo, SalesLine.Type::Item, Item."No.", 1);
        SalesCrMemo."Posting Date" := WorkDate();
        SalesCrMemo.Modify();
        SalesLine.Validate("Unit Price", 1000); //Use a value that is easy to verify in the report
        SalesLine.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesCrMemo, true, false);

        // [WHEN] Apply Entries from Credit Memo to Invoice
        LibraryERM.FindCustomerLedgerEntry(CustledEntry, CustledEntry."Document Type"::"Credit Memo", DocumentNo);
        ApplyCustLedgerEntry(CustledEntry."Document Type"::"Credit Memo", Customer."No.");

        // [WHEN] Run Aged Accounts Receivable Report
        Evaluate(PeriodLength, '<1M>');
        Customer.SetRecFilter();
        Commit();
        SaveAgedAccountsReceivable(
            Customer, AgingBy::"Posting Date", HeadingType::"Date Interval", PeriodLength, true, true);

        //[THEN] Check These  Entries should be there.
        LibraryReportDataset.AssertElementWithValueNotExist('CLEPostingDate', WorkDate());
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Report III");
        Clear(LibraryReportDataset);
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Report III");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibraryERMCountryData.UpdateFAPostingGroup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Report III");
    end;

    local procedure AgedAccountRecFalsePrintAmtLCYAndCurrencyCodeMatchesLCY(FirstBlank: Boolean)
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
        CurrencyCode1: Code[10];
        CurrencyCode2: Code[10];
        PeriodLength: DateFormula;
    begin
        // Setup: Create Currency and update LCY Code in GL Setup.
        Initialize();
        CreateLCYAndUpdateGeneralLedgerSetup(CurrencyCode);

        // Create and Post 2 Sales Orders.
        CustomerNo := CreateCustomer();
        if FirstBlank then begin
            CurrencyCode1 := '';
            CurrencyCode2 := CurrencyCode;
        end else begin
            CurrencyCode1 := CurrencyCode;
            CurrencyCode2 := '';
        end;
        CreateAndPostSalesDocument(SalesLine, CustomerNo, SalesLine."Document Type"::Order, CurrencyCode1, true);
        CreateAndPostSalesDocument(SalesLine, CustomerNo, SalesLine."Document Type"::Order, CurrencyCode2, true);

        // Exercise: Run and save Aged Account Receivable Report with Print Amount LCY = False.
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        Customer.Get(CustomerNo);
        Customer.SetRecFilter();
        SaveAgedAccountsReceivable(Customer, AgingBy::"Due Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // Verify: Verify the Balance in the report.
        Customer.CalcFields(Balance);
        VerifyXMLReport('No_Cust', CustomerNo, 'TotalCLE1Amt', Customer.Balance);
    end;

    local procedure SetupAgedAccountsReceivable(var SalesLine: Record "Sales Line"; var PostedDocNo: Code[20]; var PeriodLength: DateFormula; AgingBy: Integer; HeadingType: Option; PrintAmountLCY: Boolean; PrintDetails: Boolean; CurrencyCode: Code[10]) VATAmount: Decimal
    var
        Customer: Record Customer;
    begin
        // Setup: Create and Post Sales Order and Find Customer Ledger Entry Amount.
        PostedDocNo := CreateAndPostSalesDocument(SalesLine, CreateCustomer(), SalesLine."Document Type"::Order, CurrencyCode, true);
        VATAmount := Round(SalesLine."Line Amount" + (SalesLine."Line Amount" * SalesLine."VAT %" / 100));

        // Exercise: Take Period Length with Random Values.
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        Customer.SetRange("No.", SalesLine."Sell-to Customer No.");
        SaveAgedAccountsReceivable(Customer, AgingBy, HeadingType, PeriodLength, PrintAmountLCY, PrintDetails);
    end;

    local procedure PrepareCustomFCYSalesInvoiceForProForma(var SalesLine: Record "Sales Line"; CurrencyCode: Code[10])
    begin
        CreateFCYSalesInvoiceWithVATSetup(SalesLine, CurrencyCode, 12, 5, 1000.11111);
        Assert.IsTrue(SalesLine.Amount mod 10000 <> 0, '');
        Assert.IsTrue(SalesLine."Amount Including VAT" mod 10000 <> 0, '');
    end;

    local procedure CreateAndPostGenJournalLines(var GenJournalLine: Record "Gen. Journal Line"; InvoiceAmount: Decimal; PaymentAmount: Decimal; AccountNo: Code[20]; ExtDocNoForPmtLine: Code[35]) PmtDiscAmount: Decimal
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, AccountNo, InvoiceAmount);
        PmtDiscAmount := -GenJournalLine.Amount * GenJournalLine."Payment Discount %" / 100;  // Calculate Payment Discount Amount.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, GenJournalLine."Account No.", PaymentAmount + PmtDiscAmount);
        if ExtDocNoForPmtLine <> '' then begin
            GenJournalLine.Validate("External Document No.", ExtDocNoForPmtLine);
            GenJournalLine.Modify(true);
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesShipment(var PostedShipmentNo: Code[20]; CustomerNo: Code[20]) Quantity: Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order, CustomerNo, '');
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        Quantity := SalesLine.Quantity;
        PostedShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateAndPostSalesReturnReceipt(var PostedReceiptNo: Code[20]; CustomerNo: Code[20]) Quantity: Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Return Order", CustomerNo, '');
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        Quantity := SalesLine.Quantity;
        PostedReceiptNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateSalesOrderWithSevItemsForProForma(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Item: array[3] of Record Item;
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerWithDetails());

        SalesHeader.Validate("Your Reference", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);

        for i := 1 to ArrayLen(Item) do begin
            CreateItemWithDetails(Item[i]);
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, Item[i]."No.", LibraryRandom.RandDecInRange(10, 20, 2));
            SalesLine.Validate("Qty. to Invoice", Round(SalesLine.Quantity / 3));
            SalesLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 30));
            SalesLine.Modify(true);
        end;

        // Leave last line with zero quantity (TFS 225721)
        SalesLine.Validate(Quantity, 0);
        SalesLine.Modify(true);
    end;

    local procedure CreateFCYSalesInvoiceWithVATSetup(var SalesLine: Record "Sales Line"; CurrencyCode: Code[10]; VATRate: Decimal; Quantity: Decimal; UnitPrice: Decimal)
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        LibrarySales.CreateFCYSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), Quantity, '', 0D, CurrencyCode);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify();
    end;

    local procedure SetupSalesDocumentTest(var SalesLine: Record "Sales Line"; Ship: Boolean; Invoice: Boolean)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order, Customer."No.", '');
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity);
        SalesLine.Modify(true);

        // Exercise.
        SaveSalesDocumentTest(SalesLine."Document No.", Ship, Invoice, false, false);
    end;

    local procedure CreateGenJnlLineWithBalAccount(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);

        // Create Currency Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
    begin
        // Create Customer with Application Method Apply to Oldest and attach Payment Terms to it.
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithCurrency(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer());
        Customer.Validate("Currency Code", CreateCurrencyAndExchangeRate());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerAndPostGenJnlLines(var Customer: Record Customer; var InvoiceAmount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", InvoiceAmount);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", -(InvoiceAmount * 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10]; Invoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesLine, DocumentType, CustomerNo, CurrencyCode);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, Invoice));
    end;

    [Scope('OnPrem')]
    procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]; Amount: Integer)
    var
        GLAccount: Record "G/L Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Sales);
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateCustomerWithDimension(var DimensionValue: Record "Dimension Value") CustomerNo: Code[20]
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        CustomerNo := CreateCustomer();
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateCustomerWithDetails(): Code[20]
    var
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateCustomerWithAddress(Customer);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Customer."VAT Registration No." := LibraryUtility.GenerateGUID();
        Customer.Validate("Shipment Method Code", CreateShipmentMethod());
        Customer.Validate("Country/Region Code", CreateCountryRegion());
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Validate("Post Code", LibraryUtility.GenerateGUID());
        Customer.Validate(City, LibraryUtility.GenerateGUID());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        // Take Random Values for Quantity and Unit Price.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePostSalesInvoiceWithDueDateCalc(CustomerNo: Code[20]; DueDate: Date): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Due Date", DueDate);
        SalesHeader.Modify();
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        exit(SalesInvoiceHeader."Amount Including VAT");
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
    end;

    local procedure CreateLCYAndUpdateGeneralLedgerSetup(var CurrencyCode: Code[10])
    begin
        CurrencyCode := CreateCurrencyAndExchangeRate();
        UpdateCurrencyExchangeRate(CurrencyCode, 1, 1); // Update Exchange Rate to 1:1 since this is a Local Currency.
        UpdateGeneralLedgerSetupForLCYCode(CurrencyCode);
    end;

    local procedure CreateItemCharge(var ItemCharge: Record "Item Charge"; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        ItemCharge.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        ItemCharge.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        ItemCharge.Modify(true);
    end;

    local procedure CreateAndModifySalesLine(SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; AccountNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, AccountNo, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithCurrFactor(var SalesHeaderNo: Code[20]; var ExpectedResult: Decimal; var VATIdentifier: Code[20]; CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        SalesHeader.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        SalesHeader.Validate("Currency Factor",
          CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount" +
          LibraryRandom.RandDec(100, 2));
        SalesHeader.Modify(true);
        SalesHeaderNo := SalesHeader."No.";
        ExpectedResult := Round(CurrencyExchangeRate."Exchange Rate Amount" / SalesHeader."Currency Factor", 0.000001);
        VATIdentifier := SalesLine."VAT Identifier";
    end;

    local procedure CreateResource(var Resource: Record Resource; VATBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        LibraryResource: Codeunit "Library - Resource";
    begin
        LibraryResource.CreateResource(Resource, VATBusPostingGroup);
        Resource.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Resource.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Resource.Modify(true);
    end;

    local procedure CreateSalesOrderWithDifferentLineType(var SalesHeader: Record "Sales Header"): Decimal
    var
        ItemCharge: Record "Item Charge";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        Resource: Record Resource;
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        // Find VAT Posting setup, G/L Account, Resource and Charge Item.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        CreateGLAccount(GLAccount, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CreateResource(
          Resource, VATPostingSetup."VAT Bus. Posting Group",
          GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CreateItemCharge(ItemCharge, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        // Create Sales Order with Prepayment % with different line type.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        SalesHeader.Modify(true);
        CreateAndModifySalesLine(SalesHeader, SalesLine.Type::Item, Item."No.");
        CreateAndModifySalesLine(SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.");
        CreateAndModifySalesLine(SalesHeader, SalesLine.Type::Resource, Resource."No.");
        CreateAndModifySalesLine(SalesHeader, SalesLine.Type::"Fixed Asset", FindFixedAsset());
        CreateAndModifySalesLine(SalesHeader, SalesLine.Type::"Charge (Item)", ItemCharge."No.");
        exit(VATPostingSetup."VAT %");
    end;

    local procedure CreatePostCreditMemoWithoutShiptoInfo(): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo",
          LibrarySales.CreateCustomerNo(), CreateCurrencyAndExchangeRate());
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        ClearShiptoInfoForSalesHeader(SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCurrencyWithExchRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        CurrencyCode: Code[10];
    begin
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
    end;

    local procedure CreateCurrencyWithDecimalPlaces(AmountRoundingPrecision: Decimal; AmountDecimalPlaces: Text[5]; UnitAmountRoundingPrecision: Decimal; UnitAmountDecimalPlaces: Text[5]): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        Currency."Amount Rounding Precision" := AmountRoundingPrecision;
        Currency."Amount Decimal Places" := AmountDecimalPlaces;
        Currency."Unit-Amount Rounding Precision" := UnitAmountRoundingPrecision;
        Currency."Unit-Amount Decimal Places" := UnitAmountDecimalPlaces;
        Currency.Modify();
        exit(Currency.Code);
    end;

    local procedure CreateAnalysisLine(var AnalysisLine: Record "Analysis Line"; AnalysisLineTemplateName: Code[10]; CustomerNo: Code[20]; IsBold: Boolean; IsItalic: Boolean; IsUnderlined: Boolean)
    begin
        LibraryInventory.CreateAnalysisLine(AnalysisLine, AnalysisLine."Analysis Area"::Sales, AnalysisLineTemplateName);
        AnalysisLine.Validate("Row Ref. No.", LibraryUtility.GenerateGUID());
        AnalysisLine.Validate(Type, AnalysisLine.Type::Customer);
        AnalysisLine.Validate(Range, CustomerNo);
        AnalysisLine.Validate(Bold, IsBold);
        AnalysisLine.Validate(Italic, IsItalic);
        AnalysisLine.Validate(Underline, IsUnderlined);
        AnalysisLine.Modify(true);
    end;

    local procedure CreateItemWithDetails(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Country/Region of Origin Code", CreateCountryRegion());
        Item.Validate("Net Weight", LibraryRandom.RandDecInRange(1000, 2000, 2));
        Item.Validate("Tariff No.", LibraryUtility.CreateCodeRecord(DATABASE::"Tariff Number"));
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        Item.Modify(true);
    end;

    local procedure CreateShipmentMethod(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.Init();
        ShipmentMethod.Code := LibraryUtility.GenerateRandomCode(ShipmentMethod.FieldNo(Code), DATABASE::"Shipment Method");
        ShipmentMethod.Description := LibraryUtility.GenerateGUID();
        ShipmentMethod.Insert(true);
        exit(ShipmentMethod.Code);
    end;

    local procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate(Name, LibraryUtility.GenerateGUID());
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, Quantity, '', 0D);
    end;

    local procedure CreateTrackedItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy"; IncludeInventory: Boolean; ReorderQuantity: Decimal; ItemTrackingCode: Code[10])
    begin
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Include Inventory", IncludeInventory);
        Item.Validate("Reorder Quantity", ReorderQuantity);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLineWithTracking(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingMode: Option " ","Assign Lot No.","Select Entries","Verify Entries";
    begin
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for Page Handler.
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, '');  // Required for test when using Item Tracking.
        CreateItemJournalLine(ItemJournalTemplate, ItemJournalBatch, ItemJournalLine, ItemNo, Quantity);
        ItemJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        ItemJournalLine.Modify(true);
        ItemJournalLine.OpenItemTrackingLines(false);  // Assign Tracking on Page Handler.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
    end;

    local procedure CreateItemJournalLine(ItemJournalTemplate: Record "Item Journal Template"; ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
    end;

    local procedure FindAssignedLotNo(ItemNo: Code[20]): Code[20]
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.FindLast();
        exit(ItemLedgEntry."Lot No.");
    end;

    local procedure ClearShiptoInfoForSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Ship-to Name", '');
        SalesHeader.Validate("Ship-to Address", '');
        SalesHeader.Validate("Ship-to Address 2", '');
        SalesHeader.Validate("Ship-to City", '');
        SalesHeader.Validate("Ship-to Contact", '');
        SalesHeader.Validate("Location Code", '');
        SalesHeader.Validate("Shipment Date", 0D);
        SalesHeader.Validate("Ship-to Post Code", '');
        SalesHeader.Validate("Ship-to Country/Region Code", '');
        SalesHeader.Modify(true);
    end;

    local procedure DocumentEntriesForSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; ShowInLCY: Boolean)
    var
        SalesLine: Record "Sales Line";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedSalesInvoicePage: Page "Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // Setup: Create and Post Sales Order.
        Initialize();
        DocumentNo := CreateAndPostSalesDocument(
            SalesLine, CreateCustomer(), SalesLine."Document Type"::Order, CreateCurrencyAndExchangeRate(), true);
        LibraryVariableStorage.Enqueue(ShowInLCY);  // Enqueue for DocumentEntriesReqPageHandler.
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.FILTER.SetFilter("No.", DocumentNo);

        // Exercise.
        PostedSalesInvoice."&Navigate".Invoke();  // Navigate.

        // Verify: Verify Tables and No of Records as per Navigate and Amount with and without LCY.
        LibraryReportDataset.LoadDataSetFile();
        SalesInvoiceHeader.SetRange("No.", DocumentNo);
        VerifyDocumentEntries(PostedSalesInvoicePage.Caption, SalesInvoiceHeader.Count);
        VerifyLedgerOnDocumentEntries(DocumentNo);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.CalcFields(Amount);
    end;

    local procedure DocumentEntriesForSalesCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; ShowInLCY: Boolean)
    var
        SalesLine: Record "Sales Line";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedSalesCreditMemoPage: Page "Posted Sales Credit Memo";
        DocumentNo: Code[20];
    begin
        // Setup: Create and Post Sales Credit Memo.
        Initialize();
        DocumentNo := CreateAndPostSalesDocument(
            SalesLine, CreateCustomer(), SalesLine."Document Type"::"Credit Memo", CreateCurrencyAndExchangeRate(), true);
        LibraryVariableStorage.Enqueue(ShowInLCY);  // Enqueue for DocumentEntriesReqPageHandler.
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", DocumentNo);

        // Exercise.
        PostedSalesCreditMemo."&Navigate".Invoke();  // Navigate.

        // Verify: Verify Tables and No of Records as per Navigate and Amount with and without LCY.
        LibraryReportDataset.LoadDataSetFile();
        SalesCrMemoHeader.SetRange("No.", DocumentNo);
        VerifyDocumentEntries(PostedSalesCreditMemoPage.Caption, SalesCrMemoHeader.Count);
        VerifyLedgerOnDocumentEntries(DocumentNo);
        SalesCrMemoHeader.FindFirst();
        SalesCrMemoHeader.CalcFields(Amount);
    end;

    local procedure FindFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.FindFirst();
        exit(FixedAsset."No.");
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
    end;

    local procedure GetSalesDocAmounts(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; var Amount: Decimal; var AmountLCY: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        Amount := CustLedgerEntry.Amount;
        AmountLCY := CustLedgerEntry."Amount (LCY)";
    end;

    local procedure ApplyCustLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20])
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Document Type", Format(DocumentType));
        CustomerLedgerEntries.FILTER.SetFilter("Customer No.", CustomerNo);
        CustomerLedgerEntries."Apply Entries".Invoke();
    end;

    local procedure MockApplyUnapplyScenario(CustomerNo: Code[20]; ApplnDate1: Date; UnapplDate: Date; ApplnDate2: Date) Amount: Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        Amount := LibraryRandom.RandDec(100, 2);
        MockCustLedgerEntry(CustLedgerEntry, CustomerNo, Amount, WorkDate());
        MockDtldCustLedgEntry(CustomerNo, CustLedgerEntry."Entry No.", -Amount, true, ApplnDate1);
        MockDtldCustLedgEntry(CustomerNo, CustLedgerEntry."Entry No.", Amount, true, UnapplDate);
        MockDtldCustLedgEntry(CustomerNo, CustLedgerEntry."Entry No.", -Amount, false, ApplnDate2);
        UpdateOpenOnCustLedgerEntry(CustLedgerEntry."Entry No.");
    end;

    local procedure MockCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; EntryAmount: Decimal; PostingDate: Date)
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Posting Date" := PostingDate;
        CustLedgerEntry.Amount := EntryAmount;
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();
        MockInitialDtldCustLedgEntry(CustomerNo, CustLedgerEntry."Entry No.", EntryAmount, PostingDate);
    end;

    local procedure MockInitialDtldCustLedgEntry(CustomerNo: Code[20]; CustLedgEntryNo: Integer; EntryAmount: Decimal; PostingDate: Date)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        MockDtldCLE(
          DetailedCustLedgEntry,
          CustomerNo, CustLedgEntryNo, DetailedCustLedgEntry."Entry Type"::"Initial Entry", EntryAmount, false, PostingDate);
    end;

    local procedure MockDtldCustLedgEntry(CustomerNo: Code[20]; CustLedgEntryNo: Integer; EntryAmount: Decimal; UnappliedEntry: Boolean; PostingDate: Date)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        MockDtldCLE(
          DetailedCustLedgEntry,
          CustomerNo, CustLedgEntryNo, DetailedCustLedgEntry."Entry Type"::Application, EntryAmount, UnappliedEntry, PostingDate);
    end;

    local procedure MockDtldCLE(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustomerNo: Code[20]; CustLedgEntryNo: Integer; EntryType: Enum "Detailed CV Ledger Entry Type"; EntryAmount: Decimal; UnappliedEntry: Boolean; PostingDate: Date)
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Customer No." := CustomerNo;
        DetailedCustLedgEntry."Entry Type" := EntryType;
        DetailedCustLedgEntry."Posting Date" := PostingDate;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntryNo;
        DetailedCustLedgEntry.Amount := EntryAmount;
        DetailedCustLedgEntry.Unapplied := UnappliedEntry;
        DetailedCustLedgEntry.Insert();
    end;

    local procedure SaveAgedAccountsReceivable(var Customer: Record Customer; AgingBy: Option; HeadingType: Option; PeriodLength: DateFormula; AmountLCY: Boolean; PrintDetails: Boolean)
    var
        AgedAccountsReceivable: Report "Aged Accounts Receivable";
    begin
        Clear(AgedAccountsReceivable);
        AgedAccountsReceivable.SetTableView(Customer);
        AgedAccountsReceivable.InitializeRequest(WorkDate(), AgingBy, PeriodLength, AmountLCY, PrintDetails, HeadingType, false);
        AgedAccountsReceivable.Run();
    end;

    local procedure SaveBlanketSalesOrder(No: Code[20]; InternalInfo: Boolean)
    var
        SalesHeader: Record "Sales Header";
        BlanketSalesOrder: Report "Blanket Sales Order";
    begin
        Clear(BlanketSalesOrder);
        SalesHeader.SetRange("No.", No);
        BlanketSalesOrder.SetTableView(SalesHeader);
        BlanketSalesOrder.InitializeRequest(0, InternalInfo, false, false);
        Commit();
        BlanketSalesOrder.Run();
    end;

    local procedure SaveCustomerBalanceToDate(No: Code[20]; AmountInLCY: Boolean; UnappliedEntries: Boolean)
    var
        Customer: Record Customer;
        CustomerBalanceToDate: Report "Customer - Balance to Date";
    begin
        Clear(CustomerBalanceToDate);
        Customer.SetRange("No.", No);
        CustomerBalanceToDate.SetTableView(Customer);
        CustomerBalanceToDate.InitializeRequest(AmountInLCY, false, UnappliedEntries, WorkDate());  // Setting False for New Page Per Customer Option.
        Commit();
        CustomerBalanceToDate.Run();
    end;

    local procedure SaveSalesDocumentTest(No: Code[20]; Ship: Boolean; Invoice: Boolean; ShowDimension: Boolean; ShowItemCharge: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesDocumentTest: Report "Sales Document - Test";
    begin
        Clear(SalesDocumentTest);
        SalesHeader.SetRange("No.", No);
        SalesDocumentTest.SetTableView(SalesHeader);
        SalesDocumentTest.InitializeRequest(Ship, Invoice, ShowDimension, ShowItemCharge);
        Commit();
        SalesDocumentTest.Run();
    end;

    local procedure RunAgedAccountsReceivableWithParameters(Customer: Record Customer; AgedAsOfDate: Date)
    var
        AgedAccountsReceivable: Report "Aged Accounts Receivable";
    begin
        Clear(AgedAccountsReceivable);
        LibraryVariableStorage.Enqueue(AgedAsOfDate);

        Customer.SetRecFilter();
        AgedAccountsReceivable.SetTableView(Customer);
        AgedAccountsReceivable.Run();
    end;

    local procedure RunSalesCreditMemoTestReport(DocNo: Code[20])
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", DocNo);
        SalesCreditMemo.TestReport.Invoke();
    end;

    local procedure RunStandardSalesCreditMemo(CreditMemoDocNo: Code[20]) FileName: Text[1024]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        StandardSalesCreditMemo: Report "Standard Sales - Credit Memo";
    begin
        SalesCrMemoHeader.Get(CreditMemoDocNo);
        SalesCrMemoHeader.SetFilter("No.", '%1', CreditMemoDocNo);
        StandardSalesCreditMemo.SetTableView(SalesCrMemoHeader);
        StandardSalesCreditMemo.InitializeRequest(true, true);
        FileName := LibraryReportDataset.GetFileName();
        StandardSalesCreditMemo.SaveAsPdf(FileName);
    end;

    local procedure RunStatementReport(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.SetRange("No.", CustomerNo);
        Commit();
        REPORT.Run(REPORT::Statement, true, false, Customer);
    end;

    local procedure RunStandardStatementReport(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.SetRange("No.", CustomerNo);
        Commit();
        REPORT.Run(REPORT::"Standard Statement", true, false, Customer);
    end;

    local procedure SaveSalesShipmentReport(No: Code[20]; ShowInternalInformation: Boolean; LogInteraction: Boolean; ShowCorrectionLines: Boolean)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipment: Report "Sales - Shipment";
    begin
        Clear(SalesShipment);
        SalesShipmentHeader.SetRange("No.", No);
        SalesShipment.SetTableView(SalesShipmentHeader);

        // Passing 0 for No. of Copies and TRUE for Show Serial/ Lot No. Appendix option as these options can not be checked.
        SalesShipment.InitializeRequest(0, ShowInternalInformation, LogInteraction, ShowCorrectionLines, true, false);
        Commit();
        SalesShipment.Run();
    end;

    local procedure SaveStandardSalesShipmentReport(No: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        StandardSalesShipment: Report "Standard Sales - Shipment";
    begin
        Clear(StandardSalesShipment);
        SalesShipmentHeader.SetRange("No.", No);
        StandardSalesShipment.SetTableView(SalesShipmentHeader);

        StandardSalesShipment.InitializeRequest(false, false, false, true);
        Commit();
        StandardSalesShipment.Run();
    end;

    local procedure SaveStandardSalesReturnReceiptReport(No: Code[20])
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        StandardSalesReturnRcpt: Report "Standard Sales - Return Rcpt.";
    begin
        Clear(StandardSalesReturnRcpt);
        ReturnReceiptHeader.SetRange("No.", No);
        StandardSalesReturnRcpt.SetTableView(ReturnReceiptHeader);

        StandardSalesReturnRcpt.InitializeRequest(false, false);
        Commit();
        StandardSalesReturnRcpt.Run();
    end;

    local procedure SaveReturnOrderReport(No: Code[20]; ShowInternalInfo: Boolean; LogInteraction: Boolean)
    var
        SalesHeader: Record "Sales Header";
        ReturnOrderConfirmation: Report "Return Order Confirmation";
    begin
        Clear(ReturnOrderConfirmation);
        SalesHeader.SetRange("No.", No);
        ReturnOrderConfirmation.SetTableView(SalesHeader);
        ReturnOrderConfirmation.InitializeRequest(ShowInternalInfo, LogInteraction);
        Commit();
        ReturnOrderConfirmation.Run();
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exist before creating
        // General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure SetupInvoiceDiscount(): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        // Required Random Value for "Discount %" fields and 0 for Minimum Amount.
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CreateCustomer(), '', 0);
        CustInvoiceDisc.Validate("Discount %", 1 + LibraryRandom.RandDec(10, 1)); // Minimum Discount %1 should be 1.
        CustInvoiceDisc.Modify(true);
        exit(CustInvoiceDisc.Code);
    end;

    local procedure SetupSalesAndReceivablesSetup(CreditMemoNos: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Memo Nos.", CreditMemoNos);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetupCalcInvDisc(CalcInvDiscount: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateCurrencyExchangeRate(CurrencyCode: Code[10]; ExchangeRateAmt: Decimal; AdjmtExchRateAmt: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRateAmt);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", AdjmtExchRateAmt);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", ExchangeRateAmt);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", AdjmtExchRateAmt);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetupForLCYCode(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := '';        // to avoid error on updating LCY Code
        GeneralLedgerSetup.Validate("LCY Code", CurrencyCode);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateOpenOnCustLedgerEntry(EntryNo: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Get(EntryNo);
        CustLedgerEntry.CalcFields(Amount);
        CustLedgerEntry.Open := CustLedgerEntry.Amount <> 0;
        CustLedgerEntry.Modify();
    end;

    local procedure UpdateSalesPrepmtAccount(SalesPrepaymentsAccount: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]) OldSalesPrepaymentsAccount: Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        OldSalesPrepaymentsAccount := GeneralPostingSetup."Sales Prepayments Account";
        GeneralPostingSetup.Validate("Sales Prepayments Account", SalesPrepaymentsAccount);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate(Name, LibraryUtility.GenerateGUID());
        CompanyInformation.Validate("Name 2", LibraryUtility.GenerateGUID());
        CompanyInformation.Validate(Address, LibraryUtility.GenerateGUID());
        CompanyInformation.Validate("Address 2", LibraryUtility.GenerateGUID());
        CompanyInformation.Validate("Post Code", LibraryUtility.GenerateGUID());
        CompanyInformation.Validate(City, LibraryUtility.GenerateGUID());
        CompanyInformation.Validate("E-Mail", LibraryUtility.GenerateGUID() + '@' + LibraryUtility.GenerateGUID());
        CompanyInformation.Validate("Home Page", LibraryUtility.GenerateGUID());
        CompanyInformation.Validate("Phone No.", LibraryUtility.GenerateGUID());
        CompanyInformation."Country/Region Code" := ''; // Force to use address format from G/L setup, not from company info country.
        CompanyInformation."VAT Registration No." := LibraryUtility.GenerateGUID();
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateGLSetupDefaultUnitAmountRounding()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Unit-Amount Rounding Precision" := 0.00001;
        GeneralLedgerSetup."Unit-Amount Decimal Places" := '2:5';
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpdateNoSeriesOnItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch.Validate("No. Series", NoSeries);
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateCustomerAndPostGenJnlLinesWithFilters(CustomerNo: Code[20]; GlobalDimension1Code: Code[20]; GlobalDimension2Code: Code[20]; CurrencyCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          CustomerNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Shortcut Dimension 1 Code", GlobalDimension1Code);
        GenJournalLine.Validate("Shortcut Dimension 2 Code", GlobalDimension2Code);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure RunCustomerBalanceToDateWithLimitTotal(CustomerNo: Code[20]; GlobalDimension1Filter: Text; GlobalDimension2Filter: Text; CurrencyFilter: Text)
    var
        Customer: Record Customer;
        CustomerBalanceToDate: Report "Customer - Balance to Date";
    begin
        Clear(CustomerBalanceToDate);
        Customer.SetRange("No.", CustomerNo);
        Customer.SetRange("Global Dimension 1 Filter", GlobalDimension1Filter);
        Customer.SetRange("Global Dimension 2 Filter", GlobalDimension2Filter);
        Customer.SetRange("Currency Filter", CurrencyFilter);
        CustomerBalanceToDate.SetTableView(Customer);
        CustomerBalanceToDate.InitializeRequest(false, false, false, WorkDate());
        Commit();
        CustomerBalanceToDate.Run();
    end;

    local procedure RunCustomerBalanceToDateWithCustomer(CustomerNo: Code[20]; Unapplied: Boolean; ReportDate: Date)
    var
        Customer: Record Customer;
        CustomerBalanceToDate: Report "Customer - Balance to Date";
    begin
        Commit();
        Clear(CustomerBalanceToDate);
        Customer.SetRange("No.", CustomerNo);
        CustomerBalanceToDate.SetTableView(Customer);
        CustomerBalanceToDate.InitializeRequest(false, false, Unapplied, ReportDate);
        CustomerBalanceToDate.Run();
    end;

    local procedure RunStandardSalesProformaInvFromOrderPage(SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        Commit();
        SalesOrder.Trap();
        PAGE.Run(PAGE::"Sales Order", SalesHeader);
        SalesOrder.ProformaInvoice.Invoke();
        SalesOrder.Close();
    end;

    local procedure RunStandardSalesProFormaInv(DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("No.", DocumentNo);
        Commit();
        REPORT.Run(REPORT::"Standard Sales - Pro Forma Inv", true, false, SalesHeader);
    end;

    local procedure PostInvoiceWithDimensions(var GenJournalLine: Record "Gen. Journal Line"; CustNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue[1], GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue[2], GeneralLedgerSetup."Global Dimension 2 Code");
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustNo, GenJournalLine."Bal. Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), LibraryRandom.RandIntInRange(1000, 2000));
        GenJournalLine.Validate("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        GenJournalLine.Validate("Shortcut Dimension 2 Code", DimensionValue[2].Code);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostApplyPaymentWithDimensions(var GenJournalLine: Record "Gen. Journal Line"; CustNo: Code[20]; PostingDate: Date; Amount: Decimal; ShortcutDimension1Code: Code[20]; ShortcutDimension2Code: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustNo, GenJournalLine."Bal. Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Shortcut Dimension 1 Code", ShortcutDimension1Code);
        GenJournalLine.Validate("Shortcut Dimension 2 Code", ShortcutDimension2Code);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        ApplyCustLedgerEntry(GenJournalLine."Document Type", GenJournalLine."Account No.");
    end;

    local procedure PrepareAgedAccReceivableReportForDimRun(var Customer: Record Customer; var PeriodLength: DateFormula; ShortcutDimension1Code: Code[20]; ShortcutDimension2Code: Code[20])
    begin
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        Customer.SetFilter("Global Dimension 1 Filter", ShortcutDimension1Code);
        Customer.SetFilter("Global Dimension 2 Filter", ShortcutDimension2Code);
        Customer.SetRecFilter();
    end;

    local procedure SetReportSelection(ReportSelectionUsage: Enum "Report Selection Usage"; ReportId: Integer)
    var
        CustomReportSelection: Record "Custom Report Selection";
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelectionUsage);
        ReportSelections.DeleteAll();
        CustomReportSelection.SetRange(Usage, ReportSelectionUsage);
        CustomReportSelection.DeleteAll();

        ReportSelections.Init();
        ReportSelections.Usage := ReportSelectionUsage;
        ReportSelections."Report ID" := ReportId;
        if ReportSelections.Insert() then;
    end;

    local procedure FormatDecimal(Value: Decimal; Decimals: Integer): Text
    begin
        exit(
          Format(Value, 0, StrSubstNo('<Sign><Integer Thousand><1000Character,,><Decimals,%1><Comma,.><Filler Character,0>', Decimals + 1)));
    end;

    local procedure FormatDecimalXML(DecimalValue: Decimal): Text
    begin
        exit(Format(DecimalValue, 0, '<Precision,0:2><Standard Format,9>'));
    end;

    local procedure VerifyAgedAccountsRecReport(PostedDocNo: Code[20]; SellToCustNo: Code[20]; Total: Decimal; VATAmount: Decimal; TotalLCY: Decimal; VATAmountLCY: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Cust', SellToCustNo);
        LibraryReportDataset.SetRange('CLEEndDateDocNo', PostedDocNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('CLEEndDate', Total);
        LibraryReportDataset.AssertCurrentRowValueEquals('AgedCLE1TempRemAmt', VATAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('CLEEndDateAmtLCY', TotalLCY);
        LibraryReportDataset.AssertCurrentRowValueEquals('AgedCLE1RemAmtLCY', VATAmountLCY);
    end;

    local procedure VerifyCurrencyAgedAccountsReceivable(CurrencyCode: Code[10]; Amount: Decimal; AmountLCY: Decimal; NodeIndex: Integer)
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//Result/CurrrencyCode', CurrencyCode, NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//Result/TempCurrCode', CurrencyCode, NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//Result/RemAmt_CLEEndDate', FormatDecimalXML(Amount), NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//Result/CLEEndDateAmtLCY', FormatDecimalXML(AmountLCY), NodeIndex);
    end;

    local procedure VerifyTotalLCYAgedAccountsReceivable(TotalLCY: Decimal)
    var
        nodeList: DotNet XmlNodeList;
        TotalLastIndex: Integer;
        TotalLCYText: Text;
        TotalLCYActual: Decimal;
    begin
        LibraryXPathXMLReader.GetNodeList('//Result/GrandTotalCLE1AmtLCY', nodeList);
        TotalLastIndex := nodeList.Count - 1; // index of the last node that contains Total(LCY) value
        TotalLCYText := LibraryXPathXMLReader.GetNodeInnerTextByXPathWithIndex('//Result/GrandTotalCLE1AmtLCY', TotalLastIndex);
        Evaluate(TotalLCYActual, TotalLCYText);
        Assert.AreEqual(TotalLCY, TotalLCYActual, 'Total(LCY) amount is not as expected');
    end;

    local procedure VerifyInternalInformation(DimensionValueRec: Record "Dimension Value"; Separator: Text[3])
    begin
        LibraryReportDataset.AssertElementWithValueExists('DimText',
          StrSubstNo(HeaderDimensionTxt, DimensionValueRec."Dimension Code", Separator, DimensionValueRec.Code));
    end;

    local procedure VerifyInteractionLogEntry(DocumentType: Enum "Interaction Log Entry Document Type"; DocumentNo: Code[20])
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.SetRange("Document Type", DocumentType);
        InteractionLogEntry.SetRange("Document No.", DocumentNo);
        Assert.IsFalse(InteractionLogEntry.IsEmpty, StrSubstNo(RecordErr, InteractionLogEntry.TableCaption()));
    end;

    local procedure VerifyUndoneQuantityInReport(DocumentNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.SetRange(Correction, true);
        SalesShipmentLine.FindLast();
        LibraryReportDataset.SetRange('LineNo_SalesShptLine', SalesShipmentLine."Line No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_SalesShptLine', SalesShipmentLine.Quantity);
    end;

    local procedure VerifyInvoiceDiscountInReport(SalesLine: Record "Sales Line")
    begin
        LibraryReportDataset.SetRange('Sales_Line__Type', Format(SalesLine.Type));
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line__Quantity', SalesLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___Qty__to_Invoice_', SalesLine."Qty. to Invoice");
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___Unit_Price_', SalesLine."Unit Price");
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___Line_Amount_', SalesLine."Line Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___No__', SalesLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___Allow_Invoice_Disc__', SalesLine."Allow Invoice Disc.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___VAT_Identifier_', SalesLine."VAT Identifier");

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('Sales_Line___Line_Discount___', SalesLine."Line Discount %");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___Inv__Discount_Amount_', SalesLine."Inv. Discount Amount");
    end;

    local procedure VerifyCustBalanceToDateWithLCY(CustLedgerEntry: Record "Cust. Ledger Entry"; InvAmountLCY: Decimal; PmtAmountLCY: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryReportDataset.SetRange('PostingDt_CustLedgEntry', Format(WorkDate()));
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Invoice));
        LibraryReportDataset.SetRange('DocType_DtldCustLedgEntry', Format(GenJournalLine."Document Type"::Payment));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('EntryNo_CustLedgEntry', CustLedgerEntry."Entry No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', Format(InvAmountLCY));
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt', Format(PmtAmountLCY));

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('TotalCaption', TotalCapTxt);

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TtlAmtCurrencyTtlBuff2', Round(InvAmountLCY + PmtAmountLCY));
    end;

    local procedure VerifyCustomerBalanceToDate(GenJournalLine: Record "Gen. Journal Line"; InvoiceAmount: Decimal; PmtDiscAmount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        AutoFormat: Codeunit "Auto Format";
    begin
        LibraryReportDataset.SetRange('PostingDt_CustLedgEntry', Format(WorkDate()));
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Payment));
        LibraryReportDataset.SetRange('EntType_DtldCustLedgEnt', Format(DetailedCustLedgEntry."Entry Type"::"Payment Discount"));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('DocNo_CustLedgEntry', GenJournalLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', Format(GenJournalLine.Amount));
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt',
            Format(Round(PmtDiscAmount), 0, AutoFormat.ResolveAutoFormat("Auto Format"::AmountFormat, GenJournalLine."Currency Code")));

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('EntType_DtldCustLedgEnt', Format(DetailedCustLedgEntry."Entry Type"::Application));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt', Format(InvoiceAmount));

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('TotalCaption', TotalCapTxt);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'TtlAmtCurrencyTtlBuff2', Round(InvoiceAmount + PmtDiscAmount + GenJournalLine.Amount))
    end;

    local procedure VerifyCustomerPaymentReceipt(DocumentNo: Code[20]; PmtDiscAmount: Decimal; Amount: Decimal; PaymentAmount: Decimal)
    var
        ReportAmount: Decimal;
    begin
        // Convert Amount in two decimal places using FORMAT to verify it in Report.
        Evaluate(ReportAmount, Format(PmtDiscAmount, 0, '<Precision,2><Standard Format,1>'));
        LibraryReportDataset.SetRange('DocumentNo_CustLedgEntry', DocumentNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ShowAmount', Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('PmtDiscInvCurr', ReportAmount);

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('ExtDocNo_CustLedgEntry', DocumentNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt_CustLedgEntry', PaymentAmount);
    end;

    local procedure VerifyUnappliedEntries(GenJournalLine: Record "Gen. Journal Line"; InvoiceAmount: Decimal; EntryNo: Integer)
    begin
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Invoice));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', Format(InvoiceAmount));

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('EntryNo_CustLedgEntry', EntryNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', Format(GenJournalLine.Amount));

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('DocType_DtldCustLedgEntry', Format(GenJournalLine."Document Type"::Payment));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt', Format(GenJournalLine.Amount));

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('TotalCaption', TotalCapTxt);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TtlAmtCurrencyTtlBuff2', Round(InvoiceAmount + GenJournalLine.Amount));
    end;

    local procedure VerifyVATEntries(VATIdentifierLabel: Text[50]; VATPercLabel: Text[50]; VATBaseLabel: Text[50]; LineAmountLabel: Text[50]; InvDiscBaseAmountLabel: Text[50])
    var
        VATAmountLine: Record "VAT Amount Line";
    begin
        VATAmountLine.SetFilter("VAT %", '>0');
        VATAmountLine.FindFirst();
        LibraryReportDataset.SetRange(VATIdentifierLabel, VATAmountLine."VAT Identifier");
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals(VATPercLabel, VATAmountLine."VAT %");
        LibraryReportDataset.AssertCurrentRowValueEquals(VATBaseLabel, VATAmountLine."VAT Base");
        LibraryReportDataset.AssertCurrentRowValueEquals(LineAmountLabel, VATAmountLine."Line Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals(InvDiscBaseAmountLabel, VATAmountLine."Inv. Disc. Base Amount");
    end;

    local procedure VerifyDocumentEntries(DocEntryTableName: Text[50]; RowValue: Decimal)
    begin
        LibraryReportDataset.SetRange(DocEntryTableNameTxt, DocEntryTableName);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(DocEntryNoofRecordsTxt, RowValue)
    end;

    local procedure VerifySalesDocumentTestSalesLine(SalesLine: Record "Sales Line")
    begin
        // Verify: Verify Report Data.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Sales_Line___No__', SalesLine."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line__Quantity', SalesLine.Quantity);
    end;

    local procedure VerifyItemLedgerWithValueEntry(DocumentNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntries(ItemLedgerEntry.TableCaption(), ItemLedgerEntry.Count);
        VerifyValueEntry(DocumentNo);
    end;

    local procedure VerifyLedgerOnDocumentEntries(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        VATEntry: Record "VAT Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntries(GLEntry.TableCaption(), GLEntry.Count);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntries(CustLedgerEntry.TableCaption(), CustLedgerEntry.Count);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntries(DetailedCustLedgEntry.TableCaption(), DetailedCustLedgEntry.Count);
        VATEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntries(VATEntry.TableCaption(), VATEntry.Count);
        VerifyValueEntry(DocumentNo);
    end;

    local procedure VerifyAmtOnDocumentEntriesReport(PostingDateCaptionElement: Text[50]; PostingDateCaption: Text[50]; AmtCaptionElement: Text[50]; Amount: Decimal)
    begin
        LibraryReportDataset.SetRange(PostingDateCaptionElement, PostingDateCaption);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(AmtCaptionElement, Amount);
    end;

    local procedure VerifySalesDocumentTestReport()
    var
        SalesLine: Record "Sales Line";
    begin
        VerifyWarningOnReportCell(Format(SalesLine.Type::Item));
        VerifyWarningOnReportCell(Format(SalesLine.Type::"G/L Account"));
        VerifyWarningOnReportCell(Format(SalesLine.Type::Resource));
        VerifyWarningOnReportCell(Format(SalesLine.Type::"Fixed Asset"));
        VerifyWarningOnReportCell(Format(SalesLine.Type::"Charge (Item)"));
    end;

    local procedure VerifyWarningOnReportCell(SalesLineType: Text[30])
    var
        SalesLine: Record "Sales Line";
    begin
        LibraryReportDataset.SetRange('Sales_Line__Type', SalesLineType);
        LibraryReportDataset.SetRange('ErrorText_Number__Control97Caption', WarningTxt);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ErrorText_Number__Control97',
          StrSubstNo(PrepaymentPostErr, SalesLine.FieldCaption("Prepmt. Line Amount")));
    end;

    local procedure VerifyDataOnSalesDocumentTestReport(VATAmount: Decimal; VATPercent: Decimal; Amount: Decimal)
    begin
        // Validate Line Amount and VAT Amount in the report.
        LibraryReportDataset.SetRange('VATAmountLine__VAT___', Format(VATPercent));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('VATAmountLine__Line_Amount_', -Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('VATAmountLine__VAT_Amount_', Round(-VATAmount));
    end;

    local procedure VerifyStatementEntriesTotal(TotalAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();

        // filter the Total row
        LibraryReportDataset.SetRange('EntriesExists', EntriesExistTxt);
        LibraryReportDataset.SetRange('Total_Caption', TotalTxt);

        if LibraryReportDataset.GetNextRow() then
            LibraryReportDataset.AssertCurrentRowValueEquals(CustBalanceCustLedgEntryTxt, TotalAmount);
    end;

    local procedure VerifyValueEntry(DocumentNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntries(ValueEntry.TableCaption(), ValueEntry.Count);
    end;

    local procedure VerifyXMLReport(XmlElementCaption: Text; XmlValue: Text; ValidateCaption: Text; ValidateValue: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(XmlElementCaption, XmlValue);
        LibraryReportDataset.GetLastRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(ValidateCaption, ValidateValue);
    end;

    local procedure VerifyCustomerBalanceToDateWithLimitTotal(CustomerNo: Code[20]; GlobalDimension1Code: Code[20]; GlobalDimension2Code: Code[20]; CurrencyCode: Code[10])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryReportDataset.LoadDataSetFile();
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Global Dimension 1 Code", GlobalDimension1Code);
        CustLedgerEntry.SetRange("Global Dimension 2 Code", GlobalDimension2Code);
        CustLedgerEntry.SetRange("Currency Code", CurrencyCode);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount);

        LibraryReportDataset.SetRange('PostingDt_CustLedgEntry', Format(WorkDate()));
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Invoice));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', Format(CustLedgerEntry.Amount));
    end;

    local procedure VerifyCustomerEntriesAndBalanceInCustomerBalanceToDate(GenJournalLine: Record "Gen. Journal Line"; Balance: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Invoice));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', Format(-GenJournalLine.Amount));
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::"Credit Memo"));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', Format(GenJournalLine.Amount));
        LibraryReportDataset.SetRange('CustName', GenJournalLine."Account No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TtlAmtCurrencyTtlBuff', Balance);
    end;

    local procedure VerifyCustomerBalanceToDateTwoEntriesExist(CustomerNo: Code[20]; PmtAmount: Decimal; Amount: Decimal; TotalAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Customer', CustomerNo);
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(PmtAmount));
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(Amount));
        LibraryReportDataset.AssertElementWithValueExists('TtlAmtCurrencyTtlBuff', TotalAmount);
        LibraryReportDataset.AssertElementWithValueNotExist('postDt_DtldCustLedgEntry', Format(WorkDate() + 1));
    end;

    local procedure VerifyCustomerBalanceToDateDoesNotExist(CustomerNo: Code[20]; PmtAmount: Decimal; Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Customer', CustomerNo);
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(PmtAmount));
        LibraryReportDataset.AssertElementWithValueNotExist('OriginalAmt', Format(Amount));
        LibraryReportDataset.AssertElementWithValueExists('TtlAmtCurrencyTtlBuff', PmtAmount);
        LibraryReportDataset.AssertElementWithValueNotExist('postDt_DtldCustLedgEntry', Format(WorkDate() + 1));
    end;

    local procedure VerifyRowFormatInAnalysisReport(AnalysisLine: Record "Analysis Line"; Normal: Boolean; Bold: Boolean; Italic: Boolean; BoldItalic: Boolean; Underlined: Boolean)
    begin
        LibraryReportDataset.SetRange('RowRefNo_AnlysLine', AnalysisLine."Row Ref. No.");
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), RowPrintedMultiplyErr);

        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Body4View_AnlysLine', Normal);
        LibraryReportDataset.AssertCurrentRowValueEquals('Body5View_AnlysLine', Bold);
        LibraryReportDataset.AssertCurrentRowValueEquals('Body6View_AnlysLine', Italic);
        LibraryReportDataset.AssertCurrentRowValueEquals('Body7View_AnlysLine', BoldItalic);
        LibraryReportDataset.AssertCurrentRowValueEquals('Body8View_AnlysLine', Underlined);
    end;

    local procedure VerifyAgedAccountsReceivableNoOfHitsCodeCoverage(CodeLine: Text; NoOfHits: Integer)
    var
        CodeCoverage: Record "Code Coverage";
    begin
        Assert.AreEqual(
          NoOfHits,
          CodeCoverageMgt.GetNoOfHitsCoverageForObject(CodeCoverage."Object Type"::Report, REPORT::"Aged Accounts Receivable", CodeLine),
          StrSubstNo('%1 must be called %2 times when Aged Accounts Receivable is run', CodeLine, NoOfHits));
    end;

    local procedure VerifyProformaInvoiceBaseValues(SalesHeader: Record "Sales Header")
    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        ShipmentMethod: Record "Shipment Method";
        SalesLine: Record "Sales Line";
        FormatDocument: Codeunit "Format Document";
        TotalWeight: Decimal;
        TotalAmount: Decimal;
        TotalVATAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalAmountLbl: Text[50];
        TotalAmountInclVATLbl: Text[50];
        TotalAmounExclVATLbl: Text[50];
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        CompanyInformation.Get();

        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentTitleLbl', 'Pro Forma Invoice');

        // Header - Company Information
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentDate', Format(SalesHeader."Document Date", 0, 4));

        LibraryReportDataset.AssertCurrentRowValueEquals('CompanyEMail', CompanyInformation."E-Mail");
        LibraryReportDataset.AssertCurrentRowValueEquals('CompanyHomePage', CompanyInformation."Home Page");
        LibraryReportDataset.AssertCurrentRowValueEquals('CompanyPhoneNo', CompanyInformation."Phone No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('CompanyVATRegNo', CompanyInformation."VAT Registration No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('CompanyAddress1', CompanyInformation.Name);
        LibraryReportDataset.AssertCurrentRowValueEquals('CompanyAddress2', CompanyInformation."Name 2");
        LibraryReportDataset.AssertCurrentRowValueEquals('CompanyAddress3', CompanyInformation.Address);
        LibraryReportDataset.AssertCurrentRowValueEquals('CompanyAddress4', CompanyInformation."Address 2");
        LibraryReportDataset.AssertCurrentRowValueEquals('CompanyAddress5', CompanyInformation."Post Code" + ' ' + CompanyInformation.City);
        if CountryRegion.Get(CompanyInformation."Country/Region Code") then
            LibraryReportDataset.AssertCurrentRowValueEquals('CompanyAddress6', CountryRegion.Name);

        // Header - Customer Information
        Customer.Get(SalesHeader."Sell-to Customer No.");
        CountryRegion.Get(Customer."Country/Region Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress1', Customer."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress2', Customer.Address);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress3', Customer."Address 2");
        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress4', Customer.City + ', ' + Customer."Post Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress5', CountryRegion.Name);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress6', '');
        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress7', '');
        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress8', '');

        // Header - Document Information
        ShipmentMethod.Get(Customer."Shipment Method Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('YourReference', SalesHeader."Your Reference");
        LibraryReportDataset.AssertCurrentRowValueEquals('ExternalDocumentNo', SalesHeader."External Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo', SalesHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesPersonName', SalesHeader."Salesperson Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('ShipmentMethodDescription', ShipmentMethod.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals('Currency', LibraryERM.GetLCYCode());
        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerVATRegNo', Customer."VAT Registration No.");

        // Labels
        FormatDocument.SetTotalLabels(LibraryERM.GetLCYCode(), TotalAmountLbl, TotalAmountInclVATLbl, TotalAmounExclVATLbl);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmountLbl', TotalAmountLbl);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmountInclVATLbl', TotalAmountInclVATLbl);
        LibraryReportDataset.AssertCurrentRowValueEquals('DeclartionLbl', 'For customs purposes only.');
        LibraryReportDataset.AssertCurrentRowValueEquals('SignatureLbl', 'For and on behalf of the above named company:');
        LibraryReportDataset.AssertCurrentRowValueEquals('SignatureNameLbl', 'Name (in print) Signature');
        // Lines: 1-2 with Quantity, 3 - zero quantity
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        VerifyProformaInvoiceLineValues(SalesLine, TotalWeight, TotalAmount, TotalVATAmount, TotalAmountInclVAT);
        SalesLine.Next();
        VerifyProformaInvoiceLineValues(SalesLine, TotalWeight, TotalAmount, TotalVATAmount, TotalAmountInclVAT);
        SalesLine.Next();
        VerifyProformaInvoiceZeroQtyLineValues(SalesLine);

        // Totals
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalWeight', TotalWeight);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalValue', FormatDecimal(TotalAmount, 2));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalVATAmount', FormatDecimal(TotalVATAmount, 2));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmountInclVAT', FormatDecimal(TotalAmountInclVAT, 2));
    end;

    local procedure VerifyProformaInvoiceLineValues(SalesLine: Record "Sales Line"; var TotalWeight: Decimal; var TotalAmount: Decimal; var TotalVATAmount: Decimal; var TotalAmountInclVAT: Decimal)
    var
        Item: Record Item;
        LineAmount: Decimal;
        VATAmount: Decimal;
    begin
        Item.Get(SalesLine."No.");
        LineAmount := Round(SalesLine.Amount * SalesLine."Qty. to Invoice" / SalesLine.Quantity);
        VATAmount := SalesLine."Amount Including VAT" - SalesLine.Amount;
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemDescription', SalesLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('CountryOfManufacturing', Item."Country/Region of Origin Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('Tariff', Item."Tariff No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity', SalesLine."Qty. to Invoice");
        LibraryReportDataset.AssertCurrentRowValueEquals('Price', FormatDecimal(Round(SalesLine.Amount / SalesLine.Quantity, 0.00001), 5));
        LibraryReportDataset.AssertCurrentRowValueEquals('NetWeight', Item."Net Weight");
        LibraryReportDataset.AssertCurrentRowValueEquals('LineAmount', FormatDecimal(LineAmount, 2));
        LibraryReportDataset.AssertCurrentRowValueEquals('VATPct', SalesLine."VAT %");
        LibraryReportDataset.AssertCurrentRowValueEquals('VATAmount', FormatDecimal(VATAmount, 2));

        TotalWeight += Round(SalesLine."Net Weight" * SalesLine."Qty. to Invoice");
        TotalAmount += LineAmount;
        TotalVATAmount += VATAmount;
        TotalAmountInclVAT += Round(SalesLine."Amount Including VAT" * SalesLine."Qty. to Invoice" / SalesLine.Quantity);

        Assert.IsTrue(LibraryReportDataset.GetNextRow(), Rep1302DatasetErr);
    end;

    local procedure VerifyProformaInvoiceZeroQtyLineValues(SalesLine: Record "Sales Line")
    var
        Item: Record Item;
    begin
        Item.Get(SalesLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemDescription', SalesLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('CountryOfManufacturing', Item."Country/Region of Origin Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('Tariff', Item."Tariff No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity', SalesLine."Qty. to Invoice");
        LibraryReportDataset.AssertCurrentRowValueEquals('Price', FormatDecimal(SalesLine."Unit Price", 2));
        LibraryReportDataset.AssertCurrentRowValueEquals('NetWeight', Item."Net Weight");
        LibraryReportDataset.AssertCurrentRowValueEquals('LineAmount', FormatDecimal(0, 2));
        LibraryReportDataset.AssertCurrentRowValueEquals('VATPct', SalesLine."VAT %");
        LibraryReportDataset.AssertCurrentRowValueEquals('VATAmount', FormatDecimal(0, 2));

        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'wrong rep 1302 Pro Forma Invoice dataset');
    end;

    local procedure VerifySalesShipmentDocFieldsExcel(SalesHeader: array[2] of Record "Sales Header")
    var
        WorksheetCount: Integer;
        Index: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();
        WorksheetCount := LibraryReportValidation.CountWorksheets();

        for Index := 1 to WorksheetCount do begin
            Assert.IsTrue(
              LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(Index, PurchaseOrderNoLbl), ExpectedCellValueErr);
            Assert.IsTrue(
              LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(Index, OurDocumentNoLbl), ExpectedCellValueErr);
            Assert.IsTrue(
              LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(
                Index, SalesHeader[Index]."External Document No."), ExpectedCellValueErr);
            Assert.IsTrue(
              LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(Index, SalesHeader[Index]."No."), ExpectedCellValueErr);
        end;
    end;

    local procedure SaveStandardSalesShipmentReportWithCorrectionLines(No: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        StandardSalesShipment: Report "Standard Sales - Shipment";
    begin
        Clear(StandardSalesShipment);
        SalesShipmentHeader.SetRange("No.", No);
        StandardSalesShipment.SetTableView(SalesShipmentHeader);

        StandardSalesShipment.InitializeRequest(false, false, true, false);
        Commit();
        StandardSalesShipment.Run();
    end;

    local procedure SaveStandardSalesShipmentReportWithOutCorrectionLines(No: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        StandardSalesShipment: Report "Standard Sales - Shipment";
    begin
        Clear(StandardSalesShipment);
        SalesShipmentHeader.SetRange("No.", No);
        StandardSalesShipment.SetTableView(SalesShipmentHeader);

        StandardSalesShipment.InitializeRequest(false, false, false, false);
        Commit();
        StandardSalesShipment.Run();
    end;

    local procedure VerifyUndoneQuantityInStandardSalesShipmentReport(DocumentNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.SetRange(Correction, true);
        SalesShipmentLine.FindLast();
        LibraryReportDataset.SetRange('LineNo_Line', SalesShipmentLine."Line No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_Line', format(SalesShipmentLine.Quantity));
    end;

    local procedure VerifyAppliesCustomerEntriesAndBalanceInCustomerBalanceToDate(GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Invoice));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', Format(-GenJournalLine.Amount));
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Payment));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', Format(GenJournalLine.Amount));
    end;

    local procedure RunCustomerBalanceToDateForAllCustomer(
        Unapplied: Boolean;
        ReportDate: Date)
    var
        CustomerBalanceToDate: Report "Customer - Balance to Date";
    begin
        CustomerBalanceToDate.InitializeRequest(false, false, Unapplied, ReportDate);
        CustomerBalanceToDate.Run();
    end;

    local procedure DetailedCustLedgEntryAmount(CustomerNo: Code[20]; PostingDate: Date): Decimal
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.SetRange("Posting Date", 0D, PostingDate);
        DetailedCustLedgEntry.CalcSums(Amount);
        exit(DetailedCustLedgEntry.Amount)
    end;

    local procedure VerifyCustomerEntriesAmountInCustomerBalanceToDate(
        InvoiceAmount: array[2] of Decimal;
        InvoiceNo: array[2] of Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Invoice));
        LibraryReportDataset.SetRange('DocNo_CustLedgEntry', InvoiceNo[1]);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', Format(InvoiceAmount[1]));
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Invoice));
        LibraryReportDataset.SetRange('DocNo_CustLedgEntry', InvoiceNo[2]);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', Format(InvoiceAmount[2]));
    end;

    local procedure VerifyCustomerEntriesAmountInCustomerBalanceToDateForSpecificCustomer(
        CustomerNo: Code[20];
        InvoiceAmount: array[2] of Decimal;
        InvoiceNo: array[2] of Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Invoice));
        LibraryReportDataset.SetRange('No_Customer', Format(CustomerNo));
        LibraryReportDataset.SetRange('DocNo_CustLedgEntry', InvoiceNo[1]);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', Format(InvoiceAmount[1]));
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Invoice));
        LibraryReportDataset.SetRange('No_Customer', Format(CustomerNo));
        LibraryReportDataset.SetRange('DocNo_CustLedgEntry', InvoiceNo[2]);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', Format(InvoiceAmount[2]));
    end;

    local procedure VerifyTotalOnCustBalanceToDateWithLCY(Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('TotalCaption', TotalCapTxt);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TtlAmtCurrencyTtlBuff2', Round(Amount));
    end;

    local procedure SaveAgedAccReceivable(var Customer: Record Customer; AgingBy: Option; HeadingType: Option; PeriodLength: DateFormula; AmountLCY: Boolean; PrintDetails: Boolean; PostingDate: Date)
    var
        AgedAccountsReceivable: Report "Aged Accounts Receivable";
    begin
        Clear(AgedAccountsReceivable);
        AgedAccountsReceivable.SetTableView(Customer);
        AgedAccountsReceivable.InitializeRequest(PostingDate, AgingBy, PeriodLength, AmountLCY, PrintDetails, HeadingType, false);
        AgedAccountsReceivable.Run();
    end;

    procedure UnapplyCustomerLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; PostingDate: Date)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Customer No.", CustLedgerEntry."Customer No.");
        DetailedCustLedgEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.SetRange(Unapplied, false);
        DetailedCustLedgEntry.FindFirst();
        if PostingDate = 0D then
            PostingDate := DetailedCustLedgEntry."Posting Date";
        SourceCodeSetup.Get();
        CustLedgerEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.");
        GenJournalLine.Validate("Document No.", DetailedCustLedgEntry."Document No.");
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Account No.", DetailedCustLedgEntry."Customer No.");
        GenJournalLine.Validate(Correction, true);
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::" ");
        GenJournalLine.Validate(Description, CustLedgerEntry.Description);
        GenJournalLine.Validate("Posting Group", CustLedgerEntry."Customer Posting Group");
        GenJournalLine.Validate("Source Type", GenJournalLine."Source Type"::Vendor);
        GenJournalLine.Validate("Source No.", DetailedCustLedgEntry."Customer No.");
        GenJournalLine.Validate("Source Code", SourceCodeSetup."Unapplied Sales Entry Appln.");
        GenJournalLine.Validate("Source Currency Code", DetailedCustLedgEntry."Currency Code");
        GenJournalLine.Validate("System-Created Entry", true);
        GenJnlPostLine.UnapplyCustLedgEntry(GenJournalLine, DetailedCustLedgEntry);
    end;

    local procedure UpdateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; AppliestoDocNo: Code[20]; Amount: Decimal)
    begin
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliestoDocNo);
        GenJournalLine.Validate("Document No.", AppliestoDocNo);
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; NoOfLine: Integer; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Counter: Integer;
    begin
        SelectGenJournalBatch(GenJournalBatch);
        for Counter := 1 to NoOfLine do
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
              GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
    end;

    local procedure CreateAndPostSalesInvoiceWithOneLine(CustomerNo: Code[20]; ExtDocNo: Code[20]; Amount: Decimal; DueDate: Date): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateItem(Item, Amount);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("External Document No.", ExtDocNo);

        if DueDate <> 0D then
            SalesHeader.Validate("Due Date", DueDate);
        SalesHeader."Posting Date" := WorkDate();

        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateItem(var Item: Record Item; Amount: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", Amount);
        Item.Validate("Last Direct Cost", Amount);
        Item.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DocumentEntriesReqPageHandler(var DocumentEntries: TestRequestPage "Document Entries")
    var
        CurrecnyInLcy: Variant;
    begin
        LibraryVariableStorage.Dequeue(CurrecnyInLcy);
        DocumentEntries.PrintAmountsInLCY.SetValue(CurrecnyInLcy);  // Boolean Show Amount in LCY
        DocumentEntries.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NavigatePageHandler(var Navigate: TestPage Navigate)
    begin
        Navigate."No. of Records".Value();
        Navigate.Print.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndApplyCustPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        if ApplyCustomerEntries.Editable() then;
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries."Post Application".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationPageHandler(var PostApplication: Page "Post Application"; var Response: Action)
    begin
        // Modal Page Handler.
        if PostApplication.Editable() then;
        Response := ACTION::OK
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAgedAccountsReceivable(var AgedAccountsReceivable: TestRequestPage "Aged Accounts Receivable")
    begin
        if AgedAccountsReceivable.Editable() then;
        AgedAccountsReceivable.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAgedAccountsReceivableFileName(var AgedAccountsReceivable: TestRequestPage "Aged Accounts Receivable")
    var
        FileName: Text;
    begin
        FileName := LibraryReportDataset.GetFileName();
        LibraryVariableStorage.Enqueue(FileName);
        AgedAccountsReceivable.SaveAsXml(LibraryReportDataset.GetParametersFileName(), FileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAgedAccountsReceivableEmptyPeriodLength(var AgedAccountsReceivable: TestRequestPage "Aged Accounts Receivable")
    begin
        if AgedAccountsReceivable.Editable() then;
        AgedAccountsReceivable.PeriodLength.SetValue('');
        AgedAccountsReceivable.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAgedAccountsReceivableDefaultPeriodLength(var AgedAccountsReceivable: TestRequestPage "Aged Accounts Receivable")
    begin
        LibraryVariableStorage.Enqueue(AgedAccountsReceivable.PeriodLength.Value);
        AgedAccountsReceivable.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHBlanketSalesOrder(var BlanketSalesOrder: TestRequestPage "Blanket Sales Order")
    begin
        BlanketSalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCustomerBalanceToDate(var CustomerBalanceToDate: TestRequestPage "Customer - Balance to Date")
    begin
        CustomerBalanceToDate.ShowEntriesWithZeroBalance.SetValue(false);
        CustomerBalanceToDate.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCustomerBalanceToDateEnableShowEntriesWithZeroBalance(var CustomerBalanceToDate: TestRequestPage "Customer - Balance to Date")
    begin
        CustomerBalanceToDate.ShowEntriesWithZeroBalance.SetValue(true);
        CustomerBalanceToDate.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCustomerPaymentReceipt(var CustomerPaymentReceipt: TestRequestPage "Customer - Payment Receipt")
    begin
        CustomerPaymentReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHReturnOrderConfirmation(var ReturnOrderConfirmation: TestRequestPage "Return Order Confirmation")
    begin
        ReturnOrderConfirmation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHSalesDocumentTest(var SalesDocumentTest: TestRequestPage "Sales Document - Test")
    begin
        SalesDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHSalesShipment(var SalesShipment: TestRequestPage "Sales - Shipment")
    begin
        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHStandardSalesShipment(var StandardSalesShipment: TestRequestPage "Standard Sales - Shipment")
    begin
        StandardSalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure RHStandardSalesShipmentSetShowItemTracking(var StandardSalesShipment: TestRequestPage "Standard Sales - Shipment")
    begin
        StandardSalesShipment.ShowLotSNControl.SetValue(true);
        StandardSalesShipment.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHStandardSalesReturnReceipt(var StandardSalesReturnRcpt: TestRequestPage "Standard Sales - Return Rcpt.")
    begin
        StandardSalesReturnRcpt.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementRequestPageHandler(var StatementRequestPage: TestRequestPage Statement)
    begin
        StatementRequestPage."Start Date".SetValue(WorkDate());
        StatementRequestPage."End Date".SetValue(WorkDate());
        StatementRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UndoShipmentConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm handler for Undo Shipment Confirmation Message. Send Reply YES.
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementCancelRequestPageHandler(var StandardStatement: TestRequestPage "Standard Statement")
    begin
        StandardStatement.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardStatementRequestPageHandler(var StandardStatement: TestRequestPage "Standard Statement")
    begin
        StandardStatement."Start Date".SetValue(WorkDate());
        StandardStatement."End Date".SetValue(WorkDate());
        StandardStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardStatementNoLogInteractionRequestPageHandler(var StandardStatement: TestRequestPage "Standard Statement")
    begin
        LibraryVariableStorage.Enqueue(StandardStatement.LogInteraction.Enabled());
        StandardStatement."Start Date".SetValue(WorkDate());
        StandardStatement."End Date".SetValue(WorkDate());
        StandardStatement.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText());
        StandardStatement.LogInteraction.SetValue(LibraryVariableStorage.DequeueBoolean());
        StandardStatement.ReportOutput.SetValue('Preview');
        StandardStatement.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentSaveAsExcelRequestPageHandler(var SalesShipment: TestRequestPage "Sales - Shipment")
    begin
        SalesShipment.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisReportRequestPageHandler(var AnalysisReport: TestRequestPage "Analysis Report")
    begin
        AnalysisReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LotItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ItemTrackingMode: Option " ","Assign Lot No.","Select Entries","Verify Entries","Set Lot No.","Set Quantity & Lot No.","Get Lot Quantity";
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingMode::"Assign Lot No.":
                ItemTrackingLines."Assign Lot No.".Invoke();
            ItemTrackingMode::"Select Entries":
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingMode::"Verify Entries":
                begin
                    ItemTrackingLines."Lot No.".AssertEquals(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".AssertEquals(LibraryVariableStorage.DequeueDecimal());
                end;
            ItemTrackingMode::"Set Lot No.":
                ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
            ItemTrackingMode::"Set Quantity & Lot No.":
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            ItemTrackingMode::"Get Lot Quantity":
                begin
                    ItemTrackingLines.FILTER.SetFilter("Lot No.", LibraryVariableStorage.DequeueText());
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Quantity (Base)".AsDecimal());
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AgedAccountsReceivableReportRequestPageHandler(var AgedAccountsReceivable: TestRequestPage "Aged Accounts Receivable")
    var
        RefAgingBy: Option "Due Date","Posting Date","Document Date";
    begin
        AgedAccountsReceivable.Agingby.SetValue(RefAgingBy::"Due Date");
        AgedAccountsReceivable.AgedAsOf.SetValue(LibraryVariableStorage.DequeueDate());
        AgedAccountsReceivable.PrintDetails.SetValue(true);
        AgedAccountsReceivable.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProFormaInvoiceXML_RPH(var ProFormaInvoice: TestRequestPage "Standard Sales - Pro Forma Inv")
    begin
        ProFormaInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
