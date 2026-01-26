codeunit 144192 "IT - Fiscal Reports"
{
    // // [FEATURE] [Fiscal Reports]
    // 
    // Tests reports:
    // VAT Register - Print 12120
    // G/L Book - Print 12121
    // 
    // Covers Test Cases for WI - 348936
    // ------------------------------------------------------------------
    // Test Function Name                                          TFS ID
    // ------------------------------------------------------------------
    // VATRegisterGroupedWithPrintCompanyInformation               154863

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        IsInitialized: Boolean;
        FinalPrintMessageErr: Label 'Final Print Message expected.';
        ReprintInfoErr: Label 'Correct Reprint Information Fiscal Reports was not created.';
        WrongPeriodErr: Label 'Start Date and End Date do not correspond to begin';
        ReprintInfoDoesNotExistErr: Label 'The Reprint Info Fiscal Reports does not exist.';
        ReprintInfoShouldNotExistErr: Label 'The Reprint Info Fiscal Reports should not exist.';
        PreviousPeriodNotPrintedErr: Label 'There are entries in the previous period that were not printed.';
        ConfirmFinalPrintMsg: Label 'Are you sure you want to print the VAT Register as final version ?';
        ConfirmReprintMsg: Label 'This period has already been printed. Do you want to print it again?';
        SetManuallyMsg: Label 'You must update the %1 field in the %2 window when you have printed the report.', Comment = '.';
        ConfirmCorrectPrintMsg: Label 'Has the report been print out correctly?';
        EntriesHaveBeenMarkedMsg: Label 'The G/L entries printed have been marked.';
        MessageNotFoundErr: Label 'Message not found.';
        StartingDateErr: Label 'Starting Date must be greater';
        PreviousPeriodErr: Label 'previous period has not been printed.';
        XlsxTok: Label '.xlsx';
        PageNumberingLbl: Label 'Page %1/%2', Comment = '.';
        PageNumberLbl: Label 'Page %1', Comment = '.';
        PageNumberingErr: Label 'Page numbers are not correct in the report.';
        NameTok: Label 'Name';
        VATRegTok: Label 'VATReg';
        RowMustExistErr: Label 'Row Must Exist.';

    [Test]
    [Scope('OnPrem')]
    procedure VATRegisterTest()
    var
        VATRegister: Record "VAT Register";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        PrintCompanyInfo: Boolean;
        LastPrintingDate: Date;
    begin
        Initialize();
        // Setup - prepare data
        SelectVATRegister(VATRegister);
        LastPrintingDate := VATRegister."Last Printing Date";

        // Setup - set report parameters values
        StartDate := GetStartDateForVATRegister(VATRegister.Code);
        EndDate := GetEndDate(StartDate);
        ReportType := ReportType::Test;
        PrintCompanyInfo := true;

        // Exercise - run the report
        RunVATRegisterReport(VATRegister, ReportType, StartDate, EndDate, PrintCompanyInfo);

        // Verify
        VATRegister.Get(VATRegister.Code);
        VATRegister.TestField("Last Printing Date", LastPrintingDate);
        VerifyVATBookEntries(StartDate, EndDate, VATRegister.Code, false);
        VerifyReprintInfoVATRegister(StartDate, EndDate, VATRegister.Code, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,FinalPrintMessageHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterFinalConfirm()
    var
        VATRegister: Record "VAT Register";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        PrintCompanyInfo: Boolean;
    begin
        Initialize();
        // Setup - prepare data
        SelectVATRegister(VATRegister);

        // Setup - set report parameters values
        StartDate := GetStartDateForVATRegister(VATRegister.Code);
        EndDate := GetEndDate(StartDate);
        ReportType := ReportType::Final;
        PrintCompanyInfo := true;

        // Exercise - run the report
        RunVATRegisterReport(VATRegister, ReportType, StartDate, EndDate, PrintCompanyInfo); // Confirm final printing

        // Verify
        VATRegister.Get(VATRegister.Code);
        VATRegister.TestField("Last Printing Date", EndDate);
        VerifyVATBookEntries(StartDate, EndDate, VATRegister.Code, true);
        VerifyReprintInfoVATRegister(StartDate, EndDate, VATRegister.Code, true);

        // Tear down - rollback changes
        asserterror Error('');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure VATRegisterFinalNotConfirm()
    var
        VATRegister: Record "VAT Register";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        PrintCompanyInfo: Boolean;
    begin
        Initialize();
        // Setup - prepare data
        SelectVATRegister(VATRegister);

        // Setup - set report parameters values
        StartDate := GetStartDateForVATRegister(VATRegister.Code);
        EndDate := GetEndDate(StartDate);
        ReportType := ReportType::Final;
        PrintCompanyInfo := true;

        // Exercise - run the report
        asserterror RunVATRegisterReport(VATRegister, ReportType, StartDate, EndDate, PrintCompanyInfo); // Don't confirm final printing

        // Verify
        VATRegister.Get(VATRegister.Code);
        VATRegister.TestField("Last Printing Date", 0D);
        VerifyVATBookEntries(StartDate, EndDate, VATRegister.Code, false);
        VerifyReprintInfoVATRegister(StartDate, EndDate, VATRegister.Code, false);

        // Tear down - rollback changes
        asserterror Error('');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrueTwice,FinalPrintMessageHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterFinalTwice()
    var
        VATRegister: Record "VAT Register";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        PrintCompanyInfo: Boolean;
    begin
        Initialize();
        // Setup - prepare data
        SelectVATRegister(VATRegister);

        // Setup - set report parameters values
        StartDate := GetStartDateForVATRegister(VATRegister.Code);
        EndDate := GetEndDate(StartDate);
        ReportType := ReportType::Final;
        PrintCompanyInfo := true;

        // Exercise - run the report twice for the same parameters
        RunVATRegisterReport(VATRegister, ReportType, StartDate, EndDate, PrintCompanyInfo); // Confirm final printing
        RunVATRegisterReport(VATRegister, ReportType, StartDate, EndDate, PrintCompanyInfo); // Verify confirm message about reprinting

        // Verify
        VATRegister.Get(VATRegister.Code);
        VATRegister.TestField("Last Printing Date", EndDate);
        VerifyVATBookEntries(StartDate, EndDate, VATRegister.Code, true);
        VerifyReprintInfoVATRegister(StartDate, EndDate, VATRegister.Code, true);

        // Tear down - rollback changes
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATRegisterFinalWrongPeriod()
    var
        VATRegister: Record "VAT Register";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        PrintCompanyInfo: Boolean;
    begin
        Initialize();
        // Setup - prepare data
        SelectVATRegister(VATRegister);

        // Setup - set report parameters values
        StartDate := GetStartDateForVATRegister(VATRegister.Code);
        EndDate := CalcDate(StrSubstNo('<CM+%1M>', LibraryRandom.RandInt(10)), StartDate);
        ReportType := ReportType::Final;
        PrintCompanyInfo := true;

        // Exercise and Verify - run the report with wrong period
        asserterror RunVATRegisterReport(VATRegister, ReportType, StartDate, EndDate, PrintCompanyInfo); // Confirm final printing
        Assert.ExpectedError(WrongPeriodErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATRegisterFinalMissedPeriod()
    var
        VATRegister: Record "VAT Register";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        PrintCompanyInfo: Boolean;
    begin
        Initialize();
        // Setup - prepare data
        SelectVATRegister(VATRegister);

        // Setup - set report parameters values
        StartDate := GetStartDateForVATRegister(VATRegister.Code);
        StartDate := CalcDate('<1M>', StartDate);
        EndDate := GetEndDate(StartDate);
        ReportType := ReportType::Final;
        PrintCompanyInfo := true;

        // Exercise and Verify - run the report with wrong period
        asserterror RunVATRegisterReport(VATRegister, ReportType, StartDate, EndDate, PrintCompanyInfo); // Confirm final printing
        Assert.ExpectedError(PreviousPeriodNotPrintedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,FinalPrintMessageHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterReprint()
    var
        VATRegister: Record "VAT Register";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        PrintCompanyInfo: Boolean;
    begin
        Initialize();
        // Setup - prepare data
        SelectVATRegister(VATRegister);

        // Setup - set report parameters values
        StartDate := GetStartDateForVATRegister(VATRegister.Code);
        EndDate := GetEndDate(StartDate);
        ReportType := ReportType::Final;
        PrintCompanyInfo := true;

        // Exercise - run the report twice
        RunVATRegisterReport(VATRegister, ReportType, StartDate, EndDate, PrintCompanyInfo); // Confirm final printing
        ReportType := ReportType::Reprint;
        RunVATRegisterReport(VATRegister, ReportType, StartDate, EndDate, PrintCompanyInfo); // No additional confirm messages

        // Verify
        VATRegister.Get(VATRegister.Code);
        VATRegister.TestField("Last Printing Date", EndDate);
        VerifyVATBookEntries(StartDate, EndDate, VATRegister.Code, true);
        VerifyReprintInfoVATRegister(StartDate, EndDate, VATRegister.Code, true);

        // Tear down - rollback changes
        asserterror Error('');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,FinalPrintMessageHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterReprintWrongEndDate()
    var
        VATRegister: Record "VAT Register";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        NewEndDate: Date;
        PrintCompanyInfo: Boolean;
    begin
        Initialize();
        // Setup - prepare data
        SelectVATRegister(VATRegister);

        // Setup - set report parameters values
        StartDate := GetStartDateForVATRegister(VATRegister.Code);
        EndDate := GetEndDate(StartDate);
        ReportType := ReportType::Final;
        PrintCompanyInfo := true;

        // Exercise - run the report twice
        RunVATRegisterReport(VATRegister, ReportType, StartDate, EndDate, PrintCompanyInfo); // Confirm final printing
        ReportType := ReportType::Reprint;
        NewEndDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(10)), StartDate);

        // Verify - error message is shown for wrong dates for reprint
        asserterror RunVATRegisterReport(VATRegister, ReportType, StartDate, NewEndDate, PrintCompanyInfo);
        Assert.ExpectedError(ReprintInfoDoesNotExistErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,FinalPrintMessageHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterReprintWrongStartDate()
    var
        VATRegister: Record "VAT Register";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        NewStartDate: Date;
        PrintCompanyInfo: Boolean;
    begin
        Initialize();
        // Setup - prepare data
        SelectVATRegister(VATRegister);

        // Setup - set report parameters values
        StartDate := GetStartDateForVATRegister(VATRegister.Code);
        EndDate := GetEndDate(StartDate);
        ReportType := ReportType::Final;
        PrintCompanyInfo := true;

        // Exercise - run the report twice
        RunVATRegisterReport(VATRegister, ReportType, StartDate, EndDate, PrintCompanyInfo); // Confirm final printing
        ReportType := ReportType::Reprint;
        NewStartDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(10)), StartDate);

        // Verify - error message is shown for wrong dates for reprint
        asserterror RunVATRegisterReport(VATRegister, ReportType, NewStartDate, EndDate, PrintCompanyInfo);
        Assert.ExpectedError(ReprintInfoDoesNotExistErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,FinalPrintMessageHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterPageNumbering()
    var
        VATRegister: Record "VAT Register";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        PrintCompanyInfo: Boolean;
    begin
        Initialize();
        // Setup - prepare data
        SelectVATRegister(VATRegister);
        SetLastPrintedPage(VATRegister, 0);

        // Setup - set report parameters values
        StartDate := GetStartDateForVATRegisterFiscalYear(VATRegister.Code, false);
        EndDate := GetEndDate(StartDate);
        ReportType := ReportType::Final;
        PrintCompanyInfo := true;

        // Exercise - run the report
        RunVATRegisterReport(VATRegister, ReportType, StartDate, EndDate, PrintCompanyInfo);  // Confirm final printing

        // Verify
        VerifyPageNumbering(GetYearForPageNumbering(StartDate), 1, PrintCompanyInfo);

        // Tear down - rollback changes
        asserterror Error('');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,FinalPrintMessageHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterPageNumberingInitializeLastPrintedPage()
    var
        VATRegister: Record "VAT Register";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        PrintCompanyInfo: Boolean;
        LastPrintedPage: Integer;
    begin
        Initialize();
        // Setup - prepare data
        SelectVATRegister(VATRegister);
        LastPrintedPage := LibraryRandom.RandInt(10);
        SetLastPrintedPage(VATRegister, LastPrintedPage);

        // Setup - set report parameters values
        StartDate := GetStartDateForVATRegisterFiscalYear(VATRegister.Code, false);
        EndDate := GetEndDate(StartDate);
        ReportType := ReportType::Final;
        PrintCompanyInfo := true;

        // Exercise - run the report
        RunVATRegisterReport(VATRegister, ReportType, StartDate, EndDate, PrintCompanyInfo);  // Confirm final printing

        // Verify
        VerifyPageNumbering(GetYearForPageNumbering(StartDate), LastPrintedPage + 1, PrintCompanyInfo);

        // Tear down - rollback changes
        asserterror Error('');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,FinalPrintMessageHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterPageNumberingNoCompanyInfo()
    var
        VATRegister: Record "VAT Register";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        PrintCompanyInfo: Boolean;
        LastPrintedPage: Integer;
    begin
        Initialize();
        // Setup - prepare data
        SelectVATRegister(VATRegister);
        LastPrintedPage := LibraryRandom.RandInt(10);
        SetLastPrintedPage(VATRegister, LastPrintedPage);

        // Setup - set report parameters values
        StartDate := GetStartDateForVATRegisterFiscalYear(VATRegister.Code, false);
        EndDate := GetEndDate(StartDate);
        ReportType := ReportType::Final;
        PrintCompanyInfo := false;

        // Exercise - run the report
        RunVATRegisterReport(VATRegister, ReportType, StartDate, EndDate, PrintCompanyInfo); // Confirm final printing

        // Verify
        VerifyPageNumbering(GetYearForPageNumbering(StartDate), LastPrintedPage + 1, PrintCompanyInfo);

        // Tear down - rollback changes
        asserterror Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBookTest()
    var
        ReprintInfoFiscalReports: Record "Reprint Info Fiscal Reports";
        GLSetup: Record "General Ledger Setup";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        PrintCompanyInfo: Boolean;
    begin
        Initialize();

        // Setup - set report parameter values.
        ReportType := ReportType::Test;
        StartDate := GetStartDate(false);
        EndDate := GetEndDate(StartDate);
        PrintCompanyInfo := true;
        GLSetup.Get();

        // Exercise - Post and Print GL Book Entries.
        PostAndPrintGLBookEntry(ReportType, StartDate, EndDate, PrintCompanyInfo);

        // Verify GL Entry Book.
        VerifyGLBookEntryTestPrint(StartDate, EndDate);

        // Verify G/L Setup.
        VerifyGLSetup(GLSetup."Last Gen. Jour. Printing Date", GLSetup."Last General Journal No.");

        // Verify Reprinting Info.
        Assert.IsFalse(
          ReprintInfoFiscalReports.Get(
            ReprintInfoFiscalReports.Report::"G/L Book - Print", StartDate, EndDate), ReprintInfoShouldNotExistErr);

        // Tear Down.
        DeleteGLBookEntry();
    end;

    [Test]
    [HandlerFunctions('ConfirmCorrectPrintHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLBookFinalSameFiscalYear()
    var
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        PrintCompanyInfo: Boolean;
        LastGenJnlNo: Integer;
        LastPrintedPageNo: Integer;
    begin
        Initialize();

        // Setup - set report parameters values
        ReportType := ReportType::Final;
        PrintCompanyInfo := true;

        // Exercise - Post and Print GL Book Entries.
        StartDate := GetStartDate(false);
        EndDate := GetEndDate(StartDate);
        PostAndPrintGLBookEntry(ReportType, StartDate, EndDate, PrintCompanyInfo); // Confirm final printing.

        LastGenJnlNo := GetLastGenJnlNo();
        LastPrintedPageNo := GetLastPrintedPageNo();

        // Exercise - Post and Print GL Book Entries.
        StartDate := GetStartDate(false);  // Same Fiscal Year.
        EndDate := GetEndDate(StartDate);
        PostAndPrintGLBookEntry(ReportType, StartDate, EndDate, PrintCompanyInfo); // Confirm final printing.

        // Verify GL Entry Book.
        VerifyGLBookEntryFinalPrint(StartDate, EndDate, LastGenJnlNo);

        // Verify G/L Setup.
        VerifyGLSetup(EndDate, GetLastProgressiveNo(EndDate));

        // Verify Reprinting Info.
        VerifyGLBookReprintInfo(StartDate, EndDate, LastPrintedPageNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmCorrectPrintHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLBookFinalNewFiscalYear()
    var
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        PrintCompanyInfo: Boolean;
        LastGenJnlNo: Integer;
        LastPrintedPageNo: Integer;
    begin
        Initialize();

        // Setup - set report parameters values
        ReportType := ReportType::Final;
        PrintCompanyInfo := true;

        // Exercise - Post and Print GL Book Entries.
        StartDate := GetStartDate(false);
        EndDate := GetEndDate(StartDate);
        PostAndPrintGLBookEntry(ReportType, StartDate, EndDate, PrintCompanyInfo); // Confirm final printing.

        LastGenJnlNo := GetLastGenJnlNo();
        LastPrintedPageNo := GetLastPrintedPageNo();

        // Exercise - Post and Print GL Book Entries.
        StartDate := GetStartDate(true);  // New Fiscal Year.
        EndDate := GetEndDate(StartDate);
        PostAndPrintGLBookEntry(ReportType, StartDate, EndDate, PrintCompanyInfo); // Confirm final printing.

        // Verify GL Entry Book.
        VerifyGLBookEntryFinalPrint(StartDate, EndDate, LastGenJnlNo);

        // Verify G/L Setup.
        VerifyGLSetup(EndDate, GetLastProgressiveNo(EndDate));

        // Verify Reprinting Info.
        VerifyGLBookReprintInfo(StartDate, EndDate, LastPrintedPageNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBookFinalMissedPeriod()
    var
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        PrintCompanyInfo: Boolean;
    begin
        Initialize();

        // Setup - set report parameters values
        ReportType := ReportType::Final;
        PrintCompanyInfo := true;

        // Exercise - Post GL Book Entries w/o Printing.
        StartDate := GetStartDate(false);
        EndDate := GetEndDate(StartDate);
        CreatePostGLBookEntry(CalcDate('<' + Format(LibraryRandom.RandInt(15)) + 'D>', StartDate)); // Random Date within period.

        // Verify - Print Report for Next Month and Verify Error Message.
        StartDate := CalcDate('<1D>', EndDate);
        EndDate := GetEndDate(StartDate);
        asserterror PostAndPrintGLBookEntry(ReportType, StartDate, EndDate, PrintCompanyInfo); // Confirm final printing.
        Assert.ExpectedError(PreviousPeriodErr);

        // Tear Down.
        DeleteGLBookEntry();
    end;

    [Test]
    [HandlerFunctions('ConfirmCorrectPrintHandler,MessageHandler,GLBookPrintReqHandler')]
    [Scope('OnPrem')]
    procedure GLBookFinalTwice()
    var
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        PrintCompanyInfo: Boolean;
    begin
        Initialize();

        // Setup - set report parameters values
        ReportType := ReportType::Final;
        PrintCompanyInfo := true;

        // Exercise - Post and Print GL Book Entries.
        StartDate := GetStartDate(false);
        EndDate := GetEndDate(StartDate);
        PostAndPrintGLBookEntry(ReportType, StartDate, EndDate, PrintCompanyInfo); // Confirm final printing.

        // Verify - Print Report and Verify Error Message.
        Commit();
        LibraryVariableStorage.Enqueue(StartDate); // Store Start Date.
        LibraryVariableStorage.Enqueue(StartingDateErr); // Store expected message.
        REPORT.Run(REPORT::"G/L Book - Print", true); // Handler

        // Tear Down.
        DeleteGLBookEntry();
    end;

    [Test]
    [HandlerFunctions('ConfirmCorrectPrintHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLBookReprint()
    var
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        EndDate: Date;
        PrintCompanyInfo: Boolean;
        LastGenJnlNo: Integer;
        LastPrintedPageNo: Integer;
    begin
        Initialize();

        // Setup - set report parameters values
        ReportType := ReportType::Final;
        PrintCompanyInfo := true;
        LastGenJnlNo := GetLastGenJnlNo();
        LastPrintedPageNo := GetLastPrintedPageNo();

        // Exercise - Post and Print GL Book Entries.
        StartDate := GetStartDate(false);
        EndDate := GetEndDate(StartDate);
        PostAndPrintGLBookEntry(ReportType, StartDate, EndDate, PrintCompanyInfo); // Confirm final printing.
        RunGLBookReport(ReportType::Reprint, StartDate, EndDate, PrintCompanyInfo);

        // Verify GL Entry Book.
        VerifyGLBookEntryFinalPrint(StartDate, EndDate, LastGenJnlNo);

        // Verify G/L Setup.
        VerifyGLSetup(EndDate, GetLastProgressiveNo(EndDate));

        // Verify Reprinting Info.
        VerifyGLBookReprintInfo(StartDate, EndDate, LastPrintedPageNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBookReprintIncorrectPeriod()
    var
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        PrintCompanyInfo: Boolean;
    begin
        Initialize();

        // Setup - set report parameters values
        ReportType := ReportType::Reprint;
        PrintCompanyInfo := true;

        // Exercise - Post and Print GL Book Entries.
        StartDate := GetStartDate(false);

        // Verify - Print Report and Verify Error Message.
        asserterror PostAndPrintGLBookEntry(ReportType, StartDate, GetEndDate(StartDate), PrintCompanyInfo);
        Assert.ExpectedError(ReprintInfoDoesNotExistErr);

        // Tear Down.
        DeleteGLBookEntry();
    end;

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler,ConfirmHandlerTrue,FinalPrintMessageHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterGroupedWithPrintCompanyInformation()
    var
        VATRegister: Record "VAT Register";
        PeriodStartDate: Date;
        PeriodEndDate: Date;
        ReportType: Option Test,Final,Reprint;
    begin
        // Purpose of the test is to verify that that page numbering works in VAT Register Grouped.

        // Setup.
        Initialize();
        SelectVATRegister(VATRegister);
        PeriodStartDate := GetStartDateForVATRegister(VATRegister.Code);
        PeriodEndDate := GetEndDate(PeriodStartDate);
        RunVATRegisterReport(VATRegister, ReportType::Final, PeriodStartDate, PeriodEndDate, true);
        EnqueueValuesInVATRegisterGroupedHandler(PeriodStartDate, PeriodEndDate);
        Commit();  // Commit is required to run VAT Register Grouped Report.

        // Exercise.
        REPORT.Run(REPORT::"VAT Register Grouped");  // Opens handler - VATRegisterGroupedRequestPageHandler.

        // Verify.
        VerifyPageNumberingVATRegisterGrouped(1, true);  // 1 is used for First page number and True is used for Print Company Information.
    end;

    [Test]
    [HandlerFunctions('VATRegisterReportPrintHandler')]
    [Scope('OnPrem')]
    procedure OnVATRegisterPrintingForServiceInvoice()
    var
        VATRegister: Record "VAT Register";
        ServiceHeader: Record "Service Header";
        StartDate: Date;
        EndDate: Date;
        GLLastGJPrintingDatePrevValue: Date;
        WorkDatePrevValue: Date;
    begin
        // [FEATURE] [Services] [Invoice]
        // [SCENARIO 363245] Service Invoice's Customer name and VAT Registration No. should be printed in VAT Fiscal Register report
        Initialize();

        SelectSalesVATRegister(VATRegister);
        StartDate := GetStartDateForVATRegisterFiscalYear(VATRegister.Code, false);
        EndDate := GetEndDate(StartDate);

        // [GIVEN] Service Invoice posted
        GLLastGJPrintingDatePrevValue := SetGLLastGJPrintingDate(StartDate);
        WorkDatePrevValue := WorkDate();
        WorkDate := LibraryUtility.GenerateRandomDate(StartDate, EndDate);
        CreateAndPostServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, VATRegister.Code);

        // [WHEN] Run VAT Fiscal Register report for the period where Invoice is posted
        Commit();
        RunVATRegisterPrint(StartDate, EndDate, VATRegister.Code);

        // [THEN] Customer's Name and VAT Registration No. are filled in report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow(NameTok, ServiceHeader."Bill-to Name") + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals(VATRegTok, ServiceHeader."VAT Registration No.");

        // Tear Down
        SetGLLastGJPrintingDate(GLLastGJPrintingDatePrevValue);
        WorkDate := WorkDatePrevValue;
    end;

    [Test]
    [HandlerFunctions('VATRegisterReportPrintHandler')]
    [Scope('OnPrem')]
    procedure OnVATRegisterPrintingForServiceCrMemo()
    var
        VATRegister: Record "VAT Register";
        ServiceHeader: Record "Service Header";
        StartDate: Date;
        EndDate: Date;
        GLLastGJPrintingDatePrevValue: Date;
        WorkDatePrevValue: Date;
    begin
        // [FEATURE] [Services] [Credit Memo]
        // [SCENARIO 363245] Service Credit Memo's Customer name and VAT Registration No. should be printed in VAT Fiscal Register report
        Initialize();

        SelectSalesVATRegister(VATRegister);
        StartDate := GetStartDateForVATRegisterFiscalYear(VATRegister.Code, false);
        EndDate := GetEndDate(StartDate);

        // [GIVEN] Service Credit Memo posted
        GLLastGJPrintingDatePrevValue := SetGLLastGJPrintingDate(StartDate);
        WorkDatePrevValue := WorkDate();
        WorkDate := LibraryUtility.GenerateRandomDate(StartDate, EndDate);
        CreateAndPostServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", VATRegister.Code);

        // [WHEN] Run VAT Fiscal Register report for the period where Credit Memo is posted
        Commit();
        RunVATRegisterPrint(StartDate, EndDate, VATRegister.Code);

        // [THEN] Customer's Name and VAT Registration No. are filled in report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow(NameTok, ServiceHeader."Bill-to Name") + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals(VATRegTok, ServiceHeader."VAT Registration No.");

        // Tear Down
        SetGLLastGJPrintingDate(GLLastGJPrintingDatePrevValue);
        WorkDate := WorkDatePrevValue;
    end;

    [Test]
    [HandlerFunctions('VATRegisterReportPrintHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterTestReverseChargeCustEmptyCountryCode()
    var
        NoSeries: Record "No. Series";
        VATBookEntry: Record "VAT Book Entry";
        StartDate: Date;
    begin
        // [SCENARIO 375440] Entries with empty Country Code with VAT Calculation Type "Reverse Charge" are shown in report VAT Register with empty field "IntraC".
        Initialize();

        // [GIVEN] VAT Book Entry with "VAT Calculation Type" = "Reverse Charge VAT" and Customer with empty "Country/Region Code".
        NoSeries.Get(CreateNoSeries(NoSeries."No. Series Type"::Sales, CreateVATRegister()));
        CreateVATBookEntry(
          VATBookEntry, CreateCustomer(''), NoSeries.Code, VATBookEntry.Type::Sale,
          VATBookEntry."VAT Calculation Type"::"Reverse Charge VAT", WorkDate());

        // [WHEN] Run report VAT Register - Print.
        Commit();
        StartDate := GetStartDateForVATRegister(NoSeries."VAT Register");
        RunVATRegisterPrint(StartDate, GetEndDate(StartDate), NoSeries."VAT Register");

        // [THEN] Field IntraC is not shown in the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('VAT_Register_Code', NoSeries."VAT Register");
        LibraryReportDataset.AssertElementWithValueNotExist('IntraC', 'I.O.');
    end;

    [Test]
    [HandlerFunctions('VATRegisterReportPrintHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterTestReverseChargeCustCompanyCountryCode()
    var
        NoSeries: Record "No. Series";
        VATBookEntry: Record "VAT Book Entry";
        CompanyInformation: Record "Company Information";
        StartDate: Date;
    begin
        // [SCENARIO 375440] Entries with Country Code equal to Company's one with VAT Calculation Type "Reverse Charge" are shown in report VAT Register with empty field "IntraC".
        Initialize();

        // [GIVEN] VAT Book Entry with "VAT Calculation Type" = "Reverse Charge VAT" and Customer with "Country/Region Code" = Company's Country/Region Code 'IT'.
        NoSeries.Get(CreateNoSeries(NoSeries."No. Series Type"::Sales, CreateVATRegister()));
        CompanyInformation.Get();
        CreateVATBookEntry(
          VATBookEntry, CreateCustomer(CompanyInformation."Country/Region Code"), NoSeries.Code, VATBookEntry.Type::Sale,
          VATBookEntry."VAT Calculation Type"::"Reverse Charge VAT", WorkDate());

        // [WHEN] Run report VAT Register - Print.
        Commit();
        StartDate := GetStartDateForVATRegister(NoSeries."VAT Register");
        RunVATRegisterPrint(StartDate, GetEndDate(StartDate), NoSeries."VAT Register");

        // [THEN] Field IntraC is not shown in the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('VAT_Register_Code', NoSeries."VAT Register");
        LibraryReportDataset.AssertElementWithValueNotExist('IntraC', 'I.O.');
    end;

    [Test]
    [HandlerFunctions('VATRegisterReportPrintHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterTestReverseChargeCustExtCountryCode()
    var
        NoSeries: Record "No. Series";
        VATBookEntry: Record "VAT Book Entry";
        StartDate: Date;
    begin
        // [SCENARIO 375440] Entries with Country Code different from Company's one with VAT Calculation Type "Reverse Charge" are filled in report VAT Register with empty field "IntraC".
        Initialize();

        // [GIVEN] VAT Book Entry with "VAT Calculation Type" = "Reverse Charge VAT" and Customer with external "Country/Region Code" 'AT'.
        NoSeries.Get(CreateNoSeries(NoSeries."No. Series Type"::Sales, CreateVATRegister()));
        CreateVATBookEntry(
          VATBookEntry, CreateCustomer(CreateCountryRegionCode()), NoSeries.Code, VATBookEntry.Type::Sale,
          VATBookEntry."VAT Calculation Type"::"Reverse Charge VAT", WorkDate());

        // [WHEN] Run report VAT Register - Print.
        Commit();
        StartDate := GetStartDateForVATRegister(NoSeries."VAT Register");
        RunVATRegisterPrint(StartDate, GetEndDate(StartDate), NoSeries."VAT Register");

        // [THEN] Field IntraC is shown in the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('VAT_Register_Code', NoSeries."VAT Register");
        LibraryReportDataset.AssertElementWithValueExists('IntraC', 'I.O.');
    end;

    [Test]
    [HandlerFunctions('VATRegisterReportPrintHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterTestReverseChargeVendEmptyCountryCode()
    var
        NoSeries: Record "No. Series";
        VATBookEntry: Record "VAT Book Entry";
        StartDate: Date;
    begin
        // [SCENARIO 375440] Entries with empty Country Code with VAT Calculation Type "Reverse Charge" are shown in report VAT Register with empty field "IntraC".
        Initialize();

        // [GIVEN] VAT Book Entry with "VAT Calculation Type" = "Reverse Charge VAT" and Vendor with empty "Country/Region Code".
        NoSeries.Get(CreateNoSeries(NoSeries."No. Series Type"::Sales, CreateVATRegister()));
        CreateVATBookEntry(
          VATBookEntry, CreateVendor(''), NoSeries.Code, VATBookEntry.Type::Purchase,
          VATBookEntry."VAT Calculation Type"::"Reverse Charge VAT", WorkDate());

        // [WHEN] Run report VAT Register - Print.
        Commit();
        StartDate := GetStartDateForVATRegister(NoSeries."VAT Register");
        RunVATRegisterPrint(StartDate, GetEndDate(StartDate), NoSeries."VAT Register");

        // [THEN] Field IntraC is not shown in the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('VAT_Register_Code', NoSeries."VAT Register");
        LibraryReportDataset.AssertElementWithValueNotExist('IntraC', 'I.O.');
    end;

    [Test]
    [HandlerFunctions('VATRegisterReportPrintHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterTestReverseChargeVendCompanyCountryCode()
    var
        NoSeries: Record "No. Series";
        VATBookEntry: Record "VAT Book Entry";
        CompanyInformation: Record "Company Information";
        StartDate: Date;
    begin
        // [SCENARIO 375440] Entries with Country Code equal to Company's one with VAT Calculation Type "Reverse Charge" are shown in report VAT Register with empty field "IntraC".
        Initialize();

        // [GIVEN] VAT Book Entry with "VAT Calculation Type" = "Reverse Charge VAT" and Vendor with "Country/Region Code" = Company's Country/Region Code 'IT'.
        NoSeries.Get(CreateNoSeries(NoSeries."No. Series Type"::Sales, CreateVATRegister()));
        CompanyInformation.Get();
        CreateVATBookEntry(
          VATBookEntry, CreateVendor(CompanyInformation."Country/Region Code"), NoSeries.Code, VATBookEntry.Type::Purchase,
          VATBookEntry."VAT Calculation Type"::"Reverse Charge VAT", WorkDate());

        // [WHEN] Run report VAT Register - Print.
        Commit();
        StartDate := GetStartDateForVATRegister(NoSeries."VAT Register");
        RunVATRegisterPrint(StartDate, GetEndDate(StartDate), NoSeries."VAT Register");

        // [THEN] Field IntraC is not shown in the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('VAT_Register_Code', NoSeries."VAT Register");
        LibraryReportDataset.AssertElementWithValueNotExist('IntraC', 'I.O.');
    end;

    [Test]
    [HandlerFunctions('VATRegisterReportPrintHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterTestReverseChargeVendExtCountryCode()
    var
        NoSeries: Record "No. Series";
        VATBookEntry: Record "VAT Book Entry";
        StartDate: Date;
    begin
        // [SCENARIO 375440] Entries with Country Code different from Company's one with VAT Calculation Type "Reverse Charge" are filled in report VAT Register with empty field "IntraC".
        Initialize();

        // [GIVEN] VAT Book Entry with "VAT Calculation Type" = "Reverse Charge VAT" and Vendor with external "Country/Region Code" 'AT'.
        NoSeries.Get(CreateNoSeries(NoSeries."No. Series Type"::Sales, CreateVATRegister()));
        CreateVATBookEntry(
          VATBookEntry, CreateVendor(CreateCountryRegionCode()), NoSeries.Code, VATBookEntry.Type::Purchase,
          VATBookEntry."VAT Calculation Type"::"Reverse Charge VAT", WorkDate());

        // [WHEN] Run report VAT Register - Print.
        Commit();
        StartDate := GetStartDateForVATRegister(NoSeries."VAT Register");
        RunVATRegisterPrint(StartDate, GetEndDate(StartDate), NoSeries."VAT Register");

        // [THEN] Field IntraC is shown in the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('VAT_Register_Code', NoSeries."VAT Register");
        LibraryReportDataset.AssertElementWithValueExists('IntraC', 'I.O.');
    end;

    [Test]
    [HandlerFunctions('VATRegisterReportPrintHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterTestReverseChargeSettlEmptyCountryCode()
    var
        NoSeries: Record "No. Series";
        VATBookEntry: Record "VAT Book Entry";
        StartDate: Date;
    begin
        // [SCENARIO 375440] Entries with empty Country Code with VAT Calculation Type "Reverse Charge" are shown in report VAT Register with empty field "IntraC".
        Initialize();

        // [GIVEN] VAT Book Entry with "VAT Calculation Type" = "Reverse Charge VAT" and Type = Settlement.
        NoSeries.Get(CreateNoSeries(NoSeries."No. Series Type"::Sales, CreateVATRegister()));
        CreateVATBookEntry(
          VATBookEntry, LibraryUTUtility.GetNewCode(), NoSeries.Code, VATBookEntry.Type::Settlement,
          VATBookEntry."VAT Calculation Type"::"Reverse Charge VAT", WorkDate());

        // [WHEN] Run report VAT Register - Print.
        Commit();
        StartDate := WorkDate();
        RunVATRegisterPrint(StartDate, GetEndDate(StartDate), NoSeries."VAT Register");

        // [THEN] Field IntraC is not shown in the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('VAT_Register_Code', NoSeries."VAT Register");
        LibraryReportDataset.AssertElementWithValueNotExist('IntraC', 'I.O.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandlerStub')]
    [Scope('OnPrem')]
    procedure VATRegisterPageNumberingNextCalendarYearPrint()
    var
        VATRegister: Record "VAT Register";
        AccountingPeriod: Record "Accounting Period";
        NoSeries: Record "No. Series";
        VATBookEntry: Record "VAT Book Entry";
        ReportType: Option Test,Final,Reprint;
        StartDate: Date;
        ReportStartDate: Date;
        ReportEndDate: Date;
        PostingDate: Date;
        Index: Integer;
    begin
        // [SCENARIO 378881] Page numbering "VAT Register - Print" report must not consider Accounting Period settings and must consider calendar year enumerating from first page number
        Initialize();

        StartDate := CalcDate('<3Y + CY + 1D>', GetStartDate(true));
        NoSeries.Get(CreateNoSeries(NoSeries."No. Series Type"::Sales, CreateVATRegister()));
        VATRegister.Get(NoSeries."VAT Register");
        VATRegister."Last Printing Date" := StartDate - 1;
        VATRegister.Modify();
        // [GIVEN] "VAT Register" "VR" where and "Last Printed Page" = 10
        SetLastPrintedPage(VATRegister, 10);

        // [GIVEN] "Accounting Period[1]" where "Starting Date" = 01/01/2016, "New Fiscal Year" = FALSE
        // [GIVEN] "Accounting Period[2]" where "Starting Date" = 01/02/2016, "New Fiscal Year" = FALSE
        // [GIVEN] "Accounting Period[3]" where "Starting Date" = 01/03/2016, "New Fiscal Year" = FALSE
        // [GIVEN] "Accounting Period[4]" where "Starting Date" = 01/04/2016, "New Fiscal Year" = TRUE
        // [GIVEN] "Accounting Period[5]" where "Starting Date" = 01/05/2016, "New Fiscal Year" = FALSE
        // [GIVEN] "Accounting Period[6]" where "Starting Date" = 01/06/2016, "New Fiscal Year" = FALSE
        // [GIVEN] 6 VAT Book Entries where "Posting Date" hits corresponding accounting period
        for Index := 0 to 6 do begin
            PostingDate := CalcDate('<' + Format(Index) + 'M>', StartDate);
            CreateAccountingPeriod(AccountingPeriod, PostingDate, (Index + 1) mod 4 = 0);
            CreateVATBookEntry(
              VATBookEntry, LibraryUTUtility.GetNewCode(), NoSeries.Code, VATBookEntry.Type::Purchase,
              VATBookEntry."VAT Calculation Type"::"Reverse Charge VAT", PostingDate + 1);
        end;

        // [GIVEN] Printed "VAT Register - Print" report for January 2016 with two pages. Where "Page Number[1]" = "Page 2016/1" and "Page Number[2]" = "Page 2016/2"
        // [GIVEN] Printed "VAT Register - Print" report for February 2016 with two pages. Where "Page Number[1]" = "Page 2016/3" and "Page Number[2]" = "Page 2016/4"
        // [GIVEN] Printed "VAT Register - Print" report for March 2016 with two pages. Where "Page Number[1]" = "Page 2016/5" and "Page Number[2]" = "Page 2016/6"

        // [WHEN] Print "VAT Register - Print" report for April, May, June 2016 with two pages each.
        // [THEN] "Page Number[1]" = "Page 2016/7" and "Page Number[2]" = "Page 2016/8" for April
        // [THEN] "Page Number[1]" = "Page 2016/9" and "Page Number[2]" = "Page 2016/10" for May
        // [THEN] "Page Number[1]" = "Page 2016/11" and "Page Number[2]" = "Page 2016/12" for June
        for Index := 0 to 6 do begin
            ReportStartDate := CalcDate('<' + Format(Index) + 'M>', StartDate);
            ReportEndDate := GetEndDate(ReportStartDate);

            RunVATRegisterReport(VATRegister, ReportType::Final, ReportStartDate, ReportEndDate, true);

            VATRegister.Find();
            SetLastPrintedPage(VATRegister, (Index + 1) * 2);

            VerifyPageNumberOnWorksheet(Index * 2 + 1, GetYearForPageNumbering(StartDate), 16, 28, 2);
            VerifyPageNumberOnWorksheet(Index * 2 + 2, GetYearForPageNumbering(StartDate), 21, 17, 3);
        end;
    end;

    [Test]
    [HandlerFunctions('PostingDateConfim,CancelEntriesRequestPage,CancelFaEntryMessageHandler,GLBookRequestPage')]
    procedure GLBookReportsTToRunAfterFixedAssetsDeletion()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBook: Record "Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        FAGLJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        FALedgerEntries: TestPage "FA Ledger Entries";
        FAGLDoc: code[20];
        InvoiceNo: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        // [SCENIRIO] 524065 Error occur on G/L book when printing after the deletion of the fixed asset.
        Initialize();

        // [GIVEN] Create a Fixed Asste with Posting Group.
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);

        // [GIVEN] Depreciation Book created.
        DepreciationBook.Get(LibraryFixedAsset.GetDefaultDeprBook());
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);

        // [GIVEN] Validation of FA Posting Group, Depreciation Book Code and Depreciation Starting Date.
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Validate("Depreciation Book Code", DepreciationBook.Code);
        FADepreciationBook.Validate("Depreciation Starting Date", Today());

        // [GIVEN] Depreciation Ending is calculated one year from Today.
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<1Y>', Today()));
        FADepreciationBook.Modify(true);

        // [GIVEN] Create a Purchase Header with Document type Invoice and Validate Posting date.
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchHeader.Validate("Posting Date", Today + 1);
        PurchHeader.Modify(true);

        // [GIVEN] Create a Purchase Line with Type Fixed assets and validate the Price.
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::"Fixed Asset", FixedAsset."No.", LibraryRandom.RandInt(10));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);

        // [GIVEN] Post the cretaed Purchase Document.
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [GIVEN] FA Ledger Entry is found for respective Purchase Order.
        FALedgerEntry.SetRange("Document No.", InvoiceNo);
        FALedgerEntry.FindFirst();

        // [GIVEN] Invoke the Cancel Entry of the same FA Ledger Entry.
        FALedgerEntries.OpenEdit();
        FALedgerEntries.FILTER.SetFilter("Entry No.", Format(FALedgerEntry."Entry No."));
        FALedgerEntries.CancelEntries.Invoke();

        // [GIVEN] Create GL Account for Balancing Account.
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Find the Canceled Entry and add Balancing Entry.
        FAGLJournalLine.SetRange("Account No.", FixedAsset."No.");
        FAGLJournalLine.FindLast();

        // [GIVEN] Assign No Series to a variable.
        FAGLDoc := LibraryERM.CreateNoSeriesCode();

        // [GIVEN] Validate Balance Account Type and Account No with Created GL Account.
        FAGLJournalLine.Validate("Document No.", FAGLDoc);
        FAGLJournalLine.Validate("Bal. Account Type", FAGLJournalLine."Bal. Account Type"::"G/L Account");
        FAGLJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        FAGLJournalLine.Modify(true);

        // [GIVEN] Post the Fixed Assets Gen Journal.
        FAGLJournalLine.SetRange("Document No.", FAGLDoc);
        FAGLJournalLine.FindFirst();
        Codeunit.Run(Codeunit::"Gen. Jnl.-Post Line", FAGLJournalLine);

        // [THEN] Delete the Fixed Asstes.
        FixedAsset.Delete(true);

        // [GIVEN] Assign The Start Date and End Date.
        StartDate := GetStartDate(false);
        EndDate := GetEndDate(StartDate);

        // [GIVEN] Enqueue all The Values set in request page.
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);
        Commit();

        // [THEN] Run GL Book Report to ensure it is not effected.
        REPORT.Run(REPORT::"G/L Book - Print");
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), RowMustExistErr);
    end;

    [Test]
    procedure ITDeniedVendorsListTest()
    var
        CountryRegion: array[2] of Record "Country/Region";
        Vendor: array[2] of Record Vendor;
        DummyRecordVar: Variant;
    begin
        // [SCENARIO 495201] IT denied vendors list contains vendors from denylisted countries
        Initialize();

        // [GIVEN] Deny listed country "XX"
        LibraryERM.CreateCountryRegion(CountryRegion[1]);
        SetOnDenyList(CountryRegion[1], true);

        // [GIVEN] Regular country "YY"
        LibraryERM.CreateCountryRegion(CountryRegion[2]);

        // [GIVEN] Vendor "V-XX" from deny listed country "XX"
        LibraryPurchase.CreateVendor(Vendor[1]);
        SetCountryRegionCode(Vendor[1], CountryRegion[1].Code);

        // [GIVEN] Vendor  "V-YY" from regular country "YY"
        LibraryPurchase.CreateVendor(Vendor[2]);
        SetCountryRegionCode(Vendor[2], CountryRegion[2].Code);

        // [WHEN] Run IT denied vendors list report
        LibraryReportDataset.RunReportAndLoad(Report::"Denied Vendors List", DummyRecordVar, '');

        // [THEN] Report contains vendor "V-XX" from deny listed country "XX"
        LibraryReportDataset.AssertElementWithValueExists('VendorNo', Vendor[1]."No.");

        // [THEN] Report does not contain vendor "V-YY" from regular country "YY"
        LibraryReportDataset.AssertElementWithValueNotExist('VendorNo', Vendor[2]."No.");
    end;


    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        SetCompanyInformation(); // Registration Company No., Fiscal Code.
        DeleteGLBookEntry(); // Delete Demo Data.
        IsInitialized := true;
        Commit();
    end;

    local procedure CreateAccountingPeriod(var AccPeriod: Record "Accounting Period"; StartingDate: Date; NewFiscalYear: Boolean)
    begin
        AccPeriod.Init();
        AccPeriod.Validate("Starting Date", StartingDate);
        AccPeriod.Validate("New Fiscal Year", NewFiscalYear);
        AccPeriod.Insert(true);
    end;

    local procedure CreatePostGLBookEntry(PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          LibraryRandom.RandDec(1000, 2));

        LibraryERM.CreateGLAccount(GLAccount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure EnqueueValuesInVATRegisterGroupedHandler(PeriodStartingDate: Date; PeriodEndingDate: Date)
    begin
        // Enqueue Values For VAT Register Grouped Request Page Handler.
        LibraryVariableStorage.Enqueue(PeriodStartingDate);
        LibraryVariableStorage.Enqueue(PeriodEndingDate);
    end;

    local procedure GetYearForPageNumbering(Date: Date): Integer
    begin
        exit(Date2DMY(Date, 3));
    end;

    local procedure GetNoSeries(VATRegisterCode: Code[10]) NoSeriesCode: Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.SetFilter("VAT Register", VATRegisterCode);
        NoSeries.FindFirst();
        NoSeriesCode := NoSeries.Code;
    end;

    local procedure GetEndDate(Date: Date) EndDate: Date
    begin
        EndDate := CalcDate('<CM>', Date);
    end;

    local procedure GetStartDate(NewFiscalYear: Boolean) StartDate: Date
    var
        AccPeriod: Record "Accounting Period";
    begin
        AccPeriod.SetFilter("Starting Date", '>%1', GetLastPostingDate());
        if not AccPeriod.FindFirst() then
            CreateAccountingPeriod(AccPeriod, CalcDate('<CM+1D>', GetLastPostingDate()), NewFiscalYear);
        StartDate := AccPeriod."Starting Date";
    end;

    local procedure GetLastPostingDate() LastPostingDate: Date
    var
        GLEntry: Record "G/L Entry";
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        LastPostingDate := GLSetup."Last Gen. Jour. Printing Date"; // G/L Book Entries are either Printed or Deleted.
        if LastPostingDate = 0D then begin
            GLEntry.SetCurrentKey("Official Date");
            GLEntry.FindLast();
            LastPostingDate := GLEntry."Posting Date";
        end;
    end;

    local procedure GetLastPrintedPageNo(): Integer
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(GLSetup."Last Printed G/L Book Page");
    end;

    local procedure GetLastGenJnlNo(): Integer
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(GLSetup."Last General Journal No.");
    end;

    local procedure GetLastProgressiveNo(EndDate: Date): Integer
    var
        GLBookEntry: Record "GL Book Entry";
    begin
        GLBookEntry.SetCurrentKey("Official Date");
        GLBookEntry.SetFilter("Progressive No.", '<>%1', 0);
        GLBookEntry.SetFilter("Official Date", '..%1', ClosingDate(EndDate));
        GLBookEntry.FindLast();
        exit(GLBookEntry."Progressive No.");
    end;

    local procedure GetStartDateForVATRegister(VATRegisterCode: Code[10]) StartDate: Date
    var
        VATBookEntry: Record "VAT Book Entry";
        AccountingPeriod: Record "Accounting Period";
    begin
        VATBookEntry.SetCurrentKey("Posting Date", "Entry No.");
        VATBookEntry.SetRange("Printing Date", 0D);
        VATBookEntry.SetFilter(Type, '<>%1', VATBookEntry.Type::Settlement);
        VATBookEntry.CalcFields("No. Series");
        VATBookEntry.SetFilter("No. Series", GetNoSeries(VATRegisterCode));
        VATBookEntry.FindFirst();
        AccountingPeriod.SetFilter("Starting Date", '<=%1', VATBookEntry."Posting Date");
        AccountingPeriod.FindLast();
        StartDate := AccountingPeriod."Starting Date";
    end;

    local procedure GetStartDateForVATRegisterFiscalYear(VATRegisterCode: Code[10]; NewFiscalYear: Boolean) StartDate: Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        StartDate := GetStartDateForVATRegister(VATRegisterCode);
        AccountingPeriod.SetRange("Starting Date", StartDate);
        AccountingPeriod.FindFirst();
        AccountingPeriod.Validate("New Fiscal Year", NewFiscalYear);
        AccountingPeriod.Modify(true);
    end;

    local procedure GetSetManuallyMessage(): Text
    var
        GLSetup: Record "General Ledger Setup";
    begin
        exit(StrSubstNo(SetManuallyMsg, GLSetup.FieldCaption("Last Printed G/L Book Page"), GLSetup.TableCaption()));
    end;

    local procedure IsEqual(Expected: Text[1024]; Actual: Text[1024]): Boolean
    begin
        if StrPos(Expected, Actual) > 0 then
            exit(true);
        exit(false);
    end;

    local procedure IsNewFiscalYear(StartDate: Date): Boolean
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.Get(StartDate);
        exit(AccountingPeriod."New Fiscal Year");
    end;

    local procedure PostAndPrintGLBookEntry(ReportType: Option; StartDate: Date; EndDate: Date; PrintCompanyInfo: Boolean)
    begin
        CreatePostGLBookEntry(CalcDate('<' + Format(LibraryRandom.RandInt(15)) + 'D>', StartDate)); // Random Date within period.

        // Exercise - run the report.
        RunGLBookReport(ReportType, StartDate, EndDate, PrintCompanyInfo); // Confirm final printing
    end;

    local procedure DeleteGLBookEntry()
    var
        GLBookEntry: Record "GL Book Entry";
    begin
        GLBookEntry.DeleteAll(false); // Delete GL Book Entry.
    end;

    local procedure RunGLBookReport(ReportType: Option Test,Final,Reprint; StartDate: Date; EndDate: Date; PrintCompanyInfo: Boolean)
    var
        GLBookPrint: Report "G/L Book - Print";
        CompanyInformation: array[7] of Text[100];
    begin
        if ReportType = ReportType::Final then begin
            LibraryVariableStorage.Enqueue(ConfirmCorrectPrintMsg); // Store expected message
            LibraryVariableStorage.Enqueue(EntriesHaveBeenMarkedMsg); // Store expected message
            LibraryVariableStorage.Enqueue(GetSetManuallyMessage()); // Store expected message
        end;

        GetCompanyInformation(CompanyInformation);
        GLBookPrint.InitializeRequest(ReportType, StartDate, EndDate, PrintCompanyInfo, CompanyInformation);
        GLBookPrint.SaveAsExcel(TemporaryPath + LibraryUtility.GenerateGUID() + XlsxTok);
        UpdateLastPageNo();

        LibraryVariableStorage.Clear();
    end;

    local procedure RunVATRegisterReport(VATRegister: Record "VAT Register"; ReportType: Option; StartDate: Date; EndDate: Date; PrintCompanyInfo: Boolean)
    var
        VATRegisterPrint: Report "VAT Register - Print";
        CompanyInformation: array[7] of Text[100];
    begin
        GetCompanyInformation(CompanyInformation);
        VATRegisterPrint.InitializeRequest(VATRegister, ReportType, StartDate, EndDate, PrintCompanyInfo, CompanyInformation);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        VATRegisterPrint.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    local procedure SelectVATRegister(var VATRegister: Record "VAT Register")
    var
        VATBookEntry: Record "VAT Book Entry";
        NoSeries: Record "No. Series";
    begin
        VATBookEntry.SetFilter("Sell-to/Buy-from No.", '<>%1', '');
        VATBookEntry.SetRange("Printing Date", 0D);
        VATBookEntry.SetFilter(Type, '<>%1', VATBookEntry.Type::Settlement);
        VATBookEntry.CalcFields("No. Series");
        VATBookEntry.SetFilter("No. Series", '<>''''');
        VATBookEntry.FindLast();
        VATBookEntry.CalcFields("No. Series");
        NoSeries.Get(VATBookEntry."No. Series");
        VATRegister.Get(NoSeries."VAT Register");
    end;

    local procedure SelectSalesVATRegister(var VATRegister: Record "VAT Register")
    var
        VATBookEntry: Record "VAT Book Entry";
        NoSeries: Record "No. Series";
    begin
        VATBookEntry.SetRange("Printing Date", 0D);
        VATBookEntry.SetRange(Type, VATBookEntry.Type::Sale);
        VATBookEntry.CalcFields("No. Series");
        VATBookEntry.SetFilter("No. Series", '<>''''');
        VATBookEntry.FindLast();
        VATBookEntry.CalcFields("No. Series");
        NoSeries.Get(VATBookEntry."No. Series");
        VATRegister.Get(NoSeries."VAT Register");
    end;

    local procedure RunVATRegisterPrint(StartDate: Date; EndDate: Date; VATRegisterCode: Code[10])
    var
        ReportType: Option Test,Final,Reprint;
        PrintCompanyInfo: Boolean;
    begin
        ReportType := ReportType::Test;
        PrintCompanyInfo := true;

        LibraryVariableStorage.Enqueue(ReportType);
        LibraryVariableStorage.Enqueue(VATRegisterCode);
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);
        LibraryVariableStorage.Enqueue(PrintCompanyInfo);

        REPORT.Run(REPORT::"VAT Register - Print");
    end;

    local procedure SetLastPrintedPage(var VATRegister: Record "VAT Register"; LastPrintedPage: Integer)
    begin
        VATRegister.Validate("Last Printed VAT Register Page", LastPrintedPage);
        VATRegister.Modify(true);
    end;

    local procedure SetOnDenyList(var CountryRegion: Record "Country/Region"; NewOnDenyList: Boolean)
    begin
        CountryRegion.Validate("On Deny List", NewOnDenyList);
        CountryRegion.Modify(true);
    end;

    local procedure SetCompanyInformation()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyInfo.Validate("Register Company No.", Format(LibraryRandom.RandInt(10)));
        CompanyInfo.Validate("Fiscal Code", '01369030935 '); // Valid Fiscal Code
        CompanyInfo.Modify(true);
    end;

    local procedure GetCompanyInformation(var CompanyInformation: array[7] of Text[100])
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyInformation[1] := CompanyInfo.Name;
        CompanyInformation[2] := CompanyInfo.Address;
        CompanyInformation[3] := CopyStr(CompanyInfo."Post Code" + '  ' + CompanyInfo.City + '  ' + CompanyInfo.County, 1, 50);
        CompanyInformation[4] := CompanyInfo."Register Company No.";
        CompanyInformation[5] := CompanyInfo."VAT Registration No.";
        CompanyInformation[6] := CompanyInfo."Fiscal Code";
    end;

    local procedure CreateAndPostServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; VATRegisterCode: Code[10])
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceLine: Record "Service Line";
        NoSeries: Record "No. Series";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo('');
        Customer.Modify();
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");
        ServiceHeader.Validate(
          "Operation Type",
          CreateNoSeries(NoSeries."No. Series Type"::Sales, VATRegisterCode));
        ServiceHeader.Validate("Posting Date", WorkDate());
        ServiceHeader.Modify();
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure CreateNoSeries(NoSeriesType: Enum "No. Series Type"; VATRegisterCode: Code[10]): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Get(LibraryERM.CreateNoSeriesCode());
        NoSeries."No. Series Type" := NoSeriesType;
        NoSeries."VAT Register" := VATRegisterCode;
        NoSeries."Date Order" := true;
        NoSeries.Modify();

        LibraryERM.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        exit(NoSeries.Code);
    end;

    local procedure CreateVATBookEntry(var VATBookEntry: Record "VAT Book Entry"; SellToBuyFromNo: Code[20]; NoSeriesCode: Code[20]; VATBookEntryType: Enum "General Posting Type"; VATCalculationType: Enum "Tax Calculation Type"; PostingDate: Date)
    begin
        VATBookEntry."Entry No." := LibraryUtility.GetNewRecNo(VATBookEntry, VATBookEntry.FieldNo("Entry No."));
        VATBookEntry.Type := VATBookEntryType;
        VATBookEntry."No. Series" := NoSeriesCode;
        VATBookEntry."Posting Date" := PostingDate;
        VATBookEntry."Sell-to/Buy-from No." := SellToBuyFromNo;
        VATBookEntry."Document No." := LibraryUTUtility.GetNewCode();
        VATBookEntry."VAT Identifier" := CreateVATIdentifier();
        VATBookEntry."Reverse VAT Entry" := true;
        VATBookEntry."VAT Calculation Type" := VATCalculationType;
        VATBookEntry."Unrealized Amount" := LibraryRandom.RandDec(10, 2);
        VATBookEntry."Unrealized Base" := VATBookEntry."Unrealized Amount";
        VATBookEntry."Unrealized VAT Entry No." := CreateVATEntry(VATBookEntry, PostingDate);
        VATBookEntry.Insert();
    end;

    local procedure CreateVATEntry(VATBookEntry: Record "VAT Book Entry"; PostingDate: Date): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry.Type := VATBookEntry.Type;
        VATEntry."No. Series" := VATBookEntry."No. Series";
        VATEntry."Posting Date" := PostingDate;
        VATEntry."Document No." := VATBookEntry."Document No.";
        VATEntry."Bill-to/Pay-to No." := VATBookEntry."Sell-to/Buy-from No.";
        VATEntry."VAT Identifier" := VATBookEntry."VAT Identifier";
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry."VAT Calculation Type" := VATBookEntry."VAT Calculation Type";
        VATEntry."Unrealized VAT Entry No." := VATEntry."Entry No.";
        VATEntry."Unrealized Amount" := VATBookEntry."Unrealized Amount";
        VATEntry."Unrealized Base" := VATBookEntry."Unrealized Base";
        VATEntry.Insert();
        exit(VATEntry."Entry No.");
    end;

    local procedure CreateVATIdentifier(): Code[20]
    var
        VATIdentifier: Record "VAT Identifier";
    begin
        VATIdentifier.Init();
        VATIdentifier.Code := LibraryUTUtility.GetNewCode10();
        VATIdentifier.Insert();
        exit(VATIdentifier.Code);
    end;

    local procedure CreateVATRegister(): Code[10]
    var
        VATRegister: Record "VAT Register";
    begin
        VATRegister.Init();
        VATRegister.Code := LibraryUTUtility.GetNewCode10();
        VATRegister.Insert();
        exit(VATRegister.Code);
    end;

    local procedure CreateCustomer(CountryRegionCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountryRegionCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(CountryRegionCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CountryRegionCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        exit(CountryRegion.Code);
    end;

    local procedure SetCountryRegionCode(var Vendor: Record Vendor; CountryRegionCode: Code[10])
    begin
        Vendor.Validate("Country/Region Code", CountryRegionCode);
        Vendor.Modify(true);
    end;

    local procedure SetGLLastGJPrintingDate(StartDate: Date) GLLastGJPrintingDatePrevValue: Date
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLLastGJPrintingDatePrevValue := GLSetup."Last Gen. Jour. Printing Date";
        GLSetup."Last Gen. Jour. Printing Date" := StartDate - 1;
        GLSetup.Modify();
        exit(GLLastGJPrintingDatePrevValue);
    end;

    local procedure VerifyGLBookEntryFinalPrint(StartDate: Date; EndDate: Date; LastGenJnlNo: Integer)
    var
        GLBookEntry: Record "GL Book Entry";
        ProgressiveNo: Integer;
    begin
        // Verify Progressive No.
        GLBookEntry.SetCurrentKey("Official Date");
        GLBookEntry.SetRange("Official Date", StartDate, ClosingDate(EndDate));
        GLBookEntry.FindSet();

        if not IsNewFiscalYear(StartDate) then
            ProgressiveNo := LastGenJnlNo;

        repeat
            ProgressiveNo += 1;
            GLBookEntry.TestField("Progressive No.", ProgressiveNo);
        until GLBookEntry.Next() = 0;
    end;

    local procedure VerifyGLBookEntryTestPrint(StartDate: Date; EndDate: Date)
    var
        GLBookEntry: Record "GL Book Entry";
    begin
        // Verify Progressive No.
        GLBookEntry.SetCurrentKey("Official Date");
        GLBookEntry.SetRange("Official Date", StartDate, ClosingDate(EndDate));
        GLBookEntry.SetFilter("Progressive No.", '>0');
        Assert.IsTrue(GLBookEntry.IsEmpty, EntriesHaveBeenMarkedMsg);
    end;

    local procedure VerifyGLBookReprintInfo(StartDate: Date; EndDate: Date; LastPageNumber: Integer)
    var
        ReprintInfoFiscalReports: Record "Reprint Info Fiscal Reports";
        FirstPageNumber: Integer;
    begin
        ReprintInfoFiscalReports.Get(ReprintInfoFiscalReports.Report::"G/L Book - Print", StartDate, EndDate);
        FirstPageNumber := 1;
        if not IsNewFiscalYear(StartDate) then
            FirstPageNumber += LastPageNumber;
        ReprintInfoFiscalReports.TestField("First Page Number", FirstPageNumber);
    end;

    local procedure VerifyGLSetup(LastGenJnlPrintingDate: Date; LastGenJnlNo: Integer)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.TestField("Last Gen. Jour. Printing Date", LastGenJnlPrintingDate);
        GLSetup.TestField("Last General Journal No.", LastGenJnlNo);
    end;

    local procedure VerifyPageNumbering(StartingCalendarYear: Integer; FirstPageNo: Integer; PrintCompanyInformation: Boolean)
    var
        PageCount: Integer;
        I: Integer;
        PageNumberText: Text[20];
        FirstPageToVerify: Integer;
    begin
        FirstPageToVerify := 1;
        if PrintCompanyInformation then  // If Company Information should be printed - page with it should not have a number
            FirstPageToVerify := 2;
        PageCount := LibraryReportValidation.CountWorksheets();
        for I := FirstPageToVerify to PageCount do begin
            PageNumberText := StrSubstNo(PageNumberingLbl, StartingCalendarYear, FirstPageNo + I - FirstPageToVerify);
            Assert.IsTrue(LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(I, PageNumberText), PageNumberingErr);
        end;
    end;

    local procedure VerifyPageNumberingVATRegisterGrouped(FirstPageNo: Integer; PrintCompanyInformation: Boolean)
    var
        PageCount: Integer;
        I: Integer;
        PageNumberText: Text[20];
        FirstPageToVerify: Integer;
    begin
        FirstPageToVerify := 1;
        if PrintCompanyInformation then  // If Company Information should be printed - page with it should not have a number
            FirstPageToVerify := 2;
        PageCount := LibraryReportValidation.CountWorksheets();
        for I := FirstPageToVerify to PageCount do begin
            PageNumberText := StrSubstNo(PageNumberLbl, FirstPageNo + I - FirstPageToVerify);
            Assert.IsTrue(LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(I, PageNumberText), PageNumberingErr);
        end;
    end;

    local procedure VerifyReprintInfoVATRegister(ActualStartDate: Date; ActualEndDate: Date; VATRegisterCode: Code[10]; FinalPrint: Boolean)
    var
        ReprintInfoFiscalReports: Record "Reprint Info Fiscal Reports";
    begin
        ReprintInfoFiscalReports.SetRange(Report, ReprintInfoFiscalReports.Report::"VAT Register - Print");
        ReprintInfoFiscalReports.SetRange("Start Date", ActualStartDate);
        ReprintInfoFiscalReports.SetRange("End Date", ActualEndDate);
        ReprintInfoFiscalReports.SetFilter("Vat Register Code", VATRegisterCode);
        if FinalPrint then
            Assert.IsTrue(ReprintInfoFiscalReports.FindFirst(), ReprintInfoErr)
        else
            Assert.IsFalse(ReprintInfoFiscalReports.FindFirst(), ReprintInfoErr)
    end;

    local procedure VerifyVATBookEntries(ActualStartDate: Date; ActualEndDate: Date; VATRegisterCode: Code[10]; FinalPrint: Boolean)
    var
        VATBookEntry: Record "VAT Book Entry";
    begin
        VATBookEntry.SetRange("Posting Date", ActualStartDate, ActualEndDate);
        VATBookEntry.CalcFields("No. Series");
        VATBookEntry.SetRange("No. Series", GetNoSeries(VATRegisterCode));
        VATBookEntry.SetFilter(Type, '<>%1', VATBookEntry.Type::Settlement);
        VATBookEntry.FindSet();
        repeat
            if FinalPrint then
                VATBookEntry.TestField("Printing Date", Today)
            else
                VATBookEntry.TestField("Printing Date", 0D)
        until VATBookEntry.Next() = 0;
    end;

    local procedure VerifyPageNumberOnWorksheet(ExpectedPageNumber: Integer; Year: Integer; RowNo: Integer; ColumnNo: Integer; WorksheetNo: Integer)
    var
        ExpectedPageText: Text;
        ActualPageText: Text;
    begin
        ExpectedPageText := StrSubstNo(PageNumberingLbl, Year, ExpectedPageNumber);
        ActualPageText := LibraryReportValidation.GetValueAtFromWorksheet(RowNo, ColumnNo, Format(WorksheetNo));
        Assert.AreEqual(ExpectedPageText, ActualPageText, 'Wrong page number on worksheet ' + Format(WorksheetNo));
    end;

    local procedure UpdateLastPageNo()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Last Printed G/L Book Page" += LibraryRandom.RandInt(10); // User is supposed to update the field manually.
        GLSetup.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(IsEqual(Question, ConfirmFinalPrintMsg), FinalPrintMessageErr);
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(IsEqual(Question, ConfirmFinalPrintMsg), FinalPrintMessageErr);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrueTwice(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(IsEqual(Question, ConfirmReprintMsg) or IsEqual(Question, ConfirmFinalPrintMsg), FinalPrintMessageErr);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure FinalPrintMessageHandler(Message: Text[1024])
    var
        VATRegister: Record "VAT Register";
    begin
        Assert.IsTrue(
          IsEqual(
            Message, StrSubstNo(SetManuallyMsg, VATRegister.FieldCaption("Last Printed VAT Register Page"), VATRegister.TableCaption())),
          FinalPrintMessageErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmCorrectPrintHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(IsEqual(Question, ExpectedMessage), MessageNotFoundErr);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(IsEqual(Message, Format(ExpectedMessage)), MessageNotFoundErr);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerStub(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLBookPrintReqHandler(var GLBookPrint: TestRequestPage "G/L Book - Print")
    var
        ExpectedMessage: Variant;
        StartDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        asserterror GLBookPrint.StartingDate.SetValue(StartDate);
        Assert.ExpectedError(ExpectedMessage);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATRegisterGroupedRequestPageHandler(var VATRegisterGrouped: TestRequestPage "VAT Register Grouped")
    var
        PeriodStartingDate: Variant;
        PeriodEndingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PeriodStartingDate);
        LibraryVariableStorage.Dequeue(PeriodEndingDate);
        VATRegisterGrouped.PeriodStartingDate.SetValue(Format(PeriodStartingDate));
        VATRegisterGrouped.PeriodEndingDate.SetValue(Format(PeriodEndingDate));
        VATRegisterGrouped.PrintCompanyInformations.SetValue(true);
        LibraryReportValidation.SetFileName(Format(PeriodStartingDate, 0, 2));
        VATRegisterGrouped.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATRegisterReportPrintHandler(var VATRegisterPrint: TestRequestPage "VAT Register - Print")
    var
        ReportType: Variant;
        StartDate: Variant;
        EndDate: Variant;
        PrintCompanyInfo: Variant;
        VATRegisterCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(ReportType);
        LibraryVariableStorage.Dequeue(VATRegisterCode);
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        LibraryVariableStorage.Dequeue(PrintCompanyInfo);
        VATRegisterPrint.VATRegister.SetValue(VATRegisterCode);
        VATRegisterPrint.PrintingType.SetValue(ReportType);
        VATRegisterPrint.PeriodStartingDate.SetValue(StartDate);
        VATRegisterPrint.PeriodEndingDate.SetValue(EndDate);
        VATRegisterPrint.PrintCompanyInformations.SetValue(PrintCompanyInfo);

        VATRegisterPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    procedure PostingDateConfim(Que: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    procedure CancelEntriesRequestPage(var CancelEntries: TestRequestPage "Cancel FA Entries")
    begin
        CancelEntries.OK().Invoke();
    end;

    [MessageHandler]
    procedure CancelFaEntryMessageHandler(Message: Text)
    begin
    end;

    [RequestPageHandler]
    procedure GLBookRequestPage(var GLBookPrint: TestRequestPage "G/L Book - Print")
    var
        StartDate: Variant;
        EndDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        GLBookPrint.StartingDate.SetValue(Format(StartDate));
        GLBookPrint.EndingDate.SetValue(Format(EndDate));
        GLBookPrint.PrintCompanyInformations.SetValue(true);
        GLBookPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

