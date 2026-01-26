codeunit 144124 "ERM Service VAT EC Calculate"
{
    // // [FEATURE] [Service] [VAT] [EC]
    // 1.  Test to verify G/L entry and VAT entry after posting Service Invoice without Currency and Reverse Charge VAT.
    // 2.  Test to verify G/L entry and VAT entry after posting Service Invoice with Currency and Reverse Charge VAT.
    // 3.  Test to verify G/L entry and VAT entry after posting Service Credit Memo with Currency and Reverse Charge VAT.
    // 4.  Test to verify G/L entry and VAT entry after posting Service Credit Memo without Currency and Reverse Charge VAT.
    // 5.  Test to verify G/L entry and VAT entry after posting Service Invoice without Currency and Normal VAT.
    // 6.  Test to verify G/L entry and VAT entry after posting Service Credit Memo without Currency and Normal VAT.
    // 7.  Test to verify G/L entry and VAT entry after posting Service Invoice with Line Discount.
    // 8.  Test to verify G/L entry and VAT entry after posting Service Credit Memo with Line Discount.
    // 9.  Test to verify Amount on Service Invoice Statistics after posting Service Invoice without Currency and Normal VAT.
    // 10. Test to verify Amount on Service Credit Memo Statistics after posting Service Credit Memo without Currency and Normal VAT.
    // 11. Test to verify G/L entry after posting Service Credit Memo with Currency and Normal VAT.
    // 12. Test to verify G/L entry after posting Service Invoice with Currency and Normal VAT.
    //
    // Covers Test Cases for WI - 352251
    // ------------------------------------------------------------------------------------------
    // Test Function Name                                                                 TFS ID
    // ------------------------------------------------------------------------------------------
    // PostedServiceInvReverseChargeVATWithoutCurrency                                     284008
    // PostedServiceInvoiceReverseChargeVATWithCurrency                                    284007
    // PostedServiceCrMemoReverseChargeVATWithCurrency                                     284015
    // PostedServiceCrMemoReverseChargeVATWithoutCurrency                                  284016
    // PostedServiceInvoiceNormalVATWithoutCurrency                                        284006
    // PostedServiceCreditMemoNormalVATWithoutCurrency                                     284013
    //
    // Covers Test Cases for WI - 352348
    // ------------------------------------------------------------------------------------------
    // Test Function Name                                                                 TFS ID
    // ------------------------------------------------------------------------------------------
    // PostedServiceInvoiceWithLineDiscount                                                217456
    // PostedServiceCreditMemoWithLineDiscount                                             217457
    // ServiceInvoiceStatisticsWithNormalVAT                                               284009
    // ServiceCreditMemoStatisticsWithNormalVAT                                            284011
    // PostedServiceCreditMemoNormalVATWithCurrency                                        284012
    // PostedServiceInvoiceNormalVATWithCurrency                                           284003

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ValueMustBeEqualMsg: Label 'Value must be equal.';

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceInvReverseChargeVATWithoutCurrency()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Test to verify G/L entry and VAT entry after posting Service Invoice without Currency and Reverse Charge VAT.
        PostServiceDocumentAndVerifyGLVATEntry(
          ServiceHeader."Document Type"::Invoice, '', LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2), 0);  // Currency Code as blank. Take random Quantity and Unit Price. AdditionalCurrencyAmount as 0.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceReverseChargeVATWithCurrency()
    var
        ServiceHeader: Record "Service Header";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // Test to verify G/L entry and VAT entry after posting Service Invoice with Currency and Reverse Charge VAT.
        Quantity := LibraryRandom.RandInt(10);
        UnitPrice := LibraryRandom.RandInt(100);
        PostServiceDocumentAndVerifyGLVATEntry(
          ServiceHeader."Document Type"::Invoice, CreateCurrency(), Quantity, UnitPrice, -Quantity * UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceCrMemoReverseChargeVATWithCurrency()
    var
        ServiceHeader: Record "Service Header";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // Test to verify G/L entry and VAT entry after posting Service Credit Memo with Currency and Reverse Charge VAT.
        Quantity := LibraryRandom.RandInt(10);
        UnitPrice := LibraryRandom.RandInt(10);
        PostServiceDocumentAndVerifyGLVATEntry(
          ServiceHeader."Document Type"::"Credit Memo", CreateCurrency(), Quantity, UnitPrice, Quantity * UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceCrMemoReverseChargeVATWithoutCurrency()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Test to verify G/L entry and VAT entry after posting Service Credit Memo without Currency and Reverse Charge VAT.
        PostServiceDocumentAndVerifyGLVATEntry(
          ServiceHeader."Document Type"::"Credit Memo", '', LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2), 0);  // Currency Code as blank. Take random Quantity and Unit Price. Additional Currency Amount as 0.
    end;

    local procedure PostServiceDocumentAndVerifyGLVATEntry(DocumentType: Enum "Service Document Type"; CurrencyCode: Code[10]; Quantity: Decimal; UnitPrice: Decimal; AdditionalCurrencyAmount: Decimal)
    var
        ServiceLine: Record "Service Line";
        DocumentNo: Code[20];
        OldAdditionalReportingCurrency: Code[10];
        Amount: Decimal;
    begin
        // Setup: Create Service Credit Memo. Update Additional Reporting Currency on General Ledger Setup.
        OldAdditionalReportingCurrency := UpdateAdditionalReportingCurrOnGeneralLedgerSetup(CurrencyCode);
        CreateServiceDocumentAndUpdateGLAccount(
          ServiceLine, CurrencyCode, DocumentType, ServiceLine."VAT Calculation Type"::"Reverse Charge VAT",
          Quantity, UnitPrice);
        Amount := LibraryERM.ConvertCurrency(ServiceLine.Amount, CurrencyCode, '', WorkDate());  // To Currency as blank.

        // Exercise.
        PostServiceDocument(ServiceLine."Document No.", ServiceLine."Document Type");

        // Verify: Verify Amount, Additional Currency Base, VAT Amount and Additional Currency Amount on G/L Entry and VAT Entry.
        DocumentNo := FindPostedDocumentNo(DocumentType, ServiceLine."Customer No.");
        VerifyGLEntry(DocumentNo, ServiceLine."No.", FindServiceLineAmount(DocumentType, Amount), AdditionalCurrencyAmount);
        VerifyGLEntry(
          DocumentNo, GetReceivableAccount(ServiceLine."Customer No."), -FindServiceLineAmount(DocumentType, Amount),
          -AdditionalCurrencyAmount);
        VerifyVATEntry(DocumentNo, FindServiceLineAmount(DocumentType, Amount), 0, 0, AdditionalCurrencyAmount);  // Additional Currency Amount and Amount as 0.

        // Tear Down.
        UpdateAdditionalReportingCurrOnGeneralLedgerSetup(OldAdditionalReportingCurrency);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceNormalVATWithoutCurrency()
    var
        ServiceLine: Record "Service Line";
    begin
        // Test to verify G/L entry and VAT entry after posting Service Invoice without Currency and Normal VAT.
        PostServiceDocumentNormalVATWithoutCurrency(ServiceLine."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoNormalVATWithoutCurrency()
    var
        ServiceLine: Record "Service Line";
    begin
        // Test to verify G/L entry and VAT entry after posting Service Credit Memo without Currency and Normal VAT.
        PostServiceDocumentNormalVATWithoutCurrency(ServiceLine."Document Type"::"Credit Memo");
    end;

    local procedure PostServiceDocumentNormalVATWithoutCurrency(DocumentType: Enum "Service Document Type")
    var
        ServiceLine: Record "Service Line";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // Test to verify G/L entry and VAT entry after posting Service Credit Memo without Currency and Normal VAT.

        // Setup: Create and post Service Document.
        CreateServiceDocumentAndUpdateGLAccount(
          ServiceLine, '', DocumentType, ServiceLine."VAT Calculation Type"::"Normal VAT",
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));  // Take random Quantity and Unit Price. Currency as blank.
        VATAmount := ServiceLine.Amount * (ServiceLine."VAT %" + ServiceLine."EC %") / 100;

        // Exercise.
        PostServiceDocument(ServiceLine."Document No.", ServiceLine."Document Type");

        // Verify: Verify Amount, Additional Currency Base, VAT Amount and Additional Currency Amount on G/L Entry and VAT Entry.
        DocumentNo := FindPostedDocumentNo(DocumentType, ServiceLine."Customer No.");
        VerifyGLEntry(DocumentNo, ServiceLine."No.", FindServiceLineAmount(DocumentType, ServiceLine.Amount), 0);  // Additional Currency Amount as 0.
        VerifyGLEntry(
          DocumentNo, GetReceivableAccount(ServiceLine."Customer No."), -FindServiceLineAmount(
            DocumentType, ServiceLine.Amount + VATAmount), 0);  // Additional Currency Amount as 0.
        VerifyVATEntry(
          DocumentNo, FindServiceLineAmount(DocumentType, ServiceLine.Amount), FindServiceLineAmount(DocumentType, VATAmount), 0, 0);  // Additional Currency Amount and Additional Currency Base as 0.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceWithLineDiscount()
    var
        ServiceLine: Record "Service Line";
    begin
        // Test to verify G/L entry and VAT entry after posting Service Invoice with Line Discount.
        PostServiceDocumentWithLineDiscount(ServiceLine."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoWithLineDiscount()
    var
        ServiceLine: Record "Service Line";
    begin
        // Test to verify G/L entry and VAT entry after posting Service Credit Memo with Line Discount.
        PostServiceDocumentWithLineDiscount(ServiceLine."Document Type"::"Credit Memo");
    end;

    local procedure PostServiceDocumentWithLineDiscount(DocumentType: Enum "Service Document Type")
    var
        ServiceLine: Record "Service Line";
        DocumentNo: Code[20];
        OldPostLineDiscount: Boolean;
    begin
        // Test to verify G/L entry and VAT entry after posting Service Credit Memo with Line Discount.

        // Setup.
        OldPostLineDiscount := UpdateSalesReceivablesSetupPostLineDiscount(true);  // Post Line Discount as True.
        CreateServiceDocumentWithLineDiscount(ServiceLine, DocumentType);

        // Exercise.
        PostServiceDocument(ServiceLine."Document No.", ServiceLine."Document Type");

        // Verify: Verify Amount, Additional Currency Base, VAT Amount and Additional Currency Amount on G/L Entry and VAT Entry.
        DocumentNo := FindPostedDocumentNo(DocumentType, ServiceLine."Customer No.");
        VerifyGLEntry(DocumentNo, ServiceLine."No.", FindServiceLineAmount(DocumentType, ServiceLine."Line Discount Amount"), 0);  // Additional Currency Amount as 0.
        VerifyGLEntry(DocumentNo, GetReceivableAccount(ServiceLine."Customer No."), 0, 0);  // Additional Currency Amount and Additional Currency Base as 0.
        VerifyVATEntryTotal(DocumentNo, 0, 0, 0, 0);  // Amount, Base, Additional Currency Amount and Additional Currency Base as 0.

        // Tear Down.
        UpdateSalesReceivablesSetupPostLineDiscount(OldPostLineDiscount);
    end;
#if not CLEAN27
    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ServiceInvoiceStatisticsPageHandler')]
    procedure ServiceInvoiceStatisticsWithNormalVAT()
    var
        ServiceLine: Record "Service Line";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // Test to verify Amount on Service Invoice Statistics after posting Service Invoice without Currency and Normal VAT.

        // Setup: Create and post Service Invoice. Update Additional Reporting Currency on General Ledger Setup.
        CreateAndPostServiceDocument(ServiceLine, ServiceLine."Document Type"::Invoice);
        DocumentNo := FindServiceInvoiceHeader(ServiceLine."Customer No.");
        VATAmount := ServiceLine.Amount * (ServiceLine."VAT %" + ServiceLine."EC %") / 100;
        LibraryVariableStorage.Enqueue(ServiceLine.Amount);
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(ServiceLine.Amount + VATAmount);
        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.FILTER.SetFilter("No.", DocumentNo);

        // Exercise.
        PostedServiceInvoice.Statistics.Invoke();
        PostedServiceInvoice.Close();

        // Verify: Verify Amount, VAT Amount and Amount Including VAT on Service Invoice Statistics.
        // Verification in page handler ServiceInvoiceStatisticsPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ServiceCreditMemoStatisticsPageHandler')]
    procedure ServiceCreditMemoStatisticsWithNormalVAT()
    var
        ServiceLine: Record "Service Line";
        PostedServiceCreditMemos: TestPage "Posted Service Credit Memos";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // Test to verify Amount on Service Credit Memo Statistics after posting Service Credit Memo without Currency and Normal VAT.

        // Setup: Create and post Service Invoice. Open page Posted Service Credit Memos.
        CreateAndPostServiceDocument(ServiceLine, ServiceLine."Document Type"::"Credit Memo");
        DocumentNo := FindServiceCreditMemo(ServiceLine."Customer No.");
        VATAmount := ServiceLine.Amount * (ServiceLine."VAT %" + ServiceLine."EC %") / 100;
        LibraryVariableStorage.Enqueue(ServiceLine.Amount);
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(ServiceLine.Amount + VATAmount);
        PostedServiceCreditMemos.OpenView();
        PostedServiceCreditMemos.FILTER.SetFilter("No.", DocumentNo);

        // Exercise.
        PostedServiceCreditMemos.Statistics.Invoke();
        PostedServiceCreditMemos.Close();

        // Verify: Verify Amount, VAT Amount and Amount Including VAT on Service Credit Memo Statistics.
        // Verification in page handler ServiceCreditMemoStatisticsPageHandler
    end;
#endif
    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ServiceInvoiceStatisticsPageHandlerNM')]
    procedure ServiceInvoiceStatisticsWithNormalVATNM()
    var
        ServiceLine: Record "Service Line";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // Test to verify Amount on Service Invoice Statistics after posting Service Invoice without Currency and Normal VAT.

        // Setup: Create and post Service Invoice. Update Additional Reporting Currency on General Ledger Setup.
        CreateAndPostServiceDocument(ServiceLine, ServiceLine."Document Type"::Invoice);
        DocumentNo := FindServiceInvoiceHeader(ServiceLine."Customer No.");
        VATAmount := ServiceLine.Amount * (ServiceLine."VAT %" + ServiceLine."EC %") / 100;
        LibraryVariableStorage.Enqueue(ServiceLine.Amount);
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(ServiceLine.Amount + VATAmount);
        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.FILTER.SetFilter("No.", DocumentNo);

        // Exercise.
        PostedServiceInvoice.ServiceStatistics.Invoke();
        PostedServiceInvoice.Close();

        // Verify: Verify Amount, VAT Amount and Amount Including VAT on Service Invoice Statistics.
        // Verification in page handler ServiceInvoiceStatisticsPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ServiceCreditMemoStatisticsPageHandlerNM')]
    procedure ServiceCreditMemoStatisticsWithNormalVATNM()
    var
        ServiceLine: Record "Service Line";
        PostedServiceCreditMemos: TestPage "Posted Service Credit Memos";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // Test to verify Amount on Service Credit Memo Statistics after posting Service Credit Memo without Currency and Normal VAT.

        // Setup: Create and post Service Invoice. Open page Posted Service Credit Memos.
        CreateAndPostServiceDocument(ServiceLine, ServiceLine."Document Type"::"Credit Memo");
        DocumentNo := FindServiceCreditMemo(ServiceLine."Customer No.");
        VATAmount := ServiceLine.Amount * (ServiceLine."VAT %" + ServiceLine."EC %") / 100;
        LibraryVariableStorage.Enqueue(ServiceLine.Amount);
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(ServiceLine.Amount + VATAmount);
        PostedServiceCreditMemos.OpenView();
        PostedServiceCreditMemos.FILTER.SetFilter("No.", DocumentNo);

        // Exercise.
        PostedServiceCreditMemos.ServiceStatistics.Invoke();
        PostedServiceCreditMemos.Close();

        // Verify: Verify Amount, VAT Amount and Amount Including VAT on Service Credit Memo Statistics.
        // Verification in page handler ServiceCreditMemoStatisticsPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceCreditMemoNormalVATWithCurrency()
    var
        ServiceLine: Record "Service Line";
    begin
        // Test to verify G/L entry after posting Service Credit Memo with Currency and Normal VAT.
        PostServiceDocumentNormalVATWithCurrency(ServiceLine."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceNormalVATWithCurrency()
    var
        ServiceLine: Record "Service Line";
    begin
        // Test to verify G/L entry after posting Service Invoice with Currency and Normal VAT.
        PostServiceDocumentNormalVATWithCurrency(ServiceLine."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcVATAmountVATPct()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [SCENARIO 379514] VAT % of VAT Amount Line record is copied from service line in the ServiceLine.CalcVATAmountLines function

        // [GIVEN] VAT Posting Setup with "Reverse Charge VAT" and VAT %
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT",
          LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Service Quote with VAT Posting Setup
        CreateServiceQuoteWithVATPostingSetup(
          ServiceHeader,
          ServiceLine,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          VATPostingSetup);

        // [WHEN] Run funciton ServiceLine.CalcVATAmountLines
        ServiceLine.CalcVATAmountLines(0, ServiceHeader, ServiceLine, VATAmountLine, true);

        // [THEN] VATAmountLine.VAT % is copied from Service line
        VATAmountLine.TestField("VAT %", ServiceLine."VAT %");
    end;

    local procedure PostServiceDocumentNormalVATWithCurrency(DocumentType: Enum "Service Document Type")
    var
        ServiceLine: Record "Service Line";
        OldAdditionalReportingCurrency: Code[10];
        CurrencyCode: Code[10];
    begin
        // Test to verify G/L entry after posting Service Invoice with Currency and Normal VAT.

        // Setup: Create Service Credit Memo. Update Additional Reporting Currency on General Ledger Setup.
        CurrencyCode := CreateCurrency();
        OldAdditionalReportingCurrency := UpdateAdditionalReportingCurrOnGeneralLedgerSetup(CurrencyCode);
        CreateServiceDocumentAndUpdateGLAccount(
          ServiceLine, CurrencyCode, DocumentType, ServiceLine."VAT Calculation Type"::"Normal VAT",
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));  // Take random Quantity and Unit Price.

        // Exercise.
        PostServiceDocument(ServiceLine."Document No.", ServiceLine."Document Type");

        // Verify: Verify Amount, Additional Currency Base on G/L Entry.
        VerifyGLEntry(
          FindPostedDocumentNo(DocumentType, ServiceLine."Customer No."), ServiceLine."No.",
          FindServiceLineAmount(DocumentType, LibraryERM.ConvertCurrency(ServiceLine.Amount, CurrencyCode, '', WorkDate())),
          FindServiceLineAmount(DocumentType, ServiceLine.Amount));  // To Currency as blank.

        // Tear Down.
        UpdateAdditionalReportingCurrOnGeneralLedgerSetup(OldAdditionalReportingCurrency);
    end;

    local procedure CreateAndPostServiceDocument(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type")
    begin
        CreateServiceDocumentAndUpdateGLAccount(
          ServiceLine, '', DocumentType, ServiceLine."VAT Calculation Type"::"Normal VAT",
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));  // Take random Quantity and Unit Price. Currency as blank.
        PostServiceDocument(ServiceLine."Document No.", ServiceLine."Document Type");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        Currency.Validate("Residual Gains Account", CreateGLAccount('', ''));  // Gen. Prod. Posting Group and VAT Prod. Posting Group as blank.
        Currency.Validate("Residual Losses Account", Currency."Residual Gains Account");
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        GeneralPostingSetup.Validate("Sales Line Disc. Account", CreateGLAccount('', ''));  // Gen. Prod. Posting Group and VAT Prod. Posting Group as blank.
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateGLAccount(GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; CurrencyCode: Code[10]; DocumentType: Enum "Service Document Type"; VATCalculationType: Enum "Tax Calculation Type"; Quantity: Decimal; UnitPrice: Decimal)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        ServiceHeader: Record "Service Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup, VATCalculationType);
        CreateServiceHeader(
          ServiceHeader, DocumentType, CurrencyCode, GeneralPostingSetup."Gen. Bus. Posting Group",
          VATPostingSetup."VAT Bus. Posting Group");
        CreateServiceLine(
          ServiceLine, ServiceHeader, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
          Quantity, UnitPrice);
    end;

    local procedure CreateServiceDocumentAndUpdateGLAccount(var ServiceLine: Record "Service Line"; CurrencyCode: Code[10]; DocumentType: Enum "Service Document Type"; VATCalculationType: Enum "Tax Calculation Type"; Quantity: Decimal; UnitPrice: Decimal)
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CreateServiceDocument(ServiceLine, CurrencyCode, DocumentType, VATCalculationType, Quantity, UnitPrice);
        Customer.Get(ServiceLine."Customer No.");
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        UpdatePostingGroupOnGLAccount(
          CustomerPostingGroup."Invoice Rounding Account", ServiceLine."Gen. Prod. Posting Group", ServiceLine."VAT Prod. Posting Group");
    end;

    local procedure CreateServiceDocumentWithLineDiscount(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type")
    begin
        CreateServiceDocument(
          ServiceLine, '', DocumentType, ServiceLine."VAT Calculation Type"::"Normal VAT",
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));  // Take random Qunatity and Unit Price. Currency Code as blank.
        ServiceLine.Validate("Line Discount %", 100);  // 100 % Discount required for Line Discount %.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CurrencyCode: Code[10]; GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20])
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CreateCustomer(GenBusPostingGroup, VATBusPostingGroup));
        ServiceHeader.Validate("Currency Code", CurrencyCode);
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", CreateGLAccount(GenProdPostingGroup, VATProdPostingGroup));
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Unit Price", UnitPrice);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceQuoteWithVATPostingSetup(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; CustomerNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup")
    var
        RefGLAccount: Record "G/L Account";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, CustomerNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, RefGLAccount."Gen. Posting Type"::Sale));
        ServiceLine.Validate(Quantity, LibraryRandom.RandIntInRange(10, 20));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        ServiceLine.Modify();
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Validate("Sales VAT Account", CreateGLAccount('', ''));  // Gen. Prod. Posting Group and VAT Prod. Posting Group as blank.
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDec(10, 2));
        VATPostingSetup.Validate("EC %", LibraryRandom.RandDec(10, 2));
        VATPostingSetup.Modify(true);
    end;

    local procedure FindServiceLineAmount(DocumentType: Enum "Service Document Type"; Amount: Decimal): Decimal
    var
        ServiceHeader: Record "Service Header";
    begin
        if DocumentType = ServiceHeader."Document Type"::Invoice then
            exit(-Amount);
        exit(Amount);
    end;

    local procedure FindPostedDocumentNo(DocumentType: Enum "Service Document Type"; CustomerNo: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        if DocumentType = ServiceHeader."Document Type"::Invoice then
            exit(FindServiceInvoiceHeader(CustomerNo));
        exit(FindServiceCreditMemo(CustomerNo));
    end;

    local procedure FindServiceCreditMemo(CustomerNo: Code[20]): Code[20]
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Customer No.", CustomerNo);
        ServiceCrMemoHeader.FindFirst();
        exit(ServiceCrMemoHeader."No.");
    end;

    local procedure FindServiceInvoiceHeader(CustomerNo: Code[20]): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure GetReceivableAccount(No: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(No);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure PostServiceDocument(DocumentNo: Code[20]; DocumentType: Enum "Service Document Type")
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(DocumentType, DocumentNo);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // Post as ship and invoice.
    end;

    local procedure UpdateAdditionalReportingCurrOnGeneralLedgerSetup(NewAdditionalReportingCurrency: Code[10]) AdditionalReportingCurrency: Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        AdditionalReportingCurrency := GeneralLedgerSetup."Additional Reporting Currency";
        GeneralLedgerSetup."Additional Reporting Currency" := NewAdditionalReportingCurrency;  // Using assignment to avoid execution of Adjust Add. Reporting Currency batch job.
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePostingGroupOnGLAccount(No: Code[20]; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(No);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true)
    end;

    local procedure UpdateSalesReceivablesSetupPostLineDiscount(PostLineDiscount: Boolean) OldPostLineDiscount: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldPostLineDiscount := SalesReceivablesSetup."Post Line Discount";
        SalesReceivablesSetup.Validate("Post Line Discount", PostLineDiscount);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal; AdditionalCurrencyAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, GLEntry."Additional-Currency Amount", LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Base: Decimal; Amount: Decimal; AdditionalCurrencyAmount: Decimal; AdditionalCurrencyBase: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(Base, VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        Assert.AreNearlyEqual(Amount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, VATEntry."Additional-Currency Amount", LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        Assert.AreNearlyEqual(
          AdditionalCurrencyBase, VATEntry."Additional-Currency Base", LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
    end;

    local procedure VerifyVATEntryTotal(DocumentNo: Code[20]; Base: Decimal; Amount: Decimal; AdditionalCurrencyAmount: Decimal; AdditionalCurrencyBase: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.CalcSums(Base, Amount, "Additional-Currency Base", "Additional-Currency Amount");
        Assert.AreNearlyEqual(Base, VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        Assert.AreNearlyEqual(Amount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, VATEntry."Additional-Currency Amount", LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        Assert.AreNearlyEqual(
          AdditionalCurrencyBase, VATEntry."Additional-Currency Base", LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
    end;
#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceStatisticsPageHandler(var ServiceInvoiceStatistics: TestPage "Service Invoice Statistics")
    var
        Amount: Variant;
        VATAmount: Variant;
        TotalAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(Amount);
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(TotalAmount);
        Assert.AreNearlyEqual(
          Amount, ServiceInvoiceStatistics.Amount.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        Assert.AreNearlyEqual(
          VATAmount, ServiceInvoiceStatistics.VATAmount.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        ServiceInvoiceStatistics.Subform.First();
        Assert.AreNearlyEqual(
          TotalAmount, ServiceInvoiceStatistics.Subform."Amount Including VAT".AsDecimal(),
          LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoStatisticsPageHandler(var ServiceCreditMemoStatistics: TestPage "Service Credit Memo Statistics")
    var
        Amount: Variant;
        VATAmount: Variant;
        TotalAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(Amount);
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(TotalAmount);
        Assert.AreNearlyEqual(
          Amount, ServiceCreditMemoStatistics.Amount.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        Assert.AreNearlyEqual(
          VATAmount, ServiceCreditMemoStatistics.VATAmount.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        ServiceCreditMemoStatistics.Subform.First();
        Assert.AreNearlyEqual(
          TotalAmount, ServiceCreditMemoStatistics.Subform."Amount Including VAT".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceStatisticsPageHandlerNM(var ServiceInvoiceStatistics: TestPage "Service Invoice Statistics")
    var
        Amount: Variant;
        VATAmount: Variant;
        TotalAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(Amount);
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(TotalAmount);
        Assert.AreNearlyEqual(
          Amount, ServiceInvoiceStatistics.Amount.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        Assert.AreNearlyEqual(
          VATAmount, ServiceInvoiceStatistics.VATAmount.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        ServiceInvoiceStatistics.Subform.First();
        Assert.AreNearlyEqual(
          TotalAmount, ServiceInvoiceStatistics.Subform."Amount Including VAT".AsDecimal(),
          LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoStatisticsPageHandlerNM(var ServiceCreditMemoStatistics: TestPage "Service Credit Memo Statistics")
    var
        Amount: Variant;
        VATAmount: Variant;
        TotalAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(Amount);
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(TotalAmount);
        Assert.AreNearlyEqual(
          Amount, ServiceCreditMemoStatistics.Amount.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        Assert.AreNearlyEqual(
          VATAmount, ServiceCreditMemoStatistics.VATAmount.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        ServiceCreditMemoStatistics.Subform.First();
        Assert.AreNearlyEqual(
          TotalAmount, ServiceCreditMemoStatistics.Subform."Amount Including VAT".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
    end;
}
