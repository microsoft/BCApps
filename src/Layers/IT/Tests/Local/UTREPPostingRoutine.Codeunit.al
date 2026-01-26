codeunit 144068 "UT REP Posting Routine"
{
    // Test for feature POSTROUT - Posting Routine.
    // 
    // -----------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                               TFS ID
    // -----------------------------------------------------------------------------------------------------------------------
    // SeveralGLBookEntriesPerTransactionOnAccountBookSheetPrint                                                        59429

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountCap: Label 'Amnt';
        AmountLCYCap: Label 'AmountLCY';
        CompanyInfoAddressCap: Label 'CompanyInformation_2_';
        CompanyInfoNameCap: Label 'CompanyInformation_1_';
        CompanyInfoRegisterNumberCap: Label 'CompanyInformation_4_';
        CompanyInfoFiscalCodeCap: Label 'CompanyInformation_6_Caption';
        CorrectionAmountTxt: Label 'Correction of Remaining Amount';
        CrAmtLCYCap: Label 'CrAmtLCY_DtldCustLedgEntry';
        CustomerNumberCap: Label 'No_Customer';
        DecreasesAmntCap: Label 'DecreasesAmnt';
        DescriptionCap: Label 'Descr';
        DetailedCustLedgEntryNumberCap: Label 'EntryNo_DtldCustLedgEntry';
        DetailedVendLedgEntryNumberCap: Label 'EntryNo_DtldVendLedgEntry';
        DtldCustLedgEntryTypeCap: Label 'EntryType_DtldCustLedgEntry';
        DtldVendLedgEntryTypeCap: Label 'EntryType_DtldVendLedgEntry';
        DialogErr: Label 'Dialog';
        GLAccountNumberCap: Label 'G_L_Account_No_';
        GLBookEntryDebitAmountCap: Label 'GL_Book_Entry__Debit_Amount_';
        GLBookEntryGLAccountNumberCap: Label 'GL_Book_Entry__G_L_Account_No__';
        GLBookEntryNumberCap: Label 'GL_Book_Entry__Entry_No__';
        GLBookEntryAmountCap: Label 'StartOnHand___Amount';
        IcreasesAmntCap: Label 'IcreasesAmnt';
        LastPrintedPageNoCap: Label 'LastPrintedPageNo';
        PageCap: Label 'Page ';
        PageNoCap: Label 'Page %1/';
        PageNoPrefixCap: Label 'PageNoPrefix';
        PrintedEntriesTotalCap: Label 'PrintedEntriesTotalCaption';
        PrintedEntriesTotCap: Label 'PrintedEntriesTotCaption';
        ProgressiveTotCap: Label 'PrintedEntriesTotProgressiveTotCaption';
        PrintedEntriesTotalTxt: Label 'Printed Entries Total';
        ProgressiveTotalTxt: Label 'Printed Entries Total + Progressive Total';
        SignumCap: Label 'Signum';
        SignumAmountCap: Label 'Amount___Signum';
        StartOnHandAmountLCYCap: Label 'StartOnHandAmountLCY';
        StartOnHandAmtLCYCap: Label 'StartOnHandAmtLCY';
        TestValidationErr: Label 'TestValidation';
        TotalAmountLCYForRTCCap: Label 'TotalAmountLCYForRTC';
        TotalIcreasesAmntForRTCCap: Label 'TotalIcreasesAmntForRTC';
        VATRegisterCodeCap: Label 'ForCode_VAT_Register_Code';
        VendorNumberCap: Label 'No_Vendor';
        VATBookEntrySellToBuyFromNumberCap: Label 'VAT_Book_Entry__Sell_to_Buy_from_No__';
        VATBookEntryNumberCap: Label 'VATBookEntry__Entry_No__';
        LedgerAmountCap: Label 'LedgAmount';
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        UnpostedSalesDocumentsMsg: Label 'An unposted sales document with posting number %1 exists.\\%2.', Comment = '%1=Posting No.,%2=Sales Header RecordID';
        UnpostedPurchDocumentsMsg: Label 'An unposted puchase document with posting number %1 exists.\\%2.', Comment = '%1=Posting No.,%2=Purchase Header RecordID';
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('CustomerSheetPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DetailedCustLedgEntryOnAfterGetRecordCustSheetPrint()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [SCENARIO] Validate Detailed Customer Ledger Entry - OnAfterGetRecord Trigger of Report - 12104 Customer Sheet - Print.

        // [GIVEN] Create Sales Header with blank Posting Number and Detailed Customer Ledger Entry.
        Initialize();
        CreateCustomerEntries(
          DetailedCustLedgEntry, CreateSalesHeader(''), LibraryUTUtility.GetNewCode(),
          DetailedCustLedgEntry."Entry Type"::"Correction of Remaining Amount");  // Document Number, Blank Posting Number.
        LibraryVariableStorage.Enqueue(DetailedCustLedgEntry."Customer No.");  // Enqueue value for handler - CustomerSheetPrintRequestPageHandler.

        // [WHEN] Run report "Customer Sheet - Print"
        REPORT.Run(REPORT::"Customer Sheet - Print");  // Opens handler - CustomerSheetPrintRequestPageHandler.

        // [THEN] Verify Detailed Customer Ledger Entry - Customer Number, Entry Number and Amount LCY on XML of Report - Customer Sheet - Print.
        VerifyEntryNumberAndAmountOnReport(
          CustomerNumberCap, DetailedCustLedgEntryNumberCap, AmountLCYCap, DetailedCustLedgEntry."Customer No.",
          DetailedCustLedgEntry."Entry No.", DetailedCustLedgEntry."Amount (LCY)");
        VerifyValuesOnCustSheetPrintReport(DetailedCustLedgEntry);
    end;

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportPostingNumberVATRegGroupedError()
    begin
        // [SCENARIO] Validate OnPreReport Trigger of Report - 12108 VAT Register Grouped. with unposted document

        // Setup.
        Initialize();
        CreatePurchaseHeader(LibraryUTUtility.GetNewCode());  // Code value for Posting Number.

        // [WHEN] Run report "VAT Register Grouped"
        asserterror REPORT.Run(REPORT::"VAT Register Grouped");  // Opens handler - VATRegisterGroupedRequestPageHandler.

        // [THEN] Verify Error Code. Actual error message: There are unposted purchase documents with a reserved Posting No. Please post these before continuing.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportBlankRegCompanyNoVATRegGroupedError()
    begin
        // [SCENARIO] Validate OnPreReport Trigger of Report - 12108 VAT Register Grouped. with blank Register Company Number

        // Setup.
        Initialize();
        UpdateCompanyInfoRegisterCompanyNumber('');  // Blank Register Company Number.

        // [WHEN] Run report "VAT Register Grouped"
        asserterror REPORT.Run(REPORT::"VAT Register Grouped");  // Opens handler - VATRegisterGroupedRequestPageHandler.

        // [THEN] Verify Error Code. Actual error message: All Company Information related fields should be filled in on the request form.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATRegBufferOnAfterGetRecordVATRegGrouped()
    begin
        // [SCENARIO] Validate VAT Register - Buffer - OnAfterGetRecord Trigger of Report - 12108 VAT Register Grouped.
        // [GIVEN] Update Company Information - Register Company Number. Create VAT Register Buffer.
        // [WHEN] Run report "VAT Register Grouped"
        // [THEN] Verify VAT Register Buffer - VAT Register Code, Signum and Signum Amount on XML of Report - VAT Register Grouped.
        RegisterTypeVATRegisterGrouped(1, -1);  // Register Type as 1 and -1 for Sign Factor.
    end;

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATRegBufferOnAfterGetRecordRegisterTypeVATRegGrouped()
    var
        VATRegisterBuffer: Record "VAT Register - Buffer";
    begin
        // [SCENARIO] Validate VAT Register - Buffer - OnAfterGetRecord Trigger of Report - 12108 VAT Register Grouped for different VAT Register Types
        // [GIVEN] Update Company Information - Register Company Number. Create VAT Register Buffer.
        // [WHEN] Run report "VAT Register Grouped"
        // [THEN] Verify VAT Register Buffer - VAT Register Code, Signum and Signum Amount on XML of Report - VAT Register Grouped.
        RegisterTypeVATRegisterGrouped(VATRegisterBuffer."Register Type"::Purchase, 1);  // Value 1 for Sign Factor.
        RegisterTypeVATRegisterGrouped(VATRegisterBuffer."Register Type"::Sale, -1);  // Value -1 for Sign Factor.
    end;

    local procedure RegisterTypeVATRegisterGrouped(RegisterType: Option; SignFactor: Integer)
    var
        VATRegisterBuffer: Record "VAT Register - Buffer";
    begin
        Initialize();
        UpdateCompanyInfoRegisterCompanyNumber(LibraryUTUtility.GetNewCode());
        CreateVATRegisterBuffer(VATRegisterBuffer, RegisterType);

        REPORT.Run(REPORT::"VAT Register Grouped");  // Opens handler - VATRegisterGroupedRequestPageHandler.

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VATRegisterCodeCap, VATRegisterBuffer."VAT Register Code");
        LibraryReportDataset.AssertElementWithValueExists(SignumCap, SignFactor);
        LibraryReportDataset.AssertElementWithValueExists(SignumAmountCap, SignFactor * VATRegisterBuffer.Amount);
    end;

    [Test]
    [HandlerFunctions('AccountBookSheetPrintRequestPageHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportPostingNumberAccountBookSheetPrintError()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Validate OnPreReport Trigger of Report - 12109 Account Book Sheet - Print.

        // [GIVEN] Create Purchase Header with Posting Number.
        Initialize();
        CreatePurchaseHeaderWithNo(PurchHeader);
        LibraryVariableStorage.Enqueue(CreateGLAccount());  // Enqueue value for handler - AccountBookSheetPrintRequestPageHandler.

        // [WHEN] Run report "Account Book Sheet - Print"
        REPORT.Run(REPORT::"Account Book Sheet - Print");  // Opens handler - AccountBookSheetPrintRequestPageHandler.

        // [THEN] Verify Error Code. Actual error message: There are unposted purchase documents with a reserved Posting No. Please post these before continuing.
        // TFSID: 314849
        Assert.ExpectedMessage(
          StrSubstNo(
            UnpostedPurchDocumentsMsg, PurchHeader."Posting No.", PurchHeader.RecordId),
          LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AccountBookSheetPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GLBookEntryOnAfterGetRecordAccountBookSheetPrint()
    var
        GLBookEntry: Record "GL Book Entry";
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] Validate GL Book Entry - OnAfterGetRecord Trigger of Report - 12109 Account Book Sheet - Print.

        // [GIVEN] Create General Ledger Book Entry and General Ledger Entry.
        Initialize();
        CreateGLBookEntry(
          GLBookEntry, GLBookEntry."Source Type", LibraryUTUtility.GetNewCode(),
          CalcDate('<' + Format(-LibraryRandom.RandIntInRange(2, 10)) + 'D>', WorkDate()), LibraryRandom.RandInt(10), '');  // Source Number, Official Date less than WORKDATE and Progressive Number.
        CreateGLEntry(GLEntry, GLBookEntry);
        LibraryVariableStorage.Enqueue(GLEntry."G/L Account No.");  // Enqueue values for handler - AccountBookSheetPrintRequestPageHandler.

        // [WHEN] Run report "Account Book Sheet - Print"
        REPORT.Run(REPORT::"Account Book Sheet - Print");  // Opens handler - AccountBookSheetPrintRequestPageHandler.

        // [THEN] Verify G/L Account Number, G/L Book Entry Number and Amount on XML of Report - Account Book Sheet - Print.
        VerifyEntryNumberAndAmountOnReport(
          GLAccountNumberCap, GLBookEntryNumberCap, AmountCap, GLEntry."G/L Account No.", GLBookEntry."Entry No.", GLEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('AccountBookSheetPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SeveralGLBookEntriesPerTransactionOnAccountBookSheetPrint()
    var
        GLBookEntry: Record "GL Book Entry";
        GLEntry: Record "G/L Entry";
        AccNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO] Validate G/L Book Entries posted per one transaction in Report 12109 Account Book Sheet - Print.

        Initialize();
        GLBookEntry.DeleteAll();
        AccNo := CreateGLAccount();

        for i := 1 to 2 do begin
            CreateGLBookEntryWithAccNo(GLBookEntry, AccNo, LibraryRandom.RandDec(10, 2));
            CreateGLEntry(GLEntry, GLBookEntry);
        end;

        LibraryVariableStorage.Enqueue(AccNo);
        REPORT.Run(REPORT::"Account Book Sheet - Print");

        LibraryReportDataset.LoadDataSetFile();
        for i := 1 to 2 do begin
            AssertElementsWithValuesExists(
              GLAccountNumberCap, GLBookEntryNumberCap, GLBookEntryAmountCap,
              GLEntry."G/L Account No.", GLBookEntry."Entry No.", GLEntry.Amount);
            GLEntry.Next(-1);
            GLBookEntry.Next(-1);
        end;
    end;

    [Test]
    [HandlerFunctions('VendorSheetPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DetailedVendLedgEntryOnAfterGetRecordVendSheetPrint()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // [SCENARIO] Validate Detailed Vendor Ledger Entry - OnAfterGetRecord Trigger of Report - 12110 Vendor Sheet - Print.

        // [GIVEN] Create Purchase Header with blank Posting Number and Detailed Vendor Ledger Entry.
        Initialize();
        CreateVendorEntries(
          DetailedVendorLedgEntry, CreatePurchaseHeader(''), DetailedVendorLedgEntry."Entry Type"::"Correction of Remaining Amount",
          LibraryUTUtility.GetNewCode10()); // Blank Posting Number.
        LibraryVariableStorage.Enqueue(DetailedVendorLedgEntry."Vendor No.");  // Enqueue value for handler - VendorSheetPrintRequestPageHandler.

        // [WHEN] Run report "Vendor Sheet - Print"
        REPORT.Run(REPORT::"Vendor Sheet - Print");  // Opens handler - VendorSheetPrintRequestPageHandler.

        // [THEN] Verify Detailed Vendor Ledger Entry - Vendor Number, Entry No, Amount LCY on XML of Report - Vendor Sheet - Print.
        VerifyEntryNumberAndAmountOnReport(
          VendorNumberCap, DetailedVendLedgEntryNumberCap, AmountLCYCap, DetailedVendorLedgEntry."Vendor No.",
          DetailedVendorLedgEntry."Entry No.", DetailedVendorLedgEntry."Amount (LCY)");
        VerifyValuesOnVendSheetPrintReport(DetailedVendorLedgEntry);
    end;

    [Test]
    [HandlerFunctions('CustomerSheetPrintRequestPageHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportPostingNumberCustSheetPrintError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO] Validate OnPreReport Trigger of Report - 12104 Customer Sheet - Print.

        // [GIVEN] Create Sales Header with Posting Number.
        Initialize();

        // [WHEN] Run report "Customer Sheet - Print"
        LibraryVariableStorage.Enqueue(CreateSalesHeaderWithNo(SalesHeader));
        REPORT.Run(REPORT::"Customer Sheet - Print");

        // [THEN] Verify Error Code. Actual error message: There are unposted documents with a reserved Posting No. Please post these before continuing.
        // TFSID: 314849
        Assert.ExpectedMessage(
          StrSubstNo(
            UnpostedSalesDocumentsMsg, SalesHeader."Posting No.", SalesHeader.RecordId),
          LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VendorSheetPrintRequestPageHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportPostingNumberVendSheetPrintError()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Validate OnPreReport Trigger of Report - 12110 Vendor Sheet - Print.

        // Setup: Create Purchase Header with Posting Number.
        Initialize();

        // [WHEN] Run report "Vendor Sheet - Print"
        LibraryVariableStorage.Enqueue(CreatePurchaseHeaderWithNo(PurchHeader));
        REPORT.Run(REPORT::"Vendor Sheet - Print");

        // [THEN] Verify Error Code. Actual error message: There are unposted documents with a reserved Posting No. Please post these before continuing.
        // TFSID: 314849
        Assert.ExpectedMessage(
          StrSubstNo(
            UnpostedPurchDocumentsMsg, PurchHeader."Posting No.", PurchHeader.RecordId),
          LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportPostingNumberVATRegisterPrintError()
    begin
        // [SCENARIO] Validate OnPreReport Trigger of Report - 12120 VAT Register - Print. with Posting Number

        // [GIVEN] Create Purchase Header with Posting Number.
        Initialize();
        CreatePurchaseHeader(LibraryUTUtility.GetNewCode());
        LibraryVariableStorage.Enqueue(CreateVATRegister());  // Enqueue value for handler - VATRegisterPrintRequestPageHandler.

        // [WHEN] Run report "VAT Register - Print"
        asserterror REPORT.Run(REPORT::"VAT Register - Print");  // Opens handler - VATRegisterPrintRequestPageHandler.

        // [THEN] Verify Error Code. Actual error message: There are unposted purchase documents with a reserved Posting No. Please post these before continuing.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportPostingNumberGLBookPrintError()
    begin
        // [SCENARIO] Validate OnPreReport Trigger of Report - 12121 G/L Book - Print. with Posting Number with unposted document
        // [GIVEN] Create Purchase Header with Posting Number.
        Initialize();
        CreatePurchaseHeader(LibraryUTUtility.GetNewCode());
        EnqueueStartingDateAndEndingDate(WorkDate(), WorkDate());  // Enqueue values for handler - GLBookPrintRequestPageHandler.

        // [WHEN] Run report "G/L Book - Print"
        asserterror REPORT.Run(REPORT::"G/L Book - Print");  // Opens handler - GLBookPrintRequestPageHandler.

        // [THEN] Verify Error Code. Actual error message: There are unposted purchase documents with a reserved Posting No. Please post these before continuing.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportRegisterCompanyNumberGLBookPrintError()
    begin
        // [SCENARIO] Validate OnPreReport Trigger of Report - 12121 G/L Book - Print. with blank Register Company Number

        // [GIVEN] Update Company Information.
        Initialize();
        UpdateCompanyInfoRegisterCompanyNumber('');  // Blank Register Company Number.
        EnqueueStartingDateAndEndingDate(WorkDate(), WorkDate());  // Enqueue values for handler - GLBookPrintRequestPageHandler.

        // [WHEN] Run report "G/L Book - Print"
        asserterror REPORT.Run(REPORT::"G/L Book - Print");  // Opens handler - GLBookPrintRequestPageHandler.

        // [THEN] Verify Error Code. Actual error message: All Company Information related fields should be filled in on the request form.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportStartingDateGLBookPrintError()
    begin
        // [SCENARIO] Validate OnPreReport Trigger of Report - 12121 G/L Book - Print. with blank Starting Date
        Initialize();
        OnPreReportStartingEndingDateGLBookPrint(0D, WorkDate());  // Blank Starting Date, Ending Date - WORKDATE.
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportEndingDateGLBookPrintError()
    begin
        // [SCENARIO] Validate OnPreReport Trigger of Report - 12121 G/L Book - Print. with blank Ending Date
        Initialize();
        OnPreReportStartingEndingDateGLBookPrint(WorkDate(), 0D);  // Starting Date - WorkDate(), blank Ending Date.
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportGreaterEndingDateGLBookPrintError()
    begin
        // [SCENARIO] Validate OnPreReport Trigger of Report - 12121 G/L Book - Print with Ending Date less than Work Date
        Initialize();
        OnPreReportStartingEndingDateGLBookPrint(WorkDate(), CalcDate('<' + Format(-LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Starting Date - WorkDate(), Ending Date less than WORKDATE.
    end;

    local procedure OnPreReportStartingEndingDateGLBookPrint(StartingDate: Date; EndingDate: Date)
    begin
        EnqueueStartingDateAndEndingDate(StartingDate, EndingDate);  // Enqueue values for handler - GLBookPrintRequestPageHandler.

        asserterror REPORT.Run(REPORT::"G/L Book - Print");  // Opens handler - GLBookPrintRequestPageHandler.

        // Verify: Verify Error Code. Actual error message: Validation error for Field:StartingDate,  Message = 'Starting Date must not be blank.'. or Field:EndingDate,  Message = 'Ending Date must not be blank.'.
        // or Field:EndingDate,  Message = 'Ending Date must not be less than Starting Date'.
        Assert.ExpectedErrorCode(TestValidationErr);
    end;

    [Test]
    [HandlerFunctions('ReprintGLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportLastPrintingDateGLBookPrintError()
    begin
        // [SCENARIO] Validate OnPreReport Trigger of Report - 12121 G/L Book - Print. with Ending Date greater than Work Date
        Initialize();
        OnPreReportLastPrintingDateGLBookPrint(WorkDate(), CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>'));  // Last General Journal Printing Date - WORKDATE and Ending Date - greater than WORKDATE.
    end;

    [Test]
    [HandlerFunctions('ReprintGLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportWithoutLastPrintingDateGLBookPrintError()
    begin
        // [SCENARIO] Validate OnPreReport Trigger of Report - 12121 G/L Book - Print. with blank Printing Date
        Initialize();
        OnPreReportLastPrintingDateGLBookPrint(0D, WorkDate());  // Blank Last General Journal Printing Date  and Ending Date - WORKDATE.
    end;

    local procedure OnPreReportLastPrintingDateGLBookPrint(LastGenJourPrintingDate: Date; EndingDate: Date)
    begin
        // Update G/L Setup - Last General Journal Printing Date.
        UpdateGLSetupLastGenJourPrintingDate(LastGenJourPrintingDate);
        LibraryVariableStorage.Enqueue(EndingDate);  // Enqueue value for handler - ReprintGLBookPrintRequestPageHandler.

        // Exercise.
        asserterror REPORT.Run(REPORT::"G/L Book - Print");  // Opens handler - ReprintGLBookPrintRequestPageHandler.

        // Verify: Verify Error Code. Actual error message: Validation error for Field:Validation error for Field:EndingDate,  Message = 'Ending Date must not be greater than
        // Last Gen. Jour. Printing Date of G/L Setup.' or Validation error for Field:ReportType,  Message = 'There is nothing to reprint'.
        Assert.ExpectedErrorCode(TestValidationErr);
    end;

    [Test]
    [HandlerFunctions('ReprintGLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportEntryNumberGLBookPrintError()
    var
        GLBookEntry: Record "GL Book Entry";
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] Validate OnPreReport Trigger of Report - 12121 G/L Book - Print with blank Source Number

        // [GIVEN] Update Company Information - Register Company Number, G/L Setup - Last General Journal Printing Date. Create G/L Book Entry and G/ L Entry.
        Initialize();
        UpdateCompanyInfoRegisterCompanyNumber(LibraryUTUtility.GetNewCode());
        UpdateGLSetupLastGenJourPrintingDate(WorkDate());
        CreateGLBookEntry(
          GLBookEntry, GLBookEntry."Source Type", '',
          CalcDate('<' + Format(-LibraryRandom.RandIntInRange(2, 10)) + 'D>', WorkDate()), 0, '');  // Blank Source Number, Official Date less than WorkDate(), Progressive Number - 0.
        CreateGLEntry(GLEntry, GLBookEntry);
        LibraryVariableStorage.Enqueue(WorkDate()); // Enqueue values for handler - ReprintGLBookPrintRequestPageHandler.

        // [WHEN] Run report "G/L Book - Print"
        asserterror REPORT.Run(REPORT::"G/L Book - Print");  // Opens handler - ReprintGLBookPrintRequestPageHandler.

        // [THEN] Verify Error Code. Actual error message: Entry Number of the previous period has not been printed.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('ReprintGLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GLBookEntryOnPreDataItemGLBookPrint()
    var
        CompanyInformation: Record "Company Information";
        GLBookEntry: Record "GL Book Entry";
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] Validate GL Book Entry - OnPreDataItem Trigger of Report - 12121 G/L Book - Print.

        // [GIVEN] Update Company Information - Register Company Number, G/L Setup - Last General Journal Printing Date. Create G/L Book Entry.
        Initialize();
        UpdateCompanyInfoRegisterCompanyNumber(LibraryUTUtility.GetNewCode());
        UpdateGLSetupLastGenJourPrintingDate(WorkDate());
        CreateGLBookEntry(
          GLBookEntry, GLBookEntry."Source Type", '', CalcDate('<' + Format(-LibraryRandom.RandIntInRange(2, 10)) + 'D>', WorkDate()),
          LibraryRandom.RandInt(10), '');  // Blank Source Number, Official Date less than WorkDate(), and Random value for Progressive Number.
        CreateGLEntry(GLEntry, GLBookEntry);
        CreateReprintInfoFiscalReports();
        LibraryVariableStorage.Enqueue(WorkDate()); // Enqueue values for handler - ReprintGLBookPrintRequestPageHandler.

        // [WHEN] Run report "G/L Book - Print"
        REPORT.Run(REPORT::"G/L Book - Print");  // Opens handler - ReprintGLBookPrintRequestPageHandler.

        // [THEN] Verify Register Company Number and Fiscal Code Caption on XML of Report -  G/L Book - Print.
        CompanyInformation.Get();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CompanyInfoRegisterNumberCap, CompanyInformation."Register Company No.");
        LibraryReportDataset.AssertElementWithValueExists(CompanyInfoFiscalCodeCap, CompanyInformation.FieldCaption("Fiscal Code"));
    end;

    [Test]
    [HandlerFunctions('ReprintGLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GLBookEntryOnAfterGetRecordCustGLBookPrint()
    var
        GLBookEntry: Record "GL Book Entry";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Validate GL Book Entry - OnAfterGetRecord of Report - 12121 G/L Book - Print. for Customer
        CustomerNo := CreateCustomer();
        GLBookEntryOnAfterGetRecordSourceTypeGLBookPrint(
          GLBookEntry."Source Type"::Customer, CustomerNo, CreateSalesInvHeader(CustomerNo));
    end;

    [Test]
    [HandlerFunctions('ReprintGLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GLBookEntryOnAfterGetRecordVendGLBookPrint()
    var
        GLBookEntry: Record "GL Book Entry";
        VendorNo: Code[20];
    begin
        // [SCENARIO] Validate GL Book Entry - OnAfterGetRecord of Report - 12121 G/L Book - Print. for Vendor
        VendorNo := CreateVendor();
        GLBookEntryOnAfterGetRecordSourceTypeGLBookPrint(GLBookEntry."Source Type"::Vendor, VendorNo, CreatePurchInvHeader(VendorNo));
    end;

    [Test]
    [HandlerFunctions('ReprintGLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GLBookEntryOnAfterGetRecordBankAccountGLBookPrint()
    var
        GLBookEntry: Record "GL Book Entry";
    begin
        // [SCENARIO] Validate GL Book Entry - OnAfterGetRecord of Report - 12121 G/L Book - Print for Bank
        GLBookEntryOnAfterGetRecordSourceTypeGLBookPrint(GLBookEntry."Source Type"::"Bank Account", CreateBankAccont(), '');
    end;

    [Test]
    [HandlerFunctions('ReprintGLBookPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GLBookEntryOnAfterGetRecordFixedAssetGLBookPrint()
    var
        GLBookEntry: Record "GL Book Entry";
    begin
        // [SCENARIO] Validate GL Book Entry - OnAfterGetRecord of Report - 12121 G/L Book - Print. for Fixed Asset
        GLBookEntryOnAfterGetRecordSourceTypeGLBookPrint(GLBookEntry."Source Type"::"Fixed Asset", CreateFixedAsset(), '');
    end;

    local procedure GLBookEntryOnAfterGetRecordSourceTypeGLBookPrint(SourceType: Enum "Gen. Journal Source Type"; SourceNo: Code[20]; DocumentNo: Code[20])
    var
        GLBookEntry: Record "GL Book Entry";
        GLEntry: Record "G/L Entry";
        ReprintInfoFiscalReports: Record "Reprint Info Fiscal Reports";
    begin
        // Setup: Update Company Information - Register Company Number, G/L Setup - Last General Journal Printing Date. Create G/L Book Entry, G/L Entry.
        Initialize();
        UpdateCompanyInfoRegisterCompanyNumber(LibraryUTUtility.GetNewCode());
        UpdateGLSetupLastGenJourPrintingDate(WorkDate());
        CreateGLBookEntry(GLBookEntry, SourceType, SourceNo, WorkDate(), LibraryRandom.RandInt(10), DocumentNo);  // Random value for Progressive Number.
        CreateGLEntry(GLEntry, GLBookEntry);
        CreateReprintInfoFiscalReports();
        LibraryVariableStorage.Enqueue(WorkDate()); // Enqueue values for handler - ReprintGLBookPrintRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"G/L Book - Print");  // Opens handler - ReprintGLBookPrintRequestPageHandler.

        // Verify: Verify Page No, Last Printed Page No,Source Number, G/L Entry - G/L Account Number and Debit Amount on XML of Report - G/L Book - Print.
        ReprintInfoFiscalReports.Get(ReprintInfoFiscalReports.Report::"G/L Book - Print", WorkDate(), WorkDate(), '');  // Using blank VAT Register Code.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(DescriptionCap, SourceNo);
        LibraryReportDataset.AssertElementWithValueExists(GLBookEntryGLAccountNumberCap, GLEntry."G/L Account No.");
        LibraryReportDataset.AssertElementWithValueExists(GLBookEntryDebitAmountCap, GLEntry."Debit Amount");
        LibraryReportDataset.AssertElementWithValueExists(PageNoPrefixCap, PageCap + Format(Date2DMY(WorkDate(), 3)));
        LibraryReportDataset.AssertElementWithValueExists(LastPrintedPageNoCap, ReprintInfoFiscalReports."First Page Number" - 2);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportCodeVATRegisterPrintError()
    begin
        // [SCENARIO] Validate OnPreReport Trigger of Report - 12120 VAT Register - Print. with blank VAT Register Code
        Initialize();
        LibraryVariableStorage.Enqueue('');  // Enqueue blank value VAT Register Code for handler - VATRegisterPrintRequestPageHandler.

        // [WHEN] Run report "VAT Register - Print"
        asserterror REPORT.Run(REPORT::"VAT Register - Print");  // Opens handler - VATRegisterPrintRequestPageHandler.

        // [THEN] Verify Error Code. Actual error message: Please select a Code.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintCompanyInfoOnPreDataItemVATRegisterPrintError()
    begin
        // [SCENARIO] Validate Print Company Information - OnPreDataItem Trigger of Report - 12120 VAT Register - Print.
        Initialize();
        UpdateCompanyInfoRegisterCompanyNumber('');  // Blank Register Company Number.
        LibraryVariableStorage.Enqueue(CreateVATRegister());  // Enqueue value for handler - VATRegisterPrintRequestPageHandler.

        // [WHEN] Run report "VAT Register - Print"
        asserterror REPORT.Run(REPORT::"VAT Register - Print");  // Opens handler - VATRegisterPrintRequestPageHandler.

        // [THEN] Verify Error Code. Actual error message: All Company Information related fields should be filled in on the request form.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATBookEntryOnAfterGetRecordPurchaseFalseVATRegisterPrint()
    var
        VATBookEntry: Record "VAT Book Entry";
    begin
        // [SCENARIO] Validate VAT Book Entry - OnAfterGetRecord Trigger of Report - 12120 VAT Register - Print. with Purchase Reverse VAT Entry
        VATBookEntryTypeReverseVATEntryVATRegisterPrint(VATBookEntry.Type::Purchase, false);  // Reverse VAT Entry - False.
    end;

    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATBookEntryOnAfterGetRecordSaleTrueVATRegisterPrint()
    var
        VATBookEntry: Record "VAT Book Entry";
    begin
        // [SCENARIO] Validate VAT Book Entry - OnAfterGetRecord Trigger of Report - 12120 VAT Register - Print. with Sales Reverse VAT Entry
        VATBookEntryTypeReverseVATEntryVATRegisterPrint(VATBookEntry.Type::Sale, true);  // Reverse VAT Entry - True.
    end;

    local procedure VATBookEntryTypeReverseVATEntryVATRegisterPrint(Type: Enum "General Posting Type"; ReverseVATEntry: Boolean)
    var
        CompanyInformation: Record "Company Information";
        NoSeries: Record "No. Series";
        VATBookEntry: Record "VAT Book Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        ExpectedAmount: Decimal;
    begin
        // Setup: Update Company Information - Register Company Number, Create VAT Book Entries, Create Vendor entries.
        Initialize();
        UpdateCompanyInfoRegisterCompanyNumber(LibraryUTUtility.GetNewCode());
        CreateNumberSeries(NoSeries);
        CreateVATBookEntry(VATBookEntry, Type, NoSeries.Code, ReverseVATEntry, CreateVendor());
        CreateVATEntry(VATBookEntry);
        CreateVendorEntries(
          DetailedVendorLedgEntry, VATBookEntry."Sell-to/Buy-from No.", DetailedVendorLedgEntry."Entry Type"::"Initial Entry",
          VATBookEntry."Document No.");
        LibraryVariableStorage.Enqueue(NoSeries."VAT Register");  // Enqueue value for handler - VATRegisterPrintRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"VAT Register - Print");  // Opens handler - VATRegisterPrintRequestPageHandler.

        // Verify: Verify VAT Book Entry - Sell-to/Buy-from Number, Entry Number and Amount on XML of Report - VAT Register - Print.
        CompanyInformation.Get();
        ExpectedAmount := DetailedVendorLedgEntry.Amount;
        if ReverseVATEntry then
            ExpectedAmount := -ExpectedAmount;
        VerifyEntryNumberAndAmountOnReport(
          VATBookEntrySellToBuyFromNumberCap, VATBookEntryNumberCap, LedgerAmountCap, VATBookEntry."Sell-to/Buy-from No.",
          VATBookEntry."Entry No.", ExpectedAmount);
        LibraryReportDataset.AssertElementWithValueExists(CompanyInfoNameCap, CompanyInformation.Name);
        LibraryReportDataset.AssertElementWithValueExists(CompanyInfoAddressCap, CompanyInformation.Address);
        LibraryReportDataset.AssertElementWithValueExists(PageNoPrefixCap, StrSubstNo(PageNoCap, Date2DMY(WorkDate(), 3)));
    end;

    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATBookEntryOnAfterGetRecordSaleFalseVATRegisterPrint()
    var
        NoSeries: Record "No. Series";
        VATBookEntry: Record "VAT Book Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [SCENARIO] Validate VAT Book Entry - OnAfterGetRecord Trigger of Report - 12120 VAT Register - Print. without Sales Reverse VAT Entry
        Initialize();
        UpdateCompanyInfoRegisterCompanyNumber(LibraryUTUtility.GetNewCode());
        CreateNumberSeries(NoSeries);
        CreateVATBookEntry(VATBookEntry, VATBookEntry.Type::Sale, NoSeries.Code, false, CreateCustomer());  // Reverse VAT Entry - False.
        CreateVATEntry(VATBookEntry);
        CreateCustomerEntries(
          DetailedCustLedgEntry, VATBookEntry."Sell-to/Buy-from No.", VATBookEntry."Document No.",
          DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        LibraryVariableStorage.Enqueue(NoSeries."VAT Register");  // Enqueue value for handler - VATRegisterPrintRequestPageHandler.

        // [WHEN] Run report "VAT Register - Print"
        REPORT.Run(REPORT::"VAT Register - Print");  // Opens handler - VATRegisterPrintRequestPageHandler.

        // [THEN] Verify VAT Book Entry - Sell-to/Buy-from Number, Entry Number and Amount on XML of Report - VAT Register - Print.
        VerifyEntryNumberAndAmountOnReport(
          VATBookEntrySellToBuyFromNumberCap, VATBookEntryNumberCap, LedgerAmountCap, VATBookEntry."Sell-to/Buy-from No.",
          VATBookEntry."Entry No.", DetailedCustLedgEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('BankSheetPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BankAccountSheetPrintStartingBalance()
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        BankAccount: Record "Bank Account";
    begin
        // [FEATURE] [Bank Sheet - Print]
        // [SCENARIO] Report "Bank Sheet - Print" should print starting and ending balance when net change is zero

        Initialize();

        // [GIVEN] Bank Account "A" with net change on WorkDate() - 1
        BankAccLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(BankAccLedgEntry, BankAccLedgEntry.FieldNo("Entry No."));
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccLedgEntry."Bank Account No." := BankAccount."No.";
        BankAccLedgEntry."Posting Date" := CalcDate('<-1D>', WorkDate());
        BankAccLedgEntry.Amount := LibraryRandom.RandDec(1000, 2);
        BankAccLedgEntry.Insert();

        LibraryVariableStorage.Enqueue(BankAccLedgEntry."Bank Account No.");

        // [WHEN] Print report "Bank Sheet - Print" for bank account "A" on WORKDATE
        REPORT.Run(REPORT::"Bank Sheet - Print");

        // [THEN] Start balance is exported in the report
        VerifyReportElement('No_BankAccount', BankAccLedgEntry."Bank Account No.", 'StartOnHand', BankAccLedgEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('AccountBookSheetPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccountBookSheetPrintForMultipleEntries()
    var
        GLBookEntry: array[3] of Record "GL Book Entry";
        GLEntry: Record "G/L Entry";
        AccNo: Code[20];
    begin
        // [SCENARIO 317680] Debit and Credit Amount of one line doesn't leak to other lines in report "Account Book Sheet - Print".
        Initialize();

        // [GIVEN] Three G/L Book entries (GLE) and associated G/L entries:
        // [GIVEN] GLE1 with Debit Amount "D1", Credit Amount 0;
        // [GIVEN] GLE2 with Debit Amount 0, Credit Amount "C1";
        // [GIVEN] GLE3 with Debit Amount "D2", Credit Amount 0.
        AccNo := CreateGLAccount();
        CreateGLBookEntryWithAccNo(GLBookEntry[1], AccNo, LibraryRandom.RandDec(10, 2));
        CreateGLEntry(GLEntry, GLBookEntry[1]);

        CreateGLBookEntryWithAccNo(GLBookEntry[2], AccNo, -LibraryRandom.RandDec(10, 2));
        CreateGLEntry(GLEntry, GLBookEntry[2]);

        CreateGLBookEntryWithAccNo(GLBookEntry[3], AccNo, LibraryRandom.RandDec(10, 2));
        CreateGLEntry(GLEntry, GLBookEntry[3]);

        // [WHEN] Report "Account Book Sheet - Print" is run.
        LibraryVariableStorage.Enqueue(AccNo);
        Commit();
        REPORT.Run(REPORT::"Account Book Sheet - Print");

        // [THEN] Sum of IcreasesAmnt tag equal to "D1" + "D2", Sum of DecreasesAmnt equal to "C1".
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(GLBookEntry[1]."Debit Amount" + GLBookEntry[3]."Debit Amount", LibraryReportDataset.Sum(IcreasesAmntCap), '');
        Assert.AreEqual(GLBookEntry[2]."Credit Amount", LibraryReportDataset.Sum(DecreasesAmntCap), '');
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintDateValidateRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATFiscalRegisterPrintValidatesPeriodEndingDate()
    var
        GLSetup: Record "General Ledger Setup";
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
        VatEntry: Record "VAT Entry";
    begin
        // [FEATURE] [VAT Report] [Date]
        // [SCENARIO 322953] VAT Fiscal Register - Print report's request page validates proper Quarter PeriodEndingDate
        Initialize();

        // [GIVEN] Set "VAT Settlement Period"::Quarter in General Ledger Setup
        VatEntry.DeleteAll();
        PeriodicSettlementVATEntry.DeleteAll();
        GLSetup.Get();
        GLSetup.Validate("VAT Settlement Period", GLSetup."VAT Settlement Period"::Quarter);
        GLSetup.Modify(true);

        // [WHEN] Run report "VAT Register - Print" and set PeriodStartingDate = '01-01-2021' in RPH
        LibraryVariableStorage.Enqueue(CreateVATRegister());
        REPORT.Run(REPORT::"VAT Register - Print");

        // [THEN] PeriodEndingDate equals '3/31/2021'
        Assert.AreEqual('3/31/2021', LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintQuarterDateRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATFiscalRegisterPrintExqcutesForQuarterPeriod()
    var
        GLSetup: Record "General Ledger Setup";
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
        VatEntry: Record "VAT Entry";
    begin
        // [FEATURE] [VAT Report] [Date]
        // [SCENARIO 322953] VAT Fiscal Register - Print report runs with proper PeriodStartingDate and PeriodEndingDate for Quarter period
        Initialize();

        // [GIVEN] Set "VAT Settlement Period"::Quarter in General Ledger Setup
        VatEntry.DeleteAll();
        PeriodicSettlementVATEntry.DeleteAll();
        GLSetup.Get();
        GLSetup.Validate("VAT Settlement Period", GLSetup."VAT Settlement Period"::Quarter);
        GLSetup.Modify(true);

        // [WHEN] Run report "VAT Register - Print" with proper PeriodStartingDate and PeriodEndingDate for Quarter period (set in RPH)
        // [THEN] Verify Error Code. Actual error message: There are unposted purchase documents with a reserved Posting No. Please post these before continuing.
        LibraryVariableStorage.Enqueue(CreateVATRegister());
        REPORT.Run(REPORT::"VAT Register - Print");
    end;

    [Test]
    [HandlerFunctions('VendorSheetPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorSheetPrintForMultipleEntries()
    var
        DtldVendorLedgEntry: array[3] of Record "Detailed Vendor Ledg. Entry";
        PurchaseHeaderNo: Code[20];
    begin
        // [FEATURE] [Vendor Sheet - Print]
        // [SCENARIO 328287] Debit and Credit Amount of one line doesn't leak to other lines in report "Vendor Sheet - Print".
        Initialize();

        // [GIVEN] Three Detailed Vendor Ledger entries (DVLE):
        // [GIVEN] DVLE1 with Amount (LCY) "D1" > 0;
        // [GIVEN] DVLE2 with Amount (LCY) "D2" > 0;
        // [GIVEN] DVLE3 with Amount (LCY) "D3" < 0.
        PurchaseHeaderNo := CreatePurchaseHeader('');
        CreateVendorEntries(
          DtldVendorLedgEntry[1], PurchaseHeaderNo, DtldVendorLedgEntry[1]."Entry Type"::"Initial Entry", LibraryUTUtility.GetNewCode10());
        CreateVendorEntries(
          DtldVendorLedgEntry[2], PurchaseHeaderNo, DtldVendorLedgEntry[2]."Entry Type"::"Initial Entry", LibraryUTUtility.GetNewCode10());
        DtldVendorLedgEntry[2]."Amount (LCY)" := -LibraryRandom.RandDec(10, 2);
        DtldVendorLedgEntry[2].Modify();
        CreateVendorEntries(
          DtldVendorLedgEntry[3], PurchaseHeaderNo, DtldVendorLedgEntry[3]."Entry Type"::"Initial Entry", LibraryUTUtility.GetNewCode10());

        // [WHEN] Report "Vendor Sheet - Print" is run.
        LibraryVariableStorage.Enqueue(DtldVendorLedgEntry[1]."Vendor No.");
        Commit();
        REPORT.Run(REPORT::"Vendor Sheet - Print");

        // [THEN] TotalIcreasesAmntForRTC equal to "D1" + "D2", TotalDecreasesAmntForRTC equal to "D3".
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'TotalIcreasesAmntForRTC', DtldVendorLedgEntry[1]."Amount (LCY)" + DtldVendorLedgEntry[3]."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('TotalDecreasesAmntForRTC', Abs(DtldVendorLedgEntry[2]."Amount (LCY)"));
    end;

    [Test]
    [HandlerFunctions('BankSheetPrintRPH')]
    [Scope('OnPrem')]
    procedure SingleBankAccountSheetPrintForMultipleEntries()
    var
        BankAccLedgEntry: array[3] of Record "Bank Account Ledger Entry";
        BankAccount: Record "Bank Account";
    begin
        // [FEATURE] [Bank Sheet - Print]
        // [SCENARIO 328287] Debit and Credit Amount of one line doesn't leak to other lines in report "Vendor Sheet - Print".
        Initialize();

        // [GIVEN] Created Bank Account and three Bank Account Ledger entries:
        // [GIVEN] first and third with positive amounts, second one with negative
        LibraryERM.CreateBankAccount(BankAccount);
        CreateBankEntry(BankAccLedgEntry[1], BankAccount."No.", WorkDate(), LibraryRandom.RandDec(1000, 2));
        CreateBankEntry(BankAccLedgEntry[2], BankAccount."No.", WorkDate(), -LibraryRandom.RandDec(1000, 2));
        CreateBankEntry(BankAccLedgEntry[3], BankAccount."No.", WorkDate(), LibraryRandom.RandDec(1000, 2));

        // [WHEN] Run report "Bank Sheet - Print" for Bank Account
        Commit();
        BankAccount.SetFilter("No.", BankAccount."No.");
        BankAccount.SetFilter("Date Filter", Format(WorkDate()));
        REPORT.Run(REPORT::"Bank Sheet - Print", true, false, BankAccount);

        // [THEN] 'IncreasesAmt' and 'DecreasesAmt' are not transferred from previous entries
        // [THEN] Total 'Amt' is calculated correctly
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportCreditDebitAmounts(
          BankAccount."No.", BankAccLedgEntry[1].Amount, BankAccLedgEntry[2].Amount, BankAccLedgEntry[3].Amount);
    end;

    [Test]
    [HandlerFunctions('BankSheetPrintRPH')]
    [Scope('OnPrem')]
    procedure MultipleBankAccountsSheetPrintForMultipleEntries()
    var
        BankAccLedgEntry: array[6] of Record "Bank Account Ledger Entry";
        BankAccount: array[3] of Record "Bank Account";
    begin
        // [FEATURE] [Bank Sheet - Print]
        // [SCENARIO 328287] Debit and Credit Amount of one line doesn't leak to other lines in report "Vendor Sheet - Print" when run for multiple Bank Accounts
        Initialize();

        // [GIVEN] Created Bank Account 1 and three Bank Account Ledger entries:
        // [GIVEN] first and third with positive amounts, second one with negative
        LibraryERM.CreateBankAccount(BankAccount[1]);
        CreateBankEntry(BankAccLedgEntry[1], BankAccount[1]."No.", WorkDate(), LibraryRandom.RandDec(1000, 2));
        CreateBankEntry(BankAccLedgEntry[2], BankAccount[1]."No.", WorkDate(), -LibraryRandom.RandDec(1000, 2));
        CreateBankEntry(BankAccLedgEntry[3], BankAccount[1]."No.", WorkDate(), LibraryRandom.RandDec(1000, 2));

        // [GIVEN] Created Bank Account 2 and three Bank Account Ledger entries:
        // [GIVEN] first and third with positive amounts, second one with negative
        LibraryERM.CreateBankAccount(BankAccount[2]);
        CreateBankEntry(BankAccLedgEntry[4], BankAccount[2]."No.", WorkDate(), LibraryRandom.RandDec(1000, 2));
        CreateBankEntry(BankAccLedgEntry[5], BankAccount[2]."No.", WorkDate(), -LibraryRandom.RandDec(1000, 2));
        CreateBankEntry(BankAccLedgEntry[6], BankAccount[2]."No.", WorkDate(), LibraryRandom.RandDec(1000, 2));

        // [WHEN] Run report "Bank Sheet - Print" for both Bank Accounts
        Commit();
        BankAccount[3].SetFilter("No.", StrSubstNo('%1..%2', BankAccount[1]."No.", BankAccount[2]."No."));
        BankAccount[3].SetFilter("Date Filter", Format(WorkDate()));
        REPORT.Run(REPORT::"Bank Sheet - Print", true, false, BankAccount[3]);

        // [THEN] 'IncreasesAmt' and 'DecreasesAmt' are not transferred from previous entries
        // [THEN] Total 'Amt' is calculated correctly
        // [THEN] Each Bank Account is calculated separrately and correctly
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportCreditDebitAmounts(
          BankAccount[1]."No.", BankAccLedgEntry[1].Amount, BankAccLedgEntry[2].Amount, BankAccLedgEntry[3].Amount);

        LibraryReportDataset.Reset();
        VerifyReportCreditDebitAmounts(
          BankAccount[2]."No.", BankAccLedgEntry[4].Amount, BankAccLedgEntry[5].Amount, BankAccLedgEntry[6].Amount);
    end;

    [Test]
    [HandlerFunctions('AccountBookSheetPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AccountBookPrintOnAnyAvilableData()
    var
        GLEntry: Record "G/L Entry";
        GLBookEntry: Record "GL Book Entry";
    begin
        // [SCENARIO 536209] Report "Account Book Sheet - Print" should print report if data exists.
        Initialize();

        // [GIVEN] Insert GL Entry with G/L Account on WorkDate() - 1
        CreateGLBookEntry(
          GLBookEntry, GLBookEntry."Source Type", LibraryUTUtility.GetNewCode(),
          CalcDate('<' + Format(-LibraryRandom.RandIntInRange(2, 10)) + 'D>', WorkDate()), LibraryRandom.RandInt(10), '');  // Source Number, Official Date less than WORKDATE and Progressive Number.
        CreateGLEntry(GLEntry, GLBookEntry);

        // [GIVEN] Store GL Account No in a Variable.
        LibraryVariableStorage.Enqueue(GLEntry."G/L Account No.");

        // [WHEN] RUN report Account Book Sheet - Print.
        REPORT.Run(REPORT::"Account Book Sheet - Print");

        // [THEN] GL Account No. must have value in report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('G_L_Account_No_', GLEntry."G/L Account No.");
    end;

    [Test]
    [HandlerFunctions('VendorSheetPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VendorSheetPrintOnAnyAvilableData()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // [SCENARIO 536209] Report "Vendor Sheet - Print" should print when data is avilable.
        Initialize();

        // [GIVEN] Insert Detalied Vendor Ledger Entry on WorkDate() - 1
        CreateVendorEntries(
            DetailedVendorLedgEntry,
            CreatePurchaseHeader(''),
            DetailedVendorLedgEntry."Entry Type"::"Correction of Remaining Amount",
            LibraryUTUtility.GetNewCode10());

        // [GIVEN] Enqueue value for handler - VendorSheetPrintRequestPageHandler.
        LibraryVariableStorage.Enqueue(DetailedVendorLedgEntry."Vendor No.");

        // [WHEN] Run report "Vendor Sheet - Print"
        REPORT.Run(REPORT::"Vendor Sheet - Print");

        // [THEN] Vendor No. must have value in report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_Vendor', DetailedVendorLedgEntry."Vendor No.");
    end;

    [Test]
    [HandlerFunctions('CustomerSheetPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerSheetPrintOnAnyAvilableData()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [SCENARIO 536209] Report "Customer Sheet - Print" should print when data is there.
        Initialize();

        // [GIVEN] Insert Detailed Customer Ledger Entry on WorkDate() - 1.
        CreateCustomerEntries(
            DetailedCustLedgEntry,
            CreateSalesHeader(''),
            LibraryUTUtility.GetNewCode(),
            DetailedCustLedgEntry."Entry Type"::"Correction of Remaining Amount");

        // [GIVEN] Enqueue Customer No.
        LibraryVariableStorage.Enqueue(DetailedCustLedgEntry."Customer No.");

        // [WHEN] Run report "Customer Sheet - Print"
        REPORT.Run(REPORT::"Customer Sheet - Print");

        // [THEN] Amount must have value in report if data is within filter. 
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(StartOnHandAmountLCYCap, DetailedCustLedgEntry."Amount (LCY)");
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;

        isInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
    end;

    local procedure CreateBankAccont(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount.Name := BankAccount."No.";
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateBankEntry(var BankAccLedgEntry: Record "Bank Account Ledger Entry"; BankAccountNo: Code[20]; Date: Date; Amount: Decimal)
    begin
        BankAccLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(BankAccLedgEntry, BankAccLedgEntry.FieldNo("Entry No."));
        BankAccLedgEntry."Bank Account No." := BankAccountNo;
        BankAccLedgEntry."Posting Date" := Date;
        BankAccLedgEntry.Amount := Amount;
        BankAccLedgEntry.Insert();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Name := Customer."No.";
        Customer."Date Filter" := WorkDate();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateCustomerEntries(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustomerNo: Code[20]; DocumentNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        CustLedgerEntry2.FindLast();
        CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Document No." := DocumentNo;
        CustLedgerEntry."Currency Code" := LibraryUTUtility.GetNewCode10();
        CustLedgerEntry.Amount := LibraryRandom.RandDec(10, 2);
        CustLedgerEntry."Amount (LCY)" := CustLedgerEntry.Amount + LibraryRandom.RandDec(10, 2);
        CustLedgerEntry.Insert();

        DetailedCustLedgEntry2.FindLast();
        DetailedCustLedgEntry."Entry No." := DetailedCustLedgEntry2."Entry No." + 1;
        DetailedCustLedgEntry."Customer No." := CustLedgerEntry."Customer No.";
        DetailedCustLedgEntry."Document No." := CustLedgerEntry."Document No.";
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Entry Type" := EntryType;
        DetailedCustLedgEntry.Amount := LibraryRandom.RandDec(10, 2);
        DetailedCustLedgEntry."Amount (LCY)" := DetailedCustLedgEntry.Amount;
        DetailedCustLedgEntry."Credit Amount" := DetailedCustLedgEntry.Amount;
        DetailedCustLedgEntry."Credit Amount (LCY)" := DetailedCustLedgEntry.Amount;
        DetailedCustLedgEntry."Posting Date" := CustLedgerEntry."Posting Date";
        DetailedCustLedgEntry.Insert(true);
    end;

    local procedure CreateVendorEntries(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; VendorNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DocumentNo: Code[20])
    var
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry2.FindLast();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Document No." := DocumentNo;
        VendorLedgerEntry."Currency Code" := LibraryUTUtility.GetNewCode10();
        VendorLedgerEntry.Insert();

        DetailedVendorLedgEntry2.FindLast();
        DetailedVendorLedgEntry."Entry No." := DetailedVendorLedgEntry2."Entry No." + 1;
        DetailedVendorLedgEntry."Vendor No." := VendorLedgerEntry."Vendor No.";
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DetailedVendorLedgEntry."Entry Type" := EntryType;
        DetailedVendorLedgEntry."Document No." := VendorLedgerEntry."Document No.";
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDec(10, 2);
        DetailedVendorLedgEntry."Amount (LCY)" := DetailedVendorLedgEntry.Amount;
        DetailedVendorLedgEntry."Debit Amount" := DetailedVendorLedgEntry.Amount;
        DetailedVendorLedgEntry."Debit Amount (LCY)" := DetailedVendorLedgEntry.Amount;
        DetailedVendorLedgEntry."Posting Date" := VendorLedgerEntry."Posting Date";
        DetailedVendorLedgEntry.Insert(true);
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset."No." := LibraryUTUtility.GetNewCode();
        FixedAsset.Description := FixedAsset."No.";
        FixedAsset.Insert();
        exit(FixedAsset."No.");
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount."Date Filter" := WorkDate();
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateGLBookEntry(var GLBookEntry: Record "GL Book Entry"; SourceType: Enum "Gen. Journal Source Type"; SourceNo: Code[20]; OfficialDate: Date; ProgressiveNo: Integer; DocumentNo: Code[20])
    begin
        GLBookEntry.DeleteAll();  // Deleting of G/L Book Entry is required to run Report - G/L Book - Print.
        GLBookEntry."Entry No." := 1;
        GLBookEntry."Document Type" := GLBookEntry."Document Type"::Invoice;
        GLBookEntry."Document No." := DocumentNo;
        GLBookEntry."G/L Account No." := CreateGLAccount();
        GLBookEntry."Posting Date" := WorkDate();
        GLBookEntry."Source Type" := SourceType;
        GLBookEntry."Source No." := SourceNo;
        GLBookEntry.Amount := LibraryRandom.RandDec(10, 2);
        GLBookEntry."Debit Amount" := GLBookEntry.Amount;
        GLBookEntry."Official Date" := OfficialDate;
        GLBookEntry."Progressive No." := ProgressiveNo;
        GLBookEntry."Transaction No." := 1;
        GLBookEntry.Insert();
    end;

    local procedure CreateGLBookEntryWithAccNo(var GLBookEntry: Record "GL Book Entry"; AccNo: Code[20]; EntryAmount: Decimal)
    var
        EntryNo: Integer;
    begin
        GLBookEntry.Reset();
        if GLBookEntry.FindLast() then
            EntryNo := GLBookEntry."Entry No.";
        EntryNo += 1;
        GLBookEntry.Init();
        GLBookEntry."Entry No." := EntryNo;
        GLBookEntry."Document Type" := GLBookEntry."Document Type"::Invoice;
        GLBookEntry."G/L Account No." := AccNo;
        GLBookEntry."Posting Date" := WorkDate();
        GLBookEntry."Source No." := LibraryUTUtility.GetNewCode();
        GLBookEntry.Amount := EntryAmount;
        if EntryAmount > 0 then
            GLBookEntry."Debit Amount" := EntryAmount
        else
            GLBookEntry."Credit Amount" := Abs(EntryAmount);
        GLBookEntry."Official Date" := WorkDate();
        GLBookEntry."Progressive No." := 1;
        GLBookEntry."Transaction No." := 1;
        GLBookEntry.Insert();
    end;

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry"; GLBookEntry: Record "GL Book Entry")
    var
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."Document Type" := GLBookEntry."Document Type"::Invoice;
        GLEntry."Document No." := GLBookEntry."Document No.";
        GLEntry."Posting Date" := WorkDate();
        GLEntry."G/L Account No." := GLBookEntry."G/L Account No.";
        GLEntry.Amount := GLBookEntry.Amount;
        if GLEntry.Amount > 0 then
            GLEntry."Debit Amount" := GLEntry.Amount
        else
            GLEntry."Credit Amount" := Abs(GLEntry.Amount);
        GLEntry."Source Type" := GLBookEntry."Source Type";
        GLEntry."Source No." := GLBookEntry."Source No.";
        GLEntry."Transaction No." := 1;
        GLEntry.Insert();
    end;

    local procedure CreateNumberSeries(var NoSeries: Record "No. Series")
    begin
        NoSeries.Code := LibraryUTUtility.GetNewCode10();
        NoSeries."VAT Register" := CreateVATRegister();
        NoSeries.Insert();
    end;

    local procedure CreatePurchaseHeader(PostingNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Buy-from Vendor No." := CreateVendor();
        PurchaseHeader."Posting No." := PostingNo;
        PurchaseHeader.Insert();
        exit(PurchaseHeader."Buy-from Vendor No.");
    end;

    local procedure CreatePurchaseHeaderWithNo(var PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Buy-from Vendor No." := CreateVendor();
        PurchaseHeader."Posting No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader.Insert();
        exit(PurchaseHeader."Buy-from Vendor No.");
    end;

    local procedure CreatePurchInvHeader(BuyFromVendorNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader."No." := LibraryUTUtility.GetNewCode();
        PurchInvHeader."Pay-to Name" := BuyFromVendorNo;
        PurchInvHeader.Insert();
        exit(PurchInvHeader."No.");
    end;

    local procedure CreateReprintInfoFiscalReports()
    var
        ReprintInfoFiscalReports: Record "Reprint Info Fiscal Reports";
    begin
        ReprintInfoFiscalReports.Report := ReprintInfoFiscalReports.Report::"G/L Book - Print";
        ReprintInfoFiscalReports."Start Date" := WorkDate();
        ReprintInfoFiscalReports."End Date" := WorkDate();
        ReprintInfoFiscalReports.Insert();
    end;

    local procedure CreateSalesHeader(PostingNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Sell-to Customer No." := CreateCustomer();
        SalesHeader."Posting No." := PostingNo;
        SalesHeader.Insert();
        exit(SalesHeader."Sell-to Customer No.");
    end;

    local procedure CreateSalesHeaderWithNo(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Sell-to Customer No." := CreateCustomer();
        SalesHeader."Posting No." := LibraryUTUtility.GetNewCode();
        SalesHeader.Insert();
        exit(SalesHeader."Sell-to Customer No.");
    end;

    local procedure CreateSalesInvHeader(SellToCustomerNo: Code[20]): Code[20]
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        SalesInvHeader."No." := LibraryUTUtility.GetNewCode();
        SalesInvHeader."Bill-to Name" := SellToCustomerNo;
        SalesInvHeader.Insert();
        exit(SalesInvHeader."No.");
    end;

    local procedure CreateVATBookEntry(var VATBookEntry: Record "VAT Book Entry"; Type: Enum "General Posting Type"; NoSeries: Code[20]; ReverseVATEntry: Boolean; SellToBuyFromNo: Code[20])
    var
        VATBookEntry2: Record "VAT Book Entry";
    begin
        VATBookEntry2.FindLast();
        VATBookEntry."Entry No." := VATBookEntry2."Entry No." + 1;
        VATBookEntry.Type := Type;
        VATBookEntry."No. Series" := NoSeries;
        VATBookEntry."Posting Date" := WorkDate();
        VATBookEntry."Sell-to/Buy-from No." := SellToBuyFromNo;
        VATBookEntry."Printing Date" := 0D;
        VATBookEntry."Document No." := LibraryUTUtility.GetNewCode();
        VATBookEntry."VAT Identifier" := CreateVATIdentifier();
        VATBookEntry."Reverse VAT Entry" := ReverseVATEntry;
        VATBookEntry."Unrealized VAT" := false;
        VATBookEntry.Insert();
    end;

    local procedure CreateVATEntry(VATBookEntry: Record "VAT Book Entry")
    var
        VATEntry: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
    begin
        VATEntry2.FindLast();
        VATEntry."Entry No." := VATEntry2."Entry No." + 1;
        VATEntry.Type := VATBookEntry.Type;
        VATEntry."No. Series" := VATBookEntry."No. Series";
        VATEntry."Posting Date" := WorkDate();
        VATEntry."Document No." := VATBookEntry."Document No.";
        VATEntry."Bill-to/Pay-to No." := VATBookEntry."Sell-to/Buy-from No.";
        VATEntry."VAT Identifier" := VATBookEntry."VAT Identifier";
        VATEntry.Insert();
    end;

    local procedure CreateVATIdentifier(): Code[10]
    var
        VATIdentifier: Record "VAT Identifier";
    begin
        VATIdentifier.Code := LibraryUTUtility.GetNewCode10();
        VATIdentifier.Insert();
        exit(VATIdentifier.Code);
    end;

    local procedure CreateVATRegister(): Code[10]
    var
        VATRegister: Record "VAT Register";
    begin
        VATRegister.Code := LibraryUTUtility.GetNewCode10();
        VATRegister.Insert();
        exit(VATRegister.Code);
    end;

    local procedure CreateVATRegisterBuffer(var VATRegisterBuffer: Record "VAT Register - Buffer"; RegisterType: Option)
    begin
        VATRegisterBuffer."Period End Date" := WorkDate();
        VATRegisterBuffer."VAT Register Code" := CreateVATRegister();
        VATRegisterBuffer."Register Type" := RegisterType;
        VATRegisterBuffer."Period Start Date" := WorkDate();
        VATRegisterBuffer."Period End Date" := WorkDate();
        VATRegisterBuffer.Amount := LibraryRandom.RandDec(10, 2);
        VATRegisterBuffer.Insert();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Name := Vendor."No.";
        Vendor."Date Filter" := WorkDate();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure EnqueueStartingDateAndEndingDate(StartingDate: Date; EndingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
    end;

    local procedure GLBookPrintSAVEASXML(GLBookPrint: TestRequestPage "G/L Book - Print"; ReportType: Option; StartingDate: Variant)
    var
        EndingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(EndingDate);
        GLBookPrint.ReportType.SetValue(ReportType);
        GLBookPrint.StartingDate.SetValue(WorkDate());
        GLBookPrint.StartingDate.SetValue(StartingDate);
        GLBookPrint.EndingDate.SetValue(WorkDate());
        GLBookPrint.EndingDate.SetValue(EndingDate);
        GLBookPrint.FiscalCode.SetValue(LibraryUTUtility.GetNewCode());
        GLBookPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure UpdateCompanyInfoRegisterCompanyNumber(RegisterCompanyNo: Text[50])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Register Company No." := RegisterCompanyNo;
        CompanyInformation.Modify();
    end;

    local procedure UpdateGLSetupLastGenJourPrintingDate(LastGenJourPrintingDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Last Gen. Jour. Printing Date" := LastGenJourPrintingDate;
        GeneralLedgerSetup.Modify();
    end;

    local procedure VerifyEntryNumberAndAmountOnReport(NumberCaption: Text; EntryNumberCaption: Text; AmountCaption: Text; ExpectedNumber: Variant; ExpectedEntryNumber: Variant; ExpectedAmount: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        AssertElementsWithValuesExists(
          NumberCaption, EntryNumberCaption, AmountCaption, ExpectedNumber, ExpectedEntryNumber, ExpectedAmount);
    end;

    local procedure VerifyValuesOnCustSheetPrintReport(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        LibraryReportDataset.AssertElementWithValueExists(PrintedEntriesTotalCap, Format(PrintedEntriesTotalTxt));
        LibraryReportDataset.AssertElementWithValueExists(ProgressiveTotCap, Format(ProgressiveTotalTxt));
        LibraryReportDataset.AssertElementWithValueExists(DtldCustLedgEntryTypeCap, Format(CorrectionAmountTxt));
        LibraryReportDataset.AssertElementWithValueExists(StartOnHandAmountLCYCap, DetailedCustLedgEntry."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(DecreasesAmntCap, DetailedCustLedgEntry."Credit Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(CrAmtLCYCap, DetailedCustLedgEntry."Credit Amount (LCY)");
    end;

    local procedure VerifyValuesOnVendSheetPrintReport(DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
        LibraryReportDataset.AssertElementWithValueExists(PrintedEntriesTotCap, Format(PrintedEntriesTotalTxt));
        LibraryReportDataset.AssertElementWithValueExists(ProgressiveTotCap, Format(ProgressiveTotalTxt));
        LibraryReportDataset.AssertElementWithValueExists(StartOnHandAmtLCYCap, DetailedVendorLedgEntry."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(TotalAmountLCYForRTCCap, DetailedVendorLedgEntry."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(DtldVendLedgEntryTypeCap, Format(CorrectionAmountTxt));
        LibraryReportDataset.AssertElementWithValueExists(IcreasesAmntCap, DetailedVendorLedgEntry."Debit Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists(TotalIcreasesAmntForRTCCap, DetailedVendorLedgEntry."Debit Amount (LCY)");
    end;

    local procedure VerifyReportElement(FilterOnElementName: Text; FilterOnElementValue: Text; AssertElementName: Text; AssertElementValue: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(FilterOnElementName, FilterOnElementValue);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(AssertElementName, AssertElementValue);
    end;

    local procedure VerifyReportCreditDebitAmounts(BankNo: Code[20]; FirstAmount: Decimal; SecondAmount: Decimal; ThirdAmount: Decimal)
    begin
        LibraryReportDataset.SetRange('No_BankAccount', BankNo);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find first Bank Account entry');
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find second Bank Account entries');
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'IncreasesAmt', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'DecreasesAmt', -SecondAmount);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find third Bank Account entry');
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'IncreasesAmt', ThirdAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'DecreasesAmt', 0);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Amt', FirstAmount + SecondAmount + ThirdAmount);
    end;

    local procedure AssertElementsWithValuesExists(NumberCaption: Text; EntryNumberCaption: Text; AmountCaption: Text; ExpectedNumber: Variant; ExpectedEntryNumber: Variant; ExpectedAmount: Variant)
    begin
        LibraryReportDataset.AssertElementWithValueExists(NumberCaption, ExpectedNumber);
        LibraryReportDataset.AssertElementWithValueExists(EntryNumberCaption, ExpectedEntryNumber);
        LibraryReportDataset.AssertElementWithValueExists(AmountCaption, ExpectedAmount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountBookSheetPrintRequestPageHandler(var AccountBookSheetPrint: TestRequestPage "Account Book Sheet - Print")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        AccountBookSheetPrint."G/L Account".SetFilter("No.", No);
        AccountBookSheetPrint."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        AccountBookSheetPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerSheetPrintRequestPageHandler(var CustomerSheetPrint: TestRequestPage "Customer Sheet - Print")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CustomerSheetPrint.Customer.SetFilter("No.", No);
        CustomerSheetPrint.Customer.SetFilter("Date Filter", Format(WorkDate()));
        CustomerSheetPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLBookPrintRequestPageHandler(var GLBookPrint: TestRequestPage "G/L Book - Print")
    var
        StartingDate: Variant;
        ReportType: Option "Test Print","Final Print",Reprint;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        GLBookPrintSAVEASXML(GLBookPrint, ReportType::"Test Print", StartingDate);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReprintGLBookPrintRequestPageHandler(var GLBookPrint: TestRequestPage "G/L Book - Print")
    var
        ReportType: Option "Test Print","Final Print",Reprint;
    begin
        GLBookPrintSAVEASXML(GLBookPrint, ReportType::Reprint, WorkDate());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATRegisterGroupedRequestPageHandler(var VATRegisterGrouped: TestRequestPage "VAT Register Grouped")
    begin
        VATRegisterGrouped.PeriodStartingDate.SetValue(WorkDate());
        VATRegisterGrouped.PeriodEndingDate.SetValue(WorkDate());
        VATRegisterGrouped.FiscalCode.SetValue(LibraryUTUtility.GetNewCode());
        VATRegisterGrouped.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATRegisterPrintRequestPageHandler(var VATRegisterPrint: TestRequestPage "VAT Register - Print")
    var
        VATRegister: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATRegister);
        VATRegisterPrint.VATRegister.SetValue(VATRegister);
        VATRegisterPrint.PeriodStartingDate.SetValue(WorkDate());
        VATRegisterPrint.PeriodEndingDate.SetValue(WorkDate());
        VATRegisterPrint.FiscalCode.SetValue(LibraryUTUtility.GetNewCode());
        VATRegisterPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATRegisterPrintDateValidateRPH(var VATRegisterPrint: TestRequestPage "VAT Register - Print")
    var
        VATRegister: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATRegister);
        VATRegisterPrint.VATRegister.SetValue(VATRegister);
        VATRegisterPrint.PeriodStartingDate.SetValue(DMY2Date(1, 1, 2021));
        LibraryVariableStorage.Enqueue(VATRegisterPrint.PeriodEndingDate.Value);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATRegisterPrintQuarterDateRPH(var VATRegisterPrint: TestRequestPage "VAT Register - Print")
    var
        VATRegister: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATRegister);
        VATRegisterPrint.VATRegister.SetValue(VATRegister);
        VATRegisterPrint.PrintCompanyInformations.SetValue(false);
        VATRegisterPrint.PeriodStartingDate.SetValue(CalcDate('<-CM>', WorkDate()));
        VATRegisterPrint.PeriodEndingDate.SetValue(CalcDate('<+CM+2M>', WorkDate()));
        VATRegisterPrint.FiscalCode.SetValue(LibraryUTUtility.GetNewCode());
        VATRegisterPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorSheetPrintRequestPageHandler(var VendorSheetPrint: TestRequestPage "Vendor Sheet - Print")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        VendorSheetPrint.Vendor.SetFilter("No.", No);
        VendorSheetPrint.Vendor.SetFilter("Date Filter", Format(WorkDate()));
        VendorSheetPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankSheetPrintRequestPageHandler(var BankSheetPrint: TestRequestPage "Bank Sheet - Print")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        BankSheetPrint."Bank Account".SetFilter("No.", No);
        BankSheetPrint."Bank Account".SetFilter("Date Filter", Format(WorkDate()));
        BankSheetPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankSheetPrintRPH(var BankSheetPrint: TestRequestPage "Bank Sheet - Print")
    begin
        BankSheetPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;
}

