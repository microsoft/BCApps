codeunit 144541 "Purchase Document - VAT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase]
        IsInitialized := false;
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryNLLocalization: Codeunit "Library - NL Localization";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GetProposalEntriesReportForPurchInvWithCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // [FEATURE] [Telebank] [Get Proposal Entries]
        // [SCENARIO 363155] Get Proposal Entries when Vendor, Our Bank Account, Purch.Invoice have the same FCY
        Initialize();

        // [GIVEN] Vendor, Our Bank Account, Purch.Invoice with the same currency = "X" and Amount = "A"
        CurrencyCode := CreateCurrencyWithRandomExchangeRate();
        Amount := ScenarioPurchInvoiceWithCurrency(PurchaseHeader, CurrencyCode, CurrencyCode, CurrencyCode);

        // [WHEN] Run Get Proposal Entries Report
        REPORT.Run(REPORT::"Get Proposal Entries");

        // [THEN] 'Currency Code' = "X", 'Amount' = "A" on Proposal Line
        // [THEN] 'Foreign Currency' = '', 'Foreign Amount' = 0 on Proposal Line
        VerifyForeignCurrencyAndAmountOnProposalLine(PurchaseHeader, CurrencyCode, Amount, '', 0);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GetProposalEntriesReportForPurchInvWithNewCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        Amount: Decimal;
    begin
        // [FEATURE] [Telebank] [Get Proposal Entries]
        // [SCENARIO 363155] Get Proposal Entries when Purch.Invoice has FCY different from Vendor, Our Bank Account
        Initialize();

        // [GIVEN] Vendor, Our Bank Account with no Currency, Purch.Invoice Currency = "X" and Amount = "A"
        Amount := ScenarioPurchInvoiceWithCurrency(PurchaseHeader, '', '', CreateCurrencyWithRandomExchangeRate());

        // [WHEN] Run Get Proposal Entries Report
        REPORT.Run(REPORT::"Get Proposal Entries");

        // [THEN] 'Currency Code' = '', 'Amount' = LCY("A") on Proposal Line
        // [THEN] 'Foreign Currency' = "X", 'Foreign Amount' = "A" on Proposal Line
        VerifyForeignCurrencyAndAmountOnProposalLine(
          PurchaseHeader, '', Round(Amount / PurchaseHeader."Currency Factor"), PurchaseHeader."Currency Code", Amount);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GetProposalEntriesReportForPurchInvWithoutCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        Amount: Decimal;
    begin
        // [FEATURE] [Telebank] [Get Proposal Entries]
        // [SCENARIO] Get Proposal Entries when Vendor, Our Bank Account, Purch.Invoice with LCY currency
        Initialize();

        // [GIVEN] Vendor, Our Bank Account, Purch.Invoice with no Currency and Amount = "A"
        Amount := ScenarioPurchInvoiceWithCurrency(PurchaseHeader, '', '', '');

        // [WHEN] Run Get Proposal Entries Report
        REPORT.Run(REPORT::"Get Proposal Entries");

        // [THEN] 'Currency Code' = '', 'Amount' = "A" on Proposal Line
        // [THEN] 'Foreign Currency' = '', 'Foreign Amount' = 0 on Proposal Line
        VerifyForeignCurrencyAndAmountOnProposalLine(PurchaseHeader, '', Amount, '', 0);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GetProposalEntriesReportForPurchInvWithOurBankCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // [FEATURE] [Telebank] [Get Proposal Entries]
        // [SCENARIO 363152] Get Proposal Entries when Vendor in LCY whereas Vendor, Our Bank Account have the same FCY
        Initialize();

        // [GIVEN] Vendor with empty Currency, Our Bank Account, Purch.Invoice with the same Currency = "X" and Amount = "A"
        CurrencyCode := CreateCurrencyWithRandomExchangeRate();
        Amount := ScenarioPurchInvoiceWithCurrency(PurchaseHeader, '', CurrencyCode, CurrencyCode);

        // [WHEN] Run Get Proposal Entries Report
        REPORT.Run(REPORT::"Get Proposal Entries");

        // [THEN] 'Currency Code' = "X", 'Amount' = "A" on Proposal Line
        // [THEN] 'Foreign Currency' = '', 'Foreign Amount' = 0 on Proposal Line
        VerifyForeignCurrencyAndAmountOnProposalLine(PurchaseHeader, CurrencyCode, Amount, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithPriceIncludingVat()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Verify program allows to set Prices Including VAT =True on Purchase order when Check Doc. Total Amounts=True on Purchase & Payables Setup window.
        Initialize();
        UpdatePurchasePayableSetup();
        CreatePurchaseDocumentWithPriceIncludingVAT(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Order, '', '');

        // [WHEN] Post Purchase Order to check for any error.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Verify To check Purchase Order posted or not with Amount.
        VerifyPurchaseRcpt(DocumentNo, PurchaseLine."Direct Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoWithPriceIncludingVat()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Verify program allows to set Prices Including VAT =True on Purchase Credit Memo Order when Check Doc. Total Amounts=True on Purchase & Payables Setup window.
        Initialize();
        CreatePurchaseDocumentWithPriceIncludingVAT(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::"Credit Memo", '', '');
        UpdatePurchaseHeaderWithDocumentAmountIncludingVat(PurchaseHeader, PurchaseLine."Line Amount");

        // [WHEN] Post Purchase Order to check for any error.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Verify To check Purchase Credit Memo Order posted or not with Amount.
        VerifyPurchaseCreditMemo(DocumentNo, PurchaseLine."Direct Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceQtyToReceiveForGLAccSecondLine()
    var
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
        DocNo: Code[20];
        GLAccountNo: Code[20];
        Amt: Decimal;
    begin
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        Amt := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Purchase Invoice with one line with G/L Account 'A'
        PurchaseInvoice.OpenNew();
        Vendor.Get(LibraryPurchase.CreateVendorNo());
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);
        DocNo := PurchaseInvoice."No.".Value();
        PurchaseInvoice."Vendor Invoice No.".SetValue(DocNo);
        PurchaseInvoice.PurchLines.Type.SetValue(PurchaseInvoice.PurchLines.Type.GetOption(2));
        PurchaseInvoice.PurchLines."No.".SetValue(GLAccountNo);
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(Amt);
        PurchaseInvoice.PurchLines.New();
        // [WHEN] create the second line with G/L Account 'A', set "Direct Unit Cost" to 'X'
        PurchaseInvoice.PurchLines."No.".SetValue(GLAccountNo);
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(Amt);
        PurchaseInvoice.OK().Invoke();

        // [THEN] "Qty. to Receive" is 1 in the second line
        VerifyPurchLineQtyToReceive(DocNo, 1);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GetProposalEntriesSeparateLinesByForeignCurrency()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        CurrencyCode: array[2] of Code[10];
        InvoiceAmount: array[2] of Decimal;
    begin
        // [SCENARIO 363884] Get Proposal Entries generates separate Proposal Line for each Foreign Currency
        Initialize();
        SetupCheckDocTotalAmt(false);

        // [GIVEN] Posted Purchase Invoice "A" with Currency "X" and Posted Purchase Invoice "B" with Currency "Y" for the same Vendor
        CurrencyCode[1] := CreateCurrencyWithRandomExchangeRate();
        CurrencyCode[2] := CreateCurrencyWithRandomExchangeRate();
        InvoiceAmount[1] := CreatePostPurchaseInvoice(
            PurchaseHeader[1], CreateVendorWithCurrency('', CreateVendorTransactionMode('')), CurrencyCode[1]);
        InvoiceAmount[2] := CreatePostPurchaseInvoice(
            PurchaseHeader[2], PurchaseHeader[1]."Buy-from Vendor No.", CurrencyCode[2]);

        // [WHEN] Run Get Proposal Entries Report
        REPORT.Run(REPORT::"Get Proposal Entries");

        // [THEN] Proposal Line with Foreign Currency = "X" exists, Amount is equal to Invoice "A" Amount
        VerifyForeignCurrencyAndAmountOnProposalLine(
          PurchaseHeader[1], '', Round(InvoiceAmount[1] / PurchaseHeader[1]."Currency Factor"), CurrencyCode[1], InvoiceAmount[1]);

        // [THEN] Proposal Line with Foreign Currency = "Y" exists, Amount is equal to Invoice "B" Amount
        VerifyForeignCurrencyAndAmountOnProposalLine(
          PurchaseHeader[2], '', Round(InvoiceAmount[2] / PurchaseHeader[2]."Currency Factor"), CurrencyCode[2], InvoiceAmount[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoQtyToReceiveForGLAccSecondLine()
    var
        Vendor: Record Vendor;
        PurchaseCrMemo: TestPage "Purchase Credit Memo";
        DocNo: Code[20];
        GLAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 376541] Return Qty. to Ship is equal to 1 after user adds a line with G/L Account to already existing one
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        Amount := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Purchase Credit Memo with 1 line for G/L Account
        PurchaseCrMemo.OpenNew();
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseCrMemo."Buy-from Vendor Name".SetValue(Vendor.Name);
        DocNo := PurchaseCrMemo."No.".Value();
        PurchaseCrMemo."Vendor Cr. Memo No.".SetValue(DocNo);
        PurchaseCrMemo.PurchLines.Type.SetValue(PurchaseCrMemo.PurchLines.Type.GetOption(2));
        PurchaseCrMemo.PurchLines."No.".SetValue(GLAccountNo);
        PurchaseCrMemo.PurchLines."Direct Unit Cost".SetValue(Amount);

        // [WHEN] Go to next line and set G/L Account No. and Amount
        PurchaseCrMemo.PurchLines.New();
        PurchaseCrMemo.PurchLines."No.".SetValue(GLAccountNo);
        PurchaseCrMemo.PurchLines."Direct Unit Cost".SetValue(Amount);
        PurchaseCrMemo.OK().Invoke();

        // [THEN] Second lines has "Return Qty. to Ship" = 1
        VerifyPurchLineReturnQtyToShip(DocNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocAmountVATOnPurchaseHeaderWhenSecondLineHasZeroVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        Amount: array[3] of Decimal;
        VATAmount: array[3] of Decimal;
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 229427] "Purchase Header"."Doc. Amount VAT" must be correct when Purchase Lines has different "VAT %" (second line has zero VAT)
        Initialize();

        // [GIVEN] Purchase document with three lines
        CreatePurchHeaderWithPostingGroups(PurchaseHeader, 0);

        // [GIVEN] First Purchase line with VAT = 18%, Amount = 100, Amount incl. VAT = 118
        CreatePurchLineWithVATPostingSetup(PurchaseHeader, Amount[1], VATAmount[1], LibraryRandom.RandIntInRange(10, 50));

        // [GIVEN] Second Purchase line with VAT = 0%, Amount = 200, Amount incl. VAT = 200
        CreatePurchLineWithVATPostingSetup(PurchaseHeader, Amount[2], VATAmount[2], 0);

        // [GIVEN] Third Purchase line with VAT = 9%, Amount = 300, Amount incl. VAT = 327
        CreatePurchLineWithVATPostingSetup(PurchaseHeader, Amount[3], VATAmount[3], LibraryRandom.RandIntInRange(50, 90));

        // [WHEN] Validating of field "Purchase Header"."Doc. Amount Incl. VAT" with value 645
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", Amount[1] + Amount[2] + Amount[3] + VATAmount[1] + VATAmount[2] + VATAmount[3]);

        // [THEN] "Purchase Header"."Doc. Amount VAT" = 45
        PurchaseHeader.TestField("Doc. Amount VAT", VATAmount[1] + VATAmount[2] + VATAmount[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocAmountVATOnPurchaseHeaderWhenFirstLineHasZeroVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        Amount: array[3] of Decimal;
        VATAmount: array[3] of Decimal;
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 229427] "Purchase Header"."Doc. Amount VAT" must be correct when Purchase Lines has different "VAT %" (first line has zero VAT)
        Initialize();

        // [GIVEN] Purchase document with three lines
        CreatePurchHeaderWithPostingGroups(PurchaseHeader, 0);

        // [GIVEN] First Purchase line with VAT = 0%, Amount = 100, Amount incl. VAT = 100
        CreatePurchLineWithVATPostingSetup(PurchaseHeader, Amount[1], VATAmount[1], 0);

        // [GIVEN] Second Purchase line with VAT = 18%, Amount = 200, Amount incl. VAT = 236
        CreatePurchLineWithVATPostingSetup(PurchaseHeader, Amount[2], VATAmount[2], LibraryRandom.RandIntInRange(10, 50));

        // [GIVEN] Third Purchase line with VAT = 9%, Amount = 300, Amount incl. VAT = 327
        CreatePurchLineWithVATPostingSetup(PurchaseHeader, Amount[3], VATAmount[3], LibraryRandom.RandIntInRange(50, 90));

        // [WHEN] Validating of field "Purchase Header"."Doc. Amount Incl. VAT" with value 663
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", Amount[1] + Amount[2] + VATAmount[1] + VATAmount[2] + Amount[3] + VATAmount[3]);

        // [THEN] "Purchase Header"."Doc. Amount VAT" = 63
        PurchaseHeader.TestField("Doc. Amount VAT", VATAmount[1] + VATAmount[2] + VATAmount[3]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DocAmountVATOnPurchaseHeaderWithVATBaseDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        Amount: array[3] of Decimal;
        VATAmount: array[3] of Decimal;
        VATRate: Decimal;
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 229653] "Purchase Header"."Doc. Amount VAT" must be correct when Purchase Header has "Sales Header"."VAT Base Discount %"
        Initialize();

        // [GIVEN] Purchase document with "Purchase Header"."VAT Base Discount %" = "50"
        CreatePurchHeaderWithPostingGroups(PurchaseHeader, LibraryRandom.RandIntInRange(10, 50));

        // [GIVEN] First Purchase line with VAT = 25%, Amount = 100, Amount incl. VAT = 100
        VATRate := LibraryRandom.RandIntInRange(10, 50);
        CreatePurchLineWithVATPostingSetup(PurchaseHeader, Amount[1], VATAmount[1], VATRate);

        // [WHEN] Validating of field "Purchase Header"."Doc. Amount Incl. VAT" with value 117,5
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", Amount[1] + VATAmount[1]);

        // [THEN] "Purchase Header"."Doc. Amount VAT" = 17,5
        PurchaseHeader.TestField("Doc. Amount VAT", Round(Amount[1] * (1 - PurchaseHeader."VAT Base Discount %" / 100) / 100 * VATRate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocAmountVATOnPurchaseHeaderWhenPurchaseLinesHasDifferentVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        Amount: array[3] of Decimal;
        VATAmount: array[3] of Decimal;
        AmountModificator: Integer;
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 232544] "Purchase Header"."Doc. Amount VAT" must be correct when Purchase Lines has different "VAT %" and users input "Doc. Amount Incl. VAT" are not equal to Amount Including VAT
        Initialize();

        // [GIVEN] Purchase document with three lines
        CreatePurchHeaderWithPostingGroups(PurchaseHeader, 0);

        // [GIVEN] First Purchase line with VAT = 0%, Amount = 100, Amount incl. VAT = 100
        CreatePurchLineWithVATPostingSetup(PurchaseHeader, Amount[1], VATAmount[1], 0);

        // [GIVEN] Second Purchase line with VAT = 18%, Amount = 200, Amount incl. VAT = 236
        CreatePurchLineWithVATPostingSetup(PurchaseHeader, Amount[2], VATAmount[2], LibraryRandom.RandIntInRange(10, 50));

        // [GIVEN] Third Purchase line with VAT = 9%, Amount = 300, Amount incl. VAT = 327
        CreatePurchLineWithVATPostingSetup(PurchaseHeader, Amount[3], VATAmount[3], LibraryRandom.RandIntInRange(50, 90));

        // [WHEN] Validating of field "Purchase Header"."Doc. Amount Incl. VAT" with value 663 * 2 = 1326
        AmountModificator := LibraryRandom.RandIntInRange(2, 10);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Validate(
          "Doc. Amount Incl. VAT",
          (Amount[1] + Amount[2] + VATAmount[1] + VATAmount[2] + Amount[3] + VATAmount[3]) * AmountModificator);

        // [THEN] "Purchase Header"."Doc. Amount VAT" = 63 * 2 = 126
        PurchaseHeader.TestField("Doc. Amount VAT", (VATAmount[1] + VATAmount[2] + VATAmount[3]) * AmountModificator);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    procedure GetProposalEntriesReportForMultiplePurchInvWithCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        TransactionMode: Record "Transaction Mode";
        CurrencyCode: Code[10];
        TransactionModeCode: Code[10];
        VendorNo: array[3] of Code[20];
        Amount: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Telebank] [Get Proposal Entries]
        // [SCENARIO 461518] Foreign Currency when run Get Proposal Entries for multiple Invoices when Vendor, Bank Account and Purchase Invoice have the same FCY.
        Initialize();

        // [GIVEN] Our Bank Account with Currency "X".
        // [GIVEN] Three Vendors with Currency Code "X" and Transaction Mode "T".
        // [GIVEN] Two posted Purchase Invoices with Currency "X" and sum of Amounts "A" for each Vendor.
        CurrencyCode := CreateCurrencyWithRandomExchangeRate();
        TransactionModeCode := CreateVendorTransactionMode(CurrencyCode);
        TransactionMode.Get(TransactionMode."Account Type"::Vendor, TransactionModeCode);
        for i := 1 to ArrayLen(VendorNo) do begin
            VendorNo[i] := CreateVendorWithCurrency(CurrencyCode, TransactionModeCode);
            Amount[i] += CreatePostPurchaseInvoice(PurchaseHeader, VendorNo[i], CurrencyCode);
            Amount[i] += CreatePostPurchaseInvoice(PurchaseHeader, VendorNo[i], CurrencyCode);
        end;

        // [WHEN] Run Get Proposal Entries Report.
        Report.Run(Report::"Get Proposal Entries");

        // [THEN] Three Proposal Lines with Currency Code "X" and Amount "A" were created - one for each Vendor.
        // [THEN] Each line has blank Foreign Currency and Foreign Amount = 0.
        VerifyForeignCurrencyAndAmountOnProposalLine(TransactionMode."Our Bank", VendorNo[1], CurrencyCode, Amount[1], '', 0);
        VerifyForeignCurrencyAndAmountOnProposalLine(TransactionMode."Our Bank", VendorNo[2], CurrencyCode, Amount[2], '', 0);
        VerifyForeignCurrencyAndAmountOnProposalLine(TransactionMode."Our Bank", VendorNo[3], CurrencyCode, Amount[3], '', 0);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Purchase Document - VAT");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Purchase Document - VAT");

        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Purchase Document - VAT");
    end;

    local procedure ScenarioPurchInvoiceWithCurrency(var PurchaseHeader: Record "Purchase Header"; VendorCurrencyCode: Code[10]; BankAccountCurrencyCode: Code[10]; InvoiceCurrencyCode: Code[10]): Decimal
    begin
        exit(
          CreatePostPurchaseInvoice(
            PurchaseHeader,
            CreateVendorWithCurrency(VendorCurrencyCode, CreateVendorTransactionMode(BankAccountCurrencyCode)),
            InvoiceCurrencyCode));
    end;

    local procedure CreatePurchaseDocumentWithPriceIncludingVAT(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; CurrencyCode: Code[10])
    var
        Item: Record Item;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate(
          "Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(5));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePurchaseHeaderWithDocumentAmountIncludingVat(var PurchaseHeader: Record "Purchase Header"; DocAmountInclVAT: Decimal)
    begin
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", DocAmountInclVAT);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateVendorWithCurrency(CurrencyCode: Code[10]; TransactionModeCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Transaction Mode Code", TransactionModeCode);
        Vendor.Validate("Preferred Bank Account Code", CreateVendorBankAccount(Vendor."No."));
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCurrencyWithRandomExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Invoice Rounding Precision", LibraryERM.GetAmountRoundingPrecision());
        Currency.Modify(true);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateVendorBankAccount(VendorNo: Code[20]): Code[10]
    var
        VendorBankAccount: Record "Vendor Bank Account";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        VendorBankAccount.Init();
        VendorBankAccount.Validate(
          Code, LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo(Code), DATABASE::"Vendor Bank Account"));
        VendorBankAccount.Validate("Vendor No.", VendorNo);
        VendorBankAccount.Insert(true);
        exit(VendorBankAccount.Code);
    end;

    local procedure CreateOurBank(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateVendorTransactionMode(CurencyCode: Code[10]): Code[10]
    var
        TransactionMode: Record "Transaction Mode";
    begin
        LibraryNLLocalization.CreateTransactionMode(TransactionMode, TransactionMode."Account Type"::Vendor);
        TransactionMode.Validate("Our Bank", CreateOurBank(CurencyCode));
        TransactionMode.Validate("Identification No. Series", LibraryERM.CreateNoSeriesCode());
        TransactionMode.Modify(true);
        exit(TransactionMode.Code);
    end;

    local procedure CreatePostPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; CurrencyCode: Code[10]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocumentWithPriceIncludingVAT(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          VendorNo,
          CurrencyCode);
        UpdatePurchaseHeaderWithDocumentAmountIncludingVat(PurchaseHeader, PurchaseLine."Line Amount");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(PurchaseLine."Line Amount")
    end;

    local procedure CreatePurchHeaderWithPostingGroups(var PurchaseHeader: Record "Purchase Header"; VATBaseDiscount: Integer)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        PurchaseHeader.Validate("VAT Base Discount %", VATBaseDiscount);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchLineWithVATPostingSetup(var PurchaseHeader: Record "Purchase Header"; var Amount: Decimal; var VATAmount: Decimal; VATRate: Integer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        CreateVATPostingSetupWithPercent(VATPostingSetup, VATRate, PurchaseHeader."VAT Bus. Posting Group");
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNoWithPostingSetup(GenProductPostingGroup.Code, VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandIntInRange(10, 100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 1000));
        PurchaseLine.Modify(true);
        Amount := PurchaseLine.Amount;
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
    end;

    local procedure CreateVATPostingSetupWithPercent(var VATPostingSetup: Record "VAT Posting Setup"; VATRate: Integer; VATBusPostingGroupCode: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Identifier", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", VATRate);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdatePurchasePayableSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Check Doc. Total Amounts", true);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure VerifyForeignCurrencyAndAmountOnProposalLine(PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[20]; AmountInCurrency: Decimal; ForeignCurrency: Code[20]; ForeignAmount: Decimal)
    var
        ProposalLine: Record "Proposal Line";
    begin
        ProposalLine.SetRange(Bank, PurchaseHeader."Bank Account Code");
        ProposalLine.SetRange("Account Type", ProposalLine."Account Type"::Vendor);
        ProposalLine.SetRange("Account No.", PurchaseHeader."Buy-from Vendor No.");
        ProposalLine.SetRange("Foreign Currency", ForeignCurrency);
        ProposalLine.FindFirst();
        ProposalLine.TestField("Currency Code", CurrencyCode);
        ProposalLine.TestField(Amount, AmountInCurrency);
        ProposalLine.TestField("Foreign Amount", ForeignAmount);
    end;

    local procedure VerifyForeignCurrencyAndAmountOnProposalLine(OurBankAccountCode: Code[20]; VendorNo: Code[20]; CurrencyCode: Code[20]; AmountInCurrency: Decimal; ForeignCurrency: Code[20]; ForeignAmount: Decimal)
    var
        ProposalLine: Record "Proposal Line";
    begin
        ProposalLine.SetRange("Our Bank No.", OurBankAccountCode);
        ProposalLine.SetRange("Account Type", ProposalLine."Account Type"::Vendor);
        ProposalLine.SetRange("Account No.", VendorNo);
        Assert.RecordCount(ProposalLine, 1);

        ProposalLine.FindFirst();
        ProposalLine.TestField("Currency Code", CurrencyCode);
        ProposalLine.TestField(Amount, AmountInCurrency);
        ProposalLine.TestField("Foreign Currency", ForeignCurrency);
        ProposalLine.TestField("Foreign Amount", ForeignAmount);
    end;

    local procedure VerifyPurchaseCreditMemo(DocumentNo: Code[20]; DirectUnitCost: Decimal)
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.FindFirst();
        PurchCrMemoLine.TestField("Direct Unit Cost", DirectUnitCost);
    end;

    local procedure VerifyPurchaseRcpt(DocumentNo: Code[20]; DirectUnitCost: Decimal)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Document No.", DocumentNo);
        PurchRcptLine.FindFirst();
        PurchRcptLine.TestField("Direct Unit Cost", DirectUnitCost);
    end;

    local procedure VerifyPurchLineQtyToReceive(DocumentNo: Code[20]; QtyToReceive: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindLast();
        PurchaseLine.TestField("Qty. to Receive", QtyToReceive);
    end;

    local procedure VerifyPurchLineReturnQtyToShip(DocumentNo: Code[20]; ReturnQtyToShip: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindLast();
        PurchaseLine.TestField("Return Qty. to Ship", ReturnQtyToShip);
    end;

    local procedure SetupCheckDocTotalAmt(NewCheckDocTotalAmounts: Boolean)
    var
        PurchasePayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasePayablesSetup.Get();
        PurchasePayablesSetup.Validate("Check Doc. Total Amounts", NewCheckDocTotalAmounts);
        PurchasePayablesSetup.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetProposalEntriesRequestPageHandler(var GetProposalEntries: TestRequestPage "Get Proposal Entries")
    begin
        GetProposalEntries.CurrencyDate.SetValue(CalcDate(StrSubstNo('<%1m>', LibraryRandom.RandInt(5)), WorkDate()));
        GetProposalEntries.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy Message Handler.
    end;
}

