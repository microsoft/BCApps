codeunit 134100 "ERM Prepayment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJournals: Codeunit "Library - Journals";
        IsInitialized: Boolean;
        GLEntryAmountErr: Label 'Amount must be same.';
        SpecifyInvNoSerieErr: Label 'Specify the code for the number series that will be used to assign numbers to posted sales prepayment invoices.';
        PrepaymentAmountErr: Label '%1 must be same.';
        PrepaymentPercentErr: Label '%1 must not be zero.';
        UnknownErr: Label 'Unknown error.';
        PostPrepaymentErr: Label '%1 cannot be more than %2 in %3 %4=''%5'',%6=''%7'',%8=''%9''.', Comment = '%1=FieldCaption,%2=Value,%3=TableName,%4=FieldName,%5=FieldValue,%6=FieldName,%7=FieldValue,%8=FieldName,%9=FieldValue';
        PrepaymentErr: Label '%1 cannot be less than %2 in %3 %4=''%5'',%6=''%7'',%8=''%9''.', Comment = '%1=FieldName,%2=FieldValue,%3=TableName,%4=FieldName,%5=FieldValue,%6=FieldName,%7=FieldValue,%8=FieldName,%9=FieldValue';
        PrepmtLineAmountErr: Label 'Prepmt. Line Amount Excl. VAT cannot be more than';
        AmountErr: Label '%1 must be %2 in %3.';
        StatTotalAmtLCYErr: Label 'Statistics Total LCY is incorrect.';
        WrongPrepaymentStatusErr: Label 'Status must be equal to ''Pending Prepayment''  in %1: Document Type=%2, No.=%3. Current value is ''Open''.';
        WrongPostingNoSeriesErr: Label 'Wrong Posting No. Series in %1.';
        RmngUnrealAmountErr: Label 'Wrong value in Remaining Unrealized Amount of VAT Entry after Unappling prepayment invoice.';
        DtldCustLedgEntryErr: Label 'Transaction No of Detailed Cust. Ledg. Entry must not be zero.';
        DtldVendLedgEntryErr: Label 'Transaction No of Detailed Vendor Ledg. Entry must not be zero.';
        SalesDocExistErr: Label 'Sales document was not deleted';
        PurchaseDocExistErr: Label 'Purchase document was not deleted';
        PrepaymentAmountInvErr: Label 'Prepmt. Amt. Inv. Incl. VAT must be equal to';
        CannotChangePrepmtAccErr: Label 'You cannot change %2 while %1 is pending prepayment.', Comment = '%2- field caption, %1 - "sales order 1001".';
        CannotChangeSetupOnPrepmtAccErr: Label 'You cannot change %2 on account %3 while %1 is pending prepayment.', Comment = '%2 - field caption, %3 - account number, %1 - "sales order 1001".';
        SalesOrderNotCreatedWorksheetLineMsg: Label 'The Sales Order entry not created in Cash Flow Worksheet.';
        CustomerNo: Code[20];

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentPercentDecimal()
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO] Setting up a Prepayment % between 0 and 100 with 5 decimal places on Customer.
        CustomerWithPrepaymentPercent(LibraryRandom.RandDec(99, 5));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentPercentZero()
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as boundary value 0 on Customer.
        CustomerWithPrepaymentPercent(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentPercentHundred()
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as boundary value 100 on Customer.
        CustomerWithPrepaymentPercent(100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentPercentInteger()
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as integer value between 1 and 99 on Customer.
        CustomerWithPrepaymentPercent(LibraryRandom.RandInt(99));
    end;

    local procedure CustomerWithPrepaymentPercent(PrepaymentPercent: Decimal)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        LineGLAccount: Record "G/L Account";
    begin
        // [GIVEN] Create a new Customer. Validate Prepayment % in Customer as per parameter passed.
        Initialize();
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);

        CreateCustomerNotPrepayment(Customer, LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Customer.Validate("Prepayment %", PrepaymentPercent);
        Customer.Modify(true);

        // [WHEN] Create Sales Header, Sales Line with Item, G/L Account, Resource, Fixed Asset, Charge (Item).
        CreateSalesOrder(SalesHeader, Customer."No.", LineGLAccount);

        // [THEN] Check that the Prepayment % on Sales Header is the same as that on Customer. Check that Compress Payment is TRUE
        // and the calculations for Prepayment on Sales Line are as per Prepayment % inputted.
        SalesHeader.TestField("Prepayment %", PrepaymentPercent);
        SalesHeader.TestField("Compress Prepayment", true);
        VerifyPrepaymentOnSalesLine(SalesHeader);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoPrepaymentDueDate()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        LineGLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Sales] [Payment Terms]
        // [SCENARIO] Setting up a Prepayment Due Date with Payment Terms having no Due Date Calculation on Customer.

        // [GIVEN] Create a new Payment Term without any Due Date Calculation.
        Initialize();
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);

        // [WHEN] Create Customer, Sales Header, Sales Line with Item, G/L Account, Resource, Fixed Asset, Charge (Item).
        SalesOrderPrepaymentDueDate(SalesHeader, PaymentTerms.Code, LineGLAccount);

        // [THEN] Check that the Prepayment Due Date and Due Date on Sales Header are Document Date of Sales Header.
        SalesHeader.TestField("Due Date", SalesHeader."Document Date");
        SalesHeader.TestField("Prepayment Due Date", SalesHeader."Document Date");

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroPrepaymentDueDate()
    begin
        // [FEATURE] [Sales] [Payment Term]
        // [SCENARIO] Setting up a Prepayment Due Date with Payment Terms having Due Date Calculation as boundary value 0D on Customer.
        PrepaymentDueDateOnSalesOrder('<0D>');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RandomPrepaymentDueDate()
    begin
        // [FEATURE] [Sales] [Payment Term]
        // [SCENARIO] Setting up a Prepayment Due Date with Payment Terms having Due Date Calculation as any value on Customer.
        PrepaymentDueDateOnSalesOrder('<' + Format(LibraryRandom.RandInt(365)) + 'D>');  // Create formula with 1 to 365 days.
    end;

    local procedure PrepaymentDueDateOnSalesOrder(DueDate: Text[6])
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        LineGLAccount: Record "G/L Account";
    begin
        // [GIVEN] Create a new Payment Term with Due Date Calculation as per parameter passed.
        Initialize();
        CreatePaymentTermWithDueDate(PaymentTerms, DueDate);
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);

        // [WHEN] Create Sales Order -Customer, Sales Header, Sales Line with Item, G/L Account, Resource, Fixed Asset, Charge (Item).
        SalesOrderPrepaymentDueDate(SalesHeader, PaymentTerms.Code, LineGLAccount);

        // [THEN] Check that the Prepayment Due Date and Due Date on Sales Header are calculated by considering Due Date Calculation
        // of Payment Terms with Document Date of Sales Header.
        SalesHeader.TestField("Due Date", CalcDate(PaymentTerms."Due Date Calculation", SalesHeader."Document Date"));
        SalesHeader.TestField("Prepayment Due Date", CalcDate(PaymentTerms."Due Date Calculation", SalesHeader."Document Date"));

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostZeroPrepaymentDueDate()
    begin
        // [FEATURE] [Sales] [Payment Term]
        // [SCENARIO] Posting a Prepayment Invoice having Prepayment Due Date with Payment Terms having Due Date Calculation as 0D on Customer.
        PostWithPrepaymentDueDate('<0D>');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRandomPrepaymentDueDate()
    begin
        // [FEATURE] [Sales] [Payment Term]
        // [SCENARIO] Posting a Prepayment Invoice having Prepayment Due Date with Payment Terms having Due Date Calculation as not 0D on Customer.
        PostWithPrepaymentDueDate('<' + Format(LibraryRandom.RandInt(365)) + 'D>');  // Create formula with 1 to 365 days.
    end;

    local procedure PostWithPrepaymentDueDate(DueDate: Text[6])
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        LineGLAccount: Record "G/L Account";
    begin
        // [GIVEN] Create a new Payment Term Due Date Calculation as per parameter passed. Create Sales Order - Create Customer, Sales
        // Header, Sales Line with Item, G/L Account, Resource, Fixed Asset, Charge (Item).
        Initialize();
        CreatePaymentTermWithDueDate(PaymentTerms, DueDate);

        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);
        SalesOrderPrepaymentDueDate(SalesHeader, PaymentTerms.Code, LineGLAccount);

        // [WHEN] Setup Prepayments Accounts for Sales Lines and Post Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Check the Prepayment Amount on Prepayment Invoice is sum of Prepayment Amount on Sales Line and the Due Date is the
        // Prepayment Due Date on Sales Header.
        VerifyPrepaymentAmountDueDate(SalesHeader);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepaymentPercentDecimal()
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % between 0 to 100 with 5 decimal places for Sales Type Customer.
        CustomerSalesPrepaymentPercent(LibraryRandom.RandDec(99, 5));  // Using RANDOM value for Prepayment %.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepaymentPercentZero()
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as boundary value 0 for Sales Type Customer.
        CustomerSalesPrepaymentPercent(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepaymentPercentHundred()
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as boundary value 100 for Sales Type Customer.
        CustomerSalesPrepaymentPercent(100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepaymentPercent()
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % for Sales Type Customer.
        CustomerSalesPrepaymentPercent(LibraryRandom.RandInt(100));  // Using RANDOM value for Prepayment %.
    end;

    local procedure CustomerSalesPrepaymentPercent(PrepaymentPercent: Decimal)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentPct: Record "Sales Prepayment %";
    begin
        // [GIVEN] Create a new Customer and Item. Create Sales Prepayment and Validate Prepayment % as per parameter passed.
        Initialize();
        CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        CreatePrepayment(SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::Customer, Customer."No.", Item."No.", PrepaymentPercent);

        // [WHEN] Create Sales Header, Sales Line for Item.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", Item."No.");

        // [THEN] Check that the Prepayment % on Sales Line is same as defined on Sales Prepayment, the calculation for Prepmt.
        // Line Amount on Sales Line are as per Prepayment % inputted and Prepayment Percent on Sales Header.
        VerifyPrepaymentLineAmount(SalesLine, SalesPrepaymentPct."Prepayment %");
        VerifyPrepaymentPercent(SalesHeader, SalesLine, Customer."Prepayment %", SalesPrepaymentPct."Prepayment %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepaymentCustPriceGroup()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentPct: Record "Sales Prepayment %";
        CustomerPriceGroup: Record "Customer Price Group";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % between 0 to 100 with 5 decimal places for Sales Type Customer Price Group.

        // [GIVEN] Create a new Customer and Item. Create Sales Prepayment and Validate Prepayment %
        // between 0 to 100 with 5 decimal places for Sales Type Customer Price Group.
        Initialize();
        CreateItem(Item);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerNo := CreateCustomerWithPriceGroup(CustomerPriceGroup.Code);
        CreatePrepayment(
          SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::"Customer Price Group", CustomerPriceGroup.Code, Item."No.",
          LibraryRandom.RandDec(99, 5));  // Random Number Generator for Prepayment Percent.

        // [WHEN] Create Sales Header, Sales Line for Item.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, CustomerNo, Item."No.");

        // [THEN] Check that the Prepayment % on Sales Line is same as defined on Sales Prepayment, the calculation for Prepmt.
        // Line Amount on Sales Line are as per Prepayment % inputted and Prepayment Percent on Sales Header.
        VerifyPrepaymentLineAmount(SalesLine, SalesPrepaymentPct."Prepayment %");
        VerifyPrepaymentPercent(SalesHeader, SalesLine, 0, SalesPrepaymentPct."Prepayment %");  // Prepayment percent in Customer is zero.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepaymentAllCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentPct: Record "Sales Prepayment %";
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % between 0 to 100 with 5 decimal places for Sales Type All Customer.

        // [GIVEN] Create new Customer and Item. Create Sales Prepayment and Validate Prepayment %
        // between 0 to 100 with 5 decimal places for Sales Type All Customer.
        Initialize();
        CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);

        // Random Number Generator for Prepayment Percent.
        CreatePrepayment(
          SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::"All Customers", '', Item."No.", LibraryRandom.RandDec(99, 5));

        // [WHEN] Create Sales Header, Sales Line for Item.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", Item."No.");

        // [THEN] Check that the Prepayment % on Sales Line is same as defined on Sales Prepayment, the calculation for Prepmt.
        // Line Amount on Sales Line are as per Prepayment % inputted and Prepayment Percent on Sales Header.
        VerifyPrepaymentLineAmount(SalesLine, SalesPrepaymentPct."Prepayment %");
        VerifyPrepaymentPercent(SalesHeader, SalesLine, Customer."Prepayment %", SalesPrepaymentPct."Prepayment %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepaymentDateRange()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentPct: Record "Sales Prepayment %";
        DateRange: Integer;
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment %  Only valid in specific time interval.

        // [GIVEN] Create new Customer and Item. Create Sales Prepayment and Validate Prepayment %
        // between 0 to 100 with 5 decimal places and validate End date for Sales Type Customer.
        Initialize();
        CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);

        // Random Number Generator for Prepayment Percent.
        CreatePrepayment(
          SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::Customer, Customer."No.", Item."No.", LibraryRandom.RandDec(99, 5));
        DateRange := LibraryRandom.RandInt(10);
        SalesPrepaymentPct.Validate(
          "Ending Date", CalcDate('<' + Format(DateRange) + 'D>', SalesPrepaymentPct."Starting Date"));
        SalesPrepaymentPct.Modify(true);

        // [WHEN] Create Sales Header with Posting Date between Sales Prepayment Start and End Date and create Sales Line for Item.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", Item."No.");
        SalesHeader.Validate("Posting Date", CalcDate('<' + Format(DateRange - 1) + 'D>', WorkDate()));
        SalesHeader.Modify(true);

        // [THEN] Check that the Prepayment % on Sales Line is same as defined on Sales Prepayment
        // and the calculation for Prepmt. Line Amount on Sales Line are as per Prepayment % inputted.
        SalesLine.TestField("Prepayment %", SalesPrepaymentPct."Prepayment %");
        VerifyPrepaymentLineAmount(SalesLine, SalesPrepaymentPct."Prepayment %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepaymentBlankSetup()
    var
        Item: Record Item;
        SalesPrepaymentPct: Record "Sales Prepayment %";
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % for Not complete setup.

        // [GIVEN] Create new Customer and Item.
        Initialize();
        CreateItem(Item);

        // [WHEN] Create Sales Prepayment without Sales Code for Sales Type Customer.
        asserterror LibrarySales.CreateSalesPrepaymentPct(
            SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::Customer, '', Item."No.", WorkDate());

        // [THEN] Check that while defining Prepayment %, system must give an error.
        Assert.IsTrue(StrPos(GetLastErrorText, Item."No.") > 0, UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupNewSalesPrepaymentAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        SalesPrepaymentsAccountOld: Code[20];
    begin
        // [FEATURE] [Sales] [Setup]
        // [SCENARIO] Setting up Sales Prepayment Account in a General Posting Setup.

        // [GIVEN] Find a GL Account.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);

        // [WHEN] Setup Sales Prepayments Account in General Posting Setup.
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        SalesPrepaymentsAccountOld := AttachSalesPrepaymentAccountInSetup(GeneralPostingSetup, GLAccount."No.");

        // [THEN] Verify the Sales Prepayment Account in General Posting Setup.
        GeneralPostingSetup.TestField("Sales Prepayments Account", GLAccount."No.");

        // 4. Tear Down: Change back the Sales Prepayment Account in the General Posting Setup.
        GeneralPostingSetup.Validate("Sales Prepayments Account", SalesPrepaymentsAccountOld);
        GeneralPostingSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WrongSalesPrepaymentAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        RandomCodeGLAccount: Code[20];
    begin
        // [FEATURE] [Sales] [Setup]
        // [SCENARIO] Error on setting up Sales Prepayment Account in a General Posting Setup with unkown GL Account.

        // [GIVEN]
        Initialize();

        // [WHEN] Create a Code Randomly, Setup Sales Prepayments Account in General Posting Setup with wrong GL Account.
        RandomCodeGLAccount := CopyStr(
            LibraryUtility.GenerateRandomCode(GLAccount.FieldNo("No."), DATABASE::"G/L Account"),
            1, LibraryUtility.GetFieldLength(DATABASE::"G/L Account", GLAccount.FieldNo("No.")));
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        asserterror AttachSalesPrepaymentAccountInSetup(GeneralPostingSetup, RandomCodeGLAccount);

        // [THEN] Verify the error message.
        Assert.IsTrue(StrPos(GetLastErrorText, RandomCodeGLAccount) > 0, UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoSeriesInvoiceAndMemo()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LineGLAccount: Record "G/L Account";
        VATClauseCode: Code[20];
    begin
        // [FEATURE] [Sales] [Series No] [Credit Memo]
        // [SCENARIO] Setting up the Posted Prepmt Inv Nos and Posted Prepmt Cr Memo Nos in Sales Setup with Posted Invoice Nos and Posted Credit Memo Nos.

        // [GIVEN] Change the Posted Prepmt Inv Nos and Posted Prepmt Cr Memo Nos in Sales and Receivable Setup, create Payment Terms,
        // create Sales Order with created payment terms.
        Initialize();
        PrepmtInvNosInSetup(SalesReceivablesSetup);
        PrepmtCreditMemoInSetup(SalesReceivablesSetup);
        LibraryERM.CreatePaymentTerms(PaymentTerms);

        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);
        VATClauseCode := UpdateVATClauseCode(LineGLAccount);
        SalesOrderPrepaymentDueDate(SalesHeader, PaymentTerms.Code, LineGLAccount);

        // [WHEN] Create Setup for Sales Prepayment Account and Post the Prepayment Sales Invoice and Prepayment Credit Memo.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);

        // [THEN] Verify the Posted Prepmt Sales Invoice No and Posted Prepmt Cr Memo Nos with No Series.
        // [THEN] VAT Clause Code is updated in posted document line from VAT Posting Setup (TFS 443665)        
        VerifyPrepaymentInvoice(SalesHeader."No.", SalesReceivablesSetup."Posted Prepmt. Inv. Nos.", VATClauseCode);
        VerifyPrepaymentCreditMemo(SalesHeader."No.", SalesReceivablesSetup."Posted Prepmt. Cr. Memo Nos.", VATClauseCode);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewNoSeriesInvoiceAndMemo()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LineGLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Sales] [Series No] [Credit Memo]
        // [SCENARIO] Setting up the Posted Prepmt Inv Nos and Posted Prepmt Cr Memo Nos in Sales and Receivable Setup with new created No Series.

        // [GIVEN] Create No Series with No Sereis Line, change the Posted Prepmt Inv Nos and Posted Prepmt Cr Memo Nos in
        // Sales and Receivable Setup create Payment Terms, create Sales Order with created Payment Terms.
        Initialize();
        PostedPrepmtInvNosInSetup(SalesReceivablesSetup, CreateNoSeriesWithLine());
        PostedPrepmtCrMemoNosInSetup(SalesReceivablesSetup, CreateNoSeriesWithLine());
        LibraryERM.CreatePaymentTerms(PaymentTerms);

        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);
        SalesOrderPrepaymentDueDate(SalesHeader, PaymentTerms.Code, LineGLAccount);

        // [WHEN] Create Setup for Sales Prepayment Account, post the Prepayment Sales Invoice and Prepayment Credit Memo.
        PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);

        // [THEN] Verify the Posted Prepmt Inv Nos and Posted Prepmt Cr Memo Nos with No Series.
        VerifyPrepaymentInvoice(SalesHeader."No.", SalesReceivablesSetup."Posted Prepmt. Inv. Nos.", '');
        VerifyPrepaymentCreditMemo(SalesHeader."No.", SalesReceivablesSetup."Posted Prepmt. Cr. Memo Nos.", '');

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankNoSeriesPrepaymentInvoice()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LineGLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Sales] [Series No]
        // [SCENARIO] Error on setting up the Posted Prepmt Inv Nos with blank in Sales and Receivable Setup.

        // [GIVEN] Attach the Posted Prepmt Inv Nos as blank in Sales and Receivable Setup, create Payment Terms, create Sales Order
        // with created Payment Terms.
        Initialize();
        SalesReceivablesSetup.Get();
        PrepmtInvNosBlankInSetup('');
        LibraryERM.CreatePaymentTerms(PaymentTerms);

        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);
        SalesOrderPrepaymentDueDate(SalesHeader, PaymentTerms.Code, LineGLAccount);
        // [WHEN] Create Setup for Sales Prepayment Account and Post the Prepayment Sales Invoice.
        asserterror PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Verify the Posted Sales Invoice No with No Series.
        Assert.IsTrue(GetLastErrorText = SpecifyInvNoSerieErr, UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentWithoutSetup()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO] Not setting up a Prepayment % on Customer and Item and check the "Prepayment %" on created Sales Header and Sales Line.

        // [GIVEN] Create a new Customer and Item.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItem(Item);

        // [WHEN] Create Sales Header, Sales Line for Item.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", Item."No.");

        // [THEN] Check that the Prepayment Percent on Sales Line and Sales Header.
        VerifyPrepaymentPercent(SalesHeader, SalesLine, Customer."Prepayment %", Customer."Prepayment %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroPercentOnPriceGroup()
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as boundary value 0 for Sales Type Customer Price Group.
        PercentOnPriceGroup(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HundredPercentOnPriceGroup()
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as boundary value 100 for Sales Type Customer Price Group.
        PercentOnPriceGroup(100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RandomPercentOnPriceGroup()
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as an integer value for Sales Type Customer Price Group.

        // Using Random Number Generator to get the random value of Prepayment Percent.
        PercentOnPriceGroup(LibraryRandom.RandDec(99, 5));
    end;

    local procedure PercentOnPriceGroup(PrepaymentPercent: Decimal)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentPct: Record "Sales Prepayment %";
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        // [GIVEN] Create a new Customer and Item, Create Customer Price Group, modify Customer, create Sales "Prepayment %" of Sales
        // [GIVEN] Type Customer Price Group and validate the "Prepayment %" of Sales "Prepayment %" as parameter.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItem(Item);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPrepaymentPriceGroup(Customer, CustomerPriceGroup.Code);
        CreatePrepayment(
          SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::"Customer Price Group",
          CustomerPriceGroup.Code, Item."No.", PrepaymentPercent);

        // [WHEN] Create Sales Header, Sales Line for Item.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", Item."No.");

        // [THEN] Check that the Prepayment % on Sales Line is same as defined on Sales Prepayment
        // and on Sales Header is same with Customer Prepayment Percent.
        VerifyPrepaymentPercent(SalesHeader, SalesLine, Customer."Prepayment %", SalesPrepaymentPct."Prepayment %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroPercentItemAllCustomer()
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as boundary value 0 for Sales Type All Customer.
        PercentItemAllCustomer(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HundredPercentItemAllCustomer()
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as boundary value 100 for Sales Type All Customer.
        PercentItemAllCustomer(100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RandomPercentItemAllCustomer()
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as an integer value for Sales Type All Customer.
        // Using Random Number Generator to get the random value of Prepayment Percent.
        PercentItemAllCustomer(LibraryRandom.RandInt(100));
    end;

    local procedure PercentItemAllCustomer(PrepaymentPercent: Integer)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentPct: Record "Sales Prepayment %";
    begin
        // [GIVEN] Create new Customer and Item. Create Sales Prepayment and Validate Prepayment %
        // [GIVEN] as parameter with 5 decimal places for Sales Type All Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItem(Item);
        CreatePrepayment(SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::"All Customers", '', Item."No.", PrepaymentPercent);

        // [WHEN] Create Sales Header, Sales Line for Item.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", Item."No.");

        // [THEN] Check that the Prepayment % on Sales Line is same as defined on Sales Prepayment Percent
        // and on Sales Header is same with Customer Prepayment Percent.
        VerifyPrepaymentPercent(SalesHeader, SalesLine, Customer."Prepayment %", SalesPrepaymentPct."Prepayment %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPrepaymentSetup()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PrepmtLineAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO 128389] Not setting up "Prepayment %" on Item and check "Prepayment %" on created Sales Header and Sales Line and Post the Prepayment Invoice.

        // [GIVEN] Create a new Customer and Item, modify Prepayment Percent in Customer.
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        CreateItem(Item);

        // Using Random Number Generator for the random value of Prepayment Percent in Customer.
        PrepaymentPercentInCustomer(Customer, LibraryRandom.RandDec(99, 5));

        // [WHEN] Create Sales Header, Sales Line for Item.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", Item."No.");
        PrepmtLineAmount := SalesLine."Prepmt. Line Amount";
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Check that the Prepayment Percent on Sales Line and Sales Header, check the Prepmt Line Amount, Prepmt Amt to Deduct,
        // Prepmt Amt Inv in Sales Line, check the corresponding GL Entry,VAT Entry, Customer Ledger Entry,
        // Detailed Customer Ledger Entry.
        VerifyPrepaymentPercent(SalesHeader, SalesLine, Customer."Prepayment %", Customer."Prepayment %");
        VerifyPrepaymentAmount(SalesHeader."No.", PrepmtLineAmount);
        asserterror VerifyLedgerEntries(SalesHeader."No.", PrepmtLineAmount, SalesHeader."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroPrepaymentPercentOnItem()
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as a decimal value with 5 decimal places in Customer and Boundary value zero for Item.

        // Using Random Number Generator for Prepayment Percent.
        Initialize();
        SetupPrepaymentOnItemCustomer(LibraryRandom.RandDec(99, 5), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PercentOnItemLessThanCustomer()
    var
        PrepaymentPercent: Decimal;
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as a decimal value with 5 decimal places in Customer and one less than Customer "Prepayment %" for Item.

        // Using Random Number Generator for Prepayment Percent.
        Initialize();
        PrepaymentPercent := LibraryRandom.RandDec(99, 5);
        SetupPrepaymentOnItemCustomer(PrepaymentPercent, PrepaymentPercent - LibraryUtility.GenerateRandomFraction());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PercentOnItemMoreThanCustomer()
    var
        PrepaymentPercent: Decimal;
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as a decimal value with 5 decimal places in Customer and one more than Customer "Prepayment %" for Item.

        // Using Random Number Generator for Prepayment Percent.
        Initialize();
        PrepaymentPercent := LibraryRandom.RandDec(99, 5);
        SetupPrepaymentOnItemCustomer(PrepaymentPercent, PrepaymentPercent + LibraryUtility.GenerateRandomFraction());
    end;

    local procedure SetupPrepaymentOnItemCustomer(PrepaymentPercent: Decimal; PrepaymentPercent2: Decimal)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentPct: Record "Sales Prepayment %";
    begin
        // [GIVEN] Create new Customer and Item. Create Sales Prepayment and Validate Sales Prepayment Percent and "Prepayment %" for
        // Customer as the parameters for Sales Type Customer.
        LibrarySales.CreateCustomer(Customer);
        PrepaymentPercentInCustomer(Customer, PrepaymentPercent);
        CreateItem(Item);
        CreatePrepayment(SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::Customer, Customer."No.", Item."No.", PrepaymentPercent2);

        // [WHEN] Create Sales Header, Sales Line for Item.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", SalesPrepaymentPct."Item No.");

        // [THEN] Check that the Prepayment % on Sales Line is same as defined on Sales Prepayment
        // and on Sales Header is same with Customer Prepayment Percent.
        VerifyPrepaymentPercent(SalesHeader, SalesLine, Customer."Prepayment %", SalesPrepaymentPct."Prepayment %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroPercentOnItemPriceGroup()
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as a decimal value with 5 decimal places in Customer and zero "Prepayment %" for Item.

        // Using Random Number Generator for Prepayment Percent.
        Initialize();
        PercentOnItemAndPriceGroup(LibraryRandom.RandDec(99, 5), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PercentOnItemLessPriceGroup()
    var
        PrepaymentPercent: Decimal;
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as a decimal value with 5 decimal places in Customer and "Prepayment %" for Item less than Customer.

        // Using Random Number Generator for Prepayment Percent.
        Initialize();
        PrepaymentPercent := LibraryRandom.RandDec(99, 5);
        PercentOnItemAndPriceGroup(PrepaymentPercent, PrepaymentPercent - LibraryUtility.GenerateRandomFraction());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PercentOnItemMorePriceGroup()
    var
        PrepaymentPercent: Decimal;
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO] Setting up a Prepayment % as a decimal value with 5 decimal places in Customer and "Prepayment %" for Item more than Customer.

        // Using Random Number Generator for Prepayment Percent.
        Initialize();
        PrepaymentPercent := LibraryRandom.RandDec(99, 5);
        PercentOnItemAndPriceGroup(PrepaymentPercent, PrepaymentPercent + LibraryUtility.GenerateRandomFraction());
    end;

    local procedure PercentOnItemAndPriceGroup(PrepaymentPercent: Decimal; PrepaymentPercent2: Decimal)
    var
        Customer: Record Customer;
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentPct: Record "Sales Prepayment %";
    begin
        // [GIVEN] Create new Customer and Item, create Customer Price Group, modify Customer Price Group and Prepayment Percent
        // of Customer, create Sales Prepayment for Sales Type Customer Price Group and validate Prepayment % as the parameter.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPrepaymentPriceGroup(Customer, CustomerPriceGroup.Code);
        PrepaymentPercentInCustomer(Customer, PrepaymentPercent);
        CreateItem(Item);
        CreatePrepayment(
          SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::"Customer Price Group",
          CustomerPriceGroup.Code, Item."No.", PrepaymentPercent2);

        // [WHEN] Create Sales Header, Sales Line for Item.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", SalesPrepaymentPct."Item No.");

        // [THEN] Check that the Prepayment % on Sales Line is same as defined on Sales Prepayment
        // and on Sales Header is same with Customer Prepayment Percent.
        VerifyPrepaymentPercent(SalesHeader, SalesLine, Customer."Prepayment %", SalesPrepaymentPct."Prepayment %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroPercentOnItemAllCustomer()
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO 128383] Setting up a Prepayment % as a decimal value with 5 decimal places in Customer and zero "Prepayment %" for Item (all Customers).

        // Using Random Number Generator for Prepayment Percent.
        Initialize();
        PercentOnItemAndAllCustomer(LibraryRandom.RandDec(99, 5), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PercentOnItemLessAllCustomer()
    var
        PrepaymentPercent: Decimal;
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO 128384] Setting up a Prepayment % as a decimal value with 5 decimal places in Customer and "Prepayment %" for Item less than all Customers.

        // Using Random Number Generator for Prepayment Percent.
        Initialize();
        PrepaymentPercent := LibraryRandom.RandDec(99, 5);
        PercentOnItemAndAllCustomer(PrepaymentPercent, PrepaymentPercent - LibraryUtility.GenerateRandomFraction());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PercentOnItemMoreAllCustomer()
    var
        PrepaymentPercent: Decimal;
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO 128384] Setting up a Prepayment % as a decimal value with 5 decimal places in Customer and "Prepayment %" for Item more than all Customers.

        // Using Random Number Generator for Prepayment Percent.
        Initialize();
        PrepaymentPercent := LibraryRandom.RandDec(99, 5);
        PercentOnItemAndAllCustomer(PrepaymentPercent, PrepaymentPercent + LibraryUtility.GenerateRandomFraction());
    end;

    local procedure PercentOnItemAndAllCustomer(PrepaymentPercent: Decimal; PrepaymentPercent2: Decimal)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentPct: Record "Sales Prepayment %";
    begin
        // [GIVEN] Create new Customer and Item, modify Prepayment Percent of Customer as the parameter, Create Sales Prepayment
        // for Sales Type All Customer, and validate Prepayment % as the parameter.
        LibrarySales.CreateCustomer(Customer);
        PrepaymentPercentInCustomer(Customer, PrepaymentPercent);
        CreateItem(Item);
        CreatePrepayment(SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::"All Customers", '', Item."No.", PrepaymentPercent2);

        // [WHEN] Create Sales Header, Sales Line for Item.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", SalesPrepaymentPct."Item No.");

        // [THEN] Check that the Prepayment % on Sales Line is same as defined on Sales Prepayment
        // and on Sales Header is same with Customer Prepayment Percent.
        VerifyPrepaymentPercent(SalesHeader, SalesLine, Customer."Prepayment %", SalesPrepaymentPct."Prepayment %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MorePercentageThanCustomer()
    var
        PrepaymentPercent: Decimal;
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO 128385] "Prepayment %" in Sales Header and Line with "Sales Prepayment %" more than "Prepayment %" of Sales Type Customer.

        // Using Random Number Generator for Prepaymnet Percent.
        Initialize();
        PrepaymentPercent := LibraryRandom.RandDec(99, 5);
        PercentPriceGroupAndCustomer(PrepaymentPercent, PrepaymentPercent + LibraryUtility.GenerateRandomFraction());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LessPercentageThanCustomer()
    var
        PrepaymentPercent: Decimal;
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO 128385] "Prepayment %" in Sales Header and Line with "Sales Prepayment %" less than "Prepayment %" of Sales Type Customer.

        // Using Random Number Generator for Prepaymnet Percent.
        Initialize();
        PrepaymentPercent := LibraryRandom.RandDec(99, 5);
        PercentPriceGroupAndCustomer(PrepaymentPercent, PrepaymentPercent - LibraryUtility.GenerateRandomFraction());
    end;

    local procedure PercentPriceGroupAndCustomer(PrepaymentPercent: Decimal; PrepaymentPercent2: Decimal)
    var
        Customer: Record Customer;
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentPct: Record "Sales Prepayment %";
    begin
        // [GIVEN] Create new Customer and Item, modify Prepayment Percent of Customer as the parameter, Create Sales Prepayment
        // for Sales Type Customer and Customer Price Group, and validate Prepayment % as the parameter.
        LibrarySales.CreateCustomer(Customer);
        PrepaymentPercentInCustomer(Customer, PrepaymentPercent);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPrepaymentPriceGroup(Customer, CustomerPriceGroup.Code);
        CreateItem(Item);

        // Using Random Number Generator for Prepayment Percent.
        CreatePrepayment(SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::Customer, Customer."No.", Item."No.", PrepaymentPercent2);
        CreatePrepayment(
          SalesPrepaymentPct,
          SalesPrepaymentPct."Sales Type"::"Customer Price Group",
          CustomerPriceGroup.Code, SalesPrepaymentPct."Item No.", PrepaymentPercent2 + LibraryRandom.RandInt(5));

        // [WHEN] Create Sales Header, Sales Line for Item.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", SalesPrepaymentPct."Item No.");

        // [THEN] Check that the Prepayment % on Sales Line is same as defined on Sales Prepayment
        // and on Sales Header is same with Customer Prepayment Percent.
        VerifyPrepaymentPercent(SalesHeader, SalesLine, Customer."Prepayment %", PrepaymentPercent2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MorePercentageForAllCustomer()
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO 128386] "Prepayment %" in Sales Header and Line with "Sales Prepayment %" of All Customer more than "Prepayment %" of Sales Type Customer.

        // Using Random Number Generator for Prepaymnet Percent.
        PrepaymentPercentOfAllCustomer(LibraryRandom.RandDec(99, 5) + LibraryUtility.GenerateRandomFraction());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LessPercentageForAllCustomer()
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO 128386] "Prepayment %" in Sales Header and Line with "Sales Prepayment %" of All Customer less than "Prepayment %" of Sales Type Customer.

        // Using Random Number Generator for Prepaymnet Percent.
        PrepaymentPercentOfAllCustomer(LibraryRandom.RandDec(99, 5) - LibraryUtility.GenerateRandomFraction());
    end;

    local procedure PrepaymentPercentOfAllCustomer(PrepaymentPercent: Decimal)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentPct: Record "Sales Prepayment %";
    begin
        // [GIVEN] Create new Customer and Item, modify Prepayment Percent of Customer as the parameter, Create Sales Prepayment
        // for Sales Type Customer and All Customer, and validate Prepayment % as the parameter.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItem(Item);

        // Using Random Number Generator for Prepaymnet Percent.
        CreatePrepayment(SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::Customer, Customer."No.", Item."No.", PrepaymentPercent);
        CreatePrepayment(
          SalesPrepaymentPct,
          SalesPrepaymentPct."Sales Type"::"All Customers",
          '', SalesPrepaymentPct."Item No.", PrepaymentPercent + LibraryRandom.RandInt(5));

        // [WHEN] Create Sales Header, Sales Line for Item.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", SalesPrepaymentPct."Item No.");

        // [THEN] Check that the Prepayment % on Sales Line is same as defined on Sales Prepayment
        // and on Sales Header is same with Customer Prepayment Percent.
        VerifyPrepaymentPercent(SalesHeader, SalesLine, Customer."Prepayment %", PrepaymentPercent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MorePercentageThanPriceGroup()
    var
        PrepaymentPercent: Decimal;
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO 128387] "Prepayment %" in Sales Header and Line with "Sales Prepayment %" of All Customer more than "Prepayment %" of Sales Type Customer Price Group

        // Using Random Number Generator for Prepaymnet Percent.
        Initialize();
        PrepaymentPercent := LibraryRandom.RandDec(99, 5);
        PercentageAllAndPriceGroup(PrepaymentPercent, PrepaymentPercent + LibraryUtility.GenerateRandomFraction());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LessPercentageThanPriceGroup()
    var
        PrepaymentPercent: Decimal;
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO 128387] "Prepayment %" in Sales Header and Line with "Sales Prepayment %" of All Customer less than "Prepayment %" of Sales Type Customer Price Group

        // Using Random Number Generator for Prepaymnet Percent.
        Initialize();
        PrepaymentPercent := LibraryRandom.RandDec(99, 5);
        PercentageAllAndPriceGroup(PrepaymentPercent, PrepaymentPercent - LibraryUtility.GenerateRandomFraction());
    end;

    local procedure PercentageAllAndPriceGroup(PrepaymentPercent: Decimal; PrepaymentPercent2: Decimal)
    var
        Customer: Record Customer;
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentPct: Record "Sales Prepayment %";
    begin
        // [GIVEN] Create new Customer and Item, modify Prepayment Percent of Customer as the parameter, Create Sales Prepayment
        // for Sales Type Customer Price Group and All Customers, and validate Prepayment % as the parameter.
        LibrarySales.CreateCustomer(Customer);
        PrepaymentPercentInCustomer(Customer, PrepaymentPercent);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPrepaymentPriceGroup(Customer, CustomerPriceGroup.Code);
        CreateItem(Item);

        // Using Random Number Generator for Prepaymnet Percent.
        CreatePrepayment(
          SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::"Customer Price Group",
          CustomerPriceGroup.Code, Item."No.", PrepaymentPercent2);
        CreatePrepayment(
          SalesPrepaymentPct,
          SalesPrepaymentPct."Sales Type"::"All Customers",
          '', SalesPrepaymentPct."Item No.", PrepaymentPercent2 + LibraryRandom.RandInt(5));

        // [WHEN] Create Sales Header, Sales Line for Item.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", SalesPrepaymentPct."Item No.");

        // [THEN] Check that the Prepayment % on Sales Line is same as defined on Sales Prepayment
        // and on Sales Header is same with Customer Prepayment Percent.
        VerifyPrepaymentPercent(SalesHeader, SalesLine, Customer."Prepayment %", PrepaymentPercent2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceItemSetup()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentPct: Record "Sales Prepayment %";
        PrepmtLineAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO 128390] Sales Prepayment Invoice using Item setup.

        // [GIVEN] Create a new Customer and Item. Create Sales Prepayment of Sales Type Customer with random Prepayment Percent.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateItem(Item);
        CreatePrepayment(
          SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::Customer, Customer."No.", Item."No.", LibraryRandom.RandDec(99, 5));

        // [WHEN] Create Sales Header, Sales Line for Item, create the Sales Order and post the Sales Invoice Prepayment.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", SalesPrepaymentPct."Item No.");
        PrepmtLineAmount := SalesLine."Prepmt. Line Amount";
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Check the Prepmt Line Amount, Prepmt Amt to Deduct, Prepmt Amt Inv in Sales Line, check the corresponding GL Entry,
        // VAT Entry, Customer Ledger Entry, Detailed Customer Ledger Entry.
        VerifyPrepaymentAmount(SalesHeader."No.", PrepmtLineAmount);
        asserterror VerifyLedgerEntries(SalesHeader."No.", PrepmtLineAmount, SalesHeader."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceBothSetup()
    var
        Customer: Record Customer;
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        SalesPrepaymentPct: Record "Sales Prepayment %";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PrepmtLineAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO 128391] Sales Prepayment Invoice for the both Item and Customer Prepayment Setup.

        // [GIVEN] Create new Customer and Item, create Customer Price Group, modify Customer Price Group and Prepayment Percent
        // of Customer, create Sales Prepayment for Sales Type Customer Price Group and validate Prepayment.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPrepaymentPriceGroup(Customer, CustomerPriceGroup.Code);
        PrepaymentPercentInCustomer(Customer, LibraryRandom.RandDec(99, 5));
        CreateItem(Item);

        // Using Random Number Generator for Prepayment Percent.
        CreatePrepayment(
          SalesPrepaymentPct,
          SalesPrepaymentPct."Sales Type"::"Customer Price Group",
          CustomerPriceGroup.Code, Item."No.", Customer."Prepayment %" - LibraryUtility.GenerateRandomFraction());

        // [WHEN] Create Sales Header, Sales Line for Item, post the Prepayment Sales Invoice.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", SalesPrepaymentPct."Item No.");
        PrepmtLineAmount := SalesLine."Prepmt. Line Amount";
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Check the Prepmt Line Amount, Prepmt Amt to Deduct, Prepmt Amt Inv in Sales Line, check the corresponding GL Entry,
        // VAT Entry, Customer Ledger Entry, Detailed Customer Ledger Entry.
        VerifyPrepaymentAmount(SalesHeader."No.", PrepmtLineAmount);
        asserterror VerifyLedgerEntries(SalesHeader."No.", PrepmtLineAmount, SalesHeader."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceItemSetups()
    var
        Customer: Record Customer;
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentPct: Record "Sales Prepayment %";
        PrepmtLineAmount: Decimal;
        PrepaymentPercent: Decimal;
        PrepaymentPercent2: Decimal;
    begin
        // [FEATURE] [Sales] [Sales Prepayment %]
        // [SCENARIO 128392] Prepayment Invoice using combinations of Item Setup.

        // [GIVEN] Create new Customer and Item, modify Prepayment Percent of Customer, create Customer Price Group, modify the customer
        // Create Sales Prepayment for Sales Type Customer Price Group and All Customers and validate Prepayment Percent.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        PrepaymentPercent := LibraryRandom.RandDec(99, 5);  // Using Random Number Generator for Prepayment Percent.
        PrepaymentPercent2 := PrepaymentPercent - LibraryUtility.GenerateRandomFraction();
        PrepaymentPercentInCustomer(Customer, PrepaymentPercent);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPrepaymentPriceGroup(Customer, CustomerPriceGroup.Code);
        CreateItem(Item);

        // Using Random Number Generator for Prepaymnet Percent.
        CreatePrepayment(
          SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::"Customer Price Group",
          CustomerPriceGroup.Code, Item."No.", PrepaymentPercent2);
        CreatePrepayment(
          SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::"All Customers",
          '', SalesPrepaymentPct."Item No.", PrepaymentPercent2 + LibraryRandom.RandInt(5));

        // [WHEN] Create Sales Header, Sales Line for created Item, post the Sales Prepayment invoice.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", SalesPrepaymentPct."Item No.");
        PrepmtLineAmount := SalesLine."Prepmt. Line Amount";
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Check the Prepmt Line Amount, Prepmt Amt to Deduct, Prepmt Amt Inv in Sales Line, check the corresponding GL Entry,
        // VAT Entry, Customer Ledger Entry, Detailed Customer Ledger Entry.
        VerifyPrepaymentAmount(SalesHeader."No.", PrepmtLineAmount);
        asserterror VerifyLedgerEntries(SalesHeader."No.", PrepmtLineAmount, SalesHeader."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentOfMultipleGLAccounts()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 128393] Prepayment Invoice with three different sales GL Posting Account.

        // [GIVEN] Create Sales Order with 3 sales lines and create General Posting Setup.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine);
        FindSalesLine(SalesLine, SalesHeader);

        // [WHEN] Post the Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Verify the Prepayment Amount in Sales Invoice Line and GL, VAT, Customer, Detailed Customer Ledger Entries.
        VerifyPrepaymentAmounts(SalesLine, SalesHeader."No.");
        VerifyLedgerEntriesByBusPostingGroup(SalesHeader."No.", CalculateTotalPrepaymentAmount(SalesHeader), SalesHeader."Posting Date");

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('CurrencyConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceWithCurrency()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [FCY]
        // [SCENARIO 128394] Prepayment Invoice with a currency code.

        // [GIVEN] Create Sales Order with 3 sales lines, attach a currency with Sales order and create General Posting Setup.
        Initialize();

        CreateSalesDocument(SalesHeader, SalesLine);
        CurrencyInSalesHeader(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader);

        // [WHEN] Post the Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Verify the Prepayment Amount in Sales Invoice Line and GL, VAT, Customer, Detailed Customer Ledger Entries.
        VerifyPrepaymentAmounts(SalesLine, SalesHeader."No.");
        VerifyLedgerEntriesForCurrency(SalesHeader);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('PrepaymentConfirmHandler')]
    [Scope('OnPrem')]
    procedure RegretPostPrepayment()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentPct: Record "Sales Prepayment %";
        SalesPostPrepaymentYesNo: Codeunit "Sales-Post Prepayment (Yes/No)";
        PrepaymentPercent: Decimal;
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 128395] Regret to Post Prepayment.

        // [GIVEN] Create new Customer and Item, modify Customer Prepayment Percent, Create Sales Prepayment and Validate
        // Sales Prepayment Percent and "Prepayment %" for Sales Type Customer.
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        PrepaymentPercent := LibraryRandom.RandDec(99, 5);
        PrepaymentPercentInCustomer(Customer, PrepaymentPercent);
        CreateItem(Item);
        CreatePrepayment(
          SalesPrepaymentPct,
          SalesPrepaymentPct."Sales Type"::Customer, Customer."No.", Item."No.", PrepaymentPercent + LibraryUtility.GenerateRandomFraction());

        // [WHEN] Create Sales Header, Sales Line for Item and post the Sales Prepayment Invoice with No option.
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, Customer."No.", SalesPrepaymentPct."Item No.");
        SalesPostPrepaymentYesNo.PostPrepmtInvoiceYN(SalesHeader, false);

        // [THEN] Check the Sales Prepayment Invoice.
        VerifySalesPrepaymentInvoice(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrpmtInvoiceWithCompressPrpmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PrepmtAccNo: Code[20];
    begin
        // [FEATURE] [Sales] [Compress Prepayment]
        // [SCENARIO 128398] Prepayment Invoice with Compress Prepayment False in Sales Order.

        // [GIVEN] Change the Posted Prepmt Inv Nos and Posted Prepmt Cr Memo Nos in Sales and Receivable Setup, create Payment Terms,
        // create Sales Order with created payment terms.
        Initialize();

        PrepmtAccNo := CreateSalesDocument(SalesHeader, SalesLine);
        CompressPrepaymentInSalesOrder(SalesHeader);

        // [WHEN] Post the Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Check the GL Entries.
        VerifyGLEntries(SalesHeader."No.", PrepmtAccNo);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrpmtInvoiceWithCompressPrpmtManyLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PrepmtAccNo: Code[20];
    begin
        // [FEATURE] [Sales] [Compress Prepayment]
        // [SCENARIO 409617] Int overfow by Prepayment Invoice with Compress Prepayment False in Sales Order with 655 lines.

        // [GIVEN] Change the Posted Prepmt Inv Nos and Posted Prepmt Cr Memo Nos in Sales and Receivable Setup, create Payment Terms,
        Initialize();

        // [GIVEN] create Sales Order of 655+ lines with created payment terms
        PrepmtAccNo := CreateSalesDocument(SalesHeader, SalesLine, 666);
        CompressPrepaymentInSalesOrder(SalesHeader);

        // [WHEN] Post the Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Check the GL Entries.
        VerifyGLEntries(SalesHeader."No.", PrepmtAccNo);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrpmtInvoiceWithCompressPrpmtManyLines()
    var
        PurchHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PrepmtAccNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Compress Prepayment]
        // [SCENARIO 409617] Int overfow by Prepayment Invoice with Compress Prepayment False in Purch Order with 655 lines.

        // [GIVEN] Change the Posted Prepmt Inv Nos and Posted Prepmt Cr Memo Nos in Purch Setup, create Payment Terms,
        Initialize();

        // [GIVEN] create Purchase Order of 655+ lines with created payment terms
        PrepmtAccNo := CreatePurchDocument(PurchHeader, PurchaseLine, 666);
        CompressPrepaymentInPurchOrder(PurchHeader);

        // [WHEN] Post the Prepayment Invoice.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);

        // [THEN] Check the GL Entries.
        VerifyPurchGLEntries(PurchHeader."No.", PrepmtAccNo);

        // Tear down
        TearDownVATPostingSetup(PurchHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddDecimalPrepaymentPercent()
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO 128404] "Prepayment %" in Sales Line with addition of a decimal value in "Prepayment %".
        ChangePrepaymentPercent(LibraryUtility.GenerateRandomFraction());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddZeroPrepaymentPercent()
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO 128404] "Prepayment %" in Sales Line with addition of a zero in "Prepayment %".
        ChangePrepaymentPercent(0);
    end;

    local procedure ChangePrepaymentPercent(PrepaymentPercent: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
    begin
        // [GIVEN] Create a new Sales Order, change the Line Discount Percent in Sales Line,change the Prepayment Percent in Sales lines.
        Initialize();
        CreateSalesDocumentItemSetup(SalesHeader, SalesLine);
        ChangeLineDiscPercentSalesLine(SalesLine, SalesHeader);
        CopySalesLine(TempSalesLine, SalesLine, SalesHeader);
        PrepaymentPercentInSalesLine(SalesLine, PrepaymentPercent);

        // [WHEN] Post the Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Check the Prepayment Percent in Sales line, Prepayment Amount and check the Ledger Entries.
        VerifyPrepaymentPercentInLines(TempSalesLine, SalesLine, PrepaymentPercent);
        VerifyPrepaymentAmounts(SalesLine, SalesHeader."No.");
        VerifyLedgerEntriesByBusPostingGroup(SalesHeader."No.", CalculateTotalPrepaymentAmount(SalesHeader), SalesHeader."Posting Date");

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyVATProductPostingGroup()
    var
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NewVATProdPostingGr: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [VAT]
        // [SCENARIO 128406] Changed VAT Prod Posting Group on Sales Line.

        // [GIVEN] Create a Sales Order, create an Item, create a Customer with new posting setup, change the Prepayement Percent in Sales
        // Line, change the VAT Prod. Posting Group in Sales Line.
        Initialize();

        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        CreateSalesDocumentPrepayment(
          SalesHeader, SalesLine, CreateCustomerWithVAT(LineGLAccount."VAT Bus. Posting Group"),
          CreateItemVATProdPostingGroup(LineGLAccount."VAT Prod. Posting Group"));
        UpdateGeneralPostingSetupInGL(SalesLine);
        FindSalesLine(SalesLine, SalesHeader);
        PrepaymentPercentInSalesLine(SalesLine, LibraryRandom.RandDec(99, 5));
        NewVATProdPostingGr := LibraryERM.CreateRelatedVATPostingSetup(LineGLAccount);
        SalesLine.Validate("VAT Prod. Posting Group", NewVATProdPostingGr);
        SalesLine.Modify(true);

        // [WHEN] Post the Prepayment Invoice and post the Sales Order as Ship and Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify GL Account.
        VerifyGLAccountForVAT(SalesLine);
        VerifyGLAccountForNewVAT(SalesLine, InvoiceNo);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePrepaymentPercentHeader()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PrepaymentPercent: Decimal;
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO 128407] Changed "Prepayment %" on Sales Line after changing "Prepayment %" on Sales Header.

        // [GIVEN] Create a Sales Order with new General Posting Setup, modify the prepayment percent in Sales Header,
        // find the Sales Line.
        Initialize();

        CreateSalesDocumentItemSetup(SalesHeader, SalesLine);
        PrepaymentPercent := PrepaymentPercentInSalesHeader(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader);

        // [WHEN] Post the Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Checks the Prepayment Percent and Prepayment Line Amount, checks the Ledger Entries.
        VerifyPrepmtAmountOnSalesLine(SalesHeader, PrepaymentPercent);
        VerifyPrepaymentAmounts(SalesLine, SalesHeader."No.");
        VerifyLedgerEntriesByBusPostingGroup(SalesHeader."No.", CalculateTotalPrepaymentAmount(SalesHeader), SalesHeader."Posting Date");

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('CurrencyConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCustomerOnHeader()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO 128408] "Prepayment %" on Sales Line after changing the Customer on Sales Header.

        // [GIVEN] Create a Sales Order with new General Posting Setup, modify the Customer in Sales Header, find the Sales Line.
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());

        CreateSalesDocumentItemSetup(SalesHeader, SalesLine);
        CreateCustomerNotPrepayment(Customer, SalesHeader."Gen. Bus. Posting Group", SalesHeader."VAT Bus. Posting Group");
        ChangeCustomerOnHeader(SalesHeader, Customer."No.");
        FindSalesLine(SalesLine, SalesHeader);

        // [WHEN] Post the Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Checks the Prepayment Percent in Sales Header and Sales Line, checks the Prepayment Line Amount, checks the
        // Ledger Entries.
        VerifyPrepaymentOnOrder(SalesHeader);
        VerifyPrepaymentAmounts(SalesLine, SalesHeader."No.");
        VerifyLedgerEntriesByBusPostingGroup(SalesHeader."No.", CalculateTotalPrepaymentAmount(SalesHeader), SalesHeader."Posting Date");

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('CurrencyConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCustomerOnHeaderTwice()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO 128408] "Prepayment %" on Sales Line after changing the Customer on Sales Header twice.

        // [GIVEN] Create a Sales Order with new General Posting Setup, modify the customer in Sales Header, again modify the Customer in
        // Sales Header with old Customer, find the Sales Lines.
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        CreateSalesDocumentItemSetup(SalesHeader, SalesLine);
        CustomerNo := SalesHeader."Sell-to Customer No.";
        CopySalesLine(TempSalesLine, SalesLine, SalesHeader);
        CreateCustomerNotPrepayment(Customer, SalesHeader."Gen. Bus. Posting Group", SalesHeader."VAT Bus. Posting Group");
        ChangeCustomerOnHeader(SalesHeader, Customer."No.");
        ChangeCustomerOnHeader(SalesHeader, CustomerNo);
        FindSalesLine(SalesLine, SalesHeader);

        // [WHEN] Post the Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Checks the Prepayment Percent and Prepayment Line Amount in Sales Line, check the Ledger Entries.
        VerifyPrepaymentPercentInLines(TempSalesLine, SalesLine, 0);
        VerifyPrepaymentAmounts(SalesLine, SalesHeader."No.");
        VerifyLedgerEntriesByBusPostingGroup(SalesHeader."No.", CalculateTotalPrepaymentAmount(SalesHeader), SalesHeader."Posting Date");

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePrepaymentError()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Prepayment Amount]
        // [SCENARIO 128413] An error while updating "Prepayment Line Amount" with smaller amount.

        // [GIVEN]
        Initialize();

        // [WHEN] Post a Prepayment Invoice and Update Prepayment Line Amount.
        PostCustomerPrepaymentInvoice(SalesHeader, SalesLine);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        asserterror UpdatePrepaymentLineAmount(SalesLine, SalesLine."Prepmt. Line Amount" - LibraryRandom.RandDec(10, 2));

        // [THEN] Verify that Application throws an error while changing Prepayment Line Amount less than posted one after Reopen.
        Assert.AreEqual(
          StrSubstNo(
            PrepaymentErr, SalesLine.FieldCaption("Prepmt. Line Amount"),
            SalesLine."Prepmt. Line Amount", SalesLine.TableName, SalesLine.FieldName("Document Type"),
            SalesLine."Document Type", SalesLine.FieldName("Document No."), SalesLine."Document No.", SalesLine.FieldName("Line No."),
            SalesLine."Line No."),
          GetLastErrorText, UnknownErr);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSecondPrepaymentInvoice()
    var
        SalesLine: Record "Sales Line";
        PostedSaleInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Prepayment Amount]
        // [SCENARIO 128413] Prepayment Line Amount updated correctly after posting more than one Prepayment Invoice.

        // [GIVEN]
        Initialize();

        // [WHEN] Post two Prepayment Invoices.
        PostTwoPrepaymentInvoices(SalesLine);
        PostedSaleInvoiceNo := FindSalesPrepmtInvoiceNo(SalesLine."Document No.");

        // [THEN] Verify that Prepayment Line Amount updated correctly.
        SalesLine.TestField("Prepmt. Amt. Inv.", CalculateInvoiceLineAmount(PostedSaleInvoiceNo));

        // Tear down
        TearDownVATPostingSetup(SalesLine."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPrepaymentOrder()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Prepayment Amount]
        // [SCENARIO 128415] An error while updating Prepayment Amount to Deduct after Order Post.

        // [WHEN] Check Application throws an error while updating Prepayment Amount to Deduct.
        Initialize();

        PostFinalPrepaymentOrder(SalesLine);
        asserterror UpdatePrepaymentAmountToDeduct(SalesLine, SalesLine."Prepmt Amt to Deduct" + LibraryRandom.RandDec(1, 2));

        // [THEN] Verify that Update Prepayment Amount To Deduct, updated correctly in Sales Line.
        Assert.AreEqual(
          StrSubstNo(
            PostPrepaymentErr, SalesLine.FieldCaption("Prepmt Amt to Deduct"),
            SalesLine."Prepayment Amount" - SalesLine."Prepmt Amt to Deduct", SalesLine.TableName, SalesLine.FieldName("Document Type"),
            SalesLine."Document Type", SalesLine.FieldName("Document No."), SalesLine."Document No.", SalesLine.FieldName("Line No."),
            SalesLine."Line No."),
          GetLastErrorText, UnknownErr);

        // Tear down
        TearDownVATPostingSetup(SalesLine."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPrepaymentOrderWithZero()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Prepayment Amount]
        // [SCENARIO 128415] An error while updating Prepayment Amount to Deduct with Zero after Order Post.

        // [WHEN] Check Application throws an error while updating Prepayment Amount to Deduct with Zero.
        Initialize();

        PostFinalPrepaymentOrder(SalesLine);

        // [THEN] Verify that Update Prepayment Amount To Deduct, updated correctly in Sales Line.
        asserterror UpdatePrepaymentAmountToDeduct(SalesLine, 0);

        // Tear down
        TearDownVATPostingSetup(SalesLine."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyPrepaymentInvoiceSalesUnrealizedVAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedInvoiceNo: Code[20];
        GenJnlLineDocNo: Code[20];
    begin
        // [SCENARIO] Check Apply payment against Prepayment Sales Invoice with Unrealized VAT.
        Initialize();

        LibraryERM.SetUnrealizedVAT(true);

        // [GIVEN] Post Prepayment Sales Invoice with unrealized VAT.
        PostedInvoiceNo := CreateAndPostPrepaymentSalesInvoice(SalesHeader);
        // [GIVEN] Post a payment.
        GenJnlLineDocNo := CreateAndPostGenJournalLineCustomer(SalesHeader);

        // [WHEN] Applying prepayment invoice to payment.
        ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Invoice, CustLedgerEntry."Document Type"::Payment, PostedInvoiceNo, GenJnlLineDocNo);
        // [THEN] Transaction No of Detailed customer ledger must be filled.
        TransNoIsNotZeroInDtldCustLedgEntries(PostedInvoiceNo);

        // [WHEN] Unapplying prepayment invoice.
        UnapplyInvoiceCust(SalesHeader."Sell-to Customer No.", PostedInvoiceNo);
        // [THEN] Remaining Unrealized Amount of VAT Entry must be restored.
        VerifyVATEntries(PostedInvoiceNo);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyPrepaymentInvoicePurcUnrealizedVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PostedInvoiceNo: Code[20];
        GenJnlLineDocNo: Code[20];
    begin
        // [SCENARIO] Check Apply payment against Prepayment Purchase Invoice with Unrealized VAT.
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);

        // [GIVEN] Post Prepayment Purchase Invoice with unrealized VAT.
        PostedInvoiceNo := CreateAndPostPrepaymentPurchaseInvoice(PurchaseHeader);
        // [GIVEN] Post a payment.
        GenJnlLineDocNo := CreateAndPostGenJournalLineVendor(PurchaseHeader);

        // [WHEN] Applying prepayment invoice to payment.
        ApplyVendorLedgerEntries(VendorLedgerEntry."Document Type"::Invoice, VendorLedgerEntry."Document Type"::Payment,
          PostedInvoiceNo, GenJnlLineDocNo);
        // [THEN] Transaction No of Detailed vendor ledger must be filled.
        TransNoIsNotZeroInDtldVendLedgEntries(PostedInvoiceNo);

        // [WHEN] Unapplying prepayment invoice.
        UnapplyInvoiceVend(PurchaseHeader."Buy-from Vendor No.", PostedInvoiceNo);
        // [THEN] Remaining Unrealized Amount of VAT Entry must be restored.
        VerifyVATEntries(PostedInvoiceNo);

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('ApplyUnApplyEntryPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyPrepaymentInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        PostedSaleInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Apply]
        // [SCENARIO 128419] Apply payment against Prepayment Invoice.

        // [GIVEN] Create and Post Prepayment Invoice.
        Initialize();
        PostCustomerPrepaymentInvoice(SalesHeader, SalesLine);

        // [WHEN] Create General Journal Line, Apply Invoice and Post General Journal Line.
        PostedSaleInvoiceNo := FindSalesPrepmtInvoiceNo(SalesHeader."No.");
        CreateGeneralLine(SalesHeader, GenJournalLine);
        ApplyInvoice(GenJournalLine, PostedSaleInvoiceNo, GenJournalLine."Document Type"::Invoice);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify that Remaning Amount updated correctly in Customer Ledger Entry.
        VerifyCustomerLedgerAmount(PostedSaleInvoiceNo, 0);  // Passing Zero for testing of Remaning Amount.

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('ApplyUnApplyEntryPageHandler')]
    [Scope('OnPrem')]
    procedure UnApplyPrepaymentInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        PostedSaleInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Unapply]
        // [SCENARIO 128419] Un-Apply payment to a Prepayment Invoice.

        // [GIVEN] Post Prepayment Invoice, Create General Journal Line, Apply Invoice and Post General Journal Line.
        Initialize();
        PostCustomerPrepaymentInvoice(SalesHeader, SalesLine);
        PostedSaleInvoiceNo := FindSalesPrepmtInvoiceNo(SalesHeader."No.");
        CreateGeneralLine(SalesHeader, GenJournalLine);
        ApplyInvoice(GenJournalLine, PostedSaleInvoiceNo, GenJournalLine."Document Type"::Invoice);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Un-Apply Invoice.
        UnapplyInvoiceCust(SalesHeader."Sell-to Customer No.", GenJournalLine."Document No.");

        // [THEN] Verify that Remaning Amount updated correctly in Customer Ledger Entry.
        SalesHeader.TestField(Status, SalesHeader.Status::"Pending Prepayment");
        VerifyCustomerLedgerAmount(
          PostedSaleInvoiceNo,
          Round(SalesLine."Prepmt. Line Amount" * (1 + SalesLine."Prepayment VAT %" / 100)));

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocumentFromOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Copy Document]
        // [SCENARIO 128419] Copy Document functionality from Order.

        // [GIVEN] Create and Post Prepayment Invoice.
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);

        PostCustomerPrepaymentInvoice(SalesHeader, SalesLine);

        // [WHEN] Copy Document.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        CopyDocument(SalesHeader2, SalesHeader."No.", "Sales Document Type From"::Order);

        // [THEN] Verify that Prepayment fields doesnot copy from Document.
        Clear(SalesLine);
        FindSalesLine(SalesLine, SalesHeader2);
        SalesLine.TestField("Prepmt. Amt. Inv.", 0);
        SalesLine.TestField("Prepmt Amt to Deduct", 0);
        SalesLine.TestField("Prepmt Amt Deducted", 0);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocumentFromPostedInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Sales] [Copy Document]
        // [SCENARIO 128419] Copy Document functionality from Posted Invoice.

        // [GIVEN] Create and Post Prepayment Invoice.
        Initialize();
        PostCustomerPrepaymentInvoice(SalesHeader, SalesLine);

        // [WHEN] Copy Document.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        asserterror CopyDocument(SalesHeader2, FindSalesPrepmtInvoiceNo(SalesHeader."No."), "Sales Document Type From"::"Posted Invoice");

        // [THEN] Verify that System throws an error while making Copy Document for Posted Prepayment Invoice.
        Assert.ExpectedTestFieldError(SalesInvoiceHeader.FieldCaption("Prepayment Invoice"), Format(false));

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvExclVATFromShptWithPrepmtExclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Get Shipment Lines]
        // [SCENARIO] Prepayment fields` values are correctly processed after Get Shipment Lines, Prices Including VAT = FALSE
        CreateSalesInvoiceFromShipmentPrepayment(SalesHeader, SalesHeader2, false, false);
        VerifySalesSeparateInvoicePrepAmounts(SalesHeader."No.", SalesHeader2."No.");

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvInclVATFromShptWithPrepmtExclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Get Shipment Lines] [Prices Incl. VAT]
        // [SCENARIO] The error message appears when doing Get Shipment Lines for Invoice with Prices Including VAT <> Sales Order Prices Including VAT
        asserterror CreateSalesInvoiceFromShipmentPrepayment(SalesHeader, SalesHeader2, true, false);
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption("Prices Including VAT"), Format(true));

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvInclVATFromShptWithPrepmtInclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Get Shipment Lines]
        // [SCENARIO] Prepayment fields` values are correctly processed after Get Shipment Lines, Prices Including VAT = TRUE
        CreateSalesInvoiceFromShipmentPrepayment(SalesHeader, SalesHeader2, true, true);
        VerifySalesSeparateInvoicePrepAmounts(SalesHeader."No.", SalesHeader2."No.");

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvExclVATFromRcptWithPrepmtExclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Get Receipt Lines]
        // [SCENARIO] Prepayment fields` values are correctly processed after Get Receipt Lines, Prices Including VAT = FALSE
        CreatePurchInvoiceFromReceiptPrepayment(PurchaseHeader, PurchaseHeader2, false, false);
        VerifyPurchSeparateInvoicePrepAmounts(PurchaseHeader."No.", PurchaseHeader2."No.");

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvInclVATFromRcptWithPrepmtExclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Get Receipt Lines] [Prices Incl. VAT]
        // [SCENARIO] The error message appears when doing Get Receipt Lines for Invoice with Prices Including VAT <> Purchase Order Prices Including VAT
        asserterror CreatePurchInvoiceFromReceiptPrepayment(PurchaseHeader, PurchaseHeader2, true, false);
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption("Prices Including VAT"), Format(true));

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvInclVATFromRcptWithPrepmtInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Get Receipt Lines]
        // [SCENARIO] Prepayment fields` values are correctly processed after Get Receipt Lines, Prices Including VAT = TRUE
        CreatePurchInvoiceFromReceiptPrepayment(PurchaseHeader, PurchaseHeader2, true, true);
        VerifyPurchSeparateInvoicePrepAmounts(PurchaseHeader."No.", PurchaseHeader2."No.");

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatePrepaymentLineAmountExclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineGLAccount: Record "G/L Account";
        CustomerNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Prepayment Amount]
        // [SCENARIO 305376] Sales Order throws an Error while updating Prepayment Line Amount more than Prepayment Amount.

        // [GIVEN] Create Item,Customer with Prepayment and Sales Document with Prepayment.
        Initialize();
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);
        CustomerNo := CreateCustomerWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, CustomerNo, ItemNo);

        // [WHEN] Change Prepmt. Line Amount more than SalesLine."Prepayment Amount".
        asserterror SalesLine.Validate("Prepmt. Line Amount", SalesLine."Line Amount" + LibraryRandom.RandDec(10, 2));

        // [THEN] Verify the Error Message.
        Assert.ExpectedError(PrepmtLineAmountErr);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithPrepaymentPartialShipAndInv()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        LineGLAccount: Record "G/L Account";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        ExpectedAmount: Decimal;
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Item Charge]
        // [SCENARIO 327577] Item and Item Charge are partially shipped and invoiced with prepayment
        // [GIVEN] Create Customer Sales Order with Type Item and Charge Item with Prepayment Percent
        Initialize();

        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);
        CustomerNo := CreateCustomerWithPostingSetup(LineGLAccount);
        CreateSalesHeaderWithPrepaymentPercentage(SalesHeader, CustomerNo);
        CreateSalesLinesWithQtyToShip(SalesLine, SalesHeader, LineGLAccount);
        Quantity := CreateSalesLineWithSingleItemCharge(SalesLine, SalesHeader, LineGLAccount);

        // Exercise : Post Prepayment Invoice and Post Sales Order with Partail Shipment and Inovice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        ExpectedAmount := UpdateItemChargeQtyToAssign(SalesLine, Quantity);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN]
        GenPostingSetup.Get(SalesHeader."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntryAmountForSales(DocumentNo, ExpectedAmount, GenPostingSetup."Sales Account");

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithLessThanCreditLimit()
    var
        Customer: Record Customer;
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // Check Credit warning does not appear after Prepayment Invoice posted with less than Credit Limit of Customer.

        // [GIVEN] Create and Post Sales Order Prepayment less than Credit Limit of the Customer.
        Initialize();
        SetCreditWarningsCreditLimit();

        CreateCustomerWithCreditLimit(Customer, LineGLAccount, '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLineGL(
          SalesLine, SalesHeader, LineGLAccount."No.", Customer."Credit Limit (LCY)" / LibraryRandom.RandIntInRange(10, 15));

        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Create New Sales order with same Customer using Page.
        CreateSalesOrderUsingPage(SalesOrder, Customer);

        // [THEN] Verify No credit Limit Warning appear after Prepayment Invoice with Less than Credit Limit
        // and Bill To Customer No. on Sales Order Page.
        SalesOrder."Bill-to Name".AssertEquals(Customer.Name);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithLCY()
    var
        Customer: Record Customer;
        LineGLAccount: Record "G/L Account";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Check Credit warning will appear after Prepayment Invoice posted with more than Credit Limit of Customer in LCY.
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        CreateCustomerWithCreditLimit(Customer, LineGLAccount, '');
        CustomerNo := Customer."No.";
        SalesOrderWithGreaterThanCreditLimit(Customer, LineGLAccount);
        NotificationLifecycleMgt.RecallAllNotifications();

        // Tear down
        LibraryERM.SetEnableDataCheck(true);
        TearDownVATPostingSetup(Customer."VAT Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,CurrencyExchangeRatesModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithFCY()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        LineGLAccount: Record "G/L Account";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Check Credit warning will appear after Prepayment Invoice posted with more than Credit Limit of Customer In FCY.
        Initialize();
        LibraryERM.SetEnableDataCheck(false);
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);

        CreateCustomerWithCreditLimit(Customer, LineGLAccount, Currency.Code);
        CustomerNo := Customer."No.";
        SalesOrderWithGreaterThanCreditLimit(Customer, LineGLAccount);
        NotificationLifecycleMgt.RecallAllNotifications();

        // Tear down
        LibraryERM.SetEnableDataCheck(true);
        TearDownVATPostingSetup(Customer."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerStatisticsTotalAmountLCY()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        PrepmtSalesInvHeader: Record "Sales Invoice Header";
        LineGLAccount: Record "G/L Account";
    begin
        // [GIVEN] Create a new Customer with Prepayment %.
        Initialize();
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);
        CreateCustomerWithPrepmtPct(Customer, LineGLAccount);

        // [WHEN] Create Sales Order with one G/L Account line and post Prepayment Invoice,
        // Create Prepayment and apply it to Prepayment Invoice,
        // Post partitial Invoice
        CreateSalesOrderWithOneLine(Customer."No.", SalesHeader, SalesLine, LineGLAccount);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        FindSalesPrepmtInvoice(PrepmtSalesInvHeader, SalesHeader."No.");
        CreateCustomerPrepmtPaymentAndApply(PrepmtSalesInvHeader);
        SalesInvHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");

        // [THEN] Verify Total Amount (LCY) at Customer Statistics page
        VerifyCustomerStatisticsTotalAmount(
          Customer, SalesHeader, SalesLine, PrepmtSalesInvHeader, SalesInvHeader);

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorStatisticsTotalAmountLCY()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PrepmtPurchInvHeader: Record "Purch. Inv. Header";
        PurchaseAndPayablesSetup: Record "Purchases & Payables Setup";
        LineGLAccount: Record "G/L Account";
    begin
        // [GIVEN] Create a new Customer with Prepayment %.
        Initialize();
        PurchaseAndPayablesSetup.Get();
        PurchaseAndPayablesSetup."Ext. Doc. No. Mandatory" := false;
        PurchaseAndPayablesSetup.Modify();
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Purchase);
        CreateVendorWithPrepmtPct(Vendor, LineGLAccount);

        // [WHEN] Create Purch Order with one G/L Account line and post Prepayment Invoice,
        // Create Prepayment and apply it to Prepayment Invoice,
        // Post partitial Invoice
        CreatePurchOrderWithOneLine(Vendor."No.", PurchHeader, PurchLine, LineGLAccount);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);
        FindPurchPrepmtInvoice(PrepmtPurchInvHeader, PurchHeader."No.");
        CreateVendorPrepmtPaymentAndApply(PrepmtPurchInvHeader);
        PurchInvHeader.Get(PostPurchaseDocument(PurchHeader));
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");

        // [THEN] Verify Total Amount (LCY) at Customer Statistics page
        VerifyVendorStatisticsTotalAmount(
          Vendor, PurchHeader, PurchLine, PrepmtPurchInvHeader, PurchInvHeader);

        // Tear down
        TearDownVATPostingSetup(PurchHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckStatusOpenErrorWithPendingPreypamentPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineGLAccount: Record "G/L Account";
        ItemNo: Code[20];
    begin
        // Verify the status Open error when one more purchase line added on Pending Preypayment Purchase Order.

        // [GIVEN] Create Purchase order with Prepayment %.
        Initialize();

        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Purchase);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        CreatePurchaseHeader(
          CreateVendorWithPostingSetup(LineGLAccount), PurchaseHeader,
          PurchaseHeader."Document Type"::Order, false, LibraryRandom.RandDec(10, 2));
        CreatePurchaseLineItem(PurchaseLine, PurchaseHeader, ItemNo, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Add one more purchase line.
        asserterror LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLine."No.", LibraryRandom.RandDec(100, 2));

        // [THEN] Verifying Open status error for prepayment.
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption(Status), Format(PurchaseHeader.Status::Open));

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckStatusOpenErrorWithPendingPreypamentSalesOrder()
    var
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify the Open status error when one more sales line added on Pending Preypayment Sales Order.

        // Setup : Create sales order
        Initialize();

        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);
        CreateSalesHeaderWithPrepaymentPercentage(SalesHeader, CreateCustomerWithPostingSetup(LineGLAccount));
        CreateSalesLinesWithQtyToShip(SalesLine, SalesHeader, LineGLAccount);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Add one more sales line.
        asserterror LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type, SalesLine."No.", SalesLine.Quantity);

        // [THEN] Verifying Open status error for prepayment.
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));

        // Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckStatusPendingPrepaymentAfterPostingPO()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineGLAccount: Record "G/L Account";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Order Status]
        // [SCENARIO] The status Pending Prepayment after error when trying to post Purchase Order.

        // [GIVEN] Create Purchase order with Prepayment %.
        Initialize();
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Purchase);

        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        CreatePurchaseHeader(
          CreateVendorWithPostingSetup(LineGLAccount), PurchaseHeader,
          PurchaseHeader."Document Type"::Order, false, LibraryRandom.RandDec(10, 2));
        CreatePurchaseLineItem(PurchaseLine, PurchaseHeader, ItemNo, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        Commit();
        // [WHEN] Try to Post Sales Order with Page.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verifying Pending Prepayment status Purchase Header.
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseHeader."No.");
        Assert.AreEqual(PurchaseHeader.Status::"Pending Prepayment", PurchaseHeader.Status, StrSubstNo(WrongPrepaymentStatusErr, PurchaseHeader.TableCaption(), PurchaseHeader."Document Type", PurchaseHeader."No."));

        // Tear down
        TearDownVATPostingSetup(PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceFromShipmentLinesWithDiffPricesInclVAT()
    var
        Customer: Record Customer;
        SalesOrderHeader: array[2] of Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Header";
        PostedDocNo: array[2] of Code[20];
        i: Integer;
    begin
        // Verify that shipments with different "Prices Including VAT" value can be combined into sales invoice

        // [GIVEN] Ship two sales orders with single line and different values of "Prices Including VAT"
        // [GIVEN] Create sales invoice with Prices Including VAT
        // [GIVEN] Get shipment line with the sames "Prices Including VAT"
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        PostedDocNo[1] :=
          CreateAndShipSalesOrderWithSpecificPricesInclVAT(SalesOrderHeader[1], Customer."No.", true);
        PostedDocNo[2] :=
          CreateAndShipSalesOrderWithSpecificPricesInclVAT(SalesOrderHeader[2], Customer."No.", false);
        LibrarySales.CreateSalesHeader(
          SalesInvoiceHeader, SalesInvoiceHeader."Document Type"::Invoice, Customer."No.");
        SalesInvoiceHeader.Validate("Prices Including VAT", true);
        SalesInvoiceHeader.Modify(true);
        GetShipmentLines(SalesOrderHeader[1], SalesInvoiceHeader);

        // [WHEN] Get shipment line from order with different "Prices Incl. VAT"
        GetShipmentLines(SalesOrderHeader[2], SalesInvoiceHeader);

        // [THEN] Verify connection to "Shipment No." in invoice
        for i := 1 to ArrayLen(PostedDocNo) do
            VerifyInvLineFromShipment(SalesInvoiceHeader."No.", PostedDocNo[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceFromReceiptLinesWithDiffPricesInclVAT()
    var
        Vendor: Record Vendor;
        PurchOrderHeader: array[2] of Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purchase Header";
        PostedDocNo: array[2] of Code[20];
        i: Integer;
    begin
        // Verify that receipts with different "Prices Including VAT" value can be combined into purchase invoice

        // [GIVEN] Receive two purchase orders with single line and different values of "Prices Including VAT"
        // [GIVEN] Create purchase invoice with Prices Including VAT
        // [GIVEN] Get receipt line with the sames "Prices Including VAT"
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        PostedDocNo[1] :=
          CreateAndReceivePurchOrderWithSpecificPricesInclVAT(PurchOrderHeader[1], Vendor."No.", true);
        PostedDocNo[2] :=
          CreateAndReceivePurchOrderWithSpecificPricesInclVAT(PurchOrderHeader[2], Vendor."No.", false);
        LibraryPurchase.CreatePurchHeader(
          PurchaseInvoiceHeader, PurchaseInvoiceHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseInvoiceHeader.Validate("Prices Including VAT", true);
        PurchaseInvoiceHeader.Modify(true);
        GetReceiptLines(PurchOrderHeader[1], PurchaseInvoiceHeader);

        // [WHEN] Get receipt line from order with different "Prices Incl. VAT"
        GetReceiptLines(PurchOrderHeader[2], PurchaseInvoiceHeader);

        // [THEN] Verify connection to "Receipt No." in invoice
        for i := 1 to ArrayLen(PostedDocNo) do
            VerifyInvLineFromReceipt(PurchaseInvoiceHeader."No.", PostedDocNo[i]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartShipmentPrepmtExclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 360198] Sales Prepayment Cr. Memo after full Prepayment Invoice and Partial Invoice with Amounts Excl. VAT
        // [GIVEN] Posted 100% Prepayment Invoice in LCY and Price Including VAT is FALSE
        InitSalesPrepaymentScenario(SalesHeader, SalesLine, false, 100, '');
        // [GIVEN] Posted Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        // [GIVEN] Posted Partial Invoice
        PostPartialSalesInvoice(SalesHeader, SalesLine);
        // [WHEN] Prepayment Credit Memo posted
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        // [THEN] Prepaymen Amt Incl. VAT in Sales Line must be decreased by amount of Prepayment Credit Memo
        VerifySalesPrepmtAmtInclVAT(SalesLine, SalesHeader."Prices Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartReceiptPrepmtExclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 360198] Purchase Prepayment Cr. Memo after full Prepayment Invoice and Partial Invoice with Amounts Excl. VAT
        // [GIVEN] Posted 100% Prepayment Invoice in LCY and Price Including VAT is FALSE
        InitPurchasePrepaymentScenario(PurchaseHeader, PurchaseLine, false, 100, '');
        // [GIVEN] Posted Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        // [GIVEN] Posted Partial Invoice
        PostPartialPurchaseInvoice(PurchaseHeader, PurchaseLine);
        // [WHEN] Prepayment Credit Memo posted
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader);
        // [THEN] Prepaymen Amt Incl. VAT in Purchase Line must be decreased by amount of Prepayment Credit Memo
        VerifyPurchPrepmtAmtInclVAT(PurchaseLine, PurchaseHeader."Prices Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartShipmentPrepymtInclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 360198] Sales Prepayment Cr. Memo after full Prepayment Invoice and Partial Invoice with Amounts Incl. VAT
        // [GIVEN] Posted 100% Prepayment Invoice in LCY and Price Including VAT is TRUE
        InitSalesPrepaymentScenario(SalesHeader, SalesLine, true, 100, '');
        // [GIVEN] Posted Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        // [GIVEN] Posted partial Invoice
        PostPartialSalesInvoice(SalesHeader, SalesLine);
        // [WHEN] Prepayment Credit Memo posted
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        // [THEN] Prepaymen Amt Incl. VAT in Sales Line must be decreased by amount of Prepayment Credit Memo
        VerifySalesPrepmtAmtInclVAT(SalesLine, SalesHeader."Prices Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartReceiptPrepmtInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 360198] Purchase Prepayment Cr. Memo after full Prepayment Invoice and Partial Invoice with Amounts Incl. VAT
        // [GIVEN] Posted 100% Prepayment Invoice in LCY and Price Including VAT is TRUE
        InitPurchasePrepaymentScenario(PurchaseHeader, PurchaseLine, true, 100, '');
        // [GIVEN] Posted Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        // [GIVEN] Posted Partial Invoice
        PostPartialPurchaseInvoice(PurchaseHeader, PurchaseLine);
        // [WHEN] Prepayment Credit Memo posted
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader);
        // [THEN] Prepaymen Amt Incl. VAT in Purchase Line must be decreased by amount of Prepayment Credit Memo
        VerifyPurchPrepmtAmtInclVAT(PurchaseLine, PurchaseHeader."Prices Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartShipmentPrepmtFCY()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Credit Memo] [FCY]
        // [SCENARIO 360198] Sales Prepayment Cr. Memo after full Prepayment Invoice and Partial Invoice with Amounts Excl. VAT
        // [GIVEN] Posted 100% Prepayment Invoice in FCY and Price Including VAT is FALSE
        InitSalesPrepaymentScenario(SalesHeader, SalesLine, false, 100, LibraryERM.CreateCurrencyWithRounding());
        // [GIVEN] Posted Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        // [GIVEN] Posted Partial Invoice
        PostPartialSalesInvoice(SalesHeader, SalesLine);
        // [WHEN] Prepayment Credit Memo posted
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        // [THEN] Prepaymen Amt Incl. VAT in Sales Line must be decreased by amount of Prepayment Credit Memo
        VerifySalesPrepmtAmtInclVAT(SalesLine, SalesHeader."Prices Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartReceiptPrepmtFCY()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Credit Memo] [FCY]
        // [SCENARIO 360198] Purchase Prepayment Cr. Memo after full Prepayment Invoice and Partial Invoice with Amounts Excl. VAT
        // [GIVEN] Posted 100% Prepayment Invoice in FCY and Price Including VAT is FALSE
        InitPurchasePrepaymentScenario(PurchaseHeader, PurchaseLine, false, 100, LibraryERM.CreateCurrencyWithRounding());
        // [GIVEN] Posted Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        // [GIVEN] Posted Partial Invoice
        PostPartialPurchaseInvoice(PurchaseHeader, PurchaseLine);
        // [WHEN] Prepayment Credit Memo posted
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader);
        // [THEN] Prepaymen Amt Incl. VAT in Purchase Line must be decreased by amount of Prepayment Credit Memo
        VerifyPurchPrepmtAmtInclVAT(PurchaseLine, PurchaseHeader."Prices Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesOrderAfterPrepayment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 123661] Delete Sales Order after prepayment without Order invoice
        // [GIVEN] Posted Prepayment Invoice for Sales Order
        InitSalesPrepaymentScenario(
          SalesHeader, SalesLine, true, LibraryRandom.RandInt(100), '');
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        // [WHEN] Delete Sales Order
        asserterror SalesHeader.Delete(true);

        // [THEN] Error occurs
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Prepmt. Amt. Inv."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesOrderAfterPrepaymentAnsPartShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 123661] Delete Sales Order after prepayment and partially invoiced
        // [GIVEN] Posted Prepayment Invoice for Sales Order
        InitSalesPrepaymentScenario(
          SalesHeader, SalesLine, true, LibraryRandom.RandInt(100), '');
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        // [GIVEN] Order is partially invoiced
        PostPartialSalesInvoice(SalesHeader, SalesLine);
        // [WHEN] Delete Sales Order
        asserterror SalesHeader.Delete(true);

        // [THEN] Error occurs
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Prepmt. Amt. Inv."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesOrderAfterPrepaymentCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 123661] Delete Sales Order after prepayment, partially invoiced and posted Prepayment Cr. Memo
        // [GIVEN] Posted Prepayment Invoice for Sales Order
        InitSalesPrepaymentScenario(
          SalesHeader, SalesLine, true, LibraryRandom.RandInt(100), '');
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        // [GIVEN] Order is partially invoiced
        PostPartialSalesInvoice(SalesHeader, SalesLine);
        // [GIVEN] Posted Prepayment Credit Memo
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        // [WHEN] Delete Sales Order
        SalesHeader.Delete(true);

        // [THEN] Document is deleted and no error occurred
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeader.SetRange("No.", SalesHeader."No.");
        Assert.IsTrue(SalesHeader.IsEmpty, SalesDocExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesOrderAfterPrepaymentCrMemoAndInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 123661] Delete Sales Order after prepayment, partially invoiced, posted prepayment Cr. Memo and prepayment Invoice
        // [GIVEN] Posted Prepayment Invoice for Sales Order
        InitSalesPrepaymentScenario(
          SalesHeader, SalesLine, true, LibraryRandom.RandInt(100), '');
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        // [GIVEN] Order is partially invoiced
        PostPartialSalesInvoice(SalesHeader, SalesLine);
        // [GIVEN] Posted Prepayment Credit Memo
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        // [GIVEN] Posted Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Delete Sales Order
        asserterror SalesHeader.Delete(true);

        // [THEN] Error occurs
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Prepmt. Amt. Inv."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePurchaseOrderAfterPrepayment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 123661] Delete Purchase Order after prepayment without Order invoice
        // [GIVEN] Posted Prepayment Invoice for Purchase Order
        InitPurchasePrepaymentScenario(
          PurchaseHeader, PurchaseLine, true, LibraryRandom.RandInt(100), '');
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        // [WHEN] Delete Purchase Order
        asserterror PurchaseHeader.Delete(true);

        // [THEN] Error occurs
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Prepmt. Amt. Inv."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePurchaseOrderAfterPrepaymentAnsPartShipment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 123661] Delete Purchase Order after prepayment and partially invoiced
        // [GIVEN] Posted Prepayment Invoice for Purchase Order
        InitPurchasePrepaymentScenario(
          PurchaseHeader, PurchaseLine, true, LibraryRandom.RandInt(100), '');
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        // [GIVEN] Order is partially invoiced
        PostPartialPurchaseInvoice(PurchaseHeader, PurchaseLine);
        // [WHEN] Delete Purchase Order
        asserterror PurchaseHeader.Delete(true);

        // [THEN] Error occurs
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Prepmt. Amt. Inv."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePurchaseOrderAfterPrepaymentCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 123661] Delete Purchase Order after prepayment, partially invoiced and posted prepayment Cr. Memo
        // [GIVEN] Posted Prepayment Invoice for Purchase Order
        InitPurchasePrepaymentScenario(
          PurchaseHeader, PurchaseLine, true, LibraryRandom.RandInt(100), '');
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        // [GIVEN] Order is partially invoiced
        PostPartialPurchaseInvoice(PurchaseHeader, PurchaseLine);
        // [GIVEN] Posted Prepayment Credit Memo
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader);
        // [WHEN] Delete Purchase Order
        PurchaseHeader.Delete(true);

        // [THEN] Document is deleted and no error occured
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        Assert.IsTrue(PurchaseHeader.IsEmpty, PurchaseDocExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePurchaseOrderAfterPrepaymentCrMemoAndInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 123661] Delete Purchase Order after prepayment, partially invoiced, posted prepayment Cr. Memo and prepayment Invoice
        // [GIVEN] Posted Prepayment Invoice for Purchase Order
        InitPurchasePrepaymentScenario(
          PurchaseHeader, PurchaseLine, true, LibraryRandom.RandInt(100), '');
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        // [GIVEN] Order is partially invoiced
        PostPartialPurchaseInvoice(PurchaseHeader, PurchaseLine);
        // [GIVEN] Posted Prepayment Credit Memo
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader);
        // [GIVEN] Posted Prepayment Invoice
        PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Delete Purchase Order
        asserterror PurchaseHeader.Delete(true);

        // [THEN] Error occurs
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Prepmt. Amt. Inv."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtPostingNoSeriesOnSales()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Credit Memo] [Series No]
        // [SCENARIO 360624.1] Sales Prepmt. invoice's and credit memo's entries are posted with "Posted Prepmt. No. Series"
        Initialize();

        // [GIVEN] New "Series Nos." for Posted Invoice and Credit Memo
        PostedPrepmtInvNosInSetup(SalesReceivablesSetup, CreateNoSeriesWithLine());
        PostedPrepmtCrMemoNosInSetup(SalesReceivablesSetup, CreateNoSeriesWithLine());

        // [GIVEN] Simple order with prepayment
        CreateSingleLineSalesOrderWithPrepmt(SalesHeader);

        // [WHEN] Post prepayment invoice and credit memo
        PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);

        // [THEN] "Posted Prepmt. No Series" is used as "No. Series" in all associated G/L and VAT entries
        VerifySalesPrepmtInvPostingNoSeries(SalesHeader."No.", SalesReceivablesSetup."Posted Prepmt. Inv. Nos.");
        VerifySalesPrepmtCrMemoPostingNoSeries(SalesHeader."No.", SalesReceivablesSetup."Posted Prepmt. Cr. Memo Nos.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtPostingNoSeriesOnPurch()
    var
        PurchPayablesSetup: Record "Purchases & Payables Setup";
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Series No]
        // [SCENARIO 360624.2] Purchase Prepmt. invoice's and credit memo's entries are posted with "Posted Prepmt. No. Series"
        Initialize();

        // [GIVEN] New "Series Nos." for Posted Invoice and Credit Memo
        PostedPrepmtInvNosInPurchSetup(PurchPayablesSetup, CreateNoSeriesWithLine());
        PostedPrepmtCrMemoNosInPurchSetup(PurchPayablesSetup, CreateNoSeriesWithLine());

        // [GIVEN] Simple order with prepayment
        CreateSingleLinePurchOrderWithPrepmt(PurchHeader);

        // [WHEN] Post prepayment invoice and credit memo
        PostPurchasePrepaymentInvoice(PurchHeader);
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchHeader);

        // [THEN] "Posted Prepmt. No Series" is used as "No. Series" in all associated G/L and VAT entries
        VerifyPurchPrepmtInvPostingNoSeries(PurchHeader."No.", PurchPayablesSetup."Posted Prepmt. Inv. Nos.");
        VerifyPurchPrepmtCrMemoPostingNoSeries(PurchHeader."No.", PurchPayablesSetup."Posted Prepmt. Cr. Memo Nos.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtAccountExtendedText()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineGLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        PrepmtGLAccountNo: Code[20];
        PurchInvNo: Code[20];
        ExtendedText: Text;
    begin
        // [FEATURE] [Purchase] [Extended Text]
        // [SCENARIO 375445] Extended text exists in posted final invoice when prepayment G/L Account has extended text with automatic setting
        Initialize();

        // [GIVEN] Prepayment Account with Extended Text and "Automatic Ext. Texts" = TRUE
        PrepmtGLAccountNo := LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        ExtendedText := CreateGLAccountExtendedText(PrepmtGLAccountNo);
        // [GIVEN] Purchase Order with Prepayment
        CreateVendorWithPrepmtPct(Vendor, LineGLAccount);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLineGL(PurchaseLine, PurchaseHeader, LineGLAccount."No.", LibraryRandom.RandDec(100, 2));
        // [GIVEN] Posted Purchase Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post Purchase Invoice
        PurchInvNo := PostPurchaseDocument(PurchaseHeader);

        // [THEN] Final posted Purchase Invoice has extended text
        VerifyPurchPstdInvoiceExtendedText(PurchInvNo, ExtendedText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtAccountExtendedText()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineGLAccount: Record "G/L Account";
        Customer: Record Customer;
        PrepmtGLAccountNo: Code[20];
        SalesInvNo: Code[20];
        ExtendedText: Text;
    begin
        // [FEATURE] [Sales] [Extended Text]
        // [SCENARIO 375445] Extended text exists in posted final invoice when prepayment G/L Account has extended text with automatic setting
        Initialize();

        // [GIVEN] Prepayment Account with Extended Text and "Automatic Ext. Texts" = TRUE
        PrepmtGLAccountNo := LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        ExtendedText := CreateGLAccountExtendedText(PrepmtGLAccountNo);
        // [GIVEN] Sales Order with Prepayment
        CreateCustomerWithPrepmtPct(Customer, LineGLAccount);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLineGL(SalesLine, SalesHeader, LineGLAccount."No.", LibraryRandom.RandDec(100, 2));
        // [GIVEN] Posted Sales Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post Sales Invoice.
        SalesInvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Both Posted Sales Invoices has extended text
        VerifySalesPstdInvoiceExtendedText(SalesInvNo, ExtendedText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithTwoPrepmtAccAndPricesInclVAT()
    var
        SalesHeader: Record "Sales Header";
        PrepmtInvoiceNo: Code[20];
        InvoiceNo: Code[20];
        PrepmtAccNo: array[2] of Code[20];
        PostAccNo: array[6] of Code[20];
    begin
        // [FEATURE] [Sales] [Prices Incl. VAT] [Rounding]
        // [SCENARIO 376012] Post Sales 100 % Prepayment Invoice and final Invoice with two prepayment accounts, six document lines and "Prices Including VAT"
        Initialize();

        // [GIVEN] Sales Order, Prices Including VAT = TRUE, Prepayment % = 100, VAT % = 20
        // [GIVEN] Two posting accounts "Acc1" and "Acc2" with different prepayment accounts "PAcc1" and "PAcc2" accordingly
        // [GIVEN] Six document lines where "Amount Incl. VAT" = 11.25, "No." = "Acc1" for even lines, "No." = "Acc2" for odd lines
        CreateCustomSalesOrder(SalesHeader, PrepmtAccNo, PostAccNo, false);
        // [GIVEN] Posted Prepayment Invoice
        PrepmtInvoiceNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post Sales Order
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] VAT entries posted by the final Invoice fully revert VAT posted by the Prepayment Invoice
        // [THEN] VAT Entry PAcc1: Base = -28.11, Amount = -5.64
        // [THEN] VAT Entry PAcc2: Base = -28.14, Amount = -5.61
        // [THEN] VAT Entry  Acc1: Base =  28.11, Amount =  5.64
        // [THEN] VAT Entry  Acc2: Base =  28.14, Amount =  5.61
        VerifyGLEntriesScenario_376012_Sales(InvoiceNo, PrepmtInvoiceNo, PrepmtAccNo, PostAccNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderWithTwoPrepmtAccAndPricesInclVAT()
    var
        PurchHeader: Record "Purchase Header";
        PrepmtInvoiceNo: Code[20];
        InvoiceNo: Code[20];
        PrepmtAccNo: array[2] of Code[20];
        PostAccNo: array[6] of Code[20];
    begin
        // [FEATURE] [Purchase] [Prices Incl. VAT] [Rounding]
        // [SCENARIO 376012] Post Purchase 100 % Prepayment Invoice and final Invoice with two prepayment accounts, six document lines and "Prices Including VAT"
        Initialize();

        // [GIVEN] Purchase Order, Prices Including VAT = TRUE, Prepayment % = 100, VAT % = 20
        // [GIVEN] Two posting accounts "Acc1" and "Acc2" with different prepayment accounts "PAcc1" and "PAcc2" accordingly
        // [GIVEN] Six document lines where "Amount Incl. VAT" = 11.25, "No." = "Acc1" for even lines, "No." = "Acc2" for odd lines
        CreateCustomPurchOrder(PurchHeader, PrepmtAccNo, PostAccNo, false);
        // [GIVEN] Posted Prepayment Invoice
        PrepmtInvoiceNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);

        // [WHEN] Post Purchase Order
        InvoiceNo := PostPurchaseDocument(PurchHeader);

        // [THEN] VAT entries posted by the final Invoice fully revert VAT posted by the Prepayment Invoice
        // [THEN] VAT Entry PAcc1: Base =  28.11, Amount =  5.64
        // [THEN] VAT Entry PAcc2: Base =  28.14, Amount =  5.61
        // [THEN] VAT Entry  Acc1: Base = -28.11, Amount = -5.64
        // [THEN] VAT Entry  Acc2: Base = -28.14, Amount = -5.61
        VerifyGLEntriesScenario_376012_Purch(InvoiceNo, PrepmtInvoiceNo, PrepmtAccNo, PostAccNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithTwoPrepmtAccSixPostAccAndPricesInclVAT()
    var
        SalesHeader: Record "Sales Header";
        PrepmtInvoiceNo: Code[20];
        InvoiceNo: Code[20];
        PrepmtAccNo: array[2] of Code[20];
        PostAccNo: array[6] of Code[20];
    begin
        // [FEATURE] [Sales] [Prices Incl. VAT] [Rounding]
        // [SCENARIO 376012] Post Sales 100 % Prepayment Invoice and final Invoice with two prepayment accounts, six different document lines and "Prices Including VAT"
        Initialize();

        // [GIVEN] Sales Order, Prices Including VAT = TRUE, Prepayment % = 100, VAT % = 20
        // [GIVEN] Six posting accounts "Acc1".."Acc6" with different prepayment accounts "PAcc1" (for Acc 1,3,5) and "PAcc2" (for Acc 2,4,6)
        // [GIVEN] Six document lines where "Amount Incl. VAT" = 11.25, "No." = "Acc1".."Acc6"
        CreateCustomSalesOrder(SalesHeader, PrepmtAccNo, PostAccNo, true);
        // [GIVEN] Posted Prepayment Invoice
        PrepmtInvoiceNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post Sales Order
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] VAT entries posted by the final Invoice fully revert VAT posted by the Prepayment Invoice
        // [THEN] VAT Entry PAcc1: Base = -28.11, Amount = -5.64
        // [THEN] VAT Entry PAcc2: Base = -28.14, Amount = -5.61
        // [THEN] VAT Entry  Acc1,3,5: Base =  28.11, Amount =  5.64
        // [THEN] VAT Entry  Acc2,4,6: Base =  28.14, Amount =  5.61
        VerifyGLEntriesScenario_376012_Sales(InvoiceNo, PrepmtInvoiceNo, PrepmtAccNo, PostAccNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderWithTwoPrepmtAccSixPostAccAndPricesInclVAT()
    var
        PurchHeader: Record "Purchase Header";
        PrepmtInvoiceNo: Code[20];
        InvoiceNo: Code[20];
        PrepmtAccNo: array[2] of Code[20];
        PostAccNo: array[6] of Code[20];
    begin
        // [FEATURE] [Purchase] [Prices Incl. VAT] [Rounding]
        // [SCENARIO 376012] Post Purchase 100 % Prepayment Invoice and final Invoice with two prepayment accounts, six different document lines and "Prices Including VAT"
        Initialize();

        // [GIVEN] Purchase Order, Prices Including VAT = TRUE, Prepayment % = 100, VAT % = 20
        // [GIVEN] Six posting accounts "Acc1".."Acc6" with different prepayment accounts "PAcc1" (for Acc 1,3,5) and "PAcc2"(for Acc 2,4,6)
        // [GIVEN] Six document lines where "Amount Incl. VAT" = 11.25, "No." = "Acc1".."Acc6"
        CreateCustomPurchOrder(PurchHeader, PrepmtAccNo, PostAccNo, true);
        // [GIVEN] Posted Prepayment Invoice
        PrepmtInvoiceNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);

        // [WHEN] Post Purchase Order
        InvoiceNo := PostPurchaseDocument(PurchHeader);

        // [THEN] VAT entries posted by the final Invoice fully revert VAT posted by the Prepayment Invoice
        // [THEN] VAT Entry PAcc1: Base =  28.11, Amount =  5.64
        // [THEN] VAT Entry PAcc2: Base =  28.14, Amount =  5.61
        // [THEN] VAT Entry  Acc1,3,5: Base = -28.11, Amount = -5.64
        // [THEN] VAT Entry  Acc2,4,6: Base = -28.14, Amount = -5.61
        VerifyGLEntriesScenario_376012_Purch(InvoiceNo, PrepmtInvoiceNo, PrepmtAccNo, PostAccNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateVATSetupAfterSalesPrepmtAccUpdate()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        LineGLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        SalesPrepaymentsAccountOld: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376557] Prepayment VAT Posting Setup should be validated in Sales Line during posting prepayment after update "Sales Prepayment Account" in General Posting Setup

        Initialize();

        // [GIVEN] General Posting Setup with blank "Sales Prepayment Account"
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);
        CustomerNo := CreateCustomerWithPostingSetup(LineGLAccount);
        GeneralPostingSetup.Get(LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."Gen. Prod. Posting Group");
        AttachSalesPrepaymentAccountInSetup(GeneralPostingSetup, '');

        // [GIVEN] Sales Invoice with with "Prepayment VAT Amount" = 18
        CreateSalesOrderWithOneLine(CustomerNo, SalesHeader, SalesLine, LineGLAccount);

        // [GIVEN] Updated "Sales Prepayment Account" in General Posting Setup
        SalesPrepaymentsAccountOld := AttachSalesPrepaymentAccountInSetup(GeneralPostingSetup, LineGLAccount."No.");

        // [WHEN] Post Sales Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] G/L Entry is posted with "G/L Account No." = "Sales VAT Account" and "Amount" = 18
        VATPostingSetup.Get(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        VerifyGLEntry(
          FindSalesPrepmtInvoiceNo(SalesHeader."No."), VATPostingSetup."Sales VAT Account",
          -Round(SalesLine."Prepmt. Line Amount" * VATPostingSetup."VAT %" / 100), 0);

        // Tear Down
        GeneralPostingSetup."Sales Prepayments Account" := SalesPrepaymentsAccountOld;
        GeneralPostingSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateVATSetupAfterPurchPrepmtAccUpdate()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        LineGLAccount: Record "G/L Account";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VendorNo: Code[20];
        PurchPrepaymentsAccountOld: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376557] Prepayment VAT Posting Setup should be validated in Purchase Line during posting prepayment after update "Purchase Prepayment Account" in General Posting Setup

        Initialize();

        // [GIVEN] General Posting Setup with blank "Purchase Prepayment Account"
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Purchase);
        VendorNo := CreateVendorWithPostingSetup(LineGLAccount);
        GeneralPostingSetup.Get(LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."Gen. Prod. Posting Group");
        PurchPrepaymentsAccountOld := AttachPurchPrepaymentAccountInSetup(GeneralPostingSetup, '');

        // [GIVEN] Purchase Invoice with with "Prepayment VAT Amount" = 18
        CreatePurchOrderWithOneLine(VendorNo, PurchHeader, PurchLine, LineGLAccount);

        // [GIVEN] Updated "Purchase Prepayment Account" in General Posting Setup
        AttachPurchPrepaymentAccountInSetup(GeneralPostingSetup, LineGLAccount."No.");

        // [WHEN] Post Purchase Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);

        // [THEN] G/L Entry is posted with "G/L Account No." = "Purchase VAT Account" and "Amount" = 18
        VATPostingSetup.Get(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        VerifyGLEntry(
          FindPurchPrepmtInvoiceNo(PurchHeader."No."), VATPostingSetup."Purchase VAT Account",
          Round(PurchLine."Prepmt. Line Amount" * VATPostingSetup."VAT %" / 100), 0);

        // Tear Down
        GeneralPostingSetup."Purch. Prepayments Account" := PurchPrepaymentsAccountOld;
        GeneralPostingSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('GetPostedSalesDocLinesToReverseWithoutPrepmtInv')]
    [Scope('OnPrem')]
    procedure UI_GetPostedSalesDocLinesToReverseDoesNotShowPrepmtInv()
    var
        SalesHeader: Record "Sales Header";
        CrMemoSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [UI] [Reverse] [Credit Memo]
        // [SCENARIO 377330] Posted Sales Prepayment should not be shown in "Posted Sales Document Lines" page when call "Get Posted Document Lines to Reverse"

        // [GIVEN] Sales Order with Customer "X" and Prepayment
        Initialize();

        InitSalesPrepaymentScenario(SalesHeader, SalesLine, false, LibraryRandom.RandInt(100), '');

        // [GIVEN] Posted Sales Prepayment Invoice "Y"
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Sales Credit Memo with Customer "X"
        LibrarySales.CreateSalesHeader(
          CrMemoSalesHeader, CrMemoSalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");

        // [WHEN] Open "Get Posted Document Lines to Reverse"
        CrMemoSalesHeader.GetPstdDocLinesToReverse();

        // [THEN] Posted Sales Prepayment Invoice "Y" does not shown on page "Posted Sales Document Lines"
        // Verification done in GetPostedSalesDocLinesToReverseWithoutPrepmtInv
    end;

    [Test]
    [HandlerFunctions('GetPostedPurchDocLinesToReverseWithoutPrepmtInv')]
    [Scope('OnPrem')]
    procedure UI_GetPostedPurchDocLinesToReverseDoesNotShowPrepmtInv()
    var
        PurchHeader: Record "Purchase Header";
        CrMemoPurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [UI] [Reverse] [Credit Memo]
        // [SCENARIO 377330] Posted Purchase Prepayment should not be shown in "Posted Purchase Document Lines" page when call "Get Posted Document Lines to Reverse"

        // [GIVEN] Purchase Order with Customer "X" and Prepayment
        Initialize();
        InitPurchasePrepaymentScenario(PurchHeader, PurchLine, false, LibraryRandom.RandInt(100), '');

        // [GIVEN] Posted Purchase Prepayment Invoice "Y"
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);

        // [GIVEN] Purchase Credit Memo with Customer "X"
        LibraryPurchase.CreatePurchHeader(
          CrMemoPurchHeader, CrMemoPurchHeader."Document Type"::"Credit Memo", PurchHeader."Buy-from Vendor No.");

        // [WHEN] Open "Get Posted Document Lines to Reverse"
        CrMemoPurchHeader.GetPstdDocLinesToReverse();

        // [THEN] Posted Purchase Prepayment Invoice "Y" does not shown on page "Posted Purchase Document Lines"
        // Verification done in GetPostedPurchDocLinesToReverseWithoutPrepmtInv
    end;

    [Test]
    [HandlerFunctions('GetPostedSalesDocLinesToReverseWithoutPrepmtCrMemo')]
    [Scope('OnPrem')]
    procedure UI_GetPostedSalesDocLinesToReverseDoesNotShowPrepmtCrMemo()
    var
        SalesHeader: Record "Sales Header";
        CrMemoSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [UI] [Reverse] [Credit Memo]
        // [SCENARIO 377805] Posted Sales Prepayment Cr. Memo should not be shown in "Posted Sales Document Lines" page when call "Get Posted Document Lines to Reverse"

        // [GIVEN] Sales Order with Customer "X" and Prepayment
        Initialize();
        InitSalesPrepaymentScenario(SalesHeader, SalesLine, false, LibraryRandom.RandInt(100), '');

        // [GIVEN] Posted Sales Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Posted Sales Prepayment Credit Memo "Y"
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);

        // [GIVEN] Sales Credit Memo with Customer "X"
        LibrarySales.CreateSalesHeader(
          CrMemoSalesHeader, CrMemoSalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");

        // [WHEN] Open "Get Posted Document Lines to Reverse" from Cr. Memo
        CrMemoSalesHeader.GetPstdDocLinesToReverse();

        // [THEN] Posted Sales Prepayment Credit Memo "Y" does not shown on page "Posted Sales Document Lines"
        // Verification done in GetPostedSalesDocLinesToReverseWithoutPrepmtCrMemo
    end;

    [Test]
    [HandlerFunctions('GetPostedPurchDocLinesToReverseWithoutPrepmtCrMemo')]
    [Scope('OnPrem')]
    procedure UI_GetPostedPurchDocLinesToReverseDoesNotShowPrepmtCrMemo()
    var
        PurchHeader: Record "Purchase Header";
        CrMemoPurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [UI] [Reverse] [Credit Memo]
        // [SCENARIO 377330] Posted Purchase Prepayment Cr. Memo should not be shown in "Posted Purchase Document Lines" page when call "Get Posted Document Lines to Reverse"

        // [GIVEN] Purchase Order with Customer "X" and Prepayment
        Initialize();
        InitPurchasePrepaymentScenario(PurchHeader, PurchLine, false, LibraryRandom.RandInt(100), '');

        // [GIVEN] Posted Purchase Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);

        // [GIVEN] Posted Purchase Prepayment Credit Memo "Y"
        PurchHeader."Vendor Cr. Memo No." := LibraryUtility.GenerateGUID();
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchHeader);

        // [GIVEN] Purchase Credit Memo with Customer "X"
        LibraryPurchase.CreatePurchHeader(
          CrMemoPurchHeader, CrMemoPurchHeader."Document Type"::"Credit Memo", PurchHeader."Buy-from Vendor No.");

        // [WHEN] Open "Get Posted Document Lines to Reverse" from Cr. Memo
        CrMemoPurchHeader.GetPstdDocLinesToReverse();

        // [THEN] Posted Purchase Prepayment Credit Memo "Y" does not shown on page "Posted Purchase Document Lines"
        // Verification done in GetPostedPurchDocLinesToReverseWithoutPrepmtCrMemo
    end;

    [Test]
    [HandlerFunctions('CopyPurchDocRequestPageHandler,PostedPurchInvoicesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_NotPossibleToCopyAndShowPurchPrepmtInvoice()
    var
        PurchHeader: Record "Purchase Header";
        NewPurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PrepmtNo: Code[20];
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 378046] It shouldn't be possible to copy and show Purchase Prepayment Invoice

        // [GIVEN] Purchase Order with Customer "X" and Prepayment
        Initialize();
        InitPurchasePrepaymentScenario(PurchHeader, PurchLine, false, LibraryRandom.RandInt(100), '');

        // [GIVEN] Posted Purchase Prepayment Invoice "Y"
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);
        PrepmtNo := FindPurchPrepmtInvoiceNo(PurchHeader."No.");

        // [GIVEN] New Purchase Invoice with Customer "X"
        LibraryPurchase.CreatePurchHeader(
          NewPurchHeader, NewPurchHeader."Document Type"::Invoice, PurchHeader."Buy-from Vendor No.");
        LibraryVariableStorage.Enqueue(Format("Purchase Document Type From"::"Posted Invoice"));
        LibraryVariableStorage.Enqueue(PrepmtNo);
        Commit();

        // [WHEN] Call "Copy Document" from Invoice "Y"
        asserterror CopyPurchDocument(NewPurchHeader, PrepmtNo, "Purchase Document Type From"::"Posted Invoice");

        // [THEN] Posted Purchase Prepayment Invoice "Y" does not shown on page "Posted Purchase Invoices" page
        // Verification done in PostedPurchInvoicesModalPageHandler

        // [THEN] Error message "Prepayment Invoice must be equal to 'No'" raised
        Assert.ExpectedTestFieldError(PurchInvHeader.FieldCaption("Prepayment Invoice"), Format(false));
    end;

    [Test]
    [HandlerFunctions('CopyPurchDocRequestPageHandler,PostedPurchCrMemosModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_NotPossibleToCopyAndShowPurchPrepmtCrMemo()
    var
        PurchHeader: Record "Purchase Header";
        NewPurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PrepmtNo: Code[20];
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 378046] It shouldn't be possible to copy and show Purchase Prepayment Credit Memo

        // [GIVEN] Purchase Order with Customer "X" and Prepayment
        Initialize();

        InitPurchasePrepaymentScenario(PurchHeader, PurchLine, false, LibraryRandom.RandInt(100), '');

        // [GIVEN] Posted Purchase Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);

        // [GIVEN] Posted Purchase Prepayment Credit Memo "Y"
        PurchHeader."Vendor Cr. Memo No." := LibraryUtility.GenerateGUID();
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchHeader);
        PrepmtNo := FindPurchPrepmtCrMemoNo(PurchHeader."No.");

        // [GIVEN] New Purchase Invoice with Customer "X"
        LibraryPurchase.CreatePurchHeader(
          NewPurchHeader, NewPurchHeader."Document Type"::Invoice, PurchHeader."Buy-from Vendor No.");
        LibraryVariableStorage.Enqueue(Format("Purchase Document Type From"::"Posted Credit Memo"));
        LibraryVariableStorage.Enqueue(PrepmtNo);
        Commit();

        // [WHEN] Call "Copy Document" from Credit Memo "Y"
        asserterror CopyPurchDocument(NewPurchHeader, PrepmtNo, "Purchase Document Type From"::"Posted Credit Memo");

        // [THEN] Posted Purchase Prepayment Credit Memo "Y" does not shown on page "Posted Purchase Credit Memos" page
        // Verification done in PostedPurchCrMemosModalPageHandler

        // [THEN] Error message "Prepayment Credit Memo must be equal to 'No'" raised
        Assert.ExpectedTestFieldError(PurchCrMemoHeader.FieldCaption("Prepayment Credit Memo"), Format(false));
    end;

    [Test]
    [HandlerFunctions('CopySalesDocRequestPageHandler,PostedSalesInvoicesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_NotPossibleToCopyAndShowSalesPrepmtInvoice()
    var
        SalesHeader: Record "Sales Header";
        NewSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        PrepmtNo: Code[20];
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 378046] It shouldn't be possible to copy and show Sales Prepayment Invoice

        // [GIVEN] Sales Order with Customer "X" and Prepayment
        Initialize();

        InitSalesPrepaymentScenario(SalesHeader, SalesLine, false, LibraryRandom.RandInt(100), '');

        // [GIVEN] Posted Sales Prepayment Invoice "Y"
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        PrepmtNo := FindSalesPrepmtInvoiceNo(SalesHeader."No.");

        // [GIVEN] New Sales Invoice with Customer "X"
        LibrarySales.CreateSalesHeader(
          NewSalesHeader, NewSalesHeader."Document Type"::Invoice, SalesHeader."Bill-to Customer No.");
        LibraryVariableStorage.Enqueue(Format("Sales Document Type From"::"Posted Invoice"));
        LibraryVariableStorage.Enqueue(PrepmtNo);
        Commit();

        // [WHEN] Call "Copy Document" from Invoice "Y"
        asserterror CopySalesDocument(NewSalesHeader, PrepmtNo, "Sales Document Type From"::"Posted Invoice");

        // [THEN] Posted Sales Prepayment Invoice "Y" does not shown on page "Posted Sales Invoices" page
        // Verification done in PostedSalesInvoicesModalPageHandler

        // [THEN] Error message "Prepayment Invoice must be equal to 'No'" raised
        Assert.ExpectedTestFieldError(SalesInvHeader.FieldCaption("Prepayment Invoice"), Format(false));
    end;

    [Test]
    [HandlerFunctions('CopySalesDocRequestPageHandler,PostedSalesCrMemosModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_NotPossibleToCopyAndShowSalesPrepmtCrMemo()
    var
        SalesHeader: Record "Sales Header";
        NewSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PrepmtNo: Code[20];
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 378046] It shouldn't be possible to copy and show Sales Prepayment Credit Memo

        // [GIVEN] Sales Order with Customer "X" and Prepayment
        Initialize();
        InitSalesPrepaymentScenario(SalesHeader, SalesLine, false, LibraryRandom.RandInt(100), '');

        // [GIVEN] Posted Sales Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Posted Sales Prepayment Credit Memo "Y"
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        PrepmtNo := FindSalesPrepmtCrMemoNo(SalesHeader."No.");

        // [GIVEN] New Sales Invoice with Customer "X"
        LibrarySales.CreateSalesHeader(
          NewSalesHeader, NewSalesHeader."Document Type"::Invoice, SalesHeader."Bill-to Customer No.");
        LibraryVariableStorage.Enqueue(Format("Sales Document Type From"::"Posted Credit Memo"));
        LibraryVariableStorage.Enqueue(PrepmtNo);
        Commit();

        // [WHEN] Call "Copy Document" from Credit Memo "Y"
        asserterror CopySalesDocument(NewSalesHeader, PrepmtNo, "Sales Document Type From"::"Posted Credit Memo");

        // [THEN] Posted Sales Prepayment Credit Memo "Y" does not shown on page "Posted Sales Credit Memos" page
        // Verification done in PostedSalesCrMemosModalPageHandler

        // [THEN] Error message "Prepayment Credit Memo must be equal to 'No'" raised
        Assert.ExpectedTestFieldError(SalesCrMemoHeader.FieldCaption("Prepayment Credit Memo"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_PurchPrepmtInvShownFromPurchOrder()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchOrder: TestPage "Purchase Order";
        PostedPurchInvoices: TestPage "Posted Purchase Invoices";
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 378046] Prepayment Invoice should be shown when open prepayment invoices page from Purchase Order

        // [GIVEN] Purchase Order with Customer "X" and Prepayment
        Initialize();
        InitPurchasePrepaymentScenario(PurchHeader, PurchLine, false, LibraryRandom.RandInt(100), '');

        // [GIVEN] Posted Purchase Prepayment Invoice "Y"
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);

        PostedPurchInvoices.Trap();
        PurchOrder.OpenEdit();
        PurchOrder.GotoRecord(PurchHeader);

        // [WHEN] Open prepayment invoices from Purchase Order
        PurchOrder.PostedPrepaymentInvoices.Invoke();

        // [THEN] Prepayment Invoice "Y" is shown on page "Posted Purchase Invoices"
        PostedPurchInvoices."No.".AssertEquals(FindPurchPrepmtInvoiceNo(PurchHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_PurchPrepmtCrMemoShownFromPurchOrder()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchOrder: TestPage "Purchase Order";
        PostedPurchCrMemos: TestPage "Posted Purchase Credit Memos";
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 378046] Prepayment Credit Memo should be shown when open prepayment credit memos page from Purchase Order

        // [GIVEN] Sales Order with Customer "X" and Prepayment
        Initialize();
        InitPurchasePrepaymentScenario(PurchHeader, PurchLine, false, LibraryRandom.RandInt(100), '');

        // [GIVEN] Posted Sales Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);

        // [GIVEN] Posted Sales Prepayment Credit Memo "Y"
        PurchHeader."Vendor Cr. Memo No." := LibraryUtility.GenerateGUID();
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchHeader);

        PostedPurchCrMemos.Trap();
        PurchOrder.OpenEdit();
        PurchOrder.GotoRecord(PurchHeader);

        // [WHEN] Open prepayment credit memos from Purchase Order
        PurchOrder.PostedPrepaymentCrMemos.Invoke();

        // [THEN] Prepayment Credit Memo "Y" is shown on page "Posted Purchase Credit Memos"
        PostedPurchCrMemos."No.".AssertEquals(FindPurchPrepmtCrMemoNo(PurchHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_SalesPrepmtInvShownFromSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 378046] Prepayment Invoice should be shown when open prepayment invoices page from Sales Order

        // [GIVEN] Sales Order with Customer "X" and Prepayment
        Initialize();
        InitSalesPrepaymentScenario(SalesHeader, SalesLine, false, LibraryRandom.RandInt(100), '');

        // [GIVEN] Posted Sales Prepayment Invoice "Y"
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        PostedSalesInvoices.Trap();
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [WHEN] Open prepayment invoices from Sales Order
        SalesOrder.PagePostedSalesPrepaymentInvoices.Invoke();

        // [THEN] Prepayment Invoice "Y" is shown on page "Posted Sales Invoices"
        PostedSalesInvoices."No.".AssertEquals(FindSalesPrepmtInvoiceNo(SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_SalesPrepmtCrMemoShownFromSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        PostedSalesCrMemos: TestPage "Posted Sales Credit Memos";
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 378046] Prepayment Credit Memo should be shown when open prepayment credit memos page from Sales Order

        // [GIVEN] Sales Order with Customer "X" and Prepayment
        Initialize();
        InitSalesPrepaymentScenario(SalesHeader, SalesLine, false, LibraryRandom.RandInt(100), '');

        // [GIVEN] Posted Sales Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Posted Sales Prepayment Credit Memo "Y"
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);

        PostedSalesCrMemos.Trap();
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [WHEN] Open prepayment credit memos from Sales Order
        SalesOrder.PagePostedSalesPrepaymentCrMemos.Invoke();

        // [THEN] Prepayment Credit Memo "Y" is shown on page "Posted Sales Credit Memos"
        PostedSalesCrMemos."No.".AssertEquals(FindSalesPrepmtCrMemoNo(SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotChangeSalesPrepmtAccountVATProdSetupIfPendingPrepmtOrderExist()
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 418735] Stop modification of "VAT Prod. Posting Group" on Prepayment Account if orders pending prepayment exist.

        // [GIVEN] Sales Order 'SO' with Customer "X" and Prepayment
        Initialize();
        InitSalesPrepaymentScenario(SalesHeader, SalesLine, false, LibraryRandom.RandInt(100), '');

        // [GIVEN] Posted Sales Prepayment Invoice "Y"
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Try to modify "VAT Prod. Posting Group" on the prepayment account 'PA'
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GLAccount.Get(GeneralPostingSetup."Sales Prepayments Account");
        asserterror GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);

        // [THEN] Error message: 'You cannot change account while the sales order SO is in pending prepayment status.'
        Assert.ExpectedError(
            StrSubstNo(
                CannotChangeSetupOnPrepmtAccErr, SalesHeader.RecordId,
                GLAccount.FieldCaption("VAT Prod. Posting Group"), GLAccount."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotChangePurchPrepmtAccountGenProdSetupIfPendingPrepmtOrderExist()
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 418735] Stop modification of "VAT Bus. Posting Group" on Prepayment Account if orders pending prepayment exist.

        // [GIVEN] Purchase Order 'PO' with Vendor "X" and Prepayment
        Initialize();
        InitPurchasePrepaymentScenario(PurchaseHeader, PurchaseLine, false, LibraryRandom.RandInt(100), '');

        // [GIVEN] Posted Purchase Prepayment Invoice "Y"
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Try to modify "Gen. Prod. Posting Group" on the prepayment account 'PA'
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GLAccount.Get(GeneralPostingSetup."Purch. Prepayments Account");
        asserterror GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);

        // [THEN] Error message: 'You cannot change account while the purchase order PO is in pending prepayment status.'
        Assert.ExpectedError(
            StrSubstNo(
                CannotChangeSetupOnPrepmtAccErr, PurchaseHeader.RecordId,
                GLAccount.FieldCaption("Gen. Prod. Posting Group"), GLAccount."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotChangeSalesPrepmtAccountInGenPostSetupIfPendingPrepmtOrderExist()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 418735] Stop modification of "Sales Prepayment Account" in general posting setup if orders pending prepayment exist.

        // [GIVEN] Sales Order 'SO' with Customer "X" and Prepayment
        Initialize();
        InitSalesPrepaymentScenario(SalesHeader, SalesLine, false, LibraryRandom.RandInt(100), '');

        // [GIVEN] Posted Sales Prepayment Invoice "Y"
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Try to modify "Sales Prepayments Account" on the GeneralPostingSetup
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        asserterror GeneralPostingSetup.Validate("Sales Prepayments Account", LibraryERM.CreateGLAccountWithSalesSetup());

        // [THEN] Error message: 'You cannot change Sales Prepayments Account while the sales order SO is in pending prepayment status.'
        Assert.ExpectedError(
            StrSubstNo(
                CannotChangePrepmtAccErr, SalesHeader.RecordId, GeneralPostingSetup.FieldCaption("Sales Prepayments Account")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotChangePurchPrepmtAccountInGenPostSetupIfPendingPrepmtOrderExist()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 418735] Stop modification of "Purch. Prepayment Account" in general posting setup if orders pending prepayment exist.

        // [GIVEN] Purchase Order 'PO' with Vendor "X" and Prepayment
        Initialize();
        InitPurchasePrepaymentScenario(PurchaseHeader, PurchaseLine, false, LibraryRandom.RandInt(100), '');

        // [GIVEN] Posted Purchase Prepayment Invoice "Y"
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Try to modify "Purch. Prepayments Account" on the GeneralPostingSetup
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        asserterror GeneralPostingSetup.Validate("Purch. Prepayments Account", LibraryERM.CreateGLAccountWithPurchSetup());

        // [THEN] Error message: 'You cannot change Purch. Prepayments Account while the purchase order PO is in pending prepayment status.'
        Assert.ExpectedError(
            StrSubstNo(
                CannotChangePrepmtAccErr, PurchaseHeader.RecordId, GeneralPostingSetup.FieldCaption("Purch. Prepayments Account")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPaymentMethodCodeOnCustomerLedgerEntriesForPrepaymentInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PaymentMethod: Record "Payment Method";
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO 449090] Payment Method Code is not populated on the Customer Ledger Entries for Prepayment Invoices
        Initialize();

        // [GIVEN] Create a payment method
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] Create Sales Header, Sales Line
        CreateSalesDocument(SalesHeader, SalesLine);
        SalesHeader."Prepayment %" := LibraryRandom.RandDec(99, 5);
        SalesHeader."Payment Method Code" := PaymentMethod.Code;
        SalesHeader.Modify(true);

        // [WHEN] Post Sales Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Verify customer ledger entry
        VerifyCustomerLedgerEntryForSalesPrepayment(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPaymentMethodCodeOnVendorLedgerEntriesForPrepaymentInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PaymentMethod: Record "Payment Method";
    begin
        // [FEATURE] [Purchase] [Prepayment %]
        // [SCENARIO 449090] Payment Method Code is not populated on the Vendor Ledger Entries for Prepayment Invoices
        Initialize();

        // [GIVEN] Create a payment method
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] Create Purchase Header, Purchase Line
        CreatePurchDocument(PurchaseHeader, PurchaseLine, 1);
        PurchaseHeader."Prepayment %" := LibraryRandom.RandDec(99, 5);
        PurchaseHeader."Payment Method Code" := PaymentMethod.Code;
        PurchaseHeader.Modify(true);

        // [WHEN] Post Purchase Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Verify vendor ledger entry
        VerifyVendLedgerEntryForPurchPrepayment(PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPrepaymentInvoiceWithInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 470549] Post and Verify Prepayment Sales Invoice Amount When there is an Invoice Discount in Sales Order.
        Initialize();

        // [GIVEN] Create a Sales Order.
        CreateSalesDocument(SalesHeader, SalesLine);

        // [GIVEN] Update the Prepayment % in Sales Header and Invoice Discount Amount in Sales Line.
        UpdatePrepaymentPercentageAndInvoiceDiscountAmount(
            SalesHeader,
            SalesLine,
            LibraryRandom.RandInt(90),
            LibraryRandom.RandInt(100));

        // [THEN] Post the Prepayment Invoice.
        PostSalesPrepaymentInvoice(SalesHeader);

        // [VERIFY] Verify the Prepayment Sales Invoice Amount.
        Assert.AreEqual(
            CalculateTotalPrepaymentAmount(SalesHeader),
            GetSalesPrepaymentInvoiceAmount(SalesHeader),
            PrepaymentAmountInvErr + ' ' + Format(CalculateTotalPrepaymentAmount(SalesHeader)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoErrorInOrderStatsWhenPrePaymentNegInvRounding()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        PrepmtSalesInvHeader: Record "Sales Invoice Header";
        LineGLAccount: Record "G/L Account";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [SCENARIO 474283] Order statistics fails when prepayment is active and invoice rounding is negative
        Initialize();

        // [GIVEN] Create Prepayment VAT Setup
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);

        // [GIVEN] Create a new Customer with Prepayment %.
        CreateCustomerWithPrepmtPct(Customer, LineGLAccount);

        // [GIVEN] Update "Inv. Rounding Precision (LCY)" to 0.01
        GeneralLedgerSetup.FindFirst();
        GeneralLedgerSetup.Validate("Inv. Rounding Precision (LCY)", 0.01);
        GeneralLedgerSetup.Modify();

        // [GIVEN] Create Sales Order with one G/L Account line
        CreateSalesOrderWithOneLine(Customer."No.", SalesHeader, SalesLine, LineGLAccount);

        // [GIVEN] Update Unit Price 11.14 to get the negative Invoice Rounding 
        SalesLine.Validate("Unit Price", 11.14);
        SalesLine.Modify();

        // [WHEN] Post Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Find Prepayment Invoice
        FindSalesPrepmtInvoice(PrepmtSalesInvHeader, SalesHeader."No.");
        CreateCustomerPrepmtPaymentAndApply(PrepmtSalesInvHeader);
        SalesInvHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");

        // [THEN] Verify Total Amount (LCY) at Customer Statistics page
        VerifyCustomerStatisticsTotalAmount(Customer, SalesHeader, SalesLine, PrepmtSalesInvHeader, SalesInvHeader);

        // [THEN] Tear down
        TearDownVATPostingSetup(SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDescription2ShouldPopulateInTheSalesPrepaymentInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // [SCENARIO 483437] Verify that "Description 2" should populate in the sales prepayment invoice.
        Initialize();

        // [GIVEN] Create a Sales Order.
        CreateSalesDocument(SalesHeader, SalesLine, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Update the Prepayment % in Sales Header.
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(50, 50));
        SalesHeader.Validate("Compress Prepayment", false);
        SalesHeader.Modify(true);

        // [GIVEN] Update the "Description 2" in Sales Line.
        SalesLine.Validate("Description 2", LibraryUtility.GenerateGUID());
        SalesLine.Modify(true);

        // [WHEN] Post the Prepayment invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Find the Prepayment invoice.
        FindSalesPrepmtInvoice(SalesInvoiceHeader, SalesHeader."No.");

        // [VERIFY] Verify that "Description 2" should populate in the sales prepayment invoice.
        FindSalesInvoiceLines(SalesInvoiceLine, SalesInvoiceHeader);
        Assert.AreEqual(
            SalesLine."Description 2",
            SalesInvoiceLine."Description 2",
            StrSubstNo(
                AmountErr,
                SalesInvoiceLine.FieldCaption("Description 2"),
                SalesInvoiceLine."Description 2",
                SalesInvoiceLine.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCancelledInvoiceAmountAndPostedCreditMemoAmountShouldMatch()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [SCENARIO 477378] Verify that the cancelled invoice amount and posted credit memo should match in the case of prepayment.
        Initialize();

        // [GIVEN] Create a Sales Order.
        CreateSalesDocument(SalesHeader, SalesLine, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Update the Prepayment % in Sales Header.
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(50, 50));
        SalesHeader.Modify();

        // [GIVEN] Post the prepayment invoice, payment and apply Payment to the prepayment invoice.
        PostPaymentToInvoice(
            "Gen. Journal Account Type"::Customer,
            SalesHeader."Sell-to Customer No.",
            LibrarySales.PostSalesPrepaymentInvoice(SalesHeader),
            -GetSalesPrepaymentInvoiceAmount(SalesHeader));

        // [GIVEN] Change the status to Released in the Sales Header.
        PrepaymentMgt.UpdatePendingPrepaymentSales();

        // [GIVEN] Post partial Shipment.
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Qty. to Ship", 1);
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Create a Sales Header and Sales Line from Posted Shipment Line.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        GetShipmentLines(SalesHeader, SalesHeader2);

        // [GIVEN] Post a Sales Invoice.
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader2, true, true));

        // [GIVEN] Update General Posting Setup.
        GeneralPostingSetup.Get(SalesInvoiceHeader."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        LibraryERM.SetGeneralPostingSetupSalesAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify();

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Post Cancelled Invoice.
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [VERIFY] Verify that the cancelled invoice amount and posted credit memo should match.
        SalesCrMemoHeader.CalcFields("Amount Including VAT");
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesInvoiceHeader."Sell-to Customer No.");
        SalesCrMemoHeader.FindFirst();
        Assert.AreEqual(
            SalesInvoiceHeader."Amount Including VAT",
            SalesCrMemoHeader."Amount Including VAT",
            StrSubstNo(
                AmountErr,
                SalesCrMemoHeader.FieldCaption("Amount Including VAT"),
                SalesCrMemoHeader."Amount Including VAT",
                SalesCrMemoHeader.TableCaption));
    end;

    [Test]
    [HandlerFunctions('SuggestWorksheetLinesReqLiquidFundsPageHandler')]
    procedure CheckCashFlowWorksheetWhenPrePaymentPercent100()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
        LibraryCashFlowHelper: Codeunit "Library - Cash Flow Helper";
        CashFlowJournal: TestPage "Cash Flow Worksheet";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        TotalAmount: Decimal;
    begin
        // [SCENARIO 487778] Cash Flow shows incorrect for Prepayment and Partial Invoice.   
        Initialize();

        // [GIVEN] Create a Sales Order.
        CreateSalesDocument(SalesHeader, SalesLine, LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Update the Prepayment % in Sales Header.
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Validate("Compress Prepayment", false);
        SalesHeader.Modify(true);

        // [WHEN] Post the Prepayment invoice.
        DocumentNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        TotalAmount := GetTotalPrePaymentAmount(DocumentNo);

        // [WHEN] Post the Prepayment Credit Memo.
        DocumentNo2 := LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader);
        TotalAmount += GetTotalPrePaymentAmount(DocumentNo2);

        // [WHEN] Post the Prepayment invoice.
        DocumentNo3 := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        TotalAmount += GetTotalPrePaymentAmount(DocumentNo3);

        // [GIVEN] Create Cash Receipt Journal.
        CreateCashReceiptJnlLine(GenJournalLine, SalesHeader."Sell-to Customer No.");

        // [GIVEN] Apply Prepayment Invoices.
        ApplyAndPostPmtToMultipleSalesInvoices(CustomerLedgerEntry, GenJournalLine, TotalAmount);

        // [GIVEN] Post Partial Sales Order.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create Cash Flow Forecast.
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);

        // [GIVEN] Open Cash Flow Journal Page and Created Cash Flow Work Sheet Lines.
        LibraryVariableStorage.Enqueue(CashFlowForecast."No.");
        CashFlowJournal.OpenEdit();
        CashFlowJournal.SuggestWorksheetLines.Invoke();
        CashFlowJournal.Close();

        // [VERIFY] No Sales Order Entry Created in Cash Flow Journal.
        CashFlowWorksheetLine.SetRange("Source No.", SalesHeader."No.");
        Assert.IsFalse(not CashFlowWorksheetLine.IsEmpty(), SalesOrderNotCreatedWorksheetLineMsg);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SalesOrderStatisticsModalHandler')]
    procedure AmountExclPrepaymentInSOStatisticsShowsDiffOfAmountExclVATAndPrepaymentAmountExclVAT()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        GLAccount: Record "G/L Account";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 539477] Amount Excl. Prepayment in Sales Order Statistics shows 
        // Difference between Amount Excl. VAT and Prepayment Amount Excl. VAT.
        Initialize();

        // [GIVEN] Create Prepayment VAT Setup.
        CreatePrepmtVATSetup(GLAccount, GLAccount."Gen. Posting Type"::Sale);

        // [GIVEN] Create a Sales Header and Validate Prepayment %.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerWithPostingSetup(GLAccount));
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(50, 50));
        SalesHeader.Modify(true);

        // [GIVEN] Create a Sales Line.
        LibrarySales.CreateSalesLine(
            SalesLine,
            SalesHeader,
            SalesLine.Type::Item,
            CreateItemWithPostingSetup(GLAccount),
            LibraryRandom.RandInt(0));

        // [GIVEN] Validate Unit Price and Prepayment % in Sales Line.
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(500, 500));
        SalesLine.Validate("Prepayment %", SalesHeader."Prepayment %");
        SalesLine.Modify(true);

        // [GIVEN] Post Sales Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Open Sales Order page and run Statistics action.
        SalesOrder.OpenEdit();
        SalesOrder.GoToRecord(SalesHeader);
        LibraryVariableStorage.Enqueue(SalesLine."Unit Price" * SalesLine."Prepayment %" / LibraryRandom.RandIntInRange(100, 100));
        SalesOrder.Statistics.Invoke();

        // [THEN] Amount Excl. Prepayment is equal to Amount Excl. VAT - Prepayment Amount Excl. VAT in SalesOrderStatisticsModalHandler.
    end;
#endif
    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    procedure AmountExclPrepaymentInSOStatisticsShowsDiffOfAmountExclVATAndPrepaymentAmountExclVATNM()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        GLAccount: Record "G/L Account";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 539477] Amount Excl. Prepayment in Sales Order Statistics shows 
        // Difference between Amount Excl. VAT and Prepayment Amount Excl. VAT.
        Initialize();

        // [GIVEN] Create Prepayment VAT Setup.
        CreatePrepmtVATSetup(GLAccount, GLAccount."Gen. Posting Type"::Sale);

        // [GIVEN] Create a Sales Header and Validate Prepayment %.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerWithPostingSetup(GLAccount));
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(50, 50));
        SalesHeader.Modify(true);

        // [GIVEN] Create a Sales Line.
        LibrarySales.CreateSalesLine(
            SalesLine,
            SalesHeader,
            SalesLine.Type::Item,
            CreateItemWithPostingSetup(GLAccount),
            LibraryRandom.RandInt(0));

        // [GIVEN] Validate Unit Price and Prepayment % in Sales Line.
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(500, 500));
        SalesLine.Validate("Prepayment %", SalesHeader."Prepayment %");
        SalesLine.Modify(true);

        // [GIVEN] Post Sales Prepayment Invoice.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Open Sales Order page and run Statistics action.
        SalesOrder.OpenEdit();
        SalesOrder.GoToRecord(SalesHeader);
        LibraryVariableStorage.Enqueue(SalesLine."Unit Price" * SalesLine."Prepayment %" / LibraryRandom.RandIntInRange(100, 100));
        SalesOrder.SalesOrderStatistics.Invoke();

        // [THEN] Amount Excl. Prepayment is equal to Amount Excl. VAT - Prepayment Amount Excl. VAT in SalesOrderStatisticsHandler.
    end;

    [Test]
    procedure CannotReleaseSalesOrderAfterPostingPrepmtInvoiceAndPrepmtCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 604175] Stan cannot release the sales order after posting prepayment invoice and prepayment credit memo.

        InitSalesPrepaymentScenario(SalesHeader, SalesLine, false, 100, '');
        // [GIVEN] Posted Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        // [GIVEN] Posted Prepayment Credit Memo
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        // [WHEN] Release Sales Order
        asserterror LibrarySales.ReleaseSalesDocument(SalesHeader);
        // [THEN] Error message 'There are unposted prepayment amounts' is thrown
        Assert.ExpectedError('There are unposted prepayment amounts');
    end;

    [Test]
    procedure CannotReleasePurchaseOrderAfterPostingPrepmtInvoiceAndPrepmtCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 604175] Stan cannot release the purchase order after posting prepayment invoice and prepayment credit memo.

        InitPurchasePrepaymentScenario(PurchaseHeader, PurchaseLine, false, 100, '');
        // [GIVEN] Posted Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        PurchaseHeader."Vendor Cr. Memo No." := LibraryUtility.GenerateGUID();
        PurchaseHeader.Modify(true);
        // [GIVEN] Posted Prepayment Credit Memo
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader);
        // [WHEN] Release Purchase Order
        asserterror LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        // [THEN] Error message 'There are unposted prepayment amounts' is thrown
        Assert.ExpectedError('There are unposted prepayment amounts');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Prepayment");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        LibraryERMCountryData.UpdatePrepaymentAccounts();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Prepayment");
        LibraryPurchase.SetInvoiceRounding(false);
        LibrarySales.SetInvoiceRounding(false);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateFAPostingGroup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Prepayment");
    end;

    local procedure InitSalesPrepaymentScenario(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; PriceIncludingVAT: Boolean; PrepaymentPercent: Decimal; CurrencyCode: Code[10])
    var
        LineGLAccount: Record "G/L Account";
        ItemNo: Code[20];
        CustomerNo: Code[20];
    begin
        Initialize();

        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);

        CustomerNo := CreateCustomerWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Prices Including VAT", PriceIncludingVAT);
        SalesHeader.Validate("Prepayment %", PrepaymentPercent);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDecInRange(100, 200, 2));
    end;

    local procedure InitPurchasePrepaymentScenario(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PriceIncludingVAT: Boolean; PrepaymentPercent: Decimal; CurrencyCode: Code[10])
    var
        LineGLAccount: Record "G/L Account";
        ItemNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Purchase);

        VendorNo := CreateVendorWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Prices Including VAT", PriceIncludingVAT);
        PurchaseHeader.Validate("Prepayment %", PrepaymentPercent);
        PurchaseHeader.Modify(true);

        CreatePurchaseLineItem(PurchaseLine, PurchaseHeader, ItemNo, LibraryRandom.RandDec(100, 2));
    end;

    local procedure ApplyInvoice(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
        ApplyCustomerEntries: Page "Apply Customer Entries";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustEntrySetApplID.SetApplId(CustLedgerEntry, CustLedgerEntry, GenJournalLine."Document No.");
        ApplyCustomerEntries.CalcApplnAmount();
        Commit();
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJournalLine);
    end;

    local procedure AttachSalesPrepaymentAccountInSetup(var GeneralPostingSetup: Record "General Posting Setup"; SalesPrepaymentsAccount: Code[20]) SalesPrepaymentsAccountOld: Code[20]
    begin
        SalesPrepaymentsAccountOld := GeneralPostingSetup."Sales Prepayments Account";
        GeneralPostingSetup.Validate("Sales Prepayments Account", SalesPrepaymentsAccount);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure AttachPurchPrepaymentAccountInSetup(var GeneralPostingSetup: Record "General Posting Setup"; PurchPrepaymentsAccount: Code[20]) PurchPrepaymentsAccountOld: Code[20]
    begin
        PurchPrepaymentsAccountOld := GeneralPostingSetup."Purch. Prepayments Account";
        GeneralPostingSetup.Validate("Purch. Prepayments Account", PurchPrepaymentsAccount);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CalculateInvoiceLineAmount(DocumentNo: Code[20]) SalesInvoiceLineAmount: Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindSet();
        repeat
            SalesInvoiceLineAmount += SalesInvoiceLine."Line Amount";
        until SalesInvoiceLine.Next() = 0;
    end;

    local procedure CalculateTotalPrepaymentAmount(SalesHeader: Record "Sales Header") PrepaymentAmount: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        repeat
            PrepaymentAmount += SalesLine."Prepmt. Amt. Incl. VAT";
        until SalesLine.Next() = 0;
    end;

    local procedure CalculateTotalPrepaymentInvoiceAmount(SalesInvoiceHeader: Record "Sales Invoice Header") PrepaymentInvAmount: Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        FindSalesInvoiceLines(SalesInvoiceLine, SalesInvoiceHeader);
        repeat
            PrepaymentInvAmount += SalesInvoiceLine."Amount Including VAT";
        until SalesInvoiceLine.Next() = 0;
    end;

    local procedure ChangeCustomerOnHeader(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20])
    begin
        SalesHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        SalesHeader.Modify(true);
    end;

    local procedure ChangeLineDiscPercentSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");

        // Using Random Number Generator for Line Discount Percent.
        SalesLine.ModifyAll("Line Discount %", LibraryRandom.RandDec(10, 2), true);
    end;

    local procedure CompressPrepaymentInSalesOrder(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Compress Prepayment", false);
        SalesHeader.Modify(true);
    end;

    local procedure CompressPrepaymentInPurchOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Compress Prepayment", false);
        PurchaseHeader.Modify(true);
    end;

    local procedure CopyDocument(SalesHeader: Record "Sales Header"; DocumentNo: Code[20]; DocType: Enum "Sales Document Type From")
    var
        CopySalesDocument: Report "Copy Sales Document";
    begin
        Clear(CopySalesDocument);
        Commit();
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.SetParameters(DocType, DocumentNo, true, false);
        CopySalesDocument.UseRequestPage(false);
        CopySalesDocument.Run();
    end;

    local procedure CopySalesLine(var TempSalesLine: Record "Sales Line" temporary; var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        FindSalesLine(SalesLine, SalesHeader);
        repeat
            TempSalesLine := SalesLine;
            TempSalesLine.Insert();
        until SalesLine.Next() = 0;
    end;

    local procedure CreateCustomerWithPriceGroup(CustomerPriceGroupCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Customer Price Group", CustomerPriceGroupCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerNotPrepayment(var Customer: Record Customer; GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Customer: Record Customer;
    begin
        CreateCustomerNotPrepayment(Customer, LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Customer.Validate("Prepayment %", LibraryRandom.RandDec(99, 5));  // Random Number Generator for Prepayment Percent.
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithVAT(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralLine(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        // Passing Amount Zero as it will update after Apply Entry.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", 0);
        GenJournalLine.Validate(
          "Document No.", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGLAccountforPostingSetup(GLAccountPostingSetup: Record "G/L Account"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GLAccountPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GLAccountPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", GLAccountPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", GLAccountPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", 10 * LibraryRandom.RandDec(99, 5)); // Using RANDOM value for Unit Price.
        Item.Modify(true);
    end;

    local procedure CreateItemVATProdPostingGroup(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Item: Record Item;
    begin
        CreateItem(Item);
        GenProdPostingGroupInItem(Item, LineGLAccount);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemChargeWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[20]
    var
        ItemCharge: Record "Item Charge";
    begin
        ItemCharge.Init();
        ItemCharge."No." := LibraryUtility.GenerateGUID();
        ItemCharge."Gen. Prod. Posting Group" := LineGLAccount."Gen. Prod. Posting Group";
        ItemCharge."VAT Prod. Posting Group" := LineGLAccount."VAT Prod. Posting Group";
        ItemCharge.Insert(true);
        exit(ItemCharge."No.");
    end;

    local procedure CreateFAPostingGroupWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[10]
    var
        FAPostingGroup: Record "FA Posting Group";
        GLAccNo: Code[20];
    begin
        FAPostingGroup.Init();
        FAPostingGroup.Code := LibraryUtility.GenerateGUID();
        GLAccNo := CreateGLAccountforPostingSetup(LineGLAccount);
        case LineGLAccount."Gen. Posting Type" of
            LineGLAccount."Gen. Posting Type"::Purchase:
                FAPostingGroup."Acquisition Cost Account" := GLAccNo;
            LineGLAccount."Gen. Posting Type"::Sale:
                FAPostingGroup."Acq. Cost Acc. on Disposal" := GLAccNo;
        end;
        FAPostingGroup.Insert(true);
        exit(FAPostingGroup.Code);
    end;

    local procedure CreateFAWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroupCode: Code[20];
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FAPostingGroupCode := CreateFAPostingGroupWithPostingSetup(LineGLAccount);

        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", LibraryFixedAsset.GetDefaultDeprBook());
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroupCode);
        FADepreciationBook.Modify(true);

        exit(FixedAsset."No.");
    end;

    local procedure CreateResourceWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Resource: Record Resource;
    begin
        LibraryResource.CreateResource(Resource, LineGLAccount."VAT Bus. Posting Group");
        Resource.Validate("Gen. Prod. Posting Group", LineGLAccount."Gen. Prod. Posting Group");
        Resource.Validate("VAT Prod. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        Resource.Modify(true);
        exit(Resource."No.");
    end;

    local procedure CreateNoSeriesWithLine(): Code[10]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, true);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, NoSeries.Code + '000', NoSeries.Code + '999');
        exit(NoSeries.Code);
    end;

    local procedure CreatePaymentTermWithDueDate(var PaymentTerms: Record "Payment Terms"; DueDateCalculation: Text[6])
    begin
        // Create a new Payment Term having Due Date as per parameter passed.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", DueDateCalculation);
        PaymentTerms.Validate("Due Date Calculation", PaymentTerms."Due Date Calculation");  // Evaluate doesn't call validate trigger.
        PaymentTerms.Modify(true);
    end;

    local procedure CreatePrepayment(var SalesPrepaymentPct: Record "Sales Prepayment %"; SaleType: Option; SalesCode: Code[20]; ItemNo: Code[20]; PrepaymentPercent: Decimal)
    begin
        LibrarySales.CreateSalesPrepaymentPct(SalesPrepaymentPct, SaleType, SalesCode, ItemNo, WorkDate());
        SalesPrepaymentPct.Validate("Prepayment %", PrepaymentPercent);
        SalesPrepaymentPct.Modify(true);
    end;

    local procedure CreateAndShipSalesOrderWithSpecificPricesInclVAT(var SalesHeader: Record "Sales Header"; CustNo: Code[20]; PricesInclVAT: Boolean): Code[20]
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustNo);
        SalesHeader.Validate("Prices Including VAT", PricesInclVAT);
        SalesHeader.Modify(true);
        CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure CreateAndReceivePurchOrderWithSpecificPricesInclVAT(var PurchHeader: Record "Purchase Header"; VendNo: Code[20]; PricesInclVAT: Boolean): Code[20]
    var
        Item: Record Item;
        PurchLine: Record "Purchase Line";
    begin
        Clear(PurchHeader);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendNo);
        PurchHeader.Validate("Prices Including VAT", PricesInclVAT);
        PurchHeader.Modify(true);
        CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false));
    end;

    local procedure CreatePrepmtVATSetup(var LineGLAccount: Record "G/L Account"; GenPostingType: Enum "General Posting Type"): Code[20]
    begin
        if GenPostingType = GenPostingType::Sale then
            exit(LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT"));
        if GenPostingType = GenPostingType::Purchase then
            exit(LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT"));
    end;

    local procedure CreatePurchInvoiceFromReceiptPrepayment(var PurchaseOrderHeader: Record "Purchase Header"; var PurchaseInvoiceHeader: Record "Purchase Header"; IncludeVATOrder: Boolean; IncludeVATInvoice: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        LineGLAccount: Record "G/L Account";
        Counter: Integer;
        LineNo: Integer;
    begin
        // 1. Setup
        Initialize();
        LineNo := LibraryRandom.RandIntInRange(2, 100);
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Purchase);

        // 2. Create Purchase Order with Prepayment %
        CreatePurchaseHeader(CreateVendorWithPostingSetup(LineGLAccount),
          PurchaseOrderHeader, PurchaseOrderHeader."Document Type"::Order, IncludeVATOrder, LibraryRandom.RandDec(100, 5));

        // 3. Create 3 Purchase Order lines
        for Counter := 1 to LineNo do
            // Using Random Number Generator for Random Quantity.
            CreatePurchaseLineItem(
              PurchaseLine, PurchaseOrderHeader,
              CreateItemWithPostingSetup(LineGLAccount), LibraryRandom.RandDec(1000, 2));

        // 4. Post Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseOrderHeader);

        // 5. Post Purchase Order (Receive)
        LibraryPurchase.PostPurchaseDocument(PurchaseOrderHeader, true, false);

        // 6. Create Purchase Invoice
        CreatePurchaseHeader(PurchaseOrderHeader."Buy-from Vendor No.",
          PurchaseInvoiceHeader, PurchaseInvoiceHeader."Document Type"::Invoice, IncludeVATInvoice, LibraryRandom.RandDec(100, 5));
        // 7. Get Receipt Lines
        GetReceiptLines(PurchaseOrderHeader, PurchaseInvoiceHeader);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; LineType: Enum "Purchase Line Type"; LineNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, LineType, LineNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineGL(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; LineNo: Code[20]; DirectUnitCost: Decimal)
    begin
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LineNo, LibraryRandom.RandIntInRange(2, 10), DirectUnitCost);
    end;

    local procedure CreatePurchaseLineItem(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; LineNo: Code[20]; DirectUnitCost: Decimal)
    begin
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LineNo, LibraryRandom.RandIntInRange(2, 10), DirectUnitCost);
    end;

    local procedure CreatePurchaseHeader(VendorNo: Code[20]; var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; PricesIncludingVAT: Boolean; PrepmtPercent: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        if PricesIncludingVAT then
            PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Validate("Prepayment %", PrepmtPercent);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; NoOfLines: Integer) PrepmtGLAccountNo: Code[20]
    var
        LineGLAccount: Record "G/L Account";
        Counter: Integer;
    begin
        PrepmtGLAccountNo := CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Purchase);

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorWithPostingSetup(LineGLAccount));

        for Counter := 1 to NoOfLines do begin  // According to the test case we have to create only 3 Sales Line.
                                                // Using Random Number Generator for Random Quantity.
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine,
              PurchaseHeader,
              PurchaseLine.Type::Item,
              CreateItemWithPostingSetup(LineGLAccount), LibraryRandom.RandInt(10));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
            PurchaseLine.Modify();
        end;
        exit(PrepmtGLAccountNo);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"): Code[20]
    begin
        exit(CreateSalesDocument(SalesHeader, SalesLine, 3));
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; NoOfLines: Integer) PrepmtGLAccountNo: Code[20]
    var
        LineGLAccount: Record "G/L Account";
        Counter: Integer;
    begin
        PrepmtGLAccountNo := CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);

        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerWithPostingSetup(LineGLAccount));

        for Counter := 1 to NoOfLines do   // According to the test case we have to create only 3 Sales Line.
                                           // Using Random Number Generator for Random Quantity.
            LibrarySales.CreateSalesLine(
              SalesLine,
              SalesHeader,
              SalesLine.Type::Item,
              CreateItemWithPostingSetup(LineGLAccount), LibraryRandom.RandInt(10));
        exit(PrepmtGLAccountNo);
    end;

    local procedure CreateSalesDocumentItemSetup(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        LineGLAccount: Record "G/L Account";
        Customer: Code[20];
    begin
        // Create Sales Order with multiple Lines of Item Type and with new Posting Setup.
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);

        Customer := CreateCustomerWithPostingSetup(LineGLAccount);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer);
        SalesLinesWithItemTypeCustomer(SalesHeader, SalesLine, LineGLAccount);
        SalesLineWithItemSalesTypeAll(SalesHeader, SalesLine, LineGLAccount);
    end;

    local procedure CreateSalesDocumentPrepayment(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // Using Random Number Generator for Quantity to take the value between 1 to 10.
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(2, 10), LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateSalesHeader(CustomerNo: Code[20]; var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; PricesIncludingVAT: Boolean; PrepmtPercent: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        if PricesIncludingVAT then
            SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Validate("Prepayment %", PrepmtPercent);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesHeaderWithPrepaymentPercentage(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandInt(99));
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineType: Enum "Sales Line Type"; LineNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, LineType, LineNo, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineGL(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineGLAccountNo: Code[20]; UnitPrice: Decimal)
    begin
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LineGLAccountNo, LibraryRandom.RandIntInRange(2, 10), UnitPrice);
    end;

    local procedure CreateSevSalesLinesGL(SalesHeader: Record "Sales Header"; GLAccountPostingSetup: Record "G/L Account")
    var
        SalesLine: Record "Sales Line";
        GLAccountNo: Code[20];
        Counter: Integer;
    begin
        // Create 2 to 10 Sales Lines with Type as G/L Account - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(8) do begin
            GLAccountNo := CreateGLAccountforPostingSetup(GLAccountPostingSetup);
            CreateSalesLineGL(SalesLine, SalesHeader, GLAccountNo, LibraryRandom.RandDec(1000, 2));
        end;
    end;

    local procedure CreateSevSalesLinesItem(SalesHeader: Record "Sales Header"; GLAccountPostingSetup: Record "G/L Account")
    var
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        Counter: Integer;
    begin
        // Create 2 to 10 Sales Lines with Type as Item - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(8) do begin
            ItemNo := CreateItemWithPostingSetup(GLAccountPostingSetup);
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        end;
    end;

    local procedure CreateSevSalesLinesFA(SalesHeader: Record "Sales Header"; GLAccountPostingSetup: Record "G/L Account")
    var
        SalesLine: Record "Sales Line";
        FixedAssetNo: Code[20];
        Counter: Integer;
    begin
        // Create 2 to 10 Sales Lines with Type as Fixed Asset - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(8) do begin
            FixedAssetNo := CreateFAWithPostingSetup(GLAccountPostingSetup);
            CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", FixedAssetNo,
              LibraryRandom.RandIntInRange(2, 10), LibraryRandom.RandDec(1000, 2));
        end;
    end;

    local procedure CreateSevSalesLinesItemCharge(SalesHeader: Record "Sales Header"; GLAccountPostingSetup: Record "G/L Account")
    var
        SalesLine: Record "Sales Line";
        ItemChargeNo: Code[20];
        Counter: Integer;
    begin
        // Create 2 to 10 Sales Lines with Type as Item Charge - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(8) do begin
            ItemChargeNo := CreateItemChargeWithPostingSetup(GLAccountPostingSetup);
            CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", ItemChargeNo,
              LibraryRandom.RandIntInRange(2, 10), LibraryRandom.RandDec(1000, 2));
        end;
    end;

    local procedure CreateSalesLinesWithQtyToShip(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; GLAccPostingSetup: Record "G/L Account")
    var
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandIntInRange(3, 13);
        ItemNo := CreateItemWithPostingSetup(GLAccPostingSetup);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity, LibraryRandom.RandDec(1000, 2));
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandIntInRange(3, Quantity));
        SalesLine.Modify(true);
    end;

    local procedure CreateSevSalesLinesResource(SalesHeader: Record "Sales Header"; GLAccountPostingSetup: Record "G/L Account")
    var
        SalesLine: Record "Sales Line";
        ResourceNo: Code[20];
        Counter: Integer;
    begin
        // Create 2 to 10 Sales Lines with Type as Resource - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(8) do begin
            ResourceNo := CreateResourceWithPostingSetup(GLAccountPostingSetup);
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, ResourceNo, LibraryRandom.RandInt(10));
        end;
    end;

    local procedure CreateSalesLineWithSingleItemCharge(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; GLAccPostingSetup: Record "G/L Account"): Decimal
    var
        ItemChargeNo: Code[20];
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandIntInRange(3, 13);
        ItemChargeNo := CreateItemChargeWithPostingSetup(GLAccPostingSetup);
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", ItemChargeNo, Quantity, LibraryRandom.RandDec(1000, 2));
        exit(SalesLine.Quantity);
    end;

    local procedure CreateSalesInvoiceFromShipmentPrepayment(var SalesOrderHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Header"; IncludeVATOrder: Boolean; IncludeVATInvoice: Boolean)
    var
        SalesLine: Record "Sales Line";
        LineGLAccount: Record "G/L Account";
        Counter: Integer;
        LineNo: Integer;
    begin
        // Setup

        Initialize();
        LineNo := LibraryRandom.RandIntInRange(2, 100);
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);

        // Create Sales Order with Prepayment %
        CreateSalesHeader(CreateCustomerWithPostingSetup(LineGLAccount), SalesOrderHeader,
          SalesOrderHeader."Document Type"::Order, IncludeVATOrder, LibraryRandom.RandDec(100, 5));

        // Create 3 lines in Sales Order
        for Counter := 1 to LineNo do   // According to the test case we have to create only 3 Sales Line.
                                        // Using Random Number Generator for Random Quantity.
            LibrarySales.CreateSalesLine(
              SalesLine,
              SalesOrderHeader,
              SalesLine.Type::Item,
              CreateItemWithPostingSetup(LineGLAccount), LibraryRandom.RandInt(10));

        // Post Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesOrderHeader);

        // Post Sales Order (Ship)
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, false);

        // Create new Sales Invoice
        CreateSalesHeader(SalesOrderHeader."Sell-to Customer No.", SalesInvoiceHeader,
          SalesInvoiceHeader."Document Type"::Invoice, IncludeVATInvoice, LibraryRandom.RandDec(100, 5));

        // Get Shipment Lines
        GetShipmentLines(SalesOrderHeader, SalesInvoiceHeader);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; GLAccountPostingSetup: Record "G/L Account")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSevSalesLinesGL(SalesHeader, GLAccountPostingSetup);
        CreateSevSalesLinesItem(SalesHeader, GLAccountPostingSetup);
        CreateSevSalesLinesResource(SalesHeader, GLAccountPostingSetup);
        CreateSevSalesLinesFA(SalesHeader, GLAccountPostingSetup);
        CreateSevSalesLinesItemCharge(SalesHeader, GLAccountPostingSetup);
    end;

    local procedure CreateSingleLineSalesOrderWithPrepmt(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        LineGLAccount: Record "G/L Account";
    begin
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);

        CreateCustomerNotPrepayment(
          Customer, LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Item.Get(CreateItemVATProdPostingGroup(LineGLAccount."VAT Prod. Posting Group"));
        GenProdPostingGroupInItem(Item, LineGLAccount);
        CreateSalesHeader(
          Customer."No.", SalesHeader, SalesHeader."Document Type"::Order, false, LibraryRandom.RandDec(100, 2));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
    end;

    local procedure CreateSingleLinePurchOrderWithPrepmt(var PurchHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchLine: Record "Purchase Line";
        LineGLAccount: Record "G/L Account";
    begin
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Purchase);

        CreateVendor(Vendor, LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Item.Get(CreateItemVATProdPostingGroup(LineGLAccount."VAT Prod. Posting Group"));
        GenProdPostingGroupInItem(Item, LineGLAccount);
        CreatePurchaseHeader(
          Vendor."No.", PurchHeader, PurchHeader."Document Type"::Order, false, LibraryRandom.RandDec(10, 2));

        CreatePurchaseLineItem(PurchLine, PurchHeader, Item."No.", LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
    end;

    local procedure CreateVendorWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor, LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Vendor.Validate("Prepayment %", LibraryRandom.RandDec(99, 5));  // Random Number Generator for Prepayment Percent.
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateAndPostPrepaymentSalesInvoice(var SalesHeader: Record "Sales Header"): Code[20]
    var
        LineGLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
    begin
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);
        VATPostingSetup.Get(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        CustomerNo := CreateCustomerWithPostingSetup(LineGLAccount);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLineGL(SalesLine, SalesHeader, LineGLAccount."No.", LibraryRandom.RandDec(1000, 2));
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        SalesHeader.Find();
        exit(SalesHeader."Last Prepayment No.");
    end;

    local procedure CreateAndPostPrepaymentPurchaseInvoice(var PurchHeader: Record "Purchase Header"): Code[20]
    var
        LineGLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchLine: Record "Purchase Line";
        VendorNo: Code[20];
    begin
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Purchase);
        VATPostingSetup.Get(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        VendorNo := CreateVendorWithPostingSetup(LineGLAccount);

        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        CreatePurchaseLineGL(PurchLine, PurchHeader, LineGLAccount."No.", LibraryRandom.RandDec(1000, 2));
        exit(LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader));
    end;

    local procedure CreateAndPostGenJournalLineCustomer(SalesHeader: Record "Sales Header"): Code[20]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalBatch.Modify(true);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", 0);
        GenJournalLine.Validate(Amount, -1 * LibraryRandom.RandDec(1000, 2));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostGenJournalLineVendor(PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalBatch.Modify(true);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", 0);
        GenJournalLine.Validate(Amount, LibraryRandom.RandDec(1000, 2));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CurrencyInSalesHeader(var SalesHeader: Record "Sales Header")
    var
        Currency: Record Currency;
    begin
        LibraryERM.FindCurrency(Currency);
        SalesHeader.Validate("Currency Code", Currency.Code);
        SalesHeader.Modify(true);
    end;

    local procedure CustomerPrepaymentPriceGroup(var Customer: Record Customer; CustomerPriceGroup: Code[10])
    begin
        Customer.Validate("Customer Price Group", CustomerPriceGroup);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithCreditLimit(var Customer: Record Customer; var LineGLAccount: Record "G/L Account"; CurrencyCode: Code[10])
    begin
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);
        Customer.Get(CreateCustomerWithPostingSetup(LineGLAccount));
        Customer.Validate("Prices Including VAT", true);
        Customer.Validate("Credit Limit (LCY)", LibraryRandom.RandDecInRange(1000, 2000, 2));
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
    end;

    local procedure CreateSalesOrderUsingPage(var SalesOrder: TestPage "Sales Order"; Customer: Record Customer)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("Document Type", Format(SalesHeader."Document Type"::Order));
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder."Sell-to Customer Name".SetValue(Customer.Name);
    end;

    local procedure CreateGLAccountExtendedText(GLAccountNo: Code[20]): Text
    var
        GLAccount: Record "G/L Account";
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        GLAccount.Get(GLAccountNo);
        GLAccount.Validate("Automatic Ext. Texts", true);
        GLAccount.Modify(true);

        LibrarySmallBusiness.CreateExtendedTextHeader(ExtendedTextHeader, ExtendedTextHeader."Table Name"::"G/L Account", GLAccount."No.");
        LibrarySmallBusiness.CreateExtendedTextLine(ExtendedTextLine, ExtendedTextHeader);
        exit(ExtendedTextLine.Text);
    end;

    local procedure CreateCustomSalesOrder(var SalesHeader: Record "Sales Header"; var PrepmtAccNo: array[2] of Code[20]; var PostAccNo: array[6] of Code[20]; IsDifferentPostingAccounts: Boolean)
    var
        Customer: Record Customer;
        LineGLAccount: array[2] of Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        I: Integer;
    begin
        CreateSalesLineGLAccounts(LineGLAccount, PrepmtAccNo);
        VATPostingSetup.Get(LineGLAccount[1]."VAT Bus. Posting Group", LineGLAccount[1]."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", 20); // set definite percent to get required values for rounding
        VATPostingSetup.Modify(true);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", LineGLAccount[1]."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", LineGLAccount[1]."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Modify(true);

        for I := 1 to 3 do begin
            PostAccNo[2 * I - 1] := CreateCustomSalesLine(SalesHeader, LineGLAccount[1], IsDifferentPostingAccounts);
            PostAccNo[2 * I] := CreateCustomSalesLine(SalesHeader, LineGLAccount[2], IsDifferentPostingAccounts);
        end;
    end;

    local procedure CreateCustomSalesLine(SalesHeader: Record "Sales Header"; LineGLAccount: Record "G/L Account"; IsDifferentPostingAccounts: Boolean): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GetNextGLAccountNo(LineGLAccount, IsDifferentPostingAccounts), 1, 11.25);
        exit(SalesLine."No.");
    end;

    local procedure CreateCustomPurchOrder(var PurchHeader: Record "Purchase Header"; var PrepmtAccNo: array[2] of Code[20]; var PostAccNo: array[6] of Code[20]; IsDifferentPostingAccounts: Boolean)
    var
        Vendor: Record Vendor;
        LineGLAccount: array[2] of Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        I: Integer;
    begin
        CreatePurchLineGLAccounts(LineGLAccount, PrepmtAccNo);
        VATPostingSetup.Get(LineGLAccount[1]."VAT Bus. Posting Group", LineGLAccount[1]."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", 20); // set definite percent to get required values for rounding
        VATPostingSetup.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", LineGLAccount[1]."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", LineGLAccount[1]."VAT Bus. Posting Group");
        Vendor.Modify(true);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, Vendor."No.");
        PurchHeader.Validate("Prices Including VAT", true);
        PurchHeader.Validate("Prepayment %", 100);
        PurchHeader.Modify(true);

        for I := 1 to 3 do begin
            PostAccNo[2 * I - 1] := CreateCustomPurchLine(PurchHeader, LineGLAccount[1], IsDifferentPostingAccounts);
            PostAccNo[2 * I] := CreateCustomPurchLine(PurchHeader, LineGLAccount[2], IsDifferentPostingAccounts);
        end;
    end;

    local procedure CreateCustomPurchLine(PurchHeader: Record "Purchase Header"; LineGLAccount: Record "G/L Account"; IsDifferentPostingAccounts: Boolean): Code[20]
    var
        PurchLine: Record "Purchase Line";
    begin
        CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GetNextGLAccountNo(LineGLAccount, IsDifferentPostingAccounts), 1, 11.25);
        exit(PurchLine."No.");
    end;

    local procedure CreateSalesLineGLAccounts(var LineGLAccount: array[2] of Record "G/L Account"; var PrepmtAccNo: array[2] of Code[20])
    begin
        PrepmtAccNo[1] := LibrarySales.CreatePrepaymentVATSetup(LineGLAccount[1], "Tax Calculation Type"::"Normal VAT");

        LineGLAccount[2]."Gen. Bus. Posting Group" := LineGLAccount[1]."Gen. Bus. Posting Group";
        LineGLAccount[2]."VAT Bus. Posting Group" := LineGLAccount[1]."VAT Bus. Posting Group";
        LineGLAccount[2]."VAT Prod. Posting Group" := LineGLAccount[1]."VAT Prod. Posting Group";
        PrepmtAccNo[2] := LibrarySales.CreatePrepaymentVATSetup(LineGLAccount[2], "Tax Calculation Type"::"Normal VAT");
    end;

    local procedure CreatePurchLineGLAccounts(var LineGLAccount: array[2] of Record "G/L Account"; var PrepmtAccNo: array[2] of Code[20])
    begin
        PrepmtAccNo[1] := LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount[1], "Tax Calculation Type"::"Normal VAT");

        LineGLAccount[2]."Gen. Bus. Posting Group" := LineGLAccount[1]."Gen. Bus. Posting Group";
        LineGLAccount[2]."VAT Bus. Posting Group" := LineGLAccount[1]."VAT Bus. Posting Group";
        LineGLAccount[2]."VAT Prod. Posting Group" := LineGLAccount[1]."VAT Prod. Posting Group";
        PrepmtAccNo[2] := LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount[2], "Tax Calculation Type"::"Normal VAT");
    end;

    local procedure CreateCopyGLAccountNo(SrcGLAccount: Record "G/L Account"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", SrcGLAccount."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", SrcGLAccount."VAT Prod. Posting Group");
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GenPostingType: Enum "General Posting Type")
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Gen. Posting Type", GenPostingType);
        GLEntry.FindFirst();
    end;

    local procedure FindGLEntryByBusPostingGroup(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GenBusPostingGroup: Code[20])
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Gen. Bus. Posting Group", GenBusPostingGroup);
        GLEntry.FindFirst();
    end;

    local procedure FindGLEntryForGLAccount(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindSalesPrepmtInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; PrepaymentOrderNo: Code[20])
    begin
        SalesInvoiceHeader.SetRange("Prepayment Invoice", true);
        SalesInvoiceHeader.SetRange("Prepayment Order No.", PrepaymentOrderNo);
        SalesInvoiceHeader.FindFirst();
    end;

    local procedure FindSalesPrepmtInvoiceNo(PrepaymentOrderNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        FindSalesPrepmtInvoice(SalesInvoiceHeader, PrepaymentOrderNo);
        exit(SalesInvoiceHeader."No.")
    end;

    local procedure FindPurchPrepmtInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; PrepaymentOrderNo: Code[20])
    begin
        PurchInvHeader.SetRange("Prepayment Invoice", true);
        PurchInvHeader.SetRange("Prepayment Order No.", PrepaymentOrderNo);
        PurchInvHeader.FindFirst();
    end;

    local procedure FindPurchPrepmtInvoiceNo(PrepaymentOrderNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        FindPurchPrepmtInvoice(PurchInvHeader, PrepaymentOrderNo);
        exit(PurchInvHeader."No.");
    end;

    local procedure FindPurchPrepmtCrMemoNo(PrepaymentOrderNo: Code[20]): Code[20]
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("Prepayment Credit Memo", true);
        PurchCrMemoHdr.SetRange("Prepayment Order No.", PrepaymentOrderNo);
        PurchCrMemoHdr.FindFirst();
        exit(PurchCrMemoHdr."No.");
    end;

    local procedure FindSalesPrepmtCrMemoNo(PrepaymentOrderNo: Code[20]): Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Prepayment Credit Memo", true);
        SalesCrMemoHeader.SetRange("Prepayment Order No.", PrepaymentOrderNo);
        SalesCrMemoHeader.FindFirst();
        exit(SalesCrMemoHeader."No.");
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
    end;

    local procedure FindSalesInvoiceLines(var SalesInvoiceLine: Record "Sales Invoice Line"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindSet();
    end;

    local procedure FindShipmentLineNo(DocumentNo: Code[20]): Integer
    var
        SalesShptLine: Record "Sales Shipment Line";
    begin
        SalesShptLine.SetRange("Document No.", DocumentNo);
        SalesShptLine.FindFirst();
        exit(SalesShptLine."Line No.");
    end;

    local procedure FindReceiptLineNo(DocumentNo: Code[20]): Integer
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Document No.", DocumentNo);
        PurchRcptLine.FindFirst();
        exit(PurchRcptLine."Line No.");
    end;

    local procedure GenProdPostingGroupInItem(var Item: Record Item; LineGLAccount: Record "G/L Account")
    begin
        Item.Validate("Gen. Prod. Posting Group", LineGLAccount."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        Item.Modify(true);
    end;

    local procedure GetShipmentLines(SalesHeader: Record "Sales Header"; var SalesHeader2: Record "Sales Header")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShpt: Codeunit "Sales-Get Shipment";
    begin
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesGetShpt.SetSalesHeader(SalesHeader2);
        SalesGetShpt.CreateInvLines(SalesShipmentLine);
    end;

    local procedure GetReceiptLines(PurchaseHeader: Record "Purchase Header"; PurchaseHeader2: Record "Purchase Header")
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.FindFirst();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeader2);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure GetReceivablesAccountNo(CustomerPostingGroupCode: Code[20]): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure GetNextGLAccountNo(SrcGLAccount: Record "G/L Account"; IsDifferentPostingAccounts: Boolean): Code[20]
    begin
        if IsDifferentPostingAccounts then
            exit(CreateCopyGLAccountNo(SrcGLAccount));
        exit(SrcGLAccount."No.");
    end;

    local procedure ModifyPurchaseQtyToInvoice(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; LineNo: Integer)
    begin
        PurchaseLine.Get(DocumentType, DocumentNo, LineNo);
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine."Qty. to Invoice" / LibraryRandom.RandIntInRange(3, 5));
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine."Qty. to Invoice");
        PurchaseLine.Modify(true);
    end;

    local procedure ModifySalesQtyToInvoice(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; LineNo: Integer)
    begin
        SalesLine.Get(DocumentType, DocumentNo, LineNo);
        SalesLine.Validate("Qty. to Invoice", SalesLine."Qty. to Invoice" / LibraryRandom.RandIntInRange(3, 5));
        SalesLine.Validate("Qty. to Ship", SalesLine."Qty. to Invoice");
        SalesLine.Modify(true);
    end;

    local procedure PostedPrepmtCrMemoNosInSetup(var SalesReceivablesSetup: Record "Sales & Receivables Setup"; PostedPrepmtCrMemoNos: Code[20])
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Prepmt. Cr. Memo Nos.", PostedPrepmtCrMemoNos);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure PostedPrepmtInvNosInSetup(var SalesReceivablesSetup: Record "Sales & Receivables Setup"; PostedPrepmtInvNos: Code[20])
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Prepmt. Inv. Nos.", PostedPrepmtInvNos);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure PostedPrepmtCrMemoNosInPurchSetup(var PurchPayablesSetup: Record "Purchases & Payables Setup"; PostedPrepmtCrMemoNos: Code[20])
    begin
        PurchPayablesSetup.Get();
        PurchPayablesSetup.Validate("Posted Prepmt. Cr. Memo Nos.", PostedPrepmtCrMemoNos);
        PurchPayablesSetup.Modify(true);
    end;

    local procedure PostedPrepmtInvNosInPurchSetup(var PurchPayablesSetup: Record "Purchases & Payables Setup"; PostedPrepmtInvNos: Code[20])
    begin
        PurchPayablesSetup.Get();
        PurchPayablesSetup.Validate("Posted Prepmt. Inv. Nos.", PostedPrepmtInvNos);
        PurchPayablesSetup.Modify(true);
    end;

    local procedure PostPartialPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        ModifyPurchaseQtyToInvoice(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        PostPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Find();
    end;

    local procedure PostPartialSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        ModifySalesQtyToInvoice(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure PostPurchaseDocument(PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        UpdatePurchVendorInvoiceCrMemoNo(PurchaseHeader);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostPurchasePrepaymentInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        UpdatePurchVendorInvoiceCrMemoNo(PurchaseHeader);
        PurchasePostPrepayments.Invoice(PurchaseHeader);
    end;

    local procedure PostSalesPrepaymentInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        SalesPostPrepayments.Invoice(SalesHeader);
    end;

    local procedure PrepmtCreditMemoInSetup(var SalesReceivablesSetup: Record "Sales & Receivables Setup")
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Prepmt. Cr. Memo Nos.", SalesReceivablesSetup."Posted Credit Memo Nos.");
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure PrepmtInvNosBlankInSetup(PostedPrepmtInvNos: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Prepmt. Inv. Nos.", PostedPrepmtInvNos);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure PrepmtInvNosInSetup(var SalesReceivablesSetup: Record "Sales & Receivables Setup")
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Prepmt. Inv. Nos.", SalesReceivablesSetup."Posted Invoice Nos.");
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure PrepaymentPercentInCustomer(var Customer: Record Customer; PrepaymentPercent: Decimal)
    begin
        Customer.Validate("Prepayment %", PrepaymentPercent);
        Customer.Modify(true);
    end;

    local procedure PrepaymentPercentInSalesHeader(var SalesHeader: Record "Sales Header"): Decimal
    begin
        // Using Random Number Generator for Prepayment Percent in Sales Header.
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandDec(99, 5));
        SalesHeader.Modify(true);
        exit(SalesHeader."Prepayment %");
    end;

    local procedure PrepaymentPercentInSalesLine(var SalesLine: Record "Sales Line"; PrepaymentPercent: Decimal)
    begin
        SalesLine.FindSet();
        repeat
            SalesLine.Validate("Prepayment %", SalesLine."Prepayment %" + PrepaymentPercent);
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
    end;

    local procedure PostTwoPrepaymentInvoices(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        PostCustomerPrepaymentInvoice(SalesHeader, SalesLine);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        UpdatePrepaymentLineAmount(SalesLine, SalesLine."Prepmt. Line Amount" + LibraryRandom.RandDec(1, 2));
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);
    end;

    local procedure PostCustomerPrepaymentInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        LineGLAccount: Record "G/L Account";
        SalesPrepaymentPct: Record "Sales Prepayment %";
        CustomerNo: Code[20];
        ItemNo: Code[20];
    begin
        CreatePrepmtVATSetup(LineGLAccount, LineGLAccount."Gen. Posting Type"::Sale);

        CustomerNo := CreateCustomerWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        CreatePrepayment(
          SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::Customer, CustomerNo, ItemNo, LibraryRandom.RandDec(99, 5));
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, CustomerNo, SalesPrepaymentPct."Item No.");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
    end;

    local procedure PostFinalPrepaymentOrder(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        // [GIVEN] Create and Post Prepayment Invoice.
        PostCustomerPrepaymentInvoice(SalesHeader, SalesLine);

        // [WHEN] Post Sales Order.
        UpdateQuantityToShip(SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure SalesLinesWithItemTypeCustomer(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LineGLAccount: Record "G/L Account")
    var
        SalesPrepaymentPct: array[2] of Record "Sales Prepayment %";
        Counter: Integer;
        PrepaymentPercent: Decimal;
    begin
        PrepaymentPercent := LibraryRandom.RandDec(99, 2);  // Using Random Number Generator for Prpayment Percent.
        // According to the test case we have to create only 2 Sales Line with Item Sales Type of Customer.
        for Counter := 1 to 2 do begin
            // Using Random Number Generator for Random Quantity.
            CreatePrepayment(
              SalesPrepaymentPct[Counter], SalesPrepaymentPct[Counter]."Sales Type"::Customer, SalesHeader."Sell-to Customer No.",
              CreateItemWithPostingSetup(LineGLAccount), PrepaymentPercent);
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, SalesPrepaymentPct[Counter]."Item No.", LibraryRandom.RandInt(10));
            PrepaymentPercent := 0;  // Making Prepayment Percent zero for second Prepayment Line.
        end;
    end;

    local procedure SalesLineWithItemSalesTypeAll(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LineGLAccount: Record "G/L Account")
    var
        SalesPrepaymentPct: Record "Sales Prepayment %";
    begin
        // Using Random Number Generator for Random Prepayment Percent and Quantity.
        CreatePrepayment(
          SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::"All Customers", '',
          CreateItemWithPostingSetup(LineGLAccount), LibraryRandom.RandDec(99, 5));
        LibrarySales.CreateSalesLine(
          SalesLine,
          SalesHeader,
          SalesLine.Type::Item, SalesPrepaymentPct."Item No.", LibraryRandom.RandInt(10));
    end;

    local procedure SalesOrderPrepaymentDueDate(var SalesHeader: Record "Sales Header"; PaymentTermsCode: Code[10]; GLAccountPostingSetup: Record "G/L Account")
    var
        Customer: Record Customer;
    begin
        CreateCustomerNotPrepayment(
          Customer, GLAccountPostingSetup."Gen. Bus. Posting Group", GLAccountPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Prepayment %", LibraryRandom.RandDec(100, 5));
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);

        CreateSalesOrder(SalesHeader, Customer."No.", GLAccountPostingSetup);
    end;

    local procedure SetCreditWarningsCreditLimit()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"Credit Limit");
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure SalesOrderWithGreaterThanCreditLimit(Customer: Record Customer; LineGLAccount: Record "G/L Account")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [GIVEN] Create and Post Sales Order Prepayment greater than Credit Limit of the Customer.
        SetCreditWarningsCreditLimit();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLineGL(
          SalesLine, SalesHeader, LineGLAccount."No.", Customer."Credit Limit (LCY)" + LibraryRandom.RandDec(1000, 2));
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        Customer.CalcFields("Outstanding Orders (LCY)");
        LibraryVariableStorage.Enqueue(Customer."Outstanding Orders (LCY)");
        LibraryVariableStorage.Enqueue(Customer."Outstanding Orders (LCY)");

        // [WHEN] Create New Sales order with same Customer using Page.
        CreateSalesOrderUsingPage(SalesOrder, Customer);

        // [THEN] Verify Credit Limit Warning appear after Prepayment Invoice and Check Order Amount Total LCY on Check Credit Limit
        // and Bill To Customer No on Sales Order Page.
        SalesOrder."Bill-to Name".AssertEquals(Customer.Name);
    end;

    local procedure UpdateGeneralPostingSetupInGL(SalesLine: Record "Sales Line")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GLAccount.Get(GeneralPostingSetup."Sales Prepayments Account");
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", SalesLine."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure UnapplyInvoiceCust(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure UnapplyInvoiceVend(VendorNo: Code[20]; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);
    end;

    local procedure UpdateItemChargeQtyToAssign(var SalesLine: Record "Sales Line"; QuantityToInvoice: Decimal): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Qty. to Invoice", QuantityToInvoice);
        SalesLine.Modify(true);
        LibraryVariableStorage.Enqueue(SalesLine."Qty. to Invoice");
        SalesLine.ShowItemChargeAssgnt();
        exit(Round(SalesLine."Unit Price" * SalesLine."Qty. to Invoice", GeneralLedgerSetup."Amount Rounding Precision"));
    end;

    local procedure UpdateQuantityToShip(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Qty. to Ship", SalesLine."Qty. to Ship" / 2);
        SalesLine.Modify(true);
    end;

    local procedure UpdatePrepaymentLineAmount(var SalesLine: Record "Sales Line"; PrepaymentLineAmount: Decimal)
    begin
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Prepmt. Line Amount", PrepaymentLineAmount);
        SalesLine.Modify(true);
    end;

    local procedure UpdatePrepaymentAmountToDeduct(SalesLine: Record "Sales Line"; PrepmtAmttoDeduct: Decimal)
    begin
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Prepmt Amt to Deduct", PrepmtAmttoDeduct);
        SalesLine.Modify(true);
    end;

    local procedure UpdatePurchVendorInvoiceCrMemoNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateVATClauseCode(LineGLAccount: Record "G/L Account"): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
    begin
        VATPostingSetup.GET(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        LibraryERM.CreateVATClause(VATClause);
        VATPostingSetup.VALIDATE("VAT Clause Code", VATClause.Code);
        VATPostingSetup.modify(true);
        exit(VATClause.Code);
    end;

    local procedure ApplyCustomerLedgerEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, DocumentType2, DocumentNo2);
        CustLedgerEntry2.CalcFields("Remaining Amount");
        CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
        CustLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure ApplyVendorLedgerEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Remaining Amount");
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, DocumentType2, DocumentNo2);
        VendorLedgerEntry2.CalcFields("Remaining Amount");
        VendorLedgerEntry2.Validate("Amount to Apply", VendorLedgerEntry2."Remaining Amount");
        VendorLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure CopyPurchDocument(PurchHeader: Record "Purchase Header"; DocNo: Code[20]; DocType: Enum "Purchase Document Type From")
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        CopyPurchaseDocument.SetPurchHeader(PurchHeader);
        CopyPurchaseDocument.SetParameters(DocType, DocNo, true, false);
        CopyPurchaseDocument.Run();
    end;

    local procedure CopySalesDocument(SalesHeader: Record "Sales Header"; DocNo: Code[20]; DocType: Enum "Sales Document Type From")
    var
        CopySalesDocument: Report "Copy Sales Document";
    begin
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.SetParameters(DocType, DocNo, true, false);
        CopySalesDocument.Run();
    end;

    local procedure TearDownVATPostingSetup(VATBusPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.FindSet();

        VATBusinessPostingGroup.Get(VATPostingSetup."VAT Bus. Posting Group");
        VATBusinessPostingGroup.Delete();
        repeat
            VATProductPostingGroup.Get(VATPostingSetup."VAT Prod. Posting Group");
            VATProductPostingGroup.Delete();
        until VATPostingSetup.Next() = 0;

        VATPostingSetup.DeleteAll();
    end;

    local procedure VerifyGLAccountForVAT(SalesLine: Record "Sales Line")
    var
        GLEntry: Record "G/L Entry";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        FindGLEntryForGLAccount(
          GLEntry, FindSalesPrepmtInvoiceNo(SalesLine."Document No."), GeneralPostingSetup."Sales Prepayments Account");
    end;

    local procedure VerifyGLAccountForNewVAT(SalesLine: Record "Sales Line"; InvoiceNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        FindGLEntryForGLAccount(GLEntry, InvoiceNo, VATPostingSetup."Sales VAT Account");
    end;

    local procedure VerifyGLEntry(InvoiceNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal; VATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntryForGLAccount(GLEntry, InvoiceNo, GLAccountNo);
        GLEntry.CalcSums(Amount, "VAT Amount");
        Assert.AreEqual(Amount, GLEntry.Amount, GLEntryAmountErr);
        Assert.AreEqual(VATAmount, GLEntry."VAT Amount", GLEntryAmountErr);
    end;

    local procedure VerifyGLEntryWithFilter(InvoiceNo: Code[20]; GLAccountNoFilter: Text; ExpectedAmount: Decimal; ExpectedVATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", InvoiceNo);
        GLEntry.SetFilter("G/L Account No.", GLAccountNoFilter);
        GLEntry.CalcSums(Amount, "VAT Amount");
        Assert.AreEqual(ExpectedAmount, GLEntry.Amount, GLEntry.FieldCaption(Amount));
        Assert.AreEqual(ExpectedVATAmount, GLEntry."VAT Amount", GLEntry.FieldCaption("VAT Amount"));
    end;

    local procedure VerifyGLEntryByBusPostingGroup(OrderNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        FindSalesPrepmtInvoice(SalesInvoiceHeader, OrderNo);
        FindGLEntryByBusPostingGroup(GLEntry, SalesInvoiceHeader."No.", SalesInvoiceHeader."Gen. Bus. Posting Group");
        Assert.AreEqual(Abs(GLEntry.Amount + GLEntry."VAT Amount"), Amount, GLEntryAmountErr);
    end;

    local procedure VerifyGLEntries(OrderNo: Code[20]; PrepmtAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", OrderNo);
        SalesLine.CalcSums("Prepmt. Line Amount");

        FindGLEntryForGLAccount(GLEntry, FindSalesPrepmtInvoiceNo(OrderNo), PrepmtAccountNo);
        Assert.AreEqual(SalesLine."Prepmt. Line Amount", -GLEntry.Amount, GLEntryAmountErr);
    end;

    local procedure VerifyPurchGLEntries(OrderNo: Code[20]; PrepmtAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", OrderNo);
        PurchaseLine.CalcSums("Prepmt. Line Amount");

        FindGLEntryForGLAccount(GLEntry, FindPurchPrepmtInvoiceNo(OrderNo), PrepmtAccountNo);
        Assert.AreEqual(PurchaseLine."Prepmt. Line Amount", GLEntry.Amount, GLEntryAmountErr);
    end;

    local procedure VerifyLedgerEntries(OrderNo: Code[20]; PrepmtLineAmount: Decimal; PostingDate: Date)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        FindSalesPrepmtInvoice(SalesInvoiceHeader, OrderNo);
        VerifyGLEntry(SalesInvoiceHeader."No.", GetReceivablesAccountNo(SalesInvoiceHeader."Customer Posting Group"), PrepmtLineAmount, 0);
        VerifyCustomerLedgerEntry(PrepmtLineAmount, SalesInvoiceHeader."No.", PostingDate);
        VerifyDetailedCustLedgerEntry(OrderNo, PrepmtLineAmount);
    end;

    local procedure VerifyLedgerEntriesByBusPostingGroup(OrderNo: Code[20]; PrepmtLineAmount: Decimal; PostingDate: Date)
    begin
        VerifyGLEntryByBusPostingGroup(OrderNo, PrepmtLineAmount);
        VerifyCustLedgerEntries(OrderNo, PrepmtLineAmount, PostingDate);
    end;

    local procedure VerifyCustLedgerEntries(OrderNo: Code[20]; PrepmtLineAmount: Decimal; PostingDate: Date)
    begin
        VerifyCustomerLedgerEntry(PrepmtLineAmount, FindSalesPrepmtInvoiceNo(OrderNo), PostingDate);
        VerifyDetailedCustLedgerEntry(OrderNo, PrepmtLineAmount);
    end;

    local procedure VerifyGLEntryAmountForSales(DocumentNo: Code[20]; ExpectedAmount: Decimal; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        FindGLEntry(GLEntry, DocumentNo, GLEntry."Gen. Posting Type"::Sale);
        GLEntry.TestField(Amount, -1 * ExpectedAmount);
    end;

    local procedure VerifyLedgerEntriesForCurrency(SalesHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        FindSalesPrepmtInvoice(SalesInvoiceHeader, SalesHeader."No.");
        VerifyGLEntry(
          SalesInvoiceHeader."No.", GetReceivablesAccountNo(SalesInvoiceHeader."Customer Posting Group"),
          Round(
            LibraryERM.ConvertCurrency(
              CalculateTotalPrepaymentInvoiceAmount(SalesInvoiceHeader), SalesHeader."Currency Code", '', WorkDate())), 0);
        VerifyVATEntry(SalesInvoiceHeader."No.");
        VerifyDetailedCustLedgerEntry(SalesHeader."No.", CalculateTotalPrepaymentAmount(SalesHeader));
        VerifyCustomerLedgerEntry(CalculateTotalPrepaymentAmount(SalesHeader), SalesInvoiceHeader."No.", SalesHeader."Posting Date");
    end;

    local procedure VerifyPrepaymentOnSalesLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Currency: Record Currency;
    begin
        Currency.InitRoundingPrecision();

        FindSalesLine(SalesLine, SalesHeader);
        repeat
            SalesLine.TestField("Prepayment %", SalesHeader."Prepayment %");
            Assert.AreNearlyEqual(Round(SalesLine."Line Amount" * SalesHeader."Prepayment %" / 100, Currency."Amount Rounding Precision"), SalesLine."Prepmt. Line Amount", 0.01, SalesLine.FieldName("Prepmt. Line Amount"));
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyPrepmtAmountOnSalesLine(SalesHeader: Record "Sales Header"; PrepaymentPercent: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        repeat
            SalesLine.TestField("Prepayment %", PrepaymentPercent);
            Assert.AreEqual(
              Round(SalesLine."Line Amount" * PrepaymentPercent / 100), SalesLine."Prepmt. Line Amount",
              StrSubstNo(PrepaymentAmountErr, SalesLine.FieldCaption("Prepmt. Line Amount")));
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyPrepaymentAmountDueDate(SalesHeader: Record "Sales Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesInvoiceNo: Code[20];
        PrepaymentAmount: Decimal;
    begin
        SalesInvoiceNo := FindSalesPrepmtInvoiceNo(SalesHeader."No.");
        PrepaymentAmount := CalculateTotalPrepaymentAmount(SalesHeader);

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceNo);
        SalesInvoiceLine.CalcSums("Amount Including VAT");
        SalesInvoiceLine.TestField("Amount Including VAT", PrepaymentAmount);
        VerifyCustomerLedgerEntry(PrepaymentAmount, SalesInvoiceNo, SalesHeader."Prepayment Due Date");
    end;

    local procedure VerifyCustomerLedgerEntry(PrepaymentAmount: Decimal; SalesInvoiceHeaderNo: Code[20]; PrepaymentDueDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeaderNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount);
        CustLedgerEntry.TestField(Amount, PrepaymentAmount);
        CustLedgerEntry.TestField("Due Date", PrepaymentDueDate);
    end;

    local procedure VerifyDetailedCustLedgerEntry(OrderNo: Code[20]; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::Invoice);
        DetailedCustLedgEntry.SetRange("Document No.", FindSalesPrepmtInvoiceNo(OrderNo));
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyPrepaymentAmount(OrderNo: Code[20]; PrepaymentLineAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", OrderNo);
        SalesLine.FindFirst();
        SalesLine.TestField("Prepmt. Line Amount", PrepaymentLineAmount);
        SalesLine.TestField("Prepmt Amt to Deduct", PrepaymentLineAmount);
        SalesLine.TestField("Prepmt. Amt. Inv.", PrepaymentLineAmount);
    end;

    local procedure VerifyPrepaymentAmounts(var SalesLine: Record "Sales Line"; OrderNo: Code[20])
    var
        SalesLine2: Record "Sales Line";
    begin
        SalesLine.FindSet();
        SalesLine2.SetRange("Document Type", SalesLine2."Document Type"::Order);
        SalesLine2.SetRange("Document No.", OrderNo);
        SalesLine2.FindSet();
        repeat
            SalesLine2.TestField("Prepmt. Line Amount", SalesLine."Prepmt. Line Amount");
            SalesLine2.TestField("Prepmt Amt to Deduct", SalesLine."Prepmt Amt to Deduct");
            SalesLine2.TestField("Prepmt. Amt. Inv.", SalesLine."Prepmt. Amt. Inv.");
            SalesLine2.Next();
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyPrepaymentCreditMemo(PrepaymentOrderNo: Code[20]; PostedPrepmtCrMemoNos: Code[20]; VATClauseCode: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoHeader.SetRange("Prepayment Order No.", PrepaymentOrderNo);
        SalesCrMemoHeader.FindFirst();
        SalesCrMemoHeader.TestField("No.", GetLastNoUsed(PostedPrepmtCrMemoNos));
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindFirst();
        SalesCrMemoLine.TestField("VAT Clause Code", VATClauseCode);
    end;

    local procedure VerifyPrepaymentInvoice(PrepaymentOrderNo: Code[20]; PostedPrepmtInvNos: Code[20]; VATClauseCode: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";

    begin
        FindSalesPrepmtInvoice(SalesInvoiceHeader, PrepaymentOrderNo);
        SalesInvoiceHeader.TestField("No.", GetLastNoUsed(PostedPrepmtInvNos));
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("VAT Clause Code", VATClauseCode);
    end;

    local procedure GetLastNoUsed(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        FindOpenNoSeriesLine(NoSeriesLine, NoSeriesCode);
        exit(NoSeriesLine."Last No. Used");
    end;

    local procedure FindOpenNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NoSeriesCode: Code[20])
    begin
        NoSeriesLine.Reset();
        NoSeriesLine.SetCurrentKey("Series Code", "Starting Date");
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.SetRange("Starting Date", 0D, WorkDate());
        if NoSeriesLine.FindLast() then begin
            NoSeriesLine.SetRange("Starting Date", NoSeriesLine."Starting Date");
            NoSeriesLine.SetRange(Open, true);
        end;
        NoSeriesLine.FindFirst();
    end;

    local procedure VerifyPrepaymentLineAmount(SalesLine: Record "Sales Line"; PrepaymentPercent: Decimal)
    var
        Currency: Record Currency;
    begin
        Currency.InitRoundingPrecision();
        SalesLine.TestField(
          "Prepmt. Line Amount",
          Round(SalesLine."Line Amount" * PrepaymentPercent / 100, Currency."Amount Rounding Precision"));
    end;

    local procedure VerifyPrepaymentOnOrder(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.TestField("Prepayment %", 0);  // Prepayment percent must be zero.
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.FindLast();

        // Prepayment Percent must not be zero.
        Assert.AreNotEqual(0, SalesLine."Prepayment %", StrSubstNo(PrepaymentPercentErr, SalesLine."Prepayment %"));
    end;

    local procedure VerifyPrepaymentPercent(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; PrepaymentPercent: Decimal; SalesPrepaymentPercent: Decimal)
    begin
        SalesHeader.TestField("Prepayment %", PrepaymentPercent);
        SalesLine.TestField("Prepayment %", SalesPrepaymentPercent);
    end;

    local procedure VerifyPrepaymentPercentInLines(var TempSalesLine: Record "Sales Line" temporary; var SalesLine: Record "Sales Line"; PrepaymentPercent: Decimal)
    begin
        SalesLine.FindSet();
        TempSalesLine.FindSet();
        repeat
            SalesLine.TestField("Prepayment %", TempSalesLine."Prepayment %" + PrepaymentPercent);
            SalesLine.Next();
        until TempSalesLine.Next() = 0;
    end;

    local procedure VerifySalesSeparateInvoicePrepAmounts(SalesOrderNo: Code[20]; SalesInvoiceNo: Code[20])
    var
        SalesOrderLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Line";
    begin
        // Verify Prepayment fields` values between 2 Sales Documents
        SalesOrderLine.SetRange("Document Type", SalesOrderLine."Document Type"::Order);
        SalesOrderLine.SetRange("Document No.", SalesOrderNo);
        SalesOrderLine.FindSet();
        SalesInvoiceLine.SetRange("Document Type", SalesOrderLine."Document Type"::Invoice);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceNo);
        SalesInvoiceLine.SetRange(Type, SalesOrderLine.Type::Item);
        SalesInvoiceLine.FindSet();
        repeat
            Assert.AreNearlyEqual(
              SalesOrderLine."Prepmt. Amt. Incl. VAT", SalesInvoiceLine."Prepmt. Amt. Incl. VAT", 0.01,
              SalesOrderLine.FieldName("Prepmt. Amt. Incl. VAT"));
            Assert.AreNearlyEqual(
              SalesOrderLine."Prepayment Amount", SalesInvoiceLine."Prepayment Amount", 0.01,
              SalesOrderLine.FieldName("Prepayment Amount"));
            SalesInvoiceLine.TestField("Prepmt. Line Amount", SalesOrderLine."Prepmt. Line Amount");
            SalesInvoiceLine.TestField("Prepmt. Amt. Inv.", SalesOrderLine."Prepmt. Amt. Inv.");
            Assert.AreNearlyEqual(
              SalesOrderLine."Prepmt. VAT Base Amt.", SalesInvoiceLine."Prepmt. VAT Base Amt.", 0.01,
              SalesOrderLine.FieldName("Prepmt. VAT Base Amt."));
            Assert.AreNearlyEqual(
              SalesOrderLine."Prepmt. Amount Inv. Incl. VAT", SalesInvoiceLine."Prepmt. Amount Inv. Incl. VAT", 0.01,
              SalesOrderLine.FieldName("Prepmt. Amount Inv. Incl. VAT"));
            SalesOrderLine.Next();
        until SalesInvoiceLine.Next() = 0;
    end;

    local procedure VerifyPurchSeparateInvoicePrepAmounts(PurchOrderNo: Code[20]; PurchInvoiceNo: Code[20])
    var
        PurchOrderLine: Record "Purchase Line";
        PurchInvoiceLine: Record "Purchase Line";
    begin
        // Verify Prepayment fields` values between 2 Purchase Documents
        PurchOrderLine.SetRange("Document Type", PurchOrderLine."Document Type"::Order);
        PurchOrderLine.SetRange("Document No.", PurchOrderNo);
        PurchOrderLine.FindSet();
        PurchInvoiceLine.SetRange("Document Type", PurchOrderLine."Document Type"::Invoice);
        PurchInvoiceLine.SetRange("Document No.", PurchInvoiceNo);
        PurchInvoiceLine.SetRange(Type, PurchInvoiceLine.Type::Item);
        PurchInvoiceLine.FindSet();
        repeat
            Assert.AreNearlyEqual(
              PurchOrderLine."Prepmt. Amt. Incl. VAT", PurchInvoiceLine."Prepmt. Amt. Incl. VAT", 0.01,
              PurchOrderLine.FieldName("Prepmt. Amt. Incl. VAT"));
            Assert.AreNearlyEqual(
              PurchOrderLine."Prepayment Amount", PurchInvoiceLine."Prepayment Amount", 0.01,
              PurchInvoiceLine.FieldName("Prepayment Amount"));
            PurchInvoiceLine.TestField("Prepmt. Line Amount", PurchOrderLine."Prepmt. Line Amount");
            PurchInvoiceLine.TestField("Prepmt. Amt. Inv.", PurchOrderLine."Prepmt. Amt. Inv.");
            Assert.AreNearlyEqual(
              PurchOrderLine."Prepmt. VAT Base Amt.", PurchInvoiceLine."Prepmt. VAT Base Amt.", 0.01,
              PurchInvoiceLine.FieldName("Prepmt. VAT Base Amt."));
            Assert.AreNearlyEqual(
              PurchOrderLine."Prepmt. Amount Inv. Incl. VAT", PurchInvoiceLine."Prepmt. Amount Inv. Incl. VAT", 0.01,
              PurchInvoiceLine.FieldName("Prepmt. Amount Inv. Incl. VAT"));
            PurchInvoiceLine.Next();
        until PurchOrderLine.Next() = 0;
    end;

    local procedure VerifySalesPrepaymentInvoice(PrepaymentOrderNo: Code[20])
    var
        DummySalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        DummySalesInvoiceHeader.SetRange("Prepayment Invoice", true);
        DummySalesInvoiceHeader.SetRange("Prepayment Order No.", PrepaymentOrderNo);
        Assert.RecordIsEmpty(DummySalesInvoiceHeader);
    end;

    local procedure VerifyVATEntry(SalesInvoiceHeaderNo: Code[20])
    var
        DummyVATEntry: Record "VAT Entry";
    begin
        DummyVATEntry.SetRange("Document Type", DummyVATEntry."Document Type"::Invoice);
        DummyVATEntry.SetRange("Document No.", SalesInvoiceHeaderNo);
        Assert.RecordIsNotEmpty(DummyVATEntry);
    end;

    local procedure VerifyVATEntries(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetFilter("Unrealized Amount", '<>0');
        VATEntry.FindFirst();
        Assert.AreEqual(VATEntry."Unrealized Amount", VATEntry."Remaining Unrealized Amount", RmngUnrealAmountErr);
    end;

    local procedure VerifyCustomerLedgerAmount(DocumentNo: Code[20]; RemaningAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", RemaningAmount);
    end;

    local procedure VerifySalesPrepmtAmtInclVAT(var SalesLine: Record "Sales Line"; PricesIncludingVAT: Boolean)
    var
        LineAmount: Decimal;
        PrepaymentAmount: Decimal;
        PrepaymentAmountInclVAT: Decimal;
    begin
        SalesLine.Find();
        LineAmount :=
          Round(SalesLine."Quantity Invoiced" * SalesLine."Unit Price", LibraryERM.GetCurrencyAmountRoundingPrecision(SalesLine."Currency Code"));
        PrepaymentAmount :=
          Round(LineAmount * SalesLine."Prepayment %" / 100, LibraryERM.GetCurrencyAmountRoundingPrecision(SalesLine."Currency Code"));
        PrepaymentAmountInclVAT := PrepaymentAmount;
        if not PricesIncludingVAT then
            PrepaymentAmountInclVAT :=
              Round(PrepaymentAmount * (100 + SalesLine."VAT %") / 100, LibraryERM.GetCurrencyAmountRoundingPrecision(SalesLine."Currency Code"));

        Assert.AreEqual(
          PrepaymentAmountInclVAT,
          SalesLine."Prepmt. Amt. Incl. VAT",
          StrSubstNo(AmountErr, SalesLine.FieldCaption("Prepmt. Amt. Incl. VAT"), PrepaymentAmountInclVAT, SalesLine.TableCaption));
    end;

    local procedure VerifyPurchPrepmtAmtInclVAT(var PurchaseLine: Record "Purchase Line"; PricesIncludingVAT: Boolean)
    var
        LineAmount: Decimal;
        PrepaymentAmount: Decimal;
        PrepaymentAmountInclVAT: Decimal;
    begin
        PurchaseLine.Find();
        LineAmount :=
          Round(PurchaseLine."Quantity Invoiced" * PurchaseLine."Direct Unit Cost", LibraryERM.GetCurrencyAmountRoundingPrecision(PurchaseLine."Currency Code"));
        PrepaymentAmount :=
          Round(LineAmount * PurchaseLine."Prepayment %" / 100, LibraryERM.GetCurrencyAmountRoundingPrecision(PurchaseLine."Currency Code"));
        PrepaymentAmountInclVAT := PrepaymentAmount;
        if not PricesIncludingVAT then
            PrepaymentAmountInclVAT :=
              Round(PrepaymentAmount * (100 + PurchaseLine."VAT %") / 100, LibraryERM.GetCurrencyAmountRoundingPrecision(PurchaseLine."Currency Code"));

        Assert.AreEqual(
          PrepaymentAmountInclVAT,
          PurchaseLine."Prepmt. Amt. Incl. VAT",
          StrSubstNo(AmountErr, PurchaseLine.FieldCaption("Prepmt. Amt. Incl. VAT"), PrepaymentAmountInclVAT, PurchaseLine.TableCaption));
    end;

    local procedure VerifyCustomerStatisticsTotalAmount(Customer: Record Customer; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; PrepmtSalesInvHeader: Record "Sales Invoice Header"; SalesInvHeader: Record "Sales Invoice Header")
    var
        CustStatisticsPage: TestPage "Customer Statistics";
        ExpectedAmount: Decimal;
    begin
        SalesHeader.CalcFields("Amount Including VAT");
        PrepmtSalesInvHeader.CalcFields("Amount Including VAT");
        SalesInvHeader.CalcFields("Amount Including VAT");
        ExpectedAmount :=
          Round(
            SalesInvHeader."Amount Including VAT" +
            SalesHeader."Amount Including VAT" * (1 - SalesLine."Quantity Invoiced" / SalesLine.Quantity) -
            PrepmtSalesInvHeader."Amount Including VAT" * (1 - SalesLine."Quantity Invoiced" / SalesLine.Quantity),
            LibraryERM.GetAmountRoundingPrecision());

        CustStatisticsPage.OpenView();
        CustStatisticsPage.GotoRecord(Customer);
        Assert.AreNearlyEqual(
          ExpectedAmount, CustStatisticsPage.GetTotalAmountLCY.AsDecimal(), 0.01, StatTotalAmtLCYErr);
    end;

    local procedure VerifyVendorStatisticsTotalAmount(Vendor: Record Vendor; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PrepmtPurchInvHeader: Record "Purch. Inv. Header"; PurchInvHeader: Record "Purch. Inv. Header")
    var
        VendStatisticsPage: TestPage "Vendor Statistics";
        ExpectedAmount: Decimal;
    begin
        PurchHeader.CalcFields("Amount Including VAT");
        PrepmtPurchInvHeader.CalcFields("Amount Including VAT");
        PurchInvHeader.CalcFields("Amount Including VAT");
        ExpectedAmount :=
          Round(
            PurchInvHeader."Amount Including VAT" +
            PurchHeader."Amount Including VAT" * (1 - PurchLine."Quantity Invoiced" / PurchLine.Quantity) -
            PrepmtPurchInvHeader."Amount Including VAT" * (1 - PurchLine."Quantity Invoiced" / PurchLine.Quantity),
            LibraryERM.GetAmountRoundingPrecision());

        VendStatisticsPage.OpenView();
        VendStatisticsPage.GotoRecord(Vendor);
        Assert.AreNearlyEqual(
          ExpectedAmount, VendStatisticsPage.GetTotalAmountLCY.AsDecimal(), 0.01, StatTotalAmtLCYErr);
    end;

    local procedure VerifyInvLineFromReceipt(DocumentNo: Code[20]; PostedDocNo: Code[20])
    var
        DummyPurchLine: Record "Purchase Line";
    begin
        DummyPurchLine.SetRange("Document Type", DummyPurchLine."Document Type"::Invoice);
        DummyPurchLine.SetRange("Document No.", DocumentNo);
        DummyPurchLine.SetRange(Type, DummyPurchLine.Type::Item);
        DummyPurchLine.SetRange("Receipt No.", PostedDocNo);
        DummyPurchLine.SetRange("Receipt Line No.", FindReceiptLineNo(PostedDocNo));
        Assert.RecordIsNotEmpty(DummyPurchLine);
    end;

    local procedure VerifyInvLineFromShipment(DocumentNo: Code[20]; PostedDocNo: Code[20])
    var
        DummySalesLine: Record "Sales Line";
    begin
        DummySalesLine.SetRange("Document Type", DummySalesLine."Document Type"::Invoice);
        DummySalesLine.SetRange("Document No.", DocumentNo);
        DummySalesLine.SetRange(Type, DummySalesLine.Type::Item);
        DummySalesLine.SetRange("Shipment No.", PostedDocNo);
        DummySalesLine.SetRange("Shipment Line No.", FindShipmentLineNo(PostedDocNo));
        Assert.RecordIsNotEmpty(DummySalesLine);
    end;

    local procedure VerifySalesPrepmtInvPostingNoSeries(PrepaymentOrderNo: Code[20]; PostedPrepmtNos: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Prepayment Order No.", PrepaymentOrderNo);
        SalesInvoiceHeader.FindFirst();
        VerifyNoSeries(SalesInvoiceHeader."No.", PostedPrepmtNos, SalesInvoiceHeader."No. Series", SalesInvoiceHeader.TableCaption);
    end;

    local procedure VerifySalesPrepmtCrMemoPostingNoSeries(PrepaymentOrderNo: Code[20]; PostedPrepmtNos: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Prepayment Order No.", PrepaymentOrderNo);
        SalesCrMemoHeader.FindFirst();
        VerifyNoSeries(SalesCrMemoHeader."No.", PostedPrepmtNos, SalesCrMemoHeader."No. Series", SalesCrMemoHeader.TableCaption);
    end;

    local procedure VerifyPurchPrepmtInvPostingNoSeries(PrepaymentOrderNo: Code[20]; PostedPrepmtNos: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Prepayment Order No.", PrepaymentOrderNo);
        PurchInvHeader.FindFirst();
        VerifyNoSeries(PurchInvHeader."No.", PostedPrepmtNos, PurchInvHeader."No. Series", PurchInvHeader.TableCaption);
    end;

    local procedure VerifyPurchPrepmtCrMemoPostingNoSeries(PrepaymentOrderNo: Code[20]; PostedPrepmtNos: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("Prepayment Order No.", PrepaymentOrderNo);
        PurchCrMemoHdr.FindFirst();
        VerifyNoSeries(PurchCrMemoHdr."No.", PostedPrepmtNos, PurchCrMemoHdr."No. Series", PurchCrMemoHdr.TableCaption);
    end;

    local procedure VerifyNoSeries(DocNo: Code[20]; ExpectedNoSeries: Code[20]; ActualNoSeries: Code[20]; TableCaption: Text)
    begin
        Assert.AreEqual(
          ExpectedNoSeries, ActualNoSeries, StrSubstNo(WrongPostingNoSeriesErr, TableCaption));
        VerifyNoSeriesOnGLEntries(DocNo, ExpectedNoSeries);
        VerifyNoSeriesOnVATEntries(DocNo, ExpectedNoSeries);
    end;

    local procedure VerifyNoSeriesOnGLEntries(DocNo: Code[20]; NoSeries: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.FindSet();
        repeat
            Assert.AreEqual(NoSeries, GLEntry."No. Series", StrSubstNo(WrongPostingNoSeriesErr, GLEntry.TableCaption));
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyNoSeriesOnVATEntries(DocNo: Code[20]; NoSeries: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.FindSet();
        repeat
            Assert.AreEqual(NoSeries, VATEntry."No. Series", StrSubstNo(WrongPostingNoSeriesErr, VATEntry.TableCaption));
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyPurchPstdInvoiceExtendedText(DocumentNo: Code[20]; ExtendedText: Text)
    var
        DummyPurchInvLine: Record "Purch. Inv. Line";
    begin
        DummyPurchInvLine.SetRange("Document No.", DocumentNo);
        DummyPurchInvLine.SetRange(Description, ExtendedText);
        Assert.RecordIsNotEmpty(DummyPurchInvLine);
    end;

    local procedure VerifySalesPstdInvoiceExtendedText(DocumentNo: Code[20]; ExtendedText: Text)
    var
        DummySalesInvLine: Record "Sales Invoice Line";
    begin
        DummySalesInvLine.SetRange("Document No.", DocumentNo);
        DummySalesInvLine.SetRange(Description, ExtendedText);
        Assert.RecordIsNotEmpty(DummySalesInvLine);
    end;

    local procedure VerifyPrepmtAndInvoiceVATEntries(InvoiceNo: Code[20]; PrepmtInvoiceNo: Code[20])
    var
        PrepmtInvoiceVATEntry: Record "VAT Entry";
        InvoiceVATEntry: Record "VAT Entry";
    begin
        PrepmtInvoiceVATEntry.SetRange("Document No.", PrepmtInvoiceNo);
        PrepmtInvoiceVATEntry.CalcSums(Base, Amount);

        InvoiceVATEntry.SetRange("Document No.", InvoiceNo);
        if PrepmtInvoiceVATEntry.Base < 0 then
            InvoiceVATEntry.SetFilter(Base, '>0')
        else
            InvoiceVATEntry.SetFilter(Base, '<0');
        InvoiceVATEntry.CalcSums(Base, Amount);
        Assert.AreEqual(
          Abs(InvoiceVATEntry.Base), Abs(PrepmtInvoiceVATEntry.Base),
          PrepmtInvoiceVATEntry.FieldCaption(Base));
        Assert.AreEqual(
          Abs(InvoiceVATEntry.Amount), Abs(PrepmtInvoiceVATEntry.Amount),
          PrepmtInvoiceVATEntry.FieldCaption(Amount));
    end;

    local procedure VerifyGLEntriesScenario_376012_Sales(InvoiceNo: Code[20]; PrepmtInvoiceNo: Code[20]; PrepmtAccNo: array[2] of Code[20]; PostAccNo: array[6] of Code[20])
    begin
        VerifyPrepmtAndInvoiceVATEntries(InvoiceNo, PrepmtInvoiceNo);

        // The rolling rounding depends on which order we post the lines, so the 56.25 may be split into 28.11+28.14 or 28.12+28.13 
        // Instead of validating each G/L Entry separately, we validate the total amount for each account.
        // VerifyGLEntry(PrepmtInvoiceNo, PrepmtAccNo[1], -28.11, -5.64);
        // VerifyGLEntry(PrepmtInvoiceNo, PrepmtAccNo[2], -28.14, -5.61);
        VerifyGLEntryWithFilter(PrepmtInvoiceNo, StrSubstNo('%1|%2', PrepmtAccNo[1], PrepmtAccNo[2]), -56.25, -11.25);

        // Instead of validating each G/L Entry separately, we validate the total amount for each account.
        // VerifyGLEntry(InvoiceNo, PrepmtAccNo[1], 28.11, 5.64);
        // VerifyGLEntry(InvoiceNo, PrepmtAccNo[2], 28.14, 5.61);
        VerifyGLEntryWithFilter(InvoiceNo, StrSubstNo('%1|%2', PrepmtAccNo[1], PrepmtAccNo[2]), 56.25, 11.25);

        // Instead of validating each G/L Entry separately, we validate the total amount for each account.
        // VerifyGLEntryWithFilter(InvoiceNo, StrSubstNo('%1|%2|%3', PostAccNo[1], PostAccNo[3], PostAccNo[5]), -28.11, -5.64);
        // VerifyGLEntryWithFilter(InvoiceNo, StrSubstNo('%1|%2|%3', PostAccNo[2], PostAccNo[4], PostAccNo[6]), -28.14, -5.61);
        VerifyGLEntryWithFilter(InvoiceNo, StrSubstNo('%1|%2|%3|%4|%5|%6', PostAccNo[1], PostAccNo[2], PostAccNo[3], PostAccNo[4], PostAccNo[5], PostAccNo[6]), -56.25, -11.25);
    end;

    local procedure VerifyGLEntriesScenario_376012_Purch(InvoiceNo: Code[20]; PrepmtInvoiceNo: Code[20]; PrepmtAccNo: array[2] of Code[20]; PostAccNo: array[6] of Code[20])
    begin
        VerifyPrepmtAndInvoiceVATEntries(InvoiceNo, PrepmtInvoiceNo);

        // The rolling rounding depends on which order we post the lines, so the 56.25 may be split into 28.11+28.14 or 28.12+28.13 
        // Instead of validating each G/L Entry separately, we validate the total amount for each account.
        // VerifyGLEntry(PrepmtInvoiceNo, PrepmtAccNo[1], 28.11, 5.64);
        // VerifyGLEntry(PrepmtInvoiceNo, PrepmtAccNo[2], 28.14, 5.61);
        VerifyGLEntryWithFilter(PrepmtInvoiceNo, StrSubstNo('%1|%2', PrepmtAccNo[1], PrepmtAccNo[2]), 56.25, 11.25);

        // Instead of validating each G/L Entry separately, we validate the total amount for each account.
        // VerifyGLEntry(InvoiceNo, PrepmtAccNo[1], -28.11, -5.64);
        // VerifyGLEntry(InvoiceNo, PrepmtAccNo[2], -28.14, -5.61);
        VerifyGLEntryWithFilter(InvoiceNo, StrSubstNo('%1|%2', PrepmtAccNo[1], PrepmtAccNo[2]), -56.25, -11.25);

        // Instead of validating each G/L Entry separately, we validate the total amount for each account.
        // VerifyGLEntryWithFilter(InvoiceNo, StrSubstNo('%1|%2|%3', PostAccNo[1], PostAccNo[3], PostAccNo[5]), 28.11, 5.64);
        // VerifyGLEntryWithFilter(InvoiceNo, StrSubstNo('%1|%2|%3', PostAccNo[2], PostAccNo[4], PostAccNo[6]), 28.14, 5.61);
        VerifyGLEntryWithFilter(InvoiceNo, StrSubstNo('%1|%2|%3|%4|%5|%6', PostAccNo[1], PostAccNo[2], PostAccNo[3], PostAccNo[4], PostAccNo[5], PostAccNo[6]), 56.25, 11.25);
    end;

    local procedure TransNoIsNotZeroInDtldCustLedgEntries(DocumentNo: Code[20])
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::Invoice);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.FindSet();
        repeat
            Assert.AreNotEqual(0, DetailedCustLedgEntry."Transaction No.", DtldCustLedgEntryErr);
        until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure TransNoIsNotZeroInDtldVendLedgEntries(DocumentNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetRange("Document Type", DetailedVendorLedgEntry."Document Type"::Invoice);
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.FindSet();
        repeat
            Assert.AreNotEqual(0, DetailedVendorLedgEntry."Transaction No.", DtldVendLedgEntryErr);
        until DetailedVendorLedgEntry.Next() = 0;
    end;

    local procedure CreateCustomerWithPrepmtPct(var Customer: Record Customer; LineGLAccount: Record "G/L Account")
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Prepayment %", LibraryRandom.RandInt(99));
        Customer.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Customer.Modify();
    end;

    local procedure CreateSalesOrderWithOneLine(CustomerNo: Code[20]; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LineGLAccount: Record "G/L Account")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LineGLAccount."No.", LibraryRandom.RandInt(10) + 5, LibraryRandom.RandDec(1000, 2));
        SalesLine.Validate("Qty. to Ship", Round(2 * SalesLine."Qty. to Ship" / 3, 1));
        SalesLine.Modify(true);
    end;

    local procedure CreateCustomerPrepmtPaymentAndApply(SalesInvHeader: Record "Sales Invoice Header")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        SalesInvHeader.CalcFields("Amount Including VAT");
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, SalesInvHeader."Bill-to Customer No.", 0);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", SalesInvHeader."No.");
        GenJournalLine.Validate(Amount, -SalesInvHeader."Amount Including VAT");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Validate(Prepayment, true);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateVendorWithPrepmtPct(var Vendor: Record Vendor; LineGLAccount: Record "G/L Account")
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Prepayment %", LibraryRandom.RandInt(99));
        Vendor.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Vendor.Modify();
    end;

    local procedure CreatePurchOrderWithOneLine(VendorNo: Code[20]; var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; LineGLAccount: Record "G/L Account")
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);

        CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account",
          LineGLAccount."No.", LibraryRandom.RandInt(10) + 5, LibraryRandom.RandDec(1000, 2));
        PurchLine.Validate("Qty. to Receive", Round(2 * PurchLine."Qty. to Receive" / 3, 1));
        PurchLine.Modify(true);
    end;

    local procedure CreateVendorPrepmtPaymentAndApply(PurchInvHeader: Record "Purch. Inv. Header")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        PurchInvHeader.CalcFields("Amount Including VAT");
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, PurchInvHeader."Pay-to Vendor No.", 0);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", PurchInvHeader."No.");
        GenJournalLine.Validate(Amount, PurchInvHeader."Amount Including VAT");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Validate(Prepayment, true);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure VerifyCustomerLedgerEntryForSalesPrepayment(OrderNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        FindSalesPrepmtInvoice(SalesInvoiceHeader, OrderNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Payment Method Code");
    end;

    local procedure VerifyVendLedgerEntryForPurchPrepayment(OrderNo: Code[20])
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvoiceHeader: Record "Purch. Inv. Header";
    begin
        FindPurchPrepmtInvoice(PurchInvoiceHeader, OrderNo);
        VendLedgerEntry.SetRange("Document Type", VendLedgerEntry."Document Type"::Invoice);
        VendLedgerEntry.SetRange("Document No.", PurchInvoiceHeader."No.");
        VendLedgerEntry.FindFirst();
        VendLedgerEntry.TestField("Payment Method Code");
    end;

    local procedure UpdatePrepaymentPercentageAndInvoiceDiscountAmount(
        var SalesHeader: Record "Sales Header";
        var SalesLine: Record "Sales Line";
        PrepaymentPercent: Decimal;
        InvoiceDiscountAmount: Decimal)
    begin
        SalesLine.Validate("Inv. Discount Amount", InvoiceDiscountAmount);
        SalesLine.Modify(true);

        SalesHeader.Validate("Prepayment %", PrepaymentPercent);
        SalesHeader.Modify(true);
    end;

    local procedure GetSalesPrepaymentInvoiceAmount(SalesHeader: Record "Sales Header"): Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", FindSalesPrepmtInvoiceNo(SalesHeader."No."));
        SalesInvoiceLine.CalcSums("Amount Including VAT");

        exit(SalesInvoiceLine."Amount Including VAT");
    end;

    local procedure PostPaymentToInvoice(
        AccountType: Enum "Gen. Journal Account Type";
        AccountNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine,
            GenJournalLine."Document Type"::Payment,
            AccountType,
            AccountNo,
            Amount);

        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ApplyAndPostPmtToMultipleSalesInvoices(var CustLedgEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; Amt: decimal)
    begin
        CustLedgEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        LibraryERM.SetAppliestoIdCustomer(CustLedgEntry);
        GenJournalLine.Validate("Applies-to ID", UserId);
        GenJournalLine.Validate(Amount, -Amt);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure GetTotalPrePaymentAmount(DocumentNo: Code[20]): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");
        exit(CustLedgerEntry."Remaining Amount");
    end;

    local procedure CreateCashReceiptJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::"Cash Receipts");
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 0);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PrepaymentConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CurrencyConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyUnApplyEntryPageHandler(var ApplyCustomerEntries: Page "Apply Customer Entries"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSalesHandler(var ItemChargeAssignmentSale: TestPage "Item Charge Assignment (Sales)")
    var
        QtytoInvoice: Variant;
    begin
        LibraryVariableStorage.Dequeue(QtytoInvoice);
        ItemChargeAssignmentSale."Qty. to Assign".SetValue(QtytoInvoice);
        ItemChargeAssignmentSale.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetPostedSalesDocLinesToReverseWithoutPrepmtInv(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.NoOfPostedInvoices.AssertEquals('(0)');
        PostedSalesDocumentLines.PostedInvoices."Document No.".AssertEquals('');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetPostedPurchDocLinesToReverseWithoutPrepmtInv(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    begin
        PostedPurchaseDocumentLines.NoOfPostedInvoices.AssertEquals('(0)');
        PostedPurchaseDocumentLines.PostedInvoices."Document No.".AssertEquals('');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetPostedSalesDocLinesToReverseWithoutPrepmtCrMemo(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.NoOfPostedCrMemos.AssertEquals('(0)');
        PostedSalesDocumentLines.PostedCrMemos."Document No.".AssertEquals('');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetPostedPurchDocLinesToReverseWithoutPrepmtCrMemo(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    begin
        PostedPurchaseDocumentLines.NoOfPostedCrMemos.AssertEquals('(0)');
        PostedPurchaseDocumentLines.PostedCrMemos."Document No.".AssertEquals('');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPurchDocRequestPageHandler(var CopyPurchaseDocument: TestRequestPage "Copy Purchase Document")
    begin
        CopyPurchaseDocument.DocumentType.SetValue(LibraryVariableStorage.DequeueText());
        CopyPurchaseDocument.DocumentNo.Lookup();
        CopyPurchaseDocument.DocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        CopyPurchaseDocument.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoicesModalPageHandler(var PostedPurchaseInvoices: TestPage "Posted Purchase Invoices")
    begin
        PostedPurchaseInvoices.FILTER.SetFilter("No.", LibraryVariableStorage.PeekText(1));
        PostedPurchaseInvoices."No.".AssertEquals('');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemosModalPageHandler(var PostedPurchaseCreditMemos: TestPage "Posted Purchase Credit Memos")
    begin
        PostedPurchaseCreditMemos.FILTER.SetFilter("No.", LibraryVariableStorage.PeekText(1));
        PostedPurchaseCreditMemos."No.".AssertEquals('');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopySalesDocRequestPageHandler(var CopySalesDocument: TestRequestPage "Copy Sales Document")
    begin
        CopySalesDocument.DocumentType.SetValue(LibraryVariableStorage.DequeueText());
        CopySalesDocument.DocumentNo.Lookup();
        CopySalesDocument.DocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        CopySalesDocument.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicesModalPageHandler(var PostedSalesInvoices: TestPage "Posted Sales Invoices")
    begin
        PostedSalesInvoices.FILTER.SetFilter("No.", LibraryVariableStorage.PeekText(1));
        PostedSalesInvoices."No.".AssertEquals('');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemosModalPageHandler(var PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos")
    begin
        PostedSalesCreditMemos.FILTER.SetFilter("No.", LibraryVariableStorage.PeekText(1));
        PostedSalesCreditMemos."No.".AssertEquals('');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    var
        MyNotifications: Record "My Notifications";
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
        OrderAmtTotalLCY: Variant;
        AmountInNotification: Decimal;
    begin
        if Notification.Id = UpdateCurrencyExchangeRates.GetMissingExchangeRatesNotificationID() then begin
            UpdateCurrencyExchangeRates.DisableMissingExchangeRatesNotification(Notification);
            Assert.IsFalse(
              MyNotifications.IsEnabled(UpdateCurrencyExchangeRates.GetMissingExchangeRatesNotificationID()),
              'Notification should have been disabled');
            UpdateCurrencyExchangeRates.OpenCurrencyExchangeRatesPageFromNotification(Notification);
            // Verify in CurrencyExchangeRatesModalPageHandler
        end else begin
            LibraryVariableStorage.Dequeue(OrderAmtTotalLCY);
            Evaluate(AmountInNotification, Notification.GetData('OrderAmountTotalLCY'));
            Assert.AreEqual(AmountInNotification, OrderAmtTotalLCY, 'Order Amount was different than expected');
            CustCheckCrLimit.ShowNotificationDetails(Notification);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CurrencyExchangeRatesModalPageHandler(var CurrencyExchangeRates: Page "Currency Exchange Rates"; var Response: Action)
    begin
        Response := ACTION::OK;
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsModalHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics."Amount Excl. Prepayment".AssertEquals(SalesOrderStatistics.AmountInclVAT_Invoicing.AsDecimal() - SalesOrderStatistics.PrepmtTotalAmount.AsDecimal());
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics."Amount Excl. Prepayment".AssertEquals(SalesOrderStatistics.AmountInclVAT_Invoicing.AsDecimal() - SalesOrderStatistics.PrepmtTotalAmount.AsDecimal());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestWorksheetLinesReqLiquidFundsPageHandler(var SuggestWorksheetLines: TestRequestPage "Suggest Worksheet Lines")
    var
        CashFlowNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CashFlowNo);
        SuggestWorksheetLines.CashFlowNo.SetValue(CashFlowNo);
        SuggestWorksheetLines."ConsiderSource[SourceType::""Liquid Funds""]".SetValue(false);  // Liquid Funds.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Service Orders""]".SetValue(false);
        SuggestWorksheetLines."ConsiderSource[SourceType::Receivables]".SetValue(true);  // Receivables.
        SuggestWorksheetLines."ConsiderSource[SourceType::Payables]".SetValue(false);  // Payables.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Purchase Order""]".SetValue(false);  // Purchase Order.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Cash Flow Manual Revenue""]".SetValue(false);  // Cash Flow Manual Revenue.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Sales Order""]".SetValue(true);  // Sales Order.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Budgeted Fixed Asset""]".SetValue(false);  // Budgeted Fixed Asset.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Cash Flow Manual Expense""]".SetValue(false);  // Cash Flow Manual Expense.
        SuggestWorksheetLines."ConsiderSource[SourceType::""Sale of Fixed Asset""]".SetValue(false);  // Sale of Fixed Asset.
        SuggestWorksheetLines."ConsiderSource[SourceType::""G/L Budget""]".SetValue(false);  // G/L Budget.
        SuggestWorksheetLines.OK().Invoke();
    end;
}

