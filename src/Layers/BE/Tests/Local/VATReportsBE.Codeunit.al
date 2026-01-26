codeunit 144010 "VAT Reports BE"
{
    // // [FEATURE] [VAT] [Reports]
    // 1. Test to verify the Amount in Customer Ledger Entry and the Correction Amount in VAT - VIES Correction
    //    should be calculated together in exported file for the same customer within same year.
    // 
    // Covers Test cases: for BE - Hotfix 358375
    // --------------------------------------------------------------------------
    // Test Function Name                                                  TFS ID
    // --------------------------------------------------------------------------
    // VatViewWithOneEntryAndCorrectionWithoutPostingDate                  100770

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryBEHelper: Codeunit "Library - BE Helper";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        CompanyVATNumberTxt: Label 'CompanyVATNumber', Locked = true;
        AmountTxt: Label 'Amount';
        NotFoundMsg: Label 'not found';
        AmountSumTxt: Label 'AmountSum', Locked = true;
        EntryNotFoundErr: Label 'Cannot find entry.';
        MustNotExistErr: Label 'Must not exist';
        CannotCreateXMLFileMsg: Label 'Problem when creating Intervat XML File.';

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATViesWithOneEntry()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
        Txt: Text;
        FileName: Text;
    begin
        Initialize();

        // Setup.
        CreateCustomer(Customer, true);
        CreateItemWithCost(Item);

        // Exercise.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        FileName := VATVIESDeclarationDiskOpen(0, WorkDate(), true, '', Customer."No.");

        // Verify
        Assert.IsTrue(FILE.Exists(FileName), FileName + ' ' + NotFoundMsg);
        Assert.IsTrue(GetPositionOfNameSpace(FileName, CompanyVATNumberTxt) <> 0, CompanyVATNumberTxt + ' ' + NotFoundMsg);
        Assert.IsTrue(GetPositionOfNameSpace(FileName, AmountTxt) <> 0, AmountTxt + ' ' + NotFoundMsg);

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        Txt := AmountTxt + '>' + Format(CustLedgerEntry."Sales (LCY)", 0, 9);

        Assert.IsTrue(GetPositionOfNameSpace(FileName, Txt) <> 0, Txt + ' ' + NotFoundMsg);
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATViesWithOneEntryAndRepresentative()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Representative: Record Representative;
    begin
        Initialize();

        // Setup.
        CreateCustomer(Customer, true);
        CreateItemWithCost(Item);
        LibraryBEHelper.CreateRepresentative(Representative);

        Representative."E-Mail" := '';
        Representative.Modify();

        // Exercise.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        asserterror VATVIESDeclarationDiskOpen(0, WorkDate(), true, Representative.ID, Customer."No.");

        // Verify

        Assert.ExpectedError('You have indicated that representative should be included. You must specify mandatory fields : E-Mail.');

        Representative.Delete();
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MissingInformationInRepresentative()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Representative: Record Representative;
        DocumentNo: Code[20];
        Txt: Text;
        FileName: Text;
    begin
        Initialize();

        // Setup.
        CreateCustomer(Customer, true);
        CreateItemWithCost(Item);
        LibraryBEHelper.CreateRepresentative(Representative);

        // Exercise.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        FileName := VATVIESDeclarationDiskOpen(0, WorkDate(), true, Representative.ID, Customer."No.");

        // Verify
        Assert.IsTrue(FILE.Exists(FileName), FileName + ' ' + NotFoundMsg);
        Assert.IsTrue(GetPositionOfNameSpace(FileName, CompanyVATNumberTxt) <> 0, CompanyVATNumberTxt + ' ' + NotFoundMsg);
        Assert.IsTrue(GetPositionOfNameSpace(FileName, AmountTxt) <> 0, AmountTxt + ' ' + NotFoundMsg);

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        Txt := AmountTxt + '>' + Format(CustLedgerEntry."Sales (LCY)", 0, 9);

        Assert.IsTrue(GetPositionOfNameSpace(FileName, Txt) <> 0, Txt + ' ' + NotFoundMsg);
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATViesWithTwoEntry()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
        AmountToTest: Decimal;
        FileName: Text;
    begin
        Initialize();

        // Setup.
        CreateCustomer(Customer, true);
        CreateItemWithCost(Item);

        // Exercise.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 2);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        AmountToTest := CustLedgerEntry."Sales (LCY)";
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", DocumentNo);
        AmountToTest += CustLedgerEntry."Sales (LCY)";
        FileName := VATVIESDeclarationDiskOpen(1, WorkDate(), true, '', Customer."No.");

        // Verify
        Assert.IsTrue(FILE.Exists(FileName), FileName + ' ' + NotFoundMsg);
        Assert.IsTrue(GetPositionOfNameSpace(FileName, CompanyVATNumberTxt) <> 0, CompanyVATNumberTxt + ' ' + NotFoundMsg);
        Assert.IsTrue(GetPositionOfNameSpace(FileName, AmountTxt) <> 0, AmountTxt + ' ' + NotFoundMsg);

        VerifyAmountFound(FileName, AmountToTest);
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATViesWithOneEntryAndCorrection()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
        Txt: Text;
        CorrectionAmount: Decimal;
        PostingDate: Date;
        FileName: Text;
    begin
        Initialize();

        // Setup.
        CreateCustomer(Customer, true);
        CreateItemWithCost(Item);
        PostingDate := CalcDate('<+8Y>', WorkDate());

        // Exercise.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CorrectionAmount := LibraryRandom.RandDec(100, 2);

        CreateVATVIESCorrection(Customer, -CorrectionAmount, PostingDate, true);

        FileName := VATVIESDeclarationDiskOpen(0, PostingDate, true, '', Customer."No.");

        // Verify

        Assert.IsTrue(FILE.Exists(FileName), FileName + ' ' + NotFoundMsg);

        Assert.IsTrue(GetPositionOfNameSpace(FileName, CompanyVATNumberTxt) <> 0, CompanyVATNumberTxt + ' ' + NotFoundMsg);

        Assert.IsTrue(GetPositionOfNameSpace(FileName, AmountTxt) <> 0, AmountTxt + ' ' + NotFoundMsg);

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);

        Txt := AmountTxt + '>' + Format(CustLedgerEntry."Sales (LCY)", 0, 9);

        Assert.IsTrue(GetPositionOfNameSpace(FileName, Txt) <> 0, Txt + ' ' + NotFoundMsg);

        Txt := AmountSumTxt + '="' + Format(CustLedgerEntry."Sales (LCY)" - CorrectionAmount, 0, 9);
        Assert.IsTrue(GetPositionOfNameSpace(FileName, Txt) <> 0, Txt + ' ' + NotFoundMsg);
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler,CannotCreateFileMessageHandler')]
    [Scope('OnPrem')]
    procedure VATViesWithZeroAmount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
        FileName: Text;
    begin
        Initialize();

        // Setup.
        CreateCustomer(Customer, true);
        CreateItemWithCost(Item);

        // Exercise.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", DocumentNo);

        FileName := VATVIESDeclarationDiskOpen(1, WorkDate(), true, '', Customer."No.");
        // Verify
        // Verification is in CannotCreateFileMessageHandler
        Assert.IsFalse(FILE.Exists(FileName), FileName);
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATViesWithoutVATRegNo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        Initialize();

        // Setup.
        CreateItemWithCost(Item);
        CreateCustomer(Customer, false);

        // Exercise.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        Customer.SetRange("No.", Customer."No.");

        // Verify
        asserterror VATVIESDeclarationDiskOpen(0, WorkDate(), true, '', Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATViesWithoutEnterPriceNoInComp()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        CompanyInformation: Record "Company Information";
    begin
        Initialize();

        // Setup.
        CreateItemWithCost(Item);
        CreateCustomer(Customer, true);
        CompanyInformation.Get();
        CompanyInformation."Enterprise No." := '';
        CompanyInformation.Modify();

        // Exercise.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        Customer.SetRange("No.", Customer."No.");

        // Verify
        asserterror VATVIESDeclarationDiskOpen(0, WorkDate(), true, '', Customer."No.");

        LibraryBEHelper.InitializeCompanyInformation();
    end;

    [Test]
    [HandlerFunctions('VATStatementSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure VATStatementTotal()
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        I: Integer;
    begin
        Initialize();

        // Setup.
        CreateCustomer(Customer, true);
        CreateItemWithCost(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementTemplate.Name, VATStatementName.Name);
        VATStatementLine.Validate("Row No.", Format(LibraryRandom.RandInt(100)));
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Gen. Posting Type", VATStatementLine."Gen. Posting Type"::Sale);
        VATStatementLine.Validate("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        VATStatementLine.Validate("VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
        VATStatementLine.Validate("Amount Type", VATStatementLine."Amount Type"::Base);
        VATStatementLine.Validate("Document Type", VATStatementLine."Document Type"::"All except Credit Memo");
        VATStatementLine.Validate("Print on Official VAT Form", true);
        VATStatementLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise.
        for I := 1 to 12 do begin
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
            SalesLine.SetHideValidationDialog(true);
            SalesLine.Validate("Unit Price", I * 100);
            SalesLine.Modify();
            SalesHeader.SetHideValidationDialog(true);
            SalesHeader.Validate("Posting Date", DMY2Date(1, I, Date2DMY(WorkDate(), 3) + 10));
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
        end;
        VATStatementSummaryOpen(
          DMY2Date(1, 1, Date2DMY(WorkDate(), 3) + 10), 12, true, 2, false, false, false,
          VATStatementName, VATStatementLine."Statement Template Name");
        LibraryReportDataset.LoadDataSetFile();

        // Verify
        for I := 1 to 12 do
            LibraryReportDataset.AssertElementWithValueExists('TotalAmount_' + Format(I) + '_', I * 100);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount_13_', Abs(-7800));
    end;

    [Test]
    [HandlerFunctions('VATStatementSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure VATStatementCorrections()
    var
        VATStatementLine: Record "VAT Statement Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATStatementName: Record "VAT Statement Name";
        PostingDate: Date;
        CorrectionAmount: Decimal;
        TotalLineAmount: Decimal;
        AmtInAddCurr: Boolean;
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO REP.020] VAT Correction Amount in 'Declaration Summary Report' (TC157006)
        Initialize();

        // [GIVEN] ACY is not set on General Ledger Setup
        AmtInAddCurr := false;
        // [GIVEN] Posted Sales Invoice has Amount = -X
        PostingDate := GetLastAccPeriodStartDate();
        TotalLineAmount := PostSalesDocument(SalesLine, SalesHeader, PostingDate, AmtInAddCurr);
        // [GIVEN] VAT Statement Line Row A
        CreateVATStatement(
          VATStatementLine, VATStatementLine."Calculate with"::Sign, VATStatementLine."Print with"::Sign,
          SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        // [GIVEN] Added VAT Correction = Y
        CorrectionAmount := AddManualVATCorrection(VATStatementLine, PostingDate, AmtInAddCurr);

        // [WHEN] Run Report 11311 VAT Statement Summary with 'Show ACY Amounts'=No
        VATStatementName.FindFirst();
        VATStatementName.Reset();
        VATStatementSummaryOpen(
          PostingDate, 12, true, 2, false, AmtInAddCurr, true, VATStatementName, VATStatementLine."Statement Template Name");

        // [THEN] Reported Row A has Amount = -X + Y
        VerifyVATStatementSummaryTotalInRow(VATStatementLine."Row No.", CorrectionAmount + TotalLineAmount);
    end;

    [Test]
    [HandlerFunctions('VATStatementSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure VATStatementCorrectionsACY()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementName: Record "VAT Statement Name";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostingDate: Date;
        CorrectionAmount: Decimal;
        TotalLineAmount: Decimal;
        AmtInAddCurr: Boolean;
    begin
        // [FEATURE] [MANVATCORR]
        // [SCENARIO REP.021] VAT Correction Amount in 'Declaration Summary Report' in ACY
        Initialize();

        // [GIVEN] ACY is set on General Ledger Setup
        CreateAddnlReportingCurrency();
        AmtInAddCurr := true;
        // [GIVEN] Posted Sales Invoice has Amount = -X; ACY = -A
        PostingDate := GetLastAccPeriodStartDate();
        TotalLineAmount := PostSalesDocument(SalesLine, SalesHeader, PostingDate, AmtInAddCurr);
        // [GIVEN] VAT Statement Line Row A
        CreateVATStatement(
          VATStatementLine, VATStatementLine."Calculate with"::Sign, VATStatementLine."Print with"::Sign,
          SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        // [GIVEN] Added VAT Correction : Amount = Y; ACY = B
        CorrectionAmount := AddManualVATCorrection(VATStatementLine, PostingDate, AmtInAddCurr);

        // [WHEN] Run Report 11311 VAT Statement Summary with 'Show ACY Amounts'=Yes
        VATStatementName.FindFirst();
        VATStatementName.Reset();
        VATStatementSummaryOpen(
          PostingDate, 12, true, 2, false, AmtInAddCurr, true, VATStatementName, VATStatementLine."Statement Template Name");

        // [THEN] Reported Row A has Amount = -A + B
        VerifyVATStatementSummaryTotalInRow(VATStatementLine."Row No.", CorrectionAmount + TotalLineAmount);
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATViewWithOneEntryAndCorrectionWithoutPostingDate()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
        CorrectionAmount: Decimal;
        FileName: Text;
    begin
        // Test to verify the Amount in Customer Ledger Entry and the Correction Amount in VAT - VIES Correction
        // should be calculated together in exported file for the same customer within same year.

        // Setup: Create Customer. Create and post Sales Invoice at WorkDate. Create VAT - VIES Correction.
        Initialize();
        DocumentNo := CreateAndPostSalesDocument(SalesLine, SalesHeader, Customer, WorkDate());
        CorrectionAmount := LibraryRandom.RandDec(100, 2);
        CreateVATVIESCorrection(Customer, -CorrectionAmount, WorkDate(), false); // FALSE means no need to fill in Posting Date.

        // Exercise: Run VAT - VIES Declaration Disk by VATVIESDeclarationDiskRequestPageHandler.
        FileName := VATVIESDeclarationDiskOpen(0, WorkDate(), false, '', Customer."No.");

        // Verify: Verify the Amount in exported file is calculated together.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        VerifyAmountFound(FileName, CustLedgerEntry."Sales (LCY)" - CorrectionAmount);
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATViesWithCustomerZeroBalance()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        ReportedAmount: Decimal;
        CorrectionAmount: Decimal;
        PostingDate: Date;
        FileName: Text;
    begin
        // [SCENARIO TFS107002] Customer with Zero Balance should not be in the XML File
        Initialize();

        // [GIVEN]
        PostingDate := LibraryRandom.RandDateFromInRange(WorkDate(), 100, 200);
        // [GIVEN] Create and post document for customer without correction
        CreateAndPostSalesDocument(SalesLine, SalesHeader, Customer, PostingDate);
        CustNo := Customer."No.";
        ReportedAmount := SalesLine.Amount;
        // [GIVEN] Create and post document for customer with zero-balanced correction
        CreateAndPostSalesDocument(SalesLine, SalesHeader, Customer, PostingDate);
        CorrectionAmount := SalesLine.Amount;
        CreateVATVIESCorrection(Customer, -CorrectionAmount, PostingDate, true);

        // [WHEN] Run VAT - VIES Declaration Disk by VATVIESDeclarationDiskRequestPageHandler.
        FileName := VATVIESDeclarationDiskOpen(0, PostingDate, true, '', StrSubstNo('%1|%2', Customer."No.", CustNo));

        // [THEN] Should be only one ReportedAmount in XML file
        VerifyAmountNotFound(FileName, CorrectionAmount);
        VerifyAmountNotFound(FileName, -CorrectionAmount);
        VerifyAmountFound(FileName, ReportedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InclNonDeductibleVATForBaseAmountType()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // [FEATURE] [UT] [Non Deductible VAT]
        // [SCENARIO 379117] User should be able to use "Incl. Non Deductible VAT" for VAT Settlement rows with "Amount Type" Base

        Initialize();
        VATStatementLine."Amount Type" := VATStatementLine."Amount Type"::Base;
        VATStatementLine.Validate("Incl. Non Deductible VAT", true);
        VATStatementLine.TestField("Incl. Non Deductible VAT", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InclNonDeductibleVATForNotAllowedAmountType()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // [FEATURE] [UT] [Non Deductible VAT]
        // [SCENARIO 379117] User should not be able to use "Incl. Non Deductible VAT" for VAT Settlement rows with "Amount Type" different than Base or Amount

        Initialize();
        VATStatementLine."Amount Type" := VATStatementLine."Amount Type"::"Unrealized Base";
        asserterror VATStatementLine.Validate("Incl. Non Deductible VAT", true);
        Assert.ExpectedError('Amount Type must not be Unrealized Base in VAT Statement Line Statement');
    end;

    [Test]
    [HandlerFunctions('ECSalesListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ShowLinesInECSalesListReportSecondSalesLineAmountIsZero()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        ExpectedValue: array[2] of Decimal;
        VATBusinessPostingGroupCode: Code[20];
        VATProdPostingSetupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [EC Sales List]
        // [SCENARIO 381864] EC Sales List prints a correct value in the "Total Value of Item Service Supplies" column if posted sales invoice has second line with Amount = 0
        Initialize();

        // [GIVEN] "VAT Product Posting Setup" with "VAT EU"."EU Service" = TRUE
        // [GIVEN] "VAT Bus. Product Group" = "X", "VAT Prod. Posting Group" = "Y1"
        // [GIVEN] "VAT Product Posting Setup" with "VAT Non-EU"."EU Service" = FALSE
        // [GIVEN] "VAT Bus. Product Group" = "X", "VAT Prod. Posting Group" = "Y2"
        CreatePostingSetups(GeneralPostingSetup, VATBusinessPostingGroupCode, VATProdPostingSetupCode);

        // [GIVEN] Customer with "Country/Region Code" from EU Country list
        // [GIVEN] "VAT Bus. Posting Group" = "X"
        // [GIVEN] Posted Sales Invoice for Customer with two lines
        // [GIVEN] 1st line "VAT Prod. Posting Group" = EUVATPostingSetup."VAT Prod. Posting Group" and Amount = 100,25
        // [GIVEN] 2nd line "VAT Prod. Posting Group" = NonEUVATPostingSetup."VAT Prod. Posting Group" and Amount = 0
        CreateAndPostSalesInvoice(ExpectedValue, GeneralPostingSetup, VATBusinessPostingGroupCode,
          LibraryRandom.RandDecInRange(1000, 2000, 5), VATProdPostingSetupCode[1], 0, VATProdPostingSetupCode[2]);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName());
        Commit();

        // [WHEN] Run "EC Sales List" report
        REPORT.Run(REPORT::"EC Sales List");

        // [THEN] Report should contains value in "Total Value of Item Service Supplies" column = 100,25
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueOnWorksheet(
          33, 3, Format(Round(ExpectedValue[1], 0.01), 0, '<Integer Thousand><Decimals,3><Filler Character,0>'), '1');
        LibraryReportValidation.VerifyCellValueOnWorksheet(
          37, 3, Format(Round(ExpectedValue[1], 0.01), 0, '<Integer Thousand><Decimals,3><Filler Character,0>'), '1');
    end;

    [Test]
    [HandlerFunctions('ECSalesListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ShowLinesInECSalesListReportFirstSalesLineAmountIsZero()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        ExpectedValue: array[2] of Decimal;
        VATBusinessPostingGroupCode: Code[20];
        VATProdPostingSetupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [EC Sales List]
        // [SCENARIO 381864] EC Sales List prints a correct value in the "Total Value of Item Service Supplies" column if posted sales invoice has first line with Amount = 0
        Initialize();

        // [GIVEN] "VAT Product Posting Setup" with "VAT EU"."EU Service" = TRUE
        // [GIVEN] "VAT Bus. Product Group" = "X", "VAT Prod. Posting Group" = "Y1"
        // [GIVEN] "VAT Product Posting Setup" with "VAT Non-EU"."EU Service" = FALSE
        // [GIVEN] "VAT Bus. Product Group" = "X", "VAT Prod. Posting Group" = "Y2"
        CreatePostingSetups(GeneralPostingSetup, VATBusinessPostingGroupCode, VATProdPostingSetupCode);

        // [GIVEN] Customer with "Country/Region Code" from EU Country list
        // [GIVEN] "VAT Bus. Posting Group" = "X"
        // [GIVEN] Posted Sales Invoice for Customer with two lines
        // [GIVEN] 1st line "VAT Prod. Posting Group" = NonEUVATPostingSetup."VAT Prod. Posting Group" and Amount = 0
        // [GIVEN] 2nd line "VAT Prod. Posting Group" = EUVATPostingSetup."VAT Prod. Posting Group" and Amount = 100
        CreateAndPostSalesInvoice(ExpectedValue, GeneralPostingSetup, VATBusinessPostingGroupCode,
          0, VATProdPostingSetupCode[2], LibraryRandom.RandIntInRange(1000, 2000), VATProdPostingSetupCode[1]);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName());
        Commit();

        // [WHEN] Run "EC Sales List" report
        REPORT.Run(REPORT::"EC Sales List");

        // [THEN] Report should contains value in "Total Value of Item Service Supplies" column = 100,00
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueOnWorksheet(
          33, 3, Format(ExpectedValue[2], 0, '<Integer Thousand><Decimals,3><Filler Character,0>'), '1');
        LibraryReportValidation.VerifyCellValueOnWorksheet(
          37, 3, Format(ExpectedValue[2], 0, '<Integer Thousand><Decimals,3><Filler Character,0>'), '1');
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATViesOnCustomerWithBlankCountryRegionCode()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FileName: Text;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 325903] Run report "VAT-VIES Declaration Disk" in case one of the Customers has blank "Country/Region Code".
        Initialize();

        // [GIVEN] Posted Sales document for Customer with blank "Country/Region Code".
        CreateAndPostSalesDocument(SalesLine, SalesHeader, Customer, WorkDate());
        CustomerNo := Customer."No.";
        Customer."Country/Region Code" := '';
        Customer.Modify();

        // [GIVEN] Posted Sales document for Customer with non-blank "Country/Region Code".
        CreateAndPostSalesDocument(SalesLine, SalesHeader, Customer, WorkDate());
        Customer.TestField("Country/Region Code");

        // [WHEN] Run report "VAT-VIES Declaration Disk".
        FileName := VATVIESDeclarationDiskOpen(0, WorkDate(), true, '', StrSubstNo('%1|%2', CustomerNo, Customer."No."));

        // [THEN] XML file is created.
        Assert.IsTrue(FILE.Exists(FileName), StrSubstNo('%1 %2', FileName, NotFoundMsg));
    end;

    local procedure Initialize()
    var
        VATVIESCorrection: Record "VAT VIES Correction";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"VAT Reports BE");
        LibraryVariableStorage.Clear();
        VATVIESCorrection.DeleteAll();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"VAT Reports BE");

        LibraryBEHelper.InitializeCompanyInformation();

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"VAT Reports BE");
    end;

    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    local procedure VATVIESDeclarationDiskOpen(PeriodType: Integer; ReportingDate: Date; TestMode: Boolean; RepresentativeID: Code[20]; CustomerNoFilter: Text) FileName: Text
    var
        Customer: Record Customer;
        VATVIESDeclarationDisk: Report "VAT-VIES Declaration Disk BE";
        FileManagement: Codeunit "File Management";
    begin
        LibraryVariableStorage.Enqueue(PeriodType);  // set period type 0 = Month (1 = Quarter

        if PeriodType = 0 then
            LibraryVariableStorage.Enqueue(Date2DMY(ReportingDate, 2)) // Month of transactions
        else
            LibraryVariableStorage.Enqueue(Round(Date2DMY(ReportingDate, 2) / 3, 1, '>')); // Quarter of transactions

        LibraryVariableStorage.Enqueue(Date2DMY(ReportingDate, 3));  // Year of transactions
        LibraryVariableStorage.Enqueue(TestMode);  // Run the declaration in test mode
        LibraryVariableStorage.Enqueue(RepresentativeID <> '');  // Representative
        if RepresentativeID <> '' then
            LibraryVariableStorage.Enqueue(RepresentativeID)
        else
            LibraryVariableStorage.Enqueue('');  // No Representative
        Customer.SetFilter("No.", CustomerNoFilter);
        Commit();

        VATVIESDeclarationDisk.SetTableView(Customer);
        FileName := FileManagement.ServerTempFileName('txt');
        VATVIESDeclarationDisk.SetFileName(FileName);
        VATVIESDeclarationDisk.Run();
    end;

    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    local procedure VATStatementSummaryOpen(StartDate: Date; NoOfPeriods: Integer; ReportErrors: Boolean; IncludeVATEntries: Integer; PrintInIntegers: Boolean; AmtInAddCurr: Boolean; AdditionalFilters: Boolean; VATStatementName: Record "VAT Statement Name"; VATStatementTempName: Code[10])
    begin
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(NoOfPeriods);
        LibraryVariableStorage.Enqueue(ReportErrors);
        LibraryVariableStorage.Enqueue(IncludeVATEntries);
        LibraryVariableStorage.Enqueue(PrintInIntegers);
        LibraryVariableStorage.Enqueue(AmtInAddCurr);
        LibraryVariableStorage.Enqueue(AdditionalFilters);
        LibraryVariableStorage.Enqueue(VATStatementTempName);
        Commit();
        REPORT.Run(REPORT::"VAT Statement Summary", true, true, VATStatementName);
    end;

    local procedure CreateVATVIESCorrection(var Customer: Record Customer; AmountToCorrect: Decimal; PostingDate: Date; AssignCorrectionDate: Boolean)
    var
        VATVIESCorrection: Record "VAT VIES Correction";
    begin
        VATVIESCorrection.Init();
        VATVIESCorrection.Validate("Period Type", 1);
        // Month - not important
        VATVIESCorrection.Validate("Declaration Period No.", Date2DMY(PostingDate, 2));
        VATVIESCorrection.Validate("Declaration Period Year", Date2DMY(PostingDate, 3));
        VATVIESCorrection."Line No." := GetVATVIESCorNextLineNo(VATVIESCorrection);
        VATVIESCorrection.Validate("Customer No.", Customer."No.");
        VATVIESCorrection.Validate(Amount, AmountToCorrect);
        if AssignCorrectionDate then
            VATVIESCorrection.Validate("Correction Date", PostingDate);
        VATVIESCorrection.Insert();
    end;

    local procedure GetVATVIESCorNextLineNo(VATVIESCorrection: Record "VAT VIES Correction"): Integer
    var
        ExistingVATVIESCorrection: Record "VAT VIES Correction";
    begin
        if ExistingVATVIESCorrection.IsEmpty() then
            exit(10000);
        ExistingVATVIESCorrection.SetRange("Period Type", VATVIESCorrection."Period Type");
        ExistingVATVIESCorrection.SetRange("Declaration Period No.", VATVIESCorrection."Declaration Period No.");
        ExistingVATVIESCorrection.SetRange("Declaration Period Year", VATVIESCorrection."Declaration Period Year");
        if ExistingVATVIESCorrection.FindLast() then
            exit(ExistingVATVIESCorrection."Line No." + 10000);
        exit(10000);
    end;

    local procedure AddManualVATCorrection(VATStatementLine: Record "VAT Statement Line"; PostingDate: Date; InACY: Boolean): Decimal
    var
        ManualVATCorrection: Record "Manual VAT Correction";
    begin
        ManualVATCorrection.DeleteAll();
        ManualVATCorrection.Init();
        ManualVATCorrection.Validate("Posting Date", PostingDate);
        ManualVATCorrection.Validate(Amount, LibraryRandom.RandDec(100, 2));
        ManualVATCorrection.Validate("Statement Template Name", VATStatementLine."Statement Template Name");
        ManualVATCorrection.Validate("Statement Name", VATStatementLine."Statement Name");
        ManualVATCorrection.Validate("Statement Line No.", VATStatementLine."Line No.");
        ManualVATCorrection.CalcFields("Row No.");
        ManualVATCorrection.Insert(true);

        if InACY then
            exit(ManualVATCorrection."Additional-Currency Amount");
        exit(ManualVATCorrection.Amount);
    end;

    local procedure CreateAddnlReportingCurrency(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CreateCurrencyAndExchangeRate();
        GeneralLedgerSetup.Modify(true);
        exit(GeneralLedgerSetup."Additional Reporting Currency");
    end;

    local procedure CreateAndPostSalesInvoice(var ExpectedValue: array[2] of Decimal; GeneralPostingSetup: Record "General Posting Setup"; VATBusinessPostingGroupCode: Code[20]; FirstLineUnitPrice: Decimal; FirstLineVATProdPostingSetupCode: Code[20]; SecondLineUnitPrice: Integer; SecondLineVATProdPostingSetupCode: Code[20])
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomerWithEUCountry(Customer, GeneralPostingSetup, VATBusinessPostingGroupCode);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        ExpectedValue[1] := CreateSalesLineWithVATProdPostGroupAndUnitPrice(
            SalesHeader, FirstLineVATProdPostingSetupCode, GeneralPostingSetup."Gen. Prod. Posting Group", FirstLineUnitPrice);
        ExpectedValue[2] := CreateSalesLineWithVATProdPostGroupAndUnitPrice(
            SalesHeader, SecondLineVATProdPostingSetupCode, GeneralPostingSetup."Gen. Prod. Posting Group", SecondLineUnitPrice);
        LibraryVariableStorage.Enqueue(CustomerNo);
        LibraryVariableStorage.Enqueue(SalesHeader."Posting Date");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
    begin
        Currency.Init();
        Currency.Validate(Code, 'BEF');
        // The ACY for this report can be either BEF or EUR
        Currency.Insert(true);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        LibraryERM.CreateGLAccount(GLAccount);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", GLAccount."No.");
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateVATStatement(var VATStatementLine: Record "VAT Statement Line"; CalcWith: Option; PrintWith: Option; VATBusPostingG: Code[20]; VATProdPostingG: Code[20])
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
    begin
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementTemplate.Name, VATStatementName.Name);

        VATStatementLine.Validate("Row No.", Format(LibraryRandom.RandInt(100)));
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Gen. Posting Type", VATStatementLine."Gen. Posting Type"::Sale);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATBusPostingG);
        VATStatementLine.Validate("VAT Prod. Posting Group", VATProdPostingG);
        VATStatementLine.Validate("Amount Type", VATStatementLine."Amount Type"::Base);
        VATStatementLine.Validate("Document Type", VATStatementLine."Document Type"::"All except Credit Memo");
        VATStatementLine.Validate("Print on Official VAT Form", true);
        VATStatementLine.Validate("Calculate with", CalcWith);
        VATStatementLine.Validate("Print with", PrintWith);
        VATStatementLine.Modify(true);
    end;

    local procedure CreateCustomer(var Customer: Record Customer; WithVATRegNo: Boolean)
    var
        CountryRegion: Record "Country/Region";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateCountryRegion(CountryRegion);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        if WithVATRegNo then
            Customer."VAT Registration No." := LibraryBEHelper.GetUniqueVATRegNo(CountryRegion.Code);
        Customer.Modify();
    end;

    local procedure CreateCustomerWithEUCountry(var Customer: Record Customer; GeneralPostingSetup: Record "General Posting Setup"; VATBusinessPostingGroupCode: Code[20]): Code[20]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion."EU Country/Region Code" := CountryRegion.Code;
        CountryRegion.Modify();
        Customer.Get(
          LibrarySales.CreateCustomerWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", VATBusinessPostingGroupCode));
        Customer."Country/Region Code" := CountryRegion.Code;
        Customer."Prices Including VAT" := true;
        Customer.Modify();
        exit(Customer."No.");
    end;

    local procedure CreateCountryRegion(var CountryRegion: Record "Country/Region")
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion."EU Country/Region Code" := CountryRegion.Code;
        CountryRegion.Modify();
    end;

    local procedure CreateItemNoWithPostingSetups(GenProdPostingGroupCode: Code[20]; VATProductPostingGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item."Gen. Prod. Posting Group" := GenProdPostingGroupCode;
        Item."VAT Prod. Posting Group" := VATProductPostingGroupCode;
        Item.Modify();
        exit(Item."No.");
    end;

    local procedure CreateItemWithCost(var Item: Record Item)
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreatePostingSetups(var GeneralPostingSetup: Record "General Posting Setup"; var VATBusinessPostingGroupCode: Code[20]; var VATProdPostingSetupCode: array[2] of Code[20])
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VATBusinessPostingGroupCode := VATBusinessPostingGroup.Code;

        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATProdPostingSetupCode[1] :=
          CreateVATPostingSetupEUService(VATPostingSetup, false, VATBusinessPostingGroupCode, VATProductPostingGroup.Code);

        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATProdPostingSetupCode[2] :=
          CreateVATPostingSetupEUService(VATPostingSetup, true, VATBusinessPostingGroupCode, VATProductPostingGroup.Code);

        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
    end;

    local procedure CreateSalesLineWithVATProdPostGroupAndUnitPrice(var SalesHeader: Record "Sales Header"; VATProdPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]; UnitPrice: Decimal): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItemNoWithPostingSetups(GenProdPostingGroupCode, VATProdPostingGroupCode), 1);
        SalesLine."Unit Price" := UnitPrice;
        SalesLine."VAT Prod. Posting Group" := VATProdPostingGroupCode;
        SalesLine.Modify();
        exit(SalesLine.Quantity * UnitPrice);
    end;

    local procedure CreateVATPostingSetupEUService(var VATPostingSetup: Record "VAT Posting Setup"; EUService: Boolean; VATBusinessPostingGroupCode: Code[20]; VATProductPostingGroupCode: Code[20]): Code[20]
    begin
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroupCode, VATProductPostingGroupCode);
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT";
        VATPostingSetup."VAT %" := LibraryRandom.RandIntInRange(10, 30);
        VATPostingSetup."EU Service" := EUService;
        VATPostingSetup.Modify();
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure PostSalesDocument(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; PostingDate: Date; InACY: Boolean): Decimal
    var
        Customer: Record Customer;
        DocumentNo: Code[20];
    begin
        DocumentNo := CreateAndPostSalesDocument(SalesLine, SalesHeader, Customer, PostingDate);
        exit(FindVATEntryByDocNo(DocumentNo, PostingDate, InACY));
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var Customer: Record Customer; PostingDate: Date): Code[20]
    var
        Item: Record Item;
    begin
        Clear(Customer);
        CreateCustomer(Customer, true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        CreateItemWithCost(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10000, 2));
        SalesLine.Modify();

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure FindVATEntryByDocNo(DocumentNo: Code[20]; PostingDate: Date; InACY: Boolean): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Posting Date", PostingDate);
        if VATEntry.FindFirst() then begin
            if InACY then
                exit(VATEntry."Additional-Currency Base");
            exit(VATEntry.Base);
        end;
        Error(EntryNotFoundErr);
    end;

    local procedure GetLastAccPeriodStartDate(): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.FindLast();
        exit(AccountingPeriod."Starting Date");
    end;

    local procedure GetPositionOfNameSpace(FileName: Text; NameSpace: Text): Integer
    var
        DataStream: InStream;
        XMLFile: File;
        Position: Integer;
        Txt: Text;
    begin
        XMLFile.Open(FileName);
        XMLFile.CreateInStream(DataStream);
        while not DataStream.EOS and (Position = 0) do begin
            DataStream.ReadText(Txt);
            Position := StrPos(Txt, NameSpace);
        end;
        XMLFile.Close();

        exit(Position)
    end;

    local procedure VerifyVATStatementSummaryTotalInRow(RowNo: Code[10]; TotalAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VAT_Statement_Line__Row_No__', RowNo);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount_1_', TotalAmount);
    end;

    local procedure VerifyAmountNotFound(FileName: Text; Amount: Decimal)
    var
        Txt: Text;
    begin
        Txt := AmountTxt + '>' + Format(Amount, 0, 9);
        Assert.IsFalse(GetPositionOfNameSpace(FileName, Txt) <> 0, Txt + ' ' + MustNotExistErr);
    end;

    local procedure VerifyAmountFound(FileName: Text; Amount: Decimal)
    var
        Txt: Text;
    begin
        Txt := AmountTxt + '>' + Format(Amount, 0, 9);
        Assert.IsTrue(GetPositionOfNameSpace(FileName, Txt) <> 0, Txt + ' ' + NotFoundMsg);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CannotCreateFileMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(CannotCreateXMLFileMsg, Message)
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationDiskRequestPageHandler(var VATVIESDeclarationDiskReport: TestRequestPage "VAT-VIES Declaration Disk BE")
    var
        DequeuedVar: Variant;
    begin
        VATVIESDeclarationDiskReport."VAT Entry".SetFilter("VAT Bus. Posting Group", '');
        VATVIESDeclarationDiskReport."VAT Entry".SetFilter("VAT Prod. Posting Group", '');
        // Choice
        // Setting this to 0 to run the report on a month base
        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATVIESDeclarationDiskReport.Choice.SetValue(DequeuedVar);
        // Vquarter: Month to run the report
        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATVIESDeclarationDiskReport.Vquarter.SetValue(DequeuedVar);
        // Vyear: Year to run the report
        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATVIESDeclarationDiskReport.Vyear.SetValue(DequeuedVar);
        // TestDeclaration: run the report in test mode on update on company information
        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATVIESDeclarationDiskReport.TestDeclaration.SetValue(DequeuedVar);
        // AddRepresentative: add a Representative - set to false
        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATVIESDeclarationDiskReport.AddRepresentative.SetValue(DequeuedVar);
        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATVIESDeclarationDiskReport.ID.SetValue(DequeuedVar);

        VATVIESDeclarationDiskReport.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementSummaryPageHandler(var VATStatementSummaryReport: TestRequestPage "VAT Statement Summary")
    var
        DequeuedVar: Variant;
        AdditionalFilters: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATStatementSummaryReport.StartDate.SetValue(DequeuedVar); // Start Date

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATStatementSummaryReport.NoOfPeriods.SetValue(DequeuedVar); // No of periods

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATStatementSummaryReport.ReportErrors.SetValue(DequeuedVar);  // Report Errors

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATStatementSummaryReport.Selection.SetValue(DequeuedVar);  // Incluce VAT Entries

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATStatementSummaryReport.PrintInIntegers.SetValue(DequeuedVar);  // Round to whole numbers

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATStatementSummaryReport.UseAmtsInAddCurr.SetValue(DequeuedVar);  // use ACY

        LibraryVariableStorage.Dequeue(DequeuedVar);  // Additional Filters
        AdditionalFilters := DequeuedVar;
        if AdditionalFilters then begin
            LibraryVariableStorage.Dequeue(DequeuedVar);  // Statement template Name
            VATStatementSummaryReport."VAT Statement Name".SetFilter("Statement Template Name", DequeuedVar);
        end;

        VATStatementSummaryReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ECSalesListRequestPageHandler(var ECSalesList: TestRequestPage "EC Sales List")
    begin
        ECSalesList."VAT Entry".SetFilter("Bill-to/Pay-to No.", LibraryVariableStorage.DequeueText());
        ECSalesList."VAT Entry".SetFilter("Posting Date", Format(LibraryVariableStorage.DequeueDate()));
        ECSalesList.SaveAsExcel(LibraryVariableStorage.DequeueText());
    end;
}

