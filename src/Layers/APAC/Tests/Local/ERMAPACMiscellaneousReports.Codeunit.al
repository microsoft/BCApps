codeunit 141076 "ERM APAC Miscellaneous Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmtRcdNotInvoicedCap: Label 'Purchase_Line__Amt__Rcd__Not_Invoiced_';
        BuyFromVendorNoFilterTxt: Label '%1|%2';
        NextRowExistMsg: Label 'Next Row exist.';
        PayToVendorNoCap: Label 'Purchase_Header__Pay_to_Vendor_No__';
        QtyRcdNotInvoicedCap: Label 'Purchase_Line__Qty__Rcd__Not_Invoiced_';
        QuantityInvoicedCap: Label 'Purchase_Line__Quantity_Invoiced_';
        QuantityReceivedCap: Label 'Purchase_Line__Quantity_Received_';
        ReceivedQuantityCap: Label 'ReceivedQty';
        ReceivedCostCap: Label 'ReceivedCost';
        TotalBalanceAmountCap: Label 'TotalBalanceAmount';
        LibraryUtility: Codeunit "Library - Utility";
        RoundingFactor: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;

    [Test]
    [HandlerFunctions('ItemsReceivedAndNotInvoicedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MultiplePOItemsReceivedAndNotInvoicedReport()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Purchase] [Order] [Items Received and Not Invoiced]
        // [SCENARIO] values on Items Received and Not Invoiced report after posting multiple Purchase Order as Receive and Invoice.

        // Setup: Create and post two Purchase Orders for different Vendors.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndPostPurchaseOrder(PurchaseLine, true, LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDec(10, 2));  // True for Invoice. Random value used for Quantity and Qty. to Invoice.
        CreateAndPostPurchaseOrder(PurchaseLine2, true, Quantity, Quantity);  // True for Invoice. Random value used for Quantity and Qty. to Invoice.
        EnqueueValuesForItemsRcdAndNotInvdRqstPageHandler(PurchaseLine."Buy-from Vendor No.", PurchaseLine2."Buy-from Vendor No.");

        // Exercise and Verify: Run Items Received and Not Invoiced report and verify Xml values for first Purchase Order and verify No row exist for second Purchase Order.
        RunItemsRcdAndNotInvdRptAndVerifyXmlValues(PurchaseLine);
        LibraryReportDataset.SetRange(PayToVendorNoCap, PurchaseLine2."Buy-from Vendor No.");
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), NextRowExistMsg);
    end;

    [Test]
    [HandlerFunctions('ItemsReceivedAndNotInvoicedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostPOAsInvoiceItemsReceivedAndNotInvoicedReport()
    begin
        // [FEATURE] [Purchase] [Order] [Items Received and Not Invoiced]
        // [SCENARIO] values on Items Received and Not Invoiced report after posting Purchase Order as Receive and Invoice.
        PostPOItemsReceivedAndNotInvoicedReport(true);  // True for Invoice.
    end;

    [Test]
    [HandlerFunctions('ItemsReceivedAndNotInvoicedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostPOAsReceiveItemsReceivedAndNotInvoicedReport()
    begin
        // [FEATURE] [Purchase] [Order] [Items Received and Not Invoiced]
        // [SCENARIO] values on Items Received and Not Invoiced report after posting Purchase Order as Receive.
        PostPOItemsReceivedAndNotInvoicedReport(false);  // False for Invoice.
    end;

    local procedure PostPOItemsReceivedAndNotInvoicedReport(Invoice: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create and post Purchase Order.
        Initialize();
        CreateAndPostPurchaseOrder(
          PurchaseLine, Invoice, LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDec(10, 2));  // Random value for Quantity and Qty. To Invoice.
        EnqueueValuesForItemsRcdAndNotInvdRqstPageHandler(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");

        // Exercise and Verify.
        RunItemsRcdAndNotInvdRptAndVerifyXmlValues(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('StockCardRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderValueOnStockCardReport()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Order] [Stock Card]
        // [SCENARIO] values on Report - Stock Card after posting Purchase Order.

        // Setup: Create and Post Purchase Order.
        Initialize();
        CreateAndPostPurchaseOrder(
          PurchaseLine, true, LibraryRandom.RandDecInRange(50, 100, 2), LibraryRandom.RandDecInRange(10, 50, 2));  // True for Invoice. Random value used for Quantity and Qty. to Invoice.
        LibraryVariableStorage.Enqueue(PurchaseLine."No.");

        // Exercise.
        RunStockCardReport(PurchaseLine."No.");

        // Verify: Verify Received Quantity, Received Cost and Amount On Report - Stock Card.
        VerifyReceivedQuantityCostAndAmountOnStockCardReport(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceReport()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 362109] Print VAT Amount in "Purchase - Invoice" report
        Initialize();
        // [GIVEN] Posted Purchase Invoice with tax amount = "X"
        CreateAndPostPurchaseDocument(DocumentNo, VATAmount, PurchaseHeader."Document Type"::Invoice);
        // [WHEN] Preview "Purchase - Invoice" report
        RunPurchaseInvoiceReport(DocumentNo);
        // [THEN] VAT Amount in report VAT specification = "X"
        VerifyPurchaseDocumentVATAmount(VATAmount);
    end;

    [Test]
    [HandlerFunctions('PurchaseCrMemoReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoReport()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 362109] Print VAT Amount in "Purchase - Credit Memo" report
        Initialize();
        // [GIVEN] Posted Purchase Credit Memo with tax amount = "X"
        CreateAndPostPurchaseDocument(DocumentNo, VATAmount, PurchaseHeader."Document Type"::"Credit Memo");
        // [WHEN] Preview "Purchase - Credit Memo" report
        RunPurchaseCrMemoReport(DocumentNo);
        // [THEN] VAT Amount in report VAT specification = "X"
        VerifyPurchaseDocumentVATAmount(VATAmount);
    end;

    [Test]
    [HandlerFunctions('BankAccountReconciliationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReversedEntriesAreNotShownInBankAccountReconciliation()
    var
        BankAccount: Record "Bank Account";
        ExpectedDocumentNo: array[2] of Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Reverse] [Bank Account Reconciliation]
        // [SCENARIO 231426] Reversed Bank Account Ledger Entries are not shown when report "Bank Account Reconciliation" is printed.
        Initialize();

        ExpectedDocumentNo[1] := LibraryUtility.GenerateGUID();
        ExpectedDocumentNo[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Bank Account "B"
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.SetRecFilter();

        // [GIVEN] Bank Account Ledger Entry for Payment "P1"
        MockBankAccountLedgerEntry(ExpectedDocumentNo[1], BankAccount."No.", false, -LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [GIVEN] Bank Account Ledger Entry for Payment "P2"
        // [GIVEN] Reversed Bank Account Ledger Entry for Payment "P2"
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        MockBankAccountLedgerEntry(ExpectedDocumentNo[2], BankAccount."No.", true, -Amount);
        MockBankAccountLedgerEntry(ExpectedDocumentNo[2], BankAccount."No.", true, Amount);

        Commit();

        // [WHEN] Run report "Bank Account Reconciliation" for "B".
        REPORT.RunModal(REPORT::"Bank Account Reconciliation", true, false, BankAccount);

        // [THEN] Payment "X" exists in export XML.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('Bank_Account_Ledger_Entry1__Document_No__', ExpectedDocumentNo[1]);

        // [THEN] Payment "Y" doesn't exist in export XML.
        LibraryReportDataset.AssertElementTagWithValueNotExist('Bank_Account_Ledger_Entry1__Document_No__', ExpectedDocumentNo[2]);
        LibraryReportDataset.AssertElementTagWithValueNotExist('Bank_Account_Ledger_Entry2__Document_No__', ExpectedDocumentNo[2]);
    end;

    [Test]
    [HandlerFunctions('ItemsReceivedAndNotInvoicedRequestPageHandlerSimple')]
    [Scope('OnPrem')]
    procedure ItemsReceivedAndNotInvoicedFromVendorCard()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Purchase] [Order] [Items Received and Not Invoiced] [UI]
        // [SCENARIO 374783] Items Received and Not Invoiced can be run from Vendor Card action without error
        Initialize();

        // [GIVEN] Purchase order posted for Vendor
        CreateAndPostPurchaseOrder(PurchaseLine, true, LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Vendor Card page was open
        Vendor.Get(PurchaseLine."Buy-from Vendor No.");
        VendorCard.OpenView();
        VendorCard.Filter.SetFilter("No.", Vendor."No.");

        Commit();

        // [WHEN] Invoke "Items Received and Not Invoiced" action
        VendorCard."Items Received".Invoke();

        LibraryReportDataset.LoadDataSetFile();

        // [THEN] No error. Report "Items Received and Not Invoiced" is run for this Vendor
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        VerifyValuesOnItemsReceivedAndNotInvoicedReport(
          PurchaseLine."Quantity Invoiced", PurchaseLine."Quantity Received", PurchaseLine."Qty. Rcd. Not Invoiced",
          Round(PurchaseLine.Amount * PurchaseLine."Qty. Rcd. Not Invoiced" / PurchaseLine.Quantity, LibraryERM.GetAmountRoundingPrecision()));

        // Cleanup
        VendorCard.Close();
    end;

    [Test]
    [HandlerFunctions('IncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TheAllDecimalsPrintInIncomeStatementReportWhenRoundingFactorIsEmpty()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        ReportManagementAPAC: Codeunit "Report Management APAC";
        ExpectedDebitAmount: Decimal;
    begin
        // [SCENARIO 374871] Run report 28025 "Income Statement" with Rounding Factor = " ". The all decimals is printed.
        Initialize();

        // [GIVEN] Rounding Factor set to " ", Decimal precision = 2.
        RoundingFactor := RoundingFactor::" ";
        LibraryVariableStorage.Enqueue(RoundingFactor);

        // [GIVEN] Created G/L Account with entries
        LibraryERM.CreateGLAccount(GLAccount);
        ExpectedDebitAmount := ReportManagementAPAC.RoundAmount(PrepareTempDebitCreditGLEntries(
              GLAccount, GLEntry, 1000000 * LibraryRandom.RandIntInRange(3, 9), 1000000 * LibraryRandom.RandIntInRange(1, 2)), RoundingFactor);
        Commit();

        // [WHEN] Run report 28025 "Income Statement" for created G/L Account.
        GLAccount.SetRecFilter();
        GLAccount.SetRange("Date Filter", WorkDate());
        REPORT.Run(REPORT::"Income Statement", true, false, GLAccount);

        // [THEN] The report is run with correct rounding factor.
        // [THEN] The Precision for decimal places is equal to 2.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('RoundFactorText', ReportManagementAPAC.RoundDescription(RoundingFactor));
        LibraryReportDataset.AssertElementWithValueExists('Precision', 2);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('IncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TheAllDecimalsPrintInIncomeStatementReportWhenRoundingFactorIsTens()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        ReportManagementAPAC: Codeunit "Report Management APAC";
        ExpectedDebitAmount: Decimal;
    begin
        // [SCENARIO 374871] Run report 28025 "Income Statement" with Rounding Factor = "Tens". The all decimals is printed.
        Initialize();

        // [GIVEN] Rounding Factor set to "Tens" Decimal precision = 1.
        RoundingFactor := RoundingFactor::Tens;
        LibraryVariableStorage.Enqueue(RoundingFactor);

        // [GIVEN] Created G/L Account with entries
        LibraryERM.CreateGLAccount(GLAccount);
        ExpectedDebitAmount := ReportManagementAPAC.RoundAmount(PrepareTempDebitCreditGLEntries(
              GLAccount, GLEntry, 1000000 * LibraryRandom.RandIntInRange(3, 9), 1000000 * LibraryRandom.RandIntInRange(1, 2)), RoundingFactor);
        Commit();

        // [WHEN] Run report 28025 "Income Statement" for created G/L Account.
        GLAccount.SetRecFilter();
        GLAccount.SetRange("Date Filter", WorkDate());
        REPORT.Run(REPORT::"Income Statement", true, false, GLAccount);

        // [THEN] The report is run with correct rounding factor.
        // [THEN] The Precision for decimal places is equal to 1.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('RoundFactorText', ReportManagementAPAC.RoundDescription(RoundingFactor));
        LibraryReportDataset.AssertElementWithValueExists('Precision', 1);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('IncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TheAllDecimalsPrintInIncomeStatementReportWhenRoundingFactorIsHundreds()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        ReportManagementAPAC: Codeunit "Report Management APAC";
        ExpectedDebitAmount: Decimal;
    begin
        // [SCENARIO 374871] Run report 28025 "Income Statement" with Rounding Factor = "Hundreds". The all decimals is printed.
        Initialize();

        // [GIVEN] Rounding Factor set to "Hundreds" Decimal precision = 1.
        RoundingFactor := RoundingFactor::Hundreds;
        LibraryVariableStorage.Enqueue(RoundingFactor);

        // [GIVEN] Created G/L Account with entries
        LibraryERM.CreateGLAccount(GLAccount);
        ExpectedDebitAmount := ReportManagementAPAC.RoundAmount(PrepareTempDebitCreditGLEntries(
              GLAccount, GLEntry, 1000000 * LibraryRandom.RandIntInRange(3, 9), 1000000 * LibraryRandom.RandIntInRange(1, 2)), RoundingFactor);
        Commit();

        // [WHEN] Run report 28025 "Income Statement" for created G/L Account.
        GLAccount.SetRecFilter();
        GLAccount.SetRange("Date Filter", WorkDate());
        REPORT.Run(REPORT::"Income Statement", true, false, GLAccount);

        // [THEN] The report is run with correct rounding factor.
        // [THEN] The Precision for decimal places is equal to 1.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('RoundFactorText', ReportManagementAPAC.RoundDescription(RoundingFactor));
        LibraryReportDataset.AssertElementWithValueExists('Precision', 1);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('IncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TheAllDecimalsPrintInIncomeStatementReportWhenRoundingFactorIsThousands()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        ReportManagementAPAC: Codeunit "Report Management APAC";
        ExpectedDebitAmount: Decimal;
    begin
        // [SCENARIO 374871] Run report 28025 "Income Statement" with Rounding Factor = "Thousands". The all decimals is printed.
        Initialize();

        // [GIVEN] Rounding Factor set to "Thousands" Decimal precision = 0.
        RoundingFactor := RoundingFactor::Thousands;
        LibraryVariableStorage.Enqueue(RoundingFactor);

        // [GIVEN] Created G/L Account with entries
        LibraryERM.CreateGLAccount(GLAccount);
        ExpectedDebitAmount := ReportManagementAPAC.RoundAmount(PrepareTempDebitCreditGLEntries(
              GLAccount, GLEntry, 1000000 * LibraryRandom.RandIntInRange(3, 9), 1000000 * LibraryRandom.RandIntInRange(1, 2)), RoundingFactor);
        Commit();

        // [WHEN] Run report 28025 "Income Statement" for created G/L Account.
        GLAccount.SetRecFilter();
        GLAccount.SetRange("Date Filter", WorkDate());
        REPORT.Run(REPORT::"Income Statement", true, false, GLAccount);

        // [THEN] The report is run with correct rounding factor.
        // [THEN] The Precision for decimal places is equal to 0.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('RoundFactorText', ReportManagementAPAC.RoundDescription(RoundingFactor));
        LibraryReportDataset.AssertElementWithValueExists('Precision', 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('IncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TheAllDecimalsPrintInIncomeStatementReportWhenRoundingFactorIsHundredThousands()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        ReportManagementAPAC: Codeunit "Report Management APAC";
        ExpectedDebitAmount: Decimal;
    begin
        // [SCENARIO 374871] Run report 28025 "Income Statement" with Rounding Factor = "Hundred Thousands". The all decimals is printed.
        Initialize();

        // [GIVEN] Rounding Factor set to "Hundred Thousands" Decimal precision = 1.
        RoundingFactor := RoundingFactor::"Hundred Thousands";
        LibraryVariableStorage.Enqueue(RoundingFactor);

        // [GIVEN] Created G/L Account with entries
        LibraryERM.CreateGLAccount(GLAccount);
        ExpectedDebitAmount := ReportManagementAPAC.RoundAmount(PrepareTempDebitCreditGLEntries(
              GLAccount, GLEntry, 1000000 * LibraryRandom.RandIntInRange(3, 9), 1000000 * LibraryRandom.RandIntInRange(1, 2)), RoundingFactor);
        Commit();

        // [WHEN] Run report 28025 "Income Statement" for created G/L Account.
        GLAccount.SetRecFilter();
        GLAccount.SetRange("Date Filter", WorkDate());
        REPORT.Run(REPORT::"Income Statement", true, false, GLAccount);

        // [THEN] The report is run with correct rounding factor.
        // [THEN] The Precision for decimal places is equal to 1.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('RoundFactorText', ReportManagementAPAC.RoundDescription(RoundingFactor));
        LibraryReportDataset.AssertElementWithValueExists('Precision', 1);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('IncomeStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TheAllDecimalsPrintInIncomeStatementReportWhenRoundingFactorIsMillions()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        ReportManagementAPAC: Codeunit "Report Management APAC";
        ExpectedDebitAmount: Decimal;
    begin
        // [SCENARIO 374871] Run report 28025 "Income Statement" with Rounding Factor = "Millions". The all decimals is printed.
        Initialize();

        // [GIVEN] Rounding Factor set to "Millions". Decimal precision = 1.
        RoundingFactor := RoundingFactor::Millions;
        LibraryVariableStorage.Enqueue(RoundingFactor);

        // [GIVEN] Created G/L Account with entries
        LibraryERM.CreateGLAccount(GLAccount);
        ExpectedDebitAmount := ReportManagementAPAC.RoundAmount(PrepareTempDebitCreditGLEntries(
              GLAccount, GLEntry, 1000000 * LibraryRandom.RandIntInRange(3, 9), 1000000 * LibraryRandom.RandIntInRange(1, 2)), RoundingFactor);
        Commit();

        // [WHEN] Run report 28025 "Income Statement" for created G/L Account.
        GLAccount.SetRecFilter();
        GLAccount.SetRange("Date Filter", WorkDate());
        REPORT.Run(REPORT::"Income Statement", true, false, GLAccount);

        // [THEN] The report is run with correct rounding factor.
        // [THEN] The Precision for decimal places is equal to 1.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('RoundFactorText', ReportManagementAPAC.RoundDescription(RoundingFactor));
        LibraryReportDataset.AssertElementWithValueExists('Precision', 1);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemsReceivedNotInvoicedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemsReceivedNotInvoicedReportPrintsAmountWithoutVAT()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 380733] Run report "Items Received & Not Invoiced" for received and not invoiced "Purchase Order"
        Initialize();

        // [GIVEN] Created Purchase Order and post Recieve without Invoice
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchaseHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] Run report "Items Received & Not Invoiced" for created Purchase Order
        PurchaseHeader.SetRecFilter();
        REPORT.Run(REPORT::"Items Received & Not Invoiced", true, false, PurchaseHeader);

        // [THEN] The "Amount Rcd. not Invoiced" is printed without VAT.
        // [THEN] Amount is not equal to "Amount Incl. VAT"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Purchase_Line__Amt__Rcd__Not_Invoiced_', PurchaseHeader.Amount);
        LibraryReportDataset.AssertElementWithValueExists('Purchase_Line__Amt__Rcd__Not_Invoiced__Control33', PurchaseHeader.Amount);
        Assert.AreNotEqual(PurchaseHeader.Amount, PurchaseHeader."Amount Including VAT", '');
    end;

    [Test]
    [HandlerFunctions('ItemsReceivedNotInvoicedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemsReceivedNotInvoicedReportPrintsAmountWithoutVATWhenCurrencyIsChosenForPurchaseHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 380733] Run report "Items Received & Not Invoiced" for received and not invoiced "Purchase Order" with currency rounding
        Initialize();

        // [GIVEN] Created Purchase Order with currency rounding and post Recieve without Invoice
        LibraryPurchase.CreateFCYPurchaseDocumentWithItem(
            PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(),
            LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate(), LibraryERM.CreateCurrencyWithRounding());
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(50, 100, 3));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchaseHeader.CalcFields(Amount, "Amount Including VAT");

        // [WHEN] Run report "Items Received & Not Invoiced" for created Purchase Order
        PurchaseHeader.SetRecFilter();
        REPORT.Run(REPORT::"Items Received & Not Invoiced", true, false, PurchaseHeader);

        // [THEN] The "Amount Rcd. not Invoiced" is printed without VAT.
        // [THEN] Amount is not equal to "Amount Incl. VAT"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Purchase_Line__Amt__Rcd__Not_Invoiced_', PurchaseHeader.Amount);
        LibraryReportDataset.AssertElementWithValueExists('Purchase_Line__Amt__Rcd__Not_Invoiced__Control33', PurchaseHeader.Amount);
        Assert.AreNotEqual(PurchaseHeader.Amount, PurchaseHeader."Amount Including VAT", '');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure MockBankAccountLedgerEntry(DocumentNo: Code[20]; BankAccountNo: Code[20]; Reversed: Boolean; Amount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(BankAccountLedgerEntry, BankAccountLedgerEntry.FieldNo("Entry No."));
        BankAccountLedgerEntry."Bank Account No." := BankAccountNo;
        BankAccountLedgerEntry."Document No." := DocumentNo;
        BankAccountLedgerEntry.Reversed := Reversed;
        BankAccountLedgerEntry.Open := true;
        BankAccountLedgerEntry.Amount := Amount;
        BankAccountLedgerEntry.Insert();
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; Invoice: Boolean; Quantity: Decimal; QtyToInvoice: Decimal)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);  // True for Receive.
    end;

    local procedure CreateAndPostPurchaseDocument(var DocumentNo: Code[20]; var VATAmount: Decimal; DocType: Enum "Purchase Document Type")
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, Vendor."No.");
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then begin
            PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
            PurchaseHeader.Modify(true);
        end;
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));
        PurchaseLine.Modify(true);
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure EnqueueValuesForItemsRcdAndNotInvdRqstPageHandler(BuyFromVendorNo: Code[20]; BuyFromVendorNo2: Code[20])
    begin
        // Enqueue values for ItemsReceivedAndNotInvoicedRequestPageHandler.
        LibraryVariableStorage.Enqueue(BuyFromVendorNo);
        LibraryVariableStorage.Enqueue(BuyFromVendorNo2);
    end;

    local procedure RunItemsRcdAndNotInvdRptAndVerifyXmlValues(var PurchaseLine: Record "Purchase Line")
    begin
        // Exercise.
        REPORT.Run(REPORT::"Items Received & Not Invoiced");  // Opens ItemsReceivedAndNotInvoicedRequestPageHandler.

        // Verify: Values on Items Received and not Invoiced Report.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        LibraryReportDataset.LoadDataSetFile();
        VerifyValuesOnItemsReceivedAndNotInvoicedReport(
          PurchaseLine."Quantity Invoiced", PurchaseLine."Quantity Received", PurchaseLine."Qty. Rcd. Not Invoiced",
          Round(PurchaseLine.Amount * PurchaseLine."Qty. Rcd. Not Invoiced" / PurchaseLine.Quantity, LibraryERM.GetAmountRoundingPrecision()));
    end;

    local procedure RunStockCardReport(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        StockCard: Report "Stock Card";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        StockCard.SetTableView(ItemLedgerEntry);
        StockCard.Run();  // Opens StockCardRequestPageHandler.
    end;

    local procedure RunPurchaseInvoiceReport(DocumentNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: Report "Purchase - Invoice";
    begin
        PurchInvHeader.SetRange("No.", DocumentNo);
        PurchaseInvoice.SetTableView(PurchInvHeader);
        PurchaseInvoice.InitializeRequest(0, false, false);
        PurchaseInvoice.Run();
    end;

    local procedure RunPurchaseCrMemoReport(DocumentNo: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseCreditMemo: Report "Purchase - Credit Memo";
    begin
        PurchCrMemoHdr.SetRange("No.", DocumentNo);
        PurchaseCreditMemo.SetTableView(PurchCrMemoHdr);
        PurchaseCreditMemo.InitializeRequest(0, false, false);
        PurchaseCreditMemo.Run();
    end;

    local procedure VerifyReceivedQuantityCostAndAmountOnStockCardReport(PurchaseLine: Record "Purchase Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          ReceivedQuantityCap, Round(PurchaseLine."Qty. to Invoice", LibraryERM.GetAmountRoundingPrecision()));
        LibraryReportDataset.AssertElementWithValueExists(ReceivedCostCap, PurchaseLine."Direct Unit Cost");
        LibraryReportDataset.AssertElementWithValueExists(
          TotalBalanceAmountCap, PurchaseLine."Qty. to Invoice" * PurchaseLine."Direct Unit Cost");
    end;

    local procedure VerifyValuesOnItemsReceivedAndNotInvoicedReport(QuantityInvoiced: Decimal; QuantityReceived: Decimal; QtyRcdNotInvoiced: Decimal; AmtRcdNotInvoiced: Decimal)
    begin
        LibraryReportDataset.AssertElementWithValueExists(QuantityInvoicedCap, QuantityInvoiced);
        LibraryReportDataset.AssertElementWithValueExists(QuantityReceivedCap, QuantityReceived);
        LibraryReportDataset.AssertElementWithValueExists(QtyRcdNotInvoicedCap, QtyRcdNotInvoiced);
        LibraryReportDataset.AssertElementWithValueExists(AmtRcdNotInvoicedCap, AmtRcdNotInvoiced);
    end;

    local procedure VerifyPurchaseDocumentVATAmount(VATAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATAmountLineVATAmount', VATAmount);
    end;

    local procedure PrepareTempDebitCreditGLEntries(var GLAccount: Record "G/L Account"; var GLEntry: Record "G/L Entry"; DebitAmount: Decimal; CreditAmount: Decimal): Decimal
    begin
        MockGLEntry(GLEntry, GLAccount."No.", DebitAmount, 0);
        MockGLEntry(GLEntry, GLAccount."No.", 0, CreditAmount);
        exit(DebitAmount - CreditAmount);
    end;

    local procedure MockGLEntry(var GLEntry: Record "G/L Entry"; GLAccNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal)
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry."G/L Account No." := GLAccNo;
        GLEntry."Posting Date" := WorkDate();
        GLEntry.Amount := DebitAmount - CreditAmount;
        GLEntry."Debit Amount" := DebitAmount;
        GLEntry."Credit Amount" := CreditAmount;
        GLEntry.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemsReceivedAndNotInvoicedRequestPageHandler(var ItemsReceivedAndNotInvoiced: TestRequestPage "Items Received & Not Invoiced")
    var
        BuyFromVendorNo: Variant;
        BuyFromVendorNo2: Variant;
    begin
        LibraryVariableStorage.Dequeue(BuyFromVendorNo);
        LibraryVariableStorage.Dequeue(BuyFromVendorNo2);
        ItemsReceivedAndNotInvoiced."Purchase Header".SetFilter(
          "Buy-from Vendor No.", StrSubstNo(BuyFromVendorNoFilterTxt, BuyFromVendorNo, BuyFromVendorNo2));
        ItemsReceivedAndNotInvoiced.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemsReceivedAndNotInvoicedRequestPageHandlerSimple(var ItemsReceivedAndNotInvoiced: TestRequestPage "Items Received & Not Invoiced")
    begin
        ItemsReceivedAndNotInvoiced.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StockCardRequestPageHandler(var StockCard: TestRequestPage "Stock Card")
    var
        ItemNo: Variant;
        GroupTotals: Option Location;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        StockCard.GroupTotals.SetValue(GroupTotals::Location);
        StockCard."Item Ledger Entry".SetFilter("Item No.", ItemNo);
        StockCard."Item Ledger Entry".SetFilter("Posting Date", Format(WorkDate()));
        StockCard.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceReportHandler(var PurchaseInvoice: TestRequestPage "Purchase - Invoice")
    begin
        PurchaseInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoReportHandler(var PurchaseCrMemo: TestRequestPage "Purchase - Credit Memo")
    begin
        PurchaseCrMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountReconciliationRequestPageHandler(var BankAccountReconciliation: TestRequestPage "Bank Account Reconciliation")
    begin
        BankAccountReconciliation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IncomeStatementRequestPageHandler(var IncomeStatement: TestRequestPage "Income Statement")
    begin
        IncomeStatement.AmountsInWhole.SetValue(LibraryVariableStorage.DequeueInteger());
        IncomeStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemsReceivedNotInvoicedRequestPageHandler(var ItemsReceivedNotInvoiced: TestRequestPage "Items Received & Not Invoiced")
    begin
        ItemsReceivedNotInvoiced.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
