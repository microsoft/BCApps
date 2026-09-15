codeunit 144528 "ERM Stat. Repoting UT"
{
    // // [FEATURE] [Statutory Reporting]

    Subtype = Test;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        LibraryStatReporting: Codeunit "Library - Stat. Reporting";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRUReports: Codeunit "Library RU Reports";
        Assert: Codeunit Assert;
        WrongResultOfGetElementValueErr: Label 'Wrong result of "XML Element Line".GetElementValue.';
        TextType: Option Capitalized,"Literal and Capitalized";
        IsInitialized: Boolean;
        ErrorTok: Label 'Error';
        IncorrectFoundErrorErr: Label 'Check XML could not find any error';

    [Test]
    [HandlerFunctions('StatRepTableCellMappingPageHandler')]
    [Scope('OnPrem')]
    procedure SaveChangesOnStatRepTableCellMappingPage()
    var
        StatReportTableMapping: Record "Stat. Report Table Mapping";
        StatutoryReportTable: Record "Statutory Report Table";
        ExpectedTextStart: Text;
        NewRecordDescription: Text[250];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 375154] Changed values on "Stat. Rep. Table Cell Mapping" page are saved into DB
        Initialize();
        StatutoryReportTable.FindFirst();
        ExpectedTextStart := LibraryUtility.GenerateGUID();

        // [GIVEN] "Stat. Report Table Mapping" with "Int. Source Row Description" = "A1"
        LibraryVariableStorage.Enqueue(ExpectedTextStart);

        // [WHEN] Change "Int. Source Row Description" to "A2" on a "Stat. Rep. Table Cell Mapping" page
        StatReportTableMapping.ShowMappingCard(
          StatutoryReportTable."Report Code", StatutoryReportTable.Code, 10000, 10000, NewRecordDescription);

        // [THEN] "Stat. Report Table Mapping"."Int. Source Row Description" = "A2" (stored in db)
        Assert.IsTrue(StrPos(ExpectedTextStart, NewRecordDescription) = 0, '');
        Clear(StatReportTableMapping);
        StatReportTableMapping.SetRange("Int. Source Row Description", ExpectedTextStart);
        Assert.RecordIsNotEmpty(StatReportTableMapping);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_XMLGetElementValueForBlankValue()
    var
        XMLElementLine: Record "XML Element Line";
        StatutoryReportBuffer: Record "Statutory Report Buffer";
        Result: Text[250];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 372299] Function GetElementValue for "Compound Element" should return an empty string if it doesn't have child elements.
        Initialize();

        // [GIVEN] "XML Element Line" of "Compound Element" source type
        MockXMLElementLine(
          XMLElementLine,
          LibraryUtility.GenerateRandomCode(XMLElementLine.FieldNo("Report Code"), DATABASE::"XML Element Line"),
          XMLElementLine."Source Type"::"Compound Element",
          '');
        MockStatRepBuffer(StatutoryReportBuffer);

        // [WHEN] Invoke GetElementValue on the Base element
        Result := XMLElementLine.GetElementValue(StatutoryReportBuffer);

        // [THEN] GetElementValue returns ''
        Assert.AreEqual('', Result, WrongResultOfGetElementValueErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_XMLGetElementValueForFillValue()
    var
        XMLElementLine: Record "XML Element Line";
        StatutoryReportBuffer: Record "Statutory Report Buffer";
        Result: Text[250];
        XMLElementLineValue: Text[250];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 372299] Function GetElementValue for Base "Compound Element" should return Value of Child "Constant" element.
        Initialize();

        // [GIVEN] Base "XML Element Line" of "Compound Element" source type
        // [GIVEN] Child "XML Element Line" of "Constant" source type where Value = "X"
        XMLElementLineValue :=
          CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(XMLElementLine.Value), TextType::Capitalized),
            1,
            MaxStrLen(XMLElementLineValue));
        CreateBaseAndChildXmlElemLines(XMLElementLine, XMLElementLineValue);
        MockStatRepBuffer(StatutoryReportBuffer);

        // [WHEN] Invoke GetElementValue on the Base element
        Result := XMLElementLine.GetElementValue(StatutoryReportBuffer);

        // [THEN] GetElementValue returns "X"
        Assert.AreEqual(XMLElementLineValue, Result, WrongResultOfGetElementValueErr);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OpenTaxAuthoritiesFromRecipientTaxAuthCodeInStatutoryReports()
    var
        StatutoryReport: Record "Statutory Report";
        StatutoryReports: TestPage "Statutory Reports";
        TaxAuthNo: Code[20];
    begin
        // [FEATURE] [Tax Authority]
        // [SCENARIO 375181] Tax Authorities page used as Lookup page for field "Recipient Tax Authority Code" in "Statutory Reports" page
        Initialize();

        // [GIVEN] Statutory Report
        // [GIVEN] Tax Authority = "X"
        LibraryRUReports.CreateStatutoryReport(StatutoryReport);
        TaxAuthNo := LibraryPurchase.CreateVendorTaxAuthority();
        LibraryVariableStorage.Enqueue(TaxAuthNo);
        StatutoryReports.OpenEdit();
        StatutoryReports.GotoRecord(StatutoryReport);

        // [WHEN] Lookup field "Recipient Tax Authority Code" from page "Statutory Reports"
        StatutoryReports."Recipient Tax Authority Code".Lookup();

        // [THEN] Tax Authorities page is opened and Tax Authority "X" is selected
        // Verification done in TaxAuthorityModalPageHandler
        StatutoryReports."Recipient Tax Authority Code".AssertEquals(TaxAuthNo);
    end;

    [Test]
    [HandlerFunctions('NameValueLookupMPH')]
    [Scope('OnPrem')]
    procedure ReportDataCheckXmlValidationErrors()
    var
        StatutoryReportSetup: Record "Statutory Report Setup";
        StatutoryReport: Record "Statutory Report";
        ReportDataList: TestPage "Report Data List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 375202] Check XML validates generated XML against given XML Schema and shows all found errors
        Initialize();
        StatutoryReportSetup.Get();
        UpdateReportDataNosStatRepSetup(CreateNoSeries());

        // [GIVEN] Statutory report with 5 errors in generated XML
        StatutoryReport.SetRange("Format Version Code", FindFormatVersionCode());
        StatutoryReport.FindFirst();
        LibraryStatReporting.CreateStatutoryReportData(StatutoryReport);

        // [WHEN]  Press "Check XML" on Report Data page
        ReportDataList.OpenView();
        ReportDataList.FILTER.SetFilter("Report Code", StatutoryReport.Code);
        ReportDataList.CheckXml.Invoke(); // validates "Check XML" button exists

        // [THEN]  Modal page with found errors appeared.
        UpdateReportDataNosStatRepSetup(StatutoryReportSetup."Report Data Nos");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateReportHeaderWithOKEITypeOptionString()
    var
        StatutoryReportDataHeader: Record "Statutory Report Data Header";
        StatutoryReport: Record "Statutory Report";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 225227] Function "Statutory Report Data Header".CreateReportHeader must fill value of OKEI as caption of OKEIType

        // [GIVEN] Statutory Report record
        CreateStatutoryReportWithFormatVersion(StatutoryReport);

        // [WHEN] Invoke "Statutory Report Data Header".CreateReportHeader with OKEIType = 0 (option value = '383')
        StatutoryReportDataHeader.CreateReportHeader(StatutoryReport, WorkDate(), WorkDate(), WorkDate(), 0, 0, 0,
          LibraryUtility.GenerateGUID(), 0, 'PT', LibraryUtility.GenerateGUID());

        // [THEN] "Statutory Record Data Header"."OKEI" = '383'
        StatutoryReportDataHeader.SetRange("Report Code", StatutoryReport.Code);
        StatutoryReportDataHeader.FindFirst();
        StatutoryReportDataHeader.TestField(OKEI, '383');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure CreateBaseAndChildXmlElemLines(var BaseXMLElementLine: Record "XML Element Line"; ChildValue: Text[250])
    var
        ReportCode: Code[20];
        BaseXMLElementLineNo: Integer;
        ChildXMLElementLineNo: Integer;
    begin
        ReportCode := LibraryUtility.GenerateRandomCode(BaseXMLElementLine.FieldNo("Report Code"), DATABASE::"XML Element Line");
        ChildXMLElementLineNo :=
          MockXMLElementLine(BaseXMLElementLine, ReportCode, BaseXMLElementLine."Source Type"::Constant, ChildValue);
        BaseXMLElementLineNo :=
          MockXMLElementLine(BaseXMLElementLine, ReportCode, BaseXMLElementLine."Source Type"::"Compound Element", '');
        MockXMLElementExpressionLine(ReportCode, BaseXMLElementLineNo, ChildXMLElementLineNo);
        BaseXMLElementLine.Get(ReportCode, BaseXMLElementLineNo);
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        exit(NoSeries.Code);
    end;

    local procedure CreateStatutoryReportWithFormatVersion(var StatutoryReport: Record "Statutory Report")
    var
        FormatVersion: Record "Format Version";
    begin
        LibraryStatReporting.CreateStatutoryReport(StatutoryReport);
        FormatVersion.Init();
        FormatVersion.Code := LibraryUtility.GenerateRandomCode(FormatVersion.FieldNo(Code), DATABASE::"Format Version");
        FormatVersion.Insert();
        StatutoryReport."Format Version Code" := FormatVersion.Code;
        StatutoryReport.Modify();
    end;

    local procedure FindFormatVersionCode(): Code[20]
    var
        FormatVersion: Record "Format Version";
    begin
        FormatVersion.SetRange("Report Type", FormatVersion."Report Type"::Tax);
        FormatVersion.SetFilter("XML Schema File Name", '<>%1', '');
        FormatVersion.FindFirst();
        exit(FormatVersion.Code);
    end;

    local procedure MockXMLElementLine(var XMLElementLine: Record "XML Element Line"; ReportCode: Code[20]; SourceType: Option; LineValue: Text[250]): Integer
    var
        RecRef: RecordRef;
    begin
        XMLElementLine.Init();
        XMLElementLine."Report Code" := ReportCode;
        RecRef.GetTable(XMLElementLine);
        XMLElementLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, XMLElementLine.FieldNo("Line No."));
        XMLElementLine."Source Type" := SourceType;
        XMLElementLine."Data Type" := XMLElementLine."Data Type"::Integer;
        XMLElementLine.Value := LineValue;
        XMLElementLine.Insert();
        exit(XMLElementLine."Line No.");
    end;

    local procedure MockXMLElementExpressionLine(ReportCode: Code[20]; BaseXMLElementLineNo: Integer; ChildXMLElementLineNo: Integer)
    var
        XMLElementExpressionLine: Record "XML Element Expression Line";
        RecRef: RecordRef;
    begin
        XMLElementExpressionLine.Init();
        XMLElementExpressionLine."Report Code" := ReportCode;
        XMLElementExpressionLine."Base XML Element Line No." := BaseXMLElementLineNo;
        RecRef.GetTable(XMLElementExpressionLine);
        XMLElementExpressionLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, XMLElementExpressionLine.FieldNo("Line No."));
        XMLElementExpressionLine."XML Element Line No." := ChildXMLElementLineNo;
        XMLElementExpressionLine.Insert();
    end;

    local procedure MockStatRepBuffer(var StatutoryReportBuffer: Record "Statutory Report Buffer")
    begin
        StatutoryReportBuffer.Init();
        StatutoryReportBuffer."Excel Sheet Name" :=
          CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(StatutoryReportBuffer."Excel Sheet Name"), TextType::Capitalized),
            1,
            MaxStrLen(StatutoryReportBuffer."Excel Sheet Name"));
        StatutoryReportBuffer.Insert();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure StatRepTableCellMappingPageHandler(var StatRepTableCellMapping: TestPage "Stat. Rep. Table Cell Mapping")
    begin
        StatRepTableCellMapping."Int. Source Row Description".SetValue(LibraryVariableStorage.DequeueText());
        StatRepTableCellMapping.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TaxAuthorityModalPageHandler(var TaxAuthorities: TestPage "Tax Authorities")
    begin
        TaxAuthorities.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        TaxAuthorities.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NameValueLookupMPH(var NameValueLookup: TestPage "Name/Value Lookup")
    var
        Counter: Integer;
    begin
        Counter := 0;
        NameValueLookup.First();
        repeat
            NameValueLookup.Name.AssertEquals(ErrorTok);
            Counter += 1;
        until not NameValueLookup.Next();

        Assert.IsTrue(Counter > 0, IncorrectFoundErrorErr);
    end;

    local procedure UpdateReportDataNosStatRepSetup(NoSeriesCode: Code[20])
    var
        StatutoryReportSetup: Record "Statutory Report Setup";
    begin
        StatutoryReportSetup.Get();
        StatutoryReportSetup.Validate("Report Data Nos", NoSeriesCode);
        StatutoryReportSetup.Modify();
    end;
}

