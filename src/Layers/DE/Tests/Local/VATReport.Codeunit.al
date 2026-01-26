codeunit 144001 "VAT Report"
{
    // -------------------------------------------------------------------------------------------------
    // Function Name                                                                         TFS ID
    // -------------------------------------------------------------------------------------------------
    // ExportVATReportVerifyNoOfLinesOnZeroBaseAmount                                        352584
    // ExportCorrectiveVATReportCancellationOn                                               352605
    // ExportCorrectiveVATReportCancellationOff                                              352605
    // CompanyNameAdressCity                                                                 352599

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Report]
    end;

    var
        ExportVIESReport: Report "Export VIES Report";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        FieldStartPositionsRecType0Tok: Label '1,2,8,16,61,86,91,116';
        FieldStartPositionsRecType1Tok: Label '1,2,13,15,19,33,45,46,48,50';
        FieldStartPositionsRecType2Tok: Label '1,2,13,17,31,36';
        FieldLengthsRecType0Tok: Label '1,6,8,45,25,5,25,5';
        FieldLengthsRecType1Tok: Label '1,11,2,4,14,12,1,2,2,71';
        FieldLengthsRecType2Tok: Label '1,11,4,14,5,85';
        RegistrationIDLbl: Label 'Registration ID';
        CreationDateLbl: Label 'Creation Date';
        NameLbl: Label 'Name';
        PostCodeLbl: Label 'Post Code';
        CompanyAddressLbl: Label 'Company Address';
        LocationLbl: Label 'Location';
        VATRegNoLbl: Label 'VAT Registration No.';
        TypeOfStatementLbl: Label 'Type of Statement';
        ECPartnerIDLbl: Label 'EC Partner VAT ID';
        AssessmentBasisLbl: Label 'Assessment basis';
        TypeOfTurnoverLbl: Label 'Type of turnover';
        NoticeLbl: Label 'Notice';
        RevocationLbl: Label 'Revocation';
        TotalAmtLbl: Label 'Total of the assessement bases';
        NoOfLinesLbl: Label 'Number of records of record type 1';
        ReportPeriodLbl: Label 'Reporting time period';
        IncorrectNoOfReportLinesErr: Label 'The number of report lines is incorrect.';
        IncorrectVATReportLineAmtErr: Label 'The amount in the VAT Report line is incorrect.';
        MandatoryFieldEmptyErr: Label 'Not all mandatory fields are filled in the report.';
        UnknownReportLineTypeErr: Label 'Unknown report line type (Report Type field = %1).';
        IncorrectReportFieldValueErr: Label 'The value of the field %1 in VAT Report is incorrect.';
        ReportNotSubmittedErr: Label 'VAT report was not submitted.';
        VATReportMediator: Codeunit "VAT Report Mediator";
        OriginalAmtMustBeZeroErr: Label 'Original amount must be 0 in corrective report.';
        IncorrectCorrectionAmtErr: Label 'Amount must be equal to %1 in corrective line.';
        LineCannotBeChangedErr: Label 'Cancellation line cannot be changed';
        NewValueIsNotSetErr: Label 'Amount in correction line must be editable.';
        IncorrectAmtInSecondCorrErr: Label 'Amount in the second correction must be initialized with the first correction amount.';
        ReportLineRelationNotFoundErr: Label 'VAT Report Line Relation does not exist.';
        NonEUCountryInReportErr: Label 'VAT entry for non-EU country must not be included in report.';
        CorrLinesNotCreatedErr: Label 'Correction lines were not created.';
        ReportLineMustBeDeletedErr: Label 'VAT Report Line must be deleted.';
        VariableStorage: Codeunit "Library - Variable Storage";
        ReportingPeriodNotTransferredErr: Label 'Reporing period data must be transferred into corrective report from the original report.';
        ReportPeriodValidatedIncorrectlyErr: Label 'VAT report period validated incorrectly.';
        FieldMustBeFilledErr: Label 'Field %1 should be filled in table %2.';
        IncorectMsgInErrorLogErr: Label 'Incorrect error message in error log.';
        IncorrectVATEntriesListErr: Label 'Detailed vat entries list is displayed incorrectly.';
        ErrorLogMustBeEmptyErr: Label 'No errors must be logged.';
        IncorrectAmountForExportErr: Label 'Amount for export formatted incorrectly.';
        IncorrectFileNameErr: Label 'Report file name is incorrect.';
        OddNoOfCorrLinesErr: Label 'Each cancellation line should have related corrective line.';
        CorrectionEntryAlreadyExistsErr: Label 'A correction entry already exists for this entry in report';
        InvalidCompanyNameTok: Label 'Name - Labé';
        InvalidCompanyAddressTok: Label 'Address - Labé';
        InvalidCompanyCityTok: Label 'City - Labé';
        ValidCompanyNameTok: Label 'Name - Labe';
        ValidCompanyAddressTok: Label 'Address - Labe';
        ValidCompanyCityTok: Label 'City - Labe';
        KeyAlreadyExistsErr: Label 'When you run the Suggest Lines action, it will add a VAT Report line for VAT Reg. No', Comment = 'A line of type = Correction already exists in the VAT Report. Remove the line to continue. Filters: VAT Registration No. = 12345';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
    procedure SetReportPeriodTypeYear_VerifyPeriodValidated()
    var
        PeriodType: Option ,Month,Quarter,Year,"Bi-Monthly";
    begin
        Initialize();
        SetVATReportPeriodTypeVerifyDate(PeriodType::Year, 1);
    end;

    [Test]
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
    procedure SetEmptyVATRegNoInLine_VerifyErrorLogged()
    var
        VATReportLine: Record "VAT Report Line";
        VATReportPart: Option Header,Line;
    begin
        Initialize();
        SetIncorrectFieldValue_ValidateReport(VATReportPart::Line, VATReportLine.FieldNo("VAT Registration No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVIESReportVATRegistrationNo()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportBuf: Record "Data Export Buffer" temporary;
        CompanyInformation: Record "Company Information";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        SetupCompanyInformationVATRegNo(CompanyInformation);
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.FindFirst();

        VerifyReportFieldValue(
          VATReportBuf,
          1,
          5,
          GetVATRegNo(VATReportLine),
          ECPartnerIDLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportErrorLogHandler')]
    [Scope('OnPrem')]
    procedure SetEmptyCountryCodeInLine_VerifyErrorLogged()
    var
        VATReportLine: Record "VAT Report Line";
        VATReportPart: Option Header,Line;
    begin
        Initialize();
        SetIncorrectFieldValue_ValidateReport(VATReportPart::Line, VATReportLine.FieldNo("Country/Region Code"), '');
    end;

    [Test]
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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

        DeleteVATReport(VATReportHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
    procedure SuggestLines_StandardReport_VerifyCountryGrouping()
    var
        VATReportLine: Record "VAT Report Line";
    begin
        Initialize();
        SuggestLines_StandardReport_VerifyFieldGrouping(VATReportLine.FieldNo("Country/Region Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestLines_StandardReport_VerifyVATRegNoGrouping()
    var
        VATReportLine: Record "VAT Report Line";
    begin
        Initialize();
        SuggestLines_StandardReport_VerifyFieldGrouping(VATReportLine.FieldNo("VAT Registration No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestLines_StandardReport_VerifyEU3PartyTradeGrouping()
    var
        VATReportLine: Record "VAT Report Line";
    begin
        Initialize();
        SuggestLines_StandardReport_VerifyFieldGrouping(VATReportLine.FieldNo("EU 3-Party Trade"));
    end;

    [Test]
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
    procedure FormatAmountForExport_PositiveNumber_VerifyLeadingZeros()
    var
        AmtText: Text[20];
        NoOfDigits: Integer;
        i: Integer;
    begin
        Initialize();
        NoOfDigits := LibraryRandom.RandIntInRange(3, 7);
        AmtText := FormatRandomAmountForExport(NoOfDigits, true);

        for i := 1 to StrLen(AmtText) - NoOfDigits do
            Assert.AreEqual('0', Format(AmtText[i]), IncorrectAmountForExportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatAmountForExport_PositiveNumber_VerifyAmountRounded()
    var
        AmtText: Text[20];
        NoOfDigits: Integer;
    begin
        Initialize();
        NoOfDigits := LibraryRandom.RandIntInRange(3, 7);
        AmtText := FormatRandomAmountForExport(NoOfDigits, true);
        Assert.AreEqual(NoOfDigits, StrLen(DelChr(AmtText, '<', '0')), IncorrectAmountForExportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatAmountForExport_NegativeNumber()
    var
        AmtText: Text[20];
    begin
        Initialize();
        AmtText := FormatRandomAmountForExport(LibraryRandom.RandIntInRange(3, 7), false);
        Assert.AreEqual('-', Format(AmtText[StrLen(AmtText)]), IncorrectAmountForExportErr);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyMandatoryFieldsFilled()
    var
        VATReportBuf: Record "Data Export Buffer" temporary;
        VATReportHeader: Record "VAT Report Header";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);

        VerifyMandatoryFieldsInVATReport(VATReportBuf);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyNoOfLinesType0()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportBuf: Record "Data Export Buffer" temporary;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);

        Assert.AreEqual(1, CountReportBufferLines(VATReportBuf, '0'), IncorrectNoOfReportLinesErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyNoOfLinesType2()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportBuf: Record "Data Export Buffer" temporary;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);

        Assert.AreEqual(1, CountReportBufferLines(VATReportBuf, '2'), IncorrectNoOfReportLinesErr);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyNoOfLinesOnZeroBaseAmount()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportBuf: Record "Data Export Buffer" temporary;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        // Verify Export Buffer for absence of non-correction VAT report lines with 0 Base
        CreateVATReportAndSaveIntoBufferZeroBase(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);

        VerifyBufferLineCount(VATReportBuf, '1', 0);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyRegistrationID()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
        VATReportBuf: Record "Data Export Buffer" temporary;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        VATReportSetup.Get();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VerifyReportFieldValue(VATReportBuf, 0, 2, VATReportSetup."Registration ID", RegistrationIDLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyCreationDate()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportBuf: Record "Data Export Buffer" temporary;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VerifyReportFieldValue(VATReportBuf, 0, 3, Format(VATReportHeader."Processing Date", 0, '<Year4><Month,2><Day,2>'), CreationDateLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyReporterName()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportBuf: Record "Data Export Buffer" temporary;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VerifyReportFieldValue(VATReportBuf, 0, 4, VATReportHeader."Company Name", NameLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyAddressStreet()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportBuf: Record "Data Export Buffer" temporary;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VerifyReportFieldValue(VATReportBuf, 0, 5, VATReportHeader."Company Address", CompanyAddressLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyAddressPostcode()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportBuf: Record "Data Export Buffer" temporary;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VerifyReportFieldValue(VATReportBuf, 0, 6, VATReportHeader."Post Code", PostCodeLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyAddressLocation()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportBuf: Record "Data Export Buffer" temporary;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VerifyReportFieldValue(VATReportBuf, 0, 7, VATReportHeader.City, LocationLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyReporterVATID()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportBuf: Record "Data Export Buffer" temporary;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VerifyReportFieldValue(VATReportBuf, 1, 2, VATReportHeader."VAT Registration No.", VATRegNoLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyTypeOfStatement()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportBuf: Record "Data Export Buffer" temporary;
        ExportVIESReport: Report "Export VIES Report";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.FindFirst();
        VerifyReportFieldValue(VATReportBuf, 1, 3, ExportVIESReport.GetReportType(VATReportLine, VATReportHeader), TypeOfStatementLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyPartnerVATID()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportBuf: Record "Data Export Buffer" temporary;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [SCENARIO 301437] Export VIES Report when VAT Registration No does not have Country/Region prefix
        Initialize();

        // [GIVEN] EU Country/Region Code = 'BE', VAT Registration No = '123456789'
        // [WHEN] Run Export VIES Report
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.FindFirst();

        // [THEN] VAT Registration No. exported as 'BE123456789'
        VerifyReportFieldValue(
          VATReportBuf,
          1,
          5,
          GetVATRegNo(VATReportLine),
          ECPartnerIDLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVATIDWithCountryCode()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TempDataExportBuffer: Record "Data Export Buffer" temporary;
        CountryRegion: Record "Country/Region";
        VATRegNo: Text[20];
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // [SCENARIO 301437] Export VIES Report when VAT Registration No has Country/Region prefix
        Initialize();

        // [GIVEN] EU Country/Region Code = 'BE', VAT Registration No = 'BE123456789'
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion."EU Country/Region Code" :=
          LibraryUtility.GenerateRandomCodeWithLength(CountryRegion.FieldNo("EU Country/Region Code"), DATABASE::"Country/Region", 2);
        CountryRegion.Modify();
        VATRegNo := CountryRegion."EU Country/Region Code" + Format(LibraryRandom.RandIntInRange(10000000, 20000000));

        // [WHEN] Run Export VIES Report
        SetupVATReportScenarioWithVATRegNo(VATReportHeader, TestPeriodStart, TestPeriodEnd, CountryRegion.Code, VATRegNo);
        ExportVATReportIntoBuffer(VATReportHeader, TempDataExportBuffer);

        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.FindFirst();

        // [THEN] VAT Registration No. exported as 'BE123456789'
        VerifyReportFieldValue(
          TempDataExportBuffer,
          1,
          5,
          VATReportLine."VAT Registration No.",
          ECPartnerIDLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyAssessmentBasis()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportBuf: Record "Data Export Buffer" temporary;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.FindFirst();

        VerifyReportFieldValue(VATReportBuf, 1, 6, ExportVIESReport.FormatAmountForExport(VATReportLine.Base, 12), AssessmentBasisLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyTypeOfTurnover()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportBuf: Record "Data Export Buffer";
        ExportVIESReport: Report "Export VIES Report";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.FindFirst();

        VerifyReportFieldValue(VATReportBuf, 1, 7, ExportVIESReport.GetTurnoverType(VATReportLine), TypeOfTurnoverLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyNotice()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportBuf: Record "Data Export Buffer";
        ExportVIESReport: Report "Export VIES Report";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.FindFirst();

        VerifyReportFieldValue(VATReportBuf, 1, 8, ExportVIESReport.GetNotice(VATReportHeader), NoticeLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyRevocation()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportBuf: Record "Data Export Buffer";
        ExportVIESReport: Report "Export VIES Report";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.FindFirst();

        VerifyReportFieldValue(VATReportBuf, 1, 9, ExportVIESReport.GetRevocation(VATReportHeader), RevocationLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyTotalAssessmentBase()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportBuf: Record "Data Export Buffer";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.CalcSums(Base);

        VerifyReportFieldValue(
          VATReportBuf,
          2,
          4,
          ExportVIESReport.FormatAmountForExport(VATReportLine.Base, 14),
          TotalAmtLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyNoOfRecordType1Records()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportBuf: Record "Data Export Buffer";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");

        VerifyReportFieldValue(
          VATReportBuf,
          2,
          5,
          ExportVIESReport.FormatAmountForExport(VATReportLine.Count, 5),
          NoOfLinesLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyReportingTimePeriod()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportBuf: Record "Data Export Buffer";
        ExportVIESReport: Report "Export VIES Report";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);

        VerifyReportFieldValue(VATReportBuf, 2, 3, ExportVIESReport.GetReportPeriod(VATReportHeader), ReportPeriodLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportVerifyReportingTimePeriodsAreEqual()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportBuf: Record "Data Export Buffer";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        CreateVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);

        Assert.AreEqual(
          GetFieldValueFromBuffer(VATReportBuf, 1, 4),
          GetFieldValueFromBuffer(VATReportBuf, 2, 3),
          StrSubstNo(IncorrectReportFieldValueErr, ReportPeriodLbl));

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler,ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportCorrectiveVATReportVerifyTotalAmount()
    var
        VATReportHeader: Record "VAT Report Header";
        CorrVATReportHeader: Record "VAT Report Header";
        CorrVATReportLine: Record "VAT Report Line";
        VATReportBuf: Record "Data Export Buffer";
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        Initialize();
        SetupVatReportScenario_SubmitReport(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        CreateCorrectiveReport(VATReportHeader, CorrVATReportHeader);
        SubmitVATReport(CorrVATReportHeader);

        ExportVATReportIntoBuffer(CorrVATReportHeader, VATReportBuf);
        FindLastReportLine(CorrVATReportHeader."No.", CorrVATReportLine."Line Type"::Correction, CorrVATReportLine);

        VerifyReportFieldValue(
          VATReportBuf,
          2,
          4,
          ExportVIESReport.FormatAmountForExport(CorrVATReportLine.Base, 14),
          TotalAmtLbl);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler,VATReportLinesListHandler')]
    [Scope('OnPrem')]
    procedure ExportCorrectiveVATReportCancellationOn()
    begin
        // Verify Export Buffer for report lines' types and total report count
        // when Export Cancellation Lines is Off
        Initialize();
        ExportCorrectiveVATReportVerifyReportLineTypesAndCount(false, 2);
    end;

    [Test]
    [HandlerFunctions('ExportVIESReportPageHandler,VATReportLinesListHandler')]
    [Scope('OnPrem')]
    procedure ExportCorrectiveVATReportCancellationOff()
    begin
        // Verify Export Buffer for report lines' types and total report count.
        // when Export Cancellation Lines is On
        Initialize();
        ExportCorrectiveVATReportVerifyReportLineTypesAndCount(true, 3);
    end;

    [Test]
    [Scope('OnPrem')]
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

        DeleteVATReport(VATReportHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeFileNameInExportModeVerifyExtension()
    var
        VATReportHeader: Record "VAT Report Header";
        FileName: Text;
    begin
        Initialize();
        CreateStandardMonthReport(VATReportHeader);
        VATReportHeader.Validate("Test Export", false);
        FileName := ExportVIESReport.MakeFileName(VATReportHeader);

        Assert.AreEqual('p', Format(FileName[StrLen(FileName)]), IncorrectFileNameErr);

        DeleteVATReport(VATReportHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeFileNameInTestModeVerifyExtension()
    var
        VATReportHeader: Record "VAT Report Header";
        FileName: Text;
    begin
        Initialize();
        CreateStandardMonthReport(VATReportHeader);
        VATReportHeader.Validate("Test Export", true);
        FileName := ExportVIESReport.MakeFileName(VATReportHeader);

        Assert.AreEqual('t', Format(FileName[StrLen(FileName)]), IncorrectFileNameErr);

        DeleteVATReport(VATReportHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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

        DeleteVATReport(VATReportHeader."No.");
    end;

    [Test]
    [HandlerFunctions('VATReportsLookupHandler')]
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
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
    [Scope('OnPrem')]
    procedure VerifyReportLineCanRelateToOneTableOnly()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        Initialize();
        CreateMockVATReportWithLines(
          VATReportHeader,
          VATReportHeader."VAT Report Type"::Standard,
          VATReportHeader."Report Period Type"::Year,
          1);

        VATReportLineRelation.Get(VATReportHeader."No.", 1, DATABASE::"VAT Entry", 1);
        VATReportLineRelation.Validate("Table No.", DATABASE::"G/L Entry");
        asserterror VATReportLineRelation.Insert(true);

        Assert.ExpectedTestFieldError(VATReportLineRelation.FieldCaption("Table No."), Format(Database::"VAT Entry"));
    end;

    [Test]
    [HandlerFunctions('VATReportLinesListHandler')]
    [Scope('OnPrem')]
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
    [HandlerFunctions('ExportVIESReportPageHandler')]
    [Scope('OnPrem')]
    procedure ExportVATReportEncodingUT()
    var
        VATReportHeader: Record "VAT Report Header";
        FileMgt: Codeunit "File Management";
        ServerFileName: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 166131] VAT Report exports country specific symbols with correct encoding
        Initialize();

        // [GIVEN] Company information address contains country specific symbols
        SetCompanyInformationAddress('ÄäÜüöÖß');

        // [GIVEN] Created VAT Report
        CreateStandardMonthReport(VATReportHeader);

        // [WHEN] Run Export VAT report
        ServerFileName := FileMgt.ServerTempFileName('txt');
        ExportVATReport(VATReportHeader, ServerFileName);

        // [THEN] Created file contains country specific symbols in correct encoding
        VerifyCompanyInfoAddressValue(ServerFileName, 'ÄäÜüöÖß');
    end;

    [Test]
    [Scope('OnPrem')]
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
        VATReportNo := ECSLReport."No.".Value();
        ECSLReport.Close();

        VATReportHeader.Get(VATReportNo);
        VATReportHeader.TestField("Report Period Type", VATReportHeader."Report Period Type"::Month);
    end;

    [Test]
    [Scope('OnPrem')]
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
        VATReportNo := ECSLReport."No.".Value();
        ECSLReport.Close();

        VATReportHeader.Get(VATReportNo);
        VATReportHeader.TestField("Report Period Type", VATReportHeader."Report Period Type"::Quarter);
    end;

    [Test]
    [Scope('OnPrem')]
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
            'Your entry of ''%1'' is not an acceptable value for ''%2''',
            Format(VATReportHeader."Report Period Type"::Year), ECSLReport.ReportPeriodType.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
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
        VATReportNo := ECSLReport."No.".Value();
        ECSLReport.Close();

        VATReportHeader.Get(VATReportNo);
        VATReportHeader.TestField("Report Period Type", VATReportHeader."Report Period Type"::"Bi-Monthly");
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        InitializeVATReportSetup();
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
        VATReportSetup.Validate("Source Identifier", LibraryUtility.GenerateRandomCode(VATReportSetup.FieldNo("Source Identifier"), DATABASE::"VAT Report Setup"));
        VATReportSetup.Validate(
          "Transmission Process ID",
          LibraryUtility.GenerateRandomCode(VATReportSetup.FieldNo("Transmission Process ID"), DATABASE::"VAT Report Setup"));
        VATReportSetup.Validate("Supplier ID", LibraryUtility.GenerateRandomCode(VATReportSetup.FieldNo("Supplier ID"), DATABASE::"VAT Report Setup"));
        VATReportSetup.Validate("Registration ID", LibraryUtility.GenerateRandomCode(VATReportSetup.FieldNo("Registration ID"), DATABASE::"VAT Report Setup"));
        VATReportSetup.Modify();
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

    local procedure ExportCorrectiveVATReportVerifyReportLineTypesAndCount(ExportCancellationLines: Boolean; ExpectedCount: Integer)
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportBuf: Record "Data Export Buffer" temporary;
        TestPeriodStart: Date;
        TestPeriodEnd: Date;
    begin
        // Verify Export Buffer for report lines' types and total report count.
        SetupExportCancellationLines(ExportCancellationLines);

        CreateCorrectiveVATReportAndSaveIntoBuffer(VATReportBuf, VATReportHeader, TestPeriodStart, TestPeriodEnd);

        Assert.AreEqual(
          ExpectedCount, CountReportBufferLinesByVATReportType(VATReportBuf, '11'), IncorrectNoOfReportLinesErr);
        VerifyBufferLineCount(VATReportBuf, '1', ExpectedCount);

        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
        VATReportHeader.Get(VATReportHeader."Original Report No.");
        Cleanup(VATReportHeader."No.", TestPeriodStart, TestPeriodEnd);
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

    local procedure GetVATRegNo(VATReportLine: Record "VAT Report Line"): Text[20]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(VATReportLine."Country/Region Code");
        exit(CopyStr(CountryRegion."EU Country/Region Code", 1, 2) + VATReportLine."VAT Registration No.");
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
        VATReportHeader.Validate("Report Period Type", ReportPeriodType);
        VATReportHeader.Validate("Report Period No.", ReportPeriodNo);
        VATReportHeader.Validate("Report Year", ReportYear);
        VATReportHeader.Validate("Processing Date", VATReportHeader."End Date");
        VATReportHeader.Modify(true);
    end;

    local procedure CreateMockVATReportLine(VATReportNo: Code[20])
    var
        CountryRegion: Record "Country/Region";
        VATReportLine: Record "VAT Report Line";
    begin
        LibraryERM.FindCountryRegion(CountryRegion);

        VATReportLine.Init();
        VATReportLine."VAT Report No." := VATReportNo;
        VATReportLine."Line No." := 1;
        VATReportLine."Country/Region Code" := CountryRegion.Code;
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
        CreateVATReportHeader(
            VATReportHeader,
            ReportType,
            ReportPeriodType,
            ReportPeriodNo,
            CurrYear());
        CreateMockVATReportLine(VATReportHeader."No.");
        CreateMockReportRelationLine(VATReportHeader."No.");
    end;

    local procedure CreateStandardMonthReport(var VATReportHeader: Record "VAT Report Header")
    begin
        CreateMockVATReportWithLines(
          VATReportHeader,
          VATReportHeader."VAT Report Type"::Standard,
          VATReportHeader."Report Period Type"::Month,
          Date2DMY(WorkDate(), 2));
    end;

    local procedure CreateMockVATReport_SetFieldValue(VATReportPart: Option Header,Line; ValidatedFieldNo: Integer; FieldValue: Variant): Code[20]
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        RecRef: RecordRef;
        ReportFieldRef: FieldRef;
    begin
        CreateMockVATReportWithLines(
          VATReportHeader,
          VATReportHeader."VAT Report Type"::Standard,
          VATReportHeader."Report Period Type"::Year,
          1);

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

        CountryRegion.Validate(
            "EU Country/Region Code",
            LibraryUtility.GenerateRandomCode(CountryRegion.FieldNo("EU Country/Region Code"), DATABASE::"Country/Region"));
        CountryRegion.Modify(true);

        exit(CountryRegion.Code);
    end;

    local procedure FormatRandomAmountForExport(NoOfDigits: Integer; PositiveAmount: Boolean): Text[20]
    var
        RangeMin: Integer;
        RangeMax: Integer;
        Amt: Decimal;
    begin
        RangeMin := Power(10, NoOfDigits - 1);
        RangeMax := RangeMin * 10 - 1;

        Amt := LibraryRandom.RandDecInRange(RangeMin, RangeMax, 2);
        if not PositiveAmount then
            Amt := -Amt;

        exit(ExportVIESReport.FormatAmountForExport(Amt, LibraryRandom.RandIntInRange(10, 15)));
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

    local procedure CreateVATReportAndSaveIntoBuffer(var ReportBuf: Record "Data Export Buffer" temporary; var VATReportHeader: Record "VAT Report Header"; var TestPeriodStart: Date; var TestPeriodEnd: Date)
    begin
        SetupVATReportScenario(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        ExportVATReportIntoBuffer(VATReportHeader, ReportBuf);
    end;

    local procedure CreateVATReportAndSaveIntoBufferZeroBase(var ReportBuf: Record "Data Export Buffer" temporary; var VATReportHeader: Record "VAT Report Header"; var TestPeriodStart: Date; var TestPeriodEnd: Date)
    begin
        SetupVATReportScenarioZeroBase(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        ExportVATReportIntoBuffer(VATReportHeader, ReportBuf);
    end;

    local procedure CreateCorrectiveVATReportAndSaveIntoBuffer(var ReportBuf: Record "Data Export Buffer" temporary; var VATReportHeader: Record "VAT Report Header"; var TestPeriodStart: Date; var TestPeriodEnd: Date)
    begin
        SetupCorrectiveVATReportScenario(VATReportHeader, TestPeriodStart, TestPeriodEnd);
        ExportVATReportIntoBuffer(VATReportHeader, ReportBuf);
    end;

    local procedure GetFieldValueFromBuffer(var ReportBuf: Record "Data Export Buffer"; RecordType: Integer; FldNo: Integer): Text[120]
    begin
        ReportBuf.Reset();
        if ReportBuf.FindSet() then
            repeat
                if Format(ReportBuf."Field Value"[1]) = Format(RecordType) then
                    exit(ExtractFieldValueFromReportLine(ReportBuf."Field Value", FldNo));
            until ReportBuf.Next() = 0;

        exit('');
    end;

    local procedure VerifyMandatoryFieldsInVATReport(var VATReportBuf: Record "Data Export Buffer")
    begin
        VATReportBuf.FindSet();
        repeat
            case VATReportBuf."Field Value"[1] of
                '0':
                    VerifyVATReportLineFields_RecordType0(VATReportBuf."Field Value");
                '1':
                    VerifyVATReportLineFields_RecordType1(VATReportBuf."Field Value");
                '2':
                    VerifyVATReportLineFields_RecordType2(VATReportBuf."Field Value");
                else
                    Error(UnknownReportLineTypeErr, VATReportBuf."Field Value"[1]);
            end;
        until VATReportBuf.Next() = 0;
    end;

    local procedure VerifyVATReportLineFields_RecordType0(ReportLine: Text[120])
    begin
        Assert.IsTrue(
          IsFieldNotEmpty(ReportLine, 1) and
          IsFieldNotEmpty(ReportLine, 2) and
          IsFieldNotEmpty(ReportLine, 3) and
          IsFieldNotEmpty(ReportLine, 4) and
          IsFieldNotEmpty(ReportLine, 5) and
          IsFieldNotEmpty(ReportLine, 6) and
          IsFieldNotEmpty(ReportLine, 7),
          MandatoryFieldEmptyErr);
    end;

    local procedure VerifyVATReportLineFields_RecordType1(ReportLine: Text[120])
    begin
        Assert.IsTrue(
          IsFieldNotEmpty(ReportLine, 1) and
          IsFieldNotEmpty(ReportLine, 2) and
          IsFieldNotEmpty(ReportLine, 3) and
          IsFieldNotEmpty(ReportLine, 4) and
          IsFieldNotEmpty(ReportLine, 5) and
          IsFieldNotEmpty(ReportLine, 6) and
          IsFieldNotEmpty(ReportLine, 8) and
          IsFieldNotEmpty(ReportLine, 9),
          MandatoryFieldEmptyErr);
    end;

    local procedure VerifyVATReportLineFields_RecordType2(ReportLine: Text[120])
    begin
        Assert.IsTrue(
          IsFieldNotEmpty(ReportLine, 1) and
          IsFieldNotEmpty(ReportLine, 2) and
          IsFieldNotEmpty(ReportLine, 3) and
          IsFieldNotEmpty(ReportLine, 4) and
          IsFieldNotEmpty(ReportLine, 5),
          MandatoryFieldEmptyErr);
    end;

    local procedure IsFieldNotEmpty(ReportLine: Text[120]; FieldNo: Integer): Boolean
    begin
        exit(ExtractFieldValueFromReportLine(ReportLine, FieldNo) <> '');
    end;

    local procedure ExtractFieldValueFromReportLine(ReportLine: Text[120]; FieldNo: Integer): Text[120]
    var
        RecType: Text[1];
    begin
        RecType := CopyStr(ReportLine, 1, 1);
        exit(DelChr(CopyStr(ReportLine, GetFieldStartPosition(RecType, FieldNo), GetFieldLength(RecType, FieldNo)), '<>', ' '));
    end;

    local procedure GetFieldStartPosition(RecordType: Text[1]; FieldNo: Integer) StartPosition: Integer
    begin
        case RecordType of
            '0':
                Evaluate(StartPosition, SelectStr(FieldNo, FieldStartPositionsRecType0Tok));
            '1':
                Evaluate(StartPosition, SelectStr(FieldNo, FieldStartPositionsRecType1Tok));
            '2':
                Evaluate(StartPosition, SelectStr(FieldNo, FieldStartPositionsRecType2Tok));
        end;
    end;

    local procedure GetFieldLength(RecordType: Text[1]; FieldNo: Integer) Length: Integer
    begin
        case RecordType of
            '0':
                Evaluate(Length, SelectStr(FieldNo, FieldLengthsRecType0Tok));
            '1':
                Evaluate(Length, SelectStr(FieldNo, FieldLengthsRecType1Tok));
            '2':
                Evaluate(Length, SelectStr(FieldNo, FieldLengthsRecType2Tok));
        end;
    end;

    local procedure CountReportBufferLines(var ReportBuf: Record "Data Export Buffer"; RecordType: Text[1]) NoOfLines: Integer
    begin
        ReportBuf.Reset();
        ReportBuf.FindSet();
        repeat
            if Format(ReportBuf."Field Value"[1]) = RecordType then
                NoOfLines += 1;
        until ReportBuf.Next() = 0
    end;

    local procedure CountReportBufferLinesByVATReportType(var ReportBuf: Record "Data Export Buffer"; VATReportTypeFilter: Text[2]) NoOfLines: Integer
    var
        VATReportType: Text[2];
    begin
        ReportBuf.Reset();
        ReportBuf.FindSet();
        repeat
            VATReportType := CopyStr(ReportBuf."Field Value", 13, 2);
            if VATReportType = VATReportTypeFilter then
                NoOfLines += 1;
        until ReportBuf.Next() = 0
    end;

    local procedure VerifyReportFieldValue(var VATReportBuf: Record "Data Export Buffer" temporary; RecordType: Integer; FldNo: Integer; ExpectedValue: Text[120]; ReportFieldName: Text[50])
    begin
        Assert.AreEqual(
          ExpectedValue,
          GetFieldValueFromBuffer(VATReportBuf, RecordType, FldNo),
          StrSubstNo(IncorrectReportFieldValueErr, ReportFieldName));
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

    local procedure SetupCompanyInformationVATRegNo(var CompanyInformation: Record "Company Information")
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("VAT Registration No.", PadStr(CompanyInformation."Country/Region Code", 11, Format(LibraryRandom.RandInt(9))));
        CompanyInformation.Modify();
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

    local procedure ExportVATReport(var VATReportHeader: Record "VAT Report Header"; FileName: Text)
    var
        ExportVIESReport: Report "Export VIES Report";
    begin
        Commit();
        VATReportHeader.SetRange("No.", VATReportHeader."No.");
        ExportVIESReport.SetTestExportMode(FileName);
        ExportVIESReport.SetTableView(VATReportHeader);
        ExportVIESReport.RunModal();
    end;

    local procedure ExportVATReportIntoBuffer(var VATReportHeader: Record "VAT Report Header"; var ReportBuf: Record "Data Export Buffer" temporary)
    var
        ExportVIESReport: Report "Export VIES Report";
    begin
        ExportVIESReport.SetTestMode(true);
        Commit();
        VATReportHeader.SetRange("No.", VATReportHeader."No.");
        ExportVIESReport.SetTableView(VATReportHeader);
        ExportVIESReport.RunModal();
        ExportVIESReport.GetBuffer(ReportBuf);
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

    local procedure VerifyCompanyInfoAddressValue(FileName: Text; ExpectedValue: Text)
    var
        FileLine: Text;
    begin
        FileLine := LoadFirstFileLine(FileName);
        Assert.ExpectedMessage(ExpectedValue, FileLine);
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

    local procedure LoadFirstFileLine(FileName: Text) Line: Text
    var
        File: File;
        InStr: InStream;
    begin
        File.TextMode(true);
        File.Open(FileName, TEXTENCODING::Windows);
        File.Read(Line);
        File.CreateInStream(InStr);
        InStr.ReadText(Line);
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

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportVIESReportPageHandler(var ExportVIESReport: TestRequestPage "Export VIES Report")
    begin
        ExportVIESReport.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATReportLinesListHandler(var VATRepLinesList: TestPage "VAT Report Lines")
    begin
        VATRepLinesList.Last();
        VATRepLinesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATReportLinesValuesListHandler(var VATRepLinesList: TestPage "VAT Report Lines")
    begin
        VATRepLinesList.First();
        VariableStorage.Enqueue(Format(VATRepLinesList.Base));
        VATRepLinesList.Next();
        VariableStorage.Enqueue(Format(VATRepLinesList.Base));
        VATRepLinesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATReportsLookupHandler(var VATReportList: TestPage "VAT Report List")
    var
        VATReportNo: Variant;
    begin
        VariableStorage.Dequeue(VATReportNo);
        VATReportList.GotoKey(VATReportNo);
        VATReportList.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VATReportErrorLogHandler(var ErrorLogPage: TestPage "VAT Report Error Log")
    var
        ExpectedErrorText: Variant;
    begin
        VariableStorage.Dequeue(ExpectedErrorText);
        Assert.AreEqual(ExpectedErrorText, ErrorLogPage."Error Message".Value, IncorectMsgInErrorLogErr);
        ErrorLogPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
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

    local procedure VerifyBufferLineCount(var DataExportBuffer: Record "Data Export Buffer"; LineType: Text[1]; ExpectedCount: Integer)
    begin
        Assert.AreEqual(ExpectedCount, CountReportBufferLines(DataExportBuffer, LineType), IncorrectNoOfReportLinesErr);
        VerifyReportFieldValue(
          DataExportBuffer,
          2,
          5,
          ExportVIESReport.FormatAmountForExport(ExpectedCount, 5),
          TotalAmtLbl);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

