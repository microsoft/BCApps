codeunit 144049 "ERM Payment Management"
{
    // // [FEATURE] [Payment Slip]
    // 1.     Verify report GL/Cust. Ledger Reconciliation after creating and posting Gen. Journal Line.
    // 2.     Verify report GL/Vend. Ledger Reconciliation after creating and posting Gen. Journal Line.
    // 3-6.   Verify Error on Posting Payment Slip of Customer and Vendor for Unrealized VAT Type First and Last.
    // 7.     Verify Applied Amount with calculate payment discount on Credit Memo without Currency for Vendor.
    // 8.     Verify Applied Amount with calculate payment discount on Credit Memo with Currency for Vendor.
    // 9.     Verify Applied Amount without calculate payment discount on Credit Memo with Currency for Vendor.
    // 10.    Verify Applied Amount without calculate payment discount on Credit Memo without Currency for Vendor.
    // 11.    Verify Applied Amount with calculate payment discount on Credit Memo without Currency for Customer.
    // 12.    Verify Applied Amount with calculate payment discount on Credit Memo with Currency for Customer.
    // 13.    Verify Applied Amount without calculate payment discount on Credit Memo with Currency for Customer.
    // 14.    Verify Applied Amount without calculate payment discount on Credit Memo without Currency for Customer.
    // 15.    Verify Debit Amount and number of records on Bank Account Ledger and General Ledger in case of Detail Level is Account in Payment Step Ledger for Customer.
    // 16.    Verify Debit Amount and number of records on Bank Account Ledger and General Ledger in case of Detail Level is Line in Payment Step Ledger for Customer.
    // 17.    Verify Debit Amount and number of records on Bank Account Ledger and General Ledger in case of Detail Level is Account in Payment Step Ledger for Vendor.
    // 18.    Verify Debit Amount and number of records on Bank Account Ledger and General Ledger in case of Detail Level is Line in Payment Step Ledger for Vendor.
    // 19.    Verify Error on deleting payment class when Payment Slip is created.
    // 20-21. Verify Payment In Progress Amount on Customer Card when Payment In Progress field is set to True or False on Payment Status.
    // 22-23. Verify Applied and UnApplied Amount on Invoice for Customer.
    // 24.    Verify that the deletion of an applied customer payment line unapplies the customer ledger entry the payment line was applied to; i.e the Applied-to ID field should be cleared.
    // 25-26. Verify that whether a proper Due Date is suggested for manually generated payments for Customer and Vendor.
    // 27-28. Verify that Post Payment Slip of Customer and Vendor for a second time gives an error.
    // 
    // Covers Test Cases for WI - 344345
    // ---------------------------------------------------------------------------------------------------
    // Test Function Name                                                                          TFS ID
    // ---------------------------------------------------------------------------------------------------
    // GLCustLedgerReconciliationReport                                                            169508
    // GLVendLedgerReconciliationReport                                                            169509
    // 
    // Covers Test Cases:  344836
    // ---------------------------------------------------------------------------------------------------
    // Test Function Name                                                                           TFS ID
    // ---------------------------------------------------------------------------------------------------
    // PostPaymentSlipCustomerUnrealizedVATTypeFirstError                                          169497
    // PostPaymentSlipCustomerUnrealizedVATTypeLastError                                           169498
    // PostPaymentSlipVendorUnrealizedVATTypeFirstError                                            169499
    // PostPaymentSlipVendorUnrealizedVATTypeLastError                                             169500
    // 
    // Covers Test Cases:  345005
    // ---------------------------------------------------------------------------------------------------
    // Test Function Name                                                                           TFS ID
    // ---------------------------------------------------------------------------------------------------
    // AppliedAmtForVendOnPaymentSlipWithoutCurrency,
    // AppliedAmtForVendOnPaymentSlipWithDiscOnCrMemo                                        156461,156462
    // AppliedAmtForVendOnPaymentSlipWithCurrency,
    // AppliedAmtForVendOnPaymentSlipWithoutDiscOnCrMemo                                            156464
    // AppliedAmtForCustOnPaymentSlipWithoutCurrency,
    // AppliedAmtForCustOnPaymentSlipWithDiscOnCrMemo                                        156465,156466
    // AppliedAmtForCustOnPaymentSlipWithCurrency,
    // AppliedAmtForCustOnPaymentSlipWithoutDiscOnCrMemo                                            156467
    // PostCustomerPaymentWithDetailLevelAccount                                             169428,169431
    // PostCustomerPaymentWithDetailLevelLine                                                169429,169430
    // PostVendorPaymentWithDetailLevelAccount                                               169501,169503
    // PostVendorPaymentWithDetailLevelLine                                                  169502,169504
    // 
    // Covers Test Cases for WI - 345067
    // ------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                          TFS ID
    // ------------------------------------------------------------------------------------------------------------
    // DeletePaymentClassWithCreatedPaymentSlipError, PaymentInProgressTrueOnCustomerCard    169531,169538
    // PaymentInProgressFalseOnCustomerCard, ApplyAmountOnPaymentSlipForCustomer             169518,169515
    // UnapplyAmountOnPaymentSlipForCustomer, DeleteAppliedCustomerPaymentLine               169516,169533,169534
    // DueDateOnPaymentSlipForCustomer                                                       169535,169536
    // 
    // Covers Test Cases:  TFS 100399
    // ---------------------------------------------------------------------------------------------------
    // Test Function Name                                                                           TFS ID
    // ---------------------------------------------------------------------------------------------------
    // NotPostPaymentSlipCustomerWithError                                                          100399
    // NotPostPaymentSlipVendorWithError                                                            100399

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFRLocalization: Codeunit "Library - FR Localization";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        FilterRangeTxt: Label '%1..%2';
        PaymentClassNameTxt: Label 'Suggest Payments';
        PaymentClassDeleteErr: Label 'You cannot delete this Payment Class because it is already in use.';
        UnexpectedErr: Label 'Expected value does not match with Actual value.';
        UnrealizedVATTypeErr: Label 'Unrealized VAT Type must be equal to ''Percentage''';
        LineIsNotDeletedErr: Label 'Line is not deleted in Payment Slip %1';
        PaymentLineIsNotCopiedErr: Label 'Payment Line is not copied from Payment Slip %1';
        ValueIsIncorrectErr: Label 'Value %1 is incorrect for field %2.';
        StepLedgerGetErr: Label 'The Payment Step Ledger does not exist.';
        EnqueueOpt: Option " ",Application,Verification;
        AccountType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset";
        CheckDimValuePostingLineErr: Label 'A dimension used in %1 %2 %3 has caused an error. Select a Dimension Value Code for the Dimension Code %4 for Vendor %5.';
        CheckDimValuePostingHeaderErr: Label 'A dimension used in %1 has caused an error. Dimension %2 is blocked.';
        PaymentSlipErr: Label 'Payment Slip must be posted without error of Document No.';
        AppliesToIDMustBeBlankErr: Label 'Applies-to ID must be blank in Vendor Ledger Entry.';
        DocumentNoErr: Label 'Document No. must be equal to %1', Comment = '%1 = Document No.';

    [Test]
    [HandlerFunctions('GLCustLedgerReconciliationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLCustLedgerReconciliationReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify report GL/Cust. Ledger Reconciliation after creating and posting Gen. Journal Line.
        GLReconciliationReport(GenJournalLine."Bal. Account Type"::Customer, CreateCustomer(''), REPORT::"GL/Cust. Ledger Reconciliation");  // Using Blank for Currency Code.
    end;

    [Test]
    [HandlerFunctions('GLVendLedgerReconciliationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLVendLedgerReconciliationReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify report GL/Vend. Ledger Reconciliation after creating and posting Gen. Journal Line.
        GLReconciliationReport(GenJournalLine."Bal. Account Type"::Vendor, CreateVendor(''), REPORT::"GL/Vend. Ledger Reconciliation");  // Using Blank for Currency Code.
    end;

    local procedure GLReconciliationReport(BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; ReportID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create and post Gen Journal Line.
        Initialize();
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), GenJournalLine."Document Type"::" ", BalAccountType,
          BalAccountNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");  // Enqueue value for GLCustLedgerReconciliationRequestPageHandler and GLVendLedgerReconciliationRequestPageHandler.

        // Exercise.
        REPORT.Run(ReportID);

        // Verify: Verify Amount on XML after running report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalDebit_TotalCredit', -GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('G_L_Entry_Amount', -GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,ApplyCustomerEntriesModalPageHandler,ConfirmHandlerTrue,CreatePaymentSlipStrMenuHandler,PaymentLinesListModalPageHandler,PaymentSlipPageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentSlipCustomerUnrealizedVATTypeFirstError()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify Error on Posting Payment Slip of Customer for Unrealized VAT Type First.
        // Actual Error is " Unrealized VAT Type must be equal to 'Percentage'  in VAT Posting Setup: VAT Bus. Posting Group=XXXXX, VAT Prod. Posting Group=XXXXXX. Current value is 'First'."
        PostPaymentSlipCustomerUnrealizedVATType(VATPostingSetup."Unrealized VAT Type"::First);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,ApplyCustomerEntriesModalPageHandler,ConfirmHandlerTrue,CreatePaymentSlipStrMenuHandler,PaymentLinesListModalPageHandler,PaymentSlipPageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentSlipCustomerUnrealizedVATTypeLastError()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify Error on Posting Payment Slip of Customer for Unrealized VAT Type Last.
        // Actual Error is "Unrealized VAT Type must be equal to 'Percentage'  in VAT Posting Setup: VAT Bus. Posting Group=XXXXXX, VAT Prod. Posting Group=XXXXXX. Current value is 'Last'."
        PostPaymentSlipCustomerUnrealizedVATType(VATPostingSetup."Unrealized VAT Type"::Last);
    end;

    local procedure PostPaymentSlipCustomerUnrealizedVATType(UnrealizedVATType: Option)
    var
        PaymentClass: Record "Payment Class";
        PaymentLine: Record "Payment Line";
        SellToCustomerNo: Code[20];
        LineNo: Integer;
        LineNo2: Integer;
    begin
        // Setup: Create VAT Posting Setup, Payment Class, Bank Account, GL Account, Setup for Payment Slip and Create and Post Sales Invoice.
        Initialize();
        SellToCustomerNo := CreateAndPostSalesInvoice(UnrealizedVATType);
        PaymentClass.Get(CreatePaymentClass(PaymentClass.Suggestions::Vendor));
        LibraryVariableStorage.Enqueue(PaymentClass.Code);  // Enqueue value for PaymentClassListModalPageHandler.
        LineNo2 := CreateSetupForPaymentSlip(LineNo, PaymentClass.Code, false);  // Using False for Payment In Progress.
        CreatePaymentStepLedgerForCustomer(PaymentClass.Code, LineNo, LineNo2);
        CreateAndPostPaymentSlip(PaymentClass.Code, PaymentLine."Account Type"::Customer, SellToCustomerNo);

        // Exercise & Verify.
        UnrealizedVATTypeError();
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,ApplyVendorEntriesModalPageHandler,ConfirmHandlerTrue,CreatePaymentSlipStrMenuHandler,PaymentLinesListModalPageHandler,PaymentSlipPageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentSlipVendorUnrealizedVATTypeFirstError()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify Error on Posting Payment Slip of Vendor for Unrealized VAT Type First.
        // Actual Error is "Unrealized VAT Type must be equal to 'Percentage'  in VAT Posting Setup: VAT Bus. Posting Group=XXXXX, VAT Prod. Posting Group=XXXXXX. Current value is 'First'."
        PostPaymentSlipVendorUnrealizedVATType(VATPostingSetup."Unrealized VAT Type"::First);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,ApplyVendorEntriesModalPageHandler,ConfirmHandlerTrue,CreatePaymentSlipStrMenuHandler,PaymentLinesListModalPageHandler,PaymentSlipPageHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentSlipVendorUnrealizedVATTypeLastError()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify Error on Posting Payment Slip of Vendor for Unrealized VAT Type Last.
        // Actual Error is "Unrealized VAT Type must be equal to 'Percentage'  in VAT Posting Setup: VAT Bus. Posting Group=XXXXX, VAT Prod. Posting Group=XXXXXX. Current value is 'Last'."
        PostPaymentSlipVendorUnrealizedVATType(VATPostingSetup."Unrealized VAT Type"::Last);
    end;

    local procedure PostPaymentSlipVendorUnrealizedVATType(UnrealizedVATType: Option)
    var
        PaymentClass: Record "Payment Class";
        PaymentLine: Record "Payment Line";
        BuyfromVendorNo: Code[20];
        LineNo: Integer;
        LineNo2: Integer;
    begin
        // Setup: Create VAT Posting Setup, Payment Class, Bank Account, GL Account, Setup for Payment Slip and Create and Post Purchase Invoice.
        Initialize();
        CreateAndPostPurchaseInvoice(UnrealizedVATType, BuyfromVendorNo);
        PaymentClass.Get(CreatePaymentClass(PaymentClass.Suggestions::Vendor));
        LibraryVariableStorage.Enqueue(PaymentClass.Code);  // Enqueue value for PaymentClassListModalPageHandler.
        LineNo2 := CreateSetupForPaymentSlip(LineNo, PaymentClass.Code, false);  // Using False for Payment In Progress.
        CreatePaymentStepLedgerForVendor(PaymentClass.Code, LineNo, LineNo2);
        CreateAndPostPaymentSlip(PaymentClass.Code, PaymentLine."Account Type"::Vendor, BuyfromVendorNo);

        // Exercise & Verify.
        UnrealizedVATTypeError();
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRRequestPageHandler,ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure AppliedAmtForVendOnPaymentSlipWithoutCurrency()
    begin
        // Verify Applied Amount with calculate payment discount on Credit Memo without Currency for Vendor.
        PaymentDiscountOnPurchaseCrMemo('', true);  // Using Blank for Currency Code, True for Calc. Pmt. Discount,
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRRequestPageHandler,ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure AppliedAmtForVendOnPaymentSlipWithDiscOnCrMemo()
    begin
        // Verify Applied Amount with calculate payment discount on Credit Memo with Currency for Vendor.
        PaymentDiscountOnPurchaseCrMemo(LibraryERM.CreateCurrencyWithRandomExchRates(), true);    // Using True for Calc. Pmt. Discount,
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRRequestPageHandler,ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure AppliedAmtForVendOnPaymentSlipWithCurrency()
    begin
        // Verify Applied Amount without calculate payment discount on Credit Memo with Currency for Vendor.
        PaymentDiscountOnPurchaseCrMemo(LibraryERM.CreateCurrencyWithRandomExchRates(), false);  // Using False for Calc. Pmt. Discount,
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRRequestPageHandler,ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure AppliedAmtForVendOnPaymentSlipWithoutDiscOnCrMemo()
    begin
        // Verify Applied Amount without calculate payment discount on Credit Memo without Currency for Vendor.
        PaymentDiscountOnPurchaseCrMemo('', false);  // Using Blank for Currency Code, False for Calc. Pmt. Discount,
    end;

    local procedure PaymentDiscountOnPurchaseCrMemo(CurrencyCode: Code[10]; CalcPmtDiscOnCrMemos: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentClass: Record "Payment Class";
        PaymentHeader: Record "Payment Header";
        Vendor: Record Vendor;
        PaymentSlip: TestPage "Payment Slip";
        Amount: Decimal;
        DiscountAmount: Decimal;
        PaymentClassCode: Text[30];
    begin
        // Setup: Create Vnedor, update Payment Terms, create and post Purchase Invoice and Credit Memo through Gen Journal Line.
        Initialize();
        Amount := LibraryRandom.RandDecInRange(10, 1000, 2);  // Using Random Dec In Range for Amount.
        Vendor.Get(CreateVendor(CurrencyCode));
        DiscountAmount := CalcPaymentTermDiscount(Vendor."Payment Terms Code", CalcPmtDiscOnCrMemos, Amount);
        PaymentClassCode :=
          PostGenJournalAndCreatePaymentSlip(
            GenJournalLine."Account Type"::Vendor, Vendor."No.", PaymentClass.Suggestions::Vendor, -Amount);  // Required partial amount for Cr. Memo.
        LibraryVariableStorage.Enqueue(PaymentClassCode);  // Enqueue value for PaymentClassListModalPageHandler.
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader);
        Commit();  // Required for execute report.
        SuggestVendorPaymentLines(Vendor."No.", CurrencyCode, PaymentHeader);
        LibraryVariableStorage.Enqueue(GenJournalLine."Document Type"::"Credit Memo");  // Enqueue for ApplyVendorEntriesModalPageHandler.
        EnqueueValuesForHandler(EnqueueOpt::Verification, (-Amount + DiscountAmount));  // Enqueue for ApplyVendorEntriesModalPageHandler.

        // Exercise: Application call from Payment Slip.
        OpenPaymentSlip(PaymentSlip, PaymentHeader."No.");
        PaymentSlipApplication(PaymentSlip);  // Calculate Amount after payment discount.

        // Verify: Verify Applied Amount on Applied Vendor Ledger Entry, Verification done by ApplyVendorEntriesModalPageHandler.
        PaymentSlip.Close();
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsRequestPageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure AppliedAmtForCustOnPaymentSlipWithoutCurrency()
    begin
        // Verify Applied Amount with calculate payment discount on Credit Memo without Currency for Customer.
        PaymentDiscountOnSalesCrMemo('', true);  // Using Blank for Currency Code, True for Calc. Pmt. Discount,
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsRequestPageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure AppliedAmtForCustOnPaymentSlipWithDiscOnCrMemo()
    begin
        // Verify Applied Amount with calculate payment discount on Credit Memo with Currency for Customer.
        PaymentDiscountOnSalesCrMemo(LibraryERM.CreateCurrencyWithRandomExchRates(), true);  // Using True for Calc. Pmt. Discount,
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsRequestPageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure AppliedAmtForCustOnPaymentSlipWithCurrency()
    begin
        // Verify Applied Amount without calculate payment discount on Credit Memo with Currency for Customer.
        PaymentDiscountOnSalesCrMemo(LibraryERM.CreateCurrencyWithRandomExchRates(), false);  // Using False for Calc. Pmt. Discount,
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsRequestPageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure AppliedAmtForCustOnPaymentSlipWithoutDiscOnCrMemo()
    begin
        // Verify Applied Amount without calculate payment discount on Credit Memo without Currency for Customer.
        PaymentDiscountOnSalesCrMemo('', false);  // Using Blank for Currency Code, False for Calc. Pmt. Discount,
    end;

    local procedure PaymentDiscountOnSalesCrMemo(CurrencyCode: Code[10]; CalcPmtDiscOnCrMemos: Boolean)
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        PaymentClass: Record "Payment Class";
        PaymentHeader: Record "Payment Header";
        PaymentSlip: TestPage "Payment Slip";
        Amount: Decimal;
        DiscountAmount: Decimal;
        PaymentClassCode: Text[30];
    begin
        // Setup: Create Customer, update Payment Terms, create and post Sales Invoice and Credit Memo through Gen Journal Line.
        Initialize();
        Amount := LibraryRandom.RandDecInRange(10, 1000, 2);  // Using Random Dec In Range for Amount.
        Customer.Get(CreateCustomer(CurrencyCode));
        DiscountAmount := CalcPaymentTermDiscount(Customer."Payment Terms Code", CalcPmtDiscOnCrMemos, Amount);
        PaymentClassCode :=
          PostGenJournalAndCreatePaymentSlip(
            GenJournalLine."Account Type"::Customer, Customer."No.", PaymentClass.Suggestions::Customer, Amount);  // Required partial amount for Cr. Memo.
        LibraryVariableStorage.Enqueue(PaymentClassCode);  // Enqueue value for PaymentClassListModalPageHandler.
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader);
        Commit();  // Required for execute report.
        SuggestCustomerPaymentLines(Customer."No.", CurrencyCode, PaymentHeader);

        LibraryVariableStorage.Enqueue(GenJournalLine."Document Type"::"Credit Memo");
        EnqueueValuesForHandler(EnqueueOpt::Verification, Amount - DiscountAmount);  // Enqueue for ApplyCustomerEntriesModalPageHandler.

        // Exercise: Application call from Payment Slip.
        OpenPaymentSlip(PaymentSlip, PaymentHeader."No.");
        PaymentSlipApplication(PaymentSlip);  // Calculate Amount after payment discount.

        // Verify: Verify Applied Amount on Applied Customer Ledger Entry, Verification done by ApplyCustomerEntriesModalPageHandler.
        PaymentSlip.Close();
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsRequestPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostCustomerPaymentWithDetailLevelAccount()
    var
        PaymentStepLedger: Record "Payment Step Ledger";
    begin
        // Verify Debit Amount and number of records on Bank Account Ledger and General Ledger in case of Detail Level is Account in Payment Step Ledger for Customer.
        PostPaymentSlipWithMultipleCustomer(PaymentStepLedger."Detail Level"::Account, 1);  // 1 required for Number of Records.
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsRequestPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostCustomerPaymentWithDetailLevelLine()
    var
        PaymentStepLedger: Record "Payment Step Ledger";
    begin
        // Verify Debit Amount and number of records on Bank Account Ledger and General Ledger in case of Detail Level is Line in Payment Step Ledger for Customer.
        PostPaymentSlipWithMultipleCustomer(PaymentStepLedger."Detail Level"::Line, 2);  // 2 required for Number of Records.
    end;

    local procedure PostPaymentSlipWithMultipleCustomer(DetailLevel: Option; NoOfRecord: Integer)
    var
        PaymentClass: Record "Payment Class";
        PaymentHeader: Record "Payment Header";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        CustomerNo2: Code[20];
    begin
        // Setup: Create and Post two Sales Invoice with different customers, create setup for post Payment Slip and suggest customer payment.
        Initialize();
        CustomerNo := CreateAndPostSalesInvoice(VATPostingSetup."Unrealized VAT Type"::" ");
        CustomerNo2 := CreateAndPostSalesInvoice(VATPostingSetup."Unrealized VAT Type"::" ");
        PaymentClass.Get(SetupForPaymentSlipPost(DetailLevel, PaymentClass.Suggestions::Customer));
        CreatePaymentHeader(PaymentHeader);
        Commit();  // Required for execute report.

        SuggestCustomerPaymentLines(StrSubstNo(FilterRangeTxt, CustomerNo, CustomerNo2), '', PaymentHeader); // For SuggestCustomerPaymentsFRRequestPageHandler

        // Exercise and Verify.
        PostPaymentSlipAndVerifyLedgers(PaymentHeader, NoOfRecord);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRRequestPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostVendorPaymentWithDetailLevelAccount()
    var
        PaymentStepLedger: Record "Payment Step Ledger";
    begin
        // Verify Debit Amount and number of records on Bank Account Ledger and General Ledger in case of Detail Level is Account in Payment Step Ledger for Vendor.
        PostPaymentSlipWithMultipleVendor(PaymentStepLedger."Detail Level"::Account, 1);  // 1 required for Number of Records.
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRRequestPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostVendorPaymentWithDetailLevelLine()
    var
        PaymentStepLedger: Record "Payment Step Ledger";
    begin
        // Verify Debit Amount and number of records on Bank Account Ledger and General Ledger in case of Detail Level is Line in Payment Step Ledger for Vendor.
        PostPaymentSlipWithMultipleVendor(PaymentStepLedger."Detail Level"::Line, 2);  // 2 required for Number of Records.
    end;

    local procedure PostPaymentSlipWithMultipleVendor(DetailLevel: Option; NoOfRecord: Integer)
    var
        PaymentClass: Record "Payment Class";
        PaymentHeader: Record "Payment Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        VendorNo2: Code[20];
    begin
        // Setup: Create and Post two Purchase Invoice with different vendors, create setup for post Payment Slip and suggest Vendor payment.
        Initialize();
        CreateAndPostPurchaseInvoice(VATPostingSetup."Unrealized VAT Type"::" ", VendorNo);
        CreateAndPostPurchaseInvoice(VATPostingSetup."Unrealized VAT Type"::" ", VendorNo2);
        PaymentClass.Get(SetupForPaymentSlipPost(DetailLevel, PaymentClass.Suggestions::Vendor));
        CreatePaymentHeader(PaymentHeader);
        Commit();  // Required for execute report.
        SuggestVendorPaymentLines(StrSubstNo(FilterRangeTxt, VendorNo, VendorNo2), '', PaymentHeader);

        // Exercise and Verify.
        PostPaymentSlipAndVerifyLedgers(PaymentHeader, NoOfRecord);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler')]
    [Scope('OnPrem')]
    procedure DeletePaymentClassWithCreatedPaymentSlipError()
    var
        PaymentClass: Record "Payment Class";
        PaymentLine: Record "Payment Line";
        LineNo: Integer;
    begin
        // Verify Error on deleting payment class when Payment Slip is created.
        // Setup: Create Payment Class, Setup and payment slip.
        Initialize();
        PaymentClass.Get(CreatePaymentClass(PaymentClass.Suggestions::Customer));
        LibraryVariableStorage.Enqueue(PaymentClass.Code);  // Enqueue value for PaymentClassListModalPageHandler.
        CreateSetupForPaymentSlip(LineNo, PaymentClass.Code, false);  // Using False for Payment In Progress.
        CreatePaymentSlip(PaymentLine."Account Type"::Customer, CreateCustomer(''));  // Blank currency code.

        // Exercise.
        asserterror PaymentClass.Delete(true);

        // Verify: Verify Error on deleting payment class when Payment Slip is created.
        Assert.ExpectedError(PaymentClassDeleteErr);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentInProgressTrueOnCustomerCard()
    var
        Customer: Record Customer;
        PaymentInProgressLCY: Decimal;
    begin
        // Verify Payment In Progress Amount on Customer Card when Payment In Progress field is set to True on Payment Status.

        // [GIVEN] Create Customer X
        // [GIVEN] Create and post Sales Invoice for Customer X
        // [GIVEN] Create Payment Class
        // [GIVEN] Create Setup of Payment Class and Create Payment Slip with True for Payment In Progress field in Payment Status
        Initialize();
        PaymentInProgressLCY := PaymentInProgressOnCustomer(Customer, true);

        // [WHEN] Calculate Payment in progress (LCY) for Customer X
        Customer.CalcFields("Payment in progress (LCY)");

        // [THEN] Payment in progress (LCY) for Customer X and the amount on payment lines for account no. = X are equal
        Assert.AreEqual(Customer."Payment in progress (LCY)", PaymentInProgressLCY,
            StrSubstNo(ValueIsIncorrectErr, Customer."Payment in progress (LCY)", Customer.FieldCaption("Payment in progress (LCY)")));
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentInProgressFalseOnCustomerCard()
    var
        Customer: Record Customer;
    begin
        // Verify Payment In Progress Amount on Customer Card when Payment In Progress field is set to False on Payment Status.

        // [GIVEN] Create Customer X
        // [GIVEN] Create and post Sales Invoice for Customer X
        // [GIVEN] Create Payment Class
        // [GIVEN] Create Setup of Payment Class and Create Payment Slip with False for Payment In Progress field in Payment Status
        Initialize();
        PaymentInProgressOnCustomer(Customer, false);

        // [WHEN] Calculate Payment in progress (LCY) for Customer X
        Customer.CalcFields("Payment in progress (LCY)");

        // [THEN] Payment in progress (LCY) for Customer X is 0
        Assert.AreEqual(Customer."Payment in progress (LCY)", 0,
            StrSubstNo(ValueIsIncorrectErr, Customer."Payment in progress (LCY)", Customer.FieldCaption("Payment in progress (LCY)")));
    end;

    local procedure PaymentInProgressOnCustomer(var Customer: Record Customer; PaymentInProgress: Boolean): Decimal
    var
        PaymentClass: Record "Payment Class";
        PaymentLine: Record "Payment Line";
        VATPostingSetup: Record "VAT Posting Setup";
        LineNo: Integer;
    begin
        // Setup: Create Customer, create and post Sales Invoice, Create Payment Class, Create Setup of Payment Class and Create Payment Slip.
        PaymentClass.Get(CreatePaymentClass(PaymentClass.Suggestions::Customer));
        LibraryVariableStorage.Enqueue(PaymentClass.Code);  // Enqueue value for PaymentClassListModalPageHandler.
        CreateSetupForPaymentSlip(LineNo, PaymentClass.Code, PaymentInProgress);
        CreatePaymentSlip(PaymentLine."Account Type"::Customer, CreateAndPostSalesInvoice(VATPostingSetup."Unrealized VAT Type"::" "));

        // Exercise.
        ApplyPaymentSlip(PaymentClass.Code);

        // Verify: Verify Payment In Progress Amount on Customer Card.
        PaymentLine.SetRange("Payment Class", PaymentClass.Code);
        PaymentLine.FindFirst();

        Customer.Get(PaymentLine."Account No.");
        exit(-PaymentLine.Amount);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsRequestPageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyAmountOnPaymentSlipForCustomer()
    var
        PaymentSlip: TestPage "Payment Slip";
    begin
        // Verify Applied Amount on Invoice for Customer.
        Initialize();
        CreatePaymentSlipWithDiscount(PaymentSlip);

        // Exercise: Application call from Payment Slip.
        PaymentSlipApplication(PaymentSlip);  // Calculate Amount after payment discount.

        // Verify: Verify Applied Amount on Applied Customer Ledger Entry, Verification done in ApplyCustomerEntriesModalPageHandler.
        PaymentSlip.Close();
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsRequestPageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyAmountOnPaymentSlipForCustomer()
    var
        PaymentSlip: TestPage "Payment Slip";
    begin
        // Verify UnApplied Amount on Invoice for Customer.
        Initialize();
        CreatePaymentSlipWithDiscount(PaymentSlip);
        PaymentSlipApplication(PaymentSlip);

        // Exercise: Apply Payment Slip again to Unapply Payment Slip.
        ApplyPaymentSlip(Format(PaymentSlip."Payment Class"));

        // Verify: Verify UnApplied Amount on Applied Customer Ledger Entry, Verification done in ApplyCustomerEntriesModalPageHandler.
        PaymentSlip.Close();
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsRequestPageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteAppliedCustomerPaymentLine()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentSlip: TestPage "Payment Slip";
    begin
        // Verify that the deletion of an applied customer payment line unapplies the customer ledger entry the payment line was applied to; i.e the Applied-to ID field should be cleared.
        // Setup: Create and Post Sales Invoice with Discount, Create Payment Class,
        Initialize();
        CreatePaymentSlipWithDiscount(PaymentSlip);
        PaymentSlipApplication(PaymentSlip);

        // Exercise:
        FindAndDeletePaymentLine(Format(PaymentSlip."No."));

        // Verify: Verify Applied To ID on Customer Ledger Entry table and Due Date on ApplyCustomerEntriesModalPageHandler.
        CustLedgerEntry.SetRange("Customer No.", Format(PaymentSlip.Lines."Account No."));
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Applies-to ID", '');
        PaymentSlip.Close();
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsSummarizedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DueDateOnPaymentSlipForCustomer()
    var
        PaymentLine: Record "Payment Line";
        CustomerNo: Code[20];
        SummarizePer: Option " ",Customer,"Due date";
        DueDate: Date;
    begin
        // Verify that whether a proper Due Date is suggested for manually generated payments for Customer.
        // Setup & Exercise: Create and Post Sales Invoice, Create Payment Class, Setup and Create Payment Slip.
        Initialize();
        DueDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        CustomerNo := CreateCustomer('');  // Using blank currency.
        CreatePaymentSlipAndSuggestCustomerPayment(CustomerNo, CustomerNo, DueDate, SummarizePer::Customer);

        // Verify: Verify Due Date on Payment Line.
        PaymentLine.SetRange("Account No.", CustomerNo);
        PaymentLine.FindFirst();
        PaymentLine.TestField("Due Date", WorkDate());
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,ConfirmHandlerTrue,CreatePaymentSlipStrMenuHandler,PaymentLinesListModalPageHandler,PaymentSlipRemovePageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentLineCanBeRemovedFromPaymentSlip()
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        PaymentStep: Record "Payment Step";
        PaymentClass: Text[30];
        LineNo: Integer;
    begin
        // Verify removing of Payment Line from copied Payment Slip
        Initialize();

        // Create Payment Slip and remove line
        CreatePaymentOfLinesFromPostedPaymentSlip(PaymentClass, LineNo);

        // Filter copied Payment Slip Lines
        FindPaymentStep(PaymentStep, PaymentClass, LineNo);
        FindPaymentHeader(PaymentHeader, PaymentClass, PaymentStep."Next Status");
        PaymentLine.SetRange("No.", PaymentHeader."No.");

        // Verify Payment Line is deleted from copied Payment Slip
        Assert.IsTrue(PaymentLine.IsEmpty, StrSubstNo(LineIsNotDeletedErr, PaymentHeader."No."));
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,ConfirmHandlerTrue,CreatePaymentSlipStrMenuHandler,PaymentLinesListModalPageHandler,PaymentSlipRemovePageHandler')]
    [Scope('OnPrem')]
    procedure PaymentLineIsAvailableForNewPaymentSlipAfterRemoving()
    var
        PaymentClass: Text[30];
        LineNo: Integer;
    begin
        // Verify line removed from Payment Slip is available for a new Payment Slip
        Initialize();

        // Create and Payment Slip and remove line
        CreatePaymentOfLinesFromPostedPaymentSlip(PaymentClass, LineNo);

        // Create new copy of Payment Slip
        LibraryVariableStorage.Enqueue(PaymentClass); // Enqueue value for PaymentSlipRemovePageHandler
        LibraryVariableStorage.Enqueue(LineNo);       // Enqueue value for PaymentSlipRemovePageHandler
        LibraryFRLocalization.CreatePaymentSlip();

        // Verification done in PaymentSlipRemovePageHandler
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsRequestPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure NotPostPaymentSlipCustomerWithError()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentClass: Record "Payment Class";
        PaymentClassCode: Text[30];
        SellToCustomerNo: Code[20];
    begin
        // Verify that Posting of Payment Slip of Customer with error is not possible.

        // Setup
        PaymentClassCode := CreatePaymentClassWithSetup(PaymentClass.Suggestions::Customer);

        SellToCustomerNo := CreateAndPostSalesInvoice(VATPostingSetup."Unrealized VAT Type"::First);
        CreatePaymentSlipWithCustomerPayments(SellToCustomerNo, PaymentClassCode);

        // Exercise & Verify
        VerifyPostingError(PaymentClassCode);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRRequestPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure NotPostPaymentSlipVendorWithError()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentClass: Record "Payment Class";
        PaymentClassCode: Text[30];
        BuyFromVendorNo: Code[20];
    begin
        // Verify that Posting of Payment Slip of of Vendor with error is not possible.

        // Setup
        PaymentClassCode := CreatePaymentClassWithSetup(PaymentClass.Suggestions::Vendor);

        CreateAndPostPurchaseInvoice(VATPostingSetup."Unrealized VAT Type"::First, BuyFromVendorNo);
        CreatePaymentSlipWithVendorPayments(BuyFromVendorNo, PaymentClassCode);

        // Exercise & Verify
        VerifyPostingError(PaymentClassCode);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsRequestPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CustPaymentLineEntryNoAfterPostingWithMemorizeEntrySetup()
    var
        PaymentClass: Record "Payment Class";
        PaymentStepLedger: Record "Payment Step Ledger";
        PaymentClassCode: Text[30];
        PaymentHeaderNo: Code[20];
    begin
        // [SCENARIO 123828] Payment Line's Debit/Credit Entry No. is filled after post Sales Invoice and Payment Slip with "Payment Ledger Entry"."Memorize Entry" = TRUE
        Initialize();

        // [GIVEN] Payment Slip Setup with "Payment Ledger Entry"."Memorize Entry" = TRUE
        PaymentClassCode := SetupForPaymentSlipPost(PaymentStepLedger."Detail Level"::Account, PaymentClass.Suggestions::Customer);
        UpdatePaymentStepLedgerMemorizeEntry(PaymentClassCode, true);

        // [WHEN] Post payment slip applied to sales invoice
        CreatePostSlipAppliedToSalesInvoice(PaymentHeaderNo);

        // [THEN] "Payment Slip Line"."Entry No. Debit" = Last Debit G/L Entry No.
        // [THEN] "Payment Slip Line"."Entry No. Debit Memo" = Last Debit G/L Entry No.
        // [THEN] "Payment Slip Line"."Entry No. Credit" = Last Credit G/L Entry No.
        // [THEN] "Payment Slip Line"."Entry No. Credit Memo" = Last Credit G/L Entry No.
        VerifyPaymentLineDebitCreditGLNo(PaymentHeaderNo, PaymentClassCode);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRRequestPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure VendPaymentLineEntryNoAfterPostingWithMemorizeEntrySetup()
    var
        PaymentClass: Record "Payment Class";
        PaymentStepLedger: Record "Payment Step Ledger";
        PaymentClassCode: Text[30];
        PaymentHeaderNo: Code[20];
    begin
        // [SCENARIO 123828] Payment Line's Debit/Credit Entry No. is filled after post Purchase Invoice and Payment Slip with "Payment Ledger Entry"."Memorize Entry" = TRUE
        Initialize();

        // [GIVEN] Payment Slip Setup with "Payment Ledger Entry"."Memorize Entry" = TRUE
        PaymentClassCode := SetupForPaymentSlipPost(PaymentStepLedger."Detail Level"::Account, PaymentClass.Suggestions::Vendor);
        UpdatePaymentStepLedgerMemorizeEntry(PaymentClassCode, true);

        // [WHEN] Post payment slip applied to purchase invoice
        CreatePostSlipAppliedToPurchaseInvoice(PaymentHeaderNo);

        // [THEN] "Payment Slip Line"."Entry No. Debit" = Last Debit G/L Entry No.
        // [THEN] "Payment Slip Line"."Entry No. Debit Memo" = Last Debit G/L Entry No.
        // [THEN] "Payment Slip Line"."Entry No. Credit" = Last Credit G/L Entry No.
        // [THEN] "Payment Slip Line"."Entry No. Credit Memo" = Last Credit G/L Entry No.
        VerifyPaymentLineDebitCreditGLNo(PaymentHeaderNo, PaymentClassCode);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustPaymentLineDimensionSetIDAfterSuggest()
    var
        PaymentSlip: TestPage "Payment Slip";
        CustomerNo: Code[20];
        DimSetID: array[2] of Integer;
        DocNo: array[2] of Code[20];
        SuggestionsOption: Option "None",Customer,Vendor;
    begin
        // [FEATURE] [Dimension][Sales]
        // [SCENARIO 375597] System copies "Dimension Set ID" from posted Sales Order to Payment Line on "Suggest Customer Payment".
        Initialize();

        // [GIVEN] Posted Sales Orders with "Dimension Set ID" = "X"
        // [GIVEN] Posted Sales Orders with "Dimension Set ID" = "Y"
        CustomerNo := LibrarySales.CreateCustomerNo();
        DocNo[1] := PostSalesOrderWithDimensions(DimSetID[1], CustomerNo);
        DocNo[2] := PostSalesOrderWithDimensions(DimSetID[2], CustomerNo);
        CreatePaymentSlipBySuggest(SuggestionsOption::Customer);
        OpenPaymentSlip(PaymentSlip, '');
        EnqueueValuesForHandler(CustomerNo, '');

        // [WHEN] Suggests Customer Payments
        PaymentSlip.SuggestCustomerPayments.Invoke();

        // [THEN] First "Payment Line"."Dimension Set ID" = "X"
        VerifyPaymentLineDimSetID(DimSetID[1], DocNo[1]);
        // [THEN] Second "Payment Line"."Dimension Set ID" = "Y"
        VerifyPaymentLineDimSetID(DimSetID[2], DocNo[2]);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendPaymentLineDimensionSetIDAfterSuggest()
    var
        PaymentSlip: TestPage "Payment Slip";
        VendorNo: Code[20];
        DimSetID: array[2] of Integer;
        DocNo: array[2] of Code[20];
        SuggestionsOption: Option "None",Customer,Vendor;
    begin
        // [FEATURE] [Dimension][Purchase]
        // [SCENARIO 375597] System copies "Dimension Set ID" from posted Purchase Order to Payment Line on "Suggest Vendor Payment".
        Initialize();

        // [GIVEN] Posted Purchase Order with "Dimension Set ID" = "X"
        // [GIVEN] Posted Purchase Order with "Dimension Set ID" = "Y"
        VendorNo := LibraryPurchase.CreateVendorNo();
        DocNo[1] := PostPurchaseOrderWithDimensions(DimSetID[1], VendorNo);
        DocNo[2] := PostPurchaseOrderWithDimensions(DimSetID[2], VendorNo);
        CreatePaymentSlipBySuggest(SuggestionsOption::Vendor);
        OpenPaymentSlip(PaymentSlip, '');
        EnqueueValuesForHandler(VendorNo, '');

        // [WHEN] Suggests Vendor Payments
        PaymentSlip.SuggestVendorPayments.Invoke();

        // [THEN] First "Payment Line"."Dimension Set ID" = "X"
        VerifyPaymentLineDimSetID(DimSetID[1], DocNo[1]);
        // [THEN] Second "Payment Line"."Dimension Set ID" = "Y"
        VerifyPaymentLineDimSetID(DimSetID[2], DocNo[2]);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentSlipLineApplyVLEAppliesToIdEqualPaymentLineDocNo()
    var
        PaymentClass: Record "Payment Class";
        PaymentStepLedger: Record "Payment Step Ledger";
        PaymentLine: Record "Payment Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        PaymentSlip: TestPage "Payment Slip";
        PaymentHeaderNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Apply] [Purchase]
        // [SCENARIO 376303] Applies-to ID equals to Payment Line "No."/"Document No." when payment line applied to Vendor Ledger Entry
        Initialize();

        // [GIVEN] Payment Slip Setup with Line No. series defined (<> Header No. Series)
        PaymentClass.Get(
          SetupForPaymentSlipPost(PaymentStepLedger."Detail Level"::Account, PaymentClass.Suggestions::Vendor));
        PaymentClass.Validate("Line No. Series", LibraryERM.CreateNoSeriesCode());
        PaymentClass.Modify(true);

        // [GIVEN] Posted Purchase Invoice
        PurchInvHeader.Get(
          CreateAndPostPurchaseInvoice(VATPostingSetup."Unrealized VAT Type"::" ", VendorNo));

        // [GIVEN] Payment Slip with Payment Line with Document No. = "Y"
        PaymentHeaderNo := CreatePaymentSlip(PaymentLine."Account Type"::Vendor, VendorNo);
        OpenPaymentSlip(PaymentSlip, PaymentHeaderNo);
        EnqueueValuesForHandler(EnqueueOpt::Application, PurchInvHeader."Amount Including VAT");

        // [WHEN] Payment Line applied to Vendor Ledger Entry of Posted Purchase Invoice
        PaymentSlipApplication(PaymentSlip);

        // [THEN] Vendor Ledger Entry value of Applies-to ID = "Y"
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PurchInvHeader."No.");
        PaymentLine.SetRange("No.", PaymentHeaderNo);
        PaymentLine.FindFirst();
        VendorLedgerEntry.TestField("Applies-to ID", PaymentLine."No." + '/' + PaymentLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentSlipLineApplyCLEAppliesToIdEqualPaymentLineDocNo()
    var
        PaymentClass: Record "Payment Class";
        PaymentStepLedger: Record "Payment Step Ledger";
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentLine: Record "Payment Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentSlip: TestPage "Payment Slip";
        PaymentHeaderNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Apply] [Sales]
        // [SCENARIO 376303] Applies-to ID equals to Payment Line "No."/"Document No." when payment line applied to Customer Ledger Entry
        Initialize();

        // [GIVEN] Payment Slip Setup with Line No. series defined (<> Header No. Series)
        PaymentClass.Get(
          SetupForPaymentSlipPost(PaymentStepLedger."Detail Level"::Account, PaymentClass.Suggestions::Customer));
        PaymentClass.Validate("Line No. Series", LibraryERM.CreateNoSeriesCode());
        PaymentClass.Modify(true);

        // [GIVEN] Posted Sales Invoice
        CustomerNo := CreateAndPostSalesInvoice(VATPostingSetup."Unrealized VAT Type"::" ");
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesInvoiceHeader.FindFirst();

        // [GIVEN] Payment Slip with Payment Line with Document No. = "Y"
        PaymentHeaderNo := CreatePaymentSlip(PaymentLine."Account Type"::Customer, CustomerNo);
        OpenPaymentSlip(PaymentSlip, PaymentHeaderNo);
        EnqueueValuesForHandler(EnqueueOpt::Application, SalesInvoiceHeader."Amount Including VAT");

        // [WHEN] Payment Line applied to Customer Ledger Entry of Posted Sales Invoice
        PaymentSlipApplication(PaymentSlip);

        // [THEN] Customer Ledger Entry value of Applies-to ID = "Y"
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, SalesInvoiceHeader."No.");
        PaymentLine.SetRange("No.", PaymentHeaderNo);
        PaymentLine.FindFirst();
        CustLedgerEntry.TestField("Applies-to ID", PaymentLine."No." + '/' + PaymentLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentSlipLineApplyVLEAppliesToIdEqualPaymentLineNoSlashLineNo()
    var
        PaymentClass: Record "Payment Class";
        PaymentStepLedger: Record "Payment Step Ledger";
        PaymentLine: Record "Payment Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentSlip: TestPage "Payment Slip";
        PaymentHeaderNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Apply] [Purchase]
        // [SCENARIO 376303] Applies-to ID equals to "Payment Line No./Payment Line Line No." when payment line applied to Vendor Ledger Entry and Payment Line "Document No." is empty
        Initialize();

        // [GIVEN] Payment Slip Setup with Line No. series not defined
        PaymentClass.Get(
          SetupForPaymentSlipPost(PaymentStepLedger."Detail Level"::Account, PaymentClass.Suggestions::Vendor));

        // [GIVEN] Posted Purchase Invoice
        PurchInvHeader.Get(
          CreateAndPostPurchaseInvoice(VATPostingSetup."Unrealized VAT Type"::" ", VendorNo));

        // [GIVEN] Payment Slip with Payment Line with Document No. = "", Payment Line No. = "Y", Paymen Line Line No. = "10000"
        PaymentHeaderNo := CreatePaymentSlip(PaymentLine."Account Type"::Vendor, VendorNo);
        PaymentLine.SetRange("No.", PaymentHeaderNo);
        PaymentLine.FindFirst();
        PaymentLine.Validate("Document No.", '');
        PaymentLine.Modify(true);
        OpenPaymentSlip(PaymentSlip, PaymentHeaderNo);
        EnqueueValuesForHandler(EnqueueOpt::Application, PurchInvHeader."Amount Including VAT");

        // [WHEN] Payment Line applied to Vendor Ledger Entry of Posted Purchase Invoice
        PaymentSlipApplication(PaymentSlip);

        // [THEN] Vendor Ledger Entry value of Applies-to ID = "Y/10000"
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PurchInvHeader."No.");
        VendorLedgerEntry.TestField(
          "Applies-to ID",
          PaymentLine."No." + '/' + Format(PaymentLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRRequestPageHandler,ConfirmHandlerTrue,CreatePaymentSlipStrMenuHandler,PaymentLinesListModalPageHandler,PaymentSlipPageCloseHandler')]
    [Scope('OnPrem')]
    procedure VendLedgEntriesClosedAfterDelayedVATRealize()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentClassCode: Text[30];
        VendorNo: Code[20];
        PaymentHeaderNo: Code[20];
        PurchInvHeaderNo: Code[20];
        LineNo: array[3] of Integer;
    begin
        // [FEATURE] [Unrealized VAT] [Purchase]
        // [SCENARIO 376302] Vendor Ledger Entries should be closed with Payment Slips and delayed Unrealized VAT reversal setup
        Initialize();

        // [GIVEN] Posted Purchase Invoice for Vendor "V" with VAT Posting Setup and Unrealized VAT Type = Percentage
        PurchInvHeaderNo := CreateAndPostPurchaseInvoice(VATPostingSetup."Unrealized VAT Type"::Percentage, VendorNo);

        // [GIVEN] Payment Slip Setup with delayed Unrealized VAT reversal
        CreatePaymentSlipSetupWithDelayedVATRealize(PaymentClassCode, LineNo);

        // [GIVEN] Posted Payment Slip for 1st Payment Step with suggested line for Posted Purchase Invoice
        CreateSuggestAndPostPaymentSlip(VendorNo);

        // [WHEN] Payment Slip "P" created by Create Payment Slip job for 2nd Payment Step is posted
        PaymentHeaderNo :=
          CreatePaymentSlipWithSourceCodeAndAccountNo(
            CreateSourceCode(), LibraryERM.CreateBankAccountNo(), PaymentClassCode, LineNo[2]);

        // [THEN] All Vendor Ledger Entries for Vendor "V" are closed
        VerifyVendorLedgerEntriesClosed(VendorNo, 4);

        // [THEN] VAT is Realized
        VerifyRealizedVAT(PurchInvHeaderNo, PaymentHeaderNo);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRRequestPageHandler,ConfirmHandlerTrue,CreatePaymentSlipStrMenuHandler,PaymentLinesListModalPageHandler,PaymentSlipPageCloseHandler')]
    [Scope('OnPrem')]
    procedure VendLedgEntriesClosedAfterDelayedVATRealizeAndNonDelayedVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentClassCode: Text[30];
        VendorNo: Code[20];
        PaymentHeaderNo: Code[20];
        PurchInvHeaderNo: Code[20];
        LineNo: array[3] of Integer;
    begin
        // [FEATURE] [Unrealized VAT] [Purchase]
        // [SCENARIO 376302] Vendor Ledger Entries for Normal VAT and delayed Unrealized VAT should be closed with Payment Slips
        Initialize();

        // [GIVEN] Posted Purchase Invoice for Vendor "V" with Line of Unrealized VAT Type = Percentage and line of Unrealized VAT Type = ""
        PurchInvHeaderNo :=
          CreateAndPostPurchaseInvoiceWithMixedVATPostingSetup(VATPostingSetup."Unrealized VAT Type"::Percentage, VendorNo);

        // [GIVEN] Payment Slip Setup with delayed Unrealized VAT reversal
        CreatePaymentSlipSetupWithDelayedVATRealize(PaymentClassCode, LineNo);

        // [GIVEN] Posted Payment Slip for 1st Payment Step with suggested line for Posted Purchase Invoice
        CreateSuggestAndPostPaymentSlip(VendorNo);

        // [WHEN] Payment Slip "P" created by Create Payment Slip job for 2nd Payment Step is posted
        PaymentHeaderNo :=
          CreatePaymentSlipWithSourceCodeAndAccountNo(
            CreateSourceCode(), LibraryERM.CreateBankAccountNo(), PaymentClassCode, LineNo[2]);

        // [THEN] All Vendor Ledger Entries for Vendor "V" are closed
        VerifyVendorLedgerEntriesClosed(VendorNo, 4);

        // [THEN] VAT is Realized
        VerifyRealizedVAT(PurchInvHeaderNo, PaymentHeaderNo);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsSummarizedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustPaymentLineDimensionAfterSuggestBlank()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        SummarizePer: Option " ",Customer,"Due date";
        CustomerNo: array[2] of Code[20];
    begin
        // [FEATURE] [Dimension] [Sales]
        // [SCENARIO 381150] "Suggest Customer Payment" with "Summarize Per" option set to blank.
        Initialize();

        // [GIVEN] Posted Sales Order for first Customer with "Dimension Value" = "X"
        CreateCustomerWithDefaultDimensionsPostSalesOrder(CustomerNo[1], DimensionValue[1]);
        // [GIVEN] Posted Sales Order for first Customer with "Dimension Value" = "Y"
        CreateCustomerWithDefaultDimensionsPostSalesOrder(CustomerNo[2], DimensionValue[2]);

        // [WHEN] Suggests Customer Payments with blank "Summarize per" option
        CreateCustomerPaymentSlip(CustomerNo, SummarizePer::" ");

        // [THEN] First "Payment Line" has "Dimension Value" = "X"
        VerifyPaymentLineDimensionValue(AccountType::Customer, CustomerNo[1], DimensionValue[1]);
        // [THEN] Second "Payment Line" has "Dimension Value" = "Y"
        VerifyPaymentLineDimensionValue(AccountType::Customer, CustomerNo[2], DimensionValue[2]);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsSummarizedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustPaymentLineDimensionAfterSuggestPerCustomer()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        SummarizePer: Option " ",Customer,"Due date";
        CustomerNo: array[2] of Code[20];
    begin
        // [FEATURE] [Dimension] [Sales]
        // [SCENARIO 381150] "Suggest Customer Payment" with "Summarize Per" option set to "Customer".
        Initialize();

        // [GIVEN] Posted Sales Order for first Customer with "Dimension Value" = "X"
        CreateCustomerWithDefaultDimensionsPostSalesOrder(CustomerNo[1], DimensionValue[1]);
        // [GIVEN] Posted Sales Order for first Customer with "Dimension Value" = "Y"
        CreateCustomerWithDefaultDimensionsPostSalesOrder(CustomerNo[2], DimensionValue[2]);

        // [WHEN] Suggests Customer Payments with "Summarize per" option set to "Due Date"
        CreateCustomerPaymentSlip(CustomerNo, SummarizePer::Customer);

        // [THEN] First "Payment Line" has "Dimension Value" = "X"
        VerifyPaymentLineDimensionValue(AccountType::Customer, CustomerNo[1], DimensionValue[1]);
        // [THEN] Second "Payment Line" has "Dimension Value" = "Y"
        VerifyPaymentLineDimensionValue(AccountType::Customer, CustomerNo[2], DimensionValue[2]);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsSummarizedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustPaymentLineDimensionAfterSuggestPerDueDate()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        SummarizePer: Option " ",Customer,"Due date";
        CustomerNo: array[2] of Code[20];
    begin
        // [FEATURE] [Dimension] [Sales]
        // [SCENARIO 381150] "Suggest Customer Payment" with "Summarize Per" option set to "Due Date".
        Initialize();

        // [GIVEN] Posted Sales Order for first Customer with "Dimension Value" = "X"
        CreateCustomerWithDefaultDimensionsPostSalesOrder(CustomerNo[1], DimensionValue[1]);
        // [GIVEN] Posted Sales Order for first Customer with "Dimension Value" = "Y"
        CreateCustomerWithDefaultDimensionsPostSalesOrder(CustomerNo[2], DimensionValue[2]);

        // [WHEN] Suggests Customer Payments with "Summarize per" option set to "Due Date"
        CreateCustomerPaymentSlip(CustomerNo, SummarizePer::"Due date");

        // [THEN] First "Payment Line" has "Dimension Value" = "X"
        VerifyPaymentLineDimensionValue(AccountType::Customer, CustomerNo[1], DimensionValue[1]);
        // [THEN] Second "Payment Line" has "Dimension Value" = "Y"
        VerifyPaymentLineDimensionValue(AccountType::Customer, CustomerNo[2], DimensionValue[2]);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRSummarizedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendPaymentLineDimensionAfterSuggestBlank()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        SummarizePer: Option " ",Vendor,"Due date";
        VendorNo: array[2] of Code[10];
    begin
        // [FEATURE] [Dimension] [Purchase]
        // [SCENARIO 381150] "Suggest Vendor Payment" with "Summarize Per" option set to blank.
        Initialize();

        // [GIVEN] Posted Purchase Order for first Vendor with "Dimension Value" = "X"
        CreateVendorWithDefaultDimensionsPostPurchaseOrder(VendorNo[1], DimensionValue[1]);
        // [GIVEN] Posted Purchase Order for second Vendor with "Dimension Value" = "Y"
        CreateVendorWithDefaultDimensionsPostPurchaseOrder(VendorNo[2], DimensionValue[2]);

        // [WHEN] Suggests Vendor Payments with blank "Summarize per" option
        CreateVendorPaymentSlip(VendorNo, SummarizePer::" "); // SuggestVendorPaymentsFRSummarizedRequestPageHandler

        // [THEN] First "Payment Line" has "Dimension Value" = "X"
        VerifyPaymentLineDimensionValue(AccountType::Vendor, VendorNo[1], DimensionValue[1]);
        // [THEN] Second "Payment Line" has "Dimension Value" = "Y"
        VerifyPaymentLineDimensionValue(AccountType::Vendor, VendorNo[2], DimensionValue[2]);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRSummarizedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendPaymentLineDimensionAfterSuggestPerVendor()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        SummarizePer: Option " ",Vendor,"Due date";
        VendorNo: array[2] of Code[20];
    begin
        // [FEATURE] [Dimension] [Purchase]
        // [SCENARIO 381150] "Suggest Vendor Payment" with "Summarize Per" option set to "Vendor".
        Initialize();

        // [GIVEN] Posted Purchase Order for first Vendor with "Dimension Value" = "X"
        CreateVendorWithDefaultDimensionsPostPurchaseOrder(VendorNo[1], DimensionValue[1]);
        // [GIVEN] Posted Purchase Order for second Vendor with "Dimension Value" = "Y"
        CreateVendorWithDefaultDimensionsPostPurchaseOrder(VendorNo[2], DimensionValue[2]);

        // [WHEN] Suggests Vendor Payments with "Summarize per" option equal to "Vendor"
        CreateVendorPaymentSlip(VendorNo, SummarizePer::Vendor); // SuggestVendorPaymentsFRSummarizedRequestPageHandler

        // [THEN] First "Payment Line" has "Dimension Value" = "X"
        VerifyPaymentLineDimensionValue(AccountType::Vendor, VendorNo[1], DimensionValue[1]);
        // [THEN] Second "Payment Line" has "Dimension Value" = "Y"
        VerifyPaymentLineDimensionValue(AccountType::Vendor, VendorNo[2], DimensionValue[2]);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRSummarizedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendPaymentLineDimensionAfterSuggestPerDueDate()
    var
        DimensionValue: array[2] of Record "Dimension Value";
        SummarizePer: Option " ",Vendor,"Due date";
        VendorNo: array[2] of Code[20];
    begin
        // [FEATURE] [Dimension] [Purchase]
        // [SCENARIO 381150] "Suggest Vendor Payment" with "Summarize Per" option set to "Due Date".
        Initialize();

        // [GIVEN] Posted Purchase Order for first Vendor with "Dimension Value" = "X"
        CreateVendorWithDefaultDimensionsPostPurchaseOrder(VendorNo[1], DimensionValue[1]);
        // [GIVEN] Posted Purchase Order for second Vendor with "Dimension Value" = "Y"
        CreateVendorWithDefaultDimensionsPostPurchaseOrder(VendorNo[2], DimensionValue[2]);

        // [WHEN] Suggests Vendor Payments with "Summarize per" option equal to "Due Date"
        CreateVendorPaymentSlip(VendorNo, SummarizePer::"Due date"); // SuggestVendorPaymentsFRSummarizedRequestPageHandler

        // [THEN] First "Payment Line" has "Dimension Value" = "X"
        VerifyPaymentLineDimensionValue(AccountType::Vendor, VendorNo[1], DimensionValue[1]);
        // [THEN] Second "Payment Line" has "Dimension Value" = "Y"
        VerifyPaymentLineDimensionValue(AccountType::Vendor, VendorNo[2], DimensionValue[2]);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentSlipWithUpdatedExchangeRate()
    var
        PaymentHeader: Record "Payment Header";
        Vendor: Record Vendor;
        Currency: Record Currency;
        PostingDate: Date;
        RateFactorY: Decimal;
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 381339] Suggest Vendor Payments function on the Payment Slip page when Currency Exch. Rate is updated.
        Initialize();

        // [GIVEN] Currency with updated Exchange Rate
        CreateCurrencyWithDifferentExchangeRate(Currency, PostingDate, RateFactorY);

        // [GIVEN] Post Purchase Invoice when Currency Factor = "X"
        CreatePurchaseInvoiceWithCurrencyAndPost(Vendor, Currency, PostingDate);

        // [WHEN] Suggest Payment Slip when Currency Factor = "Y"
        CreatePaymentSlipWithCurrency(PaymentHeader, Vendor, Currency);

        // [THEN] Payment Line contains updated Currency Factor = "Y"
        VerifyPaymentLineCurrencyFactor(PaymentHeader, RateFactorY);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateAndPostPaymentSlipForIncompleteDimensionLine()
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        PaymentClass: Record "Payment Class";
        PaymentLine: Record "Payment Line";
        Vendor: Record Vendor;
        LineNo: Integer;
        LineNo2: Integer;
        PmtHeaderNo: Code[20];
    begin
        // [SCENARIO 311493] Posting 'Payment Line' for Vendor with empty 'Dimension Value Code' in 'Default Dimension' throws error
        Initialize();

        // [GIVEN] Created Vendor with 'Default Dimension' with empty 'Dimension Value Code'
        LibraryPurchase.CreateVendor(Vendor);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", Dimension.Code, '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // [GIVEN] Setup for Payment Slip
        PaymentClass.Get(CreatePaymentClass(PaymentClass.Suggestions::Vendor));
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LineNo2 := CreateSetupForPaymentSlip(LineNo, PaymentClass.Code, true);
        CreatePaymentStepLedgerForVendor(PaymentClass.Code, LineNo, LineNo2);

        // [WHEN] Try to create and post Payment Slip with incompete Default Dimension
        asserterror CreateAndPostNoApplyPaymentSlip(PmtHeaderNo, PaymentClass.Code, PaymentLine."Account Type"::Vendor, Vendor."No.");

        // [THEN] An error is thrown: "A dimension used in <payment line> has caused an error. Select a Dimension Value Code..."
        Assert.ExpectedErrorCode('TestWrapped:Dialog');
        Assert.ExpectedError(StrSubstNo(CheckDimValuePostingLineErr, PmtHeaderNo, PaymentLine.TableCaption(),
            LineNo, Dimension.Code, Vendor."No."));
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateAndPostPaymentSlipForBlockedDimensionHeader()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        PaymentClass: Record "Payment Class";
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        Vendor: Record Vendor;
        LineNo: Integer;
        LineNo2: Integer;
    begin
        // [SCENARIO 311493] Posting 'Payment Slip' for Vendor with blocked Dimension throws error
        Initialize();

        // [GIVEN] Created Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Setup for Payment Slip
        PaymentClass.Get(CreatePaymentClass(PaymentClass.Suggestions::Vendor));
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LineNo2 := CreateSetupForPaymentSlip(LineNo, PaymentClass.Code, true);
        CreatePaymentStepLedgerForVendor(PaymentClass.Code, LineNo, LineNo2);

        // [GIVEN] Create Payment Slip with Dimension
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        CreatePaymentSlip(PaymentLine."Account Type"::Vendor, Vendor."No.");
        PaymentLine.SetFilter("Account Type", Format(PaymentLine."Account Type"::Vendor));
        PaymentLine.SetFilter("Account No.", Vendor."No.");
        PaymentLine.FindFirst();
        PaymentHeader.SetFilter("No.", PaymentLine."No.");
        PaymentHeader.FindFirst();
        PaymentHeader.Validate("Dimension Set ID", LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code));
        PaymentHeader.Modify(true);

        // [GIVEN] Block Dimension
        Dimension.SetFilter(Code, DimensionValue."Dimension Code");
        Dimension.FindFirst();
        LibraryDimension.BlockDimension(Dimension);

        // [WHEN] Post Payment Slip with blocked Dimension
        asserterror PostPaymentSlip(PaymentClass.Code);

        // [THEN] An error is thrown: "A dimension used in <payment header> has caused an error. Dimension <No.> is blocked."
        Assert.ExpectedErrorCode('TestWrapped:Dialog');
        Assert.ExpectedError(StrSubstNo(CheckDimValuePostingHeaderErr, PaymentHeader."No.", Dimension.Code));
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsSummarizedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeletingPaymentSlipWithCustomerPaymentLineSummarizedPerCustomer()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: array[2] of Record Customer;
        PaymentClass: Record "Payment Class";
        PaymentHeader: array[2] of Record "Payment Header";
        PaymentStatus: Record "Payment Status";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentLine: Record "Payment Line";
        SummarizePer: Option " ",Customer,"Due date";
    begin
        // [SCENARIO 316414] Deleting Payment Slip doesn't lead to empty "Applies-to ID" of wrong Customer Ledger Entry, when entries suggested using Summarize per Customer.
        Initialize();

        // [GIVEN] Customers "C1", "C2".
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);
        // [GIVEN] Gen. Jnl. Lines "G1", "G2" and associated Customer Ledger Entries "CLE1", "CLE2".
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer[1]."No.", GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(10, 2), WorkDate());
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer[2]."No.", GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(10, 2), WorkDate());

        // [GIVEN] Payment class with No. Series.
        PaymentClass.Get(CreatePaymentClass(PaymentClass.Suggestions::Customer));
        PaymentClass.Validate("Line No. Series", LibraryERM.CreateNoSeriesCode());
        PaymentClass.Modify(true);
        LibraryFRLocalization.CreatePaymentStatus(PaymentStatus, PaymentClass.Code);

        // [GIVEN] Payment Slips "P1", "P2".
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader[1]);
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader[2]);
        Commit();

        // [GIVEN] "P1" suggested payment summarized per Customer "C1", "P2" suggested payment summarized per Customer "C2".
        SuggestCustomerPaymentLines(Customer[1]."No.", SummarizePer::Customer, PaymentHeader[1]);
        SuggestCustomerPaymentLines(Customer[2]."No.", SummarizePer::Customer, PaymentHeader[2]);
        PaymentLine.SetRange("No.", PaymentHeader[2]."No.");
        PaymentLine.FindFirst();
        VerifyLastNoUsedInNoSeries(PaymentClass."Line No. Series", PaymentLine."Document No."); // TFS 409091. Last No used is updated

        // [WHEN] Paymen Slip "P2" is deleted.
        PaymentHeader[2].Delete(true);

        // [THEN] "CLE1" still has "Applies-to ID", while "CLE2"'s "Applies-to ID" is empty.
        CustLedgerEntry.SetRange("Customer No.", Customer[1]."No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Applies-to ID");

        CustLedgerEntry.SetRange("Customer No.", Customer[2]."No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Applies-to ID", '');
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsSummarizedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeletingPaymentSlipWithCustomerPaymentLineSummarizedPerDueDate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: array[2] of Record Customer;
        PaymentClass: Record "Payment Class";
        PaymentHeader: array[2] of Record "Payment Header";
        PaymentStatus: Record "Payment Status";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentLine: Record "Payment Line";
        SummarizePer: Option " ",Customer,"Due date";
    begin
        // [SCENARIO 316414] Deleting Payment Slip doesn't lead to empty "Applies-to ID" of wrong Customer Ledger Entry, when entries suggested using Summarize per Due date.
        Initialize();

        // [GIVEN] Customers "C1", "C2".
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);
        // [GIVEN] Gen. Jnl. Lines "G1", "G2" and associated Customer Ledger Entries "CLE1", "CLE2".
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer[1]."No.", GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(10, 2), WorkDate());
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer[2]."No.", GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(10, 2), WorkDate());

        // [GIVEN] Payment class with No. Series.
        PaymentClass.Get(CreatePaymentClass(PaymentClass.Suggestions::Customer));
        PaymentClass.Validate("Line No. Series", LibraryERM.CreateNoSeriesCode());
        PaymentClass.Modify(true);
        LibraryFRLocalization.CreatePaymentStatus(PaymentStatus, PaymentClass.Code);

        // [GIVEN] Payment Slips "P1", "P2".
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader[1]);
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader[2]);
        Commit();

        // [GIVEN] "P1" suggested payment summarized per Due date, "P2" suggested payment summarized per Due date.
        SuggestCustomerPaymentLines(Customer[1]."No.", SummarizePer::"Due date", PaymentHeader[1]);
        SuggestCustomerPaymentLines(Customer[2]."No.", SummarizePer::"Due date", PaymentHeader[2]);
        PaymentLine.SetRange("No.", PaymentHeader[2]."No.");
        PaymentLine.FindFirst();
        VerifyLastNoUsedInNoSeries(PaymentClass."Line No. Series", PaymentLine."Document No."); // TFS 409091. Last No used is updated

        // [WHEN] Paymen Slip "P2" is deleted.
        PaymentHeader[2].Delete(true);

        // [THEN] "CLE1" still has "Applies-to ID", while "CLE2"'s "Applies-to ID" is empty.
        CustLedgerEntry.SetRange("Customer No.", Customer[1]."No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Applies-to ID");

        CustLedgerEntry.SetRange("Customer No.", Customer[2]."No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Applies-to ID", '');
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestCustomerPaymentsSummarizedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeletingPaymentSlipWithCustomerPaymentLine()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: array[2] of Record Customer;
        PaymentClass: Record "Payment Class";
        PaymentHeader: array[2] of Record "Payment Header";
        PaymentStatus: Record "Payment Status";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentLine: Record "Payment Line";
        SummarizePer: Option " ",Customer,"Due date";
    begin
        // [SCENARIO 316414] Deleting Payment Slip doesn't lead to empty "Applies-to ID" of wrong Customer Ledger Entry, when entries suggested without summarization.
        Initialize();

        // [GIVEN] Customers "C1", "C2".
        LibrarySales.CreateCustomer(Customer[1]);
        LibrarySales.CreateCustomer(Customer[2]);
        // [GIVEN] Gen. Jnl. Lines "G1", "G2" and associated Customer Ledger Entries "CLE1", "CLE2".
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer[1]."No.", GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(10, 2), WorkDate());
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer[2]."No.", GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(10, 2), WorkDate());

        // [GIVEN] Payment class with No. Series.
        PaymentClass.Get(CreatePaymentClass(PaymentClass.Suggestions::Customer));
        PaymentClass.Validate("Line No. Series", LibraryERM.CreateNoSeriesCode());
        PaymentClass.Modify(true);
        LibraryFRLocalization.CreatePaymentStatus(PaymentStatus, PaymentClass.Code);

        // [GIVEN] Payment Slips "P1", "P2".
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader[1]);
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader[2]);
        Commit();

        // [GIVEN] "P1" and "P2" suggested payment without summarization.
        SuggestCustomerPaymentLines(Customer[1]."No.", SummarizePer::" ", PaymentHeader[1]);
        SuggestCustomerPaymentLines(Customer[2]."No.", SummarizePer::" ", PaymentHeader[2]);
        PaymentLine.SetRange("No.", PaymentHeader[2]."No.");
        PaymentLine.FindFirst();
        VerifyLastNoUsedInNoSeries(PaymentClass."Line No. Series", PaymentLine."Document No."); // TFS 409091. Last No used is updated

        // [WHEN] Paymen Slip "P2" is deleted.
        PaymentHeader[2].Delete(true);

        // [THEN] "CLE1" still has "Applies-to ID", while "CLE2"'s "Applies-to ID" is empty.
        CustLedgerEntry.SetRange("Customer No.", Customer[1]."No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Applies-to ID");

        CustLedgerEntry.SetRange("Customer No.", Customer[2]."No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Applies-to ID", '');
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRSummarizedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeletingPaymentSlipWithVendorPaymentLineSummarizedPerVendor()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: array[2] of Record Vendor;
        PaymentClass: Record "Payment Class";
        PaymentHeader: array[2] of Record "Payment Header";
        PaymentStatus: Record "Payment Status";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentLine: Record "Payment Line";
        SummarizePer: Option " ",Vendor,"Due date";
    begin
        // [SCENARIO 316414] Deleting Payment Slip doesn't lead to empty "Applies-to ID" of wrong Vendor Ledger Entry, when entries suggested using Summarize per Vendor.
        Initialize();

        // [GIVEN] Vendors "C1", "C2".
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);
        // [GIVEN] Gen. Jnl. Lines "G1", "G2" and associated Vendor Ledger Entries "VLE1", "VLE2".
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor[1]."No.", GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(10, 2), WorkDate());
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor[2]."No.", GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(10, 2), WorkDate());

        // [GIVEN] Payment class with No. Series.
        PaymentClass.Get(CreatePaymentClass(PaymentClass.Suggestions::Vendor));
        PaymentClass.Validate("Line No. Series", LibraryERM.CreateNoSeriesCode());
        PaymentClass.Modify(true);
        LibraryFRLocalization.CreatePaymentStatus(PaymentStatus, PaymentClass.Code);

        // [GIVEN] Payment Slips "P1", "P2".
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader[1]);
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader[2]);
        Commit();

        // [GIVEN] "P1" suggested payment summarized per Vendor "C1", "P2" suggested payment summarized per Vendor "C2".
        SuggestVendorPaymentLines(Vendor[1]."No.", SummarizePer::Vendor, PaymentHeader[1]);
        SuggestVendorPaymentLines(Vendor[2]."No.", SummarizePer::Vendor, PaymentHeader[2]);
        PaymentLine.SetRange("No.", PaymentHeader[2]."No.");
        PaymentLine.FindFirst();
        VerifyLastNoUsedInNoSeries(PaymentClass."Line No. Series", PaymentLine."Document No."); // TFS 409091. Last No used is updated

        // [WHEN] Paymen Slip "P2" is deleted.
        PaymentHeader[2].Delete(true);

        // [THEN] "VLE1" still has "Applies-to ID", while "VLE2"'s "Applies-to ID" is empty.
        VendorLedgerEntry.SetRange("Vendor No.", Vendor[1]."No.");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Applies-to ID");

        VendorLedgerEntry.SetRange("Vendor No.", Vendor[2]."No.");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Applies-to ID", '');
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRSummarizedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeletingPaymentSlipWithVendorPaymentLineSummarizedPerDueDate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: array[2] of Record Vendor;
        PaymentClass: Record "Payment Class";
        PaymentHeader: array[2] of Record "Payment Header";
        PaymentStatus: Record "Payment Status";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentLine: Record "Payment Line";
        SummarizePer: Option " ",Customer,"Due date";
    begin
        // [SCENARIO 316414] Deleting Payment Slip doesn't lead to empty "Applies-to ID" of wrong Vendor Ledger Entry, when entries suggested using Summarize per Due date.
        Initialize();

        // [GIVEN] Vendors "C1", "C2".
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);
        // [GIVEN] Gen. Jnl. Lines "G1", "G2" and associated Vendor Ledger Entries "VLE1", "VLE2".
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor[1]."No.", GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(10, 2), WorkDate());
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor[2]."No.", GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(10, 2), WorkDate());

        // [GIVEN] Payment class with No. Series.
        PaymentClass.Get(CreatePaymentClass(PaymentClass.Suggestions::Vendor));
        PaymentClass.Validate("Line No. Series", LibraryERM.CreateNoSeriesCode());
        PaymentClass.Modify(true);
        LibraryFRLocalization.CreatePaymentStatus(PaymentStatus, PaymentClass.Code);

        // [GIVEN] Payment Slips "P1", "P2" and associated Vendor Ledger Entries "VLE1", "VLE2".
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader[1]);
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader[2]);
        Commit();

        // [GIVEN] "P1" suggested payment summarized per Due date, "P2" suggested payment summarized per Due date.
        SuggestVendorPaymentLines(Vendor[1]."No.", SummarizePer::"Due date", PaymentHeader[1]);
        SuggestVendorPaymentLines(Vendor[2]."No.", SummarizePer::"Due date", PaymentHeader[2]);
        PaymentLine.SetRange("No.", PaymentHeader[2]."No.");
        PaymentLine.FindFirst();
        VerifyLastNoUsedInNoSeries(PaymentClass."Line No. Series", PaymentLine."Document No."); // TFS 409091. Last No used is updated

        // [WHEN] Paymen Slip "P2" is deleted.
        PaymentHeader[2].Delete(true);

        // [THEN] "VLE1" still has "Applies-to ID", while "VLE2"'s "Applies-to ID" is empty.
        VendorLedgerEntry.SetRange("Vendor No.", Vendor[1]."No.");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Applies-to ID");

        VendorLedgerEntry.SetRange("Vendor No.", Vendor[2]."No.");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Applies-to ID", '');
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRSummarizedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeletingPaymentSlipWithVendorPaymentLine()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: array[2] of Record Vendor;
        PaymentClass: Record "Payment Class";
        PaymentHeader: array[2] of Record "Payment Header";
        PaymentStatus: Record "Payment Status";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentLine: Record "Payment Line";
        SummarizePer: Option " ",Customer,"Due date";
    begin
        // [SCENARIO 316414] Deleting Payment Slip doesn't lead to empty "Applies-to ID" of wrong Vendor Ledger Entry, when entries suggested without summarization.
        Initialize();

        // [GIVEN] Vendors "C1", "C2".
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);
        // [GIVEN] Gen. Jnl. Lines "G1", "G2".
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor[1]."No.", GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(10, 2), WorkDate());
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor[2]."No.", GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(10, 2), WorkDate());

        // [GIVEN] Payment class with No. Series.
        PaymentClass.Get(CreatePaymentClass(PaymentClass.Suggestions::Vendor));
        PaymentClass.Validate("Line No. Series", LibraryERM.CreateNoSeriesCode());
        PaymentClass.Modify(true);
        LibraryFRLocalization.CreatePaymentStatus(PaymentStatus, PaymentClass.Code);

        // [GIVEN] Payment Slips "P1", "P2".
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader[1]);
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader[2]);
        Commit();

        // [GIVEN] "P1" and "P2" suggested payment without summarization.
        SuggestVendorPaymentLines(Vendor[1]."No.", SummarizePer::" ", PaymentHeader[1]);
        SuggestVendorPaymentLines(Vendor[2]."No.", SummarizePer::" ", PaymentHeader[2]);
        PaymentLine.SetRange("No.", PaymentHeader[2]."No.");
        PaymentLine.FindFirst();
        VerifyLastNoUsedInNoSeries(PaymentClass."Line No. Series", PaymentLine."Document No."); // TFS 409091. Last No used is updated

        // [WHEN] Paymen Slip "P2" is deleted.
        PaymentHeader[2].Delete(true);

        // [THEN] "VLE1" still has "Applies-to ID", while "VLE2"'s "Applies-to ID" is empty.
        VendorLedgerEntry.SetRange("Vendor No.", Vendor[1]."No.");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Applies-to ID");

        VendorLedgerEntry.SetRange("Vendor No.", Vendor[2]."No.");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Applies-to ID", '');
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRRequestPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPaymentSlipAfterGettingDimError()
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        PaymentLine: Record "Payment Line";
        Vendor: Record Vendor;
        Currency: Record Currency;
        PaymentHeader: Record "Payment Header";
        PaymentSlip: TestPage "Payment Slip";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 408792] Stan can post payment slip from the second attempt after getting the dimension error

        Initialize();

        // [GIVEN] USD currency with "Realized Gains Acc." = "X"
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Realized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Modify(true);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 1, LibraryRandom.RandDecInDecimalRange(5, 10, 2));

        // [GIVEN] Department dimension is mandatory for G/L account "X"
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, Currency."Realized Gains Acc.", Dimension.Code, '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // [GIVEN] Post Purchase Invoice with Currency = "X" and Currency Factor = 0.01
        CreatePurchaseInvoiceWithCurrencyAndPost(Vendor, Currency, WorkDate());

        // [GIVEN] Payment slip with posted purchase invoiced
        CreatePaymentSlipForPurchInvApplication(PaymentHeader, Vendor, Currency);

        // [GIVEN] Currency factor is changed to 0.02 to make posting to realized gains acc.
        PaymentHeader.Validate("Currency Factor", PaymentHeader."Currency Factor" + 0.01);
        PaymentHeader.Modify(true);

        // [GIVEN] Get an error after posting the payment slip first time
        PaymentSlip.OpenEdit();
        PaymentSlip.FILTER.SetFilter("Payment Class", PaymentHeader."Payment Class");
        asserterror PaymentSlip.Post.Invoke();
        Assert.ExpectedError('Select a Dimension Value Code');

        // [GIVEN] Assign Department dimension for the payment slip
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        FindPaymentLine(PaymentLine, PaymentHeader."Payment Class", 0);
        PaymentLine.Validate(
          "Dimension Set ID", LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code));
        PaymentLine.Modify(true);

        // [WHEN] Post second time
        PaymentSlip.Post.Invoke();

        // [THEN] Payment slip has been posted
        PaymentHeader.Find();
        PaymentHeader.TestField("Status No.");
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPaymentsFRSummarizedRequestPageHandlerVendor,ConfirmHandlerTrue')]
    procedure NoSeriesShouldNotCauseIssueWithPaymentSlipWhenPosting()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        PaymentClass: Record "Payment Class";
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        PaymentStepLedger: Record "Payment Step Ledger";
        Vendor: array[2] of Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        SuggestVendorPaymentsFR: Report "Suggest Vendor Payments FR";
        PaymentSlip: TestPage "Payment Slip";
    begin
        // [FEATURE] [Payment Slip]
        // [SCENARIO 539689] No. Series should not cause issue when posting Payment Slip.
        Initialize();

        // [GIVEN] Create two Vendors.
        LibraryPurchase.CreateVendor(Vendor[1]);
        LibraryPurchase.CreateVendor(Vendor[2]);

        // [GIVEN] Create and Post two General Journals.
        CreateAndPostGeneralJournal(
            GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor[1]."No.",
            GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(10, 2), WorkDate());
        CreateAndPostGeneralJournal(
            GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor[2]."No.",
            GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(10, 2), WorkDate());

        // [GIVEN] Create Payment Class, Payment Slip Ledger.
        PaymentClass.Get(SetupForPaymentSlipPost(PaymentStepLedger."Detail Level"::Account, PaymentClass.Suggestions::Vendor));

        // [GIVEN] Modify Document No. in Payment Step Ledger.
        PaymentStepLedger.SetRange("Payment Class", PaymentClass.Code);
        PaymentStepLedger.ModifyAll("Document No.", PaymentStepLedger."Document No."::"Document ID Line");

        // [GIVEN] Store Payment Class Code.
        LibraryVariableStorage.Enqueue(PaymentClass.Code);

        // [GIVEN] Validate No. Series in Payment Class.
        PaymentClass.Validate("Line No. Series", LibraryERM.CreateNoSeriesCode());
        PaymentClass.Modify(true);

        // [GIVEN] Create Payment Header.
        CreatePaymentHeader(PaymentHeader);
        Commit();

        // [GIVEN] Run Suggest Vendor Payments FR Report. 
        SuggestVendorPaymentsFR.SetGenPayLine(PaymentHeader);
        SuggestVendorPaymentsFR.RunModal();

        // [GIVEN] Find the first Payment Line.
        PaymentLine.SetRange("No.", PaymentHeader."No.");
        PaymentLine.FindFirst();

        // [GIVEN] Open and Post Payment Slip.
        PaymentSlip.OpenEdit();
        PaymentSlip.FILTER.SetFilter("No.", PaymentHeader."No.");
        PaymentSlip.Post.Invoke();

        //[GIVEN] Find the Vendor Posting Group.
        VendorPostingGroup.Get(Vendor[1]."Vendor Posting Group");

        // [THEN] Payment Slip must be posted and Amount must match in GL Entry.
        GLEntry.SetRange("Document No.", PaymentLine."Document No.");
        GLEntry.SetRange("G/L Account No.", VendorPostingGroup."Payables Account");
        GLEntry.FindFirst();
        Assert.AreEqual(PaymentLine.Amount, Abs(GLEntry.Amount), PaymentSlipErr);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,SuggestVendorPmtsFRRequestPageHandler')]
    procedure AppliesToIDIsNotFilledIfNoPaymentLineIsCreatedBySugVendPmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentClass: Record "Payment Class";
        PaymentStatus: Record "Payment Status";
        PaymentHeader: Record "Payment Header";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SuggestVendorPaymentsFR: Report "Suggest Vendor Payments FR";
    begin
        // [SCENARIO 558277] Suggest Vendor Payment Summarize per Vendor doesn't fill 
        // Applies-to ID of Vendor Ledger Entries if no Payment Line in the Payment Slip.
        Initialize();

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Gen. Journal Line.
        CreateGenJournalLine(
            GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", GenJournalLine."Document Type"::Payment,
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [GIVEN] Validate Debit Amount in Gen. Journal Line.
        GenJournalLine.Validate("Debit Amount", LibraryRandom.RandIntInRange(100, 100));
        GenJournalLine.Modify(true);

        // [GIVEN] Post Gen. Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create a Gen. Journal Line.
        CreateGenJournalLine(
            GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [GIVEN] Validate Credit Amount in Gen. Journal Line.
        GenJournalLine.Validate("Credit Amount", LibraryRandom.RandIntInRange(100, 100));
        GenJournalLine.Modify(true);

        // [GIVEN] Post Gen. Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create a Payment Class.
        CreatePaymentClassWithNoSeries(PaymentClass);

        // [GIVEN] Create a Payment Status.
        LibraryFRLocalization.CreatePaymentStatus(PaymentStatus, PaymentClass.Code);

        // [GIVEN] Create a Payment Header.
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LibraryVariableStorage.Enqueue(Format(Vendor."No."));
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader);
        Commit();

        // [GIVEN] Run Suggest Vendor Payments FR Report.
        SuggestVendorPaymentsFR.SetGenPayLine(PaymentHeader);
        SuggestVendorPaymentsFR.RunModal();

        // [WHEN] Find Vendor Ledger Entry.
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindFirst();

        // [THEN] Applies-to ID must be blank in Vendor Ledger Entry.
        Assert.AreEqual('', VendorLedgerEntry."Applies-to ID", AppliesToIDMustBeBlankErr);

        // [WHEN] Find Vendor Ledger Entry.
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindLast();

        // [THEN] Applies-to ID must be blank in Vendor Ledger Entry.
        Assert.AreEqual('', VendorLedgerEntry."Applies-to ID", AppliesToIDMustBeBlankErr);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,ApplyCustomerEntriesModalPageHandler')]
    procedure NoSeriesUpdatedWhenInsertPaylineManually()
    var
        PaymentClass: Record "Payment Class";
        PaymentStepLedger: Record "Payment Step Ledger";
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentLine: Record "Payment Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        NoSeriesLine: Record "No. Series Line";
        PaymentSlip: TestPage "Payment Slip";
        PaymentHeaderNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO 561809]Last No. Used in No. Series line incremented when the Payment Slip lines are entered manually
        Initialize();

        // [GIVEN] Payment Slip Setup with Line No. series defined (<> Header No. Series)
        PaymentClass.Get(
          SetupForPaymentSlipPost(PaymentStepLedger."Detail Level"::Account, PaymentClass.Suggestions::Customer));
        PaymentClass.Validate("Line No. Series", LibraryERM.CreateNoSeriesCode());
        PaymentClass.Modify(true);

        // [GIVEN] Posted Sales Invoice
        CustomerNo := CreateAndPostSalesInvoice(VATPostingSetup."Unrealized VAT Type"::" ");
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesInvoiceHeader.FindFirst();

        // [GIVEN] Payment Slip with Payment Line with Document No. = "Y"
        PaymentHeaderNo := CreatePaymentSlip(PaymentLine."Account Type"::Customer, CustomerNo);

        // [GIVEN] Open the Payment Slip and enqueue the values for handler
        OpenPaymentSlip(PaymentSlip, PaymentHeaderNo);
        EnqueueValuesForHandler(EnqueueOpt::Application, SalesInvoiceHeader."Amount Including VAT");

        // [WHEN] Payment Line applied to Customer Ledger Entry of Posted Sales Invoice
        PaymentSlipApplication(PaymentSlip);

        // [THEN] Customer Ledger Entry value of Applies-to ID = "Y"
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, SalesInvoiceHeader."No.");
        PaymentLine.SetRange("No.", PaymentHeaderNo);
        PaymentLine.FindFirst();

        // [THEN] Find the Line No. Series line
        FindNoSeriesLine(NoSeriesLine, PaymentClass."Line No. Series");

        // [THEN] Verify the No. Series Line Last No. used updated
        Assert.AreEqual(PaymentLine."Document No.", NoSeriesLine."Last No. Used", StrSubstNo(DocumentNoErr, PaymentLine."Document No."));
    end;

    [Test]
    [HandlerFunctions('PaymentClassListModalPageHandler,ApplyVendorEntriesModalPageHandlerWithCancel')]
    procedure DueDateOnPaymentSlipShouldNotClearUponClosingApplyVendorLedgerEntriesPages()
    var
        PaymentClass: Record "Payment Class";
        PaymentStepLedger: Record "Payment Step Ledger";
        PaymentLine: Record "Payment Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        PaymentSlip: TestPage "Payment Slip";
        PaymentSlipSubform: TestPage "Payment Slip Subform";
        DueDate: Date;
        PaymentHeaderNo: Code[20];
        VendorNo: Code[20];
    begin
        // [SCENARIO 562947] Due Date on Payment Slip Line clears upon closing the Apply Vendor Entries page in the French version.
        Initialize();

        // [GIVEN] Payment Slip Setup with Line No. series defined (<> Header No. Series)
        PaymentClass.Get(
          SetupForPaymentSlipPost(PaymentStepLedger."Detail Level"::Account, PaymentClass.Suggestions::Vendor));
        PaymentClass.Validate("Line No. Series", LibraryERM.CreateNoSeriesCode());
        PaymentClass.Modify(true);

        // [GIVEN] Posted Purchase Invoice
        PurchInvHeader.Get(
          CreateAndPostPurchaseInvoice(VATPostingSetup."Unrealized VAT Type"::" ", VendorNo));

        // [GIVEN] Payment Slip with Payment Line with Document No. = "Y"
        PaymentHeaderNo := CreatePaymentSlip(PaymentLine."Account Type"::Vendor, VendorNo);
        OpenPaymentSlip(PaymentSlip, PaymentHeaderNo);

        // [THEN] Set Due Date to Blank on Payment Slip Subform
        FindPaymentLine(PaymentSlipSubform, PaymentHeaderNo);
        DueDate := PaymentSlipSubform."Due Date".AsDate();
        PaymentSlipSubform."Due Date".SetValue(0D);
        PaymentSlipSubform.Close();

        // [WHEN] Payment Line applied to Vendor Ledger Entry of Posted Purchase Invoice
        LibraryVariableStorage.Enqueue(EnqueueOpt::Application);
        PaymentSlipApplication(PaymentSlip);

        // [THEN] Verify Due Date not Blank on Payment Slip Subform
        FindPaymentLine(PaymentSlipSubform, PaymentHeaderNo);
        PaymentSlipSubform."Due Date".AssertEquals(DueDate);
        PaymentSlipSubform.Close();

        // [WHEN] Payment Line not applied to Vendor Ledger Entry of Posted Purchase Invoice
        LibraryVariableStorage.Enqueue(EnqueueOpt::" ");
        PaymentSlipApplication(PaymentSlip);

        // [THEN] Verify Due Date not Blank on Payment Slip Subform
        FindPaymentLine(PaymentSlipSubform, PaymentHeaderNo);
        PaymentSlipSubform."Due Date".AssertEquals(DueDate);
        PaymentSlipSubform.Close();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Payment Management");
        UpdateUnrealizedVATGeneralLedgerSetup();
        LibraryVariableStorage.Clear();
        ClearPaymentSlipData();
    end;

    local procedure ApplyPaymentSlip(PaymentClass: Text[30])
    var
        PaymentSlip: TestPage "Payment Slip";
    begin
        PaymentSlip.OpenEdit();
        PaymentSlip.FILTER.SetFilter("Payment Class", PaymentClass);
        LibraryVariableStorage.Enqueue(EnqueueOpt::Application);
        PaymentSlip.Lines.Application.Invoke();  // Invokes ApplyVendorEntriesModalPageHandler and ApplyCustomerEntriesModalPageHandler.
        PaymentSlip.Close();
    end;

    local procedure CalcPaymentTermDiscount(PaymentTermsCode: Code[10]; CalcPmtDiscOnCrMemos: Boolean; Amount: Decimal): Decimal
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(PaymentTermsCode);
        PaymentTerms.Validate("Discount %", LibraryRandom.RandDec(50, 2));  // Using Random Dec for Discount %.
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", CalcPmtDiscOnCrMemos);
        PaymentTerms.Modify(true);
        exit(Round(Amount * (PaymentTerms."Discount %" / 100), LibraryERM.GetAmountRoundingPrecision()));
    end;

    local procedure CreateAndPostGeneralJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; DueDate: Date)
    begin
        CreateGenJournalLine(
          GenJournalLine, AccountType, AccountNo, DocumentType,
          GenJournalLine."Bal. Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo());
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Validate("Due Date", DueDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostNoApplyPaymentSlip(var PaymentHeaderNo: Code[20]; PaymentClass: Text[30]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        PaymentLine: Record "Payment Line";
    begin
        CreatePaymentSlip(AccountType, AccountNo);
        PaymentLine.SetFilter("Account Type", Format(AccountType));
        PaymentLine.SetFilter("Account No.", AccountNo);
        PaymentLine.FindFirst();
        PaymentHeaderNo := PaymentLine."No.";
        PostPaymentSlip(PaymentClass);
    end;

    local procedure CreateAndPostPaymentSlip(PaymentClass: Text[30]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    begin
        CreatePaymentSlip(AccountType, AccountNo);
        ApplyPaymentSlip(PaymentClass);
        PostPaymentSlip(PaymentClass);
    end;

    local procedure CreateAndPostPurchaseInvoice(UnrealizedVATType: Option; var VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVatPostingSetup(VATPostingSetup, UnrealizedVATType);
        CreatePurchaseHeaderWithLine(PurchaseHeader, VATPostingSetup);
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithMixedVATPostingSetup(UnrealizedVATType: Option; var VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        CreateVatPostingSetup(VATPostingSetup[1], UnrealizedVATType);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup[2], VATPostingSetup[1]."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup[2].Validate("Unrealized VAT Type", VATPostingSetup[2]."Unrealized VAT Type"::" ");
        VATPostingSetup[2].Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup[2].Modify(true);

        CreatePurchaseHeaderWithLine(PurchaseHeader, VATPostingSetup[1]);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup[2], GLAccount."Gen. Posting Type"::Purchase),
          LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoice(UnrealizedVATType: Option): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVatPostingSetup(VATPostingSetup, UnrealizedVATType);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerWithVATBusPostingGroup(
            VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));  // Use random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));  // Use random value for Unit Price.
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesHeader."Sell-to Customer No.");
    end;

    local procedure PostSalesOrderWithDimensions(var DimSetID: Integer; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code);
        SalesHeader.Validate("Dimension Set ID", DimSetID);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchaseOrderWithDimensions(var DimSetID: Integer; VendorNo: Code[20]): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        DimensionValue: Record "Dimension Value";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code);
        PurchHeader.Validate("Dimension Set ID", DimSetID);
        PurchHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
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

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo,
          LibraryRandom.RandDec(10, 2));  // Taken random Amount.
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePaymentClass(Suggestions: Option): Text[30]
    var
        PaymentClass: Record "Payment Class";
    begin
        LibraryFRLocalization.CreatePaymentClass(PaymentClass);
        PaymentClass.Validate("Header No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        PaymentClass.Validate("Unrealized VAT Reversal", PaymentClass."Unrealized VAT Reversal"::Delayed);
        PaymentClass.Validate(Suggestions, Suggestions);
        PaymentClass.Modify(true);
        exit(PaymentClass.Code);
    end;

    local procedure CreatePaymentHeader(var PaymentHeader: Record "Payment Header")
    begin
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader);
        PaymentHeader.Validate("Account No.", LibraryERM.CreateBankAccountNo());
        PaymentHeader.Modify(true);
    end;

    local procedure CreatePaymentSlip(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]): Code[20]
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
    begin
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader);
        LibraryFRLocalization.CreatePaymentLine(PaymentLine, PaymentHeader."No.");
        PaymentLine.Validate("Account Type", AccountType);
        PaymentLine.Validate("Account No.", AccountNo);
        PaymentLine.Modify(true);
        exit(PaymentHeader."No.");
    end;

    local procedure CreatePaymentSlipBySuggest(Suggestion: Option) PaymentClassCode: Text[30]
    var
        PaymentStatus: Record "Payment Status";
        PaymentHeader: Record "Payment Header";
    begin
        PaymentClassCode := CreatePaymentClass(Suggestion);
        CreatePaymentStatus(PaymentStatus, PaymentClassCode, PaymentClassNameTxt, false);  // Using False for Payment In Progress.
        LibraryVariableStorage.Enqueue(PaymentClassCode);  // Enqueue value for PaymentClassListModalPageHandler.
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader);
        Commit();  // Required for execute report.
    end;

    local procedure CreatePaymentSlipAndSuggestCustomerPayment(CustomerNo: Code[20]; CustomerNo2: Code[20]; DueDate: Date; SummarizePer: Option) PaymentClassCode: Text[30]
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentClass: Record "Payment Class";
        PaymentSlip: TestPage "Payment Slip";
    begin
        PaymentClassCode :=
          SetupForPaymentOnPaymentSlip(
            GenJournalLine."Account Type"::Customer, CustomerNo, CustomerNo2,
            LibraryRandom.RandDec(10, 2), PaymentClass.Suggestions::Customer, DueDate);
        PaymentSlip.OpenEdit();
        PaymentSlip.FILTER.SetFilter("Payment Class", PaymentClassCode);
        LibraryVariableStorage.Enqueue(StrSubstNo(FilterRangeTxt, CustomerNo, CustomerNo2));
        LibraryVariableStorage.Enqueue(SummarizePer);

        // Exercise.
        PaymentSlip.SuggestCustomerPayments.Invoke();
    end;

    local procedure CreatePaymentSlipWithDiscount(var PaymentSlip: TestPage "Payment Slip")
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        PaymentClass: Record "Payment Class";
        PaymentHeader: Record "Payment Header";
        PaymentStatus: Record "Payment Status";
        Amount: Decimal;
        DiscountAmount: Decimal;
    begin
        // Setup: Create Customer, update Payment Terms, create and post Sales Invoice from Gen Journal Line.
        Amount := LibraryRandom.RandDecInRange(100, 200, 2);  // Using Random Dec In Range for Amount.
        Customer.Get(CreateCustomer(''));  // Using blank for Currency.
        DiscountAmount := CalcPaymentTermDiscount(Customer."Payment Terms Code", false, Amount);  // Using False for Calc. Pmt. Disc. on Cr. Memos field.
        CreateAndPostGeneralJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        CreatePaymentStatus(PaymentStatus, CreatePaymentClass(PaymentClass.Suggestions::Customer), PaymentClassNameTxt, false);  // Using False for Payment In Progress
        LibraryVariableStorage.Enqueue(PaymentStatus."Payment Class");  // Enqueue value for PaymentClassListModalPageHandler.
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader);
        Commit();  // Required for execute report.
        OpenPaymentSlip(PaymentSlip, PaymentHeader."No.");
        EnqueueValuesForHandler(Customer."No.", '');  // Enqueue for SuggestCustomerPaymentsFRRequestPageHandler.
        PaymentSlip.SuggestCustomerPayments.Invoke();
        EnqueueValuesForHandler(EnqueueOpt::Verification, (Amount - DiscountAmount));  // Enqueue for ApplyCustomerEntriesModalPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Document Type"::Invoice);  // Enqueue for ApplyCustomerEntriesModalPageHandler.
    end;

    local procedure CreatePaymentStatus(var PaymentStatus: Record "Payment Status"; PaymentClass: Text[30]; Name: Text[50]; PaymentInProgress: Boolean)
    begin
        LibraryFRLocalization.CreatePaymentStatus(PaymentStatus, PaymentClass);
        PaymentStatus.Validate(Name, Name);
        PaymentStatus.Validate("Payment in Progress", PaymentInProgress);
        PaymentStatus.Modify(true);
    end;

    local procedure CreatePaymentStatusWithOptions(var PaymentStatus: Record "Payment Status"; PaymentClass: Text[30]; RIB: Boolean; Look: Boolean; ReportMenu: Boolean; Amount: Boolean; Debit: Boolean; Credit: Boolean; BankAccount: Boolean; PaymentInProgress: Boolean; AcceptationCode: Boolean)
    begin
        CreatePaymentStatus(PaymentStatus, PaymentClass, LibraryUtility.GenerateGUID(), PaymentInProgress);
        PaymentStatus.Validate(RIB, RIB);
        PaymentStatus.Validate(Look, Look);
        PaymentStatus.Validate(ReportMenu, ReportMenu);
        PaymentStatus.Validate(Amount, Amount);
        PaymentStatus.Validate(Debit, Debit);
        PaymentStatus.Validate(Credit, Credit);
        PaymentStatus.Validate("Bank Account", BankAccount);
        PaymentStatus.Validate("Acceptation Code", AcceptationCode);
        PaymentStatus.Modify(true);
    end;

    local procedure CreatePaymentStep(PaymentClass: Text[30]; Name: Text[50]; PreviousStatus: Integer; NextStatus: Integer; ActionType: Enum "Payment Step Action Type"; RealizeVAT: Boolean): Integer
    var
        PaymentStep: Record "Payment Step";
        NoSeries: Record "No. Series";
    begin
        NoSeries.FindFirst();
        LibraryFRLocalization.CreatePaymentStep(PaymentStep, PaymentClass);
        PaymentStep.Validate(Name, Name);
        PaymentStep.Validate("Previous Status", PreviousStatus);
        PaymentStep.Validate("Next Status", NextStatus);
        PaymentStep.Validate("Action Type", ActionType);
        PaymentStep.Validate("Source Code", CreateSourceCode());
        PaymentStep.Validate("Header Nos. Series", NoSeries.Code);
        PaymentStep.Validate("Realize VAT", RealizeVAT);
        PaymentStep.Modify(true);
        exit(PaymentStep.Line);
    end;

    local procedure CreatePaymentStepLedger(var PaymentStepLedger: Record "Payment Step Ledger"; PaymentClass: Text[30]; Sign: Option; AccountingType: Option; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Application: Option; LineNo: Integer)
    begin
        LibraryFRLocalization.CreatePaymentStepLedger(PaymentStepLedger, PaymentClass, Sign, LineNo);
        PaymentStepLedger.Validate(Description, PaymentClass);
        PaymentStepLedger.Validate("Accounting Type", AccountingType);
        PaymentStepLedger.Validate("Account Type", AccountType);
        PaymentStepLedger.Validate("Account No.", AccountNo);
        PaymentStepLedger.Validate(Application, Application);
        PaymentStepLedger.Modify(true);
    end;

    local procedure CreatePaymentStepLedgerWithDocumentType(var PaymentStepLedger: Record "Payment Step Ledger"; PaymentClass: Text[30]; Sign: Option; AccountingType: Option; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Application: Option; LineNo: Integer; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CreatePaymentStepLedger(
          PaymentStepLedger, PaymentClass, Sign,
          AccountingType, AccountType, AccountNo, Application, LineNo);
        PaymentStepLedger.Validate("Document Type", DocumentType);
        PaymentStepLedger.Modify(true);
    end;

    local procedure CreatePaymentSlipSetupWithDelayedVATRealize(var PaymentClassCode: Text[30]; var LineNo: array[3] of Integer)
    var
        PaymentClass: Record "Payment Class";
    begin
        PaymentClassCode := CreatePaymentClass(PaymentClass.Suggestions::Vendor);
        LibraryVariableStorage.Enqueue(PaymentClassCode);
        CreateSetupForPaymentSlipWithDelayedVATRealize(LineNo, PaymentClassCode);
        CreatePaymentStepLedgerForVendorWithMemorizeVATRealize(PaymentClassCode, LineNo);
    end;

    local procedure CreatePaymentSlipWithSourceCodeAndAccountNo(SourceCode: Code[10]; AccountNo: Code[20]; PaymentClassCode: Code[30]; LineNo: Integer): Code[20]
    var
        PaymentHeader: Record "Payment Header";
    begin
        LibraryFRLocalization.CreatePaymentSlip();
        FindPaymentHeader(PaymentHeader, PaymentClassCode, LineNo);
        PaymentHeader.Validate("Source Code", SourceCode);
        PaymentHeader.Validate("Account No.", AccountNo);
        PaymentHeader.Modify(true);
        PostPaymentSlipHeaderNo(PaymentHeader."No.");
        exit(PaymentHeader."No.");
    end;

    local procedure CreatePaymentSlipForPurchInvApplication(var PaymentHeader: Record "Payment Header"; Vendor: Record Vendor; Currency: Record Currency)
    var
        PaymentClass: Record "Payment Class";
        PaymentStepLedger: Record "Payment Step Ledger";
        PaymentSlip: TestPage "Payment Slip";
    begin
        PaymentClass.Get(SetupForPmtSlipAppliedToPurchInv(PaymentStepLedger."Detail Level"::Account));
        CreatePaymentHeader(PaymentHeader);
        PaymentHeader.Validate("Currency Code", Currency.Code);
        PaymentHeader.Modify(true);

        OpenPaymentSlip(PaymentSlip, PaymentHeader."No.");
        EnqueueValuesForHandler(Vendor."No.", Currency.Code);  // Enqueue for SuggestVendorPaymentsFRRequestPageHandler.
        Commit();
        PaymentSlip.SuggestVendorPayments.Invoke();
    end;

    local procedure CreateSetupForPaymentSlip(var LineNo: Integer; PaymentClass: Text[30]; PaymentInProgress: Boolean) LineNo2: Integer
    var
        PaymentStatus: Record "Payment Status";
        PaymentStatus2: Record "Payment Status";
        PaymentStatus3: Record "Payment Status";
        PaymentStatus4: Record "Payment Status";
        PaymentStep: Record "Payment Step";
    begin
        // Hardcoded values required for Payment Class setup due to avoid Import Parameter setup through automation.
        CreatePaymentStatus(PaymentStatus, PaymentClass, 'New Document In Creation', PaymentInProgress);
        CreatePaymentStatus(PaymentStatus2, PaymentClass, 'Document Created', PaymentInProgress);
        CreatePaymentStatus(PaymentStatus3, PaymentClass, 'Payment In Creation', PaymentInProgress);
        CreatePaymentStatus(PaymentStatus4, PaymentClass, 'Payment Created', PaymentInProgress);

        // Create Payment Step.
        LineNo :=
          CreatePaymentStep(
            PaymentClass, 'Step1: Creation of documents', PaymentStatus.Line, PaymentStatus2.Line, PaymentStep."Action Type"::Ledger, false);  // FALSE for Realize VAT.
        CreatePaymentStep(
          PaymentClass, 'Step2: Documents created', PaymentStatus2.Line, PaymentStatus3.Line,
          PaymentStep."Action Type"::"Create New Document", false);  // FALSE for Realize VAT.
        LineNo2 :=
          CreatePaymentStep(
            PaymentClass, 'Step3: Creation of payment', PaymentStatus3.Line, PaymentStatus4.Line,
            PaymentStep."Action Type"::Ledger, true);  // TRUE for Realize VAT.
    end;

    local procedure CreateSetupForPaymentSlipWithDelayedVATRealize(var LineNo: array[3] of Integer; PaymentClass: Text[30])
    var
        PaymentStatus: array[5] of Record "Payment Status";
        PaymentStep: Record "Payment Step";
        LineNoDel: Integer;
    begin
        CreatePaymentStatusWithOptions(PaymentStatus[1], PaymentClass, true, true, false, false, true, false, true, false, true);
        CreatePaymentStatusWithOptions(PaymentStatus[2], PaymentClass, true, true, true, false, true, false, true, true, true);
        CreatePaymentStatusWithOptions(PaymentStatus[3], PaymentClass, false, false, false, false, true, false, false, false, false);
        CreatePaymentStatusWithOptions(PaymentStatus[4], PaymentClass, true, true, true, false, true, false, true, true, false);
        CreatePaymentStatusWithOptions(PaymentStatus[5], PaymentClass, false, false, true, false, true, false, false, false, false);

        // Step1: Creation of documents
        LineNoDel :=
          CreatePaymentStep(
            PaymentClass, LibraryUtility.GenerateGUID(), PaymentStatus[1].Line,
            PaymentStatus[2].Line, PaymentStep."Action Type"::Ledger, false);

        LineNo[1] :=
          CreatePaymentStep(
            PaymentClass, LibraryUtility.GenerateGUID(), PaymentStatus[1].Line,
            PaymentStatus[2].Line, PaymentStep."Action Type"::Ledger, false);

        PaymentStep.Get(PaymentClass, LineNoDel);
        PaymentStep.Delete();

        // Step2: Documents created
        LineNo[2] :=
          CreatePaymentStep(
            PaymentClass, LibraryUtility.GenerateGUID(), PaymentStatus[2].Line, PaymentStatus[4].Line,
            PaymentStep."Action Type"::"Create New Document", false);

        // Step3: Creation of payment
        LineNo[3] :=
          CreatePaymentStep(
            PaymentClass, LibraryUtility.GenerateGUID(), PaymentStatus[4].Line, PaymentStatus[5].Line,
            PaymentStep."Action Type"::Ledger, true);  // TRUE for Realize VAT.
    end;

    local procedure CreatePaymentStepLedgerForCustomer(PaymentClass: Text[30]; LineNo: Integer; LineNo2: Integer)
    var
        PaymentStepLedger: Record "Payment Step Ledger";
        PaymentStepLedger2: Record "Payment Step Ledger";
        PaymentStepLedger3: Record "Payment Step Ledger";
        PaymentStepLedger4: Record "Payment Step Ledger";
    begin
        // Create Payment Step Ledger for Customer.
        CreatePaymentStepLedger(
          PaymentStepLedger, PaymentClass, PaymentStepLedger.Sign::Debit, PaymentStepLedger."Accounting Type"::"Associated G/L Account",
          PaymentStepLedger."Account Type"::"G/L Account", '', PaymentStepLedger.Application::None, LineNo);  // Blank value for G/L Account No.
        CreatePaymentStepLedger(
          PaymentStepLedger2, PaymentClass, PaymentStepLedger.Sign::Credit, PaymentStepLedger."Accounting Type"::"Payment Line Account",
          PaymentStepLedger."Account Type"::"G/L Account", '', PaymentStepLedger.Application::"Applied Entry", LineNo);  // Blank value for G/L Account No.
        CreatePaymentStepLedger(
          PaymentStepLedger3, PaymentClass, PaymentStepLedger.Sign::Debit, PaymentStepLedger."Accounting Type"::"Setup Account",
          PaymentStepLedger."Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo(), PaymentStepLedger.Application::None, LineNo2);
        CreatePaymentStepLedger(
          PaymentStepLedger4, PaymentClass, PaymentStepLedger.Sign::Credit, PaymentStepLedger."Accounting Type"::"Setup Account",
          PaymentStepLedger."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), PaymentStepLedger.Application::None, LineNo2);
    end;

    local procedure CreatePaymentStepLedgerForVendor(PaymentClass: Text[30]; LineNo: Integer; LineNo2: Integer)
    var
        PaymentStepLedger: Record "Payment Step Ledger";
        PaymentStepLedger2: Record "Payment Step Ledger";
        PaymentStepLedger3: Record "Payment Step Ledger";
        PaymentStepLedger4: Record "Payment Step Ledger";
    begin
        // Create Payment Step Ledger for Vendor.
        CreatePaymentStepLedger(
          PaymentStepLedger, PaymentClass, PaymentStepLedger.Sign::Debit, PaymentStepLedger."Accounting Type"::"Payment Line Account",
          PaymentStepLedger."Account Type"::"G/L Account", '', PaymentStepLedger.Application::"Applied Entry", LineNo);  // Blank value for G/L Account No.
        CreatePaymentStepLedger(
          PaymentStepLedger2, PaymentClass, PaymentStepLedger.Sign::Credit, PaymentStepLedger."Accounting Type"::"Associated G/L Account",
          PaymentStepLedger."Account Type"::"G/L Account", '', PaymentStepLedger.Application::None, LineNo);  // Blank value for G/L Account No.
        CreatePaymentStepLedger(
          PaymentStepLedger3, PaymentClass, PaymentStepLedger.Sign::Debit, PaymentStepLedger."Accounting Type"::"Setup Account",
          PaymentStepLedger."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), PaymentStepLedger.Application::None, LineNo2);
        CreatePaymentStepLedger(
          PaymentStepLedger4, PaymentClass, PaymentStepLedger.Sign::Credit, PaymentStepLedger."Accounting Type"::"Setup Account",
          PaymentStepLedger."Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo(), PaymentStepLedger.Application::None, LineNo2);
    end;

    local procedure CreatePaymentStepLedgerForVendorWithMemorizeVATRealize(PaymentClass: Text[30]; LineNo: array[3] of Integer)
    var
        PaymentStepLedger: array[4] of Record "Payment Step Ledger";
    begin
        CreatePaymentStepLedgerWithDocumentType(
          PaymentStepLedger[1], PaymentClass, PaymentStepLedger[1].Sign::Debit,
          PaymentStepLedger[1]."Accounting Type"::"Payment Line Account", PaymentStepLedger[1]."Account Type"::"G/L Account",
          '', PaymentStepLedger[1].Application::"Applied Entry", LineNo[1], PaymentStepLedger[1]."Document Type"::Payment);

        CreatePaymentStepLedgerWithDocumentType(
          PaymentStepLedger[2], PaymentClass, PaymentStepLedger[2].Sign::Credit,
          PaymentStepLedger[2]."Accounting Type"::"Payment Line Account", PaymentStepLedger[2]."Account Type"::"G/L Account",
          '', PaymentStepLedger[2].Application::None, LineNo[1], PaymentStepLedger[2]."Document Type"::" ");
        PaymentStepLedger[2].Validate("Memorize Entry", true);
        PaymentStepLedger[2].Modify(true);

        CreatePaymentStepLedgerWithDocumentType(
          PaymentStepLedger[3], PaymentClass, PaymentStepLedger[3].Sign::Debit,
          PaymentStepLedger[3]."Accounting Type"::"Payment Line Account", PaymentStepLedger[3]."Account Type"::"G/L Account",
          '', PaymentStepLedger[3].Application::"Memorized Entry", LineNo[3], PaymentStepLedger[3]."Document Type"::Payment);

        CreatePaymentStepLedgerWithDocumentType(
          PaymentStepLedger[4], PaymentClass, PaymentStepLedger[4].Sign::Credit,
          PaymentStepLedger[4]."Accounting Type"::"Header Payment Account", PaymentStepLedger[4]."Account Type"::"G/L Account",
          '', PaymentStepLedger[4].Application::None, LineNo[3], PaymentStepLedger[4]."Document Type"::Payment);
    end;

    local procedure CreateSourceCode(): Code[10]
    var
        SourceCode: Record "Source Code";
    begin
        LibraryERM.CreateSourceCode(SourceCode);
        exit(SourceCode.Code);
    end;

    local procedure CreateSuggestAndPostPaymentSlip(VendorNo: Code[20])
    var
        PaymentHeader: Record "Payment Header";
    begin
        CreatePaymentHeader(PaymentHeader);
        Commit();
        SuggestVendorPaymentLines(VendorNo, '', PaymentHeader);
        PostPaymentSlipHeaderNo(PaymentHeader."No.");
    end;

    local procedure CreateVatPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(10));
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVendor(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePaymentClassWithSetup(Suggestions: Option) PaymentClassCode: Text[30]
    var
        PaymentStatus: Record "Payment Status";
        PaymentStatus2: Record "Payment Status";
        PaymentStep: Record "Payment Step";
        PaymentStepLedger: Record "Payment Step Ledger";
        LineNo: Integer;
    begin
        PaymentClassCode := CreatePaymentClass(Suggestions);

        // Hardcoded values required for Payment Class setup due to avoid Import Parameter setup through automation.
        CreatePaymentStatus(PaymentStatus, PaymentClassCode, 'In Progress', false);
        CreatePaymentStatus(PaymentStatus2, PaymentClassCode, 'Posted', false);

        // Create Payment Step.
        LineNo := CreatePaymentStep(
            PaymentClassCode, 'Posting', PaymentStatus.Line, PaymentStatus2.Line, PaymentStep."Action Type"::Ledger, false);

        CreatePaymentStepLedger(
          PaymentStepLedger, PaymentClassCode, PaymentStepLedger.Sign::Credit,
          PaymentStepLedger."Accounting Type"::"Header Payment Account",
          PaymentStepLedger."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), PaymentStepLedger.Application::None, LineNo);
        PaymentStepLedger.Validate("Detail Level", PaymentStepLedger."Detail Level"::Account);
        PaymentStepLedger.Modify();
    end;

    local procedure CreatePostSlipAppliedToSalesInvoice(var PaymentHeaderNo: Code[20])
    var
        PaymentHeader: Record "Payment Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentSlip: TestPage "Payment Slip";
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateAndPostSalesInvoice(VATPostingSetup."Unrealized VAT Type"::" ");
        CreatePaymentHeader(PaymentHeader);
        PaymentHeaderNo := PaymentHeader."No.";

        Commit();
        OpenPaymentSlip(PaymentSlip, PaymentHeaderNo);
        EnqueueValuesForHandler(CustomerNo, '');
        PaymentSlip.SuggestCustomerPayments.Invoke();

        PaymentSlip.Post.Invoke();
    end;

    local procedure CreatePostSlipAppliedToPurchaseInvoice(var PaymentHeaderNo: Code[20])
    var
        PaymentHeader: Record "Payment Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentSlip: TestPage "Payment Slip";
        VendorNo: Code[20];
    begin
        CreateAndPostPurchaseInvoice(VATPostingSetup."Unrealized VAT Type"::" ", VendorNo);
        CreatePaymentHeader(PaymentHeader);
        PaymentHeaderNo := PaymentHeader."No.";

        Commit();
        OpenPaymentSlip(PaymentSlip, PaymentHeaderNo);
        EnqueueValuesForHandler(VendorNo, '');
        PaymentSlip.SuggestVendorPayments.Invoke();

        PaymentSlip.Post.Invoke();
    end;

    local procedure CreatePurchaseHeaderWithLine(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorWithVATBusPostingGroup(
            VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase),
          LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVendorPaymentSlip(VendorNo: array[2] of Code[20]; SummarizePer: Option " ",Vendor,"Due date")
    var
        PaymentSlip: TestPage "Payment Slip";
        SuggestionsOption: Option "None",Customer,Vendor;
    begin
        CreatePaymentSlipBySuggest(SuggestionsOption::Vendor);
        OpenPaymentSlip(PaymentSlip, '');

        EnqueueValuesForHandler(StrSubstNo('%1|%2', VendorNo[1], VendorNo[2]), SummarizePer);
        PaymentSlip.SuggestVendorPayments.Invoke();
    end;

    local procedure CreateCustomerPaymentSlip(CustomerNo: array[2] of Code[20]; SummarizePer: Option " ",Customer,"Due date")
    var
        PaymentSlip: TestPage "Payment Slip";
        SuggestionsOption: Option "None",Customer,Vendor;
    begin
        CreatePaymentSlipBySuggest(SuggestionsOption::Customer);
        OpenPaymentSlip(PaymentSlip, '');

        EnqueueValuesForHandler(StrSubstNo('%1|%2', CustomerNo[1], CustomerNo[2]), SummarizePer);
        PaymentSlip.SuggestCustomerPayments.Invoke();
    end;

    local procedure CreateCustomerWithDefaultDimensionsPostSalesOrder(var CustomerNo: Code[20]; var DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
        PostSalesOrder(CustomerNo);
    end;

    local procedure CreateVendorWithDefaultDimensionsPostPurchaseOrder(var VendorNo: Code[20]; var DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, VendorNo, DimensionValue."Dimension Code", DimensionValue.Code);
        PostPurchaseOrder(VendorNo);
    end;

    local procedure CreateCurrencyWithDifferentExchangeRate(var Currency: Record Currency; var PostingDate: Date; var RateFactorY: Decimal)
    var
        RateFactorX: Decimal;
    begin
        PostingDate := WorkDate() - 1;
        LibraryERM.CreateCurrency(Currency);
        RateFactorX := LibraryRandom.RandDecInDecimalRange(1, 5, 2);
        RateFactorY := LibraryRandom.RandDecInDecimalRange(6, 10, 2);
        LibraryERM.CreateExchangeRate(Currency.Code, PostingDate, RateFactorX, RateFactorX);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), RateFactorY, RateFactorY);
    end;

    local procedure CreatePaymentSlipWithCurrency(var PaymentHeader: Record "Payment Header"; Vendor: Record Vendor; Currency: Record Currency)
    var
        PaymentClass: Record "Payment Class";
        PaymentStepLedger: Record "Payment Step Ledger";
        PaymentSlip: TestPage "Payment Slip";
    begin
        PaymentClass.Get(
          SetupForPaymentSlipPost(
            PaymentStepLedger."Detail Level"::Account, PaymentClass.Suggestions::Vendor)); // Enqueue value for PaymentClassListModalPageHandler.
        CreatePaymentHeader(PaymentHeader);
        PaymentHeader.Validate("Currency Code", Currency.Code);
        PaymentHeader.Modify(true);

        OpenPaymentSlip(PaymentSlip, PaymentHeader."No.");
        EnqueueValuesForHandler(Vendor."No.", Currency.Code);  // Enqueue for SuggestVendorPaymentsFRRequestPageHandler.
        Commit(); // Required for execute report.
        PaymentSlip.SuggestVendorPayments.Invoke();
    end;

    local procedure CreatePurchaseInvoiceWithCurrencyAndPost(var Vendor: Record Vendor; Currency: Record Currency; PostingDate: Date): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccount: Record "G/L Account";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        Item: Record Item;
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusinessPostingGroup.Code));

        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");

        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        GLAccount.Get(VendorPostingGroup."Invoice Rounding Account");
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        VATPostingSetup."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup.Modify();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Currency Code", Currency.Code);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.",
          LibraryRandom.RandDec(10, 2)); // Use random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));  // Use random value for Unit Price.
        PurchaseLine.Modify(true);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure EnqueueValuesForHandler(Value: Variant; Value2: Variant)
    begin
        LibraryVariableStorage.Enqueue(Value);
        LibraryVariableStorage.Enqueue(Value2);
    end;

    local procedure FindAndDeletePaymentLine(No: Code[20])
    var
        PaymentLine: Record "Payment Line";
    begin
        PaymentLine.SetRange("No.", No);
        PaymentLine.FindFirst();
        PaymentLine.Delete(true);
    end;

    local procedure VerifyVATEntryBaseAndAmount(PaymentHeaderNo: Code[20]; BaseValue: Decimal; AmountValue: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, PaymentHeaderNo);
        VATEntry.TestField(Base, BaseValue);
        VATEntry.TestField(Amount, AmountValue);
    end;

    local procedure VerifyVendorLedgerEntriesClosed(VendorNo: Code[20]; "Count": Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange(Open, false);
        Assert.RecordCount(VendorLedgerEntry, Count);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PaymentSlipPageCloseHandler(var PaymentSlip: TestPage "Payment Slip")
    begin
        PaymentSlip.Close();
    end;

    local procedure PaymentSlipApplication(PaymentSlip: TestPage "Payment Slip")
    begin
        PaymentSlip.Lines.First();
        PaymentSlip.Lines.Application.Invoke();
    end;

    local procedure PostGenJournalAndCreatePaymentSlip(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Suggestions: Option; Amount: Decimal): Text[30]
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentClass: Record "Payment Class";
        PaymentStatus: Record "Payment Status";
    begin
        CreateAndPostGeneralJournal(GenJournalLine, AccountType, AccountNo, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        CreateAndPostGeneralJournal(
          GenJournalLine, AccountType, AccountNo, GenJournalLine."Document Type"::"Credit Memo", -Amount / 2, WorkDate());  // Required less amount to invoice.
        PaymentClass.Get(CreatePaymentClass(Suggestions));
        CreatePaymentStatus(PaymentStatus, PaymentClass.Code, PaymentClassNameTxt, false);  // Using False for Payment In Progress.
        exit(PaymentClass.Code);
    end;

    local procedure PostPaymentSlip(PaymentClass: Text[30])
    var
        PaymentSlip: TestPage "Payment Slip";
    begin
        PaymentSlip.OpenEdit();
        PaymentSlip.FILTER.SetFilter("Payment Class", PaymentClass);
        PaymentSlip.Post.Invoke();  // Invoke ConfirmHandlerTrue.
    end;

    local procedure PostPaymentSlipHeaderNo(HeaderNo: Code[20])
    var
        PaymentSlip: TestPage "Payment Slip";
    begin
        PaymentSlip.OpenEdit();
        PaymentSlip.GotoKey(HeaderNo);
        PaymentSlip.Post.Invoke();
    end;

    local procedure PostPaymentSlipAndVerifyLedgers(PaymentHeader: Record "Payment Header"; NoOfRecord: Integer)
    begin
        // Exercise.
        PostPaymentSlipHeaderNo(PaymentHeader."No.");
        // Verify: Verify Debit Amount on Bank Account Ledger and General Ledger and number of records.
        PaymentHeader.CalcFields("Amount (LCY)");
        VerifyBankAccountLedgerEntry(PaymentHeader, NoOfRecord);
        VerifyGenLedgerEntry(PaymentHeader, NoOfRecord);
    end;

    local procedure PostSalesOrder(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchaseOrder(VendorNo: Code[20]): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure SetupForPaymentSlipPost(DetailLevel: Option; Suggestions: Option): Text[30]
    var
        PaymentStatus: Record "Payment Status";
        PaymentStatus2: Record "Payment Status";
        PaymentStep: Record "Payment Step";
        PaymentStepLedger: Record "Payment Step Ledger";
        PaymentStepLedger2: Record "Payment Step Ledger";
        PaymentClass: Text[30];
        LineNo: Integer;
    begin
        PaymentClass := CreatePaymentClass(Suggestions);
        CreatePaymentStatus(PaymentStatus, PaymentClass, PaymentClassNameTxt, false);  // Using False for Payment In Progress.
        CreatePaymentStatus(PaymentStatus2, PaymentClass, 'Post', false);  // Using False for Payment In Progress.
        LineNo :=
          CreatePaymentStep(PaymentClass, 'Step1: Post', PaymentStatus.Line, PaymentStatus2.Line, PaymentStep."Action Type"::Ledger, false);  // FALSE for Realize VAT.
        CreatePaymentStepLedger(
          PaymentStepLedger, PaymentClass, PaymentStepLedger.Sign::Debit, PaymentStepLedger."Accounting Type"::"Header Payment Account",
          PaymentStepLedger."Account Type"::"G/L Account", '', PaymentStepLedger.Application::None, LineNo);  // Blank value for G/L Account No.
        PaymentStepLedger.Validate("Detail Level", DetailLevel);
        PaymentStepLedger.Modify(true);
        CreatePaymentStepLedger(
          PaymentStepLedger2, PaymentClass, PaymentStepLedger2.Sign::Credit, PaymentStepLedger2."Accounting Type"::"Payment Line Account",
          PaymentStepLedger2."Account Type"::"G/L Account", '', PaymentStepLedger2.Application::"Applied Entry", LineNo);  // Blank value for G/L Account No.
        LibraryVariableStorage.Enqueue(PaymentClass);
        exit(PaymentClass);
    end;

    local procedure SetupForPmtSlipAppliedToPurchInv(DetailLevel: Option): Text[30]
    var
        PaymentStatus: Record "Payment Status";
        PaymentStatus2: Record "Payment Status";
        PaymentStep: Record "Payment Step";
        PaymentStepLedger: Record "Payment Step Ledger";
        PaymentStepLedger2: Record "Payment Step Ledger";
        DummyPaymentClass: Record "Payment Class";
        PaymentClass: Text[30];
        LineNo: Integer;
    begin
        PaymentClass := CreatePaymentClass(DummyPaymentClass.Suggestions::Vendor);
        CreatePaymentStatus(PaymentStatus, PaymentClass, PaymentClassNameTxt, false);
        CreatePaymentStatus(PaymentStatus2, PaymentClass, LibraryUtility.GenerateGUID(), false);
        LineNo :=
          CreatePaymentStep(PaymentClass, LibraryUtility.GenerateGUID(),
          PaymentStatus.Line, PaymentStatus2.Line, PaymentStep."Action Type"::Ledger, false);
        CreatePaymentStepLedger(
          PaymentStepLedger2, PaymentClass, PaymentStepLedger2.Sign::Debit, PaymentStepLedger2."Accounting Type"::"Payment Line Account",
          PaymentStepLedger2."Account Type"::"G/L Account", '', PaymentStepLedger2.Application::"Applied Entry", LineNo);
        CreatePaymentStepLedger(
          PaymentStepLedger, PaymentClass, PaymentStepLedger.Sign::Credit, PaymentStepLedger."Accounting Type"::"Header Payment Account",
          PaymentStepLedger."Account Type"::"G/L Account", '', PaymentStepLedger.Application::None, LineNo);
        PaymentStepLedger.Validate("Detail Level", DetailLevel);
        PaymentStepLedger.Modify(true);
        LibraryVariableStorage.Enqueue(PaymentClass);
        exit(PaymentClass);
    end;

    local procedure SetupForPaymentOnPaymentSlip(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AccountNo2: Code[20]; Amount: Decimal; Suggestion: Option; DueDate: Date) PaymentClassCode: Text[30]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostGeneralJournal(GenJournalLine, AccountType, AccountNo, GenJournalLine."Document Type"::Invoice, Amount, DueDate);
        CreateAndPostGeneralJournal(GenJournalLine, AccountType, AccountNo2, GenJournalLine."Document Type"::Invoice, Amount, WorkDate());
        PaymentClassCode := CreatePaymentSlipBySuggest(Suggestion);
    end;

    local procedure SuggestCustomerPaymentLines(Value: Variant; Value2: Variant; PaymentHeader: Record "Payment Header")
    var
        SuggestCustomerPayments: Report "Suggest Customer Payments";
    begin
        EnqueueValuesForHandler(Value, Value2);
        SuggestCustomerPayments.SetGenPayLine(PaymentHeader);
        SuggestCustomerPayments.RunModal();
    end;

    local procedure SuggestVendorPaymentLines(Value: Variant; Value2: Variant; PaymentHeader: Record "Payment Header")
    var
        SuggestVendorPaymentsFR: Report "Suggest Vendor Payments FR";
    begin
        EnqueueValuesForHandler(Value, Value2);
        SuggestVendorPaymentsFR.SetGenPayLine(PaymentHeader);
        SuggestVendorPaymentsFR.RunModal();
    end;

    local procedure OpenPaymentSlip(var PaymentSlip: TestPage "Payment Slip"; No: Text[50])
    begin
        PaymentSlip.OpenEdit();
        PaymentSlip.FILTER.SetFilter("No.", No);
    end;

    local procedure UnrealizedVATTypeError()
    begin
        // Excerise.
        asserterror LibraryFRLocalization.CreatePaymentSlip();  // Invoke CreatePaymentSlipStrMenuHandler.

        // Verify: Verify error.
        Assert.ExpectedError(UnrealizedVATTypeErr);
    end;

    local procedure UpdateUnrealizedVATGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unrealized VAT", true);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePaymentStepLedgerMemorizeEntry(PaymentClassCode: Text[30]; MemorizeEntry: Boolean)
    var
        PaymentStepLedger: Record "Payment Step Ledger";
    begin
        PaymentStepLedger.SetRange("Payment Class", PaymentClassCode);
        PaymentStepLedger.ModifyAll("Memorize Entry", MemorizeEntry);
    end;

    local procedure VerifyBankAccountLedgerEntry(PaymentHeader: Record "Payment Header"; NoOfRecord: Integer)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAmount: Decimal;
    begin
        BankAccountLedgerEntry.SetRange("Document No.", PaymentHeader."No.");
        BankAccountLedgerEntry.FindSet();
        repeat
            BankAmount += BankAccountLedgerEntry."Debit Amount";
        until BankAccountLedgerEntry.Next() = 0;
        Assert.AreEqual(Abs(PaymentHeader."Amount (LCY)"), BankAmount, UnexpectedErr);
        Assert.AreEqual(BankAccountLedgerEntry.Count, NoOfRecord, UnexpectedErr);
    end;

    local procedure VerifyGenLedgerEntry(PaymentHeader: Record "Payment Header"; NoOfRecord: Integer)
    var
        GLEntry: Record "G/L Entry";
        GLAmount: Decimal;
    begin
        GLEntry.SetRange("Document No.", PaymentHeader."No.");
        GLEntry.SetFilter("Debit Amount", '<>%1', 0);
        GLEntry.FindSet();
        repeat
            GLAmount += GLEntry."Debit Amount";
        until GLEntry.Next() = 0;
        Assert.AreEqual(Abs(PaymentHeader."Amount (LCY)"), GLAmount, UnexpectedErr);
        Assert.AreEqual(GLEntry.Count, NoOfRecord, UnexpectedErr);
    end;

    local procedure ClearPaymentSlipData()
    var
        PaymentClass: Record "Payment Class";
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
    begin
        PaymentClass.DeleteAll();
        PaymentHeader.DeleteAll();
        PaymentLine.DeleteAll();
    end;

    local procedure CreatePaymentOfLinesFromPostedPaymentSlip(var PaymentClassCode: Text[30]; var LineNo: Integer)
    var
        PaymentClass: Record "Payment Class";
        PaymentLine: Record "Payment Line";
    begin
        PaymentClass.Get(CreatePaymentClass(PaymentClass.Suggestions::None));
        PaymentClassCode := PaymentClass.Code;
        CreateSetupForPaymentSlip(LineNo, PaymentClassCode, false);

        LibraryVariableStorage.Enqueue(PaymentClassCode); // Enqueue value for PaymentClassListModalPageHandler.
        CreatePaymentSlip(PaymentLine."Account Type"::Customer, CreateCustomer(''));
        PostPaymentSlip(PaymentClassCode);

        LibraryVariableStorage.Enqueue(PaymentClassCode); // Enqueue value for PaymentSlipRemovePageHandler
        LibraryVariableStorage.Enqueue(LineNo);           // Enqueue value for PaymentSlipRemovePageHandler
        LibraryFRLocalization.CreatePaymentSlip();
    end;

    local procedure CreatePaymentSlipWithCustomerPayments(CustomerNo: Code[20]; PaymentClassCode: Text[30])
    var
        PaymentLine: Record "Payment Line";
        PaymentSlip: TestPage "Payment Slip";
    begin
        SetupPaymentSlip(PaymentClassCode, PaymentLine."Account Type"::Customer, CustomerNo);

        Commit();
        PaymentSlip.OpenEdit();
        PaymentSlip.FILTER.SetFilter("Payment Class", PaymentClassCode);
        PaymentSlip.SuggestCustomerPayments.Invoke();
    end;

    local procedure CreatePaymentSlipWithVendorPayments(VendorNo: Code[20]; PaymentClassCode: Text[30])
    var
        PaymentLine: Record "Payment Line";
        PaymentSlip: TestPage "Payment Slip";
    begin
        SetupPaymentSlip(PaymentClassCode, PaymentLine."Account Type"::Vendor, VendorNo);

        Commit();
        PaymentSlip.OpenEdit();
        PaymentSlip.FILTER.SetFilter("Payment Class", PaymentClassCode);
        PaymentSlip.SuggestVendorPayments.Invoke();
    end;

    local procedure SetPaymentHeaderBankAccountNo(PaymentClassCode: Text[30])
    var
        PaymentHeader: Record "Payment Header";
    begin
        PaymentHeader.SetRange("Payment Class", PaymentClassCode);
        PaymentHeader.FindFirst();
        PaymentHeader.Validate("Account No.", LibraryERM.CreateBankAccountNo());
        PaymentHeader.Modify();
    end;

    local procedure SetupPaymentSlip(PaymentClassCode: Text[30]; AccountType: Enum "Gen. Journal Account Type"; CustomerVendorNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(PaymentClassCode);  // Enqueue value for PaymentClassListModalPageHandler.
        CreatePaymentSlip(AccountType, CustomerVendorNo);

        SetPaymentHeaderBankAccountNo(PaymentClassCode);

        LibraryVariableStorage.Enqueue(CustomerVendorNo);
        LibraryVariableStorage.Enqueue(false);
    end;

    local procedure FindPaymentStep(var PaymentStep: Record "Payment Step"; PaymentClass: Text[30]; LineNo: Integer)
    begin
        PaymentStep.SetRange("Payment Class", PaymentClass);
        PaymentStep.SetRange("Previous Status", LineNo);
        PaymentStep.FindFirst();
    end;

    local procedure FindPaymentHeader(var PaymentHeader: Record "Payment Header"; PaymentClass: Text[30]; LineNo: Integer)
    begin
        PaymentHeader.SetRange("Payment Class", PaymentClass);
        PaymentHeader.SetRange("Status No.", LineNo);
        PaymentHeader.FindFirst();
    end;

    local procedure FindPaymentLine(var PaymentLine: Record "Payment Line"; PaymentClass: Text[30]; LineNo: Integer)
    begin
        PaymentLine.SetRange("Payment Class", PaymentClass);
        if LineNo <> 0 then
            PaymentLine.SetRange("Status No.", LineNo);
        PaymentLine.FindFirst();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
    end;

    local procedure GetLastDebitGLEntryNo(PaymentHeaderNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", PaymentHeaderNo);
        GLEntry.SetRange("Credit Amount", 0);
        GLEntry.FindLast();
        exit(GLEntry."Entry No.");
    end;

    local procedure GetLastCreditGLEntryNo(PaymentHeaderNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", PaymentHeaderNo);
        GLEntry.SetRange("Debit Amount", 0);
        GLEntry.FindLast();
        exit(GLEntry."Entry No.");
    end;

    local procedure VerifyCopyLinkInPaymentLine(PaymentClass: Text[30]; LineNo: Integer)
    var
        SourcePaymentLine: Record "Payment Line";
        PaymentLine: Record "Payment Line";
    begin
        FindPaymentLine(SourcePaymentLine, PaymentClass, LineNo);

        Assert.IsTrue(
          PaymentLine.Get(SourcePaymentLine."Copied To No.", SourcePaymentLine."Copied To Line"),
          StrSubstNo(PaymentLineIsNotCopiedErr, SourcePaymentLine."No."));
        Assert.IsTrue(
          PaymentLine.IsCopy,
          StrSubstNo(ValueIsIncorrectErr, PaymentLine.IsCopy, SourcePaymentLine.FieldCaption(IsCopy)));
        Assert.AreEqual(
          SourcePaymentLine."Account Type", PaymentLine."Account Type",
          StrSubstNo(ValueIsIncorrectErr, PaymentLine."Account Type", SourcePaymentLine.FieldCaption("Account Type")));
        Assert.AreEqual(
          SourcePaymentLine."Account No.", PaymentLine."Account No.",
          StrSubstNo(ValueIsIncorrectErr, PaymentLine."Account No.", SourcePaymentLine.FieldCaption("Account No.")));
    end;

    local procedure VerifyPostingError(PaymentClassCode: Text[30])
    var
        PaymentHeader: Record "Payment Header";
        PaymentStep: Record "Payment Step";
        PaymentManagement: Codeunit "Payment Management";
    begin
        PaymentStep.SetRange("Payment Class", PaymentClassCode);
        PaymentStep.FindLast();
        PaymentStep.SetRecFilter();

        PaymentHeader.SetRange("Payment Class", PaymentClassCode);
        PaymentHeader.FindFirst();

        asserterror PaymentManagement.ProcessPaymentSteps(PaymentHeader, PaymentStep);
        Assert.ExpectedError(StepLedgerGetErr);

        Clear(PaymentManagement);
        asserterror PaymentManagement.ProcessPaymentSteps(PaymentHeader, PaymentStep);
        Assert.ExpectedError(StepLedgerGetErr);
    end;

    local procedure VerifyPaymentLineDebitCreditGLNo(PaymentHeaderNo: Code[20]; PaymentClassCode: Text[30])
    var
        PaymentLine: Record "Payment Line";
        LastDebitGLEntryNo: Integer;
        LastCreditGLEntryNo: Integer;
    begin
        LastDebitGLEntryNo := GetLastDebitGLEntryNo(PaymentHeaderNo);
        LastCreditGLEntryNo := GetLastCreditGLEntryNo(PaymentHeaderNo);
        FindPaymentLine(PaymentLine, PaymentClassCode, 0);
        Assert.AreEqual(LastDebitGLEntryNo, PaymentLine."Entry No. Debit", PaymentLine.FieldCaption("Entry No. Debit"));
        Assert.AreEqual(LastDebitGLEntryNo, PaymentLine."Entry No. Debit Memo", PaymentLine.FieldCaption("Entry No. Debit Memo"));
        Assert.AreEqual(LastCreditGLEntryNo, PaymentLine."Entry No. Credit", PaymentLine.FieldCaption("Entry No. Credit"));
        Assert.AreEqual(LastCreditGLEntryNo, PaymentLine."Entry No. Credit Memo", PaymentLine.FieldCaption("Entry No. Credit Memo"));
    end;

    local procedure VerifyPaymentLineDimSetID(DimSetID: Integer; AppliestoDocNo: Code[20])
    var
        PaymentLine: Record "Payment Line";
    begin
        PaymentLine.SetRange("Applies-to Doc. No.", AppliestoDocNo);
        PaymentLine.FindFirst();
        PaymentLine.TestField("Dimension Set ID", DimSetID);
    end;

    local procedure VerifyRealizedVAT(PurchInvHeaderNo: Code[20]; PaymentHeaderNo: Code[20])
    var
        VATEntryInvoice: Record "VAT Entry";
    begin
        FindVATEntry(VATEntryInvoice, PurchInvHeaderNo);
        VATEntryInvoice.TestField("Remaining Unrealized Amount", 0);
        VATEntryInvoice.TestField("Remaining Unrealized Base", 0);
        VATEntryInvoice.Next();
        VATEntryInvoice.TestField("Remaining Unrealized Amount", 0);
        VATEntryInvoice.TestField("Remaining Unrealized Base", 0);

        VerifyVATEntryBaseAndAmount(
          PaymentHeaderNo, VATEntryInvoice."Unrealized Base", VATEntryInvoice."Unrealized Amount");
    end;

    local procedure VerifyPaymentLineDimensionValue(AccountType: Option; AccountNo: Code[20]; DimensionValue: Record "Dimension Value")
    var
        PaymentLine: Record "Payment Line";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionManagement: Codeunit DimensionManagement;
    begin
        PaymentLine.SetRange("Account Type", AccountType);
        PaymentLine.SetRange("Account No.", AccountNo);
        PaymentLine.FindFirst();
        DimensionManagement.GetDimensionSet(TempDimSetEntry, PaymentLine."Dimension Set ID");
        TempDimSetEntry.SetRange("Dimension Code", DimensionValue."Dimension Code");
        TempDimSetEntry.SetRange("Dimension Value Code", DimensionValue.Code);
        Assert.RecordIsNotEmpty(TempDimSetEntry);
    end;

    local procedure VerifyPaymentLineCurrencyFactor(var PaymentHeader: Record "Payment Header"; RateFactor: Decimal)
    var
        PaymentLine: Record "Payment Line";
    begin
        PaymentLine.SetRange("No.", PaymentHeader."No.");
        PaymentLine.FindFirst();
        PaymentLine.TestField("Currency Factor", RateFactor);
    end;

    local procedure VerifyLastNoUsedInNoSeries(NoSeriesCode: Code[20]; LastNoUsed: Code[20])
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.FindFirst();
        NoSeriesLine.TestField("Last No. Used", LastNoUsed);
    end;

    local procedure CreatePaymentClassWithNoSeries(var PaymentClass: Record "Payment Class")
    begin
        LibraryFRLocalization.CreatePaymentClass(PaymentClass);
        PaymentClass.Validate("Header No. Series", LibraryERM.CreateNoSeriesCode());
        PaymentClass.Validate("Line No. Series", LibraryERM.CreateNoSeriesCode());
        PaymentClass.Validate(Suggestions, PaymentClass.Suggestions::Vendor);
        PaymentClass.Validate("Unrealized VAT Reversal", PaymentClass."Unrealized VAT Reversal"::Application);
        PaymentClass.Validate("SEPA Transfer Type", PaymentClass."SEPA Transfer Type"::"Credit Transfer");
        PaymentClass.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        AppliedAmount: Variant;
        DocumentType: Variant;
        OptionValue: Variant;
        OptionString: Option " ",Application,Verification;
        EnqueueOption: Option;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);
        EnqueueOption := OptionValue;
        case EnqueueOption of
            OptionString::Application:
                ApplyCustomerEntries."Set Applies-to ID".Invoke();
            OptionString::Verification:
                begin
                    LibraryVariableStorage.Dequeue(AppliedAmount);
                    LibraryVariableStorage.Dequeue(DocumentType);
                    ApplyCustomerEntries.AppliedAmount.AssertEquals(AppliedAmount); // Applied Amount
                    ApplyCustomerEntries."Document Type".AssertEquals(DocumentType);
                end;
        end;
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AppliedAmount: Variant;
        OptionValue: Variant;
        OptionString: Option " ",Application,Verification;
        EnqueueOption: Option;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);
        EnqueueOption := OptionValue;
        case EnqueueOption of
            OptionString::Application:
                ApplyVendorEntries.ActionSetAppliesToID.Invoke();
            OptionString::Verification:
                begin
                    LibraryVariableStorage.Dequeue(AppliedAmount);
                    ApplyVendorEntries.AppliedAmount.AssertEquals(AppliedAmount); // Applied Amount
                    ApplyVendorEntries.Last();
                    ApplyVendorEntries."Document Type".AssertEquals(Format(VendorLedgerEntry."Document Type"::"Credit Memo"));
                end;
        end;
        ApplyVendorEntries.OK().Invoke();
    end;

    local procedure FindNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NoSeriesCode: Code[20])
    begin
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.FindFirst();
    end;

    local procedure FindPaymentLine(var PaymentSlipSubform: TestPage "Payment Slip Subform"; PaymentHeaderNo: Code[20])
    var
        PaymentLine: Record "Payment Line";
    begin
        PaymentLine.SetRange("No.", PaymentHeaderNo);
        PaymentLine.FindFirst();
        PaymentSlipSubform.OpenEdit();
        PaymentSlipSubform.GotoRecord(PaymentLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesModalPageHandlerWithCancel(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        OptionValue: Variant;
        OptionString: Option " ",Application,Verification;
        EnqueueOption: Option;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);
        EnqueueOption := OptionValue;
        case EnqueueOption of
            OptionString::Application:
                begin
                    ApplyVendorEntries.ActionSetAppliesToID.Invoke();
                    ApplyVendorEntries.OK().Invoke();
                end;
            OptionString::" ":
                ApplyVendorEntries.Cancel().Invoke();
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentClassListModalPageHandler(var PaymentClassList: TestPage "Payment Class List")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        PaymentClassList.FILTER.SetFilter(Code, Code);
        PaymentClassList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentLinesListModalPageHandler(var PaymentLinesList: TestPage "Payment Lines List")
    begin
        PaymentLinesList.OK().Invoke();  // Invokes PaymentSlipPageHandler.
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CreatePaymentSlipStrMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;  // Invokes PaymentLinesListModalPageHandler.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLCustLedgerReconciliationRequestPageHandler(var GLCustLedgerReconciliation: TestRequestPage "GL/Cust. Ledger Reconciliation")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        GLCustLedgerReconciliation.Customer.SetFilter("No.", No);
        GLCustLedgerReconciliation.Customer.SetFilter("Date Filter", Format(WorkDate()));
        GLCustLedgerReconciliation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLVendLedgerReconciliationRequestPageHandler(var GLVendLedgerReconciliation: TestRequestPage "GL/Vend. Ledger Reconciliation")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        GLVendLedgerReconciliation.Vendor.SetFilter("No.", No);
        GLVendLedgerReconciliation.Vendor.SetFilter("Date Filter", Format(WorkDate()));
        GLVendLedgerReconciliation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestCustomerPaymentsRequestPageHandler(var SuggestCustomerPayments: TestRequestPage "Suggest Customer Payments")
    var
        CurrencyFilter: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(CurrencyFilter);
        SuggestCustomerPayments.Customer.SetFilter("No.", No);
        SuggestCustomerPayments.LastPaymentDate.SetValue(CalcDate('<1M>', WorkDate()));  // Required month end date.
        SuggestCustomerPayments.CurrencyFilter.SetValue(CurrencyFilter);
        SuggestCustomerPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestCustomerPaymentsSummarizedRequestPageHandler(var SuggestCustomerPayments: TestRequestPage "Suggest Customer Payments")
    var
        No: Variant;
        SummarizePer: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(SummarizePer);
        SuggestCustomerPayments.LastPaymentDate.SetValue(WorkDate());
        SuggestCustomerPayments.SummarizePer.SetValue(SummarizePer);
        SuggestCustomerPayments.Customer.SetFilter("No.", No);
        SuggestCustomerPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsFRRequestPageHandler(var SuggestVendorPaymentsFR: TestRequestPage "Suggest Vendor Payments FR")
    var
        CurrencyFilter: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(CurrencyFilter);
        SuggestVendorPaymentsFR.Vendor.SetFilter("No.", No);
        SuggestVendorPaymentsFR.LastPaymentDate.SetValue(CalcDate('<1M>', WorkDate()));  // Required month end date.
        SuggestVendorPaymentsFR.CurrencyFilter.SetValue(CurrencyFilter);
        SuggestVendorPaymentsFR.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PaymentSlipPageHandler(var PaymentSlip: TestPage "Payment Slip")
    begin
        PaymentSlip.Post.Invoke();  // Invokes ConfirmHandlerTrue.
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PaymentSlipRemovePageHandler(var PaymentSlip: TestPage "Payment Slip")
    var
        PaymentClass: Variant;
        LineNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PaymentClass);
        LibraryVariableStorage.Dequeue(LineNo);
        VerifyCopyLinkInPaymentLine(PaymentClass, LineNo);

        PaymentSlip.Lines.Remove.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsFRSummarizedRequestPageHandler(var SuggestVendorPaymentsFR: TestRequestPage "Suggest Vendor Payments FR")
    var
        No: Variant;
        SummarizePer: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(SummarizePer);
        SuggestVendorPaymentsFR.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPaymentsFR.SummarizePer.SetValue(SummarizePer);
        SuggestVendorPaymentsFR.Vendor.SetFilter("No.", No);
        SuggestVendorPaymentsFR.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsFRSummarizedRequestPageHandlerVendor(var SuggestVendorPaymentsFR: TestRequestPage "Suggest Vendor Payments FR")
    var
        SummarizePer: Option " ",Vendor,"Due date";
    begin
        SuggestVendorPaymentsFR.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPaymentsFR.SummarizePer.SetValue(SummarizePer::Vendor);
        SuggestVendorPaymentsFR.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPmtsFRRequestPageHandler(var SuggestVendorPaymentsFR: TestRequestPage "Suggest Vendor Payments FR")
    var
        SummarizePer: Option " ",Vendor,"Due date";
    begin
        SuggestVendorPaymentsFR.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPaymentsFR.SummarizePer.SetValue(SummarizePer::Vendor);
        SuggestVendorPaymentsFR.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestVendorPaymentsFR.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

