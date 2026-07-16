codeunit 148015 "Elec. VAT Decl. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";

    trigger OnRun()
    begin
        // [FEATURE] [Electronic VAT Declaration for Denmark]
    end;

    [Test]
    procedure QuarterlyPeriodStartsOnFirstDayOfQuarter()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
        ReportingFrequency: Enum "Elec. VAT Decl. Rep. Frequency";
        EndDate: Date;
    begin
        EndDate := ElecVATDeclGetPeriods.CalcPeriodEndDate(20260901D, ReportingFrequency::Quarterly);

        Assert.AreEqual(20260630D, EndDate, 'The Q2 end date is incorrect.');
        Assert.AreEqual(20260401D, ElecVATDeclGetPeriods.CalcPeriodStartDate(EndDate, ReportingFrequency::Quarterly), 'The Q2 start date is incorrect.');
    end;

    [Test]
    procedure MonthlyPeriodUsesCalendarMonth()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
        ReportingFrequency: Enum "Elec. VAT Decl. Rep. Frequency";
        EndDate: Date;
    begin
        EndDate := ElecVATDeclGetPeriods.CalcPeriodEndDate(20260501D, ReportingFrequency::Monthly);

        Assert.AreEqual(20260430D, EndDate, 'The monthly end date is incorrect.');
        Assert.AreEqual(20260401D, ElecVATDeclGetPeriods.CalcPeriodStartDate(EndDate, ReportingFrequency::Monthly), 'The monthly start date is incorrect.');
    end;

    [Test]
    procedure SemiAnnualPeriodUsesSixCalendarMonths()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
        ReportingFrequency: Enum "Elec. VAT Decl. Rep. Frequency";
        EndDate: Date;
    begin
        EndDate := ElecVATDeclGetPeriods.CalcPeriodEndDate(20261201D, ReportingFrequency::"Semi-Annual");

        Assert.AreEqual(20260630D, EndDate, 'The semi-annual end date is incorrect.');
        Assert.AreEqual(20260101D, ElecVATDeclGetPeriods.CalcPeriodStartDate(EndDate, ReportingFrequency::"Semi-Annual"), 'The semi-annual start date is incorrect.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ResponsePeriodsKeepFrequencyAndDueDateAssociated()
    var
        VATReturnPeriod: Record "VAT Return Period";
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
        ResponseText: Text;
    begin
        Initialize();
        ResponseText := GetResponseXml(
            GetPeriodXml('Måned', '2026-05-01') +
            GetPeriodXml('Halvår', '2026-12-01'));

        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(ResponseText);

        VATReturnPeriod.SetRange("Start Date", 20260401D);
        VATReturnPeriod.SetRange("End Date", 20260430D);
        VATReturnPeriod.SetRange("Due Date", 20260501D);
        Assert.RecordIsNotEmpty(VATReturnPeriod);
        VATReturnPeriod.SetRange("Start Date", 20260101D);
        VATReturnPeriod.SetRange("End Date", 20260630D);
        VATReturnPeriod.SetRange("Due Date", 20261201D);
        Assert.RecordIsNotEmpty(VATReturnPeriod);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure GettingSamePeriodsTwiceDoesNotInsertDuplicates()
    var
        VATReturnPeriod: Record "VAT Return Period";
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
        ResponseText: Text;
    begin
        Initialize();
        ResponseText := GetResponseXml(GetPeriodXml('Kvartal', '2026-09-01'));

        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(ResponseText);
        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(ResponseText);

        VATReturnPeriod.SetRange("Start Date", 20260401D);
        VATReturnPeriod.SetRange("End Date", 20260630D);
        Assert.RecordCount(VATReturnPeriod, 1);
    end;

    [Test]
    procedure UnknownReportingFrequencyRaisesError()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        asserterror ElecVATDeclGetPeriods.GetReportingFrequency('Ugentlig');

        Assert.ExpectedError('is not supported');
    end;

    [Test]
    procedure MissingReportingFrequencyRaisesError()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
        ResponseText: Text;
    begin
        ResponseText := GetResponseXml(
            '<ns1:AngivelseBetalingFristStruktur><ns4:AngivelseFristKalenderBetalingDato>2026-05-01</ns4:AngivelseFristKalenderBetalingDato></ns1:AngivelseBetalingFristStruktur>');

        asserterror ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(ResponseText);

        Assert.ExpectedError('does not contain a reporting frequency');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure DisabledReportingFrequencyCreatesQuarterlyPeriod()
    var
        VATReturnPeriod: Record "VAT Return Period";
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
        ResponseText: Text;
    begin
        Initialize();
        ResponseText := GetResponseXml(
            '<ns1:AngivelseBetalingFristStruktur><ns4:AngivelseFristKalenderBetalingDato>2026-09-01</ns4:AngivelseFristKalenderBetalingDato></ns1:AngivelseBetalingFristStruktur>');

        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(ResponseText, false);

        VATReturnPeriod.SetRange("Start Date", 20260401D);
        VATReturnPeriod.SetRange("End Date", 20260630D);
        VATReturnPeriod.SetRange("Due Date", 20260901D);
        Assert.RecordIsNotEmpty(VATReturnPeriod);
    end;

    [Test]
    procedure UnknownReportingFrequencyInResponseRaisesError()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        asserterror ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(
            GetResponseXml(GetPeriodXml('Ugentlig', '2026-05-01')));

        Assert.ExpectedError('is not supported');
    end;

    [Test]
    procedure ExistingIncorrectPeriodPreventsOverlappingInsert()
    var
        VATReturnPeriod: Record "VAT Return Period";
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        Initialize();
        VATReturnPeriod.Validate("Start Date", 20260101D);
        VATReturnPeriod.Validate("End Date", 20260331D);
        VATReturnPeriod.Insert(true);

        asserterror ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(
            GetResponseXml(GetPeriodXml('Måned', '2026-04-01')));

        Assert.ExpectedError('overlaps the period received from SKAT');
    end;

    local procedure Initialize()
    var
        NoSeries: Record "No. Series";
        VATReportSetup: Record "VAT Report Setup";
        VATReturnPeriod: Record "VAT Return Period";
    begin
        VATReturnPeriod.DeleteAll(true);
        if not VATReportSetup.Get() then
            VATReportSetup.Insert();
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        VATReportSetup.Validate("VAT Return Period No. Series", NoSeries.Code);
        VATReportSetup.Modify();
    end;

    local procedure GetResponseXml(PeriodXml: Text): Text
    begin
        exit(
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="urn:oio:skat:nemvirksomhed:ws:1.0.0" xmlns:ns4="urn:oio:skat:nemvirksomhed:1.0.0">' +
            '<soapenv:Body><ns1:VirksomhedKalenderHent_O>' + PeriodXml + '</ns1:VirksomhedKalenderHent_O></soapenv:Body></soapenv:Envelope>');
    end;

    local procedure GetPeriodXml(Frequency: Text; DueDate: Text): Text
    begin
        exit(
            '<ns1:AngivelseBetalingFristStruktur><ns4:AngivelseFrekvensNavn>' + Frequency + '</ns4:AngivelseFrekvensNavn>' +
            '<ns4:AngivelseFristKalenderBetalingDato>' + DueDate + '</ns4:AngivelseFristKalenderBetalingDato></ns1:AngivelseBetalingFristStruktur>');
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(Message.Contains('periods were received from server'), Message);
    end;
}