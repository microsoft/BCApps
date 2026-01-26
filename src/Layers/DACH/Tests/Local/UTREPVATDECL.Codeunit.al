codeunit 142058 "UT REP VATDECL"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('VATVIESDeclarationXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportReportingDateEmptyVATVIESDeclXMLError()
    var
        ReportingType: Option "Normal transmission","Recall of an earlier report";
    begin
        // Purpose of the test is to validate OnPreReport of Report ID 11108 VAT - VIES Declaration XML.

        // Setup: Run Report VAT - VIES Declaration XML to verify Error Code, Actual error message: Reportingdate must not be empty, if marking is "recall of an earlier report".
        Initialize();
        RunReportVATVIESDeclarationXML(ReportingType::"Recall of an earlier report", 0D, '');  // XML File Name, Reportingdate, No. Series.
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportNormalTransmissionVATVIESDeclXMLError()
    var
        ReportingType: Option "Normal transmission","Recall of an earlier report";
    begin
        // Purpose of the test is to validate OnPreReport of Report ID 11108 VAT - VIES Declaration XML.

        // Setup: Run Report VAT - VIES Declaration XML to verify Error Code, Actual error message: Reportingdate must be empty, if marking is "Normal transmission".
        Initialize();
        RunReportVATVIESDeclarationXML(ReportingType::"Normal transmission", WorkDate(), '');  // XML File Name, Reportingdate, No. Series.
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportNoSeriesVATVIESDeclMLError()
    var
        ReportingType: Option "Normal transmission","Recall of an earlier report";
    begin
        // Purpose of the test is to validate OnPreReport of Report ID 11108 VAT - VIES Declaration XML.

        // Setup: Run Report VAT - VIES Declaration XML to verify Error Code, Actual error message: You didn't define a No. Series.
        Initialize();
        RunReportVATVIESDeclarationXML(ReportingType::"Normal transmission", 0D, '');  // XML File Name, Reportingdate, No. Series.
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportNoSeriesDigitsVATVIESDeclXMLError()
    var
        ReportingType: Option "Normal transmission","Recall of an earlier report";
    begin
        // Purpose of the test is to validate OnPreReport of Report ID 11108 VAT - VIES Declaration XML.

        // Setup: Run Report VAT - VIES Declaration XML to verify Error Code, Actual error message: The No. Series has not 9 digits.
        Initialize();
        RunReportVATVIESDeclarationXML(
          ReportingType::"Normal transmission", 0D, CreateNoSeries(Format(LibraryRandom.RandIntInRange(1, 99999999))));  // Reportingdate, No. Series length is within the range of 1 to 8 digits.
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationXMLRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportNumericNoSeriesVATVIESDeclXMLError()
    var
        ReportingType: Option "Normal transmission","Recall of an earlier report";
    begin
        // Purpose of the test is to validate OnPreReport of Report ID 11108 VAT - VIES Declaration XML.

        // Setup: Run Report VAT - VIES Declaration XML to verify Error Code, Actual error message: The No. Series should only contain numbers.
        Initialize();
        RunReportVATVIESDeclarationXML(ReportingType::"Normal transmission", 0D,
          CreateNoSeries(DelStr(LibraryUTUtility.GetNewCode10(), 10, 1)));
        // XML File Name, Reportingdate, No. Series of 9 digit length which contain alphanumeric characters.
    end;

    local procedure RunReportVATVIESDeclarationXML(ReportingType: Option; ReportingDate: Date; NoSeries: Code[20])
    begin
        // Enqueue Required inside VATVIESDeclarationXMLRequestPageHandler.
        LibraryVariableStorage.Enqueue(ReportingType);
        LibraryVariableStorage.Enqueue(ReportingDate);
        LibraryVariableStorage.Enqueue(NoSeries);

        // Exercise: Run Report for different parameters ReportingType, XMLFileName, ReportingDate and No. Series on VATVIESDeclarationXMLRequestPageHandler.
        asserterror REPORT.Run(REPORT::"VAT - VIES Declaration XML");

        // Verify: Verify Error Code.
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateNoSeries(StartingNo: Code[20]): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Code := LibraryUTUtility.GetNewCode10();
        NoSeries.Insert();

        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Starting No." := StartingNo;
        NoSeriesLine.Insert();
        exit(NoSeriesLine."Series Code");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationXMLRequestPageHandler(var VATVIESDeclarationXML: TestRequestPage "VAT - VIES Declaration XML")
    var
        ReportingType: Variant;
        ReportingDate: Variant;
        NoSeries: Variant;
    begin
        LibraryVariableStorage.Dequeue(ReportingType);
        LibraryVariableStorage.Dequeue(ReportingDate);
        LibraryVariableStorage.Dequeue(NoSeries);
        VATVIESDeclarationXML.ReportingType.SetValue(ReportingType);
        VATVIESDeclarationXML.ReportingDate.SetValue(ReportingDate);
        VATVIESDeclarationXML.NoSeries.SetValue(NoSeries);
        VATVIESDeclarationXML.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

