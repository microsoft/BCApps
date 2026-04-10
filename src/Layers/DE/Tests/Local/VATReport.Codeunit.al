codeunit 144001 "VAT Report"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Report] [VIES ELMA XML]
    end;

    var
        VATReportMediator: Codeunit "VAT Report Mediator";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        VariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        Assert: Codeunit Assert;
        IncorrectNoOfReportLinesErr: Label 'The number of report lines is incorrect.';
        IncorrectVATReportLineAmtErr: Label 'The amount in the VAT Report line is incorrect.';
        ReportNotSubmittedErr: Label 'VAT report was not submitted.';
        OriginalAmtMustBeZeroErr: Label 'Original amount must be 0 in corrective report.';
        IncorrectCorrectionAmtErr: Label 'Amount must be equal to %1 in corrective line.', Comment = '%1 = expected amount';
        LineCannotBeChangedErr: Label 'Cancellation line cannot be changed';
        NewValueIsNotSetErr: Label 'Amount in correction line must be editable.';
        IncorrectAmtInSecondCorrErr: Label 'Amount in the second correction must be initialized with the first correction amount.';
        ReportLineRelationNotFoundErr: Label 'VAT Report Line Relation does not exist.';
        NonEUCountryInReportErr: Label 'VAT entry for non-EU country must not be included in report.';
        CorrLinesNotCreatedErr: Label 'Correction lines were not created.';
        ReportLineMustBeDeletedErr: Label 'VAT Report Line must be deleted.';
        ReportingPeriodNotTransferredErr: Label 'Reporing period data must be transferred into corrective report from the original report.';
        ReportPeriodValidatedIncorrectlyErr: Label 'VAT report period validated incorrectly.';
        FieldMustBeFilledErr: Label 'Field %1 should be filled in table %2.', Comment = '%1 = field name, %2 = table name';
        IncorectMsgInErrorLogErr: Label 'Incorrect error message in error log.';
        IncorrectVATEntriesListErr: Label 'Detailed vat entries list is displayed incorrectly.';
        ErrorLogMustBeEmptyErr: Label 'No errors must be logged.';
        OddNoOfCorrLinesErr: Label 'Each cancellation line should have related corrective line.';
        CorrectionEntryAlreadyExistsErr: Label 'A correction entry already exists for this entry in report';
        InvalidCompanyNameTok: Label 'Name - Labé';
        InvalidCompanyAddressTok: Label 'Address - Labé';
        InvalidCompanyCityTok: Label 'City - Labé';
        ValidCompanyNameTok: Label 'Name - Labe';
        ValidCompanyAddressTok: Label 'Address - Labe';
        ValidCompanyCityTok: Label 'City - Labe';
        KeyAlreadyExistsErr: Label 'When you run the Suggest Lines action, it will add a VAT Report line for VAT Reg. No', Comment = 'A line of type = Correction already exists in the VAT Report. Remove the line to continue. Filters: VAT Registration No. = 12345';
        UnacceptableValueErr: Label 'Your entry of ''%1'' is not an acceptable value for ''%2''', Comment = '%1 = field value, %2 = field caption';
        VIESELMAFileNamePatternTxt: Label 'ZMDO.%1.%2.xml', Locked = true, Comment = '%1 = BOP User Account ID, %2 = FileID (UUID)';
        FileNamePatternMismatchErr: Label 'File name should match pattern %1*.xml, actual: %2', Comment = '%1 = expected file name pattern, %2 = actual file name';
        BOPUserAccountIDLengthErr: Label 'The BOP User Account ID must be exactly 10 digits.';
        BOPUserAccountIDMissingErr: Label 'The BOP User Account ID must be specified in the VAT Report Setup before generating the ELMA XML file.';
        IsInitialized: Boolean;

    [Test]
    procedure SetReportPeriodTypeMonth_VerifyPeriodValidated()
    var
        PeriodNo: Integer;
        PeriodType: Option ,Month,Quarter,Year,"Bi-Monthly";
    begin
        Initialize();
        PeriodNo := LibraryRandom.RandInt(12);
        SetVATReportPeriodTypeVerifyDate(PeriodType::Month, PeriodNo);
    end;

    [Test]
    procedure SetReportPeriodTypeQuarter_VerifyPeriodValidated()
    var
        PeriodNo: Integer;
        PeriodType: Option ,Month,Quarter,Year,"Bi-Monthly";
    begin
        Initialize();
        PeriodNo := LibraryRandom.RandInt(4);
        SetVATReportPeriodTypeVerifyDate(PeriodType::Quarter, PeriodNo);
    end;

    [Test]
    procedure SetReportPeriodTypeYear_VerifyPeriodValidated()
    var
        PeriodType: Option ,Month,Quarter,Year,"Bi-Monthly";
    begin
        Initialize();
        SetVATReportPeriodTypeVerifyDate(PeriodType::Year, 1);
    end;

    [Test]
    procedure SetReportPeriodTypeBiMonthly_VerifyPeriodValidated()
    var
        PeriodNo: Integer;
        PeriodType: Option ,Month,Quarter,Year,"Bi-Monthly";
    begin
        Initialize();
        PeriodNo := LibraryRandom.RandInt(4);
        SetVATReportPeriodTypeVerifyDate(PeriodType::"Bi-Monthly", PeriodNo);
    end;

    [Test]
    [HandlerFunctions('VATReportErrorLogHandler')]
    procedure SetEmptyStartDate_VerifyErrorLogged()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPart: Option Header,Line;
    begin
        Initialize();
        SetIncorrectFieldValue_ValidateReport(VATReportPart::Header, VATReportHeader.FieldNo("Start Date"), 0D);
    end;

    [Test]
    [HandlerFunctions('VATReportErrorLogHandler')]
    procedure SetEmptyEndDate_VerifyErrorLogged()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPart: Option Header,Line;
    begin
        Initialize();
        SetIncorrectFieldValue_ValidateReport(VATReportPart::Header, VATReportHeader.FieldNo("End Date"), 0D);
    end;

    [Test]
    [HandlerFunctions('VATReportErrorLogHandler')]
    procedure SetEmptyProcessingDate_VerifyErrorLogged()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPart: Option Header,Line;
    begin
        Initialize();
        SetIncorrectFieldValue_ValidateReport(VATReportPart::Header, VATReportHeader.FieldNo("Processing Date"), 0D);
    end;

    [Test]
    [HandlerFunctions('VATReportErrorLogHandler')]
    procedure SetEmptyPeriodType_VerifyErrorLogged()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPart: Option Header,Line;
    begin
        Initialize();
        SetIncorrectFieldValue_ValidateReport(VATReportPart::Header, VATReportHeader.FieldNo("Report Period Type"), VATReportHeader."Report Period Type"::" ");
    end;

    [Test]
    [HandlerFunctions('VATReportErrorLogHandler')]
    procedure SetEmptyPeriodNo_VerifyErrorLogged()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPart: Option Header,Line;
    begin
        Initialize();
        SetIncorrectFieldValue_ValidateReport(VATReportPart::Header, VATReportHeader.FieldNo("Report Period No."), 0);
    end;

    [Test]
    [HandlerFunctions('VATReportErrorLogHandler')]
    procedure SetEmptyReportYear_VerifyErrorLogged()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPart: Option Header,Line;
    begin
        Initialize();
        SetIncorrectFieldValue_ValidateReport(VATReportPart::Header, VATReportHeader.FieldNo("Report Year"), 0);
    end;

    [Test]
    [HandlerFunctions('VATReportErrorLogHandler')]
    procedure SetEmptyCompanyName_VerifyErrorLogged()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPart: Option Header,Line;
    begin
        Initialize();
        SetIncorrectFieldValue_ValidateReport(VATReportPart::Header, VATReportHeader.FieldNo("Company Name"), '');
    end;

    [Test]
    [HandlerFunctions('VATReportErrorLogHandler')]
    procedure SetEmptyCompanyAddress_VerifyErrorLogged()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPart: Option Header,Line;
    begin
        Initialize();
        SetIncorrectFieldValue_ValidateReport(VATReportPart::Header, VATReportHeader.FieldNo("Company Address"), '');
    end;

    [Test]
    [HandlerFunctions('VATReportErrorLogHandler')]
    procedure SetEmptyPostCode_VerifyErrorLogged()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPart: Option Header,Line;
    begin
        Initialize();
        SetIncorrectFieldValue_ValidateReport(VATReportPart::Header, VATReportHeader.FieldNo("Post Code"), '');
    end;

    [Test]
    [HandlerFunctions('VATReportErrorLogHandler')]
    procedure SetEmptyCity_VerifyErrorLogged()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPart: Option Header,Line;
    begin
        Initialize();
        SetIncorrectFieldValue_ValidateReport(VATReportPart::Header, VATReportHeader.FieldNo(City), '');
    end;

    [Test]
    [HandlerFunctions('VATReportErrorLogHandler')]
    procedure SetEmptyVATRegNo_VerifyErrorLogged()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPart: Option Header,Line;
    begin
        Initialize();
        SetIncorrectFieldValue_ValidateReport(VATReportPart::Header, VATReportHeader.FieldNo("VAT Registration No."), '');
    end;

    [Test]
    [HandlerFunctions('VATReportErrorLogHandler')]
    procedure SetEmptyVATRegNoInLine_VerifyErrorLogged()
    var
        VATReportLine: Record "VAT Report Line";
        VATReportPart: Option Header,Line;
    begin
        Initialize();
        SetIncorrectFieldValue_ValidateReport(VATReportPart::Line, VATReportLine.FieldNo("VAT Registration No."), '');
    end;

    [Test]
    procedure ChangeReportTypeWithLines()
    var
        VATReportHeader: Record "VAT Report Header";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [SCENARIO 105793] User can't change the report type when lines exists
        Initialize();

        // [GIVEN] A VAT Report is created
        // [GIVEN] Lines have been suggested
        SetupVATReportScenarioOpen(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        // [WHEN] The Report type on the header is changed to Correction
        asserterror VATReportHeader.Validate("VAT Report Type", VATReportHeader."VAT Report Type"::Corrective);

        // [THEN] An error is thrown because lines are present
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ChangeOriginalReportNoWithLines()
    var
        VATReportHeaderB: Record "VAT Report Header";
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [SCENARIO 105793] User can't change the Original Report No. in the header when VAT Report lines is present
        Initialize();

        // [GIVEN] A standard report have been submitted for period A
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        FindLastReportLine(VATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);

        // [GIVEN] A standard report have been submitted for period B
        CreateVATEntries(
          1, CalcDate('<+2M>', TestPeriodStart), CalcDate('<+2M>', TestPeriodEnd), '', VATReportLine."VAT Registration No.", true);
        CreateAndReleaseVATReport(VATReportHeaderB, CalcDate('<+2M>', TestPeriodStart));
        SubmitVATReport(VATReportHeaderB);

        // [GIVEN] A new document is posted for the period A
        CreateVATEntries(1, TestPeriodStart, TestPeriodEnd, '', VATReportLine."VAT Registration No.", true);

        // [GIVEN] A correction report is created for same period
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);

        // [GIVEN] The new document is suggested
        SuggestVATReportLines(CorrVATReportHeader."No.");

        // [GIVEN] Minimum one entry exists
        VATReportLine.SetRange("VAT Report No.", CorrVATReportHeader."No.");
        Assert.AreNotEqual(0, VATReportLine.Count, IncorrectNoOfReportLinesErr);

        // [WHEN] The original report no is changed
        asserterror CorrVATReportHeader.Validate("Original Report No.", VATReportHeaderB."No.");

        // [THEN] An error is thrown because lines are present
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('VATReportErrorLogHandler')]
    procedure SetEmptyCountryCodeInLine_VerifyErrorLogged()
    var
        VATReportLine: Record "VAT Report Line";
        VATReportPart: Option Header,Line;
    begin
        Initialize();
        SetIncorrectFieldValue_ValidateReport(VATReportPart::Line, VATReportLine.FieldNo("Country/Region Code"), '');
    end;

    [Test]
    procedure SetZeroAmountInLine_VerifyValidationSuccessful()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportErrorLog: Record "VAT Report Error Log";
        VATReportPart: Option Header,Line;
    begin
        Initialize();
        VATReportHeader.Get(CreateMockVATReport_SetFieldValue(VATReportPart::Line, VATReportLine.FieldNo(Base), 0));
        CODEUNIT.Run(CODEUNIT::"VAT Report Validate", VATReportHeader);
        Assert.IsTrue(VATReportErrorLog.IsEmpty, ErrorLogMustBeEmptyErr);
    end;

    [Test]
    procedure DeleteReport_VerifyLinesDeleted()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportNo: Code[20];
    begin
        Initialize();
        CreateStandardMonthReport(VATReportHeader);
        VATReportNo := VATReportHeader."No.";
        VATReportHeader.Delete(true);

        VATReportLine.SetRange("VAT Report No.", VATReportNo);
        Assert.IsTrue(VATReportLine.IsEmpty, ReportLineMustBeDeletedErr);
    end;

    [Test]
    procedure DeleteVATReportLine_VerifyRelationLinesDeleted()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        Initialize();
        CreateStandardMonthReport(VATReportHeader);

        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.DeleteAll(true);

        VATReportLineRelation.SetRange("VAT Report No.", VATReportHeader."No.");
        Assert.IsTrue(VATReportLineRelation.IsEmpty, ReportLineMustBeDeletedErr);
    end;

    [Test]
    procedure SuggestLines_VerifyDateFiltering()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        SetupVATReportScenario(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATEntry.SetRange("VAT Reporting Date", TestPeriodStart, TestPeriodEnd);

        Assert.AreEqual(VATEntry.Count, VATReportLine.Count, IncorrectNoOfReportLinesErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure SuggestLines_StandardReport_VerifyCountryGrouping()
    var
        VATReportLine: Record "VAT Report Line";
    begin
        Initialize();
        SuggestLines_StandardReport_VerifyFieldGrouping(VATReportLine.FieldNo("Country/Region Code"));
    end;

    [Test]
    procedure SuggestLines_StandardReport_VerifyVATRegNoGrouping()
    var
        VATReportLine: Record "VAT Report Line";
    begin
        Initialize();
        SuggestLines_StandardReport_VerifyFieldGrouping(VATReportLine.FieldNo("VAT Registration No."));
    end;

    [Test]
    procedure SuggestLines_StandardReport_VerifyEU3PartyTradeGrouping()
    var
        VATReportLine: Record "VAT Report Line";
    begin
        Initialize();
        SuggestLines_StandardReport_VerifyFieldGrouping(VATReportLine.FieldNo("EU 3-Party Trade"));
    end;

    [Test]
    procedure SuggestLines_StandardReport_VerifyLineRelation()
    var
        VATReportHeader: Record "VAT Report Header";
        CountryCode: Code[10];
        VATRegNo: Text[20];
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CountryCode := CreateCountryRegion();
        VATRegNo := LibraryUtility.GenerateGUID();

        FindFirstMonthWithoutVATEntries(TestPeriodStart, TestPeriodEnd);
        CreateVATEntries(5, TestPeriodStart, TestPeriodEnd, CountryCode, VATRegNo, false);
        CreateVATReport(
              VATReportHeader."VAT Report Type"::Standard,
              VATReportHeader."Report Period Type"::Month,
              Date2DMY(TestPeriodStart, 2),
              Date2DMY(TestPeriodStart, 3),
              VATReportHeader);

        VerifyReportRelationLineExistsForEachVATEntry(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd, VATRegNo, CountryCode);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure SuggestLines_StandardReport_VerifyNonEUCountryNotIncluded()
    var
        CountryRegion: Record "Country/Region";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        // Creating non-EU country
        LibraryERM.CreateCountryRegion(CountryRegion);

        FindFirstMonthWithoutVATEntries(TestPeriodStart, TestPeriodEnd);

        CreateVATEntries(1, TestPeriodStart, TestPeriodEnd, CountryRegion.Code, '', false);
        CreateVATReport(
              VATReportHeader."VAT Report Type"::Standard,
              VATReportHeader."Report Period Type"::Month,
              Date2DMY(TestPeriodStart, 2),
              Date2DMY(TestPeriodStart, 3),
              VATReportHeader);

        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        Assert.AreEqual(0, VATReportLine.Count, NonEUCountryInReportErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure CompanyNameAdressCity()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        Initialize();
        UpdateCompanyInformation(InvalidCompanyNameTok, InvalidCompanyAddressTok, InvalidCompanyCityTok);
        UpdateVATReportSetup(ValidCompanyNameTok, ValidCompanyAddressTok, ValidCompanyCityTok);

        VATReportHeader.Init();
        VATReportHeader.Insert(true);

        VerifyVATReportHeaderCompanyInformation(VATReportHeader);
    end;

    [Test]
    procedure VerifyOpenReportCannotBeSubmitted()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        Initialize();
        CreateStandardMonthReport(VATReportHeader);

        asserterror VATReportMediator.Submit(VATReportHeader);
        Assert.ExpectedTestFieldError(VATReportHeader.FieldCaption(Status), Format(VATReportHeader.Status::Exported));
    end;

    [Test]
    procedure VerifyReleasedReportCannotBeSubmitted()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        Initialize();
        CreateStandardMonthReport(VATReportHeader);
        VATReportMediator.Release(VATReportHeader);

        asserterror VATReportMediator.Submit(VATReportHeader);
        Assert.ExpectedTestFieldError(VATReportHeader.FieldCaption(Status), Format(VATReportHeader.Status::Exported));
    end;

    [Test]
    procedure VerifyExportedReportCanBeSubmitted()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        Initialize();
        CreateStandardMonthReport(VATReportHeader);
        MockVATReportExport(VATReportHeader);

        VATReportMediator.Submit(VATReportHeader);
        VATReportHeader.Get(VATReportHeader."No.");
        Assert.AreEqual(Format(VATReportHeader.Status::Submitted), Format(VATReportHeader.Status), ReportNotSubmittedErr);
    end;

    [Test]
    [HandlerFunctions('VATReportsLookupHandler')]
    procedure SetOriginalReportNo_VerifyReportValidated()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: TestPage "VAT Report";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VariableStorage.Enqueue(VATReportHeader."No.");

        VATReportPage.OpenNew();
        VATReportPage."VAT Report Type".SetValue(VATReportHeader."VAT Report Type"::Corrective);
        VATReportPage."Original Report No.".Lookup();

        VerifyOriginalReportPeriodTransferred(VATReportPage, VATReportHeader);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure SuggestCorrectiveLinesVerifyTwoLinesCreated()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        LineType: Option New,Cancellation,Correction;
    begin
        Initialize();
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);

        RunCorrectVATReportLines(CorrVATReportHeader."No.");

        Assert.IsTrue(
          CorrectionLineExists(CorrVATReportHeader."No.", LineType::Cancellation) and CorrectionLineExists(CorrVATReportHeader."No.", LineType::Correction),
          CorrLinesNotCreatedErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure SuggestCorrectiveLinesVerifyOriginalAmount()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CorrVATReportHeader: Record "VAT Report Header";
        CorrVATReportLine: Record "VAT Report Line";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        CreateCorrectiveReport(VATReportHeader, CorrVATReportHeader);

        FindLastReportLine(VATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);
        FindLastReportLine(CorrVATReportHeader."No.", CorrVATReportLine."Line Type"::Cancellation, CorrVATReportLine);
        Assert.AreEqual(-VATReportLine.Base, CorrVATReportLine.Base, OriginalAmtMustBeZeroErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure SuggestCorrectiveLinesVerifyCorrectiveAmountIsFilled()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        OriginalAmount: Decimal;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.FindLast();
        OriginalAmount := VATReportLine.Amount;
        VATReportLine.Reset();

        CreateCorrectiveReport(VATReportHeader, CorrVATReportHeader);
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Correction, VATReportLine);

        Assert.AreEqual(OriginalAmount, VATReportLine.Amount, StrSubstNo(IncorrectCorrectionAmtErr, OriginalAmount));

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure SuggestCorrectiveLinesVerifyOriginalAmountCannotBeChanged()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        CorrVATReportLine: Record "VAT Report Line";
        VATReportSubform: TestPage "VAT Report Subform";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        CreateCorrectiveReport(VATReportHeader, CorrVATReportHeader);
        FindLastReportLine(CorrVATReportHeader."No.", CorrVATReportLine."Line Type"::Cancellation, CorrVATReportLine);

        VATReportSubform.OpenEdit();
        VATReportSubform.GotoRecord(CorrVATReportLine);
        asserterror VATReportSubform.Base.SetValue(LibraryRandom.RandInt(1000));
        Assert.ExpectedError(LineCannotBeChangedErr);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure SuggestCorrectiveLinesVerifyCorrectiveAmountCanBeChanged()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        CorrVATReportLine: Record "VAT Report Line";
        VATReportSubform: TestPage "VAT Report Subform";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        NewLineAmt: Decimal;
    begin
        Initialize();
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        CreateCorrectiveReport(VATReportHeader, CorrVATReportHeader);
        FindLastReportLine(CorrVATReportHeader."No.", CorrVATReportLine."Line Type"::Correction, CorrVATReportLine);

        NewLineAmt := LibraryRandom.RandInt(1000);
        VATReportSubform.OpenEdit();
        VATReportSubform.GotoRecord(CorrVATReportLine);
        VATReportSubform.Base.SetValue(NewLineAmt);
        VATReportSubform.OK().Invoke();

        CorrVATReportLine.Get(CorrVATReportLine."VAT Report No.", CorrVATReportLine."Line No.");
        Assert.AreEqual(NewLineAmt, CorrVATReportLine.Base, NewValueIsNotSetErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure SuggestCorrectiveLinesVerifyAmountsInSecondCorrection()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CorrVATReportHeader: Record "VAT Report Header";
        CorrAmount: Decimal;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        // Create original report
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        // Create first correction
        CreateCorrectiveReport(VATReportHeader, CorrVATReportHeader);
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Correction, VATReportLine);

        // Change amount in the corrective report
        CorrAmount := LibraryRandom.RandDec(10000, 2);
        VATReportLine.Validate(Base, CorrAmount);
        VATReportLine.Modify(true);
        SubmitVATReport(CorrVATReportHeader);

        // Create second correction
        CorrVATReportHeader."No." := '';
        CreateCorrectiveReport(VATReportHeader, CorrVATReportHeader);

        // Verify that the cancellation amount in the second correction is taken from the first correction
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Cancellation, VATReportLine);
        Assert.AreEqual(-Round(CorrAmount, 1), VATReportLine.Base, IncorrectAmtInSecondCorrErr);

        // Verify that the corrective amount is taken from the first correction
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Correction, VATReportLine);
        Assert.AreEqual(Round(CorrAmount, 1), VATReportLine.Base, IncorrectAmtInSecondCorrErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure CreateCorrectiveReportVerifyPeriodTypeCannotBeChanged()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        CreateCorrectiveReport(VATReportHeader, CorrVATReportHeader);

        asserterror CorrVATReportHeader.Validate("Report Period Type", CorrVATReportHeader."Report Period Type"::Quarter);
        Assert.ExpectedTestFieldError(CorrVATReportHeader.FieldCaption("Original Report No."), '');
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure CreateCorrectiveReportVerifyPeriodNoCannotBeChanged()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        CreateCorrectiveReport(VATReportHeader, CorrVATReportHeader);

        CorrVATReportHeader."Report Period No." := 0;
        // Default period type for the test report is month, so the number must not exceed 12
        asserterror CorrVATReportHeader.Validate("Report Period No.", (CorrVATReportHeader."Report Period No." + 1) mod 12);
        Assert.ExpectedTestFieldError(CorrVATReportHeader.FieldCaption("Original Report No."), '');
    end;

    [Test]
    procedure CorrSuggestNoNewEntry()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [SCENARIO TFS=105793,106104] Suggest lines on a correction report does not add entries for VAT entries that have already been reported.
        // No new entries for customer between the two reports.
        Initialize();

        // [GIVEN] A customer in EU with a VAT entry related to it with amount X
        // [GIVEN] A standard report have been reported for the first VAT entry
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        // [GIVEN] A correction report for the same period
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);

        // [WHEN] Suggest lines is invoked
        SuggestVATReportLines(CorrVATReportHeader."No.");

        // [THEN] No lines are suggested for the customer
        VATReportLine.SetRange("VAT Report No.", CorrVATReportHeader."No.");
        Assert.AreEqual(0, VATReportLine.Count, IncorrectNoOfReportLinesErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure CorrSuggestNewEntryKnownKey()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        AmountX: Decimal;
        AmountY: Decimal;
    begin
        // [SCENARIO 105793] Correction report: A new VAT entry for a customer that have already been submitted data for, suggest lines creates a cancellation and correction line
        Initialize();

        // [GIVEN] A customer in EU with a VAT entry related to it with amount X
        // [GIVEN] A standard report have been reported for the first VAT entry
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        FindLastReportLine(VATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);
        AmountX := VATReportLine.Base;

        // [GIVEN] The VAT Report line has one VAT entry reference
        Assert.AreEqual(1, GetNumberOfVATEntryRelations(VATReportHeader."No.", VATReportLine."Line No."), IncorrectNoOfReportLinesErr);

        // [GIVEN] A new document with VAT is posted for the customer in the same period with amount Y
        CreateVATEntries(1, TestPeriodStart, TestPeriodEnd, VATReportLine."Country/Region Code", VATReportLine."VAT Registration No.", true);
        VATEntry.FindLast();
        AmountY := -VATEntry.Base;

        // [GIVEN] A correction report for the same period
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);

        // [WHEN] Suggest lines is invoked
        SuggestVATReportLines(CorrVATReportHeader."No.");

        // [THEN] A cancellation line is created which base amount = -X
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Cancellation, VATReportLine);
        Assert.AreNearlyEqual(-Round(AmountX, 1), VATReportLine.Base, 1, IncorrectVATReportLineAmtErr);

        // [THEN] A correction line is created with a base amount = X+Y
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Correction, VATReportLine);
        Assert.AreNearlyEqual(Round(AmountX, 1) + Round(AmountY, 1), VATReportLine.Base, 1, IncorrectVATReportLineAmtErr);

        // [THEN] Drill down on the correction line shows entries for X and Y
        Assert.AreEqual(2, GetNumberOfVATEntryRelations(CorrVATReportHeader."No.", VATReportLine."Line No."), IncorrectNoOfReportLinesErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure CorrSuggestNewEntryNewKey()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        AmountX: Decimal;
    begin
        // [SCENARIO 105793] Correction report: A new VAT entry for a customer that have not already been submitted data for, suggest lines creates a new line
        Initialize();

        // [GIVEN] A standard report have been reported for period A
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        // [GIVEN] A customer in EU is created and a VAT entry is posted in period A for it with base amount X
        CreateVATEntries(1, TestPeriodStart, TestPeriodEnd, '', VATReportLine."VAT Registration No.", true);
        VATEntry.FindLast();
        AmountX := -VATEntry.Base;

        // [GIVEN] A correction report for period A
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);

        // [WHEN] Suggest lines is invoked
        SuggestVATReportLines(CorrVATReportHeader."No.");

        // [THEN] A new line is created which base amount = X
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);
        Assert.AreEqual(Round(AmountX, 1), VATReportLine.Base, IncorrectVATReportLineAmtErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure CorrSuggestNewEntriesKnownKey()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        AmountX: Decimal;
        AmountY: Decimal;
        NoOfAddEntries: Integer;
    begin
        // [SCENARIO 105793] Correction report: Two new VAT entries for a customer that have already been submitted data for, suggest lines creates a cancellation and correction line
        Initialize();

        // [GIVEN] A customer in EU with two VAT entries related to it with sum amount X
        // [GIVEN] A standard report have been reported for the first VAT entry
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        FindLastReportLine(VATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);
        AmountX := VATReportLine.Base;

        // [GIVEN] Two new documents with VAT are posted for the customer in the same period with sum amount Y
        VATEntry.FindLast();
        NoOfAddEntries := LibraryRandom.RandIntInRange(2, 5);
        CreateVATEntries(
          NoOfAddEntries, TestPeriodStart, TestPeriodEnd, VATReportLine."Country/Region Code", VATReportLine."VAT Registration No.", true);
        VATEntry.SetFilter("Entry No.", '>%1', VATEntry."Entry No.");
        VATEntry.FindSet();
        repeat
            AmountY += -VATEntry.Base;
        until VATEntry.Next() = 0;

        // [GIVEN] A correction report for the same period
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);

        // [WHEN] Suggest lines is invoked
        SuggestVATReportLines(CorrVATReportHeader."No.");

        // [THEN] A cancellation line is created which base amount = -X
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Cancellation, VATReportLine);
        Assert.AreNearlyEqual(-Round(AmountX, 1), VATReportLine.Base, 1, IncorrectVATReportLineAmtErr);

        // [THEN] A correction line is created with a base amount = X+Y
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Correction, VATReportLine);
        Assert.AreNearlyEqual(Round(AmountX, 1) + Round(AmountY, 1), VATReportLine.Base, 1, IncorrectVATReportLineAmtErr);

        // [THEN] Drill down on the correction line shows entries for X and Y
        Assert.AreEqual(
          1 + NoOfAddEntries, GetNumberOfVATEntryRelations(CorrVATReportHeader."No.", VATReportLine."Line No."),
          IncorrectNoOfReportLinesErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure CorrSuggestNewEntryBasePreManualChange()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        Corr2VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        AmountX: Decimal;
        AmountY: Decimal;
        AmountZ: Decimal;
    begin
        // [SCENARIO 105793] 2nd correction report: A new VAT entry for a customer that have already been submitted data for, and corrected with a manual inputted base.
        // Suggest lines creates a cancellation and correction line
        Initialize();

        // [GIVEN] A customer in EU with a VAT entry related to it with amount X
        // [GIVEN] A standard report have been reported for the first VAT entry
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        FindLastReportLine(VATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);
        AmountX := VATReportLine.Base;

        // [GIVEN] A correction report has been submitted with a base amount manual changed to Y
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);
        RunCorrectVATReportLines(CorrVATReportHeader."No.");
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Correction, VATReportLine);
        AmountY := LibraryRandom.RandDecInRange(1, 1000, 2);
        VATReportLine.Validate(Base, AmountY);
        VATReportLine.Modify(true);
        SubmitVATReport(CorrVATReportHeader);

        // [GIVEN] A new document with VAT is posted for the customer in the same period with amount Z
        CreateVATEntries(1, TestPeriodStart, TestPeriodEnd, VATReportLine."Country/Region Code", VATReportLine."VAT Registration No.", true);
        VATEntry.FindLast();
        AmountZ := -VATEntry.Base;

        // [GIVEN] A 2nd correction report for the same period
        CreateCorrectiveVATReportHeader(VATReportHeader, Corr2VATReportHeader);

        // [WHEN] Suggest lines is invoked
        SuggestVATReportLines(Corr2VATReportHeader."No.");

        // [THEN] A cancellation line is created which base amount = -Y
        FindLastReportLine(Corr2VATReportHeader."No.", VATReportLine."Line Type"::Cancellation, VATReportLine);
        Assert.AreNearlyEqual(-Round(AmountY, 1), VATReportLine.Base, 1, IncorrectVATReportLineAmtErr);

        // [THEN] A correction line is created with a base amount = X+Z
        FindLastReportLine(Corr2VATReportHeader."No.", VATReportLine."Line Type"::Correction, VATReportLine);
        Assert.AreNearlyEqual(AmountX + Round(AmountZ, 1), VATReportLine.Base, 1, IncorrectVATReportLineAmtErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(Corr2VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure CorrSuggestNoNewEntryBasePreManualChange()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        Corr2VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        AmountY: Decimal;
    begin
        // [SCENARIO 105793] 2nd correction report: A correction report have been made with a manual base amount change. No new VAT entries.
        // Suggest lines does not suggest any lines.
        Initialize();

        // [GIVEN] A customer in EU with a VAT entry related to it with amount X
        // [GIVEN] A standard report have been reported for the first VAT entry
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        // [GIVEN] A correction report has been submitted with a base amount manual changed to Y
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);
        RunCorrectVATReportLines(CorrVATReportHeader."No.");
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Correction, VATReportLine);
        AmountY := LibraryRandom.RandDecInRange(1, 1000, 2);
        VATReportLine.Validate(Base, AmountY);
        VATReportLine.Modify(true);
        SubmitVATReport(CorrVATReportHeader);

        // [GIVEN] A 2nd correction report for the same period
        CreateCorrectiveVATReportHeader(VATReportHeader, Corr2VATReportHeader);

        // [WHEN] Suggest lines is invoked
        SuggestVATReportLines(Corr2VATReportHeader."No.");

        // [THEN] No lines are suggested for the customer
        VATReportLine.SetRange("VAT Report No.", Corr2VATReportHeader."No.");
        Assert.AreEqual(0, VATReportLine.Count, IncorrectNoOfReportLinesErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(Corr2VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure CorrSuggestNoNewEntryBasePreManualChangeCorrect()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        Corr2VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        AmountY: Decimal;
    begin
        // [SCENARIO 105793] 2nd correction report: A correction report have been made with a manual base amount change. No new VAT entries.
        // Suggest lines does not suggest any lines even after correct lines have been invoked.
        Initialize();

        // [GIVEN] A customer in EU with a VAT entry related to it with amount X
        // [GIVEN] A standard report have been reported for the first VAT entry
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        // [GIVEN] A correction report has been submitted with a base amount manual changed to Y
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);
        RunCorrectVATReportLines(CorrVATReportHeader."No.");
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Correction, VATReportLine);
        AmountY := LibraryRandom.RandDecInRange(1, 1000, 2);
        VATReportLine.Validate(Base, AmountY);
        VATReportLine.Modify(true);
        SubmitVATReport(CorrVATReportHeader);

        // [GIVEN] A 2nd correction report for the same period
        CreateCorrectiveVATReportHeader(VATReportHeader, Corr2VATReportHeader);

        // [GIVEN] The VAT Report Line with amount Y is corrected
        RunCorrectVATReportLines(Corr2VATReportHeader."No.");

        // [WHEN] Suggest lines is invoked
        SuggestVATReportLines(Corr2VATReportHeader."No.");

        // [THEN] No lines are suggested for the customer
        VATReportLine.Reset();
        VATReportLine.SetRange("VAT Report No.", Corr2VATReportHeader."No.");
        Assert.AreEqual(2, VATReportLine.Count, IncorrectNoOfReportLinesErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(Corr2VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure CorrSuggestForCorrectedLineConflictErr()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [SCENARIO TFS=105793,106104] Correction report: Suggest lines prompts an error if a correction line already exists for a key and suggest lines is about to suggest another correction
        Initialize();

        // [GIVEN] A customer in EU with a VAT entry related to it with amount X
        // [GIVEN] A standard report have been reported for the first VAT entry
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        // [GIVEN] A new VAT Entry is created the for customer with amount Y
        FindLastReportLine(VATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);
        CreateVATEntries(1, TestPeriodStart, TestPeriodEnd, VATReportLine."Country/Region Code", VATReportLine."VAT Registration No.", true);

        // [GIVEN] A correction report for the same period
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);

        // [WHEN] The VAT Report line of the standard report with amount X is selected via Correct lines
        RunCorrectVATReportLines(CorrVATReportHeader."No.");

        // [THEN] A cancellation and correction line is added to the report for the customer
        Assert.IsTrue(
              CorrectionLineExists(CorrVATReportHeader."No.", VATReportLine."Line Type"::Cancellation) and
              CorrectionLineExists(CorrVATReportHeader."No.", VATReportLine."Line Type"::Correction),
              CorrLinesNotCreatedErr);

        // [WHEN] Suggest lines is invoked
        asserterror SuggestVATReportLines(CorrVATReportHeader."No.");

        // [THEN] An error is thrown as there already exists a cancellation/correction set for the customer
        Assert.ExpectedError(KeyAlreadyExistsErr);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure CorrSuggestForCorrectedLineNoNewEntries()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [SCENARIO 105793] Correction report: Suggest lines does not prompts an error if a correction line already exists for a key and no new VAT entries is posted
        Initialize();

        // [GIVEN] A customer in EU with a VAT entry related to it with amount X
        // [GIVEN] A standard report have been reported for the first VAT entry
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        // [GIVEN] A correction report for the same period
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);

        // [GIVEN] The VAT Report Line for amount X is copied to the new report via Correct lines
        RunCorrectVATReportLines(CorrVATReportHeader."No.");

        // [GIVEN] A cancellation and correction line is added to the report for the customer
        Assert.IsTrue(
              CorrectionLineExists(CorrVATReportHeader."No.", VATReportLine."Line Type"::Cancellation) and
              CorrectionLineExists(CorrVATReportHeader."No.", VATReportLine."Line Type"::Correction),
              CorrLinesNotCreatedErr);

        // [WHEN] Suggest lines is invoked
        SuggestVATReportLines(CorrVATReportHeader."No.");

        // [THEN] No output or errors is generated
        VATReportLine.SetRange("VAT Report No.", CorrVATReportHeader."No.");
        Assert.AreEqual(2, VATReportLine.Count, IncorrectNoOfReportLinesErr); // The cancellation/correction set

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure CorrLinesDisplayCorrectBaseAmounts()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        AmountX: Decimal;
    begin
        // [SCENARIO 105793] Correction report: User can manually correct a VAT report line which has been previously reported.
        // The base amount displayed in correction and cancellation would be plus and minus the actual value reported before.
        Initialize();

        // [GIVEN] A customer in EU with a VAT entry A related to it with amount X
        // [GIVEN] A standard report have been reported for the first VAT entry A
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        FindLastReportLine(VATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);
        AmountX := VATReportLine.Base;

        // [GIVEN] A correction report is created for same period
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);

        // [GIVEN] Correct lines is invoked
        // [GIVEN] The user is presented with a set of lines for previous report: line A.
        // [WHEN] The user selects line A.
        RunCorrectVATReportLines(CorrVATReportHeader."No.");

        // [THEN] A cancellation line is created with amount -X
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Cancellation, VATReportLine);
        Assert.AreEqual(-Round(AmountX, 1), VATReportLine.Base, IncorrectAmtInSecondCorrErr);

        // [THEN] A cancellation line is created with amount X
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Correction, VATReportLine);
        Assert.AreEqual(Round(AmountX, 1), VATReportLine.Base, IncorrectAmtInSecondCorrErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure CorrLinesCannotBeInvokedTwice()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [SCENARIO 105793] Correction report: After correct lines was invoked for a line in the previous report, it correct line cannot be invoked again for the same line.
        Initialize();

        // [GIVEN] A customer in EU with a VAT entry A related to it with amount X
        // [GIVEN] A standard report have been reported for the first VAT entry A
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        FindLastReportLine(VATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);

        // [GIVEN] A correction report is created for same period and correct lines is invoked
        // [GIVEN] The user is presented with a set of lines for previous report. VAT Report Line for VAT Entry A is selected
        // [GIVEN] Two VAT Reports lines are created for line A
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);
        RunCorrectVATReportLines(CorrVATReportHeader."No.");

        // [GIVEN] Correction lines is invoked again.
        // [WHEN] The user selects to correct the VAT Report Line for VAT Entry A
        // [THEN] The user encounters an error saying that this line is already present for correction.

        asserterror RunCorrectVATReportLines(CorrVATReportHeader."No.");
        Assert.ExpectedError(CorrectionEntryAlreadyExistsErr);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesValuesListHandler')]
    procedure CorrLinesForPrevAndReportedEntries()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        Corr2VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        AmountXCheck: Variant;
        AmountYCheck: Variant;
        AmountZ: Variant;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        AmountX: Decimal;
    begin
        // [SCENARIO 105793] Correction report: User can manually correct a VAT report line which has been previously corrected or reported before.
        Initialize();
        FindFirstMonthWithoutVATEntries(TestPeriodStart, TestPeriodEnd);

        // [GIVEN] Customer A in EU with a VAT entry related to it with amount X
        CreateOneVATEntry(
          GetNextVATEntryNo(), LibraryUtility.GenerateRandomDate(TestPeriodStart, TestPeriodEnd), '', LibraryUtility.GenerateGUID(), true, false);

        // [GIVEN] Customer B in EU with a VAT entry related to it with amount Y
        CreateOneVATEntry(
          GetNextVATEntryNo(), LibraryUtility.GenerateRandomDate(TestPeriodStart, TestPeriodEnd), '', LibraryUtility.GenerateGUID() + '1', true,
          false);

        // [GIVEN] A standard report have been reported for the VAT entries of customer A and customer B.
        CreateAndReleaseVATReport(VATReportHeader, TestPeriodStart);
        SubmitVATReport(VATReportHeader);
        VATReportHeader.Get(VATReportHeader."No.");

        FindFirstReportLine(VATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);
        AmountX := VATReportLine.Base;

        // [GIVEN] A correction report is created for same period and correct lines is invoked
        // [GIVEN] The user is presented with a set of lines for previous report: a line for cutomer A with amount X, and a line for customer B with amount Y. User chooses B.
        // [GIVEN] The user then is presented with a set of 2 lines for previously reported line of customer B, cancellation line with amount -Y and a correction line with amount Y.
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);
        RunCorrectVATReportLines(CorrVATReportHeader."No.");

        // [GIVEN] The user modifies the amount of the correction for customer B to amount Z.
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Correction, VATReportLine);
        AmountZ := LibraryRandom.RandDecInRange(1, 1000, 2);
        VATReportLine.Validate(Base, AmountZ);
        VATReportLine.Modify(true);

        // [GIVEN] The report is submitted.
        SubmitVATReport(CorrVATReportHeader);

        // [WHEN] Another correction report is created for the same period and correction lines is invoked.
        VariableStorage.Clear();
        CreateCorrectiveVATReportHeader(VATReportHeader, Corr2VATReportHeader);
        RunCorrectVATReportLines(Corr2VATReportHeader."No.");

        // [THEN] The user is presented with a set of lines for previous report: line for customer A with amount X with type correction and line B for amount Z.
        VariableStorage.Dequeue(AmountXCheck);
        Assert.AreEqual(Round(AmountX, 1), Round(AmountXCheck, 1), IncorrectAmtInSecondCorrErr);
        VariableStorage.Dequeue(AmountYCheck);
        Assert.AreEqual(Round(AmountZ, 1), Round(AmountYCheck, 1), IncorrectAmtInSecondCorrErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(Corr2VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure CorrLinesNewVATEntryOldAmount()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportLineRelation: Record "VAT Report Line Relation";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        AmountX: Decimal;
        OriginalVATEntryCount: Integer;
    begin
        // [SCENARIO 105793] Correct line suggests the amount of the previous report even when new VAT entries have been posted in between
        Initialize();

        // [GIVEN] A customer in EU with a VAT entry related to it with amount X
        // [GIVEN] A standard report have been reported for the first VAT entry
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        FindLastReportLine(VATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);
        VATReportLineRelation.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLineRelation.SetRange("VAT Report Line No.", VATReportLine."Line No.");
        OriginalVATEntryCount := VATReportLineRelation.Count();

        // [GIVEN] A new VAT Entry is created the for customer with amount Y
        FindLastReportLine(VATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);
        AmountX := VATReportLine.Base;
        CreateVATEntries(1, TestPeriodStart, TestPeriodEnd, '', VATReportLine."VAT Registration No.", true);

        // [GIVEN] A correction report for the same period
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);

        // [WHEN] The VAT Report line of the standard report is selected via Correct lines
        RunCorrectVATReportLines(CorrVATReportHeader."No.");

        // [THEN] A cancellation line is created with amount -X and drill down shows the first VAT entry only
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Cancellation, VATReportLine);
        Assert.AreEqual(-Round(AmountX, 1), VATReportLine.Base, IncorrectAmtInSecondCorrErr);
        Assert.AreEqual(
          OriginalVATEntryCount, GetNumberOfVATEntryRelations(CorrVATReportHeader."No.", VATReportLine."Line No."),
          IncorrectNoOfReportLinesErr);

        // [THEN] A correction line is created with amount X and drill down shows the first VAT entry only
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Correction, VATReportLine);
        Assert.AreEqual(Round(AmountX, 1), VATReportLine.Base, IncorrectAmtInSecondCorrErr);
        Assert.AreEqual(
          OriginalVATEntryCount, GetNumberOfVATEntryRelations(CorrVATReportHeader."No.", VATReportLine."Line No."),
          IncorrectNoOfReportLinesErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure CorrSuggestChangedFilters()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        AmountX: Decimal;
        AmountZ: Decimal;
    begin
        // [SCENARIO 105793] Correction report: Trade type is different from the Standard report. The now excluded VAT entries are removed
        Initialize();

        // [GIVEN] A customer in EU with a VAT entry related to it with amount X
        // [GIVEN] A standard sales report have been reported for the first VAT entry
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        FindLastReportLine(VATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);
        AmountX := VATReportLine.Base;

        // [GIVEN] A new sales document with VAT is posted for the customer in the same period with amount Y
        CreateVATEntries(1, TestPeriodStart, TestPeriodEnd, VATReportLine."Country/Region Code", VATReportLine."VAT Registration No.", true);

        // [GIVEN] A purchase document is posted for the same period with amount Z
        CreateOneVATEntry(
          GetNextVATEntryNo(),
          LibraryUtility.GenerateRandomDate(TestPeriodStart, TestPeriodEnd),
          '',
          LibraryUtility.GenerateGUID(),
          true, true); // Purchase entry
        VATEntry.FindLast();
        AmountZ := -Round(VATEntry.Base, 1);

        // [GIVEN] A correction report for the same period
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);

        // [GIVEN] The trade type is changed to purchase
        CorrVATReportHeader.Validate("Trade Type", CorrVATReportHeader."Trade Type"::Purchases);
        CorrVATReportHeader.Modify(true);

        // [WHEN] Suggest lines is invoked
        SuggestVATReportLines(CorrVATReportHeader."No.");

        // [THEN] A cancellation line is created which base amount = -X for the customer
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Cancellation, VATReportLine);
        Assert.AreNearlyEqual(-Round(AmountX, 1), VATReportLine.Base, 1, IncorrectVATReportLineAmtErr);

        // [THEN] A correction line is created with a base amount = 0 for the customer
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Correction, VATReportLine);
        Assert.AreEqual(0, VATReportLine.Base, IncorrectVATReportLineAmtErr);

        // [THEN] A new line is created for the vendor with amount Z
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);
        Assert.AreNearlyEqual(Round(AmountZ, 1), VATReportLine.Base, 1, IncorrectVATReportLineAmtErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure CorrSuggestChangedFiltersTwice()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        Corr2VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        AmountZ: Decimal;
    begin
        // [SCENARIO 105793] Two corrections reports, where the corr. reports have different trade type than the standard
        Initialize();

        // [GIVEN] A customer in EU with a VAT entry related to it with amount X
        // [GIVEN] A standard sales report have been reported for the first VAT entry
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        // [GIVEN] A purchase document is posted for the same period with amount Y
        CreateOneVATEntry(
          GetNextVATEntryNo(),
          LibraryUtility.GenerateRandomDate(TestPeriodStart, TestPeriodEnd),
          '',
          LibraryUtility.GenerateGUID(),
          true, true); // Purchase entry

        // [GIVEN] A correction report for the same period
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);

        // [GIVEN] The trade type is changed to purchase
        CorrVATReportHeader.Validate("Trade Type", CorrVATReportHeader."Trade Type"::Purchases);
        CorrVATReportHeader.Modify(true);

        // [GIVEN] Suggest lines is invoked
        SuggestVATReportLines(CorrVATReportHeader."No.");

        // [GIVEN] The first correction report is submitted
        SubmitVATReport(CorrVATReportHeader);

        // [GiVEN] A second purchase document is posted for same period with amount Z
        CreateOneVATEntry(
          GetNextVATEntryNo(),
          LibraryUtility.GenerateRandomDate(TestPeriodStart, TestPeriodEnd),
          '',
          LibraryUtility.GenerateGUID(),
          true, true); // Purchase entry
        VATEntry.FindLast();
        AmountZ := -Round(VATEntry.Base, 1);

        // [GIVEN] A second purchase correction report is created for same period
        CreateCorrectiveVATReportHeader(VATReportHeader, Corr2VATReportHeader);
        Corr2VATReportHeader.Validate("Trade Type", CorrVATReportHeader."Trade Type"::Purchases);
        Corr2VATReportHeader.Modify(true);

        // [WHEN] Suggest lines is invoked
        SuggestVATReportLines(Corr2VATReportHeader."No.");

        // [THEN] A new line is created for the second vendor with amount Z
        FindLastReportLine(Corr2VATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);
        Assert.AreEqual(AmountZ, VATReportLine.Base, IncorrectVATReportLineAmtErr);

        // [THEN] Only one new VAT Report line is created
        VATReportLine.SetRange("VAT Report No.", Corr2VATReportHeader."No.");
        Assert.AreEqual(1, VATReportLine.Count, IncorrectNoOfReportLinesErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(Corr2VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure CorrSuggestChangedFiltersToggle()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        Corr2VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        AmountX: Decimal;
        AmountY: Decimal;
        AmountZ: Decimal;
    begin
        // [SCENARIO 105793] Standard report and 2nd correction report have same trade type, 1st correction report does not. Suggest lines is used. 2nd correction report should be equal the standard.
        Initialize();

        // [GIVEN] A customer in EU with a VAT entry related to it with amount X
        // [GIVEN] A standard sales report have been reported for the first VAT entry
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        FindLastReportLine(VATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);
        AmountX := VATReportLine.Base;

        // [GIVEN] A new sales document with VAT is posted for the customer in the same period with amount Y. This is only suppose to be picked up in the 2nd corr. report
        CreateVATEntries(1, TestPeriodStart, TestPeriodEnd, VATReportLine."Country/Region Code", VATReportLine."VAT Registration No.", true);
        VATEntry.FindLast();
        AmountY := -Round(VATEntry.Base, 1);

        // [GIVEN] A purchase document is posted for the same period with amount Z
        CreateOneVATEntry(
          GetNextVATEntryNo(),
          LibraryUtility.GenerateRandomDate(TestPeriodStart, TestPeriodEnd),
          '',
          LibraryUtility.GenerateGUID(),
          true, true); // Purchase entry
        VATEntry.FindLast();
        AmountZ := -Round(VATEntry.Base, 1);

        // [GIVEN] A correction report for the same period
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);

        // [GIVEN] The trade type is changed to purchase
        CorrVATReportHeader.Validate("Trade Type", CorrVATReportHeader."Trade Type"::Purchases);
        CorrVATReportHeader.Modify(true);

        // [GIVEN] Suggest lines is invoked
        SuggestVATReportLines(CorrVATReportHeader."No.");

        // [GIVEN] The first correction report is submitted
        SubmitVATReport(CorrVATReportHeader);

        // [GIVEN] A second correction report is created for same period
        CreateCorrectiveVATReportHeader(VATReportHeader, Corr2VATReportHeader);

        // [GIVEN] Trade type of the second correction report is changed to sales
        Corr2VATReportHeader.Validate("Trade Type", CorrVATReportHeader."Trade Type"::Sales);
        Corr2VATReportHeader.Modify(true);

        // [WHEN] Suggest lines is invoked
        SuggestVATReportLines(Corr2VATReportHeader."No.");

        // [THEN] A cancellation line is created which base amount = -Z for the vendor
        FindFirstReportLine(Corr2VATReportHeader."No.", VATReportLine."Line Type"::Cancellation, VATReportLine);
        Assert.AreNearlyEqual(-Round(AmountZ, 1), VATReportLine.Base, 1, IncorrectVATReportLineAmtErr);

        // [THEN] A correction line is created with a base amount = 0 for the vendor
        FindFirstReportLine(Corr2VATReportHeader."No.", VATReportLine."Line Type"::Correction, VATReportLine);
        Assert.AreEqual(0, VATReportLine.Base, IncorrectVATReportLineAmtErr);

        // [THEN] A cancellation line is created with a base amount = 0 for the customer
        FindLastReportLine(Corr2VATReportHeader."No.", VATReportLine."Line Type"::Cancellation, VATReportLine);
        Assert.AreEqual(0, VATReportLine.Base, IncorrectVATReportLineAmtErr);

        // [THEN] A correction line is created with a base amount = X+Y for the customer
        FindLastReportLine(Corr2VATReportHeader."No.", VATReportLine."Line Type"::Correction, VATReportLine);
        Assert.AreNearlyEqual(Round(AmountX, 1) + Round(AmountY, 1), VATReportLine.Base, 1, IncorrectVATReportLineAmtErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(Corr2VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure CorrSuggestChangedFiltersSuggestTwice()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [SCENARIO 105793] Suggest lines is invoked twice on a correction report where a filter change results in removing some entries from the standard report. No error should be thrown.
        Initialize();

        // [GIVEN] A customer in EU with a VAT entry related to it with amount X
        // [GIVEN] A standard sales report have been reported for the first VAT entry
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        // [GIVEN] A purchase document is posted for the same period with amount Y
        CreateOneVATEntry(
          GetNextVATEntryNo(),
          LibraryUtility.GenerateRandomDate(TestPeriodStart, TestPeriodEnd),
          '',
          LibraryUtility.GenerateGUID(),
          true, true); // Purchase entry

        // [GIVEN] A correction report for the same period
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);

        // [GIVEN] The trade type is changed to purchase
        CorrVATReportHeader.Validate("Trade Type", CorrVATReportHeader."Trade Type"::Purchases);
        CorrVATReportHeader.Modify(true);

        // [GIVEN] Suggest lines is invoked
        SuggestVATReportLines(CorrVATReportHeader."No.");

        // [WHEN] Suggest lines is invoked again
        SuggestVATReportLines(CorrVATReportHeader."No.");

        // [THEN] The report is not changed

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure CorrSuggestNewEntriesSuggestTwice()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [SCENARIO 105793] Suggest lines is invoked twice on a correction report where new VAT entries have been posted since the standard report. No error is thrown
        Initialize();

        // [GIVEN] A customer in EU with a VAT entry related to it with amount X
        // [GIVEN] A standard sales report have been reported for the first VAT entry
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        FindLastReportLine(VATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);

        // [GIVEN] A new sales document with VAT is posted for the customer in the same period with amount Y. This is only suppose to be picked up in the 2nd corr. report
        CreateVATEntries(1, TestPeriodStart, TestPeriodEnd, VATReportLine."Country/Region Code", VATReportLine."VAT Registration No.", true);

        // [GIVEN] A correction report for the same period
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);

        // [GIVEN] Suggest lines is invoked
        SuggestVATReportLines(CorrVATReportHeader."No.");

        // [GIVEN] The correction line's amount is changed
        FindLastReportLine(CorrVATReportHeader."No.", VATReportLine."Line Type"::Correction, VATReportLine);
        VATReportLine.Validate(Base, LibraryRandom.RandDecInRange(1, 9999, 2));
        VATReportLine.Modify(true);

        // [WHEN] Suggest lines is invoked again
        SuggestVATReportLines(CorrVATReportHeader."No.");

        // [THEN] The report is not changed

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATEntriesListHandler')]
    procedure ClickAmountAssistEdit_VerifyVATEntriesList()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: TestPage "VAT Report";
        VATAmount: Variant;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        SetupVATReportScenario(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VATReportPage.OpenView();
        VATReportPage.GotoRecord(VATReportHeader);
        VATReportPage.VATReportLines.Base.AssistEdit();

        VariableStorage.Dequeue(VATAmount);
        Assert.AreEqual(VATReportPage.VATReportLines.Base.AsDecimal(), Round(VATAmount, 1), IncorrectVATEntriesListErr);
        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure VerifyAmountCannotBeChangedInReleasedReport()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        SetupVATReportScenario(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.FindFirst();

        asserterror VATReportLine.Validate(Amount, LibraryRandom.RandInt(10000));
        Assert.ExpectedTestFieldError(VATReportHeader.FieldCaption(Status), Format(VATReportHeader.Status::Open));
    end;

    [Test]
    procedure VerifyReportLineCanRelateToOneTableOnly()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        Initialize();
        CreateMockVATReportWithLines(VATReportHeader, VATReportHeader."VAT Report Type"::Standard, VATReportHeader."Report Period Type"::Year, 1);

        VATReportLineRelation.Get(VATReportHeader."No.", 1, DATABASE::"VAT Entry", 1);
        VATReportLineRelation.Validate("Table No.", DATABASE::"G/L Entry");
        asserterror VATReportLineRelation.Insert(true);

        Assert.ExpectedTestFieldError(VATReportLineRelation.FieldCaption("Table No."), Format(Database::"VAT Entry"));
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure VerifyCorrectiveReportWithOddNoOfLinesCannotBeReleased()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        CorrVATReportLine: Record "VAT Report Line";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        CreateCorrectiveReport(VATReportHeader, CorrVATReportHeader);
        FindLastReportLine(CorrVATReportHeader."No.", CorrVATReportLine."Line Type"::Correction, CorrVATReportLine);
        CorrVATReportLine.Delete(true);

        asserterror VATReportMediator.Release(CorrVATReportHeader);
        Assert.ExpectedError(OddNoOfCorrLinesErr);
    end;

    [Test]
    procedure ECSLReportSetReportPeriodTypeMonth()
    var
        VATReportHeader: Record "VAT Report Header";
        ECSLReport: TestPage "ECSL Report";
        VATReportNo: Code[20];
    begin
        // [FEATURE] [UI] [UT] [ECSL Report]
        // [SCENARIO 320449] EC Sales List Report card accepts "Report Period Type"= Month
        Initialize();

        ECSLReport.OpenNew();
        ECSLReport."Report Period No.".SetValue(1);
        ECSLReport.ReportPeriodType.SetValue(Format(VATReportHeader."Report Period Type"::Month));
        VATReportNo := CopyStr(ECSLReport."No.".Value(), 1, 20);
        ECSLReport.Close();

        VATReportHeader.Get(VATReportNo);
        VATReportHeader.TestField("Report Period Type", VATReportHeader."Report Period Type"::Month);
    end;

    [Test]
    procedure ECSLReportSetReportPeriodTypeQuarter()
    var
        VATReportHeader: Record "VAT Report Header";
        ECSLReport: TestPage "ECSL Report";
        VATReportNo: Code[20];
    begin
        // [FEATURE] [UI] [UT] [ECSL Report]
        // [SCENARIO 320449] EC Sales List Report card accepts "Report Period Type"= Quarter
        Initialize();

        ECSLReport.OpenNew();
        ECSLReport."Report Period No.".SetValue(1);
        ECSLReport.ReportPeriodType.SetValue(Format(VATReportHeader."Report Period Type"::Quarter));
        VATReportNo := CopyStr(ECSLReport."No.".Value(), 1, 20);
        ECSLReport.Close();

        VATReportHeader.Get(VATReportNo);
        VATReportHeader.TestField("Report Period Type", VATReportHeader."Report Period Type"::Quarter);
    end;

    [Test]
    procedure ECSLReportSetReportPeriodTypeYear()
    var
        VATReportHeader: Record "VAT Report Header";
        ECSLReport: TestPage "ECSL Report";
    begin
        // [FEATURE] [UI] [UT] [ECSL Report]
        // [SCENARIO 320449] EC Sales List Report card does not accept "Report Period Type"= Year
        Initialize();

        ECSLReport.OpenNew();
        ECSLReport."Report Period No.".SetValue(1);
        asserterror ECSLReport.ReportPeriodType.SetValue(Format(VATReportHeader."Report Period Type"::Year));
        Assert.ExpectedErrorCode('TestValidation');
        Assert.ExpectedError(
          StrSubstNo(
            UnacceptableValueErr,
            Format(VATReportHeader."Report Period Type"::Year), ECSLReport.ReportPeriodType.Caption));
    end;

    [Test]
    procedure ECSLReportSetReportPeriodTypeBiMonthly()
    var
        VATReportHeader: Record "VAT Report Header";
        ECSLReport: TestPage "ECSL Report";
        VATReportNo: Code[20];
    begin
        // [FEATURE] [UI] [UT] [ECSL Report]
        // [SCENARIO 320449] EC Sales List Report card accepts "Report Period Type"= Bi-Monthly
        Initialize();

        ECSLReport.OpenNew();
        ECSLReport."Report Period No.".SetValue(1);
        ECSLReport.ReportPeriodType.SetValue(Format(VATReportHeader."Report Period Type"::"Bi-Monthly"));
        VATReportNo := CopyStr(ECSLReport."No.".Value(), 1, 20);
        ECSLReport.Close();

        VATReportHeader.Get(VATReportNo);
        VATReportHeader.TestField("Report Period Type", VATReportHeader."Report Period Type"::"Bi-Monthly");
    end;

    [Test]
    procedure ExportVATReportEncodingUT()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 166131] VAT Report exports country specific symbols with correct encoding
        Initialize();

        // [GIVEN] Company information address contains country specific symbols
        SetCompanyInformationAddress('ÄäÜüöÖß');

        // [WHEN] Create VAT Report Xml
        CreateVATReport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);

        // [THEN] XML contains country specific symbols in correct encoding
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:anschrift/zm:strasse', 'ÄäÜüöÖß');

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyNoOfLinesOnZeroBaseAmount()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] VAT Report lines with zero base amount are not included in exported VIES report
        Initialize();

        // [WHEN] Export VIES report with VAT Report Lines having zero base amount
        CreateVATReportZeroBase(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);

        // [THEN] No zmZeile nodes exist in the exported XML
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeCountByXPath('//zm:zms/zm:unternehmer/zm:zm/zm:zmZeile', 0);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyCreationDate()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains creation date
        Initialize();

        // [WHEN] Export VIES report
        CreateVATReport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);

        // [THEN] Creation date in XML starts with today's date
        InitXMLReaderForVIESReport(TempBlob);
        Assert.IsTrue(
            StrPos(LibraryXPathXMLReader.GetXmlNodeInnerTextByXPathWithIndex('//elan:Erstellung', 0), Format(Today(), 0, '<Year4>-<Month,2>-<Day,2>')) = 1,
            'Creation date should start with today''s date');

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyReporterName()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains company name
        Initialize();

        // [WHEN] Export VIES report
        CreateVATReport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);

        // [THEN] Company Name in XML matches "VR"."Company Name"
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:anschrift/zm:name', VATReportHeader."Company Name");

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyAddressStreet()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains company address
        Initialize();

        // [WHEN] Export VIES report
        CreateVATReport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);

        // [THEN] Company Address in XML matches "VR"."Company Address"
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:anschrift/zm:strasse', VATReportHeader."Company Address");

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyAddressPostcode()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains post code
        Initialize();

        // [WHEN] Export VIES report
        CreateVATReport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);

        // [THEN] Post Code in XML matches "VR"."Post Code"
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:anschrift/zm:plz', VATReportHeader."Post Code");

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyAddressLocation()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains city
        Initialize();

        // [WHEN] Export VIES report
        CreateVATReport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);

        // [THEN] City in XML matches "VR".City
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:anschrift/zm:ort', VATReportHeader.City);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyISOCountryCode()
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains ISO country code in entrepreneur's address
        Initialize();

        // [GIVEN] Company Information with Country/Region Code having ISO Code "DE"
        CompanyInformation.Get();
        CountryRegion.Get(CompanyInformation."Country/Region Code");

        // [WHEN] Export VIES report
        CreateVATReport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);

        // [THEN] ISO Country Code in XML matches Company Information's Country/Region ISO Code
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:anschrift/zm:staat', CountryRegion."ISO Code");

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyReporterVATID()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains VAT Registration No.
        Initialize();

        // [WHEN] Export VIES report
        CreateVATReport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);

        // [THEN] VAT Registration No. in XML matches "DE" + "VR"."VAT Registration No."
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:deUStIdNr', 'DE' + VATReportHeader."VAT Registration No.");

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyTypeOfStatement()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains type of statement
        Initialize();

        // [WHEN] Export VIES report
        CreateVATReport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);

        // [THEN] Type of statement attribute is '10' (standard report)
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlAttributeValue('//zm:zms/zm:unternehmer/zm:zm', 'meldeart', '10');

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyPartnerVATID()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CountryRegion: Record "Country/Region";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report exports Partner VAT ID with country code and VAT number separately
        Initialize();

        // [WHEN] Export VIES report with VAT Report Line with Country/Region Code "BE" and VAT Registration No. "123456789"
        CreateVATReport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.FindFirst();
        CountryRegion.Get(VATReportLine."Country/Region Code");

        // [THEN] Country code and VAT Registration No. are exported separately
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:zm/zm:zmZeile/zm:lkz', CountryRegion."EU Country/Region Code");
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:zm/zm:zmZeile/zm:auslUStIdNrOhneLKZ', VATReportLine."VAT Registration No.");

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyAssessmentBasis()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report exports assessment basis (amount)
        Initialize();

        // [WHEN] Export VIES report
        CreateVATReport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.FindFirst();

        // [THEN] Amount in XML matches VAT Report Line Base amount
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:zm/zm:zmZeile/zm:betrag', Format(Round(VATReportLine.Base, 1), 0, 9));

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyTypeOfTurnover()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains type of turnover 'L' for EU Deliveries
        Initialize();

        // [WHEN] Export VIES report without EU Service and without EU 3-Party Trade
        CreateVATReportWithTurnoverType(VATReportHeader, TempBlob, false, false);

        // [THEN] Type of turnover in XML is 'L' (Lieferungen - deliveries)
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:zm/zm:zmZeile/zm:umsatzart', 'L');
    end;

    [Test]
    procedure ExportVATReportVerifyTypeOfTurnoverServices()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains type of turnover 'S' for EU Services
        Initialize();

        // [WHEN] Export VIES report with VAT Report Line having "EU Service" = true
        CreateVATReportWithTurnoverType(VATReportHeader, TempBlob, true, false);

        // [THEN] Type of turnover in XML is 'S' (Sonstige Leistung - Services)
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:zm/zm:zmZeile/zm:umsatzart', 'S');
    end;

    [Test]
    procedure ExportVATReportVerifyTypeOfTurnoverTriangularTrade()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains type of turnover 'D' for EU 3-Party Trade
        Initialize();

        // [WHEN] Export VIES report with VAT Report Line having "EU 3-Party Trade" = true
        CreateVATReportWithTurnoverType(VATReportHeader, TempBlob, false, true);

        // [THEN] Type of turnover in XML is 'D' (Dreiecksgeschäft - Triangular trade)
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:zm/zm:zmZeile/zm:umsatzart', 'D');
    end;

    [Test]
    procedure ExportVATReportVerifyNotice()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report does not contain notice node when notice is not set
        Initialize();

        // [WHEN] Export VIES report with Notice = false
        CreateVATReportWithNotice(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob, false);

        // [THEN] Notice node is absent in the exported XML
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//zm:zms/zm:unternehmer/zm:zm/zm:anzeige');

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyNoticeWhenSet()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains notice node with 'true' when notice is set
        Initialize();

        // [WHEN] Export VIES report with Notice = true
        CreateVATReportWithNotice(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob, true);

        // [THEN] Notice node value is 'true'
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:zm/zm:anzeige', 'true');

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyRevocation()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report does not contain revocation node when revocation is not set
        Initialize();

        // [WHEN] Export VIES report with Revocation = false
        CreateVATReportWithRevocation(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob, false);

        // [THEN] Revocation node is absent in the exported XML
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeAbsence('//zm:zms/zm:unternehmer/zm:zm/zm:widerruf');

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyRevocationWhenSet()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains revocation node with 'true' when revocation is set
        Initialize();

        // [WHEN] Export VIES report with Revocation = true
        CreateVATReportWithRevocation(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob, true);

        // [THEN] Revocation node value is 'true'
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:zm/zm:widerruf', 'true');

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyNoOfLines()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains correct number of lines
        Initialize();

        // [WHEN] Export VIES report with multiple VAT Report Lines
        CreateVATReportWithMultipleLines(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");

        // [THEN] Number of zmZeile nodes matches VAT Report Line count
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeCountByXPath('//zm:zms/zm:unternehmer/zm:zm/zm:zmZeile', VATReportLine.Count);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyReportingTimePeriod()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains correct reporting time period
        Initialize();

        // [WHEN] Export VIES report
        CreateVATReport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);

        // [THEN] Year value in XML match VAT Report Header period
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:zm/zm:mzr/zm:jahr', Format(VATReportHeader."Report Year"));

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyPeriodCodeForQuarter()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        QuarterNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains correct period code for quarterly report (1-4)
        Initialize();

        // [GIVEN] Quarter number 1-4
        QuarterNo := LibraryRandom.RandIntInRange(1, 4);

        // [WHEN] Export VIES report with Report Period Type = Quarter
        CreateVATReportWithPeriodType(VATReportHeader, TempBlob, VATReportHeader."Report Period Type"::Quarter, QuarterNo);

        // [THEN] Period code in XML equals Quarter number (1-4)
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:zm/zm:mzr/zm:quart', Format(QuarterNo));
    end;

    [Test]
    procedure ExportVATReportVerifyPeriodCodeForYear()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains correct period code for annual report (5)
        Initialize();

        // [WHEN] Export VIES report with Report Period Type = Year
        CreateVATReportWithPeriodType(VATReportHeader, TempBlob, VATReportHeader."Report Period Type"::Year, 1);

        // [THEN] Period code in XML equals 5 (annual)
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:zm/zm:mzr/zm:quart', '5');
    end;

    [Test]
    procedure ExportVATReportVerifyPeriodCodeForBiMonthly()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        BiMonthlyPeriodNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains correct period code for bi-monthly report (11-14)
        Initialize();

        // [GIVEN] Bi-monthly period number 1-4
        BiMonthlyPeriodNo := LibraryRandom.RandIntInRange(1, 4);

        // [WHEN] Export VIES report with Report Period Type = Bi-Monthly
        CreateVATReportWithPeriodType(VATReportHeader, TempBlob, VATReportHeader."Report Period Type"::"Bi-Monthly", BiMonthlyPeriodNo);

        // [THEN] Period code in XML equals Period No + 10 (11-14)
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:zm/zm:mzr/zm:quart', Format(BiMonthlyPeriodNo + 10));
    end;

    [Test]
    procedure ExportVATReportVerifyPeriodCodeForMonth()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        MonthNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains correct period code for monthly report (21-32)
        Initialize();

        // [GIVEN] Month number 1-12
        MonthNo := LibraryRandom.RandIntInRange(1, 12);

        // [WHEN] Export VIES report with Report Period Type = Month
        CreateVATReportWithPeriodType(VATReportHeader, TempBlob, VATReportHeader."Report Period Type"::Month, MonthNo);

        // [THEN] Period code in XML equals Month No + 20 (21-32)
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:zm/zm:mzr/zm:quart', Format(MonthNo + 20));
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure ExportCorrectiveVATReportVerifyCorrectionAmount()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        CorrVATReportLine: Record "VAT Report Line";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export corrective VIES Report contains correction amount
        Initialize();

        // [GIVEN] Submitted VAT Report "VR" and Corrective VAT Report "CVR" with correction lines
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        CreateCorrectiveReport(VATReportHeader, CorrVATReportHeader);
        SubmitVATReport(CorrVATReportHeader);

        // [WHEN] Export corrective VAT Report into TempBlob
        ExportVATReportIntoTempBlob(CorrVATReportHeader, TempBlob);
        FindLastReportLine(CorrVATReportHeader."No.", CorrVATReportLine."Line Type"::Correction, CorrVATReportLine);
        InitXMLReaderForVIESReport(TempBlob);

        // [THEN] Amount in XML matches correction line Base amount
        LibraryXPathXMLReader.VerifyXmlNodeValue('//zm:zms/zm:unternehmer/zm:zm/zm:zmZeile/zm:betrag', Format(Round(CorrVATReportLine.Base, 1), 0, 9));

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure ExportCorrectiveVATReportCancellationOff()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export corrective VIES Report with cancellation lines disabled exports 2 lines
        Initialize();

        // [GIVEN] Export Cancellation Lines is Off
        SetupExportCancellationLines(false);

        // [GIVEN] Corrective VAT Report "VR"
        CreateCorrectiveVATReport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);

        // [WHEN] Initialize XML Reader for VIES Report
        InitXMLReaderForVIESReport(TempBlob);

        // [THEN] Report type is '11' (corrective) and contains 2 lines
        LibraryXPathXMLReader.VerifyXmlAttributeValue('//zm:zms/zm:unternehmer/zm:zm', 'meldeart', '11');
        LibraryXPathXMLReader.VerifyXmlNodeCountByXPath('//zm:zms/zm:unternehmer/zm:zm/zm:zmZeile', 2);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        VATReportHeader.Get(VATReportHeader."Original Report No.");
        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure ExportCorrectiveVATReportCancellationOn()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export corrective VIES Report with cancellation lines enabled exports 3 lines
        Initialize();

        // [GIVEN] Export Cancellation Lines is On
        SetupExportCancellationLines(true);

        // [GIVEN] Corrective VAT Report "VR"
        CreateCorrectiveVATReport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);

        // [WHEN] Initialize XML Reader for VIES Report
        InitXMLReaderForVIESReport(TempBlob);

        // [THEN] Report type is '11' (corrective) and contains 3 lines
        LibraryXPathXMLReader.VerifyXmlAttributeValue('//zm:zms/zm:unternehmer/zm:zm', 'meldeart', '11');
        LibraryXPathXMLReader.VerifyXmlNodeCountByXPath('//zm:zms/zm:unternehmer/zm:zm/zm:zmZeile', 3);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        VATReportHeader.Get(VATReportHeader."Original Report No.");
        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    procedure ExportCorrectiveVATReportVerifyCancellationAmountZero()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        CorrVATReportLine: Record "VAT Report Line";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export corrective VIES Report exports cancellation lines with amount = 0
        Initialize();

        // [GIVEN] Export Cancellation Lines is On
        SetupExportCancellationLines(true);

        // [GIVEN] Submitted VAT Report "VR" and Corrective VAT Report "CVR" with cancellation line having non-zero base
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        CreateCorrectiveReport(VATReportHeader, CorrVATReportHeader);
        FindLastReportLine(CorrVATReportHeader."No.", CorrVATReportLine."Line Type"::Cancellation, CorrVATReportLine);
        Assert.AreNotEqual(0, CorrVATReportLine.Base, 'Cancellation line base should not be zero');
        SubmitVATReport(CorrVATReportHeader);

        // [WHEN] Export corrective VAT Report into TempBlob
        ExportVATReportIntoTempBlob(CorrVATReportHeader, TempBlob);
        InitXMLReaderForVIESReport(TempBlob);

        // [THEN] Cancellation line amount in XML is 0 (first zmZeile is the cancellation line)
        LibraryXPathXMLReader.VerifyXmlNodeValueByIndex('//zm:zms/zm:unternehmer/zm:zm/zm:zmZeile/zm:betrag', '0', 0);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        Cleanup(CorrVATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyUmgebungProduktion()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains 'PRODUKTION' environment when test export is disabled
        Initialize();

        // [GIVEN] VAT Report "VR" with Test Export = false
        CreateVATReportWithTestExport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob, false);

        // [WHEN] Initialize XML Reader for VIES Report
        InitXMLReaderForVIESReport(TempBlob);

        // [THEN] Umgebung node value is 'PRODUKTION'
        LibraryXPathXMLReader.VerifyXmlNodeValue('//elan:Umgebung', 'PRODUKTION');

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyUmgebungTest()
    var
        VATReportHeader: Record "VAT Report Header";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 613377] Export VIES Report contains 'TEST' environment when test export is enabled
        Initialize();

        // [GIVEN] VAT Report "VR" with Test Export = true
        CreateVATReportWithTestExport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob, true);

        // [WHEN] Initialize XML Reader for VIES Report
        InitXMLReaderForVIESReport(TempBlob);

        // [THEN] Umgebung node value is 'TEST'
        LibraryXPathXMLReader.VerifyXmlNodeValue('//elan:Umgebung', 'TEST');

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure BOPUserAccountID_Valid10Digits()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 623220] Setting BOP User Account ID to a valid 10-digit value succeeds
        Initialize();

        // [GIVEN] VAT Report Setup exists
        VATReportSetup.Get();

        // [WHEN] BOP User Account ID is set to a valid 10-digit value
        VATReportSetup.Validate("BOP User Account ID", '0987654321');

        // [THEN] No error is thrown and value is stored
        Assert.AreEqual('0987654321', VATReportSetup."BOP User Account ID", 'BOP User Account ID should be stored.');
    end;

    [Test]
    procedure BOPUserAccountID_ClearValue()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 623220] Clearing BOP User Account ID after setting it is allowed
        Initialize();

        // [GIVEN] VAT Report Setup with a valid BOP User Account ID
        VATReportSetup.Get();
        VATReportSetup.Validate("BOP User Account ID", '0987654321');
        VATReportSetup.Modify();

        // [WHEN] BOP User Account ID is cleared
        VATReportSetup.Validate("BOP User Account ID", '');

        // [THEN] No error is thrown and value is empty
        Assert.AreEqual('', VATReportSetup."BOP User Account ID", 'BOP User Account ID should be cleared.');
    end;

    [Test]
    procedure BOPUserAccountID_TooShort()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 623220] Setting BOP User Account ID to fewer than 10 digits raises an error
        Initialize();

        // [GIVEN] VAT Report Setup
        VATReportSetup.Get();

        // [WHEN] BOP User Account ID is set to 5 digits
        asserterror VATReportSetup.Validate("BOP User Account ID", '12345');

        // [THEN] Error about length is raised
        Assert.ExpectedError(BOPUserAccountIDLengthErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure BOPUserAccountID_TooLong()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 623220] Setting BOP User Account ID to more than 10 digits raises an error
        Initialize();

        // [GIVEN] VAT Report Setup
        VATReportSetup.Get();

        // [WHEN] BOP User Account ID is set to 11 digits
        asserterror VATReportSetup.Validate("BOP User Account ID", '12345678901');

        // [THEN] Error about length is raised
        Assert.ExpectedError(BOPUserAccountIDLengthErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure CreateVIESELMA_BOPUserAccountIDMissing()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
        VATReportExport: Codeunit "VAT Report Export";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        FileID: Text;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 623220] Creating VIES ELMA XML without BOP User Account ID raises an error
        Initialize();

        // [GIVEN] Released VAT Report "VR" with BOP User Account ID cleared
        SetupVATReportScenario(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VATReportSetup.Get();
        VATReportSetup."BOP User Account ID" := '';
        VATReportSetup.Modify();

        // [WHEN] CreateVIESELMAXml is called
        asserterror VATReportExport.CreateVIESELMAXml(VATReportHeader, FileID, TempBlob);

        // [THEN] Error about missing BOP User Account ID is raised
        Assert.ExpectedError(BOPUserAccountIDMissingErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure CreateVIESELMA_BenutzerkontoIDInXml()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 623220] VIES ELMA XML contains BenutzerkontoID matching the configured BOP User Account ID
        Initialize();

        // [GIVEN] VAT Report with BOP User Account ID configured
        // [WHEN] VAT Report is exported into XML
        CreateVATReport(VATReportHeader, TestPeriodStart, TestPeriodEnd, TempBlob);

        // [THEN] BenutzerkontoID node contains the configured BOP User Account ID
        InitXMLReaderForVIESReport(TempBlob);
        VATReportSetup.Get();
        LibraryXPathXMLReader.VerifyXmlNodeValue('//elan:ELMAHeader/elan:BenutzerkontoID', VATReportSetup."BOP User Account ID");

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure CreateVIESELMA_FileIDMatchesEingangsID()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportExport: Codeunit "VAT Report Export";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        FileID: Text;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 623220] FileID returned from Create matches EingangsID in the generated XML
        Initialize();

        // [GIVEN] Released VAT Report "VR" with VAT Registration No. and period data
        SetupVATReportScenario(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        // [WHEN] CreateVIESELMAXml is called
        VATReportExport.CreateVIESELMAXml(VATReportHeader, FileID, TempBlob);

        // [THEN] EingangsID in ELMA header matches the returned FileID
        InitXMLReaderForVIESReport(TempBlob);
        LibraryXPathXMLReader.VerifyXmlNodeValue('//elan:ELMAHeader/elan:Identifizierung/elan:EingangsID', FileID);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure CreateVIESELMA_FileIDInFileName()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
        VATReportExport: Codeunit "VAT Report Export";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        FileName: Text;
        FileID: Text;
        ExpectedFileName: Text;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 623220] FileID from Create is used in file name from GetVIESELMAFileName
        Initialize();

        // [GIVEN] Released VAT Report "VR" with VAT Registration No. and period data
        SetupVATReportScenario(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        // [WHEN] CreateVIESELMAXml returns FileID and GetVIESELMAFileName uses it
        VATReportExport.CreateVIESELMAXml(VATReportHeader, FileID, TempBlob);
        FileName := VATReportExport.GetVIESELMAFileName(VATReportHeader, FileID);

        // [THEN] File name is ZMDO.<BOPUserAccountID>.<FileID>.xml
        VATReportSetup.Get();
        ExpectedFileName := StrSubstNo(VIESELMAFileNamePatternTxt, VATReportSetup."BOP User Account ID", FileID);
        Assert.AreEqual(ExpectedFileName, FileName, 'File name must contain the FileID from Create.');

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    procedure ExportVATReportVerifyFileName()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
        VATReportExport: Codeunit "VAT Report Export";
        TempBlob: Codeunit "Temp Blob";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
        FileName: Text;
        FileID: Text;
        ExpectedFileName: Text;
    begin
        // [FEATURE] [AI test] [UT]
        // [SCENARIO 613377] GetVIESELMAFileName returns file name ZMDO.<BenutzerkontoID>.<FileID>.xml
        Initialize();

        // [GIVEN] VAT Report "VR" with VAT Registration No. and period data
        SetupVATReportScenario(VATReportHeader, TestPeriodStart, TestPeriodEnd);

        // [WHEN] CreateVIESELMAXml is called to get the FileID, then GetVIESELMAFileName is called
        VATReportExport.CreateVIESELMAXml(VATReportHeader, FileID, TempBlob);
        FileName := VATReportExport.GetVIESELMAFileName(VATReportHeader, FileID);

        // [THEN] File name matches expected format ZMDO.<BenutzerkontoID>.<FileID>.xml
        VATReportSetup.Get();
        ExpectedFileName := StrSubstNo(VIESELMAFileNamePatternTxt, VATReportSetup."BOP User Account ID", FileID);
        Assert.AreEqual(ExpectedFileName, FileName, StrSubstNo(FileNamePatternMismatchErr, ExpectedFileName, FileName));

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        DeleteAllVATReports();
        if IsInitialized then
            exit;

        InitializeVATReportSetup();
        InitializeCompanyInformation();
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"VAT Report Setup");
        IsInitialized := true;
    end;

    local procedure InitializeVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        if not VATReportSetup.Get() then
            VATReportSetup.Insert();

        VATReportSetup.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        VATReportSetup.Validate("Modify Submitted Reports", false);
        VATReportSetup."BOP User Account ID" := '1234567890';
        VATReportSetup.Modify();
    end;

    local procedure InitializeCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        PostCode: Record "Post Code";
    begin
        PostCode.Validate(Code, LibraryUtility.GenerateGUID());
        PostCode.Validate(City, LibraryUtility.GenerateGUID());
        PostCode.Validate("Country/Region Code", CreateCountryRegion());
        PostCode.Insert();
        CompanyInformation.Get();
        CompanyInformation.Validate("Post Code", PostCode.Code);
        CompanyInformation.Modify();
    end;

    local procedure InitXMLReaderForVIESReport(var TempBlob: Codeunit "Temp Blob")
    begin
        LibraryXPathXMLReader.InitializeXml(TempBlob, 'n1', 'http://www.itzbund.de/elan');
        LibraryXPathXMLReader.AddAdditionalXmlNamespace('elan', 'http://www.itzbund.de/elan/elemente');
        LibraryXPathXMLReader.AddAdditionalXmlNamespace('zm', 'http://www.itzbund.de/ZM/01');
    end;

    local procedure UpdateCompanyInformation(CompanyName: Text[100]; CompanyAddress: Text[30]; CompanyCity: Text[30])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate(Name, CompanyName);
        CompanyInformation.Validate(Address, CompanyAddress);
        CompanyInformation.Validate(City, CompanyCity);
        CompanyInformation.Modify();
    end;

    local procedure UpdateVATReportSetup(CompanyName: Text[100]; CompanyAddress: Text[30]; CompanyCity: Text[30])
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup.Validate("Company Name", CompanyName);
        VATReportSetup.Validate("Company Address", CompanyAddress);
        VATReportSetup.Validate("Company City", CompanyCity);
        VATReportSetup.Modify();
    end;

    local procedure SetupExportCancellationLines(ExportCancellationLines: Boolean)
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup.Validate("Export Cancellation Lines", ExportCancellationLines);
        VATReportSetup.Modify();
    end;

    local procedure Cleanup(VATReportNo: Code[20]; TestPeriodStart: Date; TestPeriodEnd: Date)
    begin
        DeleteVATReport(VATReportNo);
        DeleteVATEntries(TestPeriodStart, TestPeriodEnd);
    end;

    local procedure DeleteVATReport(VATReportNo: Code[20])
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        VATReportHeader.Get(VATReportNo);
        VATReportHeader.Delete();

        VATReportLine.SetRange("VAT Report No.", VATReportNo);
        VATReportLine.DeleteAll();
        VATReportLineRelation.SetRange("VAT Report No.", VATReportNo);
        VATReportLineRelation.DeleteAll();
    end;

    local procedure DeleteVATEntries(TestPeriodStart: Date; TestPeriodEnd: Date)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("VAT Reporting Date", TestPeriodStart, TestPeriodEnd);
        VATEntry.DeleteAll(true);
    end;

    local procedure DeleteAllVATReports()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        VATReportHeader.DeleteAll();
        VATReportLine.DeleteAll();
        VATReportLineRelation.DeleteAll();
    end;

    local procedure SetupVATReportScenario(var VATReportHeader: Record "VAT Report Header"; var TestPeriodStart: Date; var TestPeriodEnd: Date)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        SetupVATReportScenarioWithVATRegNo(VATReportHeader, TestPeriodStart, TestPeriodEnd, '', CompanyInformation."VAT Registration No.");
    end;

    local procedure SetupVATReportScenarioWithVATRegNo(var VATReportHeader: Record "VAT Report Header"; var TestPeriodStart: Date; var TestPeriodEnd: Date; CountryCode: Code[10]; VATRegNo: Text[20])
    var
        NoOfEntries: Integer;
    begin
        FindFirstMonthWithoutVATEntries(TestPeriodStart, TestPeriodEnd);

        NoOfEntries := LibraryRandom.RandIntInRange(2, 5);

        CreateVATEntries(NoOfEntries, CalcDate('<-1M>', TestPeriodStart), CalcDate('<-1D>', TestPeriodStart), CountryCode, VATRegNo, true);
        CreateVATEntries(NoOfEntries, TestPeriodStart, TestPeriodEnd, CountryCode, VATRegNo, true);

        CreateAndReleaseVATReport(VATReportHeader, TestPeriodStart);
    end;

    local procedure SetupVATReportScenarioOpen(var VATReportHeader: Record "VAT Report Header"; var TestPeriodStart: Date; var TestPeriodEnd: Date)
    var
        CompanyInformation: Record "Company Information";
        NoOfEntries: Integer;
    begin
        CompanyInformation.Get();
        FindFirstMonthWithoutVATEntries(TestPeriodStart, TestPeriodEnd);
        NoOfEntries := LibraryRandom.RandIntInRange(2, 5);
        CreateVATEntries(NoOfEntries, TestPeriodStart, TestPeriodEnd, '', CompanyInformation."VAT Registration No.", true);
        CreateVATReport(
            VATReportHeader."VAT Report Type"::Standard,
            VATReportHeader."Report Period Type"::Month,
            Date2DMY(TestPeriodStart, 2),
            Date2DMY(TestPeriodStart, 3),
            VATReportHeader);

        VATReportHeader.SetRange("No.", VATReportHeader."No.");
        VATReportHeader.FindFirst();
    end;

    local procedure SetupVATReportScenarioZeroBase(var VATReportHeader: Record "VAT Report Header"; var TestPeriodStart: Date; var TestPeriodEnd: Date)
    begin
        FindFirstMonthWithoutVATEntries(TestPeriodStart, TestPeriodEnd);

        CreateMockVATEntriesForSalesDocument(
          LibraryRandom.RandIntInRange(5, 10), TestPeriodStart, TestPeriodEnd,
          0, LibraryUtility.GenerateGUID());

        CreateAndReleaseVATReport(VATReportHeader, TestPeriodStart);
    end;

    local procedure SetupCorrectiveVATReportScenario(var VATReportHeader: Record "VAT Report Header"; var TestPeriodStart: Date; var TestPeriodEnd: Date)
    var
        VATReportLine: Record "VAT Report Line";
        VATReportHeaderCorrective: Record "VAT Report Header";
        VATRegNo: Text[20];
    begin
        FindFirstMonthWithoutVATEntries(TestPeriodStart, TestPeriodEnd);

        VATRegNo := LibraryUtility.GenerateGUID();
        CreateVATEntries(LibraryRandom.RandIntInRange(2, 5), TestPeriodStart, TestPeriodEnd, CreateCountryRegion(), VATRegNo, true);
        CreateVATEntries(LibraryRandom.RandIntInRange(2, 5), TestPeriodStart, TestPeriodEnd, CreateCountryRegion(), VATRegNo, false);

        CreateVATReport(
          VATReportHeader."VAT Report Type"::Standard,
          VATReportHeader."Report Period Type"::Month,
          Date2DMY(TestPeriodStart, 2),
          Date2DMY(TestPeriodStart, 3),
          VATReportHeader);
        FindLastReportLine(VATReportHeader."No.", VATReportLine."Line Type"::New, VATReportLine);
        VATReportLine.Delete(true);
        SubmitVATReport(VATReportHeader);

        CreateCorrectiveVATReportHeader(VATReportHeader, VATReportHeaderCorrective);
        SuggestVATReportLines(VATReportHeaderCorrective."No.");
        VATReportMediator.CorrectLines(VATReportHeaderCorrective);
        SubmitVATReport(VATReportHeaderCorrective);

        VATReportHeader := VATReportHeaderCorrective;
    end;

    local procedure SetupVatReportScenario_SubmitReport(var VATReportHeader: Record "VAT Report Header"; var TestPeriodStart: Date; var TestPeriodEnd: Date)
    begin
        SetupVATReportScenario(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        SubmitVATReport(VATReportHeader);
        VATReportHeader.Get(VATReportHeader."No.");
    end;

    local procedure CreateAndReleaseVATReport(var VATReportHeader: Record "VAT Report Header"; TestPeriodStart: Date)
    begin
        CreateVATReport(
            VATReportHeader."VAT Report Type"::Standard,
            VATReportHeader."Report Period Type"::Month,
            Date2DMY(TestPeriodStart, 2),
            Date2DMY(TestPeriodStart, 3),
            VATReportHeader);
        VATReportMediator.Release(VATReportHeader);

        VATReportHeader.SetRange("No.", VATReportHeader."No.");
        VATReportHeader.FindFirst();
    end;

    local procedure SuggestLines_StandardReport_VerifyFieldGrouping(ChangedFieldNo: Integer)
    var
        VATReportHeader: Record "VAT Report Header";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        FindFirstMonthWithoutVATEntries(TestPeriodStart, TestPeriodEnd);
        InitVATEntriesGroupingScenario(LibraryRandom.RandIntInRange(2, 5), ChangedFieldNo, TestPeriodStart, TestPeriodEnd);
        CreateVATReport(
            VATReportHeader."VAT Report Type"::Standard,
            VATReportHeader."Report Period Type"::Month,
            Date2DMY(TestPeriodStart, 2),
            Date2DMY(TestPeriodStart, 3),
            VATReportHeader);

        VerifyVATReportLines(VATReportHeader."No.", 2);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    local procedure InitVATEntriesGroupingScenario(NoOfEntries: Integer; VariationFieldNo: Integer; TestPeriodStart: Date; TestPeriodEnd: Date)
    var
        VATReportLine: Record "VAT Report Line";
        CountryCode: Code[10];
        VATRegNo: Text[20];
        EU3PartyTrade: Boolean;
    begin
        CountryCode := CreateCountryRegion();
        VATRegNo := LibraryUtility.GenerateRandomCode(VATReportLine.FieldNo("VAT Registration No."), DATABASE::"VAT Entry");
        EU3PartyTrade := false;

        // Create the first group of entries
        CreateVATEntries(NoOfEntries, TestPeriodStart, TestPeriodEnd, CountryCode, VATRegNo, EU3PartyTrade);

        // Change the value of the given field
        case VariationFieldNo of
            VATReportLine.FieldNo("Country/Region Code"):
                CountryCode := CreateCountryRegion();
            VATReportLine.FieldNo("VAT Registration No."):
                VATRegNo := LibraryUtility.GenerateRandomCode(VATReportLine.FieldNo("VAT Registration No."), DATABASE::"VAT Report Line");
            VATReportLine.FieldNo("EU 3-Party Trade"):
                EU3PartyTrade := not EU3PartyTrade;
        end;

        // Create the second group of entries
        CreateVATEntries(NoOfEntries, TestPeriodStart, TestPeriodEnd, CountryCode, VATRegNo, EU3PartyTrade);
    end;

    local procedure GetNextVATEntryNo(): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        if VATEntry.FindLast() then
            exit(VATEntry."Entry No." + 1);

        exit(1);
    end;

    local procedure CreateVATEntries(NoOfEntries: Integer; MinDate: Date; MaxDate: Date; CountryCode: Code[10]; VATRegNo: Text[20]; EU3PartyTrade: Boolean)
    var
        i: Integer;
    begin
        for i := 1 to NoOfEntries do
            CreateOneVATEntry(
              GetNextVATEntryNo(),
              LibraryUtility.GenerateRandomDate(MinDate, MaxDate),
              CountryCode,
              VATRegNo,
              EU3PartyTrade, false);
    end;

    local procedure CreateOneVATEntry(EntryNo: Integer; PostingDate: Date; CountryCode: Code[10]; VATRegNo: Text[20]; EU3PartyTrade: Boolean; IsPurchase: Boolean)
    var
        VATEntry: Record "VAT Entry";
    begin
        if CountryCode = '' then
            CountryCode := CreateCountryRegion();
        if VATRegNo = '' then
            VATRegNo := LibraryUtility.GenerateRandomCode(VATEntry.FieldNo("VAT Registration No."), DATABASE::"VAT Entry");

        VATEntry.Validate("Entry No.", EntryNo);
        VATEntry.Validate("Posting Date", PostingDate);
        VATEntry.Validate("VAT Reporting Date", PostingDate);
        if IsPurchase then
            VATEntry.Validate(Type, VATEntry.Type::Purchase)
        else
            VATEntry.Validate(Type, VATEntry.Type::Sale);
        VATEntry.Validate("Country/Region Code", CountryCode);
        VATEntry.Validate("VAT Registration No.", VATRegNo);
        VATEntry.Validate("EU 3-Party Trade", EU3PartyTrade);
        VATEntry.Validate(Base, LibraryRandom.RandDecInRange(1, 10000, 2));
        VATEntry.Validate(Amount, LibraryRandom.RandDecInRange(1, 10000, 2));

        VATEntry.Insert(true);
    end;

    local procedure CreateMockVATEntryForSalesDocument(PostingDate: Date; VATBase: Decimal; VATAmount: Integer; CountryCode: Code[10]; VATRegNo: Text[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Validate("Entry No.", GetNextVATEntryNo());
        VATEntry.Validate("Posting Date", PostingDate);
        VATEntry.Validate("VAT Reporting Date", PostingDate);
        VATEntry.Validate(Type, VATEntry.Type::Sale);
        VATEntry.Validate("Country/Region Code", CountryCode);
        VATEntry.Validate("VAT Registration No.", VATRegNo);
        VATEntry.Validate("EU 3-Party Trade", false);
        VATEntry.Validate(Base, VATBase);
        VATEntry.Validate(Amount, VATAmount);

        VATEntry.Insert(true);
    end;

    local procedure CreateMockVATEntriesForSalesDocument(NoOfEntries: Integer; MinDate: Date; MaxDate: Date; VATPercent: Decimal; VATRegNo: Text[20])
    var
        VATBase: Decimal;
        VATAmount: Decimal;
        PostingDate: Date;
        CountryCode: Code[10];
    begin
        while NoOfEntries > 0 do begin
            NoOfEntries -= 1;
            VATBase := LibraryRandom.RandDec(1000, 2);
            VATAmount := Round(VATBase * VATPercent / 100);
            PostingDate := LibraryUtility.GenerateRandomDate(MinDate, MaxDate);
            CountryCode := CreateCountryRegion();
            CreateMockVATEntryForSalesDocument(
              PostingDate, -VATBase, -VATAmount, CountryCode, VATRegNo);
            CreateMockVATEntryForSalesDocument(
              PostingDate, VATBase, VATAmount, CountryCode, VATRegNo);
        end;
    end;

    local procedure CreateVATReport(VATReportType: Option Standard,Corrective; ReportPeriodType: Option; ReportPeriodNo: Integer; ReportYear: Integer; var VATReportHeader: Record "VAT Report Header"): Code[20]
    begin
        CreateVATReportHeader(VATReportHeader, VATReportType, ReportPeriodType, ReportPeriodNo, ReportYear);
        SuggestVATReportLines(VATReportHeader."No.");

        exit(VATReportHeader."No.");
    end;

    local procedure CreateVATReportHeader(var VATReportHeader: Record "VAT Report Header"; VATReportType: Option Standard,Corrective; ReportPeriodType: Option " ",Month,Quarter; ReportPeriodNo: Integer; ReportYear: Integer)
    begin
        VATReportHeader.Init();
        VATReportHeader.Insert(true);

        VATReportHeader."Report Period No." := 0;
        VATReportHeader.Validate("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code"::VIES);
        VATReportHeader.Validate("VAT Report Type", VATReportType);
        VATReportHeader."Report Period Type" := ReportPeriodType;
        VATReportHeader."Report Period No." := ReportPeriodNo;
        VATReportHeader.Validate("Report Year", ReportYear);
        VATReportHeader.Validate("Processing Date", VATReportHeader."End Date");
        VATReportHeader.Modify(true);
    end;

    local procedure CreateMockVATReportLine(VATReportNo: Code[20])
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportLine.Init();
        VATReportLine."VAT Report No." := VATReportNo;
        VATReportLine."Line No." := 1;
        VATReportLine."Country/Region Code" := CreateCountryRegion();
        VATReportLine."VAT Registration No." := LibraryUtility.GenerateRandomCode(VATReportLine.FieldNo("VAT Registration No."), DATABASE::"VAT Report Line");
        VATReportLine.Base := LibraryRandom.RandDec(10000, 2);
        VATReportLine.Amount := LibraryRandom.RandDec(10000, 2);

        VATReportLine.Insert();
    end;

    local procedure CreateMockReportRelationLine(VATReportNo: Code[20])
    var
        VATReportLine: Record "VAT Report Line";
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        VATReportLine.SetRange("VAT Report No.", VATReportNo);
        if VATReportLine.FindSet() then
            repeat
                VATReportLineRelation.Init();
                VATReportLineRelation."VAT Report No." := VATReportNo;
                VATReportLineRelation."VAT Report Line No." := VATReportLine."Line No.";
                VATReportLineRelation."Table No." := DATABASE::"VAT Entry";
                VATReportLineRelation."Entry No." := 1;
                VATReportLineRelation.Insert();
            until VATReportLine.Next() = 0;
    end;

    local procedure CreateMockVATReportWithLines(var VATReportHeader: Record "VAT Report Header"; ReportType: Option; ReportPeriodType: Option; ReportPeriodNo: Integer)
    begin
        CreateVATReportHeader(VATReportHeader, ReportType, ReportPeriodType, ReportPeriodNo, CurrYear());
        CreateMockVATReportLine(VATReportHeader."No.");
        CreateMockReportRelationLine(VATReportHeader."No.");
    end;

    local procedure CreateStandardMonthReport(var VATReportHeader: Record "VAT Report Header")
    begin
        CreateMockVATReportWithLines(VATReportHeader, VATReportHeader."VAT Report Type"::Standard, VATReportHeader."Report Period Type"::Month, Date2DMY(WorkDate(), 2));
    end;

    local procedure CreateMockVATReport_SetFieldValue(VATReportPart: Option Header,Line; ValidatedFieldNo: Integer; FieldValue: Variant): Code[20]
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        RecRef: RecordRef;
        ReportFieldRef: FieldRef;
    begin
        CreateMockVATReportWithLines(VATReportHeader, VATReportHeader."VAT Report Type"::Standard, VATReportHeader."Report Period Type"::Year, 1);

        case VATReportPart of
            VATReportPart::Header:
                RecRef.GetTable(VATReportHeader);
            VATReportPart::Line:
                begin
                    VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
                    VATReportLine.FindFirst();
                    RecRef.GetTable(VATReportLine);
                end;
        end;

        ReportFieldRef := RecRef.Field(ValidatedFieldNo);
        ReportFieldRef.Value := FieldValue;
        RecRef.Modify();

        exit(VATReportHeader."No.");
    end;

    local procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);

        CountryRegion.Validate("EU Country/Region Code", LibraryUtility.GenerateRandomAlphabeticText(2, 0));
        CountryRegion.Validate("ISO Code", LibraryUtility.GenerateRandomAlphabeticText(2, 0));
        CountryRegion.Modify(true);

        exit(CountryRegion.Code);
    end;

    local procedure CalcVATAmount(CountryCode: Code[10]; VATRegNo: Text[20]; EU3PartyTrade: Boolean): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.SetRange("Country/Region Code", CountryCode);
        VATEntry.SetRange("VAT Registration No.", VATRegNo);
        VATEntry.SetRange("EU 3-Party Trade", EU3PartyTrade);

        VATEntry.CalcSums(Base);
        exit(-Round(VATEntry.Base, 1));
    end;

    local procedure VerifyVATReportLines(VATReportNo: Code[20]; NoOfLinesExpected: Integer)
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportHeader.Get(VATReportNo);

        VATReportLine.SetRange("VAT Report No.", VATReportNo);
        Assert.AreEqual(NoOfLinesExpected, VATReportLine.Count, IncorrectNoOfReportLinesErr);

        if VATReportLine.FindSet() then
            repeat
                Assert.AreEqual(
                  VATReportLine.Base,
                  CalcVATAmount(VATReportLine."Country/Region Code", VATReportLine."VAT Registration No.", VATReportLine."EU 3-Party Trade"),
                  IncorrectVATReportLineAmtErr);
            until VATReportLine.Next() = 0;
    end;

    local procedure CreateVATReport(var VATReportHeader: Record "VAT Report Header"; var TestPeriodStart: Date; var TestPeriodEnd: Date; var TempBlob: Codeunit "Temp Blob")
    begin
        SetupVATReportScenario(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        ExportVATReportIntoTempBlob(VATReportHeader, TempBlob);
    end;

    local procedure CreateVATReportWithNotice(var VATReportHeader: Record "VAT Report Header"; var TestPeriodStart: Date; var TestPeriodEnd: Date; var TempBlob: Codeunit "Temp Blob"; Notice: Boolean)
    begin
        SetupVATReportScenario(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VATReportHeader.Notice := Notice;
        VATReportHeader.Modify();
        ExportVATReportIntoTempBlob(VATReportHeader, TempBlob);
    end;

    local procedure CreateVATReportWithRevocation(var VATReportHeader: Record "VAT Report Header"; var TestPeriodStart: Date; var TestPeriodEnd: Date; var TempBlob: Codeunit "Temp Blob"; Revocation: Boolean)
    begin
        SetupVATReportScenario(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VATReportHeader.Revocation := Revocation;
        VATReportHeader.Modify();
        ExportVATReportIntoTempBlob(VATReportHeader, TempBlob);
    end;

    local procedure CreateVATReportWithTestExport(var VATReportHeader: Record "VAT Report Header"; var TestPeriodStart: Date; var TestPeriodEnd: Date; var TempBlob: Codeunit "Temp Blob"; TestExport: Boolean)
    begin
        SetupVATReportScenario(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VATReportHeader."Test Export" := TestExport;
        VATReportHeader.Modify();
        ExportVATReportIntoTempBlob(VATReportHeader, TempBlob);
    end;

    local procedure CreateVATReportWithTurnoverType(var VATReportHeader: Record "VAT Report Header"; var TempBlob: Codeunit "Temp Blob"; EUService: Boolean; EU3PartyTrade: Boolean)
    var
        VATReportLine: Record "VAT Report Line";
    begin
        CreateMockVATReportWithLines(VATReportHeader, VATReportHeader."VAT Report Type"::Standard, VATReportHeader."Report Period Type"::Month, 1);
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.FindFirst();
        VATReportLine."EU Service" := EUService;
        VATReportLine."EU 3-Party Trade" := EU3PartyTrade;
        VATReportLine.Modify();
        ExportVATReportIntoTempBlob(VATReportHeader, TempBlob);
    end;

    local procedure CreateVATReportWithPeriodType(var VATReportHeader: Record "VAT Report Header"; var TempBlob: Codeunit "Temp Blob"; ReportPeriodType: Option " ",Month,Quarter,Year,"Bi-Monthly"; ReportPeriodNo: Integer)
    begin
        CreateMockVATReportWithLines(VATReportHeader, VATReportHeader."VAT Report Type"::Standard, ReportPeriodType, ReportPeriodNo);
        ExportVATReportIntoTempBlob(VATReportHeader, TempBlob);
    end;

    local procedure CreateVATReportWithMultipleLines(var VATReportHeader: Record "VAT Report Header"; var TestPeriodStart: Date; var TestPeriodEnd: Date; var TempBlob: Codeunit "Temp Blob")
    var
        VATReportLine: Record "VAT Report Line";
    begin
        FindFirstMonthWithoutVATEntries(TestPeriodStart, TestPeriodEnd);
        InitVATEntriesGroupingScenario(LibraryRandom.RandIntInRange(2, 5), VATReportLine.FieldNo("VAT Registration No."), TestPeriodStart, TestPeriodEnd);
        CreateVATReport(
            VATReportHeader."VAT Report Type"::Standard,
            VATReportHeader."Report Period Type"::Month,
            Date2DMY(TestPeriodStart, 2),
            Date2DMY(TestPeriodStart, 3),
            VATReportHeader);
        ExportVATReportIntoTempBlob(VATReportHeader, TempBlob);
    end;

    local procedure CreateVATReportZeroBase(var VATReportHeader: Record "VAT Report Header"; var TestPeriodStart: Date; var TestPeriodEnd: Date; var TempBlob: Codeunit "Temp Blob")
    begin
        SetupVATReportScenarioZeroBase(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        ExportVATReportIntoTempBlob(VATReportHeader, TempBlob);
    end;

    local procedure CreateCorrectiveVATReport(var VATReportHeader: Record "VAT Report Header"; var TestPeriodStart: Date; var TestPeriodEnd: Date; var TempBlob: Codeunit "Temp Blob")
    begin
        SetupCorrectiveVATReportScenario(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        ExportVATReportIntoTempBlob(VATReportHeader, TempBlob);
    end;

    local procedure CreateCorrectiveVATReportHeader(OrigVATReportHeader: Record "VAT Report Header"; var CorrVATReportHeader: Record "VAT Report Header")
    begin
        CreateVATReportHeader(
            CorrVATReportHeader,
            OrigVATReportHeader."VAT Report Type"::Corrective,
            OrigVATReportHeader."Report Period Type",
            OrigVATReportHeader."Report Period No.",
            OrigVATReportHeader."Report Year");

        CorrVATReportHeader.Validate("Original Report No.", OrigVATReportHeader."No.");
        CorrVATReportHeader.Modify(true);
    end;

    local procedure CreateCorrectiveReport(VATReportHeader: Record "VAT Report Header"; var CorrVATReportHeader: Record "VAT Report Header")
    begin
        CreateCorrectiveVATReportHeader(VATReportHeader, CorrVATReportHeader);
        RunCorrectVATReportLines(CorrVATReportHeader."No.");
    end;

    local procedure CurrYear(): Integer
    begin
        exit(Date2DMY(WorkDate(), 3));
    end;

    local procedure FindFirstMonthWithoutVATEntries(var TestPeriodStart: Date; var TestPeriodEnd: Date)
    var
        AccPeriod: Record "Accounting Period";
        DateRec: Record Date;
    begin
        // Taking a month outside of accounting periods, as it for sure doesn't have posted entries
        AccPeriod.FindFirst();
        DateRec.SetRange("Period Type", DateRec."Period Type"::Month);
        DateRec.SetFilter("Period Start", '<%1', AccPeriod."Starting Date");
        DateRec.FindLast();

        TestPeriodStart := DateRec."Period Start";
        TestPeriodEnd := NormalDate(DateRec."Period End");
    end;

    local procedure VerifyReportRelationLineExistsForEachVATEntry(VATReportNo: Code[20]; TestPeriodStart: Date; TestPeriodEnd: Date; VATRegNo: Text[20]; CountryCode: Code[10])
    var
        VATReportLineRelation: Record "VAT Report Line Relation";
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("VAT Reporting Date", TestPeriodStart, TestPeriodEnd);
        VATEntry.SetRange("VAT Registration No.", VATRegNo);
        VATEntry.SetRange("Country/Region Code", CountryCode);
        VATEntry.FindSet();
        repeat
            VATReportLineRelation.SetRange("VAT Report No.", VATReportNo);
            VATReportLineRelation.SetRange("Entry No.", VATEntry."Entry No.");
            Assert.IsFalse(VATReportLineRelation.IsEmpty, ReportLineRelationNotFoundErr);
        until VATEntry.Next() = 0;
    end;

    local procedure GetNumberOfVATEntryRelations(VATReportNo: Code[20]; LineNo: Integer): Integer
    var
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        VATReportLineRelation.SetRange("VAT Report No.", VATReportNo);
        VATReportLineRelation.SetRange("VAT Report Line No.", LineNo);
        exit(VATReportLineRelation.Count);
    end;

    local procedure ExportVATReportIntoTempBlob(var VATReportHeader: Record "VAT Report Header"; var TempBlob: Codeunit "Temp Blob")
    var
        VATReportExport: Codeunit "VAT Report Export";
        FileID: Text;
    begin
        VATReportExport.CreateVIESELMAXml(VATReportHeader, FileID, TempBlob);
    end;

    local procedure CorrectionLineExists(VATReportNo: Code[20]; LineType: Option New,Cancellation,Correction): Boolean
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportLine.SetRange("VAT Report No.", VATReportNo);
        VATReportLine.SetRange("Line Type", LineType);
        exit(not VATReportLine.IsEmpty);
    end;

    local procedure FindFirstReportLine(VATReportNo: Code[20]; LineType: Option New,Cancellation,Correction; var VATReportLine: Record "VAT Report Line")
    begin
        VATReportLine.SetRange("VAT Report No.", VATReportNo);
        VATReportLine.SetRange("Line Type", LineType);
        VATReportLine.FindFirst();
    end;

    local procedure FindLastReportLine(VATReportNo: Code[20]; LineType: Option New,Cancellation,Correction; var VATReportLine: Record "VAT Report Line")
    begin
        VATReportLine.SetRange("VAT Report No.", VATReportNo);
        VATReportLine.SetRange("Line Type", LineType);
        VATReportLine.FindLast();
    end;

    local procedure VerifyOriginalReportPeriodTransferred(var VATReportPage: TestPage "VAT Report"; var VATReportHeader: Record "VAT Report Header")
    begin
        Assert.AreEqual(VATReportPage."Start Date".AsDate(), VATReportHeader."Start Date", ReportingPeriodNotTransferredErr);
        Assert.AreEqual(VATReportPage."End Date".AsDate(), VATReportHeader."End Date", ReportingPeriodNotTransferredErr);
        Assert.AreEqual(VATReportPage."Report Period Type".AsInteger(), VATReportHeader."Report Period Type", ReportingPeriodNotTransferredErr);
        Assert.AreEqual(VATReportPage."Report Period No.".AsInteger(), VATReportHeader."Report Period No.", ReportingPeriodNotTransferredErr);
        Assert.AreEqual(VATReportPage."Report Year".AsInteger(), VATReportHeader."Report Year", ReportingPeriodNotTransferredErr);
    end;

    local procedure SetVATReportPeriodTypeVerifyDate(PeriodType: Option ,Month,Quarter,Year,"Bi-Monthly"; PeriodNo: Integer)
    var
        VATReportHeader: Record "VAT Report Header";
        ExpectedStartDate: Date;
        ExpectedEndDate: Date;
        Year: Integer;
    begin
        Year := CurrYear();
        case PeriodType of
            PeriodType::Month:
                begin
                    ExpectedStartDate := DMY2Date(1, PeriodNo, Year);
                    ExpectedEndDate := CalcDate('<CM>', ExpectedStartDate);
                end;
            PeriodType::Quarter:
                begin
                    ExpectedStartDate := DMY2Date(1, PeriodNo * 3 - 2, Year);
                    ExpectedEndDate := CalcDate('<CQ>', ExpectedStartDate);
                end;
            PeriodType::Year:
                begin
                    ExpectedStartDate := DMY2Date(1, 1, Year);
                    ExpectedEndDate := DMY2Date(31, 12, Year);
                end;
            PeriodType::"Bi-Monthly":
                begin
                    ExpectedStartDate := DMY2Date(1, PeriodNo * 3 - 2, Year);
                    ExpectedEndDate := CalcDate('<CM + 1M>', ExpectedStartDate);
                end;
        end;

        VATReportHeader.Init();
        VATReportHeader.Validate("Report Year", CurrYear());
        VATReportHeader.Validate("Report Period Type", PeriodType);
        VATReportHeader.Validate("Report Period No.", PeriodNo);

        Assert.IsTrue((ExpectedStartDate = VATReportHeader."Start Date") and (ExpectedEndDate = VATReportHeader."End Date"), ReportPeriodValidatedIncorrectlyErr);
    end;

    local procedure SetIncorrectFieldValue_ValidateReport(VATReportPart: Option Header,Line; ValidatedFieldNo: Integer; FieldValue: Variant)
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VATReportHeader.Get(CreateMockVATReport_SetFieldValue(VATReportPart, ValidatedFieldNo, FieldValue));

        VariableStorage.Enqueue(
          StrSubstNo(
            FieldMustBeFilledErr,
            GetVATReportFieldCaption(VATReportPart, ValidatedFieldNo),
            GetVATReportPartCaption(VATReportPart)));
        asserterror CODEUNIT.Run(CODEUNIT::"VAT Report Validate", VATReportHeader);
        Assert.AreEqual('', GetLastErrorText, IncorectMsgInErrorLogErr);
    end;

    local procedure MockVATReportExport(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.Status := VATReportHeader.Status::Exported;
        VATReportHeader.Modify();
    end;

    local procedure SubmitVATReport(var VATReportHeader: Record "VAT Report Header")
    begin
        if VATReportHeader.Status = VATReportHeader.Status::Open then begin
            VATReportMediator.Release(VATReportHeader);
            VATReportHeader.Get(VATReportHeader."No.");
        end;

        MockVATReportExport(VATReportHeader);
        VATReportMediator.Submit(VATReportHeader);
    end;

    local procedure SuggestVATReportLines(VATReportNo: Code[20])
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VATReportHeader.SetRange("No.", VATReportNo);
        REPORT.RunModal(REPORT::"VAT Report Suggest Lines", false, false, VATReportHeader);
    end;

    local procedure SetCompanyInformationAddress(NewAddress: Text[50])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Address := NewAddress;
        CompanyInformation.Modify();
    end;

    local procedure RunCorrectVATReportLines(VATReportNo: Code[20])
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VATReportHeader.Get(VATReportNo);
        VATReportMediator.CorrectLines(VATReportHeader);
    end;

    local procedure InitVATReportRecRef(VATReportPart: Option Header,Line; var RecRef: RecordRef)
    begin
        case VATReportPart of
            VATReportPart::Header:
                RecRef.Open(DATABASE::"VAT Report Header");
            VATReportPart::Line:
                RecRef.Open(DATABASE::"VAT Report Line");
        end;
    end;

    local procedure GetVATReportPartCaption(VATReportPart: Option Header,Line): Text
    var
        RecRef: RecordRef;
    begin
        InitVATReportRecRef(VATReportPart, RecRef);
        exit(RecRef.Caption);
    end;

    local procedure GetVATReportFieldCaption(VATReportPart: Option Header,Line; FieldNo: Integer): Text
    var
        RecRef: RecordRef;
        ReportFieldRef: FieldRef;
    begin
        InitVATReportRecRef(VATReportPart, RecRef);
        ReportFieldRef := RecRef.Field(FieldNo);
        exit(ReportFieldRef.Caption);
    end;

    [ModalPageHandler]
    procedure VATReportLinesListHandler(var VATRepLinesList: TestPage "VAT Report Lines")
    begin
        VATRepLinesList.Last();
        VATRepLinesList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure VATReportLinesValuesListHandler(var VATRepLinesList: TestPage "VAT Report Lines")
    begin
        VATRepLinesList.First();
        VariableStorage.Enqueue(Format(VATRepLinesList.Base));
        VATRepLinesList.Next();
        VariableStorage.Enqueue(Format(VATRepLinesList.Base));
        VATRepLinesList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure VATReportsLookupHandler(var VATReportList: TestPage "VAT Report List")
    var
        VATReportNo: Variant;
    begin
        VariableStorage.Dequeue(VATReportNo);
        VATReportList.GotoKey(VATReportNo);
        VATReportList.OK().Invoke();
    end;

    [PageHandler]
    procedure VATReportErrorLogHandler(var ErrorLogPage: TestPage "VAT Report Error Log")
    var
        ExpectedErrorText: Variant;
    begin
        VariableStorage.Dequeue(ExpectedErrorText);
        Assert.AreEqual(ExpectedErrorText, ErrorLogPage."Error Message".Value, IncorectMsgInErrorLogErr);
        ErrorLogPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure VATEntriesListHandler(var VATEntriesList: TestPage "VAT Entries")
    var
        VATBase: Decimal;
    begin
        VATEntriesList.First();
        repeat
            VATBase -= VATEntriesList.Base.AsDecimal();
        until not VATEntriesList.Next();

        VariableStorage.Enqueue(VATBase);
        VATEntriesList.OK().Invoke();
    end;

    local procedure VerifyVATReportHeaderCompanyInformation(VATReportHeader: Record "VAT Report Header")
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        Assert.AreEqual(VATReportSetup."Company Name", VATReportHeader."Company Name", VATReportHeader.FieldCaption("Company Name"));
        Assert.AreEqual(VATReportSetup."Company Address", VATReportHeader."Company Address", VATReportHeader.FieldCaption("Company Name"));
        Assert.AreEqual(VATReportSetup."Company City", VATReportHeader.City, VATReportHeader.FieldCaption(City));
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}