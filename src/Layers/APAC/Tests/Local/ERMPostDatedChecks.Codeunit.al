codeunit 141031 "ERM Post Dated Checks"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Post Dated Check]
    end;

    var
        Assert: Codeunit Assert;
        LibraryAPACLocalization: Codeunit "Library - APAC Localization";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        InstallmentErr: Label 'No. of Installment and Interest Rate does not match with actual values.';
        PDCLineNotFourndErr: Label 'Post Dated Check line is not exist.';
        PostDatedCheckLineAccountNoCap: Label 'Post_Dated_Check_Line_2_Account_No_';
        PostDatedCheckLineAmountCap: Label 'Post_Dated_Check_Line_2_Amount';
        PostDatedCheckLineAppliesToDocNoCap: Label 'Post_Dated_Check_Line_2__Applies_to_Doc__No__';
        PostDatedCheckLineCheckNoCap: Label 'Post_Dated_Check_Line_2__Check_No__';
        UnexpectedErr: Label 'Unexpected Error';
        VoidType: Option "Unapply and void check","Void check only";
        ValueIncorrectErr: Label '%1 value is incorrect';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestPDCCheckToBankForCustomer()
    var
        Customer: Record Customer;
        PostDatedCheckLine: Record "Post Dated Check Line";
        BalanceAmount: Decimal;
        PDCAmount: Decimal;
    begin
        // [SCENARIO] Post Dated Check and Balance Amount on Customer after Suggest Checks to Bank from Post Dated Check Lines.

        // [GIVEN] Create Customer, Post Sales order and create Post Dated Check Lines.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        BalanceAmount := CreateAndPostSalesOrder(Customer."No.");
        PDCAmount :=
          CreatePDCLine(Customer."No.", PostDatedCheckLine."Account Type"::Customer, -LibraryRandom.RandDec(100, 2), '');  // Using blank for Bank Account, Random for Check Amount.

        // Exercise.
        SuggestChecksToBank(Customer."No.");

        // [THEN] Verify Post Dated Check and Balance Amount on Customer.
        Customer.CalcFields("Balance (LCY)", "Post Dated Checks (LCY)");
        Customer.TestField("Balance (LCY)", BalanceAmount);
        Customer.TestField("Post Dated Checks (LCY)", PDCAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CashReceiptJournalFromPDCJournal()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        PDCAmount: Decimal;
    begin
        // [SCENARIO] Cash Receipt Journal after create cash Journal from Post Dated Check Lines.

        // [GIVEN] Create Customer, Post Sales order, create Post Dated Check Lines and Suggest Checks to Bank.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostSalesOrder(Customer."No.");
        PDCAmount := CreatePDCLineWithCustApplication(Customer."No.", 0, -LibraryRandom.RandDec(100, 2));  // Using 0 for Dimension Set ID, Random for Check Amount.
        SuggestChecksToBank(Customer."No.");

        // Exercise.
        CreateCashReceiptJournal(Customer."No.");

        // [THEN] Verify Post Dated Check lines on Cash Receipt Journal.
        FindCustLedgerEntry(CustLedgerEntry, Customer."No.");
        FindGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.");
        GenJournalLine.TestField(Amount, PDCAmount);
        GenJournalLine.TestField("Applies-to Doc. No.", CustLedgerEntry."Document No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure PostDatedCheckWithOverdueBalance()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [SCENARIO] Post Dated Check Lines with Credit Limit on Customer and Credit Warning as Overdue Balance on Sales & Receivable Setup.
        PostDatedCheckWithInclPDCCreditLimit(SalesReceivablesSetup."Credit Warnings"::"Overdue Balance");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostDatedCheckWithCreditWarning()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO] Post Dated Check Lines with Credit Limit on Customer and Credit Warning as Credit Limit on Sales & Receivable Setup.
        PostDatedCheckWithInclPDCCreditLimit(SalesReceivablesSetup."Credit Warnings"::"Credit Limit");
    end;

    local procedure PostDatedCheckWithInclPDCCreditLimit(CreditWarnings: Option)
    var
        Customer: Record Customer;
        PostDatedCheckLine: Record "Post Dated Check Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesOrder: TestPage "Sales Order";
    begin
        // [GIVEN] Create Customer with Credit Limit, Post Sales order, create Post Dated Check Lines and Suggest Checks to Bank.
        Initialize();
        SalesReceivablesSetup.Get();
        UpdateSalesReceivableSetup(true, CreditWarnings);  // True for Incl. PDC in Cr. Limit Check.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Credit Limit (LCY)", LibraryRandom.RandIntInRange(1000, 1500));  // Using Random in range with large value.
        Customer.Modify(true);
        CreateAndPostSalesOrder(Customer."No.");
        CreatePDCLine(Customer."No.", PostDatedCheckLine."Account Type"::Customer, -LibraryRandom.RandDecInRange(1000, 1200, 2), '');  // Using blank for Bank Account, required Random in Range to check credit limit.
        SuggestChecksToBank(Customer."No.");
        SalesOrder.OpenNew();

        // Exercise;
        SalesOrder."Sell-to Customer Name".SetValue(Customer.Name);

        // [THEN] Verify Post Dated Check Lines with Credit Limit on Customer and Credit Warning, verification done by handler SendNotificationHandler.
        SalesOrder.Close();

        // Tear Down.
        UpdateSalesReceivableSetup(SalesReceivablesSetup."Incl. PDC in Cr. Limit Check", SalesReceivablesSetup."Credit Warnings");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDatedCheckLineWithCustomerAndDateFilter()
    var
        Customer: Record Customer;
        PostDatedCheckLine: Record "Post Dated Check Line";
        PostDatedChecks: TestPage "Post Dated Checks";
    begin
        // [SCENARIO] Post Dated Check Lines with Date and Customer No. filter on Post Dated Check Page.

        // [GIVEN] Create Customer, Post Sales order, create Post Dated Check Lines.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreatePDCLine(Customer."No.", PostDatedCheckLine."Account Type"::Customer, 0, '');  // Using 0 for amount and Blank for Bank Account.

        // Exercise.
        PostDatedCheckWithFilter(PostDatedChecks, Customer."No.");

        // [THEN] Verify Post Dated Check Lines with Date and Customer No. filter on Post Dated Check Page.
        PostDatedChecks."Account No.".AssertEquals(Customer."No.");
        PostDatedChecks."Check Date".AssertEquals(WorkDate());
        PostDatedChecks.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDatedCheckLineDeletedWithDimension()
    var
        Customer: Record Customer;
        PostDatedCheckLine: Record "Post Dated Check Line";
    begin
        // [SCENARIO] Dimension Set ID after deleting Post Dated Check Lines with Dimension.

        // [GIVEN] Create Customer, Post Sales order, create and delete Post Dated Check Lines with Dimension.
        Initialize();
        CreatePDCLineWithDimension(Customer, LibraryRandom.RandInt(10));
        FindAndDeletePDCLine(Customer."No.");

        // Exercise.
        CreatePDCLine(Customer."No.", PostDatedCheckLine."Account Type"::Customer, -LibraryRandom.RandDec(100, 2), '');  // Using blank for Bank Account, Random for Check Amount.

        // [THEN] Verify Dimension Set ID after Deleting Post Dated Check Line on new Post Dated Check Line.
        FindPDCLine(PostDatedCheckLine, Customer."No.");
        PostDatedCheckLine.TestField("Dimension Set ID", 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelPostDatedCheckFromCashReceiptJournal()
    var
        Customer: Record Customer;
        PostDatedCheckLine: Record "Post Dated Check Line";
    begin
        // [SCENARIO] reverted Post Dated Check Line after Cancel Post Dated Check Line from Cash Receipt Journal.

        // [GIVEN] Create Customer, Post Sales order, create Post Dated Check Lines with Dimension and Application, Suggest Checks to Bank and create Cash Journal.
        Initialize();
        CreatePDCLineWithDimension(Customer, 0);  // Using 0 for Dimension Set ID.
        SuggestChecksToBank(Customer."No.");
        CreateCashReceiptJournal(Customer."No.");

        // Exercise:
        CancelPostDatedCheck(Customer."No.");

        // [THEN] Verify reverted Post Dated Check Line after Cancel Post Dated Check Line from Cash Receipt Journal.
        PostDatedCheckLine.SetRange("Account No.", Customer."No.");
        Assert.IsTrue(PostDatedCheckLine.FindFirst(), PDCLineNotFourndErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestPDCCheckToBankForVendor()
    var
        PostDatedCheckLine: Record "Post Dated Check Line";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PDCAmount: Decimal;
    begin
        // [SCENARIO] Post Dated Check and Balance Amount on Vendor after Suggest Checks to Bank from Post Dated Check Lines.

        // [GIVEN] Create Vendor, Post Purchase order and create Post Dated Check Lines.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPurchaseOrder(PurchaseLine, Vendor."No.");
        PDCAmount :=
          CreatePDCLine(Vendor."No.", PostDatedCheckLine."Account Type"::Vendor, LibraryRandom.RandDec(100, 2), '');  // Random for Check Amount, using blank for Bank Account.

        // Exercise.
        SuggestChecksToBank(Vendor."No.");

        // [THEN] Verify Post Dated Check and Balance Amount on Vendor.
        Vendor.CalcFields("Balance (LCY)", "Post Dated Checks (LCY)");
        Vendor.TestField("Balance (LCY)", PurchaseLine."Amount Including VAT");
        Vendor.TestField("Post Dated Checks (LCY)", -PDCAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCheckInstallmentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PDCInstallmentWithoutVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        NoOfInstallmentAndIntRate: Integer;
    begin
        // [SCENARIO] Interest Amount on Post Dated Check Line after Suggest Checks to Bank with Interest Cal Excl. VAT is Yes on General Ledger Setup.

        // [GIVEN] Create Vendor, Post Purchase order and create Post Dated Check Lines.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryPurchase.CreateVendor(Vendor);
        NoOfInstallmentAndIntRate := LibraryRandom.RandIntInRange(2, 5);
        SuggestCheckToBankWithVAT(PurchaseLine, Vendor."No.", true);  // Using True for Interest Cal Excl. VAT.

        // Exercise, Verify and Tear Down.
        CreatePDCInstallmentAndVerifyPDCLines(
          Vendor."No.", PurchaseLine.Amount, NoOfInstallmentAndIntRate, GeneralLedgerSetup."Interest Cal Excl. VAT");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateCheckInstallmentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PDCInstallmentWithVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        NoOfInstallmentAndIntRate: Integer;
    begin
        // [SCENARIO] Interest Amount on Post Dated Check Line after Suggest Checks to Bank with Interest Cal Excl. VAT is No on General Ledger Setup.

        // [GIVEN] Create Vendor, Post Purchase order and create Post Dated Check Lines.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryPurchase.CreateVendor(Vendor);
        NoOfInstallmentAndIntRate := LibraryRandom.RandIntInRange(2, 5);
        SuggestCheckToBankWithVAT(PurchaseLine, Vendor."No.", false);  // Using False for Interest Cal Excl. VAT.

        // Exercise, Verify and Tear Down.
        CreatePDCInstallmentAndVerifyPDCLines(
          Vendor."No.", PurchaseLine."Amount Including VAT", NoOfInstallmentAndIntRate, GeneralLedgerSetup."Interest Cal Excl. VAT");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,CreateCheckInstallmentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PDCInstallmentPostWithWithoutVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GLAccountNo: Code[20];
        NoOfInstallmentAndIntRate: Integer;
    begin
        // [SCENARIO] Interest Amount on GL Entry after Post Payment Journal with Interest Cal Excl. VAT is Yes on General Ledger Setup.

        // [GIVEN] Create Vendor, Post Purchase order and create Post Dated Check Lines.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryPurchase.CreateVendor(Vendor);
        NoOfInstallmentAndIntRate := LibraryRandom.RandIntInRange(2, 5);
        CreatePaymentJournalWithVAT(PurchaseLine, Vendor."No.", true, NoOfInstallmentAndIntRate);  // Using True for Interest Cal Excl. VAT.
        GLAccountNo := UpdateVendorPostingSetup(Vendor."Vendor Posting Group");

        // Exercise, Verify and Tear Down.
        PostPaymentJournalAndVerifyGLEntry(
          Vendor."No.", GLAccountNo, PurchaseLine.Amount, NoOfInstallmentAndIntRate, GeneralLedgerSetup."Interest Cal Excl. VAT");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,CreateCheckInstallmentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PDCInstallmentPostWithVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GLAccountNo: Code[20];
        NoOfInstallmentAndIntRate: Integer;
    begin
        // [SCENARIO] Interest Amount on GL Entry after Post Payment Journal with Interest Cal Excl. VAT is No on General Ledger Setup.

        // [GIVEN] Create Vendor, Post Purchase order and create Post Dated Check Lines.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryPurchase.CreateVendor(Vendor);
        NoOfInstallmentAndIntRate := LibraryRandom.RandIntInRange(2, 5);
        CreatePaymentJournalWithVAT(PurchaseLine, Vendor."No.", false, NoOfInstallmentAndIntRate);  // Using False for Interest Cal Excl. VAT.
        GLAccountNo := UpdateVendorPostingSetup(Vendor."Vendor Posting Group");

        // Exercise, Verify and Tear Down.
        PostPaymentJournalAndVerifyGLEntry(
          Vendor."No.", GLAccountNo, PurchaseLine."Amount Including VAT", NoOfInstallmentAndIntRate,
          GeneralLedgerSetup."Interest Cal Excl. VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDatedCheckLineWithVendorAndDateFilter()
    var
        PostDatedCheckLine: Record "Post Dated Check Line";
        Vendor: Record Vendor;
        PostDatedChecksPurchases: TestPage "Post Dated Checks-Purchases";
    begin
        // [SCENARIO] Post Dated Check Lines with Date and Vendor No. filter on Post Dated Check-Purchase Page.

        // [GIVEN] Create Vendor, Post Purchase order, create Post Dated Check Lines.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreatePDCLine(Vendor."No.", PostDatedCheckLine."Account Type"::Vendor, 0, '');  // Using 0 for amount and Blank for Bank Account.

        // Exercise.
        PurchPostDatedCheckWithFilter(PostDatedChecksPurchases, Vendor."No.");

        // [THEN] Verify Post Dated Check Line with Date and Customer No. filter on Post Dated Check Page.
        PostDatedChecksPurchases."Account No.".AssertEquals(Vendor."No.");
        PostDatedChecksPurchases."Check Date".AssertEquals(WorkDate());
        PostDatedChecksPurchases.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDatedCheckLineDeletedWithDimensionForVendor()
    var
        PostDatedCheckLine: Record "Post Dated Check Line";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [SCENARIO] Dimension Set ID after deleting Purchase Post Dated Check Lines with Dimension.

        // [GIVEN] Create vendor, post Purchase Order, created and delete Post Dated Check Line with Dimension.
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPurchaseOrder(PurchaseLine, Vendor."No.");
        CreatePDCLineWithVendApplication(
          Vendor."No.", SetDimensionID(
            LibraryRandom.RandInt(10)), PostDatedCheckLine."Account Type"::Vendor, LibraryRandom.RandDec(100, 2), '');  // Using Random for Check Amount and Blank for Bank Account.
        FindAndDeletePDCLine(Vendor."No.");

        // Exercise.
        CreatePDCLine(Vendor."No.", PostDatedCheckLine."Account Type"::Vendor, LibraryRandom.RandDec(100, 2), '');  // Using blank for Bank Account, Random for Check Amount.

        // [THEN] Verify Dimension Set ID after Deleting Post Dated Check Line on new Post Dated Check Line.
        FindPDCLine(PostDatedCheckLine, Vendor."No.");
        PostDatedCheckLine.TestField("Dimension Set ID", 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelPostDatedCheckFromPaymentJournal()
    var
        PostDatedCheckLine: Record "Post Dated Check Line";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [SCENARIO] reverted Post Dated Check Line after Cancel Post Dated Check Line from Payment Journal.

        // [GIVEN] Create Vendor, post Purchase order, create Post Dated Check Lines with Dimension and Application, Suggest Checks to Bank and create Payment Journal.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        SuggestCheckToBankWithVAT(PurchaseLine, Vendor."No.", false);  // Using False for Interest Cal Excl. VAT.
        CreatePaymentJournal(Vendor."No.");

        // Exercise:
        CancelPostDatedCheckForVendor(Vendor."No.");

        // [THEN] Verify reverted Post Dated Check Line after Cancel Post Dated Check Line from Payment Journal.
        PostDatedCheckLine.SetRange("Account No.", Vendor."No.");
        Assert.IsTrue(PostDatedCheckLine.FindFirst(), PDCLineNotFourndErr);
    end;

    [Test]
    [HandlerFunctions('EditDimensionSetEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostDatedCheckLinePayableDimension()
    var
        PostDatedCheckLine: Record "Post Dated Check Line";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DimensionSetID: Integer;
    begin
        // [SCENARIO] Post Dated Check Payable Dimension with Receivable Dimension.

        // [GIVEN] Create vendor, post Purchase Order, created Post Dated Check Line with Application.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPurchaseOrder(PurchaseLine, Vendor."No.");
        DimensionSetID := SetDimensionID(LibraryRandom.RandIntInRange(1000, 1100));
        CreatePDCLineWithVendApplication(
          Vendor."No.", DimensionSetID, PostDatedCheckLine."Account Type"::Vendor, LibraryRandom.RandDec(100, 2), '');  // Using Random for Check Amount and Blank for Bank Account.

        // Exercise.
        OpenDimensionFromReceivablePostDatedCheck(DimensionSetID);

        // [SCENARIO] Post Dated Check Payable Dimension with Receivable Dimension, verification done in EditDimensionSetEntriesModalPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDatedCheckLineBankAccountFromBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Vendor: Record Vendor;
        PostDatedChecksPurchases: TestPage "Post Dated Checks-Purchases";
    begin
        // [SCENARIO] Bank Account No. on Post Dated Check-Purchase page, flow from Gen. Journal Batch.

        // [GIVEN] Create Vendor, get Purchase Setup.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        PurchasesPayablesSetup.Get();

        // Exercise.
        CreatePostDatedCheckPurchase(PostDatedChecksPurchases, Vendor."No.");

        // [THEN] Verify Bank Account No. on Post Dated Check-Purchase page.
        GenJournalBatch.Get(PurchasesPayablesSetup."Post Dated Check Template", PurchasesPayablesSetup."Post Dated Check Batch");
        PostDatedChecksPurchases."Bank Account".AssertEquals(GenJournalBatch."Bal. Account No.");
        PostDatedChecksPurchases.Close();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentOnPostDatedCheckLine()
    var
        PostDatedCheckLine: Record "Post Dated Check Line";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [SCENARIO] Post Dated Check Line existence with Vendor No. and Applies-to Doc. No. after execute Suggest Vendor Payment.

        // [GIVEN] Create Vendor, post Purchase Order.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPurchaseOrder(PurchaseLine, Vendor."No.");
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Enqueue value for SuggestVendorPaymentsRequestPageHandler.

        // Exercise.
        SuggestVendorPayment();

        // [THEN] Verify Post Dated Check Line existence with Vendor No. and Applies-to Doc. No. after execute Suggest Vendor Payment.
        FindPDCLine(PostDatedCheckLine, Vendor."No.");
        Assert.AreNotEqual('', PostDatedCheckLine."Applies-to Doc. No.", UnexpectedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostDatedCheckLineWithMultipleApplication()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostDatedCheckLine: Record "Post Dated Check Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [SCENARIO] Post Dated Check Line with more than one application on Payment Journal.

        // [GIVEN] Create Vendor, Post multiple Purchase order and create & Suggest to bank Post Dated Check Lines.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPurchaseOrder(PurchaseLine, Vendor."No.");
        CreateAndPostPurchaseOrder(PurchaseLine2, Vendor."No.");
        CreatePDCLine(Vendor."No.", PostDatedCheckLine."Account Type"::Vendor, 0, '');  // Using 0 for Amount and blank for Bank Account.
        SuggestChecksToBank(Vendor."No.");
        ApplyToEntriesOnPostDatedCheckLine(Vendor."No.");

        // Exercise.
        CreatePaymentJournal(Vendor."No.");

        // [THEN] Verify Post Dated Check Line with more than one application on Payment Journal.
        FindGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.");
        GenJournalLine.TestField(Amount, PurchaseLine."Amount Including VAT" + PurchaseLine2."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('PDCAcknowledgementReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintPDCAcknowledgementReportForCustomer()
    var
        Customer: Record Customer;
    begin
        // [SCENARIO] Print Acknowledgement report for Customer.

        // [GIVEN] Create Customer, Create PDC Line with Application.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostSalesOrder(Customer."No.");
        CreatePDCLineWithCustApplication(Customer."No.", 0, -LibraryRandom.RandDec(100, 2));  // Using 0 for Dimension Set ID, Random for Amount.
        LibraryVariableStorage.Enqueue(Customer."No.");  // Enqueue value for PDCAcknowledgementReceiptRequestPageHandler.
        Commit();  // Commit required to run PDC Acknowledgement Receipt report.

        // Exercise And Verify.
        RunAndVerifyPDCAcknowledgementReceiptReport(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PDCAcknowledgementReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintPDCAcknowledgementReportForVendor()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [SCENARIO] Print Acknowledgement report for Vendor.

        // [GIVEN] Create Vendor, Create PDC Line with Application.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        SuggestCheckToBankWithVAT(PurchaseLine, Vendor."No.", false);  // Using False for Interest Cal Excl. VAT.
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Enqueue value for PDCAcknowledgementReceiptRequestPageHandler.
        Commit();  // Commit required to run PDC Acknowledgement Receipt report.

        // Exercise And Verify.
        RunAndVerifyPDCAcknowledgementReceiptReport(Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,CreateCheckInstallmentsRequestPageHandler,VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure VoidCheckLedgerEntryWithInterestAmount()
    var
        BankAccountNo: Code[20];
    begin
        // [FEATURE] [Void check] [Check Ledger Entry] [Interest]
        // [SCENARIO 123631] Void Check Ledger Entry with Interest Amount
        Initialize();
        // [GIVEN] Check Ledger Entry with Interest Amount
        BankAccountNo := CreatePostPaymentJournalLineManualCheck();
        // [WHEN] Void Check created Check Ledger Entry with "Void check only" option
        LibraryVariableStorage.Enqueue(VoidType::"Void check only");
        VoidCheck(BankAccountNo);
        // [THEN] Check Ledger Entry is voided
        VerifyCheckLedgerEntry(BankAccountNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,CreateCheckInstallmentsRequestPageHandler,VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyAndVoidCheckLedgerEntryWithInterestAmount()
    var
        BankAccountNo: Code[20];
    begin
        // [FEATURE] [Void check] [Check Ledger Entry] [Interest]
        // [SCENARIO 123631] Unapply and Void Check Ledger Entry with Interest Amount
        Initialize();
        // [GIVEN] Check Ledger Entry with Interest Amount
        BankAccountNo := CreatePostPaymentJournalLineManualCheck();
        // [WHEN] Void Check created Check Ledger Entry with "Unapply and void check" option
        LibraryVariableStorage.Enqueue(VoidType::"Unapply and void check");
        VoidCheck(BankAccountNo);
        // [THEN] Check Ledger Entry is voided
        VerifyCheckLedgerEntry(BankAccountNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,CreateCheckInstallmentsRequestPageHandler,VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure VoidCheckWithWHTAndInterestAmount()
    var
        BankAccountNo: Code[20];
        WHTAmount: Decimal;
        OldEnableWHT: Boolean;
        OldEnableGST: Boolean;
    begin
        // [FEATURE] [WHT] [Void Check]
        // [SCENARIO 363133] Void Check with WHT and Interest Amount
        Initialize();
        UpdateGLSetupWHT(true, false, OldEnableWHT, OldEnableGST);
        // [GIVEN] Purchase Invoice with WHT, applied payment with WHT and Interest
        CreateAndPostPurchOrderWithWHTAndAppliedPmt(BankAccountNo, WHTAmount);
        // [WHEN] Financialy void Check
        LibraryVariableStorage.Enqueue(VoidType::"Unapply and void check");
        VoidCheck(BankAccountNo);
        // [THEN] G/L entries reversed
        VerifyVoidedCheckLedgEntryWHTAmount(BankAccountNo, WHTAmount);
        UpdateGLSetupWHT(OldEnableWHT, OldEnableGST, OldEnableWHT, OldEnableGST);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure ApplyToEntriesOnPostDatedCheckLine(AccountNo: Code[20])
    var
        PostDatedChecksPurchases: TestPage "Post Dated Checks-Purchases";
    begin
        PostDatedChecksPurchases.OpenEdit();
        PostDatedChecksPurchases.FILTER.SetFilter("Account No.", AccountNo);
        PostDatedChecksPurchases.ApplyEntries.Invoke();  // Call ApplyVendorEntriesModalPageHandler.
        PostDatedChecksPurchases.Close();
    end;

    local procedure CancelPostDatedCheck(CustomerNo: Code[20])
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.FILTER.SetFilter("Account No.", CustomerNo);
        CashReceiptJournal.CancelPostDatedCheck.Invoke();
        CashReceiptJournal.Close();
    end;

    local procedure CancelPostDatedCheckForVendor(VendorNo: Code[20])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenEdit();
        PaymentJournal.FILTER.SetFilter("Account No.", VendorNo);
        PaymentJournal.CancelPostDatedCheck.Invoke();
        PaymentJournal.Close();
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; BuyFromVendorNo: Code[20])
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, BuyFromVendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 20));  // Use Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(50, 100, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Receive & Invoice.
    end;

    local procedure CreateAndPostPurchOrderWithWHTAndAppliedPmt(var BankAccNo: Code[20]; var WHTAmount: Decimal)
    var
        WHTPostingSetup: Record "WHT Posting Setup";
        BankAccount: Record "Bank Account";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        DocAmount: Decimal;
        NoOfInst: Integer;
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccNo := BankAccount."No.";

        CreateWHTPostingSetup(WHTPostingSetup);
        CreateVATPostingSetup(VATPostingSetup);

        VendorNo := CreateVendorWithWHT(WHTPostingSetup."WHT Business Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        DocAmount :=
          CreateAndPostPurchOrderWithWHT(
            VendorNo, WHTPostingSetup."WHT Product Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CreateAndPostPmtWithWHTAndInterest(VendorNo, BankAccNo, WHTPostingSetup."WHT Product Posting Group", DocAmount, NoOfInst);

        WHTAmount := Round(DocAmount / 100 * WHTPostingSetup."WHT %" / NoOfInst);
    end;

    local procedure CreateAndPostPurchOrderWithWHT(VendorNo: Code[20]; WHTProdPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItemWithWHT(WHTProdPostingGroupCode, VATProdPostingGroupCode), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 10000, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(PurchaseLine.Amount);
    end;

    local procedure CreateAndPostPmtWithWHTAndInterest(VendorNo: Code[20]; BankAccNo: Code[20]; WHTProdPostingGroupCode: Code[20]; Amount: Decimal; var NoOfInst: Integer): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
        PostDatedCheckLine: Record "Post Dated Check Line";
    begin
        CreatePDCLineWithVendApplication(
          VendorNo, 0, PostDatedCheckLine."Account Type"::Vendor, Amount, BankAccNo);
        SuggestChecksToBank(VendorNo);

        CreatePDCInstallment(VendorNo, LibraryRandom.RandIntInRange(2, 5));
        CreatePaymentJournal(VendorNo);

        GenJnlLine.SetRange("Account No.", VendorNo);
        GenJnlLine.ModifyAll("Bank Payment Type", GenJnlLine."Bank Payment Type"::"Manual Check");
        GenJnlLine.ModifyAll("WHT Product Posting Group", WHTProdPostingGroupCode);
        NoOfInst := GenJnlLine.Count;
        PostPaymentJournal(VendorNo);
        exit(GenJnlLine."Document No.");
    end;

    local procedure CreateAndPostSalesOrder(SellToCustomerNo: Code[20]): Decimal
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 20));  // Use Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(50, 100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Ship & Invoice.
        exit(SalesLine."Amount Including VAT");
    end;

    local procedure CreateAndUpdatePDCLine(AccountNo: Code[20]; DimensionSetID: Integer; AccountType: Option; Amount: Decimal; AppliesToDocNo: Code[20]; BankAccountNo: Code[20]) PDCAmount: Decimal
    var
        PostDatedCheckLine: Record "Post Dated Check Line";
    begin
        PDCAmount := CreatePDCLine(AccountNo, AccountType, Amount, BankAccountNo);
        FindPDCLine(PostDatedCheckLine, AccountNo);
        PostDatedCheckLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        PostDatedCheckLine.Validate("Applies-to Doc. Type", PostDatedCheckLine."Applies-to Doc. Type"::Invoice);
        PostDatedCheckLine.Validate("Dimension Set ID", DimensionSetID);
        PostDatedCheckLine.Modify(true);
    end;

    local procedure CreateCashReceiptJournal(AccountNo: Code[20])
    var
        PostDatedChecks: TestPage "Post Dated Checks";
    begin
        PostDatedChecks.OpenEdit();
        PostDatedChecks.FILTER.SetFilter("Account No.", AccountNo);
        PostDatedChecks.CreateCashJournal.Invoke();
        PostDatedChecks.Close();
    end;

    local procedure CreatePaymentJournal(AccountNo: Code[20])
    var
        PostDatedChecksPurchases: TestPage "Post Dated Checks-Purchases";
    begin
        PostDatedChecksPurchases.OpenEdit();
        PostDatedChecksPurchases.FILTER.SetFilter("Account No.", AccountNo);
        PostDatedChecksPurchases.CreatePaymentJournal.Invoke();
        PostDatedChecksPurchases.Close();
    end;

    local procedure CreatePaymentJournalWithVAT(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; InterestCalExclVAT: Boolean; NoOfInstallmentAndIntRate: Integer)
    begin
        SuggestCheckToBankWithVAT(PurchaseLine, VendorNo, InterestCalExclVAT);
        CreatePDCInstallment(VendorNo, NoOfInstallmentAndIntRate);
        CreatePaymentJournal(VendorNo);
    end;

    local procedure CreatePDCInstallment(AccountNo: Code[20]; NoOfInstallmentAndIntRate: Integer)
    var
        PostDatedChecksPurchases: TestPage "Post Dated Checks-Purchases";
    begin
        Commit();  // Commit required for run batch report.
        PostDatedChecksPurchases.OpenEdit();
        PostDatedChecksPurchases.FILTER.SetFilter("Account No.", AccountNo);
        LibraryVariableStorage.Enqueue(NoOfInstallmentAndIntRate);  // Enqueue value for CreateCheckInstallmentsRequestPageHandler.
        PostDatedChecksPurchases.CreateCheckInstallments.Invoke();  // Call CreateCheckInstallmentsRequestPageHandler.
        PostDatedChecksPurchases.Close();
    end;

    local procedure CreatePDCInstallmentAndVerifyPDCLines(VendorNo: Code[20]; Amount: Decimal; NoOfInstallmentAndIntRate: Integer; InterestCalExclVAT: Boolean)
    var
        PostDatedCheckLine: Record "Post Dated Check Line";
    begin
        // Exercise.
        CreatePDCInstallment(VendorNo, NoOfInstallmentAndIntRate);

        // Verify No. of Installment and Interst Amount on Post Dated Check line for Vendor.
        FindPDCLine(PostDatedCheckLine, VendorNo);
        Assert.AreEqual(PostDatedCheckLine.Count, NoOfInstallmentAndIntRate, InstallmentErr);
        Assert.AreNearlyEqual(
          PostDatedCheckLine."Interest Amount", Amount * NoOfInstallmentAndIntRate / 100 / NoOfInstallmentAndIntRate,
          LibraryERM.GetInvoiceRoundingPrecisionLCY(), InstallmentErr);

        // Tear Down.
        UpdateGeneralLedgerSetup(InterestCalExclVAT);
    end;

    local procedure CreatePDCLine(AccountNo: Code[20]; AccountType: Option; Amount: Decimal; BankAccount: Code[20]): Decimal
    var
        PostDatedCheckLine: Record "Post Dated Check Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        LibraryAPACLocalization.CreatePostDatedCheckLine(
          PostDatedCheckLine, AccountNo, AccountType, SalesReceivablesSetup."Post Dated Check Batch",
          SalesReceivablesSetup."Post Dated Check Template");
        PostDatedCheckLine.Validate(Amount, Amount);
        PostDatedCheckLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        PostDatedCheckLine.Validate("Check Date", WorkDate());
        PostDatedCheckLine.Validate("Check No.", LibraryUtility.GenerateGUID());
        PostDatedCheckLine.Validate("Bank Account", BankAccount);
        PostDatedCheckLine.Modify(true);
        exit(PostDatedCheckLine.Amount);
    end;

    local procedure CreatePDCLineWithCustApplication(CustomerNo: Code[20]; DimensionSetID: Integer; Amount: Decimal): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostDatedCheckLine: Record "Post Dated Check Line";
    begin
        FindCustLedgerEntry(CustLedgerEntry, CustomerNo);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        exit(
          CreateAndUpdatePDCLine(
            CustomerNo, DimensionSetID, PostDatedCheckLine."Account Type"::Customer, Amount, CustLedgerEntry."Document No.", ''));  // Using blank for Bank Account No.
    end;

    local procedure CreatePDCLineWithDimension(var Customer: Record Customer; DimensionID: Integer)
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostSalesOrder(Customer."No.");
        CreatePDCLineWithCustApplication(
          Customer."No.", SetDimensionID(DimensionID), -LibraryRandom.RandDecInRange(100, 200, 2));  // Using Random in range to avoid existing entries.
    end;

    local procedure CreatePDCLineWithVendApplication(VendorNo: Code[20]; DimensionSetID: Integer; AccountType: Option; Amount: Decimal; BankAccountNo: Code[20]): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        FindVendorLedgerEntry(VendorLedgerEntry, VendorNo);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
        exit(CreateAndUpdatePDCLine(VendorNo, DimensionSetID, AccountType, Amount, VendorLedgerEntry."Document No.", BankAccountNo));
    end;

    local procedure CreatePostDatedCheckPurchase(var PostDatedChecksPurchases: TestPage "Post Dated Checks-Purchases"; VendorNo: Code[20])
    var
        PostDatedCheckLine: Record "Post Dated Check Line";
    begin
        PostDatedChecksPurchases.OpenEdit();
        PostDatedChecksPurchases."Account Type".SetValue(PostDatedCheckLine."Account Type"::Vendor);
        PostDatedChecksPurchases."Account No.".SetValue(VendorNo);
    end;

    local procedure CreatePostPaymentJournalLineManualCheck(): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        UpdateVendorPostingSetup(Vendor."Vendor Posting Group");

        CreatePaymentJournalWithVAT(
          PurchaseLine, Vendor."No.", true, LibraryRandom.RandIntInRange(2, 5));

        GenJournalLine.SetRange("Account No.", Vendor."No.");
        GenJournalLine.FindFirst();
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Manual Check");
        GenJournalLine.Modify(true);
        PostPaymentJournal(Vendor."No.");
        exit(GenJournalLine."Bal. Account No.")
    end;

    local procedure CreateWHTPostingSetup(var WHTPostingSetup: Record "WHT Posting Setup")
    var
        WHTBusPostingGroup: Record "WHT Business Posting Group";
        WHTProdPostingGroup: Record "WHT Product Posting Group";
    begin
        LibraryAPACLocalization.CreateWHTBusinessPostingGroup(WHTBusPostingGroup);
        LibraryAPACLocalization.CreateWHTProductPostingGroup(WHTProdPostingGroup);
        LibraryAPACLocalization.CreateWHTPostingSetup(
          WHTPostingSetup, WHTBusPostingGroup.Code, WHTProdPostingGroup.Code);

        WHTPostingSetup.Validate("WHT %", LibraryRandom.RandIntInRange(10, 20));
        WHTPostingSetup.Validate("Payable WHT Account Code", LibraryERM.CreateGLAccountNo());
        WHTPostingSetup.Validate("Realized WHT Type", WHTPostingSetup."Realized WHT Type"::Payment);
        WHTPostingSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(
          VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
    end;

    local procedure CreateVendorWithWHT(WHTBusPostingGroupCode: Code[20]; VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        UpdateVendorPostingSetup(Vendor."Vendor Posting Group");
        Vendor.Validate(ABN, '');
        Vendor.Validate("ABN Division Part No.", '');
        Vendor.Validate("WHT Business Posting Group", WHTBusPostingGroupCode);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateItemWithWHT(WHTProductPostingGroup: Code[20]; VATProdPostingGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("WHT Product Posting Group", WHTProductPostingGroup);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure UpdateGLSetupWHT(EnableWHT: Boolean; EnableGST: Boolean; var OldEnableWHT: Boolean; var OldEnableGST: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        OldEnableWHT := GLSetup."Enable WHT";
        OldEnableGST := GLSetup."Enable GST (Australia)";
        GLSetup."Enable WHT" := EnableWHT;
        GLSetup."Enable GST (Australia)" := EnableGST;
        GLSetup.Modify(true);
    end;

    local procedure FindAndDeletePDCLine(AccountNo: Code[20])
    var
        PostDatedCheckLine: Record "Post Dated Check Line";
    begin
        FindPDCLine(PostDatedCheckLine, AccountNo);
        PostDatedCheckLine.Delete(true);
    end;

    local procedure FindCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure FindGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    begin
        GenJournalLine.SetRange("Account Type", AccountType);
        GenJournalLine.SetRange("Account No.", AccountNo);
        GenJournalLine.FindFirst();
    end;

    local procedure FindPDCLine(var PostDatedCheckLine: Record "Post Dated Check Line"; AccountNo: Code[20])
    begin
        PostDatedCheckLine.SetRange("Account No.", AccountNo);
        PostDatedCheckLine.FindFirst();
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure OpenDimensionFromReceivablePostDatedCheck(DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        PostDatedChecks: TestPage "Post Dated Checks";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.FindFirst();
        LibraryVariableStorage.Enqueue(DimensionSetEntry."Dimension Code");  // Enqueue value for EditDimensionSetEntriesModalPageHandler.
        PostDatedChecks.OpenEdit();
        PostDatedChecks.Dimensions.Invoke();  // Call EditDimensionSetEntriesModalPageHandler.
    end;

    local procedure PostDatedCheckWithFilter(var PostDatedChecks: TestPage "Post Dated Checks"; CustomerNo: Code[20])
    begin
        PostDatedChecks.OpenEdit();
        PostDatedChecks.DateFilter.SetValue(WorkDate());
        PostDatedChecks.CustomerNo.SetValue(CustomerNo);
    end;

    local procedure PurchPostDatedCheckWithFilter(var PostDatedChecksPurchases: TestPage "Post Dated Checks-Purchases"; VendorNo: Code[20])
    begin
        PostDatedChecksPurchases.OpenEdit();
        PostDatedChecksPurchases.DateFilter.SetValue(WorkDate());
        PostDatedChecksPurchases.VendorNo.SetValue(VendorNo);
    end;

    local procedure PostPaymentJournal(AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Account No.", AccountNo);
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostPaymentJournalAndVerifyGLEntry(VendorNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal; NoOfInstallmentAndIntRate: Integer; InterestCalExclVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        // Exercise.
        PostPaymentJournal(VendorNo);

        // Verify GL Entries after Post Dated Check line from Payment Journal.
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Round(Amount * NoOfInstallmentAndIntRate / 100 / NoOfInstallmentAndIntRate));

        // Tear Down.
        UpdateGeneralLedgerSetup(InterestCalExclVAT);
    end;

    local procedure RunAndVerifyPDCAcknowledgementReceiptReport(AccountNo: Code[20])
    var
        PostDatedCheckLine: Record "Post Dated Check Line";
    begin
        // Exercise.
        REPORT.Run(REPORT::"PDC Acknowledgement Receipt");

        // Verify Print Acknowledgement report for Post Dated Check Line.
        FindPDCLine(PostDatedCheckLine, AccountNo);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PostDatedCheckLineAccountNoCap, PostDatedCheckLine."Account No.");
        LibraryReportDataset.AssertElementWithValueExists(PostDatedCheckLineCheckNoCap, PostDatedCheckLine."Check No.");
        LibraryReportDataset.AssertElementWithValueExists(PostDatedCheckLineAppliesToDocNoCap, PostDatedCheckLine."Applies-to Doc. No.");
        LibraryReportDataset.AssertElementWithValueExists(PostDatedCheckLineAmountCap, PostDatedCheckLine.Amount);
    end;

    local procedure SetDimensionID(DimensionSetID: Integer): Integer
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        exit(LibraryDimension.CreateDimSet(DimensionSetID, Dimension.Code, DimensionValue.Code));
    end;

    local procedure SuggestChecksToBank(CustomerNo: Code[20])
    var
        PostDatedChecks: TestPage "Post Dated Checks";
    begin
        PostDatedChecks.OpenEdit();
        PostDatedChecks.FILTER.SetFilter("Account No.", CustomerNo);
        PostDatedChecks.SuggestChecksToBank.Invoke();
        PostDatedChecks.Close();
    end;

    local procedure SuggestCheckToBankWithVAT(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; InterestCalExclVAT: Boolean)
    var
        BankAccount: Record "Bank Account";
        PostDatedCheckLine: Record "Post Dated Check Line";
    begin
        // Update General Ledger Setup, Post Purchase order and create Post Dated Check Line with Application.
        UpdateGeneralLedgerSetup(InterestCalExclVAT);
        LibraryERM.CreateBankAccount(BankAccount);
        CreateAndPostPurchaseOrder(PurchaseLine, VendorNo);
        CreatePDCLineWithVendApplication(
          VendorNo, 0, PostDatedCheckLine."Account Type"::Vendor, PurchaseLine."Amount Including VAT", BankAccount."No.");  // Using 0 for Dimension ID.
        SuggestChecksToBank(VendorNo);
    end;

    local procedure SuggestVendorPayment()
    var
        PostDatedChecksPurchases: TestPage "Post Dated Checks-Purchases";
    begin
        PostDatedChecksPurchases.OpenEdit();
        PostDatedChecksPurchases.SuggestVendorPayments.Invoke(); // Call SuggestVendorPaymentsRequestPageHandler.
        PostDatedChecksPurchases.Close();
    end;

    local procedure UpdateGeneralLedgerSetup(InterestCalExclVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Interest Cal Excl. VAT", InterestCalExclVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivableSetup(InclPDCInCrLimitCheck: Boolean; CreditWarnings: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Incl. PDC in Cr. Limit Check", InclPDCInCrLimitCheck);
        SalesReceivablesSetup.Validate("Credit Warnings", CreditWarnings);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateVendorPostingSetup("Code": Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.Get(Code);
        LibraryERM.CreateGLAccount(GLAccount);
        VendorPostingGroup.Validate("Interest Account", GLAccount."No.");
        VendorPostingGroup.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure VerifyCheckLedgerEntry(BankAccountNo: Code[20])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        CheckLedgerEntry.FindFirst();
        Assert.AreEqual(
          CheckLedgerEntry."Entry Status"::"Financially Voided", CheckLedgerEntry."Entry Status",
          StrSubstNo(ValueIncorrectErr, CheckLedgerEntry.FieldCaption("Entry Status")));
    end;

    local procedure VoidCheck(BankAccountNo: Code[20])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        CheckManagement: Codeunit CheckManagement;
        ConfirmFinancialVoid: Page "Confirm Financial Void";
    begin
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        CheckLedgerEntry.FindFirst();
        CheckManagement.FinancialVoidCheck(CheckLedgerEntry);
        ConfirmFinancialVoid.SetCheckLedgerEntry(CheckLedgerEntry);
    end;

    local procedure VerifyVoidedCheckLedgEntryWHTAmount(BankAccNo: Code[20]; WHTAmount: Decimal)
    var
        CheckLedgEntry: Record "Check Ledger Entry";
    begin
        CheckLedgEntry.SetRange("Bank Account No.", BankAccNo);
        CheckLedgEntry.FindFirst();
        Assert.AreNearlyEqual(WHTAmount, CheckLedgEntry."WHT Amount", 0.01, CheckLedgEntry.FieldCaption("WHT Amount"));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.Next();
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditDimensionSetEntriesModalPageHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    var
        DimensionCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimensionCode);
        Assert.AreNotEqual(DimensionCode, EditDimensionSetEntries."Dimension Code".Value, UnexpectedErr);
        EditDimensionSetEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateCheckInstallmentsRequestPageHandler(var CreateCheckInstallments: TestRequestPage "Create Check Installments")
    var
        InstallmentParameters: Variant;
    begin
        LibraryVariableStorage.Dequeue(InstallmentParameters);
        CreateCheckInstallments.NoOfInstallments.SetValue(InstallmentParameters);
        CreateCheckInstallments.InterestPct.SetValue(InstallmentParameters);
        CreateCheckInstallments.PeriodLength.SetValue('<1M>');  // Required 1 month Length Period.
        CreateCheckInstallments.StartDocumentNo.SetValue(Format(LibraryRandom.RandInt(10)));
        CreateCheckInstallments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PDCAcknowledgementReceiptRequestPageHandler(var PDCAcknowledgementReceipt: TestRequestPage "PDC Acknowledgement Receipt")
    var
        AccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(AccountNo);
        PDCAcknowledgementReceipt."Post Dated Check Line 2".SetFilter("Account No.", AccountNo);
        PDCAcknowledgementReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SuggestVendorPayments.Vendor.SetFilter("No.", No);
        SuggestVendorPayments.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPayments.StartingDocumentNo.SetValue(Format(LibraryRandom.RandInt(10)));
        SuggestVendorPayments.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VoidCheckPageHandler(var ConfirmFinancialVoid: Page "Confirm Financial Void"; var Response: Action)
    var
        VoidTypeVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(VoidTypeVariant);
        ConfirmFinancialVoid.InitializeRequest(WorkDate(), VoidTypeVariant);
        Response := ACTION::Yes
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

