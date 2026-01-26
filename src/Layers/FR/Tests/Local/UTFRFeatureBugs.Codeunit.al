codeunit 144016 "UT FR Feature Bugs"
{
    // 1. Purpose of the test is to verify Country_Region_Code EC Sales List - Service Report.
    // 2. Purpose of the test is to verify Error on EC Sales List - Service Report.
    // 
    // Covers Test Cases for WI - 344431.
    // --------------------------------------------------------------------------------------
    // Test Function Name                                                             TFS ID
    // --------------------------------------------------------------------------------------
    // RequestPageOptionSeparateLinesECSalesList,OnPreReportECSalesListServicesError  328053

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DateFilterCap: Label '%1..%2';

    [Test]
    [HandlerFunctions('ECSalesListServicesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RequestPageOptionSeparateLinesECSalesList()
    var
        Calender: Record Date;
        CountryRegionCode: Code[10];
    begin
        // Purpose of the test is to verify Country_Region_Code EC Sales List - Service Report 10876.
        // Setup.
        Initialize();
        CountryRegionCode := CreateVATEntry();
        CalculateDate(Calender);

        // Enqueue CountryRegion,Start Date and End Date.
        EnqueueVariables(CountryRegionCode, Calender."Period Start", Calender."Period End");

        // Exercise.
        REPORT.Run(REPORT::"EC Sales List - Services");

        // Verify: Verifying on Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Country_Region_Code', CountryRegionCode);
    end;

    [Test]
    [HandlerFunctions('ECSalesListServicesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportECSalesListServicesError()
    var
        CountryRegionCode: Code[10];
    begin
        // Purpose of the test is to verify Error on EC Sales List - Service Report 10876.
        // Setup.
        Initialize();
        CountryRegionCode := CreateVATEntry();

        // Enqueue CountryRegion,Start Date and End Date.
        EnqueueVariables(CountryRegionCode, WorkDate(), WorkDate());

        // Exercise.
        asserterror REPORT.Run(REPORT::"EC Sales List - Services");

        // Verify: verify actual error message  Posting Date filter must be corrected, to run the report monthly.
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateVATEntry(): Code[10]
    var
        VATEntry2: Record "VAT Entry";
        VATEntry: Record "VAT Entry";
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Code := LibraryUTUtility.GetNewCode10();
        CountryRegion."EU Country/Region Code" := CountryRegion.Code;
        CountryRegion.Insert();
        VATEntry2.FindLast();
        VATEntry."Entry No." := VATEntry2."Entry No." + 1;
        VATEntry."Country/Region Code" := CountryRegion.Code;
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Posting Date" := WorkDate();
        VATEntry.Insert();
        exit(CountryRegion.Code);
    end;

    local procedure CalculateDate(var Calender: Record Date)
    var
        StartDate: Date;
    begin
        // Calculate Start Date and End Date.
        StartDate := DMY2Date(1, 12, Date2DMY(WorkDate(), 3) - 1);
        Calender.SetRange("Period Type", Calender."Period Type"::Month);
        Calender.SetRange("Period Start", StartDate);
        Calender.FindFirst();
    end;

    local procedure EnqueueVariables(CountryRegionCode: Code[10]; StartDate: Date; EndDate: Date)
    begin
        // Enqueue for ECSalesListServicesRequestPageHandler.
        LibraryVariableStorage.Enqueue(CountryRegionCode);
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ECSalesListServicesRequestPageHandler(var ECSalesListServices: TestRequestPage "EC Sales List - Services")
    var
        CountryRegionCode: Variant;
        StartDate: Variant;
        EndDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(CountryRegionCode);
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        ECSalesListServices."VAT Entry".SetFilter("Country/Region Code", CountryRegionCode);
        ECSalesListServices."VAT Entry".SetFilter("Posting Date", StrSubstNo(DateFilterCap, StartDate, EndDate));
        ECSalesListServices.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

