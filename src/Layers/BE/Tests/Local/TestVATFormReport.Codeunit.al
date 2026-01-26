codeunit 144021 "Test VAT - Form Report"
{
    // // [FEATURE] [VAT - Form] [Report]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryBEHelper: Codeunit "Library - BE Helper";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryXMLRead: Codeunit "Library - XML Read";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        MessageWhenValidationErr: Label 'Validation error';

    [Test]
    [HandlerFunctions('VATFormRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ManualVATCorrectionInVATFormReport()
    var
        IncludeVATEntries: Option Open,Closed,OpenAndClosed;
        Prepayment: Option PrintPrepmt,PrintZero,LeaveEmpty;
        StartDate: Date;
        xmlFileName: Text[1024];
        Period: Option Month,Quarter;
        CorrectionAmount: Decimal;
    begin
        // [FEATURE] MANVATCORR
        // [SCENARIO REP.030] VAT Correction Amount in 'Form/Intervat Declaration'
        Initialize();
        // [GIVEN] VAT Statement Line Row '01' has Amount = 0
        StartDate := CalcDate('<1Y>', WorkDate());
        // [GIVEN] Added Manual VAT Correction. Amount = X
        CorrectionAmount := AddManVATCorrection('01', StartDate);

        // [WHEN] Export to XML by Report 11307 VAT - Form
        xmlFileName := LibraryReportDataset.GetFileName();
        OpenVATFormRep(
          Period::Month, Date2DMY(StartDate, 2), Date2DMY(StartDate, 3), IncludeVATEntries::Open,
          Prepayment::LeaveEmpty, false, false, false, false, xmlFileName, false, 0);

        // [THEN] Reported Row A has Amount = X
        LibraryXMLRead.Initialize(xmlFileName);
        LibraryXMLRead.VerifyNodeValue('Amount', CorrectionAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATFormRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProcessVATFormReportInTransactionMonthAndValidate()
    var
        Period: Option Month,Quarter;
    begin
        ProcessVATFormReportAndValidate(Period::Month, 1, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATFormRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProcessVATFormReportOutsideTransactionMonthAndValidate()
    var
        Period: Option Month,Quarter;
    begin
        ProcessVATFormReportAndValidate(Period::Month, 10, false);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATFormRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProcessVATFormReportInTransactionQuarterAndValidate()
    var
        Period: Option Month,Quarter;
    begin
        ProcessVATFormReportAndValidate(Period::Quarter, 1, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATFormRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProcessVATFormReportOutsideTransactionQuarterAndValidate()
    var
        Period: Option Month,Quarter;
    begin
        ProcessVATFormReportAndValidate(Period::Quarter, 4, false);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATFormRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyErrorOnEmptyRepFieldValue()
    var
        Period: Option Month,Quarter;
        IncludeVATEntries: Option Open,Closed,OpenAndClosed;
        Prepayment: Option PrintPrepmt,PrintZero,LeaveEmpty;
        xmlFileName: Text[1024];
        StartDate: Date;
    begin
        // Setup.
        Initialize();
        StartDate := CalcDate('<+CY+1D>', WorkDate());
        xmlFileName := LibraryReportDataset.GetFileName();

        // Exercise.
        asserterror OpenVATFormRep(Period::Month, 1, Date2DMY(StartDate, 3), IncludeVATEntries::Open,
            Prepayment::LeaveEmpty, false, false, false, true, xmlFileName, false, 0);

        Assert.AssertRecordNotFound();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATFormRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyErrorOnInvalidMonthPeriod()
    var
        Period: Option Month,Quarter;
        IncludeVATEntries: Option Open,Closed,OpenAndClosed;
        Prepayment: Option PrintPrepmt,PrintZero,LeaveEmpty;
        xmlFileName: Text[1024];
        StartDate: Date;
    begin
        // Setup.
        Initialize();
        StartDate := CalcDate('<+CY+1D>', WorkDate());
        xmlFileName := LibraryReportDataset.GetFileName();

        // Exercise.
        asserterror OpenVATFormRep(Period::Month, 13, Date2DMY(StartDate, 3), IncludeVATEntries::Open,
            Prepayment::LeaveEmpty, false, false, false, true, xmlFileName, false, 0);

        Assert.ExpectedError(MessageWhenValidationErr);
    end;

    [Test]
    [HandlerFunctions('VATFormRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyErrorOnInvalidQuarterPeriod()
    var
        Period: Option Month,Quarter;
        IncludeVATEntries: Option Open,Closed,OpenAndClosed;
        Prepayment: Option PrintPrepmt,PrintZero,LeaveEmpty;
        xmlFileName: Text[1024];
        StartDate: Date;
    begin
        // Setup.
        Initialize();
        StartDate := CalcDate('<+CY+1D>', WorkDate());
        xmlFileName := LibraryReportDataset.GetFileName();

        // Exercise.
        asserterror OpenVATFormRep(Period::Quarter, 5, Date2DMY(StartDate, 3), IncludeVATEntries::Open,
            Prepayment::LeaveEmpty, false, false, false, true, xmlFileName, false, 0);

        Assert.ExpectedError(MessageWhenValidationErr);
    end;

    [Test]
    [HandlerFunctions('VATFormRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportingCorrectedVATDeclarationInVATFormReport()
    var
        CompanyInformation: Record "Company Information";
        IncludeVATEntries: Option Open,Closed,OpenAndClosed;
        Prepayment: Option PrintPrepmt,PrintZero,LeaveEmpty;
        StartDate: Date;
        xmlFileName: Text[1024];
        Period: Option Month,Quarter;
        SeqNo: Integer;
        Month: Integer;
        Year: Integer;
        ExpectedReplacedVATDeclarationTok: Label '%1-%2-%3%4', Locked = true;
    begin
        // [FEATURE] [Intervat]
        // [SCENARIO 213197] If "Is Correction" is set to TRUE in "VAT - Form" Report's Request Page, then ReplacedVATDeclaration should be added to InterVAT file

        Initialize();

        // [GIVEN] In the Request Page of "VAT - Form" Report, "Is Correction" = TRUE, "Previous Sequence No." = 11, "Year" = 2023, "Month" = 1
        StartDate := CalcDate('<1Y>', WorkDate());
        xmlFileName := LibraryReportDataset.GetFileName();
        SeqNo := LibraryRandom.RandInt(9999);
        Month := Date2DMY(StartDate, 2);
        Year := Date2DMY(StartDate, 3);

        // [WHEN] Export to XML by Report 11307 VAT - Form
        OpenVATFormRep(
          Period::Month, Month, Year, IncludeVATEntries::Open,
          Prepayment::LeaveEmpty, false, false, false, false, xmlFileName, true, SeqNo);

        // [THEN] Resulting file contains <ReplacedVATDeclaration> tag, which looks like *Previous Sequence No*-*EnterpiseNo*-*Year**Month* (11-1234567-202301)
        LibraryXMLRead.Initialize(xmlFileName);
        CompanyInformation.Get();
        LibraryXMLRead.VerifyNodeValue('ReplacedVATDeclaration', StrSubstNo(ExpectedReplacedVATDeclarationTok, Format(SeqNo), RemoveNonNumericCharacters(CompanyInformation."Enterprise No."), Format(Year), Format(Month).PadLeft(2, '0'))); // TFSID: 492248

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATFormRepRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportingNonCorrectedVATDeclarationInVATFormReport()
    var
        IncludeVATEntries: Option Open,Closed,OpenAndClosed;
        Prepayment: Option PrintPrepmt,PrintZero,LeaveEmpty;
        StartDate: Date;
        xmlFileName: Text[1024];
        Period: Option Month,Quarter;
    begin
        // [FEATURE] [Intervat]
        // [SCENARIO 213197] If "Is Correction" is set to FALSE in "VAT - Form" Report's Request Page, then ReplacedVATDeclaration should not be added to InterVAT file

        Initialize();

        // [GIVEN] In the Request Page of "VAT - Form" Report, "Is Correction" = FALSE
        // [WHEN] Export to XML by Report 11307 VAT - Form
        StartDate := CalcDate('<1Y>', WorkDate());
        xmlFileName := LibraryReportDataset.GetFileName();
        OpenVATFormRep(
          Period::Month, Date2DMY(StartDate, 2), Date2DMY(StartDate, 3), IncludeVATEntries::Open,
          Prepayment::LeaveEmpty, false, false, false, false, xmlFileName, false, 0);

        // [THEN] Resulting file does not contain <ReplacedVATDeclaration> tag
        LibraryXMLRead.Initialize(xmlFileName);
        LibraryXMLRead.VerifyElementAbsenceInSubtree('VATDeclaration', 'ReplacedVATDeclaration');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATFormRepRequestPageWithCommentHandler')]
    [Scope('OnPrem')]
    procedure VATReportFormWithComment()
    var
        Customer: Record Customer;
        TempXMLBuffer: Record "XML Buffer" temporary;
        FileManagement: Codeunit "File Management";
        IncludeVATEntries: Option Open,Closed,OpenAndClosed;
        Prepayment: Option PrintPrepmt,PrintZero,LeaveEmpty;
        StartDate: Date;
        xmlFileName: Text[1024];
        Period: Option Month,Quarter;
        Comment: Text;
    begin
        // [SCENARIO 462300] Stan can add a comment to the VAT Form Report

        Initialize();
        StartDate := CalcDate('<+CY+1D>', WorkDate());

        // [GIVEN] Sales invoice with "Posting Date" = "01.01.2023"
        LibraryBEHelper.CreateCustomerItemSalesInvoiceAndPost(Customer);
        xmlFileName := LibraryReportDataset.GetFileName();

        // [GIVEN] Run VAT Form Report
        // [GIVEN] Set "Starting Date" = "01.01.2023" and "Comment" = "Y"
        Comment := LibraryUtility.GenerateGUID();
        // [WHEN] Stan clicks "OK"
        OpenVATFormRepWithComment(Period::Quarter, 1, Date2DMY(StartDate, 3), IncludeVATEntries::Open,
          Prepayment::LeaveEmpty, false, false, false, false, xmlFileName, false, 0, Comment);

        // [THEN] /VATConsignment/VATDeclaration/Declarant/common:Comment is "Y"
        TempXMLBuffer.Load(xmlFileName);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/VATConsignment/VATDeclaration/Comment');
        TempXMLBuffer.TestField(Value, Comment);
        LibraryVariableStorage.AssertEmpty();

        FileManagement.DeleteServerFile(xmlFileName);
    end;

    [Test]
    [HandlerFunctions('VATFormRepRequestPageWithCommentHandler')]
    [Scope('OnPrem')]
    procedure VATReportFormWithCommentAndIncludeOpenAndClosedVATEntries()
    var
        Customer: Record Customer;
        TempXMLBuffer: Record "XML Buffer" temporary;
        FileManagement: Codeunit "File Management";
        IncludeVATEntries: Option Open,Closed,OpenAndClosed;
        Prepayment: Option PrintPrepmt,PrintZero,LeaveEmpty;
        StartDate: Date;
        xmlFileName: Text[1024];
        Period: Option Month,Quarter;
        Comment: Text;
    begin
        // [SCENARIO 462300] Stan can add a comment to the VAT Form Report

        Initialize();
        StartDate := CalcDate('<+CY+1D>', WorkDate());

        // [GIVEN] Sales invoice with "Posting Date" = "01.01.2023"
        LibraryBEHelper.CreateCustomerItemSalesInvoiceAndPost(Customer);
        xmlFileName := LibraryReportDataset.GetFileName();

        // [GIVEN] Run VAT Form Report
        // [GIVEN] Set "Starting Date" = "01.01.2023" and "Comment" = "Y"
        Comment := LibraryUtility.GenerateGUID();
        // [WHEN] Stan clicks "OK"
        OpenVATFormRepWithComment(Period::Quarter, 1, Date2DMY(StartDate, 3), IncludeVATEntries::OpenAndClosed,
          Prepayment::LeaveEmpty, false, false, false, false, xmlFileName, false, 0, Comment);

        // [THEN] /VATConsignment/VATDeclaration/Declarant/common:Comment is "Y"
        TempXMLBuffer.Load(xmlFileName);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/VATConsignment/VATDeclaration/Comment');
        TempXMLBuffer.TestField(Value, Comment);
        LibraryVariableStorage.AssertEmpty();

        FileManagement.DeleteServerFile(xmlFileName);
    end;

    local procedure Initialize()
    var
        ManualVATCorrection: Record "Manual VAT Correction";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test VAT - Form Report");
        LibraryVariableStorage.Clear();
        ManualVATCorrection.DeleteAll();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test VAT - Form Report");

        isInitialized := true;
        LibraryBEHelper.InitializeCompanyInformation();
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test VAT - Form Report");
    end;

    local procedure AddManVATCorrection(RowNoFilter: Text; PostingDate: Date): Decimal
    var
        GLSetup: Record "General Ledger Setup";
        VATStatementLine: Record "VAT Statement Line";
        ManualVATCorrection: Record "Manual VAT Correction";
    begin
        GLSetup.Get();
        VATStatementLine.SetRange("Statement Template Name", GLSetup."VAT Statement Template Name");
        VATStatementLine.SetRange("Statement Name", GLSetup."VAT Statement Name");
        VATStatementLine.SetFilter("Row No.", RowNoFilter);
        VATStatementLine.FindSet();
        VATStatementLine.Next(LibraryRandom.RandInt(VATStatementLine.Count - 1));

        ManualVATCorrection.Init();
        ManualVATCorrection."Statement Template Name" := VATStatementLine."Statement Template Name";
        ManualVATCorrection."Statement Name" := VATStatementLine."Statement Name";
        ManualVATCorrection."Statement Line No." := VATStatementLine."Line No.";
        ManualVATCorrection."Posting Date" := PostingDate;
        ManualVATCorrection.Amount := LibraryRandom.RandDec(10000, 2);
        ManualVATCorrection.Insert();

        Commit();

        exit(ManualVATCorrection.Amount);
    end;

    [Normal]
    [HandlerFunctions('VATFormRepRequestPageHandler,MessageHandler')]
    local procedure ProcessVATFormReportAndValidate(Period: Option Month,Quarter; PeriodValue: Integer; ValidPeriod: Boolean)
    var
        Customer: Record Customer;
        VATEntry: Record "VAT Entry";
        IncludeVATEntries: Option Open,Closed,OpenAndClosed;
        Prepayment: Option PrintPrepmt,PrintZero,LeaveEmpty;
        StartDate: Date;
        xmlFileName: Text[1024];
        base: Decimal;
        amount: Decimal;
        periodnodeName: Text;
    begin
        // Setup.
        Initialize();
        StartDate := CalcDate('<+CY+1D>', WorkDate());

        // Create customer, an item and post an invoice to that customer for the item
        LibraryBEHelper.CreateCustomerItemSalesInvoiceAndPost(Customer);

        xmlFileName := LibraryReportDataset.GetFileName();

        // Exercise.
        OpenVATFormRep(Period, PeriodValue, Date2DMY(StartDate, 3), IncludeVATEntries::Open,
          Prepayment::LeaveEmpty, false, false, false, false, xmlFileName, false, 0);

        // Verify report datasaet against VATEntry table.
        VATEntry.SetFilter(Type, 'Sale');
        VATEntry.SetFilter("Document Type", 'Invoice');
        VATEntry.SetFilter("Posting Date", '> ' + Format(StartDate));

        base := 0;
        amount := 0;
        if VATEntry.Find('-') then
            repeat
                base := base + Abs(VATEntry.Base);
                amount := amount + Abs(VATEntry.Amount);
            until VATEntry.Next() = 0;

        if Period = Period::Month then
            periodnodeName := 'Month'
        else
            periodnodeName := 'Quarter';

        LibraryXMLRead.Initialize(xmlFileName);
        LibraryXMLRead.VerifyNodeValue(periodnodeName, PeriodValue);
        LibraryXMLRead.VerifyNodeValue('Year', Date2DMY(StartDate, 3));

        if ValidPeriod then begin
            LibraryXMLRead.VerifyNodeValueInSubtree('Data', 'Amount', base);
            LibraryXMLRead.VerifyNodeValueInSubtree('Data', 'Amount', amount);
            LibraryXMLRead.VerifyNodeValue('ClientListingNihil', 'NO');
        end else begin
            asserterror LibraryXMLRead.VerifyNodeValueInSubtree('Data', 'Amount', base);
            asserterror LibraryXMLRead.VerifyNodeValueInSubtree('Data', 'Amount', amount)
        end;
    end;

    local procedure OpenVATFormRep(DeclarationType: Option Month,Quarter; MonthOrQuarter: Integer; Year: Integer; IncludeVATEntries: Option Open,Closed,OpenAndClosed; Prepayment: Option PrintPrepmt,PrintZero,LeaveEmpty; ClaimForReimbursement: Boolean; OrderPaymentForms: Boolean; NoAnnualListing: Boolean; AddRepresentative: Boolean; FileName: Text[1024]; IsCorrection: Boolean; SequenceNo: Integer)
    var
        VATForm: Report "VAT - Form";
    begin
        EnqueueBasicDataToReport(
          DeclarationType, MonthOrQuarter, Year, IncludeVATEntries, Prepayment, ClaimForReimbursement,
          OrderPaymentForms, NoAnnualListing, AddRepresentative, IsCorrection, SequenceNo);
        Commit();

        VATForm.SetFileName(FileName);
        VATForm.Run();
    end;

    local procedure OpenVATFormRepWithComment(DeclarationType: Option Month,Quarter; MonthOrQuarter: Integer; Year: Integer; IncludeVATEntries: Option Open,Closed,OpenAndClosed; Prepayment: Option PrintPrepmt,PrintZero,LeaveEmpty; ClaimForReimbursement: Boolean; OrderPaymentForms: Boolean; NoAnnualListing: Boolean; AddRepresentative: Boolean; FileName: Text[1024]; IsCorrection: Boolean; SequenceNo: Integer; Comment: Text)
    var
        VATForm: Report "VAT - Form";
    begin
        EnqueueBasicDataToReport(
          DeclarationType, MonthOrQuarter, Year, IncludeVATEntries, Prepayment, ClaimForReimbursement,
          OrderPaymentForms, NoAnnualListing, AddRepresentative, IsCorrection, SequenceNo);
        LibraryVariableStorage.Enqueue(Comment);
        Commit();

        VATForm.SetFileName(FileName);
        VATForm.Run();
    end;

    local procedure EnqueueBasicDataToReport(DeclarationType: Option Month,Quarter; MonthOrQuarter: Integer; Year: Integer; IncludeVATEntries: Option Open,Closed,OpenAndClosed; Prepayment: Option PrintPrepmt,PrintZero,LeaveEmpty; ClaimForReimbursement: Boolean; OrderPaymentForms: Boolean; NoAnnualListing: Boolean; AddRepresentative: Boolean; IsCorrection: Boolean; SequenceNo: Integer)
    begin
        LibraryVariableStorage.Enqueue(MonthOrQuarter);
        LibraryVariableStorage.Enqueue(DeclarationType);
        LibraryVariableStorage.Enqueue(Year);
        LibraryVariableStorage.Enqueue(IncludeVATEntries);
        LibraryVariableStorage.Enqueue(Prepayment);
        LibraryVariableStorage.Enqueue(ClaimForReimbursement);
        LibraryVariableStorage.Enqueue(OrderPaymentForms);
        LibraryVariableStorage.Enqueue(NoAnnualListing);
        LibraryVariableStorage.Enqueue(AddRepresentative);
        LibraryVariableStorage.Enqueue(IsCorrection);
        LibraryVariableStorage.Enqueue(SequenceNo);
    end;

    local procedure RemoveNonNumericCharacters(InputString: Text[250]): Text[30]
    begin
        exit(DelChr(InputString, '=', DelChr(InputString, '=', '0123456789')));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATFormRepRequestPageHandler(var VATForm: TestRequestPage "VAT - Form")
    begin
        VATFormRepCustRequestPageHandler(VATForm);

        VATForm.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATFormRepRequestPageWithCommentHandler(var VATForm: TestRequestPage "VAT - Form")
    begin
        VATFormRepCustRequestPageHandler(VATForm);
        VATForm.CommentControl.SetValue(LibraryVariableStorage.DequeueText());
        VATForm.OK().Invoke();
    end;

    local procedure VATFormRepCustRequestPageHandler(var VATForm: TestRequestPage "VAT - Form")
    var
        DequeuedVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATForm.Vperiod.SetValue(DequeuedVar); // Declaration Type

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATForm.ChoicePeriodType.SetValue(DequeuedVar); // Month Or Quarter

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATForm.Vyear.SetValue(DequeuedVar); // Year

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATForm.IncludeVatEntries.SetValue(DequeuedVar); // Include VAT Entries

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATForm.PrintPrepayment.SetValue(DequeuedVar); // Prepayment

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATForm.Reimbursement.SetValue(DequeuedVar); // Claim for reimbursement

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATForm.PaymForms.SetValue(DequeuedVar); // Order payment form

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATForm.Annuallist.SetValue(DequeuedVar); // No Annual Listing

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATForm.AddRepresentative.SetValue(DequeuedVar); // Add Rep.

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATForm.IsCorrectionControl.SetValue(DequeuedVar);

        LibraryVariableStorage.Dequeue(DequeuedVar);
        VATForm.PrevSequenceNoControl.SetValue(DequeuedVar);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

