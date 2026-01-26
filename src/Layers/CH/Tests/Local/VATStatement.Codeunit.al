codeunit 144005 "VAT Statement"
{
    // // [FEATURE] [Swiss] [VAT Statement] [Report]
    // Tests for Swiss Reports:
    //   1. Verify Amount in Swiss VAT Statement Report when the VAT Entries are open.
    //      AmountOnSwissVATStatementRepoAggregateByDate
    //      Covers Test Cases for Bug Id - 88612
    //   2. Verify Amount in Swiss VAT Statement Report when the VAT Entries are closed by a VAT Settlement.
    //      AmountOnSwissVATStatementRepoAggregateBySettlement
    //   3. Verify that the dates and register number filters are mutually exclusive on the report request page.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryCH: Codeunit "Library - CH";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        DatesShouldBeBlankedErr: Label 'The Starting and Ending dates should be blanked out when the  Closed with VAT Register No. field is filled.';
        ClosedWithRegisterNoShouldBeBlankedErr: Label 'The Closed with VAT Register No. field should be blanked out when the Starting and Ending dates are filled.';
        TestFieldErr: Label '%1 must have a value in %2', Comment = '%1 field; %2 table';

    [Test]
    [HandlerFunctions('SwissVATStatementReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AmountOnSwissVATStatementReportAggregateByDate()
    var
        VATStatementTemplateName: Code[10];
        PostedPurchaseInvoiceNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
        NormalRate: Integer;
        ReducedRate: Integer;
        NormalRateOld: Integer;
        ReducedRateOld: Integer;
    begin
        // [SCENARIO] Verify Cipher Amount in Swiss VAT Statement Report.

        // [GIVEN] Create VAT Posting Setup, General Posting Setup, G/L Account, create and Post Purchase and Sales Invoices, create two VAT Statement Lines.
        Initialize();
        VATStatementTemplateName := PrepareDataForSwissVATStatement(PostedPurchaseInvoiceNo, PostedSalesInvoiceNo);

        // [GIVEN] Prepare data for running the report
        SetReportVATRates(NormalRate, ReducedRate, NormalRateOld, ReducedRateOld);
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(VATStatementTemplateName);
        Commit();

        // [WHEN] Run Swiss VAT Statement Report based on some random tax percentages.
        REPORT.Run(REPORT::"Swiss VAT Statement", true, false);

        // [THEN] Cipher Amount in Swiss VAT Statement Report for both sales and purchase invoices.
        // [THEN] Ciphers for sales are exported with values: 302,312,342,382 / 303,313,343,383 (TFS 469330)
        // [THEN] Tax Amount is exported to cipher 510 (TFS 258760)
        // [THEN] VAT Rates are exported for current and precious periods (TFS 266933)
        // [THEN] FromDate and ToDate printed as start and end dates of previous year in Tax Calculation section (TFS 271803)
        VerifyReportData(PostedPurchaseInvoiceNo, PostedSalesInvoiceNo, NormalRate, ReducedRate, NormalRateOld, ReducedRateOld);
    end;

    [Test]
    [HandlerFunctions('SwissVATStatementReportRequestPageHandler,CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AmountOnSwissVATStatementReportAggregateBySettlement()
    var
        VATEntry: Record "VAT Entry";
        GLRegister: Record "G/L Register";
        GLAccountForSettlement: Record "G/L Account";
        PostedPurchaseInvoiceNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
        VATStatementTemplateName: Code[10];
        SettlementDocumentNo: Code[20];
        NormalRate: Integer;
        ReducedRate: Integer;
        NormalRateOld: Integer;
        ReducedRateOld: Integer;
    begin
        // [SCENARIO] Verify report content in the Swiss VAT Statement Report.

        // [GIVEN] Create VAT Posting Group, General Posting Group, G/L Account, create and Post Purchase and Sales Invoices, create VAT Statement Lines.
        Initialize();
        VATStatementTemplateName := PrepareDataForSwissVATStatement(PostedPurchaseInvoiceNo, PostedSalesInvoiceNo);

        // [GIVEN] Create VAT Settlement
        SettlementDocumentNo := LibraryUtility.GenerateRandomCode(VATEntry.FieldNo("Document No."), DATABASE::"VAT Entry");
        LibraryVariableStorage.Enqueue(SettlementDocumentNo);

        // [GIVEN] Create VAT Settlement account by running the Calc. and Post VAT Settlement
        LibraryERM.CreateGLAccount(GLAccountForSettlement);
        LibraryVariableStorage.Enqueue(GLAccountForSettlement."No.");
        Commit();
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement", true, false);

        VATEntry.SetRange("Posting Date", WorkDate());
        VATEntry.SetRange("Document No.", SettlementDocumentNo);
        VATEntry.FindFirst();
        GLRegister.SetRange("From VAT Entry No.", VATEntry."Entry No.");
        GLRegister.FindFirst();

        // [GIVEN] Prepare data for running the report
        SetReportVATRates(NormalRate, ReducedRate, NormalRateOld, ReducedRateOld);
        LibraryVariableStorage.Enqueue(GLRegister."No.");
        LibraryVariableStorage.Enqueue(VATStatementTemplateName);
        Commit();

        // [WHEN] Run the Swiss VAT Statement Report.
        REPORT.Run(REPORT::"Swiss VAT Statement", true);

        // [THEN] Cipher Amount in Swiss VAT Statement Report for both sales and purchase invoices.
        // [THEN] Ciphers for sales are exported with values: 302,312,342,382 / 303,313,343,383 (TFS 469330)
        // [THEN] Tax Amount is exported to cipher 510 (TFS 258760)
        // [THEN] VAT Rates are exported for current and precious periods (TFS 266933)
        // [THEN] FromDate and ToDate printed as start and end dates of previous year in Tax Calculation section (TFS 271803)
        VerifyReportData(PostedPurchaseInvoiceNo, PostedSalesInvoiceNo, NormalRate, ReducedRate, NormalRateOld, ReducedRateOld);
    end;

    [Test]
    [HandlerFunctions('SwissVATStatementReportFilterCheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ValidateRequestPageFiltersAreMutuallyExclusive()
    var
        PostedPurchaseInvoiceNo: Code[20];
        PostedSalesInvoiceNo: Code[20];
    begin
        // [SCENARIO] Verify that the dates and register number filters are mutually exclusive on the report request page.
        // Setup: Create VAT Posting Group, General Posting Group, G/L Account, create and Post Purchase and Sales Invoices, create VAT Statement Lines.
        Initialize();
        PrepareDataForSwissVATStatement(PostedPurchaseInvoiceNo, PostedSalesInvoiceNo);
        Commit();

        // Exercise AND Verify within the handler function: Run the Swiss VAT Statement Report:
        // 1. Set date filters first and ensure they are blanked out once the Closed with VAT Register No. field is filled.
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Swiss VAT Statement", true);

        // 2. Set the Closed with VAT Register No. field first and ensure they are blanked out once the date filter is filled.
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Swiss VAT Statement", true);
    end;

    [Test]
    [HandlerFunctions('SwissVATStatementReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RunSwissVATStatementReportWhenVATCipherSetupHasBlankFields()
    var
        VATCipherSetup: Record "VAT Cipher Setup";
        NormalRate: Integer;
        ReducedRate: Integer;
        NormalRateOld: Integer;
        ReducedRateOld: Integer;
    begin
        // [SCENARIO 235785] Should be no blank fields in VAT Cipher Setup when run Swiss VAT Statement report
        Initialize();

        // [GIVEN] VAT Cipher Setup where "Total Revenue" is blank
        VATCipherSetup.Get();
        VATCipherSetup."Total Revenue" := '';
        VATCipherSetup.Modify();
        Commit();

        // [WHEN] Run Swiss VAT Statement report
        SetReportVATRates(NormalRate, ReducedRate, NormalRateOld, ReducedRateOld);
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue('');

        asserterror REPORT.Run(REPORT::"Swiss VAT Statement", true);

        // [THEN] Error occured: "Total Revenue" must have a value
        Assert.ExpectedError(
          StrSubstNo(TestFieldErr, VATCipherSetup.FieldCaption("Total Revenue"), VATCipherSetup.TableCaption()));
        Assert.ExpectedErrorCode('TestField');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateNewVATCipher()
    var
        VATCipherCode: Record "VAT Cipher Code";
        VATCipherCodes: TestPage "VAT Cipher Codes";
        NewCode: Code[20];
        NewDescription: Text[50];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 235785] User is able to add VAT Cipher Setup Code
        Initialize();

        // [GIVEN] Open VAT Cipher Codes for new record
        NewCode := LibraryUtility.GenerateGUID();
        NewDescription :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(VATCipherCode.Description)), 1, MaxStrLen(VATCipherCode.Description));
        VATCipherCodes.OpenNew();

        // [WHEN] Enter "123" to Code, "Description 456" as Description
        VATCipherCodes.Code.SetValue(NewCode);
        VATCipherCodes.Description.SetValue(NewDescription);
        VATCipherCodes.Close();

        // [THEN] Ner VAT Cipher Code is created with Code = "123" and Description = "Description 456"
        VATCipherCode.Get(NewCode);
        VATCipherCode.TestField(Description, NewDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateVATCipherSetup()
    var
        VATCipherSetup: TestPage "VAT Cipher Setup";
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 235785] All fields in VAT Cipher Setup are editable
        Initialize();

        VATCipherSetup.OpenEdit();
        Assert.IsTrue(VATCipherSetup."Total Revenue".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Revenue of Non-Tax. Services".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Deduction of Tax-Exempt".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Deduction of Services Abroad".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Deduction of Transfer".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Deduction of Non-Tax. Services".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Reduction in Payments".Editable(), '');
        Assert.IsTrue(VATCipherSetup.Miscellaneous.Editable(), '');
        Assert.IsTrue(VATCipherSetup."Total Deductions".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Total Taxable Revenue".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Tax Normal Rate Serv. Before".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Tax Reduced Rate Serv. Before".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Tax Hotel Rate Serv. Before".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Acquisition Tax Before".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Total Owned Tax".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Tax Normal Rate Serv. After".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Tax Reduced Rate Serv. After".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Tax Hotel Rate Serv. After".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Acquisition Tax After".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Input Tax on Material and Serv".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Input Tax on Investsments".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Deposit Tax".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Input Tax Corrections".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Input Tax Cutbacks".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Total Input Tax".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Tax Amount to Pay".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Credit of Taxable Person".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Cash Flow Taxes".Editable(), '');
        Assert.IsTrue(VATCipherSetup."Cash Flow Compensations".Editable(), '');
    end;

    [Test]
    [HandlerFunctions('SwissVATStatementReportFieldValidationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateEndDateOfOldRates()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 271803] EndDateOfOldRates is updated on request page of Swiss VAT Statement report
        // [SCENARIO 271803] as last date of previous year for reported period
        // [SCENARIO 271803] and last date of current year when user validates EndDateOfOldRates
        Initialize();

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDate(10));
        Commit();
        REPORT.Run(REPORT::"Swiss VAT Statement", true, false);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"VAT Statement");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"VAT Statement");

        IsInitialized := true;

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibrarySetupStorage.Save(DATABASE::"VAT Cipher Setup");
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"VAT Statement");
    end;

    local procedure VerifyReportData(PostedPurchaseInvoiceNo: Code[20]; PostedSalesInvoiceNo: Code[20]; NormalRate: Integer; ReducedRate: Integer; NormalRateOld: Integer; ReducedRateOld: Integer)
    var
        VATEntryPurch: Record "VAT Entry";
        VATEntrySales: Record "VAT Entry";
        TotalTaxAmount: Decimal;
    begin
        LibraryReportDataset.LoadDataSetFile();

        // Normal and Reduced Rates
        LibraryReportDataset.AssertElementWithValueExists('FORMAT_NormalRateCur', StrSubstNo('%1%', NormalRate));
        LibraryReportDataset.AssertElementWithValueExists('FORMAT_ReducedRateCur', StrSubstNo('%1%', ReducedRate));
        LibraryReportDataset.AssertElementWithValueExists('FORMAT_NormalRateOld', StrSubstNo('%1%', NormalRateOld));
        LibraryReportDataset.AssertElementWithValueExists('FORMAT_ReducedRateOld', StrSubstNo('%1%', ReducedRateOld));

        // Verify the XML for the purchase part
        FindVATEntry(VATEntryPurch, PostedPurchaseInvoiceNo);
        FindVATEntry(VATEntrySales, PostedSalesInvoiceNo);
        LibraryReportDataset.AssertElementWithValueExists(
          'ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____400__', Round(VATEntryPurch.Amount, 0.1));

        LibraryReportDataset.AssertElementWithValueExists(
          'TaxCHF380', Round((VATEntryPurch.Base * NormalRateOld) / 100, 0.1));

        // Verify the XML for the sales part
        LibraryReportDataset.AssertElementWithValueExists(
          'TaxCHF381', Round((VATEntrySales.Base * NormalRate) / 100, 0.1));

        LibraryReportDataset.AssertElementWithValueExists(
          'ChiperAmount__VAT_Statement_Line___VAT_Statement_Cipher____310__', VATEntrySales.Base);
        LibraryReportDataset.AssertElementWithValueExists(
          'TaxCHF310', Round((VATEntrySales.Base * ReducedRateOld) / 100, 0.1));

        // Total Owned Tax (cipher 399)
        TotalTaxAmount :=
          Round((VATEntryPurch.Base * NormalRateOld) / 100, 0.1) +
          Round((VATEntrySales.Base * ReducedRateOld) / 100, 0.1) +
          Round((VATEntrySales.Base * NormalRate) / 100, 0.1);
        LibraryReportDataset.AssertElementWithValueExists(
          'TaxCHF300_TaxCHF310_TaxCHF340_TaxCHF380_TaxCHF301_TaxCHF311_TaxCHF341_TaxCHF381',
          TotalTaxAmount);

        // Cipher 510
        LibraryReportDataset.AssertElementWithValueExists(
          'ABS_Cipher510Amt_', Abs(TotalTaxAmount));

        VerifySalesCipherCodes();
        VerifyPurchaseCipherCodes();
        VerifyTaxCalculationDates();
    end;

    local procedure CreateAndPostSalesOrder(GenBusPostGr: Code[20]; VATBusPostGr: Code[20]; GLAccountNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomer(GenBusPostGr, VATBusPostGr);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          GLAccountNo, LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price");
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseInvoice(GenBusPostGr: Code[20]; VATBusPostGr: Code[20]; GLAccountNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryCH.CreateVendor(Vendor, GenBusPostGr, VATBusPostGr);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateGLAccount(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateCustomer(GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]): Code[20]
    var
        CountryRegion: Record "Country/Region";
        Customer: Record Customer;
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
    end;

    local procedure PrepareDataForSwissVATStatement(var PostedPurchaseInvoiceNo: Code[20]; var PostedSalesInvoiceNo: Code[20]): Code[10]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATCipherSetup: Record "VAT Cipher Setup";
        VATStatementLine: Record "VAT Statement Line";
        GLAccountNo: Code[20];
    begin
        VATCipherSetup.Get();
        LibraryCH.CreateGeneralPostingSetup(GeneralPostingSetup);
        LibraryCH.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          VATCipherSetup."Tax Reduced Rate Serv. Before", VATCipherSetup."Input Tax on Material and Serv");
        GLAccountNo := CreateGLAccount(GeneralPostingSetup, VATPostingSetup);

        LibraryCH.CreateVATStatementLine(
          VATStatementLine, VATPostingSetup, GLAccountNo, VATCipherSetup."Acquisition Tax Before",
          VATStatementLine."Amount Type"::Base, VATStatementLine."Gen. Posting Type"::Purchase);
        LibraryCH.CreateVATStatementLine(
          VATStatementLine, VATPostingSetup, GLAccountNo, VATCipherSetup."Input Tax on Material and Serv",
          VATStatementLine."Amount Type"::Amount, VATStatementLine."Gen. Posting Type"::Purchase);
        LibraryCH.CreateVATStatementLine(
          VATStatementLine, VATPostingSetup, GLAccountNo, VATCipherSetup."Tax Reduced Rate Serv. Before",
          VATStatementLine."Amount Type"::Base, VATStatementLine."Gen. Posting Type"::Sale);
        LibraryCH.CreateVATStatementLine(
          VATStatementLine, VATPostingSetup, GLAccountNo, VATCipherSetup."Input Tax Cutbacks",
          VATStatementLine."Amount Type"::Base, VATStatementLine."Gen. Posting Type"::Purchase);
        LibraryCH.CreateVATStatementLine(
          VATStatementLine, VATPostingSetup, GLAccountNo, VATCipherSetup."Acquisition Tax After",
          VATStatementLine."Amount Type"::Base, VATStatementLine."Gen. Posting Type"::Sale);

        PostedPurchaseInvoiceNo :=
          CreateAndPostPurchaseInvoice(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group", GLAccountNo);
        PostedSalesInvoiceNo :=
          CreateAndPostSalesOrder(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group", GLAccountNo);

        exit(VATStatementLine."Statement Template Name");
    end;

    local procedure SetReportVATRates(var NormalRate: Integer; var ReducedRate: Integer; var NormalRateOld: Integer; var ReducedRateOld: Integer)
    begin
        NormalRate := LibraryRandom.RandInt(10);
        ReducedRate := LibraryRandom.RandInt(10);
        NormalRateOld := LibraryRandom.RandInt(10);
        ReducedRateOld := LibraryRandom.RandInt(10);

        LibraryVariableStorage.Enqueue(NormalRate);
        LibraryVariableStorage.Enqueue(ReducedRate);
        LibraryVariableStorage.Enqueue(NormalRateOld);
        LibraryVariableStorage.Enqueue(ReducedRateOld);
    end;

    local procedure VerifySalesCipherCodes()
    begin
        LibraryReportDataset.GetLastRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('V300Caption', '302');
        LibraryReportDataset.AssertCurrentRowValueEquals('V301Caption', '303');
        LibraryReportDataset.AssertCurrentRowValueEquals('V310Caption', '312');
        LibraryReportDataset.AssertCurrentRowValueEquals('V311Caption', '313');
        LibraryReportDataset.AssertCurrentRowValueEquals('V340Caption', '342');
        LibraryReportDataset.AssertCurrentRowValueEquals('V341Caption', '343');
        LibraryReportDataset.AssertCurrentRowValueEquals('V380Caption', '382');
        LibraryReportDataset.AssertCurrentRowValueEquals('V381Caption', '383');
    end;

    local procedure VerifyPurchaseCipherCodes()
    begin
        LibraryReportDataset.GetLastRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('V400Caption', '400');
        LibraryReportDataset.AssertCurrentRowValueEquals('V405Caption', '405');
        LibraryReportDataset.AssertCurrentRowValueEquals('V410Caption', '410');
        LibraryReportDataset.AssertCurrentRowValueEquals('V415Caption', '415');
        LibraryReportDataset.AssertCurrentRowValueEquals('V420Caption', '420');
        LibraryReportDataset.AssertCurrentRowValueEquals('V479Caption', '479');
    end;

    local procedure VerifyTaxCalculationDates()
    begin
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'FromDateLbl', 'from ' + Format(CalcDate('<-CY>', WorkDate())));
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'ToDateLbl', 'to ' + Format(CalcDate('<-CY>', WorkDate()) - 1));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SwissVATStatementReportRequestPageHandler(var SwissVATStatement: TestRequestPage "Swiss VAT Statement")
    var
        NormalRate: Variant;
        ReducedRate: Variant;
        NormalRateOld: Variant;
        ReducedRateOld: Variant;
        ClosedRegisterNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(NormalRate);
        LibraryVariableStorage.Dequeue(ReducedRate);
        LibraryVariableStorage.Dequeue(NormalRateOld);
        LibraryVariableStorage.Dequeue(ReducedRateOld);

        LibraryVariableStorage.Dequeue(ClosedRegisterNo);
        if Format(ClosedRegisterNo) <> '' then
            SwissVATStatement.ClosedRgstrNo.SetValue(ClosedRegisterNo)
        else begin
            SwissVATStatement.StartingDate.SetValue(WorkDate());
            SwissVATStatement.EndingDate.SetValue(WorkDate());
        end;
        SwissVATStatement.Selection.SetValue('Open and Closed');
        SwissVATStatement.NormalRatePct.SetValue(NormalRate);
        SwissVATStatement.ReducedRatePct.SetValue(ReducedRate);
        SwissVATStatement.HotelRatePct.SetValue(LibraryRandom.RandInt(10));
        SwissVATStatement.NormalRateOldPct.SetValue(NormalRateOld);
        SwissVATStatement.ReducedRateOldPct.SetValue(ReducedRateOld);
        SwissVATStatement.HotelRateOldPct.SetValue(LibraryRandom.RandInt(10));
        SwissVATStatement."VAT Statement Name".SetFilter("Statement Template Name", LibraryVariableStorage.DequeueText());
        SwissVATStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SwissVATStatementReportFilterCheckRequestPageHandler(var SwissVATStatement: TestRequestPage "Swiss VAT Statement")
    var
        GLRegister: Record "G/L Register";
        SourceCodeSetup: Record "Source Code Setup";
        DatesShouldbeBlank: Variant;
        DatesShouldbeBlankBool: Boolean;
        Date: Text;
    begin
        SourceCodeSetup.FindFirst();
        GLRegister.SetFilter("Source Code", SourceCodeSetup."VAT Settlement");
        GLRegister.FindFirst();

        LibraryVariableStorage.Dequeue(DatesShouldbeBlank);
        DatesShouldbeBlankBool := DatesShouldbeBlank;
        if DatesShouldbeBlankBool then begin
            SwissVATStatement.StartingDate.SetValue(WorkDate());
            SwissVATStatement.EndingDate.SetValue(WorkDate());
            SwissVATStatement.ClosedRgstrNo.SetValue(GLRegister."No.");

            Date := SwissVATStatement.StartingDate.Value();
            Assert.AreEqual('', Date, DatesShouldBeBlankedErr);

            Date := SwissVATStatement.EndingDate.Value();
            Assert.AreEqual('', Date, DatesShouldBeBlankedErr);
        end else begin
            SwissVATStatement.ClosedRgstrNo.SetValue(GLRegister."No.");
            SwissVATStatement.StartingDate.SetValue(WorkDate());
            Assert.AreEqual('', SwissVATStatement.ClosedRgstrNo.Value, ClosedWithRegisterNoShouldBeBlankedErr);
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementRequestPageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    var
        DocumentNo: Variant;
        SettlementAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(SettlementAccountNo);
        CalcAndPostVATSettlement.StartingDate.SetValue(WorkDate());
        CalcAndPostVATSettlement.EndDateReq.SetValue(WorkDate());
        CalcAndPostVATSettlement.PostingDt.SetValue(WorkDate());
        CalcAndPostVATSettlement.VATDt.SetValue(WorkDate());
        CalcAndPostVATSettlement.DocumentNo.SetValue(DocumentNo);
        CalcAndPostVATSettlement.SettlementAcc.SetValue(SettlementAccountNo);
        CalcAndPostVATSettlement.ShowVATEntries.SetValue(true);
        CalcAndPostVATSettlement.Post.SetValue(true);
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SwissVATStatementReportFieldValidationRequestPageHandler(var SwissVATStatement: TestRequestPage "Swiss VAT Statement")
    var
        EndDate: Date;
    begin
        SwissVATStatement.StartingDate.SetValue('');
        SwissVATStatement.EndingDate.SetValue('');
        SwissVATStatement.EndDateOfOldRates.SetValue('');

        EndDate := LibraryVariableStorage.DequeueDate();
        SwissVATStatement.EndingDate.SetValue(EndDate);
        SwissVATStatement.EndDateOfOldRates.AssertEquals(CalcDate('<-CY>', EndDate) - 1);

        SwissVATStatement.EndDateOfOldRates.SetValue(EndDate);
        SwissVATStatement.EndDateOfOldRates.AssertEquals(CalcDate('<CY>', EndDate));

        SwissVATStatement.Cancel().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

