codeunit 148015 "Elec. VAT Decl. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        QuarterlyResponseTok: Label 'vat-return-periods/quarterly.xml', Locked = true;
        FrequencyChangeResponseTok: Label 'vat-return-periods/frequency-change.xml', Locked = true;
        FrequencyWithoutDeadlinesResponseTok: Label 'vat-return-periods/frequency-without-deadlines.xml', Locked = true;
        NoFrequencyListResponseTok: Label 'vat-return-periods/no-frequency-list.xml', Locked = true;
        FilingAndPaymentDatesDifferResponseTok: Label 'vat-return-periods/filing-and-payment-dates-differ.xml', Locked = true;
        UnsupportedFrequencyResponseTok: Label 'vat-return-periods/unsupported-frequency.xml', Locked = true;
        MissingFilingDateResponseTok: Label 'vat-return-periods/missing-filing-date.xml', Locked = true;
        MissingFrequencyCodeResponseTok: Label 'vat-return-periods/missing-frequency-code.xml', Locked = true;

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
    [HandlerFunctions('PeriodsReceivedMessageHandler')]
    procedure SKATQuarterlyResponseCreatesQuarterlyPeriods()
    var
        VATReturnPeriod: Record "VAT Return Period";
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        // [SCENARIO 654780] Periods are read from a VirksomhedKalenderHent_O response as SKAT sends it, with frequency code 8 (quarterly)
        Initialize();
        LibraryVariableStorage.Enqueue('8 periods were received from server. 8 new periods were inserted.');

        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(NavApp.GetResourceAsText(QuarterlyResponseTok), true);

        Assert.RecordCount(VATReturnPeriod, 8);
        VerifyVATReturnPeriodExists(20250701D, 20250930D, 20251201D);
        VerifyVATReturnPeriodExists(20251001D, 20251231D, 20260302D);
        VerifyVATReturnPeriodExists(20260101D, 20260331D, 20260601D);
        VerifyVATReturnPeriodExists(20260401D, 20260630D, 20260901D);
        VerifyVATReturnPeriodExists(20260701D, 20260930D, 20261201D);
        VerifyVATReturnPeriodExists(20261001D, 20261231D, 20270301D);
        VerifyVATReturnPeriodExists(20270101D, 20270331D, 20270601D);
        VerifyVATReturnPeriodExists(20270401D, 20270630D, 20270901D);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PeriodsReceivedMessageHandler')]
    procedure SKATQuarterlyResponseSkipsExistingPeriod()
    var
        VATReturnPeriod: Record "VAT Return Period";
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        // [SCENARIO 654780] A period that was created manually is not inserted again
        Initialize();
        VATReturnPeriod.Validate("Start Date", 20260701D);
        VATReturnPeriod.Validate("End Date", 20260930D);
        VATReturnPeriod.Validate("Due Date", 20261201D);
        VATReturnPeriod.Insert(true);
        LibraryVariableStorage.Enqueue('8 periods were received from server. 7 new periods were inserted.');

        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(NavApp.GetResourceAsText(QuarterlyResponseTok), true);

        VATReturnPeriod.Reset();
        Assert.RecordCount(VATReturnPeriod, 8);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PeriodsReceivedMessageHandler')]
    procedure SKATQuarterlyResponseWithLegacyParserCreatesQuarterlyPeriods()
    var
        VATReturnPeriod: Record "VAT Return Period";
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        // [SCENARIO 654780] The legacy parser (reporting frequency disabled) still reads the SKAT response
        Initialize();
        LibraryVariableStorage.Enqueue('8 periods were received from server. 8 new periods were inserted.');

        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(NavApp.GetResourceAsText(QuarterlyResponseTok), false);

        Assert.RecordCount(VATReturnPeriod, 8);
        VerifyVATReturnPeriodExists(20260701D, 20260930D, 20261201D);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ResponsePeriodsKeepFrequencyAndDueDateAssociated()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
        ResponseText: Text;
    begin
        Initialize();
        ResponseText := GetResponseXml(
            GetFrequencyXml('07', GetDeadlineXml('2026-05-01')) +
            GetFrequencyXml('09', GetDeadlineXml('2026-12-01')));

        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(ResponseText, true);

        VerifyVATReturnPeriodExists(20260401D, 20260430D, 20260501D);
        VerifyVATReturnPeriodExists(20260101D, 20260630D, 20261201D);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ResponsePeriodsAreIndependentOfFrequencyOrder()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
        ResponseText: Text;
    begin
        Initialize();
        ResponseText := GetResponseXml(
            GetFrequencyXml('09', GetDeadlineXml('2026-12-01')) +
            GetFrequencyXml('07', GetDeadlineXml('2026-05-01')));

        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(ResponseText, true);

        VerifyVATReturnPeriodExists(20260401D, 20260430D, 20260501D);
        VerifyVATReturnPeriodExists(20260101D, 20260630D, 20261201D);
    end;

    [Test]
    [HandlerFunctions('PeriodsReceivedMessageHandler')]
    procedure GettingSamePeriodsTwiceDoesNotInsertDuplicates()
    var
        VATReturnPeriod: Record "VAT Return Period";
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        // [SCENARIO 654780] Getting the same periods from SKAT again does not insert them again
        Initialize();
        LibraryVariableStorage.Enqueue('8 periods were received from server. 8 new periods were inserted.');
        LibraryVariableStorage.Enqueue('8 periods were received from server. 0 new periods were inserted.');

        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(NavApp.GetResourceAsText(QuarterlyResponseTok), true);
        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(NavApp.GetResourceAsText(QuarterlyResponseTok), true);

        Assert.RecordCount(VATReturnPeriod, 8);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PeriodsReceivedMessageHandler')]
    procedure FrequencyChangeCreatesPeriodsForEachFrequency()
    var
        VATReturnPeriod: Record "VAT Return Period";
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        // [SCENARIO 654780] Each frequency entry uses its own frequency code for its deadlines
        Initialize();
        LibraryVariableStorage.Enqueue('7 periods were received from server. 7 new periods were inserted.');

        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(NavApp.GetResourceAsText(FrequencyChangeResponseTok), true);

        Assert.RecordCount(VATReturnPeriod, 7);
        VerifyVATReturnPeriodExists(20250701D, 20250930D, 20251201D);
        VerifyVATReturnPeriodExists(20251001D, 20251231D, 20260302D);
        VerifyVATReturnPeriodExists(20260101D, 20260331D, 20260601D);
        VerifyVATReturnPeriodExists(20260401D, 20260630D, 20260901D);
        VerifyVATReturnPeriodExists(20260701D, 20260731D, 20260825D);
        VerifyVATReturnPeriodExists(20260801D, 20260831D, 20260925D);
        VerifyVATReturnPeriodExists(20260901D, 20260930D, 20261026D);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PeriodsReceivedMessageHandler')]
    procedure ResponseWithoutFrequencyListReceivesNoPeriods()
    var
        VATReturnPeriod: Record "VAT Return Period";
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        // [SCENARIO 654780] A response without AngivelseFrekvensListe is valid and gives no periods
        Initialize();
        LibraryVariableStorage.Enqueue('0 periods were received from server. 0 new periods were inserted.');

        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(NavApp.GetResourceAsText(NoFrequencyListResponseTok), true);

        Assert.RecordIsEmpty(VATReturnPeriod);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PeriodsReceivedMessageHandler')]
    procedure DueDateIsFilingDeadline()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        // [SCENARIO 654780] The period due date is the filing deadline (AngivelseFristKalenderFristDato), not the payment or interest date
        Initialize();
        LibraryVariableStorage.Enqueue('1 periods were received from server. 1 new periods were inserted.');

        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(NavApp.GetResourceAsText(FilingAndPaymentDatesDifferResponseTok), true);

        VerifyVATReturnPeriodExists(20260401D, 20260630D, 20260901D);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PeriodsReceivedMessageHandler')]
    procedure FrequencyWithoutDeadlinesIsIgnored()
    var
        VATReturnPeriod: Record "VAT Return Period";
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        // [SCENARIO 654780] A frequency entry without deadlines does not fail, even with a frequency code that is not supported
        Initialize();
        LibraryVariableStorage.Enqueue('1 periods were received from server. 1 new periods were inserted.');

        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(NavApp.GetResourceAsText(FrequencyWithoutDeadlinesResponseTok), true);

        Assert.RecordCount(VATReturnPeriod, 1);
        VerifyVATReturnPeriodExists(20260401D, 20260630D, 20260901D);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ReportingFrequencyCodesAreMapped()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
        ReportingFrequency: Enum "Elec. VAT Decl. Rep. Frequency";
    begin
        // [SCENARIO 654780] SKAT frequency codes 07, 08 and 09 map to monthly, quarterly and semi-annual
        Assert.AreEqual(ReportingFrequency::Monthly, ElecVATDeclGetPeriods.GetReportingFrequency('07'), 'Code 07 must be monthly.');
        Assert.AreEqual(ReportingFrequency::Quarterly, ElecVATDeclGetPeriods.GetReportingFrequency('8'), 'Code 8 must be quarterly.');
        Assert.AreEqual(ReportingFrequency::"Semi-Annual", ElecVATDeclGetPeriods.GetReportingFrequency(' 09 '), 'Code 09 must be semi-annual.');
    end;

    [Test]
    procedure UnknownReportingFrequencyRaisesError()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        asserterror ElecVATDeclGetPeriods.GetReportingFrequency('05');

        Assert.ExpectedError('is not supported');
    end;

    [Test]
    procedure NonNumericReportingFrequencyRaisesError()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        // [SCENARIO 654780] SKAT sends a numeric frequency code; frequency names are not accepted
        asserterror ElecVATDeclGetPeriods.GetReportingFrequency('Kvartal');

        Assert.ExpectedError('is not supported');
    end;

    [Test]
    procedure MissingReportingFrequencyRaisesError()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        asserterror ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(NavApp.GetResourceAsText(MissingFrequencyCodeResponseTok), true);

        Assert.ExpectedError('does not contain a reporting frequency');
    end;

    [Test]
    procedure MissingFilingDateRaisesError()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        // [SCENARIO 654780] A deadline without AngivelseFristKalenderFristDato is rejected, the optional payment date is not used instead
        asserterror ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(NavApp.GetResourceAsText(MissingFilingDateResponseTok), true);

        Assert.ExpectedError('does not contain a due date');
    end;

    [Test]
    procedure InvalidDueDateRaisesError()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        asserterror ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(
            GetResponseXml(GetFrequencyXml('07', GetDeadlineXml('not-a-date'))), true);

        Assert.ExpectedError('contains an invalid due date');
    end;

    [Test]
    procedure InvalidResponseXmlRaisesError()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        // [SCENARIO 654780] A response that cannot be read as XML is not reported as zero periods received
        asserterror ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText('not xml', true);

        Assert.ExpectedError('is not a valid XML document');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure DisabledReportingFrequencyCreatesQuarterlyPeriod()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
        ResponseText: Text;
    begin
        Initialize();
        ResponseText := GetResponseXml(GetFrequencyXml('08', GetDeadlineXml('2026-09-01')));

        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(ResponseText, false);

        VerifyVATReturnPeriodExists(20260401D, 20260630D, 20260901D);
    end;

    [Test]
    procedure UnknownReportingFrequencyInResponseRaisesError()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        asserterror ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(NavApp.GetResourceAsText(UnsupportedFrequencyResponseTok), true);

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
            GetResponseXml(GetFrequencyXml('07', GetDeadlineXml('2026-04-01'))), true);

        Assert.ExpectedError('overlaps the period received from SKAT');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportingFrequencyIsEnabledWhenKeyVaultFlagIsTrue()
    var
        ElecVATDeclAzKeyVault: Codeunit "Elec. VAT Decl. Az. Key Vault";
    begin
        SetReportingFrequencyKeyVaultFlag('true');

        Assert.IsTrue(ElecVATDeclAzKeyVault.IsReportingFrequencyEnabled(), 'Reporting frequency must be enabled when the Key Vault flag is true.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportingFrequencyIsDisabledWhenKeyVaultFlagIsFalse()
    var
        ElecVATDeclAzKeyVault: Codeunit "Elec. VAT Decl. Az. Key Vault";
    begin
        SetReportingFrequencyKeyVaultFlag('false');

        Assert.IsFalse(ElecVATDeclAzKeyVault.IsReportingFrequencyEnabled(), 'Reporting frequency must be disabled when the Key Vault flag is false.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure KeyVaultEnabledFlagUsesReportingFrequencyFromResponse()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
    begin
        Initialize();
        SetReportingFrequencyKeyVaultFlag('true');

        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(GetResponseXml(GetFrequencyXml('07', GetDeadlineXml('2026-05-01'))));

        VerifyVATReturnPeriodExists(20260401D, 20260430D, 20260501D);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure KeyVaultDisabledFlagUsesLegacyQuarterlyPeriod()
    var
        ElecVATDeclGetPeriods: Codeunit "Elec. VAT Decl. Get Periods";
        ResponseText: Text;
    begin
        Initialize();
        SetReportingFrequencyKeyVaultFlag('false');
        ResponseText := GetResponseXml(GetFrequencyXml('08', GetDeadlineXml('2026-09-01')));

        ElecVATDeclGetPeriods.GetVATReturnPeriodsFromResponseText(ResponseText);

        VerifyVATReturnPeriodExists(20260401D, 20260630D, 20260901D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportingFrequencyIsEnabledWhenKeyVaultFlagIsInvalid()
    var
        ElecVATDeclAzKeyVault: Codeunit "Elec. VAT Decl. Az. Key Vault";
    begin
        SetReportingFrequencyKeyVaultFlag('invalid');

        Assert.IsTrue(ElecVATDeclAzKeyVault.IsReportingFrequencyEnabled(), 'Reporting frequency must default to enabled when the Key Vault flag is invalid.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportingFrequencyIsEnabledWhenKeyVaultFlagIsMissing()
    var
        ElecVATDeclAzKeyVault: Codeunit "Elec. VAT Decl. Az. Key Vault";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider();
        LibraryAzureKVMockMgmt.UseAzureKeyvaultSecretProvider();

        Assert.IsTrue(ElecVATDeclAzKeyVault.IsReportingFrequencyEnabled(), 'Reporting frequency must default to enabled when the Key Vault flag is missing.');
    end;

    local procedure Initialize()
    var
        VATReportSetup: Record "VAT Report Setup";
        VATReturnPeriod: Record "VAT Return Period";
    begin
        LibraryVariableStorage.Clear();
        VATReturnPeriod.DeleteAll(true);
        if not VATReportSetup.Get() then
            VATReportSetup.Insert();
        VATReportSetup.Validate("VAT Return Period No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        VATReportSetup.Modify();
    end;

    local procedure GetResponseXml(FrequenciesXml: Text): Text
    begin
        exit(
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="urn:oio:skat:nemvirksomhed:ws:1.0.0" xmlns:ns4="urn:oio:skat:nemvirksomhed:1.0.0">' +
            '<soapenv:Body><ns1:VirksomhedKalenderHent_O><ns1:AngivelseFrekvensListe>' + FrequenciesXml + '</ns1:AngivelseFrekvensListe></ns1:VirksomhedKalenderHent_O></soapenv:Body></soapenv:Envelope>');
    end;

    local procedure GetFrequencyXml(FrequencyTypeCode: Text; DeadlinesXml: Text): Text
    begin
        exit(
            '<ns1:AngivelseFrekvens><ns4:AngivelseFrekvensForholdGyldigFraDate>2025-01-01</ns4:AngivelseFrekvensForholdGyldigFraDate>' +
            '<ns4:AngivelseFrekvensTypeCode>' + FrequencyTypeCode + '</ns4:AngivelseFrekvensTypeCode>' +
            '<ns1:AngivelseBetalingFristDatoListe>' + DeadlinesXml + '</ns1:AngivelseBetalingFristDatoListe></ns1:AngivelseFrekvens>');
    end;

    local procedure GetDeadlineXml(DueDate: Text): Text
    begin
        exit(
            '<ns1:AngivelseBetalingFristDato><ns4:AngivelseFristKalenderFristDato>' + DueDate + '</ns4:AngivelseFristKalenderFristDato>' +
            '<ns4:AngivelseFristKalenderBetalingDato>' + DueDate + '</ns4:AngivelseFristKalenderBetalingDato></ns1:AngivelseBetalingFristDato>');
    end;

    local procedure VerifyVATReturnPeriodExists(StartDate: Date; EndDate: Date; DueDate: Date)
    var
        VATReturnPeriod: Record "VAT Return Period";
    begin
        VATReturnPeriod.SetRange("Start Date", StartDate);
        VATReturnPeriod.SetRange("End Date", EndDate);
        VATReturnPeriod.SetRange("Due Date", DueDate);
        Assert.RecordIsNotEmpty(VATReturnPeriod);
    end;

    [Scope('OnPrem')]
    local procedure SetReportingFrequencyKeyVaultFlag(FlagValue: Text)
    var
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
    begin
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider();
        LibraryAzureKVMockMgmt.AddMockAzureKeyvaultSecretProviderMapping('DKElecVAT-ReportingFrequencyEnabled', FlagValue);
        LibraryAzureKVMockMgmt.UseAzureKeyvaultSecretProvider();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(Message.Contains('periods were received from server'), Message);
    end;

    [MessageHandler]
    procedure PeriodsReceivedMessageHandler(Message: Text[1024])
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Message, 'Unexpected message.');
    end;
}