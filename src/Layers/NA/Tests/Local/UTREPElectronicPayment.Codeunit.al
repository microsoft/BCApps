codeunit 141038 "UT REP Electronic Payment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Electronic Payment] [Reports]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DialogErr: Label 'Dialog';
        AmountCap: Label 'Amt';
        ValueMustEqualMsg: Label 'Value must be equal.';
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        RowsExpectedMsg: Label 'There must be %1 rows in this report.', Comment = 'There must be 3 rows in this report.';
        LibraryJournals: Codeunit "Library - Journals";
        PaymentJournalTestCaptionTxt: Label 'Payment Journal - Test';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckICPartnerPaymentJournalTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournalTest: Report "Payment Journal - Test";
        AccountName: Text[50];
    begin
        // Purpose of the test is to validate CheckICPartner function of Report 10089 - Payment Journal - Test.

        // Setup: Create General Journal Line Account Type - IC Partner.
        Initialize();
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::"IC Partner", CreateICPartner(), WorkDate());  // Posting Date - WORKDATE.

        // Exercise: Execute function - CheckICPartner of Report - Payment Journal - Test.
        PaymentJournalTest.CheckICPartner(GenJournalLine, AccountName);

        // Verify: Verify updated Account Name with General Journal Line - Account Number.
        Assert.AreEqual(GenJournalLine."Account No.", AccountName, ValueMustEqualMsg);
    end;

    [Test]
    [HandlerFunctions('PaymentJournalTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypeGLAccountPaymentJournalTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate General Journal Line - OnAfterGetRecord Trigger of Report 10089 - Payment Journal - Test.

        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypePaymentJournalTest(GenJournalLine."Account Type"::"G/L Account", CreateGLAccount(), WorkDate());  // Posting Date - WORKDATE.
    end;

    [Test]
    [HandlerFunctions('PaymentJournalTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypeCustomerPaymentJournalTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate General Journal Line - OnAfterGetRecord Trigger of Report 10089 - Payment Journal - Test.

        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypePaymentJournalTest(GenJournalLine."Account Type"::Customer, CreateCustomer(), WorkDate());  // Posting Date - WORKDATE.
    end;

    [Test]
    [HandlerFunctions('PaymentJournalTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypeVendorPaymentJournalTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate General Journal Line - OnAfterGetRecord Trigger of Report 10089 - Payment Journal - Test.

        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypePaymentJournalTest(GenJournalLine."Account Type"::Vendor, CreateVendor(), WorkDate());  // Posting Date - WORKDATE.
    end;

    [Test]
    [HandlerFunctions('PaymentJournalTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypeBankAccountPaymentJournalTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate General Journal Line - OnAfterGetRecord Trigger of Report 10089 - Payment Journal - Test.

        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypePaymentJournalTest(GenJournalLine."Account Type"::"Bank Account", CreateBankAccount(), WorkDate());  // Posting Date - WORKDATE.
    end;

    [Test]
    [HandlerFunctions('PaymentJournalTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypeFixedAssetPaymentJournalTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate General Journal Line - OnAfterGetRecord Trigger of Report 10089 - Payment Journal - Test.

        // Setup.
        Initialize();
        OnAfterGetRecordAccountTypePaymentJournalTest(GenJournalLine."Account Type"::"Fixed Asset", CreateFixedAsset(), 0D);  // Posting Date - 0D.
    end;

    local procedure OnAfterGetRecordAccountTypePaymentJournalTest(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create General Journal Line.
        CreateGeneralJournalLine(GenJournalLine, AccountType, AccountNo, PostingDate);

        // Exercise.
        REPORT.Run(REPORT::"Payment Journal - Test");  // Opens handler - PaymentJournalTestRequestPageHandler.

        // Verify: Verify Batch and Account Number on generated Report - Payment Journal - Test.
        VerifyBatchAndAccountNo(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('GSTHSTInternetFileTransferRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportInternetFileTransferStartDateBlankError()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 10500 - GST/HST Internet File Transfer.

        // Setup.
        Initialize();
        OnPreReportInternetFileTransfer(0D, 0D);  // Start Date and End Date - 0D.
    end;

    [Test]
    [HandlerFunctions('GSTHSTInternetFileTransferRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportInternetFileTransferEndDateBlankError()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 10500 - GST/HST Internet File Transfer.

        // Setup.
        Initialize();
        OnPreReportInternetFileTransfer(WorkDate(), 0D);  // Start Date - WorkDate and End Date - 0D.
    end;

    [Test]
    [HandlerFunctions('GSTHSTInternetFileTransferRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportInternetFileTransferStartDateError()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 10500 - GST/HST Internet File Transfer.

        // Setup.
        Initialize();
        OnPreReportInternetFileTransfer(CalcDate('<1D>', WorkDate()), WorkDate());  // Start Date greater than End Date.
    end;

    local procedure OnPreReportInternetFileTransfer(StartDate: Date; EndDate: Date)
    begin
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // Enqueue value for Request Page handler - GSTHSTInternetFileTransferRequestPageHandler.
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);

        // Exercise.
        asserterror REPORT.RunModal(REPORT::"GST/HST Internet File Transfer");  // Opens Request Page handler - GSTHSTInternetFileTransferRequestPageHandler.

        // Verify: Verify error Code, Actual error message: Start Date should not be blank or End Date should not be blank or End Date should be greater than the Start Date.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('GSTHSTInternetFileTransferRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure WriteToFileInternetFileTransferError()
    begin
        // Purpose of the test is to validate WriteToFile function of Report 10500 - GST/HST Internet File Transfer.

        // Setup.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // Enqueue value for Request Page handler - GSTHSTInternetFileTransferRequestPageHandler.
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(WorkDate());

        // Exercise.
        asserterror REPORT.RunModal(REPORT::"GST/HST Internet File Transfer");  // Opens Request Page handler - GSTHSTInternetFileTransferRequestPageHandler.

        // Verify: Verify error Code, Actual error message: Account Number is not defined for GST/HST in Account Identifiers.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FormatDecimalsInternetFileTransferMaxDigitsError()
    var
        GSTHSTInternetFileTransfer: Report "GST/HST Internet File Transfer";
    begin
        // Purpose of the test is to validate FormatDecimals function of Report 10500 - GST/HST Internet File Transfer.

        // Setup.
        Initialize();

        // Exercise: Execute function - GSTHSTInternetFileTransfer of Report - GST/HST Internet File Transfer.
        asserterror
          GSTHSTInternetFileTransfer.FormatDecimals(LibraryRandom.RandDec(10, 8), LibraryRandom.RandIntInRange(1, 8), AmountCap);  // Random Decimal value with Maximum Decimal digits 8 and Maximum Digits Range 1 to 8.

        // Verify: Verify error Code, Actual error message: Amount in field Amt cannot have more than Maximum Digits.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FormatDecimalsOneInternetFileTransfer()
    var
        GSTHSTInternetFileTransfer: Report "GST/HST Internet File Transfer";
        Amount: Decimal;
        DecimalValueString: Text[30];
    begin
        // Purpose of the test is to validate FormatDecimals function of Report 10500 - GST/HST Internet File Transfer.

        // Setup: Create Random Decimal number with one Decimal digit.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        Amount := LibraryRandom.RandDec(10, 1);
        DecimalValueString := DelChr(Format(Amount), '=', '.');  // Calculation based on function - FormatDecimals of Report - GST/HST Internet File Transfer.
        DecimalValueString := InsStr(DecimalValueString, '0', StrLen(DecimalValueString) + 1);

        // Exercise and Verify: Execute function - GSTHSTInternetFileTransfer of Report - GST/HST Internet File Transfer. Verify returned value with expected Amount.
        Assert.AreEqual(
          DecimalValueString,
          GSTHSTInternetFileTransfer.FormatDecimals(Amount, LibraryRandom.RandIntInRange(1, 10), AmountCap), ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FormatDecimalsMoreThanOneInternetFileTransfer()
    var
        GSTHSTInternetFileTransfer: Report "GST/HST Internet File Transfer";
        Amount: Decimal;
        DecimalValueString: Text[30];
    begin
        // Purpose of the test is to validate FormatDecimals function of Report 10500 - GST/HST Internet File Transfer.

        // Setup: Create Random Decimal number with Decimal digits in Range 2 to 8(Maximum).
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        Amount := LibraryRandom.RandDec(10, LibraryRandom.RandIntInRange(2, 8));
        DecimalValueString := DelChr(Format(Amount), '=', '.');  // Calculation based on function - FormatDecimals of Report - GST/HST Internet File Transfer.

        // Exercise and Verify: Execute function - GSTHSTInternetFileTransfer of Report - GST/HST Internet File Transfer. Verify returned value with expected Amount.
        Assert.AreEqual(
          DecimalValueString,
          GSTHSTInternetFileTransfer.FormatDecimals(Amount, LibraryRandom.RandIntInRange(9, 10), AmountCap), ValueMustEqualMsg);  // Maximum digits Range 9 to 10.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FormatDecimalsValueZeroInternetFileTransfer()
    var
        GSTHSTInternetFileTransfer: Report "GST/HST Internet File Transfer";
    begin
        // Purpose of the test is to validate FormatDecimals function of Report 10500 - GST/HST Internet File Transfer.

        // Setup.
        Initialize();

        // Exercise & Verify: Execute function - GSTHSTInternetFileTransfer with Decimal value - 0 and Maximum digits Range 1 to 10. Verify returned string with expected string - 000.
        Assert.AreEqual(
          '000',
          GSTHSTInternetFileTransfer.FormatDecimals(0, LibraryRandom.RandIntInRange(1, 10), AmountCap), ValueMustEqualMsg);  // Decimal value - 0 and Maximum digits Range 1 to 10.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FormatDatesInternetFileTransfer()
    var
        GSTHSTInternetFileTransfer: Report "GST/HST Internet File Transfer";
        ExpectedDateString: Text[8];
    begin
        // Purpose of the test is to validate FormatDates function of Report 10500 - GST/HST Internet File Transfer.

        // Setup.
        Initialize();
        ExpectedDateString := Format(WorkDate(), 0, '<Closing><Year4><Month,2><Day,2>');  // Format String based on function - FormatDates of Report - GST/HST Internet File Transfer.

        // Exercise & Verify: Execute function - FormatDates with WORKDATE. Verify function returned string with expected date string.
        Assert.AreEqual(ExpectedDateString, GSTHSTInternetFileTransfer.FormatDates(WorkDate()), ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckForPositiveWithNegativeInternetFileTransfer()
    var
        GSTHSTInternetFileTransfer: Report "GST/HST Internet File Transfer";
        Amount: Decimal;
    begin
        // Purpose of the test is to validate CheckForPositive function of Report 10500 - GST/HST Internet File Transfer.

        // Setup.
        Initialize();
        Amount := LibraryRandom.RandDec(10, 2);

        // Exercise & Verify: Execute function - CheckForPositive with Negative value. Verify returned value with expected Amount.
        Assert.AreEqual(Amount, GSTHSTInternetFileTransfer.CheckForPositive(-Amount), ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckForPositiveInternetFileTransfer()
    var
        GSTHSTInternetFileTransfer: Report "GST/HST Internet File Transfer";
    begin
        // Purpose of the test is to validate CheckForPositive function of Report 10500 - GST/HST Internet File Transfer.

        // Setup.
        Initialize();

        // Exercise & Verify: Execute function - CheckForPositive with Positive value. Verify returned value with 0.
        Assert.AreEqual(0, GSTHSTInternetFileTransfer.CheckForPositive(LibraryRandom.RandDec(10, 2)), ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckForNegativeWithPositiveInternetFileTransfer()
    var
        GSTHSTInternetFileTransfer: Report "GST/HST Internet File Transfer";
        Amount: Decimal;
    begin
        // Purpose of the test is to validate CheckForNegative function of Report 10500 - GST/HST Internet File Transfer.

        // Setup.
        Initialize();
        Amount := LibraryRandom.RandDec(10, 2);

        // Exercise & Verify: Execute function - CheckForNegative with Positive value. Verify returned value with expected Amount.
        Assert.AreEqual(Amount, GSTHSTInternetFileTransfer.CheckForNegative(Amount), ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckForNegativeInternetFileTransfer()
    var
        GSTHSTInternetFileTransfer: Report "GST/HST Internet File Transfer";
    begin
        // Purpose of the test is to validate CheckForNegative function of Report 10500 - GST/HST Internet File Transfer.

        // Setup.
        Initialize();

        // Exercise & Verify: Execute function - CheckForNegative with Negative value. Verify returned value with 0.
        Assert.AreEqual(0, GSTHSTInternetFileTransfer.CheckForNegative(-LibraryRandom.RandDec(10, 2)), ValueMustEqualMsg);
    end;

    [Test]
    [HandlerFunctions('PaymentJournalTestExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentJournalTestReportPrintsLinesCorrectly()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentJournalTest: Report "Payment Journal - Test";
        Amount: Decimal;
        DocNo: Code[20];
        NumberOfLines: Integer;
        "Count": Integer;
    begin
        // [FEATURE] [Payment Journal] [Report]
        // [SCENARIO 276941] Report 10089 prints lines with same Document No, Account No, Posting Date, Amount correctly when Applies to doc.no is different
        Initialize();

        // [GIVEN] 3 Purchase general journal lines with same Document No, Account No, Posting Date, Amount, but different Applies To Doc No
        LibraryPurchase.CreateVendor(Vendor);
        DocNo := LibraryUtility.GenerateGUID();
        Amount := LibraryRandom.RandDecInRange(10, 1000, 2);
        NumberOfLines := 3;
        CreateGenJournalTemplateAndBatch(GenJournalBatch);
        for Count := 1 to NumberOfLines do
            CreatePaymentJournalLine(GenJournalLine, GenJournalBatch, Amount, Vendor."No.", DocNo);
        Commit();

        // [WHEN] Report 10089 runs
        GenJournalLine.SetRange("Account No.", Vendor."No.");
        PaymentJournalTest.SetTableView(GenJournalLine);
        LibraryReportValidation.SetFileName(Vendor."No.");
        PaymentJournalTest.Run();  // Invokes PaymentJournalTestExcelRequestPageHandler.

        // [THEN] Report prints all 3 lines
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.SetRange(GenJournalLine.FieldCaption(Description), Vendor."No.");
        Assert.AreEqual(NumberOfLines, LibraryReportValidation.CountRows(), StrSubstNo(RowsExpectedMsg, NumberOfLines));
    end;

    [Test]
    [HandlerFunctions('PaymentJournalTestExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentJournalTestForMultipleLinesForOneDocumentNo()
    var
        Vendor: Record Vendor;
        GenJournalLine: array[3] of Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocNo: Code[20];
        GLAccNo: Code[20];
        Index: Integer;
    begin
        // [FEATURE] [UT] [Payment Journal]
        // [SCENARIO 296949] Report 10089 "Payment Journal - Test" prints all lines with the same Document No.
        Initialize();

        // [GIVEN] Payment Journal Batch with 3 lines sharing same Vendor and Document No. but with different amounts
        LibraryPurchase.CreateVendor(Vendor);
        DocNo := LibraryUtility.GenerateGUID();
        GLAccNo := LibraryERM.CreateGLAccountNo();

        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::Payments);
        for Index := 1 to ArrayLen(GenJournalLine) do begin
            LibraryJournals.CreateGenJournalLine2(
              GenJournalLine[Index], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
              GenJournalLine[Index]."Document Type"::Payment, GenJournalLine[Index]."Account Type"::Vendor, Vendor."No.",
              GenJournalLine[Index]."Bal. Account Type"::"G/L Account", GLAccNo, LibraryRandom.RandDec(100, 2));
            GenJournalLine[Index].Validate("Document No.", DocNo);
            GenJournalLine[Index].Modify(true);
        end;
        LibraryReportValidation.SetFileName(Vendor."No.");
        Commit();

        // [WHEN] Run "Payment Journal - Test" report for 3 Payment Journal Lines, enqueue values for PaymentJournalTestExcelRequestPageHandler
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        REPORT.Run(REPORT::"Payment Journal - Test", true, false, GenJournalLine[1]);

        // [THEN] Report prints all 3 lines
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.SetRange(GenJournalLine[1].FieldCaption(Description), Vendor."No.");
        Assert.AreEqual(ArrayLen(GenJournalLine), LibraryReportValidation.CountRows(), StrSubstNo(RowsExpectedMsg, ArrayLen(GenJournalLine)));
    end;

    [Test]
    [HandlerFunctions('PaymentJournalTestRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PaymentJournalTestFillsReportCaptionCompanyTemplateAndBatch();
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT] [Payment Journal]
        // [SCENARIO 310578] Report 10089 "Payment Journal - Test" fills report caption, company name, template and batch correctly.
        Initialize();

        // [GIVEN] Gen. Journal Line.
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, CreateGLAccount(), WorkDate());

        // [WHEN] Run "Payment Journal - Test" report (opens handler - PaymentJournalTestRequestPageHandler).
        REPORT.Run(REPORT::"Payment Journal - Test");

        // [THEN] The following fields are correctly filled: Payment_Journal___TestCaptionLbl, CompanyInformation_Name, Gen__Journal_Batch___Journal_Template_Name_ and Gen__Journal_Batch__Name.
        VerifyReportCaptionCompanyTemplateAndBatch(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('PaymentJournalTestExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentJournalTestPrintsReportCaptionCompanyTemplateAndBatch();
    var
        Vendor: Record "Vendor";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [UT] [Payment Journal]
        // [SCENARIO 310578] Report 10089 "Payment Journal - Test" prints report caption, company name, template and batch correctly.
        Initialize();

        // [GIVEN] Gen. Journal Line.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::Payments);
        LibraryJournals.CreateGenJournalLine2(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor,
          Vendor."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(),
          LibraryRandom.RandDec(100, 2));
        LibraryReportValidation.SetFileName(Vendor."No.");
        Commit();

        // [WHEN] Run "Payment Journal - Test" report (opens handler - PaymentJournalTestExcelRequestPageHandler).
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        REPORT.Run(REPORT::"Payment Journal - Test", true, false, GenJournalLine);
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.SetRange(GenJournalLine.FieldCaption(Description), Vendor."No.");

        // [THEN] "Payment_Journal___TestCaption1" field = 10089's report caption.
        LibraryReportValidation.VerifyCellValue(1, 1, PaymentJournalTestCaptionTxt);
        // [THEN] "CompanyInformation_Name1" field = company name.
        CompanyInformation.Get();
        LibraryReportValidation.VerifyCellValue(2, 1, CompanyInformation.Name);
        // [THEN] "Gen__Journal_Batch___Journal_Template_Name_1" field = template name.
        LibraryReportValidation.VerifyCellValue(6, 9, GenJournalLine."Journal Template Name");
        // [THEN] "Gen__Journal_Batch__Name1" field = batch name.
        LibraryReportValidation.VerifyCellValue(8, 9, GenJournalLine."Journal Batch Name");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount."Last Check No." := LibraryUTUtility.GetNewCode();
        BankAccount.Insert();
        exit(BankAccount."No.")
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset."No." := LibraryUTUtility.GetNewCode();
        FixedAsset.Insert();
        exit(FixedAsset."No.");
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateICPartner(): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Code := LibraryUTUtility.GetNewCode();
        ICPartner.Name := ICPartner.Code;
        ICPartner.Insert();
        exit(ICPartner.Code);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateGenJournalTemplateAndBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate.Insert();
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Insert();

        // Enqueue value for Request Page handler - PaymentJournalTestRequestPageHandler
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
    end;

    local procedure CreatePaymentJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; Amount: Decimal; VendorNo: Code[20]; DocNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        GenJournalLine.Validate("Document No.", DocNo);
        GenJournalLine.Validate("Applies-to Doc. No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateAndBatch(GenJournalBatch);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Line No." := LibraryRandom.RandInt(10);
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Bal. Account Type" := GenJournalLine."Account Type";
        GenJournalLine."Bal. Account No." := GenJournalLine."Account No.";
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Computer Check";
        GenJournalLine."Applies-to ID" := LibraryUTUtility.GetNewCode();
        GenJournalLine."Posting Date" := PostingDate;
        GenJournalLine."Recurring Method" := "Gen. Journal Recurring Method".FromInteger(LibraryRandom.RandIntInRange(1, 6));  // Recurring Method - Option Range 1 to 6.
        GenJournalLine.Amount := LibraryRandom.RandDec(10, 2);
        GenJournalLine.Insert();
    end;

    local procedure VerifyBatchAndAccountNo(GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line_Journal_Batch_Name', GenJournalLine."Journal Batch Name");
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line__Document_No__', GenJournalLine."Document No.");
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line__Account_No__', GenJournalLine."Account No.");
    end;

    local procedure VerifyReportCaptionCompanyTemplateAndBatch(GenJournalLine: Record "Gen. Journal Line");
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'Payment_Journal___TestCaption',
          PaymentJournalTestCaptionTxt);
        LibraryReportDataset.AssertElementWithValueExists(
          'CompanyInformation_Name',
          CompanyInformation.Name);
        LibraryReportDataset.AssertElementWithValueExists(
          'Gen__Journal_Batch___Journal_Template_Name_',
          GenJournalLine."Journal Template Name");
        LibraryReportDataset.AssertElementWithValueExists(
          'Gen__Journal_Batch__Name',
          GenJournalLine."Journal Batch Name");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PaymentJournalTestRequestPageHandler(var PaymentJournalTest: TestRequestPage "Payment Journal - Test")
    var
        JournalTemplateName: Variant;
        JournalBatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        LibraryVariableStorage.AssertEmpty();
        PaymentJournalTest."Gen. Journal Line".SetFilter("Journal Template Name", JournalTemplateName);
        PaymentJournalTest."Gen. Journal Line".SetFilter("Journal Batch Name", JournalBatchName);
        PaymentJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PaymentJournalTestExcelRequestPageHandler(var PaymentJournalTest: TestRequestPage "Payment Journal - Test")
    begin
        PaymentJournalTest."Gen. Journal Line".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText());
        PaymentJournalTest."Gen. Journal Line".SetFilter("Journal Batch Name", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
        PaymentJournalTest.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GSTHSTInternetFileTransferRequestPageHandler(var GSTHSTInternetFileTransfer: TestRequestPage "GST/HST Internet File Transfer")
    var
        EndDate: Variant;
        StartDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        LibraryVariableStorage.AssertEmpty();
        GSTHSTInternetFileTransfer.StartDate.SetValue(StartDate);
        GSTHSTInternetFileTransfer.EndDate.SetValue(EndDate);
        GSTHSTInternetFileTransfer.OK().Invoke();
    end;
}

