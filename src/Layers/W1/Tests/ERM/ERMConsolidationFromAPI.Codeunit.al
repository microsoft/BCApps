codeunit 134105 "ERM Consolidation from API"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        MockScenario: Option Simple,EntryAtClosingDate;
        Initialized: Boolean;
        EntryNo: Integer;

    trigger OnRun()
    begin
    end;

    [Test]
    procedure EntriesConsolidatedFromOneCompany()
    var
        ConsolidationProcess: Record "Consolidation Process";
        BusinessUnit: Record "Business Unit";
        BusUnitConsolidationData: Record "Bus. Unit Consolidation Data";
        ERMConsolidationFromAPI: Codeunit "ERM Consolidation from API";
        ImportConsolidationFromAPI: Codeunit "Import Consolidation from API";
        Consolidate: Codeunit Consolidate;
    begin
        // [SCENARIO] A consolidation company with a business unit B01 imports from API it's data. It should be properly consolidated by aggregating each account to an entry.
        Initialize();
        // [GIVEN] The consolidation company has the same GL Accounts as the business unit
        InsertMockGLAccounts();
        // [GIVEN] Business unit with three entries: 2 for a credit account and 1 for a debit account (balancing out).
        ERMConsolidationFromAPI.SetSimpleScenarioMocks();
        BindSubscription(ERMConsolidationFromAPI);
        // [GIVEN] A Consolidation Process is created
        ConsolidationProcess."Document No." := 'CNS01';
        ConsolidationProcess."Starting Date" := 20230105D;
        ConsolidationProcess."Ending Date" := 20230315D;
        ConsolidationProcess.Status := ConsolidationProcess.Status::NotStarted;
        ConsolidationProcess.Insert();
        BusinessUnit."Consolidation %" := 100;
        BusinessUnit.Code := 'BU01';
        BusinessUnit."Default Data Import Method" := BusinessUnit."Default Data Import Method"::API;
        BusinessUnit."BC API URL" := 'https://api.fakebc.dynamics.com/';
        BusinessUnit."External Company Name" := 'SampleCompany';
        BusinessUnit."External Company Id" := 'fe51fd61-5b9e-4a42-a6b0-e61af5469daa';
        BusinessUnit.Insert();
        // [WHEN] Running the consolidation
        ImportConsolidationFromAPI.ImportConsolidationDataForBusinessUnit(ConsolidationProcess, BusinessUnit, BusUnitConsolidationData);
        BusUnitConsolidationData.GetConsolidate(Consolidate);
        Consolidate.Run(BusinessUnit);
        // [THEN] The consolidation entries for both accounts should have the totals
        VerifyConsolidatedGLEntries();
        UnbindSubscription(ERMConsolidationFromAPI);
    end;

    [Test]
    procedure EntriesPostedAtClosingDatesFail()
    var
        ConsolidationProcess: Record "Consolidation Process";
        BusinessUnit: Record "Business Unit";
        BusUnitConsolidationData: Record "Bus. Unit Consolidation Data";
        ERMConsolidationFromAPI: Codeunit "ERM Consolidation from API";
        ImportConsolidationFromAPI: Codeunit "Import Consolidation from API";
    begin
        // [SCENARIO] A consolidation company with a business unit B01 imports from API it's data.
        // The other company has a GL entry posted at a closing date of an account period of that company.
        Initialize();
        // [GIVEN] The consolidation company has the same GL Accounts as the business unit
        InsertMockGLAccounts();
        // [GIVEN] The business unit has a GL entry posted at a closing date of an account period
        ERMConsolidationFromAPI.SetEntryAtClosingDateScenarioMocks();
        BindSubscription(ERMConsolidationFromAPI);
        // [GIVEN] A Consolidation Process is created
        ConsolidationProcess."Document No." := 'CNS01';
        ConsolidationProcess."Starting Date" := 20230105D;
        ConsolidationProcess."Ending Date" := 20230315D;
        ConsolidationProcess.Status := ConsolidationProcess.Status::NotStarted;
        ConsolidationProcess.Insert();
        BusinessUnit."Consolidation %" := 100;
        BusinessUnit.Code := 'BU01';
        BusinessUnit."Default Data Import Method" := BusinessUnit."Default Data Import Method"::API;
        BusinessUnit."BC API URL" := 'https://api.fakebc.dynamics.com/';
        BusinessUnit."External Company Name" := 'SampleCompany';
        BusinessUnit."External Company Id" := 'fe51fd61-5b9e-4a42-a6b0-e61af5469daa';
        BusinessUnit.Insert();
        // [WHEN]  Running the consolidation
        // [THEN] It should fail with an error
        asserterror ImportConsolidationFromAPI.ImportConsolidationDataForBusinessUnit(ConsolidationProcess, BusinessUnit, BusUnitConsolidationData);
        UnbindSubscription(ERMConsolidationFromAPI);
    end;

    internal procedure SetSimpleScenarioMocks()
    begin
        MockScenario := MockScenario::Simple;
    end;

    internal procedure SetEntryAtClosingDateScenarioMocks()
    begin
        MockScenario := MockScenario::EntryAtClosingDate;
    end;

    local procedure VerifyConsolidatedGLEntries()
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", '1000');
        GLEntry.FindFirst();
        Assert.AreEqual(100, GLEntry."Credit Amount", 'Expected 100 in Credit Amount for G/L Account 1000');
        GLEntry.SetRange("G/L Account No.", '2000');
        GLEntry.FindFirst();
        Assert.AreEqual(100, GLEntry."Debit Amount", 'Expected 100 in Debit Amount for G/L Account 2000');
    end;

    local procedure GLEntryJSON(AccountNo: Text; CreditAmount: Decimal; DebitAmount: Decimal): Text
    begin
        EntryNo += 1;
        exit('{"entryNumber": ' + Format(EntryNo) + ' , "postingDate": "2023-01-15", "accountNumber": "' + AccountNo + '", "creditAmount": ' + Format(CreditAmount) + ', "debitAmount": ' + Format(DebitAmount) + ', "additionalCurrencyCreditAmount": 0, "additionalCurrencyDebitAmount": 0, "dimensionSetLines": []}');
    end;

    local procedure GLAccountJSON(AccountNo: Text): Text
    begin
        exit('{"number": "' + AccountNo + '", "consolidationTranslationMethod": "Average Rate (Manual)", "consolidationDebitAccount": "", "consolidationCreditAccount": ""}');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Import Consolidation from API", 'OnBeforeGetGLSetup', '', false, false)]
    local procedure OnBeforeGetGLSetup(var IsHandled: Boolean; var Response: Text)
    begin
        case MockScenario of
            MockScenario::Simple, MockScenario::EntryAtClosingDate:
                Response := '{"value": [{"additionalReportingCurrency": "", "localCurrencyCode": "GBP", "allowQueryFromConsolidation": true}]}';
        end;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Import Consolidation from API", 'OnBeforeGetCurrencyExchangeRates', '', false, false)]
    local procedure OnBeforeGetCurrencyExchangeRates(CurrencyFilter: Text; EndingDate: Date; var IsHandled: Boolean; var Response: Text)
    begin
        case MockScenario of
            MockScenario::Simple, MockScenario::EntryAtClosingDate:
                Response := '{"value": []}';
        end;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Import Consolidation from API", 'OnBeforeGetGLEntries', '', false, false)]
    local procedure OnBeforeGetGLEntries(DateFilter: Text; AccountNoFilter: Text; var IsHandled: Boolean; var Response: Text)
    begin
        case MockScenario of
            MockScenario::Simple, MockScenario::EntryAtClosingDate:
                Response := '{"value": [' + GLEntryJSON('1000', 50, 0) + ', ' + GLEntryJSON('1000', 50, 0) + ', ' + GLEntryJSON('2000', 0, 100) + ']}';
        end;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Import Consolidation from API", 'OnBeforeGetDimensions', '', false, false)]
    local procedure OnBeforeGetDimensions(DimensionFilter: Text; var IsHandled: Boolean; var Response: Text)
    begin
        case MockScenario of
            MockScenario::Simple, MockScenario::EntryAtClosingDate:
                Response := '{"value": []}';
        end;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Import Consolidation from API", 'OnBeforeGetGLEntriesCountAtDate', '', false, false)]
    local procedure OnBeforeGetGLEntriesCountAtDate(GLAccountNo: Code[20]; ClosingDate: Date; var IsHandled: Boolean; var Response: Text)
    begin
        case MockScenario of
            MockScenario::Simple:
                Response := '{"@odata.count": 0}';
            MockScenario::EntryAtClosingDate:
                Response := '{"@odata.count": 1}';
        end;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Import Consolidation from API", 'OnBeforeGetAccountingPeriods', '', false, false)]
    local procedure OnBeforeGetAccountingPeriods(StartingDate: Date; EndingDate: Date; var IsHandled: Boolean; var Response: Text)
    begin
        case MockScenario of
            MockScenario::Simple:
                Response := '{"value": []}';
            MockScenario::EntryAtClosingDate:
                Response := '{"value": [{"startingDate": "2023-01-01", "newFiscalYear": false}]}';
        end;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Import Consolidation from API", 'OnBeforeGetPostingGLAccounts', '', false, false)]
    local procedure OnBeforeGetPostingGLAccounts(var IsHandled: Boolean; var Response: Text)
    begin
        case MockScenario of
            MockScenario::Simple, MockScenario::EntryAtClosingDate:
                Response := '{"value": [' + GLAccountJSON('1000') + ', ' + GLAccountJSON('2000') + ']}';
        end;
        IsHandled := true;
    end;

    local procedure InsertMockGLAccounts()
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := '1000';
        GLAccount.Insert();
        GLAccount."No." := '2000';
        GLAccount.Insert();
    end;

    local procedure Initialize()
    var
        ConsolidationProcess: Record "Consolidation Process";
        BusUnitInConsProcess: Record "Bus. Unit In Cons. Process";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        BusinessUnit: Record "Business Unit";
        Field: Record Field;
        GLBookEntryRecordRef: RecordRef;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        LibrarySetupStorage.Restore();
        BusUnitInConsProcess.DeleteAll();
        ConsolidationProcess.DeleteAll();
        GLAccount.DeleteAll();
        GLEntry.DeleteAll();
        BusinessUnit.DeleteAll();
        if EnvironmentInformation.GetApplicationFamily() = 'IT' then
            if Field.Get(12144, 1) then begin // "GL Book Entry"
                GLBookEntryRecordRef.Open(12144);
                GLBookEntryRecordRef.DeleteAll();
            end;

        if Initialized then
            exit;

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        Initialized := true;
    end;

}